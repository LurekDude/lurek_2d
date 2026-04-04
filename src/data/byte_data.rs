//! Contiguous byte buffer accessible from Lua.

use mlua::prelude::*;

/// Contiguous byte buffer for binary data manipulation.
///
/// Wraps a `Vec<u8>` with indexed get/set operations and string conversion.
#[derive(Debug, Clone)]
pub struct ByteData {
    data: Vec<u8>,
}

impl ByteData {
    /// Create a zero-filled buffer of the given size.
    pub fn new(size: usize) -> Self {
        Self {
            data: vec![0; size],
        }
    }

    /// Create from an existing byte vector.
    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        Self { data: bytes }
    }

    /// Create from a string.
    pub fn from_string(s: &str) -> Self {
        Self {
            data: s.as_bytes().to_vec(),
        }
    }

    /// Get the size of the buffer in bytes.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Check if the buffer is empty.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Get a byte at the given offset (0-based).
    pub fn get_byte(&self, offset: usize) -> Option<u8> {
        self.data.get(offset).copied()
    }

    /// Set a byte at the given offset (0-based). Returns false if out of bounds.
    pub fn set_byte(&mut self, offset: usize, value: u8) -> bool {
        if offset < self.data.len() {
            self.data[offset] = value;
            true
        } else {
            false
        }
    }

    /// Get the data as a lossy UTF-8 string.
    pub fn get_string(&self) -> String {
        String::from_utf8_lossy(&self.data).to_string()
    }

    /// Get a reference to the raw bytes.
    pub fn as_bytes(&self) -> &[u8] {
        &self.data
    }

    /// Get a mutable reference to the raw bytes.
    pub fn as_bytes_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }

    /// Clone the data into a new ByteData.
    pub fn clone_data(&self) -> Self {
        Self {
            data: self.data.clone(),
        }
    }
}

impl mlua::UserData for ByteData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSize", |_, this, ()| Ok(this.len()));
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));
        methods.add_method("getByte", |_, this, offset: usize| {
            this.get_byte(offset).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                ))
            })
        });
        methods.add_method_mut("setByte", |_, this, (offset, value): (usize, u8)| {
            if this.set_byte(offset, value) {
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "Offset {} out of bounds (size {})",
                    offset,
                    this.len()
                )))
            }
        });
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(this.clone_data())
        });
    }
}
