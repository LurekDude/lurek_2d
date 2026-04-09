# Doll Library

**Tier**: 3 — Lunasome (Pure Lua)
**Status**: Implemented
**Path**: `library/doll/`

## Responsibility

Socket-based visual composition for 2D characters. A DollTemplate defines
named sockets (attachment points with position, rotation, and draw order).
A Doll instance attaches Part visuals to sockets and produces a z-sorted
draw list with world-space transforms.

## Key Types

| Type | Constructor | Purpose |
|---|---|---|
| `Part` | `M.newPart()` | Visual element with texture, quad, offset, scale, color |
| `DollTemplate` | `M.newTemplate(name)` | Socket layout blueprint |
| `Doll` | `M.newDoll(template)` | Runtime instance — attach/detach parts, get draw list |

## API Surface

```lua
local Doll = require("library.doll")

local template = Doll.newTemplate("player")
template:addSocket({ name = "body", x = 0, y = 0, drawOrder = 0 })
template:addSocket({ name = "head", x = 0, y = -20, drawOrder = 1 })

local doll = Doll.newDoll(template)
doll:attach("body", Doll.newPart({ partType = "armor" }))
local drawList = doll:getDrawList()
```

## Dependencies

- None (pure Lua, optionally calls `luna.gfx` in `draw()`)

## Tests

- `tests/lua/library/test_library_doll.lua` — BDD test suite (Part, DollTemplate, Doll, getDrawList, hot-swap)
- Harness entry: `lua_test_library_doll` in `tests/lua/harness.rs`
