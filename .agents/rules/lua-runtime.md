---
description: "Load when working on LuaJIT vs Lua 5.4 behavior, GC, lua-jit/lua54 features, or Lua runtime performance. Skip for bindings, general game scripts, or API naming."
alwaysApply: false
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
- Cargo feature selection controls LuaJIT versus lua54, and LuaJIT is the shipping path while lua54 remains a fallback, so runtime assumptions should start from LuaJIT unless compatibility work says otherwise.
- Worker VMs under threading are isolated states, which means no shared Lua VM assumptions survive across threads even if the Rust side coordinates them.
- Runtime concerns here are GC pressure, allocation churn, backend differences, JIT-sensitive behavior, and VM execution characteristics, not API naming or boundary conversion.
- Measure runtime differences in release mode and state backend-sensitive behavior explicitly; dev-mode impressions are not reliable evidence for Lua runtime tuning.
- If a backend change affects visible script behavior, performance, or supported idioms, reflect it in tests or docs/specs so compatibility expectations stay explicit.
- Keep runtime tuning distinct from binding work and general Lua script style; a GC or backend issue is not the same problem as a poor API or messy main.lua.
- Backend-sensitive behavior should always be checked against Cargo features, worker VM rules, and real runtime mode before any compatibility claim is made.
- Avoid designing around one accidental backend quirk unless the repo explicitly chooses that tradeoff and documents it; fallback behavior still matters even when LuaJIT is primary.
- When tuning hot Lua paths, look for allocation churn, transient table creation, and unnecessary cross-VM work before assuming the JIT alone will save the path.

## References
- Cargo.toml
- src/runtime/
- src/thread/
- docs/specs/thread.md
