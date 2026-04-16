//! `lurek.raycaster` - DDA grid raycasting for retro FPS and dungeon-crawler games.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Color;
use crate::raycaster::{
    distance_shade, project_column, DoorDirection, DoorManager, DoorState, HeightMap, PointLight,
    RayHit, Raycaster2D, RaycasterScene, SceneBuildParams, WorldSprite,
};
use crate::raycaster::sprite_manager::SpriteManager;
use crate::runtime::resource_keys::TextureKey;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Converts a [`RayHit`] to a Lua table with distance, cell, side, alpha, and hit fields.
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

// -------------------------------------------------------------------------------
// LuaDoorManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`DoorManager`], managing sliding doors in a level.
pub struct LuaDoorManager {
    inner: Rc<RefCell<DoorManager>>,
}

impl LuaUserData for LuaDoorManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addDoor --
        /// Registers a door at grid position (x, y).
        /// @param x         : integer        — Grid X.
        /// @param y         : integer        — Grid Y.
        /// @param direction : string         — "horizontal" or "vertical".
        /// @param speed     : number         — Animation speed (units/s).
        /// @return nil
        /// integer  — Door index for open/close calls.
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
        /// Begins opening the door at the given index.
        /// @param index : integer
        /// @return nil
        methods.add_method_mut("openDoor", |_, this, index: usize| {
            this.inner.borrow_mut().open_door(index);
            Ok(())
        });

        // -- closeDoor --
        /// Begins closing the door at the given index.
        /// @param index : integer
        /// @return nil
        methods.add_method_mut("closeDoor", |_, this, index: usize| {
            this.inner.borrow_mut().close_door(index);
            Ok(())
        });

        // -- update --
        /// Advances all door animations by dt seconds.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- getDoor --
        /// Returns the state table for door at index, or nil if out of range.
        /// @param index : integer
        /// @return nil
        /// table|nil  — {x, y, openAmount, state} or nil.
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

        // -- count --
        /// Returns the number of registered doors.
        /// @return integer
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().doors().len()));

        // -- type --
        /// Returns the type string "DoorManager".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("DoorManager"));

        // -- typeOf --
        /// Returns the type string "DoorManager".
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("DoorManager"));
    }
}

// -------------------------------------------------------------------------------
// LuaHeightMap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`HeightMap`] for variable floor/ceiling heights.
pub struct LuaHeightMap {
    inner: Rc<RefCell<HeightMap>>,
}

impl LuaUserData for LuaHeightMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setFloor --
        /// Sets the floor height at (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @param h : number
        /// @return nil
        methods.add_method_mut("setFloor", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_floor(x, y, h);
            Ok(())
        });

        // -- setCeiling --
        /// Sets the ceiling height at (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @param h : number
        /// @return nil
        methods.add_method_mut("setCeiling", |_, this, (x, y, h): (u32, u32, f32)| {
            this.inner.borrow_mut().set_ceiling(x, y, h);
            Ok(())
        });

        // -- floorAt --
        /// Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
        /// @param x : integer
        /// @param y : integer
        /// @return number
        methods.add_method("floorAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().floor_at(x, y))
        });

        // -- ceilingAt --
        /// Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
        /// @param x : integer
        /// @param y : integer
        /// @return number
        methods.add_method("ceilingAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().ceiling_at(x, y))
        });

        // -- type --
        /// Returns the type string "HeightMap".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("HeightMap"));

        // -- typeOf --
        /// Returns the type string "HeightMap".
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("HeightMap"));
    }
}

// -------------------------------------------------------------------------------
// LuaPointLight UserData
// -------------------------------------------------------------------------------

/// Lua-side value wrapper around a raycaster [`PointLight`].
#[derive(Clone)]
pub struct LuaPointLight {
    inner: PointLight,
}

