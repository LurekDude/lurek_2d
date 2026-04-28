---
description: "Add a new CAG agent, skill, or prompt."
---

# Add Cag Artifact

## Goal
- Add a new agent, skill, or prompt under .github/ that conforms to the CAG standards in work/cag-system-overhaul-20260418/reports/standards/ and passes tools/validate/cag_validate.py with no new errors.

## Inputs
- artifact_type
- name

## Steps
- Load cag-workflow before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the CAG-Architect agent, following the workflow in the loaded skill.
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
- /add-cag-artifact <artifact_type> <name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: cag-workflow
- **Inputs required**: artifact_type, name
