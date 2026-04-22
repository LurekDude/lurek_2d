-- content/examples/image.lua
-- Practical usage examples for the lurek.image API (68 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.image.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/image.lua

print("[example] lurek.image — 68 API entries")

-- ── lurek.image.* free functions ──

--@api-stub: lurek.image.newImageData
-- Creates a new blank ImageData or loads one from a file.
-- Call when you need to create a new image data.
local ok, obj = pcall(function() return lurek.image.newImageData({}) end)
if ok and obj then print("created:", obj) end
print("lurek.image.newImageData ok=", ok)

--@api-stub: lurek.image.newCompressedData
-- Loads compressed texture data from a DDS file.
-- Call when you need to create a new compressed data.
local ok, obj = pcall(function() return lurek.image.newCompressedData("sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.newCompressedData ok=", ok)

--@api-stub: lurek.image.isCompressed
-- Returns true if the file at the given path is a DDS file.
-- Call when you need to check is compressed.
local ok, result = pcall(function() return lurek.image.isCompressed("sprites/player.png") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.image.isCompressed ok=", ok)

--@api-stub: lurek.image.newLayeredImage
-- Creates a new empty LayeredImage canvas with no layers.
-- Call when you need to create a new layered image.
local ok, obj = pcall(function() return lurek.image.newLayeredImage(100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.image.newLayeredImage ok=", ok)

--@api-stub: lurek.image.saveImage
-- Saves a flat ImageData to a LIMG binary file at the given path.
-- Call when you need to invoke save image.
local ok, obj = pcall(function() return lurek.image.saveImage(nil, "sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.saveImage ok=", ok)

--@api-stub: lurek.image.savePNG
-- Saves a flat ImageData as a PNG file at the given path.
-- Call when you need to invoke save p n g.
local ok, obj = pcall(function() return lurek.image.savePNG(nil, "sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.savePNG ok=", ok)

--@api-stub: lurek.image.loadImage
-- Loads an ImageData from a LIMG binary file.
-- Call when you need to load image.
local ok, obj = pcall(function() return lurek.image.loadImage("sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.loadImage ok=", ok)

--@api-stub: lurek.image.loadLayered
-- Loads a LayeredImage from a LIMG binary file.
-- Call when you need to load layered.
local ok, obj = pcall(function() return lurek.image.loadLayered("sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.loadLayered ok=", ok)

--@api-stub: lurek.image.newPaletteLut
-- Creates a new empty `PaletteLUT` used to remap colours in an image.
-- Call when you need to create a new palette lut.
local ok, obj = pcall(function() return lurek.image.newPaletteLut() end)
if ok and obj then print("created:", obj) end
print("lurek.image.newPaletteLut ok=", ok)

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
-- Call when you need to create a new province grid.
local ok, obj = pcall(function() return lurek.image.newProvinceGrid("sprites/player.png") end)
if ok and obj then print("created:", obj) end
print("lurek.image.newProvinceGrid ok=", ok)

-- ── ProvinceGrid methods ──

--@api-stub: ProvinceGrid:getWidth
-- Returns the grid width in pixels.
-- Call when you need to read width.
-- Build a ProvinceGrid via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newProvinceGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("ProvinceGrid:getWidth ->", ok, result)
end

--@api-stub: ProvinceGrid:getHeight
-- Returns the grid height in pixels.
-- Call when you need to read height.
-- Build a ProvinceGrid via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newProvinceGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("ProvinceGrid:getHeight ->", ok, result)
end

--@api-stub: ProvinceGrid:getAt
-- Returns the province ID at pixel coordinates (x, y).
-- Returns 0 for background or out-of-bounds.
-- Build a ProvinceGrid via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newProvinceGrid(...)
if instance then
  local ok, result = pcall(function() return instance:getAt(0, 0) end)
  print("ProvinceGrid:getAt ->", ok, result)
end

--@api-stub: ProvinceGrid:provinceCount
-- Returns the number of unique non-zero province IDs detected in the map.
-- Call when you need to invoke province count.
-- Build a ProvinceGrid via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newProvinceGrid(...)
if instance then
  local ok, result = pcall(function() return instance:provinceCount() end)
  print("ProvinceGrid:provinceCount ->", ok, result)
end

--@api-stub: ProvinceGrid:adjacencies
-- Returns an array of adjacency records.
-- Each record is {province_a, province_b, border_pixels}.
-- Build a ProvinceGrid via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newProvinceGrid(...)
if instance then
  local ok, result = pcall(function() return instance:adjacencies() end)
  print("ProvinceGrid:adjacencies ->", ok, result)
end

-- ── LayeredImage methods ──

--@api-stub: LayeredImage:getWidth
-- Returns the canvas width shared by all layers.
-- Call when you need to read width.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("LayeredImage:getWidth ->", ok, result)
end

--@api-stub: LayeredImage:getHeight
-- Returns the canvas height shared by all layers.
-- Call when you need to read height.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("LayeredImage:getHeight ->", ok, result)
end

--@api-stub: LayeredImage:layerCount
-- Returns the number of layers in the stack.
-- Call when you need to invoke layer count.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:layerCount() end)
  print("LayeredImage:layerCount ->", ok, result)
end

--@api-stub: LayeredImage:addLayer
-- Appends a new blank transparent layer on top and returns its 1-based index.
-- Call when you need to add layer.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:addLayer("sprites/player.png") end)
  print("LayeredImage:addLayer ->", ok, result)
end

--@api-stub: LayeredImage:removeLayer
-- Removes the layer at the given 1-based index.
-- Returns true on success.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:removeLayer(1) end)
  print("LayeredImage:removeLayer ->", ok, result)
end

--@api-stub: LayeredImage:getLayer
-- Returns a copy of the layer's pixel buffer as an ImageData.
-- Call when you need to read layer.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:getLayer(1) end)
  print("LayeredImage:getLayer ->", ok, result)
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of a layer in [0.0, 1.0].
-- Call when you need to read opacity.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:getOpacity(1) end)
  print("LayeredImage:getOpacity ->", ok, result)
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of a layer.
-- Value is clamped to [0.0, 1.0].
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:setOpacity(1, nil) end)
  print("LayeredImage:setOpacity ->", ok, result)
end

--@api-stub: LayeredImage:isVisible
-- Returns whether a layer is visible.
-- Call when you need to check is visible.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:isVisible(1) end)
  print("LayeredImage:isVisible ->", ok, result)
end

--@api-stub: LayeredImage:setVisible
-- Shows or hides a layer during compositing.
-- Call when you need to assign visible.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:setVisible(1, nil) end)
  print("LayeredImage:setVisible ->", ok, result)
end

--@api-stub: LayeredImage:getName
-- Returns the name of a layer.
-- Call when you need to read name.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:getName(1) end)
  print("LayeredImage:getName ->", ok, result)
