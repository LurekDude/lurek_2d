//! Central shared runtime state for the Lurek2D engine.
//!
//! [`SharedState`] is the hub that connects every subsystem to every API call.
//! It is created once at startup, wrapped in `Rc<RefCell<SharedState>>`, and
//! cloned into every Lua API closure. The engine event loop also holds a clone.
//!
//! Also defines [`WindowState`], [`FullscreenType`], and [`ErrorInfo`] which are
//! window-management types used by both `engine` and `lua_api`.

use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::rc::Weak;
use std::sync::Arc;

use slotmap::Key as SlotmapKey;
use slotmap::SlotMap;
use winit::window::Window;

use crate::audio::midi::MidiState;
use crate::audio::Mixer;
use crate::camera::Camera;
use crate::event::EventQueue;
use crate::filesystem::GameFS;
use crate::input::{
    GamepadMappings, GamepadState, GamepadVibrationRequest, KeyboardState, MouseState, TouchState,
};
use crate::light::LightWorld;
use crate::parallax::ParallaxLayer;
use crate::particle::ParticleSystem;
use crate::province::registry::ProvinceRegistry;
use crate::raycaster::RaycasterScene;
use crate::render::gpu_renderer::RenderStats;
use crate::render::renderer::{BlendMode, DepthMode, RenderCommand, StencilMode, TextureData};
use crate::render::{Canvas, CompoundShape, Mesh, Shader};
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ParticleKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use crate::tilemap::TileMap;
use crate::timer::Clock;
use crate::ui::GuiContext;

/// Fullscreen mode type for window management.
///
/// # Variants
/// - `Desktop` — Desktop variant.
/// - `Exclusive` — Exclusive variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum FullscreenType {
    /// Borderless fullscreen (desktop resolution).
    Desktop,
    /// Exclusive fullscreen (takes over display).
    Exclusive,
}

/// Tracks window state and queues window operations for the event loop.
///
/// # Fields
/// - `focused` — `bool`.
/// - `mouse_focused` — `bool`.
/// - `minimized` — `bool`.
/// - `maximized` — `bool`.
/// - `visible` — `bool`.
/// - `dpi_scale` — `f64`.
/// - `position_x` — `i32`.
/// - `position_y` — `i32`.
/// - `pending_title` — `Option<String>`.
/// - `pending_fullscreen` — `Option<bool>`.
/// - `pending_fullscreen_type` — `FullscreenType`.
/// - `pending_position` — `Option<(i32, i32)>`.
/// - `pending_display_index` — `Option<usize>`.
/// - `pending_size` — `Option<(u32, u32)>`.
/// - `pending_minimize` — `bool`.
/// - `pending_maximize` — `bool`.
/// - `pending_restore` — `bool`.
/// - `pending_close` — `bool`.
/// - `pending_attention` — `bool`.
/// - `pending_icon_path` — `Option<String>`.
/// - `vsync_mode` — `i32`.
/// - `pending_vsync` — `Option<i32>`.
/// - `fullscreen` — `bool`.
/// - `fullscreen_type` — `FullscreenType`.
/// - `game_width` — `f32`.
/// - `game_height` — `f32`.
/// - `scale_mode_str` — `String`.
/// - `viewport_scale_x` — `f32`.
/// - `viewport_scale_y` — `f32`.
/// - `viewport_offset_x` — `f32`.
/// - `viewport_offset_y` — `f32`.
/// - `pending_scale_mode` — `Option<String>`.
///
/// Query fields are written by `app.rs` from window events and read by Lua.
/// Pending fields are written by Lua closures and consumed by `app.rs`.
/// # Fields
#[derive(Debug)]
pub struct WindowState {
    // --- Query state (set by app.rs events, read by Lua) ---
    /// Whether the window currently has keyboard focus.
    pub focused: bool,
    /// Whether the mouse cursor is inside the window.
    pub mouse_focused: bool,
    /// Whether the window is minimized.
    pub minimized: bool,
    /// Whether the window is maximized.
    pub maximized: bool,
    /// Whether the window is visible.
    pub visible: bool,
    /// The DPI scale factor of the current display.
    pub dpi_scale: f64,
    /// Window X position in screen coordinates.
    pub position_x: i32,
    /// Window Y position in screen coordinates.
    pub position_y: i32,

