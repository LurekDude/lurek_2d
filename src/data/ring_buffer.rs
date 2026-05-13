//! Scope: Fixed-capacity circular ring storage.
//! This file defines the RingBuffer type and FIFO buffer operations.
//! It owns overwrite-on-full behavior and oldest-first iteration order.

// ---- Type: RingBuffer ----

/// A fixed-capacity circular ring buffer.
///
/// When the buffer is full and a new value is pushed, the oldest element is
/// silently overwritten.  All operations are O(1).
///
/// # Type Parameters
/// - `T` — Element type; must implement `Clone`.
pub struct RingBuffer<T: Clone> {
    /// Backing storage for ring slots.
    data: Vec<Option<T>>,
    /// Maximum number of elements the buffer can hold.
    capacity: usize,
    /// Index of the oldest element (read/pop position).
    head: usize,
    /// Number of elements currently stored.
    len: usize,
}

// ---- Implementation: RingBuffer ----

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
            // Write position is always (head + len) mod capacity — this keeps
            // the logical ring contiguous even after wrap-around.
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

    /// Returns an iterator over borrowed references to elements, oldest-first.
    ///
    /// This is more efficient than [`Self::to_vec`] for large element types
    /// because it avoids cloning. Use this when you only need to inspect elements.
    ///
    /// # Example
    /// ```no_run
    /// let rb: RingBuffer<i32> = RingBuffer::new(5);
    /// for elem in rb.iter() {
    ///     println!("{}", elem);
    /// }
    /// ```
    pub fn iter(&self) -> impl Iterator<Item = &T> {
        (0..self.len).map(move |i| {
            let physical = (self.head + i) % self.capacity;
            // SAFETY: all slots in [0, len) are guaranteed to be Some(_).
            self.data[physical].as_ref().unwrap()
        })
    }

    /// Returns all elements as a `Vec`, ordered oldest-first.
    ///
    /// **Warning:** This method clones every element. For large element types,
    /// prefer [`Self::iter`] to avoid unnecessary cloning.
    ///
    /// # Performance Note
    /// - If `T` implements `Copy`, consider using a slice method instead if possible.
    /// - For non-Copy types, collect references via `iter()` and clone selectively.
    pub fn to_vec(&self) -> Vec<T> {
        (0..self.len)
            .map(|i| {
                let physical = (self.head + i) % self.capacity;
                // SAFETY: all slots in [0, len) are guaranteed to be Some(_).
                self.data[physical].clone().unwrap()
            })
            .collect()
    }

    /// Collects references to all elements into a `Vec`, ordered oldest-first.
    ///
    /// This is useful for efficient inspection without cloning the elements.
    /// The resulting vec contains borrows that live as long as this buffer.
    pub fn to_refs(&self) -> Vec<&T> {
        self.iter().collect()
    }
}

impl<T: Clone + Copy> RingBuffer<T> {
    /// For `Copy` types, efficiently collect all elements into a `Vec` without using `clone()`.
    ///
    /// This is equivalent to `to_vec()` but may be semantically clearer for copy types.
    /// Rust will optimize the copy operations to be as efficient as possible.
    pub fn collect_copy(&self) -> Vec<T> {
        (0..self.len)
            .map(|i| {
                let physical = (self.head + i) % self.capacity;
                // For Copy types, dereferencing and assignment is very cheap.
                *self.data[physical].as_ref().unwrap()
            })
            .collect()
    }
}
