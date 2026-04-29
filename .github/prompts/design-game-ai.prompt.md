---
description: "Design one gameplay AI pattern using the existing lurek.ai surface."
agent: "Content-Maker"
---
# Design Game AI

## Goal
- Produce one gameplay AI design that fits the current engine surface.

## Inputs
- Gameplay goal.
- Target content context.
- Required AI primitives.
- Constraints or realism target.

## Steps
1. Load [skill: game-ai](../skills/game-ai/SKILL.md) and [skill: lua-scripting](../skills/lua-scripting/SKILL.md) before acting.
2. Read existing lurek.ai usage, nearby content, the relevant API docs, and any scenario constraints before editing.
3. Keep the design inside the shipped AI primitives, make the control loop readable for content authors, and note any engine gap instead of silently inventing new hooks.
4. Check the design against current examples and content patterns, then list any missing API or test support needed before implementation.

## Success Criteria
- [ ] The prompt goal was completed: Produce one gameplay AI design that fits the current engine surface.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /design-game-ai goal=squad_flank context=content/games/tactics

## CAG Metadata
Mode: agent
Loads skills: game-ai, lua-scripting
Inputs required: Gameplay goal., Target content context., Required AI primitives., Constraints or realism target.
