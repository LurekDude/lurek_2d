-- examples/raycaster.lua
-- lurek.raycaster — DDA-based grid raycasting for retro FPS and dungeon-crawler games.
-- Cast rays through a cell grid, project wall columns, check line of sight.
-- All lurek.raycaster API methods and utilities demonstrated with code and comments.

-- ── Creating the Raycaster ────────────────────────────────────────────────────

local new = lurek.raycaster.new(w, h)
-- w, h: grid dimensions in cells (e.g. 32×32 maze grid)
local MAP_W, MAP_H = 32, 32
local rc = lurek.raycaster.new(MAP_W, MAP_H)

-- ── Populating the Cell Grid ──────────────────────────────────────────────────

-- setCell(x, y, val)  — set a single cell; 0 = empty, 1+ = wall/type
rc:setCell(0, 0, 1)    -- wall
rc:setCell(5, 3, 2)    -- wall type 2 (different texture)

-- setCells(table)  — bulk-load all cells from a flat row-major table (length = w*h)
local flat_map = {}
for i = 1, MAP_W * MAP_H do flat_map[i] = 0 end
-- border walls
for x = 0, MAP_W - 1 do
    flat_map[0 * MAP_W + x + 1] = 1
    flat_map[(MAP_H - 1) * MAP_W + x + 1] = 1
end
for y = 0, MAP_H - 1 do
    flat_map[y * MAP_W + 0 + 1] = 1
    flat_map[y * MAP_W + (MAP_W - 1) + 1] = 1
end
rc:setCells(flat_map)

-- getCell(x, y) → integer
local val = rc:getCell(5, 3)   -- 2

-- isBlocked(x, y) → boolean  — true if cell value > 0
local blocked = rc:isBlocked(0, 0)   -- true

-- width() / height() → integer
local gw = rc:width()    -- 32
local gh = rc:height()   -- 32

-- ── Casting a Single Ray ──────────────────────────────────────────────────────

-- castRay(ox, oy, angle, max_dist) → hit_table | nil
-- ox, oy:    player position in world coords (1 unit = 1 grid cell)
-- angle:     direction in radians (0 = east +X)
-- max_dist:  stop after this many grid units
-- Returns nil if the ray travels max_dist without hitting a wall.

local hit = rc:castRay(16.5, 16.5, 0.0, 16.0)
if hit then
    -- hit.distance    — perp-corrected wall distance (use for column height)
    -- hit.raw_distance — true Euclidean distance
    -- hit.cell_value  — value of the hit cell (wall type, texture index)
    -- hit.side        — 0 = X-side wall, 1 = Y-side wall
    -- hit.tex_u       — texture UV coordinate [0, 1] along the wall face
    -- hit.hit_x       — world X of intersection
    -- hit.hit_y       — world Y of intersection
    -- hit.hit         — true when a wall was actually hit
    print(("Hit wall type %d at distance %.2f (u=%.3f)")
        :format(hit.cell_value, hit.distance, hit.tex_u))
end

-- ── Casting All Rays for a Frame ──────────────────────────────────────────────

-- castRays(ox, oy, angle, fov, count, max_dist) → table of hit tables
-- angle: camera centre angle | fov: horizontal field-of-view in radians
-- count: number of screen columns

local SCREEN_W = 320
local hits = rc:castRays(16.5, 16.5, 0.0, math.pi / 2, SCREEN_W, 20.0)

-- castRaysFlat(…) → flat table  — 5 floats per column, no sub-tables
-- Layout per column: [distance, raw_distance, cell_value(as float), side, tex_u]
-- Faster than castRays when you don't need a per-ray table object.

local flat = rc:castRaysFlat(16.5, 16.5, 0.0, math.pi / 2, SCREEN_W, 20.0)
for col = 0, SCREEN_W - 1 do
    local base     = col * 5 + 1
    local dist     = flat[base]
    local raw      = flat[base + 1]
    local cell_val = flat[base + 2]
    local side     = flat[base + 3]
    local tex_u    = flat[base + 4]
    -- ... render column col at screen position ...
end

-- ── Projecting Wall Columns ───────────────────────────────────────────────────

