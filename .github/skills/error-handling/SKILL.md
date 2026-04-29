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
- src/runtime/error.rs is the engine-side error hub; Lua boundaries should convert into clear, safe user-facing failures.
- src/lua_api/ and app startup paths are common sites for recoverable errors that must not panic.
- Avoid leaking absolute paths, raw Rust type names, or internal state details in Lua-visible errors.
- Callback failures, file IO, asset decode, registry-key lookup, and config parsing should prefer Result over panic.
- Recoverable content errors should keep the engine running when possible; reserve fatal paths for unrecoverable boot failures.
- Error wording should match Lua-facing behavior, not only Rust internals.
- Boundary-heavy modules like filesystem, config, asset loading, and lua_api are frequent places where user-visible error quality matters more than internal stack detail.
- Good error paths in this repo distinguish invalid content, missing assets, unsupported runtime state, and engine defects.
- This skill owns failure semantics and safe propagation, not generic logging or metrics analysis.
## Companion File Index
- None.

## References
- src/runtime/error.rs
- src/lua_api/
- src/app/app.rs
- docs/specs/lua-api-file-standard.md
