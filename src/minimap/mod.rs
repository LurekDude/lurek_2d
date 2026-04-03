//! Minimap data structures for overhead map displays (Tier 1).
//!
//! Provides a grid-based minimap with terrain coloring, fog of war,
//! tracked objects, pings, markers, and viewport rectangle overlay.
//!
//! This is a **pure CPU data-model module** — it has no GPU dependencies.
//! Extracted from `graphics` so that other modules can reference minimap
//! types without pulling in the full rendering pipeline.
//!
//! Key types: `ColorMode`, `FogLevel`, `MinimapObjectType`, `MinimapObject`, `MinimapPing`.
//! Primary entry point: `Minimap::new(width, height)`.

use std::collections::HashMap;

/// How cells are colored on the minimap. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Color` — Color variant.
/// - `Terrain` — Terrain variant.
/// - `Political` — Political variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ColorMode {
    /// Color cells by terrain type.
    Terrain,
    /// Color cells by owning faction/player.
    Political,
}

/// Fog-of-war visibility level for a cell. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Cell` — Cell variant.
/// - `Hidden` — Hidden variant.
/// - `Explored` — Explored variant.
/// - `Visible` — Visible variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum FogLevel {
    /// Cell is completely hidden.
    Hidden = 0,
    /// Cell was previously seen but is not currently visible.
    Explored = 1,
    /// Cell is currently visible.
    Visible = 2,
}

impl FogLevel {
    /// Convert from a u8 value to a FogLevel.
    ///
    /// # Parameters
    /// - `val` — `u8`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_u8(val: u8) -> Self {
        match val {
            0 => FogLevel::Hidden,
            1 => FogLevel::Explored,
            _ => FogLevel::Visible,
        }
    }
}

/// A registered object type with a display color and visibility toggle.
///
/// # Fields
/// - `name` — `String`.
/// - `color` — `[f32; 4]`.
/// - `visible` — `bool`.
#[derive(Debug, Clone)]
pub struct MinimapObjectType {
    /// Human-readable name of this object type.
    pub name: String,
    /// Display color (RGBA).
    pub color: [f32; 4],
    /// Whether objects of this type are shown on the minimap.
    pub visible: bool,
}

/// A tracked object on the minimap. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `type_index` — `usize`.
/// - `owner` — `u32`.
#[derive(Debug, Clone)]
pub struct MinimapObject {
    /// Grid X position (can be fractional).
    pub x: f32,
    /// Grid Y position (can be fractional).
    pub y: f32,
    /// Index into the object types array.
    pub type_index: usize,
    /// Owner/faction identifier (0 = neutral).
    pub owner: u32,
}

/// A temporary animated ping on the minimap.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `remaining` — `f32`.
/// - `duration` — `f32`.
/// - `color` — `[f32; 4]`.
#[derive(Debug, Clone)]
pub struct MinimapPing {
    /// Grid X position.
    pub x: f32,
    /// Grid Y position.
    pub y: f32,
    /// Time remaining before expiry (seconds).
    pub remaining: f32,
    /// Total duration of this ping (seconds).
    pub duration: f32,
    /// Display color (RGBA).
    pub color: [f32; 4],
}

/// A persistent labeled marker on the minimap.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `description` — `String`.
/// - `color` — `[f32; 4]`.
#[derive(Debug, Clone)]
pub struct MinimapMarker {
    /// Grid X position.
    pub x: f32,
    /// Grid Y position.
    pub y: f32,
    /// Optional description text.
    pub description: String,
    /// Display color (RGBA).
    pub color: [f32; 4],
}

