-- Integration: camera viewport tracking entity positions via ECS
describe("integration: scene camera viewport operations", function()
    -- @integration LCamera:getPosition
    -- @integration LCamera:setPosition
    -- @integration LUniverse:get
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.camera.newCamera
    -- @integration lurek.ecs.newUniverse
    it("camera follows tracked entity position", function()
        local universe = lurek.ecs.newUniverse()
        local cam = lurek.camera.newCamera()

        local player = universe:spawn()
        universe:set(player, "x", 128.0)
        universe:set(player, "y", 64.0)

        local raw_px = universe:get(player, "x")
        local raw_py = universe:get(player, "y")
        local px = (type(raw_px) == "number") and raw_px or ((type(raw_px) == "table" and (raw_px.x or raw_px[1])) or 0)
        local py = (type(raw_py) == "number") and raw_py or ((type(raw_py) == "table" and (raw_py.y or raw_py[2])) or 0)
        expect_type("number", px, "entity x is a number")
        expect_type("number", py, "entity y is a number")

        cam:setPosition(px, py)

        local cx, cy = cam:getPosition()
        expect_near(128, cx, 0.001, "camera follows entity x")
        expect_near(64,  cy, 0.001, "camera follows entity y")
    end)

end)
test_summary()
