//! Sprite and sprite-batch rendering types for Lurek2D.
//!
//! Provides higher-level game-graphics abstractions above the raw `RenderCommand` queue:
//! individual sprites, instanced batches, sprite sheets, nine-patch panels, and
//! TexturePacker atlas imports.
//!
//! ## Subsystem inventory
//! - [`sprite`] — [`Sprite`]: single positioned/rotated/tinted image quad
//! - [`sprite_batch`] — [`SpriteBatch`]: one-texture instanced batch → single GPU draw call
//! - [`sprite_sheet`] — [`SpriteSheet`]: named-frame UV map into a sprite sheet texture
//! - [`atlas`] — [`SpriteAtlas`]: TexturePacker JSON atlas importer with [`AtlasEntry`]
//! - [`nine_slice`] — [`NineSlice`]: 3×3 scalable patch for resizable UI panels
//!
//! Lua bridge: `src/lua_api/sprite_api.rs` as `lurek.sprite.*`.


/// TexturePacker JSON atlas importer and named region lookup.
pub mod atlas;
/// Individual sprite with position, scale, rotation, and color.
pub mod sprite;
/// Batched sprite renderer for efficient multi-sprite drawing.
pub mod sprite_batch;
/// Sprite sheet with named frame regions.
pub mod sprite_sheet;
/// Nine-slice scalable sprite for UI panels and borders.
pub mod nine_slice;

pub use atlas::{parse_texturepacker_json, AtlasEntry, SpriteAtlas};
pub use nine_slice::NineSlice;
pub use sprite::Sprite;
pub use sprite_batch::SpriteBatch;
pub use sprite_sheet::SpriteSheet;
