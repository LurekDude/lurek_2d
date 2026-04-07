//! `luna.graphics` — 2D drawing, images, fonts, canvases, meshes, shaders and sprite batches.

use super::SharedState;
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;

use crate::engine::resource_keys::*;
use crate::engine::ScreenshotRequest;
use crate::graphics::sprite_batch::BatchEntry;
use crate::graphics::{
    BlendMode, Canvas, CompareMode, DrawCommand, DrawMode, Font, Mesh, MeshDrawMode, MeshVertex,
    Shader, SpriteBatch, StencilAction, TextAlign, Texture, UniformValue,
};
use crate::image::ImageData;
use crate::math::Rect;

// ===============================================================================
// UserData wrapper types
// ===============================================================================

// -------------------------------------------------------------------------------
// LuaImage UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a loaded texture stored in SharedState.
#[derive(Clone)]
pub struct LuaImage {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: TextureKey,
}

impl LuaUserData for LuaImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of this image in pixels.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.width)
        });

        // -- getHeight --
        /// Returns the height of this image in pixels.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.height)
        });

        // -- getDimensions --
        /// Returns width and height of this image.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok((td.width, td.height))
        });

        // -- release --
        /// Releases the GPU texture memory for this image.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if st.textures.remove(this.key).is_some() {
                st.released_texture_handles
                    .insert(this.key.data().as_ffi());
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Image"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Image"));
    }
}

// -------------------------------------------------------------------------------
// LuaFont UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a loaded font stored in SharedState.
#[derive(Clone)]
pub struct LuaFont {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: FontKey,
}

impl LuaUserData for LuaFont {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the rendered width of the given text string.
        /// @param text : string
        /// @return number
        methods.add_method("getWidth", |_, this, text: String| {
            let mut st = this.state.borrow_mut();
            let font = st.fonts.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.text_width(&text))
        });

        // -- getHeight --
        /// Returns the line height of this font.
        /// @return number
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });

        // -- getLineHeight --
        /// Returns the line height multiplier of this font.
        /// @return number
        methods.add_method("getLineHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });

        // -- setLineHeight --
        /// Sets the line height multiplier for this font.
        /// @param height : number
        /// @return nil
        methods.add_method("setLineHeight", |_, this, height: f32| {
            let mut st = this.state.borrow_mut();
            let font = st.fonts.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            font.set_line_height(height);
            Ok(())
        });

        // -- getAscent --
        /// Returns the ascent of this font in pixels.
        /// @return number
        methods.add_method("getAscent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.ascent())
        });

        // -- getDescent --
        /// Returns the descent of this font in pixels.
        /// @return number
        methods.add_method("getDescent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.descent())
        });

        // -- getWrap --
        /// Wraps text to the given width and returns the lines.
        /// @param text : string
        /// @param limit : number
        /// @return table, number
        methods.add_method("getWrap", |lua, this, (text, limit): (String, f32)| {
            let mut st = this.state.borrow_mut();
            let font = st.fonts.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
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
            Ok((tbl, max_w))
        });

        // -- release --
        /// Releases this font and frees its atlas memory.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if st.fonts.remove(this.key).is_some() {
                if st.active_font == Some(this.key) {
                    st.active_font = None;
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Font"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Font"));
    }
}

// -------------------------------------------------------------------------------
// LuaCanvas UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to an off-screen render target stored in SharedState.
#[derive(Clone)]
pub struct LuaCanvas {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: CanvasKey,
}

impl LuaUserData for LuaCanvas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of this canvas in pixels.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.width)
        });

        // -- getHeight --
        /// Returns the height of this canvas in pixels.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.height)
        });

        // -- getDimensions --
        /// Returns width and height of this canvas.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok((c.width, c.height))
        });

        // -- release --
        /// Releases GPU framebuffer memory for this canvas.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if st.canvases.remove(this.key).is_some() {
                if st.active_canvas == Some(this.key) {
                    st.active_canvas = None;
                    st.draw_commands.push(DrawCommand::SetCanvas(None));
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Canvas"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Canvas"));
    }
}

// -------------------------------------------------------------------------------
// LuaSpriteBatch UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a sprite batch stored in SharedState.
#[derive(Clone)]
pub struct LuaSpriteBatch {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SpriteBatchKey,
}

impl LuaUserData for LuaSpriteBatch {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds a sprite entry to this batch.
        /// @param x : number
        /// @param y : number
        /// @return integer?
        methods.add_method(
            "add",
            |_,
             this,
             (x, y, r, sx, sy, ox, oy): (
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let mut st = this.state.borrow_mut();
                let batch = st.sprite_batches.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError(
                        "SpriteBatch handle is not valid or was released".into(),
                    )
                })?;
                let entry = BatchEntry {
                    x,
                    y,
                    quad_x: 0.0,
                    quad_y: 0.0,
                    quad_w: 0.0,
                    quad_h: 0.0,
                    rotation: r.unwrap_or(0.0),
                    sx: sx.unwrap_or(1.0),
                    sy: sy.unwrap_or(1.0),
                    ox: ox.unwrap_or(0.0),
                    oy: oy.unwrap_or(0.0),
                };
                Ok(batch.add(entry))
            },
        );

        // -- clear --
        /// Removes all sprites from this batch.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(batch) = st.sprite_batches.get_mut(this.key) {
                batch.clear();
            }
            Ok(())
        });

        // -- getCount --
        /// Returns the number of sprites in this batch.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "SpriteBatch handle is not valid or was released".into(),
                )
            })?;
            Ok(batch.len())
        });

        // -- getBufferSize --
        /// Returns the maximum capacity of this batch.
        /// @return integer
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "SpriteBatch handle is not valid or was released".into(),
                )
            })?;
            Ok(batch.buffer_size())
        });

        // -- release --
        /// Releases this sprite batch.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.sprite_batches.remove(this.key).is_some())
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("SpriteBatch"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("SpriteBatch"));
    }
}

