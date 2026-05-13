//! Shared runtime state container used by app loop and Lua-facing systems.
//! Owns frame data, resource registries, async IO handles, and per-frame metrics.

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
use slotmap::Key as SlotmapKey;
use slotmap::SlotMap;
use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::rc::Weak;
use std::sync::Arc;
use winit::window::Window;
#[derive(Debug, Clone, Copy, PartialEq)]
/// Runtime enum for FullscreenType.
pub enum FullscreenType {
    /// Selects Desktop variant.
    Desktop,
    /// Selects Exclusive variant.
    Exclusive,
}
#[derive(Debug)]
/// Runtime data model for WindowState.
pub struct WindowState {
    /// Stores focused state.
    pub focused: bool,
    /// Stores mouse_focused state.
    pub mouse_focused: bool,
    /// Stores minimized state.
    pub minimized: bool,
    /// Stores maximized state.
    pub maximized: bool,
    /// Stores visible state.
    pub visible: bool,
    /// Stores dpi_scale state.
    pub dpi_scale: f64,
    /// Stores position_x state.
    pub position_x: i32,
    /// Stores position_y state.
    pub position_y: i32,
    /// Stores pending_title state.
    pub pending_title: Option<String>,
    /// Stores pending_fullscreen state.
    pub pending_fullscreen: Option<bool>,
    /// Stores pending_fullscreen_type state.
    pub pending_fullscreen_type: FullscreenType,
    /// Stores pending_position state.
    pub pending_position: Option<(i32, i32)>,
    /// Stores pending_display_index state.
    pub pending_display_index: Option<usize>,
    /// Stores pending_size state.
    pub pending_size: Option<(u32, u32)>,
    /// Stores pending_minimize state.
    pub pending_minimize: bool,
    /// Stores pending_maximize state.
    pub pending_maximize: bool,
    /// Stores pending_restore state.
    pub pending_restore: bool,
    /// Stores pending_close state.
    pub pending_close: bool,
    /// Stores pending_attention state.
    pub pending_attention: bool,
    /// Stores pending_icon_path state.
    pub pending_icon_path: Option<String>,
    /// Stores vsync_mode state.
    pub vsync_mode: i32,
    /// Stores pending_vsync state.
    pub pending_vsync: Option<i32>,
    /// Stores fullscreen state.
    pub fullscreen: bool,
    /// Stores fullscreen_type state.
    pub fullscreen_type: FullscreenType,
    /// Stores game_width state.
    pub game_width: f32,
    /// Stores game_height state.
    pub game_height: f32,
    /// Stores scale_mode_str state.
    pub scale_mode_str: String,
    /// Stores viewport_scale_x state.
    pub viewport_scale_x: f32,
    /// Stores viewport_scale_y state.
    pub viewport_scale_y: f32,
    /// Stores viewport_offset_x state.
    pub viewport_offset_x: f32,
    /// Stores viewport_offset_y state.
    pub viewport_offset_y: f32,
    /// Stores pending_scale_mode state.
    pub pending_scale_mode: Option<String>,
}
/// Implements trait behavior for this type.
impl Default for WindowState {
    /// Execute default helper and return its result.
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
#[derive(Debug, Clone)]
/// Runtime data model for ErrorInfo.
pub struct ErrorInfo {
    /// Stores message state.
    pub message: String,
    /// Stores code state.
    pub code: String,
    /// Stores category state.
    pub category: String,
    /// Stores hint state.
    pub hint: Option<String>,
}
#[derive(Debug, Clone, PartialEq, Eq)]
/// Runtime data model for ScreenshotRequest.
pub struct ScreenshotRequest {
    /// Stores path state.
    pub path: String,
}
#[derive(Debug, Clone, Copy, Default)]
/// Runtime data model for FrameProfile.
pub struct FrameProfile {
    /// Stores app_tick_ms state.
    pub app_tick_ms: f32,
    /// Stores app_update_ms state.
    pub app_update_ms: f32,
    /// Stores app_render_ms state.
    pub app_render_ms: f32,
    /// Stores app_frame_total_ms state.
    pub app_frame_total_ms: f32,
    /// Stores process_physics_ms state.
    pub process_physics_ms: f32,
    /// Stores fixed_update_ms state.
    pub fixed_update_ms: f32,
    /// Stores process_ms state.
    pub process_ms: f32,
    /// Stores process_late_ms state.
    pub process_late_ms: f32,
    /// Stores draw_ms state.
    pub draw_ms: f32,
    /// Stores draw_ui_ms state.
    pub draw_ui_ms: f32,
    /// Stores callback_total_ms state.
    pub callback_total_ms: f32,
}
#[derive(Debug, Clone, Copy, Default)]
/// Runtime data model for ResourceMemoryStats.
pub struct ResourceMemoryStats {
    /// Stores texture_bytes state.
    pub texture_bytes: u64,
    /// Stores font_bytes state.
    pub font_bytes: u64,
    /// Stores canvas_bytes state.
    pub canvas_bytes: u64,
    /// Stores shader_bytes state.
    pub shader_bytes: u64,
    /// Stores total_bytes state.
    pub total_bytes: u64,
    /// Stores budget_bytes state.
    pub budget_bytes: u64,
    /// Stores texture_count state.
    pub texture_count: u64,
    /// Stores font_count state.
    pub font_count: u64,
    /// Stores canvas_count state.
    pub canvas_count: u64,
    /// Stores shader_count state.
    pub shader_count: u64,
}
#[derive(Debug, Clone)]
/// Runtime data model for PhysicsRunConfig.
pub struct PhysicsRunConfig {
    /// Stores fixed_dt state.
    pub fixed_dt: f64,
    /// Stores max_steps state.
    pub max_steps: u32,
    /// Stores debug_draw state.
    pub debug_draw: bool,
    /// Stores fixed_update_dt state.
    pub fixed_update_dt: f64,
}
/// Implements trait behavior for this type.
impl Default for PhysicsRunConfig {
    /// Execute default helper and return its result.
    fn default() -> Self {
        Self {
            fixed_dt: 1.0 / 60.0,
            max_steps: 8,
            debug_draw: false,
            fixed_update_dt: 0.0,
        }
    }
}
/// Runtime data model for SharedState.
pub struct SharedState {
    /// Stores render_commands state.
    pub render_commands: Vec<RenderCommand>,
    /// Stores current_color state.
    pub current_color: [f32; 4],
    /// Stores background_color state.
    pub background_color: [f32; 4],
    /// Stores textures state.
    pub textures: SlotMap<TextureKey, TextureData>,
    /// Stores released_texture_handles state.
    pub released_texture_handles: HashSet<u64>,
    /// Stores keys_down state.
    pub keys_down: HashSet<String>,
    /// Stores mouse state.
    pub mouse: MouseState,
    /// Stores delta_time state.
    pub delta_time: f64,
    /// Stores total_time state.
    pub total_time: f64,
    /// Stores fps state.
    pub fps: f64,
    /// Stores window_width state.
    pub window_width: u32,
    /// Stores window_height state.
    pub window_height: u32,
    /// Stores window_title state.
    pub window_title: String,
    /// Stores mixer state.
    pub mixer: Mixer,
    /// Stores game_dir state.
    pub game_dir: PathBuf,
    /// Stores quit_requested state.
    pub quit_requested: bool,
    /// Stores exit_code state.
    pub exit_code: i32,
    /// Stores restart_requested state.
    pub restart_requested: bool,
    /// Stores line_width state.
    pub line_width: f32,
    /// Stores blend_mode state.
    pub blend_mode: BlendMode,
    /// Stores fonts state.
    pub fonts: SlotMap<FontKey, crate::render::Font>,
    /// Stores active_font state.
    pub active_font: Option<FontKey>,
    /// Stores default_font state.
    pub default_font: Option<FontKey>,
    /// Stores default_fonts state.
    pub default_fonts: [Option<FontKey>; 6],
    /// Stores sprite_batches state.
    pub sprite_batches: SlotMap<SpriteBatchKey, crate::sprite::SpriteBatch>,
    /// Stores canvases state.
    pub canvases: SlotMap<CanvasKey, Canvas>,
    /// Stores particle_systems state.
    pub particle_systems: SlotMap<ParticleKey, ParticleSystem>,
    /// Stores gamepads state.
    pub gamepads: Vec<GamepadState>,
    /// Stores gamepad_background_events state.
    pub gamepad_background_events: bool,
    /// Stores gamepad_mappings state.
    pub gamepad_mappings: GamepadMappings,
    /// Stores gamepad_vibration_requests state.
    pub gamepad_vibration_requests: Vec<GamepadVibrationRequest>,
    /// Stores camera state.
    pub camera: Camera,
    /// Stores point_size state.
    pub point_size: f32,
    /// Stores transform_stack_depth state.
    pub transform_stack_depth: u32,
    /// Stores active_canvas state.
    pub active_canvas: Option<CanvasKey>,
    /// Stores render_stats state.
    pub render_stats: RenderStats,
    /// Stores scissor state.
    pub scissor: Option<(f32, f32, f32, f32)>,
    /// Stores color_mask state.
    pub color_mask: (bool, bool, bool, bool),
    /// Stores wireframe state.
    pub wireframe: bool,
    /// Stores default_filter state.
    pub default_filter: (String, String, u32),
    /// Stores shaders state.
    pub shaders: SlotMap<ShaderKey, Shader>,
    /// Stores active_shader state.
    pub active_shader: Option<ShaderKey>,
    /// Stores meshes state.
    pub meshes: SlotMap<MeshKey, Mesh>,
    /// Stores shapes state.
    pub shapes: SlotMap<ShapeKey, CompoundShape>,
    /// Stores keyboard state.
    pub keyboard: KeyboardState,
    /// Stores touch state.
    pub touch: TouchState,
    /// Stores window_state state.
    pub window_state: WindowState,
    /// Stores window state.
    pub window: Option<Arc<Window>>,
    /// Stores event_queue state.
    pub event_queue: EventQueue,
    /// Stores filesystem_identity state.
    pub filesystem_identity: String,
    /// Stores clock state.
    pub clock: Clock,
    /// Stores debug_overlay_enabled state.
    pub debug_overlay_enabled: bool,
    /// Stores last_error state.
    pub last_error: Option<ErrorInfo>,
    /// Stores shader_error_display_enabled state.
    pub shader_error_display_enabled: bool,
    /// Stores last_shader_compile_error state.
    pub last_shader_compile_error: Option<String>,
    /// Stores async_loader state.
    pub async_loader: Option<crate::filesystem::AsyncLoader>,
    /// Stores fs state.
    pub fs: GameFS,
    /// Stores midi_state state.
    pub midi_state: MidiState,
    /// Stores pending_screenshot state.
    pub pending_screenshot: Option<ScreenshotRequest>,
    /// Stores pending_screen_capture state.
    pub pending_screen_capture: bool,
    /// Stores captured_screen_image state.
    pub captured_screen_image: Option<crate::image::ImageData>,
    /// Stores stencil_mode state.
    pub stencil_mode: StencilMode,
    /// Stores depth_mode state.
    pub depth_mode: (DepthMode, bool),
    /// Stores light_world state.
    pub light_world: LightWorld,
    /// Stores physics_run state.
    pub physics_run: PhysicsRunConfig,
    /// Stores auto_parallax_layers state.
    pub auto_parallax_layers: Vec<Weak<RefCell<ParallaxLayer>>>,
    /// Stores auto_tilemaps state.
    pub auto_tilemaps: Vec<Weak<RefCell<TileMap>>>,
    /// Stores auto_ui_ctx state.
    pub auto_ui_ctx: Option<Weak<RefCell<GuiContext>>>,
    /// Stores raycaster_output state.
    pub raycaster_output: Option<RaycasterScene>,
    /// Stores resource_budget_bytes state.
    pub resource_budget_bytes: u64,
    /// Stores frame_profile state.
    pub frame_profile: FrameProfile,
    /// Stores frame_counter state.
    pub frame_counter: u64,
    /// Stores config_reload_revision state.
    pub config_reload_revision: u64,
    /// Stores texture_last_used state.
    pub texture_last_used: HashMap<TextureKey, u64>,
    /// Stores canvas_last_used state.
    pub canvas_last_used: HashMap<CanvasKey, u64>,
    /// Stores frame_budget_warn_ms state.
    pub frame_budget_warn_ms: Option<f32>,
    /// Stores lua_callback_timeout_ms state.
    pub lua_callback_timeout_ms: Option<f32>,
    /// Stores pending_config_reload state.
    pub pending_config_reload: bool,
    /// Stores province_registries state.
    pub province_registries: HashMap<String, ProvinceRegistry>,
    /// Stores active_province_registry state.
    pub active_province_registry: Option<String>,
}
impl SharedState {
    /// Execute new and return its result.
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
    /// Execute step_timer and return its result.
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
    /// Execute touch_texture and return its result.
    pub fn touch_texture(&mut self, key: TextureKey) {
        self.texture_last_used.insert(key, self.frame_counter);
    }
    /// Execute touch_canvas and return its result.
    pub fn touch_canvas(&mut self, key: CanvasKey) {
        self.canvas_last_used.insert(key, self.frame_counter);
    }
    /// Execute evict_lru_resources and return its result.
    pub fn evict_lru_resources(&mut self) {
        let stats = self.resource_memory_stats();
        if stats.total_bytes <= self.resource_budget_bytes {
            return;
        }
        let mut over = stats.total_bytes - self.resource_budget_bytes;
        let tex_count = self.textures.len();
        let mut candidates: Vec<(TextureKey, u64)> = Vec::with_capacity(tex_count);
        for k in self.textures.keys() {
            let last = self.texture_last_used.get(&k).copied().unwrap_or(0);
            candidates.push((k, last));
        }
        candidates.sort_unstable_by_key(|(_, last)| *last);
        for (key, _) in candidates {
            if over == 0 {
                break;
            }
            if let Some(tex) = self.textures.get(key) {
                let size = (tex.width as u64) * (tex.height as u64) * 4;
                self.released_texture_handles.insert(key.data().as_ffi());
                self.textures.remove(key);
                self.texture_last_used.remove(&key);
                over = over.saturating_sub(size);
            }
        }
    }
    /// Execute resource_memory_stats and return its result.
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
    /// Execute request_async_load and return its result.
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
    /// Execute request_async_write and return its result.
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
    /// Execute load_default_fonts and return its result.
    pub fn load_default_fonts(&mut self) {
        if self.default_font.is_some() {
            return;
        }
        let sizes = crate::render::Font::load_all_sizes();
        for (i, (font, _cw, _ch)) in sizes.into_iter().enumerate() {
            let key = self.fonts.insert(font);
            self.default_fonts[i] = Some(key);
            if i == 3 {
                self.default_font = Some(key);
                self.active_font = Some(key);
            }
        }
    }
    /// Execute poll_async_load and return its result.
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
    /// Execute poll_async_write and return its result.
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
/// Runtime data model for RendererStats.
pub struct RendererStats {
    /// Stores draw_calls state.
    pub draw_calls: usize,
    /// Stores textures state.
    pub textures: usize,
    /// Stores fonts state.
    pub fonts: usize,
    /// Stores canvases state.
    pub canvases: usize,
    /// Stores texture_memory state.
    pub texture_memory: usize,
}
impl SharedState {
    /// Execute compute_stats and return its result.
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
