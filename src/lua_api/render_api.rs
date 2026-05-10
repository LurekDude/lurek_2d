//! `lurek.graphic` - 2D drawing, images, fonts, canvases, meshes, shaders and sprite batches.

use super::SharedState;
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;

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

// ===============================================================================
// UserData wrapper types
// ===============================================================================

// -------------------------------------------------------------------------------
// LuaImage UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a loaded texture stored in SharedState.
///
/// # Fields
/// Lua-side wrapper around a raw [`ImageData`] pixel buffer.
pub struct LuaImageData {
    pub(crate) inner: ImageData,
}

impl LuaUserData for LuaImageData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the pixel width of this image buffer.
        /// @return | integer | Pixel width of this image buffer.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.width()));

        // -- getHeight --
        /// Returns the pixel height of this image buffer.
        /// @return | integer | Pixel height of this image buffer.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.height()));
        // -- resize --
        /// Returns a resized copy of this image buffer.
        /// @param | width | integer | Target width in pixels.
        /// @param | height | integer | Target height in pixels.
        /// @return | LImageData | Resized image data, or nil if the resize cannot produce an image.
        methods.add_method("resize", |lua, this, (w, h): (u32, u32)| {
            match this.inner.resize(w, h) {
                Some(img) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaImageData { inner: img })?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- blit --
        /// Blits another image buffer onto this image at the destination position.
        /// @param | src | LImageData | Source image data to copy from.
        /// @param | dst_x | integer | Destination x position in pixels.
        /// @param | dst_y | integer | Destination y position in pixels.
        /// @return | nil | No return value.
        methods.add_method_mut(
            "blit",
            |_, this, (src_ud, dst_x, dst_y): (LuaAnyUserData, i32, i32)| {
                let src_ref = src_ud.borrow::<LuaImageData>()?;
                this.inner.blit(&src_ref.inner, dst_x, dst_y);
                Ok(())
            },
        );

        // -- getRegion --
        /// Returns a copy of a rectangular region from this image buffer.
        /// @param | x | integer | Left edge of the region in pixels.
        /// @param | y | integer | Top edge of the region in pixels.
        /// @param | width | integer | Region width in pixels.
        /// @param | height | integer | Region height in pixels.
        /// @return | LImageData | Copied image region, or nil if the region is empty or outside the image.
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
        /// Returns the summed per-channel difference between this image and another image.
        /// @param | other | LImageData | Image data to compare against.
        /// @return | integer | Sum of absolute per-channel differences.
        methods.add_method("diff", |_, this, other_ud: LuaAnyUserData| {
            let other_ref = other_ud.borrow::<LuaImageData>()?;
            Ok(this.inner.diff(&other_ref.inner))
        });

        // -- mapPixels --
        /// Applies a Lua callback to each pixel in this image buffer.
        /// @param | fn | function | Callback that receives x, y, r, g, b, a and returns r, g, b, a.
        /// @return | nil | No return value.
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
        /// Returns the Lua type name for this image data object.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LImageData"));

        // -- typeOf --
        /// Returns whether this object matches a requested type name.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True when the name matches this type or a parent type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "ImageData" || name == "Object")
        });
    }
}

/// Lua-side handle to a loaded GPU texture stored in the engine's texture pool.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `TextureKey`.
///
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
        /// @return | number | Top inset value.
        /// @return | number | Right inset value.
        /// @return | number | Bottom inset value.
        /// @return | number | Left inset value.
        methods.add_method("getInsets", |_, this, ()| {
            Ok((this.top, this.right, this.bottom, this.left))
        });
        // -- getTextureSize --
        /// Returns the width and height of the source texture.
        /// @return | integer | Source texture width in pixels.
        /// @return | integer | Source texture height in pixels.
        methods.add_method("getTextureSize", |_, this, ()| Ok((this.tex_w, this.tex_h)));
        // -- type --
        /// Returns the Lua type name for this object.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LNineSlice"));

        // -- typeOf --
        /// Returns whether this object matches a requested type name.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True when the name matches this type or a parent type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "NineSlice" || name == "Object")
        });
    }
}

impl LuaUserData for LuaImage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getId --
        /// Returns the internal numeric texture handle used by low-level render systems.
        /// @return | integer | Opaque texture handle id.
        methods.add_method("getId", |_, this, ()| Ok(this.key.data().as_ffi()));

        // -- getWidth --
        /// Returns the width of this image in pixels.
        /// @return | integer | Image width in pixels.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.width)
        });

        // -- getHeight --
        /// Returns the height of this image in pixels.
        /// @return | integer | Image height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok(td.height)
        });

        // -- getDimensions --
        /// Returns width and height of this image.
        /// @return | integer | Image width in pixels.
        /// @return | integer | Image height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let td = st.textures.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Image handle is not valid or was released".into())
            })?;
            Ok((td.width, td.height))
        });

        // -- release --
        /// Releases the GPU texture memory for this image.
        /// @return | boolean | True when the image was released.
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
        /// Returns the Lua type name for this image object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Image"));

        // -- type --
        /// Returns the Lua type name for this image handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LImage"));
    }
}

// -------------------------------------------------------------------------------
// LuaFont UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a loaded font stored in SharedState.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `FontKey`.
///
#[derive(Clone)]
pub struct LuaFont {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: FontKey,
}

impl LuaUserData for LuaFont {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the rendered width of the given text string.
        /// @param | text | string | Text to measure.
        /// @return | number | Rendered width of the text.
        methods.add_method("getWidth", |_, this, text: String| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.text_width(&text))
        });

        // -- getHeight --
        /// Returns the line height of this font.
        /// @return | number | Line height of this font.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });

        // -- getLineHeight --
        /// Returns the line height multiplier of this font.
        /// @return | number | Line height multiplier of this font.
        methods.add_method("getLineHeight", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.line_height())
        });

        // -- setLineHeight --
        /// Sets the line height multiplier for this font.
        /// @param | height | number | New line height multiplier.
        /// @return | nil | No return value.
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
        /// @return | number | Font ascent in pixels.
        methods.add_method("getAscent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.ascent())
        });

        // -- getDescent --
        /// Returns the descent of this font in pixels.
        /// @return | number | Font descent in pixels.
        methods.add_method("getDescent", |_, this, ()| {
            let st = this.state.borrow();
            let font = st.fonts.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Font handle is not valid or was released".into())
            })?;
            Ok(font.descent())
        });

        // -- getWrap --
        /// Wraps text to the given width and returns the lines.
        /// @param | text | string | Text to wrap.
        /// @param | limit | number | Maximum line width.
        /// @return | table | Wrapped lines as an array of strings.
        /// @return | number | Width of the widest wrapped line.
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
        /// @return | boolean | True when the font was released.
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
        /// Returns the Lua type name for this font object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Font"));

        // -- type --
        /// Returns the Lua type name for this font handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LFont"));
    }
}

// -------------------------------------------------------------------------------
// LuaCanvas UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to an off-screen render target stored in SharedState.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `CanvasKey`.
///
#[derive(Clone)]
pub struct LuaCanvas {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: CanvasKey,
}