    // --- Pending actions (set by Lua, consumed by app.rs) ---
    /// Pending window title change.
    pub pending_title: Option<String>,
    /// Pending fullscreen toggle (Some(true) = enter, Some(false) = exit).
    pub pending_fullscreen: Option<bool>,
    /// Fullscreen type to use when entering fullscreen.
    pub pending_fullscreen_type: FullscreenType,
    /// Pending window position change.
    pub pending_position: Option<(i32, i32)>,
    /// Pending display index request for monitor move.
    pub pending_display_index: Option<usize>,
    /// Pending window size change.
    pub pending_size: Option<(u32, u32)>,
    /// Whether to minimize the window next frame.
    pub pending_minimize: bool,
    /// Whether to maximize the window next frame.
    pub pending_maximize: bool,
    /// Whether to restore the window next frame.
    pub pending_restore: bool,
    /// Whether to close the window next frame.
    pub pending_close: bool,
    /// Whether to request user attention next frame.
    pub pending_attention: bool,
    /// Pending window icon path.
    pub pending_icon_path: Option<String>,
    /// Current VSync mode (1 = Fifo, 0 = Immediate, -1 = Mailbox).
    pub vsync_mode: i32,
    /// Pending VSync mode change.
    pub pending_vsync: Option<i32>,
    /// Whether the window is currently in fullscreen mode.
    pub fullscreen: bool,
    /// The type of fullscreen currently active.
    pub fullscreen_type: FullscreenType,

    // --- Viewport scaling (set from config, recomputed on resize) ---
    /// The game's logical width in virtual pixels (game coordinate space).
    pub game_width: f32,
    /// The game's logical height in virtual pixels (game coordinate space).
    pub game_height: f32,
    /// Active scale mode string: `"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`.
    pub scale_mode_str: String,
    /// Computed horizontal scale factor from game space to window pixels.
    pub viewport_scale_x: f32,
    /// Computed vertical scale factor from game space to window pixels.
    pub viewport_scale_y: f32,
    /// Computed horizontal offset in window pixels for centering the scaled viewport.
    pub viewport_offset_x: f32,
    /// Computed vertical offset in window pixels for centering the scaled viewport.
    pub viewport_offset_y: f32,
    /// Pending scale mode change requested from Lua.
    pub pending_scale_mode: Option<String>,
}

impl Default for WindowState {
    fn default() -> Self {
        Self {
            focused: true,
            mouse_focused: true,
            minimized: false,
            maximized: false,
            visible: true,
            dpi_scale: 1.0,
            position_x: 0,
            position_y: 0,
            pending_title: None,
            pending_fullscreen: None,
            pending_fullscreen_type: FullscreenType::Desktop,
            pending_position: None,
            pending_display_index: None,
            pending_size: None,
            pending_minimize: false,
            pending_maximize: false,
            pending_restore: false,
            pending_close: false,
            pending_attention: false,
            pending_icon_path: None,
            vsync_mode: 1,
            pending_vsync: None,
            fullscreen: false,
            fullscreen_type: FullscreenType::Desktop,
            game_width: 800.0,
            game_height: 600.0,
            scale_mode_str: "none".to_string(),
            viewport_scale_x: 1.0,
            viewport_scale_y: 1.0,
            viewport_offset_x: 0.0,
            viewport_offset_y: 0.0,
            pending_scale_mode: None,
        }
    }
}

/// Structured error information for the last engine error.
///
/// # Fields
/// - `message` — `String`.
/// - `code` — `String`.
/// - `category` — `String`.
/// - `hint` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct ErrorInfo {
    /// Human-readable error message.
    pub message: String,
    /// Stable error code (e.g. "E1001").
    pub code: String,
    /// Error category name (e.g. "runtime").
    pub category: String,
    /// Optional recovery hint.
    pub hint: Option<String>,
}

/// Pending request to save the next rendered screen frame as a PNG.
///
/// # Fields
/// - `path` — `String`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ScreenshotRequest {
    /// Relative destination path inside the game's `save/` directory.
    pub path: String,
}

/// Per-frame callback timing snapshot recorded by the app loop.
///
/// All values are wall-clock milliseconds measured on the CPU for the most
/// recently completed frame.
#[derive(Debug, Clone, Copy, Default)]
pub struct FrameProfile {
    /// App loop tick overhead (input polling, housekeeping) in milliseconds.
    pub app_tick_ms: f32,
    /// App loop update section (`game_update`) in milliseconds.
    pub app_update_ms: f32,
    /// App loop render section (`render` or splash/error render) in milliseconds.
    pub app_render_ms: f32,
    /// App loop total wall-clock frame time in milliseconds.
    pub app_frame_total_ms: f32,
    /// `process_physics` callback total time for the frame.
    pub process_physics_ms: f32,
    /// `fixedUpdate` callback total time for the frame.
    pub fixed_update_ms: f32,
    /// `process(dt)` callback time for the frame.
    pub process_ms: f32,
    /// `process_late(dt)` callback time for the frame.
    pub process_late_ms: f32,
    /// `draw()` callback time for the frame.
    pub draw_ms: f32,
    /// `draw_ui()` callback time for the frame.
    pub draw_ui_ms: f32,
    /// Sum of all callback buckets above.
    pub callback_total_ms: f32,
}

