---
description: "Write or update API reference documentation for luna.* functions. Use when new Lua bindings are added or existing ones change. Produces updated docs/API/lua_api_reference_generated.md."
---

# Doc: API Reference

**Purpose**: Write accurate, complete API reference documentation for `luna.*` Lua functions.
**Use When**: New `luna.*` functions are implemented, existing signatures change, or documentation is found to be stale.
**Scope**: `docs/API/lua_api_reference_generated.md` only.

## Inputs

- `FUNCTIONS` — list of `luna.*` functions to document (e.g., `luna.gfx.setColor`, `luna.audio.setLooping`)
- `SOURCE_FILES` — corresponding Rust source files in `src/lua_api/` to read for accurate signatures

## Steps

1. Load skill `documentation/SKILL.md`
2. For each function to document:
   a. Read the Rust implementation in `src/lua_api/<module>_api.rs`
   b. Identify the exact parameter types and names from the `create_function` closure
   c. Identify return value (what Lua receives back)
   d. Note any optional parameters (those with defaults or guarded by `if` in the closure)
3. Open `docs/API/lua_api_reference_generated.md`
4. Find the correct sub-section (e.g., `## luna.gfx`)
5. Write the entry following this format:
   ```
   ### luna.<module>.<function>([params])
   Description in one sentence.
   - `param` — type, range or valid values
   - Returns: what Lua gets back (or nothing)
   ```
6. Verify all key names are lowercase: `"space"` not `"Space"`
7. Verify color parameters are documented as `[0.0, 1.0]` float range

## Outputs

- Updated `docs/API/lua_api_reference_generated.md` with accurate, complete entries for all specified functions
- No entries for functions that don't exist in `src/lua_api/`

## Acceptance

- [ ] Every listed function has an entry in `docs/API/lua_api_reference_generated.md`
- [ ] Parameter names match the Rust implementation
- [ ] Optional parameters are marked `[optional]` or given a default value
- [ ] Return values documented
- [ ] Key names in docs match `key_to_string()` mapping

## References

**Required Skills**: `documentation`, `lua-api-design`
**Suggested Agents**: `Doc-Writer`
**Related Prompts**: `design-api-surface.prompt.md`
**Docs**: `docs/API/lua_api_reference_generated.md`, `src/lua_api/`
