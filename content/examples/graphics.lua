-- examples/graphics.lua
-- 2D drawing, images, fonts, canvases, meshes, shaders and sprite batches
-- API: lurek.gfx

--------------------------------------------------------------------------------
-- Drawing mode values
"fill"  -- solid filled shape
"line"  -- outline only
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Color and background
--------------------------------------------------------------------------------

lurek.gfx.setColor(1, 0.5, 0, 1)             -- r, g, b, a
local r, g, b, a = lurek.gfx.getColor()      -- → r, g, b, a

lurek.gfx.setBackgroundColor(0.1, 0.1, 0.15)
local br, bg, bb, ba = lurek.gfx.getBackgroundColor()

--------------------------------------------------------------------------------
-- Primitive shapes
--------------------------------------------------------------------------------

-- Rectangle (last two args are optional corner rx/ry for rounding)
lurek.gfx.rectangle("fill", 10, 10, 200, 100)
lurek.gfx.rectangle("line", 220, 10, 200, 100, 8, 8)  -- rounded corners

-- Circle
lurek.gfx.circle("fill", 100, 100, 50)
lurek.gfx.circle("line", 250, 100, 50)

-- Ellipse
lurek.gfx.ellipse("fill", 100, 200, 80, 40)
lurek.gfx.ellipse("line", 280, 200, 80, 40)

-- Triangle
lurek.gfx.triangle("fill", 100, 250, 150, 320, 50, 320)
lurek.gfx.triangle("line", 250, 250, 300, 320, 200, 320)

-- Line / polyline
lurek.gfx.line(0, 0, 100, 100)
lurek.gfx.line(100, 100, 200, 50, 300, 100, 400, 50)  -- multi-segment polyline

-- Polygon (flat list or table)
lurek.gfx.polygon("fill", 100, 100, 150, 80, 200, 100, 180, 150, 120, 150)
lurek.gfx.polygon("fill", { 300, 100, 350, 80, 400, 100, 380, 150, 320, 150 })

-- Arc
lurek.gfx.arc("fill", 200, 200, 80, 0, math.pi, 32)  -- angle in radians, segments
lurek.gfx.arc("line", 400, 200, 80, -math.pi/2, math.pi)

-- Points
lurek.gfx.points(10, 10, 20, 20, 30, 30)
lurek.gfx.points({ {10, 40}, {20, 40}, {30, 40} })  -- table form

--------------------------------------------------------------------------------
-- Line and point style
--------------------------------------------------------------------------------

lurek.gfx.setLineWidth(2)
local lw = lurek.gfx.getLineWidth()  -- 2.0

lurek.gfx.setPointSize(4)
local ps = lurek.gfx.getPointSize()  -- 4.0

--------------------------------------------------------------------------------
-- Blend modes
--------------------------------------------------------------------------------

lurek.gfx.setBlendMode("alpha")        -- default (alpha blending)
lurek.gfx.setBlendMode("add")          -- additive (glow, particles)
lurek.gfx.setBlendMode("multiply")     -- multiply (shadows)
lurek.gfx.setBlendMode("replace")      -- overwrite
lurek.gfx.setBlendMode("screen")       -- screen (lightening)
local bm = lurek.gfx.getBlendMode()   -- "alpha"

--------------------------------------------------------------------------------
-- Clear the draw buffer
--------------------------------------------------------------------------------

lurek.gfx.clear()             -- clear to background color
lurek.gfx.clear(0, 0, 0)     -- explicit r, g, b

--------------------------------------------------------------------------------
-- Images
--------------------------------------------------------------------------------

-- Load from file
local img = lurek.gfx.newImage("player.png")
local iw = img:getWidth()           -- pixel width
local ih = img:getHeight()          -- pixel height
local idw, idh = img:getDimensions()

-- Draw an image
lurek.gfx.draw(img, 100, 100)
-- draw(img, x, y, rotation, scaleX, scaleY, offsetX, offsetY)
lurek.gfx.draw(img, 200, 100, 0, 2, 2, iw/2, ih/2)  -- centered, scaled

-- Release GPU memory
img:release()

-- Load from ImageData (CPU pixel buffer)
local id = lurek.img.newImageData(64, 64)
local imgFromData = lurek.gfx.newImage(id)

--------------------------------------------------------------------------------
-- Quads (sub-image crop)
--------------------------------------------------------------------------------

