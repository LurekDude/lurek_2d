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
- Use docs/specs/<module>.md for one module only.
- Use a skill for cross-cutting knowledge.
- Use an agent for a specialist role with routing.
- Use a prompt for a user-invoked workflow.
- Skill files need frontmatter with name and description.
- Skill files need Mission, When To Load, When To Skip, Domain Knowledge, Companion File Index, and References.
- Do not use fenced code blocks in SKILL.md.
- Agent files need frontmatter plus Mission, Scope, Inputs, Outputs, Workflow, Routing Table, and Anti-patterns.
- Prompt files need frontmatter plus Goal, Inputs, Steps, Success Criteria, Anti-patterns, and Example Invocation.
- Validate with python tools/validate/cag_validate.py.
- Load order is: system prompt, module specs when needed, skills, prompts, then agents.
- When work spans 3 or more agents or 5 or more files, start with Manager.

## Companion File Index
- None.

## References
- .github/copilot-instructions.md
- docs/architecture/cag-system.md
- tools/validate/cag_validate.py