/// Resource-memory accounting snapshot.
///
/// Memory values are approximate byte counts used for budget tracking and
/// diagnostics. Texture and canvas counts are exact by descriptor size; shader
/// and font values are based on in-memory source/atlas payloads.
#[derive(Debug, Clone, Copy, Default)]
pub struct ResourceMemoryStats {
    /// Estimated bytes consumed by loaded textures.
    pub texture_bytes: u64,
    /// Estimated bytes consumed by loaded font atlases.
    pub font_bytes: u64,
    /// Estimated bytes consumed by loaded canvases.
    pub canvas_bytes: u64,
    /// Estimated bytes consumed by shader source + uniform maps.
    pub shader_bytes: u64,
    /// Sum of all tracked resource bytes.
    pub total_bytes: u64,
    /// Configured texture/resource budget (`0` means unlimited).
    pub budget_bytes: u64,
    /// Number of loaded textures.
    pub texture_count: u64,
    /// Number of loaded fonts.
    pub font_count: u64,
    /// Number of loaded canvases.
    pub canvas_count: u64,
    /// Number of loaded shaders.
    pub shader_count: u64,
}

// ─── Physics run configuration sub-domain ──────────────────────────────────

/// Fixed-timestep physics and update configuration, extracted from [`SharedState`]
/// to group physics runtime settings into a single sub-domain struct.
///
/// # Fields
/// - `fixed_dt` — Fixed step in seconds for `process_physics` (default 1/60).
/// - `max_steps` — Maximum sub-steps per frame to guard against spiral-of-death (default 8).
/// - `debug_draw` — Whether the physics debug overlay is enabled.
/// - `fixed_update_dt` — Fixed step in seconds for `fixedUpdate` callback (`0.0` = disabled).
#[derive(Debug, Clone)]
pub struct PhysicsRunConfig {
    /// Fixed time-step for `process_physics` callback, in seconds (default 1/60).
    pub fixed_dt: f64,
    /// Maximum physics sub-steps per frame (spiral-of-death guard). Clamped to 1–64.
    pub max_steps: u32,
    /// Whether the physics debug overlay (AABB + velocity vectors) is enabled.
    ///
    /// Set via `lurek.physics.debugDraw(true)`.
    pub debug_draw: bool,
    /// Fixed time-step for the `fixedUpdate` Lua callback, in seconds.
    ///
    /// `0.0` means the fixed-update loop is disabled.
    pub fixed_update_dt: f64,
}

impl Default for PhysicsRunConfig {
    fn default() -> Self {
        Self {
            fixed_dt: 1.0 / 60.0,
            max_steps: 8,
            debug_draw: false,
            fixed_update_dt: 0.0,
        }
    }
}

