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
- LuaJIT is the shipping runtime (binding constraint B-01). `lua54` is a non-shipping CI fallback for platforms where LuaJIT is unavailable. Any behavior change acceptable only on lua54 must be guarded with `#[cfg(feature = "lua54")]` in Rust and documented explicitly.
- Per-frame table creation is the most common GC pressure source: `{}` inside `on_process` allocates every frame and triggers GC pauses. Reuse pre-allocated tables via `table.clear()` (LuaJIT extension) or pre-build state tables during `on_init`.
- LuaJIT JIT compilation is per-trace, not per-function. A hot loop with a polymorphic function call (different metatable types per iteration) disables JIT for that trace. Profile with `jit.dump()` or `luajit -jdump` to confirm whether a hot path is compiled.
- LuaJIT `ffi` is available and useful for tight numerical loops, but ffi types must not cross the Lua-Rust boundary through mlua — they are LuaJIT internal types and cause crashes on the Rust side.
- `table.pack` and `table.unpack` behavior differs between LuaJIT and lua54: LuaJIT follows Lua 5.1 semantics, lua54 uses 5.4 semantics. When writing cross-backend compatible code, avoid these for vararg packing; use explicit tables instead.
- `string.format` with `%d` on a float truncates silently in LuaJIT (5.1 behavior) but raises an error in lua54 (5.4 behavior). Any format string must be tested against both backends in CI if it handles numbers.
- Worker VM isolation: each worker thread runs an independent Lua VM. `lurek.thread.channel` is the only safe communication path between VMs. No global state, no shared tables, no shared userdata handles can cross VM boundaries — mlua will refuse or panic.
- The `require` cache (`package.loaded`) is per-VM. A library loaded in the main VM is not automatically available in a worker VM. Each worker must `require` its dependencies explicitly.
- GC tuning knobs: `collectgarbage("setpause", n)` and `collectgarbage("setstepmul", n)`. Default settings are appropriate for most games. Only tune when `lurek.debug.frame_stats()` shows `lua_gc_ms` above 1 ms consistently.
- When filing a Lua runtime bug, always state: feature flag used (`luaJIT` or `lua54`), reproduction script (minimal, deterministic), observed vs expected behavior, and whether the issue is LuaJIT-only, lua54-only, or both.
## Companion File Index
- None.

## References
- Cargo.toml
- src/runtime/
- src/thread/
- docs/specs/thread.md
