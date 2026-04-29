---
description: "Review a lurek.* API slice for naming, parameter, and contract consistency."
agent: "Lua-Designer"
---
# Review API Consistency

## Goal
- Find inconsistencies in the Lua-facing API contract.

## Inputs
- Target module or API slice.
- Compared APIs or prior art.
- Any reported inconsistency.

## Steps
1. Load [skill: lua-api-design](../skills/lua-api-design/SKILL.md) and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read src/lua_api/, docs/specs/, docs/api/, and nearby examples or tests for the same surface.
3. Focus on naming, return shape, callback style, defaults, and whether the API feels coherent with the rest of lurek.*.
4. State the highest-value consistency fixes and any case where the inconsistency is intentional and documented.

## Success Criteria
- [ ] Findings were listed first, or the prompt states clearly that no findings were found.
- [ ] Each finding is tied to a file, behavior, or missing proof.
- [ ] Missing validation or test coverage is called out.
- [ ] Residual risk or next owner is explicit.

## Anti-patterns
- Lead with summary instead of findings.
- Treat style nits as more important than behavior, safety, or contract drift.
- Declare the area clean without checking tests, validation, or missing proof.

## Example Invocation
- /review-api-consistency module=graphics

## CAG Metadata
Mode: agent
Loads skills: lua-api-design, documentation
Inputs required: Target module or API slice., Compared APIs or prior art., Any reported inconsistency.
