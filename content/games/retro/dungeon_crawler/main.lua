-- Dungeon Crawler (retro): textured raycaster showcase with dynamic lights.

local STATE = { PLAYING = 1, COMPLETE = 2 }

local VIEW_X = 0
local VIEW_Y = 0
local VIEW_W = 560
local VIEW_H = 560

local PANEL_X = 575
local PANEL_Y = 20

local FOV = math.rad(66)
local RAY_COUNT = VIEW_W
local MAX_DIST = 30.0

local MAP_W = 80
local MAP_H = 80

local MOVE_STEP = 1
local TURN_STEP = math.rad(90)
local MOVE_REPEAT = 0.14
local TURN_REPEAT = 0.18

local REVEAL_RAYS = 120
local REVEAL_DIST = 17.0

local TIME_MODE = 1  -- 1=DAY, 2=DUSK, 3=NIGHT

local function mode_name()
    if TIME_MODE == 1 then return "DAY"
    elseif TIME_MODE == 2 then return "DUSK"
    else return "NIGHT" end
end

local function mode_ambient()
    if TIME_MODE == 1 then return 0.90 end      -- day: 90% full brightness
    if TIME_MODE == 2 then return 0.375 end     -- dusk/dawn: 25% darker than 0.50
    return 0.05                                  -- night: 50% darker than 0.10
end

local function mode_sky_color()
    if TIME_MODE == 1 then return 0.82, 0.92, 1.00 end   -- day: light blue
    if TIME_MODE == 2 then return 1.00, 0.68, 0.40 end   -- dusk: warm orange
    return 0.05, 0.08, 0.20                              -- night: deep blue
end

-- Crouch (Ctrl key)
local crouching = false
local CAMERA_STAND_HEIGHT = 2.0 / 3.0
local CAMERA_CROUCH_HEIGHT = 1.0 / 3.0
-- Render camera sits in the back part of the tile to ensure the current tile is
-- visible under the player before the X+1 tile starts.
local CAMERA_BACK_OFFSET = 0.22

local WALL_TEXTURE_FILES = {
    [1] = "assets/textures/wall_stone_64.png",
    [2] = "assets/textures/wall_cobble_64.png",
    [3] = "assets/textures/wall_grass_64.png",
    [4] = "assets/textures/floor_dirt_64.png",
    [5] = "assets/textures/floor_sand_64.png",
    [6] = "assets/textures/wall_wood_64.png",
}

local WALL_COLORS = {
    [1] = { 0.52, 0.52, 0.55 },
    [2] = { 0.42, 0.40, 0.38 },
    [3] = { 0.27, 0.52, 0.30 },
    [4] = { 0.42, 0.31, 0.20 },
    [5] = { 0.68, 0.60, 0.44 },
    [6] = { 0.63, 0.49, 0.34 },
}

local floor_type = {}
local ceiling_type = {}
local liquid_type = {}

local state = STATE.PLAYING
local score = 0

local dungeon = {}
local explored = {}

local wall_textures = {}
local special_textures = {}
local world_models = {}
local sectoid_model = nil
local raycaster = nil

local player = {
    x = 8.5, y = 30.5,
    angle = 0.0, dir = 1,
    torch = true,
}

local move_cd = 0.0
local turn_cd = 0.0

local DIRS = { {1,0}, {0,1}, {-1,0}, {0,-1} }

local torches = {
    -- intensity in [3..8] for 1..16 scale; active in all modes
    { x=7,  y=7,  radius=4.0, r=1.00, g=0.60, b=0.20, intensity=5.0 },
    { x=18, y=8,  radius=6.0, r=0.85, g=0.95, b=1.00, intensity=8.0 },
    { x=30, y=7,  radius=4.0, r=1.00, g=0.52, b=0.12, intensity=4.0 },
    { x=47, y=8,  radius=5.0, r=0.72, g=0.88, b=1.00, intensity=6.0 },
    { x=10, y=18, radius=4.0, r=1.00, g=0.56, b=0.16, intensity=4.0 },
    { x=22, y=18, radius=7.0, r=1.00, g=0.82, b=0.62, intensity=8.0 },
    { x=36, y=16, radius=5.0, r=0.82, g=1.00, b=0.82, intensity=6.0 },
    { x=48, y=18, radius=3.0, r=1.00, g=0.48, b=0.10, intensity=3.0 },
    { x=8,  y=34, radius=5.0, r=1.00, g=0.60, b=0.20, intensity=6.0 },
    { x=19, y=36, radius=4.0, r=0.95, g=1.00, b=0.80, intensity=5.0 },
    { x=31, y=35, radius=7.0, r=0.65, g=0.85, b=1.00, intensity=8.0 },
    { x=45, y=36, radius=5.0, r=1.00, g=0.62, b=0.25, intensity=6.0 },
    { x=52, y=30, radius=3.0, r=1.00, g=0.55, b=0.18, intensity=3.0 },
    { x=27, y=27, radius=6.0, r=1.00, g=0.72, b=0.44, intensity=7.0 },
    { x=40, y=44, radius=4.0, r=0.70, g=0.90, b=1.00, intensity=5.0 },
    { x=12, y=47, radius=6.0, r=0.95, g=0.80, b=0.60, intensity=7.0 },
    { x=50, y=46, radius=5.0, r=0.78, g=0.92, b=1.00, intensity=6.0 },
    { x=6,  y=25, radius=4.0, r=1.00, g=0.50, b=0.14, intensity=4.0 },
    { x=43, y=25, radius=6.0, r=0.92, g=1.00, b=0.78, intensity=8.0 },
}

