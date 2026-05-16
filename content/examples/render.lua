-- content/examples/render.lua
-- lurek.render API examples.
-- Run: cargo run -- content/examples/render.lua

--@api-stub: lurek.render.setColor
-- Sets the active drawing color for all subsequent draw operations
do
  lurek.render.setColor(1.0, 0.5, 0.2, 1.0)  -- warm orange
  function lurek.draw()
    lurek.render.setColor(1, 0.5, 0.2, 1)
    lurek.render.rectangle('fill', 10, 10, 64, 32)
  end
end

--@api-stub: lurek.render.getColor
-- Returns the current drawing color
do
  function lurek.draw()
    local r, g, b, a = lurek.render.getColor()
    lurek.render.setColor(r, g, b, a * 0.5); lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.setColor(r, g, b, a)
  end
end

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color used at the start of each frame
do
  function lurek.init() lurek.render.setBackgroundColor(0.05, 0.07, 0.10) end
end

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background clear color
do
  local r, g, b, a = lurek.render.getBackgroundColor()
  if r + g + b < 1.0 then lurek.log.info('dark theme detected') end
end

--@api-stub: lurek.render.rectangle
-- Draws a rectangle
do
  function lurek.draw()
    lurek.render.rectangle('fill', 32, 32, 128, 64, 8, 8)
    lurek.render.rectangle('line', 32, 32, 128, 64, 8, 8)
  end
end

--@api-stub: lurek.render.circle
-- Draws a circle
do
  function lurek.draw()
    lurek.render.setColor(0.2, 0.9, 0.4, 1)
    lurek.render.circle('fill', 200, 150, 24)
  end
end

--@api-stub: lurek.render.ellipse
-- Draws an ellipse
do
  function lurek.draw()
    lurek.render.ellipse('fill', 200, 200, 60, 20)  -- ground shadow
  end
end

--@api-stub: lurek.render.triangle
-- Draws a triangle from three vertex positions
do
  function lurek.draw()
    lurek.render.triangle('fill', 100, 50, 80, 100, 120, 100)
  end
end

--@api-stub: lurek.render.line
-- Draws a line between two points, or a polyline through multiple points
do
  function lurek.draw()
    lurek.render.setLineWidth(2)
    lurek.render.line(0, 0, 100, 50, 200, 30, 300, 80)
  end
end

--@api-stub: lurek.render.polygon
-- Draws a polygon from a flat list of x,y vertex coordinates
do
  function lurek.draw()
    lurek.render.polygon('fill', 100, 100, 150, 80, 200, 120, 170, 170, 120, 160)
  end
end

--@api-stub: lurek.render.arc
-- Draws a circular arc
do
  function lurek.draw()
    lurek.render.arc('line', 200, 200, 50, 0, math.pi * 1.5)
  end
end

--@api-stub: lurek.render.points
-- Draws one or more points
do
  function lurek.draw()
    lurek.render.setPointSize(3)
    lurek.render.points(10, 10, 20, 15, 30, 25, 40, 12)
  end
end

--@api-stub: lurek.render.draw
-- Draws a drawable object (Image, Canvas, SpriteBatch, or Mesh) at the given position with optional transform
do
  local img
  function lurek.init() img = lurek.render.newImage('img/player.png') end
  function lurek.draw() lurek.render.draw(img, 100, 100, 0, 1, 1) end
end

--@api-stub: lurek.render.drawq
-- Draws a sub-region of an image defined by a Quad, with optional transform
do
  local sheet, frame
  function lurek.init()
    sheet = lurek.render.newImage('img/sheet.png')
    frame = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
  end
  function lurek.draw() lurek.render.drawq(sheet, frame, 50, 50) end
end

--@api-stub: lurek.render.print
-- Draws text using the active font at the given position
do
  function lurek.draw() lurek.render.print('SCORE: ' .. 1234, 10, 10) end
end

--@api-stub: lurek.render.printf
-- Draws word-wrapped and aligned text within a pixel-width limit
do
  function lurek.draw()
    lurek.render.printf('Welcome to Lurek2D! This text wraps inside the box.', 20, 40, 200, 'left')
  end
end

--@api-stub: lurek.render.printRich
-- Draws rich text composed of individually styled spans at the given position
do
  function lurek.draw()
    lurek.render.printRich({{text='HP', r=255, g=0, b=0, a=255}, {text=': 12 / ', r=255, g=255, b=255, a=255}, {text='20', r=0, g=255, b=0, a=255}}, 10, 30)
  end
end

--@api-stub: lurek.render.clear
-- Clears all queued render commands for the current frame
do
  function lurek.draw() lurek.render.clear(0.0, 0.0, 0.05) end
end

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for subsequent line-mode draw calls
do
  function lurek.draw()
    lurek.render.setLineWidth(4)
    lurek.render.rectangle('line', 50, 50, 100, 60)
    lurek.render.setLineWidth(1)
  end
end

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width
do
  local prev = lurek.render.getLineWidth()
  lurek.log.debug('line width: ' .. tostring(prev))
end

--@api-stub: lurek.render.setPointSize
-- Sets the point size for subsequent point draw calls
do
  function lurek.draw()
    lurek.render.setPointSize(2)
    lurek.render.points(100, 100, 110, 100, 120, 100)
  end
end

--@api-stub: lurek.render.getPointSize
-- Returns the current point size
do
  local sz = lurek.render.getPointSize()
  if sz < 2 then lurek.render.setPointSize(2) end
