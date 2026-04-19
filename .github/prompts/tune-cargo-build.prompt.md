---
description: "Tune Cargo profiles, feature flags, and build outputs for Lurek2D."
agent: Developer
tools: [tools/validate/cag_validate.py]
---
# Tune Cargo Build

## Goal

Adjust Cargo profiles, feature flags, or the `build/` output directory so a Lurek2D build target meets a stated size or speed objective without regressing `cargo test`.

## Inputs

- `target` — value supplied by the user invocation.
- `objective` — value supplied by the user invocation.

## Steps

1. Load [skill: build-system](.github/skills/build-system/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Developer` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/tune-cargo-build <target> <objective>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: build-system
- **Inputs required**: target, objective
