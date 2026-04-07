---
description: "Design a new luna.* Lua API surface. Use when adding a new function or module to the luna.* namespace. Produces a finalized API spec ready for Rust implementation."
---

# Design API Surface

**Purpose**: Design a new `luna.*` function or sub-module API before any Rust implementation starts.
**Use When**: You need to add new user-facing Lua functionality and want the API contract nailed down first.
**Do Not Use When**: The implementation is a pure internal Rust change with no new Lua-facing surface.
**Scope**: `.github/` API design only; no `src/` changes.

## Inputs

- `DOMAIN` — which sub-namespace is affected (e.g., `luna.gfx`, `luna.audio`, `luna.input`)
- `USE_CASE` — describe the game developer scenario this API serves (e.g., "draw a sprite with rotation")
- `REFERENCE_EQUIVALENT` — optional reference-engine equivalent for inspiration (never copy the signature verbatim)

## Steps

1. Load skill `lua-api-design/SKILL.md`
2. Identify which existing `luna.*` sub-namespace this belongs to, or whether a new sub-table is needed
3. Design the function signature:
   - Parameter names: lowercase, concise, no type suffixes
   - Return values: prefer primitive types (number, boolean, string) over userdata
   - Defaults: document optional parameters and their default values
4. Check for consistency with existing `luna.*` functions in the same namespace:
   - Color values always `r, g, b [, a]` in `[0.0, 1.0]` range
   - Shapes always `(mode, x, y, ...)` where mode is `"fill"` or `"line"`
   - IDs always numeric (not string handles)
5. Write a Lua usage example showing the intended developer experience
6. Identify the Rust `DrawCommand` variant or `SharedState` field this will need
7. Document any side effects or ordering constraints (e.g., "must be called inside `luna.draw()`")
8. Record the finalized spec in `docs/API/lua_api_reference_generated.md`

## Outputs

- Finalized function signature with parameter types and defaults
- Lua usage example (3–10 lines)
- Description of required Rust changes (what `DrawCommand` variant or state field)
- Updated `docs/API/lua_api_reference_generated.md` entry

## Acceptance

- [ ] Function signature follows `luna.*` namespace conventions (lowercase, no external-engine-prefixed names)
- [ ] Lua usage example is self-contained and readable
- [ ] No parameter naming conflicts with existing functions in the same namespace
- [ ] `docs/API/lua_api_reference_generated.md` updated with new entry
- [ ] Rust implementation requirements described (not implemented yet — that is `Developer`'s job)

## References

**Required Skills**: `lua-api-design`
**Suggested Agents**: `Lua-Designer`
**Related Prompts**: `create-api-function.prompt.md`, `fix-api-function.prompt.md`
**Docs**: `docs/API/lua_api_reference_generated.md`
