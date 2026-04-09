//! CPU-side RGBA8 pixel buffer for image manipulation.
//!
//! This module is part of Lurek2D's `image` subsystem and provides the implementation
//! details for image data-related operations and data management.
//! Key types exported from this module: `ImageData`.
//! Primary functions: `new()`, `from_file()`, `from_bytes()`, `width()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::log_messages::{IM01_IMAGE_LOADED, IM02_IMAGE_MISMATCH};
use crate::log_msg;
use mlua::prelude::*;

/// CPU-side pixel buffer in RGBA8 format. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Stores pixel data in row-major order, 4 bytes per pixel (R, G, B, A).
/// Can be created empty, from a file, or from raw bytes.
///
/// # Fields
/// - `width` — `u32`. Image width in pixels.
/// - `height` — `u32`. Image height in pixels.
/// - `pixels` — `Vec<u8>`. Raw RGBA8 pixel data in row-major order (4 bytes per pixel).
#[derive(Debug, Clone)]
pub struct ImageData {
    /// Image width in pixels.
    pub(super) width: u32,
    /// Image height in pixels.
    pub(super) height: u32,
    /// Raw RGBA8 pixel data in row-major order (4 bytes per pixel).
    pub(super) pixels: Vec<u8>,
}

impl ImageData {
    /// Create a new blank (transparent black) image.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            pixels: vec![0; (width * height * 4) as usize],
        }
    }

    /// Load an image from a file path. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn from_file(path: &str) -> Result<Self, String> {
        let img =
            ::image::open(path).map_err(|e| format!("Failed to load image '{}': {}", path, e))?;
        let rgba = img.to_rgba8();
        let (w, h) = rgba.dimensions();
        log_msg!(debug, IM01_IMAGE_LOADED, "{}x{}", w, h);
        Ok(Self {
            width: w,
            height: h,
            pixels: rgba.into_raw(),
        })
    }

    /// Create from raw RGBA bytes. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `bytes` — `Vec<u8>`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
    pub fn from_bytes(width: u32, height: u32, bytes: Vec<u8>) -> Result<Self, String> {
        let expected = (width * height * 4) as usize;
        if bytes.len() != expected {
            log_msg!(
                error,
                IM02_IMAGE_MISMATCH,
                "expected {} got {}",
                expected,
                bytes.len()
            );
            return Err(format!(
                "Expected {} bytes for {}x{} RGBA image, got {}",
                expected,
                width,
                height,
                bytes.len()
            ));
        }
        Ok(Self {
            width,
            height,
            pixels: bytes,
        })
    }

    /// Get the width of the image. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Get the height of the image. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Get both dimensions. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Get the RGBA values of a pixel at (x, y). Values are 0-255.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Option<(u8, u8, u8, u8)>`.
    pub fn get_pixel(&self, x: u32, y: u32) -> Option<(u8, u8, u8, u8)> {
        if x >= self.width || y >= self.height {
            return None;
        }
        let idx = ((y * self.width + x) * 4) as usize;
        Some((
            self.pixels[idx],
            self.pixels[idx + 1],
            self.pixels[idx + 2],
            self.pixels[idx + 3],
        ))
    }

    /// Set the RGBA values of a pixel at (x, y). Values are 0-255.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `r` — `u8`.
    /// - `g` — `u8`.
    /// - `b` — `u8`.
    /// - `a` — `u8`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_pixel(&mut self, x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) -> bool {
        if x >= self.width || y >= self.height {
            return false;
        }
        let idx = ((y * self.width + x) * 4) as usize;
        self.pixels[idx] = r;
        self.pixels[idx + 1] = g;
        self.pixels[idx + 2] = b;
        self.pixels[idx + 3] = a;
        true
    }

    /// Paste source image onto self at position (dx, dy).
    ///
    /// # Parameters
    /// - `source` — `&ImageData`.
    /// - `dx` — `u32`.
    /// - `dy` — `u32`.
    pub fn paste(&mut self, source: &ImageData, dx: u32, dy: u32) {
        for sy in 0..source.height {
            for sx in 0..source.width {
                let tx = dx + sx;
                let ty = dy + sy;
                if tx < self.width && ty < self.height {
                    if let Some((r, g, b, a)) = source.get_pixel(sx, sy) {
                        self.set_pixel(tx, ty, r, g, b, a);
                    }
                }
            }
        }
    }

    /// Apply a function to every pixel, replacing each (r,g,b,a) with the return value.
    ///
    /// # Parameters
    /// - `f` — `F`.
    ///
    /// # Returns
    /// `(u8, u8, u8, u8),`.
    ///
    /// The function receives `(x, y, r, g, b, a)` and returns `(r, g, b, a)`.
    pub fn map_pixel<F>(&mut self, f: F)
    where
        F: Fn(u32, u32, u8, u8, u8, u8) -> (u8, u8, u8, u8),
    {
        for y in 0..self.height {
            for x in 0..self.width {
                let idx = ((y * self.width + x) * 4) as usize;
                let r = self.pixels[idx];
                let g = self.pixels[idx + 1];
                let b = self.pixels[idx + 2];
                let a = self.pixels[idx + 3];
                let (nr, ng, nb, na) = f(x, y, r, g, b, a);
                self.pixels[idx] = nr;
                self.pixels[idx + 1] = ng;
                self.pixels[idx + 2] = nb;
                self.pixels[idx + 3] = na;
            }
        }
    }

    /// Encode the image as PNG bytes. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `Result<Vec<u8>, String>`.
    pub fn encode_png(&self) -> Result<Vec<u8>, String> {
        let img: ::image::ImageBuffer<::image::Rgba<u8>, Vec<u8>> =
            ::image::ImageBuffer::from_raw(self.width, self.height, self.pixels.clone())
                .ok_or_else(|| "Failed to create image buffer".to_string())?;
        let dynamic = ::image::DynamicImage::ImageRgba8(img);
        let mut buf = Vec::new();
        let mut cursor = std::io::Cursor::new(&mut buf);
        dynamic
            .write_to(&mut cursor, ::image::ImageOutputFormat::Png)
            .map_err(|e| format!("PNG encode error: {}", e))?;
        Ok(buf)
    }

    /// Get a reference to the raw pixel bytes.
    ///
    /// # Returns
    /// `&[u8]`.
    pub fn as_bytes(&self) -> &[u8] {
        &self.pixels
    }

    /// Get the raw pixel bytes as a vector (for Lua getString() compatibility).
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn get_string(&self) -> Vec<u8> {
        self.pixels.clone()
    }
}

