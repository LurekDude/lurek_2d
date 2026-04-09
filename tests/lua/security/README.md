# tests/lua/security — Lua Security Tests

Adversarial tests for sandbox enforcement, nil spam, path traversal, and resource exhaustion from Lua.

## Naming

`test_<threat>.lua` — e.g. `test_invalid_args.lua`, `test_mount_traversal.lua`

## Coverage

- Lua sandbox: disallowed globals, Lua FFI restrictions
- `lurek.fs` path-traversal guard
- `lurek.savegame` validation against corrupt/path-traversal data
- TOML/config injection

## Harness

Dispatched by `tests/lua/harness.rs` — one `#[test]` per file.