/// Shared mutable state passed via `Rc<RefCell<SharedState>>` to all Lua API closures and the engine loop.
///
/// # Fields
/// - `render_commands` — Queue of pending `RenderCommand` values, flushed each frame.
/// - `current_color` — Active RGBA draw color `[r, g, b, a]`.
/// - `background_color` — Screen clear color set by `lurek.graphic.setBackgroundColor`.
/// - `textures` — Loaded texture pixel data, indexed by `Texture::id`.
/// - `keys_down` — Set of currently held key name strings.
/// - `mouse` — Mouse cursor position, button state, scroll, and cursor settings.
/// - `delta_time` — Elapsed time for the current frame in seconds.
/// - `total_time` — Accumulated time since engine start in seconds.
/// - `fps` — Rolling frames-per-second measurement.
/// - `window_width` — Current window width in pixels.
/// - `window_height` — Current window height in pixels.
/// - `window_title` — Current window title string.
/// - `mixer` — The rodio audio mixer managing all sound sources.
/// - `game_dir` — Absolute path to the game directory.
/// - `quit_requested` — Set to `true` by `lurek.signal.quit()` to end the game loop.
/// - `exit_code` — Exit code to return when `quit_requested` is `true`.
/// - `restart_requested` — Set to `true` by `lurek.signal.restart()` to trigger engine restart.
/// - `line_width` — Current stroke width for outline draw commands.
/// - `blend_mode` — Current blend mode for draw operations.
/// - `fonts` — Loaded TTF fonts for text rendering.
/// - `active_font` — Index of the currently active font (`None` = use bitmap fallback).
/// - `canvases` — Off-screen render targets (canvases) for compositing.
/// - `gamepads` — Connected gamepad state instances.
/// - `fs` — Persistent sandboxed `GameFS` instance with mount layer support.
/// - `shapes` — Stores all compound shape instances.
///
/// # Fields
/// Shared mutable state accessible by both the engine loop and Lua closures.
pub struct SharedState {
    pub render_commands: Vec<RenderCommand>,
    pub current_color: [f32; 4],
    pub background_color: [f32; 4],
    pub textures: SlotMap<TextureKey, TextureData>,
    pub released_texture_handles: HashSet<u64>,
    pub keys_down: HashSet<String>,
    /// Mouse cursor position, buttons, scroll, and cursor settings.
    pub mouse: MouseState,
    pub delta_time: f64,
    pub total_time: f64,
    pub fps: f64,
    pub window_width: u32,
    pub window_height: u32,
    pub window_title: String,
    pub mixer: Mixer,
    pub game_dir: PathBuf,
    pub quit_requested: bool,
    pub exit_code: i32,
    /// Whether a restart was requested via `lurek.signal.restart()`.
    pub restart_requested: bool,
    pub line_width: f32,
    /// Current blend mode for draw operations.
    pub blend_mode: BlendMode,
    /// Loaded TTF fonts for text rendering.
    pub fonts: SlotMap<FontKey, crate::render::Font>,
    /// Key of the currently active font (`None` = use default engine font).
    pub active_font: Option<FontKey>,
    /// Built-in bitmap engine font loaded at startup — used when `active_font` is `None`.
    pub default_font: Option<FontKey>,
    /// All 6 built-in bitmap font sizes, indexed by `AVAILABLE_HEIGHTS` order.
    pub default_fonts: [Option<FontKey>; 6],
    /// Loaded sprite batches for batched rendering.
    pub sprite_batches: SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch>,
    /// Off-screen render targets (canvases) for compositing.
    pub canvases: SlotMap<CanvasKey, Canvas>,
    /// Active particle systems.
    pub particle_systems: SlotMap<ParticleKey, ParticleSystem>,
    /// Connected gamepad state instances.
    pub gamepads: Vec<GamepadState>,
    /// Whether gamepad events are received when the window is not focused.
    pub gamepad_background_events: bool,
    /// Stored SDL2 GameControllerDB-format mapping strings keyed by GUID.
    pub gamepad_mappings: GamepadMappings,
    /// Pending vibration requests queued from Lua and consumed by the app loop.
    pub gamepad_vibration_requests: Vec<GamepadVibrationRequest>,
    /// 2D camera controlling the world-to-screen view transform.
    pub camera: Camera,
    /// Visual size of drawn points in pixels.
    pub point_size: f32,
    /// Current transform stack depth (1 = base level).
    pub transform_stack_depth: u32,
    /// Currently active canvas, or `None` for screen.
    pub active_canvas: Option<CanvasKey>,
    /// Per-frame rendering statistics from the last completed frame.
    pub render_stats: RenderStats,
    /// Current scissor clipping rectangle, or `None` if disabled.
    pub scissor: Option<(f32, f32, f32, f32)>,
    /// Color write mask (r, g, b, a). Disabled channels preserve the existing target value.
    pub color_mask: (bool, bool, bool, bool),
    /// Whether wireframe rendering mode is enabled (filled shapes render as outlines).
    pub wireframe: bool,
    /// Default min/mag texture filter mode plus anisotropy level.
    pub default_filter: (String, String, u32),
    /// Loaded custom shaders for GPU rendering.
    pub shaders: SlotMap<ShaderKey, Shader>,
    /// Currently active custom shader, or `None` for default pipeline.
    pub active_shader: Option<ShaderKey>,
    /// Custom geometry meshes for rendering.
    pub meshes: SlotMap<MeshKey, Mesh>,
    /// Compound shape instances for batched primitive drawing.
    pub shapes: SlotMap<ShapeKey, CompoundShape>,
    /// Keyboard state with scancode tracking, key repeat, and text input.
    pub keyboard: KeyboardState,
    /// Active touch points for touchscreen input.
    pub touch: TouchState,
    /// Window state tracking and pending window operations.
    pub window_state: WindowState,
    /// Handle to the winit window, for monitor and video mode queries.
    pub window: Option<Arc<Window>>,
    /// Event queue for polling system and custom events.
    pub event_queue: EventQueue,
    /// Game identity string for filesystem save directory naming.
    pub filesystem_identity: String,
    /// Frame-timing clock for delta, FPS, and average delta.
    pub clock: Clock,
    /// Whether the debug overlay should be visible (toggled via F12 or Lua API).
    pub debug_overlay_enabled: bool,
    /// Last engine error info for structured error reporting.
    pub last_error: Option<ErrorInfo>,
    /// Whether runtime should render shader compile diagnostics on screen.
    pub shader_error_display_enabled: bool,
    /// Most recent shader compile error message from `lurek.graphic.newShader`.
    pub last_shader_compile_error: Option<String>,
    /// Background file loader for async asset loading.
    pub async_loader: Option<crate::filesystem::AsyncLoader>,
    /// Persistent sandboxed filesystem with mount layer support.
    pub fs: GameFS,
    /// MIDI SoundFont state for MIDI instrument rendering.
    pub midi_state: MidiState,
    /// Pending save request for the next fully rendered screen frame.
    ///
    /// Set by `lurek.graphic.saveScreenshot` and consumed after a successful render.
    pub pending_screenshot: Option<ScreenshotRequest>,
    /// Requests a one-shot CPU readback of the next rendered frame.
    ///
    /// Set by `lurek.image.fromScreen()` when no capture is available yet.
    pub pending_screen_capture: bool,
    /// Most recently captured screen pixels converted to `ImageData`.
    ///
    /// Consumed by `lurek.image.fromScreen()` on the next Lua tick.
    pub captured_screen_image: Option<crate::image::ImageData>,
    /// Active stencil mode — written by `lurek.graphic.setStencilMode`, read at render time.
    pub stencil_mode: StencilMode,
    /// Active depth test mode and write-enable flag — written by `lurek.graphic.setDepthMode`.
    ///
    /// The first field is the comparison function; the second controls depth writes.
    pub depth_mode: (DepthMode, bool),
    /// 2D lighting system world containing lights and occluders.
    pub light_world: LightWorld,
    // ─── Physics sub-domain ────────────────────────────────────────────────
    /// Physics and fixed-update runtime configuration (tick rate, debug draw, etc.).
    pub physics_run: PhysicsRunConfig,
    /// Parallax layers registered for engine auto-collection.
    ///
    /// Objects are added here when created via `lurek.parallax.newLayer()`.
    /// The engine iterates these each frame (before the Lua render callback)
    /// and appends their render commands in draw order.  Stale weak refs are
    /// skipped automatically when the Lua userdata is garbage collected.
    pub auto_parallax_layers: Vec<Weak<RefCell<ParallaxLayer>>>,
    /// Tile maps registered for engine auto-collection.
    ///
    /// Objects are added here when created via `lurek.tilemap.newTileMap()`.
    /// The engine collects commands from these before the Lua render callback.
    pub auto_tilemaps: Vec<Weak<RefCell<TileMap>>>,
    /// GUI context registered for engine auto-collection.
    ///
    /// Set when `lurek.ui` is registered.  The engine appends UI render
    /// commands after the Lua `render_ui` callback each frame.
    pub auto_ui_ctx: Option<Weak<RefCell<GuiContext>>>,
    /// Raycaster scene output from the last `buildScene()` call.
    ///
    /// Set by `lurek.raycaster.Raycaster:buildScene()` and cleared at the start
    /// of each frame.  The renderer converts these quads to `DrawTexturedQuad`
    /// commands during the auto-collect phase.
    pub raycaster_output: Option<RaycasterScene>,
    /// Maximum resident texture memory budget in bytes (0 = unlimited).
    ///
    /// When the sum of loaded texture pixel data exceeds this value the engine
    /// evicts the least-recently-used textures during the next `step_timer` tick.
    /// Set via `lurek.runtime.setResourceBudget`.
    pub resource_budget_bytes: u64,
    /// Callback timing snapshot for the most recently completed frame.
    pub frame_profile: FrameProfile,
    /// Monotonically increasing frame counter.  Incremented once per tick in `step_timer`.
    pub frame_counter: u64,
    /// Monotonic revision that increments after each successful conf.toml hot-reload.
    pub config_reload_revision: u64,
    /// Maps each live `TextureKey` to the frame on which it was last drawn.
    ///
    /// Updated by the render loop whenever a texture command is submitted.
    /// Used by `evict_lru_resources` to find the oldest unused textures.
    pub texture_last_used: HashMap<TextureKey, u64>,
    /// Maps each live `CanvasKey` to the frame on which it was last rendered to or drawn from.
    ///
    /// Updated by `touch_canvas`.  Used by `evict_lru_resources` to track canvas recency
    /// even though canvas eviction is not yet automatic (GPU cleanup differs from textures).
    pub canvas_last_used: HashMap<CanvasKey, u64>,
    /// Optional frame-budget warn threshold from conf.toml `[performance].frame_budget_warn_ms`.
    ///
    /// Mirrored from `Config` into `SharedState` on startup and hot-reload so that
    /// `lurek.runtime.getConfig()` can read it without holding a reference to the config.
    pub frame_budget_warn_ms: Option<f32>,
    /// Optional timeout budget in milliseconds for a single Lua callback.
    ///
    /// Mirrored from `Config` and applied by the app callback wrapper.
    pub lua_callback_timeout_ms: Option<f32>,
    /// When `true`, the app loop should trigger a hot-reload of `conf.toml` on the next tick.
    ///
    /// Set by `lurek.runtime.reloadConfig()`.  Consumed and cleared by the app after reload.
    pub pending_config_reload: bool,
    /// Engine-backed province registries indexed by name.
    ///
    /// Used by `lurek.province.*` and optional adapters (`province_map`, `globe`, `minimap`).
    pub province_registries: HashMap<String, ProvinceRegistry>,
    /// Optional active province registry name.
    pub active_province_registry: Option<String>,
}

