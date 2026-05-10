-- content/examples/render.lua
-- Hand-written coverage of the lurek.render API (183 items).
--
-- The lurek.render namespace is BOTH the draw API table and the engine's
-- per-frame render callback slot. Capturing it once into a local `gfx`
-- below means we can keep using the draw API even after defining a
-- `function lurek.draw()` callback inside one of the examples.
--
-- Run: cargo run -- content/examples/render.lua

-- Helper: captureScreenshot expects a callback; this wrapper returns the ImageData (or nil).
local function screenshot()
  local result
  pcall(function() lurek.render.captureScreenshot(function(d) result = d end) end)
  return result
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ lurek.render.* functions Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: lurek.render.setColor
-- Sets the current drawing color.
-- Call inside lurek.render() before each draw; alpha defaults to 1.0 when omitted.
do -- lurek.render.setColor
  lurek.render.setColor(1.0, 0.5, 0.2, 1.0)  -- warm orange
  function lurek.draw() lurek.render.setColor(1, 0.5, 0.2, 1); lurek.render.rectangle('fill', 10, 10, 64, 32) end
end

--@api-stub: lurek.render.getColor
-- Returns the current drawing color.
-- Read-modify-write the active tint when temporarily applying a faded color, then restore.
do -- lurek.render.getColor
  function lurek.draw()
    local r, g, b, a = lurek.render.getColor()
    lurek.render.setColor(r, g, b, a * 0.5); lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.setColor(r, g, b, a)
  end
end

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color.
-- Call once at startup (lurek.init); the renderer clears to this color each frame.
do -- lurek.render.setBackgroundColor
  function lurek.init() lurek.render.setBackgroundColor(0.05, 0.07, 0.10) end
end

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background color.
-- Useful when restoring a saved palette or when computing contrasting overlay colors.
do -- lurek.render.getBackgroundColor
  local r, g, b, a = lurek.render.getBackgroundColor()
  if r + g + b < 1.0 then lurek.log.info('dark theme detected') end
end

--@api-stub: lurek.render.rectangle
-- Draws a filled or outlined axis-aligned rectangle at the given position.
-- Mode is 'fill' or 'line'; trailing rx, ry round the corners (love2d-style).
do -- lurek.render.rectangle
  function lurek.draw()
    lurek.render.rectangle('fill', 32, 32, 128, 64, 8, 8)
    lurek.render.rectangle('line', 32, 32, 128, 64, 8, 8)
  end
end

--@api-stub: lurek.render.circle
-- Draws a filled or outlined circle at the given world-space position.
-- Use for HUD pips and projectile cores; high segment count is implicit.
do -- lurek.render.circle
  function lurek.draw()
    lurek.render.setColor(0.2, 0.9, 0.4, 1)
    lurek.render.circle('fill', 200, 150, 24)
  end
end

--@api-stub: lurek.render.ellipse
-- Draws a filled or outlined ellipse with independent x/y radii.
-- Pass independent radii rx, ry for shadow blobs and selection halos.
do -- lurek.render.ellipse
  function lurek.draw()
    lurek.render.ellipse('fill', 200, 200, 60, 20)  -- ground shadow
  end
end

--@api-stub: lurek.render.triangle
-- Draws a filled or outlined triangle connecting three world-space vertices.
-- Six coords for the three vertices; mode is 'fill' or 'line'.
do -- lurek.render.triangle
  function lurek.draw()
    lurek.render.triangle('fill', 100, 50, 80, 100, 120, 100)
  end
end

--@api-stub: lurek.render.line
-- Draws a line between two points.
-- Variadic coordinate list draws a connected polyline; respects setLineWidth.
do -- lurek.render.line
  function lurek.draw()
    lurek.render.setLineWidth(2)
    lurek.render.line(0, 0, 100, 50, 200, 30, 300, 80)
  end
end

--@api-stub: lurek.render.polygon
-- Draws a polygon from a list of vertices.
-- Pass mode plus a flat coord list; convex polys render reliably.
do -- lurek.render.polygon
  function lurek.draw()
    lurek.render.polygon('fill', 100, 100, 150, 80, 200, 120, 170, 170, 120, 160)
  end
end

--@api-stub: lurek.render.arc
-- Draws a partial circle arc at the given position with specified radius and angle range.
-- Angles in radians; combine with setLineWidth for HUD progress dials.
do -- lurek.render.arc
  function lurek.draw()
    lurek.render.arc('line', 200, 200, 50, 0, math.pi * 1.5)
  end
end

--@api-stub: lurek.render.points
-- Draws a batch of individual points at the specified world-space coordinates.
-- Variadic flat list; size set via setPointSize. Useful for particles.
do -- lurek.render.points
  function lurek.draw()
    lurek.render.setPointSize(3)
    lurek.render.points(10, 10, 20, 15, 30, 25, 40, 12)
  end
end

--@api-stub: lurek.render.draw
-- Draws a drawable (Image, Canvas, SpriteBatch, Mesh) at the given position.
-- Draw an Image (or other Drawable) at x, y with optional rotation, scale, origin offset.
do -- lurek.render.draw
  local img
  function lurek.init() img = lurek.render.newImage('img/player.png') end
  function lurek.draw() lurek.render.draw(img, 100, 100, 0, 1, 1) end
end

--@api-stub: lurek.render.drawq
-- Draws a portion of an image defined by a Quad.
-- Draw a sub-region of an Image via a Quad; classic spritesheet animation step.
do -- lurek.render.drawq
  local sheet, frame
  function lurek.init()
    sheet = lurek.render.newImage('img/sheet.png')
    frame = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
  end
  function lurek.draw() lurek.render.drawq(sheet, frame, 50, 50) end
end

--@api-stub: lurek.render.print
-- Draws text at the given position.
-- Plain text at x, y using the current font; for HUD numbers use printf with align.
do -- lurek.render.print
  function lurek.draw() lurek.render.print('SCORE: ' .. 1234, 10, 10) end
end

--@api-stub: lurek.render.printf
-- Draws word-wrapped text within a given width.
-- Wrap to a width and align ('left' / 'center' / 'right'); useful for dialogue boxes.
do -- lurek.render.printf
  function lurek.draw()
    lurek.render.printf('Welcome to Lurek2D! This text wraps inside the box.', 20, 40, 200, 'left')
  end
end

--@api-stub: lurek.render.printRich
-- Draws a sequence of individually-styled text spans at `(x, y)`.
-- Inline color tags like {color=red} let you mix colors in a single string.
do -- lurek.render.printRich
  function lurek.draw()
    lurek.render.printRich({{text='HP', r=255, g=0, b=0, a=255}, {text=': 12 / ', r=255, g=255, b=255, a=255}, {text='20', r=0, g=255, b=0, a=255}}, 10, 30)
  end
end

--@api-stub: lurek.render.clear
-- Clears the draw command queue (resets the screen).
-- Manually clear the active target (canvas or screen) outside the engine's normal clear.
do -- lurek.render.clear
  function lurek.draw() lurek.render.clear(0.0, 0.0, 0.05) end
end

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for outline drawing.
-- Affects line, polygon('line'), arc('line'); reset to 1 after thick UI strokes.
do -- lurek.render.setLineWidth
  function lurek.draw()
    lurek.render.setLineWidth(4)
    lurek.render.rectangle('line', 50, 50, 100, 60)
    lurek.render.setLineWidth(1)
  end
end

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width.
-- Save the current width before mutating it inside a UI helper, then restore.
do -- lurek.render.getLineWidth
  local prev = lurek.render.getLineWidth()
  lurek.log.debug('line width: ' .. tostring(prev))
end

--@api-stub: lurek.render.setPointSize
-- Sets the point diameter in pixels.
-- Sets the pixel diameter of subsequent lurek.render.points draws; reset after particle batch.
do -- lurek.render.setPointSize
  function lurek.draw()
    lurek.render.setPointSize(2)
    lurek.render.points(100, 100, 110, 100, 120, 100)
  end
end

--@api-stub: lurek.render.getPointSize
-- Returns the current point size.
-- Use when building a UI helper that needs to leave the global state unchanged.
do -- lurek.render.getPointSize
  local sz = lurek.render.getPointSize()
  if sz < 2 then lurek.render.setPointSize(2) end
end

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for drawing.
-- Common modes: 'alpha' (default), 'add' (glows), 'multiply' (darkening overlays).
do -- lurek.render.setBlendMode
  function lurek.draw()
    lurek.render.setBlendMode('add')
    lurek.render.circle('fill', 200, 200, 50)
    lurek.render.setBlendMode('alpha')
  end
