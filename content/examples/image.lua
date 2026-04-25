-- content/examples/image.lua
-- Hand-written coverage of the lurek.image API (68 items).
--
-- The lurek.image namespace owns CPU-side pixel buffers (ImageData),
-- compressed DDS payloads, layered painting canvases (LayeredImage),
-- province-map spatial indices, and palette remapping tables. All
-- image paths are resolved against the project's game directory.
--
-- Run: cargo run -- content/examples/image.lua

-- ── lurek.image.* functions ──

--@api-stub: lurek.image.newImageData
-- Creates a new blank ImageData or loads one from a file.
-- Pass a path to load from disk, or (width, height) to allocate a transparent RGBA8 buffer.
do  -- lurek.image.newImageData
  local hero = lurek.image.newImageData(64, 64)
  local scratch = lurek.image.newImageData(64, 64)
  scratch:fill(0, 0, 0, 0)
  lurek.log.info("loaded hero " .. hero:getWidth() .. "x" .. hero:getHeight(), "image")
end

--@api-stub: lurek.image.newCompressedData
-- Loads compressed texture data from a DDS file.
-- Use for GPU-ready BCn formats so wgpu can upload without a CPU decode pass.
do  -- lurek.image.newCompressedData
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local mips = (cd and cd:getMipmapCount() or 0)
  lurek.log.info("dds " .. (cd and cd:getFormat() or "unknown") .. " mips=" .. mips, "image")
end

--@api-stub: lurek.image.isCompressed
-- Returns true if the file at the given path is a DDS file.
-- Branch on this before choosing newCompressedData vs newImageData for unknown asset paths.
do  -- lurek.image.isCompressed
  local path = "assets/terrain_bc1.dds"
  local _ok_ic, _is_c = pcall(lurek.image.isCompressed, path)
  if _ok_ic and _is_c then
    pcall(lurek.image.newCompressedData, path)
  else
    lurek.image.newImageData(64, 64)
  end
end

--@api-stub: lurek.image.newLayeredImage
-- Creates a new empty LayeredImage canvas with no layers.
-- Use as a paint document; addLayer() afterwards to begin compositing.
do  -- lurek.image.newLayeredImage
  local doc = lurek.image.newLayeredImage(256, 256)
  local bg = doc:addLayer("background")
  local fg = doc:addLayer("foreground")
  lurek.log.info("layers bg=" .. bg .. " fg=" .. fg, "image")
end

--@api-stub: lurek.image.saveImage
-- Saves a flat ImageData to a LIMG binary file at the given path.
-- LIMG preserves raw RGBA8 with no quality loss; prefer it over PNG for round-trip pipelines.
do  -- lurek.image.saveImage
  local img = lurek.image.newImageData(64, 64)
  img:fill(255, 128, 0, 255)
  lurek.image.saveImage(img, "save/orange64.limg")
end

--@api-stub: lurek.image.savePNG
-- Saves a flat ImageData as a PNG file at the given path.
-- Use for screenshots, thumbnails, and any artifact a human or external tool will open.
do  -- lurek.image.savePNG
  local shot = lurek.image.newImageData(128, 64)
  shot:fill(20, 30, 40, 255)
  shot:drawCircle(64, 32, 24, 255, 200, 0, 255)
  lurek.image.savePNG(shot, "save/screenshot.png")
end

--@api-stub: lurek.image.loadImage
-- Loads an ImageData from a LIMG binary file.
-- Pair with saveImage() to reload pixel buffers written by an earlier session.
do  -- lurek.image.loadImage
  local restored = lurek.image.loadImage("save/orange64.limg")
  local w, h = restored:getDimensions()
  lurek.log.info("restored " .. w .. "x" .. h, "image")
end

--@api-stub: lurek.image.loadLayered
-- Loads a LayeredImage from a LIMG binary file.
-- Use for resuming a paint document with all named layers, opacities, and visibility intact.
do  -- lurek.image.loadLayered
  pcall(function()
    local doc = lurek.image.loadLayered("save/painting.limg")
    local count = doc:layerCount()
    lurek.log.info("painting reopened with " .. count .. " layers", "image")
  end)
end

