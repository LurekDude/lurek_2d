---
name: rust-coding
description: "Load this skill when writing or reviewing Rust engine code. It owns safe Rust conventions, error patterns, module structure, and idiomatic style. Skip it for Lua scripts, CAG files, or docs."
---
# rust-coding

## Mission
- Own safe, idiomatic Rust patterns for the engine codebase.

## When To Load
- Write Rust code.
- Review Rust code.
- Refactor Rust modules.

## When To Skip
- Lua scripts.
- CAG files.
- Docs-only work.

## Domain Knowledge
- mod.rs in src/ must contain only `pub mod`, `pub use`, doc comments, and `#[allow]` attributes. Definitions belong in sibling files. If a mod.rs has function or struct bodies, that is a defect to fix.
- No `#[cfg(test)]` blocks in src/. Unit tests for private code go in `tests/rust/unit/<module>_tests.rs`, named `<module>_tests.rs` not `<module>_test.rs`. If you see `#[cfg(test)]` in src/, move it.
- `src/lua_api/*_api.rs` must stay thin: `LuaUserData` impls, `add_methods`, registration, and type conversions only. Business logic belongs in `src/<module>/`. A binding file that starts accumulating `if/match/for` logic is drifting.
- Never hold `borrow_mut()` or `RefCell::borrow_mut()` across a Lua callback invocation. The pattern is: extract all needed values while holding the borrow, release it, then invoke Lua. Re-entry during borrow causes a runtime panic.
- SharedState access rule: `{ let guard = state.borrow(); let val = guard.field.clone(); } /* borrow released */ call_lua(val)`. The guard must be dropped before any call that might re-enter Rust.
- Pinned library versions: mlua 0.9, wgpu 22, winit 0.30, rapier2d 0.32, rodio 0.17, fontdue 0.9. Do not bump without explicit authorization; each bump needs wgpu/winit API adjustments.
- When a Rust change touches public types or functions visible through `lurek.*`, run `python tools/validate/validate_lua_api.py` to catch shape drift in generated docs.
- Public changes (new API, removed method, changed signature) must update `docs/specs/<module>.md` and `docs/CHANGELOG.md` in the same commit. Compiler green does not mean the task is done.
- Use `?` for propagation but never let it cross a callback boundary silently. Closures passed to mlua must return `mlua::Result`; inner `?` should map errors before they reach Lua with a clear message.
- Keep `unsafe` blocks small, one-purpose, and accompanied by a `// SAFETY:` comment that explains the invariant. No `unsafe` for convenience when a safe alternative exists.
- Prefer explicit module imports over glob imports (`use module::*`). Glob imports make it impossible to grep what the file actually depends on during refactors.
- Tests in `tests/rust/unit/` name their test functions `test_<behavior>_<condition>`. Keep each test assertion to one failure mode so failing tests name the problem immediately.

## Rustdoc Comment Standards — AI-First, Compact

Comments exist for AI agents reading the code. Goal: maximum signal per token. No prose, no repetition, no filler.

---

### Regular Rust files (`src/` excluding `src/lua_api/`)

**What requires a doc comment**
Every one of the following lines must have a `///` comment directly above it — no exceptions, no qualifications:
- `pub fn`, `pub async fn`
- `fn` (every private function, without exception)
- `pub struct`, `struct`
- `pub enum`, `enum`
- `pub mod` (every occurrence, in any file)
- `pub type`, `pub const`, `pub static`
- `impl Trait for Type` — one `///` line above: what the trait provides for this type
- Every field inside a struct — pub and private — one `///` line each
- Every variant inside an enum — one `///` line each

Plain `impl Type { }` (inherent impl) does NOT get a `///` on the `impl` line itself — document only the items inside.

**File level (`//!`)**
Up to ~600 characters. Write as a wrapped paragraph of 3-6 short lines. Concrete facts only: what the file owns, its purpose and role in the system, what it does NOT own, and key dependencies.
**NEVER list method names, function names, struct names, pub mod names, or any symbol from the file body.** The reader can see declarations directly. Write WHY and WHAT THIS FILE IS — not a table of contents, not a symbol index.

**Struct (`///`)**
One line: role in the system + which other type uses it.
Every field — pub and private — one `///` line: what it holds + range/units/invariant when non-obvious.

**Enum (`///`)**
One line: purpose. Every variant: one line — when it applies.

