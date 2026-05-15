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

- `Canvas::new` (`canvas.rs`): Create a canvas of `width` × `height` pixels and log its dimensions at debug level.
- `DecalSurface::new` (`decal_surface.rs`): Create a `DecalSurface` sized `width` × `height` pixels.
- `DecalSurface::get_dimensions` (`decal_surface.rs`): Return `(width, height)` as a tuple.
- `DecalSurface::get_width` (`decal_surface.rs`): Return the pixel width.
- `DecalSurface::get_height` (`decal_surface.rs`): Return the pixel height.
- `DrawLayer::new` (`draw_layer.rs`): Create an empty `DrawLayer` with ID counter starting at 0.
- `DrawLayer::queue` (`draw_layer.rs`): Enqueue a callback at `z_order` depth and return its unique callback ID.
- `DrawLayer::flush` (`draw_layer.rs`): Sort entries by `z_order`, drain, and return them; leaves the layer empty.
- `DrawLayer::clear` (`draw_layer.rs`): Discard all pending entries without firing callbacks.
- `DrawLayer::get_count` (`draw_layer.rs`): Return the number of pending entries.
- `Font::from_png_bytes` (`font.rs`): Load and decode `data` as a PNG bitmap font atlas with `cell_w`×`cell_h` cells; return error on decode failure.
- `Font::load_all_sizes` (`font.rs`): Load all six bundled bitmap font sizes; silently skip any that fail to decode.
- `Font::nearest_size` (`font.rs`): Return the index into `AVAILABLE_HEIGHTS` whose cell height is closest to `pixel_height`.
- `Font::glyph` (`font.rs`): Return `GlyphInfo` for `ch`, or `None` if the character is not in the atlas.
- `Font::text_width` (`font.rs`): Return the pixel advance-width sum for all glyphs in `text`.
- `Font::line_height` (`font.rs`): Return `cell_height * line_height_mul` as the vertical line spacing in pixels.
- `Font::set_line_height` (`font.rs`): Set the line-height multiplier applied over `cell_height`.
- `Font::ascent` (`font.rs`): Return `cell_height` as the ascent value in pixels.
- `Font::descent` (`font.rs`): Return 0.0; bitmap fonts have no descender in this implementation.
- `Font::atlas_data` (`font.rs`): Return `(pixel_data, width, height)` for the atlas texture upload.
- `Font::is_dirty` (`font.rs`): Return true when the atlas pixel data has not yet been uploaded to the GPU.
- `Font::mark_clean` (`font.rs`): Clear the dirty flag after a successful GPU texture upload.
- `Font::size` (`font.rs`): Return the pixel height of one character cell.
- `Font::cell_width` (`font.rs`): Return the pixel width of one character cell.
- `Font::has_box_drawing` (`font.rs`): Return true when this font atlas contains Unicode box-drawing glyphs.
- `Font::wrap_text` (`font.rs`): Break `text` into lines that each fit within `limit` pixels, honouring existing newlines.
- `GpuRenderer::new` (`gpu_renderer.rs`): Create a `GpuRenderer` from an already-acquired wgpu device/queue pair and surface format.
- `GpuRenderer::resize` (`gpu_renderer.rs`): Update viewport dimensions after a window resize; recreates stencil targets and clears light GPU state.
- `GpuRenderer::upload_texture` (`gpu_renderer.rs`): Upload RGBA pixel data for `key` to the GPU, replacing any previously uploaded texture.
- `GpuRenderer::create_canvas` (`gpu_renderer.rs`): Create an off-screen render-target canvas texture for `key` at `width`×`height`.
- `GpuRenderer::render_frame` (`gpu_renderer.rs`): Execute all queued `RenderCommand`s for one frame and present the frame.
- `ShaderPassDescriptor::new` (`image_effect.rs`): Create an enabled pass for `effect_name` with an empty parameter map.
- `Mesh::new` (`mesh.rs`): Allocate a mesh of `vertex_count` default-white vertices in the given draw mode.
- `Mesh::from_vertices` (`mesh.rs`): Create a mesh directly from an existing `Vec<MeshVertex>` without index reuse.
- `Mesh::from_vertex_rows` (`mesh.rs`): Build a mesh from a slice of `[x, y, u, v, r, g, b, a]` row arrays.
- `Mesh::set_vertex` (`mesh.rs`): Set the vertex at `index`; silently ignored when `index` is out of bounds.
- `Mesh::get_vertex` (`mesh.rs`): Return a reference to the vertex at `index`, or `None` when out of bounds.
- `Mesh::set_vertex_map` (`mesh.rs`): Replace the index buffer with `indices`.
- `Mesh::vertex_count` (`mesh.rs`): Return the number of vertices in this mesh.
- `Mesh::set_texture` (`mesh.rs`): Bind or unbind a texture for subsequent draw calls on this mesh.
- `Mesh::set_draw_mode` (`mesh.rs`): Change the triangle topology for this mesh.
- `Mesh::triangulate` (`mesh.rs`): Return a flat list of vertex indices expanding Fan/Strip and indexed modes into independent triangles.
- `Vec3::new` (`obj_loader.rs`): Construct from components.
- `Vec3::dot` (`obj_loader.rs`): Return the scalar dot product of `self` and `other`.
- `Vec3::len` (`obj_loader.rs`): Return the Euclidean length of this vector.
- `Vec3::normalise` (`obj_loader.rs`): Return a unit vector; returns zero vector when length < 1e-9.
- `Vec3::sub` (`obj_loader.rs`): Return `self - o`.
- `Vec3::cross` (`obj_loader.rs`): Return the cross product `self × o`.
- `Vec3::add` (`obj_loader.rs`): Return `self + o`.
- `Vec3::mul` (`obj_loader.rs`): Return `self * s` (scalar multiply).
- `ObjModel::face_count` (`obj_loader.rs`): Return the number of triangles in this model.
- `ObjModel::vertex_count` (`obj_loader.rs`): Return the number of vertex positions in this model.
- `ObjModel::uv_count` (`obj_loader.rs`): Return the number of UV entries in this model.
- `ObjModel::normal_count` (`obj_loader.rs`): Return the number of normal entries in this model.
- `ObjModel::render_to_image` (`obj_loader.rs`): CPU-rasterize the model into an `ImageData` with a virtual camera, Y-rotation, and a key light.
- `ObjModel::project_to_mesh` (`obj_loader.rs`): Project the model from `cam_pos`/`cam_target` into a `Mesh` sorted back-to-front.
- `ObjModel::project_instance_to_mesh` (`obj_loader.rs`): Project a single world-space instance with Y-rotation and uniform scale; return `(Mesh, depth)`.
- `ObjLoader::load_file` (`obj_loader.rs`): Load and triangulate an OBJ file from `path`, using `tobj`; return error on I/O or parse failure.
- `ObjLoader::parse_obj` (`obj_loader.rs`): Parse OBJ + MTL text in memory, resolving `mtllib` paths relative to `base_dir`.
- `ObjCamera::new` (`obj_loader.rs`): Construct a camera from position, target, and FOV.
- `ObjCamera::to_vecs` (`obj_loader.rs`): Return `(cam_pos, cam_target, fov_y_rad)` unpacked as `Vec3` values.
- `params_to_uniform` (`postfx_pipeline.rs`): Maps a `PostFxEffect` parameter dictionary to the 16-float packed buffer consumed by every WGSL shader's `PostFxParams` uniform.
- `PostFxTexture::new` (`postfx_pipeline.rs`): Allocate a new `PostFxTexture` of `width`x`height` in `format` on `device`.
- `PostFxPipeline::new` (`postfx_pipeline.rs`): Build all built-in effect pipelines and shared GPU resources for `surface_format`.
- `PostFxPipeline::register_custom` (`postfx_pipeline.rs`): Compile and register a custom WGSL fragment shader under `name` for use in `PostFxPass`.
- `PostFxPipeline::apply` (`postfx_pipeline.rs`): Execute all enabled `passes` in sequence using ping-pong textures; write final result to `target_view`.
- `TextSpan::new` (`renderer.rs`): Construct a `TextSpan` from a string-like value and explicit RGBA and scale.
- `Shader::new` (`shader.rs`): Parse, validate, and prepare `source`; return error string on WGSL validation failure.
- `Shader::send` (`shader.rs`): Set or replace the named uniform value used on subsequent frames.
- `Shader::has_uniform` (`shader.rs`): Return `true` when a uniform with `name` has been set.
- `Shader::ordered_uniforms` (`shader.rs`): Return all set uniforms sorted alphabetically by name for deterministic GPU upload order.
- `Shader::wrapper_source` (`shader.rs`): Return the rewritten wrapper source for injection into the GPU pipeline.
- `Shader::fragment_entry_name` (`shader.rs`): Return the fragment helper function name within `wrapper_source`.
- `Shader::fragment_inputs` (`shader.rs`): Return the ordered input slots accepted by the fragment entry.
- `CompoundShape::new` (`shape.rs`): Create an empty shape with white color and 1 px line width.
- `CompoundShape::push_command` (`shape.rs`): Append a drawing command to this shape.
- `CompoundShape::clear` (`shape.rs`): Remove all commands and reset color and line-width to defaults.
- `CompoundShape::command_count` (`shape.rs`): Return the number of commands in this shape.

