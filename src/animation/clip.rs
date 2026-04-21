//! [`AnimClip`] â€” a named animation clip referencing frames by index.

/// A named animation clip that references frames by index into the parent
///
/// # Fields
/// - `name` â€” `String`.
/// - `frame_indices` â€” `Vec<usize>`.
/// - `fps` â€” `f32`.
/// - `looping` â€” `bool`.
///
/// [`Animation`](crate::animation::Animation)'s frame pool.
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
}
