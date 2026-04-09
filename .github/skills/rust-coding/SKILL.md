---
name: rust-coding
description: "Load this skill when writing or reviewing Rust code in the Lurek2D engine. It owns safe Rust conventions, error handling patterns, module structure, and idiomatic Rust for game engine development. Skip it for Lua scripting, CAG files, or documentation."
---

# Rust Coding — Lurek2D Engine

## Load When

- Writing new Rust code in any `src/` module
- Reviewing Rust code for convention compliance
- Fixing Rust compilation errors or clippy warnings
- Refactoring Rust code for clarity or safety

## Owns

- Safe Rust coding conventions for Lurek2D
- Error handling with `Result<T>` and `EngineError`
- `Rc<RefCell<SharedState>>` usage patterns
- Module visibility rules (`pub` vs `pub(crate)`)
- Import style (absolute paths)

## Does Not Cover

- Lua scripting patterns → use `lua-scripting` skill
- Graphics pipeline specifics → use `gpu-programming` skill
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

## Module Tier System

Lurek2D source is organized in a strict tier direction — no circular deps:

| Tier | Modules | May import |
|------|---------|-----------|
| Foundation — Baseline | `math`, `engine` | `math` has no deps; `engine` imports `math` |
| Tier 1 — Core | `graphics`, `audio`, `physics`, `input`, `timer`, `filesystem`, `compute`, `data`, `image`, `sound`, `event`, `entity`, `window`, `thread` | Baseline only — no T1↔T1 cross-imports |
| Tier 2 — Extensions | `particle`, `tilemap`, `scene`, `savegame`, `modding`, `graph`, `pathfinding`, `ai`, `dataframe`, `resource` | Baseline + Tier 1 — no T2↔T2 cross-imports |
| Tier 3 — Lunasome | `content/library/` (pure Lua) | Public `lurek.*` API only |
| Bridge layer | `lua_api` | All tiers — domain modules never import `lua_api` |

**Forbidden import patterns:**
```rust
// WRONG — Tier 1 importing Tier 1
use crate::graphics::GpuRenderer;  // from inside src/audio/
use crate::audio::Mixer;           // from inside src/graphics/

// WRONG — domain module importing lua_api
use crate::lua_api::something;     // from inside src/physics/

// CORRECT — always absolute, stay within tier rules
use crate::engine::SharedState;    // Tier 1 importing Baseline
use crate::math::Vec2;             // any tier importing math
```

**Rule**: Before adding a `use crate::` statement, check whether it crosses tier boundaries. If it does, refactor — never add an exception.

## Build Commands Reference

Use scoped commands during development. Full `cargo test` only at commit time:

| When | Command |
|------|---------|
| Type-check only (no linking) | `cargo check` |
| Test one module | `cargo test --test <module>_tests` |
| Test one Lua suite | `cargo test lua_test_<module>` |
| Lint library only | `cargo clippy --lib` |
| Final gate (before commit) | `cargo test && cargo clippy -- -D warnings` |

**Never run `cargo build` or full `cargo test` during development** — they rebuild the entire engine (~4 min cold) and block parallel work.

## Avoid

- `String::from(...)` or `.to_string()` in hot paths (per-frame code) — pre-allocate or use `&str`
- Unnecessary `.clone()` — pass references or redesign ownership if you find yourself cloning in a loop
- `println!` in engine code — always use `log::info!`, `log::warn!`, `log::error!`, `log::debug!`
- `let _ = result;` — silently discarding errors; use `?` or explicitly handle
- Lua game logic inside `src/lua_api/` rust closures — keep lua_api thin; business logic belongs in domain modules
- `.unwrap()` and `.expect()` outside of tests and CLI tooling
