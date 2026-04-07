-- Horde Survivor — Vampire Survivors style bullet heaven
-- WASD to move, auto-attack orbiting projectiles, collect XP, level up

local player, enemies, projectiles, xp_gems, particles
local spawn_timer, spawn_rate, game_time, kills, score
local level, xp, xp_next, paused, upgrade_choices
local W, H = 800, 600
local ARENA = { x = 0, y = 0, w = 1600, h = 1200 }
local cam = { x = 0, y = 0 }

local UPGRADES = {
    { name = "+2 Projectiles", stat = "count", val = 2 },
    { name = "+20% Speed",     stat = "speed", val = 0.2 },
    { name = "+3 Damage",      stat = "damage", val = 3 },
    { name = "+10% Orbit",     stat = "orbit", val = 15 },
    { name = "+1 Pierce",      stat = "pierce", val = 1 },
}

local function dist(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi) return clamp(v, lo, hi) end

local function spawn_enemy()
    local side = math.random(1, 4)
    local ex, ey
    if side == 1 then ex = player.x + math.random(-W, W); ey = player.y - H / 2 - 30
    elseif side == 2 then ex = player.x + math.random(-W, W); ey = player.y + H / 2 + 30
    elseif side == 3 then ex = player.x - W / 2 - 30; ey = player.y + math.random(-H, H)
    else ex = player.x + W / 2 + 30; ey = player.y + math.random(-H, H)
    end
    local hp = 3 + math.floor(game_time / 30)
    table.insert(enemies, { x = ex, y = ey, hp = hp, max_hp = hp, r = 10, speed = 50 + math.random(0, 30) })
end

local function spawn_xp(x, y, val)
    table.insert(xp_gems, { x = x + math.random(-8, 8), y = y + math.random(-8, 8), val = val })
end

local function spawn_death_particles(x, y)
    for i = 1, 8 do
        local a = math.random() * math.pi * 2
        local spd = 60 + math.random() * 80
        table.insert(particles, { x = x, y = y, vx = math.cos(a) * spd, vy = math.sin(a) * spd, life = 0.4 })
    end
end