impl LuaUserData for LuaPointLight {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- x / y --
        /// Returns the world-space X position.
        /// @return number
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));
        /// Returns the world-space Y position.
        /// @return number
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));

        // -- radius --
        /// Returns the illumination radius.
        /// @return number
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));

        // -- intensity --
        /// Returns the intensity multiplier.
        /// @return number
        methods.add_method("intensity", |_, this, ()| Ok(this.inner.intensity));

        // -- color --
        /// Returns the RGB color as three separate values.
        /// @return number, number, number
        methods.add_method("color", |_, this, ()| {
            Ok((this.inner.color[0], this.inner.color[1], this.inner.color[2]))
        });

        // -- set --
        /// Updates all light properties at once.
        /// @param x         : number
        /// @param y         : number
        /// @param r         : number  — Red   [0,1]
        /// @param g         : number  — Green [0,1]
        /// @param b         : number  — Blue  [0,1]
        /// @param radius    : number
        /// @param intensity : number
        /// @return nil
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
        /// Returns the type string "PointLight".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("PointLight"));

        // -- typeOf --
        /// Returns the type string "PointLight".
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("PointLight"));
    }
}

// -------------------------------------------------------------------------------
// LuaRaycaster UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Raycaster2D`] grid.
pub struct LuaRaycaster {
    inner: Raycaster2D,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaRaycaster {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setCell --
        /// Sets the cell value at grid position (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @param val : integer
        /// @return nil
        methods.add_method_mut("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.set_cell(x, y, val);
            Ok(())
        });

