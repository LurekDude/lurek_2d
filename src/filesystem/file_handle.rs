//! File handle with buffered read/write and sandboxed path resolution.

use crate::engine::error::{EngineError, EngineResult};
use crate::filesystem::GameFS;
use std::io::{BufRead, BufReader, BufWriter, Read, Seek, SeekFrom, Write};
use std::path::PathBuf;

/// File access mode.
///
/// # Variants
/// - `Read` — open for reading; file must exist
/// - `Write` — open for writing; creates or truncates
/// - `Append` — open for appending; creates if needed
/// - `Closed` — handle is not open
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FileMode {
    /// Read-only access. File must exist.
    Read,
    /// Write access. Creates or truncates file.
    Write,
    /// Append access. Creates file if needed, writes at end.
    Append,
    /// File is closed.
    Closed,
}

impl FileMode {
    /// Convert a mode string ("r", "w", "a") to a `FileMode`.
    ///
    /// # Parameters
    /// - `s` — mode string: `"r"` for read, `"w"` for write, `"a"` for append
    ///
    /// # Returns
    /// The corresponding `FileMode`, or an `EngineError` for unrecognised strings.
    pub fn parse_mode(s: &str) -> EngineResult<Self> {
        match s {
            "r" => Ok(FileMode::Read),
            "w" => Ok(FileMode::Write),
            "a" => Ok(FileMode::Append),
            _ => Err(EngineError::FileSystemError(format!(
                "Invalid file mode '{}': expected 'r', 'w', or 'a'",
                s
            ))),
        }
    }

    /// Convert a `FileMode` to its string representation.
    ///
    /// # Returns
    /// `"r"`, `"w"`, `"a"`, or `"c"` (closed).
    pub fn as_str(&self) -> &'static str {
        match self {
            FileMode::Read => "r",
            FileMode::Write => "w",
            FileMode::Append => "a",
            FileMode::Closed => "c",
        }
    }
}

/// A sandboxed file handle for reading or writing game files.
pub struct FileHandle {
    /// Current mode (Read/Write/Append/Closed).
    mode: FileMode,
    /// Resolved absolute path (after sandbox validation).
    #[allow(dead_code)]
    path: PathBuf,
    /// The logical path relative to game root (for error messages).
    logical_path: String,
    /// Internal reader (for Read mode).
    reader: Option<BufReader<std::fs::File>>,
    /// Internal writer (for Write/Append mode).
    writer: Option<BufWriter<std::fs::File>>,
    /// File size (cached at open time for Read mode).
    size: u64,
}

impl FileHandle {
    /// Open a file within the sandbox.
    ///
    /// Read mode is allowed from `base_dir`; Write and Append are restricted to `save/`.
    ///
    /// # Parameters
    /// - `vfs` — the sandboxed filesystem to resolve paths against
    /// - `path` — logical path relative to the game root
    /// - `mode` — `Read`, `Write`, or `Append`
    ///
    /// # Returns
    /// An open `FileHandle`, or an `EngineError` if the path is invalid or access is denied.
    pub fn open(vfs: &GameFS, path: &str, mode: FileMode) -> EngineResult<Self> {
        match mode {
            FileMode::Read => {
                let resolved = vfs.resolve_read_path(path)?;
                let file = std::fs::File::open(&resolved).map_err(|e| {
                    EngineError::FileSystemError(format!(
                        "Cannot open '{}' for reading: {}",
                        path, e
                    ))
                })?;
                let size = file.metadata().map(|m| m.len()).unwrap_or(0);
                Ok(Self {
                    mode,
                    path: resolved,
                    logical_path: path.to_string(),
                    reader: Some(BufReader::new(file)),
                    writer: None,
                    size,
                })
            }
            FileMode::Write => {
                let resolved = vfs.resolve_save_path(path)?;
                if let Some(parent) = resolved.parent() {
                    std::fs::create_dir_all(parent).map_err(|e| {
                        EngineError::FileSystemError(format!("Failed to create directories: {}", e))
                    })?;
                }
                let file = std::fs::File::create(&resolved).map_err(|e| {
                    EngineError::FileSystemError(format!(
                        "Cannot open '{}' for writing: {}",
                        path, e
                    ))
                })?;
                Ok(Self {
                    mode,
                    path: resolved,
                    logical_path: path.to_string(),
                    reader: None,
                    writer: Some(BufWriter::new(file)),
                    size: 0,
                })
            }
            FileMode::Append => {
                let resolved = vfs.resolve_save_path(path)?;
                if let Some(parent) = resolved.parent() {
                    std::fs::create_dir_all(parent).map_err(|e| {
                        EngineError::FileSystemError(format!("Failed to create directories: {}", e))
                    })?;
                }
                let file = std::fs::OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open(&resolved)
                    .map_err(|e| {
                        EngineError::FileSystemError(format!(
                            "Cannot open '{}' for appending: {}",
                            path, e
                        ))
                    })?;
                let size = file.metadata().map(|m| m.len()).unwrap_or(0);
                Ok(Self {
                    mode,
                    path: resolved,
                    logical_path: path.to_string(),
                    reader: None,
                    writer: Some(BufWriter::new(file)),
                    size,
                })
            }
            FileMode::Closed => Err(EngineError::FileSystemError(
                "Cannot open a file in Closed mode".to_string(),
            )),
        }
    }

