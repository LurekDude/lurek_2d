//! Parallax background layer data model.
//!
//! Pure-Rust domain module — no mlua imports. All Lua binding code lives in
//! `src/lua_api/parallax_api.rs`.

use crate::engine::resource_keys::TextureKey;
use crate::graphics::BlendMode;

// ── ParallaxDrawBatch ────────────────────────────────────────────────────────

/// Computed draw batch for a single parallax layer, produced by
/// [`ParallaxLayer::build_draw_calls`].
///
/// # Fields
/// - `texture_key` — Handle to the loaded GPU texture.
/// - `tiles` — Screen-space `(x, y)` top-left positions for each tile instance.
/// - `sx` — Horizontal scale factor for `DrawImageEx`.
/// - `sy` — Vertical scale factor for `DrawImageEx`.
/// - `color` — Pre-multiplied RGBA color (tint × opacity).
/// - `blend_mode` — Blend mode for compositing this layer.
pub struct ParallaxDrawBatch {
    /// Handle to the loaded GPU texture.
    pub texture_key: TextureKey,
    /// Screen-space `(x, y)` top-left positions for each tile instance.
    pub tiles: Vec<(f32, f32)>,
    /// Horizontal scale factor applied to the native texture width.
    pub sx: f32,
    /// Vertical scale factor applied to the native texture height.
    pub sy: f32,
    /// Pre-multiplied RGBA color — `tint * opacity` already combined.
    pub color: [f32; 4],
    /// Blend mode for compositing this layer.
    pub blend_mode: BlendMode,
}

// ── ParallaxLayer ────────────────────────────────────────────────────────────

/// A single scrolling background layer in a parallax background system.
///
/// Holds all parameters (scroll, tiling, visual) and accumulates autonomous
/// scroll over time via [`ParallaxLayer::update`].  Call
/// [`ParallaxLayer::build_draw_calls`] each frame to obtain the tile positions
/// to push to the `DrawCommand` queue.
///
/// # Fields
/// - `texture_key` — GPU texture to draw.
/// - `texture_width` — Native texture width in pixels.
/// - `texture_height` — Native texture height in pixels.
/// - `scroll_factor` — Per-axis scroll multiplier relative to camera movement.
/// - `offset` — Static world-pixel bias added on top of scroll.
/// - `autoscroll` — Autonomous scroll velocity in world-pixels per second.
/// - `autoscroll_accum` — Accumulated autoscroll offset advanced by `update`.
/// - `repeat_x` — Whether the layer tiles on the X axis.
/// - `repeat_y` — Whether the layer tiles on the Y axis.
/// - `clamp_min` — Optional minimum world-pixel offset per axis.
/// - `clamp_max` — Optional maximum world-pixel offset per axis.
/// - `z` — Draw order; lower values render first (further back).
/// - `opacity` — Layer-wide opacity in `[0.0, 1.0]`.
/// - `tint` — Multiplicative RGBA tint.
/// - `blend_mode` — GPU blend mode for compositing.
/// - `visible` — Whether this layer is drawn.
/// - `scale` — Texture display scale `[sx, sy]`.
pub struct ParallaxLayer {
    // --- Texture resource ---
    /// GPU texture to draw for this layer.
    pub texture_key: TextureKey,
    /// Native texture width in pixels (used for tile-repeat math).
    pub texture_width: f32,
    /// Native texture height in pixels (used for tile-repeat math).
    pub texture_height: f32,

    // --- Scroll ---
    /// Per-axis scroll multiplier relative to camera movement.
    ///
    /// `[0.0, 0.0]` = fully fixed (sky/overlay); `[1.0, 1.0]` = moves with
    /// the camera (no parallax); `[0.3, 0.0]` = slow distant background.
    pub scroll_factor: [f32; 2],

    /// Static world-pixel bias added on top of both camera scroll and autoscroll.
    /// Use to set the initial horizontal/vertical position of the layer.
    pub offset: [f32; 2],

