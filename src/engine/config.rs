//! Engine and window configuration loaded from `conf.lua`.
//!
//! When the engine starts it looks for a `conf.lua` file in the game directory.
//! If found, it is evaluated in a minimal Lua VM.  The file must return a Lua table
//! whose structure mirrors the [`Config`] struct.  Missing fields fall back to
//! built-in defaults so authors only need to specify the settings they actually want
//! to change.
//!
//! # Structure
//!
//! [`Config`] is the top-level container and contains five nested structs:
//! - [`WindowConfig`] — window geometry, title, display placement, and decoration options.
//! - [`GraphicsConfig`] — GPU backend selection and power preference, resolved at startup.
//! - [`ModulesConfig`] — boolean feature-flags for optional engine subsystems (audio,
//!   physics, graphics, etc.).  Disabling a module avoids the startup cost and prevents
//!   the matching `luna.*` API calls from being registered.
//! - [`PerformanceConfig`] — target frame-rate cap (`fps_cap`).
//!
//! The `identity` field sets the name of the per-user save directory returned by
//! `luna.fs.getSaveDirectory()`.  If unset, the engine uses the game directory
//! name as a fallback.
//!
//! # Example `conf.lua`
//!
//! ```lua
//! return {
//!     window = {
//!         title  = "My Game",
//!         width  = 1280,
//!         height = 720,
//!         vsync  = true,
//!     },
//!     -- GPU backend: "auto" | "dx12" | "vulkan" | "metal"
//!     graphics = { backend = "auto", power_preference = "high" },
//! }
//! ```

use crate::engine::log_messages::{
    L050_MODULE_DEP_DISABLED, L051_CONF_READ_ERR, L052_CONF_PARSE_ERR,
};
#[allow(unused_imports)]
use crate::log_msg;
use mlua::prelude::*;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Top-level engine configuration. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Can be populated from `conf.lua` or constructed with defaults.
///
/// # Fields
/// - `window` — Window dimensions, title, vsync, fullscreen, and resize settings.
/// - `graphics` — GPU backend selection and power preference (resolved at engine startup).
/// - `modules` — Flags enabling optional subsystems (audio, physics, graphics, etc.).
/// - `performance` — Frame rate cap.
/// - `identity` — Save directory name (used for persistent game data).
/// - `version` — Target engine version string.
/// - `log_file` — Path to the log file, relative to the game directory.
/// - `log_append` — If `true`, appends to an existing log file instead of truncating it.
/// - `log_level` — Minimum log level written to both stderr and the log file (`"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`). Overrides the build-mode default when set.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub window: WindowConfig,
    pub graphics: GraphicsConfig,
    pub modules: ModulesConfig,
    pub performance: PerformanceConfig,
    pub identity: Option<String>,
    pub version: Option<String>,
    /// Path to the log file, relative to the game directory. Defaults to `"luna2d.log"` in the current working directory.
    pub log_file: Option<String>,
    /// If `true`, appends to an existing log file instead of truncating it on startup.
    pub log_append: bool,
    /// Minimum log level for both stderr and the log file.
    /// Valid values: `"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`.
    /// When `None`, falls back to the build-mode default (debug builds: `debug`, release builds: `error`).
    pub log_level: Option<String>,
}

/// GPU backend and power-preference settings resolved once at engine startup.
///
/// These values are read from `t.graphics` in `conf.lua` and translate directly into
/// [`wgpu::Backends`] and [`wgpu::PowerPreference`] passed to [`wgpu::Instance::new`] and
/// [`wgpu::Instance::request_adapter`] respectively.
///
/// Changing these fields after the GPU has been initialised has no effect.
///
/// # Fields
/// - `backend` — Which graphics API to use. `"auto"` lets wgpu choose the best available
///   backend for the current platform (DX12 on Windows, Metal on macOS, Vulkan on Linux).
///   Valid values: `"auto"`, `"dx12"`, `"vulkan"`, `"metal"`.
/// - `power_preference` — Hint for which physical adapter to prefer when multiple GPUs are
///   present. `"high"` requests the discrete GPU, `"low"` requests the integrated GPU,
///   `"none"` expresses no preference and lets the driver decide.
///   Valid values: `"high"`, `"low"`, `"none"`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphicsConfig {
    pub backend: String,
    pub power_preference: String,
}

