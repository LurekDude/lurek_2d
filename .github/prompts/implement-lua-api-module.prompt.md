---
description: "Build or rebuild a lurek.* Lua API module."
---
# Implement Lua Api Module

## Goal
- Build or rebuild one lurek.* Lua API module from domain code.

## Inputs
- module_name: target module.

## Steps
- Load lua-api-design, lua-rust-bridge, rust-coding, documentation, and testing-rust.
- Read the domain module and current API docs.
- Design the Lua surface first.
- Keep src/lua_api/<module>_api.rs thin.
- Put business logic in src/<module>/.
- Add docs and tests in the right places.
- Regenerate API docs if public API changed.

## Success Criteria
- [ ] The Lua API module is implemented or refreshed.
- [ ] The wrapper is thin.
- [ ] Tests and docs are updated.
- [ ] Generated API docs are refreshed when needed.

## Anti-patterns
- Put business logic in the wrapper.
- Skip API design.
- Skip tests.
- Use git add .

## Example Invocation
- /implement-lua-api-module module_name

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design, lua-rust-bridge, rust-coding, documentation, testing-rust
- **Inputs required**: module_name