end

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for subsequent draw operations
do
  function lurek.draw()
    lurek.render.setBlendMode('add')
    lurek.render.circle('fill', 200, 200, 50)
    lurek.render.setBlendMode('alpha')
  end
end

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode name
do
  local mode = lurek.render.getBlendMode()
  if mode ~= 'add' then lurek.render.setBlendMode('add') end
end

--@api-stub: lurek.render.newFont
-- Creates a new bitmap font from a PNG sprite sheet path or returns a built-in font by pixel height
do
  local hud_font
  function lurek.init() hud_font = lurek.render.newFont('assets/fonts/Inter.ttf', 18) end
end

--@api-stub: lurek.render.setFont
-- Sets the active font used by print, printf, and other text rendering calls
do
  local title_font
  function lurek.init() title_font = lurek.render.newFont('assets/fonts/Inter.ttf', 32) end
  function lurek.draw() lurek.render.setFont(title_font); lurek.render.print('LUREK', 100, 20) end
end

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil if none is set
do
  local prev = lurek.render.getFont()
  if prev then lurek.log.debug('font height ' .. tostring(prev:getHeight())) end
end

--@api-stub: lurek.render.getFontSizes
-- Returns all available built-in font pixel heights
do
  local sizes = lurek.render.getFontSizes()
  for _, sz in ipairs(sizes or {}) do lurek.log.debug('cached size ' .. sz) end
end

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in default font at the nearest available pixel height
do
  pcall(function()
    local fallback = lurek.render.getDefaultFont()
    lurek.render.setFont(fallback)
  end)
end

--@api-stub: lurek.render.getFontCellWidth
-- Returns the fixed cell width of a bitmap font
do
  pcall(function()
    local cw = lurek.render.getFontCellWidth(lurek.render.getDefaultFont())
    lurek.log.debug('hud cell width: ' .. tostring(cw))
  end)
end

--@api-stub: lurek.render.getFontWidth
-- Measures the pixel width of text using the given font
do
  pcall(function()
    local label = 'Press SPACE to start'
    local f = lurek.render.getDefaultFont()
    local w = lurek.render.getFontWidth(f, label)
    function lurek.draw() lurek.render.print(label, (800 - w) / 2, 300) end
  end)
end

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font
do
  pcall(function()
    local lh = lurek.render.getFontHeight(lurek.render.getDefaultFont())
    function lurek.draw()
      lurek.render.print('line 1', 10, 10)
      lurek.render.print('line 2', 10, 10 + lh)
    end
  end)
end

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line spacing of the given font
do
  pcall(function()
    local mult = lurek.render.getFontLineHeight(lurek.render.getDefaultFont())
    lurek.log.debug('line height multiplier: ' .. tostring(mult))
  end)
end

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height override for a font (currently a no-op stub)
do
  pcall(function()
    lurek.render.setFontLineHeight(lurek.render.getDefaultFont(), 1.25)
  end)
end

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent (pixels above baseline) of the given font
do
  pcall(function()
    local asc = lurek.render.getFontAscent(lurek.render.getDefaultFont())
    lurek.log.debug('ascent ' .. tostring(asc))
  end)
end

--@api-stub: lurek.render.getFontDescent
-- Returns the descent (pixels below baseline) of the given font
do
  pcall(function()
    local desc = lurek.render.getFontDescent(lurek.render.getDefaultFont())
    lurek.log.debug('descent ' .. tostring(desc))
  end)
end

--@api-stub: lurek.render.getFontWrap
-- Word-wraps text using the active font and returns the resulting lines and widest line width
do
  pcall(function()
    local lines, w = lurek.render.getFontWrap('A long sentence that wraps when laid out.', 120)
    lurek.log.debug('wrapped to ' .. tostring(#lines) .. ' lines')
  end)
end

--@api-stub: lurek.render.newImage
-- Loads a texture from a file path or creates one from an ImageData object
do
  local hero
  function lurek.init() hero = lurek.render.newImage('img/hero.png') end
end

--@api-stub: lurek.render.newCanvas
-- Creates a new off-screen render target with the given dimensions
do
  local rt
  function lurek.init() rt = lurek.render.newCanvas(320, 240) end
end

--@api-stub: lurek.render.setCanvas
-- Redirects all subsequent drawing to the given canvas
do
  local rt
  function lurek.init() rt = lurek.render.newCanvas(320, 240) end
  function lurek.draw()
    lurek.render.setCanvas(rt); lurek.render.clear(0, 0, 0); lurek.render.rectangle('fill', 10, 10, 50, 50)
    lurek.render.setCanvas(); lurek.render.draw(rt, 0, 0)
  end
end

--@api-stub: lurek.render.getCanvas
-- Returns the currently active canvas, or nil if drawing to the screen
do
  if lurek.render.getCanvas() == nil then lurek.log.debug('rendering to screen') end
end

--@api-stub: lurek.render.getCanvasSize
-- Returns the pixel dimensions of a canvas
do
  pcall(function()
    local c = lurek.render.newCanvas(320, 240)
    local w, h = lurek.render.getCanvasSize(c)
    lurek.log.debug('canvas dim ' .. w .. 'x' .. h)
  end)
end

--@api-stub: lurek.render.newSpriteBatch
-- Creates a batched sprite renderer for efficiently drawing many copies of the same texture
do
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 1024) end
end

--@api-stub: lurek.render.newMesh
-- Creates a custom vertex mesh from an array of vertex data tables
do
  local mesh
  function lurek.init()
    mesh = lurek.render.newMesh({ {0, 0, 0, 0, 1, 1, 1, 1}, {64, 0, 1, 0, 1, 1, 1, 1}, {32, 64, 0.5, 1, 1, 1, 1, 1} })
  end
end

--@api-stub: lurek.render.newShader
-- Compiles a WGSL shader program from source code and returns a handle
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader([[ @fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); } ]])
  end
