//! Mod implementation for the `graphics` subsystem.
//!
//! This module is part of Lurek2D's `graphics` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
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
/// Nine-slice (9-patch) image rendering for scalable UI elements.
/// RenderCommand queue, draw enums, and texture data types.
pub mod renderer;
/// Custom WGSL shader support with uniform variables.
pub mod shader;
/// Compound shape builder that accumulates vector primitives for batched drawing.
pub mod shape;
/// Sprite struct combining a texture, transform, and tint color.
/// Sprite batching for efficient rendering of many sprites sharing one texture.
/// Grid-based sprite sheet with directional support and named groups.
/// Texture loading and TextureData storage for the renderer.
/// CPU-side bin-packing texture atlas using shelf algorithm.
pub use canvas::Canvas;
pub use decal_surface::DecalSurface;
pub use draw_layer::DrawLayer;
pub use font::Font;
pub use gpu_renderer::GpuRenderer;
pub use image_effect::ShaderPassDescriptor;
pub use mesh::{Mesh, MeshDrawMode, MeshVertex};
pub use renderer::{
    BlendMode, CompareMode, DepthMode, DrawMode, DrawableKind, RenderCommand, StencilAction,
    StencilMode, TextAlign, TextureData,
};
pub use shader::{Shader, UniformValue};
pub use shape::{CompoundShape, ShapeCommand};
