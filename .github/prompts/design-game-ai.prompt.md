---
description: "Design FSM, BT, GOAP, or Utility AI for game actors via lurek.ai."
mode: agent
loads_skills: [game-ai]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Developer
inputs_required: [actor_name, behaviour_kind]
---

# Design Game Ai

## Goal

Design and implement an AI behaviour for a named actor using the `lurek.ai.*` API — FSM, behaviour tree, GOAP planner, steering, or utility AI — backed by a deterministic Lua test.

## Inputs

- `actor_name` — value supplied by the user invocation.
- `behaviour_kind` — value supplied by the user invocation.

## Steps

1. Load [skill: game-ai](.github/skills/game-ai/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Developer` agent, following the workflow in the loaded skill.
4. Run `python tools/validate/cag_validate.py` and the quality gates listed in [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring the prompt done.
5. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] All artifacts named in Goal exist on disk.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Skipping the skill-load step listed above.
- Running `git add .` instead of staging only files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/design-game-ai <actor_name> <behaviour_kind>`
