---
description: "Review module dependencies for correctness: no cross-domain imports, correct dependency direction."
---

# Review Module Dependencies

## Purpose

Audit module dependency graph for violations.

## Steps

1. For each domain module (`graphics`, `physics`, `audio`, `input`, `timer`, `filesystem`, `window`):
   - Check imports — should only use `crate::math::*` from other domain modules
   - No imports from other domain modules
2. Check `engine` — may import from all modules
3. Check `lua_api` — may import from `engine` + all domain modules
4. Report any violations with file path and import line

## Acceptance

- [ ] No cross-domain module dependencies (except through `math`)
- [ ] `engine` dependency direction correct
- [ ] `lua_api` dependency direction correct

## References

- `module-architecture` skill
- System prompt Module Direction rules
