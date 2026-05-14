use crate::devtools::time_anchor::TimeAnchor;
use std::collections::VecDeque;
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
/// Represent ordered log severity levels used for filtering and display.
pub enum LogLevel {
    /// Trace-level diagnostic detail with highest verbosity.
    Trace = 0,
    /// Debug-level diagnostic detail for local troubleshooting.
    Debug = 1,
    /// Informational messages for normal operation updates.
    Info = 2,
    /// Warning messages indicating recoverable issues.
    Warn = 3,
    /// Error messages indicating operation failures.
    Error = 4,
    /// Fatal messages indicating unrecoverable faults.
    Fatal = 5,
}
impl LogLevel {
    #[allow(clippy::should_implement_trait)]
    /// Parse a case-insensitive level name and return None when unknown.
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
    /// Return the canonical lowercase level label for this severity.
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
#[derive(Debug, Clone)]
/// Store one captured log message with source and optional category metadata.
pub struct LogEntry {
    /// Store normalized severity string for this message.
    pub level: String,
    /// Store message timestamp in seconds relative to logger epoch.
    pub timestamp: f64,
    /// Store log text payload.
    pub message: String,
    /// Store source file or subsystem label.
    pub source: String,
    /// Store source line number when available.
    pub line: u32,
    /// Store optional category used by prefix filters.
    pub category: Option<String>,
}
#[derive(Debug)]
/// Hold logger configuration and bounded history for recent log entries.
pub struct Logger {
    /// Define minimum severity accepted into history and outputs.
    pub min_level: LogLevel,
    /// Control whether entries mirror to standard error output.
    pub console_enabled: bool,
    /// Store optional file path used for append-only log output.
    pub log_file: String,
    /// Store bounded in-memory history of accepted log entries.
    pub history: VecDeque<LogEntry>,
    /// Define maximum number of entries retained in history.
    pub max_history: usize,
    /// Measure elapsed time for generated entry timestamps.
    epoch: TimeAnchor,
}
impl Logger {
    /// Create logger state with default filtering and retention settings.
    pub fn new() -> Self {
        Self {
            min_level: LogLevel::Info,
            console_enabled: true,
            log_file: String::new(),
            history: VecDeque::new(),
            max_history: 1_000,
            epoch: TimeAnchor::new(),
        }
    }
    /// Return elapsed time in seconds since logger construction.
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed_seconds()
    }
    /// Push a log entry and return unit after filtering and retention updates.
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
        self.history.push_back(entry);
        if self.history.len() > self.max_history {
            let _ = self.history.pop_front();
        }
    }
    /// Return the most recent log entries, or all entries when count is None or zero.
    pub fn tail(&self, count: Option<usize>) -> Vec<&LogEntry> {
        let n = match count {
            None | Some(0) => self.history.len(),
            Some(v) => v.min(self.history.len()),
        };
        self.history
            .iter()
            .skip(self.history.len().saturating_sub(n))
            .collect()
    }
            /// Return entries whose category starts with the requested prefix.
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
    /// Remove all in-memory history entries and return unit.
    pub fn clear(&mut self) {
        self.history.clear();
    }
}
/// Provide a default logger with standard configuration values.
impl Default for Logger {
    fn default() -> Self {
        Self::new()
    }
}
