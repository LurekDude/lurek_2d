//! Extended math API bindings — Phase 25 types and utility functions.
//!
//! Adds 7 factory functions and 23 module-level functions to `luna.math`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::geometry;
use crate::math::grid::Grid;
use crate::math::noise_generator::{DistType, FractalType, MapGenOptions, NoiseGenerator, NoiseKind};
use crate::math::procgen;
use crate::math::raycaster2d::Raycaster2D;
use crate::math::raycasting::{self, Segment};
use crate::math::spatial_hash::SpatialHash;
use crate::math::tile_walker::{Facing, TileWalker};
use crate::math::tween::Tween;
use crate::math::vec2::Vec2;

// ---------------------------------------------------------------------------
// 1. LuaVec2
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Vec2`.
struct LuaVec2 {
    inner: RefCell<Vec2>,
}

impl LuaUserData for LuaVec2 {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getX", |_, this, ()| Ok(this.inner.borrow().x));
        methods.add_method("getY", |_, this, ()| Ok(this.inner.borrow().y));
        methods.add_method("setX", |_, this, x: f32| {
            this.inner.borrow_mut().x = x;
            Ok(())
        });
        methods.add_method("setY", |_, this, y: f32| {
            this.inner.borrow_mut().y = y;
            Ok(())
        });
        methods.add_method("get", |_, this, ()| {
            let v = *this.inner.borrow();
            Ok((v.x, v.y))
        });
        methods.add_method("set", |_, this, (x, y): (f32, f32)| {
            let mut v = this.inner.borrow_mut();
            v.x = x;
            v.y = y;
            Ok(())
        });
        methods.add_method("getLength", |_, this, ()| {
            Ok(this.inner.borrow().length())
        });
        methods.add_method("getLengthSquared", |_, this, ()| {
            Ok(this.inner.borrow().length_squared())
        });
        methods.add_method("getAngle", |_, this, ()| {
            Ok(this.inner.borrow().angle())
        });
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.dot(b))
        });
        methods.add_method("cross", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.x * b.y - a.y * b.x)
        });
        methods.add_method("getDistance", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.distance(b))
        });
        methods.add_method("getNormalized", |lua, this, ()| {
            let n = this.inner.borrow().normalize();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(n) })
        });
        methods.add_method("getRotated", |lua, this, angle: f32| {
            let v = *this.inner.borrow();
            let cos = angle.cos();
            let sin = angle.sin();
            let r = Vec2::new(v.x * cos - v.y * sin, v.x * sin + v.y * cos);
            lua.create_userdata(LuaVec2 { inner: RefCell::new(r) })
        });
        methods.add_method("getPerpendicular", |lua, this, ()| {
            let v = *this.inner.borrow();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(Vec2::new(-v.y, v.x)) })
        });
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f32)| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(a.lerp(b, t)) })
        });
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaVec2 { inner: RefCell::new(*this.inner.borrow()) })
        });

        // Metamethods
        methods.add_meta_method(LuaMetaMethod::Add, |lua, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(a + b) })
        });
        methods.add_meta_method(LuaMetaMethod::Sub, |lua, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(a - b) })
        });
        methods.add_meta_method(LuaMetaMethod::Mul, |lua, this, val: LuaValue| {
            let a = *this.inner.borrow();
            match &val {
                LuaValue::UserData(ud) => {
                    let b = *ud.borrow::<LuaVec2>()?.inner.borrow();
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(Vec2::new(a.x * b.x, a.y * b.y)),
                    })
                }
                _ => {
                    let s: f32 = lua.unpack(val)?;
                    lua.create_userdata(LuaVec2 { inner: RefCell::new(a * s) })
                }
            }
        });
        methods.add_meta_method(LuaMetaMethod::Div, |lua, this, val: LuaValue| {
            let a = *this.inner.borrow();
            match &val {
                LuaValue::UserData(ud) => {
                    let b = *ud.borrow::<LuaVec2>()?.inner.borrow();
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(Vec2::new(a.x / b.x, a.y / b.y)),
                    })
                }
                _ => {
                    let s: f32 = lua.unpack(val)?;
                    lua.create_userdata(LuaVec2 { inner: RefCell::new(a / s) })
                }
            }
        });
        methods.add_meta_method(LuaMetaMethod::Unm, |lua, this, ()| {
            let v = *this.inner.borrow();
            lua.create_userdata(LuaVec2 { inner: RefCell::new(Vec2::new(-v.x, -v.y)) })
        });
        methods.add_meta_method(LuaMetaMethod::Eq, |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a == b)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let v = *this.inner.borrow();
            Ok(format!("Vec2({}, {})", v.x, v.y))
        });
    }
}

// ---------------------------------------------------------------------------
// 2. LuaNoiseGenerator
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `NoiseGenerator`.
struct LuaNoiseGenerator {
    inner: RefCell<NoiseGenerator>,
}

impl LuaUserData for LuaNoiseGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("setSeed", |_, this, seed: u64| {
            this.inner.borrow_mut().set_seed(seed);
            Ok(())
        });
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.borrow().seed()));

        methods.add_method(
            "perlinNoise",
            |_, this, args: LuaMultiValue| {
                let gen = this.inner.borrow();
                let n = args.len();
                let vals: Vec<f64> = args
                    .into_iter()
                    .map(|v| match v {
                        LuaValue::Number(n) => Ok(n),
                        LuaValue::Integer(i) => Ok(i as f64),
                        _ => Err(LuaError::RuntimeError("expected number".into())),
                    })
                    .collect::<LuaResult<Vec<_>>>()?;
                match n {
                    1 => Ok(gen.perlin_1d(vals[0])),
                    2 => Ok(gen.perlin_2d(vals[0], vals[1])),
                    3 => Ok(gen.perlin_3d(vals[0], vals[1], vals[2])),
                    4 => Ok(gen.perlin_4d(vals[0], vals[1], vals[2], vals[3])),
                    _ => Err(LuaError::RuntimeError(
                        "perlinNoise expects 1-4 arguments".into(),
                    )),
                }
            },
        );

        methods.add_method(
            "simplexNoise",
            |_, this, args: LuaMultiValue| {
                let gen = this.inner.borrow();
                let n = args.len();
                let vals: Vec<f64> = args
                    .into_iter()
                    .map(|v| match v {
                        LuaValue::Number(n) => Ok(n),
                        LuaValue::Integer(i) => Ok(i as f64),
                        _ => Err(LuaError::RuntimeError("expected number".into())),
                    })
                    .collect::<LuaResult<Vec<_>>>()?;
                match n {
                    1 => Ok(gen.simplex_1d(vals[0])),
                    2 => Ok(gen.simplex_2d(vals[0], vals[1])),
                    3 => Ok(gen.simplex_3d(vals[0], vals[1], vals[2])),
                    _ => Err(LuaError::RuntimeError(
                        "simplexNoise expects 1-3 arguments".into(),
                    )),
                }
            },
        );

        methods.add_method(
            "worleyNoise",
            |_, this, (x, y, z, dist_type, f2): (f64, f64, Option<f64>, Option<String>, Option<bool>)| {
                let gen = this.inner.borrow();
                let dt = match dist_type.as_deref() {
                    Some("manhattan") => DistType::Manhattan,
                    Some("chebyshev") => DistType::Chebyshev,
                    _ => DistType::Euclidean,
                };
                let use_f2 = f2.unwrap_or(false);
                match z {
                    Some(z) => Ok(gen.worley_3d(x, y, z, dt, use_f2)),
                    None => Ok(gen.worley_2d(x, y, dt, use_f2)),
                }
            },
        );

        methods.add_method(
            "fbm",
            |_, this, (x, y, octaves, lac, pers, kind): (f64, f64, Option<u32>, Option<f64>, Option<f64>, Option<String>)| {
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.fbm(x, y, octaves.unwrap_or(4), lac.unwrap_or(2.0), pers.unwrap_or(0.5), k))
            },
        );

        methods.add_method(
            "ridged",
            |_, this, (x, y, octaves, lac, pers, kind): (f64, f64, Option<u32>, Option<f64>, Option<f64>, Option<String>)| {
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.ridged(x, y, octaves.unwrap_or(4), lac.unwrap_or(2.0), pers.unwrap_or(0.5), k))
            },
        );

        methods.add_method(
            "turbulence",
            |_, this, (x, y, octaves, lac, pers, kind): (f64, f64, Option<u32>, Option<f64>, Option<f64>, Option<String>)| {
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.turbulence(x, y, octaves.unwrap_or(4), lac.unwrap_or(2.0), pers.unwrap_or(0.5), k))
            },
        );

        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| {
                let gen = this.inner.borrow();
                let (wx, wy) = gen.warp_domain(x, y, strength);
                Ok((wx, wy))
            },
        );

        methods.add_method(
            "generateMap",
            |lua, this, (width, height, opts_table): (u32, u32, Option<LuaTable>)| {
                let gen = this.inner.borrow();
                let opts = if let Some(t) = opts_table {
                    MapGenOptions {
                        scale_x: t.get::<_, Option<f64>>("scaleX")?.unwrap_or(1.0),
                        scale_y: t.get::<_, Option<f64>>("scaleY")?.unwrap_or(1.0),
                        octaves: t.get::<_, Option<u32>>("octaves")?.unwrap_or(4),
                        lacunarity: t.get::<_, Option<f64>>("lacunarity")?.unwrap_or(2.0),
                        persistence: t.get::<_, Option<f64>>("persistence")?.unwrap_or(0.5),
                        kind: parse_noise_kind(t.get::<_, Option<String>>("kind")?.as_deref()),
                        fractal: parse_fractal_type(t.get::<_, Option<String>>("fractal")?.as_deref()),
                        offset_x: t.get::<_, Option<f64>>("offsetX")?.unwrap_or(0.0),
                        offset_y: t.get::<_, Option<f64>>("offsetY")?.unwrap_or(0.0),
                    }
                } else {
                    MapGenOptions::default()
                };
                let map = gen.generate_map(width, height, &opts);
                let tbl = lua.create_table_with_capacity(map.len(), 0)?;
                for (i, v) in map.iter().enumerate() {
                    tbl.raw_set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        );
    }
}

fn parse_noise_kind(s: Option<&str>) -> NoiseKind {
    match s {
        Some("simplex") => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}

fn parse_fractal_type(s: Option<&str>) -> FractalType {
    match s {
        Some("ridged") => FractalType::Ridged,
        Some("turbulence") => FractalType::Turbulence,
        _ => FractalType::Fbm,
    }
}

// ---------------------------------------------------------------------------
// 3. LuaGrid
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Grid`.
struct LuaGrid {
    inner: RefCell<Grid>,
}