impl SharedState {
    /// Creates a new `SharedState` with the given window dimensions, title, and game directory.
    ///
    /// All draw state, timers, and input flags are initialised to safe defaults.
    /// The background color defaults to `LUREK_BG` (dark purple).
    ///
    /// # Parameters
    /// - `width` — Window width in pixels.
    /// - `height` — Window height in pixels.
    /// - `title` — Initial window title string.
    /// - `game_dir` — Absolute path to the game directory.
    ///
    /// # Returns
    /// A newly-initialised `SharedState`.
    pub fn new(width: u32, height: u32, title: &str, game_dir: PathBuf) -> Self {
        let fs = GameFS::new(game_dir.clone());
        SharedState {
            render_commands: Vec::new(),
            current_color: [1.0, 1.0, 1.0, 1.0],
            background_color: [0.15, 0.12, 0.25, 1.0],
            textures: SlotMap::with_key(),
            released_texture_handles: HashSet::new(),
            keys_down: HashSet::new(),
            mouse: MouseState::new(),
            delta_time: 0.0,
            total_time: 0.0,
            fps: 0.0,
            window_width: width,
            window_height: height,
            window_title: title.to_string(),
            mixer: Mixer::new(),
            game_dir,
            quit_requested: false,
            exit_code: 0,
            restart_requested: false,
            line_width: 1.0,
            blend_mode: BlendMode::default(),
            fonts: SlotMap::with_key(),
            active_font: None,
            default_font: None,
            default_fonts: [None; 6],
            sprite_batches: SlotMap::with_key(),
            canvases: SlotMap::with_key(),
            particle_systems: SlotMap::with_key(),
            gamepads: Vec::new(),
            gamepad_background_events: false,
            gamepad_mappings: GamepadMappings::new(),
            gamepad_vibration_requests: Vec::new(),
            camera: Camera::default(),
            point_size: 1.0,
            transform_stack_depth: 1,
            active_canvas: None,
            render_stats: RenderStats::default(),
            scissor: None,
            color_mask: (true, true, true, true),
            wireframe: false,
            default_filter: ("nearest".to_string(), "nearest".to_string(), 1),
            shaders: SlotMap::with_key(),
            active_shader: None,
            meshes: SlotMap::with_key(),
            shapes: SlotMap::with_key(),
            keyboard: KeyboardState::new(),
            touch: TouchState::new(),
            window_state: WindowState::default(),
            window: None,
            event_queue: EventQueue::new(),
            filesystem_identity: String::new(),
            clock: Clock::new(),
            debug_overlay_enabled: false,
            last_error: None,
            shader_error_display_enabled: false,
            last_shader_compile_error: None,
            async_loader: None,
            fs,
            midi_state: MidiState::new(),
            pending_screenshot: None,
            pending_screen_capture: false,
            captured_screen_image: None,
            stencil_mode: StencilMode::default(),
            depth_mode: (DepthMode::Always, false),
            light_world: LightWorld::new(),
            physics_run: PhysicsRunConfig::default(),
            auto_parallax_layers: Vec::new(),
            auto_tilemaps: Vec::new(),
            auto_ui_ctx: None,
            raycaster_output: None,
            resource_budget_bytes: 0,
            frame_profile: FrameProfile::default(),
            frame_counter: 0,
            config_reload_revision: 0,
            texture_last_used: HashMap::new(),
            canvas_last_used: HashMap::new(),
            frame_budget_warn_ms: None,
            lua_callback_timeout_ms: None,
            pending_config_reload: false,
            province_registries: HashMap::new(),
            active_province_registry: None,
        }
    }

