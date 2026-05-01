---
description: "Review one entity's lifecycle: creation, update, destruction, and Lua-visible handle safety."
---

# Review Entity Lifecycle

## Goal
- Audit one entity type for correct creation, update, destruction, and handle safety.

## Inputs
- Entity type and owning module.
- Lua-visible handle or key.
- Any known lifecycle concern.

## Steps
1. Load rust-coding, lua-rust-bridge, and error-handling before acting.
2. Read the owning src/<module>/ code, the Lua binding in src/lua_api/<module>_api.rs, docs/specs/<module>.md, and any nearby lifecycle test.
3. Check: creation is correct, update path preserves invariants, destruction is explicit and handles are invalidated, and Lua never holds a dangling reference.
4. Report findings with severity and the narrowest fix location.

## Success Criteria
- [ ] Findings are listed with file and line references.
- [ ] Handle safety is verified.
- [ ] Destruction and invalidation path is correct.
- [ ] No dangling Lua references found or remaining risk is explicit.

## Anti-patterns
- Allow Lua to hold raw pointers or internal handles.
- Skip checking the destruction path.

## Example Invocation
- /review-entity-lifecycle entity=PhysicsBody module=physics
