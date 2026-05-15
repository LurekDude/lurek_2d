//! - Fixed-capacity circular buffer with oldest-overwrite FIFO semantics
//! - Push, pop, peek, and index-based access with O(1) operations
//! - Iteration and collection helpers from oldest to newest element
//! - Copy-optimized collection for `Clone + Copy` element types

/// Hold circular queue storage with overwrite semantics.
pub struct RingBuffer<T: Clone> {
    /// Store slots for buffered values.
    data: Vec<Option<T>>,
    /// Store max number of elements.
    capacity: usize,
    /// Store index of oldest element.
    head: usize,
    /// Store current number of elements.
    len: usize,
}
impl<T: Clone> RingBuffer<T> {
    /// Create ring buffer with capacity clamped to at least one.
    pub fn new(capacity: usize) -> Self {
        let cap = capacity.max(1);
        let data = vec![None; cap];
        Self {
            data,
            capacity: cap,
            head: 0,
            len: 0,
        }
    }
    /// Push value and return true when buffer was not full.
    pub fn push(&mut self, value: T) -> bool {
        let had_space = self.len < self.capacity;
        if had_space {
            let write_pos = (self.head + self.len) % self.capacity;
            self.data[write_pos] = Some(value);
            self.len += 1;
        } else {
            self.data[self.head] = Some(value);
            self.head = (self.head + 1) % self.capacity;
        }
        had_space
    }
    /// Pop oldest value and return optional element.
    pub fn pop(&mut self) -> Option<T> {
        if self.len == 0 {
            return None;
        }
        let val = self.data[self.head].take();
        self.head = (self.head + 1) % self.capacity;
        self.len -= 1;
        val
    }
    /// Return oldest element reference.
    pub fn peek(&self) -> Option<&T> {
        if self.len == 0 {
            None
        } else {
            self.data[self.head].as_ref()
        }
    }
    /// Return newest element reference.
    pub fn peek_newest(&self) -> Option<&T> {
        if self.len == 0 {
            None
        } else {
            let newest = (self.head + self.len - 1) % self.capacity;
            self.data[newest].as_ref()
        }
    }
    /// Return element by logical index from oldest.
    pub fn get(&self, index: usize) -> Option<&T> {
        if index >= self.len {
            None
        } else {
            let physical = (self.head + index) % self.capacity;
            self.data[physical].as_ref()
        }
    }
    /// Return configured capacity.
    pub fn capacity(&self) -> usize {
        self.capacity
    }
    /// Return current element count.
    pub fn len(&self) -> usize {
        self.len
    }
    /// Return true when element count is zero.
    pub fn is_empty(&self) -> bool {
        self.len == 0
    }
    /// Return true when element count equals capacity.
    pub fn is_full(&self) -> bool {
        self.len == self.capacity
    }
    /// Clear all elements and reset indices.
    pub fn clear(&mut self) {
        for slot in &mut self.data {
            *slot = None;
        }
        self.head = 0;
        self.len = 0;
    }
    /// Iterate elements from oldest to newest.
    pub fn iter(&self) -> impl Iterator<Item = &T> {
        (0..self.len).map(move |i| {
            let physical = (self.head + i) % self.capacity;
            self.data[physical].as_ref().unwrap()
        })
    }
    /// Clone elements into Vec from oldest to newest.
    pub fn to_vec(&self) -> Vec<T> {
        (0..self.len)
            .map(|i| {
                let physical = (self.head + i) % self.capacity;
                self.data[physical].clone().unwrap()
            })
            .collect()
    }
    /// Collect references into Vec from oldest to newest.
    pub fn to_refs(&self) -> Vec<&T> {
        self.iter().collect()
    }
}
impl<T: Clone + Copy> RingBuffer<T> {
    /// Copy elements into Vec from oldest to newest.
    pub fn collect_copy(&self) -> Vec<T> {
        (0..self.len)
            .map(|i| {
                let physical = (self.head + i) % self.capacity;
                *self.data[physical].as_ref().unwrap()
            })
            .collect()
    }
}
