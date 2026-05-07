# render

## General Info

- Module group: `Platform Services`
- Source path: `src/render/`
- Lua API path(s): `src/lua_api/render_api.rs`
- Primary Lua namespace: `lurek.render`
- Rust test path(s): src/render/ (inline #[cfg(test)] in canvas, decal_surface, draw_layer, font, image_effect, mesh, shader, shape), src/render/renderer_tests.rs, src/render/postfx_pipeline_tests.rs
- Lua test path(s): none found in the workspace

## Summary

The `render` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `light`, `math`, `runtime`, `sprite`. Its responsibility should stay inside the Platform Services group rather than absorb behavior owned by those neighbors.

## Files

- `canvas.rs`: Logical off-screen render-target descriptor used by the backend and Lua canvas APIs.
- `decal_surface.rs`: Persistent descriptor for decal stamping targets.
- `draw_layer.rs`: Ordered callback queue for grouped draw-order management.
- `font.rs`: Bitmap font loading, atlas storage, glyph lookup, and text-measurement helpers.
- `gpu_renderer.rs`: Concrete wgpu renderer for device setup, resource pools, pipeline caching, and frame execution.
- `image_effect.rs`: Lightweight per-image shader-pass descriptor used by render commands.
- `mesh.rs`: Custom geometry data structures and mesh draw-mode support.
- `mod.rs`: Module root and public re-export surface for the active render submodules.
- `obj_loader.rs`: Wavefront OBJ loader for Lurek2D.
- `postfx_pipeline.rs`: GPU post-processing pipeline for Lurek2D.
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
- `ObjError` (`enum`, `obj_loader.rs`): Error variants from OBJ parsing.
- `Vec3` (`struct`, `obj_loader.rs`): A 3-D position.
- `Vec2` (`struct`, `obj_loader.rs`): A 2-D UV coordinate.
- `ObjFace` (`struct`, `obj_loader.rs`): A single triangle face.
- `ObjMaterial` (`struct`, `obj_loader.rs`): A material parsed from an `.mtl` file.
- `ObjModel` (`struct`, `obj_loader.rs`): The complete, triangulated OBJ model.
- `ObjLoader` (`struct`, `obj_loader.rs`): Wavefront OBJ loader.
- `ObjCamera` (`struct`, `obj_loader.rs`): Simple camera parameters for `project_to_mesh`.
- `PostFxTexture` (`struct`, `postfx_pipeline.rs`): Stores a wgpu texture and its default view together for convenience.
- `PostFxPipeline` (`struct`, `postfx_pipeline.rs`): GPU post-processing pipeline.
- `CompareMode` (`enum`, `renderer.rs`): Stencil comparison mode for `lurek.render.setStencilTest`.
- `StencilAction` (`enum`, `renderer.rs`): Stencil write action for `lurek.render.stencil` and `lurek.render.setStencilMode`.
- `StencilMode` (`struct`, `renderer.rs`): Combined stencil rendering mode stored in `SharedState`.
- `DepthMode` (`enum`, `renderer.rs`): Depth test comparison mode for `lurek.render.setDepthMode`.
- `TextAlign` (`enum`, `renderer.rs`): Text alignment mode for formatted text printing.
- `DrawMode` (`enum`, `renderer.rs`): Fill-versus-line enum used by vector primitives.
- `BlendMode` (`enum`, `renderer.rs`): Public blend-policy enum used by queued draw operations.
- `PostFxPass` (`struct`, `renderer.rs`): A single deferred draw operation queued during `lurek.draw()` and executed by `GpuRenderer`.
- `TextSpan` (`struct`, `renderer.rs`): RenderCommand.
- `RenderCommand` (`enum`, `renderer.rs`): Central deferred draw-operation enum consumed by the backend.
- `TextureData` (`struct`, `renderer.rs`): CPU-side pixel container handed off for GPU texture upload.
- `ParticleRenderShape` (`enum`, `renderer.rs`): Geometric shape used when rendering a single untextured particle via `DrawParticleSystem`.
- `ParticleInstance` (`struct`, `renderer.rs`): Per-particle render data for a single frame.
- `DrawableKind` (`enum`, `renderer.rs`): Type discriminator for resources that can be passed to lurek.render.draw.
- `PathSegment` (`enum`, `renderer.rs`): A single segment of a vector path, used with `RenderCommand::DrawPath`.
- `GradientDirection` (`enum`, `renderer.rs`): Direction for a two-stop linear or radial gradient.
- `HexOrientation` (`enum`, `renderer.rs`): Orientation for a hexagonal tile cell.
- `BevelStyle` (`enum`, `renderer.rs`): Visual style for a bevelled rectangle.
- `PhysicsDebugShape` (`struct`, `renderer.rs`): Per-collider geometry snapshot extracted from the physics world for GPU debug rendering.
- `PhysicsDebugConfig` (`struct`, `renderer.rs`): Appearance parameters for `RenderCommand::DrawPhysicsDebug`.
- `SpineSlotDraw` (`struct`, `renderer.rs`): One textured slot from a Spine skeleton for GPU rendering.
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
- `GpuRenderer::render_frame` (`gpu_renderer.rs`): Executes one complete GPU render pass, processing the full `RenderCommand` queue into the wgpu surface.
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
- `Vec3::new` (`obj_loader.rs`): Auto-doc: public item.
- `Vec3::dot` (`obj_loader.rs`): Dot product.
- `Vec3::len` (`obj_loader.rs`): Length.
- `Vec3::normalise` (`obj_loader.rs`): Normalise (returns zero vector on zero length).
- `Vec3::sub` (`obj_loader.rs`): Auto-doc: public item.
- `Vec3::cross` (`obj_loader.rs`): Auto-doc: public item.
- `Vec3::add` (`obj_loader.rs`): Auto-doc: public item.
- `Vec3::mul` (`obj_loader.rs`): Auto-doc: public item.
- `ObjModel::face_count` (`obj_loader.rs`): Number of triangles.
- `ObjModel::vertex_count` (`obj_loader.rs`): Number of position vertices.
- `ObjModel::uv_count` (`obj_loader.rs`): Number of UV coordinates.
- `ObjModel::normal_count` (`obj_loader.rs`): Number of normal vectors.
- `ObjModel::render_to_image` (`obj_loader.rs`): Software-renders the model into an RGBA image with a CPU z-buffer.
- `ObjModel::project_to_mesh` (`obj_loader.rs`): Software-project the model to a flat 2-D [`Mesh`] for GPU rendering.
- `ObjModel::project_instance_to_mesh` (`obj_loader.rs`): Project a model instance placed on world tile coordinates.
- `ObjLoader::load_file` (`obj_loader.rs`): Parse an OBJ file (and its `.mtl` sidecars) from the filesystem.
- `ObjLoader::parse_obj` (`obj_loader.rs`): Parse OBJ source given as a string (e.g.
- `ObjCamera::new` (`obj_loader.rs`): Auto-doc: public item.
- `ObjCamera::to_vecs` (`obj_loader.rs`): Auto-doc: public item.
- `params_to_uniform` (`postfx_pipeline.rs`): Maps a `PostFxEffect` parameter dictionary to the 16-float packed buffer consumed by every WGSL shader's `PostFxParams` uniform.
- `PostFxTexture::new` (`postfx_pipeline.rs`): Create a new `Rgba8UnormSrgb` render-target texture of the requested size.
- `PostFxPipeline::new` (`postfx_pipeline.rs`): Instantiate the post-FX pipeline for `surface_format`.
- `PostFxPipeline::register_custom` (`postfx_pipeline.rs`): Register a custom WGSL fragment shader under `name`.
- `PostFxPipeline::apply` (`postfx_pipeline.rs`): Execute a sequence of post-FX passes then composite the result onto `target_view`.
- `TextSpan::new` (`renderer.rs`): Creates a new span with the given text, RGBA colour, and scale.
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
- Namespace: `lurek.render`

### Module Functions
- `lurek.render.setColor`: Sets the current drawing color.
- `lurek.render.getColor`: Returns the current drawing color.
- `lurek.render.setBackgroundColor`: Sets the background clear color.
- `lurek.render.getBackgroundColor`: Returns the current background color.
- `lurek.render.rectangle`: Draws a filled or outlined axis-aligned rectangle at the given position.
- `lurek.render.circle`: Draws a filled or outlined circle at the given world-space position.
- `lurek.render.ellipse`: Draws a filled or outlined ellipse with independent x/y radii.
- `lurek.render.triangle`: Draws a filled or outlined triangle connecting three world-space vertices.
- `lurek.render.line`: Draws a line between two points.
- `lurek.render.polygon`: Draws a polygon from a list of vertices.
- `lurek.render.arc`: Draws a partial circle arc at the given position with specified radius and angle range.
- `lurek.render.points`: Draws a batch of individual points at the specified world-space coordinates.
- `lurek.render.draw`: Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
- `lurek.render.drawq`: Draws a portion of an image defined by a Quad.
- `lurek.render.drawMany`: Draws a list of images in a single call. Each entry is a table: {image, x, y} or
- `lurek.render.printRotated`: Draws text at the given position with rotation. Rotates the entire string as a block
- `lurek.render.print`: Draws text at the given position.
- `lurek.render.printf`: Draws word-wrapped text within a given width.
- `lurek.render.printRich`: Draws a sequence of styled text spans at the given position.
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
- `lurek.render.setFontLineHeight`: Sets the line height of the given font (stub - returns nil; fonts are immutable in headless mode).
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
- `lurek.render.drawNineSlice`: Queues a 9-slice draw call inside lurek.draw / lurek.draw_ui.
- `lurek.render.newShape`: Creates a new empty shape resource.
- `lurek.render.newDrawLayer`: Creates a new z-ordered draw-call queue.
- `lurek.render.drawQuadBezier`: Queues a quadratic Bezier curve.
- `lurek.render.drawCubicBezier`: Queues a cubic Bezier curve.
- `lurek.render.drawPath`: Queues a multi-segment vector path.
- `lurek.render.drawGradientRect`: Queues a gradient-filled rectangle.
- `lurek.render.drawColoredPolygon`: Queues a convex polygon with per-vertex colors.
- `lurek.render.drawIsoCubeTile`: Queues a three-face isometric cube tile.
- `lurek.render.drawHexTile`: Queues a hexagonal tile at centre (cx, cy) with given circumradius.
- `lurek.render.beginSortGroup`: Begins a Y/Z depth sort group. Draw commands until flushSortGroup are depth-sortable.
- `lurek.render.pushSortKey`: Associates the previous draw command with a depth value within the active sort group.
- `lurek.render.flushSortGroup`: Sorts and flushes all draw commands in the sort group.
- `lurek.render.drawBevelRect`: Queues a beveled border rectangle with inner fill.
- `lurek.render.pushLayer`: Begins a named compositing layer with optional alpha and blend mode.
- `lurek.render.popLayer`: Ends and composites the named layer back to its parent.
- `lurek.render.drawQuadBezier`: Queues a quadratic Bezier curve.
- `lurek.render.drawCubicBezier`: Queues a cubic Bezier curve.
- `lurek.render.drawPath`: Queues a multi-segment vector path.
- `lurek.render.drawGradientRect`: Queues a gradient-filled rectangle.
- `lurek.render.drawColoredPolygon`: Queues a convex polygon with per-vertex colors.
- `lurek.render.drawIsoCubeTile`: Queues a three-face isometric cube tile.
- `lurek.render.drawHexTile`: Queues a hexagonal tile at centre (cx, cy) with given circumradius.
- `lurek.render.beginSortGroup`: Begins a Y/Z depth sort group.
- `lurek.render.pushSortKey`: Associates the previous draw command with a depth value within the active sort group.
- `lurek.render.flushSortGroup`: Sorts and flushes all draw commands in the sort group.
- `lurek.render.drawBevelRect`: Queues a beveled border rectangle.
- `lurek.render.pushLayer`: Begins a named compositing layer. Provides alpha and blend mode for composite.
- `lurek.render.popLayer`: Ends and composites the named layer.
- `lurek.render.newLayer`: Registers a named render layer.
- `lurek.render.setLayer`: Sets the active named layer.
- `lurek.render.currentLayer`: Returns the name of the currently active named layer.
- `lurek.render.setLayerVisible`: Shows or hides the named layer.
- `lurek.render.isLayerVisible`: Returns whether the named layer is visible.
- `lurek.render.getLayerZOrder`: Returns the z order of the named layer.
- `lurek.render.setLayerZOrder`: Updates the z order of the named layer.
- `lurek.render.loadObj`: Loads a Wavefront OBJ file (relative to game dir) and returns an LObjModel.
- `lurek.render.loadModel`: Lua-facing function documented in the binding source.

### `LCanvas` Methods
- `LCanvas:getWidth`: Returns the width of this canvas in pixels.
- `LCanvas:getHeight`: Returns the height of this canvas in pixels.
- `LCanvas:getDimensions`: Returns width and height of this canvas.
- `LCanvas:release`: Releases GPU framebuffer memory for this canvas.
- `LCanvas:typeOf`: Returns the Lua type name for this canvas object.
- `LCanvas:type`: Returns the Lua type name for this canvas handle.

### `LDrawLayer` Methods
- `LDrawLayer:queue`: Queues a draw callback at the given z-order.
- `LDrawLayer:flush`: Sorts and calls all queued callbacks, then empties the queue.
- `LDrawLayer:clear`: Removes all queued callbacks without calling them.
- `LDrawLayer:getCount`: Returns the number of queued callbacks.
- `LDrawLayer:type`: Returns the string type identifier of this draw layer (for example `LDrawLayer`).
- `LDrawLayer:typeOf`: Returns true if this object is an instance of the given type name.

### `LFont` Methods
- `LFont:getWidth`: Returns the rendered width of the given text string.
- `LFont:getHeight`: Returns the line height of this font.
- `LFont:getLineHeight`: Returns the line height multiplier of this font.
- `LFont:setLineHeight`: Sets the line height multiplier for this font.
- `LFont:getAscent`: Returns the ascent of this font in pixels.
- `LFont:getDescent`: Returns the descent of this font in pixels.
- `LFont:getWrap`: Wraps text to the given width and returns the lines.
- `LFont:release`: Releases this font and frees its atlas memory.
- `LFont:typeOf`: Returns the Lua type name for this font object.
- `LFont:type`: Returns the Lua type name for this font handle.

### `LImage` Methods
- `LImage:getId`: Returns the internal numeric texture handle used by low-level render systems.
- `LImage:getWidth`: Returns the width of this image in pixels.
- `LImage:getHeight`: Returns the height of this image in pixels.
- `LImage:getDimensions`: Returns width and height of this image.
- `LImage:release`: Releases the GPU texture memory for this image.
- `LImage:typeOf`: Returns the Lua type name for this image object.
- `LImage:type`: Returns the Lua type name for this image handle.

### `LImageData` Methods
- `LImageData:getWidth`: Returns the pixel width of this image buffer.
- `LImageData:getHeight`: Returns the pixel height of this image buffer.
- `LImageData:resize`: Returns a resized copy of this image buffer.
- `LImageData:blit`: Blits another image buffer onto this image at the destination position.
- `LImageData:getRegion`: Returns a copy of a rectangular region from this image buffer.
- `LImageData:diff`: Returns the summed per-channel difference between this image and another image.
- `LImageData:mapPixels`: Applies a Lua callback to each pixel in this image buffer.
- `LImageData:type`: Returns the Lua type name for this image data object.
- `LImageData:typeOf`: Returns whether this object matches a requested type name.

### `LLObjModel` Methods
- `LLObjModel:getVertexCount`: Lua-facing function documented in the binding source.
- `LLObjModel:getFaceCount`: Lua-facing function documented in the binding source.
- `LLObjModel:getUvCount`: Lua-facing function documented in the binding source.
- `LLObjModel:getNormalCount`: Lua-facing function documented in the binding source.
- `LLObjModel:renderToImage`: Rasterizes the model into a cached sprite image using material colors from the MTL.
- `LLObjModel:projectToMesh`: Projects the 3-D model to a flat 2-D vertex table.

### `LMesh` Methods
- `LMesh:getVertexCount`: Returns the number of vertices in this mesh.
- `LMesh:getVertex`: Returns vertex data at the given 1-based index.
- `LMesh:setVertex`: Sets vertex data at the given 1-based index.
- `LMesh:setTexture`: Assigns a texture to this mesh.
- `LMesh:release`: Releases the GPU mesh resource, freeing VRAM immediately.
- `LMesh:typeOf`: Returns the Lua type name for this mesh object.
- `LMesh:type`: Returns the Lua type name for this mesh handle.

### `LNineSlice` Methods
- `LNineSlice:getInsets`: Returns the four inset values as (top, right, bottom, left).
- `LNineSlice:getTextureSize`: Returns the width and height of the source texture.
- `LNineSlice:type`: Returns the Lua type name for this object.
- `LNineSlice:typeOf`: Returns whether this object matches a requested type name.

### `LQuad` Methods
- `LQuad:getViewport`: Returns the quad viewport rectangle.
- `LQuad:setViewport`: Sets the quad viewport rectangle.
- `LQuad:getTextureDimensions`: Returns the reference texture dimensions.
- `LQuad:typeOf`: Returns the Lua type name for this quad object.
- `LQuad:type`: Returns the Lua type name for this quad handle.

### `LShader` Methods
- `LShader:send`: Sends a uniform value to this shader.
- `LShader:hasUniform`: Returns whether this shader has a uniform with the given name.
- `LShader:release`: Releases the compiled GPU shader, freeing VRAM and shader slots.
- `LShader:typeOf`: Returns the Lua type name for this shader object.
- `LShader:type`: Returns the Lua type name for this shader handle.

### `LShape` Methods
- `LShape:getCommandCount`: Returns the number of drawing commands currently stored.
- `LShape:clear`: Removes all commands and resets the shape to empty.
- `LShape:setColor`: Sets the drawing color for subsequent primitives.
- `LShape:setLineWidth`: Sets the stroke width for subsequent outlined primitives.
- `LShape:rectangle`: Queues a rectangle command.
- `LShape:roundedRectangle`: Queues a rounded rectangle command.
- `LShape:circle`: Queues a filled or outlined circle draw command onto this shape.
- `LShape:ellipse`: Queues an ellipse command.
- `LShape:triangle`: Queues a triangle command.
- `LShape:polygon`: Queues a polygon command from variadic (x, y) coordinate pairs.
- `LShape:line`: Queues a line segment command.
- `LShape:polyline`: Queues a polyline command from variadic (x, y) coordinate pairs.
- `LShape:arc`: Queues a filled or outlined arc draw command onto this shape.
- `LShape:draw`: Queues this shape for drawing at the given position.
- `LShape:typeOf`: Returns whether this object matches a requested type name.
- `LShape:type`: Returns the Lua type name for this shape handle.

### `LSpriteBatch` Methods
- `LSpriteBatch:add`: Adds a sprite entry to this batch.
- `LSpriteBatch:clear`: Removes all sprites from this batch.
- `LSpriteBatch:getCount`: Returns the number of sprites in this batch.
- `LSpriteBatch:getBufferSize`: Returns the maximum capacity of this batch.
- `LSpriteBatch:release`: Releases this sprite batch.
- `LSpriteBatch:typeOf`: Returns the Lua type name for this sprite batch object.
- `LSpriteBatch:type`: Returns the Lua type name for this sprite batch handle.

## References

- `image`: Imports or references `src/image/`. Dependency stays inside `Platform Services` and should remain acyclic.
- `light`: Imports or references `light` from `src/light/`.
- `math`: Imports or references `math` from `src/math/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.
- `sprite`: Imports or references `sprite` from `src/sprite/`.

## Notes

- Keep this module reference synchronized with `src/render/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- **Viewport culling** (`aabb_visible_2d`) is applied automatically to `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `DrawImage`, and `DrawImageEx` render commands when the draw target is the screen (`RenderTargetId::Screen`). A 4 px margin prevents pop-in at screen edges. Off-screen canvas draws are not culled (correct for render-to-texture workflows).