impl LuaUserData for LuaGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height()));
        methods.add_method("getDimensions", |_, this, ()| {
            let g = this.inner.borrow();
            Ok((g.width(), g.height()))
        });
        // 1-based coords in Lua
        methods.add_method("setWalkable", |_, this, (x, y, w): (u32, u32, bool)| {
            this.inner.borrow_mut().set_walkable(x - 1, y - 1, w);
            Ok(())
        });
        methods.add_method("isWalkable", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_walkable(x - 1, y - 1))
        });
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, f32)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
        methods.add_method("getCost", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });

        methods.add_method(
            "findPath",
            |lua, this, (sx, sy, ex, ey, algo, diagonal): (u32, u32, u32, u32, Option<String>, Option<bool>)| {
                let g = this.inner.borrow();
                let diag = diagonal.unwrap_or(false);
                let sx0 = sx - 1;
                let sy0 = sy - 1;
                let ex0 = ex - 1;
                let ey0 = ey - 1;
                let path = match algo.as_deref() {
                    Some("dijkstra") => g.find_path_dijkstra(sx0, sy0, ex0, ey0, diag),
                    Some("bfs") => g.find_path_bfs(sx0, sy0, ex0, ey0, diag),
                    _ => g.find_path_astar(sx0, sy0, ex0, ey0, diag),
                };
                match path {
                    Some(p) => {
                        let tbl = lua.create_table_with_capacity(p.len(), 0)?;
                        for (i, (px, py)) in p.iter().enumerate() {
                            let pt = lua.create_table_with_capacity(0, 2)?;
                            pt.set("x", px + 1)?;
                            pt.set("y", py + 1)?;
                            tbl.raw_set(i + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        methods.add_method("buildFlowField", |lua, this, (gx, gy): (u32, u32)| {
            let g = this.inner.borrow();
            let field = g.build_flow_field(gx - 1, gy - 1);
            let w = g.width();
            let tbl = lua.create_table_with_capacity(field.len(), 0)?;
            for (i, (dx, dy)) in field.iter().enumerate() {
                let x = (i as u32 % w) + 1;
                let y = (i as u32 / w) + 1;
                let entry = lua.create_table_with_capacity(0, 4)?;
                entry.set("x", x)?;
                entry.set("y", y)?;
                entry.set("dx", *dx)?;
                entry.set("dy", *dy)?;
                tbl.raw_set(i + 1, entry)?;
            }
            Ok(tbl)
        });
    }
}

// ---------------------------------------------------------------------------
// 4. LuaSpatialHash
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `SpatialHash`.
struct LuaSpatialHash {
    inner: RefCell<SpatialHash>,
}

fn to_string_id(val: &LuaValue) -> LuaResult<String> {
    match val {
        LuaValue::String(s) => Ok(s.to_str()?.to_string()),
        LuaValue::Integer(i) => Ok(format!("{i}")),
        LuaValue::Number(n) => Ok(format!("{n}")),
        _ => Err(LuaError::RuntimeError("id must be string or number".into())),
    }
}

impl LuaUserData for LuaSpatialHash {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size())
        });
        methods.add_method(
            "insert",
            |_, this, (id, x, y, w, h): (LuaValue, f32, f32, f32, f32)| {
                let key = to_string_id(&id)?;
                this.inner.borrow_mut().insert(key, x, y, w, h);
                Ok(())
            },
        );
        methods.add_method("remove", |_, this, id: LuaValue| {
            let key = to_string_id(&id)?;
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });
        methods.add_method(
            "update",
            |_, this, (id, x, y, w, h): (LuaValue, f32, f32, f32, f32)| {
                let key = to_string_id(&id)?;
                this.inner.borrow_mut().update(key, x, y, w, h);
                Ok(())
            },
        );
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("queryRect", |lua, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let ids = this.inner.borrow().query_rect(x, y, w, h);
            let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
            for (i, id) in ids.iter().enumerate() {
                tbl.raw_set(i + 1, id.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("queryCircle", |lua, this, (cx, cy, r): (f32, f32, f32)| {
            let ids = this.inner.borrow().query_circle(cx, cy, r);
            let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
            for (i, id) in ids.iter().enumerate() {
                tbl.raw_set(i + 1, id.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method(
            "querySegment",
            |lua, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                let ids = this.inner.borrow().query_segment(x1, y1, x2, y2);
                let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
                for (i, id) in ids.iter().enumerate() {
                    tbl.raw_set(i + 1, id.as_str())?;
                }
                Ok(tbl)
            },
        );
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().item_count())
        });
    }
}

// ---------------------------------------------------------------------------
// 5. LuaRaycaster2D
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Raycaster2D`.
///
/// Uses `Rc<RefCell<…>>` so `LuaTileWalker` can share the same raycaster.
struct LuaRaycaster2D {
    inner: Rc<RefCell<Raycaster2D>>,
}

impl LuaUserData for LuaRaycaster2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height()));
        methods.add_method("getDimensions", |_, this, ()| {
            let rc = this.inner.borrow();
            Ok((rc.width(), rc.height()))
        });
        // 1-based cell access
        methods.add_method("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.borrow_mut().set_cell(x - 1, y - 1, val);
            Ok(())
        });
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cell(x - 1, y - 1))
        });
        methods.add_method("setCells", |_, this, data: LuaTable| {
            let len = data.raw_len();
            let mut vec = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u32 = data.raw_get(i)?;
                vec.push(v);
            }
            this.inner.borrow_mut().set_cells(vec);
            Ok(())
        });
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });

        // World-space raycasting (float coords, not adjusted)
        methods.add_method(
            "castRay",
            |_, this, (ox, oy, angle, max_dist): (f32, f32, f32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                match rc.cast_ray(ox, oy, angle, md) {
                    Some(hit) => Ok((
                        LuaValue::Number(hit.distance as f64),
                        LuaValue::Integer(hit.cell_value as i64),
                        LuaValue::Integer(hit.side as i64),
                        LuaValue::Number(hit.tex_u as f64),
                        LuaValue::Number(hit.hit_x as f64),
                        LuaValue::Number(hit.hit_y as f64),
                    )),
                    None => Ok((
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                    )),
                }
            },
        );

        methods.add_method(
            "castRays",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                let hits = rc.cast_rays(ox, oy, angle, fov, count, md);
                let tbl = lua.create_table_with_capacity(hits.len(), 0)?;
                for (i, h) in hits.iter().enumerate() {
                    let entry = lua.create_table_with_capacity(0, 7)?;
                    entry.set("distance", h.distance)?;
                    entry.set("cellValue", h.cell_value)?;
                    entry.set("side", h.side)?;
                    entry.set("texU", h.tex_u)?;
                    entry.set("hitX", h.hit_x)?;
                    entry.set("hitY", h.hit_y)?;
                    entry.set("hit", h.hit)?;
                    tbl.raw_set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );

        methods.add_method(
            "castRaysFlat",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                let flat = rc.cast_rays_flat(ox, oy, angle, fov, count, md);
                let tbl = lua.create_table_with_capacity(flat.len(), 0)?;
                for (i, v) in flat.iter().enumerate() {
                    tbl.raw_set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        );

        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().line_of_sight(x1, y1, x2, y2))
            },
        );

        methods.add_method(
            "projectSprite",
            |_, this, (sx, sy, px, py, pa, fov, screen_w): (f32, f32, f32, f32, f32, f32, f32)| {
                let rc = this.inner.borrow();
                let sp = rc.project_sprite(sx, sy, px, py, pa, fov, screen_w);
                Ok((sp.screen_x, sp.scale, sp.distance, sp.visible))
            },
        );
    }
}

// ---------------------------------------------------------------------------
// 6. LuaTileWalker
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `TileWalker`.
struct LuaTileWalker {
    inner: RefCell<TileWalker>,
}

impl LuaUserData for LuaTileWalker {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // 1-based position
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.inner.borrow();
            Ok((w.x() + 1, w.y() + 1))
        });
        methods.add_method("setPosition", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().set_position(x - 1, y - 1);
            Ok(())
        });
        methods.add_method("getFacing", |_, this, ()| {
            Ok(this.inner.borrow().facing().to_str().to_string())
        });
        methods.add_method("setFacing", |_, this, facing: String| {
            let f = Facing::parse(&facing)
                .ok_or_else(|| LuaError::RuntimeError(format!("invalid facing: {facing}")))?;
            this.inner.borrow_mut().set_facing(f);
            Ok(())
        });
        methods.add_method("getFacingAngle", |_, this, ()| {
            Ok(this.inner.borrow().facing().angle())
        });
        methods.add_method("getFacingDirection", |_, this, ()| {
            let f = this.inner.borrow().facing();
            Ok((f.dx(), f.dy()))
        });
        methods.add_method("moveForward", |_, this, ()| {
            Ok(this.inner.borrow_mut().move_forward())
        });
        methods.add_method("moveBackward", |_, this, ()| {
            Ok(this.inner.borrow_mut().move_backward())
        });
        methods.add_method("strafeLeft", |_, this, ()| {
            Ok(this.inner.borrow_mut().strafe_left())
        });
        methods.add_method("strafeRight", |_, this, ()| {
            Ok(this.inner.borrow_mut().strafe_right())
        });
        methods.add_method("turnLeft", |_, this, ()| {
            this.inner.borrow_mut().turn_left();
            Ok(())
        });
        methods.add_method("turnRight", |_, this, ()| {
            this.inner.borrow_mut().turn_right();
            Ok(())
        });
        methods.add_method("turnAround", |_, this, ()| {
            this.inner.borrow_mut().turn_around();
            Ok(())
        });
        methods.add_method("setRaycaster", |_, this, rc_ud: LuaAnyUserData| {
            let lua_rc = rc_ud.borrow::<LuaRaycaster2D>()?;
            this.inner
                .borrow_mut()
                .set_raycaster(Rc::clone(&lua_rc.inner));
            Ok(())
        });
        methods.add_method("canMoveForward", |_, this, ()| {
            Ok(this.inner.borrow().can_move_forward())
        });
        methods.add_method("canMoveBackward", |_, this, ()| {
            Ok(this.inner.borrow().can_move_backward())
        });
        methods.add_method("canStrafeLeft", |_, this, ()| {
            Ok(this.inner.borrow().can_strafe_left())
        });
        methods.add_method("canStrafeRight", |_, this, ()| {
            Ok(this.inner.borrow().can_strafe_right())
        });
        methods.add_method("beginMove", |_, this, ()| {
            this.inner.borrow_mut().begin_move();
            Ok(())
        });
        methods.add_method("getInterpolatedPosition", |_, this, t: f32| {
            let (ix, iy) = this.inner.borrow().get_interpolated_position(t);
            // Return 1-based
            Ok((ix + 1.0, iy + 1.0))
        });
        methods.add_method("getInterpolatedAngle", |_, this, t: f32| {
            Ok(this.inner.borrow().get_interpolated_angle(t))
        });
        // 1-based target coords
        methods.add_method("getRelativeFacing", |_, this, (tx, ty): (i32, i32)| {
            Ok(this.inner.borrow().get_relative_facing(tx - 1, ty - 1).to_string())
        });
    }
}

// ---------------------------------------------------------------------------
// 7. LuaTween
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Tween`.
struct LuaTween {
    inner: RefCell<Tween>,
}

impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("addValue", |_, this, (start, target): (f64, f64)| {
            let idx = this.inner.borrow_mut().add_value(start, target);
            Ok(idx + 1) // 1-based
        });
        methods.add_method("update", |_, this, dt: f64| {
            Ok(this.inner.borrow_mut().update(dt))
        });
        methods.add_method("getValue", |lua, this, index: Option<i64>| {
            let tw = this.inner.borrow();
            match index {
                Some(i) => Ok(LuaValue::Number(tw.get_value((i - 1) as usize))),
                None => {
                    let vals = tw.get_all_values();
                    let tbl = lua.create_table_with_capacity(vals.len(), 0)?;
                    for (idx, v) in vals.iter().enumerate() {
                        tbl.raw_set(idx + 1, *v)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
            }
        });
        methods.add_method("getValueCount", |_, this, ()| {
            Ok(this.inner.borrow().value_count())
        });
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("set", |_, this, time: f64| {
            this.inner.borrow_mut().set_time(time);
            Ok(())
        });
        methods.add_method("getClock", |_, this, ()| {
            Ok(this.inner.borrow().clock())
        });
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });
        methods.add_method("isComplete", |_, this, ()| {
            Ok(this.inner.borrow().is_complete())
        });
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Read a flat `{x1, y1, x2, y2, ...}` Lua table into a `Vec<f32>`.
fn read_flat_f32(tbl: &LuaTable) -> LuaResult<Vec<f32>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        out.push(tbl.raw_get::<_, f32>(i)?);
    }
    Ok(out)
}

/// Read a `{{x, y}, {x, y}, ...}` or `{{x=, y=}, ...}` table into `Vec<(f32, f32)>`.
fn read_points_f32(tbl: &LuaTable) -> LuaResult<Vec<(f32, f32)>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let pt: LuaTable = tbl.raw_get(i)?;
        // Try named keys first, then positional
        let x: f32 = pt.get::<_, Option<f32>>("x")?.unwrap_or_else(|| pt.raw_get(1).unwrap_or(0.0));
        let y: f32 = pt.get::<_, Option<f32>>("y")?.unwrap_or_else(|| pt.raw_get(2).unwrap_or(0.0));
        out.push((x, y));
    }
    Ok(out)
}

