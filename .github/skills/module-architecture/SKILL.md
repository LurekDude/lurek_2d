---
name: module-architecture
description: "Load this skill when designing module boundaries, dependency direction, or crate organization for Lurek2D. It owns the dependency graph, module responsibility rules, and visibility patterns. Skip it for code implementation or API naming."
---
# module-architecture

## Mission

# Module Architecture — Lurek2D Engine

## When To Load

- Creating a new module in `src/`
- Evaluating dependency direction between modules
- Refactoring module boundaries
- Checking for dependency violations

## When To Skip

- Code implementation → use `rust-coding` skill
- Lua API naming → use `lua-api-design` skill
- Performance structure → use `performance-profiling` skill

## Domain Knowledge

### Owns
- Module dependency graph and direction rules
- Module responsibility assignments
- `pub` vs `pub(crate)` visibility decisions
- `lib.rs` module registration
- New module creation checklist

### Live Repository Contracts
- `src/lib.rs` — module re-exports (`pub mod`)
- All `src/*/mod.rs` files — module structure and exports

### Decision Rules
- **Five-group responsibility model** (strict — see `docs/architecture/engine-architecture.md`):
  - **Foundations**: `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns` — pure algorithms and data, no render/audio/input/Lua deps
  - **Core Runtime**: `runtime`, `event`, `timer`, `thread`, `network`, `filesystem` — engine lifecycle, timing, events, threading
  - **Platform Services**: `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect` — OS-facing backends
  - **Feature Systems**: `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` — game-domain services; same-group imports allowed when acyclic
  - **Edge/Integration**: `app`, `lua_api`, `devtools`, `debugbridge`, `docs`, `pipeline`, `bin` — composition root; nothing below imports these
  - `library/` → Lunasome, pure Lua; when a new gameplay-domain helper can live there, prefer that over a new Rust module
- **No upward imports**: lower groups must not import higher groups. Feature Systems allows same-group imports only when the dependency graph remains acyclic
- **One responsibility**: Each module owns one subsystem — no shared kitchen-sink modules
- **Thin `mod.rs` rule (TST-04)**: Every `mod.rs` contains ONLY `pub mod X;` declarations, `pub use X::*;` re-exports, module-level attributes (`#![...]`), and doc comments. Function / struct / enum / trait / `impl` definitions MUST live in sibling files such as `src/<module>/facade.rs`, `src/<module>/register.rs`, or topic-named files. Reinforces Zen Rule 7 ("split by reason to change"). Full text: [philosophy.md § Testing Constraints](../../../docs/architecture/philosophy.md#testing-constraints). Enforcement: `thin_modrs_audit.py` scheduled to land in `tools/audit/` during session `testing-cleanup-20260420` P3.
- **Visibility**: Default to `pub(crate)`; use `pub` only for types used by `tests/` or external consumers
- **New module checklist**: Create directory, add `mod.rs` (thin — declarations only), add sibling files for types/impls, add `pub mod` to `lib.rs` when it belongs in the Rust crate surface, and add tests in the correct registered test family
- **Math is special**: `Vec2`, `Mat3`, `Rect` are foundational — all modules may depend on `math`

## Companion File Index

- (no companion files extracted)

## References

- See related skills in `.github/skills/`.
