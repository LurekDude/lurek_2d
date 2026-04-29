---
description: "Update one roadmap phase from new evidence without turning it into a fresh brainstorm."
agent: "Discovery-Lead"
---
# Workflow Update Roadmap Phase

## Goal
- Refresh one roadmap phase so it reflects the latest evidence and dependencies.

## Inputs
- Phase path.
- New evidence.
- Reason for update.
- Target decision horizon.

## Steps
1. Load [skill: opportunity-discovery](../skills/opportunity-discovery/SKILL.md) and [skill: roadmap-planning](../skills/roadmap-planning/SKILL.md) before acting.
2. Read the current phase first, then the new evidence, and identify exactly which assumptions or gates changed.
3. Update only the sections affected by the new signal, keeping problem framing, why-now, dependencies, and acceptance gate explicit.
4. Separate confirmed changes from still-speculative ideas instead of smoothing uncertainty away.
5. Close with the updated phase state, the evidence that changed it, and any next planning question still open.

## Success Criteria
- [ ] The workflow outcome is complete: Refresh one roadmap phase so it reflects the latest evidence and dependencies.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /workflow-update-roadmap-phase path=ideas/phase_render.md evidence=latest_perf_audit

## CAG Metadata
Mode: agent
Loads skills: opportunity-discovery, roadmap-planning
Inputs required: Phase path., New evidence., Reason for update., Target decision horizon.
