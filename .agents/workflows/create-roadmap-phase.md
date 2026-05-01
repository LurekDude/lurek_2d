---
description: "Create one new roadmap phase file from an accepted problem description and evidence."
---

# Create Roadmap Phase

## Goal
- Produce one well-formed roadmap phase file with a clear problem, acceptance gate, and dependencies.

## Inputs
- Problem description.
- Target module or feature area.
- Known dependencies.
- Evidence and confidence level.

## Steps
1. Load roadmap-planning and documentation before acting.
2. Read existing phase files in work/ or ideas/ for the correct format before writing.
3. Write the phase with: problem statement, why-now, dependencies, deliverables, acceptance gate, and evidence.
4. Keep the phase narrow enough to validate in one slice.
5. Write the phase to work/{session}/ or the correct location and confirm the format matches the repo standard.

## Success Criteria
- [ ] The phase has a clear problem statement, acceptance gate, and dependencies.
- [ ] Evidence strength is marked explicitly.
- [ ] The phase is narrow enough to validate in one slice.

## Anti-patterns
- Bundle too many changes into one phase.
- Write acceptance gates that are not binary.
- Describe planned future behavior as if it already exists.

## Example Invocation
- /create-roadmap-phase goal=tilemap_layer_ordering evidence=ideas/tilemap-gaps.md
