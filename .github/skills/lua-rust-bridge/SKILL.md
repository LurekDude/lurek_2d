---
name: lua-rust-bridge
description: "Load this skill when writing Lua-Rust bindings, LuaUserData impls, type conversion, boundary errors, or SharedState borrow rules. Skip it for API design, game scripts, or pure Rust domain logic."
---
# lua-rust-bridge

## Mission
- Own binding-layer mechanics between Lua and Rust.

## When To Load
- Write or review LuaUserData code.
- Convert values across the Lua boundary.
- Handle boundary errors.
- Check SharedState borrow behavior in closures.

## When To Skip
- Public API design.
- Lua game script work.
- Pure Rust domain logic.

## Domain Knowledge
- Thin Wrapper Rule is a hard constraint: `src/lua_api/*_api.rs` contains only `LuaUserData` impls, `add_methods`, module registration, and type conversions. When a binding file contains `if/match/for` logic beyond conversion, it is drifting and the logic must move to `src/<module>/`.
- `UserData` types exposed to Lua must wrap a handle or an `Arc<>`-shared reference, not a raw struct. Raw structs bind Lua lifetimes to Rust lifetimes in ways that mlua cannot enforce safely.
- Registry key pattern for callbacks: `lua.create_registry_value(callback)?` stores a `LuaFunction` for later use. Never let a borrowed `LuaFunction` escape the current call stack — it will dangle when the Lua state advances.
- The borrow safety rule: extract all fields from `RefCell<>` or `Arc<Mutex<>>` before invoking any Lua-callable function. Pattern: `let x = { state.borrow().field.clone() }; lua.call(x)?`. The borrow must be fully dropped (scope closed) before the call.
- Type conversion checklist for each boundary function: (1) validate integer ranges before casting `i64` to `u32` or `usize`, (2) validate string content when enum-like, (3) clamp f32/f64 values to meaningful game ranges at the boundary, not deep in the module.
- `mlua::Error::RuntimeError(msg)` is the standard error type for Lua-visible failures. The message must include the `lurek.<module>.<function>` call site for content authors. Raw `mlua::Error::ExternalError` is for non-displayable engine faults.
- Registration function naming: `pub fn register(lua: &Lua, state: &SharedState) -> mlua::Result<()>`. Each `*_api.rs` exports exactly one `register` function, called from `src/lua_api/register.rs`.
- After modifying a binding, run `python tools/validate/validate_lua_api.py`. It checks that all registered functions have a docstring, that argument names match documented types, and that the generated stub stays in sync.
- `LuaUserData::add_methods` must call only `add_method`, `add_method_mut`, `add_function`, or `add_meta_method`. No side effects, no lazy-init, no global state changes inside `add_methods`.
- When a binding function exceeds ~20 lines, it is almost certainly doing too much. Split extraction, validation, domain call, and conversion into distinct steps and move the domain call to `src/<module>/`.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/mod.rs
- tools/validate/validate_lua_api.py
- docs/specs/lua-api-file-standard.md
