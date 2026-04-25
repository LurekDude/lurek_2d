-- ============================================================================
--  Platformer — Classic side-scrolling 2D platformer
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/platformer
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A/D or ←/→
--    jump       : Space / W / ↑
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 800, 600
local TILE               = 16
local LEVEL_COLS         = 40
local LEVEL_ROWS         = 15
local LEVEL_W            = LEVEL_COLS * TILE  -- 640
local LEVEL_H            = LEVEL_ROWS * TILE  -- 240

local PLAYER_W, PLAYER_H = 20, 28
local PLAYER_SPEED       = 220
local JUMP_VEL           = -450
local GRAVITY            = 800
local COYOTE_TIME        = 0.1
local WALL_SLIDE_GRAVITY = 200

-- Tile codes
local T_EMPTY   = 0
local T_GROUND  = 1
local T_PLATFORM = 2
local T_SPIKE   = 3
local T_COIN    = 4
local T_ENEMY   = 5
local T_GOAL    = 6
local T_MOVING  = 7

-- ── Scene state enum ──────────────────────────────────────────────────────
local STATE = { TITLE = 1, PLAYING = 2, LEVEL_COMPLETE = 3, GAME_OVER = 4 }
local game_state = STATE.TITLE

-- ── Mutable game state ───────────────────────────────────────────────────
local player = {
    x = 0, y = 0, vx = 0, vy = 0,
    on_ground = false, facing = 1,
    coyote = 0, wall_touch = 0,
}
local score       = 0
local lives       = 3
local current_lvl = 1
local tiles       = {}
local coins       = {}
local enemies     = {}
local moving_plats = {}
local goal        = nil
local cam_x       = 0
local cam_y_off   = 0

-- Particles
local dust_ps        = nil
local coin_ps        = nil
local stomp_ps       = nil
local death_ps       = nil

-- Tween / UI
local score_pop      = { text = "", alpha = 0, y = 0 }
local banner         = { text = "", alpha = 0, scale = 0 }
local title_blink    = 0

-- ── Level data ────────────────────────────────────────────────────────────
-- 0=empty, 1=ground, 2=platform, 3=spike, 4=coin, 5=enemy, 6=goal, 7=moving
local LEVELS = {}

LEVELS[1] = {
    "1111111111111111111111111111111111111111",
    "0000000000000000000000000000000000000000",
    "0000000000000000000000000000000000000000",
    "0000000000000000000000000000000000000000",
    "0000000000022200000000000000000000000000",
    "0000000000000000002220000000000000000000",
    "0000040400000004000000000022200000000000",
    "0000222000000022200000000000000400000060",
    "0000000000000000000004000000002220000011",
    "0000000000040000000022200000000000000011",
    "0000000004022000000000000040000000000011",
    "0000000002200000000000000022000050000011",
    "0000050000000000007770000000000022000011",
    "0022200000000000000000000000000000000011",
    "1111111131111111111111111111311111111111",
}

LEVELS[2] = {
    "1111111111111111111111111111111111111111",
    "0000000000000000000000000000000000000000",
    "0000000000000000000000000000000000000000",
    "0000000000000000000400000000000000000000",
    "0000000000000000002220000000000000000000",
    "0000040000000000000000000004000000000060",
    "0000222000000040000000000022200000000011",
    "0000000000000222000000000000000000000011",
    "0000000000000000000040000000004000000011",
    "0000004000000000000222000000022000000011",
    "0000022000007770000000000000000000050011",
    "0000000000000000000000040000000000222011",
    "0050000000000000000000222000000000000011",
    "0022200000000000000000000000000000000011",
    "1111131111113111111111111111131111111111",
}

LEVELS[3] = {
    "1111111111111111111111111111111111111111",
    "0000000000000000000000000000000000000000",
    "0000000000000000000000000000000000000060",
    "0000000000000000000000000000000000000011",
    "0000000000000040000000000000004000000011",
    "0000000000000222000000000000022000000011",
    "0000040000000000000004000000000000000011",
    "0000222000000000000022200050000000000011",
    "0000000000040000000000000022000000000011",
    "0000000000222000007770000000000004000011",
    "0050000000000000000000000000000022000011",
    "0022200000000000000000004000000000000011",
    "0000000000000050000000022000000000000011",
    "0000000000000222000000000000000000000011",
    "1111131113111111131111111111311111111111",
}

