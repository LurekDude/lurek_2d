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

local SCREEN_W, SCREEN_H = 800, 600
local TILE            = 32
local MAP_COLS, MAP_ROWS = 26, 15

local STATE = { TITLE = 1, PLAYING = 2, LEVEL_COMPLETE = 3, GAME_OVER = 4 }

-- Enemy constants (grouped into EN to save upvalues)
local EN = {
    WALKER=1, FLYER=2, TURRET=3,
    HP    = {[1]=1, [2]=2, [3]=3},
    SPEED = {[1]=60, [2]=50, [3]=0},
    W     = {[1]=20, [2]=18, [3]=24},
    H     = {[1]=22, [2]=18, [3]=20},
    SCORE=50, TURRET_INTERVAL=2.0, TURRET_BULLET_SPEED=200,
}
-- Powerup constants
local PU = { SPREAD=1, HEALTH=2, AMMO=3, SCORE=25 }
-- Player/weapon constants (grouped into K to save upvalues)
local K = {
    PW=24, PH=28, PSPD=180, GRAV=800, JVEL=-440, MAX_HP=5, MAX_AMMO=100,
    BSPD=360, BW=6, BH=4, FIRE_CD=0.12, BEAM_RANGE=220, BEAM_DRAIN=3, SPREAD=0.18,
}
local current_state = STATE.TITLE





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

