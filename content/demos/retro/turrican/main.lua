-- Turrican — C-64/Amiga Classic (Lurek2D demo)
-- A run-and-gun platformer inspired by Manfred Trenz's legendary 1990 game.
-- Blast enemies, power up, and clear each world.
-- Run with: cargo run -- content/demos/retro/turrican

-- ── Constants ────────────────────────────────────────────────────────────

local W, H       = 800, 600
local TILE        = 32
local GRAVITY     = 800
local JUMP_VEL    = -440
local PLAYER_SPD  = 180
local BULLET_SPD  = 360
local BEAM_DIST   = 220   -- Energy beam range
local MAX_HEALTH  = 5

-- ── Tilemap ───────────────────────────────────────────────────────────────
-- '1' = block, '.' = air, 'E' = enemy, 'P' = powerup, 'X' = exit

local MAP = {
    "11111111111111111111111111",
    "1........................1",
    "1...P.............E......1",
    "1..111111.....111111.....1",
    "1..............E.........1",
    "1....11111.....E.....111.1",
    "1.E............E.........1",
    "1.1111.....P.......1111..1",
    "1........E...E...........1",
    "1...11111...1111....P....1",
    "1.....E..........E.......1",
    "1...1111.....1111.........1",
    "1.E.............E......E.1",
    "1.......1111..........X..1",
    "11111111111111111111111111",
}

local MAP_W = #MAP[1]
local MAP_H = #MAP

-- ── State ─────────────────────────────────────────────────────────────────

local player = {}
local enemies = {}
local bullets = {}
local powerups = {}
local exit_tile = {}
local camera_x = 0
local score, health, level = 0, MAX_HEALTH, 1
local game_state = "playing"
local beam_timer = 0
local anim = 0

-- ── Tile Helpers ──────────────────────────────────────────────────────────

local function tile_at(tx, ty)
    if ty < 1 or ty > MAP_H then return "1" end
    if tx < 1 or tx > MAP_W then return "1" end
    return MAP[ty]:sub(tx, tx)
end

local function solid(tx, ty) return tile_at(tx, ty) == "1" end

local function world_tile(wx, wy)
    return math.floor(wx / TILE) + 1, math.floor(wy / TILE) + 1
end

local function resolve(e)
    -- Bottom
    local bx1 = world_tile(e.x + 2, e.y + e.h + 1)
    local bx2, by2 = world_tile(e.x + e.w - 2, e.y + e.h + 1)
    if e.vy >= 0 and (solid(bx1, by2) or solid(bx2, by2)) then
        e.y = (by2 - 1) * TILE - e.h
        e.vy = 0; e.on_ground = true
    else
        e.on_ground = false
    end
    -- Top
    local tx1, ty1 = world_tile(e.x + 2, e.y - 1)
    local tx2, ty11 = world_tile(e.x + e.w - 2, e.y - 1)
    if e.vy < 0 and (solid(tx1, ty1) or solid(tx2, ty11)) then
        e.y = ty1 * TILE; e.vy = 0
    end
    -- Left
    local lx, ly = world_tile(e.x - 1, e.y + 4)
    if solid(lx, ly) then e.x = lx * TILE; if e.vx then e.vx = 0 end end
    -- Right
    local rx, ry = world_tile(e.x + e.w + 1, e.y + 4)
    if solid(rx, ry) then e.x = (rx - 1) * TILE - e.w; if e.vx then e.vx = 0 end end
end

local function overlap(ax,ay,aw,ah, bx,by,bw,bh)
    return ax < bx+bw and ax+aw > bx and ay < by+bh and ay+ah > by
end

-- ── Init ─────────────────────────────────────────────────────────────────

