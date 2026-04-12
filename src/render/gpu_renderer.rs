//! GPU-accelerated 2D renderer for Lurek2D, backed by wgpu.
//!
//! Processes a `RenderCommand` queue each frame, tessellates geometry on the CPU,
//! uploads vertex / index data to GPU buffers, and issues a single render pass.
//!
//! # Design
//! - Two render pipelines: *color* (solid + gradient shapes) and *texture* (images, sprites).
//! - Transform stack maintained during command processing — standard `push/pop` transform stack semantics.
//! - Colored geometry is batched in one draw call; each distinct texture source is one draw call.
//! - Draw order: colored shapes first (in submission order), textured images second.

use std::collections::{HashMap, HashSet};
use std::f32::consts::PI;
use std::sync::mpsc;

use bytemuck::{Pod, Zeroable};

use crate::log_msg;
use crate::math::{Mat3, Vec2};
use crate::render::mesh::Mesh;
use crate::render::renderer::{BlendMode, DrawMode, RenderCommand, TextAlign, TextureData};
use crate::render::shader::{Shader, ShaderFragmentInput, UniformValue};
use crate::runtime::log_messages::{
    G002_SCREENSHOT_ZERO_SIZE, G003_SCREENSHOT_MAP_FAIL, G004_SCREENSHOT_RECV_FAIL,
    G005_SCREENSHOT_DATA_FAIL,
};
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, SpriteBatchKey, TextureKey,
};
use slotmap::{SlotMap, SparseSecondaryMap};

// ─── Vertex types ────────────────────────────────────────────────────────────

/// Vertex for solid-color geometry.
#[repr(C)]
#[derive(Copy, Clone, Pod, Zeroable)]
struct ColorVertex {
    position: [f32; 2],
    color: [f32; 4],
}

/// Vertex for textured (sprite) geometry.
#[repr(C)]
#[derive(Copy, Clone, Pod, Zeroable)]
struct TexVertex {
    position: [f32; 2],
    uv: [f32; 2],
    color: [f32; 4],
}

/// Vertex for the 2D lighting pass with per-light shadow information.
#[repr(C)]
#[derive(Copy, Clone, Pod, Zeroable)]
struct LightVertex {
    position: [f32; 2],
    uv: [f32; 2],
    color: [f32; 4],
    /// Normalized V coordinate into the shadow atlas (−1.0 = no shadow map).
    shadow_v: f32,
    _pad: [f32; 3],
}

/// Resolution (width) of each 1D radial shadow map.
const SHADOW_MAP_RES: usize = 256;

/// Maximum number of shadow-mapped lights in a single frame.
const MAX_SHADOW_LIGHTS: usize = 128;

/// Uniform buffer containing the viewport dimensions for NDC conversion.
#[repr(C)]
#[derive(Copy, Clone, Pod, Zeroable)]
struct ViewportUniform {
    size: [f32; 2],
    time: f32,
    _pad: f32,
    view_col0: [f32; 4],
    view_col1: [f32; 4],
    view_col2: [f32; 4],
}

// ─── GPU texture wrapper ──────────────────────────────────────────────────────

struct GpuTexture {
    _texture: wgpu::Texture,
    // Kept alive so the bind_group's TextureView reference stays valid.
    view: wgpu::TextureView,
    bind_group: wgpu::BindGroup,
    width: u32,
    height: u32,
}

struct DepthStencilTarget {
    _texture: wgpu::Texture,
    view: wgpu::TextureView,
    width: u32,
    height: u32,
}

struct PendingSurfaceReadback {
    buffer: wgpu::Buffer,
    padded_bytes_per_row: u32,
    width: u32,
    height: u32,
}

/// Reference to a GPU-side texture used during render batching.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum TexRef {
    Texture(TextureKey),
    Canvas(CanvasKey),
    FontAtlas(FontKey),
}

// ─── Constants ────────────────────────────────────────────────────────────────

const MAX_COLOR_VERTS: u64 = 1 << 17; // 131 072 vertices
const MAX_COLOR_IDXS: u64 = 1 << 19; // 524 288 indices
const MAX_TEX_VERTS: u64 = 1 << 14; // 16 384 vertices
const MAX_TEX_IDXS: u64 = 1 << 16; // 65 536 indices

const MAX_LIGHT_QUADS: usize = 128;

/// Per-frame rendering statistics.
///
/// # Fields
/// - `draw_calls` — `u32`.
/// - `texture_switches` — `u32`.
/// - `canvas_switches` — `u32`.
/// - `shader_switches` — `u32`.
/// - `batched_draws` — `u32`.
#[derive(Debug, Default, Clone)]
pub struct RenderStats {
    /// Number of draw calls issued this frame.
    pub draw_calls: u32,
    /// Number of texture bind group switches this frame.
    pub texture_switches: u32,
    /// Number of canvas target switches this frame.
    pub canvas_switches: u32,
    /// Number of pipeline (shader/blend) switches this frame.
    pub shader_switches: u32,
    /// Number of draw calls eliminated by coalescing.
    pub batched_draws: u32,
}

/// Optional scissor rectangle in physical pixels: `(x, y, width, height)`.
type ScissorRect = Option<(u32, u32, u32, u32)>;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum RenderTargetId {
    Screen,
    Canvas(CanvasKey),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum GeometryKind {
    Color,
    Texture,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum StencilMode {
    Disabled,
    Write(crate::render::renderer::StencilAction),
    Test(crate::render::renderer::CompareMode),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct PipelineKey {
    blend_mode: BlendMode,
    color_mask_bits: u32,
    stencil_mode: StencilMode,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum PipelineSelectionKey {
    Default {
        geometry: GeometryKind,
        pipeline: PipelineKey,
    },
    Custom {
        shader: ShaderKey,
        geometry: GeometryKind,
        pipeline: PipelineKey,
    },
}

#[derive(Debug, Clone, Copy)]
struct PreparedDraw {
    target: RenderTargetId,
    geometry: GeometryKind,
    texture_ref: Option<TexRef>,
    idx_start: u32,
    idx_count: u32,
    blend_mode: BlendMode,
    scissor: ScissorRect,
    color_mask_bits: u32,
    shader: Option<ShaderKey>,
    stencil_mode: StencilMode,
    stencil_reference: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum ShaderUniformKind {
    Float,
    Vec2,
    Vec3,
    Vec4,
    Int,
    Bool,
}

struct GpuShader {
    source: String,
    uniform_signature: Vec<(String, ShaderUniformKind)>,
    uniform_buffers: Vec<wgpu::Buffer>,
    uniform_bind_group: Option<wgpu::BindGroup>,
    color_module: wgpu::ShaderModule,
    texture_module: wgpu::ShaderModule,
    color_layout: wgpu::PipelineLayout,
    texture_layout: wgpu::PipelineLayout,
    color_pipelines: HashMap<PipelineKey, wgpu::RenderPipeline>,
    texture_pipelines: HashMap<PipelineKey, wgpu::RenderPipeline>,
}

/// Returns the wgpu `BlendState` for a given `BlendMode`.
fn blend_state_for(mode: BlendMode) -> wgpu::BlendState {
    match mode {
        BlendMode::Alpha => wgpu::BlendState::ALPHA_BLENDING,
        BlendMode::Add => wgpu::BlendState {
            color: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::SrcAlpha,
                dst_factor: wgpu::BlendFactor::One,
                operation: wgpu::BlendOperation::Add,
            },
            alpha: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::One,
                dst_factor: wgpu::BlendFactor::One,
                operation: wgpu::BlendOperation::Add,
            },
        },
        BlendMode::Multiply => wgpu::BlendState {
            color: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::Dst,
                dst_factor: wgpu::BlendFactor::Zero,
                operation: wgpu::BlendOperation::Add,
            },
            alpha: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::DstAlpha,
                dst_factor: wgpu::BlendFactor::Zero,
                operation: wgpu::BlendOperation::Add,
            },
        },
        BlendMode::Replace => wgpu::BlendState {
            color: wgpu::BlendComponent::REPLACE,
            alpha: wgpu::BlendComponent::REPLACE,
        },
        BlendMode::Screen => wgpu::BlendState {
            color: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::One,
                dst_factor: wgpu::BlendFactor::OneMinusSrc,
                operation: wgpu::BlendOperation::Add,
            },
            alpha: wgpu::BlendComponent {
                src_factor: wgpu::BlendFactor::One,
                dst_factor: wgpu::BlendFactor::OneMinusSrcAlpha,
                operation: wgpu::BlendOperation::Add,
            },
        },
    }
}

// ─── WGSL shaders (embedded inline) ─────────────────────────────────────────

const COLOR_SHADER: &str = r#"
struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) color:    vec4<f32>,
}
struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0)       color:         vec4<f32>,
}
struct Viewport {
    size: vec2<f32>,
    time: f32,
    _pad: f32,
    view_col0: vec4<f32>,
    view_col1: vec4<f32>,
    view_col2: vec4<f32>,
}
@group(0) @binding(0) var<uniform> viewport: Viewport;

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    let view = mat3x3<f32>(
        viewport.view_col0.xyz,
        viewport.view_col1.xyz,
        viewport.view_col2.xyz,
    );
    let cam_pos = view * vec3<f32>(in.position, 1.0);
    out.clip_position = vec4<f32>(
        (cam_pos.x / viewport.size.x) * 2.0 - 1.0,
        1.0 - (cam_pos.y / viewport.size.y) * 2.0,
        0.0, 1.0
    );
    out.color = in.color;
    return out;
}
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> { return in.color; }
"#;

const TEXTURE_SHADER: &str = r#"
struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) uv:       vec2<f32>,
    @location(2) color:    vec4<f32>,
}
struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0)       uv:            vec2<f32>,
    @location(1)       color:         vec4<f32>,
}
struct Viewport {
    size: vec2<f32>,
    time: f32,
    _pad: f32,
    view_col0: vec4<f32>,
    view_col1: vec4<f32>,
    view_col2: vec4<f32>,
}
@group(0) @binding(0) var<uniform>  viewport:   Viewport;
@group(1) @binding(0) var           t_diffuse:  texture_2d<f32>;
@group(1) @binding(1) var           s_diffuse:  sampler;

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    let view = mat3x3<f32>(
        viewport.view_col0.xyz,
        viewport.view_col1.xyz,
        viewport.view_col2.xyz,
    );
    let cam_pos = view * vec3<f32>(in.position, 1.0);
    out.clip_position = vec4<f32>(
        (cam_pos.x / viewport.size.x) * 2.0 - 1.0,
        1.0 - (cam_pos.y / viewport.size.y) * 2.0,
        0.0, 1.0
    );
    out.uv    = in.uv;
    out.color = in.color;
    return out;
}
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return textureSample(t_diffuse, s_diffuse, in.uv) * in.color;
}
"#;

const LIGHT_SHADER: &str = r#"
struct VertexInput {
    @location(0) position: vec2<f32>,
    @location(1) uv:       vec2<f32>,
    @location(2) color:    vec4<f32>,
    @location(3) shadow_v: f32,
}
struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0)       uv:            vec2<f32>,
    @location(1)       color:         vec4<f32>,
    @location(2)       shadow_v:      f32,
}
struct Viewport {
    size: vec2<f32>,
    time: f32,
    _pad: f32,
    view_col0: vec4<f32>,
    view_col1: vec4<f32>,
    view_col2: vec4<f32>,
}
@group(0) @binding(0) var<uniform> viewport: Viewport;
@group(1) @binding(0) var shadow_atlas: texture_2d<f32>;
@group(1) @binding(1) var shadow_sampler: sampler;

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    let view = mat3x3<f32>(
        viewport.view_col0.xyz,
        viewport.view_col1.xyz,
        viewport.view_col2.xyz,
    );
    let cam_pos = view * vec3<f32>(in.position, 1.0);
    out.clip_position = vec4<f32>(
        (cam_pos.x / viewport.size.x) * 2.0 - 1.0,
        1.0 - (cam_pos.y / viewport.size.y) * 2.0,
        0.0, 1.0
    );
    out.uv       = in.uv;
    out.color    = in.color;
    out.shadow_v = in.shadow_v;
    return out;
}
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let center = vec2<f32>(0.5, 0.5);
    let delta  = in.uv - center;
    let dist   = length(delta) * 2.0;
    let falloff = clamp(1.0 - dist, 0.0, 1.0);
    let intensity = falloff * falloff;

    // Shadow attenuation.
    var shadow = 1.0;
    if in.shadow_v >= 0.0 {
        let angle = atan2(delta.y, delta.x);                     // [-π, π]
        let u     = (angle + 3.14159265) / (2.0 * 3.14159265);  // [0, 1]
        let shadow_dist = textureSample(shadow_atlas, shadow_sampler, vec2<f32>(u, in.shadow_v)).r;
        let frag_dist   = dist * 0.5;                            // normalised to radius
        if frag_dist > shadow_dist {
            shadow = 0.0;
        }
    }

    return vec4<f32>(in.color.rgb * intensity * shadow, 1.0);
}
"#;

// ─── GpuRenderer ─────────────────────────────────────────────────────────────

struct LightGpuState {
    #[allow(dead_code)]
    accum_texture: wgpu::Texture,
    accum_view: wgpu::TextureView,
    accum_bind_group: wgpu::BindGroup,
    additive_pipeline: wgpu::RenderPipeline,
    composite_pipeline: wgpu::RenderPipeline,
    vertex_buffer: wgpu::Buffer,
    index_buffer: wgpu::Buffer,
    /// 1D-per-row shadow atlas.  Width = `SHADOW_MAP_RES`, height = `MAX_SHADOW_LIGHTS`.
    shadow_atlas_texture: wgpu::Texture,
    #[allow(dead_code)]
    shadow_atlas_view: wgpu::TextureView,
    shadow_atlas_bind_group: wgpu::BindGroup,
    width: u32,
    height: u32,
}

/// GPU-accelerated renderer that processes `RenderCommand` queues via wgpu.
///
/// # Fields
/// - `device` — `wgpu::Device`.
/// - `queue` — `wgpu::Queue`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `render_stats` — `RenderStats`.
///
/// Owns the wgpu `Device` and `Queue`. The caller (App) owns the `Surface`
/// and configuration; `render_frame` receives a shared reference each frame.
pub struct GpuRenderer {
    /// wgpu logical device.
    pub(crate) device: wgpu::Device,
    /// wgpu command queue.
    pub(crate) queue: wgpu::Queue,

    viewport_bind_group_layout: wgpu::BindGroupLayout,
    default_color_shader: wgpu::ShaderModule,
    default_texture_shader: wgpu::ShaderModule,
    default_color_layout: wgpu::PipelineLayout,
    default_texture_layout: wgpu::PipelineLayout,
    default_color_pipelines: HashMap<PipelineKey, wgpu::RenderPipeline>,
    default_texture_pipelines: HashMap<PipelineKey, wgpu::RenderPipeline>,
    shader_cache: SparseSecondaryMap<ShaderKey, GpuShader>,

    viewport_buffer: wgpu::Buffer,
    viewport_bind_group: wgpu::BindGroup,
    texture_bind_group_layout: wgpu::BindGroupLayout,

    color_vertex_buffer: wgpu::Buffer,
    color_index_buffer: wgpu::Buffer,
    tex_vertex_buffer: wgpu::Buffer,
    tex_index_buffer: wgpu::Buffer,

    gpu_textures: SparseSecondaryMap<TextureKey, GpuTexture>,

    /// Maps font key → GPU texture for font atlas textures.
    font_atlas_textures: SparseSecondaryMap<FontKey, GpuTexture>,

    /// GPU canvas textures (off-screen render targets).
    canvas_gpu_textures: SparseSecondaryMap<CanvasKey, GpuTexture>,

    screen_stencil_target: Option<DepthStencilTarget>,
    canvas_stencil_targets: SparseSecondaryMap<CanvasKey, DepthStencilTarget>,
    canvas_needs_clear: SparseSecondaryMap<CanvasKey, bool>,

    /// The surface texture format, needed for creating canvas-compatible pipelines.
    surface_format: wgpu::TextureFormat,

    /// Renderer output dimensions in physical pixels.
    pub width: u32,
    /// Renderer output dimensions in physical pixels.
    pub height: u32,

    /// Per-frame rendering statistics from the last completed frame.
    pub render_stats: RenderStats,

    /// Lazily-created GPU resources for the 2D lighting pass.
    light_gpu: Option<LightGpuState>,
}

