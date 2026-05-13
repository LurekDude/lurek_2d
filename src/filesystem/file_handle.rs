use crate::filesystem::GameFS;
use crate::runtime::error::{EngineError, EngineResult};
use std::io::{BufRead, BufReader, BufWriter, Read, Seek, SeekFrom, Write};
use std::path::PathBuf;
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FileMode {
    Read,
    Write,
    Append,
    Closed,
}
impl FileMode {
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
    pub fn as_str(&self) -> &'static str {
        match self {
            FileMode::Read => "r",
            FileMode::Write => "w",
            FileMode::Append => "a",
            FileMode::Closed => "c",
        }
    }
}
pub struct FileHandle {
    mode: FileMode,
    #[allow(dead_code)]
    path: PathBuf,
    logical_path: String,
    reader: Option<BufReader<std::fs::File>>,
    writer: Option<BufWriter<std::fs::File>>,
    size: u64,
}
impl FileHandle {
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
            Ok(None)
        } else {
            if line.ends_with('\n') {
                line.pop();
            }
            if line.ends_with('\r') {
                line.pop();
            }
            Ok(Some(line))
        }
    }
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
    pub fn get_size(&self) -> u64 {
        self.size
    }
    pub fn get_mode(&self) -> FileMode {
        self.mode
    }
    pub fn get_path(&self) -> &str {
        &self.logical_path
    }
    pub fn flush(&mut self) -> EngineResult<()> {
        if let Some(writer) = self.writer.as_mut() {
            writer
                .flush()
                .map_err(|e| EngineError::FileSystemError(format!("Flush error: {}", e)))?;
        }
        Ok(())
    }
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
