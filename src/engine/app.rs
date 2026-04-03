//! Luna2D application lifecycle using winit 0.30 + wgpu GPU rendering.
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
use crate::graphics::renderer::{DrawCommand, DrawMode, TextureData};
use crate::graphics::GpuRenderer;
use crate::input::keyboard::{winit_key_to_string, winit_scancode_to_string};
use crate::input::{gilrs_axis_to_string, gilrs_button_to_string, SystemCursor};
use crate::engine::{FullscreenType, SharedState};
use crate::lua_api::create_lua_vm;
use slotmap::SlotMap;

use gilrs::{
    Axis as GilrsAxis, Button as GilrsButton, Event as GilrsEvent, EventType as GilrsEventType,
    Gilrs,
};

use super::config::Config;

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

// ─── Luna2D Application handler ──────────────────────────────────────────────

/// Luna2D application state managed by the winit event loop.
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
    renderer: Option<GpuRenderer>,

    // Lua runtime.
    lua: Option<Lua>,
    state: Option<Rc<RefCell<SharedState>>>,
    has_game: bool,

    // Frame-rate limiting.
    last_frame: Instant,

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

    /// Lazily-initialised TTF fonts for the splash screen.
    splash_fonts: Option<(SlotMap<FontKey, crate::graphics::Font>, FontKey, FontKey)>,

    /// Lazily-initialised TTF fonts for the error screen.
    error_fonts: Option<(SlotMap<FontKey, crate::graphics::Font>, FontKey, FontKey)>,

    /// `false` until the first `RedrawRequested` triggers `init_lua()`, ensuring
    /// the splash frame is visible before the Lua VM blocks the event loop.
    lua_initialized: bool,
}