// -------------------------------------------------------------------------------
// LuaMesh UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a mesh stored in SharedState.
#[derive(Clone)]
pub struct LuaMesh {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: MeshKey,
}

impl LuaUserData for LuaMesh {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getVertexCount --
        /// Returns the number of vertices in this mesh.
        /// @return integer
        methods.add_method("getVertexCount", |_, this, ()| {
            let st = this.state.borrow();
            let mesh = st.meshes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
            })?;
            Ok(mesh.vertex_count())
        });

        // -- getVertex --
        /// Returns vertex data at the given 1-based index.
        /// @param index : integer
        /// @return number, number, number, number, number, number, number, number
        methods.add_method("getVertex", |_, this, index: usize| {
            let st = this.state.borrow();
            let mesh = st.meshes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
            })?;
            let v = mesh.get_vertex(index.wrapping_sub(1)).ok_or_else(|| {
                LuaError::RuntimeError("Mesh vertex index out of bounds".into())
            })?;
            Ok((v.x, v.y, v.u, v.v, v.r, v.g, v.b, v.a))
        });

        // -- setVertex --
        /// Sets vertex data at the given 1-based index.
        /// @param index : integer
        /// @param data : table
        /// @return nil
        methods.add_method("setVertex", |_, this, (index, data): (usize, LuaTable)| {
            let mut st = this.state.borrow_mut();
            let mesh = st.meshes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
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
            mesh.set_vertex(index.wrapping_sub(1), vertex);
            let mesh_clone = mesh.clone();
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: this.key,
                mesh: mesh_clone,
            });
            Ok(())
        });

        // -- setTexture --
        /// Assigns a texture to this mesh.
        /// @param image : Image?
        /// @return nil
        methods.add_method("setTexture", |_, this, ud: Option<LuaAnyUserData>| {
            let tex_key = match &ud {
                Some(u) => {
                    let img = u.borrow::<LuaImage>()?;
                    Some(img.key)
                }
                None => None,
            };
            let mut st = this.state.borrow_mut();
            let mesh = st.meshes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
            })?;
            mesh.set_texture(tex_key);
            Ok(())
        });

        // -- release --
        /// Releases this mesh.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.meshes.remove(this.key).is_some())
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Mesh"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Mesh"));
    }
}

// -------------------------------------------------------------------------------
// LuaShader UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a compiled shader stored in SharedState.
#[derive(Clone)]
pub struct LuaShader {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShaderKey,
}

impl LuaUserData for LuaShader {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- send --
        /// Sends a uniform value to this shader.
        /// @param name : string
        /// @param value : number|table
        /// @return nil
        methods.add_method("send", |_, this, (name, value): (String, LuaValue)| {
            let mut st = this.state.borrow_mut();
            let shader = st.shaders.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shader handle is not valid or was released".into())
            })?;
            let uv = lua_value_to_uniform(&value)?;
            shader.send(name, uv);
            Ok(())
        });

        // -- hasUniform --
        /// Returns whether this shader has a uniform with the given name.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasUniform", |_, this, name: String| {
            let st = this.state.borrow();
            let shader = st.shaders.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shader handle is not valid or was released".into())
            })?;
            Ok(shader.has_uniform(&name))
        });

        // -- release --
        /// Releases this shader.
        /// @return boolean
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if st.shaders.remove(this.key).is_some() {
                if st.active_shader == Some(this.key) {
                    st.active_shader = None;
                }
                Ok(true)
            } else {
                Ok(false)
            }
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Shader"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Shader"));
    }
}

// -------------------------------------------------------------------------------
// LuaQuad UserData
// -------------------------------------------------------------------------------

/// Lua-side quad viewport into a texture.
#[derive(Clone)]
pub struct LuaQuad {
    /// Source rectangle x.
    pub x: f32,
    /// Source rectangle y.
    pub y: f32,
    /// Source rectangle width.
    pub w: f32,
    /// Source rectangle height.
    pub h: f32,
    /// Reference texture width.
    pub sw: f32,
    /// Reference texture height.
    pub sh: f32,
}

impl LuaUserData for LuaQuad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getViewport --
        /// Returns the quad viewport rectangle.
        /// @return number, number, number, number
        methods.add_method("getViewport", |_, this, ()| {
            Ok((this.x, this.y, this.w, this.h))
        });

        // -- setViewport --
        /// Sets the quad viewport rectangle.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return nil
        methods.add_method_mut("setViewport", |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
            this.x = x;
            this.y = y;
            this.w = w;
            this.h = h;
            Ok(())
        });

        // -- getTextureDimensions --
        /// Returns the reference texture dimensions.
        /// @return number, number
        methods.add_method("getTextureDimensions", |_, this, ()| {
            Ok((this.sw, this.sh))
        });

        // -- typeOf --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("typeOf", |_, _, ()| Ok("Quad"));

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Quad"));
    }
}

// ===============================================================================
// Helpers
// ===============================================================================

