local Dungeon = {}

--- Generate a simple dungeon map using BSP-inspired room placement.
--- Returns a 2D array: 0 = floor, 1 = wall.
function Dungeon.generate(width, height)
    -- Start with all walls
    local map = {}
    for y = 1, height do
        map[y] = {}
        for x = 1, width do
            map[y][x] = 1
        end
    end

    -- Carve random rooms
    local rooms = {}
    for _ = 1, 8 do
        local rw = math.random(4, 10)
        local rh = math.random(4, 8)
        local rx = math.random(2, width - rw - 1)
        local ry = math.random(2, height - rh - 1)
        rooms[#rooms + 1] = { x = rx, y = ry, w = rw, h = rh }
        for y = ry, ry + rh - 1 do
            for x = rx, rx + rw - 1 do
                map[y][x] = 0
            end
        end
    end

    -- Connect rooms with corridors
    for i = 2, #rooms do
        local a = rooms[i - 1]
        local b = rooms[i]
        local ax = math.floor(a.x + a.w / 2)
        local ay = math.floor(a.y + a.h / 2)
        local bx = math.floor(b.x + b.w / 2)
        local by = math.floor(b.y + b.h / 2)
        -- Horizontal then vertical
        local cx = ax
        while cx ~= bx do
            if ay >= 1 and ay <= height then map[ay][cx] = 0 end
            cx = cx + (bx > ax and 1 or -1)
        end
        local cy = ay
        while cy ~= by do
            if bx >= 1 and bx <= width then map[cy][bx] = 0 end
            cy = cy + (by > ay and 1 or -1)
        end
    end

    return map
end

return Dungeon
