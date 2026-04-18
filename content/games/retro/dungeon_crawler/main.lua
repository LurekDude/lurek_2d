------------------------------------------------------------------------
-- Dungeon Crawler — Lurek2D
-- Category: retro
-- First-person grid-based dungeon crawler with raycasting pseudo-3D,
-- collectible orbs, torches, minimap, compass, and weather overlays.
------------------------------------------------------------------------

-- Action input bindings:
-- forward(w), back(s), turn_left(q), turn_right(e)
-- weather1(f1), weather2(f2), weather3(f3), quit(escape)

local STATE = { TITLE = 1, PLAYING = 2, COMPLETE = 3 }

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local VP_X, VP_Y = 10, 60
local VP_W, VP_H = 500, 480
local NUM_RAYS   = 200
local STRIP_W    = VP_W / NUM_RAYS
local FOV        = math.pi / 2
local HALF_FOV   = FOV / 2
local MAP_W, MAP_H = 12, 12
local MOVE_SPEED = 9.0

-- Wall colors: stone(1), brick(2), mossy(3), magic(4)
local WALL_COLORS = {
    { 0.55, 0.55, 0.55 },
    { 0.65, 0.30, 0.18 },
    { 0.28, 0.52, 0.30 },
    { 0.55, 0.20, 0.65 },
}

-- Direction tables (indexed dir+1: 1=N, 2=E, 3=S, 4=W)
local DIR_DX    = {  0,  1, 0, -1 }
local DIR_DY    = { -1,  0, 1,  0 }
local DIR_ANGLE = { -math.pi / 2, 0, math.pi / 2, math.pi }
local DIR_NAMES = { "N", "E", "S", "W" }

------------------------------------------------------------------------
-- Dungeon map 12x12 — 0=floor, 1=stone, 2=brick, 3=mossy, 4=magic
------------------------------------------------------------------------
local dungeon = {
    { 1,1,1,1,1,1,1,1,1,1,1,1 },
    { 1,0,0,0,2,0,0,0,0,0,0,1 },
    { 1,0,3,0,2,0,4,4,0,3,0,1 },
    { 1,0,3,0,0,0,0,4,0,3,0,1 },
    { 1,0,0,0,1,1,0,0,0,0,0,1 },
    { 1,2,2,0,0,1,0,3,3,0,2,1 },
    { 1,0,0,0,0,0,0,0,3,0,0,1 },
    { 1,0,4,0,1,0,1,0,0,0,0,1 },
    { 1,0,4,0,1,0,1,0,4,4,0,1 },
    { 1,0,0,0,0,0,0,0,0,4,0,1 },
    { 1,0,2,2,0,0,0,2,0,0,0,1 },
    { 1,1,1,1,1,1,1,1,1,1,1,1 },
}

------------------------------------------------------------------------
-- Torches and collectible orbs
------------------------------------------------------------------------
local torches = {
    { x = 2, y = 2 },  { x = 5, y = 2 },  { x = 9, y = 2 },
    { x = 2, y = 6 },  { x = 6, y = 6 },  { x = 10, y = 6 },
    { x = 2, y = 10 }, { x = 6, y = 10 }, { x = 10, y = 10 },
}

local orbs = {
    { x = 5,  y = 3,  collected = false },
    { x = 8,  y = 2,  collected = false },
    { x = 3,  y = 5,  collected = false },
    { x = 10, y = 5,  collected = false },
    { x = 4,  y = 7,  collected = false },
    { x = 8,  y = 9,  collected = false },
    { x = 3,  y = 10, collected = false },
    { x = 10, y = 10, collected = false },
}

------------------------------------------------------------------------
-- Player state
------------------------------------------------------------------------
local player = {
    gx = 2, gy = 2,
    vx = 1.5, vy = 1.5,
    dir = 1,
    va  = 0,
    moving  = false,
    turning = false,
}

------------------------------------------------------------------------
-- Game state
------------------------------------------------------------------------
local state       = STATE.TITLE
local score       = 0
local total_orbs  = #orbs
local explored    = {}
local weather     = "clear"
local weather_particles  = {}
local sparkle_particles  = {}
local torch_time  = 0
local cam         = nil

for y = 1, MAP_H do explored[y] = {} end

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function wrap_angle(a)
    while a >  math.pi do a = a - 2 * math.pi end
    while a < -math.pi do a = a + 2 * math.pi end
    return a
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function reveal_around(gx, gy)
    for dy = -1, 1 do
        for dx = -1, 1 do
            local nx, ny = gx + dx, gy + dy
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                explored[ny][nx] = true
            end
        end
    end
