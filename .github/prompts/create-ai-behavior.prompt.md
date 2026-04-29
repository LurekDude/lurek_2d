---
description: "Create one Lua-side AI behavior using the current lurek.ai surface."
agent: "Content-Maker"
---
# Create AI Behavior

## Goal
- Add one bounded gameplay AI behavior in Lua content.

## Inputs
- Behavior goal.
- Target content file or library.
- Relevant AI module or API.
- Expected demo or test path.

## Steps
1. Load [skill: game-ai](../skills/game-ai/SKILL.md) and [skill: lua-scripting](../skills/lua-scripting/SKILL.md) before acting.
2. Read the target content file, nearby lurek.ai usage, matching examples, and the accepted API surface before editing.
3. Use current lurek.ai behavior primitives, keep the behavior runnable in content, and avoid inventing new engine-side APIs from the prompt layer.
4. Run the narrowest content check or test that exercises the new behavior and confirm any required registration stays in sync.

## Success Criteria
- [ ] The prompt goal was completed: Add one bounded gameplay AI behavior in Lua content.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-ai-behavior file=content/examples/guard.lua goal=patrol_and_chase

## CAG Metadata
Mode: agent
Loads skills: game-ai, lua-scripting
Inputs required: Behavior goal., Target content file or library., Relevant AI module or API., Expected demo or test path.
