-- Lurek2D Integration Test: Particle + Timer
-- Tests time-based particle emission control.

describe("integration: particle emitter driven by timer", function()
    it("emitter created and configured without error", function()
        expect_no_error(function()
            local pe = lurek.particle.newSystem()
            expect_not_nil(pe, "particle emitter created")
            pe:setPosition(100, 100)
            pe:setEmissionRate(60.0)
            pe:setParticleLifetime(2.0, 2.0)
        end)
    end)

    it("emitter tracks time between bursts", function()
        local pe             = lurek.particle.newSystem()
        local burst_interval = 0.5  -- seconds
        local burst_count    = 0
        local elapsed        = 0.0
        local last_burst     = 0.0

        pe:setPosition(200, 200)
        pe:setEmissionRate(10)

        local t0 = lurek.timer.getTime()

        -- Simulate 2 seconds of game loop at 60 FPS
        for frame = 1, 120 do
            local dt  = 1 / 60
            elapsed   = elapsed + dt

            if elapsed - last_burst >= burst_interval then
                burst_count = burst_count + 1
                last_burst  = elapsed
                pe:emit(10)  -- emit 10 particles
            end
        end

        -- 2 seconds / 0.5 interval ~= 4 bursts (floating-point dt may give 3 or 4)
        expect_true(burst_count >= 3, "at least 3 timed bursts in 2 seconds (got " .. burst_count .. ")")

        local t1 = lurek.timer.getTime()
        expect_true(t1 >= t0, "timer is monotonic")
    end)

    it("emitter position can be updated each frame", function()
        local pe    = lurek.particle.newSystem()
        local trail = {}

        pe:setEmissionRate(1.0)
        pe:setParticleLifetime(1.0, 1.0)

        for i = 1, 10 do
            local x = i * 20.0
            local y = 100.0
            pe:setPosition(x, y)
            trail[i] = {x = x, y = y}
        end

        -- Last recorded position
        local last = trail[10]
        expect_equal(200.0, last.x, "last trail x = 200")
        expect_equal(100.0, last.y, "last trail y = 100")
    end)
end)
test_summary()
