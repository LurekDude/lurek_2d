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
- game-facing AI lives in lurek.ai.* and the best current behavior reference is tests/lua/unit/test_ai_unit.lua.
- Pick FSM, BT, GOAP, utility AI, steering, or squad logic based on authoring clarity, not engine novelty.
- Keep blackboards, goals, tags, influence, and director pacing visible enough to debug from Lua.
- AI examples should prove edge states like idle, chase, reset, empty world, and conflicting goals.
- Pathfinding algorithms and grid search belong to pathfind, not this skill.
- Favor readable game-author behavior wiring over low-level engine internals.
- docs/specs/ai.md and tests/lua/unit/test_ai_unit.lua are the best current anchors for what the public AI surface already promises.
- Many AI systems here are Lua-facing and headless-testable, so author-facing behavior clarity matters as much as engine internals.
- The skill owns game behavior composition and public AI usage, not low-level pathfinding math or Rust-only internals.
## Companion File Index
- None.

## References
- docs/specs/ai.md
- src/lua_api/ai_api.rs
- tests/lua/unit/test_ai_unit.lua
- docs/specs/pathfind.md
