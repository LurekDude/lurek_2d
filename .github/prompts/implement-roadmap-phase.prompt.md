---
description: "Execute one accepted roadmap phase through the smallest valid owner set."
agent: "Manager"
---
# Implement Roadmap Phase

## Goal
- Take one accepted roadmap phase from definition to validated completion.

## Inputs
- Accepted phase artifact.
- Constraints.
- Target gate.
- Known blockers.

## Steps
1. Load [skill: roadmap-planning](../skills/roadmap-planning/SKILL.md), [skill: module-architecture](../skills/module-architecture/SKILL.md), [skill: documentation](../skills/documentation/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read the accepted phase artifact first and restate the goal, boundaries, dependencies, and binary finish gate before routing work.
3. Split the phase into the smallest valid owner slices and route only when the current gate and proof are clear.
4. Keep docs, tests, and changelog sync tied to the slices that actually changed instead of treating them as one late catch-all step.
5. Close the phase only after the owning validations passed and the phase artifact reflects the current state.

## Success Criteria
- [ ] The workflow outcome is complete: Take one accepted roadmap phase from definition to validated completion.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /implement-roadmap-phase path=ideas/phase_audio_mixdown.md

## CAG Metadata
Mode: agent
Loads skills: roadmap-planning, module-architecture, documentation, testing-rust
Inputs required: Accepted phase artifact., Constraints., Target gate., Known blockers.
