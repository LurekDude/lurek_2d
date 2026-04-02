//! Extended graphics API registrations (second half of `register`).

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::super::SharedState;
use crate::engine::resource_keys::{
    MeshKey, ShaderKey, TextureKey,
};
use crate::graphics::mesh::{Mesh, MeshDrawMode, MeshVertex};
use crate::graphics::renderer::CompareMode;
use crate::graphics::renderer::{BlendMode, DrawCommand, StencilAction, TextAlign};
use crate::graphics::shader::{Shader, UniformValue};
use slotmap::Key;

#[allow(unused_imports)]
use super::helpers::*;

pub(super) fn register_ext(
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
