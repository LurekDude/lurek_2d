-- Endless Runner — Luna2D Demo
-- Space to jump, Down to slide, dodge obstacles, collect coins

local player, obstacles, coins, particles
local speed, score, highScore, distance
local bgLayers
local gameState -- "play", "dead"
local groundY = 500
local gravity = 1800

local function resetGame()
    player = { x = 120, y = groundY, w = 30, h = 50, vy = 0, grounded = true, sliding = false }
    obstacles = {}
    coins = {}
    particles = {}
    speed = 300
    score = 0
    distance = 0
    bgLayers = {
        { x = 0, speed = 0.2, y = 100, h = 80, color = { 0.15, 0.15, 0.3 } },
        { x = 0, speed = 0.5, y = 200, h = 60, color = { 0.1, 0.2, 0.15 } },
        { x = 0, speed = 0.8, y = 350, h = 40, color = { 0.2, 0.25, 0.1 } },
    }
    gameState = "play"
end

local function spawnObstacle()
    local kind = math.random() > 0.5 and "tall" or "low"
    if kind == "tall" then
        table.insert(obstacles, { x = 900, y = groundY - 40, w = 30, h = 40, kind = "tall" })
    else
        table.insert(obstacles, { x = 900, y = groundY - 70, w = 50, h = 20, kind = "low" })
    end
end

local function spawnCoin()
    local cy = groundY - math.random(60, 140)
    table.insert(coins, { x = 900, y = cy, r = 8, collected = false })
end

local function addParticles(px, py, r, g, b, n)
    for i = 1, n do
        local a = math.random() * 6.28
        local spd = math.random(40, 120)
        table.insert(particles, { x = px, y = py, vx = math.cos(a) * spd, vy = math.sin(a) * spd, life = 0.5, r = r, g = g, b = b })
    end
end

local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local spawnTimer = 0
local coinTimer = 0

function luna.load()
    luna.window.setTitle("Endless Runner")
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    highScore = 0
    resetGame()
end

function luna.update(dt)
    if gameState == "dead" then return end

    -- speed ramp: world accelerates continuously — eventual death is by design
    speed = 300 + distance * 0.05
    distance = distance + speed * dt
    score = math.floor(distance / 10)

    -- player input
    if luna.keyboard.isDown("space") and player.grounded then
        player.vy = -620
        player.grounded = false
    end
    player.sliding = luna.keyboard.isDown("down") and player.grounded

    -- player physics
    player.vy = player.vy + gravity * dt
    player.y = player.y + player.vy * dt
    if player.y >= groundY then
        player.y = groundY
        player.vy = 0
        player.grounded = true
    end

    local ph = player.sliding and 25 or 50
    local py = player.sliding and (groundY - 25) or (groundY - 50)

    -- spawn obstacles
    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        spawnObstacle()
        spawnTimer = math.random() * 1.2 + 0.6
    end

    -- spawn coins
    coinTimer = coinTimer - dt
    if coinTimer <= 0 then
        spawnCoin()
        coinTimer = math.random() * 0.8 + 0.4
    end

    -- move obstacles
    for i = #obstacles, 1, -1 do
        local o = obstacles[i]
        o.x = o.x - speed * dt
        if o.x + o.w < 0 then
            table.remove(obstacles, i)
        elseif rectsOverlap(player.x, py, player.w, ph, o.x, o.y, o.w, o.h) then
            gameState = "dead"
            if score > highScore then highScore = score end
            addParticles(player.x + 15, py + ph / 2, 1, 0.3, 0.2, 20)
            return
        end
    end

    -- move coins
    for i = #coins, 1, -1 do
        local c = coins[i]
        c.x = c.x - speed * dt
        if c.x < -20 then
            table.remove(coins, i)
        elseif not c.collected then
            local dx = (player.x + 15) - c.x
            local dy = (py + ph / 2) - c.y
            if math.sqrt(dx * dx + dy * dy) < c.r + 15 then
                c.collected = true
                score = score + 50
                addParticles(c.x, c.y, 1, 0.9, 0.2, 8)
                table.remove(coins, i)
            end
        end
    end

    -- bg layers: three planes at different scroll speeds create parallax depth
    for _, l in ipairs(bgLayers) do
        l.x = l.x - speed * l.speed * dt
        if l.x <= -800 then l.x = l.x + 800 end
    end

    -- particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end
end

function luna.draw()
    -- parallax bg
    for _, l in ipairs(bgLayers) do
        luna.graphics.setColor(l.color[1], l.color[2], l.color[3], 1)
        for ox = 0, 1 do
            luna.graphics.rectangle("fill", l.x + ox * 800, l.y, 810, l.h)
        end
    end

    -- ground
    luna.graphics.setColor(0.25, 0.55, 0.2, 1)
    luna.graphics.rectangle("fill", 0, groundY, 800, 100)

    -- obstacles
    for _, o in ipairs(obstacles) do
        if o.kind == "tall" then
            luna.graphics.setColor(0.7, 0.2, 0.2, 1)
        else
            luna.graphics.setColor(0.6, 0.4, 0.1, 1)
        end
        luna.graphics.rectangle("fill", o.x, o.y, o.w, o.h)
    end

    -- coins
    luna.graphics.setColor(1, 0.85, 0.1, 1)
    for _, c in ipairs(coins) do
        luna.graphics.circle("fill", c.x, c.y, c.r)
    end

    -- player
    local ph = player.sliding and 25 or 50
    local py = player.sliding and (groundY - 25) or (groundY - 50)
    luna.graphics.setColor(0.2, 0.6, 1, 1)
    luna.graphics.rectangle("fill", player.x, py, player.w, ph)
    -- eye
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.circle("fill", player.x + 22, py + 10, 4)

    -- particles
    for _, p in ipairs(particles) do
        luna.graphics.setColor(p.r, p.g, p.b, p.life * 2)
        luna.graphics.circle("fill", p.x, p.y, 3)
    end

    -- HUD
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Score: " .. score, 10, 10)
    luna.graphics.print("High: " .. highScore, 10, 30)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), 700, 10)

    if gameState == "dead" then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 200, 220, 400, 120)
        luna.graphics.setColor(1, 0.3, 0.3, 1)
        luna.graphics.print("GAME OVER", 310, 240, 1.5)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Score: " .. score, 340, 280)
        luna.graphics.print("Press SPACE to restart", 290, 310)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "space" and gameState == "dead" then resetGame() end
end
