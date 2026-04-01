---
applyTo: "src/lua_api/**"
---

# Lua API Instructions

All files in `src/lua_api/` bind Rust engine state to the `luna.*` Lua namespace. Every binding must use the `register()` pattern, capture `Rc<RefCell<SharedState>>`, and never perform rendering inside a Lua closure.

## Core Rules

- **`luna.*` namespace only** — never external engine prefixes, `game.*`, or any other prefix
- **Registration pattern**: every file must expose `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- **Clone the Rc before moving into closure**: `let s = state.clone(); lua.create_function(move |_, args| { let st = s.borrow(); ... })`
- **Return `LuaResult<T>`** from all Lua-callable functions — never panic inside a Lua closure
- **No rendering inside Lua closures** — push a `DrawCommand` variant to `state.borrow_mut().draw_commands` and return; the engine renders after `luna.draw()` returns
- **String keys lowercase**: `"space"`, `"escape"`, `"a"`, `"left"` — never uppercase, never platform-specific names

## Layer / Boundary Rules

- `lua_api/mod.rs` owns `SharedState` struct definition and `create_lua_vm()` — no other file defines state
- Sub-API files (`graphics_api.rs`, `audio_api.rs`, etc.) must only import from `crate::graphics`, `crate::physics`, etc. — never cross-import between sub-API files
- Physics worlds stored separately from `SharedState` — use `Rc<RefCell<Vec<World>>>` passed alongside state

## Compliance

- Every new `luna.*` function must be documented in `docs/lua_api_reference.md`
- Key names must match the mapping in `src/input/keyboard.rs::key_to_string()`
- All mouse button indices: 1 = left, 2 = right, 3 = middle

## Avoid

- `.unwrap()` on `state.borrow()` — use `?` or handle the `BorrowError`
- Storing non-`Clone`/non-`'static` references in Lua closures
- Direct winit or wgpu API calls inside `lua_api/` — go through the engine abstraction
- Exposing internal engine types directly to Lua — wrap in safe userdata or return primitives
- Creating a new `Rc<RefCell<>>` for state that already exists in `SharedState`
