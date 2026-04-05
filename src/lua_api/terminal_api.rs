//! `luna.terminal` Lua API bindings.
//!
//! Auto-generated skeleton from `src/terminal/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaTerminal ────────────────────────────────────────────────────────────

pub struct LuaTerminal(/* TODO: add key + state fields */);


impl LuaTerminal {
    /// Get a cell at 1-based coordinates.
    ///
    /// Returns a default cell if coordinates are out of bounds.
    ///
    ///
    /// # Parameters
    /// - `col` — `integer` ...
    /// - `row` — `integer` ...
    ///
    /// # Returns
    /// `TCell`.
    ///
    /// @param col : integer
    /// @param row : integer
    /// @return TCell
    pub fn get(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of attached widgets.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn get_widget_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get a reference to a widget by index.
    ///
    ///
    /// # Parameters
    /// - `index` — `integer` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_widget(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the currently focused widget index.
    ///
    ///
    /// # Returns
    /// `integer?`.
    ///
    /// @return integer?
    pub fn get_focused(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of columns.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn cols(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of rows.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn rows(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get a cell at 1-based coordinates, returning `None` if out of bounds.
    ///
    ///
    /// # Parameters
    /// - `col` — `integer` ...
    /// - `row` — `integer` ...
    ///
    /// # Returns
    /// `TCell?`.
    ///
    /// @param col : integer
    /// @param row : integer
    /// @return TCell?
    pub fn try_get(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of attached widgets.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn widget_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Find the first widget whose `base.tag` equals `tag`.
    ///
    ///
    /// # Parameters
    /// - `tag` — `str` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param tag : str
    /// @return Option<
    pub fn find_by_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTerminal {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("get", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWidgetCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getWidget", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFocused", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cols", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("rows", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tryGet", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("widgetCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findByTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.terminal.* functions ──────────────────────────────────────────

/// Set a cell at 1-based coordinates.
///
/// Out-of-bounds coordinates are silently ignored.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `ch` — `integer` ...
/// - `fg` — `[f32; 4]` ...
/// - `bg` — `[f32; 4]` ...
///
/// @param col : integer
/// @param row : integer
/// @param ch : integer
/// @param fg : [f32; 4]
/// @param bg : [f32; 4]
pub fn set(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the cursor position from 1-based coordinates.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
///
/// @param col : integer
/// @param row : integer
pub fn set_cursor(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a widget to the terminal.
///
///
/// # Parameters
/// - `widget` — `Widget` ...
///
/// # Returns
/// `integer`.
///
/// @param widget : Widget
/// @return integer
pub fn add_widget(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a widget by index.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param index : integer
/// @return boolean
pub fn remove_widget(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Get a mutable reference to a widget by index.
///
///
/// # Parameters
/// - `index` — `integer` ...
///
/// # Returns
/// `Option<`.
///
/// @param index : integer
/// @return Option<
pub fn get_widget_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the focused widget by index.
///
///
/// # Parameters
/// - `index` — `integer?` ...
///
/// @param index : integer?
pub fn set_focus(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Route a key press to the focused widget.
///
///
/// # Parameters
/// - `key` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param key : str
/// @return boolean
pub fn keypressed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Route text input to the focused widget.
///
///
/// # Parameters
/// - `text_input` — `str` ...
///
/// # Returns
/// `boolean`.
///
/// @param text_input : str
/// @return boolean
pub fn textinput(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Route a mouse press to widgets using 1-based grid coordinates.
///
///
/// # Parameters
/// - `grid_col` — `integer` ...
/// - `grid_row` — `integer` ...
/// - `button` — `integer` ...
///
/// # Returns
/// `boolean`.
///
/// @param grid_col : integer
/// @param grid_row : integer
/// @param button : integer
/// @return boolean
pub fn mousepressed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set only the character at a cell, keeping existing colours.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `ch` — `integer` ...
///
/// @param col : integer
/// @param row : integer
/// @param ch : integer
pub fn set_char(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set only the foreground colour at a cell.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `fg` — `[f32; 4]` ...
///
/// @param col : integer
/// @param row : integer
/// @param fg : [f32; 4]
pub fn set_fg(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set only the background colour at a cell.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `bg` — `[f32; 4]` ...
///
/// @param col : integer
/// @param row : integer
/// @param bg : [f32; 4]
pub fn set_bg(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Write a UTF-8 string left-to-right starting at a 1-based position.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `text` — `str` ...
///
/// @param col : integer
/// @param row : integer
/// @param text : str
pub fn print(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Resize the terminal grid.
///
///
/// # Parameters
/// - `new_cols` — `integer` ...
/// - `new_rows` — `integer` ...
///
/// @param new_cols : integer
/// @param new_rows : integer
pub fn resize(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a style name string.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `BorderStyle?`.
///
/// @param s : str
/// @return BorderStyle?
pub fn from_str_name(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the widget position from 1-based coordinates.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
///
/// @param col : integer
/// @param row : integer
pub fn set_position_1based(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new label widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `text` — `impl Into<String>` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param text : impl Into<String>
/// @return Widget
pub fn new_label(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new button widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `width` — `integer` ...
/// - `height` — `integer` ...
/// - `text` — `impl Into<String>` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param width : integer
/// @param height : integer
/// @param text : impl Into<String>
/// @return Widget
pub fn new_button(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new text box widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `width` — `integer` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param width : integer
/// @return Widget
pub fn new_text_box(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new list widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `width` — `integer` ...
/// - `height` — `integer` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param width : integer
/// @param height : integer
/// @return Widget
pub fn new_list(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new border widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `width` — `integer` ...
/// - `height` — `integer` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param width : integer
/// @param height : integer
/// @return Widget
pub fn new_border(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new panel widget.
///
///
/// # Parameters
/// - `col` — `integer` ...
/// - `row` — `integer` ...
/// - `width` — `integer` ...
/// - `height` — `integer` ...
///
/// # Returns
/// `Widget`.
///
/// @param col : integer
/// @param row : integer
/// @param width : integer
/// @param height : integer
/// @return Widget
pub fn new_panel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.terminal` API table.
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
    tbl.set("set", lua.create_function(set)?)?;
    tbl.set("setCursor", lua.create_function(set_cursor)?)?;
    tbl.set("addWidget", lua.create_function(add_widget)?)?;
    tbl.set("removeWidget", lua.create_function(remove_widget)?)?;
    tbl.set("getWidgetMut", lua.create_function(get_widget_mut)?)?;
    tbl.set("setFocus", lua.create_function(set_focus)?)?;
    tbl.set("keypressed", lua.create_function(keypressed)?)?;
    tbl.set("textinput", lua.create_function(textinput)?)?;
    tbl.set("mousepressed", lua.create_function(mousepressed)?)?;
    tbl.set("setChar", lua.create_function(set_char)?)?;
    tbl.set("setFg", lua.create_function(set_fg)?)?;
    tbl.set("setBg", lua.create_function(set_bg)?)?;
    tbl.set("print", lua.create_function(print)?)?;
    tbl.set("resize", lua.create_function(resize)?)?;
    tbl.set("fromStrName", lua.create_function(from_str_name)?)?;
    tbl.set("setPosition1based", lua.create_function(set_position_1based)?)?;
    tbl.set("newLabel", lua.create_function(new_label)?)?;
    tbl.set("newButton", lua.create_function(new_button)?)?;
    tbl.set("newTextBox", lua.create_function(new_text_box)?)?;
    tbl.set("newList", lua.create_function(new_list)?)?;
    tbl.set("newBorder", lua.create_function(new_border)?)?;
    tbl.set("newPanel", lua.create_function(new_panel)?)?;
    luna.set("terminal", tbl)?;
    Ok(())
}
