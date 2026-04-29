---
description: "Run or repair the release build and packaging flow for one target artifact."
agent: "Build-Engineer"
tools: [tools/dev/parallel_cargo.py, tools/dist/dist.ps1]
---
# Op Build Release

## Goal
- Produce or repair one release build flow with clear artifact proof.

## Inputs
- Target platform.
- Profile or packaging path.
- Artifact expectation.
- Observed failure or goal.

## Steps
1. Load [skill: build-system](../skills/build-system/SKILL.md), [skill: cross-platform](../skills/cross-platform/SKILL.md), and [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md) before acting.
2. Read the owning build task, Cargo profile, and packaging script before changing anything.
3. Align the local build path, release packaging path, and any install or dist assumptions so the same artifact story is consistent end to end.
4. Run the narrowest failing build or package step first, fix only that layer, then rerun the same step before moving to the broader release gate.
5. Return artifact location, command proof, and any platform-specific caveat instead of implying the release is universally green.

## Success Criteria
- [ ] The workflow outcome is complete: Produce or repair one release build flow with clear artifact proof.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /op-build-release platform=windows profile=dist

## CAG Metadata
Mode: agent
Loads skills: build-system, cross-platform, quality-pipeline
Inputs required: Target platform., Profile or packaging path., Artifact expectation., Observed failure or goal.