/// Read a `{{x, y}, {x, y}, ...}` table into `Vec<(f64, f64)>`.
fn read_points_f64(tbl: &LuaTable) -> LuaResult<Vec<(f64, f64)>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let pt: LuaTable = tbl.raw_get(i)?;
        let x: f64 = pt.get::<_, Option<f64>>("x")?.unwrap_or_else(|| pt.raw_get(1).unwrap_or(0.0));
        let y: f64 = pt.get::<_, Option<f64>>("y")?.unwrap_or_else(|| pt.raw_get(2).unwrap_or(0.0));
        out.push((x, y));
    }
    Ok(out)
}

/// Read a `{{x1,y1,x2,y2}, ...}` table into `Vec<Segment>`.
fn read_segments(tbl: &LuaTable) -> LuaResult<Vec<Segment>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let seg: LuaTable = tbl.raw_get(i)?;
        let x1: f32 = seg.raw_get(1)?;
        let y1: f32 = seg.raw_get(2)?;
        let x2: f32 = seg.raw_get(3)?;
        let y2: f32 = seg.raw_get(4)?;
        out.push(Segment { x1, y1, x2, y2 });
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers extended math API bindings on the `luna.math` table.
pub fn register(lua: &Lua, luna_table: &LuaTable) -> LuaResult<()> {
    let math: LuaTable = luna_table.get("math")?;

    // ── Factory functions ──────────────────────────────────────────────

    /// luna.math.newVec2(x, y)
    #[allow(unused_doc_comments)]
    math.set(
        "newVec2",
        lua.create_function(|lua, (x, y): (Option<f32>, Option<f32>)| {
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(Vec2::new(x.unwrap_or(0.0), y.unwrap_or(0.0))),
            })
        })?,
    )?;

    /// luna.math.newNoiseGenerator(seed)
    #[allow(unused_doc_comments)]
    math.set(
        "newNoiseGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            lua.create_userdata(LuaNoiseGenerator {
                inner: RefCell::new(NoiseGenerator::new(seed.unwrap_or(0))),
            })
        })?,
    )?;

    /// luna.math.newGrid(width, height, defaultCost)
    #[allow(unused_doc_comments)]
    math.set(
        "newGrid",
        lua.create_function(|lua, (w, h, cost): (u32, u32, Option<f32>)| {
            lua.create_userdata(LuaGrid {
                inner: RefCell::new(Grid::new(w, h, cost.unwrap_or(1.0))),
            })
        })?,
    )?;

    /// luna.math.newSpatialHash(cellSize)
    #[allow(unused_doc_comments)]
    math.set(
        "newSpatialHash",
        lua.create_function(|lua, cell_size: f32| {
            lua.create_userdata(LuaSpatialHash {
                inner: RefCell::new(SpatialHash::new(cell_size)),
            })
        })?,
    )?;

    /// luna.math.newRaycaster2D(width, height)
    #[allow(unused_doc_comments)]
    math.set(
        "newRaycaster2D",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaRaycaster2D {
                inner: Rc::new(RefCell::new(Raycaster2D::new(w, h))),
            })
        })?,
    )?;

    /// luna.math.newTileWalker(x, y, facing)
    #[allow(unused_doc_comments)]
    math.set(
        "newTileWalker",
        lua.create_function(|lua, (x, y, facing): (i32, i32, Option<String>)| {
            let f = facing
                .as_deref()
                .and_then(Facing::parse)
                .unwrap_or(Facing::North);
            lua.create_userdata(LuaTileWalker {
                inner: RefCell::new(TileWalker::new(x - 1, y - 1, f)),
            })
        })?,
    )?;

    /// luna.math.newTween(duration, easing)
    #[allow(unused_doc_comments)]
    math.set(
        "newTween",
        lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTween {
                inner: RefCell::new(Tween::new(duration, easing.as_deref().unwrap_or("linear"))),
            })
        })?,
    )?;

    // ── Geometry functions (14) ────────────────────────────────────────

    /// luna.math.angleBetween(x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;

    /// luna.math.circleContainsPoint(cx, cy, r, px, py)
    #[allow(unused_doc_comments)]
    math.set(
        "circleContainsPoint",
        lua.create_function(|_, (cx, cy, r, px, py): (f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_contains_point(cx, cy, r, px, py))
        })?,
    )?;

    /// luna.math.circleIntersectsCircle(x1, y1, r1, x2, y2, r2)
    #[allow(unused_doc_comments)]
    math.set(
        "circleIntersectsCircle",
        lua.create_function(|_, (x1, y1, r1, x2, y2, r2): (f32, f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_intersects_circle(x1, y1, r1, x2, y2, r2))
        })?,
    )?;

    /// luna.math.circleIntersectsLine(cx, cy, r, lx1, ly1, lx2, ly2)
    #[allow(unused_doc_comments)]
    math.set(
        "circleIntersectsLine",
        lua.create_function(
            |_, (cx, cy, r, lx1, ly1, lx2, ly2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) =
                    geometry::circle_intersects_line(cx, cy, r, lx1, ly1, lx2, ly2);
                Ok((
                    hit,
                    p1.map(|(x, _)| x),
                    p1.map(|(_, y)| y),
                    p2.map(|(x, _)| x),
                    p2.map(|(_, y)| y),
                ))
            },
        )?,
    )?;

    /// luna.math.circleIntersectsSegment(cx, cy, r, sx1, sy1, sx2, sy2)
    #[allow(unused_doc_comments)]
    math.set(
        "circleIntersectsSegment",
        lua.create_function(
            |_, (cx, cy, r, sx1, sy1, sx2, sy2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) =
                    geometry::circle_intersects_segment(cx, cy, r, sx1, sy1, sx2, sy2);
                Ok((
                    hit,
                    p1.map(|(x, _)| x),
                    p1.map(|(_, y)| y),
                    p2.map(|(x, _)| x),
                    p2.map(|(_, y)| y),
                ))
            },
        )?,
    )?;

    /// luna.math.polygonArea(vertices)
    #[allow(unused_doc_comments)]
    math.set(
        "polygonArea",
        lua.create_function(|_, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            Ok(geometry::polygon_area(&verts))
        })?,
    )?;

    /// luna.math.polygonCentroid(vertices)
    #[allow(unused_doc_comments)]
    math.set(
        "polygonCentroid",
        lua.create_function(|_, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            let (cx, cy) = geometry::polygon_centroid(&verts);
            Ok((cx, cy))
        })?,
    )?;

    /// luna.math.segmentIntersectsSegment(x1, y1, x2, y2, x3, y3, x4, y4)
    #[allow(unused_doc_comments)]
    math.set(
        "segmentIntersectsSegment",
        lua.create_function(
            |_,
             (x1, y1, x2, y2, x3, y3, x4, y4): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, pt) =
                    geometry::segment_intersects_segment(x1, y1, x2, y2, x3, y3, x4, y4);
                Ok((hit, pt.map(|(x, _)| x), pt.map(|(_, y)| y)))
            },
        )?,
    )?;

    /// luna.math.closestPointOnSegment(px, py, x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math.set(
        "closestPointOnSegment",
        lua.create_function(
            |_, (px, py, x1, y1, x2, y2): (f32, f32, f32, f32, f32, f32)| {
                let (cx, cy) = geometry::closest_point_on_segment(px, py, x1, y1, x2, y2);
                Ok((cx, cy))
            },
        )?,
    )?;

    /// luna.math.pointInPolygon(vertices, px, py)
    #[allow(unused_doc_comments)]
    math.set(
        "pointInPolygon",
        lua.create_function(|_, (tbl, px, py): (LuaTable, f32, f32)| {
            let verts = read_flat_f32(&tbl)?;
            Ok(geometry::point_in_polygon(&verts, px, py))
        })?,
    )?;

    /// luna.math.lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    #[allow(unused_doc_comments)]
    math.set(
        "lineIntersect",
        lua.create_function(
            |_,
             (x1, y1, x2, y2, x3, y3, x4, y4): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                match geometry::line_intersect(x1, y1, x2, y2, x3, y3, x4, y4) {
                    Some((ix, iy)) => Ok((Some(ix), Some(iy))),
                    None => Ok((None, None)),
                }
            },
        )?,
    )?;

    /// luna.math.bresenham(x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math.set(
        "bresenham",
        lua.create_function(|lua, (x1, y1, x2, y2): (i32, i32, i32, i32)| {
            let pts = geometry::bresenham(x1, y1, x2, y2);
            let tbl = lua.create_table_with_capacity(pts.len() * 2, 0)?;
            for (i, (x, y)) in pts.iter().enumerate() {
                tbl.raw_set(i * 2 + 1, *x)?;
                tbl.raw_set(i * 2 + 2, *y)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// luna.math.convexHull(points)
    #[allow(unused_doc_comments)]
    math.set(
        "convexHull",
        lua.create_function(|lua, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            let hull = geometry::convex_hull(&verts);
            let out = lua.create_table_with_capacity(hull.len(), 0)?;
            for (i, v) in hull.iter().enumerate() {
                out.raw_set(i + 1, *v)?;
            }
            Ok(out)
        })?,
    )?;

    /// luna.math.delaunayTriangulate(points)
    #[allow(unused_doc_comments)]
    math.set(
        "delaunayTriangulate",
        lua.create_function(|lua, tbl: LuaTable| {
            let pts = read_points_f64(&tbl)?;
            let triangles = geometry::delaunay_triangulate(&pts);
            let out = lua.create_table_with_capacity(triangles.len(), 0)?;
            for (i, tri) in triangles.iter().enumerate() {
                let t = lua.create_table_with_capacity(6, 0)?;
                for (j, v) in tri.iter().enumerate() {
                    t.raw_set(j + 1, *v)?;
                }
                out.raw_set(i + 1, t)?;
            }
            Ok(out)
        })?,
    )?;

    // ── Raycasting functions (4) ───────────────────────────────────────

    /// luna.math.castRay2D(ox, oy, dx, dy, maxDist, segments)
    #[allow(unused_doc_comments)]
    math.set(
        "castRay2D",
        lua.create_function(
            |_, (ox, oy, dx, dy, max_dist, segs_tbl): (f32, f32, f32, f32, f32, LuaTable)| {
                let segs = read_segments(&segs_tbl)?;
                match raycasting::cast_ray_2d(ox, oy, dx, dy, max_dist, &segs) {
                    Some((hx, hy, idx)) => Ok((Some(hx), Some(hy), Some(idx as i64 + 1))),
                    None => Ok((None, None, None)),
                }
            },
        )?,
    )?;

    /// luna.math.fieldOfView(ox, oy, segments, radius)
    #[allow(unused_doc_comments)]
    math.set(
        "fieldOfView",
        lua.create_function(|lua, (ox, oy, segs_tbl, radius): (f32, f32, LuaTable, f32)| {
            let segs = read_segments(&segs_tbl)?;
            let poly = raycasting::field_of_view(ox, oy, &segs, radius);
            let tbl = lua.create_table_with_capacity(poly.len(), 0)?;
            for (i, v) in poly.iter().enumerate() {
                tbl.raw_set(i + 1, *v)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// luna.math.projectColumn(distance, fov, screenHeight)
    #[allow(unused_doc_comments)]
    math.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_h): (f32, f32, f32)| {
            let (wh, ds, de) = raycasting::project_column(distance, fov, screen_h);
            Ok((wh, ds, de))
        })?,
    )?;

    /// luna.math.distanceShade(distance, maxDistance)
    #[allow(unused_doc_comments)]
    math.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_dist): (f32, f32)| {
            Ok(raycasting::distance_shade(distance, max_dist))
        })?,
    )?;

    // ── Procedural generation functions (5) ────────────────────────────

    /// luna.math.cellularAutomata(width, height, opts)
    #[allow(unused_doc_comments)]
    math.set(
        "cellularAutomata",
        lua.create_function(|lua, (w, h, opts_tbl): (u32, u32, Option<LuaTable>)| {
            let opts = if let Some(t) = opts_tbl {
                procgen::CellularOpts {
                    fill: t.get::<_, Option<f32>>("fill")?.unwrap_or(0.45),
                    iterations: t.get::<_, Option<u32>>("iterations")?.unwrap_or(5),
                    birth: t.get::<_, Option<u32>>("birth")?.unwrap_or(6),
                    survive: t.get::<_, Option<u32>>("survive")?.unwrap_or(4),
                    seed: t.get::<_, Option<u64>>("seed")?.unwrap_or(12345),
                }
            } else {
                procgen::CellularOpts::default()
            };
            let grid = procgen::cellular_automata(w, h, &opts);
            let tbl = lua.create_table_with_capacity(grid.len(), 0)?;
            for (i, v) in grid.iter().enumerate() {
                tbl.raw_set(i + 1, *v as i64)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// luna.math.voronoiDiagram(width, height, points, opts)
    #[allow(unused_doc_comments)]
    math.set(
        "voronoiDiagram",
        lua.create_function(
            |lua, (w, h, pts_tbl, opts_tbl): (u32, u32, LuaTable, Option<LuaTable>)| {
                let pts = read_points_f32(&pts_tbl)?;
                let opts = if let Some(t) = opts_tbl {
                    procgen::VoronoiOpts {
                        warp_scale: t.get::<_, Option<f32>>("warpScale")?.unwrap_or(0.1),
                        warp_strength: t.get::<_, Option<f32>>("warpStrength")?.unwrap_or(0.0),
                        seed: t.get::<_, Option<u64>>("seed")?.unwrap_or(0),
                    }
                } else {
                    procgen::VoronoiOpts::default()
                };
                let (regions, distances, second_distances) =
                    procgen::voronoi_diagram(w, h, &pts, &opts);
                let reg_tbl = lua.create_table_with_capacity(regions.len(), 0)?;
                for (i, v) in regions.iter().enumerate() {
                    reg_tbl.raw_set(i + 1, *v + 1)?; // 1-based point index
                }
                let dist_tbl = lua.create_table_with_capacity(distances.len(), 0)?;
                for (i, v) in distances.iter().enumerate() {
                    dist_tbl.raw_set(i + 1, *v)?;
                }
                let sd_tbl = lua.create_table_with_capacity(second_distances.len(), 0)?;
                for (i, v) in second_distances.iter().enumerate() {
                    sd_tbl.raw_set(i + 1, *v)?;
                }
                Ok((reg_tbl, dist_tbl, sd_tbl))
            },
        )?,
    )?;

    /// luna.math.floodFill(data, width, height, sx, sy, threshold, mode)
    #[allow(unused_doc_comments)]
    math.set(
        "floodFill",
        lua.create_function(
            |lua,
             (data_tbl, w, h, sx, sy, threshold, mode): (
                LuaTable,
                u32,
                u32,
                u32,
                u32,
                u8,
                Option<String>,
            )| {
                let len = data_tbl.raw_len();
                let mut data = Vec::with_capacity(len);
                for i in 1..=len {
                    data.push(data_tbl.raw_get::<_, u8>(i)?);
                }
                let above = mode.as_deref() == Some("above");
                // 1-based to 0-based
                let result = procgen::flood_fill(&data, w, h, sx - 1, sy - 1, threshold, above);
                let tbl = lua.create_table_with_capacity(result.len(), 0)?;
                for (i, v) in result.iter().enumerate() {
                    tbl.raw_set(i + 1, *v as i64)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    /// luna.math.poissonDisk(width, height, minDist, maxAttempts, seed)
    #[allow(unused_doc_comments)]
    math.set(
        "poissonDisk",
        lua.create_function(
            |lua,
             (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let pts = procgen::poisson_disk(
                    w,
                    h,
                    min_dist,
                    max_attempts.unwrap_or(30),
                    seed.unwrap_or(0),
                );
                let tbl = lua.create_table_with_capacity(pts.len(), 0)?;
                for (i, (px, py)) in pts.iter().enumerate() {
                    let pt = lua.create_table_with_capacity(0, 2)?;
                    pt.set("x", *px)?;
                    pt.set("y", *py)?;
                    tbl.raw_set(i + 1, pt)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    /// luna.math.perlinNoisePeriodic(x, y, px, py)
    #[allow(unused_doc_comments)]
    math.set(
        "perlinNoisePeriodic",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(procgen::perlin_noise_periodic(x, y, px, py))
        })?,
    )?;

    Ok(())
}
