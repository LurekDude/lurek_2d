//! GPU rendering layer backed by wgpu 22.
//!
//! Implements a deferred `RenderCommand` queue: Lua callbacks push draw commands into
//! `SharedState::pending_commands` during `lurek.draw()` / `lurek.draw_ui()`; after all
//! callbacks return, [`gpu_renderer::GpuRenderer::render_frame()`] processes the queue,
//! batches compatible draw calls, and presents the swapchain surface. No GPU work is done
//! inside a Lua closure.
//!
//! ## Subsystem inventory
//! - [`renderer`] — `RenderCommand` enum, draw enums, and texture data types
//! - [`gpu_renderer`] — [`GpuRenderer`]: wgpu device, queue, surface, resource pools
//! - [`canvas`] — [`Canvas`]: off-screen render-to-texture for post-processing
//! - [`font`] — [`Font`]: fontdue glyph rasterization and GPU atlas management
//! - [`shader`] — [`Shader`]: user-supplied WGSL with uniform variable table
//! - [`shape`] — compound vector shape builder for batched drawing
//! - [`mesh`] — custom vertex geometry with per-vertex position, UV, and color
//! - [`postfx_pipeline`] — ping-pong texture passes for multi-pass post-processing
//! - [`draw_layer`] — Z-ordered draw layer for painter's-algorithm sorting
//! - [`decal_surface`] — persistent surface for accumulated decal stamps
//! - [`image_effect`] — per-image shader-effect pass descriptor
//!
//! All public items are documented. Lua bridge: `src/lua_api/render_api.rs` (registered as `lurek.renders.*`).

/// Off-screen render targets (canvases) for deferred compositing.
pub mod canvas;
/// Persistent surface for stamping decal textures.
pub mod decal_surface;
/// Z-ordered draw layer for controlling render order.
pub mod draw_layer;
/// TTF/OTF font loading, glyph rasterization, and atlas packing.
pub mod font;
/// GPU-accelerated renderer backed by wgpu (primary runtime renderer).
pub mod gpu_renderer;
/// Lightweight per-image shader-effect pass data for the draw command pipeline.
pub mod image_effect;
/// Custom geometry mesh with per-vertex position, UV, and color data.
pub mod mesh;
/// Custom OBJ loader for importing 3D models.
pub mod obj_loader;
/// GPU pipeline for post-processing effects: capture, ping-pong shader passes, and compositing.
pub mod postfx_pipeline;
/// RenderCommand queue, draw enums, and texture data types.
pub mod renderer;
/// Custom WGSL shader support with uniform variables.
pub mod shader;
/// Compound shape builder that accumulates vector primitives for batched drawing.
pub mod shape;

pub use canvas::Canvas;
pub use decal_surface::DecalSurface;
pub use draw_layer::DrawLayer;
pub use font::Font;
pub use gpu_renderer::GpuRenderer;
pub use image_effect::ShaderPassDescriptor;
pub use mesh::{Mesh, MeshDrawMode, MeshVertex};
pub use postfx_pipeline::PostFxPipeline;
pub use renderer::{
    BlendMode, CompareMode, DepthMode, DrawMode, DrawableKind, RenderCommand, StencilAction,
    StencilMode, TextAlign, TextureData,
};
pub use shader::{Shader, UniformValue};
pub use shape::{CompoundShape, ShapeCommand};
