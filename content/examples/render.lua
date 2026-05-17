-- content/examples/render.lua
-- Comprehensive lurek.render API examples: drawing, text, transforms, canvases, shaders, and more.
-- Run: cargo run -- content/examples/render.lua

-- =============================================================================
-- COLOR STATE
-- =============================================================================

--@api-stub: lurek.render.setColor
-- Sets the active drawing color for all subsequent draw operations
do
  -- All draw calls use the current color as a tint/fill.
  -- Values are floats from 0.0 to 1.0 for each channel (RGBA).
  -- The alpha channel defaults to 1.0 (fully opaque) when omitted.
  lurek.render.setColor(1.0, 0.5, 0.2, 1.0)  -- warm orange, fully opaque
  lurek.render.setColor(0.0, 0.0, 0.0, 0.5)  -- semi-transparent black (shadow overlay)
end

--@api-stub: lurek.render.getColor
-- Returns the current drawing color
do
  -- Use getColor to save and restore color state around helper functions
  -- that change the color internally.
  local r, g, b, a = lurek.render.getColor()
  -- Now draw something with a different color...
  lurek.render.setColor(1, 0, 0, 1)
  -- ...then restore the original color so the caller is unaffected.
  lurek.render.setColor(r, g, b, a)
end

--@api-stub: lurek.render.setBackgroundColor
-- Sets the background clear color used at the start of each frame
do
  -- The background color fills the screen before any draw calls run.
  -- Set it once in lurek.init() for consistent results.
  -- Use dark desaturated tones for most games to reduce eye strain.
  lurek.render.setBackgroundColor(0.05, 0.07, 0.10)  -- near-black blue-grey
end

--@api-stub: lurek.render.getBackgroundColor
-- Returns the current background clear color
do
  -- Returns r, g, b, a as four floats.
  -- Useful for computing complementary UI colors based on the theme.
  local r, g, b, a = lurek.render.getBackgroundColor()
  local is_dark = (r + g + b) < 1.0
  if is_dark then
    lurek.log.info("dark theme active — using light text")
  end
end

-- =============================================================================
-- SHAPE PRIMITIVES
-- =============================================================================

--@api-stub: lurek.render.rectangle
-- Draws a rectangle
do
  -- Mode "fill" draws a solid rectangle; "line" draws only the outline.
  -- Optional rx, ry add rounded corners (horizontal and vertical radii).
  -- Rounded rects are common for buttons, panels, and health bars.
  lurek.render.setColor(0.2, 0.6, 1.0, 1.0)
  lurek.render.rectangle("fill", 32, 32, 200, 40)         -- solid blue bar
  lurek.render.setColor(1, 1, 1, 1)
  lurek.render.rectangle("line", 32, 32, 200, 40)         -- white outline
  lurek.render.rectangle("fill", 32, 90, 200, 40, 8, 8)  -- rounded corners
end

--@api-stub: lurek.render.circle
-- Draws a circle
do
  -- Circles are defined by center (x, y) and radius.
  -- Great for bullets, pickups, minimaps, and debug collision visualization.
  lurek.render.setColor(0.2, 0.9, 0.4, 1)
  lurek.render.circle("fill", 200, 150, 24)   -- filled green dot (pickup)
  lurek.render.setColor(1, 1, 1, 0.4)
  lurek.render.circle("line", 200, 150, 30)   -- faint outer ring (glow)
end

--@api-stub: lurek.render.ellipse
-- Draws an ellipse
do
  -- An ellipse has separate horizontal (rx) and vertical (ry) radii.
  -- Flat ellipses under characters simulate ground shadows.
  lurek.render.setColor(0, 0, 0, 0.3)
  lurek.render.ellipse("fill", 200, 300, 40, 10)  -- ground shadow
end

--@api-stub: lurek.render.triangle
-- Draws a triangle from three vertex positions
do
  -- Triangles are the basic building block for custom polygons.
  -- Useful for arrows, direction indicators, and simple particles.
  lurek.render.setColor(1, 0.8, 0, 1)
  lurek.render.triangle("fill", 400, 50, 380, 100, 420, 100)  -- yellow arrow tip
end

--@api-stub: lurek.render.line
-- Draws a line between two points, or a polyline through multiple points
do
  -- Pass x1,y1,x2,y2 for a single segment, or more pairs for a polyline.
  -- Use setLineWidth() first to control thickness.
  -- Great for laser beams, connection lines, and debug paths.
  lurek.render.setLineWidth(2)
  lurek.render.setColor(0.5, 1, 0.5, 1)
  lurek.render.line(10, 10, 200, 10)                 -- horizontal line
  lurek.render.line(10, 20, 50, 60, 100, 40, 150, 80)  -- polyline path
end

--@api-stub: lurek.render.polygon
-- Draws a polygon from a flat list of x,y vertex coordinates
do
  -- Minimum 3 vertices (6 values). Vertices are wound in order.
  -- Use "fill" for solid shapes, "line" for outlines.
  -- Ideal for hex tiles, irregular terrain chunks, or custom UI shapes.
  lurek.render.setColor(0.6, 0.3, 0.9, 1)
  lurek.render.polygon("fill", 100, 100, 150, 80, 200, 120, 170, 170, 120, 160)
end

--@api-stub: lurek.render.arc
-- Draws a circular arc
do
  -- An arc is a portion of a circle defined by start and end angles (radians).
  -- "fill" makes a pie/wedge shape; "line" draws the curved edge only.
  -- Use for pie charts, radial menus, cooldown indicators.
  local cooldown_pct = 0.7  -- 70% complete
  lurek.render.setColor(0, 0.8, 1, 1)
  lurek.render.arc("fill", 400, 200, 50, -math.pi/2, -math.pi/2 + math.pi*2 * cooldown_pct)
end

--@api-stub: lurek.render.points
-- Draws one or more points
do
  -- Points are rendered as small squares sized by setPointSize().
  -- Efficient for starfields, particle dots, or debug markers.
  lurek.render.setPointSize(3)
  lurek.render.setColor(1, 1, 1, 0.8)
  lurek.render.points(10, 10, 25, 40, 60, 20, 90, 55, 130, 30)  -- starfield dots
end

-- =============================================================================
-- IMAGE & DRAWABLE RENDERING
-- =============================================================================

--@api-stub: lurek.render.draw
-- Draws a drawable object (Image, Canvas, SpriteBatch, or Mesh) at the given position with optional transform
do
  -- Parameters: drawable, x, y, rotation, scaleX, scaleY, originX, originY
  -- Origin offsets shift the point around which rotation and scaling happen.
  -- Setting origin to the center of a sprite enables rotation around its midpoint.
  local img
  function lurek.init()
    img = lurek.render.newImage("img/player.png")
  end
  function lurek.draw()
    local w, h = img:getWidth(), img:getHeight()
    -- Draw centered at (200, 200), rotated 45 degrees, no scale offset
    lurek.render.draw(img, 200, 200, math.pi/4, 1, 1, w/2, h/2)
  end
end

--@api-stub: lurek.render.drawq
-- Draws a sub-region of an image defined by a Quad, with optional transform
do
  -- drawq renders only the rectangle defined by the Quad.
  -- Essential for sprite sheet animation: change the Quad each frame.
  local sheet, frames
  function lurek.init()
    sheet = lurek.render.newImage("img/sheet.png")
    -- Define 4 animation frames, each 32x32, in a horizontal strip
    frames = {}
    for i = 0, 3 do
      frames[i+1] = lurek.render.newQuad(i*32, 0, 32, 32, 256, 256)
    end
  end
  function lurek.draw()
    -- Pick frame based on time for simple animation
    local idx = math.floor(lurek.timer.getTime() * 8) % 4 + 1
    lurek.render.drawq(sheet, frames[idx], 100, 100)
  end
end

--@api-stub: lurek.render.drawMany
-- Batch-draws multiple images in one call
do
  -- drawMany takes an array of draw-entry tables for efficient bulk rendering.
  -- Each entry: {image, x, y, r, sx, sy, ox, oy} — mirrors lurek.render.draw params.
  -- Use for particle systems or tile layers that share the same texture.
  local img
  function lurek.init()
    img = lurek.render.newImage("img/star.png")
  end
  function lurek.draw()
    local items = {}
    for i = 1, 20 do
      items[i] = { img, i * 30, 100, 0, 1, 1, 0, 0 }
    end
    lurek.render.drawMany(items)
  end
end

-- =============================================================================
-- TEXT RENDERING
-- =============================================================================

--@api-stub: lurek.render.print
-- Draws text using the active font at the given position
do
  -- Renders a single line of text at (x, y) with optional uniform scale.
  -- The active font is set via setFont(); if none, uses the built-in default.
  -- Fast path for HUD labels, scores, and debug output.
  function lurek.draw()
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("SCORE: 1234", 10, 10)
    lurek.render.print("ZOOMED", 10, 40, 2.0)  -- scale=2 doubles the text size
  end
end

--@api-stub: lurek.render.printf
-- Draws word-wrapped and aligned text within a pixel-width limit
do
  -- Text wraps at the pixel limit. align can be "left", "center", "right", "justify".
  -- Use for dialog boxes, tooltips, and paragraph text.
  function lurek.draw()
    lurek.render.setColor(0.9, 0.9, 0.9, 1)
    lurek.render.printf(
      "Welcome to Lurek2D! This text automatically wraps within a 200px box.",
      20, 40, 200, "left"
    )
    lurek.render.printf("GAME OVER", 0, 300, 800, "center")  -- centered on screen
  end
end

--@api-stub: lurek.render.printRich
-- Draws rich text composed of individually styled spans at the given position
do
  -- Each span is a table with text, r, g, b, a (0-255 range), and optional scale.
  -- Use for colorized damage numbers, inline stat highlights, etc.
  function lurek.draw()
    lurek.render.printRich({
      { text = "HP", r = 255, g = 80, b = 80, a = 255 },
      { text = ": 45 / ", r = 200, g = 200, b = 200, a = 255 },
      { text = "100", r = 80, g = 255, b = 80, a = 255 },
    }, 10, 10)
  end
end

--@api-stub: lurek.render.printRotated
-- Draws text centered and rotated around its midpoint
do
  -- Rotates text around its center point, unlike print() which rotates at top-left.
  -- Useful for angled labels, spinning damage numbers, or compass markers.
  function lurek.draw()
    lurek.render.setColor(1, 1, 0, 1)
    lurek.render.printRotated("N", 400, 50, 0)               -- north label
    lurek.render.printRotated("E", 450, 100, math.pi / 2)    -- east, rotated 90 deg
  end
end

-- =============================================================================
-- FRAME MANAGEMENT
-- =============================================================================

--@api-stub: lurek.render.clear
-- Clears all queued render commands for the current frame
do
  -- clear() discards everything drawn so far this frame.
  -- Optional r,g,b args are reserved for future clear-color override.
  -- Use to implement screen transitions or to discard a cancelled draw pass.
  function lurek.draw()
    lurek.render.clear()
    -- Now redraw from scratch
    lurek.render.rectangle("fill", 0, 0, 100, 100)
  end
end

-- =============================================================================
-- LINE & POINT STYLE
-- =============================================================================

--@api-stub: lurek.render.setLineWidth
-- Sets the line width for subsequent line-mode draw calls
do
  -- Affects rectangle("line"), circle("line"), line(), polygon("line"), etc.
  -- Default is 1 pixel. Larger values create thicker outlines.
  function lurek.draw()
    lurek.render.setLineWidth(4)
    lurek.render.rectangle("line", 50, 50, 100, 60)  -- thick border
    lurek.render.setLineWidth(1)                      -- restore default
  end
end

--@api-stub: lurek.render.getLineWidth
-- Returns the current line width
do
  -- Save/restore pattern: read current width before changing it.
  local prev = lurek.render.getLineWidth()
  lurek.render.setLineWidth(3)
  -- ... draw thick outlines ...
  lurek.render.setLineWidth(prev)
end

