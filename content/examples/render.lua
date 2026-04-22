-- content/examples/render.lua
-- Scaffolded coverage of the lurek.render API (183 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/render_api.rs   (Lua binding, arg types, return shape)
--   * src/render/                 (semantics, side effects)
--   * docs/specs/render.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/render.lua

-- ── lurek.render.* functions ──

--@api-stub: lurek.render.setColor
-- Sets the current drawing color.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setColor
  local _todo = "TODO: write a real lurek.render.setColor usage example"
  print(_todo)
end

--@api-stub: lurek.render.getColor
-- Returns the current drawing color.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getColor
  local _todo = "TODO: write a real lurek.render.getColor usage example"
  print(_todo)
end

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setBackgroundColor
  local _todo = "TODO: write a real lurek.render.setBackgroundColor usage example"
  print(_todo)
end

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background color.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getBackgroundColor
  local _todo = "TODO: write a real lurek.render.getBackgroundColor usage example"
  print(_todo)
end

--@api-stub: lurek.render.rectangle
-- Draws a filled or outlined axis-aligned rectangle at the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.rectangle
  local _todo = "TODO: write a real lurek.render.rectangle usage example"
  print(_todo)
end

--@api-stub: lurek.render.circle
-- Draws a filled or outlined circle at the given world-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.circle
  local _todo = "TODO: write a real lurek.render.circle usage example"
  print(_todo)
end

--@api-stub: lurek.render.ellipse
-- Draws a filled or outlined ellipse with independent x/y radii.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.ellipse
  local _todo = "TODO: write a real lurek.render.ellipse usage example"
  print(_todo)
end

--@api-stub: lurek.render.triangle
-- Draws a filled or outlined triangle connecting three world-space vertices.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.triangle
  local _todo = "TODO: write a real lurek.render.triangle usage example"
  print(_todo)
end

--@api-stub: lurek.render.line
-- Draws a line between two points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.line
  local _todo = "TODO: write a real lurek.render.line usage example"
  print(_todo)
end

--@api-stub: lurek.render.polygon
-- Draws a polygon from a list of vertices.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.polygon
  local _todo = "TODO: write a real lurek.render.polygon usage example"
  print(_todo)
end

--@api-stub: lurek.render.arc
-- Draws a partial circle arc at the given position with specified radius and angle range.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.arc
  local _todo = "TODO: write a real lurek.render.arc usage example"
  print(_todo)
end

--@api-stub: lurek.render.points
-- Draws a batch of individual points at the specified world-space coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.points
  local _todo = "TODO: write a real lurek.render.points usage example"
  print(_todo)
end

--@api-stub: lurek.render.draw
-- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.draw
  local _todo = "TODO: write a real lurek.render.draw usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawq
-- Draws a portion of an image defined by a Quad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawq
  local _todo = "TODO: write a real lurek.render.drawq usage example"
  print(_todo)
end

--@api-stub: lurek.render.print
-- Draws text at the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.print
  local _todo = "TODO: write a real lurek.render.print usage example"
  print(_todo)
end

--@api-stub: lurek.render.printf
-- Draws word-wrapped text within a given width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.printf
  local _todo = "TODO: write a real lurek.render.printf usage example"
  print(_todo)
end

--@api-stub: lurek.render.printRich
-- Draws a sequence of individually-styled text spans at `(x, y)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.printRich
  local _todo = "TODO: write a real lurek.render.printRich usage example"
  print(_todo)
end

--@api-stub: lurek.render.clear
-- Clears the draw command queue (resets the screen).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.clear
  local _todo = "TODO: write a real lurek.render.clear usage example"
  print(_todo)
end

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for outline drawing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setLineWidth
  local _todo = "TODO: write a real lurek.render.setLineWidth usage example"
  print(_todo)
end

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getLineWidth
  local _todo = "TODO: write a real lurek.render.getLineWidth usage example"
  print(_todo)
end

--@api-stub: lurek.render.setPointSize
-- Sets the point diameter in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setPointSize
  local _todo = "TODO: write a real lurek.render.setPointSize usage example"
  print(_todo)
end

--@api-stub: lurek.render.getPointSize
-- Returns the current point size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getPointSize
  local _todo = "TODO: write a real lurek.render.getPointSize usage example"
  print(_todo)
end

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for drawing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setBlendMode
  local _todo = "TODO: write a real lurek.render.setBlendMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getBlendMode
  local _todo = "TODO: write a real lurek.render.getBlendMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.newFont
-- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newFont
  local _todo = "TODO: write a real lurek.render.newFont usage example"
  print(_todo)
end

--@api-stub: lurek.render.setFont
-- Sets the active font for print calls.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setFont
  local _todo = "TODO: write a real lurek.render.setFont usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFont
  local _todo = "TODO: write a real lurek.render.getFont usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontSizes
-- Returns a table of available built-in font pixel heights.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontSizes
  local _todo = "TODO: write a real lurek.render.getFontSizes usage example"
  print(_todo)
end

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in font by pixel height (snaps to nearest available size).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getDefaultFont
  local _todo = "TODO: write a real lurek.render.getDefaultFont usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontCellWidth
-- Returns the cell width of the given font (for monospaced bitmap fonts).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontCellWidth
  local _todo = "TODO: write a real lurek.render.getFontCellWidth usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontWidth
-- Returns the pixel width of text in the given font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontWidth
  local _todo = "TODO: write a real lurek.render.getFontWidth usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontHeight
  local _todo = "TODO: write a real lurek.render.getFontHeight usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line height of the given font (alias for getFontHeight).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontLineHeight
  local _todo = "TODO: write a real lurek.render.getFontLineHeight usage example"
  print(_todo)
end

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setFontLineHeight
  local _todo = "TODO: write a real lurek.render.setFontLineHeight usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent of the given font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontAscent
  local _todo = "TODO: write a real lurek.render.getFontAscent usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontDescent
-- Returns the descent of the given font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontDescent
  local _todo = "TODO: write a real lurek.render.getFontDescent usage example"
  print(_todo)
end

--@api-stub: lurek.render.getFontWrap
-- Returns wrapped lines and the maximum line width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getFontWrap
  local _todo = "TODO: write a real lurek.render.getFontWrap usage example"
  print(_todo)
end

--@api-stub: lurek.render.newImage
-- Loads an image from a file path or creates one from ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newImage
  local _todo = "TODO: write a real lurek.render.newImage usage example"
  print(_todo)
end

--@api-stub: lurek.render.newCanvas
-- Creates an off-screen render canvas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newCanvas
  local _todo = "TODO: write a real lurek.render.newCanvas usage example"
  print(_todo)
end

--@api-stub: lurek.render.setCanvas
-- Sets the active render target to a Canvas, or back to the screen.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setCanvas
  local _todo = "TODO: write a real lurek.render.setCanvas usage example"
  print(_todo)
end

--@api-stub: lurek.render.getCanvas
-- Returns the current canvas, or nil if drawing to screen.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getCanvas
  local _todo = "TODO: write a real lurek.render.getCanvas usage example"
  print(_todo)
end

--@api-stub: lurek.render.getCanvasSize
-- Returns the dimensions of a canvas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getCanvasSize
  local _todo = "TODO: write a real lurek.render.getCanvasSize usage example"
  print(_todo)
end

--@api-stub: lurek.render.newSpriteBatch
-- Creates a new sprite batch for the given image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newSpriteBatch
  local _todo = "TODO: write a real lurek.render.newSpriteBatch usage example"
  print(_todo)
end

--@api-stub: lurek.render.newMesh
-- Creates a custom mesh from vertex data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newMesh
  local _todo = "TODO: write a real lurek.render.newMesh usage example"
  print(_todo)
end

--@api-stub: lurek.render.newShader
-- Compiles a custom WGSL shader and returns its handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newShader
  local _todo = "TODO: write a real lurek.render.newShader usage example"
  print(_todo)
end

--@api-stub: lurek.render.setShader
-- Sets the active shader, or clears it.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setShader
  local _todo = "TODO: write a real lurek.render.setShader usage example"
  print(_todo)
end

--@api-stub: lurek.render.getShader
-- Returns the active shader, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getShader
  local _todo = "TODO: write a real lurek.render.getShader usage example"
  print(_todo)
end

--@api-stub: lurek.render.newQuad
-- Creates a new Quad viewport into a texture.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newQuad
  local _todo = "TODO: write a real lurek.render.newQuad usage example"
  print(_todo)
end

--@api-stub: lurek.render.push
-- Pushes the current transform onto the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.push
  local _todo = "TODO: write a real lurek.render.push usage example"
  print(_todo)
end

--@api-stub: lurek.render.pop
-- Pops the transform from the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.pop
  local _todo = "TODO: write a real lurek.render.pop usage example"
  print(_todo)
end

--@api-stub: lurek.render.translate
-- Translates the coordinate system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.translate
  local _todo = "TODO: write a real lurek.render.translate usage example"
  print(_todo)
end

--@api-stub: lurek.render.rotate
-- Rotates the coordinate system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.rotate
  local _todo = "TODO: write a real lurek.render.rotate usage example"
  print(_todo)
end

--@api-stub: lurek.render.scale
-- Scales the coordinate system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.scale
  local _todo = "TODO: write a real lurek.render.scale usage example"
  print(_todo)
end

--@api-stub: lurek.render.shear
-- Shears the coordinate system.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.shear
  local _todo = "TODO: write a real lurek.render.shear usage example"
  print(_todo)
end

--@api-stub: lurek.render.origin
-- Resets the transform to the identity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.origin
  local _todo = "TODO: write a real lurek.render.origin usage example"
  print(_todo)
end

--@api-stub: lurek.render.applyTransform
-- Applies an affine transform matrix.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.applyTransform
  local _todo = "TODO: write a real lurek.render.applyTransform usage example"
  print(_todo)
end

--@api-stub: lurek.render.setScissor
-- Restricts drawing to a rectangle, or clears scissor if no args.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setScissor
  local _todo = "TODO: write a real lurek.render.setScissor usage example"
  print(_todo)
end

--@api-stub: lurek.render.getScissor
-- Returns the active scissor rectangle, or nothing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getScissor
  local _todo = "TODO: write a real lurek.render.getScissor usage example"
  print(_todo)
end

--@api-stub: lurek.render.intersectScissor
-- Intersects the current scissor with a new rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.intersectScissor
  local _todo = "TODO: write a real lurek.render.intersectScissor usage example"
  print(_todo)
end

--@api-stub: lurek.render.setColorMask
-- Sets which RGBA channels are written.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setColorMask
  local _todo = "TODO: write a real lurek.render.setColorMask usage example"
  print(_todo)
end

--@api-stub: lurek.render.getColorMask
-- Returns the current color mask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getColorMask
  local _todo = "TODO: write a real lurek.render.getColorMask usage example"
  print(_todo)
end

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setWireframe
  local _todo = "TODO: write a real lurek.render.setWireframe usage example"
  print(_todo)
end

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe mode is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.isWireframe
  local _todo = "TODO: write a real lurek.render.isWireframe usage example"
  print(_todo)
end

--@api-stub: lurek.render.stencil
-- Begins stencil writing with the given action and value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.stencil
  local _todo = "TODO: write a real lurek.render.stencil usage example"
  print(_todo)
end

--@api-stub: lurek.render.setStencilTest
-- Sets the stencil comparison test, or disables stencil testing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setStencilTest
  local _todo = "TODO: write a real lurek.render.setStencilTest usage example"
  print(_todo)
end

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil buffer write/test mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setStencilMode
  local _todo = "TODO: write a real lurek.render.setStencilMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil mode as (action, compare, value).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getStencilMode
  local _todo = "TODO: write a real lurek.render.getStencilMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.clearStencil
-- Resets the stencil mode to the default (keep / always / 0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.clearStencil
  local _todo = "TODO: write a real lurek.render.clearStencil usage example"
  print(_todo)
end

--@api-stub: lurek.render.setDepthMode
-- Sets the depth test comparison and write enable.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setDepthMode
  local _todo = "TODO: write a real lurek.render.setDepthMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth mode as (mode, write).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getDepthMode
  local _todo = "TODO: write a real lurek.render.getDepthMode usage example"
  print(_todo)
end

--@api-stub: lurek.render.getWidth
-- Returns the window width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getWidth
  local _todo = "TODO: write a real lurek.render.getWidth usage example"
  print(_todo)
end

--@api-stub: lurek.render.getHeight
-- Returns the window height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getHeight
  local _todo = "TODO: write a real lurek.render.getHeight usage example"
  print(_todo)
end

--@api-stub: lurek.render.getDimensions
-- Returns window width and height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getDimensions
  local _todo = "TODO: write a real lurek.render.getDimensions usage example"
  print(_todo)
end

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filter mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setDefaultFilter
  local _todo = "TODO: write a real lurek.render.setDefaultFilter usage example"
  print(_todo)
end

--@api-stub: lurek.render.getDefaultFilter
-- Returns the default texture filter mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getDefaultFilter
  local _todo = "TODO: write a real lurek.render.getDefaultFilter usage example"
  print(_todo)
end

--@api-stub: lurek.render.getStats
-- Returns a table of renderer statistics.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getStats
  local _todo = "TODO: write a real lurek.render.getStats usage example"
  print(_todo)
end

--@api-stub: lurek.render.saveScreenshot
-- Queues a screenshot to be saved after the current frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.saveScreenshot
  local _todo = "TODO: write a real lurek.render.saveScreenshot usage example"
  print(_todo)
end

--@api-stub: lurek.render.captureScreenshot
-- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.captureScreenshot
  local _todo = "TODO: write a real lurek.render.captureScreenshot usage example"
  print(_todo)
end

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice descriptor from a texture and inset values.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newNineSlice
  local _todo = "TODO: write a real lurek.render.newNineSlice usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawNineSlice
-- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawNineSlice
  local _todo = "TODO: write a real lurek.render.drawNineSlice usage example"
  print(_todo)
end

--@api-stub: lurek.render.newShape
-- Creates a new empty [`CompoundShape`] stored in the resource pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newShape
  local _todo = "TODO: write a real lurek.render.newShape usage example"
  print(_todo)
end

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw-call queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newDrawLayer
  local _todo = "TODO: write a real lurek.render.newDrawLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawQuadBezier
-- Queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawQuadBezier
  local _todo = "TODO: write a real lurek.render.drawQuadBezier usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawCubicBezier
  local _todo = "TODO: write a real lurek.render.drawCubicBezier usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawPath
  local _todo = "TODO: write a real lurek.render.drawPath usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawGradientRect
  local _todo = "TODO: write a real lurek.render.drawGradientRect usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawColoredPolygon
  local _todo = "TODO: write a real lurek.render.drawColoredPolygon usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawIsoCubeTile
  local _todo = "TODO: write a real lurek.render.drawIsoCubeTile usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawHexTile
  local _todo = "TODO: write a real lurek.render.drawHexTile usage example"
  print(_todo)
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.beginSortGroup
  local _todo = "TODO: write a real lurek.render.beginSortGroup usage example"
  print(_todo)
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.pushSortKey
  local _todo = "TODO: write a real lurek.render.pushSortKey usage example"
  print(_todo)
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.flushSortGroup
  local _todo = "TODO: write a real lurek.render.flushSortGroup usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle with inner fill.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawBevelRect
  local _todo = "TODO: write a real lurek.render.drawBevelRect usage example"
  print(_todo)
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer with optional alpha and blend mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.pushLayer
  local _todo = "TODO: write a real lurek.render.pushLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer back to its parent.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.popLayer
  local _todo = "TODO: write a real lurek.render.popLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawQuadBezier
-- Must be called inside lurek.render or lurek.render_ui.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawQuadBezier
  local _todo = "TODO: write a real lurek.render.drawQuadBezier usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawCubicBezier
  local _todo = "TODO: write a real lurek.render.drawCubicBezier usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawPath
  local _todo = "TODO: write a real lurek.render.drawPath usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawGradientRect
  local _todo = "TODO: write a real lurek.render.drawGradientRect usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawColoredPolygon
  local _todo = "TODO: write a real lurek.render.drawColoredPolygon usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawIsoCubeTile
  local _todo = "TODO: write a real lurek.render.drawIsoCubeTile usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawHexTile
  local _todo = "TODO: write a real lurek.render.drawHexTile usage example"
  print(_todo)
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group identified by id.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.beginSortGroup
  local _todo = "TODO: write a real lurek.render.beginSortGroup usage example"
  print(_todo)
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.pushSortKey
  local _todo = "TODO: write a real lurek.render.pushSortKey usage example"
  print(_todo)
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.flushSortGroup
  local _todo = "TODO: write a real lurek.render.flushSortGroup usage example"
  print(_todo)
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.drawBevelRect
  local _todo = "TODO: write a real lurek.render.drawBevelRect usage example"
  print(_todo)
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.pushLayer
  local _todo = "TODO: write a real lurek.render.pushLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.popLayer
  local _todo = "TODO: write a real lurek.render.popLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.newLayer
-- Registers a named render layer with an optional z-order (default 0).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.newLayer
  local _todo = "TODO: write a real lurek.render.newLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.setLayer
-- Sets the active named layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setLayer
  local _todo = "TODO: write a real lurek.render.setLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active named layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.currentLayer
  local _todo = "TODO: write a real lurek.render.currentLayer usage example"
  print(_todo)
end

--@api-stub: lurek.render.setLayerVisible
-- Shows or hides the named layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setLayerVisible
  local _todo = "TODO: write a real lurek.render.setLayerVisible usage example"
  print(_todo)
end

--@api-stub: lurek.render.isLayerVisible
-- Returns `true` if the named layer is visible (default: `true`).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.isLayerVisible
  local _todo = "TODO: write a real lurek.render.isLayerVisible usage example"
  print(_todo)
end

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order of the named layer, or `0` if unregistered.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.getLayerZOrder
  local _todo = "TODO: write a real lurek.render.getLayerZOrder usage example"
  print(_todo)
end

--@api-stub: lurek.render.setLayerZOrder
-- Updates the z-order of the named layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: lurek.render.setLayerZOrder
  local _todo = "TODO: write a real lurek.render.setLayerZOrder usage example"
  print(_todo)
end

-- ── ImageData methods ──

--@api-stub: ImageData:getWidth
-- Returns the pixel width of this image buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:getWidth
  local _todo = "TODO: write a real ImageData:getWidth usage example"
  print(_todo)
end

--@api-stub: ImageData:getHeight
-- Returns the pixel height of this image buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:getHeight
  local _todo = "TODO: write a real ImageData:getHeight usage example"
  print(_todo)
end

--@api-stub: ImageData:resize
-- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:resize
  local _todo = "TODO: write a real ImageData:resize usage example"
  print(_todo)
end

--@api-stub: ImageData:diff
-- Returns the sum of absolute per-channel differences between this image and `other`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:diff
  local _todo = "TODO: write a real ImageData:diff usage example"
  print(_todo)
end

--@api-stub: ImageData:mapPixels
-- Applies a Lua function to every pixel in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:mapPixels
  local _todo = "TODO: write a real ImageData:mapPixels usage example"
  print(_todo)
end

--@api-stub: ImageData:type
-- Returns the type name "ImageData".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:type
  local _todo = "TODO: write a real ImageData:type usage example"
  print(_todo)
end

--@api-stub: ImageData:typeOf
-- Returns true when the given name matches "ImageData" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: ImageData:typeOf
  local _todo = "TODO: write a real ImageData:typeOf usage example"
  print(_todo)
end

-- ── NineSlice methods ──

--@api-stub: NineSlice:getInsets
-- Returns the four inset values as (top, right, bottom, left).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: NineSlice:getInsets
  local _todo = "TODO: write a real NineSlice:getInsets usage example"
  print(_todo)
end

--@api-stub: NineSlice:getTextureSize
-- Returns the width and height of the source texture.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: NineSlice:getTextureSize
  local _todo = "TODO: write a real NineSlice:getTextureSize usage example"
  print(_todo)
end

--@api-stub: NineSlice:type
-- Returns the type name "NineSlice".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: NineSlice:type
  local _todo = "TODO: write a real NineSlice:type usage example"
  print(_todo)
end

--@api-stub: NineSlice:typeOf
-- Returns true when the given name matches "NineSlice" or a parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: NineSlice:typeOf
  local _todo = "TODO: write a real NineSlice:typeOf usage example"
  print(_todo)
end

-- ── Image methods ──

--@api-stub: Image:getWidth
-- Returns the width of this image in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:getWidth
  local _todo = "TODO: write a real Image:getWidth usage example"
  print(_todo)
end

--@api-stub: Image:getHeight
-- Returns the height of this image in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:getHeight
  local _todo = "TODO: write a real Image:getHeight usage example"
  print(_todo)
end

--@api-stub: Image:getDimensions
-- Returns width and height of this image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:getDimensions
  local _todo = "TODO: write a real Image:getDimensions usage example"
  print(_todo)
end

--@api-stub: Image:release
-- Releases the GPU texture memory for this image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:release
  local _todo = "TODO: write a real Image:release usage example"
  print(_todo)
end

--@api-stub: Image:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:typeOf
  local _todo = "TODO: write a real Image:typeOf usage example"
  print(_todo)
end

--@api-stub: Image:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Image:type
  local _todo = "TODO: write a real Image:type usage example"
  print(_todo)
end

-- ── Font methods ──

--@api-stub: Font:getWidth
-- Returns the rendered width of the given text string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getWidth
  local _todo = "TODO: write a real Font:getWidth usage example"
  print(_todo)
end

--@api-stub: Font:getHeight
-- Returns the line height of this font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getHeight
  local _todo = "TODO: write a real Font:getHeight usage example"
  print(_todo)
end

--@api-stub: Font:getLineHeight
-- Returns the line height multiplier of this font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getLineHeight
  local _todo = "TODO: write a real Font:getLineHeight usage example"
  print(_todo)
end

--@api-stub: Font:setLineHeight
-- Sets the line height multiplier for this font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:setLineHeight
  local _todo = "TODO: write a real Font:setLineHeight usage example"
  print(_todo)
end

--@api-stub: Font:getAscent
-- Returns the ascent of this font in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getAscent
  local _todo = "TODO: write a real Font:getAscent usage example"
  print(_todo)
end

--@api-stub: Font:getDescent
-- Returns the descent of this font in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getDescent
  local _todo = "TODO: write a real Font:getDescent usage example"
  print(_todo)
end

--@api-stub: Font:getWrap
-- Wraps text to the given width and returns the lines.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:getWrap
  local _todo = "TODO: write a real Font:getWrap usage example"
  print(_todo)
end

--@api-stub: Font:release
-- Releases this font and frees its atlas memory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:release
  local _todo = "TODO: write a real Font:release usage example"
  print(_todo)
end

--@api-stub: Font:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:typeOf
  local _todo = "TODO: write a real Font:typeOf usage example"
  print(_todo)
end

--@api-stub: Font:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Font:type
  local _todo = "TODO: write a real Font:type usage example"
  print(_todo)
end

-- ── Canvas methods ──

--@api-stub: Canvas:getWidth
-- Returns the width of this canvas in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:getWidth
  local _todo = "TODO: write a real Canvas:getWidth usage example"
  print(_todo)
end

--@api-stub: Canvas:getHeight
-- Returns the height of this canvas in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:getHeight
  local _todo = "TODO: write a real Canvas:getHeight usage example"
  print(_todo)
end

--@api-stub: Canvas:getDimensions
-- Returns width and height of this canvas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:getDimensions
  local _todo = "TODO: write a real Canvas:getDimensions usage example"
  print(_todo)
end

--@api-stub: Canvas:release
-- Releases GPU framebuffer memory for this canvas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:release
  local _todo = "TODO: write a real Canvas:release usage example"
  print(_todo)
end

--@api-stub: Canvas:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:typeOf
  local _todo = "TODO: write a real Canvas:typeOf usage example"
  print(_todo)
end

--@api-stub: Canvas:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Canvas:type
  local _todo = "TODO: write a real Canvas:type usage example"
  print(_todo)
end

-- ── SpriteBatch methods ──

--@api-stub: SpriteBatch:clear
-- Removes all sprites from this batch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:clear
  local _todo = "TODO: write a real SpriteBatch:clear usage example"
  print(_todo)
end

--@api-stub: SpriteBatch:getCount
-- Returns the number of sprites in this batch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:getCount
  local _todo = "TODO: write a real SpriteBatch:getCount usage example"
  print(_todo)
end

--@api-stub: SpriteBatch:getBufferSize
-- Returns the maximum capacity of this batch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:getBufferSize
  local _todo = "TODO: write a real SpriteBatch:getBufferSize usage example"
  print(_todo)
end

--@api-stub: SpriteBatch:release
-- Releases this sprite batch.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:release
  local _todo = "TODO: write a real SpriteBatch:release usage example"
  print(_todo)
end

--@api-stub: SpriteBatch:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:typeOf
  local _todo = "TODO: write a real SpriteBatch:typeOf usage example"
  print(_todo)
end

--@api-stub: SpriteBatch:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: SpriteBatch:type
  local _todo = "TODO: write a real SpriteBatch:type usage example"
  print(_todo)
end

-- ── Mesh methods ──

--@api-stub: Mesh:getVertexCount
-- Returns the number of vertices in this mesh.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:getVertexCount
  local _todo = "TODO: write a real Mesh:getVertexCount usage example"
  print(_todo)
end

--@api-stub: Mesh:getVertex
-- Returns vertex data at the given 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:getVertex
  local _todo = "TODO: write a real Mesh:getVertex usage example"
  print(_todo)
end

--@api-stub: Mesh:setVertex
-- Sets vertex data at the given 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:setVertex
  local _todo = "TODO: write a real Mesh:setVertex usage example"
  print(_todo)
end

--@api-stub: Mesh:setTexture
-- Assigns a texture to this mesh.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:setTexture
  local _todo = "TODO: write a real Mesh:setTexture usage example"
  print(_todo)
end

--@api-stub: Mesh:release
-- Releases the GPU mesh resource, freeing VRAM immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:release
  local _todo = "TODO: write a real Mesh:release usage example"
  print(_todo)
end

--@api-stub: Mesh:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:typeOf
  local _todo = "TODO: write a real Mesh:typeOf usage example"
  print(_todo)
end

--@api-stub: Mesh:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Mesh:type
  local _todo = "TODO: write a real Mesh:type usage example"
  print(_todo)
end

-- ── Shader methods ──

--@api-stub: Shader:send
-- Sends a uniform value to this shader.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shader:send
  local _todo = "TODO: write a real Shader:send usage example"
  print(_todo)
end

--@api-stub: Shader:hasUniform
-- Returns whether this shader has a uniform with the given name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shader:hasUniform
  local _todo = "TODO: write a real Shader:hasUniform usage example"
  print(_todo)
end

--@api-stub: Shader:release
-- Releases the compiled GPU shader, freeing VRAM and shader slots.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shader:release
  local _todo = "TODO: write a real Shader:release usage example"
  print(_todo)
end

--@api-stub: Shader:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shader:typeOf
  local _todo = "TODO: write a real Shader:typeOf usage example"
  print(_todo)
end

--@api-stub: Shader:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shader:type
  local _todo = "TODO: write a real Shader:type usage example"
  print(_todo)
end

-- ── Quad methods ──

--@api-stub: Quad:getViewport
-- Returns the quad viewport rectangle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Quad:getViewport
  local _todo = "TODO: write a real Quad:getViewport usage example"
  print(_todo)
end

--@api-stub: Quad:getTextureDimensions
-- Returns the reference texture dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Quad:getTextureDimensions
  local _todo = "TODO: write a real Quad:getTextureDimensions usage example"
  print(_todo)
end

--@api-stub: Quad:typeOf
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Quad:typeOf
  local _todo = "TODO: write a real Quad:typeOf usage example"
  print(_todo)
end

--@api-stub: Quad:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Quad:type
  local _todo = "TODO: write a real Quad:type usage example"
  print(_todo)
end

-- ── Shape methods ──

--@api-stub: Shape:getCommandCount
-- Returns the number of drawing commands currently stored.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:getCommandCount
  local _todo = "TODO: write a real Shape:getCommandCount usage example"
  print(_todo)
end

--@api-stub: Shape:clear
-- Removes all commands and resets the shape to empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:clear
  local _todo = "TODO: write a real Shape:clear usage example"
  print(_todo)
end

--@api-stub: Shape:setLineWidth
-- Sets the stroke width for subsequent outlined primitives.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:setLineWidth
  local _todo = "TODO: write a real Shape:setLineWidth usage example"
  print(_todo)
end

--@api-stub: Shape:line
-- Queues a line segment command.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:line
  local _todo = "TODO: write a real Shape:line usage example"
  print(_todo)
end

--@api-stub: Shape:polyline
-- Queues a polyline command from variadic (x, y) coordinate pairs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:polyline
  local _todo = "TODO: write a real Shape:polyline usage example"
  print(_todo)
end

--@api-stub: Shape:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:typeOf
  local _todo = "TODO: write a real Shape:typeOf usage example"
  print(_todo)
end

--@api-stub: Shape:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: Shape:type
  local _todo = "TODO: write a real Shape:type usage example"
  print(_todo)
end

-- ── DrawLayer methods ──

--@api-stub: DrawLayer:queue
-- Queues a draw callback at the given z-order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:queue
  local _todo = "TODO: write a real DrawLayer:queue usage example"
  print(_todo)
end

--@api-stub: DrawLayer:flush
-- Sorts and calls all queued callbacks, then empties the queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:flush
  local _todo = "TODO: write a real DrawLayer:flush usage example"
  print(_todo)
end

--@api-stub: DrawLayer:clear
-- Removes all queued callbacks without calling them.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:clear
  local _todo = "TODO: write a real DrawLayer:clear usage example"
  print(_todo)
end

--@api-stub: DrawLayer:getCount
-- Returns the number of queued callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:getCount
  local _todo = "TODO: write a real DrawLayer:getCount usage example"
  print(_todo)
end

--@api-stub: DrawLayer:type
-- Returns the string type identifier of this draw layer (e.g.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:type
  local _todo = "TODO: write a real DrawLayer:type usage example"
  print(_todo)
end

--@api-stub: DrawLayer:typeOf
-- Returns true if this object is an instance of the given type name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/render_api.rs and docs/specs/render.md).
do  -- TODO: DrawLayer:typeOf
  local _todo = "TODO: write a real DrawLayer:typeOf usage example"
  print(_todo)
end

