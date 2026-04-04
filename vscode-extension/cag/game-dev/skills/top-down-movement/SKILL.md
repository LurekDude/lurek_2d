# Top-Down Movement

8-directional, grid-locked RPG, and analog movement for overhead perspective games.

## Key Concepts

- **Diagonal normalization**: Raw 8-dir input gives magnitude 1.41 on diagonals. Normalize to prevent speed boost.
- **Grid-locked movement**: Player moves tile-to-tile. Queue next direction mid-step for fluid RPG feel.
- **Facing direction**: Track last non-zero input direction for attack/interact orientation.
- **Bump/slide collision**: When blocked, slide along the non-blocked axis instead of full stop.

## Parameters

```lua
local MOVE_SPEED  = 120
local TILE_SIZE   = 16
local GRID_SPEED  = 80   -- pixels/sec for grid movement
```

## 8-Direction Free Movement

```lua
local player = { x = 100, y = 100, facing = "down" }

function luna.update(dt)
    local dx, dy = 0, 0
    if luna.keyboard.isDown("left")  then dx = dx - 1 end
    if luna.keyboard.isDown("right") then dx = dx + 1 end
    if luna.keyboard.isDown("up")    then dy = dy - 1 end
    if luna.keyboard.isDown("down")  then dy = dy + 1 end

    -- Normalize diagonal
    local len = math.sqrt(dx * dx + dy * dy)
    if len > 0 then
        dx, dy = dx / len, dy / len
        -- Update facing
        if math.abs(dx) > math.abs(dy) then
            player.facing = dx > 0 and "right" or "left"
        else
            player.facing = dy > 0 and "down" or "up"
        end
    end

    player.x = player.x + dx * MOVE_SPEED * dt
    player.y = player.y + dy * MOVE_SPEED * dt
end
```

## Grid-Locked RPG Movement

```lua
local player = { gx = 3, gy = 3, tx = nil, ty = nil, progress = 0, facing = "down" }

function luna.update(dt)
    if player.tx then
        -- Animate toward target tile
        player.progress = player.progress + GRID_SPEED * dt / TILE_SIZE
        if player.progress >= 1 then
            player.gx, player.gy = player.tx, player.ty
            player.tx, player.ty = nil, nil
            player.progress = 0
        end
    else
        -- Accept new input
        local dx, dy = 0, 0
        if     luna.keyboard.isDown("up")    then dy = -1; player.facing = "up"
        elseif luna.keyboard.isDown("down")  then dy =  1; player.facing = "down"
        elseif luna.keyboard.isDown("left")  then dx = -1; player.facing = "left"
        elseif luna.keyboard.isDown("right") then dx =  1; player.facing = "right"
        end
        if dx ~= 0 or dy ~= 0 then
            local nx, ny = player.gx + dx, player.gy + dy
            if is_walkable(nx, ny) then
                player.tx, player.ty = nx, ny
                player.progress = 0
            end
        end
    end
end

function luna.draw()
    local px = (player.gx + (player.tx and (player.tx - player.gx) * player.progress or 0)) * TILE_SIZE
    local py = (player.gy + (player.ty and (player.ty - player.gy) * player.progress or 0)) * TILE_SIZE
    luna.graphics.rectangle("fill", px, py, TILE_SIZE, TILE_SIZE)
end
```

## Bump/Slide Collision

```lua
-- Try X first, then Y separately
local nx = player.x + dx * MOVE_SPEED * dt
if not collides(nx, player.y) then player.x = nx end

local ny = player.y + dy * MOVE_SPEED * dt
if not collides(player.x, ny) then player.y = ny end
```

## Common Pitfalls

- **Missing diagonal normalization** — players move 41% faster diagonally. Always normalize.
- **Priority conflicts in grid movement** — if both axes pressed simultaneously, pick one (vertical or horizontal first). Be consistent.
- **Facing not updated when blocked** — update facing even if the move is rejected by collision.
- **Jitter at tile boundaries** — snap to grid after movement completes; don't accumulate float errors over many tiles.
