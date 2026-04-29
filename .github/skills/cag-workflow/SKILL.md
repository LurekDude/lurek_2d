---
name: cag-workflow
description: "Load this skill when editing .github agents, skills, prompts, or the system prompt, or when choosing the right CAG file type. Skip it for engine code, Lua scripts, or roadmap work."
---
# cag-workflow

## Mission
- Own .github file types, format rules, validation flow, and agent routing.

## When To Load
- Add or edit an agent, skill, prompt, or the system prompt.
- Decide if content belongs in a module spec, skill, agent, or prompt.
- Run cag_validate.py.
- Check agent routing.

## When To Skip
- Engine code work.
- Lua game scripting.
- Roadmap planning.

## Domain Knowledge
- In this repo, .github/ is a validated contract layer, not loose prose.
- Front-load trigger keywords in description fields because skill discovery depends on concise matching text.
- Keep one concern per file type: agent for role, skill for knowledge, prompt for workflow, system prompt for discovery index.
- SKILL.md files stay code-block free and short; domain knowledge belongs in bullets, not embedded examples.
- Agent scope must stay distinct and Manager remains the only router between specialists.
- After .github edits, run cag_validate.py and usually cag_link_check.py before closing the task.
- Prompt and skill wording should stay short because descriptions are part of the discovery surface and long text wastes token budget before matching even happens.
- Shared policy should live in one place: system prompt or shared README, not duplicated across every agent, skill, and prompt.
- If a CAG change alters routing, validator behavior, or shared contracts, update the supporting docs in the same pass rather than leaving hidden drift.
## Companion File Index
- None.

## References
- .github/copilot-instructions.md
- .github/agents/README.md
- docs/architecture/cag-system.md
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
