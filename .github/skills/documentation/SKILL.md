---
name: documentation
description: "Load this skill when writing or updating docs, READMEs, tutorials, API reference, or code comments. Skip it for code changes."
---
# documentation

## Mission
- Own doc style, source checks, generated-doc rules, and user-facing clarity.

## When To Load
- Update docs/.
- Update README.md or CONTRIBUTING.md.
- Write tutorials or API docs.
- Add code comments for complex logic.

## When To Skip
- Engine code changes.
- CAG file work.
- API design decisions.

## Domain Knowledge
- docs/api/lurek.md and docs/api/lurek.lua are generated and should never be hand-edited.
- docs/specs/*.md is the contract layer for modules; src/lua_api/*_api.rs docstrings feed the generated Lua API docs.
- The current manual generator flow after Rust Lua API changes is gen_lua_api_data.py then gen_luadoc.py; gen_all_docs.py is the broad pipeline.
- Write for Lua users or engine contributors explicitly; do not mix both audiences in one section.
- Keep examples runnable and align content/examples or library/example.lua with the documented behavior.
- Document only what exists now, not planned features or hoped-for APIs.
- docs/architecture/, docs/handbook.md, CONTRIBUTING.md, and wiki/ each serve different audiences and should not be flattened into one generic doc voice.
- Generated docs belong to tools/docs; manual docs should explain behavior, tradeoffs, and usage patterns the generators cannot express.
- Documentation owns clarity and sync for human readers, not API naming decisions or code changes.
## Companion File Index
- None.

## References
- docs/specs/
- docs/specs/lua-api-file-standard.md
- docs/api/lurek.md
- tools/docs/gen_lua_api_data.py
- tools/docs/gen_luadoc.py
