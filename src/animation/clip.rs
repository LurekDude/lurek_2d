
//! - Defines named animation clips as reusable frame-index ranges.
//! - Stores playback direction, looping state, and fallback FPS for clips that do not rely on per-frame timing.
//! - Gives higher animation systems a compact clip descriptor they can switch, reuse, and combine by name.

/// Supported clip playback modes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ClipPlaybackMode {
    /// Play frames forward.
    Forward,
    /// Play frames backward.
    Reverse,
    /// Bounce between ends.
    PingPong,
}
/// Named animation clip referencing frame indices.
#[derive(Debug, Clone)]
pub struct AnimClip {
    /// Clip name.
    pub name: String,
    /// Indices into the frame list.
    pub frame_indices: Vec<usize>,
    /// Frames per second used when frame durations are absent.
    pub fps: f32,
    /// Whether the clip loops.
    pub looping: bool,
    /// Playback mode.
    pub mode: ClipPlaybackMode,
}
