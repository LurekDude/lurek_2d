//! Own sequential binary writer with a movable cursor over an owned byte buffer.
//! Supports typed little-endian and big-endian writes, length-prefixed strings, and raw slices.
//! The cursor can be repositioned; the buffer grows automatically. Intended for building binary
//! payloads later consumed by pack/unpack, serialization, or asset export tools.
//! Does not read back written data; use `DataView` for read-only access over a slice.

/// Hold buffer and cursor for binary writes.
pub struct DataWriter {
    /// Store written bytes.
    buffer: Vec<u8>,
    /// Track current write position.
    position: usize,
}
impl DataWriter {
    /// Create empty writer and return value.
    pub fn new() -> Self {
        Self {
            buffer: Vec::new(),
            position: 0,
        }
    }
    /// Create writer with reserved capacity and return value.
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            buffer: Vec::with_capacity(capacity),
            position: 0,
        }
    }
    /// Return current cursor position.
    pub fn tell(&self) -> usize {
        self.position
    }
    /// Return current buffer length.
    pub fn len(&self) -> usize {
        self.buffer.len()
    }
    /// Return true when buffer is empty.
    pub fn is_empty(&self) -> bool {
        self.buffer.is_empty()
    }
    /// Move cursor to position and grow buffer when needed.
    pub fn seek(&mut self, pos: usize) {
        if pos > self.buffer.len() {
            self.buffer.resize(pos, 0);
        }
        self.position = pos;
    }
    /// Consume writer and return owned bytes.
    pub fn into_bytes(self) -> Vec<u8> {
        self.buffer
    }
    /// Return immutable bytes view.
    pub fn as_bytes(&self) -> &[u8] {
        &self.buffer
    }
    /// Write one u8 value at cursor.
    pub fn write_u8(&mut self, value: u8) {
        self.write_raw(&[value]);
    }
    /// Write one i8 value at cursor.
    pub fn write_i8(&mut self, value: i8) {
        self.write_raw(&[value as u8]);
    }
    /// Write u16 in little-endian order.
    pub fn write_u16_le(&mut self, value: u16) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write u16 in big-endian order.
    pub fn write_u16_be(&mut self, value: u16) {
        self.write_raw(&value.to_be_bytes());
    }
    /// Write i16 in little-endian order.
    pub fn write_i16_le(&mut self, value: i16) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write u32 in little-endian order.
    pub fn write_u32_le(&mut self, value: u32) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write i32 in little-endian order.
    pub fn write_i32_le(&mut self, value: i32) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write f32 in little-endian order.
    pub fn write_f32_le(&mut self, value: f32) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write f64 in little-endian order.
    pub fn write_f64_le(&mut self, value: f64) {
        self.write_raw(&value.to_le_bytes());
    }
    /// Write length-prefixed UTF-8 string.
    pub fn write_string(&mut self, s: &str) {
        let bytes = s.as_bytes();
        self.write_u32_le(bytes.len() as u32);
        self.write_raw(bytes);
    }
    /// Write raw bytes at cursor.
    pub fn write_bytes(&mut self, bytes: &[u8]) {
        self.write_raw(bytes);
    }
    /// Write raw bytes at cursor and grow buffer when needed.
    fn write_raw(&mut self, data: &[u8]) {
        let end = self.position + data.len();
        if end > self.buffer.len() {
            self.buffer.resize(end, 0);
        }
        self.buffer[self.position..end].copy_from_slice(data);
        self.position = end;
    }
}
/// Implement `Default` by delegating to `DataWriter::new`.
impl Default for DataWriter {
    fn default() -> Self {
        Self::new()
    }
}