**Impl blocks (`///`)**
Every `impl Trait for Type` block gets one `///` line above it: what the trait provides for this type.
Plain `impl Type { }` blocks (inherent impl) do NOT get a `///` on the `impl` line itself — document only the methods inside.

**Methods and functions (`///`)**
One line only. State what it does AND what it returns, including edge cases inline.
No `# Arguments`, no `# Returns`, no `# Errors` sections.

Single compact example (only one):
- `/// Decodes file and returns chunk decoder; returns error on open/decode failure.`

**Forbidden Phrases in Rustdoc**
- No AI-generated prose: "returns a fully initialised instance", "the insertion is O(1) amortised", "this accessor incurs no allocation", "call it freely in hot paths".
- No synonym inflation: "alias for `foo()`", "alias of `foo()`", "shorthand for", "convenience wrapper".
- No placeholders: "placeholder", "empty placeholder", "tombstone", "replacement value" (if it has a real purpose, name that purpose instead).
- No `incurs no allocation`, `O(1)`, `amortised` — these are implementation details, not user-facing docs.
- No `returns` when opening a function doc. Use imperative: "Return" or "Read" or "Parse" instead of "Returns".

**Rules (tool-aligned)**
- Enforced by tools: every `.rs` file has `//!` module doc (see `tools/audit/audit_module.py`, check D-01).
- Enforced by tools: every `pub` item has `///` doc (see `tools/audit/audit_module.py`, check D-02).
- Tooling parses plain `///` and `//!` text; no structured rustdoc sections are required by scanners.
- Keep comments compact one-liners when possible to minimize token cost for AI agents.
- For regular files, avoid `# Arguments` / `# Returns` / `# Errors` sections unless a prompt explicitly requires them.
- Every doc comment must be a concrete technical fact, not a sentence structure template.

---

### Lua API files (`src/lua_api/`)

These files expose `lurek.*` to Lua. Contract source of truth is `tools/validate/validate_lua_api.py`.

**File level (`//!`)**
Use canonical header format expected by validator.
- Format: ``//! `lurek.<module>` -- <concrete description>``.
- Example: ``//! `lurek.audio` -- Audio bindings for source playback, bus routing, and DSP controls.``


**Structs, fields, enums, helpers in `src/lua_api/`**
Same compact one-liner rule as all other Rust files. No `# Fields` block.
- Example struct line: ``/// Lua-side handle for an audio source registered in `Mixer`.``
- Example field line: ``/// Slot-map key identifying this source in `Mixer`.``
- This applies to private helpers too: every helper function gets one concrete `///` line.


**Docs for Lua-registered calls only**
Only methods/functions actually registered to Lua (`methods.add_method`, `methods.add_method_mut`, `methods.add_function`, `tbl.set(... create_function ...)`) must use verbose tagged markers.
- Required shape above each registered call:
- One summary `///` line.
- Zero or more `@param` lines when method takes Lua args.
- At least one `@return` line always.
- Example (text form): ``/// Sets playback volume.`` + ``/// @param | vol | number | Volume multiplier, clamped to >= 0.0.`` + ``/// @return | nil | No value is returned.``


**Marker format (required)**
- `/// @param | <lua_name> | <lua_type> | <description>`
- `/// @return | <lua_type> | <description>`
- `lua_type` values: `number`, `integer`, `string`, `boolean`, `nil`, `Source`, `Bus`, `table`, etc.
- Every registered Lua call must have at least one `@return` marker.
- Keep `@param` / `@return` descriptions to one line — they appear verbatim in generated API docs.
- Do not mix marker styles: never use `@param name : type` in files validated by `validate_lua_api.py`.

**Validator-enforced checks (must stay true)**
- Header exists and matches ``//! `lurek.<module>` ...``.
- `pub fn register(...)` exists and has canonical Lua/LuaTable signature.
- No rustdoc sections `/// # Parameters` or `/// # Returns`.
- Tagged docs use exact pipe format:
    - `/// @param | name | type | description`
    - `/// @return | type | description`
- No `@return | any | ...`.
- No optional/union return types (`?`, `, nil`, `|nil`).

**Forbidden in `src/lua_api/`**
- `/// # Parameters`
- `/// # Returns`
- `@return | any | ...`
- Optional/union return types like `number?`, `number, nil`, `Type|nil`
## Companion File Index
- None.

## References
- src/
- docs/specs/
- tests/rust/unit/
- tests/lua/
