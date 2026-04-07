---
name: lua-runtime
description: "Load this skill when working with the Lua scripting runtime in Luna2D: LuaJIT vs Lua 5.4 behavioral differences, the lua-jit and lua54 Cargo feature flags, mlua 0.9 specifics, garbage collector tuning, LuaJIT bitwise ops, upvalue and stack limits, string interning, or Lua performance patterns. Use for: LuaJIT FFI, GC pressure, per-frame Lua optimisation, Lua 5.4 compat testing. Skip it for the Rust binding layer (use lua-rust-bridge), general Lua game scripting (use lua-scripting), or Lua API design (use lua-api-design)."
---

# Lua Runtime — Luna2D

## Load When

- Investigating LuaJIT vs Lua 5.4 behavioral differences
- Choosing or switching the `lua-jit` / `lua54` Cargo feature flag
- Tuning the Lua garbage collector to reduce GC pauses
- Hitting a LuaJIT upvalue limit, stack overflow, or JIT compilation error
- Writing performance-critical Lua code and needing to understand JIT behavior
- Debugging unexpected number type coercions or integer arithmetic differences
- Using the LuaJIT FFI library
- Writing Lua 5.4 compatibility test code

## Owns

- LuaJIT vs Lua 5.4 feature and behavior comparison
- `lua-jit` / `lua54` Cargo feature flags and their implications
- mlua 0.9 VM creation and configuration
- Garbage collector lifecycle and tuning
- LuaJIT limits (upvalues, stack depth, string interning, trace compilation)
- Lua 5.4 exclusive features (integers, `//`, bitwise `&|~^`, `<close>`, generational GC)
- Per-Lua-VM performance patterns

---

## Backend Feature Flags

```toml
# Cargo.toml
default = ["lua-jit"]
lua-jit = ["mlua/luajit", "mlua/vendored"]  # primary: JIT compilation (x86_64 + ARM64)
lua54   = ["mlua/lua54",  "mlua/vendored"]  # fallback: pure interpreter
```

Build with non-default backend:

```powershell
# Lua 5.4 (no LuaJIT, for CI or cross-compilation)
cargo build --no-default-features --features lua54
cargo test  --no-default-features --features lua54
```

**Rule**: The shipping binary always uses `lua-jit`. The `lua54` flag is for CI compatibility testing only.

---

## LuaJIT vs Lua 5.4 — Behavior Differences

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

```lua
-- Bitwise ops: detect backend
local bit = bit or {}  -- LuaJIT: global `bit` table; Lua 5.4: not needed
local function band(a, b)
    if bit.band then return bit.band(a, b) end  -- LuaJIT
    return a & b                                  -- Lua 5.4
end

-- Integer division: compatible floor div
local function idiv(a, b) return math.floor(a / b) end
```

---

## Garbage Collector

### LuaJIT GC

LuaJIT uses a simple **incremental tri-color mark-and-sweep** GC. Parameters:

```lua
-- Default: pause=200 (restart after heap grows 200%), step=200 (step multiplier)
collectgarbage("setpause", 100)    -- restart GC sooner (lower memory peak)
collectgarbage("setstepsize", 400) -- larger steps (less frequent interruptions)

-- Force a full collection (loading screen / level transitions only)
collectgarbage("collect")

-- Query current heap size in KB
local kb = collectgarbage("count")
```

**Per-frame rule**: Never call `collectgarbage("collect")` in `luna.update()` or `luna.draw()` — it stalls the frame. Schedule it during loading screens only.

### Lua 5.4 GC

Adds a **generational mode** (experimental in 5.4):
```lua
-- Generational adds "young" generation to reduce full-collection cost
collectgarbage("generational", minor_threshold, major_threshold)
collectgarbage("incremental")  -- revert to incremental
```

### GC pressure reduction (applies to both)

