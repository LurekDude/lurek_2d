//! Atmospheric visual effects data models.
//!
//! Contains data-only structs for clouds, fog, vignette, lightning,
//! film grain, and heat haze — all consumed by the overlay renderer.

/// Cloud shadow overlay state.
///
/// Renders `count` soft shadow blobs that drift horizontally across the
/// screen. The `offset` field is an internal scroll accumulator that
/// advances by `speed * dt` each frame; the renderer uses it as a UV
/// shift and the value is allowed to grow without bound (the renderer
/// wraps it modulo screen width). Adjust `scale` to change blob size and
/// `opacity` to control how dark the shadows appear.
///
/// # Fields
/// - `enabled` — `bool` — Whether cloud shadows are active.
/// - `count` — `u32` — Number of cloud shadow blobs rendered each frame.
/// - `speed` — `f32` — Horizontal scroll speed in pixels per second.
/// - `scale` — `f32` — Relative blob size (1.0 = default).
/// - `opacity` — `f32` — Shadow overlay opacity (0.0–1.0).
/// - `offset` — `f32` — Internal accumulator; used by the renderer as a UV offset.
#[derive(Debug, Clone)]
pub struct CloudState {
    /// Whether cloud shadows are active.
    pub enabled: bool,
    /// Number of cloud shadow blobs.
    pub count: u32,
    /// Cloud movement speed.
    pub speed: f32,
    /// Cloud blob size.
    pub scale: f32,
    /// Shadow opacity (0.0–1.0).
    pub opacity: f32,
    /// Internal scroll offset.
    pub offset: f32,
}

impl Default for CloudState {
    fn default() -> Self {
        Self {
            enabled: false,
            count: 5,
            speed: 20.0,
            scale: 1.0,
            opacity: 0.3,
            offset: 0.0,
        }
    }
}

/// Atmospheric fog state.
///
/// Renders a uniform translucent colour rectangle over the entire scene,
/// simulating thick atmospheric haze. The `density` field maps linearly
/// to the overlay opacity — a `density` of 1.0 fills the screen with
/// the solid `color`; 0.0 is invisible. This is a simple per-frame alpha
/// blend and does not perform any distance-based depth fog calculation.
/// For a subtler ground-level effect, pair it with a low opacity and a
/// grey-blue tint.
///
/// # Fields
/// - `enabled` — `bool` — Whether fog is active.
/// - `density` — `f32` — Fog opacity (0.0–1.0); maps directly to blend alpha.
/// - `color` — `[f32; 4]` — Fog tint colour (RGBA).
#[derive(Debug, Clone)]
pub struct FogState {
    /// Whether fog is active.
    pub enabled: bool,
    /// Fog density.
    pub density: f32,
    /// Fog colour (RGBA).
    pub color: [f32; 4],
}

impl Default for FogState {
    fn default() -> Self {
        Self {
            enabled: false,
            density: 0.3,
            color: [0.7, 0.7, 0.8, 1.0],
        }
    }
}

/// Heat haze distortion state.
///
/// Provides a UV-space shimmer distortion driven by a slowly-evolving
/// sine wave pattern. The `intensity` field scales the peak UV offset in
/// screen-space pixels — values in the 0.2–2.0 range produce a subtle
/// desert mirage effect; higher values are suitable for extreme heat or
/// magical distortion. The GPU layer in `lua_api` animates the sine phase
/// using the current game time, so no per-frame Lua call is needed.
///
/// # Fields
/// - `enabled` — `bool` — Whether heat haze distortion is active.
/// - `intensity` — `f32` — Peak UV displacement in pixels (typical range 0.0–5.0).
#[derive(Debug, Clone)]
pub struct HeatHazeState {
    /// Whether heat haze is active.
    pub enabled: bool,
    /// Distortion strength.
    pub intensity: f32,
}

impl Default for HeatHazeState {
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.5,
        }
    }
}

/// Vignette screen-edge darkening state.
///
/// Applies a smooth radial darkening that grades from transparent at the
/// screen centre to opaque black at the corners. The `strength` value
/// controls how aggressively the edges are darkened: 0.0 produces no
/// visible effect; 0.5 is a gentle film-like border; 1.0 crushes the
/// corners to near-black. The vignette is useful for directing the
/// player's eye toward the centre of the screen and for conveying
/// low-health or tense atmospheric states.
///
/// # Fields
/// - `enabled` — `bool` — Whether vignette darkening is active.
/// - `strength` — `f32` — Edge darkening intensity (0.0–1.0; default 0.5).
#[derive(Debug, Clone)]
pub struct VignetteState {
    /// Whether vignette is active.
    pub enabled: bool,
    /// Darkening intensity.
    pub strength: f32,
}

impl Default for VignetteState {
    fn default() -> Self {
        Self {
            enabled: false,
            strength: 0.5,
        }
    }
}

/// Film grain noise overlay state.
///
/// Adds randomised per-pixel luminance noise over the rendered scene,
/// simulating the grain of analog film stock. The noise pattern is
/// regenerated every frame by the GPU layer so it does not repeat or
/// flicker in a regular pattern. `intensity` scales the peak noise
/// amplitude: 0.1–0.3 gives a subtle cinematic look; values above 0.5
/// produce a heavy grain that can obscure fine detail.
///
/// # Fields
/// - `enabled` — `bool` — Whether film grain noise is active.
/// - `intensity` — `f32` — Grain amplitude (0.0–1.0; default 0.3).
#[derive(Debug, Clone)]
pub struct FilmGrainState {
    /// Whether film grain is active.
    pub enabled: bool,
    /// Grain noise intensity.
    pub intensity: f32,
}

impl Default for FilmGrainState {
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.3,
        }
    }
}

/// Lightning flash state.
///
/// A single-shot full-screen hard flash distinct from `FlashState`:
/// lightning uses a very short default duration (0.15 s) and is
/// designed to simulate the brief, intense luminosity of a lightning
/// bolt. Trigger it with `Overlay::trigger_lightning`; the flash is
/// non-repeating and deactivates automatically once `elapsed >= duration`.
/// For sustained ambient flicker, chain repeated `trigger_lightning`
/// calls from Lua with randomised delays.
///
/// # Fields
/// - `active` — `bool` — Whether a lightning flash is in progress.
/// - `color` — `[f32; 4]` — Flash colour (RGBA); defaults to pale blue-white.
/// - `elapsed` — `f32` — Time elapsed since the last trigger (seconds).
/// - `duration` — `f32` — Total flash duration in seconds (default 0.15).
#[derive(Debug, Clone)]
pub struct LightningState {
    /// Whether a lightning flash is in progress.
    pub active: bool,
    /// Lightning flash colour (RGBA).
    pub color: [f32; 4],
    /// Time elapsed since lightning trigger.
    pub elapsed: f32,
    /// Total flash duration.
    pub duration: f32,
}

impl Default for LightningState {
    fn default() -> Self {
        Self {
            active: false,
            color: [0.9, 0.9, 1.0, 0.8],
            elapsed: 0.0,
            duration: 0.15,
        }
    }
}
