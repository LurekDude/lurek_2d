//! Configurable per-sink logging dispatch.
//!
//! [`SinkKind`] and [`Sink`] define additional log output destinations for Lua
//! games beyond the default stderr / `env_logger` channel.  The [`SinkRegistry`]
//! stores active sinks thread-locally so Lua-level log calls can fan out to each
//! registered destination without touching the Rust `log` crate.
//!
//! # Supported sinks
//! | Kind | Description |
//! |---|---|
//! | `File` | Writes every entry to a UTF-8 text file (append mode). |
//! | `Memory` | Retains entries in a bounded ring buffer for Lua inspection. |
//! | `RotatingFile` | Appends to a file and rotates by size, keeping N backup copies. |

use std::collections::VecDeque;
use std::fmt::Write as FmtWrite;
use std::fs::{self, File, OpenOptions};
use std::io::Write as IoWrite;
use std::path::{Path, PathBuf};
use std::sync::{Mutex, MutexGuard};

// ── LogLevel ──────────────────────────────────────────────────────────────

/// Minimum log level that a sink will accept.
///
/// # Variants
/// - `Debug` — Debug variant.
/// - `Info` — Info variant.
/// - `Warn` — Warn variant.
/// - `Error` — Error variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SinkLevel {
    /// Debug variant.
    Debug,
    /// Info variant.
    Info,
    /// Warn variant.
    Warn,
    /// Error variant.
    Error,
}

impl SinkLevel {
    /// Parses a level string ("debug", "info", "warn", "error"). Defaults to [`SinkLevel::Debug`].
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "info" => Self::Info,
            "warn" | "warning" => Self::Warn,
            "error" | "err" => Self::Error,
            _ => Self::Debug,
        }
    }

    /// Returns a short lowercase string representation.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Debug => "DEBUG",
            Self::Info => "INFO",
            Self::Warn => "WARN",
            Self::Error => "ERROR",
        }
    }
}

// ── MemoryEntry ───────────────────────────────────────────────────────────

/// A single log entry retained by a [`SinkKind::Memory`] sink.
///
/// # Fields
/// - `level` — `SinkLevel`.
/// - `message` — `String`.
/// - `tag` — `String`.
#[derive(Debug, Clone)]
pub struct MemoryEntry {
    /// Level of the log entry.
    pub level: SinkLevel,
    /// Log message text.
    pub message: String,
    /// Source tag (caller-provided category).
    pub tag: String,
}

// ── RotatingFileSink ─────────────────────────────────────────────────────

/// A file sink that rotates the log file when it exceeds a maximum size.
///
/// Files are named `<basename>`, `<basename>.1`, `<basename>.2`, … up to `keep_files`
/// backup copies.  When the active file grows beyond `max_bytes` the sink renames
/// each backup one position higher, opens a fresh file at the base path, and deletes
/// the oldest backup when the count exceeds `keep_files`.
///
/// # Fields
/// - `path` — `PathBuf` — Base file path (e.g. `"lurek2d.log"`).
/// - `max_bytes` — `u64` — Maximum file size before rotation (default 10 MiB).
/// - `keep_files` — `usize` — Number of rotated backup files to keep (default 3).
/// - `current_size` — `u64` — Bytes written to the current active file.
pub struct RotatingFileSink {
    /// Base log file path.
    pub path: PathBuf,
    /// Maximum bytes before rotating.
    pub max_bytes: u64,
    /// Number of old files to retain.
    pub keep_files: usize,
    current_size: u64,
    /// The open file handle; `None` only momentarily after a rotation.
    file: Option<File>,
}