impl LuaUserData for LuaCanvas {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getWidth --
        /// Returns the width of this canvas in pixels.
        /// @return | integer | Canvas width in pixels.
        methods.add_method("getWidth", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.width)
        });

        // -- getHeight --
        /// Returns the height of this canvas in pixels.
        /// @return | integer | Canvas height in pixels.
        methods.add_method("getHeight", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok(c.height)
        });

        // -- getDimensions --
        /// Returns width and height of this canvas.
        /// @return | integer | Canvas width in pixels.
        /// @return | integer | Canvas height in pixels.
        methods.add_method("getDimensions", |_, this, ()| {
            let st = this.state.borrow();
            let c = st.canvases.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Canvas handle is not valid or was released".into())
            })?;
            Ok((c.width, c.height))
        });

        // -- release --
        /// Releases GPU framebuffer memory for this canvas.
        /// @return | boolean | True when the canvas was released.
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
        /// Returns the Lua type name for this canvas object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Canvas"));

        // -- type --
        /// Returns the Lua type name for this canvas handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LCanvas"));
    }
}

// -------------------------------------------------------------------------------
// LuaSpriteBatch UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a sprite batch stored in SharedState.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `SpriteBatchKey`.
///
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
        /// @param | x | number | Sprite x position.
        /// @param | y | number | Sprite y position.
        /// @param | r | number? | Sprite rotation in radians.
        /// @param | sx | number? | Horizontal scale.
        /// @param | sy | number? | Vertical scale.
        /// @param | ox | number? | Origin x offset.
        /// @param | oy | number? | Origin y offset.
        /// @return | integer | Index of the added sprite entry.
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
        /// @return | nil | No return value.
        methods.add_method("clear", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(batch) = st.sprite_batches.get_mut(this.key) {
                batch.clear();
            }
            Ok(())
        });

        // -- getCount --
        /// Returns the number of sprites in this batch.
        /// @return | integer | Number of sprites in this batch.
        methods.add_method("getCount", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
            })?;
            Ok(batch.len())
        });

        // -- getBufferSize --
        /// Returns the maximum capacity of this batch.
        /// @return | integer | Maximum number of sprites the batch can hold.
        methods.add_method("getBufferSize", |_, this, ()| {
            let st = this.state.borrow();
            let batch = st.sprite_batches.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("SpriteBatch handle is not valid or was released".into())
            })?;
            Ok(batch.buffer_size())
        });

        // -- release --
        /// Releases this sprite batch.
        /// @return | boolean | True when the sprite batch was released.
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.sprite_batches.remove(this.key).is_some())
        });

        // -- typeOf --
        /// Returns the Lua type name for this sprite batch object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("SpriteBatch"));

        // -- type --
        /// Returns the Lua type name for this sprite batch handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LSpriteBatch"));
    }
}

// -------------------------------------------------------------------------------
// LuaMesh UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a mesh stored in SharedState.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `MeshKey`.
///
#[derive(Clone)]
pub struct LuaMesh {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: MeshKey,
}

impl LuaUserData for LuaMesh {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getVertexCount --
        /// Returns the number of vertices in this mesh.
        /// @return | integer | Number of vertices in this mesh.
        methods.add_method("getVertexCount", |_, this, ()| {
            let st = this.state.borrow();
            let mesh = st.meshes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Mesh handle is not valid or was released".into())
            })?;
            Ok(mesh.vertex_count())
        });

        // -- getVertex --
        /// Returns vertex data at the given 1-based index.
        /// @param | index | integer | 1-based vertex index.
        /// @return | number | Vertex X position.
        /// @return | number | Vertex Y position.
        /// @return | number | Texture U coordinate.
        /// @return | number | Texture V coordinate.
        /// @return | number | Red component.
        /// @return | number | Green component.
        /// @return | number | Blue component.
        /// @return | number | Alpha component.
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
        /// @param | index | integer | 1-based vertex index.
        /// @param | data | table | Vertex data table with x, y, u, v, r, g, b, a values.
        /// @return | nil | No return value.
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
        /// @param | image | LImage? | Image to assign as the mesh texture, or nil to clear it.
        /// @return | nil | No return value.
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
        /// Releases the GPU mesh resource, freeing VRAM immediately.
        /// @return | boolean | True when the mesh was released.
        methods.add_method("release", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            Ok(st.meshes.remove(this.key).is_some())
        });

        // -- typeOf --
        /// Returns the Lua type name for this mesh object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Mesh"));

        // -- type --
        /// Returns the Lua type name for this mesh handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LMesh"));
    }
}

// -------------------------------------------------------------------------------
// LuaShader UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a compiled shader stored in SharedState.
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `ShaderKey`.
///
#[derive(Clone)]
pub struct LuaShader {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShaderKey,
}

impl LuaUserData for LuaShader {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- send --
        /// Sends a uniform value to this shader.
        /// @param | name | string | Uniform name.
        /// @param | value | any | Uniform value to send.
        /// @return | nil | No return value.
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
        /// @param | name | string | Uniform name to check.
        /// @return | boolean | True when the shader defines the uniform.
        methods.add_method("hasUniform", |_, this, name: String| {
            let st = this.state.borrow();
            let shader = st.shaders.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shader handle is not valid or was released".into())
            })?;
            Ok(shader.has_uniform(&name))
        });

        // -- release --
        /// Releases the compiled GPU shader, freeing VRAM and shader slots.
        /// @return | boolean | True when the shader was released.
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
        /// Returns the Lua type name for this shader object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Shader"));

        // -- type --
        /// Returns the Lua type name for this shader handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LShader"));
    }
}

// -------------------------------------------------------------------------------
// LuaQuad UserData
// -------------------------------------------------------------------------------

/// Lua-side quad viewport into a texture.
///
/// # Fields
/// - `x` - `f32`.
/// - `y` - `f32`.
/// - `w` - `f32`.
/// - `h` - `f32`.
/// - `sw` - `f32`.
/// - `sh` - `f32`.
///
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
        /// @return | number | Viewport X coordinate.
        /// @return | number | Viewport Y coordinate.
        /// @return | number | Viewport width.
        /// @return | number | Viewport height.
        methods.add_method("getViewport", |_, this, ()| {
            Ok((this.x, this.y, this.w, this.h))
        });

        // -- setViewport --
        /// Sets the quad viewport rectangle.
        /// @param | x | number | Viewport x position.
        /// @param | y | number | Viewport y position.
        /// @param | w | number | Viewport width.
        /// @param | h | number | Viewport height.
        /// @return | nil | No return value.
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
        /// @return | number | Reference texture width.
        /// @return | number | Reference texture height.
        methods.add_method("getTextureDimensions", |_, this, ()| Ok((this.sw, this.sh)));

        // -- typeOf --
        /// Returns the Lua type name for this quad object.
        /// @return | string | Lua type name for this object.
        methods.add_method("typeOf", |_, _, ()| Ok("Quad"));

        // -- type --
        /// Returns the Lua type name for this quad handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LQuad"));
    }
}

