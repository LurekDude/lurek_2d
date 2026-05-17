-- test_render.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Security Test: API Fuzz / Nil Spam
-- Tests that core APIs handle nil, wrong types, and edge cases gracefully

-- Typed-any locals used to pass intentionally wrong values without triggering LuaLS.
local NIL = nil ---@type any
local BAD_STR_A = "hello" ---@type any
local BAD_STR_B = "world" ---@type any
local BAD_STR_DT = "not_a_number" ---@type any
local BAD_STR_LOUD = "loud" ---@type any
local BAD_TABLE = { a = 1 } ---@type any

-- @describe fuzz: nil arguments to core APIs
describe("fuzz: nil arguments to core APIs", function()
    -- @security lurek.render.setColor
    it("lurek.render.setColor handles nil gracefully", function()
        expect_error(function()
            lurek.render.setColor(NIL, NIL, NIL)
        end)
    end)

    -- @security lurek.render.rectangle
    it("lurek.render.rectangle handles nil gracefully", function()
        expect_error(function()
            lurek.render.rectangle(NIL, NIL, NIL, NIL, NIL)
        end)
    end)

    -- @security lurek.render.circle
    it("lurek.render.circle handles nil gracefully", function()
        expect_error(function()
            lurek.render.circle(NIL, NIL, NIL, NIL)
        end)
    end)

    -- @security lurek.render.line
    it("lurek.render.line with nil args is silently ignored", function()
        -- Should not error; nil coords are filtered out and draw call is skipped.
        lurek.render.line(NIL, NIL, NIL, NIL)
    end)
end)

-- @describe fuzz: wrong types to physics
describe("fuzz: wrong types to physics", function()
    -- @security lurek.physics.newWorld
    it("lurek.physics.newWorld rejects string gravity", function()
        expect_error(function()
            lurek.physics.newWorld(BAD_STR_A, BAD_STR_B)
        end)
    end)

    -- @security lurek.physics.newBody
    it("lurek.physics.newBody rejects nil world", function()
        expect_error(function()
            lurek.physics.newBody(NIL, 0, 0, "dynamic")
        end)
    end)

    -- @security lurek.physics.step
    it("lurek.physics.step rejects nil world", function()
        expect_error(function()
            lurek.physics.step(NIL, 0.016)
        end)
    end)

    -- @security lurek.physics.destroyWorld
    -- @security lurek.physics.newWorld
    -- @security lurek.physics.step
    it("lurek.physics.step rejects string dt", function()
        local world = lurek.physics.newWorld(0, 10)
        expect_error(function()
            lurek.physics.step(world, BAD_STR_DT)
        end)
        lurek.physics.destroyWorld(world)
    end)
end)

-- @describe fuzz: wrong types to entity system
describe("fuzz: wrong types to entity system", function()
    -- @security LUniverse:set
    -- @security lurek.ecs.newUniverse
    it("universe:set with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:set(NIL, "key", "value")
        end)
    end)

    -- @security LUniverse:get
    -- @security lurek.ecs.newUniverse
    it("universe:get with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:get(NIL, "key")
        end)
    end)

    -- @security LUniverse:kill
    -- @security lurek.ecs.newUniverse
    it("universe:kill with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:kill(NIL)
        end)
    end)

    -- @security LUniverse:isAlive
    -- @security lurek.ecs.newUniverse
    it("universe:isAlive with nil entity id", function()
        local universe = lurek.ecs.newUniverse()
        expect_error(function()
            universe:isAlive(NIL)
        end)
    end)
end)

-- @describe fuzz: wrong types to data module
describe("fuzz: wrong types to data module", function()
    -- @security lurek.data.encode
    it("lurek.data.encode rejects nil format", function()
        expect_error(function()
            lurek.data.encode(NIL, BAD_TABLE)
        end)
    end)

    -- @security lurek.data.decode
    it("lurek.data.decode rejects nil format", function()
        expect_error(function()
            lurek.data.decode(NIL, "{}")
        end)
    end)

    -- @security lurek.data.decode
    it("lurek.data.decode rejects malformed JSON", function()
        expect_error(function()
            lurek.data.decode("json", "{{{{not json!!!")
        end)
    end)

    -- @security lurek.data.compress
    it("lurek.data.compress rejects nil", function()
        expect_error(function()
            lurek.data.compress("deflate", NIL)
        end)
    end)

    -- @security lurek.data.decompress
    it("lurek.data.decompress rejects garbage", function()
        expect_error(function()
            lurek.data.decompress("deflate", "not compressed data at all!!")
        end)
    end)
end)

-- @describe fuzz: wrong types to AI module
describe("fuzz: wrong types to AI module", function()
    -- @security LStateMachine:addState
    -- @security lurek.ai.newStateMachine
    it("fsm:addState with nil name", function()
        local fsm = lurek.ai.newStateMachine()
        expect_error(function()
            fsm:addState(NIL, { onUpdate = function() end })
        end)
    end)

    -- @security LStateMachine:addState
    -- @security LStateMachine:forceState
    -- @security lurek.ai.newStateMachine
    it("fsm:forceState with non-existent state does not error", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", { onUpdate = function() end })
        -- forceState does not validate the name against registered states
        fsm:forceState("nonexistent_state_xyz")
    end)
end)

