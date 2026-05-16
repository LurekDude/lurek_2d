-- content/examples/image.lua
-- lurek.image API examples.
-- Run: cargo run -- content/examples/image.lua

--@api-stub: lurek.image.newImageData
-- Creates empty image data from dimensions or decodes image data from a GameFS filename
do
  local hero = lurek.image.newImageData(64, 64)
  local scratch = lurek.image.newImageData(64, 64)
  scratch:fill(0, 0, 0, 0)
  lurek.log.info("loaded hero " .. hero:getWidth() .. "x" .. hero:getHeight(), "image")
end

--@api-stub: lurek.image.newCompressedData
-- Loads DDS compressed image data from GameFS
do
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local mips = (cd and cd:getMipmapCount() or 0)
  lurek.log.info("dds " .. (cd and cd:getFormat() or "unknown") .. " mips=" .. mips, "image")
end

--@api-stub: lurek.image.isCompressed
-- Returns whether a GameFS image file begins with DDS compressed image magic bytes
do
  local path = "assets/terrain_bc1.dds"
  local _ok_ic, _is_c = pcall(lurek.image.isCompressed, path)
  if _ok_ic and _is_c then
    pcall(lurek.image.newCompressedData, path)
  else
    lurek.image.newImageData(64, 64)
  end
end

--@api-stub: lurek.image.newLayeredImage
-- Creates a layered image stack with one or more blank layers
do
  local doc = lurek.image.newLayeredImage(256, 256)
  local bg = doc:addLayer("background")
  local fg = doc:addLayer("foreground")
  lurek.log.info("layers bg=" .. bg .. " fg=" .. fg, "image")
end

--@api-stub: lurek.image.saveImage
-- Saves an image data object to a path under the current game directory
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(255, 128, 0, 255)
  lurek.image.saveImage(img, "save/orange64.limg")
end

--@api-stub: lurek.image.savePNG
-- Encodes image data as PNG and writes it under the current game directory
do
  local shot = lurek.image.newImageData(128, 64)
  shot:fill(20, 30, 40, 255)
  shot:drawCircle(64, 32, 24, 255, 200, 0, 255)
  lurek.image.savePNG(shot, "save/screenshot.png")
end

--@api-stub: LImageData:drawNineSlice
-- Draws a nine-slice region from a source image into this image
do
  local atlas = lurek.image.newImageData(32, 32)
  atlas:fill(255, 255, 255, 255)

  local out = lurek.image.newImageData(96, 64)
  out:fill(0, 0, 0, 0)
  out:drawNineSlice(atlas, 0, 0, 32, 32, 4, 4, 88, 56, 8, 8, 8, 8)
end

--@api-stub: lurek.image.loadImage
-- Loads and decodes image data from GameFS
do
  local restored = lurek.image.loadImage("save/orange64.limg")
  local w, h = restored:getDimensions()
  lurek.log.info("restored " .. w .. "x" .. h, "image")
end

--@api-stub: lurek.image.loadLayered
-- Loads a serialized layered image stack from GameFS
do
  pcall(function()
    local doc = lurek.image.loadLayered("save/painting.limg")
    local count = doc:layerCount()
    lurek.log.info("painting reopened with " .. count .. " layers", "image")
  end)
end

--@api-stub: lurek.image.newPaletteLut
-- Creates an empty palette lookup table
do
  local lut = lurek.image.newPaletteLut()
  local before = lut:getColorCount()
  lurek.log.info("new lut entries=" .. before, "image")
end

--@api-stub: lurek.image.newProvinceGrid
-- Loads a province id grid from an image file under the current game directory
do
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  lurek.log.info("loaded " .. count .. " provinces", "map")
end

-- ProvinceGrid methods

--@api-stub: ProvinceGrid:getWidth
-- Returns the width of this province grid.
do
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
-- Returns the at of this province grid.
do
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local id = (grid and grid:getAt(128, 96) or 0)
  if id ~= 0 then
    lurek.log.info("clicked province " .. id, "map")
  end
end

--@api-stub: ProvinceGrid:provinceCount
-- Performs the province count operation on this province grid.
do
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local count = (grid and grid:provinceCount() or 0)
  local owners = {}
  for i = 1, count do owners[i] = 0 end
  lurek.log.info("allocated owner table for " .. count .. " provinces", "map")
end

