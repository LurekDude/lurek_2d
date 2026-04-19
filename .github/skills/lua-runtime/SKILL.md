---
name: lua-runtime
description: "Load this skill when working with the Lua scripting runtime in Lurek2D: LuaJIT vs Lua 5.4 behavioral differences, the lua-jit and lua54 Cargo feature flags, mlua 0.9 specifics, garbage collector tuning, LuaJIT bitwise ops, upvalue and stack limits, string interning, or Lua performance patterns. Use for: LuaJIT FFI, GC pressure, per-frame Lua optimisation, Lua 5.4 compat testing. Skip it for the Rust binding layer (use lua-rust-bridge), general Lua game scripting (use lua-scripting), or Lua API design (use lua-api-design)."
---
# lua-runtime

## Mission

# Lua Runtime — Lurek2D

## When To Load

- Investigating LuaJIT vs Lua 5.4 behavioral differences
- Choosing or switching the `lua-jit` / `lua54` Cargo feature flag
- Tuning the Lua garbage collector to reduce GC pauses
- Hitting a LuaJIT upvalue limit, stack overflow, or JIT compilation error
- Writing performance-critical Lua code and needing to understand JIT behavior
- Debugging unexpected number type coercions or integer arithmetic differences
- Using the LuaJIT FFI library
- Writing Lua 5.4 compatibility test code

## When To Skip

- Skip it for the Rust binding layer (use lua-rust-bridge), general Lua game scripting (use lua-scripting), or Lua API design (use lua-api-design).

## Domain Knowledge

### Owns
- LuaJIT vs Lua 5.4 feature and behavior comparison
- `lua-jit` / `lua54` Cargo feature flags and their implications
- mlua 0.9 VM creation and configuration
- Garbage collector lifecycle and tuning
- LuaJIT limits (upvalues, stack depth, string interning, trace compilation)
- Lua 5.4 exclusive features (integers, `//`, bitwise `&|~^`, `<close>`, generational GC)
- Per-Lua-VM performance patterns

---

### Backend Feature Flags
> See [templates/backend-feature-flags.toml](templates/backend-feature-flags.toml) for the example.

Build with non-default backend:

> See [snippets/backend-feature-flags-2.ps1](snippets/backend-feature-flags-2.ps1) for the example.

**Rule**: The shipping binary always uses `lua-jit`. The `lua54` flag is for CI compatibility testing only.

---

### LuaJIT vs Lua 5.4 — Behavior Differences
| Feature | LuaJIT (primary) | Lua 5.4 (fallback) |
|---------|------------------|--------------------|
| Number type | `number` is always `double` (64-bit float) | Two types: `integer` (64-bit int) and `float` |
| Integer arithmetic | `1 / 2 == 0.5` (float) | `1 // 2 == 0` (integer floor div) |
| Bitwise ops | Requires `bit` library: `bit.band(a, b)` | Native operators: `a & b`, `a \| b`, `a ~ b` |
| `type(1)` | `"number"` | `"number"` (both float and integer return `"number"`) |
| `math.type(1)` | Not available | `"integer"` or `"float"` |
| GC mode | Incremental (one-step) | Incremental OR generational |
| `jit.*` module | Available: `jit.on()`, `jit.off()`, `jit.status()` | Not available |
| FFI | `require("ffi")` — LuaJIT C FFI | Not available |
| `table.move` | Not available | Available |
| `string.pack` / `string.unpack` | Not available | Available |
| Integer literal `1LL` | Available in LuaJIT extensions | Use `1` (native integer) |
| `goto` statement | Available | Available |
| `<close>` (to-be-closed) | Not available | Available |

### Writing cross-compatible Lua

If your code must run on both backends:

> See [examples/writing-cross-compatible-lua.lua](examples/writing-cross-compatible-lua.lua) for the example.

---

### Garbage Collector
### LuaJIT GC

LuaJIT uses a simple **incremental tri-color mark-and-sweep** GC. Parameters:

> See [examples/luajit-gc.lua](examples/luajit-gc.lua) for the example.

**Per-frame rule**: Never call `collectgarbage("collect")` in `lurek.update()` or `lurek.draw()` — it stalls the frame. Schedule it during loading screens only.

### Lua 5.4 GC

Adds a **generational mode** (experimental in 5.4):
> See [examples/lua-5-4-gc.lua](examples/lua-5-4-gc.lua) for the example.

### GC pressure reduction (applies to both)

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [templates/backend-feature-flags.toml](templates/backend-feature-flags.toml) — Backend Feature Flags
- [snippets/backend-feature-flags-2.ps1](snippets/backend-feature-flags-2.ps1) — Backend Feature Flags
- [examples/writing-cross-compatible-lua.lua](examples/writing-cross-compatible-lua.lua) — Writing cross-compatible Lua
- [examples/luajit-gc.lua](examples/luajit-gc.lua) — LuaJIT GC
- [examples/lua-5-4-gc.lua](examples/lua-5-4-gc.lua) — Lua 5.4 GC
- [examples/gc-pressure-reduction-applies-to-both.lua](examples/gc-pressure-reduction-applies-to-both.lua) — GC pressure reduction (applies to both)
- [examples/upvalue-limit-workaround.lua](examples/upvalue-limit-workaround.lua) — Upvalue limit workaround
- [examples/luajit-ffi.lua](examples/luajit-ffi.lua) — LuaJIT FFI
- [examples/local-caching-critical-for-hot-loops.lua](examples/local-caching-critical-for-hot-loops.lua) — Local caching (critical for hot loops)
- [examples/avoid-metatables-on-hot-paths.lua](examples/avoid-metatables-on-hot-paths.lua) — Avoid metatables on hot paths
- [examples/string-interning.lua](examples/string-interning.lua) — String interning
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