/// A grid-based minimap with terrain, fog, objects, pings, and markers.
///
/// # Fields
/// - `grid_width` — `u32`.
/// - `grid_height` — `u32`.
/// - `display_width` — `u32`.
/// - `display_height` — `u32`.
/// - `terrain` — `Vec<u32>`.
/// - `terrain_colors` — `HashMap<u32`.
/// - `fog` — `Vec<u8>`.
/// - `fog_enabled` — `bool`.
/// - `fog_color` — `[f32; 4]`.
/// - `objects` — `HashMap<u32`.
/// - `object_types` — `Vec<MinimapObjectType>`.
/// - `owner_colors` — `HashMap<u32`.
/// - `color_mode` — `ColorMode`.
/// - `zoom` — `f32`.
/// - `center_x` — `f32`.
/// - `center_y` — `f32`.
/// - `viewport_rect` — `Option<(f32`.
/// - `viewport_visible` — `bool`.
/// - `viewport_color` — `[f32; 4]`.
/// - `pings` — `Vec<MinimapPing>`.
/// - `markers` — `HashMap<u32`.
/// - `next_marker_id` — `u32`.
/// - `anti_alias` — `bool`.
#[derive(Debug, Clone)]
pub struct Minimap {
    // ── Grid dimensions ──
    grid_width: u32,
    grid_height: u32,

    // ── Display dimensions ──
    display_width: u32,
    display_height: u32,

    // ── Terrain ──
    terrain: Vec<u32>,
    terrain_colors: HashMap<u32, [f32; 4]>,

    // ── Fog of war ──
    fog: Vec<u8>,
    fog_enabled: bool,
    fog_color: [f32; 4],

    // ── Objects ──
    objects: HashMap<u32, MinimapObject>,
    object_types: Vec<MinimapObjectType>,
    owner_colors: HashMap<u32, [f32; 4]>,

    // ── Display state ──
    color_mode: ColorMode,
    zoom: f32,
    center_x: f32,
    center_y: f32,

    // ── Viewport overlay ──
    viewport_rect: Option<(f32, f32, f32, f32)>,
    viewport_visible: bool,
    viewport_color: [f32; 4],

    // ── Pings and markers ──
    pings: Vec<MinimapPing>,
    markers: HashMap<u32, MinimapMarker>,
    next_marker_id: u32,

    // ── Rendering options ──
    anti_alias: bool,
}