    /// Advances the clock by one tick and syncs `delta_time`, `total_time`, and `fps`.
    ///
    /// # Returns
    /// `f64` — Frame delta time in seconds.
    pub fn step_timer(&mut self) -> f64 {
        self.frame_counter = self.frame_counter.wrapping_add(1);
        let dt = self.clock.tick();
        self.delta_time = dt;
        self.total_time = self.clock.total();
        self.fps = self.clock.fps();
        if self.resource_budget_bytes > 0 {
            self.evict_lru_resources();
        }
        dt
    }

    /// Records that a texture was used on the current frame.
    ///
    /// Called by the render command loop whenever a `DrawImage` or similar
    /// command references `key`.  Used by `evict_lru_resources` to determine
    /// which textures are safest to evict.
    ///
    /// # Parameters
    /// - `key` — The `TextureKey` that was accessed this frame.
    pub fn touch_texture(&mut self, key: TextureKey) {
        self.texture_last_used.insert(key, self.frame_counter);
    }

    /// Records that a canvas was used on the current frame.
    ///
    /// Call this whenever a canvas is rendered to or drawn from so that
    /// `evict_lru_resources` can rank canvases by recency.
    ///
    /// # Parameters
    /// - `key` — The `CanvasKey` that was accessed this frame.
    pub fn touch_canvas(&mut self, key: CanvasKey) {
        self.canvas_last_used.insert(key, self.frame_counter);
    }