--@api-stub: lurek.render.setPointSize
-- Sets the point size for subsequent point draw calls
do
  -- Points are rendered as squares of this diameter.
  -- Increase for visibility; decrease for subtle dot effects.
  lurek.render.setPointSize(4)
  lurek.render.points(100, 100, 110, 100, 120, 100)  -- 4px dots in a row
end

--@api-stub: lurek.render.getPointSize
-- Returns the current point size
do
  local sz = lurek.render.getPointSize()
  lurek.log.debug("current point size: " .. tostring(sz))
end

-- =============================================================================
-- BLEND MODES
-- =============================================================================

--@api-stub: lurek.render.setBlendMode
-- Sets the blend mode for subsequent draw operations
do
  -- Modes: "alpha" (default), "add" (glow/fire), "multiply" (shadows),
  --         "replace" (no blending), "screen" (lighten).
  -- Additive blending is ideal for particles, explosions, and light effects.
  function lurek.draw()
    -- Draw a glow effect using additive blending
    lurek.render.setBlendMode("add")
    lurek.render.setColor(1, 0.5, 0, 0.6)
    lurek.render.circle("fill", 200, 200, 60)  -- fiery glow
    -- Always restore to alpha when done
    lurek.render.setBlendMode("alpha")
  end
end

--@api-stub: lurek.render.getBlendMode
-- Returns the current blend mode name
do
  local mode = lurek.render.getBlendMode()
  lurek.log.debug("blend mode: " .. mode)  -- e.g. "alpha"
end

-- =============================================================================
-- FONTS
-- =============================================================================

--@api-stub: lurek.render.newFont
-- Creates a new bitmap font from a PNG sprite sheet path or returns a built-in font by pixel height
do
  -- Pass a TTF/OTF path + size to load a custom font, or just a number for built-in.
  -- Fonts are GPU-cached after first use, so create them once in init().
  local hud_font, title_font
  function lurek.init()
    hud_font   = lurek.render.newFont("assets/fonts/Inter.ttf", 16)
    title_font = lurek.render.newFont("assets/fonts/Inter.ttf", 48)
  end
end

--@api-stub: lurek.render.setFont
-- Sets the active font used by print, printf, and other text rendering calls
do
  -- Switch fonts to change text appearance. Only one font is active at a time.
  local title_font
  function lurek.init()
    title_font = lurek.render.newFont("assets/fonts/Inter.ttf", 32)
  end
  function lurek.draw()
    lurek.render.setFont(title_font)
    lurek.render.print("TITLE SCREEN", 100, 20)
  end
end

--@api-stub: lurek.render.getFont
-- Returns the currently active font, or nil if none is set
do
  local f = lurek.render.getFont()
  if f then
    lurek.log.debug("active font height: " .. tostring(f:getHeight()))
  end
end

--@api-stub: lurek.render.getFontSizes
-- Returns all available built-in font pixel heights
do
  -- The engine ships with pre-rasterized fonts at specific sizes.
  -- Use these sizes with getDefaultFont() for instant zero-load fonts.
  local sizes = lurek.render.getFontSizes()
  for _, sz in ipairs(sizes or {}) do
    lurek.log.debug("available built-in size: " .. sz)
  end
end

--@api-stub: lurek.render.getDefaultFont
-- Returns a built-in default font at the nearest available pixel height
do
  -- Great for debug overlays — no file loading needed.
  -- Optionally pass a pixel height; engine picks the closest cached size.
  pcall(function()
    local font = lurek.render.getDefaultFont(16)
    lurek.render.setFont(font)
  end)
end

--@api-stub: lurek.render.getFontCellWidth
-- Returns the fixed cell width of a bitmap font
do
  -- Monospace/bitmap fonts have a fixed cell width for grid alignment.
  -- Returns 0 for proportional (variable-width) fonts.
  pcall(function()
    local f = lurek.render.getDefaultFont()
    local cw = lurek.render.getFontCellWidth(f)
    lurek.log.debug("cell width: " .. tostring(cw))
  end)
end

--@api-stub: lurek.render.getFontWidth
-- Measures the pixel width of text using the given font
do
  -- Essential for centering text, fitting labels in buttons, or clipping.
  pcall(function()
    local f = lurek.render.getDefaultFont()
    local label = "Press SPACE to start"
    local w = lurek.render.getFontWidth(f, label)
    -- Center the label horizontally on an 800px screen
    local screen_w = 800
    local x = (screen_w - w) / 2
    lurek.log.debug("label x=" .. tostring(x))
  end)
end

--@api-stub: lurek.render.getFontHeight
-- Returns the line height of the given font
do
  -- Use font height to stack multiple lines of text with correct spacing.
  pcall(function()
    local f = lurek.render.getDefaultFont()
    local lh = lurek.render.getFontHeight(f)
    function lurek.draw()
      lurek.render.print("Line 1", 10, 10)
      lurek.render.print("Line 2", 10, 10 + lh)
      lurek.render.print("Line 3", 10, 10 + lh * 2)
    end
  end)
end

--@api-stub: lurek.render.getFontLineHeight
-- Returns the line spacing of the given font
do
  -- Line height is the vertical distance between baselines of consecutive lines.
  pcall(function()
    local lh = lurek.render.getFontLineHeight(lurek.render.getDefaultFont())
    lurek.log.debug("line spacing: " .. tostring(lh))
  end)
end

--@api-stub: lurek.render.setFontLineHeight
-- Sets the line height override for a font (currently a no-op stub)
do
  -- Reserved for future use: override the default line spacing for tighter text.
  pcall(function()
    lurek.render.setFontLineHeight(lurek.render.getDefaultFont(), 1.4)
  end)
end

--@api-stub: lurek.render.getFontAscent
-- Returns the ascent (pixels above baseline) of the given font
do
  -- Ascent + descent = total glyph height. Useful for precise text alignment.
  pcall(function()
    local asc = lurek.render.getFontAscent(lurek.render.getDefaultFont())
    lurek.log.debug("ascent: " .. tostring(asc) .. "px")
  end)
end

--@api-stub: lurek.render.getFontDescent
-- Returns the descent (pixels below baseline) of the given font
do
  -- Descent measures how far characters like 'g', 'p', 'y' hang below the line.
  pcall(function()
    local desc = lurek.render.getFontDescent(lurek.render.getDefaultFont())
    lurek.log.debug("descent: " .. tostring(desc) .. "px")
  end)
end

