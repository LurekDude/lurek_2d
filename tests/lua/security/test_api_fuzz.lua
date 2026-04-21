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
    it("lurek.render.line handles nil gracefully", function()
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
            lurek.data.compress(nil)
        end)
    end)

    -- @covers lurek.data.decompress
    -- @description Uses arbitrary non-compressed bytes against decompression to ensure garbage input cannot corrupt or crash the decompressor.
    it("lurek.data.decompress rejects garbage", function()
        expect_error(function()
            lurek.data.decompress("not compressed data at all!!")
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
    it("fsm:forceState with non-existent state", function()
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
test_summary()
