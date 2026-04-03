//! Mod implementation for the `graphics` subsystem.
//!
//! This module is part of Luna2D's `graphics` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
/// Sprite-sheet frame animation with configurable durations and looping.
pub mod animation;
/// 2D camera with position, zoom, and rotation producing a view matrix.
pub mod camera;
/// Off-screen render targets (canvases) for deferred compositing.
pub mod canvas;
/// Wolfenstein-style raycasting column batch renderer.
pub mod column_batch;
/// Mathematical function graph and chart renderer.
pub mod data_graph_renderer;
/// Persistent surface for stamping decal textures.
pub mod decal_surface;
/// Z-ordered draw layer for controlling render order.
pub mod draw_layer;
/// TTF/OTF font loading, glyph rasterization, and atlas packing.
pub mod font;
/// GPU-accelerated renderer backed by wgpu (primary runtime renderer).
pub mod gpu_renderer;
/// Optimized renderer for large tile-based maps with chunking and LOD.
pub mod large_map_renderer;
/// 2D point light data container for lighting systems.
pub mod light2d;
/// Custom geometry mesh with per-vertex position, UV, and color data.
pub mod mesh;
/// Nine-slice (9-patch) image rendering for scalable UI elements.
pub mod nine_slice;
/// Color palette lookup table for shader-based palette swapping.
pub mod palette_lut;
/// Polygon map renderer with region management and hit detection.
pub mod polygon_map;
/// DrawCommand queue, draw enums, and texture data types.
pub mod renderer;
/// Custom WGSL shader support with uniform variables.
pub mod shader;
/// Sprite struct combining a texture, transform, and tint color.
pub mod sprite;
/// Sprite batching for efficient rendering of many sprites sharing one texture.
pub mod sprite_batch;
/// Grid-based sprite sheet with directional support and named groups.
pub mod sprite_sheet;
/// RGBA Color struct with named constants and conversion helpers.
pub mod srgb;
/// Texture loading and TextureData storage for the renderer.
pub mod texture;
/// CPU-side bin-packing texture atlas using shelf algorithm.
pub mod texture_atlas;
/// Trail renderer for fading ribbon effects.
pub mod trail;
/// Virtual resolution viewport with manual transform application.
pub mod viewport;
/// Virtual resolution viewport with automatic scaling.
pub mod viewport_scale;

pub use animation::{Animation, AnimationFrame};
pub use camera::{Camera, Camera2D};
pub use canvas::Canvas;
pub use column_batch::{ColumnBatch, ColumnData};
pub use data_graph_renderer::{GraphRenderer, GraphSeries};
pub use decal_surface::DecalSurface;
pub use draw_layer::DrawLayer;
pub use font::Font;
pub use gpu_renderer::GpuRenderer;
pub use large_map_renderer::LargeMapRenderer;
pub use light2d::Light2D;
pub use mesh::{Mesh, MeshDrawMode, MeshVertex};
pub use nine_slice::{NineSlice, Patch};
pub use palette_lut::PaletteLUT;
pub use polygon_map::PolygonMap;
pub use renderer::{
    BlendMode, CompareMode, DepthMode, DrawCommand, DrawableKind, DrawMode, StencilAction,
    StencilMode, TextAlign, TextureData,
};
pub use shader::{Shader, UniformValue};
pub use sprite::Sprite;
pub use sprite_batch::SpriteBatch;
pub use sprite_sheet::SpriteSheet;
pub use srgb::Color;
pub use texture::Texture;
pub use texture_atlas::TextureAtlas;
pub use trail::Trail;
pub use viewport::{ScaleMode, Viewport};
pub use viewport_scale::ViewportScale;