impl RotatingFileSink {
    /// Opens or creates a rotating file sink at `path`.
    ///
    /// # Parameters
    /// - `path` — `&str` — Base log file path.
    /// - `max_bytes` — `u64` — Rotation threshold.  Pass `0` to use the default (10 MiB).
    /// - `keep_files` — `usize` — Backups to retain.  Pass `0` to use the default (3).
    ///
    /// # Returns
    /// `Result<Self, String>`
    pub fn open(path: &str, max_bytes: u64, keep_files: usize) -> Result<Self, String> {
        let path_buf = PathBuf::from(path);
        let effective_max = if max_bytes == 0 { 10 * 1024 * 1024 } else { max_bytes };
        let effective_keep = if keep_files == 0 { 3 } else { keep_files };
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path_buf)
            .map_err(|e| format!("cannot open rotating log '{path}': {e}"))?;
        let current_size = file
            .metadata()
            .map(|m| m.len())
            .unwrap_or(0);
        Ok(Self {
            path: path_buf,
            max_bytes: effective_max,
            keep_files: effective_keep,
            current_size,
            file: Some(file),
        })
    }

    /// Appends `message` to the active log file, rotating if the size threshold is exceeded.
    ///
    /// Rotation renames existing backups one index higher, opens a fresh base file, and
    /// removes the oldest backup when the count would exceed `keep_files`.
    ///
    /// # Parameters
    /// - `message` — `&str`
    pub fn write_with_rotation(&mut self, message: &str) {
        // Lazy-open if the handle was closed during a previous rotation.
        if self.file.is_none() {
            if let Ok(f) = OpenOptions::new().create(true).append(true).open(&self.path) {
                self.current_size = f.metadata().map(|m| m.len()).unwrap_or(0);
                self.file = Some(f);
            } else {
                return;
            }
        }

        let bytes = message.as_bytes();
        if let Some(ref mut f) = self.file {
            if f.write_all(bytes).is_err() {
                return;
            }
        }
        self.current_size += bytes.len() as u64;

        if self.current_size >= self.max_bytes {
            self.rotate();
        }
    }

    /// Flushes the underlying OS write buffer.
    pub fn flush(&mut self) {
        if let Some(ref mut f) = self.file {
            let _ = f.flush();
        }
    }

    /// Performs the rotation: closes the current file, renames backups, opens a new base file.
    fn rotate(&mut self) {
        // Close the current file handle by dropping it before any rename.
        // This is required on Windows where open files cannot be renamed.
        self.file = None;

        // Delete the oldest backup so the shift does not overflow `keep_files`.
        Self::delete_oldest_if_needed(&self.path, self.keep_files);

        // Shift backups upward: .N-1 → .N, …, .1 → .2
        for i in (1..self.keep_files).rev() {
            let from = Self::backup_path(&self.path, i);
            let to = Self::backup_path(&self.path, i + 1);
            if from.exists() {
                let _ = fs::rename(&from, &to);
            }
        }

        // Rename base → .1
        if self.path.exists() {
            let backup_1 = Self::backup_path(&self.path, 1);
            let _ = fs::rename(&self.path, &backup_1);
        }

        // Open a fresh base file; `file` remains `None` on failure and will be
        // retried lazily on the next `write_with_rotation` call.
        match OpenOptions::new().create(true).write(true).truncate(true).open(&self.path) {
            Ok(f) => {
                self.file = Some(f);
                self.current_size = 0;
            }
            Err(_) => {
                self.current_size = 0;
            }
        }
    }

    /// Returns the path for backup number `n` (e.g. `lurek2d.log.2`).
    fn backup_path(base: &Path, n: usize) -> PathBuf {
        let name = base
            .file_name()
            .and_then(|s| s.to_str())
            .unwrap_or("lurek2d.log");
        let dir = base.parent().unwrap_or_else(|| Path::new("."));
        dir.join(format!("{name}.{n}"))
    }

    /// Deletes the oldest backup file (index = `keep_files`) if it exists.
    fn delete_oldest_if_needed(base: &Path, keep_files: usize) {
        let oldest = Self::backup_path(base, keep_files);
        if oldest.exists() {
            let _ = fs::remove_file(&oldest);
        }
    }
}

// Manual Debug — File does not implement Debug.
impl std::fmt::Debug for RotatingFileSink {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "RotatingFileSink {{ path: {:?}, max_bytes: {}, keep_files: {}, current_size: {} }}",
            self.path, self.max_bytes, self.keep_files, self.current_size
        )
    }
}

// ── SinkKind ─────────────────────────────────────────────────────────────

