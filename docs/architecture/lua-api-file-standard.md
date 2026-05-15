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
2. **Order**: description -> `@param` lines -> one `@return` line.
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
    // -- Timing ----------------------------------------------------
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
    }
}
```

Rules:
- `type()` and `typeOf()` methods come last.
- `type()` returns the canonical Lua-visible type string.
- `typeOf()` checks `name == "ThisType" || name == "Object"` or equivalent parent alias set.
- Do not embed business rules in `add_methods`; delegate to domain code.

---

## 5. Register Function

Standard shape:

```rust
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- functionName --
    /// Description.
    /// @return | nil | No value is returned.
    tbl.set("functionName", lua.create_function(|_, ()| Ok(()))?)?;

    lurek.set("module", tbl)?;
    Ok(())
}
```

Rules:
- Function name is always `register`.
- Final line MUST be `lurek.set("module", tbl)?;` with exact module key.
- No side effects during registration beyond table creation and callback/userdata setup.

---

## 6. Enum / Constant Registration

Constants inside the module table should still follow the same nearby section style when they are grouped by helper functions or builders.

Rules:
- Prefer plain `tbl.set("NAME", value)?;` for constants.
- For enum-like string constants, document the function that consumes them rather than every constant unless the constant table is itself user-facing.

---

## 7. Naming Conventions

- File name: `<module>_api.rs`
- Module namespace: `lurek.<module>`
- UserData wrapper: `LuaTypeName`
- Lua-exposed function names: camelCase.
- Rust helper names: snake_case.
- Type method order: constructor helpers first, state mutation next, queries after that, `type` / `typeOf` last.

---

## 8. Scanner Compatibility

The doc generators and validators depend on predictable local structure.

Rules:
- Keep the `// -- name --` marker directly above the matching doc block.
- Keep the doc block directly above the registration call or method registration call.
- Do not insert unrelated comments between separator, doc block, and registered function.
- Keep `@return` syntax fixed-width and free of optional-return markers.
- If a method accepts optional Lua values, express that in `@param`, not `@return`.
