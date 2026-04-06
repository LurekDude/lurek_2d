-- Shooting Gallery — Luna2D demo game
-- Physics shooter: aim with the mouse, click to fire balls at targets.
-- Demonstrates: physics, raycast, collision events, shapes, input, text rendering.

local W, H = 800, 600
local CANNON_X, CANNON_Y = 60, 300
local MAX_BALLS = 10

local world_id
local targets = {}     -- array of {id, alive}
local target_ids = {}  -- body_id -> targets index (fast lookup)
local balls = {}       -- array of active ball body IDs
local score = 0

local function init_world()
    score = 0
    balls = {}
    targets = {}
    target_ids = {}

    world_id = luna.physics.newWorld(0, 150)

    -- Ground and ceiling (layer 3 collides with all)
    local gnd = luna.physics.newBody(world_id, W / 2, H - 5, "static")
    luna.physics.setBodySize(world_id, gnd, W, 10)
    luna.physics.setBodyLayer(world_id, gnd, 3, 3)

    local ceil = luna.physics.newBody(world_id, W / 2, 5, "static")
    luna.physics.setBodySize(world_id, ceil, W, 10)
    luna.physics.setBodyLayer(world_id, ceil, 3, 3)

    -- Right catch-wall (keeps balls from escaping)
    local rwall = luna.physics.newBody(world_id, W - 5, H / 2, "static")
    luna.physics.setBodySize(world_id, rwall, 10, H)
    luna.physics.setBodyLayer(world_id, rwall, 3, 3)

    -- 5 targets spaced down the right side (layer 2, hit by balls on layer 1)
    for i = 1, 5 do
        local ty = 80 + (i - 1) * 100
        local id = luna.physics.newBody(world_id, 720, ty, "static")
        luna.physics.setBodySize(world_id, id, 30, 70)
        luna.physics.setBodyLayer(world_id, id, 2, 3)
        local entry = { id = id, alive = true }
        table.insert(targets, entry)
        target_ids[id] = #targets
    end
end

function luna.load()
    luna.window.setTitle("Shooting Gallery — Luna2D")
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.15)
    init_world()
end

function luna.update(dt)
    luna.physics.step(world_id, dt)

    -- Collision: ball (layer 1) hits target (layer 2)?
    local collisions = luna.physics.getCollisions(world_id)
    for _, c in ipairs(collisions) do
        for _, bid in ipairs(balls) do
            if c.body_a == bid or c.body_b == bid then
                local other = (c.body_a == bid) and c.body_b or c.body_a
                local tidx = target_ids[other]
                if tidx and targets[tidx].alive then
                    targets[tidx].alive = false
                    score = score + 1
                end
            end
        end
    end

    -- Cull out-of-bounds balls from tracking list
    local live = {}
    for _, bid in ipairs(balls) do
        local bx, by = luna.physics.getBody(world_id, bid)
        if bx > -100 and bx < W + 100 and by > -100 and by < H + 100 then
            table.insert(live, bid)
        end
    end
    balls = live
end

function luna.mousepressed(x, y, btn)
    if btn ~= 1 then return end

    -- Enforce ball limit by dropping tracking on the oldest
    if #balls >= MAX_BALLS then
        table.remove(balls, 1)
    end

    local dx = x - CANNON_X
    local dy = y - CANNON_Y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then return end

    local bid = luna.physics.newCircleBody(world_id, CANNON_X, CANNON_Y, 12, "dynamic")
    luna.physics.setBodyRestitution(world_id, bid, 0.3)
    luna.physics.setBodyLayer(world_id, bid, 1, 3)
    luna.physics.setBodyVelocity(world_id, bid, 500 * dx / dist, 500 * dy / dist)
    table.insert(balls, bid)
end

function luna.keypressed(key)
    if key == "space" then
        init_world()
    end
    if key == "escape" then
        luna.event.quit()
    end
end

