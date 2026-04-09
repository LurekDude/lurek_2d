# Inventory System

Item storage, stacking, transfer, equipped state, and serialization for RPG/adventure games.

## Key Concepts

- **Item definition**: Separate item *data* (name, max_stack, icon) from *instance* (count, slot).
- **Stacking**: Group identical items up to `max_stack`. Overflow creates a new slot.
- **Transfer**: Move items between inventories (player ↔ chest) with slot-level operations.
- **Equipped slots**: Named slots (weapon, armor, accessory) with type restrictions.
- **Serialization**: Convert inventory to a plain table for saving via `luna.data.encodeToml`.

## Item Database

```lua
local ITEMS = {
    sword    = { name = "Iron Sword",   type = "weapon",     max_stack = 1, atk = 5 },
    potion   = { name = "Health Potion", type = "consumable", max_stack = 20 },
    wood     = { name = "Wood",          type = "material",   max_stack = 99 },
    ring     = { name = "Silver Ring",   type = "accessory",  max_stack = 1, def = 2 },
}
```

## Inventory Table

```lua
local function new_inventory(size)
    local inv = { slots = {}, size = size }
    for i = 1, size do inv.slots[i] = nil end
    return inv
end

local function add_item(inv, item_id, count)
    count = count or 1
    local def = ITEMS[item_id]
    -- Try stacking into existing slots
    for i = 1, inv.size do
        local slot = inv.slots[i]
        if slot and slot.id == item_id and slot.count < def.max_stack then
            local space = def.max_stack - slot.count
            local added = math.min(count, space)
            slot.count = slot.count + added
            count = count - added
            if count <= 0 then return true end
        end
    end
    -- Place in empty slots
    for i = 1, inv.size do
        if not inv.slots[i] then
            local placed = math.min(count, def.max_stack)
            inv.slots[i] = { id = item_id, count = placed }
            count = count - placed
            if count <= 0 then return true end
        end
    end
    return false  -- overflow
end

local function remove_item(inv, item_id, count)
    count = count or 1
    for i = inv.size, 1, -1 do
        local slot = inv.slots[i]
        if slot and slot.id == item_id then
            local removed = math.min(count, slot.count)
            slot.count = slot.count - removed
            count = count - removed
            if slot.count <= 0 then inv.slots[i] = nil end
            if count <= 0 then return true end
        end
    end
    return false  -- not enough
end
```

## Equipped Slots

```lua
local equipment = { weapon = nil, armor = nil, accessory = nil }

local function equip(inv, slot_index, equip_slot)
    local slot = inv.slots[slot_index]
    if not slot then return false end
    local def = ITEMS[slot.id]
    if def.type ~= equip_slot then return false end
    -- Swap with current equipment
    local old = equipment[equip_slot]
    equipment[equip_slot] = slot.id
    inv.slots[slot_index] = nil
    if old then add_item(inv, old, 1) end
    return true
end
```

## Serialization

```lua
local function serialize_inventory(inv)
    local data = {}
    for i = 1, inv.size do
        if inv.slots[i] then
            data[#data + 1] = { slot = i, id = inv.slots[i].id, count = inv.slots[i].count }
        end
    end
    return data
end
```

## Common Pitfalls

- **Item data vs instance** — never duplicate `name`/`max_stack` into each slot. Store only `id` + `count`.
- **Off-by-one on full inventory** — always check return value of `add_item`. Drop or reject excess.
- **Equip without unequip** — always swap back to inventory, don't silently discard the old item.
- **Saving item references** — serialize item IDs (strings), not Lua table references.
- **Stack overflow** — when `max_stack` is 1, stacking logic must skip to empty slots immediately.
