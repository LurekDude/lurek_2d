-- Lemmings — Amiga 500 Classic (Lurek2D demo)
-- Guide lemmings to the exit by assigning them jobs: blocker, digger, builder, basher.
-- Inspired by DMA Design's 1991 classic puzzle game.
-- Run with: cargo run -- content/demos/retro/lemmings

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local LSIZE  = 10   -- lemming unit size
local GRAVITY = 300
local WALK_SPD = 40
local FALL_FATAL = 300  -- fall height that kills
local SPAWN_INTERVAL = 2.0
local LEVEL_NEED = 8   -- lemmings needed to save
local LEVEL_TOTAL = 12  -- lemmings spawned total

-- ── Tilemap ───────────────────────────────────────────────────────────────
-- The world is stored as a flat grid. 1 = solid dirt, 0 = air.

local COLS = 80
local ROWS = 30
local TILE = 10   -- 1 tile = 10px

local terrain = {}  -- [1..COLS][1..ROWS] = true/false

local function t2w(tx, ty) return (tx-1)*TILE, (ty-1)*TILE end

local function build_terrain()
    for x = 1, COLS do
        terrain[x] = {}
        for y = 1, ROWS do
            -- Ground layers
            if y == ROWS or y == ROWS - 1 then terrain[x][y] = true
            elseif y == ROWS - 8 and x > 10 and x < 35 then terrain[x][y] = true  -- mid platform left
            elseif y == ROWS - 8 and x > 48 and x < 73 then terrain[x][y] = true  -- mid platform right
            elseif y == ROWS - 16 and x > 30 and x < 50 then terrain[x][y] = true -- upper platform
            else terrain[x][y] = false end
        end
    end
    -- Left wall and right wall
    for y = 1, ROWS do terrain[1][y] = true; terrain[COLS][y] = true end
end

local function is_solid(tx, ty)
    if tx < 1 or tx > COLS or ty < 1 or ty > ROWS then return ty >= ROWS end
    return terrain[tx][ty] == true
end

local function pixel_solid(px, py)
    return is_solid(math.floor(px/TILE)+1, math.floor(py/TILE)+1)
end

-- ── Lemming Jobs ──────────────────────────────────────────────────────────

local JOBS = { "none", "blocker", "digger", "builder", "basher" }
local JOB_COLORS = {
    none    = {0.4, 0.8, 0.2},
    blocker = {0.9, 0.5, 0.1},
    digger  = {0.6, 0.3, 0.1},
    builder = {0.2, 0.6, 0.9},
    basher  = {0.9, 0.2, 0.1},
}

-- ── State ─────────────────────────────────────────────────────────────────

local lemmings = {}
local spawned = 0
local saved   = 0
local dead    = 0
local spawn_timer = 0
local game_state = "playing"  -- "playing","win","lose"
local selected_job = "none"
local skill_counts = { blocker = 3, digger = 5, builder = 4, basher = 3 }
local anim = 0

-- Exit position (pixels)
local EXIT_X = (COLS - 5) * TILE
local EXIT_Y = (ROWS - 3) * TILE

-- Spawn position (pixels)
local SPAWN_X = 2 * TILE
local SPAWN_Y = (ROWS - 18) * TILE

-- ── Helpers ──────────────────────────────────────────────────────────────

local function spawn_lem()
    lemmings[#lemmings+1] = {
        x = SPAWN_X, y = SPAWN_Y, vx = WALK_SPD, vy = 0,
        fall_dist = 0, on_ground = false, alive = true,
        job = "none", build_steps = 0, build_timer = 0, dig_timer = 0
    }
end

