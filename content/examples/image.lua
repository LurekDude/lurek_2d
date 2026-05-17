-- content/examples/image.lua
-- lurek.image API examples: creation, pixel ops, filters, drawing, layers, palettes, provinces.
-- Run: cargo run -- content/examples/image.lua

-- =============================================================================
-- Module-level constructors
-- =============================================================================

--@api-stub: lurek.image.newImageData
-- Creates empty image data from dimensions or decodes image data from a GameFS filename
do
  -- Create a blank 64x64 canvas (all pixels start as transparent black).
  -- Use this when you need a CPU-side image for procedural generation or compositing.
  local hero = lurek.image.newImageData(64, 64)

  -- You can also create from file: lurek.image.newImageData("assets/textures/hero.png")
  -- The engine decodes PNG/BMP/TGA from GameFS and returns an LImageData handle.
  local scratch = lurek.image.newImageData(64, 64)
  scratch:fill(0, 0, 0, 0) -- clear to transparent for use as an overlay buffer
  lurek.log.info("loaded hero " .. hero:getWidth() .. "x" .. hero:getHeight(), "image")
end

--@api-stub: lurek.image.newImageDataFromBytes
-- Creates image data from raw RGBA bytes and explicit dimensions
do
  -- Build an image directly from raw RGBA8 bytes. Each pixel is 4 bytes: R, G, B, A.
  -- Useful when receiving pixel data from network, procedural generators, or compute shaders.
  -- Total byte count must equal width * height * 4.
  local width, height = 4, 4
  local pixels = string.rep(string.char(0, 128, 255, 255), width * height) -- solid sky blue
  local img = lurek.image.newImageDataFromBytes(width, height, pixels)
  lurek.log.info("fromBytes " .. img:getWidth() .. "x" .. img:getHeight(), "image")
end

--@api-stub: lurek.image.newCompressedData
-- Loads DDS compressed image data from GameFS
do
  -- DDS textures stay compressed on the GPU (BC1/BC3/BC7), saving VRAM.
  -- Use for large terrain textures, tilesets, and backgrounds.
  -- Returns LCompressedImageData with mipmap info for trilinear filtering.
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local mips = (cd and cd:getMipmapCount() or 0)
  lurek.log.info("dds " .. (cd and cd:getFormat() or "unknown") .. " mips=" .. mips, "image")
end

--@api-stub: lurek.image.isCompressed
-- Returns whether a GameFS image file begins with DDS compressed image magic bytes
do
  -- Check before loading: pick the right loader path (compressed vs raw decode).
  -- Avoids error handling when you support both DDS and PNG assets.
  local path = "assets/terrain_bc1.dds"
  local _ok_ic, _is_c = pcall(lurek.image.isCompressed, path)
  if _ok_ic and _is_c then
    -- File is DDS compressed: load directly to GPU format
    pcall(lurek.image.newCompressedData, path)
  else
    -- Regular image: decode to RGBA on CPU
    lurek.image.newImageData(64, 64)
  end
end

--@api-stub: lurek.image.newLayeredImage
-- Creates a layered image stack with one or more blank layers
do
  -- Layered images work like Photoshop documents: separate layers with opacity and visibility.
  -- Useful for character dressing systems, map editors, or painting tools.
  local doc = lurek.image.newLayeredImage(256, 256)
  local bg = doc:addLayer("background") -- layer 1: solid background
  local fg = doc:addLayer("foreground") -- layer 2: character/UI overlay
  lurek.log.info("layers bg=" .. bg .. " fg=" .. fg, "image")
end

--@api-stub: lurek.image.newPaletteLut
-- Creates an empty palette lookup table
do
  -- Palette LUTs remap pixel colors without per-pixel callback overhead.
  -- Perfect for team recoloring, damage flash effects, or seasonal palette swaps.
  local lut = lurek.image.newPaletteLut()
  local before = lut:getColorCount()
  lurek.log.info("new lut entries=" .. before, "image")
end

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province id grid from an image file under the current game directory
do
  -- Province maps use color-coded images where each unique color = one province.
  -- The engine decodes the image and assigns integer IDs for fast lookup.
  -- Used in strategy games for territory selection, pathfinding, and borders.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  lurek.log.info("loaded " .. count .. " provinces", "map")
end

-- =============================================================================
-- Module-level I/O
-- =============================================================================

--@api-stub: lurek.image.saveImage
-- Saves an image data object to a path under the current game directory
do
  -- saveImage writes the engine's internal .limg format (fast load/save, lossless).
  -- Use for runtime-generated content like procedural terrain or player drawings.
  local img = lurek.image.newImageData(64, 64)
  img:fill(255, 128, 0, 255) -- fill with orange
  lurek.image.saveImage(img, "save/orange64.limg")
end

--@api-stub: lurek.image.savePNG
-- Encodes image data as PNG and writes it under the current game directory
do
  -- savePNG is slower than saveImage but produces portable files.
  -- Use for screenshots, exported art, or sharing with external tools.
  local shot = lurek.image.newImageData(128, 64)
  shot:fill(20, 30, 40, 255) -- dark background
  shot:drawCircle(64, 32, 24, 255, 200, 0, 255) -- golden sun
  lurek.image.savePNG(shot, "save/screenshot.png")
end

--@api-stub: lurek.image.loadImage
-- Loads and decodes image data from GameFS
do
  -- loadImage reads .limg files saved by saveImage.
  -- Use to reload procedural content between sessions.
  local restored = lurek.image.loadImage("save/orange64.limg")
  local w, h = restored:getDimensions()
  lurek.log.info("restored " .. w .. "x" .. h, "image")
end

--@api-stub: lurek.image.loadLayered
-- Loads a serialized layered image stack from GameFS
do
  -- Reopen a previously saved layered document (painting tool, map editor, etc.)
  pcall(function()
    local doc = lurek.image.loadLayered("save/painting.limg")
    local count = doc:layerCount()
    lurek.log.info("painting reopened with " .. count .. " layers", "image")
  end)
end

--@api-stub: lurek.image.fromScreen
-- Returns a completed screen capture image or requests one for a future call
do
  -- Screen capture is asynchronous: first call requests the capture, returns nil.
  -- A subsequent call returns the actual LImageData once the GPU readback completes.
  -- Use for screenshot features, in-game photo modes, or visual regression testing.
  local first = lurek.image.fromScreen()
  if first == nil then
    -- Capture was requested; on next frame the data should be ready
    local later = lurek.image.fromScreen()
    if later then
      lurek.image.savePNG(later, "save/screen_capture.png")
    end
  end
end

-- =============================================================================
-- LImageData — dimensions & pixel access
-- =============================================================================

--@api-stub: LImageData:getWidth
-- Returns the width of this image data in pixels
do
  local img = lurek.image.newImageData(64, 32)
  -- Use getWidth to calculate UV coordinates or tile positions
  lurek.log.info("width=" .. img:getWidth(), "image")
end

--@api-stub: LImageData:getHeight
-- Returns the height of this image data in pixels
do
  local img = lurek.image.newImageData(64, 32)
  -- Use getHeight with getWidth to iterate over all pixels
  lurek.log.info("height=" .. img:getHeight(), "image")
end

--@api-stub: LImageData:getDimensions
-- Returns image dimensions
do
  -- getDimensions returns both width and height in one call (avoids two method calls)
  local img = lurek.image.newImageData(128, 64)
  local w, h = img:getDimensions()
  lurek.log.info("dimensions=" .. w .. "x" .. h, "image")
end

--@api-stub: LImageData:getPixel
-- Returns RGBA channels at a pixel coordinate
do
  -- getPixel reads the color at (x, y). Channels are 0-255 integers.
  -- Use for collision masks, color picking, or sampling terrain height from color.
  local img = lurek.image.newImageData(8, 8)
  img:setPixel(2, 3, 255, 128, 0, 255) -- paint an orange pixel
  local r, g, b, a = img:getPixel(2, 3)
  lurek.log.info("pixel(2,3)=" .. r .. "," .. g .. "," .. b .. "," .. a, "image")