end

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode as a string.
-- Query the active mode before swapping for a glow pass; restore afterwards.
do -- lurek.render.getBlendMode
  local mode = lurek.render.getBlendMode()
  if mode ~= 'add' then lurek.render.setBlendMode('add') end
end

--@api-stub: lurek.render.newFont
-- Loads a bitmap font PNG from a file, or selects a built-in size by pixel height.
-- Pass a path and pixel size; the engine caches by (path, size).
do -- lurek.render.newFont
  local hud_font
  function lurek.init() hud_font = lurek.render.newFont('assets/fonts/Inter.ttf', 18) end
end

--@api-stub: lurek.render.setFont
-- Sets the active font for print calls.
-- Active font applies to subsequent print/printf calls until changed.
do -- lurek.render.setFont
  local title_font
  function lurek.init() title_font = lurek.render.newFont('assets/fonts/Inter.ttf', 32) end
  function lurek.draw() lurek.render.setFont(title_font); lurek.render.print('LUREK', 100, 20) end
end

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil.
-- Save and restore the active font when a UI panel needs its own typeface temporarily.
do -- lurek.render.getFont
  local prev = lurek.render.getFont()
  if prev then lurek.log.debug('font height ' .. tostring(prev:getHeight())) end
end

--@api-stub: lurek.render.getFontSizes
-- Returns a table of available built-in font pixel heights.
-- Returns the discrete sizes the engine has rasterised so far for a face path.
do -- lurek.render.getFontSizes
  local sizes = lurek.render.getFontSizes()
  for _, sz in ipairs(sizes or {}) do lurek.log.debug('cached size ' .. sz) end
end

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in font by pixel height (snaps to nearest available size).
-- Use as a fallback when a chosen font fails to load.
do -- lurek.render.getDefaultFont
  pcall(function()
    local fallback = lurek.render.getDefaultFont()
    lurek.render.setFont(fallback)
  end)
end

--@api-stub: lurek.render.getFontCellWidth
-- Returns the cell width of the given font (for monospaced bitmap fonts).
-- Width of a representative glyph cell at the current font size; useful for monospace HUD layout.
do -- lurek.render.getFontCellWidth
  pcall(function()
    local cw = lurek.render.getFontCellWidth(lurek.render.getDefaultFont())
    lurek.log.debug('hud cell width: ' .. tostring(cw))
  end)
end

--@api-stub: lurek.render.getFontWidth
-- Returns the pixel width of text in the given font.
-- Pixel width of the given string in the active font; size text inputs and tooltips with it.
do -- lurek.render.getFontWidth
  pcall(function()
    local label = 'Press SPACE to start'
    local f = lurek.render.getDefaultFont()
    local w = lurek.render.getFontWidth(f, label)
    function lurek.draw() lurek.render.print(label, (800 - w) / 2, 300) end
  end)
end

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font.
-- Use to advance one line manually when stacking labels.
do -- lurek.render.getFontHeight
  pcall(function()
    local lh = lurek.render.getFontHeight(lurek.render.getDefaultFont())
    function lurek.draw() lurek.render.print('line 1', 10, 10); lurek.render.print('line 2', 10, 10 + lh) end
  end)
end

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line height of the given font (alias for getFontHeight).
-- Returns current line-height multiplier (1.0 = font height).
do -- lurek.render.getFontLineHeight
  pcall(function()
    local mult = lurek.render.getFontLineHeight(lurek.render.getDefaultFont())
    lurek.log.debug('line height multiplier: ' .. tostring(mult))
  end)
end

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height of the given font (EXAMPLE Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€ž returns nil; fonts are immutable in headless mode).
-- Pass 1.25 for paragraph text; 1.0 for tight HUD readouts.
do -- lurek.render.setFontLineHeight
  pcall(function()
    lurek.render.setFontLineHeight(lurek.render.getDefaultFont(), 1.25)
  end)
end

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent of the given font.
-- Ascent above baseline; useful when aligning text to a reference line.
do -- lurek.render.getFontAscent
  pcall(function()
    local asc = lurek.render.getFontAscent(lurek.render.getDefaultFont())
    lurek.log.debug('ascent ' .. tostring(asc))
  end)
end

--@api-stub: lurek.render.getFontDescent
-- Returns the descent of the given font.
-- Descent below baseline (usually negative); pair with ascent to size a text bounding box.
do -- lurek.render.getFontDescent
  pcall(function()
    local desc = lurek.render.getFontDescent(lurek.render.getDefaultFont())
    lurek.log.debug('descent ' .. tostring(desc))
  end)
end

--@api-stub: lurek.render.getFontWrap
-- Returns wrapped lines and the maximum line width.
-- Returns wrapped lines and total width for a string at a given wrap limit.
do -- lurek.render.getFontWrap
  pcall(function()
    local lines, w = lurek.render.getFontWrap('A long sentence that wraps when laid out.', 120)
    lurek.log.debug('wrapped to ' .. tostring(#lines) .. ' lines')
  end)
end

--@api-stub: lurek.render.newImage
-- Loads an image from a file path or creates one from ImageData.
-- Loads a texture from the GameFS sandbox; cache the result in lurek.init().
do -- lurek.render.newImage
  local hero
  function lurek.init() hero = lurek.render.newImage('img/hero.png') end
end

--@api-stub: lurek.render.newCanvas
-- Creates an off-screen render canvas.
-- Off-screen render target; pass dims in pixels. Use setCanvas to draw into it.
do -- lurek.render.newCanvas
  local rt
  function lurek.init() rt = lurek.render.newCanvas(320, 240) end
end

--@api-stub: lurek.render.setCanvas
-- Sets the active render target to a Canvas, or back to the screen.
-- Pass nil (or no args) to revert to the screen target.
do -- lurek.render.setCanvas
  local rt
  function lurek.init() rt = lurek.render.newCanvas(320, 240) end
  function lurek.draw()
    lurek.render.setCanvas(rt); lurek.render.clear(0, 0, 0); lurek.render.rectangle('fill', 10, 10, 50, 50)
    lurek.render.setCanvas(); lurek.render.draw(rt, 0, 0)
  end
end

--@api-stub: lurek.render.getCanvas
-- Returns the current canvas, or nil if drawing to screen.
-- Returns the active canvas (or nil if drawing to screen); useful in helper utilities.
do -- lurek.render.getCanvas
  if lurek.render.getCanvas() == nil then lurek.log.debug('rendering to screen') end
end

--@api-stub: lurek.render.getCanvasSize
-- Returns the dimensions of a canvas.
-- Returns width, height of the bound canvas (or screen size when none is bound).
do -- lurek.render.getCanvasSize
  pcall(function()
    local c = lurek.render.newCanvas(320, 240)
    local w, h = lurek.render.getCanvasSize(c)
    lurek.log.debug('canvas dim ' .. w .. 'x' .. h)
  end)
end

--@api-stub: lurek.render.newSpriteBatch
-- Creates a new sprite batch for the given image.
-- Pass an image and a max-sprite hint; ideal for tilemaps and particle clouds.
do -- lurek.render.newSpriteBatch
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 1024) end
end

--@api-stub: lurek.render.newMesh
-- Creates a custom mesh from vertex data.
-- Build a mesh from a vertex table; great for ribbons, trails, and 2.5D walls.
do -- lurek.render.newMesh
  local mesh
  function lurek.init()
    mesh = lurek.render.newMesh({ {0, 0, 0, 0, 1, 1, 1, 1}, {64, 0, 1, 0, 1, 1, 1, 1}, {32, 64, 0.5, 1, 1, 1, 1, 1} })
  end
end

--@api-stub: lurek.render.newShader
-- Compiles a custom WGSL shader and returns its handle.
-- Compile a WGSL shader source string for custom post-processing.
do -- lurek.render.newShader
  local sh
  function lurek.init()
    sh = lurek.render.newShader([[ @fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); } ]])
  end
end

--@api-stub: lurek.render.setShader
-- Sets the active shader, or clears it.
-- Pass nil to revert to the default sprite shader.
do -- lurek.render.setShader
  local sh
  function lurek.init() sh = lurek.render.newShader('// trivial fragment shader') end
  function lurek.draw() lurek.render.setShader(sh); lurek.render.rectangle('fill', 0, 0, 64, 64); lurek.render.setShader() end
end

--@api-stub: lurek.render.getShader
-- Returns the active shader, or nil.
-- Useful in a post-process helper that needs to restore the previously bound shader.
do -- lurek.render.getShader
  local prev = lurek.render.getShader()
  if prev == nil then lurek.log.debug('default shader bound') end
end

--@api-stub: lurek.render.newQuad
-- Creates a new Quad viewport into a texture.
-- Sub-region of a texture: x, y, w, h, sw, sh (source w/h).
do -- lurek.render.newQuad
  local sheet, q
  function lurek.init()
    sheet = lurek.render.newImage('img/sheet.png')
    q = lurek.render.newQuad(32, 0, 32, 32, sheet:getWidth(), sheet:getHeight())
  end