```lua
-- BAD: creates a new table every frame (200+ KB/s GC pressure)
function luna.process(dt)
    local args = { x = player.x, y = player.y }  -- heap allocation
    processArgs(args)
end

-- GOOD: pre-allocate and reuse
local _args = {}
function luna.process(dt)
    _args.x = player.x
    _args.y = player.y
    processArgs(_args)
end
```

---

## LuaJIT Limits

| Limit | Value | What happens when exceeded |
|-------|-------|--------------------------|
| Upvalues per closure | 60 | Compile error: "too many upvalues" |
| Stack depth (C frames) | ~800 | `C stack overflow` error |
| String buffer length | 2^31 - 1 | Allocation error |
| Table entries (array) | 2^26 | Allocation error |
| Loaded modules | No limit | Memory pressure |
| JIT trace length | 1000 IR instructions | Trace aborted; falls back to interpreter |

### Upvalue limit workaround

```lua
-- Hitting upvalue limit? Move state into a table:
-- BAD (each captured var = 1 upvalue):
local a, b, c, d, e, f ... = ...  -- 60 upvalues max
local function doWork()
    use(a, b, c, d, e, f ...)     -- uses all 60
end

-- GOOD: use one upvalue (the table):
local state = { a=a, b=b, c=c, d=d, e=e, f=f ... }
local function doWork()
    use(state.a, state.b ...)
end
```

---

## LuaJIT FFI

LuaJIT's `ffi` library allows calling C functions directly from Lua without a Rust binding:

```lua
local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned char uint8_t;
    void memset(void *b, int c, size_t len);
]]

-- Use with cdata pointers — do NOT pass to non-ffi Lua code
local buf = ffi.new("uint8_t[?]", 1024)
ffi.C.memset(buf, 0, 1024)
```

**Rules for Luna2D:**
- FFI is only available with the `lua-jit` feature
- Guard FFI code with a backend check: `if type(require) == 'function' then pcall(require, 'ffi') end`
- **Do not expose raw FFI pointers through a `luna.*` API** — safety boundary violation
- FFI is appropriate for compute-heavy Lua scripts; use Rust side for engine internals

---

## Performance Patterns

### Local caching (critical for hot loops)

```lua
-- BAD: global lookup every iteration (~5x slower in LuaJIT)
for i = 1, 10000 do
    math.sin(i)
end

-- GOOD: cache the function reference once
local sin = math.sin
for i = 1, 10000 do
    sin(i)
end
```

### Avoid metatables on hot paths

LuaJIT can JIT-compile table indexing but struggles with `__index` metamethods on every access:

```lua
-- BAD: __index metamethod on every `obj.x` access prevents JIT optimization
local obj = setmetatable({}, { __index = function(t, k) return defaults[k] end })

-- GOOD: flatten into a plain table when performance matters
local obj = { x = 0, y = 0, vx = 0, vy = 0 }
```

### String interning

LuaJIT interns all strings (one copy per unique string). Do NOT mutate strings in hot loops:

```lua
-- BAD: creates a new string object on every frame
local key = "player_" .. tostring(id)   -- new allocation each frame

-- GOOD: pre-build the string table as a lookup
local KEYS = {}
for i = 1, 100 do KEYS[i] = "player_" .. tostring(i) end
-- Then in hot loop:
local key = KEYS[id]   -- no allocation
```

---

## mlua 0.9 Notes

`mlua = { version = "0.9", default-features = false }` — key behaviors:

- `Lua::new()` creates a VM with no stdlib. Use `Lua::new_with(StdLib::...)` to load specific libs.
- Luna2D creates the VM in `src/lua_api/mod.rs` with a safe stdlib subset.
- `LuaError::external(e)` wraps any `std::error::Error` as a Lua error — standard pattern at boundary.
- `lua.load(chunk).exec()` for executing a string; `.call::<T>(args)` for calling result.
- Thread safety: `mlua::Lua` is **not** `Send` by default. Workers use separate `Lua` instances.
- The `send` feature enables `Lua: Send` for use in `std::thread::spawn` — Luna2D uses this for worker threads.
