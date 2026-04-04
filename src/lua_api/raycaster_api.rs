//! Registers the `luna.raycaster` namespace.
//!
//! Provides Lua-level DDA grid raycasting for retro FPS and
//! dungeon-crawler games, wrapping [`Raycaster2D`].
//!
//! This module is part of Luna2D's `lua_api` subsystem.
//! Key types exported: `LuaRaycaster`.
//! Primary functions: `register()`.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::raycaster::{RayHit, Raycaster2D};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Converts a [`RayHit`] to a Lua table.
fn ray_hit_to_table(lua: &Lua, hit: RayHit) -> LuaResult<LuaTable<'_>> {
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

// ── UserData wrapper ──────────────────────────────────────────────────────────

/// Lua UserData wrapper for a [`Raycaster2D`] grid.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Raycaster2D>>`. Shared grid state.
#[derive(Clone)]
pub struct LuaRaycaster {
    /// Shared raycaster grid.
    pub(crate) inner: Rc<RefCell<Raycaster2D>>,
}

impl LunaType for LuaRaycaster {
    const TYPE_NAME: &'static str = "Raycaster";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Raycaster", "Object"];
}

impl LuaUserData for LuaRaycaster {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ── Grid mutation ─────────────────────────────────────────────────

        /// Sets the cell value at grid position `(x, y)`.
        /// @param x   number  Column (0-based).
        /// @param y   number  Row    (0-based).
        /// @param val number  Cell value (0 = open, >0 = wall type).
        methods.add_method("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.borrow_mut().set_cell(x, y, val);
            Ok(())
        });

        /// Returns the cell value at `(x, y)`.
        /// @param x number
        /// @param y number
        /// @return number
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cell(x, y))
        });

        /// Replaces all grid cells from a flat Lua table of numbers.
        /// @param cells table  Flat array of cell values, row-major order.
        methods.add_method("setCells", |_, this, cells_tbl: LuaTable| {
            let mut cells: Vec<u32> = Vec::new();
            for v in cells_tbl.sequence_values::<u32>() {
                cells.push(v?);
            }
            this.inner.borrow_mut().set_cells(cells);
            Ok(())
        });

        /// Returns `true` when the cell at `(x, y)` is a wall (value > 0).
        /// @param x number
        /// @param y number
        /// @return boolean
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x, y))
        });

        // ── Dimensions ────────────────────────────────────────────────────

        /// Returns the grid width in cells.
        /// @return number
        methods.add_method("width", |_, this, ()| {
            Ok(this.inner.borrow().width())
        });

        /// Returns the grid height in cells.
        /// @return number
        methods.add_method("height", |_, this, ()| {
            Ok(this.inner.borrow().height())
        });

        // ── Ray casting ───────────────────────────────────────────────────

        /// Casts a single ray and returns a hit table, or `nil` if nothing was hit.
        ///
        /// Hit table fields:
        /// - `distance`    — `number`  Fisheye-corrected wall distance.
        /// - `raw_distance`— `number`  Euclidean distance.
        /// - `cell_value`  — `number`  Wall type (>0 = wall).
        /// - `side`        — `number`  0 = horizontal hit, 1 = vertical.
        /// - `tex_u`       — `number`  Texture U coordinate in [0, 1].
        /// - `hit_x`       — `number`  World-space hit point X.
        /// - `hit_y`       — `number`  World-space hit point Y.
        /// - `hit`         — `boolean` Whether a wall was actually hit.
        ///
        /// @param ox       number  Origin X in world units.
        /// @param oy       number  Origin Y in world units.
        /// @param angle    number  Ray angle in radians.
        /// @param max_dist number  Maximum ray distance.
        /// @return table|nil
        methods.add_method(
            "castRay",
            |lua, this, (ox, oy, angle, max_dist): (f32, f32, f32, f32)| {
                match this.inner.borrow().cast_ray(ox, oy, angle, max_dist) {
                    Some(hit) => {
                        let t = ray_hit_to_table(lua, hit)?;
                        Ok(LuaValue::Table(t))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        /// Casts multiple rays over a field of view and returns an array of hit tables.
        ///
        /// @param ox    number  Origin X.
        /// @param oy    number  Origin Y.
        /// @param angle number  Centre angle in radians.
        /// @param fov   number  Total field of view in radians.
        /// @param count number  Number of rays.
        /// @param max_dist number  Maximum ray distance.
        /// @return table   Array of hit tables (same format as `castRay`).
        methods.add_method(
            "castRays",
            |lua,
             this,
             (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, f32)| {
                let hits = this
                    .inner
                    .borrow()
                    .cast_rays(ox, oy, angle, fov, count, max_dist);
                let tbl = lua.create_table()?;
                for (i, hit) in hits.into_iter().enumerate() {
                    let ht = ray_hit_to_table(lua, hit)?;
                    tbl.set(i + 1, ht)?;
                }
                Ok(tbl)
            },
        );
    }
}

// ── Registration ──────────────────────────────────────────────────────────────

/// Registers the `luna.raycaster` namespace into the given `luna` table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let rc_tbl = lua.create_table()?;

    /// Creates a new [`Raycaster2D`] grid of the given dimensions.
    /// @param width  number  Grid width  in cells.
    /// @param height number  Grid height in cells.
    /// @return Raycaster
    rc_tbl.set(
        "new",
        lua.create_function(|_, (w, h): (u32, u32)| {
            Ok(LuaRaycaster {
                inner: Rc::new(RefCell::new(Raycaster2D::new(w, h))),
            })
        })?,
    )?;

    luna.set("raycaster", rc_tbl)?;
    Ok(())
}
