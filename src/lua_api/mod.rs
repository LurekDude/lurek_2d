use std::cell::RefCell;
use std::collections::HashSet;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::Arc;

use mlua::prelude::*;
use slotmap::SlotMap;
use winit::window::Window;

use crate::audio::Mixer;
use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ParticleKey, ShaderKey, SpriteBatchKey, TextureKey,
};
use crate::event::EventQueue;
use crate::graphics::gpu_renderer::RenderStats;
use crate::graphics::renderer::{BlendMode, DrawCommand, TextureData};
use crate::graphics::Camera;
use crate::graphics::Canvas;
use crate::graphics::Mesh;
use crate::graphics::Shader;
use crate::input::GamepadState;
use crate::input::KeyboardState;
use crate::input::MouseState;
use crate::input::TouchState;
use crate::particle::ParticleSystem;
use crate::audio::midi::MidiState;
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
        }
    }
}

/// Registers the `luna.ai.*` game AI toolkit API.
pub mod ai_api;
/// Registers the `luna.audio.*` sound playback API.
pub mod audio_api;
/// Registers the `luna.compute.*` array computation API.
pub mod compute_api;
/// Registers the `luna.data.*` binary data, compression, hashing, and encoding API.
pub mod data_api;
/// Registers the `luna.dataframe.*` tabular data API.
pub mod dataframe_api;
/// Registers the `luna.debugbridge.*` TCP debug server API.
pub mod debugbridge_api;
/// Registers the `luna.debug.*` runtime diagnostics and developer tools API.
pub mod debug_api;
/// Registers the `luna.docs.*` documentation management API.
pub mod docs_api;
/// Registers the `luna.entity.*` ECS universe API.
pub mod entity_api;
/// Registers the `luna.event.*` engine control API.
pub mod event_api;
/// Registers the `luna.filesystem.*` sandboxed I/O API.
pub mod filesystem_api;
/// Registers the `luna.graph.*` directed-graph and item-flow simulation API.
pub mod graph_api;
/// Registers the `luna.graphics.*` drawing API.
pub mod graphics_api;
/// Registers Phase 24 `luna.graphics.*` extension types (Light2D, Camera2D, etc.).
pub mod graphics_ext_api;
/// Registers the `luna.image.*` pixel-level image manipulation API.
pub mod image_api;
/// Registers the `luna.log.*` structured game-level logging API.
pub mod log_api;
/// Registers the `luna.localization.*` internationalization API.
pub mod localization_api;
/// Registers the `luna.keyboard.*` and `luna.mouse.*` input API.
pub mod input_api;
/// Registers the `luna.math.*` vector and math helper API.
pub mod math_api;
/// Registers Phase 25 `luna.math.*` extension types (Vec2, Grid, Noise, etc.).
pub mod math_ext_api;
/// Registers the `luna.modding.*` mod management API.
pub mod modding_api;
/// Registers the `luna.particle.*` particle-effects API.
pub mod particle_api;
/// Registers the `luna.pathfinding.*` grid-based pathfinding API.
pub mod pathfinding_api;
/// Registers the `luna.patterns.*` software design patterns API.
pub mod patterns_api;
/// Registers the `luna.physics.*` rigid-body simulation API.
pub mod physics_api;
/// Registers the `luna.minimap.*` minimap API.
pub mod minimap_api;
/// Registers the `luna.dialog.*` dialog sequencer API.
pub mod dialog_api;
/// Registers the `luna.postfx.*` post-processing effects API.
pub mod postfx_api;
/// Registers the `luna.savegame.*` save/load system API.
pub mod savegame_api;
/// Registers the `luna.scene.*` scene stack, registry, data store, and depth-sorter API.
pub mod scene_api;
/// Registers the `luna.sound.*` decoded audio sample manipulation API.
pub mod sound_api;
/// Registers the `luna.system.*` platform query API.
pub mod system_api;
/// Registers the `luna.thread.*` multithreading API.
pub mod thread_api;
/// Re-export thread channel from src/thread.
pub use crate::thread::channel as thread_channel;
/// Re-export thread worker from src/thread.
pub use crate::thread::worker as thread_worker;
/// Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API.
pub mod tilemap_api;
/// Registers the `luna.timer.*` frame-timing API.
pub mod timer_api;
/// UserData type utilities for Luna2D Lua objects.
pub mod lua_types;
/// Registers the `luna.window.*` window management API.
pub mod window_api;

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
/// - `line_width` — Current stroke width for outline draw commands.
/// - `blend_mode` — Current blend mode for draw operations.
/// - `fonts` — Loaded TTF fonts for text rendering.
/// - `active_font` — Index of the currently active font (`None` = use bitmap fallback).
/// - `canvases` — Off-screen render targets (canvases) for compositing.
/// - `gamepads` — Connected gamepad state instances.
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
    /// MIDI SoundFont state for MIDI instrument rendering.
    pub midi_state: MidiState,
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
            line_width: 1.0,
            blend_mode: BlendMode::default(),
            fonts: SlotMap::with_key(),
            active_font: None,
            sprite_batches: SlotMap::with_key(),
            canvases: SlotMap::with_key(),
            particle_systems: SlotMap::with_key(),
            gamepads: Vec::new(),
            gamepad_background_events: false,
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
            midi_state: MidiState::new(),
        }
    }
}

