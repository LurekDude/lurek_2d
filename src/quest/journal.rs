//! Journal entry for recording quest events.

// ──────────────────────────────────────────────────────────────────────────────
// JournalEntry
// ──────────────────────────────────────────────────────────────────────────────

/// A timestamped text entry in a quest's journal.
#[derive(Debug, Clone)]
pub struct JournalEntry {
    /// Monotone sequence number (assigned by `Quest`).
    pub index: u32,
    /// Text body of the entry.
    pub text: String,
    /// Optional tag (e.g., `"discovered"`, `"completed"`, `"failed"`).
    pub tag: String,
}
