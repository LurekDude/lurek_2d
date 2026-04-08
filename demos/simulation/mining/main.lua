-- Mining Demo: Side-view destructible mining world
-- WASD to move, click adjacent tiles to mine, L to place ladders
-- Run with: cargo run -- demos/simulation/mining

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local TILE_SIZE = 16
local GRID_W, GRID_H = 50, 80
local SURFACE_Y = 8

-- Tile types
local EMPTY, DIRT, STONE, ORE, GEM, LADDER, SKY = 0, 1, 2, 3, 4, 5, 6

local grid = {}
local player = { x = 25, y = 6, vy = 0, on_ground = false }
local inventory = { dirt = 0, stone = 0, ore = 0, gem = 0 }
local mining = { active = false, tx = 0, ty = 0, progress = 0, required = 0 }
local camera_y = 0
local SCREEN_W, SCREEN_H = 800, 600

local mine_times = { [DIRT] = 0.3, [STONE] = 0.8, [ORE] = 1.5, [GEM] = 2.0 }

local tile_colors = {
    [SKY]    = {0.4, 0.7, 1.0},
    [DIRT]   = {0.55, 0.35, 0.2},
    [STONE]  = {0.5, 0.5, 0.5},
    [ORE]    = {0.8, 0.6, 0.2},
    [GEM]    = {0.2, 0.8, 0.9},
    [LADDER] = {0.6, 0.5, 0.3},
    [EMPTY]  = {0.08, 0.06, 0.05},
}

local function get_tile(gx, gy)
    if gx < 1 or gx > GRID_W or gy < 1 or gy > GRID_H then return STONE end
    return grid[gy][gx]
end

local function set_tile(gx, gy, t)
    if gx >= 1 and gx <= GRID_W and gy >= 1 and gy <= GRID_H then
        grid[gy][gx] = t
    end
end

local function is_solid(gx, gy)
    local t = get_tile(gx, gy)
    return t ~= EMPTY and t ~= LADDER and t ~= SKY
end

function luna.init()
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            if y <= SURFACE_Y then
                grid[y][x] = SKY
            else
                local depth = y - SURFACE_Y
                local r = math.random()
                if r < 0.005 + depth * 0.001 then
                    grid[y][x] = GEM
                elseif r < 0.03 + depth * 0.004 then
                    grid[y][x] = ORE
                elseif r < 0.15 + depth * 0.005 then
                    grid[y][x] = STONE
                else
                    grid[y][x] = DIRT
                end
            end
        end
    end
    -- Clear spawn area
    for dy = -1, 0 do
        set_tile(player.x, SURFACE_Y + dy, SKY)
    end
    set_tile(player.x, SURFACE_Y + 1, EMPTY)
end

function luna.process(dt)
    local px, py = player.x, player.y
    local speed = 8 * dt

    -- Horizontal movement
    local dx = 0
    if luna.keyboard.isDown("a") then dx = -speed end
    if luna.keyboard.isDown("d") then dx = speed end

    local new_x = px + dx
    local gx = math.floor(new_x) + 1
    local gy = math.floor(py) + 1
    if not is_solid(gx, gy) then
        player.x = new_x
    end

    -- Ladder climbing
    local cur_gx = math.floor(player.x) + 1
    local cur_gy = math.floor(player.y) + 1
    local on_ladder = get_tile(cur_gx, cur_gy) == LADDER

    if on_ladder then
        player.vy = 0
        if luna.keyboard.isDown("w") then player.y = player.y - speed end
        if luna.keyboard.isDown("s") then player.y = player.y + speed end
    else
        -- Gravity
        player.vy = player.vy + 20 * dt
        if luna.keyboard.isDown("w") and player.on_ground then
            player.vy = -8
        end
    end

    player.y = player.y + player.vy * dt

    -- Vertical collision
    local foot_gy = math.floor(player.y + 0.9) + 1
    local head_gy = math.floor(player.y) + 1
    cur_gx = math.floor(player.x) + 1

    player.on_ground = false
    if player.vy > 0 and is_solid(cur_gx, foot_gy) then
        player.y = foot_gy - 2
        player.vy = 0
        player.on_ground = true
    end
    if player.vy < 0 and is_solid(cur_gx, head_gy) then
        player.y = head_gy
        player.vy = 0
    end

    -- Clamp
    player.x = clamp(player.x, 0, GRID_W - 1)
    player.y = clamp(player.y, 0, GRID_H - 2)

    -- Camera
    camera_y = lerp(camera_y, player.y * TILE_SIZE - SCREEN_H / 2, 5 * dt)

    -- Mining
    if mining.active then
        mining.progress = mining.progress + dt
        if mining.progress >= mining.required then
            local t = get_tile(mining.tx, mining.ty)
            if t == DIRT then inventory.dirt = inventory.dirt + 1
            elseif t == STONE then inventory.stone = inventory.stone + 1
            elseif t == ORE then inventory.ore = inventory.ore + 1
            elseif t == GEM then inventory.gem = inventory.gem + 1
            end
            set_tile(mining.tx, mining.ty, EMPTY)
            mining.active = false
        end
    end
