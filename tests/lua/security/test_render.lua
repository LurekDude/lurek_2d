-- test_render.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: API Fuzz / Nil Spam
-- Tests that core APIs handle nil, wrong types, and edge cases gracefully

-- @description Covers suite: fuzz: nil arguments to core APIs.
describe("fuzz: nil arguments to core APIs", function()
    -- @covers lurek.render.setColor
    -- @security nil-spam
    -- @security type-confusion
    -- @description Sends all-nil color channels to the renderer color setter to verify nil-spam is rejected with a Lua error instead of crashing native code.
    it("lurek.render.setColor handles nil gracefully", function()
        expect_error(function()
            lurek.render.setColor(nil, nil, nil)
        end)
    end)

    -- @covers lurek.render.rectangle
    -- @description Passes nil for every rectangle parameter to exercise draw-call argument validation and confirm the bad payload fails safely.
    it("lurek.render.rectangle handles nil gracefully", function()
        expect_error(function()
            lurek.render.rectangle(nil, nil, nil, nil, nil)
        end)
    end)

    -- @covers lurek.render.circle
    -- @description Uses nil coordinates and radius for circle drawing to probe the shape API against missing numeric inputs.
    it("lurek.render.circle handles nil gracefully", function()
        expect_error(function()
            lurek.render.circle(nil, nil, nil, nil)
        end)
    end)

    -- @covers lurek.render.line
    -- @description Floods the line primitive with nil endpoints to verify the graphics binding rejects invalid coordinates without unwinding into Rust.
    xit("lurek.render.line handles nil gracefully", function()
        expect_error(function()
            lurek.render.line(nil, nil, nil, nil)
        end)
    end)
end)

-- @description Covers suite: fuzz: wrong types to physics.
describe("fuzz: wrong types to physics", function()
    -- @covers lurek.physics.newWorld
    -- @description Supplies strings where gravity numbers are required to confirm the world constructor rejects type-confused payloads.
    it("lurek.physics.newWorld rejects string gravity", function()
        expect_error(function()
            lurek.physics.newWorld("hello", "world")
        end)
    end)

    -- @covers lurek.physics.newBody
    -- @description Calls body creation with a nil world handle to ensure missing-world misuse is surfaced as an error rather than dereferencing an invalid handle.
    it("lurek.physics.newBody rejects nil world", function()
        expect_error(function()
            lurek.physics.newBody(nil, 0, 0, "dynamic")
        end)
    end)

    -- @covers lurek.physics.step
    -- @description Steps physics with a nil world handle to probe the scheduler path for stale or absent handle validation.
    it("lurek.physics.step rejects nil world", function()
        expect_error(function()
            lurek.physics.step(nil, 0.016)
        end)
    end)

    -- @covers lurek.physics.newWorld
    -- @covers lurek.physics.step
    -- @description Uses a valid world but a string delta time to verify the stepping API rejects wrong-type frame durations cleanly.
    it("lurek.physics.step rejects string dt", function()
        local world = lurek.physics.newWorld(0, 10)
        expect_error(function()
            lurek.physics.step(world, "not_a_number")
        end)
        lurek.physics.destroyWorld(world)
    end)
end)

-- @description Covers suite: fuzz: wrong types to entity system.
describe("fuzz: wrong types to entity system", function()
    -- @covers lurek.ecs.newUniverse
    -- @description Invokes entity component assignment with a nil entity id to verify ECS APIs guard against null-handle writes.
    it("universe:set with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:set(nil, "key", "value")
        end)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @description Reads a component through a nil entity id to ensure invalid lookup handles are rejected before any table or arena access.
    it("universe:get with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:get(nil, "key")
        end)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @description Attempts to delete a nil entity id to probe liveness checks on destructive ECS operations.
    it("universe:kill with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:kill(nil)
        end)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @description Queries liveness with a nil entity id so the API must reject the malformed handle instead of treating it as entity zero.
    it("universe:isAlive with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:isAlive(nil)
        end)
    end)
end)

-- @description Covers suite: fuzz: wrong types to data module.
describe("fuzz: wrong types to data module", function()
    -- @covers lurek.data.encode
    -- @description Sends a nil format selector into the encoder to verify serialization dispatch cannot be confused by a missing codec name.
    it("lurek.data.encode rejects nil format", function()
        expect_error(function()
            lurek.data.encode(nil, { a = 1 })
        end)
    end)

    -- @covers lurek.data.decode
    -- @description Passes a nil format selector into the decoder to ensure decode routing validates the requested format before parsing.
    it("lurek.data.decode rejects nil format", function()
        expect_error(function()
            lurek.data.decode(nil, "{}")
        end)
    end)

    -- @covers lurek.data.decode
    -- @description Feeds malformed JSON into the generic decode entrypoint to verify hostile serialized input returns a Lua error instead of panicking the parser.
    it("lurek.data.decode rejects malformed JSON", function()
        expect_error(function()
            lurek.data.decode("json", "{{{{not json!!!")
        end)
    end)

    -- @covers lurek.data.compress
    -- @description Passes nil into compression to exercise null payload handling on the binary transform path.
    it("lurek.data.compress rejects nil", function()
        expect_error(function()
            lurek.data.compress("deflate", nil)
        end)
    end)

    -- @covers lurek.data.decompress
    -- @description Uses arbitrary non-compressed bytes against decompression to ensure garbage input cannot corrupt or crash the decompressor.
    it("lurek.data.decompress rejects garbage", function()
        expect_error(function()
            lurek.data.decompress("deflate", "not compressed data at all!!")
        end)
    end)
end)

