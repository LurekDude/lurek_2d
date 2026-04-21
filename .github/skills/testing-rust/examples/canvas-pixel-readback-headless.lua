-- Verify drawing actually produces pixels
local canvas = lurek.render.newCanvas(100, 100)
canvas:renderTo(function()
    lurek.render.setColor(1, 0, 0, 1)
    lurek.render.rectangle("fill", 0, 0, 100, 100)
end)
local r, g, b, a = canvas:getPixel(50, 50)
expect_near(1.0, r, 0.01)  -- proves rectangle was drawn
