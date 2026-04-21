//! Engine configuration loaded from `conf.toml` (preferred) or `conf.lua` (legacy).
//!
//! When the engine starts it looks for `conf.toml` first; if absent it falls back to
//! `conf.lua` for backward compatibility.  Missing fields fall back to built-in
//! defaults so authors only need to specify the settings they actually want to change.
//!
//! # Structure
//!
//! [`Config`] is the top-level container and contains five nested structs:
//! - [`WindowConfig`] — window geometry, title, display placement, and decoration options.
//! - [`GraphicsConfig`] — GPU backend selection and power preference, resolved at startup.
//! - [`ModulesConfig`] — boolean feature-flags for optional engine subsystems (audio,
//!   physics, graphics, etc.).  Disabling a module avoids the startup cost and prevents
//!   the matching `lurek.*` API calls from being registered.
//! - [`PerformanceConfig`] — target frame-rate cap (`fps_cap`).
//!
//! The `identity` field sets the name of the per-user save directory returned by
//! `lurek.filesystem.getSaveDirectory()`.  If unset, the engine uses the game directory
//! name as a fallback.
//!
//! # Example `conf.toml`
//!
//! ```toml
//! [window]
//! title  = "My Game"
//! width  = 1280
//! height = 720
//! vsync  = true
//!
//! # GPU backend: "auto" | "dx12" | "vulkan" | "metal"
//! [graphics]
//! backend = "auto"
//! power_preference = "high"
//! ```

