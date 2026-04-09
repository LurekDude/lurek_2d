---
description: "Build or rebuild a lurek.* Lua API module from domain module source. Reads domain pub fn signatures, designs the Lua surface, then writes a thin wrapper following the lua-api-design SKILL."
---

# Implement a Lurek2D Lua API Module

**Arguments**: `module=<module_name>` (e.g. `module=timer`, `module=audio`, `module=ai`)

## Purpose

Rebuild `src/lua_api/<module>_api.rs` as a thin wrapper over the domain module `src/<module>/`.
Business logic belongs in the domain module. The lua_api file is a bridge only.

---

## Step 0 — Collect All Declarations (Inventory)

Before reading ANY code in depth, build a flat inventory of every public item from **both** sources.
This is your working manifest — every row in this list becomes a candidate Lua API entry.

### A. From `lua_api_old/<module>_api.rs`

Run each command and record the results as one-liners (signature only, no bodies):

```powershell
# Struct wrappers
Select-String -Path lua_api_old/<module>_api.rs -Pattern 'pub struct Lua'

# UserData methods
Select-String -Path lua_api_old/<module>_api.rs -Pattern 'methods\.add_method'

# Table functions registered in register()
Select-String -Path lua_api_old/<module>_api.rs -Pattern 'tbl\.set\('
```

### B. From `src/<module>/*.rs`

```powershell
# All public functions and structs
Select-String -Path src/<module>/*.rs -Pattern '^pub (fn|struct|enum|trait|type|const)'

# Public methods on impl blocks
Select-String -Path src/<module>/*.rs -Pattern '^\s+pub fn '
```

Format your inventory as a table:

| Source | Kind | Name / Signature |
|---|---|---|
| `lua_api_old` | UserData struct | `pub struct LuaScheduler { inner: Scheduler, callback_key: Option<LuaRegistryKey> }` |
| `lua_api_old` | method | `methods.add_method("getDelta", ...)` |
| `lua_api_old` | fn | `tbl.set("newScheduler", ...)` |
| domain | `pub struct` | `pub struct Clock { dt: f32, total: f32, fps: f32 }` |
| domain | `pub fn` | `pub fn tick(&mut self, dt: f32)` |
| domain | `pub fn` | `pub fn fps(&self) -> f32` |

**Pause here.** Review the inventory for:
- Methods present in `lua_api_old` but missing from the domain → add them to the domain in Step 3
- Domain methods not yet exposed in the old API → decide whether to expose them
- Business logic inside old closures (loops, conditionals, struct construction) → flag for extraction

---

## Step 1 — Read the Gold Standard

Before doing anything, read `src/lua_api/timer_api.rs` in full.
Every structural and formatting rule comes from there.
Also load the `lua-api-design` skill for the detailed rules (includes mlua best practices,
`add_method` vs `add_method_mut`, `LuaRegistryKey` callback pattern, and business logic migration).

---

## Step 2 — Read Domain Files In Depth

Using the inventory from Step 0 as a guide, now read the full content of the files:

```powershell
Get-ChildItem src/<module>/ | Select-Object Name
```

For every `pub struct` — this becomes a `LuaFoo` UserData wrapper.
For every `pub fn` / `impl` method — this becomes a closure entry.

Also read `lua_api_old/<module>_api.rs` in full to understand what the old wrapper did
and identify any business logic that must be moved to the domain before writing the new wrapper.

---

## Step 3 — Build the Method Table

Using the Step 0 inventory, create a design row for every Lua-facing entry:

| Lua name (camelCase) | mlua call type | Domain call | @param lines | @return type | Expose? |
|---|---|---|---|---|---|
| `getDelta` | `add_method` | `inner.dt()` | *(none)* | `number` | yes |
| `setDelta` | `add_method_mut` | `inner.set_dt(v)` | `@param value : number` | `nil` | yes |
| `newScheduler` | `add_function` | `Scheduler::new()` | *(none)* | `Scheduler` | yes |

