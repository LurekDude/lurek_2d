-- ============================================================================
-- Turrican — Lurek2D
-- ============================================================================
-- Category : retro
-- Source   : content/games/retro/turrican/main.lua
-- Run with : cargo run -- content/games/retro/turrican
-- ============================================================================
-- Run-and-gun platformer inspired by Manfred Trenz's 1990 classic.
-- Dual weapon system: rapid-fire shot (F) and sweeping energy beam (G).
-- Controls: A/D move, Space/W jump, F shoot, G beam, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
-- Capture lurek.render API table before `function lurek.render()` shadows it.
local gfx = lurek.render

local SCREEN_W, SCREEN_H = 800, 600
local TILE            = 32
local MAP_COLS, MAP_ROWS = 26, 15

local STATE = { TITLE = 1, PLAYING = 2, LEVEL_COMPLETE = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

-- Player
local PLAYER_W, PLAYER_H = 24, 28
local PLAYER_SPEED       = 180
local GRAVITY            = 800
local JUMP_VEL           = -440
local MAX_HP             = 5
local MAX_AMMO           = 100

-- Weapons
local BULLET_SPEED    = 360
local BULLET_W, BULLET_H = 6, 4
local FIRE_COOLDOWN   = 0.12
local BEAM_RANGE      = 220
local BEAM_DRAIN      = 3   -- ammo per second
local SPREAD_ANGLE    = 0.18 -- radians offset for spread

-- Enemies
local EN_WALKER = 1
local EN_FLYER  = 2
local EN_TURRET = 3
local ENEMY_HP    = { [EN_WALKER] = 1, [EN_FLYER] = 2, [EN_TURRET] = 3 }
local ENEMY_SPEED = { [EN_WALKER] = 60, [EN_FLYER] = 50, [EN_TURRET] = 0 }
local ENEMY_W     = { [EN_WALKER] = 20, [EN_FLYER] = 18, [EN_TURRET] = 24 }
local ENEMY_H     = { [EN_WALKER] = 22, [EN_FLYER] = 18, [EN_TURRET] = 20 }
local ENEMY_SCORE = 50
local TURRET_INTERVAL = 2.0
local TURRET_BULLET_SPEED = 200

-- Powerup types
local PU_SPREAD = 1
local PU_HEALTH = 2
local PU_AMMO   = 3
local POWERUP_SCORE = 25

-- Colors
local COL_PLAYER   = { 0.25, 0.45, 0.85 }
local COL_BLOCK    = { 0.30, 0.25, 0.20 }
local COL_EXIT     = { 0.15, 0.80, 0.30 }
local COL_WALKER   = { 0.80, 0.25, 0.15 }
local COL_FLYER    = { 0.90, 0.55, 0.15 }
local COL_TURRET   = { 0.70, 0.20, 0.20 }
local COL_BULLET   = { 1.0, 0.95, 0.5 }
local COL_BEAM     = { 0.4, 0.85, 1.0 }
local COL_PU_SPREAD = { 1.0, 0.3, 0.3 }
local COL_PU_HEALTH = { 0.3, 1.0, 0.4 }
local COL_PU_AMMO   = { 0.3, 0.6, 1.0 }

-- ---------------------------------------------------------------------------
-- Level data (3 levels, 26x15 each, row-major strings)
-- . = air, 1 = block, E = walker, F = flyer, T = turret,
-- S = spread, H = health, A = ammo, X = exit
-- ---------------------------------------------------------------------------
local LEVELS = {
    { -- Level 1: introduction
        "11111111111111111111111111",
        "..........................",
        "..........................",
        "..........111.............",
        ".......E......F...........",
        "......1111......111.......",
        "..........................",
        "..S.......A...........H...",
        "..111.....111.....T.111...",
        "..........................",
        ".............E............",
        "...E......1111111........X",
        "..1111.................111",
        "..........................",
        "11111111111111111111111111",
    },
    { -- Level 2: more turrets, flyers
        "11111111111111111111111111",
        "..........................",
        "..F.........F.........F...",
        "..........................",
        "....1111......T...111.....",
        "..........................",
        "..A.....E.......E.........",
        "..111...1111....1111..S...",
        ".....................111..",
        ".........T................",
        "..H....11111..........E..",
        "..111..........11111.1111",
        ".........................X",
        "..........................",
        "11111111111111111111111111",
    },
    { -- Level 3: gauntlet
        "11111111111111111111111111",
        "..........................",
        "..T...F...T...F...T.......",
        "..111.....111.....111.....",
        "..........................",
        "....E...........E.........",
        "....1111...A...1111.......",
        "..........................",
        "..S.......T.......H.......",
        "..111...11111...111.......",
        "..........................",
        "...E.........E.........E..",
        "..1111..T..1111..T..111.X",
        "..........................",
        "11111111111111111111111111",
    },
}

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local player = {}
local bullets = {}
local enemy_bullets = {}
local enemies = {}
local powerups = {}
local tiles = {}

local hp, ammo, score, high_score = MAX_HP, MAX_AMMO, 0, 0
local fire_timer = 0
local has_spread = false
local beam_active = false
local beam_angle  = 0
local facing = 1    -- 1 = right, -1 = left
local current_level = 1
local level_w = 0

local camera = nil
local cam_x = 0

-- Particle systems
local ps_impact   = nil
local ps_explode  = nil
local ps_beam     = nil
local ps_pickup   = nil

-- Tween
local flash_alpha = { a = 0 }
local banner = { y = -60 }

local invuln_timer = 0
local INVULN_TIME  = 1.5

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function load_level(idx)
    tiles = {}
    enemies = {}
    powerups = {}
    bullets = {}
    enemy_bullets = {}
    beam_active = false
    beam_angle = 0

    local map = LEVELS[idx]
    level_w = MAP_COLS * TILE

    for row = 1, MAP_ROWS do
        local line = map[row]
        for col = 1, MAP_COLS do
            local ch = line:sub(col, col)
            local wx = (col - 1) * TILE
            local wy = (row - 1) * TILE
            if ch == "1" then
                tiles[#tiles + 1] = { x = wx, y = wy }
            elseif ch == "E" then
                enemies[#enemies + 1] = { kind = EN_WALKER, x = wx, y = wy, hp = ENEMY_HP[EN_WALKER], dir = 1, timer = 0 }
            elseif ch == "F" then
                enemies[#enemies + 1] = { kind = EN_FLYER, x = wx, y = wy, hp = ENEMY_HP[EN_FLYER], base_y = wy, t = math.random() * 6.28, timer = 0 }
            elseif ch == "T" then
                enemies[#enemies + 1] = { kind = EN_TURRET, x = wx, y = wy, hp = ENEMY_HP[EN_TURRET], timer = math.random() * TURRET_INTERVAL }
            elseif ch == "S" then
                powerups[#powerups + 1] = { kind = PU_SPREAD, x = wx, y = wy, t = math.random() * 6.28 }
            elseif ch == "H" then
                powerups[#powerups + 1] = { kind = PU_HEALTH, x = wx, y = wy, t = math.random() * 6.28 }
            elseif ch == "A" then
                powerups[#powerups + 1] = { kind = PU_AMMO, x = wx, y = wy, t = math.random() * 6.28 }
            elseif ch == "X" then
                tiles[#tiles + 1] = { x = wx, y = wy, exit = true }
            end
        end
    end

    player = { x = TILE * 2, y = TILE * 12, vx = 0, vy = 0, on_ground = false }
    fire_timer = 0
    cam_x = 0
end

local function tile_collision(px, py, pw, ph)
    for i = 1, #tiles do
        local t = tiles[i]
        if not t.exit and aabb(px, py, pw, ph, t.x, t.y, TILE, TILE) then
            return true
        end
    end
    return false
end

local function check_exit(px, py, pw, ph)
    for i = 1, #tiles do
        local t = tiles[i]
        if t.exit and aabb(px, py, pw, ph, t.x, t.y, TILE, TILE) then
            return true
        end
    end
    return false
end

local function fire_bullet(x, y, dx, dy)
    if ammo <= 0 then return end
    ammo = ammo - 1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then dx, dy = facing, 0; len = 1 end
    dx, dy = dx / len, dy / len
    bullets[#bullets + 1] = { x = x, y = y, dx = dx * BULLET_SPEED, dy = dy * BULLET_SPEED }
end

local function fire_spread(x, y)
    fire_bullet(x, y, facing, 0)
    fire_bullet(x, y, facing, -SPREAD_ANGLE * facing * 2)
    fire_bullet(x, y, facing, SPREAD_ANGLE * facing * 2)
end

local function damage_player()
    if invuln_timer > 0 then return end
    hp = hp - 1
    invuln_timer = INVULN_TIME
    if hp <= 0 then
        high_score = math.max(high_score, score)
        current_state = STATE.GAME_OVER
    end
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Turrican — Lurek2D")
    gfx.setBackgroundColor(0.05, 0.05, 0.12)

    lurek.input.bind("left",   { "a" })
    lurek.input.bind("right",  { "d" })
    lurek.input.bind("jump",   { "space", "w" })
    lurek.input.bind("shoot",  { "f" })
    lurek.input.bind("beam",   { "g" })
    lurek.input.bind("quit",   { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle systems
    ps_impact = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0, lifetimeMin = 0.1, lifetimeMax = 0.25,
        speedMin = 80, speedMax = 160, direction = 0, spread = 6.28,
        sizes = { 2, 1 }, colors = { 1, 0.9, 0.3, 1, 1, 0.4, 0.1, 0 },
    })
    ps_explode = lurek.particle.newSystem({
        maxParticles = 120, emissionRate = 0, lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 60, speedMax = 200, direction = 0, spread = 6.28,
        gravityY = 120, sizes = { 4, 2, 0 }, colors = { 1, 0.6, 0.1, 1, 0.8, 0.2, 0, 0 },
    })
    ps_beam = lurek.particle.newSystem({
        maxParticles = 80, emissionRate = 0, lifetimeMin = 0.05, lifetimeMax = 0.15,
        speedMin = 30, speedMax = 80, direction = 0, spread = 6.28,
        sizes = { 3, 1 }, colors = { 0.4, 0.85, 1, 1, 0.2, 0.5, 1, 0 },
    })
    ps_pickup = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0, lifetimeMin = 0.3, lifetimeMax = 0.6,
        speedMin = 40, speedMax = 100, direction = -1.57, spread = 1.0,
        sizes = { 3, 1 }, colors = { 1, 1, 0.5, 1, 0.5, 1, 0.3, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Particle updates
    ps_impact:update(dt)
    ps_explode:update(dt)
    ps_beam:update(dt)
    ps_pickup:update(dt)
    lurek.tween.update(dt)

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("shoot") or lurek.input.wasActionPressed("jump") then
            current_level = 1
            hp = MAX_HP
            ammo = MAX_AMMO
            score = 0
            has_spread = false
            load_level(current_level)
            current_state = STATE.PLAYING
        end
        return
    end

    -- ── LEVEL COMPLETE ────────────────────────────────────────
    if current_state == STATE.LEVEL_COMPLETE then
        if lurek.input.wasActionPressed("shoot") or lurek.input.wasActionPressed("jump") then
            current_level = current_level + 1
            if current_level > #LEVELS then
                high_score = math.max(high_score, score)
                current_state = STATE.TITLE
            else
                load_level(current_level)
                current_state = STATE.PLAYING
            end
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("shoot") or lurek.input.wasActionPressed("jump") then
            current_state = STATE.TITLE
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────
    if invuln_timer > 0 then invuln_timer = invuln_timer - dt end

    -- Movement
    local dx = 0
    if lurek.input.isActionDown("left") then dx = -1; facing = -1 end
    if lurek.input.isActionDown("right") then dx = 1; facing = 1 end
    player.vx = dx * PLAYER_SPEED

    -- Jump
    if lurek.input.wasActionPressed("jump") and player.on_ground then
        player.vy = JUMP_VEL
        player.on_ground = false
    end

    -- Gravity
    player.vy = player.vy + GRAVITY * dt

    -- Horizontal movement + collision
    local nx = player.x + player.vx * dt
    if not tile_collision(nx, player.y, PLAYER_W, PLAYER_H) then
        player.x = nx
    end
    player.x = clamp(player.x, 0, level_w - PLAYER_W)

    -- Vertical movement + collision
    local ny = player.y + player.vy * dt
    if tile_collision(player.x, ny, PLAYER_W, PLAYER_H) then
        if player.vy > 0 then
            player.on_ground = true
            player.vy = 0
            -- Snap to tile top
            local snapped = false
            for i = 1, #tiles do
                local t = tiles[i]
                if not t.exit and aabb(player.x, ny, PLAYER_W, PLAYER_H, t.x, t.y, TILE, TILE) then
                    player.y = t.y - PLAYER_H
                    snapped = true
                    break
                end
            end
            if not snapped then player.y = ny end
        else
            player.vy = 0
        end
    else
        player.y = ny
        player.on_ground = false
    end

    -- Falling off screen
    if player.y > SCREEN_H + 100 then
        damage_player()
        if current_state == STATE.PLAYING then
            player.x = TILE * 2
            player.y = TILE * 2
            player.vy = 0
        end
    end

    -- ── Shooting ──────────────────────────────────────────────
    fire_timer = fire_timer - dt
    if lurek.input.isActionDown("shoot") and fire_timer <= 0 then
        fire_timer = FIRE_COOLDOWN
        local bx = player.x + (facing > 0 and PLAYER_W or 0)
        local by = player.y + PLAYER_H * 0.4
        if has_spread then
            fire_spread(bx, by)
        else
            fire_bullet(bx, by, facing, 0)
        end
        -- Weapon flash
        flash_alpha.a = 0.6
        lurek.tween.to(flash_alpha, 0.08, { a = 0 })
    end

    -- ── Energy beam ───────────────────────────────────────────
    beam_active = lurek.input.isActionDown("beam") and ammo > 0
    if beam_active then
        ammo = ammo - BEAM_DRAIN * dt
        if ammo < 0 then ammo = 0; beam_active = false end
        beam_angle = beam_angle + dt * 2.5
        if beam_angle > 1.2 then beam_angle = -1.2 end

        -- Beam endpoint
        local bx = player.x + PLAYER_W / 2
        local by = player.y + PLAYER_H / 2
        local a = beam_angle
        local ex = bx + math.cos(a) * BEAM_RANGE * facing
        local ey = by + math.sin(a) * BEAM_RANGE
        ps_beam:emit(2, ex, ey)

        -- Beam vs enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            local ecx = e.x + ENEMY_W[e.kind] / 2
            local ecy = e.y + ENEMY_H[e.kind] / 2
            -- Check distance from beam line
            local dx2 = ecx - bx
            local dy2 = ecy - by
            local dist = math.sqrt(dx2 * dx2 + dy2 * dy2)
            if dist < BEAM_RANGE + 10 then
                local dot = dx2 * math.cos(a) * facing + dy2 * math.sin(a)
                if dot > 0 then
                    local cross = math.abs(dx2 * math.sin(a) - dy2 * math.cos(a) * facing)
                    if cross < 20 then
                        e.hp = e.hp - 4 * dt
                        if e.hp <= 0 then
                            score = score + ENEMY_SCORE
                            ps_explode:emit(25, ecx, ecy)
                            table.remove(enemies, i)
                        end
                    end
                end
            end
        end
    else
        beam_angle = 0
    end

    -- ── Update bullets ────────────────────────────────────────
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt
        local remove = false

        -- Off screen
        if b.x < cam_x - 50 or b.x > cam_x + SCREEN_W + 50 or b.y < -50 or b.y > SCREEN_H + 50 then
            remove = true
        end

        -- Tile hit
        if not remove and tile_collision(b.x, b.y, BULLET_W, BULLET_H) then
            remove = true
            ps_impact:emit(6, b.x, b.y)
        end

        -- Enemy hit
        if not remove then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if aabb(b.x, b.y, BULLET_W, BULLET_H, e.x, e.y, ENEMY_W[e.kind], ENEMY_H[e.kind]) then
                    e.hp = e.hp - 1
                    remove = true
                    ps_impact:emit(8, b.x, b.y)
                    if e.hp <= 0 then
                        score = score + ENEMY_SCORE
                        ps_explode:emit(20, e.x + ENEMY_W[e.kind] / 2, e.y + ENEMY_H[e.kind] / 2)
                        table.remove(enemies, j)
                    end
                    break
                end
            end
        end

        if remove then table.remove(bullets, i) end
    end

    -- ── Update enemy bullets ──────────────────────────────────
    for i = #enemy_bullets, 1, -1 do
        local b = enemy_bullets[i]
        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt
        local remove = false
        if b.x < cam_x - 50 or b.x > cam_x + SCREEN_W + 50 or b.y < -50 or b.y > SCREEN_H + 50 then
            remove = true
        end
        if not remove and aabb(b.x, b.y, 4, 4, player.x, player.y, PLAYER_W, PLAYER_H) then
            remove = true
            damage_player()
        end
        if remove then table.remove(enemy_bullets, i) end
    end

    -- ── Update enemies ────────────────────────────────────────
    for i = 1, #enemies do
        local e = enemies[i]
        if e.kind == EN_WALKER then
            e.x = e.x + ENEMY_SPEED[EN_WALKER] * e.dir * dt
            -- Reverse at edges or tile boundaries
            local ahead = e.x + (e.dir > 0 and ENEMY_W[EN_WALKER] + 2 or -2)
            if ahead < 0 or ahead > level_w or tile_collision(ahead, e.y, 2, ENEMY_H[EN_WALKER]) then
                e.dir = -e.dir
            end
            -- Check floor
            if not tile_collision(e.x + ENEMY_W[EN_WALKER] / 2, e.y + ENEMY_H[EN_WALKER] + 2, 2, 2) then
                e.dir = -e.dir
            end
            -- Contact damage
            if aabb(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, ENEMY_W[EN_WALKER], ENEMY_H[EN_WALKER]) then
                damage_player()
            end

        elseif e.kind == EN_FLYER then
            e.t = e.t + dt * 2.2
            e.y = e.base_y + math.sin(e.t) * 40
            -- Move toward player slowly
            if player.x > e.x then e.x = e.x + ENEMY_SPEED[EN_FLYER] * dt
            else e.x = e.x - ENEMY_SPEED[EN_FLYER] * dt end
            -- Contact damage
            if aabb(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, ENEMY_W[EN_FLYER], ENEMY_H[EN_FLYER]) then
                damage_player()
            end

        elseif e.kind == EN_TURRET then
            e.timer = e.timer + dt
            if e.timer >= TURRET_INTERVAL then
                e.timer = 0
                local dx2 = player.x - e.x
                local dy2 = player.y - e.y
                local dist = math.sqrt(dx2 * dx2 + dy2 * dy2)
                if dist > 1 then
                    enemy_bullets[#enemy_bullets + 1] = {
                        x = e.x + ENEMY_W[EN_TURRET] / 2,
                        y = e.y + ENEMY_H[EN_TURRET] / 2,
                        dx = (dx2 / dist) * TURRET_BULLET_SPEED,
                        dy = (dy2 / dist) * TURRET_BULLET_SPEED,
                    }
                end
            end
            -- Contact damage
            if aabb(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, ENEMY_W[EN_TURRET], ENEMY_H[EN_TURRET]) then
                damage_player()
            end
        end
    end

    -- ── Powerups ──────────────────────────────────────────────
    for i = #powerups, 1, -1 do
        local p = powerups[i]
        p.t = p.t + dt * 3
        if aabb(player.x, player.y, PLAYER_W, PLAYER_H, p.x + 4, p.y + 4, 24, 24) then
            score = score + POWERUP_SCORE
            ps_pickup:emit(15, p.x + 16, p.y + 16)
            if p.kind == PU_SPREAD then
                has_spread = true
                -- Weapon switch flash
                flash_alpha.a = 1.0
                lurek.tween.to(flash_alpha, 0.3, { a = 0 })
            elseif p.kind == PU_HEALTH then
                hp = math.min(hp + 2, MAX_HP)
            elseif p.kind == PU_AMMO then
                ammo = math.min(ammo + 25, MAX_AMMO)
            end
            table.remove(powerups, i)
        end
    end

    -- ── Exit check ────────────────────────────────────────────
    if check_exit(player.x, player.y, PLAYER_W, PLAYER_H) then
        current_state = STATE.LEVEL_COMPLETE
        banner.y = -60
        lurek.tween.to(banner, 0.5, { y = SCREEN_H / 2 - 30 })
    end

    -- ── Camera ────────────────────────────────────────────────
    local target_cx = player.x - SCREEN_W / 2 + PLAYER_W / 2
    cam_x = clamp(target_cx, 0, math.max(0, level_w - SCREEN_W))
    camera:setPosition(cam_x, 0)
    camera:update(dt)
end

-- ---------------------------------------------------------------------------
-- Render (world space — camera-transformed)
-- ---------------------------------------------------------------------------
function lurek.render()
    if current_state == STATE.TITLE then
        gfx.setColor(0.4, 0.85, 1.0, 1)
        gfx.print("TURRICAN", SCREEN_W / 2 - 100, SCREEN_H / 3, 4)
        gfx.setColor(0.7, 0.7, 0.8, 1)
        gfx.print("A Lurek2D Tribute", SCREEN_W / 2 - 80, SCREEN_H / 3 + 60, 1.5)
        gfx.setColor(0.9, 0.9, 0.5, math.abs(math.sin(lurek.timer.getTime() * 2.5)))
        gfx.print("PRESS F OR SPACE TO START", SCREEN_W / 2 - 120, SCREEN_H / 2 + 40, 1.5)
        gfx.setColor(0.5, 0.5, 0.6, 1)
        gfx.print("Inspired by Manfred Trenz (1990)", SCREEN_W / 2 - 120, SCREEN_H - 80, 1)
        return
    end

    if current_state == STATE.GAME_OVER then
        gfx.setColor(0.9, 0.2, 0.2, 1)
        gfx.print("GAME OVER", SCREEN_W / 2 - 80, SCREEN_H / 3, 3)
        gfx.setColor(0.8, 0.8, 0.8, 1)
        gfx.print("Score: " .. score, SCREEN_W / 2 - 60, SCREEN_H / 2, 2)
        gfx.print("High Score: " .. high_score, SCREEN_W / 2 - 80, SCREEN_H / 2 + 40, 1.5)
        gfx.setColor(0.6, 0.6, 0.7, 1)
        gfx.print("Press F to return to title", SCREEN_W / 2 - 100, SCREEN_H / 2 + 100, 1)
        return
    end

    camera:apply()

    -- Tiles
    for i = 1, #tiles do
        local t = tiles[i]
        if t.exit then
            gfx.setColor(COL_EXIT[1], COL_EXIT[2], COL_EXIT[3], 1)
        else
            -- Slight shade variation
            local shade = ((t.x + t.y) % 64 < 32) and 1.0 or 0.85
            gfx.setColor(COL_BLOCK[1] * shade, COL_BLOCK[2] * shade, COL_BLOCK[3] * shade, 1)
        end
        gfx.rectangle("fill", t.x, t.y, TILE, TILE)
        -- Tile outline
        gfx.setColor(0.15, 0.12, 0.08, 0.5)
        gfx.rectangle("line", t.x, t.y, TILE, TILE)
    end

    -- Powerups (spinning diamonds)
    for i = 1, #powerups do
        local p = powerups[i]
        local col
        if p.kind == PU_SPREAD then col = COL_PU_SPREAD
        elseif p.kind == PU_HEALTH then col = COL_PU_HEALTH
        else col = COL_PU_AMMO end

        local pulse = 0.7 + 0.3 * math.sin(p.t)
        gfx.setColor(col[1], col[2], col[3], pulse)
        -- Diamond shape (rotated square approximation)
        local cx, cy = p.x + 16, p.y + 16
        local sz = 10 + math.sin(p.t * 0.8) * 2
        gfx.rectangle("fill", cx - sz / 2, cy - sz / 2, sz, sz)
        gfx.setColor(1, 1, 1, 0.4)
        gfx.rectangle("line", cx - sz / 2 - 1, cy - sz / 2 - 1, sz + 2, sz + 2)
    end

    -- Enemies
    for i = 1, #enemies do
        local e = enemies[i]
        local col
        if e.kind == EN_WALKER then col = COL_WALKER
        elseif e.kind == EN_FLYER then col = COL_FLYER
        else col = COL_TURRET end
        gfx.setColor(col[1], col[2], col[3], 1)
        gfx.rectangle("fill", e.x, e.y, ENEMY_W[e.kind], ENEMY_H[e.kind])
        -- Eyes / details
        gfx.setColor(1, 1, 0.3, 0.9)
        if e.kind == EN_WALKER then
            gfx.rectangle("fill", e.x + 4, e.y + 4, 4, 4)
            gfx.rectangle("fill", e.x + 12, e.y + 4, 4, 4)
        elseif e.kind == EN_FLYER then
            gfx.circle("fill", e.x + ENEMY_W[EN_FLYER] / 2, e.y + ENEMY_H[EN_FLYER] / 2, 4)
        elseif e.kind == EN_TURRET then
            -- Barrel
            gfx.setColor(0.5, 0.15, 0.15, 1)
            local tx = e.x + ENEMY_W[EN_TURRET] / 2
            local ty = e.y + ENEMY_H[EN_TURRET] / 2
            local pdx = player.x - tx
            local pdy = player.y - ty
            local pdist = math.sqrt(pdx * pdx + pdy * pdy)
            if pdist > 1 then
                gfx.line(tx, ty, tx + (pdx / pdist) * 16, ty + (pdy / pdist) * 16)
            end
        end
    end

    -- Player bullets
    gfx.setColor(COL_BULLET[1], COL_BULLET[2], COL_BULLET[3], 1)
    for i = 1, #bullets do
        local b = bullets[i]
        gfx.rectangle("fill", b.x - BULLET_W / 2, b.y - BULLET_H / 2, BULLET_W, BULLET_H)
    end

    -- Enemy bullets
    gfx.setColor(0.9, 0.3, 0.3, 1)
    for i = 1, #enemy_bullets do
        local b = enemy_bullets[i]
        gfx.circle("fill", b.x, b.y, 3)
    end

    -- Energy beam
    if beam_active then
        local bx = player.x + PLAYER_W / 2
        local by = player.y + PLAYER_H / 2
        local a = beam_angle
        local ex = bx + math.cos(a) * BEAM_RANGE * facing
        local ey = by + math.sin(a) * BEAM_RANGE
        -- Glow (wider, transparent)
        gfx.setColor(COL_BEAM[1], COL_BEAM[2], COL_BEAM[3], 0.25)
        gfx.line(bx, by - 2, ex, ey - 2)
        gfx.line(bx, by + 2, ex, ey + 2)
        -- Core beam
        gfx.setColor(COL_BEAM[1], COL_BEAM[2], COL_BEAM[3], 0.9)
        gfx.line(bx, by, ex, ey)
        -- Beam tip
        gfx.setColor(1, 1, 1, 0.8)
        gfx.circle("fill", ex, ey, 4)
    end

    -- Player
    local show_player = true
    if invuln_timer > 0 then
        show_player = math.floor(invuln_timer * 10) % 2 == 0
    end
    if show_player then
        gfx.setColor(COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3], 1)
        gfx.rectangle("fill", player.x, player.y, PLAYER_W, PLAYER_H)
        -- Visor
        gfx.setColor(0.6, 0.9, 1.0, 0.9)
        local vx = facing > 0 and (player.x + PLAYER_W - 8) or (player.x + 2)
        gfx.rectangle("fill", vx, player.y + 5, 6, 4)
        -- Arm / gun
        gfx.setColor(0.4, 0.4, 0.5, 1)
        local gx = facing > 0 and (player.x + PLAYER_W) or (player.x - 6)
        gfx.rectangle("fill", gx, player.y + PLAYER_H * 0.35, 6, 4)
    end

    -- Weapon flash overlay
    if flash_alpha.a > 0.01 then
        gfx.setColor(1, 1, 0.8, flash_alpha.a * 0.3)
        gfx.rectangle("fill", player.x - 10, player.y - 10, PLAYER_W + 20, PLAYER_H + 20)
    end

    -- Particles
    ps_impact:draw()
    ps_explode:draw()
    ps_beam:draw()
    ps_pickup:draw()

    camera:reset()

    -- Level complete banner
    if current_state == STATE.LEVEL_COMPLETE then
        gfx.setColor(0.1, 0.7, 0.3, 1)
        gfx.print("LEVEL " .. current_level .. " COMPLETE!", SCREEN_W / 2 - 120, banner.y, 3)
        gfx.setColor(0.8, 0.8, 0.9, 1)
        gfx.print("Press F to continue", SCREEN_W / 2 - 80, banner.y + 50, 1.5)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD overlay)
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    if current_state ~= STATE.PLAYING and current_state ~= STATE.LEVEL_COMPLETE then return end

    -- HP bar
    gfx.setColor(0.2, 0.2, 0.2, 0.7)
    gfx.rectangle("fill", 10, 10, 110, 18)
    gfx.setColor(0.2, 0.8, 0.3, 1)
    gfx.rectangle("fill", 12, 12, (hp / MAX_HP) * 106, 14)
    gfx.setColor(1, 1, 1, 1)
    gfx.print("HP", 14, 12, 1)

    -- Ammo bar
    gfx.setColor(0.2, 0.2, 0.2, 0.7)
    gfx.rectangle("fill", 10, 32, 110, 18)
    gfx.setColor(0.3, 0.6, 1.0, 1)
    gfx.rectangle("fill", 12, 34, (ammo / MAX_AMMO) * 106, 14)
    gfx.setColor(1, 1, 1, 1)
    gfx.print("AMMO", 14, 34, 1)

    -- Weapon indicator
    local weapon_name = has_spread and "SPREAD" or "NORMAL"
    local wc = has_spread and { 1, 0.4, 0.4 } or { 0.8, 0.8, 0.3 }
    gfx.setColor(wc[1], wc[2], wc[3], 1)
    gfx.print(weapon_name, 14, 56, 1)

    -- Score
    gfx.setColor(1, 1, 1, 1)
    gfx.print("SCORE: " .. score, SCREEN_W - 180, 12, 1.2)

    -- Level
    gfx.setColor(0.7, 0.7, 0.8, 1)
    gfx.print("LEVEL " .. current_level, SCREEN_W - 180, 34, 1)

    -- FPS
    gfx.setColor(0.5, 0.5, 0.5, 0.7)
    gfx.print("FPS: " .. lurek.timer.getFPS(), SCREEN_W - 90, SCREEN_H - 20, 1)
end
