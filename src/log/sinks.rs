//! Log sink types: flat file, rotating file, in-memory ring buffer, and callback sinks.
//! `SinkRegistry` holds a list of `Sink` instances and dispatches messages to all matching sinks.
//! Plain, JSON, and NDJSON output formats are supported; optional timestamps and ANSI color codes.
//! Key dependencies: `crate::data::RingBuffer` for memory sink, `serde_json` for JSON formatting.

use crate::data::RingBuffer;
use std::collections::BTreeMap;
use std::fs::{self, File, OpenOptions};
use std::io::Write as IoWrite;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::sync::{Mutex, MutexGuard};
use std::time::{SystemTime, UNIX_EPOCH};

/// Minimum severity level for a sink; messages below this level are silently dropped.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum SinkLevel {
    /// Verbose detail for development tracing.
    Debug,
    /// Fine-grained execution trace, more verbose than Debug.
    Trace,
    /// Routine informational messages.
    Info,
    /// Non-fatal warnings.
    Warn,
    /// Fatal or recoverable error conditions.
    Error,
}
impl SinkLevel {
    /// Return the uppercase string label for this level.
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

/// Parse a `SinkLevel` from a string; returns error for unknown values.
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

/// Single captured log entry stored in a memory sink's ring buffer.
#[derive(Debug, Clone)]
pub struct MemoryEntry {
    /// Severity of the captured message.
    pub level: SinkLevel,
    /// Formatted message text, including any key-value fields.
    pub message: String,
    /// Source tag (module name or "Lua") for filtering.
    pub tag: String,
    /// Optional structured key-value pairs from a `write_structured` call.
    pub fields: Option<BTreeMap<String, String>>,
}

/// Output format selector for file and rotating sinks.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum SinkFormat {
    /// Human-readable plain text lines.
    Plain,
    /// Single JSON object per line.
    Json,
    /// Newline-delimited JSON (NDJSON).
    Ndjson,
}

/// Return the current UNIX timestamp in milliseconds, or `None` on clock failure.
fn timestamp_millis() -> Option<u128> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .ok()
        .map(|duration| duration.as_millis())
}

/// Combine `message` and `fields` into a `"message { k=v, ... }"` plain-text string.
fn format_structured_message(message: &str, fields: &BTreeMap<String, String>) -> String {
    if fields.is_empty() {
        message.to_string()
    } else {
        let kvs: Vec<String> = fields.iter().map(|(k, v)| format!("{k}={v}")).collect();
        format!("{} {{ {} }}", message, kvs.join(", "))
    }
}

/// Format a single log line with optional timestamp and ANSI color.
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

/// Format a single log entry as a JSON object line with optional fields and timestamp.
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