end

--@api-stub: LayeredImage:setName
-- Renames the layer at the given index to the new name string.
-- Call when you need to assign name.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:setName(1, "sprites/player.png") end)
  print("LayeredImage:setName ->", ok, result)
end

--@api-stub: LayeredImage:swapLayers
-- Swaps two layers by their 1-based indices, changing their compositing order.
-- Call when you need to invoke swap layers.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:swapLayers(1, 1) end)
  print("LayeredImage:swapLayers ->", ok, result)
end

--@api-stub: LayeredImage:merge
-- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
-- Call when you need to invoke merge.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:merge() end)
  print("LayeredImage:merge ->", ok, result)
end

--@api-stub: LayeredImage:save
-- Saves the layered image to a LIMG binary file at the given path.
-- Call when you need to invoke save.
-- Build a LayeredImage via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newLayeredImage(...)
if instance then
  local ok, result = pcall(function() return instance:save("sprites/player.png") end)
  print("LayeredImage:save ->", ok, result)
end

-- ── CompressedImageData methods ──

--@api-stub: CompressedImageData:getWidth
-- Returns the width of the base mip level in pixels.
-- Call when you need to read width.
-- Build a CompressedImageData via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newCompressedImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("CompressedImageData:getWidth ->", ok, result)
end

--@api-stub: CompressedImageData:getHeight
-- Returns the height of the base mip level in pixels.
-- Call when you need to read height.
-- Build a CompressedImageData via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newCompressedImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("CompressedImageData:getHeight ->", ok, result)
end