**Rules**:
- Expose every meaningful method. Omit: `new()` (replaced by Lua factory), internal helpers, `Default`.
- Lua names: `snake_case` → `camelCase`. Constructor factories use `new` prefix: `newAgent`.
- Types: bool→boolean, f64/f32→number, i32/i64→integer, String→string, Option<T>→`type?`, UserData wrapper→wrapper name, no return→nil. NEVER write `any`.
- For Lua callback parameters: use `LuaFunction` in the signature; store with `lua.create_registry_value(func)?` → `LuaRegistryKey`.
- `add_method` for read-only wrapper access; `add_method_mut` only when the wrapper struct itself is mutated (e.g. updating a stored `Option<LuaRegistryKey>`).

---

## Step 4 — Identify Missing Domain Methods and Extract Business Logic

For **every** piece of business logic found in `lua_api_old/<module>_api.rs` closures
(loops, conditionals, multi-field struct construction, `thread::sleep`, state accumulation),
move it to the domain module FIRST:

1. Add `pub fn` with `///` docstring to the domain module (following `rust-coding` skill).
2. Follow the **Business Logic Migration Pattern** from the `lua-api-design` skill.
3. Verify it compiles: `cargo check --lib 2>&1 | Select-String "error"`.
4. Then call the new domain method — one call — inside the closure.

---

## Step 5 — Write the lua_api File

Write `src/lua_api/<module>_api.rs` following the **File Anatomy** in the `lua-api-design` skill **exactly**.
Also apply the **mlua Best Practices** table from the skill before writing any code:

1. `//! \`lurek.<module>\` — one-sentence description.` (first line, no BOM)
2. Imports in exact order (`use mlua::prelude::*` — always via prelude)
3. For each `pub struct` that needs Lua access: `LuaFoo` UserData wrapper struct
4. `impl LuaUserData for LuaFoo` with every method from the Step 3 table:
   - Use `add_method` (immutable) or `add_method_mut` (wrapper mutation) per the skill decision table
   - Use `add_function` for factory/static calls
   - Use `add_meta_method(LuaMetaMethod::ToString, …)` for `__tostring`
   - Store Lua callbacks via `lua.create_registry_value(func)? → LuaRegistryKey`
   - Each method has `// -- name --` header, docstring, then the `methods.add_method*(` call
5. `pub fn register(…)` block with `let tbl = lua.create_table()?;`, factory functions,
   table functions, `lurek.set("<module>", tbl)?;`, `Ok(())`

**Each closure body must have exactly ONE domain call.** No loops, no conditionals, no inline math, no struct construction with 3+ fields.

---

## Step 6 — Validate

```powershell
python tools/validate/validate_lua_api.py src/lua_api/<module>_api.rs
```

Exit 0 = pass. Fix ALL errors and warnings. Repeat until clean.

**After validator passes, also manually check** (validator cannot catch these):
- Every `methods.add_method*(` call — multi-line or not — has `/// @return <type>` immediately above it
- No `impl mlua::UserData` — must be `impl LuaUserData` (prelude form)
- No `/// @return any` — must be a specific type
- No plain comment (`// …`) immediately above `///` docstring lines
- Every Lua function parameter stored without `LuaRegistryKey` — must use `create_registry_value`

---

## Step 7 — Compile Check

```powershell
cargo check --lib 2>&1 | Select-String "error"
```

Fix every compile error. Do not commit with errors.

---

## Step 8 — Register in mod.rs

If the module is new (not already in `src/lua_api/mod.rs`), add:

```rust
mod <module>_api;
```

And in `create_lua_vm()`:

```rust
<module>_api::register(&lua, &luna, state.clone())?;
```

---

## Done When

- Step 0 inventory is complete (both sources listed as a table)
- All business logic migrated to domain module (no loops/conditionals in closures)
- `python tools/validate/validate_lua_api.py src/lua_api/<module>_api.rs` exits 0
- `cargo check --lib 2>&1 | Select-String "error"` produces no output
- Every `methods.add_method*(` call has a docstring with `@return` above it
- No `impl mlua::UserData` (use prelude `impl LuaUserData`)
- No `/// @return any` anywhere in the file
- Lua callbacks stored via `LuaRegistryKey` (not raw `LuaFunction` captures)
- Module registered in `mod.rs`
