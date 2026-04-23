-- ============================================================
-- Maze Defense — Hybrid tower-defense where YOU build the maze
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/maze_defense
-- ============================================================

local COLS, ROWS = 20, 14
local CELL  = 38
local OX    = 10
local OY    = 40
local W     = COLS * CELL + OX * 2
local H     = ROWS * CELL + OY + 40

local EMPTY  = 0
local WALL   = 1
local TOWER  = 2
local SPAWN  = 3
local BASE   = 4
local PATH   = 5

local gold      = 100
local lives     = 20
local wave      = 0
local wave_cd   = 5.0
local score     = 0
local enemies   = {}
local towers    = {}
local bullets   = {}
local grid      = {}
local state     = "build"   -- build | combat | gameover | victory

local particle_sys = nil

-- Build path grid: spawn top-left(0,6), base bottom-right(19,7)
local SPAWN_C, SPAWN_R = 1, 7
local BASE_C,  BASE_R  = 20, 7

local function init_grid()
    grid = {}
    for r = 1, ROWS do
        grid[r] = {}
        for c = 1, COLS do grid[r][c] = EMPTY end
    end
    grid[SPAWN_R][SPAWN_C] = SPAWN
    grid[BASE_R][BASE_C]   = BASE
end

-- Simple BFS pathfinding through grid
local function bfs()
    local visited = {}
    local prev    = {}
    local queue   = { { c = SPAWN_C, r = SPAWN_R } }
    for r = 1, ROWS do visited[r] = {} end
    visited[SPAWN_R][SPAWN_C] = true

    local function valid(c, r)
        return c >= 1 and c <= COLS and r >= 1 and r <= ROWS
            and not visited[r][c]
            and (grid[r][c] ~= WALL and grid[r][c] ~= TOWER)
    end

    while #queue > 0 do
        local cur = table.remove(queue, 1)
        if cur.c == BASE_C and cur.r == BASE_R then
            -- trace back
            local path = {}
            local n = cur
            while n do
                table.insert(path, 1, { c = n.c, r = n.r })
                n = prev[n.r .. "," .. n.c]
            end
            return path
        end
        local dirs = { {0,-1},{0,1},{-1,0},{1,0} }
        for _, d in ipairs(dirs) do
            local nc, nr = cur.c + d[1], cur.r + d[2]
            if valid(nc, nr) then
                visited[nr][nc] = true
                prev[nr .. "," .. nc] = { c = cur.c, r = cur.r }
                queue[#queue + 1] = { c = nc, r = nr }
            end
        end
    end
    return nil  -- blocked
end

local current_path = {}
local hover_c, hover_r = 0, 0

local function cell_world(c, r)
    return OX + (c-1) * CELL, OY + (r-1) * CELL
end

local function mouse_to_cell(mx, my)
    local c = math.floor((mx - OX) / CELL) + 1
    local r = math.floor((my - OY) / CELL) + 1
    return c, r
end

local function spawn_enemy()
    local hp = 15 + wave * 8
    enemies[#enemies + 1] = {
        hp = hp, maxHp = hp,
        step = 1,
        progress = 0.0,
        speed = 60 + wave * 5,
        reward = 5 + wave,
    }
end

local function rebuild_path()
    current_path = bfs() or {}
    -- mark path on grid (visual only)
    for r = 1, ROWS do
        for c = 1, COLS do
            if grid[r][c] == PATH then grid[r][c] = EMPTY end
        end
    end
    for i = 2, #current_path - 1 do
        local p = current_path[i]
        if grid[p.r][p.c] == EMPTY then grid[p.r][p.c] = PATH end
    end
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("place_wall",   "mouse1")
lurek.input.bind("place_tower",  "mouse2")
lurek.input.bind("start_wave",   "space")
lurek.input.bind("quit",         "escape")

-- ── Init ──────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Maze Defense — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.08, 0.05, 1.0)

    particle_sys = lurek.particle.newSystem({
        maxParticles = 60,
        emitRate     = 0,
        lifetime     = { 0.2, 0.5 },
        speed        = { 30, 100 },
        startColor   = { 1.0, 0.6, 0.1, 1.0 },
        endColor     = { 0.8, 0.1, 0.0, 0.0 },
        startSize    = 5, endSize = 1,
        spread       = math.pi * 2,
    })

    init_grid()
    rebuild_path()