local orbs = {
    { x=6.5,  y=7.5,  collected=false },
    { x=14.5, y=4.5,  collected=false },
    { x=21.5, y=8.5,  collected=false },
    { x=28.5, y=7.5,  collected=false },
    { x=31.5, y=15.5, collected=false },
    { x=26.5, y=22.5, collected=false },
    { x=18.5, y=27.5, collected=false },
    { x=10.5, y=24.5, collected=false },
    { x=6.5,  y=18.5, collected=false },
    { x=29.5, y=29.5, collected=false },
}
local total_orbs = #orbs

local function new_grid(w, h, fill)
    local g = {}
    for y = 1, h do
        g[y] = {}
        for x = 1, w do g[y][x] = fill end
    end
    return g
end

local function carve_rect_floor(x0, y0, x1, y1, ft)
    for y = y0, y1 do
        for x = x0, x1 do
            if x >= 2 and y >= 2 and x <= MAP_W-1 and y <= MAP_H-1 then
                if dungeon[y][x] == 0 then
                    floor_type[y][x] = ft
                end
            end
        end
    end
end

local function carve_rect_ceiling(x0, y0, x1, y1, ct)
    for y = y0, y1 do
        for x = x0, x1 do
            if x >= 2 and y >= 2 and x <= MAP_W-1 and y <= MAP_H-1 then
                if dungeon[y][x] == 0 then
                    ceiling_type[y][x] = ct
                end
            end
        end
    end
end

local function build_dungeon()
    -- Larger map with roads, forests, river, roofed houses, and visible lava.
    dungeon = new_grid(MAP_W, MAP_H, 0)
    floor_type = new_grid(MAP_W, MAP_H, 4)   -- 4 grass fallback
    ceiling_type = new_grid(MAP_W, MAP_H, 0) -- 0 open sky
    liquid_type = new_grid(MAP_W, MAP_H, 0)  -- 0 none, 1 water, 2 lava

    -- Outer border
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            if x == 1 or y == 1 or x == MAP_W or y == MAP_H then dungeon[y][x] = 2 end
        end
    end

    -- Main roads
    for y = 2, MAP_H - 1 do
        for x = 38, 41 do floor_type[y][x] = 1 end
    end
    for x = 2, MAP_W - 1 do
        for y = 38, 41 do floor_type[y][x] = 1 end
    end
    for y = 8, 72 do
        for x = 10, 12 do floor_type[y][x] = 1 end
    end

    -- Field zones
    carve_rect_floor(3, 3, 34, 34, 2)
    carve_rect_floor(45, 3, 78, 34, 3)
    carve_rect_floor(3, 45, 34, 78, 5)
    carve_rect_floor(45, 45, 78, 78, 6)

    -- Forest blocks (tree trunks/bush walls)
    for y = 6, 32, 2 do
        for x = 4, 30, 2 do
            if (x + y) % 3 ~= 0 then dungeon[y][x] = 4 end
        end
    end
    for y = 50, 76, 2 do
        for x = 52, 76, 2 do
            if (x + y) % 4 ~= 1 then dungeon[y][x] = 4 end
        end
    end

    -- River: meandering north->south band in the east half.
    for y = 4, 76 do
        local cx = 58 + math.floor(math.sin(y * 0.16) * 5)
        for dx = -1, 1 do
            local x = cx + dx
            if x >= 2 and x <= MAP_W - 1 and dungeon[y][x] == 0 then
                liquid_type[y][x] = 1
                floor_type[y][x] = 4
            end
        end
        -- sandy banks
        for dx = -2, 2 do
            local x = cx + dx
            if x >= 2 and x <= MAP_W - 1 and dungeon[y][x] == 0 and liquid_type[y][x] == 0 then
                floor_type[y][x] = 5
            end
        end
    end

    -- Roofed house helper.
    local function make_house(x0, y0, x1, y1, wall_t, floor_t, roof_t)
        for y = y0, y1 do
            for x = x0, x1 do
                local border = (x == x0 or x == x1 or y == y0 or y == y1)
                ceiling_type[y][x] = roof_t
                if border then
                    dungeon[y][x] = wall_t
                else
                    dungeon[y][x] = 0
                    floor_type[y][x] = floor_t
                end
            end
        end
        local door_x = math.floor((x0 + x1) * 0.5)
        dungeon[y1][door_x] = 0
        floor_type[y1][door_x] = floor_t
    end

    make_house(18, 20, 28, 30, 6, 5, 6)
    make_house(48, 18, 60, 30, 1, 5, 1)
    make_house(20, 52, 34, 66, 6, 1, 6)

    -- Lava pool placed in OPEN area near the central road (visible and reachable by sight).
    for y = 46, 50 do
        for x = 22, 28 do
            if dungeon[y][x] == 0 then
                liquid_type[y][x] = 2
                floor_type[y][x] = 1
            end
        end
    end

    -- Keep spawn zone open on west road.
    for y = 39, 42 do
        for x = 6, 14 do
            dungeon[y][x] = 0
            floor_type[y][x] = 1
            liquid_type[y][x] = 0
        end
    end

    player.x, player.y = 8.5, 40.5
