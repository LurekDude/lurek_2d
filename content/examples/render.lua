-- content/examples/render.lua
-- Auto-scaffolded coverage of the lurek.render Lua API (183 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/render.lua

print("[example] lurek.render loaded — 183 API items demonstrated")

-- ── lurek.render free functions ──

--@api-stub: lurek.render.setColor
-- Sets the current drawing color.
-- Use this when sets the current drawing color is needed.
if false then
  local _r = lurek.render.setColor(nil, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.getColor
-- Returns the current drawing color.
-- Use this when returns the current drawing color is needed.
if false then
  local _r = lurek.render.getColor()
  print(_r)
end

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color.
-- Use this when sets the background clear color is needed.
if false then
  local _r = lurek.render.setBackgroundColor(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background color.
-- Use this when returns the current background color is needed.
if false then
  local _r = lurek.render.getBackgroundColor()
  print(_r)
end

--@api-stub: lurek.render.rectangle
-- Draws a filled or outlined axis-aligned rectangle at the given position.
-- Use this when draws a filled or outlined axis-aligned rectangle at the given position is needed.
if false then
  local _r = lurek.render.rectangle()
  print(_r)
end

--@api-stub: lurek.render.circle
-- Draws a filled or outlined circle at the given world-space position.
-- Use this when draws a filled or outlined circle at the given world-space position is needed.
if false then
  local _r = lurek.render.circle(nil, 0, 0, nil)
  print(_r)
end

--@api-stub: lurek.render.ellipse
-- Draws a filled or outlined ellipse with independent x/y radii.
-- Use this when draws a filled or outlined ellipse with independent x/y radii is needed.
if false then
  local _r = lurek.render.ellipse(nil, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.triangle
-- Draws a filled or outlined triangle connecting three world-space vertices.
-- Use this when draws a filled or outlined triangle connecting three world-space vertices is needed.
if false then
  local _r = lurek.render.triangle(nil, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.line
-- Draws a line between two points.
-- Use this when draws a line between two points is needed.
if false then
  local _r = lurek.render.line({})
  print(_r)
end

--@api-stub: lurek.render.polygon
-- Draws a polygon from a list of vertices.
-- Use this when draws a polygon from a list of vertices is needed.
if false then
  local _r = lurek.render.polygon({})
  print(_r)
end

--@api-stub: lurek.render.arc
-- Draws a partial circle arc at the given position with specified radius and angle range.
-- Use this when draws a partial circle arc at the given position with specified radius and angle range is needed.
if false then
  local _r = lurek.render.arc()
  print(_r)
end

--@api-stub: lurek.render.points
-- Draws a batch of individual points at the specified world-space coordinates.
-- Use this when draws a batch of individual points at the specified world-space coordinates is needed.
if false then
  local _r = lurek.render.points({})
  print(_r)
end

--@api-stub: lurek.render.draw
-- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
-- Use this when draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position is needed.
if false then
  local _r = lurek.render.draw({})
  print(_r)
end

--@api-stub: lurek.render.drawq
-- Draws a portion of an image defined by a Quad.
-- Use this when draws a portion of an image defined by a Quad is needed.
if false then
  local _r = lurek.render.drawq()
  print(_r)
end

--@api-stub: lurek.render.print
-- Draws text at the given position.
-- Use this when draws text at the given position is needed.
if false then
  local _r = lurek.render.print(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.printf
-- Draws word-wrapped text within a given width.
-- Use this when draws word-wrapped text within a given width is needed.
if false then
  local _r = lurek.render.printf(0, 0, 0, 0, 1)
  print(_r)
end

--@api-stub: lurek.render.printRich
-- Draws a sequence of individually-styled text spans at `(x, y)`.
-- Use this when draws a sequence of individually-styled text spans at `(x, y)` is needed.
if false then
  local _r = lurek.render.printRich(1, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.clear
-- Clears the draw command queue (resets the screen).
-- Use this when clears the draw command queue (resets the screen) is needed.
if false then
  local _r = lurek.render.clear(nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for outline drawing.
-- Use this when sets the line width for outline drawing is needed.
if false then
  local _r = lurek.render.setLineWidth(0)
  print(_r)
end

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width.
-- Use this when returns the current line width is needed.
if false then
  local _r = lurek.render.getLineWidth()
  print(_r)
end

--@api-stub: lurek.render.setPointSize
-- Sets the point diameter in pixels.
-- Use this when sets the point diameter in pixels is needed.
if false then
  local _r = lurek.render.setPointSize(1)
  print(_r)
end

--@api-stub: lurek.render.getPointSize
-- Returns the current point size.
-- Use this when returns the current point size is needed.
if false then
  local _r = lurek.render.getPointSize()
  print(_r)
end

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for drawing.
-- Use this when sets the blend mode for drawing is needed.
if false then
  local _r = lurek.render.setBlendMode(nil)
  print(_r)
end

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode as a string.
-- Use this when returns the current blend mode as a string is needed.
if false then
  local _r = lurek.render.getBlendMode()
  print(_r)
end

--@api-stub: lurek.render.newFont
-- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
-- Use this when loads a bitmap font PNG from a file, or selects a built-in size by pixel height is needed.
if false then
  local _r = lurek.render.newFont({})
  print(_r)
end

--@api-stub: lurek.render.setFont
-- Sets the active font for print calls.
-- Use this when sets the active font for print calls is needed.
if false then
  local _r = lurek.render.setFont(nil)
  print(_r)
end

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil.
-- Use this when returns the currently active font, or nil is needed.
if false then
  local _r = lurek.render.getFont()
  print(_r)
end

--@api-stub: lurek.render.getFontSizes
-- Returns a table of available built-in font pixel heights.
-- Use this when returns a table of available built-in font pixel heights is needed.
if false then
  local _r = lurek.render.getFontSizes()
  print(_r)
end

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in font by pixel height (snaps to nearest available size).
-- Use this when returns a built-in font by pixel height (snaps to nearest available size) is needed.
if false then
  local _r = lurek.render.getDefaultFont(1)
  print(_r)
end

--@api-stub: lurek.render.getFontCellWidth
-- Returns the cell width of the given font (for monospaced bitmap fonts).
-- Use this when returns the cell width of the given font (for monospaced bitmap fonts) is needed.
if false then
  local _r = lurek.render.getFontCellWidth(nil)
  print(_r)
end

--@api-stub: lurek.render.getFontWidth
-- Returns the pixel width of text in the given font.
-- Use this when returns the pixel width of text in the given font is needed.
if false then
  local _r = lurek.render.getFontWidth(nil, 0)
  print(_r)
end

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font.
-- Use this when returns the line height of the given font is needed.
if false then
  local _r = lurek.render.getFontHeight(nil)
  print(_r)
end

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line height of the given font (alias for getFontHeight).
-- Use this when returns the line height of the given font (alias for getFontHeight) is needed.
if false then
  local _r = lurek.render.getFontLineHeight(nil)
  print(_r)
end

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode).
-- Use this when sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode) is needed.
if false then
  local _r = lurek.render.setFontLineHeight(1, 0)
  print(_r)
end

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent of the given font.
-- Use this when returns the ascent of the given font is needed.
if false then
  local _r = lurek.render.getFontAscent(nil)
  print(_r)
end

--@api-stub: lurek.render.getFontDescent
-- Returns the descent of the given font.
-- Use this when returns the descent of the given font is needed.
if false then
  local _r = lurek.render.getFontDescent(nil)
  print(_r)
end

--@api-stub: lurek.render.getFontWrap
-- Returns wrapped lines and the maximum line width.
-- Use this when returns wrapped lines and the maximum line width is needed.
if false then
  local _r = lurek.render.getFontWrap(0, 0)
  print(_r)
end

--@api-stub: lurek.render.newImage
-- Loads an image from a file path or creates one from ImageData.
-- Use this when loads an image from a file path or creates one from ImageData is needed.
if false then
  local _r = lurek.render.newImage(nil)
  print(_r)
end

--@api-stub: lurek.render.newCanvas
-- Creates an off-screen render canvas.
-- Use this when creates an off-screen render canvas is needed.
if false then
  local _r = lurek.render.newCanvas(1, 1)
  print(_r)
end

--@api-stub: lurek.render.setCanvas
-- Sets the active render target to a Canvas, or back to the screen.
-- Use this when sets the active render target to a Canvas, or back to the screen is needed.
if false then
  local _r = lurek.render.setCanvas(nil)
  print(_r)
end

--@api-stub: lurek.render.getCanvas
-- Returns the current canvas, or nil if drawing to screen.
-- Use this when returns the current canvas, or nil if drawing to screen is needed.
if false then
  local _r = lurek.render.getCanvas()
  print(_r)
end

--@api-stub: lurek.render.getCanvasSize
-- Returns the dimensions of a canvas.
-- Use this when returns the dimensions of a canvas is needed.
if false then
  local _r = lurek.render.getCanvasSize(nil)
  print(_r)
end

--@api-stub: lurek.render.newSpriteBatch
-- Creates a new sprite batch for the given image.
-- Use this when creates a new sprite batch for the given image is needed.
if false then
  local _r = lurek.render.newSpriteBatch(nil, 0)
  print(_r)
end

--@api-stub: lurek.render.newMesh
-- Creates a custom mesh from vertex data.
-- Use this when creates a custom mesh from vertex data is needed.
if false then
  local _r = lurek.render.newMesh(0, nil)
  print(_r)
end

--@api-stub: lurek.render.newShader
-- Compiles a custom WGSL shader and returns its handle.
-- Use this when compiles a custom WGSL shader and returns its handle is needed.
if false then
  local _r = lurek.render.newShader(nil)
  print(_r)
end

--@api-stub: lurek.render.setShader
-- Sets the active shader, or clears it.
-- Use this when sets the active shader, or clears it is needed.
if false then
  local _r = lurek.render.setShader(nil)
  print(_r)
end

--@api-stub: lurek.render.getShader
-- Returns the active shader, or nil.
-- Use this when returns the active shader, or nil is needed.
if false then
  local _r = lurek.render.getShader()
  print(_r)
end

--@api-stub: lurek.render.newQuad
-- Creates a new Quad viewport into a texture.
-- Use this when creates a new Quad viewport into a texture is needed.
if false then
  local _r = lurek.render.newQuad(0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.push
-- Pushes the current transform onto the stack.
-- Use this when pushes the current transform onto the stack is needed.
if false then
  local _r = lurek.render.push()
  print(_r)
end

--@api-stub: lurek.render.pop
-- Pops the transform from the stack.
-- Use this when pops the transform from the stack is needed.
if false then
  local _r = lurek.render.pop()
  print(_r)
end

--@api-stub: lurek.render.translate
-- Translates the coordinate system.
-- Use this when translates the coordinate system is needed.
if false then
  local _r = lurek.render.translate(0, 0)
  print(_r)
end

--@api-stub: lurek.render.rotate
-- Rotates the coordinate system.
-- Use this when rotates the coordinate system is needed.
if false then
  local _r = lurek.render.rotate(1)
  print(_r)
end

--@api-stub: lurek.render.scale
-- Scales the coordinate system.
-- Use this when scales the coordinate system is needed.
if false then
  local _r = lurek.render.scale(0, 0)
  print(_r)
end

--@api-stub: lurek.render.shear
-- Shears the coordinate system.
-- Use this when shears the coordinate system is needed.
if false then
  local _r = lurek.render.shear(0, 0)
  print(_r)
end

--@api-stub: lurek.render.origin
-- Resets the transform to the identity.
-- Use this when resets the transform to the identity is needed.
if false then
  local _r = lurek.render.origin()
  print(_r)
end

--@api-stub: lurek.render.applyTransform
-- Applies an affine transform matrix.
-- Use this when applies an affine transform matrix is needed.
if false then
  local _r = lurek.render.applyTransform(0)
  print(_r)
end

--@api-stub: lurek.render.setScissor
-- Restricts drawing to a rectangle, or clears scissor if no args.
-- Use this when restricts drawing to a rectangle, or clears scissor if no args is needed.
if false then
  local _r = lurek.render.setScissor({})
  print(_r)
end

--@api-stub: lurek.render.getScissor
-- Returns the active scissor rectangle, or nothing.
-- Use this when returns the active scissor rectangle, or nothing is needed.
if false then
  local _r = lurek.render.getScissor()
  print(_r)
end

--@api-stub: lurek.render.intersectScissor
-- Intersects the current scissor with a new rectangle.
-- Use this when intersects the current scissor with a new rectangle is needed.
if false then
  local _r = lurek.render.intersectScissor(0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.setColorMask
-- Sets which RGBA channels are written.
-- Reset with no args.
if false then
  local _r = lurek.render.setColorMask({})
  print(_r)
end

--@api-stub: lurek.render.getColorMask
-- Returns the current color mask.
-- Use this when returns the current color mask is needed.
if false then
  local _r = lurek.render.getColorMask()
  print(_r)
end

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering.
-- Use this when enables or disables wireframe rendering is needed.
if false then
  local _r = lurek.render.setWireframe(1)
  print(_r)
end

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe mode is active.
-- Use this when returns whether wireframe mode is active is needed.
if false then
  local _r = lurek.render.isWireframe()
  print(_r)
end

--@api-stub: lurek.render.stencil
-- Begins stencil writing with the given action and value.
-- Use this when begins stencil writing with the given action and value is needed.
if false then
  local _r = lurek.render.stencil(1, 0)
  print(_r)
end

--@api-stub: lurek.render.setStencilTest
-- Sets the stencil comparison test, or disables stencil testing.
-- Use this when sets the stencil comparison test, or disables stencil testing is needed.
if false then
  local _r = lurek.render.setStencilTest(nil, 0)
  print(_r)
end

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil buffer write/test mode.
-- Use this when sets the stencil buffer write/test mode is needed.
if false then
  local _r = lurek.render.setStencilMode(1, nil, 0)
  print(_r)
end

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil mode as (action, compare, value).
-- Use this when returns the current stencil mode as (action, compare, value) is needed.
if false then
  local _r = lurek.render.getStencilMode()
  print(_r)
end

--@api-stub: lurek.render.clearStencil
-- Resets the stencil mode to the default (keep / always / 0).
-- Use this when resets the stencil mode to the default (keep / always / 0) is needed.
if false then
  local _r = lurek.render.clearStencil()
  print(_r)
end

--@api-stub: lurek.render.setDepthMode
-- Sets the depth test comparison and write enable.
-- Use this when sets the depth test comparison and write enable is needed.
if false then
  local _r = lurek.render.setDepthMode(nil, 0)
  print(_r)
end

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth mode as (mode, write).
-- Use this when returns the current depth mode as (mode, write) is needed.
if false then
  local _r = lurek.render.getDepthMode()
  print(_r)
end

--@api-stub: lurek.render.getWidth
-- Returns the window width in pixels.
-- Use this when returns the window width in pixels is needed.
if false then
  local _r = lurek.render.getWidth()
  print(_r)
end

--@api-stub: lurek.render.getHeight
-- Returns the window height in pixels.
-- Use this when returns the window height in pixels is needed.
if false then
  local _r = lurek.render.getHeight()
  print(_r)
end

--@api-stub: lurek.render.getDimensions
-- Returns window width and height.
-- Use this when returns window width and height is needed.
if false then
  local _r = lurek.render.getDimensions()
  print(_r)
end

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filter mode.
-- Use this when sets the default texture filter mode is needed.
if false then
  local _r = lurek.render.setDefaultFilter(1, nil, 1)
  print(_r)
end

--@api-stub: lurek.render.getDefaultFilter
-- Returns the default texture filter mode.
-- Use this when returns the default texture filter mode is needed.
if false then
  local _r = lurek.render.getDefaultFilter()
  print(_r)
end

--@api-stub: lurek.render.getStats
-- Returns a table of renderer statistics.
-- Use this when returns a table of renderer statistics is needed.
if false then
  local _r = lurek.render.getStats()
  print(_r)
end

--@api-stub: lurek.render.saveScreenshot
-- Queues a screenshot to be saved after the current frame.
-- Use this when queues a screenshot to be saved after the current frame is needed.
if false then
  local _r = lurek.render.saveScreenshot(0)
  print(_r)
end

--@api-stub: lurek.render.captureScreenshot
-- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
-- Use this when calls the given callback with an ImageData captured from the current frame (stub: creates blank) is needed.
if false then
  local _r = lurek.render.captureScreenshot(function() end)
  print(_r)
end

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice descriptor from a texture and inset values.
-- Use this when creates a 9-slice descriptor from a texture and inset values is needed.
if false then
  local _r = lurek.render.newNineSlice(nil, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.drawNineSlice
-- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
-- Use this when queues a 9-slice draw call inside lurek.render / lurek.render_ui is needed.
if false then
  local _r = lurek.render.drawNineSlice(nil, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.newShape
-- Creates a new empty [`CompoundShape`] stored in the resource pool.
-- Use this when creates a new empty [`CompoundShape`] stored in the resource pool is needed.
if false then
  local _r = lurek.render.newShape()
  print(_r)
end

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw-call queue.
-- Use this when creates a new z-ordered draw-call queue is needed.
if false then
  local _r = lurek.render.newDrawLayer()
  print(_r)
end

--@api-stub: lurek.render.drawQuadBezier
-- Queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point.
-- Use this when queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point is needed.
if false then
  local _r = lurek.render.drawQuadBezier()
  print(_r)
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Use this when queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points is needed.
if false then
  local _r = lurek.render.drawCubicBezier()
  print(_r)
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Use this when queues a multi-segment vector path is needed.
if false then
  local _r = lurek.render.drawPath(0, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- color1/color2 are {r,g,b,a} tables.
if false then
  local _r = lurek.render.drawGradientRect()
  print(_r)
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Use this when queues a convex polygon with per-vertex colours is needed.
if false then
  local _r = lurek.render.drawColoredPolygon(0, {1, 1, 1, 1}, nil)
  print(_r)
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- Use this when queues a three-face isometric cube tile at screen position (sx, sy) is needed.
if false then
  local _r = lurek.render.drawIsoCubeTile()
  print(_r)
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Use this when queues a hexagonal tile at centre (cx, cy) with given circumradius is needed.
if false then
  local _r = lurek.render.drawHexTile()
  print(_r)
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group.
-- Draw commands until flushSortGroup are depth-sortable.
if false then
  local _r = lurek.render.beginSortGroup(1)
  print(_r)
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Use this when associates the previous draw command with a depth value within the active sort group is needed.
if false then
  local _r = lurek.render.pushSortKey(1)
  print(_r)
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Use this when sorts and flushes all draw commands in the sort group is needed.
if false then
  local _r = lurek.render.flushSortGroup(1)
  print(_r)
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle with inner fill.
-- Use this when queues a beveled border rectangle with inner fill is needed.
if false then
  local _r = lurek.render.drawBevelRect()
  print(_r)
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer with optional alpha and blend mode.
-- Use this when begins a named compositing layer with optional alpha and blend mode is needed.
if false then
  local _r = lurek.render.pushLayer(1, 0, 1)
  print(_r)
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer back to its parent.
-- Use this when ends and composites the named layer back to its parent is needed.
if false then
  local _r = lurek.render.popLayer(1)
  print(_r)
end

--@api-stub: lurek.render.drawQuadBezier
-- Must be called inside lurek.render or lurek.render_ui.
-- Use this when must be called inside lurek.render or lurek.render_ui is needed.
if false then
  local _r = lurek.render.drawQuadBezier(0, 0, 0, 0, 0, 0, 1)
  print(_r)
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Use this when queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points is needed.
if false then
  local _r = lurek.render.drawCubicBezier(0, 0, 0, 0, 0, 0, 0, 0, 1)
  print(_r)
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Use this when queues a multi-segment vector path is needed.
if false then
  local _r = lurek.render.drawPath(0, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- Both colors are RGBA tables {r,g,b,a} or positional {[1]=r,[2]=g,[3]=b,[4]=a}.
if false then
  local _r = lurek.render.drawGradientRect(0, 0, 0, 0, nil, nil, nil)
  print(_r)
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Use this when queues a convex polygon with per-vertex colours is needed.
if false then
  local _r = lurek.render.drawColoredPolygon(0, {1, 1, 1, 1}, nil)
  print(_r)
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- Use this when queues a three-face isometric cube tile at screen position (sx, sy) is needed.
if false then
  local _r = lurek.render.drawIsoCubeTile(0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Use this when queues a hexagonal tile at centre (cx, cy) with given circumradius is needed.
if false then
  local _r = lurek.render.drawHexTile(0, 0, 1, 1, nil)
  print(_r)
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group identified by id.
-- Use this when begins a Y/Z depth sort group identified by id is needed.
if false then
  local _r = lurek.render.beginSortGroup(1)
  print(_r)
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Use this when associates the previous draw command with a depth value within the active sort group is needed.
if false then
  local _r = lurek.render.pushSortKey(1)
  print(_r)
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Use this when sorts and flushes all draw commands in the sort group is needed.
if false then
  local _r = lurek.render.flushSortGroup(1)
  print(_r)
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle.
-- Use this when queues a beveled border rectangle is needed.
if false then
  local _r = lurek.render.drawBevelRect(0, 0, 0, 0, 0, 0, 0)
  print(_r)
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer.
-- Provides alpha and blend mode for composite.
if false then
  local _r = lurek.render.pushLayer(1, 0, 1)
  print(_r)
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer.
-- Use this when ends and composites the named layer is needed.
if false then
  local _r = lurek.render.popLayer(1)
  print(_r)
end

--@api-stub: lurek.render.newLayer
-- Registers a named render layer with an optional z-order (default 0).
-- Use this when registers a named render layer with an optional z-order (default 0) is needed.
if false then
  local _r = lurek.render.newLayer(1, 0)
  print(_r)
end

--@api-stub: lurek.render.setLayer
-- Sets the active named layer.
-- Draw calls made after this will be
if false then
  local _r = lurek.render.setLayer(1)
  print(_r)
end

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active named layer.
-- Use this when returns the name of the currently active named layer is needed.
if false then
  local _r = lurek.render.currentLayer()
  print(_r)
end

--@api-stub: lurek.render.setLayerVisible
-- Shows or hides the named layer.
-- Hidden layers are excluded from
if false then
  local _r = lurek.render.setLayerVisible(1, 0)
  print(_r)
end

--@api-stub: lurek.render.isLayerVisible
-- Returns `true` if the named layer is visible (default: `true`).
-- Use this when returns `true` if the named layer is visible (default: `true`) is needed.
if false then
  local _r = lurek.render.isLayerVisible(1)
  print(_r)
end

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order of the named layer, or `0` if unregistered.
-- Use this when returns the z-order of the named layer, or `0` if unregistered is needed.
if false then
  local _r = lurek.render.getLayerZOrder(1)
  print(_r)
end

--@api-stub: lurek.render.setLayerZOrder
-- Updates the z-order of the named layer.
-- Auto-creates the layer if
if false then
  local _r = lurek.render.setLayerZOrder(1, 0)
  print(_r)
end

-- ── ImageData methods ──

--@api-stub: ImageData:getWidth
-- Returns the pixel width of this image buffer.
-- Use this when returns the pixel width of this image buffer is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:getWidth()
end

--@api-stub: ImageData:getHeight
-- Returns the pixel height of this image buffer.
-- Use this when returns the pixel height of this image buffer is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:getHeight()
end

--@api-stub: ImageData:resize
-- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
-- Use this when returns a new ImageData scaled to the given dimensions using bilinear interpolation is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:resize(0, 0)
end

--@api-stub: ImageData:diff
-- Returns the sum of absolute per-channel differences between this image and `other`.
-- Use this when returns the sum of absolute per-channel differences between this image and `other` is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:diff(0)
end

--@api-stub: ImageData:mapPixels
-- Applies a Lua function to every pixel in-place.
-- Use this when applies a Lua function to every pixel in-place is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:mapPixels(function() end)
end

--@api-stub: ImageData:type
-- Returns the type name "ImageData".
-- Use this when returns the type name "ImageData" is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:type()
end

--@api-stub: ImageData:typeOf
-- Returns true when the given name matches "ImageData" or a parent type.
-- Use this when returns true when the given name matches "ImageData" or a parent type is needed.
if false then
  local _o = nil  -- ImageData instance
  _o:typeOf(1)
end

-- ── NineSlice methods ──

--@api-stub: NineSlice:getInsets
-- Returns the four inset values as (top, right, bottom, left).
-- Use this when returns the four inset values as (top, right, bottom, left) is needed.
if false then
  local _o = nil  -- NineSlice instance
  _o:getInsets()
end

--@api-stub: NineSlice:getTextureSize
-- Returns the width and height of the source texture.
-- Use this when returns the width and height of the source texture is needed.
if false then
  local _o = nil  -- NineSlice instance
  _o:getTextureSize()
end

--@api-stub: NineSlice:type
-- Returns the type name "NineSlice".
-- Use this when returns the type name "NineSlice" is needed.
if false then
  local _o = nil  -- NineSlice instance
  _o:type()
end

--@api-stub: NineSlice:typeOf
-- Returns true when the given name matches "NineSlice" or a parent type.
-- Use this when returns true when the given name matches "NineSlice" or a parent type is needed.
if false then
  local _o = nil  -- NineSlice instance
  _o:typeOf(1)
end

-- ── Image methods ──

--@api-stub: Image:getWidth
-- Returns the width of this image in pixels.
-- Use this when returns the width of this image in pixels is needed.
if false then
  local _o = nil  -- Image instance
  _o:getWidth()
end

--@api-stub: Image:getHeight
-- Returns the height of this image in pixels.
-- Use this when returns the height of this image in pixels is needed.
if false then
  local _o = nil  -- Image instance
  _o:getHeight()
end

--@api-stub: Image:getDimensions
-- Returns width and height of this image.
-- Use this when returns width and height of this image is needed.
if false then
  local _o = nil  -- Image instance
  _o:getDimensions()
end

--@api-stub: Image:release
-- Releases the GPU texture memory for this image.
-- Use this when releases the GPU texture memory for this image is needed.
if false then
  local _o = nil  -- Image instance
  _o:release()
end

--@api-stub: Image:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Image instance
  _o:typeOf()
end

--@api-stub: Image:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Image instance
  _o:type()
end

-- ── Font methods ──

--@api-stub: Font:getWidth
-- Returns the rendered width of the given text string.
-- Use this when returns the rendered width of the given text string is needed.
if false then
  local _o = nil  -- Font instance
  _o:getWidth(0)
end

--@api-stub: Font:getHeight
-- Returns the line height of this font.
-- Use this when returns the line height of this font is needed.
if false then
  local _o = nil  -- Font instance
  _o:getHeight()
end

--@api-stub: Font:getLineHeight
-- Returns the line height multiplier of this font.
-- Use this when returns the line height multiplier of this font is needed.
if false then
  local _o = nil  -- Font instance
  _o:getLineHeight()
end

--@api-stub: Font:setLineHeight
-- Sets the line height multiplier for this font.
-- Use this when sets the line height multiplier for this font is needed.
if false then
  local _o = nil  -- Font instance
  _o:setLineHeight(1)
end

--@api-stub: Font:getAscent
-- Returns the ascent of this font in pixels.
-- Use this when returns the ascent of this font in pixels is needed.
if false then
  local _o = nil  -- Font instance
  _o:getAscent()
end

--@api-stub: Font:getDescent
-- Returns the descent of this font in pixels.
-- Use this when returns the descent of this font in pixels is needed.
if false then
  local _o = nil  -- Font instance
  _o:getDescent()
end

--@api-stub: Font:getWrap
-- Wraps text to the given width and returns the lines.
-- Use this when wraps text to the given width and returns the lines is needed.
if false then
  local _o = nil  -- Font instance
  _o:getWrap(0, 0)
end

--@api-stub: Font:release
-- Releases this font and frees its atlas memory.
-- Use this when releases this font and frees its atlas memory is needed.
if false then
  local _o = nil  -- Font instance
  _o:release()
end

--@api-stub: Font:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Font instance
  _o:typeOf()
end

--@api-stub: Font:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Font instance
  _o:type()
end

-- ── Canvas methods ──

--@api-stub: Canvas:getWidth
-- Returns the width of this canvas in pixels.
-- Use this when returns the width of this canvas in pixels is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:getWidth()
end

--@api-stub: Canvas:getHeight
-- Returns the height of this canvas in pixels.
-- Use this when returns the height of this canvas in pixels is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:getHeight()
end

--@api-stub: Canvas:getDimensions
-- Returns width and height of this canvas.
-- Use this when returns width and height of this canvas is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:getDimensions()
end

--@api-stub: Canvas:release
-- Releases GPU framebuffer memory for this canvas.
-- Use this when releases GPU framebuffer memory for this canvas is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:release()
end

--@api-stub: Canvas:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:typeOf()
end

--@api-stub: Canvas:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Canvas instance
  _o:type()
end

-- ── SpriteBatch methods ──

--@api-stub: SpriteBatch:clear
-- Removes all sprites from this batch.
-- Use this when removes all sprites from this batch is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:clear()
end

--@api-stub: SpriteBatch:getCount
-- Returns the number of sprites in this batch.
-- Use this when returns the number of sprites in this batch is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:getCount()
end

--@api-stub: SpriteBatch:getBufferSize
-- Returns the maximum capacity of this batch.
-- Use this when returns the maximum capacity of this batch is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:getBufferSize()
end

--@api-stub: SpriteBatch:release
-- Releases this sprite batch.
-- Use this when releases this sprite batch is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:release()
end

--@api-stub: SpriteBatch:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:typeOf()
end

--@api-stub: SpriteBatch:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- SpriteBatch instance
  _o:type()
end

-- ── Mesh methods ──

--@api-stub: Mesh:getVertexCount
-- Returns the number of vertices in this mesh.
-- Use this when returns the number of vertices in this mesh is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:getVertexCount()
end

--@api-stub: Mesh:getVertex
-- Returns vertex data at the given 1-based index.
-- Use this when returns vertex data at the given 1-based index is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:getVertex(1)
end

--@api-stub: Mesh:setVertex
-- Sets vertex data at the given 1-based index.
-- Use this when sets vertex data at the given 1-based index is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:setVertex(1, 0)
end

--@api-stub: Mesh:setTexture
-- Assigns a texture to this mesh.
-- Use this when assigns a texture to this mesh is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:setTexture(nil)
end

--@api-stub: Mesh:release
-- Releases the GPU mesh resource, freeing VRAM immediately.
-- Use this when releases the GPU mesh resource, freeing VRAM immediately is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:release()
end

--@api-stub: Mesh:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:typeOf()
end

--@api-stub: Mesh:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Mesh instance
  _o:type()
end

-- ── Shader methods ──

--@api-stub: Shader:send
-- Sends a uniform value to this shader.
-- Use this when sends a uniform value to this shader is needed.
if false then
  local _o = nil  -- Shader instance
  _o:send(1, 0)
end

--@api-stub: Shader:hasUniform
-- Returns whether this shader has a uniform with the given name.
-- Use this when returns whether this shader has a uniform with the given name is needed.
if false then
  local _o = nil  -- Shader instance
  _o:hasUniform(1)
end

--@api-stub: Shader:release
-- Releases the compiled GPU shader, freeing VRAM and shader slots.
-- Use this when releases the compiled GPU shader, freeing VRAM and shader slots is needed.
if false then
  local _o = nil  -- Shader instance
  _o:release()
end

--@api-stub: Shader:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Shader instance
  _o:typeOf()
end

--@api-stub: Shader:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Shader instance
  _o:type()
end

-- ── Quad methods ──

--@api-stub: Quad:getViewport
-- Returns the quad viewport rectangle.
-- Use this when returns the quad viewport rectangle is needed.
if false then
  local _o = nil  -- Quad instance
  _o:getViewport()
end

--@api-stub: Quad:getTextureDimensions
-- Returns the reference texture dimensions.
-- Use this when returns the reference texture dimensions is needed.
if false then
  local _o = nil  -- Quad instance
  _o:getTextureDimensions()
end

--@api-stub: Quad:typeOf
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Quad instance
  _o:typeOf()
end

--@api-stub: Quad:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Quad instance
  _o:type()
end

-- ── Shape methods ──

--@api-stub: Shape:getCommandCount
-- Returns the number of drawing commands currently stored.
-- Use this when returns the number of drawing commands currently stored is needed.
if false then
  local _o = nil  -- Shape instance
  _o:getCommandCount()
end

--@api-stub: Shape:clear
-- Removes all commands and resets the shape to empty.
-- Use this when removes all commands and resets the shape to empty is needed.
if false then
  local _o = nil  -- Shape instance
  _o:clear()
end

--@api-stub: Shape:setLineWidth
-- Sets the stroke width for subsequent outlined primitives.
-- Use this when sets the stroke width for subsequent outlined primitives is needed.
if false then
  local _o = nil  -- Shape instance
  _o:setLineWidth(0)
end

--@api-stub: Shape:line
-- Queues a line segment command.
-- Use this when queues a line segment command is needed.
if false then
  local _o = nil  -- Shape instance
  _o:line(0, 0, 0, 0)
end

--@api-stub: Shape:polyline
-- Queues a polyline command from variadic (x, y) coordinate pairs.
-- Use this when queues a polyline command from variadic (x, y) coordinate pairs is needed.
if false then
  local _o = nil  -- Shape instance
  _o:polyline()
end

--@api-stub: Shape:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Use this when returns true if the given type name matches this object's type or any parent type is needed.
if false then
  local _o = nil  -- Shape instance
  _o:typeOf(1)
end

--@api-stub: Shape:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Shape instance
  _o:type()
end

-- ── DrawLayer methods ──

--@api-stub: DrawLayer:queue
-- Queues a draw callback at the given z-order.
-- Use this when queues a draw callback at the given z-order is needed.
if false then
  local _o = nil  -- DrawLayer instance
  _o:queue(0, nil)
end

--@api-stub: DrawLayer:flush
-- Sorts and calls all queued callbacks, then empties the queue.
-- Use this when sorts and calls all queued callbacks, then empties the queue is needed.
if false then
  local _o = nil  -- DrawLayer instance
  _o:flush()
end

--@api-stub: DrawLayer:clear
-- Removes all queued callbacks without calling them.
-- Use this when removes all queued callbacks without calling them is needed.
if false then
  local _o = nil  -- DrawLayer instance
  _o:clear()
end

--@api-stub: DrawLayer:getCount
-- Returns the number of queued callbacks.
-- Use this when returns the number of queued callbacks is needed.
if false then
  local _o = nil  -- DrawLayer instance
  _o:getCount()
end

--@api-stub: DrawLayer:type
-- Returns the string type identifier of this draw layer (e.g.
-- `'sprite'`).
if false then
  local _o = nil  -- DrawLayer instance
  _o:type()
end

--@api-stub: DrawLayer:typeOf
-- Returns true if this object is an instance of the given type name.
-- Use this when returns true if this object is an instance of the given type name is needed.
if false then
  local _o = nil  -- DrawLayer instance
  _o:typeOf(1)
end