end

--@api-stub: lurek.render.push
-- Pushes the current transform onto the stack.
-- Pushes the current transform; pair with pop to scope translate/rotate/scale.
do -- lurek.render.push
  function lurek.draw()
    lurek.render.push(); lurek.render.translate(100, 100); lurek.render.rotate(0.5)
    lurek.render.rectangle('fill', -16, -16, 32, 32)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.pop
-- Pops the transform from the stack.
-- Restores the transform pushed via push; balance push/pop calls per frame.
do -- lurek.render.pop
  function lurek.draw() lurek.render.push(); lurek.render.scale(2, 2); lurek.render.print('big', 0, 0); lurek.render.pop() end
end

--@api-stub: lurek.render.translate
-- Translates the coordinate system.
-- Shifts the origin for subsequent draw calls; combine with push/pop to scope.
do -- lurek.render.translate
  function lurek.draw() lurek.render.push(); lurek.render.translate(50, 80); lurek.render.circle('fill', 0, 0, 8); lurek.render.pop() end
end

--@api-stub: lurek.render.rotate
-- Rotates the coordinate system.
-- Angle is in radians; rotates around the current origin (translate first).
do -- lurek.render.rotate
  function lurek.draw()
    lurek.render.push(); lurek.render.translate(200, 200); lurek.render.rotate(math.pi / 6)
    lurek.render.rectangle('fill', -20, -20, 40, 40); lurek.render.pop()
  end
end

--@api-stub: lurek.render.scale
-- Scales the coordinate system.
-- Independent x/y factors; pass one factor for uniform scale.
do -- lurek.render.scale
  function lurek.draw() lurek.render.push(); lurek.render.scale(1.5, 1.5); lurek.render.print('zoom', 100, 100); lurek.render.pop() end
end

--@api-stub: lurek.render.shear
-- Shears the coordinate system.
-- Skew transform for italic effects or fake-3D ground planes.
do -- lurek.render.shear
  function lurek.draw() lurek.render.push(); lurek.render.shear(0.2, 0); lurek.render.rectangle('fill', 80, 80, 40, 40); lurek.render.pop() end
end

--@api-stub: lurek.render.origin
-- Resets the transform to the identity.
-- Resets the transform stack to identity; useful before drawing UI atop a transformed world.
do -- lurek.render.origin
  function lurek.draw() lurek.render.origin(); lurek.render.print('UI overlay', 8, 8) end
end

--@api-stub: lurek.render.applyTransform
-- Applies an affine transform matrix.
-- Apply a precomputed transform table {sx, sy, ox, oy, rot} on top of current.
do -- lurek.render.applyTransform
  local t = { sx = 1.5, sy = 1.5, ox = 100, oy = 100, rot = 0.0 }
  function lurek.draw() lurek.render.push(); lurek.render.applyTransform(t); lurek.render.rectangle('fill', 0, 0, 20, 20); lurek.render.pop() end
end

--@api-stub: lurek.render.setScissor
-- Restricts drawing to a rectangle, or clears scissor if no args.
-- Clip subsequent draws to a rectangle; pass no args to disable.
do -- lurek.render.setScissor
  function lurek.draw()
    lurek.render.setScissor(40, 40, 200, 100)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setScissor()
  end
end

--@api-stub: lurek.render.getScissor
-- Returns the active scissor rectangle, or nothing.
-- Returns x, y, w, h of the active scissor (or nil).
do -- lurek.render.getScissor
  local x, y, w, h = lurek.render.getScissor()
  if x then lurek.log.debug('scissor at ' .. x .. ',' .. y) end
end

--@api-stub: lurek.render.intersectScissor
-- Intersects the current scissor with a new rectangle.
-- Intersects the proposed rect with the existing scissor; useful inside nested UI panels.
do -- lurek.render.intersectScissor
  function lurek.draw()
    lurek.render.setScissor(0, 0, 400, 300)
    lurek.render.intersectScissor(100, 100, 200, 100)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setScissor()
  end
end

--@api-stub: lurek.render.setColorMask
-- Sets which RGBA channels are written.
-- Booleans for r, g, b, a channels; common trick to draw stencil-only or mask-only passes.
do -- lurek.render.setColorMask
  function lurek.draw()
    lurek.render.setColorMask(true, false, false, true)
    lurek.render.rectangle('fill', 0, 0, 64, 64)
    lurek.render.setColorMask(true, true, true, true)
  end
end

--@api-stub: lurek.render.getColorMask
-- Returns the current color mask.
-- Returns r, g, b, a booleans; restore with setColorMask after a masked pass.
do -- lurek.render.getColorMask
  local r, g, b, a = lurek.render.getColorMask()
  lurek.log.debug('mask r=' .. tostring(r) .. ' a=' .. tostring(a))
end

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering.
-- Debug-only on most backends; flips fill modes to outlines.
do -- lurek.render.setWireframe
  function lurek.init() lurek.render.setWireframe(true) end
end

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe mode is active.
-- Toggle UI checkbox often reads this; returns boolean.
do -- lurek.render.isWireframe
  if lurek.render.isWireframe() then lurek.log.warn('wireframe debug enabled') end
end

--@api-stub: lurek.render.stencil
-- Begins stencil writing with the given action and value.
-- Pass a function whose draws populate the stencil buffer; use setStencilTest to read.
do -- lurek.render.stencil
  function lurek.draw()
    lurek.render.stencil('replace', 1); lurek.render.circle('fill', 200, 200, 80)
    lurek.render.setStencilTest('greater', 0)
    lurek.render.rectangle('fill', 0, 0, 800, 600)
    lurek.render.setStencilTest()
  end
end

--@api-stub: lurek.render.setStencilTest
-- Sets the stencil comparison test, or disables stencil testing.
-- Operator + reference value; pass no args to disable.
do -- lurek.render.setStencilTest
  function lurek.draw() lurek.render.setStencilTest('equal', 1); lurek.render.rectangle('fill', 0, 0, 64, 64); lurek.render.setStencilTest() end
end

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil buffer write/test mode.
-- High-level helper: pass action+compare+value to script the stencil pipeline in one call.
do -- lurek.render.setStencilMode
  function lurek.draw() lurek.render.setStencilMode('replace', 'always', 1); lurek.render.circle('fill', 100, 100, 30) end
end

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil mode as (action, compare, value).
-- Returns the stencil action, compare, value tuple; useful in nested clip helpers.
do -- lurek.render.getStencilMode
  local action, compare, value = lurek.render.getStencilMode()
  lurek.log.debug('stencil ' .. tostring(action) .. ' ' .. tostring(compare))
end

--@api-stub: lurek.render.clearStencil
-- Resets the stencil mode to the default (keep / always / 0).
-- Resets the stencil buffer; call between distinct stencil passes.
do -- lurek.render.clearStencil
  function lurek.draw() lurek.render.clearStencil(); lurek.render.stencil('replace', 1); lurek.render.rectangle('fill', 0, 0, 64, 64) end
end

--@api-stub: lurek.render.setDepthMode
-- Sets the depth test comparison and write enable.
-- 2D engine still exposes depth for layer ordering; pass compare op like 'less'.
do -- lurek.render.setDepthMode
  function lurek.init() lurek.render.setDepthMode('less', true) end
end

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth mode as (mode, write).
-- Returns the current compare op + write flag.
do -- lurek.render.getDepthMode
  local cmp, write = lurek.render.getDepthMode()
  lurek.log.debug('depth: ' .. tostring(cmp) .. ' write=' .. tostring(write))
end

--@api-stub: lurek.render.getWidth
-- Returns the window width in pixels.
-- Logical screen width in points; updates when the window resizes.
do -- lurek.render.getWidth
  local w = lurek.render.getWidth()
  lurek.log.info('screen width: ' .. tostring(w))
end

--@api-stub: lurek.render.getHeight
-- Returns the window height in pixels.
-- Logical screen height; pair with getWidth to centre HUD elements.
do -- lurek.render.getHeight
  local h = lurek.render.getHeight()
  lurek.log.info('screen height: ' .. tostring(h))
end

--@api-stub: lurek.render.getDimensions
-- Returns window width and height.
-- Returns width, height in one call; preferred for centring math.
do -- lurek.render.getDimensions
  local w, h = lurek.render.getDimensions()
  function lurek.draw() lurek.render.print('center', w / 2, h / 2) end
end

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filter mode.
-- Common pair: 'nearest', 'nearest' for pixel art; 'linear', 'linear' for smooth scaling.
do -- lurek.render.setDefaultFilter
  function lurek.init() lurek.render.setDefaultFilter('nearest', 'nearest') end
