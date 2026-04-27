-- ============================================================================
-- Raycaster FPS — Lurek2D
-- ============================================================================
-- Category : retro
-- Source   : content/games/retro/raycaster_fps/main.lua
-- Run with : cargo run -- content/games/retro/raycaster_fps
-- ============================================================================
-- Wolfenstein 3D-style first-person raycaster with DDA, 6 wall types,
-- billboard items, enemies, minimap, weather overlays, and hitscan weapon.
-- Controls: WASD move/strafe, Q/E rotate, Space fire, F1-F3 weather, Esc quit

-- Action input bindings:
-- forward(w), back(s), strafe_left(a), strafe_right(d)
-- rotate_left(q), rotate_right(e), fire(space)
-- weather1(f1), weather2(f2), weather3(f3), quit(escape)

-- ── constants ─────────────────────────────────────────────────
local SCREEN_W, SCREEN_H = 960, 540
local LOG_W, LOG_H       = 320, 180
local SCALE_X             = SCREEN_W / LOG_W
local SCALE_Y             = SCREEN_H / LOG_H

local NUM_RAYS = 320
local FOV      = math.rad(72)
local HALF_FOV = FOV / 2

local MAP_W, MAP_H = 16, 16
local MOVE_SPEED   = 3.5
local ROT_SPEED    = 2.8
local STRAFE_SPEED = 2.8

local FIRE_COOLDOWN = 0.3
local WEAPON_DAMAGE = 34
local ENEMY_RANGE   = 10
local ENEMY_DAMAGE  = 8
local CONTACT_DAMAGE = 15

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }

-- Wall types: 1=stone, 2=brick, 3=blue_stone, 4=red_stone, 5=mossy, 6=gold
local WALL_COLORS = {
    { 0.50, 0.50, 0.50 },  -- stone
    { 0.60, 0.30, 0.15 },  -- brick
    { 0.25, 0.35, 0.60 },  -- blue stone
    { 0.65, 0.20, 0.18 },  -- red stone
    { 0.30, 0.50, 0.25 },  -- mossy
    { 0.75, 0.65, 0.20 },  -- gold
}

-- Item types
local ITEM_KEY_RED   = 1
local ITEM_KEY_BLUE  = 2
local ITEM_KEY_GREEN = 3
local ITEM_HEALTH    = 4
local ITEM_AMMO      = 5

local ITEM_COLORS = {
    [ITEM_KEY_RED]   = { 1.0, 0.2, 0.2 },
    [ITEM_KEY_BLUE]  = { 0.2, 0.4, 1.0 },
    [ITEM_KEY_GREEN] = { 0.2, 1.0, 0.3 },
    [ITEM_HEALTH]    = { 1.0, 1.0, 1.0 },
    [ITEM_AMMO]      = { 1.0, 0.8, 0.1 },
}

local ITEM_NAMES = {
    [ITEM_KEY_RED]   = "RED KEY",
    [ITEM_KEY_BLUE]  = "BLUE KEY",
    [ITEM_KEY_GREEN] = "GREEN KEY",
    [ITEM_HEALTH]    = "+25 HP",
    [ITEM_AMMO]      = "+10 AMMO",
}

-- Enemy types
local ENEMY_SOLDIER = 1
local ENEMY_OFFICER = 2

local ENEMY_HP    = { [ENEMY_SOLDIER] = 50, [ENEMY_OFFICER] = 80 }
local ENEMY_SPD   = { [ENEMY_SOLDIER] = 1.5, [ENEMY_OFFICER] = 2.2 }
local ENEMY_COLOR = {
    [ENEMY_SOLDIER] = { 0.55, 0.35, 0.15 },
    [ENEMY_OFFICER] = { 0.70, 0.15, 0.15 },
}
local ENEMY_FIRE_CD = { [ENEMY_SOLDIER] = 2.0, [ENEMY_OFFICER] = 1.2 }

-- ── map ───────────────────────────────────────────────────────
-- 0=floor, 1-6=wall types
local world_map = {
    { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 },
    { 1,0,0,0,2,0,0,0,0,0,0,3,0,0,0,1 },
    { 1,0,0,0,2,0,0,0,0,0,0,3,0,0,0,1 },
    { 1,0,0,0,0,0,4,4,0,0,0,0,0,0,0,1 },
    { 1,2,2,0,0,0,4,0,0,5,5,0,0,6,6,1 },
    { 1,0,0,0,0,0,0,0,0,0,5,0,0,0,0,1 },
    { 1,0,0,3,3,0,0,0,0,0,0,0,6,0,0,1 },
    { 1,0,0,3,0,0,0,1,1,0,0,0,6,0,0,1 },
    { 1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1 },
    { 1,0,5,0,0,0,0,0,0,0,4,4,0,0,0,1 },
    { 1,0,5,0,0,6,0,0,0,0,0,4,0,0,0,1 },
    { 1,0,0,0,0,6,0,0,0,0,0,0,0,2,2,1 },
    { 1,0,0,0,0,0,0,3,3,0,0,0,0,0,0,1 },
    { 1,0,4,4,0,0,0,0,3,0,0,5,0,0,0,1 },
    { 1,0,0,0,0,0,0,0,0,0,0,5,0,0,0,1 },
    { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 },
}

