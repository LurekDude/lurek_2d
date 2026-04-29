---
description: "Refresh Lua API docstrings at the source and regenerate the derived reference artifacts."
agent: "Doc-Writer"
tools: [tools/docs/gen_lua_api_data.py, tools/docs/gen_luadoc.py]
---
# Workflow Refresh Lua API Docstrings

## Goal
- Bring Lua API docstrings and generated reference outputs back in sync.

## Inputs
- Target module or API slice.
- Doc drift or wording issue.
- Required generation scope.

## Steps
1. Load [skill: documentation](../skills/documentation/SKILL.md) and [skill: lua-api-design](../skills/lua-api-design/SKILL.md) before acting.
2. Read the owning src/lua_api/*_api.rs file, the matching spec, and the current generated output before editing text.
3. Fix the source doc comments only, keeping Lua-facing wording concrete and consistent with the shipped API.
4. Regenerate the Lua API data and generated docs after the source edit, and copy extension-facing artifacts only if that flow is part of the current contract.
5. Close with the regenerated output proof and any remaining wording gap that still needs an API decision rather than a doc fix.

## Success Criteria
- [ ] The workflow outcome is complete: Bring Lua API docstrings and generated reference outputs back in sync.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Edit generated docs/api files directly while leaving stale source docstrings in place.
- Describe planned API behavior as if it already ships.
- Skip regeneration and assume the rendered docs match the edited source.

## Example Invocation
- /workflow-refresh-lua-api-docstrings module=audio

## CAG Metadata
Mode: agent
Loads skills: documentation, lua-api-design
Inputs required: Target module or API slice., Doc drift or wording issue., Required generation scope.