#[allow(unused_imports)]
use crate::log_msg;
use crate::runtime::log_messages::{
    L050_MODULE_DEP_DISABLED, L051_CONF_READ_ERR, L052_CONF_PARSE_ERR,
};
use mlua::prelude::*;
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Top-level engine configuration.
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
    /// Path to the log file, relative to the game directory. Defaults to `"lurek2d.log"` in the current working directory.
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
/// registering the matching `lurek.*` namespace entirely.
///
/// # Fields
/// - `audio` — rodio audio subsystem (`lurek.audio`).
/// - `physics` — rapier2d physics world (`lurek.physics`).
/// - `graphics` — GPU render pipeline (`lurek.renderphic`, `lurek.font`, `lurek.sprite`).
/// - `input` — keyboard / mouse / gamepad input (`lurek.input`).
/// - `timer` — frame timer and scheduled callbacks (`lurek.timer`).
/// - `filesystem` — sandboxed game filesystem (`lurek.filesystem`).
/// - `window` — window state queries (`lurek.window`).
/// - `particle` — 2D particle emitters (`lurek.particle`).
/// - `image` — CPU-side image manipulation (`lurek.image`).
/// - `gui` — retained-mode GUI widgets (`lurek.ui`).
/// - `overlay` — fullscreen overlay and post-processing effects (`lurek.effect`, `lurek.effect`).
/// - `tilemap` — tile maps, tile sets, and map generation (`lurek.tilemap`).
/// - `scene` — scene stack and transition management (`lurek.scene`).
/// - `savegame` — save/load orchestration and schema versioning (`lurek.save`).
/// - `entity` — lightweight ECS primitives (`lurek.ecs`).
/// - `ai` — FSMs, behaviour trees, and steering (`lurek.ai`, `lurek.steering`).
/// - `pathfinding` — A★ and flow-field navigation grids (`lurek.pathfind`).
/// - `thread` — background Rust threads and `Channel` objects (`lurek.thread`).
/// - `graph` — directed graphs and flow simulation (`lurek.graph`).
/// - `data` — binary data helpers, encoding/compression, and serial (`lurek.data`, `lurek.serial`).
/// - `compute` — dense numerical arrays and `DataFrame` (`lurek.compute`, `lurek.dataframe`).
/// - `minimap` — minimap extraction and FOV masking (`lurek.minimap`).
/// - `modding` — mod discovery and load ordering (`lurek.mods`).
/// - `pipeline` — data transformation pipelines and pattern helpers (`lurek.pipeline`, `lurek.patterns`).
/// - `system` — system information queries (`lurek.runtime`).
/// - `localization` — string localisation tables (`lurek.i18n`).
/// - `debug` — debug bridge, doc server, and automation helpers (`lurek.debug`, `lurek.debugbridge`, `lurek.docs`, `lurek.automation`).
#[derive(Debug, Clone, Serialize, Deserialize)]
/// # Fields
/// - `graphics` — See field documentation.
/// - `physics` — See field documentation.
/// - `audio` — See field documentation.
/// - `input` — See field documentation.
/// - `timer` — See field documentation.
/// - `filesystem` — See field documentation.
/// - `gui` — See field documentation.
/// - `scene` — See field documentation.
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
    /// Enable lurek.animation sprite animation API (frame clips, named animations).
    pub animation: bool,
    /// Enable lurek.tween property tweening API (animate any Lua table field).
    pub tween: bool,
    /// Enable lurek.camera Camera2D API.
    pub camera: bool,
    /// Enable lurek.network UDP networking API.
    pub network: bool,
    /// Enable lurek.procgen procedural generation API.
    pub procgen: bool,
    /// Enable lurek.raycaster DDA raycaster API.
    pub raycaster: bool,
    /// Enable lurek.spine skeletal animation API.
    pub spine: bool,
    /// Enable lurek.terminal text-mode terminal emulator API.
    pub terminal: bool,
    /// Enable lurek.parallax multi-layer scrolling background API.
    pub parallax: bool,
    /// Enable lurek.globe Geoscape-style province sphere API.
    pub globe: bool,
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
    /// - `parallax` requires `graphics` (layer scrolling renders to the GPU surface).
    /// - `terminal` requires `graphics` (text-mode terminal renders via the GPU surface).
    /// - `animation` requires `graphics` (frame clips are GPU draw calls).
    /// - `tilemap` requires `graphics` (tile layers are batched GPU draw calls).
    /// - `raycaster` requires `graphics` (DDA output is rendered to a GPU texture).
    /// - `camera` requires `graphics` (Camera2D transforms are applied at the GPU level).
    /// - `globe` requires `graphics` (province sphere renders to the GPU surface).
    /// - `spine` requires `animation` (skeletal animation builds on the animation subsystem).
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
            if self.parallax {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "parallax requires graphics");
                self.parallax = false;
            }
            if self.terminal {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "terminal requires graphics");
                self.terminal = false;
            }
            if self.animation {
                log_msg!(
                    warn,
                    L050_MODULE_DEP_DISABLED,
                    "animation requires graphics"
                );
                self.animation = false;
            }
            if self.tilemap {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "tilemap requires graphics");
                self.tilemap = false;
            }
            if self.raycaster {
                log_msg!(
                    warn,
                    L050_MODULE_DEP_DISABLED,
                    "raycaster requires graphics"
                );
                self.raycaster = false;
            }
            if self.camera {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "camera requires graphics");
                self.camera = false;
            }
            if self.globe {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "globe requires graphics");
                self.globe = false;
            }
            if self.spine {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "spine requires graphics");
                self.spine = false;
            }
        }
        // spine also requires animation (checked after the graphics block so that
        // the graphics-disabled path above already cleared both animation and spine).
        if !self.animation && self.spine {
            log_msg!(warn, L050_MODULE_DEP_DISABLED, "spine requires animation");
            self.spine = false;
        }
    }
}

