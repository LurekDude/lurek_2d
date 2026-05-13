//! Scope: Define animation clip metadata and playback modes.
//! This file defines clip playback direction and clip frame-index metadata.
//! It owns the static data used by animation playback state.

// ---- Type: ClipPlaybackMode ----

/// Playback mode for an [`AnimClip`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ClipPlaybackMode {
    /// Progresses from first frame to last frame.
    Forward,
    /// Progresses from last frame to first frame.
    Reverse,
    /// Bounces between first and last frame.
    PingPong,
}

// ---- Type: AnimClip ----

/// A named animation clip that references frame indices in the parent animation.
///
/// # Fields
/// - `name` â€” `String`.
/// - `frame_indices` â€” `Vec<usize>`.
/// - `fps` â€” `f32`.
/// - `looping` â€” `bool`.
/// - `mode` â€” [`ClipPlaybackMode`].
///
/// The indices refer to the frame pool in [`Animation`](crate::animation::Animation).
#[derive(Debug, Clone)]
pub struct AnimClip {
    /// Human-readable clip name.
    pub name: String,
    /// Indices into [`Animation::frames`](crate::animation::Animation) (0-based).
    pub frame_indices: Vec<usize>,
    /// Playback speed in frames per second.
    pub fps: f32,
    /// Whether the clip wraps around after the last frame.
    pub looping: bool,
    /// Playback mode for frame traversal.
    pub mode: ClipPlaybackMode,
}
