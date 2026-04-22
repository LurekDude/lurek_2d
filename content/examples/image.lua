-- content/examples/image.lua
-- Scaffolded coverage of the lurek.image API (68 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/image_api.rs   (Lua binding, arg types, return shape)
--   * src/image/                 (semantics, side effects)
--   * docs/specs/image.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/image.lua

-- ── lurek.image.* functions ──

--@api-stub: lurek.image.newImageData
-- Creates a new blank ImageData or loads one from a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.newImageData
  local _todo = "TODO: write a real lurek.image.newImageData usage example"
  print(_todo)
end

--@api-stub: lurek.image.newCompressedData
-- Loads compressed texture data from a DDS file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.newCompressedData
  local _todo = "TODO: write a real lurek.image.newCompressedData usage example"
  print(_todo)
end

--@api-stub: lurek.image.isCompressed
-- Returns true if the file at the given path is a DDS file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.isCompressed
  local _todo = "TODO: write a real lurek.image.isCompressed usage example"
  print(_todo)
end

--@api-stub: lurek.image.newLayeredImage
-- Creates a new empty LayeredImage canvas with no layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.newLayeredImage
  local _todo = "TODO: write a real lurek.image.newLayeredImage usage example"
  print(_todo)
end

--@api-stub: lurek.image.saveImage
-- Saves a flat ImageData to a LIMG binary file at the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.saveImage
  local _todo = "TODO: write a real lurek.image.saveImage usage example"
  print(_todo)
end

--@api-stub: lurek.image.savePNG
-- Saves a flat ImageData as a PNG file at the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.savePNG
  local _todo = "TODO: write a real lurek.image.savePNG usage example"
  print(_todo)
end

--@api-stub: lurek.image.loadImage
-- Loads an ImageData from a LIMG binary file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.loadImage
  local _todo = "TODO: write a real lurek.image.loadImage usage example"
  print(_todo)
end

--@api-stub: lurek.image.loadLayered
-- Loads a LayeredImage from a LIMG binary file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.loadLayered
  local _todo = "TODO: write a real lurek.image.loadLayered usage example"
  print(_todo)
end

--@api-stub: lurek.image.newPaletteLut
-- Creates a new empty `PaletteLUT` used to remap colours in an image.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.newPaletteLut
  local _todo = "TODO: write a real lurek.image.newPaletteLut usage example"
  print(_todo)
end

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: lurek.image.newProvinceGrid
  local _todo = "TODO: write a real lurek.image.newProvinceGrid usage example"
  print(_todo)
end

-- ── ProvinceGrid methods ──

--@api-stub: ProvinceGrid:getWidth
-- Returns the grid width in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: ProvinceGrid:getWidth
  local _todo = "TODO: write a real ProvinceGrid:getWidth usage example"
  print(_todo)
end

--@api-stub: ProvinceGrid:getHeight
-- Returns the grid height in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: ProvinceGrid:getHeight
  local _todo = "TODO: write a real ProvinceGrid:getHeight usage example"
  print(_todo)
end

--@api-stub: ProvinceGrid:getAt
-- Returns the province ID at pixel coordinates (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: ProvinceGrid:getAt
  local _todo = "TODO: write a real ProvinceGrid:getAt usage example"
  print(_todo)
end

--@api-stub: ProvinceGrid:provinceCount
-- Returns the number of unique non-zero province IDs detected in the map.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: ProvinceGrid:provinceCount
  local _todo = "TODO: write a real ProvinceGrid:provinceCount usage example"
  print(_todo)
end

--@api-stub: ProvinceGrid:adjacencies
-- Returns an array of adjacency records.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: ProvinceGrid:adjacencies
  local _todo = "TODO: write a real ProvinceGrid:adjacencies usage example"
  print(_todo)
end

-- ── LayeredImage methods ──

--@api-stub: LayeredImage:getWidth
-- Returns the canvas width shared by all layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:getWidth
  local _todo = "TODO: write a real LayeredImage:getWidth usage example"
  print(_todo)
end

--@api-stub: LayeredImage:getHeight
-- Returns the canvas height shared by all layers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:getHeight
  local _todo = "TODO: write a real LayeredImage:getHeight usage example"
  print(_todo)
end

--@api-stub: LayeredImage:layerCount
-- Returns the number of layers in the stack.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:layerCount
  local _todo = "TODO: write a real LayeredImage:layerCount usage example"
  print(_todo)
end

--@api-stub: LayeredImage:addLayer
-- Appends a new blank transparent layer on top and returns its 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:addLayer
  local _todo = "TODO: write a real LayeredImage:addLayer usage example"
  print(_todo)
end

--@api-stub: LayeredImage:removeLayer
-- Removes the layer at the given 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:removeLayer
  local _todo = "TODO: write a real LayeredImage:removeLayer usage example"
  print(_todo)
end

--@api-stub: LayeredImage:getLayer
-- Returns a copy of the layer's pixel buffer as an ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:getLayer
  local _todo = "TODO: write a real LayeredImage:getLayer usage example"
  print(_todo)
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of a layer in [0.0, 1.0].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:getOpacity
  local _todo = "TODO: write a real LayeredImage:getOpacity usage example"
  print(_todo)
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:setOpacity
  local _todo = "TODO: write a real LayeredImage:setOpacity usage example"
  print(_todo)
end

--@api-stub: LayeredImage:isVisible
-- Returns whether a layer is visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:isVisible
  local _todo = "TODO: write a real LayeredImage:isVisible usage example"
  print(_todo)
end

--@api-stub: LayeredImage:setVisible
-- Shows or hides a layer during compositing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:setVisible
  local _todo = "TODO: write a real LayeredImage:setVisible usage example"
  print(_todo)
end

--@api-stub: LayeredImage:getName
-- Returns the name of a layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:getName
  local _todo = "TODO: write a real LayeredImage:getName usage example"
  print(_todo)
end

--@api-stub: LayeredImage:setName
-- Renames the layer at the given index to the new name string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:setName
  local _todo = "TODO: write a real LayeredImage:setName usage example"
  print(_todo)
end

--@api-stub: LayeredImage:swapLayers
-- Swaps two layers by their 1-based indices, changing their compositing order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:swapLayers
  local _todo = "TODO: write a real LayeredImage:swapLayers usage example"
  print(_todo)
end

--@api-stub: LayeredImage:merge
-- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:merge
  local _todo = "TODO: write a real LayeredImage:merge usage example"
  print(_todo)
end

--@api-stub: LayeredImage:save
-- Saves the layered image to a LIMG binary file at the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: LayeredImage:save
  local _todo = "TODO: write a real LayeredImage:save usage example"
  print(_todo)
end

-- ── CompressedImageData methods ──

--@api-stub: CompressedImageData:getWidth
-- Returns the width of the base mip level in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: CompressedImageData:getWidth
  local _todo = "TODO: write a real CompressedImageData:getWidth usage example"
  print(_todo)
end

--@api-stub: CompressedImageData:getHeight
-- Returns the height of the base mip level in pixels.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: CompressedImageData:getHeight
  local _todo = "TODO: write a real CompressedImageData:getHeight usage example"
  print(_todo)
end

--@api-stub: CompressedImageData:getDimensions
-- Returns the width and height of the base mip level.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: CompressedImageData:getDimensions
  local _todo = "TODO: write a real CompressedImageData:getDimensions usage example"
  print(_todo)
end

--@api-stub: CompressedImageData:getMipmapCount
-- Returns the number of mipmap levels stored.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: CompressedImageData:getMipmapCount
  local _todo = "TODO: write a real CompressedImageData:getMipmapCount usage example"
  print(_todo)
end

--@api-stub: CompressedImageData:getFormat
-- Returns the compressed format name string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: CompressedImageData:getFormat
  local _todo = "TODO: write a real CompressedImageData:getFormat usage example"
  print(_todo)
end

-- ── mlua methods ──

--@api-stub: mlua:getWidth
-- Returns the width.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:getWidth
  local _todo = "TODO: write a real mlua:getWidth usage example"
  print(_todo)
end

--@api-stub: mlua:getHeight
-- Returns the height.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:getHeight
  local _todo = "TODO: write a real mlua:getHeight usage example"
  print(_todo)
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:getDimensions
  local _todo = "TODO: write a real mlua:getDimensions usage example"
  print(_todo)
end

--@api-stub: mlua:getPixel
-- Returns the pixel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:getPixel
  local _todo = "TODO: write a real mlua:getPixel usage example"
  print(_todo)
end

--@api-stub: mlua:encode
-- Encode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:encode
  local _todo = "TODO: write a real mlua:encode usage example"
  print(_todo)
end

--@api-stub: mlua:getString
-- Returns the string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:getString
  local _todo = "TODO: write a real mlua:getString usage example"
  print(_todo)
end

--@api-stub: mlua:mapPixel
-- Map pixel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:mapPixel
  local _todo = "TODO: write a real mlua:mapPixel usage example"
  print(_todo)
end

--@api-stub: mlua:brightness
-- Brightness.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:brightness
  local _todo = "TODO: write a real mlua:brightness usage example"
  print(_todo)
end

--@api-stub: mlua:contrast
-- Contrast.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:contrast
  local _todo = "TODO: write a real mlua:contrast usage example"
  print(_todo)
end

--@api-stub: mlua:saturation
-- Saturation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:saturation
  local _todo = "TODO: write a real mlua:saturation usage example"
  print(_todo)
end

--@api-stub: mlua:gamma
-- Gamma.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:gamma
  local _todo = "TODO: write a real mlua:gamma usage example"
  print(_todo)
end

--@api-stub: mlua:grayscale
-- Grayscale.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:grayscale
  local _todo = "TODO: write a real mlua:grayscale usage example"
  print(_todo)
end

--@api-stub: mlua:sepia
-- Sepia.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:sepia
  local _todo = "TODO: write a real mlua:sepia usage example"
  print(_todo)
end

--@api-stub: mlua:invert
-- Invert.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:invert
  local _todo = "TODO: write a real mlua:invert usage example"
  print(_todo)
end

--@api-stub: mlua:threshold
-- Threshold.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:threshold
  local _todo = "TODO: write a real mlua:threshold usage example"
  print(_todo)
end

--@api-stub: mlua:posterize
-- Posterize.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:posterize
  local _todo = "TODO: write a real mlua:posterize usage example"
  print(_todo)
end

--@api-stub: mlua:fill
-- Fill.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:fill
  local _todo = "TODO: write a real mlua:fill usage example"
  print(_todo)
end

--@api-stub: mlua:noise
-- Noise.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:noise
  local _todo = "TODO: write a real mlua:noise usage example"
  print(_todo)
end

--@api-stub: mlua:alphaMask
-- Alpha mask.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:alphaMask
  local _todo = "TODO: write a real mlua:alphaMask usage example"
  print(_todo)
end

--@api-stub: mlua:flipHorizontal
-- Flip horizontal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:flipHorizontal
  local _todo = "TODO: write a real mlua:flipHorizontal usage example"
  print(_todo)
end

--@api-stub: mlua:flipVertical
-- Flip vertical.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:flipVertical
  local _todo = "TODO: write a real mlua:flipVertical usage example"
  print(_todo)
end

--@api-stub: mlua:rotate90cw
-- Rotate90cw.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:rotate90cw
  local _todo = "TODO: write a real mlua:rotate90cw usage example"
  print(_todo)
end

--@api-stub: mlua:crop
-- Crop.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:crop
  local _todo = "TODO: write a real mlua:crop usage example"
  print(_todo)
end

--@api-stub: mlua:resizeNearest
-- Resize nearest.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:resizeNearest
  local _todo = "TODO: write a real mlua:resizeNearest usage example"
  print(_todo)
end

--@api-stub: mlua:blur
-- Blur.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:blur
  local _todo = "TODO: write a real mlua:blur usage example"
  print(_todo)
end

--@api-stub: mlua:sharpen
-- Sharpen.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:sharpen
  local _todo = "TODO: write a real mlua:sharpen usage example"
  print(_todo)
end

--@api-stub: mlua:resize
-- Returns a bilinear-interpolated copy of the image at the given dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:resize
  local _todo = "TODO: write a real mlua:resize usage example"
  print(_todo)
end

--@api-stub: mlua:diff
-- Returns the sum of absolute per-channel pixel differences with another ImageData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:diff
  local _todo = "TODO: write a real mlua:diff usage example"
  print(_todo)
end

--@api-stub: mlua:mapPixels
-- Applies a function to every pixel in-place.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:mapPixels
  local _todo = "TODO: write a real mlua:mapPixels usage example"
  print(_todo)
end

--@api-stub: mlua:applyPaletteLut
-- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:applyPaletteLut
  local _todo = "TODO: write a real mlua:applyPaletteLut usage example"
  print(_todo)
end

--@api-stub: mlua:setRawData
-- Replaces all pixel data from a raw RGBA byte string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: mlua:setRawData
  local _todo = "TODO: write a real mlua:setRawData usage example"
  print(_todo)
end

-- ── PaletteLUT methods ──

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of colour mapping entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: PaletteLUT:getColorCount
  local _todo = "TODO: write a real PaletteLUT:getColorCount usage example"
  print(_todo)
end

--@api-stub: PaletteLUT:clear
-- Removes all colour mapping entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/image_api.rs and docs/specs/image.md).
do  -- TODO: PaletteLUT:clear
  local _todo = "TODO: write a real PaletteLUT:clear usage example"
  print(_todo)
end

