| Design module structure | Architect |
| Complex multi-agent task | Planner → then Architect/Developer/... |
| CAG layer itself | CAG-Architect |

### Compliance
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

### Anti-Patterns
- **Skills not loaded before use**: Loading a skill AFTER starting the task — always load first
- **Business logic in AGENT.md**: AGENT.md holds architectural facts, not task procedures — procedures belong in skills or prompts
- **Skills that duplicate the system prompt**: If a rule applies universally to all Lurek2D work, it belongs in `copilot-instructions.md`, not a skill
- **Giant skills**: A skill > 200 lines is trying to be two skills — split by concern
- **Stale copilot-instructions.md**: Adding a skill without updating the system prompt skills list — it becomes undiscoverable
- **Unapproved frontmatter keys**: Inventing new frontmatter keys breaks `cag_validate.py` — only use the approved set above
- **Renaming skills without updating system prompt**: The skills list in `copilot-instructions.md` must stay in sync