-- @describe fuzz: wrong types to math module
describe("fuzz: wrong types to math module", function()
    -- @security lurek.math.Vec2
    it("Vec2 rejects string args", function()
        expect_error(function()
            lurek.math.Vec2(BAD_STR_A, BAD_STR_B)
        end)
    end)

    -- @security lurek.math.sin
    it("sin rejects nil", function()
        expect_error(function()
            lurek.math.sin(NIL)
        end)
    end)

    -- @security lurek.math.lerp
    it("lerp rejects nil", function()
        expect_error(function()
            lurek.math.lerp(NIL, NIL, NIL)
        end)
    end)
end)

-- @describe fuzz: wrong types to audio module
describe("fuzz: wrong types to audio module", function()
    -- @security lurek.audio.setMasterVolume
    it("setMasterVolume rejects string", function()
        expect_error(function()
            lurek.audio.setMasterVolume(BAD_STR_LOUD)
        end)
    end)

    -- @security lurek.audio.setMasterVolume
    it("setMasterVolume rejects nil", function()
        expect_error(function()
            lurek.audio.setMasterVolume(NIL)
        end)
    end)
end)

-- @describe fuzz: edge case numbers
describe("fuzz: edge case numbers", function()
    -- @security lurek.math.cos
    -- @security lurek.math.sin
    it("math handles very large numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e15)
            lurek.math.cos(1e15)
        end)
    end)

    -- @security lurek.math.cos
    -- @security lurek.math.sin
    it("math handles very small numbers", function()
        expect_no_error(function()
            lurek.math.sin(1e-15)
            lurek.math.cos(1e-15)
        end)
    end)

    -- @security lurek.math.sin
    -- @security lurek.math.sqrt
    it("math handles negative zero", function()
        expect_no_error(function()
            lurek.math.sin(-0.0)
            lurek.math.sqrt(0.0)
        end)
    end)

    -- @security lurek.math.Vec2
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

