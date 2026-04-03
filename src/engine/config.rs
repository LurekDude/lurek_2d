//! Engine and window configuration loaded from `conf.lua`.
//!
//! When the engine starts it looks for a `conf.lua` file in the game directory.
//! If found, it is executed in a minimal Lua VM and the result is read into a [`Config`]
//! struct.  Missing fields fall back to built-in defaults so authors only need to specify
//! the settings they actually want to change.
//!
//! # Structure
//!
//! [`Config`] is the top-level container and contains four nested structs:
//! - [`WindowConfig`] — window geometry, title, display placement, and decoration options.
//! - [`ModulesConfig`] — boolean feature-flags for optional engine subsystems (audio,
//!   physics, graphics, etc.).  Disabling a module avoids the startup cost and prevents
//!   the matching `luna.*` API calls from being registered.
//! - [`PerformanceConfig`] — target frame-rate cap (`fps_cap`).
//!
//! The `identity` field sets the name of the per-user save directory returned by
//! `luna.filesystem.getSaveDirectory()`.  If unset, the engine uses the game directory
//! name as a fallback.
//!
//! # Example `conf.lua`
//!
//! ```lua
//! luna.window.setTitle("My Game")
//! luna.window.setDimensions(1280, 720)
//! luna.window.setFullscreen(false)
//! luna.window.setVsync(true)
//! ```

use mlua::prelude::*;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Top-level engine configuration. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Can be populated from `conf.lua` or constructed with defaults.
///
/// # Fields
/// - `window` — Window dimensions, title, vsync, fullscreen, and resize settings.
/// - `modules` — Flags enabling optional subsystems (audio, physics, graphics, etc.).
/// - `performance` — Frame rate cap.
/// - `identity` — Save directory name (used for persistent game data).
/// - `version` — Target engine version string.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub window: WindowConfig,
    pub modules: ModulesConfig,
    pub performance: PerformanceConfig,
    pub identity: Option<String>,
    pub version: Option<String>,
    /// Path to the log file, relative to the game directory. Defaults to `"luna2d.log"` in the current working directory.
    pub log_file: Option<String>,
    /// If `true`, appends to an existing log file instead of truncating it on startup.
    pub log_append: bool,
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
}

/// Flags to enable or disable optional engine subsystems.
///
/// # Fields
/// - `audio` — Enable the rodio audio subsystem.
/// - `physics` — Enable the physics world subsystem.
/// - `graphics` — Enable the graphics subsystem.
/// - `input` — Enable the input subsystem.
/// - `timer` — Enable the timer subsystem.
/// - `filesystem` — Enable the filesystem subsystem.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModulesConfig {
    pub audio: bool,
    pub physics: bool,
    pub graphics: bool,
    pub input: bool,
    pub timer: bool,
    pub filesystem: bool,
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
            },
            modules: ModulesConfig {
                audio: true,
                physics: true,
                graphics: true,
                input: true,
                timer: true,
                filesystem: true,
            },
            performance: PerformanceConfig { target_fps: 60 },
            identity: None,
            version: None,
            log_file: None,
            log_append: false,
        }
    }
}

impl Config {
    /// Loads engine configuration from `conf.lua` in the game directory.
    ///
    /// If `conf.lua` is absent or contains errors, returns `Config::default()` silently.
    /// The expected Lua pattern is:
    /// ```lua
    /// function luna.conf(t)
    ///     t.window.title = "My Game"
    ///     t.window.width = 1280
    ///     t.window.height = 720
    /// end
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
        let mut config = Config::default();

        if !conf_path.exists() {
            return (config, None);
        }

        let lua = Lua::new();
        let luna = match lua.create_table() {
            Ok(t) => t,
            Err(e) => return (config, Some(format!("Failed to create Lua table: {}", e))),
        };
        if let Err(e) = lua.globals().set("luna", &luna) {
            return (config, Some(format!("Failed to set luna global: {}", e)));
        }

        // Load and execute conf.lua
        let code = match std::fs::read_to_string(&conf_path) {
            Ok(c) => c,
            Err(e) => {
                log::warn!("Failed to read conf.lua: {}", e);
                return (config, Some(format!("Failed to read conf.lua: {}", e)));
            }
        };

        if let Err(e) = lua.load(&code).set_name("conf.lua").exec() {
            log::warn!("Error in conf.lua: {}", e);
            return (config, Some(format!("Error in conf.lua: {}", e)));
        }

        // Call luna.conf(t) if defined
        if let Ok(conf_fn) = luna.get::<_, LuaFunction>("conf") {
            let t = Self::create_config_table(&lua, &config);
            if let Err(e) = conf_fn.call::<_, ()>(t.clone()) {
                log::warn!("Error calling luna.conf(): {}", e);
                return (config, Some(format!("Error calling luna.conf(): {}", e)));
            }
            config = Self::read_config_table(&t, config);
        }

        (config, None)
    }

    fn create_config_table<'a>(lua: &'a Lua, config: &Config) -> LuaTable<'a> {
        let t = lua.create_table().unwrap();

        let window = lua.create_table().unwrap();
        window.set("title", config.window.title.as_str()).unwrap();
        window.set("width", config.window.width).unwrap();
        window.set("height", config.window.height).unwrap();
        window.set("vsync", config.window.vsync).unwrap();
        window.set("fullscreen", config.window.fullscreen).unwrap();
        window.set("resizable", config.window.resizable).unwrap();
        window
            .set("minwidth", config.window.min_width.unwrap_or(0))
            .unwrap();
        window
            .set("minheight", config.window.min_height.unwrap_or(0))
            .unwrap();
        window.set("borderless", config.window.borderless).unwrap();
        window
            .set("icon", config.window.icon.as_deref().unwrap_or(""))
            .unwrap();
        window
            .set("displayindex", config.window.display_index)
            .unwrap();
        t.set("window", window).unwrap();

        let modules = lua.create_table().unwrap();
        modules.set("audio", config.modules.audio).unwrap();
        modules.set("physics", config.modules.physics).unwrap();
        modules.set("graphics", config.modules.graphics).unwrap();
        modules.set("input", config.modules.input).unwrap();
        modules.set("timer", config.modules.timer).unwrap();
        modules
            .set("filesystem", config.modules.filesystem)
            .unwrap();
        t.set("modules", modules).unwrap();

        let perf = lua.create_table().unwrap();
        perf.set("target_fps", config.performance.target_fps)
            .unwrap();
        t.set("performance", perf).unwrap();

        if let Some(ref identity) = config.identity {
            t.set("identity", identity.as_str()).unwrap();
        }
        if let Some(ref version) = config.version {
            t.set("version", version.as_str()).unwrap();
        }

        let log_tbl = lua.create_table().unwrap();
        log_tbl
            .set("file", config.log_file.as_deref().unwrap_or(""))
            .unwrap();
        log_tbl.set("append", config.log_append).unwrap();
        t.set("log", log_tbl).unwrap();

        t
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
        }

        config
    }
}
