//! Luna2D application lifecycle using winit 0.30 + wgpu GPU rendering.
//!
//! Replaces the minifb-based `App` with a `winit` event loop and `GpuRenderer`.
//! The game loop structure (callbacks, SharedState, Lua VM) is preserved;
//! only the rendering and windowing backends change.

use std::cell::RefCell;
use std::collections::HashSet;
use std::path::PathBuf;
use std::rc::Rc;
use std::sync::Arc;
use std::time::Instant;

use mlua::prelude::*;
use winit::application::ApplicationHandler;
use winit::event::{ElementState, MouseButton, WindowEvent};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::window::{Window, WindowId};

use crate::graphics::renderer::{DrawCommand, DrawMode};
use crate::graphics::GpuRenderer;
use crate::input::keyboard::winit_key_to_string;
use crate::lua_api::{SharedState, create_lua_vm};
use crate::timer::Clock;

use super::config::Config;

// ─── Luna2D Application handler ──────────────────────────────────────────────

/// Luna2D application state managed by the winit event loop.
struct LunaApp {
    config: Config,
    game_dir: PathBuf,

    // Initialised in `resumed()`.
    window: Option<Arc<Window>>,
    surface: Option<wgpu::Surface<'static>>,
    surface_format: wgpu::TextureFormat,
    renderer: Option<GpuRenderer>,

    // Lua runtime.
    lua: Option<Lua>,
    state: Option<Rc<RefCell<SharedState>>>,
    has_game: bool,

    // Timing.
    clock: Clock,
    last_frame: Instant,
    total_time: f64,

    // Input tracking for keypressed / keyreleased callbacks.
    prev_keys: HashSet<String>,
    prev_mouse: [bool; 3],
    mouse_x: f32,
    mouse_y: f32,

    // Exit flag.
    quit: bool,
}

impl LunaApp {
    fn new(config: Config, game_dir: PathBuf) -> Self {
        LunaApp {
            config,
            game_dir,
            window: None,
            surface: None,
            surface_format: wgpu::TextureFormat::Bgra8UnormSrgb,
            renderer: None,
            lua: None,
            state: None,
            has_game: false,
            clock: Clock::new(),
            last_frame: Instant::now(),
            total_time: 0.0,
            prev_keys: HashSet::new(),
            prev_mouse: [false; 3],
            mouse_x: 0.0,
            mouse_y: 0.0,
            quit: false,
        }
    }

