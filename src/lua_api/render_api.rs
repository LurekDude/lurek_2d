//! `lurek.render` - Provides 2D drawing primitives, texture rendering, text output, blend modes, and render state management.
use super::SharedState;
use crate::image::ImageData;
use crate::image::Texture;
use crate::image::TextureColorSpace;
use crate::math::Rect;
use crate::render::renderer::{BevelStyle, GradientDirection, HexOrientation, PathSegment};
use crate::render::shape::{CompoundShape, ShapeCommand};
use crate::render::{
    BlendMode, Canvas, CompareMode, DepthMode, DrawMode, Font, Mesh, MeshDrawMode, MeshVertex,
    RenderCommand, Shader, StencilAction, StencilMode, TextAlign, UniformValue,
};
use crate::runtime::resource_keys::*;
use crate::runtime::ScreenshotRequest;
use crate::sprite::sprite_batch::BatchEntry;
use crate::sprite::SpriteBatch;
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;
/// Raw pixel buffer for CPU-side image manipulation before uploading to a GPU texture.
pub struct LuaImageData {
    pub(crate) inner: ImageData,
}
impl LuaUserData for LuaImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of this image data in pixels.
        /// @return | number | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));
        // -- getHeight --
        /// Returns the height of this image data in pixels.
        /// @return | number | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        // -- resize --
        /// Creates a new ImageData resized to the given dimensions using bilinear sampling.
        /// @param | w | integer | Target width in pixels.
        /// @param | h | integer | Target height in pixels.
        /// @return | LImageData | A new resized ImageData, or nil if the operation failed.
        methods.add_method("resize", |lua, this, (w, h): (u32, u32)| {
            match this.inner.resize(w, h) {
                Some(img) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaImageData { inner: img })?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- blit --
        /// Copies pixel data from another ImageData onto this one at the specified position.
        /// @param | source | LImageData | The source image data to copy from.
        /// @param | dstX | integer | Destination X offset in pixels.
        /// @param | dstY | integer | Destination Y offset in pixels.
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<LuaImageData>()?;
                this.inner.blit(&src_ref.inner, dst_x, dst_y);
                Ok(())
            },
        );
        // -- getRegion --
        /// Extracts a rectangular sub-region as a new ImageData.
        /// @param | x | integer | Top-left X coordinate of the region.
        /// @param | y | integer | Top-left Y coordinate of the region.
        /// @param | w | integer | Width of the region in pixels.
        /// @param | h | integer | Height of the region in pixels.
        /// @return | LImageData | A new ImageData for the region, or nil if out of bounds.
        methods.add_method(
            "getRegion",
            |lua, this, (x, y, w, h): (u32, u32, u32, u32)| match this.inner.get_region(x, y, w, h)
            {
                Some(img) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaImageData { inner: img })?,
                )),
                None => Ok(LuaValue::Nil),
            },
        );
        // -- diff --
        /// Computes a numeric difference score between this image and another of the same size.
        /// @param | other | LImageData | The image data to compare against.
        /// @return | number | Sum of per-pixel absolute color differences (0 = identical).
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<LuaImageData>()?;
            Ok(this.inner.diff(&other_ref.inner))
        });
        // -- mapPixels --
        /// Iterates over every pixel and replaces its color with the return value of the callback.
        /// @param | callback | function | Called as callback(x, y, r, g, b, a) → (r, g, b, a) for each pixel.
        methods.add_method_mut("mapPixels", |_lua, this, callback: LuaFunction| {
            let w = this.inner.width();
            let h = this.inner.height();
            for py in 0..h {
                for px in 0..w {
                    if let Some((r, g, b, a)) = this.inner.get_pixel(px, py) {
                        let result: (u8, u8, u8, u8) = callback.call((px, py, r, g, b, a))?;
                        this.inner
                            .set_pixel(px, py, result.0, result.1, result.2, result.3);
                    }
                }
            }
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LImageData".
        methods.add_method("type", |_, _, ()| Ok("LImageData"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check ("ImageData" or "Object").
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ImageData" || name == "Object")
        });
    }
}
/// GPU-backed texture handle used for drawing images to screen.
#[derive(Clone)]
pub struct LuaImage {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: TextureKey,
}
/// Texture with defined border insets for scalable 9-slice rendering (e.g., UI panels, buttons).
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
        /// Returns the border insets (top, right, bottom, left) that define the stretchable regions.
        /// @return | number, number, number, number | Top, right, bottom, left inset values.
        methods.add_method("getInsets", |_, this, ()| {
            Ok((this.top, this.right, this.bottom, this.left))
        });
        // -- getTextureSize --
        /// Returns the pixel dimensions of the underlying source texture.
        /// @return | number, number | Width and height in pixels.
        methods.add_method("getTextureSize", |_, this, ()| Ok((this.tex_w, this.tex_h)));
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LNineSlice".
        methods.add_method("type", |_, _, ()| Ok("LNineSlice"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check ("NineSlice" or "Object").
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "NineSlice" || name == "Object")
        });
    }
}
impl LuaUserData for LuaImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the internal numeric handle ID for this image.
        /// @return | number | Opaque image handle identifier.
        methods.add_method("getId", |_, this, ()| Ok(this.key.data().as_ffi()));
        // -- getWidth --
        /// Returns the width of this image in pixels.
        /// @return | number | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.width)
        });
        // -- getHeight --
        /// Returns the height of this image in pixels.
        /// @return | number | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.height)
        });
        // -- getDimensions --
        /// Returns both width and height of this image.
        /// @return | number, number | Width and height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok((td.width, td.height))
        });
        // -- release --
        /// Releases the GPU memory for this image. The handle becomes invalid after this call.
        /// @return | boolean | True if the image was still valid and was released.
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
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Image".
        methods.add_method("typeOf", |_, _, ()| Ok("Image"));
        // -- type --
        /// Returns the type name string for this image object.
        /// @return | string | Always "LImage".
        methods.add_method("type", |_, _, ()| Ok("LImage"));
    }
}
/// Bitmap font handle for measuring and rendering text.
#[derive(Clone)]
pub struct LuaFont {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: FontKey,
}
impl LuaUserData for LuaFont {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Measures the pixel width of a string when rendered with this font.
        /// @param | text | string | The text to measure.
        /// @return | number | Width in pixels.
        methods.add_method("getWidth", |_, this, text: String| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.text_width(&text))
        });
        // -- getHeight --
        /// Returns the line height of this font in pixels.
        /// @return | number | Line height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });
        // -- getLineHeight --
        /// Returns the spacing between consecutive lines of text.
        /// @return | number | Line height in pixels.
        methods.add_method("getLineHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });
        // -- setLineHeight --
        /// Overrides the line height used for multi-line text rendering.
        /// @param | height | number | New line height in pixels.
        methods.add_method("setLineHeight", |_, this, height: f32| {
            let mut st = this.state.borrow_mut();
            let font = st.fonts.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            font.set_line_height(height);
            Ok(())
        });
        // -- getAscent --
        /// Returns the ascent (pixels above the baseline) of this font.
        /// @return | number | Ascent in pixels.
        methods.add_method("getAscent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.ascent())
        });
        // -- getDescent --
        /// Returns the descent (pixels below the baseline) of this font.
        /// @return | number | Descent in pixels (positive value extending downward).
        methods.add_method("getDescent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.descent())
        });
        // -- getWrap --
        /// Word-wraps text to fit within a pixel width limit and returns the resulting lines.
        /// @param | text | string | The text to wrap.
        /// @param | limit | number | Maximum line width in pixels.
        /// @return | table, number | Array of wrapped line strings, and the widest line width.
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
        /// Releases the font resource. The handle becomes invalid after this call.
        /// @return | boolean | True if the font was still valid and was released.
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
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Font".
        methods.add_method("typeOf", |_, _, ()| Ok("Font"));
        // -- type --
        /// Returns the type name string for this font object.
        /// @return | string | Always "LFont".
        methods.add_method("type", |_, _, ()| Ok("LFont"));
    }
}
/// Off-screen render target that can be drawn to and then composited onto the screen.
#[derive(Clone)]
pub struct LuaCanvas {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: CanvasKey,
}
impl LuaUserData for LuaCanvas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of this canvas in pixels.
        /// @return | number | Width in pixels.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.width)
        });
        // -- getHeight --
        /// Returns the height of this canvas in pixels.
        /// @return | number | Height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.height)
        });
        // -- getDimensions --
        /// Returns both width and height of this canvas.
        /// @return | number, number | Width and height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok((c.width, c.height))
        });
        // -- release --
        /// Releases the canvas GPU resource. If this canvas is currently active, drawing reverts to the screen.
        /// @return | boolean | True if the canvas was still valid and was released.
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
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Canvas".
        methods.add_method("typeOf", |_, _, ()| Ok("Canvas"));
        // -- type --
        /// Returns the type name string for this canvas object.
        /// @return | string | Always "LCanvas".
        methods.add_method("type", |_, _, ()| Ok("LCanvas"));
    }
}
/// Batched sprite renderer for efficiently drawing many copies of the same texture.
#[derive(Clone)]
pub struct LuaSpriteBatch {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SpriteBatchKey,
}
impl LuaUserData for LuaSpriteBatch {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- add --
        /// Adds a sprite entry to the batch at the given position with optional transform.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | r | number? | Rotation in radians.
        /// @param | sx | number? | Scale X (default 1).
        /// @param | sy | number? | Scale Y (default 1).
        /// @param | ox | number? | Origin offset X.
        /// @param | oy | number? | Origin offset Y.
        /// @return | number | Index of the added entry.
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
        /// Removes all entries from the sprite batch.
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(batch) = st.sprite_batches.get_mut(this.key) {
                batch.clear();
            }
            Ok(())
        });
        // -- getCount --
        /// Returns the number of sprite entries currently in the batch.
        /// @return | number | Entry count.
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
            })?;
            Ok(batch.len())
        });
        // -- getBufferSize --
        /// Returns the maximum number of entries this batch can hold.
        /// @return | number | Buffer capacity.
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
            })?;
            Ok(batch.buffer_size())
        });
        // -- release --
        /// Releases the sprite batch resource.
        /// @return | boolean | True if the batch was valid and was released.
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.sprite_batches.remove(this.key).is_some())
        });
        // -- typeOf --
        /// Returns the type name of this object.
        /// @param | name | string | Type name to check.
        /// @return | string | Always "SpriteBatch".
        methods.add_method("typeOf", |_, _, ()| Ok("SpriteBatch"));
        // -- type --
        /// Returns the type name string for this sprite batch.
        /// @return | string | Always "LSpriteBatch".
        methods.add_method("type", |_, _, ()| Ok("LSpriteBatch"));
    }
}
/// Custom vertex mesh for advanced 2D geometry rendering with per-vertex color and UV data.
#[derive(Clone)]
pub struct LuaMesh {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: MeshKey,
}
impl LuaUserData for LuaMesh {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getVertexCount --
        /// Returns the number of vertices in this mesh.
        /// @return | number | Vertex count.
        methods.add_method("getVertexCount", |_, this, ()| {
            let st = this.state.borrow();
            let mesh = st.meshes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
            })?;
            Ok(mesh.vertex_count())
        });
        // -- getVertex --
        /// Returns the data for a single vertex by 1-based index.
        /// @param | index | integer | 1-based vertex index.
        /// @return | number, number, number, number, number, number, number, number | x, y, u, v, r, g, b, a.
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
        /// Updates a single vertex by 1-based index. Table format: {x, y, u, v, r, g, b, a}.
        /// @param | index | integer | 1-based vertex index.
        /// @param | data | table | Vertex data: {x, y, u, v, r, g, b, a}.
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
        /// Assigns or removes a texture for this mesh. Pass nil to clear the texture.
        /// @param | image | LImage? | Image to use as the mesh texture, or nil to remove.
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
        /// Releases the mesh GPU resource and invalidates the handle.
        /// @return | boolean | True if the mesh was valid and was released.
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.meshes.remove(this.key).is_some())
        });
        // -- typeOf --
        /// Returns the type name of this object.
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Mesh".
        methods.add_method("typeOf", |_, _, ()| Ok("Mesh"));
        // -- type --
        /// Returns the type name string for this mesh object.
        /// @return | string | Always "LMesh".
        methods.add_method("type", |_, _, ()| Ok("LMesh"));
    }
}
/// GPU shader program for custom rendering effects (post-processing, distortion, etc.).
#[derive(Clone)]
pub struct LuaShader {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShaderKey,
}
impl LuaUserData for LuaShader {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- send --
        /// Sends a uniform value to this shader by name. Supported types: number, boolean, or table (vec2/vec3/vec4).
        /// @param | name | string | Uniform variable name declared in the shader.
        /// @param | value | number|boolean|table | The value to send.
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
        /// Checks whether this shader declares a uniform with the given name.
        /// @param | name | string | Uniform name to check.
        /// @return | boolean | True if the uniform exists.
        methods.add_method("hasUniform", |_, this, name: String| {
            let st = this.state.borrow();
            let shader = st.shaders.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shader handle is not valid or was released".into())
            })?;
            Ok(shader.has_uniform(&name))
        });
        // -- release --
        /// Releases the shader resource. If active, the default shader is restored.
        /// @return | boolean | True if the shader was valid and was released.
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
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Shader".
        methods.add_method("typeOf", |_, _, ()| Ok("Shader"));
        // -- type --
        /// Returns the type name string for this shader object.
        /// @return | string | Always "LShader".
        methods.add_method("type", |_, _, ()| Ok("LShader"));
    }
}
/// Rectangular sub-region of a texture, used for sprite sheets and atlas-based rendering.
#[derive(Clone)]
pub struct LuaQuad {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
    pub sw: f32,
    pub sh: f32,
}
impl LuaUserData for LuaQuad {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getViewport --
        /// Returns the quad's viewport rectangle within the source texture.
        /// @return | number, number, number, number | x, y, width, height in texture pixels.
        methods.add_method("getViewport", |_, this, ()| {
            Ok((this.x, this.y, this.w, this.h))
        });
        // -- setViewport --
        /// Updates the quad's viewport rectangle.
        /// @param | x | number | Left edge in texture pixels.
        /// @param | y | number | Top edge in texture pixels.
        /// @param | w | number | Width in texture pixels.
        /// @param | h | number | Height in texture pixels.
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
        /// Returns the full dimensions of the source texture this quad references.
        /// @return | number, number | Source texture width and height.
        methods.add_method("getTextureDimensions", |_, this, ()| Ok((this.sw, this.sh)));
        // -- typeOf --
        /// Returns the type name of this object.
        /// @param | name | string | Type name to check.
        /// @return | string | Always "Quad".
        methods.add_method("typeOf", |_, _, ()| Ok("Quad"));
        // -- type --
        /// Returns the type name string for this quad object.
        /// @return | string | Always "LQuad".
        methods.add_method("type", |_, _, ()| Ok("LQuad"));
    }
}
/// Converts a Lua scalar or numeric table into a shader uniform payload supported by the renderer.
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
/// Parses a Lua shape draw mode string into the renderer draw mode enum.
fn parse_draw_mode(mode: &str) -> Result<DrawMode, LuaError> {
    match mode {
        "fill" => Ok(DrawMode::Fill),
        "line" => Ok(DrawMode::Line),
        other => Err(LuaError::RuntimeError(format!(
            "unknown draw mode: '{other}'"
        ))),
    }
}
/// Parses a Lua blend mode string into the renderer blend mode enum.
fn parse_blend_mode(s: &str) -> Result<BlendMode, LuaError> {
    match s {
        "alpha" => Ok(BlendMode::Alpha),
        "add" | "additive" => Ok(BlendMode::Add),
        "multiply" => Ok(BlendMode::Multiply),
        "replace" | "none" => Ok(BlendMode::Replace),
        "screen" => Ok(BlendMode::Screen),
        other => Err(LuaError::RuntimeError(format!(
            "unknown blend mode: '{other}'"
        ))),
    }
}
/// Retained compound shape that accumulates drawing commands and can be rendered in one call.
#[derive(Clone)]
pub struct LuaShape {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShapeKey,
}
impl LuaUserData for LuaShape {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getCommandCount --
        /// Returns the number of drawing commands accumulated in this shape.
        /// @return | number | Command count.
        methods.add_method("getCommandCount", |_, this, ()| {
            let st = this.state.borrow();
            let shape = st.shapes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            Ok(shape.command_count() as i64)
        });
        // -- clear --
        /// Removes all drawing commands from this shape, making it empty.
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.clear();
            Ok(())
        });
        // -- setColor --
        /// Sets the drawing color for subsequent shape commands.
        /// @param | r | number | Red channel (0–1).
        /// @param | g | number | Green channel (0–1).
        /// @param | b | number | Blue channel (0–1).
        /// @param | a | number? | Alpha channel (0–1, default 1).
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
        /// Sets the line width for subsequent line-mode shape commands.
        /// @param | w | number | Line width in pixels.
        methods.add_method("setLineWidth", |_, this, w: f32| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.push_command(ShapeCommand::SetLineWidth(w));
            Ok(())
        });
        // -- rectangle --
        /// Adds a rectangle command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x | number | Left edge X.
        /// @param | y | number | Top edge Y.
        /// @param | w | number | Width.
        /// @param | h | number | Height.
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
        /// Adds a rounded rectangle command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x | number | Left edge X.
        /// @param | y | number | Top edge Y.
        /// @param | w | number | Width.
        /// @param | h | number | Height.
        /// @param | rx | number | Horizontal corner radius.
        /// @param | ry | number? | Vertical corner radius (defaults to rx).
        methods.add_method("roundedRectangle", |_, this, (mode, x, y, w, h, rx, ry): (String, f32, f32, f32, f32, f32, Option<f32>)| {
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
        /// Adds a filled or outlined circle command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x | number | Center X.
        /// @param | y | number | Center Y.
        /// @param | r | number | Radius.
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
        /// Adds an ellipse command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x | number | Center X.
        /// @param | y | number | Center Y.
        /// @param | rx | number | Horizontal radius.
        /// @param | ry | number | Vertical radius.
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
        /// Adds a triangle command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x1 | number | First vertex X.
        /// @param | y1 | number | First vertex Y.
        /// @param | x2 | number | Second vertex X.
        /// @param | y2 | number | Second vertex Y.
        /// @param | x3 | number | Third vertex X.
        /// @param | y3 | number | Third vertex Y.
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
        /// Adds a polygon command to the shape from a flat list of x,y coordinate pairs.
        /// @param | mode | string | "fill" or "line".
        /// @param | ... | number | Flat coordinate values: x1, y1, x2, y2, ... (minimum 3 vertices / 6 values).
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
        /// Adds a line segment command to the shape.
        /// @param | x1 | number | Start X.
        /// @param | y1 | number | Start Y.
        /// @param | x2 | number | End X.
        /// @param | y2 | number | End Y.
        methods.add_method("line", |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            let mut st = this.state.borrow_mut();
            let shape = st.shapes.get_mut(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            shape.push_command(ShapeCommand::Line { x1, y1, x2, y2 });
            Ok(())
        });
        // -- polyline --
        /// Adds a connected polyline command to the shape from a flat list of x,y coordinate pairs.
        /// @param | ... | number | Flat coordinate values: x1, y1, x2, y2, ... (minimum 2 points / 4 values).
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
        /// Adds a filled or outlined arc command to the shape.
        /// @param | mode | string | "fill" or "line".
        /// @param | x | number | Center X.
        /// @param | y | number | Center Y.
        /// @param | r | number | Radius.
        /// @param | astart | number | Start angle in radians.
        /// @param | aend | number | End angle in radians.
        /// @param | segments | number? | Number of arc segments (default 32).
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
        /// Renders the accumulated shape commands to the screen with optional transform.
        /// @param | x | number | X position.
        /// @param | y | number | Y position.
        /// @param | rotation | number? | Rotation in radians (default 0).
        /// @param | sx | number? | Scale X (default 1).
        /// @param | sy | number? | Scale Y (default 1).
        /// @param | ox | number? | Origin offset X (default 0).
        /// @param | oy | number? | Origin offset Y (default 0).
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
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check ("Shape" or "Object").
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Shape" || name == "Object")
        });
        // -- type --
        /// Returns the type name string for this shape object.
        /// @return | string | Always "LShape".
        methods.add_method("type", |_, _, ()| Ok("LShape"));
    }
}
/// Z-ordered draw callback layer for sorting draw calls by depth before flushing.
struct LuaDrawLayer {
    entries: Vec<(f64, mlua::RegistryKey)>,
}
impl LuaUserData for LuaDrawLayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- queue --
        /// Enqueues a draw callback at the given z-depth. Callbacks execute when flush() is called.
        /// @param | z | number | Z-depth value used for sorting (lower draws first).
        /// @param | f | function | Callback to invoke during flush.
        methods.add_method_mut("queue", |lua, this, (z, f): (f64, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            this.entries.push((z, key));
            Ok(())
        });
        // -- flush --
        /// Sorts all queued callbacks by z-depth and executes them in order, then empties the layer.
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
        // -- clear --
        /// Discards all queued callbacks without executing them.
        methods.add_method_mut("clear", |lua, this, ()| {
            for (_, key) in this.entries.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- getCount --
        /// Returns the number of callbacks currently queued.
        /// @return | number | Queue length.
        methods.add_method("getCount", |_, this, ()| Ok(this.entries.len() as i64));
        // -- type --
        /// Returns the type name string for this draw layer.
        /// @return | string | Always "LDrawLayer".
        methods.add_method("type", |_, _, ()| Ok("LDrawLayer"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check ("LDrawLayer", "DrawLayer", or "Object").
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDrawLayer" || name == "DrawLayer" || name == "Object")
        });
    }
}
/// Registers the `lurek.render` module and all its functions and types into the Lua state.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;
    let s = state.clone();
    // -- setColor --
    /// Sets the active drawing color for all subsequent draw operations.
    /// @param | r | number | Red channel (0–1).
    /// @param | g | number | Green channel (0–1).
    /// @param | b | number | Blue channel (0–1).
    /// @param | a | number? | Alpha channel (0–1, default 1).
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
    let s = state.clone();
    // -- getColor --
    /// Returns the current drawing color.
    /// @return | number, number, number, number | Red, green, blue, alpha channels (0–1).
    graphics.set(
        "getColor",
        lua.create_function(move |_, ()| {
            let c = s.borrow().current_color;
            Ok((c[0], c[1], c[2], c[3]))
        })?,
    )?;
    let s = state.clone();
    // -- setBackgroundColor --
    /// Sets the background clear color used at the start of each frame.
    /// @param | r | number | Red channel (0–1).
    /// @param | g | number | Green channel (0–1).
    /// @param | b | number | Blue channel (0–1).
    graphics.set(
        "setBackgroundColor",
        lua.create_function(move |_, (r, g, b): (f32, f32, f32)| {
            s.borrow_mut().background_color = [r, g, b, 1.0];
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getBackgroundColor --
    /// Returns the current background clear color.
    /// @return | number, number, number, number | Red, green, blue, alpha channels (0–1).
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
    let s = state.clone();
    // -- rectangle --
    /// Draws a rectangle. If rx is provided, draws a rounded rectangle.
    /// @param | mode | string | "fill" or "line".
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Width.
    /// @param | h | number | Height.
    /// @param | rx | number? | Horizontal corner radius for rounded rectangle.
    /// @param | ry | number? | Vertical corner radius (defaults to rx).
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
                let dm = parse_draw_mode(&mode)?;
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
    let s = state.clone();
    // -- circle --
    /// Draws a filled or outlined circle at the given position.
    /// @param | mode | string | "fill" or "line".
    /// @param | x | number | Center X.
    /// @param | y | number | Center Y.
    /// @param | radius | number | Circle radius in pixels.
    graphics.set(
        "circle",
        lua.create_function(move |_, (mode, x, y, radius): (String, f32, f32, f32)| {
            s.borrow_mut().render_commands.push(RenderCommand::Circle {
                mode: parse_draw_mode(&mode)?,
                x,
                y,
                r: radius,
            });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- ellipse --
    /// Draws a filled or outlined ellipse at the given position.
    /// @param | mode | string | "fill" or "line".
    /// @param | x | number | Center X.
    /// @param | y | number | Center Y.
    /// @param | rx | number | Horizontal radius.
    /// @param | ry | number | Vertical radius.
    graphics.set(
        "ellipse",
        lua.create_function(
            move |_, (mode, x, y, rx, ry): (String, f32, f32, f32, f32)| {
                s.borrow_mut().render_commands.push(RenderCommand::Ellipse {
                    mode: parse_draw_mode(&mode)?,
                    x,
                    y,
                    rx,
                    ry,
                });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    // -- triangle --
    /// Draws a triangle from three vertex positions.
    /// @param | mode | string | "fill" or "line".
    /// @param | x1 | number | First vertex X.
    /// @param | y1 | number | First vertex Y.
    /// @param | x2 | number | Second vertex X.
    /// @param | y2 | number | Second vertex Y.
    /// @param | x3 | number | Third vertex X.
    /// @param | y3 | number | Third vertex Y.
    graphics.set(
        "triangle",
        lua.create_function(
            move |_, (mode, x1, y1, x2, y2, x3, y3): (String, f32, f32, f32, f32, f32, f32)| {
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::Triangle {
                        mode: parse_draw_mode(&mode)?,
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
    let s = state.clone();
    // -- line --
    /// Draws a line between two points, or a polyline through multiple points.
    /// @param | ... | number | Coordinate values: x1, y1, x2, y2 for a line, or more for a polyline.
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
    let s = state.clone();
    // -- polygon --
    /// Draws a polygon from a flat list of x,y vertex coordinates.
    /// @param | mode | string | "fill" or "line".
    /// @param | ... | number | Flat vertex coordinates: x1, y1, x2, y2, ... (minimum 3 vertices).
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
                mode: parse_draw_mode(&mode_str)?,
                vertices,
            });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    // -- arc --
    /// Draws a filled or outlined circular arc segment.
    /// @param | mode | string | "fill" or "line".
    /// @param | x | number | Center X.
    /// @param | y | number | Center Y.
    /// @param | radius | number | Arc radius.
    /// @param | angle1 | number | Start angle in radians.
    /// @param | angle2 | number | End angle in radians.
    /// @param | segments | number? | Number of arc segments (default 32).
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
                    mode: parse_draw_mode(&mode)?,
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
    let s = state.clone();
    // -- points --
    /// Draws one or more points. Accepts either a table of {x,y} pairs or flat x,y coordinate values.
    /// @param | ... | table|number | Point data as a table of {x,y} sub-tables, or flat x1,y1,x2,y2,... values.
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
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    // -- draw --
    /// Draws a drawable object (Image, Canvas, SpriteBatch, or Mesh) at the given position with optional transform.
    /// @param | drawable | LImage|LCanvas|LSpriteBatch|LMesh | The drawable object to render.
    /// @param | x | number? | X position (default 0).
    /// @param | y | number? | Y position (default 0).
    /// @param | r | number? | Rotation in radians (default 0).
    /// @param | sx | number? | Scale X (default 1).
    /// @param | sy | number? | Scale Y (default 1).
    /// @param | ox | number? | Origin offset X (default 0).
    /// @param | oy | number? | Origin offset Y (default 0).
    /// @return | nil | No return value.
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
    let s = state.clone();
    #[allow(clippy::type_complexity)]
    // -- drawq --
    /// Draws a sub-region of an image defined by a Quad, with optional transform.
    /// @param | image | LImage | Source image to draw from.
    /// @param | quad | LQuad | Quad defining the source rectangle within the image.
    /// @param | x | number? | X position (default 0).
    /// @param | y | number? | Y position (default 0).
    /// @param | r | number? | Rotation in radians (default 0).
    /// @param | sx | number? | Scale X (default 1).
    /// @param | sy | number? | Scale Y (default 1).
    /// @param | ox | number? | Origin offset X (default 0).
    /// @param | oy | number? | Origin offset Y (default 0).
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
    let s = state.clone();
    // -- drawMany --
    /// Batch-draws multiple images in one call. Each entry is a table: {image, x, y, r, sx, sy, ox, oy}.
    /// @param | list | table | Array of draw entry tables.
    graphics.set(
        "drawMany",
        lua.create_function(move |_, list: LuaTable| {
            let mut st = s.borrow_mut();
            let len = list.raw_len();
            for i in 1..=len {
                let entry: LuaTable = match list.raw_get(i) {
                    Ok(LuaValue::Table(t)) => t,
                    _ => continue,
                };
                let img_val: LuaValue = entry.raw_get(1).unwrap_or(LuaValue::Nil);
                let x: f32 = entry
                    .raw_get::<_, Option<f32>>(2)
                    .unwrap_or(None)
                    .unwrap_or(0.0);
                let y: f32 = entry
                    .raw_get::<_, Option<f32>>(3)
                    .unwrap_or(None)
                    .unwrap_or(0.0);
                let r: f32 = entry
                    .raw_get::<_, Option<f32>>(4)
                    .unwrap_or(None)
                    .unwrap_or(0.0);
                let sx: f32 = entry
                    .raw_get::<_, Option<f32>>(5)
                    .unwrap_or(None)
                    .unwrap_or(1.0);
                let sy: f32 = entry
                    .raw_get::<_, Option<f32>>(6)
                    .unwrap_or(None)
                    .unwrap_or(1.0);
                let ox: f32 = entry
                    .raw_get::<_, Option<f32>>(7)
                    .unwrap_or(None)
                    .unwrap_or(0.0);
                let oy: f32 = entry
                    .raw_get::<_, Option<f32>>(8)
                    .unwrap_or(None)
                    .unwrap_or(0.0);
                if let LuaValue::UserData(ud) = img_val {
                    if let Ok(img) = ud.borrow::<LuaImage>() {
                        let key = img.key;
                        drop(img);
                        if !st.textures.contains_key(key) {
                            continue;
                        }
                        let has_transform =
                            r != 0.0 || sx != 1.0 || sy != 1.0 || ox != 0.0 || oy != 0.0;
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
                    }
                }
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- printRotated --
    /// Draws text centered and rotated around its midpoint.
    /// @param | text | string | Text to render.
    /// @param | x | number | Center X position.
    /// @param | y | number | Center Y position.
    /// @param | angle | number | Rotation angle in radians.
    /// @param | scale | number? | Text scale factor (default 1).
    graphics.set(
        "printRotated",
        lua.create_function(
            move |_, (text, x, y, angle, scale): (String, f32, f32, f32, Option<f32>)| {
                let scale = scale.unwrap_or(1.0);
                let (font_key, origin_x, origin_y) = {
                    let st = s.borrow();
                    let font_key = st.active_font.or(st.default_font);
                    let Some(font_key) = font_key else {
                        return Ok(());
                    };
                    let Some(font) = st.fonts.get(font_key) else {
                        return Ok(());
                    };
                    let origin_x = -font.text_width(&text) * scale * 0.5;
                    let origin_y = -font.line_height() * scale * 0.5;
                    (font_key, origin_x, origin_y)
                };
                let st = &mut s.borrow_mut().render_commands;
                st.push(RenderCommand::PushTransform);
                st.push(RenderCommand::Translate { x, y });
                st.push(RenderCommand::Rotate { angle });
                st.push(RenderCommand::Print {
                    font_key,
                    text,
                    x: origin_x,
                    y: origin_y,
                    scale,
                });
                st.push(RenderCommand::PopTransform);
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- print --
    /// Draws text using the active font at the given position.
    /// @param | text | string | Text to render.
    /// @param | x | number? | X position (default 0).
    /// @param | y | number? | Y position (default 0).
    /// @param | scale | number? | Text scale factor (default 1).
    graphics.set(
        "print",
        lua.create_function(
            move |_, (text, x, y, scale): (String, Option<f32>, Option<f32>, Option<f32>)| {
                let x = x.unwrap_or(0.0);
                let y = y.unwrap_or(0.0);
                let scale = scale.unwrap_or(1.0);
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
                        log::warn!("lurek.graphic.print: no font loaded, text not rendered");
                    }
                }
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- printf --
    /// Draws word-wrapped and aligned text within a pixel-width limit.
    /// @param | text | string | Text to render.
    /// @param | x | number | X position.
    /// @param | y | number | Y position.
    /// @param | limit | number | Maximum line width in pixels for wrapping.
    /// @param | align | string? | Alignment: "left" (default), "center", "right", or "justify".
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
                let active_font = {
                    let st = s.borrow();
                    st.active_font.or(st.default_font)
                };
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
    let s = state.clone();
    // -- printRich --
    /// Draws rich text composed of individually styled spans at the given position.
    /// @param | spans | table | Array of span tables, each with fields: text, r, g, b, a, scale.
    /// @param | x | number | X position.
    /// @param | y | number | Y position.
    graphics.set(
        "printRich",
        lua.create_function(move |_, (spans_table, x, y): (mlua::Table, f32, f32)| {
            use crate::render::renderer::TextSpan;
            let font_key_opt = {
                let st = s.borrow();
                st.active_font.or(st.default_font)
            };
            let Some(font_key) = font_key_opt else {
                return Ok(());
            };
            let mut spans: Vec<TextSpan> = Vec::new();
            for pair in spans_table.pairs::<mlua::Value, mlua::Table>() {
                let (_, span_tbl) = pair.map_err(mlua::Error::external)?;
                let text: String = span_tbl.get::<_, String>("text").unwrap_or_default();
                let r: u8 = span_tbl.get::<_, u8>("r").unwrap_or(255);
                let g: u8 = span_tbl.get::<_, u8>("g").unwrap_or(255);
                let b: u8 = span_tbl.get::<_, u8>("b").unwrap_or(255);
                let a: u8 = span_tbl.get::<_, u8>("a").unwrap_or(255);
                let scale: f32 = span_tbl.get::<_, f32>("scale").unwrap_or(1.0);
                spans.push(TextSpan::new(text, r, g, b, a, scale));
            }
            s.borrow_mut().render_commands.push(
                crate::render::renderer::RenderCommand::DrawRichText {
                    font_key,
                    spans,
                    x,
                    y,
                },
            );
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- clear --
    /// Clears all queued render commands for the current frame.
    /// @param | r | number? | Unused (reserved for future clear-color override).
    /// @param | g | number? | Unused.
    /// @param | b | number? | Unused.
    graphics.set(
        "clear",
        lua.create_function(
            move |_, (_r, _g, _b): (Option<f32>, Option<f32>, Option<f32>)| {
                s.borrow_mut().render_commands.clear();
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- setLineWidth --
    /// Sets the line width for subsequent line-mode draw calls.
    /// @param | w | number | Line width in pixels.
    graphics.set(
        "setLineWidth",
        lua.create_function(move |_, w: f32| {
            let mut st = s.borrow_mut();
            st.line_width = w;
            st.render_commands.push(RenderCommand::SetLineWidth(w));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getLineWidth --
    /// Returns the current line width used for line-mode drawing.
    /// @return | number | Line width in pixels.
    graphics.set(
        "getLineWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().line_width))?,
    )?;
    let s = state.clone();
    // -- setPointSize --
    /// Sets the point size for subsequent point draw calls.
    /// @param | size | number | Point diameter in pixels.
    graphics.set(
        "setPointSize",
        lua.create_function(move |_, size: f32| {
            let mut st = s.borrow_mut();
            st.point_size = size;
            st.render_commands.push(RenderCommand::SetPointSize(size));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getPointSize --
    /// Returns the current point diameter used for point drawing.
    /// @return | number | Point diameter in pixels.
    graphics.set(
        "getPointSize",
        lua.create_function(move |_, ()| Ok(s.borrow().point_size))?,
    )?;
    let s = state.clone();
    // -- setBlendMode --
    /// Sets the blend mode for subsequent draw operations.
    /// @param | mode | string | One of: "alpha", "add", "multiply", "replace", "screen".
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
    let s = state.clone();
    // -- getBlendMode --
    /// Returns the current blend mode name.
    /// @return | string | Current blend mode: "alpha", "add", "multiply", "replace", or "screen".
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
    let s = state.clone();
    // -- newFont --
    /// Creates a new bitmap font from a PNG sprite sheet path or returns a built-in font by pixel height.
    /// @param | pathOrSize | string|number | File path to a PNG font sheet, or a pixel height for a built-in font.
    /// @param | size | number? | Cell height in pixels when loading from a file (default 14).
    /// @return | LFont | The created font handle.
    graphics.set(
        "newFont",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();
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
            if path == "default" {
                let idx = crate::render::Font::nearest_size(size as u32);
                if let Some(key) = st.default_fonts[idx] {
                    return Ok(LuaFont {
                        state: s.clone(),
                        key,
                    });
                }
            }
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
    let s = state.clone();
    // -- setFont --
    /// Sets the active font used by print, printf, and other text rendering calls.
    /// @param | font | LFont | Font handle to make active.
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
    let s = state.clone();
    // -- getFont --
    /// Returns the currently active font, or nil if none is set.
    /// @return | LFont | The active font handle.
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
    /// Returns all available built-in font pixel heights.
    /// @return | number[] | Array of available font height values.
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
    let s = state.clone();
    // -- getDefaultFont --
    /// Returns a built-in default font at the nearest available pixel height.
    /// @param | pixelHeight | integer? | Desired pixel height (default 14).
    /// @return | LFont | The built-in font handle.
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
    let s = state.clone();
    // -- getFontCellWidth --
    /// Returns the fixed cell width of a bitmap font.
    /// @param | font | LFont | Font handle to query.
    /// @return | number | Cell width in pixels.
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
    let s = state.clone();
    // -- getFontWidth --
    /// Measures the pixel width of text using the given font.
    /// @param | font | LFont | Font handle to measure with.
    /// @param | text | string | Text to measure.
    /// @return | number | Width in pixels.
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
    let s = state.clone();
    // -- getFontHeight --
    /// Returns the line height of the given font.
    /// @param | font | LFont | Font handle to query.
    /// @return | number | Line height in pixels.
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
    let s = state.clone();
    // -- getFontLineHeight --
    /// Returns the line spacing of the given font.
    /// @param | font | LFont | Font handle to query.
    /// @return | number | Line height in pixels.
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
    /// Sets the line height override for a font (currently a no-op stub).
    /// @param | font | LFont | Font handle.
    /// @param | lh | number | Line height value.
    graphics.set(
        "setFontLineHeight",
        lua.create_function(|_, (_font, _lh): (LuaAnyUserData, f32)| Ok(()))?,
    )?;
    let s = state.clone();
    // -- getFontAscent --
    /// Returns the ascent (pixels above baseline) of the given font.
    /// @param | font | LFont | Font handle to query.
    /// @return | number | Ascent in pixels.
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
    let s = state.clone();
    // -- getFontDescent --
    /// Returns the descent (pixels below baseline) of the given font.
    /// @param | font | LFont | Font handle to query.
    /// @return | number | Descent in pixels.
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
    let s = state.clone();
    // -- getFontWrap --
    /// Word-wraps text using the active font and returns the resulting lines and widest line width.
    /// @param | text | string | Text to wrap.
    /// @param | limit | number | Maximum line width in pixels.
    /// @return | LuaValue, number | Wrapped lines as a table when a font is active, or nil otherwise, followed by the widest line width.
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
    let s = state.clone();
    // -- newImage --
    /// Loads a texture from a file path or creates one from an ImageData object.
    /// @param | pathOrData | string|LImageData | File path to an image, or an ImageData object.
    /// @param | colorSpace | string? | Color space: "srgb" (default) or "linear".
    /// @return | LImage | The loaded image handle.
    graphics.set(
        "newImage",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let arg = iter.next().ok_or_else(|| {
                LuaError::RuntimeError(
                    "lurek.graphic.newImage: expected a file path string or ImageData".into(),
                )
            })?;
            let color_space = match iter.next() {
                Some(LuaValue::String(mode)) => {
                    let mode = mode.to_str().map_err(|e| {
                        LuaError::RuntimeError(format!(
                            "lurek.graphic.newImage: invalid color space string: {}",
                            e
                        ))
                    })?;
                    Texture::parse_color_space(mode).ok_or_else(|| {
                        LuaError::RuntimeError(format!(
                            "lurek.graphic.newImage: invalid color space '{}', expected 'srgb' or 'linear'",
                            mode
                        ))
                    })?
                }
                Some(other) => {
                    return Err(LuaError::RuntimeError(format!(
                        "lurek.graphic.newImage: second argument must be color space string, got {}",
                        other.type_name()
                    )));
                }
                None => TextureColorSpace::Srgb,
            };
            match arg {
            LuaValue::String(path_str) => {
                let path = path_str.to_str().map_err(|e| {
                    LuaError::RuntimeError(format!("lurek.graphic.newImage: invalid path: {}", e))
                })?;
                let mut st = s.borrow_mut();
                let full_path = st.game_dir.join(path);
                match Texture::load_with_color_space(&full_path, &mut st.textures, color_space) {
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
                match Texture::from_rgba_with_color_space(
                    w,
                    h,
                    pixels,
                    &mut st.textures,
                    color_space,
                ) {
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
        }
        })?,
    )?;
    let s = state.clone();
    // -- newCanvas --
    /// Creates a new off-screen render target with the given dimensions.
    /// @param | width | integer | Canvas width in pixels (must be > 0).
    /// @param | height | integer | Canvas height in pixels (must be > 0).
    /// @return | LCanvas | The created canvas handle.
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
    let s = state.clone();
    // -- resetCanvas --
    /// Marks a canvas as needing a full clear before its next render pass. Use before re-rendering to avoid content accumulation.
    /// @param | canvas | LCanvas | Canvas to reset.
    /// @return | nil | No return value.
    graphics.set(
        "resetCanvas",
        lua.create_function(move |_, ud: LuaAnyUserData| {
            let c = ud.borrow::<LuaCanvas>()?;
            let key = c.key;
            drop(c);
            let mut st = s.borrow_mut();
            if !st.canvases.contains_key(key) {
                return Err(LuaError::RuntimeError(
                    "lurek.render.resetCanvas: canvas handle is not valid".into(),
                ));
            }
            st.render_commands.push(RenderCommand::ResetCanvas(key));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- setCanvas --
    /// Redirects all subsequent drawing to the given canvas. Pass nil to draw to the screen again.
    /// @param | canvas | LCanvas? | Canvas to draw to, or nil for the main screen.
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
    let s = state.clone();
    // -- getCanvas --
    /// Returns the currently active canvas, or nil if drawing to the screen.
    /// @return | LCanvas | The active canvas handle.
    graphics.set(
        "getCanvas",
        lua.create_function(move |_, ()| match s.borrow().active_canvas {
            Some(key) => Ok(Some(LuaCanvas {
                state: s.clone(),
                key,
            })),
            None => Ok(None),
        })?,
    )?;
    let s = state.clone();
    // -- getCanvasSize --
    /// Returns the pixel dimensions of a canvas.
    /// @param | canvas | LCanvas | Canvas handle to query.
    /// @return | number, number | Width and height in pixels.
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
    let s = state.clone();
    // -- newSpriteBatch --
    /// Creates a batched sprite renderer for efficiently drawing many copies of the same texture.
    /// @param | image | LImage | Source texture for all sprites in the batch.
    /// @param | max | integer? | Maximum number of entries (default 1000).
    /// @return | LSpriteBatch | The created sprite batch handle.
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
    let s = state.clone();
    // -- newMesh --
    /// Creates a custom vertex mesh from an array of vertex data tables.
    /// @param | verts | table | Array of vertex tables: {{x, y, u, v, r, g, b, a}, ...}.
    /// @param | mode | string? | Draw mode: "triangles" (default), "fan", or "strip".
    /// @return | LMesh | The created mesh handle.
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
    let s = state.clone();
    // -- newShader --
    /// Compiles a WGSL shader program from source code and returns a handle.
    /// @param | code | string | WGSL shader source code.
    /// @return | LShader | The compiled shader handle.
    graphics.set(
        "newShader",
        lua.create_function(move |_, code: String| {
            let shader = match Shader::new(code) {
                Ok(shader) => shader,
                Err(err) => {
                    let msg = format!("lurek.graphic.newShader: {}", err);
                    s.borrow_mut().last_shader_compile_error = Some(msg.clone());
                    return Err(LuaError::RuntimeError(msg));
                }
            };
            let key = {
                let mut st = s.borrow_mut();
                st.last_shader_compile_error = None;
                st.shaders.insert(shader)
            };
            Ok(LuaShader {
                state: s.clone(),
                key,
            })
        })?,
    )?;
    let s = state.clone();
    // -- setShader --
    /// Activates a shader for subsequent draw calls. Pass nil to restore the default shader.
    /// @param | shader | LShader? | Shader handle to activate, or nil for default.
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
    let s = state.clone();
    // -- getShader --
    /// Returns the currently active shader, or nil if using the default.
    /// @return | LShader | The active shader handle.
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
    #[allow(clippy::type_complexity)]
    // -- newQuad --
    /// Creates a Quad defining a rectangular sub-region of a texture for sprite-sheet rendering.
    /// @param | x | number | Left edge in texture pixels.
    /// @param | y | number | Top edge in texture pixels.
    /// @param | w | number | Width in texture pixels.
    /// @param | h | number | Height in texture pixels.
    /// @param | sw | number | Full source texture width.
    /// @param | sh | number | Full source texture height.
    /// @return | LQuad | The created quad.
    graphics.set(
        "newQuad",
        lua.create_function(
            move |_, (x, y, w, h, sw, sh): (f32, f32, f32, f32, f32, f32)| {
                Ok(LuaQuad { x, y, w, h, sw, sh })
            },
        )?,
    )?;
    let s = state.clone();
    // -- push --
    /// Pushes the current transformation matrix onto the transform stack.
    graphics.set(
        "push",
        lua.create_function(move |_, ()| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PushTransform);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- pop --
    /// Pops the top transformation matrix from the transform stack, restoring the previous one.
    graphics.set(
        "pop",
        lua.create_function(move |_, ()| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PopTransform);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- translate --
    /// Applies a translation to the current transformation matrix.
    /// @param | x | number | Horizontal translation in pixels.
    /// @param | y | number | Vertical translation in pixels.
    graphics.set(
        "translate",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::Translate { x, y });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- rotate --
    /// Applies a rotation to the current transformation matrix.
    /// @param | angle | number | Rotation angle in radians.
    graphics.set(
        "rotate",
        lua.create_function(move |_, angle: f32| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::Rotate { angle });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- scale --
    /// Applies scaling to the current transformation matrix.
    /// @param | sx | number | Horizontal scale factor.
    /// @param | sy | number? | Vertical scale factor (defaults to sx for uniform scaling).
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
    let s = state.clone();
    // -- shear --
    /// Applies a shear (skew) to the current transformation matrix.
    /// @param | kx | number | Horizontal shear factor.
    /// @param | ky | number | Vertical shear factor.
    graphics.set(
        "shear",
        lua.create_function(move |_, (kx, ky): (f32, f32)| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::Shear { kx, ky });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- origin --
    /// Resets the current transformation matrix to the identity (no transform).
    graphics.set(
        "origin",
        lua.create_function(move |_, ()| {
            s.borrow_mut().render_commands.push(RenderCommand::Origin);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- applyTransform --
    /// Multiplies the current transformation matrix by a 3x3 matrix (9 values in row-major order).
    /// @param | mat | table | Flat table of 9 numbers representing a 3x3 transform matrix.
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
    let s = state.clone();
    // -- setScissor --
    /// Sets or clears the scissor rectangle. Only pixels inside this region are drawn. Call with no args to clear.
    /// @param | x | number? | Left edge of the scissor rectangle.
    /// @param | y | number? | Top edge.
    /// @param | w | number? | Width.
    /// @param | h | number? | Height.
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
    let s = state.clone();
    // -- getScissor --
    /// Returns the current scissor rectangle, or nothing if no scissor is set.
    /// @return | number, number, number, number | x, y, w, h of the scissor rect (empty if none).
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
    let s = state.clone();
    // -- intersectScissor --
    /// Intersects the given rectangle with the current scissor, narrowing the drawable region.
    /// @param | x | number | Left edge.
    /// @param | y | number | Top edge.
    /// @param | w | number | Width.
    /// @param | h | number | Height.
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
    let s = state.clone();
    // -- setColorMask --
    /// Sets which color channels are written during draw calls. Call with no args to enable all.
    /// @param | r | boolean? | Enable red channel.
    /// @param | g | boolean? | Enable green channel.
    /// @param | b | boolean? | Enable blue channel.
    /// @param | a | boolean? | Enable alpha channel.
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
    let s = state.clone();
    // -- getColorMask --
    /// Returns the current color write mask.
    /// @return | boolean, boolean, boolean, boolean | Red, green, blue, alpha channel write states.
    graphics.set(
        "getColorMask",
        lua.create_function(move |_, ()| Ok(s.borrow().color_mask))?,
    )?;
    let s = state.clone();
    // -- setWireframe --
    /// Enables or disables wireframe rendering mode.
    /// @param | enabled | boolean | True for wireframe, false for solid.
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
    let s = state.clone();
    // -- isWireframe --
    /// Returns whether wireframe rendering is currently active.
    /// @return | boolean | True if wireframe mode is on.
    graphics.set(
        "isWireframe",
        lua.create_function(move |_, ()| Ok(s.borrow().wireframe))?,
    )?;
    let s = state.clone();
    // -- stencil --
    /// Begins a stencil write pass with the given action and reference value.
    /// @param | action | string? | Stencil action: "replace" (default), "zero", "increment", "decrement", etc.
    /// @param | value | number? | Stencil reference value (default 1).
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
    let s = state.clone();
    // -- setStencilTest --
    /// Configures the stencil comparison test for subsequent draws. Pass nil to disable.
    /// @param | compare | string? | Compare function: "equal", "notequal", "less", "greater", etc. Nil disables.
    /// @param | value | number? | Reference value to compare against (default 1).
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
    let s = state.clone();
    // -- setStencilMode --
    /// Sets the stencil write action, compare function, and reference value at once.
    /// @param | action | string | Stencil action: "keep", "zero", "replace", "increment", "decrement", etc.
    /// @param | compare | string? | Compare function (default "always").
    /// @param | value | number? | Reference value (default 0).
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
    let s = state.clone();
    // -- getStencilMode --
    /// Returns the current stencil action, compare mode, and reference value.
    /// @return | string, string, number | Action name, compare mode name, and reference value.
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
    let s = state.clone();
    // -- clearStencil --
    /// Resets the stencil state to defaults (no stencil operations).
    graphics.set(
        "clearStencil",
        lua.create_function(move |_, ()| {
            s.borrow_mut().stencil_mode = StencilMode::default();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- setDepthMode --
    /// Sets the depth comparison mode and whether depth writes are enabled.
    /// @param | mode | string | Compare mode: "always", "never", "less", "lequal", "equal", "notequal", "greater", "gequal".
    /// @param | write | boolean? | Enable depth buffer writes (default false).
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
    let s = state.clone();
    // -- getDepthMode --
    /// Returns the current depth comparison mode and write-enable flag.
    /// @return | string, boolean | Depth mode name and whether depth writes are enabled.
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
    let s = state.clone();
    // -- getWidth --
    /// Returns the current window width in pixels.
    /// @return | number | Window width.
    graphics.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;
    let s = state.clone();
    // -- getHeight --
    /// Returns the current window height in pixels.
    /// @return | number | Window height.
    graphics.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;
    let s = state.clone();
    // -- getDimensions --
    /// Returns the current window width and height.
    /// @return | number, number | Width and height in pixels.
    graphics.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;
    let s = state.clone();
    // -- setDefaultFilter --
    /// Sets the default texture filtering mode for newly created images.
    /// @param | min | string | Minification filter: "nearest" or "linear".
    /// @param | mag | string | Magnification filter: "nearest" or "linear".
    /// @param | anisotropy | integer? | Anisotropy level (default 1).
    graphics.set(
        "setDefaultFilter",
        lua.create_function(
            move |_, (min, mag, anisotropy): (String, String, Option<u32>)| {
                s.borrow_mut().default_filter = (min, mag, anisotropy.unwrap_or(1));
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- getDefaultFilter --
    /// Returns the current default texture filtering settings.
    /// @return | string, string, number | Min filter, mag filter, anisotropy level.
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
    let s = state.clone();
    // -- getStats --
    /// Returns a table of rendering statistics for the current frame.
    /// @return | table | Stats table with rendering counters.
    /// @field | drawcalls | integer | Total draw call count.
    /// @field | textures | integer | Loaded texture count.
    /// @field | fonts | integer | Loaded font count.
    /// @field | canvases | integer | Active canvas count.
    /// @field | texture_memory | integer | Texture memory in bytes.
    /// @field | gpu_draw_calls | integer | GPU-side draw call count.
    /// @field | batched_draws | integer | Batched draw count.
    /// @field | texture_switches | integer | Texture switch count.
    /// @field | canvas_switches | integer | Canvas switch count.
    /// @field | shader_switches | integer | Shader switch count.
    /// @field | cpu_render_ms | number | CPU render time in milliseconds.
    graphics.set(
        "getStats",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let r = st.compute_stats();
            let stats = lua.create_table()?;
            /// Performs the 'drawcalls' operation.
            stats.set("drawcalls", r.draw_calls)?;
            /// Performs the 'textures' operation.
            stats.set("textures", r.textures)?;
            /// Performs the 'fonts' operation.
            stats.set("fonts", r.fonts)?;
            /// Performs the 'canvases' operation.
            stats.set("canvases", r.canvases)?;
            /// Performs the 'texture_memory' operation.
            stats.set("texture_memory", r.texture_memory)?;
            /// Performs the 'gpu_draw_calls' operation.
            stats.set("gpu_draw_calls", st.render_stats.draw_calls)?;
            /// Performs the 'batched_draws' operation.
            stats.set("batched_draws", st.render_stats.batched_draws)?;
            /// Performs the 'texture_switches' operation.
            stats.set("texture_switches", st.render_stats.texture_switches)?;
            /// Performs the 'canvas_switches' operation.
            stats.set("canvas_switches", st.render_stats.canvas_switches)?;
            /// Performs the 'shader_switches' operation.
            stats.set("shader_switches", st.render_stats.shader_switches)?;
            /// Performs the 'cpu_render_ms' operation.
            stats.set("cpu_render_ms", st.render_stats.cpu_render_ms)?;
            Ok(stats)
        })?,
    )?;
    let s = state.clone();
    // -- saveScreenshot --
    /// Saves a screenshot of the current frame to a file under the save/ directory.
    /// @param | path | string | Output path (must start with "save/").
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
    /// Captures a screenshot as ImageData and passes it to a callback (stub: returns 1x1 placeholder).
    /// @param | callback | function | Called with an LImageData argument.
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
    /// Creates a 9-slice definition from an image and four border insets for scalable UI rendering.
    /// @param | image | LImage | Source texture.
    /// @param | top | number | Top border inset in pixels.
    /// @param | right | number | Right border inset.
    /// @param | bottom | number | Bottom border inset.
    /// @param | left | number | Left border inset.
    /// @return | LNineSlice | The 9-slice handle.
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
    let s = state.clone();
    // -- drawNineSlice --
    /// Draws a 9-slice image stretched to fill the given rectangle, keeping borders unscaled.
    /// @param | slice | LNineSlice | The 9-slice handle to draw.
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Target width.
    /// @param | h | number | Target height.
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
    let s = state.clone();
    // -- newShape --
    /// Creates a new retained compound shape for accumulating draw commands.
    /// @return | LShape | The created shape handle.
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
    /// Creates a new z-ordered draw layer for sorting draw callbacks by depth.
    /// @return | LDrawLayer | The created draw layer.
    graphics.set(
        "newDrawLayer",
        lua.create_function(|_, ()| {
            Ok(LuaDrawLayer {
                entries: Vec::new(),
            })
        })?,
    )?;
    let s = state.clone();
    // -- drawQuadBezier --
    /// Draws a quadratic Bezier curve through start, control, and end points.
    /// @param | x1 | number | Start X.
    /// @param | y1 | number | Start Y.
    /// @param | cx | number | Control point X.
    /// @param | cy | number | Control point Y.
    /// @param | x2 | number | End X.
    /// @param | y2 | number | End Y.
    /// @param | segs | integer? | Number of line segments (default 16).
    graphics.set("drawQuadBezier", lua.create_function(
            move |_,
                  (x1, y1, cx, cy, x2, y2, segs): (
                f32, f32, f32, f32, f32, f32, Option<u32>,
            )| {
                use crate::math::Vec2;
                s.borrow_mut().render_commands.push(RenderCommand::DrawQuadBezier {
                    start: Vec2::new(x1, y1),
                    control: Vec2::new(cx, cy),
                    end: Vec2::new(x2, y2),
                    segments: segs.unwrap_or(16),
                });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawCubicBezier --
    /// Draws a cubic Bezier curve through start, two control points, and end.
    /// @param | x1 | number | Start X.
    /// @param | y1 | number | Start Y.
    /// @param | cx1 | number | First control point X.
    /// @param | cy1 | number | First control point Y.
    /// @param | cx2 | number | Second control point X.
    /// @param | cy2 | number | Second control point Y.
    /// @param | x2 | number | End X.
    /// @param | y2 | number | End Y.
    /// @param | segs | number? | Number of line segments (default 16).
    graphics.set(
        "drawCubicBezier",
        lua.create_function(
            move |_,
                  (x1, y1, cx1, cy1, cx2, cy2, x2, y2, segs): (
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<u32>,
            )| {
                use crate::math::Vec2;
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawCubicBezier {
                        start: Vec2::new(x1, y1),
                        c1: Vec2::new(cx1, cy1),
                        c2: Vec2::new(cx2, cy2),
                        end: Vec2::new(x2, y2),
                        segments: segs.unwrap_or(16),
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawPath --
    /// Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments.
    /// @param | path | table | Array of segment tables, each with a "type" field and coordinates.
    /// @param | mode | string? | "line" (default) or "fill".
    /// @param | close | boolean? | Close the path back to start (default false).
    graphics.set(
        "drawPath",
        lua.create_function(
            move |_, (path, mode, close): (LuaTable, Option<String>, Option<bool>)| {
                let draw_mode = match mode.as_deref().unwrap_or("line") {
                    "fill" => DrawMode::Fill,
                    "line" => DrawMode::Line,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawPath: unknown mode '{other}'"
                        )))
                    }
                };
                let mut segs: Vec<PathSegment> = Vec::new();
                for i in 1..=path.raw_len() {
                    let entry: LuaTable = path.get(i)?;
                    let seg_type: String = entry.get("type")?;
                    let seg = match seg_type.as_str() {
                        "moveTo" => PathSegment::MoveTo {
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "lineTo" => PathSegment::LineTo {
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "quadTo" => PathSegment::QuadTo {
                            cx: entry.get("cx")?,
                            cy: entry.get("cy")?,
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "cubicTo" => PathSegment::CubicTo {
                            cx1: entry.get("cx1")?,
                            cy1: entry.get("cy1")?,
                            cx2: entry.get("cx2")?,
                            cy2: entry.get("cy2")?,
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        other => {
                            return Err(LuaError::RuntimeError(format!(
                                "drawPath: unknown segment type '{other}'"
                            )))
                        }
                    };
                    segs.push(seg);
                }
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawPath {
                        segments: segs,
                        mode: draw_mode,
                        close: close.unwrap_or(false),
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawGradientRect --
    /// Draws a rectangle with a two-color gradient fill.
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Width (must be positive).
    /// @param | h | number | Height (must be positive).
    /// @param | c1 | table | Start color {r, g, b [, a]}.
    /// @param | c2 | table | End color {r, g, b [, a]}.
    /// @param | dir | string? | Direction: "vertical" (default), "horizontal", "diagDown", "diagUp", "radial".
    graphics.set(
        "drawGradientRect",
        lua.create_function(
            move |_,
                  (x, y, w, h, c1, c2, dir): (
                f32,
                f32,
                f32,
                f32,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                if w <= 0.0 || h <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawGradientRect: w and h must be positive".into(),
                    ));
                }
                let color1 = [
                    c1.get::<_, f32>(1).unwrap_or(0.0),
                    c1.get::<_, f32>(2).unwrap_or(0.0),
                    c1.get::<_, f32>(3).unwrap_or(0.0),
                    c1.get::<_, f32>(4).unwrap_or(1.0),
                ];
                let color2 = [
                    c2.get::<_, f32>(1).unwrap_or(0.0),
                    c2.get::<_, f32>(2).unwrap_or(0.0),
                    c2.get::<_, f32>(3).unwrap_or(0.0),
                    c2.get::<_, f32>(4).unwrap_or(1.0),
                ];
                let direction = match dir.as_deref().unwrap_or("vertical") {
                    "horizontal" => GradientDirection::Horizontal,
                    "vertical" => GradientDirection::Vertical,
                    "diagDown" => GradientDirection::DiagDown,
                    "diagUp" => GradientDirection::DiagUp,
                    "radial" => GradientDirection::Radial,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawGradientRect: unknown direction '{other}'"
                        )))
                    }
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawGradientRect {
                        x,
                        y,
                        w,
                        h,
                        color1,
                        color2,
                        direction,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawColoredPolygon --
    /// Draws a polygon with per-vertex colors.
    /// @param | vertices | table | Flat array of x,y coordinates: {x1, y1, x2, y2, ...}.
    /// @param | colors | table | Array of color tables: {{r, g, b, a}, ...}, one per vertex.
    /// @param | mode | string? | "fill" (default) or "line".
    graphics.set("drawColoredPolygon", lua.create_function(
            move |_, (vertices, colors, mode): (LuaTable, LuaTable, Option<String>)| {
                let draw_mode = match mode.as_deref().unwrap_or("fill") {
                    "fill" => DrawMode::Fill,
                    "line" => DrawMode::Line,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawColoredPolygon: unknown mode '{other}'"
                        )))
                    }
                };
                let n = vertices.raw_len();
                if n < 4 || n % 2 != 0 {
                    return Err(LuaError::RuntimeError(
                        "drawColoredPolygon: vertices must be a flat [x,y,...] table with at least 2 pairs".into(),
                    ));
                }
                let mut verts: Vec<f32> = Vec::with_capacity(n);
                for i in 1..=n {
                    verts.push(vertices.get::<_, f32>(i)?);
                }
                let vert_count = n / 2;
                let col_count = colors.raw_len();
                let mut cols: Vec<[f32; 4]> = Vec::with_capacity(vert_count);
                for i in 1..=vert_count {
                    if i <= col_count {
                        let c: LuaTable = colors.get(i)?;
                        cols.push([
                            c.get::<_, f32>(1).unwrap_or(1.0),
                            c.get::<_, f32>(2).unwrap_or(1.0),
                            c.get::<_, f32>(3).unwrap_or(1.0),
                            c.get::<_, f32>(4).unwrap_or(1.0),
                        ]);
                    } else {
                        cols.push([1.0, 1.0, 1.0, 1.0]);
                    }
                }
                s.borrow_mut().render_commands.push(RenderCommand::DrawColoredPolygon {
                    vertices: verts,
                    colors: cols,
                    mode: draw_mode,
                });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawIsoCubeTile --
    /// Draws an isometric cube tile with configurable face colors and optional textures.
    /// @param | sx | number | Screen X position of the tile center.
    /// @param | sy | number | Screen Y position of the tile center.
    /// @param | halfW | number | Half-width of the tile diamond.
    /// @param | halfH | number | Half-height of the tile diamond.
    /// @param | opts | table? | Options: depth, topColor, leftColor, rightColor, topTexture, leftTexture, rightTexture.
    graphics.set(
        "drawIsoCubeTile",
        lua.create_function(
            move |_, (sx, sy, half_w, half_h, opts): (f32, f32, f32, f32, Option<LuaTable>)| {
                let parse_color = |tbl: Option<LuaTable>| -> [f32; 4] {
                    tbl.map(|t| {
                        [
                            t.get::<_, f32>(1).unwrap_or(1.0),
                            t.get::<_, f32>(2).unwrap_or(1.0),
                            t.get::<_, f32>(3).unwrap_or(1.0),
                            t.get::<_, f32>(4).unwrap_or(1.0),
                        ]
                    })
                    .unwrap_or([1.0, 1.0, 1.0, 1.0])
                };
                let (
                    depth,
                    top_color,
                    top_tex_key,
                    left_color,
                    left_tex_key,
                    right_color,
                    right_tex_key,
                ) = if let Some(ref o) = opts {
                    let depth = o.get::<_, f32>("depth").unwrap_or(0.0);
                    let top_color =
                        parse_color(o.get::<_, Option<LuaTable>>("topColor").ok().flatten());
                    let left_color =
                        parse_color(o.get::<_, Option<LuaTable>>("leftColor").ok().flatten());
                    let right_color =
                        parse_color(o.get::<_, Option<LuaTable>>("rightColor").ok().flatten());
                    let top_tex = o
                        .get::<_, Option<LuaAnyUserData>>("topTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    let left_tex = o
                        .get::<_, Option<LuaAnyUserData>>("leftTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    let right_tex = o
                        .get::<_, Option<LuaAnyUserData>>("rightTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    (
                        depth,
                        top_color,
                        top_tex,
                        left_color,
                        left_tex,
                        right_color,
                        right_tex,
                    )
                } else {
                    (
                        0.0,
                        [1.0; 4],
                        None,
                        [0.7, 0.7, 0.7, 1.0],
                        None,
                        [0.5, 0.5, 0.5, 1.0],
                        None,
                    )
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawIsoCubeTile {
                        screen_x: sx,
                        screen_y: sy,
                        half_w,
                        half_h,
                        depth,
                        top_color,
                        top_texture: top_tex_key,
                        left_color,
                        left_texture: left_tex_key,
                        right_color,
                        right_texture: right_tex_key,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawHexTile --
    /// Draws a regular hexagonal tile at the given center position.
    /// @param | cx | number | Center X.
    /// @param | cy | number | Center Y.
    /// @param | size | number | Hex radius (must be positive).
    /// @param | orientation | string? | "pointyTop" (default) or "flatTop".
    /// @param | mode | string? | "line" (default) or "fill".
    graphics.set(
        "drawHexTile",
        lua.create_function(
            move |_,
                  (cx, cy, size, orientation, mode): (
                f32,
                f32,
                f32,
                Option<String>,
                Option<String>,
            )| {
                if size <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawHexTile: size must be positive".into(),
                    ));
                }
                let orientation = match orientation.as_deref().unwrap_or("pointyTop") {
                    "pointyTop" | "pointy" => HexOrientation::PointyTop,
                    "flatTop" | "flat" => HexOrientation::FlatTop,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawHexTile: unknown orientation '{other}'"
                        )))
                    }
                };
                let draw_mode = match mode.as_deref().unwrap_or("line") {
                    "fill" => DrawMode::Fill,
                    "line" => DrawMode::Line,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawHexTile: unknown mode '{other}'"
                        )))
                    }
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawHexTile {
                        cx,
                        cy,
                        size,
                        orientation,
                        mode: draw_mode,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- beginSortGroup --
    /// Begins a depth-sorted rendering group. Draw calls within this group are sorted by pushSortKey values.
    /// @param | id | integer | Group identifier.
    graphics.set(
        "beginSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::BeginSortGroup { group_id: id });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- pushSortKey --
    /// Sets the depth sort key for subsequent draw calls within the current sort group.
    /// @param | depth | number | Sort depth value (lower draws first).
    graphics.set(
        "pushSortKey",
        lua.create_function(move |_, depth: f32| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PushSortKey(depth));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- flushSortGroup --
    /// Ends a sort group and emits all accumulated draw calls in sorted order.
    /// @param | id | integer | Group identifier matching the beginSortGroup call.
    graphics.set(
        "flushSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::FlushSortGroup { group_id: id });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- drawBevelRect --
    /// Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements.
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Width (must be positive).
    /// @param | h | number | Height (must be positive).
    /// @param | bevelW | number? | Bevel border width (default 2).
    /// @param | style | string? | Bevel style: "raised" (default), "sunken", "ridge", "groove", "flat".
    /// @param | opts | table? | Options: highlight, shadow, fillColor (each a {r,g,b,a} table).
    graphics.set(
        "drawBevelRect",
        lua.create_function(
            move |_,
                  (x, y, w, h, bevel_w, style, opts): (
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
                Option<String>,
                Option<LuaTable>,
            )| {
                if w <= 0.0 || h <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawBevelRect: w and h must be positive".into(),
                    ));
                }
                let bevel_w = bevel_w.unwrap_or(2.0).max(0.0);
                let bevel_style = match style.as_deref().unwrap_or("raised") {
                    "raised" => BevelStyle::Raised,
                    "sunken" => BevelStyle::Sunken,
                    "ridge" => BevelStyle::Ridge,
                    "groove" => BevelStyle::Groove,
                    "flat" => BevelStyle::Flat,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawBevelRect: unknown style '{other}'"
                        )))
                    }
                };
                let parse_color_tbl = |key: &str, def: [f32; 4]| -> [f32; 4] {
                    opts.as_ref()
                        .and_then(|t| t.get::<_, LuaTable>(key).ok())
                        .map(|c| {
                            [
                                c.get::<_, f32>(1).unwrap_or(def[0]),
                                c.get::<_, f32>(2).unwrap_or(def[1]),
                                c.get::<_, f32>(3).unwrap_or(def[2]),
                                c.get::<_, f32>(4).unwrap_or(def[3]),
                            ]
                        })
                        .unwrap_or(def)
                };
                let highlight = parse_color_tbl("highlight", [1.0, 1.0, 1.0, 1.0]);
                let shadow = parse_color_tbl("shadow", [0.2, 0.2, 0.2, 1.0]);
                let fill_color = parse_color_tbl("fillColor", [0.5, 0.5, 0.5, 1.0]);
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawBevelRect {
                        x,
                        y,
                        w,
                        h,
                        bevel_w,
                        style: bevel_style,
                        highlight,
                        shadow,
                        fill_color,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- pushLayer --
    /// Begins a compositing layer with the given alpha and blend mode. Must be paired with popLayer.
    /// @param | id | integer | Layer identifier (must match the popLayer call).
    /// @param | alpha | number? | Layer opacity (0–1, default 1).
    /// @param | blendMode | string? | Blend mode: "alpha" (default), "add", "multiply", "replace", "screen".
    graphics.set(
        "pushLayer",
        lua.create_function(
            move |_, (id, alpha, blend_mode): (u64, Option<f32>, Option<String>)| {
                let alpha = alpha.unwrap_or(1.0).clamp(0.0, 1.0);
                let blend = match blend_mode.as_deref().unwrap_or("alpha") {
                    "alpha" => BlendMode::Alpha,
                    "add" | "additive" => BlendMode::Add,
                    "multiply" => BlendMode::Multiply,
                    "replace" | "none" => BlendMode::Replace,
                    "screen" => BlendMode::Screen,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "pushLayer: unknown blend mode '{other}'"
                        )))
                    }
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::PushLayer { id, alpha, blend });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- popLayer --
    /// Ends a compositing layer and composites it with the previous content.
    /// @param | id | integer | Layer identifier matching the pushLayer call.
    graphics.set(
        "popLayer",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PopLayer { id });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- drawQuadBezier --
    /// Draws a quadratic Bezier curve through start, control, and end points.
    /// @param | x1 | number | Start X.
    /// @param | y1 | number | Start Y.
    /// @param | cx | number | Control point X.
    /// @param | cy | number | Control point Y.
    /// @param | x2 | number | End X.
    /// @param | y2 | number | End Y.
    /// @param | segments | number? | Number of line segments (default 16).
    graphics.set(
        "drawQuadBezier",
        lua.create_function(
            move |_,
                  (x1, y1, cx, cy, x2, y2, segments): (
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<u32>,
            )| {
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawQuadBezier {
                        start: crate::math::Vec2::new(x1, y1),
                        control: crate::math::Vec2::new(cx, cy),
                        end: crate::math::Vec2::new(x2, y2),
                        segments: segments.unwrap_or(16),
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawCubicBezier --
    /// Draws a cubic Bezier curve through start, two control points, and end.
    /// @param | x1 | number | Start X.
    /// @param | y1 | number | Start Y.
    /// @param | cx1 | number | First control point X.
    /// @param | cy1 | number | First control point Y.
    /// @param | cx2 | number | Second control point X.
    /// @param | cy2 | number | Second control point Y.
    /// @param | x2 | number | End X.
    /// @param | y2 | number | End Y.
    /// @param | segments | number? | Number of line segments (default 16).
    graphics.set(
        "drawCubicBezier",
        lua.create_function(
            move |_,
                  (x1, y1, cx1, cy1, cx2, cy2, x2, y2, segments): (
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                f32,
                Option<u32>,
            )| {
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawCubicBezier {
                        start: crate::math::Vec2::new(x1, y1),
                        c1: crate::math::Vec2::new(cx1, cy1),
                        c2: crate::math::Vec2::new(cx2, cy2),
                        end: crate::math::Vec2::new(x2, y2),
                        segments: segments.unwrap_or(16),
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawPath --
    /// Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments.
    /// @param | path | table | Array of segment tables, each with a "type" field and coordinates.
    /// @param | mode | string? | "line" (default) or "fill".
    /// @param | close | boolean? | Close the path back to start (default false).
    graphics.set(
        "drawPath",
        lua.create_function(
            move |_, (path, mode, close): (LuaTable, Option<String>, Option<bool>)| {
                let draw_mode = parse_draw_mode(mode.as_deref().unwrap_or("line"))?;
                let mut segs: Vec<PathSegment> = Vec::new();
                for i in 1..=path.raw_len() {
                    let entry: LuaTable = path.get(i)?;
                    let seg_type: String = entry.get("type")?;
                    let seg = match seg_type.as_str() {
                        "moveTo" => PathSegment::MoveTo {
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "lineTo" => PathSegment::LineTo {
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "quadTo" => PathSegment::QuadTo {
                            cx: entry.get("cx")?,
                            cy: entry.get("cy")?,
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        "cubicTo" => PathSegment::CubicTo {
                            cx1: entry.get("cx1")?,
                            cy1: entry.get("cy1")?,
                            cx2: entry.get("cx2")?,
                            cy2: entry.get("cy2")?,
                            x: entry.get("x")?,
                            y: entry.get("y")?,
                        },
                        other => {
                            return Err(LuaError::RuntimeError(format!(
                                "drawPath: unknown segment type '{other}'"
                            )))
                        }
                    };
                    segs.push(seg);
                }
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawPath {
                        segments: segs,
                        mode: draw_mode,
                        close: close.unwrap_or(false),
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawGradientRect --
    /// Draws a rectangle with a two-color gradient fill.
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Width (must be positive).
    /// @param | h | number | Height (must be positive).
    /// @param | c1 | table | Start color {r, g, b [, a]}.
    /// @param | c2 | table | End color {r, g, b [, a]}.
    /// @param | dir | string? | Direction: "vertical" (default), "horizontal", "diagDown", "diagUp", "radial".
    graphics.set(
        "drawGradientRect",
        lua.create_function(
            move |_,
                  (x, y, w, h, c1, c2, dir): (
                f32,
                f32,
                f32,
                f32,
                LuaTable,
                LuaTable,
                Option<String>,
            )| {
                if w <= 0.0 || h <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawGradientRect: w and h must be positive".into(),
                    ));
                }
                let color1 = [
                    c1.get::<_, f32>(1).unwrap_or(0.0),
                    c1.get::<_, f32>(2).unwrap_or(0.0),
                    c1.get::<_, f32>(3).unwrap_or(0.0),
                    c1.get::<_, f32>(4).unwrap_or(1.0),
                ];
                let color2 = [
                    c2.get::<_, f32>(1).unwrap_or(0.0),
                    c2.get::<_, f32>(2).unwrap_or(0.0),
                    c2.get::<_, f32>(3).unwrap_or(0.0),
                    c2.get::<_, f32>(4).unwrap_or(1.0),
                ];
                let direction = match dir.as_deref().unwrap_or("vertical") {
                    "horizontal" => GradientDirection::Horizontal,
                    "vertical" => GradientDirection::Vertical,
                    "diagDown" => GradientDirection::DiagDown,
                    "diagUp" => GradientDirection::DiagUp,
                    "radial" => GradientDirection::Radial,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawGradientRect: unknown direction '{other}'"
                        )))
                    }
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawGradientRect {
                        x,
                        y,
                        w,
                        h,
                        color1,
                        color2,
                        direction,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawColoredPolygon --
    /// Draws a polygon with per-vertex colors.
    /// @param | vertices | table | Flat array of x,y coordinates: {x1, y1, x2, y2, ...}.
    /// @param | colors | table | Array of color tables: {{r, g, b, a}, ...}, one per vertex.
    /// @param | mode | string? | "fill" (default) or "line".
    graphics.set("drawColoredPolygon", lua.create_function(
            move |_, (vertices, colors, mode): (LuaTable, LuaTable, Option<String>)| {
                let draw_mode = parse_draw_mode(mode.as_deref().unwrap_or("fill"))?;
                let n = vertices.raw_len();
                if n < 4 || n % 2 != 0 {
                    return Err(LuaError::RuntimeError(
                        "drawColoredPolygon: vertices must be a flat [x,y,...] table with at least 2 pairs".into(),
                    ));
                }
                let mut verts: Vec<f32> = Vec::with_capacity(n);
                for i in 1..=n {
                    verts.push(vertices.get::<_, f32>(i)?);
                }
                let vert_count = n / 2;
                let col_count = colors.raw_len();
                let mut cols: Vec<[f32; 4]> = Vec::with_capacity(vert_count);
                for i in 1..=vert_count {
                    if i <= col_count {
                        let c: LuaTable = colors.get(i)?;
                        cols.push([
                            c.get::<_, f32>(1).unwrap_or(1.0),
                            c.get::<_, f32>(2).unwrap_or(1.0),
                            c.get::<_, f32>(3).unwrap_or(1.0),
                            c.get::<_, f32>(4).unwrap_or(1.0),
                        ]);
                    } else {
                        cols.push([1.0, 1.0, 1.0, 1.0]);
                    }
                }
                s.borrow_mut().render_commands.push(RenderCommand::DrawColoredPolygon {
                    vertices: verts,
                    colors: cols,
                    mode: draw_mode,
                });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawIsoCubeTile --
    /// Draws an isometric cube tile with configurable face colors and optional textures.
    /// @param | sx | number | Screen X position of the tile center.
    /// @param | sy | number | Screen Y position of the tile center.
    /// @param | halfW | number | Half-width of the tile diamond.
    /// @param | halfH | number | Half-height of the tile diamond.
    /// @param | opts | table? | Options: depth, topColor, leftColor, rightColor, topTexture, leftTexture, rightTexture.
    graphics.set(
        "drawIsoCubeTile",
        lua.create_function(
            move |_, (sx, sy, half_w, half_h, opts): (f32, f32, f32, f32, Option<LuaTable>)| {
                let parse_color = |tbl: Option<LuaTable>| -> [f32; 4] {
                    tbl.map(|t| {
                        [
                            t.get::<_, f32>(1).unwrap_or(1.0),
                            t.get::<_, f32>(2).unwrap_or(1.0),
                            t.get::<_, f32>(3).unwrap_or(1.0),
                            t.get::<_, f32>(4).unwrap_or(1.0),
                        ]
                    })
                    .unwrap_or([1.0, 1.0, 1.0, 1.0])
                };
                let (
                    depth,
                    top_color,
                    top_tex_key,
                    left_color,
                    left_tex_key,
                    right_color,
                    right_tex_key,
                ) = if let Some(ref o) = opts {
                    let depth = o.get::<_, f32>("depth").unwrap_or(0.0);
                    let top_color =
                        parse_color(o.get::<_, Option<LuaTable>>("topColor").ok().flatten());
                    let left_color =
                        parse_color(o.get::<_, Option<LuaTable>>("leftColor").ok().flatten());
                    let right_color =
                        parse_color(o.get::<_, Option<LuaTable>>("rightColor").ok().flatten());
                    let top_tex = o
                        .get::<_, Option<LuaAnyUserData>>("topTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    let left_tex = o
                        .get::<_, Option<LuaAnyUserData>>("leftTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    let right_tex = o
                        .get::<_, Option<LuaAnyUserData>>("rightTexture")
                        .ok()
                        .flatten()
                        .and_then(|ud| ud.borrow::<LuaImage>().ok().map(|img| img.key));
                    (
                        depth,
                        top_color,
                        top_tex,
                        left_color,
                        left_tex,
                        right_color,
                        right_tex,
                    )
                } else {
                    (
                        0.0,
                        [1.0; 4],
                        None,
                        [0.7, 0.7, 0.7, 1.0],
                        None,
                        [0.5, 0.5, 0.5, 1.0],
                        None,
                    )
                };
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawIsoCubeTile {
                        screen_x: sx,
                        screen_y: sy,
                        half_w,
                        half_h,
                        depth,
                        top_color,
                        top_texture: top_tex_key,
                        left_color,
                        left_texture: left_tex_key,
                        right_color,
                        right_texture: right_tex_key,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- drawHexTile --
    /// Draws a regular hexagonal tile at the given center position.
    /// @param | cx | number | Center X.
    /// @param | cy | number | Center Y.
    /// @param | size | number | Hex radius (must be positive).
    /// @param | orientation | string? | "pointyTop" (default) or "flatTop".
    /// @param | mode | string? | "line" (default) or "fill".
    graphics.set(
        "drawHexTile",
        lua.create_function(
            move |_,
                  (cx, cy, size, orientation, mode): (
                f32,
                f32,
                f32,
                Option<String>,
                Option<String>,
            )| {
                if size <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawHexTile: size must be positive".into(),
                    ));
                }
                let orientation = match orientation.as_deref().unwrap_or("pointyTop") {
                    "pointyTop" | "pointy" => HexOrientation::PointyTop,
                    "flatTop" | "flat" => HexOrientation::FlatTop,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawHexTile: unknown orientation '{other}'"
                        )))
                    }
                };
                let draw_mode = parse_draw_mode(mode.as_deref().unwrap_or("line"))?;
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawHexTile {
                        cx,
                        cy,
                        size,
                        orientation,
                        mode: draw_mode,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- beginSortGroup --
    /// Begins a depth-sorted rendering group. Draw calls within this group are sorted by pushSortKey values.
    /// @param | id | integer | Group identifier.
    graphics.set(
        "beginSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::BeginSortGroup { group_id: id });
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- pushSortKey --
    /// Sets the depth sort key for subsequent draw calls within the current sort group.
    /// @param | depth | number | Sort depth value (lower draws first).
    graphics.set(
        "pushSortKey",
        lua.create_function(move |_, depth: f32| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PushSortKey(depth));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- flushSortGroup --
    /// Ends a sort group and emits all accumulated draw calls in sorted order.
    /// @param | id | integer | Group identifier matching the beginSortGroup call.
    graphics.set(
        "flushSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::FlushSortGroup { group_id: id });
            Ok(())
        })?,
    )?;
    #[allow(clippy::type_complexity)]
    let s = state.clone();
    // -- drawBevelRect --
    /// Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements.
    /// @param | x | number | Left edge X.
    /// @param | y | number | Top edge Y.
    /// @param | w | number | Width (must be positive).
    /// @param | h | number | Height (must be positive).
    /// @param | bevelW | number? | Bevel border width (default 2).
    /// @param | style | string? | Bevel style: "raised" (default), "sunken", "ridge", "groove", "flat".
    /// @param | opts | table? | Options: highlight, shadow, fillColor (each a {r,g,b,a} table).
    graphics.set(
        "drawBevelRect",
        lua.create_function(
            move |_,
                  (x, y, w, h, bevel_w, style, opts): (
                f32,
                f32,
                f32,
                f32,
                Option<f32>,
                Option<String>,
                Option<LuaTable>,
            )| {
                if w <= 0.0 || h <= 0.0 {
                    return Err(LuaError::RuntimeError(
                        "drawBevelRect: w and h must be positive".into(),
                    ));
                }
                let bevel_w = bevel_w.unwrap_or(2.0).max(0.0);
                let bevel_style = match style.as_deref().unwrap_or("raised") {
                    "raised" => BevelStyle::Raised,
                    "sunken" => BevelStyle::Sunken,
                    "ridge" => BevelStyle::Ridge,
                    "groove" => BevelStyle::Groove,
                    "flat" => BevelStyle::Flat,
                    other => {
                        return Err(LuaError::RuntimeError(format!(
                            "drawBevelRect: unknown style '{other}'"
                        )))
                    }
                };
                let parse_color_tbl = |key: &str, def: [f32; 4]| -> [f32; 4] {
                    opts.as_ref()
                        .and_then(|t| t.get::<_, LuaTable>(key).ok())
                        .map(|c| {
                            [
                                c.get::<_, f32>(1).unwrap_or(def[0]),
                                c.get::<_, f32>(2).unwrap_or(def[1]),
                                c.get::<_, f32>(3).unwrap_or(def[2]),
                                c.get::<_, f32>(4).unwrap_or(def[3]),
                            ]
                        })
                        .unwrap_or(def)
                };
                let highlight = parse_color_tbl("highlight", [1.0, 1.0, 1.0, 1.0]);
                let shadow = parse_color_tbl("shadow", [0.2, 0.2, 0.2, 1.0]);
                let fill_color = parse_color_tbl("fillColor", [0.5, 0.5, 0.5, 1.0]);
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::DrawBevelRect {
                        x,
                        y,
                        w,
                        h,
                        bevel_w,
                        style: bevel_style,
                        highlight,
                        shadow,
                        fill_color,
                    });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- pushLayer --
    /// Begins a compositing layer with the given alpha and blend mode. Must be paired with popLayer.
    /// @param | id | integer | Layer identifier (must match the popLayer call).
    /// @param | alpha | number? | Layer opacity (0–1, default 1).
    /// @param | blendMode | string? | Blend mode: "alpha" (default), "add", "multiply", "replace", "screen".
    graphics.set(
        "pushLayer",
        lua.create_function(
            move |_, (id, alpha, blend_mode): (u64, Option<f32>, Option<String>)| {
                let alpha = alpha.unwrap_or(1.0).clamp(0.0, 1.0);
                let blend = blend_mode
                    .as_deref()
                    .map(parse_blend_mode)
                    .transpose()?
                    .unwrap_or(BlendMode::Alpha);
                s.borrow_mut()
                    .render_commands
                    .push(RenderCommand::PushLayer { id, alpha, blend });
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    // -- popLayer --
    /// Ends a compositing layer and composites it with the previous content.
    /// @param | id | integer | Layer identifier matching the pushLayer call.
    graphics.set(
        "popLayer",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PopLayer { id });
            Ok(())
        })?,
    )?;
    let layer_zorders: Rc<RefCell<std::collections::HashMap<String, i32>>> =
        Rc::new(RefCell::new(std::collections::HashMap::new()));
    let layer_visible: Rc<RefCell<std::collections::HashMap<String, bool>>> =
        Rc::new(RefCell::new(std::collections::HashMap::new()));
    let current_layer: Rc<RefCell<String>> = Rc::new(RefCell::new("default".to_string()));
    let lz = layer_zorders.clone();
    let lv = layer_visible.clone();
    // -- newLayer --
    /// Creates a named rendering layer with an optional z-order for draw call organization.
    /// @param | name | string | Layer name.
    /// @param | zOrder | integer? | Z-order for layer sorting (default 0).
    graphics.set(
        "newLayer",
        lua.create_function(move |_, (name, z_order): (String, Option<i32>)| {
            lz.borrow_mut().insert(name.clone(), z_order.unwrap_or(0));
            lv.borrow_mut().entry(name).or_insert(true);
            Ok(())
        })?,
    )?;
    let cl = current_layer.clone();
    let lz2 = layer_zorders.clone();
    let lv2 = layer_visible.clone();
    // -- setLayer --
    /// Sets the active rendering layer by name. Creates the layer if it does not exist.
    /// @param | name | string | Layer name to activate.
    graphics.set(
        "setLayer",
        lua.create_function(move |_, name: String| {
            lz2.borrow_mut().entry(name.clone()).or_insert(0);
            lv2.borrow_mut().entry(name.clone()).or_insert(true);
            *cl.borrow_mut() = name;
            Ok(())
        })?,
    )?;
    let cl2 = current_layer.clone();
    // -- currentLayer --
    /// Returns the name of the currently active rendering layer.
    /// @return | string | Active layer name.
    graphics.set(
        "currentLayer",
        lua.create_function(move |_, ()| Ok(cl2.borrow().clone()))?,
    )?;
    let lv3 = layer_visible.clone();
    // -- setLayerVisible --
    /// Sets whether a named rendering layer is visible.
    /// @param | name | string | Layer name.
    /// @param | visible | boolean | True to show, false to hide.
    graphics.set(
        "setLayerVisible",
        lua.create_function(move |_, (name, visible): (String, bool)| {
            lv3.borrow_mut().insert(name, visible);
            Ok(())
        })?,
    )?;
    let lv4 = layer_visible.clone();
    // -- isLayerVisible --
    /// Returns whether a named rendering layer is currently visible.
    /// @param | name | string | Layer name.
    /// @return | boolean | True if the layer is visible.
    graphics.set(
        "isLayerVisible",
        lua.create_function(move |_, name: String| Ok(*lv4.borrow().get(&name).unwrap_or(&true)))?,
    )?;
    let lz3 = layer_zorders.clone();
    // -- getLayerZOrder --
    /// Returns the z-order value of a named rendering layer.
    /// @param | name | string | Layer name.
    /// @return | number | Z-order value (default 0 if unset).
    graphics.set(
        "getLayerZOrder",
        lua.create_function(move |_, name: String| Ok(*lz3.borrow().get(&name).unwrap_or(&0)))?,
    )?;
    let lz4 = layer_zorders.clone();
    // -- setLayerZOrder --
    /// Sets the z-order value of a named rendering layer.
    /// @param | name | string | Layer name.
    /// @param | z | integer | New z-order value.
    graphics.set(
        "setLayerZOrder",
        lua.create_function(move |_, (name, z): (String, i32)| {
            lz4.borrow_mut().insert(name, z);
            Ok(())
        })?,
    )?;
    let state_for_obj = state.clone();
    // -- loadObj --
    /// Loads a Wavefront OBJ model file and returns a model handle for projection and rendering.
    /// @param | path | string | File path to the .obj file relative to the game directory.
    /// @return | LObjModel | The loaded OBJ model handle.
    graphics.set(
        "loadObj",
        lua.create_function(move |_, path: String| {
            let full_path = {
                let st = state_for_obj.borrow();
                st.game_dir.join(&path)
            };
            let model = crate::render::obj_loader::ObjLoader::load_file(&full_path)
                .map_err(|e| LuaError::RuntimeError(format!("loadObj '{}': {}", path, e)))?;
            Ok(LObjModel {
                state: state_for_obj.clone(),
                model,
                sprite_cache: std::collections::HashMap::new(),
            })
        })?,
    )?;
    let state_for_model = state.clone();
    // -- loadModel --
    /// Loads a 3D model file (OBJ format) and returns a handle for 2D projection and sprite rendering.
    /// @param | path | string | File path to the model file relative to the game directory.
    /// @return | LObjModel | The loaded model handle.
    graphics.set(
        "loadModel",
        lua.create_function(move |_, path: String| {
            let full_path = {
                let st = state_for_model.borrow();
                st.game_dir.join(&path)
            };
            let model = crate::render::obj_loader::ObjLoader::load_file(&full_path)
                .map_err(|e| LuaError::RuntimeError(format!("loadModel '{}': {}", path, e)))?;
            Ok(LObjModel {
                state: state_for_model.clone(),
                model,
                sprite_cache: std::collections::HashMap::new(),
            })
        })?,
    )?;
    /// Performs the 'render' operation.
    lurek.set("render", graphics)?;
    Ok(())
}
use crate::render::obj_loader::{ObjCamera, ObjModel};
/// Loaded OBJ 3D model handle for CPU-side projection to 2D meshes and sprite rendering.
pub struct LObjModel {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) model: ObjModel,
    pub(crate) sprite_cache: std::collections::HashMap<String, TextureKey>,
}
impl LuaUserData for LObjModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getVertexCount --
        /// Returns the number of vertices in this OBJ model.
        /// @return | number | Vertex count.
        methods.add_method("getVertexCount", |_, this, ()| {
            Ok(this.model.vertex_count())
        });
        // -- getFaceCount --
        /// Returns the number of faces (triangles) in this OBJ model.
        /// @return | number | Face count.
        methods.add_method("getFaceCount", |_, this, ()| Ok(this.model.face_count()));
        // -- getUvCount --
        /// Returns the number of UV texture coordinates in this OBJ model.
        /// @return | number | UV coordinate count.
        methods.add_method("getUvCount", |_, this, ()| Ok(this.model.uv_count()));
        // -- getNormalCount --
        /// Returns the number of vertex normals in this OBJ model.
        /// @return | number | Normal count.
        methods.add_method("getNormalCount", |_, this, ()| {
            Ok(this.model.normal_count())
        });
        // -- renderToImage --
        /// Renders the OBJ model to a GPU texture at the given resolution with optional 90-degree rotation.
        /// @param | width | integer | Output image width in pixels.
        /// @param | height | integer | Output image height in pixels.
        /// @param | rotation | number? | Rotation step (0–3, each step = 90 degrees, default 0).
        /// @return | LImage | The rendered image handle.
        methods.add_method_mut(
            "renderToImage",
            |_, this, (width, height, rotation): (u32, u32, Option<u8>)| {
                let rotation = rotation.unwrap_or(0) % 4;
                let cache_key = format!("{}x{}:{}", width, height, rotation);
                if let Some(tex_key) = this.sprite_cache.get(&cache_key).copied() {
                    let st = this.state.borrow();
                    if st.textures.contains_key(tex_key) {
                        drop(st);
                        return Ok(LuaImage {
                            state: this.state.clone(),
                            key: tex_key,
                        });
                    }
                }
                let image = this.model.render_to_image(width, height, rotation);
                let pixels = image.as_bytes().to_vec();
                let mut st = this.state.borrow_mut();
                let tex = Texture::from_rgba(width, height, pixels, &mut st.textures)
                    .map_err(|e| LuaError::RuntimeError(format!("renderToImage: {}", e)))?;
                st.released_texture_handles.remove(&tex.key.data().as_ffi());
                this.sprite_cache.insert(cache_key, tex.key);
                Ok(LuaImage {
                    state: this.state.clone(),
                    key: tex.key,
                })
            },
        );
        // -- projectToMesh --
        /// Projects the OBJ model into 2D vertex data using a virtual camera, returning a table of vertex rows.
        /// @param | camera | table | Camera parameters: {x, y, z, tx, ty, tz, fov}.
        /// @param | screenW | number | Screen width for projection.
        /// @param | screenH | number | Screen height for projection.
        /// @return | table | Array of vertex tables: {{x, y, u, v, r, g, b, a}, ...}.
        /// @field | x | number | X.
        /// @field | y | number | Y.
        /// @field | u | number | U.
        /// @field | v | number | V.
        /// @field | r | number | R.
        /// @field | g | number | G.
        /// @field | b | number | B.
        /// @field | a | number | A.
        methods.add_method(
            "projectToMesh",
            |lua, this, (cam_tbl, screen_w, screen_h): (LuaTable, f32, f32)| {
                let cam = ObjCamera::new(
                    cam_tbl.get::<_, f32>("x").unwrap_or(0.0),
                    cam_tbl.get::<_, f32>("y").unwrap_or(0.0),
                    cam_tbl.get::<_, f32>("z").unwrap_or(5.0),
                    cam_tbl.get::<_, f32>("tx").unwrap_or(0.0),
                    cam_tbl.get::<_, f32>("ty").unwrap_or(0.0),
                    cam_tbl.get::<_, f32>("tz").unwrap_or(0.0),
                    cam_tbl.get::<_, f32>("fov").unwrap_or(60.0),
                );
                let (cam_pos, cam_tgt, fov_y) = cam.to_vecs();
                let mesh = this
                    .model
                    .project_to_mesh(cam_pos, cam_tgt, fov_y, screen_w, screen_h, None);
                let out = lua.create_table()?;
                for (i, v) in mesh.vertices.iter().enumerate() {
                    let row = lua.create_table()?;
                    row.set(1, v.x)?;
                    row.set(2, v.y)?;
                    row.set(3, v.u)?;
                    row.set(4, v.v)?;
                    row.set(5, v.r)?;
                    row.set(6, v.g)?;
                    row.set(7, v.b)?;
                    row.set(8, v.a)?;
                    out.set(i + 1, row)?;
                }
                Ok(out)
            },
        );
    }
}
