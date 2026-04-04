# Lunasome ÔÇö Luna2D Standard Library

The `library/` folder is Tier 3 in Luna2D's active layer model. It contains pure-Lua gameplay libraries that ship alongside the engine but are not embedded in the binary.

## Layer Contract

- Baseline, Tier 1, and Tier 2 live in the Rust runtime under `src/`.
- `src/lua_api/` is the bridge that exposes the public `luna.*` surface.
- Tier 3 lives here in `library/`.
- Lunasome modules consume public `luna.*` APIs and other Lua modules; the Rust engine does not depend on `library/`.
- `examples/` is a consumer of the public Lua surface, not part of the numbered layer model.

## Deliverables

| Deliverable | Role |
|---|---|
| `luna2d[.exe]` | Engine runtime binary ÔÇö windowing, GPU, physics, audio, input, filesystem |
| `library/` | Lunasome standard library ÔÇö pure-Lua gameplay systems |
| `examples/` | Reference games and verification targets built on the public Lua surface |

## Usage

```lua
-- Load a library module from any main.lua:
local dialog = require("library.dialog")
local item = require("library.item")
local inventory = require("library.inventory")
```

The engine automatically adds the correct search paths so `require("library.*")` resolves to the `library/` folder placed next to the engine binary or game directory.

## Module Index

| Module | Description | Status |
|---|---|---|
| `library.dialog` | Typewriter dialog sequencer with choices, waits, and call nodes | Ôťů Full |
| `library.item` | Item type catalog, pools, stacks, builders, and history | Ôťů Full |
| `library.inventory` | Containers, weighted bags, slots, and inventories | Ôťů Full |
| `library.province_map` | Province maps, Voronoi generation, map modes (wraps `luna.province`) | Ôťů Proxy |
| `library.quest` | Quest tracking, objectives, and branching completion states | ­čöž Stub |
| `library.battle` | Turn-based battle system ÔÇö combatants, actions, and turn order | ­čöž Stub |
| `library.stats` | Character attributes, derived stats, and modifiers | ­čöž Stub |
| `library.economy` | Named resource economy with flow rates, decay, and conversions | ­čöž Stub |
| `library.crafting` | Recipe system, ingredient matching, and crafting queues | ­čöž Stub |
| `library.cardgame` | Cards, stacks, deck building, slots, and card pools | ­čöž Stub |
| `library.combat` | Vehicle combat ÔÇö chassis, turrets, weapons, and projectiles | ­čöž Stub |

## Validation

There is no separate `library/tests/` tree today. Library behavior is currently verified through the Lua harness in `tests/lua/unit/`, including `test_library_dialog.lua` and `test_library_quest.lua`. When you add or change a library module, add or update coverage there and, when relevant, verify a representative example under `examples/`.

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