/// Frame rate cap and other performance tuning options.
///
/// # Fields
/// - `target_fps` — Desired frames per second for the game loop.
/// - `physics_tick_rate` — Fixed tick rate for `process_physics` callback (Hz, default 60).
/// - `fixed_update_tick_rate` — Optional fixed tick rate for the `fixedUpdate` Lua callback (Hz).  `None` disables fixed update.
/// - `frame_budget_warn_ms` — If set, emit a `warn!` log when a frame exceeds this many milliseconds.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    pub target_fps: u32,
    /// Fixed tick rate in Hz for the `process_physics` callback (default 60).
    pub physics_tick_rate: u32,
    /// Optional fixed tick rate in Hz for the `fixedUpdate` Lua callback.  `None` = disabled.
    #[serde(default)]
    pub fixed_update_tick_rate: Option<u32>,
    /// Frame time threshold in milliseconds before a `warn!` is emitted.  `None` = no warning.
    #[serde(default)]
    pub frame_budget_warn_ms: Option<f32>,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            window: WindowConfig {
                width: 800,
                height: 600,
                title: if cfg!(debug_assertions) {
                    format!("Lurek2D v{} [DEBUG]", env!("CARGO_PKG_VERSION"))
                } else {
                    format!("Lurek2D v{}", env!("CARGO_PKG_VERSION"))
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
                tween: true,
                camera: true,
                network: true,
                procgen: true,
                raycaster: true,
                spine: true,
                terminal: true,
                parallax: true,
                globe: true,
            },
            performance: PerformanceConfig {
                target_fps: 60,
                physics_tick_rate: 60,
                fixed_update_tick_rate: None,
                frame_budget_warn_ms: None,
            },
            identity: None,
            version: None,
            log_file: None,
            log_append: false,
            log_level: None,
        }
    }
}

impl Config {
    /// Loads engine configuration from the game directory.
    ///
    /// Tries `conf.toml` first (preferred TOML format), then falls back to `conf.lua`
    /// for backward compatibility.  If neither file exists, returns `Config::default()`.
    ///
    /// # Parameters
    /// - `game_dir` — Absolute path to the directory containing the game files.
    ///
    /// # Returns
    /// A tuple of `(Config, Option<String>)`. The second element is `Some(msg)` if
    /// loading had errors; the returned `Config` still holds usable defaults.
    pub fn load(game_dir: &Path) -> (Self, Option<String>) {
        let toml_path = game_dir.join("conf.toml");
        if toml_path.exists() {
            return Self::load_from_conf_toml(game_dir);
        }
        Self::load_from_conf_lua(game_dir)
    }

    /// Loads engine configuration from `conf.toml` in the game directory.
    ///
    /// The file must be valid TOML whose top-level keys match the [`Config`] struct.
    /// Missing keys fall back to defaults from [`Config::default`].  Nested tables are
    /// merged field-by-field so a `[window]` block with only `title` still keeps the
    /// default `width` and `height`.
    ///
    /// # Parameters
    /// - `game_dir` — Absolute path to the directory containing `conf.toml`.
    ///
    /// # Returns
    /// A tuple of `(Config, Option<String>)`. The second element is `Some(msg)` if
    /// `conf.toml` had errors; the returned `Config` still holds usable defaults.
    pub fn load_from_conf_toml(game_dir: &Path) -> (Self, Option<String>) {
        let conf_path = game_dir.join("conf.toml");
        let default = Config::default();

        if !conf_path.exists() {
            return (default, None);
        }

        let text = match std::fs::read_to_string(&conf_path) {
            Ok(c) => c,
            Err(e) => {
                log_msg!(warn, L051_CONF_READ_ERR, "{}", e);
                return (default, Some(format!("Failed to read conf.toml: {}", e)));
            }
        };

        let override_val = match toml::from_str::<toml::Value>(&text) {
            Ok(v) => v,
            Err(e) => {
                log_msg!(warn, L052_CONF_PARSE_ERR, "{}", e);
                return (default, Some(format!("Error in conf.toml: {}", e)));
            }
        };

        // Merge override on top of serialised defaults so omitted keys keep
        // their default values rather than triggering a serde error.
        let default_text = match toml::to_string(&default) {
            Ok(s) => s,
            Err(_) => return (default, None),
        };
        let mut merged: toml::Value =
            toml::from_str(&default_text).unwrap_or(toml::Value::Table(toml::Table::new()));

        if let (toml::Value::Table(base), toml::Value::Table(over_)) = (&mut merged, override_val) {
            for (k, v) in over_ {
                // Merge nested tables to preserve unspecified defaults within sections.
                if let (Some(toml::Value::Table(base_tbl)), toml::Value::Table(over_tbl)) =
                    (base.get_mut(&k), v.clone())
                {
                    for (sk, sv) in over_tbl {
                        base_tbl.insert(sk, sv);
                    }
                } else {
                    base.insert(k, v);
                }
            }
        }

        match merged.try_into::<Config>() {
            Ok(cfg) => (cfg, None),
            Err(e) => {
                log_msg!(warn, L052_CONF_PARSE_ERR, "{}", e);
                (default, Some(format!("Error in conf.toml: {}", e)))
            }
        }
    }

