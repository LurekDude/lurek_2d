---
description: "Add or fix one lurek.* API function end-to-end: Rust binding, Lua surface, test, and doc sync."
---

# Create API Function

## Goal
- Add or fix one lurek.* API function with correct binding, test, and doc coverage.

## Inputs
- Function name and lurek.* namespace.
- Accepted API shape.
- Target src/lua_api/ file.
- Required validation.

## Steps
1. Load lua-api-design, lua-rust-bridge, rust-coding, and testing-rust before acting.
2. Read src/lua_api/<module>_api.rs, src/<module>/, docs/specs/<module>.md, and nearby examples before editing.
3. Add or fix the binding in src/lua_api/<module>_api.rs, keeping logic thin and moving behavior into src/<module>/.
4. Update or add a Lua test in tests/lua/ and regenerate Lua API docs from source.
5. Run the narrowest test for the changed function, then widen to the full module test target.

## Success Criteria
- [ ] Binding is thin and delegates to the correct src/<module>/ logic.
- [ ] A Lua test covers the new or changed behavior.
- [ ] Lua API docs are regenerated.
- [ ] No generated artifact was hand-edited.

## Example Invocation
- /create-api-function function=lurek.sprite.set_color
