-- ============================================================================
--  Horde Survivor — Vampire Survivors-style top-down horde survival
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/horde_survivor
--
--  Controls (bound as input actions — see lurek.init):
--    up/down/left/right : W/A/S/D
--    pick1/pick2/pick3  : 1/2/3  (level-up menu)
--    quit               : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local ARENA_W,  ARENA_H  = 1600, 1200

local STATE = { TITLE = 1, PLAYING = 2, LEVEL_UP = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

-- Player defaults
local PLAYER_RADIUS      = 12
local PLAYER_SPEED       = 180
local PLAYER_MAX_HP      = 100
local INVULN_TIME        = 0.5
local XP_COLLECT_DIST    = 60

-- Projectile defaults
local PROJ_RADIUS        = 5
local PROJ_BASE_DAMAGE   = 5
local PROJ_ORBIT_SPEED   = 3.0   -- radians/sec
local PROJ_ORBIT_RADIUS  = 60
local PROJ_BASE_COUNT    = 3
local PROJ_BASE_PIERCE   = 1

-- Enemy constants
local ENEMY_WALKER  = 1
local ENEMY_RUNNER  = 2
local ENEMY_TANK    = 3
local ENEMY_EXPLODER = 4

local ENEMY_HP = {
    [ENEMY_WALKER]   = 1,
    [ENEMY_RUNNER]   = 2,
    [ENEMY_TANK]     = 5,
    [ENEMY_EXPLODER] = 3,
}
local ENEMY_SPEED = {
    [ENEMY_WALKER]   = 50,
    [ENEMY_RUNNER]   = 120,
    [ENEMY_TANK]     = 35,
    [ENEMY_EXPLODER] = 70,
}
local ENEMY_SIZE = {
    [ENEMY_WALKER]   = 10,
    [ENEMY_RUNNER]   = 9,
    [ENEMY_TANK]     = 18,
    [ENEMY_EXPLODER] = 12,
}
local ENEMY_COLORS = {
    [ENEMY_WALKER]   = {0.8, 0.3, 0.3},
    [ENEMY_RUNNER]   = {1.0, 0.6, 0.1},
    [ENEMY_TANK]     = {0.5, 0.3, 0.7},
    [ENEMY_EXPLODER] = {0.2, 0.9, 0.4},
}
local ENEMY_CONTACT_DMG = 10
local EXPLODER_RADIUS   = 80
local EXPLODER_DAMAGE   = 15

-- XP / leveling
local XP_GEM_SIZE   = 5
local XP_BASE_VALUE = 10
local XP_PER_LEVEL  = 50   -- increases each level

-- Spawn tuning
local SPAWN_INTERVAL_START = 1.5
local SPAWN_INTERVAL_MIN   = 0.3

-- ── Game state ────────────────────────────────────────────────────────────
local player = {}
local projectiles = {}
local enemies = {}
local xp_gems = {}

local proj_count    = PROJ_BASE_COUNT
local proj_damage   = PROJ_BASE_DAMAGE
local proj_orbit_r  = PROJ_ORBIT_RADIUS
local proj_pierce   = PROJ_BASE_PIERCE
local speed_mult    = 1.0
local orbit_angle   = 0

local hp            = PLAYER_MAX_HP
local xp            = 0
local xp_to_next    = XP_PER_LEVEL
local level         = 1
local kills         = 0
local game_time     = 0
local invuln_timer  = 0

local spawn_timer   = 0
local spawn_interval = SPAWN_INTERVAL_START

-- Upgrade menu
local upgrade_choices = {}

-- Particle systems & tweens
local death_burst     = nil
local xp_sparkle      = nil
local levelup_flash   = nil
local xp_bar_tween    = nil
local damage_flash    = 0
local flash_tween     = nil

-- Camera
local cam = nil

-- Upgrade definitions
local UPGRADES = {
    { name = "+2 Projectiles",    desc = "More orbiting shots",    apply = function() proj_count = proj_count + 2 end },
    { name = "+20% Speed",        desc = "Faster movement",        apply = function() speed_mult = speed_mult + 0.2 end },
    { name = "+3 Damage",         desc = "Harder hits",            apply = function() proj_damage = proj_damage + 3 end },
    { name = "+15px Orbit Radius", desc = "Wider attack circle",   apply = function() proj_orbit_r = proj_orbit_r + 15 end },
    { name = "+1 Pierce",         desc = "Pass through more foes", apply = function() proj_pierce = proj_pierce + 1 end },
}

-- ── Helpers ───────────────────────────────────────────────────────────────
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function pick_random_upgrades()
    local pool = {}
    for i = 1, #UPGRADES do pool[i] = i end
    -- Fisher-Yates partial shuffle for 3
    local chosen = {}
    for i = 1, math.min(3, #pool) do
        local j = math.random(i, #pool)
        pool[i], pool[j] = pool[j], pool[i]
        chosen[i] = UPGRADES[pool[i]]
    end
    return chosen
end

local function spawn_enemy()
    -- Pick edge position outside camera view
    local side = math.random(1, 4)
    local ex, ey
    if side == 1 then     -- top
        ex = player.x + math.random(-500, 500)
        ey = player.y - SCREEN_H / 2 - 40
    elseif side == 2 then -- bottom
        ex = player.x + math.random(-500, 500)
        ey = player.y + SCREEN_H / 2 + 40
    elseif side == 3 then -- left
        ex = player.x - SCREEN_W / 2 - 40
        ey = player.y + math.random(-400, 400)
    else                  -- right
        ex = player.x + SCREEN_W / 2 + 40
        ey = player.y + math.random(-400, 400)
    end
    ex = clamp(ex, 0, ARENA_W)
    ey = clamp(ey, 0, ARENA_H)

    -- Pick type — tanks and exploders appear after time
    local roll = math.random(100)
    local etype
    if game_time < 30 then
        etype = (roll <= 70) and ENEMY_WALKER or ENEMY_RUNNER
    elseif game_time < 90 then
        if roll <= 40 then etype = ENEMY_WALKER
        elseif roll <= 70 then etype = ENEMY_RUNNER
        elseif roll <= 90 then etype = ENEMY_TANK
        else etype = ENEMY_EXPLODER end
    else
        if roll <= 20 then etype = ENEMY_WALKER
        elseif roll <= 45 then etype = ENEMY_RUNNER
        elseif roll <= 75 then etype = ENEMY_TANK
        else etype = ENEMY_EXPLODER end
    end

    enemies[#enemies + 1] = {
        x = ex, y = ey,
        hp = ENEMY_HP[etype],
        etype = etype,
        flash = 0,
    }
end

local function reset_game()
    player = { x = ARENA_W / 2, y = ARENA_H / 2, dir_x = 0, dir_y = -1 }
    enemies = {}
    xp_gems = {}
    proj_count   = PROJ_BASE_COUNT
    proj_damage  = PROJ_BASE_DAMAGE
    proj_orbit_r = PROJ_ORBIT_RADIUS
    proj_pierce  = PROJ_BASE_PIERCE
    speed_mult   = 1.0
    orbit_angle  = 0
    hp           = PLAYER_MAX_HP
    xp           = 0
    xp_to_next   = XP_PER_LEVEL
    level        = 1
    kills        = 0
    game_time    = 0
    invuln_timer = 0
    spawn_timer  = 0
    spawn_interval = SPAWN_INTERVAL_START
    damage_flash = 0
    upgrade_choices = {}
end

-- ── Init ──────────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Horde Survivor — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.12, 0.08)

    lurek.input.bind("up",    {"w"})
    lurek.input.bind("down",  {"s"})
    lurek.input.bind("left",  {"a"})
    lurek.input.bind("right", {"d"})
    lurek.input.bind("pick1", {"1"})
    lurek.input.bind("pick2", {"2"})
    lurek.input.bind("pick3", {"3"})
    lurek.input.bind("quit",  {"escape"})

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle: enemy death burst
    death_burst = lurek.particle.newSystem({
        maxParticles = 120,
        emissionRate = 0,
        lifetimeMin  = 0.15,
        lifetimeMax  = 0.4,
        speedMin     = 50,
        speedMax     = 140,
        direction    = 0,
        spread       = 6.28,
        gravityY     = 0,
        sizes        = {4, 1},
        colors       = {1, 0.3, 0.2, 1,  1, 0.8, 0.2, 0},
    })

    -- Particle: XP pickup sparkle
    xp_sparkle = lurek.particle.newSystem({
        maxParticles = 60,
        emissionRate = 0,
        lifetimeMin  = 0.2,
        lifetimeMax  = 0.5,
        speedMin     = 20,
        speedMax     = 60,
        direction    = -1.57,
        spread       = 1.5,
        gravityY     = -30,
        sizes        = {3, 1},
        colors       = {0.3, 1, 0.3, 1,  0.3, 1, 0.3, 0},
    })

    -- Particle: level up flash
    levelup_flash = lurek.particle.newSystem({
        maxParticles = 100,
        emissionRate = 0,
        lifetimeMin  = 0.3,
        lifetimeMax  = 0.8,
        speedMin     = 60,
        speedMax     = 200,
        direction    = 0,
        spread       = 6.28,
        gravityY     = 0,
        sizes        = {6, 2},
        colors       = {1, 1, 0.3, 1,  1, 0.8, 0.1, 0},
    })

    math.randomseed(os.time())
    reset_game()
end

-- ── Process ───────────────────────────────────────────────────────────────
function lurek.process(dt)
    if lurek.input.keyboard.isDown("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE ─────────────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.keyboard.isDown("pick1") or lurek.input.keyboard.isDown("pick2") or lurek.input.keyboard.isDown("pick3") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.keyboard.isDown("pick1") then
            reset_game()
            current_state = STATE.PLAYING
        end
        return
    end

    -- ── LEVEL UP ──────────────────────────────────────────────────────
    if current_state == STATE.LEVEL_UP then
        for i = 1, 3 do
            if lurek.input.keyboard.isDown("pick" .. i) and upgrade_choices[i] then
                upgrade_choices[i].apply()
                current_state = STATE.PLAYING
                break
            end
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────────────
    game_time = game_time + dt
    invuln_timer = math.max(0, invuln_timer - dt)
    lurek.window.setTitle(string.format("Horde Survivor — Lv%d | %d kills | %s — Lurek2D",
        level, kills, string.format("%d:%02d", math.floor(game_time / 60), math.floor(game_time) % 60)))

    -- Player movement
    local mx, my = 0, 0
    if lurek.input.isActionDown("up")    then my = my - 1 end
    if lurek.input.isActionDown("down")  then my = my + 1 end
    if lurek.input.isActionDown("left")  then mx = mx - 1 end
    if lurek.input.isActionDown("right") then mx = mx + 1 end
    if mx ~= 0 or my ~= 0 then
        local len = math.sqrt(mx * mx + my * my)
        mx, my = mx / len, my / len
        player.dir_x, player.dir_y = mx, my
    end
    local spd = PLAYER_SPEED * speed_mult * dt
    player.x = clamp(player.x + mx * spd, PLAYER_RADIUS, ARENA_W - PLAYER_RADIUS)
    player.y = clamp(player.y + my * spd, PLAYER_RADIUS, ARENA_H - PLAYER_RADIUS)

    -- Update orbit angle
    orbit_angle = orbit_angle + PROJ_ORBIT_SPEED * dt

    -- Build projectile positions
    projectiles = {}
    for i = 1, proj_count do
        local a = orbit_angle + (i - 1) * (2 * math.pi / proj_count)
        projectiles[i] = {
            x = player.x + math.cos(a) * proj_orbit_r,
            y = player.y + math.sin(a) * proj_orbit_r,
            hits = 0,
        }
    end

    -- Spawn enemies
    spawn_interval = math.max(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_START - game_time * 0.008)
    spawn_timer = spawn_timer + dt
    -- Spawn multiple at once as time passes
    local batch = 1 + math.floor(game_time / 60)
    while spawn_timer >= spawn_interval do
        spawn_timer = spawn_timer - spawn_interval
        for _ = 1, batch do
            spawn_enemy()
        end
    end

    -- Update enemies
    local enemies_next = {}
    for _, e in ipairs(enemies) do
        -- Move toward player
        local d = dist(e.x, e.y, player.x, player.y)
        if d > 1 then
            local s = ENEMY_SPEED[e.etype] * dt
            e.x = e.x + (player.x - e.x) / d * s
            e.y = e.y + (player.y - e.y) / d * s
        end
        e.flash = math.max(0, e.flash - dt * 4)

        -- Contact damage to player
        local touch_dist = ENEMY_SIZE[e.etype] + PLAYER_RADIUS
        if d < touch_dist and invuln_timer <= 0 then
            hp = hp - ENEMY_CONTACT_DMG
            invuln_timer = INVULN_TIME
            damage_flash = 0.4
            flash_tween = lurek.tween.to(
                { val = 0.4 },
                { val = 0 },
                0.3,
                "outQuad"
            )
        end

        -- Projectile hits
        local alive = true
        for _, p in ipairs(projectiles) do
            if p.hits < proj_pierce then
                local pd = dist(p.x, p.y, e.x, e.y)
                if pd < PROJ_RADIUS + ENEMY_SIZE[e.etype] then
                    e.hp = e.hp - proj_damage
                    e.flash = 1
                    p.hits = p.hits + 1
                    if e.hp <= 0 then
                        alive = false
                        kills = kills + 1
                        -- Death burst
                        death_burst:setPosition(e.x, e.y)
                        death_burst:emit(12)
                        -- Drop XP gem
                        xp_gems[#xp_gems + 1] = { x = e.x, y = e.y }
                        -- Exploder special
                        if e.etype == ENEMY_EXPLODER then
                            -- Damage nearby enemies and player
                            for _, other in ipairs(enemies) do
                                if other ~= e then
                                    local od = dist(e.x, e.y, other.x, other.y)
                                    if od < EXPLODER_RADIUS then
                                        other.hp = other.hp - EXPLODER_DAMAGE
                                        other.flash = 1
                                    end
                                end
                            end
                            local pd2 = dist(e.x, e.y, player.x, player.y)
                            if pd2 < EXPLODER_RADIUS and invuln_timer <= 0 then
                                hp = hp - EXPLODER_DAMAGE
                                invuln_timer = INVULN_TIME
                                damage_flash = 0.4
                            end
                            death_burst:emit(20)
                        end
                        break
                    end
                end
            end
        end
        if alive and e.hp > 0 then
            enemies_next[#enemies_next + 1] = e
        end
    end
    enemies = enemies_next

    -- Collect XP gems
    local gems_next = {}
    for _, g in ipairs(xp_gems) do
        local gd = dist(g.x, g.y, player.x, player.y)
        if gd < XP_COLLECT_DIST then
            xp = xp + XP_BASE_VALUE
            xp_sparkle:setPosition(g.x, g.y)
            xp_sparkle:emit(6)
            -- Check level up
            if xp >= xp_to_next then
                xp = xp - xp_to_next
                level = level + 1
                xp_to_next = XP_PER_LEVEL + (level - 1) * 20
                upgrade_choices = pick_random_upgrades()
                current_state = STATE.LEVEL_UP
                levelup_flash:setPosition(player.x, player.y)
                levelup_flash:emit(40)
            end
        else
            gems_next[#gems_next + 1] = g
        end
    end
    xp_gems = gems_next

    -- Update flash tween
    if flash_tween then
        damage_flash = math.max(0, damage_flash - dt * 2)
    end

    -- Update particles
    death_burst:update(dt)
    xp_sparkle:update(dt)
    levelup_flash:update(dt)

    -- Camera follow
    local cam_x = clamp(player.x, SCREEN_W / 2, ARENA_W - SCREEN_W / 2)
    local cam_y = clamp(player.y, SCREEN_H / 2, ARENA_H - SCREEN_H / 2)
    cam:setPosition(cam_x, cam_y)

    -- Check death
    if hp <= 0 then
        hp = 0
        current_state = STATE.GAME_OVER
    end
end

-- ── Render (world space — affected by camera) ─────────────────────────────
function lurek.draw()
    cam:apply()

    if current_state == STATE.TITLE then
        lurek.render.setColor(0.3, 0.35, 0.25)
        lurek.render.drawRectangle("fill", 0, 0, ARENA_W, ARENA_H)
        return
    end

    -- Arena ground
    lurek.render.setColor(0.15, 0.18, 0.12)
    lurek.render.drawRectangle("fill", 0, 0, ARENA_W, ARENA_H)

    -- Arena border
    lurek.render.setColor(0.08, 0.1, 0.06)
    lurek.render.drawRectangle("fill", -50, -50, ARENA_W + 100, 50)
    lurek.render.drawRectangle("fill", -50, ARENA_H, ARENA_W + 100, 50)
    lurek.render.drawRectangle("fill", -50, 0, 50, ARENA_H)
    lurek.render.drawRectangle("fill", ARENA_W, 0, 50, ARENA_H)

    -- Ground detail — subtle grid
    lurek.render.setColor(0.13, 0.16, 0.1, 0.3)
    for gx = 0, ARENA_W, 100 do
        lurek.render.line(gx, 0, gx, ARENA_H)
    end
    for gy = 0, ARENA_H, 100 do
        lurek.render.line(0, gy, ARENA_W, gy)
    end

    -- XP gems (green diamonds)
    for _, g in ipairs(xp_gems) do
        lurek.render.setColor(0.2, 0.9, 0.3)
        local s = XP_GEM_SIZE
        lurek.render.drawPolygon("fill", g.x, g.y - s, g.x + s, g.y, g.x, g.y + s, g.x - s, g.y)
        lurek.render.setColor(0.5, 1, 0.6)
        lurek.render.drawPolygon("fill", g.x, g.y - s * 0.5, g.x + s * 0.5, g.y, g.x, g.y + s * 0.5, g.x - s * 0.5, g.y)
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        local c = ENEMY_COLORS[e.etype]
        local flash_r = math.min(1, c[1] + e.flash * 0.5)
        local flash_g = math.min(1, c[2] + e.flash * 0.5)
        local flash_b = math.min(1, c[3] + e.flash * 0.5)
        lurek.render.setColor(flash_r, flash_g, flash_b)
        lurek.render.drawCircle("fill", e.x, e.y, ENEMY_SIZE[e.etype])

        -- Inner detail
        lurek.render.setColor(c[1] * 0.6, c[2] * 0.6, c[3] * 0.6)
        lurek.render.drawCircle("fill", e.x, e.y, ENEMY_SIZE[e.etype] * 0.5)

        -- Exploder warning ring
        if e.etype == ENEMY_EXPLODER then
            lurek.render.setColor(0.2, 0.9, 0.4, 0.3)
            lurek.render.drawCircle("line", e.x, e.y, ENEMY_SIZE[e.etype] + 3)
        end
    end

    -- Projectiles (orbiting)
    for _, p in ipairs(projectiles) do
        lurek.render.setColor(1, 0.9, 0.4)
        lurek.render.drawCircle("fill", p.x, p.y, PROJ_RADIUS)
        lurek.render.setColor(1, 1, 0.8)
        lurek.render.drawCircle("fill", p.x, p.y, PROJ_RADIUS * 0.5)
    end

    -- Orbit ring (subtle)
    lurek.render.setColor(1, 0.9, 0.4, 0.15)
    lurek.render.drawCircle("line", player.x, player.y, proj_orbit_r)

    -- Player
    local pa = (invuln_timer > 0 and math.floor(invuln_timer * 10) % 2 == 0) and 0.4 or 1.0
    lurek.render.setColor(0.3, 0.7, 1.0, pa)
    lurek.render.drawCircle("fill", player.x, player.y, PLAYER_RADIUS)
    -- Direction indicator
    lurek.render.setColor(0.6, 0.9, 1.0, pa)
    lurek.render.drawCircle("fill",
        player.x + player.dir_x * PLAYER_RADIUS * 0.7,
        player.y + player.dir_y * PLAYER_RADIUS * 0.7,
        PLAYER_RADIUS * 0.35)
    -- Player outline
    lurek.render.setColor(0.2, 0.5, 0.8, pa)
    lurek.render.drawCircle("line", player.x, player.y, PLAYER_RADIUS)

    -- Particles
    death_burst:draw()
    xp_sparkle:draw()
    levelup_flash:draw()

    -- Damage flash overlay
    if damage_flash > 0 then
        lurek.render.setColor(1, 0.2, 0.1, damage_flash)
        lurek.render.drawRectangle("fill",
            player.x - SCREEN_W / 2, player.y - SCREEN_H / 2,
            SCREEN_W, SCREEN_H)
    end
end

-- ── Render UI (screen space — NOT affected by camera) ─────────────────────
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    -- ── TITLE ─────────────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(1, 0.9, 0.3)
        lurek.render.print("HORDE SURVIVOR", SCREEN_W / 2 - 120, 180, 32)
        lurek.render.setColor(0.8, 0.8, 0.8)
        lurek.render.print("Survive the endless horde!", SCREEN_W / 2 - 110, 230, 16)
        lurek.render.setColor(0.6, 0.9, 0.6)
        lurek.render.print("Press 1, 2, or 3 to start", SCREEN_W / 2 - 100, 320, 16)
        lurek.render.setColor(0.5, 0.5, 0.5)
        lurek.render.print("WASD = move  |  Auto-attack", SCREEN_W / 2 - 110, 370, 14)
        lurek.render.setColor(0.4, 0.4, 0.4)
        lurek.render.print(string.format("FPS: %d", fps), 10, SCREEN_H - 20, 12)
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.drawRectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(1, 0.3, 0.3)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 80, 150, 32)
        lurek.render.setColor(0.9, 0.9, 0.9)
        local time_str = string.format("%d:%02d", math.floor(game_time / 60), math.floor(game_time) % 60)
        lurek.render.print("Time: " .. time_str, SCREEN_W / 2 - 60, 220, 18)
        lurek.render.print("Kills: " .. kills, SCREEN_W / 2 - 60, 250, 18)
        lurek.render.print("Level: " .. level, SCREEN_W / 2 - 60, 280, 18)
        lurek.render.setColor(0.6, 0.9, 0.6)
        lurek.render.print("Press 1 to restart", SCREEN_W / 2 - 80, 340, 16)
        lurek.render.setColor(0.4, 0.4, 0.4)
        lurek.render.print(string.format("FPS: %d", fps), 10, SCREEN_H - 20, 12)
        return
    end

    -- ── LEVEL UP overlay ──────────────────────────────────────────────
    if current_state == STATE.LEVEL_UP then
        lurek.render.setColor(0, 0, 0, 0.65)
        lurek.render.drawRectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(1, 1, 0.3)
        lurek.render.print("LEVEL UP!", SCREEN_W / 2 - 70, 120, 28)
        lurek.render.setColor(0.9, 0.9, 0.9)
        lurek.render.print("Choose an upgrade:", SCREEN_W / 2 - 80, 170, 16)

        for i, u in ipairs(upgrade_choices) do
            local bx = SCREEN_W / 2 - 160
            local by = 210 + (i - 1) * 80
            -- Card background
            lurek.render.setColor(0.15, 0.2, 0.15, 0.9)
            lurek.render.drawRectangle("fill", bx, by, 320, 65)
            lurek.render.setColor(0.4, 0.8, 0.4)
            lurek.render.drawRectangle("line", bx, by, 320, 65)
            -- Number
            lurek.render.setColor(1, 0.9, 0.3)
            lurek.render.print(tostring(i), bx + 10, by + 12, 28)
            -- Name and desc
            lurek.render.setColor(1, 1, 1)
            lurek.render.print(u.name, bx + 45, by + 12, 18)
            lurek.render.setColor(0.7, 0.7, 0.7)
            lurek.render.print(u.desc, bx + 45, by + 38, 13)
        end
        return
    end

    -- ── PLAYING HUD ───────────────────────────────────────────────────

    -- HP bar
    local bar_w = 200
    local bar_h = 16
    local bar_x = 10
    local bar_y = 10
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.drawRectangle("fill", bar_x, bar_y, bar_w, bar_h)
    local hp_frac = hp / PLAYER_MAX_HP
    local hp_color_r = 1 - hp_frac
    local hp_color_g = hp_frac
    lurek.render.setColor(hp_color_r, hp_color_g, 0.1, 0.9)
    lurek.render.drawRectangle("fill", bar_x, bar_y, bar_w * hp_frac, bar_h)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(string.format("HP %d/%d", hp, PLAYER_MAX_HP), bar_x + 4, bar_y + 1, 12)

    -- XP bar
    local xp_y = bar_y + bar_h + 4
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.drawRectangle("fill", bar_x, xp_y, bar_w, 10)
    local xp_frac = xp / xp_to_next
    lurek.render.setColor(0.3, 0.8, 1.0, 0.9)
    lurek.render.drawRectangle("fill", bar_x, xp_y, bar_w * xp_frac, 10)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(string.format("XP %d/%d", xp, xp_to_next), bar_x + 4, xp_y - 1, 10)

    -- Level
    lurek.render.setColor(1, 0.9, 0.3)
    lurek.render.print("Lv " .. level, bar_x + bar_w + 10, bar_y, 16)

    -- Kill counter
    lurek.render.setColor(0.9, 0.5, 0.5)
    lurek.render.print("Kills: " .. kills, SCREEN_W - 130, 10, 14)

    -- Timer
    local time_str = string.format("%d:%02d", math.floor(game_time / 60), math.floor(game_time) % 60)
    lurek.render.setColor(0.9, 0.9, 0.9)
    lurek.render.print(time_str, SCREEN_W / 2 - 20, 10, 18)

    -- Stats line
    lurek.render.setColor(0.6, 0.6, 0.6)
    lurek.render.print(string.format("DMG:%d  ORB:%d  SPD:%.0f%%  PIERCE:%d",
        proj_damage, proj_count, speed_mult * 100, proj_pierce),
        10, SCREEN_H - 22, 11)

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.4)
    lurek.render.print(string.format("FPS: %d", fps), SCREEN_W - 80, SCREEN_H - 20, 12)
end