end

--@api-stub: LImageData:setPixel
-- Sets RGBA channels at a pixel coordinate
do
  -- setPixel writes one pixel at (x, y) with RGBA channels 0-255.
  -- Use for drawing individual dots, placing markers on minimaps, or procedural art.
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(0, 0, 255, 0, 0, 255)   -- red at top-left
  img:setPixel(7, 7, 0, 255, 0, 255)   -- green at center
  local r, g, b = img:getPixel(7, 7)
  lurek.log.info("center r=" .. r .. " g=" .. g, "image")
end

--@api-stub: LImageData:encode
-- Encodes image data in a supported format
do
  -- encode("png") returns a PNG byte string without writing to disk.
  -- Use for network transmission, clipboard, or in-memory texture upload.
  local img = lurek.image.newImageData(16, 16)
  img:fill(200, 100, 50, 255)
  local bytes = img:encode("png")
  lurek.log.info("encoded size=" .. #bytes .. " bytes", "image")
end

--@api-stub: LImageData:getString
-- Returns the raw pixel byte string of this image data
do
  -- getString returns the raw RGBA8 buffer as a Lua string (width * height * 4 bytes).
  -- Useful for hashing, checksums, or passing to FFI routines.
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)
  local raw = img:getString()
  lurek.log.info("raw bytes=" .. #raw, "image")
end

--@api-stub: LImageData:getRawBytes
-- Returns the raw pixel byte string of this image data without any format conversion.
do
  -- getRawBytes is identical to getString — returns RGBA8 buffer directly.
  -- Use when you need the pixel buffer for compute, serialization, or bit manipulation.
  local img = lurek.image.newImageData(4, 4)
  local bytes = img:getRawBytes()
  lurek.log.debug("raw bytes=" .. #bytes, "image")
end

--@api-stub: LImageData:setRawData
-- Replaces the image byte buffer with raw bytes
do
  -- setRawData overwrites ALL pixels from a raw RGBA8 string.
  -- The string length must equal width * height * 4 bytes exactly.
  -- Use for procedural generation or importing external pixel data.
  local img = lurek.image.newImageData(2, 2)
  -- 4 pixels, each 4 bytes (RGBA): solid red
  local raw = string.rep(string.char(255, 0, 0, 255), 4)
  img:setRawData(raw)
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("raw r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

-- =============================================================================
-- LImageData — per-pixel transforms
-- =============================================================================

--@api-stub: LImageData:mapPixel
-- Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values
do
  -- mapPixel calls your function for each pixel: fn(x, y, r, g, b, a) -> r, g, b, a.
  -- Use for custom color grading, procedural patterns, or per-pixel game logic.
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 150, 200, 255)
  img:mapPixel(function(x, y, r, g, b, a)
    return b, g, r, a   -- swap red and blue channels (cool tint effect)
  end)
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("after mapPixel r=" .. r .. " b=" .. b, "image")
end

--@api-stub: LImageData:mapPixels
-- Iterates over every pixel and replaces its color with the return value of the callback
do
  -- mapPixels is an alias for mapPixel with identical behavior.
  -- Both accept fn(x, y, r, g, b, a) -> r, g, b, a.
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)
  img:mapPixels(function(x, y, r, g, b, a)
    return g, r, b, a   -- swap R and G channels
  end)
  local r, g = img:getPixel(0, 0)
  lurek.log.info("after map: r=" .. r .. " g=" .. g, "image")
end

-- =============================================================================
-- LImageData — color adjustments (in-place)
-- =============================================================================

--@api-stub: LImageData:brightness
-- Applies a brightness factor to this image in place
do
  -- Factor < 1.0 darkens, > 1.0 brightens. Channels are clamped to 0-255.
  -- Use for day/night transitions or flash-on-hit effects.
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:brightness(0.5)   -- halve brightness (simulate dusk)
  local r = img:getPixel(0, 0)
  lurek.log.info("r after darken=" .. r, "image")
end

--@api-stub: LImageData:contrast
-- Applies a contrast factor to this image in place
do
  -- Factor > 1.0 increases contrast (darks darker, lights lighter).
  -- Factor < 1.0 flattens toward mid-gray. Use for dramatic cutscene effects.
  local img = lurek.image.newImageData(8, 8)
  img:fill(128, 128, 128, 255)
  img:contrast(2.0)   -- high contrast
  local r = img:getPixel(0, 0)
  lurek.log.info("r after contrast=" .. r, "image")
end

--@api-stub: LImageData:saturation
-- Applies a saturation factor to this image in place
do
  -- Factor 0.0 = full grayscale, 1.0 = unchanged, >1.0 = oversaturated.
  -- Use 0.0 for death screens or desaturation when paused.
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 100, 50, 255)
  img:saturation(0.0)   -- full desaturate (grayscale)
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:gamma
-- Applies gamma correction to this image in place
do
  -- Gamma 2.2 = sRGB curve (darkens midtones). Gamma 0.45 = inverse (brightens).
  -- Use when converting between linear and sRGB color spaces for correct blending.
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 100, 100, 255)
  img:gamma(2.2)   -- apply standard sRGB gamma curve
  local r = img:getPixel(0, 0)
  lurek.log.info("r after gamma=" .. r, "image")
end

