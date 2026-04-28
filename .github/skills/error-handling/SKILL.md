---
name: error-handling
description: "Load this skill when designing Result flows, EngineError variants, Lua error propagation, or panic prevention. Skip it for general Rust coding or test work."
---
# error-handling

## Mission
- Own Result flow, EngineError shape, and Lua-visible error behavior.

## When To Load
- Add or change EngineError variants.
- Convert errors across Rust and Lua boundaries.
- Prevent panics in normal runtime paths.
- Review recoverable versus fatal behavior.

## When To Skip
- General Rust implementation.
- Test writing.

## Domain Knowledge
- Prefer Result and explicit propagation over panic paths.
- Keep Lua-visible errors clear and safe.
- Do not leak internal paths or implementation detail in user-facing errors.
- Keep recoverable runtime failures recoverable.
- Use EngineError as the common engine-side error shape.
- Treat callback and boundary errors carefully so the engine stays stable.

## Companion File Index
- None.

## References
- src/runtime/error.rs
- src/lua_api/mod.rs
- src/app/app.rs