--@api-stub: ProvinceGrid:adjacencies
-- Performs the adjacencies operation on this province grid.
do
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  local edges = (grid and grid:adjacencies() or {})
  lurek.log.info("adjacency edges=" .. #edges, "map")
end

--@api-stub: ProvinceGrid:getPolygons
-- Returns the polygons of this province grid.
do
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
-- Returns the polygons simplified of this province grid.
do
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
  local ok_grid, grid = pcall(lurek.image.newProvinceGrid, "assets/world_provinces.png")
  if not ok_grid then return end
  pcall(function()
    grid:drawShapes(0, 0, 1.0)
  end)
end

-- LayeredImage methods

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
-- Performs the layer count operation on this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  doc:addLayer("ink")
  lurek.log.info("layer count=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:addLayer
-- Adds a layer to this layered image.
do
  local doc = lurek.image.newLayeredImage(128, 128)
  local idx = doc:addLayer("highlights")
  doc:setOpacity(idx, 0.75)
  lurek.log.info("added layer at index " .. idx, "paint")
end

--@api-stub: LayeredImage:removeLayer
-- Removes a layer from this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("scratch")
  doc:removeLayer(1)
  lurek.log.info("layers after remove=" .. doc:layerCount(), "paint")
end

--@api-stub: LayeredImage:getLayer
-- Returns the layer of this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local snap = doc:getLayer(1)
  lurek.image.savePNG(snap, "save/layer1.png")
end

--@api-stub: LayeredImage:getOpacity
-- Returns the opacity of this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  local a = doc:getOpacity(1)
  lurek.log.info("layer 1 opacity=" .. a, "paint")
end

--@api-stub: LayeredImage:setOpacity
-- Sets the opacity of this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("shadow")
  doc:setOpacity(idx, 0.5)
end

--@api-stub: LayeredImage:isVisible
-- Returns true if this layered image is currently visible.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("ink")
  if doc:isVisible(1) then
    lurek.log.info("layer 1 is visible", "paint")
  end
end

--@api-stub: LayeredImage:setVisible
-- Sets the visibility flag for this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("guides")
  doc:setVisible(idx, false)
end

--@api-stub: LayeredImage:getName
-- Returns the name of this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("background")
  local name = doc:getName(1)
  lurek.log.info("layer 1 name='" .. name .. "'", "paint")
end

--@api-stub: LayeredImage:setName
-- Sets the name of this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  local idx = doc:addLayer("untitled")
  doc:setName(idx, "background")
end

--@api-stub: LayeredImage:swapLayers
-- Performs the swap layers operation on this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("a")
  doc:addLayer("b")
  doc:swapLayers(1, 2)
end

--@api-stub: LayeredImage:merge
-- Performs the merge operation on this layered image.
do
  local doc = lurek.image.newLayeredImage(64, 64)
  doc:addLayer("base")
  local flat = doc:merge()
  lurek.image.savePNG(flat, "save/flattened.png")
end

--@api-stub: LayeredImage:save
-- Saves the current state of this layered image.
do
  local doc = lurek.image.newLayeredImage(128, 128)
  doc:addLayer("background")
  doc:save("save/painting.limg")
end

-- CompressedImageData methods

--@api-stub: CompressedImageData:getWidth
-- Returns the width of this compressed image data.
do
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
  local ok_cd, cd = pcall(lurek.image.newCompressedData, "assets/terrain_bc1.dds")
  if not ok_cd then return end
  local fmt = (cd and cd:getFormat() or "unknown")
  lurek.log.info("dds format=" .. fmt, "image")
end

-- ImageData methods

--@api-stub: mlua:getWidth
-- Returns the width of this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local w = img:getWidth()
  lurek.log.info("hero width=" .. w, "image")
end

--@api-stub: mlua:getHeight
-- Returns the height of this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local h = img:getHeight()
  lurek.log.info("hero height=" .. h, "image")
end

--@api-stub: mlua:getDimensions
-- Returns the dimensions of this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local w, h = img:getDimensions()
  lurek.log.info("hero " .. w .. "x" .. h, "image")
end

--@api-stub: mlua:getPixel
-- Returns the pixel of this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("top-left rgba=" .. r .. "," .. g .. "," .. b .. "," .. a, "image")
end

--@api-stub: mlua:encode
-- Performs the encode operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(0, 200, 100, 255)
  local png_bytes = img:encode("png")
  lurek.log.info("png byte length=" .. #png_bytes, "image")
end

--@api-stub: LImageData:getString
-- Returns the string of this mlua.
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)
  local raw = img:getString()
  lurek.log.info("raw bytes=" .. #raw, "image")
end

--@api-stub: mlua:mapPixel
-- Performs the map pixel operation on this mlua.
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(64, 64, 64, 255)
  img:mapPixel(function(_, _, r, g, b, a) return 255 - r, 255 - g, 255 - b, a end)
end

--@api-stub: mlua:brightness
-- Performs the brightness operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:brightness(1.2)
  lurek.image.savePNG(img, "save/hero_brighter.png")
end

--@api-stub: mlua:contrast
-- Performs the contrast operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:contrast(1.4)
  lurek.image.savePNG(img, "save/hero_contrast.png")
end

--@api-stub: mlua:saturation
-- Performs the saturation operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:saturation(0.0)
  lurek.image.savePNG(img, "save/hero_desaturated.png")
end

--@api-stub: mlua:gamma
-- Performs the gamma operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:gamma(2.2)
  lurek.image.savePNG(img, "save/hero_gamma.png")
end

--@api-stub: mlua:grayscale
-- Performs the grayscale operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:grayscale()
  lurek.image.savePNG(img, "save/hero_gray.png")
end

--@api-stub: mlua:sepia
-- Performs the sepia operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:sepia()
  lurek.image.savePNG(img, "save/hero_sepia.png")
end

--@api-stub: mlua:invert
-- Performs the invert operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:invert()
  lurek.image.savePNG(img, "save/hero_inverted.png")
end

--@api-stub: mlua:threshold
-- Performs the threshold operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:threshold(128)
  lurek.image.savePNG(img, "save/hero_mask.png")
end

--@api-stub: mlua:posterize
-- Performs the posterize operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:posterize(4)
  lurek.image.savePNG(img, "save/hero_posterized.png")
end

--@api-stub: mlua:fill
-- Performs the fill operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(20, 30, 40, 255)
  lurek.image.savePNG(img, "save/solid.png")
end

--@api-stub: mlua:noise
-- Performs the noise operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(128, 128, 128, 255)
  img:noise(32)
  lurek.image.savePNG(img, "save/noise.png")
end

--@api-stub: mlua:alphaMask
-- Performs the alpha mask operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:alphaMask(0.5)
  lurek.image.savePNG(img, "save/hero_halfalpha.png")
end

--@api-stub: mlua:flipHorizontal
-- Performs the flip horizontal operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:flipHorizontal()
  lurek.image.savePNG(img, "save/hero_flipped.png")
end

--@api-stub: mlua:flipVertical
-- Performs the flip vertical operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:flipVertical()
  lurek.image.savePNG(img, "save/hero_vflipped.png")
end

--@api-stub: mlua:rotate90cw
-- Performs the rotate90cw operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local rotated = img:rotate90cw()
  lurek.image.savePNG(rotated, "save/hero_cw.png")
end

--@api-stub: mlua:crop
-- Performs the crop operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local face = img:crop(8, 4, 32, 32)
  lurek.image.savePNG(face, "save/hero_face.png")
end

--@api-stub: mlua:resizeNearest
-- Performs the resize nearest operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local big = img:resizeNearest(128, 128)
  lurek.image.savePNG(big, "save/hero_2x.png")
end

--@api-stub: mlua:blur
-- Performs the blur operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local soft = img:blur(2)
  lurek.image.savePNG(soft, "save/hero_blurred.png")
end

--@api-stub: mlua:sharpen
-- Performs the sharpen operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local crisp = img:sharpen()
  lurek.image.savePNG(crisp, "save/hero_sharp.png")
end

--@api-stub: mlua:resize
-- Performs the resize operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local thumb = img:resize(32, 32)
  if thumb then
    lurek.image.savePNG(thumb, "save/hero_thumb.png")
  end
end

--@api-stub: mlua:diff
-- Performs the diff operation on this mlua.
do
  pcall(function()
    local a = lurek.image.newImageData(64, 64)
    local b = lurek.image.newImageData("save/hero_baseline.png")
    local delta = a:diff(b)
    lurek.log.info("image diff=" .. delta, "test")
  end)
end

--@api-stub: mlua:mapPixels
-- Performs the map pixels operation on this mlua.
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(100, 100, 100, 255)
  img:mapPixels(function(_, _, r, g, b, a) return r + 50, g, b, a end)
end

--@api-stub: mlua:applyPaletteLut
-- Applies palette lut to this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local lut = lurek.image.newPaletteLut()
  img:applyPaletteLut(lut)
  lurek.image.savePNG(img, "save/hero_recoloured.png")
end

--@api-stub: mlua:setRawData
-- Sets the raw data of this mlua.
do
  local img = lurek.image.newImageData(2, 2)
  local bytes = string.rep(string.char(255, 0, 0, 255), 4)
  img:setRawData(bytes)
  lurek.image.savePNG(img, "save/red2x2.png")
end

-- PaletteLUT methods

--@api-stub: PaletteLUT:getColorCount
-- Returns the number of color items in this palette lut.
do
  local lut = lurek.image.newPaletteLut()
  local n = lut:getColorCount()
  if n == 0 then
    lurek.log.info("lut is empty, no remaps configured", "image")
  end
end

--@api-stub: PaletteLUT:clear
-- Clears all items from this palette lut.
do
  local lut = lurek.image.newPaletteLut()
  lut:clear()
  lurek.log.info("lut reset, count=" .. lut:getColorCount(), "image")
end

--@api-stub: PaletteLUT:cycle
-- Performs the cycle operation on this palette lut.
do
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)
  lut:setColor(0, 255, 0, 255, 0, 0, 255, 255)
  lut:cycle(1)
end

--@api-stub: LImageData:type
-- Performs the mlua operation on this .
do
  local dst = lurek.image.newImageData(64, 64)
  local src = lurek.image.newImageData(16, 16)
  src:fill(1, 0.5, 0, 1)
  dst:blit(src, 24, 24)
  lurek.log.info("blit complete", "image")
end

end

--@api-stub: LayeredImage:moveLayer
-- Performs the move layer operation on this layered image.
do
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  li:moveLayer(1, 2)
  lurek.log.info("layer moved", "image")
end

--@api-stub: PaletteLUT:setColor
-- Sets the color of this palette lut.
do
  local lut = lurek.image.newPaletteLut()
  lut:setColor(1, 0, 0, 1, 0, 1, 0, 1)
  lurek.log.info("lut entries: " .. lut:getColorCount(), "image")
end

--@api-stub: LayeredImage:setLayer
-- Sets the layer of this layered image.
do
  local li = lurek.image.newLayeredImage(32, 32)
  li:addLayer()
  local newData = lurek.image.newImageData(32, 32)
  newData:fill(0.5, 0.5, 1, 1)
  li:setLayer(1, newData)
  lurek.log.info("layer set", "image")
end

--@api-stub: mlua:blit
-- Performs the blit operation on this mlua.
do
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:blit(src, 16, 16)
  lurek.log.info("blit done", "image")
end

--@api-stub: mlua:convolve
-- Performs the convolve operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  local blurred = img:convolve({1,2,1, 2,4,2, 1,2,1}, 3)
  lurek.log.info("convolved: " .. blurred:getWidth(), "image")
end

--@api-stub: mlua:drawCircle
-- Draws or renders this mlua to the current render target.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawCircle(64, 64, 30, 1, 0, 0, 1)
  lurek.log.info("circle drawn on ImageData", "image")
end

--@api-stub: mlua:drawLine
-- Draws or renders this mlua to the current render target.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawLine(0, 0, 127, 127, 0, 1, 0, 1)
  lurek.log.info("line drawn on ImageData", "image")
end

--@api-stub: mlua:drawRect
-- Draws or renders this mlua to the current render target.
do
  local img = lurek.image.newImageData(128, 128)
  img:drawRect(10, 10, 60, 40, 0, 0, 1, 1)
  lurek.log.info("rect drawn on ImageData", "image")
end

--@api-stub: mlua:getRegion
-- Returns the region of this mlua.
do
  local img = lurek.image.newImageData(128, 128)
  local region = img:getRegion(0, 0, 32, 32)
  if region then
    lurek.log.info("region: " .. region:getWidth() .. "x" .. region:getHeight(), "image")
  end
end

--@api-stub: mlua:paste
-- Performs the paste operation on this mlua.
do
  local src = lurek.image.newImageData(32, 32)
  local dst = lurek.image.newImageData(64, 64)
  dst:paste(src, 16, 16)
  lurek.log.info("paste done", "image")
end

--@api-stub: mlua:setPixel
-- Sets the pixel of this mlua.
do
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(8, 8, 1.0, 0.0, 0.5, 1.0)
  local r, g, b, a = img:getPixel(8, 8)
  lurek.log.info("pixel r=" .. r, "image")
end

--@api-stub: mlua:tint
-- Performs the tint operation on this mlua.
do
  local img = lurek.image.newImageData(64, 64)
  img:tint(1.0, 0.8, 0.6, 1.0)
  lurek.log.info("tint applied", "image")
end

end

end

-- -----------------------------------------------------------------------------
-- ImageData methods
-- -----------------------------------------------------------------------------

--@api-stub: ImageData:type
-- Returns the Lua-visible type name string for this image data handle.
do
  local img = lurek.image.newImageData(8, 8)
  assert(img:type() == "ImageData")
end

--@api-stub: ImageData:typeOf
-- Returns true if this image data handle matches the given type name string.
do
  local img = lurek.image.newImageData(8, 8)
  assert(img:typeOf("ImageData") == true)
end

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
--@api-stub: LImageData:getWidth
-- Returns the width of this image data in pixels
do
  local img = lurek.image.newImageData(64, 32)
  lurek.log.info("width=" .. img:getWidth(), "image")
end
--@api-stub: LImageData:getHeight
-- Returns the height of this image data in pixels
do
  local img = lurek.image.newImageData(64, 32)
  lurek.log.info("height=" .. img:getHeight(), "image")
end
--@api-stub: LImageData:getDimensions
-- Returns image dimensions
do
  local img = lurek.image.newImageData(128, 64)
  local w, h = img:getDimensions()
  lurek.log.info("dimensions=" .. w .. "x" .. h, "image")
end
--@api-stub: LImageData:getPixel
-- Returns RGBA channels at a pixel coordinate
do
  local img = lurek.image.newImageData(8, 8)
  img:setPixel(2, 3, 255, 128, 0, 255)   -- set orange pixel
  local r, g, b, a = img:getPixel(2, 3)
  lurek.log.info("pixel(2,3)=" .. r .. "," .. g .. "," .. b .. "," .. a, "image")
end
--@api-stub: LImageData:setPixel
-- Sets RGBA channels at a pixel coordinate
do
  local img = lurek.image.newImageData(16, 16)
  img:setPixel(0, 0, 255, 0, 0, 255)   -- red at top-left
  img:setPixel(7, 7, 0, 255, 0, 255)   -- green at center
  local r, g, b = img:getPixel(7, 7)
  lurek.log.info("center r=" .. r .. " g=" .. g, "image")
end
--@api-stub: LImageData:encode
-- Encodes image data in a supported format
do
  local img = lurek.image.newImageData(16, 16)
  img:fill(200, 100, 50, 255)
  local bytes = img:encode("png")
  lurek.log.info("encoded size=" .. #bytes .. " bytes", "image")
end
--@api-stub: LImageData:mapPixel
-- Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 150, 200, 255)
  img:mapPixel(function(x, y, r, g, b, a)
    return b, g, r, a   -- swap R and B (blue shift)
  end)
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("after mapPixel r=" .. r .. " b=" .. b, "image")
end
--@api-stub: LImageData:brightness
-- Applies a brightness factor to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:brightness(0.5)   -- darken by half
  local r = img:getPixel(0, 0)
  lurek.log.info("r after darken=" .. r, "image")
end
--@api-stub: LImageData:contrast
-- Applies a contrast factor to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(128, 128, 128, 255)
  img:contrast(2.0)   -- high contrast
  local r = img:getPixel(0, 0)
  lurek.log.info("r after contrast=" .. r, "image")
end
--@api-stub: LImageData:saturation
-- Applies a saturation factor to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 100, 50, 255)
  img:saturation(0.0)   -- full desaturate
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:gamma
-- Applies gamma correction to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 100, 100, 255)
  img:gamma(2.2)   -- apply sRGB gamma
  local r = img:getPixel(0, 0)
  lurek.log.info("r after gamma=" .. r, "image")
