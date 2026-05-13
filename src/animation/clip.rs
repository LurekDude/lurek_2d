//! Define animation clip metadata and playback modes.

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