/// Converts a Lua value to a `UniformValue`.
fn lua_value_to_uniform(v: &LuaValue) -> LuaResult<UniformValue> {
    match v {
        LuaValue::Number(n) => Ok(UniformValue::Float(*n as f32)),
        LuaValue::Integer(n) => Ok(UniformValue::Int(*n as i32)),
        LuaValue::Boolean(b) => Ok(UniformValue::Bool(*b)),
        LuaValue::Table(t) => {
            let len = t.raw_len();
            match len {
                2 => {
                    let a: f32 = t.get(1)?;
                    let b: f32 = t.get(2)?;
                    Ok(UniformValue::Vec2([a, b]))
                }
                3 => {
                    let a: f32 = t.get(1)?;
                    let b: f32 = t.get(2)?;
                    let c: f32 = t.get(3)?;
                    Ok(UniformValue::Vec3([a, b, c]))
                }
                4 => {
                    let a: f32 = t.get(1)?;
                    let b: f32 = t.get(2)?;
                    let c: f32 = t.get(3)?;
                    let d: f32 = t.get(4)?;
                    Ok(UniformValue::Vec4([a, b, c, d]))
                }
                _ => Err(LuaError::RuntimeError(
                    "Uniform table must have 2, 3, or 4 elements".into(),
                )),
            }
        }
        _ => Err(LuaError::RuntimeError(
            "Uniform value must be a number, boolean, or table".into(),
        )),
    }
}

/// Parses a mode string into DrawMode.
fn parse_draw_mode(mode: &str) -> DrawMode {
    if mode == "fill" {
        DrawMode::Fill
    } else {
        DrawMode::Line
    }
}

// ===============================================================================
// Registration
// ===============================================================================

