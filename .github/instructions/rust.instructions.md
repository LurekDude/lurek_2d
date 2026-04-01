---
applyTo: "src/**/*.rs"
---

# Rust Source Instructions

All Rust files in `src/` must follow safe-Rust conventions, use absolute import paths, and never introduce `unsafe` without a documented `// SAFETY:` justification.

## Core Rules

- **No `unsafe`** without a `// SAFETY:` comment explaining invariants upheld
- **Absolute imports only**: `use crate::module::Type` — never `use super::` except inside the same file's nested modules
- **Error handling**: `thiserror` derive for `EngineError` enum; `LuaResult<T>` inside `lua_api/`; only `panic!` in tests
- **No `.unwrap()` in production paths** — use `?`, `.ok_or()`, or structured error propagation
- **Visibility**: prefer `pub(crate)` for cross-module types; only `pub` for cross-crate API surface
- **Format before every commit**: `cargo fmt`; zero clippy warnings: `cargo clippy`
- **Constructors**: prefer `impl Into<T>` for flexible parameter types on public APIs

## Layer / Boundary Rules

Module dependency direction — only these imports are allowed:
- `engine` may depend on all modules
- `lua_api` may depend on `engine` types and all domain modules
- Domain modules (`graphics`, `physics`, `audio`, `input`, `timer`, `filesystem`, `math`, `window`) must **NOT** depend on each other except through `math`
- `math` depends on nothing; it is the foundation layer

Forbidden patterns:
- `use crate::graphics::` inside `src/physics/`
- `use crate::audio::` inside `src/input/`
- `use super::super::` for cross-module navigation

## Compliance

- All new public types need at minimum one integration test in `tests/`
- Float comparisons in tests: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats
- Doc comments (`///`) required on all `pub` functions and types

## Avoid

- `String::from` in hot paths — prefer `&str` for owned-once patterns
- Unnecessary `clone()` — understand when a reference suffices
- `println!` in engine code — use `log::debug!` / `log::warn!` / `log::error!`
- Ignoring `Result` returns with `let _ =`
- Placing Lua-specific logic outside `src/lua_api/`
