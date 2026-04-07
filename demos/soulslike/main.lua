-- 2D Souls-like Precision Combat
-- WASD move, J=light attack, K=heavy attack, L=dodge, Space=block

local W, H = 800, 600
local player, boss, particles, shake
local state -- "play", "dead", "victory"

local function dist(a, b) return math.abs(a.x - b.x) end

local function clamp(v, lo, hi) return clamp(v, lo, hi) end

local function spawn_hit_particles(x, y, r, g, b)
    for i = 1, 6 do
        local a = math.random() * math.pi * 2
        local spd = 80 + math.random() * 120
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(a) * spd, vy = math.sin(a) * spd - 40,
            life = 0.3 + math.random() * 0.2,
            r = r, g = g, b = b
        })
    end
end

function luna.load()
    luna.window.setTitle("Soulslike Combat")
    luna.graphics.setBackgroundColor(0.08, 0.06, 0.1)

    local ground = H - 100
    player = {
        x = 200, y = ground, w = 24, h = 48,
        speed = 180, facing = 1,
        hp = 100, max_hp = 100,
        stamina = 100, max_stamina = 100, stam_regen = 30,
        -- actions
        attacking = false, atk_timer = 0, atk_dur = 0, atk_type = nil,
        dodging = false, dodge_timer = 0, dodge_dur = 0.4, dodge_dir = 0,
        blocking = false,
        iframe = false, iframe_timer = 0,
        hurt_flash = 0,
        -- attack ranges/damage
        light_range = 60, light_dmg = 8, light_dur = 0.3, light_cost = 12,
        heavy_range = 70, heavy_dmg = 18, heavy_dur = 0.6, heavy_cost = 25,
        dodge_cost = 20, block_cost_per_sec = 20,
    }

    boss = {
        x = 550, y = ground, w = 40, h = 64,
        speed = 80, facing = -1,
        hp = 300, max_hp = 300,
        phase = 1,
        -- AI state
        state = "idle", timer = 0,
        atk_type = nil, atk_timer = 0,
        telegraph_dur = 0.8, atk_dur = 0.3, recovery_dur = 1.0,
        tele_flash = 0,
        hurt_flash = 0,
    }

    particles = {}
    shake = { timer = 0, intensity = 0 }
    state = "play"
end

local function try_hit_boss(range, dmg)
    if dist(player, boss) < range then
        local multiplier = 1
        if boss.state == "recovery" then multiplier = 1.5 end
        boss.hp = boss.hp - dmg * multiplier
        boss.hurt_flash = 0.15
        spawn_hit_particles(boss.x, boss.y - boss.h / 2, 1, 0.3, 0.3)
        shake.timer = 0.12; shake.intensity = 4
        if boss.hp <= boss.max_hp * 0.5 and boss.phase == 1 then
            boss.phase = 2
            boss.speed = 130
            boss.telegraph_dur = 0.5
            boss.recovery_dur = 0.6
        end
        if boss.hp <= 0 then
            boss.hp = 0
            state = "victory"
        end
    end
end

local function boss_try_hit_player()
    if player.iframe then return end
    local range = boss.phase == 2 and 80 or 65
    if dist(player, boss) < range then
        if player.blocking and player.stamina > 0 then
            player.stamina = player.stamina - 30
            spawn_hit_particles(player.x, player.y - player.h / 2, 0.5, 0.5, 1)
            shake.timer = 0.08; shake.intensity = 2
        else
            local dmg = boss.phase == 2 and 25 or 18
            player.hp = player.hp - dmg
            player.hurt_flash = 0.2
            spawn_hit_particles(player.x, player.y - player.h / 2, 1, 0.2, 0.2)
            shake.timer = 0.15; shake.intensity = 6
            if player.hp <= 0 then player.hp = 0; state = "dead" end
        end
    end
end