    /// Read up to `count` bytes, or all remaining bytes when `count` is `None`.
    ///
    /// # Parameters
    /// - `count` — maximum bytes to read, or `None` to read until EOF
    ///
    /// # Returns
    /// The bytes read, or an `EngineError` if the file is not open for reading.
    pub fn read(&mut self, count: Option<usize>) -> EngineResult<Vec<u8>> {
        let reader = self
            .reader
            .as_mut()
            .ok_or_else(|| EngineError::FileSystemError("File not open for reading".to_string()))?;
        match count {
            Some(n) => {
                let mut buf = vec![0u8; n];
                let bytes_read = reader
                    .read(&mut buf)
                    .map_err(|e| EngineError::FileSystemError(format!("Read error: {}", e)))?;
                buf.truncate(bytes_read);
                Ok(buf)
            }
            None => {
                let mut buf = Vec::new();
                reader
                    .read_to_end(&mut buf)
                    .map_err(|e| EngineError::FileSystemError(format!("Read error: {}", e)))?;
                Ok(buf)
            }
        }
    }

    /// Read a single line without the trailing newline character.
    ///
    /// # Returns
    /// `Some(line)` with the line contents, or `None` when EOF is reached.
    pub fn read_line(&mut self) -> EngineResult<Option<String>> {
        let reader = self
            .reader
            .as_mut()
            .ok_or_else(|| EngineError::FileSystemError("File not open for reading".to_string()))?;
        let mut line = String::new();
        let bytes = reader
            .read_line(&mut line)
            .map_err(|e| EngineError::FileSystemError(format!("Read error: {}", e)))?;
        if bytes == 0 {
            Ok(None) // EOF
        } else {
            // Trim trailing newline characters
            if line.ends_with('\n') {
                line.pop();
            }
            if line.ends_with('\r') {
                line.pop();
            }
            Ok(Some(line))
        }
    }

    /// Write raw bytes to the file.
    ///
    /// # Parameters
    /// - `data` — byte slice to write
    ///
    /// # Returns
    /// The number of bytes written, or an `EngineError` if not open for writing.
    pub fn write(&mut self, data: &[u8]) -> EngineResult<usize> {
        let writer = self
            .writer
            .as_mut()
            .ok_or_else(|| EngineError::FileSystemError("File not open for writing".to_string()))?;
        let written = writer
            .write(data)
            .map_err(|e| EngineError::FileSystemError(format!("Write error: {}", e)))?;
        Ok(written)
    }

    /// Seek to an absolute byte position in the file.
    ///
    /// # Parameters
    /// - `pos` — byte offset from the start of the file
    ///
    /// # Returns
    /// The resulting seek position, or an `EngineError` if the file is closed.
    pub fn seek(&mut self, pos: u64) -> EngineResult<u64> {
        if let Some(reader) = self.reader.as_mut() {
            reader
                .seek(SeekFrom::Start(pos))
                .map_err(|e| EngineError::FileSystemError(format!("Seek error: {}", e)))
        } else if let Some(writer) = self.writer.as_mut() {
            writer
                .seek(SeekFrom::Start(pos))
                .map_err(|e| EngineError::FileSystemError(format!("Seek error: {}", e)))
        } else {
            Err(EngineError::FileSystemError("File is closed".to_string()))
        }
    }

    /// Get the current byte position within the file.
    ///
    /// # Returns
    /// The current offset from the beginning of the file, or an `EngineError` if closed.
    pub fn tell(&mut self) -> EngineResult<u64> {
        if let Some(reader) = self.reader.as_mut() {
            reader
                .stream_position()
                .map_err(|e| EngineError::FileSystemError(format!("Tell error: {}", e)))
        } else if let Some(writer) = self.writer.as_mut() {
            writer
                .stream_position()
                .map_err(|e| EngineError::FileSystemError(format!("Tell error: {}", e)))
        } else {
            Err(EngineError::FileSystemError("File is closed".to_string()))
        }
    }

    /// Get the file size in bytes (cached at open time).
    ///
    /// # Returns
    /// File size in bytes (`0` for Write mode until data is flushed).
    pub fn get_size(&self) -> u64 {
        self.size
    }

    /// Get the current file access mode.
    ///
    /// # Returns
    /// The `FileMode` this handle was opened with, or `Closed` after `close()` is called.
    pub fn get_mode(&self) -> FileMode {
        self.mode
    }

    /// Get the logical (game-relative) path of this file.
    ///
    /// # Returns
    /// The path string as passed to `FileHandle::open`.
    pub fn get_path(&self) -> &str {
        &self.logical_path
    }

    /// Flush buffered writes to disk.
    ///
    /// # Returns
    /// `Ok(())` on success, or an `EngineError` if flushing fails.
    pub fn flush(&mut self) -> EngineResult<()> {
        if let Some(writer) = self.writer.as_mut() {
            writer
                .flush()
                .map_err(|e| EngineError::FileSystemError(format!("Flush error: {}", e)))?;
        }
        Ok(())
    }

    /// Close the file handle, flushing any pending writes first.
    ///
    /// # Returns
    /// `Ok(())` on success. Calling `close()` on an already-closed handle is a no-op.
    pub fn close(&mut self) -> EngineResult<()> {
        if self.mode == FileMode::Closed {
            return Ok(());
        }
        self.flush()?;
        self.reader = None;
        self.writer = None;
        self.mode = FileMode::Closed;
        Ok(())
    }

    /// Check whether the end of file has been reached (Read mode only).
    ///
    /// # Returns
    /// `true` when there are no more bytes to read; `false` otherwise.
    pub fn is_eof(&mut self) -> EngineResult<bool> {
        let reader = self
            .reader
            .as_mut()
            .ok_or_else(|| EngineError::FileSystemError("File not open for reading".to_string()))?;
        let buf = reader
            .fill_buf()
            .map_err(|e| EngineError::FileSystemError(format!("EOF check error: {}", e)))?;
        Ok(buf.is_empty())
    }
}

impl Drop for FileHandle {
    fn drop(&mut self) {
        let _ = self.close();
    }
}
