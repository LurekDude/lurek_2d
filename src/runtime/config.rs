//! Engine configuration loaded from `conf.toml`.
//!
//! When the engine starts it looks for `conf.toml`; if absent it uses built-in
//! defaults.  Missing fields also fall back to built-in defaults so authors only
//! need to specify the settings they actually want to change.
//!
//! # Structure
//!
//! [`Config`] is the top-level container and contains five nested structs:
//! - [`WindowConfig`] — window geometry, title, display placement, and decoration options.
//! - [`RenderConfig`] — GPU backend selection and power preference, resolved at startup.
//! - [`ModulesConfig`] — boolean feature-flags for optional engine subsystems (audio,
//!   physics, render, etc.).  Disabling a module avoids the startup cost and prevents
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
//! [render]
//! backend = "auto"
//! power_preference = "high"
//! ```

#[allow(unused_imports)]
use crate::log_msg;
use crate::runtime::log_messages::{
    L050_MODULE_DEP_DISABLED, L051_CONF_READ_ERR, L052_CONF_PARSE_ERR,
};
use serde::{Deserialize, Serialize};
use std::path::Path;

/// Top-level engine configuration.
///
/// Loaded from `conf.toml` or constructed with defaults.
///
/// # Fields
/// - `window` — Window dimensions, title, vsync, fullscreen, and resize settings.
/// - `render` — GPU backend selection and power preference (resolved at engine startup).
/// - `modules` — Flags enabling optional subsystems (audio, physics, render, etc.).
/// - `performance` — Frame rate cap.
/// - `identity` — Save directory name (used for persistent game data).
/// - `version` — Target engine version string.
/// - `log_file` — Path to the log file, relative to the game directory.
/// - `log_append` — If `true`, appends to an existing log file instead of truncating it.
/// - `log_level` — Minimum log level written to both stderr and the log file (`"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`). Overrides the build-mode default when set.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub window: WindowConfig,
    pub render: RenderConfig,
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
/// These values are read from `[render]` in `conf.toml` and translate directly into
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
pub struct RenderConfig {
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
/// `true` only in debug builds.  Set a flag to `false` in `conf.toml` to skip
/// registering the matching `lurek.*` namespace entirely.
///
/// # Fields
/// - `audio` — rodio audio subsystem (`lurek.audio`).
/// - `physics` — rapier2d physics world (`lurek.physics`).
/// - `render` — GPU render pipeline (`lurek.render`, `lurek.font`, `lurek.sprite`).
/// - `input` — keyboard / mouse / gamepad input (`lurek.input`).
/// - `timer` — frame timer and scheduled callbacks (`lurek.timer`).
/// - `filesystem` — sandboxed game filesystem (`lurek.filesystem`).
/// - `window` — window state queries (`lurek.window`).
/// - `particle` — 2D particle emitters (`lurek.particle`).
/// - `image` — CPU-side image manipulation (`lurek.image`).
/// - `ui` — retained-mode GUI widgets (`lurek.ui`).
/// - `effect` — fullscreen overlay and post-processing effects (`lurek.effect`).
/// - `tilemap` — tile maps, tile sets, and map generation (`lurek.tilemap`).
/// - `scene` — scene stack and transition management (`lurek.scene`).
/// - `save` — save/load orchestration and schema versioning (`lurek.save`).
/// - `ecs` — lightweight ECS primitives (`lurek.ecs`).
/// - `ai` — FSMs, behaviour trees, and steering (`lurek.ai`, `lurek.steering`).
/// - `pathfind` — A★ and flow-field navigation grids (`lurek.pathfind`).
/// - `thread` — background Rust threads and `Channel` objects (`lurek.thread`).
/// - `graph` — directed graphs and flow simulation (`lurek.graph`).
/// - `data` — binary data helpers, encoding/compression, and serial (`lurek.data`, `lurek.serial`).
/// - `compute` — dense numerical arrays and `DataFrame` (`lurek.compute`, `lurek.dataframe`).
/// - `minimap` — minimap extraction and FOV masking (`lurek.minimap`).
/// - `mods` — mod discovery and load ordering (`lurek.mods`).
/// - `pipeline` — data transformation pipelines and pattern helpers (`lurek.pipeline`, `lurek.patterns`).
/// - `runtime` — system information queries (`lurek.runtime`).
/// - `i18n` — string localisation tables (`lurek.i18n`).
/// - `debug` — debug bridge, doc server, and automation helpers (`lurek.debug`, `lurek.debugbridge`, `lurek.docs`, `lurek.automation`).
#[derive(Debug, Clone, Serialize, Deserialize)]
/// # Fields
/// - `render` — See field documentation.
/// - `physics` — See field documentation.
/// - `audio` — See field documentation.
/// - `input` — See field documentation.
/// - `timer` — See field documentation.
/// - `filesystem` — See field documentation.
/// - `ui` — See field documentation.
/// - `scene` — See field documentation.
pub struct ModulesConfig {
    pub audio: bool,
    pub physics: bool,
    pub render: bool,
    pub input: bool,
    pub timer: bool,
    pub filesystem: bool,
    pub window: bool,
    pub particle: bool,
    pub image: bool,
    pub ui: bool,
    pub effect: bool,
    pub tilemap: bool,
    pub scene: bool,
    pub save: bool,
    pub ecs: bool,
    pub ai: bool,
    pub pathfind: bool,
    pub thread: bool,
    pub graph: bool,
    pub data: bool,
    pub compute: bool,
    pub minimap: bool,
    pub mods: bool,
    pub pipeline: bool,
    pub runtime: bool,
    pub i18n: bool,
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
    /// internally inconsistent.  Call this after loading `conf.toml`.
    ///
    /// Current rules:
    /// - `minimap` requires `render` (the minimap samples the render output).
    /// - `particle` requires `render` (particles are draw calls).
    /// - `ui` requires `render` (widgets render to the GPU surface).
    /// - `effect` requires `render` (overlay and postfx are render passes).
    /// - `parallax` requires `render` (layer scrolling renders to the GPU surface).
    /// - `terminal` requires `render` (text-mode terminal renders via the GPU surface).
    /// - `animation` requires `render` (frame clips are GPU draw calls).
    /// - `tilemap` requires `render` (tile layers are batched GPU draw calls).
    /// - `raycaster` requires `render` (DDA output is rendered to a GPU texture).
    /// - `camera` requires `render` (Camera2D transforms are applied at the GPU level).
    /// - `globe` requires `render` (province sphere renders to the GPU surface).
    /// - `spine` requires `animation` (skeletal animation builds on the animation subsystem).
    pub fn validate_and_fix(&mut self) {
        if !self.render {
            if self.minimap {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "minimap requires render");
                self.minimap = false;
            }
            if self.particle {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "particle requires render");
                self.particle = false;
            }
            if self.ui {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "ui requires render");
                self.ui = false;
            }
            if self.effect {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "effect requires render");
                self.effect = false;
            }
            if self.parallax {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "parallax requires render");
                self.parallax = false;
            }
            if self.terminal {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "terminal requires render");
                self.terminal = false;
            }
            if self.animation {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "animation requires render");
                self.animation = false;
            }
            if self.tilemap {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "tilemap requires render");
                self.tilemap = false;
            }
            if self.raycaster {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "raycaster requires render");
                self.raycaster = false;
            }
            if self.camera {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "camera requires render");
                self.camera = false;
            }
            if self.globe {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "globe requires render");
                self.globe = false;
            }
            if self.spine {
                log_msg!(warn, L050_MODULE_DEP_DISABLED, "spine requires render");
                self.spine = false;
            }
        }
        // spine also requires animation (checked after the render block so that
        // the render-disabled path above already cleared both animation and spine).
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
/// - `lua_callback_timeout_ms` — Optional hard timeout (milliseconds) for any single Lua callback. `None` disables timeout protection.
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
    /// Optional timeout in milliseconds for one Lua callback invocation.
    ///
    /// When set, callbacks that exceed this budget are aborted and surfaced as runtime errors.
    #[serde(default)]
    pub lua_callback_timeout_ms: Option<f32>,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            window: WindowConfig {
                width: 800,
                height: 600,
                title: if cfg!(debug_assertions) {
                    "Lurek2D [DEBUG]".to_string()
                } else {
                    "Lurek2D".to_string()
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
            render: RenderConfig {
                backend: "auto".to_string(),
                power_preference: "high".to_string(),
            },
            modules: ModulesConfig {
                audio: true,
                physics: true,
                render: true,
                input: true,
                timer: true,
                filesystem: true,
                window: true,
                particle: true,
                image: true,
                ui: true,
                effect: true,
                tilemap: true,
                scene: true,
                save: true,
                ecs: true,
                ai: true,
                pathfind: true,
                thread: true,
                graph: true,
                data: true,
                compute: true,
                minimap: true,
                mods: true,
                pipeline: true,
                runtime: true,
                i18n: true,
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
                lua_callback_timeout_ms: None,
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
    /// Tries `conf.toml`; if absent returns `Config::default()`.
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
        (Config::default(), None)
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
}

// Tests migrated to tests/rust/unit/runtime_tests.rs
