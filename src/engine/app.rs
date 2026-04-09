//! Lurek2D application lifecycle using winit 0.30 + wgpu GPU rendering.
//!
//! Uses a `winit` event loop with `GpuRenderer` for hardware-accelerated rendering.
//! The game loop structure (callbacks, SharedState, Lua VM) follows the standard pattern.

use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::Arc;
use std::time::Instant;

use crate::event::EventArg;
use mlua::prelude::*;
use winit::application::ApplicationHandler;
use winit::event::{ElementState, MouseButton, WindowEvent};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::keyboard::PhysicalKey;
use winit::window::{CursorGrabMode, CursorIcon, Window, WindowId};

use crate::engine::debug_overlay::DebugOverlay;
use crate::engine::error_screen::ErrorScreen;
use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, SpriteBatchKey, TextureKey,
};
use crate::engine::shared_state::WindowState;
use crate::engine::{FullscreenType, SharedState};
use crate::graphics::renderer::{DrawCommand, DrawMode, TextureData};
use crate::graphics::GpuRenderer;
use crate::input::keyboard::{winit_key_to_string, winit_scancode_to_string};
use crate::input::{gilrs_axis_to_string, gilrs_button_to_string, SystemCursor};
use crate::lua_api::create_lua_vm;
use slotmap::SlotMap;

use gilrs::{
    Axis as GilrsAxis, Button as GilrsButton, Event as GilrsEvent, EventType as GilrsEventType,
    Gilrs,
};

use super::config::Config;
use crate::engine::log_messages::{
    L003_GAME_LOADED, L006_SPLASH_SCREEN, L007_NO_MAIN_LUA, L010_RENDER_ERROR, L011_LUA_ERROR,
    L016_LUA_VM_INIT_FAIL, L017_MAIN_LUA_READ_FAIL, L021_CLIPBOARD_FAIL, L023_GPU_TEX_TOO_SMALL,
    L024_SURFACE_LOST, L033_GPU_ADAPTER, L034_GPU_TEX_DIM, L035_GPU_INIT, L036_GAMEPAD_CONNECTED,
    L037_GAMEPAD_DISCONNECTED, L038_GILRS_UNAVAILABLE, L039_WINDOW_CLOSE, L040_ICON_LOAD_FAIL,
    L041_ICON_CONV_FAIL, L042_DISPLAY_INDEX_UNAVAIL, L043_DROP_FILE, L044_DROP_GAME,
    L070_SURFACE_NO_READBACK, L071_CURSOR_GRAB_FAIL, L072_CURSOR_GRAB_LOCK_FAIL,
    L073_CURSOR_POS_FAIL, L074_SCREENSHOT_NO_READBACK, L075_SCREENSHOT_SAVE_FAIL,
    L076_SCREENSHOT_ENCODE_FAIL, L077_DRAG_HOVER, L078_DRAG_HOVER_CANCEL, L079_DRAG_DROP_IGNORED,
    L080_GAME_DIR, L081_LOG_FILE, L082_LOG_FILE_FAIL,
};
#[allow(unused_imports)]
use crate::log_msg;

/// Recomputes viewport scale and offset based on game and window dimensions.
///
/// Updates `viewport_scale_x`, `viewport_scale_y`, `viewport_offset_x`, and `viewport_offset_y`
/// on the provided `WindowState` given the current physical window size.
///
/// # Parameters
/// - `ws` — Mutable reference to the window state to update.
/// - `win_w` — Physical window width in pixels.
/// - `win_h` — Physical window height in pixels.
fn recompute_viewport(ws: &mut WindowState, win_w: u32, win_h: u32) {
    let gw = ws.game_width.max(1.0);
    let gh = ws.game_height.max(1.0);
    match ws.scale_mode_str.as_str() {
        "letterbox" => {
            let s = (win_w as f32 / gw).min(win_h as f32 / gh);
            ws.viewport_scale_x = s;
            ws.viewport_scale_y = s;
            ws.viewport_offset_x = (win_w as f32 - gw * s) * 0.5;
            ws.viewport_offset_y = (win_h as f32 - gh * s) * 0.5;
        }
        "stretch" => {
            ws.viewport_scale_x = win_w as f32 / gw;
            ws.viewport_scale_y = win_h as f32 / gh;
            ws.viewport_offset_x = 0.0;
            ws.viewport_offset_y = 0.0;
        }
        "pixel" => {
            let s = ((win_w as f32 / gw).min(win_h as f32 / gh))
                .floor()
                .max(1.0);
            ws.viewport_scale_x = s;
            ws.viewport_scale_y = s;
            ws.viewport_offset_x = (win_w as f32 - gw * s) * 0.5;
            ws.viewport_offset_y = (win_h as f32 - gh * s) * 0.5;
        }
        _ => {
            // "none" — pass-through, no scaling
            ws.viewport_scale_x = 1.0;
            ws.viewport_scale_y = 1.0;
            ws.viewport_offset_x = 0.0;
            ws.viewport_offset_y = 0.0;
        }
    }
}

// ─── Run state machine ──────────────────────────────────────────────────────

/// Tracks whether the engine is running normally, showing an error, or shutting down.
enum RunState {
    /// Normal game execution.
    Running,
    /// An error occurred; the error screen is being displayed.
    Error(ErrorScreen),
    /// The user requested a restart from the error screen.
    Restarting,
}

#[derive(Clone, Copy)]
struct SplashTexture {
    texture_key: TextureKey,
    width: u32,
    height: u32,
}

struct SplashBranding {
    textures: SlotMap<TextureKey, TextureData>,
    large_icon: SplashTexture,
    banner: SplashTexture,
}

fn splash_window_title(base_title: &str) -> String {
    format!("{} v{}", base_title, env!("CARGO_PKG_VERSION"))
}

fn fit_contain_size(src_w: u32, src_h: u32, max_w: f32, max_h: f32) -> (f32, f32) {
    let src_w = src_w.max(1) as f32;
    let src_h = src_h.max(1) as f32;
    let scale = (max_w.max(1.0) / src_w).min(max_h.max(1.0) / src_h);
    (src_w * scale, src_h * scale)
}

// ─── Lurek2D Application handler ──────────────────────────────────────────────

/// Lurek2D application state managed by the winit event loop.
struct LunaApp {
    config: Config,
    game_dir: PathBuf,

    // Initialised in `resumed()`.
    window: Option<Arc<Window>>,
    surface: Option<wgpu::Surface<'static>>,
    surface_format: wgpu::TextureFormat,
    surface_alpha_mode: wgpu::CompositeAlphaMode,
    surface_present_modes: Vec<wgpu::PresentMode>,
    surface_present_mode: wgpu::PresentMode,
    surface_usage: wgpu::TextureUsages,
    renderer: Option<GpuRenderer>,

    // Lua runtime.
    lua: Option<Lua>,
    state: Option<Rc<RefCell<SharedState>>>,
    has_game: bool,

    // Frame-rate limiting.
    last_frame: Instant,

    // Main-loop pipeline state.
    /// `true` after the `ready` callback has fired for the first time.
    ready_fired: bool,
    /// Accumulator for fixed-timestep `process_physics` callbacks (seconds).
    physics_accumulator: f64,

    // Input tracking for keypressed / keyreleased callbacks.
    prev_mouse: [bool; 5],
    mouse_x: f32,
    mouse_y: f32,

    // Gamepad hardware polling via gilrs.
    gilrs: Option<Gilrs>,

    /// Current engine run state (normal, error, or restarting).
    run_state: RunState,

    /// Debug overlay showing FPS and draw call count.
    debug_overlay: DebugOverlay,

    /// Error message from conf.lua loading, displayed after window opens.
    conf_error: Option<String>,

    /// True when the game_dir was explicitly passed as a CLI argument.
    explicit_game_dir: bool,

    /// Current window VSync mode (1 = Fifo/vsync, 0 = no-vsync, -1 = Mailbox when supported).
    window_vsync_mode: i32,

    /// Lazily-initialised TTF fonts shared by both the splash and error screens.
    ///
    /// Tuple: (font_store, title_key at 36 pt, body_key at 18 pt).
    engine_fonts: Option<(SlotMap<FontKey, crate::graphics::Font>, FontKey, FontKey)>,

    /// Cached embedded PNG branding used by the no-game splash screen.
    splash_branding: Option<SplashBranding>,

    /// Prevents retrying splash branding decode every frame after a load failure.
    splash_branding_failed: bool,

    /// Tracks whether any Ctrl modifier (left or right) is currently held.
    ///
    /// Updated by `ModifiersChanged` events so that the error screen key handler can
    /// detect Ctrl+C without relying on `SharedState` (which may be `None`).
    ctrl_held: bool,

    /// `false` until the first `RedrawRequested` triggers `init_lua()`, ensuring
    /// the splash frame is visible before the Lua VM blocks the event loop.
    lua_initialized: bool,

    /// Whether a file or folder is currently being dragged over the window.
    drag_hover: bool,

    /// Maximum allowed surface dimension from GPU limits.
    max_surface_dim: u32,

    /// Reusable command buffer for viewport-wrapped draw commands; avoids per-frame allocation.
    render_cmd_buf: Vec<DrawCommand>,

    /// If `Some`, write an auto-screenshot PNG to this absolute path and quit.
    auto_screenshot_path: Option<PathBuf>,
    /// Minimum number of rendered game frames to wait before capturing (default 3).
    auto_screenshot_frames: u32,
    /// `true` once the auto-screenshot has been written (prevents double-capture).
    auto_screenshot_done: bool,
    /// Count of rendered game frames since `has_game` became `true`.
    auto_screenshot_frame_count: u32,
    /// Wall-clock time when the first game frame started (used as a safety-exit deadline).
    auto_screenshot_start: Option<Instant>,
}

impl LunaApp {
    fn new(
        config: Config,
        game_dir: PathBuf,
        conf_error: Option<String>,
        explicit_game_dir: bool,
        auto_screenshot_path: Option<PathBuf>,
        auto_screenshot_frames: u32,
    ) -> Self {
        let window_vsync_mode = if config.window.vsync { 1 } else { 0 };

        LunaApp {
            config,
            game_dir,
            window: None,
            surface: None,
            surface_format: wgpu::TextureFormat::Bgra8UnormSrgb,
            surface_alpha_mode: wgpu::CompositeAlphaMode::Auto,
            surface_present_modes: Vec::new(),
            surface_present_mode: wgpu::PresentMode::Fifo,
            surface_usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
            renderer: None,
            lua: None,
            state: None,
            has_game: false,
            last_frame: Instant::now(),
            ready_fired: false,
            physics_accumulator: 0.0,
            prev_mouse: [false; 5],
            mouse_x: 0.0,
            mouse_y: 0.0,
            gilrs: None,
            run_state: RunState::Running,
            debug_overlay: DebugOverlay::new(),
            conf_error,
            explicit_game_dir,
            window_vsync_mode,
            engine_fonts: None,
            splash_branding: None,
            splash_branding_failed: false,
            ctrl_held: false,
            lua_initialized: false,
            drag_hover: false,
            max_surface_dim: 4096,
            render_cmd_buf: Vec::new(),
            auto_screenshot_path,
            auto_screenshot_frames,
            auto_screenshot_done: false,
            auto_screenshot_frame_count: 0,
            auto_screenshot_start: None,
        }
    }

