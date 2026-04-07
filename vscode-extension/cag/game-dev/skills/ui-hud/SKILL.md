# UI / HUD

Health bars, minimap, inventory slots, tooltips, damage numbers, cooldown indicators, and speech bubbles.

## Key Concepts

- **Screen-space rendering**: HUD elements are drawn after the camera transform is popped (no world scrolling).
- **Anchoring**: Position elements relative to screen edges so they work at different resolutions.
- **Gradients**: Interpolate bar color from green → yellow → red based on percentage.
- **Floating text**: Spawn at world position, animate upward and fade out.

## Health Bar with Color Gradient

```lua
local function draw_health_bar(x, y, w, h, hp, max_hp)
    local pct = hp / max_hp
    -- Background
    luna.gfx.setColor(0.2, 0.2, 0.2, 0.8)
    luna.gfx.rectangle("fill", x, y, w, h)
    -- Bar color: green → yellow → red
    local r = pct < 0.5 and 1.0 or (1.0 - pct) * 2
    local g = pct > 0.5 and 1.0 or pct * 2
    luna.gfx.setColor(r, g, 0, 1)
    luna.gfx.rectangle("fill", x, y, w * pct, h)
    -- Border
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.rectangle("line", x, y, w, h)
end
```

## Damage Numbers (Floating Text)

```lua
local floaters = {}

local function spawn_damage(x, y, amount)
    floaters[#floaters + 1] = {
        x = x, y = y, text = tostring(amount),
        vy = -60, life = 1.0, max_life = 1.0,
    }
end

local function update_floaters(dt)
    for i = #floaters, 1, -1 do
        local f = floaters[i]
        f.y = f.y + f.vy * dt
        f.life = f.life - dt
        if f.life <= 0 then table.remove(floaters, i) end
    end
end

local function draw_floaters()
    for _, f in ipairs(floaters) do
        local alpha = f.life / f.max_life
        luna.gfx.setColor(1, 0.2, 0.2, alpha)
        luna.gfx.print(f.text, f.x, f.y)
    end
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Cooldown Indicator

```lua
local function draw_cooldown(x, y, size, remaining, total)
    local pct = remaining / total
    luna.gfx.setColor(0, 0, 0, 0.5)
    luna.gfx.rectangle("fill", x, y, size, size * pct)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.rectangle("line", x, y, size, size)
end
```

## Tooltip

```lua
local function draw_tooltip(mx, my, text)
    local tw = #text * 8 + 16
    local th = 24
    luna.gfx.setColor(0, 0, 0, 0.85)
    luna.gfx.rectangle("fill", mx + 12, my, tw, th)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print(text, mx + 20, my + 4)
end
```

## Inventory Grid

```lua
local SLOT_SIZE = 32
local SLOT_PAD  = 4

local function draw_inventory_grid(inv, ox, oy)
    for i = 1, inv.size do
        local col = (i - 1) % 5
        local row = math.floor((i - 1) / 5)
        local sx = ox + col * (SLOT_SIZE + SLOT_PAD)
        local sy = oy + row * (SLOT_SIZE + SLOT_PAD)
        luna.gfx.setColor(0.3, 0.3, 0.3, 0.9)
        luna.gfx.rectangle("fill", sx, sy, SLOT_SIZE, SLOT_SIZE)
        if inv.slots[i] then
            luna.gfx.setColor(1, 1, 1, 1)
            luna.gfx.print(inv.slots[i].id, sx + 2, sy + 2)
            luna.gfx.print(inv.slots[i].count, sx + 20, sy + 20)
        end
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.rectangle("line", sx, sy, SLOT_SIZE, SLOT_SIZE)
    end
    luna.gfx.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Drawing HUD in world space** — always pop camera transforms before HUD. Elements should not scroll with the world.
- **Hardcoded positions** — anchor to screen edges or percentages. Breaks on resolution change otherwise.
- **Color leak** — always reset `luna.gfx.setColor(1,1,1,1)` after drawing colored HUD elements.
- **Floaters accumulation** — remove dead floaters. Without cleanup, the table grows every hit.
- **Z-order** — draw HUD last. Tooltips last of all. Order: world → HUD → overlay → tooltip.