/// Window dimensions, title, vsync, fullscreen, and resize settings.
///
/// # Fields
/// - `width` — Window width in pixels.
/// - `height` — Window height in pixels.
/// - `title` — Title bar string.
/// - `vsync` — Enable vertical sync.
/// - `fullscreen` — Launch in fullscreen mode.
/// - `resizable` — Allow the user to resize the window.
/// - `min_width` — Minimum window width (optional).
/// - `min_height` — Minimum window height (optional).
/// - `borderless` — Remove window decorations (title bar, borders).
/// - `icon` — Path to a window icon image, resolved relative to the game directory and applied during startup.
/// - `display_index` — Monitor index for window placement (0 = primary).
/// - `scale_mode` — Viewport scaling mode: `"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`. Default: `"none"`.
/// - `game_width` — Logical game resolution width in virtual pixels. `None` means match window width.
/// - `game_height` — Logical game resolution height in virtual pixels. `None` means match window height.
/// - `maximized` — Start the window maximized. Default: `false`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WindowConfig {
    pub width: u32,
    pub height: u32,
    pub title: String,
    pub vsync: bool,
    pub fullscreen: bool,
    pub resizable: bool,
    pub min_width: Option<u32>,
    pub min_height: Option<u32>,
    pub borderless: bool,
    pub icon: Option<String>,
    pub display_index: u32,
    /// Viewport scaling mode: `"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`.
    pub scale_mode: String,
    /// Logical game resolution width in virtual pixels. `None` means match window width.
    pub game_width: Option<u32>,
    /// Logical game resolution height in virtual pixels. `None` means match window height.
    pub game_height: Option<u32>,
    /// Whether to start the window maximized.
    pub maximized: bool,
}

/// Flags to enable or disable optional engine subsystems.
///
/// All flags default to `true` (all systems on) except `debug`, which defaults to
/// `true` only in debug builds.  Set a flag to `false` in `conf.lua` to skip
/// registering the matching `luna.*` namespace entirely.
///
/// # Fields
/// - `audio` — rodio audio subsystem (`luna.audio`).
/// - `physics` — rapier2d physics world (`luna.physics`).
/// - `graphics` — GPU render pipeline (`luna.gfx`, `luna.font`, `luna.sprite`).
/// - `input` — keyboard / mouse / gamepad input (`luna.input`).
/// - `timer` — frame timer and scheduled callbacks (`luna.time`).
/// - `filesystem` — sandboxed game filesystem (`luna.fs`).
/// - `window` — window state queries (`luna.window`).
/// - `particle` — 2D particle emitters (`luna.particles`).
/// - `image` — CPU-side image manipulation (`luna.img`).
/// - `gui` — retained-mode GUI widgets (`luna.ui`).
/// - `overlay` — fullscreen overlay and post-processing effects (`luna.overlay`, `luna.postfx`).
/// - `tilemap` — tile maps, tile sets, and map generation (`luna.tilemap`).
/// - `scene` — scene stack and transition management (`luna.scene`).
/// - `savegame` — save/load orchestration and schema versioning (`luna.savegame`).
/// - `entity` — lightweight ECS primitives (`luna.entity`).
/// - `ai` — FSMs, behaviour trees, and steering (`luna.ai`, `luna.steering`).
/// - `pathfinding` — A★ and flow-field navigation grids (`luna.pathfinding`).
/// - `thread` — background Rust threads and `Channel` objects (`luna.thread`).
/// - `graph` — directed graphs and flow simulation (`luna.graph`).
/// - `data` — binary data helpers, encoding/compression, and serial (`luna.data`, `luna.codec`).
/// - `compute` — dense numerical arrays and `DataFrame` (`luna.gpu`, `luna.dataframe`).
/// - `minimap` — minimap extraction and FOV masking (`luna.minimap`).
/// - `modding` — mod discovery and load ordering (`luna.modding`).
/// - `pipeline` — data transformation pipelines and pattern helpers (`luna.pipeline`, `luna.patterns`).
/// - `system` — system information queries (`luna.platform`).
/// - `localization` — string localisation tables (`luna.localization`).
/// - `debug` — debug bridge, doc server, and automation helpers (`luna.debug`, `luna.debugbridge`, `luna.docs`, `luna.automation`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModulesConfig {
    pub audio: bool,
    pub physics: bool,
    pub graphics: bool,
    pub input: bool,
    pub timer: bool,
    pub filesystem: bool,
    pub window: bool,
    pub particle: bool,
    pub image: bool,
    pub gui: bool,
    pub overlay: bool,
    pub tilemap: bool,
    pub scene: bool,
    pub savegame: bool,
    pub entity: bool,
    pub ai: bool,
    pub pathfinding: bool,
    pub thread: bool,
    pub graph: bool,
    pub data: bool,
    pub compute: bool,
    pub minimap: bool,
    pub modding: bool,
    pub pipeline: bool,
    pub system: bool,
    pub localization: bool,
    pub debug: bool,
    /// Enable luna.tween sprite animation API.
    pub animation: bool,
    /// Enable luna.camera Camera2D API.
    pub camera: bool,
    /// Enable luna.network UDP networking API.
    pub network: bool,
    /// Enable luna.procgen procedural generation API.
    pub procgen: bool,
    /// Enable luna.raycaster DDA raycaster API.
    pub raycaster: bool,
    /// Enable luna.spine skeletal animation API.
    pub spine: bool,
    /// Enable luna.terminal text-mode terminal emulator API.
    pub terminal: bool,
}