// ===============================================================================
// Helpers
// ===============================================================================

// Converts a Lua value to a `UniformValue`.
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

// Parses a mode string into DrawMode.
fn parse_draw_mode(mode: &str) -> Result<DrawMode, LuaError> {
    match mode {
        "fill" => Ok(DrawMode::Fill),
        "line" => Ok(DrawMode::Line),
        other => Err(LuaError::RuntimeError(format!(
            "unknown draw mode: '{other}'"
        ))),
    }
}

// Parses a blend mode string into BlendMode.
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

// -------------------------------------------------------------------------------
// LuaShape UserData
// -------------------------------------------------------------------------------

/// Lua-side handle to a [`CompoundShape`] stored in [`SharedState::shapes`].
///
/// # Fields
/// - `state` - `Rc<RefCell<SharedState>>`.
/// - `key` - `ShapeKey`.
///
///
/// Created via `lurek.graphic.newShape()`. Builder methods accumulate draw commands
/// in the backing slot; `shape:draw(x, y)` queues a `DrawShape` command each frame.
#[derive(Clone)]
pub struct LuaShape {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: ShapeKey,
}

impl LuaUserData for LuaShape {
    #[allow(clippy::type_complexity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getCommandCount --
        /// Returns the number of drawing commands currently stored.
        /// @return | integer | Number of drawing commands stored in this shape.
        methods.add_method("getCommandCount", |_, this, ()| {
            let st = this.state.borrow();
            let shape = st.shapes.get(this.key).ok_or_else(|| {
                LuaError::RuntimeError("Shape handle is stale or was released".into())
            })?;
            Ok(shape.command_count() as i64)
        });

        // -- clear --
        /// Removes all commands and resets the shape to empty.
        /// @return | nil | No return value.
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
        /// @param | r | number | Red channel in the range 0 to 1.
        /// @param | g | number | Green channel in the range 0 to 1.
        /// @param | b | number | Blue channel in the range 0 to 1.
        /// @param | a | number? | Alpha channel in the range 0 to 1, defaulting to 1.
        /// @return | nil | No return value.
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
        /// @param | w | number | Stroke width in pixels.
        /// @return | nil | No return value.
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
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x | number | Rectangle x position.
        /// @param | y | number | Rectangle y position.
        /// @param | w | number | Rectangle width.
        /// @param | h | number | Rectangle height.
        /// @return | nil | No return value.
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
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x | number | Rectangle x position.
        /// @param | y | number | Rectangle y position.
        /// @param | w | number | Rectangle width.
        /// @param | h | number | Rectangle height.
        /// @param | rx | number | Horizontal corner radius.
        /// @param | ry | number? | Vertical corner radius, defaulting to rx.
        /// @return | nil | No return value.
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
        /// Queues a filled or outlined circle draw command onto this shape.
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x | number | Circle center x position.
        /// @param | y | number | Circle center y position.
        /// @param | r | number | Circle radius.
        /// @return | nil | No return value.
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
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x | number | Ellipse center x position.
        /// @param | y | number | Ellipse center y position.
        /// @param | rx | number | Horizontal radius.
        /// @param | ry | number | Vertical radius.
        /// @return | nil | No return value.
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
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x1 | number | First vertex x position.
        /// @param | y1 | number | First vertex y position.
        /// @param | x2 | number | Second vertex x position.
        /// @param | y2 | number | Second vertex y position.
        /// @param | x3 | number | Third vertex x position.
        /// @param | y3 | number | Third vertex y position.
        /// @return | nil | No return value.
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
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | ... | number | Flat x and y coordinate pairs, with at least three vertices.
        /// @return | nil | No return value.
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
        /// @param | x1 | number | Start x position.
        /// @param | y1 | number | Start y position.
        /// @param | x2 | number | End x position.
        /// @param | y2 | number | End y position.
        /// @return | nil | No return value.
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
        /// @param | ... | number | Flat x and y coordinate pairs, with at least two points.
        /// @return | nil | No return value.
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
        /// Queues a filled or outlined arc draw command onto this shape.
        /// @param | mode | string | Draw mode, typically "fill" or "line".
        /// @param | x | number | Arc center x position.
        /// @param | y | number | Arc center y position.
        /// @param | r | number | Arc radius.
        /// @param | astart | number | Start angle in radians.
        /// @param | aend | number | End angle in radians.
        /// @param | segments | integer? | Segment count, defaulting to 32.
        /// @return | nil | No return value.
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
        /// Queues this shape for drawing at the given position.
        /// @param | x | number | World x position.
        /// @param | y | number | World y position.
        /// @param | rotation | number? | Rotation in radians, defaulting to 0.
        /// @param | sx | number? | Horizontal scale, defaulting to 1.
        /// @param | sy | number? | Vertical scale, defaulting to 1.
        /// @param | ox | number? | Origin x offset in object space, defaulting to 0.
        /// @param | oy | number? | Origin y offset in object space, defaulting to 0.
        /// @return | nil | No return value.
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
        /// Returns whether this object matches a requested type name.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True when the name matches this type or a parent type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Shape" || name == "Object")
        });

        // -- type --
        /// Returns the Lua type name for this shape handle.
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LShape"));
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
        // -- queue --
        /// Queues a draw callback for later execution.
        /// @param | z | number | Z order for the callback.
        /// @param | fn | function | Callback to queue.
        /// @return | nil | No return value.
        methods.add_method_mut("queue", |lua, this, (z, f): (f64, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            this.entries.push((z, key));
            Ok(())
        });

        // -- flush --
        /// Sorts and calls all queued callbacks, then empties the queue.
        /// @return | nil | No return value.
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
        /// Removes all queued callbacks without calling them.
        /// @return | nil | No return value.
        methods.add_method_mut("clear", |lua, this, ()| {
            for (_, key) in this.entries.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- getCount --
        /// Returns the number of queued callbacks.
        /// @return | number | Number of queued callbacks.
        methods.add_method("getCount", |_, this, ()| Ok(this.entries.len() as i64));

        // -- type --
        /// Returns the string type identifier of this draw layer (for example `LDrawLayer`).
        /// @return | string | Lua type name for this object.
        methods.add_method("type", |_, _, ()| Ok("LDrawLayer"));

        // -- typeOf --
        /// Returns true if this object is an instance of the given type name.
        /// @param | name | string | Type name to test.
        /// @return | boolean | True when the name matches this type or a parent type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDrawLayer" || name == "DrawLayer" || name == "Object")
        });
    }
}

// ===============================================================================
// Registration
// ===============================================================================