end

--@api-stub: lurek.render.setShader
-- Activates a shader for subsequent draw calls
do
  local sh
  function lurek.init() sh = lurek.render.newShader('// trivial fragment shader') end
  function lurek.draw()
    lurek.render.setShader(sh)
    lurek.render.rectangle('fill', 0, 0, 64, 64)
    lurek.render.setShader()
  end
end

--@api-stub: lurek.render.getShader
-- Returns the currently active shader, or nil if using the default
do
  local prev = lurek.render.getShader()
  if prev == nil then lurek.log.debug('default shader bound') end
end

--@api-stub: lurek.render.newQuad
-- Creates a Quad defining a rectangular sub-region of a texture for sprite-sheet rendering
do
  local sheet, q
  function lurek.init()
    sheet = lurek.render.newImage('img/sheet.png')
    q = lurek.render.newQuad(32, 0, 32, 32, sheet:getWidth(), sheet:getHeight())
  end
end

--@api-stub: lurek.render.push
-- Pushes the current transformation matrix onto the transform stack
do
  function lurek.draw()
    lurek.render.push(); lurek.render.translate(100, 100); lurek.render.rotate(0.5)
    lurek.render.rectangle('fill', -16, -16, 32, 32)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.pop
-- Pops the top transformation matrix from the transform stack, restoring the previous one
do
  function lurek.draw()
    lurek.render.push()
    lurek.render.scale(2, 2)
    lurek.render.print('big', 0, 0)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.translate
-- Applies a translation to the current transformation matrix
do
  function lurek.draw()
    lurek.render.push()
    lurek.render.translate(50, 80)
    lurek.render.circle('fill', 0, 0, 8)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.rotate
-- Applies a rotation to the current transformation matrix
do
  function lurek.draw()
    lurek.render.push(); lurek.render.translate(200, 200); lurek.render.rotate(math.pi / 6)
    lurek.render.rectangle('fill', -20, -20, 40, 40); lurek.render.pop()
  end
end

--@api-stub: lurek.render.scale
-- Applies scaling to the current transformation matrix
do
  function lurek.draw()
    lurek.render.push()
    lurek.render.scale(1.5, 1.5)
    lurek.render.print('zoom', 100, 100)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.shear
-- Applies a shear (skew) to the current transformation matrix
do
  function lurek.draw()
    lurek.render.push()
    lurek.render.shear(0.2, 0)
    lurek.render.rectangle('fill', 80, 80, 40, 40)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.origin
-- Resets the current transformation matrix to the identity (no transform)
do
  function lurek.draw() lurek.render.origin(); lurek.render.print('UI overlay', 8, 8) end
end

--@api-stub: lurek.render.applyTransform
-- Multiplies the current transformation matrix by a 3x3 matrix (9 values in row-major order)
do
  local t = { sx = 1.5, sy = 1.5, ox = 100, oy = 100, rot = 0.0 }
  function lurek.draw()
    lurek.render.push()
    lurek.render.applyTransform(t)
    lurek.render.rectangle('fill', 0, 0, 20, 20)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.setScissor
-- Sets or clears the scissor rectangle
do
  function lurek.draw()
    lurek.render.setScissor(40, 40, 200, 100)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setScissor()
  end
end

--@api-stub: lurek.render.getScissor
-- Returns the current scissor rectangle, or nothing if no scissor is set
do
  local x, y, w, h = lurek.render.getScissor()
  if x then lurek.log.debug('scissor at ' .. x .. ',' .. y) end
end

--@api-stub: lurek.render.intersectScissor
-- Intersects the given rectangle with the current scissor, narrowing the drawable region
do
  function lurek.draw()
    lurek.render.setScissor(0, 0, 400, 300)
    lurek.render.intersectScissor(100, 100, 200, 100)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setScissor()
  end
end

--@api-stub: lurek.render.setColorMask
-- Sets which color channels are written during draw calls
do
  function lurek.draw()
    lurek.render.setColorMask(true, false, false, true)
    lurek.render.rectangle('fill', 0, 0, 64, 64)
    lurek.render.setColorMask(true, true, true, true)
  end
end

--@api-stub: lurek.render.getColorMask
-- Returns the current color write mask
do
  local r, g, b, a = lurek.render.getColorMask()
  lurek.log.debug('mask r=' .. tostring(r) .. ' a=' .. tostring(a))
end

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering mode
do
  function lurek.init() lurek.render.setWireframe(true) end
end

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe rendering is currently active
do
  if lurek.render.isWireframe() then lurek.log.warn('wireframe debug enabled') end
end

--@api-stub: lurek.render.stencil
-- Begins a stencil write pass with the given action and reference value
do
  function lurek.draw()
    lurek.render.stencil('replace', 1); lurek.render.circle('fill', 200, 200, 80)
    lurek.render.setStencilTest('greater', 0)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setStencilTest()
  end
end

--@api-stub: lurek.render.setStencilTest
-- Configures the stencil comparison test for subsequent draws
do
  function lurek.draw()
    lurek.render.setStencilTest('equal', 1)
    lurek.render.rectangle('fill', 0, 0, 64, 64)
    lurek.render.setStencilTest()
  end
