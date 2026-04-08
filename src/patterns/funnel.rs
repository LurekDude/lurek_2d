//! Event funnel: collect incoming events over a time window and flush as a batch.
//!
//! [`Funnel`] accumulates event records during a configurable collection window
//! and fires a flush callback (managed in the Lua API layer) when the window
//! expires or a maximum count is reached. Useful for damage number batching,
//! multi-touch gesture recognition, combo moves, and network packet aggregation.

// ── FunnelEntry ───────────────────────────────────────────────────────────

/// A single event collected by a [`Funnel`].
///
/// # Fields
/// - `id` — `u64`.
/// - `tag` — `String`.
/// - `value` — `f64`.
#[derive(Debug, Clone)]
pub struct FunnelEntry {
    /// Monotonic insertion id.
    pub id: u64,
    /// Caller-supplied tag / event type.
    pub tag: String,
    /// Optional numeric payload (0.0 when unused).
    pub value: f64,
}

// ── Funnel ────────────────────────────────────────────────────────────────

/// Batching event collector. Accumulates entries for `window` seconds or up
/// to `max_entries` items, then signals the Lua API layer to flush.
///
/// # Fields
/// - `name` — `String`.
/// - `window` — `f64`.
/// - `max_entries` — `usize`.
#[derive(Debug)]
pub struct Funnel {
    /// Display name.
    pub name: String,
    /// Collection window in seconds. A value of `0` means flush on every push.
    pub window: f64,
    /// Flush when this many entries accumulate (0 = no count limit).
    pub max_entries: usize,
    /// Whether the funnel is open for new entries.
    pub enabled: bool,
    accumulated: f64,
    entries: Vec<FunnelEntry>,
    next_id: u64,
    /// Total number of flushes performed.
    pub flush_count: u64,
}

impl Funnel {
    /// Creates a new funnel.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `window` — `f64`.
    /// - `max_entries` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str, window: f64, max_entries: usize) -> Self {
        Self {
            name: name.to_string(),
            window: window.max(0.0),
            max_entries,
            enabled: true,
            accumulated: 0.0,
            entries: Vec::new(),
            next_id: 1,
            flush_count: 0,
        }
    }

    /// Adds an event to the funnel. Returns the entry id and whether an
    /// immediate flush is warranted (e.g., `max_entries` reached or `window == 0`).
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    /// - `value` — `f64`.
    ///
    /// # Returns
    /// `(u64, bool)`.
    pub fn push(&mut self, tag: &str, value: f64) -> (u64, bool) {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(FunnelEntry { id, tag: tag.to_string(), value });
        let should_flush = self.window == 0.0
            || (self.max_entries > 0 && self.entries.len() >= self.max_entries);
        (id, should_flush)
    }

    /// Advances the window timer by `dt` seconds. Returns `true` when the
    /// window has expired and there are entries pending flush.
    ///
    /// # Parameters
    /// - `dt` — `f64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled || self.entries.is_empty() || self.window == 0.0 {
            return false;
        }
        self.accumulated += dt;
        self.accumulated >= self.window
    }

    /// Drains all buffered entries and resets the timer.
    ///
    /// # Returns
    /// `Vec<FunnelEntry>`.
    pub fn flush(&mut self) -> Vec<FunnelEntry> {
        self.accumulated = 0.0;
        self.flush_count += 1;
        std::mem::take(&mut self.entries)
    }

    /// Returns the buffered entries without draining them.
    ///
    /// # Returns
    /// `&[FunnelEntry]`.
    pub fn pending(&self) -> &[FunnelEntry] {
        &self.entries
    }

    /// Number of buffered entries.
    ///
    /// # Returns
    /// `usize`.
    pub fn pending_count(&self) -> usize {
        self.entries.len()
    }

    /// Discards all buffered entries without calling a flush callback.
    pub fn discard(&mut self) {
        self.entries.clear();
        self.accumulated = 0.0;
    }
}
