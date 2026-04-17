-- content/examples/render.lua
-- Lurek2D lurek.render API Reference
-- Run with: cargo run -- content/examples/render
--
-- Scenario: A side-scrolling RPG with HUD, tilemaps via sprite batches,
-- custom shaders for water effects, off-screen canvases for minimaps,
-- nine-slice UI panels, layered rendering, and screenshot capture.

print("=== lurek.render — 2D Rendering Pipeline ===\n")

-- =============================================================================
-- Color & Background
-- =============================================================================

--@api-stub: lurek.render.setColor
lurek.render.setColor(1, 1, 1, 1)

--@api-stub: lurek.render.getColor
local r, g, b, a = lurek.render.getColor()
print("color: " .. r .. ", " .. g .. ", " .. b .. ", " .. a)

--@api-stub: lurek.render.setBackgroundColor
lurek.render.setBackgroundColor(0.05, 0.05, 0.15, 1.0)

--@api-stub: lurek.render.getBackgroundColor
local br, bg, bb, ba = lurek.render.getBackgroundColor()
print("background: " .. br .. ", " .. bg .. ", " .. bb)

--@api-stub: lurek.render.clear
lurek.render.clear()

-- =============================================================================
-- Primitive Drawing — shapes, lines, points
-- =============================================================================

--@api-stub: lurek.render.rectangle
-- Draw a filled rectangle (player health bar background).
lurek.render.rectangle("fill", 20, 20, 200, 30)

--@api-stub: lurek.render.circle
-- Draw a filled circle (minimap blip).
lurek.render.circle("fill", 400, 300, 16)

--@api-stub: lurek.render.ellipse
-- Oval shadow under a character.
lurek.render.ellipse("fill", 200, 500, 24, 8)

--@api-stub: lurek.render.triangle
lurek.render.triangle("fill", 100, 100, 130, 60, 160, 100)

--@api-stub: lurek.render.line
-- Draw an aim line from player to crosshair.
lurek.render.line(100, 300, 400, 250)

--@api-stub: lurek.render.polygon
-- Hexagonal tile outline.
lurek.render.polygon("line", {100,50, 150,25, 200,50, 200,100, 150,125, 100,100})

--@api-stub: lurek.render.arc
-- Radial cooldown indicator.
lurek.render.arc("fill", 600, 400, 30, 0, math.pi * 1.5)

--@api-stub: lurek.render.points
-- Particle positions for a simple star field.
lurek.render.points({10,20, 50,80, 120,40, 300,200})

-- ---- Advanced shape drawing -----------------------------------------------

--@api-stub: lurek.render.drawQuadBezier
-- Smooth projectile trail (quadratic Bezier).
lurek.render.drawQuadBezier(50, 300, 200, 100, 350, 300, 20)

--@api-stub: lurek.render.drawCubicBezier
-- S-curve river on the world map.
lurek.render.drawCubicBezier(50, 500, 150, 300, 300, 700, 450, 500, 30)

--@api-stub: lurek.render.drawPath
-- Draw an arbitrary path (NPC patrol route visualization).
lurek.render.drawPath({{100,100}, {200,80}, {300,120}, {350,200}})

--@api-stub: lurek.render.drawGradientRect
-- Sky gradient background behind parallax layers.
lurek.render.drawGradientRect(0, 0, 800, 200,
    {0.2, 0.3, 0.8, 1}, {0.6, 0.8, 1.0, 1})

--@api-stub: lurek.render.drawColoredPolygon
-- Terrain polygon with per-vertex colors.
lurek.render.drawColoredPolygon(
    {{x=0,y=100,r=0,g=0.6,b=0,a=1}, {x=100,y=0,r=0,g=0.8,b=0,a=1}, {x=200,y=100,r=0,g=0.5,b=0,a=1}})

--@api-stub: lurek.render.drawBevelRect
-- Beveled button background for the HUD.
lurek.render.drawBevelRect(500, 20, 120, 40, 6)

-- ---- Isometric & Hex tiles ------------------------------------------------

--@api-stub: lurek.render.drawIsoCubeTile
-- Draw an isometric cube tile for a strategy game grid.
lurek.render.drawIsoCubeTile(400, 200, 64, 32, {0.5, 0.7, 0.3, 1})

--@api-stub: lurek.render.drawHexTile
-- Draw a single hex tile for a hex-grid strategy map.
lurek.render.drawHexTile(500, 200, 30, {0.3, 0.5, 0.7, 1})

-- =============================================================================
-- Line & Point Styles
-- =============================================================================

--@api-stub: lurek.render.setLineWidth
lurek.render.setLineWidth(2.0)

--@api-stub: lurek.render.getLineWidth
print("line width: " .. lurek.render.getLineWidth())

--@api-stub: lurek.render.setPointSize
lurek.render.setPointSize(3.0)

--@api-stub: lurek.render.getPointSize
print("point size: " .. lurek.render.getPointSize())

-- =============================================================================
-- Blend Modes
-- =============================================================================

--@api-stub: lurek.render.setBlendMode
-- Additive blending for fire/glow particles.
lurek.render.setBlendMode("add")

--@api-stub: lurek.render.getBlendMode
print("blend mode: " .. lurek.render.getBlendMode())

-- Reset to default alpha blending.
lurek.render.setBlendMode("alpha")

-- =============================================================================
-- Font & Text
-- =============================================================================

--@api-stub: lurek.render.newFont
-- Load a TTF font for dialogue UI.
local dialog_font = lurek.render.newFont("assets/fonts/pixel.ttf", 16)

--@api-stub: lurek.render.setFont
lurek.render.setFont(dialog_font)

--@api-stub: lurek.render.getFont
local current_font = lurek.render.getFont()

--@api-stub: lurek.render.getDefaultFont
local default_font = lurek.render.getDefaultFont()

