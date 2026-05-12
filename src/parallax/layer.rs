//! Parallax background layer data model.
//!
//! Pure-Rust domain module — no mlua imports. All Lua binding code lives in
//! `src/lua_api/parallax_api.rs`.

use crate::render::BlendMode;
use crate::render::ShaderPassDescriptor;
use crate::runtime::resource_keys::TextureKey;
use std::collections::HashMap;

/// Smallest allowed tile size in logical pixels.
///
/// This hard floor prevents pathological draw-call explosions when scripts pass
/// tiny values to `set_tile_size`.
const MIN_TILE_SIZE: f32 = 16.0;

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
    /// Optional per-image shader pass chain for this layer.
    pub effect: Option<Vec<ShaderPassDescriptor>>,
}

// ── ParallaxLayer ────────────────────────────────────────────────────────────

/// A single scrolling background layer in a parallax background system.
///
/// Holds all parameters (scroll, tiling, visual) and accumulates autonomous
/// scroll over time via [`ParallaxLayer::update`].  Call
/// [`ParallaxLayer::build_draw_calls`] each frame to obtain the tile positions
/// to push to the `RenderCommand` queue.
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
/// - `tiling` — Whether seamless infinite tiling is enabled on both axes.
/// - `tile_w` — Optional tile width override (defaults to scaled texture width).
/// - `tile_h` — Optional tile height override (defaults to scaled texture height).
/// - `depth` — Floating-point draw depth for fine-grained ordering (default 0.0).
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

    // --- Tiling ---
    /// Whether seamless infinite tiling is enabled on both axes simultaneously.
    ///
    /// When `true`, both `repeat_x` and `repeat_y` are effectively overridden to
    /// `true` in the draw-call builder.  Setting this to `false` reverts to the
    /// individual `repeat_x`/`repeat_y` flags.
    pub tiling: bool,

    /// Optional tile width override in scaled pixels.
    ///
    /// When `Some(w)`, the tile width used for repeat math is `w` instead of
    /// `texture_width * scale[0]`.  Useful for sub-region tiling.
    pub tile_w: Option<f32>,

    /// Optional tile height override in scaled pixels.
    ///
    /// When `Some(h)`, the tile height used for repeat math is `h` instead of
    /// `texture_height * scale[1]`.
    pub tile_h: Option<f32>,

    // --- Float depth ---
    /// Floating-point draw depth for fine-grained Z ordering.
    ///
    /// Complements `z: i32` for cases where fractional ordering is needed.
    /// Lower values render first (further back).  Default is `0.0`.
    pub depth: f32,

    /// Optional per-image shader pass chain applied to each tile draw call.
    pub effect_chain: Option<Vec<ShaderPassDescriptor>>,

    /// Enables velocity-based stretch on top of base scale.
    pub motion_stretch_enabled: bool,
    /// Stretch factor per px/s of autoscroll speed.
    pub motion_stretch_strength: f32,
    /// Upper bound for per-axis stretch multiplier.
    pub motion_stretch_max_scale: f32,
}

