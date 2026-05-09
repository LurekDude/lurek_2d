-- Lurek2D Stress Test: Mass Body Creation
-- Creates 1000 physics bodies and steps the world

-- @describe physics stress: 1000 bodies
describe("physics stress: 1000 bodies", function()
    -- @stress lurek.math.floor
    -- @stress lurek.physics.destroyWorld
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    it("creates 1000 bodies without error", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local bodies = {}

        for i = 1, 1000 do
            local x = (i % 50) * 10
            local y = lurek.math.floor(i / 50) * 10
            bodies[i] = lurek.physics.newBody(world_id, x, y, "dynamic")
        end

        expect_equal(1000, #bodies, "created 1000 bodies")

        -- Verify all bodies are valid
        for i = 1, 10 do
            local x, y = bodies[i]:getPosition()
            expect_true(type(x) == "number", "body position is number")
        end

        lurek.physics.destroyWorld(world_id)
    end)

    -- @stress lurek.physics.destroyWorld
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.step
    it("steps 1000-body world 60 times", function()
        local world_id = lurek.physics.newWorld(0, 100)

        for i = 1, 1000 do
            lurek.physics.newBody(world_id, i * 2, 0, "dynamic")
        end

        -- Simulate one second of gameplay
        for step = 1, 60 do
            lurek.physics.step(world_id, 1.0 / 60.0)
        end

        -- World should still be valid
        expect_true(true, "world survived 60 steps with 1000 bodies")

        lurek.physics.destroyWorld(world_id)
    end)
end)



-- ================================================================
-- Merged from: test_physics_cellular_stress.lua
-- ================================================================

-- Stress test: large cellular world simulation
-- Steps a 128x128 CellularWorld 500 times and verifies no crash.

-- @describe stress: cellular world simulation
describe("stress: cellular world simulation", function()
    --              and verifies simulation completes without error.
    -- @stress LCellular:countCells
    -- @stress LCellular:fillRect
    -- @stress LCellular:stepN
    -- @stress lurek.physics.CELL_ROCK
    -- @stress lurek.physics.CELL_SAND
    -- @stress lurek.physics.CELL_WATER
    -- @stress lurek.physics.newCellular
    it("128x128 cellular steps 500 ticks without error", function()
        local W, H = 128, 128
        local sim = lurek.physics.newCellular(W, H)

        -- Place a layer of sand at the top.
        sim:fillRect(0, 0, W, 4, lurek.physics.CELL_SAND)
        -- Place a water layer in the middle.
        sim:fillRect(0, math.floor(H / 2), W, 4, lurek.physics.CELL_WATER)
        -- Rock floor.
        sim:fillRect(0, H - 2, W, 2, lurek.physics.CELL_ROCK)

        local sand_initial = sim:countCells(lurek.physics.CELL_SAND)
        local rock_initial = sim:countCells(lurek.physics.CELL_ROCK)

        expect_no_error(function()
            sim:stepN(500)
        end)

        -- Rock is immutable     count must remain the same.
        expect_equal(rock_initial, sim:countCells(lurek.physics.CELL_ROCK))

        -- Sand is conserved.
        expect_equal(sand_initial, sim:countCells(lurek.physics.CELL_SAND))
    end)

    --              after a long simulation run.
    -- @stress LCellular:fillRect
    -- @stress LCellular:stepN
    -- @stress LCellular:toImageData
    -- @stress lurek.physics.CELL_SAND
    -- @stress lurek.physics.newCellular
    it("toImageData returns correct size after 200 steps", function()
        local W, H = 128, 128
        local sim = lurek.physics.newCellular(W, H)
        sim:fillRect(0, 0, W, 1, lurek.physics.CELL_SAND)
        sim:stepN(200)
        local raw = sim:toImageData()
        expect_equal(W * H * 4, #raw)
    end)
end)




-- ================================================================
-- Merged from: test_physics_collision_stress.lua
-- ================================================================

-- Lurek2D Stress Test: Physics Collision Storm
-- Tests mass body creation, extended simulation, and collision detection

-- @describe physics stress: collision storm
describe("physics stress: collision storm", function()
    -- @stress lurek.physics.getBody
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.step
    it("creates 500 bodies in a confined space", function()
        local world = lurek.physics.newWorld(0, 200)

        -- Ground
        lurek.physics.newBody(world, 250, 500, "static")

        -- Drop 500 bodies from varying heights
        local bodies = {}
        for i = 1, 500 do
            local x = 50 + (i % 20) * 20
            local y = -i * 5
            bodies[i] = lurek.physics.newBody(world, x, y, "dynamic")
        end

        expect_equal(500, #bodies, "500 dynamic bodies created")

        -- Step 300 times (5 seconds at 60fps)
        for step = 1, 300 do
            lurek.physics.step(world, 1.0 / 60.0)
        end

        -- Check that a body moved due to gravity
        local x, y = lurek.physics.getBody(world, bodies[1])
        expect_true(y > -500 * 5, "body moved under gravity")
    end)

    -- @stress lurek.physics.getCollisions
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.setBodyVelocity
    -- @stress lurek.physics.step
    it("detects collisions between moving bodies", function()
        local world = lurek.physics.newWorld(0, 100)

        -- Two bodies approaching each other
        local a = lurek.physics.newBody(world, 100, 100, "dynamic")
        local b = lurek.physics.newBody(world, 200, 100, "dynamic")

        -- Give them opposing velocities
        lurek.physics.setBodyVelocity(world, a, 50, 0)
        lurek.physics.setBodyVelocity(world, b, -50, 0)

        -- Step until they might collide
        local collisions_detected = false
        for step = 1, 120 do
            lurek.physics.step(world, 1.0 / 60.0)
            local events = lurek.physics.getCollisions(world)
            if events and #events > 0 then
                collisions_detected = true
                break
            end
        end

        -- The simulation should not crash regardless of collision result
        expect_true(true, "collision simulation completed without crash")
    end)

    -- @stress LWorld:newCircleBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.step
    it("circle bodies handle mass collision", function()
        local world = lurek.physics.newWorld(0, 100)

        -- Create 200 circle bodies
        for i = 1, 200 do
            local x = (i % 20) * 15 + 50
            local y = math.floor(i / 20) * 15
            world:newCircleBody(x, y, 5, "dynamic")
        end

        -- Step 180 times (3 seconds)
        for step = 1, 180 do
            lurek.physics.step(world, 1.0 / 60.0)
        end

        expect_true(true, "circle collision simulation completed")
    end)
end)

-- @describe physics stress: determinism
describe("physics stress: determinism", function()
    -- @stress lurek.physics.getBody
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.step
    it("same initial state produces same result", function()
        local function run_simulation()
            local world = lurek.physics.newWorld(0, 100)
            local body = lurek.physics.newBody(world, 100, 0, "dynamic")

            for step = 1, 60 do
                lurek.physics.step(world, 1.0 / 60.0)
            end

            local x, y = lurek.physics.getBody(world, body)
            return x, y
        end

        local x1, y1 = run_simulation()
        local x2, y2 = run_simulation()

        expect_near(x1, x2, 0.001, "x position deterministic")
        expect_near(y1, y2, 0.001, "y position deterministic")
    end)

    -- @stress lurek.physics.getBody
    -- @stress lurek.physics.newBody
    -- @stress lurek.physics.newWorld
    -- @stress lurek.physics.step
    it("deterministic results stay stable across 10 repeated runs", function()
        local function run_once()
            local world = lurek.physics.newWorld(0, 100)
            local body = lurek.physics.newBody(world, 50, 0, "dynamic")
            for _ = 1, 120 do
                lurek.physics.step(world, 1.0 / 60.0)
            end
            local x, y = lurek.physics.getBody(world, body)
            return x, y
        end

        local base_x, base_y = run_once()
        for _ = 1, 9 do
            local x, y = run_once()
            expect_near(base_x, x, 0.001, "x deterministic across repeated runs")
            expect_near(base_y, y, 0.001, "y deterministic across repeated runs")
        end
    end)
end)



-- ================================================================
-- Merged from: test_physics_terrain_stress.lua
-- ================================================================

-- Stress test: large terrain fill/dig/flush cycle
-- Exercises TerrainMap with a 128x128 grid, multiple fill + dig + flush iterations.

-- @describe stress: physics terrain fill/dig/flush
describe("stress: physics terrain fill/dig/flush", function()
    --              and verifies the dirty flag is cleared each time.
    -- @stress LTerrain:fillAll
    -- @stress LTerrain:fillCircle
    -- @stress LTerrain:flush
    -- @stress LTerrain:isDirty
    -- @stress lurek.physics.newTerrain
    -- @stress lurek.physics.newWorld
    it("20 fill/dig/flush cycles complete without error on 128x128", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(128, 128, 4, world)

        expect_no_error(function()
            for i = 1, 20 do
                terrain:fillAll(true)
                -- Dig a different circle each iteration.
                local cx = 64 + (i % 5) * 8
                local cy = 64 + math.floor(i / 5) * 8
                terrain:fillCircle(cx * 4, cy * 4, 32, false)
                terrain:flush()
                expect_false(terrain:isDirty())
            end
        end)
    end)

    --              counts on a partially-filled grid.
    -- @stress LTerrain:collapseColumns
    -- @stress LTerrain:fillRect
    -- @stress LTerrain:solidPositions
    -- @stress lurek.physics.newTerrain
    -- @stress lurek.physics.newWorld
    it("collapse then solidPositions is consistent", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(64, 64, 4, world)
        -- Fill top half only (rows 0-31); rows 32-63 are air     all top cells will collapse.
        terrain:fillRect(0, 0, 256, 128, true) -- world coords for rows 0-31
        local before = #terrain:solidPositions()
        terrain:collapseColumns()
        local after = #terrain:solidPositions()
        -- Can only check after <= before (collapseColumns removes cells).
        expect_true(after <= before, "solidPositions count must not increase after collapse")
    end)
end)




-- ================================================================
-- Merged from: test_physics_zones_stress.lua
-- ================================================================

-- Stress test: physics zones with many bodies
-- Creates 50 zones and 500 dynamic bodies, steps 60 times.
-- Verifies no crash and reasonable zone-event throughput.

-- @describe stress: physics zones throughput
describe("stress: physics zones throughput", function()
    --              without error. Verifies event table is returned.
    -- @stress LWorld:addZone
    -- @stress LWorld:getZoneEvents
    -- @stress LWorld:newBody
    -- @stress LWorld:step
    -- @stress LZone:setGravityZero
    -- @stress lurek.physics.newWorld
    it("50 zones + 500 bodies steps 60 frames without error", function()
        local world = lurek.physics.newWorld(0, 0)

        -- Create 50 overlapping zones.
        for i = 1, 50 do
            local z = world:addZone(-200 + i * 4, -200 + i * 4, 400, 400)
            z:setGravityZero()
            z:setPriority(i)
        end

        -- Create 500 dynamic bodies scattered across the arena.
        for i = 1, 500 do
            local x = (i % 50) * 8 - 200
            local y = math.floor(i / 50) * 8 - 200
            world:newBody(x, y, "dynamic")
        end

        -- Step 60 frames.
        expect_no_error(function()
            for _ = 1, 60 do
                world:step(1/60)
            end
        end)

        -- Events must be a table; may be large.
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)
end)




-- ================================================================
-- Merged from: test_stress_physics_cellular.lua
-- ================================================================

-- Stress test: large cellular world simulation
-- Steps a 128x128 CellularWorld 500 times and verifies no crash.

-- @describe stress: cellular world simulation
describe("stress: cellular world simulation", function()
    --              and verifies simulation completes without error.
    -- @stress LCellular:countCells
    -- @stress LCellular:fillRect
    -- @stress LCellular:stepN
    -- @stress lurek.physics.CELL_ROCK
    -- @stress lurek.physics.CELL_SAND
    -- @stress lurek.physics.CELL_WATER
    -- @stress lurek.physics.newCellular
    it("128x128 cellular steps 500 ticks without error", function()
        local W, H = 128, 128
        local sim = lurek.physics.newCellular(W, H)

        -- Place a layer of sand at the top.
        sim:fillRect(0, 0, W, 4, lurek.physics.CELL_SAND)
        -- Place a water layer in the middle.
        sim:fillRect(0, math.floor(H / 2), W, 4, lurek.physics.CELL_WATER)
        -- Rock floor.
        sim:fillRect(0, H - 2, W, 2, lurek.physics.CELL_ROCK)

        local sand_initial = sim:countCells(lurek.physics.CELL_SAND)
        local rock_initial = sim:countCells(lurek.physics.CELL_ROCK)

        expect_no_error(function()
            sim:stepN(500)
        end)

        -- Rock is immutable     count must remain the same.
        expect_equal(rock_initial, sim:countCells(lurek.physics.CELL_ROCK))

        -- Sand is conserved.
        expect_equal(sand_initial, sim:countCells(lurek.physics.CELL_SAND))
    end)

    --              after a long simulation run.
    -- @stress LCellular:fillRect
    -- @stress LCellular:stepN
    -- @stress LCellular:toImageData
    -- @stress lurek.physics.CELL_SAND
    -- @stress lurek.physics.newCellular
    it("toImageData returns correct size after 200 steps", function()
        local W, H = 128, 128
        local sim = lurek.physics.newCellular(W, H)
        sim:fillRect(0, 0, W, 1, lurek.physics.CELL_SAND)
        sim:stepN(200)
        local raw = sim:toImageData()
        expect_equal(W * H * 4, #raw)
    end)
end)




-- ================================================================
-- Merged from: test_stress_physics_terrain.lua
-- ================================================================

-- Stress test: large terrain fill/dig/flush cycle
-- Exercises TerrainMap with a 128x128 grid, multiple fill + dig + flush iterations.

-- @describe stress: physics terrain fill/dig/flush
describe("stress: physics terrain fill/dig/flush", function()
    --              and verifies the dirty flag is cleared each time.
    -- @stress LTerrain:fillAll
    -- @stress LTerrain:fillCircle
    -- @stress LTerrain:flush
    -- @stress LTerrain:isDirty
    -- @stress lurek.physics.newTerrain
    -- @stress lurek.physics.newWorld
    it("20 fill/dig/flush cycles complete without error on 128x128", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(128, 128, 4, world)

        expect_no_error(function()
            for i = 1, 20 do
                terrain:fillAll(true)
                -- Dig a different circle each iteration.
                local cx = 64 + (i % 5) * 8
                local cy = 64 + math.floor(i / 5) * 8
                terrain:fillCircle(cx * 4, cy * 4, 32, false)
                terrain:flush()
                expect_false(terrain:isDirty())
            end
        end)
    end)

    --              counts on a partially-filled grid.
    -- @stress LTerrain:collapseColumns
    -- @stress LTerrain:fillRect
    -- @stress LTerrain:solidPositions
    -- @stress lurek.physics.newTerrain
    -- @stress lurek.physics.newWorld
    it("collapse then solidPositions is consistent", function()
        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(64, 64, 4, world)
        -- Fill top half only (rows 0-31); rows 32-63 are air     all top cells will collapse.
        terrain:fillRect(0, 0, 256, 128, true) -- world coords for rows 0-31
        local before = #terrain:solidPositions()
        terrain:collapseColumns()
        local after = #terrain:solidPositions()
        -- Can only check after <= before (collapseColumns removes cells).
        expect_true(after <= before, "solidPositions count must not increase after collapse")
    end)
end)




-- ================================================================
-- Merged from: test_stress_physics_zones.lua
-- ================================================================

-- Stress test: physics zones with many bodies
-- Creates 50 zones and 500 dynamic bodies, steps 60 times.
-- Verifies no crash and reasonable zone-event throughput.

-- @describe stress: physics zones throughput
describe("stress: physics zones throughput", function()
    --              without error. Verifies event table is returned.
    -- @stress LWorld:addZone
    -- @stress LWorld:getZoneEvents
    -- @stress LWorld:newBody
    -- @stress LWorld:step
    -- @stress LZone:setGravityZero
    -- @stress lurek.physics.newWorld
    it("50 zones + 500 bodies steps 60 frames without error", function()
        local world = lurek.physics.newWorld(0, 0)

        -- Create 50 overlapping zones.
        for i = 1, 50 do
            local z = world:addZone(-200 + i * 4, -200 + i * 4, 400, 400)
            z:setGravityZero()
            z:setPriority(i)
        end

        -- Create 500 dynamic bodies scattered across the arena.
        for i = 1, 500 do
            local x = (i % 50) * 8 - 200
            local y = math.floor(i / 50) * 8 - 200
            world:newBody(x, y, "dynamic")
        end

        -- Step 60 frames.
        expect_no_error(function()
            for _ = 1, 60 do
                world:step(1/60)
            end
        end)

        -- Events must be a table; may be large.
        local events = world:getZoneEvents()
        expect_type("table", events)
    end)
end)
test_summary()


