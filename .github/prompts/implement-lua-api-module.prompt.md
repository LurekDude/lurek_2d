---
description: "Build or rebuild a lurek.* Lua API module from domain module source. Reads domain pub fn signatures, designs the Lua surface, then writes..."
agent: Lua-Designer
tools: [tools/validate/validate_lua_api.py]
---
# Implement Lua Api Module

## Goal

Rebuild `src/lua_api/<module>_api.rs` as a thin wrapper over the domain module `src/<module>/`.
Business logic belongs in the domain module. The lua_api file is a bridge only.

## Inputs

- `LuaRegistryKey` — value supplied by the user invocation.
- `module` — value supplied by the user invocation.
- `module_name` — value supplied by the user invocation.
- `type` — value supplied by the user invocation.

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Methods present in `lua_api_old` but missing from the domain → add them to the domain in Step 3
3. Domain methods not yet exposed in the old API → decide whether to expose them
4. Business logic inside old closures (loops, conditionals, struct construction) → flag for extraction
5. Expose every meaningful method. Omit: `new()` (replaced by Lua factory), internal helpers, `Default`.
6. Lua names: `snake_case` → `camelCase`. Constructor factories use `new` prefix: `newAgent`.
7. Types: bool→boolean, f64/f32→number, i32/i64→integer, String→string, Option<T>→`type?`, UserData wrapper→wrapper name, no return→nil. NEVER write `any`.
8. For Lua callback parameters: use `LuaFunction` in the signature; store with `lua.create_registry_value(func)?` → `LuaRegistryKey`.
9. `add_method` for read-only wrapper access; `add_method_mut` only when the wrapper struct itself is mutated (e.g. updating a stored `Option<LuaRegistryKey>`).
10. Add `pub fn` with `///` docstring to the domain module (following `rust-coding` skill).
11. Follow the **Business Logic Migration Pattern** from the `lua-api-design` skill.
12. Verify it compiles: `cargo check --lib 2>&1 | Select-String "error"`.

## Success Criteria

- [ ] Step 0 inventory is complete (both sources listed as a table)
- [ ] All business logic migrated to domain module (no loops/conditionals in closures)
- [ ] `python tools/validate/validate_lua_api.py src/lua_api/<module>_api.rs` exits 0
- [ ] `cargo check --lib 2>&1 | Select-String "error"` produces no output
- [ ] Every `methods.add_method*(` call has a docstring with `@return` above it
- [ ] No `impl mlua::UserData` (use prelude `impl LuaUserData`)
- [ ] No `/// @return any` anywhere in the file
- [ ] Lua callbacks stored via `LuaRegistryKey` (not raw `LuaFunction` captures)
- [ ] Module registered in `mod.rs`

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/implement-lua-api-module <LuaRegistryKey> <module> <module_name> <type>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-api-design, rust-coding
- **Inputs required**: LuaRegistryKey, module, module_name, type
