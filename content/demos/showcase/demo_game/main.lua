-- Shooting Gallery -- Lurek2D demo game
-- Physics shooter: aim with the mouse, click to fire balls at targets.
-- Demonstrates: physics, raycast, collision events, shapes, input, text rendering.
-- Run with: cargo run -- content/demos/showcase/demo_game

local W, H = 800, 600
local CANNON_X, CANNON_Y = 60, 300
local MAX_BALLS = 10

local world_id
local targets = {}     -- array of {id=LuaBody, alive}
local target_ids = {}  -- body integer id -> targets index (fast lookup)
local balls = {}       -- array of active ball LuaBody objects
local score = 0

local function init_world()
    score = 0
    balls = {}
    targets = {}
    target_ids = {}

    world_id = lurek.physics.newWorld(0, 150)

    -- Ground and ceiling (layer 3 collides with all)
    local gnd = world_id:newBody(W / 2, H - 5, "static")
    world_id:addFixture(gnd:getId(), "rectangle", 1, 0.3, 0, false, W, 10)
    gnd:setLayer(3); gnd:setMask(3)

    local ceil = world_id:newBody(W / 2, 5, "static")
    world_id:addFixture(ceil:getId(), "rectangle", 1, 0.3, 0, false, W, 10)
    ceil:setLayer(3); ceil:setMask(3)

    -- Right catch-wall (keeps balls from escaping)
    local rwall = world_id:newBody(W - 5, H / 2, "static")
    world_id:addFixture(rwall:getId(), "rectangle", 1, 0.3, 0, false, 10, H)
    rwall:setLayer(3); rwall:setMask(3)

    -- 5 targets spaced down the right side (layer 2, hit by balls on layer 1)
    for i = 1, 5 do
        local ty = 80 + (i - 1) * 100
        local body = world_id:newBody(720, ty, "static")
        world_id:addFixture(body:getId(), "rectangle", 1, 0.3, 0, false, 30, 70)
        body:setLayer(2); body:setMask(3)
        local entry = { id = body, alive = true }
        table.insert(targets, entry)
        target_ids[body:getId()] = #targets
    end
end

function lurek.init()
    lurek.window.setTitle("Shooting Gallery -- Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.15)
    init_world()
end

function lurek.process(dt)
    world_id:step(dt)

    -- Collision: ball (layer 1) hits target (layer 2)?
    local collisions = world_id:getCollisionEvents()
    for _, c in ipairs(collisions) do
        for _, bid in ipairs(balls) do
            local bid_int = bid:getId()
            if c.bodyA == bid_int or c.bodyB == bid_int then
                local other = (c.bodyA == bid_int) and c.bodyB or c.bodyA
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
        local bx, by = bid:getPosition()
        if bx > -100 and bx < W + 100 and by > -100 and by < H + 100 then
            table.insert(live, bid)
        end
    end
    balls = live
end

function lurek.mousepressed(x, y, btn)
    if btn ~= 1 then return end

    -- Enforce ball limit by dropping tracking on the oldest
    if #balls >= MAX_BALLS then
        table.remove(balls, 1)
    end

    local dx = x - CANNON_X
    local dy = y - CANNON_Y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 1 then return end

    local bid = world_id:newCircleBody(CANNON_X, CANNON_Y, 12, "dynamic")
    bid:setRestitution(0.3)
    bid:setLayer(1); bid:setMask(3)
    bid:setVelocity(500 * dx / dist, 500 * dy / dist)
    table.insert(balls, bid)
end

function lurek.keypressed(key)
    if key == "space" then
        init_world()
    end
    if key == "escape" then
        lurek.signal.quit()
    end
end

function lurek.render()
    local mx, my = lurek.mouse.getPosition()

    -- Walls (visual borders)
    lurek.render.setColor(0.15, 0.25, 0.45)
    lurek.render.rectangle("fill", 0, 0, W, 10)
    lurek.render.rectangle("fill", 0, H - 10, W, 10)

    -- Aim ray (raycast from cannon toward mouse)
    local dx = mx - CANNON_X
    local dy = my - CANNON_Y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 1 then
        local ux, uy = dx / dist, dy / dist
        local ex = CANNON_X + ux * 900
        local ey = CANNON_Y + uy * 900
        lurek.render.setLineWidth(1)
        local hit = world_id:raycast(CANNON_X, CANNON_Y, ex, ey)
        if hit then
            lurek.render.setColor(1.0, 1.0, 0.2, 0.55)
            lurek.render.line(CANNON_X, CANNON_Y, hit.x, hit.y)
            lurek.render.setColor(1.0, 0.6, 0.0)
            lurek.render.circle("fill", hit.x, hit.y, 5)
        else
            lurek.render.setColor(1.0, 1.0, 0.2, 0.2)
            lurek.render.line(CANNON_X, CANNON_Y, ex, ey)
        end
    end

    -- Targets
    for _, t in ipairs(targets) do
        local tx, ty = t.id:getPosition()
        if t.alive then
            lurek.render.setColor(0.85, 0.18, 0.18)
            lurek.render.rectangle("fill", tx - 15, ty - 35, 30, 70)
            lurek.render.setColor(1.0, 0.5, 0.5)
            lurek.render.rectangle("line", tx - 15, ty - 35, 30, 70)
        else
            lurek.render.setColor(0.22, 0.22, 0.22)
            lurek.render.rectangle("fill", tx - 15, ty - 35, 30, 70)
        end
    end

    -- Fired balls
    for _, bid in ipairs(balls) do
        local bx, by = bid:getPosition()
        lurek.render.setColor(0.3, 0.65, 1.0)
        lurek.render.circle("fill", bx, by, 12)
        lurek.render.setColor(0.65, 0.9, 1.0)
        lurek.render.circle("line", bx, by, 12)
    end

    -- Cannon body
    lurek.render.setColor(0.55, 0.55, 0.65)
    lurek.render.rectangle("fill", CANNON_X - 22, CANNON_Y - 16, 44, 32)
    lurek.render.setColor(0.75, 0.75, 0.85)
    lurek.render.rectangle("line", CANNON_X - 22, CANNON_Y - 16, 44, 32)
    -- Barrel pointing at mouse
    if dist > 1 then
        lurek.render.setLineWidth(5)
        lurek.render.setColor(0.45, 0.45, 0.55)
        lurek.render.line(CANNON_X, CANNON_Y,
            CANNON_X + (dx / dist) * 32,
            CANNON_Y + (dy / dist) * 32)
        lurek.render.setLineWidth(1)
    end

    -- Mouse crosshair
    lurek.render.setColor(1.0, 1.0, 1.0, 0.7)
    lurek.render.line(mx - 12, my, mx + 12, my)
    lurek.render.line(mx, my - 12, mx, my + 12)

    -- HUD
    lurek.render.setColor(1.0, 1.0, 1.0)
    lurek.render.print("Score: " .. score .. " / 5", 10, 18, 2)

    lurek.render.setColor(0.55, 0.65, 0.75)
    lurek.render.print("Click = Fire    SPACE = Reset    ESC = Quit", 10, H - 28, 2)

    -- Win banner
    local all_dead = true
    for _, t in ipairs(targets) do
        if t.alive then all_dead = false; break end
    end
    if all_dead then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.55)
        lurek.render.rectangle("fill", 160, 240, 480, 90)
        lurek.render.setColor(1.0, 0.9, 0.1)
        lurek.render.print("YOU WIN!", 270, 255, 4)
        lurek.render.setColor(0.8, 0.8, 0.9)
        lurek.render.print("Press SPACE to play again", 220, 300, 2)
    end
end
