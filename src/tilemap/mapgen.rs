//! Procedural map generation — MapBlock, MapGroup, MapScript, MapGen.
//!
//! This module is part of Lurek2D's `tilemap` subsystem and provides the implementation
//! details for mapgen-related operations and data management.
//! Key types exported from this module: `Edge`, `MapBlock`, `MapGroup`, `StepType`, `ScriptStep`.
//! Primary functions: `from_str()`, `as_str()`, `new()`, `set_tile()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;

use super::tilemap::TileMap;
use super::tileset::TileSet;
use crate::runtime::log_messages::{MG01, MG02, MG03};
use crate::log_msg;

/// Cardinal edge direction for block-segment connectivity.
///
/// # Variants
/// - `North` — North variant.
/// - `East` — East variant.
/// - `South` — South variant.
/// - `West` — West variant.
#[derive(Debug, Clone, Copy, Hash, PartialEq, Eq)]
pub enum Edge {
    /// Top edge.
    North,
    /// Right edge.
    East,
    /// Bottom edge.
    South,
    /// Left edge.
    West,
}

impl Edge {
    /// Parses an edge from a lowercase string (`"north"`, `"east"`, `"south"`, `"west"`).
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Edge>`.
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

    /// Returns the lowercase string representation of this edge.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Edge::North => "north",
            Edge::East => "east",
            Edge::South => "south",
            Edge::West => "west",
        }
    }
}

/// A prefab grid of tiles that can be stamped into a generated map.
///
/// Contains multi-layer tile data and per-segment edge connection IDs.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `layers` — `u32`.
/// - `segment_size` — `u32`.
/// - `name` — `String`.
/// - `weight` — `f32`.
/// - `tile_data` — `Vec<Vec<u32>>`.
/// - `sides` — `HashMap<(Edge`.
#[derive(Clone)]
pub struct MapBlock {
    width: u32,
    height: u32,
    layers: u32,
    segment_size: u32,
    name: String,
    weight: f32,
    /// Per-layer GID arrays (row-major, size = width×height per layer).
    tile_data: Vec<Vec<u32>>,
    /// (edge, segment_idx) → side connection ID.
    sides: HashMap<(Edge, u32), u32>,
}

impl MapBlock {
    /// Creates a new map block with the given dimensions.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `layers` — `u32`.
    /// - `segment_size` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Tile data is initialized to all zeros (empty) across `layers` layers.
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

    /// Sets the GID of a tile at `(x, y)` on the given layer (0-based).
    ///
    /// # Parameters
    /// - `layer` — `u32`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `gid` — `u32`.
    pub fn set_tile(&mut self, layer: u32, x: u32, y: u32, gid: u32) {
        if let Some(data) = self.tile_data.get_mut(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                data[idx] = gid;
            }
        }
    }

    /// Returns the GID of the tile at `(x, y)` on the given layer. Returns 0 if out of bounds.
    ///
    /// # Parameters
    /// - `layer` — `u32`.
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile(&self, layer: u32, x: u32, y: u32) -> u32 {
        if let Some(data) = self.tile_data.get(layer as usize) {
            if x < self.width && y < self.height {
                let idx = (y * self.width + x) as usize;
                return data[idx];
            }
        }
        0
    }

    /// Sets the side connection ID for a segment on a given edge.
    ///
    /// # Parameters
    /// - `edge` — `Edge`.
    /// - `segment` — `u32`.
    /// - `side_id` — `u32`.
    pub fn set_side(&mut self, edge: Edge, segment: u32, side_id: u32) {
        self.sides.insert((edge, segment), side_id);
    }

    /// Returns the side connection ID for a segment on a given edge, or 0 if not set.
    ///
    /// # Parameters
    /// - `edge` — `Edge`.
    /// - `segment` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_side(&self, edge: Edge, segment: u32) -> u32 {
        self.sides.get(&(edge, segment)).copied().unwrap_or(0)
    }

    /// Returns the block width in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Returns the block height in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Returns the block dimensions as `(width, height)` in tiles.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Returns the number of layers in this block.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_layer_count(&self) -> u32 {
        self.layers
    }

    /// Returns the segment size in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }

    /// Returns the number of segments along the width.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width_in_segments(&self) -> u32 {
        self.width / self.segment_size
    }

    /// Returns the number of segments along the height.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height_in_segments(&self) -> u32 {
        self.height / self.segment_size
    }

    /// Returns the segment count for a given edge direction.
    ///
    /// # Parameters
    /// - `edge` — `Edge`.
    ///
    /// # Returns
    /// `u32`.
    ///
    /// North/South = width in segments, East/West = height in segments.
    pub fn get_segment_count(&self, edge: Edge) -> u32 {
        match edge {
            Edge::North | Edge::South => self.get_width_in_segments(),
            Edge::East | Edge::West => self.get_height_in_segments(),
        }
    }

    /// Sets the human-readable name of this block.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }

    /// Returns the name of this block. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Sets the placement weight (default 1.0).
    ///
    /// # Parameters
    /// - `weight` — `f32`.
    pub fn set_weight(&mut self, weight: f32) {
        self.weight = weight;
    }

    /// Returns the placement weight. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_weight(&self) -> f32 {
        self.weight
    }
}

/// A biome-like container holding [`MapBlock`] prefabs and [`MapScript`] generators.
///
/// # Fields
/// - `name` — `String`.
/// - `blocks` — `Vec<MapBlock>`.
/// - `scripts` — `Vec<MapScript>`.
#[derive(Clone)]
pub struct MapGroup {
    name: String,
    blocks: Vec<MapBlock>,
    scripts: Vec<MapScript>,
}

impl MapGroup {
    /// Creates a new empty map group. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        log_msg!(debug, MG02, "{}", name);
        Self {
            name: name.to_string(),
            blocks: Vec::new(),
            scripts: Vec::new(),
        }
    }

    /// Adds a block to this group. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `block` — `MapBlock`.
    pub fn add_block(&mut self, block: MapBlock) {
        log_msg!(debug, MG03);
        self.blocks.push(block);
    }

    /// Returns a reference to a block by index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&MapBlock>`.
    pub fn get_block(&self, index: usize) -> Option<&MapBlock> {
        self.blocks.get(index)
    }

    /// Returns a mutable reference to a block by index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&mut MapBlock>`.
    pub fn get_block_mut(&mut self, index: usize) -> Option<&mut MapBlock> {
        self.blocks.get_mut(index)
    }

    /// Returns the number of blocks in this group.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_block_count(&self) -> usize {
        self.blocks.len()
    }

