---
description: "Debug and fix Lua script errors in Lurek2D. Use when a Lua game script exits with an error, panics the engine, or produces unexpected mlu..."
agent: Debugger
---
# Fix Lua Error

## Goal

Debug and fix Lua script errors in Lurek2D. Use when a Lua game script exits with an error, panics the engine, or produces unexpected mlu... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `ERROR_MSG` — the full error message (including Lua traceback if available)
- `SCRIPT_PATH` — path to the `main.lua` file or example directory
- `REPRODUCTION` — minimal steps to reproduce (e.g., `cargo run -- content/examples/my_game`)

## Steps

1. Load [skill: dev-debugging](.github/skills/dev-debugging/SKILL.md), [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Load skill `dev-debugging/SKILL.md`
3. Parse the error message:
4. `attempt to index a nil value (global 'luna')` → `luna` table not constructed; check `create_lua_vm()`
5. `bad argument #N to '<func>'` → argument type mismatch; check Lua call vs Rust binding signature
6. `attempt to call a nil value` → function not registered; check `register()` in `lua_api/mod.rs`
7. Stack overflow → recursive `update`/`draw` callback calling itself
8. Find the Rust binding for the failing function in `src/lua_api/<module>_api.rs`
9. Compare the Lua call signature against the Rust `create_function` argument types
10. Check that the function is registered:
11. `src/lua_api/mod.rs` — `<module>_api::register(&lua, &luna, state.clone())?`
12. `lurek.set("<name>", ...)` in the corresponding `register()` function

## Success Criteria

- [ ] Root-cause explanation (Lua script bug, binding mismatch, or missing registration)
- [ ] Fix applied (Rust or Lua side, with reasoning)
- [ ] Verified: `cargo run -- <SCRIPT_PATH>` succeeds

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-lua-error <SCRIPT_PATH> <func> <module> <name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: dev-debugging, lua-api-design
- **Inputs required**: SCRIPT_PATH, func, module, name
