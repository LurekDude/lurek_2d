---
name: workflow-update-roadmap-phase
description: Update the status, tasks, or acceptance gates of an existing Lurek2D roadmap phase file.
---

# Update Roadmap Phase

## Purpose


## Load Skill First

Load `.github/skills/roadmap-planning/SKILL.md` before proceeding.

## Use When

- Implementation of tasks within a phase is partially or fully complete
- Scope needs revision after discovery work
- New upstream dependencies have been identified
- A phase has been superseded or split

## Do Not Use When

- Creating a new phase from scratch → use `create-roadmap-phase`
- Making code changes that fulfil a phase → route to the appropriate specialist agent

## Inputs

- `STATUS_UPDATE` — per-task status: which tasks are done, in-progress, or blocked
- `SCOPE_CHANGE` — new files added / removed from task list (if any)
- `NEW_DEPS` — any new `Depends On` or `Blocks` that emerged

## Steps

### Step 1: Read the Phase File

Open `PHASE_FILE` and read every section. Identify every `### N.X` task.

### Step 2: Add or Update the Status Section

Insert a `## Status` section immediately after the frontmatter block (after the `---` divider, before `## Goal`):

```markdown
## Status

**As of**: YYYY-MM-DD (or milestone/release name)
- Task N.1 — ✅ Complete: brief description of what was done
- Task N.2 — 🔄 In Progress: current blocker or next action
- Task N.3 — ⬜ Not Started
- Task N.4 — ❌ Cancelled: reason
```

Status symbols:
| Symbol | Meaning |
|---|---|
| ✅ | Complete — no further work needed |
| 🔄 | In Progress — actively being worked |
| ⬜ | Not Started — planned but untouched |
| ❌ | Cancelled — won't be done; document reason |

If a `## Status` section already exists, update it in place — do NOT create a second one.

### Step 3: Add As-Built Notes to Current State Analysis

When tasks complete with findings that differ from the original plan, append to `## Current State Analysis`:

```markdown
**As-Built (YYYY-MM-DD)**: Brief description of what was actually implemented vs the original plan. Reference PR or commit if available.
```

Do NOT delete original analysis text — it is the design record.

### Step 4: Revise Scope or Tasks if Needed

- New sub-task discovered mid-implementation → add `### N.X` at the bottom of `## Implementation Tasks`
- Task split into sub-tasks → add sub-items under the original task headline
- Task removed → mark `❌ Cancelled` in Status, leave task body intact
- Never renumber existing task IDs — add new ones only

### Step 5: Update Dependency Fields

If new dependencies emerged:

1. Add them to the `Depends On:` frontmatter line
2. Open each newly-added dependency phase and update its `Blocks:` line to include this phase

### Step 6: Mark Phase Complete (when all gates pass)

When every task is ✅ and all Acceptance Gates pass:

1. Update `## Status` with overall completion note
2. Optionally add a `## Retrospective` section after `## Acceptance Gates`:

```markdown
## Retrospective

- What went well: ...
- What took longer than expected: ...
- What changed from the original plan: ...
- What the next phase should watch for: ...
```

### Step 7: Verify Consistency

Check these three consistency points:

1. If phase is complete, every gate in `## Acceptance Gates` must have a corresponding ✅ in `## Status`
2. `Depends On` phases must all have ✅ or be complete before this phase can be `In Progress`
3. No `Blocks` phase should be `In Progress` if this phase is not complete

## Outputs

- Updated phase file with `## Status` section reflecting current reality
- Updated dependency files (if `Blocks:` lines changed)
- Optional `## Retrospective` section for completed phases

## Acceptance

- [ ] `## Status` section present with per-task symbols
- [ ] No original task descriptions deleted
- [ ] All new tasks follow `### N.X` numbering (N = phase number)
- [ ] Dependency frontmatter fields updated if new deps discovered
- [ ] Phase file reads correctly (no broken Markdown)
