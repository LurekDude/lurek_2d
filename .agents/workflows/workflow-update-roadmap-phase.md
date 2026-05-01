---
description: "Update one existing roadmap phase: status, acceptance gate, or dependencies."
---

# Workflow Update Roadmap Phase

## Goal
- Update one roadmap phase to reflect the current status, completed gates, or changed dependencies.

## Inputs
- Phase file path.
- What changed (status, gate, dependency, evidence).
- Supporting proof or validation result.

## Steps
1. Load roadmap-planning before acting.
2. Read the current phase file and any linked acceptance gate evidence.
3. Update only the sections that changed: status, evidence, gate results, or dependency state.
4. Preserve original intent with notes or as-built comments instead of rewriting history.
5. Confirm the phase file format matches the repo standard.

## Success Criteria
- [ ] Only changed sections were updated.
- [ ] Original intent is preserved where the direction did not change.
- [ ] Supporting proof is attached or referenced.
- [ ] Format matches the repo standard.

## Example Invocation
- /workflow-update-roadmap-phase phase=work/session/phase-tilemap.md status=complete
