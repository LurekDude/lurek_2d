---
description: "Run a full feature-development workflow with explicit owners, gates, and sync steps."
---

# Workflow Feature Development

## Goal
- Drive one feature from scoped request to validated completion.

## Inputs
- Feature goal.
- Accepted source of truth.
- Constraints.
- Required final gate.

## Steps
1. Load module-architecture, documentation, testing-rust, and roadmap-planning before acting.
2. Normalize the feature into goal, constraints, out-of-scope items, and the proof needed to call it done.
3. Split the work into the smallest valid owner slices and keep docs, tests, and changelog sync attached to the slices that actually move.
4. Require a focused validation after the first meaningful edit in each slice before allowing more reading or more patching.
5. Close only when the final gate is green and all required sync artifacts for the touched scope are current.

## Success Criteria
- [ ] The feature is complete from scoped request to validated completion.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /workflow-feature-development feature=save_slots source=docs/specs/save.md
