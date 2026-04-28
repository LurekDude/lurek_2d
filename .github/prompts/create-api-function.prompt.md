---
description: "Create a new lurek.* API function."
---

# Create Api Function

## Goal
- Step-by-step workflow for adding a new function to the lurek.* Lua API.

## Inputs
- **Module**: Which lurek.* module (graphics, physics, audio, input, etc.)
- **Function name**: Proposed name following lurek.<module>.<verb>() pattern
- **Parameters**: List of parameters with types
- **Return value**: What the function returns to Lua
- **Use case**: Why this function is needed

## Steps
- Load lua-api-design, rust-coding before changing any files.
- Check existing API in src/lua_api/<module>_api.rs for naming consistency
- Verify the function doesn't duplicate existing functionality
- Design the signature following Lua API conventions (see lua-api-design skill)
- Implement the binding in the appropriate *_api.rs file using the register() pattern
- Add the function to docs/api/lurek.md
- Write at least one test exercising the new function
- Run cargo test and cargo clippy
- Consult the actual lurek.* API surface via docs/api/lurek.md, content/examples/, and docs/specs/. Do NOT invent APIs.

## Success Criteria
- [ ] Modified src/lua_api/<module>_api.rs with new binding
- [ ] Updated docs/api/lurek.md
- [ ] New or updated test in tests/
- [ ] Verified: cargo test passes, cargo clippy clean

## Anti-patterns
- Modifying an existing API function (use fix-api-function.prompt.md)
- Designing the overall API surface (use Lua-Designer agent)

## Example Invocation
- /create-api-function <module> <verb>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design, rust-coding
- **Inputs required**: module, verb
