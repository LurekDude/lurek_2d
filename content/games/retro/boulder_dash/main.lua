-- ============================================================================
-- Boulder Dash — Lurek2D
-- Category: retro
-- Classic cave exploration: dig earth, collect diamonds, dodge boulders
-- ============================================================================

local CELL = 20
local COLS = 40
local ROWS = 26
local MAP_W = COLS * CELL
local MAP_H = ROWS * CELL

-- Cell types
local EMPTY   = 0
local EARTH   = 1
local WALL    = 2
local BOULDER = 3
local DIAMOND = 4
local PLAYER  = 5
local EXIT    = 6

-- States
local TITLE          = "TITLE"
local PLAYING        = "PLAYING"
local LEVEL_COMPLETE = "LEVEL_COMPLETE"
local GAME_OVER      = "GAME_OVER"

-- Game state
local state = TITLE
local grid = {}
local px, py = 1, 1
local lives = 3
local level = 1
local diamonds_collected = 0
local diamonds_needed = 0
local timer_left = 0
local exit_open = false
local physics_timer = 0
local PHYSICS_STEP = 0.18
local level_flash = 0
local diamond_pulse = 0
local player_dead = false
local death_timer = 0
local particles = {}
local cam_x, cam_y = 0, 0

-- Level definitions: {diamonds_needed, time_limit, boulder_chance, diamond_chance, earth_chance}
local LEVELS = {
    { needed = 10, time = 120, boulders = 0.08, diamonds = 0.04, earth = 0.70 },
    { needed = 16, time = 100, boulders = 0.10, diamonds = 0.05, earth = 0.65 },
    { needed = 24, time =  90, boulders = 0.12, diamonds = 0.06, earth = 0.60 },
}

-- ============================================================================
-- Helpers
-- ============================================================================

local function in_bounds(x, y)
    return x >= 1 and x <= COLS and y >= 1 and y <= ROWS
end

local function cell(x, y)
    if not in_bounds(x, y) then return WALL end
    return grid[y][x]
end

local function set_cell(x, y, v)
    if in_bounds(x, y) then grid[y][x] = v end
end

local function spawn_particles(wx, wy, r, g, b, count, speed, life)
    for i = 1, (count or 6) do
        local angle = math.random() * math.pi * 2
        local spd = (speed or 60) * (0.5 + math.random() * 0.5)
        particles[#particles + 1] = {
            x = wx, y = wy,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = (life or 0.5) * (0.6 + math.random() * 0.4),
            max_life = life or 0.5,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        }
    end
end

-- ============================================================================
-- Level generation
-- ============================================================================

local function generate_level(lv)
    local def = LEVELS[lv]
    diamonds_needed = def.needed
    timer_left = def.time
    diamonds_collected = 0
    exit_open = false
    physics_timer = 0
    player_dead = false
    death_timer = 0
    particles = {}
    diamond_pulse = 0
    level_flash = 1.0

    grid = {}
    for y = 1, ROWS do
        grid[y] = {}
        for x = 1, COLS do
            if y == 1 or y == ROWS or x == 1 or x == COLS then
                grid[y][x] = WALL
            else
                local r = math.random()
                if r < def.diamonds then
                    grid[y][x] = DIAMOND
                elseif r < def.diamonds + def.boulders then
                    grid[y][x] = BOULDER
                elseif r < def.diamonds + def.boulders + def.earth then
                    grid[y][x] = EARTH
                else
                    grid[y][x] = EMPTY
                end
            end
        end
    end

    -- Place player top-left area
    px, py = 3, 3
    for dy = -1, 1 do
        for dx = -1, 1 do
            set_cell(px + dx, py + dy, EMPTY)
        end
    end
    set_cell(px, py, PLAYER)

    -- Place exit bottom-right area
    local ex, ey = COLS - 2, ROWS - 2
    set_cell(ex, ey, EXIT)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
                if cell(ex + dx, ey + dy) ~= WALL then
                    set_cell(ex + dx, ey + dy, EMPTY)
                end
            end
        end
    end

    -- Add some extra wall structures for complexity
    local structures = 3 + lv * 2
    for i = 1, structures do
        local sx = math.random(4, COLS - 4)
        local sy = math.random(4, ROWS - 4)
        local horizontal = math.random() > 0.5
        local len = math.random(3, 6)
        for j = 0, len do
            local wx = horizontal and (sx + j) or sx
            local wy = horizontal and sy or (sy + j)
            if in_bounds(wx, wy) and not (wx == px and wy == py) and not (wx == ex and wy == ey) then
                set_cell(wx, wy, WALL)
            end
        end
    end
