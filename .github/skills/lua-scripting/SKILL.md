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
- Game scripts and tests should use lurek.* only, with locals as state and no accidental globals.
- content/examples/ shows small API slices; content/games/ shows larger patterns; tests/lua/ shows proof-oriented usage.
- Keep init, process, render, and input callback responsibilities separate.
- Multiply movement, timers, tween input, and decay by dt when behavior is time-based.
- Prefer readability for game authors over clever abstraction.
- Generated docs and working examples are the current source for valid Lua usage.
- content/games/, content/examples/, and tests/lua/ each model a different Lua writing style here: playable content, minimal examples, and proof-oriented tests.
- Good scripts keep callback roles obvious, state local, and dt-driven behavior explicit.
- The skill owns author-facing Lua structure and API use, not engine implementation or public API design.
## Companion File Index
- None.

## References
- content/games/
- content/examples/
- tests/lua/
- docs/api/lurek.md
