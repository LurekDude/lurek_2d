---
description: "Tune Cargo profiles and build output."
---

# Tune Cargo Build

## Goal
- Adjust Cargo profiles, feature flags, or the build/ output directory so a Lurek2D build target meets a stated size or speed objective without regressing cargo test.

## Inputs
- target
- objective

## Steps
- Load build-system before changing any files.
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
- /tune-cargo-build <target> <objective>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: build-system
- **Inputs required**: target, objective
