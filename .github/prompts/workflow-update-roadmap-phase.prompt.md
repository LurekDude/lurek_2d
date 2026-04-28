---
description: "Update an existing roadmap phase file."
---

# Workflow Update Roadmap Phase

## Goal
- Update the status, tasks, or acceptance gates of an existing Lurek2D roadmap phase file.

## Inputs
- STATUS_UPDATE per-task status: which tasks are done, in-progress, or blocked
- SCOPE_CHANGE new files added / removed from task list (if any)
- NEW_DEPS any new Depends On or Blocks that emerged

## Steps
- Load roadmap-planning before changing any files.
- Read this prompt's Inputs and confirm every required argument is present.
- Load any skill listed in loads_skills of this prompt's frontmatter.
- Execute the work as the Architect agent.
- Run the relevant quality gates from the quality-pipeline before declaring done.

## Success Criteria
- [ ] Updated phase file with ## Status section reflecting current reality
- [ ] Updated dependency files (if Blocks: lines changed)
- [ ] Optional ## Retrospective section for completed phases

## Anti-patterns
- Creating a new phase from scratch use create-roadmap-phase
- Making code changes that fulfil a phase route to the appropriate specialist agent

## Example Invocation
- /workflow-update-roadmap-phase

## CAG Metadata
- **Mode**: agent
- **Loads skills**: roadmap-planning
