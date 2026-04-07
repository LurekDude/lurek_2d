-- Pinball — Physics-based pinball table
-- Left/Right arrows or Z/slash for flippers, Space to launch

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 500, 700
local world, ball_body, walls, bumpers, flippers
local score, balls_left, state, launch_power
local ball_r = 8
local FLIPPER_LEN = 60
local targets, gate_body

local function make_wall(x1, y1, x2, y2)
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    local b = luna.physics.newBody(world, cx, cy, "static")
    luna.physics.setBodySize(world, b, len, 6)
    return { body = b, x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function make_bumper(x, y, r)
    local b = luna.physics.newCircleBody(world, x, y, r, "static")
    luna.physics.setBodyRestitution(world, b, 1.8)
    return { body = b, x = x, y = y, r = r, flash = 0 }
end

local function make_target(x, y)
    local b = luna.physics.newBody(world, x, y, "static")
    luna.physics.setBodySize(world, b, 20, 8)
    luna.physics.setBodyRestitution(world, b, 1.2)
    return { body = b, x = x, y = y, hit = false, flash = 0 }
end

local function reset_ball()
    -- launcher slot right side
    ball_body = luna.physics.newCircleBody(world, W - 20, H - 80, ball_r, "dynamic")
    luna.physics.setBodyRestitution(world, ball_body, 0.4)
    state = "launch"
    launch_power = 0
end

function luna.load()
    luna.window.setTitle("Pinball")
    luna.graphics.setBackgroundColor(0.05, 0.06, 0.1)

    world = luna.physics.newWorld(0, 300)
    walls = {}
    bumpers = {}
    targets = {}
    score = 0
    balls_left = 3

    -- outer walls
    table.insert(walls, make_wall(10, 10, W - 10, 10))        -- top
    table.insert(walls, make_wall(10, 10, 10, H - 60))        -- left
    table.insert(walls, make_wall(W - 10, 10, W - 10, H - 60))-- right
    -- angled gutters
    table.insert(walls, make_wall(10, H - 60, 140, H - 20))   -- left gutter
    table.insert(walls, make_wall(W - 140, H - 20, W - 10, H - 60)) -- right gutter
    -- launcher wall
    table.insert(walls, make_wall(W - 35, 50, W - 35, H - 30))

    -- bumpers (circular)
    table.insert(bumpers, make_bumper(180, 200, 22))
    table.insert(bumpers, make_bumper(300, 180, 22))
    table.insert(bumpers, make_bumper(240, 300, 18))
    table.insert(bumpers, make_bumper(150, 380, 18))
    table.insert(bumpers, make_bumper(330, 350, 20))

    -- score targets
    table.insert(targets, make_target(100, 120))
    table.insert(targets, make_target(200, 100))
    table.insert(targets, make_target(300, 110))
    table.insert(targets, make_target(400, 130))

    -- flippers (represented as kinematic bodies)
    flippers = {
        left  = { x = 170, y = H - 40, angle = 0, body = nil },
        right = { x = 310, y = H - 40, angle = 0, body = nil },
    }
    flippers.left.body = luna.physics.newBody(world, 170, H - 40, "static")
    luna.physics.setBodySize(world, flippers.left.body, FLIPPER_LEN, 10)
    flippers.right.body = luna.physics.newBody(world, 310, H - 40, "static")
    luna.physics.setBodySize(world, flippers.right.body, FLIPPER_LEN, 10)

    reset_ball()
end

function luna.update(dt)
    if state == "dead" then return end

    -- launch power
    if state == "launch" then
        if luna.keyboard.isDown("space") then
            launch_power = clamp(launch_power + dt * 400, 0, 600)
        end
        return
    end

    -- flipper control
    local left_active = luna.keyboard.isDown("left") or luna.keyboard.isDown("z")
    local right_active = luna.keyboard.isDown("right") or luna.keyboard.isDown("/")

    -- apply flipper impulse to ball when activated
    local bx, by = luna.physics.getBody(world, ball_body)

    if left_active then
        local fx, fy = flippers.left.x, flippers.left.y
        local d = math.sqrt((bx - fx) * (bx - fx) + (by - fy) * (by - fy))
        if d < FLIPPER_LEN and by > fy - 20 then
            luna.physics.setBodyVelocity(world, ball_body, -100, -500)
        end
    end

    if right_active then
        local fx, fy = flippers.right.x, flippers.right.y
        local d = math.sqrt((bx - fx) * (bx - fx) + (by - fy) * (by - fy))
        if d < FLIPPER_LEN and by > fy - 20 then
            luna.physics.setBodyVelocity(world, ball_body, 100, -500)
        end
    end

    luna.physics.step(world, dt)

    -- check collisions
    local cols = luna.physics.getCollisions(world)
    for _, col in ipairs(cols) do
        local a, b = col.body_a, col.body_b
        for _, bump in ipairs(bumpers) do
            if a == bump.body or b == bump.body then
                score = score + 100
                bump.flash = 0.3
            end
        end
        for _, tgt in ipairs(targets) do
            if a == tgt.body or b == tgt.body then
                if not tgt.hit then
                    score = score + 500
                    tgt.hit = true
                    tgt.flash = 0.5
                end
            end
        end
    end

    -- update flashes
    for _, bump in ipairs(bumpers) do
        if bump.flash > 0 then bump.flash = bump.flash - dt end
    end
    for _, tgt in ipairs(targets) do
        if tgt.flash > 0 then tgt.flash = tgt.flash - dt end
    end

    -- ball out of bounds (drain)
    bx, by = luna.physics.getBody(world, ball_body)
    if by > H + 20 then
        balls_left = balls_left - 1
        if balls_left <= 0 then
            state = "dead"
        else
            reset_ball()
            -- reset targets
            for _, tgt in ipairs(targets) do tgt.hit = false end
        end
    end
end

function luna.draw()
    -- walls
    luna.graphics.setColor(0.4, 0.45, 0.6, 1)
    luna.graphics.setLineWidth(3)
    for _, w in ipairs(walls) do
        luna.graphics.line(w.x1, w.y1, w.x2, w.y2)
    end
    luna.graphics.setLineWidth(1)

    -- bumpers
    for _, bump in ipairs(bumpers) do
        if bump.flash > 0 then
            luna.graphics.setColor(1, 0.9, 0.3, 1)
        else
            luna.graphics.setColor(0.8, 0.3, 0.3, 1)
        end
        luna.graphics.circle("fill", bump.x, bump.y, bump.r)
        luna.graphics.setColor(1, 1, 1, 0.3)
        luna.graphics.circle("line", bump.x, bump.y, bump.r)
    end

    -- targets
    for _, tgt in ipairs(targets) do
        if tgt.hit then
            luna.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        elseif tgt.flash > 0 then
            luna.graphics.setColor(1, 1, 0.2, 1)
        else
            luna.graphics.setColor(0.2, 0.8, 0.4, 1)
        end
        luna.graphics.rectangle("fill", tgt.x - 10, tgt.y - 4, 20, 8)
    end

    -- flippers
    local left_active = luna.keyboard.isDown("left") or luna.keyboard.isDown("z")
    local right_active = luna.keyboard.isDown("right") or luna.keyboard.isDown("/")

    luna.graphics.setColor(0.6, 0.7, 0.9, 1)
    -- left flipper
    local la = left_active and -0.4 or 0.3
    local lx1 = flippers.left.x - 10
    local lx2 = flippers.left.x + FLIPPER_LEN / 2
    local ly = flippers.left.y + la * 20
    luna.graphics.line(lx1, flippers.left.y, lx2, ly)
    luna.graphics.circle("fill", lx1, flippers.left.y, 6)
    luna.graphics.circle("fill", lx2, ly, 5)

    -- right flipper
    local ra = right_active and -0.4 or 0.3
    local rx1 = flippers.right.x + 10
    local rx2 = flippers.right.x - FLIPPER_LEN / 2
    local ry = flippers.right.y + ra * 20
    luna.graphics.line(rx1, flippers.right.y, rx2, ry)
    luna.graphics.circle("fill", rx1, flippers.right.y, 6)
    luna.graphics.circle("fill", rx2, ry, 5)

    -- ball
    if state ~= "dead" then
        local bx, by = luna.physics.getBody(world, ball_body)
        luna.graphics.setColor(0.9, 0.9, 0.95, 1)
        luna.graphics.circle("fill", bx, by, ball_r)
        luna.graphics.setColor(1, 1, 1, 0.4)
        luna.graphics.circle("fill", bx - 2, by - 2, 3)
    end

    -- launcher power bar
    if state == "launch" then
        luna.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        luna.graphics.rectangle("fill", W - 28, H - 200, 16, 150)
        luna.graphics.setColor(1, 0.4, 0.1, 1)
        local barH = (launch_power / 600) * 150
        luna.graphics.rectangle("fill", W - 28, H - 200 + 150 - barH, 16, barH)
        luna.graphics.setColor(1, 1, 1, 0.7)
        luna.graphics.print("SPACE", W - 32, H - 215, 0.6)
    end

    -- HUD
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("SCORE: " .. score, 20, 20, 1.3)
    luna.graphics.print("BALLS: " .. balls_left, 20, 50)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), 20, 70, 0.8)

    -- game over
    if state == "dead" then
        luna.graphics.setColor(0, 0, 0, 0.75)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 0.3, 0.3, 1)
        luna.graphics.print("GAME OVER", 130, 280, 3)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Final Score: " .. score, 180, 350, 1.5)
        luna.graphics.print("Press R to restart", 180, 400)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then luna.load() end
end

function luna.keyreleased(key)
    if state == "launch" and key == "space" then
        luna.physics.setBodyVelocity(world, ball_body, 0, -launch_power)
        state = "play"
        launch_power = 0
    end
end
