# Library Module Integration

How to use `library/` Lunasome modules inside `content/games/`.

---

## Module Status

Only use **✅ Full** modules. Stub modules compile but produce runtime errors.

| Module | Status | Require Path | What It Provides |
|--------|--------|--------------|-----------------|
| `dialog` | ✅ Full | `require("library.dialog")` | Typewriter sequencer, branching choices, event callbacks, call nodes |
| `item` | ✅ Full | `require("library.item")` | Item type definition, instance creation, stat lookup |
| `inventory` | ✅ Full | `require("library.inventory")` | Slot-based inventory — add/remove/query items |
| `province_map` | ✅ Proxy | `require("library.province_map")` | Province/region map (wraps `lurek.province`) |
| `battle` | 🔧 Stub | — | **Do not use** |
| `stats` | 🔧 Stub | — | **Do not use** |
| `economy` | 🔧 Stub | — | **Do not use** |
| `crafting` | 🔧 Stub | — | **Do not use** |
| `cardgame` | 🔧 Stub | — | **Do not use** |
| `combat` | 🔧 Stub | — | **Do not use** |
| `quest` | 🔧 Stub | — | **Do not use** |

---

## Import Pattern

Place `require()` calls at the **top of `main.lua`**, immediately after the header comment block
and before any other code:

```lua
-- content/games/loot_rpg_demo/main.lua
-- Loot RPG Demo — item drops, inventory management, stat display
-- Controls: Arrow keys to move, Space to pick up
-- Run with: cargo run -- content/games/loot_rpg_demo

local item      = require("library.item")
local inventory = require("library.inventory")

-- ── state ─────────────────────────────────────────────────────
local player = { x = 400, y = 300, inv = nil }
local drops  = {}
```

Engine search paths are configured so `require("library.X")` resolves to
`library/X.lua` relative to the engine binary or game directory.

---

## `library.dialog` — Full Usage Pattern

```lua
local dialog = require("library.dialog")

local seq   -- dialog sequencer, created in lurek.load
local current_line = ""
local current_speaker = ""
local choices  = {}

function lurek.init()
    lurek.window.setTitle("Dialog Demo")
    lurek.render.setBackgroundColor(0.06, 0.06, 0.06)

    -- Build sequence
    seq = dialog.newSequencer()
    seq:setSpeed(25)         -- characters per second

    -- Register line event — fires for each line of text
    seq:on("line", function(speaker, text)
        current_speaker = speaker
        current_line    = text
        choices = {}
    end)

    -- Register choice event — fires when player reaches a branch
    seq:on("choice", function(opts)
        choices = opts
    end)

    -- Load a script (array of node tables)
    seq:load({
        { node = "line",   speaker = "Guard", text = "Halt! Who goes there?" },
        { node = "choice", options = { "A traveler", "None of your business" } },
        { node = "call",   fn = function(choice)
            if choice == 1 then
                return { { node = "line", speaker = "Guard", text = "Pass, traveler." } }
            else
                return { { node = "line", speaker = "Guard", text = "Seize them!" } }
            end
        end },
    })
    seq:start()
end

function lurek.process(dt)
    seq:update(dt)
end

function lurek.render()
    -- dialog box at bottom 25% of screen
    lurek.render.setColor(0, 0, 0, 0.8)
    lurek.render.rectangle("fill", 20, 450, 760, 140)
    lurek.render.setColor(0.9, 0.9, 0.9)
    lurek.render.print(current_speaker .. ": " .. current_line, 30, 465)
    for i, opt in ipairs(choices) do
        lurek.render.print(i .. ". " .. opt, 40, 480 + i * 20)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    if key == "space" or key == "return" then
        if #choices == 0 then seq:advance() end
    end
    if key == "1" and choices[1] then seq:choose(1) end
    if key == "2" and choices[2] then seq:choose(2) end
end
```

---

## `library.item` + `library.inventory` — Full Usage Pattern

```lua
local item      = require("library.item")
local inventory = require("library.inventory")

local player_inv
local world_drops = {}

function lurek.init()
    lurek.window.setTitle("Loot RPG")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.1)

    -- Define item types (do this once in lurek.load)
    item.clearTypes()
    item.defineType("health_potion", {
        category   = "consumable",
        base_stats = { heal = 50 },
        rarity     = "common",
    })
    item.defineType("sword", {
        category   = "weapon",
        base_stats = { attack = 12, speed = 1.2 },
        rarity     = "rare",
    })

    -- Create inventory (capacity in slots)
    player_inv = inventory.new(20)

    -- Spawn some world drops
    table.insert(world_drops, {
        x    = 300, y = 300,
        inst = item.create("health_potion"),
    })
    table.insert(world_drops, {
        x    = 450, y = 250,
        inst = item.create("sword"),
    })
end

function lurek.process(dt)
    -- pick up item if player is close enough
    for i = #world_drops, 1, -1 do
        local d = world_drops[i]
        if math.abs(player.x - d.x) < 32 and math.abs(player.y - d.y) < 32 then
            if inventory.add(player_inv, d.inst) then
                table.remove(world_drops, i)
            end
        end
    end
end

function lurek.render()
    -- draw world drops
    for _, d in ipairs(world_drops) do
        lurek.render.setColor(1, 0.8, 0.2)
        lurek.render.circle("fill", d.x, d.y, 8)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print(d.inst.type_id, d.x + 10, d.y - 6)
    end

    -- draw inventory sidebar
    lurek.render.setColor(0.1, 0.1, 0.2, 0.9)
    lurek.render.rectangle("fill", 620, 10, 170, 300)
    lurek.render.setColor(0.8, 0.8, 1)
    lurek.render.print("Inventory", 630, 16)
    local slots = inventory.getSlots(player_inv)
    for i, slot in ipairs(slots) do
        if slot then
            lurek.render.print(slot.type_id, 630, 16 + i * 18)
        end
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
end
```

---

## Rules When Using Library Modules

1. **Import at the top** — never inside a callback or conditional block
2. **Init in `lurek.load()` only** — call `item.clearTypes()`, `inventory.new()`, etc. in load
3. **Never require stubs** — check the status table above before adding a require
4. **Interleave freely** — library calls and `lurek.*` calls can appear in the same callback
5. **No `lurek.item = require(...)` aliasing** — bind to a `local` variable always
6. **Smoke tests**: library-using demos should still implement the smoke-test pattern if screenshot automation is needed

---

## Adding a New `require` Path to `README.md`

When a demo uses a library module, the `content/games/README.md` key APIs column should list it:
```markdown
| [loot_rpg_demo](#loot_rpg_demo) | Item drops and inventory system | `item`, `inventory`, `graphics` |
```
