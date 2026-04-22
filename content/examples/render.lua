-- content/examples/render.lua
-- Practical usage examples for the lurek.render API (183 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.render.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/render.lua

print("[example] lurek.render — 183 API entries")

-- ── lurek.render.* free functions ──

--@api-stub: lurek.render.setColor
-- Sets the current drawing color.
-- Call when you need to assign color.
local ok, err = pcall(function() lurek.render.setColor(1, 1, 1, 1) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setColor applied=", ok)

--@api-stub: lurek.render.getColor
-- Returns the current drawing color.
-- Call when you need to read color.
local ok, value = pcall(function() return lurek.render.getColor() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getColor ->", v)

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color.
-- Call when you need to assign background color.
local ok, err = pcall(function() lurek.render.setBackgroundColor(1, 1, 1) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setBackgroundColor applied=", ok)

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background color.
-- Call when you need to read background color.
local ok, value = pcall(function() return lurek.render.getBackgroundColor() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getBackgroundColor ->", v)

--@api-stub: lurek.render.rectangle
-- Draws a filled or outlined axis-aligned rectangle at the given position.
-- Call when you need to invoke rectangle.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.rectangle() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.rectangle drawn=", ok)

--@api-stub: lurek.render.circle
-- Draws a filled or outlined circle at the given world-space position.
-- Call when you need to invoke circle.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.circle("fill", 0, 0, nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.circle drawn=", ok)

--@api-stub: lurek.render.ellipse
-- Draws a filled or outlined ellipse with independent x/y radii.
-- Call when you need to invoke ellipse.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.ellipse("fill", 0, 0, nil, nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.ellipse drawn=", ok)

--@api-stub: lurek.render.triangle
-- Draws a filled or outlined triangle connecting three world-space vertices.
-- Call when you need to invoke triangle.
local ok, result = pcall(function() return lurek.render.triangle("fill", nil, nil, nil, nil, nil, nil) end)
if ok then print("lurek.render.triangle ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.line
-- Draws a line between two points.
-- Call when you need to invoke line.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.line({}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.line drawn=", ok)

--@api-stub: lurek.render.polygon
-- Draws a polygon from a list of vertices.
-- Call when you need to invoke polygon.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.polygon({}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.polygon drawn=", ok)

--@api-stub: lurek.render.arc
-- Draws a partial circle arc at the given position with specified radius and angle range.
-- Call when you need to invoke arc.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.arc() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.arc drawn=", ok)

--@api-stub: lurek.render.points
-- Draws a batch of individual points at the specified world-space coordinates.
-- Call when you need to invoke points.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.points({}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.points drawn=", ok)

--@api-stub: lurek.render.draw
-- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
-- Call when you need to invoke draw.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.draw({}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.draw drawn=", ok)

--@api-stub: lurek.render.drawq
-- Draws a portion of an image defined by a Quad.
-- Call when you need to invoke drawq.
local ok, result = pcall(function() return lurek.render.drawq() end)
if ok then print("lurek.render.drawq ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.print
-- Draws text at the given position.
-- Call when you need to invoke print.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.print("hello", 0, 0, 1) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.print drawn=", ok)

--@api-stub: lurek.render.printf
-- Draws word-wrapped text within a given width.
-- Call when you need to invoke printf.
local ok, result = pcall(function() return lurek.render.printf("hello", 0, 0, nil, nil) end)
if ok then print("lurek.render.printf ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.printRich
-- Draws a sequence of individually-styled text spans at `(x, y)`.
-- Call when you need to render rich.
local ok, result = pcall(function() return lurek.render.printRich({}, 0, 0) end)
if ok then print("lurek.render.printRich ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.clear
-- Clears the draw command queue (resets the screen).
-- Call when you need to invoke clear.
local ok, err = pcall(function() lurek.render.clear(1, 1, 1) end)
if not ok then print("skipped:", err) end
print("lurek.render.clear cleared=", ok)

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for outline drawing.
-- Call when you need to assign line width.
local ok, err = pcall(function() lurek.render.setLineWidth(100) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setLineWidth applied=", ok)

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width.
-- Call when you need to read line width.
local ok, value = pcall(function() return lurek.render.getLineWidth() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getLineWidth ->", v)

--@api-stub: lurek.render.setPointSize
-- Sets the point diameter in pixels.
-- Call when you need to assign point size.
local ok, err = pcall(function() lurek.render.setPointSize(10) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setPointSize applied=", ok)

--@api-stub: lurek.render.getPointSize
-- Returns the current point size.
-- Call when you need to read point size.
local ok, value = pcall(function() return lurek.render.getPointSize() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getPointSize ->", v)

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for drawing.
-- Call when you need to assign blend mode.
local ok, err = pcall(function() lurek.render.setBlendMode("fill") end)
if not ok then print("set skipped:", err) end
print("lurek.render.setBlendMode applied=", ok)

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode as a string.
-- Call when you need to read blend mode.
local ok, value = pcall(function() return lurek.render.getBlendMode() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getBlendMode ->", v)

--@api-stub: lurek.render.newFont
-- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
-- Call when you need to create a new font.
local ok, obj = pcall(function() return lurek.render.newFont({}) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newFont ok=", ok)

--@api-stub: lurek.render.setFont
-- Sets the active font for print calls.
-- Call when you need to assign font.
local ok, err = pcall(function() lurek.render.setFont(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setFont applied=", ok)

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil.
-- Call when you need to read font.
local ok, value = pcall(function() return lurek.render.getFont() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFont ->", v)

--@api-stub: lurek.render.getFontSizes
-- Returns a table of available built-in font pixel heights.
-- Call when you need to read font sizes.
local ok, value = pcall(function() return lurek.render.getFontSizes() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontSizes ->", v)

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in font by pixel height (snaps to nearest available size).
-- Call when you need to read default font.
local ok, value = pcall(function() return lurek.render.getDefaultFont(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getDefaultFont ->", v)

--@api-stub: lurek.render.getFontCellWidth
-- Returns the cell width of the given font (for monospaced bitmap fonts).
-- Call when you need to read font cell width.
local ok, value = pcall(function() return lurek.render.getFontCellWidth(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontCellWidth ->", v)

--@api-stub: lurek.render.getFontWidth
-- Returns the pixel width of text in the given font.
-- Call when you need to read font width.
local ok, value = pcall(function() return lurek.render.getFontWidth(nil, "hello") end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontWidth ->", v)

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font.
-- Call when you need to read font height.
local ok, value = pcall(function() return lurek.render.getFontHeight(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontHeight ->", v)

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line height of the given font (alias for getFontHeight).
-- Call when you need to read font line height.
local ok, value = pcall(function() return lurek.render.getFontLineHeight(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontLineHeight ->", v)

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height of the given font (stub â€” returns nil; fonts are immutable in headless mode).
-- Call when you need to assign font line height.
local ok, err = pcall(function() lurek.render.setFontLineHeight(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setFontLineHeight applied=", ok)

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent of the given font.
-- Call when you need to read font ascent.
local ok, value = pcall(function() return lurek.render.getFontAscent(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontAscent ->", v)

--@api-stub: lurek.render.getFontDescent
-- Returns the descent of the given font.
-- Call when you need to read font descent.
local ok, value = pcall(function() return lurek.render.getFontDescent(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontDescent ->", v)

--@api-stub: lurek.render.getFontWrap
-- Returns wrapped lines and the maximum line width.
-- Call when you need to read font wrap.
local ok, value = pcall(function() return lurek.render.getFontWrap("hello", nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getFontWrap ->", v)

--@api-stub: lurek.render.newImage
-- Loads an image from a file path or creates one from ImageData.
-- Call when you need to create a new image.
local ok, obj = pcall(function() return lurek.render.newImage(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newImage ok=", ok)

--@api-stub: lurek.render.newCanvas
-- Creates an off-screen render canvas.
-- Call when you need to create a new canvas.
local ok, obj = pcall(function() return lurek.render.newCanvas(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newCanvas ok=", ok)

--@api-stub: lurek.render.setCanvas
-- Sets the active render target to a Canvas, or back to the screen.
-- Call when you need to assign canvas.
local ok, err = pcall(function() lurek.render.setCanvas(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setCanvas applied=", ok)

--@api-stub: lurek.render.getCanvas
-- Returns the current canvas, or nil if drawing to screen.
-- Call when you need to read canvas.
local ok, value = pcall(function() return lurek.render.getCanvas() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getCanvas ->", v)

--@api-stub: lurek.render.getCanvasSize
-- Returns the dimensions of a canvas.
-- Call when you need to read canvas size.
local ok, value = pcall(function() return lurek.render.getCanvasSize(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.render.getCanvasSize ->", v)

--@api-stub: lurek.render.newSpriteBatch
-- Creates a new sprite batch for the given image.
-- Call when you need to create a new sprite batch.
local ok, obj = pcall(function() return lurek.render.newSpriteBatch(nil, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newSpriteBatch ok=", ok)

--@api-stub: lurek.render.newMesh
-- Creates a custom mesh from vertex data.
-- Call when you need to create a new mesh.
local ok, obj = pcall(function() return lurek.render.newMesh(nil, "fill") end)
if ok and obj then print("created:", obj) end
print("lurek.render.newMesh ok=", ok)

--@api-stub: lurek.render.newShader
-- Compiles a custom WGSL shader and returns its handle.
-- Call when you need to create a new shader.
local ok, obj = pcall(function() return lurek.render.newShader(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newShader ok=", ok)

--@api-stub: lurek.render.setShader
-- Sets the active shader, or clears it.
-- Call when you need to assign shader.
local ok, err = pcall(function() lurek.render.setShader(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setShader applied=", ok)

--@api-stub: lurek.render.getShader
-- Returns the active shader, or nil.
-- Call when you need to read shader.
local ok, value = pcall(function() return lurek.render.getShader() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getShader ->", v)

--@api-stub: lurek.render.newQuad
-- Creates a new Quad viewport into a texture.
-- Call when you need to create a new quad.
local ok, obj = pcall(function() return lurek.render.newQuad(0, 0, 100, 100, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newQuad ok=", ok)

--@api-stub: lurek.render.push
-- Pushes the current transform onto the stack.
-- Call when you need to invoke push.
local ok, err = pcall(function() lurek.render.push() end)
if not ok then print("mutator skipped:", err) end
print("lurek.render.push done=", ok)

--@api-stub: lurek.render.pop
-- Pops the transform from the stack.
-- Call when you need to invoke pop.
local ok, err = pcall(function() lurek.render.pop() end)
if not ok then print("skipped:", err) end
print("lurek.render.pop cleared=", ok)

--@api-stub: lurek.render.translate
-- Translates the coordinate system.
-- Call when you need to invoke translate.
local ok, result = pcall(function() return lurek.render.translate(0, 0) end)
if ok then print("lurek.render.translate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.rotate
-- Rotates the coordinate system.
-- Call when you need to invoke rotate.
local ok, result = pcall(function() return lurek.render.rotate(0) end)
if ok then print("lurek.render.rotate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.scale
-- Scales the coordinate system.
-- Call when you need to invoke scale.
local ok, result = pcall(function() return lurek.render.scale(nil, nil) end)
if ok then print("lurek.render.scale ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.shear
-- Shears the coordinate system.
-- Call when you need to invoke shear.
local ok, result = pcall(function() return lurek.render.shear(nil, nil) end)
if ok then print("lurek.render.shear ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.origin
-- Resets the transform to the identity.
-- Call when you need to invoke origin.
local ok, result = pcall(function() return lurek.render.origin() end)
if ok then print("lurek.render.origin ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.applyTransform
-- Applies an affine transform matrix.
-- Call when you need to invoke apply transform.
local ok, err = pcall(function() lurek.render.applyTransform(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.applyTransform applied=", ok)

--@api-stub: lurek.render.setScissor
-- Restricts drawing to a rectangle, or clears scissor if no args.
-- Call when you need to assign scissor.
local ok, err = pcall(function() lurek.render.setScissor({}) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setScissor applied=", ok)

--@api-stub: lurek.render.getScissor
-- Returns the active scissor rectangle, or nothing.
-- Call when you need to read scissor.
local ok, value = pcall(function() return lurek.render.getScissor() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getScissor ->", v)

--@api-stub: lurek.render.intersectScissor
-- Intersects the current scissor with a new rectangle.
-- Call when you need to invoke intersect scissor.
local ok, result = pcall(function() return lurek.render.intersectScissor(0, 0, 100, 100) end)
if ok then print("lurek.render.intersectScissor ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.setColorMask
-- Sets which RGBA channels are written.
-- Reset with no args.
local ok, err = pcall(function() lurek.render.setColorMask({}) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setColorMask applied=", ok)

--@api-stub: lurek.render.getColorMask
-- Returns the current color mask.
-- Call when you need to read color mask.
local ok, value = pcall(function() return lurek.render.getColorMask() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getColorMask ->", v)

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering.
-- Call when you need to assign wireframe.
local ok, err = pcall(function() lurek.render.setWireframe(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setWireframe applied=", ok)

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe mode is active.
-- Call when you need to check is wireframe.
local ok, result = pcall(function() return lurek.render.isWireframe() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.render.isWireframe ok=", ok)

--@api-stub: lurek.render.stencil
-- Begins stencil writing with the given action and value.
-- Call when you need to invoke stencil.
local ok, result = pcall(function() return lurek.render.stencil(nil, nil) end)
if ok then print("lurek.render.stencil ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.setStencilTest
-- Sets the stencil comparison test, or disables stencil testing.
-- Call when you need to assign stencil test.
local ok, err = pcall(function() lurek.render.setStencilTest(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setStencilTest applied=", ok)

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil buffer write/test mode.
-- Call when you need to assign stencil mode.
local ok, err = pcall(function() lurek.render.setStencilMode(nil, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setStencilMode applied=", ok)

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil mode as (action, compare, value).
-- Call when you need to read stencil mode.
local ok, value = pcall(function() return lurek.render.getStencilMode() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getStencilMode ->", v)

--@api-stub: lurek.render.clearStencil
-- Resets the stencil mode to the default (keep / always / 0).
-- Call when you need to invoke clear stencil.
local ok, err = pcall(function() lurek.render.clearStencil() end)
if not ok then print("skipped:", err) end
print("lurek.render.clearStencil cleared=", ok)

--@api-stub: lurek.render.setDepthMode
-- Sets the depth test comparison and write enable.
-- Call when you need to assign depth mode.
local ok, err = pcall(function() lurek.render.setDepthMode("fill", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setDepthMode applied=", ok)

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth mode as (mode, write).
-- Call when you need to read depth mode.
local ok, value = pcall(function() return lurek.render.getDepthMode() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getDepthMode ->", v)

--@api-stub: lurek.render.getWidth
-- Returns the window width in pixels.
-- Call when you need to read width.
local ok, value = pcall(function() return lurek.render.getWidth() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getWidth ->", v)

--@api-stub: lurek.render.getHeight
-- Returns the window height in pixels.
-- Call when you need to read height.
local ok, value = pcall(function() return lurek.render.getHeight() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getHeight ->", v)

--@api-stub: lurek.render.getDimensions
-- Returns window width and height.
-- Call when you need to read dimensions.
local ok, value = pcall(function() return lurek.render.getDimensions() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getDimensions ->", v)

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filter mode.
-- Call when you need to assign default filter.
local ok, err = pcall(function() lurek.render.setDefaultFilter(0, nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setDefaultFilter applied=", ok)

--@api-stub: lurek.render.getDefaultFilter
-- Returns the default texture filter mode.
-- Call when you need to read default filter.
local ok, value = pcall(function() return lurek.render.getDefaultFilter() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getDefaultFilter ->", v)

--@api-stub: lurek.render.getStats
-- Returns a table of renderer statistics.
-- Call when you need to read stats.
local ok, value = pcall(function() return lurek.render.getStats() end)
local v = ok and value or "(unavailable)"
print("lurek.render.getStats ->", v)

--@api-stub: lurek.render.saveScreenshot
-- Queues a screenshot to be saved after the current frame.
-- Call when you need to invoke save screenshot.
local ok, obj = pcall(function() return lurek.render.saveScreenshot("path") end)
if ok and obj then print("created:", obj) end
print("lurek.render.saveScreenshot ok=", ok)

--@api-stub: lurek.render.captureScreenshot
-- Calls the given callback with an ImageData captured from the current frame (stub: creates blank).
-- Call when you need to invoke capture screenshot.
local ok, result = pcall(function() return lurek.render.captureScreenshot(function() end) end)
if ok then print("lurek.render.captureScreenshot ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice descriptor from a texture and inset values.
-- Call when you need to create a new nine slice.
local ok, obj = pcall(function() return lurek.render.newNineSlice(nil, nil, nil, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newNineSlice ok=", ok)

--@api-stub: lurek.render.drawNineSlice
-- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
-- Call when you need to render nine slice.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawNineSlice(nil, 0, 0, 100, 100) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawNineSlice drawn=", ok)

--@api-stub: lurek.render.newShape
-- Creates a new empty [`CompoundShape`] stored in the resource pool.
-- Call when you need to create a new shape.
local ok, obj = pcall(function() return lurek.render.newShape() end)
if ok and obj then print("created:", obj) end
print("lurek.render.newShape ok=", ok)

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw-call queue.
-- Call when you need to create a new draw layer.
local ok, obj = pcall(function() return lurek.render.newDrawLayer() end)
if ok and obj then print("created:", obj) end
print("lurek.render.newDrawLayer ok=", ok)

--@api-stub: lurek.render.drawQuadBezier
-- Queues a quadratic BĂ©zier curve from (x1,y1) to (x2,y2) with one control point.
-- Call when you need to render quad bezier.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawQuadBezier() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawQuadBezier drawn=", ok)

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Call when you need to render cubic bezier.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawCubicBezier() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawCubicBezier drawn=", ok)

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Call when you need to render path.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawPath("path", "fill", nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawPath drawn=", ok)

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- color1/color2 are {r,g,b,a} tables.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawGradientRect() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawGradientRect drawn=", ok)

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Call when you need to render colored polygon.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawColoredPolygon(nil, {1, 1, 1, 1}, "fill") end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawColoredPolygon drawn=", ok)

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- Call when you need to render iso cube tile.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawIsoCubeTile() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawIsoCubeTile drawn=", ok)

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Call when you need to render hex tile.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawHexTile() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawHexTile drawn=", ok)

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group.
-- Draw commands until flushSortGroup are depth-sortable.
local ok, result = pcall(function() return lurek.render.beginSortGroup(1) end)
if ok then print("lurek.render.beginSortGroup ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Call when you need to invoke push sort key.
local ok, err = pcall(function() lurek.render.pushSortKey(nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.render.pushSortKey done=", ok)

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Call when you need to invoke flush sort group.
local ok, result = pcall(function() return lurek.render.flushSortGroup(1) end)
if ok then print("lurek.render.flushSortGroup ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle with inner fill.
-- Call when you need to render bevel rect.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawBevelRect() end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawBevelRect drawn=", ok)

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer with optional alpha and blend mode.
-- Call when you need to invoke push layer.
local ok, err = pcall(function() lurek.render.pushLayer(1, 1, nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.render.pushLayer done=", ok)

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer back to its parent.
-- Call when you need to invoke pop layer.
local ok, err = pcall(function() lurek.render.popLayer(1) end)
if not ok then print("skipped:", err) end
print("lurek.render.popLayer cleared=", ok)

--@api-stub: lurek.render.drawQuadBezier
-- Must be called inside lurek.render or lurek.render_ui.
-- Call when you need to render quad bezier.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawQuadBezier(nil, nil, nil, nil, nil, nil, nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawQuadBezier drawn=", ok)

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Call when you need to render cubic bezier.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawCubicBezier(nil, nil, nil, nil, nil, nil, nil, nil, nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawCubicBezier drawn=", ok)

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Call when you need to render path.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawPath("path", "fill", nil) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawPath drawn=", ok)

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- Both colors are RGBA tables {r,g,b,a} or positional {[1]=r,[2]=g,[3]=b,[4]=a}.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawGradientRect(0, 0, 100, 100, nil, nil, "dir") end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawGradientRect drawn=", ok)

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Call when you need to render colored polygon.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawColoredPolygon(nil, {1, 1, 1, 1}, "fill") end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawColoredPolygon drawn=", ok)

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- Call when you need to render iso cube tile.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawIsoCubeTile(nil, nil, nil, nil, {}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawIsoCubeTile drawn=", ok)

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Call when you need to render hex tile.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawHexTile(nil, nil, 10, nil, "fill") end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawHexTile drawn=", ok)

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group identified by id.
-- Call when you need to invoke begin sort group.
local ok, result = pcall(function() return lurek.render.beginSortGroup(1) end)
if ok then print("lurek.render.beginSortGroup ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Call when you need to invoke push sort key.
local ok, err = pcall(function() lurek.render.pushSortKey(nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.render.pushSortKey done=", ok)

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Call when you need to invoke flush sort group.
local ok, result = pcall(function() return lurek.render.flushSortGroup(1) end)
if ok then print("lurek.render.flushSortGroup ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle.
-- Call when you need to render bevel rect.
-- Real use: place this call inside your `function lurek.render() ... end` callback.
local ok, err = pcall(function() lurek.render.drawBevelRect(0, 0, 100, 100, nil, nil, {}) end)
if not ok then print("draw skipped (no GPU ctx):", err) end
print("lurek.render.drawBevelRect drawn=", ok)

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer.
-- Provides alpha and blend mode for composite.
local ok, err = pcall(function() lurek.render.pushLayer(1, 1, nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.render.pushLayer done=", ok)

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer.
-- Call when you need to invoke pop layer.
local ok, err = pcall(function() lurek.render.popLayer(1) end)
if not ok then print("skipped:", err) end
print("lurek.render.popLayer cleared=", ok)

--@api-stub: lurek.render.newLayer
-- Registers a named render layer with an optional z-order (default 0).
-- Call when you need to create a new layer.
local ok, obj = pcall(function() return lurek.render.newLayer("name", nil) end)
if ok and obj then print("created:", obj) end
print("lurek.render.newLayer ok=", ok)

--@api-stub: lurek.render.setLayer
-- Sets the active named layer.
-- Draw calls made after this will be.
local ok, err = pcall(function() lurek.render.setLayer("name") end)
if not ok then print("set skipped:", err) end
print("lurek.render.setLayer applied=", ok)

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active named layer.
-- Call when you need to invoke current layer.
local ok, result = pcall(function() return lurek.render.currentLayer() end)
if ok then print("lurek.render.currentLayer ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.render.setLayerVisible
-- Shows or hides the named layer.
-- Hidden layers are excluded from.
local ok, err = pcall(function() lurek.render.setLayerVisible("name", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setLayerVisible applied=", ok)

--@api-stub: lurek.render.isLayerVisible
-- Returns `true` if the named layer is visible (default: `true`).
-- Call when you need to check is layer visible.
local ok, result = pcall(function() return lurek.render.isLayerVisible("name") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.render.isLayerVisible ok=", ok)

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order of the named layer, or `0` if unregistered.
-- Call when you need to read layer z order.
local ok, value = pcall(function() return lurek.render.getLayerZOrder("name") end)
local v = ok and value or "(unavailable)"
print("lurek.render.getLayerZOrder ->", v)

--@api-stub: lurek.render.setLayerZOrder
-- Updates the z-order of the named layer.
-- Auto-creates the layer if.
local ok, err = pcall(function() lurek.render.setLayerZOrder("name", 0) end)
if not ok then print("set skipped:", err) end
print("lurek.render.setLayerZOrder applied=", ok)

-- ── ImageData methods ──

--@api-stub: ImageData:getWidth
-- Returns the pixel width of this image buffer.
-- Call when you need to read width.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("ImageData:getWidth ->", ok, result)
end

--@api-stub: ImageData:getHeight
-- Returns the pixel height of this image buffer.
-- Call when you need to read height.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("ImageData:getHeight ->", ok, result)
end

--@api-stub: ImageData:resize
-- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
-- Call when you need to invoke resize.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:resize(100, 100) end)
  print("ImageData:resize ->", ok, result)
end

--@api-stub: ImageData:diff
-- Returns the sum of absolute per-channel differences between this image and `other`.
-- Call when you need to invoke diff.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:diff(nil) end)
  print("ImageData:diff ->", ok, result)
end

--@api-stub: ImageData:mapPixels
-- Applies a Lua function to every pixel in-place.
-- Call when you need to invoke map pixels.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:mapPixels(function() end) end)
  print("ImageData:mapPixels ->", ok, result)
end

--@api-stub: ImageData:type
-- Returns the type name "ImageData".
-- Call when you need to invoke type.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ImageData:type ->", ok, result)
end

--@api-stub: ImageData:typeOf
-- Returns true when the given name matches "ImageData" or a parent type.
-- Call when you need to invoke type of.
-- Build a ImageData via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImageData(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("ImageData:typeOf ->", ok, result)
end

-- ── NineSlice methods ──

--@api-stub: NineSlice:getInsets
-- Returns the four inset values as (top, right, bottom, left).
-- Call when you need to read insets.
-- Build a NineSlice via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newNineSlice(...)
if instance then
  local ok, result = pcall(function() return instance:getInsets() end)
  print("NineSlice:getInsets ->", ok, result)
end

--@api-stub: NineSlice:getTextureSize
-- Returns the width and height of the source texture.
-- Call when you need to read texture size.
-- Build a NineSlice via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newNineSlice(...)
if instance then
  local ok, result = pcall(function() return instance:getTextureSize() end)
  print("NineSlice:getTextureSize ->", ok, result)
end

--@api-stub: NineSlice:type
-- Returns the type name "NineSlice".
-- Call when you need to invoke type.
-- Build a NineSlice via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newNineSlice(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("NineSlice:type ->", ok, result)
end

--@api-stub: NineSlice:typeOf
-- Returns true when the given name matches "NineSlice" or a parent type.
-- Call when you need to invoke type of.
-- Build a NineSlice via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newNineSlice(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("NineSlice:typeOf ->", ok, result)
end

-- ── Image methods ──

--@api-stub: Image:getWidth
-- Returns the width of this image in pixels.
-- Call when you need to read width.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("Image:getWidth ->", ok, result)
end

--@api-stub: Image:getHeight
-- Returns the height of this image in pixels.
-- Call when you need to read height.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("Image:getHeight ->", ok, result)
end

--@api-stub: Image:getDimensions
-- Returns width and height of this image.
-- Call when you need to read dimensions.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("Image:getDimensions ->", ok, result)
end

--@api-stub: Image:release
-- Releases the GPU texture memory for this image.
-- Call when you need to invoke release.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Image:release ->", ok, result)
end

--@api-stub: Image:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Image:typeOf ->", ok, result)
end

--@api-stub: Image:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Image via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newImage(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Image:type ->", ok, result)
end

-- ── Font methods ──

--@api-stub: Font:getWidth
-- Returns the rendered width of the given text string.
-- Call when you need to read width.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth("hello") end)
  print("Font:getWidth ->", ok, result)
end

--@api-stub: Font:getHeight
-- Returns the line height of this font.
-- Call when you need to read height.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("Font:getHeight ->", ok, result)
end

--@api-stub: Font:getLineHeight
-- Returns the line height multiplier of this font.
-- Call when you need to read line height.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getLineHeight() end)
  print("Font:getLineHeight ->", ok, result)
end

--@api-stub: Font:setLineHeight
-- Sets the line height multiplier for this font.
-- Call when you need to assign line height.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:setLineHeight(100) end)
  print("Font:setLineHeight ->", ok, result)
end

--@api-stub: Font:getAscent
-- Returns the ascent of this font in pixels.
-- Call when you need to read ascent.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getAscent() end)
  print("Font:getAscent ->", ok, result)
end

--@api-stub: Font:getDescent
-- Returns the descent of this font in pixels.
-- Call when you need to read descent.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getDescent() end)
  print("Font:getDescent ->", ok, result)
end

--@api-stub: Font:getWrap
-- Wraps text to the given width and returns the lines.
-- Call when you need to read wrap.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:getWrap("hello", nil) end)
  print("Font:getWrap ->", ok, result)
end

--@api-stub: Font:release
-- Releases this font and frees its atlas memory.
-- Call when you need to invoke release.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Font:release ->", ok, result)
end

--@api-stub: Font:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Font:typeOf ->", ok, result)
end

--@api-stub: Font:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Font via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newFont(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Font:type ->", ok, result)
end

-- ── Canvas methods ──

--@api-stub: Canvas:getWidth
-- Returns the width of this canvas in pixels.
-- Call when you need to read width.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("Canvas:getWidth ->", ok, result)
end

--@api-stub: Canvas:getHeight
-- Returns the height of this canvas in pixels.
-- Call when you need to read height.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("Canvas:getHeight ->", ok, result)
end

--@api-stub: Canvas:getDimensions
-- Returns width and height of this canvas.
-- Call when you need to read dimensions.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("Canvas:getDimensions ->", ok, result)
end

--@api-stub: Canvas:release
-- Releases GPU framebuffer memory for this canvas.
-- Call when you need to invoke release.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Canvas:release ->", ok, result)
end

--@api-stub: Canvas:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Canvas:typeOf ->", ok, result)
end

--@api-stub: Canvas:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Canvas via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newCanvas(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Canvas:type ->", ok, result)
end

-- ── SpriteBatch methods ──

--@api-stub: SpriteBatch:clear
-- Removes all sprites from this batch.
-- Call when you need to invoke clear.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("SpriteBatch:clear ->", ok, result)
end

--@api-stub: SpriteBatch:getCount
-- Returns the number of sprites in this batch.
-- Call when you need to read count.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("SpriteBatch:getCount ->", ok, result)
end

--@api-stub: SpriteBatch:getBufferSize
-- Returns the maximum capacity of this batch.
-- Call when you need to read buffer size.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:getBufferSize() end)
  print("SpriteBatch:getBufferSize ->", ok, result)
end

--@api-stub: SpriteBatch:release
-- Releases this sprite batch.
-- Call when you need to invoke release.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("SpriteBatch:release ->", ok, result)
end

--@api-stub: SpriteBatch:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("SpriteBatch:typeOf ->", ok, result)
end

--@api-stub: SpriteBatch:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a SpriteBatch via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newSpriteBatch(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("SpriteBatch:type ->", ok, result)
end

-- ── Mesh methods ──

--@api-stub: Mesh:getVertexCount
-- Returns the number of vertices in this mesh.
-- Call when you need to read vertex count.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:getVertexCount() end)
  print("Mesh:getVertexCount ->", ok, result)
end

--@api-stub: Mesh:getVertex
-- Returns vertex data at the given 1-based index.
-- Call when you need to read vertex.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:getVertex(1) end)
  print("Mesh:getVertex ->", ok, result)
end

--@api-stub: Mesh:setVertex
-- Sets vertex data at the given 1-based index.
-- Call when you need to assign vertex.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:setVertex(1, {}) end)
  print("Mesh:setVertex ->", ok, result)
end

--@api-stub: Mesh:setTexture
-- Assigns a texture to this mesh.
-- Call when you need to assign texture.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:setTexture(nil) end)
  print("Mesh:setTexture ->", ok, result)
end

--@api-stub: Mesh:release
-- Releases the GPU mesh resource, freeing VRAM immediately.
-- Call when you need to invoke release.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Mesh:release ->", ok, result)
end

--@api-stub: Mesh:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Mesh:typeOf ->", ok, result)
end

--@api-stub: Mesh:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Mesh via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newMesh(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Mesh:type ->", ok, result)
end

-- ── Shader methods ──

--@api-stub: Shader:send
-- Sends a uniform value to this shader.
-- Call when you need to invoke send.
-- Build a Shader via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShader(...)
if instance then
  local ok, result = pcall(function() return instance:send("name", nil) end)
  print("Shader:send ->", ok, result)
end

--@api-stub: Shader:hasUniform
-- Returns whether this shader has a uniform with the given name.
-- Call when you need to check has uniform.
-- Build a Shader via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShader(...)
if instance then
  local ok, result = pcall(function() return instance:hasUniform("name") end)
  print("Shader:hasUniform ->", ok, result)
end

--@api-stub: Shader:release
-- Releases the compiled GPU shader, freeing VRAM and shader slots.
-- Call when you need to invoke release.
-- Build a Shader via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShader(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Shader:release ->", ok, result)
end

--@api-stub: Shader:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Shader via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShader(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Shader:typeOf ->", ok, result)
end

--@api-stub: Shader:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Shader via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShader(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Shader:type ->", ok, result)
end

-- ── Quad methods ──

--@api-stub: Quad:getViewport
-- Returns the quad viewport rectangle.
-- Call when you need to read viewport.
-- Build a Quad via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newQuad(...)
if instance then
  local ok, result = pcall(function() return instance:getViewport() end)
  print("Quad:getViewport ->", ok, result)
end

--@api-stub: Quad:getTextureDimensions
-- Returns the reference texture dimensions.
-- Call when you need to read texture dimensions.
-- Build a Quad via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newQuad(...)
if instance then
  local ok, result = pcall(function() return instance:getTextureDimensions() end)
  print("Quad:getTextureDimensions ->", ok, result)
end

--@api-stub: Quad:typeOf
-- Returns the type name of this object.
-- Call when you need to invoke type of.
-- Build a Quad via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newQuad(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf() end)
  print("Quad:typeOf ->", ok, result)
end

--@api-stub: Quad:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Quad via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newQuad(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Quad:type ->", ok, result)
end

-- ── Shape methods ──

--@api-stub: Shape:getCommandCount
-- Returns the number of drawing commands currently stored.
-- Call when you need to read command count.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:getCommandCount() end)
  print("Shape:getCommandCount ->", ok, result)
end

--@api-stub: Shape:clear
-- Removes all commands and resets the shape to empty.
-- Call when you need to invoke clear.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Shape:clear ->", ok, result)
end

--@api-stub: Shape:setLineWidth
-- Sets the stroke width for subsequent outlined primitives.
-- Call when you need to assign line width.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:setLineWidth(100) end)
  print("Shape:setLineWidth ->", ok, result)
end

--@api-stub: Shape:line
-- Queues a line segment command.
-- Call when you need to invoke line.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:line(nil, nil, nil, nil) end)
  print("Shape:line ->", ok, result)
end

--@api-stub: Shape:polyline
-- Queues a polyline command from variadic (x, y) coordinate pairs.
-- Call when you need to invoke polyline.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:polyline() end)
  print("Shape:polyline ->", ok, result)
end

--@api-stub: Shape:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Call when you need to invoke type of.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Shape:typeOf ->", ok, result)
end

--@api-stub: Shape:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Shape via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newShape(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Shape:type ->", ok, result)
end

-- ── DrawLayer methods ──

--@api-stub: DrawLayer:queue
-- Queues a draw callback at the given z-order.
-- Call when you need to invoke queue.
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:queue(0, nil) end)
  print("DrawLayer:queue ->", ok, result)
end

--@api-stub: DrawLayer:flush
-- Sorts and calls all queued callbacks, then empties the queue.
-- Call when you need to invoke flush.
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("DrawLayer:flush ->", ok, result)
end

--@api-stub: DrawLayer:clear
-- Removes all queued callbacks without calling them.
-- Call when you need to invoke clear.
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("DrawLayer:clear ->", ok, result)
end

--@api-stub: DrawLayer:getCount
-- Returns the number of queued callbacks.
-- Call when you need to read count.
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("DrawLayer:getCount ->", ok, result)
end

--@api-stub: DrawLayer:type
-- Returns the string type identifier of this draw layer (e.g.
-- `'sprite'`).
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("DrawLayer:type ->", ok, result)
end

--@api-stub: DrawLayer:typeOf
-- Returns true if this object is an instance of the given type name.
-- Call when you need to invoke type of.
-- Build a DrawLayer via the appropriate lurek.render.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.render.newDrawLayer(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("DrawLayer:typeOf ->", ok, result)
end

