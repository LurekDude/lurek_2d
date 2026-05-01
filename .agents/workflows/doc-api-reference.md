---
description: "Write or update docs for one module, API surface, or contributor workflow topic."
---

# Doc API Reference

## Goal
- Write or update documentation for one module, function group, or contributor workflow.

## Inputs
- Target (module name, API surface, or handbook section).
- Audience (game author or engine contributor).
- Required validation step.

## Steps
1. Load documentation before acting.
2. Determine the source of truth: src/lua_api/*_api.rs docstrings for generated Lua API docs, docs/specs/<module>.md for module contracts.
3. Edit the correct source file. Never hand-edit docs/api/lurek.md or docs/api/lurek.lua directly.
4. After changing Lua API docstrings, run python tools/docs/gen_lua_api_data.py and python tools/docs/gen_luadoc.py to regenerate.
5. Verify the output looks correct and update docs/CHANGELOG.md.

## Success Criteria
- [ ] Source of truth is updated, not generated output directly.
- [ ] Generated files are regenerated and match source.
- [ ] Audience-appropriate voice and concision.

## Example Invocation
- /doc-api-reference target=lurek.timer audience=game-author
