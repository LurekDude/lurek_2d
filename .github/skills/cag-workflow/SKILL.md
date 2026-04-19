---
name: cag-workflow
description: "Load this skill when working with the Lurek2D CAG (Copilot Agent Customization) layer: building or editing agents, skills, or prompts under .github/; choosing the right CAG artifact type; running cag_validate.py; or designing the AI-first workflow for a new task type. Skip it for general code implementation, game scripting, or roadmap planning."
---
# cag-workflow

## Mission

# CAG Workflow — Lurek2D

## When To Load

- Adding or editing an agent, skill, or prompt
- Deciding whether a new piece of knowledge should be a skill, an agent, a prompt, or AGENT.md
- Running `cag_validate.py` to check schema compliance
- Understanding how agents route work to each other
- Maintaining the system prompt (`copilot-instructions.md`) — e.g., adding new skills to the list

## When To Skip

- Skip it for general code implementation, game scripting, or roadmap planning.

## Domain Knowledge

### Owns
- `.github/` folder taxonomy (agents / skills / prompts)
- CAG artifact type decision rules (AGENT.md vs Skill vs Prompt)
- Skill and agent file format requirements
- `cag_validate.py` validation workflow
- `copilot-instructions.md` maintenance rules
- Agent routing table and load order

### .github/ Layout
> See [snippets/github-layout.txt](snippets/github-layout.txt) for the example.

### CAG Artifact Taxonomy
| Artifact | When to use | Loaded |
|----------|-------------|--------|
| **Module spec** (`docs/specs/<module>.md`) | Module-specific architecture, types, constraints, patterns | By agents reading domain context |
| **Skill** (`.github/skills/`) | Cross-cutting reusable workflow — used across multiple modules | Explicitly with `read_file` before task |
| **Agent** (`.github/agents/`) | Specialist role with a defined mission and restricted scope | Via `runSubagent` or `@AgentName` |
| **Prompt** (`.github/prompts/`) | Task-driven playbook for a specific operation type | Operator selection |

### Decision Rule: Module Spec vs Skill vs Prompt
> See [snippets/decision-rule-module-spec-vs-skill.txt](snippets/decision-rule-module-spec-vs-skill.txt) for the example.

### Skill File Format
> See [snippets/skill-file-format.md](snippets/skill-file-format.md) for the example.

**Rules:**
- First H2 must be `## Load When`
- Description frontmatter must include "Load this skill when", "Use for:", and "Skip it for:" clauses
- Content must be actionable and Lurek2D-specific — no generic advice that is not tied to this codebase
- Update `copilot-instructions.md` skills list whenever a skill is added/removed

### Agent File Format
> See [snippets/agent-file-format.md](snippets/agent-file-format.md) for the example.

### Validation
> See [snippets/validation.ps1](snippets/validation.ps1) for the example.

- Exit 1 = validation failures (schema errors, missing required sections)
- `tools-cag-validation` skill contains full rule details and severity model

### Load Order (Runtime)
1. `copilot-instructions.md` — always loaded, system backbone
2. `docs/specs/<module>.md` — read explicitly when working in that module
3. **Skills** — must be explicitly loaded via `read_file` BEFORE working on task
4. **Prompts** — operator selects a playbook
5. **Agents** — spawned via `runSubagent` for specialist work

`copilot-instructions.md` contains:
- The skills list in the `<skills>` section (describes each skill and its trigger condition)
- The agents routing table
- Critical rules and architecture constraints

**When to update it:**
- Adding/removing a skill → update the `<skill>` entries in the instructions
- Adding a new agent → add a row to the agent routing table
- Adding/changing an architecture constraint → update the corresponding table

**How to update**: Use `replace_string_in_file` to change the specific section — never rewrite the whole file.

### Agent Routing
The `Manager` agent owns the session start and routes work to specialist agents:

| Signal | Agent |
|--------|-------|
| Write Rust code | Developer |
| Design Lua `lurek.*` API | Lua-Designer |
| GPU/rendering work | Renderer |
| Physics work | Physicist |
| Write tests | Tester |
| Write docs | Doc-Writer |
| Diagnose bug | Debugger |

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/github-layout.txt](snippets/github-layout.txt) — .github/ Layout
- [snippets/decision-rule-module-spec-vs-skill.txt](snippets/decision-rule-module-spec-vs-skill.txt) — Decision Rule: Module Spec vs Skill vs Prompt
- [snippets/skill-file-format.md](snippets/skill-file-format.md) — Skill File Format
- [snippets/agent-file-format.md](snippets/agent-file-format.md) — Agent File Format
- [snippets/validation.ps1](snippets/validation.ps1) — Validation
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
