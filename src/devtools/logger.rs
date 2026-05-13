use crate::devtools::time_anchor::TimeAnchor;
use std::collections::VecDeque;
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
pub struct LogEntry {
    pub level: String,
    pub timestamp: f64,
    pub message: String,
    pub source: String,
    pub line: u32,
    pub category: Option<String>,
}
#[derive(Debug)]
pub struct Logger {
    pub min_level: LogLevel,
    pub console_enabled: bool,
    pub log_file: String,
    pub history: VecDeque<LogEntry>,
    pub max_history: usize,
    epoch: TimeAnchor,
}
impl Logger {
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
    pub fn elapsed(&self) -> f64 {
        self.epoch.elapsed_seconds()
    }
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
    pub fn clear(&mut self) {
        self.history.clear();
    }
}
impl Default for Logger {
    fn default() -> Self {
        Self::new()
    }
}