--@api-stub: lurek.image.newPaletteLut
-- Creates a new empty `PaletteLUT` used to remap colours in an image.
-- Build once with setColor() entries, then apply to many sprites that share the same palette.
do  -- lurek.image.newPaletteLut
  local lut = lurek.image.newPaletteLut()
  local before = lut:getColorCount()
  lurek.log.info("new lut entries=" .. before, "image")
end

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province map PNG and builds an O(1) spatial index with adjacency data.
-- Use for grand-strategy maps where each unique RGB colour identifies one province.
do  -- lurek.image.newProvinceGrid
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  lurek.log.info("loaded " .. count .. " provinces", "map")
end

-- ── ProvinceGrid methods ──

--@api-stub: ProvinceGrid:getWidth
-- Returns the grid width in pixels.
-- Pair with getHeight() to clamp mouse coordinates before calling getAt().
do  -- ProvinceGrid:getWidth
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local w = (grid and grid:getWidth() or 0)
  if w > 0 then
    lurek.log.info("province map width=" .. w, "map")
  end
end

--@api-stub: ProvinceGrid:getHeight
-- Returns the grid height in pixels.
-- Use alongside getWidth() to size the rendered minimap or perform bounds checks.
do  -- ProvinceGrid:getHeight
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local h = (grid and grid:getHeight() or 0)
  lurek.log.info("province map height=" .. h, "map")
end

--@api-stub: ProvinceGrid:getAt
-- Returns the province ID at pixel coordinates (x, y).
-- Returns 0 for the background; check for non-zero before treating the click as a province.
do  -- ProvinceGrid:getAt
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local id = (grid and grid:getAt(128, 96) or 0)
  if id ~= 0 then
    lurek.log.info("clicked province " .. id, "map")
  end
end

--@api-stub: ProvinceGrid:provinceCount
-- Returns the number of unique non-zero province IDs detected in the map.
-- Pre-allocate per-province arrays (owners, populations) using this count at startup.
do  -- ProvinceGrid:provinceCount
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  local owners = {}
  for i = 1, count do owners[i] = 0 end
  lurek.log.info("allocated owner table for " .. count .. " provinces", "map")
end

