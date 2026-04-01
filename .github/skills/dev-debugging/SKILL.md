---
name: dev-debugging
description: "Load this skill when diagnosing runtime bugs, crashes, or unexpected behavior in Luna2D. It owns diagnostic techniques, error tracing, and root cause analysis patterns. Skip it for feature implementation or test writing."
---

# Development Debugging — Luna2D Engine

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
- **Check callback order**: Bugs often come from state mutation during `luna.draw()` (should be read-only)
- **Type boundary**: Most bugs occur at Lua↔Rust type conversion boundaries
- **Never guess**: Follow the code path, don't assume the cause
