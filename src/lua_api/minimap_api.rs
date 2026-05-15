//! `lurek.minimap` -- Lua bindings for grid minimaps, terrain colors, fog, object markers, overlays, layers, hover conversion, and render command output.

use super::camera_api::LuaCamera2D;
use super::render_api::LuaImage;
use super::SharedState;
use crate::minimap::{ColorMode, FogLevel, LayerData, MarkerAnimation, Minimap};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Reads an RGBA byte color from a Lua array table, defaulting missing channels to 255.
fn parse_color_table(tbl: LuaTable) -> LuaResult<[u8; 4]> {
    let r: u8 = tbl.get(1).unwrap_or(255);
    let g: u8 = tbl.get(2).unwrap_or(255);
    let b: u8 = tbl.get(3).unwrap_or(255);
    let a: u8 = tbl.get(4).unwrap_or(255);
    Ok([r, g, b, a])
}
/// Resolves a `LuaImage` icon handle and display size for minimap object and marker textures.
fn parse_lua_image_icon(
    image_ud: LuaAnyUserData,
    default_width: Option<f32>,
    default_height: Option<f32>,
    method_name: &str,
) -> LuaResult<(
    crate::runtime::resource_keys::TextureKey,
    f32,
    f32,
    f32,
    f32,
)> {
    let image = image_ud.borrow::<LuaImage>().map_err(|_| {
        LuaError::RuntimeError(format!(
            "lurek.minimap: {} expects an LImage from lurek.render.newImage()",
            method_name
        ))
    })?;
    let (texture_width, texture_height) = {
        let state = image.state.borrow();
        let Some(texture) = state.textures.get(image.key) else {
            return Err(LuaError::RuntimeError(format!(
                "lurek.minimap: {} received an image whose texture is no longer resident",
                method_name
            )));
        };
        (texture.width as f32, texture.height as f32)
    };
    Ok((
        image.key,
        texture_width,
        texture_height,
        default_width.unwrap_or(texture_width),
        default_height.unwrap_or(texture_height),
    ))
}
/// Lua-side wrapper for a minimap instance and access to render command state.
pub struct LuaMinimap {
    /// Wrapped minimap model.
    inner: Minimap,
    /// Shared runtime state used to enqueue render commands.
    state: Rc<RefCell<SharedState>>,
}
/// Provides Lua methods for minimap content, overlays, layers, interaction, and rendering.
impl LuaUserData for LuaMinimap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getGridWidth --
        /// Returns the minimap grid width. This method is available to Lua scripts.
        /// @return | integer | Grid width in cells.
        methods.add_method("getGridWidth", |_, this, ()| Ok(this.inner.grid_width()));
        // -- getGridHeight --
        /// Returns the minimap grid height. This method is available to Lua scripts.
        /// @return | integer | Grid height in cells.
        methods.add_method("getGridHeight", |_, this, ()| Ok(this.inner.grid_height()));
        // -- getCellCount --
        /// Returns the total number of grid cells.
        /// @return | integer | Cell count.
        methods.add_method("getCellCount", |_, this, ()| Ok(this.inner.grid_size()));
        // -- getGridSize --
        /// Returns the minimap grid size. This method is available to Lua scripts.
        /// @return | integer | Grid width in cells.
        /// @return | integer | Grid height in cells.
        methods.add_method("getGridSize", |_, this, ()| {
            Ok((this.inner.grid_width(), this.inner.grid_height()))
        });
        // -- getDisplayWidth --
        /// Returns the minimap display width.
        /// @return | integer | Display width in pixels.
        methods.add_method("getDisplayWidth", |_, this, ()| {
            Ok(this.inner.display_width())
        });
        // -- getDisplayHeight --
        /// Returns the minimap display height.
        /// @return | integer | Display height in pixels.
        methods.add_method("getDisplayHeight", |_, this, ()| {
            Ok(this.inner.display_height())
        });
        // -- getDisplaySize --
        /// Returns the minimap display size. This method is available to Lua scripts.
        /// @return | integer | Display width in pixels.
        /// @return | integer | Display height in pixels.
        methods.add_method("getDisplaySize", |_, this, ()| {
            Ok((this.inner.display_width(), this.inner.display_height()))
        });
        // -- setDisplaySize --
        /// Sets the minimap display size. This method is available to Lua scripts.
        /// @param | w | integer | Display width in pixels.
        /// @param | h | integer | Display height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setDisplaySize", |_, this, (w, h): (u32, u32)| {
            this.inner.set_display_size(w, h);
            Ok(())
        });
        // -- setTerrain --
        /// Sets terrain type for a one-based grid cell.
        /// @param | x | integer | One-based grid x coordinate.
        /// @param | y | integer | One-based grid y coordinate.
        /// @param | terrain_type | integer | Terrain type id.
        /// @return | nil | No value is returned.
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
        /// Returns terrain type for a one-based grid cell.
        /// @param | x | integer | One-based grid x coordinate.
        /// @param | y | integer | One-based grid y coordinate.
        /// @return | integer | Terrain type id.
        methods.add_method("getTerrain", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getTerrain coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_terrain(x - 1, y - 1))
        });
        // -- setTerrainData --
        /// Replaces terrain data from a flat array table.
        /// @param | data | table | Array table of terrain type ids.
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
        /// Sets RGBA color for a terrain type. This method is available to Lua scripts.
        /// @param | terrain_type | integer | Terrain type id.
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number | Optional alpha channel, defaulting to 1.0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setTerrainColor",
            |_, this, (terrain_type, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_terrain_color(terrain_type, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );
        // -- getTerrainColor --
        /// Returns RGBA color for a terrain type.
        /// @param | terrain_type | integer | Terrain type id.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getTerrainColor", |_, this, terrain_type: u32| {
            let c = this.inner.get_terrain_color(terrain_type);
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setTileDescription --
        /// Sets text description for a tile type.
        /// @param | type_id | integer | Tile type id.
        /// @param | desc | string | Description text.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setTileDescription",
            |_, this, (type_id, desc): (u32, String)| {
                this.inner.set_tile_description(type_id, desc);
                Ok(())
            },
        );
        // -- getTileDescription --
        /// Returns text description for a tile type.
        /// @param | type_id | integer | Tile type id.
        /// @return | string | Description text, or nil when missing.
        methods.add_method("getTileDescription", |_, this, type_id: u32| {
            Ok(this
                .inner
                .get_tile_description(type_id)
                .map(|s| s.to_string()))
        });
        // -- setFogEnabled --
        /// Enables or disables fog display. This method is available to Lua scripts.
        /// @param | enabled | boolean | Fog enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setFogEnabled", |_, this, enabled: bool| {
            this.inner.set_fog_enabled(enabled);
            Ok(())
        });
        // -- isFogEnabled --
        /// Returns whether fog display is enabled.
        /// @return | boolean | True when fog is enabled.
        methods.add_method("isFogEnabled", |_, this, ()| Ok(this.inner.fog_enabled()));
        // -- setFogLevel --
        /// Sets fog level for a one-based grid cell.
        /// @param | x | integer | One-based grid x coordinate.
        /// @param | y | integer | One-based grid y coordinate.
        /// @param | level | integer | Fog level byte.
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
        /// Returns fog level for a one-based grid cell.
        /// @param | x | integer | One-based grid x coordinate.
        /// @param | y | integer | One-based grid y coordinate.
        /// @return | integer | Fog level byte.
        methods.add_method("getFogLevel", |_, this, (x, y): (u32, u32)| {
            if x == 0 || y == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: getFogLevel coordinates are 1-based".into(),
                ));
            }
            Ok(this.inner.get_fog_level(x - 1, y - 1) as u8)
        });
        // -- setFogColor --
        /// Sets the fog overlay color. This method is available to Lua scripts.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number? | Lua argument for `a`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setFogColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_fog_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );
        // -- getFogColor --
        /// Returns the fog overlay color. This method is available to Lua scripts.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getFogColor", |_, this, ()| {
            let c = this.inner.fog_color();
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setFogData --
        /// Replaces fog data from a flat array table.
        /// @param | data | table | Array table of fog level bytes.
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
        // -- addObjectType --
        /// Adds an object type and returns its one-based index.
        /// @param | name | string | String value for `name`.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number? | Lua argument for `a`.
        /// @return | integer | One-based object type index.
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
        /// Sets visibility for an object type by one-based index.
        /// @param | type_idx | integer | One-based object type index.
        /// @param | visible | boolean | Visibility flag.
        /// @return | nil | No value is returned.
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
        /// Returns visibility for an object type by one-based index.
        /// @param | type_idx | integer | One-based object type index.
        /// @return | boolean | True when the object type is visible.
        methods.add_method("isObjectTypeVisible", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: object type index is 1-based".into(),
                ));
            }
            Ok(this.inner.is_object_type_visible(type_idx - 1))
        });
        // -- getObjectTypeCount --
        /// Returns the number of object types.
        /// @return | integer | Object type count.
        methods.add_method("getObjectTypeCount", |_, this, ()| {
            Ok(this.inner.object_type_count())
        });
        // -- setObjectTypeTexture --
        /// Assigns an image texture to an object type.
        /// @param | type_idx | integer | One-based object type index.
        /// @param | image_ud | LImage | Image handle from `lurek.render.newImage`.
        /// @param | width | number | Optional display width.
        /// @param | height | number | Optional display height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setObjectTypeTexture",
            |_,
             this,
             (type_idx, image_ud, width, height): (
                usize,
                LuaAnyUserData,
                Option<f32>,
                Option<f32>,
            )| {
                if type_idx == 0 {
                    return Err(LuaError::RuntimeError(
                        "lurek.minimap: object type index is 1-based".into(),
                    ));
                }
                let (texture_key, tex_w, tex_h, display_w, display_h) =
                    parse_lua_image_icon(image_ud, width, height, "setObjectTypeTexture")?;
                this.inner.set_object_type_texture(
                    type_idx - 1,
                    texture_key,
                    tex_w,
                    tex_h,
                    display_w,
                    display_h,
                );
                Ok(())
            },
        );
        // -- clearObjectTypeTexture --
        /// Clears image texture for an object type.
        /// @param | type_idx | integer | One-based object type index.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearObjectTypeTexture", |_, this, type_idx: usize| {
            if type_idx == 0 {
                return Err(LuaError::RuntimeError(
                    "lurek.minimap: object type index is 1-based".into(),
                ));
            }
            this.inner.clear_object_type_texture(type_idx - 1);
            Ok(())
        });
        // -- setObject --
        /// Adds or updates an object on the minimap.
        /// @param | id | integer | Object id.
        /// @param | x | number | Object x coordinate.
        /// @param | y | number | Object y coordinate.
        /// @param | type_idx | integer | One-based object type index.
        /// @param | owner | integer | Optional owner id, defaulting to 0.
        /// @return | nil | No value is returned.
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
        /// Removes an object by id. This method is available to Lua scripts.
        /// @param | id | integer | Object id.
        /// @return | boolean | True when an object was removed.
        methods.add_method_mut("removeObject", |_, this, id: u32| {
            Ok(this.inner.remove_object(id))
        });
        // -- clearObjects --
        /// Clears all objects from the minimap.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearObjects", |_, this, ()| {
            this.inner.clear_objects();
            Ok(())
        });
        // -- getObjectCount --
        /// Returns the number of objects on the minimap.
        /// @return | integer | Object count.
        methods.add_method("getObjectCount", |_, this, ()| {
            Ok(this.inner.object_count())
        });
        // -- setOwnerColor --
        /// Sets RGBA color for an owner id. This method is available to Lua scripts.
        /// @param | owner | integer | Lua argument for `owner`.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number? | Lua argument for `a`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setOwnerColor",
            |_, this, (owner, r, g, b, a): (u32, f32, f32, f32, Option<f32>)| {
                this.inner
                    .set_owner_color(owner, [r, g, b, a.unwrap_or(1.0)]);
                Ok(())
            },
        );
        // -- getOwnerColor --
        /// Returns RGBA color for an owner id. This method is available to Lua scripts.
        /// @param | owner | integer | Owner id.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getOwnerColor", |_, this, owner: u32| {
            let c = this.inner.get_owner_color(owner);
            Ok((c[0], c[1], c[2], c[3]))
        });
        // -- setColorMode --
        /// Sets the minimap color mode. This method is available to Lua scripts.
        /// @param | mode | string | Color mode name, expected `terrain` or `political`.
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
        /// Returns the current minimap color mode.
        /// @return | string | Color mode name.
        methods.add_method("getColorMode", |_, this, ()| {
            Ok(this.inner.color_mode().as_str())
        });
        // -- setZoom --
        /// Sets minimap zoom. This method is available to Lua scripts.
        /// @param | zoom | number | Zoom value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setZoom", |_, this, zoom: f32| {
            this.inner.set_zoom(zoom);
            Ok(())
        });
        // -- getZoom --
        /// Returns minimap zoom. This method is available to Lua scripts.
        /// @return | number | Zoom value.
        methods.add_method("getZoom", |_, this, ()| Ok(this.inner.zoom()));
        // -- setCenter --
        /// Sets minimap world center. This method is available to Lua scripts.
        /// @param | x | number | Center x coordinate.
        /// @param | y | number | Center y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setCenter", |_, this, (x, y): (f32, f32)| {
            this.inner.set_center(x, y);
            Ok(())
        });
        // -- trackCamera --
        /// Centers the minimap and viewport rectangle from a camera handle.
        /// @param | camera_ud | LCamera | Camera handle from `lurek.camera.newCamera`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("trackCamera", |_, this, camera_ud: LuaAnyUserData| {
            let camera = camera_ud.borrow::<LuaCamera2D>().map_err(|_| {
                LuaError::RuntimeError(
                    "lurek.minimap: trackCamera expects an LCamera from lurek.camera.newCamera()"
                        .into(),
                )
            })?;
            let (camera_x, camera_y) = camera.position();
            let (vx, vy, vw, vh) = camera.visible_area();
            this.inner.set_center(camera_x, camera_y);
            this.inner.set_viewport_rect(vx, vy, vw, vh);
            Ok(())
        });
        // -- revealRadius --
        /// Reveals fog inside a world-space radius.
        /// @param | cx | number | Center x coordinate.
        /// @param | cy | number | Center y coordinate.
        /// @param | radius | number | Reveal radius.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "revealRadius",
            |_, this, (cx, cy, radius): (f32, f32, f32)| {
                this.inner.reveal_radius(cx, cy, radius);
                Ok(())
            },
        );
        // -- getCenter --
        /// Returns minimap world center. This method is available to Lua scripts.
        /// @return | number | Center x coordinate.
        /// @return | number | Center y coordinate.
        methods.add_method("getCenter", |_, this, ()| {
            Ok((this.inner.center_x(), this.inner.center_y()))
        });
        // -- getCenterX --
        /// Returns minimap world center x coordinate.
        /// @return | number | Center x coordinate.
        methods.add_method("getCenterX", |_, this, ()| Ok(this.inner.center_x()));
        // -- getCenterY --
        /// Returns minimap world center y coordinate.
        /// @return | number | Center y coordinate.
        methods.add_method("getCenterY", |_, this, ()| Ok(this.inner.center_y()));
        // -- setViewportRect --
        /// Sets the visible viewport rectangle shown on the minimap.
        /// @param | x | number | Numeric `x` argument for this call.
        /// @param | y | number | Numeric `y` argument for this call.
        /// @param | w | number | Lua argument for `w`.
        /// @param | h | number | Lua argument for `h`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setViewportRect",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.inner.set_viewport_rect(x, y, w, h);
                Ok(())
            },
        );
        // -- clearViewportRect --
        /// Clears the viewport rectangle. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearViewportRect", |_, this, ()| {
            this.inner.clear_viewport_rect();
            Ok(())
        });
        // -- getViewportRect --
        /// Returns the viewport rectangle when one is set.
        /// @return | LuaValue | X coordinate, or nil.
        /// @return | LuaValue | Y coordinate, or nil.
        /// @return | LuaValue | Width, or nil.
        /// @return | LuaValue | Height, or nil.
        methods.add_method("getViewportRect", |_, this, ()| {
            match this.inner.viewport_rect() {
                Some((x, y, w, h)) => Ok((Some(x), Some(y), Some(w), Some(h))),
                None => Ok((None, None, None, None)),
            }
        });
        // -- setViewportVisible --
        /// Sets whether the viewport rectangle is visible.
        /// @param | visible | boolean | Visibility flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setViewportVisible", |_, this, visible: bool| {
            this.inner.set_viewport_visible(visible);
            Ok(())
        });
        // -- isViewportVisible --
        /// Returns whether the viewport rectangle is visible.
        /// @return | boolean | True when visible.
        methods.add_method("isViewportVisible", |_, this, ()| {
            Ok(this.inner.viewport_visible())
        });
        // -- setViewportColor --
        /// Sets the viewport rectangle color.
        /// @param | r | number | Lua argument for `r`.
        /// @param | g | number | Lua argument for `g`.
        /// @param | b | number | Lua argument for `b`.
        /// @param | a | number? | Lua argument for `a`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setViewportColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                this.inner.set_viewport_color([r, g, b, a.unwrap_or(0.8)]);
                Ok(())
            },
        );
        // -- getViewportColor --
        /// Returns the viewport rectangle color.
        /// @return | number | Red channel.
        /// @return | number | Green channel.
        /// @return | number | Blue channel.
        /// @return | number | Alpha channel.
        methods.add_method("getViewportColor", |_, this, ()| {
            let c = this.inner.viewport_color();
            Ok((c[0], c[1], c[2], c[3]))
        });
        #[allow(clippy::type_complexity)]
        // -- addPing --
        /// Adds a timed ping effect at a minimap position.
        /// @param | x | number | Ping x coordinate.
        /// @param | y | number | Ping y coordinate.
        /// @param | duration | number | Ping duration in seconds.
        /// @return | nil | No value is returned.
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
        /// @return | integer | Ping count.
        methods.add_method("getPingCount", |_, this, ()| Ok(this.inner.ping_count()));
        #[allow(clippy::type_complexity)]
        // -- addMarker --
        /// Adds a marker and returns its id. This method is available to Lua scripts.
        /// @param | x | number | Marker x coordinate.
        /// @param | y | number | Marker y coordinate.
        /// @param | desc | string | Optional marker description.
        /// @return | integer | Marker id.
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
        /// Removes a marker by id. This method is available to Lua scripts.
        /// @param | id | integer | Marker id.
        /// @return | boolean | True when a marker was removed.
        methods.add_method_mut("removeMarker", |_, this, id: u32| {
            Ok(this.inner.remove_marker(id))
        });
        // -- hasMarker --
        /// Returns whether a marker id exists.
        /// @param | id | integer | Marker id.
        /// @return | boolean | True when the marker exists.
        methods.add_method("hasMarker", |_, this, id: u32| {
            Ok(this.inner.has_marker(id))
        });
        // -- getMarkerDescription --
        /// Returns a marker description by id.
        /// @param | id | integer | Marker id.
        /// @return | string | Marker description, or nil when missing.
        methods.add_method("getMarkerDescription", |_, this, id: u32| {
            Ok(this.inner.get_marker_description(id).map(|s| s.to_string()))
        });
        // -- getMarkerCount --
        /// Returns the number of markers. This method is available to Lua scripts.
        /// @return | integer | Marker count.
        methods.add_method("getMarkerCount", |_, this, ()| {
            Ok(this.inner.marker_count())
        });
        // -- setMarkerTexture --
        /// Assigns an image texture to a marker.
        /// @param | id | integer | Marker id.
        /// @param | image_ud | LImage | Image handle from `lurek.render.newImage`.
        /// @param | width | number | Optional display width.
        /// @param | height | number | Optional display height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setMarkerTexture",
            |_, this, (id, image_ud, width, height): (u32, LuaAnyUserData, Option<f32>, Option<f32>)| {
                let (texture_key, tex_w, tex_h, display_w, display_h) =
                    parse_lua_image_icon(image_ud, width, height, "setMarkerTexture")?;
                this.inner.set_marker_texture(id, texture_key, tex_w, tex_h, display_w, display_h);
                Ok(())
            },
        );
        // -- clearMarkerTexture --
        /// Clears image texture from a marker.
        /// @param | id | integer | Marker id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearMarkerTexture", |_, this, id: u32| {
            this.inner.clear_marker_texture(id);
            Ok(())
        });
        // -- setMarkerAnimation --
        /// Sets marker animation by type name.
        /// @param | id | integer | Marker id.
        /// @param | anim_type | string | Animation type: `blink`, `pulse`, or `rotate`.
        /// @param | speed | number | Animation speed.
        /// @return | nil | No value is returned.
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
        /// Clears marker animation by id. This method is available to Lua scripts.
        /// @param | id | integer | Marker id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearMarkerAnimation", |_, this, id: u32| {
            this.inner.clear_marker_animation(id);
            Ok(())
        });
        // -- drawLine --
        /// Adds an overlay line. This method is available to Lua scripts.
        /// @param | x1 | number | Lua argument for `x1`.
        /// @param | y1 | number | Lua argument for `y1`.
        /// @param | x2 | number | Lua argument for `x2`.
        /// @param | y2 | number | Lua argument for `y2`.
        /// @param | color_tbl | table | Lua argument for `color_tbl`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "drawLine",
            |_, this, (x1, y1, x2, y2, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_line(x1, y1, x2, y2, color);
                Ok(())
            },
        );
        // -- drawRect --
        /// Adds an overlay rectangle. This method is available to Lua scripts.
        /// @param | x | number | Numeric `x` argument for this call.
        /// @param | y | number | Numeric `y` argument for this call.
        /// @param | w | number | Lua argument for `w`.
        /// @param | h | number | Lua argument for `h`.
        /// @param | color_tbl | table | Lua argument for `color_tbl`.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, color_tbl): (f32, f32, f32, f32, LuaTable)| {
                let color = parse_color_table(color_tbl)?;
                this.inner.draw_rect(x, y, w, h, color);
                Ok(())
            },
        );
        // -- clearOverlay --
        /// Clears overlay shapes. This method is available to Lua scripts.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearOverlay", |_, this, ()| {
            this.inner.clear_overlay();
            Ok(())
        });
        // -- getOverlayShapeCount --
        /// Returns the number of overlay shapes.
        /// @return | integer | Overlay shape count.
        methods.add_method("getOverlayShapeCount", |_, this, ()| {
            Ok(this.inner.overlay_shapes().len())
        });
        // -- showPath --
        /// Adds a colored path overlay and returns its id.
        /// @param | points_tbl | table | Array table of point arrays `{x, y}`.
        /// @param | color_tbl | table | RGBA byte color table.
        /// @return | integer | Path id.
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
        /// Clears one path by id or all paths when no id is provided.
        /// @param | id | integer | Optional path id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clearPath", |_, this, id: Option<u32>| {
            this.inner.clear_path(id);
            Ok(())
        });
        // -- getPathCount --
        /// Returns the number of paths. This method is available to Lua scripts.
        /// @return | integer | Path count.
        methods.add_method("getPathCount", |_, this, ()| Ok(this.inner.paths().len()));
        // -- setLayer --
        /// Sets active minimap layer. This method is available to Lua scripts.
        /// @param | layer | integer | Layer index.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setLayer", |_, this, layer: usize| {
            this.inner.set_layer(layer);
            Ok(())
        });
        // -- getLayer --
        /// Returns active minimap layer. This method is available to Lua scripts.
        /// @return | integer | Layer index.
        methods.add_method("getLayer", |_, this, ()| Ok(this.inner.get_layer()));
        // -- getLayerCount --
        /// Returns the number of minimap layers.
        /// @return | integer | Layer count.
        methods.add_method("getLayerCount", |_, this, ()| Ok(this.inner.layer_count()));
        // -- setLayerData --
        /// Sets raw cell data for a layer. This method is available to Lua scripts.
        /// @param | layer | integer | Layer index.
        /// @param | data_tbl | table | Array table of cell bytes.
        /// @return | nil | No value is returned.
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
        // -- getLayerData --
        /// Returns raw cell data for a layer. This method is available to Lua scripts.
        /// @param | layer | integer | Layer index.
        /// @return | table | Array table of cell bytes, or nil when missing.
        methods.add_method("getLayerData", |lua, this, layer: usize| {
            let Some(layer_data) = this.inner.layer_data(layer) else {
                return Ok(None::<LuaTable>);
            };
            let tbl = lua.create_table()?;
            for (index, cell) in layer_data.cells.iter().enumerate() {
                tbl.set(index + 1, *cell)?;
            }
            Ok(Some(tbl))
        });
        // -- setAntiAlias --
        /// Enables or disables minimap anti-aliasing.
        /// @param | enabled | boolean | Anti-alias flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setAntiAlias", |_, this, enabled: bool| {
            this.inner.set_anti_alias(enabled);
            Ok(())
        });
        // -- isAntiAlias --
        /// Returns whether anti-aliasing is enabled.
        /// @return | boolean | True when enabled.
        methods.add_method("isAntiAlias", |_, this, ()| Ok(this.inner.anti_alias()));
        // -- setClickable --
        /// Enables or disables minimap click handling.
        /// @param | enabled | boolean | Clickable flag.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setClickable", |_, this, enabled: bool| {
            this.inner.set_clickable(enabled);
            Ok(())
        });
        // -- isClickable --
        /// Returns whether minimap click handling is enabled.
        /// @return | boolean | True when clickable.
        methods.add_method("isClickable", |_, this, ()| Ok(this.inner.is_clickable()));
        // -- getHoverInfo --
        /// Returns hover text for a screen position when available.
        /// @param | sx | number | Lua argument for `sx`.
        /// @param | sy | number | Lua argument for `sy`.
        /// @param | mx | number | Lua argument for `mx`.
        /// @param | my | number | Lua argument for `my`.
        /// @return | string | Hover info text, or nil when unavailable.
        methods.add_method(
            "getHoverInfo",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this
                    .inner
                    .get_hover_info(sx, sy, mx, my)
                    .map(|s| s.to_string()))
            },
        );
        // -- screenToGrid --
        /// Converts a screen position to grid coordinates.
        /// @param | sx | number | Lua argument for `sx`.
        /// @param | sy | number | Lua argument for `sy`.
        /// @param | mx | number | Lua argument for `mx`.
        /// @param | my | number | Lua argument for `my`.
        /// @return | LuaValue | Conversion result from the minimap module.
        methods.add_method(
            "screenToGrid",
            |_, this, (sx, sy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.screen_to_grid(sx, sy, mx, my))
            },
        );
        // -- gridToScreen --
        /// Converts grid coordinates to screen coordinates.
        /// @param | gx | number | Lua argument for `gx`.
        /// @param | gy | number | Lua argument for `gy`.
        /// @param | mx | number | Lua argument for `mx`.
        /// @param | my | number | Lua argument for `my`.
        /// @return | LuaValue | Conversion result from the minimap module.
        methods.add_method(
            "gridToScreen",
            |_, this, (gx, gy, mx, my): (f32, f32, f32, f32)| {
                Ok(this.inner.grid_to_screen(gx, gy, mx, my))
            },
        );
        // -- update --
        /// Advances minimap animations and timers.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("update", |_, this, dt: f32| {
            this.inner.update(dt);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this minimap handle.
        /// @return | string | The string `LMinimap`.
        methods.add_method("type", |_, _, ()| Ok("LMinimap"));
        // -- typeOf --
        /// Returns whether this minimap handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LMinimap`, `Minimap`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMinimap" || name == "Minimap" || name == "Object")
        });
        // -- render --
        /// Enqueues minimap render commands at an optional screen position.
        /// @param | x | number | Optional screen x coordinate, defaulting to 0.
        /// @param | y | number | Optional screen y coordinate, defaulting to 0.
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let sx = x.unwrap_or(0.0);
            let sy = y.unwrap_or(0.0);
            let cmds = this.inner.build_render_commands(sx, sy);
            this.state.borrow_mut().render_commands.extend(cmds);
            Ok(())
        });
        // -- drawToImage --
        /// Draws the minimap into image data at a pixel size.
        /// @param | pixel_size | integer | Pixel size scale.
        /// @return | LuaValue | Image data returned by the minimap module.
        methods.add_method("drawToImage", |_, this, pixel_size: u32| {
            let img = this.inner.draw_to_image(pixel_size);
            Ok(img)
        });
    }
}
/// Registers the `lurek.minimap` module.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newMinimap --
    /// Creates a minimap with grid dimensions and optional display size.
    /// @param | grid_w | integer | Grid width in cells.
    /// @param | grid_h | integer | Grid height in cells.
    /// @param | display_w | integer | Optional display width in pixels, defaulting to 200.
    /// @param | display_h | integer | Optional display height in pixels, defaulting to 200.
    /// @return | LMinimap | New minimap handle.
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
    lurek.set("minimap", tbl)?;
    Ok(())
}