local hp, ammo, score, high_score = K.MAX_HP, K.MAX_AMMO, 0, 0
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
                enemies[#enemies + 1] = { kind = EN.WALKER, x = wx, y = wy, hp = EN.HP[EN.WALKER], dir = 1, timer = 0 }
            elseif ch == "F" then
                enemies[#enemies + 1] = { kind = EN.FLYER, x = wx, y = wy, hp = EN.HP[EN.FLYER], base_y = wy, t = math.random() * 6.28, timer = 0 }
            elseif ch == "T" then
                enemies[#enemies + 1] = { kind = EN.TURRET, x = wx, y = wy, hp = EN.HP[EN.TURRET], timer = math.random() * EN.TURRET_INTERVAL }
            elseif ch == "S" then
                powerups[#powerups + 1] = { kind = PU.SPREAD, x = wx, y = wy, t = math.random() * 6.28 }
            elseif ch == "H" then
                powerups[#powerups + 1] = { kind = PU.HEALTH, x = wx, y = wy, t = math.random() * 6.28 }
            elseif ch == "A" then
                powerups[#powerups + 1] = { kind = PU.AMMO, x = wx, y = wy, t = math.random() * 6.28 }
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
    bullets[#bullets + 1] = { x = x, y = y, dx = dx * K.BSPD, dy = dy * K.BSPD }
end

local function fire_spread(x, y)
    fire_bullet(x, y, facing, 0)
    fire_bullet(x, y, facing, -K.SPREAD * facing * 2)
    fire_bullet(x, y, facing, K.SPREAD * facing * 2)
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
-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Turrican — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.12)

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
            hp = K.MAX_HP
            ammo = K.MAX_AMMO
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
    player.vx = dx * K.PSPD

    -- Jump
    if lurek.input.wasActionPressed("jump") and player.on_ground then
        player.vy = K.JVEL
        player.on_ground = false
    end

    -- Gravity
    player.vy = player.vy + K.GRAV * dt

    -- Horizontal movement + collision
    local nx = player.x + player.vx * dt
    if not tile_collision(nx, player.y, K.PW, K.PH) then
        player.x = nx
    end
    player.x = clamp(player.x, 0, level_w - K.PW)

    -- Vertical movement + collision
    local ny = player.y + player.vy * dt
    if tile_collision(player.x, ny, K.PW, K.PH) then
        if player.vy > 0 then
            player.on_ground = true
            player.vy = 0
            -- Snap to tile top
            local snapped = false
            for i = 1, #tiles do
                local t = tiles[i]
                if not t.exit and aabb(player.x, ny, K.PW, K.PH, t.x, t.y, TILE, TILE) then
                    player.y = t.y - K.PH
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
        fire_timer = K.FIRE_CD
        local bx = player.x + (facing > 0 and K.PW or 0)
        local by = player.y + K.PH * 0.4
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
        ammo = ammo - K.BEAM_DRAIN * dt
        if ammo < 0 then ammo = 0; beam_active = false end
        beam_angle = beam_angle + dt * 2.5
        if beam_angle > 1.2 then beam_angle = -1.2 end

        -- Beam endpoint
        local bx = player.x + K.PW / 2
        local by = player.y + K.PH / 2
        local a = beam_angle
        local ex = bx + math.cos(a) * K.BEAM_RANGE * facing
        local ey = by + math.sin(a) * K.BEAM_RANGE
        ps_beam:emit(2, ex, ey)

        -- Beam vs enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            local ecx = e.x + EN.W[e.kind] / 2
            local ecy = e.y + EN.H[e.kind] / 2
            -- Check distance from beam line
            local dx2 = ecx - bx
            local dy2 = ecy - by
            local dist = math.sqrt(dx2 * dx2 + dy2 * dy2)
            if dist < K.BEAM_RANGE + 10 then
                local dot = dx2 * math.cos(a) * facing + dy2 * math.sin(a)
                if dot > 0 then
                    local cross = math.abs(dx2 * math.sin(a) - dy2 * math.cos(a) * facing)
                    if cross < 20 then
                        e.hp = e.hp - 4 * dt
                        if e.hp <= 0 then
                            score = score + EN.SCORE
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
        if not remove and tile_collision(b.x, b.y, K.BW, K.BH) then
            remove = true
            ps_impact:emit(6, b.x, b.y)
        end

        -- Enemy hit
        if not remove then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if aabb(b.x, b.y, K.BW, K.BH, e.x, e.y, EN.W[e.kind], EN.H[e.kind]) then
                    e.hp = e.hp - 1
                    remove = true
                    ps_impact:emit(8, b.x, b.y)
                    if e.hp <= 0 then
                        score = score + EN.SCORE
                        ps_explode:emit(20, e.x + EN.W[e.kind] / 2, e.y + EN.H[e.kind] / 2)
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
        if not remove and aabb(b.x, b.y, 4, 4, player.x, player.y, K.PW, K.PH) then
            remove = true
            damage_player()
        end
        if remove then table.remove(enemy_bullets, i) end
    end

    -- ── Update enemies ────────────────────────────────────────
    for i = 1, #enemies do
        local e = enemies[i]
        if e.kind == EN.WALKER then
            e.x = e.x + EN.SPEED[EN.WALKER] * e.dir * dt
            -- Reverse at edges or tile boundaries
            local ahead = e.x + (e.dir > 0 and EN.W[EN.WALKER] + 2 or -2)
            if ahead < 0 or ahead > level_w or tile_collision(ahead, e.y, 2, EN.H[EN.WALKER]) then
                e.dir = -e.dir
            end
            -- Check floor
            if not tile_collision(e.x + EN.W[EN.WALKER] / 2, e.y + EN.H[EN.WALKER] + 2, 2, 2) then
                e.dir = -e.dir
            end
            -- Contact damage
            if aabb(player.x, player.y, K.PW, K.PH, e.x, e.y, EN.W[EN.WALKER], EN.H[EN.WALKER]) then
                damage_player()
            end

        elseif e.kind == EN.FLYER then
            e.t = e.t + dt * 2.2
            e.y = e.base_y + math.sin(e.t) * 40
            -- Move toward player slowly
            if player.x > e.x then e.x = e.x + EN.SPEED[EN.FLYER] * dt
            else e.x = e.x - EN.SPEED[EN.FLYER] * dt end
            -- Contact damage
            if aabb(player.x, player.y, K.PW, K.PH, e.x, e.y, EN.W[EN.FLYER], EN.H[EN.FLYER]) then
                damage_player()
            end

        elseif e.kind == EN.TURRET then
            e.timer = e.timer + dt
            if e.timer >= EN.TURRET_INTERVAL then
                e.timer = 0
                local dx2 = player.x - e.x
                local dy2 = player.y - e.y
                local dist = math.sqrt(dx2 * dx2 + dy2 * dy2)
                if dist > 1 then
                    enemy_bullets[#enemy_bullets + 1] = {
                        x = e.x + EN.W[EN.TURRET] / 2,
                        y = e.y + EN.H[EN.TURRET] / 2,
                        dx = (dx2 / dist) * EN.TURRET_BULLET_SPEED,
                        dy = (dy2 / dist) * EN.TURRET_BULLET_SPEED,
                    }
                end
            end
            -- Contact damage
            if aabb(player.x, player.y, K.PW, K.PH, e.x, e.y, EN.W[EN.TURRET], EN.H[EN.TURRET]) then
                damage_player()
            end
        end
    end

    -- ── Powerups ──────────────────────────────────────────────
    for i = #powerups, 1, -1 do
        local p = powerups[i]
        p.t = p.t + dt * 3
        if aabb(player.x, player.y, K.PW, K.PH, p.x + 4, p.y + 4, 24, 24) then
            score = score + PU.SCORE
            ps_pickup:emit(15, p.x + 16, p.y + 16)
            if p.kind == PU.SPREAD then
                has_spread = true
                -- Weapon switch flash
                flash_alpha.a = 1.0
                lurek.tween.to(flash_alpha, 0.3, { a = 0 })
            elseif p.kind == PU.HEALTH then
                hp = math.min(hp + 2, K.MAX_HP)
            elseif p.kind == PU.AMMO then
                ammo = math.min(ammo + 25, K.MAX_AMMO)
            end
            table.remove(powerups, i)
        end
    end

    -- ── Exit check ────────────────────────────────────────────
    if check_exit(player.x, player.y, K.PW, K.PH) then
        current_state = STATE.LEVEL_COMPLETE
        banner.y = -60
        lurek.tween.to(banner, 0.5, { y = SCREEN_H / 2 - 30 })
    end

    -- ── Camera ────────────────────────────────────────────────
    local target_cx = player.x - SCREEN_W / 2 + K.PW / 2
    cam_x = clamp(target_cx, 0, math.max(0, level_w - SCREEN_W))
    camera:setPosition(cam_x, 0)
    camera:update(dt)
end

-- ---------------------------------------------------------------------------
-- Render (world space — camera-transformed)
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.4, 0.85, 1.0, 1)
        text_("TURRICAN", SCREEN_W / 2 - 100, SCREEN_H / 3, 4)
        lurek.render.setColor(0.7, 0.7, 0.8, 1)
        text_("A Lurek2D Tribute", SCREEN_W / 2 - 80, SCREEN_H / 3 + 60, 1.5)
        lurek.render.setColor(0.9, 0.9, 0.5, math.abs(math.sin(lurek.timer.getTime() * 2.5)))
        text_("PRESS F OR SPACE TO START", SCREEN_W / 2 - 120, SCREEN_H / 2 + 40, 1.5)
        lurek.render.setColor(0.5, 0.5, 0.6, 1)
        text_("Inspired by Manfred Trenz (1990)", SCREEN_W / 2 - 120, SCREEN_H - 80, 1)
        return
    end

    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        text_("GAME OVER", SCREEN_W / 2 - 80, SCREEN_H / 3, 3)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        text_("Score: " .. score, SCREEN_W / 2 - 60, SCREEN_H / 2, 2)
        text_("High Score: " .. high_score, SCREEN_W / 2 - 80, SCREEN_H / 2 + 40, 1.5)
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        text_("Press F to return to title", SCREEN_W / 2 - 100, SCREEN_H / 2 + 100, 1)
        return
    end

    camera:apply()

    -- Tiles
    for i = 1, #tiles do
        local t = tiles[i]
        if t.exit then
            lurek.render.setColor(COL_EXIT[1], COL_EXIT[2], COL_EXIT[3], 1)
        else
            -- Slight shade variation
            local shade = ((t.x + t.y) % 64 < 32) and 1.0 or 0.85
            lurek.render.setColor(COL_BLOCK[1] * shade, COL_BLOCK[2] * shade, COL_BLOCK[3] * shade, 1)
        end
        rect("fill", t.x, t.y, TILE, TILE)
        -- Tile outline
        lurek.render.setColor(0.15, 0.12, 0.08, 0.5)
        rect("line", t.x, t.y, TILE, TILE)
    end

    -- Powerups (spinning diamonds)
    for i = 1, #powerups do
        local p = powerups[i]
        local col
        if p.kind == PU.SPREAD then col = COL_PU_SPREAD
        elseif p.kind == PU.HEALTH then col = COL_PU_HEALTH
        else col = COL_PU_AMMO end

        local pulse = 0.7 + 0.3 * math.sin(p.t)
        lurek.render.setColor(col[1], col[2], col[3], pulse)
        -- Diamond shape (rotated square approximation)
        local cx, cy = p.x + 16, p.y + 16
        local sz = 10 + math.sin(p.t * 0.8) * 2
        rect("fill", cx - sz / 2, cy - sz / 2, sz, sz)
        lurek.render.setColor(1, 1, 1, 0.4)
        rect("line", cx - sz / 2 - 1, cy - sz / 2 - 1, sz + 2, sz + 2)
    end

    -- Enemies
    for i = 1, #enemies do
        local e = enemies[i]
        local col
        if e.kind == EN.WALKER then col = COL_WALKER
        elseif e.kind == EN.FLYER then col = COL_FLYER
        else col = COL_TURRET end
        lurek.render.setColor(col[1], col[2], col[3], 1)
        rect("fill", e.x, e.y, EN.W[e.kind], EN.H[e.kind])
        -- Eyes / details
        lurek.render.setColor(1, 1, 0.3, 0.9)
        if e.kind == EN.WALKER then
            rect("fill", e.x + 4, e.y + 4, 4, 4)
            rect("fill", e.x + 12, e.y + 4, 4, 4)
        elseif e.kind == EN.FLYER then
            circ("fill", e.x + EN.W[EN.FLYER] / 2, e.y + EN.H[EN.FLYER] / 2, 4)
        elseif e.kind == EN.TURRET then
            -- Barrel
            lurek.render.setColor(0.5, 0.15, 0.15, 1)
            local tx = e.x + EN.W[EN.TURRET] / 2
            local ty = e.y + EN.H[EN.TURRET] / 2
            local pdx = player.x - tx
            local pdy = player.y - ty
            local pdist = math.sqrt(pdx * pdx + pdy * pdy)
            if pdist > 1 then
                ln(tx, ty, tx + (pdx / pdist) * 16, ty + (pdy / pdist) * 16)
            end
        end
    end

    -- Player bullets
    lurek.render.setColor(COL_BULLET[1], COL_BULLET[2], COL_BULLET[3], 1)
    for i = 1, #bullets do
        local b = bullets[i]
        rect("fill", b.x - K.BW / 2, b.y - K.BH / 2, K.BW, K.BH)
    end

    -- Enemy bullets
    lurek.render.setColor(0.9, 0.3, 0.3, 1)
    for i = 1, #enemy_bullets do
        local b = enemy_bullets[i]
        circ("fill", b.x, b.y, 3)
    end

    -- Energy beam
    if beam_active then
        local bx = player.x + K.PW / 2
        local by = player.y + K.PH / 2
        local a = beam_angle
        local ex = bx + math.cos(a) * K.BEAM_RANGE * facing
        local ey = by + math.sin(a) * K.BEAM_RANGE
        -- Glow (wider, transparent)
        lurek.render.setColor(COL_BEAM[1], COL_BEAM[2], COL_BEAM[3], 0.25)
        ln(bx, by - 2, ex, ey - 2)
        ln(bx, by + 2, ex, ey + 2)
        -- Core beam
        lurek.render.setColor(COL_BEAM[1], COL_BEAM[2], COL_BEAM[3], 0.9)
        ln(bx, by, ex, ey)
        -- Beam tip
        lurek.render.setColor(1, 1, 1, 0.8)
        circ("fill", ex, ey, 4)
    end

    -- Player
    local show_player = true
    if invuln_timer > 0 then
        show_player = math.floor(invuln_timer * 10) % 2 == 0
    end
    if show_player then
        lurek.render.setColor(COL_PLAYER[1], COL_PLAYER[2], COL_PLAYER[3], 1)
        rect("fill", player.x, player.y, K.PW, K.PH)
        -- Visor
        lurek.render.setColor(0.6, 0.9, 1.0, 0.9)
        local vx = facing > 0 and (player.x + K.PW - 8) or (player.x + 2)
        rect("fill", vx, player.y + 5, 6, 4)
        -- Arm / gun
        lurek.render.setColor(0.4, 0.4, 0.5, 1)
        local gx = facing > 0 and (player.x + K.PW) or (player.x - 6)
        rect("fill", gx, player.y + K.PH * 0.35, 6, 4)
    end

    -- Weapon flash overlay
    if flash_alpha.a > 0.01 then
        lurek.render.setColor(1, 1, 0.8, flash_alpha.a * 0.3)
        rect("fill", player.x - 10, player.y - 10, K.PW + 20, K.PH + 20)
    end

    -- Particles
    ps_impact:draw()
    ps_explode:draw()
    ps_beam:draw()
    ps_pickup:draw()

    camera:reset()

    -- Level complete banner
    if current_state == STATE.LEVEL_COMPLETE then
        lurek.render.setColor(0.1, 0.7, 0.3, 1)
        text_("LEVEL " .. current_level .. " COMPLETE!", SCREEN_W / 2 - 120, banner.y, 3)
        lurek.render.setColor(0.8, 0.8, 0.9, 1)
        text_("Press F to continue", SCREEN_W / 2 - 80, banner.y + 50, 1.5)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space — HUD overlay)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state ~= STATE.PLAYING and current_state ~= STATE.LEVEL_COMPLETE then return end

    -- HP bar
    lurek.render.setColor(0.2, 0.2, 0.2, 0.7)
    rect("fill", 10, 10, 110, 18)
    lurek.render.setColor(0.2, 0.8, 0.3, 1)
    rect("fill", 12, 12, (hp / K.MAX_HP) * 106, 14)
    lurek.render.setColor(1, 1, 1, 1)
    text_("HP", 14, 12, 1)

    -- Ammo bar
    lurek.render.setColor(0.2, 0.2, 0.2, 0.7)
    rect("fill", 10, 32, 110, 18)
    lurek.render.setColor(0.3, 0.6, 1.0, 1)
    rect("fill", 12, 34, (ammo / K.MAX_AMMO) * 106, 14)
    lurek.render.setColor(1, 1, 1, 1)
    text_("AMMO", 14, 34, 1)

    -- Weapon indicator
    local weapon_name = has_spread and "SPREAD" or "NORMAL"
    local wc = has_spread and { 1, 0.4, 0.4 } or { 0.8, 0.8, 0.3 }
    lurek.render.setColor(wc[1], wc[2], wc[3], 1)
    text_(weapon_name, 14, 56, 1)

    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    text_("SCORE: " .. score, SCREEN_W - 180, 12, 1.2)

    -- Level
    lurek.render.setColor(0.7, 0.7, 0.8, 1)
    text_("LEVEL " .. current_level, SCREEN_W - 180, 34, 1)

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5, 0.7)
    text_("FPS: " .. lurek.timer.getFPS(), SCREEN_W - 90, SCREEN_H - 20, 1)
end