    /// Removes a block by index if in bounds.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    pub fn remove_block(&mut self, index: usize) {
        if index < self.blocks.len() {
            self.blocks.remove(index);
        }
    }

    /// Adds a script to this group. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `script` — `MapScript`.
    pub fn add_script(&mut self, script: MapScript) {
        self.scripts.push(script);
    }

    /// Returns a reference to a script by index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&MapScript>`.
    pub fn get_script(&self, index: usize) -> Option<&MapScript> {
        self.scripts.get(index)
    }

    /// Returns the number of scripts in this group.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_script_count(&self) -> usize {
        self.scripts.len()
    }

    /// Returns the name of this group. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Sets the name of this group. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
}

/// The type of operation a [`ScriptStep`] performs.
///
/// # Variants
/// - `FillRandom` — FillRandom variant.
/// - `PlaceBlock` — PlaceBlock variant.
/// - `PlaceRandom` — PlaceRandom variant.
/// - `PlaceLine` — PlaceLine variant.
/// - `FloodFill` — FloodFill variant.
/// - `FillArea` — FillArea variant.
/// - `DrawPath` — DrawPath variant.
/// - `FillRect` — FillRect variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StepType {
    /// Fill with random tiles from available blocks.
    FillRandom,
    /// Stamp a specific block into the map.
    PlaceBlock,
    /// Place a random block.
    PlaceRandom,
    /// Place blocks in a line.
    PlaceLine,
    /// Flood-fill from a point.
    FloodFill,
    /// Fill a rectangular area.
    FillArea,
    /// Draw a path between points.
    DrawPath,
    /// Fill a rectangle with a tile.
    FillRect,
}

