# Camera System

Smooth follow, deadzone, screenshake, zoom, and bounds-clamped camera for 2D games.

## Key Concepts

- **Lerp follow**: Smoothly interpolate camera toward target. Higher speed = snappier.
- **Deadzone**: Rectangle around screen center where small movements don't trigger camera motion.
- **Room locking**: Snap camera to discrete room boundaries (Zelda-style).
- **Screenshake**: Trauma-based decay — offset by `trauma^2 * max_offset * noise`.
- **Look-ahead**: Shift camera in the player's velocity direction for better visibility.
- **Bounds clamping**: Prevent camera from showing outside the world.

## Parameters

```lua
local CAM_SPEED     = 5.0
local DEADZONE_W    = 40
local DEADZONE_H    = 30
local SHAKE_DECAY   = 3.0
local SHAKE_MAX_X   = 8
local SHAKE_MAX_Y   = 6
local LOOK_AHEAD    = 40
```

## Smooth Follow

```lua
local cam = { x = 0, y = 0, trauma = 0 }

function update_camera(target, dt)
    cam.x = cam.x + (target.x - cam.x) * CAM_SPEED * dt
    cam.y = cam.y + (target.y - cam.y) * CAM_SPEED * dt
end
```

## Deadzone Follow

```lua
function update_camera_deadzone(target, dt)
    local dx = target.x - cam.x
    local dy = target.y - cam.y
    if math.abs(dx) > DEADZONE_W then
        cam.x = cam.x + (dx - DEADZONE_W * (dx > 0 and 1 or -1)) * CAM_SPEED * dt
    end
    if math.abs(dy) > DEADZONE_H then
        cam.y = cam.y + (dy - DEADZONE_H * (dy > 0 and 1 or -1)) * CAM_SPEED * dt
    end
end
```

## Screenshake (Trauma-Based)

```lua
function add_trauma(amount)
    cam.trauma = math.min(1.0, cam.trauma + amount)
end

function apply_shake(dt)
    cam.trauma = math.max(0, cam.trauma - SHAKE_DECAY * dt)
    local shake = cam.trauma * cam.trauma
    local ox = shake * SHAKE_MAX_X * (math.random() * 2 - 1)
    local oy = shake * SHAKE_MAX_Y * (math.random() * 2 - 1)
    return ox, oy
end

function luna.render()
    local ox, oy = apply_shake(dt_global)
    luna.gfx.push()
    luna.gfx.translate(-cam.x + ox, -cam.y + oy)
    -- draw world here
    luna.gfx.pop()
end
```

## Bounds Clamping

```lua
function clamp_camera(world_w, world_h, screen_w, screen_h)
    local hw, hh = screen_w * 0.5, screen_h * 0.5
    cam.x = math.max(hw, math.min(world_w - hw, cam.x))
    cam.y = math.max(hh, math.min(world_h - hh, cam.y))
end
```

## Look-Ahead

```lua
function update_camera_lookahead(target, vx, dt)
    local ahead = vx > 0 and LOOK_AHEAD or (vx < 0 and -LOOK_AHEAD or 0)
    local goal_x = target.x + ahead
    cam.x = cam.x + (goal_x - cam.x) * CAM_SPEED * dt
end
```

## Common Pitfalls

- **Lerp with raw dt** — `cam + (target - cam) * speed * dt` can overshoot if `speed * dt > 1`. Clamp: `math.min(1, speed * dt)`.
- **Shake without decay** — camera oscillates forever. Always subtract from trauma each frame.
- **Integer snapping** — for pixel-art games, round camera position to integers to avoid sub-pixel jitter.
- **Bounds smaller than screen** — if the world is smaller than the viewport, center it instead of clamping.
- **Shake during pause** — decay trauma even when paused, or freeze it explicitly.