end

------------------------------------------------------------------------
-- Raycasting
------------------------------------------------------------------------
local function cast_ray(ox, oy, angle)
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    local t    = 0
    local step = 0.03
    while t < 16 do
        t = t + step
        local cx = ox + dx * t
        local cy = oy + dy * t
        local gx = math.floor(cx) + 1
        local gy = math.floor(cy) + 1
        if gx < 1 or gx > MAP_W or gy < 1 or gy > MAP_H then
            return t, 1, 0
        end
        if dungeon[gy][gx] > 0 then
            local prev_cx = ox + dx * (t - step)
            local prev_gx = math.floor(prev_cx) + 1
            local side = (prev_gx ~= gx) and 1 or 0
            return t, dungeon[gy][gx], side
        end
    end
    return 16, 0, 0
end

local function wall_color(wtype, dist, side)
    local c = WALL_COLORS[wtype] or WALL_COLORS[1]
    local fog   = math.max(0.1, 1.0 - dist / 14.0)
    local shade = (side == 1) and 0.75 or 1.0
    return c[1] * fog * shade, c[2] * fog * shade, c[3] * fog * shade
end

------------------------------------------------------------------------
-- Weather particle spawner
------------------------------------------------------------------------
local function spawn_weather(dt)
    if weather == "clear" then return end
    local rate = (weather == "rain") and 40 or 20
    for _ = 1, math.floor(rate * dt * 60) do
        weather_particles[#weather_particles + 1] = {
            x = math.random() * 800, y = -10,
            vy = (weather == "rain") and (200 + math.random() * 150) or (30 + math.random() * 40),
            vx = (weather == "rain") and (math.random() * 20 - 10) or (math.random() * 30 - 15),
            life = 0,
            max_life = (weather == "rain") and 3.0 or 8.0,
            size = (weather == "rain") and 1 or (2 + math.random() * 2),
        }
    end
end

------------------------------------------------------------------------
-- lurek.init
------------------------------------------------------------------------
lurek.init(function()
    lurek.window.setTitle("Dungeon Crawler — Lurek2D")
    lurek.render.setBackgroundColor(0.02, 0.02, 0.05)

    lurek.input.bind("forward",    { "w" })
    lurek.input.bind("back",       { "s" })
    lurek.input.bind("turn_left",  { "q" })
    lurek.input.bind("turn_right", { "e" })
    lurek.input.bind("weather1",   { "f1" })
    lurek.input.bind("weather2",   { "f2" })
    lurek.input.bind("weather3",   { "f3" })
    lurek.input.bind("quit",       { "escape" })
    lurek.input.bind("start",      { "return" })

    cam = lurek.camera.new(800, 600)
    player.vx = player.gx - 0.5
    player.vy = player.gy - 0.5
    player.va = DIR_ANGLE[player.dir + 1]
    reveal_around(player.gx, player.gy)
end)

lurek.ready(function() end)

