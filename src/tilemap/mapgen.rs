use super::tilemap::TileMap;
use super::tileset::TileSet;
use crate::log_msg;
use crate::runtime::log_messages::{MG01, MG02, MG03};
use std::collections::HashMap;
#[derive(Debug, Clone, Copy, Hash, PartialEq, Eq)]
pub enum Edge {
    North,
    East,
    South,
    West,
}
impl Edge {
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Edge> {
        match s {
            "north" => Some(Edge::North),
            "east" => Some(Edge::East),
            "south" => Some(Edge::South),
            "west" => Some(Edge::West),
            _ => None,
        }
    }
    pub fn as_str(&self) -> &'static str {
        match self {
            Edge::North => "north",
            Edge::East => "east",
            Edge::South => "south",
            Edge::West => "west",
        }
    }
}
#[derive(Clone)]
pub struct MapBlock {
    width: u32,
    height: u32,
    layers: u32,
    segment_size: u32,
    name: String,
    weight: f32,
    tile_data: Vec<Vec<u32>>,
    sides: HashMap<(Edge, u32), u32>,
}
impl MapBlock {
    pub fn new(width: u32, height: u32, layers: u32, segment_size: u32) -> Self {
        let cap = (width * height) as usize;
        let tile_data = (0..layers).map(|_| vec![0u32; cap]).collect();
        log_msg!(debug, MG01, "{}x{} {} layers", width, height, layers);
        Self {
            width,
            height,
            layers,
            segment_size,
            name: String::new(),
            weight: 1.0,
            tile_data,
            sides: HashMap::new(),
        }
    }
    pub fn set_tile(&mut self, layer: u32, x: u32, y: u32, gid: u32) {
        if let Some(data) = self.tile_data.get_mut(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                data[idx] = gid;
            }
        }
    }
    pub fn get_tile(&self, layer: u32, x: u32, y: u32) -> u32 {
        if let Some(data) = self.tile_data.get(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                return data[idx];
            }
        }
        0
    }
    pub fn set_side(&mut self, edge: Edge, segment: u32, side_id: u32) {
        self.sides.insert((edge, segment), side_id);
    }
    pub fn get_side(&self, edge: Edge, segment: u32) -> u32 {
        self.sides.get(&(edge, segment)).copied().unwrap_or(0)
    }
    pub fn get_width(&self) -> u32 {
        self.width
    }
    pub fn get_height(&self) -> u32 {
        self.height
    }
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn get_layer_count(&self) -> u32 {
        self.layers
    }
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }
    pub fn get_width_in_segments(&self) -> u32 {
        self.width / self.segment_size
    }
    pub fn get_height_in_segments(&self) -> u32 {
        self.height / self.segment_size
    }
    pub fn get_segment_count(&self, edge: Edge) -> u32 {
        match edge {
            Edge::North | Edge::South => self.get_width_in_segments(),
            Edge::East | Edge::West => self.get_height_in_segments(),
        }
    }
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
    pub fn get_name(&self) -> &str {
        &self.name
    }
    pub fn set_weight(&mut self, weight: f32) {
        self.weight = weight;
    }
    pub fn get_weight(&self) -> f32 {
        self.weight
    }
}
#[derive(Clone)]
pub struct MapGroup {
    name: String,
    blocks: Vec<MapBlock>,
    scripts: Vec<MapScript>,
}
impl MapGroup {
    pub fn new(name: &str) -> Self {
        log_msg!(debug, MG02, "{}", name);
        Self {
            name: name.to_string(),
            blocks: Vec::new(),
            scripts: Vec::new(),
        }
    }
    pub fn add_block(&mut self, block: MapBlock) {
        log_msg!(debug, MG03);
        self.blocks.push(block);
    }
    pub fn get_block(&self, index: usize) -> Option<&MapBlock> {
        self.blocks.get(index)
    }
    pub fn get_block_mut(&mut self, index: usize) -> Option<&mut MapBlock> {
        self.blocks.get_mut(index)
    }
    pub fn get_block_count(&self) -> usize {
        self.blocks.len()
    }
    pub fn remove_block(&mut self, index: usize) {
        if index < self.blocks.len() {
            self.blocks.remove(index);
        }
    }
    pub fn add_script(&mut self, script: MapScript) {
        self.scripts.push(script);
    }
    pub fn get_script(&self, index: usize) -> Option<&MapScript> {
        self.scripts.get(index)
    }
    pub fn get_script_count(&self) -> usize {
        self.scripts.len()
    }
    pub fn get_name(&self) -> &str {
        &self.name
    }
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StepType {
    FillRandom,
    PlaceBlock,
    PlaceRandom,
    PlaceLine,
    FloodFill,
    FillArea,
    DrawPath,
    FillRect,
}
impl StepType {
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<StepType> {
        match s {
            "fill_random" => Some(StepType::FillRandom),
            "place_block" => Some(StepType::PlaceBlock),
            "place_random" => Some(StepType::PlaceRandom),
            "place_line" => Some(StepType::PlaceLine),
            "flood_fill" => Some(StepType::FloodFill),
            "fill_area" => Some(StepType::FillArea),
            "draw_path" => Some(StepType::DrawPath),
            "fill_rect" => Some(StepType::FillRect),
            _ => None,
        }
    }
    pub fn as_str(&self) -> &'static str {
        match self {
            StepType::FillRandom => "fill_random",
            StepType::PlaceBlock => "place_block",
            StepType::PlaceRandom => "place_random",
            StepType::PlaceLine => "place_line",
            StepType::FloodFill => "flood_fill",
            StepType::FillArea => "fill_area",
            StepType::DrawPath => "draw_path",
            StepType::FillRect => "fill_rect",
        }
    }
}
#[derive(Clone)]
pub struct ScriptStep {
    pub step_type: StepType,
    pub group_index: i32,
    pub block_index: i32,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
    pub count: u32,
    pub rotation: u32,
    pub mirror: bool,
    pub random_rotation: bool,
    pub random_mirror: bool,
    pub direction: u32,
    pub match_sides: bool,
    pub condition_step: i32,
    pub condition_success: bool,
    pub chance: f32,
    pub repeat_count: u32,
    pub min_count: i32,
    pub max_count: i32,
    pub size_filter_w: i32,
    pub size_filter_h: i32,
    pub tile_id: u32,
    pub path_width: u32,
    pub tile_layer: u32,
    pub zone_start_y: i32,
    pub zone_end_y: i32,
}
impl Default for ScriptStep {
    fn default() -> Self {
        Self {
            step_type: StepType::FillRandom,
            group_index: -1,
            block_index: -1,
            x: 0,
            y: 0,
            width: 0,
            height: 0,
            count: 1,
            rotation: 0,
            mirror: false,
            random_rotation: false,
            random_mirror: false,
            direction: 0,
            match_sides: true,
            condition_step: -1,
            condition_success: true,
            chance: 1.0,
            repeat_count: 1,
            min_count: -1,
            max_count: -1,
            size_filter_w: -1,
            size_filter_h: -1,
            tile_id: 0,
            path_width: 1,
            tile_layer: 0,
            zone_start_y: -1,
            zone_end_y: -1,
        }
    }
}
#[derive(Clone)]
pub struct MapScript {
    name: String,
    steps: Vec<ScriptStep>,
}
impl MapScript {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            steps: Vec::new(),
        }
    }
    pub fn add_step(&mut self, step: ScriptStep) {
        self.steps.push(step);
    }
    pub fn get_step(&self, index: usize) -> Option<&ScriptStep> {
        self.steps.get(index)
    }
    pub fn get_step_count(&self) -> usize {
        self.steps.len()
    }
    pub fn remove_step(&mut self, index: usize) {
        if index < self.steps.len() {
            self.steps.remove(index);
        }
    }
    pub fn clear_steps(&mut self) {
        self.steps.clear();
    }
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
    pub fn get_name(&self) -> &str {
        &self.name
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapOrientation {
    TopDown,
    SideView,
    Isometric,
    Hexagonal,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayerMode {
    Unified,
    Independent,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapSize {
    Small,
    Medium,
    Large,
    Custom(u32, u32),
}
impl MapSize {
    pub fn grid_dimensions(&self) -> (u32, u32) {
        match self {
            MapSize::Small => (3, 3),
            MapSize::Medium => (5, 5),
            MapSize::Large => (6, 6),
            MapSize::Custom(w, h) => (*w, *h),
        }
    }
}
#[derive(Clone)]
pub struct MapZone {
    pub name: String,
    pub start_row: u32,
    pub height: u32,
}
struct Lcg {
    state: u64,
}
impl Lcg {
    fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }
    fn next_u64(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        self.state
    }
    fn next_bounded(&mut self, bound: u32) -> u32 {
        (self.next_u64() % bound as u64) as u32
    }
}
#[derive(Clone)]
pub struct MapGen {
    grid_w: u32,
    grid_h: u32,
    segment_size: u32,
    tile_pixel_w: u32,
    tile_pixel_h: u32,
    orientation: MapOrientation,
    layer_mode: LayerMode,
    zones: Vec<MapZone>,
    last_placement_count: u32,
    seed: u64,
}
impl MapGen {
    pub fn new(size: MapSize, segment_size: u32) -> Self {
        let (grid_w, grid_h) = size.grid_dimensions();
        Self {
            grid_w,
            grid_h,
            segment_size,
            tile_pixel_w: 32,
            tile_pixel_h: 32,
            orientation: MapOrientation::TopDown,
            layer_mode: LayerMode::Unified,
            zones: Vec::new(),
            last_placement_count: 0,
            seed: 0,
        }
    }
    pub fn generate(
        &mut self,
        group: &MapGroup,
        script_index: Option<usize>,
        seed: Option<u64>,
        layer_name: &str,
    ) -> TileMap {
        let actual_seed = seed.unwrap_or(self.seed);
        self.seed = actual_seed;
        let mut rng = Lcg::new(actual_seed);
        let map_w = self.grid_w * self.segment_size;
        let map_h = self.grid_h * self.segment_size;
        let mut tilemap = TileMap::new(self.tile_pixel_w, self.tile_pixel_h, 16);
        tilemap.add_layer(layer_name, map_w, map_h);
        let ts = TileSet::new(1, 256, 16, self.tile_pixel_w, self.tile_pixel_h, 0, 0);
        tilemap.add_tileset(ts);
        let mut placement_count = 0u32;
        if let Some(si) = script_index {
            if let Some(script) = group.get_script(si) {
                for step_idx in 0..script.get_step_count() {
                    if let Some(step) = script.get_step(step_idx) {
                        if step.chance < 1.0 {
                            let roll = (rng.next_u64() % 10000) as f32 / 10000.0;
                            if roll >= step.chance {
                                continue;
                            }
                        }
                        for _ in 0..step.repeat_count {
                            match step.step_type {
                                StepType::FillRandom => {
                                    self.step_fill_random(
                                        &mut tilemap,
                                        group,
                                        step,
                                        &mut rng,
                                        map_w,
                                        map_h,
                                    );
                                    placement_count += map_w * map_h;
                                }
                                StepType::PlaceBlock => {
                                    if self.step_place_block(
                                        &mut tilemap,
                                        group,
                                        step,
                                        map_w,
                                        map_h,
                                    ) {
                                        placement_count += 1;
                                    }
                                }
                                StepType::FillRect => {
                                    self.step_fill_rect(&mut tilemap, step, map_w, map_h);
                                    placement_count += 1;
                                }
                                _ => {}
                            }
                        }
                    }
                }
            }
        }
        self.last_placement_count = placement_count;
        tilemap
    }
    pub fn generate_world(
        &mut self,
        group: &MapGroup,
        columns: u32,
        rows: u32,
        script_index: Option<usize>,
        seed: Option<u64>,
        layer_name: &str,
    ) -> TileMap {
        let actual_seed = seed.unwrap_or(self.seed);
        let region_w = self.grid_w * self.segment_size;
        let region_h = self.grid_h * self.segment_size;
        let total_w = region_w * columns;
        let total_h = region_h * rows;
        let mut tilemap = TileMap::new(self.tile_pixel_w, self.tile_pixel_h, 16);
        tilemap.add_layer(layer_name, total_w, total_h);
        let ts = TileSet::new(1, 256, 16, self.tile_pixel_w, self.tile_pixel_h, 0, 0);
        tilemap.add_tileset(ts);
        let mut total_placements = 0u32;
        for row in 0..rows {
            for col in 0..columns {
                let region_seed = actual_seed.wrapping_add((row * columns + col) as u64);
                let region = self.generate(group, script_index, Some(region_seed), "region");
                let ox = col * region_w;
                let oy = row * region_h;
                for ty in 0..region_h {
                    for tx in 0..region_w {
                        let gid = region.get_tile(0, tx, ty);
                        if gid != 0 {
                            tilemap.set_tile(0, ox + tx, oy + ty, gid);
                        }
                    }
                }
                total_placements += self.last_placement_count;
            }
        }
        self.last_placement_count = total_placements;
        tilemap
    }
    pub fn get_grid_width(&self) -> u32 {
        self.grid_w
    }
    pub fn get_grid_height(&self) -> u32 {
        self.grid_h
    }
    pub fn get_grid_dimensions(&self) -> (u32, u32) {
        (self.grid_w, self.grid_h)
    }
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }
    pub fn set_grid_dimensions(&mut self, w: u32, h: u32) {
        self.grid_w = w;
        self.grid_h = h;
    }
    pub fn set_tile_size(&mut self, w: u32, h: u32) {
        self.tile_pixel_w = w;
        self.tile_pixel_h = h;
    }
    pub fn get_tile_pixel_width(&self) -> u32 {
        self.tile_pixel_w
    }
    pub fn get_tile_pixel_height(&self) -> u32 {
        self.tile_pixel_h
    }
    pub fn get_placement_count(&self) -> u32 {
        self.last_placement_count
    }
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }
    pub fn add_zone(&mut self, name: &str, start_row: u32, height: u32) {
        self.zones.push(MapZone {
            name: name.to_string(),
            start_row,
            height,
        });
    }
    pub fn get_zone_count(&self) -> usize {
        self.zones.len()
    }
    pub fn get_zone(&self, index: usize) -> Option<&MapZone> {
        self.zones.get(index)
    }
    pub fn clear_zones(&mut self) {
        self.zones.clear();
    }
    pub fn set_layer_mode(&mut self, mode: LayerMode) {
        self.layer_mode = mode;
    }
    pub fn get_layer_mode(&self) -> LayerMode {
        self.layer_mode
    }
    fn step_fill_random(
        &self,
        tilemap: &mut TileMap,
        group: &MapGroup,
        step: &ScriptStep,
        rng: &mut Lcg,
        map_w: u32,
        map_h: u32,
    ) {
        if group.get_block_count() == 0 {
            return;
        }
        let layer = step.tile_layer as usize;
        for ty in 0..map_h {
            for tx in 0..map_w {
                let block_idx = rng.next_bounded(group.get_block_count() as u32) as usize;
                if let Some(block) = group.get_block(block_idx) {
                    if block.get_width() > 0 && block.get_height() > 0 {
                        let bx = rng.next_bounded(block.get_width());
                        let by = rng.next_bounded(block.get_height());
                        let gid = block.get_tile(0, bx, by);
                        if gid != 0 {
                            tilemap.set_tile(layer, tx, ty, gid);
                        }
                    }
                }
            }
        }
    }
    fn step_place_block(
        &self,
        tilemap: &mut TileMap,
        group: &MapGroup,
        step: &ScriptStep,
        map_w: u32,
        map_h: u32,
    ) -> bool {
        let bi = if step.block_index < 0 {
            0usize
        } else {
            step.block_index as usize
        };
        if let Some(block) = group.get_block(bi) {
            let layer = step.tile_layer as usize;
            for by in 0..block.get_height() {
                for bx in 0..block.get_width() {
                    let tx = step.x + bx;
                    let ty = step.y + by;
                    if tx < map_w && ty < map_h {
                        let gid = block.get_tile(0, bx, by);
                        if gid != 0 {
                            tilemap.set_tile(layer, tx, ty, gid);
                        }
                    }
                }
            }
            true
        } else {
            false
        }
    }
    fn step_fill_rect(&self, tilemap: &mut TileMap, step: &ScriptStep, map_w: u32, map_h: u32) {
        let layer = step.tile_layer as usize;
        let x_end = (step.x + step.width).min(map_w);
        let y_end = (step.y + step.height).min(map_h);
        for ty in step.y..y_end {
            for tx in step.x..x_end {
                tilemap.set_tile(layer, tx, ty, step.tile_id);
            }
        }
    }
}
