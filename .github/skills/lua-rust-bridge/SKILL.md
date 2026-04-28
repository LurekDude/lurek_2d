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
- Keep binding files thin and move business logic into domain modules.
- Clone shared state handles before moving them into closures.
- Do not hold RefCell borrows across Lua callback boundaries.
- Keep conversions explicit and predictable.
- Store long-lived Lua callbacks through registry keys, not borrowed function values.
- Validate binding conventions with the existing Lua API validator.

## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/mod.rs
- tools/validate/validate_lua_api.py