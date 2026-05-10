-- Integration: AI world agent position is mirrored by camera while scene stack is active.
-- @describe integration: ai + scene + camera
describe("integration: ai + scene + camera", function()
    -- @integration lurek.ai.newWorld
    -- @integration lurek.camera.newCamera
    -- @integration lurek.scene.clear
    -- @integration lurek.scene.getStackSize
    -- @integration lurek.scene.push
    it("keeps camera aligned with AI agent position", function()
        local world = lurek.ai.newWorld()
        local cam = lurek.camera.newCamera()

        lurek.scene.clear()
        lurek.scene.push({ name = "battle" })

        local agent = world:addAgent("hero")
        agent:setPosition(64, 96)
        local ax, ay = agent:getPosition()

        cam:setPosition(ax, ay)
        local cx, cy = cam:getPosition()

        expect_equal(1, lurek.scene.getStackSize(), "scene stack should contain active scene")
        expect_near(ax, cx, 0.001, "camera x follows AI agent")
        expect_near(ay, cy, 0.001, "camera y follows AI agent")
    end)
end)

test_summary()