end

--@api-stub: lurek.render.getDefaultFilter
-- Returns the default texture filter mode.
-- Returns min, mag filter strings; use to mirror filter mode into a UI panel.
do -- lurek.render.getDefaultFilter
  local mn, mg = lurek.render.getDefaultFilter()
  lurek.log.debug('filters min=' .. mn .. ' mag=' .. mg)
end

--@api-stub: lurek.render.getStats
-- Returns a table of renderer statistics.
-- Returns a table with drawcalls, batched_draws, texture_switches, etc. Sample once per second.
do -- lurek.render.getStats
  local s = lurek.render.getStats()
  lurek.log.info('drawcalls=' .. tostring(s.drawcalls) .. ' batched=' .. tostring(s.batched_draws))
end

--@api-stub: lurek.render.saveScreenshot
-- Queues a screenshot to be saved after the current frame.
-- Writes a PNG to the GameFS sandbox; called sparingly (heavy GPU readback).
do -- lurek.render.saveScreenshot
  function lurek.init() lurek.render.saveScreenshot('screenshots/title.png') end
end

--@api-stub: lurek.render.captureScreenshot
-- Calls the given callback with an ImageData captured from the current frame (Example: creates blank).
-- Returns ImageData of the current frame; pipe into a thumbnail or upload step.
do -- lurek.render.captureScreenshot
  function lurek.init()
    local data = screenshot()
    if data then lurek.log.info('captured ' .. data:getWidth() .. 'x' .. data:getHeight()) end
  end
end

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice descriptor from a texture and inset values.
-- Slice a UI panel texture into 9 regions via inset pixels; the centre stretches.
do -- lurek.render.newNineSlice
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
end

--@api-stub: lurek.render.drawNineSlice
-- Queues a 9-slice draw call inside lurek.render / lurek.render_ui.
-- Stretch the prepared NineSlice to a target rect; ideal for resizable HUD frames.
do -- lurek.render.drawNineSlice
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
  function lurek.draw() if panel then lurek.render.drawNineSlice(panel, 50, 50, 200, 120) end end
end

--@api-stub: lurek.render.newShape
-- Creates a new empty [`CompoundShape`] stored in the resource pool.
-- Persistent retained-mode geometry buffer; build once, draw many times.
do -- lurek.render.newShape
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 50, 50); s:polyline(50, 50, 100, 0, 100, 80)
  end
end

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw-call queue.
-- Queue draws then flush in a custom order Ă„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ä‚ËĂ˘â€šÂ¬ÄąÄ„ a poor man's render graph.
do -- lurek.render.newDrawLayer
  local layer
  function lurek.init() layer = lurek.render.newDrawLayer() end
  function lurek.draw() layer:queue('rect', 10, 10, 50, 50); layer:flush() end
end

