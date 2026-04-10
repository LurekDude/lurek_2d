//! `luna.img` — CPU-side pixel-level image manipulation.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::image::serial;
use crate::image::{CompressedImageData, ImageData, LayeredImage};

// -------------------------------------------------------------------------------
// LuaLayeredImage UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`LayeredImage`].
pub struct LuaLayeredImage {
    inner: LayeredImage,
}

impl LuaUserData for LuaLayeredImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the canvas width shared by all layers.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));

        // -- getHeight --
        /// Returns the canvas height shared by all layers.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));

        // -- layerCount --
        /// Returns the number of layers in the stack.
        /// @return integer
        methods.add_method("layerCount", |_, this, ()| Ok(this.inner.layer_count()));

        // -- addLayer --
        /// Appends a new blank transparent layer on top and returns its 1-based index.
        /// @param name : string?
        /// @return integer
        methods.add_method_mut("addLayer", |_, this, name: Option<String>| {
            let label = name.unwrap_or_else(|| format!("Layer {}", this.inner.layer_count() + 1));
            let idx = this.inner.add_layer(label);
            Ok(idx + 1) // expose as 1-based
        });

        // -- removeLayer --
        /// Removes the layer at the given 1-based index. Returns true on success.
        /// @param index : integer
        /// @return boolean
        methods.add_method_mut("removeLayer", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.remove_layer(index - 1).is_some())
        });

        // -- getLayer --
        /// Returns a copy of the layer's pixel buffer as an ImageData.
        /// @param index : integer
        /// @return ImageData
        methods.add_method("getLayer", |lua, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| lua.create_userdata(l.data.clone()))
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))?
        });

        // -- setLayer --
        /// Replaces a layer's pixel buffer with a copy of the given ImageData.
        /// @param index : integer
        /// @param imagedata : ImageData
        /// @return boolean
        methods.add_method_mut(
            "setLayer",
            |_, this, (index, img): (usize, LuaAnyUserData)| {
                if index == 0 {
                    return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
                }
                let src = img
                    .borrow::<ImageData>()
                    .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
                Ok(this.inner.set_layer_image(index - 1, &src))
            },
        );

        // -- getOpacity --
        /// Returns the opacity of a layer in [0.0, 1.0].
        /// @param index : integer
        /// @return number
        methods.add_method("getOpacity", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.opacity)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });

        // -- setOpacity --
        /// Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
        /// @param index : integer
        /// @param opacity : number
        /// @return boolean
        methods.add_method_mut("setOpacity", |_, this, (index, opacity): (usize, f32)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_opacity(index - 1, opacity))
        });

        // -- isVisible --
        /// Returns whether a layer is visible.
        /// @param index : integer
        /// @return boolean
        methods.add_method("isVisible", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.visible)
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });

        // -- setVisible --
        /// Shows or hides a layer during compositing.
        /// @param index : integer
        /// @param visible : boolean
        /// @return boolean
        methods.add_method_mut("setVisible", |_, this, (index, visible): (usize, bool)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_visible(index - 1, visible))
        });

        // -- getName --
        /// Returns the name of a layer.
        /// @param index : integer
        /// @return string
        methods.add_method("getName", |_, this, index: usize| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            this.inner
                .get_layer(index - 1)
                .map(|l| l.name.clone())
                .ok_or_else(|| LuaError::RuntimeError(format!("layer {} does not exist", index)))
        });

        // -- setName --
        /// Renames a layer.
        /// @param index : integer
        /// @param name : string
        /// @return boolean
        methods.add_method_mut("setName", |_, this, (index, name): (usize, String)| {
            if index == 0 {
                return Err(LuaError::RuntimeError("layer index must be >= 1".into()));
            }
            Ok(this.inner.set_name(index - 1, name))
        });

        // -- swapLayers --
        /// Swaps two layers by their 1-based indices, changing their compositing order.
        /// @param a : integer
        /// @param b : integer
        /// @return boolean
        methods.add_method_mut("swapLayers", |_, this, (a, b): (usize, usize)| {
            if a == 0 || b == 0 {
                return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
            }
            Ok(this.inner.swap_layers(a - 1, b - 1))
        });

        // -- moveLayer --
        /// Moves a layer from one position to another, shifting layers in between.
        /// @param from_index : integer
        /// @param to_index : integer
        /// @return boolean
        methods.add_method_mut(
            "moveLayer",
            |_, this, (from_idx, to_idx): (usize, usize)| {
                if from_idx == 0 || to_idx == 0 {
                    return Err(LuaError::RuntimeError("layer indices must be >= 1".into()));
                }
                Ok(this.inner.move_layer(from_idx - 1, to_idx - 1))
            },
        );

        // -- merge --
        /// Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
        /// @return ImageData
        methods.add_method("merge", |lua, this, ()| {
            lua.create_userdata(this.inner.merge())
        });

        // -- save --
        /// Saves the layered image to a LIMG binary file at the given path.
        /// @param path : string
        /// @return nil
        methods.add_method("save", |_, this, path: String| {
            serial::save_layered(&this.inner, &path).map_err(LuaError::external)
        });
    }
}

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
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width));

        // -- getHeight --
        /// Returns the height of the base mip level in pixels.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height));

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

/// Registers the `lurek.img` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
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
                LuaError::RuntimeError("newImageData expects (width, height) or (filename)".into())
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

    // -- newLayeredImage --
    /// Creates a new empty LayeredImage canvas with no layers.
    /// @param width : integer
    /// @param height : integer
    /// @return LayeredImage
    tbl.set(
        "newLayeredImage",
        lua.create_function(move |lua, (width, height): (u32, u32)| {
            lua.create_userdata(LuaLayeredImage {
                inner: LayeredImage::new(width, height),
            })
        })?,
    )?;

    // -- saveImage --
    /// Saves a flat ImageData to a LIMG binary file at the given path.
    /// @param imagedata : ImageData
    /// @param path : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "saveImage",
        lua.create_function(move |_, (img_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let img = img_ud
                .borrow::<ImageData>()
                .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
            serial::save_image(&img, path_str).map_err(LuaError::external)
        })?,
    )?;

    // -- savePNG --
    /// Saves a flat ImageData as a PNG file at the given path.
    /// @param imagedata : ImageData
    /// @param path : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "savePNG",
        lua.create_function(move |_, (img_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let img = img_ud
                .borrow::<ImageData>()
                .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
            let bytes = img.encode_png().map_err(LuaError::RuntimeError)?;
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).map_err(LuaError::external)?;
            }
            std::fs::write(&path, &bytes).map_err(LuaError::external)
        })?,
    )?;

    // -- loadImage --
    /// Loads an ImageData from a LIMG binary file.
    /// @param path : string
    /// @return ImageData
    let s = state.clone();
    tbl.set(
        "loadImage",
        lua.create_function(move |lua, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let img = serial::load_image(path_str).map_err(LuaError::external)?;
            lua.create_userdata(img)
        })?,
    )?;

    // -- loadLayered --
    /// Loads a LayeredImage from a LIMG binary file.
    /// @param path : string
    /// @return LayeredImage
    let s = state.clone();
    tbl.set(
        "loadLayered",
        lua.create_function(move |lua, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let stack = serial::load_layered(path_str).map_err(LuaError::external)?;
            lua.create_userdata(LuaLayeredImage { inner: stack })
        })?,
    )?;

    luna.set("img", tbl)?;
    Ok(())
}
