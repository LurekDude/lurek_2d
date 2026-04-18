-- Lemmings — Lurek2D
-- Category: retro
-- A puzzle game inspired by DMA Design's 1991 classic (1991).
-- Assign jobs to mindless lemmings to guide them from entrance to exit.

local TILE = 10
local COLS = 80
local ROWS = 30
local GRAVITY = 300
local WALK_SPEED = 40
local FATAL_FALL = 300
local SPAWN_INTERVAL = 2.0
local TOTAL_LEMMINGS = 12
local NEEDED = 8

-- states
local STATE_TITLE = "TITLE"
local STATE_PLAYING = "PLAYING"
local STATE_LEVEL_COMPLETE = "LEVEL_COMPLETE"
local STATE_FAILED = "FAILED"
local STATE_GAME_OVER = "GAME_OVER"

local state = STATE_TITLE
local terrain = {}
local lemmings = {}
local particles = {}
local tweens_list = {}
local entrance = { col = 10, row = 3 }
local exit_pos = { col = 68, row = 26 }
local spawn_timer = 0
local spawned_count = 0
local saved_count = 0
local dead_count = 0
local level = 1
local level_timer = 0
local saved_pulse = 1.0
local fanfare_alpha = 0
local fanfare_text = ""
local cursor_x, cursor_y = 400, 300

local job_limits = {}
local job_used = {}

local levels = {
    {
        entrance = { col = 10, row = 3 },
        exit_pos = { col = 68, row = 26 },
        jobs = { blocker = 5, digger = 3, builder = 2, basher = 3 },
        build = function(t)
            for c = 0, COLS - 1 do t[14][c] = 1 end
            for c = 0, COLS - 1 do t[27][c] = 1; t[28][c] = 1 end
            for c = 20, 60 do t[20][c] = 1 end
            for r = 14, 27 do t[r][0] = 1; t[r][COLS - 1] = 1 end
            for c = 30, 35 do for r = 14, 20 do t[r][c] = 1 end end
            for c = 50, 55 do for r = 20, 27 do t[r][c] = 1 end end
        end
    },
    {
        entrance = { col = 5, row = 2 },
        exit_pos = { col = 74, row = 26 },
        jobs = { blocker = 3, digger = 4, builder = 3, basher = 2 },
        build = function(t)
            for c = 0, COLS - 1 do t[10][c] = 1 end
            for c = 0, COLS - 1 do t[18][c] = 1 end
            for c = 0, COLS - 1 do t[27][c] = 1; t[28][c] = 1 end
            for r = 0, 28 do t[r][0] = 1; t[r][COLS - 1] = 1 end
            for c = 15, 25 do t[10][c] = 0 end
            for c = 40, 50 do t[18][c] = 0 end
            for c = 60, 65 do for r = 10, 18 do t[r][c] = 1 end end
        end
    },
    {
        entrance = { col = 40, row = 2 },
        exit_pos = { col = 70, row = 26 },
        jobs = { blocker = 2, digger = 2, builder = 5, basher = 2 },
        build = function(t)
            for c = 0, COLS - 1 do t[27][c] = 1; t[28][c] = 1 end
            for r = 0, 28 do t[r][0] = 1; t[r][COLS - 1] = 1 end
            for c = 10, 30 do t[8][c] = 1 end
            for c = 50, 70 do t[8][c] = 1 end
            for c = 5, 20 do t[16][c] = 1 end
            for c = 35, 50 do t[22][c] = 1 end
            for c = 25, 30 do for r = 16, 22 do t[r][c] = 1 end end
            for c = 55, 60 do for r = 8, 16 do t[r][c] = 1 end end
        end
    },
}

local function init_terrain()
    terrain = {}
    for r = 0, ROWS - 1 do
        terrain[r] = {}
        for c = 0, COLS - 1 do terrain[r][c] = 0 end
    end
end

local function solid(c, r)
    if r < 0 or r >= ROWS or c < 0 or c >= COLS then return true end
    return terrain[r] and terrain[r][c] == 1
end

local function remove_tile(c, r)
    if r >= 0 and r < ROWS and c >= 0 and c < COLS and terrain[r] then
        terrain[r][c] = 0
    end
end

