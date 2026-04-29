---
description: "Run the release readiness checklist for the current build, docs, and CAG state."
agent: "Build-Engineer"
tools: [tools/dev/parallel_cargo.py, tools/validate/cag_validate.py, tools/dist/dist.ps1]
---
# Workflow Release Check

## Goal
- Return a clear release-readiness result for one target build.

## Inputs
- Release target.
- Required artifact.
- Expected gates.
- Any changed areas.

## Steps
1. Load [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md), [skill: build-system](../skills/build-system/SKILL.md), [skill: tools-cag-validation](../skills/tools-cag-validation/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read the target build or dist path, current tasks, and any release docs before running gates.
3. Run the required build, test, and validation commands in a stable order so the first real blocker stays obvious.
4. Include CAG validation when .github changed and keep generated-doc or packaging checks explicit when the release path depends on them.
5. Close with release status, blocking gates, artifact notes, and any remaining manual step.

## Success Criteria
- [ ] The workflow outcome is complete: Return a clear release-readiness result for one target build.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /workflow-release-check target=windows_release

## CAG Metadata
Mode: agent
Loads skills: quality-pipeline, build-system, tools-cag-validation, testing-rust
Inputs required: Release target., Required artifact., Expected gates., Any changed areas.
