//! Main runtime application loop and platform orchestration.
//! Bridges winit events, renderer surface lifecycle, Lua callbacks, input routing,
//! hot-reload watchers, splash/error/debug overlays, and game loading handoff.
//! Does not own feature subsystem logic; coordinates subsystem calls and state.

use super::debug_overlay::DebugOverlay;
use super::error_screen::ErrorScreen;
use super::lua_callbacks::{
    call_lua_callback_checked_with_timeout, call_lua_callback_with_timeout,
};
use super::splash_screen::{load_splash_branding, make_splash_commands, SplashBranding};
use crate::event::EventArg;
use crate::filesystem::watcher::FileWatcher;
use crate::input::keyboard::{winit_key_to_string, winit_scancode_to_string};
use crate::input::{gilrs_axis_to_string, gilrs_button_to_string, SystemCursor};
#[allow(unused_imports)]
use crate::log_msg;
use crate::lua_api::create_lua_vm;
use crate::render::renderer::{RenderCommand, TextureData};
use crate::render::GpuRenderer;
pub use crate::runtime::config::Config;
use crate::runtime::log_messages::{
    L003_GAME_LOADED, L006_SPLASH_SCREEN, L007_NO_MAIN_LUA, L010_RENDER_ERROR, L011_LUA_ERROR,
    L016_LUA_VM_INIT_FAIL, L017_MAIN_LUA_READ_FAIL, L021_CLIPBOARD_FAIL, L023_GPU_TEX_TOO_SMALL,
    L024_SURFACE_LOST, L033_GPU_ADAPTER, L034_GPU_TEX_DIM, L035_GPU_INIT, L036_GAMEPAD_CONNECTED,
    L037_GAMEPAD_DISCONNECTED, L038_GILRS_UNAVAILABLE, L039_WINDOW_CLOSE, L040_ICON_LOAD_FAIL,
    L041_ICON_CONV_FAIL, L043_DROP_FILE, L044_DROP_GAME, L070_SURFACE_NO_READBACK,
    L071_CURSOR_GRAB_FAIL, L072_CURSOR_GRAB_LOCK_FAIL, L073_CURSOR_POS_FAIL,
    L074_SCREENSHOT_NO_READBACK, L075_SCREENSHOT_SAVE_FAIL, L076_SCREENSHOT_ENCODE_FAIL,
    L077_DRAG_HOVER, L078_DRAG_HOVER_CANCEL, L079_DRAG_DROP_IGNORED, L080_GAME_DIR, L081_LOG_FILE,
    L082_LOG_FILE_FAIL, L083_DROP_ARCHIVE, L084_DROP_ARCHIVE_FAIL,
};
use crate::runtime::resource_keys::{
    CanvasKey, FontKey, MeshKey, ShaderKey, SpriteBatchKey, TextureKey,
};
pub use crate::runtime::shared_state::WindowState;
use crate::runtime::{FullscreenType, SharedState};
use crate::window::{center_window_on_monitor, move_window_to_display, select_startup_monitor};
use gilrs::{
    ff::{BaseEffect, BaseEffectType, Effect, EffectBuilder, Envelope, Repeat, Replay, Ticks},
    Axis as GilrsAxis, Button as GilrsButton, Event as GilrsEvent, EventType as GilrsEventType,
    GamepadId as GilrsGamepadId, Gilrs,
};
use mlua::prelude::*;
use slotmap::SlotMap;
use std::cell::RefCell;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::sync::Arc;
use std::time::Instant;
use winit::application::ApplicationHandler;
use winit::event::{ElementState, MouseButton, WindowEvent};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::keyboard::PhysicalKey;
use winit::window::{CursorGrabMode, CursorIcon, Window, WindowId};
/// Recompute viewport scale and offset from game-space size to current window size.
pub fn recompute_viewport(ws: &mut WindowState, win_w: u32, win_h: u32) {
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
            ws.viewport_scale_x = 1.0;
            ws.viewport_scale_y = 1.0;
            ws.viewport_offset_x = 0.0;
            ws.viewport_offset_y = 0.0;
        }
    }
}
/// High-level app runtime state used by the frame/event loop.
pub enum RunState {
    /// Normal game/runtime execution.
    Running,
    /// Fatal error mode that renders an `ErrorScreen`.
    Error(ErrorScreen),
    /// Transition state while rebuilding runtime after reload/restart.
    Restarting,
}
/// Build splash window title with engine version suffix.
pub fn splash_window_title(base_title: &str) -> String {
    format!("{} v{}", base_title, env!("CARGO_PKG_VERSION"))
}
/// Fit source size into max bounds while preserving aspect ratio.
pub fn fit_contain_size(src_w: u32, src_h: u32, max_w: f32, max_h: f32) -> (f32, f32) {
    let src_w = src_w.max(1) as f32;
    let src_h = src_h.max(1) as f32;
    let scale = (max_w.max(1.0) / src_w).min(max_h.max(1.0) / src_h);
    (src_w * scale, src_h * scale)
}
/// Central app runtime state shared by winit callbacks and frame update/render flow.
pub struct LurekApp {
    /// Holds config state.
    config: Config,
    /// Holds game_dir state.
    game_dir: PathBuf,
    /// Holds window state.
    window: Option<Arc<Window>>,
    /// Holds surface state.
    surface: Option<wgpu::Surface<'static>>,
    /// Holds surface_format state.
    surface_format: wgpu::TextureFormat,
    /// Holds surface_alpha_mode state.
    surface_alpha_mode: wgpu::CompositeAlphaMode,
    /// Holds surface_present_modes state.
    surface_present_modes: Vec<wgpu::PresentMode>,
    /// Holds surface_present_mode state.
    surface_present_mode: wgpu::PresentMode,
    /// Holds surface_usage state.
    surface_usage: wgpu::TextureUsages,
    /// Holds renderer state.
    renderer: Option<GpuRenderer>,
    /// Holds lua state.
    pub lua: Option<Lua>,
    /// Holds state state.
    pub state: Option<Rc<RefCell<SharedState>>>,
    /// Holds has_game state.
    has_game: bool,
    /// Holds last_frame state.
    last_frame: Instant,
    /// Holds ready_fired state.
    ready_fired: bool,
    /// Holds physics_accumulator state.
    physics_accumulator: f64,
    /// Holds fixed_update_accumulator state.
    fixed_update_accumulator: f64,
    /// Holds prev_mouse state.
    prev_mouse: [bool; 5],
    /// Holds mouse_x state.
    mouse_x: f32,
    /// Holds mouse_y state.
    mouse_y: f32,
    /// Holds gilrs state.
    gilrs: Option<Gilrs>,
    /// Holds gamepad_effects state.
    gamepad_effects: HashMap<usize, Effect>,
    /// Holds run_state state.
    pub run_state: RunState,
    /// Holds debug_overlay state.
    debug_overlay: DebugOverlay,
    /// Holds conf_error state.
    conf_error: Option<String>,
    /// Holds conf_watcher state.
    conf_watcher: FileWatcher,
    /// Holds content_script_watcher state.
    content_script_watcher: FileWatcher,
    /// Holds content_asset_watcher state.
    content_asset_watcher: FileWatcher,
    /// Holds explicit_game_dir state.
    explicit_game_dir: bool,
    /// Holds window_vsync_mode state.
    window_vsync_mode: i32,
    /// Holds engine_fonts state.
    engine_fonts: Option<(SlotMap<FontKey, crate::render::Font>, FontKey, FontKey)>,
    /// Holds splash_branding state.
    splash_branding: Option<SplashBranding>,
    /// Holds splash_branding_failed state.
    splash_branding_failed: bool,
    /// Holds ctrl_held state.
    ctrl_held: bool,
    /// Holds lua_initialized state.
    lua_initialized: bool,
    /// Holds drag_hover state.
    drag_hover: bool,
    /// Holds max_surface_dim state.
    max_surface_dim: u32,
    /// Holds render_cmd_buf state.
    render_cmd_buf: Vec<RenderCommand>,
    /// Holds auto_parallax_buf state.
    auto_parallax_buf: Vec<Rc<RefCell<crate::parallax::ParallaxLayer>>>,
    /// Holds auto_tilemap_buf state.
    auto_tilemap_buf: Vec<Rc<RefCell<crate::tilemap::TileMap>>>,
    /// Holds auto_particle_cmd_buf state.
    auto_particle_cmd_buf: Vec<RenderCommand>,
    /// Holds auto_ui_cmd_buf state.
    auto_ui_cmd_buf: Vec<RenderCommand>,
    /// Holds auto_screenshot_path state.
    auto_screenshot_path: Option<PathBuf>,
    /// Holds auto_screenshot_frames state.
    auto_screenshot_frames: u32,
    /// Holds auto_screenshot_time state.
    auto_screenshot_time: Option<f32>,
    /// Holds auto_screenshot_done state.
    auto_screenshot_done: bool,
    /// Holds auto_screenshot_frame_count state.
    auto_screenshot_frame_count: u32,
    /// Holds auto_screenshot_start state.
    auto_screenshot_start: Option<Instant>,
    /// Holds window_pos state.
    window_pos: Option<(i32, i32)>,
    /// Holds lurek_temp_dir state.
    lurek_temp_dir: Option<tempfile::TempDir>,
    /// Holds perf_report_started state.
    perf_report_started: Instant,
    /// Holds perf_frames state.
    perf_frames: u32,
    /// Holds perf_tick_ms_acc state.
    perf_tick_ms_acc: f64,
    /// Holds perf_update_ms_acc state.
    perf_update_ms_acc: f64,
    /// Holds perf_render_ms_acc state.
    perf_render_ms_acc: f64,
    /// Holds perf_log_enabled state.
    perf_log_enabled: bool,
}
impl LurekApp {
    #[allow(clippy::too_many_arguments)]
    /// Build app runtime state and initialize filesystem watchers from startup config.
    pub fn new(
        config: Config,
        game_dir: PathBuf,
        conf_error: Option<String>,
        explicit_game_dir: bool,
        auto_screenshot_path: Option<PathBuf>,
        auto_screenshot_frames: u32,
        auto_screenshot_time: Option<f32>,
        window_pos: Option<(i32, i32)>,
    ) -> Self {
        let window_vsync_mode = if config.window.vsync { 1 } else { 0 };
        let mut conf_watcher = FileWatcher::new();
        conf_watcher.watch(game_dir.join("conf.toml"));
        let mut content_script_watcher = FileWatcher::new();
        let mut content_asset_watcher = FileWatcher::new();
        register_content_watchers(
            &game_dir,
            &mut content_script_watcher,
            &mut content_asset_watcher,
        );
        LurekApp {
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
            fixed_update_accumulator: 0.0,
            prev_mouse: [false; 5],
            mouse_x: 0.0,
            mouse_y: 0.0,
            gilrs: None,
            gamepad_effects: HashMap::new(),
            run_state: RunState::Running,
            debug_overlay: DebugOverlay::new(),
            conf_error,
            conf_watcher,
            content_script_watcher,
            content_asset_watcher,
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
            auto_parallax_buf: Vec::new(),
            auto_tilemap_buf: Vec::new(),
            auto_particle_cmd_buf: Vec::new(),
            auto_ui_cmd_buf: Vec::new(),
            auto_screenshot_path,
            auto_screenshot_frames,
            auto_screenshot_time,
            auto_screenshot_done: false,
            auto_screenshot_frame_count: 0,
            auto_screenshot_start: None,
            window_pos,
            lurek_temp_dir: None,
            perf_report_started: Instant::now(),
            perf_frames: 0,
            perf_tick_ms_acc: 0.0,
            perf_update_ms_acc: 0.0,
            perf_render_ms_acc: 0.0,
            perf_log_enabled: std::env::var("LUREK_PERF_LOG").ok().as_deref() == Some("1"),
        }
    }
    /// Return callback_timeout_ms result.
    fn callback_timeout_ms(&self) -> Option<f32> {
        self.config.performance.lua_callback_timeout_ms
    }
    /// Update state in refresh_content_watchers.
    fn refresh_content_watchers(&mut self) {
        self.content_script_watcher = FileWatcher::new();
        self.content_asset_watcher = FileWatcher::new();
        register_content_watchers(
            &self.game_dir,
            &mut self.content_script_watcher,
            &mut self.content_asset_watcher,
        );
    }
    /// Update state in perf_record_frame.
    fn perf_record_frame(&mut self, tick_ms: f64, update_ms: f64, render_ms: f64) {
        if !self.perf_log_enabled {
            return;
        }
        self.perf_frames += 1;
        self.perf_tick_ms_acc += tick_ms;
        self.perf_update_ms_acc += update_ms;
        self.perf_render_ms_acc += render_ms;
        let elapsed = self.perf_report_started.elapsed().as_secs_f64();
        if elapsed < 1.0 {
            return;
        }
        let n = (self.perf_frames as f64).max(1.0);
        log::info!(
            "PERF frame_cpu_ms avg: tick={:.3}, update={:.3}, render={:.3}, total={:.3}, fps_est={:.1}",
            self.perf_tick_ms_acc / n,
            self.perf_update_ms_acc / n,
            self.perf_render_ms_acc / n,
            (self.perf_tick_ms_acc + self.perf_update_ms_acc + self.perf_render_ms_acc) / n,
            n / elapsed,
        );
        self.perf_report_started = Instant::now();
        self.perf_frames = 0;
        self.perf_tick_ms_acc = 0.0;
        self.perf_update_ms_acc = 0.0;
        self.perf_render_ms_acc = 0.0;
    }
    /// Return wants_splash_screen result.
    fn wants_splash_screen(&self) -> bool {
        !self.explicit_game_dir && !self.game_dir.join("main.lua").exists()
    }
    /// Return current_window_title result.
    fn current_window_title(&self) -> String {
        if self.wants_splash_screen() {
            splash_window_title(&self.config.window.title)
        } else {
            self.config.window.title.clone()
        }
    }
    /// Select supported present mode and normalized vsync flag from requested mode.
    pub fn resolve_present_mode(
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
    /// Return clamp_surface_dims result.
    fn clamp_surface_dims(&self, w: u32, h: u32) -> (u32, u32) {
        let m = self.max_surface_dim.max(1);
        (w.max(1).min(m), h.max(1).min(m))
    }
    /// Return surface_configuration result.
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
    /// Update state in apply_vsync_mode.
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
    /// Update state in init_gpu.
    fn init_gpu(&mut self, window: Arc<Window>) {
        let t0 = Instant::now();
        let width = self.config.window.width;
        let height = self.config.window.height;
        let backends = wgpu::util::backend_bits_from_env().unwrap_or(
            match self.config.render.backend.as_str() {
                "dx12" => wgpu::Backends::DX12,
                "vulkan" => wgpu::Backends::VULKAN,
                "metal" => wgpu::Backends::METAL,
                _ => wgpu::Backends::PRIMARY,
            },
        );
        let power_preference = match self.config.render.power_preference.as_str() {
            "low" => wgpu::PowerPreference::LowPower,
            "none" => wgpu::PowerPreference::None,
            _ => wgpu::PowerPreference::HighPerformance,
        };
        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends,
            ..Default::default()
        });
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
            self.config.render.backend,
            self.config.render.power_preference,
        );
        let (device, queue) = pollster::block_on(adapter.request_device(
            &wgpu::DeviceDescriptor {
                label: Some("Lurek2D Device"),
                required_features: wgpu::Features::empty(),
                required_limits: {
                    let mut limits = wgpu::Limits::downlevel_defaults();
                    limits.max_texture_dimension_2d = adapter
                        .limits()
                        .max_texture_dimension_2d
                        .max(limits.max_texture_dimension_2d);
                    limits
                },
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
    /// Update state in init_lua.
    pub fn init_lua(&mut self) {
        self.ready_fired = false;
        self.physics_accumulator = 0.0;
        self.fixed_update_accumulator = 0.0;
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
        shared_state.physics_run.fixed_dt =
            1.0 / self.config.performance.physics_tick_rate.max(1) as f64;
        shared_state.physics_run.fixed_update_dt =
            match self.config.performance.fixed_update_tick_rate {
                Some(rate) if rate > 0 => 1.0 / rate as f64,
                _ => 0.0,
            };
        shared_state.frame_budget_warn_ms = self.config.performance.frame_budget_warn_ms;
        shared_state.lua_callback_timeout_ms = self.callback_timeout_ms();
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
        state.borrow_mut().load_default_fonts();
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
                        if let Err(e) = call_lua_callback_checked_with_timeout(
                            &lua,
                            "init",
                            (),
                            self.callback_timeout_ms(),
                        ) {
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
        } else {
            if self.explicit_game_dir {
                log_msg!(warn, L007_NO_MAIN_LUA, "{}", self.game_dir.display());
            }
            log_msg!(info, L006_SPLASH_SCREEN);
        }
        self.lua = Some(lua);
        self.state = Some(state);
    }
    /// Update state in tick_frame.
    fn tick_frame(&mut self) {
        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            let dt = st.clock.tick();
            st.delta_time = dt;
            st.total_time = st.clock.total();
            st.fps = st.clock.fps();
            st.keyboard.begin_frame();
            st.mouse.begin_frame();
            st.touch.begin_frame();
            for gp in &mut st.gamepads {
                gp.begin_frame();
            }
            self.debug_overlay.enabled = st.debug_overlay_enabled;
        }
        self.apply_pending_window_actions();
    }
    /// Update state in apply_pending_window_actions.
    fn apply_pending_window_actions(&mut self) {
        let window = match &self.window {
            Some(w) => w.clone(),
            None => return,
        };
        let state = match &self.state {
            Some(s) => s.clone(),
            None => return,
        };
        let (
            pending_title,
            pending_fullscreen,
            pending_fullscreen_type,
            pending_position,
            pending_display_index,
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
                st.window_state.pending_display_index.take(),
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
        if let Some(title) = pending_title {
            window.set_title(&title);
            state.borrow_mut().window_title = title;
        }
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
        if let Some((x, y)) = pending_position {
            window.set_outer_position(winit::dpi::PhysicalPosition::new(x, y));
        }
        if let Some(display_index) = pending_display_index {
            if !move_window_to_display(window.as_ref(), display_index) {
                log::warn!("Requested display index {} is not available", display_index);
            }
        }
        if let Some((w, h)) = pending_size {
            let _ = window.request_inner_size(winit::dpi::PhysicalSize::new(w, h));
        }
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
        if pending_attention {
            window.request_user_attention(Some(winit::window::UserAttentionType::Informational));
        }
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
        if pending_close {
            state.borrow_mut().quit_requested = true;
        }
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
    /// Update state in game_update.
    fn game_update(&mut self) {
        let (Some(lua), Some(state)) = (&self.lua, &self.state) else {
            return;
        };
        let callback_timeout_ms = self.callback_timeout_ms();
        if self.auto_screenshot_path.is_some() && !self.auto_screenshot_done {
            if self.auto_screenshot_frame_count == 0 {
                self.auto_screenshot_start = Some(Instant::now());
            }
            self.auto_screenshot_frame_count += 1;
        }
        if !self.ready_fired {
            self.ready_fired = true;
            if let Err(e) =
                call_lua_callback_checked_with_timeout(lua, "ready", (), callback_timeout_ms)
            {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
        }
        let dt = state.borrow().clock.delta();
        let mut frame_profile = crate::runtime::FrameProfile::default();
        {
            let phase_start = Instant::now();
            let fixed_dt = state.borrow().physics_run.fixed_dt;
            self.physics_accumulator += dt;
            let max_steps = state.borrow().physics_run.max_steps as usize;
            let mut steps = 0;
            while self.physics_accumulator >= fixed_dt && steps < max_steps {
                self.physics_accumulator -= fixed_dt;
                steps += 1;
                if let Err(e) = call_lua_callback_checked_with_timeout(
                    lua,
                    "process_physics",
                    fixed_dt,
                    callback_timeout_ms,
                ) {
                    self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                    return;
                }
            }
            frame_profile.process_physics_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            let phase_start = Instant::now();
            let fixed_dt = state.borrow().physics_run.fixed_update_dt;
            if fixed_dt > 0.0 {
                self.fixed_update_accumulator += dt;
                let max_steps = 8;
                let mut steps = 0;
                while self.fixed_update_accumulator >= fixed_dt && steps < max_steps {
                    self.fixed_update_accumulator -= fixed_dt;
                    steps += 1;
                    if let Err(e) = call_lua_callback_checked_with_timeout(
                        lua,
                        "fixedUpdate",
                        fixed_dt,
                        callback_timeout_ms,
                    ) {
                        self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                        return;
                    }
                }
            }
            frame_profile.fixed_update_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            let phase_start = Instant::now();
            if let Err(e) =
                call_lua_callback_checked_with_timeout(lua, "process", dt, callback_timeout_ms)
            {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
            frame_profile.process_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            let phase_start = Instant::now();
            if let Err(e) =
                call_lua_callback_checked_with_timeout(lua, "process_late", dt, callback_timeout_ms)
            {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
            frame_profile.process_late_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            let mut s = state.borrow_mut();
            s.render_commands.clear();
            s.raycaster_output = None;
        }
        {
            let s = state.borrow();
            let cam_x = s.camera.position.x;
            let cam_y = s.camera.position.y;
            let screen_w = s.window_state.game_width;
            let screen_h = s.window_state.game_height;
            self.auto_parallax_buf.clear();
            self.auto_parallax_buf
                .extend(s.auto_parallax_layers.iter().filter_map(|w| w.upgrade()));
            drop(s);
            for rc in &self.auto_parallax_buf {
                let cmds = rc
                    .borrow()
                    .generate_render_commands(cam_x, cam_y, screen_w, screen_h);
                state.borrow_mut().render_commands.extend(cmds);
            }
            state
                .borrow_mut()
                .auto_parallax_layers
                .retain(|w| w.upgrade().is_some());
        }
        {
            let s = state.borrow();
            let cam_x = s.camera.position.x;
            let cam_y = s.camera.position.y;
            let cam_w = s.window_state.game_width;
            let cam_h = s.window_state.game_height;
            self.auto_tilemap_buf.clear();
            self.auto_tilemap_buf
                .extend(s.auto_tilemaps.iter().filter_map(|w| w.upgrade()));
            drop(s);
            for rc in &self.auto_tilemap_buf {
                let cmds = rc
                    .borrow()
                    .generate_render_commands(0.0, 0.0, cam_x, cam_y, cam_w, cam_h);
                state.borrow_mut().render_commands.extend(cmds);
            }
            state
                .borrow_mut()
                .auto_tilemaps
                .retain(|w| w.upgrade().is_some());
        }
        {
            let phase_start = Instant::now();
            if let Err(e) =
                call_lua_callback_checked_with_timeout(lua, "draw", (), callback_timeout_ms)
            {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
            frame_profile.draw_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            let scene_opt = state.borrow_mut().raycaster_output.take();
            if let Some(scene) = scene_opt {
                #[derive(Clone)]
                /// Screen-space textured quad with depth used for raycaster depth sorting.
                struct DepthQuad {
                    /// Quad corners in screen space.
                    corners: [crate::math::Vec2; 4],
                    /// UV coordinates per corner.
                    uvs: [crate::math::Vec2; 4],
                    /// Reciprocal depth values per corner for perspective-correct interpolation.
                    corner_w: [f32; 4],
                    /// Texture key used for textured draw.
                    texture_key: TextureKey,
                    /// Per-quad tint/light colour multiplier.
                    color: [f32; 4],
                    /// Depth key used for painter-style ordering.
                    depth: f32,
                }
                /// Depth-sorted render item used by the raycaster composition path.
                enum DepthItem {
                    /// Textured wall/floor/ceiling quad.
                    Quad(DepthQuad),
                    /// Mesh model with depth key.
                    Model(crate::render::Mesh, f32),
                }
                let mut depth_items: Vec<DepthItem> = Vec::with_capacity(scene.quad_count());
                for wall in &scene.walls {
                    if let Some(key) = wall.texture_key {
                        depth_items.push(DepthItem::Quad(DepthQuad {
                            corners: wall.corners,
                            uvs: wall.uvs,
                            corner_w: wall.corner_w,
                            texture_key: key,
                            color: wall.light,
                            depth: wall.depth,
                        }));
                    }
                }
                for floor in &scene.floors {
                    if let Some(key) = floor.texture_key {
                        depth_items.push(DepthItem::Quad(DepthQuad {
                            corners: floor.corners,
                            uvs: floor.uvs,
                            corner_w: floor.corner_w,
                            texture_key: key,
                            color: floor.light,
                            depth: floor.depth,
                        }));
                    }
                }
                for ceil in &scene.ceilings {
                    if let Some(key) = ceil.texture_key {
                        depth_items.push(DepthItem::Quad(DepthQuad {
                            corners: ceil.corners,
                            uvs: ceil.uvs,
                            corner_w: ceil.corner_w,
                            texture_key: key,
                            color: ceil.light,
                            depth: ceil.depth,
                        }));
                    }
                }
                for sprite in &scene.sprites {
                    depth_items.push(DepthItem::Quad(DepthQuad {
                        corners: sprite.corners,
                        uvs: sprite.uvs,
                        corner_w: [1.0, 1.0, 1.0, 1.0],
                        texture_key: sprite.texture_key,
                        color: sprite.light,
                        depth: sprite.depth,
                    }));
                }
                for model in &scene.models {
                    depth_items.push(DepthItem::Model(model.mesh.clone(), model.depth));
                }
                depth_items.sort_by(|a, b| {
                    let ad = match a {
                        DepthItem::Quad(q) => q.depth,
                        DepthItem::Model(_, d) => *d,
                    };
                    let bd = match b {
                        DepthItem::Quad(q) => q.depth,
                        DepthItem::Model(_, d) => *d,
                    };
                    bd.partial_cmp(&ad).unwrap_or(std::cmp::Ordering::Equal)
                });
                let mut s = state.borrow_mut();
                for item in depth_items {
                    match item {
                        DepthItem::Quad(dq) => {
                            s.render_commands.push(RenderCommand::DrawTexturedQuad {
                                corners: dq.corners,
                                uvs: dq.uvs,
                                corner_w: dq.corner_w,
                                texture_key: dq.texture_key,
                                color: dq.color,
                            });
                        }
                        DepthItem::Model(mesh, _) => {
                            s.render_commands.push(RenderCommand::DrawMeshTransient {
                                mesh,
                                x: 0.0,
                                y: 0.0,
                                rotation: 0.0,
                                sx: 1.0,
                                sy: 1.0,
                                ox: 0.0,
                                oy: 0.0,
                            });
                        }
                    }
                }
            }
        }
        {
            self.auto_particle_cmd_buf.clear();
            {
                let s = state.borrow();
                for ps in s.particle_systems.values() {
                    self.auto_particle_cmd_buf
                        .extend(ps.generate_render_commands());
                }
            }
            state
                .borrow_mut()
                .render_commands
                .extend(self.auto_particle_cmd_buf.iter().cloned());
        }
        {
            let phase_start = Instant::now();
            if let Err(e) =
                call_lua_callback_checked_with_timeout(lua, "draw_ui", (), callback_timeout_ms)
            {
                self.run_state = RunState::Error(try_errorhandler_or_screen(lua, &e));
                return;
            }
            frame_profile.draw_ui_ms = phase_start.elapsed().as_secs_f64() as f32 * 1000.0;
        }
        {
            self.auto_ui_cmd_buf.clear();
            if let Some(rc) = state
                .borrow()
                .auto_ui_ctx
                .as_ref()
                .and_then(|w| w.upgrade())
            {
                self.auto_ui_cmd_buf
                    .extend(rc.borrow_mut().generate_render_commands());
            }
            state
                .borrow_mut()
                .render_commands
                .extend(self.auto_ui_cmd_buf.iter().cloned());
        }
        let (fps, draw_calls, w) = {
            let st = state.borrow();
            (st.fps, st.render_stats.draw_calls, st.window_width)
        };
        let overlay_font = state.borrow().active_font.or(state.borrow().default_font);
        let overlay_cmds =
            self.debug_overlay
                .build_render_commands(w, fps, draw_calls, overlay_font);
        if !overlay_cmds.is_empty() {
            state.borrow_mut().render_commands.extend(overlay_cmds);
        }
        if let Some(font_key) = overlay_font {
            let shader_err = {
                let st = state.borrow();
                if st.shader_error_display_enabled {
                    st.last_shader_compile_error.clone()
                } else {
                    None
                }
            };
            if let Some(err) = shader_err {
                state
                    .borrow_mut()
                    .render_commands
                    .push(RenderCommand::Print {
                        font_key,
                        text: format!("Shader error: {}", err),
                        x: 12.0,
                        y: 28.0,
                        scale: 0.9,
                    });
            }
        }
        frame_profile.callback_total_ms = frame_profile.process_physics_ms
            + frame_profile.fixed_update_ms
            + frame_profile.process_ms
            + frame_profile.process_late_ms
            + frame_profile.draw_ms
            + frame_profile.draw_ui_ms;
        state.borrow_mut().frame_profile = frame_profile;
    }
    /// Update state in render.
    fn render(&mut self) {
        let (Some(renderer), Some(surface), Some(state)) =
            (&mut self.renderer, &self.surface, &self.state)
        else {
            return;
        };
        let (
            commands,
            default_filter,
            bg,
            cam_matrix,
            frame_time,
            frame_count,
            vp_scale_x,
            vp_scale_y,
            vp_offset_x,
            vp_offset_y,
            vp_mode,
            game_w,
            game_h,
            screenshot_request,
            screen_capture_requested,
            textures,
            shaders,
            canvases,
            meshes,
            sprite_batches,
            mut fonts,
        ) = {
            let mut st = state.borrow_mut();
            (
                std::mem::take(&mut st.render_commands),
                st.default_filter.clone(),
                st.background_color,
                st.camera.view_matrix(),
                st.total_time as f32,
                st.frame_counter,
                st.window_state.viewport_scale_x,
                st.window_state.viewport_scale_y,
                st.window_state.viewport_offset_x,
                st.window_state.viewport_offset_y,
                st.window_state.scale_mode_str.clone(),
                st.window_state.game_width,
                st.window_state.game_height,
                st.pending_screenshot.take(),
                std::mem::replace(&mut st.pending_screen_capture, false),
                std::mem::take(&mut st.textures),
                std::mem::take(&mut st.shaders),
                std::mem::take(&mut st.canvases),
                std::mem::take(&mut st.meshes),
                std::mem::take(&mut st.sprite_batches),
                std::mem::take(&mut st.fonts),
            )
        };
        let use_viewport = vp_mode != "none"
            && (vp_scale_x != 1.0 || vp_scale_y != 1.0 || vp_offset_x != 0.0 || vp_offset_y != 0.0);
        if use_viewport {
            self.render_cmd_buf.clear();
            if vp_mode == "letterbox" || vp_mode == "pixel" {
                self.render_cmd_buf.push(RenderCommand::SetScissor(Some((
                    vp_offset_x,
                    vp_offset_y,
                    game_w * vp_scale_x,
                    game_h * vp_scale_y,
                ))));
            }
            self.render_cmd_buf.push(RenderCommand::PushTransform);
            self.render_cmd_buf.push(RenderCommand::Translate {
                x: vp_offset_x,
                y: vp_offset_y,
            });
            self.render_cmd_buf.push(RenderCommand::Scale {
                sx: vp_scale_x,
                sy: vp_scale_y,
            });
            self.render_cmd_buf.extend(commands.iter().cloned());
            self.render_cmd_buf.push(RenderCommand::PopTransform);
            if vp_mode == "letterbox" || vp_mode == "pixel" {
                self.render_cmd_buf.push(RenderCommand::SetScissor(None));
            }
        }
        let final_commands: &Vec<RenderCommand> = if use_viewport {
            &self.render_cmd_buf
        } else {
            &commands
        };
        let screenshot_supported = self.surface_usage.contains(wgpu::TextureUsages::COPY_SRC);
        let capture_screenshot = screenshot_request.is_some() && screenshot_supported;
        let capture_screen_image = screen_capture_requested && screenshot_supported;
        let auto_screenshot_ready = match self.auto_screenshot_time {
            Some(secs) => {
                self.auto_screenshot_start
                    .map(|s| s.elapsed().as_secs_f32() >= secs)
                    .unwrap_or(false)
                    && self.auto_screenshot_frame_count >= 3
            }
            None => self.auto_screenshot_frame_count >= self.auto_screenshot_frames,
        };
        let should_auto_capture = screenshot_supported
            && !self.auto_screenshot_done
            && self.auto_screenshot_path.is_some()
            && auto_screenshot_ready;
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
                frame_count,
                capture_screenshot || should_auto_capture || capture_screen_image,
            )
        };
        let screenshot_pixels = match screenshot_pixels {
            Ok(screenshot) => screenshot,
            Err(e) => {
                if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                    log_msg!(warn, L024_SURFACE_LOST);
                    {
                        let mut st = state.borrow_mut();
                        st.fonts = fonts;
                        st.sprite_batches = sprite_batches;
                        st.textures = textures;
                        st.shaders = shaders;
                        st.canvases = canvases;
                        st.meshes = meshes;
                        st.pending_screenshot = screenshot_request;
                        st.pending_screen_capture = screen_capture_requested;
                    }
                    self.reconfigure_surface();
                    return;
                } else {
                    log_msg!(error, L010_RENDER_ERROR, "{:?}", e);
                }
                None
            }
        };
        {
            let mut st = state.borrow_mut();
            st.fonts = fonts;
            st.sprite_batches = sprite_batches;
            st.textures = textures;
            st.shaders = shaders;
            st.canvases = canvases;
            st.meshes = meshes;
            if capture_screen_image {
                st.captured_screen_image =
                    screenshot_pixels
                        .as_ref()
                        .and_then(|(width, height, pixels)| {
                            crate::image::ImageData::from_bytes(*width, *height, pixels.clone())
                                .ok()
                        });
            }
        }
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
                                    crate::runtime::log_messages::L001_ENGINE_START,
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
        if let Some(budget_ms) = self.config.performance.frame_budget_warn_ms {
            let elapsed_ms = self.last_frame.elapsed().as_secs_f64() * 1000.0;
            if elapsed_ms > budget_ms as f64 {
                log::warn!(
                    "frame budget exceeded: {:.2}ms > {}ms threshold",
                    elapsed_ms,
                    budget_ms
                );
            }
        }
    }
    /// Update state in render_splash.
    fn render_splash(&mut self) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        let total_time = self
            .state
            .as_ref()
            .map_or(0.0, |s| s.borrow().clock.total());
        if self.engine_fonts.is_none() {
            let mut fonts: SlotMap<FontKey, crate::render::Font> = SlotMap::with_key();
            let all = crate::render::Font::load_all_sizes();
            let title_idx = crate::render::Font::nearest_size(36);
            let small_idx = crate::render::Font::nearest_size(18);
            let mut title_key = None;
            let mut small_key = None;
            for (i, (font, _cw, _ch)) in all.into_iter().enumerate() {
                let key = fonts.insert(font);
                if i == title_idx {
                    title_key = Some(key);
                }
                if i == small_idx {
                    small_key = Some(key);
                }
            }
            let tk = title_key.expect("embedded bitmap fonts");
            let sk = small_key.expect("embedded bitmap fonts");
            self.engine_fonts = Some((fonts, tk, sk));
        }
        let (splash_fonts, _title_key, small_key) = self
            .engine_fonts
            .as_mut()
            .expect("engine_fonts initialized above");
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
        let no_batches: SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch> = SlotMap::with_key();
        let no_canvases: SlotMap<CanvasKey, crate::render::Canvas> = SlotMap::with_key();
        let empty_textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
        let no_meshes: SlotMap<MeshKey, crate::render::Mesh> = SlotMap::with_key();
        let no_shaders: SlotMap<ShaderKey, crate::render::Shader> = SlotMap::with_key();
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
            0u64,
            false,
        ) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                self.reconfigure_surface();
            }
        }
    }
    /// Update state in render_error.
    fn render_error(&mut self, error_screen: &ErrorScreen) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        if self.engine_fonts.is_none() {
            let mut fonts: SlotMap<FontKey, crate::render::Font> = SlotMap::with_key();
            let all = crate::render::Font::load_all_sizes();
            let title_idx = crate::render::Font::nearest_size(36);
            let small_idx = crate::render::Font::nearest_size(18);
            let mut title_key = None;
            let mut small_key = None;
            for (i, (font, _cw, _ch)) in all.into_iter().enumerate() {
                let key = fonts.insert(font);
                if i == title_idx {
                    title_key = Some(key);
                }
                if i == small_idx {
                    small_key = Some(key);
                }
            }
            let tk = title_key.expect("embedded bitmap fonts");
            let sk = small_key.expect("embedded bitmap fonts");
            self.engine_fonts = Some((fonts, tk, sk));
        }
        let (error_fonts, heading_key, body_key) = self
            .engine_fonts
            .as_mut()
            .expect("engine_fonts initialized above");
        let cmds = error_screen.build_render_commands(
            renderer.width,
            renderer.height,
            Some(*heading_key),
            Some(*body_key),
        );
        let bg = [0.11, 0.22, 0.53, 1.0];
        let no_batches: SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch> = SlotMap::with_key();
        let no_canvases: SlotMap<CanvasKey, crate::render::Canvas> = SlotMap::with_key();
        let no_textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
        let no_meshes: SlotMap<MeshKey, crate::render::Mesh> = SlotMap::with_key();
        let no_shaders: SlotMap<ShaderKey, crate::render::Shader> = SlotMap::with_key();
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
            0u64,
            false,
        ) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                self.reconfigure_surface();
            }
        }
    }
    /// Extract `.lurek` archive into a temp directory and reject unsafe paths.
    fn extract_lurek_archive(
        archive_path: &std::path::Path,
    ) -> Result<(std::path::PathBuf, tempfile::TempDir), String> {
        use std::io;
        let file = std::fs::File::open(archive_path)
            .map_err(|e| format!("Cannot open archive '{}': {}", archive_path.display(), e))?;
        let mut archive = zip::ZipArchive::new(file)
            .map_err(|e| format!("Invalid ZIP archive '{}': {}", archive_path.display(), e))?;
        let temp_dir =
            tempfile::tempdir().map_err(|e| format!("Failed to create temp dir: {}", e))?;
        for i in 0..archive.len() {
            let mut entry = archive
                .by_index(i)
                .map_err(|e| format!("Archive entry {}: {}", i, e))?;
            let entry_name = entry.name().to_owned();
            let relative = std::path::Path::new(&entry_name);
            for component in relative.components() {
                match component {
                    std::path::Component::Normal(_) | std::path::Component::CurDir => {}
                    _ => {
                        return Err(format!(
                            "Unsafe path in archive: '{}' - extraction rejected",
                            entry_name
                        ));
                    }
                }
            }
            let dest = temp_dir.path().join(relative);
            if entry.is_dir() {
                std::fs::create_dir_all(&dest)
                    .map_err(|e| format!("Cannot create dir '{}': {}", dest.display(), e))?;
            } else {
                if let Some(parent) = dest.parent() {
                    std::fs::create_dir_all(parent)
                        .map_err(|e| format!("Cannot create dir '{}': {}", parent.display(), e))?;
                }
                let mut out = std::fs::File::create(&dest)
                    .map_err(|e| format!("Cannot create file '{}': {}", dest.display(), e))?;
                io::copy(&mut entry, &mut out)
                    .map_err(|e| format!("Cannot write '{}': {}", dest.display(), e))?;
            }
        }
        let dir = temp_dir.path().to_path_buf();
        Ok((dir, temp_dir))
    }
    /// Update state in restart_game.
    fn restart_game(&mut self) {
        self.refresh_content_watchers();
        self.lua = None;
        self.state = None;
        self.has_game = false;
        self.prev_mouse = [false; 5];
        self.run_state = RunState::Running;
        self.init_lua();
    }
    /// Update state in poll_content_hot_reload.
    fn poll_content_hot_reload(&mut self) {
        if !self.has_game {
            return;
        }
        let script_changed = !self.content_script_watcher.poll().is_empty();
        let asset_changed = !self.content_asset_watcher.poll().is_empty();
        if !(script_changed || asset_changed) {
            return;
        }
        log::info!(
            "content hot-reload triggered (scripts_changed={}, assets_changed={})",
            script_changed,
            asset_changed
        );
        self.restart_game();
    }
    /// Update state in poll_config_hot_reload.
    fn poll_config_hot_reload(&mut self) {
        if self.conf_watcher.poll().is_empty() {
            return;
        }
        let (new_config, load_err) = Config::load(&self.game_dir);
        if let Some(err) = load_err {
            log::warn!("conf.toml hot-reload failed: {}", err);
            return;
        }
        self.config = new_config;
        self.window_vsync_mode = if self.config.window.vsync { 1 } else { 0 };
        if let Some(level) = self.config.log_level.as_deref() {
            crate::runtime::log_messages::set_log_level(level);
        }
        if let Some(window) = &self.window {
            window.set_title(&self.current_window_title());
        }
        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            st.physics_run.fixed_dt = 1.0 / self.config.performance.physics_tick_rate.max(1) as f64;
            st.physics_run.fixed_update_dt = match self.config.performance.fixed_update_tick_rate {
                Some(rate) if rate > 0 => 1.0 / rate as f64,
                _ => 0.0,
            };
            st.frame_budget_warn_ms = self.config.performance.frame_budget_warn_ms;
            st.lua_callback_timeout_ms = self.callback_timeout_ms();
            st.window_state.vsync_mode = self.window_vsync_mode;
            st.window_state.pending_vsync = Some(self.window_vsync_mode);
            st.window_state.game_width =
                self.config
                    .window
                    .game_width
                    .unwrap_or(self.config.window.width) as f32;
            st.window_state.game_height =
                self.config
                    .window
                    .game_height
                    .unwrap_or(self.config.window.height) as f32;
            st.window_state.scale_mode_str = self.config.window.scale_mode.clone();
            let (ww, wh) = (st.window_width, st.window_height);
            recompute_viewport(&mut st.window_state, ww, wh);
            st.config_reload_revision = st.config_reload_revision.saturating_add(1);
        }
        log::info!("conf.toml hot-reloaded successfully");
    }
    /// Update state in reconfigure_surface.
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
    /// Update state in handle_resize.
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
        if self.has_game {
            if let Some(lua) = &self.lua {
                call_lua_callback_with_timeout(
                    lua,
                    "resize",
                    (width, height),
                    self.callback_timeout_ms(),
                );
            }
        }
    }
    /// Update state in poll_gamepads.
    fn poll_gamepads(&mut self) {
        let callback_timeout_ms = self.callback_timeout_ms();
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
                        gamepad.set_connected(true);
                        gamepad.update_button(btn_idx, true);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback_with_timeout(
                                lua,
                                "gamepadpressed",
                                (id_u32, button_name),
                                callback_timeout_ms,
                            );
                        }
                    }
                }
                GilrsEventType::ButtonReleased(btn, _) => {
                    let btn_idx = gilrs_button_to_u32(btn);
                    let button_name = gilrs_button_to_string(btn).to_string();
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.set_connected(true);
                        gamepad.update_button(btn_idx, false);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback_with_timeout(
                                lua,
                                "gamepadreleased",
                                (id_u32, button_name),
                                callback_timeout_ms,
                            );
                        }
                    }
                }
                GilrsEventType::AxisChanged(axis, value, _) => {
                    let axis_idx = gilrs_axis_to_u32(axis);
                    let axis_name = gilrs_axis_to_string(axis).to_string();
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.set_connected(true);
                        gamepad.update_axis(axis_idx, value);
                    }
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback_with_timeout(
                                lua,
                                "gamepadaxis",
                                (id_u32, axis_name, value),
                                callback_timeout_ms,
                            );
                        }
                    }
                }
                GilrsEventType::Connected => {
                    let gamepad = gilrs.gamepad(id);
                    let name = gamepad.name().to_string();
                    let guid = format_gilrs_uuid(gamepad.uuid());
                    let ff_supported = gamepad.is_ff_supported();
                    {
                        let mut st = state.borrow_mut();
                        let entry = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        entry.set_connected(true);
                        entry.set_vibration_supported(ff_supported);
                        entry.name = name;
                        entry.set_guid(guid);
                    }
                    log_msg!(info, L036_GAMEPAD_CONNECTED, "id={}", id_usize);
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback_with_timeout(
                                lua,
                                "joystickadded",
                                (id_u32,),
                                callback_timeout_ms,
                            );
                            call_lua_callback_with_timeout(
                                lua,
                                "gamepadconnected",
                                (id_u32,),
                                callback_timeout_ms,
                            );
                        }
                    }
                }
                GilrsEventType::Disconnected => {
                    if let Some(effect) = self.gamepad_effects.remove(&id_usize) {
                        let _ = effect.stop();
                    }
                    {
                        let mut st = state.borrow_mut();
                        let gamepad = ensure_gamepad_slot(&mut st.gamepads, id_usize);
                        gamepad.set_connected(false);
                    }
                    log_msg!(info, L037_GAMEPAD_DISCONNECTED, "id={}", id_usize);
                    if has_game {
                        if let Some(lua) = lua {
                            call_lua_callback_with_timeout(
                                lua,
                                "joystickremoved",
                                (id_u32,),
                                callback_timeout_ms,
                            );
                            call_lua_callback_with_timeout(
                                lua,
                                "gamepaddisconnected",
                                (id_u32,),
                                callback_timeout_ms,
                            );
                        }
                    }
                }
                _ => {}
            }
        }
        self.process_pending_gamepad_vibration();
    }
    /// Update state in process_pending_gamepad_vibration.
    fn process_pending_gamepad_vibration(&mut self) {
        let Some(gilrs) = &mut self.gilrs else { return };
        let Some(state) = &self.state else { return };
        let requests = {
            let mut st = state.borrow_mut();
            std::mem::take(&mut st.gamepad_vibration_requests)
        };
        for req in requests {
            if let Some(effect) = Self::build_gamepad_vibration_effect(gilrs, req) {
                if effect.play().is_ok() {
                    self.gamepad_effects.insert(req.id, effect);
                }
            }
        }
    }
    /// Build force-feedback effect from queued vibration request when device supports it.
    fn build_gamepad_vibration_effect(
        gilrs: &mut Gilrs,
        request: crate::input::GamepadVibrationRequest,
    ) -> Option<Effect> {
        let mut target_id: Option<GilrsGamepadId> = None;
        let mut ff_supported = false;
        for (id, gamepad) in gilrs.gamepads() {
            if usize::from(id) == request.id {
                target_id = Some(id);
                ff_supported = gamepad.is_ff_supported();
                break;
            }
        }
        let target_id = target_id?;
        if !ff_supported {
            return None;
        }
        let low_mag = (request.low_freq.clamp(0.0, 1.0) * u16::MAX as f32) as u16;
        let high_mag = (request.high_freq.clamp(0.0, 1.0) * u16::MAX as f32) as u16;
        let play_for = Ticks::from_ms(request.duration_ms.max(1));
        let scheduling = Replay {
            after: Ticks::from_ms(0),
            play_for,
            with_delay: Ticks::from_ms(0),
        };
        let mut builder = EffectBuilder::new();
        builder
            .gamepads(&[target_id])
            .repeat(Repeat::For(play_for))
            .add_effect(BaseEffect {
                kind: BaseEffectType::Strong {
                    magnitude: high_mag,
                },
                scheduling,
                envelope: Envelope::default(),
            })
            .add_effect(BaseEffect {
                kind: BaseEffectType::Weak { magnitude: low_mag },
                scheduling,
                envelope: Envelope::default(),
            });
        builder.finish(gilrs).ok()
    }
}
/// Return gilrs_button_to_u32 result.
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
/// Return gilrs_axis_to_u32 result.
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
/// Grow gamepad state vector and return mutable slot for `id_usize`.
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
/// Return format_gilrs_uuid result.
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
/// Return system_cursor_to_winit_cursor result.
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
/// Return load_embedded_icon result.
fn load_embedded_icon() -> Option<winit::window::Icon> {
    let image = match ::image::load_from_memory(std::include_bytes!(concat!(
        env!("CARGO_MANIFEST_DIR"),
        "/assets/icon.png"
    ))) {
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
/// Return load_window_icon result.
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
/// Register watchers for script and asset files under `game_dir`.
fn register_content_watchers(
    game_dir: &Path,
    script_watcher: &mut FileWatcher,
    asset_watcher: &mut FileWatcher,
) {
    /// Walk directory tree and register paths by extension.
    fn walk_dir(root: &Path, script_watcher: &mut FileWatcher, asset_watcher: &mut FileWatcher) {
        let entries = match std::fs::read_dir(root) {
            Ok(entries) => entries,
            Err(_) => return,
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if let Some(name) = path.file_name().and_then(|n| n.to_str()) {
                    if matches!(name, "save" | "logs" | "target" | ".git") {
                        continue;
                    }
                }
                walk_dir(&path, script_watcher, asset_watcher);
                continue;
            }
            let ext = path
                .extension()
                .and_then(|e| e.to_str())
                .map(|e| e.to_ascii_lowercase());
            match ext.as_deref() {
                Some("lua") => script_watcher.watch(&path),
                Some("png") | Some("jpg") | Some("jpeg") | Some("webp") | Some("bmp")
                | Some("gif") | Some("ogg") | Some("wav") | Some("mp3") | Some("flac")
                | Some("ttf") | Some("otf") | Some("wgsl") | Some("json") | Some("toml") => {
                    asset_watcher.watch(&path)
                }
                _ => {}
            }
        }
    }
    walk_dir(game_dir, script_watcher, asset_watcher);
}
/// Provides the ApplicationHandler behavior contract for LurekApp.
impl ApplicationHandler for LurekApp {
    /// Update state in resumed.
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() {
            return;
        }
        let initial_title = self.current_window_title();
        let mut window_attrs = Window::default_attributes()
            .with_visible(false)
            .with_title(&initial_title)
            .with_inner_size(winit::dpi::PhysicalSize::new(
                self.config.window.width,
                self.config.window.height,
            ))
            .with_resizable(self.config.window.resizable)
            .with_decorations(!self.config.window.borderless);
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
        } else if let Some((wx, wy)) = self.window_pos {
            window.set_outer_position(winit::dpi::PhysicalPosition::new(wx, wy));
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
            if let Some(icon) = load_embedded_icon() {
                window.set_window_icon(Some(icon));
            }
        }
        self.init_gpu(window);
        match Gilrs::new() {
            Ok(g) => self.gilrs = Some(g),
            Err(e) => log_msg!(warn, L038_GILRS_UNAVAILABLE, "{}", e),
        }
        self.last_frame = Instant::now();
        if let Some(win) = &self.window {
            win.set_visible(true);
            win.request_redraw();
        }
    }
    /// Update state in window_event.
    fn window_event(&mut self, event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        match event {
            WindowEvent::CloseRequested => {
                log_msg!(info, L039_WINDOW_CLOSE);
                if let Some(lua) = &self.lua {
                    call_lua_callback_with_timeout(lua, "exit", (), self.callback_timeout_ms());
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
            }
            WindowEvent::Focused(focused) => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.focused = focused;
                }
                if self.has_game {
                    if let Some(lua) = &self.lua {
                        call_lua_callback_with_timeout(
                            lua,
                            "focus",
                            (focused,),
                            self.callback_timeout_ms(),
                        );
                    }
                }
            }
            WindowEvent::Occluded(occluded) => {
                if let Some(state) = &self.state {
                    state.borrow_mut().window_state.visible = !occluded;
                }
                if self.has_game {
                    if let Some(lua) = &self.lua {
                        call_lua_callback_with_timeout(
                            lua,
                            "visible",
                            (!occluded,),
                            self.callback_timeout_ms(),
                        );
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
                let scancode_str = if let PhysicalKey::Code(code) = event.physical_key {
                    winit_scancode_to_string(code).map(|s| s.to_string())
                } else {
                    None
                };
                if event.repeat {
                    let repeat_enabled = self
                        .state
                        .as_ref()
                        .map(|s| s.borrow().keyboard.has_key_repeat())
                        .unwrap_or(false);
                    if !repeat_enabled {
                        return;
                    }
                }
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
                        return;
                    }
                    match event.state {
                        ElementState::Pressed => {
                            if key_str == "escape" {
                                event_loop.exit();
                                return;
                            }
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
                                    call_lua_callback_with_timeout(
                                        lua,
                                        "keypressed",
                                        (key_str.clone(), sc.clone(), event.repeat),
                                        self.callback_timeout_ms(),
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
                                    call_lua_callback_with_timeout(
                                        lua,
                                        "keyreleased",
                                        (key_str.clone(), sc),
                                        self.callback_timeout_ms(),
                                    );
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
                                call_lua_callback_with_timeout(
                                    lua,
                                    "textinput",
                                    text,
                                    self.callback_timeout_ms(),
                                );
                            }
                        }
                    }
                }
            }
            WindowEvent::CursorMoved { position, .. } => {
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
                        call_lua_callback_with_timeout(
                            lua,
                            "wheelmoved",
                            (dx, dy),
                            self.callback_timeout_ms(),
                        );
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
                                call_lua_callback_with_timeout(
                                    lua,
                                    "mousepressed",
                                    (mx, my, (i + 1) as u32),
                                    self.callback_timeout_ms(),
                                );
                            } else if !pressed && self.prev_mouse[i] {
                                call_lua_callback_with_timeout(
                                    lua,
                                    "mousereleased",
                                    (mx, my, (i + 1) as u32),
                                    self.callback_timeout_ms(),
                                );
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
                if !self.lua_initialized {
                    if let Some(win) = &self.window {
                        win.set_visible(true);
                    }
                    self.init_lua();
                    self.lua_initialized = true;
                    if self.auto_screenshot_path.is_some() {
                        self.auto_screenshot_start = Some(Instant::now());
                    }
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
                if matches!(self.run_state, RunState::Restarting) {
                    self.restart_game();
                    return;
                }
                if let Some(state) = &self.state {
                    if state.borrow().quit_requested {
                        event_loop.exit();
                        return;
                    }
                }
                let tick_start = Instant::now();
                self.poll_gamepads();
                self.tick_frame();
                let tick_ms = tick_start.elapsed().as_secs_f64() * 1000.0;
                let mut update_ms = 0.0;
                let mut render_ms = 0.0;
                let run_state = std::mem::replace(&mut self.run_state, RunState::Running);
                match run_state {
                    RunState::Error(ref screen) => {
                        let render_start = Instant::now();
                        self.render_error(screen);
                        render_ms = render_start.elapsed().as_secs_f64() * 1000.0;
                        self.run_state = run_state;
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
                            let update_start = Instant::now();
                            self.game_update();
                            update_ms = update_start.elapsed().as_secs_f64() * 1000.0;
                            let render_start = Instant::now();
                            self.render();
                            render_ms = render_start.elapsed().as_secs_f64() * 1000.0;
                        } else {
                            let render_start = Instant::now();
                            self.render_splash();
                            render_ms = render_start.elapsed().as_secs_f64() * 1000.0;
                        }
                    }
                    RunState::Restarting => {}
                }
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    st.frame_profile.app_tick_ms = tick_ms as f32;
                    st.frame_profile.app_update_ms = update_ms as f32;
                    st.frame_profile.app_render_ms = render_ms as f32;
                    st.frame_profile.app_frame_total_ms = (tick_ms + update_ms + render_ms) as f32;
                }
                self.perf_record_frame(tick_ms, update_ms, render_ms);
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
                            call_lua_callback_with_timeout(
                                lua,
                                "touchpressed",
                                (id, x, y, dx, dy, pressure),
                                self.callback_timeout_ms(),
                            );
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
                            call_lua_callback_with_timeout(
                                lua,
                                "touchmoved",
                                (id, x, y, dx, dy, pressure),
                                self.callback_timeout_ms(),
                            );
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
                            call_lua_callback_with_timeout(
                                lua,
                                "touchreleased",
                                (id, x, y, dx, dy, pressure),
                                self.callback_timeout_ms(),
                            );
                        }
                    }
                }
            }
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
                log::debug!("[lurek drag-drop] DroppedFile: {}", path.display());
                log_msg!(info, L043_DROP_FILE, "{}", path.display());
                if self.drag_hover {
                    self.drag_hover = false;
                    if let Some(win) = &self.window {
                        win.request_redraw();
                    }
                }
                if !self.has_game {
                    let main_lua = path.join("main.lua");
                    let is_lurek_archive = path
                        .extension()
                        .map(|e| e.eq_ignore_ascii_case("lurek"))
                        .unwrap_or(false);
                    if is_lurek_archive {
                        log_msg!(info, L083_DROP_ARCHIVE, "{}", path.display());
                        match LurekApp::extract_lurek_archive(&path) {
                            Ok((dir, td)) => {
                                self.lurek_temp_dir = Some(td);
                                self.game_dir = dir;
                                self.explicit_game_dir = true;
                                self.restart_game();
                            }
                            Err(e) => {
                                log_msg!(warn, L084_DROP_ARCHIVE_FAIL, "{}: {}", path.display(), e);
                            }
                        }
                    } else if path.is_dir() && main_lua.exists() {
                        log_msg!(info, L044_DROP_GAME, "{}", path.display());
                        self.game_dir = path;
                        self.explicit_game_dir = true;
                        self.restart_game();
                    } else if path.is_dir() {
                        log_msg!(warn, L007_NO_MAIN_LUA, "no main.lua in: {}", path.display());
                    } else if let Some(parent) = path.parent() {
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
    /// Update state in about_to_wait.
    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        use std::time::Duration;
        if let Some(state) = &self.state {
            let requested = state.borrow().pending_config_reload;
            if requested {
                state.borrow_mut().pending_config_reload = false;
                self.conf_watcher.force_changed();
            }
        }
        self.poll_config_hot_reload();
        self.poll_content_hot_reload();
        if !self.auto_screenshot_done {
            if let Some(start) = self.auto_screenshot_start {
                let expected_capture_secs = match self.auto_screenshot_time {
                    Some(secs) => secs.max(0.0),
                    None => {
                        let fps = self.config.performance.target_fps.max(1) as f32;
                        self.auto_screenshot_frames as f32 / fps
                    }
                };
                let deadline_secs = (expected_capture_secs + 2.0).max(3.0);
                if start.elapsed() > Duration::from_secs_f32(deadline_secs) {
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
            event_loop.set_control_flow(ControlFlow::Poll);
        } else {
            let remaining = target - elapsed;
            #[cfg(target_os = "windows")]
            {
                if remaining > Duration::from_micros(1500) {
                    std::thread::sleep(remaining - Duration::from_micros(1000));
                }
                event_loop.set_control_flow(ControlFlow::Poll);
            }
            #[cfg(not(target_os = "windows"))]
            {
                let next = Instant::now() + remaining;
                event_loop.set_control_flow(ControlFlow::WaitUntil(next));
            }
        }
    }
}
/// Thin bootstrap wrapper that owns startup config and launches `LurekApp` event loop.
pub struct App {
    /// Runtime configuration loaded before app startup.
    config: Config,
    /// Optional configuration parse error passed to first-frame error handling.
    conf_error: Option<String>,
}
impl App {
    /// Create bootstrap app wrapper with config and optional pre-start config error.
    pub fn new(config: Config, conf_error: Option<String>) -> Self {
        App { config, conf_error }
    }
    /// Start the winit event loop and run the runtime for the selected game directory.
    pub fn run(
        self,
        game_dir: PathBuf,
        explicit_game_dir: bool,
        screenshot_path: Option<PathBuf>,
        screenshot_frames: u32,
        screenshot_time: Option<f32>,
        window_pos: Option<(i32, i32)>,
    ) {
        init_logging(
            &game_dir,
            self.config.log_file.as_deref(),
            self.config.log_append,
            self.config.log_level.as_deref(),
        );
        crate::runtime::messages::init();
        log_msg!(
            info,
            crate::runtime::log_messages::L001_ENGINE_START,
            "v{} (wgpu GPU backend)",
            env!("CARGO_PKG_VERSION"),
        );
        log_msg!(info, L080_GAME_DIR, "{}", game_dir.display());
        let event_loop = EventLoop::new().expect("Failed to create event loop");
        event_loop.set_control_flow(ControlFlow::Poll);
        let mut app = LurekApp::new(
            self.config,
            game_dir,
            self.conf_error,
            explicit_game_dir,
            screenshot_path,
            screenshot_frames,
            screenshot_time,
            window_pos,
        );
        event_loop.run_app(&mut app).expect("Event loop error");
        log_msg!(info, crate::runtime::log_messages::L002_ENGINE_STOP);
    }
}
/// Initialize logger with file sink and selected level filters.
fn init_logging(
    game_dir: &Path,
    log_file: Option<&str>,
    log_append: bool,
    log_level: Option<&str>,
) {
    use std::io::Write as _;
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
            .join("lurek.log")
    };
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
    let wgpu_level = if cfg!(debug_assertions) {
        log::LevelFilter::Warn
    } else {
        log::LevelFilter::Error
    };
    match file_result {
        Ok(file) => {
            let file = std::sync::Arc::new(std::sync::Mutex::new(file));
            let file_clone = std::sync::Arc::clone(&file);
            env_logger::Builder::new()
                .filter_level(level)
                .parse_default_env()
                .filter_module("wgpu", wgpu_level)
                .filter_module("wgpu_core", wgpu_level)
                .filter_module("wgpu_hal", wgpu_level)
                .filter_module("naga", wgpu_level)
                .format(move |buf, record| {
                    let ts = buf.timestamp_millis();
                    let line = format!("[{}] {:5} {}\n", ts, record.level(), record.args());
                    writeln!(buf, "[{}] {:5} {}", ts, record.level(), record.args())?;
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
/// Return try_errorhandler_or_screen result.
fn try_errorhandler_or_screen(lua: &Lua, err: &mlua::Error) -> ErrorScreen {
    let msg = format!("{}", err);
    log_msg!(error, L011_LUA_ERROR, "runtime: {}", msg);
    if let Ok(lurek) = lua.globals().get::<_, LuaTable>("lurek") {
        if let Ok(handler) = lurek.get::<_, LuaFunction>("errorhandler") {
            match handler.call::<_, ()>(msg.clone()) {
                Ok(()) => {
                    return ErrorScreen::from_lua_error(err);
                }
                Err(handler_err) => {
                    let combined = format!(
                        "Error in lurek.errorhandler\nOriginal error: {}\n\nHandler error: {}",
                        msg, handler_err
                    );
                    return ErrorScreen::from_error(&combined);
                }
            }
        }
    }
    ErrorScreen::from_lua_error(err)
}