    /// Autonomous scroll velocity in world-pixels per second.
    ///
    /// Applied cumulatively each frame by [`ParallaxLayer::update`].  Positive
    /// X scrolls right; positive Y scrolls down.
    pub autoscroll: [f32; 2],

    /// Accumulated autonomous scroll since creation or last [`ParallaxLayer::reset_autoscroll`].
    pub autoscroll_accum: [f32; 2],

    // --- Tiling ---
    /// Whether the layer wraps (tiles) on the X axis.
    pub repeat_x: bool,
    /// Whether the layer wraps (tiles) on the Y axis.
    pub repeat_y: bool,

    /// Optional minimum world-pixel scroll offset `[min_x, min_y]` (clamps scroll).
    pub clamp_min: Option<[f32; 2]>,
    /// Optional maximum world-pixel scroll offset `[max_x, max_y]` (clamps scroll).
    pub clamp_max: Option<[f32; 2]>,

    // --- Visual ---
    /// Draw order relative to other layers.  Lower values render first (further back).
    pub z: i32,
    /// Layer-wide opacity override in `[0.0, 1.0]`.
    pub opacity: f32,
    /// Multiplicative RGBA tint applied to every pixel of this layer.
    pub tint: [f32; 4],
    /// GPU blend mode used when compositing this layer onto the framebuffer.
    pub blend_mode: BlendMode,
    /// Whether this layer is included in draw output.
    pub visible: bool,

    /// Texture scale factor `[sx, sy]`.
    ///
    /// Values > 1 zoom in (fewer, larger tiles); values < 1 zoom out (more,
    /// smaller tiles show more of the texture world).
    pub scale: [f32; 2],
}

