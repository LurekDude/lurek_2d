//! Helper types and utilities for the graphics API.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::super::SharedState;
use crate::engine::resource_keys::{
    CanvasKey, FontKey, MeshKey, SpriteBatchKey, TextureKey,
};
use crate::graphics::renderer::DrawCommand;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use slotmap::Key;


/// Lua UserData wrapper for a loaded texture/image resource.
///
/// # Fields
/// - `state` ÔÇö `Rc<RefCell<SharedState>>`.
/// - `key` ÔÇö `TextureKey`.
///
/// Wraps a `TextureKey` and shared state reference so the Lua side
/// can call methods like `img:getWidth()` directly on the object.
#[derive(Clone)]
pub struct LuaImage {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: TextureKey,
}

impl LunaType for LuaImage {
    const TYPE_NAME: &'static str = "Image";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Drawable", "Texture", "Object"];
}

impl LuaUserData for LuaImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the image width in pixels.
        ///
        /// # Returns
        /// `integer` ÔÇö pixel width.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(tex) = st.textures.get(this.key) {
                Ok(tex.width as f32)
            } else {
                Err(LuaError::RuntimeError(
                    "Image handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the image height in pixels.
        ///
        /// # Returns
        /// `integer` ÔÇö pixel height.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(tex) = st.textures.get(this.key) {
                Ok(tex.height as f32)
            } else {
                Err(LuaError::RuntimeError(
                    "Image handle is no longer valid".into(),
                ))
            }
        });

        /// Returns image width and height in pixels.
        ///
        /// # Returns
        /// Two integers `width, height`.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(tex) = st.textures.get(this.key) {
                Ok((tex.width as f32, tex.height as f32))
            } else {
                Err(LuaError::RuntimeError(
                    "Image handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the current min and mag texture filters.
        ///
        /// # Returns
        /// Two strings `min, mag`.
        methods.add_method("getFilter", |_, _this, ()| {
            Ok(("linear".to_string(), "linear".to_string()))
        });

        /// Returns the current texture wrap mode for the horizontal and vertical axes.
        ///
        /// # Returns
        /// Two strings: horizontal wrap and vertical wrap ('clamp', 'repeat', or 'mirror').
        methods.add_method("getWrap", |_, _this, ()| {
            Ok(("clamp".to_string(), "clamp".to_string()))
        });
    }
}

/// Lua UserData wrapper for a nine-slice (9-patch) image definition.
///
/// Stores the source texture key, border insets, and texture dimensions
/// so the engine can draw the image stretched to any size while preserving
/// corner and edge proportions.
#[derive(Clone)]
pub struct LuaNineSlice {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) texture_key: TextureKey,
    pub(crate) top: f32,
    pub(crate) right: f32,
    pub(crate) bottom: f32,
    pub(crate) left: f32,
    pub(crate) tex_width: f32,
    pub(crate) tex_height: f32,
}

impl LunaType for LuaNineSlice {
    const TYPE_NAME: &'static str = "NineSlice";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaNineSlice {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the insets.
        ///
        /// # Returns
        /// The current insets.
        methods.add_method("getInsets", |_, this, ()| {
            Ok((this.top, this.right, this.bottom, this.left))
        });

        /// Returns the texture size.
        ///
        /// # Parameters
        /// - `x` ÔÇö `number`.
        /// - `y` ÔÇö `number`.
        /// - `w` ÔÇö `number`.
        /// - `h` ÔÇö `number`.
        ///
        /// # Returns
        /// The current texture size.
        methods.add_method("getTextureSize", |_, this, ()| {
            Ok((this.tex_width, this.tex_height))
        });

        /// Draws to the current render target.
        ///
        /// # Parameters
        /// - `x` ÔÇö `number`.
        /// - `y` ÔÇö `number`.
        /// - `w` ÔÇö `number`.
        /// - `h` ÔÇö `number`.
        methods.add_method("draw", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            st.draw_commands.push(DrawCommand::DrawNineSlice {
                texture_key: this.texture_key,
                tex_w: this.tex_width,
                tex_h: this.tex_height,
                top: this.top,
                right: this.right,
                bottom: this.bottom,
                left: this.left,
                x,
                y,
                w,
                h,
            });
            Ok(())
        });
    }
}

/// Lua UserData wrapper for a loaded font resource.
///
/// # Fields
/// - `state` ÔÇö `Rc<RefCell<SharedState>>`.
/// - `key` ÔÇö `FontKey`.
///
/// Wraps a `FontKey` and shared state reference so the Lua side
/// can call methods like `font:getHeight()` directly on the object.
#[derive(Clone)]
pub struct LuaFont {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: FontKey,
}

