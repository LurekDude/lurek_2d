---
name: lua-api-design
description: "Load this skill when designing or modifying the lurek.* Lua API surface. It owns naming conventions, parameter patterns, callback contracts, and API consistency rules. Skip it for Rust internals or pure Lua scripting."
companion_files:
  examples: [examples/1-file-header.rs, examples/2-imports-exact-order.rs, examples/4-userdata-struct.rs, examples/5-impl-luauserdata-block.rs, examples/callback-storage-pattern-luaregistrykey.rs, examples/callback-storage-pattern-luaregistrykey-2.rs, examples/method-section-header-8-space-indent.rs, examples/docstring.rs, examples/docstring-2.rs, examples/6-register-section.rs, examples/7-function-entry-pattern-4-space.rs, examples/param-syntax.rs, examples/return-syntax.rs, examples/business-logic-migration-pattern.rs, examples/business-logic-migration-pattern-2.rs]
  templates: []
  snippets: [snippets/first-action-read-the-gold-standard.txt, snippets/3-section-separators.txt, snippets/validation.ps1, snippets/extended-notes.md]
related_skills: []
---

# lua-api-design

## Mission

# Lua API Design - Lurek2D Engine

## When To Load

- Creating or updating any `src/lua_api/*_api.rs` file
- Adding a new `lurek.*` function or UserData method
- Designing the API surface for a domain module
- Code-reviewing a lua_api file

## When To Skip

- Rust implementation of domain logic -> `rust-coding` skill
- Writing Lua game scripts -> `lua-scripting` skill
- Step-by-step workflow for building a module from scratch -> `implement-lua-api-module` prompt
---

## Domain Knowledge

### Owns
- `lurek.*` namespace structure and naming conventions
- File structure, import order, section separator format
- Inline closure docstring format (`@param`/`@return` - NEVER `# Parameters`/`# Returns`)
- Registration pattern - ALL files MUST follow the pattern exactly
- The Thin Wrapper Rule: lua_api files contain **zero** business logic

### FIRST ACTION: Read the Gold Standard
Before writing a single line of lua_api code, read this file in full:

> See [snippets/first-action-read-the-gold-standard.txt](snippets/first-action-read-the-gold-standard.txt) for the example.

Every rule below is derived from it. If anything here contradicts `timer_api.rs`, `timer_api.rs` wins.

---

### mlua Best Practices (verified against mlua 0.9 / LuaJIT)
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

### File Anatomy
### 1. File Header

> See [examples/1-file-header.rs](examples/1-file-header.rs) for the example.

- Must be the first line of the file.
- Format: `//!` + space + backtick-module-name + ` - ` + one sentence.
- Module name must exactly match the key passed to `lurek.set("module", tbl)`.

### 2. Imports (exact order)

> See [examples/2-imports-exact-order.rs](examples/2-imports-exact-order.rs) for the example.

- ALWAYS `use mlua::prelude::*` - never individual mlua items.
- `use super::SharedState` first.
- Domain crate imports after a blank line.

### 3. Section Separators

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/first-action-read-the-gold-standard.txt](snippets/first-action-read-the-gold-standard.txt) — FIRST ACTION: Read the Gold Standard
- [examples/1-file-header.rs](examples/1-file-header.rs) — 1. File Header
- [examples/2-imports-exact-order.rs](examples/2-imports-exact-order.rs) — 2. Imports (exact order)
- [snippets/3-section-separators.txt](snippets/3-section-separators.txt) — 3. Section Separators
- [examples/4-userdata-struct.rs](examples/4-userdata-struct.rs) — 4. UserData Struct
- [examples/5-impl-luauserdata-block.rs](examples/5-impl-luauserdata-block.rs) — 5. `impl LuaUserData` Block
- [examples/callback-storage-pattern-luaregistrykey.rs](examples/callback-storage-pattern-luaregistrykey.rs) — Callback storage pattern (LuaRegistryKey)
- [examples/callback-storage-pattern-luaregistrykey-2.rs](examples/callback-storage-pattern-luaregistrykey-2.rs) — Callback storage pattern (LuaRegistryKey)
- [examples/method-section-header-8-space-indent.rs](examples/method-section-header-8-space-indent.rs) — Method section header (8-space indent)
- [examples/docstring.rs](examples/docstring.rs) — Docstring
- [examples/docstring-2.rs](examples/docstring-2.rs) — Docstring
- [examples/6-register-section.rs](examples/6-register-section.rs) — 6. Register Section
- [examples/7-function-entry-pattern-4-space.rs](examples/7-function-entry-pattern-4-space.rs) — 7. Function Entry Pattern (4-space indent in register)
- [examples/param-syntax.rs](examples/param-syntax.rs) — @param syntax
- [examples/return-syntax.rs](examples/return-syntax.rs) — @return syntax
- [examples/business-logic-migration-pattern.rs](examples/business-logic-migration-pattern.rs) — Business Logic Migration Pattern
- [examples/business-logic-migration-pattern-2.rs](examples/business-logic-migration-pattern-2.rs) — Business Logic Migration Pattern
- [snippets/validation.ps1](snippets/validation.ps1) — Validation
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
