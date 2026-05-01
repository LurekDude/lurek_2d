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
- All public functions live under `lurek.*` exactly — no bare globals, no `engine.*`, no alternative top-level tables. This is binding constraint C-01; any new namespace proposal goes through Lua-Designer, not Developer.
- Test the API shape with a short Lua snippet in `content/examples/` before writing binding code. A design flaw in a 10-line sketch costs nothing; the same flaw in a bound+tested+documented API costs a breaking change.
- Arity rule: prefer fixed-arity functions or option tables. Avoid optional positional arguments beyond 2 — they break autocomplete and make `lurek.*` calls hard to read six months later. `lurek.sprite.draw(sprite, x, y, opts)` is acceptable; `lurek.sprite.draw(sprite, x, y, rot, sx, sy, ox, oy)` is not.
- Return shape must be stable and documented. Functions that return `nil` on failure should say so explicitly in the docstring. Never return `nil` and `error` depending on context for the same function — choose one pattern per function.
- Callback contracts must state: when it fires (frame phase), what arguments it receives (types and units), what happens if it raises an error (caught/logged or propagated), and whether it fires once or repeatedly.
- Check `src/lua_api/register.rs` and `docs/api/lurek.md` for existing naming patterns before proposing a name. `lurek.audio.play` vs `lurek.audio.start` vs `lurek.audio.source.play` — pick the one that matches the nearest neighbor.
- Run `python tools/validate/validate_lua_api.py` on any new or changed binding to verify docstring shape, argument naming, and type annotation completeness. This feeds generated docs.
- Migration notes are mandatory for: changed argument order, renamed params, removed functions, changed return type, changed callback signature. Migration notes go in `docs/specs/<module>.md` under a Changelog or Migration section.
- If a proposed function is only useful for one game genre, check `library/` first. Core `lurek.*` is for universal game behaviors; domain logic belongs in library modules.
- Enums should be represented as Lua strings with a small closed set, documented in the docstring. Magic strings with an open set are a design smell; if the set is open, use a type alias or documentation that says so explicitly.
- `docs/api/lurek.lua` and `docs/api/lurek.md` are generated — never hand-edit them. Always fix docstring issues in `src/lua_api/<module>_api.rs`, then regenerate with `python tools/gen_all_docs.py`.
## Companion File Index
- None.

## References
- src/lua_api/
- src/lua_api/register.rs
- docs/api/lurek.md
- docs/specs/
- content/examples/