end

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil write action, compare function, and reference value at once
do
  function lurek.draw()
    lurek.render.setStencilMode('replace', 'always', 1)
    lurek.render.circle('fill', 100, 100, 30)
  end
end

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil action, compare mode, and reference value
do
  local action, compare, value = lurek.render.getStencilMode()
  lurek.log.debug('stencil ' .. tostring(action) .. ' ' .. tostring(compare))
end

--@api-stub: lurek.render.clearStencil
-- Resets the stencil state to defaults (no stencil operations)
do
  function lurek.draw()
    lurek.render.clearStencil()
    lurek.render.stencil('replace', 1)
    lurek.render.rectangle('fill', 0, 0, 64, 64)
  end
end

--@api-stub: lurek.render.setDepthMode
-- Sets the depth comparison mode and whether depth writes are enabled
do
  function lurek.init() lurek.render.setDepthMode('less', true) end
end

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth comparison mode and write-enable flag
do
  local cmp, write = lurek.render.getDepthMode()
  lurek.log.debug('depth: ' .. tostring(cmp) .. ' write=' .. tostring(write))
end

--@api-stub: lurek.render.getWidth
-- Returns the current window width in pixels
do
  local w = lurek.render.getWidth()
  lurek.log.info('screen width: ' .. tostring(w))
end

--@api-stub: lurek.render.getHeight
-- Returns the current window height in pixels
do
  local h = lurek.render.getHeight()
  lurek.log.info('screen height: ' .. tostring(h))
end

--@api-stub: lurek.render.getDimensions
-- Returns the current window width and height
do
  local w, h = lurek.render.getDimensions()
  function lurek.draw() lurek.render.print('center', w / 2, h / 2) end
end

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filtering mode for newly created images
do
  function lurek.init() lurek.render.setDefaultFilter('nearest', 'nearest') end
end

--@api-stub: lurek.render.getDefaultFilter
-- Returns the current default texture filtering settings
do
  local mn, mg = lurek.render.getDefaultFilter()
  lurek.log.debug('filters min=' .. mn .. ' mag=' .. mg)
end

--@api-stub: lurek.render.getStats
-- Returns a table of rendering statistics for the current frame
do
  local s = lurek.render.getStats()
  lurek.log.info('drawcalls=' .. tostring(s.drawcalls) .. ' batched=' .. tostring(s.batched_draws))
end

--@api-stub: lurek.render.saveScreenshot
-- Saves a screenshot of the current frame to a file under the save/ directory
do
  function lurek.init() lurek.render.saveScreenshot('screenshots/title.png') end
end

--@api-stub: lurek.render.captureScreenshot
-- Captures a screenshot as ImageData and passes it to a callback (stub: returns 1x1 placeholder)
do
  function lurek.init()
    local data = screenshot()
    if data then lurek.log.info('captured ' .. data:getWidth() .. 'x' .. data:getHeight()) end
  end
end

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice definition from an image and four border insets for scalable UI rendering
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
end

--@api-stub: lurek.render.drawNineSlice
-- Draws a 9-slice image stretched to fill the given rectangle, keeping borders unscaled
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
  function lurek.draw() if panel then lurek.render.drawNineSlice(panel, 50, 50, 200, 120) end end
end

--@api-stub: lurek.render.newShape
-- Creates a new retained compound shape for accumulating draw commands
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 50, 50); s:polyline(50, 50, 100, 0, 100, 80)
  end
end

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw layer for sorting draw callbacks by depth
do
  local layer
  function lurek.init() layer = lurek.render.newDrawLayer() end
  function lurek.draw() layer:queue('rect', 10, 10, 50, 50); layer:flush() end
end

--@api-stub: lurek.render.drawQuadBezier
-- Draws a quadratic Bezier curve through start, control, and end points
do
  function lurek.draw()
    lurek.render.drawQuadBezier(50, 200, 150, 50, 250, 200, 32)
  end
end

--@api-stub: lurek.render.drawCubicBezier
-- Draws a cubic Bezier curve through start, two control points, and end
do
  function lurek.draw()
    lurek.render.drawCubicBezier(50, 200, 100, 50, 200, 50, 250, 200, 48)
  end
end

--@api-stub: lurek.render.drawPath
-- Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments
do
  function lurek.draw()
    lurek.render.drawPath({100, 100, 150, 80, 200, 120, 180, 170}, "line", false)
  end
end

--@api-stub: lurek.render.drawGradientRect
-- Draws a rectangle with a two-color gradient fill
do
  function lurek.draw()
    lurek.render.drawGradientRect(0, 0, 800, 600, {0.05, 0.05, 0.10, 1}, {0.20, 0.10, 0.30, 1}, 'vertical')
  end
end

--@api-stub: lurek.render.drawColoredPolygon
-- Draws a polygon with per-vertex colors
do
  function lurek.draw()
    lurek.render.drawColoredPolygon({100, 100, 200, 100, 150, 200}, {{1,0,0,1}, {0,1,0,1}, {0,0,1,1}})
  end
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Draws an isometric cube tile with configurable face colors and optional textures
do
  function lurek.draw()
    lurek.render.drawIsoCubeTile(200, 200, 16, 9, {topColor={0.6,0.7,0.5,1}, leftColor={0.4,0.5,0.3,1}, rightColor={0.5,0.6,0.4,1}})
  end
end

