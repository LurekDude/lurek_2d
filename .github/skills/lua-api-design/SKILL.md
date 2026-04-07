---
name: lua-api-design
description: "Load this skill when designing or modifying the luna.* Lua API surface. It owns naming conventions, parameter patterns, callback contracts, and API consistency rules. Skip it for Rust internals or pure Lua scripting."
---

# Lua API Design - Luna2D Engine

## Load When

- Creating or updating any `src/lua_api/*_api.rs` file
- Adding a new `luna.*` function or UserData method
- Designing the API surface for a domain module
- Code-reviewing a lua_api file

## Owns

- `luna.*` namespace structure and naming conventions
- File structure, import order, section separator format
- Inline closure docstring format (`@param`/`@return` - NEVER `# Parameters`/`# Returns`)
- Registration pattern - ALL files MUST follow the pattern exactly
- The Thin Wrapper Rule: lua_api files contain **zero** business logic

## Does Not Cover

- Rust implementation of domain logic -> `rust-coding` skill
- Writing Lua game scripts -> `lua-scripting` skill
- Step-by-step workflow for building a module from scratch -> `implement-lua-api-module` prompt

---

## FIRST ACTION: Read the Gold Standard

Before writing a single line of lua_api code, read this file in full:

```
src/lua_api/timer_api.rs
```

Every rule below is derived from it. If anything here contradicts `timer_api.rs`, `timer_api.rs` wins.

---

## mlua Best Practices (verified against mlua 0.9 / LuaJIT)

These are the canonical mlua patterns enforced in this codebase:

| Pattern | Rule |
|---|---|
| Imports | Always `use mlua::prelude::*` — gives `LuaUserData`, `LuaResult`, `LuaFunction`, `LuaRegistryKey`, etc. |
| UserData trait | Write `impl LuaUserData` (prelude alias), never `impl mlua::UserData` |
| Immutable methods | `add_method("name", \|_, this, arg\| …)` — `this: &Self` |
| Mutable methods | `add_method_mut("name", \|_, this, arg\| …)` — `this: &mut Self` |
| Static/factory | `add_function("name", \|lua, arg\| …)` — no `self`; for constructors |
| Metamethods | `add_meta_method(LuaMetaMethod::ToString, …)` for `__tostring`, `__eq`, `__index` |
| Callbacks (Lua fns) | `lua.create_registry_value(func)?` → `LuaRegistryKey`; prevents GC collecting the fn |
| Callback cleanup | `lua.remove_registry_value(key)?` when the callback is cancelled or the object drops |
| Registry read | `lua.registry_value::<LuaFunction>(&key)?` to retrieve and call a stored callback |
| Shared state | Clone `Rc` BEFORE closure: `let s = state.clone(); tbl.set("f", lua.create_function(move \|_,…\| { s.borrow()… }))` |
| Error conversion | `.map_err(LuaError::external)` at the Lua boundary for non-`LuaResult` errors |
| Optional params | `Option<T>` in function signature: `arg: Option<f32>` |
| Multiple params | Tuple destructure: `(a, b): (f32, f32)` |
| Variadic params | `args: Variadic<T>` as the args type |

---

## File Anatomy

### 1. File Header

```rust
//! `luna.<module>` - One-line description of what this module provides.
```

- Must be the first line of the file.
- Format: `//!` + space + backtick-module-name + ` - ` + one sentence.
- Module name must exactly match the key passed to `luna.set("module", tbl)`.

### 2. Imports (exact order)

```rust
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::<tier>::<Module>;
```

- ALWAYS `use mlua::prelude::*` - never individual mlua items.
- `use super::SharedState` first.
- Domain crate imports after a blank line.

### 3. Section Separators

```
// -------------------------------------------------------------------------------
// LuaFoo UserData
// -------------------------------------------------------------------------------
```

Standard labels: `LuaFoo UserData`, `Register`.

### 4. UserData Struct

```rust
/// Lua-side wrapper around [`DomainType`].
pub struct LuaFoo {
    inner: DomainType,
}
```

### 5. `impl LuaUserData` Block

