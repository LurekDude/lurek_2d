use crate::engine::error::{EngineError, EngineResult};
use std::path::{Path, PathBuf};

/// File metadata returned by `get_info()`.
///
/// # Fields
/// - `file_type` — whether the entry is a file, directory, symlink, or other
/// - `size` — size in bytes
/// - `modified_time` — last modification time as a UNIX timestamp, if available
/// - `readonly` — whether the entry is marked read-only
#[derive(Debug, Clone)]
pub struct FileInfo {
    /// The type of file system entry.
    pub file_type: FileType,
    /// Size in bytes.
    pub size: u64,
    /// Last modification time as a UNIX timestamp, if available.
    pub modified_time: Option<u64>,
    /// Whether the entry is read-only.
    pub readonly: bool,
}

/// File type classification for `FileInfo`.
///
/// # Variants
/// - `File` — regular file
/// - `Directory` — directory
/// - `Symlink` — symbolic link
/// - `Other` — unknown or special entry
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FileType {
    /// Regular file.
    File,
    /// Directory.
    Directory,
    /// Symbolic link.
    Symlink,
    /// Unknown or special entry.
    Other,
}

/// Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks.
pub struct GameFS {
    base_dir: PathBuf,
    identity: String,
}

impl GameFS {
    /// Creates a new `GameFS` rooted at `base_dir`.
    ///
    /// # Parameters
    /// - `base_dir` — The game's root directory; all paths are resolved relative to this.
    ///
    /// # Returns
    /// A new `GameFS` instance ready for sandboxed I/O.
    pub fn new(base_dir: impl Into<PathBuf>) -> Self {
        GameFS {
            base_dir: base_dir.into(),
            identity: String::new(),
        }
    }

    /// Returns a reference to the base directory path.
    ///
    /// # Returns
    /// `&Path` — The absolute base directory set at construction.
    pub fn base_dir(&self) -> &Path {
        &self.base_dir
    }

    /// Reads the file at `path` (relative to base dir) and returns its contents as a `String`.
    ///
    /// Canonicalises the path and rejects any path that escapes the base directory,
    /// preventing path-traversal attacks.
    ///
    /// # Parameters
    /// - `path` — Relative path to the file within the game directory.
    ///
    /// # Returns
    /// `Ok(String)` — The UTF-8 file contents. `Err(EngineError)` — I/O or traversal error.
    pub fn read_string(&self, path: &str) -> EngineResult<String> {
        let full = self.base_dir.join(path);
        // Prevent path traversal
        let canonical = full.canonicalize().map_err(|e| {
            EngineError::FileSystemError(format!("Cannot resolve '{}': {}", path, e))
        })?;
        let base_canonical = self
            .base_dir
            .canonicalize()
            .map_err(|e| EngineError::FileSystemError(format!("Cannot resolve base dir: {}", e)))?;
        if !canonical.starts_with(&base_canonical) {
            return Err(EngineError::FileSystemError(
                "Access denied: path traversal detected".into(),
            ));
        }
        std::fs::read_to_string(&canonical)
            .map_err(|e| EngineError::FileSystemError(format!("Failed to read '{}': {}", path, e)))
    }

    /// Reads the file at `path` as raw bytes.
    ///
    /// Applies the same path-traversal check as `read_string`.
    ///
    /// # Parameters
    /// - `path` — Relative path to the file within the game directory.
    ///
    /// # Returns
    /// `Ok(Vec<u8>)` — The raw file bytes. `Err(EngineError)` — I/O or traversal error.
    pub fn read_bytes(&self, path: &str) -> EngineResult<Vec<u8>> {
        let full = self.base_dir.join(path);
        let canonical = full.canonicalize().map_err(|e| {
            EngineError::FileSystemError(format!("Cannot resolve '{}': {}", path, e))
        })?;
        let base_canonical = self
            .base_dir
            .canonicalize()
            .map_err(|e| EngineError::FileSystemError(format!("Cannot resolve base dir: {}", e)))?;
        if !canonical.starts_with(&base_canonical) {
            return Err(EngineError::FileSystemError(
                "Access denied: path traversal detected".into(),
            ));
        }
        std::fs::read(&canonical)
            .map_err(|e| EngineError::FileSystemError(format!("Failed to read '{}': {}", path, e)))
    }

