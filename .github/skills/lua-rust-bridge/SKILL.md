---
name: lua-rust-bridge
description: "Load this skill when designing or implementing the bridge between Rust engine modules and the lurek.* Lua API: creating UserData types, registration functions, binding domain types to Lua, or keeping src/lua_api/ thin. Use for: new Lua API modules, Lua↔Rust data conversion, AGENT.md↔lua_api sync. Skip it for domain Rust logic, game scripting, or GPU code."
---

# Lua↔Rust Bridge — Lurek2D

## Load When

- Creating a new `lurek.*` API module (`.rs` file in `src/lua_api/`)
- Wrapping a Rust domain type as a Lua `UserData` object
- Designing Lua-callable functions for a new subsystem
- Syncing `src/<module>/AGENT.md` ↔ `src/lua_api/<module>_api.rs`
- Converting data between Lua tables and Rust structs/enums
- Debugging `LuaError` messages or type mismatch panics at the Lua boundary

## Owns

- `pub fn register(lua, luna_table, state)` contract and code pattern
- Rc clone pattern before moving state into closures
- `UserData` wrapping and `LunaType` trait
- Lua↔Rust data conversion patterns (`lua.to_value` / `lua.from_value`)
- Error conversion to `LuaError` at the bridge boundary
- AGENT.md ↔ lua_api sync contract

## Bridge Architecture

```
Game Script (Lua)
  └── lurek.<module>.<func>(args)
        ↓ mlua dispatch
  src/lua_api/<module>_api.rs
        ↓ Rc<RefCell<SharedState>>
  src/<module>/        [domain logic — pure Rust]
        ↓
  SharedState::resource_pool → SlotMap<TypedKey, Resource>
```

**Rule**: `lua_api/` is a translation layer only. Business logic stays in domain modules. If `lua_api/*.rs` contains more than ~10 lines of logic per function, move that logic to the domain module.

## Registration Contract

Every API module MUST follow this exact pattern (gold standard: `src/lua_api/timer_api.rs`):

```rust
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── funcName ──────────────────────────────────
    /// One-sentence description.
    /// @param name : type
    /// @return type
    let s = state.clone();
    tbl.set("funcName", lua.create_function(move |_, arg: Type| {
        Ok(s.borrow().method(arg))
    })?)?;

    lurek.set("module", tbl)?;
    Ok(())
}
```

**Critical rules:**
- Flat body (`let s = ...; tbl.set(...)`) — NOT wrapped in `{ }` block expressions
- Clone the `Rc` BEFORE moving into the closure: `let s = state.clone();`
- Section separators: `// ── SectionName ──────────────────────`
- Docstrings use ONLY `/// @param` and `/// @return` — never `# Parameters` / `# Returns`

## UserData Pattern

**All `impl LuaUserData` blocks belong in `src/lua_api/<module>_api.rs` — never in domain modules.**

Wrapper structs (`Lua<X>`) and their `impl LuaUserData` live together in the api file, not in `src/<module>/`:

```rust
// src/lua_api/image_api.rs  ← CORRECT place for BOTH the struct and impl
pub struct LuaImage {
    pub key: TextureKey,
    pub width: u32,
    pub height: u32,
}

impl LuaUserData for LuaImage {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.width));
        methods.add_method("release", |_, this, ()| {
            Ok(())
        });
    }
}
```

**WRONG — never put `impl LuaUserData` in a domain module:**
```rust
// src/image/mod.rs  ← FORBIDDEN
impl LuaUserData for LuaImage { ... } // compile error: mlua not in domain deps
```

- UserData holds only: typed resource key + cached read-only metadata
- GPU resources live in `SharedState`; never store `wgpu` objects in UserData
- Implement `LunaType` trait for consistent `type()`, `typeOf()`, `__tostring` across all types
- The audit tool (B-03) will flag any `impl LuaUserData` found in `src/<module>/` files as ERROR

## Lua↔Rust Data Conversion

| Direction | Pattern |
|-----------|---------|
| Lua → Rust struct | `lua.from_value::<MyStruct>(val)?` (requires `serde::Deserialize`) |
| Rust struct → Lua | `lua.to_value(&my_struct)?` (requires `serde::Serialize`) |
| Lua table → manual | `tbl.get::<String>("key")?` — only for small, known-shape tables |
| Rust Vec → Lua table | `lua.create_sequence_from(vec.iter())?` |
| Optional Lua arg | `Option<T>` in the function signature; `None` = Lua nil |

**Rule**: Prefer `lua.to_value()` / `lua.from_value()` over manual field iteration. Reserve manual iteration for small, stable table shapes.

## Error Handling at the Boundary