local spriteSheet = lurek.gfx.newImage("spritesheet.png")
local sw, sh = spriteSheet:getDimensions()

-- newQuad(x, y, w, h, sourceW, sourceH)
local q1 = lurek.gfx.newQuad(0,   0, 32, 32, sw, sh)   -- frame 1
local q2 = lurek.gfx.newQuad(32,  0, 32, 32, sw, sh)   -- frame 2
local q3 = lurek.gfx.newQuad(64,  0, 32, 32, sw, sh)   -- frame 3

-- Draw with quad
lurek.gfx.drawq(spriteSheet, q1, 300, 100)
lurek.gfx.drawq(spriteSheet, q2, 340, 100)

-- Quad inspection
local qx, qy, qw, qh = q1:getViewport()       -- → x, y, w, h
q1:setViewport(0, 32, 32, 32)                   -- shift to next row
local tsw, tsh = q1:getTextureDimensions()     -- → sw, sh
local qt = q1:typeOf()                          -- "Quad"

--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------

-- Load a font, specify size in pixels
local font = lurek.gfx.newFont("font.ttf", 16)
lurek.gfx.setFont(font)
local activeFont = lurek.gfx.getFont()     -- the LuaFont or nil

-- Font metrics
local fw = font:getWidth("Hello!")             -- rendered text width
local fh = font:getHeight()                    -- line height
local fl = font:getLineHeight()                -- line height (same)
font:setLineHeight(1.2)
local fa = font:getAscent()                    -- ascent (baseline to cap)
local fd = font:getDescent()                   -- descent (baseline to floor)
local lines, maxW = font:getWrap("Long text", 100)  -- word-wrapped lines

font:release()

-- Module-level text metrics using the active font
local textW = lurek.gfx.getFontWidth(font, "Hello!")
local textH = lurek.gfx.getFontHeight(font)
local textA = lurek.gfx.getFontAscent(font)
local textD = lurek.gfx.getFontDescent(font)
local wrappedLines, w2 = lurek.gfx.getFontWrap("Long text", 100)

-- Draw text
lurek.gfx.print("Hello, World!")
lurek.gfx.print("At position", 100, 200)
lurek.gfx.print("Scaled", 100, 230, 1.5)  -- scale factor

-- Wrapped / aligned text
lurek.gfx.printf("Left aligned text", 50, 100, 300, "left")
lurek.gfx.printf("Centered heading", 50, 140, 300, "center")
lurek.gfx.printf("Right aligned", 50, 180, 300, "right")
lurek.gfx.printf("Justified paragraph text here", 50, 220, 300, "justify")

--------------------------------------------------------------------------------
-- Canvases (render-to-texture)
--------------------------------------------------------------------------------

local canvas = lurek.gfx.newCanvas(800, 600)
local cw = canvas:getWidth()     -- 800
local ch = canvas:getHeight()    -- 600
local cdw, cdh = canvas:getDimensions()

-- Render into canvas
lurek.gfx.setCanvas(canvas)
    lurek.gfx.clear(0, 0, 0)
    lurek.gfx.rectangle("fill", 10, 10, 100, 100)
    lurek.gfx.print("Inside canvas", 10, 120)
lurek.gfx.setCanvas()       -- pass nothing to restore screen

local active = lurek.gfx.getCanvas()  -- returns Canvas or nil

-- Draw canvas to screen like an image
lurek.gfx.draw(canvas, 0, 0)

canvas:release()

--------------------------------------------------------------------------------
-- Sprite batches (batch-draw many instances of one texture)
--------------------------------------------------------------------------------

local batchtex = lurek.gfx.newImage("coin.png")
local batch = lurek.gfx.newSpriteBatch(batchtex, 500)   -- max 500 sprites

-- Add sprites: add(x, y, r?, sx?, sy?, ox?, oy?) → integer id
batch:add(100, 100)
batch:add(200, 100, 0, 1.5, 1.5)
batch:add(300, 100, math.pi/4, 2, 2, 8, 8)  -- rotated, scaled, centered

local count = batch:getCount()          -- 3
local capacity = batch:getBufferSize()  -- 500

-- Draw all sprites
lurek.gfx.draw(batch, 0, 0)

-- Clear all added sprites
batch:clear()
batch:release()

