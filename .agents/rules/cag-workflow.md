---
description: "Load when editing .agents rules and workflows, or when choosing the right agent file type. Skip for engine code, Lua scripts, or roadmap work."
alwaysApply: false
---

# cag-workflow

## Mission
- Own .agents/ file types, format rules, and agent routing.

## When To Load
- Add or edit a rule, skill, or workflow.
- Decide if content belongs in a rule, conditional skill, or workflow.
- Check agent routing.

## When To Skip
- Engine code work.
- Lua game scripting.
- Roadmap planning.

## Domain Knowledge
- .agents/ is a validated contract layer, not loose prose, so every edit should preserve discoverability, routing, and validator compatibility.
- Front-load concrete trigger words in description fields because discovery depends on short matching text.
- Keep one concern per file type: always-on rules for global constraints, conditional skills for domain knowledge, workflows for slash-command procedures.
- Choose the smallest valid primitive first; if the behavior is always-on it belongs in a rule with alwaysApply: true, if it is task-scoped it belongs in a conditional skill or workflow.
- Rule files should stay code-block free and easy to scan; the value is concentrated bullets.
- Distinct scope matters more than coverage count: overlapping skills dilute discovery.
- Shared policy should live once in systems.md, not be restated across many files.

## References
- .agents/rules/systems.md
- docs/architecture/cag-system.md
