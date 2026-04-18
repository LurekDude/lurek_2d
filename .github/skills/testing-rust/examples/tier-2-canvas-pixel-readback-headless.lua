-- @covers lurek.gfx.rectangle
-- @evidence pixel
describe("lurek.gfx.rectangle", function()
    it("fills rectangle region with current color", function()
        local canvas = lurek.gfx.newCanvas(64, 64)
        canvas:renderTo(function()
            lurek.gfx.setColor(1, 0, 0, 1)
            lurek.gfx.rectangle("fill", 0, 0, 64, 64)
        end)
        expect_canvas_pixel(canvas, 32, 32, 1.0, 0.0, 0.0, 1.0, 0.05,
            "center pixel must be red after filled rectangle")
    end)
end)
