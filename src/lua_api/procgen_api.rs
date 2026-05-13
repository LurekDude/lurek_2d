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
pub struct LuaBiomeClassifier(BiomeClassifier);
impl LuaUserData for LuaBiomeClassifier {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("classify", |_, this, (h, m, t): (f32, f32, f32)| {
            Ok(this.0.classify(h, m, t).as_str())
        });
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
        methods.add_method("type", |_, _, ()| Ok("BiomeClassifier"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "BiomeClassifier" || name == "Object")
        });
    }
}
impl BiomeRules {
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
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
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
    tbl.set(
        "perlinNoise",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(perlin_noise_periodic(x, y, px, py))
        })?,
    )?;
    tbl.set("poissonDisk", lua.create_function(
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
            let p_tbl = lua.create_table()?;
            for (i, p) in placements.iter().enumerate() {
                let t = lua.create_table()?;
                t.set("name", p.name.as_str())?;
                t.set("x", p.x)?;
                t.set("y", p.y)?;
                t.set("width", p.width)?;
                t.set("height", p.height)?;
                p_tbl.set(i + 1, t)?;
            }
            Ok((out, p_tbl))
        })?,
    )?;
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
                let p_tbl = lua.create_table()?;
                for (i, p) in placements.iter().enumerate() {
                    let t = lua.create_table()?;
                    t.set("name", p.name.as_str())?;
                    t.set("x", p.x)?;
                    t.set("y", p.y)?;
                    t.set("width", p.width)?;
                    t.set("height", p.height)?;
                    p_tbl.set(i + 1, t)?;
                }
                Ok((out, p_tbl))
            },
        )?,
    )?;
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
                res.set("cells", out_cells)?;
                res.set("width", hm.width)?;
                res.set("height", hm.height)?;
                Ok(res)
            },
        )?,
    )?;
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
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y): (f32, f32)| Ok(simplex_noise_2d(x, y)))?,
    )?;
    tbl.set(
        "simplex3d",
        lua.create_function(|_, (x, y, z): (f32, f32, f32)| Ok(simplex_noise_3d(x, y, z)))?,
    )?;
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
    tbl.set(
        "biomeColor",
        lua.create_function(|_, name: String| {
            let bt = BiomeType::from_name(&name);
            let [r, g, b, a] = bt.color_rgba();
            Ok((r, g, b, a))
        })?,
    )?;
    luna.set("procgen", tbl)?;
    Ok(())
}
impl CellularOpts {
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