--@api-stub: LImageData:tint
-- Blends this image toward a tint color in place
do
  -- tint(r, g, b, factor): blends each pixel toward the tint color by factor (0-1).
  -- Factor 0 = no change, 1 = fully tinted. Use for faction-colored units or mood lighting.
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:tint(255, 0, 0, 0.5)   -- 50% red tint (damage indicator)
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:grayscale
-- Converts this image to grayscale in place
do
  -- Converts to luminance-weighted grayscale (0.299R + 0.587G + 0.114B).
  -- Use for disabled UI elements, death screen, or generating heightmaps from color.
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 128, 64, 255)
  img:grayscale()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("gray r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:sepia
-- Applies a sepia filter to this image in place
do
  -- Sepia gives an old-photograph look. Applies after internal grayscale conversion.
  -- Use for flashback scenes, aged documents, or vintage UI.
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 180, 160, 255)
  img:sepia()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("sepia r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:invert
-- Inverts image color channels in place
do
  -- Each channel becomes 255 - original. Alpha is preserved.
  -- Use for negative effects, X-ray vision, or psychedelic transitions.
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 150, 200, 255)
  img:invert()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("inverted r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:threshold
-- Applies a threshold filter to this image in place
do
  -- Pixels with luminance > value become white, others become black.
  -- Use for generating collision masks, silhouettes, or high-contrast HUD elements.
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:threshold(128)   -- above 128 luminance -> white
  local r = img:getPixel(0, 0)
  lurek.log.info("thresholded r=" .. r, "image")
end

--@api-stub: LImageData:posterize
-- Reduces image colors to a fixed number of levels in place
do
  -- Quantizes each channel to N discrete levels. Creates a retro/cel-shaded look.
  -- levels=2 gives pure black/white per channel, levels=4 gives 4 shades.
  local img = lurek.image.newImageData(8, 8)
  img:fill(180, 120, 60, 255)
  img:posterize(3)   -- 3 levels per channel
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("posterised r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

--@api-stub: LImageData:noise
-- Adds noise to this image in place
do
  -- Adds random +/- amount to each RGB channel. Alpha is unchanged.
  -- Use for film grain, dithering, or breaking up flat-colored surfaces.
  local img = lurek.image.newImageData(16, 16)
  img:fill(128, 128, 128, 255)
  img:noise(20)   -- random variation of +/-20 per channel
  lurek.log.info("noise applied to 16x16 image", "image")
end

--@api-stub: LImageData:alphaMask
-- Multiplies this image alpha channel by a factor in place
do
  -- Multiplies every pixel's alpha by the given factor. RGB channels are unchanged.
  -- Use for fade-out effects, creating semi-transparent overlays, or soft masks.
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 255, 255, 255)
  img:alphaMask(0.5)   -- make 50% transparent
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("alpha after mask=" .. a, "image")
end

--@api-stub: LImageData:fill
-- Fills the whole image with one RGBA color
do
  -- Overwrites every pixel with the given RGBA color.
  -- Use to clear a canvas before drawing, or create solid color textures.
  local img = lurek.image.newImageData(16, 16)
  img:fill(64, 128, 192, 255)   -- solid blue-grey
  local r, g, b, a = img:getPixel(8, 8)
  lurek.log.info("fill r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end

-- =============================================================================
-- LImageData — geometric transforms
-- =============================================================================

--@api-stub: LImageData:flipHorizontal
-- Flips this image horizontally in place
do
  -- Mirrors left-to-right. Use for character facing direction or symmetry generation.
  local img = lurek.image.newImageData(4, 4)
  img:setPixel(0, 0, 255, 0, 0, 255)   -- red marker at top-left
  img:flipHorizontal()
  local r = img:getPixel(3, 0)   -- marker should now be at top-right
  lurek.log.info("flipped: r at (3,0)=" .. r, "image")
end

--@api-stub: LImageData:flipVertical
-- Flips this image vertically in place
do
  -- Mirrors top-to-bottom. Use for water reflections or UI mirroring.
  local img = lurek.image.newImageData(4, 4)
  img:setPixel(0, 0, 0, 255, 0, 255)   -- green marker at top-left
  img:flipVertical()
  local r, g = img:getPixel(0, 3)   -- marker should now be at bottom-left
  lurek.log.info("flipped: g at (0,3)=" .. g, "image")
end

--@api-stub: LImageData:rotate90cw
-- Returns a new image rotated ninety degrees clockwise
do
  -- Returns a NEW image (original is unchanged). Width and height swap.
  -- Use for tile rotation in map editors or portrait/landscape switching.
  local img = lurek.image.newImageData(4, 8)   -- 4 wide, 8 tall
  local rot = img:rotate90cw()               -- becomes 8 wide, 4 tall
  lurek.log.info("rotated w=" .. rot:getWidth() .. " h=" .. rot:getHeight(), "image")
end

--@api-stub: LImageData:crop
-- Returns a cropped image region
do
  -- Extracts a rectangular sub-image as a new LImageData.
  -- Use to cut individual sprites from a sprite sheet or trim whitespace.
  local sheet = lurek.image.newImageData(64, 64)
  sheet:fill(80, 160, 240, 255)
  local sprite = sheet:crop(0, 0, 16, 16) -- first 16x16 sprite in the sheet
  lurek.log.info("sprite w=" .. sprite:getWidth() .. " h=" .. sprite:getHeight(), "image")
end

--@api-stub: LImageData:resizeNearest
-- Returns a resized image using nearest-neighbor sampling
do
  -- Nearest-neighbor preserves hard pixel edges (no blurring).
  -- Ideal for pixel art upscaling where you want crisp blocky pixels.
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 50, 100, 255)
  local big = img:resizeNearest(64, 64)   -- 8x upscale, stays pixelated
  lurek.log.info("scaled w=" .. big:getWidth() .. " h=" .. big:getHeight(), "image")
end

--@api-stub: LImageData:resize
-- Creates a new ImageData resized to the given dimensions using bilinear sampling
do
  -- Bilinear filtering smooths pixels during resize. Optional filter parameter:
  -- "bilinear" (default), "nearest", "lanczos3" (sharpest quality).
  -- Use for generating thumbnails or atlas packing with smooth edges.
  local img = lurek.image.newImageData(64, 64)
  img:fill(100, 200, 50, 255)
  local small = img:resize(8, 8)
  lurek.log.info("resized w=" .. small:getWidth() .. " h=" .. small:getHeight(), "image")
end

--@api-stub: LImageData:blur
-- Returns a blurred copy of this image
do
  -- Returns a new blurred copy (original unchanged). Radius controls blur strength.
  -- Use for background bokeh, shadow generation, or smooth lighting maps.
  local img = lurek.image.newImageData(32, 32)
  img:fill(255, 255, 255, 255)
  img:setPixel(16, 16, 0, 0, 0, 255)   -- single dark pixel
  local blurred = img:blur(2) -- radius=2 pixels
  lurek.log.info("blurred w=" .. blurred:getWidth(), "image")
end

--@api-stub: LImageData:sharpen
-- Returns a sharpened copy of this image
do
  -- Returns a new sharpened copy using a standard unsharp mask kernel.
  -- Use to enhance text readability or make blurry loaded assets crisper.
  local img = lurek.image.newImageData(16, 16)
  img:fill(180, 180, 180, 255)
  local sharp = img:sharpen()
  lurek.log.info("sharpened w=" .. sharp:getWidth(), "image")
end

--@api-stub: LImageData:convolve
-- Applies a convolution kernel and returns the filtered image
do
  -- Applies a custom NxN convolution kernel. Kernel is a flat array, ksize is the side length.
  -- Use for edge detection, emboss, or custom blur kernels.
  local img = lurek.image.newImageData(16, 16)
  img:fill(180, 180, 180, 255)
  -- Standard sharpen kernel (3x3)
  local kernel = {0, -1, 0, -1, 5, -1, 0, -1, 0}
  local result = img:convolve(kernel, 3)
  lurek.log.info("convolved w=" .. result:getWidth(), "image")
end

-- =============================================================================
-- LImageData — drawing primitives
-- =============================================================================

--@api-stub: LImageData:drawRect
-- Draws a filled rectangle into this image
do
  -- Draws a solid filled rectangle: drawRect(x, y, w, h, r, g, b, a).
  -- Use for health bars, selection boxes, or procedural tile generation.
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawRect(4, 4, 24, 12, 255, 100, 0, 255)   -- orange health bar
  local r, g, b = img:getPixel(10, 8)
  lurek.log.info("bar pixel r=" .. r .. " g=" .. g, "image")
end

--@api-stub: LImageData:drawCircle
-- Draws a filled circle into this image
do
  -- Draws a solid filled circle: drawCircle(cx, cy, radius, r, g, b, a).
  -- Use for bullet holes, particle stamps, or procedural planet generation.
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawCircle(16, 16, 10, 255, 255, 0, 255)   -- yellow sun
  local r, g = img:getPixel(16, 16)
  lurek.log.info("center r=" .. r .. " g=" .. g, "image")
end

--@api-stub: LImageData:drawLine
-- Draws a line into this image
do
  -- Draws a 1-pixel line between two points: drawLine(x0, y0, x1, y1, r, g, b, a).
  -- Use for grid overlays, connecting nodes, or procedural cracks.
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawLine(0, 0, 31, 31, 255, 255, 255, 255)   -- white diagonal
  local r = img:getPixel(15, 15)
  lurek.log.info("line pixel r=" .. r, "image")
end

--@api-stub: LImageData:drawNineSlice
-- Draws a nine-slice region from a source image into this image
do
  -- Nine-slice stretches a bordered UI texture to any size without distorting corners.
  -- Parameters: src, src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h,
  --             inset_left, inset_right, inset_top, inset_bottom.
  -- Corners stay fixed, edges stretch in one axis, center fills.
  local atlas = lurek.image.newImageData(32, 32)
  atlas:fill(255, 255, 255, 255) -- white panel texture

  local out = lurek.image.newImageData(96, 64)
  out:fill(0, 0, 0, 0) -- transparent background
  -- Stretch the 32x32 source panel to 88x56 with 8px border insets
  out:drawNineSlice(atlas, 0, 0, 32, 32, 4, 4, 88, 56, 8, 8, 8, 8)
end

-- =============================================================================
-- LImageData — compositing
-- =============================================================================

--@api-stub: LImageData:blit
-- Copies pixel data from another ImageData onto this one at the specified position
do
  -- blit copies src onto dst at (dx, dy). Alpha is overwritten, not blended.
  -- Use for stamp-based painting, compositing sprite layers, or atlas building.
  local base = lurek.image.newImageData(32, 32)
  base:fill(0, 0, 128, 255) -- dark blue background
  local overlay = lurek.image.newImageData(8, 8)
  overlay:fill(255, 255, 0, 200) -- semi-transparent yellow patch
  base:blit(overlay, 12, 12)   -- paste at position (12, 12)
  local r, g, b = base:getPixel(14, 14)
  lurek.log.info("blit pixel g=" .. g, "image")
end

--@api-stub: LImageData:paste
-- Pastes a source image into this image at unsigned destination coordinates
do
  -- paste is similar to blit: copies src pixels into dst at (dx, dy).
  -- Use for icon placement, badge stamping, or building composite textures.
  local canvas = lurek.image.newImageData(32, 32)
  canvas:fill(30, 30, 60, 255)  -- dark slate background
  local icon = lurek.image.newImageData(8, 8)
  icon:fill(255, 200, 0, 255)   -- gold icon
  canvas:paste(icon, 4, 4)
  local r, g = canvas:getPixel(6, 6)
  lurek.log.info("icon pixel r=" .. r .. " g=" .. g, "image")
end

--@api-stub: LImageData:getRegion
-- Extracts a rectangular sub-region as a new ImageData
do
  -- getRegion returns a copy of pixels in the given rect, or nil if out of bounds.
  -- Use for extracting frames from a sprite sheet or sampling a sub-area for analysis.
  local img = lurek.image.newImageData(64, 64)
  img:drawRect(10, 10, 20, 20, 255, 0, 0, 255) -- red square
  local region = img:getRegion(10, 10, 20, 20)
  if region then
    lurek.log.info("region w=" .. region:getWidth() .. " h=" .. region:getHeight(), "image")
  end
end

--@api-stub: LImageData:diff
-- Computes a numeric difference score between this image and another of the same size
do
  -- Returns a scalar difference (sum of channel deltas). 0 = identical images.
  -- Use for visual regression testing or detecting changes between frames.
  local a = lurek.image.newImageData(8, 8)
  local b = lurek.image.newImageData(8, 8)
  a:fill(200, 200, 200, 255)
  b:fill(100, 100, 100, 255)
  local d = a:diff(b)
  lurek.log.info("pixel diff=" .. tostring(d), "image")
end

--@api-stub: LImageData:applyPaletteLut
-- Applies a palette lookup table to this image in place
do
  -- Remaps pixel colors using a pre-built LUT. Exact color match only.
  -- Much faster than mapPixel for bulk recoloring (e.g., team colors in RTS games).
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)   -- solid red
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)   -- remap red -> green
  img:applyPaletteLut(lut)
  local r, g = img:getPixel(0, 0)
  lurek.log.info("after lut r=" .. r .. " g=" .. g, "image")