-- ── Parse level into game objects ─────────────────────────────────────────
local function load_level(num)
    tiles       = {}
    coins       = {}
    enemies     = {}
    moving_plats = {}
    goal        = nil

    local data = LEVELS[num]
    for r = 1, LEVEL_ROWS do
        tiles[r] = {}
        local row_str = data[r]
        for c = 1, LEVEL_COLS do
            local ch = tonumber(row_str:sub(c, c))
            if ch == T_COIN then
                tiles[r][c] = T_EMPTY
                coins[#coins + 1] = { x = (c - 1) * TILE + TILE / 2, y = (r - 1) * TILE + TILE / 2, alive = true }
            elseif ch == T_ENEMY then
                tiles[r][c] = T_EMPTY
                enemies[#enemies + 1] = {
                    x = (c - 1) * TILE, y = (r - 1) * TILE - 4,
                    w = 16, h = 20, vx = 40, alive = true,
                    min_x = 0, max_x = LEVEL_W,
                }
                -- find platform bounds for patrol
                local e = enemies[#enemies]
                local left = c
                while left > 1 and (data[r + 1] and tonumber(data[r + 1]:sub(left, left)) or 0) ~= T_EMPTY do
                    left = left - 1
                end
                local right = c
                while right < LEVEL_COLS and (data[r + 1] and tonumber(data[r + 1]:sub(right, right)) or 0) ~= T_EMPTY do
                    right = right + 1
                end
                e.min_x = (left - 1) * TILE
                e.max_x = right * TILE - e.w
            elseif ch == T_GOAL then
                tiles[r][c] = T_EMPTY
                goal = { x = (c - 1) * TILE, y = (r - 1) * TILE, w = TILE, h = TILE }
            elseif ch == T_MOVING then
                tiles[r][c] = T_EMPTY
                moving_plats[#moving_plats + 1] = {
                    x = (c - 1) * TILE, y = (r - 1) * TILE,
                    w = TILE, h = TILE,
                    base_x = (c - 1) * TILE,
                    range = 48, speed = 1.5, phase = math.random() * 6.28,
                }
            else
                tiles[r][c] = ch
            end
        end
    end

    -- reset player
    player.x = 2 * TILE
    player.y = (LEVEL_ROWS - 2) * TILE - PLAYER_H
    player.vx = 0
    player.vy = 0
    player.on_ground = false
    player.coyote = 0
    player.wall_touch = 0
    cam_x = 0
end

-- ── Collision helpers ─────────────────────────────────────────────────────
local function tile_at(px, py)
    local c = math.floor(px / TILE) + 1
    local r = math.floor(py / TILE) + 1
    if c < 1 or c > LEVEL_COLS or r < 1 or r > LEVEL_ROWS then return T_GROUND end
    return tiles[r][c]
end

local function is_solid(t)
    return t == T_GROUND or t == T_PLATFORM
end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- Check if player stands on a moving platform, return it or nil
local function on_moving_platform()
    local foot_y = player.y + PLAYER_H
    for _, p in ipairs(moving_plats) do
        if player.x + PLAYER_W > p.x and player.x < p.x + p.w then
            if math.abs(foot_y - p.y) < 3 and player.vy >= 0 then
                return p
            end
        end
    end
    return nil
end

-- ── Engine callbacks ──────────────────────────────────────────────────────

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
    lurek.window.setTitle("Platformer — Lurek2D")
    lurek.render.setBackgroundColor(0.3, 0.5, 0.8)

    -- Input actions
    lurek.input.bind("left",  {"a", "left"})
    lurek.input.bind("right", {"d", "right"})
    lurek.input.bind("jump",  {"space", "w", "up"})
    lurek.input.bind("quit",  {"escape"})

    -- Particle systems
    dust_ps = lurek.particle.newSystem({
        maxParticles = 20, lifetime = 0.3,
        speed = 30, spread = 3.14,
        sizeStart = 3, sizeEnd = 1,
        colorStart = {0.7, 0.6, 0.4, 0.8},
        colorEnd   = {0.7, 0.6, 0.4, 0.0},
    })
    coin_ps = lurek.particle.newSystem({
        maxParticles = 15, lifetime = 0.4,
        speed = 60, spread = 6.28,
        sizeStart = 3, sizeEnd = 1,
        colorStart = {1.0, 0.9, 0.2, 1.0},
        colorEnd   = {1.0, 0.9, 0.2, 0.0},
    })
    stomp_ps = lurek.particle.newSystem({
        maxParticles = 12, lifetime = 0.35,
        speed = 50, spread = 3.14,
        sizeStart = 4, sizeEnd = 1,
        colorStart = {0.9, 0.3, 0.1, 0.9},
        colorEnd   = {0.5, 0.1, 0.0, 0.0},
    })
    death_ps = lurek.particle.newSystem({
        maxParticles = 30, lifetime = 0.5,
        speed = 100, spread = 6.28,
        sizeStart = 4, sizeEnd = 2,
        colorStart = {1.0, 0.2, 0.2, 1.0},
        colorEnd   = {0.5, 0.0, 0.0, 0.0},
    })
end

local function _ready_setup()
    load_level(1)
end

-- ── Process ───────────────────────────────────────────────────────────────
function lurek.process(dt)
    title_blink = title_blink + dt

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── Title ─────────────────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        if lurek.input.wasActionPressed("return") then
            game_state = STATE.PLAYING
            score = 0
            lives = 3
            current_lvl = 1
            load_level(1)
        end
        return
    end

    -- ── Level complete ────────────────────────────────────────────────────
    if game_state == STATE.LEVEL_COMPLETE then
        if lurek.input.wasActionPressed("return") then
            game_state = STATE.PLAYING
        end
        return
    end

    -- ── Game over ─────────────────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("return") then
            game_state = STATE.TITLE
        end
        return
    end

    -- ── Playing ───────────────────────────────────────────────────────────
    local move_x = 0
    if lurek.input.isActionDown("left")  then move_x = move_x - 1 end
    if lurek.input.isActionDown("right") then move_x = move_x + 1 end
    if move_x ~= 0 then player.facing = move_x end

    player.vx = move_x * PLAYER_SPEED

    -- Coyote time tracking
    if player.on_ground then
        player.coyote = COYOTE_TIME
    else
        player.coyote = player.coyote - dt
    end

    -- Jump
    if lurek.input.wasActionPressed("jump") and player.coyote > 0 then
        player.vy = JUMP_VEL
        player.on_ground = false
        player.coyote = 0
    end

    -- Wall slide detection
    local wall_sliding = false
    if not player.on_ground and player.vy > 0 then
        local check_x = (move_x > 0) and (player.x + PLAYER_W + 1) or (player.x - 1)
        local mid_y = player.y + PLAYER_H / 2
        if is_solid(tile_at(check_x, mid_y)) and move_x ~= 0 then
            wall_sliding = true
        end
    end

    -- Gravity
    if wall_sliding then
        player.vy = player.vy + WALL_SLIDE_GRAVITY * dt
        if player.vy > 100 then player.vy = 100 end
    else
        player.vy = player.vy + GRAVITY * dt
    end
    if player.vy > 600 then player.vy = 600 end

    -- Update moving platforms
    local time_now = lurek.timer.getTime()
    for _, mp in ipairs(moving_plats) do
        local old_x = mp.x
        mp.x = mp.base_x + math.sin(time_now * mp.speed + mp.phase) * mp.range
        mp.dx = mp.x - old_x
    end

    -- Horizontal movement + collision
    local new_x = player.x + player.vx * dt

    -- Carry by moving platform
    local mp_on = on_moving_platform()
    if mp_on then
        new_x = new_x + (mp_on.dx or 0)
    end

    -- Clamp to level
    if new_x < 0 then new_x = 0 end
    if new_x + PLAYER_W > LEVEL_W then new_x = LEVEL_W - PLAYER_W end

    -- X collision
    local step_dir = (new_x > player.x) and 1 or -1
    local check_x_edge = (step_dir > 0) and (new_x + PLAYER_W - 1) or new_x
    local blocked_x = false
    for oy = 0, PLAYER_H - 1, 8 do
        if is_solid(tile_at(check_x_edge, player.y + oy)) then
            blocked_x = true
            break
        end
    end
    if not blocked_x then
        player.x = new_x
    end

    -- Vertical movement + collision
    local new_y = player.y + player.vy * dt
    player.on_ground = false

    if player.vy >= 0 then
        -- falling: check feet
        local foot_y = new_y + PLAYER_H
        local landed = false
        for ox = 2, PLAYER_W - 2, 4 do
            if is_solid(tile_at(player.x + ox, foot_y)) then
                landed = true
                break
            end
        end
        -- also check moving platforms
        if not landed then
            for _, mp in ipairs(moving_plats) do
                if player.x + PLAYER_W > mp.x and player.x < mp.x + mp.w then
                    if foot_y >= mp.y and player.y + PLAYER_H <= mp.y + 4 then
                        landed = true
                        new_y = mp.y - PLAYER_H
                        break
                    end
                end
            end
        end
        if landed then
            new_y = math.floor(foot_y / TILE) * TILE - PLAYER_H
            player.vy = 0
            if not player.on_ground then
                -- landing dust
                dust_ps:emit(player.x + PLAYER_W / 2, new_y + PLAYER_H, 6)
            end
            player.on_ground = true
        end
    else
        -- rising: check head
        for ox = 2, PLAYER_W - 2, 4 do
            if is_solid(tile_at(player.x + ox, new_y)) then
                new_y = (math.floor(new_y / TILE) + 1) * TILE
                player.vy = 0
                break
            end
        end
    end
    player.y = new_y

    -- Spike check
    local foot_tile = tile_at(player.x + PLAYER_W / 2, player.y + PLAYER_H - 1)
    if foot_tile == T_SPIKE then
        death_ps:emit(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, 20)
        lives = lives - 1
        if lives <= 0 then
            game_state = STATE.GAME_OVER
        else
            load_level(current_lvl)
        end
        return
    end

    -- Coin collection
    for _, c in ipairs(coins) do
        if c.alive then
            local dx = (player.x + PLAYER_W / 2) - c.x
            local dy = (player.y + PLAYER_H / 2) - c.y
            if math.abs(dx) < 14 and math.abs(dy) < 14 then
                c.alive = false
                score = score + 100
                coin_ps:emit(c.x, c.y, 10)
                -- Score popup tween
                score_pop.text = "+100"
                score_pop.alpha = 1.0
                score_pop.y = c.y - cam_y_off
                lurek.tween.to(score_pop, 0.7, { alpha = 0, y = score_pop.y - 30 })
            end
        end
    end

    -- Enemy update + collision
    for _, e in ipairs(enemies) do
        if e.alive then
            e.x = e.x + e.vx * dt
            if e.x <= e.min_x or e.x >= e.max_x then
                e.vx = -e.vx
            end

            -- Collision with player
            if rect_overlap(player.x, player.y, PLAYER_W, PLAYER_H, e.x, e.y, e.w, e.h) then
                -- Stomping: player above enemy midpoint and falling
                if player.vy > 0 and player.y + PLAYER_H < e.y + e.h / 2 + 6 then
                    e.alive = false
                    player.vy = JUMP_VEL * 0.6
                    score = score + 200
                    stomp_ps:emit(e.x + e.w / 2, e.y + e.h / 2, 10)
                    score_pop.text = "+200"
                    score_pop.alpha = 1.0
                    score_pop.y = e.y - cam_y_off
                    lurek.tween.to(score_pop, 0.7, { alpha = 0, y = score_pop.y - 30 })
                else
                    death_ps:emit(player.x + PLAYER_W / 2, player.y + PLAYER_H / 2, 20)
                    lives = lives - 1
                    if lives <= 0 then
                        game_state = STATE.GAME_OVER
                    else
                        load_level(current_lvl)
                    end
                    return
                end
            end
        end
    end

    -- Goal check
    if goal and rect_overlap(player.x, player.y, PLAYER_W, PLAYER_H, goal.x, goal.y, goal.w, goal.h) then
        if current_lvl < #LEVELS then
            current_lvl = current_lvl + 1
            load_level(current_lvl)
            game_state = STATE.LEVEL_COMPLETE
            banner.text = "LEVEL " .. current_lvl
            banner.alpha = 0
            banner.scale = 0.5
            lurek.tween.to(banner, 0.5, { alpha = 1, scale = 1 })
        else
            -- Won the game
            game_state = STATE.LEVEL_COMPLETE
            banner.text = "YOU WIN!  SCORE: " .. score
            banner.alpha = 0
            banner.scale = 0.5
            lurek.tween.to(banner, 0.5, { alpha = 1, scale = 1 })
        end
        return
    end

    -- Fall off bottom
    if player.y > LEVEL_H + 40 then
        death_ps:emit(player.x + PLAYER_W / 2, LEVEL_H, 15)
        lives = lives - 1
        if lives <= 0 then
            game_state = STATE.GAME_OVER
        else
            load_level(current_lvl)
        end
        return
    end

    -- Camera follow
    local target_cx = player.x - SCREEN_W / 2 + PLAYER_W / 2
    cam_x = cam_x + (target_cx - cam_x) * 6 * dt
    if cam_x < 0 then cam_x = 0 end
    if cam_x > LEVEL_W - SCREEN_W then cam_x = math.max(0, LEVEL_W - SCREEN_W) end

    -- Vertical camera: keep level vertically centered with deadzone
    local level_top = (SCREEN_H - LEVEL_H) / 2
    cam_y_off = level_top

    -- Update particles
    dust_ps:update(dt)
    coin_ps:update(dt)
    stomp_ps:update(dt)
    death_ps:update(dt)
end

-- ── Render (world space) ──────────────────────────────────────────────────
function lurek.draw()
    if game_state == STATE.TITLE then return end

    local ox = -cam_x
    local oy = cam_y_off

    -- Draw tiles
    for r = 1, LEVEL_ROWS do
        for c = 1, LEVEL_COLS do
            local t = tiles[r][c]
            local tx = (c - 1) * TILE + ox
            local ty = (r - 1) * TILE + oy
            if t == T_GROUND then
                lurek.render.setColor(0.45, 0.30, 0.15, 1)
                rect(tx, ty, TILE, TILE)
            elseif t == T_PLATFORM then
                lurek.render.setColor(0.55, 0.38, 0.18, 1)
                rect(tx, ty, TILE, TILE)
            elseif t == T_SPIKE then
                lurek.render.setColor(0.9, 0.1, 0.1, 1)
                rect(tx, ty + TILE / 2, TILE, TILE / 2)
                -- triangle top (simplified as smaller rect)
                rect(tx + 3, ty + 2, TILE - 6, TILE / 2)
            end
        end
    end

    -- Moving platforms
    lurek.render.setColor(0.6, 0.45, 0.2, 1)
    for _, mp in ipairs(moving_plats) do
        rect(mp.x + ox, mp.y + oy, mp.w, mp.h)
    end

    -- Coins
    for _, c in ipairs(coins) do
        if c.alive then
            lurek.render.setColor(1.0, 0.85, 0.1, 1)
            circ(c.x + ox, c.y + oy, 5)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            lurek.render.setColor(0.85, 0.15, 0.1, 1)
            rect(e.x + ox, e.y + oy, e.w, e.h)
            -- Eyes
            lurek.render.setColor(1, 1, 1, 1)
            local ex = (e.vx > 0) and (e.x + 10) or (e.x + 3)
            rect(ex + ox, e.y + 4 + oy, 3, 3)
        end
    end

    -- Goal flag
    if goal then
        -- Pole
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        rect(goal.x + 6 + ox, goal.y - 16 + oy, 3, TILE + 16)
        -- Flag
        lurek.render.setColor(0.1, 0.85, 0.2, 1)
        rect(goal.x + 9 + ox, goal.y - 14 + oy, 10, 8)
    end

    -- Player
    local px = player.x + ox
    local py = player.y + oy
    -- Body
    lurek.render.setColor(0.2, 0.4, 0.9, 1)
    rect(px, py, PLAYER_W, PLAYER_H)
    -- Eyes
    lurek.render.setColor(1, 1, 1, 1)
    if player.facing > 0 then
        rect(px + 12, py + 6, 4, 4)
        rect(px + 12, py + 6, 4, 4)
    else
        rect(px + 4, py + 6, 4, 4)
        rect(px + 4, py + 6, 4, 4)
    end
    -- Pupil
    lurek.render.setColor(0, 0, 0, 1)
    if player.facing > 0 then
        rect(px + 14, py + 7, 2, 2)
    else
        rect(px + 4, py + 7, 2, 2)
    end

    -- Particles (world space)
    dust_ps:draw()
    coin_ps:draw()
    stomp_ps:draw()
    death_ps:draw()
end

-- ── Render UI (screen space) ──────────────────────────────────────────────
function lurek.draw_ui()
    -- ── Title screen ──────────────────────────────────────────────────────
    if game_state == STATE.TITLE then
        lurek.render.setColor(0.2, 0.4, 0.9, 1)
        text_("CLASSIC PLATFORMER", SCREEN_W / 2 - 140, SCREEN_H / 2 - 60, 32)
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 1)
            text_("PRESS ENTER", SCREEN_W / 2 - 80, SCREEN_H / 2 + 20, 20)
        end
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        text_("A/D or Arrows: Move  |  Space/W: Jump", SCREEN_W / 2 - 170, SCREEN_H / 2 + 70, 14)
        return
    end

    -- ── HUD ───────────────────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    text_("SCORE: " .. score, 10, 10, 18)
    text_("LIVES: " .. lives, 10, 34, 18)
    text_("LEVEL: " .. current_lvl .. "/" .. #LEVELS, 10, 58, 18)

    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.7, 0.7, 0.7, 0.7)
    text_("FPS: " .. fps, SCREEN_W - 90, 10, 14)

    -- Score popup
    if score_pop.alpha > 0.01 then
        lurek.render.setColor(1, 1, 0.2, score_pop.alpha)
        text_(score_pop.text, SCREEN_W / 2 - 20, score_pop.y, 20)
    end

    -- ── Level complete banner ─────────────────────────────────────────────
    if game_state == STATE.LEVEL_COMPLETE then
        lurek.render.setColor(0, 0, 0, 0.5)
        rect(0, SCREEN_H / 2 - 50, SCREEN_W, 100)
        lurek.render.setColor(1, 1, 1, banner.alpha)
        text_(banner.text, SCREEN_W / 2 - 100, SCREEN_H / 2 - 20, 28)
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.8, 0.8, banner.alpha)
            text_("PRESS ENTER", SCREEN_W / 2 - 70, SCREEN_H / 2 + 20, 18)
        end
    end

    -- ── Game over ─────────────────────────────────────────────────────────
    if game_state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        rect(0, 0, SCREEN_W, SCREEN_H)
        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        text_("GAME OVER", SCREEN_W / 2 - 90, SCREEN_H / 2 - 40, 32)
        lurek.render.setColor(1, 1, 1, 1)
        text_("FINAL SCORE: " .. score, SCREEN_W / 2 - 80, SCREEN_H / 2 + 10, 20)
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.8, 0.8, 1)
            text_("PRESS ENTER", SCREEN_W / 2 - 70, SCREEN_H / 2 + 50, 18)
        end
    end
end
