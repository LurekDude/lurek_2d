# Animation State Machine

State-driven sprite animation with transition conditions, priority, and frame events.

## Key Concepts

- **Animation state**: Each state maps to a sprite sheet row/range, speed, and loop mode.
- **Transitions**: Conditions based on velocity, grounded flag, or explicit triggers.
- **Priority**: Higher-priority animations (attack) override lower ones (walk). One-shot anims return to idle when done.
- **Frame events**: Fire callbacks at specific frames (e.g., spawn hitbox on frame 3 of attack).

## State Definition

```lua
local anims = {
    idle   = { frames = {1,2,3,4},     speed = 0.15, loop = true,  priority = 0 },
    walk   = { frames = {5,6,7,8},     speed = 0.10, loop = true,  priority = 1 },
    jump   = { frames = {9,10},        speed = 0.12, loop = false, priority = 2 },
    fall   = { frames = {11,12},       speed = 0.12, loop = true,  priority = 2 },
    attack = { frames = {13,14,15,16}, speed = 0.08, loop = false, priority = 3 },
}
```

## Animation Controller

```lua
local anim = { state = "idle", frame = 1, timer = 0, locked = false }

local function set_anim(name)
    if anim.locked and anims[name].priority <= anims[anim.state].priority then return end
    if anim.state == name then return end
    anim.state = name
    anim.frame = 1
    anim.timer = 0
    anim.locked = not anims[name].loop
end

local function update_anim(dt)
    local def = anims[anim.state]
    anim.timer = anim.timer + dt
    if anim.timer >= def.speed then
        anim.timer = anim.timer - def.speed
        anim.frame = anim.frame + 1
        -- Frame event hook
        if anim.on_frame then anim.on_frame(anim.state, anim.frame) end
        if anim.frame > #def.frames then
            if def.loop then
                anim.frame = 1
            else
                anim.frame = #def.frames
                anim.locked = false
                set_anim("idle")
            end
        end
    end
end
```

## Auto-Transition from Game State

```lua
function update_anim_state(player)
    if not anim.locked then
        if not player.grounded and player.vy < 0 then
            set_anim("jump")
        elseif not player.grounded and player.vy > 0 then
            set_anim("fall")
        elseif math.abs(player.vx) > 10 then
            set_anim("walk")
        else
            set_anim("idle")
        end
    end
end
```

## Drawing

```lua
function luna.render()
    local def = anims[anim.state]
    local quad_index = def.frames[anim.frame]
    -- Use luna.gfx.draw with quad from sprite sheet
    luna.gfx.draw(spritesheet, quads[quad_index], player.x, player.y)
end
```

## Frame Events Example

```lua
anim.on_frame = function(state, frame)
    if state == "attack" and frame == 3 then
        spawn_hitbox(player.x + 16, player.y, 20, 20)
    end
end
```

## Common Pitfalls

- **State flickering** — if walk/idle conditions alternate each frame, add a velocity threshold (e.g., `> 10` not `> 0`).
- **Locked animation ignored** — always check `anim.locked` and priority before overriding.
- **Timer accumulation** — subtract `def.speed` instead of resetting to 0 to avoid frame skips at low FPS.
- **Missing flip** — don't forget to flip the sprite horizontally based on `player.facing`.
- **Frame events fire twice** — guard with a `fired` flag per frame if the event has side effects.
