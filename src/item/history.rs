//! Change history — append-only log of stack mutations.
//!
//! `StackHistory` is kept separate from `Stack` so that the caller decides
//! what (if anything) to track.  Wrap it in an `Rc<RefCell<StackHistory>>`
//! and pass it around alongside stacks.

use std::collections::VecDeque;

// ─────────────────────────────────────────────────────────────────────────────
// HistoryAction
// ─────────────────────────────────────────────────────────────────────────────

/// The category of change that was recorded.
///
/// # Variants
/// - `An` — An variant.
/// - `Pushed` — Pushed variant.
/// - `Popped` — Popped variant.
/// - `Moved` — Moved variant.
/// - `A` — A variant.
/// - `Shuffled` — Shuffled variant.
/// - `Sorted` — Sorted variant.
/// - `Cleared` — Cleared variant.
/// - `Built` — Built variant.
/// - `User` — User variant.
/// - `Custom` — Custom variant.
#[derive(Debug, Clone, PartialEq)]
pub enum HistoryAction {
    /// An item was pushed onto a stack (records the item type and display name).
    Pushed {
        item_type: String,
        item_name: String,
    },
    /// An item was popped off a stack.
    Popped {
        item_type: String,
        item_name: String,
    },
    /// An item moved from one stack to another.
    Moved {
        item_type: String,
        item_name: String,
        from_stack: String,
        to_stack: String,
    },
    /// A stack was shuffled.
    Shuffled,
    /// A stack was sorted (records which field was used).
    Sorted { by: String },
    /// A stack was fully cleared.
    Cleared,
    /// A stack was built from a template (records item count).
    Built { count: usize },
    /// User-defined event string.
    Custom { label: String },
}

// ─────────────────────────────────────────────────────────────────────────────
// HistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

/// A single entry in the history log. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `seq` — `u64`.
/// - `stack_name` — `String`.
/// - `action` — `HistoryAction`.
/// - `size_after` — `usize`.
#[derive(Debug, Clone)]
pub struct HistoryEntry {
    /// Monotonically increasing sequence number.
    pub seq: u64,
    /// Name of the stack that changed.
    pub stack_name: String,
    /// The action that occurred.
    pub action: HistoryAction,
    /// Stack size **after** this action.
    pub size_after: usize,
}

// ─────────────────────────────────────────────────────────────────────────────
// StackHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Append-only change log with an optional rolling size limit.
///
/// # Fields
/// - `entries` — `VecDeque<HistoryEntry>`.
/// - `max_size` — `Option<usize>`.
/// - `next_seq` — `u64`.
#[derive(Debug, Clone)]
pub struct StackHistory {
    entries: VecDeque<HistoryEntry>,
    /// Maximum entries retained (`None` = unlimited).
    max_size: Option<usize>,
    /// Monotonically increasing counter.
    next_seq: u64,
}

impl StackHistory {
    /// Create an unlimited history. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self { entries: VecDeque::new(), max_size: None, next_seq: 0 }
    }

    /// Create a history capped at `max_size` entries (oldest are evicted).
    ///
    /// # Parameters
    /// - `ax_size` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn with_max_size(max_size: usize) -> Self {
        Self { entries: VecDeque::with_capacity(max_size.min(512)), max_size: Some(max_size), next_seq: 0 }
    }

    /// Append an action. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `stack_name` — `impl Into<String>`.
    /// - `action` — `HistoryAction`.
    /// - `size_after` — `usize`.
    pub fn record(&mut self, stack_name: impl Into<String>, action: HistoryAction, size_after: usize) {
        if let Some(max) = self.max_size {
            while self.entries.len() >= max {
                self.entries.pop_front();
            }
        }
        self.entries.push_back(HistoryEntry {
            seq: self.next_seq,
            stack_name: stack_name.into(),
            action,
            size_after,
        });
        self.next_seq += 1;
    }

    /// Append a user-defined label as a `Custom` action.
    ///
    /// # Parameters
    /// - `stack_name` — `impl Into<String>`.
    /// - `label` — `impl Into<String>`.
    /// - `size_after` — `usize`.
    pub fn record_custom(&mut self, stack_name: impl Into<String>, label: impl Into<String>, size_after: usize) {
        self.record(stack_name, HistoryAction::Custom { label: label.into() }, size_after);
    }

    /// Number of entries in the log. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` if no events have been recorded.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Iterate over all entries (oldest first).
    ///
    /// # Returns
    /// `impl Iterator<Item = &HistoryEntry>`.
    pub fn entries(&self) -> impl Iterator<Item = &HistoryEntry> {
        self.entries.iter()
    }

    /// Return the most recent entry, if any. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Option<&HistoryEntry>`.
    pub fn last(&self) -> Option<&HistoryEntry> {
        self.entries.back()
    }

    /// Clear all recorded entries. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.entries.clear();
    }

    /// Return entries for a specific stack name.
    ///
    /// # Parameters
    /// - `stack_name` — `&str`.
    ///
    /// # Returns
    /// `Vec<&HistoryEntry>`.
    pub fn entries_for(&self, stack_name: &str) -> Vec<&HistoryEntry> {
        self.entries.iter().filter(|e| e.stack_name == stack_name).collect()
    }
}

impl Default for StackHistory {
    fn default() -> Self {
        Self::new()
    }
}
