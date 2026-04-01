---
name: lua-sandbox-design
description: "Load this skill when implementing or auditing the Lua VM sandbox in Luna2D: library selection, global nulling, path traversal prevention, or error message hygiene. Skip it for lua.* API surface design, Rust engine internals, or game scripting."
---

# Lua Sandbox Design — Luna2D Engine

## Load When

- Modifying `create_lua_vm()` in `src/lua_api/mod.rs`
- Reviewing which standard libraries are opened
- Adding filesystem access through `GameFS`
- Hardening against path traversal or null-byte injection
- Deciding whether to expose `require` or module loading

## Owns

- Standard library allowlist and denylist for mlua
- Global nulling strategy after `Lua::new()` / `open_libs()`
- `GameFS` path validation rules
- Error message sanitization before Lua sees them

## Does Not Cover

- `luna.*` API naming conventions → use `lua-api-design` skill
- Rust safety patterns → use `rust-coding` skill
- GameFS caching or asset formats → use `asset-pipeline` skill

## Live Repository Contracts

- `src/lua_api/mod.rs` — `create_lua_vm(state)`: opens libs, registers all API modules
- `src/filesystem/vfs.rs` — `GameFS`: sandboxed read-only access within the game directory
- `src/lua_api/filesystem_api.rs` — Lua bindings for `GameFS` (`luna.fs.*`)

## Decision Rules

### Library Allowlist — Open Only These

| Library    | mlua flag             | Reason kept  |
| ---------- | --------------------- | ------------ |
| `math`     | `StdLib::MATH`        | Deterministic, pure |
| `string`   | `StdLib::STRING`      | String manipulation |
| `table`    | `StdLib::TABLE`       | Data structures |
| `coroutine`| `StdLib::COROUTINE`   | Cooperative tasks |
| `utf8`     | `StdLib::UTF8`        | Text encoding |

### Library Denylist — Never Open

- **`os`** — system commands, clock, environment variables, process control
- **`io`** — raw file I/O bypasses `GameFS` entirely
- **`debug`** — bypasses metatables, exposes stack frames, allows arbitrary upvalue mutation; especially dangerous because it can undo any sandbox restriction set via `__index`/`__newindex`
- **`package` / `require`** — loads arbitrary Lua files or C extensions from the filesystem

### Global Nulling After VM Init

After opening allowed libs, nil out any dangerous globals that mlua may surface:

> See [example.lua](example.lua) for the global nulling after vm init code example.

- `rawget` / `rawset` are low-risk but should be audited: they bypass `__index`/`__newindex`, so if any sandboxing relies on metatables, nil them out too.
- Do not expose `collectgarbage` (timing oracle) or `print` if a custom print binding is provided.

### Module Loading — No `require`

- Luna2D does **not** support Lua module loading. `require` is nil'd after VM init.
- If multi-file scripts are needed, provide `luna.include(path)` via `GameFS` with the same path validation rules, never raw `require`.

### GameFS Path Validation

1. **Canonicalize** the joined path (`game_root + "/" + user_path`) before any I/O.
2. **Prefix check**: after canonicalization the result must start with `game_root`; reject otherwise.
3. **Null-byte rejection**: reject any path containing `\0` before joining — Rust `Path` silently truncates at null bytes on some platforms.
4. **Deny absolute paths**: reject any user-supplied path starting with `/`, `\`, or a drive letter (`C:`).

### Error Message Hygiene

- Catch Lua errors at the engine boundary (`engine/app.rs` / `create_lua_vm`).
- Strip Rust source paths (`src/...`, `luna2d/...`) from error strings before displaying to the user.
- Expose only: script file name, Lua line number, and the error message itself.
- Never forward `LuaError::RuntimeError` with the raw internal `Display` directly to game scripts.