local function assign_job(lem, job)
    if skill_counts[job] and skill_counts[job] > 0 then
        lem.job = job; skill_counts[job] = skill_counts[job] - 1
        return true
    end
    return false
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.4, 0.6, 0.9)
    build_terrain()
    lemmings = {}; spawned = 0; saved = 0; dead = 0; spawn_timer = 0
    skill_counts = { blocker = 3, digger = 5, builder = 4, basher = 3 }
    selected_job = "digger"
    game_state = "playing"
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    anim = anim + dt

    -- Spawn
    if spawned < LEVEL_TOTAL then
        spawn_timer = spawn_timer - dt
        if spawn_timer <= 0 then
            spawn_lem(); spawned = spawned + 1; spawn_timer = SPAWN_INTERVAL
        end
    end

    for i = #lemmings, 1, -1 do
        local lem = lemmings[i]
        if not lem.alive then goto continue end

        -- ── Blocker: stands still ──────────────────────────────────────────
        if lem.job == "blocker" then goto done end

        -- ── Gravity ───────────────────────────────────────────────────────
        local next_y = lem.y + lem.vy * dt
        if pixel_solid(lem.x + LSIZE/2, next_y + LSIZE) then
            local fall = lem.fall_dist
            if fall > FALL_FATAL then
                lem.alive = false; dead = dead + 1; goto continue
            end
            -- Land: snap to top of tile
            local ty = math.floor((lem.y + LSIZE) / TILE) * TILE
            lem.y = ty - LSIZE
            lem.vy = 0; lem.on_ground = true; lem.fall_dist = 0
        else
            lem.vy = lem.vy + GRAVITY * dt
            lem.y = next_y
            lem.fall_dist = lem.fall_dist + math.max(0, lem.vy) * dt
            lem.on_ground = false
        end

        if not lem.on_ground then goto done end

        -- ── Digger: remove tiles below ────────────────────────────────────
        if lem.job == "digger" then
            lem.dig_timer = lem.dig_timer + dt
            if lem.dig_timer > 0.25 then
                lem.dig_timer = 0
                local tx = math.floor(lem.x / TILE) + 1
                local ty = math.floor((lem.y + LSIZE) / TILE) + 1
                for bx = math.max(1, tx - 1), math.min(COLS, tx + 1) do
                    if terrain[bx] and terrain[bx][ty] then
                        terrain[bx][ty] = false
                    end
                end
                if ty >= ROWS then lem.job = "none" end  -- Hit rock bottom
            end
            goto done
        end

        -- ── Basher: remove tiles to the side ─────────────────────────────
        if lem.job == "basher" then
            lem.dig_timer = lem.dig_timer + dt
            if lem.dig_timer > 0.2 then
                lem.dig_timer = 0
                local face_col = math.floor((lem.x + (lem.vx > 0 and LSIZE + 2 or -2)) / TILE) + 1
                local ty = math.floor((lem.y + LSIZE/2) / TILE) + 1
                for by = math.max(1, ty - 1), math.min(ROWS, ty + 1) do
                    if terrain[face_col] and terrain[face_col][by] then
                        terrain[face_col][by] = false
                    end
                end
            end
        end

        -- ── Builder: place tiles ──────────────────────────────────────────
        if lem.job == "builder" then
            lem.build_timer = lem.build_timer + dt
            if lem.build_timer > 0.35 and lem.build_steps < 10 then
                lem.build_timer = 0
                lem.build_steps = lem.build_steps + 1
                local tx = math.floor((lem.x + (lem.vx > 0 and LSIZE or 0)) / TILE) + 1
                local ty = math.floor(lem.y / TILE) + 1
                if tx >= 1 and tx <= COLS and ty >= 1 and ty <= ROWS then
                    terrain[tx][ty] = true
                end
                lem.y = lem.y - TILE  -- Step up
            elseif lem.build_steps >= 10 then
                lem.job = "none"
            end
        end

        -- ── Walk ──────────────────────────────────────────────────────────
        local next_x = lem.x + lem.vx * dt
        -- Check if blocker is blocking
        for _, bl in ipairs(lemmings) do
            if bl ~= lem and bl.alive and bl.job == "blocker" then
                if math.abs((bl.x + LSIZE/2) - (next_x + LSIZE/2)) < LSIZE + 2 then
                    lem.vx = -lem.vx; goto done
                end
            end
        end
        -- Wall / cliff check
        if pixel_solid(next_x + (lem.vx > 0 and LSIZE + 1 or -1), lem.y + LSIZE/2) then
            lem.vx = -lem.vx
        else
            lem.x = next_x
        end

        -- ── Exit check ────────────────────────────────────────────────────
        if lem.x + LSIZE > EXIT_X and lem.x < EXIT_X + TILE * 2 and
           lem.y + LSIZE > EXIT_Y and lem.y < EXIT_Y + TILE * 2 then
            lem.alive = false; saved = saved + 1
        end

        ::done::
        ::continue::
    end

    -- Win / lose
    local done_all = (saved + dead) >= LEVEL_TOTAL and spawned >= LEVEL_TOTAL
    if done_all or saved >= LEVEL_NEED then
        game_state = saved >= LEVEL_NEED and "win" or "lose"
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Background sky gradient (simplified)
    lurek.render.setColor(0.45, 0.65, 0.95)
    lurek.render.rectangle("fill", 0, 0, W, H)

    -- Terrain
    for x = 1, COLS do
        for y = 1, ROWS do
            if terrain[x] and terrain[x][y] then
                local wx, wy = t2w(x, y)
                local ratio = y / ROWS
                lurek.render.setColor(0.35 - ratio*0.1, 0.55 - ratio*0.1, 0.15)
                lurek.render.rectangle("fill", wx, wy, TILE, TILE)
                -- Top edge highlight
                if not (terrain[x] and terrain[x][y-1]) then
                    lurek.render.setColor(0.5, 0.8, 0.25)
                    lurek.render.rectangle("fill", wx, wy, TILE, 3)
                end
            end
        end
    end

    -- Exit door
    lurek.render.setColor(0.9, 0.7, 0.1)
    lurek.render.rectangle("fill", EXIT_X, EXIT_Y - 20, TILE * 2, TILE * 2 + 20)
    lurek.render.setColor(0, 0, 0)
    lurek.render.print("EXIT", EXIT_X + 3, EXIT_Y - 16, 1.1)

    -- Spawn hatch
    lurek.render.setColor(0.8, 0.5, 0.2)
    lurek.render.rectangle("fill", SPAWN_X - 5, SPAWN_Y - 14, TILE * 2 + 10, TILE)
    local bounce = 0.5 + 0.5 * math.sin(anim * 8)
    lurek.render.setColor(1, 0.8, 0.1)
    lurek.render.rectangle("fill", SPAWN_X + 2, SPAWN_Y - 12 - bounce * 3, TILE + 6, 6)

    -- Lemmings
    for _, lem in ipairs(lemmings) do
        if lem.alive then
            local jc = JOB_COLORS[lem.job] or JOB_COLORS.none
            lurek.render.setColor(jc[1], jc[2], jc[3])
            lurek.render.rectangle("fill", lem.x, lem.y, LSIZE, LSIZE)
            -- Head
            lurek.render.setColor(0.9, 0.75, 0.6)
            lurek.render.circle("fill", lem.x + LSIZE/2, lem.y - 3, 5)
            -- Blue hat
            lurek.render.setColor(0.2, 0.2, 0.9)
            lurek.render.rectangle("fill", lem.x + 1, lem.y - 8, LSIZE - 2, 6)
            -- Walking legs
            local leg = math.floor(anim * 8) % 2 == 0
            if lem.on_ground and lem.job == "none" then
                lurek.render.setColor(jc[1] * 0.7, jc[2] * 0.7, jc[3] * 0.7)
                lurek.render.rectangle("fill", lem.x + (leg and 1 or 5), lem.y + LSIZE, 3, 4)
                lurek.render.rectangle("fill", lem.x + (leg and 5 or 1), lem.y + LSIZE, 3, 4)
            end
        end
    end

    -- HUD panel
    lurek.render.setColor(0.1, 0.1, 0.15, 0.85)
    lurek.render.rectangle("fill", 0, H - 42, W, 42)
    lurek.render.setColor(0.5, 1, 0.3)
    lurek.render.print("Saved: " .. saved .. "/" .. LEVEL_NEED, 8, H - 37, 1.5)
    lurek.render.setColor(1, 0.4, 0.4)
    lurek.render.print("Dead: " .. dead, 170, H - 37, 1.5)
    lurek.render.setColor(1, 0.8, 0.2)
    lurek.render.print("Left: " .. (LEVEL_TOTAL - spawned), 290, H - 37, 1.5)

    -- Job buttons
    local jobs_row = {"blocker","digger","builder","basher"}
    for i, j in ipairs(jobs_row) do
        local bx = 380 + (i-1) * 100
        local sel = selected_job == j
        lurek.render.setColor(sel and 0.3 or 0.2, sel and 0.5 or 0.3, sel and 0.9 or 0.5)
        lurek.render.rectangle("fill", bx, H - 40, 94, 36)
        if sel then
            lurek.render.setColor(1, 1, 0.2)
            lurek.render.rectangle("line", bx, H - 40, 94, 36)
        end
        local jc = JOB_COLORS[j]
        lurek.render.setColor(jc[1], jc[2], jc[3])
        lurek.render.print(j:upper() .. " " .. (skill_counts[j] or 0), bx + 4, H - 30, 1.2)
    end

    -- Overlay
    if game_state ~= "playing" then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, W, H)
        if game_state == "win" then
            lurek.render.setColor(0.2, 1, 0.4)
            lurek.render.print("LEVEL COMPLETE!", W/2 - 110, H/2 - 25, 3)
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("Saved: " .. saved .. " / " .. LEVEL_NEED, W/2 - 90, H/2 + 20, 2)
        else
            lurek.render.setColor(1, 0.2, 0.2)
            lurek.render.print("LEVEL FAILED", W/2 - 94, H/2 - 25, 3)
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("Saved: " .. saved .. " / " .. LEVEL_NEED, W/2 - 90, H/2 + 20, 2)
        end
        lurek.render.setColor(0.6, 0.6, 0.6)
        lurek.render.print("Press R to retry", W/2 - 88, H/2 + 58, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then lurek.signal.restart() end
    -- Job cycle: 1-4 keys
    if key == "1" then selected_job = "blocker" end
    if key == "2" then selected_job = "digger" end
    if key == "3" then selected_job = "builder" end
    if key == "4" then selected_job = "basher" end
    -- Click simulation: assign the nearest lemming within 20px to selected job
    -- (full mouse not available here, so use keyboard shortcut instead)
    if key == "a" then
        -- Assign job to the first eligible lemming near front of group
        for _, lem in ipairs(lemmings) do
            if lem.alive and lem.job == "none" and selected_job ~= "none" then
                assign_job(lem, selected_job)
                break
            end
        end
    end
end
