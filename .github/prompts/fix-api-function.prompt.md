---
description: "Fix a broken or incorrect Lua API function: signature, behavior, or error handling."
---

# Fix API Function

## Purpose

Fix a broken `lurek.*` API function.

## Inputs

- **Function**: Which `lurek.*` function is broken
- **Expected behavior**: What it should do
- **Actual behavior**: What it currently does

## Steps

1. Read the binding in `src/lua_api/<module>_api.rs`
2. Read the underlying engine code
3. Identify the discrepancy
4. Fix the binding or engine code
5. Update `docs/API/lua_api_reference_generated.md` if signature changed
6. Verify with test

## Acceptance

- [ ] Function behaves as documented
- [ ] API reference accurate
- [ ] Tests pass

## References

- `lua-api-design` skill
- `docs/API/lua_api_reference_generated.md`