local function spawn_particles(x, y, color, count, speed)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd - speed * 0.3,
            life = 0.4 + math.random() * 0.4,
            age = 0,
            r = color[1], g = color[2], b = color[3],
            size = 2 + math.random() * 2,
        })
    end
end

local function add_tween(target, field, from, to, dur, on_done)
    table.insert(tweens_list, {
        target = target, field = field,
        from = from, to = to,
        duration = dur, elapsed = 0,
        on_done = on_done,
    })
end

local function load_level(idx)
    local lv = levels[idx]
    if not lv then
        state = STATE_GAME_OVER
        return
    end
    init_terrain()
    lv.build(terrain)
    entrance = { col = lv.entrance.col, row = lv.entrance.row }
    exit_pos = { col = lv.exit_pos.col, row = lv.exit_pos.row }
    job_limits = {}
    job_used = {}
    for k, v in pairs(lv.jobs) do
        job_limits[k] = v
        job_used[k] = 0
    end
    lemmings = {}
    particles = {}
    tweens_list = {}
    spawn_timer = 0
    spawned_count = 0
    saved_count = 0
    dead_count = 0
    level_timer = 0
    fanfare_alpha = 0
    state = STATE_PLAYING
end

local function create_lemming()
    local lx = entrance.col * TILE + TILE / 2
    local ly = entrance.row * TILE
    spawn_particles(lx, ly, {0.9, 0.9, 0.5}, 6, 40)
    return {
        x = lx, y = ly,
        vx = WALK_SPEED, vy = 0,
        dir = 1,
        job = "walker",
        alive = true, saved = false,
        fall_dist = 0,
        build_steps = 0,
        dig_timer = 0,
        anim_timer = 0,
    }
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.age = p.age + dt
        if p.age >= p.life then
            table.remove(particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 200 * dt
            i = i + 1
        end
    end
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens_list do
        local tw = tweens_list[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        local ease = t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
        if tw.target and tw.field then
            tw.target[tw.field] = tw.from + (tw.to - tw.from) * ease
        end
        if t >= 1.0 then
            if tw.on_done then tw.on_done() end
            table.remove(tweens_list, i)
        else
            i = i + 1
        end
    end
end

local function pixel_col(x) return math.floor(x / TILE) end
local function pixel_row(y) return math.floor(y / TILE) end

local function update_lemming(lem, dt)
    if not lem.alive or lem.saved then return end
    lem.anim_timer = lem.anim_timer + dt

    local col = pixel_col(lem.x)
    local row = pixel_row(lem.y + TILE)
    local on_ground = solid(col, row)

    if lem.job == "blocker" then return end

    if lem.job == "digger" then
        lem.dig_timer = lem.dig_timer + dt
        if lem.dig_timer >= 0.3 then
            lem.dig_timer = 0
            local dc = pixel_col(lem.x)
            local dr = pixel_row(lem.y + TILE)
            if solid(dc, dr) then
                remove_tile(dc, dr)
                lem.y = lem.y + TILE
                spawn_particles(lem.x, lem.y, {0.6, 0.4, 0.2}, 4, 30)
            else
                lem.job = "walker"
            end
        end
        return
    end

    if lem.job == "builder" then
        lem.dig_timer = lem.dig_timer + dt
        if lem.dig_timer >= 0.35 then
            lem.dig_timer = 0
            if lem.build_steps < 8 then
                local bc = pixel_col(lem.x + lem.dir * TILE)
                local br = pixel_row(lem.y) - 1
                if br >= 0 and br < ROWS and bc >= 0 and bc < COLS then
                    terrain[br][bc] = 1
                    lem.x = lem.x + lem.dir * TILE
                    lem.y = lem.y - TILE
                    lem.build_steps = lem.build_steps + 1
                    spawn_particles(lem.x, lem.y, {0.9, 0.7, 0.3}, 3, 20)
                else
                    lem.job = "walker"
                end
            else
                lem.job = "walker"
            end
        end
        return
    end

    if lem.job == "basher" then
        lem.dig_timer = lem.dig_timer + dt
        if lem.dig_timer >= 0.25 then
            lem.dig_timer = 0
            local bc = pixel_col(lem.x + lem.dir * TILE)
            local br = pixel_row(lem.y)
            local br2 = pixel_row(lem.y - TILE / 2)
            local hit = false
            if solid(bc, br) then remove_tile(bc, br); hit = true end
            if solid(bc, br2) then remove_tile(bc, br2); hit = true end
            if hit then
                lem.x = lem.x + lem.dir * TILE
                spawn_particles(lem.x, lem.y, {0.5, 0.35, 0.2}, 4, 35)
            else
                lem.job = "walker"
            end
        end
        return
    end

    -- walker / falling
    if not on_ground then
        lem.vy = lem.vy + GRAVITY * dt
        lem.y = lem.y + lem.vy * dt
        lem.fall_dist = lem.fall_dist + math.abs(lem.vy * dt)
        local new_row = pixel_row(lem.y + TILE)
        if solid(pixel_col(lem.x), new_row) then
            lem.y = (new_row - 1) * TILE
            if lem.fall_dist >= FATAL_FALL then
                lem.alive = false
                dead_count = dead_count + 1
                spawn_particles(lem.x, lem.y, {0.8, 0.2, 0.2}, 12, 80)
            end
            lem.vy = 0
            lem.fall_dist = 0
        end
    else
        lem.vy = 0
        lem.fall_dist = 0
        lem.x = lem.x + lem.dir * WALK_SPEED * dt
        local next_col = pixel_col(lem.x + lem.dir * (TILE / 2))
        local head_row = pixel_row(lem.y - 1)
        if solid(next_col, pixel_row(lem.y)) or solid(next_col, head_row) then
            lem.dir = -lem.dir
        end
    end

    -- check exit
    local ec = pixel_col(lem.x)
    local er = pixel_row(lem.y)
    if ec == exit_pos.col and er >= exit_pos.row - 1 and er <= exit_pos.row then
        lem.saved = true
        saved_count = saved_count + 1
        local pulse_ref = { val = saved_pulse }
        add_tween(pulse_ref, "val", 1.5, 1.0, 0.3)
        spawn_particles(exit_pos.col * TILE + TILE / 2, exit_pos.row * TILE, {0.3, 0.9, 0.3}, 8, 50)
    end

    -- out of bounds kill
    if lem.y > ROWS * TILE + 50 then
        lem.alive = false
        dead_count = dead_count + 1
    end
end

local function try_assign_job(job_name)
    if not job_limits[job_name] then return end
    if job_used[job_name] >= job_limits[job_name] then return end
    local best = nil
    local best_dist = 30
    for _, lem in ipairs(lemmings) do
        if lem.alive and not lem.saved and lem.job == "walker" then
            local dx = lem.x - cursor_x
            local dy = lem.y - cursor_y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < best_dist then
                best_dist = dist
                best = lem
            end
        end
    end
    if best then
        best.job = job_name
        best.dig_timer = 0
        best.build_steps = 0
        job_used[job_name] = job_used[job_name] + 1
        if job_name == "digger" then
            spawn_particles(best.x, best.y, {0.7, 0.5, 0.2}, 5, 25)
        elseif job_name == "builder" then
            spawn_particles(best.x, best.y, {1.0, 0.8, 0.3}, 5, 25)
        elseif job_name == "basher" then
            spawn_particles(best.x, best.y, {0.6, 0.4, 0.3}, 5, 25)
        elseif job_name == "blocker" then
            spawn_particles(best.x, best.y, {0.8, 0.2, 0.2}, 5, 25)
        end
    end
end

local function all_done()
    if spawned_count < TOTAL_LEMMINGS then return false end
    for _, lem in ipairs(lemmings) do
        if lem.alive and not lem.saved then return false end
    end
    return true
end

local function start_fanfare(text)
    fanfare_text = text
    local ref = { val = 0 }
    add_tween(ref, "val", 0, 1, 0.5)
    fanfare_alpha = 1
end

-- ─── Engine callbacks ───────────────────────────────────────────

lurek.setTitle("Lemmings — Lurek2D")
lurek.setBackgroundColor(0.05, 0.05, 0.15)

lurek.init(function()
    lurek.window.setTitle("Lemmings — Lurek2D")
end)

lurek.ready(function()
    state = STATE_TITLE
end)

lurek.process(function(dt)
    -- track mouse
    cursor_x, cursor_y = lurek.input.getMousePosition()

    if state == STATE_TITLE then
        if lurek.input.isKeyPressed("return") or lurek.input.isKeyPressed("space") then
            level = 1
            load_level(level)
        end
        if lurek.input.isKeyPressed("escape") then
            lurek.signal.quit()
        end
        return
    end

    if state == STATE_GAME_OVER then
        if lurek.input.isKeyPressed("return") or lurek.input.isKeyPressed("space") then
            state = STATE_TITLE
        end
        if lurek.input.isKeyPressed("escape") then
            lurek.signal.quit()
        end
        return
    end

    if state == STATE_LEVEL_COMPLETE or state == STATE_FAILED then
        update_tweens(dt)
        update_particles(dt)
        if lurek.input.isKeyPressed("return") or lurek.input.isKeyPressed("space") then
            if state == STATE_LEVEL_COMPLETE then
                level = level + 1
                load_level(level)
            else
                load_level(level)
            end
        end
        if lurek.input.isKeyPressed("escape") then
            lurek.signal.quit()
        end
        return
    end

    -- PLAYING
    if lurek.input.isKeyPressed("escape") then
        lurek.signal.quit()
        return
    end

    level_timer = level_timer + dt

    -- spawn
    if spawned_count < TOTAL_LEMMINGS then
        spawn_timer = spawn_timer + dt
        if spawn_timer >= SPAWN_INTERVAL then
            spawn_timer = spawn_timer - SPAWN_INTERVAL
            spawned_count = spawned_count + 1
            table.insert(lemmings, create_lemming())
        end
    end

    -- job keys
    if lurek.input.isKeyPressed("1") then try_assign_job("blocker") end
    if lurek.input.isKeyPressed("2") then try_assign_job("digger") end
    if lurek.input.isKeyPressed("3") then try_assign_job("builder") end
    if lurek.input.isKeyPressed("4") then try_assign_job("basher") end

    -- blocker collision
    for _, lem in ipairs(lemmings) do
        if lem.alive and not lem.saved and lem.job == "blocker" then
            for _, other in ipairs(lemmings) do
                if other ~= lem and other.alive and not other.saved and other.job ~= "blocker" then
                    local dx = other.x - lem.x
                    local dy = other.y - lem.y
                    if math.abs(dx) < TILE and math.abs(dy) < TILE then
                        if (other.dir > 0 and dx > 0) or (other.dir < 0 and dx < 0) then
                            -- approaching blocker, do nothing (will turn from solid check)
                        end
                        if math.abs(dx) < TILE * 0.6 then
                            other.dir = -other.dir
                        end
                    end
                end
            end
        end
    end

    -- update lemmings
    for _, lem in ipairs(lemmings) do
        update_lemming(lem, dt)
    end

    update_particles(dt)
    update_tweens(dt)

    -- check win/lose
    if all_done() then
        if saved_count >= NEEDED then
            state = STATE_LEVEL_COMPLETE
            start_fanfare("LEVEL " .. level .. " COMPLETE!")
        else
            state = STATE_FAILED
            start_fanfare("FAILED — " .. saved_count .. "/" .. NEEDED .. " saved")
        end
    end
end)

lurek.render(function()
    if state == STATE_TITLE or state == STATE_GAME_OVER then return end

    local ox, oy = 0, 100

    -- draw terrain
    for r = 0, ROWS - 1 do
        for c = 0, COLS - 1 do
            if terrain[r] and terrain[r][c] == 1 then
                local shade = 0.35 + ((r + c) % 3) * 0.05
                lurek.render.setColor(shade + 0.1, shade - 0.05, shade - 0.15, 1)
                lurek.render.drawRect(ox + c * TILE, oy + r * TILE, TILE, TILE)
            end
        end
    end

    -- draw entrance (trap door)
    local ex_px = ox + entrance.col * TILE
    local ey_px = oy + entrance.row * TILE
    lurek.render.setColor(0.6, 0.6, 0.7, 1)
    lurek.render.drawRect(ex_px - 8, ey_px - 12, 26, 4)
    lurek.render.setColor(0.4, 0.4, 0.5, 1)
    lurek.render.drawRect(ex_px - 5, ey_px - 8, 20, 10)
    lurek.render.setColor(0.2, 0.2, 0.3, 1)
    lurek.render.drawRect(ex_px, ey_px - 4, 10, 6)

    -- draw exit (archway)
    local xx = ox + exit_pos.col * TILE
    local xy = oy + exit_pos.row * TILE
    lurek.render.setColor(0.2, 0.7, 0.2, 1)
    lurek.render.drawRect(xx - 6, xy - 18, 4, 20)
    lurek.render.drawRect(xx + 12, xy - 18, 4, 20)
    lurek.render.drawRect(xx - 6, xy - 20, 22, 4)
    lurek.render.setColor(0.1, 0.5, 0.1, 1)
    lurek.render.drawRect(xx - 2, xy - 16, 14, 2)

    -- draw lemmings
    for _, lem in ipairs(lemmings) do
        if lem.alive and not lem.saved then
            local lx = ox + lem.x - 3
            local ly = oy + lem.y - 8

            if lem.job == "blocker" then
                -- red body, arms out
                lurek.render.setColor(0.9, 0.3, 0.3, 1)
                lurek.render.drawRect(lx, ly + 2, 6, 6)
                lurek.render.setColor(0.8, 0.2, 0.2, 1)
                lurek.render.drawRect(lx - 4, ly + 3, 4, 2)
                lurek.render.drawRect(lx + 6, ly + 3, 4, 2)
                -- head
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + 1, ly, 4, 3)
            elseif lem.job == "digger" then
                -- brown body, pickaxe motion
                lurek.render.setColor(0.6, 0.45, 0.2, 1)
                lurek.render.drawRect(lx, ly + 2, 6, 6)
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + 1, ly, 4, 3)
                -- pickaxe
                local swing = math.sin(lem.anim_timer * 8) * 3
                lurek.render.setColor(0.5, 0.5, 0.5, 1)
                lurek.render.drawRect(lx + 2, ly - 2 + swing, 2, 4)
            elseif lem.job == "builder" then
                -- yellow body with brick
                lurek.render.setColor(0.9, 0.8, 0.2, 1)
                lurek.render.drawRect(lx, ly + 2, 6, 6)
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + 1, ly, 4, 3)
                -- brick in hand
                lurek.render.setColor(0.8, 0.4, 0.2, 1)
                lurek.render.drawRect(lx + lem.dir * 5, ly + 4, 4, 3)
            elseif lem.job == "basher" then
                -- orange body, punch motion
                lurek.render.setColor(0.85, 0.55, 0.2, 1)
                lurek.render.drawRect(lx, ly + 2, 6, 6)
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + 1, ly, 4, 3)
                local punch = math.abs(math.sin(lem.anim_timer * 10)) * 4
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + lem.dir * (4 + punch), ly + 3, 3, 2)
            else
                -- walker: blue/green body
                lurek.render.setColor(0.2, 0.5, 0.9, 1)
                lurek.render.drawRect(lx, ly + 2, 6, 6)
                -- head
                lurek.render.setColor(0.95, 0.8, 0.6, 1)
                lurek.render.drawRect(lx + 1, ly, 4, 3)
                -- green hair
                lurek.render.setColor(0.2, 0.8, 0.3, 1)
                lurek.render.drawRect(lx + 1, ly - 1, 4, 2)
            end

            -- feet animation for walkers
            if lem.job == "walker" then
                local step = math.floor(lem.anim_timer * 6) % 2
                lurek.render.setColor(0.15, 0.15, 0.4, 1)
                if step == 0 then
                    lurek.render.drawRect(lx, ly + 8, 2, 2)
                    lurek.render.drawRect(lx + 4, ly + 8, 2, 2)
                else
                    lurek.render.drawRect(lx + 1, ly + 8, 2, 2)
                    lurek.render.drawRect(lx + 3, ly + 8, 2, 2)
                end
            end
        end
    end

    -- draw particles
    for _, p in ipairs(particles) do
        local alpha = 1 - (p.age / p.life)
        lurek.render.setColor(p.r, p.g, p.b, alpha)
        lurek.render.drawRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end

    -- cursor indicator
    lurek.render.setColor(1, 1, 1, 0.5)
    lurek.render.drawRect(cursor_x - 1, cursor_y - 8, 2, 16)
    lurek.render.drawRect(cursor_x - 8, cursor_y - 1, 16, 2)