local function pick_upgrades()
    upgrade_choices = {}
    local pool = {}
    for i = 1, #UPGRADES do pool[i] = i end
    for i = 1, 3 do
        local idx = math.random(1, #pool)
        table.insert(upgrade_choices, UPGRADES[pool[idx]])
        table.remove(pool, idx)
    end
    paused = true
end

local function apply_upgrade(u)
    if u.stat == "count" then player.proj_count = player.proj_count + u.val
    elseif u.stat == "speed" then player.speed = player.speed * (1 + u.val)
    elseif u.stat == "damage" then player.proj_dmg = player.proj_dmg + u.val
    elseif u.stat == "orbit" then player.orbit_r = player.orbit_r + u.val
    elseif u.stat == "pierce" then player.proj_pierce = player.proj_pierce + u.val
    end
    paused = false
    upgrade_choices = nil
end

function luna.load()
    luna.window.setTitle("Horde Survivor")
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    player = { x = ARENA.w / 2, y = ARENA.h / 2, r = 12, speed = 160, hp = 100, max_hp = 100,
               proj_count = 3, proj_dmg = 5, orbit_r = 50, orbit_speed = 3, proj_pierce = 1, angle = 0 }
    enemies = {}; projectiles = {}; xp_gems = {}; particles = {}
    spawn_timer = 0; spawn_rate = 1.2; game_time = 0; kills = 0; score = 0
    level = 1; xp = 0; xp_next = 10; paused = false; upgrade_choices = nil
end

function luna.update(dt)
    if paused then return end
    game_time = game_time + dt

    -- player movement
    local dx, dy = 0, 0
    if luna.keyboard.isDown("w") then dy = -1 end
    if luna.keyboard.isDown("s") then dy = 1 end
    if luna.keyboard.isDown("a") then dx = -1 end
    if luna.keyboard.isDown("d") then dx = 1 end
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        player.x = clamp(player.x + dx / len * player.speed * dt, player.r, ARENA.w - player.r)
        player.y = clamp(player.y + dy / len * player.speed * dt, player.r, ARENA.h - player.r)
    end

    cam.x = player.x - W / 2
    cam.y = player.y - H / 2

    -- orbiting projectile positions
    -- Advance the shared orbit angle each frame, then spread N projectiles evenly around it
    player.angle = player.angle + player.orbit_speed * dt
    projectiles = {}
    for i = 1, player.proj_count do
        -- Distribute projectiles at equal angular intervals (2π / count)
        local a = player.angle + (i - 1) * (math.pi * 2 / player.proj_count)
        table.insert(projectiles, {
            x = player.x + math.cos(a) * player.orbit_r,
            y = player.y + math.sin(a) * player.orbit_r,
            r = 6, hits = 0
        })
    end

    -- enemy spawning
    spawn_timer = spawn_timer + dt
    spawn_rate = clamp(1.2 - game_time * 0.01, 0.15, 1.2)
    if spawn_timer >= spawn_rate then
        spawn_timer = 0
        local count = 1 + math.floor(game_time / 20)
        for i = 1, count do spawn_enemy() end
    end

    -- enemy movement and projectile collision
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        local dx2 = player.x - e.x; local dy2 = player.y - e.y
        local d = math.sqrt(dx2 * dx2 + dy2 * dy2)
        if d > 1 then
            e.x = e.x + dx2 / d * e.speed * dt
            e.y = e.y + dy2 / d * e.speed * dt
        end
        -- projectile hits
        for _, p in ipairs(projectiles) do
            if p.hits < player.proj_pierce and dist(e.x, e.y, p.x, p.y) < e.r + p.r then
                e.hp = e.hp - player.proj_dmg
                p.hits = p.hits + 1
            end
        end
        -- enemy death
        if e.hp <= 0 then
            kills = kills + 1; score = score + 10
            spawn_xp(e.x, e.y, 1 + math.floor(game_time / 60))
            spawn_death_particles(e.x, e.y)
            table.remove(enemies, i)
        elseif dist(e.x, e.y, player.x, player.y) < e.r + player.r then
            player.hp = player.hp - 15 * dt
        end
    end

    -- xp pickup
    for i = #xp_gems, 1, -1 do
        local g = xp_gems[i]
        local d = dist(g.x, g.y, player.x, player.y)
        if d < 80 then
            -- Magnetic XP pull: strength scales inversely with distance so gems accelerate as they approach
            local pull = 300 * dt / clamp(d, 1, 80)
            local dx3 = player.x - g.x; local dy3 = player.y - g.y
            local len = math.sqrt(dx3 * dx3 + dy3 * dy3)
            if len > 1 then g.x = g.x + dx3 / len * pull * 80; g.y = g.y + dy3 / len * pull * 80 end
        end
        if d < player.r + 6 then
            xp = xp + g.val
            table.remove(xp_gems, i)
            if xp >= xp_next then
                xp = xp - xp_next
                level = level + 1
                xp_next = math.floor(xp_next * 1.5)
                pick_upgrades()
            end
        end
    end

    -- particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end

    -- death
    if player.hp <= 0 then player.hp = 0; paused = true end
end

function luna.draw()
    local ox, oy = -cam.x, -cam.y

    -- arena border
    luna.graphics.setColor(0.2, 0.2, 0.3, 1)
    luna.graphics.rectangle("line", ARENA.x + ox, ARENA.y + oy, ARENA.w, ARENA.h)

    -- xp gems
    luna.graphics.setColor(0.2, 1, 0.4, 1)
    for _, g in ipairs(xp_gems) do
        luna.graphics.rectangle("fill", g.x + ox - 3, g.y + oy - 3, 6, 6)
    end

    -- particles
    for _, p in ipairs(particles) do
        local a = clamp(p.life / 0.4, 0, 1)
        luna.graphics.setColor(1, 0.6, 0.1, a)
        luna.graphics.circle("fill", p.x + ox, p.y + oy, 3)
    end

    -- enemies
    for _, e in ipairs(enemies) do
        luna.graphics.setColor(0.9, 0.2, 0.2, 1)
        luna.graphics.circle("fill", e.x + ox, e.y + oy, e.r)
        -- hp bar
        luna.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        luna.graphics.rectangle("fill", e.x + ox - 10, e.y + oy - e.r - 6, 20, 3)
        luna.graphics.setColor(0, 1, 0, 0.8)
        luna.graphics.rectangle("fill", e.x + ox - 10, e.y + oy - e.r - 6, 20 * (e.hp / e.max_hp), 3)
    end

    -- projectiles
    luna.graphics.setColor(0.4, 0.8, 1, 1)
    for _, p in ipairs(projectiles) do
        luna.graphics.circle("fill", p.x + ox, p.y + oy, p.r)
    end

    -- player
    luna.graphics.setColor(0.3, 0.9, 0.3, 1)
    luna.graphics.circle("fill", player.x + ox, player.y + oy, player.r)

    -- HUD
    luna.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    luna.graphics.rectangle("fill", 0, 0, W, 36)

    -- HP bar
    luna.graphics.setColor(0.3, 0.3, 0.3, 1)
    luna.graphics.rectangle("fill", 10, 8, 150, 14)
    luna.graphics.setColor(0.9, 0.2, 0.2, 1)
    luna.graphics.rectangle("fill", 10, 8, 150 * (player.hp / player.max_hp), 14)

    -- XP bar
    luna.graphics.setColor(0.3, 0.3, 0.3, 1)
    luna.graphics.rectangle("fill", 170, 8, 100, 14)
    luna.graphics.setColor(0.2, 0.8, 1, 1)
    luna.graphics.rectangle("fill", 170, 8, 100 * (xp / xp_next), 14)

    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Lv " .. level, 280, 8)
    luna.graphics.print("Kills: " .. kills, 340, 8)
    luna.graphics.print(string.format("Time: %d:%02d", math.floor(game_time / 60), math.floor(game_time) % 60), 460, 8)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), 600, 8)
    luna.graphics.print("Enemies: " .. #enemies, 680, 8)

    -- upgrade menu
    if paused and upgrade_choices then
        luna.graphics.setColor(0, 0, 0, 0.7)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 1, 0.3, 1)
        luna.graphics.print("LEVEL UP! Choose an upgrade:", 240, 180, 1.5)
        for i, u in ipairs(upgrade_choices) do
            luna.graphics.setColor(0.15, 0.15, 0.25, 0.9)
            luna.graphics.rectangle("fill", 200, 220 + i * 60, 400, 45)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print("[" .. i .. "] " .. u.name, 220, 232 + i * 60, 1.2)
        end
    elseif paused then
        luna.graphics.setColor(0, 0, 0, 0.7)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(0.9, 0.15, 0.15, 1)
        luna.graphics.print("YOU DIED", 280, 240, 3)
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Kills: " .. kills .. "  Score: " .. score .. "  Time: " .. math.floor(game_time) .. "s", 220, 320, 1.2)
        luna.graphics.print("Press R to restart", 300, 370)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if paused and upgrade_choices then
        local n = tonumber(key)
        if n and n >= 1 and n <= 3 and upgrade_choices[n] then
            apply_upgrade(upgrade_choices[n])
        end
    end
    if paused and not upgrade_choices and key == "r" then luna.load() end
end