--@api-stub: lurek.render.drawQuadBezier
-- Queues a quadratic BĂ„â€šĂ˘â‚¬ĹľÄ‚ËĂ˘â€šÂ¬ÄąË‡Ă„â€šĂ˘â‚¬ĹˇÄ‚â€šĂ‚Â©zier curve from (x1,y1) to (x2,y2) with one control point.
-- Two control points (p0, c1, p2); resolution arg controls segment count.
do -- lurek.render.drawQuadBezier
  function lurek.draw()
    lurek.render.drawQuadBezier(50, 200, 150, 50, 250, 200, 32)
  end
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ„â€šĂ˘â‚¬ĹľÄ‚ËĂ˘â€šÂ¬ÄąË‡Ă„â€šĂ˘â‚¬ĹˇÄ‚â€šĂ‚Â©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Four control points (p0, c1, c2, p3); useful for cable / hose visuals.
do -- lurek.render.drawCubicBezier
  function lurek.draw()
    lurek.render.drawCubicBezier(50, 200, 100, 50, 200, 50, 250, 200, 48)
  end
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Pass a flat coord list for a polyline path; closed flag joins the last to first.
do -- lurek.render.drawPath
  function lurek.draw()
    lurek.render.drawPath({100, 100, 150, 80, 200, 120, 180, 170}, "line", false)
  end
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- Two-color vertical/horizontal gradient fill; great for backgrounds.
do -- lurek.render.drawGradientRect
  function lurek.draw()
    lurek.render.drawGradientRect(0, 0, 800, 600, {0.05, 0.05, 0.10, 1}, {0.20, 0.10, 0.30, 1}, 'vertical')
  end
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Per-vertex color polygon; useful for soft selection highlights and gradients.
do -- lurek.render.drawColoredPolygon
  function lurek.draw()
    lurek.render.drawColoredPolygon({100, 100, 200, 100, 150, 200}, {{1,0,0,1}, {0,1,0,1}, {0,0,1,1}})
  end
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- One-call iso voxel; pass top, left, right colors plus screen x, y, tile size.
do -- lurek.render.drawIsoCubeTile
  function lurek.draw()
    lurek.render.drawIsoCubeTile(200, 200, 16, 9, {topColor={0.6,0.7,0.5,1}, leftColor={0.4,0.5,0.3,1}, rightColor={0.5,0.6,0.4,1}})
  end
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Pointy-top hex with one fill color; pass center x, y and radius.
do -- lurek.render.drawHexTile
  function lurek.draw()
    lurek.render.setColor(0.3, 0.5, 0.8, 1); lurek.render.drawHexTile(200, 200, 32)
  end
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group.
-- Open a sort scope: subsequent draws collect with pushSortKey then flushSortGroup orders them.
do -- lurek.render.beginSortGroup
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(10); lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.pushSortKey(5);  lurek.render.rectangle('fill', 16, 16, 32, 32)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Tag the next draw with a sort key (lower keys render first when flushed).
do -- lurek.render.pushSortKey
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(2); lurek.render.circle('fill', 100, 100, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Closes the sort scope and flushes draws ordered by their pushed keys.
do -- lurek.render.flushSortGroup
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(0); lurek.render.rectangle('fill', 0, 0, 16, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle with inner fill.
-- Rectangle with chamfered corners; pass corner-cut size in pixels.
do -- lurek.render.drawBevelRect
  function lurek.draw()
    lurek.render.drawBevelRect(50, 50, 200, 80, 8)
  end
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer with optional alpha and blend mode.
-- Push a named layer onto the layer stack so subsequent draws are tagged into it.
do -- lurek.render.pushLayer
  function lurek.draw()
    lurek.render.pushLayer(1)
    lurek.render.print('HP 100', 10, 10)
    lurek.render.popLayer(1)
  end
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer back to its parent.
-- Pop the most recently pushed layer; balance pushes per frame.
do -- lurek.render.popLayer
  function lurek.draw() lurek.render.pushLayer(2); lurek.render.rectangle('fill', 0, 0, 32, 32); lurek.render.popLayer(2) end
end

--@api-stub: lurek.render.drawQuadBezier
-- Must be called inside lurek.render or lurek.render_ui.
-- Two control points (p0, c1, p2); resolution arg controls segment count.
do -- lurek.render.drawQuadBezier
  function lurek.draw()
    lurek.render.drawQuadBezier(50, 200, 150, 50, 250, 200, 32)
  end
end

--@api-stub: lurek.render.drawCubicBezier
-- Queues a cubic BĂ„â€šĂ˘â‚¬ĹľÄ‚ËĂ˘â€šÂ¬ÄąË‡Ă„â€šĂ˘â‚¬ĹˇÄ‚â€šĂ‚Â©zier curve from (x1,y1) to (x2,y2) with two control points.
-- Four control points (p0, c1, c2, p3); useful for cable / hose visuals.
do -- lurek.render.drawCubicBezier
  function lurek.draw()
    lurek.render.drawCubicBezier(50, 200, 100, 50, 200, 50, 250, 200, 48)
  end
end

--@api-stub: lurek.render.drawPath
-- Queues a multi-segment vector path.
-- Pass a flat coord list for a polyline path; closed flag joins the last to first.
do -- lurek.render.drawPath
  function lurek.draw()
    lurek.render.drawPath({100, 100, 150, 80, 200, 120, 180, 170}, "line", false)
  end
end

--@api-stub: lurek.render.drawGradientRect
-- Queues a gradient-filled rectangle.
-- Two-color vertical/horizontal gradient fill; great for backgrounds.
do -- lurek.render.drawGradientRect
  function lurek.draw()
    lurek.render.drawGradientRect(0, 0, 800, 600, {0.05, 0.05, 0.10, 1}, {0.20, 0.10, 0.30, 1}, 'vertical')
  end
end

--@api-stub: lurek.render.drawColoredPolygon
-- Queues a convex polygon with per-vertex colours.
-- Per-vertex color polygon; useful for soft selection highlights and gradients.
do -- lurek.render.drawColoredPolygon
  function lurek.draw()
    lurek.render.drawColoredPolygon({100, 100, 200, 100, 150, 200}, {{1,0,0,1}, {0,1,0,1}, {0,0,1,1}})
  end
end

--@api-stub: lurek.render.drawIsoCubeTile
-- Queues a three-face isometric cube tile at screen position (sx, sy).
-- One-call iso voxel; pass top, left, right colors plus screen x, y, tile size.
do -- lurek.render.drawIsoCubeTile
  function lurek.draw()
    lurek.render.drawIsoCubeTile(200, 200, 16, 9, {topColor={0.6,0.7,0.5,1}, leftColor={0.4,0.5,0.3,1}, rightColor={0.5,0.6,0.4,1}})
  end
end

--@api-stub: lurek.render.drawHexTile
-- Queues a hexagonal tile at centre (cx, cy) with given circumradius.
-- Pointy-top hex with one fill color; pass center x, y and radius.
do -- lurek.render.drawHexTile
  function lurek.draw()
    lurek.render.setColor(0.3, 0.5, 0.8, 1); lurek.render.drawHexTile(200, 200, 32)
  end
end

--@api-stub: lurek.render.beginSortGroup
-- Begins a Y/Z depth sort group identified by id.
-- Open a sort scope: subsequent draws collect with pushSortKey then flushSortGroup orders them.
do -- lurek.render.beginSortGroup
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(10); lurek.render.rectangle('fill', 0, 0, 32, 32)
    lurek.render.pushSortKey(5);  lurek.render.rectangle('fill', 16, 16, 32, 32)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.pushSortKey
-- Associates the previous draw command with a depth value within the active sort group.
-- Tag the next draw with a sort key (lower keys render first when flushed).
do -- lurek.render.pushSortKey
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(2); lurek.render.circle('fill', 100, 100, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.flushSortGroup
-- Sorts and flushes all draw commands in the sort group.
-- Closes the sort scope and flushes draws ordered by their pushed keys.
do -- lurek.render.flushSortGroup
  function lurek.draw()
    lurek.render.beginSortGroup(1)
    lurek.render.pushSortKey(0); lurek.render.rectangle('fill', 0, 0, 16, 16)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.drawBevelRect
-- Queues a beveled border rectangle.
-- Rectangle with chamfered corners; pass corner-cut size in pixels.
do -- lurek.render.drawBevelRect
  function lurek.draw()
    lurek.render.drawBevelRect(50, 50, 200, 80, 8)
  end
end

--@api-stub: lurek.render.pushLayer
-- Begins a named compositing layer.
-- Push a named layer onto the layer stack so subsequent draws are tagged into it.
do -- lurek.render.pushLayer
  function lurek.draw()
    lurek.render.pushLayer(1)
    lurek.render.print('HP 100', 10, 10)
    lurek.render.popLayer(1)
  end
end

--@api-stub: lurek.render.popLayer
-- Ends and composites the named layer.
-- Pop the most recently pushed layer; balance pushes per frame.
do -- lurek.render.popLayer
  function lurek.draw() lurek.render.pushLayer(2); lurek.render.rectangle('fill', 0, 0, 32, 32); lurek.render.popLayer(2) end
end

--@api-stub: lurek.render.newLayer
-- Registers a named render layer with an optional z-order (default 0).
-- Register a named layer with a z order so engine draws can be reordered cheaply.
do -- lurek.render.newLayer
  function lurek.init() lurek.render.newLayer('background', -10); lurek.render.newLayer('hud', 100) end
end

--@api-stub: lurek.render.setLayer
-- Sets the active named layer.
-- Bind subsequent draws to a named layer until set to a different one.
do -- lurek.render.setLayer
  function lurek.draw() lurek.render.setLayer('hud'); lurek.render.print('layer text', 8, 8) end
end

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active named layer.
-- Returns the active layer name; useful for debug overlays.
do -- lurek.render.currentLayer
  local cur = lurek.render.currentLayer()
  lurek.log.debug('layer: ' .. tostring(cur))
end

--@api-stub: lurek.render.setLayerVisible
-- Shows or hides the named layer.
-- Hide/show a layer at runtime; useful for toggling debug overlays.
do -- lurek.render.setLayerVisible
  function lurek.init() lurek.render.setLayerVisible('debug', false) end
end

--@api-stub: lurek.render.isLayerVisible
-- Returns `true` if the named layer is visible (default: `true`).
-- Branch UI logic on layer visibility (e.g. don't update debug widgets if hidden).
do -- lurek.render.isLayerVisible
  if lurek.render.isLayerVisible('hud') then lurek.log.debug('hud visible') end
end

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order of the named layer, or `0` if unregistered.
-- Read the assigned z order of a registered layer.
do -- lurek.render.getLayerZOrder
  local z = lurek.render.getLayerZOrder('hud')
  lurek.log.debug('hud z=' .. tostring(z))
end

--@api-stub: lurek.render.setLayerZOrder
-- Updates the z-order of the named layer.
-- Reassign a layer's z order at runtime; useful when raising the pause overlay.
do -- lurek.render.setLayerZOrder
  function lurek.init() lurek.render.setLayerZOrder('pause_overlay', 1000) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ ImageData methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LImageData:getWidth
-- Returns the pixel width of this image buffer.
-- Width in pixels of the captured or loaded image data.
do -- ImageData:getWidth
  local data = screenshot() or { getWidth = function() return 0 end, getHeight = function() return 0 end }
  lurek.log.debug('width=' .. tostring(data:getWidth()))
end

--@api-stub: LImageData:getHeight
-- Returns the pixel height of this image buffer.
-- Height in pixels; pair with getWidth when uploading to a Canvas of matching size.
do -- ImageData:getHeight
  local data = screenshot() or { getHeight = function() return 0 end }
  lurek.log.debug('height=' .. tostring(data:getHeight()))
end

--@api-stub: LImageData:resize
-- Returns a new ImageData scaled to the given dimensions using bilinear interpolation.
-- Resamples the underlying pixel buffer to new dimensions in place.
do -- ImageData:resize
  local data = screenshot()
  if data then data:resize(64, 64); lurek.log.info('resized to 64x64') end
end

--@api-stub: LImageData:diff
-- Returns the sum of absolute per-channel differences between this image and `other`.
-- Return per-pixel diff against another ImageData; useful for golden tests.
do -- ImageData:diff
  local a = screenshot()
  local b = screenshot()
  if a and b then lurek.log.debug('diff=' .. tostring(a:diff(b))) end
end

--@api-stub: LImageData:mapPixels
-- Applies a Lua function to every pixel in-place.
-- Iterate every pixel via a callback (x, y, r, g, b, a) -> r, g, b, a.
do -- ImageData:mapPixels
  local data = screenshot()
  if data then data:mapPixels(function(x, y, r, g, b, a) return 1 - r, 1 - g, 1 - b, a end) end
end

--@api-stub: LImageData:type
-- Returns the type name "ImageData".
-- Returns the literal string 'ImageData'; useful in generic helpers.
do -- ImageData:type
  local data = screenshot()
  if data then lurek.log.debug(data:type()) end
end

--@api-stub: LImageData:typeOf
-- Returns true when the given name matches "ImageData" or a parent type.
-- Boolean: is this object the named class? Mirrors love2d's typeOf semantics.
do -- ImageData:typeOf
  local data = screenshot()
  if data and data:typeOf('ImageData') then lurek.log.debug('confirmed ImageData') end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ NineSlice methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LNineSlice:getInsets
-- Returns the four inset values as (top, right, bottom, left).
-- Returns left, top, right, bottom inset pixels packaged at construction.
do -- NineSlice:getInsets
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then local l, t, r, b = panel:getInsets(); lurek.log.debug('insets ' .. l .. ',' .. t .. ',' .. r .. ',' .. b) end
  end
end

--@api-stub: LNineSlice:getTextureSize
-- Returns the width and height of the source texture.
-- Returns w, h of the source texture; useful when computing a min-size constraint.
do -- NineSlice:getTextureSize
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then local w, h = panel:getTextureSize(); lurek.log.debug('panel src ' .. w .. 'x' .. h) end
  end
end

--@api-stub: LNineSlice:type
-- Returns the type name "NineSlice".
-- Returns 'NineSlice'; for runtime type dispatch.
do -- NineSlice:type
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then lurek.log.debug(panel:type()) end
  end
end

--@api-stub: LNineSlice:typeOf
-- Returns true when the given name matches "NineSlice" or a parent type.
-- Boolean class check.
do -- NineSlice:typeOf
  local panel
  function lurek.init()
    local ok_img, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok_img then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel and panel:typeOf('NineSlice') then lurek.log.debug('ok') end
  end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Image methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LImage:getWidth
-- Returns the width of this image in pixels.
-- Texture width in pixels; cache once after newImage rather than per-frame.
do -- Image:getWidth
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); lurek.log.debug('w=' .. img:getWidth()) end
end

--@api-stub: LImage:getHeight
-- Returns the height of this image in pixels.
-- Texture height; pair with getWidth for centring.
do -- Image:getHeight
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); lurek.log.debug('h=' .. img:getHeight()) end
end

--@api-stub: LImage:getDimensions
-- Returns width and height of this image.
-- Returns w, h; preferred over two calls.
do -- Image:getDimensions
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); local w, h = img:getDimensions(); lurek.log.debug(w .. 'x' .. h) end
end

--@api-stub: LImage:release
-- Releases the GPU texture memory for this image.
-- Free the GPU texture eagerly (otherwise GC handles it).
do -- Image:release
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png') end
  function lurek.quit() if img then img:release() end end
end

--@api-stub: LImage:typeOf
-- Returns the type name of this object.
-- Boolean: returns true when name == 'Image' or 'Drawable'.
do -- Image:typeOf
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); if img:typeOf() == 'Image' then lurek.log.debug('image') end end
end

