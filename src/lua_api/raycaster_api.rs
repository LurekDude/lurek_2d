//! `lurek.raycaster` - Provides a pseudo-3D raycasting engine for first-person dungeon crawlers with textured walls, floors, and ceilings.

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
/// Rebuilds a texture key and raw handle pair from the persisted numeric texture id.
fn texture_key_from_raw_id(raw_id: u64) -> (TextureKey, u64) {
    (TextureKey::from(slotmap::KeyData::from_ffi(raw_id)), raw_id)
}
/// Parses nil, numeric ids, or `LImage` userdata into a raycaster texture reference.
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
/// Serializes one raycaster hit result into the Lua table layout returned by cast helpers.
fn ray_hit_to_table<'lua>(lua: &'lua Lua, hit: &RayHit) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    /// Performs the 'distance' operation.
    /// @return | nil | No value is returned.
    t.set("distance", hit.distance)?;
    /// Performs the 'raw_distance' operation.
    /// @return | nil | No value is returned.
    t.set("raw_distance", hit.raw_distance)?;
    /// Performs the 'cell_value' operation.
    /// @return | nil | No value is returned.
    t.set("cell_value", hit.cell_value)?;
    /// Performs the 'alpha' operation.
    /// @return | nil | No value is returned.
    t.set("alpha", hit.alpha)?;
    /// Performs the 'side' operation.
    /// @return | nil | No value is returned.
    t.set("side", hit.side)?;
    /// Performs the 'tex_u' operation.
    /// @return | nil | No value is returned.
    t.set("tex_u", hit.tex_u)?;
    /// Performs the 'hit_x' operation.
    /// @return | nil | No value is returned.
    t.set("hit_x", hit.hit_x)?;
    /// Performs the 'hit_y' operation.
    /// @return | nil | No value is returned.
    t.set("hit_y", hit.hit_y)?;
    /// Performs the 'hit' operation.
    /// @return | nil | No value is returned.
    t.set("hit", hit.hit)?;
    Ok(t)
}
/// Parses a Lua array of point light tables into raycaster point light definitions.
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
/// Lua-visible door manager that controls sliding doors within a raycaster map.
/// Doors can be opened, closed, and animated over time at configurable speeds.
pub struct LuaDoorManager {
    inner: Rc<RefCell<DoorManager>>,
}
impl LuaUserData for LuaDoorManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addDoor --
        /// Registers a new sliding door at the given grid cell.
        /// @param | x | integer | Grid column of the door cell.
        /// @param | y | integer | Grid row of the door cell.
        /// @param | direction | string | Slide axis: "horizontal" or "vertical".
        /// @param | speed | number | How fast the door opens/closes (units per second).
        /// @return | integer | Zero-based index of the newly added door.
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
        // -- openDoor --
        /// Begins opening the door at the given index. The door animates over time via `update()`.
        /// @param | index | integer | Zero-based index of the door to open.
        /// @return | nil | No value is returned.
        methods.add_method_mut("openDoor", |_, this, index: usize| {
            this.inner.borrow_mut().open_door(index);
            Ok(())
        });
        // -- closeDoor --
        /// Begins closing the door at the given index. The door animates over time via `update()`.
        /// @param | index | integer | Zero-based index of the door to close.
        /// @return | nil | No value is returned.
        methods.add_method_mut("closeDoor", |_, this, index: usize| {
            this.inner.borrow_mut().close_door(index);
            Ok(())
        });
        // -- update --
        /// Advances all door animations by the given delta time. Call once per frame.
        /// @param | dt | number | Delta time in seconds since last frame.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- getDoor --
        /// Returns a table describing the door at the given index, or nil if index is out of range.
        /// The table contains: x, y, openAmount (0.0..1.0), state ("closed"|"opening"|"open"|"closing").
        /// @param | index | integer | Zero-based index of the door to query.
        /// @return | table | Door info table, or nil if not found.
        methods.add_method("getDoor", |lua, this, index: usize| {
            let mgr = this.inner.borrow();
            if let Some(door) = mgr.doors().get(index) {
                let tbl = lua.create_table()?;
                /// Performs the 'x' operation.
                /// @return | nil | No value is returned.
                tbl.set("x", door.x)?;
                /// Performs the 'y' operation.
                /// @return | nil | No value is returned.
                tbl.set("y", door.y)?;
                /// Performs the 'openAmount' operation.
                /// @return | nil | No value is returned.
                tbl.set("openAmount", door.open_amount)?;
                let state_str = match door.state {
                    DoorState::Closed => "closed",
                    DoorState::Opening => "opening",
                    DoorState::Open => "open",
                    DoorState::Closing => "closing",
                };
                /// Performs the 'state' operation.
                /// @return | nil | No value is returned.
                tbl.set("state", state_str)?;
                Ok(LuaValue::Table(tbl))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- count --
        /// Returns the total number of registered doors.
        /// @return | integer | Door count.
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().doors().len()));
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LDoorManager".
        methods.add_method("type", |_, _, ()| Ok("LDoorManager"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDoorManager" || name == "DoorManager" || name == "Object")
        });
    }
}
/// Lua-visible height map that stores per-cell floor and ceiling offsets for variable-height raycaster levels.
pub struct LuaHeightMap {
    inner: Rc<RefCell<HeightMap>>,
}
impl LuaUserData for LuaHeightMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setFloor --
        /// Sets the floor height offset at a specific grid cell.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | h | number | Floor height offset (0.0 = default floor level).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFloor", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_floor(x, y, h);
            Ok(())
        });
        // -- setCeiling --
        /// Sets the ceiling height offset at a specific grid cell.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | h | number | Ceiling height offset (0.0 = default ceiling level).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCeiling", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_ceiling(x, y, h);
            Ok(())
        });
        // -- floorAt --
        /// Returns the floor height offset at a given grid cell.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | number | Floor height offset at that cell.
        methods.add_method("floorAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().floor_at(x, y))
        });
        // -- ceilingAt --
        /// Returns the ceiling height offset at a given grid cell.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | number | Ceiling height offset at that cell.
        methods.add_method("ceilingAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().ceiling_at(x, y))
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LHeightMap".
        methods.add_method("type", |_, _, ()| Ok("LHeightMap"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHeightMap" || name == "HeightMap" || name == "Object")
        });
    }
}
/// Lua-visible point light that illuminates nearby raycaster tiles and sprites with colored light and falloff.
#[derive(Clone)]
pub struct LuaPointLight {
    inner: PointLight,
}
impl LuaUserData for LuaPointLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- x --
        /// Returns the X world position of this light.
        /// @return | number | X coordinate.
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));
        // -- y --
        /// Returns the Y world position of this light.
        /// @return | number | Y coordinate.
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));
        // -- radius --
        /// Returns the light's falloff radius in world units.
        /// @return | number | Radius.
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));
        // -- intensity --
        /// Returns the brightness multiplier of this light.
        /// @return | number | Intensity.
        methods.add_method("intensity", |_, this, ()| Ok(this.inner.intensity));
        // -- color --
        /// Returns the RGB color components of this light.
        /// @return | number | Red channel (0.0..1.0).
        /// @return | number | Green channel (0.0..1.0).
        /// @return | number | Blue channel (0.0..1.0).
        methods.add_method("color", |_, this, ()| {
            Ok((
                this.inner.color[0],
                this.inner.color[1],
                this.inner.color[2],
            ))
        });
        // -- set --
        /// Overwrites all properties of this point light in a single call.
        /// @param | x | number | New X world position.
        /// @param | y | number | New Y world position.
        /// @param | r | number | Red color channel (0.0..1.0).
        /// @param | g | number | Green color channel (0.0..1.0).
        /// @param | b | number | Blue color channel (0.0..1.0).
        /// @param | radius | number | Falloff radius in world units.
        /// @param | intensity | number | Brightness multiplier.
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
        // -- type --
        /// Returns the type name of this object ("LPointLight").
        /// @return | string | Type name string.
        methods.add_method("type", |_, _, ()| Ok("LPointLight"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if this object is of the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPointLight" || name == "PointLight" || name == "Object")
        });
    }
}
/// Lua-visible raycaster map that holds cell data, per-cell textures, and provides raycasting,.
/// collision, and scene-building operations for first-person dungeon-crawler rendering.
pub struct LuaRaycaster {
    inner: Raycaster2D,
    state: Rc<RefCell<SharedState>>,
    floor_cell_textures: HashMap<(u32, u32), (TextureKey, u64)>,
    ceiling_cell_textures: HashMap<(u32, u32), (TextureKey, u64)>,
    lowered_floor_cells: HashMap<(u32, u32), LuaLoweredFloorCell>,
}
#[derive(Clone, Copy)]
/// Stores lowered-floor render overrides for a single raycaster cell.
struct LuaLoweredFloorCell {
    texture_key: TextureKey,
    raw_id: u64,
    depth_offset: f32,
    tint: [f32; 3],
    blocked: bool,
}
impl LuaUserData for LuaRaycaster {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setCell --
        /// Sets the wall type value at a grid cell. Non-zero values are solid walls.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | val | integer | Wall type (0 = empty, 1+ = wall texture index).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.set_cell(x, y, val);
            Ok(())
        });
        // -- getCell --
        /// Returns the wall type value at a grid cell.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | integer | Cell value (0 = empty, 1+ = wall type).
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_cell(x, y))
        });
        // -- setCells --
        /// Replaces the entire map grid with a flat array of cell values (row-major order).
        /// @param | cells | table | Flat array of numbers with width*height elements.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCells", |_, this, cells_tbl: LuaTable| {
            let cells: Vec<u32> = cells_tbl
                .sequence_values::<u32>()
                .collect::<LuaResult<_>>()?;
            this.inner.set_cells(cells);
            Ok(())
        });
        // -- isBlocked --
        /// Returns true if the grid cell is a solid wall (non-zero value).
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | boolean | True if cell blocks movement and rays.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.is_blocked(x, y))
        });
        // -- width --
        /// Returns the map width in grid cells.
        /// @return | integer | Map width.
        methods.add_method("width", |_, this, ()| Ok(this.inner.width()));
        // -- height --
        /// Returns the map height in grid cells.
        /// @return | integer | Map height.
        methods.add_method("height", |_, this, ()| Ok(this.inner.height()));
        // -- setFloorTextureCell --
        /// Assigns a per-cell floor texture override. Pass nil to remove the override.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | texture | LImage? | Texture image, integer id, or nil to clear.
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
        // -- getFloorTextureCell --
        /// Returns the raw texture id assigned to this floor cell, or nil if none.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | integer | Raw texture id or nil.
        methods.add_method("getFloorTextureCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.floor_cell_textures.get(&(x, y)).map(|entry| entry.1))
        });
        // -- setCeilingTextureCell --
        /// Assigns a per-cell ceiling texture override. Pass nil to remove the override.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | texture | LImage? | Texture image, integer id, or nil to clear.
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
        // -- getCeilingTextureCell --
        /// Returns the raw texture id assigned to this ceiling cell, or nil if none.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | integer | Raw texture id or nil.
        methods.add_method("getCeilingTextureCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.ceiling_cell_textures.get(&(x, y)).map(|entry| entry.1))
        });
        // -- setLoweredFloorCell --
        /// Marks a cell as a lowered floor (pit) with its own texture, depth, tint, and blocking flag.
        /// Pass nil to remove the lowered floor designation.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @param | opts | table? | Options table {texture, depth?, r?, g?, b?, blocked?} or nil to clear.
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
        // -- getLoweredFloorCell --
        /// Returns the lowered floor configuration at a cell, or nil if the cell is normal.
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | table | Table {texture, depth, r, g, b, blocked} or nil.
        methods.add_method("getLoweredFloorCell", |lua, this, (x, y): (u32, u32)| {
            if let Some(cell) = this.lowered_floor_cells.get(&(x, y)) {
                let tbl = lua.create_table()?;
                /// Performs the 'texture' operation.
                /// @return | nil | No value is returned.
                tbl.set("texture", cell.raw_id)?;
                /// Performs the 'depth' operation.
                /// @return | nil | No value is returned.
                tbl.set("depth", cell.depth_offset)?;
                /// Performs the 'r' operation.
                /// @return | nil | No value is returned.
                tbl.set("r", cell.tint[0])?;
                /// Performs the 'g' operation.
                /// @return | nil | No value is returned.
                tbl.set("g", cell.tint[1])?;
                /// Performs the 'b' operation.
                /// @return | nil | No value is returned.
                tbl.set("b", cell.tint[2])?;
                /// Performs the 'blocked' operation.
                /// @return | nil | No value is returned.
                tbl.set("blocked", cell.blocked)?;
                Ok(LuaValue::Table(tbl))
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- isWalkBlocked --
        /// Returns true if the cell blocks walking (solid wall OR blocked lowered-floor cell).
        /// @param | x | integer | Grid column.
        /// @param | y | integer | Grid row.
        /// @return | boolean | True if the cell cannot be walked through.
        methods.add_method("isWalkBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.is_blocked(x, y)
                || this
                    .lowered_floor_cells
                    .get(&(x, y))
                    .map(|cell| cell.blocked)
                    .unwrap_or(false))
        });
        // -- tryMove --
        /// Attempts to move from (px,py) by (dx,dy) with wall-slide collision. Returns the final position.
        /// @param | px | number | Current X position in world space.
        /// @param | py | number | Current Y position in world space.
        /// @param | dx | number | Desired X movement delta.
        /// @param | dy | number | Desired Y movement delta.
        /// @return | number | Final X position.
        /// @return | number | Final Y position.
        /// @return | boolean | Whether any movement occurred.
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
        // -- gridMove --
        /// Performs a discrete grid-step movement in one of 4 cardinal directions with collision.
        /// Used for tile-by-tile dungeon crawlers.
        /// @param | px | number | Current X position.
        /// @param | py | number | Current Y position.
        /// @param | dir | integer | Facing direction 1..4 (1=N, 2=E, 3=S, 4=W).
        /// @param | action | string | Movement action: "forward", "back", "left", or "right".
        /// @param | step | number | Step distance in world units (typically 1.0).
        /// @return | number | Final X position.
        /// @return | number | Final Y position.
        /// @return | boolean | Whether the move succeeded.
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
        // -- castRay --
        /// Casts a single ray from (ox,oy) at the given angle and returns hit info or nil.
        /// @param | ox | number | Ray origin X.
        /// @param | oy | number | Ray origin Y.
        /// @param | angle | number | Ray direction in radians.
        /// @param | maxDist | number | Maximum cast distance.
        /// @return | table | Hit table {distance, raw_distance, cell_value, alpha, side, tex_u, hit_x, hit_y, hit} or nil.
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
        // -- castRays --
        /// Casts multiple rays across a field of view and returns an array of hit tables.
        /// @param | ox | number | Ray origin X.
        /// @param | oy | number | Ray origin Y.
        /// @param | angle | number | Center angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | count | integer | Number of rays to cast.
        /// @param | maxDist | number | Maximum cast distance per ray.
        /// @return | table | Array of hit tables (same fields as castRay).
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
        // -- castRaysFlat --
        /// Casts multiple rays and returns only the corrected distances as a flat array.
        /// More efficient than castRays when only distances are needed.
        /// @param | ox | number | Ray origin X.
        /// @param | oy | number | Ray origin Y.
        /// @param | angle | number | Center angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | count | integer | Number of rays to cast.
        /// @param | maxDist | number | Maximum cast distance per ray.
        /// @return | table | Flat array of corrected distance values.
        methods.add_method(
            "castRaysFlat",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, f32)| {
                let flat = this
                    .inner
                    .cast_rays_flat(ox, oy, angle, fov, count, max_dist);
                lua.create_sequence_from(flat)
            },
        );
        // -- lineOfSight --
        /// Tests whether there is a clear line of sight between two world points (no walls in between).
        /// @param | x1 | number | Start X.
        /// @param | y1 | number | Start Y.
        /// @param | x2 | number | End X.
        /// @param | y2 | number | End Y.
        /// @return | boolean | True if the path is unobstructed.
        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                Ok(this.inner.line_of_sight(x1, y1, x2, y2))
            },
        );
        // -- revealCellsFromRays --
        /// Casts rays across the FOV and returns a list of grid cells that are visible (for fog-of-war).
        /// @param | ox | number | Ray origin X.
        /// @param | oy | number | Ray origin Y.
        /// @param | angle | number | Center angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | count | integer | Number of rays.
        /// @param | maxDist | number | Maximum ray distance.
        /// @param | step | number? | Walk step along each ray (default 0.2).
        /// @return | table | Array of {x, y} tables representing revealed grid cells.
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
                    /// Performs the 'x' operation.
                    /// @return | nil | No value is returned.
                    row.set("x", *x)?;
                    /// Performs the 'y' operation.
                    /// @return | nil | No value is returned.
                    row.set("y", *y)?;
                    out.set(i + 1, row)?;
                }
                Ok(out)
            },
        );
        // -- computeTileLight --
        /// Computes the combined lighting color at a tile from ambient and point lights, accounting for walls.
        /// @param | x | integer | Tile grid column.
        /// @param | y | integer | Tile grid row.
        /// @param | ambient | number | Base ambient light level (0.0..1.0).
        /// @param | lights | table? | Array of point-light tables {x, y, radius, r?, g?, b?, intensity?}.
        /// @return | number | Red light channel.
        /// @return | number | Green light channel.
        /// @return | number | Blue light channel.
        /// @return | number | Average luminance.
        methods.add_method(
            "computeTileLight",
            |_, this, (x, y, ambient, lights_tbl): (u32, u32, f32, LuaValue)| {
                let lights = parse_point_lights(lights_tbl, "lurek.raycaster.computeTileLight")?;
                let rgb = compute_tile_light(&this.inner, x, y, ambient, &lights);
                let luma = ((rgb[0] + rgb[1] + rgb[2]) / 3.0).clamp(0.0, 1.0);
                Ok((rgb[0], rgb[1], rgb[2], luma))
            },
        );
        // -- buildMinimapWindow --
        /// Generates a grid of minimap tile samples around a center point with lighting info.
        /// Useful for rendering a lit minimap overlay.
        /// @param | centerX | number | Center X in world coordinates.
        /// @param | centerY | number | Center Y in world coordinates.
        /// @param | radius | integer | Tile radius around the center to sample.
        /// @param | ambient | number | Ambient light level (0.0..1.0).
        /// @param | lights | table? | Array of point-light tables.
        /// @return | table | Array of {x, y, blocked, visible, r, g, b, luma} tables.
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
                    /// Performs the 'x' operation.
                    /// @return | nil | No value is returned.
                    row.set("x", s.x)?;
                    /// Performs the 'y' operation.
                    /// @return | nil | No value is returned.
                    row.set("y", s.y)?;
                    /// Performs the 'blocked' operation.
                    /// @return | nil | No value is returned.
                    row.set("blocked", s.blocked)?;
                    /// Performs the 'visible' operation.
                    /// @return | nil | No value is returned.
                    row.set("visible", s.visible)?;
                    /// Performs the 'r' operation.
                    /// @return | nil | No value is returned.
                    row.set("r", s.light[0])?;
                    /// Performs the 'g' operation.
                    /// @return | nil | No value is returned.
                    row.set("g", s.light[1])?;
                    /// Performs the 'b' operation.
                    /// @return | nil | No value is returned.
                    row.set("b", s.light[2])?;
                    /// Performs the 'luma' operation.
                    /// @return | nil | No value is returned.
                    row.set("luma", s.luma)?;
                    out.set(i + 1, row)?;
                }
                Ok(out)
            },
        );
        // -- setWallAlpha --
        /// Sets the transparency for a specific wall tile type, enabling see-through walls.
        /// @param | tileType | integer | The cell value (1..255) whose alpha to change.
        /// @param | alpha | number | Opacity (0.0 = fully transparent, 1.0 = fully opaque).
        /// @return | nil | No value is returned.
        methods.add_method_mut("setWallAlpha", |_, this, (tile_type, alpha): (u8, f32)| {
            this.inner.set_wall_alpha(tile_type, alpha);
            Ok(())
        });
        // -- getWallAlpha --
        /// Returns the current transparency value for a wall tile type.
        /// @param | tileType | integer | The cell value to query.
        /// @return | number | Alpha value (0.0..1.0).
        methods.add_method("getWallAlpha", |_, this, tile_type: u8| {
            Ok(this.inner.get_wall_alpha(tile_type))
        });
        // -- castRayMulti --
        /// Casts a single ray that passes through transparent walls, returning multiple hits.
        /// @param | ox | number | Ray origin X.
        /// @param | oy | number | Ray origin Y.
        /// @param | angle | number | Ray direction in radians.
        /// @param | maxDist | number | Maximum cast distance.
        /// @param | maxHits | integer? | Maximum number of hits to collect (default 4, max 8).
        /// @return | table | Array of hit tables in distance order.
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
        // -- castFloorRow --
        /// Computes floor/ceiling texture UV coordinates for a single scanline row.
        /// Used for software-rendered textured floors.
        /// @param | camX | number | Camera X position.
        /// @param | camY | number | Camera Y position.
        /// @param | dirX | number | Camera forward direction X.
        /// @param | dirY | number | Camera forward direction Y.
        /// @param | planeX | number | Camera plane X (half-width of FOV).
        /// @param | planeY | number | Camera plane Y (half-width of FOV).
        /// @param | row | integer | Scanline row offset from screen center.
        /// @return | table | Array of {u, v} tables for each pixel in the row.
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
                    /// Performs the 'u' operation.
                    /// @return | nil | No value is returned.
                    t.set("u", *u)?;
                    /// Performs the 'v' operation.
                    /// @return | nil | No value is returned.
                    t.set("v", *v)?;
                    tbl.set(i + 1, t)?;
                }
                Ok(tbl)
            },
        );
        // -- projectSprite --
        /// Projects a world-space sprite to screen coordinates for billboard rendering.
        /// @param | sx | number | Sprite world X.
        /// @param | sy | number | Sprite world Y.
        /// @param | px | number | Player X position.
        /// @param | py | number | Player Y position.
        /// @param | pa | number | Player angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | screenW | number | Screen width in pixels.
        /// @return | table | Projection info {screen_x, scale, distance, visible}.
        methods.add_method(
            "projectSprite",
            |lua,
             this,
             (sx, sy, px, py, pa, fov, screen_w): (f32, f32, f32, f32, f32, f32, f32)| {
                let sp = this.inner.project_sprite(sx, sy, px, py, pa, fov, screen_w);
                let t = lua.create_table()?;
                /// Performs the 'screen_x' operation.
                /// @return | nil | No value is returned.
                t.set("screen_x", sp.screen_x)?;
                /// Performs the 'scale' operation.
                /// @return | nil | No value is returned.
                t.set("scale", sp.scale)?;
                /// Performs the 'distance' operation.
                /// @return | nil | No value is returned.
                t.set("distance", sp.distance)?;
                /// Performs the 'visible' operation.
                /// @return | nil | No value is returned.
                t.set("visible", sp.visible)?;
                Ok(t)
            },
        );
        // -- drawTopDown --
        /// Renders a top-down debug view of the map with the player's position and direction.
        /// @param | px | number | Player X position.
        /// @param | py | number | Player Y position.
        /// @param | angle | number | Player facing angle in radians.
        /// @param | scale | integer | Pixels per grid cell.
        /// @return | table | Raw image data.
        methods.add_method(
            "drawTopDown",
            |_, this, (px, py, angle, scale): (f32, f32, f32, u32)| {
                let img = this.inner.draw_top_down_to_image(px, py, angle, scale);
                Ok(img)
            },
        );
        // -- drawView --
        /// Renders a first-person raycaster view to a raw image buffer (no textures, flat-shaded).
        /// @param | px | number | Player X position.
        /// @param | py | number | Player Y position.
        /// @param | angle | number | Player facing angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | w | integer | Output image width in pixels.
        /// @param | h | integer | Output image height in pixels.
        /// @param | maxDist | number | Maximum render distance.
        /// @return | table | Raw image data.
        methods.add_method(
            "drawView",
            |_, this, (px, py, angle, fov, w, h, max_dist): (f32, f32, f32, f32, u32, u32, f32)| {
                let img = this
                    .inner
                    .draw_view_to_image(px, py, angle, fov, w, h, max_dist);
                Ok(img)
            },
        );
        // -- drawDepthMap --
        /// Renders a grayscale depth map showing distance-to-wall for each column.
        /// @param | px | number | Player X position.
        /// @param | py | number | Player Y position.
        /// @param | angle | number | Player facing angle in radians.
        /// @param | fov | number | Field of view in radians.
        /// @param | numRays | integer | Number of rays (columns) to cast.
        /// @param | w | integer | Output image width in pixels.
        /// @param | h | integer | Output image height in pixels.
        /// @param | maxDist | number | Maximum render distance.
        /// @return | table | Raw depth-map image data.
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
        // -- drawLineOfSight --
        /// Renders a debug image showing the line-of-sight ray between two world points.
        /// @param | ax | number | Start X.
        /// @param | ay | number | Start Y.
        /// @param | bx | number | End X.
        /// @param | by | number | End Y.
        /// @param | scale | integer | Pixels per grid cell.
        /// @return | table | Raw image data.
        methods.add_method(
            "drawLineOfSight",
            |_, this, (ax, ay, bx, by, scale): (f32, f32, f32, f32, u32)| {
                let img = this
                    .inner
                    .draw_line_of_sight_to_image(ax, ay, bx, by, scale);
                Ok(img)
            },
        );
        // -- drawCameraSweep --
        /// Renders multiple frames of a rotating camera sweep as a single combined image.
        /// @param | x | number | Camera X position.
        /// @param | y | number | Camera Y position.
        /// @param | fov | number | Field of view in radians.
        /// @param | maxDist | number | Maximum render distance.
        /// @param | numFrames | integer | Number of rotation steps.
        /// @param | fw | integer | Frame width in pixels.
        /// @param | fh | integer | Frame height in pixels.
        /// @return | table | Raw image data for all frames.
        methods.add_method("drawCameraSweep", |_, this, (x, y, fov, max_dist, num_frames, fw, fh): (f32, f32, f32, f32, u32, u32, u32)| {
                let img = this.inner.draw_camera_sweep_to_image(x, y, fov, max_dist, num_frames, fw, fh);
                Ok(img)
            },
        );
        // -- buildScene --
        /// Builds a complete textured raycaster scene for GPU rendering. Stores the output internally.
        /// for the renderer to consume on the next frame. Returns the number of quads generated.
        /// @param | params | table | Scene params {px, py, angle, fov, rays, max_dist, screen_w, screen_h, ambient?, shade_dist?, floor_r/g/b?, ceiling_r/g/b?, camera_height?, horizon_offset?}.
        /// @param | lights | table? | Array of point-light tables {x, y, radius, r?, g?, b?, intensity?}.
        /// @param | sprites | table? | Array of sprite tables {x, y, texture, size?}.
        /// @param | wallTextures | table? | Map of cell_value -> texture for wall surfaces.
        /// @return | integer | Total number of quads in the built scene.
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
        // -- buildSceneWithModels --
        /// Builds a textured raycaster scene with additional 3D .obj model instances projected into the view.
        /// Extends buildScene with a models array for placing 3D props in the dungeon.
        /// @param | params | table | Scene params (same as buildScene).
        /// @param | lights | table? | Array of point-light tables.
        /// @param | sprites | table? | Array of sprite tables.
        /// @param | wallTextures | table? | Map of cell_value -> texture.
        /// @param | models | table? | Array of model instance tables {model, x, y, rotation?, scale?}.
        /// @return | integer | Total number of quads in the built scene.
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
        // -- type --
        /// Returns the type name of this object ("LRaycaster").
        /// @return | string | Type name string.
        methods.add_method("type", |_, _, ()| Ok("LRaycaster"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if this object is of the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRaycaster" || name == "Object")
        });
    }
}
/// Lua-visible sprite manager that tracks world-space billboard sprites for sorting and projection.
pub struct LuaSpriteManager {
    inner: SpriteManager,
}
impl LuaUserData for LuaSpriteManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds a new sprite to the manager at a world position with a texture name and optional scale.
        /// @param | x | number | World X position.
        /// @param | y | number | World Y position.
        /// @param | texture | string | Texture asset name.
        /// @param | scale | number? | Sprite size multiplier (default 1.0).
        /// @return | integer | Unique sprite id for later manipulation.
        methods.add_method_mut(
            "add",
            |_, this, (x, y, texture, scale): (f32, f32, String, Option<f32>)| {
                Ok(this.inner.add(x, y, &texture, scale.unwrap_or(1.0)))
            },
        );
        // -- remove --
        /// Removes a sprite by its id. This method is available to Lua scripts.
        /// @param | id | integer | Sprite id returned by add().
        /// @return | nil | No value is returned.
        methods.add_method_mut("remove", |_, this, id: u32| {
            this.inner.remove(id);
            Ok(())
        });
        // -- setPosition --
        /// Updates the world position of an existing sprite.
        /// @param | id | integer | Sprite id.
        /// @param | x | number | New world X.
        /// @param | y | number | New world Y.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setPosition", |_, this, (id, x, y): (u32, f32, f32)| {
            this.inner.set_position(id, x, y);
            Ok(())
        });
        // -- setVisible --
        /// Shows or hides a sprite without removing it.
        /// @param | id | integer | Sprite id.
        /// @param | visible | boolean | Whether the sprite should be rendered.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setVisible", |_, this, (id, visible): (u32, bool)| {
            this.inner.set_visible(id, visible);
            Ok(())
        });
        // -- clear --
        /// Removes all sprites from the manager.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- sortAndProject --
        /// Sorts all visible sprites by distance from the camera and returns projection data.
        /// @param | camX | number | Camera X position.
        /// @param | camY | number | Camera Y position.
        /// @param | camAngle | number | Camera facing angle (unused, reserved).
        /// @return | table | Array of {id, x, y, texture, scale, distance} sorted back-to-front.
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
                    /// Performs the 'id' operation.
                    /// @return | nil | No value is returned.
                    entry.set("id", s.id)?;
                    /// Performs the 'x' operation.
                    /// @return | nil | No value is returned.
                    entry.set("x", s.x)?;
                    /// Performs the 'y' operation.
                    /// @return | nil | No value is returned.
                    entry.set("y", s.y)?;
                    /// Performs the 'texture' operation.
                    /// @return | nil | No value is returned.
                    entry.set("texture", s.texture.clone())?;
                    /// Performs the 'scale' operation.
                    /// @return | nil | No value is returned.
                    entry.set("scale", s.scale)?;
                    /// Performs the 'distance' operation.
                    /// @return | nil | No value is returned.
                    entry.set("distance", dist)?;
                    tbl.set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );
        // -- type --
        /// Returns the type name of this object ("LSpriteManager").
        /// @return | string | Type name string.
        methods.add_method("type", |_, _, ()| Ok("LSpriteManager"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if this object is of the given type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpriteManager" || name == "SpriteManager" || name == "Object")
        });
    }
}
/// Registers the `lurek.raycaster` module table and all its factory functions into Lua.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- new --
    /// Creates a new raycaster map with the given grid dimensions.
    /// @param | w | integer | Map width in cells.
    /// @param | h | integer | Map height in cells.
    /// @return | LRaycaster | A new raycaster map instance.
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
    // -- newMap --
    /// Creates a new raycaster map (alias for `new`).
    /// @param | w | integer | Map width in cells.
    /// @param | h | integer | Map height in cells.
    /// @return | LRaycaster | A new raycaster map instance.
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
    // -- projectColumn --
    /// Computes the projected wall-column height for a given distance, FOV, and screen height.
    /// @param | distance | number | Perpendicular distance to the wall.
    /// @param | fov | number | Field of view in radians.
    /// @param | screenHeight | number | Screen height in pixels.
    /// @return | number | Projected column height in pixels.
    tbl.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_height): (f32, f32, f32)| {
            Ok(project_column(distance, fov, screen_height))
        })?,
    )?;
    // -- distanceShade --
    /// Returns a brightness multiplier (0.0..1.0) based on distance for fog/darkness falloff.
    /// @param | distance | number | Distance to shade.
    /// @param | maxDistance | number | Distance at which shade reaches zero.
    /// @return | number | Shade factor (1.0 at distance 0, approaching 0.0 at maxDistance).
    tbl.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_distance): (f32, f32)| {
            Ok(distance_shade(distance, max_distance))
        })?,
    )?;
    // -- newDoorManager --
    /// Creates a new door manager for tracking and animating sliding doors.
    /// @return | LDoorManager | A new empty door manager.
    tbl.set(
        "newDoorManager",
        lua.create_function(|_, ()| {
            Ok(LuaDoorManager {
                inner: Rc::new(RefCell::new(DoorManager::new())),
            })
        })?,
    )?;
    // -- newHeightMap --
    /// Creates a new height map for variable floor/ceiling heights across the grid.
    /// @param | w | integer | Width in cells.
    /// @param | h | integer | Height in cells.
    /// @return | LHeightMap | A new height map initialized to zero.
    tbl.set(
        "newHeightMap",
        lua.create_function(|_, (w, h): (u32, u32)| {
            Ok(LuaHeightMap {
                inner: Rc::new(RefCell::new(HeightMap::new(w, h))),
            })
        })?,
    )?;
    // -- newPointLight --
    /// Creates a new point light with position, color, radius, and intensity.
    /// @param | x | number | World X position.
    /// @param | y | number | World Y position.
    /// @param | r | number | Red channel (0.0..1.0).
    /// @param | g | number | Green channel (0.0..1.0).
    /// @param | b | number | Blue channel (0.0..1.0).
    /// @param | radius | number | Light falloff radius in world units.
    /// @param | intensity | number | Brightness multiplier.
    /// @return | LPointLight | A new point light instance.
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
    // -- newSpriteManager --
    /// Creates a new sprite manager for tracking and projecting billboard sprites.
    /// @return | LSpriteManager | A new empty sprite manager.
    tbl.set(
        "newSpriteManager",
        lua.create_function(|_, ()| {
            Ok(LuaSpriteManager {
                inner: SpriteManager::new(),
            })
        })?,
    )?;
    /// Performs the 'raycaster' operation.
    /// @return | nil | No value is returned.
    lurek.set("raycaster", tbl)?;
    Ok(())
}