    fn wants_splash_screen(&self) -> bool {
        !self.explicit_game_dir && !self.game_dir.join("main.lua").exists()
    }

    fn current_window_title(&self) -> String {
        if self.wants_splash_screen() {
            splash_window_title(&self.config.window.title)
        } else {
            self.config.window.title.clone()
        }
    }

    fn resolve_present_mode(
        available_modes: &[wgpu::PresentMode],
        requested_mode: i32,
    ) -> (wgpu::PresentMode, i32) {
        let supports = |mode| available_modes.contains(&mode);

        match requested_mode {
            -1 if supports(wgpu::PresentMode::Mailbox) => {
                return (wgpu::PresentMode::Mailbox, -1);
            }
            0 if supports(wgpu::PresentMode::Immediate) => {
                return (wgpu::PresentMode::Immediate, 0);
            }
            _ if supports(wgpu::PresentMode::Fifo) => {
                return (wgpu::PresentMode::Fifo, 1);
            }
            _ => {}
        }

        if requested_mode == 0 && supports(wgpu::PresentMode::AutoNoVsync) {
            return (wgpu::PresentMode::AutoNoVsync, 0);
        }

        if requested_mode != 0 && supports(wgpu::PresentMode::AutoVsync) {
            return (wgpu::PresentMode::AutoVsync, 1);
        }

        if supports(wgpu::PresentMode::Immediate) {
            return (wgpu::PresentMode::Immediate, 0);
        }

        if supports(wgpu::PresentMode::Mailbox) {
            return (wgpu::PresentMode::Mailbox, -1);
        }

        if supports(wgpu::PresentMode::Fifo) {
            return (wgpu::PresentMode::Fifo, 1);
        }

        if requested_mode == 0 {
            (wgpu::PresentMode::AutoNoVsync, 0)
        } else {
            (wgpu::PresentMode::AutoVsync, 1)
        }
    }

    /// Clamps surface dimensions to the GPU's maximum texture size, ensuring wgpu never panics.
    ///
    /// # Parameters
    /// - `w` — Requested width in physical pixels.
    /// - `h` — Requested height in physical pixels.
    ///
    /// # Returns
    /// `(u32, u32)` clamped width and height, each at least 1.
    fn clamp_surface_dims(&self, w: u32, h: u32) -> (u32, u32) {
        let m = self.max_surface_dim.max(1);
        (w.max(1).min(m), h.max(1).min(m))
    }

    fn surface_configuration(&self, width: u32, height: u32) -> wgpu::SurfaceConfiguration {
        wgpu::SurfaceConfiguration {
            usage: self.surface_usage,
            format: self.surface_format,
            width,
            height,
            present_mode: self.surface_present_mode,
            alpha_mode: self.surface_alpha_mode,
            view_formats: vec![],
            desired_maximum_frame_latency: 2,
        }
    }

    fn apply_vsync_mode(&mut self, requested_mode: i32) {
        let (present_mode, vsync_mode) =
            Self::resolve_present_mode(&self.surface_present_modes, requested_mode);

        self.surface_present_mode = present_mode;
        self.window_vsync_mode = vsync_mode;
        self.config.window.vsync = vsync_mode != 0;

        if let Some(state) = &self.state {
            state.borrow_mut().window_state.vsync_mode = vsync_mode;
        }

        self.reconfigure_surface();
    }

