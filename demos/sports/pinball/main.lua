-- Pinball -- Physics-based pinball table
-- Left/Right arrows or Z/slash for flippers, Space to launch
-- Run with: cargo run -- demos/sports/pinball

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
    local b = world:newBody(cx, cy, "static")
    world:addFixture(b:getId(), "rectangle", 1, 0.3, 0, false, len, 6)
    return { body = b, x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function make_bumper(x, y, r)
    local b = world:newCircleBody(x, y, r, "static")
    b:setRestitution(1.8)
    return { body = b, x = x, y = y, r = r, flash = 0 }
end

local function make_target(x, y)
    local b = world:newBody(x, y, "static")
    world:addFixture(b:getId(), "rectangle", 1, 0.3, 0, false, 20, 8)
    b:setRestitution(1.2)
    return { body = b, x = x, y = y, hit = false, flash = 0 }
end

local function reset_ball()
    -- launcher slot right side
    ball_body = world:newCircleBody(W - 20, H - 80, ball_r, "dynamic")
    ball_body:setRestitution(0.4)
    state = "launch"
    launch_power = 0
end

function luna.init()
    luna.window.setTitle("Pinball")
    luna.gfx.setBackgroundColor(0.05, 0.06, 0.1)

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
    flippers.left.body = world:newBody(170, H - 40, "static")
    world:addFixture(flippers.left.body:getId(), "rectangle", 1, 0.3, 0, false, FLIPPER_LEN, 10)
    flippers.right.body = world:newBody(310, H - 40, "static")
    world:addFixture(flippers.right.body:getId(), "rectangle", 1, 0.3, 0, false, FLIPPER_LEN, 10)

    reset_ball()
end

function luna.process(dt)
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
    local bx, by = ball_body:getPosition()

    if left_active then
        local fx, fy = flippers.left.x, flippers.left.y
        local d = math.sqrt((bx - fx) * (bx - fx) + (by - fy) * (by - fy))
        if d < FLIPPER_LEN and by > fy - 20 then
            ball_body:setVelocity(-100, -500)
        end
    end

    if right_active then
        local fx, fy = flippers.right.x, flippers.right.y
        local d = math.sqrt((bx - fx) * (bx - fx) + (by - fy) * (by - fy))
        if d < FLIPPER_LEN and by > fy - 20 then
            ball_body:setVelocity(100, -500)
        end
    end

    world:step(dt)

    -- check collisions
    local cols = world:getCollisionEvents()
    for _, col in ipairs(cols) do
        local a, b = col.bodyA, col.bodyB
        for _, bump in ipairs(bumpers) do
            if a == bump.body:getId() or b == bump.body:getId() then
                score = score + 100
                bump.flash = 0.3
            end
        end
        for _, tgt in ipairs(targets) do
            if a == tgt.body:getId() or b == tgt.body:getId() then
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
    bx, by = ball_body:getPosition()
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

function luna.render()
    -- walls
    luna.gfx.setColor(0.4, 0.45, 0.6, 1)
    luna.gfx.setLineWidth(3)
    for _, w in ipairs(walls) do
        luna.gfx.line(w.x1, w.y1, w.x2, w.y2)
    end
    luna.gfx.setLineWidth(1)

    -- bumpers
    for _, bump in ipairs(bumpers) do
        if bump.flash > 0 then
            luna.gfx.setColor(1, 0.9, 0.3, 1)
        else
            luna.gfx.setColor(0.8, 0.3, 0.3, 1)
        end
        luna.gfx.circle("fill", bump.x, bump.y, bump.r)
        luna.gfx.setColor(1, 1, 1, 0.3)
        luna.gfx.circle("line", bump.x, bump.y, bump.r)
    end

    -- targets
    for _, tgt in ipairs(targets) do
        if tgt.hit then
            luna.gfx.setColor(0.3, 0.3, 0.3, 0.5)
        elseif tgt.flash > 0 then
            luna.gfx.setColor(1, 1, 0.2, 1)
        else
            luna.gfx.setColor(0.2, 0.8, 0.4, 1)
        end
        luna.gfx.rectangle("fill", tgt.x - 10, tgt.y - 4, 20, 8)
    end

    -- flippers
    local left_active = luna.keyboard.isDown("left") or luna.keyboard.isDown("z")
    local right_active = luna.keyboard.isDown("right") or luna.keyboard.isDown("/")

    luna.gfx.setColor(0.6, 0.7, 0.9, 1)
    -- left flipper
    local la = left_active and -0.4 or 0.3
    local lx1 = flippers.left.x - 10
    local lx2 = flippers.left.x + FLIPPER_LEN / 2
    local ly = flippers.left.y + la * 20
    luna.gfx.line(lx1, flippers.left.y, lx2, ly)
    luna.gfx.circle("fill", lx1, flippers.left.y, 6)
    luna.gfx.circle("fill", lx2, ly, 5)

    -- right flipper
    local ra = right_active and -0.4 or 0.3
    local rx1 = flippers.right.x + 10
    local rx2 = flippers.right.x - FLIPPER_LEN / 2
    local ry = flippers.right.y + ra * 20
    luna.gfx.line(rx1, flippers.right.y, rx2, ry)
    luna.gfx.circle("fill", rx1, flippers.right.y, 6)
    luna.gfx.circle("fill", rx2, ry, 5)

    -- ball
    if state ~= "dead" then
        local bx, by = ball_body:getPosition()
        luna.gfx.setColor(0.9, 0.9, 0.95, 1)
        luna.gfx.circle("fill", bx, by, ball_r)
        luna.gfx.setColor(1, 1, 1, 0.4)
        luna.gfx.circle("fill", bx - 2, by - 2, 3)
    end

    -- launcher power bar
    if state == "launch" then
        luna.gfx.setColor(0.2, 0.2, 0.2, 0.8)
        luna.gfx.rectangle("fill", W - 28, H - 200, 16, 150)
        luna.gfx.setColor(1, 0.4, 0.1, 1)
        local barH = (launch_power / 600) * 150
        luna.gfx.rectangle("fill", W - 28, H - 200 + 150 - barH, 16, barH)
        luna.gfx.setColor(1, 1, 1, 0.7)
        luna.gfx.print("SPACE", W - 32, H - 215, 0.6)
    end

    -- HUD
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("SCORE: " .. score, 20, 20, 1.3)
    luna.gfx.print("BALLS: " .. balls_left, 20, 50)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 20, 70, 0.8)

    -- game over
    if state == "dead" then
        luna.gfx.setColor(0, 0, 0, 0.75)
        luna.gfx.rectangle("fill", 0, 0, W, H)
        luna.gfx.setColor(1, 0.3, 0.3, 1)
        luna.gfx.print("GAME OVER", 130, 280, 3)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print("Final Score: " .. score, 180, 350, 1.5)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if state == "launch" and key == "space" then
        -- release: launch ball upward
        ball_body:setVelocity(0, -launch_power)
        state = "play"
    end
end

function luna.keyreleased(key)
    -- (handled inline above)
end