--@api-stub: lurek.render.getFontWrap
-- Word-wraps text using the active font and returns the resulting lines and widest line width
do
  -- Returns (lines_table, max_width). Use to pre-compute dialog box height.
  pcall(function()
    local text = "A long sentence that needs to wrap when displayed in a narrow dialog box."
    local lines, widest = lurek.render.getFontWrap(text, 150)
    if lines then
      lurek.log.debug("wrapped to " .. #lines .. " lines, widest=" .. tostring(widest))
    end
  end)
end

-- =============================================================================
-- IMAGES & TEXTURES
-- =============================================================================

--@api-stub: lurek.render.newImage
-- Loads a texture from a file path or creates one from an ImageData object
do
  -- Supports PNG, BMP, TGA. Path is relative to the game directory.
  -- Optional colorSpace: "srgb" (default for art) or "linear" (for data textures).
  -- Always create images in init() — loading mid-frame causes stalls.
  local hero, normal_map
  function lurek.init()
    hero       = lurek.render.newImage("img/hero.png")
    normal_map = lurek.render.newImage("img/normals.png", "linear")
  end
end

-- =============================================================================
-- CANVASES (RENDER TARGETS)
-- =============================================================================

--@api-stub: lurek.render.newCanvas
-- Creates a new off-screen render target with the given dimensions
do
  -- Canvases let you draw into a texture, then composite it onto the screen.
  -- Common uses: minimap, lighting layer, post-processing input, screen shake.
  local scene_buffer
  function lurek.init()
    scene_buffer = lurek.render.newCanvas(320, 240)  -- quarter-res for retro look
  end
end

--@api-stub: lurek.render.setCanvas
-- Redirects all subsequent drawing to the given canvas
do
  -- Pass a canvas to draw into it; pass nil (or no args) to return to screen.
  -- Always pair: setCanvas(rt) ... draw ... setCanvas()
  local rt
  function lurek.init()
    rt = lurek.render.newCanvas(320, 240)
  end
  function lurek.draw()
    -- Render the scene into the off-screen buffer
    lurek.render.setCanvas(rt)
    lurek.render.clear(0, 0, 0)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.rectangle("fill", 10, 10, 50, 50)
    -- Switch back to screen and draw the buffer scaled up
    lurek.render.setCanvas()
    lurek.render.draw(rt, 0, 0, 0, 2.5, 2.5)
  end
end

--@api-stub: lurek.render.getCanvas
-- Returns the currently active canvas, or nil if drawing to the screen
do
  -- Check where we are drawing to avoid accidentally nesting canvas switches.
  if lurek.render.getCanvas() == nil then
    lurek.log.debug("currently rendering to the main screen")
  end
end

--@api-stub: lurek.render.getCanvasSize
-- Returns the pixel dimensions of a canvas
do
  -- Useful when you need to know the render target size for UV calculations.
  pcall(function()
    local c = lurek.render.newCanvas(320, 240)
    local w, h = lurek.render.getCanvasSize(c)
    lurek.log.debug("canvas: " .. w .. "x" .. h)
  end)
end

-- =============================================================================
-- SPRITE BATCHES
-- =============================================================================

--@api-stub: lurek.render.newSpriteBatch
-- Creates a batched sprite renderer for efficiently drawing many copies of the same texture
do
  -- SpriteBatches reduce draw calls for tile maps and particle systems.
  -- All sprites share the same texture. Specify max capacity upfront.
  local batch
  function lurek.init()
    local tileset = lurek.render.newImage("img/tiles.png")
    batch = lurek.render.newSpriteBatch(tileset, 2048)  -- up to 2048 tiles
  end
end

-- =============================================================================
-- MESHES
-- =============================================================================

--@api-stub: lurek.render.newMesh
-- Creates a custom vertex mesh from an array of vertex data tables
do
  -- Each vertex: {x, y, u, v, r, g, b, a} — position, UV, color.
  -- Modes: "triangles" (default), "fan", "strip".
  -- Use for custom geometry, textured quads, or deformable surfaces.
  local mesh
  function lurek.init()
    mesh = lurek.render.newMesh({
      { 0,  0,  0, 0,  1, 0, 0, 1 },  -- top-left, red
      { 64, 0,  1, 0,  0, 1, 0, 1 },  -- top-right, green
      { 32, 64, 0.5, 1, 0, 0, 1, 1 }, -- bottom-center, blue
    }, "triangles")
  end
  function lurek.draw()
    lurek.render.draw(mesh, 100, 100)
  end
end

-- =============================================================================
-- SHADERS
-- =============================================================================

--@api-stub: lurek.render.newShader
-- Compiles a WGSL shader program from source code and returns a handle
do
  -- Shaders use WGSL (WebGPU Shading Language). Compile once in init().
  -- Use for post-processing, palette swaps, water effects, or CRT filters.
  local sh
  function lurek.init()
    sh = lurek.render.newShader([[
      @fragment fn fs() -> @location(0) vec4<f32> {
        return vec4<f32>(1.0, 0.5, 0.0, 1.0);
      }
    ]])
  end
end

--@api-stub: lurek.render.setShader
-- Activates a shader for subsequent draw calls
do
  -- Pass a shader handle to enable it; pass nil to restore the default.
  -- All draw calls between setShader(sh) and setShader() use the custom shader.
  local sh
  function lurek.init()
    sh = lurek.render.newShader("// WGSL shader source")
  end
  function lurek.draw()
    lurek.render.setShader(sh)
    lurek.render.rectangle("fill", 0, 0, 200, 200)  -- drawn with custom shader
    lurek.render.setShader()                         -- back to default
  end
end

--@api-stub: lurek.render.getShader
-- Returns the currently active shader, or nil if using the default
do
  local active = lurek.render.getShader()
  if active == nil then
    lurek.log.debug("using default shader pipeline")
  end
end

-- =============================================================================
-- QUADS (SPRITE SHEET REGIONS)
-- =============================================================================

--@api-stub: lurek.render.newQuad
-- Creates a Quad defining a rectangular sub-region of a texture for sprite-sheet rendering
do
  -- Parameters: x, y, width, height within the texture, then full texture width and height.
  -- Create one Quad per animation frame, then swap them each tick.
  local sheet, walk_frame
  function lurek.init()
    sheet = lurek.render.newImage("img/sheet.png")
    -- Second frame in a 32x32 grid on a 256x256 sheet
    walk_frame = lurek.render.newQuad(32, 0, 32, 32, 256, 256)
  end
end

-- =============================================================================
-- TRANSFORM STACK
-- =============================================================================

--@api-stub: lurek.render.push
-- Pushes the current transformation matrix onto the transform stack
do
  -- push/pop let you isolate transforms. All changes between push and pop
  -- are discarded when you pop, restoring the previous matrix.
  function lurek.draw()
    lurek.render.push()
      lurek.render.translate(100, 100)
      lurek.render.rotate(0.5)
      lurek.render.rectangle("fill", -16, -16, 32, 32)  -- rotated around center
    lurek.render.pop()
    -- Transform is restored here — subsequent draws are unaffected.
  end
end

--@api-stub: lurek.render.pop
-- Pops the top transformation matrix from the transform stack, restoring the previous one
do
  -- Always pair each push() with exactly one pop().
  -- Mismatched push/pop causes an error or visual corruption.
  function lurek.draw()
    lurek.render.push()
      lurek.render.scale(2, 2)
      lurek.render.print("doubled", 0, 0)
    lurek.render.pop()
    lurek.render.print("normal", 0, 30)
  end
end

--@api-stub: lurek.render.translate
-- Applies a translation to the current transformation matrix
do
  -- Shifts the drawing origin by (x, y) pixels.
  -- Common for camera scrolling: translate(-camX, -camY) before drawing the world.
  function lurek.draw()
    lurek.render.push()
      lurek.render.translate(400, 300)  -- move origin to screen center
      lurek.render.circle("fill", 0, 0, 20)  -- draws at (400, 300)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.rotate
-- Applies a rotation to the current transformation matrix
do
  -- Rotates around the current origin in radians (clockwise).
  -- Translate to the pivot point first, then rotate, then draw at (0,0).
  function lurek.draw()
    lurek.render.push()
      lurek.render.translate(200, 200)      -- pivot point
      lurek.render.rotate(math.pi / 6)      -- 30 degrees
      lurek.render.rectangle("fill", -20, -20, 40, 40)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.scale
-- Applies scaling to the current transformation matrix
do
  -- sx, sy scale horizontally and vertically. Negative values flip.
  -- If sy is omitted, uniform scaling (sx, sx) is applied.
  function lurek.draw()
    lurek.render.push()
      lurek.render.scale(2, 2)             -- everything is 2x larger
      lurek.render.print("BIG TEXT", 10, 10)
    lurek.render.pop()
    lurek.render.push()
      lurek.render.scale(-1, 1)            -- horizontal flip (mirror)
      lurek.render.print("FLIPPED", -200, 50)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.shear
-- Applies a shear (skew) to the current transformation matrix
do
  -- kx shears horizontally; ky shears vertically.
  -- Use for italic text effects, parallelogram shapes, or wind deformation.
  function lurek.draw()
    lurek.render.push()
      lurek.render.shear(0.3, 0)  -- horizontal skew
      lurek.render.rectangle("fill", 80, 80, 60, 40)
    lurek.render.pop()
  end
end

--@api-stub: lurek.render.origin
-- Resets the current transformation matrix to the identity (no transform)
do
  -- Instantly removes all active transforms without needing to pop.
  -- Useful for HUD overlays that must be drawn in screen space regardless
  -- of any world camera transform currently in effect.
  function lurek.draw()
    -- ... (world drawing with camera transforms) ...
    lurek.render.origin()
    lurek.render.print("FPS: 60", 8, 8)  -- always at top-left of screen
  end
end

--@api-stub: lurek.render.applyTransform
-- Multiplies the current transformation matrix by a 3x3 matrix (9 values in row-major order)
do
  -- For advanced use: apply a pre-computed 3x3 affine matrix directly.
  -- Row-major order: {m11, m12, m13, m21, m22, m23, m31, m32, m33}
  -- The bottom row is typically {0, 0, 1} for 2D affine transforms.
  function lurek.draw()
    lurek.render.push()
      -- Identity with 2x scale: {2,0,0, 0,2,0, 0,0,1}
      lurek.render.applyTransform({2, 0, 0, 0, 2, 0, 0, 0, 1})
      lurek.render.rectangle("fill", 10, 10, 20, 20)
    lurek.render.pop()
  end
end

-- =============================================================================
-- SCISSOR (CLIPPING)
-- =============================================================================

--@api-stub: lurek.render.setScissor
-- Sets or clears the scissor rectangle
do
  -- Only pixels inside the scissor rect are drawn. Everything else is clipped.
  -- Pass no args or nil to clear the scissor and allow full-screen drawing.
  -- Essential for scroll views, inventory panels, and minimap regions.
  function lurek.draw()
    lurek.render.setScissor(40, 40, 200, 100)
    -- This fills the whole screen, but only the scissor region is visible
    lurek.render.rectangle("fill", 0, 0, 800, 600)
    lurek.render.setScissor()  -- clear scissor
  end
end

--@api-stub: lurek.render.getScissor
-- Returns the current scissor rectangle, or nothing if no scissor is set
do
  local x, y, w, h = lurek.render.getScissor()
  if x then
    lurek.log.debug("scissor active at " .. x .. "," .. y .. " size " .. w .. "x" .. h)
  end
end

--@api-stub: lurek.render.intersectScissor
-- Intersects the given rectangle with the current scissor, narrowing the drawable region
do
  -- Narrows an existing scissor. Useful for nested UI panels that each clip further.
  function lurek.draw()
    lurek.render.setScissor(0, 0, 400, 300)        -- outer panel
    lurek.render.intersectScissor(100, 50, 200, 150) -- inner content area
    lurek.render.rectangle("fill", 0, 0, 800, 600)  -- only the intersection shows
    lurek.render.setScissor()
  end
end

-- =============================================================================
-- COLOR MASK
-- =============================================================================

--@api-stub: lurek.render.setColorMask
-- Sets which color channels are written during draw calls
do
  -- Disable channels to create special effects or write only to specific buffers.
  -- For example, write only red channel for a thermal-vision overlay.
  function lurek.draw()
    lurek.render.setColorMask(true, false, false, true)  -- red + alpha only
    lurek.render.rectangle("fill", 0, 0, 100, 100)
    lurek.render.setColorMask(true, true, true, true)    -- restore all channels
  end
end

--@api-stub: lurek.render.getColorMask
-- Returns the current color write mask
do
  local r, g, b, a = lurek.render.getColorMask()
  lurek.log.debug("mask: R=" .. tostring(r) .. " G=" .. tostring(g) .. " B=" .. tostring(b) .. " A=" .. tostring(a))
end

-- =============================================================================
-- WIREFRAME
-- =============================================================================

--@api-stub: lurek.render.setWireframe
-- Enables or disables wireframe rendering mode
do
  -- Wireframe shows triangle edges for all filled geometry.
  -- Useful as a debug visualization toggle.
  local debug_wireframe = false
  function lurek.keypressed(key)
    if key == "f3" then
      debug_wireframe = not debug_wireframe
      lurek.render.setWireframe(debug_wireframe)
    end
  end
end

--@api-stub: lurek.render.isWireframe
-- Returns whether wireframe rendering is currently active
do
  if lurek.render.isWireframe() then
    lurek.log.warn("wireframe mode is ON — remember to disable for release")
  end
end

-- =============================================================================
-- STENCIL BUFFER
-- =============================================================================

--@api-stub: lurek.render.stencil
-- Begins a stencil write pass with the given action and reference value
do
  -- Stencils let you mask drawing regions with arbitrary shapes.
  -- Step 1: Write a shape into the stencil buffer with stencil("replace", 1).
  -- Step 2: Set a stencil test so only pixels matching the stencil are drawn.
  -- Classic use: circular viewport, spotlight mask, portal windows.
  function lurek.draw()
    -- Write a circle into the stencil buffer
    lurek.render.stencil("replace", 1)
    lurek.render.circle("fill", 400, 300, 100)
    -- Now only draw where stencil == 1 (inside the circle)
    lurek.render.setStencilTest("equal", 1)
    lurek.render.rectangle("fill", 0, 0, 800, 600)  -- only circular region shows
    lurek.render.setStencilTest()  -- disable test
  end
end

--@api-stub: lurek.render.setStencilTest
-- Configures the stencil comparison test for subsequent draws
do
  -- compare: "equal", "notequal", "less", "greater", "lequal", "gequal", "always", "never"
  -- Pass nil or no args to disable the stencil test.
  function lurek.draw()
    lurek.render.setStencilTest("greater", 0)  -- draw only where stencil > 0
    lurek.render.rectangle("fill", 0, 0, 64, 64)
    lurek.render.setStencilTest()               -- disable
  end
end

--@api-stub: lurek.render.setStencilMode
-- Sets the stencil write action, compare function, and reference value at once
do
  -- Combines the stencil write action with comparison in one call.
  -- Actions: "keep", "zero", "replace", "increment", "decrement", "invert"
  function lurek.draw()
    lurek.render.setStencilMode("replace", "always", 1)
    lurek.render.circle("fill", 100, 100, 50)  -- writes 1 into stencil
  end
end

--@api-stub: lurek.render.getStencilMode
-- Returns the current stencil action, compare mode, and reference value
do
  local action, compare, value = lurek.render.getStencilMode()
  lurek.log.debug("stencil: " .. tostring(action) .. " " .. tostring(compare) .. " ref=" .. tostring(value))
end

--@api-stub: lurek.render.clearStencil
-- Resets the stencil state to defaults (no stencil operations)
do
  -- Call between stencil passes to reset the buffer for a new mask shape.
  function lurek.draw()
    lurek.render.clearStencil()
    -- Now ready for a fresh stencil write
    lurek.render.stencil("replace", 1)
    lurek.render.rectangle("fill", 50, 50, 100, 100)
  end
end

-- =============================================================================
-- DEPTH BUFFER
-- =============================================================================

--@api-stub: lurek.render.setDepthMode
-- Sets the depth comparison mode and whether depth writes are enabled
do
  -- Depth modes: "always", "never", "less", "lequal", "equal", "notequal", "greater", "gequal"
  -- Use depth for layered 2D (isometric) or 2.5D rendering with proper occlusion.
  function lurek.init()
    lurek.render.setDepthMode("lequal", true)
  end
end

--@api-stub: lurek.render.getDepthMode
-- Returns the current depth comparison mode and write-enable flag
do
  local cmp, write = lurek.render.getDepthMode()
  lurek.log.debug("depth: mode=" .. tostring(cmp) .. " write=" .. tostring(write))
end

-- =============================================================================
-- SCREEN DIMENSIONS
-- =============================================================================

--@api-stub: lurek.render.getWidth
-- Returns the current window width in pixels
do
  local w = lurek.render.getWidth()
  lurek.log.info("screen width: " .. tostring(w) .. "px")
end

--@api-stub: lurek.render.getHeight
-- Returns the current window height in pixels
do
  local h = lurek.render.getHeight()
  lurek.log.info("screen height: " .. tostring(h) .. "px")
end

--@api-stub: lurek.render.getDimensions
-- Returns the current window width and height
do
  -- Use for responsive layouts, centering, and aspect-ratio calculations.
  local w, h = lurek.render.getDimensions()
  local cx, cy = w / 2, h / 2  -- screen center
  function lurek.draw()
    lurek.render.print("CENTER", cx - 20, cy)
  end
end

-- =============================================================================
-- TEXTURE FILTERING
-- =============================================================================

--@api-stub: lurek.render.setDefaultFilter
-- Sets the default texture filtering mode for newly created images
do
  -- "nearest" preserves pixel art crispness; "linear" smooths scaled images.
  -- Set once in init() before loading any images.
  -- Anisotropy improves quality at oblique angles (default 1).
  function lurek.init()
    lurek.render.setDefaultFilter("nearest", "nearest")  -- pixel art game
  end
end

--@api-stub: lurek.render.getDefaultFilter
-- Returns the current default texture filtering settings
do
  local min_f, mag_f, aniso = lurek.render.getDefaultFilter()
  lurek.log.debug("filter: min=" .. min_f .. " mag=" .. mag_f .. " aniso=" .. tostring(aniso))
end

-- =============================================================================
-- RENDER STATISTICS
-- =============================================================================

--@api-stub: lurek.render.getStats
-- Returns a table of rendering statistics for the current frame
do
  -- Provides draw call count, texture switches, batching efficiency, etc.
  -- Display in a debug overlay to monitor rendering performance.
  local stats = lurek.render.getStats()
  lurek.log.info("draw calls: " .. tostring(stats.drawcalls) ..
                 ", batched: " .. tostring(stats.batched_draws) ..
                 ", tex switches: " .. tostring(stats.texture_switches))
end

-- =============================================================================
-- SCREENSHOTS
-- =============================================================================

--@api-stub: lurek.render.saveScreenshot
-- Saves a screenshot of the current frame to a file under the save/ directory
do
  -- Path must start with "save/" (writes to the game's save directory).
  -- Useful for automated testing, user-triggered photo mode, or thumbnails.
  function lurek.keypressed(key)
    if key == "f12" then
      lurek.render.saveScreenshot("screenshots/capture.png")
    end
  end
end

--@api-stub: lurek.render.captureScreenshot
-- Captures a screenshot as ImageData and passes it to a callback (stub: returns 1x1 placeholder)
do
  -- The callback receives an LImageData you can process (diff, resize, etc.).
  -- Use for in-game photo albums or thumbnail generation.
  function lurek.init()
    lurek.render.captureScreenshot(function(data)
      lurek.log.info("captured image: " .. data:getWidth() .. "x" .. data:getHeight())
    end)
  end
end

-- =============================================================================
-- NINE-SLICE UI
-- =============================================================================

--@api-stub: lurek.render.newNineSlice
-- Creates a 9-slice definition from an image and four border insets for scalable UI rendering
do
  -- 9-slice keeps corners and borders pixel-perfect while stretching the center.
  -- Insets: top, right, bottom, left — defines the non-stretched border regions.
  -- Perfect for buttons, panels, dialog boxes, and inventory slots.
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then
      panel = lurek.render.newNineSlice(img, 8, 8, 8, 8)  -- 8px borders
    end
  end
end

--@api-stub: lurek.render.drawNineSlice
-- Draws a 9-slice image stretched to fill the given rectangle, keeping borders unscaled
do
  -- The center stretches to fill (x, y, w, h) while borders stay crisp.
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
  function lurek.draw()
    if panel then
      lurek.render.drawNineSlice(panel, 50, 50, 300, 150)  -- scalable dialog box
    end
  end
end

-- =============================================================================
-- RETAINED SHAPES
-- =============================================================================

--@api-stub: lurek.render.newShape
-- Creates a new retained compound shape for accumulating draw commands
do
  -- Shapes store drawing commands and replay them via shape:draw().
  -- Build complex vector art once, then render it at different positions/scales.
  local icon
  function lurek.init()
    icon = lurek.render.newShape()
    icon:setColor(1, 0.8, 0, 1)
    icon:circle("fill", 16, 16, 12)
    icon:setColor(0, 0, 0, 1)
    icon:line(10, 16, 22, 16)  -- horizontal line through circle
  end
  function lurek.draw()
    icon:draw(100, 100)        -- draw at (100, 100)
    icon:draw(200, 100, 0, 2, 2)  -- draw again at 2x scale
  end
end

-- =============================================================================
-- DRAW LAYERS (Z-SORTED CALLBACKS)
-- =============================================================================

--@api-stub: lurek.render.newDrawLayer
-- Creates a new z-ordered draw layer for sorting draw callbacks by depth
do
  -- DrawLayers queue callbacks with z-depth values, then flush them in sorted order.
  -- Use for isometric games where sprite draw order depends on Y position.
  local layer
  function lurek.init()
    layer = lurek.render.newDrawLayer()
  end
  function lurek.draw()
    -- Queue sprites at different depths (lower z draws first / behind)
    layer:queue(10, function() lurek.render.rectangle("fill", 50, 50, 32, 32) end)
    layer:queue(5, function() lurek.render.rectangle("fill", 60, 60, 32, 32) end)
    layer:flush()  -- draws z=5 first, then z=10 on top
  end
end

-- =============================================================================
-- BEZIER CURVES
-- =============================================================================

--@api-stub: lurek.render.drawQuadBezier
-- Draws a quadratic Bezier curve through start, control, and end points
do
  -- Quadratic Bezier: 1 control point pulls the curve in its direction.
  -- segments parameter controls smoothness (more = smoother but more expensive).
  -- Use for curved UI connectors, speech bubble tails, or smooth paths.
  function lurek.draw()
    lurek.render.setColor(0, 1, 1, 1)
    lurek.render.drawQuadBezier(
      50, 200,   -- start
      150, 50,   -- control point (pulls curve upward)
      250, 200,  -- end
      32          -- segment count
    )
  end
end

--@api-stub: lurek.render.drawCubicBezier
-- Draws a cubic Bezier curve through start, two control points, and end
do
  -- Cubic Bezier: 2 control points give S-curves and more complex shapes.
  -- Standard in vector graphics (SVG, fonts). Higher segment count = smoother.
  function lurek.draw()
    lurek.render.setColor(1, 0.5, 1, 1)
    lurek.render.drawCubicBezier(
      50, 300,    -- start
      100, 150,   -- control point 1
      200, 450,   -- control point 2
      250, 300,   -- end
      48           -- segment count
    )
  end
end

-- =============================================================================
-- VECTOR PATHS
-- =============================================================================

--@api-stub: lurek.render.drawPath
-- Draws a vector path composed of moveTo, lineTo, quadTo, and cubicTo segments
do
  -- Paths are arrays of coordinate values drawn as connected line segments.
  -- mode: "line" (outline) or "fill" (solid). close: connect last point to first.
  function lurek.draw()
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.drawPath(
      { 100, 100, 150, 60, 200, 100, 180, 160, 120, 160 },
      "line",
      true  -- close the path (connect end to start)
    )
  end
end

-- =============================================================================
-- GRADIENT & COLORED PRIMITIVES
-- =============================================================================

--@api-stub: lurek.render.drawGradientRect
-- Draws a rectangle with a two-color gradient fill
do
  -- Directions: "vertical", "horizontal", "diagDown", "diagUp", "radial"
  -- Colors are tables: {r, g, b [, a]}
  -- Use for sky backgrounds, health bar fills, or button hover effects.
  function lurek.draw()
    -- Sky gradient: light blue at top, dark blue at bottom
    lurek.render.drawGradientRect(0, 0, 800, 400,
      { 0.4, 0.7, 1.0, 1 },    -- top color (light sky blue)
      { 0.05, 0.1, 0.3, 1 },   -- bottom color (dark navy)
      "vertical"
    )
  end
end

--@api-stub: lurek.render.drawColoredPolygon
-- Draws a polygon with per-vertex colors
do
  -- Each vertex gets its own color; the GPU interpolates between them.
  -- Use for terrain blending, colored mesh previews, or artistic gradients.
  function lurek.draw()
    lurek.render.drawColoredPolygon(
      { 200, 100, 300, 200, 100, 200 },                   -- triangle vertices
      { { 1, 0, 0, 1 }, { 0, 1, 0, 1 }, { 0, 0, 1, 1 } }, -- red, green, blue
      "fill"
    )
  end
end

-- =============================================================================
-- ISOMETRIC & HEX TILES
-- =============================================================================

--@api-stub: lurek.render.drawIsoCubeTile
-- Draws an isometric cube tile with configurable face colors and optional textures
do
  -- Renders a 3-face isometric cube at (sx, sy) with half-width and half-height.
  -- opts: topColor, leftColor, rightColor (each {r,g,b,a}), depth, textures.
  function lurek.draw()
    lurek.render.drawIsoCubeTile(200, 200, 32, 16, {
      topColor   = { 0.5, 0.8, 0.4, 1 },  -- grass top
      leftColor  = { 0.3, 0.5, 0.2, 1 },  -- shaded left
      rightColor = { 0.4, 0.6, 0.3, 1 },  -- lit right
    })
  end
end

--@api-stub: lurek.render.drawHexTile
-- Draws a regular hexagonal tile
do
  -- orientation: "pointyTop" (default) or "flatTop"
  -- mode: "line" (default) or "fill"
  -- Use for hex-grid strategy games, terrain maps, or board games.
  function lurek.draw()
    lurek.render.setColor(0.3, 0.5, 0.8, 1)
    lurek.render.drawHexTile(200, 200, 32, "pointyTop", "fill")
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.drawHexTile(200, 200, 32, "pointyTop", "line")  -- outline
  end
end

-- =============================================================================
-- SORT GROUPS (DEPTH SORTING)
-- =============================================================================

--@api-stub: lurek.render.beginSortGroup
-- Begins a depth-sorted rendering group
do
  -- Sort groups collect draw calls and reorder them by pushSortKey before flushing.
  -- Use for isometric games where objects at lower Y should be drawn behind.
  function lurek.draw()
    lurek.render.beginSortGroup(1)
      lurek.render.pushSortKey(10)
      lurek.render.setColor(1, 0, 0, 1)
      lurek.render.rectangle("fill", 50, 50, 32, 32)  -- drawn second (on top)
      lurek.render.pushSortKey(5)
      lurek.render.setColor(0, 0, 1, 1)
      lurek.render.rectangle("fill", 60, 60, 32, 32)  -- drawn first (behind)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.pushSortKey
-- Sets the depth sort key for subsequent draw calls within the current sort group
do
  -- Lower values are drawn first (further back). Change the key between draw calls.
  function lurek.draw()
    lurek.render.beginSortGroup(1)
      lurek.render.pushSortKey(0)   -- background layer
      lurek.render.rectangle("fill", 0, 0, 800, 600)
      lurek.render.pushSortKey(100) -- foreground layer
      lurek.render.circle("fill", 400, 300, 30)
    lurek.render.flushSortGroup(1)
  end
end

--@api-stub: lurek.render.flushSortGroup
-- Ends a sort group and emits all accumulated draw calls in sorted order
do
  -- Must match the ID passed to beginSortGroup.
  -- After flush, the group is cleared and ready to reuse next frame.
  function lurek.draw()
    lurek.render.beginSortGroup(1)
      lurek.render.pushSortKey(1)
      lurek.render.rectangle("fill", 0, 0, 16, 16)
    lurek.render.flushSortGroup(1)
  end
end

-- =============================================================================
-- BEVEL RECTANGLES (3D-STYLE UI)
-- =============================================================================

--@api-stub: lurek.render.drawBevelRect
-- Draws a beveled rectangle with highlight, shadow, and fill colors for 3D-style UI elements
do
  -- Styles: "raised", "sunken", "ridge", "groove", "flat"
  -- opts: highlight, shadow, fillColor — each a {r,g,b,a} table.
  -- Classic for retro UI panels, buttons, and toolbar borders.
  function lurek.draw()
    lurek.render.drawBevelRect(50, 50, 200, 80, 4, "raised", {
      highlight = { 1, 1, 1, 0.5 },
      shadow    = { 0, 0, 0, 0.5 },
      fillColor = { 0.6, 0.6, 0.6, 1 },
    })
    lurek.render.drawBevelRect(50, 150, 200, 80, 4, "sunken")
  end
end

-- =============================================================================
-- COMPOSITING LAYERS
-- =============================================================================

--@api-stub: lurek.render.pushLayer
-- Begins a compositing layer with the given alpha and blend mode
do
  -- Compositing layers group draw calls and apply alpha/blend as a unit.
  -- Use for fade-in UI panels, semi-transparent HUDs, or additive overlays.
  -- Must be paired with popLayer using the same ID.
  function lurek.draw()
    lurek.render.pushLayer(1, 0.5, "alpha")  -- 50% opacity group
      lurek.render.setColor(1, 1, 1, 1)
      lurek.render.print("This entire block is 50% transparent", 10, 10)
      lurek.render.rectangle("fill", 10, 30, 100, 20)
    lurek.render.popLayer(1)
  end
end

--@api-stub: lurek.render.popLayer
-- Ends a compositing layer and composites it with the previous content
do
  -- Flushes and composites the layer's contents onto the underlying surface.
  function lurek.draw()
    lurek.render.pushLayer(2, 0.8)
      lurek.render.rectangle("fill", 0, 0, 64, 64)
    lurek.render.popLayer(2)
  end
end

-- =============================================================================
-- NAMED RENDER LAYERS
-- =============================================================================

--@api-stub: lurek.render.newLayer
-- Creates a named rendering layer with an optional z-order for draw call organization
do
  -- Named layers separate draw calls into logical groups rendered in z-order.
  -- Lower z-order draws first (behind). Use for background, world, HUD separation.
  function lurek.init()
    lurek.render.newLayer("background", -100)
    lurek.render.newLayer("world", 0)
    lurek.render.newLayer("hud", 100)
  end
end

--@api-stub: lurek.render.setLayer
-- Sets the active rendering layer by name
do
  -- All subsequent draw calls go into the named layer until you switch again.
  function lurek.draw()
    lurek.render.setLayer("background")
    lurek.render.rectangle("fill", 0, 0, 800, 600)  -- behind everything
    lurek.render.setLayer("hud")
    lurek.render.print("Score: 999", 10, 10)         -- always on top
  end
end

--@api-stub: lurek.render.currentLayer
-- Returns the name of the currently active rendering layer
do
  local name = lurek.render.currentLayer()
  lurek.log.debug("active layer: " .. tostring(name))
end

--@api-stub: lurek.render.setLayerVisible
-- Sets whether a named rendering layer is visible
do
  -- Toggle layer visibility for debug overlays or pause-screen effects.
  function lurek.init()
    lurek.render.newLayer("debug_overlay", 999)
    lurek.render.setLayerVisible("debug_overlay", false)  -- hidden by default
  end
end

--@api-stub: lurek.render.isLayerVisible
-- Returns whether a named rendering layer is currently visible
do
  if lurek.render.isLayerVisible("hud") then
    lurek.log.debug("HUD layer is visible")
  end
end

--@api-stub: lurek.render.getLayerZOrder
-- Returns the z-order value of a named rendering layer
do
  local z = lurek.render.getLayerZOrder("hud")
  lurek.log.debug("hud z-order: " .. tostring(z))
end

--@api-stub: lurek.render.setLayerZOrder
-- Sets the z-order value of a named rendering layer
do
  -- Dynamically reorder layers: bring a pause overlay above everything.
  function lurek.init()
    lurek.render.newLayer("pause_overlay", 0)
  end
  function lurek.keypressed(key)
    if key == "escape" then
      lurek.render.setLayerZOrder("pause_overlay", 9999)
    end
  end
end

-- =============================================================================
-- IMAGEDATA METHODS
-- =============================================================================

--@api-stub: ImageData:getWidth
-- Returns the width of this image data.
do
  local data = lurek.image.newImageData(64, 64)
  lurek.log.debug("imagedata width: " .. tostring(data:getWidth()))
end

--@api-stub: ImageData:getHeight
-- Returns the height of this image data.
do
  local data = lurek.image.newImageData(64, 64)
  lurek.log.debug("imagedata height: " .. tostring(data:getHeight()))
end

--@api-stub: ImageData:resize
-- Performs the resize operation on this image data.
do
  -- Creates a new ImageData resized using bilinear sampling.
  -- Use for thumbnail generation or texture mip creation.
  local data = lurek.image.newImageData(128, 128)
  if data then
    local thumb = data:resize(32, 32)
    lurek.log.info("resized to 32x32")
  end
end

--@api-stub: ImageData:diff
-- Performs the diff operation on this image data.
do
  -- Computes total pixel difference between two same-sized images.
  -- Returns 0 if identical. Use for screenshot regression tests.
  local a = lurek.image.newImageData(64, 64)
  local b = lurek.image.newImageData(64, 64)
  if a and b then
    local diff_score = a:diff(b)
    lurek.log.debug("diff score: " .. tostring(diff_score))
  end
end

--@api-stub: ImageData:mapPixels
-- Performs the map pixels operation on this image data.
do
  -- Iterates every pixel and replaces its color with the callback's return value.
  -- callback(x, y, r, g, b, a) -> (r, g, b, a)
  -- Use for color inversion, tinting, or procedural texture generation.
  local data = lurek.image.newImageData(64, 64)
  if data then
    data:mapPixels(function(x, y, r, g, b, a)
      return 1 - r, 1 - g, 1 - b, a  -- invert colors
    end)
  end
end

--@api-stub: ImageData:blit
-- Performs the blit operation on this image data.
do
  -- Copies pixels from a source ImageData onto this one at a given offset.
  -- Use for compositing atlas pages or stamping decals.
  local dst = lurek.image.newImageData(128, 128)
  local src = lurek.image.newImageData(32, 32)
  if dst and src then
    dst:blit(src, 10, 10)  -- paste src at (10, 10) on dst
  end
end

--@api-stub: ImageData:getRegion
-- Returns the region of this image data.
do
  -- Extracts a rectangular sub-region as a new ImageData.
  -- Useful for splitting sprite sheets on the CPU side.
  local atlas = lurek.image.newImageData(256, 256)
  if atlas then
    local tile = atlas:getRegion(0, 0, 32, 32)  -- first tile
    if tile then
      lurek.log.debug("tile size: " .. tile:getWidth() .. "x" .. tile:getHeight())
    end
  end
end

-- =============================================================================
-- NINESLICE METHODS
-- =============================================================================

--@api-stub: NineSlice:getInsets
-- Returns the insets of this nine slice.
do
  -- Returns top, right, bottom, left border widths as four numbers.
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then
      local t, r, b, l = panel:getInsets()
      lurek.log.debug("insets: " .. t .. "," .. r .. "," .. b .. "," .. l)
    end
  end
end

--@api-stub: NineSlice:getTextureSize
-- Returns the texture size of this nine slice.
do
  -- Returns the width and height of the underlying source texture.
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then
      local w, h = panel:getTextureSize()
      lurek.log.debug("source texture: " .. w .. "x" .. h)
    end
  end
end

--@api-stub: NineSlice:type
-- Returns the Lua-visible type name string for this nine slice handle.
do
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel then lurek.log.debug(panel:type()) end  -- "LNineSlice"
  end
end

--@api-stub: NineSlice:typeOf
-- Returns true if this nine slice handle matches the given type name string.
do
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "img/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
    if panel and panel:typeOf("LNineSlice") then
      lurek.log.debug("confirmed NineSlice")
    end
  end
end

--@api-stub: NineSlice:draw
-- Draws or renders this nine slice to the current render target.
do
  -- Convenience draw via drawNineSlice(); renders the 9-slice at given bounds.
  local panel
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "ui/panel.png")
    if ok then panel = lurek.render.newNineSlice(img, 8, 8, 8, 8) end
  end
  function lurek.draw()
    if panel then lurek.render.drawNineSlice(panel, 100, 100, 300, 200) end
  end
end

-- =============================================================================
-- IMAGE METHODS
-- =============================================================================

--@api-stub: Image:getWidth
-- Returns the width of this image.
do
  local img
  function lurek.init()
    img = lurek.render.newImage("img/hero.png")
    lurek.log.debug("image width: " .. img:getWidth() .. "px")
  end
end

--@api-stub: Image:getHeight
-- Returns the height of this image.
do
  local img
  function lurek.init()
    img = lurek.render.newImage("img/hero.png")
    lurek.log.debug("image height: " .. img:getHeight() .. "px")
  end
end

--@api-stub: Image:getDimensions
-- Returns the dimensions of this image.
do
  -- Returns width and height in one call — convenient for origin calculations.
  local img
  function lurek.init()
    img = lurek.render.newImage("img/hero.png")
    local w, h = img:getDimensions()
    lurek.log.debug("image: " .. w .. "x" .. h)
  end
end

--@api-stub: Image:release
-- Performs the release operation on this image.
do
  -- Frees the GPU texture memory. The handle is invalid after this call.
  -- Call in lurek.quit() for large textures, or when swapping level art.
  local img
  function lurek.init() img = lurek.render.newImage("img/hero.png") end
  function lurek.quit() if img then img:release() end end
end

--@api-stub: Image:typeOf
-- Returns true if this image handle matches the given type name string.
do
  local img
  function lurek.init()
    img = lurek.render.newImage("img/hero.png")
    if img:typeOf("LImage") then lurek.log.debug("confirmed Image type") end
  end
end

--@api-stub: Image:type
-- Returns the Lua-visible type name string for this image handle.
do
  local img
  function lurek.init()
    img = lurek.render.newImage("img/hero.png")
    lurek.log.debug("type: " .. img:type())  -- "LImage"
  end
end

--@api-stub: LImage:getId
-- Returns the internal numeric handle ID for this image
do
  -- Opaque handle identifier for internal tracking or debug logging.
  local ok, img = pcall(lurek.render.newImage, "assets/textures/placeholder.png")
  if ok and img then
    lurek.log.info("texture handle ID: " .. tostring(img:getId()))
  end
end

-- =============================================================================
-- FONT METHODS
-- =============================================================================

--@api-stub: Font:getWidth
-- Returns the width of this font.
do
  -- Measures the pixel width of a string. Use for button sizing and centering.
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    local w = f:getWidth("Hello, World!")
    lurek.log.debug("text width: " .. w .. "px")
  end
end

--@api-stub: Font:getHeight
-- Returns the height of this font.
do
  -- Returns the line height in pixels. Use for vertical text layout.
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    lurek.log.debug("font height: " .. f:getHeight() .. "px")
  end
end

--@api-stub: Font:getLineHeight
-- Returns the line height of this font.
do
  -- Line height = vertical distance between baselines of consecutive lines.
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    lurek.log.debug("line height: " .. f:getLineHeight())
  end
end

--@api-stub: Font:setLineHeight
-- Sets the line height of this font.
do
  -- Override the default line spacing for tighter or looser text layout.
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    f:setLineHeight(24)  -- force 24px between lines
  end
end

--@api-stub: Font:getAscent
-- Returns the ascent of this font.
do
  -- Ascent = pixels above baseline (uppercase letter tops).
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    lurek.log.debug("ascent: " .. tostring(f:getAscent()) .. "px")
  end
end

--@api-stub: Font:getDescent
-- Returns the descent of this font.
do
  -- Descent = pixels below baseline (tails of g, p, y).
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    lurek.log.debug("descent: " .. tostring(f:getDescent()) .. "px")
  end
end

--@api-stub: Font:getWrap
-- Returns the wrap of this font.
do
  -- Word-wraps text to a pixel width. Returns (lines, widest_line_width).
  -- Use to pre-calculate dialog box dimensions.
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 14)
    local lines, widest = f:getWrap("A long sentence that must be wrapped.", 120)
    lurek.log.debug("wrapped to " .. #lines .. " lines, widest=" .. tostring(widest))
  end
end

--@api-stub: Font:release
-- Performs the release operation on this font.
do
  -- Frees the font GPU resource. The handle is invalid after release.
  local f
  function lurek.init() f = lurek.render.newFont("assets/fonts/Inter.ttf", 18) end
  function lurek.quit() if f then f:release() end end
end

--@api-stub: Font:typeOf
-- Returns true if this font handle matches the given type name string.
do
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    if f:typeOf("LFont") then lurek.log.debug("confirmed Font type") end
  end
end

--@api-stub: Font:type
-- Returns the Lua-visible type name string for this font handle.
do
  local f
  function lurek.init()
    f = lurek.render.newFont("assets/fonts/Inter.ttf", 18)
    lurek.log.debug("type: " .. f:type())  -- "LFont"
  end
end

-- =============================================================================
-- CANVAS METHODS
-- =============================================================================

--@api-stub: Canvas:getWidth
-- Returns the width of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    lurek.log.debug("canvas width: " .. c:getWidth())
  end
end

--@api-stub: Canvas:getHeight
-- Returns the height of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    lurek.log.debug("canvas height: " .. c:getHeight())
  end
end

--@api-stub: Canvas:getDimensions
-- Returns the dimensions of this canvas.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    local w, h = c:getDimensions()
    lurek.log.debug("canvas: " .. w .. "x" .. h)
  end
end

--@api-stub: Canvas:release
-- Performs the release operation on this canvas.
do
  -- Frees the GPU render target. Use when switching levels or resizing.
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
    if c:typeOf("LCanvas") then lurek.log.debug("confirmed Canvas type") end
  end
end

--@api-stub: Canvas:type
-- Returns the Lua-visible type name string for this canvas handle.
do
  local c
  function lurek.init()
    c = lurek.render.newCanvas(320, 240)
    lurek.log.debug("type: " .. c:type())  -- "LCanvas"
  end
end

-- =============================================================================
-- SPRITEBATCH METHODS
-- =============================================================================

--@api-stub: SpriteBatch:add
-- Adds a sprite entry to this sprite batch.
do
  -- Parameters: x, y, rotation, scaleX, scaleY, originX, originY
  -- Returns the index of the added entry (useful for later updates).
  local batch
  function lurek.init()
    local ok, img = pcall(lurek.render.newImage, "sprites/hero.png")
    if ok then
      batch = lurek.render.newSpriteBatch(img, 256)
      local idx = batch:add(100, 200, 0, 1, 1, 16, 16)
      lurek.log.info("added sprite at index " .. tostring(idx))
    end
  end
end

--@api-stub: SpriteBatch:clear
-- Clears all items from this sprite batch.
do
  -- Call each frame before rebuilding the batch with updated positions.
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 1024)
  end
  function lurek.process(dt)
    batch:clear()
    -- Re-add visible tiles based on camera position...
  end