end

-- ============================================================================
-- Physics: gravity and cascading
-- ============================================================================

local function run_physics()
    -- Process bottom-up so falling works correctly
    for y = ROWS - 1, 2, -1 do
        for x = 2, COLS - 1 do
            local c = grid[y][x]
            if c == BOULDER or c == DIAMOND then
                local below = cell(x, y + 1)
                if below == EMPTY then
                    -- Fall straight down
                    set_cell(x, y, EMPTY)
                    set_cell(x, y + 1, c)
                    -- Check if it lands on player
                    if x == px and y + 1 == py then
                        player_dead = true
                        death_timer = 1.0
                        spawn_particles(px * CELL - CELL / 2, py * CELL - CELL / 2,
                            1.0, 1.0, 0.0, 12, 80, 0.8)
                    end
                elseif below == PLAYER and y + 1 == py then
                    -- Boulder/diamond falls onto player from above
                    player_dead = true
                    death_timer = 1.0
                    spawn_particles(px * CELL - CELL / 2, py * CELL - CELL / 2,
                        1.0, 1.0, 0.0, 12, 80, 0.8)
                    set_cell(x, y, EMPTY)
                    set_cell(x, y + 1, c)
                elseif below == BOULDER or below == DIAMOND then
                    -- Try slide left
                    if cell(x - 1, y) == EMPTY and cell(x - 1, y + 1) == EMPTY then
                        set_cell(x, y, EMPTY)
                        set_cell(x - 1, y + 1, c)
                    -- Try slide right
                    elseif cell(x + 1, y) == EMPTY and cell(x + 1, y + 1) == EMPTY then
                        set_cell(x, y, EMPTY)
                        set_cell(x + 1, y + 1, c)
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- Callbacks
-- ============================================================================

lurek.init(function()
    lurek.window.setTitle("Boulder Dash — Lurek2D")
    lurek.setBackgroundColor(0.06, 0.04, 0.02)
    math.randomseed(os.time())
end)

lurek.ready(function()
    -- Ready
end)

