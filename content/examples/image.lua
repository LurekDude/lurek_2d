-- examples/image.lua
-- luna.img — CPU-side pixel buffer manipulation (ImageData and CompressedImageData).
-- All luna.img API methods demonstrated with code and comments.
-- Includes all 20 image-processing effects added in 0.6.0.
-- This file is documentation code, not a runnable game.

-- ── ImageData ────────────────────────────────────────────────────────────────

-- newImageData(width, height) → ImageData
-- Creates a new RGBA8 pixel buffer filled with transparent black.
local img_data = luna.img.newImageData(64, 64)

-- newImageData(path) → ImageData
-- Loads an image file from the game filesystem into a CPU pixel buffer.
local loaded = luna.img.newImageData("textures/player.png")

-- newImageData(width, height, bytes) → ImageData
-- Creates an ImageData from raw bytes (must be width*height*4 bytes, RGBA8 order).
local raw_bytes = string.rep("\xFF\x00\x00\xFF", 4 * 4)  -- 4x4 solid red
local from_bytes = luna.img.newImageData(4, 4, raw_bytes)

-- ── ImageData : dimensions ────────────────────────────────────────────────────

local w = img_data:getWidth()         -- 64
local h = img_data:getHeight()        -- 64
local iw, ih = img_data:getDimensions()  -- 64, 64

-- ── ImageData : pixel access ─────────────────────────────────────────────────
-- All pixel coordinates are 0-based (top-left is 0,0).
-- Channel values are integers 0–255.

-- getPixel(x, y) → r, g, b, a
local r, g, b, a = img_data:getPixel(0, 0)  -- 0, 0, 0, 0  (transparent black)

-- setPixel(x, y, r, g, b, a)
img_data:setPixel(10, 10, 255, 128, 0, 255)   -- solid orange at (10,10)
img_data:setPixel(20, 20, 0, 200, 255, 180)   -- translucent cyan at (20,20)

-- ── ImageData : batch operations ─────────────────────────────────────────────

-- mapPixel(fn) — apply fn(x, y, r, g, b, a) → r, g, b, a to every pixel
-- Useful for image effects and procedural generation.
img_data:mapPixel(function(x, y, r, g, b, a)
    -- Checkerboard pattern
    if (x + y) % 2 == 0 then
        return 255, 255, 255, 255  -- white
    else
        return 0, 0, 0, 255        -- black
    end
end)

-- paste(source_img_data, dest_x, dest_y)
-- Copies all pixels from source into this buffer at (dest_x, dest_y).
local stamp = luna.img.newImageData(8, 8)
stamp:mapPixel(function(_, _, _, _, _, _)
    return 255, 0, 0, 255  -- fill with red
end)

img_data:paste(stamp, 5, 5)  -- paste red 8x8 square at (5,5) in img_data

-- ── ImageData : export ────────────────────────────────────────────────────────

-- getString() → string
-- Returns the raw RGBA8 pixel bytes as a Lua string (width * height * 4 bytes).
local raw = img_data:getString()
local byte_count = #raw  -- 64 * 64 * 4 = 16384

-- encode("png") → string  — PNG-compressed bytes, ready to write to a file.
local png_bytes = img_data:encode("png")
luna.fs.write("output.png", png_bytes)

-- ── Using ImageData to modify a GPU texture ───────────────────────────────────

-- Luna2D allows uploading an ImageData as a GPU texture:
--   local tex = luna.gfx.newImage(img_data)
--   luna.gfx.draw(tex, x, y)

-- ── CompressedImageData ───────────────────────────────────────────────────────

-- newCompressedData(path) → CompressedImageData
-- Loads a DXT/BCn compressed texture from disk (e.g. a .dds file).
-- The data stays GPU-compressed in CPU memory for fast upload.
-- local cdata = luna.img.newCompressedData("textures/rock_bc3.dds")