end

local function reset_explored()
    explored = new_grid(MAP_W, MAP_H, false)
end

local function is_blocked(wx, wy)
    local gx = math.floor(wx)+1
    local gy = math.floor(wy)+1
    if gx<1 or gy<1 or gx>MAP_W or gy>MAP_H then return true end
    if raycaster then return raycaster:isWalkBlocked(gx-1, gy-1) end
    return dungeon[gy][gx] > 0
end

local function try_step(dx, dy)
    local tx = player.x+dx
    local ty = player.y+dy
    if not is_blocked(tx, ty) then player.x=tx; player.y=ty end
end

local function sync_angle_from_dir()
    player.angle = (player.dir-1) * TURN_STEP
end

local function do_forward_step(sign)
    if raycaster and raycaster.gridMove then
        local action = sign > 0 and "forward" or "back"
        local nx, ny, moved = raycaster:gridMove(player.x, player.y, player.dir, action, MOVE_STEP)
        if moved then
            player.x, player.y = nx, ny
        end
        return
    end
    local d = DIRS[player.dir]
    try_step(d[1] * MOVE_STEP * sign, d[2] * MOVE_STEP * sign)
end

local function do_strafe_step(sign)
    if raycaster and raycaster.gridMove then
        local action = sign > 0 and "left" or "right"
        local nx, ny, moved = raycaster:gridMove(player.x, player.y, player.dir, action, MOVE_STEP)
        if moved then
            player.x, player.y = nx, ny
        end
        return
    end
    local d = DIRS[player.dir]
    try_step(d[2] * MOVE_STEP * sign, -d[1] * MOVE_STEP * sign)
end

local function reveal_cell(wx, wy)
    local gx=math.floor(wx)+1
    local gy=math.floor(wy)+1
    if gx>=1 and gy>=1 and gx<=MAP_W and gy<=MAP_H then explored[gy][gx]=true end
end

local function reveal_from_rays()
    if not raycaster then return end
    if raycaster.revealCellsFromRays then
        local cells = raycaster:revealCellsFromRays(
            player.x,
            player.y,
            player.angle,
            FOV,
            REVEAL_RAYS,
            REVEAL_DIST,
            0.2
        )
        for _, cell in ipairs(cells) do
            local gx = (cell.x or -1) + 1
            local gy = (cell.y or -1) + 1
            if gx >= 1 and gy >= 1 and gx <= MAP_W and gy <= MAP_H then
                explored[gy][gx] = true
            end
        end
    else
        reveal_cell(player.x, player.y)
        local rays = raycaster:castRays(player.x, player.y, player.angle, FOV, REVEAL_RAYS, REVEAL_DIST)
        for _, hit in ipairs(rays) do
            local hx = hit.hit_x or (player.x + math.cos(player.angle)*REVEAL_DIST)
            local hy = hit.hit_y or (player.y + math.sin(player.angle)*REVEAL_DIST)
            local dx, dy = hx-player.x, hy-player.y
            local steps = math.max(1, math.floor(math.sqrt(dx*dx+dy*dy)/0.2))
            for s = 0, steps do
                local t = s/steps
                reveal_cell(player.x+dx*t, player.y+dy*t)
            end
        end
    end
end