/// Creates and configures the Lua VM, registers all `luna.*` sub-APIs, and returns the ready `Lua` instance.
///
/// # Parameters
/// - `state` — Shared engine state passed (via `Rc<RefCell>` clone) to every Lua closure.
///
/// # Returns
/// `LuaResult<Lua>` — A configured Lua VM with `luna.*` as a global, or a Lua error if any sub-API fails to register.
pub fn create_lua_vm(state: Rc<RefCell<SharedState>>) -> LuaResult<Lua> {
    let lua = Lua::new();

    // Create the luna namespace table
    let luna = lua.create_table()?;

    // Register all sub-APIs
    ai_api::register(&lua, &luna)?;
    graphics_api::register(&lua, &luna, state.clone())?;
    graphics_ext_api::register(&lua, &luna)?;
    input_api::register(&lua, &luna, state.clone())?;
    audio_api::register(&lua, &luna, state.clone())?;
    timer_api::register(&lua, &luna, state.clone())?;
    math_api::register(&lua, &luna)?;
    math_ext_api::register(&lua, &luna)?;
    filesystem_api::register(&lua, &luna, state.clone())?;
    window_api::register(&lua, &luna, state.clone())?;
    physics_api::register(&lua, &luna)?;
    particle_api::register(&lua, &luna, state.clone())?;
    event_api::register(&lua, &luna, state.clone())?;
    system_api::register(&lua, &luna, state.clone())?;
    data_api::register(&lua, &luna)?;
    log_api::register(&lua, &luna)?;
    localization_api::register(&lua, &luna)?;
    image_api::register(&lua, &luna, state.clone())?;
    compute_api::register(&lua, &luna)?;
    dataframe_api::register(&lua, &luna)?;
    debugbridge_api::register(&lua, &luna)?;
    debug_api::register(&lua, &luna)?;
    docs_api::register(&lua, &luna)?;
    graph_api::register(&lua, &luna)?;
    sound_api::register(&lua, &luna, state.clone())?;
    thread_api::register(&lua, &luna)?;
    tilemap_api::register(&lua, &luna)?;
    scene_api::register(&lua, &luna)?;
    pathfinding_api::register(&lua, &luna)?;
    patterns_api::register(&lua, &luna)?;
    minimap_api::register(&lua, &luna)?;
    dialog_api::register(&lua, &luna)?;
    postfx_api::register(&lua, &luna)?;
    entity_api::register(&lua, &luna)?;
    modding_api::register(&lua, &luna, state.clone())?;
    savegame_api::register(&lua, &luna, state.clone())?;

    lua.globals().set("luna", luna)?;

    Ok(lua)
}
