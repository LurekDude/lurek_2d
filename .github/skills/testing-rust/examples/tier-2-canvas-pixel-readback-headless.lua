-- @covers lurek.render.rectangle
-- @evidence pixel
describe("lurek.render.rectangle", function()
    it("fills rectangle region with current color", function()
        local canvas = lurek.render.newCanvas(64, 64)
        canvas:renderTo(function()
            lurek.render.setColor(1, 0, 0, 1)
            lurek.render.rectangle("fill", 0, 0, 64, 64)
        end)
        expect_canvas_pixel(canvas, 32, 32, 1.0, 0.0, 0.0, 1.0, 0.05,
            "center pixel must be red after filled rectangle")
    end)
end)
