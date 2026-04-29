---
description: "Short user-facing task description with concrete trigger words."
agent: Agent-Name
---
# Prompt Title

## Goal
- One clear outcome for this prompt.

## Inputs
- Required input one.
- Required input two.

## Steps
1. Load [skill: primary-skill](../../.github/skills/primary-skill/SKILL.md) and any other listed skills before acting.
2. Read the owning files, source of truth, and nearest validation surface.
3. Perform only the bounded work named by this prompt.
4. Run the narrowest relevant validation, then report proof and remaining risk.

## Success Criteria
- [ ] The bounded outcome is complete.
- [ ] Required sync artifacts are updated.
- [ ] Validation proof is attached.

## Anti-patterns
- Widen scope beyond the prompt.
- Skip the first narrow validation.
- Edit generated artifacts by hand when the source should change instead.

## Example Invocation
- /prompt-name key=value

## CAG Metadata
Mode: agent
Loads skills: primary-skill
Inputs required: input one, input two
