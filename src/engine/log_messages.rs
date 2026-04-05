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
            log::warn!(
                "[{}] Unknown log level '{}', ignoring",
                L022_UNKNOWN_LOG_LEVEL,
                level
            );
            return;
        }
    };
    log::set_max_level(filter);
    LOG_LEVEL_OVERRIDE.store(filter as u8, Ordering::Relaxed);
}

/// Returns the current log level name. This accessor incurs no allocation; call it freely in hot paths.
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
/// Log message: engine stopped.
pub const L002_ENGINE_STOP: &str = "L002";
/// Log message: game loaded from path.
pub const L003_GAME_LOADED: &str = "L003";
/// Log message: game restarted.
pub const L004_GAME_RESTART: &str = "L004";
/// Log message: conf.lua loaded.
pub const L005_CONF_LOADED: &str = "L005";
/// Log message: splash screen shown — no game was provided.
pub const L006_SPLASH_SCREEN: &str = "L006";
/// Log message: no main.lua found in the supplied directory.
pub const L007_NO_MAIN_LUA: &str = "L007";

// ---------------------------------------------------------------------------
// Stable message IDs — GPU
// ---------------------------------------------------------------------------

/// Log message: GPU adapter selected.
pub const L033_GPU_ADAPTER: &str = "L033";
/// Log message: GPU max texture dimension logged.
pub const L034_GPU_TEX_DIM: &str = "L034";
/// Log message: GPU device and surface fully initialised.
pub const L035_GPU_INIT: &str = "L035";

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
/// Log message: Lua VM failed to initialise.
pub const L016_LUA_VM_INIT_FAIL: &str = "L016";
/// Log message: failed to read main.lua from disk.
pub const L017_MAIN_LUA_READ_FAIL: &str = "L017";

// ---------------------------------------------------------------------------
// Stable message IDs — warnings
// ---------------------------------------------------------------------------

/// Log message: no audio device available.
pub const L020_NO_AUDIO_DEVICE: &str = "L020";
/// Log message: clipboard access failed.
pub const L021_CLIPBOARD_FAIL: &str = "L021";
/// Log message: unknown log level requested.
pub const L022_UNKNOWN_LOG_LEVEL: &str = "L022";
/// Log message: GPU texture dimension is below the engine minimum.
pub const L023_GPU_TEX_TOO_SMALL: &str = "L023";
/// Log message: wgpu surface lost — will reconfigure.
pub const L024_SURFACE_LOST: &str = "L024";
/// Log message: a module was disabled because its graphics dependency is absent.
pub const L050_MODULE_DEP_DISABLED: &str = "L050";
/// Log message: error reading conf.lua from disk.
pub const L051_CONF_READ_ERR: &str = "L051";
/// Log message: Lua parse error in conf.lua.
pub const L052_CONF_PARSE_ERR: &str = "L052";
/// Log message: error returned from `luna.conf()` callback.
pub const L053_CONF_CALLBACK_ERR: &str = "L053";

// ---------------------------------------------------------------------------
// Stable message IDs — subsystems
// ---------------------------------------------------------------------------

/// Log message: gamepad device connected.
pub const L036_GAMEPAD_CONNECTED: &str = "L036";
/// Log message: gamepad device disconnected.
pub const L037_GAMEPAD_DISCONNECTED: &str = "L037";
/// Log message: gilrs gamepad library unavailable.
pub const L038_GILRS_UNAVAILABLE: &str = "L038";
/// Log message: window close was requested.
pub const L039_WINDOW_CLOSE: &str = "L039";
/// Log message: window icon image failed to load.
pub const L040_ICON_LOAD_FAIL: &str = "L040";
/// Log message: window icon data could not be converted.
pub const L041_ICON_CONV_FAIL: &str = "L041";
/// Log message: configured display index is unavailable.
pub const L042_DISPLAY_INDEX_UNAVAIL: &str = "L042";
/// Log message: a file was dropped onto the window.
pub const L043_DROP_FILE: &str = "L043";
/// Log message: a game folder was dropped — loading it.
pub const L044_DROP_GAME: &str = "L044";

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

