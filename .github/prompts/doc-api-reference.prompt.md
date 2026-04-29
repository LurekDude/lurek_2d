---
description: "Refresh API reference content from source docstrings and current contracts."
agent: "Doc-Writer"
tools: [tools/docs/gen_lua_api_data.py, tools/docs/gen_luadoc.py]
---
# Doc API Reference

## Goal
- Bring API reference content back in sync with the source.

## Inputs
- Target module or API slice.
- Doc issue or gap.
- Source of truth.
- Required generation scope.

## Steps
1. Load [skill: documentation](../skills/documentation/SKILL.md) and [skill: lua-api-design](../skills/lua-api-design/SKILL.md) before acting.
2. Read the owning Rust docstrings, docs/specs/, linked examples, and the generator inputs before editing.
3. Fix the source text that drives the generated docs, keep the wording concrete for Lua users, and avoid manual edits to generated artifacts.
4. Run the relevant doc generators and verify the resulting reference matches the intended contract.

## Success Criteria
- [ ] The prompt goal was completed: Bring API reference content back in sync with the source.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Hand-edit generated docs/api files instead of changing their source inputs.
- Document planned behavior as if it already ships.
- Mix contributor notes and user-facing reference text in the same section.

## Example Invocation
- /doc-api-reference module=audio issue=stale_params

## CAG Metadata
Mode: agent
Loads skills: documentation, lua-api-design
Inputs required: Target module or API slice., Doc issue or gap., Source of truth., Required generation scope.