impl Minimap {
    /// Create a new minimap with the given grid and display dimensions.
    ///
    /// # Parameters
    /// - `grid_width` — `u32`.
    /// - `grid_height` — `u32`.
    /// - `display_width` — `u32`.
    /// - `display_height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(grid_width: u32, grid_height: u32, display_width: u32, display_height: u32) -> Self {
        let cell_count = (grid_width * grid_height) as usize;
        Self {
            grid_width,
            grid_height,
            display_width,
            display_height,
            terrain: vec![0; cell_count],
            terrain_colors: HashMap::new(),
            fog: vec![0; cell_count],
            fog_enabled: false,
            fog_color: [0.0, 0.0, 0.0, 0.8],
            objects: HashMap::new(),
            object_types: Vec::new(),
            owner_colors: HashMap::new(),
            color_mode: ColorMode::Terrain,
            zoom: 1.0,
            center_x: grid_width as f32 / 2.0,
            center_y: grid_height as f32 / 2.0,
            viewport_rect: None,
            viewport_visible: true,
            viewport_color: [1.0, 1.0, 1.0, 0.8],
            pings: Vec::new(),
            markers: HashMap::new(),
            next_marker_id: 1,
            anti_alias: false,
        }
    }

    // ── Grid queries ──

    /// Returns the grid width in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_width(&self) -> u32 {
        self.grid_width
    }

    /// Returns the grid height in cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_height(&self) -> u32 {
        self.grid_height
    }

    /// Returns the total number of grid cells. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_size(&self) -> u32 {
        self.grid_width * self.grid_height
    }

    // ── Display dimensions ──

    /// Returns the display width in pixels. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn display_width(&self) -> u32 {
        self.display_width
    }

    /// Returns the display height in pixels. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn display_height(&self) -> u32 {
        self.display_height
    }

    /// Set the display size in pixels. Replaces the current display size value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    pub fn set_display_size(&mut self, width: u32, height: u32) {
        self.display_width = width;
        self.display_height = height;
    }

    // ── Terrain ──

    /// Set the terrain type at a grid position (0-based internally).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `errain_type` — `u32`.
    pub fn set_terrain(&mut self, x: u32, y: u32, terrain_type: u32) {
        if x < self.grid_width && y < self.grid_height {
            let idx = (y * self.grid_width + x) as usize;
            self.terrain[idx] = terrain_type;
        }
    }

    /// Get the terrain type at a grid position.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_terrain(&self, x: u32, y: u32) -> u32 {
        if x < self.grid_width && y < self.grid_height {
            self.terrain[(y * self.grid_width + x) as usize]
        } else {
            0
        }
    }

    /// Set the display color for a terrain type.
    ///
    /// # Parameters
    /// - `errain_type` — `u32`.
    /// - `color` — `[f32; 4]`.
    pub fn set_terrain_color(&mut self, terrain_type: u32, color: [f32; 4]) {
        self.terrain_colors.insert(terrain_type, color);
    }

    /// Get the display color for a terrain type.
    ///
    /// # Parameters
    /// - `errain_type` — `u32`.
    ///
    /// # Returns
    /// `[f32`.
    pub fn get_terrain_color(&self, terrain_type: u32) -> [f32; 4] {
        self.terrain_colors.get(&terrain_type).copied().unwrap_or([0.5, 0.5, 0.5, 1.0])
    }

    // ── Fog of war ──

    /// Enable or disable fog of war. Replaces the current fog enabled value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_fog_enabled(&mut self, enabled: bool) {
        self.fog_enabled = enabled;
    }

    /// Returns whether fog of war is enabled. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `bool`.
    pub fn fog_enabled(&self) -> bool {
        self.fog_enabled
    }

    /// Set the fog level at a grid position.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `level` — `FogLevel`.
    pub fn set_fog_level(&mut self, x: u32, y: u32, level: FogLevel) {
        if x < self.grid_width && y < self.grid_height {
            let idx = (y * self.grid_width + x) as usize;
            self.fog[idx] = level as u8;
        }
    }

    /// Get the fog level at a grid position.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `FogLevel`.
    pub fn get_fog_level(&self, x: u32, y: u32) -> FogLevel {
        if x < self.grid_width && y < self.grid_height {
            FogLevel::from_u8(self.fog[(y * self.grid_width + x) as usize])
        } else {
            FogLevel::Hidden
        }
    }

    /// Set the fog overlay color (RGBA). Replaces the current fog color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `[f32; 4]`.
    pub fn set_fog_color(&mut self, color: [f32; 4]) {
        self.fog_color = color;
    }

    /// Get the fog overlay color. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `[f32`.
    pub fn fog_color(&self) -> [f32; 4] {
        self.fog_color
    }

    /// Set the entire fog grid from a flat byte array.
    ///
    /// # Parameters
    /// - `data` — `&[u8]`.
    pub fn set_fog_data(&mut self, data: &[u8]) {
        let cell_count = (self.grid_width * self.grid_height) as usize;
        for (i, &val) in data.iter().enumerate().take(cell_count) {
            self.fog[i] = val.min(2);
        }
    }

    // ── Object types ──

    /// Register a new object type and return its index.
    ///
    /// # Parameters
    /// - `name` — `String`.
    /// - `color` — `[f32; 4]`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_object_type(&mut self, name: String, color: [f32; 4]) -> usize {
        let idx = self.object_types.len();
        self.object_types.push(MinimapObjectType {
            name,
            color,
            visible: true,
        });
        idx
    }

    /// Set whether an object type is visible on the minimap.
    ///
    /// # Parameters
    /// - `ype_index` — `usize`.
    /// - `visible` — `bool`.
    pub fn set_object_type_visible(&mut self, type_index: usize, visible: bool) {
        if let Some(ot) = self.object_types.get_mut(type_index) {
            ot.visible = visible;
        }
    }

    /// Returns whether an object type is visible.
    ///
    /// # Parameters
    /// - `ype_index` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_object_type_visible(&self, type_index: usize) -> bool {
        self.object_types
            .get(type_index)
            .is_some_and(|ot| ot.visible)
    }

    /// Get the number of registered object types.
    ///
    /// # Returns
    /// `usize`.
    pub fn object_type_count(&self) -> usize {
        self.object_types.len()
    }

    // ── Objects ──

    /// Set or update a tracked object on the minimap.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `ype_index` — `usize`.
    /// - `owner` — `u32`.
    pub fn set_object(&mut self, id: u32, x: f32, y: f32, type_index: usize, owner: u32) {
        self.objects.insert(id, MinimapObject { x, y, type_index, owner });
    }

    /// Remove a tracked object by ID. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_object(&mut self, id: u32) -> bool {
        self.objects.remove(&id).is_some()
    }

    /// Remove all tracked objects. After this call the container is in the same state as immediately after construction.
    pub fn clear_objects(&mut self) {
        self.objects.clear();
    }

    /// Get the number of tracked objects. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn object_count(&self) -> usize {
        self.objects.len()
    }

    // ── Owner colors ──

    /// Set the display color for an owner/faction.
    ///
    /// # Parameters
    /// - `owner` — `u32`.
    /// - `color` — `[f32; 4]`.
    pub fn set_owner_color(&mut self, owner: u32, color: [f32; 4]) {
        self.owner_colors.insert(owner, color);
    }

    /// Get the display color for an owner/faction.
    ///
    /// # Parameters
    /// - `owner` — `u32`.
    ///
    /// # Returns
    /// `[f32`.
    pub fn get_owner_color(&self, owner: u32) -> [f32; 4] {
        self.owner_colors.get(&owner).copied().unwrap_or([0.8, 0.8, 0.8, 1.0])
    }

    // ── Color mode ──

    /// Set the color mode (Terrain or Political).
    ///
    /// # Parameters
    /// - `ode` — `ColorMode`.
    pub fn set_color_mode(&mut self, mode: ColorMode) {
        self.color_mode = mode;
    }

    /// Get the current color mode. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `ColorMode`.
    pub fn color_mode(&self) -> ColorMode {
        self.color_mode
    }

    // ── Zoom and pan ──

    /// Set the zoom level (1.0 = default). Replaces the current zoom value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `zoom` — `f32`.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom.max(0.1);
    }

    /// Get the current zoom level. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f32`.
    pub fn zoom(&self) -> f32 {
        self.zoom
    }

    /// Set the center of the minimap view in grid coordinates.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn set_center(&mut self, x: f32, y: f32) {
        self.center_x = x;
        self.center_y = y;
    }

    /// Get the center X coordinate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f32`.
    pub fn center_x(&self) -> f32 {
        self.center_x
    }

    /// Get the center Y coordinate. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f32`.
    pub fn center_y(&self) -> f32 {
        self.center_y
    }

    // ── Viewport rectangle ──

    /// Set the viewport rectangle overlay (in grid coordinates).
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `w` — `f32`.
    /// - `h` — `f32`.
    pub fn set_viewport_rect(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport_rect = Some((x, y, w, h));
    }

    /// Clear the viewport rectangle overlay. After this call the container is in the same state as immediately after construction.
    pub fn clear_viewport_rect(&mut self) {
        self.viewport_rect = None;
    }

    /// Get the viewport rectangle, if set. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32)>`.
    pub fn viewport_rect(&self) -> Option<(f32, f32, f32, f32)> {
        self.viewport_rect
    }

    /// Set whether the viewport rectangle is visible.
    ///
    /// # Parameters
    /// - `visible` — `bool`.
    pub fn set_viewport_visible(&mut self, visible: bool) {
        self.viewport_visible = visible;
    }

    /// Returns whether the viewport rectangle is visible.
    ///
    /// # Returns
    /// `bool`.
    pub fn viewport_visible(&self) -> bool {
        self.viewport_visible
    }

    /// Set the viewport rectangle color. Replaces the current viewport color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `[f32; 4]`.
    pub fn set_viewport_color(&mut self, color: [f32; 4]) {
        self.viewport_color = color;
    }

    /// Get the viewport rectangle color. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `[f32`.
    pub fn viewport_color(&self) -> [f32; 4] {
        self.viewport_color
    }

    // ── Pings ──

    /// Add an animated ping at grid coordinates.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `duration` — `f32`.
    /// - `color` — `[f32; 4]`.
    pub fn add_ping(&mut self, x: f32, y: f32, duration: f32, color: [f32; 4]) {
        self.pings.push(MinimapPing {
            x,
            y,
            remaining: duration,
            duration,
            color,
        });
    }

    /// Get the number of active pings. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn ping_count(&self) -> usize {
        self.pings.len()
    }

    // ── Markers ──

    /// Add a persistent marker and return its ID.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    /// - `description` — `String`.
    /// - `color` — `[f32; 4]`.
    ///
    /// # Returns
    /// `u32`.
    pub fn add_marker(&mut self, x: f32, y: f32, description: String, color: [f32; 4]) -> u32 {
        let id = self.next_marker_id;
        self.next_marker_id += 1;
        self.markers.insert(id, MinimapMarker { x, y, description, color });
        id
    }

    /// Remove a marker by ID. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_marker(&mut self, id: u32) -> bool {
        self.markers.remove(&id).is_some()
    }

    /// Check if a marker with the given ID exists.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_marker(&self, id: u32) -> bool {
        self.markers.contains_key(&id)
    }

    /// Get the description of a marker, if it exists.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_marker_description(&self, id: u32) -> Option<&str> {
        self.markers.get(&id).map(|m| m.description.as_str())
    }

    /// Get the number of markers. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn marker_count(&self) -> usize {
        self.markers.len()
    }

    // ── Rendering options ──

    /// Set whether anti-aliasing is enabled. Replaces the current anti alias value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_anti_alias(&mut self, enabled: bool) {
        self.anti_alias = enabled;
    }

    /// Returns whether anti-aliasing is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn anti_alias(&self) -> bool {
        self.anti_alias
    }

    // ── Coordinate conversion ──

    /// Convert screen coordinates to grid coordinates.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    /// - `inimap_x` — `f32`.
    /// - `inimap_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn screen_to_grid(&self, sx: f32, sy: f32, minimap_x: f32, minimap_y: f32) -> (f32, f32) {
        let cells_visible_x = self.grid_width as f32 / self.zoom;
        let cells_visible_y = self.grid_height as f32 / self.zoom;
        let cell_px_w = self.display_width as f32 / cells_visible_x;
        let cell_px_h = self.display_height as f32 / cells_visible_y;

        let local_x = sx - minimap_x;
        let local_y = sy - minimap_y;

        let start_x = self.center_x - cells_visible_x / 2.0;
        let start_y = self.center_y - cells_visible_y / 2.0;

        let gx = start_x + local_x / cell_px_w;
        let gy = start_y + local_y / cell_px_h;
        (gx, gy)
    }

    /// Convert grid coordinates to screen coordinates.
    ///
    /// # Parameters
    /// - `gx` — `f32`.
    /// - `gy` — `f32`.
    /// - `inimap_x` — `f32`.
    /// - `inimap_y` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn grid_to_screen(&self, gx: f32, gy: f32, minimap_x: f32, minimap_y: f32) -> (f32, f32) {
        let cells_visible_x = self.grid_width as f32 / self.zoom;
        let cells_visible_y = self.grid_height as f32 / self.zoom;
        let cell_px_w = self.display_width as f32 / cells_visible_x;
        let cell_px_h = self.display_height as f32 / cells_visible_y;

        let start_x = self.center_x - cells_visible_x / 2.0;
        let start_y = self.center_y - cells_visible_y / 2.0;

        let sx = minimap_x + (gx - start_x) * cell_px_w;
        let sy = minimap_y + (gy - start_y) * cell_px_h;
        (sx, sy)
    }

    // ── Update ──

    /// Update pings (decrement timers, remove expired ones).
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        self.pings.retain_mut(|ping| {
            ping.remaining -= dt;
            ping.remaining > 0.0
        });
    }
}