local function init_level()
    enemies = {}; bullets = {}; powerups = {}
    for row = 1, MAP_H do
        for col = 1, MAP_W do
            local ch = tile_at(col, row)
            local wx, wy = (col - 1) * TILE, (row - 1) * TILE
            if ch == "E" then
                enemies[#enemies+1] = { x = wx, y = wy, w = 26, h = 28, vx = 40, vy = 0,
                    on_ground = false, hp = 2, shoot_cd = 2 + math.random(), alive = true }
            elseif ch == "P" then
                powerups[#powerups+1] = { x = wx + 4, y = wy + 4, w = 24, h = 24, alive = true }
            elseif ch == "X" then
                exit_tile = { x = wx, y = wy, w = TILE, h = TILE }
            end
        end
    end
    player = { x = TILE, y = TILE * 2, w = 24, h = 32, vx = 0, vy = 0,
               on_ground = false, facing = 1, shoot_cd = 0, beam_active = false }
    camera_x = 0
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.06, 0.04, 0.14)
    score = 0; health = MAX_HEALTH; level = 1
    init_level()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt
    beam_timer = math.max(0, beam_timer - dt)
    player.shoot_cd = math.max(0, player.shoot_cd - dt)

    -- Input
    local move = 0
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a")  then move = -1 end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then move =  1 end
    if move ~= 0 then player.facing = move end
    player.vx = move * PLAYER_SPD

    -- Beam weapon
    player.beam_active = lurek.input.isKeyDown("z")

    -- Gravity
    if not player.on_ground then player.vy = player.vy + GRAVITY * dt end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    resolve(player)

    -- Camera
    local cam_t = player.x - W / 3
    camera_x = camera_x + (cam_t - camera_x) * 0.1
    camera_x = math.max(0, math.min(MAP_W * TILE - W, camera_x))

    -- Bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.life = b.life - dt
        if b.life <= 0 or solid(world_tile(b.x, b.y)) then table.remove(bullets, i) end
    end

    -- Enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if not e.alive then goto next_e end
        if not e.on_ground then e.vy = e.vy + GRAVITY * dt end
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        resolve(e)
        -- Reverse at walls
        if solid(world_tile(e.x + e.w + 2, e.y + e.h - 4)) then e.vx = -math.abs(e.vx) end
        if solid(world_tile(e.x - 2, e.y + e.h - 4)) then e.vx = math.abs(e.vx) end

        e.shoot_cd = e.shoot_cd - dt
        if e.shoot_cd <= 0 then
            e.shoot_cd = 2 + math.random()
            local dx = player.x - e.x
            bullets[#bullets+1] = {
                x = e.x + e.w/2, y = e.y + 10,
                vx = (dx > 0 and 1 or -1) * BULLET_SPD * 0.6,
                life = 1.8, enemy = true
            }
        end

        -- Beam hit
        if player.beam_active then
            local bx = player.x + (player.facing > 0 and player.w or -BEAM_DIST)
            if player.facing < 0 then bx = player.x - BEAM_DIST end
            local bw = BEAM_DIST
            local bpy = player.y + 10
            if overlap(bx, bpy, bw, 12, e.x, e.y, e.w, e.h) then
                e.hp = e.hp - 2 * dt
                if e.hp <= 0 then e.alive = false; score = score + 300 end
            end
        end
        ::next_e::
    end

    -- Player bullets vs enemies
    for bi = #bullets, 1, -1 do
        if not bullets[bi] or bullets[bi].enemy then goto cont_b end
        for _, e in ipairs(enemies) do
            if e.alive and overlap(bullets[bi].x - 3, bullets[bi].y - 3, 6, 6, e.x, e.y, e.w, e.h) then
                e.hp = e.hp - 1
                if e.hp <= 0 then e.alive = false; score = score + 200 end
                table.remove(bullets, bi)
                break
            end
        end
        ::cont_b::
    end

    -- Enemy bullets vs player
    for i = #bullets, 1, -1 do
        if not bullets[i] then break end
        local b = bullets[i]
        if b.enemy and overlap(b.x - 3, b.y - 3, 6, 6, player.x, player.y, player.w, player.h) then
            health = health - 1
            table.remove(bullets, i)
            if health <= 0 then game_state = "gameover" end
        end
    end

    -- Powerups
    for _, p in ipairs(powerups) do
        if p.alive and overlap(player.x, player.y, player.w, player.h, p.x, p.y, p.w, p.h) then
            p.alive = false; health = math.min(MAX_HEALTH, health + 2); score = score + 100
        end
    end

    -- Exit
    if exit_tile.x and overlap(player.x, player.y, player.w, player.h, exit_tile.x, exit_tile.y, exit_tile.w, exit_tile.h) then
        score = score + level * 2000; level = level + 1; init_level()
    end

    -- Fall off
    if player.y > MAP_H * TILE then
        health = health - 1
        if health <= 0 then game_state = "gameover" else init_level() end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    local cam = math.floor(camera_x)
    local fc = math.floor(cam / TILE)
    local lc = fc + math.ceil(W / TILE) + 2

    -- Tiles
    for row = 1, MAP_H do
        for col = fc, lc do
            if tile_at(col, row) == "1" then
                local sx, sy = (col - 1) * TILE - cam, (row - 1) * TILE
                lurek.render.setColor(0.22, 0.14, 0.38)
                lurek.render.rectangle("fill", sx, sy, TILE, TILE)
                lurek.render.setColor(0.4, 0.25, 0.6)
                lurek.render.rectangle("line", sx, sy, TILE, TILE)
            end
        end
    end

    -- Exit
    if exit_tile.x then
        local sx = exit_tile.x - cam
        lurek.render.setColor(0, 0.8, 1)
        lurek.render.rectangle("fill", sx, exit_tile.y, exit_tile.w, exit_tile.h)
        lurek.render.setColor(0, 0, 0)
        lurek.render.print("EXIT", sx + 3, exit_tile.y + 8, 1.2)
    end

    -- Powerups (pulsing)
    local pulse = 0.6 + 0.4 * math.sin(anim * 5)
    for _, p in ipairs(powerups) do
        if p.alive then
            lurek.render.setColor(0.9 * pulse, 0.5, 1)
            lurek.render.circle("fill", p.x - cam + p.w/2, p.y + p.h/2, 10)
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("+", p.x - cam + 6, p.y + 4, 1.4)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local sx = e.x - cam
            lurek.render.setColor(0.7, 0.2, 0.4)
            lurek.render.rectangle("fill", sx + 3, e.y + 6, e.w - 6, e.h - 6)
            lurek.render.setColor(0.9, 0.5, 0.2)
            lurek.render.circle("fill", sx + e.w/2, e.y + 7, 8)
            -- HP bar
            lurek.render.setColor(0.2, 0, 0)
            lurek.render.rectangle("fill", sx, e.y - 7, e.w, 5)
            lurek.render.setColor(0.8, 0.1, 0.1)
            lurek.render.rectangle("fill", sx, e.y - 7, e.w * (e.hp / 2), 5)
        end
    end

    -- Bullets
    lurek.render.setColor(1, 0.9, 0.1)
    for _, b in ipairs(bullets) do
        if not b.enemy then lurek.render.rectangle("fill", b.x - cam - 2, b.y, 5, 8) end
    end
    lurek.render.setColor(1, 0.3, 0.1)
    for _, b in ipairs(bullets) do
        if b.enemy then lurek.render.rectangle("fill", b.x - cam - 2, b.y, 5, 5) end
    end

    -- Beam weapon
    if player.beam_active then
        local bx = player.x - cam + (player.facing > 0 and player.w or -BEAM_DIST)
        lurek.render.setColor(0.1, 0.8, 1, 0.7)
        lurek.render.rectangle("fill", bx, player.y + 10, BEAM_DIST, 12)
    end

    -- Player
    local px = player.x - cam
    lurek.render.setColor(0.1, 0.5, 0.9)
    lurek.render.rectangle("fill", px + 3, player.y + 10, player.w - 6, player.h - 10)
    lurek.render.setColor(0.85, 0.75, 0.6)
    lurek.render.circle("fill", px + player.w/2, player.y + 10, 11)
    -- Helmet
    lurek.render.setColor(0.15, 0.15, 0.5)
    lurek.render.rectangle("fill", px + 2, player.y, player.w - 4, 12)

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, W, 30)
    lurek.render.setColor(0.5, 0.3, 1)
    lurek.render.print("TURRICAN", 8, 4, 1.8)
    lurek.render.setColor(1, 1, 1)
    lurek.render.print("Score: " .. score, W/2 - 50, 4, 1.6)
    -- Health bar
    for i = 1, MAX_HEALTH do
        local hx = W - 22 * i - 8
        lurek.render.setColor(i <= health and 0.9 or 0.25, 0.2, 0.4)
        lurek.render.rectangle("fill", hx, 5, 18, 20)
    end
    lurek.render.setColor(0.4, 0.8, 1)
    lurek.render.print("Lv " .. level, W/2 + 70, 4, 1.6)

    -- Controls hint
    lurek.render.setColor(0.5, 0.5, 0.7, 0.7)
    lurek.render.print("[A/D] Move  [W/Up/Space] Jump  [X] Shoot  [Z] Beam", 10, H - 22, 1.3)

    -- Overlay
    if game_state == "gameover" then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(0.6, 0.2, 1)
        lurek.render.print("TURRICAN FALLS", W/2 - 115, H/2 - 25, 3)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "up" or key == "w") and player.on_ground then
        player.vy = JUMP_VEL; player.on_ground = false
    end
    if key == "x" and player.shoot_cd <= 0 then
        bullets[#bullets+1] = {
            x = player.x + (player.facing > 0 and player.w or 0),
            y = player.y + 12,
            vx = player.facing * BULLET_SPD,
            life = 1.0, enemy = false
        }
        player.shoot_cd = 0.2
    end
end
