-- content/library/roguelike/example.lua
-- Self-contained roguelike example: 12×8 dungeon, player + two monsters,
-- shadowcasting FOV, energy scheduler, and a goal-map-driven hunt loop.

local rl = require("library.roguelike")

-- ─── 1. Build a tiny dungeon (1 = wall, 0 = floor) ──────────────────────────

local W, H = 12, 8
local map = {
    "111111111111",
    "100000000001",
    "100011110001",
    "100010000001",
    "100010111101",
    "100000000001",
    "100000000001",
    "111111111111",
}
-- Convert to grid[y][x]
local grid = {}
for y = 1, H do
    grid[y] = {}
    for x = 1, W do
        grid[y][x] = tonumber(map[y]:sub(x, x))
    end
end
local function blocker(x, y)
    if x < 1 or x > W or y < 1 or y > H then return true end
    return grid[y][x] == 1
end

-- ─── 2. FOV from the player's position ──────────────────────────────────────

local fov = rl.newFov({ range = 7 }):setBlocker(blocker)
local px, py = 2, 2
fov:compute(px, py)

print("--- FOV from ("..px..","..py..") ---")
for y = 1, H do
    local row = ""
    for x = 1, W do
        if x == px and y == py then row = row .. "@"
        elseif blocker(x, y) then  row = row .. (fov:isVisible(x,y) and "#" or " ")
        elseif fov:isVisible(x, y) then row = row .. "."
        elseif fov:isExplored(x, y) then row = row .. ":"
        else row = row .. " "
        end
    end
    print(row)
end

-- ─── 3. Energy scheduler — Player(speed 12), Goblin(8), Wolf(15) ────────────

local Player = { name = "Player", x = px, y = py, speed = 12 }
local Goblin = { name = "Goblin", x = 9,  y = 6, speed = 8  }
local Wolf   = { name = "Wolf",   x = 10, y = 2, speed = 15 }

local sch = rl.newScheduler()
sch:add(Player, Player.speed)
sch:add(Goblin, Goblin.speed)
sch:add(Wolf,   Wolf.speed)

-- ─── 4. Goal map — monsters hunt the player ─────────────────────────────────

local hunt = rl.newGoalMap(W, H):setBlocker(blocker)
    :setSources({ { Player.x, Player.y, 0 } })
    :bake()

print("\n--- 8 turns ---")
local turns = {}
for _ = 1, 8 do
    local actor = sch:next()
    table.insert(turns, actor.name)
    if actor ~= Player then
        local dx, dy = hunt:gradientAt(actor.x, actor.y)
        actor.x = actor.x + dx
        actor.y = actor.y + dy
    end
end
print("turn order: " .. table.concat(turns, ", "))

-- ─── 5. Distances from player ───────────────────────────────────────────────

print("\n--- distances from player ---")
print(string.format("Goblin distance: %d", hunt:distanceAt(Goblin.x, Goblin.y)))
print(string.format("Wolf   distance: %d", hunt:distanceAt(Wolf.x,   Wolf.y)))

-- ─── 6. Flee — Wolf retreats from the player ────────────────────────────────

local fdx, fdy = hunt:flee(Wolf.x, Wolf.y, 1.5)
print(string.format("Wolf flee step: (%d, %d) from (%d,%d)",
    fdx, fdy, Wolf.x, Wolf.y))

-- ─── 7. Bresenham + LoS ─────────────────────────────────────────────────────

local los_pts = rl.bresenham(Player.x, Player.y, Goblin.x, Goblin.y)
print(string.format("\nLoS line has %d cells", #los_pts))
print("LoS visible: " .. tostring(rl.lineOfSight(fov, Player.x, Player.y, Goblin.x, Goblin.y)))

return Player, Goblin, Wolf, sch, fov, hunt
