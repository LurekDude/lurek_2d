//! GPU-accelerated 2D renderer for Luna2D, backed by wgpu.
//!
//! Processes a `DrawCommand` queue each frame, tessellates geometry on the CPU,
//! uploads vertex / index data to GPU buffers, and issues a single render pass.
//!
//! # Design
//! - Two render pipelines: *color* (solid + gradient shapes) and *texture* (images, sprites).
//! - Transform stack maintained during command processing — identical to standard push/pop transform stack.
//! - Colored geometry is batched in one draw call; each distinct texture source is one draw call.
//! - Draw order: colored shapes first (in submission order), textured images second.

use std::collections::HashMap;

use bytemuck::{Pod, Zeroable};

use crate::engine::resource_keys::{
    CanvasKey, FontKey, ShaderKey, TextureKey,
};
use crate::graphics::renderer::BlendMode;
use slotmap::SparseSecondaryMap;

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

/// Per-frame rendering statistics. Consult the module-level documentation for the broader usage context and preconditions.
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
    Write(crate::graphics::renderer::StencilAction),
    Test(crate::graphics::renderer::CompareMode),
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

// ─── GpuRenderer ─────────────────────────────────────────────────────────────

/// GPU-accelerated renderer that processes `DrawCommand` queues via wgpu.
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
}


/// Gpu Resources sub-module.
pub(super) mod gpu_resources;
/// Render Pass sub-module.
pub(super) mod render_pass;