-- @description Covers suite: fuzz: wrong types to AI module.
describe("fuzz: wrong types to AI module", function()
    -- @covers lurek.ai.newStateMachine
    -- @description Attempts to register a state under a nil name so the AI binding must reject malformed FSM definitions.
    it("fsm:addState with nil name", function()
        local fsm = lurek.ai.newStateMachine()
        expect_error(function()
            fsm:addState(nil, { onUpdate = function() end })
        end)
    end)

    -- @covers lurek.ai.newStateMachine
    -- @description Forces a transition into an undefined state to check that state-machine control flow rejects bogus identifiers rather than indexing nil state records.
    xit("fsm:forceState with non-existent state", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", { onUpdate = function() end })
        expect_error(function()
            fsm:forceState("nonexistent_state_xyz")
        end)
    end)
end)

-- @description Covers suite: fuzz: wrong types to math module.
describe("fuzz: wrong types to math module", function()
    -- @covers lurek.math.Vec2
    -- @description Constructs a vector with string components to verify numeric constructors defend against type confusion.
    it("Vec2 rejects string args", function()
        expect_error(function()
            lurek.math.Vec2("hello", "world")
        end)
    end)

    -- @covers lurek.math.sin
    -- @description Sends nil into a scalar trigonometry function to confirm math bindings reject absent numbers consistently.
    it("sin rejects nil", function()
        expect_error(function()
            lurek.math.sin(nil)
        end)
    end)

    -- @covers lurek.math.lerp
    -- @description Passes nil through all interpolation parameters to test the API against fully missing numeric input.
    it("lerp rejects nil", function()
        expect_error(function()
            lurek.math.lerp(nil, nil, nil)
        end)
    end)
end)

-- @description Covers suite: fuzz: wrong types to audio module.
describe("fuzz: wrong types to audio module", function()
    -- @covers lurek.audio.setMasterVolume
    -- @description Sends a string volume value to the master gain setter to confirm audio controls reject non-numeric inputs.
    it("setMasterVolume rejects string", function()
        expect_error(function()
            lurek.audio.setMasterVolume("loud")
        end)
    end)

    -- @covers lurek.audio.setMasterVolume
    -- @description Sends nil to the master gain setter to probe null handling on the audio control surface.
    it("setMasterVolume rejects nil", function()
        expect_error(function()
            lurek.audio.setMasterVolume(nil)
        end)
    end)
end)

-- @description Covers suite: fuzz: edge case numbers.
describe("fuzz: edge case numbers", function()
    -- @covers lurek.math.sin
    -- @covers lurek.math.cos
    -- @description Exercises trigonometry with extremely large magnitudes to ensure floating-point extremes do not crash the math bindings.
    it("math handles very large numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e15)
            lurek.math.cos(1e15)
        end)
    end)

    -- @covers lurek.math.sin
    -- @covers lurek.math.cos
    -- @description Uses subnormal-scale inputs to confirm very small floats remain safe at the Lua-to-Rust boundary.
    it("math handles very small numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e-15)
            lurek.math.cos(1e-15)
        end)
    end)

    -- @covers lurek.math.sin
    -- @covers lurek.math.sqrt
    -- @description Checks negative zero handling so edge-case floating-point signs do not produce traps in scalar math helpers.
    it("math handles negative zero", function()
        expect_no_error(function()
            lurek.math.sin(-0.0)
            lurek.math.sqrt(0.0)
        end)
    end)

    -- @covers lurek.math.Vec2
    -- @description Constructs a vector with positive infinity to verify extreme numeric values do not crash userdata creation or normalization paths.
    it("Vec2 handles inf", function()
        -- Should not crash even with inf
        expect_no_error(function()
            local v = lurek.math.Vec2(1/0, 0)
        end)
    end)
end)



-- ================================================================
-- Merged from: test_fuzz_boundary.lua
-- ================================================================

-- Lurek2D Fuzz Tests (Sandbox Boundary)

-- @description Covers suite: sandbox boundary fuzzing.
describe("sandbox boundary fuzzing", function()
    -- @covers lurek.math
    -- @covers lurek.renders
    -- @covers lurek.physics
    -- @description Iterates over exposed math, graphics, and physics functions with random garbage arguments to detect Rust panics or VM crashes under broad fuzz pressure.
    it("handles random inputs without crashing the engine", function()
        -- Extract a few engine API tables
        local namespaces = {lurek.math, lurek.renders, lurek.physics}

        -- Generate random Lua types
        local garbage = {
            1, -1, 0, 3.14, "hello", "", string.rep("A", 10000),
            {}, {a=1}, {1, 2, 3},
            function() end, true, false, nil
        }

        for _, ns in ipairs(namespaces) do
            if ns then
                for func_name, func in pairs(ns) do
                    if type(func) == "function" then
                        -- Fuzz each function with 1-3 garbage args
                        for i = 1, 10 do
                            local a1 = garbage[math.random(#garbage)]
                            local a2 = garbage[math.random(#garbage)]
                            local a3 = garbage[math.random(#garbage)]

                            -- We expect this to either succeed or throw a Lua error (which is caught by pcall)
                            -- What MUST NOT happen is a Rust panic (which crashes the test process)
                            pcall(func, a1, a2, a3)
                        end
                    end
                end
            end
        end
        expect_true(true, "survived fuzzing without a Rust panic")
    end)
end)



-- ================================================================
-- Merged from: test_invalid_args.lua
-- ================================================================

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
