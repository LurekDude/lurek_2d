-- Load image into CPU buffer
local imgData = lurek.image.newImageData("tiles.png")

-- Apply pixel-level filter
imgData:mapPixel(function(x, y, r, g, b, a)
    -- Palette swap: replace specific colour
    if r > 0.9 and g < 0.1 and b < 0.1 then
        return 0.1, 0.1, 0.9, a   -- red → blue
    end
    return r, g, b, a
end)

-- Upload to GPU
local img = lurek.render.newImage(imgData)
