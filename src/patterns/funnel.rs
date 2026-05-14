//! Time-windowed entry accumulator that signals when to flush buffered data.
//! Used for batching Lua events, analytics, or network packets within a time or count budget.

/// A single accumulated value pushed into a `Funnel`.
#[derive(Debug, Clone)]
pub struct FunnelEntry {
    /// Identifier assigned at push time.
    pub id: u64,
    /// Caller-defined category label.
    pub tag: String,
    /// Numeric payload value.
    pub value: f64,
}
/// Buffered accumulator that flushes after a time window or entry count threshold.
#[derive(Debug)]
pub struct Funnel {
    /// Debug name.
    pub name: String,
    /// Seconds after which `update` signals a flush; `0` means flush immediately on push.
    pub window: f64,
    /// Maximum entries before a push triggers an immediate flush; `0` means no count limit.
    pub max_entries: usize,
    /// When false, `update` never signals a flush.
    pub enabled: bool,
    /// Accumulated time since last flush.
    accumulated: f64,
    /// Buffered entries waiting to be flushed.
    entries: Vec<FunnelEntry>,
    /// Next id to assign.
    next_id: u64,
    /// How many times `flush` has been called.
    pub flush_count: u64,
}
/// All methods for `Funnel`.
impl Funnel {
    /// Create a funnel named `name` with a `window`-second flush timer and `max_entries` count limit.
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
    /// Buffer a `(tag, value)` entry and return `(id, should_flush)` where `should_flush` signals an immediate flush.
    pub fn push(&mut self, tag: &str, value: f64) -> (u64, bool) {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(FunnelEntry {
            id,
            tag: tag.to_string(),
            value,
        });
        let should_flush =
            self.window == 0.0 || (self.max_entries > 0 && self.entries.len() >= self.max_entries);
        (id, should_flush)
    }
    /// Advance internal time by `dt` seconds; return true when the flush window has elapsed.
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled || self.entries.is_empty() || self.window == 0.0 {
            return false;
        }
        self.accumulated += dt;
        self.accumulated >= self.window
    }
    /// Drain all buffered entries, reset the timer, and increment `flush_count`.
    pub fn flush(&mut self) -> Vec<FunnelEntry> {
        self.accumulated = 0.0;
        self.flush_count += 1;
        std::mem::take(&mut self.entries)
    }
    /// Return a slice of entries that have not yet been flushed.
    pub fn pending(&self) -> &[FunnelEntry] {
        &self.entries
    }
    /// Return the number of buffered entries.
    pub fn pending_count(&self) -> usize {
        self.entries.len()
    }
    /// Drop all buffered entries and reset the timer without incrementing `flush_count`.
    pub fn discard(&mut self) {
        self.entries.clear();
        self.accumulated = 0.0;
    }
}