end

--@api-stub: SpriteBatch:getCount
-- Returns the total count of items held by this sprite batch.
do
  -- Use for debug stats or to detect when approaching buffer capacity.
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 256)
    batch:add(0, 0)
    batch:add(32, 0)
    lurek.log.debug("batch count: " .. batch:getCount())  -- 2
  end
end

--@api-stub: SpriteBatch:getBufferSize
-- Returns the buffer size of this sprite batch.
do
  -- The maximum number of sprites this batch can hold (set at creation).
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 512)
    lurek.log.debug("capacity: " .. batch:getBufferSize())  -- 512
  end
end

--@api-stub: SpriteBatch:release
-- Performs the release operation on this sprite batch.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 256)
  end
  function lurek.quit() if batch then batch:release() end end
end

--@api-stub: SpriteBatch:typeOf
-- Returns true if this sprite batch handle matches the given type name string.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 64)
    if batch:typeOf("LSpriteBatch") then lurek.log.debug("confirmed SpriteBatch") end
  end
end

--@api-stub: SpriteBatch:type
-- Returns the Lua-visible type name string for this sprite batch handle.
do
  local batch
  function lurek.init()
    batch = lurek.render.newSpriteBatch(lurek.render.newImage("img/tiles.png"), 64)
    lurek.log.debug("type: " .. batch:type())  -- "LSpriteBatch"
  end