lurek.process(function(dt)
    if state == TITLE then
        if lurek.input.isActionJustPressed("ui_accept") then
            level = 1
            lives = 3
            generate_level(level)
            state = PLAYING
        end
        if lurek.input.isActionJustPressed("quit") then
            lurek.signal.emit("quit")
        end

    elseif state == PLAYING then
        if lurek.input.isActionJustPressed("quit") then
            lurek.signal.emit("quit")
        end

        -- Level flash tween
        if level_flash > 0 then
            level_flash = level_flash - dt * 2.0
            if level_flash < 0 then level_flash = 0 end
        end

        -- Diamond pulse tween
        if diamond_pulse > 0 then
            diamond_pulse = diamond_pulse - dt * 4.0
            if diamond_pulse < 0 then diamond_pulse = 0 end
        end

        -- Death handling
        if player_dead then
            death_timer = death_timer - dt
            if death_timer <= 0 then
                player_dead = false
                lives = lives - 1
                if lives <= 0 then
                    state = GAME_OVER
                else
                    generate_level(level)
                end
            end
        else
            -- Timer
            timer_left = timer_left - dt
            if timer_left <= 0 then
                timer_left = 0
                player_dead = true
                death_timer = 1.0
                spawn_particles(px * CELL - CELL / 2, py * CELL - CELL / 2,
                    1.0, 0.2, 0.0, 15, 90, 1.0)
            end

            -- Player input
            local dx, dy = 0, 0
            if lurek.input.isActionJustPressed("up") then dy = -1 end
            if lurek.input.isActionJustPressed("down") then dy = 1 end
            if lurek.input.isActionJustPressed("left") then dx = -1 end
            if lurek.input.isActionJustPressed("right") then dx = 1 end

            if dx ~= 0 or dy ~= 0 then
                local nx, ny = px + dx, py + dy
                local target = cell(nx, ny)

                if target == EMPTY or target == EARTH or target == DIAMOND or
                   (target == EXIT and exit_open) then
                    -- Dig earth
                    if target == EARTH then
                        spawn_particles(nx * CELL - CELL / 2, ny * CELL - CELL / 2,
                            0.55, 0.35, 0.15, 5, 40, 0.3)
                    end
                    -- Collect diamond
                    if target == DIAMOND then
                        diamonds_collected = diamonds_collected + 1
                        diamond_pulse = 1.0
                        spawn_particles(nx * CELL - CELL / 2, ny * CELL - CELL / 2,
                            0.0, 0.9, 1.0, 8, 70, 0.5)
                        if diamonds_collected >= diamonds_needed then
                            exit_open = true
                        end
                    end
                    -- Reach exit
                    if target == EXIT and exit_open then
                        state = LEVEL_COMPLETE
                    end

                    set_cell(px, py, EMPTY)
                    px, py = nx, ny
                    set_cell(px, py, PLAYER)
                elseif target == BOULDER and dy == 0 then
                    -- Push boulder horizontally
                    local bx = nx + dx
                    if cell(bx, ny) == EMPTY then
                        set_cell(nx, ny, EMPTY)
                        set_cell(bx, ny, BOULDER)
                        set_cell(px, py, EMPTY)
                        px, py = nx, ny
                        set_cell(px, py, PLAYER)
                    end
                end
            end

            -- Physics step
            physics_timer = physics_timer + dt
            if physics_timer >= PHYSICS_STEP then
                physics_timer = physics_timer - PHYSICS_STEP
                run_physics()
            end

            -- Check if player cell was overwritten by physics
            if cell(px, py) ~= PLAYER and not player_dead then
                player_dead = true
                death_timer = 1.0
                spawn_particles(px * CELL - CELL / 2, py * CELL - CELL / 2,
                    1.0, 1.0, 0.0, 12, 80, 0.8)
            end
        end

        -- Camera follow
        local target_cx = px * CELL - CELL / 2 - 400
        local target_cy = py * CELL - CELL / 2 - 300
        target_cx = math.max(0, math.min(target_cx, MAP_W - 800))
        target_cy = math.max(0, math.min(target_cy, MAP_H - 600))
        cam_x = cam_x + (target_cx - cam_x) * math.min(1, dt * 6)
        cam_y = cam_y + (target_cy - cam_y) * math.min(1, dt * 6)

        -- Update particles
        local i = 1
        while i <= #particles do
            local p = particles[i]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 120 * dt
            p.life = p.life - dt
            if p.life <= 0 then
                table.remove(particles, i)
            else
                i = i + 1
            end
        end

    elseif state == LEVEL_COMPLETE then
        level_flash = level_flash - dt * 1.5
        if lurek.input.isActionJustPressed("ui_accept") then
            level = level + 1
            if level > #LEVELS then
                -- Won all levels, back to title
                state = TITLE
            else
                generate_level(level)
                state = PLAYING
            end
        end

    elseif state == GAME_OVER then
        if lurek.input.isActionJustPressed("ui_accept") then
            state = TITLE
        end
        if lurek.input.isActionJustPressed("quit") then
            lurek.signal.emit("quit")
        end
    end
end)

-- ============================================================================
-- Rendering: cave, objects, particles
-- ============================================================================