end

-- =============================================================================
-- LImageData — type identity
-- =============================================================================

--@api-stub: LImageData:type
-- Returns the Lua-visible type name string for this image data handle
do
  -- type() returns the class name as a string. Use for runtime type checks.
  local dst = lurek.image.newImageData(64, 64)
  local src = lurek.image.newImageData(16, 16)
  src:fill(255, 128, 0, 255)
  dst:blit(src, 24, 24)
  lurek.log.info("type=" .. dst:type(), "image")
end

--@api-stub: ImageData:type
-- Returns the Lua-visible type name string for this image data handle.
do
  local img = lurek.image.newImageData(8, 8)
  assert(img:type() == "ImageData")
end

--@api-stub: ImageData:typeOf
-- Returns true if this image data handle matches the given type name string.
do
  -- typeOf checks if this handle matches a type name. Supports "ImageData" and "Object".
  local img = lurek.image.newImageData(8, 8)
  assert(img:typeOf("ImageData") == true)
end

-- =============================================================================
-- LCompressedImageData methods
-- =============================================================================

--@api-stub: LCompressedImageData:type
-- Returns the Lua-visible type name for this compressed image handle
do
  local ok, compressed_image_data_obj = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if ok and compressed_image_data_obj then
    local t = compressed_image_data_obj:type()
    lurek.log.info("LCompressedImageData:type = " .. t, "image")
  end
end

--@api-stub: LCompressedImageData:typeOf
-- Returns whether this compressed image handle matches a supported type name
do
  local ok, compressed_image_data_obj = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if ok and compressed_image_data_obj then
    lurek.log.info("is LCompressedImageData: " .. tostring(compressed_image_data_obj:typeOf("LCompressedImageData")), "image")
    lurek.log.info("is wrong: " .. tostring(compressed_image_data_obj:typeOf("Unknown")), "image")
  end
end

--@api-stub: CompressedImageData:getWidth
-- Returns the width of this compressed image data.
do
  -- Base mipmap width in pixels. DDS images can be 1024+ for terrain.
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local w = (cd and cd:getWidth() or 0)
  lurek.log.info("dds base width=" .. w, "image")
end

--@api-stub: CompressedImageData:getHeight
-- Returns the height of this compressed image data.
do
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local h = (cd and cd:getHeight() or 0)
  lurek.log.info("dds base height=" .. h, "image")
end

--@api-stub: CompressedImageData:getDimensions
-- Returns the dimensions of this compressed image data.
do
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local w = cd and cd:getWidth() or 0
  local h = cd and cd:getHeight() or 0
  lurek.log.info("dds " .. w .. "x" .. h, "image")
end

--@api-stub: CompressedImageData:getMipmapCount
-- Returns the number of mipmap items in this compressed image data.
do
  -- Mipmaps are pre-computed smaller versions for trilinear filtering.
  -- More mipmaps = smoother rendering at far distances.
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local mips = (cd and cd:getMipmapCount() or 0)
  if mips > 1 then
    lurek.log.info("trilinear ready, mips=" .. mips, "image")
  end
end

--@api-stub: CompressedImageData:getFormat
-- Returns the format of this compressed image data.
do
  -- Format string identifies the compression: "BC1", "BC3", "BC7", etc.
  -- BC1 = no alpha (smallest), BC3 = full alpha, BC7 = best quality.
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local fmt = (cd and cd:getFormat() or "unknown")
  lurek.log.info("dds format=" .. fmt, "image")
end

-- =============================================================================
-- LLayeredImage methods
-- =============================================================================

--@api-stub: LLayeredImage:getWidth
-- Returns the layered image width
do
  local li = lurek.image.newLayeredImage(128, 64)
  lurek.log.info("width=" .. li:getWidth(), "image")
end

--@api-stub: LLayeredImage:getHeight
-- Returns the layered image height
do
  local li = lurek.image.newLayeredImage(128, 64)
  lurek.log.info("height=" .. li:getHeight(), "image")
end

--@api-stub: LLayeredImage:layerCount
-- Returns the number of layers in the stack
do
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  lurek.log.info("layers=" .. li:layerCount(), "image")
end

--@api-stub: LLayeredImage:addLayer
-- Adds a blank layer with an optional name
do
  -- Returns the 1-based index of the new layer. Name is optional.
  -- Layers are drawn bottom-to-top: layer 1 is the background.
  local li = lurek.image.newLayeredImage(64, 64)
  local idx = li:addLayer("highlights")
  lurek.log.info("added layer idx=" .. idx .. " total=" .. li:layerCount(), "image")
end

--@api-stub: LLayeredImage:removeLayer
-- Removes a layer by one-based index
do
  -- Returns true if the layer existed and was removed.
  -- Remaining layers shift down to fill the gap.
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  local ok = li:removeLayer(1)
  lurek.log.info("removed=" .. tostring(ok) .. " remaining=" .. li:layerCount(), "image")
end

--@api-stub: LLayeredImage:getLayer
-- Returns image data for a layer by one-based index
do
  -- Returns an LImageData snapshot of that layer's pixel content.
  -- You can then draw on it and set it back with setLayer.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  local layer = li:getLayer(idx)
  lurek.log.info("layer w=" .. layer:getWidth(), "image")