end

-- =============================================================================
-- MESH METHODS
-- =============================================================================

--@api-stub: Mesh:getVertexCount
-- Returns the number of vertex items in this mesh.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
    lurek.log.debug("vertex count: " .. m:getVertexCount())  -- 3
  end
end

--@api-stub: Mesh:getVertex
-- Returns the vertex of this mesh.
do
  -- Returns x, y, u, v, r, g, b, a for the vertex at the given 1-based index.
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 0, 0, 1 },
      { 64, 0, 1, 0, 0, 1, 0, 1 },
      { 32, 64, 0.5, 1, 0, 0, 1, 1 },
    })
    local x, y, u, v, r, g, b, a = m:getVertex(1)
    lurek.log.debug("v1 pos: " .. tostring(x) .. "," .. tostring(y))
  end
end

--@api-stub: Mesh:setVertex
-- Sets the vertex of this mesh.
do
  -- Update vertex data at runtime for deformable surfaces or animations.
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
  end
  function lurek.process(dt)
    -- Animate the top vertex up and down
    local offset = math.sin(lurek.timer.getTime() * 2) * 10
    m:setVertex(3, { 32, 64 + offset, 0.5, 1, 1, 1, 1, 1 })
  end
end

--@api-stub: Mesh:setTexture
-- Sets the texture of this mesh.
do
  -- Assign a texture for UV-mapped rendering. Pass nil to clear.
  local m, tex
  function lurek.init()
    tex = lurek.render.newImage("img/sheet.png")
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
    m:setTexture(tex)  -- UVs now sample from sheet.png
  end
