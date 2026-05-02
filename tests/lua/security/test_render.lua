-- test_render.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: API Fuzz / Nil Spam
-- Tests that core APIs handle nil, wrong types, and edge cases gracefully
---@diagnostic disable: param-type-mismatch

describe("fuzz: nil arguments to core APIs", function()
    it("lurek.render.setColor handles nil gracefully", function()
        expect_error(function()
            lurek.render.setColor(nil, nil, nil)
        end)
    end)

    it("lurek.render.rectangle handles nil gracefully", function()
        expect_error(function()
            lurek.render.rectangle(nil, nil, nil, nil, nil)
        end)
    end)

    it("lurek.render.circle handles nil gracefully", function()
        expect_error(function()
            lurek.render.circle(nil, nil, nil, nil)
        end)
    end)

    it("lurek.render.line with nil args is silently ignored", function()
        -- Should not error — nil coords are filtered out, the draw call is just skipped
        lurek.render.line(nil, nil, nil, nil)
    end)
end)

describe("fuzz: wrong types to physics", function()
    it("lurek.physics.newWorld rejects string gravity", function()
        expect_error(function()
            lurek.physics.newWorld("hello", "world")
        end)
    end)

    it("lurek.physics.newBody rejects nil world", function()
        expect_error(function()
            lurek.physics.newBody(nil, 0, 0, "dynamic")
        end)
    end)

    it("lurek.physics.step rejects nil world", function()
        expect_error(function()
            lurek.physics.step(nil, 0.016)
        end)
    end)

    it("lurek.physics.step rejects string dt", function()
        local world = lurek.physics.newWorld(0, 10)
        expect_error(function()
            lurek.physics.step(world, "not_a_number")
        end)
        lurek.physics.destroyWorld(world)
    end)
end)

describe("fuzz: wrong types to entity system", function()
    it("universe:set with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:set(nil, "key", "value")
        end)
    end)

    it("universe:get with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:get(nil, "key")
        end)
    end)

    it("universe:kill with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:kill(nil)
        end)
    end)

    it("universe:isAlive with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:isAlive(nil)
        end)
    end)
end)

describe("fuzz: wrong types to data module", function()
    it("lurek.data.encode rejects nil format", function()
        expect_error(function()
            lurek.data.encode(nil, { a = 1 })
        end)
    end)

    it("lurek.data.decode rejects nil format", function()
        expect_error(function()
            lurek.data.decode(nil, "{}")
        end)
    end)

    it("lurek.data.decode rejects malformed JSON", function()
        expect_error(function()
            lurek.data.decode("json", "{{{{not json!!!")
        end)
    end)

    it("lurek.data.compress rejects nil", function()
        expect_error(function()
            lurek.data.compress("deflate", nil)
        end)
    end)

    it("lurek.data.decompress rejects garbage", function()
        expect_error(function()
            lurek.data.decompress("deflate", "not compressed data at all!!")
        end)
    end)
end)

describe("fuzz: wrong types to AI module", function()
    it("fsm:addState with nil name", function()
        local fsm = lurek.ai.newStateMachine()
        expect_error(function()
            fsm:addState(nil, { onUpdate = function() end })
        end)
    end)

    it("fsm:forceState with non-existent state does not error", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", { onUpdate = function() end })
        -- forceState does not validate the name against registered states
        fsm:forceState("nonexistent_state_xyz")
    end)
end)

describe("fuzz: wrong types to math module", function()
    it("Vec2 rejects string args", function()
        expect_error(function()
            lurek.math.Vec2("hello", "world")
        end)
    end)

    it("sin rejects nil", function()
        expect_error(function()
            lurek.math.sin(nil)
        end)
    end)

    it("lerp rejects nil", function()
        expect_error(function()
            lurek.math.lerp(nil, nil, nil)
        end)
    end)
end)

describe("fuzz: wrong types to audio module", function()
    it("setMasterVolume rejects string", function()
        expect_error(function()
            lurek.audio.setMasterVolume("loud")
        end)
    end)

    it("setMasterVolume rejects nil", function()
        expect_error(function()
            lurek.audio.setMasterVolume(nil)
        end)
    end)
end)

