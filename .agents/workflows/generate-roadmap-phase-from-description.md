---
description: "Generate a formal roadmap phase file from a free-text description."
---

# Generate Roadmap Phase From Description

## Goal
- Convert a free-text description into a well-formed roadmap phase file.

## Inputs
- Free-text description of the problem or feature.
- Known constraints or dependencies.
- Target module or area.

## Steps
1. Load roadmap-planning before acting.
2. Extract from the description: problem statement, why-now signal, deliverables, known dependencies, and acceptance gate.
3. Fill missing information with explicit unknowns rather than invented detail.
4. Format the result as a phase file consistent with existing phase files in work/ or ideas/.
5. Mark evidence strength and any open questions explicitly.

## Success Criteria
- [ ] The phase file has a clear problem, acceptance gate, and dependencies.
- [ ] Missing or uncertain elements are marked explicitly.
- [ ] The format matches the repo standard.

## Example Invocation
- /generate-roadmap-phase-from-description text="We need better tilemap layer support for the platformer demo"
