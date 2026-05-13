pub struct DepthBuffer {
    width: u32,
    buffer: Vec<f32>,
}
impl DepthBuffer {
    pub fn new(width: u32) -> Self {
        Self {
            width,
            buffer: vec![f32::MAX; width as usize],
        }
    }
    pub fn clear(&mut self) {
        self.buffer.fill(f32::MAX);
    }
    pub fn set(&mut self, column: u32, depth: f32) {
        if (column as usize) < self.buffer.len() {
            self.buffer[column as usize] = depth;
        }
    }
    pub fn get(&self, column: u32) -> f32 {
        if (column as usize) < self.buffer.len() {
            self.buffer[column as usize]
        } else {
            f32::MAX
        }
    }
    pub fn is_visible(&self, column: u32, depth: f32) -> bool {
        depth < self.get(column)
    }
    pub fn width(&self) -> u32 {
        self.width
    }
}