/// Emit a structured log message with a stable ID prefix and catalog text.
///
/// The message text is looked up from the global [`MessageCatalog`] so that
/// human-readable strings live in `src/engine/cfg/messages.toml` rather than
/// scattered across source files.
///
/// # Forms
///
/// ```ignore
/// // Simple — catalog text only (no dynamic args):
/// log_msg!(info, L001_ENGINE_START);
/// // → "[L001] Luna2D Engine starting"
///
/// // With dynamic detail appended after the catalog text:
/// log_msg!(info, L003_GAME_LOADED, "path: {}", main_lua.display());
/// // → "[L003] Game loaded: path: /my/game/main.lua"
///
/// log_msg!(warn, L020_NO_AUDIO_DEVICE, "device: {}", device_name);
/// log_msg!(error, L010_RENDER_ERROR, "{:?}", err);
/// ```
///
/// [`MessageCatalog`]: crate::engine::messages::MessageCatalog
#[macro_export]
macro_rules! log_msg {
    // ---- no dynamic args: emit catalog text only ----
    (error, $id:expr) => {
        log::error!("[{}] {}", $id, $crate::engine::messages::get_message($id))
    };
    (warn, $id:expr) => {
        log::warn!("[{}] {}", $id, $crate::engine::messages::get_message($id))
    };
    (info, $id:expr) => {
        log::info!("[{}] {}", $id, $crate::engine::messages::get_message($id))
    };
    (debug, $id:expr) => {
        log::debug!("[{}] {}", $id, $crate::engine::messages::get_message($id))
    };
    (trace, $id:expr) => {
        log::trace!("[{}] {}", $id, $crate::engine::messages::get_message($id))
    };
    // ---- with dynamic detail args ----
    (error, $id:expr, $($arg:tt)+) => {
        log::error!("[{}] {}: {}", $id, $crate::engine::messages::get_message($id), format_args!($($arg)+))
    };
    (warn, $id:expr, $($arg:tt)+) => {
        log::warn!("[{}] {}: {}", $id, $crate::engine::messages::get_message($id), format_args!($($arg)+))
    };
    (info, $id:expr, $($arg:tt)+) => {
        log::info!("[{}] {}: {}", $id, $crate::engine::messages::get_message($id), format_args!($($arg)+))
    };
    (debug, $id:expr, $($arg:tt)+) => {
        log::debug!("[{}] {}: {}", $id, $crate::engine::messages::get_message($id), format_args!($($arg)+))
    };
    (trace, $id:expr, $($arg:tt)+) => {
        log::trace!("[{}] {}: {}", $id, $crate::engine::messages::get_message($id), format_args!($($arg)+))
    };
}


// ---------------------------------------------------------------------------
// Audio module IDs (Tier 1)
// ---------------------------------------------------------------------------

/// Log message: failed to read a MIDI file from disk.
pub const A001_MIDI_READ_FAIL: &str = "A001";
/// Log message: MIDI playback is compiled out in this build.
pub const A002_MIDI_DISABLED: &str = "A002";
/// Log message: audio output device not available.
pub const A003_AUDIO_OUTPUT_UNAVAIL: &str = "A003";
/// Log message: audio queue entry started (debug trace).
pub const A004_AUDIO_PLAY_QUEUED: &str = "A004";

// ---------------------------------------------------------------------------
// Graphics module IDs (Tier 1)
// ---------------------------------------------------------------------------

/// Log message: failed to rasterize a font glyph.
pub const G001_FONT_GLYPH_WARN: &str = "G001";
/// Log message: screenshot aborted — surface is zero-sized.
pub const G002_SCREENSHOT_ZERO_SIZE: &str = "G002";
/// Log message: screenshot failed — readback buffer map error.
pub const G003_SCREENSHOT_MAP_FAIL: &str = "G003";
/// Log message: screenshot failed — readback status receive error.
pub const G004_SCREENSHOT_RECV_FAIL: &str = "G004";
/// Log message: screenshot failed — pixel data read error.
pub const G005_SCREENSHOT_DATA_FAIL: &str = "G005";

// ---------------------------------------------------------------------------
// Physics module IDs (Tier 1)
// ---------------------------------------------------------------------------

