---
applyTo: ".github/**"
---

# CAG Layer Instructions

All files in `.github/` are the Copilot Augmentation Guide (CAG) layer. Every edit must maintain structural compliance and be validated with `python tools/cag_validate.py` before committing.

## Core Rules

- **Validate before AND after editing**: run `python tools/cag_validate.py --file <path>` for targeted checks; run `python tools/cag_validate.py` for full validation
- **One system prompt**: `.github/copilot-instructions.md` — never duplicate its content in agent files or skills
- **Frontmatter required on every file**: instructions need `applyTo`, skills need `name` + `description`, prompts need `description`, agents need `name` + `description` + `tools`
- **Agent files are role-shaped, not topic-shaped**: each agent owns a distinct surface; they must not overlap or duplicate the Manager role
- **Never put task workflows in instructions** — instructions are per-file-family rules; workflows go in prompts

## Layer / Boundary Rules

CAG load order: **System Prompt → Instructions → Skills → Prompts → Agents**

| Layer | File location | What it contains |
|---|---|---|
| System prompt | `.github/copilot-instructions.md` | Repo-wide facts, architecture, routing |
| Instructions | `.github/instructions/*.instructions.md` | Per-file-family rules, `applyTo` glob |
| Skills | `.github/skills/{name}/SKILL.md` | Deep domain patterns, on-demand |
| Prompts | `.github/prompts/{verb}-{noun}.prompt.md` | Task playbooks, repeatable workflows |
| Agents | `.github/agents/{name}.agent.md` | Specialist roles, routed by Manager |

## Compliance

- Skill folder name must match `name:` frontmatter exactly
- Agent `name:` frontmatter must match the filename stem (e.g., `developer.agent.md` → `name: Developer`)
- Prompt filenames: `{verb}-{noun}.prompt.md` — verb from: `analyze`, `create`, `fix`, `run`, `review`, `design`, `doc`, `workflow`, `op`
- `agents/README.md` must list every agent with its mission summary

## Avoid

- Editing `.github/` files without running the validator afterwards
- Duplicating system prompt content (architecture facts, dependency versions) in skill or agent files
- Adding frontmatter keys not in the approved set (`applyTo`, `name`, `description`, `tools`, `model`, `argument-hint`, `target`, `user-invocable`)
- Creating agent files that say "does everything" — each agent must have an explicit non-goal
- Deleting or renaming skill folders without updating the system prompt routing table