lurek.render(function()
    if state == TITLE then return end
    if state == GAME_OVER then return end

    local ox = -math.floor(cam_x)
    local oy = -math.floor(cam_y)

    -- Draw grid
    for y = 1, ROWS do
        for x = 1, COLS do
            local sx = (x - 1) * CELL + ox
            local sy = (y - 1) * CELL + oy
            -- Cull off-screen cells
            if sx > -CELL and sx < 800 and sy > -CELL and sy < 600 then
                local c = grid[y][x]
                if c == EARTH then
                    lurek.render.drawRect(sx, sy, CELL - 1, CELL - 1, 0.55, 0.35, 0.15, 1)
                    -- Earth detail dots
                    lurek.render.drawRect(sx + 4, sy + 4, 2, 2, 0.45, 0.28, 0.10, 0.5)
                    lurek.render.drawRect(sx + 12, sy + 10, 2, 2, 0.45, 0.28, 0.10, 0.5)
                elseif c == WALL then
                    lurek.render.drawRect(sx, sy, CELL - 1, CELL - 1, 0.4, 0.4, 0.45, 1)
                    lurek.render.drawRect(sx + 1, sy + 1, CELL - 3, 1, 0.5, 0.5, 0.55, 0.3)
                elseif c == BOULDER then
                    -- Tan boulder
                    lurek.render.drawRect(sx + 2, sy + 2, CELL - 4, CELL - 4, 0.7, 0.6, 0.4, 1)
                    lurek.render.drawRect(sx + 4, sy + 3, 4, 3, 0.8, 0.7, 0.5, 0.4)
                elseif c == DIAMOND then
                    -- Cyan diamond shape (two rects as cross)
                    local pulse = math.sin(lurek.timer.getTime() * 6 + x * 0.7 + y * 0.5) * 0.15
                    local dr = 0.0
                    local dg = 0.7 + pulse
                    local db = 1.0
                    lurek.render.drawRect(sx + 6, sy + 2, 8, CELL - 4, dr, dg, db, 1)
                    lurek.render.drawRect(sx + 3, sy + 6, CELL - 6, 8, dr, dg, db, 1)
                    -- Sparkle highlight
                    lurek.render.drawRect(sx + 8, sy + 4, 3, 3, 1, 1, 1, 0.6)
                elseif c == PLAYER then
                    if not player_dead then
                        -- Yellow player
                        lurek.render.drawRect(sx + 2, sy + 2, CELL - 4, CELL - 4, 1.0, 0.9, 0.2, 1)
                        -- Eyes
                        lurek.render.drawRect(sx + 5, sy + 6, 3, 3, 0.1, 0.1, 0.1, 1)
                        lurek.render.drawRect(sx + 12, sy + 6, 3, 3, 0.1, 0.1, 0.1, 1)
                    end
                elseif c == EXIT then
                    if exit_open then
                        -- Bright green open exit
                        local glow = 0.7 + math.sin(lurek.timer.getTime() * 4) * 0.3
                        lurek.render.drawRect(sx, sy, CELL - 1, CELL - 1, 0.0, glow, 0.1, 1)
                        lurek.render.drawRect(sx + 4, sy + 4, CELL - 9, CELL - 9, 0.2, 1.0, 0.3, 0.7)
                    else
                        -- Dark closed exit
                        lurek.render.drawRect(sx, sy, CELL - 1, CELL - 1, 0.15, 0.2, 0.15, 1)
                    end
                end
            end
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        local sz = p.size * alpha
        lurek.render.drawRect(p.x + ox - sz / 2, p.y + oy - sz / 2, sz, sz,
            p.r, p.g, p.b, alpha)
    end

    -- Level flash overlay
    if level_flash > 0 then
        lurek.render.drawRect(0, 0, 800, 600, 1, 1, 1, level_flash * 0.3)
    end
end)

-- ============================================================================
-- UI rendering: HUD, title, game over
-- ============================================================================

