//! Lua API bindings for the `luna.font.*` font rasterizer module.
//!
//! Provides `newRasterizer`, `newTrueTypeRasterizer`, `newBMFontRasterizer`,
//! and `newGlyphData` factory functions matching the LÖVE2D `love.font` module
//! surface.  Font loading delegates to the same `Font::from_bytes` path used by
//! `luna.graphics.newFont` so the returned `LuaFont` userdata is fully
//! compatible with all existing graphics API functions.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::graphics_api::{font_key_from_value, LuaFont};
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::lua_api::SharedState;

// ---------------------------------------------------------------------------
// GlyphData userdata
// ---------------------------------------------------------------------------

/// Glyph metrics returned by `luna.font.newGlyphData`.
///
/// Stores the pixel dimensions, advance width, and bearing offsets for a
/// single Unicode code point in the source font.
///
/// # Fields
/// - `width` — Pixel width of the rasterized glyph bitmap.
/// - `height` — Pixel height of the rasterized glyph bitmap.
/// - `advance` — Horizontal advance (cursor movement after this glyph).
/// - `bearing_x` — Horizontal bearing (offset from cursor to left edge).
/// - `bearing_y` — Vertical bearing (offset from baseline to top edge).
/// - `glyph` — Unicode code point as a Lua integer.
/// - `glyph_string` — Single UTF-8 character string.
#[derive(Clone)]
pub struct GlyphData {
    /// Pixel width of the rasterized glyph bitmap.
    pub width: u32,
    /// Pixel height of the rasterized glyph bitmap.
    pub height: u32,
    /// Horizontal advance in pixels.
    pub advance: f32,
    /// Horizontal bearing offset (cursor → left edge of glyph).
    pub bearing_x: f32,
    /// Vertical bearing offset (baseline → top edge of glyph).
    pub bearing_y: f32,
    /// Unicode code point.
    pub glyph: u32,
    /// Single-character UTF-8 string representation of `glyph`.
    pub glyph_string: String,
}

impl LunaType for GlyphData {
    const TYPE_NAME: &'static str = "GlyphData";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Data", "Object"];
}

impl LuaUserData for GlyphData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the pixel width of the glyph bitmap.
        ///
        /// # Returns
        /// `integer`
        methods.add_method("getWidth", |_, this, ()| Ok(this.width));

        /// Returns the pixel height of the glyph bitmap.
        ///
        /// # Returns
        /// `integer`
        methods.add_method("getHeight", |_, this, ()| Ok(this.height));

        /// Returns the horizontal advance width in pixels.
        ///
        /// # Returns
        /// `number`
        methods.add_method("getAdvance", |_, this, ()| Ok(this.advance));

        /// Returns the horizontal bearing (cursor-to-glyph-edge offset).
        ///
        /// # Returns
        /// `number`
        methods.add_method("getBearingX", |_, this, ()| Ok(this.bearing_x));

        /// Returns the vertical bearing (baseline-to-glyph-top offset).
        ///
        /// # Returns
        /// `number`
        methods.add_method("getBearingY", |_, this, ()| Ok(this.bearing_y));

        /// Returns the Unicode code point as an integer.
        ///
        /// # Returns
        /// `integer`
        methods.add_method("getGlyph", |_, this, ()| Ok(this.glyph));

        /// Returns the glyph character as a UTF-8 string.
        ///
        /// # Returns
        /// `string`
        methods.add_method("getGlyphString", |_, this, ()| {
            Ok(this.glyph_string.clone())
        });
    }
}

// ---------------------------------------------------------------------------
// Helper: load a font the same way luna.graphics.newFont does
// ---------------------------------------------------------------------------

