//! Read-only views over shared byte buffers.

use std::sync::Arc;

/// Bounds-checked read-only view over shared buffer.
///
/// Uses `Arc<Vec<u8>>` for shared ownership so that multiple views can reference the
/// same buffer without copying.
///
pub struct DataView {
    /// The underlying byte buffer (shared ownership).
    pub data: Arc<Vec<u8>>,
    /// Byte offset into `data` where this view starts.
    pub offset: usize,
    /// Number of bytes in this view.
    pub size: usize,
}

impl DataView {
/// Create a new view spanning the entire buffer.
    ///
    ///
    /// `Self`.
    pub fn new(data: Arc<Vec<u8>>) -> Self {
        let size = data.len();
        Self {
            data,
            offset: 0,
            size,
        }
    }
/// Create a view starting at `offset` covering `size` bytes.
    ///
/// Return an error if `offset + size` exceeds the buffer length.
    ///
    ///
    /// `Result<Self, String>`.
    pub fn new_slice(data: Arc<Vec<u8>>, offset: usize, size: usize) -> Result<Self, String> {
        if offset + size > data.len() {
            return Err(format!(
                "DataView: slice out of bounds (offset={} size={} buffer_len={})",
                offset,
                size,
                data.len()
            ));
        }
        Ok(Self { data, offset, size })
    }
/// Return the number of bytes in this view.
    ///
    /// `usize`.
    pub fn get_size(&self) -> usize {
        self.size
    }
/// Read a `u8` at `idx` relative to this view's start offset.
    ///
    ///
    /// `Result<u8, String>`.
    pub fn get_u8(&self, idx: usize) -> Result<u8, String> {
        self.check(idx, 1)?;
        Ok(self.data[self.offset + idx])
    }
/// Read an `i8` at `idx`.
    ///
    ///
    /// `Result<i8, String>`.
    pub fn get_i8(&self, idx: usize) -> Result<i8, String> {
        self.check(idx, 1)?;
        Ok(self.data[self.offset + idx] as i8)
    }
/// Read a little-endian `u16` at `idx`.
    ///
    ///
    /// `Result<u16, String>`.
    pub fn get_u16(&self, idx: usize) -> Result<u16, String> {
        self.check(idx, 2)?;
        let abs = self.offset + idx;
        Ok(u16::from_le_bytes([self.data[abs], self.data[abs + 1]]))
    }
/// Read a little-endian `i16` at `idx`.
    ///
    ///
    /// `Result<i16, String>`.
    pub fn get_i16(&self, idx: usize) -> Result<i16, String> {
        self.check(idx, 2)?;
        let abs = self.offset + idx;
        Ok(i16::from_le_bytes([self.data[abs], self.data[abs + 1]]))
    }
/// Read a little-endian `u32` at `idx`.
    ///
    ///
    /// `Result<u32, String>`.
    pub fn get_u32(&self, idx: usize) -> Result<u32, String> {
        self.check(idx, 4)?;
        let abs = self.offset + idx;
        Ok(u32::from_le_bytes([
            self.data[abs],
            self.data[abs + 1],
            self.data[abs + 2],
            self.data[abs + 3],
        ]))
    }
/// Read a little-endian `i32` at `idx`.
    ///
    ///
    /// `Result<i32, String>`.
    pub fn get_i32(&self, idx: usize) -> Result<i32, String> {
        self.check(idx, 4)?;
        let abs = self.offset + idx;
        Ok(i32::from_le_bytes([
            self.data[abs],
            self.data[abs + 1],
            self.data[abs + 2],
            self.data[abs + 3],
        ]))
    }
/// Read a little-endian `f32` at `idx`.
    ///
    ///
    /// `Result<f32, String>`.
    pub fn get_f32(&self, idx: usize) -> Result<f32, String> {
        self.check(idx, 4)?;
        let abs = self.offset + idx;
        Ok(f32::from_le_bytes([
            self.data[abs],
            self.data[abs + 1],
            self.data[abs + 2],
            self.data[abs + 3],
        ]))
    }
/// Read a little-endian `f64` at `idx`.
    ///
    ///
    /// `Result<f64, String>`.
    pub fn get_f64(&self, idx: usize) -> Result<f64, String> {
        self.check(idx, 8)?;
        let abs = self.offset + idx;
        Ok(f64::from_le_bytes([
            self.data[abs],
            self.data[abs + 1],
            self.data[abs + 2],
            self.data[abs + 3],
            self.data[abs + 4],
            self.data[abs + 5],
            self.data[abs + 6],
            self.data[abs + 7],
        ]))
    }

    /// Asserts that `idx + width` bytes are within this view's bounds.
    ///
    /// Every typed read calls this first so that all bounds errors are
    /// caught before any pointer arithmetic touches the backing buffer.
    fn check(&self, idx: usize, width: usize) -> Result<(), String> {
        if idx + width > self.size {
            Err(format!(
                "DataView: read {} bytes at index {} out of bounds (view size {})",
                width, idx, self.size
            ))
        } else {
            Ok(())
        }
    }
}

/// Lua-side wrapper around [`DataView`].
///
/// Keeps the domain type free of mlua method registration while exposing
/// the same read-only accessor surface through the Lua bridge.
///
pub struct LuaDataView {
    pub(crate) inner: DataView,
}

impl LuaDataView {
/// Create a new `LuaDataView` wrapping the given `DataView`.
    ///
    ///
    /// `Self`.
    pub fn new(inner: DataView) -> Self {
        Self { inner }
    }
}