function luna.draw()
    local mx, my = luna.mouse.getPosition()

    -- Walls (visual borders)
    luna.graphics.setColor(0.15, 0.25, 0.45)
    luna.graphics.rectangle("fill", 0, 0, W, 10)
    luna.graphics.rectangle("fill", 0, H - 10, W, 10)

    -- Aim ray (raycast from cannon toward mouse)
    local dx = mx - CANNON_X
    local dy = my - CANNON_Y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 1 then
        local ux, uy = dx / dist, dy / dist
        local ex = CANNON_X + ux * 900
        local ey = CANNON_Y + uy * 900
        luna.graphics.setLineWidth(1)
        local hit = luna.physics.raycast(world_id, CANNON_X, CANNON_Y, ex, ey)
        if hit then
            luna.graphics.setColor(1.0, 1.0, 0.2, 0.55)
            luna.graphics.line(CANNON_X, CANNON_Y, hit.x, hit.y)
            luna.graphics.setColor(1.0, 0.6, 0.0)
            luna.graphics.circle("fill", hit.x, hit.y, 5)
        else
            luna.graphics.setColor(1.0, 1.0, 0.2, 0.2)
            luna.graphics.line(CANNON_X, CANNON_Y, ex, ey)
        end
    end

    -- Targets
    for _, t in ipairs(targets) do
        local tx, ty = luna.physics.getBody(world_id, t.id)
        if t.alive then
            luna.graphics.setColor(0.85, 0.18, 0.18)
            luna.graphics.rectangle("fill", tx - 15, ty - 35, 30, 70)
            luna.graphics.setColor(1.0, 0.5, 0.5)
            luna.graphics.rectangle("line", tx - 15, ty - 35, 30, 70)
        else
            luna.graphics.setColor(0.22, 0.22, 0.22)
            luna.graphics.rectangle("fill", tx - 15, ty - 35, 30, 70)
        end
    end

    -- Fired balls
    for _, bid in ipairs(balls) do
        local bx, by = luna.physics.getBody(world_id, bid)
        luna.graphics.setColor(0.3, 0.65, 1.0)
        luna.graphics.circle("fill", bx, by, 12)
        luna.graphics.setColor(0.65, 0.9, 1.0)
        luna.graphics.circle("line", bx, by, 12)
    end

    -- Cannon body
    luna.graphics.setColor(0.55, 0.55, 0.65)
    luna.graphics.rectangle("fill", CANNON_X - 22, CANNON_Y - 16, 44, 32)
    luna.graphics.setColor(0.75, 0.75, 0.85)
    luna.graphics.rectangle("line", CANNON_X - 22, CANNON_Y - 16, 44, 32)
    -- Barrel pointing at mouse
    if dist > 1 then
        luna.graphics.setLineWidth(5)
        luna.graphics.setColor(0.45, 0.45, 0.55)
        luna.graphics.line(CANNON_X, CANNON_Y,
            CANNON_X + (dx / dist) * 32,
            CANNON_Y + (dy / dist) * 32)
        luna.graphics.setLineWidth(1)
    end

    -- Mouse crosshair
    luna.graphics.setColor(1.0, 1.0, 1.0, 0.7)
    luna.graphics.line(mx - 12, my, mx + 12, my)
    luna.graphics.line(mx, my - 12, mx, my + 12)

    -- HUD
    luna.graphics.setColor(1.0, 1.0, 1.0)
    luna.graphics.print("Score: " .. score .. " / 5", 10, 18, 2)

    luna.graphics.setColor(0.55, 0.65, 0.75)
    luna.graphics.print("Click = Fire    SPACE = Reset    ESC = Quit", 10, H - 28, 2)

    -- Win banner
    local all_dead = true
    for _, t in ipairs(targets) do
        if t.alive then all_dead = false; break end
    end
    if all_dead then
        luna.graphics.setColor(0.0, 0.0, 0.0, 0.55)
        luna.graphics.rectangle("fill", 160, 240, 480, 90)
        luna.graphics.setColor(1.0, 0.9, 0.1)
        luna.graphics.print("YOU WIN!", 270, 255, 4)
        luna.graphics.setColor(0.8, 0.8, 0.9)
        luna.graphics.print("Press SPACE to play again", 220, 300, 2)
    end
end