    /// Loads engine configuration from `conf.lua` in the game directory.
    ///
    /// If `conf.lua` is absent or contains errors, returns `Config::default()` silently.
    /// Prefer `conf.toml` for new games — this loader exists for backward compatibility.
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

        // Set up the `lurek` global so conf.lua can define `function lurek.conf(t)`.
        let lurek_table = match lua.create_table() {
            Ok(t) => t,
            Err(e) => return (config, Some(format!("Lua table creation failed: {e}"))),
        };
        if let Err(e) = lua.globals().set("lurek", lurek_table.clone()) {
            return (config, Some(format!("Failed to set lurek global: {e}")));
        }

        // Execute conf.lua — it either defines `lurek.conf(t)` or returns a table.
        let eval_result = lua.load(&code).set_name("conf.lua").eval::<LuaValue>();

        // Strategy 1: conf.lua returned a table directly → read it.
        if let Ok(LuaValue::Table(t)) = &eval_result {
            return (Self::read_config_table(t, config), None);
        }

        // If eval failed because conf.lua defines a function (no return), try exec.
        // A genuine parse error will also fail here; log a clear fallback notice and
        // continue with defaults so the engine can still reach the error screen.
        if eval_result.is_err() {
            if let Err(e) = lua.load(&code).set_name("conf.lua").exec() {
                log_msg!(warn, L052_CONF_PARSE_ERR, "{}. Using default config.", e);
                return (config, Some(format!("Error in conf.lua: {e}")));
            }
        }

        // Strategy 2: conf.lua defined `function lurek.conf(t)` — call it.
        if let Ok(conf_fn) = lurek_table.get::<_, mlua::Function>("conf") {
            let config_table = match Self::build_config_table(&lua, &config) {
                Ok(t) => t,
                Err(e) => return (config, Some(format!("Failed to build config table: {e}"))),
            };
            if let Err(e) = conf_fn.call::<_, ()>(config_table.clone()) {
                log_msg!(warn, L052_CONF_PARSE_ERR, "{}", e);
                return (config, Some(format!("Error calling lurek.conf: {e}")));
            }
            return (Self::read_config_table(&config_table, config), None);
        }