## Lua API Reference

- Binding path(s): `src/lua_api/render_api.rs`
- Namespace: `lurek.render`

### Module Functions
- `lurek.render.setColor`: Sets the active drawing color for all subsequent draw operations.
- `lurek.render.getColor`: Returns the current drawing color.
- `lurek.render.setBackgroundColor`: Sets the background clear color used at the start of each frame.
- `lurek.render.getBackgroundColor`: Returns the current background clear color.
- `lurek.render.rectangle`: Draws a rectangle. If rx is provided, draws a rounded rectangle.
- `lurek.render.circle`: Draws a circle.
- `lurek.render.ellipse`: Draws an ellipse.
- `lurek.render.triangle`: Draws a triangle from three vertex positions.
- `lurek.render.line`: Draws a line between two points, or a polyline through multiple points.
- `lurek.render.polygon`: Draws a polygon from a flat list of x,y vertex coordinates.
- `lurek.render.arc`: Draws a circular arc.
- `lurek.render.points`: Draws one or more points. Accepts either a table of {x,y} pairs or flat x,y coordinate values.
- `lurek.render.draw`: Draws a drawable object (Image, Canvas, SpriteBatch, or Mesh) at the given position with optional transform.
- `lurek.render.drawq`: Draws a sub-region of an image defined by a Quad, with optional transform.
- `lurek.render.drawMany`: Batch-draws multiple images in one call. Each entry is a table: {image, x, y, r, sx, sy, ox, oy}.
- `lurek.render.printRotated`: Draws text centered and rotated around its midpoint.
- `lurek.render.print`: Draws text using the active font at the given position.
- `lurek.render.printf`: Draws word-wrapped and aligned text within a pixel-width limit.
- `lurek.render.printRich`: Draws rich text composed of individually styled spans at the given position.
- `lurek.render.clear`: Clears all queued render commands for the current frame.
- `lurek.render.setLineWidth`: Sets the line width for subsequent line-mode draw calls.
- `lurek.render.getLineWidth`: Returns the current line width.
- `lurek.render.setPointSize`: Sets the point size for subsequent point draw calls.
- `lurek.render.getPointSize`: Returns the current point size.
- `lurek.render.setBlendMode`: Sets the blend mode for subsequent draw operations.
- `lurek.render.getBlendMode`: Returns the current blend mode name.
- `lurek.render.newFont`: Creates a new bitmap font from a PNG sprite sheet path or returns a built-in font by pixel height.
- `lurek.render.setFont`: Sets the active font used by print, printf, and other text rendering calls.
- `lurek.render.getFont`: Returns the currently active font, or nil if none is set.
- `lurek.render.getFontSizes`: Returns all available built-in font pixel heights.
- `lurek.render.getDefaultFont`: Returns a built-in default font at the nearest available pixel height.
- `lurek.render.getFontCellWidth`: Returns the fixed cell width of a bitmap font.
- `lurek.render.getFontWidth`: Measures the pixel width of text using the given font.
- `lurek.render.getFontHeight`: Returns the line height of the given font.
- `lurek.render.getFontLineHeight`: Returns the line spacing of the given font.
- `lurek.render.setFontLineHeight`: Sets the line height override for a font (currently a no-op stub).
- `lurek.render.getFontAscent`: Returns the ascent (pixels above baseline) of the given font.
- `lurek.render.getFontDescent`: Returns the descent (pixels below baseline) of the given font.
- `lurek.render.getFontWrap`: Word-wraps text using the active font and returns the resulting lines and widest line width.
- `lurek.render.newImage`: Loads a texture from a file path or creates one from an ImageData object.
- `lurek.render.newCanvas`: Creates a new off-screen render target with the given dimensions.
- `lurek.render.setCanvas`: Redirects all subsequent drawing to the given canvas. Pass nil to draw to the screen again.
- `lurek.render.getCanvas`: Returns the currently active canvas, or nil if drawing to the screen.
- `lurek.render.getCanvasSize`: Returns the pixel dimensions of a canvas.
- `lurek.render.newSpriteBatch`: Creates a batched sprite renderer for efficiently drawing many copies of the same texture.
- `lurek.render.newMesh`: Creates a custom vertex mesh from an array of vertex data tables.
- `lurek.render.newShader`: Compiles a WGSL shader program from source code and returns a handle.
- `lurek.render.setShader`: Activates a shader for subsequent draw calls. Pass nil to restore the default shader.
- `lurek.render.getShader`: Returns the currently active shader, or nil if using the default.
- `lurek.render.newQuad`: Creates a Quad defining a rectangular sub-region of a texture for sprite-sheet rendering.
- `lurek.render.push`: Pushes the current transformation matrix onto the transform stack.
- `lurek.render.pop`: Pops the top transformation matrix from the transform stack, restoring the previous one.
- `lurek.render.translate`: Applies a translation to the current transformation matrix.
- `lurek.render.rotate`: Applies a rotation to the current transformation matrix.
- `lurek.render.scale`: Applies scaling to the current transformation matrix.
- `lurek.render.shear`: Applies a shear (skew) to the current transformation matrix.
- `lurek.render.origin`: Resets the current transformation matrix to the identity (no transform).
- `lurek.render.applyTransform`: Multiplies the current transformation matrix by a 3x3 matrix (9 values in row-major order).
- `lurek.render.setScissor`: Sets or clears the scissor rectangle. Only pixels inside this region are drawn. Call with no args to clear.
- `lurek.render.getScissor`: Returns the current scissor rectangle, or nothing if no scissor is set.
- `lurek.render.intersectScissor`: Intersects the given rectangle with the current scissor, narrowing the drawable region.
- `lurek.render.setColorMask`: Sets which color channels are written during draw calls. Call with no args to enable all.
- `lurek.render.getColorMask`: Returns the current color write mask.
- `lurek.render.setWireframe`: Enables or disables wireframe rendering mode.
- `lurek.render.isWireframe`: Returns whether wireframe rendering is currently active.
- `lurek.render.stencil`: Begins a stencil write pass with the given action and reference value.
- `lurek.render.setStencilTest`: Configures the stencil comparison test for subsequent draws. Pass nil to disable.
- `lurek.render.setStencilMode`: Sets the stencil write action, compare function, and reference value at once.
- `lurek.render.getStencilMode`: Returns the current stencil action, compare mode, and reference value.
- `lurek.render.clearStencil`: Resets the stencil state to defaults (no stencil operations).
- `lurek.render.setDepthMode`: Sets the depth comparison mode and whether depth writes are enabled.
- `lurek.render.getDepthMode`: Returns the current depth comparison mode and write-enable flag.
- `lurek.render.getWidth`: Returns the current window width in pixels.
- `lurek.render.getHeight`: Returns the current window height in pixels.
- `lurek.render.getDimensions`: Returns the current window width and height.
- `lurek.render.setDefaultFilter`: Sets the default texture filtering mode for newly created images.
- `lurek.render.getDefaultFilter`: Returns the current default texture filtering settings.
- `lurek.render.getStats`: Returns a table of rendering statistics for the current frame.
- `lurek.render.saveScreenshot`: Saves a screenshot of the current frame to a file under the save/ directory.
- `lurek.render.captureScreenshot`: Captures a screenshot as ImageData and passes it to a callback (stub: returns 1x1 placeholder).
- `lurek.render.newNineSlice`: Creates a 9-slice definition from an image and four border insets for scalable UI rendering.
- `lurek.render.drawNineSlice`: Draws a 9-slice image stretched to fill the given rectangle, keeping borders unscaled.
- `lurek.render.newShape`: Creates a new retained compound shape for accumulating draw commands.
- `lurek.render.newDrawLayer`: Creates a new z-ordered draw layer for sorting draw callbacks by depth.
- `lurek.render.drawQuadBezier`: Draws a quadratic Bezier curve through start, control, and end points.
- `lurek.render.drawCubicBezier`: Draws a cubic Bezier curve through start, two control points, and end.
- `lurek.render.drawPath`: Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments.
- `lurek.render.drawGradientRect`: Draws a rectangle with a two-color gradient fill.
- `lurek.render.drawColoredPolygon`: Draws a polygon with per-vertex colors.
- `lurek.render.drawIsoCubeTile`: Draws an isometric cube tile with configurable face colors and optional textures.
- `lurek.render.drawHexTile`: Draws a regular hexagonal tile.
- `lurek.render.beginSortGroup`: Begins a depth-sorted rendering group. Draw calls within this group are sorted by pushSortKey values.
- `lurek.render.pushSortKey`: Sets the depth sort key for subsequent draw calls within the current sort group.
- `lurek.render.flushSortGroup`: Ends a sort group and emits all accumulated draw calls in sorted order.
- `lurek.render.drawBevelRect`: Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements.
- `lurek.render.pushLayer`: Begins a compositing layer with the given alpha and blend mode. Must be paired with popLayer.
- `lurek.render.popLayer`: Ends a compositing layer and composites it with the previous content.
- `lurek.render.drawQuadBezier`: Draws a quadratic Bezier curve through start, control, and end points.
- `lurek.render.drawCubicBezier`: Draws a cubic Bezier curve through start, two control points, and end.
- `lurek.render.drawPath`: Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments.
- `lurek.render.drawGradientRect`: Draws a rectangle with a two-color gradient fill.
- `lurek.render.drawColoredPolygon`: Draws a polygon with per-vertex colors.
- `lurek.render.drawIsoCubeTile`: Draws an isometric cube tile with configurable face colors and optional textures.
- `lurek.render.drawHexTile`: Draws a regular hexagonal tile.
- `lurek.render.beginSortGroup`: Begins a depth-sorted rendering group. Draw calls within this group are sorted by pushSortKey values.
- `lurek.render.pushSortKey`: Sets the depth sort key for subsequent draw calls within the current sort group.
- `lurek.render.flushSortGroup`: Ends a sort group and emits all accumulated draw calls in sorted order.
- `lurek.render.drawBevelRect`: Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements.
- `lurek.render.pushLayer`: Begins a compositing layer with the given alpha and blend mode. Must be paired with popLayer.
- `lurek.render.popLayer`: Ends a compositing layer and composites it with the previous content.
- `lurek.render.newLayer`: Creates a named rendering layer with an optional z-order for draw call organization.
- `lurek.render.setLayer`: Sets the active rendering layer by name. Creates the layer if it does not exist.
- `lurek.render.currentLayer`: Returns the name of the currently active rendering layer.
- `lurek.render.setLayerVisible`: Sets whether a named rendering layer is visible.
- `lurek.render.isLayerVisible`: Returns whether a named rendering layer is currently visible.
- `lurek.render.getLayerZOrder`: Returns the z-order value of a named rendering layer.
- `lurek.render.setLayerZOrder`: Sets the z-order value of a named rendering layer.
- `lurek.render.loadObj`: Loads a Wavefront OBJ model file and returns a model handle for projection and rendering.
- `lurek.render.loadModel`: Loads a 3D model file (OBJ format) and returns a handle for 2D projection and sprite rendering.