--@api-stub: lurek.render.drawHexTile
-- Draws a regular hexagonal tile
do
  function lurek.draw()
    lurek.render.setColor(0.3, 0.5, 0.8, 1); lurek.render.drawHexTile(200, 200, 32)
  end
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a depth-sorted rendering group
do
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(10); lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.pushSortKey(5);  lurek.render.rectangle('fill', 16, 16, 32, 32)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.pushSortKey
-- Sets the depth sort key for subsequent draw calls within the current sort group
do
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(2); lurek.render.circle('fill', 100, 100, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.flushSortGroup
-- Ends a sort group and emits all accumulated draw calls in sorted order
do
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(0); lurek.render.rectangle('fill', 0, 0, 16, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.drawBevelRect
-- Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements
do
  function lurek.draw()
    lurek.render.drawBevelRect(50, 50, 200, 80, 8)
  end
end

--@api-stub: lurek.render.pushLayer
-- Begins a compositing layer with the given alpha and blend mode
do
  function lurek.draw()
    lurek.render.pushLayer(1)
    lurek.render.print('HP 100', 10, 10)
    lurek.render.popLayer(1)
  end
end

--@api-stub: lurek.render.popLayer
-- Ends a compositing layer and composites it with the previous content
do
  function lurek.draw()
    lurek.render.pushLayer(2)
    lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.popLayer(2)
  end
end

end


--@api-stub: lurek.render.newLayer
-- Creates a named rendering layer with an optional z-order for draw call organization
do
  function lurek.init()
    lurek.render.newLayer('background', -10)
    lurek.render.newLayer('hud', 100)
  end
end

--@api-stub: lurek.render.setLayer
-- Sets the active rendering layer by name
do
  function lurek.draw() lurek.render.setLayer('hud'); lurek.render.print('layer text', 8, 8) end
end

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active rendering layer
do
  local cur = lurek.render.currentLayer()
  lurek.log.debug('layer: ' .. tostring(cur))
end

--@api-stub: lurek.render.setLayerVisible
-- Sets whether a named rendering layer is visible
do
  function lurek.init() lurek.render.setLayerVisible('debug', false) end
end

--@api-stub: lurek.render.isLayerVisible
-- Returns whether a named rendering layer is currently visible
do
  if lurek.render.isLayerVisible('hud') then lurek.log.debug('hud visible') end
end

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order value of a named rendering layer
do
  local z = lurek.render.getLayerZOrder('hud')
  lurek.log.debug('hud z=' .. tostring(z))
end

--@api-stub: lurek.render.setLayerZOrder
-- Sets the z-order value of a named rendering layer
do
  function lurek.init() lurek.render.setLayerZOrder('pause_overlay', 1000) end
end

-- ImageData methods

--@api-stub: ImageData:getWidth
-- Returns the width of this image data.
do
  local data = screenshot() or { getWidth = function() return 0 end, getHeight = function() return 0 end }
  lurek.log.debug('width=' .. tostring(data:getWidth()))
end

--@api-stub: ImageData:getHeight
-- Returns the height of this image data.
do
  local data = screenshot() or { getHeight = function() return 0 end }
  lurek.log.debug('height=' .. tostring(data:getHeight()))
end

--@api-stub: ImageData:resize
-- Performs the resize operation on this image data.
do
  local data = screenshot()
  if data then data:resize(64, 64); lurek.log.info('resized to 64x64') end
end

--@api-stub: ImageData:diff
-- Performs the diff operation on this image data.
do
  local a = screenshot()
  local b = screenshot()
  if a and b then lurek.log.debug('diff=' .. tostring(a:diff(b))) end
end

--@api-stub: ImageData:mapPixels
-- Performs the map pixels operation on this image data.
do
  local data = screenshot()
  if data then data:mapPixels(function(x, y, r, g, b, a) return 1 - r, 1 - g, 1 - b, a end) end
end

-- NineSlice methods

--@api-stub: NineSlice:getInsets
-- Returns the insets of this nine slice.
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then local l, t, r, b = panel:getInsets(); lurek.log.debug('insets ' .. l .. ',' .. t .. ',' .. r .. ',' .. b) end
  end
end

--@api-stub: NineSlice:getTextureSize
-- Returns the texture size of this nine slice.
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then local w, h = panel:getTextureSize(); lurek.log.debug('panel src ' .. w .. 'x' .. h) end
  end
end

--@api-stub: NineSlice:type
-- Returns the Lua-visible type name string for this nine slice handle.
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then lurek.log.debug(panel:type()) end
  end
end

--@api-stub: NineSlice:typeOf
-- Returns true if this nine slice handle matches the given type name string.
do
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel and panel:typeOf('NineSlice') then lurek.log.debug('ok') end
  end
end

-- Image methods

--@api-stub: Image:getWidth
-- Returns the width of this image.
do
  local img
  function lurek.init()
    img = lurek.render.newImage('img/hero.png')
    lurek.log.debug('w=' .. img:getWidth())
  end
end

--@api-stub: Image:getHeight
-- Returns the height of this image.
do
  local img
  function lurek.init()
    img = lurek.render.newImage('img/hero.png')
    lurek.log.debug('h=' .. img:getHeight())
  end
end

--@api-stub: Image:getDimensions
-- Returns the dimensions of this image.
do
  local img
  function lurek.init()
    img = lurek.render.newImage('img/hero.png')
    local w, h = img:getDimensions()
    lurek.log.debug(w .. 'x' .. h)
  end
end

--@api-stub: Image:release
-- Performs the release operation on this image.
do
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png') end
  function lurek.quit() if img then img:release() end end
end

--@api-stub: Image:typeOf
-- Returns true if this image handle matches the given type name string.
do
  local img
  function lurek.init()
    img = lurek.render.newImage('img/hero.png')
    if img:typeOf() == 'Image' then lurek.log.debug('image') end
  end
end

--@api-stub: Image:type
-- Returns the Lua-visible type name string for this image handle.
do
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); lurek.log.debug(img:type()) end
end

-- Font methods

--@api-stub: Font:getWidth
-- Returns the width of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug('w=' .. f:getWidth('Hello'))
  end
end

--@api-stub: Font:getHeight
-- Returns the height of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug('h=' .. f:getHeight())
  end
end

--@api-stub: Font:getLineHeight
-- Returns the line height of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug('lh=' .. f:getLineHeight())
  end
end

--@api-stub: Font:setLineHeight
-- Sets the line height of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    f:setLineHeight(1.25)
  end
end

--@api-stub: Font:getAscent
-- Returns the ascent of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug('asc=' .. tostring(f:getAscent()))
  end
end

--@api-stub: Font:getDescent
-- Returns the descent of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug('desc=' .. tostring(f:getDescent()))
  end
end

--@api-stub: Font:getWrap
-- Returns the wrap of this font.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 14)
    local lines, w = f:getWrap('A long sentence to wrap.', 80); lurek.log.debug('lines=' .. #lines)
  end
end

--@api-stub: Font:release
-- Performs the release operation on this font.
do
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18) end
  function lurek.quit() if f then f:release() end end
