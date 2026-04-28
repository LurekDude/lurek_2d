---
description: "Create a new tilemap feature."
---

# Create Tilemap Feature

## Goal
- Create a new tilemap feature (layer type, autotile rule, collision mapping, or TMX extension). Follow the tilemap module's existing patte...

## Inputs
- SharedState

## Steps
- Load documentation before changing any files.
- **Define the feature scope**
- Which tilemap type is affected? (TileMap, IsoMap, ChunkMap, AutoTileSheet, TileSet)
- Is this a new layer type, a new operation, or an extension to existing behavior?
- Does it affect TMX (Tiled) import/export?
- **Implement in Rust**
- Add types/methods to src/tilemap/ following existing patterns
- Use pub for cross-module types, pub(crate) when possible
- Error handling: EngineError for internal errors, LuaResult for Lua-facing functions
- Respect dependency direction: tilemap may depend on math, must NOT depend on graphics/engine
- **Add Lua bindings** (if user-facing)
- Add to src/lua_api/tilemap_api.rs following the register() pattern

## Success Criteria
- [ ] Feature compiles with 0 clippy warnings
- [ ] Integration tests pass
- [ ] Lua bindings follow lurek.tilemap.* naming
- [ ] Public types have /// doc comments
- [ ] No dependency direction violations

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-tilemap-feature <SharedState>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation
- **Inputs required**: SharedState
