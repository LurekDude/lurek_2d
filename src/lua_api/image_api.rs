//! Registers the `luna.image.*` pixel-level image manipulation API.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::image::ImageData;
use crate::lua_api::SharedState;

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

    /// Image.
    luna.set("image", image_table)?;
    Ok(())
}
