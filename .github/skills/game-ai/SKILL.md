---
name: game-ai
description: "Load this skill when designing or implementing lurek.ai.* game behavior like FSMs, behavior trees, GOAP, steering, or squad logic. Skip it for Rust AI internals or pathfinding algorithms."
---
# game-ai

## Mission
- Own game-facing AI patterns built on lurek.ai.*.

## When To Load
- Design or write FSM, BT, GOAP, steering, or utility AI.
- Build enemy or NPC behavior.
- Connect AI to game actions.

## When To Skip
- Rust AI internals.
- Pathfinding algorithm work.

## Domain Knowledge
- Start from game behavior, not engine internals.
- Pick one AI model that fits the problem.
- Keep state and transitions clear.
- Keep debug visibility in mind.
- Test edge cases like idle, chase, lose target, and reset.
- Use lurek.ai.* patterns consistently.

## Companion File Index
- None.

## References
- docs/specs/ai.md
- docs/specs/pathfind.md