end

--@api-stub: Font:typeOf
-- Returns true if this font handle matches the given type name string.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    if f:typeOf() == 'Font' then lurek.log.debug('font') end
  end
end

--@api-stub: Font:type
-- Returns the Lua-visible type name string for this font handle.
do
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 18)
    lurek.log.debug(f:type())
  end
end

-- Canvas methods

--@api-stub: Canvas:getWidth
-- Returns the width of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    lurek.log.debug('cw=' .. c:getWidth())
  end
end

--@api-stub: Canvas:getHeight
-- Returns the height of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    lurek.log.debug('ch=' .. c:getHeight())
  end
end

--@api-stub: Canvas:getDimensions
-- Returns the dimensions of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    local w, h = c:getDimensions()
    lurek.log.debug(w .. 'x' .. h)
  end
end

--@api-stub: Canvas:release
-- Performs the release operation on this canvas.
do
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240) end
  function lurek.quit() if c then c:release() end end
end

--@api-stub: Canvas:typeOf
-- Returns true if this canvas handle matches the given type name string.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    if c:typeOf() == 'Canvas' then lurek.log.debug('canvas') end
  end
end

--@api-stub: Canvas:type
-- Returns the Lua-visible type name string for this canvas handle.
do
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); lurek.log.debug(c:type()) end
end

-- SpriteBatch methods

--@api-stub: SpriteBatch:clear
-- Clears all items from this sprite batch.
do
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 1024) end
  function lurek.process(dt) batch:clear() end
end

--@api-stub: SpriteBatch:getCount
-- Returns the total count of items held by this sprite batch.
do
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256) end
  function lurek.draw() lurek.log.debug('batched=' .. batch:getCount()) end
end

--@api-stub: SpriteBatch:getBufferSize
-- Returns the buffer size of this sprite batch.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256)
    lurek.log.debug('cap=' .. batch:getBufferSize())
  end
end

--@api-stub: SpriteBatch:release
-- Performs the release operation on this sprite batch.
do
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256) end
  function lurek.quit() if batch then batch:release() end end
end

--@api-stub: SpriteBatch:typeOf
-- Returns true if this sprite batch handle matches the given type name string.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 64)
    if batch:typeOf() == 'SpriteBatch' then lurek.log.debug('batch') end
  end
end

--@api-stub: SpriteBatch:type
-- Returns the Lua-visible type name string for this sprite batch handle.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 64)
    lurek.log.debug(batch:type())
  end
end

-- Mesh methods

--@api-stub: Mesh:getVertexCount
-- Returns the number of vertex items in this mesh.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} })
    lurek.log.debug('verts=' .. m:getVertexCount())
  end
end

--@api-stub: Mesh:getVertex
-- Returns the vertex of this mesh.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} })
    local v = m:getVertex(1); if v then lurek.log.debug('v0.x=' .. tostring(v[1])) end
  end
end

--@api-stub: Mesh:setVertex
-- Sets the vertex of this mesh.
do
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }) end
  function lurek.process(dt) if m then m:setVertex(1, {0, 0, 0, 0, 1, 1, 1, 1}) end end
end

--@api-stub: Mesh:setTexture
-- Sets the texture of this mesh.
do
  local m, tex
  function lurek.init()
    tex = lurek.render.newImage('img/sheet.png')
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }); m:setTexture(tex)
  end
end

--@api-stub: Mesh:release
-- Performs the release operation on this mesh.
do
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }) end
  function lurek.quit() if m then m:release() end end
end

--@api-stub: Mesh:typeOf
-- Returns true if this mesh handle matches the given type name string.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} })
    if m:typeOf() == 'Mesh' then lurek.log.debug('mesh') end
  end
end

--@api-stub: Mesh:type
-- Returns the Lua-visible type name string for this mesh handle.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} })
    lurek.log.debug(m:type())
  end
end

-- Shader methods

--@api-stub: Shader:send
-- Sends to the target associated with this shader.
do
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source') end
  function lurek.process(dt) if sh then sh:send('time', lurek.time and lurek.time.getTime() or 0.0) end end
