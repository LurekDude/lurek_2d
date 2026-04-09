---
name: dev-debugging
description: "Load this skill when diagnosing runtime bugs, crashes, or unexpected behavior in Lurek2D. It owns diagnostic techniques, error tracing, and root cause analysis patterns. Skip it for feature implementation or test writing."
---

# Development Debugging — Lurek2D Engine

## Load When

- Investigating a crash or panic in the engine
- Tracing unexpected behavior in game scripts or engine code
- Analyzing error messages or stack traces
- Debugging RefCell borrow panics or type errors

## Owns

- Rust panic and error trace analysis
- RefCell borrow conflict diagnosis
- Lua/Rust boundary error tracing
- Game loop state diagnosis
- Data flow tracing through SharedState

## Does Not Cover

- Writing fixes → route to Developer agent
- Performance analysis → use `performance-profiling` skill
- Test writing → use `testing-rust` skill

## Live Repository Contracts

- `src/lua_api/mod.rs` — SharedState borrow patterns (common source of bugs)
- `src/engine/app.rs` — main loop where errors surface
- `src/engine/error.rs` — EngineError types for error classification

## Decision Rules

- **Read the panic message**: Rust panics include file, line, and message — start there
- **RefCell panics**: "already borrowed" means two closures are borrowing SharedState simultaneously
- **Lua errors**: Check `LuaError` variant — usually type mismatch or missing function
- **Data flow trace**: Follow the value from Lua callback → SharedState → processing → output
- **Minimal reproduction**: Reduce to the smallest script/state that triggers the bug
- **Log strategically**: Use `log::debug!` or `log::trace!` for temporary diagnostic output
- **Check callback order**: Bugs often come from state mutation during `lurek.draw()` (should be read-only)
- **Type boundary**: Most bugs occur at Lua↔Rust type conversion boundaries
- **Never guess**: Follow the code path, don't assume the cause

---

## Environment Variables for Diagnosis

Set these before launching to get more diagnostic output:

```powershell
# Show all Lurek2D log output (info + debug + trace)
$env:RUST_LOG = "lurek2d=debug"
cargo run -- content/demos/hello_world

# Show only engine startup/shutdown lifecycle events
$env:RUST_LOG = "lurek2d=info"

# Show wgpu validation errors (GPU-related crashes)
$env:RUST_LOG = "wgpu_core=warn,wgpu_hal=warn,lurek2d=debug"

# Full panic backtrace (file + line for every frame)
$env:RUST_BACKTRACE = "1"

# Full backtrace WITH source lines (requires debug symbols)
$env:RUST_BACKTRACE = "full"

# Force a specific GPU backend (useful to isolate driver bugs)
$env:WGPU_BACKEND = "vulkan"   # or "dx12", "metal", "gl"
$env:WGPU_ADAPTER_NAME = "Intel"   # prefer Intel iGPU when multiple adapters present

# Disable JIT compilation (fall back to LuaJIT interpreter — slower but stable)
# Set inside Lua: jit.off()
```

---

## Common Error Patterns

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| `already borrowed: BorrowMutError` | Two closures both `borrow_mut()` SharedState simultaneously | Restructure: do not hold a borrow across a Lua callback |
| `already borrowed: BorrowError` during borrow_mut | SharedState is borrowed immutably when mutable borrow requested | End the immutable borrow before the mutable one begins |
| `LuaError: expected table, got nil` | `lurek.someModule` is nil — module not registered | Check `lua_api/mod.rs` — module may not be in the `register()` call chain |
| `LuaError: attempt to index a nil value` | Lua variable not initialised before use | Trace back where the variable should have been set |
| `SlotMap: key used after removal` | Stale `TextureKey`/`FontKey`/etc. used after `release()` | Check resource lifecycle; never cache keys beyond the resource's lifetime |
| `wgpu ERROR: validation error` | Invalid GPU state (bind group mismatch, incorrect buffer size) | Set `RUST_LOG=wgpu_core=warn` and read the full validation message |
| `C stack overflow` | LuaJIT stack depth exceeded ~800 frames | Flatten recursive algorithms or increase stack size via `jit.opt.start` |
| Blank window, no errors | `lurek.draw()` never called or all draw calls outside canvas scope | Add `print("draw called")` to confirm callback fires |
| Audio device not found | No audio hardware or wrong device selected | Engine falls back to headless audio; check `log::warn` output |

---

## Lua Error Debugging

### Custom error handler

```lua
-- main.lua: catch all unhandled errors before the engine error screen
function lurek.errorhandler(msg)
    -- Log to file + console before showing error screen
    print("UNHANDLED ERROR: " .. tostring(msg))
    lurek.fs.append("errors.log", msg .. "\n")
    return msg   -- return the message to display on error screen
end
```

### pcall for recoverable errors

```lua
-- Wrap risky code in pcall to handle errors without crashing
local ok, err = pcall(function()
    lurek.gfx.newImage("missing.png")
end)
if not ok then
    print("Failed to load image: " .. tostring(err))
    -- use fallback image
end
```

### Tracing Lua→Rust errors

When a `LuaError` originates in Rust and surfaces in Lua, the error message includes the Rust source location if `LuaError::external(e)` was used:

```
RuntimeError("luna2d::graphics: texture file not found: player.png")
```

The prefix `luna2d::<module>:` is the Rust source. Search `src/<module>/` for the error string.

---

## RefCell Borrow Diagnosis

The most common engine crash. When you see:

```
thread 'main' panicked at 'already borrowed: BorrowMutError'
  src/lua_api/graphics_api.rs:42
```

**Pattern**: Two code paths are simultaneously active that both borrow SharedState.

**Typical cause**: A Lua callback is invoked WHILE SharedState is already borrowed by the caller:

```rust
// BAD: borrow held across a Lua call that also borrows
let state = self.state.borrow();      // borrow 1 starts
let val = state.something;
lua.call_function("callback", val)?;  // callback may also borrow_mut → PANIC
drop(state);                          // borrow 1 never reached
```

**Fix**: Release the borrow before invoking any Lua callback:

```rust
// GOOD: clone the value out, release borrow, then call Lua
let val = {
    let state = self.state.borrow();   // borrow starts
    state.something.clone()             // extract value
};                                      // borrow ends HERE
lua.call_function("callback", val)?;   // safe — no active borrow
```

---

## Diagnostic Log Placement

```rust
// Temporary diagnostic: add to a hot path to trace data flow
log::debug!("[DEBUG] value at {} = {:?}", line!(), my_value);

// Remove before commit. Use RUST_LOG=lurek2d=debug to see debug! output.
// Never leave log::debug! in production hot paths (per-frame).
```

**Rule**: `log::debug!` calls have near-zero cost when the log level is above debug (which is the default). Safe to leave in code as long as they don't format complex values.

