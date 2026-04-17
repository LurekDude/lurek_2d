-- content/examples/image.lua
-- Lurek2D lurek.image API Reference
-- Run with: cargo run -- content/examples/image
--
-- Scenario: A pixel art RPG with a map editor that loads, manipulates, and exports
-- images — applying color grading for day/night, generating province maps,
-- layered character portraits, palette swaps, and screenshot post-processing.

print("=== lurek.image — Image Processing & Manipulation ===\n")

-- =============================================================================
-- Image Data Creation (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.image.newImageData ---------------------------------------
--@api-stub: lurek.image.newImageData
-- Create a blank image buffer for procedural texture generation.
local canvas_img = lurek.image.newImageData(256, 256)
print("blank image data: 256x256 pixels")

-- ---- Stub: lurek.image.loadImage ------------------------------------------
--@api-stub: lurek.image.loadImage
-- Load an image file into an ImageData buffer for pixel manipulation.
local hero_portrait = lurek.image.loadImage("assets/portraits/hero.png")
print("hero portrait loaded for editing")

-- ---- Stub: lurek.image.newCompressedData ----------------------------------
--@api-stub: lurek.image.newCompressedData
-- Load a GPU-compressed texture (DXT/BC/ETC) for memory-efficient storage.
local compressed = lurek.image.newCompressedData("assets/textures/world_atlas.dds")
print("compressed texture loaded: world atlas")

-- ---- Stub: lurek.image.isCompressed ---------------------------------------
--@api-stub: lurek.image.isCompressed
print("world atlas compressed: " .. tostring(lurek.image.isCompressed(compressed)))

-- ---- Stub: lurek.image.newLayeredImage ------------------------------------
--@api-stub: lurek.image.newLayeredImage
-- Layered images for character paper-doll systems or UI compositing.
local portrait_layers = lurek.image.newLayeredImage(128, 128)
print("layered image: 128x128 (character portrait compositor)")

-- ---- Stub: lurek.image.loadLayered ----------------------------------------
--@api-stub: lurek.image.loadLayered
-- Load a multi-layer image file (PSD-like format).
local npc_layers = lurek.image.loadLayered("assets/portraits/npc_layered.png")
print("layered NPC portrait loaded")

-- ---- Stub: lurek.image.newPaletteLut --------------------------------------
--@api-stub: lurek.image.newPaletteLut
-- Create a palette look-up table for color swaps (e.g. faction recoloring).
-- Maps source colors to replacement colors.
local fire_palette = lurek.image.newPaletteLut({
    {0.8, 0.2, 0.1, 1.0},  -- red
    {1.0, 0.5, 0.0, 1.0},  -- orange
    {1.0, 0.9, 0.2, 1.0},  -- yellow
    {0.3, 0.1, 0.0, 1.0},  -- dark red
})
print("fire palette LUT: 4 colors (red/orange/yellow/dark)")

-- ---- Stub: lurek.image.newProvinceGrid ------------------------------------
--@api-stub: lurek.image.newProvinceGrid
-- Create a province grid from a color-coded map image.
-- Each unique color = one province. Used for strategy game maps.
local province_map = lurek.image.newProvinceGrid("assets/maps/provinces.png")
print("province grid loaded from color-coded map")

-- =============================================================================
-- Save / Export (module-level functions)
-- =============================================================================

-- ---- Stub: lurek.image.saveImage ------------------------------------------
--@api-stub: lurek.image.saveImage
-- Save an ImageData to file (format detected from extension).
lurek.image.saveImage(canvas_img, "output/generated_texture.png")
print("image saved: output/generated_texture.png")

-- ---- Stub: lurek.image.savePNG --------------------------------------------
--@api-stub: lurek.image.savePNG
-- Explicit PNG save with compression options.
lurek.image.savePNG(canvas_img, "output/texture_hq.png")
print("PNG saved: output/texture_hq.png")

-- =============================================================================
-- ProvinceGrid Object Methods
-- =============================================================================

-- ---- Stub: ProvinceGrid:getWidth ------------------------------------------
--@api-stub: ProvinceGrid:getWidth
print("province grid width: " .. province_map:getWidth() .. "px")

-- ---- Stub: ProvinceGrid:getHeight -----------------------------------------
--@api-stub: ProvinceGrid:getHeight
print("province grid height: " .. province_map:getHeight() .. "px")

-- ---- Stub: ProvinceGrid:getAt ---------------------------------------------
--@api-stub: ProvinceGrid:getAt
-- Get the province ID at a pixel position (for mouse picking on the world map).
local province_id = province_map:getAt(256, 128)
print("province at (256,128): " .. tostring(province_id))

-- ---- Stub: ProvinceGrid:provinceCount -------------------------------------
--@api-stub: ProvinceGrid:provinceCount
print("total provinces: " .. province_map:provinceCount())

-- ---- Stub: ProvinceGrid:adjacencies ---------------------------------------
--@api-stub: ProvinceGrid:adjacencies
-- Get all provinces adjacent to a given one (for diplomacy/border logic).
local neighbors = province_map:adjacencies(province_id)
print("province " .. tostring(province_id) .. " neighbors: " .. #neighbors)

-- =============================================================================
-- LayeredImage Object Methods — paper-doll compositing
-- =============================================================================

-- ---- Stub: LayeredImage:getWidth ------------------------------------------
--@api-stub: LayeredImage:getWidth
print("layered width: " .. portrait_layers:getWidth())

-- ---- Stub: LayeredImage:getHeight -----------------------------------------
--@api-stub: LayeredImage:getHeight
print("layered height: " .. portrait_layers:getHeight())

-- ---- Stub: LayeredImage:layerCount ----------------------------------------
--@api-stub: LayeredImage:layerCount
print("layers: " .. portrait_layers:layerCount())

-- ---- Stub: LayeredImage:addLayer ------------------------------------------
--@api-stub: LayeredImage:addLayer
-- Add layers for each equipment slot in a character portrait.
portrait_layers:addLayer("base_body", "assets/portraits/layers/body.png")
portrait_layers:addLayer("armor", "assets/portraits/layers/plate_armor.png")
portrait_layers:addLayer("helmet", "assets/portraits/layers/iron_helm.png")
portrait_layers:addLayer("expression", "assets/portraits/layers/smile.png")
print("4 layers added: body, armor, helmet, expression")

-- ---- Stub: LayeredImage:removeLayer ---------------------------------------
--@api-stub: LayeredImage:removeLayer
portrait_layers:removeLayer("helmet")
print("helmet layer removed (player unequipped)")

-- ---- Stub: LayeredImage:getLayer ------------------------------------------
--@api-stub: LayeredImage:getLayer
local armor_layer = portrait_layers:getLayer("armor")
print("armor layer: " .. tostring(armor_layer))

-- ---- Stub: LayeredImage:getOpacity ----------------------------------------
--@api-stub: LayeredImage:getOpacity
print("armor opacity: " .. tostring(portrait_layers:getOpacity("armor")))

-- ---- Stub: LayeredImage:setOpacity ----------------------------------------
--@api-stub: LayeredImage:setOpacity
-- Fade out damaged equipment for a visual "broken" effect.
portrait_layers:setOpacity("armor", 0.5)
print("armor opacity: 0.5 (damaged appearance)")

-- ---- Stub: LayeredImage:isVisible -----------------------------------------
--@api-stub: LayeredImage:isVisible
print("armor visible: " .. tostring(portrait_layers:isVisible("armor")))

-- ---- Stub: LayeredImage:setVisible ----------------------------------------
--@api-stub: LayeredImage:setVisible
-- Toggle helmet visibility from the UI.
portrait_layers:setVisible("expression", true)
print("expression layer visible")

-- ---- Stub: LayeredImage:getName -------------------------------------------
--@api-stub: LayeredImage:getName
print("layer 0 name: " .. portrait_layers:getName(0))

-- ---- Stub: LayeredImage:setName -------------------------------------------
--@api-stub: LayeredImage:setName
portrait_layers:setName(0, "skin_base")
print("layer 0 renamed to: skin_base")

-- ---- Stub: LayeredImage:swapLayers ----------------------------------------
--@api-stub: LayeredImage:swapLayers
-- Reorder layers (put expression on top of armor).
portrait_layers:swapLayers(0, 1)
print("layers 0 and 1 swapped")

-- ---- Stub: LayeredImage:merge ---------------------------------------------
--@api-stub: LayeredImage:merge
-- Flatten all layers into a single ImageData for export or rendering.
local flat = portrait_layers:merge()
print("layers merged to single image")

-- ---- Stub: LayeredImage:save ----------------------------------------------
--@api-stub: LayeredImage:save
portrait_layers:save("output/hero_portrait_final.png")
print("layered portrait saved: output/hero_portrait_final.png")

-- =============================================================================
-- CompressedImageData Object Methods
-- =============================================================================

-- ---- Stub: CompressedImageData:getWidth -----------------------------------
--@api-stub: CompressedImageData:getWidth
print("compressed width: " .. compressed:getWidth())

-- ---- Stub: CompressedImageData:getHeight ----------------------------------
--@api-stub: CompressedImageData:getHeight
print("compressed height: " .. compressed:getHeight())

-- ---- Stub: CompressedImageData:getDimensions ------------------------------
--@api-stub: CompressedImageData:getDimensions
local cw, ch = compressed:getDimensions()
print("compressed: " .. cw .. "x" .. ch)

-- ---- Stub: CompressedImageData:getMipmapCount -----------------------------
--@api-stub: CompressedImageData:getMipmapCount
print("mipmaps: " .. compressed:getMipmapCount())

-- ---- Stub: CompressedImageData:getFormat ----------------------------------
--@api-stub: CompressedImageData:getFormat
print("format: " .. compressed:getFormat())

-- =============================================================================
-- ImageData (mlua class) — pixel-level manipulation
-- =============================================================================

-- ---- Stub: mlua:getWidth --------------------------------------------------
--@api-stub: mlua:getWidth
print("canvas width: " .. canvas_img:getWidth())

-- ---- Stub: mlua:getHeight -------------------------------------------------
--@api-stub: mlua:getHeight
print("canvas height: " .. canvas_img:getHeight())

-- ---- Stub: mlua:getDimensions ---------------------------------------------
--@api-stub: mlua:getDimensions
local iw, ih = canvas_img:getDimensions()
print("canvas dimensions: " .. iw .. "x" .. ih)

-- ---- Stub: mlua:getPixel --------------------------------------------------
--@api-stub: mlua:getPixel
-- Read a pixel's RGBA values (0.0-1.0 range).
local r, g, b, a = canvas_img:getPixel(0, 0)
print("pixel (0,0): r=" .. r .. " g=" .. g .. " b=" .. b .. " a=" .. a)

-- ---- Stub: mlua:fill ------------------------------------------------------
--@api-stub: mlua:fill
-- Fill the entire image with a color for a blank canvas.
canvas_img:fill(0.2, 0.3, 0.5, 1.0)
print("canvas filled with dark blue")

-- ---- Stub: mlua:noise ----------------------------------------------------
--@api-stub: mlua:noise
-- Apply Perlin noise for procedural texture generation.
canvas_img:noise(42, 0.05)
print("Perlin noise applied (seed=42, scale=0.05)")

-- ---- Stub: mlua:mapPixel -------------------------------------------------
--@api-stub: mlua:mapPixel
-- Transform every pixel with a custom function.
-- Example: swap red and blue channels.
canvas_img:mapPixel(function(x, y, r, g, b, a)
    return b, g, r, a  -- swap R <-> B
end)
print("pixel map applied: R/B channel swap")

-- ---- Stub: mlua:encode ---------------------------------------------------
--@api-stub: mlua:encode
-- Encode the image to a format string (e.g. for network transfer).
local encoded = canvas_img:encode("png")
print("image encoded to PNG: " .. #encoded .. " bytes")

-- ---- Stub: mlua:getString -------------------------------------------------
--@api-stub: mlua:getString
local raw_str = canvas_img:getString()
print("raw pixel data: " .. #raw_str .. " bytes")

-- Color adjustments for day/night cycle and mood effects:

-- ---- Stub: mlua:brightness ------------------------------------------------
--@api-stub: mlua:brightness
-- Increase brightness for daytime, decrease for night.
canvas_img:brightness(1.2)
print("brightness +20% (midday sun)")

-- ---- Stub: mlua:contrast --------------------------------------------------
--@api-stub: mlua:contrast
canvas_img:contrast(1.1)
print("contrast +10% (sharper shadows)")

-- ---- Stub: mlua:saturation ------------------------------------------------
--@api-stub: mlua:saturation
-- Desaturate during flashback or ghost-world sequences.
canvas_img:saturation(0.3)
print("saturation 30% (faded memory flashback)")

-- ---- Stub: mlua:gamma -----------------------------------------------------
--@api-stub: mlua:gamma
canvas_img:gamma(1.0)
print("gamma: 1.0 (neutral)")

-- ---- Stub: mlua:grayscale -------------------------------------------------
--@api-stub: mlua:grayscale
-- Full grayscale for death screen or stylistic choice.
canvas_img:grayscale()
print("converted to grayscale")

-- ---- Stub: mlua:sepia -----------------------------------------------------
--@api-stub: mlua:sepia
-- Sepia tone for old-timey flashback sequences.
canvas_img:sepia()
print("sepia tone applied (historical flashback)")

-- ---- Stub: mlua:invert ----------------------------------------------------
--@api-stub: mlua:invert
-- Invert colors for psychedelic or damage effects.
canvas_img:invert()
print("colors inverted (negative image)")

-- ---- Stub: mlua:threshold -------------------------------------------------
--@api-stub: mlua:threshold
-- Convert to black/white at a brightness threshold. Good for stencil masks.
canvas_img:threshold(0.5)
print("threshold at 0.5 (high-contrast mask)")

-- ---- Stub: mlua:posterize -------------------------------------------------
--@api-stub: mlua:posterize
-- Reduce to N color levels for a retro look.
canvas_img:posterize(4)
print("posterized to 4 levels (retro pixel art style)")

-- ---- Stub: mlua:alphaMask -------------------------------------------------
--@api-stub: mlua:alphaMask
-- Apply a grayscale mask image as the alpha channel.
-- White areas become opaque, black becomes transparent.
local mask = lurek.image.newImageData(256, 256)
mask:fill(1.0, 1.0, 1.0, 1.0)
canvas_img:alphaMask(mask)
print("alpha mask applied")

-- Geometric transforms:

-- ---- Stub: mlua:flipHorizontal --------------------------------------------
--@api-stub: mlua:flipHorizontal
canvas_img:flipHorizontal()
print("flipped horizontally (mirror)")

-- ---- Stub: mlua:flipVertical ----------------------------------------------
--@api-stub: mlua:flipVertical
canvas_img:flipVertical()
print("flipped vertically")

-- ---- Stub: mlua:rotate90cw ------------------------------------------------
--@api-stub: mlua:rotate90cw
canvas_img:rotate90cw()
print("rotated 90° clockwise")

-- ---- Stub: mlua:crop ------------------------------------------------------
--@api-stub: mlua:crop
-- Crop to a sub-region (x, y, width, height).
canvas_img:crop(32, 32, 192, 192)
print("cropped to 192x192 from (32,32)")

-- ---- Stub: mlua:resize ---------------------------------------------------
--@api-stub: mlua:resize
-- Resize with bilinear interpolation (smooth scaling).
canvas_img:resize(128, 128)
print("resized to 128x128 (bilinear)")

-- ---- Stub: mlua:resizeNearest ---------------------------------------------
--@api-stub: mlua:resizeNearest
-- Nearest-neighbor resize preserves pixel art crispness.
canvas_img:resizeNearest(64, 64)
print("resized to 64x64 (nearest-neighbor — crisp pixels)")

-- Filters:

-- ---- Stub: mlua:blur ------------------------------------------------------
--@api-stub: mlua:blur
-- Gaussian blur for softening or depth-of-field effect.
canvas_img:blur(3)
print("blurred with radius 3")

-- ---- Stub: mlua:sharpen ---------------------------------------------------
--@api-stub: mlua:sharpen
canvas_img:sharpen(1.5)
print("sharpened (strength 1.5)")

-- Comparison:

-- ---- Stub: mlua:diff ------------------------------------------------------
--@api-stub: mlua:diff
-- Pixel-by-pixel difference between two images (for regression testing).
local diff_img = canvas_img:diff(mask)
print("diff computed (non-zero = pixels that changed)")

-- ---- Stub: mlua:mapPixels -------------------------------------------------
--@api-stub: mlua:mapPixels
-- Alternative pixel mapper (batch version).
canvas_img:mapPixels(function(x, y, r, g, b, a)
    return r * 0.9, g * 0.8, b * 1.1, a
end)
print("mapPixels: cool tint applied (slightly blue)")

-- ---- Stub: mlua:applyPaletteLut -------------------------------------------
--@api-stub: mlua:applyPaletteLut
-- Remap image colors using a palette LUT. Use for faction recoloring.
canvas_img:applyPaletteLut(fire_palette)
print("fire palette LUT applied (faction recolor)")

-- =============================================================================
-- PaletteLUT Object Methods
-- =============================================================================

-- ---- Stub: PaletteLUT:getColorCount ---------------------------------------
--@api-stub: PaletteLUT:getColorCount
print("fire palette colors: " .. fire_palette:getColorCount())

-- ---- Stub: PaletteLUT:clear -----------------------------------------------
--@api-stub: PaletteLUT:clear
fire_palette:clear()
print("palette LUT cleared")

print("\n-- image.lua example complete --")
