---
description: "Create a new Lurek2D roadmap phase file with all required metadata, tasks, and acceptance gates."
mode: agent
loads_skills: [roadmap-planning]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Architect
inputs_required: []
---

# Create Roadmap Phase

## Goal

Create a new Lurek2D roadmap phase file with all required metadata, tasks, and acceptance gates. The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `PHASE_TITLE` — descriptive title (e.g., "Gamepad Input Deep Parity")
- `GOAL_DESC` — one paragraph: what changes, why it matters
- `PRIORITY` — Critical | High | Medium | Low
- `DEPENDS_ON` — list of phase numbers this phase requires (or "Nothing")
- `SCOPE_ESTIMATE` — rough file count or "Large — requires discovery"

## Steps

1. Load [skill: roadmap-planning](.github/skills/roadmap-planning/SKILL.md) before changing any files.
2. Assign the next sequential number (e.g., current max is 18 → new phase is 19)
3. Choose a slug: lowercase hyphenated, ≤4 words, describes the feature
4. For each phase listed in `DEPENDS_ON`, open that phase file
5. Verify it exists and its `Blocks:` field either already lists the new phase or needs updating
6. If the new phase is truly independent: `Depends On: Nothing`

## Success Criteria

- [ ] The `Architect` agent has produced the artifacts named in Goal.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.

## Anti-patterns

- The change is a single file fix or a small addition → just make the change
- The phase already exists and needs updating → use `workflow-update-roadmap-phase`

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-roadmap-phase`