impl LunaType for LuaFont {
    const TYPE_NAME: &'static str = "Font";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaFont {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Measures the rendered width of `text` using this font's current size.
        ///
        /// # Parameters
        /// - `text` ÔÇö `string`: The string to measure.
        ///
        /// # Returns
        /// `number` ÔÇö rendered width in pixels.
        methods.add_method("getWidth", |_, this, text: String| {
            let mut st = this.state.borrow_mut();
            if let Some(font) = st.fonts.get_mut(this.key) {
                Ok(font.text_width(&text))
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the line height of this font at its loaded size, in pixels.
        ///
        /// # Returns
        /// `integer` ÔÇö line height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(font) = st.fonts.get(this.key) {
                Ok(font.line_height())
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the line height in pixels used when advancing to the next line of text.
        ///
        /// # Returns
        /// Line height in pixels.
        methods.add_method("getLineHeight", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(font) = st.fonts.get(this.key) {
                Ok(font.line_height())
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });

        /// Sets the line height multiplier used when laying out multi-line text.
        ///
        /// # Parameters
        /// - `height` ÔÇö Line height factor (1.0 = normal, >1.0 = extra spacing).
        methods.add_method("setLineHeight", |_, this, height: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(font) = st.fonts.get_mut(this.key) {
                font.set_line_height(height);
                Ok(())
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the ascent (distance from baseline to the top of the tallest glyph) in pixels.
        ///
        /// # Returns
        /// `number` ÔÇö ascent in pixels.
        methods.add_method("getAscent", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(font) = st.fonts.get(this.key) {
                Ok(font.ascent())
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the descent (distance below the baseline for descenders) in pixels.
        ///
        /// # Returns
        /// `number` ÔÇö descent in pixels.
        methods.add_method("getDescent", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(font) = st.fonts.get(this.key) {
                Ok(font.descent())
            } else {
                Err(LuaError::RuntimeError(
                    "Font handle is no longer valid".into(),
                ))
            }
        });
    }
}

/// Lua UserData wrapper for a sprite batch resource.
///
/// # Fields
/// - `state` ÔÇö `Rc<RefCell<SharedState>>`.
/// - `key` ÔÇö `SpriteBatchKey`.
///
/// Wraps a `SpriteBatchKey` and shared state reference.
#[derive(Clone)]
pub struct LuaSpriteBatch {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SpriteBatchKey,
}

impl LunaType for LuaSpriteBatch {
    const TYPE_NAME: &'static str = "SpriteBatch";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Drawable", "Object"];
}

impl LuaUserData for LuaSpriteBatch {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the number of sprites currently added to this batch.
        ///
        /// # Returns
        /// Current sprite count as an integer.
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(batch) = st.sprite_batches.get(this.key) {
                Ok(batch.len())
            } else {
                Err(LuaError::RuntimeError(
                    "SpriteBatch handle is no longer valid".into(),
                ))
            }
        });

        /// Removes all sprites from this batch and resets the sprite count to zero.
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(batch) = st.sprite_batches.get_mut(this.key) {
                batch.clear();
                Ok(())
            } else {
                Err(LuaError::RuntimeError(
                    "SpriteBatch handle is no longer valid".into(),
                ))
            }
        });

        #[allow(clippy::type_complexity)]
        methods.add_method(
            "add",
            |_,
             this,
             (x, y, r, sx, sy, ox, oy, qx, qy, qw, qh): (
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let mut st = this.state.borrow_mut();
                let batch = st.sprite_batches.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("SpriteBatch handle is no longer valid".into())
                })?;
                let entry = crate::graphics::sprite_batch::BatchEntry {
                    x,
                    y,
                    quad_x: qx.unwrap_or(0.0),
                    quad_y: qy.unwrap_or(0.0),
                    quad_w: qw.unwrap_or(0.0),
                    quad_h: qh.unwrap_or(0.0),
                    rotation: r.unwrap_or(0.0),
                    sx: sx.unwrap_or(1.0),
                    sy: sy.unwrap_or(sx.unwrap_or(1.0)),
                    ox: ox.unwrap_or(0.0),
                    oy: oy.unwrap_or(0.0),
                };
                match batch.add(entry) {
                    Some(idx) => Ok(idx),
                    None => Err(LuaError::RuntimeError("SpriteBatch is full".into())),
                }
            },
        );

        /// Returns the maximum number of sprites this batch was allocated to hold.
        ///
        /// # Returns
        /// Buffer capacity as an integer.
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(batch) = st.sprite_batches.get(this.key) {
                Ok(batch.buffer_size())
            } else {
                Err(LuaError::RuntimeError(
                    "SpriteBatch handle is no longer valid".into(),
                ))
            }
        });
    }
}

/// Lua UserData wrapper for an off-screen canvas resource.
///
/// # Fields
/// - `state` ÔÇö `Rc<RefCell<SharedState>>`.
/// - `key` ÔÇö `CanvasKey`.
#[derive(Clone)]
pub struct LuaCanvas {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: CanvasKey,
}

impl LunaType for LuaCanvas {
    const TYPE_NAME: &'static str = "Canvas";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Drawable", "Texture", "Object"];
}