end

-- ── Process ───────────────────────────────────────────────
function lurek.process(dt)
    if particle_sys then particle_sys:update(dt) end

    if lurek.input.wasActionPressed("quit") then lurek.event.quit() return end

    local mx, my = lurek.input.mouse.getPosition()
    hover_c, hover_r = mouse_to_cell(mx, my)

    if state == "build" then
        if lurek.input.wasActionPressed("place_wall") then
            local c, r = hover_c, hover_r
            if c >= 1 and c <= COLS and r >= 1 and r <= ROWS
               and grid[r][c] == EMPTY and gold >= 10 then
                grid[r][c] = WALL
                local test = bfs()
                if test then
                    gold = gold - 10
                    rebuild_path()
                else
                    grid[r][c] = EMPTY  -- would block path
                end
            end
        end

        if lurek.input.wasActionPressed("place_tower") then
            local c, r = hover_c, hover_r
            if c >= 1 and c <= COLS and r >= 1 and r <= ROWS
               and grid[r][c] == EMPTY and gold >= 25 then
                grid[r][c] = TOWER
                local test = bfs()
                if test then
                    gold = gold - 25
                    towers[#towers + 1] = { c = c, r = r, cooldown = 0.0, range = 3.0 * CELL }
                    rebuild_path()
                else
                    grid[r][c] = EMPTY
                    table.remove(towers)
                end
            end
        end

        if lurek.input.wasActionPressed("start_wave") then
            wave     = wave + 1
            state    = "combat"
            wave_cd  = 0.0
            for _ = 1, 5 + wave * 2 do
                spawn_enemy()
            end
        end
        return
    end

    if state == "gameover" or state == "victory" then return end

    -- Combat
    -- Move enemies along path
    local to_remove = {}
    for _, e in ipairs(enemies) do
        if #current_path < 2 then break end
        local cur = current_path[e.step]
        local nxt = current_path[e.step + 1]
        if not nxt then
            -- Reached base
            lives = lives - 1
            to_remove[#to_remove + 1] = e
            if lives <= 0 then state = "gameover" end
        else
            local wx, wy = cell_world(cur.c, cur.r)
            local tx, ty = cell_world(nxt.c, nxt.r)
            wx = wx + CELL/2 ; wy = wy + CELL/2
            tx = tx + CELL/2 ; ty = ty + CELL/2
            local dx, dy = tx - wx, ty - wy
            local dist   = math.sqrt(dx*dx + dy*dy)
            e.progress   = e.progress + e.speed * dt
            if e.progress >= CELL then
                e.progress = 0
                e.step     = e.step + 1
            end
        end
    end
    for _, e in ipairs(to_remove) do
        for i, v in ipairs(enemies) do if v == e then table.remove(enemies, i) break end end
    end

    -- Tower shooting
    for _, tower in ipairs(towers) do
        tower.cooldown = tower.cooldown - dt
        if tower.cooldown <= 0 then
            local tx, ty = cell_world(tower.c, tower.r)
            tx = tx + CELL/2 ; ty = ty + CELL/2
            for _, e in ipairs(enemies) do
                if e.hp > 0 and #current_path >= e.step then
                    local ep = current_path[e.step]
                    local ex, ey = cell_world(ep.c, ep.r)
                    ex = ex + CELL/2 ; ey = ey + CELL/2
                    local dx, dy = ex - tx, ey - ty
                    local d = math.sqrt(dx*dx + dy*dy)
                    if d <= tower.range then
                        e.hp = e.hp - 8
                        bullets[#bullets + 1] = { x = tx, y = ty, tx = ex, ty = ey, t = 0.15 }
                        tower.cooldown = 0.8
                        if e.hp <= 0 then
                            gold  = gold + e.reward
                            score = score + 10
                            if particle_sys then particle_sys:emit(ex, ey, 8) end
                        end
                        break
                    end
                end
            end
        end
    end

    -- Remove dead enemies
    for i = #enemies, 1, -1 do
        if enemies[i].hp <= 0 then table.remove(enemies, i) end
    end

    -- Update bullets
    for i = #bullets, 1, -1 do
        bullets[i].t = bullets[i].t - dt
        if bullets[i].t <= 0 then table.remove(bullets, i) end
    end

    if #enemies == 0 then
        if wave >= 5 then
            state = "victory"
        else
            state   = "build"
            gold    = gold + 20
        end
    end
end

-- ── Render world ──────────────────────────────────────────
function lurek.draw()
    -- Grid
    for r = 1, ROWS do
        for c = 1, COLS do
            local v = grid[r][c]
            local col
            if v == WALL  then col = {0.4,0.4,0.4,1}
            elseif v == TOWER then col = {0.2,0.5,0.8,1}
            elseif v == SPAWN then col = {0.8,0.6,0.1,1}
            elseif v == BASE  then col = {0.2,0.8,0.3,1}
            elseif v == PATH  then col = {0.15,0.22,0.15,1}
            else col = {0.1,0.14,0.1,1} end
            local wx, wy = cell_world(c, r)
            lurek.render.rectangle(wx, wy, CELL-1, CELL-1, { color = col })
        end
    end

    -- Hover highlight
    if hover_c >= 1 and hover_c <= COLS and hover_r >= 1 and hover_r <= ROWS then
        local wx, wy = cell_world(hover_c, hover_r)
        lurek.render.rectangle(wx, wy, CELL-1, CELL-1, { color = {1,1,1,0.15} })
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        if #current_path >= e.step then
            local p  = current_path[e.step]
            local ex, ey = cell_world(p.c, p.r)
            ex = ex + CELL/2 - 7
            ey = ey + e.progress - 10
            lurek.render.rectangle(ex, ey, 14, 14, { color = {0.8,0.2,0.2,1} })
            local hpw = math.floor(14 * e.hp / e.maxHp)
            lurek.render.rectangle(ex, ey - 4, hpw, 3, { color = {0.2,0.8,0.2,1} })
        end
    end

    -- Bullets
    for _, b in ipairs(bullets) do
        local t = 1.0 - b.t / 0.15
        local bx = b.x + (b.tx - b.x) * t
        local by = b.y + (b.ty - b.y) * t
        lurek.render.rectangle(bx - 2, by - 2, 4, 4, { color = {1,0.9,0.3,1} })
    end

    if particle_sys then particle_sys:draw() end
end

-- ── Render UI ─────────────────────────────────────────────
function lurek.draw_ui()
    lurek.render.print("Gold: " .. gold, 14, 8, { color = {1,0.85,0.2,1}, size = 15 })
    lurek.render.print("Lives: " .. lives, 130, 8, { color = {0.3,1.0,0.3,1}, size = 15 })
    lurek.render.print("Wave: " .. wave .. "/5", 240, 8, { color = {0.7,0.7,1.0,1}, size = 15 })
    lurek.render.print("Score: " .. score, 360, 8, { color = {1,1,1,1}, size = 15 })

    if state == "build" then
        lurek.render.print("BUILD PHASE  LMB=Wall(10g)  RMB=Tower(25g)  Space=Start Wave", 14, ROWS*CELL + OY + 4, { color = {0.5,0.8,0.5,1}, size = 12 })
    elseif state == "combat" then
        lurek.render.print("WAVE " .. wave .. " — Enemies remaining: " .. #enemies, 14, ROWS*CELL + OY + 4, { color = {1,0.5,0.3,1}, size = 12 })
    elseif state == "gameover" then
        lurek.render.print("GAME OVER", 260, 200, { color = {0.9,0.2,0.2,1}, size = 48 })
    elseif state == "victory" then
        lurek.render.print("VICTORY!", 270, 200, { color = {1,0.9,0.2,1}, size = 48 })
    end
end
