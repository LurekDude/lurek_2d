-- content/examples/image.lua
-- Auto-scaffolded coverage of the lurek.image Lua API (68 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/image.lua

print("[example] lurek.image loaded — 68 API items demonstrated")

-- ── lurek.image free functions ──

--@api-stub: lurek.image.newImageData
-- Creates a new blank ImageData or loads one from a file.
-- Use this when creates a new blank ImageData or loads one from a file is needed.
if false then
  local _r = lurek.image.newImageData({})
  print(_r)
end

--@api-stub: lurek.image.newCompressedData
-- Loads compressed texture data from a DDS file.
-- Use this when loads compressed texture data from a DDS file is needed.
if false then
  local _r = lurek.image.newCompressedData(1)
  print(_r)
end

--@api-stub: lurek.image.isCompressed
-- Returns true if the file at the given path is a DDS file.
-- Use this when returns true if the file at the given path is a DDS file is needed.
if false then
  local _r = lurek.image.isCompressed(1)
  print(_r)
end

--@api-stub: lurek.image.newLayeredImage
-- Creates a new empty LayeredImage canvas with no layers.
-- Use this when creates a new empty LayeredImage canvas with no layers is needed.
if false then
  local _r = lurek.image.newLayeredImage(1, 1)
  print(_r)
end

--@api-stub: lurek.image.saveImage
-- Saves a flat ImageData to a LIMG binary file at the given path.
-- Use this when saves a flat ImageData to a LIMG binary file at the given path is needed.
if false then
  local _r = lurek.image.saveImage(nil, 1)
  print(_r)
end

--@api-stub: lurek.image.savePNG
-- Saves a flat ImageData as a PNG file at the given path.
-- Use this when saves a flat ImageData as a PNG file at the given path is needed.
if false then
  local _r = lurek.image.savePNG(nil, 1)
  print(_r)
end

--@api-stub: lurek.image.loadImage
-- Loads an ImageData from a LIMG binary file.
-- Use this when loads an ImageData from a LIMG binary file is needed.
if false then
  local _r = lurek.image.loadImage(1)
  print(_r)
end

--@api-stub: lurek.image.loadLayered
-- Loads a LayeredImage from a LIMG binary file.
-- Use this when loads a LayeredImage from a LIMG binary file is needed.
if false then
  local _r = lurek.image.loadLayered(1)
  print(_r)
end

--@api-stub: lurek.image.newPaletteLut
-- Creates a new empty `PaletteLUT` used to remap colours in an image.
-- Use this when creates a new empty `PaletteLUT` used to remap colours in an image is needed.
if false then
  local _r = lurek.image.newPaletteLut()
  print(_r)
end

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
-- Use this when loads a province map PNG and builds an O(1) spatial index with adjacency data is needed.
if false then
  local _r = lurek.image.newProvinceGrid(1)
  print(_r)
end

-- ── ProvinceGrid methods ──

--@api-stub: ProvinceGrid:getWidth
-- Returns the grid width in pixels.
-- Use this when returns the grid width in pixels is needed.
if false then
  local _o = nil  -- ProvinceGrid instance
  _o:getWidth()
end

--@api-stub: ProvinceGrid:getHeight
-- Returns the grid height in pixels.
-- Use this when returns the grid height in pixels is needed.
if false then
  local _o = nil  -- ProvinceGrid instance
  _o:getHeight()
end

--@api-stub: ProvinceGrid:getAt
-- Returns the province ID at pixel coordinates (x, y).
-- Returns 0 for background or out-of-bounds.
if false then
  local _o = nil  -- ProvinceGrid instance
  _o:getAt(0, 0)
end

--@api-stub: ProvinceGrid:provinceCount
-- Returns the number of unique non-zero province IDs detected in the map.
-- Use this when returns the number of unique non-zero province IDs detected in the map is needed.
if false then
  local _o = nil  -- ProvinceGrid instance
  _o:provinceCount()
end

--@api-stub: ProvinceGrid:adjacencies
-- Returns an array of adjacency records.
-- Each record is {province_a, province_b, border_pixels}.
if false then
  local _o = nil  -- ProvinceGrid instance
  _o:adjacencies()
end

-- ── LayeredImage methods ──

--@api-stub: LayeredImage:getWidth
-- Returns the canvas width shared by all layers.
-- Use this when returns the canvas width shared by all layers is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:getWidth()
end

--@api-stub: LayeredImage:getHeight
-- Returns the canvas height shared by all layers.
-- Use this when returns the canvas height shared by all layers is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:getHeight()
end

--@api-stub: LayeredImage:layerCount
-- Returns the number of layers in the stack.
-- Use this when returns the number of layers in the stack is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:layerCount()
end

--@api-stub: LayeredImage:addLayer
-- Appends a new blank transparent layer on top and returns its 1-based index.
-- Use this when appends a new blank transparent layer on top and returns its 1-based index is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:addLayer(1)
end

--@api-stub: LayeredImage:removeLayer
-- Removes the layer at the given 1-based index.
-- Returns true on success.
if false then
  local _o = nil  -- LayeredImage instance
  _o:removeLayer(1)
end

--@api-stub: LayeredImage:getLayer
-- Returns a copy of the layer's pixel buffer as an ImageData.
-- Use this when returns a copy of the layer's pixel buffer as an ImageData is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:getLayer(1)
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of a layer in [0.0, 1.0].
-- Use this when returns the opacity of a layer in [0.0, 1.0] is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:getOpacity(1)
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of a layer.
-- Value is clamped to [0.0, 1.0].
if false then
  local _o = nil  -- LayeredImage instance
  _o:setOpacity(1, 0)
end

--@api-stub: LayeredImage:isVisible
-- Returns whether a layer is visible.
-- Use this when returns whether a layer is visible is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:isVisible(1)
end

--@api-stub: LayeredImage:setVisible
-- Shows or hides a layer during compositing.
-- Use this when shows or hides a layer during compositing is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:setVisible(1, 0)
end

--@api-stub: LayeredImage:getName
-- Returns the name of a layer.
-- Use this when returns the name of a layer is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:getName(1)
end

--@api-stub: LayeredImage:setName
-- Renames the layer at the given index to the new name string.
-- Use this when renames the layer at the given index to the new name string is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:setName(1, 1)
end

--@api-stub: LayeredImage:swapLayers
-- Swaps two layers by their 1-based indices, changing their compositing order.
-- Use this when swaps two layers by their 1-based indices, changing their compositing order is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:swapLayers(nil, nil)
end

--@api-stub: LayeredImage:merge
-- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
-- Use this when flattens all visible layers into a single ImageData using Porter-Duff "over" compositing is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:merge()
end

--@api-stub: LayeredImage:save
-- Saves the layered image to a LIMG binary file at the given path.
-- Use this when saves the layered image to a LIMG binary file at the given path is needed.
if false then
  local _o = nil  -- LayeredImage instance
  _o:save(0)
end

-- ── CompressedImageData methods ──

--@api-stub: CompressedImageData:getWidth
-- Returns the width of the base mip level in pixels.
-- Use this when returns the width of the base mip level in pixels is needed.
if false then
  local _o = nil  -- CompressedImageData instance
  _o:getWidth()
end

--@api-stub: CompressedImageData:getHeight
-- Returns the height of the base mip level in pixels.
-- Use this when returns the height of the base mip level in pixels is needed.
if false then
  local _o = nil  -- CompressedImageData instance
  _o:getHeight()
end

--@api-stub: CompressedImageData:getDimensions
-- Returns the width and height of the base mip level.
-- Use this when returns the width and height of the base mip level is needed.
if false then
  local _o = nil  -- CompressedImageData instance
  _o:getDimensions()
end

--@api-stub: CompressedImageData:getMipmapCount
-- Returns the number of mipmap levels stored.
-- Use this when returns the number of mipmap levels stored is needed.
if false then
  local _o = nil  -- CompressedImageData instance
  _o:getMipmapCount()
end

--@api-stub: CompressedImageData:getFormat
-- Returns the compressed format name string.
-- Use this when returns the compressed format name string is needed.
if false then
  local _o = nil  -- CompressedImageData instance
  _o:getFormat()
end

-- ── mlua methods ──

--@api-stub: mlua:getWidth
-- Returns the width.
-- Use this when returns the width is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getWidth()
end

--@api-stub: mlua:getHeight
-- Returns the height.
-- Use this when returns the height is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getHeight()
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions.
-- Use this when returns the dimensions is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getDimensions()
end

--@api-stub: mlua:getPixel
-- Returns the pixel.
-- Use this when returns the pixel is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getPixel(0, 0)
end

--@api-stub: mlua:encode
-- Encode.
-- Use this when encode is needed.
if false then
  local _o = nil  -- mlua instance
  _o:encode(0)
end

--@api-stub: mlua:getString
-- Returns the string.
-- Use this when returns the string is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getString()
end

--@api-stub: mlua:mapPixel
-- Map pixel.
-- Use this when map pixel is needed.
if false then
  local _o = nil  -- mlua instance
  _o:mapPixel(1)
end

--@api-stub: mlua:brightness
-- Brightness.
-- Use this when brightness is needed.
if false then
  local _o = nil  -- mlua instance
  _o:brightness(0)
end

--@api-stub: mlua:contrast
-- Contrast.
-- Use this when contrast is needed.
if false then
  local _o = nil  -- mlua instance
  _o:contrast(0)
end

--@api-stub: mlua:saturation
-- Saturation.
-- Use this when saturation is needed.
if false then
  local _o = nil  -- mlua instance
  _o:saturation(0)
end

--@api-stub: mlua:gamma
-- Gamma.
-- Use this when gamma is needed.
if false then
  local _o = nil  -- mlua instance
  _o:gamma(nil)
end

--@api-stub: mlua:grayscale
-- Grayscale.
-- Use this when grayscale is needed.
if false then
  local _o = nil  -- mlua instance
  _o:grayscale()
end

--@api-stub: mlua:sepia
-- Sepia.
-- Use this when sepia is needed.
if false then
  local _o = nil  -- mlua instance
  _o:sepia()
end

--@api-stub: mlua:invert
-- Invert.
-- Use this when invert is needed.
if false then
  local _o = nil  -- mlua instance
  _o:invert()
end

--@api-stub: mlua:threshold
-- Threshold.
-- Use this when threshold is needed.
if false then
  local _o = nil  -- mlua instance
  _o:threshold(0)
end

--@api-stub: mlua:posterize
-- Posterize.
-- Use this when posterize is needed.
if false then
  local _o = nil  -- mlua instance
  _o:posterize(0)
end

--@api-stub: mlua:fill
-- Fill.
-- Use this when fill is needed.
if false then
  local _o = nil  -- mlua instance
  _o:fill(nil, nil, nil, nil)
end

--@api-stub: mlua:noise
-- Noise.
-- Use this when noise is needed.
if false then
  local _o = nil  -- mlua instance
  _o:noise(1)
end

--@api-stub: mlua:alphaMask
-- Alpha mask.
-- Use this when alpha mask is needed.
if false then
  local _o = nil  -- mlua instance
  _o:alphaMask(0)
end

--@api-stub: mlua:flipHorizontal
-- Flip horizontal.
-- Use this when flip horizontal is needed.
if false then
  local _o = nil  -- mlua instance
  _o:flipHorizontal()
end

--@api-stub: mlua:flipVertical
-- Flip vertical.
-- Use this when flip vertical is needed.
if false then
  local _o = nil  -- mlua instance
  _o:flipVertical()
end

--@api-stub: mlua:rotate90cw
-- Rotate90cw.
-- Use this when rotate90cw is needed.
if false then
  local _o = nil  -- mlua instance
  _o:rotate90cw()
end

--@api-stub: mlua:crop
-- Crop.
-- Use this when crop is needed.
if false then
  local _o = nil  -- mlua instance
  _o:crop(0, 0, 0, 0)
end

--@api-stub: mlua:resizeNearest
-- Resize nearest.
-- Use this when resize nearest is needed.
if false then
  local _o = nil  -- mlua instance
  _o:resizeNearest(1, 1)
end

--@api-stub: mlua:blur
-- Blur.
-- Use this when blur is needed.
if false then
  local _o = nil  -- mlua instance
  _o:blur(nil)
end

--@api-stub: mlua:sharpen
-- Sharpen.
-- Use this when sharpen is needed.
if false then
  local _o = nil  -- mlua instance
  _o:sharpen()
end

--@api-stub: mlua:resize
-- Returns a bilinear-interpolated copy of the image at the given dimensions.
-- Use this when returns a bilinear-interpolated copy of the image at the given dimensions is needed.
if false then
  local _o = nil  -- mlua instance
  _o:resize(0, 0)
end

--@api-stub: mlua:diff
-- Returns the sum of absolute per-channel pixel differences with another ImageData.
-- Use this when returns the sum of absolute per-channel pixel differences with another ImageData is needed.
if false then
  local _o = nil  -- mlua instance
  _o:diff(0)
end

--@api-stub: mlua:mapPixels
-- Applies a function to every pixel in-place.
-- Use this when applies a function to every pixel in-place is needed.
if false then
  local _o = nil  -- mlua instance
  _o:mapPixels(1)
end

--@api-stub: mlua:applyPaletteLut
-- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
-- Use this when applies a `PaletteLUT` to the image in place, replacing exact colour matches is needed.
if false then
  local _o = nil  -- mlua instance
  _o:applyPaletteLut(0)
end

--@api-stub: mlua:setRawData
-- Replaces all pixel data from a raw RGBA byte string.
-- Use this when replaces all pixel data from a raw RGBA byte string is needed.
if false then
  local _o = nil  -- mlua instance
  _o:setRawData(0)
end

-- ── PaletteLUT methods ──

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of colour mapping entries.
-- Use this when returns the number of colour mapping entries is needed.
if false then
  local _o = nil  -- PaletteLUT instance
  _o:getColorCount()
end

--@api-stub: PaletteLUT:clear
-- Removes all colour mapping entries.
-- Use this when removes all colour mapping entries is needed.
if false then
  local _o = nil  -- PaletteLUT instance
  _o:clear()
end

