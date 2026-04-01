---
description: "Debug and fix Lua script errors in Luna2D. Use when a Lua game script exits with an error, panics the engine, or produces unexpected mlua error messages. Produces a root-cause diagnosis and fix."
---

# Fix Lua Error

**Purpose**: Diagnose and fix Lua errors thrown inside the Luna2D engine at runtime.
**Use When**: A `main.lua` script exits with an `mlua` error, `attempt to index a nil value`, `bad argument`, stack overflow, or similar Lua-side failure.
**Do Not Use When**: The crash is a Rust panic (not an mlua `LuaError`) — use `fix-engine-bug.prompt.md` instead.
**Scope**: `src/lua_api/`, `src/engine/app.rs`, and the affected Lua script.

## Inputs

- `ERROR_MSG` — the full error message (including Lua traceback if available)
- `SCRIPT_PATH` — path to the `main.lua` file or example directory
- `REPRODUCTION` — minimal steps to reproduce (e.g., `cargo run -- examples/my_game`)

## Steps

1. Load skill `dev-debugging/SKILL.md`
2. Parse the error message:
   - `attempt to index a nil value (global 'luna')` → `luna` table not constructed; check `create_lua_vm()`
   - `bad argument #N to '<func>'` → argument type mismatch; check Lua call vs Rust binding signature
   - `attempt to call a nil value` → function not registered; check `register()` in `lua_api/mod.rs`
   - Stack overflow → recursive `update`/`draw` callback calling itself
3. Find the Rust binding for the failing function in `src/lua_api/<module>_api.rs`
4. Compare the Lua call signature against the Rust `create_function` argument types
5. Check that the function is registered:
   - `src/lua_api/mod.rs` — `<module>_api::register(&lua, &luna, state.clone())?`
   - `luna.set("<name>", ...)` in the corresponding `register()` function
6. Fix the mismatch (either the Lua script or the binding — prefer fixing the binding if the API is ambiguous)
7. Add a guard or descriptive error via `lua.create_error_from_string()` where possible
8. Verify: `cargo run -- <SCRIPT_PATH>`

## Outputs

- Root-cause explanation (Lua script bug, binding mismatch, or missing registration)
- Fix applied (Rust or Lua side, with reasoning)
- Verified: `cargo run -- <SCRIPT_PATH>` succeeds

## Acceptance

- [ ] The specific error no longer occurs
- [ ] Fix does not break other examples (`cargo run -- examples/hello_world`)
- [ ] If binding was incorrect, a regression test is added

## References

**Required Skills**: `dev-debugging`, `lua-api-design`
**Suggested Agents**: `Debugger`, `Developer`
**Related Prompts**: `fix-api-function.prompt.md`, `fix-engine-bug.prompt.md`
**Commands**:
```powershell
cargo run -- <SCRIPT_PATH>
cargo run -- examples/hello_world
```
**Docs**: `docs/lua_api_reference.md`, `src/lua_api/mod.rs`
