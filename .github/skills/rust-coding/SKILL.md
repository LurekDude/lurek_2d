---
name: rust-coding
description: "Load this skill when writing or reviewing Rust code in the Lurek2D engine. It owns safe Rust conventions, error handling patterns, module structure, and idiomatic Rust for game engine development. Skip it for Lua scripting, CAG files, or documentation."
---
# rust-coding

## Mission

# Rust Coding — Lurek2D Engine

## When To Load

- Writing new Rust code in any `src/` module
- Reviewing Rust code for convention compliance
- Fixing Rust compilation errors or clippy warnings
- Refactoring Rust code for clarity or safety

## When To Skip

- Lua scripting patterns → use `lua-scripting` skill
- Graphics pipeline specifics → use `gpu-programming` skill
- Physics algorithms → use `physics-engine` skill
- Performance optimization → use `performance-profiling` skill

## Domain Knowledge

### Owns
- Safe Rust coding conventions for Lurek2D
- Error handling with `Result<T>` and `EngineError`
- `Rc<RefCell<SharedState>>` usage patterns
- Module visibility rules (`pub` vs `pub(crate)`)
- Import style (absolute paths)

### Live Repository Contracts
- `src/lib.rs` — all module re-exports via `pub mod`
- `src/runtime/error.rs` — `EngineError` enum definition
- `src/lua_api/mod.rs` — `SharedState` struct and `create_lua_vm()` function

### Decision Rules
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
- **No tests in `src/`**: Never add `#[cfg(test)]` or `mod tests { … }` to any file under `src/`. All Rust tests live in `tests/rust/unit/<module>_tests.rs`.
- **`mod.rs` is declarations only**: `src/<module>/mod.rs` must contain ONLY `pub mod`, `pub use`, and `pub(crate)` re-exports. All implementation goes into named sub-files (`circle.rs`, `spline.rs`, etc.). The reviewer will reject any struct, enum, impl, or fn found in `mod.rs`.

### Module Group System
Lurek2D source is organized in five responsibility groups — no cycles, ever:

| Group | Modules | May import |
|-------|---------|-----------|
| Foundations | `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns` | Pure algorithms — no render/audio/input/Lua deps |
| Core Runtime | `runtime`, `event`, `timer`, `thread`, `network`, `filesystem` | Foundations only |
| Platform Services | `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect` | Foundations + Core Runtime |
| Feature Systems | `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` | Below groups; same-group OK when acyclic |
| Edge/Integration | `app`, `lua_api`, `devtools`, `debugbridge`, `docs`, `pipeline`, `bin` | All groups — nothing below imports these |
| Lunasome | `library/` (pure Lua) | Public `lurek.*` API only |

**Forbidden import patterns:**
> See [examples/module-group-system.rs](examples/module-group-system.rs) for the example.

**Rule**: Before adding a `use crate::` statement, check whether it crosses group boundaries upward. If it does, refactor — never add an exception.

### Build Commands Reference
Use scoped commands during development. Full `cargo test` only at commit time:

| When | Command |
|------|---------|
| Type-check only (no linking) | `cargo check` |
| Test one module | `cargo test --test <module>_tests` |
| Test one Lua suite | `cargo test lua_test_<module>` |
| Lint library only | `cargo clippy --lib` |
| Final gate (before commit) | `cargo test && cargo clippy -- -D warnings` |

**Never run `cargo build` or full `cargo test` during development** — they rebuild the entire engine (~4 min cold) and block parallel work.

### Avoid
- `String::from(...)` or `.to_string()` in hot paths (per-frame code) — pre-allocate or use `&str`
- Unnecessary `.clone()` — pass references or redesign ownership if you find yourself cloning in a loop
- `println!` in engine code — always use `log::info!`, `log::warn!`, `log::error!`, `log::debug!`
- `let _ = result;` — silently discarding errors; use `?` or explicitly handle
- Lua game logic inside `src/lua_api/` rust closures — keep lua_api thin; business logic belongs in domain modules
- `.unwrap()` and `.expect()` outside of tests and CLI tooling
- `#[cfg(test)]` blocks anywhere inside `src/` — test modules in `src/` pollute the domain layer; always use `tests/rust/unit/`
- Any implementation (structs, enums, fns, impls) in `mod.rs` — mod.rs is declarations-only; put all code in named sub-files

## Companion File Index

- [examples/module-group-system.rs](examples/module-group-system.rs) — Module Group System

## References

- See related skills in `.github/skills/`.