-- @describe sandbox boundary fuzzing
describe("sandbox boundary fuzzing", function()
    -- @security fuzz.random.api_inputs
    it("handles random inputs without crashing the engine", function()
        math.randomseed(1337)

        -- Extract a few engine API tables
        local namespaces = {lurek.math, lurek.render, lurek.physics}

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

-- @describe validation: physics invalid args
describe("validation: physics invalid args", function()
    -- @security lurek.physics.step
    it("rejects nil world ID", function()
        expect_error(function()
            lurek.physics.step(NIL, 0.016)
        end, "nil world ID")
    end)

    -- @security lurek.physics.newWorld
    -- @security lurek.physics.step
    it("handles negative dt without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Negative dt should not crash
        expect_no_error(function()
            lurek.physics.step(world_id, -1.0)
        end, "negative dt should not crash")
    end)

    -- @security lurek.physics.newBody
    -- @security lurek.physics.newWorld
    it("handles invalid body type string", function()
        local world_id = lurek.physics.newWorld(0, 100)
        -- Engine may accept or coerce invalid types
        expect_no_error(function()
            local invalid_bt = "invalid_type"
            lurek.physics.newBody(world_id, 0, 0, invalid_bt)
        end, "invalid body type should not crash")
    end)

    -- @security lurek.physics.newBody
    -- @security lurek.physics.newWorld
    it("handles NaN position gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        expect_no_error(function()
            lurek.physics.newBody(world_id, 0/0, 0/0, "dynamic")
        end)
    end)

    -- @security lurek.physics.newBody
    -- @security lurek.physics.newWorld
    -- @security lurek.physics.setBodyVelocity
    -- @security lurek.physics.step
    it("handles huge velocity without crash", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body = lurek.physics.newBody(world_id, 0, 0, "dynamic")
        expect_no_error(function()
            lurek.physics.setBodyVelocity(world_id, body, 1e10, 1e10)
            lurek.physics.step(world_id, 0.016)
        end, "huge velocity should not crash")
    end)

    -- @security lurek.physics.destroyWorld
    -- @security lurek.physics.newWorld
    -- @security lurek.physics.step
    it("handles destroyed world gracefully", function()
        local world_id = lurek.physics.newWorld(0, 100)
        lurek.physics.destroyWorld(world_id)
        -- Operations on destroyed world may not crash
        expect_no_error(function()
            lurek.physics.step(world_id, 0.016)
        end, "step on destroyed world should not crash")
    end)
end)

-- @describe validation: compute invalid args
describe("validation: compute invalid args", function()
    -- @security lurek.compute.zeros
    it("rejects zero-dimension array", function()
        expect_error(function()
            lurek.compute.zeros({0}, "float32")
        end, "zero dimension should error")
    end)

    -- @security lurek.compute.zeros
    it("rejects negative dimension", function()
        expect_error(function()
            lurek.compute.zeros({-5}, "float32")
        end, "negative dimension should error")
    end)

    -- @security lurek.compute.zeros
    it("rejects invalid dtype string", function()
        expect_error(function()
            lurek.compute.zeros({10}, "invalid_type")
        end, "invalid dtype should error")
    end)

    -- @security lurek.compute.zeros
    it("accepts 4D arrays with valid dimensions", function()
        local arr = lurek.compute.zeros({2, 3, 4, 5}, "float32")
        expect_not_nil(arr)
    end)
end)

-- @describe validation: dataframe invalid ops
describe("validation: dataframe invalid ops", function()
    -- @security LDataFrame:addColumn
    -- @security LDataFrame:removeColumn
    -- @security lurek.dataframe.newDataFrame
    it("rejects removing nonexistent column", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("real", 0)
        expect_error(function()
            df:removeColumn("nonexistent")
        end, "remove nonexistent column should error")
    end)

    -- @security LDataFrame:addColumn
    -- @security LDataFrame:addRow
    -- @security LDataFrame:getValue
    -- @security lurek.dataframe.newDataFrame
    it("rejects out-of-range row access", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("val", 0)
        df:addRow({val = 1})
        expect_error(function()
            df:getValue(999, "val")
        end, "out of range row should error")
    end)

    -- @security LDataFrame:addColumn
    -- @security lurek.dataframe.newDataFrame
    it("rejects duplicate column names", function()
        local df = lurek.dataframe.newDataFrame()
        df:addColumn("name", "")
        expect_error(function()
            df:addColumn("name", "")
        end, "duplicate column should error")
    end)
end)

-- @describe validation: graph invalid operations
describe("validation: graph invalid operations", function()
    -- @security LGraph:addEdge
    -- @security LGraph:addNode
    -- @security lurek.graph.newGraph
    it("rejects edge with invalid node", function()
        local g = lurek.graph.newGraph()
        local n1 = g:addNode("processor", 100)
        -- Passing a number instead of node userdata should error
        expect_error(function()
            g:addEdge(n1, 999)
        end, "edge to invalid node should error")
    end)

    -- @security LGraph:addNode
    -- @security lurek.graph.newGraph
    it("accepts negative capacity", function()
        local g = lurek.graph.newGraph()
        expect_no_error(function()
            g:addNode("processor", -1)
        end)
    end)
end)

-- @describe validation: entity invalid operations
describe("validation: entity invalid operations", function()
    -- @security LUniverse:kill
    -- @security lurek.ecs.newUniverse
    it("handles kill of nonexistent entity", function()
        local universe = lurek.ecs.newUniverse()
        expect_no_error(function()
            universe:kill(99999)
        end, "kill nonexistent should not crash")
    end)

    -- @security LUniverse:isAlive
    -- @security LUniverse:kill
    -- @security LUniverse:spawn
    -- @security lurek.ecs.newUniverse
    it("handles get on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_false(universe:isAlive(id), "dead entity is not alive")
    end)

    -- @security LUniverse:kill
    -- @security LUniverse:set
    -- @security LUniverse:spawn
    -- @security lurek.ecs.newUniverse
    it("handles set on dead entity", function()
        local universe = lurek.ecs.newUniverse()
        local id = universe:spawn()
        universe:kill(id)
        expect_error(function()
            universe:set(id, "comp", 42)
        end, "set on dead entity should error")
    end)
end)

-- @describe validation: image invalid operations
describe("validation: image invalid operations", function()
    -- @security lurek.image.newImageData
    it("handles zero-size image gracefully", function()
        -- Engine may accept zero-size image without error
        expect_no_error(function()
            lurek.image.newImageData(0, 0)
        end, "zero size image should not crash")
    end)

    -- @security lurek.image.newImageData
    it("rejects loading nonexistent file", function()
        expect_error(function()
            lurek.image.newImageData("nonexistent_file.png")
        end, "nonexistent file should error")
    end)
end)

-- @describe validation: tilemap invalid operations
describe("validation: tilemap invalid operations", function()
    -- @security LTileMap:addLayer
    -- @security LTileMap:addTileSet
    -- @security LTileMap:getTile
    -- @security lurek.tilemap.newTileMap
    -- @security lurek.tilemap.newTileSet
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

-- @describe fuzz: P0 modules nil type extreme
describe("fuzz: P0 modules nil type extreme", function()
    -- @security lurek.data.compress
    -- @security lurek.data.decompress
    -- @security lurek.physics.newWorld
    -- @security lurek.serial.fromJson
    -- @security lurek.image.newImageData
    it("rejects hostile payloads across P0 modules without panic", function()
        expect_error(function()
            lurek.data.compress("deflate", NIL)
        end)

        expect_error(function()
            lurek.data.decompress("deflate", string.rep("x", 4096))
        end)

        expect_error(function()
            lurek.serial.fromJson(string.rep("{", 2048))
        end)

        expect_no_error(function()
            lurek.physics.newWorld(0, 1e9)
        end)

        expect_error(function()
            lurek.image.newImageData("nonexistent_p0_image.png")
        end)
    end)
end)
test_summary()


