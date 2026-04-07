-- Tower Defense
-- Controls: Click grid to place tower, 1 for basic tower, 2 for cannon tower, N for next wave, Escape to quit
-- Stop enemies from reaching the right side!

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600
local TILE = 40
local COLS, ROWS = 20, 15
local grid = {}
local enemies = {}
local towers = {}
local projectiles = {}
local particles = {}
local cash = 100
local lives = 20
local wave = 0
local waveActive = false
local spawnTimer = 0
local spawnCount = 0
local spawnMax = 0
local towerType = "basic"
local gameOver = false

-- Path waypoints (fixed path through the grid)
local path = {
    {1, 3}, {5, 3}, {5, 7}, {10, 7}, {10, 3}, {15, 3}, {15, 11}, {19, 11}
}

local function lerpPath(t)
    -- t is 0..1 along the full path
    local totalLen = 0
    local segs = {}
    for i = 1, #path - 1 do
        local dx = (path[i+1][1] - path[i][1]) * TILE
        local dy = (path[i+1][2] - path[i][2]) * TILE
        local len = math.sqrt(dx * dx + dy * dy)
        table.insert(segs, { sx = path[i][1] * TILE + TILE/2, sy = path[i][2] * TILE + TILE/2,
                             ex = path[i+1][1] * TILE + TILE/2, ey = path[i+1][2] * TILE + TILE/2, len = len })
        totalLen = totalLen + len
    end
    local target = t * totalLen
    local acc = 0
    for _, seg in ipairs(segs) do
        if acc + seg.len >= target then
            local frac = (target - acc) / seg.len
            return lerp(seg.sx, seg.ex, frac), lerp(seg.sy, seg.ey, frac)
        end
        acc = acc + seg.len
    end
    local last = segs[#segs]
    return last.ex, last.ey
end

local function isPathTile(gx, gy)
    -- Check if tile is on or near the path
    for i = 1, #path - 1 do
        local ax, ay = path[i][1], path[i][2]
        local bx, by = path[i+1][1], path[i+1][2]
        if ax == bx then -- vertical segment
            if gx == ax and gy >= clamp(ay, 0, by < ay and by or ay) and gy <= clamp(ay, ay > by and ay or by, ROWS) then return true end
            local minY, maxY = clamp(math.floor(clamp(ay < by and ay or by, 0, ROWS)), 0, ROWS),
                               clamp(math.floor(clamp(ay > by and ay or by, 0, ROWS)), 0, ROWS)
            if gx == ax and gy >= minY and gy <= maxY then return true end
        else -- horizontal segment
            local minX, maxX = clamp(math.floor(clamp(ax < bx and ax or bx, 0, COLS)), 0, COLS),
                               clamp(math.floor(clamp(ax > bx and ax or bx, 0, COLS)), 0, COLS)
            if gy == ay and gx >= minX and gx <= maxX then return true end
        end
    end
    return false
end

function luna.init()
    luna.window.setTitle("Tower Defense")
    luna.gfx.setBackgroundColor(0.12, 0.15, 0.1)
    -- Mark path tiles
    for gx = 0, COLS - 1 do
        for gy = 0, ROWS - 1 do
            local key = gx .. "," .. gy
            grid[key] = { path = isPathTile(gx, gy), tower = false }
        end
    end
end

local function spawnEnemy()
    local hp = 5 + wave * 3
    local speed = 0.08 + wave * 0.003
    table.insert(enemies, { t = 0, speed = speed, hp = hp, maxHp = hp, reward = 5 + wave })
end

local function startWave()
    wave = wave + 1
    waveActive = true
    spawnCount = 0
    spawnMax = 5 + wave * 2
    spawnTimer = 0
end

local function distXY(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function addParticles(x, y, r, g, b, n)
    for i = 1, n do
        local a = math.random() * math.pi * 2
        local s = math.random(30, 100)
        table.insert(particles, {x=x, y=y, vx=math.cos(a)*s, vy=math.sin(a)*s, life=0.35, r=r, g=g, b=b})
    end
end

function luna.process(dt)
    if gameOver then return end

    -- Spawn enemies
    if waveActive and spawnCount < spawnMax then
        spawnTimer = spawnTimer - dt
        if spawnTimer <= 0 then
            spawnEnemy()
            spawnCount = spawnCount + 1
            spawnTimer = 0.7
        end
    end

    -- Update enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.t = e.t + e.speed * dt
        e.x, e.y = lerpPath(e.t)
        if e.t >= 1 then
            lives = lives - 1
            table.remove(enemies, i)
            if lives <= 0 then lives = 0; gameOver = true end
        elseif e.hp <= 0 then
            cash = cash + e.reward
            addParticles(e.x, e.y, 1, 0.5, 0.1, 8)
            table.remove(enemies, i)
        end
    end

    -- Check wave complete
    if waveActive and spawnCount >= spawnMax and #enemies == 0 then
        waveActive = false
    end

    -- Tower shooting
    for _, tw in ipairs(towers) do
        tw.cd = tw.cd - dt
        if tw.cd <= 0 then
            -- Find nearest enemy
            local best, bestD = nil, tw.range + 1
            for _, e in ipairs(enemies) do
                local d = distXY(tw.x, tw.y, e.x, e.y)
                if d < bestD then best = e; bestD = d end
            end
            if best then
                local angle = math.atan2(best.y - tw.y, best.x - tw.x)
                table.insert(projectiles, {
                    x = tw.x, y = tw.y,
                    vx = math.cos(angle) * 300,
                    vy = math.sin(angle) * 300,
                    dmg = tw.dmg, life = 1.5, splash = tw.splash or 0
                })
                tw.cd = tw.fireRate
            end
        end
    end

    -- Update projectiles
    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        local hit = false
        for _, e in ipairs(enemies) do
            if distXY(p.x, p.y, e.x, e.y) < 12 then
                e.hp = e.hp - p.dmg
                -- Splash damage
                if p.splash > 0 then
                    for _, e2 in ipairs(enemies) do
                        if e2 ~= e and distXY(e.x, e.y, e2.x, e2.y) < p.splash then
                            e2.hp = e2.hp - p.dmg * 0.5
                        end
                    end
                    addParticles(p.x, p.y, 1, 0.4, 0.1, 6)
                end
                hit = true
                break
            end
        end
        if hit or p.life <= 0 then table.remove(projectiles, i) end
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

function luna.render()
    -- Grid
    for gx = 0, COLS - 1 do
        for gy = 0, ROWS - 1 do
            local key = gx .. "," .. gy
            local cell = grid[key]
            local px, py = gx * TILE, gy * TILE
            if cell and cell.path then
                luna.gfx.setColor(0.3, 0.28, 0.2, 1)
            else
                luna.gfx.setColor(0.18, 0.22, 0.14, 1)
            end
            luna.gfx.rectangle("fill", px, py, TILE, TILE)
            luna.gfx.setColor(0.1, 0.12, 0.08, 0.3)
            luna.gfx.rectangle("line", px, py, TILE, TILE)
        end
    end

    -- Towers
    for _, tw in ipairs(towers) do
        if tw.kind == "basic" then
            luna.gfx.setColor(0.3, 0.7, 0.9, 1)
        else
            luna.gfx.setColor(0.8, 0.4, 0.2, 1)
        end
        luna.gfx.rectangle("fill", tw.x - 12, tw.y - 12, 24, 24)
        luna.gfx.setColor(0.1, 0.1, 0.1, 1)
        luna.gfx.rectangle("line", tw.x - 12, tw.y - 12, 24, 24)
        -- Range indicator on hover
        local mx, my = luna.mouse.getPosition()
        if distXY(mx, my, tw.x, tw.y) < 18 then
            luna.gfx.setColor(1, 1, 1, 0.1)
            luna.gfx.circle("line", tw.x, tw.y, tw.range)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        luna.gfx.setColor(0.9, 0.2, 0.2, 1)
        luna.gfx.circle("fill", e.x, e.y, 8)
        -- HP bar
        luna.gfx.setColor(0.2, 0.2, 0.2, 1)
        luna.gfx.rectangle("fill", e.x - 10, e.y - 14, 20, 4)
        luna.gfx.setColor(0.1, 0.9, 0.1, 1)
        luna.gfx.rectangle("fill", e.x - 10, e.y - 14, 20 * (e.hp / e.maxHp), 4)
    end

    -- Projectiles
    luna.gfx.setColor(1, 1, 0.6, 1)
    for _, p in ipairs(projectiles) do
        luna.gfx.circle("fill", p.x, p.y, 3)
    end

    -- Particles
    for _, p in ipairs(particles) do
        luna.gfx.setColor(p.r, p.g, p.b, p.life * 2.5)
        luna.gfx.circle("fill", p.x, p.y, 3)
    end

    -- HUD
    luna.gfx.setColor(0, 0, 0, 0.7)
    luna.gfx.rectangle("fill", 0, H - 30, W, 30)
    luna.gfx.setColor(1, 0.85, 0.2, 1)
    luna.gfx.print("Gold: " .. cash, 10, H - 24)
    luna.gfx.setColor(1, 0.3, 0.3, 1)
    luna.gfx.print("Lives: " .. lives, 120, H - 24)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Wave: " .. wave, 230, H - 24)
    local tInfo = towerType == "basic" and "[1]Basic(20g)" or "[2]Cannon(40g)"
    luna.gfx.print(tInfo .. "  [N]NextWave", 340, H - 24)
    luna.gfx.print("FPS:" .. luna.time.getFPS(), W - 70, H - 24)

    if gameOver then
        luna.gfx.setColor(0, 0, 0, 0.6)
        luna.gfx.rectangle("fill", 250, 260, 300, 60)
        luna.gfx.setColor(1, 0.2, 0.2, 1)
        luna.gfx.print("GAME OVER — Wave " .. wave, 280, 275, 1.5)
    end
end

function luna.mousepressed(x, y, button)
    if gameOver then return end
    local gx = math.floor(x / TILE)
    local gy = math.floor(y / TILE)
    if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS then return end
    local key = gx .. "," .. gy
    local cell = grid[key]
    if not cell or cell.path or cell.tower then return end

    local cost = towerType == "basic" and 20 or 40
    if cash < cost then return end

    cash = cash - cost
    cell.tower = true
    local tw = {
        x = gx * TILE + TILE / 2,
        y = gy * TILE + TILE / 2,
        kind = towerType,
        cd = 0
    }
    if towerType == "basic" then
        tw.dmg, tw.fireRate, tw.range, tw.splash = 3, 0.5, 100, 0
    else
        tw.dmg, tw.fireRate, tw.range, tw.splash = 8, 1.5, 120, 40
    end
    table.insert(towers, tw)
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "1" then towerType = "basic" end
    if key == "2" then towerType = "cannon" end
    if key == "n" and not waveActive and not gameOver then startWave() end
end
