# `bin` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | Indirect / none |
| **Source** | `src/bin/` |
| **Rust Tests** | None dedicated |
| **Lua Tests** | None |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The bin module holds alternative compiled entry points for the engine. It exists so the project can ship or develop with different binary behaviors while still routing all real startup logic through the shared library crate.

Right now the important distinction is between the main console-attached launcher and the console-less Windows launcher under src/bin/. The bin module keeps that packaging concern separate from engine startup behavior, which still belongs in lib.rs and app.

This module does not own configuration parsing, platform initialization, splash behavior, or the event loop. If a change affects engine boot semantics rather than which binary wrapper calls into them, it belongs somewhere else.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Edge/Integration layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
No direct Lua namespace — consumed through app/runtime integration or other bindings
    |
    v
src/bin/mod.rs
    |- lurekc.rs - lurekc
```

---

## Source Files

| File | Purpose |
|------|---------|
| `lurekc.rs` | Minimal console-less launcher for Windows builds that applies the windows_subsystem attribute and then delegates straight to lurek2d::lurek_run(). This file should stay intentionally tiny because it is only a wrapper binary. |

---

## Submodules

### `bin::lurekc`

Minimal console-less launcher for Windows builds that applies the windows_subsystem attribute and then delegates straight to lurek2d::lurek_run(). This file should stay intentionally tiny because it is only a wrapper binary.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `main`

The only meaningful symbol in this module is the binary entry function in lurekc.rs.

---

## Lua API

This module does not expose a dedicated direct Lua namespace. It is consumed indirectly through higher-level engine callbacks, shared state, or other `lurek.*` surfaces.

---

## Lua Examples

```lua
-- This module has no dedicated direct Lua namespace.
-- It is used indirectly through other engine systems.
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 0 |
| `enum` | 0 |
| `fn` (Lua API) | 0 |
| **Total** | **0** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/bin/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.
