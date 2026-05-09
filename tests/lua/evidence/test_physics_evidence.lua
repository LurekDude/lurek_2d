-- test_physics_evidence.lua
-- Clean evidence suite for physics module visual outputs.

local OUT = "tests/output/physics/"

local function clamp255(v)
    if v < 0 then return 0 end
    if v > 255 then return 255 end
    return math.floor(v)
end

local function draw_body_dot(img, world, body, r, g, b)
    local x, y = lurek.physics.getBody(world, body)
    if not x or not y then
        return
    end
    local ix = math.floor(x + 0.5)
    local iy = math.floor(y + 0.5)
    for dy = -3, 3 do
        for dx = -3, 3 do
            local px = ix + dx
            local py = iy + dy
            if px >= 0 and py >= 0 and px < 320 and py < 200 then
                img:setPixel(px, py, r, g, b, 255)
            end
        end
    end
end

-- @describe Evidence: lurek.physics visual scenarios
describe("Evidence: lurek.physics visual scenarios", function()
    before_each(function()
        ensure_evidence_dir("physics")
    end)

    -- @evidence file
    it("PNG: physics_gravity_drop.png -- dynamic bodies falling onto static ground", function()
        local world = lurek.physics.newWorld(0, 90)
        local ground = lurek.physics.newBody(world, 160, 182, "static")
        lurek.physics.attachShape(ground, lurek.physics.newRectangleShape(280, 16))

        local ball = lurek.physics.newBody(world, 110, 24, "dynamic")
        lurek.physics.attachShape(ball, lurek.physics.newCircleShape(10))

        local box = lurek.physics.newBody(world, 200, 28, "dynamic")
        lurek.physics.attachShape(box, lurek.physics.newRectangleShape(18, 18))

        for _ = 1, 120 do
            lurek.physics.step(world, 1 / 120)
        end

        local img = lurek.image.newImageData(320, 200)
        img:fill(18, 22, 34, 255)
        img:drawRect(20, 174, 280, 16, 180, 182, 188, 255)
        draw_body_dot(img, world, ball, 255, 210, 60)
        draw_body_dot(img, world, box, 70, 220, 255)

        local path = OUT .. "physics_gravity_drop.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
        lurek.physics.destroyWorld(world)
    end)

    -- @evidence file
    it("PNG: physics_velocity_tracks.png -- velocity vectors sampled over time", function()
        local world = lurek.physics.newWorld(0, 0)
        local body = lurek.physics.newBody(world, 36, 44, "dynamic")
        lurek.physics.attachShape(body, lurek.physics.newRectangleShape(14, 14))
        lurek.physics.setBodyVelocity(world, body, 70, 25)

        local points = {}
        for i = 1, 80 do
            lurek.physics.step(world, 1 / 120)
            if i % 8 == 0 then
                local x, y, vx, vy = lurek.physics.getBody(world, body)
                points[#points + 1] = { x = x, y = y, vx = vx, vy = vy }
            end
        end

        local img = lurek.image.newImageData(320, 200)
        img:fill(20, 20, 28, 255)
        for i = 2, #points do
            local a = points[i - 1]
            local b = points[i]
            img:drawLine(a.x, a.y, b.x, b.y, 160, 180, 255, 255)
        end
        for _, p in ipairs(points) do
            img:drawRect(p.x - 2, p.y - 2, 4, 4, 255, 230, 120, 255)
            img:drawLine(p.x, p.y, p.x + p.vx * 0.2, p.y + p.vy * 0.2, 120, 255, 150, 255)
        end

        local path = OUT .. "physics_velocity_tracks.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
        lurek.physics.destroyWorld(world)
    end)

    -- @evidence file
    it("PNG: physics_collision_bands.png -- collision event intensity over simulation", function()
        local world = lurek.physics.newWorld(0, 0)

        local a = lurek.physics.newBody(world, 60, 100, "dynamic")
        lurek.physics.attachShape(a, lurek.physics.newRectangleShape(16, 16))
        lurek.physics.setBodyVelocity(world, a, 48, 0)

        local b = lurek.physics.newBody(world, 260, 100, "dynamic")
        lurek.physics.attachShape(b, lurek.physics.newRectangleShape(16, 16))
        lurek.physics.setBodyVelocity(world, b, -48, 0)

        local collision_counts = {}
        for i = 1, 140 do
            lurek.physics.step(world, 1 / 120)
            local events = lurek.physics.getCollisions(world)
            collision_counts[#collision_counts + 1] = #events
        end

        local img = lurek.image.newImageData(320, 200)
        img:fill(14, 16, 24, 255)
        for i = 1, #collision_counts do
            local x = math.floor((i - 1) * 320 / #collision_counts)
            local h = math.min(90, collision_counts[i] * 16 + 2)
            img:drawRect(x, 180 - h, 2, h, 255, 120, 120, 255)
        end
        draw_body_dot(img, world, a, 250, 220, 80)
        draw_body_dot(img, world, b, 120, 220, 255)

        local path = OUT .. "physics_collision_bands.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
        lurek.physics.destroyWorld(world)
    end)

    -- @evidence file
    it("PNG: physics_query_map.png -- AABB, circle and point query map", function()
        local img = lurek.image.newImageData(320, 200)
        img:fill(24, 24, 28, 255)

        local ax, ay, aw, ah = 90, 50, 120, 80
        local bx, by, bw, bh = 150, 86, 80, 60
        local cx, cy, cr = 118, 110, 36

        img:drawRect(ax, ay, aw, ah, 70, 100, 220, 120)
        img:drawRect(bx, by, bw, bh, 220, 130, 80, 120)

        for y = 0, 199, 4 do
            for x = 0, 319, 4 do
                local inside_a = lurek.physics.testPoint(x, y, ax, ay, aw, ah)
                local hit_c = lurek.physics.testCircleAABB(cx, cy, cr, x, y, 3, 3)
                if inside_a then
                    img:drawRect(x, y, 3, 3, 120, 160, 255, 220)
                end
                if hit_c then
                    img:drawRect(x + 1, y + 1, 2, 2, 140, 255, 160, 220)
                end
            end
        end

        local overlap = lurek.physics.testAABB(ax, ay, aw, ah, bx, by, bw, bh)
        local circles = lurek.physics.testCircles(cx, cy, cr, 220, 90, 28)

        img:drawCircle(cx, cy, cr, 90, 230, 120, 255)
        img:drawCircle(220, 90, 28, 255, 190, 60, 255)
        img:drawRect(8, 8, overlap and 44 or 10, 8, 110, 200, 255, 255)
        img:drawRect(8, 20, circles and 44 or 10, 8, 255, 190, 100, 255)

        local path = OUT .. "physics_query_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("PNG: physics_sleep_flags.png -- sleeping permission states visualized", function()
        local world = lurek.physics.newWorld(0, 20)
        local a = lurek.physics.newBody(world, 90, 80, "dynamic")
        local b = lurek.physics.newBody(world, 230, 80, "dynamic")
        lurek.physics.attachShape(a, lurek.physics.newRectangleShape(20, 20))
        lurek.physics.attachShape(b, lurek.physics.newRectangleShape(20, 20))

        lurek.physics.setSleepingAllowed(world, a, true)
        lurek.physics.setSleepingAllowed(world, b, false)

        for _ = 1, 90 do
            lurek.physics.step(world, 1 / 120)
        end

        local allow_a = lurek.physics.isSleepingAllowed(world, a)
        local allow_b = lurek.physics.isSleepingAllowed(world, b)

        local img = lurek.image.newImageData(320, 200)
        img:fill(16, 20, 26, 255)
        draw_body_dot(img, world, a, 255, 205, 100)
        draw_body_dot(img, world, b, 120, 200, 255)
        img:drawRect(40, 20, allow_a and 70 or 14, 10, 240, 170, 90, 255)
        img:drawRect(180, 20, allow_b and 70 or 14, 10, 120, 200, 255, 255)

        local path = OUT .. "physics_sleep_flags.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
        lurek.physics.destroyWorld(world)
    end)
end)

test_summary()
