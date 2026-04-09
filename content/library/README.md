# Lunasome ��� Lurek2D Standard Library

The `content/library/` folder is Tier 3 in Lurek2D's active layer model. It contains pure-Lua gameplay libraries that ship alongside the engine but are not embedded in the binary.

## Layer Contract

- Baseline, Tier 1, and Tier 2 live in the Rust runtime under `src/`.
- `src/lua_api/` is the bridge that exposes the public `lurek.*` surface.
- Tier 3 lives here in `content/library/`.
- Lunasome modules consume public `lurek.*` APIs and other Lua modules; the Rust engine does not depend on `content/library/`.
- `content/demos/` is a consumer of the public Lua surface, not part of the numbered layer model.

## Deliverables

| Deliverable | Role |
|---|---|
| `lurek2d[.exe]` | Engine runtime binary ��� windowing, GPU, physics, audio, input, filesystem |
| `content/library/` | Lunasome standard library ��� pure-Lua gameplay systems |
| `content/demos/` | Reference games and verification targets built on the public Lua surface |

## Usage

```lua
-- Load a library module from any main.lua:
local dialog = require("library.dialog")
local item = require("library.item")
local inventory = require("library.inventory")
```

The engine automatically adds the correct search paths so `require("library.*")` resolves to the `content/library/` folder placed next to the engine binary or game directory.

## Module Index

| Module | Description | Status |
|---|---|---|
| `library.dialog` | Typewriter dialog sequencer with choices, waits, and call nodes | ԝ� Full |
| `library.item` | Item type catalog, pools, stacks, builders, and history | ԝ� Full |
| `library.inventory` | Containers, weighted bags, slots, and inventories | ԝ� Full |
| `library.province_map` | Province maps, Voronoi generation, map modes (wraps `lurek.province`) | ԝ� Proxy |
| `library.quest` | Quest tracking, objectives, and branching completion states | ���� Stub |
| `library.battle` | Turn-based battle system ��� combatants, actions, and turn order | ���� Stub |
| `library.stats` | Character attributes, derived stats, and modifiers | ���� Stub |
| `library.economy` | Named resource economy with flow rates, decay, and conversions | ���� Stub |
| `library.crafting` | Recipe system, ingredient matching, and crafting queues | ���� Stub |
| `library.cardgame` | Cards, stacks, deck building, slots, and card pools | ���� Stub |
| `library.combat` | Vehicle combat ��� chassis, turrets, weapons, and projectiles | ���� Stub |

## Validation

There is no separate `content/library/tests/` tree today. Library behavior is currently verified through the Lua harness in `tests/lua/unit/`, including `test_library_dialog.lua` and `test_library_quest.lua`. When you add or change a library module, add or update coverage there and, when relevant, verify a representative example under `content/demos/`.

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
