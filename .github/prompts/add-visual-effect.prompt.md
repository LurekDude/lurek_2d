---
description: "Add a new visual effect."
---

# Add Visual Effect

## Goal
- Implement a named full-screen post-processing effect using the canvas render-to-texture pipeline plus a custom WGSL fragment shader, with one lurek.* toggle and a Lua evidence test.

## Inputs
- effect_name

## Steps
- Load visual-effects before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Renderer agent, following the workflow in the loaded skill.
- Consult the actual lurek.* API surface via docs/api/lurek.md, content/examples/, and docs/specs/. Do NOT invent APIs.
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
- /add-visual-effect <effect_name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: visual-effects
- **Inputs required**: effect_name
