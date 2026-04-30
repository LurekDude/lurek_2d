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
- In this repo, .github/ is a validated contract layer, not loose prose, so every edit should preserve discoverability, routing, and validator compatibility at the same time.
- Front-load concrete trigger words in description fields because discovery depends on short matching text, and vague prose near the end of a description is effectively invisible to the loader.
- Keep one concern per file type: agent for role and delegation, skill for reusable domain knowledge, prompt for a focused workflow, and the system prompt for global discovery rules.
- Choose the smallest valid primitive first; if the behavior is always-on it belongs in instructions, if it is task-scoped it belongs in a skill or prompt, and if it needs context isolation it belongs in an agent.
- SKILL.md files should stay code-block free, example-light, and easy to scan; the value is concentrated bullets that change search and execution behavior, not long tutorial text.
- Distinct scope matters more than coverage count: overlapping skills dilute discovery, create conflicting advice, and make it harder for the router to pick the right file with confidence.
- Manager remains the only router between specialists, so agent files should describe clear ownership boundaries instead of partial overlap or fallback-to-everything behavior.
- Shared policy should live once in .github/copilot-instructions.md or the relevant architecture doc, not be restated with different wording across skills, prompts, and agents.
- Companion File Index should name only files that materially improve execution of that skill; dumping broad reading lists there weakens the signal and wastes context.
## Companion File Index
- None.

## References
- .github/copilot-instructions.md
- .github/agents/README.md
- docs/architecture/cag-system.md
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
