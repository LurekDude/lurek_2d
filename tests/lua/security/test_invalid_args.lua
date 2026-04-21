-- Lurek2D Validation Test: Invalid API Arguments
-- Tests that API functions handle bad inputs without crashing

-- @description Covers suite: validation: physics invalid args.
describe("validation: physics invalid args", function()
    -- @covers lurek.physics.step
    -- @security lurek.compute.zeros
    -- @security lurek.dataframe.newDataFrame
    -- @security lurek.ecs.newUniverse
    -- @security lurek.graph.newGraph
    -- @security lurek.image.newImageData
    -- @security lurek.physics.destroyWorld
    -- @security lurek.physics.newBody
    -- @security lurek.physics.newWorld
    -- @security lurek.physics.setBodyVelocity
    -- @security lurek.physics.step
    -- @security lurek.tilemap.newTileMap
    -- @security lurek.tilemap.newTileSet
    -- @description Verifies stepping physics with a nil world id is rejected as an invalid handle instead of dereferencing a missing world.
    it("rejects nil world ID", function()
        expect_error(function()
            lurek.physics.step(nil, 0.016)
        end, "nil world ID")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
    -- @description Sends a negative timestep through a valid world to ensure the simulation path degrades safely even when the delta is nonsensical.
    it("handles negative dt without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Negative dt should not crash
        expect_no_error(function()
            lurek.physics.step(world_id, -1.0)
        end, "negative dt should not crash")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @description Creates a body with an unknown body type string to probe enum coercion and verify invalid body kinds do not crash the binding.
    it("handles invalid body type string", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Engine may accept or coerce invalid types
        expect_no_error(function()
            lurek.physics.newBody(world_id, 0, 0, "invalid_type")
        end, "invalid body type should not crash")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @description Injects NaN coordinates into body creation to ensure the physics bridge rejects or safely contains non-finite transforms.
    it("handles NaN position gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        expect_no_error(function()
            lurek.physics.newBody(world_id, 0/0, 0/0, "dynamic")
        end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.newBody
    -- @covers lurek.physics.setBodyVelocity
    -- @covers lurek.physics.step
    -- @description Drives a body with extremely large velocities to confirm the solver and handle lookups stay stable under overflow-prone inputs.
    it("handles huge velocity without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body = lurek.physics.newBody(world_id, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world_id, body, 1e10, 1e10)
            lurek.physics.step(world_id, 0.016)
        end, "huge velocity should not crash")
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.destroyWorld
    -- @covers lurek.physics.step
    -- @description Steps a world handle after destruction to verify stale-handle use is contained rather than crashing the physics registry.
    it("handles destroyed world gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        lurek.physics.destroyWorld(world_id)
        -- Operations on destroyed world may not crash
        expect_no_error(function()
            lurek.physics.step(world_id, 0.016)
        end, "step on destroyed world should not crash")
    end)
end)

-- @description Covers suite: validation: compute invalid args.
describe("validation: compute invalid args", function()
    -- @covers lurek.compute.zeros
    -- @description Requests a zero-length dimension from the compute allocator to confirm invalid shapes are rejected before allocation.
    it("rejects zero-dimension array", function()
        expect_error(function()
            lurek.compute.zeros({0}, "float32")
        end, "zero dimension should error")
    end)

    -- @covers lurek.compute.zeros
    -- @description Supplies a negative array dimension to test shape validation against underflow-style input.
    it("rejects negative dimension", function()
        expect_error(function()
            lurek.compute.zeros({-5}, "float32")
        end, "negative dimension should error")
    end)

    -- @covers lurek.compute.zeros
    -- @description Uses an unsupported dtype string so the compute entrypoint must reject unknown element types explicitly.
    it("rejects invalid dtype string", function()
        expect_error(function()
            lurek.compute.zeros({10}, "invalid_type")
        end, "invalid dtype should error")
    end)

    -- @covers lurek.compute.zeros
    -- @description Requests a four-dimensional tensor when the API only accepts lower-dimensional shapes, exercising bounds checks on shape rank.
    it("rejects too many dimensions", function()
        expect_error(function()
            lurek.compute.zeros({2, 3, 4, 5}, "float32")
        end, "4D should error")
    end)
end)

-- @description Covers suite: validation: dataframe invalid ops.
describe("validation: dataframe invalid ops", function()
    -- @covers lurek.dataframe.newDataFrame
    -- @description Removes a column that was never declared to verify schema mutation guards reject bogus column names.
    it("rejects removing nonexistent column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("real", 0)
        expect_error(function()
            df:removeColumn("nonexistent")
        end, "remove nonexistent column should error")
    end)

    -- @covers lurek.dataframe.newDataFrame
    -- @description Reads far beyond the existing row range to ensure dataframe accessors reject out-of-bounds indices cleanly.
    it("rejects out-of-range row access", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 1})
        expect_error(function()
            df:getValue(999, "val")
        end, "out of range row should error")
    end)

    -- @covers lurek.dataframe.newDataFrame
    -- @description Defines the same column twice to check that duplicate schema names are blocked rather than corrupting internal tables.
    it("rejects duplicate column names", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("name", "")
        expect_error(function()
            df:addColumn("name", "")
        end, "duplicate column should error")
    end)
end)

-- @description Covers suite: validation: graph invalid operations.
describe("validation: graph invalid operations", function()
    -- @covers lurek.graph.newGraph
    -- @description Attempts to connect a valid node to a bogus numeric handle to verify graph edge creation validates both endpoints.
    it("rejects edge with invalid node", function()
        local g = lurek.graph.newGraph()
        local n1 = g:addNode("processor", 100)
        -- Passing a number instead of node userdata should error
        expect_error(function()
            g:addEdge(n1, 999)
        end, "edge to invalid node should error")
    end)

    -- @covers lurek.graph.newGraph
    -- @description Adds a node with a negative capacity to verify the graph constructor path remains safe even if the value is semantically odd.
    it("accepts negative capacity", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:addNode("processor", -1)
        end)
    end)
end)

-- @description Covers suite: validation: entity invalid operations.
describe("validation: entity invalid operations", function()
    -- @covers lurek.ecs.newUniverse
    -- @description Kills an entity id that was never allocated to confirm the ECS ignores invalid deletes without panicking.
    it("handles kill of nonexistent entity", function()
        local universe = lurek.ecs.newUniverse()
        expect_no_error(function()
            universe:kill(99999)
        end, "kill nonexistent should not crash")
    end)

    -- @covers lurek.ecs.newUniverse
    -- @description Reads liveness after destroying an entity to verify dead ids stay invalid and do not resurrect through a getter.
    it("handles get on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_false(universe:isAlive(id), "dead entity is not alive")
    end)

    -- @covers lurek.ecs.newUniverse
    -- @description Attempts to mutate components on a dead entity id to verify stale entity handles are rejected.
    it("handles set on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_error(function()
            universe:set(id, "comp", 42)
        end, "set on dead entity should error")
    end)
end)