/// Shared font-loading implementation used by all `luna.font` rasterizer
/// factory functions.  Reads `path` relative to `game_dir`, parses it with
/// `Font::from_bytes`, inserts it into the slot map, and returns a `LuaFont`
/// userdata.
///
/// # Parameters
/// - `state` — `&Rc<RefCell<SharedState>>`.
/// - `path` — `&str`.
/// - `size` — `f32`.
///
/// # Returns
/// `LuaResult<LuaFont>`.
fn load_font(
    state: &Rc<RefCell<SharedState>>,
    path: &str,
    size: f32,
) -> LuaResult<LuaFont> {
    let mut st = state.borrow_mut();
    let full_path = st.game_dir.join(path);
    let data = std::fs::read(&full_path).map_err(|e| {
        LuaError::RuntimeError(format!(
            "luna.font: failed to read '{}': {}",
            path, e
        ))
    })?;
    let font = crate::graphics::Font::from_bytes(&data, size)
        .map_err(|e| LuaError::RuntimeError(format!("luna.font: {}", e)))?;
    let key = st.fonts.insert(font);
    Ok(LuaFont {
        state: state.clone(),
        key,
    })
}

// ---------------------------------------------------------------------------
// register()
// ---------------------------------------------------------------------------

/// Registers the `luna.font.*` API onto the `luna` global table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let font_table = lua.create_table()?;

    // luna.font.newRasterizer(source, size?) -> LuaFont
    /// Loads a TTF/OTF font file and returns a font userdata object.
    ///
    /// This is an alias for `luna.graphics.newFont` exposed on the `luna.font`
    /// module for LÖVE2D compatibility.
    let state_cl = state.clone();
    font_table.set(
        "newRasterizer",
        lua.create_function(move |_, (path, size): (String, Option<f32>)| {
            load_font(&state_cl, &path, size.unwrap_or(14.0))
        })?,
    )?;

    // luna.font.newTrueTypeRasterizer(source, size, hinting?) -> LuaFont
    /// Loads a TTF/OTF font with an optional hinting hint (currently ignored).
    ///
    /// The `hinting` parameter is accepted for API compatibility but has no
    /// effect — fontdue uses its own hinting strategy internally.
    let state_cl = state.clone();
    font_table.set(
        "newTrueTypeRasterizer",
        lua.create_function(
            move |_, (path, size, _hinting): (String, Option<f32>, Option<String>)| {
                load_font(&state_cl, &path, size.unwrap_or(14.0))
            },
        )?,
    )?;

    // luna.font.newBMFontRasterizer(image_file, glyph_hints) -> error
    /// Stub: BMFont rasterization is not yet supported.
    ///
    /// Raises a descriptive Lua error so scripts fail fast with a clear
    /// message rather than a cryptic nil-dereference.
    font_table.set(
        "newBMFontRasterizer",
        lua.create_function(
            move |_, (_image_file, _glyph_hints): (LuaValue, LuaValue)| {
                Err::<(), _>(LuaError::RuntimeError(
                    "luna.font.newBMFontRasterizer: BMFont is not yet supported".to_string(),
                ))
            },
        )?,
    )?;

    // luna.font.newGlyphData(font, codepoint) -> GlyphData
    /// Returns glyph metrics for a given Unicode code point within the font.
    ///
    /// `font` may be a `LuaFont` userdata or a raw font ID integer.
    /// `codepoint` is a Unicode integer (e.g. `string.byte("A")` = 65).
    let state_cl = state.clone();
    font_table.set(
        "newGlyphData",
        lua.create_function(move |_, (font_val, codepoint): (LuaValue, u32)| {
            let key = font_key_from_value(&font_val)?;
            let ch = char::from_u32(codepoint).ok_or_else(|| {
                LuaError::RuntimeError(format!(
                    "luna.font.newGlyphData: invalid Unicode codepoint {}",
                    codepoint
                ))
            })?;
            let mut st = state_cl.borrow_mut();
            let font = st.fonts.get_mut(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.font.newGlyphData: font handle is not valid or was released".to_string(),
                )
            })?;
            // Ensure the glyph is rasterized so we can read its metrics.
            font.ensure_glyph(ch);
            let info = font.glyph(ch).cloned();
            drop(st);
            match info {
                Some(g) => Ok(GlyphData {
                    width: g.width,
                    height: g.height,
                    advance: g.advance_width,
                    bearing_x: g.offset_x,
                    bearing_y: g.offset_y,
                    glyph: codepoint,
                    glyph_string: ch.to_string(),
                }),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.font.newGlyphData: failed to rasterize codepoint {}",
                    codepoint
                ))),
            }
        })?,
    )?;

    luna.set("font", font_table)?;
    Ok(())
}