    /// Writes `content` to `path`, which must be inside the `save/` subdirectory.
    ///
    /// Creates parent directories automatically. Rejects any path outside `save/`
    /// to prevent scripts from writing arbitrary files to the system.
    ///
    /// # Parameters
    /// - `path` — Relative path under `save/`, e.g. `"save/progress.json"`.
    /// - `content` — String content to write.
    ///
    /// # Returns
    /// `Ok(())` on success. `Err(EngineError)` if the path is outside `save/` or an I/O error occurs.
    pub fn write_string(&self, path: &str, content: &str) -> EngineResult<()> {
        let full = self.base_dir.join(path);
        // Only allow writing within save/ subdirectory
        let save_dir = self.base_dir.join("save");
        if !full.starts_with(&save_dir) {
            return Err(EngineError::FileSystemError(
                "Write access restricted to save/ directory".into(),
            ));
        }
        // Prevent path traversal via ".." components
        for component in std::path::Path::new(path).components() {
            if let std::path::Component::ParentDir = component {
                return Err(EngineError::FileSystemError(
                    "Access denied: path traversal detected".into(),
                ));
            }
        }
        if let Some(parent) = full.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                EngineError::FileSystemError(format!("Failed to create directories: {}", e))
            })?;
        }
        std::fs::write(&full, content)
            .map_err(|e| EngineError::FileSystemError(format!("Failed to write '{}': {}", path, e)))
    }

    /// Returns `true` if the file or directory at `path` exists within the game directory.
    ///
    /// # Parameters
    /// - `path` — Relative path to check.
    ///
    /// # Returns
    /// `bool` — `true` if the path exists on disk.
    pub fn exists(&self, path: &str) -> bool {
        self.base_dir.join(path).exists()
    }

    /// Lists all entries in the directory at `path` relative to the game directory.
    ///
    /// # Parameters
    /// - `path` — Relative path to the directory to list.
    ///
    /// # Returns
    /// `Ok(Vec<String>)` — Entry names (files and subdirectories). `Err(EngineError)` on I/O failure.
    pub fn list(&self, path: &str) -> EngineResult<Vec<String>> {
        let full = self.base_dir.join(path);
        let mut entries = Vec::new();
        for entry in std::fs::read_dir(&full).map_err(|e| {
            EngineError::FileSystemError(format!("Failed to list '{}': {}", path, e))
        })? {
            let entry = entry.map_err(|e| {
                EngineError::FileSystemError(format!("Failed to read entry: {}", e))
            })?;
            if let Some(name) = entry.file_name().to_str() {
                entries.push(name.to_string());
            }
        }
        Ok(entries)
    }

    // ── Directory Operations ──────────────────────────────────────────

    /// Get sorted directory items relative to `base_dir`.
    ///
    /// # Parameters
    /// - `path` — directory path relative to the game root
    ///
    /// # Returns
    /// Sorted list of entry names (filenames only, not full paths), or an `EngineError`.
    pub fn get_directory_items(&self, path: &str) -> EngineResult<Vec<String>> {
        let resolved = self.resolve_read_path(path)?;
        let rd = std::fs::read_dir(&resolved).map_err(|e| {
            EngineError::FileSystemError(format!("Cannot read directory '{}': {}", path, e))
        })?;
        let mut items: Vec<String> = rd
            .filter_map(|e| e.ok())
            .filter_map(|e| e.file_name().to_str().map(|s| s.to_string()))
            .collect();
        items.sort();
        Ok(items)
    }

    /// Check if the given path refers to a regular file.
    ///
    /// # Parameters
    /// - `path` — path relative to the game root
    ///
    /// # Returns
    /// `true` if the path exists and is a regular file; `false` otherwise.
    pub fn is_file(&self, path: &str) -> bool {
        self.resolve_read_path(path)
            .map(|p| p.is_file())
            .unwrap_or(false)
    }

    /// Check if the given path refers to a directory.
    ///
    /// # Parameters
    /// - `path` — path relative to the game root
    ///
    /// # Returns
    /// `true` if the path exists and is a directory; `false` otherwise.
    pub fn is_directory(&self, path: &str) -> bool {
        self.resolve_read_path(path)
            .map(|p| p.is_dir())
            .unwrap_or(false)
    }

    /// Create a directory (and all parent directories) inside the save area.
    ///
    /// # Parameters
    /// - `path` — target directory path; must be inside `save/`
    ///
    /// # Returns
    /// `Ok(())` on success, or an `EngineError` if creation fails or the path is outside `save/`.
    pub fn create_directory(&self, path: &str) -> EngineResult<()> {
        let resolved = self.resolve_save_path(path)?;
        std::fs::create_dir_all(&resolved).map_err(|e| {
            EngineError::FileSystemError(format!("Cannot create directory '{}': {}", path, e))
        })
    }

    /// Remove a file or empty directory from the save area.
    ///
    /// # Parameters
    /// - `path` — path to remove; must be inside `save/`
    ///
    /// # Returns
    /// `Ok(())` on success, or an `EngineError` if removal fails or path is outside `save/`.
    pub fn remove(&self, path: &str) -> EngineResult<()> {
        let resolved = self.resolve_save_path(path)?;
        if resolved.is_dir() {
            std::fs::remove_dir(&resolved).map_err(|e| {
                EngineError::FileSystemError(format!("Cannot remove directory '{}': {}", path, e))
            })
        } else {
            std::fs::remove_file(&resolved).map_err(|e| {
                EngineError::FileSystemError(format!("Cannot remove file '{}': {}", path, e))
            })
        }
    }

    /// Get file or directory metadata.
    ///
    /// # Parameters
    /// - `path` — path relative to the game root
    ///
    /// # Returns
    /// A `FileInfo` struct with type, size, modification time, and read-only flag;
    /// returns an `EngineError` if the path does not exist or is inaccessible.
    pub fn get_info(&self, path: &str) -> EngineResult<FileInfo> {
        let resolved = self.resolve_read_path(path)?;
        let metadata = std::fs::metadata(&resolved).map_err(|e| {
            EngineError::FileSystemError(format!("Cannot get info for '{}': {}", path, e))
        })?;
        let modified_time = metadata
            .modified()
            .ok()
            .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
            .map(|d| d.as_secs());
        Ok(FileInfo {
            file_type: if metadata.is_file() {
                FileType::File
            } else if metadata.is_dir() {
                FileType::Directory
            } else {
                FileType::Other
            },
            size: metadata.len(),
            modified_time,
            readonly: metadata.permissions().readonly(),
        })
    }

    /// Append UTF-8 string content to a file in the save area.
    ///
    /// Creates the file and any parent directories if they do not exist.
    ///
    /// # Parameters
    /// - `path` — target file path; must be inside `save/`
    /// - `content` — string to append
    ///
    /// # Returns
    /// `Ok(())` on success, or an `EngineError` on I/O failure or path violation.
    pub fn append_string(&self, path: &str, content: &str) -> EngineResult<()> {
        let full = self.base_dir.join(path);
        let save_dir = self.base_dir.join("save");
        if !full.starts_with(&save_dir) {
            return Err(EngineError::FileSystemError(
                "Write access restricted to save/ directory".into(),
            ));
        }
        // Prevent path traversal via ".." components
        for component in std::path::Path::new(path).components() {
            if let std::path::Component::ParentDir = component {
                return Err(EngineError::FileSystemError(
                    "Access denied: path traversal detected".into(),
                ));
            }
        }
        if let Some(parent) = full.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                EngineError::FileSystemError(format!("Failed to create directories: {}", e))
            })?;
        }
        use std::io::Write;
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&full)
            .map_err(|e| {
                EngineError::FileSystemError(format!("Failed to open '{}' for append: {}", path, e))
            })?;
        file.write_all(content.as_bytes()).map_err(|e| {
            EngineError::FileSystemError(format!("Failed to append to '{}': {}", path, e))
        })
    }

    // ── Path Utilities ────────────────────────────────────────────────

    /// Get the game source directory (where `main.lua` lives).
    ///
    /// # Returns
    /// Absolute path of the game root directory as a `String`.
    pub fn get_source(&self) -> String {
        self.base_dir.to_string_lossy().to_string()
    }

    /// Get the save directory path.
    ///
    /// # Returns
    /// Path to the `save/` subdirectory inside the game root.
    pub fn get_save_directory(&self) -> PathBuf {
        self.base_dir.join("save")
    }

    /// Get the current working directory of the process.
    ///
    /// # Returns
    /// The working directory as a `String`, or an `EngineError` if it cannot be determined.
    pub fn get_working_directory() -> EngineResult<String> {
        std::env::current_dir()
            .map(|p| p.to_string_lossy().to_string())
            .map_err(|e| {
                EngineError::FileSystemError(format!("Cannot get working directory: {}", e))
            })
    }

    /// Get the current user's home directory.
    ///
    /// # Returns
    /// Home directory path as a `String` (`USERPROFILE` on Windows, `HOME` on Unix).
    /// Falls back to the current directory if the environment variable is not set.
    pub fn get_user_directory() -> String {
        #[cfg(target_os = "windows")]
        {
            std::env::var("USERPROFILE").unwrap_or_else(|_| {
                std::env::current_dir()
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or_else(|_| ".".to_string())
            })
        }
        #[cfg(not(target_os = "windows"))]
        {
            std::env::var("HOME").unwrap_or_else(|_| {
                std::env::current_dir()
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or_else(|_| ".".to_string())
            })
        }
    }

    /// Get the game identity string used for save directory naming.
    ///
    /// # Returns
    /// The identity string, or an empty string if not set.
    pub fn get_identity(&self) -> &str {
        &self.identity
    }

    /// Set the game identity string.
    ///
    /// # Parameters
    /// - `identity` — short name used to identify the game (e.g. `"my_awesome_game"`)
    pub fn set_identity(&mut self, identity: &str) {
        self.identity = identity.to_string();
    }

    // ── Internal Path Resolution ──────────────────────────────────────

    /// Resolve a logical path to an absolute path for reading.
    ///
    /// Rejects path-traversal sequences (`..`) via `canonicalize()`.
    ///
    /// # Parameters
    /// - `path` — logical path relative to the game root
    ///
    /// # Returns
    /// Canonical absolute path, or an `EngineError` if the path escapes the sandbox.
    pub fn resolve_read_path(&self, path: &str) -> EngineResult<PathBuf> {
        let full = self.base_dir.join(path);
        let canonical = full.canonicalize().map_err(|e| {
            EngineError::FileSystemError(format!("Cannot resolve '{}': {}", path, e))
        })?;
        let base_canonical = self
            .base_dir
            .canonicalize()
            .map_err(|e| EngineError::FileSystemError(format!("Cannot resolve base dir: {}", e)))?;
        if !canonical.starts_with(&base_canonical) {
            return Err(EngineError::FileSystemError(
                "Access denied: path traversal detected".into(),
            ));
        }
        Ok(canonical)
    }

    /// Resolve a logical path to an absolute path for writing.
    ///
    /// Enforces that the target is inside the `save/` subdirectory.
    ///
    /// # Parameters
    /// - `path` — logical path; must begin with `save/`
    ///
    /// # Returns
    /// Absolute path inside `save/`, or an `EngineError` if the path is outside the write sandbox.
    pub fn resolve_save_path(&self, path: &str) -> EngineResult<PathBuf> {
        let full = self.base_dir.join(path);
        let save_dir = self.base_dir.join("save");
        // For files that don't exist yet, check the logical path prefix
        if !full.starts_with(&save_dir) {
            return Err(EngineError::FileSystemError(
                "Write access restricted to save/ directory".into(),
            ));
        }
        // Prevent path traversal by checking for ".." components
        for component in std::path::Path::new(path).components() {
            if let std::path::Component::ParentDir = component {
                return Err(EngineError::FileSystemError(
                    "Access denied: path traversal detected".into(),
                ));
            }
        }
        Ok(full)
    }
}
