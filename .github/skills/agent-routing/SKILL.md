---
name: agent-routing
description: "Load this skill when routing work between CAG agents, choosing ownership, or shaping Manager handoffs. Skip it for single-agent mode or direct work inside one already-chosen owner."
---
# agent-routing

## Mission
- Own exact routing rules for Manager and the shared handoff contract.
- Keep ownership boundaries explicit across agents.
- Remove duplicated routing prose from agent files.

## When To Load
- Manager handles any multi-agent, unclear-ownership, or phase-splitting task.
- Ownership between two or more agents is unclear.
- A handoff packet or acceptance gate needs shaping.
- CAG edits change the agent graph, ownership map, or routing heuristics.

## When To Skip
- Single-agent mode.
- Direct implementation inside one already-chosen agent.
- Pure code, content, docs, or test work when ownership is already explicit.

## Domain Knowledge
- Only Manager routes between agents; specialists return completion, blocker, or scope-mismatch output.
- Manager must load this skill first on every task that needs routing or handoff shaping.
- Prefer one specialist when one specialist is enough.
- Route to Planner before implementation when work spans 3 or more agents, 5 or more files, or the phase order is unclear.
- Research closes fact gaps; Solver chooses a path after facts exist; Planner phases already-accepted work.
- Debugger diagnoses runtime causes; Developer, Renderer, Physicist, Audio-Eng, Build-Engineer, or Extension-Engineer implement fixes in their owned surfaces.
- Tester adds or updates coverage after behavior is known; Reviewer gates finished diffs instead of rediscovering ownership.
- Spec-Owner owns docs/specs contracts; Doc-Writer owns markdown docs and generated references; Content-Maker owns runnable Lua content and non-markdown support files.
- Manager handoffs stay short: Context, Goal, Inputs, Done When, Return To.
- One phase gets one owner and one binary gate.
- Manager bases accept or reject decisions on specialist outputs, validation results, and work/{session}/ artifacts instead of redoing specialist work.
- Specialists never route directly to peers.
- When ownership is unclear between adjacent roles, choose the narrowest owning artifact class: product code, content, docs, specs, validation, analysis, or orchestration.

## Companion File Index
- .github/agents/README.md
- docs/architecture/cag-system.md

## References
- .github/copilot-instructions.md
- .github/agents/README.md
- docs/architecture/cag-system.md
- .github/agents/manager.agent.md
