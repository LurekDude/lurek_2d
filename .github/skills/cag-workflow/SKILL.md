---
name: cag-workflow
description: "Load this skill when working with the Lurek2D CAG (Copilot Agent Customization) layer: building or editing agents, skills, or prompts under .github/; choosing the right CAG artifact type; running cag_validate.py; or designing the AI-first workflow for a new task type. Skip it for general code implementation, game scripting, or roadmap planning."
---

# CAG Workflow — Lurek2D

## Load When

- Adding or editing an agent, skill, or prompt
- Deciding whether a new piece of knowledge should be a skill, an agent, a prompt, or AGENT.md
- Running `cag_validate.py` to check schema compliance
- Understanding how agents route work to each other
- Maintaining the system prompt (`copilot-instructions.md`) — e.g., adding new skills to the list

## Owns

- `.github/` folder taxonomy (agents / skills / prompts)
- CAG artifact type decision rules (AGENT.md vs Skill vs Prompt)
- Skill and agent file format requirements
- `cag_validate.py` validation workflow
- `copilot-instructions.md` maintenance rules
- Agent routing table and load order

## .github/ Layout

```
.github/
├── copilot-instructions.md    — system prompt (always-on backbone)
├── agents/                    — specialist agent roles (.agent.md)
│   └── README.md              — index listing every agent with mission summary
├── skills/                    — reusable domain knowledge (.../SKILL.md)
│   └── <name>/SKILL.md
└── prompts/                   — task-driven playbooks (.prompt.md)
```

## CAG Artifact Taxonomy

| Artifact | When to use | Loaded |
|----------|-------------|--------|
| **AGENT.md** (`src/<module>/`) | Module-specific architecture, types, constraints, patterns | By agents reading domain context |
| **Skill** (`.github/skills/`) | Cross-cutting reusable workflow — used across multiple modules | Explicitly with `read_file` before task |
| **Agent** (`.github/agents/`) | Specialist role with a defined mission and restricted scope | Via `runSubagent` or `@AgentName` |
| **Prompt** (`.github/prompts/`) | Task-driven playbook for a specific operation type | Operator selection |

## Decision Rule: AGENT.md vs Skill vs Prompt

```
Is the knowledge MODULE-SPECIFIC (types, patterns, invariants for one src/ module)?
  → AGENT.md in src/<module>/AGENT.md

Is it a REUSABLE WORKFLOW or domain pattern used across multiple files/modules?
  → Skill in .github/skills/<name>/SKILL.md

Is it a COMPLETE TASK PLAYBOOK (series of steps to accomplish a deliverable)?
  → Prompt in .github/prompts/<verb>-<noun>.prompt.md
```

## Skill File Format

```markdown
---
name: my-skill
description: "Load this skill when ... Use for: A, B, C. Skip it for: X, Y."
---

# Skill Title — Lurek2D

## Load When
(first section — one sentence per bullet)

## [Substantive sections]
...
```

**Rules:**
- First H2 must be `## Load When`
- Description frontmatter must include "Load this skill when", "Use for:", and "Skip it for:" clauses
- Content must be actionable and Lurek2D-specific — no generic advice that is not tied to this codebase
- Update `copilot-instructions.md` skills list whenever a skill is added/removed

## Agent File Format

```markdown
---
name: AgentName
description: "**AgentName** — One sentence mission. Scope declaration. What it does NOT do."
tools: [<tool list>]
---

# AgentName — Lurek2D

## MISSION
...

## SCOPE
...
```

## Validation

```powershell
# Validate all .github/ CAG files
python tools/validate/cag_validate.py

# Validate one family
python tools/validate/cag_validate.py --type skill
python tools/validate/cag_validate.py --type agent

# Validate a single file
python tools/validate/cag_validate.py --file .github/skills/my-skill/SKILL.md
```

- Exit 1 = validation failures (schema errors, missing required sections)
- `tools-cag-validation` skill contains full rule details and severity model

## Load Order (Runtime)

1. `copilot-instructions.md` — always loaded, system backbone
2. `src/<module>/AGENT.md` — read explicitly when working in that module
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

## Agent Routing

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
| Optimize performance | Optimizer |
| Design module structure | Architect |
| Complex multi-agent task | Planner → then Architect/Developer/... |
| CAG layer itself | CAG-Architect |

## Compliance

### Frontmatter Keys — Approved Set

Only these frontmatter keys are supported across CAG artifact types:

| Key | Artifact | Purpose |
|-----|----------|---------|
| `name` | skill, agent | Identifier matching the folder/filename |
| `description` | skill, agent, prompt | Human-readable description shown in the skills panel |
| `tools` | agent | Allowed tool list |
| `model` | agent | Preferred model override |
| `argument-hint` | agent | Usage hint for the orchestrator |
| `target` | prompt | Default target file or scope |
| `user-invocable` | prompt | Whether operator can invoke directly |

Never invent new frontmatter keys. Only use keys from this set.

### Prompt Verb Convention

Prompt file names must follow `{verb}-{noun}.prompt.md`. Approved verbs:

`analyze`, `create`, `fix`, `run`, `review`, `design`, `doc`, `workflow`, `op`, `implement`, `generate`, `audit`

### agents/README.md

`agents/README.md` must list **every** agent file with:
- Agent name (matching `name:` frontmatter)
- One-sentence mission summary

When adding or removing an agent, update the README and `copilot-instructions.md` in the same commit.

## Anti-Patterns

- **Skills not loaded before use**: Loading a skill AFTER starting the task — always load first
- **Business logic in AGENT.md**: AGENT.md holds architectural facts, not task procedures — procedures belong in skills or prompts
- **Skills that duplicate the system prompt**: If a rule applies universally to all Lurek2D work, it belongs in `copilot-instructions.md`, not a skill
- **Giant skills**: A skill > 200 lines is trying to be two skills — split by concern
- **Stale copilot-instructions.md**: Adding a skill without updating the system prompt skills list — it becomes undiscoverable
- **Unapproved frontmatter keys**: Inventing new frontmatter keys breaks `cag_validate.py` — only use the approved set above
- **Renaming skills without updating system prompt**: The skills list in `copilot-instructions.md` must stay in sync
