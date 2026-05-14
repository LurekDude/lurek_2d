//! Parallax scrolling subsystem: layer management, draw-batch accumulation, and tile iteration.
//! Owns the data model for multi-speed background layers and dispatches draw commands to the renderer.
//! Does not own camera math or final GPU submission; those belong in `render` and `src/render/`.
//! Key re-exports: `ParallaxLayer`, `ParallaxDrawBatch` from `layer`.

/// Stateless draw-call helpers: converts layer data into renderer `RenderCommand` payloads.
pub mod draw;
/// `ParallaxLayer` definition and `ParallaxDrawBatch` accumulator used by game code.
pub mod layer;
/// Named preset constructors for common parallax configurations (sky, mountains, clouds).
pub mod presets;
/// Integration point that calls `draw` for each active layer on every frame.
pub mod render;
/// Iterator over visible tile columns for a given layer scroll offset and screen width.
pub mod tile_iter;
pub use layer::{ParallaxDrawBatch, ParallaxLayer};
