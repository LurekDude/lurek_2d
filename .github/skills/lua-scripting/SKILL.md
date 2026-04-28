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
- Use lurek.* only for engine-facing APIs.
- Keep game state in locals, not accidental globals.
- Multiply movement and time-based updates by dt.
- Keep rendering in render callbacks and logic in process callbacks.
- Keep scripts readable enough for game authors first.
- Use docs/api/lurek.md and content examples as the source of current script patterns.

## Companion File Index
- None.

## References
- content/games/
- content/examples/
- docs/api/lurek.md