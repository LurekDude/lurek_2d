# render

## General Info

- Module group: `Platform Services.`
- Source path: `src/render/`
- Lua API path(s): `src/lua_api/render_api.rs`
- Primary Lua namespace: `lurek.graphic`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The render module owns the engine's core 2D rendering pipeline. It exists so Lua and higher-level systems can describe draw intent through `RenderCommand` values while the engine keeps control of batching, resource uploads, pipeline state, canvas targets, and final frame execution.

Its boundary is the command queue and backend needed to consume it: canvases, fonts, shaders, meshes, vector shapes, draw layers, decals, and lightweight effect descriptors live here because they are part of the renderer's own object model. It does not own sprite-domain data now housed under `src/sprite/`, and it does not own separate feature systems that consume rendering such as scene flow or gameplay animation.

**Scope boundary**: This module currently depends on `light`, `math`, `runtime`, `sprite`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

## Files

- `canvas.rs`: Logical off-screen render-target descriptor used by the backend and Lua canvas APIs.
- `decal_surface.rs`: Persistent descriptor for decal stamping targets.
- `draw_layer.rs`: Ordered callback queue for grouped draw-order management.
- `font.rs`: Bitmap font loading, atlas storage, glyph lookup, and text-measurement helpers.
- `gpu_renderer.rs`: Concrete wgpu renderer for device setup, resource pools, pipeline caching, and frame execution.
- `image_effect.rs`: Lightweight per-image shader-pass descriptor used by render commands.
- `mesh.rs`: Custom geometry data structures and mesh draw-mode support.
- `mod.rs`: Module root and public re-export surface for the active render submodules.
- `renderer.rs`: Render-command enum plus blend, stencil, depth, text, and texture-side data types.
- `shader.rs`: Custom WGSL shader objects, validation, and typed uniform values.
- `shape.rs`: Compound vector-shape builder and the primitive command list it records.

## Types

- `Canvas` (`struct`, `canvas.rs`): Off-screen target descriptor for drawing into textures instead of the swapchain.
- `DecalSurface` (`struct`, `decal_surface.rs`): Render-owned descriptor for decal workflows.
- `LayerEntry` (`struct`, `draw_layer.rs`): A queued draw entry with its z-order.
- `DrawLayer` (`struct`, `draw_layer.rs`): Ordered callback container for higher-level draw sequencing.
- `Font` (`struct`, `font.rs`): Render-side text resource with atlas and measurement behavior.
- `GlyphInfo` (`struct`, `font.rs`): Information about a single glyph in the atlas.
- `RenderStats` (`struct`, `gpu_renderer.rs`): Per-frame rendering statistics.
- `GpuRenderer` (`struct`, `gpu_renderer.rs`): wgpu-backed renderer that owns the actual frame, pipeline, and GPU resource logic.
- `ShaderPassDescriptor` (`struct`, `image_effect.rs`): Lightweight effect-pass description attached to image draws.
- `MeshDrawMode` (`enum`, `mesh.rs`): Drawing mode for mesh geometry.
- `MeshVertex` (`struct`, `mesh.rs`): A single vertex in a mesh.
- `Mesh` (`struct`, `mesh.rs`): Custom geometry mesh with per-vertex position, UV, and color data.
- `CompareMode` (`enum`, `renderer.rs`): Stencil comparison mode for `lurek.gfx.setStencilTest`.
- `StencilAction` (`enum`, `renderer.rs`): Stencil write action for `lurek.gfx.stencil` and `lurek.gfx.setStencilMode`.
- `StencilMode` (`struct`, `renderer.rs`): Combined stencil rendering mode stored in `SharedState`.
- `DepthMode` (`enum`, `renderer.rs`): Depth test comparison mode for `lurek.gfx.setDepthMode`.
- `TextAlign` (`enum`, `renderer.rs`): Text alignment mode for formatted text printing.
- `DrawMode` (`enum`, `renderer.rs`): Fill-versus-line enum used by vector primitives.
- `BlendMode` (`enum`, `renderer.rs`): Public blend-policy enum used by queued draw operations.
- `RenderCommand` (`enum`, `renderer.rs`): Central deferred draw-operation enum consumed by the backend.
- `TextureData` (`struct`, `renderer.rs`): CPU-side pixel container handed off for GPU texture upload.
- `ParticleRenderShape` (`enum`, `renderer.rs`): Geometric shape used when rendering a single untextured particle via `DrawParticleSystem`.
- `ParticleInstance` (`struct`, `renderer.rs`): Per-particle render data for a single frame.
- `DrawableKind` (`enum`, `renderer.rs`): Type discriminator for resources that can be passed to lurek.gfx.draw.
- `ShaderFragmentInput` (`enum`, `shader.rs`): Which fragment shader input the user's entry point expects.
- `Shader` (`struct`, `shader.rs`): Represents a compiled custom shader with its uniform values.
- `UniformValue` (`enum`, `shader.rs`): A uniform value that can be sent to a shader from Lua.
- `ShapeCommand` (`enum`, `shape.rs`): A single drawing command stored inside a [`CompoundShape`] command queue.
- `CompoundShape` (`struct`, `shape.rs`): A compound shape that accumulates draw primitives in local (object-space) coordinates and replays them as a unified entity via [`crate::render::RenderCommand::DrawShape`].