/// Log message: pulley joint not supported; falling back to fixed joint.
pub const P001_PULLEY_JOINT_FALLBACK: &str = "P001";
/// Log message: gear joint not supported; falling back to fixed joint.
pub const P002_GEAR_JOINT_FALLBACK: &str = "P002";

// ---------------------------------------------------------------------------
// Dataframe module IDs (Tier 2)
// ---------------------------------------------------------------------------

/// Log message: right join not yet implemented in DataFrame.
pub const DF01_RIGHT_JOIN_UNIMPL: &str = "DF01";

// ---------------------------------------------------------------------------
// Lua API layer IDs
// ---------------------------------------------------------------------------

/// Log message: a Lua-bound stub function was called (debug trace).
pub const LA01_API_STUB: &str = "LA01";
/// Log message: a pipeline Lua callback raised an error.
pub const LA02_PIPELINE_CALLBACK_FAIL: &str = "LA02";
/// Log message: openURL rejected because the scheme is not in the allowlist.
pub const LA03_OPEN_URL_REJECTED: &str = "LA03";
/// Log message: clipboard write operation failed.
pub const LA04_CLIPBOARD_WRITE_FAIL: &str = "LA04";
/// Log message: clipboard is unavailable on this platform.
pub const LA05_CLIPBOARD_UNAVAIL: &str = "LA05";
/// Log message: clipboard read operation failed.
pub const LA06_CLIPBOARD_READ_FAIL: &str = "LA06";
/// Log message: window.setScaleMode called with an unknown mode string.
pub const LA07_SCALE_MODE_UNKNOWN: &str = "LA07";
/// Log message: pathfinding.setThreadCount is not yet exposed to Lua.
pub const LA08_PATHFINDING_THREAD_UNIMPL: &str = "LA08";

// ---------------------------------------------------------------------------
// Lua callback error IDs (baseline)
// ---------------------------------------------------------------------------

/// Log message: error in a Lua callback function.
pub const L060_LUA_CALLBACK_ERROR: &str = "L060";




// ---------------------------------------------------------------------------
// App module IDs — surface, cursor, screenshot, drag-drop (baseline.app)
// ---------------------------------------------------------------------------

/// Log message: surface COPY_SRC not supported; screenshots unavailable.
pub const L070_SURFACE_NO_READBACK: &str = "L070";
/// Log message: failed to apply relative cursor grab mode.
pub const L071_CURSOR_GRAB_FAIL: &str = "L071";
/// Log message: failed to apply cursor grab mode (locked/none).
pub const L072_CURSOR_GRAB_LOCK_FAIL: &str = "L072";
/// Log message: failed to set cursor position.
pub const L073_CURSOR_POS_FAIL: &str = "L073";
/// Log message: screenshot requested but surface does not support readback.
pub const L074_SCREENSHOT_NO_READBACK: &str = "L074";
/// Log message: failed to save screenshot PNG to filesystem.
pub const L075_SCREENSHOT_SAVE_FAIL: &str = "L075";
/// Log message: failed to PNG-encode screenshot data.
pub const L076_SCREENSHOT_ENCODE_FAIL: &str = "L076";
/// Log message: drag-drop file hover event received.
pub const L077_DRAG_HOVER: &str = "L077";
/// Log message: drag-drop hover cancelled.
pub const L078_DRAG_HOVER_CANCEL: &str = "L078";
/// Log message: drag-drop event ignored because a game is already running.
pub const L079_DRAG_DROP_IGNORED: &str = "L079";
/// Log message: game directory resolved.
pub const L080_GAME_DIR: &str = "L080";
/// Log message: log file path resolved.
pub const L081_LOG_FILE: &str = "L081";
/// Log message: could not create log file; logging falls back to stderr.
pub const L082_LOG_FILE_FAIL: &str = "L082";

// ---------------------------------------------------------------------------
// Graphics font atlas growth IDs
// ---------------------------------------------------------------------------

/// Log message: font atlas has reached the maximum size and cannot grow.
pub const G006_ATLAS_MAX_SIZE: &str = "G006";
