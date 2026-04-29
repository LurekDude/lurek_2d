---
description: "Design one lurek.* API slice before implementation."
agent: "Lua-Designer"
---
# Design API Surface

## Goal
- Produce a bounded Lua API design that is ready for implementation.

## Inputs
- Target module.
- Capability goal.
- User-facing use case.
- Known constraints or compatibility concerns.

## Steps
1. Load [skill: lua-api-design](../skills/lua-api-design/SKILL.md), [skill: lua-scripting](../skills/lua-scripting/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read the current lurek.* surface, docs/specs/, nearby examples, and any accepted architecture notes before editing.
3. Focus on naming, parameters, returns, callbacks, and consistency; stop before implementation and record any tradeoff that affects later bindings.
4. Check the design against nearby APIs and usage patterns, then call out open compatibility risk or missing source truth instead of inventing certainty.

## Success Criteria
- [ ] The prompt goal was completed: Produce a bounded Lua API design that is ready for implementation.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /design-api-surface module=window capability=modal_dialog

## CAG Metadata
Mode: agent
Loads skills: lua-api-design, lua-scripting, documentation
Inputs required: Target module., Capability goal., User-facing use case., Known constraints or compatibility concerns.
