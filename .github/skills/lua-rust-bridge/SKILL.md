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
- Thin Wrapper Rule applies: src/lua_api/*_api.rs owns bindings, conversions, and registration only, while business logic stays in src/<module>/.
- Push mlua-heavy code to the boundary and keep engine decisions in domain modules; mixing them makes borrow bugs and review confusion much more likely.
- Registry keys own long-lived callbacks and closures; borrowed Lua functions should not escape their immediate call unless the lifetime and ownership are made explicit.
- RefCell and SharedState borrows cannot safely survive callback edges or long-lived closures, so boundary code should release borrows before invoking user-controlled Lua.
- Keep table, tuple, userdata, and enum-like conversions explicit so Lua-visible shapes stay predictable and generated docs remain trustworthy.
- Convert errors at the right layer: preserve internal context in Rust, but expose a clear Lua-facing failure that matches the public contract.
- Registration code should stay declarative and easy to audit; hidden side effects during module registration make startup and doc generation harder to reason about.
- After boundary changes, validate docstrings and conventions with validate_lua_api.py because the bridge layer also feeds generated docs and structural checks.
- Binding quality in this repo depends on thin files, explicit conversions, safe callback ownership, and no business logic hidden in src/lua_api/*.
- When a boundary function starts accumulating policy, that is usually a sign to move behavior back into the owning module and keep the bridge thin again.
- This skill owns boundary mechanics, userdata and callback handling, and conversion discipline, not user-facing API semantics, runtime tuning, or general Rust architecture.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/mod.rs
- tools/validate/validate_lua_api.py
- docs/specs/lua-api-file-standard.md
