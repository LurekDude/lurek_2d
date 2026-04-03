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

Luna2D uses a **four-tier module system** plus two foundation layers. The tier of a module determines what it may import. Violating these rules creates circular dependencies.

**Foundation layers** (always importable by all tiers):
- `math` — leaf, no Luna2D dependencies; all modules may freely import it
- `engine` — app lifecycle, may import all modules

**Import rules by tier:**
- **Tier 1 Basic Core** (`graphics`, `audio`, `physics`, `input`, `timer`, `filesystem`, `compute`, `data`, `image`, `sound`, `event`, `entity`, `window`, `thread`): may only import `math` and `engine`. No Tier 1 ↔ Tier 1 cross-imports.
- **Tier 2 Engine Extensions** (`particle`, `tilemap`, `scene`, `savegame`, `modding`, `graph`, `pathfinding`, `ai`, `dataframe`, `resource`): may import `math`, `engine`, and Tier 1 modules. No Tier 2 ↔ Tier 2 cross-imports.
- **Tier 3 Gameplay Systems** (`combat`, `crafting`, `dialog`, `inventory`, `item`, `quest`, `stats`, `province_map`): may import Tier 1 and Tier 2 modules. No Tier 3 ↔ Tier 3 cross-imports.
- **Tier 4 Platform Integrations** (future): wraps external SDKs; must not be imported by lower tiers.
- `lua_api` is the integration layer and may import any module. Domain modules must **never** import `lua_api`.

Forbidden patterns:
- `use crate::graphics::` inside `src/physics/` (Tier 1 → Tier 1 cross-import)
- `use crate::audio::` inside `src/input/` (Tier 1 → Tier 1 cross-import)
- `use crate::tilemap::` inside `src/particle/` (Tier 2 → Tier 2 cross-import)
- `use crate::combat::` inside `src/inventory/` (Tier 3 → Tier 3 cross-import)
- `use crate::lua_api::` inside any domain module
- `use super::super::` for cross-module navigation

## Compliance

- All new public types need at minimum one integration test in `tests/`
- Float comparisons in tests: `assert!((val - expected).abs() < 1e-5)` — never `assert_eq!` on floats
- Doc comments (`///`) required on all `pub` functions and types

## Build and Check Commands

**During development (fast — use these while implementing):**
```powershell
cargo check                                   # Type-check only — no codegen, no binary
cargo check --lib                             # Type-check the library crate only
cargo test --test <module>_tests -- --nocapture  # Test only the one module you changed
cargo clippy --lib                            # Lint the library only (no test binaries)
```

**Never** run `cargo build` or `cargo test` (full, no filter) during development — it rebuilds
the entire engine (4+ min cold) and blocks all CPU cores. Other agents or the user may be
working in parallel on different modules. Use scoped commands.

**Final gate only (before `git commit`):**
```powershell
cargo test && cargo clippy -- -D warnings
```
`cargo build` is only needed for dist packaging — never add it as a pre-test step.

## Avoid

- `String::from` in hot paths — prefer `&str` for owned-once patterns
- Unnecessary `clone()` — understand when a reference suffices
- `println!` in engine code — use `log::debug!` / `log::warn!` / `log::error!`
- Ignoring `Result` returns with `let _ =`
- Placing Lua-specific logic outside `src/lua_api/`
