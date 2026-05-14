//! 2D sprite system: single sprites, texture atlases, sprite sheets, nine-slice panels, and batched drawing.
//! Owns Sprite, SpriteAtlas, SpriteSheet, NineSlice, SpriteBatch, and the TexturePacker JSON parser.
//! Does not own texture upload or GPU pipeline \u2014 those live in the render module.
//! Key dependencies: render (RenderCommand), image (ImageData), math (Rect).

/// Texture atlas region map and TexturePacker JSON parser.
pub mod atlas;
/// Nine-slice panel geometry for scalable UI borders and boxes.
pub mod nine_slice;
/// Core Sprite type with transform, tint, and region data.
#[allow(clippy::module_inception)]
pub mod sprite;
/// SpriteBatch: deferred draw-call accumulation for grouped sprite rendering.
pub mod sprite_batch;
/// SpriteSheet: uniform grid frame extraction from a single texture.
pub mod sprite_sheet;
pub use atlas::{parse_texturepacker_json, AtlasEntry, SpriteAtlas};
pub use nine_slice::NineSlice;
pub use sprite::Sprite;
pub use sprite_batch::SpriteBatch;
pub use sprite_sheet::SpriteSheet;
