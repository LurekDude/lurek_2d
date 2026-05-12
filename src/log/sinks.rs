//! Configurable per-sink logging dispatch.
//!
//! [`SinkKind`] and [`Sink`] define additional log output destinations for Lua
//! games beyond the default stderr / `env_logger` channel.  The [`SinkRegistry`]
//! stores active sinks thread-locally so Lua-level log calls can fan out to each
//! registered destination without touching the Rust `log` crate.
//!
//! ## Design
//!
//! Each [`Sink`] is owned by one Lua VM via its [`SinkRegistry`].  Sinks are
//! identified by a monotonically increasing `u64` id assigned by the registry.
//! The level-filtering logic lives in [`Sink::write`] / [`Sink::write_structured`]
//! so callers don't need to pre-filter.
//!
//! ## Supported sinks
//!
//! | Kind | Description |
//! |---|---|
//! | `File` | Writes every entry to a UTF-8 text file (append mode). |
//! | `Memory` | Retains entries in a bounded ring buffer for Lua inspection. |
//! | `RotatingFile` | Appends to a file and rotates by size, keeping N backup copies. |

use crate::data::RingBuffer;
use std::collections::BTreeMap;
use std::fs::{self, File, OpenOptions};
use std::io::Write as IoWrite;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::sync::{Mutex, MutexGuard};
use std::time::{SystemTime, UNIX_EPOCH};

// ── LogLevel ──────────────────────────────────────────────────────────────

/// Minimum severity threshold that a [`Sink`] will accept.
///
/// Entries below a sink's configured `SinkLevel` are silently dropped.
/// The ordering is `Debug < Info < Warn < Error`, derived via `PartialOrd` /
/// `Ord`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SinkLevel {
    /// Lowest severity — verbose diagnostic output.
    Debug,
    /// Extremely verbose tracing output.
    Trace,
    /// Normal operational messages.
    Info,
    /// Potential issues that do not prevent execution.
    Warn,
    /// Critical failures requiring attention.
    Error,
}

impl SinkLevel {
    /// Returns the canonical uppercase display string (`"DEBUG"`, `"INFO"`,
    /// `"TRACE"`, `"WARN"`, `"ERROR"`).
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Debug => "DEBUG",
            Self::Trace => "TRACE",
            Self::Info => "INFO",
            Self::Warn => "WARN",
            Self::Error => "ERROR",
        }
    }
}