/// The dispatching strategy for a registered sink.
///
/// # Variants
/// - `File` — File variant.
/// - `Memory` — Memory variant.
/// - `RotatingFile` — RotatingFile variant.
pub enum SinkKind {
    /// Writes entries to a file.
    File {
        /// The open file handle.
        file: Mutex<File>,
        /// Filesystem path for display.
        path: String,
    },
    /// Retains entries in an in-memory ring buffer.
    Memory {
        /// Ring buffer of recent entries.
        entries: Mutex<VecDeque<MemoryEntry>>,
        /// Maximum retained entries.
        capacity: usize,
    },
    /// Appends entries to a file with automatic rotation by size.
    RotatingFile {
        /// The mutex-guarded rotating file sink.
        sink: Mutex<RotatingFileSink>,
        /// Filesystem path for display.
        path: String,
    },
}

impl std::fmt::Debug for SinkKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SinkKind::File { path, .. } => write!(f, "File({path})"),
            SinkKind::Memory { capacity, .. } => write!(f, "Memory({capacity})"),
            SinkKind::RotatingFile { path, .. } => write!(f, "RotatingFile({path})"),
        }
    }
}

// ── Sink ──────────────────────────────────────────────────────────────────

/// A registered log output destination.
///
/// # Fields
/// - `id` — `u64`.
/// - `min_level` — `SinkLevel`.
/// - `kind` — `SinkKind`.
#[derive(Debug)]
pub struct Sink {
    /// Unique sink id.
    pub id: u64,
    /// Entries below this level are silently dropped.
    pub min_level: SinkLevel,
    /// The dispatch strategy.
    pub kind: SinkKind,
}

impl Sink {
    /// Creates a file sink.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `path` — `&str`.
    /// - `min_level` — `SinkLevel`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn file(id: u64, path: &str, min_level: SinkLevel) -> Result<Self, String> {
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)
            .map_err(|e| format!("cannot open log file '{path}': {e}"))?;
        Ok(Self {
            id,
            min_level,
            kind: SinkKind::File { file: Mutex::new(file), path: path.to_string() },
        })
    }

    /// Creates a memory sink.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `capacity` — `usize`.
    /// - `min_level` — `SinkLevel`.
    ///
    /// # Returns
    /// `Self`.
    pub fn memory(id: u64, capacity: usize, min_level: SinkLevel) -> Self {
        Self {
            id,
            min_level,
            kind: SinkKind::Memory {
                entries: Mutex::new(VecDeque::with_capacity(capacity.max(1))),
                capacity: capacity.max(1),
            },
        }
    }

    /// Creates a rotating file sink that rotates at `max_bytes` and keeps `keep_files` backups.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `path` — `&str` — Base log file path (e.g. `"lurek2d.log"`).
    /// - `min_level` — `SinkLevel`.
    /// - `max_bytes` — `u64` — Rotation threshold; `0` uses the default (10 MiB).
    /// - `keep_files` — `usize` — Backup count; `0` uses the default (3).
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn rotating_file(
        id: u64,
        path: &str,
        min_level: SinkLevel,
        max_bytes: u64,
        keep_files: usize,
    ) -> Result<Self, String> {
        let inner = RotatingFileSink::open(path, max_bytes, keep_files)?;
        Ok(Self {
            id,
            min_level,
            kind: SinkKind::RotatingFile {
                sink: Mutex::new(inner),
                path: path.to_string(),
            },
        })
    }

    /// Dispatches a log entry to this sink (no-op when below `min_level`).
    ///
    /// # Parameters
    /// - `level` — `SinkLevel`.
    /// - `tag` — `&str`.
    /// - `message` — `&str`.
    pub fn write(&self, level: SinkLevel, tag: &str, message: &str) {
        if level < self.min_level {
            return;
        }
        match &self.kind {
            SinkKind::File { file, .. } => {
                let mut text = String::new();
                let _ = writeln!(text, "[{}] {}: {}", level.as_str(), tag, message);
                if let Ok(mut guard) = file.lock() {
                    let _ = guard.write_all(text.as_bytes());
                }
            }
            SinkKind::Memory { entries, capacity } => {
                if let Ok(mut q) = entries.lock() {
                    if q.len() >= *capacity {
                        q.pop_front();
                    }
                    q.push_back(MemoryEntry {
                        level,
                        message: message.to_string(),
                        tag: tag.to_string(),
                    });
                }
            }
            SinkKind::RotatingFile { sink, .. } => {
                let mut text = String::new();
                let _ = writeln!(text, "[{}] {}: {}", level.as_str(), tag, message);
                if let Ok(mut guard) = sink.lock() {
                    guard.write_with_rotation(&text);
                }
            }
        }
    }

    /// Returns the sink type name string.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn type_name(&self) -> &'static str {
        match &self.kind {
            SinkKind::File { .. } => "file",
            SinkKind::Memory { .. } => "memory",
            SinkKind::RotatingFile { .. } => "rotating",
        }
    }

    /// Returns the path for a file sink, or `None`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn path(&self) -> Option<&str> {
        match &self.kind {
            SinkKind::File { path, .. } => Some(path),
            SinkKind::Memory { .. } => None,
            SinkKind::RotatingFile { path, .. } => Some(path),
        }
    }

    /// Reads all memory entries and optionally drains them.
    ///
    /// Returns `None` when called on a non-memory sink.
    ///
    /// # Parameters
    /// - `drain` — `bool`.
    ///
    /// # Returns
    /// `Option<Vec<MemoryEntry>>`.
    pub fn read_memory(&self, drain: bool) -> Option<Vec<MemoryEntry>> {
        match &self.kind {
            SinkKind::Memory { entries, .. } => {
                if let Ok(mut q) = entries.lock() {
                    if drain {
                        Some(q.drain(..).collect())
                    } else {
                        Some(q.iter().cloned().collect())
                    }
                } else {
                    Some(Vec::new())
                }
            }
            SinkKind::File { .. } => None,
        }
    }

    /// Flushes a file sink (no-op on memory sinks).
    pub fn flush(&self) {
        match &self.kind {
            SinkKind::File { file, .. } => {
                if let Ok(guard) = file.lock() {
                    // File implements Flush but we can only access via MutexGuard;
                    // the underlying OS buffer is flushed by the drop of the guard.
                    drop(guard as MutexGuard<File>);
                }
            }
            SinkKind::RotatingFile { sink, .. } => {
                if let Ok(mut guard) = sink.lock() {
                    guard.flush();
                }
            }
            SinkKind::Memory { .. } => {}
        }
    }
}

