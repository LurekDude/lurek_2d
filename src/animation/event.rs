//! [`AnimEvent`] — events emitted during animation playback.

/// Events emitted by [`Animation::update`](crate::animation::Animation::update).
///
/// # Variants
/// - `Finished` — Finished variant.
/// - `FrameChanged` — FrameChanged variant.
/// - `Looped` — Looped variant.
///
/// Retrieve pending events with [`Animation::drain_events`](crate::animation::Animation::drain_events).
#[derive(Debug, Clone, PartialEq)]
pub enum AnimEvent {
    /// A non-looping clip reached its final frame and stopped.
    Finished,
    /// The active frame changed to `frame_index` (position within the clip's
    /// `frame_indices` list).
    FrameChanged {
        /// 0-based index within the clip's frame list.
        frame_index: usize,
    },
    /// A looping clip wrapped back to its first frame.
    Looped,
}
