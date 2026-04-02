//! Extended tilemap API registrations (second half of `register`).

//! Registers the `luna.tilemap.*` tile map, tileset, autotile, and procedural generation API.
//!
//! Exposes `LuaTileSet`, `LuaTileMap`, `LuaAutoTileSheet`, `LuaMapBlock`, `LuaMapGroup`,
//! `LuaMapScript`, and `LuaMapGen` UserData types wrapping the `crate::tilemap` module.
//!
//! All Lua-facing tile/layer/segment indices are **1-based**; Rust internals are 0-based.
#![allow(unused_doc_comments)]

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::tilemap::coords;
use crate::tilemap::isomap::IsoMap;


#[allow(unused_imports)]
use super::helpers::*;

pub(super) fn register_ext(
    lua: &Lua,
    tilemap_table: &LuaTable,
) -> LuaResult<()> {
    // =======================================================================
    // Coordinate functions
    // =======================================================================

    /// luna.tilemap.toScreenIso(tx, ty, tileW, tileH)
    tilemap_table.set(
        "toScreenIso",
        lua.create_function(|_, (tx, ty, tile_w, tile_h): (f32, f32, f32, f32)| {
            let v = coords::to_screen_iso(tx, ty, tile_w, tile_h);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.fromScreenIso(sx, sy, tileW, tileH)
    tilemap_table.set(
        "fromScreenIso",
        lua.create_function(|_, (sx, sy, tile_w, tile_h): (f32, f32, f32, f32)| {
            let v = coords::from_screen_iso(sx, sy, tile_w, tile_h);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.isoRotate(direction, steps)
    tilemap_table.set(
        "isoRotate",
        lua.create_function(|_, (direction, steps): (i32, i32)| {
            Ok(coords::iso_rotate(direction, steps))
        })?,
    )?;

    /// luna.tilemap.isoDirectionName(direction)
    tilemap_table.set(
        "isoDirectionName",
        lua.create_function(|_, direction: i32| Ok(coords::iso_direction_name(direction)))?,
    )?;

    /// luna.tilemap.isoDirectionFromAngle(angle)
    tilemap_table.set(
        "isoDirectionFromAngle",
        lua.create_function(|_, angle: f32| Ok(coords::iso_direction_from_angle(angle)))?,
    )?;

    /// luna.tilemap.toScreenHex(q, r, size)
    tilemap_table.set(
        "toScreenHex",
        lua.create_function(|_, (q, r, size): (i32, i32, f32)| {
            let v = coords::to_screen_hex(q, r, size);
            Ok((v.x, v.y))
        })?,
    )?;

    /// luna.tilemap.fromScreenHex(sx, sy, size)
    tilemap_table.set(
        "fromScreenHex",
        lua.create_function(|_, (sx, sy, size): (f32, f32, f32)| {
            let (q, r) = coords::from_screen_hex(sx, sy, size);
            Ok((q, r))
        })?,
    )?;

    /// Returns the six hex grid coordinates adjacent to the cell at (q, r).
    ///
    /// # Parameters
    /// - `q` ÔÇö Integer q (column) coordinate of the center cell.
    /// - `r` ÔÇö Integer r (row) coordinate of the center cell.
    ///
    /// # Returns
    /// Table of six {q, r} neighbor coordinate tables.
    tilemap_table.set(
        "hexNeighbors",
        lua.create_function(|lua, (q, r): (i32, i32)| {
            let neighbors = coords::hex_neighbors(q, r);
            let t = lua.create_table()?;
            for (i, (nq, nr)) in neighbors.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *nq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *nr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexDistance(q1, r1, q2, r2)
    tilemap_table.set(
        "hexDistance",
        lua.create_function(|_, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            Ok(coords::hex_distance(q1, r1, q2, r2))
        })?,
    )?;

    /// Rounds fractional hex coordinates (q, r) to the nearest integer hex cell center.
    ///
    /// # Parameters
    /// - `q` ÔÇö Fractional q (column) coordinate.
    /// - `r` ÔÇö Fractional r (row) coordinate.
    ///
    /// # Returns
    /// Rounded integer q and r coordinates.
    tilemap_table.set(
        "hexRound",
        lua.create_function(|_, (q, r): (f32, f32)| {
            let (rq, rr) = coords::hex_round(q, r);
            Ok((rq, rr))
        })?,
    )?;

    /// luna.tilemap.hexLine(q1, r1, q2, r2)
    tilemap_table.set(
        "hexLine",
        lua.create_function(|lua, (q1, r1, q2, r2): (i32, i32, i32, i32)| {
            let cells = coords::hex_line(q1, r1, q2, r2);
            let t = lua.create_table()?;
            for (i, (q, r)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *q)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *r)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// Returns all hex cell coordinates forming the ring at exactly the given radius from (q, r).
    ///
    /// # Parameters
    /// - `q` ÔÇö Center q coordinate.
    /// - `r` ÔÇö Center r coordinate.
    /// - `radius` ÔÇö Ring distance in hex steps.
    ///
    /// # Returns
    /// Table of {q, r} coordinates for each cell on the ring.
    tilemap_table.set(
        "hexRing",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_ring(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexSpiral(q, r, radius)
    tilemap_table.set(
        "hexSpiral",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_spiral(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// Returns all hex cell coordinates within a given radius of center (q, r).
    ///
    /// # Parameters
    /// - `q` ÔÇö Center q coordinate.
    /// - `r` ÔÇö Center r coordinate.
    /// - `radius` ÔÇö Radius in hex steps (1 = immediate ring, 2 = two rings, etc.).
    ///
    /// # Returns
    /// Table of {q, r} coordinates for every cell within the radius.
    tilemap_table.set(
        "hexArea",
        lua.create_function(|lua, (q, r, radius): (i32, i32, i32)| {
            let cells = coords::hex_area(q, r, radius);
            let t = lua.create_table()?;
            for (i, (cq, cr)) in cells.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Q on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("q", *cq)?;
                /// R on this ChunkMap.
                ///
                /// # Returns
                /// The result.
                pair.set("r", *cr)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;

    /// luna.tilemap.hexRotate(q, r, centerQ, centerR, steps)
    tilemap_table.set(
        "hexRotate",
        lua.create_function(
            |_, (q, r, center_q, center_r, steps): (i32, i32, i32, i32, i32)| {
                let (rq, rr) = coords::hex_rotate(q, r, center_q, center_r, steps);
                Ok((rq, rr))
            },
        )?,
    )?;

    /// luna.tilemap.hexReflect(q, r, centerQ, centerR, axis)
    tilemap_table.set(
        "hexReflect",
        lua.create_function(
            |_, (q, r, center_q, center_r, axis): (i32, i32, i32, i32, String)| {
                let (rq, rr) = coords::hex_reflect(q, r, center_q, center_r, &axis);
                Ok((rq, rr))
            },
        )?,
    )?;

    /// luna.tilemap.newIsoMap(width, height, tileW, tileH, levelHeight)
    tilemap_table.set(
        "newIsoMap",
        lua.create_function(
            |_, (width, height, tile_w, tile_h, level_height): (u32, u32, u32, u32, u32)| {
                Ok(LuaIsoMap {
                    inner: Rc::new(RefCell::new(IsoMap::new(
                        width,
                        height,
                        tile_w,
                        tile_h,
                        level_height,
                    ))),
                })
            },
        )?,
    )?;

    // Tile-part constants (1-based for Lua callers)
    /// F l o o r on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("FLOOR", 1u32)?;
    /// N o r t h_ w a l l on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("NORTH_WALL", 2u32)?;
    /// W e s t_ w a l l on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("WEST_WALL", 3u32)?;
    /// O b j e c t on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    tilemap_table.set("OBJECT", 4u32)?;

    /// Tilemap on this ChunkMap.
    ///
    /// # Returns
    /// The result.
    Ok(())
}