    fn init_gpu(&mut self, window: Arc<Window>) {
        let t0 = Instant::now();
        let width = self.config.window.width;
        let height = self.config.window.height;

        // Resolve graphics backend from conf.lua (t.graphics.backend).
        // Falls back to WGPU_BACKEND env var, then to the platform-native primary backend.
        let backends = wgpu::util::backend_bits_from_env().unwrap_or(
            match self.config.graphics.backend.as_str() {
                "dx12" => wgpu::Backends::DX12,
                "vulkan" => wgpu::Backends::VULKAN,
                "metal" => wgpu::Backends::METAL,
                _ => wgpu::Backends::PRIMARY, // "auto" or any unrecognised value
            },
        );

        // Resolve power preference from conf.lua (t.graphics.power_preference).
        let power_preference = match self.config.graphics.power_preference.as_str() {
            "low" => wgpu::PowerPreference::LowPower,
            "none" => wgpu::PowerPreference::None,
            _ => wgpu::PowerPreference::HighPerformance, // "high" or any unrecognised value
        };

        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends,
            ..Default::default()
        });

        // SAFETY: The surface lifetime is tied to the Arc<Window> which outlives the surface.
        let surface: wgpu::Surface<'static> = instance
            .create_surface(Arc::clone(&window))
            .expect("Failed to create wgpu surface");

        let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference,
            compatible_surface: Some(&surface),
            force_fallback_adapter: false,
        }))
        .expect("No compatible GPU adapter found. Try installing a display driver.");

        let adapter_info = adapter.get_info();
        log_msg!(
            info,
            L033_GPU_ADAPTER,
            "{} ({:?}, {:?}) [backend={}, power={}]",
            adapter_info.name,
            adapter_info.backend,
            adapter_info.device_type,
            self.config.graphics.backend,
            self.config.graphics.power_preference,
        );

        let (device, queue) = pollster::block_on(adapter.request_device(
            &wgpu::DeviceDescriptor {
                label: Some("Lurek2D Device"),
                required_features: wgpu::Features::empty(),
                required_limits: wgpu::Limits::downlevel_defaults(),
                memory_hints: Default::default(),
            },
            None,
        ))
        .expect("Failed to create wgpu device");

        let caps = surface.get_capabilities(&adapter);
        let surface_format = caps
            .formats
            .iter()
            .copied()
            .find(|f| f.is_srgb())
            .unwrap_or(caps.formats[0]);

        self.surface_format = surface_format;
        self.surface_alpha_mode = caps.alpha_modes[0];
        self.surface_present_modes = caps.present_modes.clone();
        self.surface_usage = if caps.usages.contains(wgpu::TextureUsages::COPY_SRC) {
            wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::COPY_SRC
        } else {
            log_msg!(warn, L070_SURFACE_NO_READBACK);
            wgpu::TextureUsages::RENDER_ATTACHMENT
        };
        (self.surface_present_mode, self.window_vsync_mode) =
            Self::resolve_present_mode(&self.surface_present_modes, self.window_vsync_mode);

        // Read GPU limits and store the max surface dimension to prevent surface configure panics.
        self.max_surface_dim = device.limits().max_texture_dimension_2d;
        log_msg!(info, L034_GPU_TEX_DIM, "{}", self.max_surface_dim);

        let (cw, ch) = self.clamp_surface_dims(width, height);
        if cw != width || ch != height {
            log_msg!(
                warn,
                L023_GPU_TEX_TOO_SMALL,
                "initial window {}x{} exceeds GPU max {}; clamping to {}x{}",
                width,
                height,
                self.max_surface_dim,
                cw,
                ch
            );
        }
        surface.configure(&device, &self.surface_configuration(cw, ch));

        let renderer = GpuRenderer::new(device, queue, surface_format, cw, ch);

        self.surface = Some(surface);
        self.renderer = Some(renderer);
        self.window = Some(window);
        log_msg!(
            info,
            L035_GPU_INIT,
            "{:.0?} (format={:?}, present={:?}, {}x{})",
            t0.elapsed(),
            surface_format,
            self.surface_present_mode,
            width,
            height,
        );
    }

    fn init_lua(&mut self) {
        // Reset per-game pipeline state.
        self.ready_fired = false;
        self.physics_accumulator = 0.0;

        // Show conf.lua error if present
        if let Some(conf_err) = self.conf_error.take() {
            self.run_state = RunState::Error(ErrorScreen::from_error(&format!(
                "Configuration Error\n{}",
                conf_err
            )));
        }

        let window_title = self.current_window_title();
        if let Some(window) = &self.window {
            window.set_title(&window_title);
        }

        let mut shared_state = SharedState::new(
            self.config.window.width,
            self.config.window.height,
            &window_title,
            self.game_dir.clone(),
        );
        if let Some(identity) = &self.config.identity {
            shared_state.filesystem_identity = identity.clone();
        }
        shared_state.window_state.vsync_mode = self.window_vsync_mode;
        shared_state.window = self.window.as_ref().map(Arc::clone);
        shared_state.physics_fixed_dt =
            1.0 / self.config.performance.physics_tick_rate.max(1) as f64;

        // Initialize viewport state from config.
        {
            let ws = &mut shared_state.window_state;
            ws.game_width = self
                .config
                .window
                .game_width
                .unwrap_or(self.config.window.width) as f32;
            ws.game_height = self
                .config
                .window
                .game_height
                .unwrap_or(self.config.window.height) as f32;
            ws.scale_mode_str = self.config.window.scale_mode.clone();
            let (ww, wh) = (shared_state.window_width, shared_state.window_height);
            recompute_viewport(ws, ww, wh);
        }

        let state = Rc::new(RefCell::new(shared_state));

        // Load the embedded OpenSans default font before Lua starts — all lurek.gfx.print()
        // calls without an active font will use this instead of the bitmap fallback.
        state.borrow_mut().load_default_font();

        let lua = match create_lua_vm(state.clone(), &self.config.modules) {
            Ok(l) => l,
            Err(e) => {
                log_msg!(error, L016_LUA_VM_INIT_FAIL, "{}", e);
                self.run_state = RunState::Error(ErrorScreen::from_error(&format!(
                    "Lua VM Initialization Failed\n{}",
                    e
                )));
                self.state = Some(state);
                return;
            }
        };

        let main_lua = self.game_dir.join("main.lua");
        if main_lua.exists() {
            log_msg!(info, L003_GAME_LOADED, "{}", main_lua.display());
            match std::fs::read_to_string(&main_lua) {
                Ok(code) => {
                    if let Err(e) = lua.load(&code).set_name("main.lua").exec() {
                        log_msg!(error, L011_LUA_ERROR, "main.lua: {}", e);
                        self.run_state = RunState::Error(ErrorScreen::from_lua_error(&e));
                    } else {
                        if let Err(e) = call_lua_callback_checked(&lua, "init", ()) {
                            self.run_state = RunState::Error(try_errorhandler_or_screen(&lua, &e));
                        }
                        self.has_game = true;
                    }
                }
                Err(e) => {
                    log_msg!(error, L017_MAIN_LUA_READ_FAIL, "{}", e);
                    self.run_state = RunState::Error(ErrorScreen::from_error(&format!(
                        "Failed to read main.lua\n{}",
                        e
                    )));
                }
            }
        } else if self.explicit_game_dir {
            // Explicitly passed a directory but it has no main.lua
            let msg = format!("No game found\nNo main.lua at: {}", self.game_dir.display());
            log_msg!(warn, L007_NO_MAIN_LUA, "{}", self.game_dir.display());
            self.run_state = RunState::Error(ErrorScreen::from_error(&msg));
        } else {
            log_msg!(info, L006_SPLASH_SCREEN);
        }

        self.lua = Some(lua);
        self.state = Some(state);
    }

    fn tick_frame(&mut self) {
        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            let dt = st.clock.tick();
            st.delta_time = dt;
            st.total_time = st.clock.total();
            st.fps = st.clock.fps();
            st.keyboard.begin_frame();
            st.mouse.begin_frame();

            // Sync debug overlay state from Lua.
            self.debug_overlay.enabled = st.debug_overlay_enabled;
        }

        self.apply_pending_window_actions();
    }

    fn apply_pending_window_actions(&mut self) {
        let window = match &self.window {
            Some(w) => w.clone(),
            None => return,
        };
        let state = match &self.state {
            Some(s) => s.clone(),
            None => return,
        };

        // Extract all pending actions while holding the borrow, then drop before applying.
        let (
            pending_title,
            pending_fullscreen,
            pending_fullscreen_type,
            pending_position,
            pending_size,
            pending_minimize,
            pending_maximize,
            pending_restore,
            pending_attention,
            pending_icon_path,
            pending_vsync,
            pending_close,
            text_input_enabled,
            mouse_visible,
            mouse_grabbed,
            mouse_relative_mode,
            mouse_cursor,
            pending_cursor_position,
            pending_scale_mode,
        ) = {
            let mut st = state.borrow_mut();
            (
                st.window_state.pending_title.take(),
                st.window_state.pending_fullscreen.take(),
                st.window_state.pending_fullscreen_type,
                st.window_state.pending_position.take(),
                st.window_state.pending_size.take(),
                std::mem::take(&mut st.window_state.pending_minimize),
                std::mem::take(&mut st.window_state.pending_maximize),
                std::mem::take(&mut st.window_state.pending_restore),
                std::mem::take(&mut st.window_state.pending_attention),
                st.window_state.pending_icon_path.take(),
                st.window_state.pending_vsync.take(),
                std::mem::take(&mut st.window_state.pending_close),
                st.keyboard.has_text_input(),
                st.mouse.is_visible(),
                st.mouse.is_grabbed(),
                st.mouse.get_relative_mode(),
                st.mouse.get_cursor(),
                st.mouse.take_pending_position(),
                st.window_state.pending_scale_mode.take(),
            )
        };

        // Apply pending title
        if let Some(title) = pending_title {
            window.set_title(&title);
            state.borrow_mut().window_title = title;
        }

        // Apply pending fullscreen
        if let Some(fullscreen) = pending_fullscreen {
            if fullscreen {
                use winit::window::Fullscreen;
                match pending_fullscreen_type {
                    FullscreenType::Desktop => {
                        window.set_fullscreen(Some(Fullscreen::Borderless(None)));
                    }
                    FullscreenType::Exclusive => {
                        if let Some(monitor) = window.current_monitor() {
                            if let Some(mode) = monitor.video_modes().next() {
                                window.set_fullscreen(Some(Fullscreen::Exclusive(mode)));
                            }
                        }
                    }
                }
                state.borrow_mut().window_state.fullscreen = true;
                state.borrow_mut().window_state.fullscreen_type = pending_fullscreen_type;
            } else {
                window.set_fullscreen(None);
                state.borrow_mut().window_state.fullscreen = false;
            }
        }

        // Apply pending position
        if let Some((x, y)) = pending_position {
            window.set_outer_position(winit::dpi::PhysicalPosition::new(x, y));
        }

        // Apply pending size
        if let Some((w, h)) = pending_size {
            let _ = window.request_inner_size(winit::dpi::PhysicalSize::new(w, h));
        }

        // Apply pending minimize/maximize/restore
        if pending_minimize {
            window.set_minimized(true);
        }
        if pending_maximize {
            window.set_maximized(true);
        }
        if pending_restore {
            window.set_minimized(false);
            window.set_maximized(false);
        }

        // Apply pending attention
        if pending_attention {
            window.request_user_attention(Some(winit::window::UserAttentionType::Informational));
        }

        // Apply pending icon
        if let Some(icon_path) = pending_icon_path {
            let icon = {
                let st = state.borrow();
                load_window_icon(&st.game_dir, &icon_path)
            };
            if let Some(icon) = icon {
                window.set_window_icon(Some(icon));
            }
        }

        if let Some(vsync_mode) = pending_vsync {
            self.apply_vsync_mode(vsync_mode);
        }

        window.set_ime_allowed(text_input_enabled);

        let requested_grab_mode = if mouse_relative_mode {
            CursorGrabMode::Locked
        } else if mouse_grabbed {
            CursorGrabMode::Confined
        } else {
            CursorGrabMode::None
        };

        if let Err(error) = window.set_cursor_grab(requested_grab_mode) {
            if mouse_relative_mode {
                if let Err(confined_error) = window.set_cursor_grab(CursorGrabMode::Confined) {
                    log_msg!(debug, L071_CURSOR_GRAB_FAIL, "{}", confined_error);
                }
            } else if mouse_grabbed {
                log_msg!(debug, L072_CURSOR_GRAB_LOCK_FAIL, "{}", error);
            }
        }

        window.set_cursor_visible(if mouse_relative_mode {
            false
        } else {
            mouse_visible
        });
        window.set_cursor(system_cursor_to_winit_cursor(mouse_cursor));

        if let Some((x, y)) = pending_cursor_position {
            let cursor_position = winit::dpi::PhysicalPosition::new(x as f64, y as f64);
            if let Err(error) = window.set_cursor_position(cursor_position) {
                log_msg!(debug, L073_CURSOR_POS_FAIL, "{}", error);
            }
        }

        // Apply pending close
        if pending_close {
            state.borrow_mut().quit_requested = true;
        }

        // Apply pending scale mode
        if let Some(new_mode) = pending_scale_mode {
            if matches!(
                new_mode.as_str(),
                "none" | "letterbox" | "stretch" | "pixel"
            ) {
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    st.window_state.scale_mode_str = new_mode;
                    let (ww, wh) = (st.window_width, st.window_height);
                    recompute_viewport(&mut st.window_state, ww, wh);
                }
            }
        }
    }

    fn game_update(&mut self) {
        let (Some(lua), Some(state)) = (&self.lua, &self.state) else {
            return;
        };

        // Count frames for the auto-screenshot delay.
        if self.auto_screenshot_path.is_some() && !self.auto_screenshot_done {
            if self.auto_screenshot_frame_count == 0 {
                self.auto_screenshot_start = Some(Instant::now());
            }
            self.auto_screenshot_frame_count += 1;
        }

        // ── 1. ready (fires once, before first process) ─────────────────
        if !self.ready_fired {
            self.ready_fired = true;
            if let Err(e) = call_lua_callback_checked(lua, "ready", ()) {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
        }

        let dt = state.borrow().clock.delta();

        // ── 2. process_physics (fixed timestep, may fire 0..N times) ────
        {
            let fixed_dt = state.borrow().physics_fixed_dt;
            self.physics_accumulator += dt;
            // Safety cap: max 8 physics steps per frame to avoid spiral of death.
            let max_steps = 8;
            let mut steps = 0;
            while self.physics_accumulator >= fixed_dt && steps < max_steps {
                self.physics_accumulator -= fixed_dt;
                steps += 1;
                if let Err(e) = call_lua_callback_checked(lua, "process_physics", fixed_dt) {
                    self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                    return;
                }
            }
        }

        // ── 3. process(dt) (variable timestep, once per frame) ──────────
        if let Err(e) = call_lua_callback_checked(lua, "process", dt) {
            self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
            return;
        }

        // ── 4. process_late(dt) (after process, before render) ──────────
        if let Err(e) = call_lua_callback_checked(lua, "process_late", dt) {
            self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
            return;
        }

        // ── 5. render (main draw pass) ──────────────────────────────────
        state.borrow_mut().draw_commands.clear();
        if let Err(e) = call_lua_callback_checked(lua, "render", ()) {
            self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
            return;
        }

        // ── 6. render_ui (UI/HUD overlay pass) ──────────────────────────
        if let Err(e) = call_lua_callback_checked(lua, "render_ui", ()) {
            self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
            return;
        }

        // Append debug overlay commands after game draw
        let (fps, draw_calls, w) = {
            let st = state.borrow();
            (st.fps, st.render_stats.draw_calls, st.window_width)
        };
        let overlay_cmds = self.debug_overlay.draw_commands(w, fps, draw_calls);
        if !overlay_cmds.is_empty() {
            state.borrow_mut().draw_commands.extend(overlay_cmds);
        }
    }

    fn render(&mut self) {
        let (Some(renderer), Some(surface), Some(state)) =
            (&mut self.renderer, &self.surface, &self.state)
        else {
            return;
        };

        let (
            commands,
            textures,
            shaders,
            default_filter,
            bg,
            cam_matrix,
            frame_time,
            vp_scale_x,
            vp_scale_y,
            vp_offset_x,
            vp_offset_y,
            vp_mode,
            game_w,
            game_h,
            screenshot_request,
        ) = {
            let st = state.borrow();
            (
                st.draw_commands.clone(),
                st.textures.clone(),
                st.shaders.clone(),
                st.default_filter.clone(),
                st.background_color,
                st.camera.view_matrix(),
                st.total_time as f32,
                st.window_state.viewport_scale_x,
                st.window_state.viewport_scale_y,
                st.window_state.viewport_offset_x,
                st.window_state.viewport_offset_y,
                st.window_state.scale_mode_str.clone(),
                st.window_state.game_width,
                st.window_state.game_height,
                st.pending_screenshot.clone(),
            )
        };

        // Wrap draw commands with viewport transform when scale mode is active.
        // Uses the reusable render_cmd_buf to avoid a per-frame heap allocation.
        let use_viewport = vp_mode != "none"
            && (vp_scale_x != 1.0 || vp_scale_y != 1.0 || vp_offset_x != 0.0 || vp_offset_y != 0.0);
        if use_viewport {
            self.render_cmd_buf.clear();
            if vp_mode == "letterbox" || vp_mode == "pixel" {
                self.render_cmd_buf.push(DrawCommand::SetScissor(Some((
                    vp_offset_x,
                    vp_offset_y,
                    game_w * vp_scale_x,
                    game_h * vp_scale_y,
                ))));
            }
            self.render_cmd_buf.push(DrawCommand::PushTransform);
            self.render_cmd_buf.push(DrawCommand::Translate {
                x: vp_offset_x,
                y: vp_offset_y,
            });
            self.render_cmd_buf.push(DrawCommand::Scale {
                sx: vp_scale_x,
                sy: vp_scale_y,
            });
            self.render_cmd_buf.extend(commands.iter().cloned());
            self.render_cmd_buf.push(DrawCommand::PopTransform);
            if vp_mode == "letterbox" || vp_mode == "pixel" {
                self.render_cmd_buf.push(DrawCommand::SetScissor(None));
            }
        }
        let final_commands: &Vec<DrawCommand> = if use_viewport {
            &self.render_cmd_buf
        } else {
            &commands
        };

        // Temporarily take fonts out of SharedState for mutable access during rendering.
        let mut fonts = std::mem::take(&mut state.borrow_mut().fonts);
        let sprite_batches = std::mem::take(&mut state.borrow_mut().sprite_batches);
        let canvases = state.borrow().canvases.clone();
        let meshes = state.borrow().meshes.clone();
        let screenshot_supported = self.surface_usage.contains(wgpu::TextureUsages::COPY_SRC);
        let capture_screenshot = screenshot_request.is_some() && screenshot_supported;

        // Auto-screenshot: capture pixels this frame once enough frames have been rendered.
        let should_auto_capture = screenshot_supported
            && !self.auto_screenshot_done
            && self.auto_screenshot_path.is_some()
            && self.auto_screenshot_frame_count >= self.auto_screenshot_frames;

        let screenshot_pixels = {
            let s_ref = state.borrow();
            renderer.render_frame(
                surface,
                final_commands,
                &textures,
                &mut fonts,
                &s_ref.light_world,
                &sprite_batches,
                &canvases,
                &meshes,
                &shaders,
                &default_filter,
                bg,
                &cam_matrix,
                frame_time,
                capture_screenshot || should_auto_capture,
            )
        };
        let screenshot_pixels = match screenshot_pixels {
            Ok(screenshot) => screenshot,
            Err(e) => {
                if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                    log_msg!(warn, L024_SURFACE_LOST);
                    state.borrow_mut().fonts = fonts;
                    state.borrow_mut().sprite_batches = sprite_batches;
                    self.reconfigure_surface();
                    return;
                } else {
                    log_msg!(error, L010_RENDER_ERROR, "{:?}", e);
                }
                None
            }
        };

        // Put fonts and sprite batches back.
        state.borrow_mut().fonts = fonts;
        state.borrow_mut().sprite_batches = sprite_batches;

        // Copy render stats to SharedState for Lua access.
        state.borrow_mut().render_stats = renderer.render_stats.clone();

        if let Some(request) = screenshot_request {
            if !screenshot_supported {
                log_msg!(error, L074_SCREENSHOT_NO_READBACK, "path: {}", request.path);
            } else if let Some((width, height, ref pixels)) = screenshot_pixels {
                match crate::image::ImageData::from_bytes(width, height, pixels.clone())
                    .and_then(|image| image.encode_png())
                {
                    Ok(png) => {
                        if let Err(err) = state.borrow().fs.write_bytes(&request.path, &png) {
                            log_msg!(
                                error,
                                L075_SCREENSHOT_SAVE_FAIL,
                                "path: {}, err: {}",
                                request.path,
                                err
                            );
                        }
                    }
                    Err(err) => {
                        log_msg!(
                            error,
                            L076_SCREENSHOT_ENCODE_FAIL,
                            "path: {}, err: {}",
                            request.path,
                            err
                        );
                    }
                }
            }
            state.borrow_mut().pending_screenshot = None;
        }

        // Auto-screenshot: write pixels directly to the absolute path and quit.
        if should_auto_capture {
            if let Some(ref path) = self.auto_screenshot_path.clone() {
                if let Some((width, height, pixels)) = screenshot_pixels {
                    match crate::image::ImageData::from_bytes(width, height, pixels)
                        .and_then(|image| image.encode_png())
                    {
                        Ok(png) => {
                            if let Some(parent) = path.parent() {
                                let _ = std::fs::create_dir_all(parent);
                            }
                            if let Err(err) = std::fs::write(path, &png) {
                                log_msg!(
                                    error,
                                    L075_SCREENSHOT_SAVE_FAIL,
                                    "auto-screenshot path: {}, err: {}",
                                    path.display(),
                                    err
                                );
                            } else {
                                log_msg!(
                                    info,
                                    crate::engine::log_messages::L001_ENGINE_START,
                                    "auto-screenshot saved to: {}",
                                    path.display()
                                );
                            }
                        }
                        Err(err) => {
                            log_msg!(
                                error,
                                L076_SCREENSHOT_ENCODE_FAIL,
                                "auto-screenshot path: {}, err: {}",
                                path.display(),
                                err
                            );
                        }
                    }
                }
                self.auto_screenshot_done = true;
                state.borrow_mut().quit_requested = true;
            }
        }
    }

    fn render_splash(&mut self) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        let total_time = self
            .state
            .as_ref()
            .map_or(0.0, |s| s.borrow().clock.total());

        // Lazily initialise shared TTF engine fonts (used by both splash and error screens).
        if self.engine_fonts.is_none() {
            static FONT_DATA: &[u8] = include_bytes!("../../assets/fonts/OpenSans.ttf");
            let mut fonts: SlotMap<FontKey, crate::graphics::Font> = SlotMap::with_key();
            let title_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 36.0).expect("embedded font");
            let small_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 18.0).expect("embedded font");
            let title_key = fonts.insert(title_font);
            let small_key = fonts.insert(small_font);
            self.engine_fonts = Some((fonts, title_key, small_key));
        }
        let (splash_fonts, _title_key, small_key) = self.engine_fonts.as_mut().unwrap();

        if self.splash_branding.is_none() && !self.splash_branding_failed {
            self.splash_branding = load_splash_branding();
            self.splash_branding_failed = self.splash_branding.is_none();
        }

        let branding = self.splash_branding.as_ref();

        let cmds = make_splash_commands(
            renderer.width,
            renderer.height,
            *small_key,
            splash_fonts,
            branding,
            self.drag_hover,
        );
        let bg = [0.12, 0.08, 0.20, 1.0];
        let no_batches: SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch> = SlotMap::with_key();
        let no_canvases: SlotMap<CanvasKey, crate::graphics::Canvas> = SlotMap::with_key();
        let empty_textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
        let no_meshes: SlotMap<MeshKey, crate::graphics::Mesh> = SlotMap::with_key();
        let no_shaders: SlotMap<ShaderKey, crate::graphics::Shader> = SlotMap::with_key();
        let default_filter = ("linear".to_string(), "linear".to_string(), 1);
        let no_lights = crate::light::light_world::LightWorld::new();
        let splash_textures = branding.map_or(&empty_textures, |assets| &assets.textures);
        if let Err(e) = renderer.render_frame(
            surface,
            &cmds,
            splash_textures,
            splash_fonts,
            &no_lights,
            &no_batches,
            &no_canvases,
            &no_meshes,
            &no_shaders,
            &default_filter,
            bg,
            &crate::math::Mat3::identity(),
            total_time as f32,
            false,
        ) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                self.reconfigure_surface();
            }
        }
    }

    fn render_error(&mut self, error_screen: &ErrorScreen) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };

        // Re-use the shared engine fonts (same OpenSans 36/18 pt as the splash screen).
        if self.engine_fonts.is_none() {
            static FONT_DATA: &[u8] = include_bytes!("../../assets/fonts/OpenSans.ttf");
            let mut fonts: SlotMap<FontKey, crate::graphics::Font> = SlotMap::with_key();
            let title_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 36.0).expect("embedded font");
            let small_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 18.0).expect("embedded font");
            let title_key = fonts.insert(title_font);
            let small_key = fonts.insert(small_font);
            self.engine_fonts = Some((fonts, title_key, small_key));
        }
        let (error_fonts, heading_key, body_key) = self.engine_fonts.as_mut().unwrap();

        let cmds = error_screen.draw_commands(
            renderer.width,
            renderer.height,
            Some(*heading_key),
            Some(*body_key),
        );
        let bg = [0.11, 0.22, 0.53, 1.0];
        let no_batches: SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch> = SlotMap::with_key();
        let no_canvases: SlotMap<CanvasKey, crate::graphics::Canvas> = SlotMap::with_key();
        let no_textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
        let no_meshes: SlotMap<MeshKey, crate::graphics::Mesh> = SlotMap::with_key();
        let no_shaders: SlotMap<ShaderKey, crate::graphics::Shader> = SlotMap::with_key();
        let default_filter = ("linear".to_string(), "linear".to_string(), 1);
        let no_lights = crate::light::light_world::LightWorld::new();
        if let Err(e) = renderer.render_frame(
            surface,
            &cmds,
            &no_textures,
            error_fonts,
            &no_lights,
            &no_batches,
            &no_canvases,
            &no_meshes,
            &no_shaders,
            &default_filter,
            bg,
            &crate::math::Mat3::identity(),
            0.0,
            false,
        ) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                self.reconfigure_surface();
            }
        }
    }

    fn restart_game(&mut self) {
        // Reset Lua state and reinitialise
        self.lua = None;
        self.state = None;
        self.has_game = false;
        self.prev_mouse = [false; 5];
        self.run_state = RunState::Running;
        self.init_lua();
    }

    fn reconfigure_surface(&mut self) {
        let Some((w, h)) = self
            .renderer
            .as_ref()
            .map(|renderer| (renderer.width, renderer.height))
        else {
            return;
        };
        let (w, h) = self.clamp_surface_dims(w, h);
        let surface_config = self.surface_configuration(w, h);
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        surface.configure(&renderer.device, &surface_config);
    }

    fn handle_resize(&mut self, width: u32, height: u32) {
        if width == 0 || height == 0 {
            return;
        }
        let (width, height) = self.clamp_surface_dims(width, height);
        let surface_config = self.surface_configuration(width, height);
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        renderer.resize(width, height);
        surface.configure(&renderer.device, &surface_config);
        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            st.window_width = width;
            st.window_height = height;
            recompute_viewport(&mut st.window_state, width, height);
        }
        // Fire lurek.resize(w, h) callback
        if self.has_game {
            if let Some(lua) = &self.lua {
                call_lua_callback(lua, "resize", (width, height));
            }
        }
    }

    fn poll_gamepads(&mut self) {
        let Some(gilrs) = &mut self.gilrs else { return };
        let Some(state) = &self.state else { return };
        let has_game = self.has_game;
        let lua = self.lua.as_ref();

        while let Some(GilrsEvent { id, event, .. }) = gilrs.next_event() {
            let id_usize = usize::from(id);
            let id_u32 = id_usize as u32;
            match event {
                GilrsEventType::ButtonPressed(btn, _) => {
                    let btn_idx = gilrs_button_to_u32(btn);
                    let button_name = gilrs_button_to_string(btn).to_string();
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.connected = true;
                        gamepad.update_button(btn_idx, true);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback(lua, "gamepadpressed", (id_u32, button_name));
                        }
                    }
                }
                GilrsEventType::ButtonReleased(btn, _) => {
                    let btn_idx = gilrs_button_to_u32(btn);
                    let button_name = gilrs_button_to_string(btn).to_string();
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.connected = true;
                        gamepad.update_button(btn_idx, false);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback(lua, "gamepadreleased", (id_u32, button_name));
                        }
                    }
                }
                GilrsEventType::AxisChanged(axis, value, _) => {
                    let axis_idx = gilrs_axis_to_u32(axis);
                    let axis_name = gilrs_axis_to_string(axis).to_string();
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.connected = true;
                        gamepad.update_axis(axis_idx, value);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback(lua, "gamepadaxis", (id_u32, axis_name, value));
                        }
                    }
                }
                GilrsEventType::Connected => {
                    let gamepad = gilrs.gamepad(id);
                    let name = gamepad.name().to_string();
                    let guid = format_gilrs_uuid(gamepad.uuid());
                    {
                        let mut st = state.borrow_mut();
                        let entry = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        entry.connected = true;
                        entry.name = name;
                        entry.set_guid(guid);
                    }
                    log_msg!(info, L036_GAMEPAD_CONNECTED, "id={}", id_usize);
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback(lua, "joystickadded", (id_u32,));
                        }
                    }
                }
                GilrsEventType::Disconnected => {
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.connected = false;
                    }
                    log_msg!(info, L037_GAMEPAD_DISCONNECTED, "id={}", id_usize);
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback(lua, "joystickremoved", (id_u32,));
                        }
                    }
                }
                _ => {}
            }
        }
    }
}

