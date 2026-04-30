---
name: lua-api-design
description: "Load this skill when designing or changing the lurek.* Lua API surface. It owns naming, params, callbacks, and consistency. Skip it for Rust internals or pure Lua scripts."
---
# lua-api-design

## Mission
- Own the public lurek.* API shape for game authors.

## When To Load
- Add or change a lurek.* function.
- Review naming or param shape.
- Align callbacks and return types.

## When To Skip
- Rust internals.
- Pure Lua game scripts.

## Domain Knowledge
- The public namespace is lurek.* only and should stay aligned with src/lua_api/register.rs, docs/specs, and generated docs; naming drift across those surfaces is an API defect, not just a doc bug.
- Prefer stable arity, explicit defaults, fixed return shapes, and predictable callback contracts over overloaded string-driven APIs or behavior that changes by hidden convention.
- Test API shape early with content/examples and Lua tests before binding work grows around a weak signature; it is cheaper to change a sketch than a widely copied example.
- Keep Lua-visible type names, callback names, option-table fields, and return values consistent with generated docs and neighboring APIs in the same namespace.
- If an API is niche, game-specific, or mostly composition, check whether it belongs in library/ or example content before adding it to core lurek.*.
- Public API changes imply sync work across docs, examples, tests, dependent libraries, and sometimes changelog or migration guidance.
- Public APIs should fit existing lurek.* language rather than importing patterns wholesale from unrelated engines with different runtime and content assumptions.
- Prefer explicit option tables when the parameter list would otherwise become fragile, but keep table keys stable, well-named, and documented.
- Avoid magic strings and shape-shifting returns when an enum-like value, dedicated function, or consistent tuple is clearer for game authors.
- Breaking or subtle API changes should come with migration notes and visible examples because tests, docs, and library modules are downstream from the shape chosen here.
- This skill owns external API ergonomics, discoverability, and consistency for authors, not binding mechanics, backend runtime tuning, or pure Lua script structure.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/register.rs
- docs/api/lurek.md
- docs/specs/
- content/examples/