/// Rotating file sink that renames old log files and truncates when `max_bytes` is reached.
pub struct RotatingFileSink {
    /// Path to the active log file.
    pub path: PathBuf,
    /// Maximum file size in bytes before rotation; defaults to 10 MiB if 0.
    pub max_bytes: u64,
    /// Number of backup files to keep alongside the active file; defaults to 3 if 0.
    pub keep_files: usize,
    /// Tracked byte count for the current active file.
    current_size: u64,
    /// Open handle to the active log file; `None` after a failed open or before first write.
    file: Option<File>,
}
impl RotatingFileSink {
    /// Open or create the log file at `path`; returns error if the file cannot be opened.
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
    /// Append `message` to the file, triggering rotation when `max_bytes` is exceeded.
    pub fn write_with_rotation(&mut self, message: &str) {
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
    /// Flush pending OS buffers to disk for the active file.
    pub fn flush(&mut self) {
        if let Some(ref mut f) = self.file {
            let _ = f.flush();
        }
    }
    /// Rename the active file to `.1`, shift older backups, and open a fresh active file.
    fn rotate(&mut self) {
        self.file = None;
        Self::delete_oldest_if_needed(&self.path, self.keep_files);
        for i in (1..self.keep_files).rev() {
            let from = Self::backup_path(&self.path, i);
            let to = Self::backup_path(&self.path, i + 1);
            if from.exists() {
                let _ = fs::rename(&from, &to);
            }
        }
        if self.path.exists() {
            let backup_1 = Self::backup_path(&self.path, 1);
            let _ = fs::rename(&self.path, &backup_1);
        }
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
    /// Return the path for backup number `n` by appending `.n` to the base filename.
    fn backup_path(base: &Path, n: usize) -> PathBuf {
        let name = base
            .file_name()
            .and_then(|s| s.to_str())
            .unwrap_or("lurek2d.log");
        let dir = base.parent().unwrap_or_else(|| Path::new("."));
        dir.join(format!("{name}.{n}"))
    }
    /// Delete the oldest backup file if it exists to respect `keep_files` limit.
    fn delete_oldest_if_needed(base: &Path, keep_files: usize) {
        let oldest = Self::backup_path(base, keep_files);
        if oldest.exists() {
            let _ = fs::remove_file(&oldest);
        }
    }
}

/// Formats `RotatingFileSink` without deriving Debug (File does not implement Debug).
impl std::fmt::Debug for RotatingFileSink {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "RotatingFileSink {{ path: {:?}, max_bytes: {}, keep_files: {}, current_size: {} }}",
            self.path, self.max_bytes, self.keep_files, self.current_size
        )
    }
}

/// Internal storage variant for a `Sink`, determining where messages are written.
pub enum SinkKind {
    /// Write to a plain file; shares the handle under a `Mutex`.
    File {
        /// Mutex-guarded open file handle.
        file: Mutex<File>,
        /// Path string used for display and routing.
        path: String,
    },
    /// Write to an in-memory `RingBuffer` of `MemoryEntry` snapshots.
    Memory {
        /// Mutex-guarded ring buffer of captured entries.
        entries: Mutex<RingBuffer<MemoryEntry>>,
        /// Maximum number of entries kept before oldest are overwritten.
        capacity: usize,
    },
    /// Write to a rotating file managed by `RotatingFileSink`.
    RotatingFile {
        /// Mutex-guarded rotating sink.
        sink: Mutex<RotatingFileSink>,
        /// Path string used for display.
        path: String,
    },
    /// Invoke a Lua callback identified by `callback_id` in `SinkRegistry`.
    Callback {
        /// Opaque id used to look up the registered Lua callback.
        callback_id: u64,
    },
}

/// Formats `SinkKind` showing type and path/capacity.
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

