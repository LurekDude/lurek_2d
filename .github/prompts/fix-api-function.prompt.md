---
description: "Fix a broken or incorrect Lua API function: signature, behavior, or error handling."
---

# Fix API Function

## Purpose

Fix a broken `luna.*` API function.

## Inputs

- **Function**: Which `luna.*` function is broken
- **Expected behavior**: What it should do
- **Actual behavior**: What it currently does

## Steps

1. Read the binding in `src/lua_api/<module>_api.rs`
2. Read the underlying engine code
3. Identify the discrepancy
4. Fix the binding or engine code
5. Update `docs/lua_api_reference.md` if signature changed
6. Verify with test

## Acceptance

- [ ] Function behaves as documented
- [ ] API reference accurate
- [ ] Tests pass

## References

- `lua-api-design` skill
- `docs/lua_api_reference.md`
