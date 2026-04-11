//! `lurek.raycaster` - DDA grid raycasting for retro FPS and dungeon-crawler games.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::Color;
use crate::raycaster::{
    distance_shade, project_column, PointLight, RayHit, Raycaster2D, RaycasterScene,
    SceneBuildParams, WorldSprite,
};
use crate::runtime::resource_keys::TextureKey;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Converts a [`RayHit`] to a Lua table with distance, cell, side, and hit fields.
fn ray_hit_to_table<'lua>(lua: &'lua Lua, hit: &RayHit) -> LuaResult<LuaTable<'lua>> {
    let t = lua.create_table()?;
    t.set("distance", hit.distance)?;
    t.set("raw_distance", hit.raw_distance)?;
    t.set("cell_value", hit.cell_value)?;
    t.set("side", hit.side)?;
    t.set("tex_u", hit.tex_u)?;
    t.set("hit_x", hit.hit_x)?;
    t.set("hit_y", hit.hit_y)?;
    t.set("hit", hit.hit)?;
    Ok(t)
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
        /// @return integer — quad count
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
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.raycaster` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
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

    luna.set("raycaster", tbl)?;
    Ok(())
}