impl FromStr for SinkLevel {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "debug" => Ok(Self::Debug),
            "trace" => Ok(Self::Trace),
            "info" => Ok(Self::Info),
            "warn" | "warning" => Ok(Self::Warn),
            "error" | "err" => Ok(Self::Error),
            _ => Err(format!("unknown sink level '{s}'")),
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
/// - `fields` — `Option<BTreeMap<String, String>>`. Structured key-value pairs (None for plain entries).
#[derive(Debug, Clone)]
pub struct MemoryEntry {
    /// Level of the log entry.
    pub level: SinkLevel,
    /// Log message text.
    pub message: String,
    /// Source tag (caller-provided category).
    pub tag: String,
    /// Structured key-value fields; `None` for plain log entries.
    pub fields: Option<BTreeMap<String, String>>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum SinkFormat {
    Plain,
    Json,
    Ndjson,
}

fn timestamp_millis() -> Option<u128> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .ok()
        .map(|duration| duration.as_millis())
}

fn format_structured_message(message: &str, fields: &BTreeMap<String, String>) -> String {
    if fields.is_empty() {
        message.to_string()
    } else {
        let kvs: Vec<String> = fields.iter().map(|(k, v)| format!("{k}={v}")).collect();
        format!("{} {{ {} }}", message, kvs.join(", "))
    }
}

fn format_log_line(
    level: SinkLevel,
    tag: &str,
    message: &str,
    timestamp: Option<u128>,
    use_color: bool,
) -> String {
    let line = match timestamp {
        Some(ts) => format!("[{ts}] [{}] {}: {}\n", level.as_str(), tag, message),
        None => format!("[{}] {}: {}\n", level.as_str(), tag, message),
    };
    if !use_color {
        return line;
    }
    let color = match level {
        SinkLevel::Error => "\u{1b}[31m",
        SinkLevel::Warn => "\u{1b}[33m",
        SinkLevel::Info => "\u{1b}[32m",
        SinkLevel::Debug => "\u{1b}[36m",
        SinkLevel::Trace => "\u{1b}[90m",
    };
    format!("{color}{line}\u{1b}[0m")
}

fn format_json_line(
    level: SinkLevel,
    tag: &str,
    message: &str,
    fields: Option<&BTreeMap<String, String>>,
    timestamp_ms: Option<u128>,
) -> String {
    let value = if let Some(fields) = fields {
        serde_json::json!({
            "level": level.as_str().to_lowercase(),
            "tag": tag,
            "message": message,
            "timestamp_ms": timestamp_ms,
            "fields": fields,
        })
    } else {
        serde_json::json!({
            "level": level.as_str().to_lowercase(),
            "tag": tag,
            "message": message,
            "timestamp_ms": timestamp_ms,
        })
    };
    format!("{}\n", value)
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
        let effective_max = if max_bytes == 0 {
            10 * 1024 * 1024
        } else {
            max_bytes
        };
        let effective_keep = if keep_files == 0 { 3 } else { keep_files };
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path_buf)
            .map_err(|e| format!("cannot open rotating log '{path}': {e}"))?;
        let current_size = file.metadata().map(|m| m.len()).unwrap_or(0);
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
            if let Ok(f) = OpenOptions::new()
                .create(true)
                .append(true)
                .open(&self.path)
            {
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
        // 1. Close the current file handle by dropping it before any rename.
        //    Required on Windows where open file handles prevent renames.
        self.file = None;

        // 2. Delete the oldest backup so the upward shift doesn't overflow `keep_files`.
        Self::delete_oldest_if_needed(&self.path, self.keep_files);

        // 3. Shift backups upward: .N-1 → .N, …, .1 → .2
        //    Iterating in reverse avoids overwriting a higher-numbered backup.
        for i in (1..self.keep_files).rev() {
            let from = Self::backup_path(&self.path, i);
            let to = Self::backup_path(&self.path, i + 1);
            if from.exists() {
                let _ = fs::rename(&from, &to);
            }
        }

        // 4. Rename base → .1
        if self.path.exists() {
            let backup_1 = Self::backup_path(&self.path, 1);
            let _ = fs::rename(&self.path, &backup_1);
        }

        // 5. Open a fresh base file; `file` remains `None` on failure and will
        //    be retried lazily on the next `write_with_rotation` call.
        match OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(&self.path)
        {
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
/// Each variant owns its storage — a file handle, a ring buffer, or a
/// [`RotatingFileSink`] — behind a [`Mutex`] so the sink can be shared
/// safely with the `SinkRegistry`.
pub enum SinkKind {
    /// Writes entries to an append-mode text file.
    File {
        /// The open file handle (mutex-guarded for concurrent writes).
        file: Mutex<File>,
        /// Filesystem path for display and diagnostics.
        path: String,
    },
    /// Retains entries in a bounded in-memory ring buffer.
    Memory {
        /// Ring buffer of recent entries, evicting oldest on overflow.
        entries: Mutex<RingBuffer<MemoryEntry>>,
        /// Maximum retained entries before eviction.
        capacity: usize,
    },
    /// Appends entries to a file with automatic size-based rotation.
    RotatingFile {
        /// The mutex-guarded rotating file sink.
        sink: Mutex<RotatingFileSink>,
        /// Filesystem path for display and diagnostics.
        path: String,
    },
    /// Calls back into Lua-side push handlers without polling.
    Callback {
        /// Opaque callback id resolved by the Lua binding layer.
        callback_id: u64,
    },
}

impl std::fmt::Debug for SinkKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SinkKind::File { path, .. } => write!(f, "File({path})"),
            SinkKind::Memory { capacity, .. } => write!(f, "Memory({capacity})"),
            SinkKind::RotatingFile { path, .. } => write!(f, "RotatingFile({path})"),
            SinkKind::Callback { callback_id } => write!(f, "Callback({callback_id})"),
        }
    }
}

// ── Sink ──────────────────────────────────────────────────────────────────

