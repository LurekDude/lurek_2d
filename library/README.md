# Luna2D Standard Library

The `library/` folder contains the **Luna2D Standard Library** — pure-Lua gameplay
systems that ship alongside the engine but are not embedded in the binary.

## Three-Deliverable Model

| Deliverable | Description |
|---|---|
| `luna2d[.exe]` | Engine binary — GPU, physics, audio, input |
| `library/` | Standard Library — gameplay systems in Lua |
| `examples/` | Reference games — use both deliverables |

## Usage

```lua
-- Load a library module from any main.lua:
local dialog   = require("library.dialog")
local item     = require("library.item")
local inventory = require("library.inventory")
```

The engine automatically adds the correct search paths so `require("library.*")`
resolves to the `library/` folder placed next to the engine binary or game directory.

## Module Index

| Module | Description | Status |
|---|---|---|
| `library.dialog` | Typewriter dialog sequencer with choices, waits, and call nodes | ✅ Full |
| `library.item` | Item type catalog, pools, stacks, builders, and history | ✅ Full |
| `library.inventory` | Containers, weighted bags, slots, and inventories | ✅ Full |
| `library.province_map` | Province maps, Voronoi generation, map modes (wraps `luna.province`) | ✅ Proxy |
| `library.quest` | Quest tracking, objectives, and branching completion states | 🔧 Stub |
| `library.battle` | Turn-based battle system — combatants, actions, and turn order | 🔧 Stub |
| `library.stats` | Character attributes, derived stats, and modifiers | 🔧 Stub |
| `library.economy` | Named resource economy with flow rates, decay, and conversions | 🔧 Stub |
| `library.crafting` | Recipe system, ingredient matching, and crafting queues | 🔧 Stub |
| `library.cardgame` | Cards, stacks, deck building, slots, and card pools | 🔧 Stub |
| `library.combat` | Vehicle combat — chassis, turrets, weapons, and projectiles | 🔧 Stub |

## LDoc Conventions

All library modules use [LDoc](https://lunarmodules.github.io/ldoc/) docstrings:

```lua
--- One-sentence summary of the function.
-- @param name string Name of the thing.
-- @param opts table Optional configuration table.
-- @treturn table The created object.
function M.newThing(name, opts) end
```

## Generating Docs

```powershell
python tools/gen_lib_docs.py          # generate docs/API/libs/*.md per module
python tools/gen_lib_docs.py --check  # report modules missing doc coverage
```