## Functions

- `Canvas::new` (`canvas.rs`): Creates a new `Canvas` descriptor with the given dimensions.
- `DecalSurface::new` (`decal_surface.rs`): Creates a new decal surface with the given pixel dimensions.
- `DecalSurface::get_dimensions` (`decal_surface.rs`): Returns the surface dimensions as `(width, height)`.
- `DecalSurface::get_width` (`decal_surface.rs`): Returns the surface width in pixels.
- `DecalSurface::get_height` (`decal_surface.rs`): Returns the surface height in pixels.
- `DrawLayer::new` (`draw_layer.rs`): Creates an empty draw layer.
- `DrawLayer::queue` (`draw_layer.rs`): Queues an entry with the given z-order.
- `DrawLayer::flush` (`draw_layer.rs`): Sorts entries by z-order ascending and drains the queue.
- `DrawLayer::clear` (`draw_layer.rs`): Discards all queued entries.
- `DrawLayer::get_count` (`draw_layer.rs`): Returns the number of queued entries.
- `Font::from_png_bytes` (`font.rs`): Creates a bitmap font from raw PNG bytes.
- `Font::load_all_sizes` (`font.rs`): Loads all 6 built-in bitmap font sizes from embedded PNGs.
- `Font::nearest_size` (`font.rs`): Returns the index into `AVAILABLE_HEIGHTS` for the nearest matching font size.
- `Font::glyph` (`font.rs`): Returns glyph information for a character by computing its UV from the grid position.
- `Font::text_width` (`font.rs`): Returns the total advance width of the given text string in pixels.
- `Font::line_height` (`font.rs`): Returns the vertical line height in pixels (cell_height x line_height_mul).
- `Font::set_line_height` (`font.rs`): Sets the line height multiplier.
- `Font::ascent` (`font.rs`): Returns the font's ascent (cell_height as f32, for backwards compatibility).
- `Font::descent` (`font.rs`): Returns the font's descent (0.0 for bitmap fonts, for backwards compatibility).
- `Font::atlas_data` (`font.rs`): Returns the atlas RGBA pixel data and its dimensions.
- `Font::is_dirty` (`font.rs`): Returns `true` if the atlas has been modified since the last `mark_clean()` call.
- `Font::mark_clean` (`font.rs`): Marks the atlas as clean (no pending changes to upload).
- `Font::size` (`font.rs`): Returns the font cell height as f32 (the effective "size" of this bitmap font).
- `Font::cell_width` (`font.rs`): Returns the glyph cell width in pixels.
- `Font::has_box_drawing` (`font.rs`): Returns whether this font includes box-drawing characters.
- `Font::wrap_text` (`font.rs`): Breaks text into lines that fit within `limit` pixel width.
- `GpuRenderer::new` (`gpu_renderer.rs`): Creates a new `GpuRenderer` from an already-created wgpu device and queue.
- `GpuRenderer::resize` (`gpu_renderer.rs`): Updates the viewport uniform after a window resize.
- `GpuRenderer::upload_texture` (`gpu_renderer.rs`): Uploads raw RGBA8 pixel data as a new GPU texture stored under the given key.
- `GpuRenderer::create_canvas` (`gpu_renderer.rs`): Creates an off-screen GPU canvas texture stored under the given key.
- `GpuRenderer::render_frame` (`gpu_renderer.rs`): Processes a frame: uploads new textures, tessellates commands, renders to surface, presents.
- `ShaderPassDescriptor::new` (`image_effect.rs`): Creates a new enabled pass with the given effect name and an empty parameter map.
- `Mesh::new` (`mesh.rs`): Creates a new empty mesh with the specified vertex count and draw mode.
- `Mesh::from_vertices` (`mesh.rs`): Creates a mesh from a vector of vertices.
- `Mesh::from_vertex_rows` (`mesh.rs`): Creates a mesh from raw per-vertex float rows (x, y, u, v, r, g, b, a).
- `Mesh::set_vertex` (`mesh.rs`): Sets a single vertex at the given index.
- `Mesh::get_vertex` (`mesh.rs`): Gets a vertex at the given index.
- `Mesh::set_vertex_map` (`mesh.rs`): Sets the index buffer for indexed drawing.
- `Mesh::vertex_count` (`mesh.rs`): Returns the number of vertices.
- `Mesh::set_texture` (`mesh.rs`): Sets the texture for this mesh.
- `Mesh::set_draw_mode` (`mesh.rs`): Sets the draw mode.
- `Mesh::triangulate` (`mesh.rs`): Expands vertices into a list of triangle indices based on the draw mode.
- `Shader::new` (`shader.rs`): Creates a new shader from WGSL source code.
- `Shader::send` (`shader.rs`): Sets a uniform value by name.
- `Shader::has_uniform` (`shader.rs`): Returns whether a uniform with the given name has been set.
- `Shader::ordered_uniforms` (`shader.rs`): Returns the current uniforms sorted by name for stable GPU binding order.
- `Shader::wrapper_source` (`shader.rs`): Returns the wrapper WGSL source that calls the user's fragment entry.
- `Shader::fragment_entry_name` (`shader.rs`): Returns the name of the user's fragment entry point.
- `Shader::fragment_inputs` (`shader.rs`): Returns the ordered list of inputs the fragment entry expects.
- `CompoundShape::new` (`shape.rs`): Creates a new empty compound shape with default color (white) and line width (1.0).
- `CompoundShape::push_command` (`shape.rs`): Appends a drawing command to the shape's command queue.
- `CompoundShape::clear` (`shape.rs`): Empties the command queue and resets color and line-width state to defaults.
- `CompoundShape::command_count` (`shape.rs`): Returns the number of commands currently in the queue.

