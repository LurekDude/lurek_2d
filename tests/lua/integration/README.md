# tests/lua/integration — Lua Integration Tests

Tests that verify two or more `lurek.*` modules working together. Both namespaces must appear in each file.

## Naming

`test_<module1>_<module2>.lua` — e.g. `test_physics_timer.lua`, `test_entity_ai.lua`

## Rules

- Minimum 2 distinct `lurek.*` namespaces per file
- Headless — no GPU/audio/window calls
- Each file ends with `test_summary()`

## Harness

Dispatched by `tests/lua/harness.rs` — one `#[test]` per file.
