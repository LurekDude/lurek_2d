# `<module>` — Agent Reference

<!--
  TEMPLATE — derived from docs/specs/data.md (golden example).
  Copy this file to docs/specs/<module>.md and fill in every section.
  Required sections: all 10 H2 headers below (Summary through Notes).
  The render.md antipattern (copy-pasted API prose) is WRONG.
  The data.md pattern (tables of functions, 1-line descriptions) is RIGHT.
-->

| Property | Value |
|----------|-------|
| **Tier** | Tier N — <name> |
| **Status** | Implemented / Partial / Stub |
| **Lua API** | `lurek.<namespace>` |
| **Source** | `src/<module>/` |
| **Rust Tests** | `tests/rust/unit/<module>_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_<module>.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md` § <section> |

---

## Summary

<!-- 3–6 short paragraphs. Purpose, main types, key design decisions, scope boundary.
     Use bold for the first mention of each major type.
     End with a "Scope boundary" sentence naming any modules this one does NOT depend on. -->

The `<module>` module is …

**TypeA** does X …
**TypeB** does Y …

**Scope boundary**: This module depends only on `math` and `engine` (Baseline). It has no
GPU, audio, or window dependencies.

---

## Architecture

<!-- ASCII box diagram showing data flow through the module.
     Start from the Lua API line → internal components → external crates.
     5–20 lines. Required. -->

```
lurek.<ns>.* (Lua API — src/lua_api/<module>_api.rs)
    │
    ▼
src/<module>/mod.rs
    ├── type_a.rs ── TypeA
    └── type_b.rs ── TypeB (depends on TypeA)
```

---

## Source Files

<!-- One row per .rs file in src/<module>/. 1–2 sentence purpose per file.
     ~5–15 rows typical. DO NOT list files that don't exist. -->

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — declares submodules, re-exports public types. |
| `type_a.rs` | <TypeA description> |
| `type_b.rs` | <TypeB description> |

---

## Submodules

<!-- One H3 per .rs file (excluding mod.rs). 2–4 sentences about what the submodule does
     and how it connects to the rest of the module. Then a bullet list of its public types. -->

### `<module>::type_a`

<What type_a.rs does, its key algorithm or data structure, and how it's used by the rest.>

- **`TypeA`** (struct): <One-line description>.
- **`TypeAConfig`** (struct): <One-line description>.

### `<module>::type_b`

<What type_b.rs does.>

- **`TypeB`** (struct): <One-line description>.
- **`Mode`** (enum): <One-line description — list variants inline>: `VariantA`, `VariantB`.

---

## Key Types

<!-- One H4 per exported Rust type that a developer would touch.
     Cover: what it is, constructors, important methods, relevant fields.
     ~3–6 sentences per type. DO NOT repeat the Lua API table row description here. -->

### Structs

#### `<module>::type_a::TypeA`

<2–4 sentences: what it holds, constructors, key methods used externally.>

#### `<module>::type_b::TypeB`

<2–4 sentences.>

### Enums

#### `<module>::type_b::Mode`

Variants: `VariantA` (<meaning>), `VariantB` (<meaning>). Parsed via `Mode::from_str()`.

---

## Lua API

<!-- This is the CORE section. List EVERY user-visible Lua function.
     Use one row per function. Format: `lurek.ns.fn(params)` → 1-line description.
     Group by functional area. UserData methods go in their own sub-table.
     DO NOT omit any function. DO NOT paste Rust code. DO NOT write paragraphs.
     Target: 1 table row = 1 function = 1 line of description.

     Reference the actual source: src/lua_api/<module>_api.rs
-->

Exposed under `lurek.<namespace>.*` by `src/lua_api/<module>_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.<ns>.newThing(args)` | Creates a … Returns a `Thing` handle. |
| `lurek.<ns>.doSomething(thing, x, y)` | Does X to `thing` at position (x, y). |
| `lurek.<ns>.getCount()` | Returns the total number of active instances. |

### `Thing` Methods

<!-- One sub-table per UserData type that has methods -->

| Method | Description |
|--------|-------------|
| `thing:methodA(param)` | Does A. Returns boolean. |
| `thing:methodB()` | Does B. No return value. |
| `thing:getType()` | Returns the string type name of this object. |

---

## Lua Examples

<!-- 1 runnable Lua code block. Cover the primary use case end-to-end.
     Must be syntactically correct and use only real lurek.* functions.
     10–40 lines. Use comments to label each step. -->

```lua
-- Create and use a Thing
local t = lurek.<ns>.newThing(...)

lurek.process = function(dt)
    t:methodA(true)
end

lurek.render = function()
    lurek.<ns>.doSomething(t, 100, 200)
end
```

---

## Item Summary

<!-- Count every exported public Rust item in the module. -->

| Kind | Count |
|------|-------|
| `struct` | N |
| `enum` | N |
| `fn` (Lua API) | N |
| **Total** | **N** |

---

## References

<!-- Dependencies to OTHER modules. One row per dependency.
     Only list dependencies that actually exist in the code. -->

| Module | Relationship | Notes |
|--------|--------------|-------|
| `math` | Imports `Vec2`, `Color` from `src/math/`. | Read-only; no writes back to `math`. |
| `runtime` | Reads `SharedState` for resource pool access. | — |

---

## Notes

<!-- Anything that doesn't fit above: gotchas, known limitations, performance notes,
     planned changes, migration warnings. 3–8 bullet points. -->

- **Key gotcha**: …
- **Performance**: …
- **Planned**: …
