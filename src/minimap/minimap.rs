//! Core `Minimap` data model: terrain grid, fog of war, objects, pings, markers, and navigation.

use crate::runtime::log_messages::MM01_MINIMAP_INIT;
use crate::log_msg;
use std::collections::HashMap;

use super::types::{
    ColorMode, FogLevel, MinimapMarker, MinimapObject, MinimapObjectType, MinimapPing,
};

/// A grid-based minimap with terrain, fog-of-war, objects, pings, markers, and navigation state.
///
/// # Fields
/// - `grid_width` — `u32`.
/// - `grid_height` — `u32`.
/// - `display_width` — `u32`.
/// - `display_height` — `u32`.
/// - `terrain` — `Vec<u32>`.
/// - `terrain_colors` — `HashMap<u32, [f32; 4]>`.
/// - `fog` — `Vec<u8>`.
/// - `fog_enabled` — `bool`.
/// - `fog_color` — `[f32; 4]`.
/// - `objects` — `HashMap<u32, MinimapObject>`.
/// - `object_types` — `Vec<MinimapObjectType>`.
/// - `owner_colors` — `HashMap<u32, [f32; 4]>`.
/// - `color_mode` — `ColorMode`.
/// - `zoom` — `f32`.
/// - `center_x` — `f32`.
/// - `center_y` — `f32`.
/// - `viewport_rect` — `Option<(f32, f32, f32, f32)>`.
/// - `viewport_visible` — `bool`.
/// - `viewport_color` — `[f32; 4]`.
/// - `pings` — `Vec<MinimapPing>`.
/// - `markers` — `HashMap<u32, MinimapMarker>`.
/// - `anti_alias` — `bool`.
/// - `clickable` — `bool`.
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
    tile_descriptions: HashMap<u32, String>,

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
    clickable: bool,
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
        log_msg!(
            debug,
            MM01_MINIMAP_INIT,
            "{}x{} grid",
            grid_width,
            grid_height
        );
        let cell_count = (grid_width * grid_height) as usize;
        Self {
            grid_width,
            grid_height,
            display_width,
            display_height,
            terrain: vec![0; cell_count],
            terrain_colors: HashMap::new(),
            tile_descriptions: HashMap::new(),
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
            clickable: true,
        }
    }

    // ── Grid queries ──

    /// Returns the grid width in cells.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_width(&self) -> u32 {
        self.grid_width
    }

    /// Returns the grid height in cells.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_height(&self) -> u32 {
        self.grid_height
    }

    /// Returns the total number of grid cells.
    ///
    /// # Returns
    /// `u32`.
    pub fn grid_size(&self) -> u32 {
        self.grid_width * self.grid_height
    }

    // ── Display dimensions ──

    /// Returns the display width in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn display_width(&self) -> u32 {
        self.display_width
    }

    /// Returns the display height in pixels.
    ///
    /// # Returns
    /// `u32`.
    pub fn display_height(&self) -> u32 {
        self.display_height
    }

    /// Set the display size in pixels.
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
    /// - `terrain_type` — `u32`.
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

    /// Bulk-set terrain types from a flat slice (row-major, length = gridW × gridH).
    ///
    /// # Parameters
    /// - `data` — `&[u32]`.
    pub fn set_terrain_data(&mut self, data: &[u32]) {
        let cell_count = (self.grid_width * self.grid_height) as usize;
        for (i, &val) in data.iter().enumerate().take(cell_count) {
            self.terrain[i] = val;
        }
    }

    /// Set the display color for a terrain type.
    ///
    /// # Parameters
    /// - `terrain_type` — `u32`.
    /// - `color` — `[f32; 4]`.
    pub fn set_terrain_color(&mut self, terrain_type: u32, color: [f32; 4]) {
        self.terrain_colors.insert(terrain_type, color);
    }

    /// Get the display color for a terrain type (grey `[0.5, 0.5, 0.5, 1.0]` if unset).
    ///
    /// # Parameters
    /// - `terrain_type` — `u32`.
    ///
    /// # Returns
    /// `[f32; 4]`.
    pub fn get_terrain_color(&self, terrain_type: u32) -> [f32; 4] {
        self.terrain_colors
            .get(&terrain_type)
            .copied()
            .unwrap_or([0.5, 0.5, 0.5, 1.0])
    }

    // ── Tile descriptions ──

    /// Set a hover tooltip string for a terrain type ID.
    ///
    /// # Parameters
    /// - `type_id` — `u32`.
    /// - `desc` — `String`.
    pub fn set_tile_description(&mut self, type_id: u32, desc: String) {
        self.tile_descriptions.insert(type_id, desc);
    }

    /// Get the hover tooltip string for a terrain type ID. Returns `None` if not set.
    ///
    /// # Parameters
    /// - `type_id` — `u32`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_tile_description(&self, type_id: u32) -> Option<&str> {
        self.tile_descriptions.get(&type_id).map(|s| s.as_str())
    }

    // ── Fog of war ──

    /// Enable or disable fog of war.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_fog_enabled(&mut self, enabled: bool) {
        self.fog_enabled = enabled;
    }

    /// Returns whether fog of war is enabled.
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

    /// Set the fog overlay color (RGBA).
    ///
    /// # Parameters
    /// - `color` — `[f32; 4]`.
    pub fn set_fog_color(&mut self, color: [f32; 4]) {
        self.fog_color = color;
    }

    /// Get the fog overlay color.
    ///
    /// # Returns
    /// `[f32; 4]`.
    pub fn fog_color(&self) -> [f32; 4] {
        self.fog_color
    }

    /// Set the entire fog grid from a flat byte array (0=hidden, 1=explored, 2=visible).
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

    /// Register a new object type and return its 0-based index.
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
    /// - `type_index` — `usize`.
    /// - `visible` — `bool`.
    pub fn set_object_type_visible(&mut self, type_index: usize, visible: bool) {
        if let Some(ot) = self.object_types.get_mut(type_index) {
            ot.visible = visible;
        }
    }

    /// Returns whether an object type is visible.
    ///
    /// # Parameters
    /// - `type_index` — `usize`.
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
    /// - `type_index` — `usize`.
    /// - `owner` — `u32`.
    pub fn set_object(&mut self, id: u32, x: f32, y: f32, type_index: usize, owner: u32) {
        self.objects.insert(
            id,
            MinimapObject {
                x,
                y,
                type_index,
                owner,
            },
        );
    }

    /// Remove a tracked object by ID. Returns `true` if the object was present.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_object(&mut self, id: u32) -> bool {
        self.objects.remove(&id).is_some()
    }

    /// Remove all tracked objects.
    pub fn clear_objects(&mut self) {
        self.objects.clear();
    }

    /// Get the number of tracked objects.
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

    /// Get the display color for an owner/faction (grey `[0.8, 0.8, 0.8, 1.0]` if unset).
    ///
    /// # Parameters
    /// - `owner` — `u32`.
    ///
    /// # Returns
    /// `[f32; 4]`.
    pub fn get_owner_color(&self, owner: u32) -> [f32; 4] {
        self.owner_colors
            .get(&owner)
            .copied()
            .unwrap_or([0.8, 0.8, 0.8, 1.0])
    }

    // ── Color mode ──

    /// Set the color mode (`Terrain` or `Political`).
    ///
    /// # Parameters
    /// - `mode` — `ColorMode`.
    pub fn set_color_mode(&mut self, mode: ColorMode) {
        self.color_mode = mode;
    }

    /// Get the current color mode.
    ///
    /// # Returns
    /// `ColorMode`.
    pub fn color_mode(&self) -> ColorMode {
        self.color_mode
    }

    // ── Zoom and pan ──

    /// Set the zoom level (minimum 0.1).
    ///
    /// # Parameters
    /// - `zoom` — `f32`.
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom.max(0.1);
    }

    /// Get the current zoom level.
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

    /// Get the center X coordinate.
    ///
    /// # Returns
    /// `f32`.
    pub fn center_x(&self) -> f32 {
        self.center_x
    }

    /// Get the center Y coordinate.
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

    /// Clear the viewport rectangle overlay.
    pub fn clear_viewport_rect(&mut self) {
        self.viewport_rect = None;
    }

    /// Get the viewport rectangle, if set.
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

    /// Set the viewport rectangle color.
    ///
    /// # Parameters
    /// - `color` — `[f32; 4]`.
    pub fn set_viewport_color(&mut self, color: [f32; 4]) {
        self.viewport_color = color;
    }

    /// Get the viewport rectangle color.
    ///
    /// # Returns
    /// `[f32; 4]`.
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

    /// Get the number of active pings.
    ///
    /// # Returns
    /// `usize`.
    pub fn ping_count(&self) -> usize {
        self.pings.len()
    }

    // ── Markers ──

    /// Add a persistent marker and return its auto-assigned ID.
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
        self.markers.insert(
            id,
            MinimapMarker {
                x,
                y,
                description,
                color,
            },
        );
        id
    }

    /// Remove a marker by ID. Returns `true` if it existed.
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

    /// Get the number of markers.
    ///
    /// # Returns
    /// `usize`.
    pub fn marker_count(&self) -> usize {
        self.markers.len()
    }

    // ── Rendering options ──

    /// Set whether anti-aliasing is enabled.
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

    /// Set whether this minimap responds to click hit-testing.
    ///
    /// # Parameters
    /// - `enabled` — `bool`.
    pub fn set_clickable(&mut self, enabled: bool) {
        self.clickable = enabled;
    }

    /// Returns whether this minimap responds to click hit-testing.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_clickable(&self) -> bool {
        self.clickable
    }

    // ── Coordinate conversion ──

    /// Convert screen coordinates to grid coordinates.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    /// - `minimap_x` — `f32`.
    /// - `minimap_y` — `f32`.
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
    /// - `minimap_x` — `f32`.
    /// - `minimap_y` — `f32`.
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

    /// Get hover tooltip text for the element under the given screen coordinates.
    ///
    /// Returns the tile description of the terrain type at the hovered grid cell, or `None`
    /// if the coordinates are outside the minimap or no description is set for that terrain type.
    ///
    /// # Parameters
    /// - `sx` — `f32`.
    /// - `sy` — `f32`.
    /// - `minimap_x` — `f32`.
    /// - `minimap_y` — `f32`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_hover_info(&self, sx: f32, sy: f32, minimap_x: f32, minimap_y: f32) -> Option<&str> {
        // Bounds check against display rect
        let local_x = sx - minimap_x;
        let local_y = sy - minimap_y;
        if local_x < 0.0
            || local_y < 0.0
            || local_x >= self.display_width as f32
            || local_y >= self.display_height as f32
        {
            return None;
        }

        let (gx, gy) = self.screen_to_grid(sx, sy, minimap_x, minimap_y);
        let gxi = gx.floor() as i64;
        let gyi = gy.floor() as i64;
        if gxi < 0 || gyi < 0 || gxi >= self.grid_width as i64 || gyi >= self.grid_height as i64 {
            return None;
        }

        let terrain_type = self.terrain[(gyi as u32 * self.grid_width + gxi as u32) as usize];
        self.get_tile_description(terrain_type)
    }

    // ── Update ──

    /// Advance time-based effects: decrement ping timers and remove expired pings.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn update(&mut self, dt: f32) {
        self.pings.retain_mut(|ping| {
            ping.remaining -= dt;
            ping.remaining > 0.0
        });
    }

    // ── CPU rendering ──

    /// Renders the minimap to an `ImageData` for evidence/testing.
    ///
    /// Draws terrain cells coloured by terrain type (or political owner
    /// colours), applies fog-of-war dimming, and stamps objects and markers
    /// on top.
    ///
    /// # Parameters
    /// - `pixel_size` — `u32` — Output image size in pixels (both width and height
    ///   are derived from `display_width` / `display_height`).
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, _pixel_size: u32) -> crate::image::ImageData {
        let w = self.display_width;
        let h = self.display_height;
        let cell_w = w / self.grid_width.max(1);
        let cell_h = h / self.grid_height.max(1);

        let mut img = crate::image::ImageData::new(w, h);

        // Draw terrain cells
        for gy in 0..self.grid_height {
            for gx in 0..self.grid_width {
                let terrain_type = self.get_terrain(gx, gy);
                let tc = match self.color_mode {
                    ColorMode::Political => {
                        // Find first object in this cell and use its owner colour
                        let mut owner_c = self.get_terrain_color(terrain_type);
                        for obj in self.objects.values() {
                            let ox = obj.x as u32;
                            let oy = obj.y as u32;
                            // If there are objects with this owner, paint the cell area
                            if ox / self.grid_width.max(1) == gx / 1
                                || oy / self.grid_height.max(1) == gy / 1
                            {
                                owner_c = self.get_owner_color(obj.owner);
                                break;
                            }
                        }
                        owner_c
                    }
                    _ => self.get_terrain_color(terrain_type),
                };

                let mut mult = 1.0f32;
                if self.fog_enabled {
                    let fog = self.get_fog_level(gx, gy);
                    mult = match fog {
                        FogLevel::Visible => 1.0,
                        FogLevel::Explored => 0.5,
                        FogLevel::Hidden => 0.15,
                    };
                }

                let r = (tc[0] * 255.0 * mult) as u8;
                let g = (tc[1] * 255.0 * mult) as u8;
                let b = (tc[2] * 255.0 * mult) as u8;

                for py in 0..cell_h {
                    for px in 0..cell_w {
                        img.set_pixel(gx * cell_w + px, gy * cell_h + py, r, g, b, 255);
                    }
                }
            }
        }

        // Draw objects
        for obj in self.objects.values() {
            let screen_x = (obj.x * cell_w as f32) as i32;
            let screen_y = (obj.y * cell_h as f32) as i32;
            let ot = self.object_types.get(obj.type_index);
            let (cr, cg, cb, radius) = if let Some(ot) = ot {
                (
                    (ot.color[0] * 255.0) as u8,
                    (ot.color[1] * 255.0) as u8,
                    (ot.color[2] * 255.0) as u8,
                    4u32,
                )
            } else {
                (255, 255, 255, 3)
            };
            img.draw_circle(screen_x, screen_y, radius, cr, cg, cb, 255);
        }

        // Draw markers
        for marker in self.markers.values() {
            let mx = (marker.x * cell_w as f32) as i32;
            let my = (marker.y * cell_h as f32) as i32;
            let mr = (marker.color[0] * 255.0) as u8;
            let mg = (marker.color[1] * 255.0) as u8;
            let mb = (marker.color[2] * 255.0) as u8;
            img.draw_circle(mx, my, 3, mr, mg, mb, 255);
            img.draw_line(mx - 4, my, mx + 4, my, mr, mg, mb, 255);
            img.draw_line(mx, my - 4, mx, my + 4, mr, mg, mb, 255);
        }

        img
    }

    /// Generates GPU `RenderCommand`s for the minimap at the given screen position.
    ///
    /// # Parameters
    /// - `screen_x` — `f32` — Screen X of the minimap top-left corner.
    /// - `screen_y` — `f32` — Screen Y of the minimap top-left corner.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn build_render_commands(
        &self,
        screen_x: f32,
        screen_y: f32,
    ) -> Vec<crate::graphics::renderer::RenderCommand> {
        use crate::graphics::renderer::{DrawMode, RenderCommand};

        let mut cmds: Vec<RenderCommand> = Vec::new();
        let cw = (self.display_width / self.grid_width.max(1)) as f32;
        let ch = (self.display_height / self.grid_height.max(1)) as f32;

        // ── Terrain cells ──────────────────────────────────────────────────────
        for gy in 0..self.grid_height {
            for gx in 0..self.grid_width {
                let terrain_type = self.get_terrain(gx, gy);
                let tc = self.get_terrain_color(terrain_type);
                let mut mult = 1.0f32;
                if self.fog_enabled {
                    let fog = self.get_fog_level(gx, gy);
                    mult = match fog {
                        FogLevel::Visible => 1.0,
                        FogLevel::Explored => 0.5,
                        FogLevel::Hidden => 0.15,
                    };
                }
                cmds.push(RenderCommand::SetColor(
                    tc[0] * mult,
                    tc[1] * mult,
                    tc[2] * mult,
                    1.0,
                ));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: screen_x + gx as f32 * cw,
                    y: screen_y + gy as f32 * ch,
                    w: cw,
                    h: ch,
                });
            }
        }

        // ── Objects ────────────────────────────────────────────────────────────
        for obj in self.objects.values() {
            let ox = screen_x + obj.x * cw;
            let oy = screen_y + obj.y * ch;
            let ot = self.object_types.get(obj.type_index);
            let (r, g, b) = if let Some(ot) = ot {
                (ot.color[0], ot.color[1], ot.color[2])
            } else {
                (1.0f32, 1.0, 1.0)
            };
            cmds.push(RenderCommand::SetColor(r, g, b, 1.0));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: ox,
                y: oy,
                r: 4.0,
            });
        }

        // ── Markers ────────────────────────────────────────────────────────────
        for marker in self.markers.values() {
            let mx = screen_x + marker.x * cw;
            let my = screen_y + marker.y * ch;
            cmds.push(RenderCommand::SetColor(
                marker.color[0],
                marker.color[1],
                marker.color[2],
                marker.color[3],
            ));
            cmds.push(RenderCommand::Circle {
                mode: DrawMode::Fill,
                x: mx,
                y: my,
                r: 3.0,
            });
            cmds.push(RenderCommand::Line {
                x1: mx - 4.0,
                y1: my,
                x2: mx + 4.0,
                y2: my,
            });
            cmds.push(RenderCommand::Line {
                x1: mx,
                y1: my - 4.0,
                x2: mx,
                y2: my + 4.0,
            });
        }

        cmds
    }
}
