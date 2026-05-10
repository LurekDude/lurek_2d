-- Integration: effect stack setup and camera transforms can be configured together.
-- @describe integration: effect + camera
describe("integration: effect + camera", function()
    -- @integration LCamera:getZoom
    -- @integration LCamera:setZoom
    -- @integration LEffectStack:add
    -- @integration lurek.camera.newCamera
    -- @integration lurek.effect.newEffect
    -- @integration lurek.effect.newStack
    it("applies effect stack while camera zoom changes", function()
        local cam = lurek.camera.newCamera()
        local stack = lurek.effect.newStack(320, 240)
        local bloom = lurek.effect.newEffect("bloom")

        stack:add(bloom)
        cam:setZoom(1.25)

        local z = cam:getZoom()
        expect_near(1.25, z, 0.001, "camera zoom should be applied")
    end)
end)

test_summary()