--------------------------------------------------------------------------------
-- Meshes (custom vertex geometry)
--------------------------------------------------------------------------------

-- Vertices: {x, y, u, v, r, g, b, a} where u/v are texture UV, rgba is tint
local vertices = {
    {   0, -50, 0.5, 0.0, 1, 0, 0, 1 },  -- top, red
    {  50,  50, 1.0, 1.0, 0, 1, 0, 1 },  -- bottom-right, green
    { -50,  50, 0.0, 1.0, 0, 0, 1, 1 },  -- bottom-left, blue
}
local mesh = lurek.gfx.newMesh(vertices, "triangles")  -- or "fan", "strip"

-- Assign a texture to mesh UV coordinates
mesh:setTexture(batchtex)

-- Inspect / modify vertices
local vc = mesh:getVertexCount()                 -- 3
local vx, vy, vu, vv, vr, vg, vb, va = mesh:getVertex(1)   -- first vertex (1-based)
mesh:setVertex(1, { 0, -60, 0.5, 0.0, 1, 1, 0, 1 })

-- Draw mesh at a position
lurek.gfx.draw(mesh, 300, 200)

mesh:release()

--------------------------------------------------------------------------------
-- Shaders (custom WGSL fragment shaders)
--------------------------------------------------------------------------------

local shaderCode = [[
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = vec2<f32>(in.uv.x, in.uv.y);
    let wave = sin(luna_Time * 3.0 + uv.y * 10.0) * 0.5 + 0.5;
    return vec4<f32>(wave, uv.x, 1.0 - uv.y, 1.0);
}
]]

local shader = lurek.gfx.newShader(shaderCode)

-- Check / send uniforms
local has = shader:hasUniform("myParam")
shader:send("myFloat", 0.5)              -- single float
shader:send("myVec2", { 1.0, 0.5 })     -- vec2
shader:send("myVec3", { 1, 0.5, 0.25 }) -- vec3
shader:send("myVec4", { 1, 1, 0, 1 })   -- vec4 (rgba)
shader:send("myBool", true)              -- bool
shader:send("myInt", 42)                 -- int

-- Activate shader for subsequent draw calls
lurek.gfx.setShader(shader)
lurek.gfx.rectangle("fill", 100, 100, 200, 200)
lurek.gfx.setShader()       -- restore default shader

local activeShader = lurek.gfx.getShader()  -- returns Shader or nil

shader:release()

--------------------------------------------------------------------------------
-- Transforms (affine 2D transform stack)
--------------------------------------------------------------------------------

-- Push/pop preserve current transform state
lurek.gfx.push()
    lurek.gfx.translate(100, 100)
    lurek.gfx.rotate(math.pi / 4)
    lurek.gfx.scale(2, 2)
    lurek.gfx.shear(0.1, 0)
    lurek.gfx.rectangle("fill", -25, -25, 50, 50)   -- drawn at (100,100), rotated+scaled
lurek.gfx.pop()

-- Reset to identity
lurek.gfx.origin()

-- Apply raw matrix (9 elements, column-major mat3)
local mat = { 1, 0, 0,   0, 1, 0,   50, 50, 1 }  -- translate(50,50)
lurek.gfx.applyTransform(mat)

--------------------------------------------------------------------------------
-- Scissor (clipping rectangle)
--------------------------------------------------------------------------------

lurek.gfx.setScissor(50, 50, 300, 200)
lurek.gfx.rectangle("fill", 0, 0, 400, 300)    -- clipped to scissor rect
lurek.gfx.setScissor()                           -- clear scissor

local sx, sy, sw, sh = lurek.gfx.getScissor()  -- may return nothing if not set
lurek.gfx.intersectScissor(100, 100, 100, 100)  -- intersect with current

--------------------------------------------------------------------------------
-- Color mask (control which channels are written)
--------------------------------------------------------------------------------

lurek.gfx.setColorMask(true, true, true, false)   -- no alpha writes
local rm, gm, bm2, am = lurek.gfx.getColorMask()
lurek.gfx.setColorMask()                           -- restore all channels

--------------------------------------------------------------------------------
-- Wireframe
--------------------------------------------------------------------------------

lurek.gfx.setWireframe(true)
lurek.gfx.circle("fill", 200, 200, 50)    -- drawn as wireframe outline
lurek.gfx.setWireframe(false)
local wf = lurek.gfx.isWireframe()        -- false