end

--@api-stub: Mesh:release
-- Performs the release operation on this mesh.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
  end
  function lurek.quit() if m then m:release() end end
end

--@api-stub: Mesh:typeOf
-- Returns true if this mesh handle matches the given type name string.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
    if m:typeOf("LMesh") then lurek.log.debug("confirmed Mesh type") end
  end
end

--@api-stub: Mesh:type
-- Returns the Lua-visible type name string for this mesh handle.
do
  local m
  function lurek.init()
    m = lurek.render.newMesh({
      { 0, 0, 0, 0, 1, 1, 1, 1 },
      { 64, 0, 1, 0, 1, 1, 1, 1 },
      { 32, 64, 0.5, 1, 1, 1, 1, 1 },
    })
    lurek.log.debug("type: " .. m:type())  -- "LMesh"
  end
end

-- =============================================================================
-- SHADER METHODS
-- =============================================================================

--@api-stub: Shader:send
-- Sends to the target associated with this shader.
do
  -- Send uniform values to the shader by name. Supports numbers, booleans, tables.
  -- Call each frame for time-based effects or changing parameters.
  local sh
  function lurek.init()
    sh = lurek.render.newShader("// WGSL with uniform 'time'")
  end
  function lurek.process(dt)
    if sh and sh:hasUniform("time") then
      sh:send("time", lurek.timer.getTime())
    end
  end
end

--@api-stub: Shader:hasUniform
-- Returns true if this shader has a uniform.
do
  -- Check before sending to avoid errors on shaders missing expected uniforms.
  local sh
  function lurek.init()
    sh = lurek.render.newShader("// shader source")
    if sh:hasUniform("resolution") then
      local w, h = lurek.render.getDimensions()
      sh:send("resolution", { w, h })
    end
  end
end

--@api-stub: Shader:release
-- Performs the release operation on this shader.
do
  local sh
  function lurek.init() sh = lurek.render.newShader("// shader source") end
  function lurek.quit() if sh then sh:release() end end
end

--@api-stub: Shader:typeOf
-- Returns true if this shader handle matches the given type name string.
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader("// shader source")
    if sh:typeOf("LShader") then lurek.log.debug("confirmed Shader type") end
  end
end

--@api-stub: Shader:type
-- Returns the Lua-visible type name string for this shader handle.
do
  local sh
  function lurek.init()
    sh = lurek.render.newShader("// shader source")
    lurek.log.debug("type: " .. sh:type())  -- "LShader"
  end
end

-- =============================================================================
-- QUAD METHODS
-- =============================================================================

--@api-stub: Quad:getViewport
-- Returns the viewport of this quad.
do
  -- Returns x, y, width, height of the quad's rectangle within the source texture.
  local q
  function lurek.init()
    q = lurek.render.newQuad(32, 0, 32, 32, 256, 256)
    local x, y, w, h = q:getViewport()
    lurek.log.debug("quad viewport: " .. x .. "," .. y .. " " .. w .. "x" .. h)
  end
end

--@api-stub: Quad:getTextureDimensions
-- Returns the texture dimensions of this quad.
do
  -- Returns the full source texture width and height this quad references.
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    local sw, sh = q:getTextureDimensions()
    lurek.log.debug("source texture: " .. sw .. "x" .. sh)
  end
end

--@api-stub: Quad:setViewport
-- Sets the viewport of this quad.
do
  -- Update the quad's source rectangle for animation frame changes.
  -- Cheaper than creating a new Quad every frame.
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
  end
  function lurek.process(dt)
    -- Advance to the next frame in a horizontal strip
    local frame = math.floor(lurek.timer.getTime() * 10) % 8
    q:setViewport(frame * 32, 0, 32, 32)
  end
end

--@api-stub: Quad:typeOf
-- Returns true if this quad handle matches the given type name string.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    if q:typeOf("LQuad") then lurek.log.debug("confirmed Quad type") end
  end
end

--@api-stub: Quad:type
-- Returns the Lua-visible type name string for this quad handle.
do
  local q
  function lurek.init()
    q = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
    lurek.log.debug("type: " .. q:type())  -- "LQuad"
  end
end

-- =============================================================================
-- SHAPE METHODS
-- =============================================================================

--@api-stub: Shape:getCommandCount
-- Returns the number of command items in this shape.
do
  -- Track how complex a retained shape is for debug/performance monitoring.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 50, 50)
    s:circle("fill", 80, 80, 10)
    lurek.log.debug("shape commands: " .. s:getCommandCount())  -- 2
  end
end

--@api-stub: Shape:clear
-- Clears all items from this shape.
do
  -- Reset the shape to rebuild it each frame (for dynamic vector graphics).
  local s
  function lurek.init() s = lurek.render.newShape() end
  function lurek.process(dt)
    s:clear()
    -- Rebuild with current game state...
    s:rectangle("fill", 0, 0, 50, 50)
  end
end

--@api-stub: Shape:setLineWidth
-- Sets the line width of this shape.
do
  -- Affects all subsequent line-mode commands added to this shape.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setLineWidth(3)
    s:line(0, 0, 100, 0)  -- thick line
  end
end

--@api-stub: Shape:setColor
-- Sets the color of this shape.
do
  -- Each shape command uses the color active at the time it was added.
  -- Call setColor between commands to create multi-colored shapes.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(1.0, 0.0, 0.0, 1.0)  -- red
    s:circle("fill", 20, 20, 10)
    s:setColor(0.0, 1.0, 0.0, 1.0)  -- green
    s:circle("fill", 50, 20, 10)
  end
end

--@api-stub: Shape:line
-- Performs the line operation on this shape.
do
  -- Adds a line segment from (x1,y1) to (x2,y2) to the shape.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:line(0, 0, 100, 0)    -- horizontal
    s:line(100, 0, 100, 50)  -- vertical
  end
end

--@api-stub: Shape:polyline
-- Performs the polyline operation on this shape.
do
  -- Adds a connected sequence of line segments from flat x,y pairs.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:polyline(0, 0, 30, 50, 60, 10, 90, 60, 120, 0)  -- zigzag path
  end
end

--@api-stub: Shape:arc
-- Performs the arc operation on this shape.
do
  -- Adds a circular arc to the shape (same params as lurek.render.arc).
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.2, 0.8, 1.0, 1.0)
    s:arc("fill", 60, 60, 40, 0, math.pi * 1.5)
  end
  function lurek.draw() s:draw(100, 100) end
end

--@api-stub: Shape:circle
-- Performs the circle operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(1, 0.4, 0, 1)
    s:circle("fill", 0, 0, 20)  -- circle at shape-local origin
  end
  function lurek.draw() s:draw(200, 200) end
end

