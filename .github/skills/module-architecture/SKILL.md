---
name: module-architecture
description: "Load this skill when planning module boundaries, dependency direction, or crate layout. Skip it for implementation or API naming."
---
# module-architecture

## Mission
- Own module boundaries, dependency direction, and visibility rules.

## When To Load
- Plan a new module.
- Review module boundaries.
- Fix bad dependency direction.
- Check crate or folder layout.

## When To Skip
- Implementation work.
- API naming.

## Domain Knowledge
- The five tier dependency graph is: Foundations (math, data, serial) → Core Runtime (runtime, app, event) → Platform Services (render, audio, input, window, filesystem) → Feature Systems (physics, animation, ai, particle, tilemap, etc.) → Edge/Integration (lua_api, network, mods, devtools). Any import that goes upward from a lower tier to a higher tier is a binding constraint violation (T-01). Cycles between any two modules are a binding constraint violation (T-02).
- How to audit the current dependency graph: run `python tools/audit/dep_graph.py` (if it exists) or use `cargo tree --edges all | grep -E "->.*src/"`. Compare the result against the tier table. Any edge pointing from a lower tier to a higher tier is a boundary defect.
- `mod.rs` as a manifest: every `src/<module>/mod.rs` must contain only `pub mod`, `pub use`, attributes (`#[allow(...)]` at file level only), and doc comments. No `fn`, `struct`, `impl`, or `const` definitions belong in `mod.rs`. Run `python tools/audit/thin_modrs_audit.py` to find violations. Fix by moving definitions to a sibling file (e.g., `timer_core.rs`).
- How to place a new module: (1) identify the tier it belongs to based on what it depends on — if it needs `render`, it is Feature or Edge, never Foundations; (2) check if an existing module can absorb it as a submodule without growing beyond one clear responsibility; (3) create `src/<module>/mod.rs` as a manifest, implement in sibling files, export only the public API in `mod.rs`, then register in `src/lib.rs`; (4) add `docs/specs/<module>.md` and update `docs/specs/README.md`.
- `src/lua_api/` is a boundary layer: no `src/<module>/` should import from `src/lua_api/`. If domain code needs a type that currently lives in a binding file, move that type to `src/<module>/` first. Binding files import from domain modules — never the reverse.
- When a module wants data from a higher tier: the solution is dependency inversion, not a `pub use` workaround. Define a trait in a lower-tier module, implement it in the higher-tier module, and inject the implementation via the composition root in `src/app/` or `src/runtime/`.
- Cross-module communication rule: within a tier, modules communicate via function calls and struct arguments. Across tiers, prefer passing data through the composition root rather than direct imports. The event system (`src/event/`) and the shared state (`src/runtime/shared_state.rs`) are the sanctioned cross-tier communication paths.
## Companion File Index
- None.

## References
- docs/specs/
- src/lib.rs
- tools/validate/validate_module_coverage.py
- tools/audit/thin_modrs_audit.py
