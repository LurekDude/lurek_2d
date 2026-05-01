---
description: "Create one roadmap phase draft with clear problem, gate, and dependency framing."
agent: "Planner"
---
# Create Roadmap Phase

## Goal
- Write one roadmap phase draft that is ready for planning review.

## Inputs
- Target artifact path.
- Problem statement.
- Scope horizon.
- Known dependencies or blockers.

## Steps
1. Load [skill: opportunity-discovery](../skills/opportunity-discovery/SKILL.md) and [skill: roadmap-planning](../skills/roadmap-planning/SKILL.md) before acting.
2. Read the target roadmap or ideas artifact, adjacent phase notes, and any supporting gap or evidence files before editing.
3. Keep the phase grounded in one clear problem, why-now, dependencies, and acceptance gate instead of turning it into a loose brainstorm.
4. Re-read the phase for clarity, dependency ordering, and evidence strength, then flag any missing proof instead of smoothing it over.

## Success Criteria
- [ ] The prompt goal was completed: Write one roadmap phase draft that is ready for planning review.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /create-roadmap-phase path=ideas/phase_lighting.md problem=2d_light_pipeline

## CAG Metadata
Mode: agent
Loads skills: opportunity-discovery, roadmap-planning
Inputs required: Target artifact path., Problem statement., Scope horizon., Known dependencies or blockers.
