-- Factory Automation — Grid-based logistics demo
-- Click to place, 1-4 select type, R rotate, right-click delete
-- Run with: cargo run -- content/demos/simulation/factory

local TILE = 32
local COLS, ROWS = 25, 18
local W, H = COLS * TILE, ROWS * TILE

local grid       -- grid[r][c] = { type, dir, timer, input, output, ... }
local items      -- moving items on conveyors
local place_type -- 1=conveyor, 2=miner, 3=smelter, 4=assembler
local place_dir  -- 0=right,1=down,2=left,3=up
local product_count, ingot_count
local ore_patches -- random ore locations

local DIR_DX = { [0] = 1, [1] = 0, [2] = -1, [3] = 0 }
local DIR_DY = { [0] = 0, [1] = 1, [2] = 0, [3] = -1 }
local TYPE_NAMES = { "Conveyor", "Miner", "Smelter", "Assembler" }
local TYPE_COLORS = {
    { 0.5, 0.5, 0.5 }, -- conveyor
    { 0.7, 0.5, 0.2 }, -- miner
    { 0.9, 0.4, 0.2 }, -- smelter
    { 0.3, 0.5, 0.9 }, -- assembler
}
local ITEM_COLORS = {
    ore    = { 0.6, 0.4, 0.2 },
    ingot  = { 0.8, 0.8, 0.3 },
    product = { 0.3, 0.9, 0.4 },
}

local function in_bounds(c, r) return c >= 1 and c <= COLS and r >= 1 and r <= ROWS end

local function output_pos(c, r, dir)
    return c + DIR_DX[dir], r + DIR_DY[dir]
end

function lurek.init()
    lurek.window.setTitle("Factory Automation")
    lurek.render.setBackgroundColor(0.12, 0.14, 0.12)
    grid = {}
    for r = 1, ROWS do
        grid[r] = {}
        for c = 1, COLS do grid[r][c] = nil end
    end
    items = {}
    place_type = 1
    place_dir = 0
    product_count = 0
    ingot_count = 0

    -- scatter ore patches
    ore_patches = {}
    for i = 1, 12 do
        local c = math.random(2, COLS - 1)
        local r = math.random(2, ROWS - 1)
        ore_patches[r * 100 + c] = true
    end
end

local function try_push_item(item_type, to_c, to_r)
    -- Items reaching the grid boundary are consumed (products increment the global counter)
    if not in_bounds(to_c, to_r) then
        if item_type == "product" then product_count = product_count + 1 end
        return true -- consumed at edge
    end
    local dest = grid[to_r] and grid[to_r][to_c]
    if not dest then return false end

    if dest.type == 1 then -- conveyor: add item
        table.insert(items, { kind = item_type, c = to_c, r = to_r, progress = 0 })
        return true
    elseif dest.type == 3 and item_type == "ore" and (dest.input_count or 0) < 3 then
        dest.input_count = (dest.input_count or 0) + 1
        return true
    elseif dest.type == 4 and item_type == "ingot" and (dest.input_count or 0) < 3 then
        dest.input_count = (dest.input_count or 0) + 1
        return true
    end
    return false
end

function lurek.process(dt)
    -- machines tick
    for r = 1, ROWS do
        for c = 1, COLS do
            local cell = grid[r][c]
            if cell then
                cell.timer = (cell.timer or 0) + dt

                if cell.type == 2 then -- miner: produce ore every 2s if on ore patch
                    if ore_patches[r * 100 + c] and cell.timer >= 2 then
                        cell.timer = 0
                        local nc, nr = output_pos(c, r, cell.dir)
                        try_push_item("ore", nc, nr)
                    end
                elseif cell.type == 3 then -- smelter: ore -> ingot every 3s
                    if (cell.input_count or 0) >= 1 and cell.timer >= 3 then
                        cell.timer = 0
                        cell.input_count = cell.input_count - 1
                        local nc, nr = output_pos(c, r, cell.dir)
                        if not try_push_item("ingot", nc, nr) then
                            ingot_count = ingot_count + 1
                        end
                    end
                elseif cell.type == 4 then -- assembler: 2 ingots -> product every 4s
                    if (cell.input_count or 0) >= 2 and cell.timer >= 4 then
                        cell.timer = 0
                        cell.input_count = cell.input_count - 2
                        local nc, nr = output_pos(c, r, cell.dir)
                        if not try_push_item("product", nc, nr) then
                            product_count = product_count + 1
                        end
                    end
                end
            end
        end
    end

    -- move items on conveyors
    -- Belt progress 0→1 represents sub-tile position; at 1 the item advances to the next cell
    local speed = 1.5 -- tiles per second
    for i = #items, 1, -1 do
        local it = items[i]
        it.progress = it.progress + speed * dt
        if it.progress >= 1 then
            local cell = grid[it.r] and grid[it.r][it.c]
            local dir = cell and cell.dir or 0
            local nc, nr = output_pos(it.c, it.r, dir)
            table.remove(items, i)
            try_push_item(it.kind, nc, nr)
        end
    end
