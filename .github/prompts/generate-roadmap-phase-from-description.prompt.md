---
description: Generate a complete Lurek2D roadmap phase file from a natural language description of scope and goals.
agent: Architect
---
# Generate Roadmap Phase From Description

## Goal

Generate a complete Lurek2D roadmap phase file from a natural language description of scope and goals. The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `Noun` — value supplied by the user invocation.
- `StructName` — value supplied by the user invocation.
- `domain` — value supplied by the user invocation.
- `module` — value supplied by the user invocation.
- `name` — value supplied by the user invocation.
- `slug` — value supplied by the user invocation.
- `verb` — value supplied by the user invocation.

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md), [skill: roadmap-planning](.github/skills/roadmap-planning/SKILL.md) before changing any files.
2. **Feature domain** — which Lurek2D module(s) does this touch? (graphics, physics, audio, input, filesystem, math, timer, window, data, image, sound, event, thread, system, or a new module)
3. **Core capability** — one sentence: what can the game developer do after this phase that they cannot do today?
4. **Scope signal** — is this a small addition (1–3 new functions), a medium module extension (new sub-system), or a large new module (brand-new `src/<name>/` + `lua_api/<name>_api.rs`)?
5. **Lua API surface sketch** — list the `lurek.*` function names implied by the description. If none are named, invent canonical names following the `lurek.<module>.<verb><Noun>` pattern.
6. **Rust implementation surface sketch** — list the struct/trait/module names the implementation will likely need.
7. `docs/API/lua-api.md` — what the current generated reference says
8. Assign the next number (zero-padded, e.g. `19`, `20`).
9. Choose a slug: lowercase-hyphenated, max 4 words, describes the feature not the status.
10. Determine dependencies:
11. Does this phase need SlotMap keys? → Depends On Phase 1
12. Does it need OO Lua objects (UserData)? → Depends On Phase 13

## Success Criteria

- [ ] The `Architect` agent has produced the artifacts named in Goal.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/generate-roadmap-phase-from-description <Noun> <StructName> <domain> <module> <name> <slug> <verb>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation, roadmap-planning
- **Inputs required**: Noun, StructName, domain, module, name, slug, verb
