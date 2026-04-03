//! Render-frame execution, draw-call dispatch, tessellation, and pipeline management
//! for [`GpuRenderer`].
//!
//! This module is part of Luna2D's `gpu_renderer` subsystem and provides the implementation
//! details for render pass-related operations and data management.
//! Primary functions: `render_frame()`, `parse_filter_mode()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

#[allow(unused_imports)]
use super::{GpuRenderer, RenderStats};
#[allow(unused_imports)]
use super::{ColorVertex, TexVertex, ViewportUniform, GpuTexture, DepthStencilTarget, TexRef, ScissorRect, RenderTargetId, GeometryKind, StencilMode, PipelineKey, PipelineSelectionKey, PreparedDraw, ShaderUniformKind, GpuShader, blend_state_for};

use std::collections::{HashMap, HashSet};
use std::f32::consts::PI;


use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, SpriteBatchKey, TextureKey,
};
use crate::graphics::mesh::Mesh;
use crate::graphics::renderer::{BlendMode, DrawCommand, DrawMode, TextAlign, TextureData};
use crate::graphics::shader::{Shader, ShaderFragmentInput, UniformValue};
use crate::math::{Mat3, Vec2};
use slotmap::SlotMap;

impl GpuRenderer {
    /// Processes a frame: uploads new textures, tessellates commands, renders to surface, presents.
    ///
    /// # Parameters
    /// - `surface` — `&wgpu::Surface<'static>`.
    /// - `commands` — `&[DrawCommand]`.
    /// - `textures` — `&SlotMap<TextureKey, TextureData>`.
    /// - `fonts` — `&mut SlotMap<FontKey, crate::graphics::Font>`.
    /// - `sprite_batches` — `&SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch>`.
    /// - `canvases` — `&SlotMap<CanvasKey, crate::graphics::Canvas>`.
    /// - `meshes` — `&SlotMap<MeshKey, Mesh>`.
    /// - `shaders` — `&SlotMap<ShaderKey, Shader>`.
    /// - `default_filter` — `&(String, String, u32)`.
    /// - `background_color` — `[f32`.
    ///
    /// Returns `Err(wgpu::SurfaceError)` on transient errors; the caller should reconfigure on
    /// `SurfaceError::Lost`.
    #[allow(clippy::too_many_arguments)]
    pub fn render_frame(
        &mut self,
        surface: &wgpu::Surface<'static>,
        commands: &[DrawCommand],
        textures: &SlotMap<TextureKey, TextureData>,
        fonts: &mut SlotMap<FontKey, crate::graphics::Font>,
        sprite_batches: &SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch>,
        canvases: &SlotMap<CanvasKey, crate::graphics::Canvas>,
        meshes: &SlotMap<MeshKey, Mesh>,
        shaders: &SlotMap<ShaderKey, Shader>,
        default_filter: &(String, String, u32),
        background_color: [f32; 4],
        camera_matrix: &Mat3,
        frame_time: f32,
    ) -> Result<(), wgpu::SurfaceError> {
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
                DrawCommand::SetColor(r, g, b, a) => {
                    current_color = [*r, *g, *b, *a];
                }
                DrawCommand::SetLineWidth(w) => {
                    line_width = *w;
                }

                // ── Transform stack ──────────────────────────────────────
                DrawCommand::PushTransform => {
                    let top = *transform_stack.last().unwrap();
                    transform_stack.push(top);
                }
                DrawCommand::PopTransform => {
                    if transform_stack.len() > 1 {
                        transform_stack.pop();
                    }
                }
                DrawCommand::Translate { x, y } => {
                    let m = Mat3::from_translation(Vec2 { x: *x, y: *y });
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                DrawCommand::Rotate { angle } => {
                    let m = Mat3::from_rotation(*angle);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                DrawCommand::Scale { sx, sy } => {
                    let m = Mat3::from_scale(Vec2 { x: *sx, y: *sy });
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                DrawCommand::Shear { kx, ky } => {
                    let m = Mat3::from_shear(*kx, *ky);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }
                DrawCommand::Origin => {
                    let top = transform_stack.last_mut().unwrap();
                    *top = Mat3::identity();
                }
                DrawCommand::ApplyTransform { matrix } => {
                    let m = Mat3::from_row_major(matrix);
                    let top = transform_stack.last_mut().unwrap();
                    *top = *top * m;
                }

                DrawCommand::Rectangle { mode, x, y, w, h } => {
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
                DrawCommand::RoundedRectangle {
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
                DrawCommand::Circle { mode, x, y, r } => {
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
                DrawCommand::Ellipse { mode, x, y, rx, ry } => {
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
                DrawCommand::Triangle {
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
                DrawCommand::Polygon { mode, vertices } => {
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
                DrawCommand::Line { x1, y1, x2, y2 } => {
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
                DrawCommand::Polyline { points } => {
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
                DrawCommand::Arc {
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

                DrawCommand::SetBlendMode(mode) => {
                    current_blend_mode = *mode;
                }

                DrawCommand::Print { text, x, y, scale } => {
                    let t = transform_stack.last().unwrap();
                    let mut verts = Vec::new();
                    let mut idxs = Vec::new();
                    render_text(
                        &mut verts,
                        &mut idxs,
                        t,
                        current_color,
                        text,
                        *x,
                        *y,
                        *scale,
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

                DrawCommand::DrawImage { texture_key, x, y } => {
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
                DrawCommand::DrawImageEx {
                    texture_key,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
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
                DrawCommand::DrawQuad {
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
                DrawCommand::PrintFont {
                    font_key,
                    ref text,
                    x,
                    y,
                    scale,
                } => {
                    if let Some(font) = fonts.get_mut(*font_key) {
                        for ch in text.chars() {
                            font.ensure_glyph(ch);
                        }

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
                DrawCommand::DrawBatch { batch_key } => {
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
                DrawCommand::SetCanvas(canvas) => {
                    current_target = match canvas {
                        Some(key) => RenderTargetId::Canvas(*key),
                        None => RenderTargetId::Screen,
                    };
                    self.render_stats.canvas_switches += 1;
                }
                DrawCommand::RegisterCanvas { .. } => {}
                DrawCommand::DrawCanvas {
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
                DrawCommand::SetPointSize(size) => {
                    point_size = *size;
                }

                DrawCommand::SetScissor(rect) => {
                    current_scissor = *rect;
                }

                DrawCommand::SetColorMask(r, g, b, a) => {
                    color_mask_bits = color_write_mask_bits((*r, *g, *b, *a));
                }

                DrawCommand::SetWireframe(enabled) => {
                    wireframe = *enabled;
                }

                DrawCommand::Points { points } => {
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
                DrawCommand::PrintFormatted {
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

                        for line in &wrapped {
                            for ch in line.chars() {
                                font.ensure_glyph(ch);
                            }
                        }

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

                DrawCommand::StencilBegin { action, value } => {
                    stencil_mode = StencilMode::Write(*action);
                    stencil_reference = *value;
                }
                DrawCommand::StencilEnd => {
                    stencil_mode = StencilMode::Disabled;
                }
                DrawCommand::SetStencilTest(test) => match test {
                    Some((compare, value)) => {
                        stencil_mode = StencilMode::Test(*compare);
                        stencil_reference = *value;
                    }
                    None => {
                        stencil_mode = StencilMode::Disabled;
                        stencil_reference = 0;
                    }
                },
                DrawCommand::DrawMesh {
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
                DrawCommand::SyncMesh { .. } => {}
                DrawCommand::DrawNineSlice {
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
                        let ns = crate::graphics::NineSlice::new(
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
                DrawCommand::SetShader(shader) => {
                    active_shader = shader.filter(|key| shaders.contains_key(*key));
                }
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

        self.queue.submit(std::iter::once(encoder.finish()));
        output.present();
        Ok(())
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
        canvases: &SlotMap<CanvasKey, crate::graphics::Canvas>,
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
    /// Capture the current frame and deliver pixels to a callback.
    ///
    /// This is a stub implementation — in a full wgpu-backed build the swapchain
    /// surface texture would be copied into a wgpu::Buffer, mapped on the next
    /// frame, and the BGRA→RGBA-converted bytes passed to callback.
    ///
    /// As a headless-compatible stub the callback is invoked immediately with an
    /// empty pixel buffer and the current viewport dimensions.
    ///
    /// # Parameters
    /// - callback — Box<dyn FnOnce(Vec<u8>, u32, u32) + Send>. Receives (pixels, width, height).
    pub fn request_screenshot(&mut self, callback: Box<dyn FnOnce(Vec<u8>, u32, u32) + Send>) {
        // Stub: full GPU readback requires async buffer mapping. Until then,
        // deliver an empty frame so callers can depend on the public API surface.
        callback(vec![], self.width, self.height);
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

/// Parse a Lua string into a wgpu `FilterMode`.
///
/// # Returns
/// `wgpu::FilterMode`.
///
/// # Parameters
/// - `value` — `&str`
pub(super) fn parse_filter_mode(value: &str) -> wgpu::FilterMode {
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

fn compare_function(compare: crate::graphics::renderer::CompareMode) -> wgpu::CompareFunction {
    match compare {
        crate::graphics::renderer::CompareMode::Equal => wgpu::CompareFunction::Equal,
        crate::graphics::renderer::CompareMode::NotEqual => wgpu::CompareFunction::NotEqual,
        crate::graphics::renderer::CompareMode::Less => wgpu::CompareFunction::Less,
        crate::graphics::renderer::CompareMode::LessEqual => wgpu::CompareFunction::LessEqual,
        crate::graphics::renderer::CompareMode::Greater => wgpu::CompareFunction::Greater,
        crate::graphics::renderer::CompareMode::GreaterEqual => wgpu::CompareFunction::GreaterEqual,
        crate::graphics::renderer::CompareMode::Always => wgpu::CompareFunction::Always,
        crate::graphics::renderer::CompareMode::Never => wgpu::CompareFunction::Never,
    }
}

fn stencil_operation(action: crate::graphics::renderer::StencilAction) -> wgpu::StencilOperation {
    match action {
        crate::graphics::renderer::StencilAction::Replace => wgpu::StencilOperation::Replace,
        crate::graphics::renderer::StencilAction::Increment => {
            wgpu::StencilOperation::IncrementClamp
        }
        crate::graphics::renderer::StencilAction::Decrement => {
            wgpu::StencilOperation::DecrementClamp
        }
        crate::graphics::renderer::StencilAction::IncrementWrap => {
            wgpu::StencilOperation::IncrementWrap
        }
        crate::graphics::renderer::StencilAction::DecrementWrap => {
            wgpu::StencilOperation::DecrementWrap
        }
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

/// Render bitmap text as coloured quads (one quad per lit pixel).
#[allow(clippy::too_many_arguments)]
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

// ─── Bitmap font ─────────────────────────────────────────────────────────────

/// Returns a 7-row × 5-bit bitmap pattern for the given character.
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

#[cfg(test)]
mod tests {
    use std::convert::TryInto;

    use super::*;
    use crate::graphics::renderer::{CompareMode, StencilAction};

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