end

--@api-stub: LLayeredImage:setLayer
-- Replaces a layer's image data by one-based index
do
  -- Replaces the pixel content of an existing layer with a new LImageData.
  -- The new image must match the layered image dimensions.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  local src = lurek.image.newImageData(32, 32)
  src:fill(100, 200, 50, 255) -- paint layer green
  li:setLayer(idx, src)
  local out = li:getLayer(idx)
  local r, g = out:getPixel(0, 0)
  lurek.log.info("layer g=" .. g, "image")
end

--@api-stub: LLayeredImage:getOpacity
-- Returns a layer opacity by one-based index
do
  -- Opacity is 0.0 (invisible) to 1.0 (fully opaque). Default is 1.0.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setOpacity(idx, 0.75)
  lurek.log.info("opacity=" .. li:getOpacity(idx), "image")
end

--@api-stub: LLayeredImage:setOpacity
-- Sets a layer opacity by one-based index
do
  -- Use opacity for fade effects, ghost layers, or blending strength control.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setOpacity(idx, 0.5) -- 50% transparent
  lurek.log.info("opacity=" .. li:getOpacity(idx), "image")
end

--@api-stub: LLayeredImage:isVisible
-- Returns layer visibility by one-based index
do
  -- Invisible layers are skipped during merge. Use to toggle overlay layers.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  lurek.log.info("visible by default: " .. tostring(li:isVisible(idx)), "image")
  li:setVisible(idx, false)
  lurek.log.info("after hide: " .. tostring(li:isVisible(idx)), "image")
end

--@api-stub: LLayeredImage:setVisible
-- Sets layer visibility by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setVisible(idx, false)   -- hide for now
  lurek.log.info("hidden: " .. tostring(not li:isVisible(idx)), "image")
  li:setVisible(idx, true)    -- show again
  lurek.log.info("visible again: " .. tostring(li:isVisible(idx)), "image")
end

--@api-stub: LLayeredImage:getName
-- Returns a layer name by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setName(idx, "body")
  lurek.log.info("name=" .. li:getName(idx), "image")
end

--@api-stub: LLayeredImage:setName
-- Sets a layer name by one-based index
do
  -- Names are for human identification. Use meaningful names for save/load UX.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setName(idx, "helmet")
  lurek.log.info("name=" .. li:getName(idx), "image")
end

--@api-stub: LLayeredImage:swapLayers
-- Swaps two layers by one-based indices
do
  -- Instantly swaps two layers' positions in the stack (including content and metadata).
  local li = lurek.image.newLayeredImage(32, 32)
  li:addLayer(); li:addLayer()
  li:setName(1, "layer_a"); li:setName(2, "layer_b")
  li:swapLayers(1, 2)
  lurek.log.info("after swap: idx1=" .. li:getName(1), "image")
end

--@api-stub: LLayeredImage:moveLayer
-- Moves a layer from one one-based index to another
do
  -- moveLayer(from, to) reorders without swapping. Other layers shift.
  -- Use for "bring to front" or "send to back" in a layer panel.
  local li = lurek.image.newLayeredImage(32, 32)
  for i = 1, 3 do li:addLayer(); li:setName(i, "layer_" .. i) end
  li:moveLayer(3, 1)   -- bring layer 3 to the front (index 1)
  lurek.log.info("front layer=" .. li:getName(1), "image")
end

--@api-stub: LLayeredImage:merge
-- Merges visible layers into a single image data object
do
  -- Flattens all visible layers respecting opacity into one LImageData.
  -- Use when exporting final art or creating a texture for the GPU.
  local li = lurek.image.newLayeredImage(32, 32)
  local bg_idx = li:addLayer()
  local fg_idx = li:addLayer()
  local bg = lurek.image.newImageData(32, 32); bg:fill(50, 50, 200, 255)
  local fg = lurek.image.newImageData(32, 32); fg:fill(255, 200, 0, 128)
  li:setLayer(bg_idx, bg); li:setLayer(fg_idx, fg)
  local flat = li:merge()
  lurek.log.info("merged w=" .. flat:getWidth(), "image")
end

--@api-stub: LLayeredImage:save
-- Saves the layered image stack to a file
do
  -- Serializes the full layer stack (pixels, names, opacity, visibility) to .limg.
  -- Reload later with lurek.image.loadLayered.
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  local layer_data = lurek.image.newImageData(32, 32)
  layer_data:fill(200, 150, 100, 255)
  li:setLayer(idx, layer_data)
  li:save("save/test_layered.limg")
  lurek.log.info("saved layered image to save/test_layered.limg", "image")
end

--@api-stub: LLayeredImage:type
-- Returns the Lua-visible type name for this layered image handle
do
  local layered_image_obj = lurek.image.newLayeredImage(32, 32)
  local t = layered_image_obj:type()
  lurek.log.info("LLayeredImage:type = " .. t, "image")
end

--@api-stub: LLayeredImage:typeOf
-- Returns whether this layered image handle matches a supported type name
do
  local layered_image_obj = lurek.image.newLayeredImage(32, 32)
  lurek.log.info("is LLayeredImage: " .. tostring(layered_image_obj:typeOf("LLayeredImage")), "image")
  lurek.log.info("is wrong: " .. tostring(layered_image_obj:typeOf("Unknown")), "image")
end

-- =============================================================================
-- LPaletteLUT methods
-- =============================================================================

--@api-stub: LPaletteLUT:type
-- Returns the Lua-visible type name for this palette lookup table handle
do
  local palette_l_u_t_obj = lurek.image.newPaletteLut()
  local t = palette_l_u_t_obj:type()
  lurek.log.info("LPaletteLUT:type = " .. t, "image")
end

--@api-stub: LPaletteLUT:typeOf
-- Returns whether this palette lookup table handle matches a supported type name
do
  local palette_l_u_t_obj = lurek.image.newPaletteLut()
  lurek.log.info("is LPaletteLUT: " .. tostring(palette_l_u_t_obj:typeOf("LPaletteLUT")), "image")
  lurek.log.info("is wrong: " .. tostring(palette_l_u_t_obj:typeOf("Unknown")), "image")
end

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of color items in this palette lut.
do
  -- getColorCount returns how many source->dest color mappings are registered.
  local lut = lurek.image.newPaletteLut()
  local n = lut:getColorCount()
  if n == 0 then
    lurek.log.info("lut is empty, no remaps configured", "image")
  end
end

--@api-stub: PaletteLUT:setColor
-- Sets the color of this palette lut.
do
  -- setColor(fr, fg, fb, fa, tr, tg, tb, ta): maps source RGBA to dest RGBA.
  -- When applyPaletteLut finds a pixel matching the source color, it replaces with dest.
  -- Use for team recoloring: map template red -> faction blue.
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 255, 0, 255) -- red pixels become green
  lurek.log.info("lut entries: " .. lut:getColorCount(), "image")
end

--@api-stub: PaletteLUT:clear
-- Clears all items from this palette lut.
do
  -- Removes all color mappings. Use before rebuilding a LUT for a new faction.
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 0, 255, 255)
  lut:clear()
  lurek.log.info("lut reset, count=" .. lut:getColorCount(), "image")
end

--@api-stub: PaletteLUT:cycle
-- Performs the cycle operation on this palette lut.
do
  -- Rotates all destination colors by an offset. Creates animated palette cycling.
  -- Classic technique for water shimmer, lava flow, or rainbow effects.
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)   -- red -> green
  lut:setColor(0, 255, 0, 255, 0, 0, 255, 255)   -- green -> blue
  lut:cycle(1) -- shift all mappings by 1 position
end

-- =============================================================================
-- LProvinceGrid methods
-- =============================================================================

--@api-stub: LProvinceGrid:type
-- Returns the Lua-visible type name for this province grid handle
do
  local ok, province_grid_obj = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if ok and province_grid_obj then
    local t = province_grid_obj:type()
    lurek.log.info("LProvinceGrid:type = " .. t, "image")
  end
