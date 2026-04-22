---
description: "Add a post-processing visual effect (CRT, bloom, distortion, etc)."
---
# Add Visual Effect

## Goal

Implement a named full-screen post-processing effect using the canvas render-to-texture pipeline plus a custom WGSL fragment shader, with one `lurek.*` toggle and a Lua evidence test.

## Inputs

- `effect_name` — value supplied by the user invocation.

## Steps

1. Load [skill: visual-effects](.github/skills/visual-effects/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Renderer` agent, following the workflow in the loaded skill.
4. Consult the actual `lurek.*` API surface via [docs/lua-api.md](docs/lua-api.md), [content/examples/](content/examples/), and [docs/specs/](docs/specs/). Do NOT invent APIs.
5. Run `python tools/validate/cag_validate.py` and the quality gates listed in [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring the prompt done.
6. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] All artifacts named in Goal exist on disk.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Skipping the skill-load step listed above.
- Running `git add .` instead of staging only files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/add-visual-effect <effect_name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: visual-effects
- **Inputs required**: effect_name
