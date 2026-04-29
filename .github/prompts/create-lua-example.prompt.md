---
description: "Create one Lua example that demonstrates a concrete API or pattern."
agent: "Content-Maker"
---
# Create Lua Example

## Goal
- Add one runnable Lua example with clear teaching value.

## Inputs
- Example name.
- Target API or pattern.
- Audience level.
- Required assets or setup.

## Steps
1. Load [skill: examples-management](../skills/examples-management/SKILL.md), [skill: lua-scripting](../skills/lua-scripting/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read content/examples/, nearby Lua examples, the matching API docs or spec, and any asset constraints before editing.
3. Use the real API exactly as shipped, keep the example small enough to teach one idea, and update light documentation only where it helps discovery.
4. Run the narrowest example load path and confirm the example still matches the current public API.

## Success Criteria
- [ ] The prompt goal was completed: Add one runnable Lua example with clear teaching value.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-lua-example name=timers target=timer.after

## CAG Metadata
Mode: agent
Loads skills: examples-management, lua-scripting, documentation
Inputs required: Example name., Target API or pattern., Audience level., Required assets or setup.
