---
description: "Design or implement a lurek.ai.* game behavior pattern: FSMs, behavior trees, GOAP, steering, or squad logic."
---

# Create AI Behavior

## Goal
- Author one working AI behavior for an NPC or enemy.

## Inputs
- Behavior goal.
- NPC or entity type.
- lurek.ai.* APIs to use.
- Test or runnable proof target.

## Steps
1. Load game-ai and lua-scripting before acting.
2. Read docs/specs/ai.md, src/lua_api/ai_api.rs, and the nearest existing AI test or example before writing.
3. Choose the simplest paradigm that captures the behavior clearly: FSM, BT, GOAP, utility, or steering.
4. Wire the behavior using only lurek.ai.* calls; keep state visible and inspect-able.
5. Add a Lua test or content proof for the authored behavior.

## Success Criteria
- [ ] The behavior is implemented using lurek.ai.*.
- [ ] State, transitions, and goal evaluation are clear.
- [ ] A Lua test or demo proof covers the behavior.

## Anti-patterns
- Mix multiple AI paradigms in one behavior with no clear reason.
- Hide state transitions inside opaque closures.
- Assume the behavior works without a test.

## Example Invocation
- /create-ai-behavior goal=patrol_and_chase entity=guard