end

local function draw_arrow(cx, cy, dir, size)
    local dx, dy = DIR_DX[dir] * size, DIR_DY[dir] * size
    local px, py = -dy * 0.4, dx * 0.4
    lurek.render.polygon("fill", {
        cx + dx, cy + dy,
        cx - dx * 0.3 + px, cy - dy * 0.3 + py,
        cx - dx * 0.3 - px, cy - dy * 0.3 - py
    })
end

function lurek.render()
    -- grid lines
    lurek.render.setColor(0.2, 0.22, 0.2, 0.5)
    for r = 0, ROWS do
        lurek.render.line(0, r * TILE, W, r * TILE)
    end
    for c = 0, COLS do
        lurek.render.line(c * TILE, 0, c * TILE, H)
    end

    -- ore patches
    for key, _ in pairs(ore_patches) do
        local pr = math.floor(key / 100)
        local pc = key - pr * 100
        lurek.render.setColor(0.4, 0.3, 0.15, 0.5)
        lurek.render.rectangle("fill", (pc - 1) * TILE + 2, (pr - 1) * TILE + 2, TILE - 4, TILE - 4)
    end

    -- buildings
    for r = 1, ROWS do
        for c = 1, COLS do
            local cell = grid[r][c]
            if cell then
                local col = TYPE_COLORS[cell.type]
                lurek.render.setColor(col[1], col[2], col[3], 0.85)
                lurek.render.rectangle("fill", (c - 1) * TILE + 1, (r - 1) * TILE + 1, TILE - 2, TILE - 2)
                -- direction arrow
                lurek.render.setColor(1, 1, 1, 0.7)
                local cx = (c - 1) * TILE + TILE / 2
                local cy = (r - 1) * TILE + TILE / 2
                draw_arrow(cx, cy, cell.dir, 8)

                -- input count indicator
                if cell.input_count and cell.input_count > 0 then
                    lurek.render.setColor(1, 1, 1, 1)
                    lurek.render.print(tostring(cell.input_count), (c - 1) * TILE + 2, (r - 1) * TILE + 1, 0.7)
                end
            end
        end
    end

    -- items on conveyors
    for _, it in ipairs(items) do
        local cell = grid[it.r] and grid[it.r][it.c]
        local dir = cell and cell.dir or 0
        local bx = (it.c - 1) * TILE + TILE / 2 + DIR_DX[dir] * (it.progress - 0.5) * TILE
        local by = (it.r - 1) * TILE + TILE / 2 + DIR_DY[dir] * (it.progress - 0.5) * TILE
        local ic = ITEM_COLORS[it.kind] or { 1, 1, 1 }
        lurek.render.setColor(ic[1], ic[2], ic[3], 1)
        lurek.render.rectangle("fill", bx - 4, by - 4, 8, 8)
    end

    -- ghost preview
    local mx, my = lurek.mouse.getPosition()
    local gc = math.floor(mx / TILE) + 1
    local gr = math.floor(my / TILE) + 1
    if in_bounds(gc, gr) then
        local col = TYPE_COLORS[place_type]
        lurek.render.setColor(col[1], col[2], col[3], 0.35)
        lurek.render.rectangle("fill", (gc - 1) * TILE, (gr - 1) * TILE, TILE, TILE)
        lurek.render.setColor(1, 1, 1, 0.5)
        draw_arrow((gc - 1) * TILE + TILE / 2, (gr - 1) * TILE + TILE / 2, place_dir, 8)
    end

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.7)
    lurek.render.rectangle("fill", 0, H, W, 30)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Placing: " .. TYPE_NAMES[place_type] .. "  Dir: " .. ({"R","D","L","U"})[place_dir + 1]
        .. "  |  Products: " .. product_count .. "  |  1-4: type  R: rotate  Click: place  RightClick: delete", 8, H + 6, 0.8)
end

function lurek.mousepressed(x, y, button)
    local gc = math.floor(x / TILE) + 1
    local gr = math.floor(y / TILE) + 1
    if not in_bounds(gc, gr) then return end

    if button == 1 then
        grid[gr][gc] = { type = place_type, dir = place_dir, timer = 0, input_count = 0 }
    elseif button == 2 then
        grid[gr][gc] = nil
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "1" then place_type = 1 end
    if key == "2" then place_type = 2 end
    if key == "3" then place_type = 3 end
    if key == "4" then place_type = 4 end
    if key == "r" then place_dir = (place_dir + 1) % 4 end
end
