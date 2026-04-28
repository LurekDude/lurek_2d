---
description: "Triage GitHub issues."
---

# Triage Github Issues

## Goal
- Triage open GitHub issues for the Lurek2D repository apply correct labels, milestones, and routing without modifying issue bodies.

## Inputs
- repo
- label_filter

## Steps
- Load github-workflow before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Manager agent, following the workflow in the loaded skill.
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
- /triage-github-issues <repo> <label_filter>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: github-workflow
- **Inputs required**: repo, label_filter