--@api-stub: Shape:ellipse
-- Performs the ellipse operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.9, 0.9, 0.2, 1)
    s:ellipse("fill", 0, 0, 40, 15)  -- wide oval
  end
  function lurek.draw() s:draw(300, 200) end
end

--@api-stub: Shape:rectangle
-- Performs the rectangle operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.8, 0.3, 0.1, 1)
    s:rectangle("fill", 0, 0, 80, 40)
  end
  function lurek.draw() s:draw(50, 50) end
end

--@api-stub: Shape:roundedRectangle
-- Performs the rounded rectangle operation on this shape.
do
  -- Adds a rounded rectangle with horizontal (rx) and optional vertical (ry) radius.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.4, 0.7, 0.9, 1)
    s:roundedRectangle("fill", 0, 0, 120, 60, 10, 10)
  end
  function lurek.draw() s:draw(100, 100) end
end

--@api-stub: Shape:polygon
-- Performs the polygon operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.5, 0.2, 0.8, 1)
    s:polygon("fill", 0, 0, 40, -20, 80, 0, 60, 40, 20, 40)  -- pentagon
  end
  function lurek.draw() s:draw(150, 150) end
end

--@api-stub: Shape:triangle
-- Performs the triangle operation on this shape.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0.2, 0.9, 0.4, 1)
    s:triangle("fill", 0, -30, 30, 30, -30, 30)  -- equilateral-ish
  end
  function lurek.draw() s:draw(200, 200) end
end

--@api-stub: Shape:draw
-- Draws or renders this shape to the current render target.
do
  -- Parameters: x, y, rotation, scaleX, scaleY, originX, originY
  -- Replays all accumulated shape commands at the given transform.
  local s
  function lurek.init()
    s = lurek.render.newShape()
    s:setColor(0, 1, 0.5, 1)
    s:rectangle("fill", -25, -25, 50, 50)
  end
  function lurek.draw()
    s:draw(200, 200, math.pi / 4)  -- draw rotated 45 degrees
  end
end

--@api-stub: Shape:typeOf
-- Returns true if this shape handle matches the given type name string.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    if s:typeOf("LShape") then lurek.log.debug("confirmed Shape") end
  end
end

--@api-stub: Shape:type
-- Returns the Lua-visible type name string for this shape handle.
do
  local s
  function lurek.init()
    s = lurek.render.newShape()
    lurek.log.debug("type: " .. s:type())  -- "LShape"
  end
end

-- =============================================================================
-- DRAWLAYER METHODS
-- =============================================================================

--@api-stub: DrawLayer:queue
-- Performs the queue operation on this draw layer.
do
  -- Enqueues a draw callback at the given z-depth.
  -- Callbacks execute sorted by z when flush() is called.
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw()
    dl:queue(10, function() lurek.render.rectangle("fill", 50, 50, 32, 32) end)
    dl:queue(5, function() lurek.render.circle("fill", 66, 66, 20) end)
    dl:flush()  -- circle draws first (z=5), then rectangle (z=10)
  end
end

--@api-stub: DrawLayer:flush
-- Flushes all pending output from this draw layer immediately.
do
  -- Sorts queued callbacks by z-depth and executes them, then empties the queue.
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.draw()
    dl:queue(0, function() lurek.render.rectangle("fill", 0, 0, 800, 600) end)
    dl:flush()
  end
end

--@api-stub: DrawLayer:clear
-- Clears all items from this draw layer.
do
  -- Discard queued callbacks without executing them.
  local dl
  function lurek.init() dl = lurek.render.newDrawLayer() end
  function lurek.process(dt)
    dl:clear()  -- discard stale frame data before queuing new draws
  end
end

--@api-stub: DrawLayer:getCount
-- Returns the total count of items held by this draw layer.
do
  local dl
  function lurek.init()
    dl = lurek.render.newDrawLayer()
    dl:queue(0, function() end)
    dl:queue(1, function() end)
    lurek.log.debug("queued callbacks: " .. dl:getCount())  -- 2
  end
end

--@api-stub: DrawLayer:type
-- Returns the Lua-visible type name string for this draw layer handle.
do
  local dl
  function lurek.init()
    dl = lurek.render.newDrawLayer()
    lurek.log.debug("type: " .. dl:type())  -- "LDrawLayer"
  end
end

--@api-stub: DrawLayer:typeOf
-- Returns true if this draw layer handle matches the given type name string.
do
  local dl
  function lurek.init()
    dl = lurek.render.newDrawLayer()
    if dl:typeOf("LDrawLayer") then lurek.log.debug("confirmed DrawLayer") end
  end
end

-- =============================================================================
-- 3D MODEL LOADING (OBJ)
-- =============================================================================

--@api-stub: lurek.render.loadObj
-- Loads a Wavefront OBJ model file and returns a model handle for projection and rendering
do
  -- Loads .obj files for CPU-side 3D-to-2D projection.
  -- Use for pre-rendered sprites, isometric assets, or model previews.
  local ok, model = pcall(lurek.render.loadObj, "assets/models/ship.obj")
  if ok and model then
    lurek.log.info("loaded OBJ: " .. model:getVertexCount() .. " verts")
  end
end

--@api-stub: lurek.render.loadModel
-- Loads a 3D model file (OBJ format) and returns a handle for 2D projection and sprite rendering
do
  -- Alias for loadObj with a more generic name.
  local ok, mdl = pcall(lurek.render.loadModel, "assets/models/tower.obj")
  if ok and mdl then
    lurek.log.info("model: " .. mdl:getFaceCount() .. " faces")
  end
end

-- =============================================================================
-- OBJ MODEL METHODS
-- =============================================================================

--@api-stub: LObjModel:getVertexCount
-- Returns the number of vertices in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    lurek.log.debug("vertices: " .. model:getVertexCount())
  end
end

--@api-stub: LObjModel:getFaceCount
-- Returns the number of faces (triangles) in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    lurek.log.debug("faces: " .. model:getFaceCount())
  end
end

--@api-stub: LObjModel:getUvCount
-- Returns the number of UV texture coordinates in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    lurek.log.debug("UVs: " .. model:getUvCount())
  end
end

--@api-stub: LObjModel:getNormalCount
-- Returns the number of vertex normals in this OBJ model
do
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    lurek.log.debug("normals: " .. model:getNormalCount())
  end
end

