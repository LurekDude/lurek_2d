# Procedural Generation

BSP room generation, corridor connection, weighted loot tables, enemy placement, secret rooms, and seeded random.

## Key Concepts

- **BSP (Binary Space Partition)**: Recursively split a rectangle into sub-regions. Place rooms inside leaves.
- **Corridors**: Connect room centers with L-shaped hallways.
- **Weighted random**: Select items from a probability table. Used for loot, enemy types, room themes.
- **Seeded RNG**: Use a fixed seed for reproducible worlds. Store seed in save data.
- **Enemy placement**: Distribute enemies based on room size and difficulty curve.

## Seeded Random

```lua
local rng_state = 12345

local function seed_rng(s)
    rng_state = s
end

local function next_random()
    -- Simple LCG (replace with better PRNG if needed)
    rng_state = (rng_state * 1103515245 + 12345) % (2^31)
    return rng_state / (2^31)
end

local function random_int(min, max)
    return math.floor(next_random() * (max - min + 1)) + min
end
```

## BSP Room Generation

```lua
local MIN_ROOM = 6
local ROOM_PAD = 2

local function bsp_split(x, y, w, h, depth)
    if depth <= 0 or (w < MIN_ROOM * 2 and h < MIN_ROOM * 2) then
        -- Leaf: place a room with padding
        local rw = random_int(MIN_ROOM, w - ROOM_PAD)
        local rh = random_int(MIN_ROOM, h - ROOM_PAD)
        local rx = x + random_int(1, w - rw - 1)
        local ry = y + random_int(1, h - rh - 1)
        return {{ x = rx, y = ry, w = rw, h = rh }}
    end

    local rooms = {}
    if w > h then
        -- Vertical split
        local split = random_int(MIN_ROOM, w - MIN_ROOM)
        local left  = bsp_split(x, y, split, h, depth - 1)
        local right = bsp_split(x + split, y, w - split, h, depth - 1)
        for _, r in ipairs(left)  do rooms[#rooms + 1] = r end
        for _, r in ipairs(right) do rooms[#rooms + 1] = r end
    else
        -- Horizontal split
        local split = random_int(MIN_ROOM, h - MIN_ROOM)
        local top    = bsp_split(x, y, w, split, depth - 1)
        local bottom = bsp_split(x, y + split, w, h - split, depth - 1)
        for _, r in ipairs(top)    do rooms[#rooms + 1] = r end
        for _, r in ipairs(bottom) do rooms[#rooms + 1] = r end
    end
    return rooms
end
```

## Corridor Connection

```lua
local function connect_rooms(grid, a, b, map_w)
    local ax = math.floor(a.x + a.w / 2)
    local ay = math.floor(a.y + a.h / 2)
    local bx = math.floor(b.x + b.w / 2)
    local by = math.floor(b.y + b.h / 2)

    -- Horizontal then vertical
    local x = ax
    while x ~= bx do
        grid[ay * map_w + x + 1] = 0  -- floor
        x = x + (bx > ax and 1 or -1)
    end
    local y = ay
    while y ~= by do
        grid[y * map_w + bx + 1] = 0
        y = y + (by > ay and 1 or -1)
    end
end
```

## Weighted Loot Table

```lua
local LOOT_TABLE = {
    { id = "gold",   weight = 50 },
    { id = "potion", weight = 30 },
    { id = "key",    weight = 10 },
    { id = "gem",    weight = 5 },
    { id = "none",   weight = 5 },
}

local function roll_loot()
    local total = 0
    for _, e in ipairs(LOOT_TABLE) do total = total + e.weight end
    local roll = next_random() * total
    local acc = 0
    for _, e in ipairs(LOOT_TABLE) do
        acc = acc + e.weight
        if roll <= acc then return e.id ~= "none" and e.id or nil end
    end
end
```

## Enemy Placement

```lua
local function place_enemies(room, difficulty)
    local area = room.w * room.h
    local count = math.floor(area / 20) + difficulty
    local enemies = {}
    for i = 1, count do
        enemies[#enemies + 1] = {
            x = room.x + random_int(1, room.w - 2),
            y = room.y + random_int(1, room.h - 2),
            type = difficulty > 3 and "skeleton" or "slime",
        }
    end
    return enemies
end
```

## Common Pitfalls

- **Not using seeded RNG** — `math.random()` gives different results each run. Use a seedable generator for reproducibility.
- **Rooms overlapping** — BSP prevents this by design, but validate bounds after padding.
- **Disconnected rooms** — always connect consecutive rooms in the list. Verify reachability.
- **Loot in walls** — place items at room center or floor tiles, never on wall tiles.
- **Difficulty scaling** — increase enemy count and type based on dungeon depth, not uniformly.
