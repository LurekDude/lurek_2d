---
description: "Author or edit a content/layouts/ TOML UI layout."
mode: agent
loads_skills: [ui-layout]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Lua-Designer
inputs_required: [screen_name]
---

# Author Ui Layout

## Goal

Author or edit a TOML UI layout under `content/layouts/` for a named screen — grid-snapped coordinates, valid widget types, renderable via `tools/ui/render_layout.py`.

## Inputs

- `screen_name` — value supplied by the user invocation.

## Steps

1. Load [skill: ui-layout](.github/skills/ui-layout/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Lua-Designer` agent, following the workflow in the loaded skill.
4. Run `python tools/validate/cag_validate.py` and the quality gates listed in [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring the prompt done.
5. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] All artifacts named in Goal exist on disk.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Skipping the skill-load step listed above.
- Running `git add .` instead of staging only files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/author-ui-layout <screen_name>`
