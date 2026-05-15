//! - Procedural tile-map generation driven by reusable block stamps and scripted steps.
//! - `MapBlock` stores rectangular tile grids with edge side-IDs for neighbour matching.
//! - `MapGroup` collects blocks and `MapScript`s into named generation palettes.
//! - `ScriptStep` parameterises operations: fill, place, scatter, flood-fill, path drawing.
//! - `MapGen` orchestrates generation using seeded LCG RNG, zones, orientation, and layer modes.
//! - Supports single-region and multi-region world tiling with independent seeds per region.
//! - Deterministic output: same seed + script always produces the same map.
//! - Grid presets (`MapSize`) and horizontal zone bands constrain placement areas.
//! - Orientation tags (top-down, side-view, isometric, hexagonal) stored for downstream renderers.
//! - Layer modes control whether blocks share a unified layer or write independently.

use super::tilemap::TileMap;
use super::tileset::TileSet;
use crate::log_msg;
use crate::runtime::log_messages::{MG01, MG02, MG03};
use std::collections::HashMap;

/// Cardinal edge of a `MapBlock`, used as a side-matching key.
#[derive(Debug, Clone, Copy, Hash, PartialEq, Eq)]
pub enum Edge {
    /// Top edge of the block.
    North,
    /// Right edge of the block.
    East,
    /// Bottom edge of the block.
    South,
    /// Left edge of the block.
    West,
}
impl Edge {
    /// Parse `s` ("north", "east", "south", "west") into an `Edge`; returns `None` for unknown strings.
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
    /// Return the lowercase string representation of this edge.
    pub fn as_str(&self) -> &'static str {
        match self {
            Edge::North => "north",
            Edge::East => "east",
            Edge::South => "south",
            Edge::West => "west",
        }
    }
}
/// A reusable tile stamp: a rectangular grid of tile GIDs with edge side-IDs for matching.
#[derive(Clone)]
pub struct MapBlock {
    /// Block width in tiles.
    width: u32,
    /// Block height in tiles.
    height: u32,
    /// Number of tile layers.
    layers: u32,
    /// Segment size used for side-segment calculations.
    segment_size: u32,
    /// Human-readable identifier for this block.
    name: String,
    /// Selection weight for random placement; higher values increase frequency.
    weight: f32,
    /// Per-layer flat tile-GID arrays.
    tile_data: Vec<Vec<u32>>,
    /// Edge segment ID map keyed by `(Edge, segment_index)`.
    sides: HashMap<(Edge, u32), u32>,
}
impl MapBlock {
    /// Create an empty `MapBlock` with `width`×`height` tiles, `layers` layers, and the given `segment_size`.
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
    /// Write `gid` at `(x, y)` in `layer`; no-op for out-of-bounds or missing layer.
    pub fn set_tile(&mut self, layer: u32, x: u32, y: u32, gid: u32) {
        if let Some(data) = self.tile_data.get_mut(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                data[idx] = gid;
            }
        }
    }
    /// Return the GID at `(x, y)` in `layer`; returns 0 for out-of-bounds or missing layer.
    pub fn get_tile(&self, layer: u32, x: u32, y: u32) -> u32 {
        if let Some(data) = self.tile_data.get(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                return data[idx];
            }
        }
        0
    }
    /// Assign side ID `side_id` to `segment` on the given `edge`.
    pub fn set_side(&mut self, edge: Edge, segment: u32, side_id: u32) {
        self.sides.insert((edge, segment), side_id);
    }

    /// Return the side ID for `segment` on `edge`; returns 0 when unset.
    pub fn get_side(&self, edge: Edge, segment: u32) -> u32 {
        self.sides.get(&(edge, segment)).copied().unwrap_or(0)
    }

    /// Return the block width in tiles.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Return the block height in tiles.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Return `(width, height)` in tiles.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Return the number of tile layers.
    pub fn get_layer_count(&self) -> u32 {
        self.layers
    }

    /// Return the segment size used for side subdivision.
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }

    /// Return the number of segments on the north/south edges.
    pub fn get_width_in_segments(&self) -> u32 {
        self.width / self.segment_size
    }

    /// Return the number of segments on the east/west edges.
    pub fn get_height_in_segments(&self) -> u32 {
        self.height / self.segment_size
    }

    /// Return the segment count for the given `edge`.
    pub fn get_segment_count(&self, edge: Edge) -> u32 {
        match edge {
            Edge::North | Edge::South => self.get_width_in_segments(),
            Edge::East | Edge::West => self.get_height_in_segments(),
        }
    }

    /// Set the block name. This function is part of the public API.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }

    /// Return the block name. This function is part of the public API.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Set the random selection weight.
    pub fn set_weight(&mut self, weight: f32) {
        self.weight = weight;
    }

    /// Return the random selection weight.
    pub fn get_weight(&self) -> f32 {
        self.weight
    }
}
/// A named collection of `MapBlock`s and `MapScript`s that the generator pulls from.
#[derive(Clone)]
pub struct MapGroup {
    /// Human-readable identifier.
    name: String,
    /// Registered tile block stamps.
    blocks: Vec<MapBlock>,
    /// Registered generation scripts.
    scripts: Vec<MapScript>,
}
impl MapGroup {
    /// Create an empty `MapGroup` with the given `name`.
    pub fn new(name: &str) -> Self {
        log_msg!(debug, MG02, "{}", name);
        Self {
            name: name.to_string(),
            blocks: Vec::new(),
            scripts: Vec::new(),
        }
    }
    /// Append `block` to this group.
    pub fn add_block(&mut self, block: MapBlock) {
        log_msg!(debug, MG03);
        self.blocks.push(block);
    }
    /// Return a shared reference to the block at `index`, or `None`.
    pub fn get_block(&self, index: usize) -> Option<&MapBlock> {
        self.blocks.get(index)
    }

