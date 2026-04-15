//! `lurek.collision` — Lightweight stateless geometric collision helpers.
//!
//! These pure-math functions perform fast overlap detection without requiring a
//! full physics world. Suitable for RPG, puzzle, or visual-novel games that only
//! need simple overlap detection, not rigid-body simulation.
//!
//! All functions are pure and stateless — the `_state` parameter is accepted only
//! to match the standard `register()` contract.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::SharedState;

/// Registers the `lurek.collision` namespace.
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── testAABB ─────────────────────────────────────────────────────────────
    /// Returns true when two axis-aligned bounding boxes overlap.
    /// @param ax : number  -- left edge of box A
    /// @param ay : number  -- top edge of box A
    /// @param aw : number  -- width of box A
    /// @param ah : number  -- height of box A
    /// @param bx : number  -- left edge of box B
    /// @param by : number  -- top edge of box B
    /// @param bw : number  -- width of box B
    /// @param bh : number  -- height of box B
    /// @return boolean
    tbl.set(
        "testAABB",
        lua.create_function(
            |_,
             (ax, ay, aw, ah, bx, by, bw, bh): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_aabb(
                    ax, ay, aw, ah, bx, by, bw, bh,
                ))
            },
        )?,
    )?;

    // ── testCircles ───────────────────────────────────────────────────────────
    /// Returns true when two circles overlap.
    /// @param ax : number  -- centre X of circle A
    /// @param ay : number  -- centre Y of circle A
    /// @param ar : number  -- radius of circle A
    /// @param bx : number  -- centre X of circle B
    /// @param by : number  -- centre Y of circle B
    /// @param br : number  -- radius of circle B
    /// @return boolean
    tbl.set(
        "testCircles",
        lua.create_function(
            |_, (ax, ay, ar, bx, by, br): (f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_circles(
                    ax, ay, ar, bx, by, br,
                ))
            },
        )?,
    )?;

    // ── testPoint ────────────────────────────────────────────────────────────
    /// Returns true when point (px, py) lies inside the AABB.
    /// @param px : number  -- point X
    /// @param py : number  -- point Y
    /// @param ax : number  -- left edge of AABB
    /// @param ay : number  -- top edge of AABB
    /// @param aw : number  -- width of AABB
    /// @param ah : number  -- height of AABB
    /// @return boolean
    tbl.set(
        "testPoint",
        lua.create_function(
            |_, (px, py, ax, ay, aw, ah): (f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_point_aabb(
                    px, py, ax, ay, aw, ah,
                ))
            },
        )?,
    )?;

    // ── testCircleAABB ────────────────────────────────────────────────────────
    /// Returns true when a circle overlaps an AABB.
    /// @param cx : number  -- circle centre X
    /// @param cy : number  -- circle centre Y
    /// @param cr : number  -- circle radius
    /// @param ax : number  -- left edge of AABB
    /// @param ay : number  -- top edge of AABB
    /// @param aw : number  -- width of AABB
    /// @param ah : number  -- height of AABB
    /// @return boolean
    tbl.set(
        "testCircleAABB",
        lua.create_function(
            |_, (cx, cy, cr, ax, ay, aw, ah): (f32, f32, f32, f32, f32, f32, f32)| {
                Ok(crate::physics::collision_helpers::test_circle_aabb(
                    cx, cy, cr, ax, ay, aw, ah,
                ))
            },
        )?,
    )?;

    luna.set("collision", tbl)?;
    Ok(())
}