fn gilrs_button_to_u32(btn: GilrsButton) -> u32 {
    match btn {
        GilrsButton::South => 0,
        GilrsButton::East => 1,
        GilrsButton::West => 2,
        GilrsButton::North => 3,
        GilrsButton::LeftTrigger => 4,
        GilrsButton::RightTrigger => 5,
        GilrsButton::Select => 6,
        GilrsButton::Start => 7,
        GilrsButton::LeftThumb => 8,
        GilrsButton::RightThumb => 9,
        GilrsButton::DPadUp => 10,
        GilrsButton::DPadDown => 11,
        GilrsButton::DPadLeft => 12,
        GilrsButton::DPadRight => 13,
        _ => 255,
    }
}

fn gilrs_axis_to_u32(axis: GilrsAxis) -> u32 {
    match axis {
        GilrsAxis::LeftStickX => 0,
        GilrsAxis::LeftStickY => 1,
        GilrsAxis::RightStickX => 2,
        GilrsAxis::RightStickY => 3,
        GilrsAxis::LeftZ => 4,
        GilrsAxis::RightZ => 5,
        _ => 255,
    }
}

fn ensure_gamepad_slot(
    gamepads: &mut Vec<crate::input::GamepadState>,
    id_usize: usize,
) -> &mut crate::input::GamepadState {
    while gamepads.len() <= id_usize {
        let new_id = gamepads.len() as u32;
        gamepads.push(crate::input::GamepadState::new(new_id));
    }

    &mut gamepads[id_usize]
}