    /// Return a mutable reference to the block at `index`, or `None`.
    pub fn get_block_mut(&mut self, index: usize) -> Option<&mut MapBlock> {
        self.blocks.get_mut(index)
    }

    /// Return the number of blocks in this group.
    pub fn get_block_count(&self) -> usize {
        self.blocks.len()
    }

    /// Remove the block at `index`; no-op for out-of-bounds.
    pub fn remove_block(&mut self, index: usize) {
        if index < self.blocks.len() {
            self.blocks.remove(index);
        }
    }

    /// Append `script` to this group.
    pub fn add_script(&mut self, script: MapScript) {
        self.scripts.push(script);
    }

    /// Return a shared reference to the script at `index`, or `None`.
    pub fn get_script(&self, index: usize) -> Option<&MapScript> {
        self.scripts.get(index)
    }

    /// Return the number of scripts in this group.
    pub fn get_script_count(&self) -> usize {
        self.scripts.len()
    }

    /// Return the group name. This function is part of the public API.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Set the group name. This function is part of the public API.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
}
/// Generation operation type applied by a `ScriptStep`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StepType {
    /// Fill every tile with a random GID from the group.
    FillRandom,
    /// Place a specific block at a fixed position.
    PlaceBlock,
    /// Place a randomly chosen block at a random position.
    PlaceRandom,
    /// Place blocks along a straight line.
    PlaceLine,
    /// Flood-fill an area from a seed position.
    FloodFill,
    /// Fill an area with a pattern.
    FillArea,
    /// Draw a path through the map.
    DrawPath,
    /// Fill a rectangular region with a tile ID.
    FillRect,
}
impl StepType {
    /// Parse a step-type name string; returns `None` for unrecognised values.
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
    /// Return the string representation of this step type.
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
/// A single parameterised step in a `MapScript`.
#[derive(Clone)]
pub struct ScriptStep {
    /// The operation to perform.
    pub step_type: StepType,
    /// Index into the group's block list; -1 means random.
    pub group_index: i32,
    /// Index into the group's block list for the specific block; -1 means pick by weight.
    pub block_index: i32,
    /// Target X tile coordinate for placement operations.
    pub x: u32,
    /// Target Y tile coordinate for placement operations.
    pub y: u32,
    /// Width of the operation area in tiles.
    pub width: u32,
    /// Height of the operation area in tiles.
    pub height: u32,
    /// Number of placements to attempt for scatter operations.
    pub count: u32,
    /// Fixed rotation for the placed block (0–3 in 90° steps).
    pub rotation: u32,
    /// Whether to mirror the placed block horizontally.
    pub mirror: bool,
    /// Whether rotation is randomised each repeat.
    pub random_rotation: bool,
    /// Whether mirror is randomised each repeat.
    pub random_mirror: bool,
    /// Direction index used by `DrawPath` and `PlaceLine`.
    pub direction: u32,
    /// When `true`, edges must match adjacent placed blocks.
    pub match_sides: bool,
    /// Index of a prior step that must have succeeded (-1 = no condition).
    pub condition_step: i32,
    /// Whether the condition step must have succeeded (`true`) or failed (`false`).
    pub condition_success: bool,
    /// Probability in `[0.0, 1.0]` that this step executes.
    pub chance: f32,
    /// How many times this step is repeated per generation.
    pub repeat_count: u32,
    /// Minimum placement count required; -1 means no minimum.
    pub min_count: i32,
    /// Maximum placement count allowed; -1 means no maximum.
    pub max_count: i32,
    /// Width filter for block selection; -1 means any width.
    pub size_filter_w: i32,
    /// Height filter for block selection; -1 means any height.
    pub size_filter_h: i32,
    /// Tile GID used by `FillRect` and similar tile-painting steps.
    pub tile_id: u32,
    /// Number of tiles wide for `DrawPath`.
    pub path_width: u32,
    /// Layer index in the tile map to write GIDs into.
    pub tile_layer: u32,
    /// Start row for zone-constrained placement; -1 means full map.
    pub zone_start_y: i32,
    /// End row for zone-constrained placement; -1 means full map.
    pub zone_end_y: i32,
}
/// Default `ScriptStep`: `FillRandom`, group/block indices -1, chance 1.0, repeat 1.
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
/// An ordered sequence of `ScriptStep`s that drives one generation pass.
#[derive(Clone)]
pub struct MapScript {
    /// Human-readable identifier.
    name: String,
    /// Ordered list of generation steps.
    steps: Vec<ScriptStep>,
}
impl MapScript {
    /// Create an empty `MapScript` with the given `name`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            steps: Vec::new(),
        }
    }
    /// Append `step` to this script.
    pub fn add_step(&mut self, step: ScriptStep) {
        self.steps.push(step);
    }

    /// Return a shared reference to the step at `index`, or `None`.
    pub fn get_step(&self, index: usize) -> Option<&ScriptStep> {
        self.steps.get(index)
    }

    /// Return the number of steps in this script.
    pub fn get_step_count(&self) -> usize {
        self.steps.len()
    }

    /// Remove the step at `index`; no-op for out-of-bounds.
    pub fn remove_step(&mut self, index: usize) {
        if index < self.steps.len() {
            self.steps.remove(index);
        }
    }

    /// Remove all steps from this script.
    pub fn clear_steps(&mut self) {
        self.steps.clear();
    }

    /// Set the script name. This function is part of the public API.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }

    /// Return the script name. This function is part of the public API.
    pub fn get_name(&self) -> &str {
        &self.name
    }
}
/// Projection / rendering orientation for the generated map.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapOrientation {
    /// Standard top-down tile map.
    TopDown,
    /// Side-scrolling platform view.
    SideView,
    /// Isometric 2:1 diamond projection.
    Isometric,
    /// Hexagonal grid map.
    Hexagonal,
}