-- isCompressed(imagedata_value) → boolean
-- Returns true if the value is a CompressedImageData (not a standard ImageData).
-- local is_compressed = luna.img.isCompressed(cdata)  -- true
-- local is_standard   = luna.img.isCompressed(img_data)  -- false

-- CompressedImageData : dimensions
-- cdata:getWidth()   → integer
-- cdata:getHeight()  → integer
-- cdata:getDimensions() → w, h

-- CompressedImageData : format
-- cdata:getFormat() → string  e.g. "DXT1", "DXT5", "BC7"

-- CompressedImageData : mip levels
-- cdata:getMipmapCount() → integer  (1 = no mipmaps)
-- cdata:getString(mip_level?) → raw bytes for a specific mip level (0-based)
-- cdata:getSize(mip_level?) → integer  byte count for that mip level

-- ── Image-processing effects ──────────────────────────────────────────────────
-- All 20 effects operate on ImageData in CPU memory.
-- Effects that work in-place take no return value; geometric operations that
-- produce a new image return a new ImageData.

local pixels = luna.img.newImageData(64, 64)

-- ── Color / Tone — in-place ───────────────────────────────────────────────────

-- brightness(factor)  — multiply RGB by factor; >1 brightens, <1 darkens, 0 = black
pixels:brightness(1.5)      -- 50% brighter
pixels:brightness(0.7)      -- 30% darker

-- contrast(factor)  — scale distance of each channel from mid-grey (128)
pixels:contrast(1.2)        -- higher contrast
pixels:contrast(0.8)        -- lower contrast (flatter look)

-- saturation(factor)  — 0 = greyscale, 1 = original, >1 = boosted
pixels:saturation(0.0)      -- fully desaturated (greyscale)
pixels:saturation(1.8)      -- over-saturated

-- gamma(gamma)  — apply gamma correction per channel
pixels:gamma(2.2)           -- standard monitor gamma (lighten)
pixels:gamma(0.45)          -- inverse gamma (darken midtones)

-- tint(tr, tg, tb, factor)  — blend each pixel toward tint colour
pixels:tint(255, 200, 150, 0.3)  -- 30% warm orange cast
pixels:tint(0, 0, 0, 1.0)        -- factor=1.0 → fully black (destructive)

-- ── Filters — in-place ───────────────────────────────────────────────────────

-- grayscale()  — perceptual luminance (0.2126R + 0.7152G + 0.0722B) to all channels
pixels:grayscale()

-- sepia()  — classic warm sepia tone using the standard matrix
pixels:sepia()

-- invert()  — 255 - channel for each RGB channel; alpha unchanged
pixels:invert()

-- threshold(value)  — pixels above luminance threshold → white; below → black
pixels:threshold(128)   -- midpoint threshold

-- posterize(levels)  — reduce each channel to N evenly-spaced levels (min 2)
pixels:posterize(4)     -- 4-level per channel (paint.net-style)
pixels:posterize(2)     -- pure black-and-white per channel

-- fill(r, g, b, a)  — overwrite every pixel with the given solid colour
pixels:fill(255, 0, 0, 255)   -- solid red
pixels:fill(0, 0, 0, 0)       -- fully transparent black

-- noise(amount)  — add pseudo-random noise ±amount to each RGB channel
pixels:noise(20)   -- subtle grain
pixels:noise(80)   -- heavy grain

-- alphaMask(factor)  — multiply alpha by factor; 0=transparent, 1=unchanged
pixels:alphaMask(0.5)   -- 50% opacity
pixels:alphaMask(0.0)   -- fully transparent

-- ── Geometric — in-place ─────────────────────────────────────────────────────

-- flipHorizontal()  — mirror left ↔ right; dimensions unchanged
pixels:flipHorizontal()

-- flipVertical()  — mirror top ↔ bottom; dimensions unchanged
pixels:flipVertical()

-- ── Geometric — returns new ImageData ────────────────────────────────────────

-- rotate90cw()  — rotate 90° clockwise; new_width = old_height, new_height = old_width
local rotated = pixels:rotate90cw()

