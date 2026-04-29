---
description: "Fix a build dependency, feature-flag, or packaging dependency problem."
agent: "Build-Engineer"
tools: [tools/dev/parallel_cargo.py, tools/dist/dist.ps1]
---
# Fix Dependency Issue

## Goal
- Resolve one dependency issue in the build or packaging layer.

## Inputs
- Failing dependency path.
- Platform.
- Observed error.
- Expected build or package flow.

## Steps
1. Load [skill: build-system](../skills/build-system/SKILL.md) and [skill: cross-platform](../skills/cross-platform/SKILL.md) before acting.
2. Reproduce the failure from Cargo.toml, build scripts, profile settings, lockfiles, tasks, and any platform-specific packaging script involved in the failure.
3. Correct the dependency declaration, feature selection, or packaging assumption in the build layer instead of hacking around it in product code.
4. Rerun the narrowest failing build or package command first, then confirm the wider flow if the targeted fix passed.

## Success Criteria
- [ ] The failure was reproduced or tightly localized.
- [ ] The owner slice was fixed at the source.
- [ ] The failing check now passes.
- [ ] No unrelated drift was introduced.

## Anti-patterns
- Patch symptoms in a different layer from the one that owns the failure.
- Skip the smallest reproducer and guess at the fix.
- Keep editing after the first change instead of rerunning the failing check.

## Example Invocation
- /fix-dependency-issue platform=windows error=missing_upx

## CAG Metadata
Mode: agent
Loads skills: build-system, cross-platform
Inputs required: Failing dependency path., Platform., Observed error., Expected build or package flow.
