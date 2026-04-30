---
name: lua-scripting
description: "Load this skill when writing or reviewing Lua game scripts and lurek.* usage. Skip it for engine Rust or API design."
---
# lua-scripting

## Mission
- Own Lua game-script structure, lurek.* usage, and script-level clarity.

## When To Load
- Write a Lua game script.
- Review lurek.* usage in content or tests.
- Build a script example or demo.
- Check Lua-side structure and callback flow.

## When To Skip
- Engine Rust code.
- Public API design.

## Domain Knowledge
- Game scripts and tests should use lurek.* only, keep state in locals or explicit tables, and avoid accidental globals that leak behavior across callbacks.
- content/examples/ shows small API slices, content/games/ shows larger playable patterns, and tests/lua/ shows proof-oriented usage; choose the style that matches the artifact you are writing.
- Keep init, process, render, input, and teardown responsibilities separate so callback flow stays readable and debugging does not depend on hidden ordering assumptions.
- Multiply movement, timers, tween input, and other time-based behavior by dt when the mechanic is frame-rate sensitive.
- Prefer readability for game authors over clever abstraction; a straightforward state table and clear callback flow usually beats a heavily abstracted script.
- Generated docs and working examples are the current source for valid Lua usage, but good scripts should still make their assumptions explicit instead of relying on implied engine behavior.
- Use small helper modules or library/ packages for reusable behavior rather than letting one large main.lua accumulate unrelated systems.
- Keep asset paths, configuration tables, and callback wiring explicit and relative to the game content root so scripts remain portable.
- content/games/, content/examples/, and tests/lua/ each model a different writing style in this repo: playable content, minimal teaching surface, and proof-oriented assertions.
- Good scripts keep callback roles obvious, state local, dt-driven behavior explicit, and public lurek.* calls easy to grep or review.
- This skill owns author-facing Lua structure, content-side clarity, and lurek.* usage, not engine implementation, bridge mechanics, or public API design.
## Companion File Index
- None.

## References
- content/games/
- content/examples/
- tests/lua/
- docs/api/lurek.md