--------------------------------------------------------------------------------
-- Stencil buffer
--------------------------------------------------------------------------------

-- Write stencil value 1 where shape is drawn
lurek.gfx.stencil("replace", 1)
    lurek.gfx.circle("fill", 200, 200, 80)
lurek.gfx.stencil()    -- end stencil write (restores to color pass)

-- Only render where stencil == 1
lurek.gfx.setStencilTest("equal", 1)
lurek.gfx.rectangle("fill", 0, 0, 400, 400)  -- masked to circle area
lurek.gfx.setStencilTest()                     -- disable stencil test

-- Stencil actions:  "replace" | "keep" | "zero" | "increment" | "decrement"
"incrementwrap" | "decrementwrap" | "invert"
-- Stencil compare:  "equal" | "notequal" | "less" | "lequal"
"greater" | "gequal" | "always" | "never"

--------------------------------------------------------------------------------
-- Window dimensions
--------------------------------------------------------------------------------

local winW = lurek.gfx.getWidth()             -- window width in pixels
local winH = lurek.gfx.getHeight()            -- window height in pixels
local ww, wh = lurek.gfx.getDimensions()

--------------------------------------------------------------------------------
-- Texture filter mode
--------------------------------------------------------------------------------

lurek.gfx.setDefaultFilter("nearest", "nearest")   -- for pixel art
lurek.gfx.setDefaultFilter("linear",  "linear", 1) -- for smooth scaling
local minF, magF, ani = lurek.gfx.getDefaultFilter()

--------------------------------------------------------------------------------
-- Renderer statistics
--------------------------------------------------------------------------------

local stats = lurek.gfx.getStats()
-- stats.drawcalls    — draw commands queued this frame
-- stats.textures     — loaded texture count
-- stats.fonts        — loaded font count
-- stats.canvases     — canvas count
-- stats.texture_memory — approximate GPU texture memory in bytes

--------------------------------------------------------------------------------
-- Screenshot
--------------------------------------------------------------------------------

-- Queue a PNG save after the current frame completes
lurek.gfx.saveScreenshot("save/screenshot.png")

--------------------------------------------------------------------------------
-- Typical game loop pattern
--------------------------------------------------------------------------------

local playerImg  -- assumed loaded in lurek.init()

-- lurek.render is called every frame to issue draw commands.
-- The engine processes the queued DrawCommands after this returns.
lurek.render = function()
    lurek.gfx.clear()

    -- Background
    lurek.gfx.setColor(0.2, 0.2, 0.4)
    lurek.gfx.rectangle("fill", 0, 0, lurek.gfx.getDimensions())

    -- Entities
    lurek.gfx.setColor(1, 1, 1)
    if playerImg then
        lurek.gfx.draw(playerImg, 100, 100)
    end

    -- UI text
    lurek.gfx.setColor(1, 1, 0)
    lurek.gfx.print("Press ESC to quit", 10, 10)
end

-- ─── Canvas ────────────────────────────────────────────────────────────────────
-- Runtime-type detection: useful when a receiving function accepts Canvas or Image.
local ctype  = canvas:type()               -- "Canvas"
local isCvs  = canvas:typeOf("Canvas")     -- true
local isImg2 = canvas:typeOf("Image")      -- false

-- ─── DrawLayer ─────────────────────────────────────────────────────────────────
-- DrawLayer accumulates z-sorted callbacks; inspect or discard them between frames.
drawlayer:queue(10, function() lurek.gfx.print("HUD", 0, 0) end)  -- enqueue at depth 10
local dlCount = drawlayer:getCount()            -- 1  (number of queued callbacks)
drawlayer:flush()                               -- sort, execute, then empty the queue
drawlayer:clear()                               -- discard all pending callbacks without executing
local dlType  = drawlayer:type()                -- "DrawLayer"
local isDL    = drawlayer:typeOf("DrawLayer")   -- true

-- ─── Font ──────────────────────────────────────────────────────────────────────
-- typeOf lets you guard shared-object parameters before calling font metrics.
local ftType  = font:type()               -- "Font"
local isFont  = font:typeOf("Font")       -- true

-- ─── Image ─────────────────────────────────────────────────────────────────────
local imgType  = image:type()             -- "Image"
local isImage  = image:typeOf("Image")    -- true

