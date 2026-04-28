---
description: "Create a new roadmap phase file."
---

# Create Roadmap Phase

## Goal
- Create a new Lurek2D roadmap phase file with all required metadata, tasks, and acceptance gates.

## Inputs
- PHASE_TITLE descriptive title (e.g., "Gamepad Input Deep Parity")
- GOAL_DESC one paragraph: what changes, why it matters
- PRIORITY Critical | High | Medium | Low
- DEPENDS_ON list of phase numbers this phase requires (or "Nothing")
- SCOPE_ESTIMATE rough file count or "Large requires discovery"

## Steps
- Load roadmap-planning before changing any files.
- Assign the next sequential number (e.g., current max is 18 new phase is 19)
- Choose a slug: lowercase hyphenated, 4 words, describes the feature
- For each phase listed in DEPENDS_ON, open that phase file
- Verify it exists and its Blocks: field either already lists the new phase or needs updating
- If the new phase is truly independent: Depends On: Nothing

## Success Criteria
- [ ] The Architect agent has produced the artifacts named in Goal.
- [ ] python tools/validate/cag_validate.py returns no new errors.

## Anti-patterns
- The change is a single file fix or a small addition just make the change
- The phase already exists and needs updating use workflow-update-roadmap-phase

## Example Invocation
- /create-roadmap-phase

## CAG Metadata
- **Mode**: agent
- **Loads skills**: roadmap-planning