### `LCanvas` Methods
- `LCanvas:getWidth`: Returns the width of this canvas in pixels.
- `LCanvas:getHeight`: Returns the height of this canvas in pixels.
- `LCanvas:getDimensions`: Returns both width and height of this canvas.
- `LCanvas:release`: Releases the canvas GPU resource. If this canvas is currently active, drawing reverts to the screen.
- `LCanvas:typeOf`: Returns the type name of this object.
- `LCanvas:type`: Returns the internal Lua type tag.

### `LDrawLayer` Methods
- `LDrawLayer:queue`: Enqueues a draw callback at the given z-depth. Callbacks execute when flush() is called.
- `LDrawLayer:flush`: Sorts all queued callbacks by z-depth and executes them in order, then empties the layer.
- `LDrawLayer:clear`: Discards all queued callbacks without executing them.
- `LDrawLayer:getCount`: Returns the number of callbacks currently queued.
- `LDrawLayer:type`: Returns the internal Lua type tag.
- `LDrawLayer:typeOf`: Checks whether this object matches the given type name.

### `LFont` Methods
- `LFont:getWidth`: Measures the pixel width of a string when rendered with this font.
- `LFont:getHeight`: Returns the line height of this font in pixels.
- `LFont:getLineHeight`: Returns the spacing between consecutive lines of text.
- `LFont:setLineHeight`: Overrides the line height used for multi-line text rendering.
- `LFont:getAscent`: Returns the ascent (pixels above the baseline) of this font.
- `LFont:getDescent`: Returns the descent (pixels below the baseline) of this font.
- `LFont:getWrap`: Word-wraps text to fit within a pixel width limit and returns the resulting lines.
- `LFont:release`: Releases the font resource. The handle becomes invalid after this call.
- `LFont:typeOf`: Returns the type name of this object.
- `LFont:type`: Returns the internal Lua type tag.

