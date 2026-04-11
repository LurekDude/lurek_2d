# `render` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.graphic` |
| **Source** | `src/render/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The render module owns the engine's core 2D rendering pipeline. It exists so Lua and higher-level systems can describe draw intent through `RenderCommand` values while the engine keeps control of batching, resource uploads, pipeline state, canvas targets, and final frame execution.

Its boundary is the command queue and backend needed to consume it: canvases, fonts, shaders, meshes, vector shapes, draw layers, decals, and lightweight effect descriptors live here because they are part of the renderer's own object model. It does not own sprite-domain data now housed under `src/sprite/`, and it does not own separate feature systems that consume rendering such as scene flow or gameplay animation.

**Scope boundary**: This module currently depends on `light`, `math`, `runtime`, `sprite`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.graphic.* (Lua API — src/lua_api/render_api.rs)
    |
    v
src/render/mod.rs
    |- canvas.rs - canvas
    |- decal_surface.rs - decal_surface
    |- draw_layer.rs - draw_layer
    |- font.rs - font
    |- gpu_renderer.rs - gpu_renderer
    |- image_effect.rs - image_effect
    |- mesh.rs - mesh
    |- renderer.rs - renderer
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `canvas.rs` | Logical off-screen render-target descriptor used by the backend and Lua canvas APIs. |
| `decal_surface.rs` | Persistent descriptor for decal stamping targets. |
| `draw_layer.rs` | Ordered callback queue for grouped draw-order management. |
| `font.rs` | Bitmap font loading, atlas storage, glyph lookup, and text-measurement helpers. |
| `gpu_renderer.rs` | Concrete wgpu renderer for device setup, resource pools, pipeline caching, and frame execution. |
| `image_effect.rs` | Lightweight per-image shader-pass descriptor used by render commands. |
| `mesh.rs` | Custom geometry data structures and mesh draw-mode support. |
| `mod.rs` | Module root and public re-export surface for the active render submodules. |
| `renderer.rs` | Render-command enum plus blend, stencil, depth, text, and texture-side data types. |
| `shader.rs` | Custom WGSL shader objects, validation, and typed uniform values. |
| `shape.rs` | Compound vector-shape builder and the primitive command list it records. |

---

## Submodules

### `render::canvas`

Logical off-screen render-target descriptor used by the backend and Lua canvas APIs.

- **`Canvas`** (struct): An off-screen render target with a fixed pixel resolution.

### `render::decal_surface`

Persistent descriptor for decal stamping targets.

- **`DecalSurface`** (struct): Persistent render target for stamping decals.

### `render::draw_layer`

Ordered callback queue for grouped draw-order management.

- **`LayerEntry`** (struct): A queued draw entry with its z-order.
- **`DrawLayer`** (struct): Z-ordered draw callback queue.

### `render::font`

Bitmap font loading, atlas storage, glyph lookup, and text-measurement helpers.

- **`Font`** (struct): A bitmap font loaded from an embedded PNG sprite sheet.
- **`GlyphInfo`** (struct): Information about a single glyph in the atlas.

### `render::gpu_renderer`

Concrete wgpu renderer for device setup, resource pools, pipeline caching, and frame execution.

- **`RenderStats`** (struct): Per-frame rendering statistics.
- **`GpuRenderer`** (struct): GPU-accelerated renderer that processes `RenderCommand` queues via wgpu.

### `render::image_effect`

Lightweight per-image shader-pass descriptor used by render commands.

- **`ShaderPassDescriptor`** (struct): One shader pass in a per-image effect chain.

### `render::mesh`

Custom geometry data structures and mesh draw-mode support.

- **`MeshDrawMode`** (enum): Drawing mode for mesh geometry.
- **`MeshVertex`** (struct): A single vertex in a mesh.
- **`Mesh`** (struct): Custom geometry mesh with per-vertex position, UV, and color data.

### `render::renderer`

Render-command enum plus blend, stencil, depth, text, and texture-side data types.

- **`CompareMode`** (enum): Stencil comparison mode for `lurek.gfx.setStencilTest`.
- **`StencilAction`** (enum): Stencil write action for `lurek.gfx.stencil` and `lurek.gfx.setStencilMode`.
- **`StencilMode`** (struct): Combined stencil rendering mode stored in `SharedState`.
- **`DepthMode`** (enum): Depth test comparison mode for `lurek.gfx.setDepthMode`.
- **`TextAlign`** (enum): Text alignment mode for formatted text printing.
- **`DrawMode`** (enum): Whether a shape is drawn filled or as an outline.
- **`BlendMode`** (enum): Blending mode for draw operations.
- **`RenderCommand`** (enum): A single deferred draw operation queued during `lurek.draw()` and executed by `GpuRenderer`.
- **`TextureData`** (struct): Raw RGBA pixel data for a loaded texture, stored in the renderer's texture atlas.
- **`ParticleRenderShape`** (enum): Geometric shape used when rendering a single untextured particle via `DrawParticleSystem`.

### `render::shader`

Custom WGSL shader objects, validation, and typed uniform values.

- **`ShaderFragmentInput`** (enum): Which fragment shader input the user's entry point expects.
- **`Shader`** (struct): Represents a compiled custom shader with its uniform values.
- **`UniformValue`** (enum): A uniform value that can be sent to a shader from Lua.

### `render::shape`

Compound vector-shape builder and the primitive command list it records.

- **`ShapeCommand`** (enum): A single drawing command stored inside a [`CompoundShape`] command queue.
- **`CompoundShape`** (struct): A compound shape that accumulates draw primitives in local (object-space) coordinates and replays them as a unified entity via [`crate::render::RenderCommand::DrawShape`].

---

## Key Types

### Public Types

#### `RenderCommand`

Central deferred draw-operation enum consumed by the backend.

#### `GpuRenderer`

wgpu-backed renderer that owns the actual frame, pipeline, and GPU resource logic.

#### `Canvas`

Off-screen target descriptor for drawing into textures instead of the swapchain.

#### `Font`

Render-side text resource with atlas and measurement behavior.

#### `TextureData`

CPU-side pixel container handed off for GPU texture upload.

#### `BlendMode`

Public blend-policy enum used by queued draw operations.

#### `DrawMode`

Fill-versus-line enum used by vector primitives.

#### `StencilMode`, `StencilAction`, `CompareMode`, `DepthMode`

Core depth and stencil state vocabulary for queued rendering.

#### `Shader` and `UniformValue`

Custom shader object plus the typed values scripts can send into it.

#### `Mesh` and `MeshVertex`

Custom geometry types for explicit vertex-driven rendering.

#### `CompoundShape` and `ShapeCommand`

Recorded vector-shape commands replayed later through render commands.

#### `DrawLayer`

Ordered callback container for higher-level draw sequencing.

#### `DecalSurface`

Render-owned descriptor for decal workflows.

#### `ShaderPassDescriptor`

Lightweight effect-pass description attached to image draws.

---

## Lua API

Exposed under `lurek.graphic.*` by `src/lua_api/render_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.render.setColor` | Sets the current drawing color. |
| `lurek.render.getColor` | Returns the current drawing color. |
| `lurek.render.setBackgroundColor` | Sets the background clear color. |
| `lurek.render.getBackgroundColor` | Returns the current background color. |
| `lurek.render.rectangle` | Draws a rectangle. |
| `lurek.render.circle` | Draws a circle. |
| `lurek.render.ellipse` | Draws an ellipse. |
| `lurek.render.triangle` | Draws a triangle. |
| `lurek.render.line` | Draws a line between two points. |
| `lurek.render.polygon` | Draws a polygon from a list of vertices. |
| `lurek.render.arc` | Draws a partial circle arc at the given position with specified radius and angle range. |
| `lurek.render.points` | Draws a list of points. |
| `lurek.render.draw` | Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position. |
| `lurek.render.drawq` | Draws a portion of an image defined by a Quad. |
| `lurek.render.print` | Draws text at the given position. |
| `lurek.render.printf` | Draws word-wrapped text within a given width. |
| `lurek.render.clear` | Clears the draw command queue (resets the screen). |
| `lurek.render.setLineWidth` | Sets the line width for outline drawing. |
| `lurek.render.getLineWidth` | Returns the current line width. |
| `lurek.render.setPointSize` | Sets the point diameter in pixels. |
| `lurek.render.getPointSize` | Returns the current point size. |
| `lurek.render.setBlendMode` | Sets the blend mode for drawing. |
| `lurek.render.getBlendMode` | Returns the current blend mode as a string. |
| `lurek.render.newFont` | Loads a bitmap font PNG from a file, or selects a built-in size by pixel height. |
| `lurek.render.setFont` | Sets the active font for print calls. |
| `lurek.render.getFont` | Returns the currently active font, or nil. |
| `lurek.render.getFontSizes` | Returns a table of available built-in font pixel heights. |
| `lurek.render.getDefaultFont` | Returns a built-in font by pixel height (snaps to nearest available size). |
| `lurek.render.getFontCellWidth` | Returns the cell width of the given font (for monospaced bitmap fonts). |
| `lurek.render.getFontWidth` | Returns the pixel width of text in the given font. |
| `lurek.render.getFontHeight` | Returns the line height of the given font. |
| `lurek.render.getFontLineHeight` | Returns the line height of the given font (alias for getFontHeight). |
| `lurek.render.setFontLineHeight` | Sets the line height of the given font (stub — returns nil; fonts are immutable in headless mode). |
| `lurek.render.getFontAscent` | Returns the ascent of the given font. |
| `lurek.render.getFontDescent` | Returns the descent of the given font. |
| `lurek.render.getFontWrap` | Returns wrapped lines and the maximum line width. |
| `lurek.render.newImage` | Loads an image from a file path or creates one from ImageData. |
| `lurek.render.newCanvas` | Creates an off-screen render canvas. |
| `lurek.render.setCanvas` | Sets the active render target to a Canvas, or back to the screen. |
| `lurek.render.getCanvas` | Returns the current canvas, or nil if drawing to screen. |
| `lurek.render.getCanvasSize` | Returns the dimensions of a canvas. |
| `lurek.render.newSpriteBatch` | Creates a new sprite batch for the given image. |
| `lurek.render.newMesh` | Creates a custom mesh from vertex data. |
| `lurek.render.newShader` | Compiles a custom WGSL shader and returns its handle. |
| `lurek.render.setShader` | Sets the active shader, or clears it. |
| `lurek.render.getShader` | Returns the active shader, or nil. |
| `lurek.render.newQuad` | Creates a new Quad viewport into a texture. |
| `lurek.render.push` | Pushes the current transform onto the stack. |
| `lurek.render.pop` | Pops the transform from the stack. |
| `lurek.render.translate` | Translates the coordinate system. |
| `lurek.render.rotate` | Rotates the coordinate system. |
| `lurek.render.scale` | Scales the coordinate system. |
| `lurek.render.shear` | Shears the coordinate system. |
| `lurek.render.origin` | Resets the transform to the identity. |
| `lurek.render.applyTransform` | Applies an affine transform matrix. |
| `lurek.render.setScissor` | Restricts drawing to a rectangle, or clears scissor if no args. |
| `lurek.render.getScissor` | Returns the active scissor rectangle, or nothing. |
| `lurek.render.intersectScissor` | Intersects the current scissor with a new rectangle. |
| `lurek.render.setColorMask` | Sets which RGBA channels are written. Reset with no args. |
| `lurek.render.getColorMask` | Returns the current color mask. |
| `lurek.render.setWireframe` | Enables or disables wireframe rendering. |
| `lurek.render.isWireframe` | Returns whether wireframe mode is active. |
| `lurek.render.stencil` | Begins stencil writing with the given action and value. |
| `lurek.render.setStencilTest` | Sets the stencil comparison test, or disables stencil testing. |
| `lurek.render.setStencilMode` | Sets the stencil buffer write/test mode. |
| `lurek.render.getStencilMode` | Returns the current stencil mode as (action, compare, value). |
| `lurek.render.clearStencil` | Resets the stencil mode to the default (keep / always / 0). |
| `lurek.render.setDepthMode` | Sets the depth test comparison and write enable. |
| `lurek.render.getDepthMode` | Returns the current depth mode as (mode, write). |
| `lurek.render.getWidth` | Returns the window width in pixels. |
| `lurek.render.getHeight` | Returns the window height in pixels. |
| `lurek.render.getDimensions` | Returns window width and height. |
| `lurek.render.setDefaultFilter` | Sets the default texture filter mode. |
| `lurek.render.getDefaultFilter` | Returns the default texture filter mode. |
| `lurek.render.getStats` | Returns a table of renderer statistics. |
| `lurek.render.saveScreenshot` | Queues a screenshot to be saved after the current frame. |
| `lurek.render.captureScreenshot` | Calls the given callback with an ImageData captured from the current frame (stub: creates blank). |
| `lurek.render.newNineSlice` | Creates a 9-slice descriptor from a texture and inset values. |
| `lurek.render.drawNineSlice` | Queues a 9-slice draw call inside lurek.render / lurek.render_ui. |
| `lurek.render.newShape` | Creates a new empty [`CompoundShape`] stored in the resource pool. |
| `lurek.render.newDrawLayer` | Creates a new z-ordered draw-call queue. |

### `Canvas` Methods

| Method | Description |
|--------|-------------|
| `canvas:getWidth(...)` | Returns the width of this canvas in pixels. |
| `canvas:getHeight(...)` | Returns the height of this canvas in pixels. |
| `canvas:getDimensions(...)` | Returns width and height of this canvas. |
| `canvas:release(...)` | Releases GPU framebuffer memory for this canvas. |
| `canvas:typeOf(...)` | Returns the type name of this object. |
| `canvas:type(...)` | Returns the type name of this object. |

### `DrawLayer` Methods

| Method | Description |
|--------|-------------|
| `drawlayer:queue(...)` | Queues a draw callback at the given z-order. |
| `drawlayer:flush(...)` | Sorts and calls all queued callbacks, then empties the queue. |
| `drawlayer:clear(...)` | Removes all queued callbacks without calling them. |
| `drawlayer:getCount(...)` | Returns the number of queued callbacks. |
| `drawlayer:type(...)` | Returns the type name. |
| `drawlayer:typeOf(...)` | Returns true if this object is an instance of the given type name. |

### `Font` Methods

| Method | Description |
|--------|-------------|
| `font:getWidth(...)` | Returns the rendered width of the given text string. |
| `font:getHeight(...)` | Returns the line height of this font. |
| `font:getLineHeight(...)` | Returns the line height multiplier of this font. |
| `font:setLineHeight(...)` | Sets the line height multiplier for this font. |
| `font:getAscent(...)` | Returns the ascent of this font in pixels. |
| `font:getDescent(...)` | Returns the descent of this font in pixels. |
| `font:getWrap(...)` | Wraps text to the given width and returns the lines. |
| `font:release(...)` | Releases this font and frees its atlas memory. |
| `font:typeOf(...)` | Returns the type name of this object. |
| `font:type(...)` | Returns the type name of this object. |

### `Image` Methods

| Method | Description |
|--------|-------------|
| `image:getWidth(...)` | Returns the width of this image in pixels. |
| `image:getHeight(...)` | Returns the height of this image in pixels. |
| `image:getDimensions(...)` | Returns width and height of this image. |
| `image:release(...)` | Releases the GPU texture memory for this image. |
| `image:typeOf(...)` | Returns the type name of this object. |
| `image:type(...)` | Returns the type name of this object. |

### `ImageData` Methods

| Method | Description |
|--------|-------------|
| `imagedata:getWidth(...)` | Returns the pixel width of this image buffer. |
| `imagedata:getHeight(...)` | Returns the pixel height of this image buffer. |
| `imagedata:type(...)` | Returns the type name "ImageData". |
| `imagedata:typeOf(...)` | Returns true when the given name matches "ImageData" or a parent type. |

### `Mesh` Methods

| Method | Description |
|--------|-------------|
| `mesh:getVertexCount(...)` | Returns the number of vertices in this mesh. |
| `mesh:getVertex(...)` | Returns vertex data at the given 1-based index. |
| `mesh:setVertex(...)` | Sets vertex data at the given 1-based index. |
| `mesh:setTexture(...)` | Assigns a texture to this mesh. |
| `mesh:release(...)` | Releases this mesh. |
| `mesh:typeOf(...)` | Returns the type name of this object. |
| `mesh:type(...)` | Returns the type name of this object. |

### `NineSlice` Methods

| Method | Description |
|--------|-------------|
| `nineslice:getInsets(...)` | Returns the four inset values as (top, right, bottom, left). |
| `nineslice:getTextureSize(...)` | Returns the width and height of the source texture. |
| `nineslice:type(...)` | Returns the type name "NineSlice". |
| `nineslice:typeOf(...)` | Returns true when the given name matches "NineSlice" or a parent type. |

### `Quad` Methods

| Method | Description |
|--------|-------------|
| `quad:getViewport(...)` | Returns the quad viewport rectangle. |
| `quad:getTextureDimensions(...)` | Returns the reference texture dimensions. |
| `quad:typeOf(...)` | Returns the type name of this object. |
| `quad:type(...)` | Returns the type name of this object. |

### `Shader` Methods

| Method | Description |
|--------|-------------|
| `shader:send(...)` | Sends a uniform value to this shader. |
| `shader:hasUniform(...)` | Returns whether this shader has a uniform with the given name. |
| `shader:release(...)` | Releases this shader. |
| `shader:typeOf(...)` | Returns the type name of this object. |
| `shader:type(...)` | Returns the type name of this object. |

### `Shape` Methods

| Method | Description |
|--------|-------------|
| `shape:getCommandCount(...)` | Returns the number of drawing commands currently stored. |
| `shape:clear(...)` | Removes all commands and resets the shape to empty. |
| `shape:setLineWidth(...)` | Sets the stroke width for subsequent outlined primitives. |
| `shape:line(...)` | Queues a line segment command. |
| `shape:polyline(...)` | Queues a polyline command from variadic (x, y) coordinate pairs. |
| `shape:typeOf(...)` | Returns true if the given type name matches this object's type or any parent type. |
| `shape:type(...)` | Returns the type name of this object. |

### `SpriteBatch` Methods

| Method | Description |
|--------|-------------|
| `spritebatch:clear(...)` | Removes all sprites from this batch. |
| `spritebatch:getCount(...)` | Returns the number of sprites in this batch. |
| `spritebatch:getBufferSize(...)` | Returns the maximum capacity of this batch. |
| `spritebatch:release(...)` | Releases this sprite batch. |
| `spritebatch:typeOf(...)` | Returns the type name of this object. |
| `spritebatch:type(...)` | Returns the type name of this object. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.graphic.
if lurek.graphic then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 16 |
| `enum` | 13 |
| `fn` (Lua API) | 146 |
| **Total** | **175** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `light` | Imports or references `light` from `src/light/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Platform Services to Foundations. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |
| `sprite` | Imports or references `sprite` from `src/sprite/`. | Cross-group dependency from Platform Services to Feature Systems. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/render/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