fn format_gilrs_uuid(uuid_bytes: [u8; 16]) -> String {
    format!(
        "{:02x}{:02x}{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}-{:02x}{:02x}{:02x}{:02x}{:02x}{:02x}",
        uuid_bytes[0],
        uuid_bytes[1],
        uuid_bytes[2],
        uuid_bytes[3],
        uuid_bytes[4],
        uuid_bytes[5],
        uuid_bytes[6],
        uuid_bytes[7],
        uuid_bytes[8],
        uuid_bytes[9],
        uuid_bytes[10],
        uuid_bytes[11],
        uuid_bytes[12],
        uuid_bytes[13],
        uuid_bytes[14],
        uuid_bytes[15],
    )
}

fn system_cursor_to_winit_cursor(cursor: SystemCursor) -> CursorIcon {
    match cursor {
        SystemCursor::Arrow => CursorIcon::Default,
        SystemCursor::IBeam => CursorIcon::Text,
        SystemCursor::Wait => CursorIcon::Wait,
        SystemCursor::Crosshair => CursorIcon::Crosshair,
        SystemCursor::Hand => CursorIcon::Pointer,
        SystemCursor::SizeNWSE => CursorIcon::NwseResize,
        SystemCursor::SizeNESW => CursorIcon::NeswResize,
        SystemCursor::SizeWE => CursorIcon::EwResize,
        SystemCursor::SizeNS => CursorIcon::NsResize,
        SystemCursor::SizeAll => CursorIcon::Move,
        SystemCursor::No => CursorIcon::NotAllowed,
    }
}

/// Loads the embedded engine icon PNG and converts it to a [`winit::window::Icon`].
///
/// Used as the default window icon when the game's `conf.lua` does not supply a
/// custom icon path. Returns `None` if the embedded bytes cannot be decoded.
fn load_embedded_icon() -> Option<winit::window::Icon> {
    static ICON_BYTES: &[u8] = include_bytes!("../../assets/icon.png");
    let image = match ::image::load_from_memory(ICON_BYTES) {
        Ok(img) => img,
        Err(e) => {
            log_msg!(warn, L040_ICON_LOAD_FAIL, "embedded icon: {}", e);
            return None;
        }
    };
    let rgba = image.to_rgba8();
    let (w, h) = (rgba.width(), rgba.height());
    match winit::window::Icon::from_rgba(rgba.into_raw(), w, h) {
        Ok(icon) => Some(icon),
        Err(e) => {
            log_msg!(warn, L041_ICON_CONV_FAIL, "embedded icon: {}", e);
            None
        }
    }
}

fn load_window_icon(game_dir: &Path, icon_path: &str) -> Option<winit::window::Icon> {
    let resolved_path = {
        let path = Path::new(icon_path);
        if path.is_absolute() {
            path.to_path_buf()
        } else {
            game_dir.join(path)
        }
    };

    let image = match ::image::open(&resolved_path) {
        Ok(image) => image,
        Err(error) => {
            log_msg!(
                warn,
                L040_ICON_LOAD_FAIL,
                "'{}': {}",
                resolved_path.display(),
                error
            );
            return None;
        }
    };

    let rgba = image.to_rgba8();
    let (width, height) = (rgba.width(), rgba.height());
    match winit::window::Icon::from_rgba(rgba.into_raw(), width, height) {
        Ok(icon) => Some(icon),
        Err(error) => {
            log_msg!(
                warn,
                L041_ICON_CONV_FAIL,
                "'{}': {}",
                resolved_path.display(),
                error
            );
            None
        }
    }
}

fn load_embedded_splash_texture(
    bytes: &[u8],
    asset_name: &str,
    textures: &mut SlotMap<TextureKey, TextureData>,
) -> Option<SplashTexture> {
    let image = match ::image::load_from_memory(bytes) {
        Ok(image) => image,
        Err(error) => {
            log::warn!(
                "Failed to decode embedded splash texture '{}': {}",
                asset_name,
                error
            );
            return None;
        }
    };

    let rgba = image.to_rgba8();
    let (width, height) = rgba.dimensions();
    match crate::graphics::Texture::from_rgba(width, height, rgba.into_raw(), textures) {
        Ok(texture) => Some(SplashTexture {
            texture_key: texture.key,
            width: texture.width,
            height: texture.height,
        }),
        Err(error) => {
            log::warn!(
                "Failed to prepare embedded splash texture '{}': {}",
                asset_name,
                error
            );
            None
        }
    }
}

fn load_splash_branding() -> Option<SplashBranding> {
    static LARGE_ICON_BYTES: &[u8] = include_bytes!("../../assets/icon-large.png");
    static BANNER_BYTES: &[u8] = include_bytes!("../../assets/banner.png");

    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let large_icon =
        load_embedded_splash_texture(LARGE_ICON_BYTES, "assets/svg/large_icon.png", &mut textures)?;
    let banner =
        load_embedded_splash_texture(BANNER_BYTES, "assets/svg/banner.png", &mut textures)?;

    Some(SplashBranding {
        textures,
        large_icon,
        banner,
    })
}

fn select_startup_monitor(
    event_loop: &ActiveEventLoop,
    display_index: u32,
) -> Option<winit::monitor::MonitorHandle> {
    let primary = event_loop
        .primary_monitor()
        .or_else(|| event_loop.available_monitors().next());
    if display_index == 0 {
        return primary;
    }

    let monitor = event_loop.available_monitors().nth(display_index as usize);
    if monitor.is_none() {
        log_msg!(
            warn,
            L042_DISPLAY_INDEX_UNAVAIL,
            "index {}, falling back to primary",
            display_index
        );
    }
    monitor.or(primary)
}

fn center_window_on_monitor(
    window: &Window,
    monitor: &winit::monitor::MonitorHandle,
    width: u32,
    height: u32,
) {
    let monitor_size = monitor.size();
    let monitor_position = monitor.position();
    let x = monitor_position.x + ((monitor_size.width as i32 - width as i32).max(0) / 2);
    let y = monitor_position.y + ((monitor_size.height as i32 - height as i32).max(0) / 2);
    window.set_outer_position(winit::dpi::PhysicalPosition::new(x, y));
}

impl ApplicationHandler for LunaApp {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() {
            return;
        } // already initialised

        let initial_title = self.current_window_title();
        let mut window_attrs = Window::default_attributes()
            .with_title(&initial_title)
            .with_inner_size(winit::dpi::PhysicalSize::new(
                self.config.window.width,
                self.config.window.height,
            ))
            .with_resizable(self.config.window.resizable)
            .with_decorations(!self.config.window.borderless);

        // Apply minimum window size if both dimensions are set
        if let (Some(w), Some(h)) = (self.config.window.min_width, self.config.window.min_height) {
            window_attrs = window_attrs.with_min_inner_size(winit::dpi::PhysicalSize::new(w, h));
        }

        let startup_monitor = select_startup_monitor(event_loop, self.config.window.display_index);

        let window = Arc::new(
            event_loop
                .create_window(window_attrs)
                .expect("Failed to create window"),
        );

        if self.config.window.fullscreen {
            window.set_fullscreen(Some(winit::window::Fullscreen::Borderless(
                startup_monitor.clone(),
            )));
        } else if let Some(monitor) = startup_monitor.as_ref() {
            center_window_on_monitor(
                window.as_ref(),
                monitor,
                self.config.window.width,
                self.config.window.height,
            );
        }

        if self.config.window.maximized && !self.config.window.fullscreen {
            window.set_maximized(true);
        }

        if let Some(icon_path) = self.config.window.icon.as_deref() {
            if let Some(icon) = load_window_icon(&self.game_dir, icon_path) {
                window.set_window_icon(Some(icon));
            }
        } else {
            // No icon configured — fall back to the embedded engine icon.
            if let Some(icon) = load_embedded_icon() {
                window.set_window_icon(Some(icon));
            }
        }

        self.init_gpu(window);

        // Initialize gilrs gamepad polling (can happen before Lua VM).
        match Gilrs::new() {
            Ok(g) => self.gilrs = Some(g),
            Err(e) => log_msg!(warn, L038_GILRS_UNAVAILABLE, "{}", e),
        }
        self.last_frame = Instant::now();

