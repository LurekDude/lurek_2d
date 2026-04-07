//! `luna.image` — CPU-side pixel-level image manipulation.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::image::{CompressedImageData, ImageData};

// -------------------------------------------------------------------------------
// LuaCompressedImageData UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`CompressedImageData`].
pub struct LuaCompressedImageData {
    inner: CompressedImageData,
}

impl LuaUserData for LuaCompressedImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- getWidth --
        /// Returns the width of the base mip level in pixels.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.width)
        });

        // -- getHeight --
        /// Returns the height of the base mip level in pixels.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.height)
        });

        // -- getDimensions --
        /// Returns the width and height of the base mip level.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.inner.get_dimensions())
        });

        // -- getMipmapCount --
        /// Returns the number of mipmap levels stored.
        /// @return integer
        methods.add_method("getMipmapCount", |_, this, ()| {
            Ok(this.inner.get_mipmap_count())
        });

        // -- getFormat --
        /// Returns the compressed format name string.
        /// @return string
        methods.add_method("getFormat", |_, this, ()| {
            Ok(this.inner.get_format().to_string())
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.image` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newImageData --
    /// Creates a new blank ImageData or loads one from a file.
    /// @param width_or_filename : integer|string
    /// @param height : integer?
    /// @return ImageData
    let s = state.clone();
    tbl.set(
        "newImageData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let first = iter.next().ok_or_else(|| {
                LuaError::RuntimeError(
                    "newImageData expects (width, height) or (filename)".into(),
                )
            })?;
            let img = if let LuaValue::String(ref filename) = first {
                let name = filename
                    .to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
                let path = s.borrow().game_dir.join(name);
                ImageData::from_file(
                    path.to_str()
                        .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?,
                )
                .map_err(LuaError::RuntimeError)?
            } else {
                let width = match first {
                    LuaValue::Integer(n) => n as u32,
                    LuaValue::Number(n) => n as u32,
                    _ => {
                        return Err(LuaError::RuntimeError("width must be a number".into()));
                    }
                };
                let height = match iter.next() {
                    Some(LuaValue::Integer(n)) => n as u32,
                    Some(LuaValue::Number(n)) => n as u32,
                    _ => {
                        return Err(LuaError::RuntimeError("height must be a number".into()));
                    }
                };
                ImageData::new(width, height)
            };
            lua.create_userdata(img)
        })?,
    )?;

    // -- newCompressedData --
    /// Loads compressed texture data from a DDS file.
    /// @param filename : string
    /// @return CompressedImageData
    let s = state.clone();
    tbl.set(
        "newCompressedData",
        lua.create_function(move |lua, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let cid = CompressedImageData::from_file(path_str).map_err(LuaError::external)?;
            lua.create_userdata(LuaCompressedImageData { inner: cid })
        })?,
    )?;

    // -- isCompressed --
    /// Returns true if the file at the given path is a DDS file.
    /// @param filename : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isCompressed",
        lua.create_function(move |_, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            Ok(CompressedImageData::is_dds_file(
                path.to_str().unwrap_or(""),
            ))
        })?,
    )?;

    luna.set("image", tbl)?;
    Ok(())
}
