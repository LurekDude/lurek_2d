//! `lurek.minimap` â€” Grid-based minimap with terrain, fog of war, objects, pings, and markers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::minimap::{ColorMode, FogLevel, LayerData, MarkerAnimation, Minimap};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Parse a Lua table `{r, g, b, a}` (integers 0â€“255) into a `[u8; 4]` color array.
///
/// Missing channels default to 255.
fn parse_color_table(tbl: LuaTable) -> LuaResult<[u8; 4]> {
    let r: u8 = tbl.get(1).unwrap_or(255);
    let g: u8 = tbl.get(2).unwrap_or(255);
    let b: u8 = tbl.get(3).unwrap_or(255);
    let a: u8 = tbl.get(4).unwrap_or(255);
    Ok([r, g, b, a])
}

// -------------------------------------------------------------------------------
// LuaMinimap UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Minimap`].
pub struct LuaMinimap {
    inner: Minimap,
    state: Rc<RefCell<SharedState>>,
}

impl LuaUserData for LuaMinimap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // â”€â”€ Grid queries â”€â”€

        // -- getGridWidth --
        /// Returns the grid width in cells.
        /// @return integer
        methods.add_method("getGridWidth", |_, this, ()| Ok(this.inner.grid_width()));

        // -- getGridHeight --
        /// Returns the grid height in cells.
        /// @return integer
        methods.add_method("getGridHeight", |_, this, ()| Ok(this.inner.grid_height()));

        // -- getGridSize --
        /// Returns the grid width and height as two values.
        /// @return integer, integer
        methods.add_method("getGridSize", |_, this, ()| {
            Ok((this.inner.grid_width(), this.inner.grid_height()))
        });

        // â”€â”€ Display dimensions â”€â”€

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
        /// @param w integer
        /// @param h integer
        /// @return nil
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.set_display_size(w, h);
            Ok(())
        });

        // â”€â”€ Terrain â”€â”€

        // -- setTerrain --
        /// Sets the terrain type at a 1-based grid position.
        /// @param x integer
        /// @param y integer
        /// @param terrain_type integer
        /// @return nil
        methods.add_method_mut(
            "setTerrain",
            |_, this, (x, y, terrain_type): (u32, u32, u32)| {
                if x == 0 || y == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: setTerrain coordinates are 1-based".into(),
                    ));
                }
                this.inner.set_terrain(x - 1, y - 1, terrain_type);
                Ok(())
            },
        );

        // -- getTerrain --
        /// Returns the terrain type at a 1-based grid position.
        /// @param x integer
        /// @param y integer
        /// @return integer
        methods.add_method("getTerrain", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getTerrain coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_terrain(x - 1, y - 1))
        });

        // -- setTerrainData --
        /// Sets terrain types from a flat 1-based Lua table of integers (row-major).
        /// @param data table
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
        /// @param terrain_type integer
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number?
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
        /// @param terrain_type integer
        /// @return number, number, number, number
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // â”€â”€ Tile descriptions â”€â”€

        // -- setTileDescription --
        /// Sets a hover tooltip string for a terrain type ID.
        /// @param type_id integer
        /// @param desc string
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
        /// @param type_id integer
        /// @return string?
        methods.add_method("getTileDescription", |_, this, type_id: u32| {
            Ok(this
                .inner
                .get_tile_description(type_id)
                .map(|s| s.to_string()))
        });

        // â”€â”€ Fog of war â”€â”€

        // -- setFogEnabled --
        /// Enables or disables fog of war.
        /// @param enabled boolean
        /// @return nil
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.set_fog_enabled(enabled);
            Ok(())
        });

        // -- isFogEnabled --
        /// Returns whether fog of war is enabled.
        /// @return boolean
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog_enabled()));

        // -- setFogLevel --
        /// Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
        /// @param x integer
        /// @param y integer
        /// @param level integer
        /// @return nil
        methods.add_method_mut("setFogLevel", |_, this, (x, y, level): (u32, u32, u8)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: setFogLevel coordinates are 1-based".into(),
                ));
            }
            this.inner
                .set_fog_level(x - 1, y - 1, FogLevel::from_u8(level));
            Ok(())
        });

        // -- getFogLevel --
        /// Returns the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
        /// @param x integer
        /// @param y integer
        /// @return integer
        methods.add_method("getFogLevel", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getFogLevel coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_fog_level(x - 1, y - 1) as u8)
        });

        // -- setFogColor --
        /// Sets the fog overlay color.
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number?
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
        /// @param data table
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

        // â”€â”€ Object types â”€â”€

        // -- addObjectType --
        /// Registers a new object type and returns its 1-based index.
        /// @param name string
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number?
        /// @return integer
        methods.add_method_mut(
            "addObjectType",
            |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                let idx = this
                    .inner
                    .add_object_type(name, [r, g, b, a.unwrap_or(1.0)]);
                Ok(idx + 1)
            },
        );

        // -- setObjectTypeVisible --
        /// Sets whether an object type (1-based index) is visible.
        /// @param type_idx integer
        /// @param visible boolean
        /// @return nil
        methods.add_method_mut(
            "setObjectTypeVisible",
            |_, this, (type_idx, visible): (usize, bool)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner.set_object_type_visible(type_idx - 1, visible);
                Ok(())
            },
        );

        // -- isObjectTypeVisible --
        /// Returns whether an object type (1-based index) is visible.
        /// @param type_idx integer
        /// @return boolean
        methods.add_method("isObjectTypeVisible", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: object type index is 1-based".into(),
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

        // â”€â”€ Objects â”€â”€

        // -- setObject --
        /// Sets or updates a tracked object on the minimap.
        /// @param id integer
        /// @param x number
        /// @param y number
        /// @param type_idx integer
        /// @param owner integer?
        /// @return nil
        methods.add_method_mut(
            "setObject",
            |_, this, (id, x, y, type_idx, owner): (u32, f32, f32, usize, Option<u32>)| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                this.inner
                    .set_object(id, x, y, type_idx - 1, owner.unwrap_or(0));
                Ok(())
            },
        );

        // -- removeObject --
        /// Removes a tracked object by ID.
        /// @param id integer
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

        // â”€â”€ Owner colors â”€â”€

        // -- setOwnerColor --
        /// Sets the display color for an owner/faction.
        /// @param owner integer
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number?
        /// @return nil
        methods.add_method_mut(
            "setOwnerColor",
            |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        // -- getOwnerColor --
        /// Returns the display color for an owner/faction as r, g, b, a.
        /// @param owner integer
        /// @return number, number, number, number
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // â”€â”€ Color mode â”€â”€

        // -- setColorMode --
        /// Sets the color mode ("terrain" or "political").
        /// @param mode string
        /// @return nil
        methods.add_method_mut("setColorMode", |_, this, mode: String| {
            let cm = ColorMode::parse_mode(&mode).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "lurek.minimap: unknown color mode '{}', expected 'terrain' or 'political'",
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

        // â”€â”€ Zoom and pan â”€â”€

        // -- setZoom --
        /// Sets the zoom level (minimum 0.1).
        /// @param zoom number
        /// @return nil
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.set_zoom(zoom);
            Ok(())
        });

        // -- getZoom --
        /// Returns the current zoom level.
        /// @return number
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.zoom()));

        // -- setCenter --
        /// Sets the center of the minimap view in grid coordinates.
        /// @param x number
        /// @param y number
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
        methods.add_method("getCenterX", |_, this, ()| Ok(this.inner.center_x()));

        // -- getCenterY --
        /// Returns the center Y coordinate.
        /// @return number
        methods.add_method("getCenterY", |_, this, ()| Ok(this.inner.center_y()));

        // â”€â”€ Viewport rectangle â”€â”€

        // -- setViewportRect --
        /// Sets the viewport rectangle overlay in grid coordinates.
        /// @param x number
        /// @param y number
        /// @param w number
        /// @param h number
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
        /// number?, number?, number?, number?
        /// @return nil
        methods.add_method("getViewportRect", |_, this, ()| {
            match this.inner.viewport_rect() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        // -- setViewportVisible --
        /// Sets whether the viewport rectangle is visible.
        /// @param visible boolean
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
        /// @param r number
        /// @param g number
        /// @param b number
        /// @param a number?
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

        // â”€â”€ Pings â”€â”€

        // -- addPing --
        /// Adds an animated ping at grid coordinates with a duration and optional color.
        /// @param x number
        /// @param y number
        /// @param duration number
        /// @param r number?
        /// @param g number?
        /// @param b number?
        /// @param a number?
        /// @return nil
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addPing",
            |_,
             this,
             (x, y, duration, r, g, b, a): (
                f32,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
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
        methods.add_method("getPingCount", |_, this, ()| Ok(this.inner.ping_count()));

        // â”€â”€ Markers â”€â”€

        // -- addMarker --
        /// Adds a persistent marker and returns its auto-assigned ID.
        /// @param x number
        /// @param y number
        /// @param desc string?
        /// @param r number?
        /// @param g number?
        /// @param b number?
        /// @param a number?
        /// @return integer
        #[allow(clippy::type_complexity)]
        methods.add_method_mut(
            "addMarker",
            |_,
             this,
             (x, y, desc, r, g, b, a): (
                f32,
                f32,
                Option<String>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
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
        /// Removes the minimap marker with the given integer ID, if present.
        /// @param id integer
        /// @return boolean
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.remove_marker(id))
        });

        // -- hasMarker --
        /// Returns whether a marker with the given ID exists.
        /// @param id integer
        /// @return boolean
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.has_marker(id))
        });

        // -- getMarkerDescription --
        /// Returns the description of a marker, or nil.
        /// @param id integer
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

        // â”€â”€ Marker animation â”€â”€

        // -- setMarkerAnimation --
        /// Attaches an animation to a marker. Does nothing if the ID does not exist.
        /// @param id integer
        /// @param anim_type string  -- "blink", "pulse", or "rotate"
        /// @param speed number
        /// @return nil
        methods.add_method_mut(
            "setMarkerAnimation",
            |_, this, (id, anim_type, speed): (u32, String, f32)| {
                let anim = match anim_type.as_str() {
                    "blink" => MarkerAnimation::Blink { speed, phase: 0.0 },
                    "pulse" => MarkerAnimation::Pulse { speed, phase: 0.0 },
                    "rotate" => MarkerAnimation::Rotate { speed, angle: 0.0 },
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "lurek.minimap: unknown animation type '{}', \
                             expected 'blink', 'pulse', or 'rotate'",
                            other
                        )))
                    }
                };
                this.inner.set_marker_animation(id, anim);
                Ok(())
            },
        );

        // -- clearMarkerAnimation --
        /// Removes the animation from a marker, reverting it to static.
        /// @param id integer
        /// @return nil
        methods.add_method_mut("clearMarkerAnimation", |_, this, id: u32| {
            this.inner.clear_marker_animation(id);
            Ok(())
        });

        // â”€â”€ Geometry overlay â”€â”€

        // -- drawLine --
        /// Draws a custom line segment on the minimap overlay.
        /// @param x1 number
        /// @param y1 number
        /// @param x2 number
        /// @param y2 number
        /// @param color table  -- {r, g, b, a} integers 0-255
        /// @return nil
        methods.add_method_mut(
            "drawLine",
            |_, this, (x1, y1, x2, y2, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_line(x1, y1, x2, y2, color);
                Ok(())
            },
        );

        // -- drawRect --
        /// Draws a custom rectangle on the minimap overlay.
        /// @param x number
        /// @param y number
        /// @param w number
        /// @param h number
        /// @param color table  -- {r, g, b, a} integers 0-255
        /// @return nil
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_rect(x, y, w, h, color);
                Ok(())
            },
        );

        // -- clearOverlay --
        /// Removes all custom geometry from the minimap overlay.
        /// @return nil
        methods.add_method_mut("clearOverlay", |_, this, ()| {
            this.inner.clear_overlay();
            Ok(())
        });

        // â”€â”€ Path overlay â”€â”€

        // -- showPath --
        /// Displays a pathfinding route on the minimap and returns its path ID.
        /// @param points table  -- {{ x, y }, { x, y }, ... }
        /// @param color table   -- { r, g, b, a } integers 0-255
        /// @return nil
        /// integer  -- path ID (pass to clearPath to remove it)
        methods.add_method_mut(
            "showPath",
            |_, this, (points_tbl, color_tbl): (LuaTable, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                let len = points_tbl.len()? as usize;
                let mut points = Vec::with_capacity(len);
                for i in 1..=len {
                    let pt: LuaTable = points_tbl.get(i)?;
                    let x: f32 = pt.get(1)?;
                    let y: f32 = pt.get(2)?;
                    points.push((x, y));
                }
                let id = this.inner.show_path(points, color);
                Ok(id)
            },
        );

        // -- clearPath --
        /// Removes a displayed path. If id is nil, all paths are removed.
        /// @param id integer?
        /// @return nil
        methods.add_method_mut("clearPath", |_, this, id: Option<u32>| {
            this.inner.clear_path(id);
            Ok(())
        });

        // â”€â”€ Multi-layer â”€â”€

        // -- setLayer --
        /// Switches the minimap's active render layer (0-based index).
        /// @param layer integer
        /// @return nil
        methods.add_method_mut("setLayer", |_, this, layer: usize| {
            this.inner.set_layer(layer);
            Ok(())
        });

        // -- getLayer --
        /// Returns the index of the currently active render layer.
        /// @return integer
        methods.add_method("getLayer", |_, this, ()| Ok(this.inner.get_layer()));

        // -- setLayerData --
        /// Stores tile data for a specific layer index.
        /// @param layer integer
        /// @param data table  -- flat 1-based table of terrain type integers
        /// @return nil
        methods.add_method_mut(
            "setLayerData",
            |_, this, (layer, data_tbl): (usize, LuaTable)| {
                let len = data_tbl.len()? as usize;
                let mut cells = Vec::with_capacity(len);
                for i in 1..=len {
                    let v: u8 = data_tbl.get(i)?;
                    cells.push(v);
                }
                let w = this.inner.grid_width();
                let h = this.inner.grid_height();
                this.inner.set_layer_data(
                    layer,
                    LayerData {
                        cells,
                        width: w,
                        height: h,
                    },
                );
                Ok(())
            },
        );

        // â”€â”€ Rendering options â”€â”€

        // -- setAntiAlias --
        /// Sets whether anti-aliasing is enabled.
        /// @param enabled boolean
        /// @return nil
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.set_anti_alias(enabled);
            Ok(())
        });

        // -- isAntiAlias --
        /// Returns whether anti-aliasing is enabled.
        /// @return boolean
        methods.add_method("isAntiAlias", |_, this, ()| Ok(this.inner.anti_alias()));

        // -- setClickable --
        /// Sets whether this minimap responds to click hit-testing.
        /// @param enabled boolean
        /// @return nil
        methods.add_method_mut("setClickable", |_, this, enabled: bool| {
            this.inner.set_clickable(enabled);
            Ok(())
        });

        // -- isClickable --
        /// Returns whether this minimap responds to click hit-testing.
        /// @return boolean
        methods.add_method("isClickable", |_, this, ()| Ok(this.inner.is_clickable()));

        // â”€â”€ Hover info â”€â”€

        // -- getHoverInfo --
        /// Returns hover tooltip text for the element under screen coordinates, or nil.
        /// @param sx number
        /// @param sy number
        /// @param minimap_x number
        /// @param minimap_y number
        /// @return string?
        methods.add_method(
            "getHoverInfo",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .get_hover_info(sx, sy, mx, my)
                    .map(|s| s.to_string()))
            },
        );

        // â”€â”€ Coordinate conversion â”€â”€

        // -- screenToGrid --
        /// Converts screen coordinates to grid coordinates.
        /// @param sx number
        /// @param sy number
        /// @param minimap_x number
        /// @param minimap_y number
        /// @return number, number
        methods.add_method(
            "screenToGrid",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.screen_to_grid(sx, sy, mx, my))
            },
        );

        // -- gridToScreen --
        /// Converts grid coordinates to screen coordinates.
        /// @param gx number
        /// @param gy number
        /// @param minimap_x number
        /// @param minimap_y number
        /// @return number, number
        methods.add_method(
            "gridToScreen",
            |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.grid_to_screen(gx, gy, mx, my))
            },
        );

        // â”€â”€ Update â”€â”€

        // -- update --
        /// Advances time-based effects by dt seconds (expires pings).
        /// @param dt number
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
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Minimap" || name == "Object")
        });

        // â”€â”€ Rendering â”€â”€

        // -- render --
        /// Renders the minimap to the screen at the given position.
        /// @param x number?
        /// @param y number?
        /// @return nil
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let sx = x.unwrap_or(0.0);
            let sy = y.unwrap_or(0.0);
            let cmds = this.inner.build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });

        // -- drawToImage --
        /// Renders the minimap grid to a CPU ImageData.
        /// @param pixel_size integer
        /// @return ImageData
        methods.add_method("drawToImage", |_, this, pixel_size: u32| {
            let img = this.inner.draw_to_image(pixel_size);
            Ok(img)
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.minimap` API table with the Lua VM.
///
/// @param lua &Lua
/// @param lurek &LuaTable
/// @param state Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newMinimap --
    /// Creates a new grid-based minimap.
    /// @param grid_w integer
    /// @param grid_h integer
    /// @param display_w integer?
    /// @param display_h integer?
    /// @return Minimap
    let s = state.clone();
    tbl.set(
        "newMinimap",
        lua.create_function(
            move |_, (grid_w, grid_h, display_w, display_h): (u32, u32, Option<u32>, Option<u32>)| {
                let dw = display_w.unwrap_or(200);
                let dh = display_h.unwrap_or(200);
                Ok(LuaMinimap {
                    inner: Minimap::new(grid_w, grid_h, dw, dh),
                    state: s.clone(),
                })
            },
        )?,
    )?;

    /// Namespace containing the minimap API module.
    /// Provides minimap rendering and overlay functionalities.
    lurek.set("minimap", tbl)?;
    Ok(())
}
