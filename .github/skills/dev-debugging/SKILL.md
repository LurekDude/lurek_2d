---
name: dev-debugging
description: "Load this skill when diagnosing runtime bugs, crashes, or unexpected behavior in Lurek2D. It owns diagnostic techniques, error tracing, and root cause analysis patterns. Skip it for feature implementation or test writing."
---
# dev-debugging

## Mission

# Development Debugging — Lurek2D Engine

## When To Load

- Investigating a crash or panic in the engine
- Tracing unexpected behavior in game scripts or engine code
- Analyzing error messages or stack traces
- Debugging RefCell borrow panics or type errors

## When To Skip

- Writing fixes → route to Developer agent
- Performance analysis → use `performance-profiling` skill
- Test writing → use `testing-rust` skill

## Domain Knowledge

### Owns
- Rust panic and error trace analysis
- RefCell borrow conflict diagnosis
- Lua/Rust boundary error tracing
- Game loop state diagnosis
- Data flow tracing through SharedState

### Live Repository Contracts
- `src/lua_api/mod.rs` — SharedState borrow patterns (common source of bugs)
- `src/app/app.rs` — main loop where errors surface
- `src/runtime/error.rs` — EngineError types for error classification

### Decision Rules
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

### Environment Variables for Diagnosis
Set these before launching to get more diagnostic output:

> See [snippets/environment-variables-for-diagnosis.ps1](snippets/environment-variables-for-diagnosis.ps1) for the example.

---

### Common Error Patterns
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

### Lua Error Debugging
### Custom error handler

> See [examples/custom-error-handler.lua](examples/custom-error-handler.lua) for the example.

### pcall for recoverable errors

> See [examples/pcall-for-recoverable-errors.lua](examples/pcall-for-recoverable-errors.lua) for the example.

### Tracing Lua→Rust errors

When a `LuaError` originates in Rust and surfaces in Lua, the error message includes the Rust source location if `LuaError::external(e)` was used:

> See [snippets/tracing-lua-rust-errors.txt](snippets/tracing-lua-rust-errors.txt) for the example.

The prefix `luna2d::<module>:` is the Rust source. Search `src/<module>/` for the error string.

---

### RefCell Borrow Diagnosis

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/environment-variables-for-diagnosis.ps1](snippets/environment-variables-for-diagnosis.ps1) — Environment Variables for Diagnosis
- [examples/custom-error-handler.lua](examples/custom-error-handler.lua) — Custom error handler
- [examples/pcall-for-recoverable-errors.lua](examples/pcall-for-recoverable-errors.lua) — pcall for recoverable errors
- [snippets/tracing-lua-rust-errors.txt](snippets/tracing-lua-rust-errors.txt) — Tracing Lua→Rust errors
- [snippets/refcell-borrow-diagnosis.txt](snippets/refcell-borrow-diagnosis.txt) — RefCell Borrow Diagnosis
- [examples/refcell-borrow-diagnosis-2.rs](examples/refcell-borrow-diagnosis-2.rs) — RefCell Borrow Diagnosis
- [examples/refcell-borrow-diagnosis-3.rs](examples/refcell-borrow-diagnosis-3.rs) — RefCell Borrow Diagnosis
- [examples/diagnostic-log-placement.rs](examples/diagnostic-log-placement.rs) — Diagnostic Log Placement
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
- [tools/dev/test_fix_loop.py](../../../tools/dev/test_fix_loop.py) — agent-friendly test-run / fix / re-run loop for fast iteration on failing tests.
