-- content/examples/image.lua
-- Lurek2D lurek.image API Reference
-- Run with: cargo run -- content/examples/image
--
Scenario: A pixel art RPG with a map editor that loads, manipulates, and exports
-- images — applying color grading for day/night, generating province maps,
-- layered character portraits, palette swaps, and screenshot post-processing.

print("=== lurek.image — Image Processing & Manipulation ===\n")

-- =============================================================================
-- Image Data Creation (module-level functions)
-- =============================================================================

-- Create a blank image buffer for procedural texture generation.
local canvas_img = lurek.image.newImageData(256, 256)
print("blank image data: 256x256 pixels")

-- Load an image file into an ImageData buffer for pixel manipulation.
local hero_portrait = lurek.image.loadImage("assets/portraits/hero.png")
print("hero portrait loaded for editing")

-- Load a GPU-compressed texture (DXT/BC/ETC) for memory-efficient storage.
local compressed = lurek.image.newCompressedData("assets/textures/world_atlas.dds")
print("compressed texture loaded: world atlas")

print("world atlas compressed: " .. tostring(lurek.image.isCompressed(compressed)))

-- Layered images for character paper-doll systems or UI compositing.
local portrait_layers = lurek.image.newLayeredImage(128, 128)
print("layered image: 128x128 (character portrait compositor)")

-- Load a multi-layer image file (PSD-like format).
local npc_layers = lurek.image.loadLayered("assets/portraits/npc_layered.png")
print("layered NPC portrait loaded")

-- Create a palette look-up table for color swaps (e.g. faction recoloring).
-- Maps source colors to replacement colors.
local fire_palette = lurek.image.newPaletteLut({
    {0.8, 0.2, 0.1, 1.0},  -- red
    {1.0, 0.5, 0.0, 1.0},  -- orange
    {1.0, 0.9, 0.2, 1.0},  -- yellow
    {0.3, 0.1, 0.0, 1.0},  -- dark red
})
print("fire palette LUT: 4 colors (red/orange/yellow/dark)")

-- Create a province grid from a color-coded map image.
-- Each unique color = one province. Used for strategy game maps.
local province_map = lurek.image.newProvinceGrid("assets/maps/provinces.png")
print("province grid loaded from color-coded map")

-- =============================================================================
-- Save / Export (module-level functions)
-- =============================================================================

-- Save an ImageData to file (format detected from extension).
lurek.image.saveImage(canvas_img, "output/generated_texture.png")
print("image saved: output/generated_texture.png")

-- Explicit PNG save with compression options.
lurek.image.savePNG(canvas_img, "output/texture_hq.png")
print("PNG saved: output/texture_hq.png")

-- =============================================================================
-- ProvinceGrid Object Methods
-- =============================================================================

print("province grid width: " .. province_map:getWidth() .. "px")

print("province grid height: " .. province_map:getHeight() .. "px")

-- Get the province ID at a pixel position (for mouse picking on the world map).
local province_id = province_map:getAt(256, 128)
print("province at (256,128): " .. tostring(province_id))

print("total provinces: " .. province_map:provinceCount())

