//! `luna.input` Lua API bindings.
//!
//! Auto-generated skeleton from `src/input/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaGamepadMappings ────────────────────────────────────────────────────────────

pub struct LuaGamepadMappings(/* TODO: add key + state fields */);


impl LuaGamepadMappings {
    /// Returns the mapping string for `guid`, or `None` if unknown.
    ///
    ///
    /// # Parameters
    /// - `guid` — `SDL-format` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param guid : SDL-format
    /// @return Option<
    pub fn get_mapping_string(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Writes all stored mappings to a plain-text file, one per line.
    ///
    ///
    /// # Parameters
    /// - `path` — `Destination` ...
    ///
    /// # Returns
    /// `Result<()`.
    ///
    /// @param path : Destination
    /// @return Result<()
    pub fn save_to_file(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGamepadMappings {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getMappingString", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("saveToFile", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGamepadState ────────────────────────────────────────────────────────────

pub struct LuaGamepadState(/* TODO: add key + state fields */);


impl LuaGamepadState {
    /// Returns `true` if the button at `button` index is currently pressed.
    ///
    ///
    /// # Parameters
    /// - `button` — `Button` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param button : Button
    /// @return boolean
    pub fn is_button_pressed(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current value of the analog axis at `axis` index.
    ///
    ///
    /// # Parameters
    /// - `axis` — `Axis` ...
    ///
    /// # Returns
    /// `number`.
    ///
    /// @param axis : Axis
    /// @return number
    pub fn get_axis_value(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether this gamepad is currently connected.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_connected(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of distinct buttons that have been reported.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_button_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of distinct axes that have been reported.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_axis_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the d-pad hat direction string for the requested hat index.
    ///
    ///
    /// # Parameters
    /// - `hat` — `integer` ...
    ///
    /// @param hat : integer
    pub fn get_hat(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGamepadState {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isButtonPressed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAxisValue", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isConnected", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getButtonCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAxisCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHat", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaKeyboardState ────────────────────────────────────────────────────────────

pub struct LuaKeyboardState(/* TODO: add key + state fields */);


impl LuaKeyboardState {
    /// Returns `true` if the given physical scancode is currently held down.
    ///
    ///
    /// # Parameters
    /// - `scancode` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param scancode : str
    /// @return boolean
    pub fn is_scancode_down(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if key repeat event delivery is enabled.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn has_key_repeat(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if text input (IME) event delivery is enabled.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn has_text_input(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if `key` is currently held down.
    ///
    ///
    /// # Parameters
    /// - `key` — `Lowercase` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param key : Lowercase
    /// @return boolean
    pub fn is_down(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the named modifier key is currently held.
    ///
    ///
    /// # Parameters
    /// - `modifier` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param modifier : str
    /// @return boolean
    pub fn is_modifier_active(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaKeyboardState {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isScancodeDown", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasKeyRepeat", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasTextInput", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isDown", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isModifierActive", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMouseState ────────────────────────────────────────────────────────────

pub struct LuaMouseState(/* TODO: add key + state fields */);


impl LuaMouseState {
    /// Returns `true` if the button at `button` index is currently held down.
    ///
    ///
    /// # Parameters
    /// - `button` — `Button` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param button : Button
    /// @return boolean
    pub fn is_down(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the cursor is visible. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_visible(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether the cursor is confined to the window.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_grabbed(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns whether relative mouse mode is active.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn get_relative_mode(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current system cursor shape.
    ///
    ///
    /// # Returns
    /// `SystemCursor`.
    ///
    /// @return SystemCursor
    pub fn get_cursor(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMouseState {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isDown", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isVisible", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isGrabbed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRelativeMode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCursor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTouchState ────────────────────────────────────────────────────────────

pub struct LuaTouchState(/* TODO: add key + state fields */);


impl LuaTouchState {
    /// Returns all active touch points. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn get_touches(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns a specific touch point by ID. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `id` — `integer` ...
    ///
    /// # Returns
    /// `TouchPoint?`.
    ///
    /// @param id : integer
    /// @return TouchPoint?
    pub fn get_touch(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of active touches. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_touch_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTouchState {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTouches", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTouch", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTouchCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.input.* functions ──────────────────────────────────────────

/// Updates the pressed state for a specific button.
///
///
/// # Parameters
/// - `button` — `Button` ...
/// - `pressed` — `true` ...
///
/// @param button : Button
/// @param pressed : true
pub fn update_button(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates the value for a specific analog axis.
///
///
/// # Parameters
/// - `axis` — `Axis` ...
/// - `value` — `Axis` ...
///
/// @param axis : Axis
/// @param value : Axis
pub fn update_axis(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a `gilrs::Button` to a engine-compatible string name.
///
///
/// # Parameters
/// - `button` — `gilrs::Button` ...
///
/// @param button : gilrs::Button
pub fn gilrs_button_to_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a `gilrs::Axis` to a engine-compatible string name.
///
///
/// # Parameters
/// - `axis` — `gilrs::Axis` ...
///
/// @param axis : gilrs::Axis
pub fn gilrs_axis_to_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Inserts or replaces the mapping string for the given GUID.
///
///
/// # Parameters
/// - `guid` — `SDL-format` ...
/// - `mapping` — `Full` ...
///
/// @param guid : SDL-format
/// @param mapping : Full
pub fn set_mapping(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses a plain-text GameControllerDB file and merges entries into this store.
///
/// Lines that start with `#` are treated as comments and skipped.
/// Empty lines are also skipped.  Returns the number of mappings loaded.
///
///
/// # Parameters
/// - `path` — `File` ...
///
/// # Returns
/// `Result<usize`.
///
/// @param path : File
/// @return Result<usize
pub fn load_from_file(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Records that `key` is now held down, adding it to the pressed list if newly down.
///
///
/// # Parameters
/// - `key` — `Lowercase` ...
///
/// @param key : Lowercase
pub fn set_key_down(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Records that `key` was released, adding it to the released list if it was down.
///
///
/// # Parameters
/// - `key` — `Lowercase` ...
///
/// @param key : Lowercase
pub fn set_key_up(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the modifier bitmask when modifiers change.
///
///
/// # Parameters
/// - `shift` — `boolean` ...
/// - `ctrl` — `boolean` ...
/// - `alt` — `boolean` ...
/// - `meta` — `boolean` ...
///
/// @param shift : boolean
/// @param ctrl : boolean
/// @param alt : boolean
/// @param meta : boolean
pub fn set_modifiers(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `luna.*` API.
///
/// Returns `Some(name)` for recognised keys, `None` for keys without a mapping
/// (which the engine skips silently).
///
///
/// # Parameters
/// - `key` — `A` ...
///
/// # Returns
/// `string?`.
///
/// @param key : A
/// @return string?
pub fn winit_key_to_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.
///
/// Scancodes represent physical key positions and are layout-independent.
///
///
/// # Parameters
/// - `code` — `A` ...
///
/// # Returns
/// `Option<`.
///
/// @param code : A
/// @return Option<
pub fn winit_scancode_to_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parses a cursor name string into a `SystemCursor` variant.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `Self`.
///
/// @param name : str
/// @return Self
pub fn from_name(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates the cursor position. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
///
/// @param x : number
/// @param y : number
pub fn update_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Requests that the backend cursor move to a new position.
///
///
/// # Parameters
/// - `x` — `number` ...
/// - `y` — `number` ...
///
/// @param x : number
/// @param y : number
pub fn request_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Records a button press or release event, updating the transient pressed/released flags.
///
///
/// # Parameters
/// - `button` — `Button` ...
/// - `pressed` — `true` ...
///
/// @param button : Button
/// @param pressed : true
pub fn set_button(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets cursor visibility. Replaces the current visible value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `visible` — `boolean` ...
///
/// @param visible : boolean
pub fn set_visible(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets whether the cursor is confined to the window.
///
///
/// # Parameters
/// - `grabbed` — `boolean` ...
///
/// @param grabbed : boolean
pub fn set_grabbed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets relative (FPS) mouse mode. Replaces the current relative mode value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `relative` — `boolean` ...
///
/// @param relative : boolean
pub fn set_relative_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Accumulates scroll delta for the current frame.
///
///
/// # Parameters
/// - `dx` — `number` ...
/// - `dy` — `number` ...
///
/// @param dx : number
/// @param dy : number
pub fn accumulate_scroll(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the system cursor shape. Replaces the current cursor value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// # Parameters
/// - `cursor` — `SystemCursor` ...
///
/// @param cursor : SystemCursor
pub fn set_cursor(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns whether cursor customisation is supported on this platform.
///
///
/// # Returns
/// `boolean`.
///
/// @return boolean
pub fn is_cursor_supported(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Registers or updates a touch point. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `pressure` — `number` ...
///
/// @param id : integer
/// @param x : number
/// @param y : number
/// @param pressure : number
pub fn touch_start(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates the position of an existing touch point.
///
///
/// # Parameters
/// - `id` — `integer` ...
/// - `x` — `number` ...
/// - `y` — `number` ...
/// - `pressure` — `number` ...
///
/// @param id : integer
/// @param x : number
/// @param y : number
/// @param pressure : number
pub fn touch_move(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a touch point. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `id` — `integer` ...
///
/// @param id : integer
pub fn touch_end(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.input` API table.
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
    tbl.set("updateButton", lua.create_function(update_button)?)?;
    tbl.set("updateAxis", lua.create_function(update_axis)?)?;
    tbl.set("gilrsButtonToString", lua.create_function(gilrs_button_to_string)?)?;
    tbl.set("gilrsAxisToString", lua.create_function(gilrs_axis_to_string)?)?;
    tbl.set("setMapping", lua.create_function(set_mapping)?)?;
    tbl.set("loadFromFile", lua.create_function(load_from_file)?)?;
    tbl.set("setKeyDown", lua.create_function(set_key_down)?)?;
    tbl.set("setKeyUp", lua.create_function(set_key_up)?)?;
    tbl.set("setModifiers", lua.create_function(set_modifiers)?)?;
    tbl.set("winitKeyToString", lua.create_function(winit_key_to_string)?)?;
    tbl.set("winitScancodeToString", lua.create_function(winit_scancode_to_string)?)?;
    tbl.set("fromName", lua.create_function(from_name)?)?;
    tbl.set("updatePosition", lua.create_function(update_position)?)?;
    tbl.set("requestPosition", lua.create_function(request_position)?)?;
    tbl.set("setButton", lua.create_function(set_button)?)?;
    tbl.set("setVisible", lua.create_function(set_visible)?)?;
    tbl.set("setGrabbed", lua.create_function(set_grabbed)?)?;
    tbl.set("setRelativeMode", lua.create_function(set_relative_mode)?)?;
    tbl.set("accumulateScroll", lua.create_function(accumulate_scroll)?)?;
    tbl.set("setCursor", lua.create_function(set_cursor)?)?;
    tbl.set("isCursorSupported", lua.create_function(is_cursor_supported)?)?;
    tbl.set("touchStart", lua.create_function(touch_start)?)?;
    tbl.set("touchMove", lua.create_function(touch_move)?)?;
    tbl.set("touchEnd", lua.create_function(touch_end)?)?;
    luna.set("input", tbl)?;
    Ok(())
}
