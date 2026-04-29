---
name: lua-runtime
description: "Load this skill when working on LuaJIT vs Lua 5.4 behavior, GC, lua-jit/lua54 features, or Lua runtime performance. Skip it for bindings, general game scripts, or API naming."
---
# lua-runtime

## Mission
- Own Lua runtime behavior, backend differences, and runtime tuning concerns.

## When To Load
- Compare LuaJIT and Lua 5.4 behavior.
- Tune GC or runtime hot paths.
- Review lua-jit or lua54 feature use.
- Diagnose runtime-only scripting differences.

## When To Skip
- Lua-Rust binding work.
- General game scripts.
- API naming.

## Domain Knowledge
- Cargo feature selection controls LuaJIT versus lua54; LuaJIT is the shipping path and lua54 is fallback only.
- Worker VMs under threading are isolated states; no shared Lua VM assumptions survive across threads.
- Runtime concerns here are GC pressure, allocation churn, backend differences, and VM behavior, not API naming.
- Measure runtime differences in release mode and state backend-sensitive behavior explicitly.
- If a backend change affects visible script behavior, reflect it in tests or docs/specs.
- Keep runtime tuning distinct from binding and game-script work.
- Backend-sensitive behavior should be checked against Cargo features, worker VM rules, and release-mode runtime expectations before any compatibility claim is made.
- Runtime tuning here includes GC pressure, LuaJIT vs lua54 behavior, and multi-VM constraints, not boundary conversion or API naming.
- This skill owns scripting runtime characteristics, not gameplay script style.
## Companion File Index
- None.

## References
- Cargo.toml
- src/runtime/
- src/thread/
- docs/specs/thread.md