end

--@api-stub: LProvinceGrid:typeOf
-- Returns whether this province grid handle matches a supported type name
do
  local ok, province_grid_obj = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if ok and province_grid_obj then
    lurek.log.info("is LProvinceGrid: " .. tostring(province_grid_obj:typeOf("LProvinceGrid")), "image")
    lurek.log.info("is wrong: " .. tostring(province_grid_obj:typeOf("Unknown")), "image")
  end
end

--@api-stub: ProvinceGrid:getWidth
-- Returns the width of this province grid.
do
  -- Grid width matches the source province map image pixel width.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local w = (grid and grid:getWidth() or 0)
  if w > 0 then
    lurek.log.info("province map width=" .. w, "map")
  end
end

--@api-stub: ProvinceGrid:getHeight
-- Returns the height of this province grid.
do
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local h = (grid and grid:getHeight() or 0)
  lurek.log.info("province map height=" .. h, "map")
end

--@api-stub: ProvinceGrid:getAt
-- Returns the province id at given pixel coordinates in this province grid.
do
  -- getAt(x, y) returns the province id at that pixel. Use for mouse-click territory selection.
  -- Returns 0 for ocean/empty pixels depending on your map encoding.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local id = (grid and grid:getAt(128, 96) or 0)
  if id ~= 0 then
    lurek.log.info("clicked province " .. id, "map")
  end
end

--@api-stub: ProvinceGrid:provinceCount
-- Returns the number of distinct provinces in this province grid.
do
  -- Use provinceCount to allocate game-state arrays (owners, populations, armies).
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  local owners = {}
  for i = 1, count do owners[i] = 0 end
  lurek.log.info("allocated owner table for " .. count .. " provinces", "map")
end