-- @description Covers suite: validation: image invalid operations.
describe("validation: image invalid operations", function()
    -- @covers lurek.image.newImageData
    -- @description Creates a zero-by-zero image to ensure degenerate dimensions are handled without crashing the image allocator.
    it("handles zero-size image gracefully", function()
        -- Engine may accept zero-size image without error
        expect_no_error(function()
            lurek.image.newImageData(0, 0)
        end, "zero size image should not crash")
    end)

    -- @covers lurek.image.newImageData
    -- @description Loads a missing image path to verify file-based image creation returns a Lua error for absent assets.
    it("rejects loading nonexistent file", function()
        expect_error(function()
            lurek.image.newImageData("nonexistent_file.png")
        end, "nonexistent file should error")
    end)
end)

-- @description Covers suite: validation: tilemap invalid operations.
describe("validation: tilemap invalid operations", function()
    -- @covers lurek.tilemap.newTileMap
    -- @covers lurek.tilemap.newTileSet
    -- @description Reads tiles far outside the layer bounds to ensure map lookups remain safe under oversized coordinates.
    it("handles out-of-bounds tile access", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 10, 10)
        -- Out of bounds should return 0 or error, not crash
        expect_no_error(function()
            local tile = map:getTile(1, 999, 999)
        end, "out of bounds tile access should not crash")
    end)
end)
test_summary()