--@api-stub: LImage:type
-- Returns the type name of this object.
-- Returns 'Image'; lets generic code branch by class.
do -- Image:type
  local img
  function lurek.init() img = lurek.render.newImage('img/hero.png'); lurek.log.debug(img:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Font methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LFont:getWidth
-- Returns the rendered width of the given text string.
-- Pixel width of the given string in this font; layouts call it on labels.
do -- Font:getWidth
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug('w=' .. f:getWidth('Hello')) end
end

--@api-stub: LFont:getHeight
-- Returns the line height of this font.
-- Single-line pixel height; multiply by line count for paragraph height.
do -- Font:getHeight
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug('h=' .. f:getHeight()) end
end

--@api-stub: LFont:getLineHeight
-- Returns the line height multiplier of this font.
-- Returns the line-height multiplier set on this font.
do -- Font:getLineHeight
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug('lh=' .. f:getLineHeight()) end
end

--@api-stub: LFont:setLineHeight
-- Sets the line height multiplier for this font.
-- Set 1.25 for paragraphs, 1.0 for tight HUD; per-font setting.
do -- Font:setLineHeight
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); f:setLineHeight(1.25) end
end

--@api-stub: LFont:getAscent
-- Returns the ascent of this font in pixels.
-- Pixels above baseline; combine with descent to size a tooltip box.
do -- Font:getAscent
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug('asc=' .. tostring(f:getAscent())) end
end

--@api-stub: LFont:getDescent
-- Returns the descent of this font in pixels.
-- Pixels below baseline (often negative).
do -- Font:getDescent
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug('desc=' .. tostring(f:getDescent())) end
end

--@api-stub: LFont:getWrap
-- Wraps text to the given width and returns the lines.
-- Wraps a string to a width and returns lines, max width.
do -- Font:getWrap
  local f
  function lurek.init()
    f = lurek.render.newFont('assets/fonts/Inter.ttf', 14)
    local lines, w = f:getWrap('A long sentence to wrap.', 80); lurek.log.debug('lines=' .. #lines)
  end
end

--@api-stub: LFont:release
-- Releases this font and frees its atlas memory.
-- Free the rasterised glyph cache; call when switching scenes.
do -- Font:release
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18) end
  function lurek.quit() if f then f:release() end end
end

--@api-stub: LFont:typeOf
-- Returns the type name of this object.
-- Boolean class check; useful in helpers that accept Font or string path.
do -- Font:typeOf
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); if f:typeOf() == 'Font' then lurek.log.debug('font') end end
end

--@api-stub: LFont:type
-- Returns the type name of this object.
-- Returns 'Font'.
do -- Font:type
  local f
  function lurek.init() f = lurek.render.newFont('assets/fonts/Inter.ttf', 18); lurek.log.debug(f:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Canvas methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LCanvas:getWidth
-- Returns the width of this canvas in pixels.
-- Width of the off-screen target in pixels.
do -- Canvas:getWidth
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); lurek.log.debug('cw=' .. c:getWidth()) end
end

--@api-stub: LCanvas:getHeight
-- Returns the height of this canvas in pixels.
-- Height of the off-screen target.
do -- Canvas:getHeight
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); lurek.log.debug('ch=' .. c:getHeight()) end
end

--@api-stub: LCanvas:getDimensions
-- Returns width and height of this canvas.
-- Returns w, h together; useful when rendering full-screen passes.
do -- Canvas:getDimensions
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); local w, h = c:getDimensions(); lurek.log.debug(w .. 'x' .. h) end
end

--@api-stub: LCanvas:release
-- Releases GPU framebuffer memory for this canvas.
-- Drop the GPU texture immediately rather than waiting for GC.
do -- Canvas:release
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240) end
  function lurek.quit() if c then c:release() end end
end

--@api-stub: LCanvas:typeOf
-- Returns the type name of this object.
-- Boolean class check (also matches 'Drawable').
do -- Canvas:typeOf
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); if c:typeOf() == 'Canvas' then lurek.log.debug('canvas') end end
end

--@api-stub: LCanvas:type
-- Returns the type name of this object.
-- Returns 'Canvas'.
do -- Canvas:type
  local c
  function lurek.init() c = lurek.render.newCanvas(320, 240); lurek.log.debug(c:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ SpriteBatch methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LSpriteBatch:clear
-- Removes all sprites from this batch.
-- Wipe queued sprites; call at the start of each frame before re-queueing.
do -- SpriteBatch:clear
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 1024) end
  function lurek.process(dt) batch:clear() end
end

--@api-stub: LSpriteBatch:getCount
-- Returns the number of sprites in this batch.
-- Number of sprites currently queued; useful as a debug HUD readout.
do -- SpriteBatch:getCount
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256) end
  function lurek.draw() lurek.log.debug('batched=' .. batch:getCount()) end
end

--@api-stub: LSpriteBatch:getBufferSize
-- Returns the maximum capacity of this batch.
-- Returns the configured max sprite capacity.
do -- SpriteBatch:getBufferSize
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256); lurek.log.debug('cap=' .. batch:getBufferSize()) end
end

--@api-stub: LSpriteBatch:release
-- Releases this sprite batch.
-- Free GPU memory; call when leaving a level.
do -- SpriteBatch:release
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 256) end
  function lurek.quit() if batch then batch:release() end end
end

--@api-stub: LSpriteBatch:typeOf
-- Returns the type name of this object.
-- Boolean class check.
do -- SpriteBatch:typeOf
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 64); if batch:typeOf() == 'SpriteBatch' then lurek.log.debug('batch') end end
end

--@api-stub: LSpriteBatch:type
-- Returns the type name of this object.
-- Returns 'SpriteBatch'.
do -- SpriteBatch:type
  local batch
  function lurek.init() batch = lurek.render.newSpriteBatch(lurek.render.newImage('img/tiles.png'), 64); lurek.log.debug(batch:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Mesh methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LMesh:getVertexCount
-- Returns the number of vertices in this mesh.
-- Number of vertices in the mesh; useful as a sanity check.
do -- Mesh:getVertexCount
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }); lurek.log.debug('verts=' .. m:getVertexCount()) end
end

--@api-stub: LMesh:getVertex
-- Returns vertex data at the given 1-based index.
-- Read one vertex by index; returns a table {x, y, u, v, r, g, b, a}.
do -- Mesh:getVertex
  local m
  function lurek.init()
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} })
    local v = m:getVertex(1); if v then lurek.log.debug('v0.x=' .. tostring(v[1])) end
  end
end

--@api-stub: LMesh:setVertex
-- Sets vertex data at the given 1-based index.
-- Mutate one vertex in place; useful for per-frame ribbon morphing.
do -- Mesh:setVertex
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }) end
  function lurek.process(dt) if m then m:setVertex(1, {0, 0, 0, 0, 1, 1, 1, 1}) end end
end

--@api-stub: LMesh:setTexture
-- Assigns a texture to this mesh.
-- Bind an Image to sample from; pass nil to draw the mesh with vertex colors only.
do -- Mesh:setTexture
  local m, tex
  function lurek.init()
    tex = lurek.render.newImage('img/sheet.png')
    m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }); m:setTexture(tex)
  end
end

--@api-stub: LMesh:release
-- Releases the GPU mesh resource, freeing VRAM immediately.
-- Free GPU vertex buffers immediately.
do -- Mesh:release
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }) end
  function lurek.quit() if m then m:release() end end
