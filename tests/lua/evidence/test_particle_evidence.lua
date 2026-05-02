-- test_evidence_particle.lua
-- Evidence test: lurek.particle API + renders particle positions to PNG
-- Produces: particle_positions.png, particle_emitter_burst.png

local OUT = "tests/output/particle/"

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

describe("Evidence: lurek.particle API + PNG visualization", function()
    -- @evidence file
    it("PNG: particle emitter positions as colored dots", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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
            local sys = lurek.particle.newSystem()
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

        lurek.image.savePNG(img, OUT .. "particle_positions.png")
    end)

    -- @evidence file
    it("PNG: burst emission visualized over time", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)
        img:fill(5, 5, 15, 255)

        local sys = lurek.particle.newSystem()
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

        lurek.image.savePNG(img, OUT .. "particle_emitter_burst.png")
    end)

    -- @evidence file
    -- warms each up, renders via toImage(), and writes the composite as a PNG.
    -- If any shape's tessellation code was deleted, its column of the output PNG would differ.
    it("PNG: new shapes rendered via toImage", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)
        img:fill(10, 10, 20, 255)

        local shapes = { "shrapnel", "ray", "puff", "ring", "capsule" }
        local cols = { 0, 50, 102, 154, 205 }
        local tile_w = 50
        local tile_h = 64

        for i, shape_name in ipairs(shapes) do
            local ps = lurek.particle.newSystem({
                maxParticles = 80,
                emissionRate = 100,
                shape = shape_name,
                lifetimeMin = 3,
                lifetimeMax = 3,
                sizeMin = 8,
                sizeMax = 12,
            })
            ps:setPosition(tile_w * 0.5, tile_h * 0.5)
            ps:start()
            ps:warmUp(0.5)
            local tile = ps:toImage(tile_w, tile_h)
            -- Blit tile into the composite image
            local ox = cols[i]
            for ty = 0, tile_h - 1 do
                for tx = 0, tile_w - 1 do
                    local r, g, b, a = tile:getPixel(tx, ty)
                    if a > 0 then
                        img:setPixel(ox + tx, ty, r, g, b, a)
                    end
                end
            end
            lurek.particle.release(ps)
        end

        lurek.image.savePNG(img, OUT .. "particle_new_shapes.png")
    end)

    -- @evidence file
    -- inward, simulates 1 second, and saves the result via toImage().
    -- If the attractor force-computation was removed, the particle distribution
    -- in the output PNG would be more spread-out.
    it("PNG: attractor pulls particles to center", function()
        local W, H = 128, 128
        local ps = lurek.particle.newSystem({
            maxParticles = 150,
            emissionRate = 200,
            shape = "circle",
            lifetimeMin = 4,
            lifetimeMax = 4,
            sizeMin = 3,
            sizeMax = 5,
            speedMin = 40,
            speedMax = 80,
        })
        ps:setPosition(64, 64)
        ps:addAttractor(64, 64, 500, 200)
        ps:start()
        -- Pre-simulate so attractor has had time to pull particles inward
        for _ = 1, 10 do
            ps:update(0.05)
        end
        local img = ps:toImage(W, H)
        lurek.image.savePNG(img, OUT .. "particle_attractor.png")
        lurek.particle.release(ps)
    end)

end)



-- ================================================================
-- Merged from: test_evidence_particle.lua
-- ================================================================

-- test_evidence_particle.lua
-- Evidence test: lurek.particle API + renders particle positions to PNG
-- Produces: particle_positions.png, particle_emitter_burst.png

local OUT = "tests/output/particle/"

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

describe("Evidence: lurek.particle API + PNG visualization", function()
    -- @evidence file
    it("PNG: particle emitter positions as colored dots", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
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
            local sys = lurek.particle.newSystem()
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

        lurek.image.savePNG(img, OUT .. "particle_positions.png")
    end)

    -- @evidence file
    it("PNG: burst emission visualized over time", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)
        img:fill(5, 5, 15, 255)

        local sys = lurek.particle.newSystem()
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

        lurek.image.savePNG(img, OUT .. "particle_emitter_burst.png")
    end)

    -- @evidence file
    -- warms each up, renders via toImage(), and writes the composite as a PNG.
    -- If any shape's tessellation code was deleted, its column of the output PNG would differ.
    it("PNG: new shapes rendered via toImage", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)
        img:fill(10, 10, 20, 255)

        local shapes = { "shrapnel", "ray", "puff", "ring", "capsule" }
        local cols = { 0, 50, 102, 154, 205 }
        local tile_w = 50
        local tile_h = 64

        for i, shape_name in ipairs(shapes) do
            local ps = lurek.particle.newSystem({
                maxParticles = 80,
                emissionRate = 100,
                shape = shape_name,
                lifetimeMin = 3,
                lifetimeMax = 3,
                sizeMin = 8,
                sizeMax = 12,
            })
            ps:setPosition(tile_w * 0.5, tile_h * 0.5)
            ps:start()
            ps:warmUp(0.5)
            local tile = ps:toImage(tile_w, tile_h)
            -- Blit tile into the composite image
            local ox = cols[i]
            for ty = 0, tile_h - 1 do
                for tx = 0, tile_w - 1 do
                    local r, g, b, a = tile:getPixel(tx, ty)
                    if a > 0 then
                        img:setPixel(ox + tx, ty, r, g, b, a)
                    end
                end
            end
            lurek.particle.release(ps)
        end

        lurek.image.savePNG(img, OUT .. "particle_new_shapes.png")
    end)

    -- @evidence file
    -- inward, simulates 1 second, and saves the result via toImage().
    -- If the attractor force-computation was removed, the particle distribution
    -- in the output PNG would be more spread-out.
    it("PNG: attractor pulls particles to center", function()
        local W, H = 128, 128
        local ps = lurek.particle.newSystem({
            maxParticles = 150,
            emissionRate = 200,
            shape = "circle",
            lifetimeMin = 4,
            lifetimeMax = 4,
            sizeMin = 3,
            sizeMax = 5,
            speedMin = 40,
            speedMax = 80,
        })
        ps:setPosition(64, 64)
        ps:addAttractor(64, 64, 500, 200)
        ps:start()
        -- Pre-simulate so attractor has had time to pull particles inward
        for _ = 1, 10 do
            ps:update(0.05)
        end
        local img = ps:toImage(W, H)
        lurek.image.savePNG(img, OUT .. "particle_attractor.png")
        lurek.particle.release(ps)
    end)

end)
test_summary()