    /// Evicts least-recently-used textures until total resident resource size is within budget.
    ///
    /// Uses [`resource_memory_stats`] to compute the combined byte footprint of textures,
    /// fonts, canvases, and shaders.  If the total exceeds `resource_budget_bytes`, textures
    /// are sorted by their last-used frame (oldest first) and removed one by one until the
    /// budget is met or no more texture candidates remain.
    ///
    /// The method only removes entries from `SharedState::textures`; the corresponding GPU
    /// resources are invalidated during the normal `released_texture_handles` flush at the
    /// start of each frame.
    pub fn evict_lru_resources(&mut self) {
        let stats = self.resource_memory_stats();
        if stats.total_bytes <= self.resource_budget_bytes {
            return;
        }
        let mut over = stats.total_bytes - self.resource_budget_bytes;
        // Pre-allocate with known capacity to avoid repeated reallocation.
        let tex_count = self.textures.len();
        let mut candidates: Vec<(TextureKey, u64)> = Vec::with_capacity(tex_count);
        for k in self.textures.keys() {
            let last = self.texture_last_used.get(&k).copied().unwrap_or(0);
            candidates.push((k, last));
        }
        // Unstable sort is sufficient and avoids extra comparisons for equal timestamps.
        candidates.sort_unstable_by_key(|(_, last)| *last);
        for (key, _) in candidates {
            if over == 0 {
                break;
            }
            if let Some(tex) = self.textures.get(key) {
                let size = (tex.width as u64) * (tex.height as u64) * 4;
                // Mark for GPU release via the existing handle-based mechanism.
                self.released_texture_handles.insert(key.data().as_ffi());
                self.textures.remove(key);
                self.texture_last_used.remove(&key);
                over = over.saturating_sub(size);
            }
        }
    }

    /// Returns a summary of resident resource memory usage.
    ///
    /// # Returns
    /// [`ResourceMemoryStats`] with per-kind byte estimates and object counts.
    /// A `budget_bytes` of `0` means unlimited.
    pub fn resource_memory_stats(&self) -> ResourceMemoryStats {
        let texture_bytes: u64 = self
            .textures
            .values()
            .map(|t| (t.width as u64) * (t.height as u64) * 4)
            .sum();
        let font_bytes: u64 = self
            .fonts
            .values()
            .map(|font| font.atlas_data().0.len() as u64)
            .sum();
        let canvas_bytes: u64 = self
            .canvases
            .values()
            .map(|canvas| (canvas.width as u64) * (canvas.height as u64) * 4)
            .sum();
        let shader_bytes: u64 = self
            .shaders
            .values()
            .map(|shader| {
                let src = shader.source.len() as u64;
                let wrapper = shader.wrapper_source.len() as u64;
                let uniforms_overhead = (shader.uniforms.len() as u64) * 32;
                src + wrapper + uniforms_overhead
            })
            .sum();
        let total_bytes = texture_bytes + font_bytes + canvas_bytes + shader_bytes;

        ResourceMemoryStats {
            texture_bytes,
            font_bytes,
            canvas_bytes,
            shader_bytes,
            total_bytes,
            budget_bytes: self.resource_budget_bytes,
            texture_count: self.textures.len() as u64,
            font_count: self.fonts.len() as u64,
            canvas_count: self.canvases.len() as u64,
            shader_count: self.shaders.len() as u64,
        }
    }

    /// Submits a background file-read request, lazily creating the async loader.
    ///
    /// # Parameters
    /// - `path` — Relative path to the file within the game directory.
    ///
    /// # Returns
    /// `u64` — An opaque handle ID used to poll the load result.
    pub fn request_async_load(&mut self, path: &str) -> crate::runtime::error::EngineResult<u64> {
        let resolved = self.fs.resolve_read_path(path)?;
        if self.async_loader.is_none() {
            self.async_loader = Some(crate::filesystem::AsyncLoader::new());
        }
        let handle = self
            .async_loader
            .as_ref()
            .expect("async_loader initialized above")
            .request_load(resolved);
        Ok(handle.0)
    }

