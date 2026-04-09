# tests/lua/library — Lua Library Tests

One test file per Lunasome `library/` module (Tier 3 pure-Lua).

## Naming

`test_<library>.lua` — e.g. `test_battle.lua`, `test_inventory.lua`

## Coverage

Tests exercise the library's public API using only lurek.* engine primitives.
No Rust engine internals may be accessed from library test code.

## Harness

Dispatched by `tests/lua/harness.rs` — one `#[test]` per file.