impl StepType {
    /// Parses a step type from a string identifier.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<StepType>`.
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

    /// Returns the string identifier for this step type.
    ///
    /// # Returns
    /// `&'static str`.
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

/// A single step in a [`MapScript`] with rich configuration.
///
/// # Fields
/// - `step_type` — `StepType`.
/// - `group_index` — `i32`.
/// - `block_index` — `i32`.
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `count` — `u32`.
/// - `rotation` — `u32`.
/// - `mirror` — `bool`.
/// - `random_rotation` — `bool`.
/// - `random_mirror` — `bool`.
/// - `direction` — `u32`.
/// - `match_sides` — `bool`.
/// - `condition_step` — `i32`.
/// - `condition_success` — `bool`.
/// - `chance` — `f32`.
/// - `repeat_count` — `u32`.
/// - `min_count` — `i32`.
/// - `max_count` — `i32`.
/// - `size_filter_w` — `i32`.
/// - `size_filter_h` — `i32`.
/// - `tile_id` — `u32`.
/// - `path_width` — `u32`.
/// - `tile_layer` — `u32`.
/// - `zone_start_y` — `i32`.
/// - `zone_end_y` — `i32`.
///
/// # Fields
#[derive(Clone)]
pub struct ScriptStep {
    /// Type of generation step.
    pub step_type: StepType,
    /// Group index (-1 = all).
    pub group_index: i32,
    /// Block index (-1 = random).
    pub block_index: i32,
    /// X position (tiles).
    pub x: u32,
    /// Y position (tiles).
    pub y: u32,
    /// Width (tiles).
    pub width: u32,
    /// Height (tiles).
    pub height: u32,
    /// Repeat count.
    pub count: u32,
    /// Rotation (0–3, 90° increments).
    pub rotation: u32,
    /// Whether to mirror the block.
    pub mirror: bool,
    /// Enable random rotation.
    pub random_rotation: bool,
    /// Enable random mirroring.
    pub random_mirror: bool,
    /// Direction: 0 = horizontal, 1 = vertical.
    pub direction: u32,
    /// Whether to match side connection IDs.
    pub match_sides: bool,
    /// Condition step index (-1 = unconditional).
    pub condition_step: i32,
    /// Whether the condition must have succeeded.
    pub condition_success: bool,
    /// Chance of execution (0.0–1.0).
    pub chance: f32,
    /// Number of times to repeat this step.
    pub repeat_count: u32,
    /// Minimum count (-1 = no limit).
    pub min_count: i32,
    /// Maximum count (-1 = no limit).
    pub max_count: i32,
    /// Width size filter (-1 = ignore).
    pub size_filter_w: i32,
    /// Height size filter (-1 = ignore).
    pub size_filter_h: i32,
    /// Tile GID to use.
    pub tile_id: u32,
    /// Path width in tiles.
    pub path_width: u32,
    /// Target tile layer.
    pub tile_layer: u32,
    /// Zone start row (-1 = ignore).
    pub zone_start_y: i32,
    /// Zone end row (-1 = ignore).
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

/// A named sequence of [`ScriptStep`]s that drives procedural generation.
///
/// # Fields
/// - `name` — `String`.
/// - `steps` — `Vec<ScriptStep>`.
#[derive(Clone)]
pub struct MapScript {
    name: String,
    steps: Vec<ScriptStep>,
}

impl MapScript {
    /// Creates a new empty map script. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            steps: Vec::new(),
        }
    }

    /// Appends a step to this script. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `step` — `ScriptStep`.
    pub fn add_step(&mut self, step: ScriptStep) {
        self.steps.push(step);
    }

    /// Returns a reference to a step by index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&ScriptStep>`.
    pub fn get_step(&self, index: usize) -> Option<&ScriptStep> {
        self.steps.get(index)
    }

