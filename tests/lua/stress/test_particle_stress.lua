-- Lurek2D Stress Test: Particle System Burst Emission
-- Tests large particle counts and extended lifecycle simulation

-- @description Covers suite: particle stress: burst emission.
describe("particle stress: burst emission", function()
    -- @covers lurek.particle.newSystem
    -- @covers ParticleSystem:emit
    -- @covers ParticleSystem:getCount
    -- @stress Emits a single 5000-particle burst from one configured system.
    -- @description Stresses particle allocation and spawn throughput by constructing a large-capacity system and forcing a full-capacity burst emission.
    it("emits 5000 particles", function()
        local sys = lurek.particle.newSystem({
            maxParticles = 5000,
            emissionRate = 5000,
            lifetime = {2, 4},
            speed = {50, 150},
            direction = 0,
            spread = 6.28,
        })

        -- Emit burst
        sys:emit(5000)

        expect_true(sys:getCount() > 0, "particles emitted")
    end)

    -- @covers lurek.particle.newSystem
    -- @covers ParticleSystem:start
    -- @covers ParticleSystem:update
    -- @covers lurek.particle.isActive
    -- @stress Advances one live particle system for 120 fixed 60 FPS updates.
    -- @description Stresses sustained particle lifecycle stepping by running two seconds of updates on an active emitter with nontrivial lifetime and spread settings.
    it("simulates 120 frames of particle lifecycle", function()
        local sys = lurek.particle.newSystem({
            maxParticles = 2000,
            emissionRate = 100,
            lifetime = {0.5, 1.5},
            speed = {20, 80},
            direction = 0,
            spread = 3.14,
        })

        sys:start()

        -- Simulate 2 seconds at 60fps
        for frame = 1, 120 do
            sys:update(1.0 / 60.0)
        end

        -- System should still be active
        expect_true(lurek.particle.isActive(sys), "system still active")
    end)

    -- @covers lurek.particle.newSystem
    -- @covers ParticleSystem:start
    -- @covers ParticleSystem:update
    -- @covers ParticleSystem:stop
    -- @covers ParticleSystem:reset
    -- @covers ParticleSystem:getCount
    -- @stress Emits into a live system for 30 frames, then stops and resets it to clear the pool.
    -- @description Stresses particle cleanup behavior by letting a system accumulate particles before forcing a stop-plus-reset sequence and verifying the count drops to zero.
    it("stop and reset clears all particles", function()
        local sys = lurek.particle.newSystem({
            maxParticles = 1000,
            emissionRate = 500,
            lifetime = {1, 2},
            speed = {50, 100},
        })

        sys:start()
        -- Let some particles emit
        for frame = 1, 30 do
            sys:update(1.0 / 60.0)
        end

        sys:stop()
        sys:reset()

        expect_equal(0, sys:getCount(), "all particles cleared after reset")
    end)
end)
test_summary()