## Lua API Reference

- Binding path(s): `src/lua_api/render_api.rs`
- Namespace: `lurek.graphic`

### Module Functions
- `lurek.render.setColor`: Sets the current drawing color.
- `lurek.render.getColor`: Returns the current drawing color.
- `lurek.render.setBackgroundColor`: Sets the background clear color.
- `lurek.render.getBackgroundColor`: Returns the current background color.
- `lurek.render.rectangle`: Draws a rectangle.
- `lurek.render.circle`: Draws a circle.
- `lurek.render.ellipse`: Draws an ellipse.
- `lurek.render.triangle`: Draws a triangle.
- `lurek.render.line`: Draws a line between two points.
- `lurek.render.polygon`: Draws a polygon from a list of vertices.
- `lurek.render.arc`: Draws a partial circle arc at the given position with specified radius and angle range.
- `lurek.render.points`: Draws a list of points.
- `lurek.render.draw`: Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
- `lurek.render.drawq`: Draws a portion of an image defined by a Quad.
- `lurek.render.print`: Draws text at the given position.
- `lurek.render.printf`: Draws word-wrapped text within a given width.
- `lurek.render.clear`: Clears the draw command queue (resets the screen).
- `lurek.render.setLineWidth`: Sets the line width for outline drawing.
- `lurek.render.getLineWidth`: Returns the current line width.
- `lurek.render.setPointSize`: Sets the point diameter in pixels.
- `lurek.render.getPointSize`: Returns the current point size.
- `lurek.render.setBlendMode`: Sets the blend mode for drawing.
- `lurek.render.getBlendMode`: Returns the current blend mode as a string.
- `lurek.render.newFont`: Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
- `lurek.render.setFont`: Sets the active font for print calls.
- `lurek.render.getFont`: Returns the currently active font, or nil.
- `lurek.render.getFontSizes`: Returns a table of available built-in font pixel heights.
- `lurek.render.getDefaultFont`: Returns a built-in font by pixel height (snaps to nearest available size).
- `lurek.render.getFontCellWidth`: Returns the cell width of the given font (for monospaced bitmap fonts).
- `lurek.render.getFontWidth`: Returns the pixel width of text in the given font.
- `lurek.render.getFontHeight`: Returns the line height of the given font.
- `lurek.render.getFontLineHeight`: Returns the line height of the given font (alias for getFontHeight).
- `lurek.render.setFontLineHeight`: Sets the line height of the given font (stub — returns nil; fonts are immutable in headless mode).
- `lurek.render.getFontAscent`: Returns the ascent of the given font.
- `lurek.render.getFontDescent`: Returns the descent of the given font.
- `lurek.render.getFontWrap`: Returns wrapped lines and the maximum line width.
- `lurek.render.newImage`: Loads an image from a file path or creates one from ImageData.
- `lurek.render.newCanvas`: Creates an off-screen render canvas.
- `lurek.render.setCanvas`: Sets the active render target to a Canvas, or back to the screen.
- `lurek.render.getCanvas`: Returns the current canvas, or nil if drawing to screen.
- `lurek.render.getCanvasSize`: Returns the dimensions of a canvas.
- `lurek.render.newSpriteBatch`: Creates a new sprite batch for the given image.
- `lurek.render.newMesh`: Creates a custom mesh from vertex data.
- `lurek.render.newShader`: Compiles a custom WGSL shader and returns its handle.
- `lurek.render.setShader`: Sets the active shader, or clears it.
- `lurek.render.getShader`: Returns the active shader, or nil.
- `lurek.render.newQuad`: Creates a new Quad viewport into a texture.
- `lurek.render.push`: Pushes the current transform onto the stack.
- `lurek.render.pop`: Pops the transform from the stack.
- `lurek.render.translate`: Translates the coordinate system.
- `lurek.render.rotate`: Rotates the coordinate system.
- `lurek.render.scale`: Scales the coordinate system.
- `lurek.render.shear`: Shears the coordinate system.
- `lurek.render.origin`: Resets the transform to the identity.
- `lurek.render.applyTransform`: Applies an affine transform matrix.
- `lurek.render.setScissor`: Restricts drawing to a rectangle, or clears scissor if no args.
- `lurek.render.getScissor`: Returns the active scissor rectangle, or nothing.
- `lurek.render.intersectScissor`: Intersects the current scissor with a new rectangle.
- `lurek.render.setColorMask`: Sets which RGBA channels are written. Reset with no args.
- `lurek.render.getColorMask`: Returns the current color mask.
- `lurek.render.setWireframe`: Enables or disables wireframe rendering.
- `lurek.render.isWireframe`: Returns whether wireframe mode is active.
- `lurek.render.stencil`: Begins stencil writing with the given action and value.
- `lurek.render.setStencilTest`: Sets the stencil comparison test, or disables stencil testing.
- `lurek.render.setStencilMode`: Sets the stencil buffer write/test mode.
- `lurek.render.getStencilMode`: Returns the current stencil mode as (action, compare, value).
- `lurek.render.clearStencil`: Resets the stencil mode to the default (keep / always / 0).
- `lurek.render.setDepthMode`: Sets the depth test comparison and write enable.
- `lurek.render.getDepthMode`: Returns the current depth mode as (mode, write).
- `lurek.render.getWidth`: Returns the window width in pixels.
- `lurek.render.getHeight`: Returns the window height in pixels.
- `lurek.render.getDimensions`: Returns window width and height.
- `lurek.render.setDefaultFilter`: Sets the default texture filter mode.
- `lurek.render.getDefaultFilter`: Returns the default texture filter mode.
- `lurek.render.getStats`: Returns a table of renderer statistics.
- `lurek.render.saveScreenshot`: Queues a screenshot to be saved after the current frame.
- `lurek.render.captureScreenshot`: Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
- `lurek.render.newNineSlice`: Creates a 9-slice descriptor from a texture and inset values.
- `lurek.render.drawNineSlice`: Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
- `lurek.render.newShape`: Creates a new empty [`CompoundShape`] stored in the resource pool.
- `lurek.render.newDrawLayer`: Creates a new z-ordered draw-call queue.