end

function luna.mousepressed(mx, my, button)
    if button == 1 then
        local gx = math.floor((mx) / TILE_SIZE) + 1
        local gy = math.floor((my + camera_y) / TILE_SIZE) + 1
        local pgx = math.floor(player.x) + 1
        local pgy = math.floor(player.y) + 1
        local ddx = math.abs(gx - pgx)
        local ddy = math.abs(gy - pgy)
        if ddx + ddy <= 2 then
            local t = get_tile(gx, gy)
            if mine_times[t] then
                mining.active = true
                mining.tx = gx
                mining.ty = gy
                mining.progress = 0
                mining.required = mine_times[t]
            end
        end
    end
end

function luna.keypressed(key)
    if key == "l" then
        local gx = math.floor(player.x) + 1
        local gy = math.floor(player.y + 1) + 1
        if get_tile(gx, gy) == EMPTY then
            set_tile(gx, gy, LADDER)
        end
    end
    if key == "escape" then luna.signal.quit() end
end

function luna.render()
    luna.gfx.setBackgroundColor(0.05, 0.05, 0.08)

    local pgx = math.floor(player.x) + 1
    local pgy = math.floor(player.y) + 1

    -- Visible tile range
    local start_row = math.floor(camera_y / TILE_SIZE)
    local end_row = start_row + math.floor(SCREEN_H / TILE_SIZE) + 2

    for y = clamp(start_row, 1, GRID_H), clamp(end_row, 1, GRID_H) do
        for x = 1, GRID_W do
            local t = grid[y][x]
            if t ~= EMPTY then
                local dist = math.sqrt((x - pgx) ^ 2 + (y - pgy) ^ 2)
                local light = clamp(1.0 - dist / 12, 0.1, 1.0)
                if t == SKY then light = 1.0 end
                local c = tile_colors[t]
                luna.gfx.setColor(c[1] * light, c[2] * light, c[3] * light, 1)
                luna.gfx.rectangle("fill",
                    (x - 1) * TILE_SIZE,
                    (y - 1) * TILE_SIZE - camera_y,
                    TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- Mining progress bar
    if mining.active then
        local mx = (mining.tx - 1) * TILE_SIZE
        local my = (mining.ty - 1) * TILE_SIZE - camera_y
        local pct = mining.progress / mining.required
        luna.gfx.setColor(1, 1, 0, 0.8)
        luna.gfx.rectangle("fill", mx, my - 4, TILE_SIZE * pct, 3)
    end

    -- Player
    local sx = player.x * TILE_SIZE
    local sy = player.y * TILE_SIZE - camera_y
    luna.gfx.setColor(0.2, 0.9, 0.3, 1)
    luna.gfx.rectangle("fill", sx, sy, TILE_SIZE, TILE_SIZE)

    -- HUD
    luna.gfx.setColor(1, 1, 1, 1)
    local depth = math.floor(player.y - SURFACE_Y)
    if depth < 0 then depth = 0 end
    luna.gfx.print("Depth: " .. depth .. "m", 10, 10)
    luna.gfx.print("Dirt:" .. inventory.dirt .. " Stone:" .. inventory.stone ..
        " Ore:" .. inventory.ore .. " Gem:" .. inventory.gem, 10, 28)
    luna.gfx.print("WASD:move  Click:mine  L:ladder", 10, 46)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 700, 10)
end