-- crop(x, y, w, h)  — extract a sub-rectangle; returns nil if out of bounds
local cropped = pixels:crop(10, 10, 32, 32)  -- 32×32 region from (10,10)
if cropped then
    luna.fs.write("crop.png", cropped:encode("png"))
end

-- resizeNearest(new_w, new_h)  — nearest-neighbour scale to any size
local thumb = pixels:resizeNearest(16, 16)

-- ── Convolution — returns new ImageData ──────────────────────────────────────

-- blur(radius)  — separated box blur; radius=0 returns a copy
local blurred1 = pixels:blur(0)   -- copy
local blurred2 = pixels:blur(3)   -- soft blur (7×7 window)

-- sharpen()  — 3×3 unsharp (5C − N − S − E − W); alpha copied from source
local sharpened = pixels:sharpen()

-- ── Common pipeline: load → edit → upload ────────────────────────────────────
--[[
function luna.init()
    local pixels = luna.img.newImageData("textures/player.png")
    pixels:brightness(1.2)     -- slightly brighter
    pixels:sharpen()           -- wrong: sharpen returns NEW image
    pixels = pixels:sharpen()  -- correct: assign the returned image
    pixels:sepia()             -- apply sepia in-place
    player_tex = luna.gfx.newImage(pixels)
end
]]

-- ── Typical use — procedural texture ─────────────────────────────────────────

--[[
function luna.init()
    local pixels = luna.img.newImageData(256, 256)
    pixels:mapPixel(function(x, y)
        -- Simple noise-based terrain colour
        local n = luna.math.noise(x / 50, y / 50)
        if n > 0.3 then
            return 80, 140, 40, 255    -- grass
        elseif n > 0 then
            return 200, 170, 100, 255  -- sand
        else
            return 20, 80, 200, 255    -- water
        end
    end)
    pixels:saturation(1.3)     -- boost saturation before uploading
    terrain_tex = luna.gfx.newImage(pixels)
end

function luna.render()
    luna.gfx.draw(terrain_tex, 0, 0)
end
]]

-- ── LayeredImage — compositing layer stack ──────────────────────────────────

--[[
-- Create a 128x128 layered canvas
local stack = luna.img.newLayeredImage(128, 128)

-- Add a red background layer
local bg_idx = stack:addLayer("background")
local bg_px = luna.img.newImageData(128, 128)
bg_px:fill(200, 60, 60, 255)
stack:setLayer(bg_idx, bg_px)

-- Add a semi-transparent blue overlay
local fg_idx = stack:addLayer("overlay")
local fg_px = luna.img.newImageData(128, 128)
fg_px:fill(40, 80, 220, 128)       -- alpha = 128 → half transparent
stack:setLayer(fg_idx, fg_px)

-- Per-layer opacity (independent of per-pixel alpha)
stack:setOpacity(fg_idx, 0.8)      -- 80% layer opacity
stack:setVisible(bg_idx, true)

-- Reorder layers
stack:swapLayers(1, 2)             -- swap bg and overlay in z-order

-- Flatten all visible layers into one ImageData (Porter-Duff "over")
local flat = stack:merge()
local texture = luna.gfx.newImage(flat)
]]

-- ── LIMG binary save / load ─────────────────────────────────────────────────

--[[
-- Save a flat ImageData as a compressed .lim binary file
local img = luna.img.newImageData(64, 64)
img:fill(180, 90, 30, 255)
luna.img.saveImage(img, "my_image.lim")

-- Load it back
local loaded = luna.img.loadImage("my_image.lim")
assert(loaded:getWidth() == 64)

-- Save a full LayeredImage stack
local stack = luna.img.newLayeredImage(64, 64)
stack:addLayer("base")
stack:addLayer("decal")
stack:setOpacity(2, 0.5)
stack:save("my_layers.lim")         -- :save() method on LayeredImage

-- Load it back
local stack2 = luna.img.loadLayered("my_layers.lim")
assert(stack2:layerCount() == 2)
assert(stack2:getName(2) == "decal")
]]
