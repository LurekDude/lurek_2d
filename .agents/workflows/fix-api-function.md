---
description: "Fix one broken or incorrect lurek.* API function: binding, return type, error behavior, or param handling."
---

# Fix API Function

## Goal
- Fix one specific lurek.* API function at the correct binding layer.

## Inputs
- Function name and namespace.
- Observed failure or contract violation.
- Test or repro that exposes the bug.

## Steps
1. Load lua-rust-bridge, lua-api-design, and error-handling before acting.
2. Read src/lua_api/<module>_api.rs, the nearest Lua test, and docs/specs/<module>.md.
3. Fix the binding at the source: param validation, return type, or error propagation.
4. Do not change the public API shape unless the shape itself is wrong and a migration note is written.
5. Run the narrowest Lua test for the fixed function.

## Success Criteria
- [ ] The binding fix is at the correct source layer.
- [ ] A Lua test covers the fixed behavior.
- [ ] API shape was not changed without a migration note.
- [ ] The narrowest validation passes.

## Example Invocation
- /fix-api-function function=lurek.sprite.get_size symptom=wrong_return_type
