//! Fundamental ordered-collection and set ADTs for Lua scripting.
//!
//! [`StackMeta`], [`QueueMeta`], [`ListMeta`], and [`SetMeta`] carry only the metadata
//! (capacity constraints) needed by the Lua API layer.  The actual Lua-value storage is
//! managed in `lua_api/patterns_api.rs` using `LuaRegistryKey` collections.

// ── StackMeta ─────────────────────────────────────────────────────────────────

/// Capacity metadata for a last-in-first-out stack.
///
/// # Fields
/// - `capacity` — `usize`.
///
/// `capacity == 0` means unlimited.
#[derive(Debug, Default, Clone)]
pub struct StackMeta {
    /// Maximum number of items (0 = unlimited).
    pub capacity: usize,
}

impl StackMeta {
    /// Creates a new [`StackMeta`] with the given capacity.
    ///
    /// # Parameters
    /// - `capacity` — `usize` (0 = unlimited).
    ///
    /// # Returns
    /// `StackMeta`.
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }

    /// Returns `true` if `len` items would exceed the capacity limit.
    ///
    /// # Parameters
    /// - `len` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}

// ── QueueMeta ─────────────────────────────────────────────────────────────────

/// Capacity metadata for a first-in-first-out queue.
///
/// # Fields
/// - `capacity` — `usize`.
///
/// `capacity == 0` means unlimited.
#[derive(Debug, Default, Clone)]
pub struct QueueMeta {
    /// Maximum number of items (0 = unlimited).
    pub capacity: usize,
}

impl QueueMeta {
    /// Creates a new [`QueueMeta`] with the given capacity.
    ///
    /// # Parameters
    /// - `capacity` — `usize` (0 = unlimited).
    ///
    /// # Returns
    /// `QueueMeta`.
    pub fn new(capacity: usize) -> Self {
        Self { capacity }
    }

    /// Returns `true` if `len` items would exceed the capacity limit.
    ///
    /// # Parameters
    /// - `len` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self, len: usize) -> bool {
        self.capacity > 0 && len >= self.capacity
    }
}
