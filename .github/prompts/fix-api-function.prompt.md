---
description: "Fix a broken or incorrect Lua API function: signature, behavior, or error handling."
---
# Fix Api Function

## Goal

Fix a broken `lurek.*` API function.

## Inputs

- **Function**: Which `lurek.*` function is broken
- **Expected behavior**: What it should do
- **Actual behavior**: What it currently does

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Read the binding in `src/lua_api/<module>_api.rs`
3. Read the underlying engine code
4. Identify the discrepancy
5. Fix the binding or engine code
6. Update `docs/api/lurek.md` if signature changed
7. Verify with test
8. Consult the actual `lurek.*` API surface via [docs/api/lurek.md](docs/api/lurek.md), [content/examples/](content/examples/), and [docs/specs/](docs/specs/). Do NOT invent APIs.

## Success Criteria

- [ ] Function behaves as documented
- [ ] API reference accurate
- [ ] Tests pass

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-api-function <module>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-api-design
- **Inputs required**: module
