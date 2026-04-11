//! Parallax background system — multi-layer scrolling backgrounds with camera-relative
//! scroll factors, autoscroll, tiling, blend modes, and scene grouping.
//!
//! # Tier
//! Tier 2 — depends on `engine` (SharedState, TextureKey) and `graphics` (BlendMode).
//! Access to Tier 1 camera data flows through `SharedState::camera`; there is no direct
//! import of the `camera` crate module.
//!
//! # Architecture
//!
//! The domain module (`src/parallax/`) provides pure-Rust data types and scroll math.
//! All Lua binding code lives exclusively in `src/lua_api/parallax_api.rs`.
//!
//! ## Key types
//!
//! | Type | Purpose |
//! |---|---|
//! | [`ParallaxLayer`] | Single scrolling texture layer with all visual/scroll parameters |
//! | [`ParallaxDrawBatch`] | Tile position batch produced by `build_draw_calls`, consumed by the Lua bridge |
//!
//! ## Scroll formula
//!
//! ```text
//! pixel_offset = camera_pos * scroll_factor + manual_offset + autoscroll_accum
//! start_x      = -(pixel_offset_x % tex_w)   // for repeat_x = true
//! ```
//!
//! ## Lua API (registered by `src/lua_api/parallax_api.rs`)
//!
//! ```text
//! lurek.parallax.newLayer(opts)        → LuaParallaxLayer
//! lurek.parallax.newSet(name)          → LuaParallaxSet
//! layer:update(dt)
//! layer:draw(cam_x, cam_y)
//! layer:drawAuto()                     -- reads lurek.camera position
//! layer:setScrollFactor(x, y)
//! layer:setOffset(x, y)
//! layer:setAutoscroll(vx, vy)
//! layer:setRepeat(repeat_x, repeat_y)
//! layer:setScale(sx, sy)
//! layer:setZ(z)
//! layer:setOpacity(a)
//! layer:setTint(r, g, b, a)
//! layer:setBlendMode(mode)
//! layer:setVisible(v)
//! layer:setClamp(min_x, min_y, max_x, max_y)
//! layer:clearClamp()
//! layer:resetAutoscroll()
//! layer:getScrollFactor()  → x, y
//! layer:getOffset()        → x, y
//! layer:getZ()             → z
//! layer:getOpacity()       → a
//! layer:isVisible()        → bool
//! layer:type()             → "ParallaxLayer"
//! set:addLayer(layer)
//! set:removeLayerAt(index)
//! set:update(dt)
//! set:draw(cam_x, cam_y)
//! set:drawAuto()
//! set:sortByZ()
//! set:layerCount()          → n
//! set:setVisible(v)
//! set:getName()             → string
//! set:setName(name)
//! set:type()                → "ParallaxSet"
//! ```

/// Parallax layer data model and draw-call batch builder.
pub mod layer;
/// Render-command generation for parallax layers.
pub mod render;
/// CPU software-rendering fallback for headless draw-to-image.
pub mod draw;

pub use layer::{ParallaxDrawBatch, ParallaxLayer};
