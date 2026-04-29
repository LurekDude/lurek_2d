---
description: "Create or extend one event pattern in the engine without breaking ownership boundaries."
agent: "Developer"
---
# Create Event Pattern

## Goal
- Add one bounded event flow in the correct owner layer.

## Inputs
- Event goal.
- Owning module.
- Publishers and consumers.
- Expected validation path.

## Steps
1. Load [skill: module-architecture](../skills/module-architecture/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Read src/event/, the owning module, nearby event producers or consumers, and any matching spec text before editing.
3. Keep event shape and ownership explicit, avoid ad hoc global signaling, and surface failures where the producing or consuming side can actually act on them.
4. Run the narrowest test or build path that proves the new event flow and confirm no unrelated event surface drifted.

## Success Criteria
- [ ] The prompt goal was completed: Add one bounded event flow in the correct owner layer.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-event-pattern module=runtime goal=scene_transition_notifications

## CAG Metadata
Mode: agent
Loads skills: module-architecture, rust-coding, error-handling
Inputs required: Event goal., Owning module., Publishers and consumers., Expected validation path.
