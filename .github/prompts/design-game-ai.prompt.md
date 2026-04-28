---
description: "Design game AI with lurek.ai."
---

# Design Game Ai

## Goal
- Design and implement an AI behaviour for a named actor using the lurek.ai.* API FSM, behaviour tree, GOAP planner, steering, or utility AI backed by a deterministic Lua test.

## Inputs
- actor_name
- behaviour_kind

## Steps
- Load game-ai before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Developer agent, following the workflow in the loaded skill.
- Run python tools/validate/cag_validate.py and the quality gates listed in quality-pipeline before declaring the prompt done.
- Add a docs/CHANGELOG.md entry under the current version.

## Success Criteria
- [ ] All artifacts named in Goal exist on disk.
- [ ] python tools/validate/cag_validate.py returns no new errors.
- [ ] docs/CHANGELOG.md has a new entry under the current version.

## Anti-patterns
- Skipping the skill-load step listed above.
- Running git add . instead of staging only files this prompt produced.

## Example Invocation
- /design-game-ai <actor_name> <behaviour_kind>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: game-ai
- **Inputs required**: actor_name, behaviour_kind
