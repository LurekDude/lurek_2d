#[derive(Debug, Default, Clone)]
pub struct StackMeta {
    pub capacity: usize,
}
impl StackMeta {
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}
#[derive(Debug, Default, Clone)]
pub struct QueueMeta {
    pub capacity: usize,
}
impl QueueMeta {
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}
