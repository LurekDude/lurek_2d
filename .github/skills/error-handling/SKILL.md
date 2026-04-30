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
- src/runtime/error.rs is the engine-side error hub, and Lua boundaries should translate failures into clear, safe user-facing messages that preserve meaning without leaking internals.
- src/lua_api/ and app startup paths are common sites for recoverable errors that must not panic; these are the places where boundary quality matters more than raw stack detail.
- Avoid leaking absolute paths, raw Rust type names, private handles, or internal state details in Lua-visible errors unless that detail is truly required for the user to fix content.
- Callback failures, file IO, asset decode, registry-key lookup, channel handoff, and config parsing should prefer Result-based flow over panic or silent ignore behavior.
- Recoverable content errors should keep the engine running when possible, while fatal exits should be reserved for unrecoverable boot, renderer, or configuration failures that prevent safe continuation.
- Good error wording here matches Lua-facing behavior and next action, not just Rust internals; say what failed and what kind of input or state caused it.
- Distinguish invalid content, missing assets, unsupported runtime state, unavailable resource, and engine defect as separate failure classes because they imply different fixes and different severity.
- Preserve internal context in Rust where useful, but sanitize the outward message so content authors see a stable error contract instead of implementation trivia.
- When an error crosses async or threaded boundaries, preserve enough category information that the receiver can still decide whether to retry, abort, or surface a fatal message.
- Do not log and rewrap the same failure at every layer; one well-placed error with clear propagation is better than duplicate noise.
## Companion File Index
- None.

## References
- src/runtime/error.rs
- src/lua_api/
- src/app/app.rs
- docs/specs/lua-api-file-standard.md
