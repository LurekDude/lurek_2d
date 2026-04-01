---
name: lua-api-design
description: "Load this skill when designing or modifying the luna.* Lua API surface. It owns naming conventions, parameter patterns, callback contracts, and API consistency rules. Skip it for Rust internals or pure Lua scripting."
---

# Lua API Design — Luna2D Engine

## Load When

- Adding a new `luna.*` function
- Changing an existing API signature
- Designing callback conventions
- Reviewing API consistency across modules

## Owns

- `luna.*` namespace structure and naming conventions
- Function parameter order and type conventions
- Callback registration patterns
- API consistency across modules (graphics, audio, physics, etc.)

## Does Not Cover

- Rust implementation of bindings → use `rust-coding` skill
- Writing Lua game scripts → use `lua-scripting` skill
- Performance of Lua/Rust boundary → use `performance-profiling` skill

## Live Repository Contracts

- `src/lua_api/mod.rs` — `register()` function pattern, SharedState
- `src/lua_api/graphics_api.rs` — `luna.graphics.*` bindings
- `src/lua_api/physics_api.rs` — `luna.physics.*` bindings
- `src/lua_api/audio_api.rs` — `luna.audio.*` bindings
- `docs/lua_api_reference.md` — API documentation

## Decision Rules

- **Namespace**: All functions under `luna.*` — NEVER external engine prefixes or any other prefix
- **Module pattern**: `luna.<module>.<function>()` (e.g., `luna.graphics.draw()`)
- **Registration**: Every API file exports `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- **Parameter conventions**: `dt` for delta time, `x, y` for coordinates, `key` for key names, `btn` for buttons
- **Key names**: Lowercase strings: `"space"`, `"escape"`, `"a"`, `"left"`, `"return"`
- **Return types**: `LuaResult<T>` for all Lua-callable functions
- **Error messages**: Descriptive, mention the function name and what went wrong
- **Callbacks**: `luna.load()`, `luna.update(dt)`, `luna.draw()`, `luna.keypressed(key)`, etc.
- **Consistency**: Similar functions across modules use the same parameter patterns
- **Documentation**: Every new function must appear in `docs/lua_api_reference.md`