end
--@api-stub: LImageData:tint
-- Blends this image toward a tint color in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:tint(255, 0, 0, 0.5)   -- 50% red tint
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:grayscale
-- Converts this image to grayscale in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 128, 64, 255)
  img:grayscale()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("gray r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:sepia
-- Applies a sepia filter to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 180, 160, 255)
  img:sepia()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("sepia r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:invert
-- Inverts image color channels in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(100, 150, 200, 255)
  img:invert()
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("inverted r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:threshold
-- Applies a threshold filter to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 200, 200, 255)
  img:threshold(128)   -- pixels > 128 â†’ white
  local r = img:getPixel(0, 0)
  lurek.log.info("thresholded r=" .. r, "image")
end
--@api-stub: LImageData:posterize
-- Reduces image colors to a fixed number of levels in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(180, 120, 60, 255)
  img:posterize(3)   -- 3 levels per channel
  local r, g, b = img:getPixel(0, 0)
  lurek.log.info("posterised r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:fill
-- Fills the whole image with one RGBA color
do
  local img = lurek.image.newImageData(16, 16)
  img:fill(64, 128, 192, 255)   -- fill solid blue-grey
  local r, g, b, a = img:getPixel(8, 8)
  lurek.log.info("fill r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:noise
-- Adds noise to this image in place
do
  local img = lurek.image.newImageData(16, 16)
  img:fill(128, 128, 128, 255)
  img:noise(20)   -- Â±20 per channel
  lurek.log.info("noise applied to 16x16 image", "image")
end
--@api-stub: LImageData:alphaMask
-- Multiplies this image alpha channel by a factor in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 255, 255, 255)
  img:alphaMask(0.5)   -- 50% transparent
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("alpha after mask=" .. a, "image")
end
--@api-stub: LImageData:flipHorizontal
-- Flips this image horizontally in place
do
  local img = lurek.image.newImageData(4, 4)
  img:setPixel(0, 0, 255, 0, 0, 255)   -- red at top-left
  img:flipHorizontal()
  local r = img:getPixel(3, 0)   -- now at top-right
  lurek.log.info("flipped: r at (3,0)=" .. r, "image")
end
--@api-stub: LImageData:flipVertical
-- Flips this image vertically in place
do
  local img = lurek.image.newImageData(4, 4)
  img:setPixel(0, 0, 0, 255, 0, 255)   -- green at top-left
  img:flipVertical()
  local r, g = img:getPixel(0, 3)   -- now at bottom-left
  lurek.log.info("flipped: g at (0,3)=" .. g, "image")
end
--@api-stub: LImageData:rotate90cw
-- Returns a new image rotated ninety degrees clockwise
do
  local img = lurek.image.newImageData(4, 8)   -- 4Ă—8 original
  local rot = img:rotate90cw()               -- becomes 8Ă—4
  lurek.log.info("rotated w=" .. rot:getWidth() .. " h=" .. rot:getHeight(), "image")
end
--@api-stub: LImageData:crop
-- Returns a cropped image region
do
  local sheet = lurek.image.newImageData(64, 64)
  sheet:fill(80, 160, 240, 255)
  local sprite = sheet:crop(0, 0, 16, 16)
  lurek.log.info("sprite w=" .. sprite:getWidth() .. " h=" .. sprite:getHeight(), "image")
end
--@api-stub: LImageData:resizeNearest
-- Returns a resized image using nearest-neighbor sampling
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(200, 50, 100, 255)
  local big = img:resizeNearest(64, 64)   -- 8Ă— upscale
  lurek.log.info("scaled w=" .. big:getWidth() .. " h=" .. big:getHeight(), "image")
end
--@api-stub: LImageData:blur
-- Returns a blurred copy of this image
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(255, 255, 255, 255)
  img:setPixel(16, 16, 0, 0, 0, 255)   -- single black pixel
  local blurred = img:blur(2)
  lurek.log.info("blurred w=" .. blurred:getWidth(), "image")
end
--@api-stub: LImageData:sharpen
-- Returns a sharpened copy of this image
do
  local img = lurek.image.newImageData(16, 16)
  img:fill(180, 180, 180, 255)
  local sharp = img:sharpen()
  lurek.log.info("sharpened w=" .. sharp:getWidth(), "image")
end
--@api-stub: LImageData:drawRect
-- Draws a filled rectangle into this image
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawRect(4, 4, 24, 12, 255, 100, 0, 255)   -- orange bar
  local r, g, b = img:getPixel(10, 8)
  lurek.log.info("bar pixel r=" .. r .. " g=" .. g, "image")
end
--@api-stub: LImageData:drawCircle
-- Draws a filled circle into this image
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawCircle(16, 16, 10, 255, 255, 0, 255)   -- yellow circle
  local r, g = img:getPixel(16, 16)
  lurek.log.info("center r=" .. r .. " g=" .. g, "image")
end
--@api-stub: LImageData:drawLine
-- Draws a line into this image
do
  local img = lurek.image.newImageData(32, 32)
  img:fill(0, 0, 0, 255)
  img:drawLine(0, 0, 31, 31, 255, 255, 255, 255)   -- white diagonal
  local r = img:getPixel(15, 15)
  lurek.log.info("line pixel r=" .. r, "image")
end
--@api-stub: LImageData:resize
-- Creates a new ImageData resized to the given dimensions using bilinear sampling
do
  local img = lurek.image.newImageData(64, 64)
  img:fill(100, 200, 50, 255)
  local small = img:resize(8, 8)
  lurek.log.info("resized w=" .. small:getWidth() .. " h=" .. small:getHeight(), "image")
end
--@api-stub: LImageData:blit
-- Copies pixel data from another ImageData onto this one at the specified position
do
  local base = lurek.image.newImageData(32, 32)
  base:fill(0, 0, 128, 255)
  local overlay = lurek.image.newImageData(8, 8)
  overlay:fill(255, 255, 0, 200)
  base:blit(overlay, 12, 12)   -- paste yellow patch at (12,12)
  local r, g, b = base:getPixel(14, 14)
  lurek.log.info("blit pixel g=" .. g, "image")
end
--@api-stub: LImageData:getRegion
-- Extracts a rectangular sub-region as a new ImageData
do
  local img = lurek.image.newImageData(64, 64)
  img:drawRect(10, 10, 20, 20, 255, 0, 0, 255)
  local region = img:getRegion(10, 10, 20, 20)
  lurek.log.info("region w=" .. region:getWidth() .. " h=" .. region:getHeight(), "image")
end
--@api-stub: LImageData:diff
-- Computes a numeric difference score between this image and another of the same size
do
  local a = lurek.image.newImageData(8, 8)
  local b = lurek.image.newImageData(8, 8)
  a:fill(200, 200, 200, 255)
  b:fill(100, 100, 100, 255)
  local d = a:diff(b)
  lurek.log.info("pixel diff=" .. tostring(d), "image")
end
--@api-stub: LImageData:mapPixels
-- Iterates over every pixel and replaces its color with the return value of the callback
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)
  img:mapPixels(function(x, y, r, g, b, a)
    return g, r, b, a   -- swap R and G
  end)
  local r, g = img:getPixel(0, 0)
  lurek.log.info("after map: r=" .. r .. " g=" .. g, "image")
end
--@api-stub: LImageData:convolve
-- Applies a convolution kernel and returns the filtered image
do
  local img = lurek.image.newImageData(16, 16)
  img:fill(180, 180, 180, 255)
  local kernel = {0, -1, 0, -1, 5, -1, 0, -1, 0}   -- sharpen kernel
  local result = img:convolve(kernel, 3)
  lurek.log.info("convolved w=" .. result:getWidth(), "image")
end
--@api-stub: LImageData:applyPaletteLut
-- Applies a palette lookup table to this image in place
do
  local img = lurek.image.newImageData(8, 8)
  img:fill(255, 0, 0, 255)   -- red
  local lut = lurek.image.newPaletteLut()
  lut:setColor(255, 0, 0, 255, 0, 255, 0, 255)   -- red â†’ green
  img:applyPaletteLut(lut)
  local r, g = img:getPixel(0, 0)
  lurek.log.info("after lut r=" .. r .. " g=" .. g, "image")
end
--@api-stub: LImageData:setRawData
-- Replaces the image byte buffer with raw bytes
do
  local img = lurek.image.newImageData(2, 2)
  -- 4 pixels Ă— 4 bytes (RGBA), all red
  local raw = string.rep("Ăż  Ăż", 4)
  img:setRawData(raw)
  local r, g, b, a = img:getPixel(0, 0)
  lurek.log.info("raw r=" .. r .. " g=" .. g .. " b=" .. b, "image")
end
--@api-stub: LImageData:paste
-- Pastes a source image into this image at unsigned destination coordinates
do
  local canvas = lurek.image.newImageData(32, 32)
  canvas:fill(30, 30, 60, 255)
  local icon = lurek.image.newImageData(8, 8)
  icon:fill(255, 200, 0, 255)
  canvas:paste(icon, 4, 4)
  local r, g = canvas:getPixel(6, 6)
  lurek.log.info("icon pixel r=" .. r .. " g=" .. g, "image")
end
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
  local li = lurek.image.newLayeredImage(64, 64)
  local idx = li:addLayer()
  lurek.log.info("added layer idx=" .. idx .. " total=" .. li:layerCount(), "image")
end
--@api-stub: LLayeredImage:removeLayer
-- Removes a layer by one-based index
do
  local li = lurek.image.newLayeredImage(64, 64)
  li:addLayer()
  li:addLayer()
  local ok = li:removeLayer(1)
  lurek.log.info("removed=" .. tostring(ok) .. " remaining=" .. li:layerCount(), "image")
end
--@api-stub: LLayeredImage:getLayer
-- Returns image data for a layer by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  local layer = li:getLayer(idx)
  lurek.log.info("layer w=" .. layer:getWidth(), "image")
end
--@api-stub: LLayeredImage:setLayer
-- Replaces a layer's image data by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  local src = lurek.image.newImageData(32, 32)
  src:fill(100, 200, 50, 255)
  li:setLayer(idx, src)
  local out = li:getLayer(idx)
  local r, g = out:getPixel(0, 0)
  lurek.log.info("layer g=" .. g, "image")
end
--@api-stub: LLayeredImage:getOpacity
-- Returns a layer opacity by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setOpacity(idx, 0.75)
  lurek.log.info("opacity=" .. li:getOpacity(idx), "image")
end
--@api-stub: LLayeredImage:setOpacity
-- Sets a layer opacity by one-based index
do
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setOpacity(idx, 0.5)
  lurek.log.info("opacity=" .. li:getOpacity(idx), "image")
end
--@api-stub: LLayeredImage:isVisible
-- Returns layer visibility by one-based index
do
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
  li:setVisible(idx, false)
  lurek.log.info("hidden: " .. tostring(not li:isVisible(idx)), "image")
  li:setVisible(idx, true)
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
  local li = lurek.image.newLayeredImage(32, 32)
  local idx = li:addLayer()
  li:setName(idx, "helmet")
  lurek.log.info("name=" .. li:getName(idx), "image")
end
--@api-stub: LLayeredImage:swapLayers
-- Swaps two layers by one-based indices
do
  local li = lurek.image.newLayeredImage(32, 32)
  li:addLayer(); li:addLayer()
  li:setName(1, "layer_a"); li:setName(2, "layer_b")
  li:swapLayers(1, 2)
  lurek.log.info("after swap: idx1=" .. li:getName(1), "image")
end
--@api-stub: LLayeredImage:moveLayer
-- Moves a layer from one one-based index to another
do
  local li = lurek.image.newLayeredImage(32, 32)
  for i = 1, 3 do li:addLayer(); li:setName(i, "layer_" .. i) end
  li:moveLayer(3, 1)   -- bring layer 3 to the front
  lurek.log.info("front layer=" .. li:getName(1), "image")
end
--@api-stub: LLayeredImage:merge
-- Merges visible layers into a single image data object
do
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

--@api-stub: lurek.image.newImageDataFromBytes
-- Creates image data from raw RGBA bytes and explicit dimensions
do
  local pixels = string.rep(string.char(0, 128, 255, 255), 16) -- 4x4 blue RGBA8
  local img = lurek.image.newImageDataFromBytes(4, 4, pixels)
  lurek.log.info("fromBytes " .. img:getWidth() .. "x" .. img:getHeight(), "image")
end

-- Creates an ImageData from a raw RGBA8 byte string. Width Ă— height Ă— 4 bytes required.
-- lurek.image.newImageDataFromBytes(64.0, 64.0, bytes)  -- -> ImageData

-- -----------------------------------------------------------------------------
-- LImageData methods
-- -----------------------------------------------------------------------------

-- Build an image from raw RGBA bytes, read bytes back, and resize with explicit lanczos3 filter.
--@api-stub: raw
-- Performs the raw operation on this .
do
  local bytes = string.rep(string.char(255, 0, 0, 255), 4) -- 2x2 red RGBA8
  local img = lurek.image.newImageDataFromBytes(2, 2, bytes)
  local raw = img:getRawBytes()
  local out = img:resize(4, 4, "lanczos3")
  lurek.log.info("raw=" .. #raw .. " out=" .. out:getWidth() .. "x" .. out:getHeight(), "image")
end

--@api-stub: lurek.image.fromScreen
-- Returns a completed screen capture image or requests one for a future call
do
  local first = lurek.image.fromScreen()
  if first == nil then
    local later = lurek.image.fromScreen()
    if later then
      lurek.image.savePNG(later, "save/screen_capture.png")
    end
  end
end

-- -----------------------------------------------------------------------------
-- LProvinceGrid methods
-- -----------------------------------------------------------------------------

--@api-stub: ProvinceGrid
-- Performs the province grid operation on this .
do
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

--@api-stub: LImageData:getRawBytes
-- Returns the raw pixel byte string of this image data without any format conversion.
do
  local img = lurek.image.newImageData(4, 4)
  local bytes = img:getRawBytes()
  lurek.log.debug("raw bytes=" .. #bytes, "image")
end
