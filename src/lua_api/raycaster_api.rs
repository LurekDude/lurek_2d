use super::SharedState;
use crate::lua_api::render_api::{LObjModel, LuaImage};
use crate::math::Color;
use crate::raycaster::sprite_manager::SpriteManager;
use crate::raycaster::{
    build_minimap_tile_window, compute_lighting, compute_tile_light, dir4_delta, distance_shade,
    project_column, reveal_cells_from_rays, try_move, DoorDirection, DoorManager, DoorState,
    GridMoveAction, HeightMap, ModelMesh, PointLight, RayHit, Raycaster2D, RaycasterScene,
    SceneBuildParams, WorldSprite,
};
use crate::render::obj_loader::Vec3;
use crate::runtime::resource_keys::TextureKey;
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
fn texture_key_from_raw_id(raw_id: u64) -> (TextureKey, u64) {
    (TextureKey::from(slotmap::KeyData::from_ffi(raw_id)), raw_id)
}
fn parse_texture_key_value(
    value: &LuaValue,
    api_name: &str,
) -> LuaResult<Option<(TextureKey, u64)>> {
    match value {
        LuaValue::Nil => Ok(None),
        LuaValue::Integer(v) => {
            if *v < 0 {
                return Err(LuaError::RuntimeError(format!(
                    "{}: texture id must be >= 0",
                    api_name
                )));
            }
            Ok(Some(texture_key_from_raw_id(*v as u64)))
        }
        LuaValue::Number(v) => {
            if !v.is_finite() || *v < 0.0 || v.fract() != 0.0 {
                return Err(LuaError::RuntimeError(format!(
                    "{}: texture must be an integer id, LImage userdata, or nil",
                    api_name
                )));
            }
            Ok(Some(texture_key_from_raw_id(*v as u64)))
        }
        LuaValue::UserData(ud) => {
            let img = ud.borrow::<LuaImage>().map_err(|_| {
                LuaError::RuntimeError(format!(
                    "{}: texture userdata must be LImage from lurek.render.newImage()",
                    api_name
                ))
            })?;
            let key = img.key;
            let raw = key.data().as_ffi();
            Ok(Some((key, raw)))
        }
        _ => Err(LuaError::RuntimeError(format!(
            "{}: texture must be an integer id, LImage userdata, or nil",
            api_name
        ))),
    }
}
fn ray_hit_to_table<'lua>(lua: &'lua Lua, hit: &RayHit) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    t.set("distance", hit.distance)?;
    t.set("raw_distance", hit.raw_distance)?;
    t.set("cell_value", hit.cell_value)?;
    t.set("alpha", hit.alpha)?;
    t.set("side", hit.side)?;
    t.set("tex_u", hit.tex_u)?;
    t.set("hit_x", hit.hit_x)?;
    t.set("hit_y", hit.hit_y)?;
    t.set("hit", hit.hit)?;
    Ok(t)
}
fn parse_point_lights(value: LuaValue, api_name: &str) -> LuaResult<Vec<PointLight>> {
    match value {
        LuaValue::Nil => Ok(Vec::new()),
        LuaValue::Table(tbl) => {
            let mut out = Vec::new();
            for pair in tbl.sequence_values::<LuaTable>() {
                let lt = pair?;
                out.push(PointLight {
                    x: lt.get::<_, f32>("x").map_err(|_| {
                        LuaError::RuntimeError(format!("{}: lights[].x is required", api_name))
                    })?,
                    y: lt.get::<_, f32>("y").map_err(|_| {
                        LuaError::RuntimeError(format!("{}: lights[].y is required", api_name))
                    })?,
                    radius: lt.get::<_, Option<f32>>("radius")?.unwrap_or(0.0).max(0.0),
                    color: [
                        lt.get::<_, Option<f32>>("r")?.unwrap_or(1.0),
                        lt.get::<_, Option<f32>>("g")?.unwrap_or(1.0),
                        lt.get::<_, Option<f32>>("b")?.unwrap_or(1.0),
                    ],
                    intensity: lt.get::<_, Option<f32>>("intensity")?.unwrap_or(1.0),
                });
            }
            Ok(out)
        }
        _ => Err(LuaError::RuntimeError(format!(
            "{}: lights must be an array table or nil",
            api_name
        ))),
    }
}
pub struct LuaDoorManager {
    inner: Rc<RefCell<DoorManager>>,
}
impl LuaUserData for LuaDoorManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "addDoor",
            |_, this, (x, y, dir_str, speed): (u32, u32, String, f32)| {
                let dir = match dir_str.as_str() {
                    "vertical" => DoorDirection::Vertical,
                    _ => DoorDirection::Horizontal,
                };
                Ok(this.inner.borrow_mut().add_door(x, y, dir, speed))
            },
        );
        methods.add_method_mut("openDoor", |_, this, index: usize| {
            this.inner.borrow_mut().open_door(index);
            Ok(())
        });
        methods.add_method_mut("closeDoor", |_, this, index: usize| {
            this.inner.borrow_mut().close_door(index);
            Ok(())
        });
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("getDoor", |lua, this, index: usize| {
            let mgr = this.inner.borrow();
            if let Some(door) = mgr.doors().get(index) {
                let tbl = lua.create_table()?;
                tbl.set("x", door.x)?;
                tbl.set("y", door.y)?;
                tbl.set("openAmount", door.open_amount)?;
                let state_str = match door.state {
                    DoorState::Closed => "closed",
                    DoorState::Opening => "opening",
                    DoorState::Open => "open",
                    DoorState::Closing => "closing",
                };
                tbl.set("state", state_str)?;
                Ok(LuaValue::Table(tbl))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().doors().len()));
        methods.add_method("type", |_, _, ()| Ok("LDoorManager"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDoorManager" || name == "DoorManager" || name == "Object")
        });
    }
}
pub struct LuaHeightMap {
    inner: Rc<RefCell<HeightMap>>,
}
impl LuaUserData for LuaHeightMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("setFloor", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_floor(x, y, h);
            Ok(())
        });
        methods.add_method_mut("setCeiling", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_ceiling(x, y, h);
            Ok(())
        });
        methods.add_method("floorAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().floor_at(x, y))
        });
        methods.add_method("ceilingAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().ceiling_at(x, y))
        });
        methods.add_method("type", |_, _, ()| Ok("LHeightMap"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHeightMap" || name == "HeightMap" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaPointLight {
    inner: PointLight,
}
impl LuaUserData for LuaPointLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));
        methods.add_method("intensity", |_, this, ()| Ok(this.inner.intensity));
        methods.add_method("color", |_, this, ()| {
            Ok((
                this.inner.color[0],
                this.inner.color[1],
                this.inner.color[2],
            ))
        });
        methods.add_method_mut(
            "set",
            |_, this, (x, y, r, g, b, radius, intensity): (f32, f32, f32, f32, f32, f32, f32)| {
                this.inner.x = x;
                this.inner.y = y;
                this.inner.color = [r, g, b];
                this.inner.radius = radius;
                this.inner.intensity = intensity;
                Ok(())
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LPointLight"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPointLight" || name == "PointLight" || name == "Object")
        });
    }
}
pub struct LuaRaycaster {
    inner: Raycaster2D,
    state: Rc<RefCell<SharedState>>,
    floor_cell_textures: HashMap<(u32, u32), (TextureKey, u64)>,
    ceiling_cell_textures: HashMap<(u32, u32), (TextureKey, u64)>,
    lowered_floor_cells: HashMap<(u32, u32), LuaLoweredFloorCell>,
}
#[derive(Clone, Copy)]
struct LuaLoweredFloorCell {
    texture_key: TextureKey,
    raw_id: u64,
    depth_offset: f32,
    tint: [f32; 3],
    blocked: bool,
}
impl LuaUserData for LuaRaycaster {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.set_cell(x, y, val);
            Ok(())
        });
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_cell(x, y))
        });
        methods.add_method_mut("setCells", |_, this, cells_tbl: LuaTable| {
            let cells: Vec<u32> = cells_tbl
                .sequence_values::<u32>()
                .collect::<LuaResult<_>>()?;
            this.inner.set_cells(cells);
            Ok(())
        });
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.is_blocked(x, y))
        });
        methods.add_method("width", |_, this, ()| Ok(this.inner.width()));
        methods.add_method("height", |_, this, ()| Ok(this.inner.height()));
        methods.add_method_mut(
            "setFloorTextureCell",
            |_, this, (x, y, texture): (u32, u32, LuaValue)| {
                match parse_texture_key_value(&texture, "lurek.raycaster.setFloorTextureCell")? {
                    Some((key, raw_id)) => {
                        this.floor_cell_textures.insert((x, y), (key, raw_id));
                    }
                    None => {
                        this.floor_cell_textures.remove(&(x, y));
                    }
                }
                Ok(())
            },
        );
        methods.add_method("getFloorTextureCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.floor_cell_textures.get(&(x, y)).map(|entry| entry.1))
        });
        methods.add_method_mut(
            "setCeilingTextureCell",
            |_, this, (x, y, texture): (u32, u32, LuaValue)| {
                match parse_texture_key_value(&texture, "lurek.raycaster.setCeilingTextureCell")? {
                    Some((key, raw_id)) => {
                        this.ceiling_cell_textures.insert((x, y), (key, raw_id));
                    }
                    None => {
                        this.ceiling_cell_textures.remove(&(x, y));
                    }
                }
                Ok(())
            },
        );
        methods.add_method("getCeilingTextureCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.ceiling_cell_textures.get(&(x, y)).map(|entry| entry.1))
        });
        methods.add_method_mut(
            "setLoweredFloorCell",
            |_, this, (x, y, opts): (u32, u32, LuaValue)| {
                match opts {
                    LuaValue::Nil => {
                        this.lowered_floor_cells.remove(&(x, y));
                    }
                    LuaValue::Table(tbl) => {
                        let tex_val = tbl.get::<_, LuaValue>("texture")?;
                        let (texture_key, raw_id) = parse_texture_key_value(
                            &tex_val,
                            "lurek.raycaster.setLoweredFloorCell(texture)",
                        )?
                        .ok_or_else(|| {
                            LuaError::RuntimeError(
                                "lurek.raycaster.setLoweredFloorCell: opts.texture cannot be nil"
                                    .to_string(),
                            )
                        })?;
                        let depth_offset = tbl
                            .get::<_, Option<f32>>("depth")?
                            .unwrap_or(0.25)
                            .clamp(0.0, 0.75);
                        let tint = [
                            tbl.get::<_, Option<f32>>("r")?
                                .unwrap_or(1.0)
                                .clamp(0.0, 1.0),
                            tbl.get::<_, Option<f32>>("g")?
                                .unwrap_or(1.0)
                                .clamp(0.0, 1.0),
                            tbl.get::<_, Option<f32>>("b")?
                                .unwrap_or(1.0)
                                .clamp(0.0, 1.0),
                        ];
                        let blocked = tbl.get::<_, Option<bool>>("blocked")?.unwrap_or(true);
                        this.lowered_floor_cells.insert(
                            (x, y),
                            LuaLoweredFloorCell {
                                texture_key,
                                raw_id,
                                depth_offset,
                                tint,
                                blocked,
                            },
                        );
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "lurek.raycaster.setLoweredFloorCell: opts must be a table or nil"
                                .to_string(),
                        ));
                    }
                }
                Ok(())
            },
        );
        methods.add_method("getLoweredFloorCell", |lua, this, (x, y): (u32, u32)| {
            if let Some(cell) = this.lowered_floor_cells.get(&(x, y)) {
                let tbl = lua.create_table()?;
                tbl.set("texture", cell.raw_id)?;
                tbl.set("depth", cell.depth_offset)?;
                tbl.set("r", cell.tint[0])?;
                tbl.set("g", cell.tint[1])?;
                tbl.set("b", cell.tint[2])?;
                tbl.set("blocked", cell.blocked)?;
                Ok(LuaValue::Table(tbl))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("isWalkBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.is_blocked(x, y)
                || this
                    .lowered_floor_cells
                    .get(&(x, y))
                    .map(|cell| cell.blocked)
                    .unwrap_or(false))
        });
        methods.add_method(
            "tryMove",
            |_, this, (px, py, dx, dy): (f32, f32, f32, f32)| {
                let width = this.inner.width();
                let height = this.inner.height();
                let (nx, ny, moved) = try_move(width, height, px, py, dx, dy, |x, y| {
                    this.inner.is_blocked(x, y)
                        || this
                            .lowered_floor_cells
                            .get(&(x, y))
                            .map(|cell| cell.blocked)
                            .unwrap_or(false)
                });
                Ok((nx, ny, moved))
            },
        );
        methods.add_method(
            "gridMove",
            |_, this, (px, py, dir, action, step): (f32, f32, u8, String, f32)| {
                let parsed = GridMoveAction::parse(action.as_str()).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "lurek.raycaster.gridMove: action must be one of 'forward', 'back', 'left', 'right'"
                            .to_string(),
                    )
                })?;
                if !(1..=4).contains(&dir) {
                    return Err(LuaError::RuntimeError(
                        "lurek.raycaster.gridMove: dir must be in range 1..4".to_string(),
                    ));
                }
                let (dx, dy) = dir4_delta(dir, parsed, step);
                let width = this.inner.width();
                let height = this.inner.height();
                let (nx, ny, moved) = try_move(width, height, px, py, dx, dy, |x, y| {
                    this.inner.is_blocked(x, y)
                        || this
                            .lowered_floor_cells
                            .get(&(x, y))
                            .map(|cell| cell.blocked)
                            .unwrap_or(false)
                });
                Ok((nx, ny, moved))
            },
        );
        methods.add_method(
            "castRay",
            |lua, this, (ox, oy, angle, max_dist): (f32, f32, f32, f32)| match this
                .inner
                .cast_ray(ox, oy, angle, max_dist)
            {
                Some(hit) => Ok(LuaValue::Table(ray_hit_to_table(lua, &hit)?)),
                None => Ok(LuaValue::Nil),
            },
        );
        methods.add_method(
            "castRays",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, f32)| {
                let hits = this.inner.cast_rays(ox, oy, angle, fov, count, max_dist);
                let tbl = lua.create_table()?;
                for (i, hit) in hits.iter().enumerate() {
                    tbl.set(i + 1, ray_hit_to_table(lua, hit)?)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method(
            "castRaysFlat",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, f32)| {
                let flat = this
                    .inner
                    .cast_rays_flat(ox, oy, angle, fov, count, max_dist);
                lua.create_sequence_from(flat)
            },
        );
        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                Ok(this.inner.line_of_sight(x1, y1, x2, y2))
            },
        );
        methods.add_method(
            "revealCellsFromRays",
            |lua,
             this,
             (ox, oy, angle, fov, count, max_dist, step): (
                f32,
                f32,
                f32,
                f32,
                u32,
                f32,
                Option<f32>,
            )| {
                let cells = reveal_cells_from_rays(
                    &this.inner,
                    ox,
                    oy,
                    angle,
                    fov,
                    count,
                    max_dist,
                    step.unwrap_or(0.2),
                );
                let out = lua.create_table()?;
                for (i, (x, y)) in cells.iter().enumerate() {
                    let row = lua.create_table()?;
                    row.set("x", *x)?;
                    row.set("y", *y)?;
                    out.set(i + 1, row)?;
                }
                Ok(out)
            },
        );
        methods.add_method(
            "computeTileLight",
            |_, this, (x, y, ambient, lights_tbl): (u32, u32, f32, LuaValue)| {
                let lights = parse_point_lights(lights_tbl, "lurek.raycaster.computeTileLight")?;
                let rgb = compute_tile_light(&this.inner, x, y, ambient, &lights);
                let luma = ((rgb[0] + rgb[1] + rgb[2]) / 3.0).clamp(0.0, 1.0);
                Ok((rgb[0], rgb[1], rgb[2], luma))
            },
        );
        methods.add_method(
            "buildMinimapWindow",
            |lua,
             this,
             (center_x, center_y, radius, ambient, lights_tbl):
                 (f32, f32, u32, f32, LuaValue)| {
                let lights = parse_point_lights(lights_tbl, "lurek.raycaster.buildMinimapWindow")?;
                let samples =
                    build_minimap_tile_window(&this.inner, center_x, center_y, radius, ambient, &lights);
                let out = lua.create_table()?;
                for (i, s) in samples.iter().enumerate() {
                    let row = lua.create_table()?;
                    row.set("x", s.x)?;
                    row.set("y", s.y)?;
                    row.set("blocked", s.blocked)?;
                    row.set("visible", s.visible)?;
                    row.set("r", s.light[0])?;
                    row.set("g", s.light[1])?;
                    row.set("b", s.light[2])?;
                    row.set("luma", s.luma)?;
                    out.set(i + 1, row)?;
                }
                Ok(out)
            },
        );
        methods.add_method_mut("setWallAlpha", |_, this, (tile_type, alpha): (u8, f32)| {
            this.inner.set_wall_alpha(tile_type, alpha);
            Ok(())
        });
        methods.add_method("getWallAlpha", |_, this, tile_type: u8| {
            Ok(this.inner.get_wall_alpha(tile_type))
        });
        methods.add_method(
            "castRayMulti",
            |lua, this, (ox, oy, angle, max_dist, max_hits): (f32, f32, f32, f32, Option<u32>)| {
                let cap = max_hits.unwrap_or(4).min(8);
                let hits = this.inner.cast_ray_multi(ox, oy, angle, max_dist, cap);
                let tbl = lua.create_table()?;
                for (i, hit) in hits.iter().enumerate() {
                    tbl.set(i + 1, ray_hit_to_table(lua, hit)?)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method(
            "castFloorRow",
            |lua,
             this,
             (cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row): (
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                i32,
            )| {
                let uvs = this
                    .inner
                    .cast_floor_row(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row);
                let tbl = lua.create_table()?;
                for (i, (u, v)) in uvs.iter().enumerate() {
                    let t = lua.create_table()?;
                    t.set("u", *u)?;
                    t.set("v", *v)?;
                    tbl.set(i + 1, t)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method(
            "projectSprite",
            |lua,
             this,
             (sx, sy, px, py, pa, fov, screen_w): (f32, f32, f32, f32, f32, f32, f32)| {
                let sp = this.inner.project_sprite(sx, sy, px, py, pa, fov, screen_w);
                let t = lua.create_table()?;
                t.set("screen_x", sp.screen_x)?;
                t.set("scale", sp.scale)?;
                t.set("distance", sp.distance)?;
                t.set("visible", sp.visible)?;
                Ok(t)
            },
        );
        methods.add_method(
            "drawTopDown",
            |_, this, (px, py, angle, scale): (f32, f32, f32, u32)| {
                let img = this.inner.draw_top_down_to_image(px, py, angle, scale);
                Ok(img)
            },
        );
        methods.add_method(
            "drawView",
            |_, this, (px, py, angle, fov, w, h, max_dist): (f32, f32, f32, f32, u32, u32, f32)| {
                let img = this
                    .inner
                    .draw_view_to_image(px, py, angle, fov, w, h, max_dist);
                Ok(img)
            },
        );
        methods.add_method(
            "drawDepthMap",
            |_,
             this,
             (px, py, angle, fov, num_rays, w, h, max_dist): (
                f32,
                f32,
                f32,
                f32,
                u32,
                u32,
                u32,
                f32,
            )| {
                let img = this
                    .inner
                    .draw_depth_map_to_image(px, py, angle, fov, num_rays, w, h, max_dist);
                Ok(img)
            },
        );
        methods.add_method(
            "drawLineOfSight",
            |_, this, (ax, ay, bx, by, scale): (f32, f32, f32, f32, u32)| {
                let img = this
                    .inner
                    .draw_line_of_sight_to_image(ax, ay, bx, by, scale);
                Ok(img)
            },
        );
        methods.add_method("drawCameraSweep", |_, this, (x, y, fov, max_dist, num_frames, fw, fh): (f32, f32, f32, f32, u32, u32, u32)| {
                let img = this.inner.draw_camera_sweep_to_image(x, y, fov, max_dist, num_frames, fw, fh);
                Ok(img)
            },
        );
        methods.add_method(
            "buildScene",
            |_,
             this,
             (params_tbl, lights_tbl, sprites_tbl, wall_tex_tbl): (
                LuaTable,
                LuaValue,
                LuaValue,
                LuaValue,
            )| {
                let params = SceneBuildParams {
                    player_x: params_tbl.get::<_, f32>("px")?,
                    player_y: params_tbl.get::<_, f32>("py")?,
                    player_angle: params_tbl.get::<_, f32>("angle")?,
                    fov: params_tbl.get::<_, f32>("fov")?,
                    ray_count: params_tbl.get::<_, u32>("rays")?,
                    max_distance: params_tbl.get::<_, f32>("max_dist")?,
                    screen_width: params_tbl.get::<_, f32>("screen_w")?,
                    screen_height: params_tbl.get::<_, f32>("screen_h")?,
                    ambient_light: params_tbl.get::<_, Option<f32>>("ambient")?.unwrap_or(0.3),
                    shade_distance: params_tbl
                        .get::<_, Option<f32>>("shade_dist")?
                        .unwrap_or(8.0),
                    floor_color: Color::new(
                        params_tbl.get::<_, Option<f32>>("floor_r")?.unwrap_or(0.2),
                        params_tbl.get::<_, Option<f32>>("floor_g")?.unwrap_or(0.2),
                        params_tbl.get::<_, Option<f32>>("floor_b")?.unwrap_or(0.2),
                        1.0,
                    ),
                    ceiling_color: Color::new(
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_r")?
                            .unwrap_or(0.1),
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_g")?
                            .unwrap_or(0.1),
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_b")?
                            .unwrap_or(0.15),
                        1.0,
                    ),
                    camera_height: params_tbl
                        .get::<_, Option<f32>>("camera_height")?
                        .unwrap_or(0.5),
                    horizon_offset: params_tbl
                        .get::<_, Option<f32>>("horizon_offset")?
                        .unwrap_or(0.0),
                };
                let lights: Vec<PointLight> = match lights_tbl {
                    LuaValue::Table(tbl) => {
                        let mut v = Vec::new();
                        for pair in tbl.sequence_values::<LuaTable>() {
                            let lt = pair?;
                            v.push(PointLight {
                                x: lt.get::<_, f32>("x")?,
                                y: lt.get::<_, f32>("y")?,
                                radius: lt.get::<_, f32>("radius")?,
                                color: [
                                    lt.get::<_, Option<f32>>("r")?.unwrap_or(1.0),
                                    lt.get::<_, Option<f32>>("g")?.unwrap_or(1.0),
                                    lt.get::<_, Option<f32>>("b")?.unwrap_or(1.0),
                                ],
                                intensity: lt.get::<_, Option<f32>>("intensity")?.unwrap_or(1.0),
                            });
                        }
                        v
                    }
                    _ => Vec::new(),
                };
                let sprites: Vec<WorldSprite> = match sprites_tbl {
                    LuaValue::Table(tbl) => {
                        let mut v = Vec::new();
                        for pair in tbl.sequence_values::<LuaTable>() {
                            let st = pair?;
                            let tex_val = st.get::<_, LuaValue>("texture")?;
                            let (key, _) = parse_texture_key_value(
                                &tex_val,
                                "lurek.raycaster.buildScene(sprites[].texture)",
                            )?
                            .ok_or_else(|| {
                                LuaError::RuntimeError(
                                    "lurek.raycaster.buildScene: sprites[].texture cannot be nil"
                                        .to_string(),
                                )
                            })?;
                            v.push(WorldSprite {
                                world_x: st.get::<_, f32>("x")?,
                                world_y: st.get::<_, f32>("y")?,
                                texture_key: key,
                                size: st.get::<_, Option<f32>>("size")?.unwrap_or(1.0),
                            });
                        }
                        v
                    }
                    _ => Vec::new(),
                };
                let wall_tex_map: std::collections::HashMap<u32, TextureKey> = match wall_tex_tbl {
                    LuaValue::Table(tbl) => {
                        let mut m = std::collections::HashMap::new();
                        for pair in tbl.pairs::<u32, LuaValue>() {
                            let (cell_val, tex_val) = pair?;
                            let (key, _) = parse_texture_key_value(
                                &tex_val,
                                "lurek.raycaster.buildScene(wall_textures)",
                            )?
                            .ok_or_else(|| {
                                LuaError::RuntimeError(format!(
                                    "lurek.raycaster.buildScene: wall_textures[{}] cannot be nil",
                                    cell_val
                                ))
                            })?;
                            m.insert(cell_val, key);
                        }
                        m
                    }
                    _ => std::collections::HashMap::new(),
                };
                let scene = RaycasterScene::build(
                    &this.inner,
                    &params,
                    &lights,
                    &sprites,
                    &|cell_value| wall_tex_map.get(&cell_value).copied(),
                    &|x, y| this.floor_cell_textures.get(&(x, y)).map(|entry| entry.0),
                    &|x, y| this.ceiling_cell_textures.get(&(x, y)).map(|entry| entry.0),
                    &|x, y| {
                        this.lowered_floor_cells.get(&(x, y)).map(|cell| {
                            crate::raycaster::build_scene::LoweredFloorCell {
                                texture_key: cell.texture_key,
                                depth_offset: cell.depth_offset,
                                tint: cell.tint,
                                blocked: cell.blocked,
                            }
                        })
                    },
                );
                let quad_count = scene.quad_count();
                this.state.borrow_mut().raycaster_output = Some(scene);
                Ok(quad_count)
            },
        );
        methods.add_method(
            "buildSceneWithModels",
            |_,
             this,
             (params_tbl, lights_tbl, sprites_tbl, wall_tex_tbl, models_tbl): (
                LuaTable,
                LuaValue,
                LuaValue,
                LuaValue,
                LuaValue,
            )| {
                let params = SceneBuildParams {
                    player_x: params_tbl.get::<_, f32>("px")?,
                    player_y: params_tbl.get::<_, f32>("py")?,
                    player_angle: params_tbl.get::<_, f32>("angle")?,
                    fov: params_tbl.get::<_, f32>("fov")?,
                    ray_count: params_tbl.get::<_, u32>("rays")?,
                    max_distance: params_tbl.get::<_, f32>("max_dist")?,
                    screen_width: params_tbl.get::<_, f32>("screen_w")?,
                    screen_height: params_tbl.get::<_, f32>("screen_h")?,
                    ambient_light: params_tbl.get::<_, Option<f32>>("ambient")?.unwrap_or(0.3),
                    shade_distance: params_tbl
                        .get::<_, Option<f32>>("shade_dist")?
                        .unwrap_or(8.0),
                    floor_color: Color::new(
                        params_tbl.get::<_, Option<f32>>("floor_r")?.unwrap_or(0.2),
                        params_tbl.get::<_, Option<f32>>("floor_g")?.unwrap_or(0.2),
                        params_tbl.get::<_, Option<f32>>("floor_b")?.unwrap_or(0.2),
                        1.0,
                    ),
                    ceiling_color: Color::new(
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_r")?
                            .unwrap_or(0.1),
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_g")?
                            .unwrap_or(0.1),
                        params_tbl
                            .get::<_, Option<f32>>("ceiling_b")?
                            .unwrap_or(0.15),
                        1.0,
                    ),
                    camera_height: params_tbl
                        .get::<_, Option<f32>>("camera_height")?
                        .unwrap_or(0.5),
                    horizon_offset: params_tbl
                        .get::<_, Option<f32>>("horizon_offset")?
                        .unwrap_or(0.0),
                };
                let lights: Vec<PointLight> = match lights_tbl {
                    LuaValue::Table(tbl) => {
                        let mut v = Vec::new();
                        for pair in tbl.sequence_values::<LuaTable>() {
                            let lt = pair?;
                            v.push(PointLight {
                                x: lt.get::<_, f32>("x")?,
                                y: lt.get::<_, f32>("y")?,
                                radius: lt.get::<_, f32>("radius")?,
                                color: [
                                    lt.get::<_, Option<f32>>("r")?.unwrap_or(1.0),
                                    lt.get::<_, Option<f32>>("g")?.unwrap_or(1.0),
                                    lt.get::<_, Option<f32>>("b")?.unwrap_or(1.0),
                                ],
                                intensity: lt.get::<_, Option<f32>>("intensity")?.unwrap_or(1.0),
                            });
                        }
                        v
                    }
                    _ => Vec::new(),
                };
                let sprites: Vec<WorldSprite> = match sprites_tbl {
                    LuaValue::Table(tbl) => {
                        let mut v = Vec::new();
                        for pair in tbl.sequence_values::<LuaTable>() {
                            let st = pair?;
                            let tex_val = st.get::<_, LuaValue>("texture")?;
                            let (key, _) = parse_texture_key_value(
                                &tex_val,
                                "lurek.raycaster.buildSceneWithModels(sprites[].texture)",
                            )?
                            .ok_or_else(|| {
                                LuaError::RuntimeError(
                                    "lurek.raycaster.buildSceneWithModels: sprites[].texture cannot be nil"
                                        .to_string(),
                                )
                            })?;
                            v.push(WorldSprite {
                                world_x: st.get::<_, f32>("x")?,
                                world_y: st.get::<_, f32>("y")?,
                                texture_key: key,
                                size: st.get::<_, Option<f32>>("size")?.unwrap_or(1.0),
                            });
                        }
                        v
                    }
                    _ => Vec::new(),
                };
                let wall_tex_map: std::collections::HashMap<u32, TextureKey> = match wall_tex_tbl {
                    LuaValue::Table(tbl) => {
                        let mut m = std::collections::HashMap::new();
                        for pair in tbl.pairs::<u32, LuaValue>() {
                            let (cell_val, tex_val) = pair?;
                            let (key, _) = parse_texture_key_value(
                                &tex_val,
                                "lurek.raycaster.buildSceneWithModels(wall_textures)",
                            )?
                            .ok_or_else(|| {
                                LuaError::RuntimeError(format!(
                                    "lurek.raycaster.buildSceneWithModels: wall_textures[{}] cannot be nil",
                                    cell_val
                                ))
                            })?;
                            m.insert(cell_val, key);
                        }
                        m
                    }
                    _ => std::collections::HashMap::new(),
                };
                let mut scene =
                    RaycasterScene::build(&this.inner, &params, &lights, &sprites, &|cell_value| {
                        wall_tex_map.get(&cell_value).copied()
                    }, &|x, y| this.floor_cell_textures.get(&(x, y)).map(|entry| entry.0), &|x, y| {
                        this.ceiling_cell_textures.get(&(x, y)).map(|entry| entry.0)
                    }, &|x, y| {
                        this.lowered_floor_cells.get(&(x, y)).map(|cell| crate::raycaster::build_scene::LoweredFloorCell {
                            texture_key: cell.texture_key,
                            depth_offset: cell.depth_offset,
                            tint: cell.tint,
                            blocked: cell.blocked,
                        })
                    });
                if let LuaValue::Table(tbl) = models_tbl {
                    let cam_pos = Vec3::new(params.player_x, params.camera_height, params.player_y);
                    let cam_target = Vec3::new(
                        params.player_x + params.player_angle.cos(),
                        params.camera_height,
                        params.player_y + params.player_angle.sin(),
                    );
                    for pair in tbl.sequence_values::<LuaTable>() {
                        let mt = pair?;
                        let model_ud = mt.get::<_, LuaAnyUserData>("model")?;
                        let model_ref = model_ud.borrow::<LObjModel>().map_err(|_| {
                            LuaError::RuntimeError(
                                "lurek.raycaster.buildSceneWithModels: models[].model must be LObjModel"
                                    .to_string(),
                            )
                        })?;
                        let (mut mesh, depth) = model_ref.model.project_instance_to_mesh(
                            cam_pos,
                            cam_target,
                            params.fov,
                            params.screen_width,
                            params.screen_height,
                            mt.get::<_, f32>("x")?,
                            mt.get::<_, f32>("y")?,
                            mt.get::<_, Option<u8>>("rotation")?.unwrap_or(0),
                            mt.get::<_, Option<f32>>("scale")?.unwrap_or(1.0),
                        );
                        if mesh.vertices.is_empty() {
                            continue;
                        }
                        let model_cell_x = mt.get::<_, f32>("x")?.floor().max(0.0) as u32;
                        let model_cell_y = mt.get::<_, f32>("y")?.floor().max(0.0) as u32;
                        let model_ambient = if this
                            .ceiling_cell_textures
                            .contains_key(&(model_cell_x, model_cell_y))
                        {
                            params.ambient_light * 0.5
                        } else {
                            params.ambient_light
                        };
                        let model_x = mt.get::<_, f32>("x")?;
                        let model_y = mt.get::<_, f32>("y")?;
                        let wall_at = |cx: i32, cy: i32| -> bool {
                            this.inner.get_cell(cx as u32, cy as u32) != 0
                        };
                        let model_light = compute_lighting(model_x, model_y, model_ambient, &lights, &wall_at);
                        for v in &mut mesh.vertices {
                            v.r *= model_light[0];
                            v.g *= model_light[1];
                            v.b *= model_light[2];
                        }
                        scene.models.push(ModelMesh { mesh, depth });
                    }
                }
                let quad_count = scene.quad_count();
                this.state.borrow_mut().raycaster_output = Some(scene);
                Ok(quad_count)
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LRaycaster"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRaycaster" || name == "Object")
        });
    }
}
pub struct LuaSpriteManager {
    inner: SpriteManager,
}
impl LuaUserData for LuaSpriteManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "add",
            |_, this, (x, y, texture, scale): (f32, f32, String, Option<f32>)| {
                Ok(this.inner.add(x, y, &texture, scale.unwrap_or(1.0)))
            },
        );
        methods.add_method_mut("remove", |_, this, id: u32| {
            this.inner.remove(id);
            Ok(())
        });
        methods.add_method_mut("setPosition", |_, this, (id, x, y): (u32, f32, f32)| {
            this.inner.set_position(id, x, y);
            Ok(())
        });
        methods.add_method_mut("setVisible", |_, this, (id, visible): (u32, bool)| {
            this.inner.set_visible(id, visible);
            Ok(())
        });
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method(
            "sortAndProject",
            |lua, this, (cam_x, cam_y, _cam_angle): (f32, f32, f32)| {
                let sorted = this.inner.sort_by_distance(cam_x, cam_y);
                let tbl = lua.create_table()?;
                for (i, s) in sorted.iter().enumerate() {
                    let dx = s.x - cam_x;
                    let dy = s.y - cam_y;
                    let dist = (dx * dx + dy * dy).sqrt();
                    let entry = lua.create_table()?;
                    entry.set("id", s.id)?;
                    entry.set("x", s.x)?;
                    entry.set("y", s.y)?;
                    entry.set("texture", s.texture.clone())?;
                    entry.set("scale", s.scale)?;
                    entry.set("distance", dist)?;
                    tbl.set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );
        methods.add_method("type", |_, _, ()| Ok("LSpriteManager"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteManager" || name == "SpriteManager" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "new",
        lua.create_function(move |_, (w, h): (u32, u32)| {
            Ok(LuaRaycaster {
                inner: Raycaster2D::new(w, h),
                state: s.clone(),
                floor_cell_textures: HashMap::new(),
                ceiling_cell_textures: HashMap::new(),
                lowered_floor_cells: HashMap::new(),
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newMap",
        lua.create_function(move |_, (w, h): (u32, u32)| {
            Ok(LuaRaycaster {
                inner: Raycaster2D::new(w, h),
                state: s.clone(),
                floor_cell_textures: HashMap::new(),
                ceiling_cell_textures: HashMap::new(),
                lowered_floor_cells: HashMap::new(),
            })
        })?,
    )?;
    tbl.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_height): (f32, f32, f32)| {
            Ok(project_column(distance, fov, screen_height))
        })?,
    )?;
    tbl.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_distance): (f32, f32)| {
            Ok(distance_shade(distance, max_distance))
        })?,
    )?;
    tbl.set(
        "newDoorManager",
        lua.create_function(|_, ()| {
            Ok(LuaDoorManager {
                inner: Rc::new(RefCell::new(DoorManager::new())),
            })
        })?,
    )?;
    tbl.set(
        "newHeightMap",
        lua.create_function(|_, (w, h): (u32, u32)| {
            Ok(LuaHeightMap {
                inner: Rc::new(RefCell::new(HeightMap::new(w, h))),
            })
        })?,
    )?;
    tbl.set(
        "newPointLight",
        lua.create_function(
            |_, (x, y, r, g, b, radius, intensity): (f32, f32, f32, f32, f32, f32, f32)| {
                Ok(LuaPointLight {
                    inner: PointLight {
                        x,
                        y,
                        radius,
                        intensity,
                        color: [r, g, b],
                    },
                })
            },
        )?,
    )?;
    tbl.set(
        "newSpriteManager",
        lua.create_function(|_, ()| {
            Ok(LuaSpriteManager {
                inner: SpriteManager::new(),
            })
        })?,
    )?;
    lurek.set("raycaster", tbl)?;
    Ok(())
}
