---
description: "Tune LuaJIT runtime performance, GC settings, or backend-sensitive script behavior."
---

# Tune Lua Runtime

## Goal
- Improve LuaJIT runtime performance or GC behavior for a specific scenario.

## Inputs
- Scenario or script under analysis.
- Observed issue (GC pressure, slow callbacks, backend quirk).
- Build mode (release required).

## Steps
1. Load lua-runtime and performance-profiling before acting.
2. Build in release mode with LuaJIT backend.
3. Identify whether the issue is GC pressure, allocation churn, JIT-sensitive behavior, or backend mismatch.
4. Tune the narrowest knob: GC step size, allocation reduction, or backend-specific flag.
5. Measure before and after in release mode using the same scenario.
6. Document the tradeoff if a fix is backend-specific.

## Success Criteria
- [ ] Measurements are from release mode with LuaJIT.
- [ ] The tuning is minimal and targeted.
- [ ] Tradeoffs are explicit when the fix is backend-specific.

## Example Invocation
- /tune-lua-runtime scenario=content/games/demo_platformer.lua issue=gc_pressure
