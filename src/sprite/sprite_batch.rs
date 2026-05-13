use crate::runtime::resource_keys::TextureKey;
pub struct SpriteBatch {
    texture_key: TextureKey,
    entries: Vec<BatchEntry>,
    max_entries: usize,
}
pub struct BatchEntry {
    pub x: f32,
    pub y: f32,
    pub quad_x: f32,
    pub quad_y: f32,
    pub quad_w: f32,
    pub quad_h: f32,
    pub rotation: f32,
    pub sx: f32,
    pub sy: f32,
    pub ox: f32,
    pub oy: f32,
}
impl SpriteBatch {
    pub fn new(texture_key: TextureKey, max_entries: usize) -> Self {
        let cap = if max_entries > 0 { max_entries } else { 256 };
        SpriteBatch {
            texture_key,
            entries: Vec::with_capacity(cap),
            max_entries,
        }
    }
    pub fn add(&mut self, entry: BatchEntry) -> Option<usize> {
        if self.max_entries > 0 && self.entries.len() >= self.max_entries {
            return None;
        }
        let idx = self.entries.len();
        self.entries.push(entry);
        Some(idx)
    }
    pub fn clear(&mut self) {
        self.entries.clear();
    }
    pub fn texture_key(&self) -> TextureKey {
        self.texture_key
    }
    pub fn entries(&self) -> &[BatchEntry] {
        &self.entries
    }
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    pub fn buffer_size(&self) -> usize {
        self.max_entries
    }
}
