//! Central shared runtime state for the Luna2D engine.
//!
//! [`SharedState`] is the hub that connects every subsystem to every API call.
//! It is created once at startup, wrapped in `Rc<RefCell<SharedState>>`, and
//! cloned into every Lua API closure. The engine event loop also holds a clone.
//!
//! Also defines [`WindowState`], [`FullscreenType`], and [`ErrorInfo`] which are
//! window-management types used by both `engine` and `lua_api`.

use std::collections::HashSet;
use std::path::PathBuf;
use std::sync::Arc;

use slotmap::SlotMap;
use winit::window::Window;

use crate::audio::midi::MidiState;
use crate::audio::Mixer;
use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ParticleKey, ShaderKey, ShapeKey, SpriteBatchKey, TextureKey,
};
use crate::event::EventQueue;
use crate::filesystem::GameFS;
use crate::graphics::gpu_renderer::RenderStats;
use crate::graphics::renderer::{BlendMode, DepthMode, DrawCommand, StencilMode, TextureData};
use crate::camera::Camera;
use crate::graphics::{Canvas, CompoundShape, Mesh, Shader};
use crate::input::{GamepadMappings, GamepadState, KeyboardState, MouseState, TouchState};
use crate::particle::ParticleSystem;
use crate::timer::Clock;

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

/// Shared mutable state passed via `Rc<RefCell<SharedState>>` to all Lua API closures and the engine loop.
///
/// # Fields
/// - `draw_commands` — Queue of pending `DrawCommand` values, flushed each frame.
/// - `current_color` — Active RGBA draw color `[r, g, b, a]`.
/// - `background_color` — Screen clear color set by `luna.graphics.setBackgroundColor`.
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
/// - `quit_requested` — Set to `true` by `luna.event.quit()` to end the game loop.
/// - `exit_code` — Exit code to return when `quit_requested` is `true`.
/// - `restart_requested` — Set to `true` by `luna.event.restart()` to trigger engine restart.
/// - `line_width` — Current stroke width for outline draw commands.
/// - `blend_mode` — Current blend mode for draw operations.
/// - `fonts` — Loaded TTF fonts for text rendering.
/// - `active_font` — Index of the currently active font (`None` = use bitmap fallback).
/// - `canvases` — Off-screen render targets (canvases) for compositing.
/// - `gamepads` — Connected gamepad state instances.
/// - `fs` — Persistent sandboxed `GameFS` instance with mount layer support.
/// - `shapes` — Stores all compound shape instances.
///
/// Shared mutable state accessible by both the engine loop and Lua closures.
pub struct SharedState {
    pub draw_commands: Vec<DrawCommand>,
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
    /// Whether a restart was requested via `luna.event.restart()`.
    pub restart_requested: bool,
    pub line_width: f32,
    /// Current blend mode for draw operations.
    pub blend_mode: BlendMode,
    /// Loaded TTF fonts for text rendering.
    pub fonts: SlotMap<FontKey, crate::graphics::Font>,
    /// Key of the currently active font (`None` = use bitmap fallback).
    pub active_font: Option<FontKey>,
    /// Loaded sprite batches for batched rendering.
    pub sprite_batches: SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch>,
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
    /// Background file loader for async asset loading.
    pub async_loader: Option<crate::filesystem::AsyncLoader>,
    /// Persistent sandboxed filesystem with mount layer support.
    pub fs: GameFS,
    /// MIDI SoundFont state for MIDI instrument rendering.
    pub midi_state: MidiState,
    /// Whether a screenshot capture was requested this frame.
    ///
    /// Set to `true` by `luna.graphics.captureScreenshot`. Cleared after the callback fires.
    pub pending_screenshot: bool,
    /// Active stencil mode — written by `luna.graphics.setStencilMode`, read at render time.
    pub stencil_mode: StencilMode,
    /// Active depth test mode and write-enable flag — written by `luna.graphics.setDepthMode`.
    ///
    /// The first field is the comparison function; the second controls depth writes.
    pub depth_mode: (DepthMode, bool),
}

impl SharedState {
    /// Creates a new `SharedState` with the given window dimensions, title, and game directory.
    ///
    /// All draw state, timers, and input flags are initialised to safe defaults.
    /// The background color defaults to `LUNA_BG` (dark purple).
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
            draw_commands: Vec::new(),
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
            sprite_batches: SlotMap::with_key(),
            canvases: SlotMap::with_key(),
            particle_systems: SlotMap::with_key(),
            gamepads: Vec::new(),
            gamepad_background_events: false,
            gamepad_mappings: GamepadMappings::new(),
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
            async_loader: None,
            fs,
            midi_state: MidiState::new(),
            pending_screenshot: false,
            stencil_mode: StencilMode::default(),
            depth_mode: (DepthMode::Always, false),
        }
    }
}
