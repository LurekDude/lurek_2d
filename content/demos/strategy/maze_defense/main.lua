-- Maze Defense — Tower Defense with Player-Built Mazing
-- Place walls to redirect enemies, build towers to shoot them
-- Run with: cargo run -- content/demos/strategy/maze_defense

local GRID_W, GRID_H = 20, 15
local CELL = 38
local OX, OY = 20, 20

local grid = {}       -- 0=empty, 1=wall, 2=tower
local enemies = {}
local bullets = {}
local wave = 1
local lives = 20
local gold = 100
local score = 0
local spawnTimer = 0
local enemiesToSpawn = 0
local waveActive = false
local path = {}
local gameOver = false

local SPAWN = {1, 1}
local EXIT = {GRID_W, GRID_H}
local WALL_COST = 5
local TOWER_COST = 20
local buildMode = "wall"  -- "wall" or "tower"

-- BFS pathfinding: finds the shortest 4-directional path through empty cells
-- from SPAWN to EXIT. Returns a list of {gx,gy} grid cells, or nil if the
-- exit is completely walled off.
local function findPath()
    local visited = {}
    local parent = {}   -- parent[gy][gx] = {px, py}  — used to reconstruct the path
    for y = 1, GRID_H do
        visited[y] = {}
        parent[y] = {}
        for x = 1, GRID_W do
            visited[y][x] = false
            parent[y][x] = nil
        end
    end
    -- BFS frontier initialised at the spawn cell
    local queue = {{SPAWN[1], SPAWN[2]}}
    visited[SPAWN[2]][SPAWN[1]] = true

    while #queue > 0 do
        local cur = table.remove(queue, 1)  -- dequeue from front (O(n) but grid is small)
        local cx, cy = cur[1], cur[2]
        if cx == EXIT[1] and cy == EXIT[2] then
            -- Reached exit — walk parent chain backward to rebuild ordered path
            local p = {}
            local nx, ny = cx, cy
            while nx and ny do
                table.insert(p, 1, {nx, ny})   -- prepend so result is SPAWN→EXIT order
                local pr = parent[ny][nx]
                if pr then nx, ny = pr[1], pr[2] else break end
            end
            return p
        end
        local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
        for _, d in ipairs(dirs) do
            local nx, ny = cx + d[1], cy + d[2]
            if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
                -- Only traverse empty cells (grid==0); walls and towers block passage
                if not visited[ny][nx] and grid[ny][nx] == 0 then
                    visited[ny][nx] = true
                    parent[ny][nx] = {cx, cy}
                    queue[#queue + 1] = {nx, ny}
                end
            end
        end
    end
    return nil -- no path exists — exit is blocked
end

local function recalcPath()
    path = findPath() or {}
end

local function spawnEnemy()
    local hp = 3 + wave * 2
    local speed = 40 + wave * 5
    if math.random() < 0.3 then
        hp = hp * 2
        speed = speed * 0.6
    end
    table.insert(enemies, {
        x = (SPAWN[1] - 0.5) * CELL + OX,
        y = (SPAWN[2] - 0.5) * CELL + OY,
        hp = hp, maxHp = hp,
        speed = speed,
        pathIdx = 1,
    })
end

local function startWave()
    enemiesToSpawn = 5 + wave * 3
    spawnTimer = 0
    waveActive = true
end

function lurek.init()
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            grid[y][x] = 0
        end
    end
    recalcPath()
    startWave()
end

function lurek.process(dt)
    if gameOver then return end

    -- Spawn enemies
    if enemiesToSpawn > 0 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= 0.6 then
            spawnTimer = 0
            spawnEnemy()
            enemiesToSpawn = enemiesToSpawn - 1
        end
    end

    -- Move enemies along path
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        if #path > 0 and e.pathIdx <= #path then
            local target = path[e.pathIdx]
            local tx = (target[1] - 0.5) * CELL + OX
            local ty = (target[2] - 0.5) * CELL + OY
            local dx, dy = tx - e.x, ty - e.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < 2 then
                e.pathIdx = e.pathIdx + 1
                if e.pathIdx > #path then
                    lives = lives - 1
                    table.remove(enemies, i)
                    if lives <= 0 then gameOver = true end
                end
            else
                e.x = e.x + (dx / dist) * e.speed * dt
                e.y = e.y + (dy / dist) * e.speed * dt
            end
        elseif #path == 0 then
            -- No path, enemies stuck
        end
    end

    -- Towers shoot
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            if grid[y][x] == 2 then
                local tx = (x - 0.5) * CELL + OX
                local ty = (y - 0.5) * CELL + OY
                local range = CELL * 3
                local closest = nil
                local closestDist = range
                for _, e in ipairs(enemies) do
                    local d = math.sqrt((e.x - tx)^2 + (e.y - ty)^2)
                    if d < closestDist then
                        closestDist = d
                        closest = e
                    end
                end
                -- Rate limit with time
                if closest then
                    local fireKey = x .. "_" .. y
                    if not grid.lastFire then grid.lastFire = {} end
                    local now = lurek.time.getTime()
                    if not grid.lastFire[fireKey] or now - grid.lastFire[fireKey] > 0.8 then
                        grid.lastFire[fireKey] = now
                        local dx = closest.x - tx
                        local dy = closest.y - ty
                        local d = math.sqrt(dx*dx + dy*dy)
                        table.insert(bullets, {
                            x = tx, y = ty,
                            vx = (dx/d) * 200, vy = (dy/d) * 200,
                            life = 1.5
                        })
                    end
                end
            end
        end
    end

    -- Update bullets
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(bullets, i)
        else
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                local d = math.sqrt((e.x - b.x)^2 + (e.y - b.y)^2)
                if d < 10 then
                    e.hp = e.hp - (2 + wave)
                    table.remove(bullets, i)
                    if e.hp <= 0 then
                        gold = gold + 5 + wave
                        score = score + 10
                        table.remove(enemies, j)
                    end
                    break
                end
            end
        end
    end

    -- Wave complete
    if waveActive and #enemies == 0 and enemiesToSpawn <= 0 then
        waveActive = false
        wave = wave + 1
        gold = gold + wave * 10
        startWave()
    end
end

function lurek.keypressed(key)
    if key == "1" then buildMode = "wall" end
    if key == "2" then buildMode = "tower" end
    if key == "escape" then lurek.signal.quit() end
    if gameOver and key == "r" then
        gameOver = false
        lives = 20
        gold = 100
        score = 0
        wave = 1
        enemies = {}
        bullets = {}
        lurek.signal.restart()
    end
end

function lurek.mousepressed(mx, my, btn)
    if gameOver then return end
    local gx = math.floor((mx - OX) / CELL) + 1
    local gy = math.floor((my - OY) / CELL) + 1
    if gx < 1 or gx > GRID_W or gy < 1 or gy > GRID_H then return end
    if (gx == SPAWN[1] and gy == SPAWN[2]) or (gx == EXIT[1] and gy == EXIT[2]) then return end

    if btn == 1 then
        if grid[gy][gx] == 0 then
            if buildMode == "wall" and gold >= WALL_COST then
                -- Tentatively place the wall, then run BFS to verify the path survives.
                -- If no path exists after placement, undo immediately — blocking the exit
                -- would make the game impossible to win.
                grid[gy][gx] = 1
                local testPath = findPath()
                if not testPath then
                    grid[gy][gx] = 0  -- path sealed — reject placement
                else
                    gold = gold - WALL_COST
                    path = testPath   -- accept new (longer) path
                end
            elseif buildMode == "tower" and gold >= TOWER_COST then
                -- Towers are placed on solid cells, so we first test with a wall tile
                -- to confirm the exit is still reachable, then promote the cell to tower.
                grid[gy][gx] = 1
                local testPath = findPath()
                if not testPath then
                    grid[gy][gx] = 0
                else
                    grid[gy][gx] = 2
                    gold = gold - TOWER_COST
                    path = testPath
                end
            end
        end
    elseif btn == 2 then
        if grid[gy][gx] ~= 0 then
            grid[gy][gx] = 0
            recalcPath()
        end
    end
end

function lurek.render()
    lurek.render.setBackgroundColor(0.08, 0.1, 0.08)

    -- Grid
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local px = OX + (x - 1) * CELL
            local py = OY + (y - 1) * CELL
            if grid[y][x] == 0 then
                lurek.render.setColor(0.15, 0.18, 0.15, 1)
            elseif grid[y][x] == 1 then
                lurek.render.setColor(0.4, 0.35, 0.25, 1)
            elseif grid[y][x] == 2 then
                lurek.render.setColor(0.2, 0.3, 0.6, 1)
            end
            lurek.render.rectangle("fill", px, py, CELL - 1, CELL - 1)
        end
    end

    -- Spawn and exit markers
    lurek.render.setColor(0, 1, 0, 1)
    lurek.render.rectangle("fill", OX + (SPAWN[1]-1)*CELL, OY + (SPAWN[2]-1)*CELL, CELL-1, CELL-1)
    lurek.render.setColor(1, 0, 0, 1)
    lurek.render.rectangle("fill", OX + (EXIT[1]-1)*CELL, OY + (EXIT[2]-1)*CELL, CELL-1, CELL-1)

    -- Path visualization
    lurek.render.setColor(0.3, 0.8, 0.3, 0.3)
    for _, p in ipairs(path) do
        if grid[p[2]][p[1]] == 0 then
            lurek.render.rectangle("fill", OX + (p[1]-1)*CELL + 8, OY + (p[2]-1)*CELL + 8, CELL - 17, CELL - 17)
        end
    end

    -- Tower range indicators
    lurek.render.setColor(0.3, 0.4, 0.8, 0.15)
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            if grid[y][x] == 2 then
                local tx = (x - 0.5) * CELL + OX
                local ty = (y - 0.5) * CELL + OY
                lurek.render.circle("fill", tx, ty, CELL * 3)
            end
        end
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        -- HP bar
        lurek.render.setColor(0.3, 0.3, 0.3, 1)
        lurek.render.rectangle("fill", e.x - 8, e.y - 14, 16, 3)
        lurek.render.setColor(1, 0.2, 0.2, 1)
        lurek.render.rectangle("fill", e.x - 8, e.y - 14, 16 * (e.hp / e.maxHp), 3)
        -- Body
        lurek.render.setColor(0.9, 0.3, 0.3, 1)
        lurek.render.circle("fill", e.x, e.y, 6)
    end

    -- Bullets
    lurek.render.setColor(1, 1, 0.4, 1)
    for _, b in ipairs(bullets) do
        lurek.render.circle("fill", b.x, b.y, 3)
    end

    -- HUD
    lurek.render.setColor(0, 0, 0, 0.8)
    lurek.render.rectangle("fill", 0, 0, 800, 18)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Wave: " .. wave .. "  Gold: " .. gold .. "  Lives: " .. lives .. "  Score: " .. score, 10, 2)
    local modeText = buildMode == "wall" and "[1]>WALL($5)" or "  [1] Wall($5)"
    local modeText2 = buildMode == "tower" and " [2]>TOWER($20)" or " [2] Tower($20)"
    lurek.render.setColor(0.8, 0.8, 0.5, 1)
    lurek.render.print(modeText .. modeText2 .. "  RClick=Remove", 400, 2)

    if gameOver then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 250, 250, 300, 80)
        lurek.render.setColor(1, 0.3, 0.3, 1)
        lurek.render.print("GAME OVER", 330, 265, 1.5)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Score: " .. score .. "  Wave: " .. wave, 320, 300)
        lurek.render.print("Press R to restart", 320, 318)
    end
end
