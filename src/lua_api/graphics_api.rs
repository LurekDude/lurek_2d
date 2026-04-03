//! Registers the `luna.graphics.*` graphics API.
//!

use std::cell::RefCell;
use std::rc::Rc;
use crate::lua_api::SharedState;
use crate::graphics::renderer::{BlendMode, CompareMode, DepthMode, DrawCommand, DrawMode, StencilAction, StencilMode, TextAlign};
use crate::graphics::texture::Texture;
use slotmap::Key;
use crate::engine::resource_keys::{CanvasKey, FontKey, MeshKey, SpriteBatchKey, TextureKey, ShaderKey};
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::graphics::mesh::{Mesh, MeshDrawMode, MeshVertex};
use crate::graphics::shader::{Shader, UniformValue};
use mlua::prelude::*;

// ── Helper types ──────────────────────────────────────────────────────────
/// Lua UserData wrapper for a loaded texture resource.
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `key` — `TextureKey`.
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
///
/// # Fields
/// - `state` — `Rc<RefCell<SharedState>>`.
/// - `texture_key` — `TextureKey`.
/// - `top` — `f32`.
/// - `right` — `f32`.
/// - `bottom` — `f32`.
/// - `left` — `f32`.
/// - `tex_width` — `f32`.
/// - `tex_height` — `f32`.
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
///
/// # Parameters
/// - `val` — `&LuaValue`.
///
/// # Returns
/// `LuaResult<TextureKey>`.
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
///
/// # Parameters
/// - `val` — `&LuaValue`.
///
/// # Returns
/// `LuaResult<FontKey>`.
pub(crate) fn font_key_from_value(val: &LuaValue) -> LuaResult<FontKey> {
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
///
/// # Parameters
/// - `val` — `&LuaValue`.
///
/// # Returns
/// `LuaResult<SpriteBatchKey>`.
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
///
/// # Parameters
/// - `val` — `&LuaValue`.
///
/// # Returns
/// `LuaResult<CanvasKey>`.
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

/// Returns a `LuaError` for an invalid or released texture handle.
///
/// # Parameters
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaError`.
pub(super) fn invalid_texture_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released texture handle",
        function_name
    ))
}

/// Returns a `LuaError` for an invalid or released font handle.
///
/// # Parameters
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaError`.
pub(super) fn invalid_font_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released font handle",
        function_name
    ))
}

/// Returns a `LuaError` for an invalid or released sprite batch handle.
///
/// # Parameters
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaError`.
pub(super) fn invalid_batch_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released sprite batch handle",
        function_name
    ))
}

/// Returns a `LuaError` for an invalid or released canvas handle.
///
/// # Parameters
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaError`.
pub(super) fn invalid_canvas_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released canvas handle",
        function_name
    ))
}

/// Returns a `LuaError` for an invalid or released mesh handle.
///
/// # Parameters
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaError`.
pub(super) fn invalid_mesh_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released mesh handle",
        function_name
    ))
}

/// Resolves a texture key, validating the handle is still alive.
///
/// # Parameters
/// - `state` — `&SharedState`.
/// - `val` — `&LuaValue`.
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaResult<TextureKey>`.
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

/// Resolves a font key and validates the font is still loaded.
///
/// # Parameters
/// - `state` — `&SharedState`.
/// - `val` — `&LuaValue`.
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaResult<FontKey>`.
pub(crate) fn require_font_key(
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

/// Resolves a sprite-batch key and validates the batch is still alive.
///
/// # Parameters
/// - `state` — `&SharedState`.
/// - `val` — `&LuaValue`.
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaResult<SpriteBatchKey>`.
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