### `LImage` Methods
- `LImage:getId`: Returns the internal numeric handle ID for this image.
- `LImage:getWidth`: Returns the width of this image in pixels.
- `LImage:getHeight`: Returns the height of this image in pixels.
- `LImage:getDimensions`: Returns both width and height of this image.
- `LImage:release`: Releases the GPU memory for this image. The handle becomes invalid after this call.
- `LImage:typeOf`: Returns the type name of this object.
- `LImage:type`: Returns the internal Lua type tag.

### `LImageData` Methods
- `LImageData:getWidth`: Returns the width of this image data in pixels.
- `LImageData:getHeight`: Returns the height of this image data in pixels.
- `LImageData:resize`: Creates a new ImageData resized to the given dimensions using bilinear sampling.
- `LImageData:blit`: Copies pixel data from another ImageData onto this one at the specified position.
- `LImageData:getRegion`: Extracts a rectangular sub-region as a new ImageData.
- `LImageData:diff`: Computes a numeric difference score between this image and another of the same size.
- `LImageData:mapPixels`: Iterates over every pixel and replaces its color with the return value of the callback.
- `LImageData:type`: Returns the type name of this object.
- `LImageData:typeOf`: Checks whether this object matches the given type name.

### `LMesh` Methods
- `LMesh:getVertexCount`: Returns the number of vertices in this mesh.
- `LMesh:getVertex`: Returns the data for a single vertex by 1-based index.
- `LMesh:setVertex`: Updates a single vertex by 1-based index. Table format: {x, y, u, v, r, g, b, a}.
- `LMesh:setTexture`: Assigns or removes a texture for this mesh. Pass nil to clear the texture.
- `LMesh:release`: Releases the mesh resource.
- `LMesh:typeOf`: Returns the type name of this object.
- `LMesh:type`: Returns the internal Lua type tag.

