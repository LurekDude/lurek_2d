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
- Thin Wrapper Rule applies: src/lua_api/*_api.rs owns bindings, conversions, and registration only.
- Push business logic into src/<module>/ and keep mlua-heavy code at the boundary.
- Registry keys own long-lived callbacks; borrowed Lua functions should not escape their immediate call safely.
- RefCell and SharedState borrows cannot survive callback edges or long-lived closures.
- Keep table, tuple, and userdata conversions explicit so Lua-visible shapes stay predictable.
- After boundary changes, validate docstrings and conventions with validate_lua_api.py.
- Binding quality in this repo depends on thin files, explicit conversions, safe callback ownership, and no business logic hidden in src/lua_api/*.
- validate_lua_api.py and docstring standards are part of the bridge contract because the binding layer also feeds generated docs and validation.
- This skill owns boundary mechanics, not user-facing API semantics or general Rust architecture.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/mod.rs
- tools/validate/validate_lua_api.py
- docs/specs/lua-api-file-standard.md
