---
description: "Create a new tilemap feature (layer type, autotile rule, collision mapping, or TMX extension). Follow the tilemap module's existing patte..."
agent: Developer
tools: [tools/docs/gen_docs_lua.py]
---
# Create Tilemap Feature

## Goal

Create a new tilemap feature (layer type, autotile rule, collision mapping, or TMX extension). Follow the tilemap module's existing patte... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `SharedState` — value supplied by the user invocation.

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md) before changing any files.
2. **Define the feature scope**
3. Which tilemap type is affected? (TileMap, IsoMap, ChunkMap, AutoTileSheet, TileSet)
4. Is this a new layer type, a new operation, or an extension to existing behavior?
5. Does it affect TMX (Tiled) import/export?
6. **Implement in Rust**
7. Add types/methods to `src/tilemap/` following existing patterns
8. Use `pub` for cross-module types, `pub(crate)` when possible
9. Error handling: `EngineError` for internal errors, `LuaResult` for Lua-facing functions
10. Respect dependency direction: tilemap may depend on math, must NOT depend on graphics/engine
11. **Add Lua bindings** (if user-facing)
12. Add to `src/lua_api/tilemap_api.rs` following the `register()` pattern

## Success Criteria

- [ ] Feature compiles with 0 clippy warnings
- [ ] Integration tests pass
- [ ] Lua bindings follow `lurek.tilemap.*` naming
- [ ] Public types have `///` doc comments
- [ ] No dependency direction violations

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-tilemap-feature <SharedState>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation
- **Inputs required**: SharedState
