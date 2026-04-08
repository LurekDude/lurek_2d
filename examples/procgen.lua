-- examples/procgen.lua
-- luna.procgen — Stateless procedural generation utilities.
-- Cave maps, flood fill, Perlin noise, Poisson-disk sampling, Voronoi diagrams.
-- All luna.procgen API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Cellular Automata ─────────────────────────────────────────────────────────

-- cellularAutomata(w, h, opts?) → table  — flat (w×h) byte grid of 0/1 values
-- The returned table is 1-based, length = w * h.
-- opts keys:
--   fill       (0.0–1.0, default 0.45) — initial fill probability
--   iterations (integer,  default 5)   — smoothing passes
--   birth      (integer,  default 5)   — neighbour count to birth a cell
--   survive    (integer,  default 4)   — neighbour count for cell to survive
--   seed       (integer,  default 0)   — RNG seed; 0 = random

local W, H = 80, 50
local cave_map = luna.procgen.cellularAutomata(W, H, {
    fill       = 0.45,
    iterations = 5,
    birth      = 5,
    survive    = 4,
    seed       = 12345,
})

-- Read a specific cell value (1-based index = y * W + x + 1)
local function get_cell(data, width, x, y)
    return data[y * width + x + 1]   -- 0 = empty, 1 = wall
end

for y = 0, H - 1 do
    for x = 0, W - 1 do
        local is_wall = get_cell(cave_map, W, x, y)
        -- use is_wall to build tile map or collision data
    end
end

-- ── Flood Fill ────────────────────────────────────────────────────────────────

-- floodFill(data, w, h, sx, sy, threshold?, above?) → table
-- Returns a boolean array (1 = reachable) from start (sx, sy).
-- threshold: byte value cutoff (default 128).
-- above:     if true, fill cells ABOVE threshold; if false, fill cells BELOW.

local reachable = luna.procgen.floodFill(cave_map, W, H, 40, 25, 128, false)
-- reachable[i] == 1 if cell i can be reached from (40, 25) without crossing walls

-- Count reachable floor cells
local floor_count = 0
for _, v in ipairs(reachable) do
    if v == 1 then floor_count = floor_count + 1 end
end

-- ── Perlin Noise ──────────────────────────────────────────────────────────────

-- perlinNoise(x, y, px, py) → number
-- Evaluates periodic Perlin noise at (x, y) with period (px, py).
-- Returns a value roughly in [-1, 1].
-- Use tiling periods for seamlessly tiling noise (e.g. heightmaps).

local elevation = {}
for y = 0, 63 do
    for x = 0, 63 do
        -- octave stack for fBm-style noise
        local n = 0
        n = n + 1.0 * luna.procgen.perlinNoise(x * 0.05, y * 0.05, 64 * 0.05, 64 * 0.05)
        n = n + 0.5 * luna.procgen.perlinNoise(x * 0.10, y * 0.10, 64 * 0.10, 64 * 0.10)
        n = n + 0.25 * luna.procgen.perlinNoise(x * 0.20, y * 0.20, 64 * 0.20, 64 * 0.20)
        n = (n / 1.75 + 1) * 0.5   -- normalize to [0,1]
        elevation[y * 64 + x + 1] = n
    end
end

-- ── Poisson-Disk Sampling ─────────────────────────────────────────────────────

-- poissonDisk(w, h, min_dist, max_attempts?, seed?) → table of {x, y}
-- Generates well-separated random points across a (w × h) area.
-- min_dist:     minimum distance between any two points.
-- max_attempts: candidate attempts per active point (default 30; higher = denser packing).
-- seed:         RNG seed (0 = random).

local map_w, map_h = 800.0, 600.0
local tree_points = luna.procgen.poissonDisk(map_w, map_h, 64.0, 30, 42)

for _, pt in ipairs(tree_points) do
    local x, y = pt.x, pt.y
    -- spawn a tree at world position (x, y)
end

print("Placed " .. #tree_points .. " trees via Poisson-disk sampling")

-- ── Voronoi Diagram ───────────────────────────────────────────────────────────

-- voronoi(w, h, pts, opts?) → regions_table, distances_table, distances2_table
-- pts:   array of {x, y} seed point tables (world coords in [0, w) × [0, h)).
-- opts keys:
--   warp_scale    — spatial distortion frequency (0 = none)
--   warp_strength — spatial distortion amplitude (0 = none)
--   seed          — RNG seed for warp
-- Returns three flat tables (length = w * h):
--   regions   — 1-based seed index of the closest seed per cell
--   distances — distance to the closest seed per cell (F1)
--   distances2 — distance to the second-closest seed per cell (F2)

local seeds = {
    { x = 100, y = 100 },
    { x = 300, y = 200 },
    { x = 200, y = 350 },
    { x = 500, y = 150 },
    { x = 450, y = 400 },
}

local regions, dist1, dist2 = luna.procgen.voronoi(W, H, seeds, {
    warp_scale    = 0.1,
    warp_strength = 20.0,
    seed          = 7,
})

-- Colour each cell by its region index
for i = 1, W * H do
    local region_id = regions[i]    -- 1 = seed1, 2 = seed2, ...
    local d1 = dist1[i]             -- distance to closest seed
    local d2 = dist2[i]             -- distance to second-closest seed
    local border = (d2 - d1) < 8   -- true = near a Voronoi edge
end

-- ── Combining Techniques ─────────────────────────────────────────────────────

--[[
-- Example: heightmap island with Poisson tree placement

local function make_island(gw, gh, seed)
    -- 1. elevation via layered Perlin
    local height = {}
    for y = 0, gh-1 do
        for x = 0, gw-1 do
            local n = luna.procgen.perlinNoise(x*0.04, y*0.04, gw*0.04, gh*0.04)
                    + 0.5 * luna.procgen.perlinNoise(x*0.08, y*0.08, gw*0.08, gh*0.08)
            local h = (n / 1.5 + 1) * 0.5
            -- fade edges to ocean
            local fx = (x/gw - 0.5) * 2
            local fy = (y/gh - 0.5) * 2
            h = h - (fx*fx + fy*fy)
            height[y*gw + x + 1] = h
        end
    end

    -- 2. classify tiles
    local tiles = {}
    for i, h in ipairs(height) do
        if h < 0   then tiles[i] = "ocean"
        elseif h < 0.15 then tiles[i] = "sand"
        elseif h < 0.50 then tiles[i] = "grass"
        else tiles[i] = "mountain" end
    end

    -- 3. flood-fill to separate largest landmass
    -- (convert to byte grid: 0=ocean, 1=land)
    local landmask = {}
    for i, t in ipairs(tiles) do landmask[i] = (t ~= "ocean") and 1 or 0 end
    local reach = luna.procgen.floodFill(landmask, gw, gh, gw//2, gh//2, 1, true)

    -- 4. Poisson trees on grass cells only
    local trees = luna.procgen.poissonDisk(gw, gh, 4.0, 20, seed)
    local final_trees = {}
    for _, pt in ipairs(trees) do
        local ix = math.floor(pt.x)
        local iy = math.floor(pt.y)
        local idx = iy*gw + ix + 1
        if tiles[idx] == "grass" and reach[idx] == 1 then
            final_trees[#final_trees+1] = pt
        end
    end

    return tiles, final_trees
end
]]
