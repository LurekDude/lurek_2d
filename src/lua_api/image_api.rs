//! `luna.image` Lua API bindings.
//!
//! Auto-generated skeleton from `src/image/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaCompressedImageData ────────────────────────────────────────────────────────────

pub struct LuaCompressedImageData(/* TODO: add key + state fields */);


impl LuaCompressedImageData {
    /// Return the number of mipmap levels stored.
    ///
    ///
    /// @return integer
    pub fn get_mipmap_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaCompressedImageData {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getMipmapCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaImageData ────────────────────────────────────────────────────────────

pub struct LuaImageData(/* TODO: add key + state fields */);


impl LuaImageData {
    /// Get the width of the image. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the height of the image. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the RGBA values of a pixel at (x, y). Values are 0-255.
    ///
    /// @param x : integer
    /// @param y : integer
    /// @return Option<(u8
    pub fn get_pixel(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Encode the image as PNG bytes. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return Result<Vec<u8>
    pub fn encode_png(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the raw pixel bytes as a vector (for Lua getString() compatibility).
    ///
    ///
    /// @return table
    pub fn get_string(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaImageData {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("width", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("height", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPixel", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("encodePng", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getString", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaPaletteLUT ────────────────────────────────────────────────────────────

pub struct LuaPaletteLUT(/* TODO: add key + state fields */);


impl LuaPaletteLUT {
    /// Returns the number of color mappings. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_color_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the source color at the given 0-based index, if it exists.
    ///
    /// @param index : integer
    /// @return Color?
    pub fn get_from_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the target color at the given 0-based index, if it exists.
    ///
    /// @param index : integer
    /// @return Color?
    pub fn get_to_color(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaPaletteLUT {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getColorCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFromColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getToColor", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.image.* functions ──────────────────────────────────────────

/// Load compressed texture data from DDS file bytes.
///
/// Returns `Unknown` format rather than failing when the format is unrecognised.
///
/// @param bytes : [u8]
/// @return Result<Self
pub fn from_dds(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Load an image from a file path. Returns a fully initialised instance with all fields set to their initial values.
///
/// @param path : str
/// @return Result<Self
pub fn from_file(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create from raw RGBA bytes. Returns a fully initialised instance with all fields set to their initial values.
///
/// @param width : integer
/// @param height : integer
/// @param bytes : table
/// @return Result<Self
pub fn from_bytes(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the RGBA values of a pixel at (x, y). Values are 0-255.
///
/// @param x : integer
/// @param y : integer
/// @param r : u8
/// @param g : u8
/// @param b : u8
/// @param a : u8
/// @return boolean
pub fn set_pixel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Paste source image onto self at position (dx, dy).
///
///
/// @param source : ImageData
/// @param dx : integer
/// @param dy : integer
pub fn paste(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Apply a function to every pixel, replacing each (r,g,b,a) with the return value.
///
/// @param f : F
/// @return The
pub fn map_pixel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the color mapping at the given 0-based index.
///
///
/// @param index : integer
/// @param from : Color
/// @param to : Color
pub fn set_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.image` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("fromDds", lua.create_function(from_dds)?)?;
    tbl.set("fromFile", lua.create_function(from_file)?)?;
    tbl.set("fromBytes", lua.create_function(from_bytes)?)?;
    tbl.set("setPixel", lua.create_function(set_pixel)?)?;
    tbl.set("paste", lua.create_function(paste)?)?;
    tbl.set("mapPixel", lua.create_function(map_pixel)?)?;
    tbl.set("setColor", lua.create_function(set_color)?)?;
    luna.set("image", tbl)?;
    Ok(())
}
