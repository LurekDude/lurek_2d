-- Boulder Dash — C-64 Classic (Lurek2D demo)
-- Dig through caves, collect diamonds, and escape before time runs out.
-- Avoid boulders that fall if their support is dug away.
-- Run with: cargo run -- content/demos/retro/boulder_dash

-- ── Constants ────────────────────────────────────────────────────────────

local CELL = 20
local MAP_W, MAP_H = 40, 26
local VIEW_W, VIEW_H = 40, 28
local W, H = 800, 560

-- Cell types
local EMPTY = 0
local EARTH = 1
local WALL  = 2
local BOULDER = 3
local DIAMOND = 4
local PLAYER = 5
local EXIT = 6

local COLORS = {
    [EMPTY]   = {0.06, 0.04, 0.02},
    [EARTH]   = {0.55, 0.35, 0.12},
    [WALL]    = {0.4,  0.4,  0.45},
    [BOULDER] = {0.75, 0.65, 0.5},
    [DIAMOND] = {0.3,  0.8,  1.0},
    [EXIT]    = {0.1,  0.9,  0.3},
}

-- ── State ─────────────────────────────────────────────────────────────────

local map = {}
local player_x, player_y
local score, lives, level = 0, 3, 1
local diamonds_needed, diamonds_got = 0, 0
local time_left = 0
local game_state = "playing"
local phys_timer = 0
local PHYS_STEP = 0.18

-- ── Helpers ──────────────────────────────────────────────────────────────

local function cell(x, y)     return (x >= 0 and x < MAP_W and y >= 0 and y < MAP_H) and map[y * MAP_W + x] or WALL end
local function set_cell(x, y, v) if x >= 0 and x < MAP_W and y >= 0 and y < MAP_H then map[y * MAP_W + x] = v end end

local function gen_level()
    map = {}
    for i = 0, MAP_W * MAP_H - 1 do map[i] = EARTH end
    -- Border walls
    for x = 0, MAP_W - 1 do set_cell(x, 0, WALL); set_cell(x, MAP_H - 1, WALL) end
    for y = 0, MAP_H - 1 do set_cell(0, y, WALL); set_cell(MAP_W - 1, y, WALL) end
    -- Scattered walls
    for i = 1, 30 + level * 3 do
        set_cell(math.random(1, MAP_W - 2), math.random(1, MAP_H - 2), WALL)
    end
    -- Boulders
    for i = 1, 40 + level * 2 do
        local bx, by = math.random(1, MAP_W - 2), math.random(2, MAP_H - 2)
        if cell(bx, by) == EARTH then set_cell(bx, by, BOULDER) end
    end
    -- Diamonds
    diamonds_needed = 10 + level * 2
    diamonds_got = 0
    for i = 1, diamonds_needed + 8 do
        local dx, dy = math.random(1, MAP_W - 2), math.random(2, MAP_H - 2)
        if cell(dx, dy) == EARTH then set_cell(dx, dy, DIAMOND) end
    end
    -- Player start
    player_x = 2; player_y = 1
    set_cell(player_x, player_y, EMPTY)
    set_cell(player_x, player_y + 1, EMPTY)
    -- Exit (locked until enough diamonds)
    set_cell(MAP_W - 3, MAP_H - 2, EXIT)
    time_left = 120 - (level - 1) * 5
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.04, 0.03, 0.01)
    score = 0; lives = 3; level = 1
    gen_level()
end

-- ── Update ───────────────────────────────────────────────────────────────

local move_cd = 0

