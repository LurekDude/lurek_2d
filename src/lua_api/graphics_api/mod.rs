//! Registers the `luna.graphics.*` graphics API.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::SharedState;
use crate::graphics::renderer::{BlendMode, DrawCommand, DrawMode};
use crate::graphics::texture::Texture;
use slotmap::Key;

mod helpers;
pub(super) mod ext;
#[allow(unused_imports)]
use helpers::*;

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
    // luna.graphics.draw(image_id, x, y)
    let s = state.clone();
    graphics.set(
        "draw",
        lua.create_function(move |_, (id_val, x, y): (LuaValue, f32, f32)| {
            let mut st = s.borrow_mut();
            let texture_key = require_texture_key(&st, &id_val, "luna.graphics.draw")?;
            st.draw_commands
                .push(DrawCommand::DrawImage { texture_key, x, y });
            Ok(())
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

    #[allow(unused_doc_comments)]
    /// Draws an image with a full affine transform.
    ///
    /// Lua API: luna.graphics.drawEx(image_id, x, y, r?, sx?, sy?, ox?, oy?)
    #[allow(unused_doc_comments)]
    /// Draws an image with a full affine transform.
    ///
    /// Lua API: luna.graphics.drawEx(image_id, x, y, r?, sx?, sy?, ox?, oy?)
    #[allow(unused_doc_comments)]
    /// Draws an image with a full affine transform.
    ///
    /// Lua API: luna.graphics.drawEx(image_id, x, y, r?, sx?, sy?, ox?, oy?)
    // luna.graphics.drawEx(image_id, x, y, r?, sx?, sy?, ox?, oy?)
    // - Full transform draw without a quad.
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "drawEx",
        lua.create_function(
            move |_,
                  (id_val, x, y, rotation, sx, sy, ox, oy): (
                LuaValue,
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let mut st = s.borrow_mut();
                let texture_key = require_texture_key(&st, &id_val, "luna.graphics.drawEx")?;
                let rotation = rotation.unwrap_or(0.0);
                let sx = sx.unwrap_or(1.0);
                let sy = sy.unwrap_or(sx);
                let ox = ox.unwrap_or(0.0);
                let oy = oy.unwrap_or(0.0);
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
            },
        )?,
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


    ext::register_ext(lua, &graphics, state.clone())?;

    luna.set("graphics", graphics)?;

    Ok(())
}