/// How layers are assigned when generating multi-layer maps.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayerMode {
    /// All blocks write to a single unified layer.
    Unified,
    /// Each block manages its own layer independently.
    Independent,
}
/// Named grid size preset or explicit tile dimensions.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapSize {
    /// 3×3 grid of segments.
    Small,
    /// 5×5 grid of segments.
    Medium,
    /// 6×6 grid of segments.
    Large,
    /// Custom `(width, height)` grid of segments.
    Custom(u32, u32),
}
impl MapSize {
    /// Return the `(grid_w, grid_h)` segment-grid dimensions for this size preset.
    pub fn grid_dimensions(&self) -> (u32, u32) {
        match self {
            MapSize::Small => (3, 3),
            MapSize::Medium => (5, 5),
            MapSize::Large => (6, 6),
            MapSize::Custom(w, h) => (*w, *h),
        }
    }
}
/// A horizontal zone band used to constrain generation to a row range.
#[derive(Clone)]
pub struct MapZone {
    /// Zone identifier.
    pub name: String,
    /// First tile row of this zone.
    pub start_row: u32,
    /// Height in tile rows.
    pub height: u32,
}

/// Minimal LCG pseudo-random number generator for deterministic map generation.
struct Lcg {
    /// Current generator state.
    state: u64,
}
impl Lcg {
    /// Seed the generator; adds 1 to avoid a zero state.
    fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }
    /// Advance the state and return the next 64-bit value.
    fn next_u64(&mut self) -> u64 {
        self.state = self
            .state
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        self.state
    }
    /// Return a value uniformly distributed in `[0, bound)`.
    fn next_bounded(&mut self, bound: u32) -> u32 {
        (self.next_u64() % bound as u64) as u32
    }
}

