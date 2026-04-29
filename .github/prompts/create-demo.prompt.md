---
description: "Create a runnable demo in content/games/ with the required registration and smoke coverage."
agent: "Content-Maker"
---
# Create Demo

## Goal
- Create one runnable demo that proves a concrete engine or content slice.

## Inputs
- Demo name.
- Theme or mechanic.
- Target APIs.
- Expected smoke-test coverage.

## Steps
1. Load [skill: demo-creation](../skills/demo-creation/SKILL.md) and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read content/games/, neighboring demos, tests/lua/content/games/, tests/demo_smoke_tests.rs, and harness registration before editing.
3. Keep the demo focused, runnable, and honest about the current API; update conf, registration, and README files when the demo shape requires them.
4. Run the narrowest demo load or smoke path available and confirm the demo registration and tests stay aligned.

## Success Criteria
- [ ] The prompt goal was completed: Create one runnable demo that proves a concrete engine or content slice.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-demo name=lighting_lab theme=2d_lights

## CAG Metadata
Mode: agent
Loads skills: demo-creation, documentation
Inputs required: Demo name., Theme or mechanic., Target APIs., Expected smoke-test coverage.
