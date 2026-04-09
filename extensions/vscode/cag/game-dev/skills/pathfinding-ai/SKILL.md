# Pathfinding & AI

A* grid pathfinding, path following, obstacle avoidance, aggro radius, AI modes, and formations.

## Key Concepts

- **A* on grid**: Find shortest path on a tile grid with walkability data. Heuristic: Manhattan or Euclidean.
- **Path smoothing**: Remove redundant waypoints on straight lines.
- **Detection radius**: Aggro when player enters range; deaggro after leaving a larger range (hysteresis).
- **AI modes**: Patrol (follow waypoints), Chase (pursue target), Flee (run away), Idle (wait).
- **Formations**: Groups of enemies maintain relative positions while moving.

## A* Implementation

```lua
local function astar(grid, start, goal, w, h)
    local open = { [start.x .. "," .. start.y] = { x = start.x, y = start.y, g = 0, f = 0 } }
    local closed = {}
    local came_from = {}

    local function heuristic(a, b)
        return math.abs(a.x - b.x) + math.abs(a.y - b.y)
    end

    open[start.x .. "," .. start.y].f = heuristic(start, goal)

    while next(open) do
        -- Find lowest f in open
        local best_key, best = nil, nil
        for k, node in pairs(open) do
            if not best or node.f < best.f then best_key, best = k, node end
        end

        if best.x == goal.x and best.y == goal.y then
            -- Reconstruct path
            local path = {}
            local key = best.x .. "," .. best.y
            while key do
                local parts = {}
                for p in key:gmatch("[^,]+") do parts[#parts+1] = tonumber(p) end
                table.insert(path, 1, { x = parts[1], y = parts[2] })
                key = came_from[key]
            end
            return path
        end

        open[best_key] = nil
        closed[best_key] = true

        local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
        for _, d in ipairs(dirs) do
            local nx, ny = best.x + d[1], best.y + d[2]
            local nk = nx .. "," .. ny
            if nx >= 0 and nx < w and ny >= 0 and ny < h
               and not closed[nk] and grid[ny * w + nx + 1] == 0 then
                local ng = best.g + 1
                if not open[nk] or ng < open[nk].g then
                    came_from[nk] = best_key
                    open[nk] = { x = nx, y = ny, g = ng, f = ng + heuristic({x=nx,y=ny}, goal) }
                end
            end
        end
    end
    return nil  -- no path
end
```

## Path Following

```lua
local function follow_path(enemy, path, speed, dt)
    if not path or #path == 0 then return end
    local target = path[1]
    local tx = target.x * TILE_SIZE + TILE_SIZE * 0.5
    local ty = target.y * TILE_SIZE + TILE_SIZE * 0.5
    local dx, dy = tx - enemy.x, ty - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 2 then
        table.remove(path, 1)
    else
        enemy.x = enemy.x + (dx / dist) * speed * dt
        enemy.y = enemy.y + (dy / dist) * speed * dt
    end
end
```

## Detection Radius (Aggro / Deaggro)

```lua
local AGGRO_RANGE   = 120
local DEAGGRO_RANGE = 180

local function update_aggro(enemy, player)
    local dist = math.sqrt((player.x - enemy.x)^2 + (player.y - enemy.y)^2)
    if not enemy.aggro and dist < AGGRO_RANGE then
        enemy.aggro = true
        enemy.mode = "chase"
    elseif enemy.aggro and dist > DEAGGRO_RANGE then
        enemy.aggro = false
        enemy.mode = "patrol"
    end
end
```

## AI Modes

```lua
local function update_enemy(enemy, player, dt)
    update_aggro(enemy, player)
    if enemy.mode == "patrol" then
        follow_path(enemy, enemy.patrol_path, 40, dt)
    elseif enemy.mode == "chase" then
        -- Repath periodically
        enemy.repath_timer = (enemy.repath_timer or 0) - dt
        if enemy.repath_timer <= 0 then
            enemy.chase_path = astar(grid, tile_of(enemy), tile_of(player), map_w, map_h)
            enemy.repath_timer = 0.5
        end
        follow_path(enemy, enemy.chase_path, 60, dt)
    elseif enemy.mode == "flee" then
        -- Move away from player
        local dx = enemy.x - player.x
        local dy = enemy.y - player.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0 then
            enemy.x = enemy.x + (dx/dist) * 50 * dt
            enemy.y = enemy.y + (dy/dist) * 50 * dt
        end
    end
end
```

## Common Pitfalls

- **Repathing every frame** — A* is expensive. Repath every 0.3–0.5s, not every update.
- **No deaggro hysteresis** — if aggro and deaggro at the same distance, enemy flickers between modes at the boundary.
- **Path through closed doors** — regenerate grid walkability when world state changes (doors, bridges).
- **Diagonal movement on 4-dir grid** — if allowing diagonals, check both adjacent tiles to prevent corner cutting.
- **String key allocation** — `x..","..y` creates strings every iteration. For performance, use `y * w + x` as numeric key.
