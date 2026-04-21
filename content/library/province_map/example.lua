--- Example usage for library.province_map.
-- Run with: lua content/library/province_map/example.lua
-- Builds a small 4-province map programmatically, sets adjacency,
-- finds a route between provinces, and demonstrates faction map
-- modes with a fixed colour function. No PNG load (that path requires
-- lurek.image); we use the public construction API instead.
-- @module example.province_map

local M = require("library.province_map")

-- ── 1. Create an empty 8x8 province map ───────────────────────────────────────
local map = M.newProvinceMap(8, 8)
print(string.format("[example.province_map] map %dx%d", map:width(), map:height()))

-- ── 2. Build four provinces and insert them ───────────────────────────────────
local p_north = M.newProvince(1, { 200, 50,  50  })  ; p_north.name = "Northwald"
local p_south = M.newProvince(2, { 50,  200, 50  })  ; p_south.name = "Southreach"
local p_east  = M.newProvince(3, { 50,  50,  200 })  ; p_east.name  = "Eastmarch"
local p_west  = M.newProvince(4, { 200, 200, 50  })  ; p_west.name  = "Westhold"

p_north:setFaction("red")
p_south:setFaction("green")
p_east:setFaction("red")
p_west:setFaction("green")

p_north:setResource("gold", 100)
p_south:setResource("gold", 60)
p_east:setResource("gold", 40)
p_west:setResource("gold", 80)

map:insertProvince(p_north)
map:insertProvince(p_south)
map:insertProvince(p_east)
map:insertProvince(p_west)
print(string.format("[example.province_map] provinces=%d", map:provinceCount()))

-- ── 3. Paint pixels (province IDs) into the four quadrants ────────────────────
for y = 1, 4 do
    for x = 1, 4 do map:setPixel(x, y, 1) end          -- NW = north
    for x = 5, 8 do map:setPixel(x, y, 3) end          -- NE = east
end
for y = 5, 8 do
    for x = 1, 4 do map:setPixel(x, y, 4) end          -- SW = west
    for x = 5, 8 do map:setPixel(x, y, 2) end          -- SE = south
end
print(string.format("[example.province_map] pixel(1,1)=%s pixel(8,8)=%s",
    tostring(map:getProvinceAt(1, 1)), tostring(map:getProvinceAt(8, 8))))

-- ── 4. Define adjacency edges (so routing can hop between provinces) ──────────
map:setAdjacent(1, 3, { "land" })   -- N <-> E
map:setAdjacent(1, 4, { "land" })   -- N <-> W
map:setAdjacent(2, 3, { "land" })   -- S <-> E
map:setAdjacent(2, 4, { "land" })   -- S <-> W
print(string.format("[example.province_map] adjacency edges=%d", map:adjacencyCount()))

local neighbors = map:getNeighbors(1)
table.sort(neighbors)
print(string.format("[example.province_map] neighbors of #1 = [%s]",
    table.concat(neighbors, ",")))

-- ── 5. BFS shortest path between two provinces ────────────────────────────────
local route = map:findRoute(1, 2)
if route then
    print(string.format("[example.province_map] route 1 -> 2 = [%s] (hops=%d)",
        table.concat(route, "->"), #route - 1))
else
    print("[example.province_map] no route between 1 and 2")
end
print(string.format("[example.province_map] BFS distance(1,2)=%s",
    tostring(map:distance(1, 2))))

-- ── 6. Faction-aware queries ──────────────────────────────────────────────────
local red_owned = map:getProvincesByFaction("red")
table.sort(red_owned)
print(string.format("[example.province_map] red faction owns ids=[%s] gold_total=%d",
    table.concat(red_owned, ","),
    map:totalResourceForFaction("red", "gold")))

-- ── 7. Map mode: colour each province by a fixed lookup ───────────────────────
local fixed_colors = {
    [1] = { 255, 0,   0   },
    [2] = { 0,   255, 0   },
    [3] = { 0,   0,   255 },
    [4] = { 255, 255, 0   },
}
local mode = M.newMapMode("political", M.newFixedColorFn(fixed_colors))
local resolved = M.resolveProvinceColors(map, mode)
print(string.format("[example.province_map] resolved %d province colours under '%s' mode",
    #map:provinceIds(), mode.name))
local _ = resolved  -- caller would render these

print("[example.province_map] done.")
