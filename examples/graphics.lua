-- examples/graphics.lua
-- 2D drawing, images, fonts, canvases, meshes, shaders and sprite batches
-- API: luna.gfx

--------------------------------------------------------------------------------
-- Drawing mode values
--   "fill"  — solid filled shape
--   "line"  — outline only
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Color and background
--------------------------------------------------------------------------------

luna.gfx.setColor(1, 0.5, 0, 1)             -- r, g, b, a
local r, g, b, a = luna.gfx.getColor()      -- → r, g, b, a

luna.gfx.setBackgroundColor(0.1, 0.1, 0.15)
local br, bg, bb, ba = luna.gfx.getBackgroundColor()

--------------------------------------------------------------------------------
-- Primitive shapes
--------------------------------------------------------------------------------

-- Rectangle (last two args are optional corner rx/ry for rounding)
luna.gfx.rectangle("fill", 10, 10, 200, 100)
luna.gfx.rectangle("line", 220, 10, 200, 100, 8, 8)  -- rounded corners

-- Circle
luna.gfx.circle("fill", 100, 100, 50)
luna.gfx.circle("line", 250, 100, 50)

-- Ellipse
luna.gfx.ellipse("fill", 100, 200, 80, 40)
luna.gfx.ellipse("line", 280, 200, 80, 40)

-- Triangle
luna.gfx.triangle("fill", 100, 250, 150, 320, 50, 320)
luna.gfx.triangle("line", 250, 250, 300, 320, 200, 320)

-- Line / polyline
luna.gfx.line(0, 0, 100, 100)
luna.gfx.line(100, 100, 200, 50, 300, 100, 400, 50)  -- multi-segment polyline

-- Polygon (flat list or table)
luna.gfx.polygon("fill", 100, 100, 150, 80, 200, 100, 180, 150, 120, 150)
luna.gfx.polygon("fill", { 300, 100, 350, 80, 400, 100, 380, 150, 320, 150 })

-- Arc
luna.gfx.arc("fill", 200, 200, 80, 0, math.pi, 32)  -- angle in radians, segments
luna.gfx.arc("line", 400, 200, 80, -math.pi/2, math.pi)

-- Points
luna.gfx.points(10, 10, 20, 20, 30, 30)
luna.gfx.points({ {10, 40}, {20, 40}, {30, 40} })  -- table form

--------------------------------------------------------------------------------
-- Line and point style
--------------------------------------------------------------------------------

luna.gfx.setLineWidth(2)
local lw = luna.gfx.getLineWidth()  -- 2.0

luna.gfx.setPointSize(4)
local ps = luna.gfx.getPointSize()  -- 4.0

--------------------------------------------------------------------------------
-- Blend modes
--------------------------------------------------------------------------------

luna.gfx.setBlendMode("alpha")        -- default (alpha blending)
luna.gfx.setBlendMode("add")          -- additive (glow, particles)
luna.gfx.setBlendMode("multiply")     -- multiply (shadows)
luna.gfx.setBlendMode("replace")      -- overwrite
luna.gfx.setBlendMode("screen")       -- screen (lightening)
local bm = luna.gfx.getBlendMode()   -- "alpha"

--------------------------------------------------------------------------------
-- Clear the draw buffer
--------------------------------------------------------------------------------

luna.gfx.clear()             -- clear to background color
luna.gfx.clear(0, 0, 0)     -- explicit r, g, b

--------------------------------------------------------------------------------
-- Images
--------------------------------------------------------------------------------

-- Load from file
local img = luna.gfx.newImage("player.png")
local iw = img:getWidth()           -- pixel width
local ih = img:getHeight()          -- pixel height
local idw, idh = img:getDimensions()

-- Draw an image
luna.gfx.draw(img, 100, 100)
-- draw(img, x, y, rotation, scaleX, scaleY, offsetX, offsetY)
luna.gfx.draw(img, 200, 100, 0, 2, 2, iw/2, ih/2)  -- centered, scaled

-- Release GPU memory
img:release()

-- Load from ImageData (CPU pixel buffer)
local id = luna.img.newImageData(64, 64)
local imgFromData = luna.gfx.newImage(id)

--------------------------------------------------------------------------------
-- Quads (sub-image crop)
--------------------------------------------------------------------------------

local spriteSheet = luna.gfx.newImage("spritesheet.png")
local sw, sh = spriteSheet:getDimensions()

-- newQuad(x, y, w, h, sourceW, sourceH)
local q1 = luna.gfx.newQuad(0,   0, 32, 32, sw, sh)   -- frame 1
local q2 = luna.gfx.newQuad(32,  0, 32, 32, sw, sh)   -- frame 2
local q3 = luna.gfx.newQuad(64,  0, 32, 32, sw, sh)   -- frame 3

