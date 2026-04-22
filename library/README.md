# Lunasome â€” Lurek2D Standard Library

The `library/` folder is Tier 3 in Lurek2D's active layer model. It contains pure-Lua gameplay libraries that ship alongside the engine but are not embedded in the binary.

## Layer Contract

- Baseline, Tier 1, and Tier 2 live in the Rust runtime under `src/`.
- `src/lua_api/` is the bridge that exposes the public `lurek.*` surface.
- Tier 3 lives here in `library/`.
- Lunasome modules consume public `lurek.*` APIs and other Lua modules; the Rust engine does not depend on `library/`.
- `content/demos/` is a consumer of the public Lua surface, not part of the numbered layer model.

## Deliverables

| Deliverable        | Role                                                                      |
| ------------------ | ------------------------------------------------------------------------- |
| `lurek2d[.exe]`    | Engine runtime binary â€” windowing, GPU, physics, audio, input, filesystem |
| `library/` | Lunasome standard library â€” pure-Lua gameplay systems                     |
| `content/demos/`   | Reference games and verification targets built on the public Lua surface  |

## Usage

```lua
-- Load a library module from any main.lua:
local dialog    = require("library.dialog")
local item      = require("library.item")
local inventory = require("library.inventory")
local scheduler = require("library.scheduler")
```

The engine automatically adds the correct search paths so `require("library.*")` resolves to the `library/` folder placed next to the engine binary or game directory.

## Module Index

| Module                 | Description                                                                   | Status  |
| ---------------------- | ----------------------------------------------------------------------------- | ------- |
| `library.battle`       | Turn-based battle system â€” combatants, actions, and turn order                | Stub    |
| `library.cardgame`     | Cards, stacks, deck building, slots, and card pools                           | Stub    |
| `library.combat`       | Vehicle combat â€” chassis, turrets, weapons, and projectiles                   | Stub    |
| `library.crafting`     | Recipe system, ingredient matching, and crafting queues                       | Stub    |
| `library.dialog`       | Typewriter dialog sequencer with choices, waits, and call nodes               | Full    |
| `library.doll`         | Paper-doll equip/render scaffolding                                           | Stub    |
| `library.economy`      | Named resource economy with flow rates, decay, and conversions                | Stub    |
| `library.inventory`    | Containers, weighted bags, slots, and inventories                             | Full    |
| `library.item`         | Item type catalog, pools, stacks, builders, and history                       | Full    |
| `library.lobby`        | Pre-game lobby & room manager built on `lurek.network`                        | Full    |
| `library.netstate`     | Authority-driven state replication & turn-based protocol on `lurek.network`   | Full    |
| `library.patterns`     | **Deprecated 0.6.0** â€” proxy that forwards to `library.scheduler`             | Proxy   |
| `library.province_map` | Province maps, Voronoi generation, map modes (wraps `lurek.image`)              | Full    |
| `library.quest`        | Quest tracking, objectives, and branching completion states                   | Stub    |
| `library.rpc`          | Remote procedure calls over `lurek.network`                                   | Full    |
| `library.scheduler`    | Pure-Lua coroutine scheduler driven by `:update(dt)` (was `library.patterns`) | Full    |
| `library.stats`        | Character attributes, derived stats, and modifiers                            | Stub    |
| `library.loot`         | Walkerâ€“Vose alias weighted RNG, drop DSL, and pity timers                     | Full    |
| `library.narrative`    | Ink-flavoured branching narrative interpreter (knots, choices, variables)     | Partial |
| `library.roguelike`    | Shadowcasting FOV, energy scheduler, and Dijkstra goal maps                   | Full    |
| `library.cinematic`    | Multi-track scrubbable cutscene timeline (tween/camera/audio/dialog)          | Partial |
| `library.rhythm`       | BPM-locked event sequencer and judgement scoring over `lurek.audio`           | Full    |

## Validation

Library behaviour is verified through the Lua harness in `tests/lua/library/`,
with one `test_library_<name>.lua` file per module. Each new file is
manually registered in `tests/lua/harness.rs`. When you add or change a
library module, add or update coverage there and, when relevant, verify a
representative example under `content/demos/`.