    /// Returns the number of steps. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_step_count(&self) -> usize {
        self.steps.len()
    }

    /// Removes a step by index if in bounds.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    pub fn remove_step(&mut self, index: usize) {
        if index < self.steps.len() {
            self.steps.remove(index);
        }
    }

    /// Removes all steps. After this call the container is in the same state as immediately after construction.
    pub fn clear_steps(&mut self) {
        self.steps.clear();
    }

    /// Sets the name of this script. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }

    /// Returns the name of this script. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_name(&self) -> &str {
        &self.name
    }
}

/// Map orientation for visual layout hints.
///
/// # Variants
/// - `TopDown` — TopDown variant.
/// - `SideView` — SideView variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapOrientation {
    /// Standard top-down orthogonal.
    TopDown,
    /// Side-scrolling view.
    SideView,
}

/// How layers are managed during generation.
///
/// # Variants
/// - `Unified` — Unified variant.
/// - `Independent` — Independent variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayerMode {
    /// All block layers merge into a single tilemap layer.
    Unified,
    /// Each block layer maps to its own tilemap layer.
    Independent,
}

/// Predefined map size presets expressed in segment-grid units.
///
/// # Variants
/// - `Small` — Small variant.
/// - `Medium` — Medium variant.
/// - `Large` — Large variant.
/// - `Custom` — Custom variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MapSize {
    /// 3×3 segments.
    Small,
    /// 5×5 segments.
    Medium,
    /// 6×6 segments.
    Large,
    /// Custom grid dimensions.
    Custom(u32, u32),
}

impl MapSize {
    /// Returns the `(columns, rows)` grid dimensions.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn grid_dimensions(&self) -> (u32, u32) {
        match self {
            MapSize::Small => (3, 3),
            MapSize::Medium => (5, 5),
            MapSize::Large => (6, 6),
            MapSize::Custom(w, h) => (*w, *h),
        }
    }
}

/// A named horizontal zone within a generated map.
///
/// # Fields
/// - `name` — `String`.
/// - `start_row` — `u32`.
/// - `height` — `u32`.
#[derive(Clone)]
pub struct MapZone {
    /// Zone name.
    pub name: String,
    /// Start row (0-based).
    pub start_row: u32,
    /// Height in rows.
    pub height: u32,
}

/// Simple LCG pseudo-random number generator for deterministic map generation.
struct Lcg {
    state: u64,
}

impl Lcg {
    /// Creates a new LCG seeded with the given value.
    fn new(seed: u64) -> Self {
        Self {
            state: seed.wrapping_add(1),
        }
    }

    /// Returns the next pseudo-random `u64`.
    fn next_u64(&mut self) -> u64 {
        // LCG constants from Numerical Recipes
        self.state = self
            .state
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        self.state
    }

    /// Returns a value in `[0, bound)`. Panics if `bound == 0`.
    fn next_bounded(&mut self, bound: u32) -> u32 {
        (self.next_u64() % bound as u64) as u32
    }
}