function luna.update(dt)
    if state ~= "play" then return end

    -- particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt; p.vy = p.vy + 200 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) end
    end

    -- shake
    if shake.timer > 0 then shake.timer = shake.timer - dt end

    -- flash timers
    if player.hurt_flash > 0 then player.hurt_flash = player.hurt_flash - dt end
    if boss.hurt_flash > 0 then boss.hurt_flash = boss.hurt_flash - dt end

    -- player stamina regen
    if not player.attacking and not player.dodging and not player.blocking then
        player.stamina = clamp(player.stamina + player.stam_regen * dt, 0, player.max_stamina)
    end

    -- player dodge
    if player.dodging then
        player.dodge_timer = player.dodge_timer + dt
        player.x = player.x + player.dodge_dir * 350 * dt
        player.iframe = player.dodge_timer < 0.25
        if player.dodge_timer >= player.dodge_dur then
            player.dodging = false; player.iframe = false
        end
    end

    -- player attack
    if player.attacking then
        player.atk_timer = player.atk_timer + dt
        -- hit on middle of attack
        if player.atk_timer >= player.atk_dur * 0.5 and player.atk_timer - dt < player.atk_dur * 0.5 then
            local range = player.atk_type == "light" and player.light_range or player.heavy_range
            local dmg = player.atk_type == "light" and player.light_dmg or player.heavy_dmg
            try_hit_boss(range, dmg)
        end
        if player.atk_timer >= player.atk_dur then player.attacking = false end
    end

    -- player movement (not during attack/dodge)
    if not player.attacking and not player.dodging then
        local dx = 0
        if luna.keyboard.isDown("a") then dx = -1 end
        if luna.keyboard.isDown("d") then dx = 1 end
        if dx ~= 0 then
            player.x = clamp(player.x + dx * player.speed * dt, 30, W - 30)
            player.facing = dx
        end
        -- block
        player.blocking = luna.keyboard.isDown("space") and player.stamina > 0
        if player.blocking then
            player.stamina = clamp(player.stamina - player.block_cost_per_sec * dt, 0, player.max_stamina)
        end
    end

    -- boss AI
    boss.facing = player.x < boss.x and -1 or 1
    boss.timer = boss.timer + dt

    if boss.state == "idle" then
        -- approach player
        local d = dist(player, boss)
        if d > 70 then
            boss.x = boss.x + boss.facing * boss.speed * dt
        end
        local approach_time = boss.phase == 2 and 1.0 or 1.8
        if boss.timer > approach_time then
            boss.state = "telegraph"
            boss.timer = 0
            boss.atk_type = (boss.phase == 2 and math.random() > 0.5) and "heavy" or "light"
        end
    elseif boss.state == "telegraph" then
        boss.tele_flash = math.sin(boss.timer * 20) * 0.5 + 0.5
        if boss.timer >= boss.telegraph_dur then
            boss.state = "attack"
            boss.timer = 0
            boss.tele_flash = 0
        end
    elseif boss.state == "attack" then
        if boss.timer < 0.05 then
            -- lunge
            boss.x = boss.x + boss.facing * 100
            boss_try_hit_player()
        end
        if boss.timer >= boss.atk_dur then
            boss.state = "recovery"
            boss.timer = 0
        end
    elseif boss.state == "recovery" then
        if boss.timer >= boss.recovery_dur then
            boss.state = "idle"
            boss.timer = 0
        end
    end

    boss.x = clamp(boss.x, 50, W - 50)
    player.x = clamp(player.x, 30, W - 30)
end

local function draw_bar(x, y, w, h, val, max, r, g, b)
    luna.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    luna.graphics.rectangle("fill", x, y, w, h)
    luna.graphics.setColor(r, g, b, 1)
    luna.graphics.rectangle("fill", x, y, w * clamp(val / max, 0, 1), h)
    luna.graphics.setColor(1, 1, 1, 0.3)
    luna.graphics.rectangle("line", x, y, w, h)
end

