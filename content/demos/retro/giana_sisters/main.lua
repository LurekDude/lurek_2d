-- The Great Giana Sisters — C-64 Classic (Lurek2D demo)
-- Side-scrolling platformer inspired by the infamous 1987 C-64 game.
-- Collect gems and reach the exit on each level. Jump on enemies to defeat them.
-- Run with: cargo run -- content/demos/retro/giana_sisters

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local TILE = 32
local GRAVITY = 900
local JUMP_VEL = -500
local PLAYER_SPEED = 180
local SCROLL_SPEED = 0.15

-- ── Level map ─────────────────────────────────────────────────────────────
-- '1' = solid block, '.' = empty, 'G' = gem, 'E' = exit, 'M' = monster

local LEVEL_MAP = {
    "1111111111111111111111111111111111111111",
    "1......................................1",
    "1...G.G.G..............................1",
    "1.111111111...G.G.....G.G..G...........1",
    "1..............1111111................E1",
    "1.....G.......................G.G......11",
    "1.1111111....M.....11111.....1111.....11",
    "1............1.1............1....11...11",
    "1.G.G.G......1...G....M.....1.......G.11",
    "1.11111...1111...1111..1111.1..1111..11",
    "1.......M.........G........G.1.......11",
    "1.111111..111111..111111...1111111...11",
    "1............G.G.G..........G.G......11",
    "11111111111111111111111111111111111111111",
}

-- ── State ─────────────────────────────────────────────────────────────────

local map_rows = #LEVEL_MAP
local map_cols = #LEVEL_MAP[1]

local player = {}
local enemies = {}
local gems = {}
local exit_tile = {}
local camera_x = 0
local score, lives, level = 0, 3, 1
local game_state = "playing"

-- ── Helpers ──────────────────────────────────────────────────────────────

local function tile_at(tx, ty)
    if ty < 1 or ty > map_rows then return "1" end
    if tx < 1 or tx > map_cols then return "1" end
    return LEVEL_MAP[ty]:sub(tx, tx)
end

local function solid(tx, ty)
    local t = tile_at(tx, ty)
    return t == "1"
end

local function world_to_tile(wx, wy) return math.floor(wx / TILE) + 1, math.floor(wy / TILE) + 1 end

local function collide_rect(e)
    -- Resolve entity vertically and horizontally against tiles
    local ex, ey, ew, eh = e.x, e.y, e.w, e.h
    -- Bottom
    local bx1, by1 = world_to_tile(ex + 2, ey + eh + 1)
    local bx2, by2 = world_to_tile(ex + ew - 2, ey + eh + 1)
    if e.vy >= 0 and (solid(bx1, by1) or solid(bx2, by2)) then
        e.y = (by1 - 1) * TILE - eh
        e.vy = 0
        e.on_ground = true
    else
        e.on_ground = false
    end
    -- Top
    local tx1, ty1 = world_to_tile(ex + 2, ey - 1)
    local tx2, ty2 = world_to_tile(ex + ew - 2, ey - 1)
    if e.vy < 0 and (solid(tx1, ty1) or solid(tx2, ty2)) then
        e.y = ty1 * TILE
        e.vy = 0
    end
    -- Left/Right
    local lx, ly = world_to_tile(ex - 1, ey + 4)
    if solid(lx, ly) then e.x = lx * TILE; e.vx = 0 end
    local rx, ry = world_to_tile(ex + ew + 1, ey + 4)
    if solid(rx, ry) then e.x = (rx - 1) * TILE - ew; e.vx = 0 end
end

