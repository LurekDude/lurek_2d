-- Stealth Action Demo — top-down sneaking with guard vision cones
-- WASD to move, LShift to crouch, Escape to quit
-- Run with: cargo run -- demos/action/stealth

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local player = { x = 60, y = 60, r = 8, speed = 150, crouching = false, hidden = false, caught = false, won = false }
local guards = {}
local hideSpots = {}
local walls = {}
local exitZone = { x = 700, y = 500, w = 60, h = 60 }
local noiseRipples = {}
local alertTimer = 0

local function makeGuard(path, speed, fov, viewDist)
    return {
        x = path[1].x, y = path[1].y, angle = 0,
        path = path, pathIdx = 1, pathDir = 1, speed = speed or 60,
        fov = fov or 0.8, viewDist = viewDist or 140,
        state = "patrol", suspicion = 0, chaseTarget = nil,
    }
end

local function dist(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

local function pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

local function lineRect(x1, y1, x2, y2, rx, ry, rw, rh)
    -- simplified: check if segment endpoints are inside rect
    if pointInRect(x1, y1, rx, ry, rw, rh) or pointInRect(x2, y2, rx, ry, rw, rh) then return true end
    return false
end

-- canSee: determines whether a guard can see a target at (tx, ty).
-- The check has three layers:
--   1) Distance — target must be within guard.viewDist pixels.
--   2) Angle   — the angle from guard to target must fall within ±guard.fov radians
--                of the guard's current facing angle (guard.angle).
--                math.atan2 gives the absolute angle; the difference is normalised
--                to the (-π, π] range before comparison.
--   3) Occlusion — a simplified wall-intersection test using lineRect. Any wall
--                rectangle that the line-of-sight segment passes through blocks vision.
local function canSee(guard, tx, ty)
    local dx, dy = tx - guard.x, ty - guard.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > guard.viewDist then return false end       -- outside range
    local angleToTarget = math.atan2(dy, dx)
    local diff = angleToTarget - guard.angle
    -- Normalise angle difference to [-π, π] so a guard facing left at -π
    -- still correctly detects targets on either side of the wrap boundary.
    while diff > math.pi  do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    if math.abs(diff) > guard.fov then return false end -- outside cone
    -- Wall occlusion: if the LoS segment intersects any wall rect, vision is blocked.
    for _, w in ipairs(walls) do
        if lineRect(guard.x, guard.y, tx, ty, w.x, w.y, w.w, w.h) then return false end
    end
    return true
end

function luna.init()
    luna.window.setTitle("Stealth Action")
    luna.gfx.setBackgroundColor(0.1, 0.12, 0.1)

    -- walls
    walls = {
        { x = 200, y = 100, w = 20, h = 200 },
        { x = 400, y = 0,   w = 20, h = 300 },
        { x = 300, y = 350, w = 200, h = 20 },
        { x = 550, y = 200, w = 20, h = 250 },
        { x = 100, y = 400, w = 200, h = 20 },
    }

    -- hide spots
    hideSpots = {
        { x = 50,  y = 300, w = 50, h = 50 },
        { x = 250, y = 150, w = 50, h = 50 },
        { x = 450, y = 400, w = 60, h = 50 },
        { x = 620, y = 100, w = 50, h = 50 },
    }

    -- guards
    guards = {
        makeGuard({ {x=300, y=80}, {x=300, y=280} }, 50, 0.7, 130),
        makeGuard({ {x=500, y=320}, {x=500, y=500} }, 55, 0.9, 150),
        makeGuard({ {x=150, y=480}, {x=350, y=480} }, 45, 0.6, 120),
        makeGuard({ {x=650, y=250}, {x=650, y=450} }, 60, 0.8, 140),
    }
end

local function resetLevel()
    player.x, player.y = 60, 60
    player.caught = false
    player.won = false
    player.crouching = false
    for _, g in ipairs(guards) do
        g.x, g.y = g.path[1].x, g.path[1].y
        g.pathIdx, g.pathDir = 1, 1
        g.state = "patrol"
        g.suspicion = 0
    end
    noiseRipples = {}
