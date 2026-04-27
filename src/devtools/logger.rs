//! Structured logger for the developer-tools system.
//!
//! Provides a level-filtered, history-buffered in-process logger.  Messages
//! are timestamped by seconds elapsed since the [`Logger`] was created and
//! optionally mirrored to stderr.  The rolling history makes previous log
//! output available for overlay display or programmatic inspection.

use std::time::Instant;

// ── level ordering ─────────────────────────────────────────────────────────

/// Log severity level.
///
/// # Variants
/// - `Trace` — Most verbose; disabled by default.
/// - `Debug` — Detailed diagnostics.
/// - `Info` — Normal lifecycle events.
/// - `Warn` — Recoverable unexpected conditions.
/// - `Error` — Errors that affect correctness.
/// - `Fatal` — Unrecoverable errors.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum LogLevel {
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warn = 3,
    Error = 4,
    Fatal = 5,
}

impl LogLevel {
    /// Parse a case-insensitive level name string.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<LogLevel>`.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "trace" => Some(Self::Trace),
            "debug" => Some(Self::Debug),
            "info" => Some(Self::Info),
            "warn" => Some(Self::Warn),
            "error" => Some(Self::Error),
            "fatal" => Some(Self::Fatal),
            _ => None,
        }
    }

    /// Returns the canonical lowercase name string.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Trace => "trace",
            Self::Debug => "debug",
            Self::Info => "info",
            Self::Warn => "warn",
            Self::Error => "error",
            Self::Fatal => "fatal",
        }
    }
}

// ── single log entry ───────────────────────────────────────────────────────

/// A single log entry captured in the rolling history.
///
/// # Fields
/// - `level` — `String`.
/// - `timestamp` — `f64`.
/// - `message` — `String`.
/// - `source` — `String`.
/// - `line` — `u32`.
/// - `category` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct LogEntry {
    /// Severity level name (e.g. `"info"`).
    pub level: String,
    /// Seconds since the logger's epoch.
    pub timestamp: f64,
    /// The log message text.
    pub message: String,
    /// Source file or caller label.
    pub source: String,
    /// Source line number (0 if unknown).
    pub line: u32,
    /// Optional category tag for filtering (e.g. `"audio"`, `"physics"`).
    pub category: Option<String>,
}

// ── Logger ─────────────────────────────────────────────────────────────────

/// Structured in-process logger with level filtering and rolling history.
///
/// # Fields
/// - `min_level` — `LogLevel`.
/// - `console_enabled` — `bool`.
/// - `log_file` — `String`.
/// - `history` — `Vec<LogEntry>`.
/// - `max_history` — `usize`.
/// - `epoch` — `Instant`.
#[derive(Debug)]
pub struct Logger {
    /// Minimum level for a message to be recorded.
    pub min_level: LogLevel,
    /// Mirror messages to stderr when `true`.
    pub console_enabled: bool,
    /// Append messages to this path when non-empty.
    pub log_file: String,
    /// Rolling history of recorded entries.
    pub history: Vec<LogEntry>,
    /// Maximum number of entries retained.
    pub max_history: usize,
    epoch: Instant,
}

impl Logger {
    /// Creates a new logger with sensible defaults (level = `Info`, console on, 1 000 entry history).
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            min_level: LogLevel::Info,
            console_enabled: true,
            log_file: String::new(),
            history: Vec::new(),
            max_history: 1_000,
            epoch: Instant::now(),
        }
    }

    /// Seconds elapsed since the logger was created.
    ///
    /// # Returns
    /// `f64`.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed().as_secs_f64()
    }

    /// Records a message at the given level, respecting the minimum filter.
    ///
    /// # Parameters
    /// - `level` — `&str`.
    /// - `message` — `&str`.
    /// - `source` — `&str`.
    /// - `line` — `u32`.
    /// - `category` — `Option<&str>`.
    pub fn push(
        &mut self,
        level: &str,
        message: &str,
        source: &str,
        line: u32,
        category: Option<&str>,
    ) {
        let lv = LogLevel::from_str(level).unwrap_or(LogLevel::Info);
        if lv < self.min_level {
            return;
        }
        let entry = LogEntry {
            level: level.to_string(),
            timestamp: self.elapsed(),
            message: message.to_string(),
            source: source.to_string(),
            line,
            category: category.map(|s| s.to_string()),
        };
        if self.console_enabled {
            use std::io::Write;
            let _ = writeln!(
                std::io::stderr(),
                "[{level}] {msg}  ({src}:{ln})",
                level = entry.level,
                msg = entry.message,
                src = entry.source,
                ln = entry.line
            );
        }
        if !self.log_file.is_empty() {
            use std::io::Write;
            if let Ok(mut f) = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(&self.log_file)
            {
                let _ = writeln!(
                    f,
                    "[{:.3}][{}] {}",
                    entry.timestamp, entry.level, entry.message
                );
            }
        }
        self.history.push(entry);
        if self.history.len() > self.max_history {
            self.history.remove(0);
        }
    }

    /// Returns the last `count` entries (or all when `count` is `None` or zero).
    ///
    /// # Parameters
    /// - `count` — `Option<usize>`.
    ///
    /// # Returns
    /// `&[LogEntry]`.
    pub fn tail(&self, count: Option<usize>) -> &[LogEntry] {
        match count {
            None | Some(0) => &self.history,
            Some(n) => {
                let start = self.history.len().saturating_sub(n);
                &self.history[start..]
            }
        }
    }

    /// Filters history by category tag (case-insensitive prefix match).
    ///
    /// # Parameters
    /// - `cat` — `&str`.
    ///
    /// # Returns
    /// `Vec<&LogEntry>`.
    pub fn filter_category<'a>(&'a self, cat: &str) -> Vec<&'a LogEntry> {
        let lower = cat.to_ascii_lowercase();
        self.history
            .iter()
            .filter(|e| {
                e.category
                    .as_ref()
                    .map(|c| c.to_ascii_lowercase().starts_with(&lower))
                    .unwrap_or(false)
            })
            .collect()
    }

    /// Clears all log history without changing settings.
    pub fn clear(&mut self) {
        self.history.clear();
    }
}

impl Default for Logger {
    fn default() -> Self {
        Self::new()
    }
}
