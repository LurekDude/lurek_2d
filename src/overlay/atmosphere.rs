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