--@api-stub: CompressedImageData:getDimensions
-- Returns the width and height of the base mip level.
-- Call when you need to read dimensions.
-- Build a CompressedImageData via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newCompressedImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("CompressedImageData:getDimensions ->", ok, result)
end

--@api-stub: CompressedImageData:getMipmapCount
-- Returns the number of mipmap levels stored.
-- Call when you need to read mipmap count.
-- Build a CompressedImageData via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newCompressedImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getMipmapCount() end)
  print("CompressedImageData:getMipmapCount ->", ok, result)
end

--@api-stub: CompressedImageData:getFormat
-- Returns the compressed format name string.
-- Call when you need to read format.
-- Build a CompressedImageData via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newCompressedImageData(...)
if instance then
  local ok, result = pcall(function() return instance:getFormat() end)
  print("CompressedImageData:getFormat ->", ok, result)
end

-- ── mlua methods ──

--@api-stub: mlua:getWidth
-- Returns the width.
-- Call when you need to read width.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getWidth() end)
  print("mlua:getWidth ->", ok, result)
end

--@api-stub: mlua:getHeight
-- Returns the height.
-- Call when you need to read height.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getHeight() end)
  print("mlua:getHeight ->", ok, result)
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions.
-- Call when you need to read dimensions.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("mlua:getDimensions ->", ok, result)
end

--@api-stub: mlua:getPixel
-- Returns the pixel.
-- Call when you need to read pixel.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getPixel(0, 0) end)
  print("mlua:getPixel ->", ok, result)
end

--@api-stub: mlua:encode
-- Encode.
-- Call when you need to invoke encode.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:encode("format value") end)
  print("mlua:encode ->", ok, result)
end

--@api-stub: mlua:getString
-- Returns the string.
-- Call when you need to read string.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getString() end)
  print("mlua:getString ->", ok, result)
end

--@api-stub: mlua:mapPixel
-- Map pixel.
-- Call when you need to invoke map pixel.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:mapPixel(function() end) end)
  print("mlua:mapPixel ->", ok, result)
end

--@api-stub: mlua:brightness
-- Brightness.
-- Call when you need to invoke brightness.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:brightness(1) end)
  print("mlua:brightness ->", ok, result)
end

--@api-stub: mlua:contrast
-- Contrast.
-- Call when you need to invoke contrast.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:contrast(1) end)
  print("mlua:contrast ->", ok, result)
end

--@api-stub: mlua:saturation
-- Saturation.
-- Call when you need to invoke saturation.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:saturation(1) end)
  print("mlua:saturation ->", ok, result)
end

--@api-stub: mlua:gamma
-- Gamma.
-- Call when you need to invoke gamma.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:gamma(nil) end)
  print("mlua:gamma ->", ok, result)
end

--@api-stub: mlua:grayscale
-- Grayscale.
-- Call when you need to invoke grayscale.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:grayscale() end)
  print("mlua:grayscale ->", ok, result)
end

--@api-stub: mlua:sepia
-- Sepia.
-- Call when you need to invoke sepia.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:sepia() end)
  print("mlua:sepia ->", ok, result)
end

--@api-stub: mlua:invert
-- Invert.
-- Call when you need to invoke invert.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:invert() end)
  print("mlua:invert ->", ok, result)
end