impl ParallaxLayer {
    /// Creates a new `ParallaxLayer` with sensible defaults.
    ///
    /// Defaults: `scroll_factor = [1.0, 0.0]`, `opacity = 1.0`, `tint = white`,
    /// `blend_mode = Alpha`, `repeat_x = true`, `repeat_y = false`, `scale = [1.0, 1.0]`,
    /// `tiling = false`, `tile_w = None`, `tile_h = None`, `depth = 0.0`.
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
            tiling: false,
            tile_w: None,
            tile_h: None,
            depth: 0.0,
            effect_chain: None,
            motion_stretch_enabled: false,
            motion_stretch_strength: 0.001,
            motion_stretch_max_scale: 2.0,
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
        let (tw, th) = self.resolved_tile_dimensions();
        if tw > 0.0 {
            self.autoscroll_accum[0] = self.autoscroll_accum[0].rem_euclid(tw);
        }
        if th > 0.0 {
            self.autoscroll_accum[1] = self.autoscroll_accum[1].rem_euclid(th);
        }
    }

    fn resolved_tile_dimensions(&self) -> (f32, f32) {
        let base_w = self.texture_width * self.scale[0];
        let base_h = self.texture_height * self.scale[1];

        let tw = self.tile_w.unwrap_or(base_w).max(MIN_TILE_SIZE);
        let th = self.tile_h.unwrap_or(base_h).max(MIN_TILE_SIZE);

        (tw, th)
    }

    /// Computes the world-pixel scroll offset for the given camera position.
    ///
    /// Formula: `pixel_offset = camera * scroll_factor + manual_offset + autoscroll_accum`.
    /// Optional axis clamping is applied after accumulation to prevent the layer
    /// from scrolling beyond designer-specified bounds.
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

        let (tex_w, tex_h) = self.resolved_tile_dimensions();
        let repeat_x = self.tiling || self.repeat_x;
        let repeat_y = self.tiling || self.repeat_y;

        if tex_w <= 0.0 || tex_h <= 0.0 {
            return None;
        }

        let (px, py) = self.compute_pixel_offset(cam_x, cam_y);

        // Start position: for repeat axes use modulo so we always start at or
        // before the left/top screen edge; for non-repeat, use raw negative offset
        // so the single tile slides with the camera.
        let start_x = if repeat_x { -px.rem_euclid(tex_w) } else { -px };
        let start_y = if repeat_y { -py.rem_euclid(tex_h) } else { -py };

        let tiles = crate::parallax::tile_iter::collect_tiled_positions(
            start_x,
            start_y,
            tex_w,
            tex_h,
            repeat_x,
            repeat_y,
            [screen_w, screen_h],
        );

        let [tr, tg, tb, ta] = self.tint;
        let color = [tr, tg, tb, ta * self.opacity];
        let mut sx = if self.texture_width > 0.0 {
            tex_w / self.texture_width
        } else {
            self.scale[0]
        };
        let mut sy = if self.texture_height > 0.0 {
            tex_h / self.texture_height
        } else {
            self.scale[1]
        };

        let mut effect = self.effect_chain.clone();

        if self.motion_stretch_enabled {
            let speed_x = self.autoscroll[0].abs();
            let speed_y = self.autoscroll[1].abs();
            let max_extra = (self.motion_stretch_max_scale - 1.0).max(0.0);
            let sx_extra = (speed_x * self.motion_stretch_strength).min(max_extra);
            let sy_extra = (speed_y * self.motion_stretch_strength).min(max_extra);
            sx *= 1.0 + sx_extra;
            sy *= 1.0 + sy_extra;

            let speed = (speed_x * speed_x + speed_y * speed_y).sqrt();
            if speed > 1.0 {
                let mut params = HashMap::new();
                params.insert("strength".to_string(), (speed * 0.001).clamp(0.0, 1.0));
                params.insert(
                    "direction_x".to_string(),
                    if speed > 0.0 {
                        self.autoscroll[0] / speed
                    } else {
                        0.0
                    },
                );
                params.insert(
                    "direction_y".to_string(),
                    if speed > 0.0 {
                        self.autoscroll[1] / speed
                    } else {
                        0.0
                    },
                );

                let mut chain = effect.unwrap_or_default();
                chain.push(ShaderPassDescriptor {
                    effect_name: "motion_blur".to_string(),
                    params,
                    enabled: true,
                });
                effect = Some(chain);
            }
        }

        Some(ParallaxDrawBatch {
            texture_key: self.texture_key,
            tiles,
            sx,
            sy,
            color,
            blend_mode: self.blend_mode,
            effect,
        })
    }

    /// Resets the autoscroll accumulator to zero.
    ///
    /// Useful for scene transitions where the autoscroll should restart from
    /// the beginning.
    pub fn reset_autoscroll(&mut self) {
        self.autoscroll_accum = [0.0, 0.0];
    }

    /// Enables or disables seamless infinite tiling on both axes.
    ///
    /// When `true`, the layer tiles in both X and Y regardless of the
    /// individual `repeat_x`/`repeat_y` flags.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_tiling(&mut self, enabled: bool) {
        self.tiling = enabled;
    }

    /// Returns `true` if seamless infinite tiling is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn get_tiling(&self) -> bool {
        self.tiling
    }

    /// Sets an explicit tile size override, bypassing the scaled texture dimensions.
    ///
    /// Pass the width and height in logical pixels.  Both values must be positive;
    /// non-positive values are silently clamped to the scaled texture size.
    ///
    /// # Parameters
    /// - `w` — `f32` — tile width in pixels.
    /// - `h` — `f32` — tile height in pixels.
    pub fn set_tile_size(&mut self, w: f32, h: f32) {
        self.tile_w = if w > 0.0 {
            Some(w.max(MIN_TILE_SIZE))
        } else {
            None
        };
        self.tile_h = if h > 0.0 {
            Some(h.max(MIN_TILE_SIZE))
        } else {
            None
        };
    }

    /// Sets the floating-point draw depth for this layer.
    ///
    /// Lower values render first (further back).  Works alongside `z: i32`
    /// for cases where fractional ordering is required.
    ///
    /// # Parameters
    /// - `z` — `f32`.
    pub fn set_depth(&mut self, z: f32) {
        self.depth = z;
    }

    /// Returns the floating-point draw depth.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_depth(&self) -> f32 {
        self.depth
    }

    /// Replaces the per-layer shader pass chain.
    pub fn set_effect_chain(&mut self, chain: Vec<ShaderPassDescriptor>) {
        self.effect_chain = if chain.is_empty() { None } else { Some(chain) };
    }

    /// Clears all per-layer shader passes.
    pub fn clear_effect_chain(&mut self) {
        self.effect_chain = None;
    }

    /// Returns the number of configured per-layer shader passes.
    pub fn effect_count(&self) -> usize {
        self.effect_chain.as_ref().map_or(0, Vec::len)
    }

    /// Enables/disables velocity-based stretch and configures its range.
    pub fn set_motion_stretch(&mut self, enabled: bool, strength: f32, max_scale: f32) {
        self.motion_stretch_enabled = enabled;
        self.motion_stretch_strength = strength.max(0.0);
        self.motion_stretch_max_scale = max_scale.max(1.0);
    }
}

// ── Tests ────────────────────────────────────────────────────────────────────
