//! `lurek.graphic` — 2D drawing, images, fonts, canvases, meshes, shaders and sprite batches.

use super::SharedState;
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;

use crate::image::ImageData;
use crate::image::Texture;
use crate::math::Rect;
use crate::render::shape::{CompoundShape, ShapeCommand};
use crate::render::sprite_batch::BatchEntry;
use crate::render::{
    BlendMode, Canvas, CompareMode, DepthMode, DrawMode, Font, Mesh, MeshDrawMode, MeshVertex,
    RenderCommand, Shader, StencilAction, StencilMode, TextAlign, UniformValue,
};
use crate::runtime::resource_keys::*;
use crate::runtime::ScreenshotRequest;
use crate::sprite::SpriteBatch;

// ===============================================================================
// UserData wrapper types
// ===============================================================================

// -------------------------------------------------------------------------------
// LuaImage UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a loaded texture stored in SharedState.
///
/// Lua-side wrapper around a raw [`ImageData`] pixel buffer (e.g. from `captureScreenshot`).
pub struct LuaImageData {
    pub(crate) inner: ImageData,
}

impl LuaUserData for LuaImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the pixel width of this image buffer.
        /// @return integer
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        /// Returns the pixel height of this image buffer.
        /// @return integer
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        /// Returns the type name "ImageData".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("ImageData"));
        /// Returns true when the given name matches "ImageData" or a parent type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ImageData" || name == "Object")
        });
    }
}

/// Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
/// Fields: state (Rc<RefCell<SharedState>>), key (TextureKey).
#[derive(Clone)]
pub struct LuaImage {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: TextureKey,
}

/// Lua-side 9-slice descriptor.
///
/// Stores the texture key and four inset distances (top, right, bottom, left).
#[derive(Clone)]
pub struct LuaNineSlice {
    key: TextureKey,
    tex_w: u32,
    tex_h: u32,
    top: f32,
    right: f32,
    bottom: f32,
    left: f32,
}