### `Canvas` Methods
- `Canvas:getWidth`: Returns the width of this canvas in pixels.
- `Canvas:getHeight`: Returns the height of this canvas in pixels.
- `Canvas:getDimensions`: Returns width and height of this canvas.
- `Canvas:release`: Releases GPU framebuffer memory for this canvas.
- `Canvas:typeOf`: Returns the type name of this object.
- `Canvas:type`: Returns the type name of this object.

### `DrawLayer` Methods
- `DrawLayer:queue`: Queues a draw callback at the given z-order.
- `DrawLayer:flush`: Sorts and calls all queued callbacks, then empties the queue.
- `DrawLayer:clear`: Removes all queued callbacks without calling them.
- `DrawLayer:getCount`: Returns the number of queued callbacks.
- `DrawLayer:type`: Returns the type name.
- `DrawLayer:typeOf`: Returns true if this object is an instance of the given type name.

### `Font` Methods
- `Font:getWidth`: Returns the rendered width of the given text string.
- `Font:getHeight`: Returns the line height of this font.
- `Font:getLineHeight`: Returns the line height multiplier of this font.
- `Font:setLineHeight`: Sets the line height multiplier for this font.
- `Font:getAscent`: Returns the ascent of this font in pixels.
- `Font:getDescent`: Returns the descent of this font in pixels.
- `Font:getWrap`: Wraps text to the given width and returns the lines.
- `Font:release`: Releases this font and frees its atlas memory.
- `Font:typeOf`: Returns the type name of this object.
- `Font:type`: Returns the type name of this object.

