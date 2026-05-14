//! Per-column depth buffer for sprite occlusion. Stores the nearest wall depth for
//! each screen column so sprite pixels behind a wall are discarded. Used by the
//! sprite draw pass in `draw.rs`. Does not interact with the GPU depth buffer.

/// Per-column wall-hit depth used to cull sprite pixels that fall behind a wall.
pub struct DepthBuffer {
    /// Number of screen columns this buffer covers.
    width: u32,
    /// Depth values indexed by column; initialised to `f32::MAX` (no wall).
    buffer: Vec<f32>,
}
impl DepthBuffer {
    /// Create a new depth buffer for `width` screen columns, all initialised to `f32::MAX`.
    pub fn new(width: u32) -> Self {
        Self {
            width,
            buffer: vec![f32::MAX; width as usize],
        }
    }
    /// Reset all columns to `f32::MAX` (no wall) ready for the next frame.
    pub fn clear(&mut self) {
        self.buffer.fill(f32::MAX);
    }
    /// Store wall depth for `column`; silently ignores out-of-range indices.
    pub fn set(&mut self, column: u32, depth: f32) {
        if (column as usize) < self.buffer.len() {
            self.buffer[column as usize] = depth;
        }
    }
    /// Return the stored depth for `column`, or `f32::MAX` if out of range.
    pub fn get(&self, column: u32) -> f32 {
        if (column as usize) < self.buffer.len() {
            self.buffer[column as usize]
        } else {
            f32::MAX
        }
    }
    /// Return true when `depth` is less than the stored depth for `column` (sprite pixel is visible).
    pub fn is_visible(&self, column: u32, depth: f32) -> bool {
        depth < self.get(column)
    }
    /// Return the width this buffer was created for.
    pub fn width(&self) -> u32 {
        self.width
    }
}