end

--@api-stub: Shader:hasUniform
-- Returns true if this shader has a uniform.
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader('// shader source')
    if sh:hasUniform('time') then sh:send('time', 0.0) end
  end
end

--@api-stub: Shader:release
-- Performs the release operation on this shader.
do
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source') end
  function lurek.quit() if sh then sh:release() end end
end

--@api-stub: Shader:typeOf
-- Returns true if this shader handle matches the given type name string.
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader('// shader source')
    if sh:typeOf() == 'Shader' then lurek.log.debug('shader') end
  end
end

--@api-stub: Shader:type
-- Returns the Lua-visible type name string for this shader handle.
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader('// shader source')
    lurek.log.debug(sh:type())
  end
end

-- Quad methods

--@api-stub: Quad:getViewport
-- Returns the viewport of this quad.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    local x, y, w, h = q:getViewport()
    lurek.log.debug(x .. ',' .. y .. ',' .. w .. ',' .. h)
  end
end

--@api-stub: Quad:getTextureDimensions
-- Returns the texture dimensions of this quad.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    local sw, sh = q:getTextureDimensions()
    lurek.log.debug(sw .. 'x' .. sh)
  end
end

--@api-stub: Quad:typeOf
-- Returns true if this quad handle matches the given type name string.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    if q:typeOf() == 'Quad' then lurek.log.debug('quad') end
  end
end

--@api-stub: Quad:type
-- Returns the Lua-visible type name string for this quad handle.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    lurek.log.debug(q:type())
  end
end

-- Shape methods

--@api-stub: Shape:getCommandCount
-- Returns the number of command items in this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 50, 50)
    lurek.log.debug('cmds=' .. s:getCommandCount())
  end
end

--@api-stub: Shape:clear
-- Clears all items from this shape.
do
  local s
  function lurek.init() s = lurek.render.newShape() end
  function lurek.process(dt) if s then s:clear(); s:line(0, 0, 100 * dt, 50) end end
end

--@api-stub: Shape:setLineWidth
-- Sets the line width of this shape.
do
  local s
  function lurek.init() s = lurek.render.newShape(); s:setLineWidth(3); s:line(0, 0, 80, 0) end
end

--@api-stub: Shape:line
-- Performs the line operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 100, 0)
    s:line(100, 0, 100, 100)
  end
end

--@api-stub: Shape:polyline
-- Performs the polyline operation on this shape.
do
  local s
  function lurek.init() s = lurek.render.newShape(); s:polyline(0, 0, 50, 80, 100, 20, 150, 100) end
end

--@api-stub: Shape:typeOf
-- Returns true if this shape handle matches the given type name string.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    if s:typeOf('Shape') then lurek.log.debug('shape') end
  end
end

--@api-stub: Shape:type
-- Returns the Lua-visible type name string for this shape handle.
do
  local s
  function lurek.init() s = lurek.render.newShape(); lurek.log.debug(s:type()) end
end

-- DrawLayer methods

--@api-stub: DrawLayer:queue
-- Performs the queue operation on this draw layer.
do
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw() dl:queue('rect', 'fill', 50, 50, 100, 60); dl:flush() end
end

--@api-stub: DrawLayer:flush
-- Flushes all pending output from this draw layer immediately.
do
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw() dl:queue('circle', 'fill', 100, 100, 16); dl:flush() end
end

--@api-stub: DrawLayer:clear
-- Clears all items from this draw layer.
do
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.process(dt) dl:clear() end
end

--@api-stub: DrawLayer:getCount
-- Returns the total count of items held by this draw layer.
do
  local dl
  function lurek.init()
    dl = lurek.render.newDrawLayer()
    dl:queue(0, function() lurek.render.rectangle('fill', 0, 0, 8, 8) end)
    lurek.log.debug('queued=' .. dl:getCount())
  end
end

--@api-stub: DrawLayer:type
-- Returns the Lua-visible type name string for this draw layer handle.
do
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer(); lurek.log.debug(dl:type()) end
end

--@api-stub: DrawLayer:typeOf
-- Returns true if this draw layer handle matches the given type name string.
do
  local dl
  function lurek.init()
    dl = lurek.render.newDrawLayer()
    if dl:typeOf('DrawLayer') then lurek.log.debug('dl') end
  end
end


--@api-stub: SpriteBatch:add
-- Adds a  to this sprite batch.
do
  local batch_ref
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "sprites/hero.png")
    if ok then
      batch_ref = lurek.render.newSpriteBatch(img, 256)
      batch_ref:add(100, 200, 0, 1, 1, 16, 16)
      lurek.log.info("batch count: " .. batch_ref:getCount(), "render")
    end
  end
end

--@api-stub: Shape:arc
-- Performs the arc operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.2, 0.8, 1.0, 1.0)
  s:arc("fill", 200, 200, 60, 0, math.pi * 1.5)
  s:draw(0, 0)
  lurek.log.info("arc shape drawn", "render")
end

--@api-stub: ImageData:blit
-- Performs the blit operation on this image data.
do
  local dst = lurek.image.newImageData(64, 64)
  lurek.log.info("ImageData blit available", "render")
end

--@api-stub: Shape:circle
-- Performs the circle operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(1, 0.4, 0, 1)
  s:circle("fill", 300, 250, 40)
  s:draw(0, 0)
  lurek.log.info("circle shape drawn", "render")
end

