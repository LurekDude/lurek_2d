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

- **Dependency direction** (strict):
  - `math` → depends on nothing (foundational)
  - `graphics`, `physics`, `audio`, `input`, `timer`, `filesystem`, `window` → depend only on `math`
  - `engine` → may depend on ALL domain modules
  - `lua_api` → depends on `engine` + ALL domain modules
- **No cross-domain deps**: `graphics` must NOT import from `physics`, `audio`, etc. (and vice versa)
- **One responsibility**: Each module owns one subsystem — no shared kitchen-sink modules
- **mod.rs pattern**: Each module has `mod.rs` for re-exports + separate files for types
- **Visibility**: Default to `pub(crate)`; use `pub` only for types used by `tests/` or external consumers
- **New module checklist**: Create directory, add `mod.rs`, add `pub mod` to `lib.rs`, add tests
- **Math is special**: `Vec2`, `Mat3`, `Rect` are foundational — all modules may depend on `math`