------------------------------------------------------------------------
-- lurek.process
------------------------------------------------------------------------
lurek.process(function(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.signal.quit()
        return
    end

    -- TITLE state
    if state == STATE.TITLE then
        if lurek.input.wasActionPressed("start") then state = STATE.PLAYING end
        return
    end

    -- COMPLETE state
    if state == STATE.COMPLETE then return end

    -- === PLAYING ===
    torch_time = torch_time + dt

    -- Weather switching
    if lurek.input.wasActionPressed("weather1") then weather = "clear" end
    if lurek.input.wasActionPressed("weather2") then weather = "rain"  end
    if lurek.input.wasActionPressed("weather3") then weather = "snow"  end

    -- Grid movement (blocked during animation)
    if not player.moving and not player.turning then
        if lurek.input.wasActionPressed("forward") then
            local di = player.dir + 1
            local nx = player.gx + DIR_DX[di]
            local ny = player.gy + DIR_DY[di]
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H
               and dungeon[ny][nx] == 0 then
                player.gx = nx
                player.gy = ny
                player.moving = true
                reveal_around(nx, ny)
            end
        elseif lurek.input.wasActionPressed("back") then
            local di = player.dir + 1
            local nx = player.gx - DIR_DX[di]
            local ny = player.gy - DIR_DY[di]
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H
               and dungeon[ny][nx] == 0 then
                player.gx = nx
                player.gy = ny
                player.moving = true
                reveal_around(nx, ny)
            end
        elseif lurek.input.wasActionPressed("turn_left") then
            player.dir = (player.dir - 1) % 4
            player.turning = true
        elseif lurek.input.wasActionPressed("turn_right") then
            player.dir = (player.dir + 1) % 4
            player.turning = true
        end
    end

    -- Smooth lerp toward target
    local tgt_x = player.gx - 0.5
    local tgt_y = player.gy - 0.5
    local tgt_a = DIR_ANGLE[player.dir + 1]
    local da    = wrap_angle(tgt_a - player.va)
    local spd   = math.min(1, MOVE_SPEED * dt)

    player.vx = lerp(player.vx, tgt_x, spd)
    player.vy = lerp(player.vy, tgt_y, spd)
    player.va = player.va + da * spd

    if math.abs(player.vx - tgt_x) < 0.01 and math.abs(player.vy - tgt_y) < 0.01 then
        player.vx = tgt_x
        player.vy = tgt_y
        player.moving = false
    end
    if math.abs(wrap_angle(player.va - tgt_a)) < 0.02 then
        player.va = tgt_a
        player.turning = false
    end

    -- Orb collection
    for _, orb in ipairs(orbs) do
        if not orb.collected and orb.x == player.gx and orb.y == player.gy then
            orb.collected = true
            score = score + 100
            for _ = 1, 14 do
                sparkle_particles[#sparkle_particles + 1] = {
                    x = VP_X + VP_W / 2 + math.random() * 50 - 25,
                    y = VP_Y + VP_H / 2 + math.random() * 50 - 25,
                    vx = math.random() * 200 - 100,
                    vy = math.random() * 200 - 100,
                    life = 0, max_life = 0.8,
                    r = 1.0, g = 0.85, b = 0.2,
                }
            end
        end
    end

    -- Check win condition
    local all_collected = true
    for _, orb in ipairs(orbs) do
        if not orb.collected then all_collected = false; break end
    end
    if all_collected then state = STATE.COMPLETE end

    -- Update weather particles
    spawn_weather(dt)
    local i = 1
    while i <= #weather_particles do
        local p = weather_particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life + dt
        if p.life > p.max_life or p.y > 620 then
            weather_particles[i] = weather_particles[#weather_particles]
            weather_particles[#weather_particles] = nil
        else
            i = i + 1
        end
    end

    -- Update sparkle particles
    local j = 1
    while j <= #sparkle_particles do
        local p = sparkle_particles[j]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life + dt
        if p.life > p.max_life then
            sparkle_particles[j] = sparkle_particles[#sparkle_particles]
            sparkle_particles[#sparkle_particles] = nil
        else
            j = j + 1
        end
    end

    cam:update(dt)
end)

------------------------------------------------------------------------
-- lurek.render — 3D viewport: ceiling, floor, raycasted walls, torches
------------------------------------------------------------------------
lurek.render(function()
    if state == STATE.TITLE then return end
    cam:apply()

    -- Ceiling gradient (16 bands, darker further away)
    local bands   = 16
    local band_h  = (VP_H / 2) / bands
    for i = 0, bands - 1 do
        local b = 0.08 + 0.07 * (1.0 - i / bands)
        lurek.render.setColor(b * 0.6, b * 0.7, b * 0.9, 1)
        lurek.render.rectangle("fill", VP_X, VP_Y + i * band_h, VP_W, band_h + 1)
    end

    -- Floor gradient (16 bands, brighter closer)
    for i = 0, bands - 1 do
        local b = 0.06 + 0.06 * (i / bands)
        lurek.render.setColor(b * 0.5, b * 0.35, b * 0.2, 1)
        lurek.render.rectangle("fill", VP_X, VP_Y + VP_H / 2 + i * band_h, VP_W, band_h + 1)
    end

    -- Raycasting wall strips
    for r = 0, NUM_RAYS - 1 do
        local ray_a = player.va - HALF_FOV + (r / NUM_RAYS) * FOV
        local dist, wtype, side = cast_ray(player.vx, player.vy, ray_a)

        local corr = dist * math.cos(ray_a - player.va)
        if corr < 0.1 then corr = 0.1 end

        local strip_h = (VP_H * 0.9) / corr
        if strip_h > VP_H then strip_h = VP_H end

        local sx = VP_X + r * STRIP_W
        local sy = VP_Y + (VP_H - strip_h) / 2

        if wtype > 0 then
            local cr, cg, cb = wall_color(wtype, corr, side)

            -- Procedural texture variation per wall type
            if wtype == 2 then
                local pat = (math.floor(sy) % 8 < 4) and 0.92 or 1.0
                cr, cg, cb = cr * pat, cg * pat, cb * pat
            elseif wtype == 3 then
                local moss = 1.0 + 0.1 * math.sin(r * 0.7 + sy * 0.3)
                cg = cg * moss
            elseif wtype == 4 then
                local pulse = 0.85 + 0.15 * math.sin(torch_time * 3 + r * 0.2)
                cr, cg, cb = cr * pulse, cg * pulse, cb * pulse
            end

            lurek.render.setColor(cr, cg, cb, 1)
            lurek.render.rectangle("fill", sx, sy, STRIP_W + 0.5, strip_h)
        end
    end

    -- Torch glow projected into 3D viewport
    for _, torch in ipairs(torches) do
        local tdx  = (torch.x - 0.5) - player.vx
        local tdy  = (torch.y - 0.5) - player.vy
        local tdist = math.sqrt(tdx * tdx + tdy * tdy)
        if tdist < 8 then
            local ta  = math.atan2(tdy, tdx)
            local rel = wrap_angle(ta - player.va)
            if math.abs(rel) < HALF_FOV then
                local scr_x   = VP_X + ((rel / FOV) + 0.5) * VP_W
                local flicker  = 8 + 4 * math.sin(torch_time * 8 + torch.x * 3.7 + torch.y * 2.3)
                local alpha    = math.max(0, 0.25 * (1 - tdist / 8))
                lurek.render.setColor(1.0, 0.7, 0.2, alpha)
                lurek.render.circle("fill", scr_x, VP_Y + VP_H / 2 - 20, flicker)
            end
        end
    end

    -- Viewport border
    lurek.render.setColor(0.3, 0.3, 0.4, 1)
    lurek.render.rectangle("line", VP_X, VP_Y, VP_W, VP_H)

    cam:reset()
end)

------------------------------------------------------------------------
-- lurek.render_ui — minimap, compass, score, weather, particles
------------------------------------------------------------------------
lurek.render_ui(function()
    -- === TITLE SCREEN ===
    if state == STATE.TITLE then
        lurek.render.setColor(0.5, 0.2, 0.7, 1)
        lurek.render.print("DUNGEON CRAWLER", 220, 200, 36)
        lurek.render.setColor(0.7, 0.7, 0.8, 1)
        lurek.render.print("First-person grid dungeon with raycasting", 195, 270, 16)
        local blink = math.sin(lurek.time.getTime() * 4) > 0
        if blink then
            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print("PRESS ENTER", 330, 380, 20)
        end
        lurek.render.setColor(0.4, 0.4, 0.5, 1)
        lurek.render.print("W/S = Move   Q/E = Turn   F1-F3 = Weather", 190, 440, 14)
        return
    end

    -- === COMPLETE SCREEN ===
    if state == STATE.COMPLETE then
        lurek.render.setColor(1, 0.85, 0.2, 1)
        lurek.render.print("DUNGEON COMPLETE!", 240, 220, 32)
        lurek.render.setColor(0.9, 0.9, 1, 1)
        lurek.render.print("All orbs collected!   Score: " .. score, 255, 290, 18)
        lurek.render.setColor(0.6, 0.6, 0.7, 1)
        lurek.render.print("Press ESCAPE to exit", 300, 350, 16)
        return
    end

    -- === RIGHT PANEL ===
    local PX = 530
    local PY = 30

    lurek.render.setColor(0.8, 0.7, 1, 1)
    lurek.render.print("DUNGEON CRAWLER", PX, PY, 16)

    -- Score
    lurek.render.setColor(1, 0.85, 0.2, 1)
    lurek.render.print("Score: " .. score, PX, PY + 28, 14)

    -- Orbs remaining
    local remaining = 0
    for _, o in ipairs(orbs) do if not o.collected then remaining = remaining + 1 end end
    lurek.render.setColor(0.5, 0.9, 1, 1)
    lurek.render.print("Orbs: " .. (total_orbs - remaining) .. "/" .. total_orbs, PX, PY + 48, 14)

    -- Compass
    lurek.render.setColor(0.6, 0.6, 0.7, 1)
    lurek.render.print("Facing: " .. DIR_NAMES[player.dir + 1], PX, PY + 72, 14)
    local comp_cx = PX + 130
    local comp_cy = PY + 86
    local comp_r  = 18
    lurek.render.setColor(0.2, 0.2, 0.3, 0.8)
    lurek.render.circle("fill", comp_cx, comp_cy, comp_r)
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.circle("line", comp_cx, comp_cy, comp_r)
    local needle_a = DIR_ANGLE[player.dir + 1]
    local nx = comp_cx + math.cos(needle_a) * (comp_r - 4)
    local ny = comp_cy + math.sin(needle_a) * (comp_r - 4)
    lurek.render.setColor(1, 0.3, 0.3, 1)
    lurek.render.line(comp_cx, comp_cy, nx, ny)

    -- Weather indicator
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.print("Weather: " .. weather, PX, PY + 115, 12)
    lurek.render.print("F1=Clear  F2=Rain  F3=Snow", PX, PY + 132, 10)

    -- === MINIMAP ===
    local MM_X    = PX + 5
    local MM_Y    = PY + 160
    local MM_CELL = 18

    lurek.render.setColor(0.05, 0.05, 0.1, 0.9)
    lurek.render.rectangle("fill", MM_X - 2, MM_Y - 2,
        MAP_W * MM_CELL + 4, MAP_H * MM_CELL + 4)

    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local cx = MM_X + (x - 1) * MM_CELL
            local cy = MM_Y + (y - 1) * MM_CELL
            if explored[y] and explored[y][x] then
                if dungeon[y][x] > 0 then
                    local wc = WALL_COLORS[dungeon[y][x]]
                    lurek.render.setColor(wc[1] * 0.6, wc[2] * 0.6, wc[3] * 0.6, 1)
                else
                    lurek.render.setColor(0.15, 0.15, 0.2, 1)
                end
                lurek.render.rectangle("fill", cx, cy, MM_CELL - 1, MM_CELL - 1)

                -- Orbs on minimap
                for _, o in ipairs(orbs) do
                    if o.x == x and o.y == y and not o.collected then
                        lurek.render.setColor(1, 0.85, 0.2, 0.8)
                        lurek.render.circle("fill", cx + MM_CELL / 2, cy + MM_CELL / 2, 3)
                    end
                end
                -- Torches on minimap
                for _, t in ipairs(torches) do
                    if t.x == x and t.y == y then
                        lurek.render.setColor(1, 0.5, 0.1, 0.6)
                        lurek.render.circle("fill", cx + MM_CELL / 2, cy + MM_CELL / 2, 2)
                    end
                end
            else
                lurek.render.setColor(0.08, 0.08, 0.08, 1)
                lurek.render.rectangle("fill", cx, cy, MM_CELL - 1, MM_CELL - 1)
            end
        end
    end

    -- Player marker on minimap
    local pmx = MM_X + player.vx * MM_CELL
    local pmy = MM_Y + player.vy * MM_CELL
    lurek.render.setColor(0.2, 1, 0.3, 1)
    lurek.render.circle("fill", pmx, pmy, 4)
    local di = player.dir + 1
    lurek.render.line(pmx, pmy, pmx + DIR_DX[di] * 8, pmy + DIR_DY[di] * 8)

    -- Minimap border and label
    lurek.render.setColor(0.4, 0.4, 0.5, 1)
    lurek.render.rectangle("line", MM_X - 2, MM_Y - 2,
        MAP_W * MM_CELL + 4, MAP_H * MM_CELL + 4)
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.print("MINIMAP", MM_X + MAP_W * MM_CELL / 2 - 25,
        MM_Y + MAP_H * MM_CELL + 6, 11)

    -- === WEATHER OVERLAY ===
    for _, p in ipairs(weather_particles) do
        local alpha = 1.0 - p.life / p.max_life
        if weather == "rain" then
            lurek.render.setColor(0.5, 0.6, 0.9, alpha * 0.7)
            lurek.render.line(p.x, p.y, p.x + p.vx * 0.02, p.y + 6)
        else
            lurek.render.setColor(0.9, 0.95, 1, alpha * 0.6)
            lurek.render.circle("fill", p.x, p.y, p.size)
        end
    end

    -- Sparkle particles (orb collect)
    for _, p in ipairs(sparkle_particles) do
        local alpha = 1.0 - p.life / p.max_life
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        lurek.render.circle("fill", p.x, p.y, 3 * alpha)
    end

    -- Torch flicker particles near player
    local fl_alpha = 0.3 + 0.15 * math.sin(torch_time * 10)
    for _, torch in ipairs(torches) do
        local tdx = torch.x - player.gx
        local tdy = torch.y - player.gy
        if math.abs(tdx) <= 2 and math.abs(tdy) <= 2 then
            for _ = 1, 2 do
                local fx = VP_X + VP_W / 2 + tdx * 40 + math.random() * 10 - 5
                local fy = VP_Y + 40 + math.random() * 20
                lurek.render.setColor(1, 0.6, 0.1, fl_alpha * 0.5)
                lurek.render.circle("fill", fx, fy, 2 + math.random() * 2)
            end
        end
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.5, 1)
    lurek.render.print("FPS: " .. lurek.time.getFPS(), PX, 575, 11)
end)