local function load_textures()
    wall_textures = {}
    for id, path in pairs(WALL_TEXTURE_FILES) do
        wall_textures[id] = lurek.render.newImage(path)
    end
    special_textures.water = lurek.render.newImage("assets/textures/ray_water.png")
    special_textures.lava = lurek.render.newImage("assets/textures/ray_lava.png")
end

local function build_random_model_instances()
    world_models = {}
    local ok, mdl = pcall(lurek.render.loadModel, "assets/models/sectoid.obj")
    if not ok or not mdl then return end
    sectoid_model = mdl

    math.randomseed(1337)
    local candidates = {}
    for y = 3, MAP_H - 2 do
        for x = 3, MAP_W - 2 do
            if dungeon[y][x] == 0 and liquid_type[y][x] == 0 then
                local dx = (x + 0.5) - player.x
                local dy = (y + 0.5) - player.y
                if dx * dx + dy * dy > 64 then
                    candidates[#candidates + 1] = { x = x, y = y }
                end
            end
        end
    end
    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local count = math.min(6, #candidates)
    for i = 1, count do
        local cell = candidates[i]
        world_models[#world_models + 1] = {
            x = cell.x - 0.5,
            y = cell.y - 0.5,
            model = sectoid_model,
            rotation = ((i - 1) % 4),
            scale = 0.42,
        }
    end
end

local function apply_map_to_raycaster()
    raycaster = lurek.raycaster.new(MAP_W, MAP_H)
    for y = 1, MAP_H do
        for x = 1, MAP_W do raycaster:setCell(x-1, y-1, dungeon[y][x]) end
    end
    for y = 0, MAP_H-1 do
        for x = 0, MAP_W-1 do
            local ft = floor_type[y+1][x+1]
            if ft == 1 then
                -- road dirt
                raycaster:setFloorTextureCell(x, y, wall_textures[4])
            elseif ft == 2 then
                -- plowed dark field
                raycaster:setFloorTextureCell(x, y, wall_textures[2])
            elseif ft == 3 then
                -- dry stubble field
                raycaster:setFloorTextureCell(x, y, wall_textures[5])
            elseif ft == 4 then
                -- grass
                raycaster:setFloorTextureCell(x, y, wall_textures[3])
            elseif ft == 5 then
                -- muddy yard / barn interior
                raycaster:setFloorTextureCell(x, y, wall_textures[1])
            elseif ft == 6 then
                -- straw area
                raycaster:setFloorTextureCell(x, y, wall_textures[6])
            end

                local ct = ceiling_type[y+1][x+1]
                if ct >= 1 and ct <= 6 then
                    raycaster:setCeilingTextureCell(x, y, wall_textures[ct])
                else
                    raycaster:setCeilingTextureCell(x, y, nil)
                end

            local lt = liquid_type[y+1][x+1]
            if lt == 1 then
                raycaster:setLoweredFloorCell(x, y, {
                    texture = special_textures.water,
                    depth = 0.25,
                    r = 0.72, g = 0.88, b = 1.0,
                    blocked = true,
                })
            elseif lt == 2 then
                raycaster:setLoweredFloorCell(x, y, {
                    texture = special_textures.lava,
                    depth = 0.25,
                    r = 1.0, g = 0.62, b = 0.22,
                    blocked = true,
                })
            else
                raycaster:setLoweredFloorCell(x, y, nil)
            end
        end
    end
end

local function collect_orbs()
    local all = true
    for _, orb in ipairs(orbs) do
        if not orb.collected then
            local dx, dy = orb.x-player.x, orb.y-player.y
            if (dx*dx+dy*dy) < 0.35*0.35 then
                orb.collected=true; score=score+100
            else
                all=false
            end
        end
    end
    if all then state=STATE.COMPLETE end
end

local function build_light_list()
    local lights = {}
    -- Player torch toggle T
    if player.torch then
        -- Player light on 1..16 scale: requested power 8.
        lights[#lights+1] = {
            x=player.x, y=player.y,
            radius=7.0, r=1.0, g=0.88, b=0.66, intensity=8.0,
        }
    end
    -- Map lights are active in all modes.
    for _, t in ipairs(torches) do
        lights[#lights+1] = {
            x=t.x+0.5, y=t.y+0.5,
            radius=t.radius, r=t.r, g=t.g, b=t.b, intensity=t.intensity,
        }
    end
    -- Orb glow: almost off in night.
    local orb_intensity = (TIME_MODE == 1) and 2.0 or ((TIME_MODE == 2) and 1.2 or 0.25)
    for _, orb in ipairs(orbs) do
        if not orb.collected then
            lights[#lights+1] = {
                x=orb.x, y=orb.y,
                radius=2.0, r=0.30, g=0.70, b=1.0, intensity=orb_intensity,
            }
        end
    end
    -- Liquids: lava glows, water does not.
        for y = 1, MAP_H do
            for x = 1, MAP_W do
                local lt = liquid_type[y][x]
                if lt == 2 then
                    lights[#lights+1] = {
                        x=x-0.5, y=y-0.5,
                        radius=5.0, r=1.00, g=0.48, b=0.10, intensity=8.0,
                    }
                end
            end
        end
    return lights
end

local function wall_texture_map()
    return {
        [1]=wall_textures[1], [2]=wall_textures[2],
        [3]=wall_textures[3], [4]=wall_textures[4],
        [5]=wall_textures[5], [6]=wall_textures[6],
    }
end

local function build_world_sprites()
    if not wall_textures[6] then return {} end
    local candidates = {
        { x = 24.5, y = 24.5, texture = wall_textures[6], size = 0.9 },
        { x = 52.5, y = 22.5, texture = wall_textures[5], size = 1.0 },
        { x = 30.5, y = 58.5, texture = wall_textures[1], size = 1.1 },
    }
    -- Skip sprites placed over lava or water.
    local result = {}
    for _, s in ipairs(candidates) do
        local tx, ty = math.floor(s.x), math.floor(s.y)
        if liquid_type[ty] and liquid_type[ty][tx] == 0 then
            result[#result + 1] = s
        end
    end
    return result
end

local function build_world_models()
    return world_models
end

function lurek.init()
    lurek.window.setTitle("Dungeon Crawler")
    lurek.render.setBackgroundColor(0.03, 0.03, 0.04)
    lurek.input.bind("forward",    {"w","up"})
    lurek.input.bind("back",       {"s","down"})
    lurek.input.bind("left",       {"a"})
    lurek.input.bind("right",      {"d"})
    lurek.input.bind("turn_left",  {"q","left"})
    lurek.input.bind("turn_right", {"e","right"})
    lurek.input.bind("torch",      {"t"})
    lurek.input.bind("daynight",   {"n"})
    lurek.input.bind("crouch",     {"ctrl"})
    lurek.input.bind("quit",       {"escape"})
    build_dungeon()
    -- Remove orbs placed on lava or water (defensive: none currently overlap, but guard for future edits).
    do
        local filtered = {}
        for _, orb in ipairs(orbs) do
            local tx = math.floor(orb.x) + 1  -- convert to 1-indexed Lua map coord
            local ty = math.floor(orb.y) + 1
            if not (liquid_type[ty] and liquid_type[ty][tx] ~= 0) then
                filtered[#filtered + 1] = orb
            end
        end
        orbs = filtered
    end
    reset_explored()
    load_textures()
    build_random_model_instances()
    apply_map_to_raycaster()
    reveal_from_rays()
end

-- T / N are toggled here, NOT in process(), because wasActionPressed
-- is checked after begin_frame clears keys_pressed. keypressed fires
-- directly from the KeyboardInput OS event, so it always sees the press.
function lurek.keypressed(key, _sc, is_repeat)
    if is_repeat then return end
    if key == "t" then player.torch = not player.torch
    elseif key == "n" then TIME_MODE = (TIME_MODE % 3) + 1
    end
end

function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit(); return end
    -- Crouch (hold Ctrl)
    crouching = lurek.input.isActionDown("crouch")
    if state == STATE.COMPLETE then return end
    move_cd = math.max(0.0, move_cd-dt)
    turn_cd = math.max(0.0, turn_cd-dt)
    if turn_cd <= 0.0 then
        local tl = lurek.input.wasActionPressed("turn_left")  or lurek.input.isActionDown("turn_left")
        local tr = lurek.input.wasActionPressed("turn_right") or lurek.input.isActionDown("turn_right")
        if tl then
            player.dir = ((player.dir+2)%4)+1
            sync_angle_from_dir(); turn_cd=TURN_REPEAT
        elseif tr then
            player.dir = (player.dir%4)+1
            sync_angle_from_dir(); turn_cd=TURN_REPEAT
        end
    end
    if move_cd <= 0.0 then
        local fw = lurek.input.wasActionPressed("forward") or lurek.input.isActionDown("forward")
        local bk = lurek.input.wasActionPressed("back")    or lurek.input.isActionDown("back")
        local lf = lurek.input.wasActionPressed("left")    or lurek.input.isActionDown("left")
        local rt = lurek.input.wasActionPressed("right")   or lurek.input.isActionDown("right")
        if fw     then do_forward_step(1);  move_cd=MOVE_REPEAT
        elseif bk then do_forward_step(-1); move_cd=MOVE_REPEAT
        elseif lf then do_strafe_step(1);   move_cd=MOVE_REPEAT
        elseif rt then do_strafe_step(-1);  move_cd=MOVE_REPEAT
        end
    end
    collect_orbs()
    reveal_from_rays()
end

-- Sky gradient: 3 layers from top (dark) to horizon (bright)
-- DAY:   bright blue sky → very light blue at horizon
-- DUSK:  warm orange sky → golden at horizon
-- NIGHT: deep blue sky → very dark blue at horizon
local SKY_TOP = {
    [1] = {0.40, 0.52, 0.74},  -- day: deeper blue upper sky
    [2] = {0.30, 0.22, 0.32},  -- dusk: dark warm-violet upper sky
    [3] = {0.01, 0.02, 0.07},  -- night: near-black blue upper sky
}
local SKY_MID = {
    [1] = {0.57, 0.67, 0.84},  -- day: softer middle blue
    [2] = {0.74, 0.46, 0.29},  -- dusk: warm amber middle
    [3] = {0.03, 0.05, 0.11},  -- night: dark blue middle
}
local SKY_BOT = {
    [1] = {0.82, 0.88, 0.97},  -- day: bright hazy horizon
    [2] = {0.97, 0.66, 0.37},  -- dusk: orange horizon glow
    [3] = {0.05, 0.07, 0.14},  -- night: dim blue horizon
}

local function draw_sky_gradient(horizon_y)
    -- Smooth 3-color sky using gradient API (no hard seam lines).
    local top = SKY_TOP[TIME_MODE]
    local mid = SKY_MID[TIME_MODE]
    local bot = SKY_BOT[TIME_MODE]
    local split = math.floor(horizon_y * 0.58)
    lurek.render.drawGradientRect(0, 0, VIEW_W, split, {top[1], top[2], top[3], 1.0}, {mid[1], mid[2], mid[3], 1.0}, "vertical")
    lurek.render.drawGradientRect(0, split, VIEW_W, math.max(1, math.floor(horizon_y - split)), {mid[1], mid[2], mid[3], 1.0}, {bot[1], bot[2], bot[3], 1.0}, "vertical")
end

function lurek.draw()
    if raycaster then
        local ambient = mode_ambient()
        local sky_r, sky_g, sky_b = mode_sky_color()
        local camera_h = crouching and CAMERA_CROUCH_HEIGHT or CAMERA_STAND_HEIGHT
        local horizon_y = VIEW_H * 0.5

        -- Sky: gradient background behind raycaster ceiling.
        draw_sky_gradient(horizon_y)

        -- Camera is rendered slightly behind the player center within the same tile.
        local forward_x = math.cos(player.angle)
        local forward_y = math.sin(player.angle)
        local render_px = player.x - forward_x * CAMERA_BACK_OFFSET
        local render_py = player.y - forward_y * CAMERA_BACK_OFFSET

        raycaster:buildSceneWithModels({
            px=render_px, py=render_py,
            angle=player.angle,
            fov=FOV, rays=RAY_COUNT,
            max_dist=MAX_DIST,
            screen_w=VIEW_W, screen_h=VIEW_H,
            ambient=ambient, shade_dist=1000.0,
            camera_height=camera_h,
            floor_r=1.0, floor_g=1.0, floor_b=1.0,
            ceiling_r=sky_r, ceiling_g=sky_g, ceiling_b=sky_b,
            horizon_offset=0.0,
        }, build_light_list(), build_world_sprites(), wall_texture_map(), build_world_models())

        -- Draw shadows under OBJ models (dark blurred circles at horizon)
        for _, model in ipairs(world_models) do
            local dx = model.x - render_px
            local dy = model.y - render_py
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < MAX_DIST then
                -- Project model position to screen
                local angle_to_model = math.atan2(dy, dx)
                local angle_diff = angle_to_model - player.angle
                -- Normalize angle difference
                while angle_diff > math.pi do angle_diff = angle_diff - 2*math.pi end
                while angle_diff < -math.pi do angle_diff = angle_diff + 2*math.pi end

                if math.abs(angle_diff) < FOV / 2 then
                    local proj_x = VIEW_W * 0.5 + (math.tan(angle_diff) / math.tan(FOV/2)) * (VIEW_W * 0.5)
                    local shadow_size = math.max(2, 16 / dist)  -- Smaller shadow farther away

                    -- Draw blurred black circle shadow at horizon
                    lurek.render.setColor(0, 0, 0, 0.3)  -- Semi-transparent black
                    for r = shadow_size, 1, -1 do
                        local alpha = 0.3 * (1 - r / shadow_size)
                        lurek.render.setColor(0, 0, 0, alpha)
                        lurek.render.circle("fill", proj_x, horizon_y + shadow_size, r)
                    end
                end
            end
        end

        -- Mask the area below the gameplay viewport so geometry never bleeds under UI.
        lurek.render.setColor(0.07, 0.07, 0.10, 1.0)
        lurek.render.rectangle("fill", 0, VIEW_H, VIEW_W, 600 - VIEW_H)
    end
end

local function draw_minimap()
    -- Smaller cells = larger tactical coverage.
    local MM_X=PANEL_X; local MM_Y=PANEL_Y+176
    local MM_CELL=5; local MM_R=16
    local side=MM_R*2+1
    local mm_w=side*MM_CELL; local mm_h=side*MM_CELL
    local cgx=math.floor(player.x)+1
    local cgy=math.floor(player.y)+1

    local ambient = mode_ambient()
    local lights = build_light_list()
    local minimap_samples = {}
    if raycaster and raycaster.buildMinimapWindow then
        local samples = raycaster:buildMinimapWindow(player.x, player.y, MM_R, ambient, lights)
        for _, s in ipairs(samples) do
            minimap_samples[(s.x + 1) .. "," .. (s.y + 1)] = s
        end
    end

    local mm_bg
    if TIME_MODE == 1 then
        mm_bg = 0.10
    elseif TIME_MODE == 2 then
        mm_bg = 0.08
    else
        mm_bg = 0.03
    end
    lurek.render.setColor(mm_bg, mm_bg, mm_bg*1.25, 0.98)
    lurek.render.rectangle("fill", MM_X-2, MM_Y-2, mm_w+4, mm_h+4)

    for oy = -MM_R, MM_R do
        for ox = -MM_R, MM_R do
            local gx=cgx+ox; local gy=cgy+oy
            local sx=MM_X+(ox+MM_R)*MM_CELL
            local sy=MM_Y+(oy+MM_R)*MM_CELL
            if gx>=1 and gy>=1 and gx<=MAP_W and gy<=MAP_H then
                local v=dungeon[gy][gx]
                local sample = minimap_samples[gx .. "," .. gy]
                local ll = sample and sample.luma or ambient
                ll = math.max(0.05, math.min(1.0, ll))
                if v>0 then
                    -- Walls: bright block + border
                    local c=WALL_COLORS[v]
                    local wf = 0.55 + 0.45 * ll
                    lurek.render.setColor(c[1]*wf, c[2]*wf, c[3]*wf, 1.0)
                    lurek.render.rectangle("fill", sx, sy, MM_CELL-1, MM_CELL-1)
                    lurek.render.setColor(math.max(0.0, c[1]*wf*0.5), math.max(0.0, c[2]*wf*0.5), math.max(0.0, c[3]*wf*0.5), 1.0)
                    lurek.render.rectangle("line", sx, sy, MM_CELL-1, MM_CELL-1)
                else
                    -- Floors: darker block, no border
                    local ft=floor_type[gy][gx]
                    local br = 0.20 + 0.55 * ll
                    local lt = liquid_type[gy][gx]
                    if lt == 1 then
                        lurek.render.setColor(0.08 + 0.18*ll, 0.20 + 0.28*ll, 0.40 + 0.40*ll, 1.0)
                    elseif lt == 2 then
                        lurek.render.setColor(0.38 + 0.38*ll, 0.14 + 0.20*ll, 0.02 + 0.08*ll, 1.0)
                    elseif ft==1 then
                        lurek.render.setColor(0.26*br, 0.21*br, 0.14*br, 1.0)
                    elseif ft==2 then
                        lurek.render.setColor(0.24*br, 0.24*br, 0.27*br, 1.0)
                    elseif ft==3 then
                        lurek.render.setColor(0.34*br, 0.31*br, 0.18*br, 1.0)
                    elseif ft==4 then
                        lurek.render.setColor(0.16*br, 0.28*br, 0.14*br, 1.0)
                    elseif ft==5 then
                        lurek.render.setColor(0.20*br, 0.18*br, 0.16*br, 1.0)
                    else
                        lurek.render.setColor(0.35*br, 0.30*br, 0.20*br, 1.0)
                    end
                    lurek.render.rectangle("fill", sx, sy, MM_CELL-1, MM_CELL-1)
                end

                -- Orbs at exact sub-tile positions.
                for _, orb in ipairs(orbs) do
                    if not orb.collected and math.floor(orb.x)+1==gx and math.floor(orb.y)+1==gy then
                        local ox2=sx+(orb.x-math.floor(orb.x))*(MM_CELL-1)
                        local oy2=sy+(orb.y-math.floor(orb.y))*(MM_CELL-1)
                        lurek.render.setColor(0.95,0.85,0.2,1.0)
                        lurek.render.circle("fill", ox2, oy2, 1.5)
                    end
                end
            else
                lurek.render.setColor(0.05, 0.05, 0.06, 1.0)
                lurek.render.rectangle("fill", sx, sy, MM_CELL-1, MM_CELL-1)
            end
        end
    end

    -- Player dot: true sub-tile position.
    local px_mm = MM_X + MM_R*MM_CELL + (player.x - math.floor(player.x)) * MM_CELL
    local py_mm = MM_Y + MM_R*MM_CELL + (player.y - math.floor(player.y)) * MM_CELL
    lurek.render.setColor(0.2, 1.0, 0.35, 1.0)
    lurek.render.circle("fill", px_mm, py_mm, 2.3)
    lurek.render.setColor(1.0, 1.0, 0.3, 1.0)
    lurek.render.line(px_mm, py_mm, px_mm + math.cos(player.angle)*5, py_mm + math.sin(player.angle)*5)

    lurek.render.setColor(0.4, 0.4, 0.5, 1.0)
    lurek.render.rectangle("line", MM_X-2, MM_Y-2, mm_w+4, mm_h+4)
    local label_color
    if TIME_MODE == 1 then
        label_color = 0.75
    elseif TIME_MODE == 2 then
        label_color = 0.62
    else
        label_color = 0.50
    end
    lurek.render.setColor(label_color, label_color, label_color*1.08, 1.0)
    lurek.render.print("MINIMAP (TILE LIGHT)", MM_X, MM_Y+mm_h+8)
end

function lurek.draw_ui()
    lurek.render.setColor(0.08,0.08,0.12,0.92)
    lurek.render.rectangle("fill", PANEL_X-10, PANEL_Y-10, 225, 590)
    lurek.render.setColor(0.25,0.25,0.32,1.0)
    lurek.render.rectangle("line", PANEL_X-10, PANEL_Y-10, 225, 590)

    lurek.render.setColor(0.88,0.88,0.95,1.0)
    lurek.render.print("DUNGEON CRAWLER", PANEL_X, PANEL_Y)

    local collected=0
    for _, orb in ipairs(orbs) do if orb.collected then collected=collected+1 end end
    lurek.render.setColor(0.95,0.85,0.25,1.0)
    lurek.render.print("Score: "..score, PANEL_X, PANEL_Y+28)
    lurek.render.setColor(0.55,0.88,1.0,1.0)
    lurek.render.print("Orbs: "..collected.."/"..total_orbs, PANEL_X, PANEL_Y+50)
    lurek.render.setColor(0.7,0.7,0.78,1.0)
    lurek.render.print("WSAD move, Q/E turn", PANEL_X, PANEL_Y+70)
    lurek.render.print("T=torch  N=day/night", PANEL_X, PANEL_Y+86)
    lurek.render.print("Ctrl=crouch", PANEL_X, PANEL_Y+102)

    -- Torch status
    local tl = player.torch and "[ON]" or "[OFF]"
    if player.torch then lurek.render.setColor(1.0,0.75,0.2,1.0)
    else lurek.render.setColor(0.4,0.4,0.4,1.0) end
    lurek.render.print("Torch: "..tl, PANEL_X, PANEL_Y+120)

    -- Day/Night status
    local dn = "[" .. mode_name() .. "]"
    if TIME_MODE == 1 then
        lurek.render.setColor(1.0,0.95,0.5,1.0)
    elseif TIME_MODE == 2 then
        lurek.render.setColor(1.0,0.72,0.45,1.0)
    else
        lurek.render.setColor(0.4,0.5,0.9,1.0)
    end
    lurek.render.print("Mode: "..dn, PANEL_X, PANEL_Y+138)

    -- Crouch indicator
    if crouching then
        lurek.render.setColor(0.6,0.9,0.6,1.0)
        lurek.render.print("[CROUCH]", PANEL_X, PANEL_Y+156)
    end

    local facing=math.deg(player.angle)
    if facing < 0 then facing=facing+360 end
    lurek.render.setColor(0.7,0.7,0.78,1.0)
    lurek.render.print("Heading: "..string.format("%.0f",facing).." deg", PANEL_X, PANEL_Y+176)

    draw_minimap()

    if state==STATE.COMPLETE then
        lurek.render.setColor(1.0,0.92,0.3,1.0)
        lurek.render.print("ALL ORBS COLLECTED!", PANEL_X, 550)
    end
    lurek.render.setColor(0.45,0.45,0.5,1.0)
    lurek.render.print("FPS: "..lurek.timer.getFPS(), PANEL_X, 575)
end
