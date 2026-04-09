//! Contiguous byte buffer accessible from Lua.
//!
//! This module is part of Lurek2D's `data` subsystem and provides the implementation
//! details for byte data-related operations and data management.
//! Key types exported from this module: `ByteData`.
//! Primary functions: `new()`, `from_bytes()`, `from_string()`, `len()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use mlua::prelude::*;

/// Contiguous byte buffer for binary data manipulation.
///
/// Wraps a `Vec<u8>` with indexed get/set operations and string conversion.
///
/// # Fields
/// - `data` — `Vec<u8>`.
#[derive(Debug, Clone)]
pub struct ByteData {
    data: Vec<u8>,
}

impl ByteData {
    /// Create a zero-filled buffer of the given size.
    ///
    /// # Parameters
    /// - `size` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(size: usize) -> Self {
        Self {
            data: vec![0; size],
        }
    }

    /// Create from an existing byte vector. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `bytes` — `Vec<u8>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        Self { data: bytes }
    }

    /// Create from a string. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_string(s: &str) -> Self {
        Self {
            data: s.as_bytes().to_vec(),
        }
    }

    /// Get the size of the buffer in bytes.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Check if the buffer is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Get a byte at the given offset (0-based).
    ///
    /// # Parameters
    /// - `offset` — `usize`.
    ///
    /// # Returns
    /// `Option<u8>`.
    pub fn get_byte(&self, offset: usize) -> Option<u8> {
        self.data.get(offset).copied()
    }

    /// Set a byte at the given offset (0-based). Returns false if out of bounds.
    ///
    /// # Parameters
    /// - `offset` — `usize`.
    /// - `value` — `u8`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_byte(&mut self, offset: usize, value: u8) -> bool {
        if offset < self.data.len() {
            self.data[offset] = value;
            true
        } else {
            false
        }
    }

    /// Get the data as a lossy UTF-8 string.
    ///
    /// # Returns
    /// `String`.
    pub fn get_string(&self) -> String {
        String::from_utf8_lossy(&self.data).to_string()
    }

    /// Get a reference to the raw bytes. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.data
    }

    /// Get a mutable reference to the raw bytes.
    ///
    /// # Returns
    /// `&mut [u8]`.
    pub fn as_bytes_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }

    /// Clone the data into a new ByteData. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Self`.
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

#[cfg(test)]
mod tests {
    use super::*;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_zero_filled_correct_len() {
        let bd = ByteData::new(8);
        assert_eq!(bd.len(), 8);
        assert_eq!(bd.get_byte(0), Some(0));
        assert_eq!(bd.get_byte(7), Some(0));
    }

    #[test]
    fn from_bytes_preserves_data() {
        let bd = ByteData::from_bytes(vec![1, 2, 3]);
        assert_eq!(bd.len(), 3);
        assert_eq!(bd.get_byte(0), Some(1));
        assert_eq!(bd.get_byte(2), Some(3));
    }

    #[test]
    fn from_string_converts_correctly() {
        let bd = ByteData::from_string("hi");
        assert_eq!(bd.len(), 2);
        assert_eq!(bd.get_byte(0), Some(b'h'));
        assert_eq!(bd.get_byte(1), Some(b'i'));
    }

    // ── Get / Set ─────────────────────────────────────────────────────────────

    #[test]
    fn set_byte_roundtrip() {
        let mut bd = ByteData::new(4);
        let ok = bd.set_byte(2, 42);
        assert!(ok);
        assert_eq!(bd.get_byte(2), Some(42));
    }

    #[test]
    fn set_byte_out_of_bounds_returns_false() {
        let mut bd = ByteData::new(4);
        assert!(!bd.set_byte(10, 1));
    }

    #[test]
    fn get_byte_out_of_bounds_returns_none() {
        let bd = ByteData::new(4);
        assert!(bd.get_byte(99).is_none());
    }

    // ── Buffer ops ────────────────────────────────────────────────────────────

    #[test]
    fn is_empty_zero_size() {
        let bd = ByteData::new(0);
        assert!(bd.is_empty());
    }

    #[test]
    fn as_bytes_matches_data() {
        let bd = ByteData::from_bytes(vec![10, 20, 30]);
        assert_eq!(bd.as_bytes(), &[10u8, 20, 30]);
    }

    #[test]
    fn get_string_roundtrip() {
        let bd = ByteData::from_string("hello");
        assert_eq!(bd.get_string(), "hello");
    }
}
