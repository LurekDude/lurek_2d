//! Scope: Growable byte-buffer writing.
//! This file defines the DataWriter type and typed write helpers.
//! It owns cursor advancement and little-endian default encoding.

/// A growable byte buffer with a write cursor.
///
/// Companion to `DataView` — use `DataWriter` to build binary data that can
/// later be read back via `DataView`.
///
/// # Fields
/// - `buffer` — `Vec<u8>`. The backing byte storage.
/// - `position` — `usize`. Current write cursor position.
pub struct DataWriter {
    buffer: Vec<u8>,
    position: usize,
}

impl DataWriter {
    /// Creates a new empty `DataWriter`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            buffer: Vec::new(),
            position: 0,
        }
    }

    /// Creates a `DataWriter` pre-allocated with `capacity` bytes.
    ///
    /// # Parameters
    /// - `capacity` — `usize`. Initial capacity hint.
    ///
    /// # Returns
    /// `Self`.
    pub fn with_capacity(capacity: usize) -> Self {
        Self {
            buffer: Vec::with_capacity(capacity),
            position: 0,
        }
    }

    /// Returns the current cursor position.
    ///
    /// # Returns
    /// `usize`.
    pub fn tell(&self) -> usize {
        self.position
    }

    /// Returns the number of bytes written so far.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.buffer.len()
    }

    /// Returns `true` if no bytes have been written.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.buffer.is_empty()
    }

    /// Moves the write cursor to `pos`.
    ///
    /// If `pos` is beyond the current length, the buffer is zero-extended.
    ///
    /// # Parameters
    /// - `pos` — `usize`. New cursor position.
    pub fn seek(&mut self, pos: usize) {
        if pos > self.buffer.len() {
            self.buffer.resize(pos, 0);
        }
        self.position = pos;
    }

    /// Consumes the writer and returns the underlying byte vector.
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn into_bytes(self) -> Vec<u8> {
        self.buffer
    }

    /// Returns a shared reference to the written bytes.
    ///
    /// # Returns
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.buffer
    }

    // ── Write methods ─────────────────────────────────────────────────

    /// Writes a single byte and advances the cursor.
    pub fn write_u8(&mut self, value: u8) {
        self.write_raw(&[value]);
    }

    /// Writes an `i8` and advances the cursor.
    pub fn write_i8(&mut self, value: i8) {
        self.write_raw(&[value as u8]);
    }

    /// Writes a little-endian `u16` and advances the cursor.
    pub fn write_u16_le(&mut self, value: u16) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a big-endian `u16` and advances the cursor.
    pub fn write_u16_be(&mut self, value: u16) {
        self.write_raw(&value.to_be_bytes());
    }

    /// Writes a little-endian `i16` and advances the cursor.
    pub fn write_i16_le(&mut self, value: i16) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a little-endian `u32` and advances the cursor.
    pub fn write_u32_le(&mut self, value: u32) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a little-endian `i32` and advances the cursor.
    pub fn write_i32_le(&mut self, value: i32) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a little-endian `f32` and advances the cursor.
    pub fn write_f32_le(&mut self, value: f32) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a little-endian `f64` and advances the cursor.
    pub fn write_f64_le(&mut self, value: f64) {
        self.write_raw(&value.to_le_bytes());
    }

    /// Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
    ///
    /// # Parameters
    /// - `s` — `&str`. The string to write.
    pub fn write_string(&mut self, s: &str) {
        let bytes = s.as_bytes();
        self.write_u32_le(bytes.len() as u32);
        self.write_raw(bytes);
    }

    /// Writes raw bytes and advances the cursor.
    ///
    /// # Parameters
    /// - `bytes` — `&[u8]`.
    pub fn write_bytes(&mut self, bytes: &[u8]) {
        self.write_raw(bytes);
    }

    // ── Internal ──────────────────────────────────────────────────────

    /// Writes `data` at the current cursor position, extending the buffer if needed.
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
