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
- Game-facing AI lives in lurek.ai.* and the best current behavior reference is tests/lua/unit/test_ai_unit.lua, so public behavior should stay grounded in what authors can already exercise headlessly.
- Pick FSM, behavior tree, GOAP, utility AI, steering, or squad logic based on authoring clarity and behavior shape, not on engine novelty or theoretical completeness.
- Keep blackboards, goals, tags, influence values, and pacing controls visible enough that a Lua author can inspect or reason about behavior when something feels wrong.
- AI examples and tests should prove edge states such as idle, chase, lose-target, reset, empty world, conflicting goals, and no-valid-action cases.
- Pathfinding algorithms, grid search, and route math belong to pathfind; this skill focuses on decision making and behavior composition above that layer.
- Favor readable game-author wiring over low-level engine cleverness; if a behavior graph is hard to read, it will be harder to tune than to implement.
- docs/specs/ai.md and the Lua AI tests are the best current anchors for what the public AI surface already promises, so design should stay consistent with those expectations.
- Many AI systems here are Lua-facing and headless-testable, which means clarity of state names, transitions, and goal evaluation matters as much as internal efficiency.
- Avoid mixing several paradigms into one behavior just because the engine supports them; choose the simplest model that captures the behavior cleanly.
- Good AI content in this repo should make intent obvious: what the agent wants, what state it is in, and why it changed state now.
- This skill owns game behavior composition, author-facing AI patterns, and public lurek.ai.* usage, not low-level pathfinding math or Rust-only internals.
## Companion File Index
- None.

## References
- docs/specs/ai.md
- src/lua_api/ai_api.rs
- tests/lua/unit/test_ai_unit.lua
- docs/specs/pathfind.md
