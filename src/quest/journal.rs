//! Journal entry for recording quest events.
//!
//! This module is part of Luna2D's `quest` subsystem and provides the implementation
//! details for journal-related operations and data management.
//! Key types exported from this module: `JournalEntry`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

// ──────────────────────────────────────────────────────────────────────────────
// JournalEntry
// ──────────────────────────────────────────────────────────────────────────────

/// A timestamped text entry in a quest's journal.
///
/// # Fields
/// - `index` — `u32`.
/// - `text` — `String`.
/// - `tag` — `String`.
#[derive(Debug, Clone)]
pub struct JournalEntry {
    /// Monotone sequence number (assigned by `Quest`).
    pub index: u32,
    /// Text body of the entry.
    pub text: String,
    /// Optional tag (e.g., `"discovered"`, `"completed"`, `"failed"`).
    pub tag: String,
}
