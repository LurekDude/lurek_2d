//! `lurek.image` â€” CPU-side pixel-level image manipulation.
//!
//! Exposes `ImageData` (RGBA pixel buffers), `CompressedImageData` (DXT/BC/ETC),
//! `LayeredImage` (multi-layer compositing), `ProvinceGrid` (colour-keyed region maps),
//! and `PaletteLUT` (palette-swap look-up tables). All operations run on the CPU;
//! upload to GPU is handled by the render layer.

use super::render_api::LuaImageData;
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::image::serial;
use crate::image::{CompressedImageData, ImageData, LayeredImage, ProvinceGrid};

// -------------------------------------------------------------------------------
// LuaProvinceGrid UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`ProvinceGrid`].
pub struct LuaProvinceGrid {
    inner: ProvinceGrid,
}

impl LuaUserData for LuaProvinceGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the grid width in pixels.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));

        // -- getHeight --
        /// Returns the grid height in pixels.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));

        // -- getAt --
        /// Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
        /// @param x : integer
        /// @param y : integer
        /// @return integer
        methods.add_method("getAt", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.get_at(x, y))
        });

        // -- provinceCount --
        /// Returns the number of unique non-zero province IDs detected in the map.
        /// @return integer
        methods.add_method("provinceCount", |_, this, ()| {
            Ok(this.inner.province_count())
        });

        // -- adjacencies --
        /// Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
        /// @return table
        methods.add_method("adjacencies", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, &(a, b, bp)) in this.inner.adjacencies().iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("province_a", a)?;
                entry.set("province_b", b)?;
                entry.set("border_pixels", bp)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
    }
}

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
        /// Renames the layer at the given index to the new name string.
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

/// Registers the `lurek.image` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
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
            // Accept both LuaImageData (from render/spine) and raw ImageData (from image module).
            let bytes = if let Ok(wrapper) = img_ud.borrow::<LuaImageData>() {
                wrapper.inner.encode_png().map_err(LuaError::RuntimeError)?
            } else {
                let raw = img_ud
                    .borrow::<ImageData>()
                    .map_err(|_| LuaError::RuntimeError("argument must be an ImageData".into()))?;
                raw.encode_png().map_err(LuaError::RuntimeError)?
            };
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

    // -- newPaletteLut --
    /// Creates a new empty `PaletteLUT` used to remap colours in an image.
    ///
    /// @return PaletteLUT
    tbl.set(
        "newPaletteLut",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaPaletteLUT {
                inner: crate::image::palette_lut::PaletteLUT::new(),
            })
        })?,
    )?;
    // â”€â”€ newProvinceGrid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    /// Loads a province map PNG and builds an O(1) spatial index with adjacency data.
    /// Each unique RGB color in the PNG is assigned a sequential province ID (1..n).
    /// Black pixels (0,0,0) are treated as background and return ID 0.
    /// @param filename : string
    /// @return ProvinceGrid
    let s = state.clone();
    tbl.set(
        "newProvinceGrid",
        lua.create_function(move |lua, filename: String| {
            let path = s.borrow().game_dir.join(&filename);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".into()))?;
            let grid = ProvinceGrid::from_file(path_str).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaProvinceGrid { inner: grid })
        })?,
    )?;
    lurek.set("image", tbl)?;
    Ok(())
}