```rust
impl LuaUserData for LuaFoo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- methodName --
        /// One-sentence description.
        /// @param arg : type
        /// @return type
        methods.add_method("methodName", |_, this, arg: T| {
            Ok(this.inner.method(arg))
        });

        // -- mutateFoo --
        /// Mutates an internal field.
        /// @param value : number
        /// @return nil
        methods.add_method_mut("mutateFoo", |_, this, value: f32| {
            this.inner.set_value(value);
            Ok(())
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(this.inner.to_display_string())
        });

    }
}
```

#### `add_method` vs `add_method_mut`

| Use | When |
|---|---|
| `add_method` | `this: &Self` — read-only access to the wrapper |
| `add_method_mut` | `this: &mut Self` — must mutate the wrapper itself (e.g. cached state, stored key) |
| `add_function` | No `self` at all — static/factory/constructor functions |

**Rule**: prefer `add_method` unless mutation of the wrapper struct is strictly required. Mutation of the underlying domain value through `RefCell` still uses `add_method`.

#### Callback storage pattern (LuaRegistryKey)

When a method accepts a Lua function to call later, store it in the registry:

```rust
        // -- setCallback --
        /// Registers a Lua function called on each tick.
        /// @param fn : function
        /// @return nil
        methods.add_method_mut("setCallback", |lua, this, func: LuaFunction| {
            this.callback_key = Some(lua.create_registry_value(func)?);
            Ok(())
        });
```

To call the callback later (single domain call per closure — call a domain method that accepts a `LuaFunction`):

```rust
        // -- tick --
        /// Advances the scheduler by dt seconds, firing due callbacks.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("tick", |lua, this, dt: f32| {
            if let Some(key) = &this.callback_key {  // guard: Option<LuaRegistryKey>
                let func: LuaFunction = lua.registry_value(key)?;
                this.inner.tick(dt, &func)?;  // single domain call
            }
            Ok(())
        });
```

**Exception to the one-domain-call rule**: An `if let Some(key) = &this.callback_key` guard
around a single domain call is acceptable — the guard is infrastructure, not business logic.
This is the **only** accepted multi-statement pattern in a closure body.

Clean up: `lua.remove_registry_value(key)?` in a `cancel`/`destroy` method.

#### Method section header (8-space indent)

```rust
        // -- methodName --
```

#### Docstring

```rust
        /// One-sentence description.
        /// @param name : type
        /// @return type
```

- `@param` before `@return`. Always.
- No blank line between last docstring line and `methods.add_method(`.
- Docstring above the call site, never inside the closure.
- Multi-line form: docstring is ABOVE `methods.add_method(`:

```rust
        // -- addFoo --
        /// Adds a foo.
        /// @param x : number
        /// @return nil
        methods.add_method(    // docstring here, above this line
            "addFoo",
            |_, this, x: f32| {
                this.inner.add_foo(x);
                Ok(())
            },
        );
```

### 6. Register Section

```rust
/// Registers the `luna.<module>` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ... entries ...

    luna.set("<module>", tbl)?;
    Ok(())
}
```

- Signature is FIXED: `(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- Table variable is ALWAYS named `tbl`.
- Last two lines: `luna.set("<module>", tbl)?;` then `Ok(())`.

### 7. Function Entry Pattern (4-space indent in register)

Standard pattern with state:

```rust
    // -- funcName --
    /// One-sentence description.
    /// @param arg : type
    /// @return type
    let s = state.clone();
    tbl.set(
        "funcName",
        lua.create_function(move |_, arg: T| Ok(s.borrow().method(arg)))?,
    )?;
