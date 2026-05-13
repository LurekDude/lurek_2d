//! Growable byte buffer write cursor.

/// Write cursor over growable buffer.
///
/// Companion to `DataView` — use `DataWriter` to build binary data that can
/// later be read back via `DataView`.
///
pub struct DataWriter {
    buffer: Vec<u8>,
    position: usize,
}

impl DataWriter {
/// Create a new empty `DataWriter`.
    ///
    /// `Self`.
    pub fn new() -> Self {
        Self {
            buffer: Vec::new(),
            position: 0,
        }
    }
/// Create a `DataWriter` pre-allocated with `capacity` bytes.
    ///
    ///
    /// `Self`.
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            buffer: Vec::with_capacity(capacity),
            position: 0,
        }
    }
/// Return the current cursor position.
    ///
    /// `usize`.
    pub fn tell(&self) -> usize {
        self.position
    }
/// Return the number of bytes written so far.
    ///
    /// `usize`.
    pub fn len(&self) -> usize {
        self.buffer.len()
    }
/// Return `true` if no bytes have been written.
    ///
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.buffer.is_empty()
    }

    /// Moves the write cursor to `pos`.
    ///
    /// If `pos` is beyond the current length, the buffer is zero-extended.
    ///
    pub fn seek(&mut self, pos: usize) {
        if pos > self.buffer.len() {
            self.buffer.resize(pos, 0);
        }
        self.position = pos;
    }

    /// Consumes the writer and returns the underlying byte vector.
    ///
    /// `Vec<u8>`.
    pub fn into_bytes(self) -> Vec<u8> {
        self.buffer
    }
/// Return a shared reference to the written bytes.
    ///
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.buffer
    }

    // ── Write methods ─────────────────────────────────────────────────
/// Write a single byte and advances the cursor.
    pub fn write_u8(&mut self, value: u8) {
        self.write_raw(&[value]);
    }
/// Write an `i8` and advances the cursor.
    pub fn write_i8(&mut self, value: i8) {
        self.write_raw(&[value as u8]);
    }
/// Write a little-endian `u16` and advances the cursor.
    pub fn write_u16_le(&mut self, value: u16) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a big-endian `u16` and advances the cursor.
    pub fn write_u16_be(&mut self, value: u16) {
        self.write_raw(&value.to_be_bytes());
    }
/// Write a little-endian `i16` and advances the cursor.
    pub fn write_i16_le(&mut self, value: i16) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a little-endian `u32` and advances the cursor.
    pub fn write_u32_le(&mut self, value: u32) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a little-endian `i32` and advances the cursor.
    pub fn write_i32_le(&mut self, value: i32) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a little-endian `f32` and advances the cursor.
    pub fn write_f32_le(&mut self, value: f32) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a little-endian `f64` and advances the cursor.
    pub fn write_f64_le(&mut self, value: f64) {
        self.write_raw(&value.to_le_bytes());
    }
/// Write a length-prefixed UTF-8 string (4-byte LE length + bytes).
    ///
    pub fn write_string(&mut self, s: &str) {
        let bytes = s.as_bytes();
        self.write_u32_le(bytes.len() as u32);
        self.write_raw(bytes);
    }
/// Write raw bytes and advances the cursor.
    ///
    pub fn write_bytes(&mut self, bytes: &[u8]) {
        self.write_raw(bytes);
    }

    // ── Internal ──────────────────────────────────────────────────────
/// Write `data` at the current cursor position, extending the buffer if needed.
    fn write_raw(&mut self, data: &[u8]) {
        let end = self.position + data.len();
        if end > self.buffer.len() {
            self.buffer.resize(end, 0);
        }
        self.buffer[self.position..end].copy_from_slice(data);
        self.position = end;
    }
}

impl Default for DataWriter {
    fn default() -> Self {
        Self::new()
    }
}
