---
description: "Tune one Lua runtime behavior or performance-sensitive path in the engine."
agent: "Developer"
---
# Tune Lua Runtime

## Goal
- Adjust one Lua runtime path without widening scope.

## Inputs
- Runtime concern.
- Target path.
- Repro or measurement.
- Acceptance gate.

## Steps
1. Load [skill: lua-runtime](../skills/lua-runtime/SKILL.md) and [skill: rust-coding](../skills/rust-coding/SKILL.md) before acting.
2. Read the smallest repro, the owning runtime or bridge code, and any current measurement or test evidence before editing.
3. Keep the change inside the controlling runtime path, preserve LuaJIT-first constraints, and document any behavior difference instead of hiding it.
4. Rerun the same repro or narrow runtime test first, then widen validation only if the focused path improved or was fixed.

## Success Criteria
- [ ] The prompt goal was completed: Adjust one Lua runtime path without widening scope.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /tune-lua-runtime path=src/runtime concern=callback_overhead

## CAG Metadata
Mode: agent
Loads skills: lua-runtime, rust-coding
Inputs required: Runtime concern., Target path., Repro or measurement., Acceptance gate.
