---
name: module-architecture
description: "Load this skill when designing module boundaries, dependency direction, or crate organization for Luna2D. It owns the dependency graph, module responsibility rules, and visibility patterns. Skip it for code implementation or API naming."
---

# Module Architecture — Luna2D Engine

## Load When

- Creating a new module in `src/`
- Evaluating dependency direction between modules
- Refactoring module boundaries
- Checking for dependency violations

## Owns

- Module dependency graph and direction rules
- Module responsibility assignments
- `pub` vs `pub(crate)` visibility decisions
- `lib.rs` module registration
- New module creation checklist

## Does Not Cover

- Code implementation → use `rust-coding` skill
- Lua API naming → use `lua-api-design` skill
- Performance structure → use `performance-profiling` skill

## Live Repository Contracts

- `src/lib.rs` — module re-exports (`pub mod`)
- All `src/*/mod.rs` files — module structure and exports

## Decision Rules

- **Layer model** (strict):
  - `math` → depends on nothing; it is the Baseline leaf
  - `engine` → Baseline runtime lifecycle and shared state
  - Tier 1 Rust modules → depend only on `math` and `engine`
  - Tier 2 Rust modules → depend on Baseline + Tier 1, never other Tier 2 modules
  - `lua_api` → bridge layer that imports engine modules to expose `luna.*`
  - `library/` → Tier 3 Lunasome, pure Lua; when a new gameplay-domain helper can live there, prefer that over a new Rust gameplay module
  - Gameplay-oriented Rust modules still under `src/` are migration-state code, not the target Tier 3 architecture for new work
- **No same-tier cross-imports**: Tier 1 modules must not import other Tier 1 modules; Tier 2 modules must not import other Tier 2 modules
- **One responsibility**: Each module owns one subsystem — no shared kitchen-sink modules
- **mod.rs pattern**: Each module has `mod.rs` for re-exports + separate files for types
- **Visibility**: Default to `pub(crate)`; use `pub` only for types used by `tests/` or external consumers
- **New module checklist**: Create directory, add `mod.rs`, add `pub mod` to `lib.rs` when it belongs in the Rust crate surface, and add tests in the correct registered test family
- **Math is special**: `Vec2`, `Mat3`, `Rect` are foundational — all modules may depend on `math`
