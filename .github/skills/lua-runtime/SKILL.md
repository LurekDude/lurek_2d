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
- LuaJIT is the main runtime and shipping path.
- lua54 is a fallback and compatibility path, not the shipping target.
- Keep runtime assumptions explicit when behavior differs by backend.
- Treat GC and allocation pressure as runtime concerns, not API-shape concerns.
- Keep worker VM limits and multi-VM rules in mind for threaded Lua work.
- Verify feature-flag behavior against Cargo.toml when backend selection matters.

## Companion File Index
- None.

## References
- Cargo.toml
- src/runtime/
- docs/specs/thread.md