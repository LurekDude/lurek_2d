---
description: "Load when writing or updating docs, READMEs, tutorials, API reference, or code comments. Skip for code changes."
alwaysApply: false
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
- docs/api/lurek.md and docs/api/lurek.lua are generated outputs and should never be hand-edited; fix Lua API wording at the Rust docstring source and regenerate.
- docs/specs/*.md is the contract layer for modules, while src/lua_api/*_api.rs docstrings feed generated Lua API pages, so documentation changes need the right source-of-truth file before any prose is touched.
- The narrow regeneration path after Rust Lua API changes is gen_lua_api_data.py then gen_luadoc.py; gen_all_docs.py is the broad pipeline when multiple derived docs may have drifted.
- Write for one audience at a time: Lua game authors need usage and behavior, engine contributors need ownership, constraints, and architecture; mixing both in one paragraph usually weakens both.
- docs/architecture/, docs/handbook.md, CONTRIBUTING.md, docs/specs/, and wiki/ serve different reading modes and should keep their own voice, density, and level of abstraction.
- Manual docs should explain behavior, limits, tradeoffs, and workflow, not duplicate generated API tables or mirror code structure line by line.
- Keep examples runnable and aligned with documented behavior; content/examples, library/example.lua, and demo content are evidence that the docs still describe a real path a user can execute.
- Document only what exists now, not planned features, aspirational APIs, or guessed future flags; roadmap material belongs elsewhere.
- When code changes affect user-visible behavior, cross-artifact sync matters: specs, handbook notes, examples, and changelog entries should move with the same logical change.
- Concision matters more than exhaustive prose in this repo; readers need the shortest explanation that prevents wrong usage.

## References
- docs/specs/
- docs/specs/lua-api-file-standard.md
- docs/api/lurek.md
- tools/docs/gen_lua_api_data.py
- tools/docs/gen_luadoc.py