### `LNineSlice` Methods
- `LNineSlice:getInsets`: Returns the border insets (top, right, bottom, left) that define the stretchable regions.
- `LNineSlice:getTextureSize`: Returns the pixel dimensions of the underlying source texture.
- `LNineSlice:type`: Returns the type name of this object.
- `LNineSlice:typeOf`: Checks whether this object matches the given type name.

### `LObjModel` Methods
- `LObjModel:getVertexCount`: Returns the number of vertices in this OBJ model.
- `LObjModel:getFaceCount`: Returns the number of faces (triangles) in this OBJ model.
- `LObjModel:getUvCount`: Returns the number of UV texture coordinates in this OBJ model.
- `LObjModel:getNormalCount`: Returns the number of vertex normals in this OBJ model.
- `LObjModel:renderToImage`: Renders the OBJ model to a GPU texture at the given resolution with optional 90-degree rotation.
- `LObjModel:projectToMesh`: Projects the OBJ model into 2D vertex data using a virtual camera, returning a table of vertex rows.

### `LQuad` Methods
- `LQuad:getViewport`: Returns the quad's viewport rectangle within the source texture.
- `LQuad:setViewport`: Updates the quad's viewport rectangle.
- `LQuad:getTextureDimensions`: Returns the full dimensions of the source texture this quad references.
- `LQuad:typeOf`: Returns the type name of this object.
- `LQuad:type`: Returns the internal Lua type tag.

