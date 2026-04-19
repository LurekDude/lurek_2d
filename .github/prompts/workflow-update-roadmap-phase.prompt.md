---
description: "Update the status, tasks, or acceptance gates of an existing Lurek2D roadmap phase file."
agent: Architect
---
# Workflow Update Roadmap Phase

## Goal

Update the status, tasks, or acceptance gates of an existing Lurek2D roadmap phase file. The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `STATUS_UPDATE` — per-task status: which tasks are done, in-progress, or blocked
- `SCOPE_CHANGE` — new files added / removed from task list (if any)
- `NEW_DEPS` — any new `Depends On` or `Blocks` that emerged

## Steps

1. Load [skill: roadmap-planning](.github/skills/roadmap-planning/SKILL.md) before changing any files.
2. Read this prompt's Inputs and confirm every required argument is present.
3. Load any skill listed in `loads_skills` of this prompt's frontmatter.
4. Execute the work as the `Architect` agent.
5. Run the relevant quality gates from the [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring done.

## Success Criteria

- [ ] Updated phase file with `## Status` section reflecting current reality
- [ ] Updated dependency files (if `Blocks:` lines changed)
- [ ] Optional `## Retrospective` section for completed phases

## Anti-patterns

- Creating a new phase from scratch → use `create-roadmap-phase`
- Making code changes that fulfil a phase → route to the appropriate specialist agent

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/workflow-update-roadmap-phase`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: roadmap-planning