/// Registers the lurek.graphic namespace on the given Lua table.
/// @param | lua | &Lua | Lua state that owns the namespace.
/// @param | lurek | &LuaTable | Root lurek table to extend.
/// @param | state | Rc<RefCell<SharedState>> | Shared engine state used by the bindings.
/// @return | nil | No return value.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let graphics = lua.create_table()?;

    // ---------------------------------------------------------------------------
    // Color
    // ---------------------------------------------------------------------------

    // -- setColor --
    /// Sets the current drawing color.
    /// @param | r | number | Red channel in the range 0 to 1.
    /// @param | g | number | Green channel in the range 0 to 1.
    /// @param | b | number | Blue channel in the range 0 to 1.
    /// @param | a | number? | Alpha channel in the range 0 to 1, defaulting to 1.
    /// @return | nil | No return value.
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
    /// @return | number | Current red component.
    /// @return | number | Current green component.
    /// @return | number | Current blue component.
    /// @return | number | Current alpha component.
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
    /// @param | r | number | Red channel in the range 0 to 1.
    /// @param | g | number | Green channel in the range 0 to 1.
    /// @param | b | number | Blue channel in the range 0 to 1.
    /// @return | nil | No return value.
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
    /// @return | number | Background red component.
    /// @return | number | Background green component.
    /// @return | number | Background blue component.
    /// @return | number | Background alpha component.
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

    // -- Shape Drawing -------------------------------------------------

    // -- rectangle --
    /// Draws a filled or outlined axis-aligned rectangle at the given position.
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @param | rx | number? | Horizontal corner radius.
    /// @param | ry | number? | Vertical corner radius.
    /// @return | nil | No return value.
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

    // -- circle --
    /// Draws a filled or outlined circle at the given world-space position.
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | x | number | Circle center x position.
    /// @param | y | number | Circle center y position.
    /// @param | radius | number | Circle radius.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- ellipse --
    /// Draws a filled or outlined ellipse with independent x/y radii.
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | x | number | Ellipse center x position.
    /// @param | y | number | Ellipse center y position.
    /// @param | rx | number | Horizontal radius.
    /// @param | ry | number | Vertical radius.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- triangle --
    /// Draws a filled or outlined triangle connecting three world-space vertices.
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | x1 | number | First vertex x position.
    /// @param | y1 | number | First vertex y position.
    /// @param | x2 | number | Second vertex x position.
    /// @param | y2 | number | Second vertex y position.
    /// @param | x3 | number | Third vertex x position.
    /// @param | y3 | number | Third vertex y position.
    /// @return | nil | No return value.
    let s = state.clone();
    #[allow(clippy::type_complexity)]
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

    // -- line --
    /// Draws a line between two points.
    /// @param | x1 | number | Start x position.
    /// @param | y1 | number | Start y position.
    /// @param | x2 | number | End x position.
    /// @param | y2 | number | End y position.
    /// @return | nil | No return value.
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
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | ... | number | Flat x and y coordinate pairs, with at least three vertices.
    /// @return | nil | No return value.
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
                mode: parse_draw_mode(&mode_str)?,
                vertices,
            });
            Ok(())
        })?,
    )?;

    // -- arc --
    /// Draws a partial circle arc at the given position with specified radius and angle range.
    /// @param | mode | string | Draw mode, typically "fill" or "line".
    /// @param | x | number | Arc center x position.
    /// @param | y | number | Arc center y position.
    /// @param | radius | number | Arc radius.
    /// @param | angle1 | number | Start angle in radians.
    /// @param | angle2 | number | End angle in radians.
    /// @param | segments | integer? | Segment count, defaulting to 32.
    /// @return | nil | No return value.
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

    // -- points --
    /// Draws a batch of individual points at the specified world-space coordinates.
    /// @param | ... | any | Point coordinates passed as numbers or as a table of point pairs.
    /// @return | nil | No return value.
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

    // -- Drawing -------------------------------------------------

    // -- draw --
    /// Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
    /// @param | drawable | any | Drawable value, such as an LImage, LCanvas, LSpriteBatch, or LMesh.
    /// @param | x | number? | Draw x position, defaulting to 0.
    /// @param | y | number? | Draw y position, defaulting to 0.
    /// @param | r | number? | Rotation in radians, defaulting to 0.
    /// @param | sx | number? | Horizontal scale, defaulting to 1.
    /// @param | sy | number? | Vertical scale, defaulting to 1.
    /// @param | ox | number? | Origin x offset, defaulting to 0.
    /// @param | oy | number? | Origin y offset, defaulting to 0.
    /// @return | nil | No return value.
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
    /// @param | image | LImage | Image to draw from.
    /// @param | quad | LQuad | Quad that defines the source region.
    /// @param | x | number? | Draw x position, defaulting to 0.
    /// @param | y | number? | Draw y position, defaulting to 0.
    /// @param | r | number? | Rotation in radians, defaulting to 0.
    /// @param | sx | number? | Horizontal scale, defaulting to 1.
    /// @param | sy | number? | Vertical scale, defaulting to 1.
    /// @param | ox | number? | Origin x offset, defaulting to 0.
    /// @param | oy | number? | Origin y offset, defaulting to 0.
    /// @return | nil | No return value.
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

    // -- drawMany --
    /// Draws a list of images in a single call. Each entry is a table: {image, x, y} or
    /// {image, x, y, r, sx, sy, ox, oy}. Engine-level viewport culling is applied per entry.
    /// @param | list | table | Array of draw entries.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- printRotated --
    /// Draws text at the given position with rotation. Rotates the entire string as a block
    /// around point (x, y). Engine-level transform stack is used â€” no per-glyph math in Lua.
    /// @param | text | string | Text to draw.
    /// @param | x | number | Draw x position.
    /// @param | y | number | Draw y position.
    /// @param | angle | number | Rotation in radians.
    /// @param | scale | number? | Text scale, defaulting to 1.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Text -------------------------------------------------

    // -- print --
    /// Draws text at the given position.
    /// @param | text | string | Text to draw.
    /// @param | x | number? | Draw x position, defaulting to 0.
    /// @param | y | number? | Draw y position, defaulting to 0.
    /// @param | scale | number? | Text scale, defaulting to 1.
    /// @return | nil | No return value.
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
                        // No font available - skip rendering.
                        log::warn!("lurek.graphic.print: no font loaded, text not rendered");
                    }
                }
                Ok(())
            },
        )?,
    )?;

    // -- printf --
    /// Draws word-wrapped text within a given width.
    /// @param | text | string | Text to draw.
    /// @param | x | number | Draw x position.
    /// @param | y | number | Draw y position.
    /// @param | limit | number | Wrap width.
    /// @param | align | string? | Alignment name, defaulting to left.
    /// @return | nil | No return value.
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

    // -- printRich --
    /// Draws a sequence of styled text spans at the given position.
    /// @param | spans | table | Table of span tables with text, color, and optional scale fields.
    /// @param | x | number | Draw x position.
    /// @param | y | number | Draw y position.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Clear -------------------------------------------------

    // -- clear --
    /// Clears the draw command queue (resets the screen).
    /// @param | r | number? | Optional red channel.
    /// @param | g | number? | Optional green channel.
    /// @param | b | number? | Optional blue channel.
    /// @return | nil | No return value.
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

    // -- Line/Point Style -------------------------------------------------

    // -- setLineWidth --
    /// Sets the line width for outline drawing.
    /// @param | width | number | Line width in pixels.
    /// @return | nil | No return value.
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
    /// @return | number | Current line width.
    let s = state.clone();
    graphics.set(
        "getLineWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().line_width))?,
    )?;

    // -- setPointSize --
    /// Sets the point diameter in pixels.
    /// @param | size | number | Point size in pixels.
    /// @return | nil | No return value.
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
    /// @return | number | Current point size.
    let s = state.clone();
    graphics.set(
        "getPointSize",
        lua.create_function(move |_, ()| Ok(s.borrow().point_size))?,
    )?;

    // -- Blend Mode -------------------------------------------------

    // -- setBlendMode --
    /// Sets the blend mode for drawing.
    /// @param | mode | string | Blend mode name.
    /// @return | nil | No return value.
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
    /// @return | string | Current blend mode name.
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

    // -- Font Management -------------------------------------------------

    // -- newFont --
    /// Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
    /// @param | path_or_size | any | Font path string or built-in font height.
    /// @param | size | number? | Requested font size when loading from a file path.
    /// @return | LFont | Loaded font handle.
    let s = state.clone();
    graphics.set(
        "newFont",
        lua.create_function(move |_, args: LuaMultiValue| {
            let mut st = s.borrow_mut();

            // Handle: newFont(number) - select built-in by pixel height
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

            // Handle: newFont(integer) - select built-in by pixel height
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
    /// @param | font | LFont | Font to make active.
    /// @return | nil | No return value.
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
    /// @return | LFont | Active font handle, or nil if no active font is set.
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
    /// @return | table | Table of built-in font heights.
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
    /// @param | pixel_height | number? | Requested built-in font height, defaulting to 14.
    /// @return | LFont | Built-in font handle.
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
    /// @param | font | LFont | Font to inspect.
    /// @return | number | Font cell width.
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
    /// @param | font | LFont | Font to measure with.
    /// @param | text | string | Text to measure.
    /// @return | number | Pixel width of the text.
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
    /// @param | font | LFont | Font to inspect.
    /// @return | number | Font line height.
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
    /// @param | font | LFont | Font to inspect.
    /// @return | number | Font line height.
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
    /// Sets the line height of the given font (stub - returns nil; fonts are immutable in headless mode).
    /// @param | font | LFont | Font to target.
    /// @param | line_height | number | Requested line height.
    /// @return | nil | No return value.
    graphics.set(
        "setFontLineHeight",
        lua.create_function(|_, (_font, _lh): (LuaAnyUserData, f32)| Ok(()))?,
    )?;

    // -- getFontAscent --
    /// Returns the ascent of the given font.
    /// @param | font | LFont | Font to inspect.
    /// @return | number | Font ascent.
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
    /// @param | font | LFont | Font to inspect.
    /// @return | number | Font descent.
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
    /// @param | text | string | Text to wrap.
    /// @param | limit | number | Maximum line width.
    /// @return | table | Wrapped lines as an array of strings.
    /// @return | number | Maximum wrapped line width.
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

    // -- Image Management -------------------------------------------------

    // -- newImage --
    /// Loads an image from a file path or creates one from ImageData.
    /// @param | path_or_data | any | Image file path or image data object.
    /// @return | LImage | Loaded image handle.
    let s = state.clone();
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

    // -- Canvas Management -------------------------------------------------

    // -- newCanvas --
    /// Creates an off-screen render canvas.
    /// @param | width | integer | Canvas width in pixels.
    /// @param | height | integer | Canvas height in pixels.
    /// @return | LCanvas | Created canvas handle.
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
    /// @param | canvas | LCanvas? | Canvas to target, or nil to draw to the screen.
    /// @return | nil | No return value.
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
    /// @return | LCanvas | Active canvas handle, or nil when drawing to the screen.
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
    /// @param | canvas | LCanvas | Canvas to inspect.
    /// @return | integer | Canvas width in pixels.
    /// @return | integer | Canvas height in pixels.
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

    // -- SpriteBatch -------------------------------------------------

    // -- newSpriteBatch --
    /// Creates a new sprite batch for the given image.
    /// @param | image | LImage | Source image for the batch.
    /// @param | max_sprites | integer? | Maximum sprite count, defaulting to 1000.
    /// @return | LSpriteBatch | Created sprite batch handle.
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

    // -- Mesh -------------------------------------------------

    // -- newMesh --
    /// Creates a custom mesh from vertex data.
    /// @param | vertices | table | Vertex rows with x, y, u, v, r, g, b, a values.
    /// @param | mode | string? | Mesh draw mode, defaulting to triangles.
    /// @return | LMesh | Created mesh handle.
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

    // -- Shader -------------------------------------------------

    // -- newShader --
    /// Compiles a custom WGSL shader and returns its handle.
    /// @param | code | string | WGSL shader source code.
    /// @return | LShader | Compiled shader handle.
    let s = state.clone();
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

    // -- setShader --
    /// Sets the active shader, or clears it.
    /// @param | shader | LShader? | Shader to activate, or nil to clear it.
    /// @return | nil | No return value.
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
    /// @return | LShader | Active shader handle, or nil when no shader is active.
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

    // -- Quad -------------------------------------------------

    // -- newQuad --
    /// Creates a new Quad viewport into a texture.
    /// @param | x | number | Quad x position in the source texture.
    /// @param | y | number | Quad y position in the source texture.
    /// @param | w | number | Quad width.
    /// @param | h | number | Quad height.
    /// @param | sw | number | Reference texture width.
    /// @param | sh | number | Reference texture height.
    /// @return | LQuad | Created quad handle.
    #[allow(clippy::type_complexity)]
    graphics.set(
        "newQuad",
        lua.create_function(
            move |_, (x, y, w, h, sw, sh): (f32, f32, f32, f32, f32, f32)| {
                Ok(LuaQuad { x, y, w, h, sw, sh })
            },
        )?,
    )?;

    // -- Transform Stack -------------------------------------------------

    // -- push --
    /// Pushes the current transform onto the stack.
    /// @return | nil | No return value.
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
    /// @return | nil | No return value.
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
    /// @param | x | number | Translation amount on the x axis.
    /// @param | y | number | Translation amount on the y axis.
    /// @return | nil | No return value.
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
    /// @param | angle | number | Rotation angle in radians.
    /// @return | nil | No return value.
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
    /// @param | sx | number | Horizontal scale.
    /// @param | sy | number? | Vertical scale, defaulting to sx.
    /// @return | nil | No return value.
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
    /// @param | kx | number | Shear factor on the x axis.
    /// @param | ky | number | Shear factor on the y axis.
    /// @return | nil | No return value.
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
    /// @return | nil | No return value.
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
    /// @param | matrix | table | 3x3 affine transform matrix values.
    /// @return | nil | No return value.
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

    // -- Scissor -------------------------------------------------

    // -- setScissor --
    /// Restricts drawing to a rectangle, or clears scissor if no args.
    /// @param | x | number? | Scissor x position.
    /// @param | y | number? | Scissor y position.
    /// @param | w | number? | Scissor width.
    /// @param | h | number? | Scissor height.
    /// @return | nil | No return value.
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
    /// @return | number | Scissor X coordinate.
    /// @return | number | Scissor Y coordinate.
    /// @return | number | Scissor width.
    /// @return | number | Scissor height.
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
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @return | nil | No return value.
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

    // -- Color Mask -------------------------------------------------

    // -- setColorMask --
    /// Sets which RGBA channels are written. Reset with no args.
    /// @param | r | boolean? | Red channel write enable.
    /// @param | g | boolean? | Green channel write enable.
    /// @param | b | boolean? | Blue channel write enable.
    /// @param | a | boolean? | Alpha channel write enable.
    /// @return | nil | No return value.
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
    /// @return | boolean | Whether red writes are enabled.
    /// @return | boolean | Whether green writes are enabled.
    /// @return | boolean | Whether blue writes are enabled.
    /// @return | boolean | Whether alpha writes are enabled.
    let s = state.clone();
    graphics.set(
        "getColorMask",
        lua.create_function(move |_, ()| Ok(s.borrow().color_mask))?,
    )?;

    // -- Wireframe -------------------------------------------------

    // -- setWireframe --
    /// Enables or disables wireframe rendering.
    /// @param | enabled | boolean | True to enable wireframe rendering.
    /// @return | nil | No return value.
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
    /// @return | boolean | True when wireframe mode is active.
    let s = state.clone();
    graphics.set(
        "isWireframe",
        lua.create_function(move |_, ()| Ok(s.borrow().wireframe))?,
    )?;

    // -- Stencil -------------------------------------------------

    // -- stencil --
    /// Begins stencil writing with the given action and value.
    /// @param | action | string? | Stencil action name, defaulting to replace.
    /// @param | value | integer? | Stencil reference value, defaulting to 1.
    /// @return | nil | No return value.
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
    /// @param | compare | string? | Comparison mode name, or nil to disable stencil testing.
    /// @param | value | integer? | Stencil reference value, defaulting to 1.
    /// @return | nil | No return value.
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

    // -- Window Dimensions -------------------------------------------------

    // -- setStencilMode --
    /// Sets the stencil buffer write/test mode.
    /// @param | action | string | Stencil action name.
    /// @param | compare | string? | Comparison mode name, defaulting to always.
    /// @param | value | integer? | Reference value in the range 0 to 255.
    /// @return | nil | No return value.
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
    /// @return | string | Current stencil action.
    /// @return | string | Current stencil comparison mode.
    /// @return | integer | Current stencil reference value.
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
    /// @return | nil | No return value.
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
    /// @param | mode | string | Depth comparison mode name.
    /// @param | write | boolean? | Whether depth writes are enabled, defaulting to false.
    /// @return | nil | No return value.
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
    /// @return | string | Current depth comparison mode.
    /// @return | boolean | Whether depth writes are enabled.
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

    // -- Window Dimensions -------------------------------------------------

    // -- getWidth --
    /// Returns the window width in pixels.
    /// @return | integer | Window width in pixels.
    let s = state.clone();
    graphics.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    // -- getHeight --
    /// Returns the window height in pixels.
    /// @return | integer | Window height in pixels.
    let s = state.clone();
    graphics.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    // -- getDimensions --
    /// Returns window width and height.
    /// @return | integer | Window width in pixels.
    /// @return | integer | Window height in pixels.
    let s = state.clone();
    graphics.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // -- Default Filter -------------------------------------------------

    // -- setDefaultFilter --
    /// Sets the default texture filter mode.
    /// @param | min | string | Minification filter mode name.
    /// @param | mag | string | Magnification filter mode name.
    /// @param | anisotropy | integer? | Anisotropy level, defaulting to 1.
    /// @return | nil | No return value.
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
    /// @return | string | Default minification filter.
    /// @return | string | Default magnification filter.
    /// @return | integer | Default anisotropy level.
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

    // -- Stats -------------------------------------------------

    // -- getStats --
    /// Returns a table of renderer statistics.
    /// @return | table | Renderer statistics table.
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
            stats.set("cpu_render_ms", st.render_stats.cpu_render_ms)?;
            Ok(stats)
        })?,
    )?;

    // -- Screenshot -------------------------------------------------

    // -- saveScreenshot --
    /// Queues a screenshot to be saved after the current frame.
    /// @param | path | string | Output path, which must start with save/.
    /// @return | nil | No return value.
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
    /// @param | callback | function | Callback that receives the captured image data.
    /// @return | nil | No return value.
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
    /// @param | image | LImage | Source image.
    /// @param | top | number | Top inset.
    /// @param | right | number | Right inset.
    /// @param | bottom | number | Bottom inset.
    /// @param | left | number | Left inset.
    /// @return | LNineSlice | Created nine-slice descriptor.
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
    /// Queues a 9-slice draw call inside lurek.draw / lurek.draw_ui.
    /// @param | slice | LNineSlice | Nine-slice descriptor to draw.
    /// @param | x | number | Draw x position.
    /// @param | y | number | Draw y position.
    /// @param | width | number | Draw width.
    /// @param | height | number | Draw height.
    /// @return | nil | No return value.
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
    /// Creates a new empty shape resource.
    /// @return | LShape | Created shape handle.
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
    /// @return | LDrawLayer | Created draw layer handle.
    graphics.set(
        "newDrawLayer",
        lua.create_function(|_, ()| {
            Ok(LuaDrawLayer {
                entries: Vec::new(),
            })
        })?,
    )?;

    // -- BÄ‚Â©zier Curves -------------------------------------------------

    // -- drawQuadBezier --
    // -- drawQuadBezier --
    /// Queues a quadratic Bezier curve.
    /// @param | x1 | number | Start x position.
    /// @param | y1 | number | Start y position.
    /// @param | cx | number | Control point x position.
    /// @param | cy | number | Control point y position.
    /// @param | x2 | number | End x position.
    /// @param | y2 | number | End y position.
    /// @param | segments | integer? | Segment count, defaulting to 16.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- drawCubicBezier --
    /// Queues a cubic Bezier curve.
    /// @param | x1 | number | Start x position.
    /// @param | y1 | number | Start y position.
    /// @param | cx1 | number | First control point x position.
    /// @param | cy1 | number | First control point y position.
    /// @param | cx2 | number | Second control point x position.
    /// @param | cy2 | number | Second control point y position.
    /// @param | x2 | number | End x position.
    /// @param | y2 | number | End y position.
    /// @param | segments | integer? | Segment count, defaulting to 16.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Path Drawing -------------------------------------------------

    // -- drawPath --
    /// Queues a multi-segment vector path.
    /// @param | path | table | Path segment table.
    /// @param | mode | string? | Draw mode, defaulting to line.
    /// @param | close | boolean? | Whether to close the path, defaulting to false.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Gradient Rectangles -------------------------------------------------

    // -- drawGradientRect --
    /// Queues a gradient-filled rectangle.
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @param | color1 | table | First RGBA color table.
    /// @param | color2 | table | Second RGBA color table.
    /// @param | direction | string? | Gradient direction, defaulting to vertical.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Colored Polygons -------------------------------------------------

    // -- drawColoredPolygon --
    /// Queues a convex polygon with per-vertex colors.
    /// @param | vertices | table | Flat vertex table with x and y pairs.
    /// @param | colors | table | Per-vertex RGBA color tables.
    /// @param | mode | string? | Draw mode, defaulting to fill.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- Isometric Cube -------------------------------------------------

    // -- drawIsoCubeTile --
    /// Queues a three-face isometric cube tile.
    /// @param | sx | number | Screen x position.
    /// @param | sy | number | Screen y position.
    /// @param | halfW | number | Half tile width.
    /// @param | halfH | number | Half tile height.
    /// @param | opts | table? | Optional depth, color, and texture options.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Hex Tiles -------------------------------------------------

    // -- drawHexTile --
    /// Queues a hexagonal tile at centre (cx, cy) with given circumradius.
    /// @param | cx | number | Center x position.
    /// @param | cy | number | Center y position.
    /// @param | size | number | Hex radius.
    /// @param | orientation | string? | Orientation name, defaulting to pointyTop.
    /// @param | mode | string? | Draw mode, defaulting to line.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Depth Sort Groups -------------------------------------------------

    // -- beginSortGroup --
    /// Begins a Y/Z depth sort group. Draw commands until flushSortGroup are depth-sortable.
    /// @param | id | integer | Sort group identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "beginSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::BeginSortGroup { group_id: id });
            Ok(())
        })?,
    )?;

    // -- pushSortKey --
    /// Associates the previous draw command with a depth value within the active sort group.
    /// @param | depth | number | Depth value for the previous draw command.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "pushSortKey",
        lua.create_function(move |_, depth: f32| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PushSortKey(depth));
            Ok(())
        })?,
    )?;

    // -- flushSortGroup --
    /// Sorts and flushes all draw commands in the sort group.
    /// @param | id | integer | Sort group identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "flushSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::FlushSortGroup { group_id: id });
            Ok(())
        })?,
    )?;

    // -- Bevel Rectangles -------------------------------------------------

    // -- drawBevelRect --
    /// Queues a beveled border rectangle with inner fill.
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @param | bevelW | number? | Bevel width, defaulting to 2.
    /// @param | style | string? | Bevel style name, defaulting to raised.
    /// @param | opts | table? | Optional highlight, shadow, and fill colors.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Compositing Layers -------------------------------------------------

    // -- pushLayer --
    /// Begins a named compositing layer with optional alpha and blend mode.
    /// @param | id | integer | Layer identifier.
    /// @param | alpha | number? | Layer alpha, defaulting to 1.
    /// @param | blendMode | string? | Blend mode name, defaulting to alpha.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- popLayer --
    /// Ends and composites the named layer back to its parent.
    /// @param | id | integer | Layer identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "popLayer",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PopLayer { id });
            Ok(())
        })?,
    )?;
    // -- drawQuadBezier --
    /// Queues a quadratic Bezier curve.
    /// @param | x1 | number | Start x position.
    /// @param | y1 | number | Start y position.
    /// @param | cx | number | Control point x position.
    /// @param | cy | number | Control point y position.
    /// @param | x2 | number | End x position.
    /// @param | y2 | number | End y position.
    /// @param | segments | integer? | Segment count, defaulting to 16.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- drawCubicBezier --
    /// Queues a cubic Bezier curve.
    /// @param | x1 | number | Start x position.
    /// @param | y1 | number | Start y position.
    /// @param | cx1 | number | First control point x position.
    /// @param | cy1 | number | First control point y position.
    /// @param | cx2 | number | Second control point x position.
    /// @param | cy2 | number | Second control point y position.
    /// @param | x2 | number | End x position.
    /// @param | y2 | number | End y position.
    /// @param | segments | integer? | Segment count, defaulting to 16.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Path Drawing -------------------------------------------------

    // -- drawPath --
    /// Queues a multi-segment vector path.
    /// @param | path | table | Path segment table.
    /// @param | mode | string? | Draw mode, defaulting to line.
    /// @param | close | boolean? | Whether to close the path, defaulting to false.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Gradient Rectangles -------------------------------------------------

    // -- drawGradientRect --
    /// Queues a gradient-filled rectangle.
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @param | color1 | table | First RGBA color table.
    /// @param | color2 | table | Second RGBA color table.
    /// @param | direction | string? | Gradient direction, defaulting to vertical.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Colored Polygons -------------------------------------------------

    // -- drawColoredPolygon --
    /// Queues a convex polygon with per-vertex colors.
    /// @param | vertices | table | Flat vertex table with x and y pairs.
    /// @param | colors | table | Per-vertex RGBA color tables.
    /// @param | mode | string? | Draw mode, defaulting to fill.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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

    // -- Isometric Cube -------------------------------------------------

    // -- drawIsoCubeTile --
    /// Queues a three-face isometric cube tile.
    /// @param | sx | number | Screen x position.
    /// @param | sy | number | Screen y position.
    /// @param | halfW | number | Half tile width.
    /// @param | halfH | number | Half tile height.
    /// @param | opts | table? | Optional depth, color, and texture options.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Hex Tiles -------------------------------------------------

    // -- drawHexTile --
    /// Queues a hexagonal tile at centre (cx, cy) with given circumradius.
    /// @param | cx | number | Center x position.
    /// @param | cy | number | Center y position.
    /// @param | size | number | Hex radius.
    /// @param | orientation | string? | Orientation name, defaulting to pointyTop.
    /// @param | mode | string? | Draw mode, defaulting to line.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- Depth Sort Groups -------------------------------------------------

    // -- beginSortGroup --
    /// Begins a Y/Z depth sort group.
    /// @param | id | integer | Sort group identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "beginSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::BeginSortGroup { group_id: id });
            Ok(())
        })?,
    )?;

    // -- pushSortKey --
    /// Associates the previous draw command with a depth value within the active sort group.
    /// @param | depth | number | Depth value for the previous draw command.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "pushSortKey",
        lua.create_function(move |_, depth: f32| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PushSortKey(depth));
            Ok(())
        })?,
    )?;

    // -- flushSortGroup --
    /// Sorts and flushes all draw commands in the sort group.
    /// @param | id | integer | Sort group identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "flushSortGroup",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::FlushSortGroup { group_id: id });
            Ok(())
        })?,
    )?;

    // -- Bevel Rectangles -------------------------------------------------

    // -- drawBevelRect --
    /// Queues a beveled border rectangle.
    /// @param | x | number | Rectangle x position.
    /// @param | y | number | Rectangle y position.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @param | bevelW | number? | Bevel width, defaulting to 2.
    /// @param | style | string? | Bevel style name, defaulting to raised.
    /// @param | opts | table? | Optional highlight, shadow, and fill colors.
    /// @return | nil | No return value.
    #[allow(clippy::type_complexity)]
    let s = state.clone();
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

    // -- Compositing Layers -------------------------------------------------

    // -- pushLayer --
    /// Begins a named compositing layer. Provides alpha and blend mode for composite.
    /// @param | id | integer | Layer identifier.
    /// @param | alpha | number? | Layer alpha, defaulting to 1.
    /// @param | blendMode | string? | Blend mode name, defaulting to alpha.
    /// @return | nil | No return value.
    let s = state.clone();
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

    // -- popLayer --
    /// Ends and composites the named layer.
    /// @param | id | integer | Layer identifier.
    /// @return | nil | No return value.
    let s = state.clone();
    graphics.set(
        "popLayer",
        lua.create_function(move |_, id: u64| {
            s.borrow_mut()
                .render_commands
                .push(RenderCommand::PopLayer { id });
            Ok(())
        })?,
    )?;

    // -- Named Layer Registry -------------------------------------------------
    // A lightweight metadata registry for named render layers.  Stores
    // z-ordering and visibility without touching SharedState or GPU resources.

    let layer_zorders: Rc<RefCell<std::collections::HashMap<String, i32>>> =
        Rc::new(RefCell::new(std::collections::HashMap::new()));
    let layer_visible: Rc<RefCell<std::collections::HashMap<String, bool>>> =
        Rc::new(RefCell::new(std::collections::HashMap::new()));
    let current_layer: Rc<RefCell<String>> = Rc::new(RefCell::new("default".to_string()));

    // -- newLayer --
    /// Registers a named render layer.
    /// @param | name | string | Layer name.
    /// @param | z_order | integer? | Layer z order, defaulting to 0.
    /// @return | nil | No return value.
    let lz = layer_zorders.clone();
    let lv = layer_visible.clone();
    graphics.set(
        "newLayer",
        lua.create_function(move |_, (name, z_order): (String, Option<i32>)| {
            lz.borrow_mut().insert(name.clone(), z_order.unwrap_or(0));
            lv.borrow_mut().entry(name).or_insert(true);
            Ok(())
        })?,
    )?;

    // -- setLayer --
    /// Sets the active named layer.
    /// @param | name | string | Layer name.
    /// @return | nil | No return value.
    let cl = current_layer.clone();
    let lz2 = layer_zorders.clone();
    let lv2 = layer_visible.clone();
    graphics.set(
        "setLayer",
        lua.create_function(move |_, name: String| {
            lz2.borrow_mut().entry(name.clone()).or_insert(0);
            lv2.borrow_mut().entry(name.clone()).or_insert(true);
            *cl.borrow_mut() = name;
            Ok(())
        })?,
    )?;

    // -- currentLayer --
    /// Returns the name of the currently active named layer.
    /// @return | string | Name of the active named layer.
    let cl2 = current_layer.clone();
    graphics.set(
        "currentLayer",
        lua.create_function(move |_, ()| Ok(cl2.borrow().clone()))?,
    )?;

    // -- setLayerVisible --
    /// Shows or hides the named layer.
    /// @param | name | string | Layer name.
    /// @param | visible | boolean | Whether the layer is visible.
    /// @return | nil | No return value.
    let lv3 = layer_visible.clone();
    graphics.set(
        "setLayerVisible",
        lua.create_function(move |_, (name, visible): (String, bool)| {
            lv3.borrow_mut().insert(name, visible);
            Ok(())
        })?,
    )?;

    // -- isLayerVisible --
    /// Returns whether the named layer is visible.
    /// @param | name | string | Layer name.
    /// @return | boolean | True when the layer is visible.
    let lv4 = layer_visible.clone();
    graphics.set(
        "isLayerVisible",
        lua.create_function(move |_, name: String| Ok(*lv4.borrow().get(&name).unwrap_or(&true)))?,
    )?;

    // -- getLayerZOrder --
    /// Returns the z order of the named layer.
    /// @param | name | string | Layer name.
    /// @return | integer | Layer z order, or 0 if the layer is not registered.
    let lz3 = layer_zorders.clone();
    graphics.set(
        "getLayerZOrder",
        lua.create_function(move |_, name: String| Ok(*lz3.borrow().get(&name).unwrap_or(&0)))?,
    )?;

    // -- setLayerZOrder --
    /// Updates the z order of the named layer.
    /// @param | name | string | Layer name.
    /// @param | z_order | integer | New layer z order.
    /// @return | nil | No return value.
    let lz4 = layer_zorders.clone();
    graphics.set(
        "setLayerZOrder",
        lua.create_function(move |_, (name, z): (String, i32)| {
            lz4.borrow_mut().insert(name, z);
            Ok(())
        })?,
    )?;
    // -- loadObj --
    /// Loads a Wavefront OBJ file (relative to game dir) and returns an LObjModel.
    /// @param | path | string | Relative path, e.g. "assets/models/tank.obj".
    /// @return | LObjModel | Loaded model with projectToMesh method.
    let state_for_obj = state.clone();
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
    /// Alias for `loadObj`; loads a Wavefront OBJ file and returns an `LObjModel`.
    /// @param | path | string | Relative path to an `.obj` asset file.
    /// @return | LObjModel | Loaded model userdata.
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

    lurek.set("render", graphics)?;
    Ok(())
}