## LDoc Conventions

All library modules use [LDoc](https://lunarmodules.github.io/ldoc/) docstrings:

```lua
--- One-sentence summary of the function.
-- @param name string Name of the thing.
-- @param opts table Optional configuration table.
-- @treturn table The created object.
function M.newThing(name, opts) end
```

Top-of-file headers should declare `@module library.<name>`,
`@status full|partial|stub|proxy`, and `@see lurek.<ns>.<fn>` cross-links
where the library wraps or composes a `lurek.*` surface.

## Generating Docs

```powershell
python tools/docs/gen_lib_docs.py          # generate docs/library/*.md per module
python tools/docs/gen_lib_docs.py --check  # report modules missing doc coverage
```
# Lunasome ďż˝ďż˝ďż˝ Lurek2D Standard Library

The `library/` folder is Tier 3 in Lurek2D's active layer model. It contains pure-Lua gameplay libraries that ship alongside the engine but are not embedded in the binary.

## Layer Contract

- Baseline, Tier 1, and Tier 2 live in the Rust runtime under `src/`.
- `src/lua_api/` is the bridge that exposes the public `lurek.*` surface.
- Tier 3 lives here in `library/`.
- Lunasome modules consume public `lurek.*` APIs and other Lua modules; the Rust engine does not depend on `library/`.
- `content/demos/` is a consumer of the public Lua surface, not part of the numbered layer model.

## Deliverables

| Deliverable        | Role                                                                        |
| ------------------ | --------------------------------------------------------------------------- |
| `lurek2d[.exe]`    | Engine runtime binary ďż˝ďż˝ďż˝ windowing, GPU, physics, audio, input, filesystem |
| `library/` | Lunasome standard library ďż˝ďż˝ďż˝ pure-Lua gameplay systems                     |
| `content/demos/`   | Reference games and verification targets built on the public Lua surface    |

## Usage

```lua
-- Load a library module from any main.lua:
local dialog = require("library.dialog")
local item = require("library.item")
local inventory = require("library.inventory")
```

The engine automatically adds the correct search paths so `require("library.*")` resolves to the `library/` folder placed next to the engine binary or game directory.

## Module Index

| Module                 | Description                                                                                                                                                      | Status    |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `library.dialog`       | Typewriter dialog sequencer with choices, waits, and call nodes                                                                                                  | Ôťďż˝ Full   |
| `library.item`         | Item type catalog, pools, stacks, builders, and history                                                                                                          | Ôťďż˝ Full   |
| `library.inventory`    | Containers, weighted bags, slots, and inventories                                                                                                                | Ôťďż˝ Full   |
| `library.province_map` | Pure-Lua province grid, adjacency graph, BFS routing, map modes, and event bus; uses `lurek.image.newProvinceGrid` only inside `M.newFromPng` for fast PNG loading | Full      |
| `library.quest`        | Quest tracking, objectives, and branching completion states                                                                                                      | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.battle`       | Turn-based battle system ďż˝ďż˝ďż˝ combatants, actions, and turn order                                                                                                 | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.stats`        | Character attributes, derived stats, and modifiers                                                                                                               | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.economy`      | Named resource economy with flow rates, decay, and conversions                                                                                                   | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.crafting`     | Recipe system, ingredient matching, and crafting queues                                                                                                          | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.cardgame`     | Cards, stacks, deck building, slots, and card pools                                                                                                              | ďż˝ďż˝ďż˝ďż˝ Stub |
| `library.combat`       | Vehicle combat ďż˝ďż˝ďż˝ chassis, turrets, weapons, and projectiles                                                                                                    | ďż˝ďż˝ďż˝ďż˝ Stub |

## Validation

There is no separate `library/tests/` tree today. Library behavior is currently verified through the Lua harness in `tests/lua/unit/`, including `test_library_dialog.lua` and `test_library_quest.lua`. When you add or change a library module, add or update coverage there and, when relevant, verify a representative example under `content/demos/`.

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
python tools/gen_lib_docs.py          # generate docs/library/*.md per module
python tools/gen_lib_docs.py --check  # report modules missing doc coverage
```