describe("fuzz: edge case numbers", function()
    it("math handles very large numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e15)
            lurek.math.cos(1e15)
        end)
    end)

    it("math handles very small numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e-15)
            lurek.math.cos(1e-15)
        end)
    end)

    it("math handles negative zero", function()
        expect_no_error(function()
            lurek.math.sin(-0.0)
            lurek.math.sqrt(0.0)
        end)
    end)

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

describe("sandbox boundary fuzzing", function()
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

describe("validation: physics invalid args", function()
    it("rejects nil world ID", function()
        expect_error(function()
            lurek.physics.step(nil, 0.016)
        end, "nil world ID")
    end)

    it("handles negative dt without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Negative dt should not crash
        expect_no_error(function()
            lurek.physics.step(world_id, -1.0)
        end, "negative dt should not crash")
    end)

    it("handles invalid body type string", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Engine may accept or coerce invalid types
        expect_no_error(function()
            local invalid_bt = "invalid_type"
            lurek.physics.newBody(world_id, 0, 0, invalid_bt)
        end, "invalid body type should not crash")
    end)

    it("handles NaN position gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        expect_no_error(function()
            lurek.physics.newBody(world_id, 0/0, 0/0, "dynamic")
        end)
    end)

    it("handles huge velocity without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body = lurek.physics.newBody(world_id, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world_id, body, 1e10, 1e10)
            lurek.physics.step(world_id, 0.016)
        end, "huge velocity should not crash")
    end)

    it("handles destroyed world gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        lurek.physics.destroyWorld(world_id)
        -- Operations on destroyed world may not crash
        expect_no_error(function()
            lurek.physics.step(world_id, 0.016)
        end, "step on destroyed world should not crash")
    end)
end)

describe("validation: compute invalid args", function()
    it("rejects zero-dimension array", function()
        expect_error(function()
            lurek.compute.zeros({0}, "float32")
        end, "zero dimension should error")
    end)

    it("rejects negative dimension", function()
        expect_error(function()
            lurek.compute.zeros({-5}, "float32")
        end, "negative dimension should error")
    end)

    it("rejects invalid dtype string", function()
        expect_error(function()
            lurek.compute.zeros({10}, "invalid_type")
        end, "invalid dtype should error")
    end)

    it("rejects too many dimensions", function()
        expect_error(function()
            lurek.compute.zeros({2, 3, 4, 5}, "float32")
        end, "4D should error")
    end)
end)

describe("validation: dataframe invalid ops", function()
    it("rejects removing nonexistent column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("real", 0)
        expect_error(function()
            df:removeColumn("nonexistent")
        end, "remove nonexistent column should error")
    end)

    it("rejects out-of-range row access", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 1})
        expect_error(function()
            df:getValue(999, "val")
        end, "out of range row should error")
    end)

    it("rejects duplicate column names", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("name", "")
        expect_error(function()
            df:addColumn("name", "")
        end, "duplicate column should error")
    end)
end)

describe("validation: graph invalid operations", function()
    it("rejects edge with invalid node", function()
        local g = lurek.graph.newGraph()
        local n1 = g:addNode("processor", 100)
        -- Passing a number instead of node userdata should error
        expect_error(function()
            g:addEdge(n1, 999)
        end, "edge to invalid node should error")
    end)

    it("accepts negative capacity", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:addNode("processor", -1)
        end)
    end)
end)

describe("validation: entity invalid operations", function()
    it("handles kill of nonexistent entity", function()
        local universe = lurek.ecs.newUniverse()
        expect_no_error(function()
            universe:kill(99999)
        end, "kill nonexistent should not crash")
    end)

    it("handles get on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_false(universe:isAlive(id), "dead entity is not alive")
    end)

    it("handles set on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_error(function()
            universe:set(id, "comp", 42)
        end, "set on dead entity should error")
    end)
end)

describe("validation: image invalid operations", function()
    it("handles zero-size image gracefully", function()
        -- Engine may accept zero-size image without error
        expect_no_error(function()
            lurek.image.newImageData(0, 0)
        end, "zero size image should not crash")
    end)

    it("rejects loading nonexistent file", function()
        expect_error(function()
            lurek.image.newImageData("nonexistent_file.png")
        end, "nonexistent file should error")
    end)
end)

describe("validation: tilemap invalid operations", function()
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