        // Request a redraw immediately. The first RedrawRequested will render the
        // splash frame and THEN call init_lua(), ensuring the splash is visible
        // before Lua VM initialisation blocks the event loop.
        if let Some(win) = &self.window {
            win.request_redraw();
        }
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        match event {
            WindowEvent::CloseRequested => {
                log_msg!(info, L039_WINDOW_CLOSE);
                if let Some(lua) = &self.lua {
                    call_lua_callback(lua, "exit", ());
                }
                event_loop.exit();
            }

            WindowEvent::Resized(size) => {
                self.handle_resize(size.width, size.height);
            }

            WindowEvent::ScaleFactorChanged {
                scale_factor,
                inner_size_writer: _,
            } => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.dpi_scale = scale_factor;
                }
                // A subsequent Resized event will call handle_resize() to reconfigure the surface.
            }

            WindowEvent::Focused(focused) => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.focused = focused;
                }
                if self.has_game {
                    if let Some(lua) = &self.lua {
                        call_lua_callback(lua, "focus", (focused,));
                    }
                }
            }

            WindowEvent::Occluded(occluded) => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.visible = !occluded;
                }
                if self.has_game {
                    if let Some(lua) = &self.lua {
                        call_lua_callback(lua, "visible", (!occluded,));
                    }
                }
            }

            WindowEvent::CursorEntered { .. } => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.mouse_focused = true;
                }
            }

            WindowEvent::CursorLeft { .. } => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.mouse_focused = false;
                }
            }

            WindowEvent::ModifiersChanged(mods) => {
                let state_mods = mods.state();
                self.ctrl_held = state_mods.control_key();
                if let Some(state) = &self.state {
                    state.borrow_mut().keyboard.set_modifiers(
                        state_mods.shift_key(),
                        state_mods.control_key(),
                        state_mods.alt_key(),
                        state_mods.super_key(),
                    );
                }
            }

            WindowEvent::KeyboardInput { event, .. } => {
                // Resolve physical scancode string.
                let scancode_str = if let PhysicalKey::Code(code) = event.physical_key {
                    winit_scancode_to_string(code).map(|s| s.to_string())
                } else {
                    None
                };

                // Check key repeat suppression.
                if event.repeat {
                    let repeat_enabled = self
                        .state
                        .as_ref()
                        .map(|s| s.borrow().keyboard.has_key_repeat())
                        .unwrap_or(false);
                    if !repeat_enabled {
                        // Still update scancode tracking but skip callbacks.
                        return;
                    }
                }

                // Update scancode state.
                if let Some(sc) = &scancode_str {
                    if let Some(state) = &self.state {
                        let mut st = state.borrow_mut();
                        match event.state {
                            ElementState::Pressed => st.keyboard.press_scancode(sc.clone()),
                            ElementState::Released => st.keyboard.release_scancode(sc.clone()),
                        }
                    }
                }

                if let Some(key_str) = winit_key_to_string(&event.logical_key) {
                    // Handle error mode keys before normal processing.
                    if matches!(self.run_state, RunState::Error(_)) {
                        if event.state == ElementState::Pressed {
                            if key_str == "escape" {
                                event_loop.exit();
                                return;
                            }
                            if key_str == "r" {
                                self.run_state = RunState::Restarting;
                                return;
                            }
                            if self.ctrl_held && key_str == "c" {
                                if let RunState::Error(ref screen) = self.run_state {
                                    let text = screen.as_text();
                                    match arboard::Clipboard::new() {
                                        Ok(mut cb) => {
                                            let _ = cb.set_text(text);
                                        }
                                        Err(e) => {
                                            log_msg!(warn, L021_CLIPBOARD_FAIL, "{}", e);
                                        }
                                    }
                                }
                                return;
                            }
                        }
                        return; // Swallow all other keys in error mode.
                    }

                    match event.state {
                        ElementState::Pressed => {
                            // Check quit on Escape.
                            if key_str == "escape" {
                                event_loop.exit();
                                return;
                            }
                            // Toggle debug overlay on F12.
                            if key_str == "f12" {
                                self.debug_overlay.enabled = !self.debug_overlay.enabled;
                                if let Some(state) = &self.state {
                                    state.borrow_mut().debug_overlay_enabled =
                                        self.debug_overlay.enabled;
                                }
                                return;
                            }
                            if let Some(state) = &self.state {
                                let mut st = state.borrow_mut();
                                st.keys_down.insert(key_str.clone());
                                st.keyboard.set_key_down(&key_str);
                            }
                            if self.has_game {
                                if let Some(lua) = &self.lua {
                                    let sc = scancode_str.clone().unwrap_or_default();
                                    call_lua_callback(
                                        lua,
                                        "keypressed",
                                        (key_str.clone(), sc.clone(), event.repeat),
                                    );
                                }
                            }
                            if let Some(state) = &self.state {
                                let sc = scancode_str.clone().unwrap_or_default();
                                state.borrow_mut().event_queue.push_event(
                                    "keypressed",
                                    vec![
                                        EventArg::Str(key_str.clone()),
                                        EventArg::Str(sc),
                                        EventArg::Bool(event.repeat),
                                    ],
                                );
                            }
                        }
                        ElementState::Released => {
                            if let Some(state) = &self.state {
                                let mut st = state.borrow_mut();
                                st.keys_down.remove(&key_str);
                                st.keyboard.set_key_up(&key_str);
                            }
                            if self.has_game {
                                if let Some(lua) = &self.lua {
                                    let sc = scancode_str.clone().unwrap_or_default();
                                    call_lua_callback(lua, "keyreleased", (key_str.clone(), sc));
                                }
                            }
                            if let Some(state) = &self.state {
                                let sc = scancode_str.clone().unwrap_or_default();
                                state.borrow_mut().event_queue.push_event(
                                    "keyreleased",
                                    vec![EventArg::Str(key_str.clone()), EventArg::Str(sc)],
                                );
                            }
                        }
                    }
                }
            }

            WindowEvent::Ime(winit::event::Ime::Commit(text)) => {
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    if st.keyboard.has_text_input() {
                        st.keyboard.push_text_input(text.clone());
                        drop(st);
                        if self.has_game {
                            if let Some(lua) = &self.lua {
                                call_lua_callback(lua, "textinput", text);
                            }
                        }
                    }
                }
            }

            WindowEvent::CursorMoved { position, .. } => {
                // Transform window-space coordinates to game-space via inverse viewport.
                let (gx, gy) = if let Some(state) = &self.state {
                    let st = state.borrow();
                    let ws = &st.window_state;
                    let gx = if ws.viewport_scale_x > 0.0 {
                        (position.x as f32 - ws.viewport_offset_x) / ws.viewport_scale_x
                    } else {
                        position.x as f32
                    };
                    let gy = if ws.viewport_scale_y > 0.0 {
                        (position.y as f32 - ws.viewport_offset_y) / ws.viewport_scale_y
                    } else {
                        position.y as f32
                    };
                    (gx, gy)
                } else {
                    (position.x as f32, position.y as f32)
                };
                self.mouse_x = gx;
                self.mouse_y = gy;
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    st.mouse.x = gx;
                    st.mouse.y = gy;
                }
            }

            WindowEvent::MouseWheel { delta, .. } => {
                let (dx, dy) = match delta {
                    winit::event::MouseScrollDelta::LineDelta(x, y) => (x as f64, y as f64),
                    winit::event::MouseScrollDelta::PixelDelta(pos) => (pos.x, pos.y),
                };
                if let Some(state) = &self.state {
                    state.borrow_mut().mouse.accumulate_scroll(dx, dy);
                }
                if self.has_game {
                    if let Some(lua) = &self.lua {
                        call_lua_callback(lua, "wheelmoved", (dx, dy));
                    }
                }
            }

            WindowEvent::MouseInput {
                state: btn_state,
                button,
                ..
            } => {
                let idx = match button {
                    MouseButton::Left => Some(0),
                    MouseButton::Right => Some(1),
                    MouseButton::Middle => Some(2),
                    MouseButton::Back => Some(3),
                    MouseButton::Forward => Some(4),
                    _ => None,
                };
                if let Some(i) = idx {
                    let pressed = btn_state == ElementState::Pressed;
                    if let Some(state) = &self.state {
                        state.borrow_mut().mouse.set_button(i, pressed);
                    }
                    if self.has_game {
                        let mx = self.mouse_x;
                        let my = self.mouse_y;
                        if let Some(lua) = &self.lua {
                            if pressed && !self.prev_mouse[i] {
                                call_lua_callback(lua, "mousepressed", (mx, my, (i + 1) as u32));
                            } else if !pressed && self.prev_mouse[i] {
                                call_lua_callback(lua, "mousereleased", (mx, my, (i + 1) as u32));
                            }
                        }
                    }
                    if let Some(state) = &self.state {
                        let mx = self.mouse_x;
                        let my = self.mouse_y;
                        if pressed && !self.prev_mouse[i] {
                            state.borrow_mut().event_queue.push_event(
                                "mousepressed",
                                vec![
                                    EventArg::Num(mx as f64),
                                    EventArg::Num(my as f64),
                                    EventArg::Num((i + 1) as f64),
                                ],
                            );
                        } else if !pressed && self.prev_mouse[i] {
                            state.borrow_mut().event_queue.push_event(
                                "mousereleased",
                                vec![
                                    EventArg::Num(mx as f64),
                                    EventArg::Num(my as f64),
                                    EventArg::Num((i + 1) as f64),
                                ],
                            );
                        }
                    }
                    self.prev_mouse[i] = pressed;
                }
            }

            WindowEvent::RedrawRequested => {
                // --- First-frame Lua init -------------------------------------
                // On the very first redraw, show the splash and then call
                // init_lua(). The splash frame is submitted to the GPU before
                // init_lua blocks, so the user sees it during loading.
                if !self.lua_initialized {
                    self.render_splash();
                    self.init_lua();
                    self.lua_initialized = true;
                    // Start the screenshot safety timer now that the game is loaded.
                    if self.auto_screenshot_path.is_some() {
                        self.auto_screenshot_start = Some(Instant::now());
                    }
                    // Sync window state into SharedState now that state exists.
                    if let (Some(window), Some(state)) = (&self.window, &self.state) {
                        let mut st = state.borrow_mut();
                        st.window_state.fullscreen = window.fullscreen().is_some();
                        if let Ok(position) = window.outer_position() {
                            st.window_state.position_x = position.x;
                            st.window_state.position_y = position.y;
                        }
                    }
                    if let Some(win) = &self.window {
                        win.request_redraw();
                    }
                    return;
                }

                // Handle restart request from error screen.
                if matches!(self.run_state, RunState::Restarting) {
                    self.restart_game();
                    return;
                }

                // Check quit flag from Lua (e.g., lurek.signal.quit()).
                if let Some(state) = &self.state {
                    if state.borrow().quit_requested {
                        event_loop.exit();
                        return;
                    }
                }

                self.poll_gamepads();
                self.tick_frame();

                // Temporarily take run_state to avoid borrow issues with render_error.
                let run_state = std::mem::replace(&mut self.run_state, RunState::Running);
                match run_state {
                    RunState::Error(ref screen) => {
                        self.render_error(screen);
                        self.run_state = run_state;
                        // In screenshot mode quit immediately instead of waiting for user input.
                        if self.auto_screenshot_path.is_some() {
                            if let Some(state) = &self.state {
                                state.borrow_mut().quit_requested = true;
                            } else {
                                event_loop.exit();
                            }
                        }
                    }
                    RunState::Running => {
                        if self.has_game {
                            self.game_update();
                            self.render();
                        } else {
                            self.render_splash();
                        }
                    }
                    RunState::Restarting => {
                        // Handled above; should not reach here.
                    }
                }
            }

            WindowEvent::Touch(touch) => {
                let id = touch.id;
                let x = touch.location.x;
                let y = touch.location.y;
                let pressure = touch.force.map_or(1.0, |f| match f {
                    winit::event::Force::Normalized(n) => n,
                    winit::event::Force::Calibrated {
                        force,
                        max_possible_force,
                        ..
                    } => {
                        if max_possible_force > 0.0 {
                            force / max_possible_force
                        } else {
                            1.0
                        }
                    }
                });

                match touch.phase {
                    winit::event::TouchPhase::Started => {
                        let dx = 0.0;
                        let dy = 0.0;
                        if let Some(state) = &self.state {
                            state.borrow_mut().touch.touch_start(id, x, y, pressure);
                        }
                        if let Some(lua) = self.lua.as_ref().filter(|_| self.has_game) {
                            call_lua_callback(lua, "touchpressed", (id, x, y, dx, dy, pressure));
                        }
                    }
                    winit::event::TouchPhase::Moved => {
                        let (dx, dy) = if let Some(state) = &self.state {
                            let mut st = state.borrow_mut();
                            let delta = st
                                .touch
                                .get_touch(id)
                                .map(|touch_point| (x - touch_point.x, y - touch_point.y))
                                .unwrap_or((0.0, 0.0));
                            st.touch.touch_move(id, x, y, pressure);
                            delta
                        } else {
                            (0.0, 0.0)
                        };
                        if let Some(lua) = self.lua.as_ref().filter(|_| self.has_game) {
                            call_lua_callback(lua, "touchmoved", (id, x, y, dx, dy, pressure));
                        }
                    }
                    winit::event::TouchPhase::Ended | winit::event::TouchPhase::Cancelled => {
                        let (dx, dy) = if let Some(state) = &self.state {
                            let mut st = state.borrow_mut();
                            let delta = st
                                .touch
                                .get_touch(id)
                                .map(|touch_point| (x - touch_point.x, y - touch_point.y))
                                .unwrap_or((0.0, 0.0));
                            st.touch.touch_end(id);
                            delta
                        } else {
                            (0.0, 0.0)
                        };
                        if let Some(lua) = self.lua.as_ref().filter(|_| self.has_game) {
                            call_lua_callback(lua, "touchreleased", (id, x, y, dx, dy, pressure));
                        }
                    }
                }
            }

            // Drag-and-drop: allow loading a game folder by dropping it onto the window.
            WindowEvent::HoveredFile(path) => {
                log_msg!(debug, L077_DRAG_HOVER, "{}", path.display());
                if !self.has_game {
                    self.drag_hover = true;
                    if let Some(win) = &self.window {
                        win.request_redraw();
                    }
                }
            }

            WindowEvent::HoveredFileCancelled => {
                log_msg!(debug, L078_DRAG_HOVER_CANCEL);
                if self.drag_hover {
                    self.drag_hover = false;
                    if let Some(win) = &self.window {
                        win.request_redraw();
                    }
                }
            }

            WindowEvent::DroppedFile(path) => {
                log::debug!("[luna2d drag-drop] DroppedFile: {}", path.display());
                log_msg!(info, L043_DROP_FILE, "{}", path.display());
                if self.drag_hover {
                    self.drag_hover = false;
                    if let Some(win) = &self.window {
                        win.request_redraw();
                    }
                }
                if !self.has_game {
                    let main_lua = path.join("main.lua");
                    if path.is_dir() && main_lua.exists() {
                        log_msg!(info, L044_DROP_GAME, "{}", path.display());
                        self.game_dir = path;
                        self.explicit_game_dir = true;
                        self.restart_game();
                    } else if path.is_dir() {
                        log_msg!(warn, L007_NO_MAIN_LUA, "no main.lua in: {}", path.display());
                    } else if let Some(parent) = path.parent() {
                        // User may have dropped a file inside the game folder.
                        let parent_main = parent.join("main.lua");
                        if parent_main.exists() {
                            log_msg!(info, L044_DROP_GAME, "parent folder: {}", parent.display());
                            self.game_dir = parent.to_path_buf();
                            self.explicit_game_dir = true;
                            self.restart_game();
                        }
                    }
                } else {
                    log_msg!(debug, L079_DRAG_DROP_IGNORED);
                }
            }

            _ => {}
        }
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        use std::time::Duration;

        // Safety-net: if screenshot mode has been active for > 3 s without a capture,
        // force-quit so the batch tool never hangs indefinitely.
        if !self.auto_screenshot_done {
            if let Some(start) = self.auto_screenshot_start {
                if start.elapsed() > Duration::from_secs(3) {
                    if let Some(state) = &self.state {
                        state.borrow_mut().quit_requested = true;
                    } else {
                        event_loop.exit();
                    }
                }
            }
        }

        let target = Duration::from_secs_f64(1.0 / self.config.performance.target_fps as f64);
        let elapsed = self.last_frame.elapsed();
        if elapsed >= target {
            self.last_frame = Instant::now();
            if let Some(win) = &self.window {
                win.request_redraw();
            }
        } else {
            // Sleep until the next frame deadline so the event loop doesn't
            // spin at 100% CPU while waiting. Input events still wake the
            // thread immediately (WaitUntil is a *maximum* sleep duration).
            let next = Instant::now() + (target - elapsed);
            event_loop.set_control_flow(ControlFlow::WaitUntil(next));
        }
    }
}

