---
description: "Create a new Lua API function in the lurek.* namespace. Guides through API design, Rust binding implementation, documentation, and testing."
---
# Create Api Function

## Goal

Step-by-step workflow for adding a new function to the `lurek.*` Lua API.

## Inputs

- **Module**: Which `lurek.*` module (graphics, physics, audio, input, etc.)
- **Function name**: Proposed name following `lurek.<module>.<verb>()` pattern
- **Parameters**: List of parameters with types
- **Return value**: What the function returns to Lua
- **Use case**: Why this function is needed

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md), [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Check existing API in `src/lua_api/<module>_api.rs` for naming consistency
3. Verify the function doesn't duplicate existing functionality
4. Design the signature following Lua API conventions (see `lua-api-design` skill)
5. Implement the binding in the appropriate `*_api.rs` file using the `register()` pattern
6. Add the function to `docs/api/lurek.md`
7. Write at least one test exercising the new function
8. Run `cargo test` and `cargo clippy`
9. Consult the actual `lurek.*` API surface via [docs/api/lurek.md](docs/api/lurek.md), [content/examples/](content/examples/), and [docs/specs/](docs/specs/). Do NOT invent APIs.

## Success Criteria

- [ ] Modified `src/lua_api/<module>_api.rs` with new binding
- [ ] Updated `docs/api/lurek.md`
- [ ] New or updated test in `tests/`
- [ ] Verified: `cargo test` passes, `cargo clippy` clean

## Anti-patterns

- Modifying an existing API function (use `fix-api-function.prompt.md`)
- Designing the overall API surface (use `Lua-Designer` agent)

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-api-function <module> <verb>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-api-design, rust-coding
- **Inputs required**: module, verb
