---
name: roadmap-planning
description: "Load this skill when shaping roadmap or backlog artifacts, defining acceptance gates, or checking dependency consistency for future work. Skip it for code work or API design."
---
# roadmap-planning

## Mission

Own the phase file format, dependency graph rules, acceptance gate authoring, status tracking, and roadmap consistency checks.

## When To Load

- Creating a new roadmap phase file
- Updating status or acceptance gates on an existing phase
- Auditing the dependency graph for cycles or missing phases
- Writing acceptance gates for a feature or milestone

## When To Skip

- Implementing code -> use rust-coding skill
- Designing APIs -> use lua-api-design skill
- Writing tests -> use testing-rust skill

## Domain Knowledge
- The repo currently has no formal docs/roadmap/ tree, so planning should start from ideas/, docs, architecture notes, and existing review evidence rather than pretending a full phase system already exists.
- If roadmap phase files are introduced, they should point to real repo commands, real validation gates, and concrete artifacts, not vague aspirations or untestable outcomes.
- Dependencies should mirror module, rollout, or migration order and remain acyclic; if a plan needs circular prerequisites, the slices are probably wrong.
- Acceptance gates must be binary and use the same commands developers already run locally, otherwise status becomes subjective and unreviewable.
- Preserve original intent with status notes, superseded steps, or as-built comments instead of rewriting history when a phase evolves; planning documents should show change, not erase it.
- Good roadmap slices here are small enough to ship, validate, and hand off; oversized phases that bundle architecture, docs, tooling, and content into one block quickly lose decision value.
- Every phase or milestone should name the owning area, key dependency, expected validation evidence, and the artifact that proves completion.
- Because formal roadmap files do not yet exist, planning should remain lightweight and traceable to current repo structure, not import heavyweight process vocabulary for its own sake.
- Use implementation-neutral language where possible; roadmap artifacts should define outcomes and gates, not precommit the exact internal design before discovery is complete.
- If a proposed phase changes contributor workflow, cite the docs or quality gates that must move with it.
## Companion File Index

None - all guidance is inline.

## References
- ideas/
- docs/architecture/
- docs/handbook.md
- work/