end

function luna.process(dt)
    if player.caught or player.won then return end

    -- player movement
    local speed = player.speed
    player.crouching = luna.keyboard.isDown("lshift")
    if player.crouching then speed = speed * 0.4 end
    local dx, dy = 0, 0
    if luna.keyboard.isDown("w") then dy = -1 end
    if luna.keyboard.isDown("s") then dy = 1 end
    if luna.keyboard.isDown("a") then dx = -1 end
    if luna.keyboard.isDown("d") then dx = 1 end
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
        local nx = player.x + dx * speed * dt
        local ny = player.y + dy * speed * dt
        -- wall collision
        local blocked = false
        for _, w in ipairs(walls) do
            if pointInRect(nx, ny, w.x - player.r, w.y - player.r, w.w + player.r * 2, w.h + player.r * 2) then
                blocked = true
            end
        end
        if not blocked then
            player.x = clamp(nx, player.r, 800 - player.r)
            player.y = clamp(ny, player.r, 600 - player.r)
        end
        -- noise when running
        if not player.crouching then
            alertTimer = alertTimer + dt
            if alertTimer > 0.5 then
                alertTimer = 0
                table.insert(noiseRipples, { x = player.x, y = player.y, r = 0, maxR = 60, alpha = 0.6 })
            end
        end
    end

    -- check if hidden
    player.hidden = false
    for _, hs in ipairs(hideSpots) do
        if pointInRect(player.x, player.y, hs.x, hs.y, hs.w, hs.h) then
            player.hidden = true
        end
    end

    -- check win
    if pointInRect(player.x, player.y, exitZone.x, exitZone.y, exitZone.w, exitZone.h) then
        player.won = true
        return
    end

    -- update noise ripples
    for i = #noiseRipples, 1, -1 do
        local nr = noiseRipples[i]
        nr.r = nr.r + dt * 100
        nr.alpha = nr.alpha - dt * 1.2
        if nr.alpha <= 0 then table.remove(noiseRipples, i) end
    end

    -- update guards
    for _, g in ipairs(guards) do
        if g.state == "patrol" then
            local target = g.path[g.pathIdx]
            local d = dist(g.x, g.y, target.x, target.y)
            if d < 3 then
                g.pathIdx = g.pathIdx + g.pathDir
                if g.pathIdx > #g.path then g.pathIdx = #g.path; g.pathDir = -1 end
                if g.pathIdx < 1 then g.pathIdx = 1; g.pathDir = 1 end
            else
                local tdx, tdy = target.x - g.x, target.y - g.y
                local tlen = math.sqrt(tdx * tdx + tdy * tdy)
                g.x = g.x + (tdx / tlen) * g.speed * dt
                g.y = g.y + (tdy / tlen) * g.speed * dt
                g.angle = math.atan2(tdy, tdx)
            end
            -- detection
            if not player.hidden and canSee(g, player.x, player.y) then
                local detRadius = player.crouching and 60 or 999
                if dist(g.x, g.y, player.x, player.y) < detRadius or not player.crouching then
                    g.suspicion = g.suspicion + dt * 2
                end
                if g.suspicion > 1.5 then
                    g.state = "chase"
                end
            else
                g.suspicion = clamp(g.suspicion - dt * 0.5, 0, 2)
            end

        elseif g.state == "chase" then
            local cdx, cdy = player.x - g.x, player.y - g.y
            local cd = math.sqrt(cdx * cdx + cdy * cdy)
            if cd > 1 then
                g.x = g.x + (cdx / cd) * g.speed * 1.4 * dt
                g.y = g.y + (cdy / cd) * g.speed * 1.4 * dt
                g.angle = math.atan2(cdy, cdx)
            end
            if cd < 15 then player.caught = true end
            if player.hidden or cd > 250 then
                g.state = "patrol"
                g.suspicion = 0
            end
        end
    end
end