/// A registered log output destination.
///
/// Each `Sink` owns a [`SinkKind`] backend and an independent
/// [`SinkLevel`] threshold.  The [`SinkRegistry`] assigns the `id` when
/// the sink is added; callers use that id to remove, flush, or read from
/// the sink later.
#[derive(Debug)]
pub struct Sink {
    /// Unique sink id.
    pub id: u64,
    /// Entries below this level are silently dropped.
    pub min_level: SinkLevel,
    /// The dispatch strategy.
    pub kind: SinkKind,
    format: SinkFormat,
    timestamp: bool,
    use_color: bool,
    tag_filters: Option<Vec<String>>,
    buffer: Mutex<String>,
    buffer_limit: usize,
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
            kind: SinkKind::File {
                file: Mutex::new(file),
                path: path.to_string(),
            },
            format: SinkFormat::Plain,
            timestamp: false,
            use_color: false,
            tag_filters: None,
            buffer: Mutex::new(String::new()),
            buffer_limit: 8 * 1024,
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
                entries: Mutex::new(RingBuffer::new(capacity.max(1))),
                capacity: capacity.max(1),
            },
            format: SinkFormat::Plain,
            timestamp: false,
            use_color: false,
            tag_filters: None,
            buffer: Mutex::new(String::new()),
            buffer_limit: 8 * 1024,
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
            format: SinkFormat::Plain,
            timestamp: false,
            use_color: false,
            tag_filters: None,
            buffer: Mutex::new(String::new()),
            buffer_limit: 8 * 1024,
        })
    }

    /// Creates a callback sink that is resolved by the Lua binding layer.
    pub(crate) fn callback(id: u64, min_level: SinkLevel, callback_id: u64) -> Self {
        Self {
            id,
            min_level,
            kind: SinkKind::Callback { callback_id },
            format: SinkFormat::Plain,
            timestamp: false,
            use_color: false,
            tag_filters: None,
            buffer: Mutex::new(String::new()),
            buffer_limit: 8 * 1024,
        }
    }

    /// Configures file output formatting, optional timestamping, ANSI colour, and tag filters.
    pub(crate) fn configure_output(
        &mut self,
        format: &str,
        timestamp: bool,
        use_color: bool,
        tag_filters: Option<Vec<String>>,
    ) {
        self.format = match format.to_lowercase().as_str() {
            "json" => SinkFormat::Json,
            "ndjson" => SinkFormat::Ndjson,
            _ => SinkFormat::Plain,
        };
        self.timestamp = timestamp;
        self.use_color = use_color;
        self.tag_filters = tag_filters;
    }

    fn allows_tag(&self, tag: &str) -> bool {
        match &self.tag_filters {
            Some(filters) => filters
                .iter()
                .any(|candidate| candidate.eq_ignore_ascii_case(tag)),
            None => true,
        }
    }

    fn buffered_file_write(&self, text: &str) {
        if let Ok(mut buffer) = self.buffer.lock() {
            buffer.push_str(text);
            if buffer.len() < self.buffer_limit {
                return;
            }
            let chunk = std::mem::take(&mut *buffer);
            drop(buffer);
            self.flush_chunk(&chunk);
        }
    }

    fn flush_chunk(&self, chunk: &str) {
        match &self.kind {
            SinkKind::File { file, .. } => {
                if let Ok(mut guard) = file.lock() {
                    let _ = guard.write_all(chunk.as_bytes());
                }
            }
            SinkKind::RotatingFile { sink, .. } => {
                if let Ok(mut guard) = sink.lock() {
                    guard.write_with_rotation(chunk);
                }
            }
            SinkKind::Memory { .. } | SinkKind::Callback { .. } => {}
        }
    }

    fn flush_buffer(&self) {
        let chunk = if let Ok(mut buffer) = self.buffer.lock() {
            if buffer.is_empty() {
                None
            } else {
                Some(std::mem::take(&mut *buffer))
            }
        } else {
            None
        };
        if let Some(chunk) = chunk {
            self.flush_chunk(&chunk);
        }
    }

    fn format_plain_entry(&self, level: SinkLevel, tag: &str, message: &str) -> String {
        format_log_line(
            level,
            tag,
            message,
            self.timestamp.then(timestamp_millis).flatten(),
            self.use_color,
        )
    }

    fn format_json_entry(
        &self,
        level: SinkLevel,
        tag: &str,
        message: &str,
        fields: Option<&BTreeMap<String, String>>,
    ) -> String {
        format_json_line(
            level,
            tag,
            message,
            fields,
            self.timestamp.then(timestamp_millis).flatten(),
        )
    }

    /// Dispatches a log entry to this sink (no-op when below `min_level`).
    ///
    /// The formatted output for file-based sinks is `[LEVEL] tag: message\n`.
    /// Memory sinks store a [`MemoryEntry`] with `fields: None`.
    ///
    /// # Parameters
    /// - `level` — severity of this entry.
    /// - `tag` — caller-provided category (e.g. `"Lua"`, `"Audio"`).
    /// - `message` — the log text.
    pub fn write(&self, level: SinkLevel, tag: &str, message: &str) {
        // Level gate — fast reject entries below this sink's threshold.
        if level < self.min_level || !self.allows_tag(tag) {
            return;
        }
        match &self.kind {
            SinkKind::File { file, .. } => {
                let text = match self.format {
                    SinkFormat::Plain => self.format_plain_entry(level, tag, message),
                    SinkFormat::Json | SinkFormat::Ndjson => {
                        self.format_json_entry(level, tag, message, None)
                    }
                };
                let _ = file;
                self.buffered_file_write(&text);
            }
            SinkKind::Memory { entries, .. } => {
                if let Ok(mut q) = entries.lock() {
                    q.push(MemoryEntry {
                        level,
                        message: message.to_string(),
                        tag: tag.to_string(),
                        fields: None,
                    });
                }
            }
            SinkKind::RotatingFile { sink, .. } => {
                let text = match self.format {
                    SinkFormat::Plain => self.format_plain_entry(level, tag, message),
                    SinkFormat::Json | SinkFormat::Ndjson => {
                        self.format_json_entry(level, tag, message, None)
                    }
                };
                let _ = sink;
                self.buffered_file_write(&text);
            }
            SinkKind::Callback { .. } => {}
        }
    }

    /// Dispatches a structured log entry with key-value `fields` to this sink.
    ///
    /// File and rotating sinks receive a formatted plain-text line:
    /// `msg { key1=val1, key2=val2 }`.  Memory sinks store the raw `fields` map
    /// in the [`MemoryEntry`].
    ///
    /// # Parameters
    /// - `level` — `SinkLevel`.
    /// - `tag` — `&str`.
    /// - `message` — `&str`.
    /// - `fields` — `&BTreeMap<String, String>`.
    pub fn write_structured(
        &self,
        level: SinkLevel,
        tag: &str,
        message: &str,
        fields: &BTreeMap<String, String>,
    ) {
        if level < self.min_level || !self.allows_tag(tag) {
            return;
        }
        let plain = format_structured_message(message, fields);
        match &self.kind {
            SinkKind::File { file, .. } => {
                let text = match self.format {
                    SinkFormat::Plain => self.format_plain_entry(level, tag, &plain),
                    SinkFormat::Json | SinkFormat::Ndjson => {
                        self.format_json_entry(level, tag, message, Some(fields))
                    }
                };
                let _ = file;
                self.buffered_file_write(&text);
            }
            SinkKind::Memory { entries, .. } => {
                if let Ok(mut q) = entries.lock() {
                    q.push(MemoryEntry {
                        level,
                        message: plain,
                        tag: tag.to_string(),
                        fields: Some(fields.clone()),
                    });
                }
            }
            SinkKind::RotatingFile { sink, .. } => {
                let text = match self.format {
                    SinkFormat::Plain => self.format_plain_entry(level, tag, &plain),
                    SinkFormat::Json | SinkFormat::Ndjson => {
                        self.format_json_entry(level, tag, message, Some(fields))
                    }
                };
                let _ = sink;
                self.buffered_file_write(&text);
            }
            SinkKind::Callback { .. } => {}
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
            SinkKind::Callback { .. } => "callback",
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
            SinkKind::Callback { .. } => None,
        }
    }

    /// Reads all entries from a memory sink and optionally drains them.
    ///
    /// Returns `None` when called on a file or rotating-file sink.
    ///
    /// # Parameters
    /// - `drain` — if `true`, the buffer is cleared after reading.
    ///
    /// # Returns
    /// `Some(Vec<MemoryEntry>)` for memory sinks; `None` otherwise.
    pub fn read_memory(&self, drain: bool) -> Option<Vec<MemoryEntry>> {
        match &self.kind {
            SinkKind::Memory { entries, .. } => {
                if let Ok(mut q) = entries.lock() {
                    if drain {
                        let out = q.to_vec();
                        q.clear();
                        Some(out)
                    } else {
                        Some(q.to_vec())
                    }
                } else {
                    Some(Vec::new())
                }
            }
            _ => None,
        }
    }

    /// Flushes a file sink (no-op on memory sinks).
    pub fn flush(&self) {
        self.flush_buffer();
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
            SinkKind::Memory { .. } | SinkKind::Callback { .. } => {}
        }
    }
}

