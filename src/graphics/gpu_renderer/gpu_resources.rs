//! Resource-management methods for [`GpuRenderer`].
//!
//! Handles GPU object creation: textures, samplers, canvases, pipelines,
//! font atlases, and depth/stencil targets.
//!
//! This module is part of Luna2D's `gpu_renderer` subsystem and provides the implementation
//! details for gpu resources-related operations and data management.
//! Primary functions: `new()`, `resize()`, `create_sampler()`, `create_texture_bind_group()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

#[allow(unused_imports)]
use super::{GpuRenderer, RenderStats};
#[allow(unused_imports)]
use super::{MAX_COLOR_VERTS, MAX_COLOR_IDXS, MAX_TEX_VERTS, MAX_TEX_IDXS,
            COLOR_SHADER, TEXTURE_SHADER};
#[allow(unused_imports)]
use super::render_pass::parse_filter_mode;
#[allow(unused_imports)]
use super::{ColorVertex, TexVertex, ViewportUniform, GpuTexture, DepthStencilTarget, TexRef, ScissorRect, RenderTargetId, GeometryKind, StencilMode, PipelineKey, PipelineSelectionKey, PreparedDraw, ShaderUniformKind, GpuShader, blend_state_for};

use std::collections::HashMap;


use crate::engine::resource_keys::{
    CanvasKey, FontKey, ShaderKey, TextureKey};
use crate::graphics::renderer::TextureData;
use crate::graphics::shader::Shader;
use slotmap::{SlotMap, SparseSecondaryMap};

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
            view_col2: [0.0, 0.0, 1.0, 0.0]};
        let viewport_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("viewport_uniform"),
            size: std::mem::size_of::<ViewportUniform>() as u64,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false});
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
                    min_binding_size: None},
                count: None}]});
        let texture_bgl = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("texture_bgl"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Texture {
                        sample_type: wgpu::TextureSampleType::Float { filterable: true },
                        view_dimension: wgpu::TextureViewDimension::D2,
                        multisampled: false},
                    count: None},
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::FRAGMENT,
                    ty: wgpu::BindingType::Sampler(wgpu::SamplerBindingType::Filtering),
                    count: None},
            ]});

        // ── Viewport bind group ────────────────────────────────────────────
        let viewport_bg = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("viewport_bg"),
            layout: &viewport_bgl,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: viewport_buffer.as_entire_binding()}]});

        // ── Default shaders and layouts ───────────────────────────────────
        let color_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("color_shader"),
            source: wgpu::ShaderSource::Wgsl(COLOR_SHADER.into())});
        let texture_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("texture_shader"),
            source: wgpu::ShaderSource::Wgsl(TEXTURE_SHADER.into())});

        let color_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("color_layout"),
            bind_group_layouts: &[&viewport_bgl],
            push_constant_ranges: &[]});
        let texture_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: Some("texture_layout"),
            bind_group_layouts: &[&viewport_bgl, &texture_bgl],
            push_constant_ranges: &[]});

        // ── Vertex / index buffers ────────────────────────────────────────
        let color_vertex_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("color_vbo"),
            size: MAX_COLOR_VERTS * std::mem::size_of::<ColorVertex>() as u64,
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false});
        let color_index_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("color_ibo"),
            size: MAX_COLOR_IDXS * std::mem::size_of::<u32>() as u64,
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false});
        let tex_vertex_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("tex_vbo"),
            size: MAX_TEX_VERTS * std::mem::size_of::<TexVertex>() as u64,
            usage: wgpu::BufferUsages::VERTEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false});
        let tex_index_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("tex_ibo"),
            size: MAX_TEX_IDXS * std::mem::size_of::<u32>() as u64,
            usage: wgpu::BufferUsages::INDEX | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false});

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
            render_stats: RenderStats::default()}
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
            view_col2: [0.0, 0.0, 1.0, 0.0]};
        self.queue
            .write_buffer(&self.viewport_buffer, 0, bytemuck::bytes_of(&data));
        self.screen_stencil_target = None;
    }

    /// Create a wgpu texture sampler with the given filter settings.
    ///
    /// # Returns
    /// `wgpu::Sampler`.
///
/// # Parameters
/// - `default_filter` — `&(String, String, u32)`
    pub(super) fn create_sampler(&self, default_filter: &(String, String, u32)) -> wgpu::Sampler {
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

    /// Allocate a wgpu bind group for the given texture.
    ///
    /// # Returns
    /// `wgpu::BindGroup`.
///
/// # Parameters
/// - `view` — `&wgpu::TextureView`
/// - `sampler` — `&wgpu::Sampler`
/// - `label` — `&'static str`
    pub(super) fn create_texture_bind_group(
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
                    resource: wgpu::BindingResource::TextureView(view)},
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: wgpu::BindingResource::Sampler(sampler)},
            ]})
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
            depth_or_array_layers: 1};
        let texture = self.device.create_texture(&wgpu::TextureDescriptor {
            label: Some("sprite_texture"),
            size,
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb,
            usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
            view_formats: &[]});
        self.queue.write_texture(
            wgpu::ImageCopyTexture {
                texture: &texture,
                mip_level: 0,
                origin: wgpu::Origin3d::ZERO,
                aspect: wgpu::TextureAspect::All},
            pixels,
            wgpu::ImageDataLayout {
                offset: 0,
                bytes_per_row: Some(4 * width),
                rows_per_image: Some(height)},
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
            height}
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
    ///
    /// # Returns
    /// `bool`.
///
/// # Parameters
/// - `font_key` — `FontKey`
/// - `font` — `&mut crate::graphics::Font`
/// - `default_filter` — `&(String, String, u32)`
    pub(super) fn ensure_font_atlas(
        &mut self,
        font_key: FontKey,
        font: &mut crate::graphics::Font,
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
                depth_or_array_layers: 1},
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: self.surface_format,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[]});
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
                height},
        );
        self.canvas_needs_clear.insert(key, true);
    }

    /// Allocate the depth-stencil attachment for the main render pass.
    ///
    /// # Returns
    /// `DepthStencilTarget`.
///
/// # Parameters
/// - `width` — `u32`
/// - `height` — `u32`
/// - `label` — `&'static str`
    pub(super) fn create_depth_stencil_target(
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
                depth_or_array_layers: 1},
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Depth24PlusStencil8,
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            view_formats: &[]});
        let view = texture.create_view(&wgpu::TextureViewDescriptor::default());
        DepthStencilTarget {
            _texture: texture,
            view,
            width,
            height}
    }

    /// Ensure the on-screen stencil target matches the current surface size.
    pub(super) fn ensure_screen_stencil_target(&mut self) {
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

    /// Ensure a per-canvas stencil buffer matches the canvas dimensions.
///
/// # Parameters
/// - `key` — `CanvasKey`
/// - `width` — `u32`
/// - `height` — `u32`
    pub(super) fn ensure_canvas_stencil_target(&mut self, key: CanvasKey, width: u32, height: u32) {
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

    /// Drop GPU resources that have been released since the last frame.
///
/// # Parameters
/// - `textures` — `&SlotMap<TextureKey, TextureData>`
/// - `fonts` — `&SlotMap<FontKey, crate::graphics::Font>`
/// - `canvases` — `&SlotMap<CanvasKey, crate::graphics::Canvas>`
/// - `shaders` — `&SlotMap<ShaderKey, Shader>`
    pub(super) fn prune_released_resources(
        &mut self,
        textures: &SlotMap<TextureKey, TextureData>,
        fonts: &SlotMap<FontKey, crate::graphics::Font>,
        canvases: &SlotMap<CanvasKey, crate::graphics::Canvas>,
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

}