impl mlua::UserData for ImageData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the width.
        ///
        /// @return table|nil
        methods.add_method("getWidth", |_, this, ()| Ok(this.width()));
        /// Returns the height.
        ///
        /// @return table|nil
        methods.add_method("getHeight", |_, this, ()| Ok(this.height()));
        /// Returns the dimensions.
        ///
        /// @return table|nil
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.dimensions();
            Ok((w, h))
        });
        /// Returns the pixel.
        ///
        /// @param x : integer
        /// @param y : integer
        /// @return nil
        methods.add_method("getPixel", |_, this, (x, y): (u32, u32)| {
            this.get_pixel(x, y).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "Pixel ({}, {}) out of bounds ({}x{})",
                    x,
                    y,
                    this.width(),
                    this.height()
                ))
            })
        });
        methods.add_method_mut(
            "setPixel",
            |_, this, (x, y, r, g, b, a): (u32, u32, u8, u8, u8, u8)| {
                if this.set_pixel(x, y, r, g, b, a) {
                    Ok(())
                } else {
                    Err(LuaError::RuntimeError(format!(
                        "Pixel ({}, {}) out of bounds ({}x{})",
                        x,
                        y,
                        this.width(),
                        this.height()
                    )))
                }
            },
        );
        /// Encode.
        ///
        /// @param format : string
        /// @return nil
        methods.add_method("encode", |_, this, format: String| match format.as_str() {
            "png" => this.encode_png().map_err(LuaError::RuntimeError),
            _ => Err(LuaError::RuntimeError(format!(
                "Unknown image format: '{}'. Use 'png'.",
                format
            ))),
        });
        /// Returns the string.
        ///
        /// @return table|nil
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));

        /// Map pixel.
        ///
        /// @param func : function
        /// @return nil
        methods.add_method_mut("mapPixel", |_, this, func: LuaFunction| {
            let w = this.width();
            let h = this.height();
            for y in 0..h {
                for x in 0..w {
                    if let Some((r, g, b, a)) = this.get_pixel(x, y) {
                        let result: (u8, u8, u8, u8) =
                            func.call((x, y, r, g, b, a)).map_err(|e| {
                                LuaError::RuntimeError(format!("mapPixel callback: {}", e))
                            })?;
                        this.set_pixel(x, y, result.0, result.1, result.2, result.3);
                    }
                }
            }
            Ok(())
        });

        // -- brightness --
        /// Brightness.
        ///
        /// @param factor : number
        /// @return nil
        methods.add_method_mut("brightness", |_, this, factor: f32| {
            this.brightness(factor);
            Ok(())
        });
        // -- contrast --
        /// Contrast.
        ///
        /// @param factor : number
        /// @return nil
        methods.add_method_mut("contrast", |_, this, factor: f32| {
            this.contrast(factor);
            Ok(())
        });
        // -- saturation --
        /// Saturation.
        ///
        /// @param factor : number
        /// @return nil
        methods.add_method_mut("saturation", |_, this, factor: f32| {
            this.saturation(factor);
            Ok(())
        });
        // -- gamma --
        /// Gamma.
        ///
        /// @param gamma : number
        /// @return nil
        methods.add_method_mut("gamma", |_, this, gamma: f32| {
            this.gamma(gamma);
            Ok(())
        });
        // -- tint --
        methods.add_method_mut(
            "tint",
            |_, this, (tr, tg, tb, factor): (u8, u8, u8, f32)| {
                this.tint(tr, tg, tb, factor);
                Ok(())
            },
        );
        // -- grayscale --
        /// Grayscale.
        ///
        /// @return nil
        methods.add_method_mut("grayscale", |_, this, ()| {
            this.grayscale();
            Ok(())
        });
        // -- sepia --
        /// Sepia.
        ///
        /// @return nil
        methods.add_method_mut("sepia", |_, this, ()| {
            this.sepia();
            Ok(())
        });
        // -- invert --
        /// Invert.
        ///
        /// @return nil
        methods.add_method_mut("invert", |_, this, ()| {
            this.invert();
            Ok(())
        });
        // -- threshold --
        /// Threshold.
        ///
        /// @param value : u8
        /// @return nil
        methods.add_method_mut("threshold", |_, this, value: u8| {
            this.threshold(value);
            Ok(())
        });
        // -- posterize --
        /// Posterize.
        ///
        /// @param levels : u8
        /// @return nil
        methods.add_method_mut("posterize", |_, this, levels: u8| {
            this.posterize(levels);
            Ok(())
        });
        // -- fill --
        /// Fill.
        ///
        /// @param r : u8
        /// @param g : u8
        /// @param b : u8
        /// @param a : u8
        /// @return nil
        methods.add_method_mut("fill", |_, this, (r, g, b, a): (u8, u8, u8, u8)| {
            this.fill(r, g, b, a);
            Ok(())
        });
        // -- noise --
        /// Noise.
        ///
        /// @param amount : u8
        /// @return nil
        methods.add_method_mut("noise", |_, this, amount: u8| {
            this.noise(amount);
            Ok(())
        });
        // -- alphaMask --
        /// Alpha mask.
        ///
        /// @param factor : number
        /// @return nil
        methods.add_method_mut("alphaMask", |_, this, factor: f32| {
            this.alpha_mask(factor);
            Ok(())
        });
        // -- flipHorizontal --
        /// Flip horizontal.
        ///
        /// @return nil
        methods.add_method_mut("flipHorizontal", |_, this, ()| {
            this.flip_horizontal();
            Ok(())
        });
        // -- flipVertical --
        /// Flip vertical.
        ///
        /// @return nil
        methods.add_method_mut("flipVertical", |_, this, ()| {
            this.flip_vertical();
            Ok(())
        });
        // -- rotate90cw --
        /// Rotate90cw.
        ///
        /// @return nil
        methods.add_method("rotate90cw", |lua, this, ()| {
            lua.create_userdata(this.rotate_90_cw())
        });
        // -- crop --
        /// Crop.
        ///
        /// @param x : integer
        /// @param y : integer
        /// @param w : integer
        /// @param h : integer
        /// @return nil
        methods.add_method("crop", |lua, this, (x, y, w, h): (u32, u32, u32, u32)| {
            this.crop(x, y, w, h)
                .ok_or_else(|| {
                    LuaError::RuntimeError(format!(
                        "crop ({},{},{},{}) out of bounds ({}x{})",
                        x,
                        y,
                        w,
                        h,
                        this.width(),
                        this.height()
                    ))
                })
                .and_then(|img| lua.create_userdata(img))
        });
        // -- resizeNearest --
        /// Resize nearest.
        ///
        /// @param new_w : integer
        /// @param new_h : integer
        /// @return nil
        methods.add_method("resizeNearest", |lua, this, (new_w, new_h): (u32, u32)| {
            lua.create_userdata(this.resize_nearest(new_w, new_h))
        });
        // -- blur --
        /// Blur.
        ///
        /// @param radius : integer
        /// @return nil
        methods.add_method("blur", |lua, this, radius: u32| {
            lua.create_userdata(this.blur(radius))
        });
        // -- sharpen --
        /// Sharpen.
        ///
        /// @return nil
        methods.add_method("sharpen", |lua, this, ()| {
            lua.create_userdata(this.sharpen())
        });
        // -- drawRect --
        /// Draws a filled rectangle onto the image.
        /// @param x : integer
        /// @param y : integer
        /// @param w : integer
        /// @param h : integer
        /// @param r : integer
        /// @param g : integer
        /// @param b : integer
        /// @param a : integer
        /// @return nil
        methods.add_method_mut(
            "drawRect",
            |_, this, (x, y, w, h, r, g, b, a): (i32, i32, u32, u32, u8, u8, u8, u8)| {
                this.draw_rect(x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        // -- drawCircle --
        /// Draws a filled circle onto the image.
        /// @param cx : integer
        /// @param cy : integer
        /// @param radius : integer
        /// @param r : integer
        /// @param g : integer
        /// @param b : integer
        /// @param a : integer
        /// @return nil
        methods.add_method_mut(
            "drawCircle",
            |_, this, (cx, cy, radius, r, g, b, a): (i32, i32, u32, u8, u8, u8, u8)| {
                this.draw_circle(cx, cy, radius, r, g, b, a);
                Ok(())
            },
        );
        // -- drawLine --
        /// Draws a line using Bresenham's algorithm.
        /// @param x0 : integer
        /// @param y0 : integer
        /// @param x1 : integer
        /// @param y1 : integer
        /// @param r : integer
        /// @param g : integer
        /// @param b : integer
        /// @param a : integer
        /// @return nil
        methods.add_method_mut(
            "drawLine",
            |_, this, (x0, y0, x1, y1, r, g, b, a): (i32, i32, i32, i32, u8, u8, u8, u8)| {
                this.draw_line(x0, y0, x1, y1, r, g, b, a);
                Ok(())
            },
        );

        // -- resize --
        /// Returns a bilinear-interpolated copy of the image at the given dimensions.
        ///
        /// Returns nil if either dimension is zero or the source image is empty.
        ///
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        /// ImageData?
        methods.add_method("resize", |lua, this, (w, h): (u32, u32)| {
            match this.resize(w, h) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- blit --
        /// Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff over.
        ///
        /// Out-of-bounds pixels are silently clipped.
        ///
        /// @param src : ImageData
        /// @param dst_x : integer
        /// @param dst_y : integer
        /// @return nil
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<ImageData>()?;
                this.blit(&src_ref, dst_x, dst_y);
                Ok(())
            },
        );

        // -- getRegion --
        /// Returns a copy of the rectangular sub-region as a new ImageData.
        ///
        /// Returns nil if the region is empty or entirely outside the image.
        ///
        /// @param x : integer
        /// @param y : integer
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        /// ImageData?
        methods.add_method(
            "getRegion",
            |lua, this, (x, y, w, h): (u32, u32, u32, u32)| match this.get_region(x, y, w, h) {
                Some(img) => Ok(LuaValue::UserData(lua.create_userdata(img)?)),
                None => Ok(LuaValue::Nil),
            },
        );

        // -- diff --
        /// Returns the sum of absolute per-channel pixel differences with another ImageData.
        ///
        /// Returns `u32::MAX` when the two images have different dimensions.
        ///
        /// @param other : ImageData
        /// @return integer
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<ImageData>()?;
            Ok(this.diff(&other_ref))
        });

        // -- mapPixels --
        /// Applies a function to every pixel in-place.
        ///
        /// The callback receives `(x, y, r, g, b, a)` (integers 0-255) and must return
        /// `r, g, b, a`. Pixels are visited in row-major order.
        ///
        /// @param fn : function
        /// @return nil
        methods.add_method_mut("mapPixels", |_, this, func: LuaFunction| {
            let w = this.width();
            let h = this.height();
            for y in 0..h {
                for x in 0..w {
                    if let Some((r, g, b, a)) = this.get_pixel(x, y) {
                        let result: (u8, u8, u8, u8) = func.call((x, y, r, g, b, a))?;
                        this.set_pixel(x, y, result.0, result.1, result.2, result.3);
                    }
                }
            }
            Ok(())
        });

        // -- convolve --
        /// Applies a custom NxN convolution kernel to the image and returns a new ImageData.
        ///
        /// `kernel` is a flat table of N*N weights in row-major order.
        /// `ksize` must be odd and satisfy `ksize * ksize == #kernel`.
        /// RGB channels are convolved; alpha is copied unchanged.
        /// Output values are clamped to [0, 255].
        ///
        /// @param kernel : table
        /// @param ksize : integer
        /// @return ImageData
        methods.add_method(
            "convolve",
            |lua, this, (kernel_t, ksize): (LuaTable, usize)| {
                let len = kernel_t.len()? as usize;
                let mut kernel: Vec<f64> = Vec::with_capacity(len);
                for i in 1..=len {
                    kernel.push(kernel_t.get::<_, f64>(i)?);
                }
                let result = this.convolve(&kernel, ksize).map_err(LuaError::external)?;
                lua.create_userdata(result)
            },
        );

        // -- applyPaletteLut --
        /// Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
        ///
        /// @param lut : PaletteLUT
        /// @return nil
        methods.add_method_mut("applyPaletteLut", |_, this, lut_ud: LuaAnyUserData| {
            let lut = lut_ud.borrow::<LuaPaletteLUT>()?;
            lut.inner.apply(this);
            Ok(())
        });

        // -- setRawData --
        /// Replaces all pixel data from a raw RGBA byte string.
        /// The string length must equal `width * height * 4`.
        ///
        /// @param bytes : string
        /// @return nil
        methods.add_method_mut("setRawData", |_, this, bytes: LuaString| {
            this.set_raw_data(bytes.as_bytes())
                .map_err(LuaError::RuntimeError)
        });

        // -- paste --
        /// Copies pixels from `source` onto this image starting at (dx, dy).
        /// Pixels that fall outside the destination bounds are clipped.
        ///
        /// @param source : ImageData
        /// @param dx : integer
        /// @param dy : integer
        /// @return nil
        methods.add_method_mut(
            "paste",
            |_, this, (src_ud, dx, dy): (LuaAnyUserData, u32, u32)| {
                let src = src_ud.borrow::<ImageData>()?;
                this.paste(&src, dx, dy);
                Ok(())
            },
        );
    }
}