end)

lurek.render_ui(function()
    if state == STATE_TITLE then
        lurek.render.setColor(0.3, 0.7, 1, 1)
        lurek.render.drawText("LEMMINGS", 260, 180, 48)
        lurek.render.setColor(0.2, 0.9, 0.3, 1)
        lurek.render.drawText("LET'S GO!", 310, 260, 24)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.drawText("Press ENTER to start", 290, 340, 16)
        lurek.render.drawText("Assign jobs: 1=Blocker  2=Digger  3=Builder  4=Basher", 160, 400, 14)
        lurek.render.drawText("Hover cursor near lemming + press key", 230, 430, 14)
        return
    end

    if state == STATE_GAME_OVER then
        lurek.render.setColor(0.9, 0.8, 0.2, 1)
        lurek.render.drawText("GAME OVER", 260, 200, 48)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.drawText("All " .. #levels .. " levels completed!", 280, 280, 20)
        lurek.render.drawText("Press ENTER to return to title", 250, 340, 16)
        return
    end

    -- HUD
    lurek.render.setColor(0.1, 0.1, 0.2, 0.85)
    lurek.render.drawRect(0, 0, 800, 28)

    lurek.render.setColor(0.3, 0.9, 0.3, 1)
    lurek.render.drawText("Saved: " .. saved_count .. "/" .. NEEDED, 10, 6, 16)

    lurek.render.setColor(0.7, 0.7, 0.9, 1)
    lurek.render.drawText("Level " .. level, 170, 6, 16)

    lurek.render.setColor(0.9, 0.9, 0.5, 1)
    lurek.render.drawText("Spawned: " .. spawned_count .. "/" .. TOTAL_LEMMINGS, 260, 6, 16)

    -- job counters
    local jx = 460
    local job_colors = {
        blocker = {0.9, 0.3, 0.3},
        digger = {0.6, 0.45, 0.2},
        builder = {0.9, 0.8, 0.2},
        basher = {0.85, 0.55, 0.2},
    }
    local job_keys_order = {"blocker", "digger", "builder", "basher"}
    local key_labels = {blocker = "1", digger = "2", builder = "3", basher = "4"}
    for _, jn in ipairs(job_keys_order) do
        local remaining = (job_limits[jn] or 0) - (job_used[jn] or 0)
        local clr = job_colors[jn]
        lurek.render.setColor(clr[1], clr[2], clr[3], 1)
        lurek.render.drawText(key_labels[jn] .. ":" .. jn:sub(1,1):upper() .. jn:sub(2) .. "=" .. remaining, jx, 6, 13)
        jx = jx + 90
    end

    -- timer
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    local mins = math.floor(level_timer / 60)
    local secs = math.floor(level_timer % 60)
    lurek.render.drawText(string.format("Time %d:%02d", mins, secs), 10, 580, 14)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.drawText("FPS: " .. fps, 730, 580, 12)

    -- bottom bar: job instructions
    lurek.render.setColor(0.1, 0.1, 0.2, 0.7)
    lurek.render.drawRect(0, 560, 800, 18)
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    lurek.render.drawText("Hover + 1:Blocker  2:Digger  3:Builder  4:Basher    ESC:Quit", 180, 562, 12)

    -- level complete / failed overlay
    if state == STATE_LEVEL_COMPLETE or state == STATE_FAILED then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.drawRect(0, 200, 800, 120)
        if state == STATE_LEVEL_COMPLETE then
            lurek.render.setColor(0.3, 1, 0.3, 1)
        else
            lurek.render.setColor(1, 0.3, 0.3, 1)
        end
        lurek.render.drawText(fanfare_text, 200, 230, 32)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        lurek.render.drawText("Saved: " .. saved_count .. "   Lost: " .. dead_count, 290, 280, 18)
        lurek.render.drawText("Press ENTER to continue", 280, 310, 14)
    end
end)