--@api-stub: lurek.render.getFontSizes
-- Get available sizes for bitmap font atlas.
local sizes = lurek.render.getFontSizes()
print("font sizes: " .. #sizes)

--@api-stub: lurek.render.getFontCellWidth
print("font cell width: " .. lurek.render.getFontCellWidth())

--@api-stub: lurek.render.getFontWidth
print("font 'Hello' width: " .. lurek.render.getFontWidth("Hello"))

--@api-stub: lurek.render.getFontHeight
print("font height: " .. lurek.render.getFontHeight())

--@api-stub: lurek.render.getFontLineHeight
print("line height: " .. lurek.render.getFontLineHeight())

--@api-stub: lurek.render.setFontLineHeight
lurek.render.setFontLineHeight(20)

--@api-stub: lurek.render.getFontAscent
print("ascent: " .. lurek.render.getFontAscent())

--@api-stub: lurek.render.getFontDescent
print("descent: " .. lurek.render.getFontDescent())

--@api-stub: lurek.render.getFontWrap
-- Wrap text for dialogue boxes (max 300px wide).
local lines, wrapped_w = lurek.render.getFontWrap("A long dialogue line that should wrap...", 300)
print("wrapped to " .. #lines .. " lines, width=" .. wrapped_w)

-- ---- Text drawing ---------------------------------------------------------

--@api-stub: lurek.render.print
-- Draw left-aligned text (NPC name above head).
lurek.render.print("Merchant", 200, 140)

--@api-stub: lurek.render.printf
-- Draw centered text in a dialogue box (width 400, centered).
lurek.render.printf("Welcome to the village!", 100, 400, 400, "center")

--@api-stub: lurek.render.printRich
-- Rich text with inline color/style tags for item tooltips.
lurek.render.printRich("{color=gold}Legendary Sword{/color}\n+50 Attack", 100, 200)

-- =============================================================================
-- Images & Textures
-- =============================================================================

--@api-stub: lurek.render.newImage
-- Load a sprite sheet texture.
local hero_tex = lurek.render.newImage("assets/sprites/hero.png")

--@api-stub: lurek.render.draw
-- Draw the hero sprite at position (200, 300).
lurek.render.draw(hero_tex, 200, 300)

--@api-stub: lurek.render.drawq
-- Draw a sub-region of the sprite sheet via a quad.
-- (quad defined below)

-- =============================================================================
-- Quads — sprite sheet sub-regions
-- =============================================================================

--@api-stub: lurek.render.newQuad
-- Define a 32x32 frame at row 0, col 0 of a 256x256 sprite sheet.
local hero_quad = lurek.render.newQuad(0, 0, 32, 32, 256, 256)

-- Now draw using the quad:
lurek.render.drawq(hero_tex, hero_quad, 200, 300)

-- =============================================================================
-- Canvases — off-screen render targets
-- =============================================================================

--@api-stub: lurek.render.newCanvas
-- Off-screen canvas for the minimap.
local minimap_canvas = lurek.render.newCanvas(200, 200)

--@api-stub: lurek.render.setCanvas
-- Redirect drawing to the minimap canvas.
lurek.render.setCanvas(minimap_canvas)
lurek.render.clear()
lurek.render.setColor(0, 0.5, 0, 1)
lurek.render.rectangle("fill", 0, 0, 200, 200)
lurek.render.setColor(1, 0, 0, 1)
lurek.render.circle("fill", 100, 100, 5)

--@api-stub: lurek.render.getCanvas
local active_canvas = lurek.render.getCanvas()

--@api-stub: lurek.render.getCanvasSize
local cw, ch = lurek.render.getCanvasSize()
print("canvas size: " .. tostring(cw) .. "x" .. tostring(ch))

-- Reset to main screen.
lurek.render.setCanvas()

-- Draw the minimap canvas onto the main screen.
lurek.render.setColor(1, 1, 1, 1)
lurek.render.draw(minimap_canvas, 580, 20)

-- =============================================================================
-- Sprite Batches — fast tilemap rendering
-- =============================================================================

--@api-stub: lurek.render.newSpriteBatch
-- Batch 1000 tile draws into one GPU call.
local tile_batch = lurek.render.newSpriteBatch(hero_tex, 1000)

-- =============================================================================
-- Meshes — custom geometry
-- =============================================================================

--@api-stub: lurek.render.newMesh
-- Create a textured quad mesh (for custom geometry like water surfaces).
local water_mesh = lurek.render.newMesh({
    {0, 0, 0, 0, 1, 1, 1, 1},
    {100, 0, 1, 0, 1, 1, 1, 1},
    {100, 50, 1, 1, 0.5, 0.7, 1, 0.8},
    {0, 50, 0, 1, 0.5, 0.7, 1, 0.8},
}, "fan")

-- =============================================================================
-- Shaders
-- =============================================================================

--@api-stub: lurek.render.newShader
-- Load a custom water ripple shader.
local water_shader = lurek.render.newShader("assets/shaders/water.wgsl")

--@api-stub: lurek.render.setShader
lurek.render.setShader(water_shader)

--@api-stub: lurek.render.getShader
local active_shader = lurek.render.getShader()

-- Draw water with the shader active, then remove it.
lurek.render.draw(water_mesh, 0, 400)
lurek.render.setShader()

-- =============================================================================
-- Nine-Slice — UI panel borders
-- =============================================================================

--@api-stub: lurek.render.newNineSlice
-- Create a nine-slice for dialogue panel frames.
local panel_9s = lurek.render.newNineSlice("assets/ui/panel_frame.png", 8, 8, 8, 8)

--@api-stub: lurek.render.drawNineSlice
-- Draw a panel that stretches to any size without distortion.
lurek.render.drawNineSlice(panel_9s, 50, 350, 300, 150)

-- =============================================================================
-- Shape Builder — batched line/polyline geometry
-- =============================================================================

--@api-stub: lurek.render.newShape
-- Build a complex shape for path visualization.
local path_shape = lurek.render.newShape()

-- =============================================================================
-- Draw Layers — ordered render groups
-- =============================================================================

--@api-stub: lurek.render.newDrawLayer
-- Create a draw layer for deferred rendering.
local ui_layer = lurek.render.newDrawLayer()

--@api-stub: lurek.render.newLayer
-- Create a named rendering layer.
local bg_layer = lurek.render.newLayer("background")

--@api-stub: lurek.render.setLayer
lurek.render.setLayer("background")

--@api-stub: lurek.render.currentLayer
print("current layer: " .. tostring(lurek.render.currentLayer()))

--@api-stub: lurek.render.setLayerVisible
lurek.render.setLayerVisible("background", true)

--@api-stub: lurek.render.isLayerVisible
print("bg visible: " .. tostring(lurek.render.isLayerVisible("background")))

--@api-stub: lurek.render.getLayerZOrder
print("bg z-order: " .. lurek.render.getLayerZOrder("background"))

--@api-stub: lurek.render.setLayerZOrder
lurek.render.setLayerZOrder("background", -10)

-- =============================================================================
-- Sort Groups — depth sorting within a frame
-- =============================================================================

--@api-stub: lurek.render.beginSortGroup
lurek.render.beginSortGroup()

--@api-stub: lurek.render.pushSortKey
-- Push entities by their Y coordinate for painter's algorithm.
lurek.render.pushSortKey(300)
lurek.render.draw(hero_tex, 200, 300)

--@api-stub: lurek.render.flushSortGroup
lurek.render.flushSortGroup()

-- =============================================================================
-- Layer Stack (push/pop for render-to-texture)
-- =============================================================================

--@api-stub: lurek.render.pushLayer
lurek.render.pushLayer(minimap_canvas)

--@api-stub: lurek.render.popLayer
lurek.render.popLayer()

-- =============================================================================
-- Transform Stack
-- =============================================================================

--@api-stub: lurek.render.push
lurek.render.push()

--@api-stub: lurek.render.translate
lurek.render.translate(400, 300)

--@api-stub: lurek.render.rotate
lurek.render.rotate(math.rad(45))

--@api-stub: lurek.render.scale
lurek.render.scale(2.0, 2.0)

--@api-stub: lurek.render.shear
lurek.render.shear(0.1, 0)

--@api-stub: lurek.render.origin
lurek.render.origin()

--@api-stub: lurek.render.applyTransform
-- Apply a custom 2D transform matrix.
lurek.render.applyTransform(1, 0, 0, 1, 100, 50)

--@api-stub: lurek.render.pop
lurek.render.pop()

-- =============================================================================
-- Scissor (clipping) — HUD health bar clip region
-- =============================================================================

--@api-stub: lurek.render.setScissor
lurek.render.setScissor(20, 20, 200, 30)

--@api-stub: lurek.render.getScissor
local sx, sy, sw, sh = lurek.render.getScissor()
print("scissor: " .. sx .. "," .. sy .. " " .. sw .. "x" .. sh)

--@api-stub: lurek.render.intersectScissor
lurek.render.intersectScissor(30, 25, 180, 20)

-- Clear scissor.
lurek.render.setScissor()

-- =============================================================================
-- Color Mask
-- =============================================================================

--@api-stub: lurek.render.setColorMask
-- Write only to the alpha channel (for stencil-like effects).
lurek.render.setColorMask(false, false, false, true)

--@api-stub: lurek.render.getColorMask
local mr, mg, mb, ma = lurek.render.getColorMask()
print("color mask: r=" .. tostring(mr) .. " g=" .. tostring(mg))

-- Restore all channels.
lurek.render.setColorMask(true, true, true, true)

-- =============================================================================
-- Wireframe Mode
-- =============================================================================

--@api-stub: lurek.render.setWireframe
lurek.render.setWireframe(false)

--@api-stub: lurek.render.isWireframe
print("wireframe: " .. tostring(lurek.render.isWireframe()))

-- =============================================================================
-- Stencil Buffer
-- =============================================================================

--@api-stub: lurek.render.stencil
-- Draw a circular stencil mask (for fog-of-war reveal).
lurek.render.stencil(function()
    lurek.render.circle("fill", 400, 300, 100)
end)

--@api-stub: lurek.render.setStencilTest
lurek.render.setStencilTest("greater", 0)

--@api-stub: lurek.render.setStencilMode
lurek.render.setStencilMode("replace", 1)

--@api-stub: lurek.render.getStencilMode
local sm_action, sm_value = lurek.render.getStencilMode()
print("stencil mode: " .. tostring(sm_action) .. " val=" .. tostring(sm_value))

--@api-stub: lurek.render.clearStencil
lurek.render.clearStencil()

-- =============================================================================
-- Depth Mode
-- =============================================================================

--@api-stub: lurek.render.setDepthMode
lurek.render.setDepthMode("lequal", true)

--@api-stub: lurek.render.getDepthMode
local dm_cmp, dm_write = lurek.render.getDepthMode()
print("depth: " .. tostring(dm_cmp) .. " write=" .. tostring(dm_write))

-- =============================================================================
-- Screen Dimensions & Defaults
-- =============================================================================

--@api-stub: lurek.render.getWidth
print("screen width: " .. lurek.render.getWidth())

--@api-stub: lurek.render.getHeight
print("screen height: " .. lurek.render.getHeight())

--@api-stub: lurek.render.getDimensions
local scrw, scrh = lurek.render.getDimensions()
print("screen: " .. scrw .. "x" .. scrh)

--@api-stub: lurek.render.setDefaultFilter
lurek.render.setDefaultFilter("nearest", "nearest")

--@api-stub: lurek.render.getDefaultFilter
local fmin, fmag = lurek.render.getDefaultFilter()
print("filter: min=" .. fmin .. " mag=" .. fmag)

-- =============================================================================
-- Statistics & Screenshots
-- =============================================================================

--@api-stub: lurek.render.getStats
local stats = lurek.render.getStats()
print("draw calls: " .. tostring(stats.drawcalls) .. ", textures: " .. tostring(stats.textures))

--@api-stub: lurek.render.saveScreenshot
lurek.render.saveScreenshot("output/screenshot.png")

--@api-stub: lurek.render.captureScreenshot
local screenshot_data = lurek.render.captureScreenshot()
print("screenshot captured: " .. tostring(screenshot_data))

-- =============================================================================
-- ImageData Object Methods
-- =============================================================================

local img_data = lurek.image.newImageData(64, 64)

--@api-stub: ImageData:getWidth
print("img data width: " .. img_data:getWidth())

--@api-stub: ImageData:getHeight
print("img data height: " .. img_data:getHeight())

--@api-stub: ImageData:resize
img_data:resize(32, 32)
print("resized to 32x32")

--@api-stub: ImageData:mapPixels
img_data:mapPixels(function(x, y, r, g, b, a)
    return x / 32, y / 32, 0.5, 1.0
end)
print("gradient mapped onto image data")

--@api-stub: ImageData:diff
local diff_data = img_data:diff(img_data)
print("diff with self: " .. tostring(diff_data))

--@api-stub: ImageData:type
print("ImageData type: " .. img_data:type())

--@api-stub: ImageData:typeOf
print("is ImageData: " .. tostring(img_data:typeOf("ImageData")))

-- =============================================================================
-- NineSlice Object Methods
-- =============================================================================

--@api-stub: NineSlice:getInsets
local left, top, right, bottom = panel_9s:getInsets()
print("nine-slice insets: " .. left .. "," .. top .. "," .. right .. "," .. bottom)

--@api-stub: NineSlice:getTextureSize
local nsw, nsh = panel_9s:getTextureSize()
print("nine-slice texture: " .. nsw .. "x" .. nsh)

--@api-stub: NineSlice:type
print("NineSlice type: " .. panel_9s:type())

--@api-stub: NineSlice:typeOf
print("is NineSlice: " .. tostring(panel_9s:typeOf("NineSlice")))

-- =============================================================================
-- Image Object Methods
-- =============================================================================

--@api-stub: Image:getWidth
print("hero tex width: " .. hero_tex:getWidth())

--@api-stub: Image:getHeight
print("hero tex height: " .. hero_tex:getHeight())

--@api-stub: Image:getDimensions
local tw, th = hero_tex:getDimensions()
print("hero tex: " .. tw .. "x" .. th)

--@api-stub: Image:type
print("Image type: " .. hero_tex:type())

--@api-stub: Image:typeOf
print("is Image: " .. tostring(hero_tex:typeOf("Image")))

--@api-stub: Image:release
-- Release GPU memory when no longer needed.
-- hero_tex:release()  -- commented: still in use

-- =============================================================================
-- Font Object Methods
-- =============================================================================

--@api-stub: Font:getWidth
print("dialog font 'Hello' width: " .. dialog_font:getWidth("Hello"))

--@api-stub: Font:getHeight
print("dialog font height: " .. dialog_font:getHeight())

--@api-stub: Font:getLineHeight
print("dialog line height: " .. dialog_font:getLineHeight())

--@api-stub: Font:setLineHeight
dialog_font:setLineHeight(1.2)

--@api-stub: Font:getAscent
print("font ascent: " .. dialog_font:getAscent())

--@api-stub: Font:getDescent
print("font descent: " .. dialog_font:getDescent())

--@api-stub: Font:getWrap
local wrap_lines, wrap_w = dialog_font:getWrap("Wrap this text", 200)
print("font wrap: " .. #wrap_lines .. " lines")

--@api-stub: Font:type
print("Font type: " .. dialog_font:type())

--@api-stub: Font:typeOf
print("is Font: " .. tostring(dialog_font:typeOf("Font")))

--@api-stub: Font:release
-- dialog_font:release()  -- commented: still in use

-- =============================================================================
-- Canvas Object Methods
-- =============================================================================

--@api-stub: Canvas:getWidth
print("minimap canvas width: " .. minimap_canvas:getWidth())

--@api-stub: Canvas:getHeight
print("minimap canvas height: " .. minimap_canvas:getHeight())

--@api-stub: Canvas:getDimensions
local mc_w, mc_h = minimap_canvas:getDimensions()
print("minimap canvas: " .. mc_w .. "x" .. mc_h)

--@api-stub: Canvas:type
print("Canvas type: " .. minimap_canvas:type())

--@api-stub: Canvas:typeOf
print("is Canvas: " .. tostring(minimap_canvas:typeOf("Canvas")))

--@api-stub: Canvas:release
-- minimap_canvas:release()  -- commented: still in use

-- =============================================================================
-- SpriteBatch Object Methods
-- =============================================================================

--@api-stub: SpriteBatch:getCount
print("batch count: " .. tile_batch:getCount())

--@api-stub: SpriteBatch:getBufferSize
print("batch buffer: " .. tile_batch:getBufferSize())

--@api-stub: SpriteBatch:clear
tile_batch:clear()
print("batch cleared")

--@api-stub: SpriteBatch:type
print("SpriteBatch type: " .. tile_batch:type())

--@api-stub: SpriteBatch:typeOf
print("is SpriteBatch: " .. tostring(tile_batch:typeOf("SpriteBatch")))

--@api-stub: SpriteBatch:release
-- tile_batch:release()  -- commented: still in use

-- =============================================================================
-- Mesh Object Methods
-- =============================================================================

--@api-stub: Mesh:getVertexCount
print("water mesh vertices: " .. water_mesh:getVertexCount())

--@api-stub: Mesh:getVertex
local vx, vy, vu, vv = water_mesh:getVertex(0)
print("vertex 0: " .. vx .. "," .. vy .. " uv=" .. vu .. "," .. vv)

--@api-stub: Mesh:setVertex
water_mesh:setVertex(0, {0, 0, 0, 0, 1, 1, 1, 1})

--@api-stub: Mesh:setTexture
water_mesh:setTexture(hero_tex)

--@api-stub: Mesh:type
print("Mesh type: " .. water_mesh:type())

--@api-stub: Mesh:typeOf
print("is Mesh: " .. tostring(water_mesh:typeOf("Mesh")))

--@api-stub: Mesh:release
-- water_mesh:release()  -- commented: still in use

-- =============================================================================
-- Shader Object Methods
-- =============================================================================

--@api-stub: Shader:send
-- Send a uniform value (e.g. elapsed time for animation).
water_shader:send("u_time", 1.5)

--@api-stub: Shader:hasUniform
print("has u_time: " .. tostring(water_shader:hasUniform("u_time")))

--@api-stub: Shader:type
print("Shader type: " .. water_shader:type())

--@api-stub: Shader:typeOf
print("is Shader: " .. tostring(water_shader:typeOf("Shader")))

--@api-stub: Shader:release
-- water_shader:release()  -- commented: still in use

-- =============================================================================
-- Quad Object Methods
-- =============================================================================

--@api-stub: Quad:getViewport
local qx, qy, qw, qh = hero_quad:getViewport()
print("quad viewport: " .. qx .. "," .. qy .. " " .. qw .. "x" .. qh)

--@api-stub: Quad:getTextureDimensions
local qtw, qth = hero_quad:getTextureDimensions()
print("quad tex: " .. qtw .. "x" .. qth)

--@api-stub: Quad:type
print("Quad type: " .. hero_quad:type())

--@api-stub: Quad:typeOf
print("is Quad: " .. tostring(hero_quad:typeOf("Quad")))

-- =============================================================================
-- Shape Object Methods
-- =============================================================================

--@api-stub: Shape:getCommandCount
print("shape commands: " .. path_shape:getCommandCount())

--@api-stub: Shape:setLineWidth
path_shape:setLineWidth(2.0)

--@api-stub: Shape:line
path_shape:line(0, 0, 100, 100)

--@api-stub: Shape:polyline
path_shape:polyline({0,0, 50,30, 100,10, 150,40})

--@api-stub: Shape:clear
path_shape:clear()
print("shape cleared")

--@api-stub: Shape:type
print("Shape type: " .. path_shape:type())

--@api-stub: Shape:typeOf
print("is Shape: " .. tostring(path_shape:typeOf("Shape")))

-- =============================================================================
-- DrawLayer Object Methods
-- =============================================================================

--@api-stub: DrawLayer:queue
-- Queue a draw command into the layer for deferred rendering.
ui_layer:queue(function()
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("HUD Text", 10, 10)
end)

--@api-stub: DrawLayer:getCount
print("UI layer queued: " .. ui_layer:getCount())

--@api-stub: DrawLayer:flush
ui_layer:flush()

--@api-stub: DrawLayer:clear
ui_layer:clear()

--@api-stub: DrawLayer:type
print("DrawLayer type: " .. ui_layer:type())

--@api-stub: DrawLayer:typeOf
print("is DrawLayer: " .. tostring(ui_layer:typeOf("DrawLayer")))

print("\n-- render.lua example complete --")
-- content/examples/render.lua
-- Lurek2D lurek.render API Reference
-- Run with: cargo run -- content/examples/render
--
-- Scenario: A retro arcade game renderer — background gradient, geometric shapes
-- for UI borders, sprite drawing with quads, bitmap fonts, off-screen canvases
-- for minimap, custom shaders for CRT effect, nine-slice panels, bezier curves
-- for particle trails, sort groups for depth ordering, mesh-based terrain,
-- draw layers for batched rendering, and screenshots for replay thumbnails.

print("=== lurek.render — Retro Arcade Renderer ===\n")

-- =============================================================================
-- Screen Setup — colours and background
-- =============================================================================

-- ---- Stub: lurek.render.getWidth -----------------------------------------
--@api-stub: lurek.render.getWidth
local scr_w = lurek.render.getWidth()
print("screen width: " .. tostring(scr_w))

-- ---- Stub: lurek.render.getHeight ----------------------------------------
--@api-stub: lurek.render.getHeight
local scr_h = lurek.render.getHeight()
print("screen height: " .. tostring(scr_h))

-- ---- Stub: lurek.render.getDimensions ------------------------------------
--@api-stub: lurek.render.getDimensions
local sw, sh = lurek.render.getDimensions()
print("screen: " .. tostring(sw) .. "x" .. tostring(sh))

-- ---- Stub: lurek.render.setBackgroundColor --------------------------------
--@api-stub: lurek.render.setBackgroundColor
lurek.render.setBackgroundColor(0.05, 0.05, 0.15, 1.0)
print("background set to dark blue")

-- ---- Stub: lurek.render.getBackgroundColor --------------------------------
--@api-stub: lurek.render.getBackgroundColor
local br, bg, bb, ba = lurek.render.getBackgroundColor()
print("background: (" .. tostring(br) .. "," .. tostring(bg) .. "," .. tostring(bb) .. ")")

-- ---- Stub: lurek.render.clear --------------------------------------------
--@api-stub: lurek.render.clear
lurek.render.clear(0.05, 0.05, 0.15, 1.0)
print("screen cleared")

-- ---- Stub: lurek.render.setColor -----------------------------------------
--@api-stub: lurek.render.setColor
lurek.render.setColor(1, 1, 1, 1)
print("draw colour: white")

-- ---- Stub: lurek.render.getColor -----------------------------------------
--@api-stub: lurek.render.getColor
local cr, cg, cb, ca = lurek.render.getColor()
print("current colour: (" .. tostring(cr) .. "," .. tostring(cg) .. "," .. tostring(cb) .. "," .. tostring(ca) .. ")")

-- =============================================================================
-- Primitive Drawing — arcade shapes
-- =============================================================================

-- ---- Stub: lurek.render.setLineWidth -------------------------------------
--@api-stub: lurek.render.setLineWidth
lurek.render.setLineWidth(2)
print("line width: 2")

-- ---- Stub: lurek.render.getLineWidth -------------------------------------
--@api-stub: lurek.render.getLineWidth
print("line width: " .. tostring(lurek.render.getLineWidth()))

-- ---- Stub: lurek.render.setPointSize -------------------------------------
--@api-stub: lurek.render.setPointSize
lurek.render.setPointSize(3)
print("point size: 3")

-- ---- Stub: lurek.render.getPointSize -------------------------------------
--@api-stub: lurek.render.getPointSize
print("point size: " .. tostring(lurek.render.getPointSize()))

-- ---- Stub: lurek.render.rectangle ----------------------------------------
--@api-stub: lurek.render.rectangle
-- Draw the play area border.
lurek.render.setColor(0, 1, 0, 1)
lurek.render.rectangle("line", 10, 10, sw - 20, sh - 20)
print("play area border drawn")

-- Filled background panel.
lurek.render.setColor(0.1, 0.1, 0.2, 0.8)
lurek.render.rectangle("fill", 20, 20, 200, 40)
print("score panel background drawn")

-- ---- Stub: lurek.render.circle -------------------------------------------
--@api-stub: lurek.render.circle
-- Draw the player as a filled circle.
lurek.render.setColor(0, 1, 1, 1)
lurek.render.circle("fill", 400, 300, 16, 32)
print("player circle drawn at (400, 300)")

-- ---- Stub: lurek.render.ellipse ------------------------------------------
--@api-stub: lurek.render.ellipse
-- Draw an enemy ship (elliptical).
lurek.render.setColor(1, 0, 0, 1)
lurek.render.ellipse("fill", 600, 200, 24, 12, 24)
print("enemy ship ellipse drawn")

-- ---- Stub: lurek.render.triangle -----------------------------------------
--@api-stub: lurek.render.triangle
-- Player ship as a triangle pointing up.
lurek.render.setColor(0, 1, 0, 1)
lurek.render.triangle("fill", 400, 280, 384, 310, 416, 310)
print("player ship triangle drawn")

-- ---- Stub: lurek.render.line ---------------------------------------------
--@api-stub: lurek.render.line
-- Laser beam from player to top of screen.
lurek.render.setColor(1, 1, 0, 1)
lurek.render.line(400, 280, 400, 10)
print("laser beam line drawn")

-- ---- Stub: lurek.render.polygon ------------------------------------------
--@api-stub: lurek.render.polygon
-- Asteroid as an irregular polygon.
lurek.render.setColor(0.6, 0.6, 0.6, 1)
lurek.render.polygon("fill", 200, 150, 220, 140, 240, 155, 235, 175, 215, 180, 195, 170)
print("asteroid polygon drawn")

-- ---- Stub: lurek.render.arc ----------------------------------------------
--@api-stub: lurek.render.arc
-- Shield arc around the player.
lurek.render.setColor(0.3, 0.5, 1, 0.6)
lurek.render.arc("line", 400, 300, 30, 0, math.pi, 20)
print("shield arc drawn")

-- ---- Stub: lurek.render.points -------------------------------------------
--@api-stub: lurek.render.points
-- Star field background dots.
lurek.render.setColor(1, 1, 1, 0.8)
lurek.render.points(50, 50, 150, 80, 300, 40, 500, 120, 700, 60, 250, 200)
print("star field points drawn")

-- =============================================================================
-- Blend Modes & Wireframe
-- =============================================================================

-- ---- Stub: lurek.render.setBlendMode -------------------------------------
--@api-stub: lurek.render.setBlendMode
lurek.render.setBlendMode("alpha")
print("blend mode: alpha")

-- ---- Stub: lurek.render.getBlendMode -------------------------------------
--@api-stub: lurek.render.getBlendMode
print("blend mode: " .. tostring(lurek.render.getBlendMode()))

-- Additive blending for explosions.
lurek.render.setBlendMode("add")
lurek.render.setColor(1, 0.5, 0, 0.8)
lurek.render.circle("fill", 600, 200, 32, 24)
print("explosion drawn with additive blending")
lurek.render.setBlendMode("alpha")

-- ---- Stub: lurek.render.setWireframe -------------------------------------
--@api-stub: lurek.render.setWireframe
lurek.render.setWireframe(false)

-- ---- Stub: lurek.render.isWireframe --------------------------------------
--@api-stub: lurek.render.isWireframe
print("wireframe: " .. tostring(lurek.render.isWireframe()))

-- =============================================================================
-- Fonts & Text — score display and messages
-- =============================================================================

-- ---- Stub: lurek.render.newFont ------------------------------------------
--@api-stub: lurek.render.newFont
local font = lurek.render.newFont(16)
print("font created: 16px")

-- ---- Stub: lurek.render.setFont ------------------------------------------
--@api-stub: lurek.render.setFont
lurek.render.setFont(font)
print("font set")

-- ---- Stub: lurek.render.getFont ------------------------------------------
--@api-stub: lurek.render.getFont
local cur_font = lurek.render.getFont()
print("current font: " .. type(cur_font))

-- ---- Stub: lurek.render.getDefaultFont -----------------------------------
--@api-stub: lurek.render.getDefaultFont
local def_font = lurek.render.getDefaultFont()
print("default font: " .. type(def_font))

-- ---- Stub: lurek.render.getFontSizes -------------------------------------
--@api-stub: lurek.render.getFontSizes
local sizes = lurek.render.getFontSizes()
if sizes then print("available font sizes: " .. #sizes) end

-- ---- Stub: lurek.render.getFontWidth -------------------------------------
--@api-stub: lurek.render.getFontWidth
local fw = lurek.render.getFontWidth("SCORE: 12345")
print("'SCORE: 12345' width: " .. tostring(fw) .. "px")

-- ---- Stub: lurek.render.getFontCellWidth ---------------------------------
--@api-stub: lurek.render.getFontCellWidth
local cw = lurek.render.getFontCellWidth()
print("font cell width: " .. tostring(cw))

-- ---- Stub: lurek.render.getFontHeight ------------------------------------
--@api-stub: lurek.render.getFontHeight
print("font height: " .. tostring(lurek.render.getFontHeight()))

-- ---- Stub: lurek.render.getFontLineHeight --------------------------------
--@api-stub: lurek.render.getFontLineHeight
print("font line height: " .. tostring(lurek.render.getFontLineHeight()))

-- ---- Stub: lurek.render.setFontLineHeight --------------------------------
--@api-stub: lurek.render.setFontLineHeight
lurek.render.setFontLineHeight(1.2)
print("font line height set to 1.2")

-- ---- Stub: lurek.render.getFontAscent ------------------------------------
--@api-stub: lurek.render.getFontAscent
print("font ascent: " .. tostring(lurek.render.getFontAscent()))

-- ---- Stub: lurek.render.getFontDescent -----------------------------------
--@api-stub: lurek.render.getFontDescent
print("font descent: " .. tostring(lurek.render.getFontDescent()))

-- ---- Stub: lurek.render.getFontWrap --------------------------------------
--@api-stub: lurek.render.getFontWrap
local wrap_w, lines = lurek.render.getFontWrap("Game Over! Insert coin to continue.", 200)
print("text wrap: width=" .. tostring(wrap_w) .. ", lines=" .. tostring(lines))

-- ---- Stub: lurek.render.print --------------------------------------------
--@api-stub: lurek.render.print
lurek.render.setColor(1, 1, 1, 1)
lurek.render.print("SCORE: 12345", 30, 30)
print("score text drawn")

-- ---- Stub: lurek.render.printf -------------------------------------------
--@api-stub: lurek.render.printf
lurek.render.printf("HIGH SCORES", 0, 50, sw, "center")
print("centred text drawn")

-- ---- Stub: lurek.render.printRich ----------------------------------------
--@api-stub: lurek.render.printRich
lurek.render.printRich("{color=red}DANGER{/color} — shields low!", 30, 70)
print("rich text drawn")

-- ---- Font userdata methods
-- ---- Stub: Font:getWidth -------------------------------------------------
--@api-stub: Font:getWidth
print("font 'A' width: " .. tostring(font:getWidth("A")))

-- ---- Stub: Font:getHeight ------------------------------------------------
--@api-stub: Font:getHeight
print("font height: " .. tostring(font:getHeight()))

-- ---- Stub: Font:getLineHeight --------------------------------------------
--@api-stub: Font:getLineHeight
print("font line height: " .. tostring(font:getLineHeight()))

-- ---- Stub: Font:setLineHeight --------------------------------------------
--@api-stub: Font:setLineHeight
font:setLineHeight(1.5)
print("font line height set to 1.5")

-- ---- Stub: Font:getAscent ------------------------------------------------
--@api-stub: Font:getAscent
print("font ascent: " .. tostring(font:getAscent()))

-- ---- Stub: Font:getDescent -----------------------------------------------
--@api-stub: Font:getDescent
print("font descent: " .. tostring(font:getDescent()))

-- ---- Stub: Font:getWrap --------------------------------------------------
--@api-stub: Font:getWrap
local fww, fwl = font:getWrap("Wrap this text please.", 100)
print("font wrap: width=" .. tostring(fww) .. " lines=" .. tostring(fwl))

-- ---- Stub: Font:release --------------------------------------------------
--@api-stub: Font:release
-- Release font when switching to a different one.
font:release()
print("font released")

-- ---- Stub: Font:typeOf ---------------------------------------------------
--@api-stub: Font:typeOf
local new_font = lurek.render.newFont(14)
print("font typeOf: " .. tostring(new_font:typeOf()))

-- ---- Stub: Font:type -----------------------------------------------------
--@api-stub: Font:type
print("font type: " .. tostring(new_font:type()))

-- =============================================================================
-- Images & Sprites — game art
-- =============================================================================

-- ---- Stub: lurek.render.newImage -----------------------------------------
--@api-stub: lurek.render.newImage
local ok_img, ship_img = pcall(function()
    return lurek.render.newImage("assets/ship.png")
end)
if not ok_img then
    print("ship image load skipped (file not found — expected in example)")
end

-- ---- Stub: lurek.render.draw ---------------------------------------------
--@api-stub: lurek.render.draw
if ok_img then
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.draw(ship_img, 400, 300, 0, 1, 1, 16, 16)
    print("ship drawn at (400, 300)")
end

-- ---- Stub: lurek.render.newQuad ------------------------------------------
--@api-stub: lurek.render.newQuad
-- Define a sub-region of a sprite sheet.
local quad = lurek.render.newQuad(0, 0, 32, 32, 256, 256)
print("quad created: 32x32 from 256x256 sheet")

-- ---- Stub: lurek.render.drawq --------------------------------------------
--@api-stub: lurek.render.drawq
if ok_img then
    lurek.render.drawq(ship_img, quad, 500, 300)
    print("quad drawn from sprite sheet")
end

-- ---- Image userdata methods
if ok_img then
    -- ---- Stub: Image:getWidth ------------------------------------------------
    --@api-stub: Image:getWidth
    print("image width: " .. tostring(ship_img:getWidth()))

    -- ---- Stub: Image:getHeight -----------------------------------------------
    --@api-stub: Image:getHeight
    print("image height: " .. tostring(ship_img:getHeight()))

    -- ---- Stub: Image:getDimensions -------------------------------------------
    --@api-stub: Image:getDimensions
    local iw, ih = ship_img:getDimensions()
    print("image: " .. tostring(iw) .. "x" .. tostring(ih))

    -- ---- Stub: Image:typeOf --------------------------------------------------
    --@api-stub: Image:typeOf
    print("image typeOf: " .. tostring(ship_img:typeOf()))

    -- ---- Stub: Image:type ----------------------------------------------------
    --@api-stub: Image:type
    print("image type: " .. tostring(ship_img:type()))

    -- ---- Stub: Image:release -------------------------------------------------
    --@api-stub: Image:release
    ship_img:release()
    print("ship image released")
end

-- ---- Quad userdata
-- ---- Stub: Quad:getViewport ----------------------------------------------
--@api-stub: Quad:getViewport
local qx, qy, qw, qh = quad:getViewport()
print("quad viewport: (" .. tostring(qx) .. "," .. tostring(qy) .. ") " .. tostring(qw) .. "x" .. tostring(qh))

-- ---- Stub: Quad:getTextureDimensions -------------------------------------
--@api-stub: Quad:getTextureDimensions
local qtw, qth = quad:getTextureDimensions()
print("quad texture: " .. tostring(qtw) .. "x" .. tostring(qth))

-- ---- Stub: Quad:typeOf ---------------------------------------------------
--@api-stub: Quad:typeOf
print("quad typeOf: " .. tostring(quad:typeOf()))

-- ---- Stub: Quad:type -----------------------------------------------------
--@api-stub: Quad:type
print("quad type: " .. tostring(quad:type()))

-- =============================================================================
-- Filter & Default Settings
-- =============================================================================

-- ---- Stub: lurek.render.setDefaultFilter ---------------------------------
--@api-stub: lurek.render.setDefaultFilter
lurek.render.setDefaultFilter("nearest", "nearest")
print("default filter: nearest (pixel art)")

-- ---- Stub: lurek.render.getDefaultFilter ---------------------------------
--@api-stub: lurek.render.getDefaultFilter
local fmin, fmag = lurek.render.getDefaultFilter()
print("default filter: min=" .. tostring(fmin) .. " mag=" .. tostring(fmag))

-- =============================================================================
-- Canvas — off-screen rendering for minimap
-- =============================================================================

-- ---- Stub: lurek.render.newCanvas ----------------------------------------
--@api-stub: lurek.render.newCanvas
local minimap = lurek.render.newCanvas(128, 128)
print("minimap canvas created: 128x128")

-- ---- Stub: lurek.render.setCanvas ----------------------------------------
--@api-stub: lurek.render.setCanvas
lurek.render.setCanvas(minimap)
print("rendering to minimap canvas")

-- Draw minimap content.
lurek.render.clear(0, 0, 0, 1)
lurek.render.setColor(0, 0.5, 0, 1)
lurek.render.rectangle("fill", 0, 0, 128, 128)
lurek.render.setColor(1, 0, 0, 1)
lurek.render.circle("fill", 64, 64, 4, 8)

-- ---- Stub: lurek.render.getCanvas ----------------------------------------
--@api-stub: lurek.render.getCanvas
local cur_canvas = lurek.render.getCanvas()
print("current canvas: " .. type(cur_canvas))

-- ---- Stub: lurek.render.getCanvasSize ------------------------------------
--@api-stub: lurek.render.getCanvasSize
local cw2, ch2 = lurek.render.getCanvasSize()
print("canvas size: " .. tostring(cw2) .. "x" .. tostring(ch2))

-- Switch back to screen.
lurek.render.setCanvas()
print("rendering to screen")

-- Draw minimap in corner.
lurek.render.setColor(1, 1, 1, 1)
lurek.render.draw(minimap, sw - 138, 10)

-- ---- Canvas userdata
-- ---- Stub: Canvas:getWidth -----------------------------------------------
--@api-stub: Canvas:getWidth
print("minimap canvas width: " .. tostring(minimap:getWidth()))

-- ---- Stub: Canvas:getHeight ----------------------------------------------
--@api-stub: Canvas:getHeight
print("minimap canvas height: " .. tostring(minimap:getHeight()))

-- ---- Stub: Canvas:getDimensions ------------------------------------------
--@api-stub: Canvas:getDimensions
local mcw, mch = minimap:getDimensions()
print("minimap canvas: " .. tostring(mcw) .. "x" .. tostring(mch))

-- ---- Stub: Canvas:typeOf -------------------------------------------------
--@api-stub: Canvas:typeOf
print("canvas typeOf: " .. tostring(minimap:typeOf()))

-- ---- Stub: Canvas:type ---------------------------------------------------
--@api-stub: Canvas:type
print("canvas type: " .. tostring(minimap:type()))

-- ---- Stub: Canvas:release ------------------------------------------------
--@api-stub: Canvas:release
minimap:release()
print("minimap canvas released")

-- =============================================================================
-- SpriteBatch — efficient enemy rendering
-- =============================================================================

-- ---- Stub: lurek.render.newSpriteBatch -----------------------------------
--@api-stub: lurek.render.newSpriteBatch
local batch = lurek.render.newSpriteBatch(256)
print("sprite batch created: capacity=256")

-- ---- Stub: SpriteBatch:clear ---------------------------------------------
--@api-stub: SpriteBatch:clear
batch:clear()
print("sprite batch cleared")

-- ---- Stub: SpriteBatch:getCount ------------------------------------------
--@api-stub: SpriteBatch:getCount
print("batch count: " .. tostring(batch:getCount()))

-- ---- Stub: SpriteBatch:getBufferSize -------------------------------------
--@api-stub: SpriteBatch:getBufferSize
print("batch buffer: " .. tostring(batch:getBufferSize()))

-- ---- Stub: SpriteBatch:typeOf --------------------------------------------
--@api-stub: SpriteBatch:typeOf
print("batch typeOf: " .. tostring(batch:typeOf()))

-- ---- Stub: SpriteBatch:type ----------------------------------------------
--@api-stub: SpriteBatch:type
print("batch type: " .. tostring(batch:type()))

-- ---- Stub: SpriteBatch:release -------------------------------------------
--@api-stub: SpriteBatch:release
batch:release()
print("sprite batch released")

-- =============================================================================
-- Mesh — terrain strip
-- =============================================================================

-- ---- Stub: lurek.render.newMesh ------------------------------------------
--@api-stub: lurek.render.newMesh
local mesh = lurek.render.newMesh(4, "fan")
print("mesh created: 4 vertices, fan mode")

-- ---- Stub: Mesh:getVertexCount -------------------------------------------
--@api-stub: Mesh:getVertexCount
print("mesh vertices: " .. tostring(mesh:getVertexCount()))

-- ---- Stub: Mesh:setVertex ------------------------------------------------
--@api-stub: Mesh:setVertex
mesh:setVertex(1, 0, 0, 0, 0, 1, 0, 0, 1)
mesh:setVertex(2, 100, 0, 1, 0, 0, 1, 0, 1)
mesh:setVertex(3, 100, 100, 1, 1, 0, 0, 1, 1)
mesh:setVertex(4, 0, 100, 0, 1, 1, 1, 0, 1)
print("mesh vertices set (coloured quad)")

-- ---- Stub: Mesh:getVertex ------------------------------------------------
--@api-stub: Mesh:getVertex
local vx, vy = mesh:getVertex(1)
print("vertex 1: (" .. tostring(vx) .. "," .. tostring(vy) .. ")")

-- ---- Stub: Mesh:setTexture -----------------------------------------------
--@api-stub: Mesh:setTexture
mesh:setTexture(nil)
print("mesh texture cleared (untextured)")

-- ---- Stub: Mesh:typeOf ---------------------------------------------------
--@api-stub: Mesh:typeOf
print("mesh typeOf: " .. tostring(mesh:typeOf()))

-- ---- Stub: Mesh:type -----------------------------------------------------
--@api-stub: Mesh:type
print("mesh type: " .. tostring(mesh:type()))

-- ---- Stub: Mesh:release --------------------------------------------------
--@api-stub: Mesh:release
mesh:release()
print("mesh released")

-- =============================================================================
-- Shaders — CRT scanline effect
-- =============================================================================

-- ---- Stub: lurek.render.newShader ----------------------------------------
--@api-stub: lurek.render.newShader
local ok_shader, shader = pcall(function()
    return lurek.render.newShader([[
        vec4 effect(vec4 color, sampler2D tex, vec2 uv) {
            float scan = sin(uv.y * 800.0) * 0.05;
            vec4 pixel = texture(tex, uv);
            return pixel * color * (1.0 - scan);
        }
    ]])
end)
if ok_shader then
    print("CRT shader created")
else
    print("shader creation skipped: " .. tostring(shader))
end

-- ---- Stub: lurek.render.setShader ----------------------------------------
--@api-stub: lurek.render.setShader
if ok_shader then
    lurek.render.setShader(shader)
    print("CRT shader active")
end

-- ---- Stub: lurek.render.getShader ----------------------------------------
--@api-stub: lurek.render.getShader
local cur_shader = lurek.render.getShader()
print("current shader: " .. type(cur_shader))

-- Reset shader.
lurek.render.setShader()

-- ---- Shader userdata
if ok_shader then
    -- ---- Stub: Shader:hasUniform ---------------------------------------------
    --@api-stub: Shader:hasUniform
    print("shader has 'time': " .. tostring(shader:hasUniform("time")))

    -- ---- Stub: Shader:send ---------------------------------------------------
    --@api-stub: Shader:send
    if shader:hasUniform("time") then
        shader:send("time", 1.5)
        print("shader uniform 'time' set to 1.5")
    end

    -- ---- Stub: Shader:typeOf -------------------------------------------------
    --@api-stub: Shader:typeOf
    print("shader typeOf: " .. tostring(shader:typeOf()))

    -- ---- Stub: Shader:type ---------------------------------------------------
    --@api-stub: Shader:type
    print("shader type: " .. tostring(shader:type()))

    -- ---- Stub: Shader:release ------------------------------------------------
    --@api-stub: Shader:release
    shader:release()
    print("shader released")
end

-- =============================================================================
-- Transform Stack — camera-like transforms
-- =============================================================================

-- ---- Stub: lurek.render.push ---------------------------------------------
--@api-stub: lurek.render.push
lurek.render.push()
print("transform pushed")

-- ---- Stub: lurek.render.translate ----------------------------------------
--@api-stub: lurek.render.translate
lurek.render.translate(sw / 2, sh / 2)
print("translated to screen centre")

-- ---- Stub: lurek.render.rotate -------------------------------------------
--@api-stub: lurek.render.rotate
lurek.render.rotate(0.1)
print("rotated 0.1 rad")

-- ---- Stub: lurek.render.scale --------------------------------------------
--@api-stub: lurek.render.scale
lurek.render.scale(2, 2)
print("scaled 2x")

-- ---- Stub: lurek.render.shear --------------------------------------------
--@api-stub: lurek.render.shear
lurek.render.shear(0.1, 0)
print("sheared x by 0.1")

-- Draw something at the transformed origin.
lurek.render.setColor(1, 1, 0, 1)
lurek.render.rectangle("fill", -10, -10, 20, 20)
print("yellow square at transformed origin")

-- ---- Stub: lurek.render.pop ----------------------------------------------
--@api-stub: lurek.render.pop
lurek.render.pop()
print("transform popped")

-- ---- Stub: lurek.render.origin -------------------------------------------
--@api-stub: lurek.render.origin
lurek.render.origin()
print("transform reset to identity")

-- ---- Stub: lurek.render.applyTransform -----------------------------------
--@api-stub: lurek.render.applyTransform
lurek.render.applyTransform(1, 0, 0, 1, 50, 50)
print("custom transform applied: translate(50,50)")
lurek.render.origin()

-- =============================================================================
-- Scissor & Clipping
-- =============================================================================

-- ---- Stub: lurek.render.setScissor ---------------------------------------
--@api-stub: lurek.render.setScissor
lurek.render.setScissor(50, 50, 200, 150)
print("scissor set: (50,50) 200x150")

-- ---- Stub: lurek.render.getScissor ---------------------------------------
--@api-stub: lurek.render.getScissor
local sx2, sy2, sw2, sh2 = lurek.render.getScissor()
print("scissor: (" .. tostring(sx2) .. "," .. tostring(sy2) .. ") " .. tostring(sw2) .. "x" .. tostring(sh2))

-- ---- Stub: lurek.render.intersectScissor ---------------------------------
--@api-stub: lurek.render.intersectScissor
lurek.render.intersectScissor(100, 100, 100, 50)
print("scissor intersected")

-- Reset scissor.
lurek.render.setScissor()

-- =============================================================================
-- Colour Mask
-- =============================================================================

-- ---- Stub: lurek.render.setColorMask -------------------------------------
--@api-stub: lurek.render.setColorMask
lurek.render.setColorMask(true, true, true, true)
print("color mask: RGBA all enabled")

-- ---- Stub: lurek.render.getColorMask -------------------------------------
--@api-stub: lurek.render.getColorMask
local mr, mg2, mb2, ma2 = lurek.render.getColorMask()
print("color mask: R=" .. tostring(mr) .. " G=" .. tostring(mg2) .. " B=" .. tostring(mb2) .. " A=" .. tostring(ma2))

-- =============================================================================
-- Stencil Buffer — UI masking
-- =============================================================================

-- ---- Stub: lurek.render.stencil ------------------------------------------
--@api-stub: lurek.render.stencil
lurek.render.stencil(function()
    lurek.render.circle("fill", 400, 300, 50, 32)
end, "replace", 1)
print("stencil written: circle mask at (400, 300)")

-- ---- Stub: lurek.render.setStencilTest -----------------------------------
--@api-stub: lurek.render.setStencilTest
lurek.render.setStencilTest("greater", 0)
print("stencil test: draw only inside circle")

-- ---- Stub: lurek.render.setStencilMode -----------------------------------
--@api-stub: lurek.render.setStencilMode
lurek.render.setStencilMode("keep", "keep", "keep")
print("stencil mode set")

-- ---- Stub: lurek.render.getStencilMode -----------------------------------
--@api-stub: lurek.render.getStencilMode
local sm = lurek.render.getStencilMode()
print("stencil mode: " .. tostring(sm))

-- ---- Stub: lurek.render.clearStencil -------------------------------------
--@api-stub: lurek.render.clearStencil
lurek.render.clearStencil()
print("stencil cleared")

-- =============================================================================
-- Depth Buffer
-- =============================================================================

-- ---- Stub: lurek.render.setDepthMode -------------------------------------
--@api-stub: lurek.render.setDepthMode
lurek.render.setDepthMode("lequal", true)
print("depth mode: lequal, write=true")

-- ---- Stub: lurek.render.getDepthMode -------------------------------------
--@api-stub: lurek.render.getDepthMode
local dm = lurek.render.getDepthMode()
print("depth mode: " .. tostring(dm))

-- =============================================================================
-- NineSlice — UI panel borders
-- =============================================================================

-- ---- Stub: lurek.render.newNineSlice -------------------------------------
--@api-stub: lurek.render.newNineSlice
local ok_ns, ns = pcall(function()
    return lurek.render.newNineSlice("assets/panel.png", 8, 8, 8, 8)
end)
if ok_ns then
    print("nine-slice created: 8px insets")
else
    print("nine-slice skipped (file not found)")
end

-- ---- Stub: lurek.render.drawNineSlice ------------------------------------
--@api-stub: lurek.render.drawNineSlice
if ok_ns then
    lurek.render.drawNineSlice(ns, 100, 400, 200, 80)
    print("nine-slice panel drawn: 200x80 at (100, 400)")
end

-- ---- NineSlice userdata
if ok_ns then
    -- ---- Stub: NineSlice:getInsets -------------------------------------------
    --@api-stub: NineSlice:getInsets
    local nl, nt, nr, nb = ns:getInsets()
    print("nine-slice insets: " .. tostring(nl) .. "," .. tostring(nt) .. "," .. tostring(nr) .. "," .. tostring(nb))

    -- ---- Stub: NineSlice:getTextureSize --------------------------------------
    --@api-stub: NineSlice:getTextureSize
    local nsw, nsh = ns:getTextureSize()
    print("nine-slice texture: " .. tostring(nsw) .. "x" .. tostring(nsh))

    -- ---- Stub: NineSlice:type ------------------------------------------------
    --@api-stub: NineSlice:type
    print("nine-slice type: " .. tostring(ns:type()))

    -- ---- Stub: NineSlice:typeOf ----------------------------------------------
    --@api-stub: NineSlice:typeOf
    print("nine-slice typeOf: " .. tostring(ns:typeOf()))
end

-- =============================================================================
-- Shape Builder — reusable line art
-- =============================================================================

-- ---- Stub: lurek.render.newShape -----------------------------------------
--@api-stub: lurek.render.newShape
local shape = lurek.render.newShape()
print("shape builder created")

-- ---- Stub: Shape:setLineWidth --------------------------------------------
--@api-stub: Shape:setLineWidth
shape:setLineWidth(3)
print("shape line width: 3")

-- ---- Stub: Shape:line ----------------------------------------------------
--@api-stub: Shape:line
shape:line(0, 0, 50, 0)
shape:line(50, 0, 50, 50)
print("2 line segments added to shape")

-- ---- Stub: Shape:polyline ------------------------------------------------
--@api-stub: Shape:polyline
shape:polyline(0, 0, 25, -20, 50, 0)
print("polyline added to shape (arrow head)")

-- ---- Stub: Shape:getCommandCount -----------------------------------------
--@api-stub: Shape:getCommandCount
print("shape commands: " .. tostring(shape:getCommandCount()))

-- ---- Stub: Shape:typeOf --------------------------------------------------
--@api-stub: Shape:typeOf
print("shape typeOf: " .. tostring(shape:typeOf()))

-- ---- Stub: Shape:type ----------------------------------------------------
--@api-stub: Shape:type
print("shape type: " .. tostring(shape:type()))

-- ---- Stub: Shape:clear ---------------------------------------------------
--@api-stub: Shape:clear
shape:clear()
print("shape cleared")

-- =============================================================================
-- DrawLayer — batched deferred rendering
-- =============================================================================

-- ---- Stub: lurek.render.newDrawLayer -------------------------------------
--@api-stub: lurek.render.newDrawLayer
local dl = lurek.render.newDrawLayer()
print("draw layer created")

-- ---- Stub: DrawLayer:queue -----------------------------------------------
--@api-stub: DrawLayer:queue
dl:queue(function()
    lurek.render.setColor(1, 0.5, 0, 1)
    lurek.render.circle("fill", 200, 200, 20, 16)
end)
dl:queue(function()
    lurek.render.setColor(0, 0.5, 1, 1)
    lurek.render.rectangle("fill", 250, 190, 40, 20)
end)
print("2 draw commands queued")

-- ---- Stub: DrawLayer:getCount --------------------------------------------
--@api-stub: DrawLayer:getCount
print("queued commands: " .. tostring(dl:getCount()))

-- ---- Stub: DrawLayer:flush -----------------------------------------------
--@api-stub: DrawLayer:flush
dl:flush()
print("draw layer flushed")

-- ---- Stub: DrawLayer:typeOf ----------------------------------------------
--@api-stub: DrawLayer:typeOf
print("draw layer typeOf: " .. tostring(dl:typeOf()))

-- ---- Stub: DrawLayer:type ------------------------------------------------
--@api-stub: DrawLayer:type
print("draw layer type: " .. tostring(dl:type()))

-- ---- Stub: DrawLayer:clear -----------------------------------------------
--@api-stub: DrawLayer:clear
dl:clear()
print("draw layer cleared")

-- =============================================================================
-- Advanced Drawing — beziers, gradients, iso/hex tiles, bevel
-- =============================================================================

-- ---- Stub: lurek.render.drawQuadBezier -----------------------------------
--@api-stub: lurek.render.drawQuadBezier
lurek.render.setColor(1, 1, 0, 1)
lurek.render.drawQuadBezier(100, 500, 200, 400, 300, 500, 20)
print("quadratic bezier drawn (particle trail)")

-- ---- Stub: lurek.render.drawCubicBezier ----------------------------------
--@api-stub: lurek.render.drawCubicBezier
lurek.render.setColor(0, 1, 1, 1)
lurek.render.drawCubicBezier(400, 500, 450, 400, 550, 600, 600, 500, 30)
print("cubic bezier drawn (smooth path)")

-- ---- Stub: lurek.render.drawPath -----------------------------------------
--@api-stub: lurek.render.drawPath
lurek.render.setColor(1, 0, 1, 1)
lurek.render.drawPath({100, 550, 150, 520, 200, 560, 250, 530}, false)
print("path drawn (open polyline)")

-- ---- Stub: lurek.render.drawGradientRect ---------------------------------
--@api-stub: lurek.render.drawGradientRect
lurek.render.drawGradientRect(50, 560, 200, 30,
    {0.2, 0, 0.4, 1}, {0.6, 0, 0.2, 1},
    {0.2, 0, 0.4, 1}, {0.6, 0, 0.2, 1})
print("gradient rectangle drawn (health bar)")

-- ---- Stub: lurek.render.drawColoredPolygon --------------------------------
--@api-stub: lurek.render.drawColoredPolygon
lurek.render.drawColoredPolygon({
    {300, 560, 1, 0, 0, 1},
    {350, 540, 0, 1, 0, 1},
    {400, 560, 0, 0, 1, 1},
})
print("coloured polygon drawn (RGB triangle)")

-- ---- Stub: lurek.render.drawIsoCubeTile ----------------------------------
--@api-stub: lurek.render.drawIsoCubeTile
lurek.render.setColor(0.5, 0.7, 0.5, 1)
lurek.render.drawIsoCubeTile(500, 400, 32, 32, 16)
print("iso cube tile drawn")

-- ---- Stub: lurek.render.drawHexTile --------------------------------------
--@api-stub: lurek.render.drawHexTile
lurek.render.setColor(0.3, 0.6, 0.8, 1)
lurek.render.drawHexTile(600, 400, 20)
print("hex tile drawn")

-- ---- Stub: lurek.render.drawBevelRect ------------------------------------
--@api-stub: lurek.render.drawBevelRect
lurek.render.setColor(0.4, 0.4, 0.6, 1)
lurek.render.drawBevelRect(50, 400, 120, 40, 6)
print("bevel rectangle drawn (button)")

-- =============================================================================
-- Sort Groups — depth-sorted rendering
-- =============================================================================

-- ---- Stub: lurek.render.beginSortGroup -----------------------------------
--@api-stub: lurek.render.beginSortGroup
lurek.render.beginSortGroup()
print("sort group started")

-- ---- Stub: lurek.render.pushSortKey --------------------------------------
--@api-stub: lurek.render.pushSortKey
-- Draw objects sorted by Y position (painter's algorithm).
lurek.render.pushSortKey(300)
lurek.render.setColor(1, 0, 0, 1)
lurek.render.circle("fill", 400, 300, 10, 12)

lurek.render.pushSortKey(200)
lurek.render.setColor(0, 1, 0, 1)
lurek.render.circle("fill", 420, 200, 10, 12)

-- ---- Stub: lurek.render.flushSortGroup -----------------------------------
--@api-stub: lurek.render.flushSortGroup
lurek.render.flushSortGroup()
print("sort group flushed (green before red)")

-- =============================================================================
-- Render Layers — named layer system
-- =============================================================================

-- ---- Stub: lurek.render.newLayer -----------------------------------------
--@api-stub: lurek.render.newLayer
local bg_layer = lurek.render.newLayer("background", 0)
local fg_layer = lurek.render.newLayer("foreground", 10)
print("layers created: background (z=0), foreground (z=10)")

-- ---- Stub: lurek.render.setLayer ----------------------------------------
--@api-stub: lurek.render.setLayer
lurek.render.setLayer("background")
print("drawing to background layer")

-- ---- Stub: lurek.render.currentLayer -------------------------------------
--@api-stub: lurek.render.currentLayer
print("current layer: " .. tostring(lurek.render.currentLayer()))

-- ---- Stub: lurek.render.setLayerVisible ----------------------------------
--@api-stub: lurek.render.setLayerVisible
lurek.render.setLayerVisible("background", true)
print("background layer visible: true")

-- ---- Stub: lurek.render.isLayerVisible -----------------------------------
--@api-stub: lurek.render.isLayerVisible
print("background visible: " .. tostring(lurek.render.isLayerVisible("background")))

-- ---- Stub: lurek.render.getLayerZOrder -----------------------------------
--@api-stub: lurek.render.getLayerZOrder
print("foreground z-order: " .. tostring(lurek.render.getLayerZOrder("foreground")))

-- ---- Stub: lurek.render.setLayerZOrder -----------------------------------
--@api-stub: lurek.render.setLayerZOrder
lurek.render.setLayerZOrder("foreground", 20)
print("foreground z-order changed to 20")

-- ---- Stub: lurek.render.pushLayer ----------------------------------------
--@api-stub: lurek.render.pushLayer
lurek.render.pushLayer("foreground")
print("pushed to foreground layer")

-- ---- Stub: lurek.render.popLayer -----------------------------------------
--@api-stub: lurek.render.popLayer
lurek.render.popLayer()
print("popped back to previous layer")

-- =============================================================================
-- ImageData — pixel manipulation
-- =============================================================================

local ok_id, img_data = pcall(function()
    return lurek.render.newImage("assets/test.png")
end)

-- ---- Stub: ImageData:getWidth --------------------------------------------
--@api-stub: ImageData:getWidth
if ok_id then print("image data width: " .. tostring(img_data:getWidth())) end

-- ---- Stub: ImageData:getHeight -------------------------------------------
--@api-stub: ImageData:getHeight
if ok_id then print("image data height: " .. tostring(img_data:getHeight())) end

-- ---- Stub: ImageData:resize ----------------------------------------------
--@api-stub: ImageData:resize
if ok_id then
    local resized = img_data:resize(64, 64)
    print("image data resized to 64x64")
end

-- ---- Stub: ImageData:diff ------------------------------------------------
--@api-stub: ImageData:diff
if ok_id then
    local d = img_data:diff(img_data)
    print("image data diff: " .. tostring(d))
end

-- ---- Stub: ImageData:mapPixels -------------------------------------------
--@api-stub: ImageData:mapPixels
if ok_id then
    img_data:mapPixels(function(x, y, r, g, b, a)
        return r * 0.5, g * 0.5, b * 0.5, a  -- darken
    end)
    print("image data pixels darkened")
end

-- ---- Stub: ImageData:type ------------------------------------------------
--@api-stub: ImageData:type
if ok_id then print("image data type: " .. tostring(img_data:type())) end

-- ---- Stub: ImageData:typeOf ----------------------------------------------
--@api-stub: ImageData:typeOf
if ok_id then print("image data typeOf: " .. tostring(img_data:typeOf())) end

-- =============================================================================
-- Stats & Screenshots
-- =============================================================================

-- ---- Stub: lurek.render.getStats -----------------------------------------
--@api-stub: lurek.render.getStats
local stats = lurek.render.getStats()
if stats then
    print("render stats: draw_calls=" .. tostring(stats.draw_calls)
        .. " textures=" .. tostring(stats.textures))
end

-- ---- Stub: lurek.render.saveScreenshot -----------------------------------
--@api-stub: lurek.render.saveScreenshot
lurek.render.saveScreenshot("screenshot.png")
print("screenshot saved: screenshot.png")

-- ---- Stub: lurek.render.captureScreenshot --------------------------------
--@api-stub: lurek.render.captureScreenshot
local cap = lurek.render.captureScreenshot()
print("screenshot captured to memory: " .. type(cap))

print("\n-- render.lua example complete --")
