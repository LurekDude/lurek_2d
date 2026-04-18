> See [examples/gc-pressure-reduction-applies-to-both.lua](examples/gc-pressure-reduction-applies-to-both.lua) for the example.

---

### LuaJIT Limits
| Limit | Value | What happens when exceeded |
|-------|-------|--------------------------|
| Upvalues per closure | 60 | Compile error: "too many upvalues" |
| Stack depth (C frames) | ~800 | `C stack overflow` error |
| String buffer length | 2^31 - 1 | Allocation error |
| Table entries (array) | 2^26 | Allocation error |
| Loaded modules | No limit | Memory pressure |
| JIT trace length | 1000 IR instructions | Trace aborted; falls back to interpreter |

### Upvalue limit workaround

> See [examples/upvalue-limit-workaround.lua](examples/upvalue-limit-workaround.lua) for the example.

---

### LuaJIT FFI
LuaJIT's `ffi` library allows calling C functions directly from Lua without a Rust binding:

> See [examples/luajit-ffi.lua](examples/luajit-ffi.lua) for the example.

**Rules for Lurek2D:**
- FFI is only available with the `lua-jit` feature
- Guard FFI code with a backend check: `if type(require) == 'function' then pcall(require, 'ffi') end`
- **Do not expose raw FFI pointers through a `lurek.*` API** — safety boundary violation
- FFI is appropriate for compute-heavy Lua scripts; use Rust side for engine internals

---

### Performance Patterns
### Local caching (critical for hot loops)

> See [examples/local-caching-critical-for-hot-loops.lua](examples/local-caching-critical-for-hot-loops.lua) for the example.

### Avoid metatables on hot paths

LuaJIT can JIT-compile table indexing but struggles with `__index` metamethods on every access:

> See [examples/avoid-metatables-on-hot-paths.lua](examples/avoid-metatables-on-hot-paths.lua) for the example.

### String interning

LuaJIT interns all strings (one copy per unique string). Do NOT mutate strings in hot loops:

> See [examples/string-interning.lua](examples/string-interning.lua) for the example.

---

### mlua 0.9 Notes
`mlua = { version = "0.9", default-features = false }` — key behaviors:

- `Lua::new()` creates a VM with no stdlib. Use `Lua::new_with(StdLib::...)` to load specific libs.
- Lurek2D creates the VM in `src/lua_api/mod.rs` with a safe stdlib subset.
- `LuaError::external(e)` wraps any `std::error::Error` as a Lua error — standard pattern at boundary.
- `lua.load(chunk).exec()` for executing a string; `.call::<T>(args)` for calling result.
- Thread safety: `mlua::Lua` is **not** `Send` by default. Workers use separate `Lua` instances.
- The `send` feature enables `Lua: Send` for use in `std::thread::spawn` — Lurek2D uses this for worker threads.