/// Computes a 1D radial shadow map for a single light.
///
/// For each angular sample the function casts a ray from the light centre and
/// finds the nearest occluder edge.  The result is a `Vec<f32>` of length
/// `SHADOW_MAP_RES` where each element is the **normalised** distance (0–1
/// relative to `light_radius`) to the closest occluder at that angle.  A value
/// of 1.0 means no occluder is closer than the light radius.
fn compute_1d_shadow_map(
    light_x: f32,
    light_y: f32,
    light_radius: f32,
    shadow_mask: u16,
    occluders: impl IntoIterator<Item = impl std::borrow::Borrow<crate::light::occluder::Occluder>>,
) -> Vec<f32> {
    let mut map = vec![1.0f32; SHADOW_MAP_RES];
    let inv_res = 1.0 / SHADOW_MAP_RES as f32;

    // Collect occluder edges once so we don't iterate occluders × resolution.
    struct Edge {
        ax: f32,
        ay: f32,
        sx: f32,
        sy: f32,
    }
    let mut edges: Vec<Edge> = Vec::new();

    for occ_ref in occluders {
        let occ = occ_ref.borrow();
        if !occ.enabled {
            continue;
        }
        if occ.light_mask & shadow_mask == 0 {
            continue;
        }
        let verts = occ.get_vertices();
        let n = verts.len();
        if n < 2 {
            continue;
        }
        for j in 0..n {
            let a = verts[j];
            let b = verts[(j + 1) % n];
            let ax = a.x + occ.position.x - light_x;
            let ay = a.y + occ.position.y - light_y;
            let bx = b.x + occ.position.x - light_x;
            let by = b.y + occ.position.y - light_y;
            edges.push(Edge {
                ax,
                ay,
                sx: bx - ax,
                sy: by - ay,
            });
        }
    }

    if edges.is_empty() {
        return map;
    }

    let inv_radius = 1.0 / light_radius;

    for i in 0..SHADOW_MAP_RES {
        let angle = (i as f32 * inv_res) * std::f32::consts::TAU - PI;
        let dir_x = angle.cos();
        let dir_y = angle.sin();
        let mut min_dist = 1.0f32;

        for e in &edges {
            let cross_ds = dir_x * e.sy - dir_y * e.sx;
            if cross_ds.abs() < 1e-8 {
                continue;
            }
            let inv_cross = 1.0 / cross_ds;
            let t = (e.ax * e.sy - e.ay * e.sx) * inv_cross;
            let u = (e.ax * dir_y - e.ay * dir_x) * inv_cross;

            if t > 0.0 && (0.0..=1.0).contains(&u) {
                let norm_dist = t * inv_radius;
                if norm_dist < min_dist && norm_dist < 1.0 {
                    min_dist = norm_dist;
                }
            }
        }

        map[i] = min_dist;
    }
    map
}

