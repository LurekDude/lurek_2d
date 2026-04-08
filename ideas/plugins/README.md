# Luna2D Plugin Architecture — Feature Proposal

**Status**: Proposal / Research Complete
**Created**: 2026-04-08
**Relates to**: A-01 (runtime-only), A-02 (desktop), B-01 (LuaJIT)

## Summary

Split Luna2D from a monolithic ~20 MB binary into a thin runtime executable (~3–5 MB)
plus dynamically-loaded plugin libraries (`.dll` / `.so` / `.dylib`). Each plugin
registers additional `luna.*` Lua API functions. Users select plugins via `conf.toml`
and the runtime discovers and loads them at startup.

## Goals

1. **Thin runtime** — the `luna2d` executable contains only Baseline + Tier 1 modules
2. **Plugin DLLs** — Tier 2 modules, business modules, and third-party extensions ship as separate shared libraries
3. **Configuration-driven** — `conf.toml` declares which plugins to load; no recompile needed
4. **Lua transparency** — scripts call `luna.*` functions regardless of whether they come from the runtime or a plugin
5. **Cross-domain** — same runtime can serve game development, business automation, data science, or education by swapping plugin sets
6. **Embeddable** — the runtime can be used as a Rust library crate (`luna2d-core`) by external hosts (Python, C#, etc.)

## Document Index

| File | Contents |
|------|----------|
| [architecture.md](architecture.md) | Technical architecture, crate layout, ABI strategy, loading sequence |
| [risks.md](risks.md) | Risk assessment, mitigations, assumptions, constraints |
| [roadmap.md](roadmap.md) | Phased implementation plan with acceptance gates |
| [use-cases.md](use-cases.md) | Use cases beyond game development |
| [cross-platform.md](cross-platform.md) | Platform porting: Windows, macOS, Linux, iOS, Android, WASM |
| [integration-modes.md](integration-modes.md) | Executable vs library vs embedded modes |
| [implementation-guide.md](implementation-guide.md) | Step-by-step coding instructions |

## Key Decision

The plugin boundary is the **Lua C API** (`lua_State*`), not Rust types. This avoids
Rust's ABI instability and lets plugins be written in Rust, C, C++, or any language that
can produce a `luaopen_*` symbol. See [architecture.md](architecture.md) for details.

## Design Assumption Updates Required

If this proposal is accepted, the following design assumptions need updating:

- **A-02** may need relaxation if mobile/WASM plugins are pursued (Phase 4+)
- **B-01** LuaJIT must export symbols or use the `libloading`-calls-`luaopen` strategy
- New assumption: **P-01** — Plugin API version must match runtime API version at load time
