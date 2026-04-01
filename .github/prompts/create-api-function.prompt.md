---
description: "Create a new Lua API function in the luna.* namespace. Guides through API design, Rust binding implementation, documentation, and testing."
---

# Create Lua API Function

## Purpose

Step-by-step workflow for adding a new function to the `luna.*` Lua API.

## Use When

- Adding a new function to any `luna.<module>.*` namespace
- Exposing engine functionality to Lua scripts

## Do Not Use When

- Modifying an existing API function (use `fix-api-function.prompt.md`)
- Designing the overall API surface (use `Lua-Designer` agent)

## Inputs

- **Module**: Which `luna.*` module (graphics, physics, audio, input, etc.)
- **Function name**: Proposed name following `luna.<module>.<verb>()` pattern
- **Parameters**: List of parameters with types
- **Return value**: What the function returns to Lua
- **Use case**: Why this function is needed

## Steps

1. Check existing API in `src/lua_api/<module>_api.rs` for naming consistency
2. Verify the function doesn't duplicate existing functionality
3. Design the signature following Lua API conventions (see `lua-api-design` skill)
4. Implement the binding in the appropriate `*_api.rs` file using the `register()` pattern
5. Add the function to `docs/lua_api_reference.md`
6. Write at least one test exercising the new function
7. Run `cargo test` and `cargo clippy`

## Outputs

- Modified `src/lua_api/<module>_api.rs` with new binding
- Updated `docs/lua_api_reference.md`
- New or updated test in `tests/`
- Verified: `cargo test` passes, `cargo clippy` clean

## Acceptance

- [ ] Function follows `luna.<module>.<verb>()` naming
- [ ] Parameters match existing conventions (dt, x, y, key, etc.)
- [ ] Returns `LuaResult<T>`
- [ ] API reference updated
- [ ] At least one test exists
- [ ] `cargo test` passes
- [ ] `cargo clippy` clean

## References

- `lua-api-design` skill
- `rust-coding` skill
- `docs/lua_api_reference.md`
