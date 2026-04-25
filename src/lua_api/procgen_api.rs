//! `lurek.procgen` — Stateless procedural generation utilities.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::procgen::heightmap::Heightmap;
use crate::procgen::lsystem::LSystem;
use crate::procgen::namegen::NameGen;
use crate::procgen::noise::{simplex_noise_2d, simplex_noise_3d};
use crate::procgen::world_graph::generate_world_graph;
use crate::procgen::{
    bsp_dungeon, cellular_automata, flood_fill, generate_noise_map_parallel, perlin_noise_periodic,
    poisson_disk, rooms_dungeon, voronoi_diagram, BspOpts, CellularOpts, HeightmapOpts,
    MapGenOptions, NoiseGenerator, RoomsOpts, VoronoiOpts, WfcOpts, WfcRules, WfcTile,
};

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.procgen` API table with the Lua VM.
///
/// @param lua &Lua
/// @param luna &LuaTable
/// @param _state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- cellularAutomata --
    /// Generates a cave-like map using cellular automata.
    /// @param w integer
    /// @param h integer
    /// @param opts table?
    /// @return table
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
    /// BFS flood fill on a flat grid of bytes.
    /// @param data table
    /// @param w integer
    /// @param h integer
    /// @param sx integer
    /// @param sy integer
    /// @param threshold integer?
    /// @param above boolean?
    /// @return table
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
    /// Evaluates periodic Perlin noise at a point.
    /// @param x number
    /// @param y number
    /// @param px number
    /// @param py number
    /// @return number
    tbl.set(
        "perlinNoise",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(perlin_noise_periodic(x, y, px, py))
        })?,
    )?;

    // -- poissonDisk --
    /// Generates Poisson disk sample points using Bridson's algorithm.
    /// @param w number
    /// @param h number
    /// @param min_dist number
    /// @param max_attempts integer?
    /// @param seed integer?
    /// @return table
    tbl.set(
        "poissonDisk",
        lua.create_function(
            |lua, (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let points = poisson_disk(w, h, min_dist, max_attempts.unwrap_or(30), seed.unwrap_or(0));
                let out = lua.create_table()?;
                for (i, (px, py)) in points.iter().enumerate() {
                    let pt = lua.create_table()?;
                    pt.set("x", *px)?;
                    pt.set("y", *py)?;
                    out.set(i + 1, pt)?;
                }
                Ok(out)
            },
        )?,
    )?;

    // -- voronoi --
    /// Generates a Voronoi diagram for a set of seed points.
    /// @return table
    /// @param w integer
    /// @param h integer
    /// @param pts table
    /// @param opts table?
    /// table, table, table
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
    /// Generates a dungeon using Binary Space Partitioning.
    /// @param opts table?
    /// @return table
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
                rt.set("x", r.x)?;
                rt.set("y", r.y)?;
                rt.set("w", r.w)?;
                rt.set("h", r.h)?;
                rooms_tbl.set(i + 1, rt)?;
            }
            let corr_tbl = lua.create_table()?;
            for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                let ct = lua.create_table()?;
                ct.set("x1", x1)?;
                ct.set("y1", y1)?;
                ct.set("x2", x2)?;
                ct.set("y2", y2)?;
                corr_tbl.set(i + 1, ct)?;
            }
            let out = lua.create_table()?;
            out.set("rooms", rooms_tbl)?;
            out.set("corridors", corr_tbl)?;
            Ok(out)
        })?,
    )?;

    // -- roomsDungeon --
    /// Generates a rooms-and-corridors dungeon.
    /// @param opts table?
    /// @return table
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
                rt.set("x", r.x)?;
                rt.set("y", r.y)?;
                rt.set("w", r.w)?;
                rt.set("h", r.h)?;
                rooms_tbl.set(i + 1, rt)?;
            }
            let corr_tbl = lua.create_table()?;
            for (i, &(x1, y1, x2, y2)) in d.corridors.iter().enumerate() {
                let ct = lua.create_table()?;
                ct.set("x1", x1)?;
                ct.set("y1", y1)?;
                ct.set("x2", x2)?;
                ct.set("y2", y2)?;
                corr_tbl.set(i + 1, ct)?;
            }
            let grid_tbl = lua.create_table()?;
            for (i, &v) in d.grid.iter().enumerate() {
                grid_tbl.set(i + 1, v)?;
            }
            let out = lua.create_table()?;
            out.set("rooms", rooms_tbl)?;
            out.set("corridors", corr_tbl)?;
            out.set("grid", grid_tbl)?;
            out.set("width", cfg.width)?;
            out.set("height", cfg.height)?;
            Ok(out)
        })?,
    )?;

    // -- heightmap --
    /// Generates a heightmap using fractal noise.
    /// @param opts table?
    /// @return table
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
            res.set("cells", out)?;
            res.set("width", hm.width)?;
            res.set("height", hm.height)?;
            Ok(res)
        })?,
    )?;

    // -- wfcGenerate --
    /// Generates a tile grid using Wave Function Collapse.
    /// @param opts table
    /// @return table
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
            res.set("cells", out)?;
            res.set("width", grid.width)?;
            res.set("height", grid.height)?;
            Ok(res)
        })?,
    )?;

    // -- lsystem --
    /// Generates an L-system string.
    /// @param opts table
    /// @param iterations integer?
    /// @return string
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
                    for pair in rt.pairs::<LuaValue, String>() {
                        if let Ok((k, val)) = pair {
                            if let LuaValue::String(s) = k {
                                if let Some(c) = s.to_str().ok().and_then(|ss| ss.chars().next()) {
                                    v.push((c, val));
                                }
                            }
                        }
                    }
                    v
                })
                .unwrap_or_default();
            let _ = &rules; // ensure variable used
            let sys = LSystem::new_from_pairs(&axiom, &rule_strings, iterations);
            Ok(sys.generate())
        })?,
    )?;

    // -- lsystemSegments --
    /// Generates L-system line segments for rendering.
    /// @param opts table
    /// @param angle_deg number?
    /// @param step number?
    /// @return table
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
                        for pair in rt.pairs::<LuaValue, String>() {
                            if let Ok((k, val)) = pair {
                                if let LuaValue::String(s) = k {
                                    if let Some(c) =
                                        s.to_str().ok().and_then(|ss| ss.chars().next())
                                    {
                                        v.push((c, val));
                                    }
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
                    st.set("x1", *x1)?;
                    st.set("y1", *y1)?;
                    st.set("x2", *x2)?;
                    st.set("y2", *y2)?;
                    out.set(i + 1, st)?;
                }
                Ok(out)
            },
        )?,
    )?;

    // -- generateName --
    /// Generates a single procedural name using a Markov chain.
    /// @param samples table
    /// @param min_len integer?
    /// @param max_len integer?
    /// @param seed integer?
    /// @return string
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
    /// Generates N procedural names using a Markov chain.
    /// @param samples table
    /// @param n integer
    /// @param min_len integer?
    /// @param max_len integer?
    /// @param seed integer?
    /// @return table
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
    /// Generates a world graph with scattered regions and edges.
    /// @param width number
    /// @param height number
    /// @param region_count integer
    /// @param seed integer?
    /// @return table
    tbl.set(
        "worldGraph",
        lua.create_function(
            |lua, (width, height, region_count, seed): (f32, f32, u32, Option<u64>)| {
                let wg = generate_world_graph(width, height, region_count, seed.unwrap_or(0));
                let regions_tbl = lua.create_table()?;
                for (i, r) in wg.regions.iter().enumerate() {
                    let rt = lua.create_table()?;
                    rt.set("id", r.id)?;
                    rt.set("name", r.name.clone())?;
                    rt.set("x", r.x)?;
                    rt.set("y", r.y)?;
                    let tags_tbl = lua.create_table()?;
                    for (j, tag) in r.tags.iter().enumerate() {
                        tags_tbl.set(j + 1, tag.clone())?;
                    }
                    rt.set("tags", tags_tbl)?;
                    regions_tbl.set(i + 1, rt)?;
                }
                let edges_tbl = lua.create_table()?;
                for (i, e) in wg.edges.iter().enumerate() {
                    let et = lua.create_table()?;
                    et.set("from", e.from)?;
                    et.set("to", e.to)?;
                    et.set("cost", e.cost)?;
                    et.set("bidirectional", e.bidirectional)?;
                    edges_tbl.set(i + 1, et)?;
                }
                let out = lua.create_table()?;
                out.set("regions", regions_tbl)?;
                out.set("edges", edges_tbl)?;
                Ok(out)
            },
        )?,
    )?;

    // -- noiseMap --
    /// Generates a noise map using the configurable NoiseGenerator.
    /// @param width integer
    /// @param height integer
    /// @param opts table?
    /// @return table
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
    /// Generates a noise map using rayon parallel processing.
    /// @param width integer
    /// @param height integer
    /// @param opts table?
    /// @return table
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

    // -- simplex2d --
    /// Returns a single Simplex noise value at the given 2-D coordinate.
    /// @param x number
    /// @param y number
    /// @return number
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y): (f32, f32)| Ok(simplex_noise_2d(x, y)))?,
    )?;

    // -- simplex3d --
    /// Returns a single Simplex noise value at the given 3-D coordinate.
    /// @param x number
    /// @param y number
    /// @param z number
    /// @return number
    tbl.set(
        "simplex3d",
        lua.create_function(|_, (x, y, z): (f32, f32, f32)| Ok(simplex_noise_3d(x, y, z)))?,
    )?;

    luna.set("procgen", tbl)?;
    Ok(())
}

impl CellularOpts {
    /// from_lua_table.
    ///
    /// @param t &LuaTable
    ///
    /// @return LuaResult<Self>
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
    /// Parses a Lua options table into [`VoronoiOpts`].
    ///
    /// Supported keys: `warp_scale`, `warp_strength`, `seed`.
    ///
    /// @param t &LuaTable
    /// @return LuaResult<Self>
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