function lurek.process(dt)
    if game_state ~= "playing" then return end
    time_left = time_left - dt
    if time_left <= 0 then
        lives = lives - 1
        if lives <= 0 then game_state = "gameover" else gen_level() end
        return
    end

    move_cd = math.max(0, move_cd - dt)

    -- Movement
    local dx, dy = 0, 0
    if lurek.input.isKeyDown("left") or lurek.input.isKeyDown("a")  then dx = -1 end
    if lurek.input.isKeyDown("right") or lurek.input.isKeyDown("d") then dx =  1 end
    if lurek.input.isKeyDown("up") or lurek.input.isKeyDown("w")    then dy = -1 end
    if lurek.input.isKeyDown("down") or lurek.input.isKeyDown("s")  then dy =  1 end

    if (dx ~= 0 or dy ~= 0) and move_cd <= 0 then
        move_cd = 0.14
        local nx, ny = player_x + dx, player_y + dy
        local nc = cell(nx, ny)
        local can_move = nc == EMPTY or nc == EARTH or nc == DIAMOND or
                         (nc == EXIT and diamonds_got >= diamonds_needed)
        -- Push boulder horizontally
        if nc == BOULDER and dy == 0 and cell(nx + dx, ny) == EMPTY then
            set_cell(nx + dx, ny, BOULDER)
            set_cell(nx, ny, EMPTY)
            can_move = true
        end
        if can_move then
            if nc == DIAMOND then diamonds_got = diamonds_got + 1; score = score + 50 end
            if nc == EXIT and diamonds_got >= diamonds_needed then
                level = level + 1; score = score + math.floor(time_left) * 10
                gen_level(); return
            end
            set_cell(player_x, player_y, EMPTY)
            player_x, player_y = nx, ny
        end
    end

    -- Physics step (boulders and diamonds fall)
    phys_timer = phys_timer + dt
    if phys_timer < PHYS_STEP then return end
    phys_timer = 0

    for y = MAP_H - 2, 1, -1 do
        for x = 1, MAP_W - 2 do
            local c = cell(x, y)
            if c == BOULDER or c == DIAMOND then
                -- Fall down
                if cell(x, y + 1) == EMPTY then
                    set_cell(x, y + 1, c); set_cell(x, y, EMPTY)
                    -- Crush player
                    if x == player_x and y + 1 == player_y then
                        lives = lives - 1
                        if lives <= 0 then game_state = "gameover" else gen_level() end
                        return
                    end
                -- Roll off to side
                elseif cell(x + 1, y) == EMPTY and cell(x + 1, y + 1) == EMPTY then
                    set_cell(x + 1, y, c); set_cell(x, y, EMPTY)
                elseif cell(x - 1, y) == EMPTY and cell(x - 1, y + 1) == EMPTY then
                    set_cell(x - 1, y, c); set_cell(x, y, EMPTY)
                end
            end
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

local function cell_px(cx, cy) return cx * CELL, cy * CELL + 40 end

function lurek.render()
    -- HUD
    lurek.render.setColor(0, 0, 0)
    lurek.render.rectangle("fill", 0, 0, W, 40)
    lurek.render.setColor(0.9, 0.7, 0.2)
    lurek.render.print("BOULDER DASH", 8, 6, 1.6)
    lurek.render.setColor(0.3, 0.8, 1)
    lurek.render.print("Dia: " .. diamonds_got .. "/" .. diamonds_needed, W/2 - 60, 8, 1.5)
    lurek.render.setColor(1, 0.4, 0.4)
    local tsec = math.max(0, math.floor(time_left))
    lurek.render.print("Time: " .. tsec, W - 120, 8, 1.5)
    lurek.render.setColor(0.7, 0.9, 0.7)
    lurek.render.print("Score: " .. score, W/2 + 80, 8, 1.5)

    -- Map cells
    for y = 0, MAP_H - 1 do
        for x = 0, MAP_W - 1 do
            local c = cell(x, y)
            if c ~= EMPTY then
                local col = COLORS[c] or {1, 0, 1}
                local px, py = cell_px(x, y)
                lurek.render.setColor(col[1], col[2], col[3])
                if c == BOULDER then
                    lurek.render.circle("fill", px + CELL/2, py + CELL/2, CELL/2 - 1)
                elseif c == DIAMOND then
                    -- Diamond shape
                    lurek.render.circle("fill", px + CELL/2, py + CELL/2, CELL/2 - 2)
                    lurek.render.setColor(0.7, 1, 1)
                    lurek.render.circle("fill", px + CELL/2 - 2, py + CELL/2 - 2, 3)
                elseif c == EXIT then
                    local open = diamonds_got >= diamonds_needed
                    lurek.render.setColor(open and 0.1 or 0.5, open and 0.9 or 0.5, open and 0.3 or 0.5)
                    lurek.render.rectangle("fill", px + 2, py + 2, CELL - 4, CELL - 4)
                else
                    lurek.render.rectangle("fill", px + 1, py + 1, CELL - 2, CELL - 2)
                end
            end
        end
    end

    -- Player
    local px, py = cell_px(player_x, player_y)
    lurek.render.setColor(1, 0.9, 0.3)
    lurek.render.circle("fill", px + CELL/2, py + CELL/2, CELL/2 - 1)
    lurek.render.setColor(0.2, 0.1, 0)
    lurek.render.circle("fill", px + CELL/2 - 3, py + CELL/2 - 2, 2)
    lurek.render.circle("fill", px + CELL/2 + 3, py + CELL/2 - 2, 2)

    -- Game-over overlay
    if game_state == "gameover" then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 0.3, 0.1)
        lurek.render.print("GAME OVER", W/2 - 80, H/2 - 25, 3)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("Score: " .. score, W/2 - 55, H/2 + 15, 2)
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
end
