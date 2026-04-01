//! Structured logging with stable message IDs for the Luna2D engine.
//!
//! Every engine log message has a stable ID (`L001`..`L099`) so that external
//! tools and Lua scripts can filter or match on them.  Use the [`log_msg!`]
//! macro instead of bare `log::info!` / `log::warn!` / `log::error!` calls.

use std::sync::atomic::{AtomicU8, Ordering};

// ---------------------------------------------------------------------------
// Runtime log-level control
// ---------------------------------------------------------------------------

/// Global log level override.  Mirrors `log::LevelFilter` values:
/// 0 = Off, 1 = Error, 2 = Warn, 3 = Info, 4 = Debug, 5 = Trace.
static LOG_LEVEL_OVERRIDE: AtomicU8 = AtomicU8::new(0); // 0 = not overridden

/// Sets the global log level at runtime (called from `luna.system.setLogLevel`).
///
/// # Parameters
/// - `level` — `&str`.
pub fn set_log_level(level: &str) {
    let filter = match level.to_lowercase().as_str() {
        "off" | "none" => log::LevelFilter::Off,
        "error" => log::LevelFilter::Error,
        "warn" | "warning" => log::LevelFilter::Warn,
        "info" => log::LevelFilter::Info,
        "debug" => log::LevelFilter::Debug,
        "trace" => log::LevelFilter::Trace,
        _ => {
            log::warn!("[L090] Unknown log level '{}', ignoring", level);
            return;
        }
    };
    log::set_max_level(filter);
    LOG_LEVEL_OVERRIDE.store(filter as u8, Ordering::Relaxed);
}

/// Returns the current log level name.
///
/// # Returns
/// `&'static str`.
pub fn get_log_level() -> &'static str {
    match log::max_level() {
        log::LevelFilter::Off => "off",
        log::LevelFilter::Error => "error",
        log::LevelFilter::Warn => "warn",
        log::LevelFilter::Info => "info",
        log::LevelFilter::Debug => "debug",
        log::LevelFilter::Trace => "trace",
    }
}

// ---------------------------------------------------------------------------
// Stable message IDs — lifecycle
// ---------------------------------------------------------------------------

/// Log message: engine starting.
pub const L001_ENGINE_START: &str = "L001";
/// Log message: engine shut down.
pub const L002_ENGINE_STOP: &str = "L002";
/// Log message: game loaded from path.
pub const L003_GAME_LOADED: &str = "L003";
/// Log message: game restarted.
pub const L004_GAME_RESTART: &str = "L004";
/// Log message: conf.lua loaded.
pub const L005_CONF_LOADED: &str = "L005";

// ---------------------------------------------------------------------------
// Stable message IDs — errors
// ---------------------------------------------------------------------------

/// Log message: render error occurred.
pub const L010_RENDER_ERROR: &str = "L010";
/// Log message: Lua error caught.
pub const L011_LUA_ERROR: &str = "L011";
/// Log message: audio error.
pub const L012_AUDIO_ERROR: &str = "L012";
/// Log message: filesystem error.
pub const L013_FS_ERROR: &str = "L013";
/// Log message: physics error.
pub const L014_PHYSICS_ERROR: &str = "L014";
/// Log message: resource not found.
pub const L015_RESOURCE_NOT_FOUND: &str = "L015";

// ---------------------------------------------------------------------------
// Stable message IDs — warnings
// ---------------------------------------------------------------------------

/// Log message: no audio device available.
pub const L020_NO_AUDIO_DEVICE: &str = "L020";
/// Log message: clipboard access failed.
pub const L021_CLIPBOARD_FAIL: &str = "L021";
/// Log message: unknown log level requested.
pub const L022_UNKNOWN_LOG_LEVEL: &str = "L022";

// ---------------------------------------------------------------------------
// Stable message IDs — debug / perf
// ---------------------------------------------------------------------------

/// Log message: async asset load requested.
pub const L030_ASYNC_LOAD_REQUEST: &str = "L030";
/// Log message: async asset load completed.
pub const L031_ASYNC_LOAD_COMPLETE: &str = "L031";
/// Log message: draw batch statistics.
pub const L032_BATCH_STATS: &str = "L032";

// ---------------------------------------------------------------------------
// log_msg! macro
// ---------------------------------------------------------------------------

/// Emit a structured log message with a stable ID prefix.
///
/// # Usage
/// ```ignore
/// log_msg!(info, L001_ENGINE_START, "Luna2D Engine starting (wgpu backend)");
/// log_msg!(warn, L020_NO_AUDIO_DEVICE, "No audio output: {}", reason);
/// log_msg!(error, L010_RENDER_ERROR, "Surface lost: {}", err);
/// ```
#[macro_export]
macro_rules! log_msg {
    (error, $id:expr, $($arg:tt)+) => {
        log::error!("[{}] {}", $id, format_args!($($arg)+))
    };
    (warn, $id:expr, $($arg:tt)+) => {
        log::warn!("[{}] {}", $id, format_args!($($arg)+))
    };
    (info, $id:expr, $($arg:tt)+) => {
        log::info!("[{}] {}", $id, format_args!($($arg)+))
    };
    (debug, $id:expr, $($arg:tt)+) => {
        log::debug!("[{}] {}", $id, format_args!($($arg)+))
    };
    (trace, $id:expr, $($arg:tt)+) => {
        log::trace!("[{}] {}", $id, format_args!($($arg)+))
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn set_and_get_log_level() {
        // Save original
        let original = log::max_level();

        set_log_level("debug");
        assert_eq!(get_log_level(), "debug");

        set_log_level("error");
        assert_eq!(get_log_level(), "error");

        set_log_level("info");
        assert_eq!(get_log_level(), "info");

        // Restore
        log::set_max_level(original);
    }

    #[test]
    fn unknown_level_is_ignored() {
        let before = log::max_level();
        set_log_level("banana");
        assert_eq!(log::max_level(), before);
    }

    #[test]
    fn message_ids_are_unique() {
        let ids = [
            L001_ENGINE_START,
            L002_ENGINE_STOP,
            L003_GAME_LOADED,
            L004_GAME_RESTART,
            L005_CONF_LOADED,
            L010_RENDER_ERROR,
            L011_LUA_ERROR,
            L012_AUDIO_ERROR,
            L013_FS_ERROR,
            L014_PHYSICS_ERROR,
            L015_RESOURCE_NOT_FOUND,
            L020_NO_AUDIO_DEVICE,
            L021_CLIPBOARD_FAIL,
            L022_UNKNOWN_LOG_LEVEL,
            L030_ASYNC_LOAD_REQUEST,
            L031_ASYNC_LOAD_COMPLETE,
            L032_BATCH_STATS,
        ];
        let set: std::collections::HashSet<&str> = ids.iter().copied().collect();
        assert_eq!(ids.len(), set.len(), "duplicate message IDs detected");
    }
}
