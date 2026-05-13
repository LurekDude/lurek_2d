#[derive(Debug, Clone)]
pub struct FunnelEntry {
    pub id: u64,
    pub tag: String,
    pub value: f64,
}
#[derive(Debug)]
pub struct Funnel {
    pub name: String,
    pub window: f64,
    pub max_entries: usize,
    pub enabled: bool,
    accumulated: f64,
    entries: Vec<FunnelEntry>,
    next_id: u64,
    pub flush_count: u64,
}
impl Funnel {
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
    pub fn update(&mut self, dt: f64) -> bool {
        if !self.enabled || self.entries.is_empty() || self.window == 0.0 {
            return false;
        }
        self.accumulated += dt;
        self.accumulated >= self.window
    }
    pub fn flush(&mut self) -> Vec<FunnelEntry> {
        self.accumulated = 0.0;
        self.flush_count += 1;
        std::mem::take(&mut self.entries)
    }
    pub fn pending(&self) -> &[FunnelEntry] {
        &self.entries
    }
    pub fn pending_count(&self) -> usize {
        self.entries.len()
    }
    pub fn discard(&mut self) {
        self.entries.clear();
        self.accumulated = 0.0;
    }
}