    fn init_gpu(&mut self, window: Arc<Window>) {
        let width = self.config.window.width;
        let height = self.config.window.height;

        let instance = wgpu::Instance::new(wgpu::InstanceDescriptor {
            backends: wgpu::Backends::all(),
            ..Default::default()
        });

        // SAFETY: The surface lifetime is tied to the Arc<Window> which outlives the surface.
        let surface: wgpu::Surface<'static> = instance
            .create_surface(Arc::clone(&window))
            .expect("Failed to create wgpu surface");

        let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: Some(&surface),
            force_fallback_adapter: false,
        }))
        .expect("No compatible GPU adapter found. Try installing a display driver.");

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

        surface.configure(
            &device,
            &wgpu::SurfaceConfiguration {
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                format: surface_format,
                width,
                height,
                present_mode: wgpu::PresentMode::AutoVsync,
                alpha_mode: caps.alpha_modes[0],
                view_formats: vec![],
                desired_maximum_frame_latency: 2,
            },
        );

        let renderer = GpuRenderer::new(device, queue, surface_format, width, height);

        self.surface_format = surface_format;
        self.surface = Some(surface);
        self.renderer = Some(renderer);
        self.window = Some(window);
    }

    fn init_lua(&mut self) {
        let state = Rc::new(RefCell::new(SharedState::new(
            self.config.window.width,
            self.config.window.height,
            &self.config.window.title,
            self.game_dir.clone(),
        )));

        let lua = match create_lua_vm(state.clone()) {
            Ok(l) => l,
            Err(e) => {
                log::error!("Failed to initialise Lua VM: {}", e);
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
                    } else {
                        call_lua_callback(&lua, "load", ());
                        self.has_game = true;
                    }
                }
                Err(e) => log::error!("Failed to read main.lua: {}", e),
            }
        } else {
            log::info!("No game loaded — showing splash screen.");
        }

        self.lua = Some(lua);
        self.state = Some(state);
    }

    fn tick_frame(&mut self) {
        let dt = self.clock.tick();
        self.total_time += dt as f64;

        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            st.delta_time = dt as f64;
            st.total_time = self.total_time;
            st.fps = self.clock.fps();
        }
    }

    fn game_update(&mut self) {
        let (Some(lua), Some(state)) = (&self.lua, &self.state) else { return };
        call_lua_callback(lua, "update", self.clock.last_dt() as f64);

        state.borrow_mut().draw_commands.clear();
        call_lua_callback(lua, "draw", ());
    }

    fn render(&mut self) {
        let (Some(renderer), Some(surface), Some(state)) =
            (&mut self.renderer, &self.surface, &self.state)
        else {
            return;
        };

        let (commands, textures, bg) = {
            let st = state.borrow();
            (st.draw_commands.clone(), st.textures.clone(), st.background_color)
        };

        if let Err(e) = renderer.render_frame(surface, &commands, &textures, bg) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                log::warn!("Surface lost/outdated — reconfiguring…");
                self.reconfigure_surface();
            } else {
                log::error!("Render error: {:?}", e);
            }
        }
    }

    fn render_splash(&mut self) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        let cmds = make_splash_commands(renderer.width, renderer.height, self.total_time);
        let bg = [0.12, 0.08, 0.20, 1.0];
        if let Err(e) = renderer.render_frame(surface, &cmds, &[], bg) {
            if e == wgpu::SurfaceError::Lost || e == wgpu::SurfaceError::Outdated {
                self.reconfigure_surface();
            }
        }
    }

    fn reconfigure_surface(&mut self) {
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        let w = renderer.width;
        let h = renderer.height;
        surface.configure(
            &renderer.device,
            &wgpu::SurfaceConfiguration {
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                format: self.surface_format,
                width: w,
                height: h,
                present_mode: wgpu::PresentMode::AutoVsync,
                alpha_mode: wgpu::CompositeAlphaMode::Auto,
                view_formats: vec![],
                desired_maximum_frame_latency: 2,
            },
        );
    }

    fn handle_resize(&mut self, width: u32, height: u32) {
        if width == 0 || height == 0 { return; }
        let (Some(renderer), Some(surface)) = (&mut self.renderer, &self.surface) else {
            return;
        };
        renderer.resize(width, height);
        surface.configure(
            &renderer.device,
            &wgpu::SurfaceConfiguration {
                usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
                format: self.surface_format,
                width,
                height,
                present_mode: wgpu::PresentMode::AutoVsync,
                alpha_mode: wgpu::CompositeAlphaMode::Auto,
                view_formats: vec![],
                desired_maximum_frame_latency: 2,
            },
        );
        if let Some(state) = &self.state {
            let mut st = state.borrow_mut();
            st.window_width = width;
            st.window_height = height;
        }
    }
}

impl ApplicationHandler for LunaApp {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() { return; } // already initialised

        let window_attrs = Window::default_attributes()
            .with_title(&self.config.window.title)
            .with_inner_size(winit::dpi::PhysicalSize::new(
                self.config.window.width,
                self.config.window.height,
            ))
            .with_resizable(false);

        let window = Arc::new(
            event_loop
                .create_window(window_attrs)
                .expect("Failed to create window"),
        );