-- ─── ImageData ─────────────────────────────────────────────────────────────────
-- ImageData holds a CPU-side pixel buffer useful for procedural texture generation.
local idW    = imagedata:getWidth()           -- pixel buffer width in pixels
local idH    = imagedata:getHeight()          -- pixel buffer height in pixels
local idType = imagedata:type()               -- "ImageData"
local isID   = imagedata:typeOf("ImageData")  -- true

-- ─── Mesh ──────────────────────────────────────────────────────────────────────
local meshType = mesh:type()            -- "Mesh"
local isMesh   = mesh:typeOf("Mesh")    -- true

-- ─── NineSlice ─────────────────────────────────────────────────────────────────
-- getInsets / getTextureSize let you adjust layout when scaling a UI panel at runtime.
local nsTop, nsRight, nsBottom, nsLeft = nineslice:getInsets()   -- inset sizes in pixels
local nsW, nsH = nineslice:getTextureSize()                       -- source texture dimensions
local nsType   = nineslice:type()                                 -- "NineSlice"
local isNS     = nineslice:typeOf("NineSlice")                    -- true

-- ─── Quad ──────────────────────────────────────────────────────────────────────
local qx, qy, qw, qh = q1:getViewport()          -- (x, y, w, h) region within texture
local qtw, qth        = q1:getTextureDimensions() -- full source texture size (tw, th)
local qType           = q1:type()                 -- "Quad"
local isQuad          = q1:typeOf("Quad")         -- true

-- ─── Shader ────────────────────────────────────────────────────────────────────
-- Use hasUniform as a guard before sending per-frame values to avoid silent errors.
if shader:hasUniform("u_time") then
    shader:send("u_time", 0.0)          -- safe: only executes when uniform exists
end
local shType = shader:type()             -- "Shader"
local isShad = shader:typeOf("Shader")   -- true

-- ─── Shape ─────────────────────────────────────────────────────────────────────
-- clear() resets the command list so you can rebuild the shape each frame cheaply.
shape:clear()                             -- discard all previously queued commands
local cmdN = shape:getCommandCount()      -- 0  (count after clear)
shape:setLineWidth(2.0)                   -- stroke width for subsequent outline commands
shape:line(0, 0, 100, 100)               -- queue a line segment command
shape:polyline(0, 0, 50, 50, 100, 0)    -- queue a multi-point connected polyline
local shpType = shape:type()             -- "Shape"
local isShape = shape:typeOf("Shape")    -- true

-- ─── SpriteBatch ───────────────────────────────────────────────────────────────
local sbType = spritebatch:type()              -- "SpriteBatch"
local isSB   = spritebatch:typeOf("SpriteBatch")  -- true

-- ─── lurek.graphics ─────────────────────────────────────────────────────────────
-- captureScreenshot delivers its ImageData asynchronously after the frame completes.
lurek.graphics.captureScreenshot(function(imgdata) end)
-- clearStencil resets the stencil buffer to defaults — call before overwriting an old mask.
lurek.graphics.clearStencil()
-- drawNineSlice must be called inside lurek.render or lurek.render_ui.
lurek.graphics.drawNineSlice(nineslice, 50, 50, 320, 240)  -- x, y, w, h
local cw2, ch2 = lurek.graphics.getCanvasSize(canvas)          -- canvas dimensions in pixels
local depthMode, depthWrite = lurek.graphics.getDepthMode()    -- e.g. "lequal", true
local lh = lurek.graphics.getFontLineHeight(font)              -- current line height multiplier
local stAction, stCompare, stValue = lurek.graphics.getStencilMode()  -- active stencil state
local dl2  = lurek.graphics.newDrawLayer()                     -- new z-ordered draw-call queue
local ns2  = lurek.graphics.newNineSlice(image, 8, 8, 8, 8)  -- 8 px uniform insets
local isNS2 = ns2:typeOf("NineSlice")                        -- true
local shape2 = lurek.graphics.newShape()                       -- new empty CompoundShape
lurek.graphics.setDepthMode("lequal")         -- "lequal", "less", "greater", "always", "never"
lurek.graphics.setFontLineHeight(font, 1.2)   -- line spacing multiplier
lurek.graphics.setStencilMode("none")         -- "none", "write", "test"