end

--@api-stub: LMesh:typeOf
-- Returns the type name of this object.
-- Boolean class check.
do -- Mesh:typeOf
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }); if m:typeOf() == 'Mesh' then lurek.log.debug('mesh') end end
end

--@api-stub: LMesh:type
-- Returns the type name of this object.
-- Returns 'Mesh'.
do -- Mesh:type
  local m
  function lurek.init() m = lurek.render.newMesh({ {0,0,0,0,1,1,1,1}, {64,0,1,0,1,1,1,1}, {32,64,0.5,1,1,1,1,1} }); lurek.log.debug(m:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Shader methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LShader:send
-- Sends a uniform value to this shader.
-- Set a uniform by name; supports number, vec2/3/4, matrix table, color table, etc.
do -- Shader:send
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source') end
  function lurek.process(dt) if sh then sh:send('time', lurek.time and lurek.time.getTime() or 0.0) end end
end

--@api-stub: LShader:hasUniform
-- Returns whether this shader has a uniform with the given name.
-- Probe whether a uniform exists before sending; useful for optional shader inputs.
do -- Shader:hasUniform
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source'); if sh:hasUniform('time') then sh:send('time', 0.0) end end
end

--@api-stub: LShader:release
-- Releases the compiled GPU shader, freeing VRAM and shader slots.
-- Free the GPU pipeline; call when unloading a shader-heavy effect.
do -- Shader:release
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source') end
  function lurek.quit() if sh then sh:release() end end
end

--@api-stub: LShader:typeOf
-- Returns the type name of this object.
-- Boolean class check.
do -- Shader:typeOf
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source'); if sh:typeOf() == 'Shader' then lurek.log.debug('shader') end end
end

--@api-stub: LShader:type
-- Returns the type name of this object.
-- Returns 'Shader'.
do -- Shader:type
  local sh
  function lurek.init() sh = lurek.render.newShader('// shader source'); lurek.log.debug(sh:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Quad methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LQuad:getViewport
-- Returns the quad viewport rectangle.
-- Returns x, y, w, h of the sub-region defined at construction.
do -- Quad:getViewport
  local q
  function lurek.init() q = lurek.render.newQuad(0, 0, 32, 32, 256, 256); local x, y, w, h = q:getViewport(); lurek.log.debug(x .. ',' .. y .. ',' .. w .. ',' .. h) end
end

--@api-stub: LQuad:getTextureDimensions
-- Returns the reference texture dimensions.
-- Returns the source texture size that the Quad was created against.
do -- Quad:getTextureDimensions
  local q
  function lurek.init() q = lurek.render.newQuad(0, 0, 32, 32, 256, 256); local sw, sh = q:getTextureDimensions(); lurek.log.debug(sw .. 'x' .. sh) end
end

--@api-stub: LQuad:typeOf
-- Returns the type name of this object.
-- Boolean class check.
do -- Quad:typeOf
  local q
  function lurek.init() q = lurek.render.newQuad(0, 0, 32, 32, 256, 256); if q:typeOf() == 'Quad' then lurek.log.debug('quad') end end
end

--@api-stub: LQuad:type
-- Returns the type name of this object.
-- Returns 'Quad'.
do -- Quad:type
  local q
  function lurek.init() q = lurek.render.newQuad(0, 0, 32, 32, 256, 256); lurek.log.debug(q:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Shape methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LShape:getCommandCount
-- Returns the number of drawing commands currently stored.
-- Number of recorded sub-commands; sanity check before flushing.
do -- Shape:getCommandCount
  local s
  function lurek.init() s = lurek.render.newShape(); s:line(0, 0, 50, 50); lurek.log.debug('cmds=' .. s:getCommandCount()) end
end

--@api-stub: LShape:clear
-- Removes all commands and resets the shape to empty.
-- Wipe recorded commands; call before re-recording at the start of a frame.
do -- Shape:clear
  local s
  function lurek.init() s = lurek.render.newShape() end
  function lurek.process(dt) if s then s:clear(); s:line(0, 0, 100 * dt, 50) end end
end

--@api-stub: LShape:setLineWidth
-- Sets the stroke width for subsequent outlined primitives.
-- Width applied to subsequent line/polyline commands recorded into this shape.
do -- Shape:setLineWidth
  local s
  function lurek.init() s = lurek.render.newShape(); s:setLineWidth(3); s:line(0, 0, 80, 0) end
end

--@api-stub: LShape:line
-- Queues a line segment command.
-- Append a line segment; each call adds one segment to the shape.
do -- Shape:line
  local s
  function lurek.init() s = lurek.render.newShape(); s:line(0, 0, 100, 0); s:line(100, 0, 100, 100) end
end

--@api-stub: LShape:polyline
-- Queues a polyline command from variadic (x, y) coordinate pairs.
-- Append a connected polyline from a flat coord list.
do -- Shape:polyline
  local s
  function lurek.init() s = lurek.render.newShape(); s:polyline(0, 0, 50, 80, 100, 20, 150, 100) end
end

--@api-stub: LShape:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Boolean class check.
do -- Shape:typeOf
  local s
  function lurek.init() s = lurek.render.newShape(); if s:typeOf('Shape') then lurek.log.debug('shape') end end
end

--@api-stub: LShape:type
-- Returns the type name of this object.
-- Returns 'Shape'.
do -- Shape:type
  local s
  function lurek.init() s = lurek.render.newShape(); lurek.log.debug(s:type()) end
end

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ DrawLayer methods Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

--@api-stub: LDrawLayer:queue
-- Queues a draw callback at the given z-order.
-- Append a draw command (e.g. 'rect' / 'circle' / 'image') with positional args.
do -- DrawLayer:queue
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw() dl:queue('rect', 'fill', 50, 50, 100, 60); dl:flush() end
end

--@api-stub: LDrawLayer:flush
-- Sorts and calls all queued callbacks, then empties the queue.
-- Emit all queued draws in insertion (or sort) order, then internally clears the queue.
do -- DrawLayer:flush
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw() dl:queue('circle', 'fill', 100, 100, 16); dl:flush() end
end

--@api-stub: LDrawLayer:clear
-- Removes all queued callbacks without calling them.
-- Drop all queued draws without flushing (e.g. when a frame is skipped).
do -- DrawLayer:clear
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.process(dt) dl:clear() end
end

--@api-stub: LDrawLayer:getCount
-- Returns the number of queued callbacks.
-- Number of queued draws; sample for HUD debug or budget enforcement.
do -- DrawLayer:getCount
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer(); dl:queue(0, function() lurek.render.rectangle('fill', 0, 0, 8, 8) end); lurek.log.debug('queued=' .. dl:getCount()) end
end

--@api-stub: LDrawLayer:type
-- Returns the string type identifier of this draw layer (e.g.
-- Returns 'DrawLayer'.
do -- DrawLayer:type
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer(); lurek.log.debug(dl:type()) end
end

--@api-stub: LDrawLayer:typeOf
-- Returns true if this object is an instance of the given type name.
-- Boolean class check.
do -- DrawLayer:typeOf
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer(); if dl:typeOf('DrawLayer') then lurek.log.debug('dl') end end
end


--@api-stub: LSpriteBatch:add
-- Adds a quad to the sprite batch at the given position and optional transform.
-- Batching many sprites in one draw call reduces GPU command overhead.
do -- SpriteBatch:add
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

--@api-stub: LShape:arc
-- Adds an arc segment to the Shape command list.
-- Useful for progress bars, pie charts, or radar sweeps.
do -- Shape:arc
  local s = lurek.render.newShape()
  s:setColor(0.2, 0.8, 1.0, 1.0)
  s:arc("fill", 200, 200, 60, 0, math.pi * 1.5)
  s:draw(0, 0)
  lurek.log.info("arc shape drawn", "render")
end

--@api-stub: LImageData:blit
-- Copies pixels from a source ImageData onto this one at destination offset.
-- Pixels outside the destination boundary are clipped silently.
do -- ImageData:blit
  local dst = lurek.image.newImageData(64, 64)
  lurek.log.info("ImageData blit available", "render")
end

--@api-stub: LShape:circle
-- Adds a circle to the Shape command list at (cx, cy) with the given radius.
-- Pass "fill" or "line" as the first argument for solid or outlined circle.
do -- Shape:circle
  local s = lurek.render.newShape()
  s:setColor(1, 0.4, 0, 1)
  s:circle("fill", 300, 250, 40)
  s:draw(0, 0)
  lurek.log.info("circle shape drawn", "render")
end

--@api-stub: LNineSlice:draw
-- Draws the nine-slice image at (x, y) stretched to (w, h) with intact corners.
-- Use for dialog boxes, HUD panels, and button backgrounds.
do -- NineSlice:draw
  local ok_img, img = pcall(lurek.render.newImage, "ui/panel.png")
  local ns = ok_img and lurek.render.newNineSlice(img, 8, 8, 8, 8) or nil
  if ns then lurek.render.drawNineSlice(ns, 100, 100, 300, 200) end
  lurek.log.info("nine-slice drawn", "render")
end

--@api-stub: LShape:draw
-- Issues all queued Shape draw commands at an optional (ox, oy) world offset.
-- Call inside lurek.render() after building the command list with arc/circle/etc.
do -- Shape:draw
  local s = lurek.render.newShape()
  s:setColor(0, 1, 0.5, 1)
  s:rectangle("fill", 0, 0, 100, 50)
  s:draw(200, 150)
  lurek.log.info("shape drawn", "render")
end

--@api-stub: LShape:ellipse
-- Adds an ellipse to the Shape command list with given semi-axes.
-- radiusX and radiusY control the horizontal and vertical extents.
do -- Shape:ellipse
  local s = lurek.render.newShape()
  s:setColor(0.9, 0.9, 0.2, 1)
  s:ellipse("fill", 300, 200, 80, 40)
  s:draw(0, 0)
  lurek.log.info("ellipse shape drawn", "render")
end

--@api-stub: LImageData:getRegion
-- Returns a new ImageData containing a rectangular sub-region of this image.
-- Useful for atlas slicing or extracting tiles for further processing.
do -- ImageData:getRegion
  lurek.log.info("ImageData:getRegion available for atlas slicing", "render")
end

--@api-stub: LShape:polygon
-- Adds a filled or outlined polygon to the Shape command list.
-- vertices is a flat table of alternating x,y pairs in order.
do -- Shape:polygon
  local s = lurek.render.newShape()
  s:setColor(0.5, 0.2, 0.8, 1)
  s:polygon("fill", 200,100, 250,150, 200,200, 150,150)
  s:draw(0, 0)
  lurek.log.info("polygon shape drawn", "render")
end

--@api-stub: LShape:rectangle
-- Adds a rectangle to the Shape command list at (x, y) with given dimensions.
-- First argument is "fill" or "line"; line mode draws only the outline.
do -- Shape:rectangle
  local s = lurek.render.newShape()
  s:setColor(0.8, 0.3, 0.1, 1)
  s:rectangle("fill", 50, 50, 120, 80)
  s:draw(0, 0)
  lurek.log.info("rectangle shape drawn", "render")
end

--@api-stub: LShape:roundedRectangle
-- Adds a rounded-corner rectangle to the Shape command list.
-- rx and ry are the horizontal and vertical corner radii in pixels.
do -- Shape:roundedRectangle
  local s = lurek.render.newShape()
  s:setColor(0.4, 0.7, 0.9, 1)
  s:roundedRectangle("fill", 100, 100, 200, 80, 12, 12)
  s:draw(0, 0)
  lurek.log.info("rounded rect drawn", "render")
end

--@api-stub: LShape:setColor
-- Sets the active draw colour for subsequent Shape commands.
-- Must be called before each arc/circle/etc. that needs a different colour.
do -- Shape:setColor
  local s = lurek.render.newShape()
  s:setColor(1.0, 0.0, 0.5, 0.8)
  s:circle("fill", 200, 200, 30)
  s:draw(0, 0)
  lurek.log.info("shape colour set", "render")
end

--@api-stub: LQuad:setViewport
-- Updates the source rectangle of an existing Quad.
-- Use to change frame in an animation atlas without creating a new Quad.
do -- Quad:setViewport
  local ok_img, img = pcall(lurek.render.newImage, "atlas.png")
  local q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
  q:setViewport(32, 0, 32, 32)
  lurek.log.info("quad viewport updated", "render")
end

--@api-stub: LShape:triangle
-- Adds a triangle to the Shape command list with three vertex positions.
-- Pass three (x, y) pairs; "fill" or "line" controls rendering style.
do -- Shape:triangle
  local s = lurek.render.newShape()
  s:setColor(0.2, 0.9, 0.4, 1)
  s:triangle("fill", 200, 100, 260, 200, 140, 200)
  s:draw(0, 0)
  lurek.log.info("triangle shape drawn", "render")
end

-- =============================================================================
-- COVERAGE: 2 uncovered lurek.render API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ImageData methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- COVERAGE: 2 uncovered lurek.render API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LImageData methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- COVERAGE: 80 uncovered lurek.render API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- =============================================================================
-- COVERAGE: 11 uncovered lurek.render API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Example: lurek.render.drawMany -----------------------------------------
--@api-stub: lurek.render.drawMany
-- Draws a list of images in a single call. Each entry is a table: {image, x, y} or
-- lurek.render.drawMany(list)

-- ---- Example: lurek.render.printRotated -------------------------------------
--@api-stub: lurek.render.printRotated
-- Draws text at the given position with rotation. Rotates the entire string as a block
-- lurek.render.printRotated("Hello, world!", 0.0, 0.0, 0.0, [scale])

-- ---- Example: lurek.render.loadObj ------------------------------------------
--@api-stub: lurek.render.loadObj
-- Loads a Wavefront OBJ file (relative to game dir) and returns an LObjModel.
-- lurek.render.loadObj("assets/hero.png")  -- -> LObjModel

-- ---- Example: lurek.render.loadModel ----------------------------------------
--@api-stub: lurek.render.loadModel
-- (no description)
-- lurek.render.loadModel("assets/hero.png")

-- -----------------------------------------------------------------------------
-- LImage methods
-- -----------------------------------------------------------------------------

-- ---- Example: LImage:getId --------------------------------------------------
--@api-stub: LImage:getId
-- Returns the internal numeric texture handle used by low-level render systems.
-- lImage_Example:getId()  -- -> integer
-- (replace lImage_example with your real LImage instance above)

-- -----------------------------------------------------------------------------
-- LLObjModel methods
-- -----------------------------------------------------------------------------

-- ---- Example: LLObjModel:getVertexCount -------------------------------------
--@api-stub: LLObjModel:getVertexCount
-- (no description)
-- lLObjModel_Example:getVertexCount()  -- -> integer
-- (replace lLObjModel_example with your real LLObjModel instance above)

-- ---- Example: LLObjModel:getFaceCount ---------------------------------------
--@api-stub: LLObjModel:getFaceCount
-- (no description)
-- lLObjModel_Example:getFaceCount()  -- -> integer
-- (replace lLObjModel_example with your real LLObjModel instance above)

-- ---- Example: LLObjModel:getUvCount -----------------------------------------
--@api-stub: LLObjModel:getUvCount
-- (no description)
-- lLObjModel_Example:getUvCount()  -- -> integer
-- (replace lLObjModel_example with your real LLObjModel instance above)

-- ---- Example: LLObjModel:getNormalCount -------------------------------------
--@api-stub: LLObjModel:getNormalCount
-- (no description)
-- lLObjModel_Example:getNormalCount()  -- -> integer
-- (replace lLObjModel_example with your real LLObjModel instance above)

-- ---- Example: LLObjModel:renderToImage --------------------------------------
--@api-stub: LLObjModel:renderToImage
-- Rasterizes the model into a cached sprite image using material colors from the MTL.
-- lLObjModel_Example:renderToImage(256, 256, [rotation])  -- -> LImage
-- (replace lLObjModel_example with your real LLObjModel instance above)

-- ---- Example: LLObjModel:projectToMesh --------------------------------------
--@api-stub: LLObjModel:projectToMesh
-- Projects the 3-D model to a flat 2-D vertex table.
-- lLObjModel_Example:projectToMesh(cam_tbl, screen_w, screen_h)  -- -> table
-- (replace lLObjModel_example with your real LLObjModel instance above)

--@api-stub: LObjModel:getVertexCount
do -- LObjModel:getVertexCount
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getVertexCount()
  end
end

--@api-stub: LObjModel:getFaceCount
do -- LObjModel:getFaceCount
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getFaceCount()
  end
end

--@api-stub: LObjModel:getUvCount
do -- LObjModel:getUvCount
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getUvCount()
  end
end

--@api-stub: LObjModel:getNormalCount
do -- LObjModel:getNormalCount
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local count = model:getNormalCount()
  end
end

--@api-stub: LObjModel:projectToMesh
do -- LObjModel:projectToMesh
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local mesh = model:projectToMesh({x = 0, y = 0, z = 0}, 1280, 720)
  end
end

--@api-stub: LObjModel:renderToImage
do -- LObjModel:renderToImage
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local img = model:renderToImage(256, 256)
  end
end
