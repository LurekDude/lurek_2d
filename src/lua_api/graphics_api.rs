//! `luna.graphics` Lua API bindings.
//!
//! Auto-generated skeleton from `src/graphics/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaColor ────────────────────────────────────────────────────────────

pub struct LuaColor(/* TODO: add key + state fields */);


impl LuaColor {
    /// Converts the color to a packed `u32` RGB value suitable for packed pixel buffers.
    ///
    /// Alpha is discarded. Bit layout: `0x00RRGGBB`.
    ///
    ///
    /// @return integer
    pub fn to_rgb_u32(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaColor {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("toRgbU32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaCompoundShape ────────────────────────────────────────────────────────────

pub struct LuaCompoundShape(/* TODO: add key + state fields */);


impl LuaCompoundShape {
    /// Returns the number of commands currently in the queue.
    ///
    ///
    /// @return integer
    pub fn command_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaCompoundShape {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("commandCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDecalSurface ────────────────────────────────────────────────────────────

pub struct LuaDecalSurface(/* TODO: add key + state fields */);


impl LuaDecalSurface {
    /// Returns the surface width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_width(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the surface height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDecalSurface {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDrawLayer ────────────────────────────────────────────────────────────

pub struct LuaDrawLayer(/* TODO: add key + state fields */);


impl LuaDrawLayer {
    /// Returns the number of queued entries. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDrawLayer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaFont ────────────────────────────────────────────────────────────

pub struct LuaFont(/* TODO: add key + state fields */);


impl LuaFont {
    /// Returns the vertical line height (ascent - descent + line gap) in pixels.
    ///
    ///
    /// @return number
    pub fn line_height(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the font's ascent (distance from baseline to top) in pixels.
    ///
    ///
    /// @return number
    pub fn ascent(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the font's descent (distance from baseline to bottom, typically negative) in pixels.
    ///
    ///
    /// @return number
    pub fn descent(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns `true` if the atlas has been modified since the last `mark_clean()` call.
    ///
    ///
    /// @return boolean
    pub fn is_dirty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the font size in pixels that this font was created with.
    ///
    ///
    /// @return number
    pub fn size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaFont {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("lineHeight", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("ascent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("descent", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isDirty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("size", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaMesh ────────────────────────────────────────────────────────────

pub struct LuaMesh(/* TODO: add key + state fields */);


impl LuaMesh {
    /// Gets a vertex at the given index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_vertex(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of vertices. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn vertex_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Expands vertices into a list of triangle indices based on the draw mode.
    ///
    ///
    /// @return table
    pub fn triangulate(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaMesh {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getVertex", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("vertexCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("triangulate", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaNineSlice ────────────────────────────────────────────────────────────

pub struct LuaNineSlice(/* TODO: add key + state fields */);


impl LuaNineSlice {
    /// Returns the 9 source and destination rectangles for rendering.
    ///
    /// Each entry is `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
    ///
    /// @param x : Destination
    /// @param y : Destination
    /// @param w : Destination
    /// @param h : Destination
    /// @return An
    pub fn patches(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNineSlice {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("patches", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaShader ────────────────────────────────────────────────────────────

pub struct LuaShader(/* TODO: add key + state fields */);


impl LuaShader {
    /// Returns whether a uniform with the given name has been set.
    ///
    /// @param name : str
    /// @return boolean
    pub fn has_uniform(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaShader {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("hasUniform", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSpriteBatch ────────────────────────────────────────────────────────────

pub struct LuaSpriteBatch(/* TODO: add key + state fields */);


impl LuaSpriteBatch {
    /// Returns the texture key this batch draws from.
    ///
    ///
    /// @return TextureKey
    pub fn texture_key(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of entries in the batch.
    ///
    ///
    /// @return integer
    pub fn len(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns true if the batch has no entries.
    ///
    ///
    /// @return boolean
    pub fn is_empty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the maximum number of entries (buffer size). 0 means unlimited.
    ///
    ///
    /// @return integer
    pub fn buffer_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSpriteBatch {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("textureKey", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("len", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEmpty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("bufferSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaSpriteSheet ────────────────────────────────────────────────────────────

pub struct LuaSpriteSheet(/* TODO: add key + state fields */);


impl LuaSpriteSheet {
    /// Return the quad for a 0-based frame index.
    ///
    /// @param index : integer
    /// @return Rect?
    pub fn get_frame(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Total number of frames in the sheet. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_frame_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return all frame quads in a 0-based row.
    ///
    /// @param row : integer
    /// @return table
    pub fn get_row(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return all frame quads in a 0-based column.
    ///
    /// @param col : integer
    /// @return table
    pub fn get_column(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return a contiguous range of frame quads starting at `start` (0-based).
    ///
    /// @param start : integer
    /// @param count : integer
    /// @return table
    pub fn get_range(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the frame quads for a named group.
    ///
    /// @param name : str
    /// @return table?
    pub fn get_group(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the names of all defined groups. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return table
    pub fn get_group_names(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return the frame quads for a 0-based direction index.
    ///
    /// @param direction : integer
    /// @return table?
    pub fn get_direction_frames(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaSpriteSheet {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getFrame", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getFrameCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRow", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getColumn", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRange", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGroup", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getGroupNames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDirectionFrames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTextureAtlas ────────────────────────────────────────────────────────────

pub struct LuaTextureAtlas(/* TODO: add key + state fields */);


impl LuaTextureAtlas {
    /// Looks up a previously packed region by name.
    ///
    /// @param name : str
    /// @return Option<
    pub fn get_region(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of packed regions. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_region_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns all packed regions in arbitrary order.
    ///
    ///
    /// @return Vec<
    pub fn get_regions(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTextureAtlas {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getRegion", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegionCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRegions", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.graphics.* functions ──────────────────────────────────────────

/// Creates a color from `u8` RGBA components in `[0, 255]`, normalizing to `[0.0, 1.0]`.
///
///
/// @param r : Red
/// @param g : Green
/// @param b : Blue
/// @param a : Alpha
pub fn from_u8(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Queues an entry with the given z-order. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param z_order : number
/// @return integer
pub fn queue(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sorts entries by z-order ascending and drains the queue.
///
///
/// @return table
pub fn flush(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Parses a TTF/OTF font from raw bytes and pre-rasterizes printable ASCII glyphs.
///
///
/// @param data : Raw
/// @param size : Font
pub fn from_bytes(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Ensures a glyph is rasterized and present in the atlas cache.
///
/// If the character has already been rasterized, this is a no-op.
/// Otherwise the glyph is rasterized via fontdue and packed into the atlas.
///
///
/// @param ch : The
pub fn ensure_glyph(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns the total advance width of the given text string in pixels.
///
/// Ensures all characters are rasterized before measuring.
///
/// @param text : The
/// @return The
pub fn text_width(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the vertical line height in pixels.
///
///
/// @param height : number
pub fn set_line_height(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns glyph information for a character, rasterizing it on demand if needed.
///
///
/// @param ch : The
pub fn glyph(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Break text into lines that fit within `limit` pixel width.
///
/// @param text : str
/// @param limit : number
/// @return table
pub fn wrap_text(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Updates the viewport uniform after a window resize.
///
///
/// @param width : integer
/// @param height : integer
pub fn resize(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Uploads raw RGBA8 pixel data as a new GPU texture stored under the given key.
///
///
/// @param key : TextureKey
/// @param pixels : [u8]
/// @param width : integer
/// @param height : integer
/// @param default_filter : (String, String, u32)
pub fn upload_texture(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates an off-screen GPU canvas texture stored under the given key.
///
///
/// @param key : CanvasKey
/// @param width : integer
/// @param height : integer
/// @param default_filter : (String, String, u32)
pub fn create_canvas(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Processes a frame: uploads new textures, tessellates commands, renders to surface, presents.
///
///
/// @param surface : wgpu::Surface<'static>
/// @param commands : [DrawCommand]
/// @param textures : SlotMap<TextureKey, TextureData>
/// @param fonts : mut SlotMap<FontKey, crate::graphics::Font>
/// @param sprite_batches : SlotMap<SpriteBatchKey, crate::graphics::SpriteBatch>
/// @param canvases : SlotMap<CanvasKey, crate::graphics::Canvas>
/// @param meshes : SlotMap<MeshKey, Mesh>
/// @param shaders : SlotMap<ShaderKey, Shader>
/// @param default_filter : (String, String, u32)
/// @param background_color : [f32
/// @param capture_screenshot : boolean
pub fn render_frame(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a mesh from a vector of vertices.
///
/// @param vertices : table
/// @param mode : MeshDrawMode
/// @return Self
pub fn from_vertices(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a single vertex at the given index.
///
///
/// @param index : integer
/// @param vertex : MeshVertex
pub fn set_vertex(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the index buffer for indexed drawing.
///
///
/// @param indices : table
pub fn set_vertex_map(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the texture for this mesh. Replaces the current texture value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param texture : TextureKey?
pub fn set_texture(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the draw mode. Replaces the current draw mode value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param mode : MeshDrawMode
pub fn set_draw_mode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets a uniform value by name. Delivery is immediate and synchronous; all connected handlers run before this method returns.
///
///
/// @param name : string
/// @param value : UniformValue
pub fn send(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Appends a drawing command to the shape's command queue.
///
///
/// @param cmd : ShapeCommand
pub fn push_command(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the world-space position of the sprite.
///
///
/// @param x : New
/// @param y : New
pub fn set_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the per-axis scale of the sprite. Replaces the current scale value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param sx : Horizontal
/// @param sy : Vertical
pub fn set_scale(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the rotation of the sprite in radians.
///
///
/// @param rotation : Rotation
pub fn set_rotation(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the multiplicative tint color applied to the sprite.
///
///
/// @param color : New
pub fn set_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a sprite entry to the batch. Returns the index of the added entry.
///
/// @param entry : BatchEntry
/// @return integer?
pub fn add(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Store a named frame group. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @param name : impl Into<String>
/// @param start_frame : integer
/// @param count : integer
pub fn name_group(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the directional mode (4 or 8 directions) and layout.
///
///
/// @param count : integer
/// @param layout : DirectionLayout
pub fn set_directions(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a texture from raw RGBA pixel data (not premultiplied).
///
/// @param width : integer
/// @param height : integer
/// @param pixels : table
/// @param textures : mut SlotMap<TextureKey, TextureData>
/// @return EngineResult<Self>
pub fn from_rgba(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Packs a named region of size `w` x `h` into the atlas.
///
/// @param name : str
/// @param w : integer
/// @param h : integer
/// @return boolean
pub fn pack(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.graphics` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("fromU8", lua.create_function(from_u8)?)?;
    tbl.set("queue", lua.create_function(queue)?)?;
    tbl.set("flush", lua.create_function(flush)?)?;
    tbl.set("fromBytes", lua.create_function(from_bytes)?)?;
    tbl.set("ensureGlyph", lua.create_function(ensure_glyph)?)?;
    tbl.set("textWidth", lua.create_function(text_width)?)?;
    tbl.set("setLineHeight", lua.create_function(set_line_height)?)?;
    tbl.set("glyph", lua.create_function(glyph)?)?;
    tbl.set("wrapText", lua.create_function(wrap_text)?)?;
    tbl.set("resize", lua.create_function(resize)?)?;
    tbl.set("uploadTexture", lua.create_function(upload_texture)?)?;
    tbl.set("createCanvas", lua.create_function(create_canvas)?)?;
    tbl.set("renderFrame", lua.create_function(render_frame)?)?;
    tbl.set("fromVertices", lua.create_function(from_vertices)?)?;
    tbl.set("setVertex", lua.create_function(set_vertex)?)?;
    tbl.set("setVertexMap", lua.create_function(set_vertex_map)?)?;
    tbl.set("setTexture", lua.create_function(set_texture)?)?;
    tbl.set("setDrawMode", lua.create_function(set_draw_mode)?)?;
    tbl.set("send", lua.create_function(send)?)?;
    tbl.set("pushCommand", lua.create_function(push_command)?)?;
    tbl.set("setPosition", lua.create_function(set_position)?)?;
    tbl.set("setScale", lua.create_function(set_scale)?)?;
    tbl.set("setRotation", lua.create_function(set_rotation)?)?;
    tbl.set("setColor", lua.create_function(set_color)?)?;
    tbl.set("add", lua.create_function(add)?)?;
    tbl.set("nameGroup", lua.create_function(name_group)?)?;
    tbl.set("setDirections", lua.create_function(set_directions)?)?;
    tbl.set("fromRgba", lua.create_function(from_rgba)?)?;
    tbl.set("pack", lua.create_function(pack)?)?;
    luna.set("graphics", tbl)?;
    Ok(())
}
