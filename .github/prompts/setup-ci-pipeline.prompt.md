---
description: "Set up or update CI automation for the current repo build and test reality."
agent: "Build-Engineer"
---
# Setup CI Pipeline

## Goal
- Create or update one CI pipeline that matches the repo's real local workflows.

## Inputs
- Pipeline goal.
- Platforms.
- Required checks.
- Artifact or release expectation.

## Steps
1. Load [skill: ci-cd-pipeline](../skills/ci-cd-pipeline/SKILL.md), [skill: build-system](../skills/build-system/SKILL.md), and [skill: github-workflow](../skills/github-workflow/SKILL.md) before acting.
2. Read the current tasks, build scripts, test entry points, and any existing workflow files before editing automation.
3. Prefer checked-in scripts and task entry points over long workflow-only shell logic so CI and local behavior stay aligned.
4. Wire only the required checks, caches, and artifacts for the named pipeline goal, and keep platform assumptions explicit.
5. Validate the workflow logic against the local commands it mirrors and document any environment-specific caveat that cannot be encoded cleanly.

## Success Criteria
- [ ] The workflow outcome is complete: Create or update one CI pipeline that matches the repo's real local workflows.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /setup-ci-pipeline goal=pr_checks platforms=windows,linux

## CAG Metadata
Mode: agent
Loads skills: ci-cd-pipeline, build-system, github-workflow
Inputs required: Pipeline goal., Platforms., Required checks., Artifact or release expectation.
