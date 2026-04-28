# Lua API File Standard

> Canonical reference for the structure, docstring format, and registration patterns
> used in every `src/lua_api/*_api.rs` file.

## Table of Contents

1. [File Structure](#1-file-structure)
2. [Docstring Format](#2-docstring-format)
3. [Section Separators](#3-section-separators)
4. [UserData Types](#4-userdata-types)
5. [Register Function](#5-register-function)
6. [Enum / Constant Registration](#6-enum--constant-registration)
7. [Naming Conventions](#7-naming-conventions)
8. [Scanner Compatibility](#8-scanner-compatibility)

---

## 1. File Structure

This standard applies to `src/lua_api/*_api.rs` files only.

Related bridge files:
- `src/lua_api/mod.rs` stays thin and only re-exports modules or public items.
- `src/lua_api/register.rs` owns `create_lua_vm` and module registration order.
- `src/lua_api/lua_types.rs` owns shared Lua-visible type helpers.

Every `src/lua_api/<module>_api.rs` file follows this order:

```
1. File header          //! `lurek.module` - Brief description.
2. Imports              use super::SharedState; use mlua::prelude::*; ...
3. Helper functions     (optional, private, non-Lua helpers only)
4. UserData structs     (optional) pub struct LuaFoo { ... }
5. impl LuaUserData     (optional) impl LuaUserData for LuaFoo { ... }
6. register function    pub fn register(lua, lurek, state) -> LuaResult<()>
```

### 1.1 File Header

```rust
//! `lurek.module` - Brief one-sentence description.
```

Rules:
- First line: `//!` + space + backtick-wrapped module name + ` - ` (ASCII hyphen) + description.
- Module name MUST exactly match the key in `lurek.set("module", tbl)`.
- Use backticks, not single quotes.
- Use ASCII only in headers and separators.

### 1.2 Imports

```rust
use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::module_name::DomainType;
```

Rules:
- ALWAYS `use mlua::prelude::*`.
- `use super::SharedState` first when shared state is needed.
- Standard library imports next.
- Blank line before `crate::...` imports.
- No business logic in helper functions; wrappers only convert, validate lightly, and delegate.

---

## 2. Docstring Format

### 2.1 Module-Level Functions (in `register()`)

```rust
    // -- functionName --
    /// Brief one-sentence description.
    /// @param | paramName | type | Description text.
    /// @param | optionalParam | type? | Description text.
    /// @return | returnType | Description text.
    let s = state.clone();
    tbl.set("functionName", lua.create_function(move |_, arg: T| {
        Ok(s.borrow().method(arg))
    })?)?;
```

### 2.2 UserData Methods (in `impl LuaUserData`)

```rust
        // -- methodName --
    /// Brief one-sentence description.
    /// @param | paramName | type | Description text.
    /// @return | returnType | Description text.
        methods.add_method("methodName", |_, this, arg: T| {
            Ok(this.inner.method(arg))
        });
```

### 2.3 Tag Reference

| Tag | Format | Example |
|-----|--------|---------|
| Description | `/// One sentence.` | `/// Returns the delta time in seconds.` |
| Parameter | `/// @param | name | type | description` | `/// @param | delay | number | Delay in seconds.` |
| Optional param | `/// @param | name | type? | description` | `/// @param | tag | string? | Optional tag filter.` |
| Varargs | `/// @param | ... | type | description` | `/// @param | ... | string | Additional event parts.` |
| Return | `/// @return | type | description` | `/// @return | number | Delta time in seconds.` |
| Multi-return | `/// @return | type, type | description` | `/// @return | integer, integer | Width and height.` |
| No return value | `/// @return | nil | No value is returned.` | |

### 2.4 Lua Type Names

| Rust type | Write as |
|-----------|----------|
| `bool` | `boolean` |
| `f32` / `f64` | `number` |
| `i32` / `i64` / `u32` / `u64` / `usize` | `integer` |
| `String` / `&str` | `string` |
| `Option<T>` parameter | `type?` (e.g. `string?`) |
| `LuaTable` | `table` |
| `LuaFunction` | `function` |
| `LuaValue` | Concrete Lua type or constrained union when known (for example `table|integer`); otherwise use `LuaValue`, the generated alias for an unconstrained Lua runtime value |
| `Vec<T>` | `table` |
| UserData wrapper | Lua-visible display name (e.g. `LCamera`, `LButton`, `LScheduler`) |
| No return value | `nil` |

### 2.5 Docstring Rules

1. **One sentence only**: The first `///` line is a single sentence on a single line.
2. **Order**: description → `@param` lines → one `@return` line.
3. **Pipe format only**: Use `@param | ... | ... | ...` and `@return | ... | ...`.
4. **No legacy syntax**: Do not use `@param name type`, `@param name : type`, or `@return type`.
5. **No `# Parameters` / `# Returns`**: Only `@param` / `@return` tags.
6. **Fixed return shape only**: Allowed: `nil`, one fixed type, or a fixed tuple like `boolean, number`. Forbidden: `?`, `|nil`, and other unions in `@return`.
7. **Placement**: Docstring sits above the optional `let s = state.clone();` line and the corresponding registration call.
8. **Every function/method MUST have at least a description and `@return`**.
9. **Prefer precise dynamic types**: For `LuaValue` inputs, document the accepted Lua shape explicitly (`table|integer`, `string|table`, and so on) whenever it is known. Only use `LuaValue` when the value is truly unconstrained at the Lua API surface. Do not introduce raw `any` or `unknown` placeholders in source docstrings.

### 2.6 Description Line Rules

- First `///` line is always a one-sentence description (no tag prefix).
- Ends with a period.
- Starts with a verb: "Returns...", "Sets...", "Creates...", "Schedules...".
- For getters: "Returns the current X."
- For setters: "Sets the X value."
- For predicates: "Returns whether X is Y."
- Do not add a second free-text `///` line. Put details into the `@param` or `@return` description field.

---

## 3. Section Separators

### 3.1 Major Section Separator

Used between file-level sections (Helpers, UserData, Register):

```rust
// ---------------------------------------------------------------------------
// Section Name
// ---------------------------------------------------------------------------
```

- ASCII dashes only.
- Section name on its own `//` line between two separator lines.
- Standard labels: `Helpers`, `LuaFoo UserData`, `Register`.

### 3.2 Function/Method Separator

Used before every individual function or method docstring:

```rust
        // -- methodName --
```

- Indent matches the surrounding code (4 spaces in `register`, 8 spaces in `impl LuaUserData`).
- Exactly: `// -- camelCaseName --`.
- Must match the Lua-side name registered in `tbl.set("name", ...)` or `methods.add_method("name", ...)`.

### 3.3 Subsection Headers (optional)

For grouping related functions within a section:

```rust
    // ── Timing ──────────────────────────────────────────────────────
```

- Prefer the major ASCII separator instead. Subsection headers are optional.

---

## 4. UserData Types

### 4.1 Struct Declaration

```rust
/// Lua-side wrapper around [`DomainType`].
pub struct LuaFoo {
    inner: DomainType,
}
```

Rules:
- Struct name: `Lua` prefix + PascalCase domain name (e.g. `LuaCamera2D`, `LuaScheduler`).
- `///` doc comment above the struct.
- Fields hold: typed resource keys, domain type references, cached read-only metadata.
- NO `wgpu` or GPU resources in UserData structs.

### 4.2 impl LuaUserData

```rust
impl LuaUserData for LuaFoo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- methodName --
        /// Description.
        /// @param | arg | type | Description text.
        /// @return | type | Description text.
        methods.add_method("methodName", |_, this, arg: T| {
            Ok(this.inner.method(arg))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("FooDisplayName"));

        // -- typeOf --
        /// Returns whether this object matches the given type name.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "FooDisplayName" || name == "Object")
        });
    }
}
```

Rules:
- `impl LuaUserData` — NEVER `impl mlua::UserData`.
- Every UserData type MUST have `type()` and `typeOf()` methods.
- The `type()` return value is the Lua-visible display name (e.g. `"Camera2D"`, `"LScheduler"`).
- Use `add_method` (immutable) unless the wrapper struct itself is mutated.
- Use `add_method_mut` only when the wrapper fields change (e.g. stored callbacks).
- Use `add_function` for static/factory methods (no `self`).

### 4.3 Method Selection Guide

| Use | When |
|-----|------|
| `add_method` | `this: &Self` — read-only access to wrapper |
| `add_method_mut` | `this: &mut Self` — must mutate wrapper fields (callbacks, caches) |
| `add_function` | No `self` — static/factory/constructor |
| `add_meta_method` | Metamethods: `__tostring`, `__eq`, `__index`, `__len` |

---

## 5. Register Function

### 5.1 Signature

```rust
/// Registers the `lurek.module` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ... function registrations ...

    lurek.set("module", tbl)?;
    Ok(())
}
```

Rules:
- Parameter name is ALWAYS `lurek` (not `luna` or other names).
- Table variable is ALWAYS `tbl`.
- `state` parameter may be omitted if the module doesn't need shared state, but the first two params are always `lua: &Lua, lurek: &LuaTable`.
- Last two lines: `lurek.set("module", tbl)?;` then `Ok(())`.
- The docstring above `register` is `/// Registers the \`lurek.module\` API table with the Lua VM.`

### 5.2 Function Entry Pattern

Standard pattern with shared state:

```rust
    // -- funcName --
    /// Description.
    /// @param | arg | type | Description text.
    /// @return | type | Description text.
    let s = state.clone();
    tbl.set("funcName", lua.create_function(move |_, arg: T| {
        Ok(s.borrow().method(arg))
    })?)?;
```

Standard pattern without shared state:

```rust
    // -- funcName --
    /// Description.
    /// @param | arg | type | Description text.
    /// @return | type | Description text.
    tbl.set("funcName", lua.create_function(|_, arg: T| {
        Ok(domain::function(arg))
    })?)?;
```

Rules:
- `let s = state.clone();` goes AFTER the docstring block, BEFORE `tbl.set(...)`.
- Flat body — NOT wrapped in `{ }` block expressions.
- Each function entry: separator → docstring → optional state clone → `tbl.set(...)`.

### 5.3 Local State Pattern

When a module manages its own state (not `SharedState`):

```rust
pub fn register(lua: &Lua, lurek: &LuaTable) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    let local_state: Rc<RefCell<MyState>> = Rc::new(RefCell::new(MyState::new()));

    // -- funcName --
    /// Description.
    /// @return | type | Description text.
    let s = local_state.clone();
    tbl.set("funcName", lua.create_function(move |_, ()| {
        Ok(s.borrow().value())
    })?)?;

    lurek.set("module", tbl)?;
    Ok(())
}
```

---

## 6. Enum / Constant Registration

For exposing named constants or enum values to Lua:

```rust
    // ── BlendMode constants ─────────────────────────────────────────
    let blend = lua.create_table()?;
    blend.set("alpha", "alpha")?;
    blend.set("add", "add")?;
    blend.set("multiply", "multiply")?;
    tbl.set("BlendMode", blend)?;
```

No docstrings on individual constant entries. The subsection header serves as documentation.

---

## 7. Naming Conventions

### 7.1 Rust → Lua Function Names

| Rust `snake_case` | Lua `camelCase` |
|-------------------|-----------------|
| `new_image` | `newImage` |
| `get_width` | `getWidth` |
| `set_volume` | `setVolume` |
| `is_down` | `isDown` |

### 7.2 Constructor Names

| Pattern | Example |
|---------|---------|
| Simple factory | `"new"` — `tbl.set("new", ...)` |
| Named factory | `"newFoo"` — `tbl.set("newScheduler", ...)` |
| From-source | `"fromFile"`, `"fromTOML"`, `"fromAseprite"` |

### 7.3 Module Names

- Always lowercase: `"timer"`, `"render"`, `"input"`.
- Dot-separated for sub-namespaces: `"input.keyboard"`, `"input.mouse"`.
- Match the `//!` header backtick name.

---

## 8. Scanner Compatibility

The documentation tools (`tools/docs/gen_lua_api.py`) parse these docstrings with specific regex patterns. Following this standard ensures zero parsing exceptions.

### 8.1 @param Detection

Regex: `r"@param\s*\|\s*(\w+\??|\.\.\.)\s*\|\s*([^|]+?)\s*\|\s*(.+)"`

- Only the pipe-delimited format is accepted.
- Parameter types may end with `?` when the parameter itself is optional.

### 8.2 @return Detection

Regex: `r"@return\s*\|\s*([^|]+?)\s*\|\s*(.+)"`

- Only the pipe-delimited format is accepted.
- Return types must be fixed and may be comma-separated for multi-return.

### 8.3 Function Name Detection

The scanner detects bindings via:
- `tbl.set("name", lua.create_function(...)` — module functions
- `methods.add_method("name", ...)` — instance methods
- `methods.add_method_mut("name", ...)` — mutable methods
- `methods.add_function("name", ...)` — static/class functions

### 8.4 Docstring Collection

The scanner collects `///` lines by scanning UPWARD from the binding call. It skips:
- Blank lines
- `let s = state.clone();` lines
- `//` non-doc comments
- `#[...]` attributes

**IMPORTANT**: Even though the scanner skips `let s =` lines, the docstring MUST be contiguous for readability. Place `let s = state.clone();` AFTER all `///` lines.

### 8.5 Class Name Detection

The scanner extracts class names from:
- `pub struct LuaFoo` declarations
- `impl LuaUserData for LuaFoo` blocks
- `methods.add_method("type", |_,_,()| Ok("DisplayName"))` for the Lua-visible name
- Widget factory functions `fn add_button_methods(...)`

---

## Quick Checklist

Before committing a `*_api.rs` file, verify:

- [ ] `//!` header uses backticks and ASCII hyphen
- [ ] `use mlua::prelude::*` (not individual items)
- [ ] Every function/method has `// -- name --` separator
- [ ] Every function/method has one description line plus one `@return`
- [ ] All `@param` / `@return` lines use the pipe-delimited format
- [ ] Docstring block is contiguous (no code between `///` lines)
- [ ] `let s = state.clone()` is after docstring, before `tbl.set()`
- [ ] Table variable is `tbl`, register param is `lurek`
- [ ] UserData types have `type()` and `typeOf()` methods
- [ ] Last two lines of `register()`: `lurek.set("module", tbl)?;` + `Ok(())`
- [ ] No `# Parameters` / `# Returns` sections
- [ ] No `@return any`, `?`, `|nil`, or union-style returns; use `unknown` for truly unconstrained dynamic values
