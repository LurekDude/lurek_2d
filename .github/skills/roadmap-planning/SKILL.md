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
- The repo currently has no formal docs/roadmap/ tree, so discovery starts from ideas/, docs, and review notes.
- If roadmap phase files are introduced, they should point to real repo commands and validation gates, not vague outcomes.
- Dependencies should mirror module or rollout order and stay acyclic.
- Acceptance gates must be binary and use the same commands developers already run locally.
- Preserve original intent with status or as-built notes instead of rewriting history when a phase evolves.
- This skill is for planning artifacts and gates, not execution or API design.
- Because formal roadmap phase files do not yet exist, planning work should start from ideas/, docs, and current validation gates rather than fake a mature process.
- If a roadmap artifact is introduced, it should stay concise, binary-gated, and traceable to real repo work and real owners.
- This skill owns future phase and backlog structure, not execution or discovery ranking itself.
## Companion File Index

None - all guidance is inline.

## References
- ideas/
- docs/architecture/
- docs/handbook.md
- work/
