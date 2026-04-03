//! Raw file data buffer loaded from the VFS.

/// Raw bytes loaded from the virtual filesystem.
///
/// # Fields
/// - `path` — `String`. The virtual path this data was loaded from.
/// - `bytes` — `Vec<u8>`. Raw file content.
pub struct FileData {
    /// Virtual path this data was loaded from.
    pub path: String,
    /// Raw file content.
    pub bytes: Vec<u8>,
}

impl FileData {
    /// Creates a new `FileData` with the given path and content.
    ///
    /// # Parameters
    /// - `path` — `String`.
    /// - `bytes` — `Vec<u8>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(path: String, bytes: Vec<u8>) -> Self {
        Self { path, bytes }
    }

    /// Returns the number of bytes in this buffer.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    /// Returns `true` if the buffer is empty.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }

    /// Returns the bytes as a UTF-8 string slice, or an error if invalid.
    ///
    /// # Returns
    /// `Result<&str, std::str::Utf8Error>`.
    pub fn as_str(&self) -> Result<&str, std::str::Utf8Error> {
        std::str::from_utf8(&self.bytes)
    }
}
