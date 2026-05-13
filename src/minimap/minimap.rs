use super::types::{
    ColorMode, FogLevel, LayerData, MarkerAnimation, MinimapMarker, MinimapObject,
    MinimapObjectType, MinimapPing, OverlayPath, OverlayShape,
};
use crate::camera::Camera2D;
use crate::log_msg;
use crate::runtime::log_messages::MM01_MINIMAP_INIT;
use crate::runtime::resource_keys::TextureKey;
use std::collections::HashMap;
#[derive(Debug, Clone, Copy)]
pub(crate) struct MinimapIcon {
    pub texture_key: TextureKey,
    pub texture_width: f32,
    pub texture_height: f32,
    pub display_width: f32,
    pub display_height: f32,
}
#[derive(Debug, Clone)]
pub struct Minimap {
    grid_width: u32,
    grid_height: u32,
    display_width: u32,
    display_height: u32,
    terrain: Vec<u32>,
    terrain_colors: HashMap<u32, [f32; 4]>,
    tile_descriptions: HashMap<u32, String>,
    fog: Vec<u8>,
    fog_enabled: bool,
    fog_color: [f32; 4],
    objects: HashMap<u32, MinimapObject>,
    object_types: Vec<MinimapObjectType>,
    object_type_icons: HashMap<usize, MinimapIcon>,
    owner_colors: HashMap<u32, [f32; 4]>,
    color_mode: ColorMode,
    zoom: f32,
    center_x: f32,
    center_y: f32,
    viewport_rect: Option<(f32, f32, f32, f32)>,
    viewport_visible: bool,
    viewport_color: [f32; 4],
    pings: Vec<MinimapPing>,
    markers: HashMap<u32, MinimapMarker>,
    marker_icons: HashMap<u32, MinimapIcon>,
    next_marker_id: u32,
    anti_alias: bool,
    clickable: bool,
    overlay_shapes: Vec<OverlayShape>,
    paths: Vec<OverlayPath>,
    next_path_id: u32,
    layers: Vec<LayerData>,
    active_layer: usize,
}
impl Minimap {
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
            object_type_icons: HashMap::new(),
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
            marker_icons: HashMap::new(),
            next_marker_id: 1,
            anti_alias: false,
            clickable: true,
            overlay_shapes: Vec::new(),
            paths: Vec::new(),
            next_path_id: 1,
            layers: Vec::new(),
            active_layer: 0,
        }
    }
    pub fn grid_width(&self) -> u32 {
        self.grid_width
    }
    pub fn grid_height(&self) -> u32 {
        self.grid_height
    }
    pub fn grid_size(&self) -> u32 {
        self.grid_width * self.grid_height
    }
    pub fn display_width(&self) -> u32 {
        self.display_width
    }
    pub fn display_height(&self) -> u32 {
        self.display_height
    }
    pub fn set_display_size(&mut self, width: u32, height: u32) {
        self.display_width = width;
        self.display_height = height;
    }
    pub fn set_terrain(&mut self, x: u32, y: u32, terrain_type: u32) {
        if x < self.grid_width && y < self.grid_height {
            let idx = (y * self.grid_width + x) as usize;
            self.terrain[idx] = terrain_type;
        }
    }
    pub fn get_terrain(&self, x: u32, y: u32) -> u32 {
        if x < self.grid_width && y < self.grid_height {
            self.terrain[(y * self.grid_width + x) as usize]
        } else {
            0
        }
    }
    pub fn set_terrain_data(&mut self, data: &[u32]) {
        let cell_count = (self.grid_width * self.grid_height) as usize;
        for (i, &val) in data.iter().enumerate().take(cell_count) {
            self.terrain[i] = val;
        }
    }
    pub fn set_terrain_color(&mut self, terrain_type: u32, color: [f32; 4]) {
        self.terrain_colors.insert(terrain_type, color);
    }
    pub fn get_terrain_color(&self, terrain_type: u32) -> [f32; 4] {
        self.terrain_colors
            .get(&terrain_type)
            .copied()
            .unwrap_or([0.5, 0.5, 0.5, 1.0])
    }
    pub fn set_tile_description(&mut self, type_id: u32, desc: String) {
        self.tile_descriptions.insert(type_id, desc);
    }
    pub fn get_tile_description(&self, type_id: u32) -> Option<&str> {
        self.tile_descriptions.get(&type_id).map(|s| s.as_str())
    }
    pub fn set_fog_enabled(&mut self, enabled: bool) {
        self.fog_enabled = enabled;
    }
    pub fn fog_enabled(&self) -> bool {
        self.fog_enabled
    }
    pub fn set_fog_level(&mut self, x: u32, y: u32, level: FogLevel) {
        if x < self.grid_width && y < self.grid_height {
            let idx = (y * self.grid_width + x) as usize;
            self.fog[idx] = level as u8;
        }
    }
    pub fn get_fog_level(&self, x: u32, y: u32) -> FogLevel {
        if x < self.grid_width && y < self.grid_height {
            FogLevel::from_u8(self.fog[(y * self.grid_width + x) as usize])
        } else {
            FogLevel::Hidden
        }
    }
    pub fn set_fog_color(&mut self, color: [f32; 4]) {
        self.fog_color = color;
    }
    pub fn fog_color(&self) -> [f32; 4] {
        self.fog_color
    }
    pub fn set_fog_data(&mut self, data: &[u8]) {
        let cell_count = (self.grid_width * self.grid_height) as usize;
        for (i, &val) in data.iter().enumerate().take(cell_count) {
            self.fog[i] = val.min(2);
        }
    }
    pub fn fog_multiplier(&self, x: u32, y: u32) -> f32 {
        if !self.fog_enabled {
            return 1.0;
        }
        match self.get_fog_level(x, y) {
            FogLevel::Visible => 1.0,
            FogLevel::Explored => 0.5,
            FogLevel::Hidden => 0.15,
        }
    }
    pub fn add_object_type(&mut self, name: String, color: [f32; 4]) -> usize {
        let idx = self.object_types.len();
        self.object_types.push(MinimapObjectType {
            name,
            color,
            visible: true,
        });
        idx
    }
    pub fn set_object_type_texture(
        &mut self,
        type_index: usize,
        texture_key: TextureKey,
        texture_width: f32,
        texture_height: f32,
        display_width: f32,
        display_height: f32,
    ) {
        if self.object_types.get(type_index).is_none() {
            return;
        }
        self.object_type_icons.insert(
            type_index,
            MinimapIcon {
                texture_key,
                texture_width: texture_width.max(1.0),
                texture_height: texture_height.max(1.0),
                display_width: display_width.max(1.0),
                display_height: display_height.max(1.0),
            },
        );
    }
    pub fn clear_object_type_texture(&mut self, type_index: usize) {
        self.object_type_icons.remove(&type_index);
    }
    pub fn set_object_type_visible(&mut self, type_index: usize, visible: bool) {
        if let Some(ot) = self.object_types.get_mut(type_index) {
            ot.visible = visible;
        }
    }
    pub fn is_object_type_visible(&self, type_index: usize) -> bool {
        self.object_types
            .get(type_index)
            .is_some_and(|ot| ot.visible)
    }
    pub fn object_type_count(&self) -> usize {
        self.object_types.len()
    }
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
    pub fn remove_object(&mut self, id: u32) -> bool {
        self.objects.remove(&id).is_some()
    }
    pub fn clear_objects(&mut self) {
        self.objects.clear();
    }
    pub fn object_count(&self) -> usize {
        self.objects.len()
    }
    pub(crate) fn objects_iter(&self) -> impl Iterator<Item = &MinimapObject> {
        self.objects.values()
    }
    pub(crate) fn object_type(&self, type_index: usize) -> Option<&MinimapObjectType> {
        self.object_types.get(type_index)
    }
    pub fn set_owner_color(&mut self, owner: u32, color: [f32; 4]) {
        self.owner_colors.insert(owner, color);
    }
    pub fn get_owner_color(&self, owner: u32) -> [f32; 4] {
        self.owner_colors
            .get(&owner)
            .copied()
            .unwrap_or([0.8, 0.8, 0.8, 1.0])
    }
    pub fn set_color_mode(&mut self, mode: ColorMode) {
        self.color_mode = mode;
    }
    pub fn color_mode(&self) -> ColorMode {
        self.color_mode
    }
    pub fn set_zoom(&mut self, zoom: f32) {
        self.zoom = zoom.max(0.1);
    }
    pub fn zoom(&self) -> f32 {
        self.zoom
    }
    pub fn set_center(&mut self, x: f32, y: f32) {
        self.center_x = x;
        self.center_y = y;
    }
    pub fn track_camera(&mut self, camera: &Camera2D) {
        let (camera_x, camera_y) = camera.get_position();
        let (vx, vy, vw, vh) = camera.get_visible_area();
        self.set_center(camera_x, camera_y);
        self.set_viewport_rect(vx, vy, vw, vh);
    }
    pub fn reveal_radius(&mut self, cx: f32, cy: f32, radius: f32) {
        if radius <= 0.0 {
            return;
        }
        let radius_sq = radius * radius;
        let min_x = ((cx - radius).floor() as i64).max(0) as u32;
        let min_y = ((cy - radius).floor() as i64).max(0) as u32;
        let max_x = ((cx + radius).ceil() as i64).min(self.grid_width as i64 - 1) as u32;
        let max_y = ((cy + radius).ceil() as i64).min(self.grid_height as i64 - 1) as u32;
        for gy in min_y..=max_y {
            for gx in min_x..=max_x {
                let dx = gx as f32 + 0.5 - cx;
                let dy = gy as f32 + 0.5 - cy;
                if dx * dx + dy * dy <= radius_sq {
                    self.set_fog_level(gx, gy, FogLevel::Visible);
                }
            }
        }
    }
    pub fn center_x(&self) -> f32 {
        self.center_x
    }
    pub fn center_y(&self) -> f32 {
        self.center_y
    }
    pub fn set_viewport_rect(&mut self, x: f32, y: f32, w: f32, h: f32) {
        self.viewport_rect = Some((x, y, w, h));
    }
    pub fn clear_viewport_rect(&mut self) {
        self.viewport_rect = None;
    }
    pub fn viewport_rect(&self) -> Option<(f32, f32, f32, f32)> {
        self.viewport_rect
    }
    pub fn set_viewport_visible(&mut self, visible: bool) {
        self.viewport_visible = visible;
    }
    pub fn viewport_visible(&self) -> bool {
        self.viewport_visible
    }
    pub fn set_viewport_color(&mut self, color: [f32; 4]) {
        self.viewport_color = color;
    }
    pub fn viewport_color(&self) -> [f32; 4] {
        self.viewport_color
    }
    pub fn add_ping(&mut self, x: f32, y: f32, duration: f32, color: [f32; 4]) {
        self.pings.push(MinimapPing {
            x,
            y,
            remaining: duration,
            duration,
            color,
        });
    }
    pub fn ping_count(&self) -> usize {
        self.pings.len()
    }
    pub fn pings(&self) -> &[MinimapPing] {
        &self.pings
    }
    pub fn markers_iter(&self) -> impl Iterator<Item = &MinimapMarker> {
        self.markers.values()
    }
    pub(crate) fn markers_with_ids(&self) -> impl Iterator<Item = (&u32, &MinimapMarker)> {
        self.markers.iter()
    }
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
                animation: None,
            },
        );
        id
    }
    pub fn remove_marker(&mut self, id: u32) -> bool {
        self.marker_icons.remove(&id);
        self.markers.remove(&id).is_some()
    }
    pub fn set_marker_texture(
        &mut self,
        id: u32,
        texture_key: TextureKey,
        texture_width: f32,
        texture_height: f32,
        display_width: f32,
        display_height: f32,
    ) {
        if !self.markers.contains_key(&id) {
            return;
        }
        self.marker_icons.insert(
            id,
            MinimapIcon {
                texture_key,
                texture_width: texture_width.max(1.0),
                texture_height: texture_height.max(1.0),
                display_width: display_width.max(1.0),
                display_height: display_height.max(1.0),
            },
        );
    }
    pub fn clear_marker_texture(&mut self, id: u32) {
        self.marker_icons.remove(&id);
    }
    pub fn has_marker(&self, id: u32) -> bool {
        self.markers.contains_key(&id)
    }
    pub fn get_marker_description(&self, id: u32) -> Option<&str> {
        self.markers.get(&id).map(|m| m.description.as_str())
    }
    pub fn marker_count(&self) -> usize {
        self.markers.len()
    }
    pub fn set_marker_animation(&mut self, id: u32, anim: MarkerAnimation) {
        if let Some(marker) = self.markers.get_mut(&id) {
            marker.animation = Some(anim);
        }
    }
    pub fn clear_marker_animation(&mut self, id: u32) {
        if let Some(marker) = self.markers.get_mut(&id) {
            marker.animation = None;
        }
    }
    pub fn draw_line(&mut self, x1: f32, y1: f32, x2: f32, y2: f32, color: [u8; 4]) {
        self.overlay_shapes.push(OverlayShape::Line {
            x1,
            y1,
            x2,
            y2,
            color,
        });
    }
    pub fn draw_rect(&mut self, x: f32, y: f32, w: f32, h: f32, color: [u8; 4]) {
        self.overlay_shapes
            .push(OverlayShape::Rect { x, y, w, h, color });
    }
    pub fn clear_overlay(&mut self) {
        self.overlay_shapes.clear();
    }
    pub fn overlay_shapes(&self) -> &[OverlayShape] {
        &self.overlay_shapes
    }
    pub fn show_path(&mut self, points: Vec<(f32, f32)>, color: [u8; 4]) -> u32 {
        let id = self.next_path_id;
        self.next_path_id += 1;
        self.paths.push(OverlayPath { id, points, color });
        id
    }
    pub fn clear_path(&mut self, id: Option<u32>) {
        match id {
            Some(n) => self.paths.retain(|p| p.id != n),
            None => self.paths.clear(),
        }
    }
    pub fn paths(&self) -> &[OverlayPath] {
        &self.paths
    }
    pub fn set_layer(&mut self, layer: usize) {
        self.active_layer = layer;
    }
    pub fn get_layer(&self) -> usize {
        self.active_layer
    }
    pub fn set_layer_data(&mut self, layer: usize, data: LayerData) {
        if layer >= self.layers.len() {
            self.layers.resize_with(layer + 1, || LayerData {
                cells: Vec::new(),
                width: 0,
                height: 0,
            });
        }
        self.layers[layer] = data;
    }
    pub fn layer_data(&self, layer: usize) -> Option<&LayerData> {
        self.layers.get(layer)
    }
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
    pub fn set_anti_alias(&mut self, enabled: bool) {
        self.anti_alias = enabled;
    }
    pub fn anti_alias(&self) -> bool {
        self.anti_alias
    }
    pub fn set_clickable(&mut self, enabled: bool) {
        self.clickable = enabled;
    }
    pub fn is_clickable(&self) -> bool {
        self.clickable
    }
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
    pub fn get_hover_info(&self, sx: f32, sy: f32, minimap_x: f32, minimap_y: f32) -> Option<&str> {
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
    pub fn update(&mut self, dt: f32) {
        self.pings.retain_mut(|ping| {
            ping.remaining -= dt;
            ping.remaining > 0.0
        });
        for marker in self.markers.values_mut() {
            if let Some(ref mut anim) = marker.animation {
                match anim {
                    MarkerAnimation::Blink { speed, phase }
                    | MarkerAnimation::Pulse { speed, phase } => {
                        *phase = (*phase + dt * *speed).rem_euclid(1.0);
                    }
                    MarkerAnimation::Rotate { speed, angle } => {
                        *angle = (*angle + dt * *speed).rem_euclid(std::f32::consts::TAU);
                    }
                }
            }
        }
    }
    pub fn draw_to_image(&self, _pixel_size: u32) -> crate::image::ImageData {
        let w = self.display_width;
        let h = self.display_height;
        let cell_w = w / self.grid_width.max(1);
        let cell_h = h / self.grid_height.max(1);
        let mut img = crate::image::ImageData::new(w, h);
        let owner_colors = self.owner_colors_by_cell();
        for gy in 0..self.grid_height {
            for gx in 0..self.grid_width {
                let terrain_type = self.get_terrain(gx, gy);
                let tc = self.resolve_cell_color(gx, gy, terrain_type, &owner_colors);
                let mult = self.fog_multiplier(gx, gy);
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
    pub fn build_render_commands(
        &self,
        screen_x: f32,
        screen_y: f32,
    ) -> Vec<crate::render::renderer::RenderCommand> {
        self.generate_render_commands(screen_x, screen_y)
    }
    pub(crate) fn object_type_icon(&self, type_index: usize) -> Option<MinimapIcon> {
        self.object_type_icons.get(&type_index).copied()
    }
    pub(crate) fn marker_icon(&self, id: u32) -> Option<MinimapIcon> {
        self.marker_icons.get(&id).copied()
    }
    pub(crate) fn owner_colors_by_cell(&self) -> HashMap<(u32, u32), [f32; 4]> {
        let mut owner_colors = HashMap::with_capacity(self.objects.len());
        for object in self.objects.values() {
            let gx = object.x.floor() as i64;
            let gy = object.y.floor() as i64;
            if gx < 0 || gy < 0 || gx >= self.grid_width as i64 || gy >= self.grid_height as i64 {
                continue;
            }
            owner_colors.insert((gx as u32, gy as u32), self.get_owner_color(object.owner));
        }
        owner_colors
    }
    pub(crate) fn resolve_cell_color(
        &self,
        gx: u32,
        gy: u32,
        terrain_type: u32,
        owner_colors: &HashMap<(u32, u32), [f32; 4]>,
    ) -> [f32; 4] {
        match self.color_mode {
            ColorMode::Terrain => self.get_terrain_color(terrain_type),
            ColorMode::Political => owner_colors
                .get(&(gx, gy))
                .copied()
                .unwrap_or_else(|| self.get_terrain_color(terrain_type)),
        }
    }
}