// ── OBJ loader Lua userdata ───────────────────────────────────────────────────

use crate::render::obj_loader::{ObjCamera, ObjModel};

/// Lua-side handle to a parsed Wavefront OBJ model.
pub struct LObjModel {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) model: ObjModel,
    pub(crate) sprite_cache: std::collections::HashMap<String, TextureKey>,
}

impl LuaUserData for LObjModel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getVertexCount --
        /// Returns the number of position vertices stored in this model.
        /// @return | integer | Number of position vertices.
        methods.add_method("getVertexCount", |_, this, ()| {
            Ok(this.model.vertex_count())
        });

        // -- getFaceCount --
        /// Returns the number of triangulated faces available in this model.
        /// @return | integer | Number of triangles.
        methods.add_method("getFaceCount", |_, this, ()| Ok(this.model.face_count()));

        // -- getUvCount --
        /// Returns the number of UV coordinates loaded from the OBJ file.
        /// @return | integer | Number of UV coordinates.
        methods.add_method("getUvCount", |_, this, ()| Ok(this.model.uv_count()));

        // -- getNormalCount --
        /// Returns the number of normal vectors stored in this model.
        /// @return | integer | Number of normal vectors.
        methods.add_method("getNormalCount", |_, this, ()| {
            Ok(this.model.normal_count())
        });

        // -- renderToImage --
        /// Rasterizes the model into a cached sprite image using material colors from the MTL.
        /// The output is cached by `(width,height,rotation)` and returned as `LImage`.
        ///
        /// @param | width | integer | Output sprite width.
        /// @param | height | integer | Output sprite height.
        /// @param | rotation | integer? | Quarter-turn rotation: 0,1,2,3.
        /// @return | LImage | Cached rendered sprite.
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
        /// Projects the 3-D model to a flat 2-D vertex table.
        /// Lua then calls lurek.render.newMesh(vertices) to create a drawable mesh.
        ///
        /// Camera table keys: x, y, z (position), tx, ty, tz (look-at), fov (degrees).
        ///
        /// @param | camera | table | Camera parameters.
        /// @param | screen_w | number | Output width in pixels.
        /// @param | screen_h | number | Output height in pixels.
        /// @return | table | Array of vertex rows: each row is { x, y, u, v, r, g, b, a }.
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

                // Convert mesh vertices to a Lua table of rows
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