impl LunaApp {
    fn new(
        config: Config,
        game_dir: PathBuf,
        conf_error: Option<String>,
        explicit_game_dir: bool,
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
            renderer: None,
            lua: None,
            state: None,
            has_game: false,
            last_frame: Instant::now(),
            prev_mouse: [false; 5],
            mouse_x: 0.0,
            mouse_y: 0.0,
            gilrs: None,
            run_state: RunState::Running,
            debug_overlay: DebugOverlay::new(),
            conf_error,
            explicit_game_dir,
            window_vsync_mode,
            splash_fonts: None,
            error_fonts: None,
            lua_initialized: false,
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

    fn surface_configuration(&self, width: u32, height: u32) -> wgpu::SurfaceConfiguration {
        wgpu::SurfaceConfiguration {
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
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
        let backends = wgpu::util::backend_bits_from_env().unwrap_or_else(|| {
            match self.config.graphics.backend.as_str() {
                "dx12" => wgpu::Backends::DX12,
                "vulkan" => wgpu::Backends::VULKAN,
                "metal" => wgpu::Backends::METAL,
                _ => wgpu::Backends::PRIMARY, // "auto" or any unrecognised value
            }
        });

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
        log::info!(
            "GPU adapter: {} ({:?}, {:?}) [backend={}, power={}]",
            adapter_info.name,
            adapter_info.backend,
            adapter_info.device_type,
            self.config.graphics.backend,
            self.config.graphics.power_preference,
        );

        let (device, queue) = pollster::block_on(adapter.request_device(
            &wgpu::DeviceDescriptor {
                label: Some("Luna2D Device"),
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
        (self.surface_present_mode, self.window_vsync_mode) =
            Self::resolve_present_mode(&self.surface_present_modes, self.window_vsync_mode);

        surface.configure(&device, &self.surface_configuration(width, height));

        let renderer = GpuRenderer::new(device, queue, surface_format, width, height);

        self.surface = Some(surface);
        self.renderer = Some(renderer);
        self.window = Some(window);
        log::info!(
            "GPU initialised in {:.0?} (format={:?}, present={:?}, {}×{})",
            t0.elapsed(),
            surface_format,
            self.surface_present_mode,
            width,
            height,
        );
    }

    fn init_lua(&mut self) {
        // Show conf.lua error if present
        if let Some(conf_err) = self.conf_error.take() {
            self.run_state = RunState::Error(ErrorScreen::from_error(&format!(
                "Configuration Error\n{}",
                conf_err
            )));
        }

        let mut shared_state = SharedState::new(
            self.config.window.width,
            self.config.window.height,
            &self.config.window.title,
            self.game_dir.clone(),
        );
        if let Some(identity) = &self.config.identity {
            shared_state.filesystem_identity = identity.clone();
        }
        shared_state.window_state.vsync_mode = self.window_vsync_mode;
        shared_state.window = self.window.as_ref().map(Arc::clone);
        let state = Rc::new(RefCell::new(shared_state));

        let lua = match create_lua_vm(state.clone()) {
            Ok(l) => l,
            Err(e) => {
                log::error!("Failed to initialise Lua VM: {}", e);
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
            log::info!("Loading game from: {}", main_lua.display());
            match std::fs::read_to_string(&main_lua) {
                Ok(code) => {
                    if let Err(e) = lua.load(&code).set_name("main.lua").exec() {
                        log::error!("Lua error in main.lua: {}", e);
                        self.run_state = RunState::Error(ErrorScreen::from_lua_error(&e));
                    } else {
                        if let Err(e) = call_lua_callback_checked(&lua, "load", ()) {
                            self.run_state = RunState::Error(try_errorhandler_or_screen(&lua, &e));
                        }
                        self.has_game = true;
                    }
                }
                Err(e) => {
                    log::error!("Failed to read main.lua: {}", e);
                    self.run_state = RunState::Error(ErrorScreen::from_error(&format!(
                        "Failed to read main.lua\n{}",
                        e
                    )));
                }
            }
        } else if self.explicit_game_dir {
            // Explicitly passed a directory but it has no main.lua
            let msg = format!("No game found\nNo main.lua at: {}", self.game_dir.display());
            log::warn!("{}", msg);
            self.run_state = RunState::Error(ErrorScreen::from_error(&msg));
        } else {
            log::info!("No game loaded — showing splash screen.");
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
                    log::debug!(
                        "Failed to apply relative cursor grab mode: {}",
                        confined_error
                    );
                }
            } else if mouse_grabbed {
                log::debug!("Failed to apply cursor grab mode: {}", error);
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
                log::debug!("Failed to set cursor position: {}", error);
            }
        }

        // Apply pending close
        if pending_close {
            state.borrow_mut().quit_requested = true;
        }
    }

    fn game_update(&mut self) {
        let (Some(lua), Some(state)) = (&self.lua, &self.state) else {
            return;
        };
        let dt = state.borrow().clock.delta();
        if let Err(e) = call_lua_callback_checked(lua, "update", dt) {
            self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
            return;
        }

        state.borrow_mut().draw_commands.clear();
        if let Err(e) = call_lua_callback_checked(lua, "draw", ()) {
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

        let (commands, textures, shaders, default_filter, bg, cam_matrix, frame_time) = {
            let st = state.borrow();
            (
                st.draw_commands.clone(),
                st.textures.clone(),
                st.shaders.clone(),
                st.default_filter.clone(),
                st.background_color,
                st.camera.view_matrix(),
                st.total_time as f32,
            )
        };

        // Temporarily take fonts out of SharedState for mutable access during rendering.
        let mut fonts = std::mem::take(&mut state.borrow_mut().fonts);
        let sprite_batches = std::mem::take(&mut state.borrow_mut().sprite_batches);
        let canvases = state.borrow().canvases.clone();
        let meshes = state.borrow().meshes.clone();

        if let Err(e) = renderer.render_frame(
            surface,
            &commands,
            &textures,
            &mut fonts,
            &sprite_batches,
            &canvases,
            &meshes,
            &shaders,
            &default_filter,
            bg,
            &cam_matrix,
            frame_time,
        ) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                log::warn!("Surface lost/outdated — reconfiguring…");
                state.borrow_mut().fonts = fonts;
                state.borrow_mut().sprite_batches = sprite_batches;
                self.reconfigure_surface();
                return;
            } else {
                log::error!("Render error: {:?}", e);
            }
        }

        // Put fonts and sprite batches back.
        state.borrow_mut().fonts = fonts;
        state.borrow_mut().sprite_batches = sprite_batches;

        // Copy render stats to SharedState for Lua access.
        state.borrow_mut().render_stats = renderer.render_stats.clone();
    }

    fn render_splash(&mut self) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        let total_time = self
            .state
            .as_ref()
            .map_or(0.0, |s| s.borrow().clock.total());

        // Lazily initialise TTF fonts for the splash screen.
        if self.splash_fonts.is_none() {
            static FONT_DATA: &[u8] = include_bytes!("../../assets/fonts/OpenSans.ttf");
            let mut fonts: SlotMap<FontKey, crate::graphics::Font> = SlotMap::with_key();
            let title_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 36.0).expect("embedded font");
            let small_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 18.0).expect("embedded font");
            let title_key = fonts.insert(title_font);
            let small_key = fonts.insert(small_font);
            self.splash_fonts = Some((fonts, title_key, small_key));
        }
        let (splash_fonts, title_key, small_key) = self.splash_fonts.as_mut().unwrap();

        let cmds = make_splash_commands(
            renderer.width,
            renderer.height,
            total_time,
            *title_key,
            *small_key,
            splash_fonts,
        );
        let bg = [0.12, 0.08, 0.20, 1.0];
        let no_batches: SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch> = SlotMap::with_key();
        let no_canvases: SlotMap<CanvasKey, crate::graphics::Canvas> = SlotMap::with_key();
        let no_textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
        let no_meshes: SlotMap<MeshKey, crate::graphics::Mesh> = SlotMap::with_key();
        let no_shaders: SlotMap<ShaderKey, crate::graphics::Shader> = SlotMap::with_key();
        let default_filter = ("linear".to_string(), "linear".to_string(), 1);
        if let Err(e) = renderer.render_frame(
            surface,
            &cmds,
            &no_textures,
            splash_fonts,
            &no_batches,
            &no_canvases,
            &no_meshes,
            &no_shaders,
            &default_filter,
            bg,
            &crate::math::Mat3::identity(),
            total_time as f32,
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

        // Lazily initialise TTF fonts for the error screen (same as splash).
        if self.error_fonts.is_none() {
            static FONT_DATA: &[u8] = include_bytes!("../../assets/fonts/OpenSans.ttf");
            let mut fonts: SlotMap<FontKey, crate::graphics::Font> = SlotMap::with_key();
            let heading_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 32.0).expect("embedded font");
            let body_font =
                crate::graphics::Font::from_bytes(FONT_DATA, 16.0).expect("embedded font");
            let heading_key = fonts.insert(heading_font);
            let body_key = fonts.insert(body_font);
            self.error_fonts = Some((fonts, heading_key, body_key));
        }
        let (error_fonts, heading_key, body_key) = self.error_fonts.as_mut().unwrap();

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
        if let Err(e) = renderer.render_frame(
            surface,
            &cmds,
            &no_textures,
            error_fonts,
            &no_batches,
            &no_canvases,
            &no_meshes,
            &no_shaders,
            &default_filter,
            bg,
            &crate::math::Mat3::identity(),
            0.0,
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
        }
        // Fire luna.resize(w, h) callback
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
                    log::info!("Gamepad {} connected", id_usize);
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
                    log::info!("Gamepad {} disconnected", id_usize);
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
            log::warn!(
                "Failed to load window icon '{}': {}",
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
            log::warn!(
                "Failed to convert window icon '{}': {}",
                resolved_path.display(),
                error
            );
            None
        }
    }
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
        log::warn!(
            "Configured display index {} is unavailable; falling back to the primary monitor",
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

        let mut window_attrs = Window::default_attributes()
            .with_title(&self.config.window.title)
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

        if let Some(icon_path) = self.config.window.icon.as_deref() {
            if let Some(icon) = load_window_icon(&self.game_dir, icon_path) {
                window.set_window_icon(Some(icon));
            }
        }

        self.init_gpu(window);

        // Initialize gilrs gamepad polling (can happen before Lua VM).
        match Gilrs::new() {
            Ok(g) => self.gilrs = Some(g),
            Err(e) => log::warn!("Gilrs init failed (gamepads unavailable): {}", e),
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
                log::info!("Window close requested.");
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
                self.mouse_x = position.x as f32;
                self.mouse_y = position.y as f32;
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    st.mouse.x = self.mouse_x;
                    st.mouse.y = self.mouse_y;
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

                // Check quit flag from Lua (e.g., luna.event.quit()).
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

            _ => {}
        }
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        use std::time::Duration;
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

/// Entry point for the Luna2D engine. Owns the game loop, GPU renderer, and Lua VM lifecycle.
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
    pub fn run(self, game_dir: PathBuf, explicit_game_dir: bool) {
        init_logging(
            &game_dir,
            self.config.log_file.as_deref(),
            self.config.log_append,
        );
        log::info!(
            "Luna2D Engine v{} starting (wgpu GPU backend)",
            env!("CARGO_PKG_VERSION"),
        );
        log::info!("Game directory: {}", game_dir.display());

        let event_loop = EventLoop::new().expect("Failed to create event loop");
        // Start with Poll so the first frame and init_lua run as fast as
        // possible. about_to_wait() switches to WaitUntil after that.
        event_loop.set_control_flow(ControlFlow::Poll);

        let mut app = LunaApp::new(self.config, game_dir, self.conf_error, explicit_game_dir);
        event_loop.run_app(&mut app).expect("Event loop error");

        log::info!("Luna2D Engine shut down.");
    }
}

// ─── Logging ─────────────────────────────────────────────────────────────────

/// Initialises logging to both stderr and a log file.
///
/// `log_file` is a path relative to `game_dir` (or absolute). When `None`,
/// the file is placed at `cwd/luna2d.log`.  When `log_append` is `true` the
/// file is opened in append mode instead of being truncated.
fn init_logging(game_dir: &Path, log_file: Option<&str>, log_append: bool) {
    use std::io::Write as _;

    // Resolve log file path: custom path relative to game_dir, or cwd/luna2d.log default.
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

    // Debug builds log everything (debug + info + warn + error) to aid bug
    // hunting.  Release builds log errors only to keep the log file lean.
    let level = if cfg!(debug_assertions) {
        log::LevelFilter::Debug
    } else {
        log::LevelFilter::Error
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
            log::info!("Log file: {}", log_path.display());
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
            log::warn!(
                "Could not create log file '{}': {} — logging to stderr only",
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
                log::error!("Lua error in luna.{}(): {}", name, e);
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

/// Tries calling `luna.errorhandler(msg)`. If it exists and succeeds, returns its
/// error screen (showing that the handler was called). If it fails or doesn't exist,
/// returns the default error screen for the original error.
fn try_errorhandler_or_screen(lua: &Lua, err: &mlua::Error) -> ErrorScreen {
    let msg = format!("{}", err);
    log::error!("Lua runtime error: {}", msg);
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

fn make_splash_commands(
    width: u32,
    height: u32,
    time: f64,
    title_key: FontKey,
    small_key: FontKey,
    fonts: &mut SlotMap<FontKey, crate::graphics::Font>,
) -> Vec<DrawCommand> {
    let cx = width as f32 / 2.0;
    let cy = height as f32 / 2.0;
    let pulse = 1.0 + (time * 2.0).sin() as f32 * 0.05;
    let moon_r = 60.0 * pulse;

    let title_text = "LUNA2D";
    let subtitle_text = "2D Game Engine";
    let version_text = format!("v{}", env!("CARGO_PKG_VERSION"));

    // Measure text widths for centering.
    let title_w = fonts
        .get_mut(title_key)
        .map(|f| f.text_width(title_text))
        .unwrap_or(0.0);
    let subtitle_w = fonts
        .get_mut(small_key)
        .map(|f| f.text_width(subtitle_text))
        .unwrap_or(0.0);
    let version_w = fonts
        .get_mut(small_key)
        .map(|f| f.text_width(&version_text))
        .unwrap_or(0.0);

    vec![
        // Moon crescent
        DrawCommand::SetColor(0.95, 0.90, 0.55, 1.0),
        DrawCommand::Circle {
            mode: DrawMode::Fill,
            x: cx,
            y: cy - 40.0,
            r: moon_r,
        },
        DrawCommand::SetColor(0.12, 0.08, 0.20, 1.0),
        DrawCommand::Circle {
            mode: DrawMode::Fill,
            x: cx + 25.0,
            y: cy - 55.0,
            r: moon_r * 0.85,
        },
        // Title
        DrawCommand::SetColor(0.95, 0.90, 0.55, 1.0),
        DrawCommand::PrintFont {
            font_key: title_key,
            text: title_text.to_string(),
            x: cx - title_w / 2.0,
            y: cy + 45.0,
            scale: 1.0,
        },
        // Subtitle
        DrawCommand::SetColor(0.6, 0.55, 0.7, 1.0),
        DrawCommand::PrintFont {
            font_key: small_key,
            text: subtitle_text.to_string(),
            x: cx - subtitle_w / 2.0,
            y: cy + 85.0,
            scale: 1.0,
        },
        // Version
        DrawCommand::SetColor(0.4, 0.35, 0.5, 1.0),
        DrawCommand::PrintFont {
            font_key: small_key,
            text: version_text,
            x: cx - version_w / 2.0,
            y: cy + 110.0,
            scale: 1.0,
        },
    ]
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

        let mut app = LunaApp::new(config, temp_dir.path().to_path_buf(), None, false);
        app.init_lua();

        let lua = app.lua.as_ref().expect("Lua VM should be initialized");
        let reported_identity: String = lua
            .load("return luna.filesystem.getIdentity()")
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
}
