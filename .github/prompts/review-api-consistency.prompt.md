---
description: "Review Lua API consistency: naming patterns, parameter conventions, return types across all lurek.* modules."
---

# Review API Consistency

## Purpose

Audit the `lurek.*` API surface for naming and convention consistency.

## Steps

1. Read all `src/lua_api/*_api.rs` files
2. Check function naming: `lurek.<module>.<verb>()` pattern
3. Check parameter conventions: `dt`, `x, y`, `key`, `btn`
4. Check return types: all return `LuaResult<T>`
5. Check key name conventions: lowercase strings
6. Compare against `docs/API/lua_api_reference_generated.md` for accuracy
7. Report inconsistencies

## Acceptance

- [ ] All functions follow naming pattern
- [ ] Parameters consistent across modules
- [ ] API reference matches code
- [ ] Key names are lowercase

## References

- `lua-api-design` skill
- `docs/API/lua_api_reference_generated.md`