```rust
// Convert domain error to LuaError at the binding boundary:
let texture = state.borrow().load_texture(path)
    .map_err(LuaError::external)?;

// Validate Lua input with a descriptive message:
if width == 0 {
    return Err(LuaError::RuntimeError(
        "lurek.gfx.newCanvas: width must be > 0".into()
    ));
}
```

- Always use `?` throughout internal code
- Convert to `LuaError` only at the Lua boundary with `.map_err(LuaError::external)`
- Never panic on bad Lua input — always return a descriptive `LuaError`
- Strip internal Rust source paths from error messages shown to Lua

## Forbidden Patterns in lua_api Files

`lua.load()` (and `lua.eval()`) are **forbidden** in `src/lua_api/*.rs` except for the narrow cases below. The validator (`tools/validate/validate_lua_api.py`) will fail on any unannoted `lua.load()` call found in a binding file.

### Known Exceptions: LUA-EVAL-JUSTIFIED

When a `lua.load()` call is genuinely unavoidable, suppress the validator with a comment placed **immediately before** the offending line:

```rust
// LUA-EVAL-JUSTIFIED: <one-sentence reason why lua.load() is unavoidable here>
let result = lua.load(code).eval::<LuaMultiValue>()?;
```

**Placement rules:**
- The `// LUA-EVAL-JUSTIFIED:` comment must be on the line directly before `lua.load()`. Only other comment lines may appear between them — intervening code lines reset the suppressor.
- The reason must follow the colon on the same line (cannot be blank).

**Acceptable uses:**
- The eval/run IS the feature (e.g., `debugbridge_api.rs`: the REPL eval endpoint exists specifically to execute arbitrary Lua code at developer request).
- Accessing the Lua `debug` library internals that have no Rust equivalent (e.g., `devtools_api.rs`: `debug.getinfo` stack introspection).

**Unacceptable uses:**
- Embedding game logic as Lua strings in a binding file — move it to a Lua library under `content/library/` or a domain helper.
- Avoiding a proper Rust implementation for convenience.

**Current justified uses in the codebase:**
| File | Location | Reason |
|------|----------|--------|
| `src/lua_api/debugbridge_api.rs` | `lurek.debug.eval` binding | Eval IS the feature — executes arbitrary code provided by the developer REPL |
| `src/lua_api/devtools_api.rs` | `debug.getinfo` introspection | Lua `debug` library has no Rust equivalent; needed for stack inspection |

## AGENT.md ↔ lua_api Sync Contract

Every `src/<module>/AGENT.md` has a `## Lua API` footer pointing to `src/lua_api/<module>_api.rs`.
Every `src/lua_api/<module>_api.rs` must stay aligned with the module's AGENT.md:

| AGENT.md | lua_api |
|----------|---------|
| Public Rust API in `## Key Types` | Should have a Lua wrapper if user-facing |
| `## Lua API` section describes `lurek.<module>.*` | All listed functions must exist in the api file |
| `## Notes` on constraints | Enforced as `LuaError` at the binding boundary |

To check alignment: `python tools/docs/gen_lua_api_data.py`

## Adding a New API Module (Checklist)

1. Create `src/lua_api/<module>_api.rs` following the registration pattern
2. Register it in `src/lua_api/mod.rs` under the appropriate `modules.<flag>` guard
3. Add `/// @param` / `/// @return` docstrings to every public function
4. Update `src/<module>/AGENT.md` — add `## Lua API` section listing new functions
5. Regenerate API docs: `python tools/docs/gen_lua_api_data.py`
6. Write Lua BDD test: `tests/lua/unit/test_<module>.lua`
7. Register the test in `tests/lua/harness.rs`
8. Run: `cargo test lua_test_<module>`

## Domain Module Checklist (before writing lua_api)

Before implementing the Lua bridge, verify the domain module provides:
- [ ] Typed resource key in `src/engine/resource_keys.rs`
- [ ] Public API methods in `src/<module>/` (no business logic in lua_api)
- [ ] `SharedState` field holding the resource pool
- [ ] Clear ownership boundary (who allocates, who frees, who holds GPU resources)

## Rendering Boundary Rule

**Never render inside a Lua closure.** Lua callbacks must not call any GPU commands directly. Instead:

1. During `lurek.draw()`, push `RenderCommand` variants to `state.borrow_mut().draw_commands`
2. Return from the Lua callback
3. The engine processes draw commands after `lurek.draw()` returns and renders the frame

```rust
// CORRECT — queue a draw command
let cmd = RenderCommand::Rectangle { ... };
state.borrow_mut().draw_commands.push(cmd);

// WRONG — never call wgpu render methods inside a Lua closure
state.borrow().gpu_renderer.render(...); // compile error anyway, but conceptually wrong
```

Any API that invokes GPU operations (wgpu render pass, texture upload, shader bind) must be called from the engine side, not from inside a `create_function` closure.
