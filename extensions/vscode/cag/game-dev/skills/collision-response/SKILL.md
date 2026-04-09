# Collision Response

Physics body callbacks, bounce, slide, one-way platforms, slopes, damage zones, and triggers using lurek.physics.

## Key Concepts

- **Contact callbacks**: Use `lurek.physics.setCallbacks` to react to collision begin/end events.
- **Bounce**: Reflect velocity on contact normal. Scale by restitution coefficient.
- **Slide**: Zero out the velocity component along the collision normal, preserve the tangential component.
- **One-way platforms**: In collision callback, ignore contacts where player is moving upward or below the platform.
- **Sensors**: Non-solid bodies that detect overlap — use for damage zones, ladders, triggers.

## Contact Callbacks

```lua
lurek.physics.setCallbacks(
    function(a, b, contact)  -- beginContact
        local data_a = lurek.physics.getUserData(a)
        local data_b = lurek.physics.getUserData(b)
        if data_a == "player" and data_b == "spike" then
            take_damage(1)
        end
    end,
    function(a, b, contact)  -- endContact
        -- e.g., clear grounded flag
    end
)
```

## One-Way Platform

```lua
-- In preSolve callback: disable contact if player is below platform
lurek.physics.setPreSolve(function(a, b, contact)
    local da = lurek.physics.getUserData(a)
    local db = lurek.physics.getUserData(b)
    if db == "oneway" then
        local _, py = lurek.physics.getPosition(a)
        local _, platy = lurek.physics.getPosition(b)
        if py > platy then
            lurek.physics.setContactEnabled(contact, false)
        end
    end
end)
```

## Bounce Response

```lua
local function bounce(body, nx, ny, restitution)
    local vx, vy = lurek.physics.getLinearVelocity(body)
    local dot = vx * nx + vy * ny
    vx = vx - 2 * dot * nx * restitution
    vy = vy - 2 * dot * ny * restitution
    lurek.physics.setLinearVelocity(body, vx, vy)
end
```

## Damage Zone (Sensor)

```lua
local zone = lurek.physics.newBody(world, 200, 300, "static")
local shape = lurek.physics.newRectangleShape(32, 32)
local fixture = lurek.physics.newFixture(zone, shape)
lurek.physics.setSensor(fixture, true)
lurek.physics.setUserData(zone, "lava")
```

## Ladder Trigger

```lua
-- beginContact: if sensor is "ladder", set player.on_ladder = true
-- endContact: set player.on_ladder = false
-- In update: if on_ladder, disable gravity and allow vertical input
```

## Slope Handling

```lua
-- Use edge shapes for slopes. In update, project movement along the slope normal.
-- Snap player Y to the slope surface to prevent bouncing.
local function snap_to_slope(player, slope_y)
    if math.abs(player.y - slope_y) < 2 then
        player.y = slope_y
        player.vy = 0
        player.grounded = true
    end
end
```

## Common Pitfalls

- **Checking collision types by string** — store type strings via `setUserData` consistently. Typos cause silent misses.
- **One-way platform velocity check** — compare positions, not velocities. Velocity can be zero at the edge.
- **Sensor vs solid confusion** — sensors generate callbacks but no physics response. Don't expect them to block.
- **Modifying bodies inside callbacks** — some physics engines defer changes. Queue actions and apply after the step.
- **Missing endContact cleanup** — always clear flags (grounded, on_ladder) in endContact to prevent stale state.