### `Image` Methods
- `Image:getWidth`: Returns the width of this image in pixels.
- `Image:getHeight`: Returns the height of this image in pixels.
- `Image:getDimensions`: Returns width and height of this image.
- `Image:release`: Releases the GPU texture memory for this image.
- `Image:typeOf`: Returns the type name of this object.
- `Image:type`: Returns the type name of this object.

### `ImageData` Methods
- `ImageData:getWidth`: Returns the pixel width of this image buffer.
- `ImageData:getHeight`: Returns the pixel height of this image buffer.
- `ImageData:type`: Returns the type name "ImageData".
- `ImageData:typeOf`: Returns true when the given name matches "ImageData" or a parent type.

### `Mesh` Methods
- `Mesh:getVertexCount`: Returns the number of vertices in this mesh.
- `Mesh:getVertex`: Returns vertex data at the given 1-based index.
- `Mesh:setVertex`: Sets vertex data at the given 1-based index.
- `Mesh:setTexture`: Assigns a texture to this mesh.
- `Mesh:release`: Releases this mesh.
- `Mesh:typeOf`: Returns the type name of this object.
- `Mesh:type`: Returns the type name of this object.

### `NineSlice` Methods
- `NineSlice:getInsets`: Returns the four inset values as (top, right, bottom, left).
- `NineSlice:getTextureSize`: Returns the width and height of the source texture.
- `NineSlice:type`: Returns the type name "NineSlice".
- `NineSlice:typeOf`: Returns true when the given name matches "NineSlice" or a parent type.

### `Quad` Methods
- `Quad:getViewport`: Returns the quad viewport rectangle.
- `Quad:getTextureDimensions`: Returns the reference texture dimensions.
- `Quad:typeOf`: Returns the type name of this object.
- `Quad:type`: Returns the type name of this object.

### `Shader` Methods
- `Shader:send`: Sends a uniform value to this shader.
- `Shader:hasUniform`: Returns whether this shader has a uniform with the given name.
- `Shader:release`: Releases this shader.
- `Shader:typeOf`: Returns the type name of this object.
- `Shader:type`: Returns the type name of this object.

