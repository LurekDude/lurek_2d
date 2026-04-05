//! `luna.minimap` Lua API bindings.
//!
//! Auto-generated skeleton from `src/minimap/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaMinimap ────────────────────────────────────────────────────────────

pub struct LuaMinimap(/* TODO: add key + state fields */);


impl LuaMinimap {
    /// Returns the grid width in cells.
    ///
    ///
    /// @return integer
    pub fn grid_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the grid height in cells.
    ///
    ///
    /// @return integer
    pub fn grid_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of grid cells.
    ///
    ///
    /// @return integer
    pub fn grid_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the display width in pixels.
    ///
    ///
    /// @return integer
    pub fn display_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the display height in pixels.
    ///
    ///
    /// @return integer
    pub fn display_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the terrain type at a grid position.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return integer
    pub fn get_terrain(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the display color for a terrain type (grey `[0.5, 0.5, 0.5, 1.0]` if unset).
    ///
    ///
    /// @param terrain_type : integer
    pub fn get_terrain_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the hover tooltip string for a terrain type ID. Returns `None` if not set.
    ///
    /// @param type_id : integer
    /// @return Option<
    pub fn get_tile_description(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether fog of war is enabled.
    ///
    ///
    /// @return boolean
    pub fn fog_enabled(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the fog level at a grid position.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return FogLevel
    pub fn get_fog_level(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether an object type is visible.
    ///
    /// @param type_index : integer
    /// @return boolean
    pub fn is_object_type_visible(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of registered object types.
    ///
    ///
    /// @return integer
    pub fn object_type_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of tracked objects.
    ///
    ///
    /// @return integer
    pub fn object_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the display color for an owner/faction (grey `[0.8, 0.8, 0.8, 1.0]` if unset).
    ///
    ///
    /// @param owner : integer
    pub fn get_owner_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the current color mode.
    ///
    ///
    /// @return ColorMode
    pub fn color_mode(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the current zoom level.
    ///
    ///
    /// @return number
    pub fn zoom(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the center X coordinate.
    ///
    ///
    /// @return number
    pub fn center_x(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the center Y coordinate.
    ///
    ///
    /// @return number
    pub fn center_y(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the viewport rectangle, if set.
    ///
    ///
    /// @return Option<(f32
    pub fn viewport_rect(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the viewport rectangle is visible.
    ///
    ///
    /// @return boolean
    pub fn viewport_visible(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of active pings.
    ///
    ///
    /// @return integer
    pub fn ping_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Check if a marker with the given ID exists.
    ///
    /// @param id : integer
    /// @return boolean
    pub fn has_marker(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the description of a marker, if it exists.
    ///
    /// @param id : integer
    /// @return Option<
    pub fn get_marker_description(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of markers.
    ///
    ///
    /// @return integer
    pub fn marker_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether anti-aliasing is enabled.
    ///
    ///
    /// @return boolean
    pub fn anti_alias(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this minimap responds to click hit-testing.
    ///
    ///
    /// @return boolean
    pub fn is_clickable(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Convert screen coordinates to grid coordinates.
    ///
    ///
    /// @param sx : number
    /// @param sy : number
    /// @param minimap_x : number
    /// @param minimap_y : number
    pub fn screen_to_grid(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Convert grid coordinates to screen coordinates.
    ///
    ///
    /// @param gx : number
    /// @param gy : number
    /// @param minimap_x : number
    /// @param minimap_y : number
    pub fn grid_to_screen(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMinimap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("gridWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("gridHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("gridSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("displayWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("displayHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTerrain", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTerrainColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTileDescription", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("fogEnabled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFogLevel", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isObjectTypeVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("objectTypeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("objectCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOwnerColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("colorMode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("zoom", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("centerX", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("centerY", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("viewportRect", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("viewportVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("pingCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasMarker", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getMarkerDescription", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("markerCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("antiAlias", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isClickable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("screenToGrid", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("gridToScreen", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.minimap.* functions ──────────────────────────────────────────

/// Set the display size in pixels.
///
///
/// @param width : integer
/// @param height : integer
pub fn set_display_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the terrain type at a grid position (0-based internally).
///
///
/// @param x : integer
/// @param y : integer
/// @param terrain_type : integer
pub fn set_terrain(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bulk-set terrain types from a flat slice (row-major, length = gridW × gridH).
///
///
/// @param data : [u32]
pub fn set_terrain_data(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the display color for a terrain type.
///
///
/// @param terrain_type : integer
/// @param color : [f32; 4]
pub fn set_terrain_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set a hover tooltip string for a terrain type ID.
///
///
/// @param type_id : integer
/// @param desc : string
pub fn set_tile_description(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enable or disable fog of war.
///
///
/// @param enabled : boolean
pub fn set_fog_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the fog level at a grid position.
///
///
/// @param x : integer
/// @param y : integer
/// @param level : FogLevel
pub fn set_fog_level(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the fog overlay color (RGBA).
///
///
/// @param color : [f32; 4]
pub fn set_fog_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the entire fog grid from a flat byte array (0=hidden, 1=explored, 2=visible).
///
///
/// @param data : [u8]
pub fn set_fog_data(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Register a new object type and return its 0-based index.
///
/// @param name : string
/// @param color : [f32; 4]
/// @return integer
pub fn add_object_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set whether an object type is visible on the minimap.
///
///
/// @param type_index : integer
/// @param visible : boolean
pub fn set_object_type_visible(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set or update a tracked object on the minimap.
///
///
/// @param id : integer
/// @param x : number
/// @param y : number
/// @param type_index : integer
/// @param owner : integer
pub fn set_object(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a tracked object by ID. Returns `true` if the object was present.
///
/// @param id : integer
/// @return boolean
pub fn remove_object(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the display color for an owner/faction.
///
///
/// @param owner : integer
/// @param color : [f32; 4]
pub fn set_owner_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the color mode (`Terrain` or `Political`).
///
///
/// @param mode : ColorMode
pub fn set_color_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the zoom level (minimum 0.1).
///
///
/// @param zoom : number
pub fn set_zoom(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the center of the minimap view in grid coordinates.
///
///
/// @param x : number
/// @param y : number
pub fn set_center(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the viewport rectangle overlay (in grid coordinates).
///
///
/// @param x : number
/// @param y : number
/// @param w : number
/// @param h : number
pub fn set_viewport_rect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set whether the viewport rectangle is visible.
///
///
/// @param visible : boolean
pub fn set_viewport_visible(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the viewport rectangle color.
///
///
/// @param color : [f32; 4]
pub fn set_viewport_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add an animated ping at grid coordinates.
///
///
/// @param x : number
/// @param y : number
/// @param duration : number
/// @param color : [f32; 4]
pub fn add_ping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a persistent marker and return its auto-assigned ID.
///
/// @param x : number
/// @param y : number
/// @param description : string
/// @param color : [f32; 4]
/// @return integer
pub fn add_marker(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a marker by ID. Returns `true` if it existed.
///
/// @param id : integer
/// @return boolean
pub fn remove_marker(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set whether anti-aliasing is enabled.
///
///
/// @param enabled : boolean
pub fn set_anti_alias(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set whether this minimap responds to click hit-testing.
///
///
/// @param enabled : boolean
pub fn set_clickable(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Get hover tooltip text for the element under the given screen coordinates.
///
/// Returns the tile description of the terrain type at the hovered grid cell, or `None`
/// if the coordinates are outside the minimap or no description is set for that terrain type.
///
/// @param sx : number
/// @param sy : number
/// @param minimap_x : number
/// @param minimap_y : number
/// @return Option<
pub fn get_hover_info(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advance time-based effects: decrement ping timers and remove expired pings.
///
///
/// @param dt : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a raw `u8` value (0/1/2) into a `FogLevel`.
///
/// @param val : u8
/// @return Self
pub fn from_u8(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.minimap` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("setDisplaySize", lua.create_function(set_display_size)?)?;
    tbl.set("setTerrain", lua.create_function(set_terrain)?)?;
    tbl.set("setTerrainData", lua.create_function(set_terrain_data)?)?;
    tbl.set("setTerrainColor", lua.create_function(set_terrain_color)?)?;
    tbl.set("setTileDescription", lua.create_function(set_tile_description)?)?;
    tbl.set("setFogEnabled", lua.create_function(set_fog_enabled)?)?;
    tbl.set("setFogLevel", lua.create_function(set_fog_level)?)?;
    tbl.set("setFogColor", lua.create_function(set_fog_color)?)?;
    tbl.set("setFogData", lua.create_function(set_fog_data)?)?;
    tbl.set("addObjectType", lua.create_function(add_object_type)?)?;
    tbl.set("setObjectTypeVisible", lua.create_function(set_object_type_visible)?)?;
    tbl.set("setObject", lua.create_function(set_object)?)?;
    tbl.set("removeObject", lua.create_function(remove_object)?)?;
    tbl.set("setOwnerColor", lua.create_function(set_owner_color)?)?;
    tbl.set("setColorMode", lua.create_function(set_color_mode)?)?;
    tbl.set("setZoom", lua.create_function(set_zoom)?)?;
    tbl.set("setCenter", lua.create_function(set_center)?)?;
    tbl.set("setViewportRect", lua.create_function(set_viewport_rect)?)?;
    tbl.set("setViewportVisible", lua.create_function(set_viewport_visible)?)?;
    tbl.set("setViewportColor", lua.create_function(set_viewport_color)?)?;
    tbl.set("addPing", lua.create_function(add_ping)?)?;
    tbl.set("addMarker", lua.create_function(add_marker)?)?;
    tbl.set("removeMarker", lua.create_function(remove_marker)?)?;
    tbl.set("setAntiAlias", lua.create_function(set_anti_alias)?)?;
    tbl.set("setClickable", lua.create_function(set_clickable)?)?;
    tbl.set("getHoverInfo", lua.create_function(get_hover_info)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("fromU8", lua.create_function(from_u8)?)?;
    luna.set("minimap", tbl)?;
    Ok(())
}
