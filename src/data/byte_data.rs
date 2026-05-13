//! Byte buffer wrapper `ByteData` for mutable data operations.
//! Provides indexed reads/writes, UTF-8 conversion, and byte manipulation.

/// Byte buffer holding a contiguous `Vec<u8>` with indexing and string conversion.
///
/// Wraps a `Vec<u8>` with indexed get/set operations and string conversion.
///
#[derive(Debug, Clone)]
pub struct ByteData {
    data: Vec<u8>,
}

impl ByteData {
    /// Create a zero-filled buffer of the given size.
    ///
    ///
    /// `Self`.
    pub fn new(size: usize) -> Self {
        Self {
            data: vec![0; size],
        }
    }

    /// Create from an existing byte vector, taking ownership.
    ///
    ///
    /// `Self`.
    pub fn from_bytes(bytes: Vec<u8>) -> Self {
        Self { data: bytes }
    }

    /// Create from a UTF-8 string, copying the string’s bytes into the buffer.
    ///
    ///
    /// `Self`.
    pub fn from_string(s: &str) -> Self {
        Self {
            data: s.as_bytes().to_vec(),
        }
    }

    /// Get the size of the buffer in bytes.
    ///
    /// `usize`.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Check if the buffer contains zero bytes.
    ///
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Get a byte at the given offset (0-based).
    ///
    ///
    /// `Option<u8>`.
    pub fn get_byte(&self, offset: usize) -> Option<u8> {
        self.data.get(offset).copied()
    }

    /// Set a byte at the given offset (0-based). Returns false if out of bounds.
    ///
    ///
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
    /// `String`.
    pub fn get_string(&self) -> String {
        String::from_utf8_lossy(&self.data).to_string()
    }
/// Return a reference to the raw byte slice.
    ///
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.data
    }

    /// Get a mutable reference to the raw bytes.
    ///
    /// `&mut [u8]`.
    pub fn as_bytes_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }

    /// Clones the internal byte buffer into a new standalone `ByteData` instance.
    ///
    /// `Self`.
    pub fn clone_data(&self) -> Self {
        Self {
            data: self.data.clone(),
        }
    }
}
