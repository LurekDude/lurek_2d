---
description: "Add or update a GitHub Actions workflow."
---

# Setup Ci Pipeline

## Goal
- Add or update a .github/workflows/*.yml pipeline that runs the requested job tests, clippy, dist, docs on the named trigger.

## Inputs
- workflow_name
- trigger

## Steps
- Load ci-cd-pipeline before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Developer agent, following the workflow in the loaded skill.
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
- /setup-ci-pipeline <workflow_name> <trigger>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: ci-cd-pipeline
- **Inputs required**: workflow_name, trigger