-- Get all provinces adjacent to a given one (for diplomacy/border logic).
local neighbors = province_map:adjacencies(province_id)
print("province " .. tostring(province_id) .. " neighbors: " .. #neighbors)

-- =============================================================================
-- LayeredImage Object Methods — paper-doll compositing
-- =============================================================================

print("layered width: " .. portrait_layers:getWidth())

print("layered height: " .. portrait_layers:getHeight())

print("layers: " .. portrait_layers:layerCount())

-- Add layers for each equipment slot in a character portrait.
portrait_layers:addLayer("base_body", "assets/portraits/layers/body.png")
portrait_layers:addLayer("armor", "assets/portraits/layers/plate_armor.png")
portrait_layers:addLayer("helmet", "assets/portraits/layers/iron_helm.png")
portrait_layers:addLayer("expression", "assets/portraits/layers/smile.png")
print("4 layers added: body, armor, helmet, expression")

portrait_layers:removeLayer("helmet")
print("helmet layer removed (player unequipped)")

local armor_layer = portrait_layers:getLayer("armor")
print("armor layer: " .. tostring(armor_layer))

print("armor opacity: " .. tostring(portrait_layers:getOpacity("armor")))

-- Fade out damaged equipment for a visual "broken" effect.
portrait_layers:setOpacity("armor", 0.5)
print("armor opacity: 0.5 (damaged appearance)")

print("armor visible: " .. tostring(portrait_layers:isVisible("armor")))

-- Toggle helmet visibility from the UI.
portrait_layers:setVisible("expression", true)
print("expression layer visible")

print("layer 0 name: " .. portrait_layers:getName(0))

portrait_layers:setName(0, "skin_base")
print("layer 0 renamed to: skin_base")

-- Reorder layers (put expression on top of armor).
portrait_layers:swapLayers(0, 1)
print("layers 0 and 1 swapped")

-- Flatten all layers into a single ImageData for export or rendering.
local flat = portrait_layers:merge()
print("layers merged to single image")

portrait_layers:save("output/hero_portrait_final.png")
print("layered portrait saved: output/hero_portrait_final.png")

-- =============================================================================
-- CompressedImageData Object Methods
-- =============================================================================

print("compressed width: " .. compressed:getWidth())

print("compressed height: " .. compressed:getHeight())

local cw, ch = compressed:getDimensions()
print("compressed: " .. cw .. "x" .. ch)

print("mipmaps: " .. compressed:getMipmapCount())

print("format: " .. compressed:getFormat())

-- =============================================================================
-- ImageData (mlua class) — pixel-level manipulation
-- =============================================================================

print("canvas width: " .. canvas_img:getWidth())

print("canvas height: " .. canvas_img:getHeight())

local iw, ih = canvas_img:getDimensions()
print("canvas dimensions: " .. iw .. "x" .. ih)

-- Read a pixel's RGBA values (0.0-1.0 range).
local r, g, b, a = canvas_img:getPixel(0, 0)
print("pixel (0,0): r=" .. r .. " g=" .. g .. " b=" .. b .. " a=" .. a)

-- Fill the entire image with a color for a blank canvas.
canvas_img:fill(0.2, 0.3, 0.5, 1.0)
print("canvas filled with dark blue")

-- Apply Perlin noise for procedural texture generation.
canvas_img:noise(42, 0.05)
print("Perlin noise applied (seed=42, scale=0.05)")

-- Transform every pixel with a custom function.
Example: swap red and blue channels.
canvas_img:mapPixel(function(x, y, r, g, b, a)
    return b, g, r, a  -- swap R <-> B
end)
print("pixel map applied: R/B channel swap")

-- Encode the image to a format string (e.g. for network transfer).
local encoded = canvas_img:encode("png")
print("image encoded to PNG: " .. #encoded .. " bytes")

local raw_str = canvas_img:getString()
print("raw pixel data: " .. #raw_str .. " bytes")

-- Color adjustments for day/night cycle and mood effects:

-- Increase brightness for daytime, decrease for night.
canvas_img:brightness(1.2)
print("brightness +20% (midday sun)")

canvas_img:contrast(1.1)
print("contrast +10% (sharper shadows)")

-- Desaturate during flashback or ghost-world sequences.
canvas_img:saturation(0.3)
print("saturation 30% (faded memory flashback)")

canvas_img:gamma(1.0)
print("gamma: 1.0 (neutral)")

-- Full grayscale for death screen or stylistic choice.
canvas_img:grayscale()
print("converted to grayscale")

-- Sepia tone for old-timey flashback sequences.
canvas_img:sepia()
print("sepia tone applied (historical flashback)")

-- Invert colors for psychedelic or damage effects.
canvas_img:invert()
print("colors inverted (negative image)")

-- Convert to black/white at a brightness threshold. Good for stencil masks.
canvas_img:threshold(0.5)
print("threshold at 0.5 (high-contrast mask)")

-- Reduce to N color levels for a retro look.
canvas_img:posterize(4)
print("posterized to 4 levels (retro pixel art style)")

-- Apply a grayscale mask image as the alpha channel.
-- White areas become opaque, black becomes transparent.
local mask = lurek.image.newImageData(256, 256)
mask:fill(1.0, 1.0, 1.0, 1.0)
canvas_img:alphaMask(mask)
print("alpha mask applied")

-- Geometric transforms:

canvas_img:flipHorizontal()
print("flipped horizontally (mirror)")

canvas_img:flipVertical()
print("flipped vertically")

canvas_img:rotate90cw()
print("rotated 90° clockwise")

-- Crop to a sub-region (x, y, width, height).
canvas_img:crop(32, 32, 192, 192)
print("cropped to 192x192 from (32,32)")

-- Resize with bilinear interpolation (smooth scaling).
canvas_img:resize(128, 128)
print("resized to 128x128 (bilinear)")

-- Nearest-neighbor resize preserves pixel art crispness.
canvas_img:resizeNearest(64, 64)
print("resized to 64x64 (nearest-neighbor — crisp pixels)")

Filters:

-- Gaussian blur for softening or depth-of-field effect.
canvas_img:blur(3)
print("blurred with radius 3")

canvas_img:sharpen(1.5)
print("sharpened (strength 1.5)")

Comparison:

-- Pixel-by-pixel difference between two images (for regression testing).
local diff_img = canvas_img:diff(mask)
print("diff computed (non-zero = pixels that changed)")

-- Alternative pixel mapper (batch version).
canvas_img:mapPixels(function(x, y, r, g, b, a)
    return r * 0.9, g * 0.8, b * 1.1, a
end)
print("mapPixels: cool tint applied (slightly blue)")

-- Remap image colors using a palette LUT. Use for faction recoloring.
canvas_img:applyPaletteLut(fire_palette)
print("fire palette LUT applied (faction recolor)")

-- =============================================================================
-- PaletteLUT Object Methods
-- =============================================================================

print("fire palette colors: " .. fire_palette:getColorCount())

fire_palette:clear()
print("palette LUT cleared")

print("\n-- image.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- mlua methods
-- -----------------------------------------------------------------------------

-- Replaces all pixel data from a raw RGBA byte string.
lurek.image:setRawData(bytes)
