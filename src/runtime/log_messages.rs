//! Structured logging with stable message IDs for the Lurek2D engine.
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

/// Sets the global log level at runtime (called from `lurek.platform.setLogLevel`).
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
/// Log message: error returned from `lurek.conf()` callback.
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
/// // → "[L001] Lurek2D Engine starting"
///
/// // With dynamic detail appended after the catalog text:
/// log_msg!(info, L003_GAME_LOADED, "path: {}", main_lua.display());
/// // → "[L003] Game loaded: path: /my/game/main.lua"
///
/// log_msg!(warn, L020_NO_AUDIO_DEVICE, "device: {}", device_name);
/// log_msg!(error, L010_RENDER_ERROR, "{:?}", err);
/// ```
///
/// [`MessageCatalog`]: crate::runtime::messages::MessageCatalog
#[macro_export]
macro_rules! log_msg {
    // ---- no dynamic args: emit catalog text only ----
    (error, $id:expr) => {
        ::log::error!("[{}] {}", $id, $crate::runtime::messages::get_message($id))
    };
    (warn, $id:expr) => {
        ::log::warn!("[{}] {}", $id, $crate::runtime::messages::get_message($id))
    };
    (info, $id:expr) => {
        ::log::info!("[{}] {}", $id, $crate::runtime::messages::get_message($id))
    };
    (debug, $id:expr) => {
        ::log::debug!("[{}] {}", $id, $crate::runtime::messages::get_message($id))
    };
    (trace, $id:expr) => {
        ::log::trace!("[{}] {}", $id, $crate::runtime::messages::get_message($id))
    };
    // ---- with dynamic detail args ----
    (error, $id:expr, $($arg:tt)+) => {
        ::log::error!("[{}] {}: {}", $id, $crate::runtime::messages::get_message($id), format_args!($($arg)+))
    };
    (warn, $id:expr, $($arg:tt)+) => {
        ::log::warn!("[{}] {}: {}", $id, $crate::runtime::messages::get_message($id), format_args!($($arg)+))
    };
    (info, $id:expr, $($arg:tt)+) => {
        ::log::info!("[{}] {}: {}", $id, $crate::runtime::messages::get_message($id), format_args!($($arg)+))
    };
    (debug, $id:expr, $($arg:tt)+) => {
        ::log::debug!("[{}] {}: {}", $id, $crate::runtime::messages::get_message($id), format_args!($($arg)+))
    };
    (trace, $id:expr, $($arg:tt)+) => {
        ::log::trace!("[{}] {}: {}", $id, $crate::runtime::messages::get_message($id), format_args!($($arg)+))
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

// ── Filesystem ──────────────────────────────────────────────────────────────
/// Stable ID for "GameFS initialised".
pub const FS01_GAMEFS_INIT: &str = "FS01";
/// Stable ID for "file read".
pub const FS02_FILE_READ: &str = "FS02";
/// Stable ID for "file write".
pub const FS03_FILE_WRITE: &str = "FS03";
/// Stable ID for "path traversal rejected".
pub const FS04_PATH_TRAVERSAL: &str = "FS04";
/// Stable ID for "VirtualFS path mounted".
pub const FS05_VFS_MOUNT: &str = "FS05";

// ── Animation ────────────────────────────────────────────────────────────────
/// Stable ID for "AnimationController created".
pub const AN01_ANIM_CTRL_INIT: &str = "AN01";
/// Stable ID for "animation clip added".
pub const AN02_CLIP_ADDED: &str = "AN02";
/// Stable ID for "animation clip not found".
pub const AN03_CLIP_NOT_FOUND: &str = "AN03";

// ── Entity ───────────────────────────────────────────────────────────────────
/// Stable ID for "Universe created".
pub const EN01_UNIVERSE_INIT: &str = "EN01";
/// Stable ID for "entity spawned".
pub const EN02_ENTITY_SPAWN: &str = "EN02";
/// Stable ID for "entity pool running low".
pub const EN03_ENTITY_LOW: &str = "EN03";

// ── Tilemap ──────────────────────────────────────────────────────────────────
/// Stable ID for "TileMap created".
pub const TM01_TILEMAP_INIT: &str = "TM01";
/// Stable ID for "tileset added to map".
pub const TM02_TILESET_ADD: &str = "TM02";
/// Stable ID for "tile layer added".
pub const TM03_LAYER_ADD: &str = "TM03";
/// Stable ID for "TMX parse failed".
pub const TM04_TMX_FAIL: &str = "TM04";

// ── SaveGame ─────────────────────────────────────────────────────────────────
/// Stable ID for "SaveManager created".
pub const SV01_SAVE_INIT: &str = "SV01";
/// Stable ID for "save write started".
pub const SV02_SAVE_WRITE: &str = "SV02";
/// Stable ID for "save load started".
pub const SV03_SAVE_LOAD: &str = "SV03";
/// Stable ID for "save write error".
pub const SV04_SAVE_ERROR: &str = "SV04";

// ── Scene ────────────────────────────────────────────────────────────────────
/// Stable ID for "SceneStack created".
pub const SC01_STACK_INIT: &str = "SC01";
/// Stable ID for "scene pushed".
pub const SC02_SCENE_PUSH: &str = "SC02";
/// Stable ID for "scene popped".
pub const SC03_SCENE_POP: &str = "SC03";
/// Stable ID for "scene stack cleared".
pub const SC04_STACK_CLEAR: &str = "SC04";

// ── Thread ───────────────────────────────────────────────────────────────────
/// Stable ID for "Worker created".
pub const TH01_WORKER_INIT: &str = "TH01";
/// Stable ID for "worker thread started".
pub const TH02_WORKER_START: &str = "TH02";
/// Stable ID for "worker thread finished".
pub const TH03_WORKER_DONE: &str = "TH03";
/// Stable ID for "worker thread error".
pub const TH04_WORKER_ERROR: &str = "TH04";

// ── Pathfinding ──────────────────────────────────────────────────────────────
/// Stable ID for "pathfinding Grid created".
pub const PF01_GRID_INIT: &str = "PF01";
/// Stable ID for "path found".
pub const PF02_PATH_FOUND: &str = "PF02";
/// Stable ID for "no path to target".
pub const PF03_NO_PATH: &str = "PF03";

// ── Modding ──────────────────────────────────────────────────────────────────
/// Stable ID for "ModManager created".
pub const MD01_MGR_INIT: &str = "MD01";
/// Stable ID for "mod entry registered".
pub const MD02_MOD_REG: &str = "MD02";
/// Stable ID for "mod load failed".
pub const MD03_MOD_FAIL: &str = "MD03";
/// Stable ID for "load order resolved".
pub const MD04_ORDER_OK: &str = "MD04";

// ── Network ──────────────────────────────────────────────────────────────────
/// Stable ID for "network host bound".
pub const NW01_HOST_BIND: &str = "NW01";
/// Stable ID for "peer connected".
pub const NW02_PEER_CONN: &str = "NW02";
/// Stable ID for "peer disconnected".
pub const NW03_PEER_DISC: &str = "NW03";
/// Stable ID for "network error".
pub const NW04_NET_ERROR: &str = "NW04";

// ── Pipeline ─────────────────────────────────────────────────────────────────
/// Stable ID for "Pipeline created".
pub const PL01_PIPELINE_INIT: &str = "PL01";
/// Stable ID for "pipeline step added".
pub const PL02_STEP_ADD: &str = "PL02";
/// Stable ID for "pipeline executed".
pub const PL03_EXEC: &str = "PL03";
/// Stable ID for "pipeline cycle detected".
pub const PL04_CYCLE: &str = "PL04";

// ── Automation ───────────────────────────────────────────────────────────────
/// Stable ID for "Simulator created".
pub const AT01_SIM_INIT: &str = "AT01";
/// Stable ID for "automation script loaded".
pub const AT02_SCRIPT_LOAD: &str = "AT02";
/// Stable ID for "simulation step warn".
pub const AT03_STEP_WARN: &str = "AT03";

// ── Audio Decoder ────────────────────────────────────────────────────────────
/// Stable ID for "audio file decoded".
pub const AD01_AUDIO_DECODED: &str = "AD01";
/// Stable ID for "audio decode error".
pub const AD02_AUDIO_ERROR: &str = "AD02";

// ── Compute ──────────────────────────────────────────────────────────────────
/// Stable ID for "NdArray allocated".
pub const CP01_NDARRAY_ALLOC: &str = "CP01";
/// Stable ID for "NdArray exceeds recommended size".
pub const CP02_NDARRAY_LARGE: &str = "CP02";

// ── Minimap ──────────────────────────────────────────────────────────────────
/// Stable ID for "Minimap created".
pub const MM01_MINIMAP_INIT: &str = "MM01";
/// Stable ID for "minimap terrain rebuilt".
pub const MM02_TERRAIN_REBUILD: &str = "MM02";

// ── Procgen ──────────────────────────────────────────────────────────────────
/// Stable ID for "cellular automata started".
pub const PG01_CELLULAR_START: &str = "PG01";
/// Stable ID for "cellular automata done".
pub const PG02_CELLULAR_DONE: &str = "PG02";

// ── Serial ───────────────────────────────────────────────────────────────────
/// Stable ID for "JSON parsed".
pub const SR01_JSON_OK: &str = "SR01";
/// Stable ID for "JSON parse error".
pub const SR02_JSON_ERR: &str = "SR02";
/// Stable ID for "JSON encoded".
pub const SR03_JSON_ENC: &str = "SR03";

// ── GUI ──────────────────────────────────────────────────────────────────────
/// Stable ID for "GuiContext created".
pub const GU01_CTX_INIT: &str = "GU01";
/// Stable ID for "widget added to context".
pub const GU02_WIDGET_ADD: &str = "GU02";
/// Stable ID for "GuiContext reset".
pub const GU03_CTX_RESET: &str = "GU03";

// ── Texture ──────────────────────────────────────────────────────────────────
/// Stable ID for "texture decoded".
pub const TX01_TEX_DECODED: &str = "TX01";
/// Stable ID for "large texture warning".
pub const TX02_TEX_LARGE: &str = "TX02";
/// Stable ID for "texture decode error".
pub const TX03_TEX_ERROR: &str = "TX03";

// ── Shader ───────────────────────────────────────────────────────────────────
/// Stable ID for "shader created".
pub const SH01_SHADER_OK: &str = "SH01";
/// Stable ID for "shader compile error".
pub const SH02_SHADER_ERR: &str = "SH02";

// ── LightWorld ───────────────────────────────────────────────────────────────
/// Stable ID for "LightWorld created".
pub const LW01_LIGHT_WORLD_INIT: &str = "LW01";
/// Stable ID for "light source added".
pub const LW02_LIGHT_ADD: &str = "LW02";
/// Stable ID for "max lights reached".
pub const LW03_LIGHT_MAX: &str = "LW03";

// ── Spine ────────────────────────────────────────────────────────────────────
/// Stable ID for "Skeleton loaded".
pub const SP01_SKEL_LOADED: &str = "SP01";
/// Stable ID for "skeleton animation not found".
pub const SP02_SKEL_ANIM_MISS: &str = "SP02";

// ── ImageData ────────────────────────────────────────────────────────────────
/// Stable ID for "ImageData loaded".
pub const IM01_IMAGE_LOADED: &str = "IM01";
/// Stable ID for "ImageData byte size mismatch".
pub const IM02_IMAGE_MISMATCH: &str = "IM02";

// ── audio_source ──────────────────────────────────────────────────────────
/// Stable ID for "audio source created with file path".
pub const AS01: &str = "AS01";

// ── audio_bus ─────────────────────────────────────────────────────────────
/// Stable ID for "audio bus created with name".
pub const BU01: &str = "BU01";
/// Stable ID for "audio bus paused".
pub const BU02: &str = "BU02";
/// Stable ID for "audio bus resumed".
pub const BU03: &str = "BU03";

// ── particle_emitter ──────────────────────────────────────────────────────
/// Stable ID for "particle system created".
pub const PE01: &str = "PE01";
/// Stable ID for "particle emitter activated".
pub const PE02: &str = "PE02";
/// Stable ID for "particle emitter stopped".
pub const PE03: &str = "PE03";
/// Stable ID for "particle system reset, all active particles cleared".
pub const PE04: &str = "PE04";

// ── physics_body ──────────────────────────────────────────────────────────
/// Stable ID for "rectangular physics body created at position".
pub const BD01: &str = "BD01";
/// Stable ID for "circular physics body created at position with radius".
pub const BD02: &str = "BD02";
/// Stable ID for "polygon physics body created at position".
pub const BD03: &str = "BD03";

// ── scheduler ─────────────────────────────────────────────────────────────
/// Stable ID for "scheduler instance created".
pub const TI01: &str = "TI01";
/// Stable ID for "one-shot callback scheduled with delay".
pub const TI02: &str = "TI02";
/// Stable ID for "repeating callback scheduled with interval".
pub const TI03: &str = "TI03";
/// Stable ID for "all scheduled callbacks cancelled".
pub const TI04: &str = "TI04";

// ── fsm ───────────────────────────────────────────────────────────────────
/// Stable ID for "FSM state transition initiated".
pub const FN01: &str = "FN01";
/// Stable ID for "FSM state transition completed or error condition triggered".
pub const FN02: &str = "FN02";

// ── goap ──────────────────────────────────────────────────────────────────
/// Stable ID for "GOAP plan computation started with action set".
pub const GP01: &str = "GP01";
/// Stable ID for "GOAP plan action execution step".
pub const GP02: &str = "GP02";
/// Stable ID for "GOAP planning failed — no valid plan found for goal".
pub const GP03: &str = "GP03";

// ── flow_field ────────────────────────────────────────────────────────────
/// Stable ID for "flow field created at grid dimensions".
pub const FF01: &str = "FF01";
/// Stable ID for "flow field computed for goal cell".
pub const FF02: &str = "FF02";
/// Stable ID for "flow field cleared".
pub const FF03: &str = "FF03";

// ── hpa ───────────────────────────────────────────────────────────────────
/// Stable ID for "HPA* abstract graph built from NavGrid".
pub const HP01: &str = "HP01";
/// Stable ID for "HPA* path not found between start and goal".
pub const HP02: &str = "HP02";
/// Stable ID for "HPA* path found between start and goal".
pub const HP03: &str = "HP03";

// ── transition ────────────────────────────────────────────────────────────
/// Stable ID for "scene transition started".
pub const TR01: &str = "TR01";
/// Stable ID for "scene transition completed".
pub const TR02: &str = "TR02";

// ── graph_simulation ──────────────────────────────────────────────────────
/// Stable ID for "graph simulation step executed".
pub const GR01: &str = "GR01";
/// Stable ID for "graph simulation events processed this step".
pub const GR02: &str = "GR02";

// ── canvas_gfx ────────────────────────────────────────────────────────────
/// Stable ID for "canvas render target created at pixel dimensions".
pub const CV01: &str = "CV01";

// ── mesh_gfx ──────────────────────────────────────────────────────────────
/// Stable ID for "GPU mesh created with vertex and index buffers".
pub const MS01: &str = "MS01";
/// Stable ID for "GPU mesh geometry updated with new vertex data".
pub const MS02: &str = "MS02";

// ── raycaster ─────────────────────────────────────────────────────────────
/// Stable ID for "raycaster world initialized at grid dimensions".
pub const RC01: &str = "RC01";

// ── fx_stack ──────────────────────────────────────────────────────────────
/// Stable ID for "post-processing effect added to FX stack".
pub const FX01: &str = "FX01";
/// Stable ID for "post-processing FX stack rendered to output target".
pub const FX02: &str = "FX02";

// ── dataframe ─────────────────────────────────────────────────────────────
/// Stable ID for "DataFrame operation logged (mutation, creation, or query)".
pub const DF01: &str = "DF01";

// ── signal ────────────────────────────────────────────────────────────────
/// Stable ID for "signal emitted to registered handlers".
pub const SG01: &str = "SG01";
/// Stable ID for "signal handler registered for event".
pub const SG02: &str = "SG02";

// ── mapgen ────────────────────────────────────────────────────────────────
/// Stable ID for "procedural map generation started at grid dimensions".
pub const MG01: &str = "MG01";
/// Stable ID for "map generation layer added to output".
pub const MG02: &str = "MG02";
/// Stable ID for "procedural map generation completed".
pub const MG03: &str = "MG03";

// ── astar ─────────────────────────────────────────────────────────────────
/// Stable ID for "A* pathfinding search started".
pub const AT01: &str = "AT01";
/// Stable ID for "A* path found between start and goal".
pub const AT02: &str = "AT02";
/// Stable ID for "A* search exhausted — no path found between start and goal".
pub const AT03: &str = "AT03";

// ── tmx ───────────────────────────────────────────────────────────────────
/// Stable ID for "TMX tilemap file parse started".
pub const TL01: &str = "TL01";
/// Stable ID for "TMX tilemap file parsed successfully at tile dimensions".
pub const TL02: &str = "TL02";

// ── voronoi ───────────────────────────────────────────────────────────────
/// Stable ID for "Voronoi diagram computed from seed points".
pub const VR01: &str = "VR01";
/// Stable ID for "Voronoi region processing step completed".
pub const VR02: &str = "VR02";

// ── savegame ──────────────────────────────────────────────────────────────
/// Stable ID for "save slot initialized for write".
pub const SV01: &str = "SV01";
/// Stable ID for "save data written to slot".
pub const SV02: &str = "SV02";
/// Stable ID for "save data loaded from slot".
pub const SV03: &str = "SV03";
/// Stable ID for "save operation failed with error".
pub const SV04: &str = "SV04";

// ── channel_thread ────────────────────────────────────────────────────────
/// Stable ID for "anonymous thread channel created".
pub const CH01: &str = "CH01";
/// Stable ID for "named thread channel created".
pub const CH02: &str = "CH02";
/// Stable ID for "value pushed onto channel queue".
pub const CH03: &str = "CH03";
/// Stable ID for "channel queue drained and cleared".
pub const CH04: &str = "CH04";

// ── light_source ──────────────────────────────────────────────────────────
/// Stable ID for "point light source added at position with radius".
pub const LT01: &str = "LT01";
/// Stable ID for "light source position updated".
pub const LT02: &str = "LT02";
/// Stable ID for "light source radius changed".
pub const LT03: &str = "LT03";

// ── relationships ─────────────────────────────────────────────────────────
/// Stable ID for "relationship type registered with hierarchy depth".
pub const RL01: &str = "RL01";
/// Stable ID for "relationship created between two entities".
pub const RL02: &str = "RL02";
/// Stable ID for "relationship lookup executed for entity pair".
pub const RL03: &str = "RL03";

// ── graph_core ────────────────────────────────────────────────────────────
/// Stable ID for "graph node added with type identifier".
pub const GC01: &str = "GC01";
/// Stable ID for "graph node removed by ID".
pub const GC02: &str = "GC02";
/// Stable ID for "directed edge added between graph nodes".
pub const GC03: &str = "GC03";
/// Stable ID for "edge removed from graph by ID".
pub const GC04: &str = "GC04";

// ── command_queue ─────────────────────────────────────────────────────────
/// Stable ID for "command queue created".
pub const CQ01: &str = "CQ01";
/// Stable ID for "command queue flushed".
pub const CQ02: &str = "CQ02";
/// Stable ID for "commands dispatched from queue".
pub const CQ03: &str = "CQ03";

// ── unit_pathfinder ───────────────────────────────────────────────────────
/// Stable ID for "unit pathfinder initialized".
pub const UP01: &str = "UP01";
/// Stable ID for "path found for unit between grid positions".
pub const UP02: &str = "UP02";
/// Stable ID for "unit pathfinding failed between grid positions".
pub const UP03: &str = "UP03";

// ── screen_overlay ────────────────────────────────────────────────────────
/// Stable ID for "screen overlay created at pixel dimensions".
pub const OV01: &str = "OV01";
/// Stable ID for "overlay color fade animation started".
pub const OV02: &str = "OV02";
/// Stable ID for "overlay flash effect started with intensity and duration".
pub const OV03: &str = "OV03";

// ── post_effect ───────────────────────────────────────────────────────────
/// Stable ID for "post-FX effect pass created".
pub const FE01: &str = "FE01";
/// Stable ID for "post-FX effect linked to shader".
pub const FE02: &str = "FE02";
/// Stable ID for "post-FX effect uniform parameter set".
pub const FE03: &str = "FE03";

// ── column_batch ──────────────────────────────────────────────────────────
/// Stable ID for "raycaster column batch created with column count".
pub const CB01: &str = "CB01";
/// Stable ID for "raycaster column cell value computed".
pub const CB02: &str = "CB02";

// ── tileset_ext ───────────────────────────────────────────────────────────
/// Stable ID for "tileset loaded with first GID and tile count".
pub const TS01: &str = "TS01";
/// Stable ID for "animated tile registered with frame count".
pub const TS02: &str = "TS02";
/// Stable ID for "tile collision flag assigned".
pub const TS03: &str = "TS03";

// ── gamepad_state ─────────────────────────────────────────────────────────
/// Stable ID for "gamepad device connected with ID".
pub const GD01: &str = "GD01";
/// Stable ID for "gamepad button state changed".
pub const GD02: &str = "GD02";
/// Stable ID for "gamepad axis value updated".
pub const GD03: &str = "GD03";

// ── dsp_effect ────────────────────────────────────────────────────────────
/// Stable ID for "DSP effect added to audio graph with ID".
pub const DP01: &str = "DP01";
/// Stable ID for "DSP audio source initialized with sample rate and channels".
pub const DP02: &str = "DP02";
/// Stable ID for "DSP effect graph processed one audio frame".
pub const DP03: &str = "DP03";

// ── blackboard ────────────────────────────────────────────────────────────
/// Stable ID for "AI blackboard created".
pub const BB01: &str = "BB01";
/// Stable ID for "blackboard value read by key".
pub const BB02: &str = "BB02";
/// Stable ID for "blackboard entries cleared".
pub const BB03: &str = "BB03";

// ── chunk_map ─────────────────────────────────────────────────────────────
/// Stable ID for "chunk map initialized with chunk side length".
pub const CK01: &str = "CK01";
/// Stable ID for "tile chunk loaded at chunk coordinates".
pub const CK02: &str = "CK02";
/// Stable ID for "tile chunk unloaded at chunk coordinates".
pub const CK03: &str = "CK03";

// ── image_effect ──────────────────────────────────────────────────────────
/// Stable ID for "image effect shader registered by name".
pub const IE01: &str = "IE01";
/// Stable ID for "image effect applied to pixel buffer".
pub const IE02: &str = "IE02";
/// Stable ID for "image effect removed by name".
pub const IE03: &str = "IE03";

// ── nav_grid ──────────────────────────────────────────────────────────────
/// Stable ID for "navigation grid created at tile dimensions".
pub const NG01: &str = "NG01";
/// Stable ID for "navigation grid cost map reloaded".
pub const NG02: &str = "NG02";
/// Stable ID for "navigation cell cost value updated".
pub const NG03: &str = "NG03";

// ── sprite_sheet ──────────────────────────────────────────────────────────
/// Stable ID for "sprite sheet parsed with total frame count".
pub const SS01: &str = "SS01";
/// Stable ID for "sprite animation clip registered with frame range".
pub const SS02: &str = "SS02";

// ── influence_map ─────────────────────────────────────────────────────────
/// Stable ID for "influence map created at grid dimensions with cell size".
pub const IF01: &str = "IF01";
/// Stable ID for "influence layer added by name".
pub const IF02: &str = "IF02";
/// Stable ID for "influence map layer values propagated".
pub const IF03: &str = "IF03";

// ── spatial_hash ──────────────────────────────────────────────────────────
/// Stable ID for "spatial hash grid created with cell size".
pub const HX01: &str = "HX01";
/// Stable ID for "spatial hash rebuilt with entity count".
pub const HX02: &str = "HX02";
