//! `lurek.minimap` - Grid-based minimap with terrain, fog of war, objects, pings, and markers.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::minimap::{ColorMode, FogLevel, LayerData, MarkerAnimation, Minimap};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

// Parses a Lua table `{r, g, b, a}` (integers 0-255) into a `[u8; 4]` color array.
// Missing channels default to 255.
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
        // -------------------------------------------------------------------
        // Grid Queries
        // -------------------------------------------------------------------

        // -- getGridWidth --
        /// Returns the grid width in cells.
        /// @return | integer | Grid width in cells.
        methods.add_method("getGridWidth", |_, this, ()| Ok(this.inner.grid_width()));

        // -- getGridHeight --
        /// Returns the grid height in cells.
        /// @return | integer | Grid height in cells.
        methods.add_method("getGridHeight", |_, this, ()| Ok(this.inner.grid_height()));

        // -- getGridSize --
        /// Returns the grid width and height as two values.
        /// @return | integer | Grid width in cells.
        /// @return | integer | Grid height in cells.
        methods.add_method("getGridSize", |_, this, ()| {
            Ok((this.inner.grid_width(), this.inner.grid_height()))
        });

        // -------------------------------------------------------------------
        // Display Dimensions
        // -------------------------------------------------------------------

        // -- getDisplayWidth --
        /// Returns the display width in pixels.
        /// @return | integer | Display width in pixels.
        methods.add_method("getDisplayWidth", |_, this, ()| {
            Ok(this.inner.display_width())
        });

        // -- getDisplayHeight --
        /// Returns the display height in pixels.
        /// @return | integer | Display height in pixels.
        methods.add_method("getDisplayHeight", |_, this, ()| {
            Ok(this.inner.display_height())
        });

        // -- getDisplaySize --
        /// Returns the display width and height as two values.
        /// @return | integer | Display width in pixels.
        /// @return | integer | Display height in pixels.
        methods.add_method("getDisplaySize", |_, this, ()| {
            Ok((this.inner.display_width(), this.inner.display_height()))
        });

        // -- setDisplaySize --
        /// Sets the display size in pixels.
        /// @param | w | integer | New display width in pixels.
        /// @param | h | integer | New display height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.set_display_size(w, h);
            Ok(())
        });

        // -------------------------------------------------------------------
        // Terrain
        // -------------------------------------------------------------------

        // -- setTerrain --
        /// Sets the terrain type at a 1-based grid position.
        /// @param | x | integer | 1-based grid column.
        /// @param | y | integer | 1-based grid row.
        /// @param | terrain_type | integer | Terrain type ID to store.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTerrain", |_, this, (x, y, terrain_type): (u32, u32, u32)| {
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
        /// @param | x | integer | 1-based grid column.
        /// @param | y | integer | 1-based grid row.
        /// @return | integer | Terrain type ID at the cell.
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
        /// @param | data | table | Flat row-major terrain ID table.
        /// @return | nil | No value is returned.
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
        /// @param | terrain_type | integer | Terrain type ID to recolor.
        /// @param | r | number | Red component in the range 0 to 1.
        /// @param | g | number | Green component in the range 0 to 1.
        /// @param | b | number | Blue component in the range 0 to 1.
        /// @param | a | number? | Alpha component in the range 0 to 1.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTerrainColor", |_, this, (terrain_type, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_terrain_color(terrain_type, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        // -- getTerrainColor --
        /// Returns the display color for a terrain type as r, g, b, a.
        /// @param | terrain_type | integer | Terrain type ID to query.
        /// @return | number | Red component.
        /// @return | number | Green component.
        /// @return | number | Blue component.
        /// @return | number | Alpha component.
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -------------------------------------------------------------------
        // Tile Descriptions
        // -------------------------------------------------------------------

        // -- setTileDescription --
        /// Sets a hover tooltip string for a terrain type ID.
        /// @param | type_id | integer | Terrain type ID to annotate.
        /// @param | desc | string | Tooltip text shown for that tile type.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTileDescription", |_, this, (type_id, desc): (u32, String)| {
                this.inner.set_tile_description(type_id, desc);
                Ok(())
            },
        );

        // -- getTileDescription --
        /// Returns the hover tooltip string for a terrain type ID, or nil.
        /// @param | type_id | integer | Type id.
        /// @return | string | Tile description string, or nil if none was set.
        methods.add_method("getTileDescription", |_, this, type_id: u32| {
            Ok(this
                .inner
                .get_tile_description(type_id)
                .map(|s| s.to_string()))
        });

        // -- Fog of war --

        // -- setFogEnabled --
        /// Enables or disables fog of war.
        /// @param | enabled | boolean | Whether it is enabled.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.set_fog_enabled(enabled);
            Ok(())
        });

        // -- isFogEnabled --
        /// Returns whether fog of war is enabled.
        /// @return | boolean | Whether fog of war is enabled.
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog_enabled()));

        // -- setFogLevel --
        /// Sets the fog level at a 1-based grid position (0=hidden, 1=explored, 2=visible).
        /// @param | x | integer | X position.
        /// @param | y | integer | Y position.
        /// @param | level | integer | Level name.
        /// @return | nil | No value is returned.
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
        /// @param | x | integer | X position.
        /// @param | y | integer | Y position.
        /// @return | integer | Fog level at the grid cell: 0 hidden, 1 explored, 2 visible.
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
        /// @param | r | number | Red component.
        /// @param | g | number | Green component.
        /// @param | b | number | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFogColor", |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_fog_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        // -- getFogColor --
        /// Returns the fog overlay color as r, g, b, a.
        /// @return | number | Fog red component.
        /// @return | number | Fog green component.
        /// @return | number | Fog blue component.
        /// @return | number | Fog alpha component.
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- setFogData --
        /// Sets the entire fog grid from a flat 1-based table (0=hidden, 1=explored, 2=visible).
        /// @param | data | table | Input data table.
        /// @return | nil | No value is returned.
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

        // -- Object types --

        // -- addObjectType --
        /// Registers a new object type and returns its 1-based index.
        /// @param | name | string | Name string.
        /// @param | r | number | Red component.
        /// @param | g | number | Green component.
        /// @param | b | number | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | integer | 1-based index of the new object type.
        methods.add_method_mut("addObjectType", |_, this, (name, r, g, b, a): (String, f32, f32, f32, Option<f32>)| {
                let idx = this
                    .inner
                    .add_object_type(name, [r, g, b, a.unwrap_or(1.0)]);
                Ok(idx + 1)
            },
        );

        // -- setObjectTypeVisible --
        /// Sets whether an object type (1-based index) is visible.
        /// @param | type_idx | integer | Type idx.
        /// @param | visible | boolean | Whether it is visible.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setObjectTypeVisible", |_, this, (type_idx, visible): (usize, bool)| {
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
        /// @param | type_idx | integer | Type idx.
        /// @return | boolean | Whether the object type is visible.
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
        /// @return | integer | Number of registered object types.
        methods.add_method("getObjectTypeCount", |_, this, ()| {
            Ok(this.inner.object_type_count())
        });

        // -- Objects --

        // -- setObject --
        /// Sets or updates a tracked object on the minimap.
        /// @param | id | integer | Object id.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | type_idx | integer | Type idx.
        /// @param | owner | integer? | Owner id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setObject", |_, this, (id, x, y, type_idx, owner): (u32, f32, f32, usize, Option<u32>)| {
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
        /// @param | id | integer | Object id.
        /// @return | boolean | True if the object existed and was removed.
        methods.add_method_mut("removeObject", |_, this, id: u32| {
            Ok(this.inner.remove_object(id))
        });

        // -- clearObjects --
        /// Removes all tracked objects.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearObjects", |_, this, ()| {
            this.inner.clear_objects();
            Ok(())
        });

        // -- getObjectCount --
        /// Returns the number of tracked objects.
        /// @return | integer | Number of tracked objects.
        methods.add_method("getObjectCount", |_, this, ()| {
            Ok(this.inner.object_count())
        });

        // -- Owner colors --

        // -- setOwnerColor --
        /// Sets the display color for an owner/faction.
        /// @param | owner | integer | Owner id.
        /// @param | r | number | Red component.
        /// @param | g | number | Green component.
        /// @param | b | number | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setOwnerColor", |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );

        // -- getOwnerColor --
        /// Returns the display color for an owner/faction as r, g, b, a.
        /// @param | owner | integer | Owner id.
        /// @return | number | Owner red component.
        /// @return | number | Owner green component.
        /// @return | number | Owner blue component.
        /// @return | number | Owner alpha component.
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- Color mode --

        // -- setColorMode --
        /// Sets the color mode ("terrain" or "political").
        /// @param | mode | string | Mode name.
        /// @return | nil | No value is returned.
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
        /// @return | string | Current color mode string.
        methods.add_method("getColorMode", |_, this, ()| {
            Ok(this.inner.color_mode().as_str())
        });

        // -- Zoom and pan --

        // -- setZoom --
        /// Sets the zoom level (minimum 0.1).
        /// @param | zoom | number | Zoom factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.set_zoom(zoom);
            Ok(())
        });

        // -- getZoom --
        /// Returns the current zoom level.
        /// @return | number | Current zoom level.
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.zoom()));

        // -- setCenter --
        /// Sets the center of the minimap view in grid coordinates.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCenter", |_, this, (x, y): (f32, f32)| {
            this.inner.set_center(x, y);
            Ok(())
        });

        // -- getCenter --
        /// Returns the center coordinates as x, y.
        /// @return | number | Center X coordinate.
        /// @return | number | Center Y coordinate.
        methods.add_method("getCenter", |_, this, ()| {
            Ok((this.inner.center_x(), this.inner.center_y()))
        });

        // -- getCenterX --
        /// Returns the center X coordinate.
        /// @return | number | Center X coordinate.
        methods.add_method("getCenterX", |_, this, ()| Ok(this.inner.center_x()));

        // -- getCenterY --
        /// Returns the center Y coordinate.
        /// @return | number | Center Y coordinate.
        methods.add_method("getCenterY", |_, this, ()| Ok(this.inner.center_y()));

        // -- Viewport rectangle --

        // -- setViewportRect --
        /// Sets the viewport rectangle overlay in grid coordinates.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | w | number | Width value.
        /// @param | h | number | Height value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewportRect", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.set_viewport_rect(x, y, w, h);
                Ok(())
            },
        );

        // -- clearViewportRect --
        /// Clears the viewport rectangle overlay.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearViewportRect", |_, this, ()| {
            this.inner.clear_viewport_rect();
            Ok(())
        });

        // -- getViewportRect --
        /// Returns the viewport rectangle as x, y, w, h or nil if not set.
        /// number?, number?, number?, number?
        /// @return | nil | No value is returned.
        methods.add_method("getViewportRect", |_, this, ()| {
            match this.inner.viewport_rect() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });

        // -- setViewportVisible --
        /// Sets whether the viewport rectangle is visible.
        /// @param | visible | boolean | Whether it is visible.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewportVisible", |_, this, visible: bool| {
            this.inner.set_viewport_visible(visible);
            Ok(())
        });

        // -- isViewportVisible --
        /// Returns whether the viewport rectangle is visible.
        /// @return | boolean | Whether the viewport rectangle is visible.
        methods.add_method("isViewportVisible", |_, this, ()| {
            Ok(this.inner.viewport_visible())
        });

        // -- setViewportColor --
        /// Sets the viewport rectangle color.
        /// @param | r | number | Red component.
        /// @param | g | number | Green component.
        /// @param | b | number | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewportColor", |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_viewport_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );

        // -- getViewportColor --
        /// Returns the viewport rectangle color as r, g, b, a.
        /// @return | number | Viewport red component.
        /// @return | number | Viewport green component.
        /// @return | number | Viewport blue component.
        /// @return | number | Viewport alpha component.
        methods.add_method("getViewportColor", |_, this, ()| {
            let c = this.inner.viewport_color();
            Ok((c[0], c[1], c[2], c[3]))
        });

        // -- Pings --

        // -- addPing --
        /// Adds an animated ping at grid coordinates with a duration and optional color.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | duration | number | Duration in seconds.
        /// @param | r | number? | Red component.
        /// @param | g | number? | Green component.
        /// @param | b | number? | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | nil | No value is returned.
        #[allow(clippy::type_complexity)]
        methods.add_method_mut("addPing", |_,
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
        /// @return | integer | Number of active pings.
        methods.add_method("getPingCount", |_, this, ()| Ok(this.inner.ping_count()));

        // -- Markers --

        // -- addMarker --
        /// Adds a persistent marker and returns its auto-assigned ID.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | desc | string? | Marker description.
        /// @param | r | number? | Red component.
        /// @param | g | number? | Green component.
        /// @param | b | number? | Blue component.
        /// @param | a | number? | Alpha component.
        /// @return | integer | Auto-assigned marker ID.
        #[allow(clippy::type_complexity)]
        methods.add_method_mut("addMarker", |_,
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
        /// @param | id | integer | Object id.
        /// @return | boolean | True if the marker existed and was removed.
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.remove_marker(id))
        });

        // -- hasMarker --
        /// Returns whether a marker with the given ID exists.
        /// @param | id | integer | Object id.
        /// @return | boolean | Whether a marker with the given ID exists.
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.has_marker(id))
        });

        // -- getMarkerDescription --
        /// Returns the description of a marker, or nil.
        /// @param | id | integer | Object id.
        /// @return | string | Marker description string, or nil if not found.
        methods.add_method("getMarkerDescription", |_, this, id: u32| {
            Ok(this.inner.get_marker_description(id).map(|s| s.to_string()))
        });

        // -- getMarkerCount --
        /// Returns the number of markers.
        /// @return | integer | Number of markers.
        methods.add_method("getMarkerCount", |_, this, ()| {
            Ok(this.inner.marker_count())
        });

        // -- Marker animation --

        // -- setMarkerAnimation --
        /// Attaches an animation to a marker. Does nothing if the ID does not exist.
        /// @param | id | integer | Object id.
        /// @param | anim_type | string | "blink", "pulse", or "rotate".
        /// @param | speed | number | Speed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setMarkerAnimation", |_, this, (id, anim_type, speed): (u32, String, f32)| {
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
        /// @param | id | integer | Object id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearMarkerAnimation", |_, this, id: u32| {
            this.inner.clear_marker_animation(id);
            Ok(())
        });

        // -- Geometry overlay --

        // -- drawLine --
        /// Draws a custom line segment on the minimap overlay.
        /// @param | x1 | number | End X position.
        /// @param | y1 | number | End Y position.
        /// @param | x2 | number | Second X position.
        /// @param | y2 | number | Second Y position.
        /// @param | color | table | {r, g, b, a} integers 0-255.
        /// @return | nil | No value is returned.
        methods.add_method_mut("drawLine", |_, this, (x1, y1, x2, y2, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_line(x1, y1, x2, y2, color);
                Ok(())
            },
        );

        // -- drawRect --
        /// Draws a custom rectangle on the minimap overlay.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | w | number | Width value.
        /// @param | h | number | Height value.
        /// @param | color | table | {r, g, b, a} integers 0-255.
        /// @return | nil | No value is returned.
        methods.add_method_mut("drawRect", |_, this, (x, y, w, h, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_rect(x, y, w, h, color);
                Ok(())
            },
        );

        // -- clearOverlay --
        /// Removes all custom geometry from the minimap overlay.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearOverlay", |_, this, ()| {
            this.inner.clear_overlay();
            Ok(())
        });

        // -- Path overlay --

        // -- showPath --
        /// Displays a pathfinding route on the minimap and returns its path ID.
        /// @param | points | table | {{ x, y }, { x, y }, ... }.
        /// @param | color | table | { r, g, b, a } integers 0-255.
        /// @return | nil | No value is returned.
        /// integer  -- path ID (pass to clearPath to remove it)
        methods.add_method_mut("showPath", |_, this, (points_tbl, color_tbl): (LuaTable, LuaTable)| {
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
        /// @param | id | integer? | Object id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearPath", |_, this, id: Option<u32>| {
            this.inner.clear_path(id);
            Ok(())
        });

        // -- Multi-layer --

        // -- setLayer --
        /// Switches the minimap's active render layer (0-based index).
        /// @param | layer | integer | Layer index.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayer", |_, this, layer: usize| {
            this.inner.set_layer(layer);
            Ok(())
        });

        // -- getLayer --
        /// Returns the index of the currently active render layer.
        /// @return | integer | Index of the currently active render layer.
        methods.add_method("getLayer", |_, this, ()| Ok(this.inner.get_layer()));

        // -- setLayerData --
        /// Stores tile data for a specific layer index.
        /// @param | layer | integer | Layer index.
        /// @param | data | table | flat 1-based table of terrain type integers.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayerData", |_, this, (layer, data_tbl): (usize, LuaTable)| {
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

        // -- Rendering options --

        // -- setAntiAlias --
        /// Sets whether anti-aliasing is enabled.
        /// @param | enabled | boolean | Whether it is enabled.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.set_anti_alias(enabled);
            Ok(())
        });

        // -- isAntiAlias --
        /// Returns whether anti-aliasing is enabled.
        /// @return | boolean | Whether anti-aliasing is enabled.
        methods.add_method("isAntiAlias", |_, this, ()| Ok(this.inner.anti_alias()));

        // -- setClickable --
        /// Sets whether this minimap responds to click hit-testing.
        /// @param | enabled | boolean | Whether it is enabled.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setClickable", |_, this, enabled: bool| {
            this.inner.set_clickable(enabled);
            Ok(())
        });

        // -- isClickable --
        /// Returns whether this minimap responds to click hit-testing.
        /// @return | boolean | Whether the minimap responds to click hit-testing.
        methods.add_method("isClickable", |_, this, ()| Ok(this.inner.is_clickable()));

        // -- Hover info --

        // -- getHoverInfo --
        /// Returns hover tooltip text for the element under screen coordinates, or nil.
        /// @param | sx | number | Screen X position.
        /// @param | sy | number | Screen Y position.
        /// @param | minimap_x | number | Minimap x value.
        /// @param | minimap_y | number | Minimap y value.
        /// @return | string | Hover tooltip string, or nil if nothing is under the cursor.
        methods.add_method("getHoverInfo", |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .get_hover_info(sx, sy, mx, my)
                    .map(|s| s.to_string()))
            },
        );

        // -- Coordinate conversion --

        // -- screenToGrid --
        /// Converts screen coordinates to grid coordinates.
        /// @param | sx | number | Screen X position.
        /// @param | sy | number | Screen Y position.
        /// @param | minimap_x | number | Minimap x value.
        /// @param | minimap_y | number | Minimap y value.
        /// @return | number | Grid X coordinate.
        /// @return | number | Grid Y coordinate.
        methods.add_method("screenToGrid", |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.screen_to_grid(sx, sy, mx, my))
            },
        );

        // -- gridToScreen --
        /// Converts grid coordinates to screen coordinates.
        /// @param | gx | number | X-axis value.
        /// @param | gy | number | Y-axis value.
        /// @param | minimap_x | number | Minimap x value.
        /// @param | minimap_y | number | Minimap y value.
        /// @return | number | Screen X coordinate.
        /// @return | number | Screen Y coordinate.
        methods.add_method("gridToScreen", |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.grid_to_screen(gx, gy, mx, my))
            },
        );

        // -- Update --

        // -- update --
        /// Advances time-based effects by dt seconds (expires pings).
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LMinimap".
        methods.add_method("type", |_, _, ()| Ok("LMinimap"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Name string.
        /// @return | boolean | True if the given type name matches this object.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMinimap" || name == "Minimap" || name == "Object")
        });

        // -- Rendering --

        // -- render --
        /// Renders the minimap to the screen at the given position.
        /// @param | x | number? | X position.
        /// @param | y | number? | Y position.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let sx = x.unwrap_or(0.0);
            let sy = y.unwrap_or(0.0);
            let cmds = this.inner.build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });

        // -- drawToImage --
        /// Renders the minimap grid to a CPU ImageData.
        /// @param | pixel_size | integer | Pixel size in source cells.
        /// @return | ImageData | Image data object.
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
/// @param | lua | Lua | Active Lua state.
/// @param | lurek | table | Root `lurek` API table.
/// @param | state | Rc<RefCell<SharedState>> | Shared engine state.
///
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newMinimap --
    /// Creates a new grid-based minimap.
    /// @param | grid_w | integer | Grid width.
    /// @param | grid_h | integer | Grid height.
    /// @param | display_w | integer? | Display width in pixels.
    /// @param | display_h | integer? | Display height in pixels.
    /// @return | Minimap | New grid-based minimap.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set("newMinimap", lua.create_function(
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