impl LuaUserData for LuaNineSlice {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getInsets --
        /// Returns the four inset values as (top, right, bottom, left).
        /// @return number, number, number, number
        methods.add_method("getInsets", |_, this, ()| {
            Ok((this.top, this.right, this.bottom, this.left))
        });
        // -- getTextureSize --
        /// Returns the width and height of the source texture.
        /// @return integer, integer
        methods.add_method("getTextureSize", |_, this, ()| Ok((this.tex_w, this.tex_h)));
        // -- draw --
        /// Compatibility stub: queuing handled by lurek.graphic.drawNineSlice.
        /// @return nil
        methods.add_method(
            "draw",
            |_, _, (_x, _y, _w, _h): (f32, f32, f32, f32)| Ok(()),
        );
        /// Returns the type name "NineSlice".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("NineSlice"));
        /// Returns true when the given name matches "NineSlice" or a parent type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "NineSlice" || name == "Object")
        });
    }
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
                st.released_texture_handles.insert(this.key.data().as_ffi());
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
/// Fields: state (Rc<RefCell<SharedState>>), key (FontKey).
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
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
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
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
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
/// Fields: state (Rc<RefCell<SharedState>>), key (CanvasKey).
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
                    st.render_commands.push(RenderCommand::SetCanvas(None));
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
/// Fields: state (Rc<RefCell<SharedState>>), key (SpriteBatchKey).
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
                    LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
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
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
            })?;
            Ok(batch.len())
        });

        // -- getBufferSize --
        /// Returns the maximum capacity of this batch.
        /// @return integer
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
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
/// Fields: state (Rc<RefCell<SharedState>>), key (MeshKey).
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
            let v = mesh
                .get_vertex(index.wrapping_sub(1))
                .ok_or_else(|| LuaError::RuntimeError("Mesh vertex index out of bounds".into()))?;
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
            st.render_commands.push(RenderCommand::SyncMesh {
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
/// Fields: state (Rc<RefCell<SharedState>>), key (ShaderKey).
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
/// Fields: x (f32), y (f32), w (f32), h (f32), sw (f32), sh (f32).
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
        methods.add_method_mut(
            "setViewport",
            |_, this, (x, y, w, h): (f32, f32, f32, f32)| {
                this.x = x;
                this.y = y;
                this.w = w;
                this.h = h;
                Ok(())
            },
        );

        // -- getTextureDimensions --
        /// Returns the reference texture dimensions.
        /// @return number, number
        methods.add_method("getTextureDimensions", |_, this, ()| Ok((this.sw, this.sh)));

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

// -------------------------------------------------------------------------------
// LuaShape UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
///
/// Created via `lurek.graphic.newShape()`. Builder methods accumulate draw commands
/// in the backing slot; `shape:draw(x, y)` queues a `DrawShape` command each frame.
#[derive(Clone)]
pub struct LuaShape {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShapeKey,
}

impl LuaUserData for LuaShape {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getCommandCount --
        /// Returns the number of drawing commands currently stored.
        /// @return integer
        methods.add_method("getCommandCount", |_, this, ()| {
            let st = this.state.borrow();
            let shape = st.shapes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            Ok(shape.command_count() as i64)
        });

        // -- clear --
        /// Removes all commands and resets the shape to empty.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.clear();
            Ok(())
        });

        // -- setColor --
        /// Sets the drawing color for subsequent primitives.
        /// @param r : number   red [0,1]
        /// @param g : number   green [0,1]
        /// @param b : number   blue [0,1]
        /// @param a : number?  alpha [0,1], default 1
        methods.add_method(
            "setColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::SetColor(r, g, b, a.unwrap_or(1.0)));
                Ok(())
            },
        );

        // -- setLineWidth --
        /// Sets the stroke width for subsequent outlined primitives.
        /// @param w : number  width in pixels
        /// @return nil
        methods.add_method("setLineWidth", |_, this, w: f32| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.push_command(ShapeCommand::SetLineWidth(w));
            Ok(())
        });

        // -- rectangle --
        /// Queues a rectangle command.
        /// @param mode : string  "fill" or "line"
        /// @param x    : number
        /// @param y    : number
        /// @param w    : number
        /// @param h    : number
        methods.add_method(
            "rectangle",
            |_, this, (mode, x, y, w, h): (String, f32, f32, f32, f32)| {
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Rectangle {
                    mode: dm,
                    x,
                    y,
                    w,
                    h,
                });
                Ok(())
            },
        );

        // -- roundedRectangle --
        /// Queues a rounded rectangle command.
        /// @param mode : string  "fill" or "line"
        /// @param x    : number
        /// @param y    : number
        /// @param w    : number
        /// @param h    : number
        /// @param rx   : number  horizontal corner radius
        /// @param ry   : number?  vertical corner radius (default = rx)
        methods.add_method(
            "roundedRectangle",
            |_, this, (mode, x, y, w, h, rx, ry): (String, f32, f32, f32, f32, f32, Option<f32>)| {
                let dm = if mode == "line" { DrawMode::Line } else { DrawMode::Fill };
                let ry = ry.unwrap_or(rx);
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::RoundedRectangle { mode: dm, x, y, w, h, rx, ry });
                Ok(())
            },
        );

        // -- circle --
        /// Queues a circle command.
        /// @param mode : string  "fill" or "line"
        /// @param x    : number  centre X
        /// @param y    : number  centre Y
        /// @param r    : number  radius
        methods.add_method(
            "circle",
            |_, this, (mode, x, y, r): (String, f32, f32, f32)| {
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Circle { mode: dm, x, y, r });
                Ok(())
            },
        );

        // -- ellipse --
        /// Queues an ellipse command.
        /// @param mode : string  "fill" or "line"
        /// @param x    : number  centre X
        /// @param y    : number  centre Y
        /// @param rx   : number  horizontal radius
        /// @param ry   : number  vertical radius
        methods.add_method(
            "ellipse",
            |_, this, (mode, x, y, rx, ry): (String, f32, f32, f32, f32)| {
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Ellipse {
                    mode: dm,
                    x,
                    y,
                    rx,
                    ry,
                });
                Ok(())
            },
        );

        // -- triangle --
        /// Queues a triangle command.
        /// @param mode : string  "fill" or "line"
        /// @param x1   : number
        /// @param y1   : number
        /// @param x2   : number
        /// @param y2   : number
        /// @param x3   : number
        /// @param y3   : number
        methods.add_method(
            "triangle",
            |_, this, (mode, x1, y1, x2, y2, x3, y3): (String, f32, f32, f32, f32, f32, f32)| {
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Triangle {
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
        );

        // -- polygon --
        /// Queues a polygon command from variadic (x, y) coordinate pairs.
        /// @param mode : string   "fill" or "line"
        /// @param ...  : number   flat x1, y1, x2, y2, … (minimum 6 numbers = 3 vertices)
        methods.add_method(
            "polygon",
            |_, this, (mode, coords): (String, mlua::Variadic<f32>)| {
                let vertices: Vec<f32> = coords.into_iter().collect();
                if vertices.len() < 6 {
                    return Err(LuaError::RuntimeError(
                        "polygon requires at least 3 vertices (6 coordinate values)".into(),
                    ));
                }
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Polygon { mode: dm, vertices });
                Ok(())
            },
        );

        // -- line --
        /// Queues a line segment command.
        /// @param x1 : number
        /// @param y1 : number
        /// @param x2 : number
        /// @param y2 : number
        /// @return nil
        methods.add_method("line", |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.push_command(ShapeCommand::Line { x1, y1, x2, y2 });
            Ok(())
        });

        // -- polyline --
        /// Queues a polyline command from variadic (x, y) coordinate pairs.
        /// @param ... : number  flat x1, y1, x2, y2, … (minimum 4 numbers = 2 points)
        /// @return nil
        methods.add_method("polyline", |_, this, coords: mlua::Variadic<f32>| {
            let points: Vec<f32> = coords.into_iter().collect();
            if points.len() < 4 {
                return Err(LuaError::RuntimeError(
                    "polyline requires at least 2 points (4 coordinate values)".into(),
                ));
            }
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.push_command(ShapeCommand::Polyline { points });
            Ok(())
        });

        // -- arc --
        /// Queues an arc command.
        /// @param mode     : string   "fill" or "line"
        /// @param x        : number   centre X
        /// @param y        : number   centre Y
        /// @param r        : number   radius
        /// @param astart   : number   start angle in radians
        /// @param aend     : number   end angle in radians
        /// @param segments : integer?  curve resolution (default 32)
        methods.add_method(
            "arc",
            |_,
             this,
             (mode, x, y, r, astart, aend, segments): (
                String,
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<u32>,
            )| {
                let dm = if mode == "line" {
                    DrawMode::Line
                } else {
                    DrawMode::Fill
                };
                let mut st = this.state.borrow_mut();
                let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                    LuaError::RuntimeError("Shape handle is stale or was released".into())
                })?;
                shape.push_command(ShapeCommand::Arc {
                    mode: dm,
                    x,
                    y,
                    radius: r,
                    angle1: astart,
                    angle2: aend,
                    segments: segments.unwrap_or(32),
                });
                Ok(())
            },
        );

        // -- draw --
        /// Queues a draw command for this shape at the given position.
        ///
        /// Must be called from a `lurek.render` or `lurek.render_ui` callback.
        /// @param x        : number   world X
        /// @param y        : number   world Y
        /// @param rotation : number?  radians, default 0
        /// @param sx       : number?  horizontal scale, default 1
        /// @param sy       : number?  vertical scale, default 1
        /// @param ox       : number?  origin X (object space), default 0
        /// @param oy       : number?  origin Y (object space), default 0
        methods.add_method(
            "draw",
            |_,
             this,
             (x, y, rotation, sx, sy, ox, oy): (
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                this.state
                    .borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawShape {
                        shape_key: this.key,
                        x,
                        y,
                        rotation: rotation.unwrap_or(0.0),
                        sx: sx.unwrap_or(1.0),
                        sy: sy.unwrap_or(1.0),
                        ox: ox.unwrap_or(0.0),
                        oy: oy.unwrap_or(0.0),
                    });
                Ok(())
            },
        );

        // -- typeOf --
        /// Returns true if the given type name matches this object's type or any parent type.
        /// @param name : string  type name to test
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Shape" || name == "Object")
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Shape"));
    }
}

