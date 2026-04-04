# Combat System

Hitbox/hurtbox, i-frames, knockback, damage numbers, drop tables, hitstop, and combo counters.

## Key Concepts

- **Hitbox/hurtbox**: Active attack region vs vulnerable region. Separate from physics bodies.
- **I-frames**: Invincibility window after taking damage. Prevents multi-hit from single attack.
- **Knockback**: Apply velocity impulse away from damage source on hit.
- **Hitstop**: Freeze both attacker and target for 2–4 frames on hit for impact feel.
- **Combo counter**: Increment on successive hits within a time window. Reset on miss or timeout.
- **Drop tables**: Weighted random loot from defeated enemies.

## Hitbox/Hurtbox

```lua
local function create_hitbox(owner, ox, oy, w, h, damage, knockback)
    return {
        x = owner.x + ox, y = owner.y + oy,
        w = w, h = h,
        damage = damage, knockback = knockback,
        owner = owner, active = true, lifetime = 0.1,
    }
end

local function check_hit(hitbox, targets)
    if not hitbox.active then return end
    for _, t in ipairs(targets) do
        if t ~= hitbox.owner and not t.invincible then
            if rects_overlap(hitbox, t) then
                apply_damage(t, hitbox.damage, hitbox.owner)
                apply_knockback(t, hitbox)
                hitbox.active = false
            end
        end
    end
end

local function rects_overlap(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x
       and a.y < b.y + b.h and a.y + a.h > b.y
end
```

## I-Frames

```lua
local I_FRAME_DURATION = 0.8

local function apply_damage(target, amount, source)
    if target.invincible then return end
    target.hp = target.hp - amount
    target.invincible = true
    target.i_timer = I_FRAME_DURATION
    spawn_damage_number(target.x, target.y, amount)
end

local function update_i_frames(entity, dt)
    if entity.invincible then
        entity.i_timer = entity.i_timer - dt
        if entity.i_timer <= 0 then entity.invincible = false end
    end
end
```

## Knockback

```lua
local function apply_knockback(target, hitbox)
    local dx = target.x - hitbox.x
    local dy = target.y - hitbox.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        target.vx = (dx / dist) * hitbox.knockback
        target.vy = (dy / dist) * hitbox.knockback
    end
end
```

## Hitstop

```lua
local hitstop = { timer = 0 }

local function trigger_hitstop(frames)
    hitstop.timer = frames / 60
end

function luna.update(dt)
    if hitstop.timer > 0 then
        hitstop.timer = hitstop.timer - dt
        return  -- freeze game logic
    end
    -- normal update...
end
```

## Combo Counter

```lua
local combo = { count = 0, timer = 0 }
local COMBO_WINDOW = 1.5  -- seconds

local function register_hit()
    combo.count = combo.count + 1
    combo.timer = COMBO_WINDOW
end

local function update_combo(dt)
    if combo.count > 0 then
        combo.timer = combo.timer - dt
        if combo.timer <= 0 then combo.count = 0 end
    end
end
```

## Drop Table

```lua
local DROP_TABLES = {
    slime = {
        { id = "gel",    weight = 60 },
        { id = "potion", weight = 25 },
        { id = "ring",   weight = 5 },
        { id = "none",   weight = 10 },
    },
}

local function roll_drop(enemy_type)
    local table = DROP_TABLES[enemy_type]
    if not table then return nil end
    local total = 0
    for _, entry in ipairs(table) do total = total + entry.weight end
    local roll = math.random() * total
    local acc = 0
    for _, entry in ipairs(table) do
        acc = acc + entry.weight
        if roll <= acc then
            return entry.id ~= "none" and entry.id or nil
        end
    end
    return nil
end
```

## Common Pitfalls

- **Hitbox stays active** — always deactivate after a hit or after its lifetime expires. Otherwise it damages every frame.
- **I-frames too short** — player gets hit multiple times by the same attack. 0.5–1.0s is typical.
- **Knockback without friction** — apply velocity decay or the entity slides forever.
- **Hitstop freezes particles** — only freeze game logic, not visual effects. Particles and screen shake should continue.
- **Combo resets on any hit taken** — decide if taking damage resets the combo. Document the design choice.
