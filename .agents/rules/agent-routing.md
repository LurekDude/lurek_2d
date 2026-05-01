---
description: "Load when routing work between agent personas, choosing ownership, or shaping handoffs. Skip for single-agent mode or direct work inside one already-chosen owner."
alwaysApply: false
---

# agent-routing

## Mission
- Own exact routing rules for handoffs.
- Keep ownership boundaries explicit across agent personas.
- Remove duplicated routing prose from rule files.

## When To Load
- Handling any multi-agent, unclear-ownership, or phase-splitting task.
- Ownership between two or more agents is unclear.
- A handoff or acceptance gate needs shaping.
- Rule edits change the agent graph, ownership map, or routing heuristics.

## When To Skip
- Single-agent mode.
- Direct implementation inside one already-chosen owner.
- Pure code, content, docs, or test work when ownership is already explicit.

## Domain Knowledge
- Prefer one specialist when one specialist is enough.
- Route to planning before implementation when work spans 3 or more agents, 5 or more files, or the phase order is unclear.
- Research closes fact gaps; Solver chooses a path after facts exist; roadmap-planning phases already-accepted work.
- Debugger (dev-debugging) diagnoses runtime causes; Developer, Renderer, Physicist, Audio-Eng, Build-Engineer, or Extension-Engineer implement fixes in their owned surfaces.
- Tester adds or updates coverage after behavior is known; Reviewer gates finished diffs instead of rediscovering ownership.
- Spec-Owner owns docs/specs contracts; Doc-Writer owns markdown docs and generated references; Content-Maker owns runnable Lua content.
- Handoffs stay short: Context, Goal, Inputs, Done When, Return To.
- One phase gets one owner and one binary gate.
- Specialists never route directly to peers.
- When ownership is unclear between adjacent roles, choose the narrowest owning artifact class.

## References
- .agents/rules/systems.md
- docs/architecture/cag-system.md
