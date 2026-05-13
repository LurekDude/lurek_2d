pub struct LayerEntry {
    pub z_order: f64,
    pub callback_id: usize,
}
pub struct DrawLayer {
    entries: Vec<LayerEntry>,
    next_id: usize,
}
impl DrawLayer {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            next_id: 0,
        }
    }
    pub fn queue(&mut self, z_order: f64) -> usize {
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(LayerEntry {
            z_order,
            callback_id: id,
        });
        id
    }
    pub fn flush(&mut self) -> Vec<LayerEntry> {
        self.entries.sort_by(|a, b| {
            a.z_order
                .partial_cmp(&b.z_order)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        std::mem::take(&mut self.entries)
    }
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
}
impl Default for DrawLayer {
    fn default() -> Self {
        Self::new()
    }
}