impl LuaUserData for LuaCanvas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the canvas width in pixels.
        ///
        /// # Returns
        /// `integer` ÔÇö pixel width.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(canvas) = st.canvases.get(this.key) {
                Ok(canvas.width as f32)
            } else {
                Err(LuaError::RuntimeError(
                    "Canvas handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the canvas height in pixels.
        ///
        /// # Returns
        /// `integer` ÔÇö pixel height.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(canvas) = st.canvases.get(this.key) {
                Ok(canvas.height as f32)
            } else {
                Err(LuaError::RuntimeError(
                    "Canvas handle is no longer valid".into(),
                ))
            }
        });

        /// Returns the canvas width and height in pixels.
        ///
        /// # Returns
        /// Two integers `width, height`.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(canvas) = st.canvases.get(this.key) {
                Ok((canvas.width as f32, canvas.height as f32))
            } else {
                Err(LuaError::RuntimeError(
                    "Canvas handle is no longer valid".into(),
                ))
            }
        });
    }
}

/// Extract a `TextureKey` from either a `LuaImage` UserData or a numeric ID.
pub(super) fn texture_key_from_value(val: &LuaValue) -> LuaResult<TextureKey> {
    match val {
        LuaValue::UserData(ud) => {
            let img = ud.borrow::<LuaImage>()?;
            Ok(img.key)
        }
        LuaValue::Integer(id) => Ok(TextureKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(TextureKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError("Expected Image or image id".into())),
    }
}

/// Extract a `FontKey` from either a `LuaFont` UserData or a numeric ID.
pub(super) fn font_key_from_value(val: &LuaValue) -> LuaResult<FontKey> {
    match val {
        LuaValue::UserData(ud) => {
            let font = ud.borrow::<LuaFont>()?;
            Ok(font.key)
        }
        LuaValue::Integer(id) => Ok(FontKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(FontKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError("Expected Font or font id".into())),
    }
}

/// Extract a `SpriteBatchKey` from either a `LuaSpriteBatch` UserData or a numeric ID.
pub(super) fn batch_key_from_value(val: &LuaValue) -> LuaResult<SpriteBatchKey> {
    match val {
        LuaValue::UserData(ud) => {
            let batch = ud.borrow::<LuaSpriteBatch>()?;
            Ok(batch.key)
        }
        LuaValue::Integer(id) => Ok(SpriteBatchKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(SpriteBatchKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError(
            "Expected SpriteBatch or batch id".into(),
        )),
    }
}

/// Extract a `CanvasKey` from either a `LuaCanvas` UserData or a numeric ID.
pub(super) fn canvas_key_from_value(val: &LuaValue) -> LuaResult<CanvasKey> {
    match val {
        LuaValue::UserData(ud) => {
            let canvas = ud.borrow::<LuaCanvas>()?;
            Ok(canvas.key)
        }
        LuaValue::Integer(id) => Ok(CanvasKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(CanvasKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError(
            "Expected Canvas or canvas id".into(),
        )),
    }
}

pub(super) fn invalid_texture_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released texture handle",
        function_name
    ))
}

pub(super) fn invalid_font_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released font handle",
        function_name
    ))
}

pub(super) fn invalid_batch_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released sprite batch handle",
        function_name
    ))
}

pub(super) fn invalid_canvas_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released canvas handle",
        function_name
    ))
}

pub(super) fn invalid_mesh_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released mesh handle",
        function_name
    ))
}

pub(super) fn require_texture_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<TextureKey> {
    let key = texture_key_from_value(val)?;
    match val {
        LuaValue::Integer(_) | LuaValue::Number(_) => {
            if state.textures.contains_key(key) {
                Ok(key)
            } else if state
                .released_texture_handles
                .contains(&key.data().as_ffi())
            {
                Err(invalid_texture_handle(function_name))
            } else {
                Ok(key)
            }
        }
        _ => {
            if !state.textures.contains_key(key) {
                Err(invalid_texture_handle(function_name))
            } else {
                Ok(key)
            }
        }
    }
}

pub(super) fn require_font_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<FontKey> {
    let key = font_key_from_value(val)?;
    if !state.fonts.contains_key(key) {
        Err(invalid_font_handle(function_name))
    } else {
        Ok(key)
    }
}

pub(super) fn require_batch_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<SpriteBatchKey> {
    let key = batch_key_from_value(val)?;
    if !state.sprite_batches.contains_key(key) {
        Err(invalid_batch_handle(function_name))
    } else {
        Ok(key)
    }
}

pub(super) fn require_canvas_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<CanvasKey> {
    let key = canvas_key_from_value(val)?;
    if !state.canvases.contains_key(key) {
        Err(invalid_canvas_handle(function_name))
    } else {
        Ok(key)
    }
}

pub(super) fn require_mesh_key(state: &SharedState, id: u64, function_name: &str) -> LuaResult<MeshKey> {
    let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
    if !state.meshes.contains_key(key) {
        Err(invalid_mesh_handle(function_name))
    } else {
        Ok(key)
    }
}
