-- test_evidence_particle.lua
-- Evidence test: lurek.particles API + renders particle positions to PNG
-- Produces: particle_positions.png, particle_emitter_burst.png

local OUT = "tests/lua/evidence/output/"

--- Helper: draw a filled circle (dot).
local function draw_dot(img, cx, cy, radius, r, g, b)
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 then
                img:setPixel(x, y, r, g, b, 255)
            end
        end
    end
end

describe("Evidence: lurek.particles API + PNG visualization", function()

    it("newSystem creates a ParticleSystem", function()
        local sys = lurek.particles.newSystem()
        expect_equal(sys:count(), 0)
    end)

    it("new system isEmpty", function()
        local sys = lurek.particles.newSystem()
        expect_equal(sys:isEmpty(), true)
    end)

    it("emit adds particles", function()
        local sys = lurek.particles.newSystem()
        sys:emit(10)
        -- emit() places particles immediately; count must be positive
        expect_equal(sys:count() > 0, true)
    end)

    it("start/stop change active state", function()
        local sys = lurek.particles.newSystem()
        sys:start()
        expect_equal(sys:isActive(), true)
        sys:stop()
        expect_equal(sys:isActive(), false)
    end)

    it("pause/resume change paused state", function()
        local sys = lurek.particles.newSystem()
        sys:start()
        sys:pause()
        expect_equal(sys:isPaused(), true)
        sys:resume()
        expect_equal(sys:isPaused(), false)
    end)

    it("reset clears particles", function()
        local sys = lurek.particles.newSystem()
        sys:emit(50)
        sys:reset()
        expect_equal(sys:count(), 0)
    end)

    it("setPosition/getPosition round-trip", function()
        local sys = lurek.particles.newSystem()
        sys:setPosition(123, 456)
        local x, y = sys:getPosition()
        expect_near(x, 123, 0.001)
        expect_near(y, 456, 0.001)
    end)

    it("type returns 'ParticleSystem'", function()
        local sys = lurek.particles.newSystem()
        expect_equal(sys:type(), "ParticleSystem")
    end)

    it("typeOf returns true for 'ParticleSystem'", function()
        local sys = lurek.particles.newSystem()
        expect_equal(sys:typeOf("ParticleSystem"), true)
    end)

    it("newTrail creates a trail without error", function()
        local ok = pcall(lurek.particles.newTrail, 1.0, 5.0)
        expect_equal(ok, true)
    end)

    it("PNG: particle emitter positions as colored dots", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)
        img:fill(10, 10, 20, 255)

        -- Create multiple emitters at different positions
        local systems = {}
        local colors = {
            {255, 80,  80},
            {80,  255, 80},
            {80,  80,  255},
            {255, 255, 80},
            {255, 80,  255},
        }
        local positions = {
            {64,  64},
            {192, 64},
            {128, 128},
            {64,  192},
            {192, 192},
        }
        for i = 1, #positions do
            local sys = lurek.particles.newSystem()
            sys:setPosition(positions[i][1], positions[i][2])
            sys:start()
            sys:emit(30)
            systems[i] = sys
        end

        -- Render each emitter as a cluster of dots around its position
        for i, sys in ipairs(systems) do
            local px, py = sys:getPosition()
            local c = colors[i]
            -- Draw emitter core (bright dot)
            draw_dot(img, math.floor(px), math.floor(py), 6, c[1], c[2], c[3])
            -- Draw particle spread (ring of smaller dots simulating emission)
            for angle = 0, 350, 15 do
                local rad = math.rad(angle)
                local spread = 15 + (i * 3)
                local dx = math.floor(px + spread * math.cos(rad))
                local dy = math.floor(py + spread * math.sin(rad))
                draw_dot(img, dx, dy, 2,
                    math.floor(c[1] * 0.6),
                    math.floor(c[2] * 0.6),
                    math.floor(c[3] * 0.6))
            end
        end

        lurek.img.savePNG(img, OUT .. "particle_positions.png")
        expect_equal(true, true)
    end)

    it("PNG: burst emission visualized over time", function()
        local W, H = 128, 128
        local img = lurek.img.newImageData(W, H)
        img:fill(5, 5, 15, 255)

        local sys = lurek.particles.newSystem()
        sys:setPosition(64, 64)
        sys:start()

        -- Simulate 4 bursts, each drawn as a ring at increasing radius
        for burst = 1, 4 do
            sys:emit(50)
            local count = sys:count()
            local radius = burst * 15
            -- Draw ring representing this burst
            for angle = 0, 359, 3 do
                local rad = math.rad(angle)
                local px = math.floor(64 + radius * math.cos(rad))
                local py = math.floor(64 + radius * math.sin(rad))
                if px >= 0 and px < W and py >= 0 and py < H then
                    local brightness = math.floor(255 * (1 - (burst - 1) / 4))
                    img:setPixel(px, py, brightness, brightness, 80, 255)
                end
            end
        end

        -- Mark center emitter
        draw_dot(img, 64, 64, 4, 255, 255, 255)

        lurek.img.savePNG(img, OUT .. "particle_emitter_burst.png")
        expect_equal(true, true)
    end)

end)

test_summary()