impl GpuRenderer {
    /// Creates a new `GpuRenderer` from an already-created wgpu device and queue.
    ///
    /// # Parameters
    /// - `device` — `wgpu::Device`.
    /// - `queue` — `wgpu::Queue`.
    /// - `surface_format` — `wgpu::TextureFormat`.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `surface_format` must match the format used when configuring the wgpu `Surface`.
    pub fn new(
        device: wgpu::Device,
        queue: wgpu::Queue,
        surface_format: wgpu::TextureFormat,
        width: u32,
        height: u32,
    ) -> Self {
        // ── Viewport uniform ──────────────────────────────────────────────
        let viewport_data = ViewportUniform {
            size: [width as f32, height as f32],
            time: 0.0,
            _pad: 0.0,
            view_col0: [1.0, 0.0, 0.0, 0.0],
            view_col1: [0.0, 1.0, 0.0, 0.0],
            view_col2: [0.0, 0.0, 1.0, 0.0],
        };
        let viewport_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("viewport_uniform"),
            size: std::mem::size_of::<ViewportUniform>() as u64,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        queue.write_buffer(&viewport_buffer, 0, bytemuck::bytes_of(&viewport_data));

        // ── Bind group layouts ────────────────────────────────────────────
        let viewport_bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("viewport_bgl"),
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStages::VERTEX,
                ty: wgpu::BindingType::Buffer {
                    ty: wgpu::BufferBindingType::Uniform,
                    has_dynamic_offset: false,
                    min_binding_size: None,
                },
                count: None,
            }],
        });
        let texture_bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("texture_bgl"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                        view_dimension: wgpu::TextureViewDimension::D2,
                        multisampled: false,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None,
                },
            ],
        });

        // ── Viewport bind group ────────────────────────────────────────────
        let viewport_bg = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("viewport_bg"),
            layout: &viewport_bgl,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: viewport_buffer.as_entire_binding(),
            }],
        });

        // ── Default shaders and layouts ───────────────────────────────────
        let color_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("color_shader"),
            source: wgpu::ShaderSource::Wgsl(COLOR_SHADER.into()),
        });
        let texture_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("texture_shader"),
            source: wgpu::ShaderSource::Wgsl(TEXTURE_SHADER.into()),
        });

        let color_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("color_layout"),
            bind_group_layouts: &[&viewport_bgl],
            push_constant_ranges: &[],
        });
        let texture_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("texture_layout"),
            bind_group_layouts: &[&viewport_bgl, &texture_bgl],
            push_constant_ranges: &[],
        });

        // ── Vertex / index buffers ────────────────────────────────────────
        let color_vertex_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("color_vbo"),
            size: MAX_COLOR_VERTS * std::mem::size_of::<ColorVertex>() as u64,
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let color_index_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("color_ibo"),
            size: MAX_COLOR_IDXS * std::mem::size_of::<u32>() as u64,
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let tex_vertex_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("tex_vbo"),
            size: MAX_TEX_VERTS * std::mem::size_of::<TexVertex>() as u64,
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let tex_index_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("tex_ibo"),
            size: MAX_TEX_IDXS * std::mem::size_of::<u32>() as u64,
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        GpuRenderer {
            device,
            queue,
            viewport_bind_group_layout: viewport_bgl,
            default_color_shader: color_shader,
            default_texture_shader: texture_shader,
            default_color_layout: color_layout,
            default_texture_layout: texture_layout,
            default_color_pipelines: HashMap::new(),
            default_texture_pipelines: HashMap::new(),
            shader_cache: SparseSecondaryMap::new(),
            viewport_buffer,
            viewport_bind_group: viewport_bg,
            texture_bind_group_layout: texture_bgl,
            color_vertex_buffer,
            color_index_buffer,
            tex_vertex_buffer,
            tex_index_buffer,
            gpu_textures: SparseSecondaryMap::new(),
            font_atlas_textures: SparseSecondaryMap::new(),
            canvas_gpu_textures: SparseSecondaryMap::new(),
            screen_stencil_target: None,
            canvas_stencil_targets: SparseSecondaryMap::new(),
            canvas_needs_clear: SparseSecondaryMap::new(),
            surface_format,
            width,
            height,
            render_stats: RenderStats::default(),
            light_gpu: None,
        }
    }

    /// Updates the viewport uniform after a window resize.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// Surface reconfiguration is the caller's responsibility (see `App::handle_resize`).
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
        let data = ViewportUniform {
            size: [width as f32, height as f32],
            time: 0.0,
            _pad: 0.0,
            view_col0: [1.0, 0.0, 0.0, 0.0],
            view_col1: [0.0, 1.0, 0.0, 0.0],
            view_col2: [0.0, 0.0, 1.0, 0.0],
        };
        self.queue
            .write_buffer(&self.viewport_buffer, 0, bytemuck::bytes_of(&data));
        self.screen_stencil_target = None;
        self.light_gpu = None;
    }

    fn create_sampler(&self, default_filter: &(String, String, u32)) -> wgpu::Sampler {
        let min_filter = parse_filter_mode(&default_filter.0);
        let mag_filter = parse_filter_mode(&default_filter.1);
        let anisotropy =
            if min_filter == wgpu::FilterMode::Linear && mag_filter == wgpu::FilterMode::Linear {
                default_filter.2.clamp(1, u16::MAX as u32) as u16
            } else {
                1
            };

        self.device.create_sampler(&wgpu::SamplerDescriptor {
            address_mode_u: wgpu::AddressMode::ClampToEdge,
            address_mode_v: wgpu::AddressMode::ClampToEdge,
            mag_filter,
            min_filter,
            mipmap_filter: min_filter,
            anisotropy_clamp: anisotropy,
            ..Default::default()
        })
    }

    fn create_texture_bind_group(
        &self,
        view: &wgpu::TextureView,
        sampler: &wgpu::Sampler,
        label: &'static str,
    ) -> wgpu::BindGroup {
        self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some(label),
            layout: &self.texture_bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(sampler),
                },
            ],
        })
    }

    /// Creates a `GpuTexture` from raw RGBA8 pixel data (does not store it).
    fn create_gpu_texture_raw(
        &self,
        pixels: &[u8],
        width: u32,
        height: u32,
        default_filter: &(String, String, u32),
    ) -> GpuTexture {
        let size = wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        };
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("sprite_texture"),
            size,
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });
        self.queue.write_texture(
            wgpu::ImageCopyTexture {
                texture: &texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            pixels,
            wgpu::ImageDataLayout {
                offset: 0,
                bytes_per_row: Some(4 * width),
                rows_per_image: Some(height),
            },
            size,
        );
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = self.create_sampler(default_filter);
        let bind_group = self.create_texture_bind_group(&view, &sampler, "sprite_bg");
        GpuTexture {
            _texture: texture,
            view,
            bind_group,
            width,
            height,
        }
    }

    /// Uploads raw RGBA8 pixel data as a new GPU texture stored under the given key.
    ///
    /// # Parameters
    /// - `key` — `TextureKey`.
    /// - `pixels` — `&[u8]`.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `default_filter` — `&(String, String, u32)`.
    pub fn upload_texture(
        &mut self,
        key: TextureKey,
        pixels: &[u8],
        width: u32,
        height: u32,
        default_filter: &(String, String, u32),
    ) {
        let gt = self.create_gpu_texture_raw(pixels, width, height, default_filter);
        self.gpu_textures.insert(key, gt);
    }

    /// Ensures a font's glyph atlas is uploaded as a GPU texture, returning `true` if ready.
    fn ensure_font_atlas(
        &mut self,
        font_key: FontKey,
        font: &mut crate::render::Font,
        default_filter: &(String, String, u32),
    ) -> bool {
        let (data, w, h) = font.atlas_data();

        if font.is_dirty() || !self.font_atlas_textures.contains_key(font_key) {
            let gt = self.create_gpu_texture_raw(data, w, h, default_filter);
            self.font_atlas_textures.insert(font_key, gt);
            font.mark_clean();
        }

        self.font_atlas_textures.contains_key(font_key)
    }

    /// Creates an off-screen GPU canvas texture stored under the given key.
    ///
    /// # Parameters
    /// - `key` — `CanvasKey`.
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `default_filter` — `&(String, String, u32)`.
    ///
    /// The texture is created with `RENDER_ATTACHMENT | TEXTURE_BINDING` so it can
    /// be rendered to and then sampled as a regular image.
    pub fn create_canvas(
        &mut self,
        key: CanvasKey,
        width: u32,
        height: u32,
        default_filter: &(String, String, u32),
    ) {
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("canvas_texture"),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: self.surface_format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = self.create_sampler(default_filter);
        let bind_group = self.create_texture_bind_group(&view, &sampler, "canvas_bg");
        self.canvas_gpu_textures.insert(
            key,
            GpuTexture {
                _texture: texture,
                view,
                bind_group,
                width,
                height,
            },
        );
        self.canvas_needs_clear.insert(key, true);
    }

    fn create_depth_stencil_target(
        &self,
        width: u32,
        height: u32,
        label: &'static str,
    ) -> DepthStencilTarget {
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some(label),
            size: wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Depth24PlusStencil8,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            view_formats: &[],
        });
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        DepthStencilTarget {
            _texture: texture,
            view,
            width,
            height,
        }
    }

    fn ensure_screen_stencil_target(&mut self) {
        let needs_recreate = self
            .screen_stencil_target
            .as_ref()
            .map(|target| target.width != self.width || target.height != self.height)
            .unwrap_or(true);
        if needs_recreate {
            self.screen_stencil_target = Some(self.create_depth_stencil_target(
                self.width,
                self.height,
                "screen_stencil_target",
            ));
        }
    }

    fn ensure_canvas_stencil_target(&mut self, key: CanvasKey, width: u32, height: u32) {
        let needs_recreate = self
            .canvas_stencil_targets
            .get(key)
            .map(|target| target.width != width || target.height != height)
            .unwrap_or(true);
        if needs_recreate {
            self.canvas_stencil_targets.insert(
                key,
                self.create_depth_stencil_target(width, height, "canvas_stencil_target"),
            );
        }
    }

    fn prune_released_resources(
        &mut self,
        textures: &SlotMap<TextureKey, TextureData>,
        fonts: &SlotMap<FontKey, crate::render::Font>,
        canvases: &SlotMap<CanvasKey, crate::render::Canvas>,
        shaders: &SlotMap<ShaderKey, Shader>,
    ) {
        let stale_textures: Vec<TextureKey> = self
            .gpu_textures
            .iter()
            .map(|(key, _)| key)
            .filter(|key| !textures.contains_key(*key))
            .collect();
        for key in stale_textures {
            self.gpu_textures.remove(key);
        }

        let stale_fonts: Vec<FontKey> = self
            .font_atlas_textures
            .iter()
            .map(|(key, _)| key)
            .filter(|key| !fonts.contains_key(*key))
            .collect();
        for key in stale_fonts {
            self.font_atlas_textures.remove(key);
        }

        let stale_canvases: Vec<CanvasKey> = self
            .canvas_gpu_textures
            .iter()
            .map(|(key, _)| key)
            .filter(|key| !canvases.contains_key(*key))
            .collect();
        for key in stale_canvases {
            self.canvas_gpu_textures.remove(key);
            self.canvas_stencil_targets.remove(key);
            self.canvas_needs_clear.remove(key);
        }

        let stale_shaders: Vec<ShaderKey> = self
            .shader_cache
            .iter()
            .map(|(key, _)| key)
            .filter(|key| !shaders.contains_key(*key))
            .collect();
        for key in stale_shaders {
            self.shader_cache.remove(key);
        }
    }

    /// Lazily creates or recreates GPU resources for the 2D lighting pass.
    fn ensure_light_resources(&mut self) {
        let needs_recreate = match &self.light_gpu {
            Some(lg) => lg.width != self.width || lg.height != self.height,
            None => true,
        };
        if !needs_recreate {
            return;
        }

        let w = self.width;
        let h = self.height;

        // ── Light accumulation texture (screen-sized) ──
        let accum_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("light_accum_texture"),
            size: wgpu::Extent3d {
                width: w,
                height: h,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: self.surface_format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });
        let accum_view = accum_texture.create_view(&wgpu::TextureViewDescriptor::default());
        let sampler = self.device.create_sampler(&wgpu::SamplerDescriptor {
            mag_filter: wgpu::FilterMode::Linear,
            min_filter: wgpu::FilterMode::Linear,
            ..Default::default()
        });
        let accum_bind_group =
            self.create_texture_bind_group(&accum_view, &sampler, "light_accum_bg");

        // ── Shadow atlas texture (SHADOW_MAP_RES × MAX_SHADOW_LIGHTS, R32Float) ──
        let shadow_atlas_texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("shadow_atlas_texture"),
            size: wgpu::Extent3d {
                width: SHADOW_MAP_RES as u32,
                height: MAX_SHADOW_LIGHTS as u32,
                depth_or_array_layers: 1,
            },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::R32Float,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[],
        });
        let shadow_atlas_view =
            shadow_atlas_texture.create_view(&wgpu::TextureViewDescriptor::default());

        // Shadow atlas bind group layout — unfilterable R32Float.
        let shadow_bgl = self
            .device
            .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                label: Some("shadow_atlas_bgl"),
                entries: &[
                    wgpu::BindGroupLayoutEntry {
                        binding: 0,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Texture {
                            sample_type: wgpu::TextureSampleType::Float { filterable: false },
                            view_dimension: wgpu::TextureViewDimension::D2,
                            multisampled: false,
                        },
                        count: None,
                    },
                    wgpu::BindGroupLayoutEntry {
                        binding: 1,
                        visibility: wgpu::ShaderStages::FRAGMENT,
                        ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::NonFiltering),
                        count: None,
                    },
                ],
            });
        let shadow_sampler = self.device.create_sampler(&wgpu::SamplerDescriptor {
            mag_filter: wgpu::FilterMode::Nearest,
            min_filter: wgpu::FilterMode::Nearest,
            ..Default::default()
        });
        let shadow_atlas_bind_group = self.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("shadow_atlas_bg"),
            layout: &shadow_bgl,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: wgpu::BindingResource::TextureView(&shadow_atlas_view),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(&shadow_sampler),
                },
            ],
        });

        // ── Light pipeline layout: viewport + shadow atlas ──
        let light_pipeline_layout =
            self.device
                .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                    label: Some("light_pipeline_layout"),
                    bind_group_layouts: &[&self.viewport_bind_group_layout, &shadow_bgl],
                    push_constant_ranges: &[],
                });

        // ── Light radial-falloff shader ──
        let light_module = self
            .device
            .create_shader_module(wgpu::ShaderModuleDescriptor {
                label: Some("light_shader"),
                source: wgpu::ShaderSource::Wgsl(LIGHT_SHADER.into()),
            });

        // Additive pipeline — renders light quads onto the accumulation texture.
        // Uses LightVertex with shadow_v attribute.
        let additive_pipeline =
            self.device
                .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                    label: Some("light_additive_pipeline"),
                    layout: Some(&light_pipeline_layout),
                    vertex: wgpu::VertexState {
                        module: &light_module,
                        entry_point: "vs_main",
                        compilation_options: Default::default(),
                        buffers: &[wgpu::VertexBufferLayout {
                            array_stride: std::mem::size_of::<LightVertex>() as wgpu::BufferAddress,
                            step_mode: wgpu::VertexStepMode::Vertex,
                            attributes: &wgpu::vertex_attr_array![
                                0 => Float32x2,
                                1 => Float32x2,
                                2 => Float32x4,
                                3 => Float32
                            ],
                        }],
                    },
                    fragment: Some(wgpu::FragmentState {
                        module: &light_module,
                        entry_point: "fs_main",
                        compilation_options: Default::default(),
                        targets: &[Some(wgpu::ColorTargetState {
                            format: self.surface_format,
                            blend: Some(blend_state_for(BlendMode::Add)),
                            write_mask: wgpu::ColorWrites::ALL,
                        })],
                    }),
                    primitive: wgpu::PrimitiveState {
                        topology: wgpu::PrimitiveTopology::TriangleList,
                        ..Default::default()
                    },
                    depth_stencil: None,
                    multisample: wgpu::MultisampleState::default(),
                    multiview: None,
                    cache: None,
                });

        // Composite pipeline — draws the accumulation texture over the scene
        // with multiply blending. Needs depth/stencil to match the screen target.
        let composite_pipeline = create_render_pipeline(
            &self.device,
            self.surface_format,
            &self.default_texture_layout,
            &self.default_texture_shader,
            GeometryKind::Texture,
            PipelineKey {
                blend_mode: BlendMode::Multiply,
                color_mask_bits: color_write_mask_bits((true, true, true, true)),
                stencil_mode: StencilMode::Disabled,
            },
            "fs_main",
        );

        // ── Vertex / index buffers for light quads + composite quad ──
        let max_verts = (MAX_LIGHT_QUADS + 1) * 4;
        let max_idxs = (MAX_LIGHT_QUADS + 1) * 6;
        let vertex_buffer = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("light_vbo"),
            size: (max_verts * std::mem::size_of::<LightVertex>()) as u64,
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let index_buffer = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("light_ibo"),
            size: (max_idxs * std::mem::size_of::<u32>()) as u64,
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        self.light_gpu = Some(LightGpuState {
            accum_texture,
            accum_view,
            accum_bind_group,
            additive_pipeline,
            composite_pipeline,
            vertex_buffer,
            index_buffer,
            shadow_atlas_texture,
            shadow_atlas_view,
            shadow_atlas_bind_group,
            width: w,
            height: h,
        });
    }

    /// Processes a frame: uploads new textures, tessellates commands, renders to surface, presents.
    ///
    /// # Parameters
    /// - `surface` — `&wgpu::Surface<'static>`.
    /// - `commands` — `&[RenderCommand]`.
    /// - `textures` — `&SlotMap<TextureKey, TextureData>`.
    /// - `fonts` — `&mut SlotMap<FontKey, crate::render::Font>`.
    /// - `sprite_batches` — `&SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch>`.
    /// - `canvases` — `&SlotMap<CanvasKey, crate::render::Canvas>`.
    /// - `meshes` — `&SlotMap<MeshKey, Mesh>`.
    /// - `shaders` — `&SlotMap<ShaderKey, Shader>`.
    /// - `default_filter` — `&(String, String, u32)`.
    /// - `background_color` — `[f32`.
    /// - `capture_screenshot` — `bool`.
    ///
    /// Returns `Err(wgpu::SurfaceError)` on transient errors; the caller should reconfigure on
    /// `SurfaceError::Lost`. When `capture_screenshot` is `true`, a successful frame may also
    /// return `Ok(Some((width, height, rgba_pixels)))` containing the presented screen image.
    #[allow(clippy::too_many_arguments)]
    pub fn render_frame(
        &mut self,
        surface: &wgpu::Surface<'static>,
        commands: &[RenderCommand],
        textures: &SlotMap<TextureKey, TextureData>,
        fonts: &mut SlotMap<FontKey, crate::render::Font>,
        light_world: &crate::light::light_world::LightWorld,
        sprite_batches: &SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch>,
        canvases: &SlotMap<CanvasKey, crate::render::Canvas>,
        meshes: &SlotMap<MeshKey, Mesh>,
        shaders: &SlotMap<ShaderKey, Shader>,
        default_filter: &(String, String, u32),
        background_color: [f32; 4],
        camera_matrix: &Mat3,
        frame_time: f32,
        capture_screenshot: bool,
    ) -> Result<Option<(u32, u32, Vec<u8>)>, wgpu::SurfaceError> {
        self.prune_released_resources(textures, fonts, canvases, shaders);

        // Lazily upload any TextureData added since last frame.
        for (key, tex_data) in textures.iter() {
            if !self.gpu_textures.contains_key(key) {
                self.upload_texture(
                    key,
                    &tex_data.pixels,
                    tex_data.width,
                    tex_data.height,
                    default_filter,
                );
            }
        }

        // Lazily create GPU textures for any new canvases.
        for (key, canvas) in canvases.iter() {
            if !self.canvas_gpu_textures.contains_key(key) {
                self.create_canvas(key, canvas.width, canvas.height, default_filter);
            }
        }

        // Reset per-frame stats.
        self.render_stats = RenderStats::default();

        let mut all_color_verts: Vec<ColorVertex> = Vec::new();
        let mut all_color_idxs: Vec<u32> = Vec::new();
        let mut all_tex_verts: Vec<TexVertex> = Vec::new();
        let mut all_tex_idxs: Vec<u32> = Vec::new();
        let mut draws: Vec<PreparedDraw> = Vec::new();

        let mut current_target = RenderTargetId::Screen;
        let mut current_blend_mode = BlendMode::Alpha;
        let mut current_scissor: Option<(f32, f32, f32, f32)> = None;
        let mut current_color = [1.0f32, 1.0, 1.0, 1.0];
        let mut color_mask_bits = color_write_mask_bits((true, true, true, true));
        let mut wireframe = false;
        let mut line_width = 1.0f32;
        let mut point_size = 1.0f32;
        let mut transform_stack: Vec<Mat3> = vec![Mat3::identity()];
        let mut stencil_mode = StencilMode::Disabled;
        let mut stencil_reference = 0u8;
        let mut active_shader: Option<ShaderKey> = None;

        for cmd in commands {
            match cmd {
                RenderCommand::SetColor(r, g, b, a) => {
                    current_color = [*r, *g, *b, *a];
                }
                RenderCommand::SetLineWidth(w) => {
                    line_width = *w;
                }

                // ── Transform stack ──────────────────────────────────────
                RenderCommand::PushTransform => {
                    let top = *transform_stack.last().unwrap();
                    transform_stack.push(top);
                }
                RenderCommand::PopTransform => {
                    if transform_stack.len() > 1 {
                        transform_stack.pop();
                    }
                }
                RenderCommand::Translate { x, y } => {
                    let m = Mat3::from_translation(Vec2 { x: *x, y: *y });
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                RenderCommand::Rotate { angle } => {
                    let m = Mat3::from_rotation(*angle);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                RenderCommand::Scale { sx, sy } => {
                    let m = Mat3::from_scale(Vec2 { x: *sx, y: *sy });
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                RenderCommand::Shear { kx, ky } => {
                    let m = Mat3::from_shear(*kx, *ky);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                RenderCommand::Origin => {
                    let top = transform_stack.last_mut().unwrap();
                    *top = Mat3::identity();
                }
                RenderCommand::ApplyTransform { matrix } => {
                    let m = Mat3::from_row_major(matrix);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }

                RenderCommand::Rectangle { mode, x, y, w, h } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_rect(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x,
                        *y,
                        *w,
                        *h,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::RoundedRectangle {
                    mode,
                    x,
                    y,
                    w,
                    h,
                    rx,
                    ry,
                } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_rounded_rect(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x,
                        *y,
                        *w,
                        *h,
                        *rx,
                        *ry,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Circle { mode, x, y, r } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_ellipse(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x,
                        *y,
                        *r,
                        *r,
                        32,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Ellipse { mode, x, y, rx, ry } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_ellipse(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x,
                        *y,
                        *rx,
                        *ry,
                        32,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Triangle {
                    mode,
                    x1,
                    y1,
                    x2,
                    y2,
                    x3,
                    y3,
                } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_triangle(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x1,
                        *y1,
                        *x2,
                        *y2,
                        *x3,
                        *y3,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Polygon { mode, vertices } => {
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_polygon(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        vertices,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Line { x1, y1, x2, y2 } => {
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    push_thick_line(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        *x1,
                        *y1,
                        *x2,
                        *y2,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::Polyline { points } => {
                    if points.len() >= 4 {
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::new();
                        let mut idxs = Vec::new();
                        let mut i = 0;
                        while i + 3 < points.len() {
                            push_thick_line(
                                &mut verts,
                                &mut idxs,
                                t,
                                current_color,
                                points[i],
                                points[i + 1],
                                points[i + 2],
                                points[i + 3],
                                line_width,
                            );
                            i += 2;
                        }
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_color_draw(
                            &mut draws,
                            &mut all_color_verts,
                            &mut all_color_idxs,
                            current_target,
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }
                RenderCommand::Arc {
                    mode,
                    x,
                    y,
                    radius,
                    angle1,
                    angle2,
                    segments,
                } => {
                    let t = transform_stack.last().unwrap();
                    let segs = if *segments == 0 { 32 } else { *segments };
                    let mode = if wireframe { &DrawMode::Line } else { mode };
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    self.tess_arc(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        mode,
                        *x,
                        *y,
                        *radius,
                        *angle1,
                        *angle2,
                        segs,
                        line_width,
                    );
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }

                RenderCommand::SetBlendMode(mode) => {
                    current_blend_mode = *mode;
                }

                RenderCommand::Print {
                    font_key,
                    ref text,
                    x,
                    y,
                    scale,
                } => {
                    if let Some(font) = fonts.get_mut(*font_key) {
                        if self.ensure_font_atlas(*font_key, font, default_filter) {
                            let t = transform_stack.last().unwrap();
                            let font_size = font.size();
                            let ratio = *scale;
                            let (target_width, target_height) =
                                self.target_dimensions(current_target, canvases);
                            let scissor =
                                normalize_scissor(current_scissor, target_width, target_height);

                            let mut cursor_x = *x;
                            for ch in text.chars() {
                                if let Some(glyph) = font.glyph(ch) {
                                    if glyph.width > 0 && glyph.height > 0 {
                                        let gw = glyph.width as f32 * ratio;
                                        let gh = glyph.height as f32 * ratio;
                                        let gx = cursor_x + glyph.offset_x * ratio;
                                        let gy = *y
                                            + (font_size - glyph.offset_y - glyph.height as f32)
                                                * ratio;

                                        let mut verts = Vec::with_capacity(4);
                                        let mut idxs = Vec::with_capacity(6);
                                        push_tex_quad(
                                            &mut verts,
                                            &mut idxs,
                                            t,
                                            current_color,
                                            gx,
                                            gy,
                                            0.0,
                                            1.0,
                                            1.0,
                                            0.0,
                                            0.0,
                                            gw,
                                            gh,
                                            glyph.uv_x,
                                            glyph.uv_y,
                                            glyph.uv_x + glyph.uv_w,
                                            glyph.uv_y + glyph.uv_h,
                                        );
                                        append_tex_draw(
                                            &mut draws,
                                            &mut all_tex_verts,
                                            &mut all_tex_idxs,
                                            current_target,
                                            TexRef::FontAtlas(*font_key),
                                            current_blend_mode,
                                            scissor,
                                            color_mask_bits,
                                            active_shader.filter(|key| shaders.contains_key(*key)),
                                            stencil_mode,
                                            stencil_reference,
                                            verts,
                                            idxs,
                                        );
                                    }
                                    cursor_x += glyph.advance_width * ratio;
                                }
                            }
                        }
                    }
                }

                RenderCommand::DrawImage {
                    texture_key,
                    x,
                    y,
                    effect: _,
                } => {
                    if let Some(gt) = self.gpu_textures.get(*texture_key) {
                        let w = gt.width as f32;
                        let h = gt.height as f32;
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::with_capacity(4);
                        let mut idxs = Vec::with_capacity(6);
                        push_tex_quad(
                            &mut verts,
                            &mut idxs,
                            t,
                            current_color,
                            *x,
                            *y,
                            0.0,
                            1.0,
                            1.0,
                            0.0,
                            0.0,
                            w,
                            h,
                            0.0,
                            0.0,
                            1.0,
                            1.0,
                        );
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Texture(*texture_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }
                RenderCommand::DrawImageEx {
                    texture_key,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                    effect: _,
                } => {
                    if let Some(gt) = self.gpu_textures.get(*texture_key) {
                        let w = gt.width as f32;
                        let h = gt.height as f32;
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::with_capacity(4);
                        let mut idxs = Vec::with_capacity(6);
                        push_tex_quad(
                            &mut verts,
                            &mut idxs,
                            t,
                            current_color,
                            *x,
                            *y,
                            *rotation,
                            *sx,
                            *sy,
                            *ox,
                            *oy,
                            w,
                            h,
                            0.0,
                            0.0,
                            1.0,
                            1.0,
                        );
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Texture(*texture_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }
                RenderCommand::DrawQuad {
                    texture_key,
                    quad_x,
                    quad_y,
                    quad_w,
                    quad_h,
                    tex_w,
                    tex_h,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                    effect: _,
                } => {
                    if let Some(_gt) = self.gpu_textures.get(*texture_key) {
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::with_capacity(4);
                        let mut idxs = Vec::with_capacity(6);
                        let u0 = quad_x / tex_w;
                        let v0 = quad_y / tex_h;
                        let u1 = (quad_x + quad_w) / tex_w;
                        let v1 = (quad_y + quad_h) / tex_h;
                        push_tex_quad(
                            &mut verts,
                            &mut idxs,
                            t,
                            current_color,
                            *x,
                            *y,
                            *rotation,
                            *sx,
                            *sy,
                            *ox,
                            *oy,
                            *quad_w,
                            *quad_h,
                            u0,
                            v0,
                            u1,
                            v1,
                        );
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Texture(*texture_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }

                RenderCommand::DrawTexturedQuad {
                    corners,
                    uvs,
                    texture_key,
                    color,
                } => {
                    if self.gpu_textures.contains_key(*texture_key) {
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::with_capacity(4);
                        let mut idxs = Vec::with_capacity(6);
                        push_tex_quad_corners(&mut verts, &mut idxs, t, *color, corners, uvs);
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Texture(*texture_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }

                RenderCommand::DrawBatch { batch_key } => {
                    if let Some(batch) = sprite_batches.get(*batch_key) {
                        let tex_key = batch.texture_key();
                        if let Some(gt) = self.gpu_textures.get(tex_key) {
                            let tex_w = gt.width as f32;
                            let tex_h = gt.height as f32;
                            let t = transform_stack.last().unwrap();
                            let mut verts = Vec::with_capacity(batch.len() * 4);
                            let mut idxs = Vec::with_capacity(batch.len() * 6);
                            for entry in batch.entries() {
                                let u0 = entry.quad_x / tex_w;
                                let v0 = entry.quad_y / tex_h;
                                let u1 = (entry.quad_x + entry.quad_w) / tex_w;
                                let v1 = (entry.quad_y + entry.quad_h) / tex_h;
                                push_tex_quad(
                                    &mut verts,
                                    &mut idxs,
                                    t,
                                    current_color,
                                    entry.x,
                                    entry.y,
                                    entry.rotation,
                                    entry.sx,
                                    entry.sy,
                                    entry.ox,
                                    entry.oy,
                                    entry.quad_w,
                                    entry.quad_h,
                                    u0,
                                    v0,
                                    u1,
                                    v1,
                                );
                            }
                            let (target_width, target_height) =
                                self.target_dimensions(current_target, canvases);
                            append_tex_draw(
                                &mut draws,
                                &mut all_tex_verts,
                                &mut all_tex_idxs,
                                current_target,
                                TexRef::Texture(tex_key),
                                current_blend_mode,
                                normalize_scissor(current_scissor, target_width, target_height),
                                color_mask_bits,
                                active_shader.filter(|key| shaders.contains_key(*key)),
                                stencil_mode,
                                stencil_reference,
                                verts,
                                idxs,
                            );
                        }
                    }
                }
                RenderCommand::SetCanvas(canvas) => {
                    current_target = match canvas {
                        Some(key) => RenderTargetId::Canvas(*key),
                        None => RenderTargetId::Screen,
                    };
                    self.render_stats.canvas_switches += 1;
                }
                RenderCommand::RegisterCanvas { .. } => {}
                RenderCommand::DrawCanvas {
                    canvas_key,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                } => {
                    if let Some(gt) = self.canvas_gpu_textures.get(*canvas_key) {
                        let w = gt.width as f32;
                        let h = gt.height as f32;
                        let t = transform_stack.last().unwrap();
                        let mut verts = Vec::with_capacity(4);
                        let mut idxs = Vec::with_capacity(6);
                        push_tex_quad(
                            &mut verts,
                            &mut idxs,
                            t,
                            current_color,
                            *x,
                            *y,
                            *rotation,
                            *sx,
                            *sy,
                            *ox,
                            *oy,
                            w,
                            h,
                            0.0,
                            0.0,
                            1.0,
                            1.0,
                        );
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Canvas(*canvas_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }
                RenderCommand::SetPointSize(size) => {
                    point_size = *size;
                }

                RenderCommand::SetScissor(rect) => {
                    current_scissor = *rect;
                }

                RenderCommand::SetColorMask(r, g, b, a) => {
                    color_mask_bits = color_write_mask_bits((*r, *g, *b, *a));
                }

                RenderCommand::SetWireframe(enabled) => {
                    wireframe = *enabled;
                }

                RenderCommand::Points { points } => {
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    let half = point_size * 0.5;
                    for &(px, py) in points {
                        let pts = [
                            apply(t, px - half, py - half),
                            apply(t, px + half, py - half),
                            apply(t, px + half, py + half),
                            apply(t, px - half, py + half),
                        ];
                        push_quad_verts(&mut verts, &mut idxs, &pts, current_color);
                    }
                    let (target_width, target_height) =
                        self.target_dimensions(current_target, canvases);
                    append_color_draw(
                        &mut draws,
                        &mut all_color_verts,
                        &mut all_color_idxs,
                        current_target,
                        current_blend_mode,
                        normalize_scissor(current_scissor, target_width, target_height),
                        color_mask_bits,
                        active_shader.filter(|key| shaders.contains_key(*key)),
                        stencil_mode,
                        stencil_reference,
                        verts,
                        idxs,
                    );
                }
                RenderCommand::PrintFormatted {
                    font_key,
                    ref text,
                    x,
                    y,
                    limit,
                    align,
                    scale,
                } => {
                    if let Some(font) = fonts.get_mut(*font_key) {
                        let ratio = *scale;
                        let wrapped = font.wrap_text(text, *limit / ratio);
                        let lh = font.line_height() * ratio;
                        let font_size = font.size();

                        if self.ensure_font_atlas(*font_key, font, default_filter) {
                            let t = transform_stack.last().unwrap();
                            let (target_width, target_height) =
                                self.target_dimensions(current_target, canvases);
                            let scissor =
                                normalize_scissor(current_scissor, target_width, target_height);
                            for (i, line) in wrapped.iter().enumerate() {
                                let line_w = font.text_width(line) * ratio;
                                let x_offset = match align {
                                    TextAlign::Center => (*limit - line_w) * 0.5,
                                    TextAlign::Right => *limit - line_w,
                                    _ => 0.0,
                                };
                                let line_x = *x + x_offset;
                                let line_y = *y + i as f32 * lh;

                                let mut cursor_x = line_x;
                                for ch in line.chars() {
                                    if let Some(glyph) = font.glyph(ch) {
                                        if glyph.width > 0 && glyph.height > 0 {
                                            let gw = glyph.width as f32 * ratio;
                                            let gh = glyph.height as f32 * ratio;
                                            let gx = cursor_x + glyph.offset_x * ratio;
                                            let gy = line_y
                                                + (font_size
                                                    - glyph.offset_y
                                                    - glyph.height as f32)
                                                    * ratio;

                                            let mut verts = Vec::with_capacity(4);
                                            let mut idxs = Vec::with_capacity(6);
                                            push_tex_quad(
                                                &mut verts,
                                                &mut idxs,
                                                t,
                                                current_color,
                                                gx,
                                                gy,
                                                0.0,
                                                1.0,
                                                1.0,
                                                0.0,
                                                0.0,
                                                gw,
                                                gh,
                                                glyph.uv_x,
                                                glyph.uv_y,
                                                glyph.uv_x + glyph.uv_w,
                                                glyph.uv_y + glyph.uv_h,
                                            );
                                            append_tex_draw(
                                                &mut draws,
                                                &mut all_tex_verts,
                                                &mut all_tex_idxs,
                                                current_target,
                                                TexRef::FontAtlas(*font_key),
                                                current_blend_mode,
                                                scissor,
                                                color_mask_bits,
                                                active_shader
                                                    .filter(|key| shaders.contains_key(*key)),
                                                stencil_mode,
                                                stencil_reference,
                                                verts,
                                                idxs,
                                            );
                                        }
                                        cursor_x += glyph.advance_width * ratio;
                                    }
                                }
                            }
                        }
                    }
                }

                RenderCommand::StencilBegin { action, value } => {
                    stencil_mode = StencilMode::Write(*action);
                    stencil_reference = *value;
                }
                RenderCommand::StencilEnd => {
                    stencil_mode = StencilMode::Disabled;
                }
                RenderCommand::SetStencilTest(test) => match test {
                    Some((compare, value)) => {
                        stencil_mode = StencilMode::Test(*compare);
                        stencil_reference = *value;
                    }
                    None => {
                        stencil_mode = StencilMode::Disabled;
                        stencil_reference = 0;
                    }
                },
                RenderCommand::DrawMesh {
                    mesh_key,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                } => {
                    if let Some(mesh) = meshes.get(*mesh_key) {
                        let cos_r = rotation.cos();
                        let sin_r = rotation.sin();
                        let parent = transform_stack.last().unwrap();
                        let tri_indices = mesh.triangulate();

                        if let Some(tex_key) = mesh.texture {
                            if self.gpu_textures.contains_key(tex_key) {
                                let mut verts = Vec::with_capacity(tri_indices.len());
                                let mut idxs = Vec::with_capacity(tri_indices.len());
                                let base_idx = 0u32;
                                for (i, &vi) in tri_indices.iter().enumerate() {
                                    if let Some(mv) = mesh.vertices.get(vi) {
                                        let lx = (mv.x - ox) * sx;
                                        let ly = (mv.y - oy) * sy;
                                        let rx = lx * cos_r - ly * sin_r + x;
                                        let ry = lx * sin_r + ly * cos_r + y;
                                        let (wx, wy) = apply(parent, rx, ry);
                                        verts.push(TexVertex {
                                            position: [wx, wy],
                                            uv: [mv.u, mv.v],
                                            color: [
                                                mv.r * current_color[0],
                                                mv.g * current_color[1],
                                                mv.b * current_color[2],
                                                mv.a * current_color[3],
                                            ],
                                        });
                                        idxs.push(base_idx + i as u32);
                                    }
                                }
                                let (target_width, target_height) =
                                    self.target_dimensions(current_target, canvases);
                                append_tex_draw(
                                    &mut draws,
                                    &mut all_tex_verts,
                                    &mut all_tex_idxs,
                                    current_target,
                                    TexRef::Texture(tex_key),
                                    current_blend_mode,
                                    normalize_scissor(current_scissor, target_width, target_height),
                                    color_mask_bits,
                                    active_shader.filter(|key| shaders.contains_key(*key)),
                                    stencil_mode,
                                    stencil_reference,
                                    verts,
                                    idxs,
                                );
                            }
                        } else {
                            let mut verts = Vec::with_capacity(tri_indices.len());
                            let mut idxs = Vec::with_capacity(tri_indices.len());
                            for &vi in &tri_indices {
                                if let Some(mv) = mesh.vertices.get(vi) {
                                    let lx = (mv.x - ox) * sx;
                                    let ly = (mv.y - oy) * sy;
                                    let rx = lx * cos_r - ly * sin_r + x;
                                    let ry = lx * sin_r + ly * cos_r + y;
                                    let (wx, wy) = apply(parent, rx, ry);
                                    let base = verts.len() as u32;
                                    verts.push(ColorVertex {
                                        position: [wx, wy],
                                        color: [
                                            mv.r * current_color[0],
                                            mv.g * current_color[1],
                                            mv.b * current_color[2],
                                            mv.a * current_color[3],
                                        ],
                                    });
                                    idxs.push(base);
                                }
                            }
                            let (target_width, target_height) =
                                self.target_dimensions(current_target, canvases);
                            append_color_draw(
                                &mut draws,
                                &mut all_color_verts,
                                &mut all_color_idxs,
                                current_target,
                                current_blend_mode,
                                normalize_scissor(current_scissor, target_width, target_height),
                                color_mask_bits,
                                active_shader.filter(|key| shaders.contains_key(*key)),
                                stencil_mode,
                                stencil_reference,
                                verts,
                                idxs,
                            );
                        }
                    }
                }
                RenderCommand::SyncMesh { .. } => {}
                RenderCommand::DrawNineSlice {
                    texture_key,
                    tex_w,
                    tex_h,
                    top,
                    right,
                    bottom,
                    left,
                    x,
                    y,
                    w,
                    h,
                } => {
                    if self.gpu_textures.get(*texture_key).is_some() {
                        let t = transform_stack.last().unwrap();
                        let ns = crate::sprite::NineSlice::new(
                            *texture_key,
                            *top,
                            *right,
                            *bottom,
                            *left,
                            *tex_w,
                            *tex_h,
                        );
                        let patches = ns.patches(*x, *y, *w, *h);
                        let mut verts = Vec::with_capacity(4 * 9);
                        let mut idxs = Vec::with_capacity(6 * 9);
                        for &(sx, sy, sw, sh, dx, dy, dw, dh) in &patches {
                            if sw <= 0.0 || sh <= 0.0 || dw <= 0.0 || dh <= 0.0 {
                                continue;
                            }
                            let u0 = sx / tex_w;
                            let v0 = sy / tex_h;
                            let u1 = (sx + sw) / tex_w;
                            let v1 = (sy + sh) / tex_h;
                            push_tex_quad(
                                &mut verts,
                                &mut idxs,
                                t,
                                current_color,
                                dx,
                                dy,
                                0.0, // no rotation
                                1.0, // sx
                                1.0, // sy
                                0.0, // ox
                                0.0, // oy
                                dw,
                                dh,
                                u0,
                                v0,
                                u1,
                                v1,
                            );
                        }
                        let (target_width, target_height) =
                            self.target_dimensions(current_target, canvases);
                        append_tex_draw(
                            &mut draws,
                            &mut all_tex_verts,
                            &mut all_tex_idxs,
                            current_target,
                            TexRef::Texture(*texture_key),
                            current_blend_mode,
                            normalize_scissor(current_scissor, target_width, target_height),
                            color_mask_bits,
                            active_shader.filter(|key| shaders.contains_key(*key)),
                            stencil_mode,
                            stencil_reference,
                            verts,
                            idxs,
                        );
                    }
                }
                RenderCommand::SetShader(shader) => {
                    active_shader = shader.filter(|key| shaders.contains_key(*key));
                }
                // DrawShape and DrawParticleSystem are not yet GPU-implemented;
                // silence non-exhaustive-pattern error until renderer support is added.
                RenderCommand::DrawShape { .. } => {}
                RenderCommand::DrawParticleSystem { .. } => {}
                // Post-FX capture/apply are managed by the PostFxStack at a higher level;
                // the GPU renderer acknowledges these commands but does not process them here.
                RenderCommand::BeginPostFx { .. } => {}
                RenderCommand::EndPostFx { .. } => {}
                RenderCommand::ApplyPostFx { .. } => {}
            }
        }

        // ── Draw-call coalescing ─────────────────────────────────────────────
        // Merge adjacent PreparedDraw entries that share identical GPU state
        // and have contiguous index ranges.  This reduces the number of draw
        // calls dispatched per frame without altering draw order.
        {
            let before = draws.len();
            let mut merged = Vec::with_capacity(draws.len());
            for d in draws {
                if let Some(last) = merged.last_mut() {
                    let l: &mut PreparedDraw = last;
                    if l.target == d.target
                        && l.geometry == d.geometry
                        && l.texture_ref == d.texture_ref
                        && l.blend_mode == d.blend_mode
                        && l.scissor == d.scissor
                        && l.color_mask_bits == d.color_mask_bits
                        && l.shader == d.shader
                        && l.stencil_mode == d.stencil_mode
                        && l.stencil_reference == d.stencil_reference
                        && d.idx_start == l.idx_start + l.idx_count
                    {
                        l.idx_count += d.idx_count;
                        continue;
                    }
                }
                merged.push(d);
            }
            let after = merged.len();
            if before > after {
                self.render_stats.batched_draws += (before - after) as u32;
            }
            draws = merged;
        }

        // Write geometry data to GPU buffers.
        if !all_color_verts.is_empty() {
            self.queue.write_buffer(
                &self.color_vertex_buffer,
                0,
                bytemuck::cast_slice(&all_color_verts),
            );
            self.queue.write_buffer(
                &self.color_index_buffer,
                0,
                bytemuck::cast_slice(&all_color_idxs),
            );
        }
        if !all_tex_verts.is_empty() {
            self.queue.write_buffer(
                &self.tex_vertex_buffer,
                0,
                bytemuck::cast_slice(&all_tex_verts),
            );
            self.queue.write_buffer(
                &self.tex_index_buffer,
                0,
                bytemuck::cast_slice(&all_tex_idxs),
            );
        }

        let output = surface.get_current_texture()?;
        let view = output
            .texture
            .create_view(&wgpu::TextureViewDescriptor::default());
        self.ensure_screen_stencil_target();
        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("render_encoder"),
            });

        let mut screen_started = false;
        let mut touched_canvases: HashSet<CanvasKey> = HashSet::new();
        let mut cursor = 0usize;

        while cursor < draws.len() {
            let target = draws[cursor].target;
            match target {
                RenderTargetId::Screen => {}
                RenderTargetId::Canvas(key) => {
                    let Some(canvas) = canvases.get(key) else {
                        while cursor < draws.len() && draws[cursor].target == target {
                            cursor += 1;
                        }
                        continue;
                    };
                    self.ensure_canvas_stencil_target(key, canvas.width, canvas.height);
                }
            }

            let (target_width, target_height) = self.target_dimensions(target, canvases);
            self.update_viewport_uniform(target_width, target_height, camera_matrix, frame_time);

            let (color_view, color_load, stencil_view, stencil_load, clear_canvas_after_pass) =
                match target {
                    RenderTargetId::Screen => {
                        let stencil_view = &self.screen_stencil_target.as_ref().unwrap().view;
                        let color_load = if screen_started {
                            wgpu::LoadOp::Load
                        } else {
                            wgpu::LoadOp::Clear(wgpu::Color {
                                r: background_color[0] as f64,
                                g: background_color[1] as f64,
                                b: background_color[2] as f64,
                                a: background_color[3] as f64,
                            })
                        };
                        let stencil_load = if screen_started {
                            wgpu::LoadOp::Load
                        } else {
                            wgpu::LoadOp::Clear(0)
                        };
                        (&view, color_load, stencil_view, stencil_load, None)
                    }
                    RenderTargetId::Canvas(key) => {
                        let canvas_view = &self.canvas_gpu_textures.get(key).unwrap().view;
                        let stencil_view = &self.canvas_stencil_targets.get(key).unwrap().view;
                        let first_use_this_frame = touched_canvases.insert(key);
                        let needs_clear = self.canvas_needs_clear.get(key).copied().unwrap_or(true);
                        let color_load = if needs_clear {
                            wgpu::LoadOp::Clear(wgpu::Color::TRANSPARENT)
                        } else {
                            wgpu::LoadOp::Load
                        };
                        let stencil_load = if first_use_this_frame {
                            wgpu::LoadOp::Clear(0)
                        } else {
                            wgpu::LoadOp::Load
                        };
                        (
                            canvas_view,
                            color_load,
                            stencil_view,
                            stencil_load,
                            if needs_clear { Some(key) } else { None },
                        )
                    }
                };

            {
                let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("ordered_render_pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: color_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: color_load,
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: Some(wgpu::RenderPassDepthStencilAttachment {
                        view: stencil_view,
                        depth_ops: None,
                        stencil_ops: Some(wgpu::Operations {
                            load: stencil_load,
                            store: wgpu::StoreOp::Store,
                        }),
                    }),
                    ..Default::default()
                });

                let mut previous_pipeline: Option<PipelineSelectionKey> = None;
                let mut previous_texture: Option<TexRef> = None;

                while cursor < draws.len() && draws[cursor].target == target {
                    let draw = draws[cursor];
                    let pipeline_key = self.pipeline_selection_key(draw);
                    if previous_pipeline != Some(pipeline_key) {
                        self.render_stats.shader_switches += 1;
                        previous_pipeline = Some(pipeline_key);
                    }
                    if draw.geometry == GeometryKind::Texture
                        && previous_texture != draw.texture_ref
                    {
                        self.render_stats.texture_switches += 1;
                        previous_texture = draw.texture_ref;
                    }
                    if self.issue_draw(&mut pass, draw, shaders) {
                        self.render_stats.draw_calls += 1;
                    }
                    cursor += 1;
                }
            }

            if let Some(key) = clear_canvas_after_pass {
                self.canvas_needs_clear.insert(key, false);
            }
            if target == RenderTargetId::Screen {
                screen_started = true;
            }
        }

        if !screen_started {
            self.update_viewport_uniform(self.width, self.height, camera_matrix, frame_time);
            let screen_stencil_view = &self.screen_stencil_target.as_ref().unwrap().view;
            let _pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                label: Some("screen_clear_pass"),
                color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                    view: &view,
                    resolve_target: None,
                    ops: wgpu::Operations {
                        load: wgpu::LoadOp::Clear(wgpu::Color {
                            r: background_color[0] as f64,
                            g: background_color[1] as f64,
                            b: background_color[2] as f64,
                            a: background_color[3] as f64,
                        }),
                        store: wgpu::StoreOp::Store,
                    },
                })],
                depth_stencil_attachment: Some(wgpu::RenderPassDepthStencilAttachment {
                    view: screen_stencil_view,
                    depth_ops: None,
                    stencil_ops: Some(wgpu::Operations {
                        load: wgpu::LoadOp::Clear(0),
                        store: wgpu::StoreOp::Store,
                    }),
                }),
                ..Default::default()
            });
        }

        // ====== LIGHT RENDERING PASS ======
        if light_world.enabled && !light_world.lights.is_empty() {
            self.ensure_light_resources();

            // ── Compute 1D shadow maps for shadow-enabled lights ──
            let mut shadow_row = 0usize;
            // Pre-collect occluders to avoid borrow issues.
            let occluder_list: Vec<&crate::light::occluder::Occluder> =
                light_world.occluders.values().collect();

            // Map from light SlotMap index → shadow atlas row (None = no shadow).
            let mut light_shadow_rows: Vec<Option<usize>> = Vec::new();
            // CPU shadow data rows to upload.
            let mut shadow_rows_data: Vec<(usize, Vec<f32>)> = Vec::new();

            for (_, light) in light_world.lights.iter() {
                if !light.enabled || light.radius * light.energy <= 0.0 {
                    light_shadow_rows.push(None);
                    continue;
                }
                if light.shadow_enabled && shadow_row < MAX_SHADOW_LIGHTS {
                    let map = compute_1d_shadow_map(
                        light.x,
                        light.y,
                        light.radius * light.energy,
                        light.shadow_mask,
                        occluder_list.iter().copied(),
                    );
                    shadow_rows_data.push((shadow_row, map));
                    light_shadow_rows.push(Some(shadow_row));
                    shadow_row += 1;
                } else {
                    light_shadow_rows.push(None);
                }
            }

            // Upload shadow atlas rows to GPU.
            if let Some(lg) = self.light_gpu.as_ref() {
                for (row, data) in &shadow_rows_data {
                    self.queue.write_texture(
                        wgpu::ImageCopyTexture {
                            texture: &lg.shadow_atlas_texture,
                            mip_level: 0,
                            origin: wgpu::Origin3d {
                                x: 0,
                                y: *row as u32,
                                z: 0,
                            },
                            aspect: wgpu::TextureAspect::All,
                        },
                        bytemuck::cast_slice(data),
                        wgpu::ImageDataLayout {
                            offset: 0,
                            bytes_per_row: Some((SHADOW_MAP_RES * 4) as u32),
                            rows_per_image: None,
                        },
                        wgpu::Extent3d {
                            width: SHADOW_MAP_RES as u32,
                            height: 1,
                            depth_or_array_layers: 1,
                        },
                    );
                }
            }

            // ── Tessellate one quad per enabled light ──
            let mut light_verts: Vec<LightVertex> = Vec::new();
            let mut light_idxs: Vec<u32> = Vec::new();
            let mut light_count = 0usize;
            let atlas_height = MAX_SHADOW_LIGHTS as f32;

            for ((_, light), shadow_opt) in light_world.lights.iter().zip(light_shadow_rows.iter())
            {
                if !light.enabled {
                    continue;
                }
                if light_count >= MAX_LIGHT_QUADS {
                    break;
                }
                let r = light.radius * light.energy;
                if r <= 0.0 {
                    continue;
                }
                let ci = light.intensity * light.energy;
                let c = [
                    light.color.r * ci,
                    light.color.g * ci,
                    light.color.b * ci,
                    1.0,
                ];
                let sv = match shadow_opt {
                    Some(row) => (*row as f32 + 0.5) / atlas_height,
                    None => -1.0,
                };

                let base = light_verts.len() as u32;
                light_verts.push(LightVertex {
                    position: [light.x - r, light.y - r],
                    uv: [0.0, 0.0],
                    color: c,
                    shadow_v: sv,
                    _pad: [0.0; 3],
                });
                light_verts.push(LightVertex {
                    position: [light.x + r, light.y - r],
                    uv: [1.0, 0.0],
                    color: c,
                    shadow_v: sv,
                    _pad: [0.0; 3],
                });
                light_verts.push(LightVertex {
                    position: [light.x + r, light.y + r],
                    uv: [1.0, 1.0],
                    color: c,
                    shadow_v: sv,
                    _pad: [0.0; 3],
                });
                light_verts.push(LightVertex {
                    position: [light.x - r, light.y + r],
                    uv: [0.0, 1.0],
                    color: c,
                    shadow_v: sv,
                    _pad: [0.0; 3],
                });
                light_idxs.extend_from_slice(&[base, base + 1, base + 2, base, base + 2, base + 3]);
                light_count += 1;
            }

            // ── Composite full-screen quad (screen-space) ──
            let composite_base = light_verts.len() as u32;
            let sw = self.width as f32;
            let sh = self.height as f32;
            light_verts.push(LightVertex {
                position: [0.0, 0.0],
                uv: [0.0, 0.0],
                color: [1.0; 4],
                shadow_v: -1.0,
                _pad: [0.0; 3],
            });
            light_verts.push(LightVertex {
                position: [sw, 0.0],
                uv: [1.0, 0.0],
                color: [1.0; 4],
                shadow_v: -1.0,
                _pad: [0.0; 3],
            });
            light_verts.push(LightVertex {
                position: [sw, sh],
                uv: [1.0, 1.0],
                color: [1.0; 4],
                shadow_v: -1.0,
                _pad: [0.0; 3],
            });
            light_verts.push(LightVertex {
                position: [0.0, sh],
                uv: [0.0, 1.0],
                color: [1.0; 4],
                shadow_v: -1.0,
                _pad: [0.0; 3],
            });
            light_idxs.extend_from_slice(&[
                composite_base,
                composite_base + 1,
                composite_base + 2,
                composite_base,
                composite_base + 2,
                composite_base + 3,
            ]);
            let composite_idx_start = (light_count * 6) as u32;

            // ── Upload light geometry ──
            {
                let lg = self.light_gpu.as_ref().unwrap();
                self.queue
                    .write_buffer(&lg.vertex_buffer, 0, bytemuck::cast_slice(&light_verts));
                self.queue
                    .write_buffer(&lg.index_buffer, 0, bytemuck::cast_slice(&light_idxs));
            }

            // ── Pass 1: Accumulate lights onto the light buffer ──
            // Light positions are in world space — the camera matrix transforms
            // them to screen space in the vertex shader, just like scene geometry.
            self.update_viewport_uniform(self.width, self.height, camera_matrix, frame_time);
            {
                let lg = self.light_gpu.as_ref().unwrap();
                let ambient = &light_world.ambient;
                let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("light_accum_pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &lg.accum_view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color {
                                r: ambient.r as f64,
                                g: ambient.g as f64,
                                b: ambient.b as f64,
                                a: 1.0,
                            }),
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    ..Default::default()
                });

                if light_count > 0 {
                    pass.set_pipeline(&lg.additive_pipeline);
                    pass.set_bind_group(0, &self.viewport_bind_group, &[]);
                    pass.set_bind_group(1, &lg.shadow_atlas_bind_group, &[]);
                    pass.set_vertex_buffer(0, lg.vertex_buffer.slice(..));
                    pass.set_index_buffer(lg.index_buffer.slice(..), wgpu::IndexFormat::Uint32);
                    pass.draw_indexed(0..(light_count * 6) as u32, 0, 0..1);
                }
            }

            // ── Pass 2: Composite light buffer over scene (multiply blend) ──
            // Use identity camera so the full-screen quad maps 1:1 to pixels.
            self.update_viewport_uniform(self.width, self.height, &Mat3::identity(), frame_time);
            {
                let lg = self.light_gpu.as_ref().unwrap();
                let screen_stencil_view = &self.screen_stencil_target.as_ref().unwrap().view;
                let mut pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("light_composite_pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Load,
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: Some(wgpu::RenderPassDepthStencilAttachment {
                        view: screen_stencil_view,
                        depth_ops: None,
                        stencil_ops: Some(wgpu::Operations {
                            load: wgpu::LoadOp::Load,
                            store: wgpu::StoreOp::Store,
                        }),
                    }),
                    ..Default::default()
                });

                pass.set_pipeline(&lg.composite_pipeline);
                pass.set_bind_group(0, &self.viewport_bind_group, &[]);
                pass.set_bind_group(1, &lg.accum_bind_group, &[]);
                pass.set_vertex_buffer(0, lg.vertex_buffer.slice(..));
                pass.set_index_buffer(lg.index_buffer.slice(..), wgpu::IndexFormat::Uint32);
                pass.set_scissor_rect(0, 0, self.width, self.height);
                pass.set_stencil_reference(0);
                pass.draw_indexed(composite_idx_start..composite_idx_start + 6, 0, 0..1);
            }

            // Restore camera viewport for any subsequent passes.
            self.update_viewport_uniform(self.width, self.height, camera_matrix, frame_time);
        }
        // ==================================

        let pending_readback = if capture_screenshot {
            self.begin_surface_readback(&mut encoder, &output.texture, self.width, self.height)
        } else {
            None
        };

        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();
        Ok(pending_readback.and_then(|readback| self.complete_surface_readback(readback)))
    }

    fn begin_surface_readback(
        &self,
        encoder: &mut wgpu::CommandEncoder,
        texture: &wgpu::Texture,
        width: u32,
        height: u32,
    ) -> Option<PendingSurfaceReadback> {
        if width == 0 || height == 0 {
            log_msg!(error, G002_SCREENSHOT_ZERO_SIZE);
            return None;
        }

        let unpadded_bytes_per_row = width.saturating_mul(4);
        let alignment = wgpu::COPY_BYTES_PER_ROW_ALIGNMENT;
        let padded_bytes_per_row = unpadded_bytes_per_row.div_ceil(alignment) * alignment;
        let buffer_size = padded_bytes_per_row as u64 * height as u64;

        let buffer = self.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("surface_readback_buffer"),
            size: buffer_size,
            usage: wgpu::BufferUsages::COPY_DST | wgpu::BufferUsages::MAP_READ,
            mapped_at_creation: false,
        });

        encoder.copy_texture_to_buffer(
            wgpu::ImageCopyTexture {
                texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All,
            },
            wgpu::ImageCopyBuffer {
                buffer: &buffer,
                layout: wgpu::ImageDataLayout {
                    offset: 0,
                    bytes_per_row: Some(padded_bytes_per_row),
                    rows_per_image: Some(height),
                },
            },
            wgpu::Extent3d {
                width,
                height,
                depth_or_array_layers: 1,
            },
        );

        Some(PendingSurfaceReadback {
            buffer,
            padded_bytes_per_row,
            width,
            height,
        })
    }

    fn complete_surface_readback(
        &self,
        readback: PendingSurfaceReadback,
    ) -> Option<(u32, u32, Vec<u8>)> {
        let slice = readback.buffer.slice(..);
        let (sender, receiver) = mpsc::channel();

        slice.map_async(wgpu::MapMode::Read, move |result| {
            let _ = sender.send(result.map_err(|err| err.to_string()));
        });

        let _ = self.device.poll(wgpu::Maintain::Wait);
        match receiver.recv() {
            Ok(Ok(())) => {}
            Ok(Err(err)) => {
                log_msg!(error, G003_SCREENSHOT_MAP_FAIL, "{}", err);
                return None;
            }
            Err(err) => {
                log_msg!(error, G004_SCREENSHOT_RECV_FAIL, "{}", err);
                return None;
            }
        }

        let mut pixels = vec![0u8; (readback.width * readback.height * 4) as usize];
        {
            let mapped = slice.get_mapped_range();
            let row_len = (readback.width * 4) as usize;
            for row in 0..readback.height as usize {
                let src_start = row * readback.padded_bytes_per_row as usize;
                let dst_start = row * row_len;
                pixels[dst_start..dst_start + row_len]
                    .copy_from_slice(&mapped[src_start..src_start + row_len]);
            }
        }
        readback.buffer.unmap();

        match self.surface_format {
            wgpu::TextureFormat::Bgra8Unorm | wgpu::TextureFormat::Bgra8UnormSrgb => {
                for pixel in pixels.chunks_exact_mut(4) {
                    pixel.swap(0, 2);
                }
            }
            wgpu::TextureFormat::Rgba8Unorm | wgpu::TextureFormat::Rgba8UnormSrgb => {}
            _other => {
                log_msg!(error, G005_SCREENSHOT_DATA_FAIL, "pixel data error");
                return None;
            }
        }

        Some((readback.width, readback.height, pixels))
    }

    fn update_viewport_uniform(
        &mut self,
        width: u32,
        height: u32,
        camera_matrix: &Mat3,
        frame_time: f32,
    ) {
        let data = ViewportUniform {
            size: [width as f32, height as f32],
            time: frame_time,
            _pad: 0.0,
            view_col0: [
                camera_matrix.m[0][0],
                camera_matrix.m[1][0],
                camera_matrix.m[2][0],
                0.0,
            ],
            view_col1: [
                camera_matrix.m[0][1],
                camera_matrix.m[1][1],
                camera_matrix.m[2][1],
                0.0,
            ],
            view_col2: [
                camera_matrix.m[0][2],
                camera_matrix.m[1][2],
                camera_matrix.m[2][2],
                0.0,
            ],
        };
        self.queue
            .write_buffer(&self.viewport_buffer, 0, bytemuck::bytes_of(&data));
    }

    fn target_dimensions(
        &self,
        target: RenderTargetId,
        canvases: &SlotMap<CanvasKey, crate::render::Canvas>,
    ) -> (u32, u32) {
        match target {
            RenderTargetId::Screen => (self.width, self.height),
            RenderTargetId::Canvas(key) => canvases
                .get(key)
                .map(|canvas| (canvas.width, canvas.height))
                .unwrap_or((self.width, self.height)),
        }
    }

    fn target_dimensions_from_gpu(&self, target: RenderTargetId) -> (u32, u32) {
        match target {
            RenderTargetId::Screen => (self.width, self.height),
            RenderTargetId::Canvas(key) => self
                .canvas_gpu_textures
                .get(key)
                .map(|canvas| (canvas.width, canvas.height))
                .unwrap_or((self.width, self.height)),
        }
    }

    fn pipeline_selection_key(&self, draw: PreparedDraw) -> PipelineSelectionKey {
        let geometry = draw.geometry;
        let pipeline = PipelineKey {
            blend_mode: draw.blend_mode,
            color_mask_bits: draw.color_mask_bits,
            stencil_mode: draw.stencil_mode,
        };
        match shader_for_draw(draw) {
            Some(shader) => PipelineSelectionKey::Custom {
                shader,
                geometry,
                pipeline,
            },
            None => PipelineSelectionKey::Default { geometry, pipeline },
        }
    }

    fn default_pipeline(
        &mut self,
        geometry: GeometryKind,
        key: PipelineKey,
    ) -> &wgpu::RenderPipeline {
        let missing = match geometry {
            GeometryKind::Color => !self.default_color_pipelines.contains_key(&key),
            GeometryKind::Texture => !self.default_texture_pipelines.contains_key(&key),
        };

        if missing {
            let pipeline = match geometry {
                GeometryKind::Color => create_render_pipeline(
                    &self.device,
                    self.surface_format,
                    &self.default_color_layout,
                    &self.default_color_shader,
                    geometry,
                    key,
                    "fs_main",
                ),
                GeometryKind::Texture => create_render_pipeline(
                    &self.device,
                    self.surface_format,
                    &self.default_texture_layout,
                    &self.default_texture_shader,
                    geometry,
                    key,
                    "fs_main",
                ),
            };

            match geometry {
                GeometryKind::Color => {
                    self.default_color_pipelines.insert(key, pipeline);
                }
                GeometryKind::Texture => {
                    self.default_texture_pipelines.insert(key, pipeline);
                }
            }
        }

        match geometry {
            GeometryKind::Color => self.default_color_pipelines.get(&key).unwrap(),
            GeometryKind::Texture => self.default_texture_pipelines.get(&key).unwrap(),
        }
    }

    fn ensure_shader_cache(&mut self, shader_key: ShaderKey, shader: &Shader) {
        let ordered_uniforms = shader.ordered_uniforms();
        let uniform_signature: Vec<(String, ShaderUniformKind)> = ordered_uniforms
            .iter()
            .map(|(name, value)| ((*name).to_string(), uniform_kind(value)))
            .collect();

        let needs_rebuild = self
            .shader_cache
            .get(shader_key)
            .map(|cached| {
                cached.source != shader.source || cached.uniform_signature != uniform_signature
            })
            .unwrap_or(true);

        if needs_rebuild {
            let uniform_bind_group_layout = if uniform_signature.is_empty() {
                None
            } else {
                Some(
                    self.device
                        .create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
                            label: Some("custom_shader_uniform_bgl"),
                            entries: &uniform_signature
                                .iter()
                                .enumerate()
                                .map(|(binding, (_, _))| wgpu::BindGroupLayoutEntry {
                                    binding: binding as u32,
                                    visibility: wgpu::ShaderStages::FRAGMENT,
                                    ty: wgpu::BindingType::Buffer {
                                        ty: wgpu::BufferBindingType::Uniform,
                                        has_dynamic_offset: false,
                                        min_binding_size: None,
                                    },
                                    count: None,
                                })
                                .collect::<Vec<_>>(),
                        }),
                )
            };

            let uniform_buffers = uniform_signature
                .iter()
                .map(|_| {
                    self.device.create_buffer(&wgpu::BufferDescriptor {
                        label: Some("custom_shader_uniform_buffer"),
                        size: 16,
                        usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
                        mapped_at_creation: false,
                    })
                })
                .collect::<Vec<_>>();

            let uniform_bind_group = uniform_bind_group_layout.as_ref().map(|layout| {
                self.device.create_bind_group(&wgpu::BindGroupDescriptor {
                    label: Some("custom_shader_uniform_bg"),
                    layout,
                    entries: &uniform_buffers
                        .iter()
                        .enumerate()
                        .map(|(binding, buffer)| wgpu::BindGroupEntry {
                            binding: binding as u32,
                            resource: buffer.as_entire_binding(),
                        })
                        .collect::<Vec<_>>(),
                })
            });

            let color_source = build_custom_color_shader_source(shader, &uniform_signature);
            let texture_source = build_custom_texture_shader_source(shader, &uniform_signature);
            let color_module = self
                .device
                .create_shader_module(wgpu::ShaderModuleDescriptor {
                    label: Some("custom_color_shader"),
                    source: wgpu::ShaderSource::Wgsl(color_source.into()),
                });
            let texture_module = self
                .device
                .create_shader_module(wgpu::ShaderModuleDescriptor {
                    label: Some("custom_texture_shader"),
                    source: wgpu::ShaderSource::Wgsl(texture_source.into()),
                });

            let color_layout = {
                let bind_group_layouts = match uniform_bind_group_layout.as_ref() {
                    Some(uniform_layout) => vec![&self.viewport_bind_group_layout, uniform_layout],
                    None => vec![&self.viewport_bind_group_layout],
                };
                self.device
                    .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                        label: Some("custom_color_layout"),
                        bind_group_layouts: &bind_group_layouts,
                        push_constant_ranges: &[],
                    })
            };
            let texture_layout = {
                let bind_group_layouts = match uniform_bind_group_layout.as_ref() {
                    Some(uniform_layout) => vec![
                        &self.viewport_bind_group_layout,
                        &self.texture_bind_group_layout,
                        uniform_layout,
                    ],
                    None => vec![
                        &self.viewport_bind_group_layout,
                        &self.texture_bind_group_layout,
                    ],
                };
                self.device
                    .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                        label: Some("custom_texture_layout"),
                        bind_group_layouts: &bind_group_layouts,
                        push_constant_ranges: &[],
                    })
            };

            self.shader_cache.insert(
                shader_key,
                GpuShader {
                    source: shader.source.clone(),
                    uniform_signature,
                    uniform_buffers,
                    uniform_bind_group,
                    color_module,
                    texture_module,
                    color_layout,
                    texture_layout,
                    color_pipelines: HashMap::new(),
                    texture_pipelines: HashMap::new(),
                },
            );
        }

        if let Some(cache) = self.shader_cache.get(shader_key) {
            for ((_, value), buffer) in ordered_uniforms.iter().zip(cache.uniform_buffers.iter()) {
                let bytes = uniform_bytes(value);
                self.queue.write_buffer(buffer, 0, &bytes);
            }
        }
    }

    fn custom_pipeline(
        &mut self,
        shader_key: ShaderKey,
        shader: &Shader,
        geometry: GeometryKind,
        key: PipelineKey,
    ) -> &wgpu::RenderPipeline {
        self.ensure_shader_cache(shader_key, shader);

        let missing = {
            let cache = self.shader_cache.get(shader_key).unwrap();
            match geometry {
                GeometryKind::Color => !cache.color_pipelines.contains_key(&key),
                GeometryKind::Texture => !cache.texture_pipelines.contains_key(&key),
            }
        };

        if missing {
            let pipeline = {
                let cache = self.shader_cache.get(shader_key).unwrap();
                match geometry {
                    GeometryKind::Color => create_render_pipeline(
                        &self.device,
                        self.surface_format,
                        &cache.color_layout,
                        &cache.color_module,
                        geometry,
                        key,
                        "luna_fragment_main",
                    ),
                    GeometryKind::Texture => create_render_pipeline(
                        &self.device,
                        self.surface_format,
                        &cache.texture_layout,
                        &cache.texture_module,
                        geometry,
                        key,
                        "luna_fragment_main",
                    ),
                }
            };

            let cache = self.shader_cache.get_mut(shader_key).unwrap();
            match geometry {
                GeometryKind::Color => {
                    cache.color_pipelines.insert(key, pipeline);
                }
                GeometryKind::Texture => {
                    cache.texture_pipelines.insert(key, pipeline);
                }
            }
        }

        let cache = self.shader_cache.get(shader_key).unwrap();
        match geometry {
            GeometryKind::Color => cache.color_pipelines.get(&key).unwrap(),
            GeometryKind::Texture => cache.texture_pipelines.get(&key).unwrap(),
        }
    }

    fn shader_bind_group(&self, shader_key: ShaderKey) -> Option<&wgpu::BindGroup> {
        self.shader_cache
            .get(shader_key)
            .and_then(|cache| cache.uniform_bind_group.as_ref())
    }

    fn texture_bind_group(&self, texture_ref: TexRef) -> Option<&wgpu::BindGroup> {
        match texture_ref {
            TexRef::Texture(key) => self
                .gpu_textures
                .get(key)
                .map(|texture| &texture.bind_group),
            TexRef::Canvas(key) => self
                .canvas_gpu_textures
                .get(key)
                .map(|texture| &texture.bind_group),
            TexRef::FontAtlas(key) => self
                .font_atlas_textures
                .get(key)
                .map(|texture| &texture.bind_group),
        }
    }

    fn issue_draw(
        &mut self,
        pass: &mut wgpu::RenderPass<'_>,
        draw: PreparedDraw,
        shaders: &SlotMap<ShaderKey, Shader>,
    ) -> bool {
        if let (RenderTargetId::Canvas(active_canvas), Some(TexRef::Canvas(source_canvas))) =
            (draw.target, draw.texture_ref)
        {
            if active_canvas == source_canvas {
                return false;
            }
        }

        let pipeline_key = PipelineKey {
            blend_mode: draw.blend_mode,
            color_mask_bits: draw.color_mask_bits,
            stencil_mode: draw.stencil_mode,
        };
        let effective_shader = shader_for_draw(draw);

        pass.set_bind_group(0, &self.viewport_bind_group, &[]);
        match draw.geometry {
            GeometryKind::Color => {
                pass.set_vertex_buffer(0, self.color_vertex_buffer.slice(..));
                pass.set_index_buffer(self.color_index_buffer.slice(..), wgpu::IndexFormat::Uint32);

                if let Some(shader_key) = effective_shader {
                    if let Some(shader) = shaders.get(shader_key) {
                        {
                            let pipeline = self.custom_pipeline(
                                shader_key,
                                shader,
                                draw.geometry,
                                pipeline_key,
                            );
                            pass.set_pipeline(pipeline);
                        }
                        if let Some(bind_group) = self.shader_bind_group(shader_key) {
                            pass.set_bind_group(1, bind_group, &[]);
                        }
                    } else {
                        let pipeline = self.default_pipeline(draw.geometry, pipeline_key);
                        pass.set_pipeline(pipeline);
                    }
                } else {
                    let pipeline = self.default_pipeline(draw.geometry, pipeline_key);
                    pass.set_pipeline(pipeline);
                }
            }
            GeometryKind::Texture => {
                let Some(texture_ref) = draw.texture_ref else {
                    return false;
                };

                pass.set_vertex_buffer(0, self.tex_vertex_buffer.slice(..));
                pass.set_index_buffer(self.tex_index_buffer.slice(..), wgpu::IndexFormat::Uint32);

                if let Some(shader_key) = effective_shader {
                    if let Some(shader) = shaders.get(shader_key) {
                        {
                            let pipeline = self.custom_pipeline(
                                shader_key,
                                shader,
                                draw.geometry,
                                pipeline_key,
                            );
                            pass.set_pipeline(pipeline);
                        }
                        {
                            let Some(texture_bind_group) = self.texture_bind_group(texture_ref)
                            else {
                                return false;
                            };
                            pass.set_bind_group(1, texture_bind_group, &[]);
                        }
                        if let Some(bind_group) = self.shader_bind_group(shader_key) {
                            pass.set_bind_group(2, bind_group, &[]);
                        }
                    } else {
                        let pipeline = self.default_pipeline(draw.geometry, pipeline_key);
                        pass.set_pipeline(pipeline);
                        let Some(texture_bind_group) = self.texture_bind_group(texture_ref) else {
                            return false;
                        };
                        pass.set_bind_group(1, texture_bind_group, &[]);
                    }
                } else {
                    let pipeline = self.default_pipeline(draw.geometry, pipeline_key);
                    pass.set_pipeline(pipeline);
                    let Some(texture_bind_group) = self.texture_bind_group(texture_ref) else {
                        return false;
                    };
                    pass.set_bind_group(1, texture_bind_group, &[]);
                }
            }
        }

        let (target_width, target_height) = self.target_dimensions_from_gpu(draw.target);
        match draw.scissor {
            Some((sx, sy, sw, sh)) => pass.set_scissor_rect(sx, sy, sw, sh),
            None => pass.set_scissor_rect(0, 0, target_width, target_height),
        }
        pass.set_stencil_reference(draw.stencil_reference);
        pass.draw_indexed(draw.idx_start..draw.idx_start + draw.idx_count, 0, 0..1);
        true
    }

    // ── Tessellation helpers ──────────────────────────────────────────────────

    #[allow(clippy::too_many_arguments)]
    fn tess_rect(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        lw: f32,
    ) {
        match mode {
            DrawMode::Fill => {
                let pts = [
                    apply(t, x, y),
                    apply(t, x + w, y),
                    apply(t, x + w, y + h),
                    apply(t, x, y + h),
                ];
                push_quad_verts(cv, ci, &pts, color);
            }
            DrawMode::Line => {
                // Four border edges as thick lines.
                push_thick_line(cv, ci, t, color, x, y, x + w, y, lw);
                push_thick_line(cv, ci, t, color, x + w, y, x + w, y + h, lw);
                push_thick_line(cv, ci, t, color, x + w, y + h, x, y + h, lw);
                push_thick_line(cv, ci, t, color, x, y + h, x, y, lw);
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn tess_rounded_rect(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        rx: f32,
        ry: f32,
        lw: f32,
    ) {
        let rx = rx.min(w * 0.5).max(0.0);
        let ry = ry.min(h * 0.5).max(0.0);
        const CORNER_SEGS: u32 = 8;

        // Build outline path; tessellate as fan (fill) or thick line segments (line).
        let path = build_rounded_rect_path(x, y, w, h, rx, ry, CORNER_SEGS);
        match mode {
            DrawMode::Fill => {
                // Fan from centroid.
                push_fan_fill(cv, ci, t, color, x + w * 0.5, y + h * 0.5, &path);
            }
            DrawMode::Line => {
                for i in 0..path.len() {
                    let j = (i + 1) % path.len();
                    push_thick_line(
                        cv, ci, t, color, path[i].0, path[i].1, path[j].0, path[j].1, lw,
                    );
                }
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn tess_ellipse(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        cx: f32,
        cy: f32,
        rx: f32,
        ry: f32,
        segs: u32,
        lw: f32,
    ) {
        match mode {
            DrawMode::Fill => {
                let base = cv.len() as u32;
                // Center vertex.
                let c = apply(t, cx, cy);
                cv.push(ColorVertex {
                    position: [c.0, c.1],
                    color,
                });
                for i in 0..=segs {
                    let a = (i as f32 / segs as f32) * 2.0 * PI;
                    let p = apply(t, cx + rx * a.cos(), cy + ry * a.sin());
                    cv.push(ColorVertex {
                        position: [p.0, p.1],
                        color,
                    });
                }
                for i in 1..=segs {
                    ci.extend_from_slice(&[base, base + i, base + i + 1]);
                }
            }
            DrawMode::Line => {
                for i in 0..segs {
                    let a0 = (i as f32 / segs as f32) * 2.0 * PI;
                    let a1 = ((i + 1) as f32 / segs as f32) * 2.0 * PI;
                    push_thick_line(
                        cv,
                        ci,
                        t,
                        color,
                        cx + rx * a0.cos(),
                        cy + ry * a0.sin(),
                        cx + rx * a1.cos(),
                        cy + ry * a1.sin(),
                        lw,
                    );
                }
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn tess_triangle(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        x3: f32,
        y3: f32,
        lw: f32,
    ) {
        match mode {
            DrawMode::Fill => {
                let base = cv.len() as u32;
                for &(px, py) in &[(x1, y1), (x2, y2), (x3, y3)] {
                    let p = apply(t, px, py);
                    cv.push(ColorVertex {
                        position: [p.0, p.1],
                        color,
                    });
                }
                ci.extend_from_slice(&[base, base + 1, base + 2]);
            }
            DrawMode::Line => {
                push_thick_line(cv, ci, t, color, x1, y1, x2, y2, lw);
                push_thick_line(cv, ci, t, color, x2, y2, x3, y3, lw);
                push_thick_line(cv, ci, t, color, x3, y3, x1, y1, lw);
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn tess_polygon(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        vertices: &[f32],
        lw: f32,
    ) {
        if vertices.len() < 6 {
            return;
        }
        let n = vertices.len() / 2;
        match mode {
            DrawMode::Fill => {
                // Fan from first vertex.
                let base = cv.len() as u32;
                for i in 0..n {
                    let p = apply(t, vertices[i * 2], vertices[i * 2 + 1]);
                    cv.push(ColorVertex {
                        position: [p.0, p.1],
                        color,
                    });
                }
                for i in 1..(n as u32 - 1) {
                    ci.extend_from_slice(&[base, base + i, base + i + 1]);
                }
            }
            DrawMode::Line => {
                for i in 0..n {
                    let j = (i + 1) % n;
                    push_thick_line(
                        cv,
                        ci,
                        t,
                        color,
                        vertices[i * 2],
                        vertices[i * 2 + 1],
                        vertices[j * 2],
                        vertices[j * 2 + 1],
                        lw,
                    );
                }
            }
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn tess_arc(
        &self,
        cv: &mut Vec<ColorVertex>,
        ci: &mut Vec<u32>,
        t: &Mat3,
        color: [f32; 4],
        mode: &DrawMode,
        cx: f32,
        cy: f32,
        r: f32,
        a1: f32,
        a2: f32,
        segs: u32,
        lw: f32,
    ) {
        match mode {
            DrawMode::Fill => {
                // Sector from center.
                let base = cv.len() as u32;
                let c = apply(t, cx, cy);
                cv.push(ColorVertex {
                    position: [c.0, c.1],
                    color,
                });
                for i in 0..=segs {
                    let a = a1 + (a2 - a1) * (i as f32 / segs as f32);
                    let p = apply(t, cx + r * a.cos(), cy + r * a.sin());
                    cv.push(ColorVertex {
                        position: [p.0, p.1],
                        color,
                    });
                }
                for i in 1..=segs {
                    ci.extend_from_slice(&[base, base + i, base + i + 1]);
                }
            }
            DrawMode::Line => {
                for i in 0..segs {
                    let a0 = a1 + (a2 - a1) * (i as f32 / segs as f32);
                    let a_next = a1 + (a2 - a1) * ((i + 1) as f32 / segs as f32);
                    push_thick_line(
                        cv,
                        ci,
                        t,
                        color,
                        cx + r * a0.cos(),
                        cy + r * a0.sin(),
                        cx + r * a_next.cos(),
                        cy + r * a_next.sin(),
                        lw,
                    );
                }
            }
        }
    }
}

// ─── Free helpers ─────────────────────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
fn append_color_draw(
    draws: &mut Vec<PreparedDraw>,
    all_verts: &mut Vec<ColorVertex>,
    all_idxs: &mut Vec<u32>,
    target: RenderTargetId,
    blend_mode: BlendMode,
    scissor: ScissorRect,
    color_mask_bits: u32,
    shader: Option<ShaderKey>,
    stencil_mode: StencilMode,
    stencil_reference: u8,
    verts: Vec<ColorVertex>,
    idxs: Vec<u32>,
) {
    if idxs.is_empty() {
        return;
    }

    let base = all_verts.len() as u32;
    let idx_start = all_idxs.len() as u32;
    all_verts.extend_from_slice(&verts);
    all_idxs.extend(idxs.iter().map(|&idx| idx + base));
    draws.push(PreparedDraw {
        target,
        geometry: GeometryKind::Color,
        texture_ref: None,
        idx_start,
        idx_count: idxs.len() as u32,
        blend_mode,
        scissor,
        color_mask_bits,
        shader,
        stencil_mode,
        stencil_reference: stencil_reference as u32,
    });
}

#[allow(clippy::too_many_arguments)]
fn append_tex_draw(
    draws: &mut Vec<PreparedDraw>,
    all_verts: &mut Vec<TexVertex>,
    all_idxs: &mut Vec<u32>,
    target: RenderTargetId,
    texture_ref: TexRef,
    blend_mode: BlendMode,
    scissor: ScissorRect,
    color_mask_bits: u32,
    shader: Option<ShaderKey>,
    stencil_mode: StencilMode,
    stencil_reference: u8,
    verts: Vec<TexVertex>,
    idxs: Vec<u32>,
) {
    if idxs.is_empty() {
        return;
    }

    let base = all_verts.len() as u32;
    let idx_start = all_idxs.len() as u32;
    all_verts.extend_from_slice(&verts);
    all_idxs.extend(idxs.iter().map(|&idx| idx + base));
    draws.push(PreparedDraw {
        target,
        geometry: GeometryKind::Texture,
        texture_ref: Some(texture_ref),
        idx_start,
        idx_count: idxs.len() as u32,
        blend_mode,
        scissor,
        color_mask_bits,
        shader,
        stencil_mode,
        stencil_reference: stencil_reference as u32,
    });
}

fn normalize_scissor(rect: Option<(f32, f32, f32, f32)>, width: u32, height: u32) -> ScissorRect {
    rect.and_then(|(x, y, w, h)| {
        let left = x.max(0.0).floor() as u32;
        let top = y.max(0.0).floor() as u32;
        let right = (x + w).max(0.0).ceil() as u32;
        let bottom = (y + h).max(0.0).ceil() as u32;
        if right <= left || bottom <= top {
            return None;
        }
        let clamped_left = left.min(width);
        let clamped_top = top.min(height);
        let clamped_right = right.min(width);
        let clamped_bottom = bottom.min(height);
        if clamped_right <= clamped_left || clamped_bottom <= clamped_top {
            None
        } else {
            Some((
                clamped_left,
                clamped_top,
                clamped_right - clamped_left,
                clamped_bottom - clamped_top,
            ))
        }
    })
}

fn color_write_mask_bits(mask: (bool, bool, bool, bool)) -> u32 {
    let mut bits = 0;
    if mask.0 {
        bits |= wgpu::ColorWrites::RED.bits();
    }
    if mask.1 {
        bits |= wgpu::ColorWrites::GREEN.bits();
    }
    if mask.2 {
        bits |= wgpu::ColorWrites::BLUE.bits();
    }
    if mask.3 {
        bits |= wgpu::ColorWrites::ALPHA.bits();
    }
    bits
}

fn color_write_mask_from_bits(bits: u32) -> wgpu::ColorWrites {
    wgpu::ColorWrites::from_bits_truncate(bits)
}

fn shader_for_draw(draw: PreparedDraw) -> Option<ShaderKey> {
    if matches!(draw.stencil_mode, StencilMode::Write(_)) {
        None
    } else {
        draw.shader
    }
}

fn parse_filter_mode(value: &str) -> wgpu::FilterMode {
    match value {
        "linear" => wgpu::FilterMode::Linear,
        _ => wgpu::FilterMode::Nearest,
    }
}

fn uniform_kind(value: &UniformValue) -> ShaderUniformKind {
    match value {
        UniformValue::Float(_) => ShaderUniformKind::Float,
        UniformValue::Vec2(_) => ShaderUniformKind::Vec2,
        UniformValue::Vec3(_) => ShaderUniformKind::Vec3,
        UniformValue::Vec4(_) => ShaderUniformKind::Vec4,
        UniformValue::Int(_) => ShaderUniformKind::Int,
        UniformValue::Bool(_) => ShaderUniformKind::Bool,
    }
}

fn uniform_bytes(value: &UniformValue) -> [u8; 16] {
    let mut bytes = [0u8; 16];
    match value {
        UniformValue::Float(v) => {
            bytes[..4].copy_from_slice(&v.to_ne_bytes());
        }
        UniformValue::Vec2(v) => {
            bytes[..8].copy_from_slice(bytemuck::cast_slice(v));
        }
        UniformValue::Vec3(v) => {
            bytes[..12].copy_from_slice(bytemuck::cast_slice(v));
        }
        UniformValue::Vec4(v) => {
            bytes.copy_from_slice(bytemuck::cast_slice(v));
        }
        UniformValue::Int(v) => {
            bytes[..4].copy_from_slice(&v.to_ne_bytes());
        }
        UniformValue::Bool(v) => {
            let raw = if *v { 1u32 } else { 0u32 };
            bytes[..4].copy_from_slice(&raw.to_ne_bytes());
        }
    }
    bytes
}

fn uniform_wgsl_type(kind: ShaderUniformKind) -> &'static str {
    match kind {
        ShaderUniformKind::Float => "f32",
        ShaderUniformKind::Vec2 => "vec2<f32>",
        ShaderUniformKind::Vec3 => "vec3<f32>",
        ShaderUniformKind::Vec4 => "vec4<f32>",
        ShaderUniformKind::Int => "i32",
        ShaderUniformKind::Bool => "u32",
    }
}

fn custom_uniform_declarations(
    uniform_signature: &[(String, ShaderUniformKind)],
    group_index: u32,
) -> String {
    uniform_signature
        .iter()
        .enumerate()
        .map(|(binding, (name, kind))| {
            format!(
                "@group({group_index}) @binding({binding}) var<uniform> {name}: {};\n",
                uniform_wgsl_type(*kind)
            )
        })
        .collect::<String>()
}

fn custom_fragment_call_args(
    inputs: &[ShaderFragmentInput],
    color_expr: &str,
    uv_expr: &str,
) -> String {
    inputs
        .iter()
        .map(|input| match input {
            ShaderFragmentInput::Color => color_expr,
            ShaderFragmentInput::Uv => uv_expr,
        })
        .collect::<Vec<_>>()
        .join(", ")
}

fn build_custom_color_shader_source(
    shader: &Shader,
    uniform_signature: &[(String, ShaderUniformKind)],
) -> String {
    let uniform_decls = custom_uniform_declarations(uniform_signature, 1);
    let fragment_call_args =
        custom_fragment_call_args(shader.fragment_inputs(), "in.color", "in.uv");
    format!(
        r#"
struct VertexInput {{
    @location(0) position: vec2<f32>,
    @location(1) color: vec4<f32>,
}}

struct VertexOutput {{
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
}}

struct LunaGlobals {{
    luna_ScreenSize: vec2<f32>,
    luna_Time: f32,
    _pad: f32,
    view_col0: vec4<f32>,
    view_col1: vec4<f32>,
    view_col2: vec4<f32>,
}}

@group(0) @binding(0) var<uniform> luna: LunaGlobals;
{uniform_decls}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {{
    var out: VertexOutput;
    let view = mat3x3<f32>(
        luna.view_col0.xyz,
        luna.view_col1.xyz,
        luna.view_col2.xyz,
    );
    let cam_pos = view * vec3<f32>(in.position, 1.0);
    out.clip_position = vec4<f32>(
        (cam_pos.x / luna.luna_ScreenSize.x) * 2.0 - 1.0,
        1.0 - (cam_pos.y / luna.luna_ScreenSize.y) * 2.0,
        0.0,
        1.0
    );
    out.color = in.color;
    out.uv = vec2<f32>(0.0, 0.0);
    return out;
}}

{user_source}

@fragment
fn luna_fragment_main(in: VertexOutput) -> @location(0) vec4<f32> {{
    return {fragment_entry}({fragment_call_args});
}}
"#,
        user_source = shader.wrapper_source(),
        fragment_entry = shader.fragment_entry_name(),
        fragment_call_args = fragment_call_args,
    )
}

fn build_custom_texture_shader_source(
    shader: &Shader,
    uniform_signature: &[(String, ShaderUniformKind)],
) -> String {
    let uniform_decls = custom_uniform_declarations(uniform_signature, 2);
    let fragment_call_args =
        custom_fragment_call_args(shader.fragment_inputs(), "sampled", "in.uv");
    format!(
        r#"
struct VertexInput {{
    @location(0) position: vec2<f32>,
    @location(1) uv: vec2<f32>,
    @location(2) color: vec4<f32>,
}}

struct VertexOutput {{
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
}}

struct LunaGlobals {{
    luna_ScreenSize: vec2<f32>,
    luna_Time: f32,
    _pad: f32,
    view_col0: vec4<f32>,
    view_col1: vec4<f32>,
    view_col2: vec4<f32>,
}}

@group(0) @binding(0) var<uniform> luna: LunaGlobals;
@group(1) @binding(0) var t_diffuse: texture_2d<f32>;
@group(1) @binding(1) var s_diffuse: sampler;
{uniform_decls}

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {{
    var out: VertexOutput;
    let view = mat3x3<f32>(
        luna.view_col0.xyz,
        luna.view_col1.xyz,
        luna.view_col2.xyz,
    );
    let cam_pos = view * vec3<f32>(in.position, 1.0);
    out.clip_position = vec4<f32>(
        (cam_pos.x / luna.luna_ScreenSize.x) * 2.0 - 1.0,
        1.0 - (cam_pos.y / luna.luna_ScreenSize.y) * 2.0,
        0.0,
        1.0
    );
    out.color = in.color;
    out.uv = in.uv;
    return out;
}}

{user_source}

@fragment
fn luna_fragment_main(in: VertexOutput) -> @location(0) vec4<f32> {{
    let sampled = textureSample(t_diffuse, s_diffuse, in.uv) * in.color;
    return {fragment_entry}({fragment_call_args});
}}
"#,
        user_source = shader.wrapper_source(),
        fragment_entry = shader.fragment_entry_name(),
        fragment_call_args = fragment_call_args,
    )
}

fn create_render_pipeline(
    device: &wgpu::Device,
    surface_format: wgpu::TextureFormat,
    layout: &wgpu::PipelineLayout,
    module: &wgpu::ShaderModule,
    geometry: GeometryKind,
    key: PipelineKey,
    fragment_entry: &str,
) -> wgpu::RenderPipeline {
    let primitive = wgpu::PrimitiveState {
        topology: wgpu::PrimitiveTopology::TriangleList,
        strip_index_format: None,
        front_face: wgpu::FrontFace::Ccw,
        cull_mode: None,
        polygon_mode: wgpu::PolygonMode::Fill,
        unclipped_depth: false,
        conservative: false,
    };

    let target = Some(wgpu::ColorTargetState {
        format: surface_format,
        blend: Some(blend_state_for(key.blend_mode)),
        write_mask: if matches!(key.stencil_mode, StencilMode::Write(_)) {
            wgpu::ColorWrites::empty()
        } else {
            color_write_mask_from_bits(key.color_mask_bits)
        },
    });

    match geometry {
        GeometryKind::Color => device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("color_pipeline"),
            layout: Some(layout),
            vertex: wgpu::VertexState {
                module,
                entry_point: "vs_main",
                compilation_options: Default::default(),
                buffers: &[wgpu::VertexBufferLayout {
                    array_stride: std::mem::size_of::<ColorVertex>() as wgpu::BufferAddress,
                    step_mode: wgpu::VertexStepMode::Vertex,
                    attributes: &wgpu::vertex_attr_array![0 => Float32x2, 1 => Float32x4],
                }],
            },
            fragment: Some(wgpu::FragmentState {
                module,
                entry_point: fragment_entry,
                compilation_options: Default::default(),
                targets: &[target],
            }),
            primitive,
            depth_stencil: Some(depth_stencil_state(key.stencil_mode)),
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        }),
        GeometryKind::Texture => device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("texture_pipeline"),
            layout: Some(layout),
            vertex: wgpu::VertexState {
                module,
                entry_point: "vs_main",
                compilation_options: Default::default(),
                buffers: &[wgpu::VertexBufferLayout {
                    array_stride: std::mem::size_of::<TexVertex>() as wgpu::BufferAddress,
                    step_mode: wgpu::VertexStepMode::Vertex,
                    attributes: &wgpu::vertex_attr_array![0 => Float32x2, 1 => Float32x2, 2 => Float32x4],
                }],
            },
            fragment: Some(wgpu::FragmentState {
                module,
                entry_point: fragment_entry,
                compilation_options: Default::default(),
                targets: &[target],
            }),
            primitive,
            depth_stencil: Some(depth_stencil_state(key.stencil_mode)),
            multisample: wgpu::MultisampleState::default(),
            multiview: None,
            cache: None,
        }),
    }
}

fn depth_stencil_state(stencil_mode: StencilMode) -> wgpu::DepthStencilState {
    wgpu::DepthStencilState {
        format: wgpu::TextureFormat::Depth24PlusStencil8,
        depth_write_enabled: false,
        depth_compare: wgpu::CompareFunction::Always,
        stencil: wgpu::StencilState {
            front: stencil_face_state(stencil_mode),
            back: stencil_face_state(stencil_mode),
            read_mask: if matches!(stencil_mode, StencilMode::Disabled) {
                0
            } else {
                0xFF
            },
            write_mask: if matches!(stencil_mode, StencilMode::Write(_)) {
                0xFF
            } else {
                0
            },
        },
        bias: wgpu::DepthBiasState::default(),
    }
}

fn stencil_face_state(stencil_mode: StencilMode) -> wgpu::StencilFaceState {
    match stencil_mode {
        StencilMode::Disabled => wgpu::StencilFaceState {
            compare: wgpu::CompareFunction::Always,
            fail_op: wgpu::StencilOperation::Keep,
            depth_fail_op: wgpu::StencilOperation::Keep,
            pass_op: wgpu::StencilOperation::Keep,
        },
        StencilMode::Write(action) => wgpu::StencilFaceState {
            compare: wgpu::CompareFunction::Always,
            fail_op: wgpu::StencilOperation::Keep,
            depth_fail_op: wgpu::StencilOperation::Keep,
            pass_op: stencil_operation(action),
        },
        StencilMode::Test(compare) => wgpu::StencilFaceState {
            compare: compare_function(compare),
            fail_op: wgpu::StencilOperation::Keep,
            depth_fail_op: wgpu::StencilOperation::Keep,
            pass_op: wgpu::StencilOperation::Keep,
        },
    }
}

fn compare_function(compare: crate::render::renderer::CompareMode) -> wgpu::CompareFunction {
    match compare {
        crate::render::renderer::CompareMode::Equal => wgpu::CompareFunction::Equal,
        crate::render::renderer::CompareMode::NotEqual => wgpu::CompareFunction::NotEqual,
        crate::render::renderer::CompareMode::Less => wgpu::CompareFunction::Less,
        crate::render::renderer::CompareMode::LessEqual => wgpu::CompareFunction::LessEqual,
        crate::render::renderer::CompareMode::Greater => wgpu::CompareFunction::Greater,
        crate::render::renderer::CompareMode::GreaterEqual => wgpu::CompareFunction::GreaterEqual,
        crate::render::renderer::CompareMode::Always => wgpu::CompareFunction::Always,
        crate::render::renderer::CompareMode::Never => wgpu::CompareFunction::Never,
    }
}

fn stencil_operation(action: crate::render::renderer::StencilAction) -> wgpu::StencilOperation {
    match action {
        crate::render::renderer::StencilAction::Replace => wgpu::StencilOperation::Replace,
        crate::render::renderer::StencilAction::Increment => wgpu::StencilOperation::IncrementClamp,
        crate::render::renderer::StencilAction::Decrement => wgpu::StencilOperation::DecrementClamp,
        crate::render::renderer::StencilAction::IncrementWrap => {
            wgpu::StencilOperation::IncrementWrap
        }
        crate::render::renderer::StencilAction::DecrementWrap => {
            wgpu::StencilOperation::DecrementWrap
        }
        crate::render::renderer::StencilAction::Keep => wgpu::StencilOperation::Keep,
        crate::render::renderer::StencilAction::Zero => wgpu::StencilOperation::Zero,
        crate::render::renderer::StencilAction::Invert => wgpu::StencilOperation::Invert,
    }
}

/// Apply the current transform matrix to a 2D point.
#[inline]
fn apply(t: &Mat3, x: f32, y: f32) -> (f32, f32) {
    let p = t.transform_point(Vec2 { x, y });
    (p.x, p.y)
}

/// Append a thick-line quad (two triangles) to the color buffers.
#[allow(clippy::too_many_arguments)]
fn push_thick_line(
    cv: &mut Vec<ColorVertex>,
    ci: &mut Vec<u32>,
    t: &Mat3,
    color: [f32; 4],
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
    width: f32,
) {
    let dx = x2 - x1;
    let dy = y2 - y1;
    let len = (dx * dx + dy * dy).sqrt();
    if len < 1e-4 {
        return;
    }
    let hw = width * 0.5;
    let nx = -dy / len * hw;
    let ny = dx / len * hw;

    let pts = [
        apply(t, x1 + nx, y1 + ny),
        apply(t, x1 - nx, y1 - ny),
        apply(t, x2 - nx, y2 - ny),
        apply(t, x2 + nx, y2 + ny),
    ];
    push_quad_verts(cv, ci, &pts, color);
}

/// Push 4 vertices + 6 indices for a quad.
fn push_quad_verts(
    cv: &mut Vec<ColorVertex>,
    ci: &mut Vec<u32>,
    pts: &[(f32, f32); 4],
    color: [f32; 4],
) {
    let base = cv.len() as u32;
    for &(x, y) in pts {
        cv.push(ColorVertex {
            position: [x, y],
            color,
        });
    }
    ci.extend_from_slice(&[base, base + 1, base + 2, base, base + 2, base + 3]);
}

/// Fan-fill from a centre point over a closed polygon path.
fn push_fan_fill(
    cv: &mut Vec<ColorVertex>,
    ci: &mut Vec<u32>,
    t: &Mat3,
    color: [f32; 4],
    cx: f32,
    cy: f32,
    path: &[(f32, f32)],
) {
    if path.len() < 2 {
        return;
    }
    let base = cv.len() as u32;
    let c = apply(t, cx, cy);
    cv.push(ColorVertex {
        position: [c.0, c.1],
        color,
    });
    for &(px, py) in path {
        let p = apply(t, px, py);
        cv.push(ColorVertex {
            position: [p.0, p.1],
            color,
        });
    }
    let n = path.len() as u32;
    for i in 0..n {
        ci.extend_from_slice(&[base, base + 1 + i, base + 1 + (i + 1) % n]);
    }
}

/// Build the outline path for a rounded rectangle (list of 2D points, closed).
fn build_rounded_rect_path(
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    rx: f32,
    ry: f32,
    segs: u32,
) -> Vec<(f32, f32)> {
    let mut pts = Vec::new();
    // Each corner: top-left, top-right, bottom-right, bottom-left
    let corners = [
        (x + rx, y + ry, PI, 1.5 * PI),
        (x + w - rx, y + ry, 1.5 * PI, 2.0 * PI),
        (x + w - rx, y + h - ry, 0.0, 0.5 * PI),
        (x + rx, y + h - ry, 0.5 * PI, PI),
    ];
    for &(cx, cy, a_start, a_end) in &corners {
        for i in 0..=segs {
            let a = a_start + (a_end - a_start) * (i as f32 / segs as f32);
            pts.push((cx + rx * a.cos(), cy + ry * a.sin()));
        }
    }
    pts
}

/// Push a textured quad with full affine transform support.
///
/// `w`, `h` — display size of the quad before scale.
/// `u0`, `v0`, `u1`, `v1` — normalised UV coordinates inside the texture.
#[allow(clippy::too_many_arguments)]
fn push_tex_quad(
    tv: &mut Vec<TexVertex>,
    ti: &mut Vec<u32>,
    t: &Mat3,
    tint: [f32; 4],
    x: f32,
    y: f32,
    rot: f32,
    sx: f32,
    sy: f32,
    ox: f32,
    oy: f32,
    w: f32,
    h: f32,
    u0: f32,
    v0: f32,
    u1: f32,
    v1: f32,
) {
    // Local corners before origin offset.
    let local = [(0.0, 0.0), (w, 0.0), (w, h), (0.0, h)];
    let uv = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)];
    let cos_r = rot.cos();
    let sin_r = rot.sin();

    let base = tv.len() as u32;
    for (i, &(lx, ly)) in local.iter().enumerate() {
        // Apply: translate by -origin, scale, rotate, then world translate.
        let sx2 = (lx - ox) * sx;
        let sy2 = (ly - oy) * sy;
        let rx = sx2 * cos_r - sy2 * sin_r + x;
        let ry = sx2 * sin_r + sy2 * cos_r + y;
        // Apply current camera/world transform.
        let (wx, wy) = apply(t, rx, ry);
        tv.push(TexVertex {
            position: [wx, wy],
            uv: [uv[i].0, uv[i].1],
            color: tint,
        });
    }
    ti.extend_from_slice(&[base, base + 1, base + 2, base, base + 2, base + 3]);
}

/// Push a textured quad with four arbitrary screen-space corners and per-corner UVs.
///
/// Unlike [`push_tex_quad`], this function accepts pre-projected corner positions
/// directly — no SRT decomposition. This supports perspective-correct quads
/// (e.g. raycaster wall faces) where the four corners are not axis-aligned.
/// The current world transform `t` is still applied to each corner.
fn push_tex_quad_corners(
    tv: &mut Vec<TexVertex>,
    ti: &mut Vec<u32>,
    t: &Mat3,
    tint: [f32; 4],
    corners: &[crate::math::Vec2; 4],
    uvs: &[crate::math::Vec2; 4],
) {
    let base = tv.len() as u32;
    for i in 0..4 {
        let (wx, wy) = apply(t, corners[i].x, corners[i].y);
        tv.push(TexVertex {
            position: [wx, wy],
            uv: [uvs[i].x, uvs[i].y],
            color: tint,
        });
    }
    ti.extend_from_slice(&[base, base + 1, base + 2, base, base + 2, base + 3]);
}

// ── Bitmap debug font ────────────────────────────────────────
// Zero-dependency 5×7 pixel font for debug/error overlays.
// Ported from src/graphic/gpu_renderer.rs.

/// Returns a 5×7 bitmap pattern for the given character.
/// Each byte represents one row; bits 4..0 are pixels left-to-right.
#[allow(dead_code)]
fn bitmap_char(ch: char) -> [u8; 7] {
    match ch.to_ascii_uppercase() {
        'A' => [
            0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001,
        ],
        'B' => [
            0b11110, 0b10001, 0b11110, 0b10001, 0b10001, 0b10001, 0b11110,
        ],
        'C' => [
            0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110,
        ],
        'D' => [
            0b11100, 0b10010, 0b10001, 0b10001, 0b10001, 0b10010, 0b11100,
        ],
        'E' => [
            0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111,
        ],
        'F' => [
            0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000,
        ],
        'G' => [
            0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110,
        ],
        'H' => [
            0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001,
        ],
        'I' => [
            0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110,
        ],
        'J' => [
            0b00111, 0b00010, 0b00010, 0b00010, 0b00010, 0b10010, 0b01100,
        ],
        'K' => [
            0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001,
        ],
        'L' => [
            0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111,
        ],
        'M' => [
            0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001,
        ],
        'N' => [
            0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001,
        ],
        'O' => [
            0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110,
        ],
        'P' => [
            0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000,
        ],
        'Q' => [
            0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101,
        ],
        'R' => [
            0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001,
        ],
        'S' => [
            0b01110, 0b10001, 0b10000, 0b01110, 0b00001, 0b10001, 0b01110,
        ],
        'T' => [
            0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100,
        ],
        'U' => [
            0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110,
        ],
        'V' => [
            0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100,
        ],
        'W' => [
            0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b11011, 0b10001,
        ],
        'X' => [
            0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001,
        ],
        'Y' => [
            0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100,
        ],
        'Z' => [
            0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111,
        ],
        '0' => [
            0b01110, 0b10011, 0b10101, 0b10101, 0b11001, 0b10001, 0b01110,
        ],
        '1' => [
            0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110,
        ],
        '2' => [
            0b01110, 0b10001, 0b00001, 0b00110, 0b01000, 0b10000, 0b11111,
        ],
        '3' => [
            0b01110, 0b10001, 0b00001, 0b00110, 0b00001, 0b10001, 0b01110,
        ],
        '4' => [
            0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010,
        ],
        '5' => [
            0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110,
        ],
        '6' => [
            0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110,
        ],
        '7' => [
            0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000,
        ],
        '8' => [
            0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110,
        ],
        '9' => [
            0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110,
        ],
        '!' => [
            0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00000, 0b00100,
        ],
        '.' => [
            0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00100,
        ],
        ',' => [
            0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00100, 0b01000,
        ],
        ':' => [
            0b00000, 0b00100, 0b00000, 0b00000, 0b00000, 0b00100, 0b00000,
        ],
        '-' => [
            0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000,
        ],
        '/' => [
            0b00001, 0b00010, 0b00010, 0b00100, 0b01000, 0b01000, 0b10000,
        ],
        _ => [
            0b01110, 0b01010, 0b01010, 0b01010, 0b01010, 0b00000, 0b01010,
        ],
    }
}

/// Renders debug text using the built-in 5×7 bitmap font.
/// Pushes colored quads into the vertex/index buffers — no font texture needed.
#[allow(dead_code)]
fn render_text(
    cv: &mut Vec<ColorVertex>,
    ci: &mut Vec<u32>,
    t: &Mat3,
    color: [f32; 4],
    text: &str,
    x: f32,
    y: f32,
    scale: f32,
) {
    let char_w = 6.0 * scale;
    let px_w = char_w / 5.0;
    let px_h = (8.0 * scale) / 7.0;
    for (i, ch) in text.chars().enumerate() {
        if ch == ' ' {
            continue;
        }
        let cx = x + i as f32 * char_w;
        let pattern = bitmap_char(ch);
        for (row, &bits) in pattern.iter().enumerate() {
            for col in 0..5u8 {
                if bits & (1 << (4 - col)) != 0 {
                    let px = cx + col as f32 * px_w;
                    let py = y + row as f32 * px_h;
                    let pts = [
                        apply(t, px, py),
                        apply(t, px + px_w, py),
                        apply(t, px + px_w, py + px_h),
                        apply(t, px, py + px_h),
                    ];
                    push_quad_verts(cv, ci, &pts, color);
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use std::convert::TryInto;

    use super::*;
    use crate::render::renderer::{CompareMode, StencilAction};

    const VALID_WGSL_FRAGMENT_SHADER: &str = r#"
@fragment
fn fs_main(
    @location(0) color: vec4<f32>,
    @location(1) uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    return color + vec4<f32>(uv, 0.0, 0.0);
}
"#;

    #[test]
    fn test_phase02_live_scissor_normalization_clamps_to_target_bounds() {
        assert_eq!(
            normalize_scissor(Some((-1.2, 2.8, 20.1, 100.0)), 10, 8),
            Some((0, 2, 10, 6))
        );
    }

    #[test]
    fn test_phase02_live_scissor_normalization_discards_fully_offscreen_rects() {
        assert_eq!(normalize_scissor(Some((11.0, 0.0, 2.0, 2.0)), 10, 8), None);
    }

    #[test]
    fn test_phase02_live_color_mask_bits_round_trip_selected_channels() {
        let bits = color_write_mask_bits((true, false, true, false));
        let mask = color_write_mask_from_bits(bits);

        assert_eq!(mask, wgpu::ColorWrites::RED | wgpu::ColorWrites::BLUE);
    }

    #[test]
    fn test_phase02_live_filter_mode_maps_linear_and_defaults_to_nearest() {
        assert_eq!(parse_filter_mode("linear"), wgpu::FilterMode::Linear);
        assert_eq!(parse_filter_mode("nearest"), wgpu::FilterMode::Nearest);
        assert_eq!(parse_filter_mode("unsupported"), wgpu::FilterMode::Nearest);
    }

    #[test]
    fn test_phase02_live_uniform_bytes_pack_bool_and_vec4_values() {
        let bool_bytes = uniform_bytes(&UniformValue::Bool(true));
        let vec4_bytes = uniform_bytes(&UniformValue::Vec4([1.0, 2.0, 3.0, 4.0]));

        assert_eq!(u32::from_ne_bytes(bool_bytes[..4].try_into().unwrap()), 1);
        assert_eq!(
            f32::from_ne_bytes(vec4_bytes[0..4].try_into().unwrap()),
            1.0
        );
        assert_eq!(
            f32::from_ne_bytes(vec4_bytes[4..8].try_into().unwrap()),
            2.0
        );
        assert_eq!(
            f32::from_ne_bytes(vec4_bytes[8..12].try_into().unwrap()),
            3.0
        );
        assert_eq!(
            f32::from_ne_bytes(vec4_bytes[12..16].try_into().unwrap()),
            4.0
        );
    }

    #[test]
    fn test_phase02_live_custom_color_shader_source_is_parseable_with_uniforms() {
        let uniform_signature = vec![
            ("tint".to_string(), ShaderUniformKind::Vec4),
            ("time_scale".to_string(), ShaderUniformKind::Float),
        ];
        let shader = Shader::new(VALID_WGSL_FRAGMENT_SHADER.to_string())
            .expect("expected valid fragment shader");
        let source = build_custom_color_shader_source(&shader, &uniform_signature);

        assert!(source.contains("@group(1) @binding(0) var<uniform> tint: vec4<f32>;"));
        assert!(source.contains("@group(1) @binding(1) var<uniform> time_scale: f32;"));
        assert!(source.contains("fn luna_fragment_main"));
        wgpu::naga::front::wgsl::parse_str(&source)
            .expect("wrapped color shader source should remain valid WGSL");
    }

    #[test]
    fn test_phase02_live_custom_texture_shader_source_is_parseable_with_uniforms() {
        let uniform_signature = vec![("uv_scale".to_string(), ShaderUniformKind::Vec2)];
        let shader = Shader::new(VALID_WGSL_FRAGMENT_SHADER.to_string())
            .expect("expected valid fragment shader");
        let source = build_custom_texture_shader_source(&shader, &uniform_signature);

        assert!(source.contains("@group(1) @binding(0) var t_diffuse: texture_2d<f32>;"));
        assert!(source.contains("@group(1) @binding(1) var s_diffuse: sampler;"));
        assert!(source.contains("@group(2) @binding(0) var<uniform> uv_scale: vec2<f32>;"));
        assert!(source.contains("textureSample(t_diffuse, s_diffuse, in.uv) * in.color"));
        wgpu::naga::front::wgsl::parse_str(&source)
            .expect("wrapped texture shader source should remain valid WGSL");
    }

    #[test]
    fn test_phase02_live_stencil_write_depth_state_enables_writes_and_action() {
        let state = depth_stencil_state(StencilMode::Write(StencilAction::IncrementWrap));

        assert_eq!(state.format, wgpu::TextureFormat::Depth24PlusStencil8);
        assert_eq!(state.depth_compare, wgpu::CompareFunction::Always);
        assert_eq!(state.stencil.read_mask, 0xFF);
        assert_eq!(state.stencil.write_mask, 0xFF);
        assert_eq!(state.stencil.front.compare, wgpu::CompareFunction::Always);
        assert_eq!(
            state.stencil.front.pass_op,
            wgpu::StencilOperation::IncrementWrap
        );
        assert_eq!(
            state.stencil.back.pass_op,
            wgpu::StencilOperation::IncrementWrap
        );
    }

    #[test]
    fn test_phase02_live_stencil_test_depth_state_reads_without_writing() {
        let state = depth_stencil_state(StencilMode::Test(CompareMode::GreaterEqual));

        assert_eq!(state.stencil.read_mask, 0xFF);
        assert_eq!(state.stencil.write_mask, 0);
        assert_eq!(
            state.stencil.front.compare,
            wgpu::CompareFunction::GreaterEqual
        );
        assert_eq!(state.stencil.front.pass_op, wgpu::StencilOperation::Keep);
        assert_eq!(
            state.stencil.back.compare,
            wgpu::CompareFunction::GreaterEqual
        );
    }
}
