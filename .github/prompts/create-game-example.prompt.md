---
description: "Create one focused game example that teaches a concrete lurek.* capability."
agent: "Content-Maker"
---
# Create Game Example

## Goal
- Add one focused game example with clear teaching value.

## Inputs
- Example name.
- Concept to teach.
- Target APIs.
- Audience level.

## Steps
1. Load [skill: examples-management](../skills/examples-management/SKILL.md), [skill: lua-scripting](../skills/lua-scripting/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read content/examples/, nearby examples, docs/specs/, and any matching content assets before editing.
3. Keep the example self-contained, show real lurek.* usage, and add only the README text needed to explain how to run and understand it.
4. Run the narrowest example load path available and confirm any required registration or docs updates stay in sync.

## Success Criteria
- [ ] The prompt goal was completed: Add one focused game example with clear teaching value.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-game-example name=camera_follow concept=smooth_tracking

## CAG Metadata
Mode: agent
Loads skills: examples-management, lua-scripting, documentation
Inputs required: Example name., Concept to teach., Target APIs., Audience level.
