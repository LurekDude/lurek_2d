---
name: error-handling
description: "Load this skill when designing or implementing error handling in Lurek2D: Result types, EngineError variants, Lua error propagation, or panic prevention. Skip it for general Rust coding or test writing."
---

# Error Handling — Lurek2D Engine

## Load When

- Adding new error types or variants to `EngineError`
- Implementing error propagation in Lua bindings
- Converting between error types (EngineError ↔ LuaError)
- Reviewing error handling for completeness

## Owns

- `EngineError` enum design and variants
- Error propagation patterns (`?` operator, `map_err`)
- Lua error surfacing (what the script author sees)
- Panic prevention strategies

## Does Not Cover

- General Rust coding → use `rust-coding` skill
- Lua API design → use `lua-api-design` skill
- Security input validation → use Security agent

## Live Repository Contracts

- `src/engine/error.rs` — `EngineError` enum definition
- `src/lua_api/mod.rs` — error conversion for Lua bindings
- `src/engine/app.rs` — top-level error handling in game loop

## Decision Rules

- **No `.unwrap()` in production**: Use `?` or `unwrap_or_default()` or `map_err()`
- **EngineError for engine**: Module-level errors wrap into `EngineError` variants
- **EngineError for engine errors**: Use `thiserror`-derived `EngineError` enum variants for engine-level errors
- **LuaResult for bindings**: All Lua-callable functions return `LuaResult<T>`
- **Descriptive messages**: Include function name and context in error messages
- **No internal paths to Lua**: Don't expose Rust file paths or internal state in Lua error messages
- **Error chain**: Preserve the original error when wrapping: `map_err(|e| format!("context: {e}"))`
- **Recoverable vs fatal**: Most errors are recoverable — only `panic!` for truly unrecoverable states
- **Callback errors**: Lua callback errors are caught and logged — engine loop continues
