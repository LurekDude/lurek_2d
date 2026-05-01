---
description: "Load when designing or implementing lurek.ai.* game behavior like FSMs, behavior trees, GOAP, steering, or squad logic. Skip for Rust AI internals or pathfinding algorithms."
alwaysApply: false
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
- Game-facing AI lives in lurek.ai.* and the best current behavior reference is tests/lua/unit/test_ai_unit.lua.
- Pick FSM, behavior tree, GOAP, utility AI, steering, or squad logic based on authoring clarity and behavior shape.
- Keep blackboards, goals, tags, influence values, and pacing controls visible enough that a Lua author can inspect or reason about behavior.
- AI examples and tests should prove edge states: idle, chase, lose-target, reset, empty world, conflicting goals, no-valid-action.
- Pathfinding algorithms belong to pathfind; this skill focuses on decision making and behavior composition.
- Favor readable game-author wiring over low-level engine cleverness.
- docs/specs/ai.md and the Lua AI tests are the best anchors for what the public AI surface already promises.
- Avoid mixing several paradigms into one behavior just because the engine supports them.

## References
- docs/specs/ai.md
- src/lua_api/ai_api.rs
- tests/lua/unit/test_ai_unit.lua
- docs/specs/pathfind.md