lurek.render_ui(function()
    local fps = lurek.timer.getFPS()

    if state == TITLE then
        lurek.render.drawText("BOULDER DASH", 200, 180, 48, 0.7, 0.5, 0.2, 1)
        lurek.render.drawText("Dig. Collect. Escape.", 255, 240, 20, 0.6, 0.6, 0.5, 1)

        local blink = math.sin(lurek.timer.getTime() * 3) * 0.4 + 0.6
        lurek.render.drawText("PRESS ENTER", 305, 350, 22, 1, 1, 1, blink)

        lurek.render.drawText("Arrow keys to move | Collect diamonds | Avoid boulders", 135, 430, 14, 0.5, 0.5, 0.4, 1)
        lurek.render.drawText(string.format("FPS: %d", fps), 10, 580, 12, 0.3, 0.3, 0.3, 1)

    elseif state == PLAYING or state == LEVEL_COMPLETE then
        -- HUD background bar
        lurek.render.drawRect(0, 0, 800, 28, 0.0, 0.0, 0.0, 0.7)

        -- Diamond count with pulse
        local pulse_scale = 1.0 + diamond_pulse * 0.3
        local dc_color_g = 0.8 + diamond_pulse * 0.2
        local diamond_text = string.format("Diamonds: %d / %d", diamonds_collected, diamonds_needed)
        lurek.render.drawText(diamond_text, 10, 5,
            math.floor(16 * pulse_scale), 0.0, dc_color_g, 1.0, 1)

        -- Exit status
        if exit_open then
            lurek.render.drawText("EXIT OPEN!", 300, 5, 16, 0.2, 1.0, 0.3, 1)
        end

        -- Timer
        local t_minutes = math.floor(timer_left / 60)
        local t_seconds = math.floor(timer_left % 60)
        local timer_r = timer_left < 20 and 1.0 or 0.9
        local timer_g = timer_left < 20 and 0.3 or 0.9
        lurek.render.drawText(string.format("Time: %d:%02d", t_minutes, t_seconds),
            500, 5, 16, timer_r, timer_g, 0.8, 1)

        -- Lives
        lurek.render.drawText(string.format("Lives: %d", lives), 650, 5, 16, 1, 0.9, 0.2, 1)

        -- Level
        lurek.render.drawText(string.format("Lv %d", level), 750, 5, 16, 0.7, 0.7, 0.7, 1)

        -- FPS
        lurek.render.drawText(string.format("FPS: %d", fps), 10, 580, 12, 0.3, 0.3, 0.3, 1)

        if state == LEVEL_COMPLETE then
            lurek.render.drawRect(150, 200, 500, 120, 0.0, 0.0, 0.0, 0.85)
            if level < #LEVELS then
                lurek.render.drawText("LEVEL COMPLETE!", 260, 220, 32, 0.2, 1.0, 0.3, 1)
                lurek.render.drawText("Press ENTER for next level", 275, 270, 18, 0.8, 0.8, 0.8, 1)
            else
                lurek.render.drawText("YOU WIN!", 310, 220, 36, 1.0, 0.9, 0.2, 1)
                lurek.render.drawText("All caves cleared! Press ENTER", 255, 270, 18, 0.8, 0.8, 0.8, 1)
            end
        end

        if player_dead then
            local flash = math.sin(death_timer * 12) * 0.3 + 0.3
            lurek.render.drawRect(0, 0, 800, 600, 1.0, 0.0, 0.0, flash)
        end

    elseif state == GAME_OVER then
        lurek.render.drawText("GAME OVER", 250, 200, 48, 0.9, 0.2, 0.1, 1)
        lurek.render.drawText(string.format("Reached Level %d", level), 300, 270, 22, 0.7, 0.7, 0.6, 1)
        lurek.render.drawText(string.format("Diamonds: %d", diamonds_collected), 310, 310, 18, 0.0, 0.8, 1.0, 1)

        local blink = math.sin(lurek.timer.getTime() * 3) * 0.4 + 0.6
        lurek.render.drawText("PRESS ENTER", 310, 400, 22, 1, 1, 1, blink)

        lurek.render.drawText(string.format("FPS: %d", fps), 10, 580, 12, 0.3, 0.3, 0.3, 1)
    end
end)