impl ParallaxLayer {
    /// Creates a new `ParallaxLayer` with sensible defaults.
    ///
    /// Defaults: `scroll_factor = [1.0, 0.0]`, `opacity = 1.0`, `tint = white`,
    /// `blend_mode = Alpha`, `repeat_x = true`, `repeat_y = false`, `scale = [1.0, 1.0]`.
    ///
    /// # Parameters
    /// - `texture_key` — `TextureKey`.
    /// - `texture_width` — `f32`.
    /// - `texture_height` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(texture_key: TextureKey, texture_width: f32, texture_height: f32) -> Self {
        ParallaxLayer {
            texture_key,
            texture_width,
            texture_height,
            scroll_factor: [1.0, 0.0],
            offset: [0.0, 0.0],
            autoscroll: [0.0, 0.0],
            autoscroll_accum: [0.0, 0.0],
            repeat_x: true,
            repeat_y: false,
            clamp_min: None,
            clamp_max: None,
            z: 0,
            opacity: 1.0,
            tint: [1.0, 1.0, 1.0, 1.0],
            blend_mode: BlendMode::Alpha,
            visible: true,
            scale: [1.0, 1.0],
        }
    }

    /// Advances the autonomous scroll accumulator by `dt` seconds.
    ///
    /// Call once per frame before [`ParallaxLayer::build_draw_calls`].  Wraps
    /// the accumulator to the scaled texture boundary to prevent floating-point
    /// overflow in long sessions.
    ///
    /// # Parameters
    /// - `dt` — Frame delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        self.autoscroll_accum[0] += self.autoscroll[0] * dt;
        self.autoscroll_accum[1] += self.autoscroll[1] * dt;

        // Prevent float overflow — wrap to scaled texture size using rem_euclid
        // so the accumulator stays in [0, tex_w) and [0, tex_h).
        let tw = self.texture_width * self.scale[0];
        let th = self.texture_height * self.scale[1];
        if tw > 0.0 {
            self.autoscroll_accum[0] = self.autoscroll_accum[0].rem_euclid(tw);
        }
        if th > 0.0 {
            self.autoscroll_accum[1] = self.autoscroll_accum[1].rem_euclid(th);
        }
    }

    /// Computes the world-pixel scroll offset for the given camera position.
    ///
    /// Combines camera-driven scroll, static offset, autoscroll accumulator,
    /// and optional axis clamping.
    fn compute_pixel_offset(&self, cam_x: f32, cam_y: f32) -> (f32, f32) {
        let mut px = cam_x * self.scroll_factor[0] + self.offset[0] + self.autoscroll_accum[0];
        let mut py = cam_y * self.scroll_factor[1] + self.offset[1] + self.autoscroll_accum[1];

        if let (Some(mn), Some(mx)) = (self.clamp_min, self.clamp_max) {
            px = px.clamp(mn[0], mx[0]);
            py = py.clamp(mn[1], mx[1]);
        }

        (px, py)
    }

    /// Builds the draw tile batch for this layer.
    ///
    /// Returns `None` when the layer is invisible or degenerate (zero-size
    /// texture, opacity ≤ 0).  Otherwise returns a [`ParallaxDrawBatch`] that
    /// the API bridge converts into `DrawImageEx` commands.
    ///
    /// Repeat axes are tiled to cover the full screen.  Non-repeat axes draw a
    /// single tile offset by the scroll.
    ///
    /// # Parameters
    /// - `cam_x` — Camera world X in game-logical pixels.
    /// - `cam_y` — Camera world Y in game-logical pixels.
    /// - `screen_w` — Logical screen width in pixels.
    /// - `screen_h` — Logical screen height in pixels.
    ///
    /// # Returns
    /// `Option<ParallaxDrawBatch>`.
    pub fn build_draw_calls(
        &self,
        cam_x: f32,
        cam_y: f32,
        screen_w: f32,
        screen_h: f32,
    ) -> Option<ParallaxDrawBatch> {
        if !self.visible || self.opacity <= 0.0 {
            return None;
        }

        let tex_w = self.texture_width * self.scale[0];
        let tex_h = self.texture_height * self.scale[1];

        if tex_w <= 0.0 || tex_h <= 0.0 {
            return None;
        }

        let (px, py) = self.compute_pixel_offset(cam_x, cam_y);

        // Start position: for repeat axes use modulo so we always start at or
        // before the left/top screen edge; for non-repeat, offset directly.
        let start_x = if self.repeat_x {
            -px.rem_euclid(tex_w)
        } else {
            -px
        };
        let start_y = if self.repeat_y {
            -py.rem_euclid(tex_h)
        } else {
            -py
        };

        let mut tiles: Vec<(f32, f32)> = Vec::new();

        match (self.repeat_x, self.repeat_y) {
            (true, true) => {
                let mut tx = start_x;
                while tx < screen_w {
                    let mut ty = start_y;
                    while ty < screen_h {
                        tiles.push((tx, ty));
                        ty += tex_h;
                    }
                    tx += tex_w;
                }
            }
            (true, false) => {
                let mut tx = start_x;
                while tx < screen_w {
                    tiles.push((tx, start_y));
                    tx += tex_w;
                }
            }
            (false, true) => {
                let mut ty = start_y;
                while ty < screen_h {
                    tiles.push((start_x, ty));
                    ty += tex_h;
                }
            }
            (false, false) => {
                tiles.push((start_x, start_y));
            }
        }

        let [tr, tg, tb, ta] = self.tint;
        let color = [tr, tg, tb, ta * self.opacity];

        Some(ParallaxDrawBatch {
            texture_key: self.texture_key,
            tiles,
            sx: self.scale[0],
            sy: self.scale[1],
            color,
            blend_mode: self.blend_mode,
        })
    }

    /// Resets the autoscroll accumulator to zero.
    ///
    /// Useful for scene transitions where the autoscroll should restart from
    /// the beginning.
    pub fn reset_autoscroll(&mut self) {
        self.autoscroll_accum = [0.0, 0.0];
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;
    use slotmap::KeyData;

    fn dummy_key() -> TextureKey {
        TextureKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn parallax_layer_new_defaults() {
        let layer = ParallaxLayer::new(dummy_key(), 512.0, 256.0);
        assert!((layer.opacity - 1.0).abs() < 1e-5);
        assert!(layer.visible);
        assert!(layer.repeat_x);
        assert!(!layer.repeat_y);
        assert_eq!(layer.z, 0);
    }

    #[test]
    fn parallax_layer_update_accumulates_autoscroll() {
        let mut layer = ParallaxLayer::new(dummy_key(), 512.0, 256.0);
        layer.autoscroll = [100.0, 50.0];
        layer.update(0.5);
        assert!((layer.autoscroll_accum[0] - 50.0).abs() < 1e-4);
        assert!((layer.autoscroll_accum[1] - 25.0).abs() < 1e-4);
    }

    #[test]
    fn parallax_layer_autoscroll_wraps_within_tex_size() {
        let mut layer = ParallaxLayer::new(dummy_key(), 100.0, 100.0);
        layer.autoscroll = [100.0, 0.0];
        layer.update(1.5); // 150 px — should wrap to 50 within [0, 100)
        assert!((layer.autoscroll_accum[0] - 50.0).abs() < 1e-4);
    }

    #[test]
    fn parallax_layer_invisible_builds_no_calls() {
        let mut layer = ParallaxLayer::new(dummy_key(), 128.0, 128.0);
        layer.visible = false;
        let batch = layer.build_draw_calls(0.0, 0.0, 800.0, 600.0);
        assert!(batch.is_none());
    }

    #[test]
    fn parallax_layer_zero_opacity_builds_no_calls() {
        let mut layer = ParallaxLayer::new(dummy_key(), 128.0, 128.0);
        layer.opacity = 0.0;
        let batch = layer.build_draw_calls(0.0, 0.0, 800.0, 600.0);
        assert!(batch.is_none());
    }

    #[test]
    fn parallax_layer_non_repeat_single_tile() {
        let mut layer = ParallaxLayer::new(dummy_key(), 512.0, 512.0);
        layer.repeat_x = false;
        layer.repeat_y = false;
        let batch = layer.build_draw_calls(0.0, 0.0, 800.0, 600.0).unwrap();
        assert_eq!(batch.tiles.len(), 1);
    }

    #[test]
    fn parallax_layer_repeat_x_fills_screen() {
        let mut layer = ParallaxLayer::new(dummy_key(), 200.0, 600.0);
        layer.repeat_x = true;
        layer.repeat_y = false;
        // 800 / 200 = 4 tiles, starting at 0 offset → tiles at x=0,200,400,600
        let batch = layer.build_draw_calls(0.0, 0.0, 800.0, 600.0).unwrap();
        assert_eq!(batch.tiles.len(), 4);
    }

    #[test]
    fn parallax_layer_scroll_factor_offsets_camera() {
        let layer = ParallaxLayer::new(dummy_key(), 200.0, 200.0);
        // scroll_factor [1,0], repeat_x true, cam_x = 100
        // pixel offset = 100 * 1 = 100; start_x = -100 % 200 = -100
        let batch = layer.build_draw_calls(100.0, 0.0, 400.0, 200.0).unwrap();
        assert!((batch.tiles[0].0 - (-100.0)).abs() < 1e-4);
    }

    #[test]
    fn parallax_layer_reset_autoscroll_clears_accum() {
        let mut layer = ParallaxLayer::new(dummy_key(), 100.0, 100.0);
        layer.autoscroll = [50.0, 20.0];
        layer.update(1.0);
        layer.reset_autoscroll();
        assert!((layer.autoscroll_accum[0]).abs() < 1e-5);
        assert!((layer.autoscroll_accum[1]).abs() < 1e-5);
    }

    #[test]
    fn parallax_layer_color_multiplies_tint_and_opacity() {
        let mut layer = ParallaxLayer::new(dummy_key(), 100.0, 200.0);
        layer.repeat_x = false;
        layer.repeat_y = false;
        layer.tint = [0.5, 0.8, 1.0, 1.0];
        layer.opacity = 0.5;
        let batch = layer.build_draw_calls(0.0, 0.0, 800.0, 600.0).unwrap();
        assert!((batch.color[3] - 0.5).abs() < 1e-5); // 1.0 * 0.5 = 0.5
    }
}