// -------------------------------------------------------------------------------
// LuaPaletteLUT UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`PaletteLUT`].
pub struct LuaPaletteLUT {
    inner: crate::image::palette_lut::PaletteLUT,
}

impl LuaUserData for LuaPaletteLUT {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Appends a colour mapping entry to the palette: when a pixel exactly matching
        /// `from_r, from_g, from_b, from_a` (0â€“255) is encountered it is replaced by
        /// `to_r, to_g, to_b, to_a`.
        ///
        /// @param from_r : integer   0-255
        /// @param from_g : integer   0-255
        /// @param from_b : integer   0-255
        /// @param from_a : integer   0-255  (255 = fully opaque)
        /// @param to_r : integer     0-255
        /// @param to_g : integer     0-255
        /// @param to_b : integer     0-255
        /// @param to_a : integer     0-255
        /// @return nil
        methods.add_method_mut(
            "setColor",
            |_, this, (fr, fg, fb, fa, tr, tg, tb, ta): (u8, u8, u8, u8, u8, u8, u8, u8)| {
                use crate::math::color::Color;
                let from = Color {
                    r: fr as f32 / 255.0,
                    g: fg as f32 / 255.0,
                    b: fb as f32 / 255.0,
                    a: fa as f32 / 255.0,
                };
                let to = Color {
                    r: tr as f32 / 255.0,
                    g: tg as f32 / 255.0,
                    b: tb as f32 / 255.0,
                    a: ta as f32 / 255.0,
                };
                let next_idx = this.inner.get_color_count();
                this.inner.set_color(next_idx, from, to);
                Ok(())
            },
        );

        /// Returns the number of colour mapping entries.
        ///
        /// @return integer
        methods.add_method("getColorCount", |_, this, ()| {
            Ok(this.inner.get_color_count())
        });

        /// Removes all colour mapping entries.
        ///
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
    }
}
