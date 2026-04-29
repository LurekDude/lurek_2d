---
description: "Expand an existing example into a clearer, more complete teaching artifact."
agent: "Content-Maker"
---
# Flesh Out Example

## Goal
- Improve one example without turning it into a demo or library.

## Inputs
- Existing example path.
- Missing concept or gap.
- Audience level.
- Required runnable proof.

## Steps
1. Load [skill: examples-management](../skills/examples-management/SKILL.md), [skill: documentation](../skills/documentation/SKILL.md), and [skill: lua-scripting](../skills/lua-scripting/SKILL.md) before acting.
2. Read the existing example, nearby examples, the related API docs or spec, and any missing assets before editing.
3. Preserve the example's original teaching goal, add only the missing setup or concept coverage, and keep the example easy to read and run.
4. Run the narrowest load path for the example and confirm the new content still teaches one coherent idea.

## Success Criteria
- [ ] The prompt goal was completed: Improve one example without turning it into a demo or library.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /flesh-out-example file=content/examples/camera.lua gap=zoom_controls

## CAG Metadata
Mode: agent
Loads skills: examples-management, documentation, lua-scripting
Inputs required: Existing example path., Missing concept or gap., Audience level., Required runnable proof.
