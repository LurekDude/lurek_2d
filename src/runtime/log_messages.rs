//! Runtime log message ids and logging helpers used across engine modules.
//! Defines stable id constants and a macro for message-aware logging calls.

use std::sync::atomic::{AtomicU8, Ordering};
static LOG_LEVEL_OVERRIDE: AtomicU8 = AtomicU8::new(0);
/// Execute set_log_level and return its result.
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
/// Execute get_log_level and return its result.
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
/// Stable log message identifier.
pub const L001_ENGINE_START: &str = "L001";
/// Stable log message identifier.
pub const L002_ENGINE_STOP: &str = "L002";
/// Stable log message identifier.
pub const L003_GAME_LOADED: &str = "L003";
/// Stable log message identifier.
pub const L004_GAME_RESTART: &str = "L004";
/// Stable log message identifier.
pub const L005_CONF_LOADED: &str = "L005";
/// Stable log message identifier.
pub const L006_SPLASH_SCREEN: &str = "L006";
/// Stable log message identifier.
pub const L007_NO_MAIN_LUA: &str = "L007";
/// Stable log message identifier.
pub const L033_GPU_ADAPTER: &str = "L033";
/// Stable log message identifier.
pub const L034_GPU_TEX_DIM: &str = "L034";
/// Stable log message identifier.
pub const L035_GPU_INIT: &str = "L035";
/// Stable log message identifier.
pub const L010_RENDER_ERROR: &str = "L010";
/// Stable log message identifier.
pub const L011_LUA_ERROR: &str = "L011";
/// Stable log message identifier.
pub const L012_AUDIO_ERROR: &str = "L012";
/// Stable log message identifier.
pub const L013_FS_ERROR: &str = "L013";
/// Stable log message identifier.
pub const L014_PHYSICS_ERROR: &str = "L014";
/// Stable log message identifier.
pub const L015_RESOURCE_NOT_FOUND: &str = "L015";
/// Stable log message identifier.
pub const L016_LUA_VM_INIT_FAIL: &str = "L016";
/// Stable log message identifier.
pub const L017_MAIN_LUA_READ_FAIL: &str = "L017";
/// Stable log message identifier.
pub const L020_NO_AUDIO_DEVICE: &str = "L020";
/// Stable log message identifier.
pub const L021_CLIPBOARD_FAIL: &str = "L021";
/// Stable log message identifier.
pub const L022_UNKNOWN_LOG_LEVEL: &str = "L022";
/// Stable log message identifier.
pub const L023_GPU_TEX_TOO_SMALL: &str = "L023";
/// Stable log message identifier.
pub const L024_SURFACE_LOST: &str = "L024";
/// Stable log message identifier.
pub const L050_MODULE_DEP_DISABLED: &str = "L050";
/// Stable log message identifier.
pub const L051_CONF_READ_ERR: &str = "L051";
/// Stable log message identifier.
pub const L052_CONF_PARSE_ERR: &str = "L052";
/// Stable log message identifier.
pub const L053_CONF_CALLBACK_ERR: &str = "L053";
/// Stable log message identifier.
pub const L036_GAMEPAD_CONNECTED: &str = "L036";
/// Stable log message identifier.
pub const L037_GAMEPAD_DISCONNECTED: &str = "L037";
/// Stable log message identifier.
pub const L038_GILRS_UNAVAILABLE: &str = "L038";
/// Stable log message identifier.
pub const L039_WINDOW_CLOSE: &str = "L039";
/// Stable log message identifier.
pub const L040_ICON_LOAD_FAIL: &str = "L040";
/// Stable log message identifier.
pub const L041_ICON_CONV_FAIL: &str = "L041";
/// Stable log message identifier.
pub const L042_DISPLAY_INDEX_UNAVAIL: &str = "L042";
/// Stable log message identifier.
pub const L043_DROP_FILE: &str = "L043";
/// Stable log message identifier.
pub const L044_DROP_GAME: &str = "L044";
/// Stable log message identifier.
pub const L030_ASYNC_LOAD_REQUEST: &str = "L030";
/// Stable log message identifier.
pub const L031_ASYNC_LOAD_COMPLETE: &str = "L031";
/// Stable log message identifier.
pub const L032_BATCH_STATS: &str = "L032";
#[macro_export]
macro_rules! log_msg {
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
/// Stable log message identifier.
pub const A001_MIDI_READ_FAIL: &str = "A001";
/// Stable log message identifier.
pub const A002_MIDI_DISABLED: &str = "A002";
/// Stable log message identifier.
pub const A003_AUDIO_OUTPUT_UNAVAIL: &str = "A003";
/// Stable log message identifier.
pub const A004_AUDIO_PLAY_QUEUED: &str = "A004";
/// Stable log message identifier.
pub const G001_FONT_GLYPH_WARN: &str = "G001";
/// Stable log message identifier.
pub const G002_SCREENSHOT_ZERO_SIZE: &str = "G002";
/// Stable log message identifier.
pub const G003_SCREENSHOT_MAP_FAIL: &str = "G003";
/// Stable log message identifier.
pub const G004_SCREENSHOT_RECV_FAIL: &str = "G004";
/// Stable log message identifier.
pub const G005_SCREENSHOT_DATA_FAIL: &str = "G005";
/// Stable log message identifier.
pub const P001_PULLEY_JOINT_FALLBACK: &str = "P001";
/// Stable log message identifier.
pub const P002_GEAR_JOINT_FALLBACK: &str = "P002";
/// Stable log message identifier.
pub const DF01_RIGHT_JOIN_UNIMPL: &str = "DF01";
/// Stable log message identifier.
pub const LA01_API_STUB: &str = "LA01";
/// Stable log message identifier.
pub const LA02_PIPELINE_CALLBACK_FAIL: &str = "LA02";
/// Stable log message identifier.
pub const LA03_OPEN_URL_REJECTED: &str = "LA03";
/// Stable log message identifier.
pub const LA04_CLIPBOARD_WRITE_FAIL: &str = "LA04";
/// Stable log message identifier.
pub const LA05_CLIPBOARD_UNAVAIL: &str = "LA05";
/// Stable log message identifier.
pub const LA06_CLIPBOARD_READ_FAIL: &str = "LA06";
/// Stable log message identifier.
pub const LA07_SCALE_MODE_UNKNOWN: &str = "LA07";
/// Stable log message identifier.
pub const LA08_PATHFINDING_THREAD_UNIMPL: &str = "LA08";
/// Stable log message identifier.
pub const L060_LUA_CALLBACK_ERROR: &str = "L060";
/// Stable log message identifier.
pub const L070_SURFACE_NO_READBACK: &str = "L070";
/// Stable log message identifier.
pub const L071_CURSOR_GRAB_FAIL: &str = "L071";
/// Stable log message identifier.
pub const L072_CURSOR_GRAB_LOCK_FAIL: &str = "L072";
/// Stable log message identifier.
pub const L073_CURSOR_POS_FAIL: &str = "L073";
/// Stable log message identifier.
pub const L074_SCREENSHOT_NO_READBACK: &str = "L074";
/// Stable log message identifier.
pub const L075_SCREENSHOT_SAVE_FAIL: &str = "L075";
/// Stable log message identifier.
pub const L076_SCREENSHOT_ENCODE_FAIL: &str = "L076";
/// Stable log message identifier.
pub const L077_DRAG_HOVER: &str = "L077";
/// Stable log message identifier.
pub const L078_DRAG_HOVER_CANCEL: &str = "L078";
/// Stable log message identifier.
pub const L079_DRAG_DROP_IGNORED: &str = "L079";
/// Stable log message identifier.
pub const L080_GAME_DIR: &str = "L080";
/// Stable log message identifier.
pub const L081_LOG_FILE: &str = "L081";
/// Stable log message identifier.
pub const L082_LOG_FILE_FAIL: &str = "L082";
/// Stable log message identifier.
pub const L083_DROP_ARCHIVE: &str = "L083";
/// Stable log message identifier.
pub const L084_DROP_ARCHIVE_FAIL: &str = "L084";
/// Stable log message identifier.
pub const G006_ATLAS_MAX_SIZE: &str = "G006";
/// Stable log message identifier.
pub const FS01_GAMEFS_INIT: &str = "FS01";
/// Stable log message identifier.
pub const FS02_FILE_READ: &str = "FS02";
/// Stable log message identifier.
pub const FS03_FILE_WRITE: &str = "FS03";
/// Stable log message identifier.
pub const FS04_PATH_TRAVERSAL: &str = "FS04";
/// Stable log message identifier.
pub const FS05_VFS_MOUNT: &str = "FS05";
/// Stable log message identifier.
pub const AN01_ANIM_CTRL_INIT: &str = "AN01";
/// Stable log message identifier.
pub const AN02_CLIP_ADDED: &str = "AN02";
/// Stable log message identifier.
pub const AN03_CLIP_NOT_FOUND: &str = "AN03";
/// Stable log message identifier.
pub const EN01_UNIVERSE_INIT: &str = "EN01";
/// Stable log message identifier.
pub const EN02_ENTITY_SPAWN: &str = "EN02";
/// Stable log message identifier.
pub const EN03_ENTITY_LOW: &str = "EN03";
/// Stable log message identifier.
pub const TM01_TILEMAP_INIT: &str = "TM01";
/// Stable log message identifier.
pub const TM02_TILESET_ADD: &str = "TM02";
/// Stable log message identifier.
pub const TM03_LAYER_ADD: &str = "TM03";
/// Stable log message identifier.
pub const TM04_TMX_FAIL: &str = "TM04";
/// Stable log message identifier.
pub const SV01_SAVE_INIT: &str = "SV01";
/// Stable log message identifier.
pub const SV02_SAVE_WRITE: &str = "SV02";
/// Stable log message identifier.
pub const SV03_SAVE_LOAD: &str = "SV03";
/// Stable log message identifier.
pub const SV04_SAVE_ERROR: &str = "SV04";
/// Stable log message identifier.
pub const SC01_STACK_INIT: &str = "SC01";
/// Stable log message identifier.
pub const SC02_SCENE_PUSH: &str = "SC02";
/// Stable log message identifier.
pub const SC03_SCENE_POP: &str = "SC03";
/// Stable log message identifier.
pub const SC04_STACK_CLEAR: &str = "SC04";
/// Stable log message identifier.
pub const TH01_WORKER_INIT: &str = "TH01";
/// Stable log message identifier.
pub const TH02_WORKER_START: &str = "TH02";
/// Stable log message identifier.
pub const TH03_WORKER_DONE: &str = "TH03";
/// Stable log message identifier.
pub const TH04_WORKER_ERROR: &str = "TH04";
/// Stable log message identifier.
pub const PF01_GRID_INIT: &str = "PF01";
/// Stable log message identifier.
pub const PF02_PATH_FOUND: &str = "PF02";
/// Stable log message identifier.
pub const PF03_NO_PATH: &str = "PF03";
/// Stable log message identifier.
pub const MD01_MGR_INIT: &str = "MD01";
/// Stable log message identifier.
pub const MD02_MOD_REG: &str = "MD02";
/// Stable log message identifier.
pub const MD03_MOD_FAIL: &str = "MD03";
/// Stable log message identifier.
pub const MD04_ORDER_OK: &str = "MD04";
/// Stable log message identifier.
pub const NW01_HOST_BIND: &str = "NW01";
/// Stable log message identifier.
pub const NW02_PEER_CONN: &str = "NW02";
/// Stable log message identifier.
pub const NW03_PEER_DISC: &str = "NW03";
/// Stable log message identifier.
pub const NW04_NET_ERROR: &str = "NW04";
/// Stable log message identifier.
pub const PL01_PIPELINE_INIT: &str = "PL01";
/// Stable log message identifier.
pub const PL02_STEP_ADD: &str = "PL02";
/// Stable log message identifier.
pub const PL03_EXEC: &str = "PL03";
/// Stable log message identifier.
pub const PL04_CYCLE: &str = "PL04";
/// Stable log message identifier.
pub const AT01_SIM_INIT: &str = "AT01";
/// Stable log message identifier.
pub const AT02_SCRIPT_LOAD: &str = "AT02";
/// Stable log message identifier.
pub const AT03_STEP_WARN: &str = "AT03";
/// Stable log message identifier.
pub const AD01_AUDIO_DECODED: &str = "AD01";
/// Stable log message identifier.
pub const AD02_AUDIO_ERROR: &str = "AD02";
/// Stable log message identifier.
pub const CP01_NDARRAY_ALLOC: &str = "CP01";
/// Stable log message identifier.
pub const CP02_NDARRAY_LARGE: &str = "CP02";
/// Stable log message identifier.
pub const MM01_MINIMAP_INIT: &str = "MM01";
/// Stable log message identifier.
pub const MM02_TERRAIN_REBUILD: &str = "MM02";
/// Stable log message identifier.
pub const PG01_CELLULAR_START: &str = "PG01";
/// Stable log message identifier.
pub const PG02_CELLULAR_DONE: &str = "PG02";
/// Stable log message identifier.
pub const SR01_JSON_OK: &str = "SR01";
/// Stable log message identifier.
pub const SR02_JSON_ERR: &str = "SR02";
/// Stable log message identifier.
pub const SR03_JSON_ENC: &str = "SR03";
/// Stable log message identifier.
pub const SR04_MSGPACK_DEC: &str = "SR04";
/// Stable log message identifier.
pub const SR05_MSGPACK_ENC: &str = "SR05";
/// Stable log message identifier.
pub const SR06_XML_OK: &str = "SR06";
/// Stable log message identifier.
pub const SR07_SCHEMA_PASS: &str = "SR07";
/// Stable log message identifier.
pub const SR08_SCHEMA_FAIL: &str = "SR08";
/// Stable log message identifier.
pub const GU01_CTX_INIT: &str = "GU01";
/// Stable log message identifier.
pub const GU02_WIDGET_ADD: &str = "GU02";
/// Stable log message identifier.
pub const GU03_CTX_RESET: &str = "GU03";
/// Stable log message identifier.
pub const TX01_TEX_DECODED: &str = "TX01";
/// Stable log message identifier.
pub const TX02_TEX_LARGE: &str = "TX02";
/// Stable log message identifier.
pub const TX03_TEX_ERROR: &str = "TX03";
/// Stable log message identifier.
pub const SH01_SHADER_OK: &str = "SH01";
/// Stable log message identifier.
pub const SH02_SHADER_ERR: &str = "SH02";
/// Stable log message identifier.
pub const LW01_LIGHT_WORLD_INIT: &str = "LW01";
/// Stable log message identifier.
pub const LW02_LIGHT_ADD: &str = "LW02";
/// Stable log message identifier.
pub const LW03_LIGHT_MAX: &str = "LW03";
/// Stable log message identifier.
pub const SP01_SKEL_LOADED: &str = "SP01";
/// Stable log message identifier.
pub const SP02_SKEL_ANIM_MISS: &str = "SP02";
/// Stable log message identifier.
pub const IM01_IMAGE_LOADED: &str = "IM01";
/// Stable log message identifier.
pub const IM02_IMAGE_MISMATCH: &str = "IM02";
/// Stable log message identifier.
pub const AS01: &str = "AS01";
/// Stable log message identifier.
pub const BU01: &str = "BU01";
/// Stable log message identifier.
pub const BU02: &str = "BU02";
/// Stable log message identifier.
pub const BU03: &str = "BU03";
/// Stable log message identifier.
pub const PE01: &str = "PE01";
/// Stable log message identifier.
pub const PE02: &str = "PE02";
/// Stable log message identifier.
pub const PE03: &str = "PE03";
/// Stable log message identifier.
pub const PE04: &str = "PE04";
/// Stable log message identifier.
pub const BD01: &str = "BD01";
/// Stable log message identifier.
pub const BD02: &str = "BD02";
/// Stable log message identifier.
pub const BD03: &str = "BD03";
/// Stable log message identifier.
pub const TI01: &str = "TI01";
/// Stable log message identifier.
pub const TI02: &str = "TI02";
/// Stable log message identifier.
pub const TI03: &str = "TI03";
/// Stable log message identifier.
pub const TI04: &str = "TI04";
/// Stable log message identifier.
pub const FN01: &str = "FN01";
/// Stable log message identifier.
pub const FN02: &str = "FN02";
/// Stable log message identifier.
pub const GP01: &str = "GP01";
/// Stable log message identifier.
pub const GP02: &str = "GP02";
/// Stable log message identifier.
pub const GP03: &str = "GP03";
/// Stable log message identifier.
pub const FF01: &str = "FF01";
/// Stable log message identifier.
pub const FF02: &str = "FF02";
/// Stable log message identifier.
pub const FF03: &str = "FF03";
/// Stable log message identifier.
pub const HP01: &str = "HP01";
/// Stable log message identifier.
pub const HP02: &str = "HP02";
/// Stable log message identifier.
pub const HP03: &str = "HP03";
/// Stable log message identifier.
pub const TR01: &str = "TR01";
/// Stable log message identifier.
pub const TR02: &str = "TR02";
/// Stable log message identifier.
pub const GR01: &str = "GR01";
/// Stable log message identifier.
pub const GR02: &str = "GR02";
/// Stable log message identifier.
pub const CV01: &str = "CV01";
/// Stable log message identifier.
pub const MS01: &str = "MS01";
/// Stable log message identifier.
pub const MS02: &str = "MS02";
/// Stable log message identifier.
pub const RC01: &str = "RC01";
/// Stable log message identifier.
pub const FX01: &str = "FX01";
/// Stable log message identifier.
pub const FX02: &str = "FX02";
/// Stable log message identifier.
pub const DF01: &str = "DF01";
/// Stable log message identifier.
pub const SG01: &str = "SG01";
/// Stable log message identifier.
pub const SG02: &str = "SG02";
/// Stable log message identifier.
pub const MG01: &str = "MG01";
/// Stable log message identifier.
pub const MG02: &str = "MG02";
/// Stable log message identifier.
pub const MG03: &str = "MG03";
/// Stable log message identifier.
pub const AT01: &str = "AT01";
/// Stable log message identifier.
pub const AT02: &str = "AT02";
/// Stable log message identifier.
pub const AT03: &str = "AT03";
/// Stable log message identifier.
pub const TL01: &str = "TL01";
/// Stable log message identifier.
pub const TL02: &str = "TL02";
/// Stable log message identifier.
pub const VR01: &str = "VR01";
/// Stable log message identifier.
pub const VR02: &str = "VR02";
/// Stable log message identifier.
pub const SV01: &str = "SV01";
/// Stable log message identifier.
pub const SV02: &str = "SV02";
/// Stable log message identifier.
pub const SV03: &str = "SV03";
/// Stable log message identifier.
pub const SV04: &str = "SV04";
/// Stable log message identifier.
pub const CH01: &str = "CH01";
/// Stable log message identifier.
pub const CH02: &str = "CH02";
/// Stable log message identifier.
pub const CH03: &str = "CH03";
/// Stable log message identifier.
pub const CH04: &str = "CH04";
/// Stable log message identifier.
pub const LT01: &str = "LT01";
/// Stable log message identifier.
pub const LT02: &str = "LT02";
/// Stable log message identifier.
pub const LT03: &str = "LT03";
/// Stable log message identifier.
pub const RL01: &str = "RL01";
/// Stable log message identifier.
pub const RL02: &str = "RL02";
/// Stable log message identifier.
pub const RL03: &str = "RL03";
/// Stable log message identifier.
pub const GC01: &str = "GC01";
/// Stable log message identifier.
pub const GC02: &str = "GC02";
/// Stable log message identifier.
pub const GC03: &str = "GC03";
/// Stable log message identifier.
pub const GC04: &str = "GC04";
/// Stable log message identifier.
pub const CQ01: &str = "CQ01";
/// Stable log message identifier.
pub const CQ02: &str = "CQ02";
/// Stable log message identifier.
pub const CQ03: &str = "CQ03";
/// Stable log message identifier.
pub const UP01: &str = "UP01";
/// Stable log message identifier.
pub const UP02: &str = "UP02";
/// Stable log message identifier.
pub const UP03: &str = "UP03";
/// Stable log message identifier.
pub const OV01: &str = "OV01";
/// Stable log message identifier.
pub const OV02: &str = "OV02";
/// Stable log message identifier.
pub const OV03: &str = "OV03";
/// Stable log message identifier.
pub const FE01: &str = "FE01";
/// Stable log message identifier.
pub const FE02: &str = "FE02";
/// Stable log message identifier.
pub const FE03: &str = "FE03";
/// Stable log message identifier.
pub const CB01: &str = "CB01";
/// Stable log message identifier.
pub const CB02: &str = "CB02";
/// Stable log message identifier.
pub const TS01: &str = "TS01";
/// Stable log message identifier.
pub const TS02: &str = "TS02";
/// Stable log message identifier.
pub const TS03: &str = "TS03";
/// Stable log message identifier.
pub const GD01: &str = "GD01";
/// Stable log message identifier.
pub const GD02: &str = "GD02";
/// Stable log message identifier.
pub const GD03: &str = "GD03";
/// Stable log message identifier.
pub const DP01: &str = "DP01";
/// Stable log message identifier.
pub const DP02: &str = "DP02";
/// Stable log message identifier.
pub const DP03: &str = "DP03";
/// Stable log message identifier.
pub const BB01: &str = "BB01";
/// Stable log message identifier.
pub const BB02: &str = "BB02";
/// Stable log message identifier.
pub const BB03: &str = "BB03";
/// Stable log message identifier.
pub const CK01: &str = "CK01";
/// Stable log message identifier.
pub const CK02: &str = "CK02";
/// Stable log message identifier.
pub const CK03: &str = "CK03";
/// Stable log message identifier.
pub const IE01: &str = "IE01";
/// Stable log message identifier.
pub const IE02: &str = "IE02";
/// Stable log message identifier.
pub const IE03: &str = "IE03";
/// Stable log message identifier.
pub const NG01: &str = "NG01";
/// Stable log message identifier.
pub const NG02: &str = "NG02";
/// Stable log message identifier.
pub const NG03: &str = "NG03";
/// Stable log message identifier.
pub const SS01: &str = "SS01";
/// Stable log message identifier.
pub const SS02: &str = "SS02";
/// Stable log message identifier.
pub const IF01: &str = "IF01";
/// Stable log message identifier.
pub const IF02: &str = "IF02";
/// Stable log message identifier.
pub const IF03: &str = "IF03";
/// Stable log message identifier.
pub const HX01: &str = "HX01";
/// Stable log message identifier.
pub const HX02: &str = "HX02";
/// Stable log message identifier.
pub const BI01: &str = "BI01";
/// Stable log message identifier.
pub const BI02: &str = "BI02";
/// Stable log message identifier.
pub const BI03: &str = "BI03";
