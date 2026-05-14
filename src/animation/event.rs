
/// Event emitted by `Animation`.
#[derive(Debug, Clone, PartialEq)]
pub enum AnimEvent {
    /// Playback finished.
    Finished,
    /// Frame index changed.
    FrameChanged {
        /// New frame index.
        frame_index: usize,
    },
    /// Playback wrapped back to the start.
    Looped,
}
impl AnimEvent {
    /// Return the canonical event type name.
    pub fn type_name(&self) -> &'static str {
        match self {
            Self::Finished => "finished",
            Self::FrameChanged { .. } => "frameChanged",
            Self::Looped => "looped",
        }
    }
    /// Return the frame index for `FrameChanged`, or `None` for other events.
    pub fn frame_index(&self) -> Option<usize> {
        match self {
            Self::FrameChanged { frame_index } => Some(*frame_index),
            _ => None,
        }
    }
}
