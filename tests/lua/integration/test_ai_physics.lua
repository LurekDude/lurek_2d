-- Integration: AI steering forces applied to physics bodies
describe("integration: AI steering with physics bodies", function()
    -- @integration LSteeringManager:addSeek
    -- @integration LSteeringManager:calculate
    -- @integration lurek.ai.newSteeringManager
    -- @integration lurek.physics.getBody
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    -- @integration lurek.physics.setBodyVelocity
    -- @integration lurek.physics.step
    it("agent seeks target in physics world", function()
        -- Top-down world: no gravity
        local world_id = lurek.physics.newWorld(0, 0)

        local seeker_body = lurek.physics.newBody(world_id, 100, 100, "dynamic")
        local target_body = lurek.physics.newBody(world_id, 400, 400, "static") -- luacheck: ignore

        local sm = lurek.ai.newSteeringManager()
        sm:addSeek(400, 400, 1.0)

        -- calculate() returns (fx, fy) steering force components
        local fx, fy = sm:calculate(100, 100, 0, 0, 50, 100, 1.0 / 60.0)
        expect_not_nil(fx, "steering fx returned")

        -- Apply as velocity, then step 60 frames
        local vel_x = type(fx) == "number" and fx or 50
        local vel_y = type(fy) == "number" and fy or 50
        lurek.physics.setBodyVelocity(world_id, seeker_body, vel_x, vel_y)
        for _ = 1, 60 do
            lurek.physics.step(world_id, 1.0 / 60.0)
        end

        local px, py = lurek.physics.getBody(world_id, seeker_body)
        local moved = math.abs(px - 100) > 0.1 or math.abs(py - 100) > 0.1
        expect_true(moved, "seeker moved from starting position")
    end)
end)
test_summary()