impl ModulesConfig {
    /// Enforces dependency constraints so that a partially-disabled config is never
    /// internally inconsistent.  Call this after reading `conf.lua`.
    ///
    /// Current rules:
    /// - `minimap` requires `graphics` (the minimap samples the render output).
    /// - `particle` requires `graphics` (particles are draw calls).
    /// - `gui` requires `graphics` (widgets render to the GPU surface).
    /// - `overlay` requires `graphics` (overlay and postfx are render passes).
    pub fn validate_and_fix(&mut self) {
        if !self.graphics {
            if self.minimap {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "minimap requires graphics");
                self.minimap = false;
            }
            if self.particle {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "particle requires graphics");
                self.particle = false;
            }
            if self.gui {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "gui requires graphics");
                self.gui = false;
            }
            if self.overlay {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "overlay requires graphics");
                self.overlay = false;
            }
            if self.terminal {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "terminal requires graphics");
                self.terminal = false;
            }
        }
    }
}

/// Frame rate cap and other performance tuning options.
///
/// # Fields
/// - `target_fps` — Desired frames per second for the game loop.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    pub target_fps: u32,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            window: WindowConfig {
                width: 800,
                height: 600,
                title: if cfg!(debug_assertions) {
                    format!("Luna2D v{} [DEBUG]", env!("CARGO_PKG_VERSION"))
                } else {
                    format!("Luna2D v{}", env!("CARGO_PKG_VERSION"))
                },
                vsync: true,
                fullscreen: false,
                resizable: false,
                min_width: None,
                min_height: None,
                borderless: false,
                icon: None,
                display_index: 0,
                scale_mode: "none".to_string(),
                game_width: None,
                game_height: None,
                maximized: false,
            },
            graphics: GraphicsConfig {
                backend: "auto".to_string(),
                power_preference: "high".to_string(),
            },
            modules: ModulesConfig {
                audio: true,
                physics: true,
                graphics: true,
                input: true,
                timer: true,
                filesystem: true,
                window: true,
                particle: true,
                image: true,
                gui: true,
                overlay: true,
                tilemap: true,
                scene: true,
                savegame: true,
                entity: true,
                ai: true,
                pathfinding: true,
                thread: true,
                graph: true,
                data: true,
                compute: true,
                minimap: true,
                modding: true,
                pipeline: true,
                system: true,
                localization: true,
                debug: cfg!(debug_assertions),
                animation: true,
                camera: true,
                network: true,
                procgen: true,
                raycaster: true,
                spine: true,
                terminal: true,
            },
            performance: PerformanceConfig { target_fps: 60 },
            identity: None,
            version: None,
            log_file: None,
            log_append: false,
            log_level: None,
        }
    }
}

impl Config {
    /// Loads engine configuration from `conf.lua` in the game directory.
    ///
    /// If `conf.lua` is absent or contains errors, returns `Config::default()` silently.
    /// The expected format is a Lua file that returns a configuration table:
    /// ```lua
    /// return {
    ///     window = { title = "My Game", width = 1280, height = 720 },
    /// }
    /// ```
    ///
    /// # Parameters
    /// - `game_dir` — Absolute path to the directory containing `conf.lua` (and `main.lua`).
    ///
    /// # Returns
    /// A tuple of `(Config, Option<String>)`. The second element is `Some(msg)` if
    /// `conf.lua` had errors; the returned `Config` still holds usable defaults.
    pub fn load_from_conf_lua(game_dir: &Path) -> (Self, Option<String>) {
        let conf_path = game_dir.join("conf.lua");
        let config = Config::default();

        if !conf_path.exists() {
            return (config, None);
        }

        let code = match std::fs::read_to_string(&conf_path) {
            Ok(c) => c,
            Err(e) => {
                log_msg!(warn, L051_CONF_READ_ERR, "{}", e);
                return (config, Some(format!("Failed to read conf.lua: {}", e)));
            }
        };

        let lua = Lua::new();
        let eval_result = lua.load(&code).set_name("conf.lua").eval::<LuaValue>();
        let config = match eval_result {
            Ok(LuaValue::Table(t)) => Self::read_config_table(&t, config),
            Ok(_) => {
                // conf.lua did not return a table — no config to merge
                config
            }
            Err(e) => {
                log_msg!(warn, L052_CONF_PARSE_ERR, "{}", e);
                return (config, Some(format!("Error in conf.lua: {}", e)));
            }
        };
        (config, None)
    }

