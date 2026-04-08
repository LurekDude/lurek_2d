//! Read-only windowed view into a shared byte buffer.
//!
//! `DataView` provides typed accessor methods over a slice of a `Vec<u8>` without
//! copying the underlying data. All reads are little-endian. Bounds are checked
//! on every access; out-of-range indices return an error.

use std::sync::Arc;

use mlua::prelude::*;

/// A windowed, read-only view into a shared byte buffer.
///
/// Uses `Arc<Vec<u8>>` for shared ownership so that multiple views can reference the
/// same buffer without copying.
///
/// # Fields
/// - `data` — `Arc<Vec<u8>>`. The shared backing buffer.
/// - `offset` — `usize`. The byte offset in `data` where this view starts.
/// - `size` — `usize`. The number of bytes in this view.
pub struct DataView {
    /// The underlying byte buffer (shared ownership).
    pub data: Arc<Vec<u8>>,
    /// Byte offset into `data` where this view starts.
    pub offset: usize,
    /// Number of bytes in this view.
    pub size: usize,
}

impl DataView {
    /// Creates a new view spanning the entire buffer.
    ///
    /// # Parameters
    /// - `data` — `Arc<Vec<u8>>`. The backing buffer.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(data: Arc<Vec<u8>>) -> Self {
        let size = data.len();
        Self {
            data,
            offset: 0,
            size,
        }
    }

    /// Creates a view starting at `offset` covering `size` bytes.
    ///
    /// Returns an error if `offset + size` exceeds the buffer length.
    ///
    /// # Parameters
    /// - `data` — `Arc<Vec<u8>>`. The backing buffer.
    /// - `offset` — `usize`. Byte offset where the view starts.
    /// - `size` — `usize`. Number of bytes in the view.
    ///
    /// # Returns
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

    /// Returns the number of bytes in this view.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_size(&self) -> usize {
        self.size
    }

    /// Reads a `u8` at `idx` relative to this view's start offset.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
    /// `Result<u8, String>`.
    pub fn get_u8(&self, idx: usize) -> Result<u8, String> {
        self.check(idx, 1)?;
        Ok(self.data[self.offset + idx])
    }

    /// Reads an `i8` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
    /// `Result<i8, String>`.
    pub fn get_i8(&self, idx: usize) -> Result<i8, String> {
        self.check(idx, 1)?;
        Ok(self.data[self.offset + idx] as i8)
    }

    /// Reads a little-endian `u16` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
    /// `Result<u16, String>`.
    pub fn get_u16(&self, idx: usize) -> Result<u16, String> {
        self.check(idx, 2)?;
        let abs = self.offset + idx;
        Ok(u16::from_le_bytes([self.data[abs], self.data[abs + 1]]))
    }

    /// Reads a little-endian `i16` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
    /// `Result<i16, String>`.
    pub fn get_i16(&self, idx: usize) -> Result<i16, String> {
        self.check(idx, 2)?;
        let abs = self.offset + idx;
        Ok(i16::from_le_bytes([self.data[abs], self.data[abs + 1]]))
    }

    /// Reads a little-endian `u32` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
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

    /// Reads a little-endian `i32` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
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

    /// Reads a little-endian `f32` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
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

    /// Reads a little-endian `f64` at `idx`.
    ///
    /// # Parameters
    /// - `idx` — `usize`. View-relative byte index.
    ///
    /// # Returns
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

// -------------------------------------------------------------------------------
// LuaDataView UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`DataView`].
pub struct LuaDataView {
    pub(crate) inner: DataView,
}

impl LuaDataView {
    /// Creates a new `LuaDataView` wrapping the given `DataView`.
    pub fn new(inner: DataView) -> Self {
        Self { inner }
    }
}

impl LuaUserData for LuaDataView {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- getUInt8 --
        /// Reads an unsigned 8-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt8", |_, this, offset: usize| {
            this.inner
                .get_u8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt8 --
        /// Reads a signed 8-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt8", |_, this, offset: usize| {
            this.inner
                .get_i8(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt16 --
        /// Reads a signed 16-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt16", |_, this, offset: usize| {
            this.inner
                .get_i16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt16 --
        /// Reads an unsigned 16-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt16", |_, this, offset: usize| {
            this.inner
                .get_u16(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getInt32 --
        /// Reads a signed 32-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getInt32", |_, this, offset: usize| {
            this.inner
                .get_i32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getUInt32 --
        /// Reads an unsigned 32-bit integer at the given offset.
        /// @param offset : integer
        /// @return integer
        methods.add_method("getUInt32", |_, this, offset: usize| {
            this.inner
                .get_u32(offset)
                .map(|v| v as i64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getFloat --
        /// Reads a 32-bit float at the given offset.
        /// @param offset : integer
        /// @return number
        methods.add_method("getFloat", |_, this, offset: usize| {
            this.inner
                .get_f32(offset)
                .map(|v| v as f64)
                .map_err(LuaError::RuntimeError)
        });

        // -- getDouble --
        /// Reads a 64-bit float at the given offset.
        /// @param offset : integer
        /// @return number
        methods.add_method("getDouble", |_, this, offset: usize| {
            this.inner.get_f64(offset).map_err(LuaError::RuntimeError)
        });

        // -- getSize --
        /// Returns the size of this view in bytes.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| {
            Ok(this.inner.get_size() as i64)
        });

    }
}