local function init_level()
    enemies = {}; gems = {}
    for row = 1, map_rows do
        for col = 1, map_cols do
            local ch = tile_at(col, row)
            local wx = (col - 1) * TILE
            local wy = (row - 1) * TILE
            if ch == "G" then gems[#gems+1] = {x = wx + 8, y = wy + 8, w = 16, h = 16, alive = true} end
            if ch == "M" then enemies[#enemies+1] = {x = wx, y = wy, vx = 80, vy = 0, w = 28, h = 28, on_ground = false, alive = true} end
            if ch == "E" then exit_tile = {x = wx, y = wy, w = TILE, h = TILE} end
        end
    end
    player = { x = TILE * 2, y = TILE * 9, vx = 0, vy = 0, w = 24, h = 32, on_ground = false, facing = 1 }
    camera_x = 0
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.3, 0.5, 0.9)
    score = 0; lives = 3; level = 1
    init_level()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end

    -- Player horizontal
    local move = 0
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a")  then move = -1 end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then move =  1 end
    player.vx = move * PLAYER_SPEED
    if move ~= 0 then player.facing = move end

    -- Gravity
    if not player.on_ground then player.vy = player.vy + GRAVITY * dt end

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    collide_rect(player)

    -- Camera follow
    local target_cx = player.x - W / 3
    camera_x = camera_x + (target_cx - camera_x) * SCROLL_SPEED
    camera_x = math.max(0, math.min(map_cols * TILE - W, camera_x))

    -- Enemy update
    for _, e in ipairs(enemies) do
        if e.alive then
            if not e.on_ground then e.vy = e.vy + GRAVITY * dt end
            e.x = e.x + e.vx * dt
            e.y = e.y + e.vy * dt
            collide_rect(e)
            -- Reverse at walls
            if e.vx > 0 and solid(world_to_tile(e.x + e.w + 2, e.y + e.h - 4)) then e.vx = -e.vx end
            if e.vx < 0 and solid(world_to_tile(e.x - 2, e.y + e.h - 4)) then e.vx = -e.vx end
            -- Player stomp
            local dx = math.abs((e.x + e.w/2) - (player.x + player.w/2))
            local dy = math.abs((e.y + e.h/2) - (player.y + player.h/2))
            if dx < (e.w + player.w)/2 - 4 and dy < (e.h + player.h)/2 - 4 then
                if player.vy > 0 and player.y + player.h < e.y + e.h * 0.6 then
                    e.alive = false; player.vy = JUMP_VEL * 0.6; score = score + 200
                else
                    lives = lives - 1
                    if lives <= 0 then game_state = "gameover" else init_level() end
                    return
                end
            end
        end
    end

    -- Gem collection
    for _, g in ipairs(gems) do
        if g.alive then
            if player.x + player.w > g.x and player.x < g.x + g.w and
               player.y + player.h > g.y and player.y < g.y + g.h then
                g.alive = false; score = score + 50
            end
        end
    end

    -- Exit
    if exit_tile.x and player.x + player.w > exit_tile.x and player.x < exit_tile.x + exit_tile.w and
       player.y + player.h > exit_tile.y and player.y < exit_tile.y + exit_tile.h then
        score = score + level * 500
        level = level + 1
        init_level()
    end

    -- Fall off screen
    if player.y > map_rows * TILE then
        lives = lives - 1
        if lives <= 0 then game_state = "gameover" else init_level() end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    local cam = math.floor(camera_x)

    -- Tiles
    local first_col = math.floor(cam / TILE)
    local last_col  = first_col + math.ceil(W / TILE) + 2
    for row = 1, map_rows do
        for col = first_col, last_col do
            local ch = tile_at(col, row)
            local sx = (col - 1) * TILE - cam
            local sy = (row - 1) * TILE
            if ch == "1" then
                lurek.gfx.setColor(0.55, 0.38, 0.15)
                lurek.gfx.rectangle("fill", sx, sy, TILE, TILE)
                lurek.gfx.setColor(0.7, 0.5, 0.25)
                lurek.gfx.rectangle("line", sx, sy, TILE, TILE)
            end
        end
    end

    -- Exit
    if exit_tile.x then
        local sx = exit_tile.x - cam
        lurek.gfx.setColor(0.1, 0.9, 0.3)
        lurek.gfx.rectangle("fill", sx, exit_tile.y, exit_tile.w, exit_tile.h)
        lurek.gfx.setColor(0, 0, 0)
        lurek.gfx.print("EXIT", sx + 3, exit_tile.y + 8, 1.2)
    end

    -- Gems
    for _, g in ipairs(gems) do
        if g.alive then
            lurek.gfx.setColor(1, 0.2, 0.8)
            lurek.gfx.circle("fill", g.x - cam + 8, g.y + 8, 8)
            lurek.gfx.setColor(1, 0.7, 1)
            lurek.gfx.circle("fill", g.x - cam + 5, g.y + 5, 3)
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if e.alive then
            local sx = e.x - cam
            lurek.gfx.setColor(0.9, 0.3, 0.1)
            lurek.gfx.rectangle("fill", sx + 2, e.y + 2, e.w - 4, e.h - 4)
            lurek.gfx.setColor(1, 1, 1)
            lurek.gfx.circle("fill", sx + (e.vx > 0 and e.w - 8 or 8), e.y + 8, 5)
        end
    end

    -- Player
    local px = player.x - cam
    lurek.gfx.setColor(0.2, 0.2, 0.8)
    lurek.gfx.rectangle("fill", px + 2, player.y + player.h/3, player.w - 4, player.h * 2/3)
    lurek.gfx.setColor(0.9, 0.7, 0.5)
    lurek.gfx.circle("fill", px + player.w/2, player.y + 14, 12)
    -- Hair / hat
    lurek.gfx.setColor(1, 0.8, 0.1)
    lurek.gfx.rectangle("fill", px + 2, player.y - 4, player.w - 4, 10)

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.5)
    lurek.gfx.rectangle("fill", 0, 0, W, 28)
    lurek.gfx.setColor(1, 1, 0)
    lurek.gfx.print("GIANA  Score: " .. score, 8, 5, 1.5)
    lurek.gfx.setColor(1, 0.5, 0.5)
    lurek.gfx.print("Lives: " .. lives, W - 100, 5, 1.5)
    lurek.gfx.setColor(0.5, 1, 0.5)
    lurek.gfx.print("Level " .. level, W/2 - 30, 5, 1.5)

    -- Overlay
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(1, 0.2, 0.2)
        lurek.gfx.print("GAME OVER", W/2 - 80, H/2 - 25, 3)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    if game_state ~= "playing" then return end
    if (key == "space" or key == "up" or key == "w") and player.on_ground then
        player.vy = JUMP_VEL
        player.on_ground = false
    end
end