// ── SinkRegistry ─────────────────────────────────────────────────────────

/// Thread-local registry of active log sinks.
///
/// # Fields
/// - `sinks` — `Vec<Sink>`.
/// - `next_id` — `u64`.
#[derive(Debug, Default)]
pub struct SinkRegistry {
    /// Active sinks.
    pub sinks: Vec<Sink>,
    next_id: u64,
}

impl SinkRegistry {
    /// Creates an empty registry.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self { sinks: Vec::new(), next_id: 1 }
    }

    /// Adds a sink, returning its assigned id.
    ///
    /// # Parameters
    /// - `sink` — `Sink`.
    ///
    /// # Returns
    /// `u64`.
    pub fn add(&mut self, mut sink: Sink) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        sink.id = id;
        self.sinks.push(sink);
        id
    }

    /// Removes a sink by id. Returns `true` if one was removed.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.sinks.len();
        self.sinks.retain(|s| s.id != id);
        self.sinks.len() < before
    }

    /// Removes all sinks.
    pub fn clear(&mut self) {
        self.sinks.clear();
    }

    /// Dispatches a log entry to all registered sinks.
    ///
    /// # Parameters
    /// - `level` — `SinkLevel`.
    /// - `tag` — `&str`.
    /// - `message` — `&str`.
    pub fn dispatch(&self, level: SinkLevel, tag: &str, message: &str) {
        for sink in &self.sinks {
            sink.write(level, tag, message);
        }
    }

    /// Returns a sink by id.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `Option<&Sink>`.
    pub fn get(&self, id: u64) -> Option<&Sink> {
        self.sinks.iter().find(|s| s.id == id)
    }
}
