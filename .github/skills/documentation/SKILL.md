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
- docs/api/lurek.md is generated. Do not hand-edit it.
- docs/specs/lua-api-file-standard.md defines the docstring contract for src/lua_api/*_api.rs.
- Use docs/specs/ for module truth.
- Keep API docs correct to the actual code signature.
- Keep examples runnable.
- Do not duplicate the same facts across many docs.
- Write Lua API docs for Lua users, not Rust users.
- Use Lua-visible type names, not internal wrapper names.
- When the task is docs-only, do not change Rust logic.
- Keep architecture docs in sync with current modules.
- library/ is pure Lua, not Rust source.
- Do not document planned features as if they already exist.

## Companion File Index
- None.

## References
- docs/api/lurek.md
- docs/specs/lua-api-file-standard.md
- docs/architecture/philosophy.md
- README.md
