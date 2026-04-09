# Platformer Movement

Tight, responsive 2D platformer controls with jump arcs, coyote time, jump buffering, and wall mechanics.

## Parameter Table

```lua
local PLAYER_SPEED       = 160
local PLAYER_JUMP_VEL    = -420
local GRAVITY            = 900
local COYOTE_FRAMES      = 6
local JUMP_BUFFER_FRAMES = 8
local MAX_FALL_SPEED     = 600
local WALL_SLIDE_SPEED   = 80
local WALL_JUMP_VEL_X    = 200
local WALL_JUMP_VEL_Y    = -380
local ACCEL              = 1200
local DECEL              = 1600
```

## Key Concepts

- **Coyote time**: Allow jumping for `COYOTE_FRAMES` after leaving a ledge. Track `coyote_timer` — reset on ground, decrement in air.
- **Jump buffering**: Queue jump input for `JUMP_BUFFER_FRAMES` before landing. If player lands within the window, auto-jump.
- **Variable jump height**: On key release, clamp upward velocity to a fraction (e.g. `vy * 0.4`) for short hops.
- **Acceleration curves**: Use `ACCEL` toward target speed; `DECEL` when no input. Prevents instant direction changes.
- **Wall slide**: When pressing into a wall in air, cap fall speed to `WALL_SLIDE_SPEED`.
- **Wall jump**: Launch away from wall with `(WALL_JUMP_VEL_X, WALL_JUMP_VEL_Y)`. Lock horizontal input briefly (~0.1s).

## Code Pattern

```lua
local player = { x = 100, y = 100, vx = 0, vy = 0, grounded = false }
local coyote_timer = 0
local jump_buffer  = 0

function lurek.process(dt)
    -- Horizontal acceleration
    local ix = 0
    if lurek.keyboard.isDown("left")  then ix = ix - 1 end
    if lurek.keyboard.isDown("right") then ix = ix + 1 end

    if ix ~= 0 then
        player.vx = player.vx + ix * ACCEL * dt
        player.vx = math.max(-PLAYER_SPEED, math.min(PLAYER_SPEED, player.vx))
    else
        local sign = player.vx > 0 and 1 or -1
        player.vx = player.vx - sign * DECEL * dt
        if sign * player.vx < 0 then player.vx = 0 end
    end

    -- Coyote time
    if player.grounded then coyote_timer = COYOTE_FRAMES
    else coyote_timer = coyote_timer - 1 end

    -- Jump buffer countdown
    jump_buffer = math.max(0, jump_buffer - 1)

    -- Jump execution
    if jump_buffer > 0 and coyote_timer > 0 then
        player.vy = PLAYER_JUMP_VEL
        coyote_timer = 0
        jump_buffer  = 0
    end

    -- Gravity + terminal velocity
    player.vy = math.min(player.vy + GRAVITY * dt, MAX_FALL_SPEED)

    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
end

function lurek.keypressed(key)
    if key == "space" then jump_buffer = JUMP_BUFFER_FRAMES end
    -- Variable jump height: release early for short hop
end

function lurek.keyreleased(key)
    if key == "space" and player.vy < 0 then
        player.vy = player.vy * 0.4
    end
end
```

## Common Pitfalls

- **Forgetting diagonal normalization** — not relevant here (horizontal-only), but don't mix top-down patterns.
- **Coyote timer in frames vs seconds** — pick one unit and stay consistent. Frames are simpler at fixed timestep.
- **MAX_FALL_SPEED too low** — makes gravity feel floaty. 600 is a good starting point.
- **Missing decel** — without deceleration the character feels like it's on ice.
- **Wall jump without input lock** — player can immediately re-stick to the same wall. Lock horizontal input for ~6 frames.