    fn read_config_table(t: &LuaTable, default: Config) -> Config {
        let mut config = default;

        if let Ok(window) = t.get::<_, LuaTable>("window") {
            if let Ok(v) = window.get::<_, String>("title") {
                config.window.title = v;
            }
            if let Ok(v) = window.get::<_, u32>("width") {
                config.window.width = v;
            }
            if let Ok(v) = window.get::<_, u32>("height") {
                config.window.height = v;
            }
            if let Ok(v) = window.get::<_, bool>("vsync") {
                config.window.vsync = v;
            }
            if let Ok(v) = window.get::<_, bool>("fullscreen") {
                config.window.fullscreen = v;
            }
            if let Ok(v) = window.get::<_, bool>("resizable") {
                config.window.resizable = v;
            }
            if let Ok(v) = window.get::<_, u32>("minwidth") {
                config.window.min_width = if v > 0 { Some(v) } else { None };
            }
            if let Ok(v) = window.get::<_, u32>("minheight") {
                config.window.min_height = if v > 0 { Some(v) } else { None };
            }
            if let Ok(v) = window.get::<_, bool>("borderless") {
                config.window.borderless = v;
            }
            if let Ok(v) = window.get::<_, String>("icon") {
                config.window.icon = if v.is_empty() { None } else { Some(v) };
            }
            if let Ok(v) = window.get::<_, u32>("displayindex") {
                config.window.display_index = v;
            }
            if let Ok(v) = window.get::<_, String>("scalemode") {
                let v = v.to_lowercase();
                if matches!(v.as_str(), "none" | "letterbox" | "stretch" | "pixel") {
                    config.window.scale_mode = v;
                }
            }
            if let Ok(v) = window.get::<_, u32>("gamewidth") {
                config.window.game_width = if v > 0 { Some(v) } else { None };
            }
            if let Ok(v) = window.get::<_, u32>("gameheight") {
                config.window.game_height = if v > 0 { Some(v) } else { None };
            }
            if let Ok(v) = window.get::<_, bool>("maximized") {
                config.window.maximized = v;
            }
        }

        if let Ok(graphics) = t.get::<_, LuaTable>("graphics") {
            if let Ok(v) = graphics.get::<_, String>("backend") {
                let v = v.to_lowercase();
                if matches!(v.as_str(), "auto" | "dx12" | "vulkan" | "metal") {
                    config.graphics.backend = v;
                }
            }
            if let Ok(v) = graphics.get::<_, String>("power_preference") {
                let v = v.to_lowercase();
                if matches!(v.as_str(), "high" | "low" | "none") {
                    config.graphics.power_preference = v;
                }
            }
        }

        if let Ok(modules) = t.get::<_, LuaTable>("modules") {
            if let Ok(v) = modules.get::<_, bool>("audio") {
                config.modules.audio = v;
            }
            if let Ok(v) = modules.get::<_, bool>("physics") {
                config.modules.physics = v;
            }
            if let Ok(v) = modules.get::<_, bool>("graphics") {
                config.modules.graphics = v;
            }
            if let Ok(v) = modules.get::<_, bool>("input") {
                config.modules.input = v;
            }
            if let Ok(v) = modules.get::<_, bool>("timer") {
                config.modules.timer = v;
            }
            if let Ok(v) = modules.get::<_, bool>("filesystem") {
                config.modules.filesystem = v;
            }
            if let Ok(v) = modules.get::<_, bool>("window") {
                config.modules.window = v;
            }
            if let Ok(v) = modules.get::<_, bool>("particle") {
                config.modules.particle = v;
            }
            if let Ok(v) = modules.get::<_, bool>("image") {
                config.modules.image = v;
            }
            if let Ok(v) = modules.get::<_, bool>("gui") {
                config.modules.gui = v;
            }
            if let Ok(v) = modules.get::<_, bool>("overlay") {
                config.modules.overlay = v;
            }
            if let Ok(v) = modules.get::<_, bool>("tilemap") {
                config.modules.tilemap = v;
            }
            if let Ok(v) = modules.get::<_, bool>("scene") {
                config.modules.scene = v;
            }
            if let Ok(v) = modules.get::<_, bool>("savegame") {
                config.modules.savegame = v;
            }
            if let Ok(v) = modules.get::<_, bool>("entity") {
                config.modules.entity = v;
            }
            if let Ok(v) = modules.get::<_, bool>("ai") {
                config.modules.ai = v;
            }
            if let Ok(v) = modules.get::<_, bool>("pathfinding") {
                config.modules.pathfinding = v;
            }
            if let Ok(v) = modules.get::<_, bool>("thread") {
                config.modules.thread = v;
            }
            if let Ok(v) = modules.get::<_, bool>("graph") {
                config.modules.graph = v;
            }
            if let Ok(v) = modules.get::<_, bool>("data") {
                config.modules.data = v;
            }
            if let Ok(v) = modules.get::<_, bool>("compute") {
                config.modules.compute = v;
            }
            if let Ok(v) = modules.get::<_, bool>("minimap") {
                config.modules.minimap = v;
            }
            if let Ok(v) = modules.get::<_, bool>("modding") {
                config.modules.modding = v;
            }
            if let Ok(v) = modules.get::<_, bool>("pipeline") {
                config.modules.pipeline = v;
            }
            if let Ok(v) = modules.get::<_, bool>("system") {
                config.modules.system = v;
            }
            if let Ok(v) = modules.get::<_, bool>("localization") {
                config.modules.localization = v;
            }
            if let Ok(v) = modules.get::<_, bool>("debug") {
                config.modules.debug = v;
            }
            if let Ok(v) = modules.get::<_, bool>("animation") {
                config.modules.animation = v;
            }
            if let Ok(v) = modules.get::<_, bool>("camera") {
                config.modules.camera = v;
            }
            if let Ok(v) = modules.get::<_, bool>("network") {
                config.modules.network = v;
            }
            if let Ok(v) = modules.get::<_, bool>("procgen") {
                config.modules.procgen = v;
            }
            if let Ok(v) = modules.get::<_, bool>("raycaster") {
                config.modules.raycaster = v;
            }
            if let Ok(v) = modules.get::<_, bool>("spine") {
                config.modules.spine = v;
            }
            if let Ok(v) = modules.get::<_, bool>("terminal") {
                config.modules.terminal = v;
            }
        }

        if let Ok(perf) = t.get::<_, LuaTable>("performance") {
            if let Ok(v) = perf.get::<_, u32>("target_fps") {
                config.performance.target_fps = v;
            }
        }

        if let Ok(v) = t.get::<_, String>("identity") {
            config.identity = if v.is_empty() { None } else { Some(v) };
        }
        if let Ok(v) = t.get::<_, String>("version") {
            config.version = if v.is_empty() { None } else { Some(v) };
        }

        if let Ok(log_tbl) = t.get::<_, LuaTable>("log") {
            if let Ok(v) = log_tbl.get::<_, String>("file") {
                config.log_file = if v.is_empty() { None } else { Some(v) };
            }
            if let Ok(v) = log_tbl.get::<_, bool>("append") {
                config.log_append = v;
            }
            if let Ok(v) = log_tbl.get::<_, String>("level") {
                let v = v.to_lowercase();
                config.log_level = if v.is_empty() { None } else { Some(v) };
            }
        }

        config
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Default values ─────────────────────────────────────────────────────────

    #[test]
    fn default_window_width_800() {
        let c = Config::default();
        assert_eq!(c.window.width, 800);
    }

    #[test]
    fn default_window_height_600() {
        let c = Config::default();
        assert_eq!(c.window.height, 600);
    }

    #[test]
    fn default_title_contains_luna2d() {
        let c = Config::default();
        assert!(c.window.title.contains("Luna2D"));
    }

    #[test]
    fn default_vsync_enabled() {
        let c = Config::default();
        assert!(c.window.vsync);
    }

    #[test]
    fn default_fps_cap_sixty() {
        let c = Config::default();
        assert_eq!(c.performance.target_fps, 60);
    }

    #[test]
    fn default_modules_graphics_enabled() {
        let c = Config::default();
        assert!(c.modules.graphics);
    }

    #[test]
    fn default_identity_none() {
        let c = Config::default();
        assert!(c.identity.is_none());
    }

    // ── Module validation ─────────────────────────────────────────────────────

    #[test]
    fn validate_disables_minimap_when_no_graphics() {
        let mut c = Config::default();
        c.modules.graphics = false;
        c.modules.minimap = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.minimap);
    }

    #[test]
    fn validate_disables_particle_when_no_graphics() {
        let mut c = Config::default();
        c.modules.graphics = false;
        c.modules.particle = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.particle);
    }
}