    /// Submits a background file-write request, lazily creating the async loader.
    ///
    /// # Parameters
    /// - `path` — Relative destination path inside `save/`.
    /// - `data` — Payload to write.
    ///
    /// # Returns
    /// `u64` — An opaque handle ID used to poll the write result.
    pub fn request_async_write(
        &mut self,
        path: &str,
        data: Vec<u8>,
    ) -> crate::runtime::error::EngineResult<u64> {
        let resolved = self.fs.resolve_save_path(path)?;
        if self.async_loader.is_none() {
            self.async_loader = Some(crate::filesystem::AsyncLoader::new());
        }
        let handle = self
            .async_loader
            .as_ref()
            .expect("async_loader initialized above")
            .request_write(resolved, data);
        Ok(handle.0)
    }

    /// Loads all 6 embedded bitmap fonts into `fonts` and stores their keys in `default_fonts`.
    ///
    /// Index 3 (14px) becomes `default_font` and `active_font`.
    /// Called once during `init_lua`. Idempotent — does nothing if `default_font` is already set.
    pub fn load_default_fonts(&mut self) {
        if self.default_font.is_some() {
            return;
        }
        let sizes = crate::render::Font::load_all_sizes();
        for (i, (font, _cw, _ch)) in sizes.into_iter().enumerate() {
            let key = self.fonts.insert(font);
            self.default_fonts[i] = Some(key);
            // Index 3 = 14px = default
            if i == 3 {
                self.default_font = Some(key);
                self.active_font = Some(key);
            }
        }
    }

    /// Polls a pending async load and returns the status and optional data.
    ///
    /// # Parameters
    /// - `handle_id` — The opaque handle returned by `request_async_load`.
    ///
    /// # Returns
    /// `(String, Option<String>)` — Status (`"pending"`, `"done"`, or `"error"`) and data.
    pub fn poll_async_load(&self, handle_id: u64) -> (String, Option<String>) {
        use crate::filesystem::{LoadHandle, LoadResult, LoadStatus};
        if let Some(ref loader) = self.async_loader {
            match loader.poll(LoadHandle(handle_id)) {
                LoadStatus::Pending => ("pending".to_string(), None),
                LoadStatus::Done(LoadResult::Ready(bytes)) => (
                    "done".to_string(),
                    Some(String::from_utf8_lossy(&bytes).to_string()),
                ),
                LoadStatus::Done(LoadResult::Error(msg)) => ("error".to_string(), Some(msg)),
            }
        } else {
            ("error".to_string(), None)
        }
    }

    /// Polls a pending async write and returns the status and optional result payload.
    ///
    /// # Parameters
    /// - `handle_id` — The opaque handle returned by `request_async_write`.
    ///
    /// # Returns
    /// `(String, Option<String>)` — Status (`"pending"`, `"done"`, or `"error"`) and payload.
    /// On success the payload is the number of bytes written as a decimal string.
    pub fn poll_async_write(&self, handle_id: u64) -> (String, Option<String>) {
        use crate::filesystem::{LoadHandle, WriteResult, WriteStatus};
        if let Some(ref loader) = self.async_loader {
            match loader.poll_write(LoadHandle(handle_id)) {
                WriteStatus::Pending => ("pending".to_string(), None),
                WriteStatus::Done(WriteResult::Written(bytes)) => {
                    ("done".to_string(), Some(bytes.to_string()))
                }
                WriteStatus::Done(WriteResult::Error(msg)) => ("error".to_string(), Some(msg)),
            }
        } else {
            ("error".to_string(), None)
        }
    }
}

/// Snapshot of renderer statistics for a single frame.
///
/// # Fields
/// - `draw_calls` — `usize`.
/// - `textures` — `usize`.
/// - `fonts` — `usize`.
/// - `canvases` — `usize`.
/// - `texture_memory` — `usize`. RGBA byte estimate.
pub struct RendererStats {
    /// Number of draw commands queued this frame.
    pub draw_calls: usize,
    /// Number of loaded textures.
    pub textures: usize,
    /// Number of loaded fonts.
    pub fonts: usize,
    /// Number of canvases.
    pub canvases: usize,
    /// Estimated total RGBA bytes used by textures.
    pub texture_memory: usize,
}

impl SharedState {
    /// Computes a snapshot of the current renderer statistics.
    ///
    /// # Returns
    /// `RendererStats`.
    pub fn compute_stats(&self) -> RendererStats {
        RendererStats {
            draw_calls: self.render_commands.len(),
            textures: self.textures.len(),
            fonts: self.fonts.len(),
            canvases: self.canvases.len(),
            texture_memory: self
                .textures
                .values()
                .map(|t| (t.width * t.height * 4) as usize)
                .sum(),
        }
    }
}