--@api-stub: ProvinceGrid:adjacencies
-- Returns an array of adjacency records.
-- Walk the result to build a graph for AI invasion planning or border rendering.
do  -- ProvinceGrid:adjacencies
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local edges = (grid and grid:adjacencies() or {})
  lurek.log.info("adjacency edges=" .. #edges, "map")
end

-- ── LayeredImage methods ──

--@api-stub: LayeredImage:getWidth
-- Returns the canvas width shared by all layers.
-- Use to size brush strokes or to validate imported layer buffers match the canvas.
do  -- LayeredImage:getWidth
  local doc = lurek.image.newLayeredImage(256, 128)
  local w = doc:getWidth()
  lurek.log.info("canvas width=" .. w, "paint")
end

--@api-stub: LayeredImage:getHeight
-- Returns the canvas height shared by all layers.
-- Pair with getWidth() to centre tools or build coordinate transforms.
do  -- LayeredImage:getHeight
  local doc = lurek.image.newLayeredImage(256, 128)
  local h = doc:getHeight()
  lurek.log.info("canvas height=" .. h, "paint")
end

--@api-stub: LayeredImage:layerCount
-- Returns the number of layers in the stack.
-- Use to drive a layers panel or to iterate every layer with getLayer(i).
do  -- LayeredImage:layerCount
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  doc:addLayer("ink")
  lurek.log.info("layer count=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:addLayer
-- Appends a new blank transparent layer on top and returns its 1-based index.
-- Capture the returned index so subsequent setName / setOpacity / setVisible target the right layer.
do  -- LayeredImage:addLayer
  local doc = lurek.image.newLayeredImage(128, 128)
  local idx = doc:addLayer("highlights")
  doc:setOpacity(idx, 0.75)
  lurek.log.info("added layer at index " .. idx, "paint")
end

--@api-stub: LayeredImage:removeLayer
-- Removes the layer at the given 1-based index.
-- Subsequent layer indices shift down by one — refresh any cached ids after a remove.
do  -- LayeredImage:removeLayer
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("scratch")
  doc:removeLayer(1)
  lurek.log.info("layers after remove=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:getLayer
-- Returns a copy of the layer's pixel buffer as an ImageData.
-- The returned ImageData is a snapshot; mutate it freely without affecting the source layer.
do  -- LayeredImage:getLayer
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local snap = doc:getLayer(1)
  lurek.image.savePNG(snap, "save/layer1.png")
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of a layer in [0.0, 1.0].
-- Read before adjusting so a slider can fade towards the existing value rather than snapping.
do  -- LayeredImage:getOpacity
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  local a = doc:getOpacity(1)
  lurek.log.info("layer 1 opacity=" .. a, "paint")
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of a layer.
-- Clamp UI sliders to [0, 1]; setOpacity itself accepts only that range.
do  -- LayeredImage:setOpacity
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("shadow")
  doc:setOpacity(idx, 0.5)
end

--@api-stub: LayeredImage:isVisible
-- Returns whether a layer is visible.
-- Use to drive the eye-icon state in a layers panel or to skip merge work for hidden layers.
do  -- LayeredImage:isVisible
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  if doc:isVisible(1) then
    lurek.log.info("layer 1 is visible", "paint")
  end
end

--@api-stub: LayeredImage:setVisible
-- Shows or hides a layer during compositing.
-- Toggle from a UI handler; merge() and save() respect the visibility flag.
do  -- LayeredImage:setVisible
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("guides")
  doc:setVisible(idx, false)
end

--@api-stub: LayeredImage:getName
-- Returns the name of a layer.
-- Use to populate a layers panel or to look up a layer by user-friendly label.
do  -- LayeredImage:getName
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("background")
  local name = doc:getName(1)
  lurek.log.info("layer 1 name='" .. name .. "'", "paint")
end

--@api-stub: LayeredImage:setName
-- Renames the layer at the given index to the new name string.
-- Call after a user double-clicks the layer label; names need not be unique.
do  -- LayeredImage:setName
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("untitled")
  doc:setName(idx, "background")
end

--@api-stub: LayeredImage:swapLayers
-- Swaps two layers by their 1-based indices, changing their compositing order.
-- Use when the user drags a layer up or down in the panel; only adjacent swaps need a single call.
do  -- LayeredImage:swapLayers
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("a")
  doc:addLayer("b")
  doc:swapLayers(1, 2)
end

--@api-stub: LayeredImage:merge
-- Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
-- Use to bake a paint document for export or to upload as a single GPU texture.
do  -- LayeredImage:merge
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local flat = doc:merge()
  lurek.image.savePNG(flat, "save/flattened.png")
end

--@api-stub: LayeredImage:save
-- Saves the layered image to a LIMG binary file at the given path.
-- LIMG preserves layer names, opacities, and visibility; use for project files, not exports.
do  -- LayeredImage:save
  local doc = lurek.image.newLayeredImage(128, 128)
  doc:addLayer("background")
  doc:save("save/painting.limg")
end

-- ── CompressedImageData methods ──

--@api-stub: CompressedImageData:getWidth
-- Returns the width of the base mip level in pixels.
-- Use to validate atlases or to compute UV coordinates for compressed textures.
do  -- CompressedImageData:getWidth
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local w = (cd and cd:getWidth() or 0)
  lurek.log.info("dds base width=" .. w, "image")
end

--@api-stub: CompressedImageData:getHeight
-- Returns the height of the base mip level in pixels.
-- Pair with getWidth() to size the destination quad before drawing.
do  -- CompressedImageData:getHeight
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local h = (cd and cd:getHeight() or 0)
  lurek.log.info("dds base height=" .. h, "image")
end

--@api-stub: CompressedImageData:getDimensions
-- Returns the width and height of the base mip level.
-- One call instead of two when you need both dimensions in a single statement.
do  -- CompressedImageData:getDimensions
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local w = cd and cd:getWidth() or 0
  local h = cd and cd:getHeight() or 0
  lurek.log.info("dds " .. w .. "x" .. h, "image")
end

--@api-stub: CompressedImageData:getMipmapCount
-- Returns the number of mipmap levels stored.
-- Branch on >1 to enable trilinear sampling; use 1 for pixel-art atlases that ship without mips.
do  -- CompressedImageData:getMipmapCount
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local mips = (cd and cd:getMipmapCount() or 0)
  if mips > 1 then
    lurek.log.info("trilinear ready, mips=" .. mips, "image")
  end
end

--@api-stub: CompressedImageData:getFormat
-- Returns the compressed format name string.
-- Inspect to confirm the DDS uses an expected BCn variant before uploading.
do  -- CompressedImageData:getFormat
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local fmt = (cd and cd:getFormat() or "unknown")
  lurek.log.info("dds format=" .. fmt, "image")
end

-- ── ImageData methods ──

--@api-stub: mlua:getWidth
-- Returns the width.
-- Read after newImageData/loadImage to size the destination canvas or sprite quad.
do  -- mlua:getWidth
  local img = lurek.image.newImageData(64, 64)
  local w = img:getWidth()
  lurek.log.info("hero width=" .. w, "image")
end

--@api-stub: mlua:getHeight
-- Returns the height.
-- Use with getWidth() to lay out atlases or compute aspect ratio.
do  -- mlua:getHeight
  local img = lurek.image.newImageData(64, 64)
  local h = img:getHeight()
  lurek.log.info("hero height=" .. h, "image")
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions.
-- One call for both axes; useful when destructuring straight into local variables.
do  -- mlua:getDimensions
  local img = lurek.image.newImageData(64, 64)
  local w, h = img:getDimensions()
  lurek.log.info("hero " .. w .. "x" .. h, "image")
end

--@api-stub: mlua:getPixel
-- Returns the pixel.
-- Out-of-bounds (x, y) raises an error; clamp inputs against getDimensions() first.
do  -- mlua:getPixel
  local img = lurek.image.newImageData(64, 64)
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("top-left rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "image")
end

--@api-stub: mlua:encode
-- Encode.
-- Only "png" is currently supported; the returned string is a complete PNG file body.
do  -- mlua:encode
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 200, 100, 255)
  local png_bytes = img:encode("png")
  lurek.log.info("png byte length=" .. #png_bytes, "image")
end

--@api-stub: mlua:getString
-- Returns the string.
-- Returns the raw RGBA8 byte string; useful for hashing or shipping over a network channel.
do  -- mlua:getString
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)
  local raw = img:getString()
  lurek.log.info("raw bytes=" .. #raw, "image")
end

--@api-stub: mlua:mapPixel
-- Map pixel.
-- Callback receives (x, y, r, g, b, a) and must return four bytes; runs on the Lua thread.
do  -- mlua:mapPixel
  local img = lurek.image.newImageData(32, 32)
  img:fill(64, 64, 64, 255)
  img:mapPixel(function(_, _, r, g, b, a) return 255 - r, 255 - g, 255 - b, a end)
end

--@api-stub: mlua:brightness
-- Brightness.
-- Factor > 1.0 brightens, < 1.0 darkens; clamps internally to valid byte range.
do  -- mlua:brightness
  local img = lurek.image.newImageData(64, 64)
  img:brightness(1.2)
  lurek.image.savePNG(img, "save/hero_brighter.png")
end

--@api-stub: mlua:contrast
-- Contrast.
-- 1.0 is identity; 1.5 boosts contrast moderately, 0.5 mutes it.
do  -- mlua:contrast
  local img = lurek.image.newImageData(64, 64)
  img:contrast(1.4)
  lurek.image.savePNG(img, "save/hero_contrast.png")
end

--@api-stub: mlua:saturation
-- Saturation.
-- 0.0 yields grayscale, 1.0 is identity, >1.0 boosts colour.
do  -- mlua:saturation
  local img = lurek.image.newImageData(64, 64)
  img:saturation(0.0)
  lurek.image.savePNG(img, "save/hero_desaturated.png")
end

--@api-stub: mlua:gamma
-- Gamma.
-- Use ~2.2 to encode linear data to sRGB-like space, ~0.4545 for the inverse.
do  -- mlua:gamma
  local img = lurek.image.newImageData(64, 64)
  img:gamma(2.2)
  lurek.image.savePNG(img, "save/hero_gamma.png")
end

--@api-stub: mlua:grayscale
-- Grayscale.
-- Uses luminance weights; alpha is preserved untouched.
do  -- mlua:grayscale
  local img = lurek.image.newImageData(64, 64)
  img:grayscale()
  lurek.image.savePNG(img, "save/hero_gray.png")
end

--@api-stub: mlua:sepia
-- Sepia.
-- Applies a fixed warm-tone matrix; pair with brightness() to taste before saving.
do  -- mlua:sepia
  local img = lurek.image.newImageData(64, 64)
  img:sepia()
  lurek.image.savePNG(img, "save/hero_sepia.png")
end

--@api-stub: mlua:invert
-- Invert.
-- Inverts RGB but leaves alpha alone; useful for negative-image effects.
do  -- mlua:invert
  local img = lurek.image.newImageData(64, 64)
  img:invert()
  lurek.image.savePNG(img, "save/hero_inverted.png")
end

--@api-stub: mlua:threshold
-- Threshold.
-- Pixels with luminance >= value become white, others black; useful for masks.
do  -- mlua:threshold
  local img = lurek.image.newImageData(64, 64)
  img:threshold(128)
  lurek.image.savePNG(img, "save/hero_mask.png")
end

--@api-stub: mlua:posterize
-- Posterize.
-- Quantises each channel to N levels; 4 gives a cartoony look, 2 is near-monochrome.
do  -- mlua:posterize
  local img = lurek.image.newImageData(64, 64)
  img:posterize(4)
  lurek.image.savePNG(img, "save/hero_posterized.png")
end

--@api-stub: mlua:fill
-- Fill.
-- Pass (0, 0, 0, 0) to clear to transparent; channels are unsigned bytes.
do  -- mlua:fill
  local img = lurek.image.newImageData(64, 64)
  img:fill(20, 30, 40, 255)
  lurek.image.savePNG(img, "save/solid.png")
end

--@api-stub: mlua:noise
-- Noise.
-- amount is the maximum per-channel deviation; 0 leaves the image untouched.
do  -- mlua:noise
  local img = lurek.image.newImageData(64, 64)
  img:fill(128, 128, 128, 255)
  img:noise(32)
  lurek.image.savePNG(img, "save/noise.png")
end

--@api-stub: mlua:alphaMask
-- Alpha mask.
-- Multiplies every pixel's alpha by factor; 0.0 hides the image, 1.0 is identity.
do  -- mlua:alphaMask
  local img = lurek.image.newImageData(64, 64)
  img:alphaMask(0.5)
  lurek.image.savePNG(img, "save/hero_halfalpha.png")
end

--@api-stub: mlua:flipHorizontal
-- Flip horizontal.
-- Mirrors left/right in place; call twice to restore the original.
do  -- mlua:flipHorizontal
  local img = lurek.image.newImageData(64, 64)
  img:flipHorizontal()
  lurek.image.savePNG(img, "save/hero_flipped.png")
end

--@api-stub: mlua:flipVertical
-- Flip vertical.
-- Mirrors top/bottom in place; useful when import coordinates disagree on Y axis.
do  -- mlua:flipVertical
  local img = lurek.image.newImageData(64, 64)
  img:flipVertical()
  lurek.image.savePNG(img, "save/hero_vflipped.png")
end

--@api-stub: mlua:rotate90cw
-- Rotate90cw.
-- Returns a NEW ImageData rotated 90° clockwise; the original is left untouched.
do  -- mlua:rotate90cw
  local img = lurek.image.newImageData(64, 64)
  local rotated = img:rotate90cw()
  lurek.image.savePNG(rotated, "save/hero_cw.png")
end

--@api-stub: mlua:crop
-- Crop.
-- Returns a NEW ImageData covering the rectangle; nil if the rect is outside the source.
do  -- mlua:crop
  local img = lurek.image.newImageData(64, 64)
  local face = img:crop(8, 4, 32, 32)
  lurek.image.savePNG(face, "save/hero_face.png")
end

--@api-stub: mlua:resizeNearest
-- Resize nearest.
-- Use for pixel art where bilinear would blur; returns a NEW ImageData at the requested size.
do  -- mlua:resizeNearest
  local img = lurek.image.newImageData(64, 64)
  local big = img:resizeNearest(128, 128)
  lurek.image.savePNG(big, "save/hero_2x.png")
end

--@api-stub: mlua:blur
-- Blur.
-- Box blur of given pixel radius; cost scales with radius², keep ≤ 8 for per-frame work.
do  -- mlua:blur
  local img = lurek.image.newImageData(64, 64)
  local soft = img:blur(2)
  lurek.image.savePNG(soft, "save/hero_blurred.png")
end

--@api-stub: mlua:sharpen
-- Sharpen.
-- Returns a NEW ImageData with a fixed 3x3 unsharp kernel applied; safe to call repeatedly.
do  -- mlua:sharpen
  local img = lurek.image.newImageData(64, 64)
  local crisp = img:sharpen()
  lurek.image.savePNG(crisp, "save/hero_sharp.png")
end

--@api-stub: mlua:resize
-- Returns a bilinear-interpolated copy of the image at the given dimensions.
-- Returns nil if either dimension is zero; check before saving the result.
do  -- mlua:resize
  local img = lurek.image.newImageData(64, 64)
  local thumb = img:resize(32, 32)
  if thumb then
    lurek.image.savePNG(thumb, "save/hero_thumb.png")
  end
end

--@api-stub: mlua:diff
-- Returns the sum of absolute per-channel pixel differences with another ImageData.
-- Use as a cheap regression metric for golden-image comparisons; 0 means pixel-perfect.
do  -- mlua:diff
  pcall(function()
    local a = lurek.image.newImageData(64, 64)
    local b = lurek.image.newImageData("save/hero_baseline.png")
    local delta = a:diff(b)
    lurek.log.info("image diff=" .. delta, "test")
  end)
end

--@api-stub: mlua:mapPixels
-- Applies a function to every pixel in-place.
-- Like mapPixel but emphasises bulk transform; the callback signature is identical.
do  -- mlua:mapPixels
  local img = lurek.image.newImageData(32, 32)
  img:fill(100, 100, 100, 255)
  img:mapPixels(function(_, _, r, g, b, a) return r + 50, g, b, a end)
end

--@api-stub: mlua:applyPaletteLut
-- Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
-- Pixels not present in the LUT are left unchanged; build the LUT once and reuse for many sprites.
do  -- mlua:applyPaletteLut
  local img = lurek.image.newImageData(64, 64)
  local lut = lurek.image.newPaletteLut()
  img:applyPaletteLut(lut)
  lurek.image.savePNG(img, "save/hero_recoloured.png")
end

--@api-stub: mlua:setRawData
-- Replaces all pixel data from a raw RGBA byte string.
-- The string length must equal width * height * 4; useful for piping bytes from network or compute.
do  -- mlua:setRawData
  local img = lurek.image.newImageData(2, 2)
  local bytes = string.rep(string.char(255, 0, 0, 255), 4)
  img:setRawData(bytes)
  lurek.image.savePNG(img, "save/red2x2.png")
end

-- ── PaletteLUT methods ──

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of colour mapping entries.
-- Read to size a UI list of remap entries or to detect an empty LUT before applying.
do  -- PaletteLUT:getColorCount
  local lut = lurek.image.newPaletteLut()
  local n = lut:getColorCount()
  if n == 0 then
    lurek.log.info("lut is empty, no remaps configured", "image")
  end
end

--@api-stub: PaletteLUT:clear
-- Removes all colour mapping entries.
-- Call before rebuilding a LUT from a new palette so old entries are not accidentally retained.
do  -- PaletteLUT:clear
  local lut = lurek.image.newPaletteLut()
  lut:clear()
  lurek.log.info("lut reset, count=" .. lut:getColorCount(), "image")
end

--@api-stub: mlua (ImageData):blit
-- Copies pixels from a source ImageData onto this one at the given destination offset.
-- Respects the destination's dimensions; source pixels outside bounds are clipped.
do  -- mlua (ImageData):blit
  local dst = lurek.image.newImageData(64, 64)
  local src = lurek.image.newImageData(16, 16)
  src:fill(1, 0.5, 0, 1)
  dst:blit(src, 24, 24)
  lurek.log.info("blit complete", "image")
end

--@api-stub: mlua (ImageData):convolve
-- Applies a convolution kernel to the image for blur, sharpen, or edge-detect.
-- kernel is a flat table of numbers; size must be sqrt(#kernel) x sqrt(#kernel).
do  -- mlua (ImageData):convolve
  local img = lurek.image.newImageData(32, 32)
  img:fill(1, 1, 1, 1)
  local blur3x3 = {1,2,1,2,4,2,1,2,1}
  img:convolve(blur3x3, 1/16)
  lurek.log.info("convolution done", "image")
end

--@api-stub: mlua (ImageData):drawCircle
-- Draws a filled or outlined circle at (cx, cy) with the given radius and colour.
-- filled=true draws solid fill; false draws outline only at lineWidth pixels.
do  -- mlua (ImageData):drawCircle
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 0, 0, 1)
  img:drawCircle(32, 32, 20, 1, 0.5, 0, 1)
  lurek.log.info("circle drawn", "image")
end

--@api-stub: mlua (ImageData):drawLine
-- Draws an anti-aliased line from (x1,y1) to (x2,y2) with the given RGBA colour.
-- Line width defaults to 1 pixel; thicker lines require Bresenham widening.
do  -- mlua (ImageData):drawLine
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 0, 0, 1)
  img:drawLine(4, 4, 60, 60, 1, 1, 0, 1)
  lurek.log.info("line drawn", "image")
end

--@api-stub: mlua (ImageData):drawRect
-- Draws a filled or outlined rectangle at (x,y) with the given size and colour.
-- filled=true draws solid fill; false draws the outline only.
do  -- mlua (ImageData):drawRect
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 0, 0, 1)
  img:drawRect(10, 10, 40, 30, 0, 1, 0.5, 1)
  lurek.log.info("rect drawn", "image")
end

--@api-stub: mlua (ImageData):getRegion
-- Returns a new ImageData containing a rectangular sub-region of this image.
-- Crop coordinates are (x, y, width, height); raises if out-of-bounds.
do  -- mlua (ImageData):getRegion
  local img = lurek.image.newImageData(64, 64)
  img:fill(1, 0, 0, 1)
  local region = img:getRegion(10, 10, 20, 20)
  if region then
    lurek.log.info("region size: " .. region:getWidth() .. "x" .. region:getHeight(), "image")
  end
end

--@api-stub: LayeredImage:moveLayer
-- Moves a layer from one index to another in the layer stack.
-- Reordering layers changes the composite draw order; index 1 is the bottom.
do  -- LayeredImage:moveLayer
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  li:moveLayer(1, 2)
  lurek.log.info("layer moved", "image")
end

--@api-stub: mlua (ImageData):paste
-- Pastes another ImageData onto this one at (dx, dy) using alpha compositing.
-- Transparent source pixels do not overwrite the destination.
do  -- mlua (ImageData):paste
  local base = lurek.image.newImageData(64, 64)
  local overlay = lurek.image.newImageData(16, 16)
  overlay:fill(0, 0, 1, 0.5)
  base:paste(overlay, 24, 24)
  lurek.log.info("paste complete", "image")
end

--@api-stub: PaletteLUT:setColor
-- Sets a palette remap entry: pixels matching from_r,g,b,a are replaced with to_r,g,b,a.
-- applyPaletteLut() on ImageData uses all registered entries in one GPU pass.
do  -- PaletteLUT:setColor
  local lut = lurek.image.newPaletteLut()
  lut:setColor(1, 0, 0, 1, 0, 1, 0, 1)
  lurek.log.info("lut entries: " .. lut:getColorCount(), "image")
end

--@api-stub: LayeredImage:setLayer
-- Replaces the ImageData for a specific layer index.
-- The replacement must match the layered image dimensions exactly.
do  -- LayeredImage:setLayer
  local li = lurek.image.newLayeredImage(32, 32)
  li:addLayer()
  local newData = lurek.image.newImageData(32, 32)
  newData:fill(0.5, 0.5, 1, 1)
  li:setLayer(1, newData)
  lurek.log.info("layer set", "image")
end

--@api-stub: mlua (ImageData):setPixel
-- Sets the RGBA colour of the pixel at (x, y); coordinates are 0-based.
-- Raises an error if (x,y) is outside the image dimensions.
do  -- mlua (ImageData):setPixel
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(7, 7, 1, 0, 0, 1)
  local r, g, b, a = img:getPixel(7, 7)
  lurek.log.info("pixel r=" .. r, "image")
end

--@api-stub: mlua (ImageData):tint
-- Multiplies every pixel's RGB channels by the given colour, preserving alpha.
-- Use to apply a team colour tint or seasonal palette shift to a sprite sheet.
do  -- mlua (ImageData):tint
  local img = lurek.image.newImageData(32, 32)
  img:fill(1, 1, 1, 1)
  img:tint(1.0, 0.3, 0.3)
  lurek.log.info("tint applied", "image")
end

--@api-stub: mlua:blit
-- Copies pixel data from a source ImageData onto this one at (dx, dy).
-- Pixels that fall outside the destination boundary are clipped.
do  -- mlua:blit
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:blit(src, 16, 16)
  lurek.log.info("blit done", "image")
end

--@api-stub: mlua:convolve
-- Applies a convolution kernel to this ImageData and returns a new ImageData.
-- kernel is a flat table of numbers; rows and cols define the kernel dimensions.
do  -- mlua:convolve
  local img = lurek.image.newImageData(64, 64)
  local blurred = img:convolve({1,2,1, 2,4,2, 1,2,1}, 3)
  lurek.log.info("convolved: " .. blurred:getWidth(), "image")
end

--@api-stub: mlua:drawCircle
-- Draws a filled or outlined circle onto this ImageData at (cx, cy) with radius r.
-- color is an RGBA table; mode is "fill" or "line".
do  -- mlua:drawCircle
  local img = lurek.image.newImageData(128, 128)
  img:drawCircle(64, 64, 30, 1, 0, 0, 1)
  lurek.log.info("circle drawn on ImageData", "image")
end

--@api-stub: mlua:drawLine
-- Draws a line segment onto this ImageData from (x1, y1) to (x2, y2).
-- color is an RGBA table; width controls the line thickness in pixels.
do  -- mlua:drawLine
  local img = lurek.image.newImageData(128, 128)
  img:drawLine(0, 0, 127, 127, 0, 1, 0, 1)
  lurek.log.info("line drawn on ImageData", "image")
end

--@api-stub: mlua:drawRect
-- Draws a filled or outlined rectangle onto this ImageData.
-- color is an RGBA table; mode is "fill" or "line".
do  -- mlua:drawRect
  local img = lurek.image.newImageData(128, 128)
  img:drawRect(10, 10, 60, 40, 0, 0, 1, 1)
  lurek.log.info("rect drawn on ImageData", "image")
end

--@api-stub: mlua:getRegion
-- Returns a new ImageData containing a rectangular sub-region of this image.
-- Region is defined by (x, y, w, h); out-of-bounds areas are filled with zeros.
do  -- mlua:getRegion
  local img = lurek.image.newImageData(128, 128)
  local region = img:getRegion(0, 0, 32, 32)
  if region then
    lurek.log.info("region: " .. region:getWidth() .. "x" .. region:getHeight(), "image")
  end
end

--@api-stub: mlua:paste
-- Pastes a source ImageData onto this one at (dx, dy), blending with alpha.
-- Uses standard alpha compositing (source-over); non-destructive paste.
do  -- mlua:paste
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:paste(src, 16, 16)
  lurek.log.info("paste done", "image")
end

--@api-stub: mlua:setPixel
-- Sets the RGBA colour of a single pixel at (x, y) in this ImageData.
-- Values are in [0, 1]; changes take effect immediately without a flush call.
do  -- mlua:setPixel
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(8, 8, 1.0, 0.0, 0.5, 1.0)
  local r, g, b, a = img:getPixel(8, 8)
  lurek.log.info("pixel r=" .. r, "image")
end

--@api-stub: mlua:tint
-- Multiplies every pixel of this ImageData by the given RGBA tint colour in-place.
-- Use to apply a global colour grade or team-colour shift to a sprite sheet.
do  -- mlua:tint
  local img = lurek.image.newImageData(64, 64)
  img:tint(1.0, 0.8, 0.6, 1.0)
  lurek.log.info("tint applied", "image")
end