--@api-stub: ProvinceGrid:adjacencies
-- Returns province adjacency records and shared border pixel counts.
do
  -- Returns an array of {province_a, province_b, border_pixels} records.
  -- Use to build a graph for pathfinding or determining which provinces border each other.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local edges = (grid and grid:adjacencies() or {})
  lurek.log.info("adjacency edges=" .. #edges, "map")
end

--@api-stub: ProvinceGrid:getPolygons
-- Returns polygon rings for every province in this province grid.
do
  -- Returns a table keyed by province_id with polygon ring arrays.
  -- Use for rendering province outlines or computing centroids.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local polys = (grid and grid:getPolygons() or {})
  local province_count = 0
  for _k, _v in pairs(polys) do
    province_count = province_count + 1
  end
  lurek.log.info("province polygon sets=" .. province_count, "map")
end

--@api-stub: ProvinceGrid:getPolygonsSimplified
-- Returns simplified polygon rings for every province in this province grid.
do
  -- Simplified polygons have fewer vertices (Douglas-Peucker reduction).
  -- Use for faster rendering or hit-testing when pixel precision is not needed.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local polys = (grid and grid:getPolygonsSimplified() or {})
  local province_count = 0
  for _k, _v in pairs(polys) do
    province_count = province_count + 1
  end
  lurek.log.info("simplified province polygon sets=" .. province_count, "map")
end

--@api-stub: LProvinceGrid:drawShapes
-- Queues filled polygon draw commands for province shapes, optionally culled to a viewport rect
do
  -- drawShapes emits render commands for all province polygons.
  -- Optional viewport rect (x, y, w, h) culls off-screen provinces for performance.
  -- Returns the number of polygons actually queued for rendering.
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  pcall(function()
    grid:drawShapes(0, 0, 1.0)
  end)
end

--@api-stub: ProvinceGrid
-- Province grid advanced operations: spans, border segments, and shape serialization.
do
  -- provinceSpans: horizontal pixel runs per province (for flood-fill rendering).
  -- borderSegments: line segments between neighboring provinces (for border drawing).
  -- serializeShapeData/deserializeShapeData: cache shape data as binary for fast reload.
  local pg = lurek.image.newProvinceGrid("content/games/strategy/eu2/map.png")
  local spans = pg:provinceSpans()
  local segments = pg:borderSegments()
  local blob = pg:serializeShapeData()
  local decoded = pg:deserializeShapeData(blob)
  lurek.log.info("spans=" .. #spans .. " segs=" .. #segments, "image")
  if decoded then
    lurek.log.info("decoded spans=" .. #decoded.spans .. " decoded segs=" .. #decoded.segments, "image")
  end
end

-- =============================================================================
-- Legacy stubs (old naming convention — preserved for backward compatibility)
-- =============================================================================

--@api-stub: mlua:getWidth
-- Returns the width of this image data.
do
  local img = lurek.image.newImageData(64, 64)
  local w = img:getWidth()
  lurek.log.info("hero width=" .. w, "image")
end

--@api-stub: mlua:getHeight
-- Returns the height of this image data.
do
  local img = lurek.image.newImageData(64, 64)
  local h = img:getHeight()
  lurek.log.info("hero height=" .. h, "image")
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions of this image data.
do
  local img = lurek.image.newImageData(64, 64)
  local w, h = img:getDimensions()
  lurek.log.info("hero " .. w .. "x" .. h, "image")
end

--@api-stub: mlua:getPixel
-- Returns the pixel color at a coordinate.
do
  local img = lurek.image.newImageData(64, 64)
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("top-left rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "image")
end

--@api-stub: mlua:setPixel
-- Sets the pixel color at a coordinate.
do
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(8, 8, 255, 0, 128, 255)
  local r, g, b, a = img:getPixel(8, 8)
  lurek.log.info("pixel r=" .. r, "image")
end

--@api-stub: mlua:encode
-- Encodes the image data in the specified format.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 200, 100, 255)
  local png_bytes = img:encode("png")
  lurek.log.info("png byte length=" .. #png_bytes, "image")
end

--@api-stub: mlua:mapPixel
-- Applies a callback to each pixel and replaces it with the returned RGBA.
do
  -- mapPixel is ideal for procedural textures: generate checkerboards, gradients, etc.
  local img = lurek.image.newImageData(32, 32)
  img:fill(64, 64, 64, 255)
  img:mapPixel(function(_, _, r, g, b, a)
    return 255 - r, 255 - g, 255 - b, a -- invert via callback
  end)
end

--@api-stub: mlua:mapPixels
-- Applies a callback to each pixel (alias for mapPixel).
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(100, 100, 100, 255)
  img:mapPixels(function(_, _, r, g, b, a) return r + 50, g, b, a end)
end

--@api-stub: mlua:brightness
-- Adjusts brightness of this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:brightness(1.2)
  lurek.image.savePNG(img, "save/hero_brighter.png")
end

--@api-stub: mlua:contrast
-- Adjusts contrast of this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:contrast(1.4)
  lurek.image.savePNG(img, "save/hero_contrast.png")
end

--@api-stub: mlua:saturation
-- Adjusts saturation of this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:saturation(0.0) -- full desaturation
  lurek.image.savePNG(img, "save/hero_desaturated.png")
end

--@api-stub: mlua:gamma
-- Applies gamma correction to this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:gamma(2.2)
  lurek.image.savePNG(img, "save/hero_gamma.png")
end

--@api-stub: mlua:tint
-- Blends this image toward a tint color in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:tint(255, 200, 150, 0.3) -- warm sunset tint
  lurek.log.info("tint applied", "image")
end

--@api-stub: mlua:grayscale
-- Converts this image data to grayscale in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:grayscale()
  lurek.image.savePNG(img, "save/hero_gray.png")
end

--@api-stub: mlua:sepia
-- Applies sepia tone to this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:sepia()
  lurek.image.savePNG(img, "save/hero_sepia.png")
end

--@api-stub: mlua:invert
-- Inverts color channels of this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:invert()
  lurek.image.savePNG(img, "save/hero_inverted.png")
end

--@api-stub: mlua:threshold
-- Applies binary threshold to this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:threshold(128) -- creates a black/white mask
  lurek.image.savePNG(img, "save/hero_mask.png")
end

--@api-stub: mlua:posterize
-- Quantizes channels to N levels in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:posterize(4) -- 4 levels per channel for retro look
  lurek.image.savePNG(img, "save/hero_posterized.png")
end

--@api-stub: mlua:fill
-- Fills the entire image with a solid RGBA color.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(20, 30, 40, 255)
  lurek.image.savePNG(img, "save/solid.png")
end

--@api-stub: mlua:noise
-- Adds random noise to this image data in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(128, 128, 128, 255)
  img:noise(32) -- +/-32 per channel for grainy film effect
  lurek.image.savePNG(img, "save/noise.png")
end

--@api-stub: mlua:alphaMask
-- Multiplies the alpha channel by a factor in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:alphaMask(0.5) -- make 50% transparent for ghost effect
  lurek.image.savePNG(img, "save/hero_halfalpha.png")
end

--@api-stub: mlua:flipHorizontal
-- Flips this image data horizontally in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:flipHorizontal() -- mirror for character facing left
  lurek.image.savePNG(img, "save/hero_flipped.png")
end

--@api-stub: mlua:flipVertical
-- Flips this image data vertically in place.
do
  local img = lurek.image.newImageData(64, 64)
  img:flipVertical() -- mirror for water reflection
  lurek.image.savePNG(img, "save/hero_vflipped.png")
end

--@api-stub: mlua:rotate90cw
-- Returns a new image rotated 90 degrees clockwise.
do
  local img = lurek.image.newImageData(64, 64)
  local rotated = img:rotate90cw()
  lurek.image.savePNG(rotated, "save/hero_cw.png")
end

--@api-stub: mlua:crop
-- Returns a cropped sub-region as a new image data.
do
  -- Extract a 32x32 face region from a 64x64 sprite
  local img = lurek.image.newImageData(64, 64)
  local face = img:crop(8, 4, 32, 32)
  lurek.image.savePNG(face, "save/hero_face.png")
end

--@api-stub: mlua:resizeNearest
-- Returns a nearest-neighbor resized copy.
do
  local img = lurek.image.newImageData(64, 64)
  local big = img:resizeNearest(128, 128) -- 2x upscale, pixel-perfect
  lurek.image.savePNG(big, "save/hero_2x.png")
end

--@api-stub: mlua:resize
-- Returns a bilinear-filtered resized copy.
do
  local img = lurek.image.newImageData(64, 64)
  local thumb = img:resize(32, 32) -- smooth downscale for thumbnail
  if thumb then
    lurek.image.savePNG(thumb, "save/hero_thumb.png")
  end
end

--@api-stub: mlua:blur
-- Returns a blurred copy of this image data.
do
  local img = lurek.image.newImageData(64, 64)
  local soft = img:blur(2) -- gaussian blur radius 2
  lurek.image.savePNG(soft, "save/hero_blurred.png")
end

--@api-stub: mlua:sharpen
-- Returns a sharpened copy of this image data.
do
  local img = lurek.image.newImageData(64, 64)
  local crisp = img:sharpen()
  lurek.image.savePNG(crisp, "save/hero_sharp.png")
end

--@api-stub: mlua:diff
-- Computes a pixel difference score against another image.
do
  pcall(function()
    local a = lurek.image.newImageData(64, 64)
    local b = lurek.image.newImageData("save/hero_baseline.png")
    local delta = a:diff(b)
    lurek.log.info("image diff=" .. delta, "test")
  end)
end

--@api-stub: mlua:applyPaletteLut
-- Applies a palette lookup table to remap colors in place.
do
  local img = lurek.image.newImageData(64, 64)
  local lut = lurek.image.newPaletteLut()
  img:applyPaletteLut(lut) -- no mappings set, so no change
  lurek.image.savePNG(img, "save/hero_recoloured.png")
end

--@api-stub: mlua:setRawData
-- Replaces all pixel bytes from a raw RGBA string.
do
  local img = lurek.image.newImageData(2, 2)
  -- 4 pixels, each RGBA (255,0,0,255) = solid red
  local bytes = string.rep(string.char(255, 0, 0, 255), 4)
  img:setRawData(bytes)
  lurek.image.savePNG(img, "save/red2x2.png")
end

--@api-stub: mlua:blit
-- Copies source pixels onto this image at the given position.
do
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:blit(src, 16, 16) -- paste src at center
  lurek.log.info("blit done", "image")
end

--@api-stub: mlua:paste
-- Pastes source pixels onto this image at the given position.
do
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:paste(src, 16, 16)
  lurek.log.info("paste done", "image")
end

--@api-stub: mlua:convolve
-- Applies a convolution kernel and returns the filtered result.
do
  -- Gaussian blur kernel (3x3, unnormalized — engine normalizes internally)
  local img = lurek.image.newImageData(64, 64)
  local blurred = img:convolve({1,2,1, 2,4,2, 1,2,1}, 3)
  lurek.log.info("convolved: " .. blurred:getWidth(), "image")
end

--@api-stub: mlua:drawCircle
-- Draws a filled circle into this image data.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawCircle(64, 64, 30, 255, 0, 0, 255) -- red circle, center of image
  lurek.log.info("circle drawn on ImageData", "image")
end

--@api-stub: mlua:drawLine
-- Draws a line into this image data.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawLine(0, 0, 127, 127, 0, 255, 0, 255) -- green diagonal
  lurek.log.info("line drawn on ImageData", "image")
end

--@api-stub: mlua:drawRect
-- Draws a filled rectangle into this image data.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawRect(10, 10, 60, 40, 0, 0, 255, 255) -- blue rectangle
  lurek.log.info("rect drawn on ImageData", "image")
end

--@api-stub: mlua:getRegion
-- Returns a rectangular sub-region as a new image data, or nil if out of bounds.
do
  local img = lurek.image.newImageData(128, 128)
  local region = img:getRegion(0, 0, 32, 32)
  if region then
    lurek.log.info("region: " .. region:getWidth() .. "x" .. region:getHeight(), "image")
  end
end

-- =============================================================================
-- Legacy LayeredImage stubs (old naming)
-- =============================================================================

--@api-stub: LayeredImage:getWidth
-- Returns the width of this layered image.
do
  local doc = lurek.image.newLayeredImage(256, 128)
  local w = doc:getWidth()
  lurek.log.info("canvas width=" .. w, "paint")
end

--@api-stub: LayeredImage:getHeight
-- Returns the height of this layered image.
do
  local doc = lurek.image.newLayeredImage(256, 128)
  local h = doc:getHeight()
  lurek.log.info("canvas height=" .. h, "paint")
end

--@api-stub: LayeredImage:layerCount
-- Returns the number of layers in this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  doc:addLayer("ink")
  lurek.log.info("layer count=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:addLayer
-- Adds a named layer to this layered image.
do
  local doc = lurek.image.newLayeredImage(128, 128)
  local idx = doc:addLayer("highlights")
  doc:setOpacity(idx, 0.75) -- semi-transparent highlights layer
  lurek.log.info("added layer at index " .. idx, "paint")
end

--@api-stub: LayeredImage:removeLayer
-- Removes a layer by index from this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("scratch")
  doc:removeLayer(1)
  lurek.log.info("layers after remove=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:getLayer
-- Returns image data for a layer by index.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local snap = doc:getLayer(1) -- get pixel data for layer 1
  lurek.image.savePNG(snap, "save/layer1.png")
end

--@api-stub: LayeredImage:setLayer
-- Replaces a layer's image data by index.
do
  local li = lurek.image.newLayeredImage(32, 32)
  li:addLayer()
  local newData = lurek.image.newImageData(32, 32)
  newData:fill(128, 128, 255, 255) -- light blue fill
  li:setLayer(1, newData)
  lurek.log.info("layer set", "image")
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of a layer.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  local a = doc:getOpacity(1) -- default is 1.0
  lurek.log.info("layer 1 opacity=" .. a, "paint")
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of a layer.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("shadow")
  doc:setOpacity(idx, 0.5) -- half-transparent shadow layer
end

--@api-stub: LayeredImage:isVisible
-- Returns whether a layer is currently visible.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  if doc:isVisible(1) then
    lurek.log.info("layer 1 is visible", "paint")
  end
end

--@api-stub: LayeredImage:setVisible
-- Sets the visibility flag for a layer.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("guides")
  doc:setVisible(idx, false) -- hide guide layer
end

--@api-stub: LayeredImage:getName
-- Returns the name of a layer.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("background")
  local name = doc:getName(1)
  lurek.log.info("layer 1 name='" .. name .. "'", "paint")
end

--@api-stub: LayeredImage:setName
-- Sets the name of a layer.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("untitled")
  doc:setName(idx, "background")
end

--@api-stub: LayeredImage:swapLayers
-- Swaps two layers by index.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("a")
  doc:addLayer("b")
  doc:swapLayers(1, 2) -- reorder without changing content
end

--@api-stub: LayeredImage:moveLayer
-- Moves a layer from one index to another.
do
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  li:moveLayer(1, 2) -- move layer 1 to position 2
  lurek.log.info("layer moved", "image")
end

--@api-stub: LayeredImage:merge
-- Flattens visible layers into one image data.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local flat = doc:merge() -- single LImageData with all visible layers composited
  lurek.image.savePNG(flat, "save/flattened.png")
end

--@api-stub: LayeredImage:save
-- Saves the layered image to a file.
do
  local doc = lurek.image.newLayeredImage(128, 128)
  doc:addLayer("background")
  doc:save("save/painting.limg") -- preserves layers, names, opacity
end

-- =============================================================================
-- Advanced: raw bytes and resize with explicit filter
-- =============================================================================

--@api-stub: raw
-- Demonstrates raw byte creation, getRawBytes, and resize with explicit lanczos3 filter.
do
  -- Build a tiny 2x2 image from raw bytes, read back, then upscale with lanczos3.
  -- lanczos3 is the highest quality filter — ideal for final asset export.
  local bytes = string.rep(string.char(255, 0, 0, 255), 4) -- 2x2 solid red
  local img = lurek.image.newImageDataFromBytes(2, 2, bytes)
  local raw = img:getRawBytes()
  local out = img:resize(4, 4, "lanczos3")
  if out then
    lurek.log.info("raw=" .. #raw .. " out=" .. out:getWidth() .. "x" .. out:getHeight(), "image")
  end
end

print("content/examples/image.lua")

-- =============================================================================
-- STUBS: 21 uncovered lurek.image API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LCompressedImageData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCompressedImageData:getWidth ---------------------------------
--@api-stub: LCompressedImageData:getWidth
-- Returns compressed image width. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCompressedImageData_stub:getWidth()  -- -> integer
-- (replace lCompressedImageData_stub with your real LCompressedImageData instance above)

-- ---- Stub: LCompressedImageData:getHeight --------------------------------
--@api-stub: LCompressedImageData:getHeight
-- Returns compressed image height. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCompressedImageData_stub:getHeight()  -- -> integer
-- (replace lCompressedImageData_stub with your real LCompressedImageData instance above)

-- ---- Stub: LCompressedImageData:getDimensions ----------------------------
--@api-stub: LCompressedImageData:getDimensions
-- Returns compressed image dimensions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCompressedImageData_stub:getDimensions()  -- -> integer
-- (replace lCompressedImageData_stub with your real LCompressedImageData instance above)

-- ---- Stub: LCompressedImageData:getMipmapCount ---------------------------
--@api-stub: LCompressedImageData:getMipmapCount
-- Returns the number of mipmap levels in this compressed image.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCompressedImageData_stub:getMipmapCount()  -- -> integer
-- (replace lCompressedImageData_stub with your real LCompressedImageData instance above)

-- ---- Stub: LCompressedImageData:getFormat --------------------------------
--@api-stub: LCompressedImageData:getFormat
-- Returns the compressed image format name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCompressedImageData_stub:getFormat()  -- -> string
-- (replace lCompressedImageData_stub with your real LCompressedImageData instance above)

-- -----------------------------------------------------------------------------
-- LImageData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LImageData:typeOf ---------------------------------------------
--@api-stub: LImageData:typeOf
-- Returns whether this image data handle matches the `LImageData` type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lImageData_stub:typeOf("hero")  -- -> boolean
-- (replace lImageData_stub with your real LImageData instance above)

-- -----------------------------------------------------------------------------
-- LPaletteLUT methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPaletteLUT:setColor ------------------------------------------
--@api-stub: LPaletteLUT:setColor
-- Adds a color mapping from source RGBA channels to destination RGBA channels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPaletteLUT_stub:setColor(fr, fg, fb, fa, tr, tg, tb, ta)
-- (replace lPaletteLUT_stub with your real LPaletteLUT instance above)

-- ---- Stub: LPaletteLUT:getColorCount -------------------------------------
--@api-stub: LPaletteLUT:getColorCount
-- Returns the number of color mappings in this palette lookup table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPaletteLUT_stub:getColorCount()  -- -> integer
-- (replace lPaletteLUT_stub with your real LPaletteLUT instance above)

-- ---- Stub: LPaletteLUT:clear ---------------------------------------------
--@api-stub: LPaletteLUT:clear
-- Removes every color mapping from this palette lookup table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPaletteLUT_stub:clear()
-- (replace lPaletteLUT_stub with your real LPaletteLUT instance above)

-- ---- Stub: LPaletteLUT:cycle ---------------------------------------------
--@api-stub: LPaletteLUT:cycle
-- Cycles palette mappings by an offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lPaletteLUT_stub:cycle(offset)
-- (replace lPaletteLUT_stub with your real LPaletteLUT instance above)

-- -----------------------------------------------------------------------------
-- LProvinceGrid methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LProvinceGrid:getWidth ----------------------------------------
--@api-stub: LProvinceGrid:getWidth
-- Returns the province grid width. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:getWidth()  -- -> integer
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:getHeight ---------------------------------------
--@api-stub: LProvinceGrid:getHeight
-- Returns the province grid height. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:getHeight()  -- -> integer
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:getAt -------------------------------------------
--@api-stub: LProvinceGrid:getAt
-- Returns the province id stored at grid coordinates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:getAt(0.0, 0.0)  -- -> integer
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:provinceCount -----------------------------------
--@api-stub: LProvinceGrid:provinceCount
-- Returns the number of distinct provinces in the grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:provinceCount()  -- -> integer
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:adjacencies -------------------------------------
--@api-stub: LProvinceGrid:adjacencies
-- Returns province adjacency records and shared border pixel counts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:adjacencies()  -- -> table
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:provinceSpans -----------------------------------
--@api-stub: LProvinceGrid:provinceSpans
-- Returns horizontal province spans by row.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:provinceSpans()  -- -> table
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:borderSegments ----------------------------------
--@api-stub: LProvinceGrid:borderSegments
-- Returns border line segments between neighboring provinces.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:borderSegments()  -- -> table
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:getPolygons -------------------------------------
--@api-stub: LProvinceGrid:getPolygons
-- Returns polygon rings for every province.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:getPolygons()  -- -> table
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:getPolygonsSimplified ---------------------------
--@api-stub: LProvinceGrid:getPolygonsSimplified
-- Returns simplified polygon rings for every province.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:getPolygonsSimplified()  -- -> table
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:serializeShapeData ------------------------------
--@api-stub: LProvinceGrid:serializeShapeData
-- Serializes province span and border shape data into a binary Lua string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:serializeShapeData()  -- -> string
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)

-- ---- Stub: LProvinceGrid:deserializeShapeData ----------------------------
--@api-stub: LProvinceGrid:deserializeShapeData
-- Decodes serialized province shape data into span and segment tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lProvinceGrid_stub:deserializeShapeData(bytes)  -- -> LuaValue
-- (replace lProvinceGrid_stub with your real LProvinceGrid instance above)
