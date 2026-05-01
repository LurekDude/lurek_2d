---
description: "Add one tilemap feature: layer rendering, tile collision, or map loading."
---

# Create Tilemap Feature

## Goal
- Implement one bounded tilemap feature in the engine and its Lua binding.

## Inputs
- Feature goal.
- Target lurek.tilemap.* shape when public API changes.
- Rendering or collision concern.

## Steps
1. Load rust-coding, lua-rust-bridge, and gpu-programming before acting.
2. Read docs/specs/tilemap.md, src/tilemap/, src/lua_api/tilemap_api.rs, and the nearest tilemap test before editing.
3. Keep the tilemap rendering in the existing 2D pipeline.
4. Run the narrowest tilemap test or build check first.
5. Update docs/specs/tilemap.md when the contract changes.

## Success Criteria
- [ ] The feature stays inside the existing 2D tilemap pipeline.
- [ ] A test covers the new behavior.
- [ ] docs/specs/tilemap.md is updated if the contract changed.

## Example Invocation
- /create-tilemap-feature goal=layer_z_ordering
