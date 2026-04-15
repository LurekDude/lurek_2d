//! Fixed-capacity circular ring buffer.
//!
//! [`RingBuffer<T>`] stores up to `capacity` elements in a circular layout.
//! Pushing onto a full buffer silently overwrites the oldest element.
//! Pop/peek operate in FIFO order (oldest first).

/// A fixed-capacity circular ring buffer.
///
/// When the buffer is full and a new value is pushed, the oldest element is
/// silently overwritten.  All operations are O(1).
///
/// # Type Parameters
/// - `T` — Element type; must implement `Clone`.
pub struct RingBuffer<T: Clone> {
    data: Vec<Option<T>>,
    capacity: usize,
    /// Index of the oldest element (read/pop position).
    head: usize,
    /// Number of elements currently stored.
    len: usize,
}

impl<T: Clone> RingBuffer<T> {
    /// Creates a new ring buffer with the given capacity.
    ///
    /// If `capacity` is 0 it is silently clamped to 1.
    ///
    /// # Parameters
    /// - `capacity` — Maximum number of elements the buffer can hold.
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

    /// Pushes `value` onto the buffer.
    ///
    /// Returns `true` if there was space available (no overwrite occurred).
    /// Returns `false` when the buffer was full and the oldest element was
    /// replaced.
    ///
    /// # Parameters
    /// - `value` — The element to push.
    pub fn push(&mut self, value: T) -> bool {
        let had_space = self.len < self.capacity;
        if had_space {
            let write_pos = (self.head + self.len) % self.capacity;
            self.data[write_pos] = Some(value);
            self.len += 1;
        } else {
            // Overwrite the oldest slot, then advance head.
            self.data[self.head] = Some(value);
            self.head = (self.head + 1) % self.capacity;
        }
        had_space
    }

    /// Removes and returns the oldest element (FIFO order).
    ///
    /// Returns `None` if the buffer is empty.
    pub fn pop(&mut self) -> Option<T> {
        if self.len == 0 {
            return None;
        }
        let val = self.data[self.head].take();
        self.head = (self.head + 1) % self.capacity;
        self.len -= 1;
        val
    }

    /// Returns a reference to the oldest element without removing it.
    ///
    /// Returns `None` if the buffer is empty.
    pub fn peek(&self) -> Option<&T> {
        if self.len == 0 {
            None
        } else {
            self.data[self.head].as_ref()
        }
    }

    /// Returns a reference to the newest element without removing it.
    ///
    /// Returns `None` if the buffer is empty.
    pub fn peek_newest(&self) -> Option<&T> {
        if self.len == 0 {
            None
        } else {
            let newest = (self.head + self.len - 1) % self.capacity;
            self.data[newest].as_ref()
        }
    }

    /// Returns a reference to the element at the given logical index.
    ///
    /// Index 0 refers to the oldest element; `len - 1` refers to the newest.
    /// Returns `None` if `index` is out of bounds.
    ///
    /// # Parameters
    /// - `index` — 0-based logical index (0 = oldest).
    pub fn get(&self, index: usize) -> Option<&T> {
        if index >= self.len {
            None
        } else {
            let physical = (self.head + index) % self.capacity;
            self.data[physical].as_ref()
        }
    }

    /// Returns the maximum number of elements the buffer can hold.
    pub fn capacity(&self) -> usize {
        self.capacity
    }

    /// Returns the number of elements currently stored.
    pub fn len(&self) -> usize {
        self.len
    }

    /// Returns `true` if the buffer contains no elements.
    pub fn is_empty(&self) -> bool {
        self.len == 0
    }

    /// Returns `true` if the buffer has reached its capacity.
    pub fn is_full(&self) -> bool {
        self.len == self.capacity
    }

    /// Removes all elements from the buffer.
    pub fn clear(&mut self) {
        for slot in &mut self.data {
            *slot = None;
        }
        self.head = 0;
        self.len = 0;
    }

    /// Returns all elements as a `Vec`, ordered oldest-first.
    pub fn to_vec(&self) -> Vec<T> {
        (0..self.len)
            .map(|i| {
                let physical = (self.head + i) % self.capacity;
                // SAFETY: all slots in [0, len) are guaranteed to be Some(_).
                self.data[physical].clone().unwrap()
            })
            .collect()
    }
}