        // -- getCell --
        /// Returns the cell value at (x, y).
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_cell(x, y))
        });

        // -- setCells --
        /// Replaces all grid cells from a flat array of values in row-major order.
        /// @param cells : table
        /// @return nil
        methods.add_method_mut("setCells", |_, this, cells_tbl: LuaTable| {
            let cells: Vec<u32> = cells_tbl
                .sequence_values::<u32>()
                .collect::<LuaResult<_>>()?;
            this.inner.set_cells(cells);
            Ok(())
        });

        // -- isBlocked --
        /// Returns true when the cell at (x, y) is a wall (value > 0).
        /// @param x : integer
        /// @param y : integer
        /// @return boolean
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.is_blocked(x, y))
        });

        // -- width --
        /// Returns the grid width in cells.
        /// @return integer
        methods.add_method("width", |_, this, ()| Ok(this.inner.width()));

        // -- height --
        /// Returns the grid height in cells.
        /// @return integer
        methods.add_method("height", |_, this, ()| Ok(this.inner.height()));

        // -- castRay --
        /// Casts a single ray and returns a hit table, or nil if nothing was hit.
        /// @param ox : number
        /// @param oy : number
        /// @param angle : number
        /// @param max_dist : number
        /// @return table|nil
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
        /// Casts multiple rays across a field of view, returns an array of hit tables.
        /// @param ox : number
        /// @param oy : number
        /// @param angle : number
        /// @param fov : number
        /// @param count : integer
        /// @param max_dist : number
        /// @return table
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
        /// Casts multiple rays and returns a flat array of 5 floats per ray.
        /// @param ox : number
        /// @param oy : number
        /// @param angle : number
        /// @param fov : number
        /// @param count : integer
        /// @param max_dist : number
        /// @return table
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
        /// Checks line of sight between two points using DDA traversal.
        /// @param x1 : number
        /// @param y1 : number
        /// @param x2 : number
        /// @param y2 : number
        /// @return boolean
        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                Ok(this.inner.line_of_sight(x1, y1, x2, y2))
            },
        );

        // -- setWallAlpha --
        /// Sets the opacity for a wall tile type. Alpha is clamped to [0, 1].
        /// Tiles with alpha < 1.0 are treated as translucent by castRayMulti.
        /// @param tile_type : integer
        /// @param alpha     : number
        /// @return nil
        methods.add_method_mut(
            "setWallAlpha",
            |_, this, (tile_type, alpha): (u8, f32)| {
                this.inner.set_wall_alpha(tile_type, alpha);
                Ok(())
            },
        );

        // -- getWallAlpha --
        /// Returns the opacity for a wall tile type. Returns 1.0 if not set.
        /// @param tile_type : integer
        /// @return number
        methods.add_method("getWallAlpha", |_, this, tile_type: u8| {
            Ok(this.inner.get_wall_alpha(tile_type))
        });

        // -- castRayMulti --
        /// Casts a ray collecting up to max_hits wall layers, continuing through
        /// translucent walls (alpha < 1.0). Returns an array of hit tables ordered
        /// nearest to farthest. Useful for glass, fences, and layered effects.
        /// @param ox       : number
        /// @param oy       : number
        /// @param angle    : number
        /// @param max_dist : number
        /// @param max_hits : integer  — layers to collect (default 4, max 8)
        /// @return table
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
        /// Computes floor (or ceiling) texture UV coordinates for one horizontal screen row.
        ///
        /// For every pixel column in the given `row`, returns a `{u, v}` table
        /// with normalised texture coordinates in `[0.0, 1.0)`.  Multiply `u` and `v`
        /// by your texture width/height to obtain integer texel indices.
        ///
        /// Rows below the screen-centre half-height are floor rows; rows above
        /// are ceiling rows.  Passing `row = screen_height / 2` returns zeros.
        ///
        /// # Usage
        /// ```lua
        /// local uvs = rc:castFloorRow(cam_x, cam_y, dir_x, dir_y, plane_x, plane_y, row)
        /// for col, uv in ipairs(uvs) do
        ///     local tx = math.floor(uv.u * TEX_W) % TEX_W
        ///     local ty = math.floor(uv.v * TEX_H) % TEX_H
        ///     -- sample floor texture at (tx, ty)
        /// end
        /// ```
        /// @param cam_x : number
        /// @param cam_y : number
        /// @param dir_x : number
        /// @param dir_y : number
        /// @param plane_x : number
        /// @param plane_y : number
        /// @param row : integer
        /// @return table
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

        // -- projectSprite --
        /// Projects a world-space sprite onto screen space.
        /// @param sx : number
        /// @param sy : number
        /// @param px : number
        /// @param py : number
        /// @param pa : number
        /// @param fov : number
        /// @param screen_w : number
        /// @return table
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

        // -- drawTopDown --
        /// Renders a top-down grid view with player marker to an ImageData.
        /// @param px : number
        /// @param py : number
        /// @param angle : number
        /// @param scale : integer
        /// @return ImageData
        methods.add_method(
            "drawTopDown",
            |_, this, (px, py, angle, scale): (f32, f32, f32, u32)| {
                let img = this.inner.draw_top_down_to_image(px, py, angle, scale);
                Ok(LuaImageData { inner: img })
            },
        );

        // -- drawView --
        /// Renders a first-person column view to an ImageData.
        /// @param px : number
        /// @param py : number
        /// @param angle : number
        /// @param fov : number
        /// @param width : integer
        /// @param height : integer
        /// @param max_dist : number
        /// @return ImageData
        methods.add_method(
            "drawView",
            |_, this, (px, py, angle, fov, w, h, max_dist): (f32, f32, f32, f32, u32, u32, f32)| {
                let img = this
                    .inner
                    .draw_view_to_image(px, py, angle, fov, w, h, max_dist);
                Ok(LuaImageData { inner: img })
            },
        );

        // -- drawDepthMap --
        /// Renders a depth-map column view to an ImageData.
        /// @param px : number
        /// @param py : number
        /// @param angle : number
        /// @param fov : number
        /// @param num_rays : integer
        /// @param width : integer
        /// @param height : integer
        /// @param max_dist : number
        /// @return ImageData
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
                Ok(LuaImageData { inner: img })
            },
        );

        // -- drawLineOfSight --
        /// Renders a line-of-sight test between two points to an ImageData.
        /// @param ax : number
        /// @param ay : number
        /// @param bx : number
        /// @param by : number
        /// @param scale : integer
        /// @return ImageData
        methods.add_method(
            "drawLineOfSight",
            |_, this, (ax, ay, bx, by, scale): (f32, f32, f32, f32, u32)| {
                let img = this
                    .inner
                    .draw_line_of_sight_to_image(ax, ay, bx, by, scale);
                Ok(LuaImageData { inner: img })
            },
        );

        // -- drawCameraSweep --
        /// Renders a mosaic of first-person views from evenly spaced angles to an ImageData.
        /// @param x : number
        /// @param y : number
        /// @param fov : number
        /// @param max_dist : number
        /// @param num_frames : integer
        /// @param frame_w : integer
        /// @param frame_h : integer
        /// @return ImageData
        methods.add_method(
            "drawCameraSweep",
            |_, this, (x, y, fov, max_dist, num_frames, fw, fh): (f32, f32, f32, f32, u32, u32, u32)| {
                let img = this.inner.draw_camera_sweep_to_image(x, y, fov, max_dist, num_frames, fw, fh);
                Ok(LuaImageData { inner: img })
            },
        );

        // -- buildScene --
        /// Builds a raycaster scene and stores it in SharedState for GPU rendering.
        /// @param params : table — { px, py, angle, fov, rays, max_dist, screen_w, screen_h, ambient?, shade_dist?, floor_color?, ceiling_color? }
        /// @param lights : table|nil — array of { x, y, radius, r, g, b, intensity }
        /// @param sprites : table|nil — array of { x, y, texture, size }
        /// @param wall_textures : table|nil — { [cell_value] = TextureKey }
        /// @return nil
        /// integer — quad count
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
                };

                // Parse lights
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

                // Parse sprites
                let sprites: Vec<WorldSprite> = match sprites_tbl {
                    LuaValue::Table(tbl) => {
                        let mut v = Vec::new();
                        for pair in tbl.sequence_values::<LuaTable>() {
                            let st = pair?;
                            let tex_id: u64 = st.get::<_, u64>("texture")?;
                            let key = TextureKey::from(slotmap::KeyData::from_ffi(tex_id));
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

                // Parse wall texture lookup table
                let wall_tex_map: std::collections::HashMap<u32, TextureKey> = match wall_tex_tbl {
                    LuaValue::Table(tbl) => {
                        let mut m = std::collections::HashMap::new();
                        for pair in tbl.pairs::<u32, u64>() {
                            let (cell_val, tex_id) = pair?;
                            m.insert(
                                cell_val,
                                TextureKey::from(slotmap::KeyData::from_ffi(tex_id)),
                            );
                        }
                        m
                    }
                    _ => std::collections::HashMap::new(),
                };

                let scene =
                    RaycasterScene::build(&this.inner, &params, &lights, &sprites, &|cell_value| {
                        wall_tex_map.get(&cell_value).copied()
                    });

                let quad_count = scene.quad_count();
                this.state.borrow_mut().raycaster_output = Some(scene);
                Ok(quad_count)
            },
        );
    }
}

