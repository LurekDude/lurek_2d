//! `luna.raycaster` Lua API bindings.
//!
//! Auto-generated skeleton from `src/raycaster/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaColumnBatch ────────────────────────────────────────────────────────────

pub struct LuaColumnBatch(/* TODO: add key + state fields */);


impl LuaColumnBatch {
    /// Reference to a single column by 0-based index.
    ///
    ///
    /// # Parameters
    /// - `col` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param col : integer
    /// @return Option<
    pub fn get_column(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Depth value at a 0-based column index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `col` — `integer` ...
    ///
    /// # Returns
    /// `number?`.
    ///
    /// @param col : integer
    /// @return number?
    pub fn get_depth_at(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Depth buffer as a flat vector (one entry per column).
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_depth_buffer(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Number of columns. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_column_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Screen width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_screen_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Screen height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn get_screen_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaColumnBatch {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getColumn", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDepthAt", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDepthBuffer", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getColumnCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getScreenWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getScreenHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDepthBuffer ────────────────────────────────────────────────────────────

pub struct LuaDepthBuffer(/* TODO: add key + state fields */);


impl LuaDepthBuffer {
    /// Gets the depth for a specific column. Returns `f32::MAX` for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `column` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param column : integer
    /// @return number
    pub fn get(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the given depth is closer than the stored depth at this column.
    ///
    ///
    /// # Parameters
    /// - `column` — `integer` ...
    /// - `depth` — `number` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param column : integer
    /// @param depth : number
    /// @return boolean
    pub fn is_visible(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the buffer width.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDepthBuffer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("get", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("width", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDoorManager ────────────────────────────────────────────────────────────

pub struct LuaDoorManager(/* TODO: add key + state fields */);


impl LuaDoorManager {
    /// Finds a door at grid position (x, y), if any.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return Option<
    pub fn get_door_at(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDoorManager {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getDoorAt", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaHeightMap ────────────────────────────────────────────────────────────

pub struct LuaHeightMap(/* TODO: add key + state fields */);


impl LuaHeightMap {
    /// Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn floor_at(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return number
    pub fn ceiling_at(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaHeightMap {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("floorAt", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("ceilingAt", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaRaycaster2D ────────────────────────────────────────────────────────────

pub struct LuaRaycaster2D(/* TODO: add key + state fields */);


impl LuaRaycaster2D {
    /// Gets the value of a cell at (x, y). Returns 0 for out-of-bounds.
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return integer
    pub fn get_cell(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the cell at (x, y) is blocked (value > 0).
    ///
    ///
    /// # Parameters
    /// - `x` — `integer` ...
    /// - `y` — `integer` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return boolean
    pub fn is_blocked(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the grid width.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the grid height.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Casts a single ray from (ox, oy) at the given angle using the DDA algorithm.
    ///
    ///
    /// # Parameters
    /// - `ox` — `number` ...
    /// - `oy` — `number` ...
    /// - `angle` — `number` ...
    /// - `max_dist` — `number` ...
    ///
    /// # Returns
    /// `RayHit?`.
    ///
    /// @param ox : number
    /// @param oy : number
    /// @param angle : number
    /// @param max_dist : number
    /// @return RayHit?
    pub fn cast_ray(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Checks line of sight between two points using DDA traversal.
    ///
    ///
    /// # Parameters
    /// - `x1` — `number` ...
    /// - `y1` — `number` ...
    /// - `x2` — `number` ...
    /// - `y2` — `number` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return boolean
    pub fn line_of_sight(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaRaycaster2D {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getCell", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isBlocked", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("width", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("height", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("castRay", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("lineOfSight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.raycaster.* functions ──────────────────────────────────────────

/// Set the data for a single 0-based column index.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `tex_u` — `number` ...
/// - `start` — `number` ...
/// - `end` — `number` ...
/// - `shade` — `number` ...
/// - `cell_val` — `integer` ...
///
/// @param col : integer
/// @param tex_u : number
/// @param start : number
/// @param end : number
/// @param shade : number
/// @param cell_val : integer
pub fn set_column(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bulk-update columns from raw ray data. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `rays` — `[f32]` ...
/// - `_fov` — `number` ...
/// - `max_shade_dist` — `number?` ...
///
/// @param rays : [f32]
/// @param _fov : number
/// @param max_shade_dist : number?
pub fn update_from_ray_data(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the floor color. Replaces the current floor color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_floor_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the ceiling color. Replaces the current ceiling color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `color` — `Color` ...
///
/// @param color : Color
pub fn set_ceiling_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the value of a cell at (x, y). 0-based coordinates.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `value` — `integer` ...
///
/// @param x : integer
/// @param y : integer
/// @param value : integer
pub fn set_cell(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bulk-sets all cells from a flat vector. Length must match width*height.
///
///
/// # Parameters
/// - `data` — `table` ...
///
/// @param data : table
pub fn set_cells(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Casts multiple rays spread across a field of view.
///
///
/// # Parameters
/// - `ox` — `number` ...
/// - `oy` — `number` ...
/// - `angle` — `number` ...
/// - `fov` — `number` ...
/// - `count` — `integer` ...
/// - `max_dist` — `number` ...
///
/// # Returns
/// `table`.
///
/// @param ox : number
/// @param oy : number
/// @param angle : number
/// @param fov : number
/// @param count : integer
/// @param max_dist : number
/// @return table
pub fn cast_rays(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Casts multiple rays and returns a flat `Vec<f32>` with 5 values per ray.
///
///
/// # Parameters
/// - `ox` — `number` ...
/// - `oy` — `number` ...
/// - `angle` — `number` ...
/// - `fov` — `number` ...
/// - `count` — `integer` ...
/// - `max_dist` — `number` ...
///
/// # Returns
/// `table`.
///
/// @param ox : number
/// @param oy : number
/// @param angle : number
/// @param fov : number
/// @param count : integer
/// @param max_dist : number
/// @return table
pub fn cast_rays_flat(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Projects a world-space sprite onto screen space.
///
///
/// # Parameters
/// - `sx` — `number` ...
/// - `sy` — `number` ...
/// - `px` — `number` ...
/// - `py` — `number` ...
/// - `pa` — `number` ...
/// - `fov` — `number` ...
/// - `screen_w` — `number` ...
///
/// # Returns
/// `SpriteProjection`.
///
/// @param sx : number
/// @param sy : number
/// @param px : number
/// @param py : number
/// @param pa : number
/// @param fov : number
/// @param screen_w : number
/// @return SpriteProjection
pub fn project_sprite(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the depth for a specific column.
///
///
/// # Parameters
/// - `column` — `integer` ...
/// - `depth` — `number` ...
///
/// @param column : integer
/// @param depth : number
pub fn set(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a door at (x, y) with the given direction and speed.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `direction` — `DoorDirection` ...
/// - `speed` — `number` ...
///
/// # Returns
/// `integer`.
///
/// @param x : integer
/// @param y : integer
/// @param direction : DoorDirection
/// @param speed : number
/// @return integer
pub fn add_door(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Begins opening a door by index.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// @param index : integer
pub fn open_door(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Begins closing a door by index.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// @param index : integer
pub fn close_door(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advances all door animations by `dt` seconds.
///
/// Doors in the `Opening` state increase `open_amount` and transition to
/// `Open` when fully open. Doors in the `Closing` state decrease
/// `open_amount` and transition to `Closed` when fully closed.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// @param dt : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the floor height at (x, y).
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `h` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param h : number
pub fn set_floor(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the ceiling height at (x, y).
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `h` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param h : number
pub fn set_ceiling(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the floor height for a rectangular region.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `w` — `integer` ...
/// - `h` — `integer` ...
/// - `height` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param w : integer
/// @param h : integer
/// @param height : number
pub fn set_floor_rect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the ceiling height for a rectangular region.
///
///
/// # Parameters
/// - `x` — `integer` ...
/// - `y` — `integer` ...
/// - `w` — `integer` ...
/// - `h` — `integer` ...
/// - `height` — `number` ...
///
/// @param x : integer
/// @param y : integer
/// @param w : integer
/// @param h : integer
/// @param height : number
pub fn set_ceiling_rect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes ambient + point-light illumination at a world position.
///
/// Each light contributes based on inverse-distance falloff within its radius.
/// The result is the sum of ambient light and all point-light contributions,
/// clamped per-channel to [0, 1].
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `ambient` — `number` ...
/// - `lights` — `[PointLight]` ...
///
/// @param x : number
/// @param y : number
/// @param ambient : number
/// @param lights : [PointLight]
pub fn compute_lighting(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Applies lighting to a distance-shaded base brightness.
///
/// Multiplies the base shade value by each channel of the light color,
/// producing a final lit RGB value.
///
///
/// # Parameters
/// - `base_shade` — `number` ...
/// - `light_color` — `[f32; 3]` ...
///
/// @param base_shade : number
/// @param light_color : [f32; 3]
pub fn apply_lit_shade(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Extracts a top-down minimap from a Raycaster2D grid.
///
/// Returns flat RGBA pixel data (4 bytes per pixel, row-major) centered on
/// the player position, with a configurable view radius and cell size.
///
///
/// # Parameters
/// - `raycaster` — `Raycaster2D` ...
/// - `player_x` — `number` ...
/// - `player_y` — `number` ...
/// - `player_angle` — `number` ...
/// - `view_radius` — `integer` ...
/// - `cell_size` — `integer` ...
/// - `wall_color` — `[u8; 4]` ...
/// - `floor_color` — `[u8; 4]` ...
/// - `player_color` — `[u8; 4]` ...
///
/// # Returns
/// `Returns`.
///
/// @param raycaster : Raycaster2D
/// @param player_x : number
/// @param player_y : number
/// @param player_angle : number
/// @param view_radius : integer
/// @param cell_size : integer
/// @param wall_color : [u8; 4]
/// @param floor_color : [u8; 4]
/// @param player_color : [u8; 4]
/// @return Returns
pub fn extract_minimap(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Renders a simple directional arrow for the player on the minimap.
///
/// Draws a small triangle pointing in the player's facing direction,
/// centered at `(center_x, center_y)` in the pixel buffer.
///
///
/// # Parameters
/// - `pixels` — `mut [u8]` ...
/// - `img_width` — `integer` ...
/// - `center_x` — `integer` ...
/// - `center_y` — `integer` ...
/// - `angle` — `number` ...
/// - `size` — `integer` ...
/// - `color` — `[u8; 4]` ...
///
/// @param pixels : mut [u8]
/// @param img_width : integer
/// @param center_x : integer
/// @param center_y : integer
/// @param angle : number
/// @param size : integer
/// @param color : [u8; 4]
pub fn draw_player_arrow(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Projects a wall column distance to screen-space drawing parameters.
///
///
/// # Parameters
/// - `distance` — `number` ...
/// - `fov` — `number` ...
/// - `screen_height` — `number` ...
///
/// # Returns
/// `Returns`.
///
/// @param distance : number
/// @param fov : number
/// @param screen_height : number
/// @return Returns
pub fn project_column(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Distance-based shading. Returns brightness in [0, 1].
///
///
/// # Parameters
/// - `distance` — `number` ...
/// - `max_distance` — `number` ...
///
/// # Returns
/// `number`.
///
/// @param distance : number
/// @param max_distance : number
/// @return number
pub fn distance_shade(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
///
///
/// # Parameters
/// - `ox` — `number` ...
/// - `oy` — `number` ...
/// - `dx` — `number` ...
/// - `dy` — `number` ...
/// - `max_dist` — `number` ...
/// - `segments` — `[Segment]` ...
///
/// # Returns
/// `Option<(f32`.
///
/// @param ox : number
/// @param oy : number
/// @param dx : number
/// @param dy : number
/// @param max_dist : number
/// @param segments : [Segment]
/// @return Option<(f32
pub fn cast_ray_2d(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes a visibility polygon by casting rays at segment endpoints.
///
///
/// # Parameters
/// - `ox` — `number` ...
/// - `oy` — `number` ...
/// - `segments` — `[Segment]` ...
/// - `radius` — `number` ...
///
/// # Returns
/// `table`.
///
/// @param ox : number
/// @param oy : number
/// @param segments : [Segment]
/// @param radius : number
/// @return table
pub fn field_of_view(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.raycaster` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("setColumn", lua.create_function(set_column)?)?;
    tbl.set("updateFromRayData", lua.create_function(update_from_ray_data)?)?;
    tbl.set("setFloorColor", lua.create_function(set_floor_color)?)?;
    tbl.set("setCeilingColor", lua.create_function(set_ceiling_color)?)?;
    tbl.set("setCell", lua.create_function(set_cell)?)?;
    tbl.set("setCells", lua.create_function(set_cells)?)?;
    tbl.set("castRays", lua.create_function(cast_rays)?)?;
    tbl.set("castRaysFlat", lua.create_function(cast_rays_flat)?)?;
    tbl.set("projectSprite", lua.create_function(project_sprite)?)?;
    tbl.set("set", lua.create_function(set)?)?;
    tbl.set("addDoor", lua.create_function(add_door)?)?;
    tbl.set("openDoor", lua.create_function(open_door)?)?;
    tbl.set("closeDoor", lua.create_function(close_door)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("setFloor", lua.create_function(set_floor)?)?;
    tbl.set("setCeiling", lua.create_function(set_ceiling)?)?;
    tbl.set("setFloorRect", lua.create_function(set_floor_rect)?)?;
    tbl.set("setCeilingRect", lua.create_function(set_ceiling_rect)?)?;
    tbl.set("computeLighting", lua.create_function(compute_lighting)?)?;
    tbl.set("applyLitShade", lua.create_function(apply_lit_shade)?)?;
    tbl.set("extractMinimap", lua.create_function(extract_minimap)?)?;
    tbl.set("drawPlayerArrow", lua.create_function(draw_player_arrow)?)?;
    tbl.set("projectColumn", lua.create_function(project_column)?)?;
    tbl.set("distanceShade", lua.create_function(distance_shade)?)?;
    tbl.set("castRay2d", lua.create_function(cast_ray_2d)?)?;
    tbl.set("fieldOfView", lua.create_function(field_of_view)?)?;
    luna.set("raycaster", tbl)?;
    Ok(())
}
