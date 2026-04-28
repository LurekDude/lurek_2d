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
- Keep names short and consistent.
- Prefer clear params and fixed return types.
- Use examples to test API shape early.
- Keep callbacks predictable.
- Match existing lurek.* patterns before adding new ones.

## Companion File Index
- None.

## References
- src/lua_api/
- docs/api/lurek.md
- docs/specs/