// ─── App entry point (public API) ────────────────────────────────────────────

/// Entry point for the Lurek2D engine. Owns the game loop, GPU renderer, and Lua VM lifecycle.
///
/// # Fields
/// - `config` — `Config`.
/// - `conf_error` — `Option<String>`.
pub struct App {
    config: Config,
    /// Error message from conf.lua loading, propagated to the error screen.
    conf_error: Option<String>,
}

impl App {
    /// Creates a new `App` with the given `Config` and an optional conf.lua error.
    ///
    /// # Parameters
    /// - `config` — `Config`.
    /// - `conf_error` — `Option<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(config: Config, conf_error: Option<String>) -> Self {
        App { config, conf_error }
    }

    /// Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
    ///
    /// # Parameters
    /// - `game_dir` — Path to the game directory.
    /// - `explicit_game_dir` — `true` when the user explicitly passed a path argument.
    /// - `screenshot_path` — If `Some`, take a screenshot at this absolute path and quit.
    /// - `screenshot_frames` — Minimum rendered game frames before capturing (default 3).
    pub fn run(
        self,
        game_dir: PathBuf,
        explicit_game_dir: bool,
        screenshot_path: Option<PathBuf>,
        screenshot_frames: u32,
    ) {
        init_logging(
            &game_dir,
            self.config.log_file.as_deref(),
            self.config.log_append,
            self.config.log_level.as_deref(),
        );
        // Initialise the message catalog before any log_msg! calls.
        crate::engine::messages::init();
        log_msg!(
            info,
            crate::engine::log_messages::L001_ENGINE_START,
            "v{} (wgpu GPU backend)",
            env!("CARGO_PKG_VERSION"),
        );
        log_msg!(info, L080_GAME_DIR, "{}", game_dir.display());

        let event_loop = EventLoop::new().expect("Failed to create event loop");
        // Start with Poll so the first frame and init_lua run as fast as
        // possible. about_to_wait() switches to WaitUntil after that.
        event_loop.set_control_flow(ControlFlow::Poll);

        let mut app = LunaApp::new(
            self.config,
            game_dir,
            self.conf_error,
            explicit_game_dir,
            screenshot_path,
            screenshot_frames,
        );
        event_loop.run_app(&mut app).expect("Event loop error");

        log_msg!(info, crate::engine::log_messages::L002_ENGINE_STOP);
    }
}

// ─── Logging ─────────────────────────────────────────────────────────────────

/// Initialises logging to both stderr and a log file.
///
/// `log_file` is a path relative to `game_dir` (or absolute). When `None`,
/// the file is placed at `cwd/lurek2d.log`.  When `log_append` is `true` the
/// file is opened in append mode instead of being truncated.
/// `log_level` overrides the build-mode default level when `Some` — valid values:
/// `"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`.
fn init_logging(
    game_dir: &Path,
    log_file: Option<&str>,
    log_append: bool,
    log_level: Option<&str>,
) {
    use std::io::Write as _;

    // Resolve log file path: custom path relative to game_dir, or cwd/lurek2d.log default.
    let log_path = if let Some(custom) = log_file {
        let p = std::path::Path::new(custom);
        if p.is_absolute() {
            p.to_path_buf()
        } else {
            game_dir.join(p)
        }
    } else {
        std::env::current_dir()
            .unwrap_or_else(|_| std::path::PathBuf::from("."))
            .join("luna2d.log")
    };

    // Open or create the log file, respecting the append flag.
    let file_result = if log_append {
        std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&log_path)
    } else {
        std::fs::OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(&log_path)
    };

    // Use explicit log_level from conf.lua if provided; otherwise fall back to
    // build-mode default (debug builds: Debug, release builds: Error).
    let level = match log_level {
        Some("error") => log::LevelFilter::Error,
        Some("warn") => log::LevelFilter::Warn,
        Some("info") => log::LevelFilter::Info,
        Some("debug") => log::LevelFilter::Debug,
        Some("trace") => log::LevelFilter::Trace,
        _ => {
            if cfg!(debug_assertions) {
                log::LevelFilter::Debug
            } else {
                log::LevelFilter::Error
            }
        }
    };

    // wgpu/wgpu_hal emit noisy INFO ("Device::maintain", "Adapter Vulkan AdapterInfo")
    // and WARN ("Unrecognized present mode") messages that users cannot act on.
    // In release we hard-floor these crates at Error; in debug at Warn so GPU
    // errors still surface without the chatter.
    let wgpu_level = if cfg!(debug_assertions) {
        log::LevelFilter::Warn
    } else {
        log::LevelFilter::Error
    };

    match file_result {
        Ok(file) => {
            // Use a Mutex so the File impl is Send + Sync.
            let file = std::sync::Arc::new(std::sync::Mutex::new(file));
            let file_clone = std::sync::Arc::clone(&file);

            env_logger::Builder::new()
                .filter_level(level)
                .parse_default_env()
                // Hard-floor noisy wgpu internals AFTER parse_default_env() so
                // a broad RUST_LOG=info can't let them pollute the log.
                .filter_module("wgpu", wgpu_level)
                .filter_module("wgpu_core", wgpu_level)
                .filter_module("wgpu_hal", wgpu_level)
                .filter_module("naga", wgpu_level)
                .format(move |buf, record| {
                    let ts = buf.timestamp_millis();
                    let line = format!("[{}] {:5} {}\n", ts, record.level(), record.args());
                    // Write to stderr (env_logger's buf is already going there)
                    writeln!(buf, "[{}] {:5} {}", ts, record.level(), record.args())?;
                    // Also write plain text (no ANSI) to the file.
                    if let Ok(mut f) = file_clone.lock() {
                        let _ = f.write_all(line.as_bytes());
                    }
                    Ok(())
                })
                .init();
            log_msg!(info, L081_LOG_FILE, "{}", log_path.display());
        }
        Err(e) => {
            env_logger::Builder::new()
                .filter_level(level)
                .parse_default_env()
                .filter_module("wgpu", wgpu_level)
                .filter_module("wgpu_core", wgpu_level)
                .filter_module("wgpu_hal", wgpu_level)
                .filter_module("naga", wgpu_level)
                .format_timestamp_millis()
                .init();
            log_msg!(
                warn,
                L082_LOG_FILE_FAIL,
                "path: {}, err: {}",
                log_path.display(),
                e
            );
        }
    }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

fn call_lua_callback<'a, A: IntoLuaMulti<'a>>(lua: &'a Lua, name: &str, args: A) {
    if let Ok(luna) = lua.globals().get::<_, LuaTable>("luna") {
        if let Ok(func) = luna.get::<_, LuaFunction>(name) {
            if let Err(e) = func.call::<_, ()>(args) {
                log_msg!(error, L011_LUA_ERROR, "lurek.{}(): {}", name, e);
            }
        }
    }
}

