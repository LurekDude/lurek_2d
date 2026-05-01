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
- `src/runtime/error.rs` defines `EngineError` with distinct variants — never collapse distinct failure classes (asset missing, shader compile, audio decode, IO, config parse) into a generic `String` variant. Each variant enables targeted recovery logic.
- Lua-visible error messages follow this pattern: `map_err(|e| mlua::Error::RuntimeError(format!("lurek.audio.play: {}", e)))`. Include the module and function in the message so content authors can locate the failing call without a Rust stack trace.
- Recoverable vs. fatal classification: `asset_not_found` is recoverable — log at warn, return `nil` or a fallback. `shader_compile_failed` is fatal — abort render pipeline, surface a developer-visible message. Config parse errors at startup are fatal. Missing optional asset at runtime is recoverable.
- The `src/lua_api/` and app startup paths are the highest-risk panic sites. Every boundary function must return `mlua::Result<T>` and propagate with `?`, never `unwrap()` or `expect()` unless the invariant is truly unbreakable and commented.
- Do not log and re-wrap the same error at every layer. One `error!()` at the origination site plus one `map_err()` for context at the boundary is the pattern. Duplicate logs at three layers make traces unreadable.
- Leak no internals in outward messages: no absolute filesystem paths (use relative from GameFS root), no raw Rust type names, no memory addresses or internal handle IDs. Content authors see a stable error surface, not implementation detail.
- Callback and thread-crossing errors: preserve the error category and a human-readable string across channel sends. Receivers need to decide retry-vs-abort, so the error type must survive the send without losing its intent.
- Five distinct failure classes to treat separately: invalid content (bad asset, wrong data shape), missing required resource, unsupported runtime state (API called in wrong phase), unavailable external resource (file IO), and engine defect (internal assertion or logic error). Each implies a different response — reject input, fallback, reject call, retry, and panic respectively.
- When converting from `std::io::Error`, `image::ImageError`, or similar external errors into `EngineError`, choose the variant by semantic meaning not by the source type. An IO error reading a .png is an asset error, not a generic IO error.
- `panic!` is acceptable only for internal invariant violations that indicate a programmer error, not for any user-input-triggered path. All `unwrap()` on user-facing paths must be replaced with explicit error propagation.
## Companion File Index
- None.

## References
- src/runtime/error.rs
- src/lua_api/
- src/app/app.rs
- docs/specs/lua-api-file-standard.md