-- Items placed on the map
local items = {
    { x = 3.5,  y = 2.5,  kind = ITEM_KEY_RED,   alive = true },
    { x = 13.5, y = 2.5,  kind = ITEM_KEY_BLUE,  alive = true },
    { x = 8.5,  y = 13.5, kind = ITEM_KEY_GREEN, alive = true },
    { x = 5.5,  y = 5.5,  kind = ITEM_HEALTH,    alive = true },
    { x = 10.5, y = 9.5,  kind = ITEM_HEALTH,    alive = true },
    { x = 2.5,  y = 10.5, kind = ITEM_AMMO,      alive = true },
    { x = 14.5, y = 6.5,  kind = ITEM_AMMO,      alive = true },
    { x = 7.5,  y = 3.5,  kind = ITEM_AMMO,      alive = true },
}

-- Enemies
local enemies = {
    { x = 6.5,  y = 2.5,  kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
    { x = 13.5, y = 5.5,  kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
    { x = 4.5,  y = 9.5,  kind = ENEMY_OFFICER, hp = ENEMY_HP[ENEMY_OFFICER], fire_cd = 0, alert = false },
    { x = 10.5, y = 12.5, kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
    { x = 8.5,  y = 7.5,  kind = ENEMY_OFFICER, hp = ENEMY_HP[ENEMY_OFFICER], fire_cd = 0, alert = false },
}

-- ── state ─────────────────────────────────────────────────────
local current_state = STATE.TITLE
local player = { x = 2.5, y = 2.5, angle = 0, hp = 100, ammo = 30 }
local fire_timer = 0
local score = 0

local particles = {}
local weather = "clear"
local weather_particles = {}
local popups = {}

local damage_flash_alpha = 0
local muzzle_flash_timer = 0
local depth_buffer = {}

---@type LCamera
local cam = nil

-- ── helpers ───────────────────────────────────────────────────
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function dist2d(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function wrap_angle(a)
    while a >  math.pi do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end

local function map_solid(gx, gy)
    if gx < 1 or gx > MAP_W or gy < 1 or gy > MAP_H then return true end
    return world_map[gy][gx] > 0
end

local function can_see(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.01 then return true end
    local step = 0.15
    local sx, sy = dx / d, dy / d
    local t = 0
    while t < d do
        t = t + step
        local cx = x1 + sx * t
        local cy = y1 + sy * t
        local gx = math.floor(cx) + 1
        local gy = math.floor(cy) + 1
        if map_solid(gx, gy) then return false end
    end
    return true
end

local function try_move(px, py, dx, dy)
    local nx, ny = px + dx, py + dy
    local r = 0.2
    local gx1 = math.floor(nx - r) + 1
    local gx2 = math.floor(nx + r) + 1
    local gy1 = math.floor(ny - r) + 1
    local gy2 = math.floor(ny + r) + 1
    if not map_solid(gx1, gy1) and not map_solid(gx2, gy1) and
       not map_solid(gx1, gy2) and not map_solid(gx2, gy2) then
        return nx, ny
    end
    -- try sliding along axes
    local sx = px + dx
    local gx1s = math.floor(sx - r) + 1
    local gx2s = math.floor(sx + r) + 1
    local gy1s = math.floor(py - r) + 1
    local gy2s = math.floor(py + r) + 1
    if not map_solid(gx1s, gy1s) and not map_solid(gx2s, gy1s) and
       not map_solid(gx1s, gy2s) and not map_solid(gx2s, gy2s) then
        return sx, py
    end
    local sy = py + dy
    local gx1y = math.floor(px - r) + 1
    local gx2y = math.floor(px + r) + 1
    local gy1y = math.floor(sy - r) + 1
    local gy2y = math.floor(sy + r) + 1
    if not map_solid(gx1y, gy1y) and not map_solid(gx2y, gy1y) and
       not map_solid(gx1y, gy2y) and not map_solid(gx2y, gy2y) then
        return px, sy
    end
    return px, py
end

-- ── particle helpers ──────────────────────────────────────────
local function spawn_particles(px, py, r, g, b, count, speed_mult)
    speed_mult = speed_mult or 1
    for _ = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local spd = (30 + math.random() * 80) * speed_mult
        particles[#particles + 1] = {
            x = px, y = py,
            vx = math.cos(angle) * spd, vy = math.sin(angle) * spd,
            life = 0.15 + math.random() * 0.35, max_life = 0.5,
            r = r, g = g, b = b,
            size = 1 + math.random() * 3,
        }
    end
end

local function spawn_muzzle_flash()
    local fx = SCREEN_W / 2
    local fy = SCREEN_H - 80
    for _ = 1, 12 do
        local angle = math.random() * math.pi * 2
        local spd = 60 + math.random() * 120
        particles[#particles + 1] = {
            x = fx + (math.random() - 0.5) * 20,
            y = fy + (math.random() - 0.5) * 10,
            vx = math.cos(angle) * spd, vy = math.sin(angle) * spd - 40,
            life = 0.1 + math.random() * 0.15, max_life = 0.25,
            r = 1.0, g = 0.8, b = 0.2,
            size = 2 + math.random() * 3,
        }
    end
    muzzle_flash_timer = 0.06
end

local function spawn_impact_sparks(sx, sy)
    for _ = 1, 6 do
        local angle = math.random() * math.pi * 2
        local spd = 40 + math.random() * 60
        particles[#particles + 1] = {
            x = sx, y = sy,
            vx = math.cos(angle) * spd, vy = math.sin(angle) * spd,
            life = 0.1 + math.random() * 0.2, max_life = 0.3,
            r = 1.0, g = 0.6, b = 0.1,
            size = 1 + math.random() * 2,
        }
    end
end

local function spawn_item_glow(sx, sy, r, g, b)
    for _ = 1, 10 do
        local angle = math.random() * math.pi * 2
        local spd = 30 + math.random() * 60
        particles[#particles + 1] = {
            x = sx, y = sy,
            vx = math.cos(angle) * spd, vy = math.sin(angle) * spd - 30,
            life = 0.3 + math.random() * 0.3, max_life = 0.6,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        }
    end
end

local function add_popup(text, sx, sy)
    popups[#popups + 1] = { text = text, x = sx, y = sy, life = 1.5, max_life = 1.5 }
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            particles[i] = particles[#particles]
            particles[#particles] = nil
        else
            i = i + 1
        end
    end
end

local function update_popups(dt)
    local i = 1
    while i <= #popups do
        local p = popups[i]
        p.y = p.y - 30 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            popups[i] = popups[#popups]
            popups[#popups] = nil
        else
            i = i + 1
        end
    end
end

-- ── weather ───────────────────────────────────────────────────
local function spawn_weather(dt)
    if weather == "clear" then return end
    local rate = (weather == "rain") and 50 or 25
    for _ = 1, math.floor(rate * dt * 60) do
        weather_particles[#weather_particles + 1] = {
            x = math.random() * SCREEN_W, y = -5,
            vy = (weather == "rain") and (250 + math.random() * 150) or (25 + math.random() * 35),
            vx = (weather == "rain") and (math.random() * 30 - 15) or (math.random() * 20 - 10),
            life = 0, max_life = (weather == "rain") and 2.5 or 7.0,
            size = (weather == "rain") and 1 or (2 + math.random() * 2),
        }
    end
end

local function update_weather(dt)
    spawn_weather(dt)
    local i = 1
    while i <= #weather_particles do
        local p = weather_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life + dt
        if p.life > p.max_life or p.y > SCREEN_H + 10 then
            weather_particles[i] = weather_particles[#weather_particles]
            weather_particles[#weather_particles] = nil
        else
            i = i + 1
        end
    end
end

-- ── DDA raycasting ────────────────────────────────────────────
local function cast_ray(ox, oy, angle)
    local dx = math.cos(angle)
    local dy = math.sin(angle)

    local map_x = math.floor(ox)
    local map_y = math.floor(oy)

    local delta_dist_x = (dx == 0) and 1e30 or math.abs(1 / dx)
    local delta_dist_y = (dy == 0) and 1e30 or math.abs(1 / dy)

    local step_x, side_dist_x
    local step_y, side_dist_y

    if dx < 0 then
        step_x = -1
        side_dist_x = (ox - map_x) * delta_dist_x
    else
        step_x = 1
        side_dist_x = (map_x + 1 - ox) * delta_dist_x
    end

    if dy < 0 then
        step_y = -1
        side_dist_y = (oy - map_y) * delta_dist_y
    else
        step_y = 1
        side_dist_y = (map_y + 1 - oy) * delta_dist_y
    end

    local side = 0
    local dist = 0
    for _ = 1, 64 do
        if side_dist_x < side_dist_y then
            side_dist_x = side_dist_x + delta_dist_x
            map_x = map_x + step_x
            side = 0
            dist = side_dist_x - delta_dist_x
        else
            side_dist_y = side_dist_y + delta_dist_y
            map_y = map_y + step_y
            side = 1
            dist = side_dist_y - delta_dist_y
        end

        local gx = map_x + 1
        local gy = map_y + 1
        if gx < 1 or gx > MAP_W or gy < 1 or gy > MAP_H then
            return dist, 1, side
        end
        if world_map[gy][gx] > 0 then
            return dist, world_map[gy][gx], side
        end
    end
    return 16, 0, 0
end

-- ── wall color with procedural texture ────────────────────────
local function wall_color(wtype, dist, side, ray_idx, strip_y)
    local c = WALL_COLORS[wtype] or WALL_COLORS[1]
    local fog   = clamp(1.0 - dist / 16.0, 0.08, 1.0)
    local shade = (side == 1) and 0.7 or 1.0
    local r, g, b = c[1] * fog * shade, c[2] * fog * shade, c[3] * fog * shade

    -- Procedural patterns
    if wtype == 2 then
        -- Brick: mortar lines
        local mortar = ((math.floor(strip_y * 0.4) % 6) == 0 or
                        (math.floor(ray_idx * 0.3 + strip_y * 0.15) % 8) == 0)
        if mortar then
            r, g, b = r * 0.6, g * 0.6, b * 0.6
        end
    elseif wtype == 3 then
        -- Blue stone: subtle vertical lines
        local line = (ray_idx % 5 == 0) and 0.85 or 1.0
        r, g, b = r * line, g * line, b * line
    elseif wtype == 4 then
        -- Red stone: cross-hatch
        local hatch = ((ray_idx + math.floor(strip_y * 0.5)) % 4 == 0) and 0.8 or 1.0
        r, g, b = r * hatch, g * hatch, b * hatch
    elseif wtype == 5 then
        -- Mossy: random-looking spots
        local spot = math.sin(ray_idx * 1.7 + strip_y * 0.9) * 0.5 + 0.5
        if spot > 0.7 then
            g = g * 1.3
        end
    elseif wtype == 6 then
        -- Gold: horizontal stripes
        local stripe = (math.floor(strip_y * 0.3) % 3 == 0) and 1.2 or 0.9
        r, g, b = r * stripe, g * stripe, b * stripe
    end

    return clamp(r, 0, 1), clamp(g, 0, 1), clamp(b, 0, 1)
end

-- ── reset game ────────────────────────────────────────────────
local function reset_game()
    player.x = 2.5
    player.y = 2.5
    player.angle = 0
    player.hp = 100
    player.ammo = 30
    fire_timer = 0
    score = 0
    damage_flash_alpha = 0
    muzzle_flash_timer = 0
    particles = {}
    weather_particles = {}
    popups = {}
    weather = "clear"

    for _, it in ipairs(items) do it.alive = true end
    enemies = {
        { x = 6.5,  y = 2.5,  kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
        { x = 13.5, y = 5.5,  kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
        { x = 4.5,  y = 9.5,  kind = ENEMY_OFFICER, hp = ENEMY_HP[ENEMY_OFFICER], fire_cd = 0, alert = false },
        { x = 10.5, y = 12.5, kind = ENEMY_SOLDIER, hp = ENEMY_HP[ENEMY_SOLDIER], fire_cd = 0, alert = false },
        { x = 8.5,  y = 7.5,  kind = ENEMY_OFFICER, hp = ENEMY_HP[ENEMY_OFFICER], fire_cd = 0, alert = false },
    }
end

-- ── lurek.init ────────────────────────────────────────────────

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
    lurek.window.setTitle("Raycaster FPS — Lurek2D")
    lurek.render.setBackgroundColor(0, 0, 0)

    lurek.input.bind("forward",      { "w" })
    lurek.input.bind("back",         { "s" })
    lurek.input.bind("strafe_left",  { "a" })
    lurek.input.bind("strafe_right", { "d" })
    lurek.input.bind("rotate_left",  { "q" })
    lurek.input.bind("rotate_right", { "e" })
    lurek.input.bind("fire",         { "space" })
    lurek.input.bind("weather1",     { "f1" })
    lurek.input.bind("weather2",     { "f2" })
    lurek.input.bind("weather3",     { "f3" })
    lurek.input.bind("quit",         { "escape" })
    lurek.input.bind("start",        { "return" })

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)
    reset_game()
end

local function _ready_setup() end

-- ── lurek.process ─────────────────────────────────────────────
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- TITLE
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") then
            current_state = STATE.PLAYING
            reset_game()
        end
        return
    end

    -- GAME OVER
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("start") then
            current_state = STATE.PLAYING
            reset_game()
        end
        update_particles(dt)
        update_popups(dt)
        return
    end

    -- === PLAYING ===
    -- Weather toggle
    if lurek.input.wasActionPressed("weather1") then weather = "clear" end
    if lurek.input.wasActionPressed("weather2") then weather = "rain"  end
    if lurek.input.wasActionPressed("weather3") then weather = "snow"  end

    -- Rotation
    if lurek.input.isActionDown("rotate_left")  then player.angle = player.angle - ROT_SPEED * dt end
    if lurek.input.isActionDown("rotate_right") then player.angle = player.angle + ROT_SPEED * dt end
    player.angle = wrap_angle(player.angle)

    -- Movement
    local dx, dy = 0, 0
    local cos_a = math.cos(player.angle)
    local sin_a = math.sin(player.angle)
    if lurek.input.isActionDown("forward") then
        dx = dx + cos_a * MOVE_SPEED * dt
        dy = dy + sin_a * MOVE_SPEED * dt
    end
    if lurek.input.isActionDown("back") then
        dx = dx - cos_a * MOVE_SPEED * dt
        dy = dy - sin_a * MOVE_SPEED * dt
    end
    if lurek.input.isActionDown("strafe_left") then
        dx = dx + sin_a * STRAFE_SPEED * dt
        dy = dy - cos_a * STRAFE_SPEED * dt
    end
    if lurek.input.isActionDown("strafe_right") then
        dx = dx - sin_a * STRAFE_SPEED * dt
        dy = dy + cos_a * STRAFE_SPEED * dt
    end
    player.x, player.y = try_move(player.x, player.y, dx, dy)

    -- Firing
    fire_timer = math.max(0, fire_timer - dt)
    if lurek.input.isActionDown("fire") and fire_timer <= 0 and player.ammo > 0 then
        fire_timer = FIRE_COOLDOWN
        player.ammo = player.ammo - 1
        spawn_muzzle_flash()

        -- Hitscan: find closest enemy in crosshair
        local best_dist = 999
        local best_enemy = nil
        for _, e in ipairs(enemies) do
            local edx = e.x - player.x
            local edy = e.y - player.y
            local ed = math.sqrt(edx * edx + edy * edy)
            local ea = math.atan2(edy, edx)
            local diff = math.abs(wrap_angle(ea - player.angle))
            if diff < 0.15 and ed < ENEMY_RANGE and ed < best_dist then
                if can_see(player.x, player.y, e.x, e.y) then
                    best_dist = ed
                    best_enemy = e
                end
            end
        end
        if best_enemy then
            best_enemy.hp = best_enemy.hp - WEAPON_DAMAGE
            best_enemy.alert = true
            -- impact sparks in screen space
            local rel = wrap_angle(math.atan2(best_enemy.y - player.y, best_enemy.x - player.x) - player.angle)
            local sx = SCREEN_W / 2 + (rel / HALF_FOV) * (SCREEN_W / 2)
            local corr = best_dist * math.cos(rel)
            local sy = SCREEN_H / 2
            spawn_impact_sparks(sx, sy)
        end
    end

    -- Remove dead enemies
    local ei = 1
    while ei <= #enemies do
        local e = enemies[ei]
        if e.hp <= 0 then
            score = score + ((e.kind == ENEMY_OFFICER) and 200 or 100)
            spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 1, 0.3, 0.1, 10, 1.5)
            add_popup("+" .. ((e.kind == ENEMY_OFFICER) and "200" or "100"), SCREEN_W / 2, SCREEN_H / 2 - 40)
            table.remove(enemies, ei)
        else
            ei = ei + 1
        end
    end

    -- Enemy AI
    for _, e in ipairs(enemies) do
        local edist = dist2d(player.x, player.y, e.x, e.y)

        -- Alert if in LOS and range
        if edist < ENEMY_RANGE and can_see(e.x, e.y, player.x, player.y) then
            e.alert = true
        end

        if e.alert then
            -- Chase toward player
            local edx = player.x - e.x
            local edy = player.y - e.y
            if edist > 1.5 then
                local spd = ENEMY_SPD[e.kind] * dt
                local norm = edist
                local mx = edx / norm * spd
                local my = edy / norm * spd
                e.x, e.y = try_move(e.x, e.y, mx, my)
            end

            -- Contact damage
            if edist < 0.6 then
                player.hp = player.hp - CONTACT_DAMAGE * dt
                damage_flash_alpha = clamp(damage_flash_alpha + 2.0 * dt, 0, 0.6)
            end

            -- Shoot at player
            e.fire_cd = e.fire_cd - dt
            if e.fire_cd <= 0 and edist < ENEMY_RANGE and can_see(e.x, e.y, player.x, player.y) then
                e.fire_cd = ENEMY_FIRE_CD[e.kind]
                player.hp = player.hp - ENEMY_DAMAGE
                damage_flash_alpha = clamp(damage_flash_alpha + 0.3, 0, 0.6)
            end
        end
    end

    -- Item collection
    for _, it in ipairs(items) do
        if it.alive and dist2d(player.x, player.y, it.x, it.y) < 0.5 then
            it.alive = false
            local ic = ITEM_COLORS[it.kind]

            -- Screen-space position for particles
            local rel = wrap_angle(math.atan2(it.y - player.y, it.x - player.x) - player.angle)
            local sx = SCREEN_W / 2 + (rel / HALF_FOV) * (SCREEN_W / 2)
            spawn_item_glow(sx, SCREEN_H / 2, ic[1], ic[2], ic[3])
            add_popup(ITEM_NAMES[it.kind], sx, SCREEN_H / 2 - 30)

            if it.kind == ITEM_HEALTH then
                player.hp = math.min(100, player.hp + 25)
            elseif it.kind == ITEM_AMMO then
                player.ammo = player.ammo + 10
            end
            score = score + 50
        end
    end

    -- Damage flash decay
    damage_flash_alpha = math.max(0, damage_flash_alpha - 1.5 * dt)
    muzzle_flash_timer = math.max(0, muzzle_flash_timer - dt)

    -- Death check
    if player.hp <= 0 then
        player.hp = 0
        current_state = STATE.GAME_OVER
    end

    update_particles(dt)
    update_popups(dt)
    update_weather(dt)
    cam:update(dt)
end

-- ── lurek.render — 3D viewport ────────────────────────────────
function lurek.draw()
    if current_state == STATE.TITLE then return end
    cam:apply()

    -- Ceiling gradient (16 bands)
    local bands  = 16
    local band_h = (SCREEN_H / 2) / bands
    for i = 0, bands - 1 do
        local t = 1.0 - i / bands
        local br = 0.05 + 0.08 * t
        lurek.render.setColor(br * 0.4, br * 0.5, br * 1.0, 1)
        rect("fill", 0, i * band_h, SCREEN_W, band_h + 1)
    end

    -- Floor gradient (16 bands)
    for i = 0, bands - 1 do
        local t = i / bands
        local br = 0.04 + 0.07 * t
        lurek.render.setColor(br * 0.7, br * 0.45, br * 0.2, 1)
        rect("fill", 0, SCREEN_H / 2 + i * band_h, SCREEN_W, band_h + 1)
    end

    -- Raycast walls and build depth buffer
    for r = 0, NUM_RAYS - 1 do
        local ray_a = player.angle - HALF_FOV + (r / NUM_RAYS) * FOV
        local dist, wtype, side = cast_ray(player.x - 1, player.y - 1, ray_a)

        -- Fish-eye correction
        local corr = dist * math.cos(ray_a - player.angle)
        if corr < 0.05 then corr = 0.05 end
        depth_buffer[r] = corr

        local strip_h = SCREEN_H / corr
        if strip_h > SCREEN_H * 4 then strip_h = SCREEN_H * 4 end

        local sx = r * SCALE_X
        local sy = (SCREEN_H - strip_h) / 2

        if wtype > 0 then
            local cr, cg, cb = wall_color(wtype, corr, side, r, sy)
            lurek.render.setColor(cr, cg, cb, 1)
            rect("fill", sx, sy, SCALE_X + 0.5, strip_h)
        end
    end

    -- Billboard items (depth-tested)
    for _, it in ipairs(items) do
        if it.alive then
            local idx = it.x - player.x
            local idy = it.y - player.y
            local idist = math.sqrt(idx * idx + idy * idy)
            if idist < 14 and idist > 0.3 then
                local ia = math.atan2(idy, idx)
                local rel = wrap_angle(ia - player.angle)
                if math.abs(rel) < HALF_FOV then
                    local icorr = idist * math.cos(rel)
                    local scr_x = SCREEN_W / 2 + (rel / HALF_FOV) * (SCREEN_W / 2)
                    local ih = SCREEN_H / icorr * 0.4
                    local iw = ih * 0.6
                    local iy = (SCREEN_H - ih) / 2 + ih * 0.2

                    -- Depth test against wall strips
                    local ray_idx = math.floor((scr_x / SCREEN_W) * NUM_RAYS)
                    ray_idx = clamp(ray_idx, 0, NUM_RAYS - 1)
                    if icorr < (depth_buffer[ray_idx] or 999) then
                        local ic = ITEM_COLORS[it.kind]
                        local fog = clamp(1.0 - idist / 16.0, 0.15, 1.0)
                        lurek.render.setColor(ic[1] * fog, ic[2] * fog, ic[3] * fog, 1)
                        rect("fill", scr_x - iw / 2, iy, iw, ih)

                        -- Icon detail
                        if it.kind <= ITEM_KEY_GREEN then
                            lurek.render.setColor(1, 1, 1, fog * 0.5)
                            rect("fill", scr_x - iw * 0.15, iy + ih * 0.3, iw * 0.3, ih * 0.15)
                        else
                            lurek.render.setColor(1, 1, 1, fog * 0.4)
                            rect("fill", scr_x - iw * 0.1, iy + ih * 0.2, iw * 0.2, ih * 0.6)
                        end
                    end
                end
            end
        end
    end

    -- Billboard enemies (depth-tested)
    for _, e in ipairs(enemies) do
        local edx = e.x - player.x
        local edy = e.y - player.y
        local edist = math.sqrt(edx * edx + edy * edy)
        if edist < 14 and edist > 0.3 then
            local ea = math.atan2(edy, edx)
            local rel = wrap_angle(ea - player.angle)
            if math.abs(rel) < HALF_FOV then
                local ecorr = edist * math.cos(rel)
                local scr_x = SCREEN_W / 2 + (rel / HALF_FOV) * (SCREEN_W / 2)
                local eh = SCREEN_H / ecorr * 0.7
                local ew = eh * 0.45
                local ey = (SCREEN_H - eh) / 2

                local ray_idx = math.floor((scr_x / SCREEN_W) * NUM_RAYS)
                ray_idx = clamp(ray_idx, 0, NUM_RAYS - 1)
                if ecorr < (depth_buffer[ray_idx] or 999) then
                    local ec = ENEMY_COLOR[e.kind]
                    local fog = clamp(1.0 - edist / 16.0, 0.15, 1.0)

                    -- Body
                    lurek.render.setColor(ec[1] * fog, ec[2] * fog, ec[3] * fog, 1)
                    rect("fill", scr_x - ew / 2, ey + eh * 0.1, ew, eh * 0.7)

                    -- Head
                    lurek.render.setColor(0.9 * fog, 0.75 * fog, 0.6 * fog, 1)
                    circ("fill", scr_x, ey + eh * 0.08, ew * 0.3)

                    -- Weapon
                    lurek.render.setColor(0.3 * fog, 0.3 * fog, 0.3 * fog, 1)
                    rect("fill", scr_x + ew * 0.2, ey + eh * 0.35, ew * 0.4, eh * 0.08)
                end
            end
        end
    end

    -- Muzzle flash overlay
    if muzzle_flash_timer > 0 then
        local a = muzzle_flash_timer / 0.06
        lurek.render.setColor(1, 0.9, 0.3, a * 0.4)
        circ("fill", SCREEN_W / 2, SCREEN_H - 70, 30 + 20 * a)
    end

    -- Damage flash overlay
    if damage_flash_alpha > 0 then
        lurek.render.setColor(1, 0, 0, damage_flash_alpha)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    cam:reset()
end

-- ── lurek.render_ui — HUD, minimap, weather, popups ───────────
function lurek.draw_ui()
    -- === TITLE SCREEN ===
    if current_state == STATE.TITLE then
        lurek.render.setColor(0.8, 0.15, 0.1, 1)
        text_("RAYCASTER FPS", 300, 160, 40)
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        text_("Wolfenstein 3D-style raycaster with 6 wall types", 225, 230, 16)
        text_("WASD = Move/Strafe   Q/E = Rotate   Space = Fire", 220, 260, 14)
        text_("F1-F3 = Weather   Esc = Quit", 320, 285, 14)
        local blink = math.sin(lurek.timer.getTime() * 4) > 0
        if blink then
            lurek.render.setColor(1, 1, 1, 1)
            text_("PRESS ENTER", 395, 360, 22)
        end
        lurek.render.setColor(0.3, 0.3, 0.4, 1)
        text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12)
        return
    end

    -- === GAME OVER ===
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(0.8, 0.1, 0.1, 1)
        text_("GAME OVER", 350, 200, 36)
        lurek.render.setColor(0.9, 0.9, 1, 1)
        text_("Score: " .. score, 420, 260, 20)
        local blink = math.sin(lurek.timer.getTime() * 4) > 0
        if blink then
            lurek.render.setColor(1, 1, 1, 1)
            text_("PRESS ENTER TO RESTART", 340, 330, 18)
        end
        lurek.render.setColor(0.3, 0.3, 0.4, 1)
        text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12)
        return
    end

    -- === HUD ===
    -- HP bar
    lurek.render.setColor(0.15, 0.15, 0.2, 0.8)
    rect("fill", 10, SCREEN_H - 40, 204, 24)
    local hp_frac = clamp(player.hp / 100, 0, 1)
    local hp_r = 1.0 - hp_frac
    local hp_g = hp_frac
    lurek.render.setColor(hp_r, hp_g, 0.1, 1)
    rect("fill", 12, SCREEN_H - 38, 200 * hp_frac, 20)
    lurek.render.setColor(1, 1, 1, 1)
    text_("HP: " .. math.floor(player.hp), 15, SCREEN_H - 38, 14)

    -- Ammo
    lurek.render.setColor(1, 0.8, 0.1, 1)
    text_("AMMO: " .. player.ammo, 230, SCREEN_H - 38, 14)

    -- Score
    lurek.render.setColor(1, 1, 1, 1)
    text_("SCORE: " .. score, 380, SCREEN_H - 38, 14)

    -- Weapon graphic (simple crosshair + gun shape)
    lurek.render.setColor(0.3, 0.3, 0.35, 1)
    rect("fill", SCREEN_W / 2 - 8, SCREEN_H - 60, 16, 40)
    rect("fill", SCREEN_W / 2 - 16, SCREEN_H - 30, 32, 12)
    lurek.render.setColor(0.2, 0.2, 0.2, 1)
    rect("fill", SCREEN_W / 2 - 3, SCREEN_H - 65, 6, 10)

    -- Crosshair
    lurek.render.setColor(1, 1, 1, 0.7)
    ln(SCREEN_W / 2 - 10, SCREEN_H / 2, SCREEN_W / 2 - 3, SCREEN_H / 2)
    ln(SCREEN_W / 2 + 3, SCREEN_H / 2, SCREEN_W / 2 + 10, SCREEN_H / 2)
    ln(SCREEN_W / 2, SCREEN_H / 2 - 10, SCREEN_W / 2, SCREEN_H / 2 - 3)
    ln(SCREEN_W / 2, SCREEN_H / 2 + 3, SCREEN_W / 2, SCREEN_H / 2 + 10)

    -- Weather indicator
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    text_("Weather: " .. weather .. "  (F1/F2/F3)", 10, 10, 12)

    -- === MINIMAP (top-right) ===
    local MM_SIZE = 130
    local MM_X = SCREEN_W - MM_SIZE - 15
    local MM_Y = 15
    local MM_CELL = MM_SIZE / MAP_W

    -- Background
    lurek.render.setColor(0.0, 0.0, 0.0, 0.7)
    rect("fill", MM_X - 2, MM_Y - 2, MM_SIZE + 4, MM_SIZE + 4)

    -- Walls
    for gy = 1, MAP_H do
        for gx = 1, MAP_W do
            local cx = MM_X + (gx - 1) * MM_CELL
            local cy = MM_Y + (gy - 1) * MM_CELL
            if world_map[gy][gx] > 0 then
                local wc = WALL_COLORS[world_map[gy][gx]]
                lurek.render.setColor(wc[1] * 0.5, wc[2] * 0.5, wc[3] * 0.5, 1)
                rect("fill", cx, cy, MM_CELL, MM_CELL)
            else
                lurek.render.setColor(0.1, 0.1, 0.12, 1)
                rect("fill", cx, cy, MM_CELL, MM_CELL)
            end
        end
    end

    -- Items on minimap
    for _, it in ipairs(items) do
        if it.alive then
            local ic = ITEM_COLORS[it.kind]
            lurek.render.setColor(ic[1], ic[2], ic[3], 0.8)
            local ix = MM_X + (it.x - 1) * MM_CELL
            local iy = MM_Y + (it.y - 1) * MM_CELL
            circ("fill", ix, iy, 2)
        end
    end

    -- Enemies on minimap
    for _, e in ipairs(enemies) do
        local ec = ENEMY_COLOR[e.kind]
        lurek.render.setColor(ec[1], ec[2], ec[3], 0.9)
        local ex = MM_X + (e.x - 1) * MM_CELL
        local ey = MM_Y + (e.y - 1) * MM_CELL
        circ("fill", ex, ey, 2.5)
    end

    -- Player on minimap
    local pmx = MM_X + (player.x - 1) * MM_CELL
    local pmy = MM_Y + (player.y - 1) * MM_CELL
    lurek.render.setColor(0.2, 1, 0.3, 1)
    circ("fill", pmx, pmy, 3)
    local dir_len = 8
    ln(pmx, pmy,
        pmx + math.cos(player.angle) * dir_len,
        pmy + math.sin(player.angle) * dir_len)

    -- Minimap border
    lurek.render.setColor(0.4, 0.4, 0.5, 1)
    rect("line", MM_X - 2, MM_Y - 2, MM_SIZE + 4, MM_SIZE + 4)

    -- === PARTICLES (screen-space) ===
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a)
        rect("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    -- === WEATHER OVERLAY ===
    for _, wp in ipairs(weather_particles) do
        local a = 1.0 - wp.life / wp.max_life
        if weather == "rain" then
            lurek.render.setColor(0.5, 0.6, 0.9, a * 0.6)
            rect("fill", wp.x, wp.y, 1, 4)
        else
            lurek.render.setColor(1, 1, 1, a * 0.7)
            circ("fill", wp.x, wp.y, wp.size)
        end
    end

    -- === POPUPS ===
    for _, pu in ipairs(popups) do
        local a = clamp(pu.life / pu.max_life, 0, 1)
        lurek.render.setColor(1, 1, 0.3, a)
        text_(pu.text, pu.x - 20, pu.y, 14)
    end

    -- FPS
    lurek.render.setColor(0.3, 0.3, 0.4, 1)
    text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12)
end
