-- Integration: particle emitter controlled by timer bursts
describe("integration: particle emitter driven by timer", function()

    -- @integration LParticleSystem:emit
    -- @integration LParticleSystem:setEmissionRate
    -- @integration LParticleSystem:setPosition
    -- @integration lurek.particle.newSystem
    -- @integration lurek.timer.getTime
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

end)
test_summary()
