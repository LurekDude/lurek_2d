-- Luna2D Stress Test: Particle System Burst Emission
-- Tests large particle counts and extended lifecycle simulation

describe("particle stress: burst emission", function()
    it("emits 5000 particles", function()
        local sys = luna.particle.newSystem({
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

    it("simulates 120 frames of particle lifecycle", function()
        local sys = luna.particle.newSystem({
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
        expect_true(luna.particle.isActive(sys), "system still active")
    end)

    it("stop and reset clears all particles", function()
        local sys = luna.particle.newSystem({
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
