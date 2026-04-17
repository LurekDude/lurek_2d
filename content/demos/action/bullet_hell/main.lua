-- Bullet Hell Shooter
-- Controls: Arrow keys to move, Space to shoot, Escape to quit
-- Survive waves of enemies and their bullet patterns!
-- Run with: cargo run -- content/demos/action/bullet_hell

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local player = {}
local bullets = {}
local enemies = {}
local enemyBullets = {}
local particles = {}
local score = 0
local lives = 3
local gameOver = false
local spawnTimer = 0
local waveTimer = 0
local wave = 1
local shootTimer = 0
local W, H = 800, 600

function lurek.init()
    lurek.window.setTitle("Bullet Hell")
    lurek.render.setBackgroundColor(0.05, 0.02, 0.1)
    player.x = W / 2
    player.y = H - 60
    player.w = 20
    player.h = 24
    player.speed = 300
end

local function spawnParticles(x, y, r, g, b, count)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = math.random(40, 160)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = 0.4 + math.random() * 0.4,
            r = r, g = g, b = b
        })
    end
end

local function spawnEnemy(pattern)
    local e = {
        x = math.random(60, W - 60),
        y = -20,
        hp = 2,
        w = 28, h = 28,
        vy = 40 + math.random(0, 30),
        pattern = pattern or "aimed",
        shootTimer = 0.8 + math.random() * 0.6,
        age = 0
    }
    table.insert(enemies, e)
end

local function fireEnemyBullet(e, angle, speed)
    table.insert(enemyBullets, {
        x = e.x, y = e.y + e.h / 2,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed
    })
end

function lurek.process(dt)
    if gameOver then return end

    -- Player movement
    if lurek.keyboard.isDown("left") then player.x = player.x - player.speed * dt end
    if lurek.keyboard.isDown("right") then player.x = player.x + player.speed * dt end
    if lurek.keyboard.isDown("up") then player.y = player.y - player.speed * dt end
    if lurek.keyboard.isDown("down") then player.y = player.y + player.speed * dt end
    player.x = clamp(player.x, 10, W - 10)
    player.y = clamp(player.y, 10, H - 10)

    -- Auto-shoot
    shootTimer = shootTimer - dt
    if shootTimer <= 0 then
        table.insert(bullets, { x = player.x - 6, y = player.y - 14, vy = -500 })
        table.insert(bullets, { x = player.x + 6, y = player.y - 14, vy = -500 })
        shootTimer = 0.1
    end

    -- Update player bullets
    for i = #bullets, 1, -1 do
        bullets[i].y = bullets[i].y + bullets[i].vy * dt
        if bullets[i].y < -10 then table.remove(bullets, i) end
    end

    -- Spawn enemies
    spawnTimer = spawnTimer - dt
    if spawnTimer <= 0 then
        local patterns = { "aimed", "spiral", "wave" }
        spawnEnemy(patterns[math.random(1, #patterns)])
        spawnTimer = clamp(1.5 - wave * 0.1, 0.4, 1.5)
    end

    -- Wave progression
    waveTimer = waveTimer + dt
    if waveTimer > 15 then
        wave = wave + 1
        waveTimer = 0
    end

    -- Update enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.y = e.y + e.vy * dt
        e.age = e.age + dt
        e.shootTimer = e.shootTimer - dt

        if e.shootTimer <= 0 then
            if e.pattern == "aimed" then
                local angle = math.atan2(player.y - e.y, player.x - e.x)
                fireEnemyBullet(e, angle, 180)
            elseif e.pattern == "spiral" then
                for a = 0, 5 do
                    fireEnemyBullet(e, e.age * 3 + a * math.pi / 3, 140)
                end
            elseif e.pattern == "wave" then
                for a = -2, 2 do
                    fireEnemyBullet(e, math.pi / 2 + a * 0.3, 160)
                end
            end
            e.shootTimer = clamp(1.2 - wave * 0.05, 0.3, 1.2)
        end

        -- Bullet-enemy collision
        for j = #bullets, 1, -1 do
            local b = bullets[j]
            if math.abs(b.x - e.x) < e.w and math.abs(b.y - e.y) < e.h then
                e.hp = e.hp - 1
                table.remove(bullets, j)
                if e.hp <= 0 then
                    score = score + 100
                    spawnParticles(e.x, e.y, 1, 0.6, 0.1, 12)
                    table.remove(enemies, i)
                    break
                end
            end
        end

        if enemies[i] and enemies[i].y > H + 30 then table.remove(enemies, i) end
    end

    -- Update enemy bullets
    for i = #enemyBullets, 1, -1 do
        local b = enemyBullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        if b.x < -10 or b.x > W + 10 or b.y < -10 or b.y > H + 10 then
            table.remove(enemyBullets, i)
        elseif math.abs(b.x - player.x) < 10 and math.abs(b.y - player.y) < 12 then
            lives = lives - 1
            spawnParticles(player.x, player.y, 0.2, 0.6, 1, 16)
            table.remove(enemyBullets, i)
            if lives <= 0 then gameOver = true end
        end
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

function lurek.render()
    -- Stars background
    lurek.render.setColor(0.3, 0.3, 0.4, 0.6)
    for i = 1, 60 do
        local sx = (i * 137) % W
        local sy = ((i * 251) + lurek.time.getTime() * (20 + i % 3 * 10)) % H
        lurek.render.rectangle("fill", sx, sy, 2, 2)
    end

    -- Player
    if not gameOver then
        lurek.render.setColor(0.3, 0.7, 1, 1)
        lurek.render.polygon("fill", {
            player.x, player.y - 14,
            player.x - 10, player.y + 10,
            player.x + 10, player.y + 10
        })
    end

    -- Player bullets
    lurek.render.setColor(0.4, 1, 0.4, 1)
    for _, b in ipairs(bullets) do
        lurek.render.rectangle("fill", b.x - 2, b.y, 4, 10)
    end

    -- Enemies
    lurek.render.setColor(1, 0.3, 0.3, 1)
    for _, e in ipairs(enemies) do
        lurek.render.rectangle("fill", e.x - e.w / 2, e.y - e.h / 2, e.w, e.h)
        lurek.render.setColor(1, 0.6, 0, 1)
        lurek.render.rectangle("fill", e.x - 4, e.y - 4, 8, 8)
        lurek.render.setColor(1, 0.3, 0.3, 1)
    end

    -- Enemy bullets
    lurek.render.setColor(1, 1, 0.2, 1)
    for _, b in ipairs(enemyBullets) do
        lurek.render.circle("fill", b.x, b.y, 4)
    end

    -- Particles
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.life * 2)
        lurek.render.circle("fill", p.x, p.y, 3)
    end

    -- HUD
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Score: " .. score, 10, 10)
    lurek.render.print("Lives: " .. lives, 10, 30)
    lurek.render.print("Wave: " .. wave, 10, 50)
    lurek.render.print("FPS: " .. lurek.time.getFPS(), W - 90, 10)

    if gameOver then
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.print("GAME OVER", W / 2 - 60, H / 2 - 20, 2)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Final Score: " .. score, W / 2 - 55, H / 2 + 20)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
end