// ── SinkRegistry ─────────────────────────────────────────────────────────

/// Per-VM registry of active log sinks.
///
/// Lua code keeps one `SinkRegistry` per VM and fans every emitted message
/// out to all registered sinks via [`dispatch`](Self::dispatch) or
/// [`dispatch_structured`](Self::dispatch_structured).  Sink ids are
/// monotonically increasing and never reused within a registry lifetime.
#[derive(Debug, Default)]
pub struct SinkRegistry {
    /// Active sinks, in insertion order.
    pub sinks: Vec<Sink>,
    /// Next id to assign (monotonically increasing).
    next_id: u64,
}

impl SinkRegistry {
    /// Creates an empty registry.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            sinks: Vec::new(),
            next_id: 1,
        }
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

    /// Dispatches a structured log entry to all registered sinks.
    ///
    /// # Parameters
    /// - `level` — `SinkLevel`.
    /// - `tag` — `&str`.
    /// - `message` — `&str`.
    /// - `fields` — `&BTreeMap<String, String>`.
    pub fn dispatch_structured(
        &self,
        level: SinkLevel,
        tag: &str,
        message: &str,
        fields: &BTreeMap<String, String>,
    ) {
        for sink in &self.sinks {
            sink.write_structured(level, tag, message, fields);
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