function luna.render()
    -- hide spots
    for _, hs in ipairs(hideSpots) do
        luna.gfx.setColor(0.05, 0.08, 0.05, 1)
        luna.gfx.rectangle("fill", hs.x, hs.y, hs.w, hs.h)
        luna.gfx.setColor(0.2, 0.3, 0.2, 1)
        luna.gfx.rectangle("line", hs.x, hs.y, hs.w, hs.h)
    end

    -- walls
    for _, w in ipairs(walls) do
        luna.gfx.setColor(0.35, 0.3, 0.25, 1)
        luna.gfx.rectangle("fill", w.x, w.y, w.w, w.h)
    end

    -- exit zone
    luna.gfx.setColor(0.2, 0.8, 0.2, 0.5)
    luna.gfx.rectangle("fill", exitZone.x, exitZone.y, exitZone.w, exitZone.h)
    luna.gfx.setColor(0.2, 1, 0.2, 1)
    luna.gfx.rectangle("line", exitZone.x, exitZone.y, exitZone.w, exitZone.h)
    luna.gfx.print("EXIT", exitZone.x + 8, exitZone.y + 20)

    -- guard vision cones
    for _, g in ipairs(guards) do
        local segments = 12
        local step = (g.fov * 2) / segments
        local r, gr, b = 1, 1, 0
        local a = 0.12
        if g.state == "chase" then r, gr, b, a = 1, 0, 0, 0.2
        elseif g.suspicion > 0.5 then r, gr, b, a = 1, 0.5, 0, 0.15 end
        luna.gfx.setColor(r, gr, b, a)
        for i = 0, segments - 1 do
            local a1 = g.angle - g.fov + step * i
            local a2 = g.angle - g.fov + step * (i + 1)
            local verts = {
                g.x, g.y,
                g.x + math.cos(a1) * g.viewDist, g.y + math.sin(a1) * g.viewDist,
                g.x + math.cos(a2) * g.viewDist, g.y + math.sin(a2) * g.viewDist,
            }
            luna.gfx.polygon("fill", verts)
        end
    end

    -- noise ripples
    for _, nr in ipairs(noiseRipples) do
        luna.gfx.setColor(1, 1, 0.5, nr.alpha * 0.3)
        luna.gfx.circle("line", nr.x, nr.y, nr.r)
    end

    -- guards
    for _, g in ipairs(guards) do
        if g.state == "chase" then
            luna.gfx.setColor(1, 0.1, 0.1, 1)
        elseif g.suspicion > 0.5 then
            luna.gfx.setColor(1, 0.6, 0.1, 1)
        else
            luna.gfx.setColor(0.8, 0.8, 0.2, 1)
        end
        luna.gfx.circle("fill", g.x, g.y, 10)
        -- direction indicator
        luna.gfx.setColor(1, 1, 1, 0.8)
        luna.gfx.line(g.x, g.y, g.x + math.cos(g.angle) * 14, g.y + math.sin(g.angle) * 14)
    end

    -- player
    local pa = player.hidden and 0.4 or 1
    local pr = player.crouching and 5 or player.r
    luna.gfx.setColor(0.2, 0.6, 1, pa)
    luna.gfx.circle("fill", player.x, player.y, pr)
    if player.crouching then
        luna.gfx.setColor(0.4, 0.8, 1, 0.3)
        luna.gfx.circle("line", player.x, player.y, 12)
    end

    -- HUD
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print(player.crouching and "CROUCHING" or "STANDING", 10, 10)
    if player.hidden then
        luna.gfx.setColor(0.3, 1, 0.3, 1)
        luna.gfx.print("HIDDEN", 10, 30)
    end
    luna.gfx.setColor(1, 1, 1, 0.5)
    luna.gfx.print("WASD: Move  |  LShift: Crouch  |  R: Reset", 10, 575)

    -- game over / win
    if player.caught then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 250, 250, 300, 80)
        luna.gfx.setColor(1, 0.2, 0.2, 1)
        luna.gfx.print("CAUGHT! Press R to retry", 290, 280, 1.2)
    end
    if player.won then
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 250, 250, 300, 80)
        luna.gfx.setColor(0.2, 1, 0.2, 1)
        luna.gfx.print("ESCAPED! Press R to replay", 285, 280, 1.2)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then resetLevel() end
end