-- Draw with quad
luna.gfx.drawq(spriteSheet, q1, 300, 100)
luna.gfx.drawq(spriteSheet, q2, 340, 100)

-- Quad inspection
local qx, qy, qw, qh = q1:getViewport()       -- → x, y, w, h
q1:setViewport(0, 32, 32, 32)                   -- shift to next row
local tsw, tsh = q1:getTextureDimensions()     -- → sw, sh
local qt = q1:typeOf()                          -- "Quad"

--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------

-- Load a font, specify size in pixels
local font = luna.gfx.newFont("font.ttf", 16)
luna.gfx.setFont(font)
local activeFont = luna.gfx.getFont()     -- the LuaFont or nil

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
local textW = luna.gfx.getFontWidth(font, "Hello!")
local textH = luna.gfx.getFontHeight(font)
local textA = luna.gfx.getFontAscent(font)
local textD = luna.gfx.getFontDescent(font)
local wrappedLines, w2 = luna.gfx.getFontWrap("Long text", 100)

-- Draw text
luna.gfx.print("Hello, World!")
luna.gfx.print("At position", 100, 200)
luna.gfx.print("Scaled", 100, 230, 1.5)  -- scale factor

-- Wrapped / aligned text
luna.gfx.printf("Left aligned text", 50, 100, 300, "left")
luna.gfx.printf("Centered heading", 50, 140, 300, "center")
luna.gfx.printf("Right aligned", 50, 180, 300, "right")
luna.gfx.printf("Justified paragraph text here", 50, 220, 300, "justify")

--------------------------------------------------------------------------------
-- Canvases (render-to-texture)
--------------------------------------------------------------------------------

local canvas = luna.gfx.newCanvas(800, 600)
local cw = canvas:getWidth()     -- 800
local ch = canvas:getHeight()    -- 600
local cdw, cdh = canvas:getDimensions()

-- Render into canvas
luna.gfx.setCanvas(canvas)
    luna.gfx.clear(0, 0, 0)
    luna.gfx.rectangle("fill", 10, 10, 100, 100)
    luna.gfx.print("Inside canvas", 10, 120)
luna.gfx.setCanvas()       -- pass nothing to restore screen

local active = luna.gfx.getCanvas()  -- returns Canvas or nil

-- Draw canvas to screen like an image
luna.gfx.draw(canvas, 0, 0)

canvas:release()

--------------------------------------------------------------------------------
-- Sprite batches (batch-draw many instances of one texture)
--------------------------------------------------------------------------------

local batchtex = luna.gfx.newImage("coin.png")
local batch = luna.gfx.newSpriteBatch(batchtex, 500)   -- max 500 sprites

-- Add sprites: add(x, y, r?, sx?, sy?, ox?, oy?) → integer id
batch:add(100, 100)
batch:add(200, 100, 0, 1.5, 1.5)
batch:add(300, 100, math.pi/4, 2, 2, 8, 8)  -- rotated, scaled, centered

local count = batch:getCount()          -- 3
local capacity = batch:getBufferSize()  -- 500

-- Draw all sprites
luna.gfx.draw(batch, 0, 0)

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
local mesh = luna.gfx.newMesh(vertices, "triangles")  -- or "fan", "strip"

-- Assign a texture to mesh UV coordinates
mesh:setTexture(batchtex)

-- Inspect / modify vertices
local vc = mesh:getVertexCount()                 -- 3
local vx, vy, vu, vv, vr, vg, vb, va = mesh:getVertex(1)   -- first vertex (1-based)
mesh:setVertex(1, { 0, -60, 0.5, 0.0, 1, 1, 0, 1 })

-- Draw mesh at a position
luna.gfx.draw(mesh, 300, 200)

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

local shader = luna.gfx.newShader(shaderCode)

-- Check / send uniforms
local has = shader:hasUniform("myParam")
shader:send("myFloat", 0.5)              -- single float
shader:send("myVec2", { 1.0, 0.5 })     -- vec2
shader:send("myVec3", { 1, 0.5, 0.25 }) -- vec3
shader:send("myVec4", { 1, 1, 0, 1 })   -- vec4 (rgba)
shader:send("myBool", true)              -- bool
shader:send("myInt", 42)                 -- int

-- Activate shader for subsequent draw calls
luna.gfx.setShader(shader)
luna.gfx.rectangle("fill", 100, 100, 200, 200)
luna.gfx.setShader()       -- restore default shader

local activeShader = luna.gfx.getShader()  -- returns Shader or nil

shader:release()