/// Resolves a canvas key and validates the canvas is still alive.
///
/// # Parameters
/// - `state` — `&SharedState`.
/// - `val` — `&LuaValue`.
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaResult<CanvasKey>`.
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

/// Resolves a mesh key and validates the mesh is still alive.
///
/// # Parameters
/// - `state` — `&SharedState`.
/// - `id` — `u64`.
/// - `function_name` — `&str`.
///
/// # Returns
/// `LuaResult<MeshKey>`.
pub(super) fn require_mesh_key(state: &SharedState, id: u64, function_name: &str) -> LuaResult<MeshKey> {
    let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
    if !state.meshes.contains_key(key) {
        Err(invalid_mesh_handle(function_name))
    } else {
        Ok(key)
    }
}


// ── Extended registrations (second half) ──────────────────────────────────
fn register_ext(
    lua: &Lua,
    graphics: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    // ÔöÇÔöÇ Sprite batch API ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Creates a new SpriteBatch for efficiently drawing many sprites sharing one texture.
    ///
    /// # Parameters
    /// - `texture` ÔÇö Texture ID that all sprites in this batch must share.
    /// - `maxSprites` ÔÇö Maximum number of sprites the batch can hold.
    ///
    /// # Returns
    /// New SpriteBatch ID.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.newSpriteBatch(image_id, max_sprites?)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.newSpriteBatch(image_id, max_sprites?)
    // luna.graphics.newSpriteBatch(image_id, max_sprites?) -> batch_id
    let s = state.clone();
    graphics.set(
        "newSpriteBatch",
        lua.create_function(
            move |_, (image_val, max_sprites): (LuaValue, Option<usize>)| {
                let tex_key = texture_key_from_value(&image_val)?;
                let mut st = s.borrow_mut();
                if !st.textures.contains_key(tex_key) {
                    return Err(LuaError::RuntimeError(
                        "luna.graphics.newSpriteBatch: texture handle is not valid or was released"
                            .into(),
                    ));
                }
                let max = max_sprites.unwrap_or(0);
                let batch = crate::graphics::SpriteBatch::new(tex_key, max);
                let key = st.sprite_batches.insert(batch);
                Ok(LuaSpriteBatch {
                    state: s.clone(),
                    key,
                })
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Appends a new sprite to the batch with the given position and transform properties.
    ///
    /// # Parameters
    /// - `batch` ÔÇö SpriteBatch ID.
    /// - `x` ÔÇö Sprite X position in pixels.
    /// - `y` ÔÇö Sprite Y position in pixels.
    /// - `angle` ÔÇö Optional rotation in radians.
    /// - `sx`, `sy` ÔÇö Optional scale factors.
    /// - `ox`, `oy` ÔÇö Optional origin offsets.
    ///
    /// # Returns
    /// Index of the newly appended sprite within the batch.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.spriteBatchAdd(batch_id, x, y, r?, sx?, sy?, ox?, oy?, quad_x?, quad_y?, quad_w?, quad_h?)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.spriteBatchAdd(batch_id, x, y, r?, sx?, sy?, ox?, oy?, quad_x?, quad_y?, quad_w?, quad_h?)
    // luna.graphics.spriteBatchAdd(batch_id, x, y, r?, sx?, sy?, ox?, oy?, quad_x?, quad_y?, quad_w?, quad_h?) -> index
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "spriteBatchAdd",
        lua.create_function(
            move |_,
                  args: (
                LuaValue,
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
                let (batch_val, x, y, r, sx, sy, ox, oy, qx, qy, qw, qh) = args;
                let batch_key = batch_key_from_value(&batch_val)?;
                let mut st = s.borrow_mut();
                let batch = st.sprite_batches.get_mut(batch_key).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "luna.graphics.spriteBatchAdd: batch handle is not valid or was released"
                            .into(),
                    )
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
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Removes all sprites from the batch, resetting its count to zero.
    ///
    /// # Parameters
    /// - `batch` ÔÇö SpriteBatch ID to clear.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.spriteBatchClear(batch_id)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.spriteBatchClear(batch_id)
    // luna.graphics.spriteBatchClear(batch_id)
    let s = state.clone();
    graphics.set(
        "spriteBatchClear",
        lua.create_function(move |_, batch_val: LuaValue| {
            let batch_key = batch_key_from_value(&batch_val)?;
            let mut st = s.borrow_mut();
            let batch = st.sprite_batches.get_mut(batch_key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.spriteBatchClear: batch handle is not valid or was released"
                        .into(),
                )
            })?;
            batch.clear();
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws all sprites in a SpriteBatch using a single efficient GPU draw call.
    ///
    /// # Parameters
    /// - `batch` ÔÇö SpriteBatch ID returned by newSpriteBatch.
    /// - `x` ÔÇö Optional X offset in pixels.
    /// - `y` ÔÇö Optional Y offset in pixels.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.drawBatch(batch_id)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.drawBatch(batch_id)
    // luna.graphics.drawBatch(batch_id)
    let s = state.clone();
    graphics.set(
        "drawBatch",
        lua.create_function(move |_, batch_val: LuaValue| {
            let mut st = s.borrow_mut();
            let batch_key = require_batch_key(&st, &batch_val, "luna.graphics.drawBatch")?;
            st.draw_commands.push(DrawCommand::DrawBatch { batch_key });
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Blend modes ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Sets the blend equation used when drawing new pixels over the existing framebuffer.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Blend mode string: 'alpha', 'additive', 'multiply', 'none', etc.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.setBlendMode(mode)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.setBlendMode(mode)
    // luna.graphics.setBlendMode(mode)
    let s = state.clone();
    graphics.set(
        "setBlendMode",
        lua.create_function(move |_, mode: String| {
            let blend_mode = match mode.as_str() {
                "alpha" => BlendMode::Alpha,
                "add" | "additive" => BlendMode::Add,
                "multiply" => BlendMode::Multiply,
                "replace" => BlendMode::Replace,
                "screen" => BlendMode::Screen,
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "Unknown blend mode: {}",
                        mode
                    )))
                }
            };
            let mut st = s.borrow_mut();
            st.blend_mode = blend_mode;
            st.draw_commands.push(DrawCommand::SetBlendMode(blend_mode));
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the name of the currently active blend mode.
    ///
    /// # Returns
    /// Blend mode string such as 'alpha', 'additive', or 'multiply'.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getBlendMode()
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getBlendMode()
    // luna.graphics.getBlendMode() -> string
    let s = state.clone();
    graphics.set(
        "getBlendMode",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let mode = match st.blend_mode {
                BlendMode::Alpha => "alpha",
                BlendMode::Add => "add",
                BlendMode::Multiply => "multiply",
                BlendMode::Replace => "replace",
                BlendMode::Screen => "screen",
            };
            Ok(mode.to_string())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Sets the camera transform: position, rotation, and zoom applied to all draw calls.
    ///
    /// # Parameters
    /// - `x` ÔÇö Camera center X in world units.
    /// - `y` ÔÇö Camera center Y in world units.
    /// - `angle` ÔÇö Optional camera rotation angle in radians.
    /// - `zoom` ÔÇö Optional zoom scale (1.0 = no zoom).
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.setCamera(x, y, zoom?, rotation?)
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.setCamera(x, y, zoom?, rotation?)
    // luna.graphics.setCamera(x, y, zoom?, rotation?)
    let s = state.clone();
    graphics.set(
        "setCamera",
        lua.create_function(
            move |_, (x, y, zoom, rotation): (f32, f32, Option<f32>, Option<f32>)| {
                let mut st = s.borrow_mut();
                st.camera.set_position(crate::math::Vec2::new(x, y));
                if let Some(z) = zoom {
                    st.camera.set_zoom(z);
                }
                if let Some(r) = rotation {
                    st.camera.set_rotation(r);
                }
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the current world-space camera translate offset (cx, cy).
    ///
    /// # Returns
    /// Camera X and Y position in world units.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraPosition()
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraPosition()
    // luna.graphics.getCameraPosition() -> x, y
    let s = state.clone();
    graphics.set(
        "getCameraPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.camera.position.x, st.camera.position.y))
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the current camera zoom (scale) factor applied to the world.
    ///
    /// # Returns
    /// Zoom scale as a number (1.0 = no zoom).
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraZoom()
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraZoom()
    // luna.graphics.getCameraZoom() -> zoom
    let s = state.clone();
    graphics.set(
        "getCameraZoom",
        lua.create_function(move |_, ()| Ok(s.borrow().camera.zoom))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the current camera rotation angle in radians.
    ///
    /// # Returns
    /// Camera rotation in radians.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraRotation()
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.getCameraRotation()
    // luna.graphics.getCameraRotation() -> rotation
    let s = state.clone();
    graphics.set(
        "getCameraRotation",
        lua.create_function(move |_, ()| Ok(s.borrow().camera.rotation))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Resets the camera transform to identity ÔÇö no translation, rotation, or zoom.
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.resetCamera()
    #[allow(unused_doc_comments)]
    /// Luna graphics API function.
    ///
    /// Lua API: luna.graphics.resetCamera()
    // luna.graphics.resetCamera()
    let s = state.clone();
    graphics.set(
        "resetCamera",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.camera = crate::graphics::Camera::default();
            Ok(())
        })?,
    )?;

    // luna.graphics.release(texture_id) -> bool
    /// Releases a GPU resource handle and returns its memory to the pool early.
    ///
    /// # Parameters
    /// - `handle` ÔÇö Resource ID to release (texture, canvas, shader, etc.).
    let s = state.clone();
    graphics.set(
        "release",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_texture_key(&st, &id_val, "luna.graphics.release")?;
            if st.textures.remove(key).is_some() {
                st.released_texture_handles.insert(key.data().as_ffi());
                Ok(true)
            } else {
                Err(invalid_texture_handle("luna.graphics.release"))
            }
        })?,
    )?;

    // luna.graphics.releaseFont(font_id) -> bool
    /// Releases the font resource for the given ID and frees its GPU atlas memory.
    ///
    /// # Parameters
    /// - `font` ÔÇö Font ID returned by newFont.
    let s = state.clone();
    graphics.set(
        "releaseFont",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_font_key(&st, &id_val, "luna.graphics.releaseFont")?;
            if st.fonts.remove(key).is_some() {
                if st.active_font == Some(key) {
                    st.active_font = None;
                }
                Ok(true)
            } else {
                Err(invalid_font_handle("luna.graphics.releaseFont"))
            }
        })?,
    )?;

    // luna.graphics.releaseCanvas(canvas_id) -> bool
    /// Releases the canvas render target and frees its GPU framebuffer memory.
    ///
    /// # Parameters
    /// - `canvas` ÔÇö Canvas ID returned by newCanvas.
    let s = state.clone();
    graphics.set(
        "releaseCanvas",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_canvas_key(&st, &id_val, "luna.graphics.releaseCanvas")?;
            if st.canvases.remove(key).is_some() {
                if st.active_canvas == Some(key) {
                    st.active_canvas = None;
                    st.draw_commands.push(DrawCommand::SetCanvas(None));
                }
                Ok(true)
            } else {
                Err(invalid_canvas_handle("luna.graphics.releaseCanvas"))
            }
        })?,
    )?;

    // luna.graphics.releaseBatch(batch_id) -> bool
    /// Releases the sprite batch resource and frees its GPU instance buffer.
    ///
    /// # Parameters
    /// - `batch` ÔÇö SpriteBatch ID returned by newSpriteBatch.
    let s = state.clone();
    graphics.set(
        "releaseBatch",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_batch_key(&st, &id_val, "luna.graphics.releaseBatch")?;
            if st.sprite_batches.remove(key).is_some() {
                Ok(true)
            } else {
                Err(invalid_batch_handle("luna.graphics.releaseBatch"))
            }
        })?,
    )?;

    // luna.graphics.points(...)
    // Accept either flat args (x1,y1,x2,y2,...) or a table of {x,y} tables
    /// Draws a list of (x, y) points using the current point size and color.
    ///
    /// # Parameters
    /// - `...` ÔÇö Alternating x, y coordinate pairs, or a flat numeric table.
    let s = state.clone();
    graphics.set(
        "points",
        lua.create_function(move |_, args: mlua::MultiValue| {
            let mut points = Vec::new();
            if args.len() == 1 {
                if let Some(mlua::Value::Table(t)) = args.get(0) {
                    for pair in t.clone().sequence_values::<mlua::Table>() {
                        let p = pair?;
                        let x: f32 = p.get(1)?;
                        let y: f32 = p.get(2)?;
                        points.push((x, y));
                    }
                }
            } else {
                let vals: Vec<f32> = args
                    .iter()
                    .map(|v| match v {
                        mlua::Value::Number(n) => *n as f32,
                        mlua::Value::Integer(n) => *n as f32,
                        _ => 0.0,
                    })
                    .collect();
                let mut i = 0;
                while i + 1 < vals.len() {
                    points.push((vals[i], vals[i + 1]));
                    i += 2;
                }
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Points { points });
            Ok(())
        })?,
    )?;

    // luna.graphics.setPointSize(size)
    /// Sets the diameter in pixels used when drawing point primitives.
    ///
    /// # Parameters
    /// - `size` ÔÇö Point diameter in pixels.
    let s = state.clone();
    graphics.set(
        "setPointSize",
        lua.create_function(move |_, size: f32| {
            let mut st = s.borrow_mut();
            st.point_size = size;
            st.draw_commands.push(DrawCommand::SetPointSize(size));
            Ok(())
        })?,
    )?;

    // luna.graphics.getPointSize() -> size
    /// Returns the current point-sprite size.
    let s = state.clone();
    graphics.set(
        "getPointSize",
        lua.create_function(move |_, ()| Ok(s.borrow().point_size))?,
    )?;

    // luna.graphics.printf(text, x, y, limit, align?)
    /// Draws word-wrapped text within a given width.
    let s = state.clone();
    graphics.set(
        "printf",
        lua.create_function(
            move |_, (text, x, y, limit, align): (String, f32, f32, f32, Option<String>)| {
                let align = match align.as_deref() {
                    Some("center") => TextAlign::Center,
                    Some("right") => TextAlign::Right,
                    Some("justify") => TextAlign::Justify,
                    _ => TextAlign::Left,
                };
                let active_font = s.borrow().active_font;
                if let Some(font_key) = active_font {
                    s.borrow_mut()
                        .draw_commands
                        .push(DrawCommand::PrintFormatted {
                            font_key,
                            text,
                            x,
                            y,
                            limit,
                            align,
                            scale: 1.0,
                        });
                }
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.getFontWrap(text, limit) -> lines_table, max_width
    /// Returns the wrap mode of the active font.
    let s = state.clone();
    graphics.set(
        "getFontWrap",
        lua.create_function(move |lua, (text, limit): (String, f32)| {
            let mut st = s.borrow_mut();
            if let Some(font_key) = st.active_font {
                if let Some(font) = st.fonts.get_mut(font_key) {
                    let lines = font.wrap_text(&text, limit);
                    let mut max_w: f32 = 0.0;
                    for line in &lines {
                        let w = font.text_width(line);
                        if w > max_w {
                            max_w = w;
                        }
                    }
                    let tbl = lua.create_table()?;
                    for (i, line) in lines.iter().enumerate() {
                        tbl.set(i + 1, line.as_str())?;
                    }
                    Ok((mlua::Value::Table(tbl), mlua::Value::Number(max_w as f64)))
                } else {
                    Ok((mlua::Value::Nil, mlua::Value::Number(0.0)))
                }
            } else {
                Ok((mlua::Value::Nil, mlua::Value::Number(0.0)))
            }
        })?,
    )?;

    // ÔöÇÔöÇ Scissor ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.setScissor(x, y, w, h) or luna.graphics.setScissor() to disable
    /// Restricts drawing to the given rectangle; clears scissor if no args.
    let s = state.clone();
    graphics.set(
        "setScissor",
        lua.create_function(move |_, args: mlua::MultiValue| {
            let mut st = s.borrow_mut();
            if args.len() >= 4 {
                let x = match &args[0] {
                    mlua::Value::Number(n) => *n as f32,
                    mlua::Value::Integer(n) => *n as f32,
                    _ => 0.0,
                };
                let y = match &args[1] {
                    mlua::Value::Number(n) => *n as f32,
                    mlua::Value::Integer(n) => *n as f32,
                    _ => 0.0,
                };
                let w = match &args[2] {
                    mlua::Value::Number(n) => *n as f32,
                    mlua::Value::Integer(n) => *n as f32,
                    _ => 0.0,
                };
                let h = match &args[3] {
                    mlua::Value::Number(n) => *n as f32,
                    mlua::Value::Integer(n) => *n as f32,
                    _ => 0.0,
                };
                st.scissor = Some((x, y, w, h));
                st.draw_commands
                    .push(DrawCommand::SetScissor(Some((x, y, w, h))));
            } else {
                st.scissor = None;
                st.draw_commands.push(DrawCommand::SetScissor(None));
            }
            Ok(())
        })?,
    )?;

    // luna.graphics.getScissor() -> x, y, w, h or nothing
    /// Returns the active scissor rectangle (x, y, w, h), or nil.
    let s = state.clone();
    graphics.set(
        "getScissor",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(match st.scissor {
                Some((x, y, w, h)) => LuaMultiValue::from_vec(vec![
                    LuaValue::Number(x as f64),
                    LuaValue::Number(y as f64),
                    LuaValue::Number(w as f64),
                    LuaValue::Number(h as f64),
                ]),
                None => LuaMultiValue::new(),
            })
        })?,
    )?;

    // luna.graphics.intersectScissor(x, y, w, h)
    /// Intersects the current scissor rectangle with the given rectangle.
    let s = state.clone();
    graphics.set(
        "intersectScissor",
        lua.create_function(move |_, (x, y, w, h): (f32, f32, f32, f32)| {
            let mut st = s.borrow_mut();
            let rect = if let Some((cx, cy, cw, ch)) = st.scissor {
                let left = x.max(cx);
                let top = y.max(cy);
                let right = (x + w).min(cx + cw);
                let bottom = (y + h).min(cy + ch);
                if right > left && bottom > top {
                    Some((left, top, right - left, bottom - top))
                } else {
                    Some((0.0, 0.0, 0.0, 0.0))
                }
            } else {
                Some((x, y, w, h))
            };
            st.scissor = rect;
            st.draw_commands.push(DrawCommand::SetScissor(rect));
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Color mask ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.setColorMask(r, g, b, a) or luna.graphics.setColorMask() to reset
    /// Sets which RGBA channels are written to the render target for subsequent draw calls.
    ///
    /// # Parameters
    /// - `r` ÔÇö Write to the red channel (boolean).
    /// - `g` ÔÇö Write to the green channel.
    /// - `b` ÔÇö Write to the blue channel.
    /// - `a` ÔÇö Write to the alpha channel.
    let s = state.clone();
    graphics.set(
        "setColorMask",
        lua.create_function(move |_, args: mlua::MultiValue| {
            let mut st = s.borrow_mut();
            if args.len() >= 4 {
                let r = match &args[0] {
                    mlua::Value::Boolean(b) => *b,
                    _ => true,
                };
                let g = match &args[1] {
                    mlua::Value::Boolean(b) => *b,
                    _ => true,
                };
                let b_val = match &args[2] {
                    mlua::Value::Boolean(b) => *b,
                    _ => true,
                };
                let a = match &args[3] {
                    mlua::Value::Boolean(b) => *b,
                    _ => true,
                };
                st.color_mask = (r, g, b_val, a);
                st.draw_commands
                    .push(DrawCommand::SetColorMask(r, g, b_val, a));
            } else {
                st.color_mask = (true, true, true, true);
                st.draw_commands
                    .push(DrawCommand::SetColorMask(true, true, true, true));
            }
            Ok(())
        })?,
    )?;

    // luna.graphics.getColorMask() -> r, g, b, a
    /// Returns the active color channel write mask.
    let s = state.clone();
    graphics.set(
        "getColorMask",
        lua.create_function(move |_, ()| Ok(s.borrow().color_mask))?,
    )?;

    // ÔöÇÔöÇ Wireframe mode ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.setWireframe(enabled)
    /// Enables or disables wireframe rendering mode.
    let s = state.clone();
    graphics.set(
        "setWireframe",
        lua.create_function(move |_, enabled: bool| {
            let mut st = s.borrow_mut();
            st.wireframe = enabled;
            st.draw_commands.push(DrawCommand::SetWireframe(enabled));
            Ok(())
        })?,
    )?;

    // luna.graphics.isWireframe() -> bool
    /// Returns whether wireframe rendering mode is active.
    let s = state.clone();
    graphics.set(
        "isWireframe",
        lua.create_function(move |_, ()| Ok(s.borrow().wireframe))?,
    )?;

    // ÔöÇÔöÇ Canvas size ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.getCanvasSize(canvas_id) -> w, h
    /// Returns the dimensions (w, h) of the current canvas.
    let s = state.clone();
    graphics.set(
        "getCanvasSize",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_canvas_key(&st, &id_val, "luna.graphics.getCanvasSize")?;
            let canvas = st
                .canvases
                .get(key)
                .ok_or_else(|| invalid_canvas_handle("luna.graphics.getCanvasSize"))?;
            Ok((canvas.width, canvas.height))
        })?,
    )?;

    // ÔöÇÔöÇ Default filter ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.setDefaultFilter(min, mag)
    /// Sets the default texture filter mode ('linear' or 'nearest').
    let s = state.clone();
    graphics.set(
        "setDefaultFilter",
        lua.create_function(
            move |_, (min, mag, anisotropy): (String, String, Option<u32>)| {
                s.borrow_mut().default_filter = (min, mag, anisotropy.unwrap_or(1));
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.getDefaultFilter() -> min, mag
    /// Returns the default texture filter mode.
    let s = state.clone();
    graphics.set(
        "getDefaultFilter",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((
                st.default_filter.0.clone(),
                st.default_filter.1.clone(),
                st.default_filter.2,
            ))
        })?,
    )?;

    // ÔöÇÔöÇ Graphics stats ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.getStats() -> table
    /// Returns a table of renderer statistics (draw calls, triangles, etc.).
    let s = state.clone();
    graphics.set(
        "getStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let stats = lua.create_table()?;
            let texture_memory = st
                .textures
                .values()
                .map(|texture| texture.pixels.len() as u64)
                .sum::<u64>()
                + st.canvases
                    .values()
                    .map(|canvas| canvas.width as u64 * canvas.height as u64 * 4)
                    .sum::<u64>();
            /// Drawcalls.
            stats.set("drawcalls", st.render_stats.draw_calls)?;
            /// Canvasswitches.
            stats.set("canvasswitches", st.render_stats.canvas_switches)?;
            /// Batcheddraws.
            stats.set("batcheddraws", st.render_stats.batched_draws)?;
            /// Texturememory.
            stats.set("texturememory", texture_memory)?;
            /// Images.
            stats.set("images", st.textures.len() as u32)?;
            /// Canvases.
            stats.set("canvases", st.canvases.len() as u32)?;
            /// Fonts.
            stats.set("fonts", st.fonts.len() as u32)?;
            Ok(stats)
        })?,
    )?;

    // ÔöÇÔöÇ Stencil ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.stencil(func, action?, value?, keepvalues?)
    /// Draws to the stencil buffer using the given Lua draw function.
    let state_cl = state.clone();
    graphics.set(
        "stencil",
        lua.create_function(
            move |_,
                  (func, action, value, _keepvalues): (
                mlua::Function,
                Option<String>,
                Option<u8>,
                Option<bool>,
            )| {
                let action = match action.as_deref() {
                    Some("increment") => StencilAction::Increment,
                    Some("decrement") => StencilAction::Decrement,
                    Some("incrementwrap") => StencilAction::IncrementWrap,
                    Some("decrementwrap") => StencilAction::DecrementWrap,
                    _ => StencilAction::Replace,
                };
                let value = value.unwrap_or(1);

                state_cl
                    .borrow_mut()
                    .draw_commands
                    .push(DrawCommand::StencilBegin { action, value });
                func.call::<_, ()>(())?;
                state_cl
                    .borrow_mut()
                    .draw_commands
                    .push(DrawCommand::StencilEnd);
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.setStencilTest(compareMode, value) or luna.graphics.setStencilTest()
    /// Configures the stencil test for subsequent draw calls.
    let state_cl = state.clone();
    graphics.set(
        "setStencilTest",
        lua.create_function(move |_, args: mlua::MultiValue| {
            let mut st = state_cl.borrow_mut();
            if args.len() >= 2 {
                let mode_str: String = match &args[0] {
                    mlua::Value::String(s) => s.to_str().unwrap_or("equal").to_string(),
                    _ => "equal".to_string(),
                };
                let value: u8 = match &args[1] {
                    mlua::Value::Integer(n) => *n as u8,
                    mlua::Value::Number(n) => *n as u8,
                    _ => 1,
                };
                let mode = match mode_str.as_str() {
                    "equal" => CompareMode::Equal,
                    "notequal" => CompareMode::NotEqual,
                    "less" => CompareMode::Less,
                    "lequal" | "lessequal" => CompareMode::LessEqual,
                    "greater" => CompareMode::Greater,
                    "gequal" | "greaterequal" => CompareMode::GreaterEqual,
                    "always" => CompareMode::Always,
                    "never" => CompareMode::Never,
                    _ => CompareMode::Equal,
                };
                st.draw_commands
                    .push(DrawCommand::SetStencilTest(Some((mode, value))));
            } else {
                st.draw_commands.push(DrawCommand::SetStencilTest(None));
            }
            Ok(())
        })?,
    )?;

    // luna.graphics.setStencilMode(action, compare?, value?)
    /// Sets the persistent stencil mode stored in SharedState.
    ///
    /// The GPU pipeline reads this on the next frame rebuild.  Both `compare`
    /// and `value` are optional; they default to `"always"` and `0`.
    let state_cl = state.clone();
    graphics.set(
        "setStencilMode",
        lua.create_function(
            move |_, (action_s, compare_s, value): (String, Option<String>, Option<u8>)| {
                let action = match action_s.to_lowercase().as_str() {
                    "keep" => StencilAction::Keep,
                    "zero" => StencilAction::Zero,
                    "replace" => StencilAction::Replace,
                    "increment" => StencilAction::Increment,
                    "decrement" => StencilAction::Decrement,
                    "incrementwrap" => StencilAction::IncrementWrap,
                    "decrementwrap" => StencilAction::DecrementWrap,
                    "invert" => StencilAction::Invert,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "luna.graphics.setStencilMode: unknown action '{}'",
                            other
                        )))
                    }
                };
                let compare = match compare_s
                    .as_deref()
                    .unwrap_or("always")
                    .to_lowercase()
                    .as_str()
                {
                    "always" => CompareMode::Always,
                    "never" => CompareMode::Never,
                    "less" => CompareMode::Less,
                    "lequal" | "lessequal" => CompareMode::LessEqual,
                    "equal" => CompareMode::Equal,
                    "notequal" => CompareMode::NotEqual,
                    "gequal" | "greaterequal" => CompareMode::GreaterEqual,
                    "greater" => CompareMode::Greater,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "luna.graphics.setStencilMode: unknown compare mode '{}'",
                            other
                        )))
                    }
                };
                let value = value.unwrap_or(0);
                state_cl.borrow_mut().stencil_mode = StencilMode {
                    action,
                    compare,
                    value,
                };
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.getStencilMode() -> action, compare, value
    /// Returns the current stencil mode as three values: action string, compare string, value.
    let state_cl = state.clone();
    graphics.set(
        "getStencilMode",
        lua.create_function(move |_, ()| {
            let st = state_cl.borrow();
            let action = match st.stencil_mode.action {
                StencilAction::Keep => "keep",
                StencilAction::Zero => "zero",
                StencilAction::Replace => "replace",
                StencilAction::Increment => "increment",
                StencilAction::Decrement => "decrement",
                StencilAction::IncrementWrap => "incrementwrap",
                StencilAction::DecrementWrap => "decrementwrap",
                StencilAction::Invert => "invert",
            };
            let compare = match st.stencil_mode.compare {
                CompareMode::Always => "always",
                CompareMode::Never => "never",
                CompareMode::Less => "less",
                CompareMode::LessEqual => "lequal",
                CompareMode::Equal => "equal",
                CompareMode::NotEqual => "notequal",
                CompareMode::GreaterEqual => "gequal",
                CompareMode::Greater => "greater",
            };
            Ok((action, compare, st.stencil_mode.value))
        })?,
    )?;

    // luna.graphics.clearStencil()
    /// Resets the stencil mode to the default (keep / always / 0).
    let state_cl = state.clone();
    graphics.set(
        "clearStencil",
        lua.create_function(move |_, ()| {
            state_cl.borrow_mut().stencil_mode = StencilMode::default();
            Ok(())
        })?,
    )?;

    // luna.graphics.setDepthMode(mode, write?)
    /// Sets the depth test comparison mode and optional write flag.
    ///
    /// `mode` is a lowercase string matching one of `DepthMode`'s variants.
    /// `write` defaults to `false`.
    let state_cl = state.clone();
    graphics.set(
        "setDepthMode",
        lua.create_function(move |_, (mode_s, write): (String, Option<bool>)| {
            let mode = match mode_s.to_lowercase().as_str() {
                "always" => DepthMode::Always,
                "never" => DepthMode::Never,
                "less" => DepthMode::Less,
                "lequal" | "lessequal" => DepthMode::LessEqual,
                "equal" => DepthMode::Equal,
                "notequal" => DepthMode::NotEqual,
                "greater" => DepthMode::Greater,
                "gequal" | "greaterequal" => DepthMode::GreaterEqual,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "luna.graphics.setDepthMode: unknown mode '{}'",
                        other
                    )))
                }
            };
            state_cl.borrow_mut().depth_mode = (mode, write.unwrap_or(false));
            Ok(())
        })?,
    )?;

    // luna.graphics.getDepthMode() -> mode, write
    /// Returns the current depth mode string and write-enable flag.
    let state_cl = state.clone();
    graphics.set(
        "getDepthMode",
        lua.create_function(move |_, ()| {
            let st = state_cl.borrow();
            let mode = match st.depth_mode.0 {
                DepthMode::Always => "always",
                DepthMode::Never => "never",
                DepthMode::Less => "less",
                DepthMode::LessEqual => "lequal",
                DepthMode::Equal => "equal",
                DepthMode::NotEqual => "notequal",
                DepthMode::Greater => "greater",
                DepthMode::GreaterEqual => "gequal",
            };
            Ok((mode, st.depth_mode.1))
        })?,
    )?;

    // ÔöÇÔöÇ Custom Shaders ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.newShader(wgslCode) Ôćĺ shader_id
    /// Compiles a custom WGSL shader program and returns its ID.
    let state_cl = state.clone();
    graphics.set(
        "newShader",
        lua.create_function(move |_, code: String| {
            let shader = Shader::new(code).map_err(|err| {
                mlua::Error::RuntimeError(format!("luna.graphics.newShader: {}", err))
            })?;
            let key = state_cl.borrow_mut().shaders.insert(shader);
            Ok(key.data().as_ffi())
        })?,
    )?;

    // luna.graphics.setShader(shader_id?) ÔÇö set active shader or reset to default
    /// Activates a custom WGSL shader for subsequent draw calls.
    let state_cl = state.clone();
    graphics.set(
        "setShader",
        lua.create_function(move |_, id: Option<u64>| {
            let mut st = state_cl.borrow_mut();
            match id {
                Some(id) => {
                    let key = ShaderKey::from(slotmap::KeyData::from_ffi(id));
                    if st.shaders.contains_key(key) {
                        st.active_shader = Some(key);
                        st.draw_commands.push(DrawCommand::SetShader(Some(key)));
                    } else {
                        return Err(mlua::Error::RuntimeError(
                            "luna.graphics.setShader: invalid shader handle".into(),
                        ));
                    }
                }
                None => {
                    st.active_shader = None;
                    st.draw_commands.push(DrawCommand::SetShader(None));
                }
            }
            Ok(())
        })?,
    )?;

    // luna.graphics.getShader() Ôćĺ shader_id or nil
    /// Returns the currently active Shader ID, or nil.
    let state_cl = state.clone();
    graphics.set(
        "getShader",
        lua.create_function(move |_, ()| {
            let st = state_cl.borrow();
            match st.active_shader {
                Some(key) => Ok(mlua::Value::Integer(key.data().as_ffi() as i64)),
                None => Ok(mlua::Value::Nil),
            }
        })?,
    )?;

    // luna.graphics.sendShader(shader_id, name, value)
    /// Sends a named uniform variable value to the currently active shader program.
    ///
    /// # Parameters
    /// - `name` ÔÇö Uniform variable name as defined in the WGSL shader.
    /// - `value` ÔÇö Value to send (number, table of numbers, or boolean).
    let state_cl = state.clone();
    graphics.set(
        "sendShader",
        lua.create_function(move |_, (id, name, value): (u64, String, mlua::Value)| {
            let key = ShaderKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let shader = st.shaders.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError("luna.graphics.sendShader: invalid shader handle".into())
            })?;

            let uniform = match value {
                mlua::Value::Number(n) => UniformValue::Float(n as f32),
                mlua::Value::Integer(n) => UniformValue::Float(n as f32),
                mlua::Value::Boolean(b) => UniformValue::Bool(b),
                mlua::Value::Table(t) => {
                    let len = t.len()? as usize;
                    match len {
                        2 => {
                            let x: f32 = t.get(1)?;
                            let y: f32 = t.get(2)?;
                            UniformValue::Vec2([x, y])
                        }
                        3 => {
                            let x: f32 = t.get(1)?;
                            let y: f32 = t.get(2)?;
                            let z: f32 = t.get(3)?;
                            UniformValue::Vec3([x, y, z])
                        }
                        4 => {
                            let x: f32 = t.get(1)?;
                            let y: f32 = t.get(2)?;
                            let z: f32 = t.get(3)?;
                            let w: f32 = t.get(4)?;
                            UniformValue::Vec4([x, y, z, w])
                        }
                        _ => {
                            return Err(mlua::Error::RuntimeError(
                                "luna.graphics.sendShader: table must have 2, 3, or 4 elements"
                                    .into(),
                            ))
                        }
                    }
                }
                _ => {
                    return Err(mlua::Error::RuntimeError(
                        "luna.graphics.sendShader: unsupported value type".into(),
                    ))
                }
            };

            shader.send(name, uniform);
            Ok(())
        })?,
    )?;

    // luna.graphics.hasShaderUniform(shader_id, name) Ôćĺ bool
    /// Returns whether the current shader has a uniform with the given name.
    let state_cl = state.clone();
    graphics.set(
        "hasShaderUniform",
        lua.create_function(move |_, (id, name): (u64, String)| {
            let key = ShaderKey::from(slotmap::KeyData::from_ffi(id));
            let st = state_cl.borrow();
            let shader = st.shaders.get(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.hasShaderUniform: invalid shader handle".into(),
                )
            })?;
            Ok(shader.has_uniform(&name))
        })?,
    )?;

    // luna.graphics.releaseShader(shader_id) ÔÇö release a shader
    /// Releases the compiled shader program and frees its GPU pipeline object.
    ///
    /// # Parameters
    /// - `shader` ÔÇö Shader ID returned by newShader.
    let state_cl = state.clone();
    graphics.set(
        "releaseShader",
        lua.create_function(move |_, id: u64| {
            let key = ShaderKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            if st.shaders.remove(key).is_some() {
                if st.active_shader == Some(key) {
                    st.active_shader = None;
                }
                Ok(true)
            } else {
                Err(mlua::Error::RuntimeError(
                    "luna.graphics.releaseShader: invalid or already-released shader handle".into(),
                ))
            }
        })?,
    )?;

    // ÔöÇÔöÇ Mesh API ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.newMesh(vertexTable, mode?) Ôćĺ mesh_id
    /// Creates a custom Mesh from vertex data and returns its ID.
    let state_cl = state.clone();
    graphics.set(
        "newMesh",
        lua.create_function(move |_, (verts, mode): (mlua::Table, Option<String>)| {
            let draw_mode = match mode.as_deref() {
                Some("fan") => MeshDrawMode::Fan,
                Some("strip") => MeshDrawMode::Strip,
                _ => MeshDrawMode::Triangles,
            };
            let mut vertices = Vec::new();
            for vert in verts.sequence_values::<mlua::Table>() {
                let v = vert?;
                let x: f32 = v.get(1).unwrap_or(0.0);
                let y: f32 = v.get(2).unwrap_or(0.0);
                let u: f32 = v.get(3).unwrap_or(0.0);
                let v_coord: f32 = v.get(4).unwrap_or(0.0);
                let r: f32 = v.get(5).unwrap_or(1.0);
                let g: f32 = v.get(6).unwrap_or(1.0);
                let b: f32 = v.get(7).unwrap_or(1.0);
                let a: f32 = v.get(8).unwrap_or(1.0);
                vertices.push(MeshVertex {
                    x,
                    y,
                    u,
                    v: v_coord,
                    r,
                    g,
                    b,
                    a,
                });
            }
            let mesh = Mesh::from_vertices(vertices, draw_mode);
            let mut st = state_cl.borrow_mut();
            let key = st.meshes.insert(mesh.clone());
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(key.data().as_ffi())
        })?,
    )?;

    // luna.graphics.drawMesh(mesh_id, x?, y?, r?, sx?, sy?, ox?, oy?)
    /// Draws the given custom Mesh geometry with the current transform and color.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    /// - `x` ÔÇö Optional X position offset in pixels.
    /// - `y` ÔÇö Optional Y position offset in pixels.
    let state_cl = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "drawMesh",
        lua.create_function(
            move |_,
                  (id, x, y, r, sx, sy, ox, oy): (
                u64,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let mut st = state_cl.borrow_mut();
                let key = require_mesh_key(&st, id, "luna.graphics.drawMesh")?;
                st.draw_commands.push(DrawCommand::DrawMesh {
                    mesh_key: key,
                    x: x.unwrap_or(0.0),
                    y: y.unwrap_or(0.0),
                    rotation: r.unwrap_or(0.0),
                    sx: sx.unwrap_or(1.0),
                    sy: sy.unwrap_or(1.0),
                    ox: ox.unwrap_or(0.0),
                    oy: oy.unwrap_or(0.0),
                });
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.setMeshVertex(mesh_id, index, {x,y,u,v,r,g,b,a})
    /// Updates position and UV data for a single vertex in a Mesh.
    let state_cl = state.clone();
    graphics.set(
        "setMeshVertex",
        lua.create_function(move |_, (id, index, data): (u64, usize, mlua::Table)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let mesh = st.meshes.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError("luna.graphics.setMeshVertex: invalid mesh handle".into())
            })?;
            let vertex = MeshVertex {
                x: data.get(1).unwrap_or(0.0),
                y: data.get(2).unwrap_or(0.0),
                u: data.get(3).unwrap_or(0.0),
                v: data.get(4).unwrap_or(0.0),
                r: data.get(5).unwrap_or(1.0),
                g: data.get(6).unwrap_or(1.0),
                b: data.get(7).unwrap_or(1.0),
                a: data.get(8).unwrap_or(1.0),
            };
            mesh.set_vertex(index - 1, vertex);
            let mesh = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(())
        })?,
    )?;

    // luna.graphics.setMeshVertices(mesh_id, vertices_table)
    /// Uploads a new flat vertex array to replace the mesh's current geometry.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    /// - `vertices` ÔÇö Table of vertex attribute tables or a flat number array.
    let state_cl = state.clone();
    graphics.set(
        "setMeshVertices",
        lua.create_function(move |_, (id, vertices): (u64, mlua::Table)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let mesh = st.meshes.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.setMeshVertices: invalid mesh handle".into(),
                )
            })?;
            let mut new_verts = Vec::new();
            for pair in vertices.sequence_values::<mlua::Table>() {
                let data = pair.map_err(|e| {
                    mlua::Error::RuntimeError(format!("luna.graphics.setMeshVertices: {}", e))
                })?;
                new_verts.push(MeshVertex {
                    x: data.get(1).unwrap_or(0.0),
                    y: data.get(2).unwrap_or(0.0),
                    u: data.get(3).unwrap_or(0.0),
                    v: data.get(4).unwrap_or(0.0),
                    r: data.get(5).unwrap_or(1.0),
                    g: data.get(6).unwrap_or(1.0),
                    b: data.get(7).unwrap_or(1.0),
                    a: data.get(8).unwrap_or(1.0),
                });
            }
            mesh.vertices = new_verts;
            let mesh = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(())
        })?,
    )?;

    // luna.graphics.getMeshVertex(mesh_id, index) Ôćĺ x,y,u,v,r,g,b,a
    /// Returns position and UV data for a vertex in a Mesh.
    let state_cl = state.clone();
    graphics.set(
        "getMeshVertex",
        lua.create_function(move |_, (id, index): (u64, usize)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let st = state_cl.borrow();
            let mesh = st.meshes.get(key).ok_or_else(|| {
                mlua::Error::RuntimeError("luna.graphics.getMeshVertex: invalid mesh handle".into())
            })?;
            let v = mesh.get_vertex(index - 1).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.getMeshVertex: vertex index out of bounds".into(),
                )
            })?;
            Ok((v.x, v.y, v.u, v.v, v.r, v.g, v.b, v.a))
        })?,
    )?;

    // luna.graphics.getMeshVertexCount(mesh_id) Ôćĺ number
    /// Returns the total number of vertices in a Mesh.
    let state_cl = state.clone();
    graphics.set(
        "getMeshVertexCount",
        lua.create_function(move |_, id: u64| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let st = state_cl.borrow();
            let mesh = st.meshes.get(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.getMeshVertexCount: invalid mesh handle".into(),
                )
            })?;
            Ok(mesh.vertex_count())
        })?,
    )?;

    // luna.graphics.setMeshTexture(mesh_id, texture_id?)
    /// Binds a texture to the given mesh so it is sampled during rendering.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    /// - `texture` ÔÇö Texture ID to bind, or nil to clear.
    let state_cl = state.clone();
    graphics.set(
        "setMeshTexture",
        lua.create_function(move |_, (id, tex_id): (u64, Option<u64>)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let mesh = st.meshes.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.setMeshTexture: invalid mesh handle".into(),
                )
            })?;
            let tex_key = tex_id.map(|id| TextureKey::from(slotmap::KeyData::from_ffi(id)));
            mesh.set_texture(tex_key);
            let mesh = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(())
        })?,
    )?;

    // luna.graphics.getMeshTexture(mesh_id) Ôćĺ texture_id or nil
    /// Returns the texture ID currently bound to the given mesh for rendering.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID to query.
    ///
    /// # Returns
    /// Texture ID, or nil if no texture is bound.
    let state_cl = state.clone();
    graphics.set(
        "getMeshTexture",
        lua.create_function(move |_, id: u64| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let st = state_cl.borrow();
            let mesh = st.meshes.get(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.getMeshTexture: invalid mesh handle".into(),
                )
            })?;
            Ok(mesh.texture.map(|k| k.data().as_ffi()))
        })?,
    )?;

    // luna.graphics.setMeshDrawMode(mesh_id, mode)
    /// Sets the vertex topology mode used when drawing a mesh ('triangles', 'fan', 'strip', 'points').
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    /// - `mode` ÔÇö Topology string: 'triangles', 'fan', 'strip', or 'points'.
    let state_cl = state.clone();
    graphics.set(
        "setMeshDrawMode",
        lua.create_function(move |_, (id, mode): (u64, String)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let mesh = st.meshes.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.setMeshDrawMode: invalid mesh handle".into(),
                )
            })?;
            let draw_mode = match mode.as_str() {
                "fan" => MeshDrawMode::Fan,
                "strip" => MeshDrawMode::Strip,
                _ => MeshDrawMode::Triangles,
            };
            mesh.set_draw_mode(draw_mode);
            let mesh = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(())
        })?,
    )?;

    // luna.graphics.setMeshVertexMap(mesh_id, indices_table)
    /// Sets an index array defining the vertex drawing order for a custom mesh.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    /// - `map` ÔÇö Table of 1-based vertex indices specifying the draw order.
    let state_cl = state.clone();
    graphics.set(
        "setMeshVertexMap",
        lua.create_function(move |_, (id, indices): (u64, mlua::Table)| {
            let key = MeshKey::from(slotmap::KeyData::from_ffi(id));
            let mut st = state_cl.borrow_mut();
            let mesh = st.meshes.get_mut(key).ok_or_else(|| {
                mlua::Error::RuntimeError(
                    "luna.graphics.setMeshVertexMap: invalid mesh handle".into(),
                )
            })?;
            let mut idx_vec = Vec::new();
            for v in indices.sequence_values::<u32>() {
                idx_vec.push(v? - 1); // Lua 1-indexed to 0-indexed
            }
            mesh.set_vertex_map(idx_vec);
            let mesh = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh,
            });
            Ok(())
        })?,
    )?;

    // luna.graphics.releaseMesh(mesh_id)
    /// Releases the custom mesh resource and frees the GPU vertex buffer.
    ///
    /// # Parameters
    /// - `mesh` ÔÇö Mesh ID returned by newMesh.
    let state_cl = state.clone();
    graphics.set(
        "releaseMesh",
        lua.create_function(move |_, id: u64| {
            let mut st = state_cl.borrow_mut();
            let key = require_mesh_key(&st, id, "luna.graphics.releaseMesh")?;
            st.meshes.remove(key);
            Ok(true)
        })?,
    )?;

    // ÔöÇÔöÇ Nine-Slice (9-patch) rendering ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    // luna.graphics.newNineSlice(image, top, right, bottom, left) -> NineSlice userdata
    /// Creates a nine-slice definition from an image and border insets.
    ///
    /// # Parameters
    /// - `image` ÔÇö Image UserData (LuaImage) or numeric image ID.
    /// - `top` ÔÇö Pixel inset from the top edge.
    /// - `right` ÔÇö Pixel inset from the right edge.
    /// - `bottom` ÔÇö Pixel inset from the bottom edge.
    /// - `left` ÔÇö Pixel inset from the left edge.
    ///
    /// # Returns
    /// A NineSlice UserData object.
    let s = state.clone();
    graphics.set(
        "newNineSlice",
        lua.create_function(
            move |_, (img, top, right, bottom, left): (LuaValue, f32, f32, f32, f32)| {
                let st = s.borrow();
                let texture_key = match &img {
                    LuaValue::UserData(ud) => {
                        let lua_img = ud.borrow::<LuaImage>()?;
                        lua_img.key
                    }
                    LuaValue::Integer(id) => {
                        TextureKey::from(slotmap::KeyData::from_ffi(*id as u64))
                    }
                    LuaValue::Number(id) => {
                        TextureKey::from(slotmap::KeyData::from_ffi(*id as u64))
                    }
                    _ => {
                        return Err(LuaError::RuntimeError(
                            "luna.graphics.newNineSlice: first argument must be an Image or image ID".into(),
                        ));
                    }
                };
                let tex = st.textures.get(texture_key).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "luna.graphics.newNineSlice: invalid image handle".into(),
                    )
                })?;
                let tw = tex.width as f32;
                let th = tex.height as f32;
                if top < 0.0 || right < 0.0 || bottom < 0.0 || left < 0.0 {
                    return Err(LuaError::RuntimeError(
                        "luna.graphics.newNineSlice: border insets must be non-negative".into(),
                    ));
                }
                if left + right > tw || top + bottom > th {
                    return Err(LuaError::RuntimeError(
                        "luna.graphics.newNineSlice: border insets exceed texture dimensions"
                            .into(),
                    ));
                }
                Ok(LuaNineSlice {
                    state: s.clone(),
                    texture_key,
                    top,
                    right,
                    bottom,
                    left,
                    tex_width: tw,
                    tex_height: th,
                })
            },
        )?,
    )?;

    // luna.graphics.drawNineSlice(nineslice, x, y, w, h)
    /// Draws a nine-slice image stretched to fill the given rectangle.
    ///
    /// # Parameters
    /// - `nineslice` ÔÇö NineSlice UserData returned by newNineSlice.
    /// - `x` ÔÇö Destination X position.
    /// - `y` ÔÇö Destination Y position.
    /// - `w` ÔÇö Destination width.
    /// - `h` ÔÇö Destination height.
    let s = state.clone();
    graphics.set(
        "drawNineSlice",
        lua.create_function(
            move |_, (ns_ud, x, y, w, h): (LuaAnyUserData, f32, f32, f32, f32)| {
                let ns = ns_ud.borrow::<LuaNineSlice>()?;
                let mut st = s.borrow_mut();
                st.draw_commands.push(DrawCommand::DrawNineSlice {
                    texture_key: ns.texture_key,
                    tex_w: ns.tex_width,
                    tex_h: ns.tex_height,
                    top: ns.top,
                    right: ns.right,
                    bottom: ns.bottom,
                    left: ns.left,
                    x,
                    y,
                    w,
                    h,
                });
                Ok(())
            },
        )?,
    )?;

    /// Graphics.
    Ok(())
}


/// Registers all `luna.graphics.*` drawing and resource management functions into the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;

    #[allow(unused_doc_comments)]
    /// Sets the current drawing color for all subsequent draw commands.
    ///
    /// Lua API: luna.graphics.setColor(r, g, b, a?)
    #[allow(unused_doc_comments)]
    /// Sets the current drawing color for all subsequent draw commands.
    ///
    /// Lua API: luna.graphics.setColor(r, g, b, a?)
    #[allow(unused_doc_comments)]
    /// Sets the current drawing color for all subsequent draw commands.
    ///
    /// Lua API: luna.graphics.setColor(r, g, b, a?)
    // luna.graphics.setColor(r, g, b, a?)
    let s = state.clone();
    graphics.set(
        "setColor",
        lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            let mut st = s.borrow_mut();
            let a = a.unwrap_or(1.0);
            st.current_color = [r, g, b, a];
            st.draw_commands.push(DrawCommand::SetColor(r, g, b, a));
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Sets the RGBA color used to clear the framebuffer at the start of each draw frame.
    ///
    /// # Parameters
    /// - `r` ÔÇö Red component in [0, 1].
    /// - `g` ÔÇö Green component in [0, 1].
    /// - `b` ÔÇö Blue component in [0, 1].
    /// - `a` ÔÇö Optional alpha component (default 1.0).
    #[allow(unused_doc_comments)]
    /// Sets the background (clear) color.
    ///
    /// Lua API: luna.graphics.setBackgroundColor(r, g, b)
    #[allow(unused_doc_comments)]
    /// Sets the background (clear) color.
    ///
    /// Lua API: luna.graphics.setBackgroundColor(r, g, b)
    // luna.graphics.setBackgroundColor(r, g, b)
    let s = state.clone();
    graphics.set(
        "setBackgroundColor",
        lua.create_function(move |_, (r, g, b): (f32, f32, f32)| {
            let mut st = s.borrow_mut();
            st.background_color = [r, g, b, 1.0];
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the current background color.
    ///
    /// Lua API: luna.graphics.getBackgroundColor()
    #[allow(unused_doc_comments)]
    /// Returns the current background color.
    ///
    /// Lua API: luna.graphics.getBackgroundColor()
    #[allow(unused_doc_comments)]
    /// Returns the current background color.
    ///
    /// Lua API: luna.graphics.getBackgroundColor()
    // luna.graphics.getBackgroundColor() -> r, g, b, a
    let s = state.clone();
    graphics.set(
        "getBackgroundColor",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((
                st.background_color[0],
                st.background_color[1],
                st.background_color[2],
                st.background_color[3],
            ))
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined rectangle at (x, y) with given width and height.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `x` ÔÇö Top-left X coordinate in pixels.
    /// - `y` ÔÇö Top-left Y coordinate in pixels.
    /// - `width` ÔÇö Rectangle width in pixels.
    /// - `height` ÔÇö Rectangle height in pixels.
    /// - `rx` ÔÇö Optional horizontal corner radius for rounded rectangles.
    /// - `ry` ÔÇö Optional vertical corner radius for rounded rectangles.
    #[allow(unused_doc_comments)]
    /// Draws a rectangle.
    ///
    /// Lua API: luna.graphics.rectangle(mode, x, y, w, h, rx?, ry?)
    #[allow(unused_doc_comments)]
    /// Draws a rectangle.
    ///
    /// Lua API: luna.graphics.rectangle(mode, x, y, w, h, rx?, ry?)
    // luna.graphics.rectangle(mode, x, y, w, h, rx?, ry?)
    let s = state.clone();
    graphics.set(
        "rectangle",
        lua.create_function(
            move |_,
                  (mode, x, y, w, h, rx, ry): (
                String,
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
            )| {
                let dm = if mode == "fill" {
                    DrawMode::Fill
                } else {
                    DrawMode::Line
                };
                match rx {
                    Some(rx_val) => {
                        let ry_val = ry.unwrap_or(rx_val);
                        s.borrow_mut()
                            .draw_commands
                            .push(DrawCommand::RoundedRectangle {
                                mode: dm,
                                x,
                                y,
                                w,
                                h,
                                rx: rx_val,
                                ry: ry_val,
                            });
                    }
                    None => {
                        s.borrow_mut().draw_commands.push(DrawCommand::Rectangle {
                            mode: dm,
                            x,
                            y,
                            w,
                            h,
                        });
                    }
                }
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined circle centered at (x, y) with the given radius.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `x` ÔÇö Center X coordinate in pixels.
    /// - `y` ÔÇö Center Y coordinate in pixels.
    /// - `radius` ÔÇö Circle radius in pixels.
    /// - `segments` ÔÇö Optional number of line segments (default auto).
    #[allow(unused_doc_comments)]
    /// Draws a circle.
    ///
    /// Lua API: luna.graphics.circle(mode, x, y, r)
    #[allow(unused_doc_comments)]
    /// Draws a circle.
    ///
    /// Lua API: luna.graphics.circle(mode, x, y, r)
    // luna.graphics.circle(mode, x, y, r)
    let s = state.clone();
    graphics.set(
        "circle",
        lua.create_function(move |_, (mode, x, y, r): (String, f32, f32, f32)| {
            let dm = if mode == "fill" {
                DrawMode::Fill
            } else {
                DrawMode::Line
            };
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Circle { mode: dm, x, y, r });
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined ellipse centered at (x, y) with given horizontal and vertical radii.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `x` ÔÇö Center X coordinate in pixels.
    /// - `y` ÔÇö Center Y coordinate in pixels.
    /// - `rx` ÔÇö Horizontal radius in pixels.
    /// - `ry` ÔÇö Vertical radius in pixels.
    /// - `segments` ÔÇö Optional segment count for smoothness.
    #[allow(unused_doc_comments)]
    /// Draws an ellipse.
    ///
    /// Lua API: luna.graphics.ellipse(mode, x, y, rx, ry)
    #[allow(unused_doc_comments)]
    /// Draws an ellipse.
    ///
    /// Lua API: luna.graphics.ellipse(mode, x, y, rx, ry)
    // luna.graphics.ellipse(mode, x, y, rx, ry)
    let s = state.clone();
    graphics.set(
        "ellipse",
        lua.create_function(
            move |_, (mode, x, y, rx, ry): (String, f32, f32, f32, f32)| {
                let dm = if mode == "fill" {
                    DrawMode::Fill
                } else {
                    DrawMode::Line
                };
                s.borrow_mut().draw_commands.push(DrawCommand::Ellipse {
                    mode: dm,
                    x,
                    y,
                    rx,
                    ry,
                });
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined triangle with three (x, y) vertex coordinates.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `x1`, `y1` ÔÇö First vertex.
    /// - `x2`, `y2` ÔÇö Second vertex.
    /// - `x3`, `y3` ÔÇö Third vertex.
    #[allow(unused_doc_comments)]
    /// Draws a triangle.
    ///
    /// Lua API: luna.graphics.triangle(mode, x1, y1, x2, y2, x3, y3)
    #[allow(unused_doc_comments)]
    /// Draws a triangle.
    ///
    /// Lua API: luna.graphics.triangle(mode, x1, y1, x2, y2, x3, y3)
    // luna.graphics.triangle(mode, x1, y1, x2, y2, x3, y3)
    let s = state.clone();
    graphics.set(
        "triangle",
        lua.create_function(
            move |_, (mode, x1, y1, x2, y2, x3, y3): (String, f32, f32, f32, f32, f32, f32)| {
                let dm = if mode == "fill" {
                    DrawMode::Fill
                } else {
                    DrawMode::Line
                };
                s.borrow_mut().draw_commands.push(DrawCommand::Triangle {
                    mode: dm,
                    x1,
                    y1,
                    x2,
                    y2,
                    x3,
                    y3,
                });
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined polygon from a flat list of (x, y) vertex coordinates.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `vertices` ÔÇö Flat table of numbers in (x, y, x, y, ...) order.
    #[allow(unused_doc_comments)]
    /// Draws a polygon.
    ///
    /// Lua API: luna.graphics.polygon(mode, x1, y1, x2, y2, ...)
    #[allow(unused_doc_comments)]
    /// Draws a polygon.
    ///
    /// Lua API: luna.graphics.polygon(mode, x1, y1, x2, y2, ...)
    // luna.graphics.polygon(mode, x1, y1, x2, y2, ...)
    let s = state.clone();
    graphics.set(
        "polygon",
        lua.create_function(move |lua_ref, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let mode_val = iter
                .next()
                .ok_or_else(|| LuaError::RuntimeError("polygon requires mode argument".into()))?;
            let mode: String = lua_ref.unpack(mode_val)?;
            let dm = if mode == "fill" {
                DrawMode::Fill
            } else {
                DrawMode::Line
            };
            let mut vertices = Vec::new();
            for val in iter {
                if let Ok(n) = lua_ref.unpack::<f32>(val) {
                    vertices.push(n);
                }
            }
            if vertices.len() < 6 {
                return Err(LuaError::RuntimeError(
                    "polygon requires at least 3 vertices (6 numbers)".into(),
                ));
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Polygon { mode: dm, vertices });
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a straight line from (x1, y1) to (x2, y2) using the current color.
    ///
    /// # Parameters
    /// - `x1` ÔÇö Start X in pixels.
    /// - `y1` ÔÇö Start Y in pixels.
    /// - `x2` ÔÇö End X in pixels.
    /// - `y2` ÔÇö End Y in pixels.
    #[allow(unused_doc_comments)]
    /// Draws a line between two points.
    ///
    /// Lua API: luna.graphics.line(x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    /// Draws a line between two points.
    ///
    /// Lua API: luna.graphics.line(x1, y1, x2, y2)
    // luna.graphics.line(x1, y1, x2, y2)
    let s = state.clone();
    graphics.set(
        "line",
        lua.create_function(move |_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Line { x1, y1, x2, y2 });
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Queues draw commands for all live particles.
    ///
    /// Lua API: luna.graphics.draw(image_id, x, y)
    #[allow(unused_doc_comments)]
    /// Queues draw commands for all live particles.
    ///
    /// Lua API: luna.graphics.draw(image_id, x, y)
    #[allow(unused_doc_comments)]
    /// Queues draw commands for all live particles.
    ///
    /// Lua API: luna.graphics.draw(image_id, x, y)
    // luna.graphics.draw(drawable, x?, y?, r?, sx?, sy?, ox?, oy?)
    /// Draws any drawable object — Image, Canvas, or SpriteBatch — at the given position.
    ///
    /// Backward-compatible: still accepts raw integer image IDs.
    ///
    /// # Parameters
    /// - `drawable` — `Drawable`. An Image, Canvas, SpriteBatch userdata, or integer image ID.
    /// - `x` — `f32`. Destination X position (default 0).
    /// - `y` — `f32`. Destination Y position (default 0).
    /// - `r` — `f32`. Rotation in radians (default 0).
    /// - `sx` — `f32`. X scale (default 1).
    /// - `sy` — `f32`. Y scale (default 1).
    /// - `ox` — `f32`. X origin offset (default 0).
    /// - `oy` — `f32`. Y origin offset (default 0).
    ///
    /// # Returns
    /// `()`.
    let s = state.clone();
    graphics.set(
        "draw",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut args_iter = args.iter();
            let drawable = args_iter.next().cloned().unwrap_or(LuaValue::Nil);
            let to_f32 = |v: &LuaValue| -> Option<f32> {
                match v {
                    LuaValue::Number(n) => Some(*n as f32),
                    LuaValue::Integer(n) => Some(*n as f32),
                    _ => None,
                }
            };
            let x = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let y = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let r = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let sx = args_iter.next().and_then(to_f32).unwrap_or(1.0);
            let sy = args_iter.next().and_then(to_f32).unwrap_or(1.0);
            let ox = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let oy = args_iter.next().and_then(to_f32).unwrap_or(0.0);

            let has_transform = r != 0.0 || sx != 1.0 || sy != 1.0 || ox != 0.0 || oy != 0.0;
            let mut st = s.borrow_mut();

            match &drawable {
                LuaValue::UserData(ud) => {
                    // Try Image
                    if let Ok(img) = ud.borrow::<LuaImage>() {
                        let key = img.key;
                        drop(img);
                        if !st.textures.contains_key(key) {
                            return Err(invalid_texture_handle("luna.graphics.draw"));
                        }
                        if has_transform {
                            st.draw_commands.push(DrawCommand::DrawImageEx {
                                texture_key: key,
                                x,
                                y,
                                rotation: r,
                                sx,
                                sy,
                                ox,
                                oy,
                            });
                        } else {
                            st.draw_commands
                                .push(DrawCommand::DrawImage { texture_key: key, x, y });
                        }
                        return Ok(());
                    }
                    // Try Canvas
                    if let Ok(canvas) = ud.borrow::<LuaCanvas>() {
                        let key = canvas.key;
                        drop(canvas);
                        if !st.canvases.contains_key(key) {
                            return Err(invalid_canvas_handle("luna.graphics.draw"));
                        }
                        st.draw_commands.push(DrawCommand::DrawCanvas {
                            canvas_key: key,
                            x,
                            y,
                            rotation: r,
                            sx,
                            sy,
                            ox,
                            oy,
                        });
                        return Ok(());
                    }
                    // Try SpriteBatch
                    if let Ok(batch) = ud.borrow::<LuaSpriteBatch>() {
                        let key = batch.key;
                        drop(batch);
                        if !st.sprite_batches.contains_key(key) {
                            return Err(invalid_batch_handle("luna.graphics.draw"));
                        }
                        st.draw_commands
                            .push(DrawCommand::DrawBatch { batch_key: key });
                        return Ok(());
                    }
                    Err(LuaError::RuntimeError(
                        "luna.graphics.draw: drawable must be an Image, Canvas, or SpriteBatch".into(),
                    ))
                }
                LuaValue::Integer(_) | LuaValue::Number(_) => {
                    // Backward compat: raw integer = texture ID
                    let key =
                        require_texture_key(&st, &drawable, "luna.graphics.draw")?;
                    if has_transform {
                        st.draw_commands.push(DrawCommand::DrawImageEx {
                            texture_key: key,
                            x,
                            y,
                            rotation: r,
                            sx,
                            sy,
                            ox,
                            oy,
                        });
                    } else {
                        st.draw_commands
                            .push(DrawCommand::DrawImage { texture_key: key, x, y });
                    }
                    Ok(())
                }
                LuaValue::Nil => Err(LuaError::RuntimeError(
                    "luna.graphics.draw: drawable cannot be nil".into(),
                )),
                _ => Err(LuaError::RuntimeError(
                    "luna.graphics.draw: expected drawable object".into(),
                )),
            }
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws the given text string at (x, y) using the active font and foreground color.
    ///
    /// # Parameters
    /// - `text` ÔÇö String to draw.
    /// - `x` ÔÇö Left edge X coordinate in pixels.
    /// - `y` ÔÇö Top edge Y coordinate in pixels.
    /// - `angle` ÔÇö Optional rotation angle in radians.
    /// - `sx`, `sy` ÔÇö Optional scale factors.
    /// - `ox`, `oy` ÔÇö Optional origin offsets.
    #[allow(unused_doc_comments)]
    /// Draws text at the given position.
    ///
    /// Lua API: luna.graphics.print(text, x, y, scale?)
    #[allow(unused_doc_comments)]
    /// Draws text at the given position.
    ///
    /// Lua API: luna.graphics.print(text, x, y, scale?)
    // luna.graphics.print(text, x, y, scale?)
    let s = state.clone();
    graphics.set(
        "print",
        lua.create_function(
            move |_, (text, x, y, scale): (String, f32, f32, Option<f32>)| {
                let active_font = s.borrow().active_font;
                let scale = scale.unwrap_or(1.0);
                match active_font {
                    Some(font_key) => {
                        s.borrow_mut().draw_commands.push(DrawCommand::PrintFont {
                            font_key,
                            text,
                            x,
                            y,
                            scale,
                        });
                    }
                    None => {
                        s.borrow_mut()
                            .draw_commands
                            .push(DrawCommand::Print { text, x, y, scale });
                    }
                }
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Loads an image file and returns its ID.
    ///
    /// Lua API: luna.graphics.newImage(path)
    #[allow(unused_doc_comments)]
    /// Loads an image file or creates from ImageData and returns its ID.
    ///
    /// Lua API: luna.graphics.newImage(path) or luna.graphics.newImage(imageData)
    #[allow(unused_doc_comments)]
    /// Loads an image file or creates from ImageData and returns its ID.
    ///
    /// Lua API: luna.graphics.newImage(path) or luna.graphics.newImage(imageData)
    #[allow(unused_doc_comments)]
    /// Loads an image file or creates from ImageData and returns its ID.
    ///
    /// Lua API: luna.graphics.newImage(path) or luna.graphics.newImage(imageData)
    // luna.graphics.newImage(path | imageData) -> image
    let s = state.clone();
    graphics.set(
        "newImage",
        lua.create_function(move |_, arg: LuaValue| match arg {
            LuaValue::String(path_str) => {
                let path = path_str.to_str().map_err(|e| {
                    LuaError::RuntimeError(format!("luna.graphics.newImage: invalid path: {}", e))
                })?;
                let mut st = s.borrow_mut();
                let full_path = st.game_dir.join(path);
                match Texture::load(&full_path, &mut st.textures) {
                    Ok(tex) => {
                        st.released_texture_handles.remove(&tex.key.data().as_ffi());
                        Ok(LuaImage {
                            state: s.clone(),
                            key: tex.key,
                        })
                    }
                    Err(e) => Err(LuaError::RuntimeError(format!(
                        "luna.graphics.newImage: failed to load '{}': {}",
                        path, e
                    ))),
                }
            }
            LuaValue::UserData(ud) => {
                let img_data = ud.borrow::<crate::image::image_data::ImageData>()?;
                let pixels = img_data.as_bytes().to_vec();
                let (w, h) = img_data.dimensions();
                let mut st = s.borrow_mut();
                match Texture::from_rgba(w, h, pixels, &mut st.textures) {
                    Ok(tex) => {
                        st.released_texture_handles.remove(&tex.key.data().as_ffi());
                        Ok(LuaImage {
                            state: s.clone(),
                            key: tex.key,
                        })
                    }
                    Err(e) => Err(LuaError::RuntimeError(format!(
                        "luna.graphics.newImage: failed to create from ImageData: {}",
                        e
                    ))),
                }
            }
            _ => Err(LuaError::RuntimeError(
                "luna.graphics.newImage: expected a file path string or ImageData".into(),
            )),
        })?,
    )?;

    // luna.graphics.newCanvas(width, height) -> canvas
    /// Creates an off-screen render canvas and returns its ID.
    let s = state.clone();
    graphics.set(
        "newCanvas",
        lua.create_function(move |_, (width, height): (u32, u32)| {
            if width == 0 || height == 0 {
                return Err(LuaError::RuntimeError(
                    "luna.graphics.newCanvas: width and height must be greater than zero".into(),
                ));
            }

            let mut st = s.borrow_mut();
            let key = st
                .canvases
                .insert(crate::graphics::Canvas::new(width, height));
            st.draw_commands.push(DrawCommand::RegisterCanvas {
                canvas_key: key,
                width,
                height,
            });
            Ok(LuaCanvas {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Clears the screen with the current background color.
    ///
    /// Lua API: luna.graphics.clear(r?, g?, b?)
    #[allow(unused_doc_comments)]
    /// Clears the screen with the current background color.
    ///
    /// Lua API: luna.graphics.clear(r?, g?, b?)
    #[allow(unused_doc_comments)]
    /// Clears the screen with the current background color.
    ///
    /// Lua API: luna.graphics.clear(r?, g?, b?)
    // luna.graphics.clear(r?, g?, b?)
    let s = state.clone();
    graphics.set(
        "clear",
        lua.create_function(
            move |_, (_r, _g, _b): (Option<f32>, Option<f32>, Option<f32>)| {
                s.borrow_mut().draw_commands.clear();
                Ok(())
            },
        )?,
    )?;

    #[allow(unused_doc_comments)]
    /// Sets the line width for outline drawing.
    ///
    /// Lua API: luna.graphics.setLineWidth(width)
    #[allow(unused_doc_comments)]
    /// Sets the line width for outline drawing.
    ///
    /// Lua API: luna.graphics.setLineWidth(width)
    #[allow(unused_doc_comments)]
    /// Sets the line width for outline drawing.
    ///
    /// Lua API: luna.graphics.setLineWidth(width)
    // luna.graphics.setLineWidth(width)
    let s = state.clone();
    graphics.set(
        "setLineWidth",
        lua.create_function(move |_, w: f32| {
            let mut st = s.borrow_mut();
            st.line_width = w;
            st.draw_commands.push(DrawCommand::SetLineWidth(w));
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the current line width in pixels used for 'line' mode drawing.
    ///
    /// # Returns
    /// Line width in pixels.
    #[allow(unused_doc_comments)]
    /// Returns the current line width.
    ///
    /// Lua API: luna.graphics.getLineWidth()
    #[allow(unused_doc_comments)]
    /// Returns the current line width.
    ///
    /// Lua API: luna.graphics.getLineWidth()
    // luna.graphics.getLineWidth()
    let s = state.clone();
    graphics.set(
        "getLineWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().line_width))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the window width in pixels.
    ///
    /// Lua API: luna.graphics.getWidth()
    #[allow(unused_doc_comments)]
    /// Returns the window width in pixels.
    ///
    /// Lua API: luna.graphics.getWidth()
    #[allow(unused_doc_comments)]
    /// Returns the window width in pixels.
    ///
    /// Lua API: luna.graphics.getWidth()
    // luna.graphics.getWidth()
    let s = state.clone();
    graphics.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the window height in pixels.
    ///
    /// Lua API: luna.graphics.getHeight()
    #[allow(unused_doc_comments)]
    /// Returns the window height in pixels.
    ///
    /// Lua API: luna.graphics.getHeight()
    #[allow(unused_doc_comments)]
    /// Returns the window height in pixels.
    ///
    /// Lua API: luna.graphics.getHeight()
    // luna.graphics.getHeight()
    let s = state.clone();
    graphics.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the window dimensions (width, height).
    ///
    /// Lua API: luna.graphics.getDimensions()
    #[allow(unused_doc_comments)]
    /// Returns the window dimensions (width, height).
    ///
    /// Lua API: luna.graphics.getDimensions()
    #[allow(unused_doc_comments)]
    /// Returns the window dimensions (width, height).
    ///
    /// Lua API: luna.graphics.getDimensions()
    // luna.graphics.getDimensions() -> width, height
    let s = state.clone();
    graphics.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // ÔöÇÔöÇ Feature 4: getColor ÔÇô read back the current draw colour ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Returns the current drawing color (r, g, b, a).
    ///
    /// Lua API: luna.graphics.getColor()
    #[allow(unused_doc_comments)]
    /// Returns the current drawing color (r, g, b, a).
    ///
    /// Lua API: luna.graphics.getColor()
    #[allow(unused_doc_comments)]
    /// Returns the current drawing color (r, g, b, a).
    ///
    /// Lua API: luna.graphics.getColor()
    // luna.graphics.getColor() -> r, g, b, a
    let s = state.clone();
    graphics.set(
        "getColor",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((
                st.current_color[0],
                st.current_color[1],
                st.current_color[2],
                st.current_color[3],
            ))
        })?,
    )?;

    // ÔöÇÔöÇ Feature 1: Transform stack ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Pushes the current transform matrix onto the transform stack.
    ///
    /// Lua API: luna.graphics.push()
    #[allow(unused_doc_comments)]
    /// Pushes the current transform matrix onto the transform stack.
    ///
    /// Lua API: luna.graphics.push()
    #[allow(unused_doc_comments)]
    /// Pushes the current transform matrix onto the transform stack.
    ///
    /// Lua API: luna.graphics.push()
    // luna.graphics.push()
    let s = state.clone();
    graphics.set(
        "push",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.draw_commands.push(DrawCommand::PushTransform);
            st.transform_stack_depth += 1;
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Pops the top transform matrix from the stack.
    ///
    /// Lua API: luna.graphics.pop()
    #[allow(unused_doc_comments)]
    /// Pops the top transform matrix from the stack.
    ///
    /// Lua API: luna.graphics.pop()
    #[allow(unused_doc_comments)]
    /// Pops the top transform matrix from the stack.
    ///
    /// Lua API: luna.graphics.pop()
    // luna.graphics.pop()
    let s = state.clone();
    graphics.set(
        "pop",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.draw_commands.push(DrawCommand::PopTransform);
            if st.transform_stack_depth > 1 {
                st.transform_stack_depth -= 1;
            }
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Translates (moves) the current transform.
    ///
    /// Lua API: luna.graphics.translate(x, y)
    #[allow(unused_doc_comments)]
    /// Translates (moves) the current transform.
    ///
    /// Lua API: luna.graphics.translate(x, y)
    #[allow(unused_doc_comments)]
    /// Translates (moves) the current transform.
    ///
    /// Lua API: luna.graphics.translate(x, y)
    // luna.graphics.translate(x, y)
    let s = state.clone();
    graphics.set(
        "translate",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Translate { x, y });
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Rotates the current transform by the given angle in radians.
    ///
    /// Lua API: luna.graphics.rotate(angle)
    #[allow(unused_doc_comments)]
    /// Rotates the current transform by the given angle in radians.
    ///
    /// Lua API: luna.graphics.rotate(angle)
    #[allow(unused_doc_comments)]
    /// Rotates the current transform by the given angle in radians.
    ///
    /// Lua API: luna.graphics.rotate(angle)
    // luna.graphics.rotate(angle)  ÔÇö radians
    let s = state.clone();
    graphics.set(
        "rotate",
        lua.create_function(move |_, angle: f32| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Rotate { angle });
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Concatenates a scale factor onto the current transform matrix.
    ///
    /// # Parameters
    /// - `sx` ÔÇö Horizontal scale factor.
    /// - `sy` ÔÇö Vertical scale factor (defaults to sx if omitted).
    #[allow(unused_doc_comments)]
    /// Scales the current transform.
    ///
    /// Lua API: luna.graphics.scale(sx, sy?)
    #[allow(unused_doc_comments)]
    /// Scales the current transform.
    ///
    /// Lua API: luna.graphics.scale(sx, sy?)
    // luna.graphics.scale(sx, sy?)
    let s = state.clone();
    graphics.set(
        "scale",
        lua.create_function(move |_, (sx, sy): (f32, Option<f32>)| {
            let sy = sy.unwrap_or(sx);
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Scale { sx, sy });
            Ok(())
        })?,
    )?;

    // luna.graphics.shear(kx, ky)
    /// Applies a shear transform to the current matrix.
    let s = state.clone();
    graphics.set(
        "shear",
        lua.create_function(move |_, (kx, ky): (f32, f32)| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Shear { kx, ky });
            Ok(())
        })?,
    )?;

    // luna.graphics.origin() ÔÇö reset transform to identity
    /// Resets the transform to the identity (no translation, rotation, or scale).
    let s = state.clone();
    graphics.set(
        "origin",
        lua.create_function(move |_, ()| {
            s.borrow_mut().draw_commands.push(DrawCommand::Origin);
            Ok(())
        })?,
    )?;

    // luna.graphics.applyTransform(transform) ÔÇö apply a Transform object to the current matrix
    /// Applies the given Transform object to the current transform stack.
    let s = state.clone();
    graphics.set(
        "applyTransform",
        lua.create_function(move |_, transform_ud: mlua::AnyUserData| {
            // Borrow the Transform from the UserData via its getMatrix method
            let table: mlua::Table = transform_ud.call_method("getMatrix", ())?;
            let mut matrix = [0.0f32; 9];
            for (i, val) in matrix.iter_mut().enumerate() {
                *val = table.get::<_, f32>(i as i64 + 1)?;
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::ApplyTransform { matrix });
            Ok(())
        })?,
    )?;

    // luna.graphics.getStackDepth() -> number
    /// Returns the current depth of the transform stack.
    let s = state.clone();
    graphics.set(
        "getStackDepth",
        lua.create_function(move |_, ()| Ok(s.borrow().transform_stack_depth))?,
    )?;

    // luna.graphics.setCanvas(canvas?) -- no arg or nil resets to the screen target
    /// Redirects all drawing to the given canvas (or screen if nil).
    let s = state.clone();
    graphics.set(
        "setCanvas",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();
            match args.into_iter().next() {
                None | Some(LuaValue::Nil) => {
                    st.active_canvas = None;
                    st.draw_commands.push(DrawCommand::SetCanvas(None));
                }
                Some(canvas_val) => {
                    let key = require_canvas_key(&st, &canvas_val, "luna.graphics.setCanvas")?;
                    st.active_canvas = Some(key);
                    st.draw_commands.push(DrawCommand::SetCanvas(Some(key)));
                }
            }
            Ok(())
        })?,
    )?;

    // luna.graphics.getCanvas() -> canvas or nil
    /// Returns the ID of the currently active render canvas, or nil.
    let s = state.clone();
    graphics.set(
        "getCanvas",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            match st.active_canvas {
                Some(key) if st.canvases.contains_key(key) => Ok(Some(LuaCanvas {
                    state: s.clone(),
                    key,
                })),
                Some(_) => {
                    st.active_canvas = None;
                    Ok(None)
                }
                None => Ok(None),
            }
        })?,
    )?;

    // luna.graphics.reset() ÔÇö reset all graphics state to defaults
    /// Resets all graphics state to defaults: transform, color (1,1,1,1), shader, and scissor.
    let s = state.clone();
    graphics.set(
        "reset",
        lua.create_function(move |_, ()| {
            let mut st = s.borrow_mut();
            st.draw_commands
                .push(DrawCommand::SetColor(1.0, 1.0, 1.0, 1.0));
            st.draw_commands
                .push(DrawCommand::SetBlendMode(BlendMode::Alpha));
            st.draw_commands.push(DrawCommand::SetLineWidth(1.0));
            st.draw_commands.push(DrawCommand::SetPointSize(1.0));
            st.draw_commands
                .push(DrawCommand::SetColorMask(true, true, true, true));
            st.draw_commands.push(DrawCommand::SetScissor(None));
            st.draw_commands.push(DrawCommand::SetWireframe(false));
            st.draw_commands.push(DrawCommand::SetShader(None));
            st.draw_commands.push(DrawCommand::Origin);
            st.draw_commands.push(DrawCommand::SetCanvas(None));
            st.current_color = [1.0, 1.0, 1.0, 1.0];
            st.background_color = [0.0, 0.0, 0.0, 1.0];
            st.line_width = 1.0;
            st.point_size = 1.0;
            st.blend_mode = BlendMode::Alpha;
            st.transform_stack_depth = 1;
            st.scissor = None;
            st.color_mask = (true, true, true, true);
            st.wireframe = false;
            st.default_filter = ("nearest".to_string(), "nearest".to_string(), 1);
            st.active_font = None;
            st.active_canvas = None;
            st.active_shader = None;
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Feature 2: Arc ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Draws a filled or outlined arc segment centered at (x, y) with the given radius.
    ///
    /// # Parameters
    /// - `mode` ÔÇö Draw mode: 'fill' or 'line'.
    /// - `x` ÔÇö Center X coordinate in pixels.
    /// - `y` ÔÇö Center Y coordinate in pixels.
    /// - `radius` ÔÇö Arc radius in pixels.
    /// - `angle1` ÔÇö Start angle in radians.
    /// - `angle2` ÔÇö End angle in radians.
    /// - `segments` ÔÇö Optional number of line segments for smoothness.
    #[allow(unused_doc_comments)]
    /// Draws an arc.
    ///
    /// Lua API: luna.graphics.arc(mode, x, y, radius, angle1, angle2, segments?)
    #[allow(unused_doc_comments)]
    /// Draws an arc.
    ///
    /// Lua API: luna.graphics.arc(mode, x, y, radius, angle1, angle2, segments?)
    // luna.graphics.arc(mode, x, y, radius, angle1, angle2, segments?)
    let s = state.clone();
    graphics.set(
        "arc",
        lua.create_function(
            move |_,
                  (mode, x, y, radius, angle1, angle2, segments): (
                String,
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<u32>,
            )| {
                let dm = if mode == "fill" {
                    DrawMode::Fill
                } else {
                    DrawMode::Line
                };
                let segments = segments.unwrap_or(32);
                s.borrow_mut().draw_commands.push(DrawCommand::Arc {
                    mode: dm,
                    x,
                    y,
                    radius,
                    angle1,
                    angle2,
                    segments,
                });
                Ok(())
            },
        )?,
    )?;

    // ÔöÇÔöÇ Feature 3: Quads (sprite-sheet regions) ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Defines a sub-rectangle of a texture (a quad).
    ///
    /// Lua API: luna.graphics.newQuad(x, y, w, h, sw, sh)
    #[allow(unused_doc_comments)]
    /// Defines a sub-rectangle of a texture (a quad).
    ///
    /// Lua API: luna.graphics.newQuad(x, y, w, h, sw, sh)
    #[allow(unused_doc_comments)]
    /// Defines a sub-rectangle of a texture (a quad).
    ///
    /// Lua API: luna.graphics.newQuad(x, y, w, h, sw, sh)
    // luna.graphics.newQuad(x, y, w, h, sw, sh) -> Lua table with quad data
    graphics.set(
        "newQuad",
        lua.create_function(
            move |lua_ref, (x, y, w, h, sw, sh): (f32, f32, f32, f32, f32, f32)| {
                let quad = lua_ref.create_table()?;
                /// X.
                quad.set("x", x)?;
                /// Y.
                quad.set("y", y)?;
                /// W.
                quad.set("w", w)?;
                /// H.
                quad.set("h", h)?;
                /// Sw.
                quad.set("sw", sw)?;
                /// Sh.
                quad.set("sh", sh)?;
                Ok(quad)
            },
        )?,
    )?;

    // luna.graphics.drawEx(drawable, x, y, r?, sx?, sy?, ox?, oy?)
    // - Polymorphic draw with full affine transform: Image/Canvas/SpriteBatch or integer ID.
    // - `sy` defaults to `sx` when omitted (uniform scaling).
    /// Draws any drawable object with a full affine transform.
    ///
    /// Accepts Image, Canvas, SpriteBatch userdata or raw integer image IDs.
    /// When `sy` is omitted it defaults to `sx` for uniform scaling.
    ///
    /// # Parameters
    /// - `drawable` — `Drawable`. An Image, Canvas, SpriteBatch userdata or integer image ID.
    /// - `x` — `f32`. Destination X position.
    /// - `y` — `f32`. Destination Y position.
    /// - `r` — `f32`. Rotation in radians (default 0).
    /// - `sx` — `f32`. X scale (default 1).
    /// - `sy` — `f32`. Y scale (default sx).
    /// - `ox` — `f32`. X origin offset (default 0).
    /// - `oy` — `f32`. Y origin offset (default 0).
    ///
    /// # Returns
    /// `()`.
    let s = state.clone();
    graphics.set(
        "drawEx",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut args_iter = args.iter();
            let drawable = args_iter.next().cloned().unwrap_or(LuaValue::Nil);
            let to_f32 = |v: &LuaValue| -> Option<f32> {
                match v {
                    LuaValue::Number(n) => Some(*n as f32),
                    LuaValue::Integer(n) => Some(*n as f32),
                    _ => None,
                }
            };
            let x = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let y = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let rotation = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let sx = args_iter.next().and_then(to_f32).unwrap_or(1.0);
            let sy = args_iter.next().and_then(to_f32).unwrap_or(sx);
            let ox = args_iter.next().and_then(to_f32).unwrap_or(0.0);
            let oy = args_iter.next().and_then(to_f32).unwrap_or(0.0);

            let mut st = s.borrow_mut();

            match &drawable {
                LuaValue::UserData(ud) => {
                    // Try Image
                    if let Ok(img) = ud.borrow::<LuaImage>() {
                        let key = img.key;
                        drop(img);
                        if !st.textures.contains_key(key) {
                            return Err(invalid_texture_handle("luna.graphics.drawEx"));
                        }
                        st.draw_commands.push(DrawCommand::DrawImageEx {
                            texture_key: key,
                            x,
                            y,
                            rotation,
                            sx,
                            sy,
                            ox,
                            oy,
                        });
                        return Ok(());
                    }
                    // Try Canvas
                    if let Ok(canvas) = ud.borrow::<LuaCanvas>() {
                        let key = canvas.key;
                        drop(canvas);
                        if !st.canvases.contains_key(key) {
                            return Err(invalid_canvas_handle("luna.graphics.drawEx"));
                        }
                        st.draw_commands.push(DrawCommand::DrawCanvas {
                            canvas_key: key,
                            x,
                            y,
                            rotation,
                            sx,
                            sy,
                            ox,
                            oy,
                        });
                        return Ok(());
                    }
                    // Try SpriteBatch
                    if let Ok(batch) = ud.borrow::<LuaSpriteBatch>() {
                        let key = batch.key;
                        drop(batch);
                        if !st.sprite_batches.contains_key(key) {
                            return Err(invalid_batch_handle("luna.graphics.drawEx"));
                        }
                        st.draw_commands
                            .push(DrawCommand::DrawBatch { batch_key: key });
                        return Ok(());
                    }
                    Err(LuaError::RuntimeError(
                        "luna.graphics.drawEx: drawable must be an Image, Canvas, or SpriteBatch"
                            .into(),
                    ))
                }
                LuaValue::Integer(_) | LuaValue::Number(_) => {
                    let texture_key =
                        require_texture_key(&st, &drawable, "luna.graphics.drawEx")?;
                    st.draw_commands.push(DrawCommand::DrawImageEx {
                        texture_key,
                        x,
                        y,
                        rotation,
                        sx,
                        sy,
                        ox,
                        oy,
                    });
                    Ok(())
                }
                LuaValue::Nil => Err(LuaError::RuntimeError(
                    "luna.graphics.drawEx: drawable cannot be nil".into(),
                )),
                _ => Err(LuaError::RuntimeError(
                    "luna.graphics.drawEx: expected drawable object".into(),
                )),
            }
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Draws a quad region of an image with an affine transform.
    ///
    /// Lua API: luna.graphics.drawQuad(image_id, quad, x, y, r?, sx?, sy?, ox?, oy?)
    #[allow(unused_doc_comments)]
    /// Draws a quad region of an image with an affine transform.
    ///
    /// Lua API: luna.graphics.drawQuad(image_id, quad, x, y, r?, sx?, sy?, ox?, oy?)
    #[allow(unused_doc_comments)]
    /// Draws a quad region of an image with an affine transform.
    ///
    /// Lua API: luna.graphics.drawQuad(image_id, quad, x, y, r?, sx?, sy?, ox?, oy?)
    // luna.graphics.drawQuad(image_id, quad, x, y, r?, sx?, sy?, ox?, oy?)
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "drawQuad",
        lua.create_function(
            move |_,
                  (id_val, quad, x, y, rotation, sx, sy, ox, oy): (
                LuaValue,
                LuaTable,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let quad_x: f32 = quad.get("x")?;
                let quad_y: f32 = quad.get("y")?;
                let quad_w: f32 = quad.get("w")?;
                let quad_h: f32 = quad.get("h")?;
                let tex_w: f32 = quad.get("sw")?;
                let tex_h: f32 = quad.get("sh")?;
                let rotation = rotation.unwrap_or(0.0);
                let sx = sx.unwrap_or(1.0);
                let sy = sy.unwrap_or(sx);
                let ox = ox.unwrap_or(0.0);
                let oy = oy.unwrap_or(0.0);
                let mut st = s.borrow_mut();
                let texture_key = require_texture_key(&st, &id_val, "luna.graphics.drawQuad")?;
                st.draw_commands.push(DrawCommand::DrawQuad {
                    texture_key,
                    quad_x,
                    quad_y,
                    quad_w,
                    quad_h,
                    tex_w,
                    tex_h,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                });
                Ok(())
            },
        )?,
    )?;

    // luna.graphics.drawCanvas(canvas, x, y, r?, sx?, sy?, ox?, oy?)
    /// Draws an off-screen canvas to the current render target.
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "drawCanvas",
        lua.create_function(
            move |_,
                  (canvas_val, x, y, rotation, sx, sy, ox, oy): (
                LuaValue,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let rotation = rotation.unwrap_or(0.0);
                let sx = sx.unwrap_or(1.0);
                let sy = sy.unwrap_or(sx);
                let ox = ox.unwrap_or(0.0);
                let oy = oy.unwrap_or(0.0);
                let mut st = s.borrow_mut();
                let canvas_key = require_canvas_key(&st, &canvas_val, "luna.graphics.drawCanvas")?;
                st.draw_commands.push(DrawCommand::DrawCanvas {
                    canvas_key,
                    x,
                    y,
                    rotation,
                    sx,
                    sy,
                    ox,
                    oy,
                });
                Ok(())
            },
        )?,
    )?;

    // ÔöÇÔöÇ Feature 5: Polyline ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Draws an open multi-segment polyline.
    ///
    /// Lua API: luna.graphics.polyline(x1, y1, x2, y2, ...)
    #[allow(unused_doc_comments)]
    /// Draws an open multi-segment polyline.
    ///
    /// Lua API: luna.graphics.polyline(x1, y1, x2, y2, ...)
    #[allow(unused_doc_comments)]
    /// Draws an open multi-segment polyline.
    ///
    /// Lua API: luna.graphics.polyline(x1, y1, x2, y2, ...)
    // luna.graphics.polyline(x1, y1, x2, y2, ...)  ÔÇö 2+ point pairs
    let s = state.clone();
    graphics.set(
        "polyline",
        lua.create_function(move |lua_ref, args: LuaMultiValue| {
            let mut points = Vec::new();
            for val in args {
                if let Ok(n) = lua_ref.unpack::<f32>(val) {
                    points.push(n);
                }
            }
            if points.len() < 4 {
                return Err(LuaError::RuntimeError(
                    "polyline requires at least 2 points (4 numbers)".into(),
                ));
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Polyline { points });
            Ok(())
        })?,
    )?;

    // ÔöÇÔöÇ Font management ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

    #[allow(unused_doc_comments)]
    /// Loads a TTF/OTF font file and returns its ID.
    ///
    /// Lua API: luna.graphics.newFont(path, size?)
    #[allow(unused_doc_comments)]
    /// Loads a TTF/OTF font file and returns its ID.
    ///
    /// Lua API: luna.graphics.newFont(path, size?)
    #[allow(unused_doc_comments)]
    /// Loads a TTF/OTF font file and returns its ID.
    ///
    /// Lua API: luna.graphics.newFont(path, size?)
    // luna.graphics.newFont(path, size?)
    let s = state.clone();
    graphics.set(
        "newFont",
        lua.create_function(move |_, (path, size): (String, Option<f32>)| {
            let mut st = s.borrow_mut();
            let size = size.unwrap_or(14.0);
            let full_path = st.game_dir.join(&path);
            let data = std::fs::read(&full_path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "luna.graphics.newFont: failed to read '{}': {}",
                    path, e
                ))
            })?;
            let font = crate::graphics::Font::from_bytes(&data, size)
                .map_err(|e| LuaError::RuntimeError(format!("luna.graphics.newFont: {}", e)))?;
            let key = st.fonts.insert(font);
            Ok(LuaFont {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Sets the active font for subsequent print calls.
    ///
    /// Lua API: luna.graphics.setFont(font_id)
    #[allow(unused_doc_comments)]
    /// Sets the active font for subsequent print calls.
    ///
    /// Lua API: luna.graphics.setFont(font_id)
    #[allow(unused_doc_comments)]
    /// Sets the active font for subsequent print calls.
    ///
    /// Lua API: luna.graphics.setFont(font_id)
    // luna.graphics.setFont(font_id)
    let s = state.clone();
    graphics.set(
        "setFont",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = font_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if !st.fonts.contains_key(key) {
                return Err(LuaError::RuntimeError(
                    "luna.graphics.setFont: font handle is not valid or was released".into(),
                ));
            }
            st.active_font = Some(key);
            Ok(())
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the currently active font ID.
    ///
    /// Lua API: luna.graphics.getFont()
    #[allow(unused_doc_comments)]
    /// Returns the currently active font ID.
    ///
    /// Lua API: luna.graphics.getFont()
    #[allow(unused_doc_comments)]
    /// Returns the currently active font ID.
    ///
    /// Lua API: luna.graphics.getFont()
    // luna.graphics.getFont() -> font_id or nil
    let s = state.clone();
    graphics.set(
        "getFont",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            match st.active_font {
                Some(key) => Ok(Some(LuaFont {
                    state: s.clone(),
                    key,
                })),
                None => Ok(None),
            }
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the width of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontWidth(font_id, text)
    #[allow(unused_doc_comments)]
    /// Returns the width of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontWidth(font_id, text)
    #[allow(unused_doc_comments)]
    /// Returns the width of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontWidth(font_id, text)
    // luna.graphics.getFontWidth(font_id, text) -> width
    let s = state.clone();
    graphics.set(
        "getFontWidth",
        lua.create_function(move |_, (id_val, text): (LuaValue, String)| {
            let key = font_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if let Some(font) = st.fonts.get_mut(key) {
                Ok(font.text_width(&text))
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.getFontWidth: font handle is not valid or was released".into(),
                ))
            }
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Returns the height of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontHeight(font_id)
    #[allow(unused_doc_comments)]
    /// Returns the height of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontHeight(font_id)
    #[allow(unused_doc_comments)]
    /// Returns the height of text in the active font.
    ///
    /// Lua API: luna.graphics.getFontHeight(font_id)
    // luna.graphics.getFontHeight(font_id) -> height
    let s = state.clone();
    graphics.set(
        "getFontHeight",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = font_key_from_value(&id_val)?;
            let st = s.borrow();
            if let Some(font) = st.fonts.get(key) {
                Ok(font.line_height())
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.getFontHeight: font handle is not valid or was released".into(),
                ))
            }
        })?,
    )?;

    // luna.graphics.getFontAscent(font_id) -> ascent
    /// Returns the active font's ascent ÔÇö distance in pixels from baseline to the top of capital letters.
    ///
    /// # Returns
    /// Ascent value in pixels as a number.
    let s = state.clone();
    graphics.set(
        "getFontAscent",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = font_key_from_value(&id_val)?;
            let st = s.borrow();
            if let Some(font) = st.fonts.get(key) {
                Ok(font.ascent())
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.getFontAscent: font handle is not valid or was released".into(),
                ))
            }
        })?,
    )?;

    // luna.graphics.getFontDescent(font_id) -> descent
    /// Returns the active font's descent ÔÇö distance in pixels from the baseline to the bottom of descenders.
    ///
    /// # Returns
    /// Descent value in pixels as a number.
    let s = state.clone();
    graphics.set(
        "getFontDescent",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = font_key_from_value(&id_val)?;
            let st = s.borrow();
            if let Some(font) = st.fonts.get(key) {
                Ok(font.descent())
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.getFontDescent: font handle is not valid or was released".into(),
                ))
            }
        })?,
    )?;

    // luna.graphics.setFontLineHeight(font_id, height)
    /// Sets the line height multiplier for the active font used in multi-line text rendering.
    ///
    /// # Parameters
    /// - `height` ÔÇö Line height factor (1.0 = default spacing).
    let s = state.clone();
    graphics.set(
        "setFontLineHeight",
        lua.create_function(move |_, (id_val, height): (LuaValue, f32)| {
            let key = font_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if let Some(font) = st.fonts.get_mut(key) {
                font.set_line_height(height);
                Ok(())
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.setFontLineHeight: font handle is not valid or was released"
                        .into(),
                ))
            }
        })?,
    )?;

    // luna.graphics.getFontLineHeight(font_id) -> height
    /// Returns the line height in pixels of the currently active font.
    ///
    /// # Returns
    /// Line height in pixels.
    let s = state.clone();
    graphics.set(
        "getFontLineHeight",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = font_key_from_value(&id_val)?;
            let st = s.borrow();
            if let Some(font) = st.fonts.get(key) {
                Ok(font.line_height())
            } else {
                Err(LuaError::RuntimeError(
                    "luna.graphics.getFontLineHeight: font handle is not valid or was released"
                        .into(),
                ))
            }
        })?,
    )?;


    // luna.graphics.captureScreenshot(callback)
    /// Captures the current frame as an `ImageData` and passes it to `callback`.
    ///
    /// In headless or test mode this creates a blank transparent `ImageData` sized to the
    /// current window dimensions and calls `callback` synchronously (GPU pixel readback is
    /// deferred to future full-GPU implementation). Setting `pending_screenshot` in
    /// `SharedState` allows engine-side code to detect that a capture was requested.
    ///
    /// # Parameters
    /// - `callback` — `function`. Called with one `ImageData` argument.
    ///
    /// # Returns
    /// Nothing.
    let s = state.clone();
    graphics.set(
        "captureScreenshot",
        lua.create_function(move |lua_ctx, callback: LuaFunction| {
            let (w, h) = {
                let st = s.borrow();
                (st.window_width, st.window_height)
            };
            s.borrow_mut().pending_screenshot = true;
            let img = crate::image::ImageData::new(w.max(1), h.max(1));
            let img_ud = lua_ctx.create_userdata(img)?;
            let result = callback.call::<_, ()>(img_ud);
            s.borrow_mut().pending_screenshot = false;
            result
        })?,
    )?;

    register_ext(lua, &graphics, state.clone())?;

    luna.set("graphics", graphics)?;

    Ok(())
}