--@api-stub: LObjModel:projectToMesh
-- Projects the OBJ model into 2D vertex data using a virtual camera, returning a table of vertex rows
do
  -- Projects 3D geometry to 2D screen space for rendering as a mesh or sprite.
  -- Camera table: {x, y, z, tx, ty, tz, fov}
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local verts = model:projectToMesh(
      { x = 0, y = 2, z = -5, tx = 0, ty = 0, tz = 0, fov = 60 },
      800, 600
    )
    lurek.log.debug("projected " .. #verts .. " vertex rows")
  end
end

--@api-stub: LObjModel:renderToImage
-- Renders the OBJ model to a GPU texture at the given resolution with optional 90-degree rotation
do
  -- Bakes the model into a sprite image for fast rendering.
  -- rotation: 0-3 (each step = 90 degrees).
  local ok, model = pcall(lurek.render.loadObj, "assets/models/cube.obj")
  if ok and model then
    local sprite = model:renderToImage(128, 128, 0)
    if sprite then
      lurek.log.debug("rendered model to " .. sprite:getWidth() .. "x" .. sprite:getHeight())
    end
  end
end

print("content/examples/render.lua")

-- =============================================================================
-- STUBS: 81 uncovered lurek.render API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LCanvas methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCanvas:getWidth ----------------------------------------------
--@api-stub: LCanvas:getWidth
-- Returns the width of this canvas in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:getWidth()  -- -> number
-- (replace lCanvas_stub with your real LCanvas instance above)

-- ---- Stub: LCanvas:getHeight ---------------------------------------------
--@api-stub: LCanvas:getHeight
-- Returns the height of this canvas in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:getHeight()  -- -> number
-- (replace lCanvas_stub with your real LCanvas instance above)

-- ---- Stub: LCanvas:getDimensions -----------------------------------------
--@api-stub: LCanvas:getDimensions
-- Returns both width and height of this canvas.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:getDimensions()  -- -> number, number
-- (replace lCanvas_stub with your real LCanvas instance above)

-- ---- Stub: LCanvas:release -----------------------------------------------
--@api-stub: LCanvas:release
-- Releases the canvas GPU resource. If this canvas is currently active, drawing reverts to the screen.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:release()  -- -> boolean
-- (replace lCanvas_stub with your real LCanvas instance above)

-- ---- Stub: LCanvas:typeOf ------------------------------------------------
--@api-stub: LCanvas:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:typeOf("hero")  -- -> boolean
-- (replace lCanvas_stub with your real LCanvas instance above)

-- ---- Stub: LCanvas:type --------------------------------------------------
--@api-stub: LCanvas:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCanvas_stub:type()  -- -> string
-- (replace lCanvas_stub with your real LCanvas instance above)

-- -----------------------------------------------------------------------------
-- LDrawLayer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDrawLayer:queue ----------------------------------------------
--@api-stub: LDrawLayer:queue
-- Enqueues a draw callback at the given z-depth. Callbacks execute when flush() is called.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:queue(0, f)
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- ---- Stub: LDrawLayer:flush ----------------------------------------------
--@api-stub: LDrawLayer:flush
-- Sorts all queued callbacks by z-depth and executes them in order, then empties the layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:flush()
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- ---- Stub: LDrawLayer:clear ----------------------------------------------
--@api-stub: LDrawLayer:clear
-- Discards all queued callbacks without executing them.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:clear()
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- ---- Stub: LDrawLayer:getCount -------------------------------------------
--@api-stub: LDrawLayer:getCount
-- Returns the number of callbacks currently queued.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:getCount()  -- -> number
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- ---- Stub: LDrawLayer:type -----------------------------------------------
--@api-stub: LDrawLayer:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:type()  -- -> string
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- ---- Stub: LDrawLayer:typeOf ---------------------------------------------
--@api-stub: LDrawLayer:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDrawLayer_stub:typeOf("hero")  -- -> boolean
-- (replace lDrawLayer_stub with your real LDrawLayer instance above)

-- -----------------------------------------------------------------------------
-- LFont methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LFont:getWidth ------------------------------------------------
--@api-stub: LFont:getWidth
-- Measures the pixel width of a string when rendered with this font.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getWidth("Hello, world!")  -- -> number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:getHeight -----------------------------------------------
--@api-stub: LFont:getHeight
-- Returns the line height of this font in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getHeight()  -- -> number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:getLineHeight -------------------------------------------
--@api-stub: LFont:getLineHeight
-- Returns the spacing between consecutive lines of text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getLineHeight()  -- -> number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:setLineHeight -------------------------------------------
--@api-stub: LFont:setLineHeight
-- Overrides the line height used for multi-line text rendering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:setLineHeight(256)
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:getAscent -----------------------------------------------
--@api-stub: LFont:getAscent
-- Returns the ascent (pixels above the baseline) of this font.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getAscent()  -- -> number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:getDescent ----------------------------------------------
--@api-stub: LFont:getDescent
-- Returns the descent (pixels below the baseline) of this font.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getDescent()  -- -> number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:getWrap -------------------------------------------------
--@api-stub: LFont:getWrap
-- Word-wraps text to fit within a pixel width limit and returns the resulting lines.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:getWrap("Hello, world!", limit)  -- -> table, number
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:release -------------------------------------------------
--@api-stub: LFont:release
-- Releases the font resource. The handle becomes invalid after this call.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:release()  -- -> boolean
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:typeOf --------------------------------------------------
--@api-stub: LFont:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:typeOf("hero")  -- -> boolean
-- (replace lFont_stub with your real LFont instance above)

-- ---- Stub: LFont:type ----------------------------------------------------
--@api-stub: LFont:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lFont_stub:type()  -- -> string
-- (replace lFont_stub with your real LFont instance above)

-- -----------------------------------------------------------------------------
-- LImage methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LImage:getWidth -----------------------------------------------
--@api-stub: LImage:getWidth
-- Returns the width of this image in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:getWidth()  -- -> number
-- (replace lImage_stub with your real LImage instance above)

-- ---- Stub: LImage:getHeight ----------------------------------------------
--@api-stub: LImage:getHeight
-- Returns the height of this image in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:getHeight()  -- -> number
-- (replace lImage_stub with your real LImage instance above)

-- ---- Stub: LImage:getDimensions ------------------------------------------
--@api-stub: LImage:getDimensions
-- Returns both width and height of this image.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:getDimensions()  -- -> number, number
-- (replace lImage_stub with your real LImage instance above)

-- ---- Stub: LImage:release ------------------------------------------------
--@api-stub: LImage:release
-- Releases the GPU memory for this image. The handle becomes invalid after this call.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:release()  -- -> boolean
-- (replace lImage_stub with your real LImage instance above)

-- ---- Stub: LImage:typeOf -------------------------------------------------
--@api-stub: LImage:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:typeOf("hero")  -- -> boolean
-- (replace lImage_stub with your real LImage instance above)

-- ---- Stub: LImage:type ---------------------------------------------------
--@api-stub: LImage:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImage_stub:type()  -- -> string
-- (replace lImage_stub with your real LImage instance above)

-- -----------------------------------------------------------------------------
-- LImageData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LImageData:getWidth -------------------------------------------
--@api-stub: LImageData:getWidth
-- Returns the width of this image data in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:getWidth()  -- -> number
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:getHeight ------------------------------------------
--@api-stub: LImageData:getHeight
-- Returns the height of this image data in pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:getHeight()  -- -> number
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:resize ---------------------------------------------
--@api-stub: LImageData:resize
-- Creates a new ImageData resized to the given dimensions using bilinear sampling.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:resize(64.0, 64.0)  -- -> LImageData
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:blit -----------------------------------------------
--@api-stub: LImageData:blit
-- Copies pixel data from another ImageData onto this one at the specified position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:blit(src_ud, dst_x, dst_y)
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:getRegion ------------------------------------------
--@api-stub: LImageData:getRegion
-- Extracts a rectangular sub-region as a new ImageData.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:getRegion(0.0, 0.0, 64.0, 64.0)  -- -> LImageData
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:diff -----------------------------------------------
--@api-stub: LImageData:diff
-- Computes a numeric difference score between this image and another of the same size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:diff(other_ud)  -- -> number
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:mapPixels ------------------------------------------
--@api-stub: LImageData:mapPixels
-- Iterates over every pixel and replaces its color with the return value of the callback.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:mapPixels(function() end)
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:type -----------------------------------------------
--@api-stub: LImageData:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:type()  -- -> string
-- (replace lImageData_stub with your real LImageData instance above)

-- ---- Stub: LImageData:typeOf ---------------------------------------------
--@api-stub: LImageData:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:typeOf("hero")  -- -> boolean
-- (replace lImageData_stub with your real LImageData instance above)

-- -----------------------------------------------------------------------------
-- LMesh methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMesh:getVertexCount ------------------------------------------
--@api-stub: LMesh:getVertexCount
-- Returns the number of vertices in this mesh.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:getVertexCount()  -- -> number
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:getVertex -----------------------------------------------
--@api-stub: LMesh:getVertex
-- Returns the data for a single vertex by 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:getVertex(1)  -- -> number, number, number, number, number, number, number, number
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:setVertex -----------------------------------------------
--@api-stub: LMesh:setVertex
-- Updates a single vertex by 1-based index. Table format: {x, y, u, v, r, g, b, a}.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:setVertex(1, data)
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:setTexture ----------------------------------------------
--@api-stub: LMesh:setTexture
-- Assigns or removes a texture for this mesh. Pass nil to clear the texture.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:setTexture([ud])
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:release -------------------------------------------------
--@api-stub: LMesh:release
-- Releases the mesh resource. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:release()  -- -> boolean
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:typeOf --------------------------------------------------
--@api-stub: LMesh:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:typeOf("hero")  -- -> boolean
-- (replace lMesh_stub with your real LMesh instance above)

-- ---- Stub: LMesh:type ----------------------------------------------------
--@api-stub: LMesh:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMesh_stub:type()  -- -> string
-- (replace lMesh_stub with your real LMesh instance above)

-- -----------------------------------------------------------------------------
-- LNineSlice methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LNineSlice:getInsets ------------------------------------------
--@api-stub: LNineSlice:getInsets
-- Returns the border insets (top, right, bottom, left) that define the stretchable regions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNineSlice_stub:getInsets()  -- -> number, number, number, number
-- (replace lNineSlice_stub with your real LNineSlice instance above)

-- ---- Stub: LNineSlice:getTextureSize -------------------------------------
--@api-stub: LNineSlice:getTextureSize
-- Returns the pixel dimensions of the underlying source texture.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNineSlice_stub:getTextureSize()  -- -> number, number
-- (replace lNineSlice_stub with your real LNineSlice instance above)

-- ---- Stub: LNineSlice:type -----------------------------------------------
--@api-stub: LNineSlice:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNineSlice_stub:type()  -- -> string
-- (replace lNineSlice_stub with your real LNineSlice instance above)

-- ---- Stub: LNineSlice:typeOf ---------------------------------------------
--@api-stub: LNineSlice:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lNineSlice_stub:typeOf("hero")  -- -> boolean
-- (replace lNineSlice_stub with your real LNineSlice instance above)

-- -----------------------------------------------------------------------------
-- LQuad methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LQuad:getViewport ---------------------------------------------
--@api-stub: LQuad:getViewport
-- Returns the quad's viewport rectangle within the source texture.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQuad_stub:getViewport()  -- -> number, number, number, number
-- (replace lQuad_stub with your real LQuad instance above)

-- ---- Stub: LQuad:setViewport ---------------------------------------------
--@api-stub: LQuad:setViewport
-- Updates the quad's viewport rectangle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQuad_stub:setViewport(0.0, 0.0, 64.0, 64.0)
-- (replace lQuad_stub with your real LQuad instance above)

-- ---- Stub: LQuad:getTextureDimensions ------------------------------------
--@api-stub: LQuad:getTextureDimensions
-- Returns the full dimensions of the source texture this quad references.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQuad_stub:getTextureDimensions()  -- -> number, number
-- (replace lQuad_stub with your real LQuad instance above)

-- ---- Stub: LQuad:typeOf --------------------------------------------------
--@api-stub: LQuad:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQuad_stub:typeOf("hero")  -- -> boolean
-- (replace lQuad_stub with your real LQuad instance above)

-- ---- Stub: LQuad:type ----------------------------------------------------
--@api-stub: LQuad:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lQuad_stub:type()  -- -> string
-- (replace lQuad_stub with your real LQuad instance above)

-- -----------------------------------------------------------------------------
-- LShader methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LShader:send --------------------------------------------------
--@api-stub: LShader:send
-- Sends a uniform value to this shader by name. Supported types: number, boolean, or table (vec2/vec3/vec4).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShader_stub:send("hero", 42)
-- (replace lShader_stub with your real LShader instance above)

-- ---- Stub: LShader:hasUniform --------------------------------------------
--@api-stub: LShader:hasUniform
-- Checks whether this shader declares a uniform with the given name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShader_stub:hasUniform("hero")  -- -> boolean
-- (replace lShader_stub with your real LShader instance above)

-- ---- Stub: LShader:release -----------------------------------------------
--@api-stub: LShader:release
-- Releases the shader resource. If active, the default shader is restored.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShader_stub:release()  -- -> boolean
-- (replace lShader_stub with your real LShader instance above)

-- ---- Stub: LShader:typeOf ------------------------------------------------
--@api-stub: LShader:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShader_stub:typeOf("hero")  -- -> boolean
-- (replace lShader_stub with your real LShader instance above)

-- ---- Stub: LShader:type --------------------------------------------------
--@api-stub: LShader:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShader_stub:type()  -- -> string
-- (replace lShader_stub with your real LShader instance above)

-- -----------------------------------------------------------------------------
-- LShape methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LShape:getCommandCount ----------------------------------------
--@api-stub: LShape:getCommandCount
-- Returns the number of drawing commands accumulated in this shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:getCommandCount()  -- -> number
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:clear --------------------------------------------------
--@api-stub: LShape:clear
-- Removes all drawing commands from this shape, making it empty.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:clear()
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:setColor -----------------------------------------------
--@api-stub: LShape:setColor
-- Sets the drawing color for subsequent shape commands.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:setColor(1.0, 0.8, 0.2, [a])
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:setLineWidth -------------------------------------------
--@api-stub: LShape:setLineWidth
-- Sets the line width for subsequent line-mode shape commands.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:setLineWidth(64.0)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:rectangle ----------------------------------------------
--@api-stub: LShape:rectangle
-- Adds a rectangle command to the shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:rectangle(mode, 0.0, 0.0, 64.0, 64.0)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:roundedRectangle ---------------------------------------
--@api-stub: LShape:roundedRectangle
-- Adds a rounded rectangle command to the shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:roundedRectangle(mode, 0.0, 0.0, 64.0, 64.0, rx, [ry])
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:circle -------------------------------------------------
--@api-stub: LShape:circle
-- Adds a circle command to the shape. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:circle(mode, 0.0, 0.0, 1.0)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:ellipse ------------------------------------------------
--@api-stub: LShape:ellipse
-- Adds an ellipse command to the shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:ellipse(mode, 0.0, 0.0, rx, ry)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:triangle -----------------------------------------------
--@api-stub: LShape:triangle
-- Adds a triangle command to the shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:triangle(mode, x1, y1, x2, y2, x3, y3)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:polygon ------------------------------------------------
--@api-stub: LShape:polygon
-- Adds a polygon command to the shape from a flat list of x,y coordinate pairs.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:polygon(mode, coords)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:line ---------------------------------------------------
--@api-stub: LShape:line
-- Adds a line segment command to the shape.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:line(x1, y1, x2, y2)
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:polyline -----------------------------------------------
--@api-stub: LShape:polyline
-- Adds a connected polyline command to the shape from a flat list of x,y coordinate pairs.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:polyline()
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:arc ----------------------------------------------------
--@api-stub: LShape:arc
-- Adds an arc command to the shape. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:arc()
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:draw ---------------------------------------------------
--@api-stub: LShape:draw
-- Renders the accumulated shape commands to the screen with optional transform.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:draw()
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:typeOf -------------------------------------------------
--@api-stub: LShape:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:typeOf("hero")  -- -> boolean
-- (replace lShape_stub with your real LShape instance above)

-- ---- Stub: LShape:type ---------------------------------------------------
--@api-stub: LShape:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lShape_stub:type()  -- -> string
-- (replace lShape_stub with your real LShape instance above)

-- -----------------------------------------------------------------------------
-- LSpriteBatch methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LSpriteBatch:add ----------------------------------------------
--@api-stub: LSpriteBatch:add
-- Adds a sprite entry to the batch at the given position with optional transform.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:add()  -- -> number
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:clear --------------------------------------------
--@api-stub: LSpriteBatch:clear
-- Removes all entries from the sprite batch.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:clear()
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:getCount -----------------------------------------
--@api-stub: LSpriteBatch:getCount
-- Returns the number of sprite entries currently in the batch.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:getCount()  -- -> number
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:getBufferSize ------------------------------------
--@api-stub: LSpriteBatch:getBufferSize
-- Returns the maximum number of entries this batch can hold.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:getBufferSize()  -- -> number
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:release ------------------------------------------
--@api-stub: LSpriteBatch:release
-- Releases the sprite batch resource.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:release()  -- -> boolean
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:typeOf -------------------------------------------
--@api-stub: LSpriteBatch:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:typeOf("hero")  -- -> boolean
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)

-- ---- Stub: LSpriteBatch:type ---------------------------------------------
--@api-stub: LSpriteBatch:type
-- Returns the internal Lua type tag. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lSpriteBatch_stub:type()  -- -> string
-- (replace lSpriteBatch_stub with your real LSpriteBatch instance above)
