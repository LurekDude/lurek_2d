# tests/lua/unit — Lua Unit Tests

One test file per `lurek.*` engine module and per `library/` Lunasome module.

## Naming

`test_<module>.lua` — e.g. `test_audio.lua`, `test_physics.lua`

## Coverage

Each file uses the BDD framework from `tests/lua/init.lua` (`describe` / `it` / `expect_equal` / `expect_near` / `expect_error`)
and **must** end with `test_summary()`.

## Constraints

- No GPU, audio device, or window API calls — headless only
- Minimum 1 test per public `lurek.*` function before merge

## Harness

Dispatched by `tests/lua/harness.rs` — one `#[test]` per file.