/// Calls a Lua callback and returns the error instead of logging it.
fn call_lua_callback_checked<'a, A: IntoLuaMulti<'a>>(
    lua: &'a Lua,
    name: &str,
    args: A,
) -> Result<(), mlua::Error> {
    if let Ok(luna) = lua.globals().get::<_, LuaTable>("luna") {
        if let Ok(func) = luna.get::<_, LuaFunction>(name) {
            func.call::<_, ()>(args)?;
        }
    }
    Ok(())
}

/// Tries calling `lurek.errorhandler(msg)`. If it exists and succeeds, returns its
/// error screen (showing that the handler was called). If it fails or doesn't exist,
/// returns the default error screen for the original error.
fn try_errorhandler_or_screen(lua: &Lua, err: &mlua::Error) -> ErrorScreen {
    let msg = format!("{}", err);
    log_msg!(error, L011_LUA_ERROR, "runtime: {}", msg);
    if let Ok(luna) = lua.globals().get::<_, LuaTable>("luna") {
        if let Ok(handler) = luna.get::<_, LuaFunction>("errorhandler") {
            match handler.call::<_, ()>(msg.clone()) {
                Ok(()) => {
                    // Handler ran successfully — still show error screen since
                    // the game state is likely corrupt.
                    return ErrorScreen::from_lua_error(err);
                }
                Err(handler_err) => {
                    // Handler itself errored. Show both errors.
                    let combined = format!(
                        "Error in luna.errorhandler\nOriginal error: {}\n\nHandler error: {}",
                        msg, handler_err
                    );
                    return ErrorScreen::from_error(&combined);
                }
            }
        }
    }
    ErrorScreen::from_lua_error(err)
}

#[allow(clippy::vec_init_then_push)]
fn make_splash_commands(
    width: u32,
    height: u32,
    small_key: FontKey,
    fonts: &mut SlotMap<FontKey, crate::graphics::Font>,
    branding: Option<&SplashBranding>,
    drag_hover: bool,
) -> Vec<DrawCommand> {
    let width_f = width as f32;
    let height_f = height as f32;
    let cx = width_f / 2.0;
    let hint_text = if drag_hover {
        "Release to load game"
    } else {
        "Drop a game folder here to load it"
    };
    let hint_w = fonts
        .get_mut(small_key)
        .map(|f| f.text_width(hint_text))
        .unwrap_or(0.0);

    let top_margin = 24.0_f32;
    let hint_band_top = height_f - 82.0;

    let mut cmds: Vec<DrawCommand> = Vec::new();

    if let Some(branding) = branding {
        let (icon_w, icon_h) = fit_contain_size(
            branding.large_icon.width,
            branding.large_icon.height,
            width_f * 0.46,
            height_f * 0.40,
        );
        let (banner_w, banner_h) = fit_contain_size(
            branding.banner.width,
            branding.banner.height,
            width_f * 0.80,
            height_f * 0.22,
        );

        let banner_center_min = top_margin + banner_h * 0.5;
        let banner_center_max = (hint_band_top - 18.0 - banner_h * 0.5).max(banner_center_min);
        let banner_center_y = (height_f * 0.72).clamp(banner_center_min, banner_center_max);

        let icon_center_min = top_margin + icon_h * 0.5;
        let icon_center_max =
            (banner_center_y - banner_h * 0.5 - 32.0 - icon_h * 0.5).max(icon_center_min);
        let icon_center_y = (height_f * 0.33).clamp(icon_center_min, icon_center_max);

        cmds.push(DrawCommand::SetColor(1.0, 1.0, 1.0, 1.0));
        cmds.push(DrawCommand::DrawImageEx {
            texture_key: branding.large_icon.texture_key,
            x: cx,
            y: icon_center_y,
            rotation: 0.0,
            sx: icon_w / branding.large_icon.width as f32,
            sy: icon_h / branding.large_icon.height as f32,
            ox: branding.large_icon.width as f32 * 0.5,
            oy: branding.large_icon.height as f32 * 0.5,
            effect: None,
        });
        cmds.push(DrawCommand::DrawImageEx {
            texture_key: branding.banner.texture_key,
            x: cx,
            y: banner_center_y,
            rotation: 0.0,
            sx: banner_w / branding.banner.width as f32,
            sy: banner_h / branding.banner.height as f32,
            ox: branding.banner.width as f32 * 0.5,
            oy: branding.banner.height as f32 * 0.5,
            effect: None,
        });
    }

    // ── Drop hint (bottom of screen) ─────────────────────────────────────────
    if drag_hover {
        cmds.push(DrawCommand::SetColor(0.40, 0.80, 0.40, 0.15));
        cmds.push(DrawCommand::Rectangle {
            mode: DrawMode::Fill,
            x: cx - 220.0,
            y: height_f - 70.0,
            w: 440.0,
            h: 40.0,
        });
        cmds.push(DrawCommand::SetColor(0.50, 0.90, 0.50, 1.0));
    } else {
        cmds.push(DrawCommand::SetColor(0.35, 0.30, 0.45, 1.0));
    }
    cmds.push(DrawCommand::PrintFont {
        font_key: small_key,
        text: hint_text.to_string(),
        x: cx - hint_w / 2.0,
        y: height_f - 55.0,
        scale: 1.0,
    });

    cmds
}

#[cfg(test)]
mod tests {
    use super::*;

    use tempfile::TempDir;

    #[test]
    fn test_init_lua_applies_identity_to_filesystem_state_and_api() {
        let temp_dir = TempDir::new().expect("Failed to create temp dir");
        let mut config = Config::default();
        config.identity = Some("phase01-save".to_string());

        let mut app = LunaApp::new(config, temp_dir.path().to_path_buf(), None, false, None, 1);
        app.init_lua();

        let lua = app.lua.as_ref().expect("Lua VM should be initialized");
        let reported_identity: String = lua
            .load("return luna.fs.getIdentity()")
            .eval()
            .expect("filesystem identity should be readable from Lua");
        assert_eq!(reported_identity, "phase01-save");

        let state = app
            .state
            .as_ref()
            .expect("shared state should be initialized");
        assert_eq!(state.borrow().filesystem_identity, "phase01-save");
        assert!(matches!(app.run_state, RunState::Running));
    }

    // ── recompute_viewport ────────────────────────────────────────────────────

    /// Build a WindowState with the given mode and game size for viewport tests.
    fn make_ws(mode: &str, game_w: f32, game_h: f32) -> WindowState {
        let mut ws = WindowState::default();
        ws.scale_mode_str = mode.to_string();
        ws.game_width = game_w;
        ws.game_height = game_h;
        ws
    }

    #[test]
    fn recompute_viewport_letterbox_wide_window_uses_height_limited_scale() {
        // 800×600 game, 1600×600 window → scale limited by height (600/600 = 1.0)
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 600);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale_x should be 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale_y should be 1.0, got {}",
            ws.viewport_scale_y
        );
        // offset_x = (1600 - 800*1) * 0.5 = 400
        assert!(
            (ws.viewport_offset_x - 400.0).abs() < 1e-4,
            "offset_x should be 400.0, got {}",
            ws.viewport_offset_x
        );
        assert!(
            ws.viewport_offset_y.abs() < 1e-4,
            "offset_y should be 0.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_letterbox_tall_window_adds_top_bottom_bars() {
        // 800×600 game, 800×900 window → scale = min(1.0, 1.5) = 1.0
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 800, 900);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale_x should be 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale_y should be 1.0, got {}",
            ws.viewport_scale_y
        );
        assert!(
            ws.viewport_offset_x.abs() < 1e-4,
            "offset_x should be 0.0, got {}",
            ws.viewport_offset_x
        );
        // offset_y = (900 - 600*1) * 0.5 = 150
        assert!(
            (ws.viewport_offset_y - 150.0).abs() < 1e-4,
            "offset_y should be 150.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_letterbox_doubled_window_gives_scale_two() {
        // 800×600 game, 1600×1200 window → scale = min(2.0, 2.0) = 2.0, no offset
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 1200);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 2.0).abs() < 1e-4,
            "scale_y should be 2.0, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4, "offset_x should be 0.0");
        assert!(ws.viewport_offset_y.abs() < 1e-4, "offset_y should be 0.0");
    }

    #[test]
    fn recompute_viewport_stretch_produces_nonuniform_scale() {
        // 800×600 game, 1600×1200 window → scale_x = 2.0, scale_y = 2.0, no offset
        let mut ws = make_ws("stretch", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 1200);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 2.0).abs() < 1e-4,
            "scale_y should be 2.0, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }

    #[test]
    fn recompute_viewport_stretch_nonuniform_window() {
        // 800×600 game, 1600×900 window → scale_x = 2.0, scale_y = 1.5 (non-uniform)
        let mut ws = make_ws("stretch", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 900);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.5).abs() < 1e-4,
            "scale_y should be 1.5, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }

    #[test]
    fn recompute_viewport_pixel_uses_integer_scale() {
        // 320×240 game, 1000×800 window → raw scale = min(3.125, 3.333) = 3.125 → floor = 3
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 1000, 800);
        assert!(
            (ws.viewport_scale_x - 3.0).abs() < 1e-4,
            "scale_x should be 3.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 3.0).abs() < 1e-4,
            "scale_y should be 3.0, got {}",
            ws.viewport_scale_y
        );
        // offset_x = (1000 - 320*3) * 0.5 = (1000 - 960) * 0.5 = 20
        assert!(
            (ws.viewport_offset_x - 20.0).abs() < 1e-4,
            "offset_x should be 20.0, got {}",
            ws.viewport_offset_x
        );
        // offset_y = (800 - 240*3) * 0.5 = (800 - 720) * 0.5 = 40
        assert!(
            (ws.viewport_offset_y - 40.0).abs() < 1e-4,
            "offset_y should be 40.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_pixel_window_barely_larger_than_game_gives_scale_one() {
        // 320×240 game, 321×241 window → raw = min(1.003, 1.004) = 1.003 → floor = 1
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 321, 241);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale should floor to 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale should floor to 1.0, got {}",
            ws.viewport_scale_y
        );
    }

    #[test]
    fn recompute_viewport_pixel_window_smaller_than_game_clamps_to_one() {
        // 320×240 game, 100×100 window → raw = ~0.31 → floor = 0 → max(1) = 1
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 100, 100);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale should clamp to 1.0 minimum, got {}",
            ws.viewport_scale_x
        );
    }

    #[test]
    fn recompute_viewport_none_mode_passthrough() {
        let mut ws = make_ws("none", 800.0, 600.0);
        recompute_viewport(&mut ws, 1920, 1080);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "none mode: scale_x should be 1.0"
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "none mode: scale_y should be 1.0"
        );
        assert!(
            ws.viewport_offset_x.abs() < 1e-4,
            "none mode: offset_x should be 0"
        );
        assert!(
            ws.viewport_offset_y.abs() < 1e-4,
            "none mode: offset_y should be 0"
        );
    }

    #[test]
    fn recompute_viewport_unknown_mode_acts_as_none() {
        let mut ws = make_ws("bogus", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 900);
        assert!((ws.viewport_scale_x - 1.0).abs() < 1e-4);
        assert!((ws.viewport_scale_y - 1.0).abs() < 1e-4);
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }
}
