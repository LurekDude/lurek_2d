# Object Pool

Pre-allocated tables for bullets, particles, and enemies. Acquire/release pattern with resize policy.

## Key Concepts

- **Pre-allocation**: Create all objects at startup. No `table.insert` during gameplay.
- **Acquire/release**: Mark objects active/inactive instead of creating/destroying.
- **Resize policy**: If pool exhausts, either recycle oldest or grow by a fixed increment.
- **Typed pools**: Separate pools for bullets, enemies, particles — different object shapes.
- **Debug overlay**: Show pool utilization (active/total) for tuning initial sizes.

## Pool Implementation

```lua
local function new_pool(size, factory)
    local pool = { objects = {}, active_count = 0, size = size }
    for i = 1, size do
        pool.objects[i] = factory()
        pool.objects[i]._active = false
        pool.objects[i]._index = i
    end
    return pool
end

local function acquire(pool)
    for i = 1, pool.size do
        if not pool.objects[i]._active then
            pool.objects[i]._active = true
            pool.active_count = pool.active_count + 1
            return pool.objects[i]
        end
    end
    return nil  -- pool exhausted
end

local function release(pool, obj)
    if obj._active then
        obj._active = false
        pool.active_count = pool.active_count - 1
    end
end

local function for_each_active(pool, fn)
    for i = 1, pool.size do
        if pool.objects[i]._active then
            fn(pool.objects[i])
        end
    end
end
```

## Bullet Pool Example

```lua
local function bullet_factory()
    return { x = 0, y = 0, vx = 0, vy = 0, damage = 1, _active = false }
end

local bullet_pool = new_pool(200, bullet_factory)

local function fire_bullet(x, y, vx, vy, damage)
    local b = acquire(bullet_pool)
    if not b then return end  -- pool full, skip
    b.x, b.y = x, y
    b.vx, b.vy = vx, vy
    b.damage = damage or 1
end

local function update_bullets(dt)
    for_each_active(bullet_pool, function(b)
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        -- Off-screen check
        if b.x < -50 or b.x > 850 or b.y < -50 or b.y > 650 then
            release(bullet_pool, b)
        end
    end)
end

local function draw_bullets()
    for_each_active(bullet_pool, function(b)
        lurek.gfx.rectangle("fill", b.x - 2, b.y - 2, 4, 4)
    end)
end
```

## Recycle Oldest (When Full)

```lua
local function acquire_or_recycle(pool)
    local obj = acquire(pool)
    if obj then return obj end
    -- Find the oldest active object (lowest index)
    for i = 1, pool.size do
        if pool.objects[i]._active then
            return pool.objects[i]  -- reuse it
        end
    end
    return nil
end
```

## Debug Overlay

```lua
local function draw_pool_debug(pool, name, x, y)
    local pct = pool.active_count / pool.size
    local color = pct > 0.9 and {1,0,0} or (pct > 0.7 and {1,1,0} or {0,1,0})
    lurek.gfx.setColor(color[1], color[2], color[3], 1)
    lurek.gfx.print(
        name .. ": " .. pool.active_count .. "/" .. pool.size,
        x, y
    )
    lurek.gfx.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Forgetting to release** — objects stay active forever, pool fills up. Always release when done.
- **Stale data on reuse** — reset all fields in `acquire` or before use. Old velocity/position leaks through.
- **Pool too small** — monitor utilization in dev. If it hits 100% regularly, increase initial size.
- **Iterating with table.remove** — never remove from pool array. Toggle `_active` flag instead.
- **Active count mismatch** — only increment/decrement in `acquire`/`release`. Don't manipulate `_active` directly elsewhere.