/// Procedural map generator: combines `MapGroup` blocks and scripts with seeded `Lcg` RNG.
#[derive(Clone)]
pub struct MapGen {
    /// Grid width in block-sized segments.
    grid_w: u32,
    /// Grid height in block-sized segments.
    grid_h: u32,
    /// Segment dimension shared with the blocks used.
    segment_size: u32,
    /// Pixel width of a single tile for the output `TileMap`.
    tile_pixel_w: u32,
    /// Pixel height of a single tile for the output `TileMap`.
    tile_pixel_h: u32,
    /// Projection orientation tag stored for callers.
    orientation: MapOrientation,
    /// Layer assignment strategy.
    layer_mode: LayerMode,
    /// Horizontal zone bands used to constrain step placement.
    zones: Vec<MapZone>,
    /// Tile placement count from the most recent `generate` or `generate_world` call.
    last_placement_count: u32,
    /// RNG seed carried between calls.
    seed: u64,
}
impl MapGen {
    /// Create a `MapGen` for the given `size` preset and `segment_size`.
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
    /// Generate a single-region `TileMap` from `group` using `script_index`, `seed`, and `layer_name`.
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
    /// Generate a `columns`×`rows` world map by tiling independently seeded regions.
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
    /// Return the grid width in segments.
    pub fn get_grid_width(&self) -> u32 {
        self.grid_w
    }

    /// Return the grid height in segments.
    pub fn get_grid_height(&self) -> u32 {
        self.grid_h
    }

    /// Return `(grid_w, grid_h)` in segments.
    pub fn get_grid_dimensions(&self) -> (u32, u32) {
        (self.grid_w, self.grid_h)
    }

    /// Return the segment size shared with the group blocks.
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }

    /// Set the grid dimensions in segments.
    pub fn set_grid_dimensions(&mut self, w: u32, h: u32) {
        self.grid_w = w;
        self.grid_h = h;
    }

    /// Set the pixel dimensions of a single tile.
    pub fn set_tile_size(&mut self, w: u32, h: u32) {
        self.tile_pixel_w = w;
        self.tile_pixel_h = h;
    }

    /// Return the pixel width of one tile.
    pub fn get_tile_pixel_width(&self) -> u32 {
        self.tile_pixel_w
    }

    /// Return the pixel height of one tile.
    pub fn get_tile_pixel_height(&self) -> u32 {
        self.tile_pixel_h
    }

    /// Return the placement count from the most recent `generate` or `generate_world` call.
    pub fn get_placement_count(&self) -> u32 {
        self.last_placement_count
    }

    /// Set the rendering orientation tag.
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }

    /// Return the current rendering orientation.
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }

    /// Append a zone band covering `[start_row, start_row + height)`.
    pub fn add_zone(&mut self, name: &str, start_row: u32, height: u32) {
        self.zones.push(MapZone {
            name: name.to_string(),
            start_row,
            height,
        });
    }

    /// Return the number of defined zones.
    pub fn get_zone_count(&self) -> usize {
        self.zones.len()
    }

    /// Return a shared reference to the zone at `index`, or `None`.
    pub fn get_zone(&self, index: usize) -> Option<&MapZone> {
        self.zones.get(index)
    }

    /// Remove all zones. This function is part of the public API.
    pub fn clear_zones(&mut self) {
        self.zones.clear();
    }

    /// Set the layer mode. This function is part of the public API.
    pub fn set_layer_mode(&mut self, mode: LayerMode) {
        self.layer_mode = mode;
    }

    /// Return the current layer mode.
    pub fn get_layer_mode(&self) -> LayerMode {
        self.layer_mode
    }
    /// Fill every tile in the map with a GID sampled randomly from `group`'s blocks.
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
    /// Stamp the block referenced by `step` at `(step.x, step.y)`; returns `true` on success.
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
    /// Fill the rectangle defined by `step` with `step.tile_id`.
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