// -------------------------------------------------------------------------------
// LuaSpriteManager UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SpriteManager`] for batch depth-sorted sprite projection.
pub struct LuaSpriteManager {
    inner: SpriteManager,
}

impl LuaUserData for LuaSpriteManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds a sprite at world position (x, y) and returns its unique id.
        /// @param x       : number
        /// @param y       : number
        /// @param texture : string
        /// @param scale   : number  (optional, default 1.0)
        /// @return integer
        methods.add_method_mut(
            "add",
            |_, this, (x, y, texture, scale): (f32, f32, String, Option<f32>)| {
                Ok(this.inner.add(x, y, &texture, scale.unwrap_or(1.0)))
            },
        );

        // -- remove --
        /// Removes the sprite with the given id. No-op if not found.
        /// @param id : integer
        /// @return nil
        methods.add_method_mut("remove", |_, this, id: u32| {
            this.inner.remove(id);
            Ok(())
        });

        // -- setPosition --
        /// Moves the sprite with the given id to world (x, y).
        /// @param id : integer
        /// @param x  : number
        /// @param y  : number
        /// @return nil
        methods.add_method_mut("setPosition", |_, this, (id, x, y): (u32, f32, f32)| {
            this.inner.set_position(id, x, y);
            Ok(())
        });

        // -- setVisible --
        /// Shows or hides the sprite with the given id.
        /// @param id      : integer
        /// @param visible : boolean
        /// @return nil
        methods.add_method_mut("setVisible", |_, this, (id, visible): (u32, bool)| {
            this.inner.set_visible(id, visible);
            Ok(())
        });

        // -- clear --
        /// Removes all sprites from the manager.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- sortAndProject --
        /// Returns an array of visible sprites sorted back-to-front from camera position.
        /// Each entry: { id, x, y, texture, scale, distance }.
        /// cam_angle is accepted for API symmetry but not used for 2D sorting.
        /// @param cam_x     : number
        /// @param cam_y     : number
        /// @param cam_angle : number
        /// @return table
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

        // -- type --
        /// Returns the type string "SpriteManager".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("SpriteManager"));

        // -- typeOf --
        /// Returns the type string "SpriteManager".
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("SpriteManager"));
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.raycaster` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- new --
    /// Creates a new raycaster grid of the given dimensions.
    /// @param width : integer
    /// @param height : integer
    /// @return Raycaster
    let s = state.clone();
    tbl.set(
        "new",
        lua.create_function(move |_, (w, h): (u32, u32)| {
            Ok(LuaRaycaster {
                inner: Raycaster2D::new(w, h),
                state: s.clone(),
            })
        })?,
    )?;

    // -- newMap --
    /// Alias for `new`. Creates a new raycaster grid of the given dimensions.
    /// @param width : integer
    /// @param height : integer
    /// @return Raycaster
    let s = state.clone();
    tbl.set(
        "newMap",
        lua.create_function(move |_, (w, h): (u32, u32)| {
            Ok(LuaRaycaster {
                inner: Raycaster2D::new(w, h),
                state: s.clone(),
            })
        })?,
    )?;

    // -- projectColumn --
    /// Projects a wall distance to screen-space drawing parameters.
    /// @param distance : number
    /// @param fov : number
    /// @param screen_height : number
    /// @return number, number, number
    tbl.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_height): (f32, f32, f32)| {
            Ok(project_column(distance, fov, screen_height))
        })?,
    )?;

    // -- distanceShade --
    /// Returns distance-based brightness in [0, 1].
    /// @param distance : number
    /// @param max_distance : number
    /// @return number
    tbl.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_distance): (f32, f32)| {
            Ok(distance_shade(distance, max_distance))
        })?,
    )?;

    // -- newDoorManager --
    /// Creates a new empty door manager.
    /// @return DoorManager
    tbl.set(
        "newDoorManager",
        lua.create_function(|_, ()| {
            Ok(LuaDoorManager {
                inner: Rc::new(RefCell::new(DoorManager::new())),
            })
        })?,
    )?;

    // -- newHeightMap --
    /// Creates a new height map with default floor (0.0) and ceiling (1.0) values.
    /// @param width  : integer
    /// @param height : integer
    /// @return HeightMap
    tbl.set(
        "newHeightMap",
        lua.create_function(|_, (w, h): (u32, u32)| {
            Ok(LuaHeightMap {
                inner: Rc::new(RefCell::new(HeightMap::new(w, h))),
            })
        })?,
    )?;

    // -- newPointLight --
    /// Creates a point light for use in raycaster scene lighting.
    /// @param x         : number   — World-space X.
    /// @param y         : number   — World-space Y.
    /// @param r         : number   — Red   [0,1].
    /// @param g         : number   — Green [0,1].
    /// @param b         : number   — Blue  [0,1].
    /// @param radius    : number   — Maximum illumination radius.
    /// @param intensity : number   — Brightness multiplier.
    /// @return PointLight
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
    /// Creates a new empty batch sprite manager for depth-sorted projection.
    /// @return SpriteManager
    tbl.set(
        "newSpriteManager",
        lua.create_function(|_, ()| {
            Ok(LuaSpriteManager {
                inner: SpriteManager::new(),
            })
        })?,
    )?;

    luna.set("raycaster", tbl)?;
    Ok(())
}