```

- `let s = state.clone();` comes AFTER docstring, BEFORE `tbl.set(`.
- Section header at 4-space indent.

---

## Docstring Contract

### @param syntax

```rust
/// @param name : type
```

### @return syntax

```rust
/// @return type
```

- `nil` for functions that return nothing.
- Must be the last docstring line before the code.

### Lua type names

| Rust type | Write as |
|---|---|
| `bool` | `boolean` |
| `f64` / `f32` | `number` |
| `i32` / `i64` / `usize` | `integer` |
| `String` | `string` |
| `Option<T>` | `type?` e.g. `string?` |
| Lua table | `table` |
| `LuaFunction` | `function` |
| UserData wrapper | the wrapper name e.g. `Agent`, `Body` |
| No return value | `nil` |

### Forbidden

| Forbidden | Replacement |
|---|---|
| `/// # Parameters` | `/// @param name : type` |
| `/// # Returns` | `/// @return type` |
| `/// @return any` | Specific type |

---

## The Thin Wrapper Rule

A lua_api file is a **BRIDGE ONLY**. Every closure body contains exactly **one domain call**.

### Allowed

- `Ok(s.borrow().field)` — state read
- `s.borrow_mut().set_field(arg); Ok(())` — state write
- `Ok(this.inner.method(arg))` — domain call
- `.map_err(LuaError::external)?` — non-Lua error conversion at boundary
- `lua.create_userdata(LuaFoo { inner })` — UserData construction (wrapping a domain value)
- `lua.create_registry_value(func)?` — Lua callback storage
- `count.unwrap_or(-1)` — trivial Option default
- `if let Some(key) = &this.callback_key { … }` — guard for stored registry key (see callback pattern above)

### Forbidden in closures

| Pattern | Where it belongs |
|---|---|
| `lua.load(r#"..."#)` | Domain module or eliminated entirely |
| Serialization / deserialization loops | Domain file |
| Struct construction with 3+ fields | Domain file — add a named constructor |
| Iteration to build output (Vec, HashMap) | Domain file |
| Business logic conditionals | Domain file |
| `std::thread::sleep(...)` | Domain file — add `timer::sleep(secs)` fn |
| Capturing mutable state in closures | Domain file — put state in domain struct |
| `HashSet`, `HashMap` construction | Domain file |

### Business Logic Migration Pattern

When you find business logic in a closure, move it to the domain like this:

**Before (anti-pattern):**
```rust
tbl.set("step", lua.create_function(move |_, dt: f32| {
    let mut s = state.borrow_mut();
    s.clock.total_time += dt;
    s.clock.fps = 1.0 / dt;
    s.clock.frame += 1;
    Ok(())
})?)?;
```

**After (correct):**
```rust
// -- step --
/// Advances the clock by dt seconds.
/// @param dt : number
/// @return nil
let s = state.clone();
tbl.set("step", lua.create_function(move |_, dt: f32| {
    s.borrow_mut().clock.tick(dt);  // single domain call
    Ok(())
})?)?;
```

Add `pub fn tick(&mut self, dt: f32)` to the `Clock` struct in `src/timer/clock.rs`.

If the domain module lacks a needed method, **add `pub fn` to domain first, then call it**.

---

## Naming Convention

| Rust `snake_case` | Lua `camelCase` |
|---|---|
| `new_image` | `"newImage"` |
| `get_width` | `"getWidth"` |
| `set_volume` | `"setVolume"` |
| `is_down` | `"isDown"` |

---

## Validation

```powershell
python tools/validate/validate_lua_api.py src/lua_api/<module>_api.rs
```

Exit code `0` = pass. Exit code `1` = errors.

**Validator limitation**: For multi-line `methods.add_method(` calls where the method name is on a separate line, the validator CANNOT detect missing docstrings. Manually verify docstrings above every multi-line `methods.add_method(` call.

---

## Anti-Patterns the Validator Catches

| Anti-pattern | Rule |
|---|---|
| `{ let s = state.clone(); tbl.set(...); }` | Block-wrapped pattern |
| `lua.load(r#"..."#)` | Embedded Lua code |
| `/// # Parameters` | Use `@param` |
| `/// # Returns` | Use `@return` |
| `/// @return any` | Too vague — use specific type |
| Missing `/// @return` above single-line `tbl.set(` | Undocumented function |
| No `//!` header | Missing module doc |
| No `luna.set("module", tbl)` | Module not registered |

## Anti-Patterns the Validator Does NOT Catch (verify manually)

| Anti-pattern | How to spot it |
|---|---|
| `impl mlua::UserData` instead of `impl LuaUserData` | grep for `mlua::UserData` |
| `add_method_mut` where `add_method` suffices | wrapper struct is not actually mutated |
| Multi-line `methods.add_method(…` missing docstring | method name on a separate line fools the validator |
| Loop / conditional logic inside closure body | more than one statement before `Ok(…)` |
| Comments above docstrings (`// Do X` then `/// …`) | plain comment immediately above `///` — remove the comment |
| `/// @return any` slipped in on a multi-line call | validator misses it when method name on separate line |
| Lua callback stored without `LuaRegistryKey` | look for `let func: LuaFunction` without `create_registry_value` |
