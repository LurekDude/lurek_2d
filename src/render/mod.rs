//! Render subsystem entry point. Re-exports all public render types used by the
//! Lua API, raycaster, UI, and scene layers. Owns no rendering logic directly;
//! each submodule carries its own responsibility. GPU state lives in `gpu_renderer`.

/// CPU-side canvas API: paint-style pixel and shape commands on an `ImageData` surface.
pub mod canvas;
/// Decal surface for projecting persistent paint-style marks onto world geometry.
pub mod decal_surface;
/// Draw-layer abstraction: ordered buckets of `RenderCommand`s flushed each frame.
pub mod draw_layer;
/// Fontdue-backed font rasterisation and glyph atlas management.
pub mod font;
/// wgpu device/queue wrapper, pipeline creation, render-pass execution.
pub mod gpu_renderer;
/// Per-frame image post-processing effect descriptors and shader parameter blocks.
pub mod image_effect;
/// GPU-uploadable mesh geometry: vertices, indices, and draw modes.
pub mod mesh;
/// Wavefront OBJ parser producing `Mesh` instances from `.obj` text data.
pub mod obj_loader;
/// Post-effect pipeline: chain of `ShaderPassDescriptor`s applied after the main pass.
pub mod postfx_pipeline;
/// `RenderCommand` enum and all draw-state types consumed by `GpuRenderer`.
pub mod renderer;
/// User-uploaded WGSL shader wrappers and `UniformValue` binding types.
pub mod shader;
/// Compound 2D shape builder using `ShapeCommand` sequences.
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
