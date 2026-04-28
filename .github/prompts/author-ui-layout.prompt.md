---
description: "Create or edit a TOML UI layout in content/layouts/."
---

# Author Ui Layout

## Goal
- Author or edit a TOML UI layout under content/layouts/ for a named screen grid-snapped coordinates, valid widget types, renderable via tools/ui/render_layout.py.

## Inputs
- screen_name

## Steps
- Load ui-layout before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Lua-Designer agent, following the workflow in the loaded skill.
- Run python tools/validate/cag_validate.py and the quality gates listed in quality-pipeline before declaring the prompt done.
- Add a docs/CHANGELOG.md entry under the current version.

## Success Criteria
- [ ] All artifacts named in Goal exist on disk.
- [ ] python tools/validate/cag_validate.py returns no new errors.
- [ ] docs/CHANGELOG.md has a new entry under the current version.

## Anti-patterns
- Skipping the skill-load step listed above.
- Running git add . instead of staging only files this prompt produced.

## Example Invocation
- /author-ui-layout <screen_name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: ui-layout
- **Inputs required**: screen_name
