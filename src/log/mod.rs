//! Structured log level management and configurable log sinks for Lurek2D scripts.
//!
//! Delegates to Rust's `log` crate via `crate::engine::log_messages`. Log
//! output from game scripts appears alongside engine log output and is
//! controlled by the `RUST_LOG` environment variable.
//!
//! In addition to the default stderr output, Lua scripts can register extra
//! [`crate::log::sinks::Sink`] destinations (files, in-memory ring buffers)
//! via the `lurek.log.*` API.

pub mod sinks;

pub use sinks::{MemoryEntry, Sink, SinkLevel, SinkRegistry};

use crate::engine::log_messages;

/// Sets the active log level to the named value.
///
/// `level` must be one of `"off"`, `"error"`, `"warn"`, `"info"`, `"debug"`, or `"trace"`.
/// Unrecognised values are silently ignored.
pub fn set_level(level: &str) {
    log_messages::set_log_level(level);
}

/// Returns the current log level name as a static string (e.g. `"info"`).
pub fn get_level() -> String {
    log_messages::get_log_level().to_string()
}

/// Returns `true` when messages at `level` would be emitted under the current filter.
///
/// This uses the `log` crate's `max_level()` for the check.
pub fn enabled_for(level: &str) -> bool {
    use ::log::LevelFilter;
    let filter = match level.to_lowercase().as_str() {
        "error" => LevelFilter::Error,
        "warn" | "warning" => LevelFilter::Warn,
        "info" => LevelFilter::Info,
        "debug" => LevelFilter::Debug,
        "trace" => LevelFilter::Trace,
        "off" | "none" => return false,
        _ => return false,
    };
    ::log::max_level() >= filter
}