        // conf.lua evaluated without error but returned nothing and defined no callback.
        (config, None)
    }

    /// Build a Lua table pre-populated with the current config defaults,
    /// suitable for passing to `lurek.conf(t)`.
    fn build_config_table<'a>(lua: &'a Lua, config: &Config) -> mlua::Result<LuaTable<'a>> {
        let t = lua.create_table()?;

        // window sub-table
        let window = lua.create_table()?;
        window.set("title", config.window.title.as_str())?;
        window.set("width", config.window.width)?;
        window.set("height", config.window.height)?;
        window.set("vsync", config.window.vsync)?;
        window.set("fullscreen", config.window.fullscreen)?;
        window.set("resizable", config.window.resizable)?;
        window.set("minwidth", config.window.min_width.unwrap_or(0))?;
        window.set("minheight", config.window.min_height.unwrap_or(0))?;
        window.set("borderless", config.window.borderless)?;
        window.set("icon", config.window.icon.as_deref().unwrap_or(""))?;
        window.set("displayindex", config.window.display_index)?;
        window.set("scalemode", config.window.scale_mode.as_str())?;
        window.set("gamewidth", config.window.game_width.unwrap_or(0))?;
        window.set("gameheight", config.window.game_height.unwrap_or(0))?;
        window.set("maximized", config.window.maximized)?;
        t.set("window", window)?;

        // graphics sub-table
        let graphics = lua.create_table()?;
        graphics.set("backend", config.graphics.backend.as_str())?;
        graphics.set(
            "power_preference",
            config.graphics.power_preference.as_str(),
        )?;
        t.set("graphics", graphics)?;

        // modules sub-table
        let modules = lua.create_table()?;
        modules.set("audio", config.modules.audio)?;
        modules.set("physics", config.modules.physics)?;
        modules.set("graphics", config.modules.graphics)?;
        modules.set("input", config.modules.input)?;
        modules.set("timer", config.modules.timer)?;
        modules.set("filesystem", config.modules.filesystem)?;
        modules.set("window", config.modules.window)?;
        modules.set("particle", config.modules.particle)?;
        modules.set("image", config.modules.image)?;
        modules.set("gui", config.modules.gui)?;
        modules.set("overlay", config.modules.overlay)?;
        modules.set("tilemap", config.modules.tilemap)?;
        modules.set("scene", config.modules.scene)?;
        modules.set("savegame", config.modules.savegame)?;
        modules.set("entity", config.modules.entity)?;
        modules.set("ai", config.modules.ai)?;
        modules.set("pathfinding", config.modules.pathfinding)?;
        modules.set("thread", config.modules.thread)?;
        modules.set("graph", config.modules.graph)?;
        modules.set("data", config.modules.data)?;
        modules.set("compute", config.modules.compute)?;
        modules.set("minimap", config.modules.minimap)?;
        modules.set("modding", config.modules.modding)?;
        modules.set("pipeline", config.modules.pipeline)?;
        modules.set("system", config.modules.system)?;
        modules.set("localization", config.modules.localization)?;
        modules.set("debug", config.modules.debug)?;
        modules.set("animation", config.modules.animation)?;
        modules.set("tween", config.modules.tween)?;
        modules.set("camera", config.modules.camera)?;
        modules.set("network", config.modules.network)?;
        modules.set("procgen", config.modules.procgen)?;
        modules.set("raycaster", config.modules.raycaster)?;
        modules.set("spine", config.modules.spine)?;
        modules.set("terminal", config.modules.terminal)?;
        t.set("modules", modules)?;

        // performance sub-table
        let performance = lua.create_table()?;
        performance.set("target_fps", config.performance.target_fps)?;
        performance.set("physics_tick_rate", config.performance.physics_tick_rate)?;
        t.set("performance", performance)?;

        // top-level fields
        t.set("identity", config.identity.as_deref().unwrap_or(""))?;
        t.set("version", config.version.as_deref().unwrap_or(""))?;

        // log sub-table
        let log_tbl = lua.create_table()?;
        log_tbl.set("file", config.log_file.as_deref().unwrap_or(""))?;
        log_tbl.set("append", config.log_append)?;
        log_tbl.set("level", config.log_level.as_deref().unwrap_or(""))?;
        t.set("log", log_tbl)?;

        Ok(t)
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
            if let Ok(v) = modules.get::<_, bool>("tween") {
                config.modules.tween = v;
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
            if let Ok(v) = perf.get::<_, u32>("physics_tick_rate") {
                if v > 0 {
                    config.performance.physics_tick_rate = v;
                }
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

// Tests migrated to tests/rust/unit/runtime_tests.rs
