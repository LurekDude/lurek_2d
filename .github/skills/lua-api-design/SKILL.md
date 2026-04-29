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
- Public namespace is lurek.* only and should stay aligned with src/lua_api/register.rs plus docs/specs.
- Prefer stable arity, explicit defaults, and fixed return shapes over overloaded string-driven APIs.
- Test API shape early with content/examples and Lua tests before binding work grows around a bad signature.
- Keep Lua-visible type names and callback names consistent with generated docs.
- If an API is niche, check whether it belongs in library/ or sample content before adding it to core lurek.*.
- Public API changes imply sync work across docs, examples, tests, and dependent libraries.
- Public APIs should fit current lurek.* language, generated docs, and sample content rather than importing patterns from unrelated engines.
- Breaking or subtle API changes should come with migration notes and visible examples because docs and tests are downstream from the shape chosen here.
- The skill owns external API ergonomics, not binding mechanics or pure Lua script architecture.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/register.rs
- docs/api/lurek.md
- docs/specs/
- content/examples/
