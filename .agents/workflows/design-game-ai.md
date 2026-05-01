---
description: "Design the lurek.ai.* behavior API for one new AI system or paradigm."
---

# Design Game AI

## Goal
- Produce an accepted lurek.ai.* API design for one AI behavior system.

## Inputs
- AI system or behavior goal.
- Paradigm: FSM, BT, GOAP, utility, steering.
- Existing lurek.ai.* surface to stay consistent with.

## Steps
1. Load lua-api-design and game-ai before acting.
2. Read docs/api/lurek.md, docs/specs/ai.md, src/lua_api/ai_api.rs, and tests/lua/unit/test_ai_unit.lua.
3. Draft function signatures, callback shapes, state names, and option table fields.
4. Compare against existing lurek.ai.* patterns for naming and callback consistency.
5. Write or update docs/specs/ai.md with the accepted design before any Rust implementation begins.

## Success Criteria
- [ ] API stays within lurek.ai.* namespace.
- [ ] Names, params, and returns are consistent with existing AI patterns.
- [ ] docs/specs/ai.md is written or updated.
- [ ] No Rust code changed in this phase.

## Example Invocation
- /design-game-ai system=behavior_tree goal=enemy_ai
