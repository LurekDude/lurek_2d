---
description: "Fix a broken lurek.* API function."
---

# Fix Api Function

## Goal
- Fix a broken lurek.* API function.

## Inputs
- **Function**: Which lurek.* function is broken
- **Expected behavior**: What it should do
- **Actual behavior**: What it currently does

## Steps
- Load lua-api-design before changing any files.
- Read the binding in src/lua_api/<module>_api.rs
- Read the underlying engine code
- Identify the discrepancy
- Fix the binding or engine code
- Update docs/api/lurek.md if signature changed
- Verify with test
- Consult the actual lurek.* API surface via docs/api/lurek.md, content/examples/, and docs/specs/. Do NOT invent APIs.

## Success Criteria
- [ ] Function behaves as documented
- [ ] API reference accurate
- [ ] Tests pass

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-api-function <module>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design
- **Inputs required**: module
