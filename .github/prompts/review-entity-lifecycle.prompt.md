---
description: "Review entity lifecycle patterns for correctness: spawn, alive check, kill, ID recycling, blueprint usage, and layer organization. Use when auditing or debugging entity management code."
---

# Review Entity Lifecycle

## Prerequisites

- Read `src/entity/mod.rs` for Universe types
- Read `src/lua_api/entity_api.rs` for Lua bindings
- Read `tests/rust/unit/entity_tests.rs` for test patterns
- Load the `ecs-architecture` skill

## Steps

1. **Check ID management**
   - IDs are sequential on first spawn (1, 2, 3, ...)
   - Killed IDs recycle in LIFO order (last killed = first reused)
   - Verify `is_alive()` check before entity access
   - Confirm no stale ID references after kill

2. **Check lifecycle ordering**
   - Entities spawned during `lurek.update()` only — never during `lurek.draw()`
   - Entities killed during `lurek.update()` only — never during `lurek.draw()`
   - Blueprint application happens at spawn time

3. **Check tag/layer usage**
   - Bitmap tags for fast group membership queries
   - Layers for spatial/functional entity grouping
   - No duplicate entities across layers unless intentional

4. **Check blueprint patterns**
   - Blueprints define reusable entity templates
   - Blueprint data is copied at spawn — not shared by reference
   - Blueprint changes don't affect already-spawned entities

5. **Verify test coverage**
   - Spawn → alive → kill → recycle cycle tested
   - Tag query correctness tested
   - Layer membership tested
   - Blueprint application tested
   - Edge case: kill-and-recycle in same frame

## Acceptance Criteria

- [ ] No stale ID references in game logic
- [ ] All mutations happen in `lurek.update()`, not `lurek.draw()`
- [ ] ID recycling follows LIFO order
- [ ] Blueprint patterns are copy-on-spawn
- [ ] Tests cover the full lifecycle