### `LShader` Methods
- `LShader:send`: Sends a uniform value to this shader by name. Supported types: number, boolean, or table (vec2/vec3/vec4).
- `LShader:hasUniform`: Checks whether this shader declares a uniform with the given name.
- `LShader:release`: Releases the shader resource. If active, the default shader is restored.
- `LShader:typeOf`: Returns the type name of this object.
- `LShader:type`: Returns the internal Lua type tag.

### `LShape` Methods
- `LShape:getCommandCount`: Returns the number of drawing commands accumulated in this shape.
- `LShape:clear`: Removes all drawing commands from this shape, making it empty.
- `LShape:setColor`: Sets the drawing color for subsequent shape commands.
- `LShape:setLineWidth`: Sets the line width for subsequent line-mode shape commands.
- `LShape:rectangle`: Adds a rectangle command to the shape.
- `LShape:roundedRectangle`: Adds a rounded rectangle command to the shape.
- `LShape:circle`: Adds a circle command to the shape.
- `LShape:ellipse`: Adds an ellipse command to the shape.
- `LShape:triangle`: Adds a triangle command to the shape.
- `LShape:polygon`: Adds a polygon command to the shape from a flat list of x,y coordinate pairs.
- `LShape:line`: Adds a line segment command to the shape.
- `LShape:polyline`: Adds a connected polyline command to the shape from a flat list of x,y coordinate pairs.
- `LShape:arc`: Adds an arc command to the shape.
- `LShape:draw`: Renders the accumulated shape commands to the screen with optional transform.
- `LShape:typeOf`: Checks whether this object matches the given type name.
- `LShape:type`: Returns the internal Lua type tag.

### `LSpriteBatch` Methods
- `LSpriteBatch:add`: Adds a sprite entry to the batch at the given position with optional transform.
- `LSpriteBatch:clear`: Removes all entries from the sprite batch.
- `LSpriteBatch:getCount`: Returns the number of sprite entries currently in the batch.
- `LSpriteBatch:getBufferSize`: Returns the maximum number of entries this batch can hold.
- `LSpriteBatch:release`: Releases the sprite batch resource.
- `LSpriteBatch:typeOf`: Returns the type name of this object.
- `LSpriteBatch:type`: Returns the internal Lua type tag.

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
