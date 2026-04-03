//! Registers the `luna.image.*` pixel-level image manipulation API.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for image api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::image::{CompressedImageData, ImageData};
use crate::lua_api::SharedState;

/// Lua userdata wrapper for [`CompressedImageData`].
///
/// Exposes `getDimensions()`, `getMipmapCount()`, and `getFormat()` to Lua.
struct LuaCompressedImageData {
    inner: CompressedImageData,
}

impl LuaUserData for LuaCompressedImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Return `(width, height)` of the base mip level.
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.inner.get_dimensions();
            Ok((w, h))
        });
        /// Return the number of mipmap levels stored in this compressed image.
        methods.add_method("getMipmapCount", |_, this, ()| {
            Ok(this.inner.get_mipmap_count())
        });
        /// Return the compressed format name string (e.g. `"dxt1"`, `"bc7"`).
        methods.add_method("getFormat", |_, this, ()| {
            Ok(this.inner.get_format().to_string())
        });
        /// Return the width of the base mip level in pixels.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getWidth", |_, this, ()| {
            Ok(this.inner.width)
        });
        /// Return the height of the base mip level in pixels.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getHeight", |_, this, ()| {
            Ok(this.inner.height)
        });
    }
}

/// Registers the `luna.image` table on the provided `luna` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let image_table = lua.create_table()?;

    // luna.image.newImageData(width, height) or luna.image.newImageData(filename)
    /// Creates a new blank RGBA8 ImageData buffer of the given size.
    let state_clone = state.clone();
    /// @param args : MultiValue
    image_table.set(
        "newImageData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let img_data = if args.len() == 1 {
                // Single arg: filename (string)
                match args.into_iter().next().unwrap() {
                    LuaValue::String(s) => {
                        let filename = s
                            .to_str()
                            .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                            .to_string();
                        let state = state_clone.borrow();
                        let path = state.game_dir.join(&filename);
                        ImageData::from_file(
                            path.to_str().ok_or_else(|| {
                                LuaError::RuntimeError("Invalid path".to_string())
                            })?,
                        )
                        .map_err(LuaError::RuntimeError)?
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "newImageData expects (width, height) or (filename)".to_string(),
                        ))
                    }
                }
            } else if args.len() >= 2 {
                let mut iter = args.into_iter();
                let width = match iter.next().unwrap() {
                    LuaValue::Integer(n) => n as u32,
                    LuaValue::Number(n) => n as u32,
                    _ => return Err(LuaError::RuntimeError("width must be a number".to_string())),
                };
                let height = match iter.next().unwrap() {
                    LuaValue::Integer(n) => n as u32,
                    LuaValue::Number(n) => n as u32,
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "height must be a number".to_string(),
                        ))
                    }
                };
                ImageData::new(width, height)
            } else {
                return Err(LuaError::RuntimeError(
                    "newImageData expects (width, height) or (filename)".to_string(),
                ));
            };

            lua.create_userdata(img_data)
        })?,
    )?;

    // luna.image.newCompressedData(filename) -> CompressedImageData userdata
    let state_clone = state.clone();
    image_table.set(
        "newCompressedData",
        lua.create_function(move |lua, filename: String| {
            let path = {
                let s = state_clone.borrow();
                s.game_dir.join(&filename)
            };
            let bytes = std::fs::read(&path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "newCompressedData: cannot read '{}': {}",
                    filename, e
                ))
            })?;
            let cid = CompressedImageData::from_dds(&bytes).map_err(|e| {
                LuaError::RuntimeError(format!("newCompressedData: {}", e))
            })?;
            lua.create_userdata(LuaCompressedImageData { inner: cid })
        })?,
    )?;

    // luna.image.isCompressed(path) -> bool
    // Returns true if the file at `path` starts with the DDS magic bytes.
    let state_clone = state.clone();
    image_table.set(
        "isCompressed",
        lua.create_function(move |_, filename: String| {
            let path = {
                let s = state_clone.borrow();
                s.game_dir.join(&filename)
            };
            let result = (|| -> Option<bool> {
                let mut f = std::fs::File::open(&path).ok()?;
                let mut magic = [0u8; 4];
                use std::io::Read;
                f.read_exact(&mut magic).ok()?;
                Some(magic == [0x44, 0x44, 0x53, 0x20])
            })()
            .unwrap_or(false);
            Ok(result)
        })?,
    )?;

    /// Image.
    luna.set("image", image_table)?;
    Ok(())
}