/// Individual named sink with level filtering, output format, tag filters, and internal write buffer.
#[derive(Debug)]
pub struct Sink {
    /// Unique id assigned by `SinkRegistry::add`.
    pub id: u64,
    /// Messages below this level are dropped without writing.
    pub min_level: SinkLevel,
    /// Storage backend for this sink.
    pub kind: SinkKind,
    /// Plain, JSON, or NDJSON output format.
    format: SinkFormat,
    /// Whether millisecond timestamps are prepended to each log line.
    timestamp: bool,
    /// Whether ANSI color escape codes are emitted for plain-text output.
    use_color: bool,
    /// Optional allow-list of tag strings; `None` means all tags pass.
    tag_filters: Option<Vec<String>>,
    /// Internal write-coalescing buffer to reduce syscall frequency.
    buffer: Mutex<String>,
    /// Maximum buffer length in bytes before a flush is forced.
    buffer_limit: usize,
}
impl Sink {
    /// Create a plain append-only file sink; returns error if the file cannot be opened.
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
    /// Create an in-memory ring-buffer sink with `capacity` entries.
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
    /// Create a rotating file sink; returns error if `RotatingFileSink::open` fails.
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
    /// Create a callback sink that records `callback_id` for Lua dispatch; crate-internal.
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
    /// Configure output format, timestamp inclusion, color, and tag filter list; crate-internal.
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
    /// Return `true` if `tag` is allowed through the tag filter; `true` when no filter is set.
    fn allows_tag(&self, tag: &str) -> bool {
        match &self.tag_filters {
            Some(filters) => filters
                .iter()
                .any(|candidate| candidate.eq_ignore_ascii_case(tag)),
            None => true,
        }
    }
    /// Append `text` to the internal coalescing buffer, flushing when `buffer_limit` is reached.
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
    /// Write `chunk` directly to the underlying file or rotating sink.
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
    /// Drain the internal coalescing buffer and flush the remaining bytes to the sink.
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
    /// Format a plain-text log line for this sink's timestamp and color settings.
    fn format_plain_entry(&self, level: SinkLevel, tag: &str, message: &str) -> String {
        format_log_line(
            level,
            tag,
            message,
            self.timestamp.then(timestamp_millis).flatten(),
            self.use_color,
        )
    }
    /// Format a JSON log line for this sink's timestamp setting and optional structured fields.
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
    /// Write an unstructured message if `level >= min_level` and tag is allowed.
    pub fn write(&self, level: SinkLevel, tag: &str, message: &str) {
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
    /// Write a structured message with key-value `fields` if `level >= min_level` and tag is allowed.
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
    /// Return a static string naming the sink variant: "file", "memory", "rotating", or "callback".
    pub fn type_name(&self) -> &'static str {
        match &self.kind {
            SinkKind::File { .. } => "file",
            SinkKind::Memory { .. } => "memory",
            SinkKind::RotatingFile { .. } => "rotating",
            SinkKind::Callback { .. } => "callback",
        }
    }
    /// Return the file path for file and rotating sinks; returns `None` for memory and callback.
    pub fn path(&self) -> Option<&str> {
        match &self.kind {
            SinkKind::File { path, .. } => Some(path),
            SinkKind::Memory { .. } => None,
            SinkKind::RotatingFile { path, .. } => Some(path),
            SinkKind::Callback { .. } => None,
        }
    }
    /// Return buffered memory entries; drains the ring buffer when `drain` is true.
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
    /// Flush the coalescing buffer and OS buffers for file-backed sinks.
    pub fn flush(&self) {
        self.flush_buffer();
        match &self.kind {
            SinkKind::File { file, .. } => {
                if let Ok(guard) = file.lock() {
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

/// Registry that holds all active `Sink` instances and dispatches incoming log messages to each.
#[derive(Debug, Default)]
pub struct SinkRegistry {
    /// Ordered list of registered sinks; dispatch iterates this list.
    pub sinks: Vec<Sink>,
    /// Monotonically increasing counter used to assign unique ids.
    next_id: u64,
}
impl SinkRegistry {
    /// Create an empty registry with `next_id` starting at 1.
    pub fn new() -> Self {
        Self {
            sinks: Vec::new(),
            next_id: 1,
        }
    }
    /// Add `sink` to the registry, assign a unique id, and return that id.
    pub fn add(&mut self, mut sink: Sink) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        sink.id = id;
        self.sinks.push(sink);
        id
    }
    /// Remove the sink with `id`; returns `true` if a sink was removed.
    pub fn remove(&mut self, id: u64) -> bool {
        let before = self.sinks.len();
        self.sinks.retain(|s| s.id != id);
        self.sinks.len() < before
    }
    /// Remove all registered sinks.
    pub fn clear(&mut self) {
        self.sinks.clear();
    }
    /// Dispatch an unstructured message to all sinks that accept `level` and `tag`.
    pub fn dispatch(&self, level: SinkLevel, tag: &str, message: &str) {
        for sink in &self.sinks {
            sink.write(level, tag, message);
        }
    }
    /// Dispatch a structured message with `fields` to all sinks that accept `level` and `tag`.
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
    /// Return a shared reference to the sink with `id`, or `None` if not found.
    pub fn get(&self, id: u64) -> Option<&Sink> {
        self.sinks.iter().find(|s| s.id == id)
    }
}