impl mlua::UserData for ImageData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.width()));
        methods.add_method("getHeight", |_, this, ()| Ok(this.height()));
        methods.add_method("getDimensions", |_, this, ()| {
            let (w, h) = this.dimensions();
            Ok((w, h))
        });
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
        methods.add_method("encode", |_, this, format: String| match format.as_str() {
            "png" => this.encode_png().map_err(LuaError::RuntimeError),
            _ => Err(LuaError::RuntimeError(format!(
                "Unknown image format: '{}'. Use 'png'.",
                format
            ))),
        });
        methods.add_method("getString", |_, this, ()| Ok(this.get_string()));

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
        methods.add_method_mut("brightness", |_, this, factor: f32| {
            this.brightness(factor);
            Ok(())
        });
        // -- contrast --
        methods.add_method_mut("contrast", |_, this, factor: f32| {
            this.contrast(factor);
            Ok(())
        });
        // -- saturation --
        methods.add_method_mut("saturation", |_, this, factor: f32| {
            this.saturation(factor);
            Ok(())
        });
        // -- gamma --
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
        methods.add_method_mut("grayscale", |_, this, ()| {
            this.grayscale();
            Ok(())
        });
        // -- sepia --
        methods.add_method_mut("sepia", |_, this, ()| {
            this.sepia();
            Ok(())
        });
        // -- invert --
        methods.add_method_mut("invert", |_, this, ()| {
            this.invert();
            Ok(())
        });
        // -- threshold --
        methods.add_method_mut("threshold", |_, this, value: u8| {
            this.threshold(value);
            Ok(())
        });
        // -- posterize --
        methods.add_method_mut("posterize", |_, this, levels: u8| {
            this.posterize(levels);
            Ok(())
        });
        // -- fill --
        methods.add_method_mut("fill", |_, this, (r, g, b, a): (u8, u8, u8, u8)| {
            this.fill(r, g, b, a);
            Ok(())
        });
        // -- noise --
        methods.add_method_mut("noise", |_, this, amount: u8| {
            this.noise(amount);
            Ok(())
        });
        // -- alphaMask --
        methods.add_method_mut("alphaMask", |_, this, factor: f32| {
            this.alpha_mask(factor);
            Ok(())
        });
        // -- flipHorizontal --
        methods.add_method_mut("flipHorizontal", |_, this, ()| {
            this.flip_horizontal();
            Ok(())
        });
        // -- flipVertical --
        methods.add_method_mut("flipVertical", |_, this, ()| {
            this.flip_vertical();
            Ok(())
        });
        // -- rotate90cw --
        methods.add_method("rotate90cw", |lua, this, ()| {
            lua.create_userdata(this.rotate_90_cw())
        });
        // -- crop --
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
        methods.add_method("resizeNearest", |lua, this, (new_w, new_h): (u32, u32)| {
            lua.create_userdata(this.resize_nearest(new_w, new_h))
        });
        // -- blur --
        methods.add_method("blur", |lua, this, radius: u32| {
            lua.create_userdata(this.blur(radius))
        });
        // -- sharpen --
        methods.add_method("sharpen", |lua, this, ()| {
            lua.create_userdata(this.sharpen())
        });
    }
}