/// Top-level procedural map generator. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Produces a [`TileMap`] by stamping [`MapBlock`] prefabs according to
/// [`MapScript`] steps, using deterministic randomness.
///
/// # Fields
/// - `grid_w` — `u32`.
/// - `grid_h` — `u32`.
/// - `segment_size` — `u32`.
/// - `tile_pixel_w` — `u32`.
/// - `tile_pixel_h` — `u32`.
/// - `orientation` — `MapOrientation`.
/// - `layer_mode` — `LayerMode`.
/// - `zones` — `Vec<MapZone>`.
/// - `last_placement_count` — `u32`.
/// - `seed` — `u64`.
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
    /// Creates a new map generator from a size preset and segment size.
    ///
    /// # Parameters
    /// - `size` — `MapSize`.
    /// - `segment_size` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Tile pixel dimensions default to 32×32.
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

    /// Generates a [`TileMap`] from a [`MapGroup`] using an optional script and seed.
    ///
    /// # Parameters
    /// - `group` — `&MapGroup`.
    /// - `script_index` — `Option<usize>`.
    /// - `seed` — `Option<u64>`.
    /// - `layer_name` — `&str` — name for the generated layer (e.g. `"main"`).
    ///
    /// # Returns
    /// `TileMap`.
    ///
    /// The map width = `grid_w * segment_size`, height = `grid_h * segment_size`.
    /// Creates one layer named `layer_name` and applies script steps. Currently implements:
    /// - [`StepType::FillRandom`]: fills tiles with random GIDs from available blocks.
    /// - [`StepType::PlaceBlock`]: stamps a specific block's tiles into the map.
    /// - [`StepType::FillRect`]: fills a rectangle with `tile_id`.
    /// - Other step types: no-op (stub).
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

        // Add a default empty tileset
        let ts = TileSet::new(1, 256, 16, self.tile_pixel_w, self.tile_pixel_h, 0, 0);
        tilemap.add_tileset(ts);

        let mut placement_count = 0u32;

        // Execute script steps if a script is selected
        if let Some(si) = script_index {
            if let Some(script) = group.get_script(si) {
                for step_idx in 0..script.get_step_count() {
                    if let Some(step) = script.get_step(step_idx) {
                        // Check chance
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
                                _ => {
                                    // Stub: other step types not yet implemented
                                }
                            }
                        }
                    }
                }
            }
        }

        self.last_placement_count = placement_count;
        tilemap
    }

    /// Generates a larger map by tiling multiple generation regions.
    ///
    /// # Parameters
    /// - `group` — `&MapGroup`.
    /// - `columns` — `u32`.
    /// - `rows` — `u32`.
    /// - `script_index` — `Option<usize>`.
    /// - `seed` — `Option<u64>`.
    /// - `layer_name` — `&str` — name for the generated layer (e.g. `"main"`).
    ///
    /// # Returns
    /// `TileMap`.
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

                // Copy region tiles into the world map
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

    /// Returns the grid width in segments. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_grid_width(&self) -> u32 {
        self.grid_w
    }

    /// Returns the grid height in segments. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_grid_height(&self) -> u32 {
        self.grid_h
    }

    /// Returns the grid dimensions as `(width, height)` in segments.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_grid_dimensions(&self) -> (u32, u32) {
        (self.grid_w, self.grid_h)
    }

    /// Returns the segment size in tiles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_segment_size(&self) -> u32 {
        self.segment_size
    }

    /// Sets the grid dimensions (width and height in segments).
    ///
    /// # Parameters
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    pub fn set_grid_dimensions(&mut self, w: u32, h: u32) {
        self.grid_w = w;
        self.grid_h = h;
    }

    /// Sets the tile pixel dimensions. Replaces the current tile size value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    pub fn set_tile_size(&mut self, w: u32, h: u32) {
        self.tile_pixel_w = w;
        self.tile_pixel_h = h;
    }

    /// Returns the tile pixel width. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_pixel_width(&self) -> u32 {
        self.tile_pixel_w
    }

    /// Returns the tile pixel height. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_tile_pixel_height(&self) -> u32 {
        self.tile_pixel_h
    }

    /// Returns the number of placements made during the last generation.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_placement_count(&self) -> u32 {
        self.last_placement_count
    }

    /// Sets the map orientation. Replaces the current orientation value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `orientation` — `MapOrientation`.
    pub fn set_orientation(&mut self, orientation: MapOrientation) {
        self.orientation = orientation;
    }

    /// Returns the current map orientation. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `MapOrientation`.
    pub fn get_orientation(&self) -> MapOrientation {
        self.orientation
    }

    /// Adds a named horizontal zone. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `start_row` — `u32`.
    /// - `height` — `u32`.
    pub fn add_zone(&mut self, name: &str, start_row: u32, height: u32) {
        self.zones.push(MapZone {
            name: name.to_string(),
            start_row,
            height,
        });
    }

    /// Returns the number of zones. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_zone_count(&self) -> usize {
        self.zones.len()
    }

    /// Returns a zone by index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&MapZone>`.
    pub fn get_zone(&self, index: usize) -> Option<&MapZone> {
        self.zones.get(index)
    }

    /// Removes all zones. After this call the container is in the same state as immediately after construction.
    pub fn clear_zones(&mut self) {
        self.zones.clear();
    }

    /// Sets the layer mode. Replaces the current layer mode value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `mode` — `LayerMode`.
    pub fn set_layer_mode(&mut self, mode: LayerMode) {
        self.layer_mode = mode;
    }

    /// Returns the current layer mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `LayerMode`.
    pub fn get_layer_mode(&self) -> LayerMode {
        self.layer_mode
    }

    // ------------------------------------------------------------------
    // Step implementations
    // ------------------------------------------------------------------

    /// Fill the map layer with random GIDs from available blocks.
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

    /// Stamp a specific block into the map at the step's (x, y) position.
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

    /// Fill a rectangle with the step's tile_id.
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn edge_from_str() {
        assert_eq!(Edge::from_str("north"), Some(Edge::North));
        assert_eq!(Edge::from_str("east"), Some(Edge::East));
        assert_eq!(Edge::from_str("south"), Some(Edge::South));
        assert_eq!(Edge::from_str("west"), Some(Edge::West));
        assert_eq!(Edge::from_str("invalid"), None);
    }

    #[test]
    fn edge_as_str() {
        assert_eq!(Edge::North.as_str(), "north");
        assert_eq!(Edge::East.as_str(), "east");
        assert_eq!(Edge::South.as_str(), "south");
        assert_eq!(Edge::West.as_str(), "west");
    }

    #[test]
    fn map_block_segment_dimensions() {
        let block = MapBlock::new(8, 6, 2, 2);
        assert_eq!(block.get_width(), 8);
        assert_eq!(block.get_height(), 6);
        assert_eq!(block.get_dimensions(), (8, 6));
        assert_eq!(block.get_layer_count(), 2);
        assert_eq!(block.get_segment_size(), 2);
        assert_eq!(block.get_width_in_segments(), 4);
        assert_eq!(block.get_height_in_segments(), 3);
        assert_eq!(block.get_segment_count(Edge::North), 4);
        assert_eq!(block.get_segment_count(Edge::South), 4);
        assert_eq!(block.get_segment_count(Edge::East), 3);
        assert_eq!(block.get_segment_count(Edge::West), 3);
    }

    #[test]
    fn map_block_tile_access() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        block.set_tile(0, 1, 2, 42);
        assert_eq!(block.get_tile(0, 1, 2), 42);
        assert_eq!(block.get_tile(0, 0, 0), 0); // default
        assert_eq!(block.get_tile(1, 0, 0), 0); // invalid layer
    }

    #[test]
    fn map_block_sides() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        block.set_side(Edge::North, 0, 5);
        block.set_side(Edge::North, 1, 7);
        assert_eq!(block.get_side(Edge::North, 0), 5);
        assert_eq!(block.get_side(Edge::North, 1), 7);
        assert_eq!(block.get_side(Edge::South, 0), 0); // not set
    }

    #[test]
    fn map_block_name_weight() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        assert!((block.get_weight() - 1.0).abs() < 1e-5);
        block.set_name("room");
        assert_eq!(block.get_name(), "room");
        block.set_weight(2.5);
        assert!((block.get_weight() - 2.5).abs() < 1e-5);
    }

    #[test]
    fn map_group_add_remove() {
        let mut group = MapGroup::new("biome1");
        assert_eq!(group.get_name(), "biome1");
        assert_eq!(group.get_block_count(), 0);

        group.add_block(MapBlock::new(4, 4, 1, 2));
        group.add_block(MapBlock::new(6, 6, 1, 3));
        assert_eq!(group.get_block_count(), 2);

        group.remove_block(0);
        assert_eq!(group.get_block_count(), 1);

        // Out-of-bounds remove is a no-op
        group.remove_block(99);
        assert_eq!(group.get_block_count(), 1);
    }

    #[test]
    fn map_group_scripts() {
        let mut group = MapGroup::new("test");
        group.add_script(MapScript::new("gen1"));
        assert_eq!(group.get_script_count(), 1);
        assert_eq!(group.get_script(0).expect("script 0 exists").get_name(), "gen1");
    }

    #[test]
    fn map_group_set_name() {
        let mut group = MapGroup::new("old");
        group.set_name("new");
        assert_eq!(group.get_name(), "new");
    }

    #[test]
    fn step_type_roundtrip() {
        let types = [
            StepType::FillRandom,
            StepType::PlaceBlock,
            StepType::PlaceRandom,
            StepType::PlaceLine,
            StepType::FloodFill,
            StepType::FillArea,
            StepType::DrawPath,
            StepType::FillRect,
        ];
        for st in &types {
            let s = st.as_str();
            assert_eq!(StepType::from_str(s), Some(*st));
        }
        assert_eq!(StepType::from_str("invalid"), None);
    }

    #[test]
    fn script_step_default() {
        let step = ScriptStep::default();
        assert_eq!(step.step_type, StepType::FillRandom);
        assert!(step.match_sides);
        assert!((step.chance - 1.0).abs() < 1e-5);
        assert_eq!(step.repeat_count, 1);
        assert_eq!(step.condition_step, -1);
        assert_eq!(step.group_index, -1);
        assert_eq!(step.block_index, -1);
    }

    #[test]
    fn map_script_step_management() {
        let mut script = MapScript::new("test_script");
        assert_eq!(script.get_name(), "test_script");
        assert_eq!(script.get_step_count(), 0);

        script.add_step(ScriptStep::default());
        script.add_step(ScriptStep {
            step_type: StepType::PlaceBlock,
            ..ScriptStep::default()
        });
        assert_eq!(script.get_step_count(), 2);
        assert_eq!(script.get_step(0).expect("step 0 exists").step_type, StepType::FillRandom);
        assert_eq!(script.get_step(1).expect("step 1 exists").step_type, StepType::PlaceBlock);

        script.remove_step(0);
        assert_eq!(script.get_step_count(), 1);
        assert_eq!(script.get_step(0).expect("step 0 exists").step_type, StepType::PlaceBlock);

        script.clear_steps();
        assert_eq!(script.get_step_count(), 0);
    }

    #[test]
    fn map_script_set_name() {
        let mut script = MapScript::new("old");
        script.set_name("new");
        assert_eq!(script.get_name(), "new");
    }

    #[test]
    fn map_size_presets() {
        assert_eq!(MapSize::Small.grid_dimensions(), (3, 3));
        assert_eq!(MapSize::Medium.grid_dimensions(), (5, 5));
        assert_eq!(MapSize::Large.grid_dimensions(), (6, 6));
        assert_eq!(MapSize::Custom(10, 20).grid_dimensions(), (10, 20));
    }

    #[test]
    fn map_gen_creation() {
        let gen = MapGen::new(MapSize::Small, 4);
        assert_eq!(gen.get_grid_width(), 3);
        assert_eq!(gen.get_grid_height(), 3);
        assert_eq!(gen.get_grid_dimensions(), (3, 3));
        assert_eq!(gen.get_segment_size(), 4);
        assert_eq!(gen.get_tile_pixel_width(), 32);
        assert_eq!(gen.get_tile_pixel_height(), 32);
        assert_eq!(gen.get_orientation(), MapOrientation::TopDown);
        assert_eq!(gen.get_layer_mode(), LayerMode::Unified);
    }

    #[test]
    fn map_gen_medium_large() {
        let med = MapGen::new(MapSize::Medium, 4);
        assert_eq!(med.get_grid_dimensions(), (5, 5));

        let large = MapGen::new(MapSize::Large, 4);
        assert_eq!(large.get_grid_dimensions(), (6, 6));
    }

    #[test]
    fn map_gen_tile_size() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        gen.set_tile_size(16, 16);
        assert_eq!(gen.get_tile_pixel_width(), 16);
        assert_eq!(gen.get_tile_pixel_height(), 16);
    }

    #[test]
    fn map_gen_orientation() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        gen.set_orientation(MapOrientation::SideView);
        assert_eq!(gen.get_orientation(), MapOrientation::SideView);
    }

    #[test]
    fn map_gen_layer_mode() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        gen.set_layer_mode(LayerMode::Independent);
        assert_eq!(gen.get_layer_mode(), LayerMode::Independent);
    }

    #[test]
    fn map_gen_zones() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        assert_eq!(gen.get_zone_count(), 0);

        gen.add_zone("forest", 0, 3);
        gen.add_zone("desert", 3, 3);
        assert_eq!(gen.get_zone_count(), 2);

        let z = gen.get_zone(0).expect("zone 0 exists");
        assert_eq!(z.name, "forest");
        assert_eq!(z.start_row, 0);
        assert_eq!(z.height, 3);

        gen.clear_zones();
        assert_eq!(gen.get_zone_count(), 0);
    }

    #[test]
    fn map_gen_generate_empty_group() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        let group = MapGroup::new("empty");
        let tilemap = gen.generate(&group, None, Some(42), "main");
        // Map should exist with correct dimensions: 3*4 = 12 x 12
        assert_eq!(tilemap.get_layer_count(), 1);
    }

    #[test]
    fn map_gen_generate_with_fill_rect() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        let mut group = MapGroup::new("test");
        let mut script = MapScript::new("gen");
        script.add_step(ScriptStep {
            step_type: StepType::FillRect,
            tile_id: 5,
            x: 0,
            y: 0,
            width: 3,
            height: 3,
            ..ScriptStep::default()
        });
        group.add_script(script);

        let tilemap = gen.generate(&group, Some(0), Some(42), "main");
        // Tile at (0,0) should be 5
        assert_eq!(tilemap.get_tile(0, 0, 0), 5);
        // Tile at (2,2) should be 5
        assert_eq!(tilemap.get_tile(0, 2, 2), 5);
        // Tile at (3,3) should be 0 (outside rect)
        assert_eq!(tilemap.get_tile(0, 3, 3), 0);
    }

    #[test]
    fn map_gen_generate_with_place_block() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        let mut group = MapGroup::new("test");

        let mut block = MapBlock::new(2, 2, 1, 2);
        block.set_tile(0, 0, 0, 10);
        block.set_tile(0, 1, 0, 11);
        block.set_tile(0, 0, 1, 12);
        block.set_tile(0, 1, 1, 13);
        group.add_block(block);

        let mut script = MapScript::new("gen");
        script.add_step(ScriptStep {
            step_type: StepType::PlaceBlock,
            block_index: 0,
            x: 1,
            y: 1,
            ..ScriptStep::default()
        });
        group.add_script(script);

        let tilemap = gen.generate(&group, Some(0), Some(42), "main");
        assert_eq!(tilemap.get_tile(0, 1, 1), 10);
        assert_eq!(tilemap.get_tile(0, 2, 1), 11);
        assert_eq!(tilemap.get_tile(0, 1, 2), 12);
        assert_eq!(tilemap.get_tile(0, 2, 2), 13);
    }

    #[test]
    fn map_gen_placement_count() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        let group = MapGroup::new("empty");
        gen.generate(&group, None, Some(1), "main");
        assert_eq!(gen.get_placement_count(), 0);
    }

    #[test]
    fn map_gen_generate_world() {
        let mut gen = MapGen::new(MapSize::Small, 2);
        let mut group = MapGroup::new("test");
        let mut script = MapScript::new("gen");
        script.add_step(ScriptStep {
            step_type: StepType::FillRect,
            tile_id: 1,
            x: 0,
            y: 0,
            width: 6,
            height: 6,
            ..ScriptStep::default()
        });
        group.add_script(script);

        let tilemap = gen.generate_world(&group, 2, 2, Some(0), Some(99), "main");
        // World should be 2 columns × 2 rows of 3*2=6 tile regions → 12×12 tiles
        assert_eq!(tilemap.get_layer_count(), 1);
        // Tile (0,0) should be filled
        assert_eq!(tilemap.get_tile(0, 0, 0), 1);
    }

    #[test]
    fn map_orientation_eq() {
        assert_eq!(MapOrientation::TopDown, MapOrientation::TopDown);
        assert_ne!(MapOrientation::TopDown, MapOrientation::SideView);
    }

    #[test]
    fn layer_mode_eq() {
        assert_eq!(LayerMode::Unified, LayerMode::Unified);
        assert_ne!(LayerMode::Unified, LayerMode::Independent);
    }
}
