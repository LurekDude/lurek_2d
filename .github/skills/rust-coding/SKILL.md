---
name: rust-coding
description: "Load this skill when writing or reviewing Rust code in the Luna2D engine. It owns safe Rust conventions, error handling patterns, module structure, and idiomatic Rust for game engine development. Skip it for Lua scripting, CAG files, or documentation."
---

# Rust Coding — Luna2D Engine

## Load When

- Writing new Rust code in any `src/` module
- Reviewing Rust code for convention compliance
- Fixing Rust compilation errors or clippy warnings
- Refactoring Rust code for clarity or safety

## Owns

- Safe Rust coding conventions for Luna2D
- Error handling with `Result<T>` and `EngineError`
- `Rc<RefCell<SharedState>>` usage patterns
- Module visibility rules (`pub` vs `pub(crate)`)
- Import style (absolute paths)

## Does Not Cover

- Lua scripting patterns → use `lua-scripting` skill
- Graphics pipeline specifics → use `software-rendering` skill
- Physics algorithms → use `physics-engine` skill
- Performance optimization → use `performance-profiling` skill

## Live Repository Contracts

- `src/lib.rs` — all module re-exports via `pub mod`
- `src/engine/error.rs` — `EngineError` enum definition
- `src/lua_api/mod.rs` — `SharedState` struct and `create_lua_vm()` function

## Decision Rules

- **No `unsafe`** unless absolutely necessary — document with `// SAFETY:` comment
- **Error propagation**: Use `?` operator, never `.unwrap()` in production paths
- **Visibility**: Default to `pub(crate)`, use `pub` only for cross-crate API
- **Imports**: Always use absolute paths: `use crate::module::Type;`
- **Constructors**: `impl Into<T>` for flexible parameters, `new()` as primary constructor
- **Closures capturing SharedState**: Clone the `Rc`, then `let state = state.clone();` before `move ||`
- **RefCell borrows**: Keep borrow scope as small as possible, never hold across async boundaries
- **Formatting**: Run `cargo fmt` before commit, `cargo clippy` must produce 0 warnings
- **Testing**: Every public function should have at least one test
- **Naming**: Types are `PascalCase`, functions are `snake_case`, constants are `SCREAMING_SNAKE_CASE`