--@api-stub: mlua:threshold
-- Threshold.
-- Call when you need to invoke threshold.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:threshold(nil) end)
  print("mlua:threshold ->", ok, result)
end

--@api-stub: mlua:posterize
-- Posterize.
-- Call when you need to invoke posterize.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:posterize(nil) end)
  print("mlua:posterize ->", ok, result)
end

--@api-stub: mlua:fill
-- Fill.
-- Call when you need to invoke fill.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:fill(1, 1, 1, 1) end)
  print("mlua:fill ->", ok, result)
end

--@api-stub: mlua:noise
-- Noise.
-- Call when you need to invoke noise.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:noise(nil) end)
  print("mlua:noise ->", ok, result)
end

--@api-stub: mlua:alphaMask
-- Alpha mask.
-- Call when you need to invoke alpha mask.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:alphaMask(1) end)
  print("mlua:alphaMask ->", ok, result)
end

--@api-stub: mlua:flipHorizontal
-- Flip horizontal.
-- Call when you need to invoke flip horizontal.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:flipHorizontal() end)
  print("mlua:flipHorizontal ->", ok, result)
end

--@api-stub: mlua:flipVertical
-- Flip vertical.
-- Call when you need to invoke flip vertical.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:flipVertical() end)
  print("mlua:flipVertical ->", ok, result)
end

--@api-stub: mlua:rotate90cw
-- Rotate90cw.
-- Call when you need to invoke rotate90cw.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:rotate90cw() end)
  print("mlua:rotate90cw ->", ok, result)
end

--@api-stub: mlua:crop
-- Crop.
-- Call when you need to invoke crop.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:crop(0, 0, 100, 100) end)
  print("mlua:crop ->", ok, result)
end

--@api-stub: mlua:resizeNearest
-- Resize nearest.
-- Call when you need to invoke resize nearest.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:resizeNearest(nil, nil) end)
  print("mlua:resizeNearest ->", ok, result)
end

--@api-stub: mlua:blur
-- Blur.
-- Call when you need to invoke blur.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:blur(nil) end)
  print("mlua:blur ->", ok, result)
end

--@api-stub: mlua:sharpen
-- Sharpen.
-- Call when you need to invoke sharpen.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:sharpen() end)
  print("mlua:sharpen ->", ok, result)
end

--@api-stub: mlua:resize
-- Returns a bilinear-interpolated copy of the image at the given dimensions.
-- Call when you need to invoke resize.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:resize(100, 100) end)
  print("mlua:resize ->", ok, result)
end

--@api-stub: mlua:diff
-- Returns the sum of absolute per-channel pixel differences with another ImageData.
-- Call when you need to invoke diff.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:diff(nil) end)
  print("mlua:diff ->", ok, result)
end

--@api-stub: mlua:mapPixels
-- Applies a function to every pixel in-place.
-- Call when you need to invoke map pixels.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:mapPixels(function() end) end)
  print("mlua:mapPixels ->", ok, result)
end

--@api-stub: mlua:applyPaletteLut
-- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
-- Call when you need to invoke apply palette lut.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:applyPaletteLut(nil) end)
  print("mlua:applyPaletteLut ->", ok, result)
end

--@api-stub: mlua:setRawData
-- Replaces all pixel data from a raw RGBA byte string.
-- Call when you need to assign raw data.
-- Build a mlua via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:setRawData(nil) end)
  print("mlua:setRawData ->", ok, result)
end

-- ── PaletteLUT methods ──

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of colour mapping entries.
-- Call when you need to read color count.
-- Build a PaletteLUT via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newPaletteLUT(...)
if instance then
  local ok, result = pcall(function() return instance:getColorCount() end)
  print("PaletteLUT:getColorCount ->", ok, result)
end

--@api-stub: PaletteLUT:clear
-- Removes all colour mapping entries.
-- Call when you need to invoke clear.
-- Build a PaletteLUT via the appropriate lurek.image.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.image.newPaletteLUT(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("PaletteLUT:clear ->", ok, result)
end

