---
description: "Design a new lurek.* Lua API surface. Use when adding a new function or module to the lurek.* namespace. Produces a finalized API spec re..."
---
# Design Api Surface

## Goal

Design a new lurek.* Lua API surface. Use when adding a new function or module to the lurek.* namespace. Produces a finalized API spec re... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `DOMAIN` — which sub-namespace is affected (e.g., `lurek.render`, `lurek.audio`, `lurek.input`)
- `USE_CASE` — describe the game developer scenario this API serves (e.g., "draw a sprite with rotation")
- `REFERENCE_EQUIVALENT` — optional reference-engine equivalent for inspiration (never copy the signature verbatim)

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Load skill `lua-api-design/SKILL.md`
3. Identify which existing `lurek.*` sub-namespace this belongs to, or whether a new sub-table is needed
4. Design the function signature:
5. Parameter names: lowercase, concise, no type suffixes
6. Return values: prefer primitive types (number, boolean, string) over userdata
7. Defaults: document optional parameters and their default values
8. Check for consistency with existing `lurek.*` functions in the same namespace:
9. Color values always `r, g, b [, a]` in `[0.0, 1.0]` range
10. Shapes always `(mode, x, y, ...)` where mode is `"fill"` or `"line"`
11. IDs always numeric (not string handles)
12. Write a Lua usage example showing the intended developer experience

## Success Criteria

- [ ] Finalized function signature with parameter types and defaults
- [ ] Lua usage example (3–10 lines)
- [ ] Description of required Rust changes (what `RenderCommand` variant or state field)
- [ ] Updated `docs/API/lua-api.md` entry

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/design-api-surface`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-api-design