-- projectColumn(distance, fov, screen_height) → top, column_height, bottom
-- top:    screen Y of the column top
-- column_height: number of pixels the column should span
-- bottom: screen Y of the column bottom

local SCREEN_H = 240
local fov = math.pi / 2

for col = 1, SCREEN_W do
    local h = hits[col]
    if h and h.hit then
        local top, col_h, bottom = lurek.raycaster.projectColumn(h.distance, fov, SCREEN_H)
        -- draw textured vertical stripe at screen column (col-1)
lurek.gfx.draw(wall_tex, col-1, top, 0, 1, col_h / wall_h, h.tex_u, 0, 1, 1)
    end
end

-- ── Distance Shading ─────────────────────────────────────────────────────────

-- distanceShade(distance, max_distance) → number  — brightness [0, 1]
-- Use as a tint multiplier so far walls appear darker.

local max_dist = 20.0
for col = 1, SCREEN_W do
    local h = hits[col]
    if h and h.hit then
        local brightness = lurek.raycaster.distanceShade(h.distance, max_dist)
lurek.gfx.setColor(brightness, brightness, brightness)
    end
end

-- ── Line of Sight ────────────────────────────────────────────────────────────

-- lineOfSight(x1, y1, x2, y2) → boolean
-- Uses DDA traversal; returns false if any cell along the line is blocked.
local can_see = rc:lineOfSight(16.5, 16.5, 20.0, 10.0)
if not can_see then
    -- enemy is hidden behind a wall
end

-- ── Sprite Projection ────────────────────────────────────────────────────────

-- projectSprite(sx, sy, px, py, pa, fov, screen_w) → {screen_x, scale, distance, visible}
-- sx, sy: sprite world position
-- px, py: player world position
-- pa:     player angle (radians)
-- fov:    horizontal field of view (radians)
-- screen_w: render width in pixels

local sprite_pos = { x = 19.5, y = 16.5 }
local player_angle = 0.0
local sp = rc:projectSprite(sprite_pos.x, sprite_pos.y, 16.5, 16.5, player_angle, fov, SCREEN_W)
if sp.visible then
    -- sp.screen_x  — horizontal pixel position of the sprite centre
    -- sp.scale     — height scale factor (1.0 = full-height sprite at dist=1)
    -- sp.distance  — corrected depth for depth sorting
    local sprite_h = SCREEN_H * sp.scale
    local draw_x   = sp.screen_x - sprite_h / 2
    local draw_y   = (SCREEN_H - sprite_h) / 2
lurek.gfx.draw(sprite_img, draw_x, draw_y, 0, sp.scale, sp.scale)
end

-- ── Minimal FPS-Style Game Loop ───────────────────────────────────────────────

--[[
local rc, player = nil, { x=16.5, y=16.5, angle=0 }
local SPEED, TURN = 2.5, 2.0

function lurek.init()
    rc = lurek.raycaster.new(MAP_W, MAP_H)
    rc:setCells(flat_map)
end

function lurek.process(dt)
    local dx = math.cos(player.angle) * SPEED * dt
    local dy = math.sin(player.angle) * SPEED * dt
    if lurek.keyboard.isDown("w") and not rc:isBlocked(math.floor(player.x+dx), math.floor(player.y)) then player.x = player.x + dx end
    if lurek.keyboard.isDown("s") and not rc:isBlocked(math.floor(player.x-dx), math.floor(player.y)) then player.x = player.x - dx end
    if lurek.keyboard.isDown("a") then player.angle = player.angle - TURN * dt end
    if lurek.keyboard.isDown("d") then player.angle = player.angle + TURN * dt end
end

function lurek.render()
    local hits_frame = rc:castRays(player.x, player.y, player.angle, math.pi/2, SCREEN_W, 20)
    for col = 1, SCREEN_W do
        local h = hits_frame[col]
        if h and h.hit then
            local top, col_h, _ = lurek.raycaster.projectColumn(h.distance, math.pi/2, SCREEN_H)
            local brightness = lurek.raycaster.distanceShade(h.distance, 20)
            lurek.gfx.setColor(brightness, brightness * 0.5, 0)   -- brownish
            lurek.gfx.rectangle("fill", col-1, top, 1, col_h)
        end
    end
end
]]
