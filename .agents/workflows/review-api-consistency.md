---
description: "Review the lurek.* Lua API for naming and signature consistency across all modules."
---

# Review API Consistency

## Goal
- Find naming, signature, or callback inconsistencies across lurek.* API modules.

## Inputs
- Scope (all or specific namespace prefix).

## Steps
1. Load lua-api-design before acting.
2. Read docs/api/lurek.md and compare naming patterns across all modules.
3. Check: function names use consistent verb style, params are explicit (no hidden positional overloads), callbacks have stable arity, and return types match documented shapes.
4. List all inconsistencies with function names and descriptions.
5. Propose the minimum rename or param fix needed to align each gap.

## Success Criteria
- [ ] All inconsistencies listed with specific function names.
- [ ] Proposals are minimal and backward-compatible where possible.
- [ ] docs/api/lurek.md was not hand-edited.

## Example Invocation
- /review-api-consistency scope=lurek.sprite