/// Registers the `luna.graphics` namespace on the given Lua table.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;

    // ── Color ────────────────────────────────────────────────────────────────

    // -- setColor --
    /// Sets the current drawing color.
    /// @param r : number
    /// @param g : number
    /// @param b : number
    /// @param a : number?
    let s = state.clone();
    graphics.set(
        "setColor",
        lua.create_function(move |_, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
            let a = a.unwrap_or(1.0);
            let mut st = s.borrow_mut();
            st.current_color = [r, g, b, a];
            st.draw_commands.push(DrawCommand::SetColor(r, g, b, a));
            Ok(())
        })?,
    )?;

    // -- getColor --
    /// Returns the current drawing color.
    /// @return number, number, number, number
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

    // -- setBackgroundColor --
    /// Sets the background clear color.
    /// @param r : number
    /// @param g : number
    /// @param b : number
    let s = state.clone();
    graphics.set(
        "setBackgroundColor",
        lua.create_function(move |_, (r, g, b): (f32, f32, f32)| {
            s.borrow_mut().background_color = [r, g, b, 1.0];
            Ok(())
        })?,
    )?;

    // -- getBackgroundColor --
    /// Returns the current background color.
    /// @return number, number, number, number
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

    // ── Shape Drawing ────────────────────────────────────────────────────────

    // -- rectangle --
    /// Draws a rectangle.
    /// @param mode : string
    /// @param x : number
    /// @param y : number
    /// @param w : number
    /// @param h : number
    /// @param rx : number?
    /// @param ry : number?
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
                let dm = parse_draw_mode(&mode);
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
                        s.borrow_mut()
                            .draw_commands
                            .push(DrawCommand::Rectangle {
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

    // -- circle --
    /// Draws a circle.
    /// @param mode : string
    /// @param x : number
    /// @param y : number
    /// @param radius : number
    let s = state.clone();
    graphics.set(
        "circle",
        lua.create_function(move |_, (mode, x, y, radius): (String, f32, f32, f32)| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Circle {
                    mode: parse_draw_mode(&mode),
                    x,
                    y,
                    r: radius,
                });
            Ok(())
        })?,
    )?;

    // -- ellipse --
    /// Draws an ellipse.
    /// @param mode : string
    /// @param x : number
    /// @param y : number
    /// @param rx : number
    /// @param ry : number
    let s = state.clone();
    graphics.set(
        "ellipse",
        lua.create_function(move |_, (mode, x, y, rx, ry): (String, f32, f32, f32, f32)| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Ellipse {
                    mode: parse_draw_mode(&mode),
                    x,
                    y,
                    rx,
                    ry,
                });
            Ok(())
        })?,
    )?;

    // -- triangle --
    /// Draws a triangle.
    /// @param mode : string
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @param x3 : number
    /// @param y3 : number
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "triangle",
        lua.create_function(
            move |_, (mode, x1, y1, x2, y2, x3, y3): (String, f32, f32, f32, f32, f32, f32)| {
                s.borrow_mut()
                    .draw_commands
                    .push(DrawCommand::Triangle {
                        mode: parse_draw_mode(&mode),
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

    // -- line --
    /// Draws a line between two points.
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    let s = state.clone();
    graphics.set(
        "line",
        lua.create_function(move |_, args: LuaMultiValue| {
            let vals: Vec<f32> = args
                .iter()
                .filter_map(|v| match v {
                    LuaValue::Number(n) => Some(*n as f32),
                    LuaValue::Integer(n) => Some(*n as f32),
                    _ => None,
                })
                .collect();
            if vals.len() == 4 {
                s.borrow_mut()
                    .draw_commands
                    .push(DrawCommand::Line {
                        x1: vals[0],
                        y1: vals[1],
                        x2: vals[2],
                        y2: vals[3],
                    });
            } else if vals.len() >= 4 {
                s.borrow_mut()
                    .draw_commands
                    .push(DrawCommand::Polyline { points: vals });
            }
            Ok(())
        })?,
    )?;

    // -- polygon --
    /// Draws a polygon from a list of vertices.
    /// @param mode : string
    /// @param vertices : table|...
    let s = state.clone();
    graphics.set(
        "polygon",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.iter();
            let mode_str = match iter.next() {
                Some(LuaValue::String(s)) => s.to_str().unwrap_or("fill").to_string(),
                _ => "fill".to_string(),
            };
            let mut vertices = Vec::new();
            for v in iter {
                match v {
                    LuaValue::Number(n) => vertices.push(*n as f32),
                    LuaValue::Integer(n) => vertices.push(*n as f32),
                    LuaValue::Table(t) => {
                        for n in t.clone().sequence_values::<f64>().flatten() {
                            vertices.push(n as f32);
                        }
                    }
                    _ => {}
                }
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Polygon {
                    mode: parse_draw_mode(&mode_str),
                    vertices,
                });
            Ok(())
        })?,
    )?;

    // -- arc --
    /// Draws an arc.
    /// @param mode : string
    /// @param x : number
    /// @param y : number
    /// @param radius : number
    /// @param angle1 : number
    /// @param angle2 : number
    /// @param segments : integer?
    let s = state.clone();
    #[allow(clippy::type_complexity)]
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
                s.borrow_mut().draw_commands.push(DrawCommand::Arc {
                    mode: parse_draw_mode(&mode),
                    x,
                    y,
                    radius,
                    angle1,
                    angle2,
                    segments: segments.unwrap_or(32),
                });
                Ok(())
            },
        )?,
    )?;

    // -- points --
    /// Draws a list of points.
    /// @param ... : number|table
    let s = state.clone();
    graphics.set(
        "points",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut points = Vec::new();
            if args.len() == 1 {
                if let Some(LuaValue::Table(t)) = args.get(0) {
                    for pair in t.clone().sequence_values::<LuaTable>() {
                        let p = pair?;
                        let x: f32 = p.get(1)?;
                        let y: f32 = p.get(2)?;
                        points.push((x, y));
                    }
                }
            } else {
                let vals: Vec<f32> = args
                    .iter()
                    .filter_map(|v| match v {
                        LuaValue::Number(n) => Some(*n as f32),
                        LuaValue::Integer(n) => Some(*n as f32),
                        _ => None,
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

    // ── Drawing ──────────────────────────────────────────────────────────────

    // -- draw --
    /// Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
    /// @param drawable : Image|Canvas|SpriteBatch|Mesh
    /// @param x : number?
    /// @param y : number?
    /// @param r : number?
    /// @param sx : number?
    /// @param sy : number?
    /// @param ox : number?
    /// @param oy : number?
    let s = state.clone();
    #[allow(clippy::type_complexity)]
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
                    if let Ok(img) = ud.borrow::<LuaImage>() {
                        let key = img.key;
                        drop(img);
                        if !st.textures.contains_key(key) {
                            return Err(LuaError::RuntimeError(
                                "luna.graphics.draw: image handle is not valid".into(),
                            ));
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
                                effect: None,
                            });
                        } else {
                            st.draw_commands.push(DrawCommand::DrawImage {
                                texture_key: key,
                                x,
                                y,
                                effect: None,
                            });
                        }
                        return Ok(());
                    }
                    if let Ok(canvas) = ud.borrow::<LuaCanvas>() {
                        let key = canvas.key;
                        drop(canvas);
                        if !st.canvases.contains_key(key) {
                            return Err(LuaError::RuntimeError(
                                "luna.graphics.draw: canvas handle is not valid".into(),
                            ));
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
                    if let Ok(batch) = ud.borrow::<LuaSpriteBatch>() {
                        let key = batch.key;
                        drop(batch);
                        if !st.sprite_batches.contains_key(key) {
                            return Err(LuaError::RuntimeError(
                                "luna.graphics.draw: sprite batch handle is not valid".into(),
                            ));
                        }
                        st.draw_commands
                            .push(DrawCommand::DrawBatch { batch_key: key });
                        return Ok(());
                    }
                    if let Ok(mesh) = ud.borrow::<LuaMesh>() {
                        let key = mesh.key;
                        drop(mesh);
                        if !st.meshes.contains_key(key) {
                            return Err(LuaError::RuntimeError(
                                "luna.graphics.draw: mesh handle is not valid".into(),
                            ));
                        }
                        st.draw_commands.push(DrawCommand::DrawMesh {
                            mesh_key: key,
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
                    Err(LuaError::RuntimeError(
                        "luna.graphics.draw: expected Image, Canvas, SpriteBatch, or Mesh".into(),
                    ))
                }
                LuaValue::Nil => Err(LuaError::RuntimeError(
                    "luna.graphics.draw: drawable cannot be nil".into(),
                )),
                _ => Err(LuaError::RuntimeError(
                    "luna.graphics.draw: unsupported drawable type".into(),
                )),
            }
        })?,
    )?;

    // -- drawq --
    /// Draws a portion of an image defined by a Quad.
    /// @param image : Image
    /// @param quad : Quad
    /// @param x : number?
    /// @param y : number?
    /// @param r : number?
    /// @param sx : number?
    /// @param sy : number?
    /// @param ox : number?
    /// @param oy : number?
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    graphics.set(
        "drawq",
        lua.create_function(
            move |_,
                  (img_ud, quad_ud, x, y, r, sx, sy, ox, oy): (
                LuaAnyUserData,
                LuaAnyUserData,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let img = img_ud.borrow::<LuaImage>()?;
                let img_key = img.key;
                drop(img);
                let quad = quad_ud.borrow::<LuaQuad>()?;
                let qx = quad.x;
                let qy = quad.y;
                let qw = quad.w;
                let qh = quad.h;
                let qsw = quad.sw;
                let qsh = quad.sh;
                drop(quad);
                let x = x.unwrap_or(0.0);
                let y = y.unwrap_or(0.0);
                let r = r.unwrap_or(0.0);
                let sx = sx.unwrap_or(1.0);
                let sy = sy.unwrap_or(1.0);
                let ox = ox.unwrap_or(0.0);
                let oy = oy.unwrap_or(0.0);
                s.borrow_mut().draw_commands.push(DrawCommand::DrawQuad {
                    texture_key: img_key,
                    quad_x: qx,
                    quad_y: qy,
                    quad_w: qw,
                    quad_h: qh,
                    tex_w: qsw,
                    tex_h: qsh,
                    x,
                    y,
                    rotation: r,
                    sx,
                    sy,
                    ox,
                    oy,
                    effect: None,
                });
                Ok(())
            },
        )?,
    )?;

    // ── Text ─────────────────────────────────────────────────────────────────

    // -- print --
    /// Draws text at the given position.
    /// @param text : string
    /// @param x : number?
    /// @param y : number?
    /// @param scale : number?
    let s = state.clone();
    graphics.set(
        "print",
        lua.create_function(
            move |_, (text, x, y, scale): (String, Option<f32>, Option<f32>, Option<f32>)| {
                let x = x.unwrap_or(0.0);
                let y = y.unwrap_or(0.0);
                let scale = scale.unwrap_or(1.0);
                let active_font = s.borrow().active_font;
                match active_font {
                    Some(font_key) => {
                        s.borrow_mut()
                            .draw_commands
                            .push(DrawCommand::PrintFont {
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

    // -- printf --
    /// Draws word-wrapped text within a given width.
    /// @param text : string
    /// @param x : number
    /// @param y : number
    /// @param limit : number
    /// @param align : string?
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

    // ── Clear ────────────────────────────────────────────────────────────────

    // -- clear --
    /// Clears the draw command queue (resets the screen).
    /// @param r : number?
    /// @param g : number?
    /// @param b : number?
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

    // ── Line/Point Style ─────────────────────────────────────────────────────

    // -- setLineWidth --
    /// Sets the line width for outline drawing.
    /// @param width : number
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

    // -- getLineWidth --
    /// Returns the current line width.
    /// @return number
    let s = state.clone();
    graphics.set(
        "getLineWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().line_width))?,
    )?;

    // -- setPointSize --
    /// Sets the point diameter in pixels.
    /// @param size : number
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

    // -- getPointSize --
    /// Returns the current point size.
    /// @return number
    let s = state.clone();
    graphics.set(
        "getPointSize",
        lua.create_function(move |_, ()| Ok(s.borrow().point_size))?,
    )?;

    // ── Blend Mode ───────────────────────────────────────────────────────────

    // -- setBlendMode --
    /// Sets the blend mode for drawing.
    /// @param mode : string
    let s = state.clone();
    graphics.set(
        "setBlendMode",
        lua.create_function(move |_, mode: String| {
            let bm = match mode.as_str() {
                "add" => BlendMode::Add,
                "multiply" => BlendMode::Multiply,
                "replace" => BlendMode::Replace,
                "screen" => BlendMode::Screen,
                _ => BlendMode::Alpha,
            };
            let mut st = s.borrow_mut();
            st.blend_mode = bm;
            st.draw_commands.push(DrawCommand::SetBlendMode(bm));
            Ok(())
        })?,
    )?;

    // -- getBlendMode --
    /// Returns the current blend mode as a string.
    /// @return string
    let s = state.clone();
    graphics.set(
        "getBlendMode",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let name = match st.blend_mode {
                BlendMode::Alpha => "alpha",
                BlendMode::Add => "add",
                BlendMode::Multiply => "multiply",
                BlendMode::Replace => "replace",
                BlendMode::Screen => "screen",
            };
            Ok(name.to_string())
        })?,
    )?;

    // ── Font Management ──────────────────────────────────────────────────────

    // -- newFont --
    /// Loads a TTF/OTF font from a file.
    /// @param path : string
    /// @param size : number?
    /// @return Font
    let s = state.clone();
    graphics.set(
        "newFont",
        lua.create_function(move |_, (path, size): (String, Option<f32>)| {
            let size = size.unwrap_or(14.0);
            let mut st = s.borrow_mut();
            let full_path = st.game_dir.join(&path);
            let data = std::fs::read(&full_path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "luna.graphics.newFont: failed to read '{}': {}",
                    path, e
                ))
            })?;
            let font = Font::from_bytes(&data, size)
                .map_err(|e| LuaError::RuntimeError(format!("luna.graphics.newFont: {}", e)))?;
            let key = st.fonts.insert(font);
            Ok(LuaFont {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // -- setFont --
    /// Sets the active font for print calls.
    /// @param font : Font
    let s = state.clone();
    graphics.set(
        "setFont",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
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

    // -- getFont --
    /// Returns the currently active font, or nil.
    /// @return Font?
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

    // -- getFontWidth --
    /// Returns the pixel width of text in the given font.
    /// @param font : Font
    /// @param text : string
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontWidth",
        lua.create_function(move |_, (ud, text): (LuaAnyUserData, String)| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let mut st = s.borrow_mut();
            let f = st.fonts.get_mut(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.getFontWidth: font handle is not valid".into(),
                )
            })?;
            Ok(f.text_width(&text))
        })?,
    )?;

    // -- getFontHeight --
    /// Returns the line height of the given font.
    /// @param font : Font
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontHeight",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.getFontHeight: font handle is not valid".into(),
                )
            })?;
            Ok(f.line_height())
        })?,
    )?;

    // -- getFontAscent --
    /// Returns the ascent of the given font.
    /// @param font : Font
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontAscent",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.getFontAscent: font handle is not valid".into(),
                )
            })?;
            Ok(f.ascent())
        })?,
    )?;

    // -- getFontDescent --
    /// Returns the descent of the given font.
    /// @param font : Font
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontDescent",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.getFontDescent: font handle is not valid".into(),
                )
            })?;
            Ok(f.descent())
        })?,
    )?;

    // -- getFontWrap --
    /// Returns wrapped lines and the maximum line width.
    /// @param text : string
    /// @param limit : number
    /// @return table, number
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
                    return Ok((LuaValue::Table(tbl), LuaValue::Number(max_w as f64)));
                }
            }
            Ok((LuaValue::Nil, LuaValue::Number(0.0)))
        })?,
    )?;

    // ── Image Management ─────────────────────────────────────────────────────

    // -- newImage --
    /// Loads an image from a file path or creates one from ImageData.
    /// @param path_or_data : string|ImageData
    /// @return Image
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
                let img_data = ud.borrow::<ImageData>()?;
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

    // ── Canvas Management ────────────────────────────────────────────────────

    // -- newCanvas --
    /// Creates an off-screen render canvas.
    /// @param width : integer
    /// @param height : integer
    /// @return Canvas
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
            let key = st.canvases.insert(Canvas::new(width, height));
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

    // -- setCanvas --
    /// Sets the active render target to a Canvas, or back to the screen.
    /// @param canvas : Canvas?
    let s = state.clone();
    graphics.set(
        "setCanvas",
        lua.create_function(move |_, ud: Option<LuaAnyUserData>| {
            let mut st = s.borrow_mut();
            match ud {
                Some(u) => {
                    let c = u.borrow::<LuaCanvas>()?;
                    let key = c.key;
                    drop(c);
                    if !st.canvases.contains_key(key) {
                        return Err(LuaError::RuntimeError(
                            "luna.graphics.setCanvas: canvas handle is not valid".into(),
                        ));
                    }
                    st.active_canvas = Some(key);
                    st.draw_commands.push(DrawCommand::SetCanvas(Some(key)));
                }
                None => {
                    st.active_canvas = None;
                    st.draw_commands.push(DrawCommand::SetCanvas(None));
                }
            }
            Ok(())
        })?,
    )?;

    // -- getCanvas --
    /// Returns the current canvas, or nil if drawing to screen.
    /// @return Canvas?
    let s = state.clone();
    graphics.set(
        "getCanvas",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            match st.active_canvas {
                Some(key) => Ok(Some(LuaCanvas {
                    state: s.clone(),
                    key,
                })),
                None => Ok(None),
            }
        })?,
    )?;

    // -- getCanvasSize --
    /// Returns the dimensions of a canvas.
    /// @param canvas : Canvas
    /// @return integer, integer
    let s = state.clone();
    graphics.set(
        "getCanvasSize",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let canvas = ud.borrow::<LuaCanvas>()?;
            let key = canvas.key;
            drop(canvas);
            let st = s.borrow();
            let c = st.canvases.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "luna.graphics.getCanvasSize: canvas handle is not valid".into(),
                )
            })?;
            Ok((c.width, c.height))
        })?,
    )?;

    // ── SpriteBatch ──────────────────────────────────────────────────────────

    // -- newSpriteBatch --
    /// Creates a new sprite batch for the given image.
    /// @param image : Image
    /// @param max_sprites : integer?
    /// @return SpriteBatch
    let s = state.clone();
    graphics.set(
        "newSpriteBatch",
        lua.create_function(move |_, (ud, max): (LuaAnyUserData, Option<usize>)| {
            let img = ud.borrow::<LuaImage>()?;
            let img_key = img.key;
            drop(img);
            let max_entries = max.unwrap_or(1000);
            let mut st = s.borrow_mut();
            if !st.textures.contains_key(img_key) {
                return Err(LuaError::RuntimeError(
                    "luna.graphics.newSpriteBatch: image handle is not valid".into(),
                ));
            }
            let batch = SpriteBatch::new(img_key, max_entries);
            let key = st.sprite_batches.insert(batch);
            Ok(LuaSpriteBatch {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // ── Mesh ─────────────────────────────────────────────────────────────────

    // -- newMesh --
    /// Creates a custom mesh from vertex data.
    /// @param vertices : table
    /// @param mode : string?
    /// @return Mesh
    let s = state.clone();
    graphics.set(
        "newMesh",
        lua.create_function(move |_, (verts, mode): (LuaTable, Option<String>)| {
            let draw_mode = match mode.as_deref() {
                Some("fan") => MeshDrawMode::Fan,
                Some("strip") => MeshDrawMode::Strip,
                _ => MeshDrawMode::Triangles,
            };
            let mut vertices = Vec::new();
            for vert in verts.sequence_values::<LuaTable>() {
                let v = vert?;
                vertices.push(MeshVertex {
                    x: v.get(1).unwrap_or(0.0),
                    y: v.get(2).unwrap_or(0.0),
                    u: v.get(3).unwrap_or(0.0),
                    v: v.get(4).unwrap_or(0.0),
                    r: v.get(5).unwrap_or(1.0),
                    g: v.get(6).unwrap_or(1.0),
                    b: v.get(7).unwrap_or(1.0),
                    a: v.get(8).unwrap_or(1.0),
                });
            }
            let mesh = Mesh::from_vertices(vertices, draw_mode);
            let mut st = s.borrow_mut();
            let mesh_clone = mesh.clone();
            let key = st.meshes.insert(mesh);
            st.draw_commands.push(DrawCommand::SyncMesh {
                mesh_key: key,
                mesh: mesh_clone,
            });
            Ok(LuaMesh {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // ── Shader ───────────────────────────────────────────────────────────────

    // -- newShader --
    /// Compiles a custom WGSL shader and returns its handle.
    /// @param code : string
    /// @return Shader
    let s = state.clone();
    graphics.set(
        "newShader",
        lua.create_function(move |_, code: String| {
            let shader = Shader::new(code).map_err(|err| {
                LuaError::RuntimeError(format!("luna.graphics.newShader: {}", err))
            })?;
            let key = s.borrow_mut().shaders.insert(shader);
            Ok(LuaShader {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // -- setShader --
    /// Sets the active shader, or clears it.
    /// @param shader : Shader?
    let s = state.clone();
    graphics.set(
        "setShader",
        lua.create_function(move |_, ud: Option<LuaAnyUserData>| {
            let mut st = s.borrow_mut();
            match ud {
                Some(u) => {
                    let sh = u.borrow::<LuaShader>()?;
                    let key = sh.key;
                    drop(sh);
                    if !st.shaders.contains_key(key) {
                        return Err(LuaError::RuntimeError(
                            "luna.graphics.setShader: shader handle is not valid".into(),
                        ));
                    }
                    st.active_shader = Some(key);
                    st.draw_commands
                        .push(DrawCommand::SetShader(Some(key)));
                }
                None => {
                    st.active_shader = None;
                    st.draw_commands.push(DrawCommand::SetShader(None));
                }
            }
            Ok(())
        })?,
    )?;

    // -- getShader --
    /// Returns the active shader, or nil.
    /// @return Shader?
    let s = state.clone();
    graphics.set(
        "getShader",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            match st.active_shader {
                Some(key) => Ok(Some(LuaShader {
                    state: s.clone(),
                    key,
                })),
                None => Ok(None),
            }
        })?,
    )?;

    // ── Quad ─────────────────────────────────────────────────────────────────

    // -- newQuad --
    /// Creates a new Quad viewport into a texture.
    /// @param x : number
    /// @param y : number
    /// @param w : number
    /// @param h : number
    /// @param sw : number
    /// @param sh : number
    /// @return Quad
    #[allow(clippy::type_complexity)]
    graphics.set(
        "newQuad",
        lua.create_function(
            move |_, (x, y, w, h, sw, sh): (f32, f32, f32, f32, f32, f32)| {
                Ok(LuaQuad {
                    x,
                    y,
                    w,
                    h,
                    sw,
                    sh,
                })
            },
        )?,
    )?;

    // ── Transform Stack ──────────────────────────────────────────────────────

    // -- push --
    /// Pushes the current transform onto the stack.
    let s = state.clone();
    graphics.set(
        "push",
        lua.create_function(move |_, ()| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::PushTransform);
            Ok(())
        })?,
    )?;

    // -- pop --
    /// Pops the transform from the stack.
    let s = state.clone();
    graphics.set(
        "pop",
        lua.create_function(move |_, ()| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::PopTransform);
            Ok(())
        })?,
    )?;

    // -- translate --
    /// Translates the coordinate system.
    /// @param x : number
    /// @param y : number
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

    // -- rotate --
    /// Rotates the coordinate system.
    /// @param angle : number
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

    // -- scale --
    /// Scales the coordinate system.
    /// @param sx : number
    /// @param sy : number?
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

    // -- shear --
    /// Shears the coordinate system.
    /// @param kx : number
    /// @param ky : number
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

    // -- origin --
    /// Resets the transform to the identity.
    let s = state.clone();
    graphics.set(
        "origin",
        lua.create_function(move |_, ()| {
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::Origin);
            Ok(())
        })?,
    )?;

    // -- applyTransform --
    /// Applies an affine transform matrix.
    /// @param matrix : table
    let s = state.clone();
    graphics.set(
        "applyTransform",
        lua.create_function(move |_, mat: LuaTable| {
            let mut m = [0.0f32; 9];
            for (i, item) in m.iter_mut().enumerate() {
                *item = mat.get::<_, f32>(i + 1).unwrap_or(if i == 0 || i == 4 || i == 8 {
                    1.0
                } else {
                    0.0
                });
            }
            s.borrow_mut()
                .draw_commands
                .push(DrawCommand::ApplyTransform { matrix: m });
            Ok(())
        })?,
    )?;

    // ── Scissor ──────────────────────────────────────────────────────────────

    // -- setScissor --
    /// Restricts drawing to a rectangle, or clears scissor if no args.
    /// @param x : number?
    /// @param y : number?
    /// @param w : number?
    /// @param h : number?
    let s = state.clone();
    graphics.set(
        "setScissor",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();
            if args.len() >= 4 {
                let to_f32 = |v: &LuaValue| match v {
                    LuaValue::Number(n) => *n as f32,
                    LuaValue::Integer(n) => *n as f32,
                    _ => 0.0,
                };
                let x = to_f32(&args[0]);
                let y = to_f32(&args[1]);
                let w = to_f32(&args[2]);
                let h = to_f32(&args[3]);
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

    // -- getScissor --
    /// Returns the active scissor rectangle, or nothing.
    /// @return number?, number?, number?, number?
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

    // -- intersectScissor --
    /// Intersects the current scissor with a new rectangle.
    /// @param x : number
    /// @param y : number
    /// @param w : number
    /// @param h : number
    let s = state.clone();
    graphics.set(
        "intersectScissor",
        lua.create_function(move |_, (x, y, w, h): (f32, f32, f32, f32)| {
            let mut st = s.borrow_mut();
            let new = Rect::new(x, y, w, h);
            let result = st.scissor.map(|(cx, cy, cw, ch)| Rect::new(cx, cy, cw, ch).intersect(&new));
            let tuple = result.map(|r| (r.x, r.y, r.width, r.height)).or(Some((x, y, w, h)));
            st.scissor = tuple;
            st.draw_commands.push(DrawCommand::SetScissor(tuple));
            Ok(())
        })?,
    )?;

    // ── Color Mask ───────────────────────────────────────────────────────────

    // -- setColorMask --
    /// Sets which RGBA channels are written. Reset with no args.
    /// @param r : boolean?
    /// @param g : boolean?
    /// @param b : boolean?
    /// @param a : boolean?
    let s = state.clone();
    graphics.set(
        "setColorMask",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();
            if args.len() >= 4 {
                let to_bool = |v: &LuaValue| matches!(v, LuaValue::Boolean(true));
                let r = to_bool(&args[0]);
                let g = to_bool(&args[1]);
                let b = to_bool(&args[2]);
                let a = to_bool(&args[3]);
                st.color_mask = (r, g, b, a);
                st.draw_commands.push(DrawCommand::SetColorMask(r, g, b, a));
            } else {
                st.color_mask = (true, true, true, true);
                st.draw_commands
                    .push(DrawCommand::SetColorMask(true, true, true, true));
            }
            Ok(())
        })?,
    )?;

    // -- getColorMask --
    /// Returns the current color mask.
    /// @return boolean, boolean, boolean, boolean
    let s = state.clone();
    graphics.set(
        "getColorMask",
        lua.create_function(move |_, ()| Ok(s.borrow().color_mask))?,
    )?;

    // ── Wireframe ────────────────────────────────────────────────────────────

    // -- setWireframe --
    /// Enables or disables wireframe rendering.
    /// @param enabled : boolean
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

    // -- isWireframe --
    /// Returns whether wireframe mode is active.
    /// @return boolean
    let s = state.clone();
    graphics.set(
        "isWireframe",
        lua.create_function(move |_, ()| Ok(s.borrow().wireframe))?,
    )?;

    // ── Stencil ──────────────────────────────────────────────────────────────

    // -- stencil --
    /// Begins stencil writing with the given action and value.
    /// @param action : string?
    /// @param value : integer?
    let s = state.clone();
    graphics.set(
        "stencil",
        lua.create_function(move |_, (action, value): (Option<String>, Option<u8>)| {
            let act = match action.as_deref() {
                Some("zero") => StencilAction::Zero,
                Some("increment") => StencilAction::Increment,
                Some("decrement") => StencilAction::Decrement,
                Some("incrementwrap") => StencilAction::IncrementWrap,
                Some("decrementwrap") => StencilAction::DecrementWrap,
                Some("invert") => StencilAction::Invert,
                Some("keep") => StencilAction::Keep,
                _ => StencilAction::Replace,
            };
            let val = value.unwrap_or(1);
            let mut st = s.borrow_mut();
            st.draw_commands
                .push(DrawCommand::StencilBegin { action: act, value: val });
            Ok(())
        })?,
    )?;

    // -- setStencilTest --
    /// Sets the stencil comparison test, or disables stencil testing.
    /// @param compare : string?
    /// @param value : integer?
    let s = state.clone();
    graphics.set(
        "setStencilTest",
        lua.create_function(move |_, (compare, value): (Option<String>, Option<u8>)| {
            let mut st = s.borrow_mut();
            match compare {
                Some(cmp) => {
                    let mode = match cmp.as_str() {
                        "equal" => CompareMode::Equal,
                        "notequal" => CompareMode::NotEqual,
                        "less" => CompareMode::Less,
                        "lequal" | "lessequal" => CompareMode::LessEqual,
                        "greater" => CompareMode::Greater,
                        "gequal" | "greaterequal" => CompareMode::GreaterEqual,
                        "always" => CompareMode::Always,
                        "never" => CompareMode::Never,
                        _ => CompareMode::Always,
                    };
                    st.draw_commands
                        .push(DrawCommand::SetStencilTest(Some((mode, value.unwrap_or(1)))));
                }
                None => {
                    st.draw_commands
                        .push(DrawCommand::SetStencilTest(None));
                }
            }
            Ok(())
        })?,
    )?;

    // ── Window Dimensions ────────────────────────────────────────────────────

    // -- getWidth --
    /// Returns the window width in pixels.
    /// @return integer
    let s = state.clone();
    graphics.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    // -- getHeight --
    /// Returns the window height in pixels.
    /// @return integer
    let s = state.clone();
    graphics.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    // -- getDimensions --
    /// Returns window width and height.
    /// @return integer, integer
    let s = state.clone();
    graphics.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // ── Default Filter ───────────────────────────────────────────────────────

    // -- setDefaultFilter --
    /// Sets the default texture filter mode.
    /// @param min : string
    /// @param mag : string
    /// @param anisotropy : integer?
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

    // -- getDefaultFilter --
    /// Returns the default texture filter mode.
    /// @return string, string, integer
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

    // ── Stats ────────────────────────────────────────────────────────────────

    // -- getStats --
    /// Returns a table of renderer statistics.
    /// @return table
    let s = state.clone();
    graphics.set(
        "getStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let r = st.compute_stats();
            let stats = lua.create_table()?;
            stats.set("drawcalls", r.draw_calls)?;
            stats.set("textures", r.textures)?;
            stats.set("fonts", r.fonts)?;
            stats.set("canvases", r.canvases)?;
            stats.set("texture_memory", r.texture_memory)?;
            Ok(stats)
        })?,
    )?;

    // ── Screenshot ───────────────────────────────────────────────────────────

    // -- saveScreenshot --
    /// Queues a screenshot to be saved after the current frame.
    /// @param path : string
    let s = state.clone();
    graphics.set(
        "saveScreenshot",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().pending_screenshot = Some(ScreenshotRequest { path });
            Ok(())
        })?,
    )?;

    luna.set("graphics", graphics)?;
    Ok(())
}