--------------------------------------------------------------------------------
-- Transforms (affine 2D transform stack)
--------------------------------------------------------------------------------

-- Push/pop preserve current transform state
luna.gfx.push()
    luna.gfx.translate(100, 100)
    luna.gfx.rotate(math.pi / 4)
    luna.gfx.scale(2, 2)
    luna.gfx.shear(0.1, 0)
    luna.gfx.rectangle("fill", -25, -25, 50, 50)   -- drawn at (100,100), rotated+scaled
luna.gfx.pop()

-- Reset to identity
luna.gfx.origin()

-- Apply raw matrix (9 elements, column-major mat3)
local mat = { 1, 0, 0,   0, 1, 0,   50, 50, 1 }  -- translate(50,50)
luna.gfx.applyTransform(mat)

--------------------------------------------------------------------------------
-- Scissor (clipping rectangle)
--------------------------------------------------------------------------------

luna.gfx.setScissor(50, 50, 300, 200)
luna.gfx.rectangle("fill", 0, 0, 400, 300)    -- clipped to scissor rect
luna.gfx.setScissor()                           -- clear scissor

local sx, sy, sw, sh = luna.gfx.getScissor()  -- may return nothing if not set
luna.gfx.intersectScissor(100, 100, 100, 100)  -- intersect with current

--------------------------------------------------------------------------------
-- Color mask (control which channels are written)
--------------------------------------------------------------------------------

luna.gfx.setColorMask(true, true, true, false)   -- no alpha writes
local rm, gm, bm2, am = luna.gfx.getColorMask()
luna.gfx.setColorMask()                           -- restore all channels

--------------------------------------------------------------------------------
-- Wireframe
--------------------------------------------------------------------------------

luna.gfx.setWireframe(true)
luna.gfx.circle("fill", 200, 200, 50)    -- drawn as wireframe outline
luna.gfx.setWireframe(false)
local wf = luna.gfx.isWireframe()        -- false

--------------------------------------------------------------------------------
-- Stencil buffer
--------------------------------------------------------------------------------

-- Write stencil value 1 where shape is drawn
luna.gfx.stencil("replace", 1)
    luna.gfx.circle("fill", 200, 200, 80)
luna.gfx.stencil()    -- end stencil write (restores to color pass)

-- Only render where stencil == 1
luna.gfx.setStencilTest("equal", 1)
luna.gfx.rectangle("fill", 0, 0, 400, 400)  -- masked to circle area
luna.gfx.setStencilTest()                     -- disable stencil test

-- Stencil actions:  "replace" | "keep" | "zero" | "increment" | "decrement"
--                   "incrementwrap" | "decrementwrap" | "invert"
-- Stencil compare:  "equal" | "notequal" | "less" | "lequal"
--                   "greater" | "gequal" | "always" | "never"

--------------------------------------------------------------------------------
-- Window dimensions
--------------------------------------------------------------------------------

local winW = luna.gfx.getWidth()             -- window width in pixels
local winH = luna.gfx.getHeight()            -- window height in pixels
local ww, wh = luna.gfx.getDimensions()

--------------------------------------------------------------------------------
-- Texture filter mode
--------------------------------------------------------------------------------

luna.gfx.setDefaultFilter("nearest", "nearest")   -- for pixel art
luna.gfx.setDefaultFilter("linear",  "linear", 1) -- for smooth scaling
local minF, magF, ani = luna.gfx.getDefaultFilter()

--------------------------------------------------------------------------------
-- Renderer statistics
--------------------------------------------------------------------------------

local stats = luna.gfx.getStats()
-- stats.drawcalls    — draw commands queued this frame
-- stats.textures     — loaded texture count
-- stats.fonts        — loaded font count
-- stats.canvases     — canvas count
-- stats.texture_memory — approximate GPU texture memory in bytes

--------------------------------------------------------------------------------
-- Screenshot
--------------------------------------------------------------------------------

-- Queue a PNG save after the current frame completes
luna.gfx.saveScreenshot("save/screenshot.png")

--------------------------------------------------------------------------------
-- Typical game loop pattern
--------------------------------------------------------------------------------

local playerImg  -- assumed loaded in luna.load()

luna.draw = function()
    luna.gfx.clear()

    -- Background
    luna.gfx.setColor(0.2, 0.2, 0.4)
    luna.gfx.rectangle("fill", 0, 0, luna.gfx.getDimensions())

    -- Entities
    luna.gfx.setColor(1, 1, 1)
    if playerImg then
        luna.gfx.draw(playerImg, 100, 100)
    end

    -- UI text
    luna.gfx.setColor(1, 1, 0)
    luna.gfx.print("Press ESC to quit", 10, 10)
end