// -------------------------------------------------------------------------------
// LuaDrawLayer UserData
// -------------------------------------------------------------------------------

/// Lua-side z-ordered draw queue. Callbacks are sorted by z and called on `flush()`.
struct LuaDrawLayer {
    entries: Vec<(f64, LuaRegistryKey)>,
}

impl LuaUserData for LuaDrawLayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Queues a draw callback at the given z-order.
        /// @param z : number
        /// @param fn : function
        /// @return nil
        methods.add_method_mut("queue", |lua, this, (z, f): (f64, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            this.entries.push((z, key));
            Ok(())
        });

        /// Sorts and calls all queued callbacks, then empties the queue.
        /// @return nil
        methods.add_method_mut("flush", |lua, this, ()| {
            this.entries
                .sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(std::cmp::Ordering::Equal));
            let entries: Vec<_> = this.entries.drain(..).collect();
            for (_, key) in entries {
                let f = lua.registry_value::<LuaFunction>(&key)?;
                lua.remove_registry_value(key)?;
                f.call::<_, ()>(())?;
            }
            Ok(())
        });

        /// Removes all queued callbacks without calling them.
        /// @return void
        methods.add_method_mut("clear", |lua, this, ()| {
            for (_, key) in this.entries.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        /// Returns the number of queued callbacks.
        /// @return number
        methods.add_method("getCount", |_, this, ()| Ok(this.entries.len() as i64));

        /// Returns the type name.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("DrawLayer"));

        /// Returns true if this object is an instance of the given type name.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "DrawLayer" || name == "Object")
        });
    }
}

