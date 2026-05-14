
/// Capacity metadata for a bounded stack.
#[derive(Debug, Default, Clone)]
pub struct StackMeta {
    /// Maximum number of elements; `0` means unbounded.
    pub capacity: usize,
}
/// Methods for `StackMeta`.
impl StackMeta {
    /// Create metadata with `capacity` (`0` = unbounded).
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }
    /// Return true when `len` is at or above a non-zero capacity limit.
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}

/// Capacity metadata for a bounded queue.
#[derive(Debug, Default, Clone)]
pub struct QueueMeta {
    /// Maximum number of elements; `0` means unbounded.
    pub capacity: usize,
}
/// Methods for `QueueMeta`.
impl QueueMeta {
    /// Create metadata with `capacity` (`0` = unbounded).
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }
    /// Return true when `len` is at or above a non-zero capacity limit.
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}
