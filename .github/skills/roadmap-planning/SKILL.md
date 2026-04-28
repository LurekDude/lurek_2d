---
name: roadmap-planning
description: "Load this skill when creating or updating roadmap phase docs, gates, dependencies, or consistency checks. Skip it for code work or API design."
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

**Phase file location:** docs/roadmap/phase-{NN}-{slug}.md where NN is 01-99 (two digits, zero-padded).

**Required frontmatter fields:** Priority (P1-P4), Estimated Scope (S/M/L/XL), Depends On (list of phase slugs or "none"), Blocks (list of phase slugs or "none").

**Required sections:** Goal (one paragraph), Current State Analysis (what exists today), Implementation Tasks (numbered list), Acceptance Gates (binary pass/fail checks).

**Dependency graph rules:** must be a DAG (directed acyclic graph). No circular dependencies allowed. If phase A depends on phase B, B must have a lower NN number. Validate by checking that Depends On references only phases with lower NN values.

**Acceptance gate rules:** each gate must be binary (pass or fail). Express as a command that exits 0 on success (e.g., "cargo test passes", "python tools/validate/X.py exits 0"). Never use subjective criteria like "looks good" or "seems fast enough".

**Status tracking for in-progress phases:** add a Status section with current progress percentage and As-Built callouts for any deviations from the original plan. Keep the original Implementation Tasks intact; add strikethrough for dropped items with justification.

## Companion File Index

None - all guidance is inline.

## References

- docs/roadmap/ - all phase files

