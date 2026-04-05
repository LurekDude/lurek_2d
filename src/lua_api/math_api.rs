//! `luna.math` Lua API bindings.
//!
//! Auto-generated skeleton from `src/math/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaBezierCurve ────────────────────────────────────────────────────────────

pub struct LuaBezierCurve(/* TODO: add key + state fields */);


impl LuaBezierCurve {
    /// Evaluate the curve at parameter `t` using De Casteljau's algorithm.
    ///
    ///
    /// # Parameters
    /// - `t` — `curve` ...
    ///
    /// # Returns
    /// `The`.
    ///
    /// @param t : curve
    /// @return The
    pub fn evaluate(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Render the curve as a polyline with the given number of segments.
    ///
    ///
    /// # Parameters
    /// - `segments` — `number` ...
    ///
    /// # Returns
    /// `segments`.
    ///
    /// @param segments : number
    /// @return segments
    pub fn render(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Render a portion of the curve between `t_start` and `t_end`.
    ///
    ///
    /// # Parameters
    /// - `t_start` — `start` ...
    /// - `t_end` — `end` ...
    /// - `segments` — `number` ...
    ///
    /// # Returns
    /// `segments`.
    ///
    /// @param t_start : start
    /// @param t_end : end
    /// @param segments : number
    /// @return segments
    pub fn render_segment(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get a control point by 0-based index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `index` — `0-based` ...
    ///
    /// # Returns
    /// `Some(Vec2)`.
    ///
    /// @param index : 0-based
    /// @return Some(Vec2)
    pub fn get_control_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of control points. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `Number`.
    ///
    /// @return Number
    pub fn get_control_point_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaBezierCurve {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("evaluate", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("render", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("renderSegment", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getControlPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getControlPointCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaColor ────────────────────────────────────────────────────────────

pub struct LuaColor(/* TODO: add key + state fields */);


impl LuaColor {
    /// Converts the color to a packed `u32` RGB value suitable for packed pixel buffers.
    ///
    /// Alpha is discarded. Bit layout: `0x00RRGGBB`.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn to_rgb_u32(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaColor {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("toRgbU32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMat3 ────────────────────────────────────────────────────────────

pub struct LuaMat3(/* TODO: add key + state fields */);


impl LuaMat3 {
    /// Compute the inverse of this 3×3 matrix. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `The`.
    ///
    /// @return The
    pub fn inverse(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Applies the matrix transform to a 2D point using homogeneous coordinates.
    ///
    ///
    /// # Parameters
    /// - `p` — `Input` ...
    ///
    /// # Returns
    /// `Vec2`.
    ///
    /// @param p : Input
    /// @return Vec2
    pub fn transform_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMat3 {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("inverse", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("transformPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaRandomGenerator ────────────────────────────────────────────────────────────

pub struct LuaRandomGenerator(/* TODO: add key + state fields */);


impl LuaRandomGenerator {
    /// Get the seed that was used to initialise (or last reset) this generator.
    ///
    ///
    /// # Returns
    /// `The`.
    ///
    /// @return The
    pub fn get_seed(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Serialise the generator state as a string for later restoration.
    ///
    ///
    /// # Returns
    /// `An`.
    ///
    /// @return An
    pub fn get_state(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaRandomGenerator {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSeed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getState", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaRect ────────────────────────────────────────────────────────────

pub struct LuaRect(/* TODO: add key + state fields */);


impl LuaRect {
    /// Returns the center point of the rectangle.
    ///
    ///
    /// # Returns
    /// `Vec2`.
    ///
    /// @return Vec2
    pub fn center(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the area of the rectangle. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn area(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the given point lies within or on the boundary of the rectangle.
    ///
    ///
    /// # Parameters
    /// - `point_x` — `X` ...
    /// - `point_y` — `Y` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param point_x : X
    /// @param point_y : Y
    /// @return boolean
    pub fn contains(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if this rectangle overlaps with `other`.
    ///
    /// Touch (shared edge) is not considered an intersection; the overlap must be positive.
    ///
    ///
    /// # Parameters
    /// - `other` — `The` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param other : The
    /// @return boolean
    pub fn intersects(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaRect {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("center", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("area", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("contains", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("intersects", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSpatialHash ────────────────────────────────────────────────────────────

pub struct LuaSpatialHash(/* TODO: add key + state fields */);


impl LuaSpatialHash {
    /// Returns the cell size. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn cell_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of items in the hash.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn item_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the IDs of all items whose AABBs overlap the query rectangle.
    ///
    ///
    /// # Parameters
    /// - `x` — `number` ...
    /// - `y` — `number` ...
    /// - `w` — `number` ...
    /// - `h` — `number` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param x : number
    /// @param y : number
    /// @param w : number
    /// @param h : number
    /// @return table
    pub fn query_rect(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the IDs of all items whose AABBs overlap the query circle.
    ///
    ///
    /// # Parameters
    /// - `cx` — `number` ...
    /// - `cy` — `number` ...
    /// - `radius` — `number` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param cx : number
    /// @param cy : number
    /// @param radius : number
    /// @return table
    pub fn query_circle(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the IDs of all items whose AABBs are intersected by a line
    ///
    ///
    /// # Parameters
    /// - `x1` — `number` ...
    /// - `y1` — `number` ...
    /// - `x2` — `number` ...
    /// - `y2` — `number` ...
    ///
    /// # Returns
    /// `table`.
    ///
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return table
    pub fn query_segment(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSpatialHash {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("cellSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("itemCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryRect", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("queryCircle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("querySegment", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTransform ────────────────────────────────────────────────────────────

pub struct LuaTransform(/* TODO: add key + state fields */);


impl LuaTransform {
    /// Transform a point from local space to world space.
    ///
    ///
    /// # Parameters
    /// - `x` — `local` ...
    /// - `y` — `local` ...
    ///
    /// @param x : local
    /// @param y : local
    pub fn transform_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Transform a point from world space back to local space.
    ///
    ///
    /// # Parameters
    /// - `x` — `world` ...
    /// - `y` — `world` ...
    ///
    /// @param x : world
    /// @param y : world
    pub fn inverse_transform_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTransform {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("transformPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("inverseTransformPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTween ────────────────────────────────────────────────────────────

pub struct LuaTween(/* TODO: add key + state fields */);


impl LuaTween {
    /// Returns the interpolated value at the given index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param index : integer
    /// @return number
    pub fn get_value(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns all interpolated values. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_all_values(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the tween has completed.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_complete(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of values in this tween.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn value_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the duration. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn duration(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current clock time. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `number`.
    ///
    /// @return number
    pub fn clock(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTween {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getValue", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAllValues", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isComplete", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("valueCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("duration", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("clock", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.math.* functions ──────────────────────────────────────────

/// Set a control point by 0-based index. Replaces the current control point value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `index` — `0-based` ...
/// - `point` — `new` ...
///
/// # Returns
/// `true`.
///
/// @param index : 0-based
/// @param point : new
/// @return true
pub fn set_control_point(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Insert a control point at a given index, or append if `index` is `None`.
///
///
/// # Parameters
/// - `point` — `position` ...
/// - `index` — `0-based` ...
///
/// @param point : position
/// @param index : 0-based
pub fn insert_control_point(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a control point by 0-based index.
///
///
/// # Parameters
/// - `index` — `0-based` ...
///
/// # Returns
/// `false`.
///
/// @param index : 0-based
/// @return false
pub fn remove_control_point(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Translate all control points by `(dx, dy)`.
///
///
/// # Parameters
/// - `dx` — `horizontal` ...
/// - `dy` — `vertical` ...
///
/// @param dx : horizontal
/// @param dy : vertical
pub fn translate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Rotate all control points around a pivot `(ox, oy)` by `angle` radians.
///
///
/// # Parameters
/// - `angle` — `rotation` ...
/// - `ox` — `pivot` ...
/// - `oy` — `pivot` ...
///
/// @param angle : rotation
/// @param ox : pivot
/// @param oy : pivot
pub fn rotate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Scale all control points around a pivot `(ox, oy)` by factor `s`.
///
///
/// # Parameters
/// - `s` — `uniform` ...
/// - `ox` — `pivot` ...
/// - `oy` — `pivot` ...
///
/// @param s : uniform
/// @param ox : pivot
/// @param oy : pivot
pub fn scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a color from `u8` RGBA components in `[0, 255]`, normalizing to `[0.0, 1.0]`.
///
///
/// # Parameters
/// - `r` — `Red` ...
/// - `g` — `Green` ...
/// - `b` — `Blue` ...
/// - `a` — `Alpha` ...
///
/// @param r : Red
/// @param g : Green
/// @param b : Blue
/// @param a : Alpha
pub fn from_u8(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a single sRGB gamma-space color component to linear space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB transfer function.
///
///
/// # Parameters
/// - `c` — `gamma-encoded` ...
///
/// # Returns
/// `Linear`.
///
/// @param c : gamma-encoded
/// @return Linear
pub fn gamma_to_linear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Convert a single linear-space color component to sRGB gamma space.
///
/// Input and output in `[0.0, 1.0]`. Uses the standard IEC 61966-2-1 sRGB inverse transfer function.
///
///
/// # Parameters
/// - `c` — `linear-light` ...
///
/// # Returns
/// `Gamma`.
///
/// @param c : linear-light
/// @return Gamma
pub fn linear_to_gamma(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Linear interpolation — no easing. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn linear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quadratic ease-in — starts slow, accelerates.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_quad(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quadratic ease-out — starts fast, decelerates.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_quad(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quadratic ease-in-out — slow start and end, fast middle.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_out_quad(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cubic ease-in — starts slow, accelerates sharply.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_cubic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cubic ease-out — starts fast, decelerates sharply.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_cubic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Cubic ease-in-out — smooth S-curve. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_out_cubic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quartic ease-in — very slow start. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_quart(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quartic ease-out — very slow end. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_quart(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Quartic ease-in-out — pronounced S-curve.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_out_quart(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sinusoidal ease-in — gentle sine-based acceleration.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_sine(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sinusoidal ease-out — gentle sine-based deceleration.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_sine(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sinusoidal ease-in-out — gentle S-curve.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_out_sine(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Exponential ease-in — very slow start, rapid acceleration.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_expo(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Exponential ease-out — rapid start, very slow end.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_expo(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Exponential ease-in-out — sharp S-curve with exponential tails.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_out_expo(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Elastic ease-in — spring-like overshoot at the start.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_elastic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Elastic ease-out — spring-like overshoot at the end.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_elastic(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bounce ease-out — simulates a bouncing ball landing.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_bounce(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bounce ease-in — simulates a bouncing ball launching.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_bounce(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Back ease-in — pulls back before accelerating past the start.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_in_back(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Back ease-out — overshoots the target then settles back.
///
///
/// # Parameters
/// - `t` — `normalised` ...
///
/// # Returns
/// `Eased`.
///
/// @param t : normalised
/// @return Eased
pub fn ease_out_back(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Looks up an easing function by name and applies it to progress value `t`.
///
/// Supported names (case-insensitive): `"linear"`, `"inQuad"`, `"outQuad"`,
/// `"inOutQuad"`, `"inCubic"`, `"outCubic"`, `"inOutCubic"`, `"inQuart"`,
/// `"outQuart"`, `"inOutQuart"`, `"inSine"`, `"outSine"`, `"inOutSine"`,
/// `"inExpo"`, `"outExpo"`, `"inOutExpo"`, `"inElastic"`, `"outElastic"`,
/// `"outBounce"`, `"inBounce"`, `"inBack"`, `"outBack"`.
///
///
/// # Parameters
/// - `name` — `easing` ...
/// - `t` — `normalised` ...
///
/// # Returns
/// `Some(f32)`.
///
/// @param name : easing
/// @param t : normalised
/// @return Some(f32)
pub fn apply(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the angle in radians from (x1, y1) to (x2, y2).
///
///
/// # Parameters
/// - `x1` — `number` ...
/// - `y1` — `number` ...
/// - `x2` — `number` ...
/// - `y2` — `number` ...
///
/// # Returns
/// `number`.
///
/// @param x1 : number
/// @param y1 : number
/// @param x2 : number
/// @param y2 : number
/// @return number
pub fn angle_between(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns true if the point (px, py) is inside the circle centered at (cx, cy) with radius r.
///
///
/// # Parameters
/// - `cx` — `number` ...
/// - `cy` — `number` ...
/// - `r` — `number` ...
/// - `px` — `number` ...
/// - `py` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param cx : number
/// @param cy : number
/// @param r : number
/// @param px : number
/// @param py : number
/// @return boolean
pub fn circle_contains_point(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns true if two circles overlap. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `x1` — `number` ...
/// - `y1` — `number` ...
/// - `r1` — `number` ...
/// - `x2` — `number` ...
/// - `y2` — `number` ...
/// - `r2` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param x1 : number
/// @param y1 : number
/// @param r1 : number
/// @param x2 : number
/// @param y2 : number
/// @param r2 : number
/// @return boolean
pub fn circle_intersects_circle(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Line-circle intersection. Returns (intersects, hit1, hit2).
///
///
/// # Parameters
/// - `cx` — `number` ...
/// - `cy` — `number` ...
/// - `r` — `number` ...
/// - `lx1` — `number` ...
/// - `ly1` — `number` ...
/// - `lx2` — `number` ...
/// - `ly2` — `number` ...
///
/// # Returns
/// `Points`.
///
/// @param cx : number
/// @param cy : number
/// @param r : number
/// @param lx1 : number
/// @param ly1 : number
/// @param lx2 : number
/// @param ly2 : number
/// @return Points
pub fn circle_intersects_line(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Segment-circle intersection. Same as line-circle but clamped to the segment.
///
///
/// # Parameters
/// - `cx` — `number` ...
/// - `cy` — `number` ...
/// - `r` — `number` ...
/// - `sx1` — `number` ...
/// - `sy1` — `number` ...
/// - `sx2` — `number` ...
/// - `sy2` — `number` ...
///
/// @param cx : number
/// @param cy : number
/// @param r : number
/// @param sx1 : number
/// @param sy1 : number
/// @param sx2 : number
/// @param sy2 : number
pub fn circle_intersects_segment(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes the signed area of a polygon using the Shoelace formula.
///
///
/// # Parameters
/// - `vertices` — `[f32]` ...
///
/// # Returns
/// `number`.
///
/// @param vertices : [f32]
/// @return number
pub fn polygon_area(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes the centroid of a polygon. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `vertices` — `[f32]` ...
///
/// # Returns
/// `vertices`.
///
/// @param vertices : [f32]
/// @return vertices
pub fn polygon_centroid(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Tests if two line segments intersect. Returns (intersects, intersection_point).
///
///
/// # Parameters
/// - `x1` — `number` ...
/// - `y1` — `number` ...
/// - `x2` — `number` ...
/// - `y2` — `number` ...
/// - `x3` — `number` ...
/// - `y3` — `number` ...
/// - `x4` — `number` ...
/// - `y4` — `number` ...
///
/// @param x1 : number
/// @param y1 : number
/// @param x2 : number
/// @param y2 : number
/// @param x3 : number
/// @param y3 : number
/// @param x4 : number
/// @param y4 : number
pub fn segment_intersects_segment(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the closest point on a line segment to a given point.
///
///
/// # Parameters
/// - `px` — `number` ...
/// - `py` — `number` ...
/// - `x1` — `number` ...
/// - `y1` — `number` ...
/// - `x2` — `number` ...
/// - `y2` — `number` ...
///
/// @param px : number
/// @param py : number
/// @param x1 : number
/// @param y1 : number
/// @param x2 : number
/// @param y2 : number
pub fn closest_point_on_segment(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Tests if a point is inside a polygon using the ray casting algorithm.
///
///
/// # Parameters
/// - `vertices` — `[f32]` ...
/// - `px` — `number` ...
/// - `py` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param vertices : [f32]
/// @param px : number
/// @param py : number
/// @return boolean
pub fn point_in_polygon(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Infinite line intersection. Returns the intersection point if lines are not parallel.
///
///
/// # Parameters
/// - `x1` — `number` ...
/// - `y1` — `number` ...
/// - `x2` — `number` ...
/// - `y2` — `number` ...
/// - `x3` — `number` ...
/// - `y3` — `number` ...
/// - `x4` — `number` ...
/// - `y4` — `number` ...
///
/// # Returns
/// `Option<(f32`.
///
/// @param x1 : number
/// @param y1 : number
/// @param x2 : number
/// @param y2 : number
/// @param x3 : number
/// @param y3 : number
/// @param x4 : number
/// @param y4 : number
/// @return Option<(f32
pub fn line_intersect(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bresenham line rasterization from (x1, y1) to (x2, y2).
///
///
/// # Parameters
/// - `x1` — `integer` ...
/// - `y1` — `integer` ...
/// - `x2` — `integer` ...
/// - `y2` — `integer` ...
///
/// # Returns
/// `Vec<(i32`.
///
/// @param x1 : integer
/// @param y1 : integer
/// @param x2 : integer
/// @param y2 : integer
/// @return Vec<(i32
pub fn bresenham(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes the convex hull of a set of 2D points using Andrew's monotone chain algorithm.
///
///
/// # Parameters
/// - `points` — `[f32]` ...
///
/// # Returns
/// `table`.
///
/// @param points : [f32]
/// @return table
pub fn convex_hull(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Delaunay triangulation using the Bowyer-Watson algorithm.
///
///
/// # Parameters
/// - `points` — `[(f64, f64)]` ...
///
/// # Returns
/// `Vec<`.
///
/// @param points : [(f64, f64)]
/// @return Vec<
pub fn delaunay_triangulate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the 3×3 identity matrix. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Returns
/// `Mat3`.
///
/// @return Mat3
pub fn identity(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Creates a `Mat3` from a flat 9-element array in row-major order.
///
///
/// # Parameters
/// - `data` — `[f32; 9]` ...
///
/// # Returns
/// `Self`.
///
/// @param data : [f32; 9]
/// @return Self
pub fn from_row_major(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a translation matrix that moves points by `(t.x, t.y)`.
///
///
/// # Parameters
/// - `t` — `Translation` ...
///
/// # Returns
/// `Mat3`.
///
/// @param t : Translation
/// @return Mat3
pub fn from_translation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a rotation matrix for a counter-clockwise rotation of `angle` radians.
///
///
/// # Parameters
/// - `angle` — `Rotation` ...
///
/// # Returns
/// `Mat3`.
///
/// @param angle : Rotation
/// @return Mat3
pub fn from_rotation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a shear (skew) matrix. Returns a fully initialised instance with all fields set to their initial values.
///
///
/// # Parameters
/// - `kx` — `Shear` ...
/// - `ky` — `Shear` ...
///
/// # Returns
/// `Mat3`.
///
/// @param kx : Shear
/// @param ky : Shear
/// @return Mat3
pub fn from_shear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a non-uniform scale matrix with the given per-axis factors.
///
///
/// # Parameters
/// - `scale` — `Vec2` ...
///
/// # Returns
/// `Mat3`.
///
/// @param scale : Vec2
/// @return Mat3
pub fn from_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Triangulate a simple polygon using the ear-clipping algorithm.
///
///
/// # Parameters
/// - `polygon` — `slice` ...
///
/// # Returns
/// `Ok(triangles)`.
///
/// @param polygon : slice
/// @return Ok(triangles)
pub fn triangulate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Check if a polygon is convex. This accessor incurs no allocation; call it freely in hot paths.
///
/// Uses cross-product sign consistency at each vertex to determine convexity.
///
///
/// # Parameters
/// - `polygon` — `slice` ...
///
/// # Returns
/// `true`.
///
/// @param polygon : slice
/// @return true
pub fn is_convex(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create with a specific seed for deterministic sequences.
///
///
/// # Parameters
/// - `seed` — `64-bit` ...
///
/// @param seed : 64-bit
pub fn with_seed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sample a uniform random integer in `[min, max]` (inclusive).
///
///
/// # Parameters
/// - `min` — `lower` ...
/// - `max` — `upper` ...
///
/// @param min : lower
/// @param max : upper
pub fn random_int(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sample a uniform random float in `[min, max)`.
///
///
/// # Parameters
/// - `min` — `lower` ...
/// - `max` — `upper` ...
///
/// @param min : lower
/// @param max : upper
pub fn random_float(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Random number from normal (Gaussian) distribution using Box-Muller transform.
///
///
/// # Parameters
/// - `stddev` — `standard` ...
/// - `mean` — `mean` ...
///
/// @param stddev : standard
/// @param mean : mean
pub fn random_normal(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the seed, fully resetting the generator state.
///
///
/// # Parameters
/// - `seed` — `new` ...
///
/// @param seed : new
pub fn set_seed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Restore the generator state from a previously serialised string.
///
///
/// # Parameters
/// - `state` — `string` ...
///
/// # Returns
/// `Ok(())`.
///
/// @param state : string
/// @return Ok(())
pub fn set_state(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Inserts an item with the given AABB. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `string` ...
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `w` — `number` ...
/// - `h` — `number` ...
///
/// @param id : string
/// @param x : number
/// @param y : number
/// @param w : number
/// @param h : number
pub fn insert(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes an item by its ID. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `str` ...
///
/// @param id : str
pub fn remove(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates an existing item's AABB. Equivalent to remove + insert.
///
///
/// # Parameters
/// - `id` — `string` ...
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `w` — `number` ...
/// - `h` — `number` ...
///
/// @param id : string
/// @param x : number
/// @param y : number
/// @param w : number
/// @param h : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create from full transformation parameters (standard parameter order).
///
/// Equivalent to: `translate(x, y) → rotate(angle) → scale(sx, sy) → shear(kx, ky) → translate(-ox, -oy)`
///
///
/// # Parameters
/// - `angle` — `rotation` ...
///
/// @param angle : rotation
pub fn from_components(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Apply translation to the transform. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `dx` — `horizontal` ...
/// - `dy` — `vertical` ...
///
/// @param dx : horizontal
/// @param dy : vertical
/// Apply a rotation to the transform. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `angle` — `rotation` ...
///
/// @param angle : rotation
/// Apply non-uniform scaling to the transform.
///
///
/// # Parameters
/// - `sx` — `horizontal` ...
/// - `sy` — `vertical` ...
///
/// @param sx : horizontal
/// @param sy : vertical
/// Apply shear to the transform (standard convention).
///
///
/// # Parameters
/// - `kx` — `horizontal` ...
/// - `ky` — `vertical` ...
///
/// @param kx : horizontal
/// @param ky : vertical
pub fn shear(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Replace the current state with full transformation parameters.
///
///
/// # Parameters
/// - `angle` — `rotation` ...
///
/// @param angle : rotation
pub fn set_transformation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a value to interpolate. Returns the 0-based index.
///
///
/// # Parameters
/// - `start` — `number` ...
/// - `target` — `number` ...
///
/// # Returns
/// `integer`.
///
/// @param start : number
/// @param target : number
/// @return integer
pub fn add_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advances the clock by `dt` seconds. Returns `true` when the tween is complete.
///
///
/// # Parameters
/// - `dt` — `number` ...
///
/// # Returns
/// `boolean`.
///
/// @param dt : number
/// @return boolean
/// Sets the clock to a specific time, clamped to [0, duration].
///
///
/// # Parameters
/// - `t` — `number` ...
///
/// @param t : number
pub fn set_time(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the zero vector `(0.0, 0.0)`. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Equivalent to `Vec2::ZERO`; provided for ergonomics.
///
///
/// # Returns
/// `Vec2`.
///
/// @return Vec2
pub fn zero(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Creates a vector with both components set to `v`.
///
///
/// # Parameters
/// - `v` — `Value` ...
///
/// # Returns
/// `Vec2`.
///
/// @param v : Value
/// @return Vec2
pub fn splat(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the dot product of this vector and `other`.
///
///
/// # Parameters
/// - `other` — `The` ...
///
/// # Returns
/// `number`.
///
/// @param other : The
/// @return number
pub fn dot(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the Euclidean length (magnitude) of the vector.
///
///
/// # Returns
/// `number`.
///
/// @return number
pub fn length(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns the squared Euclidean length of the vector.
///
/// Cheaper than `length` when only comparing magnitudes.
///
///
/// # Returns
/// `number`.
///
/// @return number
pub fn length_squared(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns a unit vector in the same direction, or the original vector if its length is zero.
///
///
/// # Returns
/// `Vec2`.
///
/// @return Vec2
pub fn normalize(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Returns the Euclidean distance between this point and `other`.
///
///
/// # Parameters
/// - `other` — `The` ...
///
/// # Returns
/// `number`.
///
/// @param other : The
/// @return number
pub fn distance(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Linearly interpolates between `self` and `other` by factor `t`.
///
/// `t = 0.0` returns `self`; `t = 1.0` returns `other`; values outside `[0, 1]` extrapolate.
///
///
/// # Parameters
/// - `other` — `Target` ...
/// - `t` — `Interpolation` ...
///
/// # Returns
/// `Vec2`.
///
/// @param other : Target
/// @param t : Interpolation
/// @return Vec2
pub fn lerp(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the angle of the vector in radians, measured from the positive X axis.
///
///
/// # Returns
/// `number`.
///
/// @return number
pub fn angle(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.math` API table.
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
    tbl.set("setControlPoint", lua.create_function(set_control_point)?)?;
    tbl.set("insertControlPoint", lua.create_function(insert_control_point)?)?;
    tbl.set("removeControlPoint", lua.create_function(remove_control_point)?)?;
    tbl.set("translate", lua.create_function(translate)?)?;
    tbl.set("rotate", lua.create_function(rotate)?)?;
    tbl.set("scale", lua.create_function(scale)?)?;
    tbl.set("fromU8", lua.create_function(from_u8)?)?;
    tbl.set("gammaToLinear", lua.create_function(gamma_to_linear)?)?;
    tbl.set("linearToGamma", lua.create_function(linear_to_gamma)?)?;
    tbl.set("linear", lua.create_function(linear)?)?;
    tbl.set("easeInQuad", lua.create_function(ease_in_quad)?)?;
    tbl.set("easeOutQuad", lua.create_function(ease_out_quad)?)?;
    tbl.set("easeInOutQuad", lua.create_function(ease_in_out_quad)?)?;
    tbl.set("easeInCubic", lua.create_function(ease_in_cubic)?)?;
    tbl.set("easeOutCubic", lua.create_function(ease_out_cubic)?)?;
    tbl.set("easeInOutCubic", lua.create_function(ease_in_out_cubic)?)?;
    tbl.set("easeInQuart", lua.create_function(ease_in_quart)?)?;
    tbl.set("easeOutQuart", lua.create_function(ease_out_quart)?)?;
    tbl.set("easeInOutQuart", lua.create_function(ease_in_out_quart)?)?;
    tbl.set("easeInSine", lua.create_function(ease_in_sine)?)?;
    tbl.set("easeOutSine", lua.create_function(ease_out_sine)?)?;
    tbl.set("easeInOutSine", lua.create_function(ease_in_out_sine)?)?;
    tbl.set("easeInExpo", lua.create_function(ease_in_expo)?)?;
    tbl.set("easeOutExpo", lua.create_function(ease_out_expo)?)?;
    tbl.set("easeInOutExpo", lua.create_function(ease_in_out_expo)?)?;
    tbl.set("easeInElastic", lua.create_function(ease_in_elastic)?)?;
    tbl.set("easeOutElastic", lua.create_function(ease_out_elastic)?)?;
    tbl.set("easeOutBounce", lua.create_function(ease_out_bounce)?)?;
    tbl.set("easeInBounce", lua.create_function(ease_in_bounce)?)?;
    tbl.set("easeInBack", lua.create_function(ease_in_back)?)?;
    tbl.set("easeOutBack", lua.create_function(ease_out_back)?)?;
    tbl.set("apply", lua.create_function(apply)?)?;
    tbl.set("angleBetween", lua.create_function(angle_between)?)?;
    tbl.set("circleContainsPoint", lua.create_function(circle_contains_point)?)?;
    tbl.set("circleIntersectsCircle", lua.create_function(circle_intersects_circle)?)?;
    tbl.set("circleIntersectsLine", lua.create_function(circle_intersects_line)?)?;
    tbl.set("circleIntersectsSegment", lua.create_function(circle_intersects_segment)?)?;
    tbl.set("polygonArea", lua.create_function(polygon_area)?)?;
    tbl.set("polygonCentroid", lua.create_function(polygon_centroid)?)?;
    tbl.set("segmentIntersectsSegment", lua.create_function(segment_intersects_segment)?)?;
    tbl.set("closestPointOnSegment", lua.create_function(closest_point_on_segment)?)?;
    tbl.set("pointInPolygon", lua.create_function(point_in_polygon)?)?;
    tbl.set("lineIntersect", lua.create_function(line_intersect)?)?;
    tbl.set("bresenham", lua.create_function(bresenham)?)?;
    tbl.set("convexHull", lua.create_function(convex_hull)?)?;
    tbl.set("delaunayTriangulate", lua.create_function(delaunay_triangulate)?)?;
    tbl.set("identity", lua.create_function(identity)?)?;
    tbl.set("fromRowMajor", lua.create_function(from_row_major)?)?;
    tbl.set("fromTranslation", lua.create_function(from_translation)?)?;
    tbl.set("fromRotation", lua.create_function(from_rotation)?)?;
    tbl.set("fromShear", lua.create_function(from_shear)?)?;
    tbl.set("fromScale", lua.create_function(from_scale)?)?;
    tbl.set("triangulate", lua.create_function(triangulate)?)?;
    tbl.set("isConvex", lua.create_function(is_convex)?)?;
    tbl.set("withSeed", lua.create_function(with_seed)?)?;
    tbl.set("randomInt", lua.create_function(random_int)?)?;
    tbl.set("randomFloat", lua.create_function(random_float)?)?;
    tbl.set("randomNormal", lua.create_function(random_normal)?)?;
    tbl.set("setSeed", lua.create_function(set_seed)?)?;
    tbl.set("setState", lua.create_function(set_state)?)?;
    tbl.set("insert", lua.create_function(insert)?)?;
    tbl.set("remove", lua.create_function(remove)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("fromComponents", lua.create_function(from_components)?)?;
    tbl.set("translate", lua.create_function(translate)?)?;
    tbl.set("rotate", lua.create_function(rotate)?)?;
    tbl.set("scale", lua.create_function(scale)?)?;
    tbl.set("shear", lua.create_function(shear)?)?;
    tbl.set("setTransformation", lua.create_function(set_transformation)?)?;
    tbl.set("addValue", lua.create_function(add_value)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("setTime", lua.create_function(set_time)?)?;
    tbl.set("zero", lua.create_function(zero)?)?;
    tbl.set("splat", lua.create_function(splat)?)?;
    tbl.set("dot", lua.create_function(dot)?)?;
    tbl.set("length", lua.create_function(length)?)?;
    tbl.set("lengthSquared", lua.create_function(length_squared)?)?;
    tbl.set("normalize", lua.create_function(normalize)?)?;
    tbl.set("distance", lua.create_function(distance)?)?;
    tbl.set("lerp", lua.create_function(lerp)?)?;
    tbl.set("angle", lua.create_function(angle)?)?;
    luna.set("math", tbl)?;
    Ok(())
}