function luna.draw()
    local sx, sy = 0, 0
    if shake.timer > 0 then
        sx = (math.random() - 0.5) * shake.intensity * 2
        sy = (math.random() - 0.5) * shake.intensity * 2
    end

    -- ground
    local ground = player.y
    luna.graphics.setColor(0.15, 0.12, 0.18, 1)
    luna.graphics.rectangle("fill", sx, ground + sy, W, H - ground)
    luna.graphics.setColor(0.3, 0.25, 0.35, 1)
    luna.graphics.line(0 + sx, ground + sy, W + sx, ground + sy)

    -- arena pillars
    luna.graphics.setColor(0.2, 0.18, 0.25, 0.6)
    luna.graphics.rectangle("fill", 60 + sx, ground - 120 + sy, 16, 120)
    luna.graphics.rectangle("fill", W - 76 + sx, ground - 120 + sy, 16, 120)

    -- particles
    for _, p in ipairs(particles) do
        local a = clamp(p.life / 0.3, 0, 1)
        luna.graphics.setColor(p.r, p.g, p.b, a)
        luna.graphics.circle("fill", p.x + sx, p.y + sy, 3)
    end

    -- boss
    local br, bg, bb = 0.7, 0.15, 0.15
    if boss.hurt_flash > 0 then br, bg, bb = 1, 1, 1 end
    if boss.tele_flash > 0.3 then br, bg, bb = 1, 0.5, 0.1 end
    if boss.state == "recovery" then br, bg, bb = 0.4, 0.15, 0.15 end
    luna.graphics.setColor(br, bg, bb, 1)
    luna.graphics.rectangle("fill", boss.x - boss.w / 2 + sx, boss.y - boss.h + sy, boss.w, boss.h)
    -- boss eyes
    luna.graphics.setColor(1, 0.3, 0.1, 1)
    local eye_x = boss.x + boss.facing * 8
    luna.graphics.circle("fill", eye_x + sx, boss.y - boss.h + 16 + sy, 4)

    -- player
    local pr, pg, pb = 0.3, 0.6, 0.9
    if player.hurt_flash > 0 then pr, pg, pb = 1, 0.3, 0.3 end
    if player.iframe then pr, pg, pb = 0.7, 0.7, 1 end
    if player.blocking then pr, pg, pb = 0.4, 0.8, 0.4 end
    luna.graphics.setColor(pr, pg, pb, player.iframe and 0.5 or 1)
    luna.graphics.rectangle("fill", player.x - player.w / 2 + sx, player.y - player.h + sy, player.w, player.h)

    -- attack slash visual
    if player.attacking and player.atk_timer < player.atk_dur * 0.7 then
        local range = player.atk_type == "light" and player.light_range or player.heavy_range
        local alpha = 1 - player.atk_timer / player.atk_dur
        luna.graphics.setColor(1, 0.9, 0.5, alpha * 0.6)
        local ax = player.x + player.facing * range / 2
        luna.graphics.rectangle("fill", ax - range / 2 + sx, player.y - player.h + 10 + sy, range, 30)
    end

    -- HUD — player bars
    draw_bar(20, 20, 200, 16, player.hp, player.max_hp, 0.8, 0.2, 0.2)
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("HP", 24, 21, 0.8)

    draw_bar(20, 42, 200, 12, player.stamina, player.max_stamina, 0.2, 0.7, 0.3)
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("ST", 24, 42, 0.7)

    -- HUD — boss bar
    draw_bar(W / 2 - 150, H - 50, 300, 20, boss.hp, boss.max_hp, 0.7, 0.15, 0.15)
    luna.graphics.setColor(1, 1, 1, 1)
    local boss_name = boss.phase == 2 and "WARDEN (Enraged)" or "WARDEN"
    luna.graphics.print(boss_name, W / 2 - 60, H - 48, 0.9)

    -- controls hint
    luna.graphics.setColor(1, 1, 1, 0.4)
    luna.graphics.print("A/D: Move  J: Light  K: Heavy  L: Dodge  Space: Block", 150, H - 20, 0.7)

    -- death / victory overlay
    if state == "dead" then
        luna.graphics.setColor(0, 0, 0, 0.8)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(0.8, 0.1, 0.1, 1)
        luna.graphics.print("YOU DIED", W / 2 - 120, H / 2 - 40, 3)
        luna.graphics.setColor(1, 1, 1, 0.8)
        luna.graphics.print("Press R to retry", W / 2 - 60, H / 2 + 30)
    elseif state == "victory" then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 0.85, 0.2, 1)
        luna.graphics.print("WARDEN DEFEATED", W / 2 - 160, H / 2 - 40, 2.5)
        luna.graphics.setColor(1, 1, 1, 0.8)
        luna.graphics.print("Press R to play again", W / 2 - 70, H / 2 + 30)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" then luna.load(); return end
    if state ~= "play" then return end
    if player.dodging or player.attacking then return end

    if key == "j" and player.stamina >= player.light_cost then
        player.attacking = true; player.atk_timer = 0
        player.atk_type = "light"; player.atk_dur = player.light_dur
        player.stamina = player.stamina - player.light_cost
    elseif key == "k" and player.stamina >= player.heavy_cost then
        player.attacking = true; player.atk_timer = 0
        player.atk_type = "heavy"; player.atk_dur = player.heavy_dur
        player.stamina = player.stamina - player.heavy_cost
    elseif key == "l" and player.stamina >= player.dodge_cost then
        player.dodging = true; player.dodge_timer = 0
        player.dodge_dir = player.facing
        player.stamina = player.stamina - player.dodge_cost
    end
end