--@api-stub: NineSlice:draw
-- Draws or renders this nine slice to the current render target.
do
  local ok_img, img = pcall(lurek.render.newImage, "ui/panel.png")
  local ns = ok_img and lurek.render.newNineSlice(img, 8, 8, 8, 8) or nil
  if ns then lurek.render.drawNineSlice(ns, 100, 100, 300, 200) end
  lurek.log.info("nine-slice drawn", "render")
end

--@api-stub: Shape:draw
-- Draws or renders this shape to the current render target.
do
  local s = lurek.render.newShape()
  s:setColor(0, 1, 0.5, 1)
  s:rectangle("fill", 0, 0, 100, 50)
  s:draw(200, 150)
  lurek.log.info("shape drawn", "render")
end

--@api-stub: Shape:ellipse
-- Performs the ellipse operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.9, 0.9, 0.2, 1)
  s:ellipse("fill", 300, 200, 80, 40)
  s:draw(0, 0)
  lurek.log.info("ellipse shape drawn", "render")
end

--@api-stub: ImageData:getRegion
-- Returns the region of this image data.
do
  lurek.log.info("ImageData:getRegion available for atlas slicing", "render")
end

--@api-stub: Shape:polygon
-- Performs the polygon operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.5, 0.2, 0.8, 1)
  s:polygon("fill", 200,100, 250,150, 200,200, 150,150)
  s:draw(0, 0)
  lurek.log.info("polygon shape drawn", "render")
end

--@api-stub: Shape:rectangle
-- Performs the rectangle operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.8, 0.3, 0.1, 1)
  s:rectangle("fill", 50, 50, 120, 80)
  s:draw(0, 0)
  lurek.log.info("rectangle shape drawn", "render")
end

--@api-stub: Shape:roundedRectangle
-- Performs the rounded rectangle operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.4, 0.7, 0.9, 1)
  s:roundedRectangle("fill", 100, 100, 200, 80, 12, 12)
  s:draw(0, 0)
  lurek.log.info("rounded rect drawn", "render")
end

--@api-stub: Shape:setColor
-- Sets the color of this shape.
do
  local s = lurek.render.newShape()
  s:setColor(1.0, 0.0, 0.5, 0.8)
  s:circle("fill", 200, 200, 30)
  s:draw(0, 0)
  lurek.log.info("shape colour set", "render")
end

--@api-stub: Quad:setViewport
-- Sets the viewport of this quad.
do
  local ok_img, img = pcall(lurek.render.newImage, "atlas.png")
  local q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
  q:setViewport(32, 0, 32, 32)
  lurek.log.info("quad viewport updated", "render")
end

--@api-stub: Shape:triangle
-- Performs the triangle operation on this shape.
do
  local s = lurek.render.newShape()
  s:setColor(0.2, 0.9, 0.4, 1)
  s:triangle("fill", 200, 100, 260, 200, 140, 200)
  s:draw(0, 0)
  lurek.log.info("triangle shape drawn", "render")
end

-- -----------------------------------------------------------------------------
-- ImageData methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LImageData methods
-- -----------------------------------------------------------------------------

--@api-stub: lurek.render.drawMany
-- Batch-draws multiple images in one call
do
  local items = {
    { x = 10, y = 20 },
    { x = 50, y = 60 },
    { x = 90, y = 100 },
  }
  lurek.render.drawMany(items)
end

--@api-stub: lurek.render.printRotated
-- Draws text centered and rotated around its midpoint
do
  lurek.render.printRotated("Rotated!", 200, 150, 0.5)
  lurek.render.printRotated("Upside", 300, 200, math.pi, 2.0)
end

--@api-stub: lurek.render.loadObj
-- Loads a Wavefront OBJ model file and returns a model handle for projection and rendering
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/ship.obj")
  if ok and model then
    lurek.log.info("obj verts=" .. model:getVertexCount(), "render")
  end
end

--@api-stub: lurek.render.loadModel
-- Loads a 3D model file (OBJ format) and returns a handle for 2D projection and sprite rendering
do
  local ok, mdl = pcall(lurek.render.loadModel, "assets/models/tower.obj")
  if ok and mdl then
    lurek.log.info("model faces=" .. mdl:getFaceCount(), "render")
  end
end

-- -----------------------------------------------------------------------------
-- LImage methods
-- -----------------------------------------------------------------------------


--@api-stub: LImage:getId
-- Returns the internal numeric handle ID for this image
do
  local ok, img = pcall(lurek.render.newImage, "assets/textures/placeholder.png")
  if ok and img then
    lurek.log.info("texture handle: " .. tostring(img:getId()), "render")
  end
end

--@api-stub: LObjModel:getVertexCount
-- Returns the number of vertices in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getVertexCount()
  end
end

--@api-stub: LObjModel:getFaceCount
-- Returns the number of faces (triangles) in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getFaceCount()
  end
end

--@api-stub: LObjModel:getUvCount
-- Returns the number of UV texture coordinates in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getUvCount()
  end
end

--@api-stub: LObjModel:getNormalCount
-- Returns the number of vertex normals in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getNormalCount()
  end
end

--@api-stub: LObjModel:projectToMesh
-- Projects the OBJ model into 2D vertex data using a virtual camera, returning a table of vertex rows
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local mesh = model:projectToMesh({x = 0, y = 0, z = 0}, 1280, 720)
  end
end

--@api-stub: LObjModel:renderToImage
-- Renders the OBJ model to a GPU texture at the given resolution with optional 90-degree rotation
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local img = model:renderToImage(256, 256)
  end
end
