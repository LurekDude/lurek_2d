-- Integration: raycaster per-cell texture overrides and render image userdata
describe("raycaster + render integration", function()
    -- @integration LImage:getId
    -- @integration LRaycaster:getFloorTextureCell
    -- @integration LRaycaster:getCeilingTextureCell
    -- @integration LRaycaster:setFloorTextureCell
    -- @integration LRaycaster:setCeilingTextureCell
    -- @integration lurek.raycaster.new
    -- @integration lurek.render.newImage
    it("accepts LImage userdata in per-cell overrides", function()
        local rc = lurek.raycaster.new(8, 8)
        local floor_img = lurek.render.newImage("assets/icon.png")
        local ceil_img = lurek.render.newImage("assets/icon.png")

        rc:setFloorTextureCell(1, 1, floor_img)
        rc:setCeilingTextureCell(1, 1, ceil_img)

        expect_equal(floor_img:getId(), rc:getFloorTextureCell(1, 1))
        expect_equal(ceil_img:getId(), rc:getCeilingTextureCell(1, 1))
    end)
end)

test_summary()
