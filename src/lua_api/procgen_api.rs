//! `lurek.procgen` — Procedural generation tools: noise, dungeon generators, wave function collapse, heightmaps, L-systems, name generation, voronoi, biomes, and world graphs.

use super::SharedState;
use crate::procgen::biome::{BiomeClassifier, BiomeRules, BiomeType};
use crate::procgen::heightmap::Heightmap;
use crate::procgen::lsystem::LSystem;
use crate::procgen::namegen::NameGen;
use crate::procgen::noise::{simplex_noise_2d, simplex_noise_3d};
use crate::procgen::world_graph::generate_world_graph;
use crate::procgen::{
    bsp_dungeon, bsp_dungeon_with_prefabs, cellular_automata, flood_fill,
    generate_noise_map_parallel, perlin_noise_periodic, poisson_disk, rooms_dungeon,
    rooms_dungeon_with_prefabs, voronoi_diagram, BspOpts, BspPrefabStamp, CellularOpts,
    HeightmapOpts, MapGenOptions, NoiseGenerator, RoomPrefabStamp, RoomsOpts, VoronoiOpts, WfcOpts,
    WfcRules, WfcTile,
};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Lua-visible wrapper around the biome classification engine, used to assign biome types based on height, moisture, and temperature.
pub struct LuaBiomeClassifier(BiomeClassifier);
impl LuaUserData for LuaBiomeClassifier {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- classify --
        /// Classify a single point into a biome type based on its environmental parameters.
        /// @param | height | number | Elevation value (0.0–1.0) of the terrain point.
        /// @param | moisture | number | Moisture level (0.0–1.0) at the point.
        /// @param | temperature | number | Temperature value (0.0–1.0) at the point.
        /// @return | string | Biome name such as "ocean", "desert", "grassland", "taiga", etc.
        methods.add_method("classify", |_, this, (h, m, t): (f32, f32, f32)| {
            Ok(this.0.classify(h, m, t).as_str())
        });
        // -- classifyMap --
        /// Classify an entire grid of points into biome types in bulk.
        /// @param | width | integer | Grid width in cells.
        /// @param | height | integer | Grid height in cells.
        /// @param | heights | table | Flat array of height values (length = width*height).
        /// @param | moisture | table | Flat array of moisture values (length = width*height).
        /// @param | temperature | table? | Optional flat array of temperature values. If omitted, temperature is ignored.
        /// @return | string[] | Biome name strings (length = width*height).
        methods.add_method(
            "classifyMap",
            |lua, this, (width, height, ht, mt, tt): (u32, u32, LuaTable, LuaTable, Option<LuaTable>)| {
                let n = (width * height) as usize;
                let heights: Vec<f32> = (1..=n).filter_map(|i| ht.get::<_, f32>(i).ok()).collect();
                let moisture: Vec<f32> = (1..=n).filter_map(|i| mt.get::<_, f32>(i).ok()).collect();
                let temperature: Vec<f32> = if let Some(t) = tt {
                    (1..=n).filter_map(|i| t.get::<_, f32>(i).ok()).collect()
                } else {
                    Vec::new()
                };
                let biomes = this.0.classify_map(width, height, &heights, &moisture, &temperature);
                let out = lua.create_table()?;
                for (i, b) in biomes.iter().enumerate() {
                    out.set(i + 1, b.as_str())?;
                }
                Ok(out)
            },
        );
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always returns "BiomeClassifier".
        methods.add_method("type", |_, _, ()| Ok("BiomeClassifier"));
        // -- typeOf --
        /// Check whether this object matches a given type name.
        /// @param | name | string | Type name to test (e.g. "BiomeClassifier" or "Object").
        /// @return | boolean | True if the object is of the specified type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BiomeClassifier" || name == "Object")
        });
    }
}
impl BiomeRules {
    /// Builds biome classification rules from a Lua options table.
    pub fn from_lua_table(t: &LuaTable) -> LuaResult<Self> {
        let mut rules = Self::default();
        if let Ok(v) = t.get::<_, f32>("ocean_threshold") {
            rules.ocean_threshold = v;
        }
        if let Ok(v) = t.get::<_, f32>("coast_threshold") {
            rules.coast_threshold = v;
        }
        if let Ok(v) = t.get::<_, f32>("mountain_threshold") {
            rules.mountain_threshold = v;
        }
        if let Ok(v) = t.get::<_, f32>("ice_cap_threshold") {
            rules.ice_cap_threshold = v;
        }
        if let Ok(v) = t.get::<_, f32>("cold_temperature") {
            rules.cold_temperature = v;
        }
        if let Ok(v) = t.get::<_, f32>("warm_temperature") {
            rules.warm_temperature = v;
        }
        if let Ok(v) = t.get::<_, f32>("dry_moisture") {
            rules.dry_moisture = v;
        }
        if let Ok(v) = t.get::<_, f32>("wet_moisture") {
            rules.wet_moisture = v;
        }
        Ok(rules)
    }
}
impl BiomeType {
    /// Parses a biome type name into its enum variant.
    pub fn from_name(s: &str) -> Self {
        match s {
            "ocean" => Self::Ocean,
            "coast" => Self::Coast,
            "beach" => Self::Beach,
            "desert" => Self::Desert,
            "grassland" => Self::Grassland,
            "shrubland" => Self::Shrubland,
            "tropical_rainforest" => Self::TropicalRainforest,
            "temperate_forest" => Self::TemperateForest,
            "taiga" => Self::Taiga,
            "tundra" => Self::Tundra,
            "mountain" => Self::Mountain,
            "ice_cap" => Self::IceCap,
            "swamp" => Self::Swamp,
            "savanna" => Self::Savanna,
            _ => Self::Grassland,
        }
    }
}
/// Registers the `lurek.procgen` module and all its functions on the given Lua table.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- cellularAutomata --
    /// Generate a cave or organic map using cellular automata rules.
    /// @param | width | integer | Grid width in cells.
    /// @param | height | integer | Grid height in cells.
    /// @param | opts | table? | Options: fill (0.0–1.0 initial fill ratio), iterations, birth threshold, survive threshold, seed.
    /// @return | integer[] | Flat array of cell values (0=empty, 1=wall) with length width×height.
    tbl.set(
        "cellularAutomata",
        lua.create_function(|lua, (w, h, opts): (u32, u32, Option<LuaTable>)| {
            let cfg = opts
                .map(|t| CellularOpts::from_lua_table(&t))
                .transpose()?
                .unwrap_or_default();
            let data = cellular_automata(w, h, &cfg);
            let out = lua.create_table()?;
            for (i, v) in data.iter().enumerate() {
                out.set(i + 1, *v)?;
            }
            Ok(out)
        })?,
    )?;
    // -- floodFill --
    /// Flood-fill a grid from a starting cell, marking all connected cells that pass a threshold test.
    /// @param | data | table | Flat array of u8 cell values (length = width*height).
    /// @param | width | number | Grid width.
    /// @param | height | number | Grid height.
    /// @param | startX | number | Start column (0-based).
    /// @param | startY | number | Start row (0-based).
    /// @param | threshold | number? | Value threshold (default 128).
    /// @param | above | boolean? | If true, fill cells >= threshold; if false (default), fill cells < threshold.
    /// @return | integer[] | Flat array of fill values (1=filled, 0=not filled) with length width×height.
    tbl.set(
        "floodFill",
        lua.create_function(
            |lua,
             (data_tbl, w, h, sx, sy, threshold, above): (
                LuaTable,
                u32,
                u32,
                u32,
                u32,
                Option<u8>,
                Option<bool>,
            )| {
                let mut data: Vec<u8> = Vec::with_capacity((w * h) as usize);
                for v in data_tbl.sequence_values::<u8>() {
                    data.push(v?);
                }
                let result = flood_fill(
                    &data,
                    w,
                    h,
                    sx,
                    sy,
                    threshold.unwrap_or(128),
                    above.unwrap_or(false),
                );
                let out = lua.create_table()?;
                for (i, v) in result.iter().enumerate() {
                    out.set(i + 1, *v)?;
                }
                Ok(out)
            },
        )?,
    )?;
    // -- perlinNoise --
    /// Sample periodic 2D Perlin noise at a given coordinate.
    /// @param | x | number | X coordinate to sample.
    /// @param | y | number | Y coordinate to sample.
    /// @param | periodX | number | Horizontal period for tiling.
    /// @param | periodY | number | Vertical period for tiling.
    /// @return | number | Noise value in the range [-1, 1].
    tbl.set(
        "perlinNoise",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(perlin_noise_periodic(x, y, px, py))
        })?,
    )?;
    // -- poissonDisk --
    /// Generate evenly-spaced random points using Poisson disk sampling. Useful for placing trees, NPCs, or loot without clustering.
    /// @param | width | number | Area width.
    /// @param | height | number | Area height.
    /// @param | minDist | number | Minimum distance between any two points.
    /// @param | maxAttempts | integer? | Rejection attempts per active point (default 30). Higher = denser fill.
    /// @param | seed | integer? | RNG seed (default 0).
    /// @return | table | Array of {x, y} tables representing generated points.
    /// @field | x | number | X.
    /// @field | y | number | Y.
    tbl.set("poissonDisk", lua.create_function(
            |lua, (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let points = poisson_disk(w, h, min_dist, max_attempts.unwrap_or(30), seed.unwrap_or(0));
                let out = lua.create_table()?;
                for (i, (px, py)) in points.iter().enumerate() {
                    let pt = lua.create_table()?;
                    /// Performs the 'x' operation.
                    pt.set("x", *px)?;
                    /// Performs the 'y' operation.
                    pt.set("y", *py)?;
                    out.set(i + 1, pt)?;
                }
                Ok(out)
            },
        )?,
    )?;
    // -- voronoi --
    /// Compute a Voronoi diagram from a set of seed points. Returns region ownership, distance-to-nearest, and distance-to-second-nearest for each cell.
    /// @param | width | integer | Grid width.
    /// @param | height | integer | Grid height.
    /// @param | points | table | Array of {x, y} seed points.
    /// @param | opts | table? | Options: warp_scale, warp_strength, seed for domain warping.
    /// @return | integer[] | 1-based region indices (length = width*height).
    /// @return | number[] | Flat array of distances to nearest seed.
    /// @return | number[] | Flat array of distances to second-nearest seed.
    tbl.set(
        "voronoi",
        lua.create_function(
            |lua, (w, h, pts_tbl, opts_tbl): (u32, u32, LuaTable, Option<LuaTable>)| {
                let mut points: Vec<(f32, f32)> = Vec::new();
                for v in pts_tbl.sequence_values::<LuaTable>() {
                    let pt = v?;
                    let x: f32 = pt.get("x")?;
                    let y: f32 = pt.get("y")?;
                    points.push((x, y));
                }
                let vopts = opts_tbl
                    .map(|t| VoronoiOpts::from_lua_table(&t))
                    .transpose()?
                    .unwrap_or_default();
                let (regions, distances, distances2) = voronoi_diagram(w, h, &points, &vopts);
                let r_tbl = lua.create_table()?;
                let d_tbl = lua.create_table()?;
                let d2_tbl = lua.create_table()?;
                for (i, ((r, d), d2)) in regions
                    .iter()
                    .zip(distances.iter())
                    .zip(distances2.iter())
                    .enumerate()
                {
                    r_tbl.set(i + 1, *r + 1)?;
                    d_tbl.set(i + 1, *d)?;
                    d2_tbl.set(i + 1, *d2)?;
                }
                Ok((r_tbl, d_tbl, d2_tbl))
            },
        )?,
    )?;
    // -- bspDungeon --
    /// Generate a dungeon layout using Binary Space Partitioning. Produces non-overlapping rooms connected by corridors.
    /// @param | opts | table? | Options: width, height, min_size (minimum leaf size), max_depth (BSP tree depth), seed, padding.
    /// @return | table | Table with .rooms (array of {x,y,w,h}) and .corridors (array of {x1,y1,x2,y2}).
    /// @field | rooms | table | Array of room tables with x, y, w, h fields.
    /// @field | corridors | table | Array of corridor tables with x1, y1, x2, y2 fields.
    tbl.set(
        "bspDungeon",
        lua.create_function(|lua, opts: Option<LuaTable>| {
            let mut cfg = BspOpts::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, u32>("width") {
                    cfg.width = v;
                }
                if let Ok(v) = t.get::<_, u32>("height") {
                    cfg.height = v;
                }
                if let Ok(v) = t.get::<_, u32>("min_size") {
                    cfg.min_size = v;
                }
                if let Ok(v) = t.get::<_, u32>("max_depth") {
                    cfg.max_depth = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    cfg.seed = v;
                }
                if let Ok(v) = t.get::<_, u32>("padding") {
                    cfg.padding = v;
                }
            }
            let d = bsp_dungeon(&cfg);
            let rooms_tbl = lua.create_table()?;
            for (i, r) in d.rooms.iter().enumerate() {
                let rt = lua.create_table()?;
                /// Performs the 'x' operation.
                rt.set("x", r.x)?;
                /// Performs the 'y' operation.
                rt.set("y", r.y)?;
                /// Performs the 'w' operation.
                rt.set("w", r.w)?;
                /// Performs the 'h' operation.
                rt.set("h", r.h)?;
                rooms_tbl.set(i + 1, rt)?;
            }
            let corr_tbl = lua.create_table()?;
            for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                let ct = lua.create_table()?;
                /// Performs the 'x1' operation.
                ct.set("x1", x1)?;
                /// Performs the 'y1' operation.
                ct.set("y1", y1)?;
                /// Performs the 'x2' operation.
                ct.set("x2", x2)?;
                /// Performs the 'y2' operation.
                ct.set("y2", y2)?;
                corr_tbl.set(i + 1, ct)?;
            }
            let out = lua.create_table()?;
            /// Performs the 'rooms' operation.
            out.set("rooms", rooms_tbl)?;
            /// Performs the 'corridors' operation.
            out.set("corridors", corr_tbl)?;
            Ok(out)
        })?,
    )?;
    // -- bspDungeonWithPrefabs --
    /// Generate a BSP dungeon and stamp named prefab rooms into suitable leaves. Returns dungeon layout plus prefab placement info.
    /// @param | opts | table? | BSP options: width, height, min_size, max_depth, seed, padding.
    /// @param | prefabs | table | Array of prefab definitions: {name, width, height}.
    /// @return | table | Dungeon table with .rooms and .corridors.
    /// @return | table | Array of placed prefabs: {name, x, y, width, height}.
    /// @field | name | string | Name.
    /// @field | x | number | X.
    /// @field | y | number | Y.
    /// @field | width | number | Width.
    /// @field | height | number | Height.
    tbl.set(
        "bspDungeonWithPrefabs",
        lua.create_function(|lua, (opts, prefabs_tbl): (Option<LuaTable>, LuaTable)| {
            let mut cfg = BspOpts::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, u32>("width") {
                    cfg.width = v;
                }
                if let Ok(v) = t.get::<_, u32>("height") {
                    cfg.height = v;
                }
                if let Ok(v) = t.get::<_, u32>("min_size") {
                    cfg.min_size = v;
                }
                if let Ok(v) = t.get::<_, u32>("max_depth") {
                    cfg.max_depth = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    cfg.seed = v;
                }
                if let Ok(v) = t.get::<_, u32>("padding") {
                    cfg.padding = v;
                }
            }
            let mut prefabs = Vec::new();
            for v in prefabs_tbl.sequence_values::<LuaTable>() {
                let p = v?;
                let name: String = p.get("name").unwrap_or_else(|_| String::from("prefab"));
                let width: u32 = p.get("width").unwrap_or(1);
                let height: u32 = p.get("height").unwrap_or(1);
                prefabs.push(BspPrefabStamp {
                    name,
                    width,
                    height,
                });
            }
            let (d, placements) = bsp_dungeon_with_prefabs(&cfg, &prefabs);
            let rooms_tbl = lua.create_table()?;
            for (i, r) in d.rooms.iter().enumerate() {
                let rt = lua.create_table()?;
                /// Performs the 'x' operation.
                rt.set("x", r.x)?;
                /// Performs the 'y' operation.
                rt.set("y", r.y)?;
                /// Performs the 'w' operation.
                rt.set("w", r.w)?;
                /// Performs the 'h' operation.
                rt.set("h", r.h)?;
                rooms_tbl.set(i + 1, rt)?;
            }
            let corr_tbl = lua.create_table()?;
            for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                let ct = lua.create_table()?;
                /// Performs the 'x1' operation.
                ct.set("x1", x1)?;
                /// Performs the 'y1' operation.
                ct.set("y1", y1)?;
                /// Performs the 'x2' operation.
                ct.set("x2", x2)?;
                /// Performs the 'y2' operation.
                ct.set("y2", y2)?;
                corr_tbl.set(i + 1, ct)?;
            }
            let out = lua.create_table()?;
            /// Performs the 'rooms' operation.
            out.set("rooms", rooms_tbl)?;
            /// Performs the 'corridors' operation.
            out.set("corridors", corr_tbl)?;
            let p_tbl = lua.create_table()?;
            for (i, p) in placements.iter().enumerate() {
                let t = lua.create_table()?;
                /// Performs the 'name' operation.
                t.set("name", p.name.as_str())?;
                /// Performs the 'x' operation.
                t.set("x", p.x)?;
                /// Performs the 'y' operation.
                t.set("y", p.y)?;
                /// Performs the 'width' operation.
                t.set("width", p.width)?;
                /// Performs the 'height' operation.
                t.set("height", p.height)?;
                p_tbl.set(i + 1, t)?;
            }
            Ok((out, p_tbl))
        })?,
    )?;
    // -- roomsDungeon --
    /// Generate a dungeon by placing random non-overlapping rooms and connecting them with corridors. Also returns a full tile grid.
    /// @param | opts | table? | Options: width, height, max_rooms, min_room_size, max_room_size, seed.
    /// @return | table | Table with .rooms ({x,y,w,h}[]), .corridors ({x1,y1,x2,y2}[]), .grid (flat u8[]), .width, .height.
    /// @field | rooms | table | Array of room tables with x, y, w, h fields.
    /// @field | corridors | table | Array of corridor tables with x1, y1, x2, y2 fields.
    /// @field | grid | integer[] | Flat grid array of tile values.
    /// @field | width | integer | Grid width in tiles.
    /// @field | height | integer | Grid height in tiles.
    tbl.set(
        "roomsDungeon",
        lua.create_function(|lua, opts: Option<LuaTable>| {
            let mut cfg = RoomsOpts::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, u32>("width") {
                    cfg.width = v;
                }
                if let Ok(v) = t.get::<_, u32>("height") {
                    cfg.height = v;
                }
                if let Ok(v) = t.get::<_, u32>("max_rooms") {
                    cfg.max_rooms = v;
                }
                if let Ok(v) = t.get::<_, u32>("min_room_size") {
                    cfg.min_room_size = v;
                }
                if let Ok(v) = t.get::<_, u32>("max_room_size") {
                    cfg.max_room_size = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    cfg.seed = v;
                }
            }
            let d = rooms_dungeon(&cfg);
            let rooms_tbl = lua.create_table()?;
            for (i, r) in d.rooms.iter().enumerate() {
                let rt = lua.create_table()?;
                /// Performs the 'x' operation.
                rt.set("x", r.x)?;
                /// Performs the 'y' operation.
                rt.set("y", r.y)?;
                /// Performs the 'w' operation.
                rt.set("w", r.w)?;
                /// Performs the 'h' operation.
                rt.set("h", r.h)?;
                rooms_tbl.set(i + 1, rt)?;
            }
            let corr_tbl = lua.create_table()?;
            for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                let ct = lua.create_table()?;
                /// Performs the 'x1' operation.
                ct.set("x1", x1)?;
                /// Performs the 'y1' operation.
                ct.set("y1", y1)?;
                /// Performs the 'x2' operation.
                ct.set("x2", x2)?;
                /// Performs the 'y2' operation.
                ct.set("y2", y2)?;
                corr_tbl.set(i + 1, ct)?;
            }
            let grid_tbl = lua.create_table()?;
            for (i, &v) in d.grid.iter().enumerate() {
                grid_tbl.set(i + 1, v)?;
            }
            let out = lua.create_table()?;
            /// Performs the 'rooms' operation.
            out.set("rooms", rooms_tbl)?;
            /// Performs the 'corridors' operation.
            out.set("corridors", corr_tbl)?;
            /// Performs the 'grid' operation.
            out.set("grid", grid_tbl)?;
            /// Performs the 'width' operation.
            out.set("width", cfg.width)?;
            /// Performs the 'height' operation.
            out.set("height", cfg.height)?;
            Ok(out)
        })?,
    )?;
    // -- roomsDungeonWithPrefabs --
    /// Generate a rooms-based dungeon and place named prefabs into qualifying rooms. Prefabs can have custom shape masks.
    /// @param | opts | table? | Room generation options: width, height, max_rooms, min_room_size, max_room_size, seed.
    /// @param | prefabs | table | Array of prefab definitions: {name, width, height, mask (optional flat u8[])}.
    /// @param | stampValue | number? | Tile value written for prefab cells in the grid (default 3).
    /// @return | table | Dungeon table with .rooms, .corridors, .grid, .width, .height.
    /// @return | table | Array of placed prefabs: {name, x, y, width, height}.
    /// @field | name | string | Name.
    /// @field | x | number | X.
    /// @field | y | number | Y.
    /// @field | width | number | Width.
    /// @field | height | number | Height.
    tbl.set(
        "roomsDungeonWithPrefabs",
        lua.create_function(
            |lua, (opts, prefabs_tbl, stamp_value): (Option<LuaTable>, LuaTable, Option<u8>)| {
                let mut cfg = RoomsOpts::default();
                if let Some(t) = opts {
                    if let Ok(v) = t.get::<_, u32>("width") {
                        cfg.width = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("height") {
                        cfg.height = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("max_rooms") {
                        cfg.max_rooms = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("min_room_size") {
                        cfg.min_room_size = v;
                    }
                    if let Ok(v) = t.get::<_, u32>("max_room_size") {
                        cfg.max_room_size = v;
                    }
                    if let Ok(v) = t.get::<_, u64>("seed") {
                        cfg.seed = v;
                    }
                }
                let mut prefabs = Vec::new();
                for v in prefabs_tbl.sequence_values::<LuaTable>() {
                    let p = v?;
                    let name: String = p.get("name").unwrap_or_else(|_| String::from("prefab"));
                    let width: u32 = p.get("width").unwrap_or(1);
                    let height: u32 = p.get("height").unwrap_or(1);
                    let mut mask = Vec::new();
                    if let Ok(mtbl) = p.get::<_, LuaTable>("mask") {
                        for mv in mtbl.sequence_values::<u8>() {
                            mask.push(mv?);
                        }
                    }
                    prefabs.push(RoomPrefabStamp {
                        name,
                        width,
                        height,
                        mask,
                    });
                }
                let (d, placements) =
                    rooms_dungeon_with_prefabs(&cfg, &prefabs, stamp_value.unwrap_or(3));
                let rooms_tbl = lua.create_table()?;
                for (i, r) in d.rooms.iter().enumerate() {
                    let rt = lua.create_table()?;
                    /// Performs the 'x' operation.
                    rt.set("x", r.x)?;
                    /// Performs the 'y' operation.
                    rt.set("y", r.y)?;
                    /// Performs the 'w' operation.
                    rt.set("w", r.w)?;
                    /// Performs the 'h' operation.
                    rt.set("h", r.h)?;
                    rooms_tbl.set(i + 1, rt)?;
                }
                let corr_tbl = lua.create_table()?;
                for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                    let ct = lua.create_table()?;
                    /// Performs the 'x1' operation.
                    ct.set("x1", x1)?;
                    /// Performs the 'y1' operation.
                    ct.set("y1", y1)?;
                    /// Performs the 'x2' operation.
                    ct.set("x2", x2)?;
                    /// Performs the 'y2' operation.
                    ct.set("y2", y2)?;
                    corr_tbl.set(i + 1, ct)?;
                }
                let grid_tbl = lua.create_table()?;
                for (i, &v) in d.grid.iter().enumerate() {
                    grid_tbl.set(i + 1, v)?;
                }
                let out = lua.create_table()?;
                /// Performs the 'rooms' operation.
                out.set("rooms", rooms_tbl)?;
                /// Performs the 'corridors' operation.
                out.set("corridors", corr_tbl)?;
                /// Performs the 'grid' operation.
                out.set("grid", grid_tbl)?;
                /// Performs the 'width' operation.
                out.set("width", cfg.width)?;
                /// Performs the 'height' operation.
                out.set("height", cfg.height)?;
                let p_tbl = lua.create_table()?;
                for (i, p) in placements.iter().enumerate() {
                    let t = lua.create_table()?;
                    /// Performs the 'name' operation.
                    t.set("name", p.name.as_str())?;
                    /// Performs the 'x' operation.
                    t.set("x", p.x)?;
                    /// Performs the 'y' operation.
                    t.set("y", p.y)?;
                    /// Performs the 'width' operation.
                    t.set("width", p.width)?;
                    /// Performs the 'height' operation.
                    t.set("height", p.height)?;
                    p_tbl.set(i + 1, t)?;
                }
                Ok((out, p_tbl))
            },
        )?,
    )?;
    // -- heightmap --
    /// Generate a fractal heightmap using multi-octave noise with optional hydraulic erosion.
    /// @param | opts | table? | Options: width, height, scale, octaves, lacunarity, persistence, seed, erosion_passes.
    /// @return | table | Table with .cells (flat f32 array 0.0–1.0), .width, .height.
    /// @field | cells | number[] | Heightmap values.
    /// @field | width | integer | Width.
    /// @field | height | integer | Height.
    tbl.set(
        "heightmap",
        lua.create_function(|lua, opts: Option<LuaTable>| {
            let mut cfg = HeightmapOpts::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, u32>("width") {
                    cfg.width = v;
                }
                if let Ok(v) = t.get::<_, u32>("height") {
                    cfg.height = v;
                }
                if let Ok(v) = t.get::<_, f64>("scale") {
                    cfg.scale = v;
                }
                if let Ok(v) = t.get::<_, u32>("octaves") {
                    cfg.octaves = v;
                }
                if let Ok(v) = t.get::<_, f64>("lacunarity") {
                    cfg.lacunarity = v;
                }
                if let Ok(v) = t.get::<_, f64>("persistence") {
                    cfg.persistence = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    cfg.seed = v;
                }
                if let Ok(v) = t.get::<_, u32>("erosion_passes") {
                    cfg.erosion_passes = v;
                }
            }
            let hm = Heightmap::generate(&cfg);
            let out = lua.create_table()?;
            for (i, &v) in hm.cells.iter().enumerate() {
                out.set(i + 1, v)?;
            }
            let res = lua.create_table()?;
            /// Performs the 'cells' operation.
            res.set("cells", out)?;
            /// Performs the 'width' operation.
            res.set("width", hm.width)?;
            /// Performs the 'height' operation.
            res.set("height", hm.height)?;
            Ok(res)
        })?,
    )?;
    // -- heightmapFromCellular --
    /// Convert a cellular automata grid into a heightmap by distance-transforming the floor cells.
    /// @param | width | integer | Grid width.
    /// @param | height | integer | Grid height.
    /// @param | cells | table | Flat u8 array from cellularAutomata.
    /// @param | floorValue | number? | Cell value treated as open floor (default 0).
    /// @return | table | Table with .cells (flat f32 array), .width, .height.
    /// @field | cells | number[] | Distance-transformed heightmap values.
    /// @field | width | integer | Width.
    /// @field | height | integer | Height.
    tbl.set(
        "heightmapFromCellular",
        lua.create_function(
            |lua, (width, height, cells_tbl, floor_value): (u32, u32, LuaTable, Option<u8>)| {
                let mut cells = Vec::with_capacity((width * height) as usize);
                for v in cells_tbl.sequence_values::<u8>() {
                    cells.push(v?);
                }
                let hm = Heightmap::from_cellular(width, height, &cells, floor_value.unwrap_or(0));
                let out_cells = lua.create_table()?;
                for (i, &v) in hm.cells.iter().enumerate() {
                    out_cells.set(i + 1, v)?;
                }
                let res = lua.create_table()?;
                /// Performs the 'cells' operation.
                res.set("cells", out_cells)?;
                /// Performs the 'width' operation.
                res.set("width", hm.width)?;
                /// Performs the 'height' operation.
                res.set("height", hm.height)?;
                Ok(res)
            },
        )?,
    )?;
    // -- wfcGenerate --
    /// Run Wave Function Collapse to generate a grid of tile IDs satisfying adjacency constraints.
    /// @param | opts | table | Options: width, height, seed, max_attempts, tiles (array of {id, weight}), adjacencies (map of tile_id -> allowed neighbor IDs[]).
    /// @return | table | Table with .cells (flat array of tile IDs, 0 if unsolved), .width, .height.
    /// @field | cells | integer[] | Tile ID per cell.
    /// @field | width | integer | Width.
    /// @field | height | integer | Height.
    tbl.set(
        "wfcGenerate",
        lua.create_function(|lua, opts: LuaTable| {
            let width: u32 = opts.get("width").unwrap_or(16);
            let height: u32 = opts.get("height").unwrap_or(16);
            let seed: u64 = opts.get("seed").unwrap_or(0);
            let max_attempts: u32 = opts.get("max_attempts").unwrap_or(10);
            let mut tiles: Vec<WfcTile> = Vec::new();
            if let Ok(tt) = opts.get::<_, LuaTable>("tiles") {
                for v in tt.sequence_values::<LuaTable>() {
                    let t = v?;
                    let id: u32 = t.get("id").unwrap_or(0);
                    let weight: f32 = t.get("weight").unwrap_or(1.0);
                    tiles.push(WfcTile { id, weight });
                }
            }
            let mut adj_map = std::collections::HashMap::new();
            if let Ok(at) = opts.get::<_, LuaTable>("adjacencies") {
                for pair in at.pairs::<LuaValue, LuaTable>() {
                    let (k, v) = pair?;
                    let tile_id: u32 = match k {
                        LuaValue::Integer(n) => n as u32,
                        _ => continue,
                    };
                    let mut neighbours: Vec<u32> = Vec::new();
                    for nv in v.sequence_values::<u32>() {
                        neighbours.push(nv?);
                    }
                    adj_map.insert(tile_id, neighbours);
                }
            }
            let wfc_opts = WfcOpts {
                width,
                height,
                tiles,
                rules: WfcRules {
                    adjacencies: adj_map,
                },
                seed,
                max_attempts,
            };
            let grid = crate::procgen::wfc_generate(&wfc_opts);
            let out = lua.create_table()?;
            for (i, c) in grid.cells.iter().enumerate() {
                out.set(i + 1, c.unwrap_or(0))?;
            }
            let res = lua.create_table()?;
            /// Performs the 'cells' operation.
            res.set("cells", out)?;
            /// Performs the 'width' operation.
            res.set("width", grid.width)?;
            /// Performs the 'height' operation.
            res.set("height", grid.height)?;
            Ok(res)
        })?,
    )?;
    // -- lsystem --
    /// Expand an L-system grammar and return the resulting string. Useful for generating branching structures like trees, rivers, or cave networks.
    /// @param | opts | table | Options: axiom (starting string), iterations (expansion count), rules (table mapping single-char keys to replacement strings).
    /// @return | string | The fully expanded L-system string.
    tbl.set(
        "lsystem",
        lua.create_function(|_, opts: LuaTable| {
            let axiom: String = opts.get("axiom").unwrap_or_else(|_| String::from("F"));
            let iterations: u32 = opts.get("iterations").unwrap_or(3);
            let rules: Vec<(char, &'static str)> = Vec::new();
            let rule_strings: Vec<(char, String)> = opts
                .get::<_, Option<LuaTable>>("rules")
                .unwrap_or(None)
                .map(|rt| {
                    let mut v = Vec::new();
                    for (k, val) in rt.pairs::<LuaValue, String>().flatten() {
                        if let LuaValue::String(s) = k {
                            if let Some(c) = s.to_str().ok().and_then(|ss| ss.chars().next()) {
                                v.push((c, val));
                            }
                        }
                    }
                    v
                })
                .unwrap_or_default();
            let _ = &rules;
            let sys = LSystem::new_from_pairs(&axiom, &rule_strings, iterations);
            Ok(sys.generate())
        })?,
    )?;
    // -- lsystemSegments --
    /// Expand an L-system and interpret the result as turtle-graphics commands, returning line segments.
    /// @param | opts | table | L-system options: axiom, iterations, rules.
    /// @param | angle | number? | Turn angle in degrees (default 25).
    /// @param | step | number? | Forward step length (default 1.0).
    /// @return | table | Array of segment tables {x1, y1, x2, y2}.
    /// @field | x1 | number | X1.
    /// @field | y1 | number | Y1.
    /// @field | x2 | number | X2.
    /// @field | y2 | number | Y2.
    tbl.set(
        "lsystemSegments",
        lua.create_function(
            |lua, (opts, angle_deg, step): (LuaTable, Option<f32>, Option<f32>)| {
                let axiom: String = opts.get("axiom").unwrap_or_else(|_| String::from("F"));
                let iterations: u32 = opts.get("iterations").unwrap_or(3);
                let rule_strings: Vec<(char, String)> = opts
                    .get::<_, Option<LuaTable>>("rules")
                    .unwrap_or(None)
                    .map(|rt| {
                        let mut v = Vec::new();
                        for (k, val) in rt.pairs::<LuaValue, String>().flatten() {
                            if let LuaValue::String(s) = k {
                                if let Some(c) = s.to_str().ok().and_then(|ss| ss.chars().next()) {
                                    v.push((c, val));
                                }
                            }
                        }
                        v
                    })
                    .unwrap_or_default();
                let sys = LSystem::new_from_pairs(&axiom, &rule_strings, iterations);
                let segs = sys.to_segments(angle_deg.unwrap_or(25.0), step.unwrap_or(1.0));
                let out = lua.create_table()?;
                for (i, (x1, y1, x2, y2)) in segs.iter().enumerate() {
                    let st = lua.create_table()?;
                    /// Performs the 'x1' operation.
                    st.set("x1", *x1)?;
                    /// Performs the 'y1' operation.
                    st.set("y1", *y1)?;
                    /// Performs the 'x2' operation.
                    st.set("x2", *x2)?;
                    /// Performs the 'y2' operation.
                    st.set("y2", *y2)?;
                    out.set(i + 1, st)?;
                }
                Ok(out)
            },
        )?,
    )?;
    // -- generateName --
    /// Generate a single random name based on a Markov chain trained from sample names. Great for NPC names, place names, or item names.
    /// @param | samples | table | Array of example name strings to learn from.
    /// @param | minLen | number? | Minimum output length in characters (default 3).
    /// @param | maxLen | number? | Maximum output length in characters (default 10).
    /// @param | seed | number? | RNG seed (default 0).
    /// @return | string | A generated name.
    tbl.set(
        "generateName",
        lua.create_function(
            |_,
             (samples_tbl, min_len, max_len, seed): (
                LuaTable,
                Option<usize>,
                Option<usize>,
                Option<u64>,
            )| {
                let mut samples: Vec<String> = Vec::new();
                for v in samples_tbl.sequence_values::<String>() {
                    samples.push(v?);
                }
                let refs: Vec<&str> = samples.iter().map(|s| s.as_str()).collect();
                let mut gen = NameGen::new(&refs, 2, seed.unwrap_or(0));
                Ok(gen.generate(min_len.unwrap_or(3), max_len.unwrap_or(10)))
            },
        )?,
    )?;
    // -- generateNames --
    /// Generate multiple random names in one call using Markov chains trained from sample data.
    /// @param | samples | table | Array of example name strings to learn from.
    /// @param | count | number | Number of names to generate.
    /// @param | minLen | number? | Minimum output length (default 3).
    /// @param | maxLen | number? | Maximum output length (default 10).
    /// @param | seed | number? | RNG seed (default 0).
    /// @return | string[] | Generated name strings.
    tbl.set(
        "generateNames",
        lua.create_function(
            |lua,
             (samples_tbl, n, min_len, max_len, seed): (
                LuaTable,
                usize,
                Option<usize>,
                Option<usize>,
                Option<u64>,
            )| {
                let mut samples: Vec<String> = Vec::new();
                for v in samples_tbl.sequence_values::<String>() {
                    samples.push(v?);
                }
                let refs: Vec<&str> = samples.iter().map(|s| s.as_str()).collect();
                let mut gen = NameGen::new(&refs, 2, seed.unwrap_or(0));
                let names = gen.generate_n(n, min_len.unwrap_or(3), max_len.unwrap_or(10));
                let out = lua.create_table()?;
                for (i, name) in names.iter().enumerate() {
                    out.set(i + 1, name.clone())?;
                }
                Ok(out)
            },
        )?,
    )?;
    // -- worldGraph --
    /// Generate a connected world graph with named regions and weighted edges. Useful for overworld maps, trade routes, or quest connectivity.
    /// @param | width | number | World area width.
    /// @param | height | number | World area height.
    /// @param | regionCount | integer | Number of regions to place.
    /// @param | seed | integer? | RNG seed (default 0).
    /// @return | table | Table with regions and edges arrays.
    /// @field | regions | table | Array of region tables, each with id (integer), name (string), x (number), y (number), tags (string[]).
    /// @field | edges | table | Array of edge tables, each with from (integer), to (integer), cost (number), bidirectional (boolean).
    tbl.set(
        "worldGraph",
        lua.create_function(
            |lua, (width, height, region_count, seed): (f32, f32, u32, Option<u64>)| {
                let wg = generate_world_graph(width, height, region_count, seed.unwrap_or(0));
                let regions_tbl = lua.create_table()?;
                for (i, r) in wg.regions.iter().enumerate() {
                    let rt = lua.create_table()?;
                    /// Performs the 'id' operation.
                    rt.set("id", r.id)?;
                    /// Performs the 'name' operation.
                    rt.set("name", r.name.clone())?;
                    /// Performs the 'x' operation.
                    rt.set("x", r.x)?;
                    /// Performs the 'y' operation.
                    rt.set("y", r.y)?;
                    let tags_tbl = lua.create_table()?;
                    for (j, tag) in r.tags.iter().enumerate() {
                        tags_tbl.set(j + 1, tag.clone())?;
                    }
                    /// Performs the 'tags' operation.
                    rt.set("tags", tags_tbl)?;
                    regions_tbl.set(i + 1, rt)?;
                }
                let edges_tbl = lua.create_table()?;
                for (i, e) in wg.edges.iter().enumerate() {
                    let et = lua.create_table()?;
                    /// Performs the 'from' operation.
                    et.set("from", e.from)?;
                    /// Performs the 'to' operation.
                    et.set("to", e.to)?;
                    /// Performs the 'cost' operation.
                    et.set("cost", e.cost)?;
                    /// Performs the 'bidirectional' operation.
                    et.set("bidirectional", e.bidirectional)?;
                    edges_tbl.set(i + 1, et)?;
                }
                let out = lua.create_table()?;
                /// Performs the 'regions' operation.
                out.set("regions", regions_tbl)?;
                /// Performs the 'edges' operation.
                out.set("edges", edges_tbl)?;
                Ok(out)
            },
        )?,
    )?;
    // -- noiseMap --
    /// Generate a 2D noise map with configurable scale, octaves, and offsets. Runs on a single thread.
    /// @param | width | integer | Map width in cells.
    /// @param | height | integer | Map height in cells.
    /// @param | opts | table? | Options: scale_x, scale_y, octaves, lacunarity, persistence, offset_x, offset_y, seed.
    /// @return | number[] | F64 noise values (length = width*height).
    tbl.set(
        "noiseMap",
        lua.create_function(|lua, (width, height, opts): (u32, u32, Option<LuaTable>)| {
            let mut cfg = MapGenOptions::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, f64>("scale_x") {
                    cfg.scale_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("scale_y") {
                    cfg.scale_y = v;
                }
                if let Ok(v) = t.get::<_, u32>("octaves") {
                    cfg.octaves = v;
                }
                if let Ok(v) = t.get::<_, f64>("lacunarity") {
                    cfg.lacunarity = v;
                }
                if let Ok(v) = t.get::<_, f64>("persistence") {
                    cfg.persistence = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_x") {
                    cfg.offset_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_y") {
                    cfg.offset_y = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    let g = NoiseGenerator::new(v);
                    let map = g.generate_map(width, height, &cfg);
                    let out = lua.create_table()?;
                    for (i, &val) in map.iter().enumerate() {
                        out.set(i + 1, val)?;
                    }
                    return Ok(out);
                }
            }
            let g = NoiseGenerator::new(0);
            let map = g.generate_map(width, height, &cfg);
            let out = lua.create_table()?;
            for (i, &val) in map.iter().enumerate() {
                out.set(i + 1, val)?;
            }
            Ok(out)
        })?,
    )?;
    // -- noiseMapParallel --
    /// Generate a 2D noise map using multiple threads for faster computation on large maps. Uses seed 0.
    /// @param | width | integer | Map width in cells.
    /// @param | height | integer | Map height in cells.
    /// @param | opts | table? | Options: scale_x, scale_y, octaves, lacunarity, persistence, offset_x, offset_y.
    /// @return | number[] | F64 noise values (length = width*height).
    tbl.set(
        "noiseMapParallel",
        lua.create_function(|lua, (width, height, opts): (u32, u32, Option<LuaTable>)| {
            let mut cfg = MapGenOptions::default();
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, f64>("scale_x") {
                    cfg.scale_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("scale_y") {
                    cfg.scale_y = v;
                }
                if let Ok(v) = t.get::<_, u32>("octaves") {
                    cfg.octaves = v;
                }
                if let Ok(v) = t.get::<_, f64>("lacunarity") {
                    cfg.lacunarity = v;
                }
                if let Ok(v) = t.get::<_, f64>("persistence") {
                    cfg.persistence = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_x") {
                    cfg.offset_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_y") {
                    cfg.offset_y = v;
                }
            }
            let map = generate_noise_map_parallel(width, height, &cfg);
            let out = lua.create_table()?;
            for (i, &val) in map.iter().enumerate() {
                out.set(i + 1, val)?;
            }
            Ok(out)
        })?,
    )?;
    // -- noiseMapParallelSeeded --
    /// Generate a 2D noise map using multiple threads with a specific seed for reproducible results.
    /// @param | width | integer | Map width in cells.
    /// @param | height | integer | Map height in cells.
    /// @param | opts | table? | Options: scale_x, scale_y, octaves, lacunarity, persistence, offset_x, offset_y, seed.
    /// @return | number[] | F64 noise values (length = width*height).
    tbl.set(
        "noiseMapParallelSeeded",
        lua.create_function(|lua, (width, height, opts): (u32, u32, Option<LuaTable>)| {
            let mut cfg = MapGenOptions::default();
            let mut seed = 0_u64;
            if let Some(t) = opts {
                if let Ok(v) = t.get::<_, f64>("scale_x") {
                    cfg.scale_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("scale_y") {
                    cfg.scale_y = v;
                }
                if let Ok(v) = t.get::<_, u32>("octaves") {
                    cfg.octaves = v;
                }
                if let Ok(v) = t.get::<_, f64>("lacunarity") {
                    cfg.lacunarity = v;
                }
                if let Ok(v) = t.get::<_, f64>("persistence") {
                    cfg.persistence = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_x") {
                    cfg.offset_x = v;
                }
                if let Ok(v) = t.get::<_, f64>("offset_y") {
                    cfg.offset_y = v;
                }
                if let Ok(v) = t.get::<_, u64>("seed") {
                    seed = v;
                }
            }
            let g = NoiseGenerator::new(seed);
            let map = g.generate_map_parallel(width, height, &cfg);
            let out = lua.create_table()?;
            for (i, &val) in map.iter().enumerate() {
                out.set(i + 1, val)?;
            }
            Ok(out)
        })?,
    )?;
    // -- simplex2d --
    /// Sample 2D simplex noise at a point. Returns a value roughly in [-1, 1].
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @return | number | Simplex noise value.
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y): (f32, f32)| Ok(simplex_noise_2d(x, y)))?,
    )?;
    // -- simplex3d --
    /// Sample 3D simplex noise at a point. The third axis can be used for animation or layering.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | z | number | Z coordinate (often time or layer index).
    /// @return | number | Simplex noise value.
    tbl.set(
        "simplex3d",
        lua.create_function(|_, (x, y, z): (f32, f32, f32)| Ok(simplex_noise_3d(x, y, z)))?,
    )?;
    // -- newBiomeClassifier --
    /// Create a BiomeClassifier object with custom threshold rules for mapping height/moisture/temperature to biome types.
    /// @param | opts | table? | Optional rules: ocean_threshold, coast_threshold, mountain_threshold, ice_cap_threshold, cold_temperature, warm_temperature, dry_moisture, wet_moisture.
    /// @return | BiomeClassifier | A classifier object with :classify() and :classifyMap() methods.
    tbl.set(
        "newBiomeClassifier",
        lua.create_function(|lua, opts: Option<LuaTable>| {
            let rules = opts
                .map(|t| BiomeRules::from_lua_table(&t))
                .transpose()?
                .unwrap_or_default();
            lua.create_userdata(LuaBiomeClassifier(BiomeClassifier::new(rules)))
        })?,
    )?;
    // -- biomeColor --
    /// Get the default RGBA display color for a biome type name. Useful for minimap or debug visualization.
    /// @param | name | string | Biome name (e.g. "ocean", "desert", "taiga").
    /// @return | number | Red component (0–255).
    /// @return | number | Green component (0–255).
    /// @return | number | Blue component (0–255).
    /// @return | number | Alpha component (0–255).
    tbl.set(
        "biomeColor",
        lua.create_function(|_, name: String| {
            let bt = BiomeType::from_name(&name);
            let [r, g, b, a] = bt.color_rgba();
            Ok((r, g, b, a))
        })?,
    )?;
    /// Performs the 'procgen' operation.
    luna.set("procgen", tbl)?;
    Ok(())
}
impl CellularOpts {
    /// Builds cellular-generation options from a Lua options table.
    pub fn from_lua_table(t: &LuaTable) -> LuaResult<Self> {
        let mut opts = Self::default();
        if let Ok(v) = t.get::<_, f32>("fill") {
            opts.fill = v;
        }
        if let Ok(v) = t.get::<_, u32>("iterations") {
            opts.iterations = v;
        }
        if let Ok(v) = t.get::<_, u32>("birth") {
            opts.birth = v;
        }
        if let Ok(v) = t.get::<_, u32>("survive") {
            opts.survive = v;
        }
        if let Ok(v) = t.get::<_, u64>("seed") {
            opts.seed = v;
        }
        Ok(opts)
    }
}
impl VoronoiOpts {
    /// Builds Voronoi-generation options from a Lua options table.
    pub fn from_lua_table(t: &LuaTable) -> LuaResult<Self> {
        let mut opts = Self::default();
        if let Ok(v) = t.get::<_, f32>("warp_scale") {
            opts.warp_scale = v;
        }
        if let Ok(v) = t.get::<_, f32>("warp_strength") {
            opts.warp_strength = v;
        }
        if let Ok(v) = t.get::<_, u64>("seed") {
            opts.seed = v;
        }
        Ok(opts)
    }
}