### `Shape` Methods
- `Shape:getCommandCount`: Returns the number of drawing commands currently stored.
- `Shape:clear`: Removes all commands and resets the shape to empty.
- `Shape:setLineWidth`: Sets the stroke width for subsequent outlined primitives.
- `Shape:line`: Queues a line segment command.
- `Shape:polyline`: Queues a polyline command from variadic (x, y) coordinate pairs.
- `Shape:typeOf`: Returns true if the given type name matches this object's type or any parent type.
- `Shape:type`: Returns the type name of this object.

### `SpriteBatch` Methods
- `SpriteBatch:clear`: Removes all sprites from this batch.
- `SpriteBatch:getCount`: Returns the number of sprites in this batch.
- `SpriteBatch:getBufferSize`: Returns the maximum capacity of this batch.
- `SpriteBatch:release`: Releases this sprite batch.
- `SpriteBatch:typeOf`: Returns the type name of this object.
- `SpriteBatch:type`: Returns the type name of this object.

### New Draw Commands (v0.7.26)

The following `lurek.graphic.*` functions queue GPU draw commands added in v0.7.26.
All functions are registered in `src/lua_api/render_api.rs` and processed in `src/render/gpu_renderer.rs`.

#### Bézier Curves

| Function | Description |
|---|---|
| `lurek.graphic.drawQuadBezier(x0,y0, cx,cy, x1,y1, color, lw?)` | Quadratic Bézier curve. `color={r,g,b,a}`, `lw` line width (default 1.0). |
| `lurek.graphic.drawCubicBezier(x0,y0, cx1,cy1, cx2,cy2, x1,y1, color, lw?)` | Cubic Bézier curve with two control points. |

#### Paths

| Function | Description |
|---|---|
| `lurek.graphic.drawPath(verts, color, closed?, lw?)` | Polyline/polygon path. `verts` is a flat array `{x1,y1,x2,y2,...}`. `closed` (bool, default false) connects last point to first. |

#### Filled Geometry

| Function | Description |
|---|---|
| `lurek.graphic.drawGradientRect(x,y,w,h, c_tl,c_tr,c_br,c_bl)` | Rectangle with per-corner colours. Each colour is `{r,g,b,a}`. |
| `lurek.graphic.drawColoredPolygon(verts)` | Polygon where each vertex is `{x,y,r,g,b,a}`. |
| `lurek.graphic.drawIsoCubeTile(x,y, size, top, left, right)` | Isometric cube tile centred at screen position `(x,y)`. Three face colours. |
| `lurek.graphic.drawHexTile(cx,cy, radius, orient, fill, border?, bw?)` | Hex tile. `orient` is `"flat"` or `"pointy"`. Optional border colour and width. |
| `lurek.graphic.drawBevelRect(x,y,w,h, bw?, opts?)` | Bevelled rectangle. `opts` table: `fillColor`, `highlight`, `shadow` — each `{r,g,b,a}`. |

#### Depth Sorting

| Function | Description |
|---|---|
| `lurek.graphic.beginSortGroup(id)` | Opens a sort group. Id is any integer token. |
| `lurek.graphic.pushSortKey(depth)` | Tags the next draw call's Z-depth within the active sort group. |
| `lurek.graphic.flushSortGroup(id)` | Closes and emits the sort group (matched by id). |

#### Compositing Layers

| Function | Description |
|---|---|
| `lurek.graphic.pushLayer(blend?, alpha?)` | Pushes a new compositing layer. `blend` is a blend mode string (e.g. `"add"`). `alpha` (default 1.0). |
| `lurek.graphic.popLayer()` | Pops and composites the current layer. |

#### Support Types (renderer.rs)

- `PathSegment` — `{ x, y, is_move }` — vertex in a draw path.
- `GradientDirection` — `Horizontal | Vertical | TopLeft | TopRight`.
- `HexOrientation` — `FlatTop | PointyTop`.
- `BevelStyle` — `Raised | Sunken | Flat`.
- `PhysicsDebugShape` — per-body snapshot: position, extents, angle, flags, hull verts.
- `PhysicsDebugConfig` — appearance config: per-state colours and line width.
- `SpineSlotDraw` — per-slot Spine rendering data: texture key, UV rect, tint.

## References

- `light`: Imports or references `light` from `src/light/`.
- `math`: Imports or references `math` from `src/math/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.

## Notes

- Keep this module reference synchronized with `src/render/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
