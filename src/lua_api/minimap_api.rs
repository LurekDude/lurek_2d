//! `luna.minimap` — Grid-based minimap with terrain, fog of war, objects, pings, and markers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::minimap::{ColorMode, FogLevel, Minimap};

// -------------------------------------------------------------------------------
// LuaMinimap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Minimap`].
pub struct LuaMinimap {
    inner: Minimap,
}

impl LuaUserData for LuaMinimap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // ── Grid queries ──

        // -- getGridWidth --
        /// Returns the grid width in cells.
        /// @return integer
        methods.add_method("getGridWidth", |_, this, ()| {
            Ok(this.inner.grid_width())
        });

        // -- getGridHeight --
        /// Returns the grid height in cells.
        /// @return integer
        methods.add_method("getGridHeight", |_, this, ()| {
            Ok(this.inner.grid_height())
        });

        // -- getGridSize --
        /// Returns the grid width and height as two values.
        /// @return integer, integer
        methods.add_method("getGridSize", |_, this, ()| {
            Ok((this.inner.grid_width(), this.inner.grid_height()))
        });

        // ── Display dimensions ──

        // -- getDisplayWidth --
        /// Returns the display width in pixels.
        /// @return integer
        methods.add_method("getDisplayWidth", |_, this, ()| {
            Ok(this.inner.display_width())
        });

        // -- getDisplayHeight --
        /// Returns the display height in pixels.
        /// @return integer
        methods.add_method("getDisplayHeight", |_, this, ()| {
            Ok(this.inner.display_height())
        });

        // -- getDisplaySize --
        /// Returns the display width and height as two values.
        /// @return integer, integer
        methods.add_method("getDisplaySize", |_, this, ()| {
            Ok((this.inner.display_width(), this.inner.display_height()))
        });

        // -- setDisplaySize --
        /// Sets the display size in pixels.
        /// @param w : integer
        /// @param h : integer
        /// @return nil
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.set_display_size(w, h);
            Ok(())
        });

        // ── Terrain ──

        // -- setTerrain --
        /// Sets the terrain type at a 1-based grid position.
        /// @param x : integer
        /// @param y : integer
        /// @param terrain_type : integer
        /// @return nil
        methods.add_method_mut(
            "setTerrain",
            |_, this, (x, y, terrain_type): (u32, u32, u32)| {
                if x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: setTerrain coordinates are 1-based".into(),
                    ));
                }
                this.inner.set_terrain(x - 1, y - 1, terrain_type);
                Ok(())
            },
        );

        // -- getTerrain --
        /// Returns the terrain type at a 1-based grid position.
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getTerrain", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: getTerrain coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_terrain(x - 1, y - 1))
        });

        // -- setTerrainData --
        /// Sets terrain types from a flat 1-based Lua table of integers (row-major).
        /// @param data : table
        /// @return nil
        methods.add_method_mut("setTerrainData", |_, this, data: LuaTable| {
            let len = data.len()? as usize;
            let mut values = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u32 = data.get(i)?;
                values.push(v);
            }
            this.inner.set_terrain_data(&values);
            Ok(())
        });

        // -- setTerrainColor --
        /// Sets the display color for a terrain type.
        /// @param terrain_type : integer
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method_mut(
            "setTerrainColor",
            |_, this, (terrain_type, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_terrain_color(terrain_type, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        // -- getTerrainColor --
        /// Returns the display color for a terrain type as r, g, b, a.
        /// @param terrain_type : integer
        /// @return number, number, number, number
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Tile descriptions ──

        // -- setTileDescription --
        /// Sets a hover tooltip string for a terrain type ID.
        /// @param type_id : integer
        /// @param desc : string
        /// @return nil
        methods.add_method_mut(
            "setTileDescription",
            |_, this, (type_id, desc): (u32, String)| {
                this.inner.set_tile_description(type_id, desc);
                Ok(())
            },
        );

        // -- getTileDescription --
        /// Returns the hover tooltip string for a terrain type ID, or nil.
        /// @param type_id : integer
        /// @return string?
        methods.add_method("getTileDescription", |_, this, type_id: u32| {
            Ok(this.inner.get_tile_description(type_id).map(|s| s.to_string()))
        });

        // ── Fog of war ──

        // -- setFogEnabled --
        /// Enables or disables fog of war.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.set_fog_enabled(enabled);
            Ok(())
        });

        // -- isFogEnabled --
        /// Returns whether fog of war is enabled.
        /// @return boolean
        methods.add_method("isFogEnabled", |_, this, ()| {
            Ok(this.inner.fog_enabled())
        });

        // -- setFogLevel --
        /// Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
        /// @param x : integer
        /// @param y : integer
        /// @param level : integer
        /// @return nil
        methods.add_method_mut("setFogLevel", |_, this, (x, y, level): (u32, u32, u8)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: setFogLevel coordinates are 1-based".into(),
                ));
            }
            this.inner.set_fog_level(x - 1, y - 1, FogLevel::from_u8(level));
            Ok(())
        });

        // -- getFogLevel --
        /// Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getFogLevel", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: getFogLevel coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_fog_level(x - 1, y - 1) as u8)
        });

        // -- setFogColor --
        /// Sets the fog overlay color.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_fog_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        // -- getFogColor --
        /// Returns the fog overlay color as r, g, b, a.
        /// @return number, number, number, number
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- setFogData --
        /// Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
        /// @param data : table
        /// @return nil
        methods.add_method_mut("setFogData", |_, this, data: LuaTable| {
            let len = data.len()? as usize;
            let mut bytes = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u8 = data.get(i)?;
                bytes.push(v);
            }
            this.inner.set_fog_data(&bytes);
            Ok(())
        });

        // ── Object types ──

        // -- addObjectType --
        /// Registers a new object type and returns its 1-based index.
        /// @param name : string
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return integer
        methods.add_method_mut(
            "addObjectType",
            |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                let idx = this.inner.add_object_type(name, [r, g, b, a.unwrap_or(1.0)]);
                Ok(idx + 1)
            },
        );

        // -- setObjectTypeVisible --
        /// Sets whether an object type (1-based index) is visible.
        /// @param type_idx : integer
        /// @param visible : boolean
        /// @return nil
        methods.add_method_mut(
            "setObjectTypeVisible",
            |_, this, (type_idx, visible): (usize, bool)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner.set_object_type_visible(type_idx - 1, visible);
                Ok(())
            },
        );

        // -- isObjectTypeVisible --
        /// Returns whether an object type (1-based index) is visible.
        /// @param type_idx : integer
        /// @return boolean
        methods.add_method("isObjectTypeVisible", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.minimap: object type index is 1-based".into(),
                ));
            }
            Ok(this.inner.is_object_type_visible(type_idx - 1))
        });

        // -- getObjectTypeCount --
        /// Returns the number of registered object types.
        /// @return integer
        methods.add_method("getObjectTypeCount", |_, this, ()| {
            Ok(this.inner.object_type_count())
        });

        // ── Objects ──

        // -- setObject --
        /// Sets or updates a tracked object on the minimap.
        /// @param id : integer
        /// @param x : number
        /// @param y : number
        /// @param type_idx : integer
        /// @param owner : integer?
        /// @return nil
        methods.add_method_mut(
            "setObject",
            |_, this, (id, x, y, type_idx, owner): (u32, f32, f32, usize, Option<u32>)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "luna.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner
                    .set_object(id, x, y, type_idx - 1, owner.unwrap_or(0));
                Ok(())
            },
        );

        // -- removeObject --
        /// Removes a tracked object by ID.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("removeObject", |_, this, id: u32| {
            Ok(this.inner.remove_object(id))
        });

        // -- clearObjects --
        /// Removes all tracked objects.
        /// @return nil
        methods.add_method_mut("clearObjects", |_, this, ()| {
            this.inner.clear_objects();
            Ok(())
        });

        // -- getObjectCount --
        /// Returns the number of tracked objects.
        /// @return integer
        methods.add_method("getObjectCount", |_, this, ()| {
            Ok(this.inner.object_count())
        });

        // ── Owner colors ──

        // -- setOwnerColor --
        /// Sets the display color for an owner/faction.
        /// @param owner : integer
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method_mut(
            "setOwnerColor",
            |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner.set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        // -- getOwnerColor --
        /// Returns the display color for an owner/faction as r, g, b, a.
        /// @param owner : integer
        /// @return number, number, number, number
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Color mode ──

        // -- setColorMode --
        /// Sets the color mode ("terrain" or "political").
        /// @param mode : string
        /// @return nil
        methods.add_method_mut("setColorMode", |_, this, mode: String| {
            let cm = ColorMode::parse_mode(&mode).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "luna.minimap: unknown color mode '{}', expected 'terrain' or 'political'",
                    mode
                ))
            })?;
            this.inner.set_color_mode(cm);
            Ok(())
        });

        // -- getColorMode --
        /// Returns the current color mode as a string.
        /// @return string
        methods.add_method("getColorMode", |_, this, ()| {
            Ok(this.inner.color_mode().as_str())
        });

        // ── Zoom and pan ──

        // -- setZoom --
        /// Sets the zoom level (minimum 0.1).
        /// @param zoom : number
        /// @return nil
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.set_zoom(zoom);
            Ok(())
        });

        // -- getZoom --
        /// Returns the current zoom level.
        /// @return number
        methods.add_method("getZoom", |_, this, ()| {
            Ok(this.inner.zoom())
        });

        // -- setCenter --
        /// Sets the center of the minimap view in grid coordinates.
        /// @param x : number
        /// @param y : number
        /// @return nil
        methods.add_method_mut("setCenter", |_, this, (x, y): (f32, f32)| {
            this.inner.set_center(x, y);
            Ok(())
        });

        // -- getCenter --
        /// Returns the center coordinates as x, y.
        /// @return number, number
        methods.add_method("getCenter", |_, this, ()| {
            Ok((this.inner.center_x(), this.inner.center_y()))
        });

        // -- getCenterX --
        /// Returns the center X coordinate.
        /// @return number
        methods.add_method("getCenterX", |_, this, ()| {
            Ok(this.inner.center_x())
        });

        // -- getCenterY --
        /// Returns the center Y coordinate.
        /// @return number
        methods.add_method("getCenterY", |_, this, ()| {
            Ok(this.inner.center_y())
        });

        // ── Viewport rectangle ──

        // -- setViewportRect --
        /// Sets the viewport rectangle overlay in grid coordinates.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return nil
        methods.add_method_mut(
            "setViewportRect",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.set_viewport_rect(x, y, w, h);
                Ok(())
            },
        );

        // -- clearViewportRect --
        /// Clears the viewport rectangle overlay.
        /// @return nil
        methods.add_method_mut("clearViewportRect", |_, this, ()| {
            this.inner.clear_viewport_rect();
            Ok(())
        });

        // -- getViewportRect --
        /// Returns the viewport rectangle as x, y, w, h or nil if not set.
        /// @return number?, number?, number?, number?
        methods.add_method("getViewportRect", |_, this, ()| {
            match this.inner.viewport_rect() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        // -- setViewportVisible --
        /// Sets whether the viewport rectangle is visible.
        /// @param visible : boolean
        /// @return nil
        methods.add_method_mut("setViewportVisible", |_, this, visible: bool| {
            this.inner.set_viewport_visible(visible);
            Ok(())
        });

        // -- isViewportVisible --
        /// Returns whether the viewport rectangle is visible.
        /// @return boolean
        methods.add_method("isViewportVisible", |_, this, ()| {
            Ok(this.inner.viewport_visible())
        });

        // -- setViewportColor --
        /// Sets the viewport rectangle color.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method_mut(
            "setViewportColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_viewport_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        // -- getViewportColor --
        /// Returns the viewport rectangle color as r, g, b, a.
        /// @return number, number, number, number
        methods.add_method("getViewportColor", |_, this, ()| {
            let c = this.inner.viewport_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        // ── Pings ──

        // -- addPing --
        /// Adds an animated ping at grid coordinates with a duration and optional color.
        /// @param x : number
        /// @param y : number
        /// @param duration : number
        /// @param r : number?
        /// @param g : number?
        /// @param b : number?
        /// @param a : number?
        /// @return nil
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addPing",
            |_, this, (x, y, duration, r, g, b, a): (f32, f32, f32, Option<f32>, Option<f32>, Option<f32>, Option<f32>)| {
                let color = [
                    r.unwrap_or(1.0),
                    g.unwrap_or(1.0),
                    b.unwrap_or(0.0),
                    a.unwrap_or(1.0),
                ];
                this.inner.add_ping(x, y, duration, color);
                Ok(())
            },
        );

        // -- getPingCount --
        /// Returns the number of active pings.
        /// @return integer
        methods.add_method("getPingCount", |_, this, ()| {
            Ok(this.inner.ping_count())
        });

        // ── Markers ──

        // -- addMarker --
        /// Adds a persistent marker and returns its auto-assigned ID.
        /// @param x : number
        /// @param y : number
        /// @param desc : string?
        /// @param r : number?
        /// @param g : number?
        /// @param b : number?
        /// @param a : number?
        /// @return integer
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addMarker",
            |_, this, (x, y, desc, r, g, b, a): (f32, f32, Option<String>, Option<f32>, Option<f32>, Option<f32>, Option<f32>)| {
                let color = [
                    r.unwrap_or(1.0),
                    g.unwrap_or(0.0),
                    b.unwrap_or(0.0),
                    a.unwrap_or(1.0),
                ];
                let id = this.inner.add_marker(x, y, desc.unwrap_or_default(), color);
                Ok(id)
            },
        );

        // -- removeMarker --
        /// Removes a marker by ID.
        /// @param id : integer
        /// @return boolean
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.remove_marker(id))
        });

        // -- hasMarker --
        /// Returns whether a marker with the given ID exists.
        /// @param id : integer
        /// @return boolean
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.has_marker(id))
        });

        // -- getMarkerDescription --
        /// Returns the description of a marker, or nil.
        /// @param id : integer
        /// @return string?
        methods.add_method("getMarkerDescription", |_, this, id: u32| {
            Ok(this.inner.get_marker_description(id).map(|s| s.to_string()))
        });

        // -- getMarkerCount --
        /// Returns the number of markers.
        /// @return integer
        methods.add_method("getMarkerCount", |_, this, ()| {
            Ok(this.inner.marker_count())
        });

        // ── Rendering options ──

        // -- setAntiAlias --
        /// Sets whether anti-aliasing is enabled.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.set_anti_alias(enabled);
            Ok(())
        });

        // -- isAntiAlias --
        /// Returns whether anti-aliasing is enabled.
        /// @return boolean
        methods.add_method("isAntiAlias", |_, this, ()| {
            Ok(this.inner.anti_alias())
        });

        // -- setClickable --
        /// Sets whether this minimap responds to click hit-testing.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method_mut("setClickable", |_, this, enabled: bool| {
            this.inner.set_clickable(enabled);
            Ok(())
        });

        // -- isClickable --
        /// Returns whether this minimap responds to click hit-testing.
        /// @return boolean
        methods.add_method("isClickable", |_, this, ()| {
            Ok(this.inner.is_clickable())
        });

        // ── Hover info ──

        // -- getHoverInfo --
        /// Returns hover tooltip text for the element under screen coordinates, or nil.
        /// @param sx : number
        /// @param sy : number
        /// @param minimap_x : number
        /// @param minimap_y : number
        /// @return string?
        methods.add_method(
            "getHoverInfo",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.get_hover_info(sx, sy, mx, my).map(|s| s.to_string()))
            },
        );

        // ── Coordinate conversion ──

        // -- screenToGrid --
        /// Converts screen coordinates to grid coordinates.
        /// @param sx : number
        /// @param sy : number
        /// @param minimap_x : number
        /// @param minimap_y : number
        /// @return number, number
        methods.add_method(
            "screenToGrid",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.screen_to_grid(sx, sy, mx, my))
            },
        );

        // -- gridToScreen --
        /// Converts grid coordinates to screen coordinates.
        /// @param gx : number
        /// @param gy : number
        /// @param minimap_x : number
        /// @param minimap_y : number
        /// @return number, number
        methods.add_method(
            "gridToScreen",
            |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.grid_to_screen(gx, gy, mx, my))
            },
        );

        // ── Update ──

        // -- update --
        /// Advances time-based effects by dt seconds (expires pings).
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Minimap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "Minimap" || name == "Object"));

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.minimap` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newMinimap --
    /// Creates a new grid-based minimap.
    /// @param grid_w : integer
    /// @param grid_h : integer
    /// @param display_w : integer?
    /// @param display_h : integer?
    /// @return Minimap
    tbl.set(
        "newMinimap",
        lua.create_function(
            |_, (grid_w, grid_h, display_w, display_h): (u32, u32, Option<u32>, Option<u32>)| {
                let dw = display_w.unwrap_or(200);
                let dh = display_h.unwrap_or(200);
                Ok(LuaMinimap {
                    inner: Minimap::new(grid_w, grid_h, dw, dh),
                })
            },
        )?,
    )?;

    luna.set("minimap", tbl)?;
    Ok(())
}
