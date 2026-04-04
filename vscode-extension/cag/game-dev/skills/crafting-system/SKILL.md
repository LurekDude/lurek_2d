# Crafting System

Recipe tables, ingredient matching, multiple outputs, station restrictions, and discovery mechanics.

## Key Concepts

- **Recipe table**: Each recipe has a list of inputs (item_id + count) and one or more outputs.
- **Fuzzy matching**: Check if inventory contains all required ingredients regardless of slot order.
- **Station restriction**: Some recipes require a specific crafting station (forge, alchemy table).
- **Discovery**: Recipes start hidden. Unlock by finding a scroll, or auto-discover when ingredients are available.
- **Multiple outputs**: A recipe can produce several items (e.g., wood plank recipe yields 4 planks).

## Recipe Definition

```lua
local RECIPES = {
    {
        id = "iron_sword",
        station = "forge",
        inputs  = { { id = "iron_bar", count = 3 }, { id = "wood", count = 1 } },
        outputs = { { id = "sword", count = 1 } },
    },
    {
        id = "health_potion",
        station = "alchemy",
        inputs  = { { id = "herb", count = 2 }, { id = "water", count = 1 } },
        outputs = { { id = "potion", count = 1 } },
    },
    {
        id = "wood_plank",
        station = nil,  -- no station needed
        inputs  = { { id = "wood", count = 1 } },
        outputs = { { id = "plank", count = 4 } },
    },
}
```

## Checking Craftability

```lua
local function can_craft(inv, recipe, current_station)
    if recipe.station and recipe.station ~= current_station then return false end
    for _, req in ipairs(recipe.inputs) do
        if count_item(inv, req.id) < req.count then return false end
    end
    return true
end

local function count_item(inv, item_id)
    local total = 0
    for i = 1, inv.size do
        local slot = inv.slots[i]
        if slot and slot.id == item_id then total = total + slot.count end
    end
    return total
end
```

## Crafting Execution

```lua
local function craft(inv, recipe, current_station)
    if not can_craft(inv, recipe, current_station) then return false end
    -- Remove inputs
    for _, req in ipairs(recipe.inputs) do
        remove_item(inv, req.id, req.count)
    end
    -- Add outputs
    for _, out in ipairs(recipe.outputs) do
        if not add_item(inv, out.id, out.count) then
            -- Inventory full — drop on ground or reject
            return false
        end
    end
    return true
end
```

## Available Recipes List

```lua
local function get_available_recipes(inv, station)
    local available = {}
    for _, recipe in ipairs(RECIPES) do
        if can_craft(inv, recipe, station) then
            available[#available + 1] = recipe
        end
    end
    return available
end
```

## Discovery System

```lua
local discovered = {}

local function discover_recipe(recipe_id)
    discovered[recipe_id] = true
end

local function is_discovered(recipe_id)
    return discovered[recipe_id] == true
end

-- Auto-discover: check on inventory change
local function auto_discover(inv)
    for _, recipe in ipairs(RECIPES) do
        if not is_discovered(recipe.id) then
            local has_all = true
            for _, req in ipairs(recipe.inputs) do
                if count_item(inv, req.id) < 1 then has_all = false; break end
            end
            if has_all then discover_recipe(recipe.id) end
        end
    end
end
```

## UI: Crafting Menu

```lua
local function draw_craft_menu(recipes, selected)
    for i, r in ipairs(recipes) do
        local y = 50 + (i - 1) * 24
        local color = (i == selected) and {1,1,0} or {1,1,1}
        luna.graphics.setColor(color[1], color[2], color[3], 1)
        local out = r.outputs[1]
        local label = ITEMS[out.id].name .. " x" .. out.count
        luna.graphics.print(label, 60, y)
    end
    luna.graphics.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Inputs not consumed on failure** — always check `can_craft` before removing items.
- **Inventory overflow** — if outputs don't fit, don't consume inputs. Or drop excess on the ground.
- **Station not checked** — player could craft forge recipes from anywhere. Always verify `current_station`.
- **Discovery leaks all recipes** — only show discovered recipes in the UI. Keep undiscovered ones hidden.
- **Recipe conflicts** — if two recipes share the same inputs, let the player choose. Don't auto-pick.