        self.init_gpu(window);
        self.init_lua();
        self.last_frame = Instant::now();
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        _id: WindowId,
        event: WindowEvent,
    ) {
        match event {
            WindowEvent::CloseRequested => {
                log::info!("Window close requested.");
                event_loop.exit();
            }

            WindowEvent::Resized(size) => {
                self.handle_resize(size.width, size.height);
            }

            WindowEvent::KeyboardInput { event, .. } => {
                if let Some(key_str) = winit_key_to_string(&event.logical_key) {
                    match event.state {
                        ElementState::Pressed => {
                            // Check quit on Escape.
                            if key_str == "escape" {
                                event_loop.exit();
                                return;
                            }
                            if let Some(state) = &self.state {
                                state.borrow_mut().keys_down.insert(key_str.clone());
                            }
                            if self.has_game {
                                if let Some(lua) = &self.lua {
                                    call_lua_callback(lua, "keypressed", key_str.clone());
                                }
                            }
                            self.prev_keys.insert(key_str);
                        }
                        ElementState::Released => {
                            if let Some(state) = &self.state {
                                state.borrow_mut().keys_down.remove(&key_str);
                            }
                            if self.has_game {
                                if !self.prev_keys.contains(&key_str) {
                                    // Only fire keyreleased if we saw the press.
                                    if let Some(lua) = &self.lua {
                                        call_lua_callback(lua, "keyreleased", key_str.clone());
                                    }
                                }
                            }
                            self.prev_keys.remove(&key_str);
                        }
                    }
                }
            }

            WindowEvent::CursorMoved { position, .. } => {
                self.mouse_x = position.x as f32;
                self.mouse_y = position.y as f32;
                if let Some(state) = &self.state {
                    let mut st = state.borrow_mut();
                    st.mouse_x = self.mouse_x;
                    st.mouse_y = self.mouse_y;
                }
            }

            WindowEvent::MouseInput { state: btn_state, button, .. } => {
                let idx = match button {
                    MouseButton::Left => Some(0),
                    MouseButton::Right => Some(1),
                    MouseButton::Middle => Some(2),
                    _ => None,
                };
                if let Some(i) = idx {
                    let pressed = btn_state == ElementState::Pressed;
                    if let Some(state) = &self.state {
                        state.borrow_mut().mouse_buttons[i] = pressed;
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
                    self.prev_mouse[i] = pressed;
                }
            }

            WindowEvent::RedrawRequested => {
                // Check quit flag from Lua (e.g., luna.event.quit()).
                if let Some(state) = &self.state {
                    if state.borrow().quit_requested {
                        event_loop.exit();
                        return;
                    }
                }

                self.tick_frame();

                if self.has_game {
                    self.game_update();
                    self.render();
                } else {
                    self.render_splash();
                }
            }

            _ => {}
        }
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        // Request a new frame at the target FPS.
        let target = 1.0 / self.config.performance.target_fps as f64;
        let elapsed = self.last_frame.elapsed().as_secs_f64();
        if elapsed >= target {
            self.last_frame = Instant::now();
            if let Some(win) = &self.window {
                win.request_redraw();
            }
        }
    }
}

// ─── App entry point (public API) ────────────────────────────────────────────

/// Entry point for the Luna2D engine. Owns the game loop, GPU renderer, and Lua VM lifecycle.
pub struct App {
    config: Config,
}

impl App {
    /// Creates a new `App` with the given `Config`.
    pub fn new(config: Config) -> Self {
        App { config }
    }

    /// Initialises the GPU, window, Lua VM, and runs the event loop until the game exits.
    pub fn run(self, game_dir: PathBuf) {
        env_logger::init();
        log::info!("Luna2D Engine starting (wgpu GPU backend)…");

        let event_loop = EventLoop::new().expect("Failed to create event loop");
        event_loop.set_control_flow(ControlFlow::Poll);

        let mut app = LunaApp::new(self.config, game_dir);
        event_loop.run_app(&mut app).expect("Event loop error");

        log::info!("Luna2D Engine shut down.");
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

fn make_splash_commands(width: u32, height: u32, time: f64) -> Vec<DrawCommand> {
    let cx = width as f32 / 2.0;
    let cy = height as f32 / 2.0;
    let pulse = 1.0 + (time * 2.0).sin() as f32 * 0.05;
    let moon_r = 60.0 * pulse;
    vec![
        DrawCommand::SetColor(0.95, 0.90, 0.55, 1.0),
        DrawCommand::Circle { mode: DrawMode::Fill, x: cx, y: cy - 40.0, r: moon_r },
        DrawCommand::SetColor(0.12, 0.08, 0.20, 1.0),
        DrawCommand::Circle { mode: DrawMode::Fill, x: cx + 25.0, y: cy - 55.0, r: moon_r * 0.85 },
        DrawCommand::SetColor(0.95, 0.90, 0.55, 1.0),
        DrawCommand::Print {
            text: "LUNA2D".to_string(),
            x: cx - 54.0, y: cy + 50.0, scale: 3.0,
        },
        DrawCommand::SetColor(0.6, 0.55, 0.7, 1.0),
        DrawCommand::Print {
            text: "2D Game Engine".to_string(),
            x: cx - 84.0, y: cy + 85.0, scale: 2.0,
        },
        DrawCommand::SetColor(0.4, 0.35, 0.5, 1.0),
        DrawCommand::Print {
            text: "v0.2.0".to_string(),
            x: cx - 36.0, y: cy + 115.0, scale: 2.0,
        },
    ]
}