// ===============================================================================
// Registration
// ===============================================================================

/// Registers the `lurek.graphic` namespace on the given Lua table.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
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
            st.render_commands.push(RenderCommand::SetColor(r, g, b, a));
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
                            .render_commands
                            .push(RenderCommand::RoundedRectangle {
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
                            .render_commands
                            .push(RenderCommand::Rectangle {
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
            s.borrow_mut().render_commands.push(RenderCommand::Circle {
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
        lua.create_function(
            move |_, (mode, x, y, rx, ry): (String, f32, f32, f32, f32)| {
                s.borrow_mut().render_commands.push(RenderCommand::Ellipse {
                    mode: parse_draw_mode(&mode),
                    x,
                    y,
                    rx,
                    ry,
                });
                Ok(())
            },
        )?,
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
                    .render_commands
                    .push(RenderCommand::Triangle {
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
                s.borrow_mut().render_commands.push(RenderCommand::Line {
                    x1: vals[0],
                    y1: vals[1],
                    x2: vals[2],
                    y2: vals[3],
                });
            } else if vals.len() >= 4 {
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::Polyline { points: vals });
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
            s.borrow_mut().render_commands.push(RenderCommand::Polygon {
                mode: parse_draw_mode(&mode_str),
                vertices,
            });
            Ok(())
        })?,
    )?;

    // -- arc --
    /// Draws a partial circle arc at the given position with specified radius and angle range.
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
                s.borrow_mut().render_commands.push(RenderCommand::Arc {
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
                .render_commands
                .push(RenderCommand::Points { points });
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
                                "lurek.graphic.draw: image handle is not valid".into(),
                            ));
                        }
                        if has_transform {
                            st.render_commands.push(RenderCommand::DrawImageEx {
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
                            st.render_commands.push(RenderCommand::DrawImage {
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
                                "lurek.graphic.draw: canvas handle is not valid".into(),
                            ));
                        }
                        st.render_commands.push(RenderCommand::DrawCanvas {
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
                                "lurek.graphic.draw: sprite batch handle is not valid".into(),
                            ));
                        }
                        st.render_commands
                            .push(RenderCommand::DrawBatch { batch_key: key });
                        return Ok(());
                    }
                    if let Ok(mesh) = ud.borrow::<LuaMesh>() {
                        let key = mesh.key;
                        drop(mesh);
                        if !st.meshes.contains_key(key) {
                            return Err(LuaError::RuntimeError(
                                "lurek.graphic.draw: mesh handle is not valid".into(),
                            ));
                        }
                        st.render_commands.push(RenderCommand::DrawMesh {
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
                        "lurek.graphic.draw: expected Image, Canvas, SpriteBatch, or Mesh".into(),
                    ))
                }
                LuaValue::Nil => Err(LuaError::RuntimeError(
                    "lurek.graphic.draw: drawable cannot be nil".into(),
                )),
                _ => Err(LuaError::RuntimeError(
                    "lurek.graphic.draw: unsupported drawable type".into(),
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
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawQuad {
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
                // Use active_font, falling back to the built-in default bitmap font.
                let font_key = s.borrow().active_font.or(s.borrow().default_font);
                match font_key {
                    Some(font_key) => {
                        s.borrow_mut().render_commands.push(RenderCommand::Print {
                            font_key,
                            text,
                            x,
                            y,
                            scale,
                        });
                    }
                    None => {
                        // No font available — skip rendering.
                        log::warn!("lurek.graphic.print: no font loaded, text not rendered");
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
                let active_font = s
                    .borrow()
                    .active_font
                    .or(s.borrow().default_font)
                    .or(s.borrow().default_font);
                if let Some(font_key) = active_font {
                    s.borrow_mut()
                        .render_commands
                        .push(RenderCommand::PrintFormatted {
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
                s.borrow_mut().render_commands.clear();
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
            st.render_commands.push(RenderCommand::SetLineWidth(w));
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
            st.render_commands.push(RenderCommand::SetPointSize(size));
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
            st.render_commands.push(RenderCommand::SetBlendMode(bm));
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
    /// Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
    /// @param path_or_size : string|number
    /// @param size : number?
    /// @return Font
    let s = state.clone();
    graphics.set(
        "newFont",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();

            // Handle: newFont(number) — select built-in by pixel height
            if let Some(LuaValue::Number(n)) = args.get(0) {
                let height = *n as u32;
                let idx = crate::render::Font::nearest_size(height);
                if let Some(key) = st.default_fonts[idx] {
                    return Ok(LuaFont {
                        state: s.clone(),
                        key,
                    });
                }
                return Err(LuaError::RuntimeError(
                    "lurek.graphic.newFont: built-in fonts not loaded".into(),
                ));
            }

            // Handle: newFont(integer) — select built-in by pixel height
            if let Some(LuaValue::Integer(n)) = args.get(0) {
                let height = *n as u32;
                let idx = crate::render::Font::nearest_size(height);
                if let Some(key) = st.default_fonts[idx] {
                    return Ok(LuaFont {
                        state: s.clone(),
                        key,
                    });
                }
                return Err(LuaError::RuntimeError(
                    "lurek.graphic.newFont: built-in fonts not loaded".into(),
                ));
            }

            // Handle: newFont(string) or newFont(string, number)
            let path = match args.get(0) {
                Some(LuaValue::String(s)) => s
                    .to_str()
                    .map_err(|e| {
                        LuaError::RuntimeError(format!(
                            "lurek.graphic.newFont: invalid path: {}",
                            e
                        ))
                    })?
                    .to_string(),
                _ => {
                    return Err(LuaError::RuntimeError(
                        "lurek.graphic.newFont: expected string path or number size".into(),
                    ))
                }
            };

            let size = match args.get(1) {
                Some(LuaValue::Number(n)) => *n as f32,
                Some(LuaValue::Integer(n)) => *n as f32,
                _ => 14.0,
            };

            // "default" keyword
            if path == "default" {
                let idx = crate::render::Font::nearest_size(size as u32);
                if let Some(key) = st.default_fonts[idx] {
                    return Ok(LuaFont {
                        state: s.clone(),
                        key,
                    });
                }
            }

            // Try loading as a PNG bitmap font from file
            let full_path = st.game_dir.join(&path);
            let data = std::fs::read(&full_path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "lurek.graphic.newFont: failed to read '{}': {}",
                    path, e
                ))
            })?;
            let cell_h = size as u32;
            let cell_w = (size * 0.6).round() as u32;
            let font = Font::from_png_bytes(&data, cell_w, cell_h, false)
                .map_err(|e| LuaError::RuntimeError(format!("lurek.graphic.newFont: {}", e)))?;
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
                    "lurek.graphic.setFont: font handle is not valid or was released".into(),
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

    // -- getFontSizes --
    /// Returns a table of available built-in font pixel heights.
    /// @return table
    graphics.set(
        "getFontSizes",
        lua.create_function(|lua, ()| {
            let tbl = lua.create_table()?;
            for (i, &h) in crate::render::font::AVAILABLE_HEIGHTS.iter().enumerate() {
                tbl.set(i + 1, h)?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- getDefaultFont --
    /// Returns a built-in font by pixel height (snaps to nearest available size).
    /// @param pixel_height : number?
    /// @return Font
    let s = state.clone();
    graphics.set(
        "getDefaultFont",
        lua.create_function(move |_, pixel_height: Option<u32>| {
            let height = pixel_height.unwrap_or(14);
            let idx = crate::render::Font::nearest_size(height);
            let st = s.borrow();
            if let Some(key) = st.default_fonts[idx] {
                Ok(LuaFont {
                    state: s.clone(),
                    key,
                })
            } else {
                Err(LuaError::RuntimeError(
                    "lurek.graphic.getDefaultFont: built-in fonts not loaded".into(),
                ))
            }
        })?,
    )?;

    // -- getFontCellWidth --
    /// Returns the cell width of the given font (for monospaced bitmap fonts).
    /// @param font : Font
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontCellWidth",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "lurek.graphic.getFontCellWidth: font handle is not valid".into(),
                )
            })?;
            Ok(f.cell_width())
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
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "lurek.graphic.getFontWidth: font handle is not valid".into(),
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
                    "lurek.graphic.getFontHeight: font handle is not valid".into(),
                )
            })?;
            Ok(f.line_height())
        })?,
    )?;

    // -- getFontLineHeight --
    /// Returns the line height of the given font (alias for getFontHeight).
    /// @param font : Font
    /// @return number
    let s = state.clone();
    graphics.set(
        "getFontLineHeight",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let font = ud.borrow::<LuaFont>()?;
            let key = font.key;
            drop(font);
            let st = s.borrow();
            let f = st.fonts.get(key).ok_or_else(|| {
                LuaError::RuntimeError(
                    "lurek.graphic.getFontLineHeight: font handle is not valid".into(),
                )
            })?;
            Ok(f.line_height())
        })?,
    )?;

    // -- setFontLineHeight --
    /// Sets the line height of the given font (stub — returns nil; fonts are immutable in headless mode).
    /// @param font : Font
    /// @param line_height : number
    /// @return nil
    graphics.set(
        "setFontLineHeight",
        lua.create_function(|_, (_font, _lh): (LuaAnyUserData, f32)| Ok(()))?,
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
                    "lurek.graphic.getFontAscent: font handle is not valid".into(),
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
                    "lurek.graphic.getFontDescent: font handle is not valid".into(),
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
            let st = s.borrow();
            if let Some(font_key) = st.active_font {
                if let Some(font) = st.fonts.get(font_key) {
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
                    LuaError::RuntimeError(format!("lurek.graphic.newImage: invalid path: {}", e))
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
                        "lurek.graphic.newImage: failed to load '{}': {}",
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
                        "lurek.graphic.newImage: failed to create from ImageData: {}",
                        e
                    ))),
                }
            }
            _ => Err(LuaError::RuntimeError(
                "lurek.graphic.newImage: expected a file path string or ImageData".into(),
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
                    "lurek.graphic.newCanvas: width and height must be greater than zero".into(),
                ));
            }
            let mut st = s.borrow_mut();
            let key = st.canvases.insert(Canvas::new(width, height));
            st.render_commands.push(RenderCommand::RegisterCanvas {
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
                            "lurek.graphic.setCanvas: canvas handle is not valid".into(),
                        ));
                    }
                    st.active_canvas = Some(key);
                    st.render_commands.push(RenderCommand::SetCanvas(Some(key)));
                }
                None => {
                    st.active_canvas = None;
                    st.render_commands.push(RenderCommand::SetCanvas(None));
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
                    "lurek.graphic.getCanvasSize: canvas handle is not valid".into(),
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
                    "lurek.graphic.newSpriteBatch: image handle is not valid".into(),
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
            let rows: Vec<[f32; 8]> = verts
                .sequence_values::<LuaTable>()
                .map(|vert| {
                    let v = vert?;
                    Ok([
                        v.get(1).unwrap_or(0.0),
                        v.get(2).unwrap_or(0.0),
                        v.get(3).unwrap_or(0.0),
                        v.get(4).unwrap_or(0.0),
                        v.get(5).unwrap_or(1.0),
                        v.get(6).unwrap_or(1.0),
                        v.get(7).unwrap_or(1.0),
                        v.get(8).unwrap_or(1.0),
                    ])
                })
                .collect::<LuaResult<_>>()?;
            let mesh = Mesh::from_vertex_rows(&rows, draw_mode);
            let mut st = s.borrow_mut();
            let mesh_clone = mesh.clone();
            let key = st.meshes.insert(mesh);
            st.render_commands.push(RenderCommand::SyncMesh {
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
                LuaError::RuntimeError(format!("lurek.graphic.newShader: {}", err))
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
                            "lurek.graphic.setShader: shader handle is not valid".into(),
                        ));
                    }
                    st.active_shader = Some(key);
                    st.render_commands.push(RenderCommand::SetShader(Some(key)));
                }
                None => {
                    st.active_shader = None;
                    st.render_commands.push(RenderCommand::SetShader(None));
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
                Ok(LuaQuad { x, y, w, h, sw, sh })
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
                .render_commands
                .push(RenderCommand::PushTransform);
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
                .render_commands
                .push(RenderCommand::PopTransform);
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
                .render_commands
                .push(RenderCommand::Translate { x, y });
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
                .render_commands
                .push(RenderCommand::Rotate { angle });
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
                .render_commands
                .push(RenderCommand::Scale { sx, sy });
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
                .render_commands
                .push(RenderCommand::Shear { kx, ky });
            Ok(())
        })?,
    )?;

    // -- origin --
    /// Resets the transform to the identity.
    let s = state.clone();
    graphics.set(
        "origin",
        lua.create_function(move |_, ()| {
            s.borrow_mut().render_commands.push(RenderCommand::Origin);
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
                *item = mat
                    .get::<_, f32>(i + 1)
                    .unwrap_or(if i == 0 || i == 4 || i == 8 { 1.0 } else { 0.0 });
            }
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::ApplyTransform { matrix: m });
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
                st.render_commands
                    .push(RenderCommand::SetScissor(Some((x, y, w, h))));
            } else {
                st.scissor = None;
                st.render_commands.push(RenderCommand::SetScissor(None));
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
            let result = st
                .scissor
                .map(|(cx, cy, cw, ch)| Rect::new(cx, cy, cw, ch).intersect(&new));
            let tuple = result
                .map(|r| (r.x, r.y, r.width, r.height))
                .or(Some((x, y, w, h)));
            st.scissor = tuple;
            st.render_commands.push(RenderCommand::SetScissor(tuple));
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
                st.render_commands
                    .push(RenderCommand::SetColorMask(r, g, b, a));
            } else {
                st.color_mask = (true, true, true, true);
                st.render_commands
                    .push(RenderCommand::SetColorMask(true, true, true, true));
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
            st.render_commands
                .push(RenderCommand::SetWireframe(enabled));
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
            st.render_commands.push(RenderCommand::StencilBegin {
                action: act,
                value: val,
            });
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
                    st.render_commands.push(RenderCommand::SetStencilTest(Some((
                        mode,
                        value.unwrap_or(1),
                    ))));
                }
                None => {
                    st.render_commands.push(RenderCommand::SetStencilTest(None));
                }
            }
            Ok(())
        })?,
    )?;

    // ── Window Dimensions ────────────────────────────────────────────────────

    // -- setStencilMode --
    /// Sets the stencil buffer write/test mode.
    /// @param action : string   — "keep"|"zero"|"replace"|"increment"|"decrement"|"invert"
    /// @param compare : string? — "always"|"equal"|"notequal"|"less"|"lequal"|"greater"|"gequal"
    /// @param value : integer?  — reference value (0–255)
    let s = state.clone();
    graphics.set(
        "setStencilMode",
        lua.create_function(
            move |_, (action, compare, value): (String, Option<String>, Option<u8>)| {
                let sa = match action.as_str() {
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
                            "unknown stencil action: {other}"
                        )))
                    }
                };
                let cmp = match compare.as_deref().unwrap_or("always") {
                    "always" => CompareMode::Always,
                    "never" => CompareMode::Never,
                    "equal" => CompareMode::Equal,
                    "notequal" => CompareMode::NotEqual,
                    "less" => CompareMode::Less,
                    "lequal" | "lessequal" => CompareMode::LessEqual,
                    "greater" => CompareMode::Greater,
                    "gequal" | "greaterequal" => CompareMode::GreaterEqual,
                    _ => CompareMode::Always,
                };
                s.borrow_mut().stencil_mode = StencilMode {
                    action: sa,
                    compare: cmp,
                    value: value.unwrap_or(0),
                };
                Ok(())
            },
        )?,
    )?;

    // -- getStencilMode --
    /// Returns the current stencil mode as (action, compare, value).
    /// @return string, string, integer
    let s = state.clone();
    graphics.set(
        "getStencilMode",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let sm = st.stencil_mode;
            let action = match sm.action {
                StencilAction::Keep => "keep",
                StencilAction::Zero => "zero",
                StencilAction::Replace => "replace",
                StencilAction::Increment => "increment",
                StencilAction::Decrement => "decrement",
                StencilAction::IncrementWrap => "incrementwrap",
                StencilAction::DecrementWrap => "decrementwrap",
                StencilAction::Invert => "invert",
            };
            let compare = match sm.compare {
                CompareMode::Always => "always",
                CompareMode::Never => "never",
                CompareMode::Equal => "equal",
                CompareMode::NotEqual => "notequal",
                CompareMode::Less => "less",
                CompareMode::LessEqual => "lequal",
                CompareMode::Greater => "greater",
                CompareMode::GreaterEqual => "gequal",
            };
            Ok((action, compare, sm.value as i64))
        })?,
    )?;

    // -- clearStencil --
    /// Resets the stencil mode to the default (keep / always / 0).
    /// @return nil
    let s = state.clone();
    graphics.set(
        "clearStencil",
        lua.create_function(move |_, ()| {
            s.borrow_mut().stencil_mode = StencilMode::default();
            Ok(())
        })?,
    )?;

    // -- setDepthMode --
    /// Sets the depth test comparison and write enable.
    /// @param mode : string  — "always"|"never"|"less"|"lequal"|"equal"|"notequal"|"greater"|"gequal"
    /// @param write : boolean? — default false
    let s = state.clone();
    graphics.set(
        "setDepthMode",
        lua.create_function(move |_, (mode, write): (String, Option<bool>)| {
            let dm = match mode.as_str() {
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
                        "unknown depth mode: {other}"
                    )))
                }
            };
            s.borrow_mut().depth_mode = (dm, write.unwrap_or(false));
            Ok(())
        })?,
    )?;

    // -- getDepthMode --
    /// Returns the current depth mode as (mode, write).
    /// @return string, boolean
    let s = state.clone();
    graphics.set(
        "getDepthMode",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let (dm, write) = st.depth_mode;
            let mode = match dm {
                DepthMode::Always => "always",
                DepthMode::Never => "never",
                DepthMode::Less => "less",
                DepthMode::LessEqual => "lequal",
                DepthMode::Equal => "equal",
                DepthMode::NotEqual => "notequal",
                DepthMode::Greater => "greater",
                DepthMode::GreaterEqual => "gequal",
            };
            Ok((mode, write))
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
            // GPU-level stats from the actual renderer
            stats.set("gpu_draw_calls", st.render_stats.draw_calls)?;
            stats.set("batched_draws", st.render_stats.batched_draws)?;
            stats.set("texture_switches", st.render_stats.texture_switches)?;
            stats.set("canvas_switches", st.render_stats.canvas_switches)?;
            stats.set("shader_switches", st.render_stats.shader_switches)?;
            Ok(stats)
        })?,
    )?;

    // ── Screenshot ───────────────────────────────────────────────────────────

    // -- saveScreenshot --
    /// Queues a screenshot to be saved after the current frame.
    /// The path must start with "save/".
    /// @param path : string
    let s = state.clone();
    graphics.set(
        "saveScreenshot",
        lua.create_function(move |_, path: String| {
            if !path.starts_with("save/") {
                return Err(LuaError::RuntimeError(format!(
                    "saveScreenshot: path must start with \"save/\" (got \"{}\")",
                    path
                )));
            }
            s.borrow_mut().pending_screenshot = Some(ScreenshotRequest { path });
            Ok(())
        })?,
    )?;

    // -- captureScreenshot --
    /// Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
    /// @param callback : function(ImageData)
    /// @return nil
    graphics.set(
        "captureScreenshot",
        lua.create_function(|lua, callback: LuaFunction| {
            let img = ImageData::new(1, 1);
            let ud = lua.create_userdata(LuaImageData { inner: img })?;
            callback.call::<_, ()>(ud)?;
            Ok(())
        })?,
    )?;

    // -- newNineSlice --
    /// Creates a 9-slice descriptor from a texture and inset values.
    /// @param image : Image
    /// @param top : number
    /// @param right : number
    /// @param bottom : number
    /// @param left : number
    /// @return NineSlice
    graphics.set(
        "newNineSlice",
        lua.create_function(
            |_, (image, top, right, bottom, left): (LuaAnyUserData, f32, f32, f32, f32)| {
                if top < 0.0 || right < 0.0 || bottom < 0.0 || left < 0.0 {
                    return Err(LuaError::RuntimeError(
                        "newNineSlice: border insets must be non-negative".into(),
                    ));
                }
                let img = image.borrow::<LuaImage>()?;
                let state = img.state.borrow();
                let (tex_w, tex_h) = state
                    .textures
                    .get(img.key)
                    .map(|t| (t.width, t.height))
                    .unwrap_or((0, 0));
                Ok(LuaNineSlice {
                    key: img.key,
                    tex_w,
                    tex_h,
                    top,
                    right,
                    bottom,
                    left,
                })
            },
        )?,
    )?;

    // -- drawNineSlice --
    /// Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
    /// @param slice : NineSlice
    /// @param x : number
    /// @param y : number
    /// @param width : number
    /// @param height : number
    /// @return nil
    let s = state.clone();
    graphics.set(
        "drawNineSlice",
        lua.create_function(
            move |_, (slice, x, y, w, h): (LuaAnyUserData, f32, f32, f32, f32)| {
                let ns = slice.borrow::<LuaNineSlice>()?;
                let key = ns.key;
                let (top, right, bottom, left) = (ns.top, ns.right, ns.bottom, ns.left);
                drop(ns);
                let mut st = s.borrow_mut();
                let (tex_w, tex_h) = st
                    .textures
                    .get(key)
                    .map(|t| (t.width as f32, t.height as f32))
                    .unwrap_or((1.0, 1.0));
                st.render_commands.push(RenderCommand::DrawNineSlice {
                    texture_key: key,
                    tex_w,
                    tex_h,
                    top,
                    right,
                    bottom,
                    left,
                    x,
                    y,
                    w,
                    h,
                });
                Ok(())
            },
        )?,
    )?;

    // -- newShape --
    /// Creates a new empty [`CompoundShape`] stored in the resource pool.
    ///
    /// Build up primitives with `shape:rectangle()`, `shape:circle()`, etc.
    /// Call `shape:draw(x, y)` inside `lurek.render` or `lurek.render_ui` to
    /// replay all commands with a unified affine transform each frame.
    ///
    /// @return Shape
    let s = state.clone();
    graphics.set(
        "newShape",
        lua.create_function(move |_, ()| {
            let key = s.borrow_mut().shapes.insert(CompoundShape::new());
            Ok(LuaShape {
                state: s.clone(),
                key,
            })
        })?,
    )?;

    // -- newDrawLayer --
    /// Creates a new z-ordered draw-call queue.
    /// @return DrawLayer
    graphics.set(
        "newDrawLayer",
        lua.create_function(|_, ()| {
            Ok(LuaDrawLayer {
                entries: Vec::new(),
            })
        })?,
    )?;

    luna.set("graphic", graphics)?;
    Ok(())
}
