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

use std::collections::VecDeque;
use std::fmt::Write as FmtWrite;
use std::fs::{File, OpenOptions};
use std::io::Write as IoWrite;
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

// ── SinkKind ─────────────────────────────────────────────────────────────

/// The dispatching strategy for a registered sink.
///
/// # Variants
/// - `File` — File variant.
/// - `Memory` — Memory variant.
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
}

impl std::fmt::Debug for SinkKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SinkKind::File { path, .. } => write!(f, "File({path})"),
            SinkKind::Memory { capacity, .. } => write!(f, "Memory({capacity})"),
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
        if let SinkKind::File { file, .. } = &self.kind {
            if let Ok(guard) = file.lock() {
                // File implements Flush but we can only access via MutexGuard;
                // the underlying OS buffer is flushed by the drop of the guard.
                drop(guard as MutexGuard<File>);
            }
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
