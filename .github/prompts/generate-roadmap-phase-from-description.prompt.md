---
description: "Turn a rough feature description into one roadmap phase draft."
agent: "Planner"
---
# Generate Roadmap Phase From Description

## Goal
- Transform a loose idea into one structured roadmap phase draft.

## Inputs
- Raw description.
- Target artifact path.
- Audience or persona.
- Any constraints.

## Steps
1. Load [skill: opportunity-discovery](../skills/opportunity-discovery/SKILL.md), [skill: roadmap-planning](../skills/roadmap-planning/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Read the supplied description, nearby roadmap or ideas files, and any supporting repo evidence before editing.
3. Extract the real problem, why-now, dependencies, and acceptance gate, then write the smallest useful phase instead of a broad vision document.
4. Re-read the draft for evidence strength and planning clarity, and mark open questions explicitly when the input is underspecified.

## Success Criteria
- [ ] The prompt goal was completed: Transform a loose idea into one structured roadmap phase draft.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /generate-roadmap-phase-from-description path=ideas/phase_editor.md description='scene workflow and editor panels'

## CAG Metadata
Mode: agent
Loads skills: opportunity-discovery, roadmap-planning, documentation
Inputs required: Raw description., Target artifact path., Audience or persona., Any constraints.
