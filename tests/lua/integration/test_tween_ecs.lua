-- Integration: tween state animating entity component properties via ECS
describe("integration: tween drives entity transform", function()
    -- @integration LTweenState:lerp
    -- @integration LTweenState:tick
    -- @integration LUniverse:get
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.tween.newState
    it("entity x position tweened from 0 to 300", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:set(id, "x", 0.0)
        universe:set(id, "y", 100.0)

        local from_val, to_val = 0.0, 300.0
        local state = lurek.tween.newState(1.0, "linear")

        -- Simulate 60 frames (1 second)
        local dt = 1 / 60
        for _ = 1, 60 do
            state:tick(dt)
            universe:set(id, "x", state:lerp(from_val, to_val))
        end

        local x = universe:get(id, "x")
        expect_near(300, x, 5.0, "entity x reached target after 1s")
    end)

    -- @integration LUniverse:get
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.tween.newState
    it("multiple entities tweened simultaneously", function()
        local universe = lurek.ecs.newUniverse()
        local ids, states, targets = {}, {}, {}

        for i = 1, 5 do
            local id = universe:spawn()
            universe:set(id, "x", 0.0)
            ids[i] = id
            states[i] = lurek.tween.newState(1.0, "linear")
            targets[i] = i * 100
        end

        -- Advance all states to completion
        for _, st in ipairs(states) do
            st:tick(1.1)
        end

        -- Verify each entity gets its target value
        for i, id in ipairs(ids) do
            local val = states[i]:lerp(0, targets[i])
            universe:set(id, "x", val)
            local x = universe:get(id, "x")
            expect_near(targets[i], x, 1.0, "entity " .. i .. " x = " .. targets[i])
        end
    end)

end)
test_summary()
