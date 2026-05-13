//! Describe events emitted by animation playback updates.

// ---- Type: AnimEvent ----

/// Events emitted by [`Animation::update`](crate::animation::Animation::update).
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

impl AnimEvent {
    // ---- Implementation: AnimEvent ----
    /// Return the event type as a Lua-friendly string.
    pub fn type_name(&self) -> &'static str {
        match self {
            Self::Finished => "finished",
            Self::FrameChanged { .. } => "frameChanged",
            Self::Looped => "looped",
        }
    }

    /// Return the frame index for `FrameChanged` events, or `None`.
    pub fn frame_index(&self) -> Option<usize> {
        match self {
            Self::FrameChanged { frame_index } => Some(*frame_index),
            _ => None,
        }
    }
}
