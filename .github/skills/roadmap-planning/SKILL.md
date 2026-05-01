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
- Current planning artifacts live in `ideas/` (raw ideas) and `work/` (active session plans). There is no formal roadmap directory yet. Do not create roadmap files that reference non-existent infrastructure or assume a process that is not yet in place.
- A valid roadmap phase has exactly four fields: **Owner** (one agent or team), **Done When** (a binary, runnable test or validator command), **Inputs** (existing artifacts this phase depends on), **Produces** (concrete artifact this phase creates). Phases without Done When are wishlist items, not roadmap entries.
- Dependency direction rule: phase B that requires phase A's output must list A's artifact as an Input. Circular phase dependencies mean the phases are wrong. Consolidate or split until the graph is a DAG.
- Slice size rule: a phase that touches more than 5 files in `src/`, more than 2 spec files, or more than 1 test suite is too large. It will slip or merge badly. Split by artifact class (code, docs, tests) if size is the problem.
- Scope-creep guard: every phase description must include a one-line statement of what is explicitly NOT in scope. This forces the planner to articulate the boundary and prevents adjacent work from silently accreting.
- Quality gate alignment: the Done When criterion for any phase touching `src/` must include `cargo test` and `cargo clippy -- -D warnings`. Done When for any phase touching `docs/` must include `python tools/gen_all_docs.py` with clean diff. Don't invent new acceptance criteria — use what developers already run.
- Ideas-to-phases pipeline: `ideas/` items are triaged to either WONTDO (add a rejection note), INVESTIGATE (goes to Planner or Architect for discovery), or PHASE (ready to add to roadmap). Do not move an idea directly to a phase without a brief investigation note.
- When a phase changes a public API, it must include a sub-step for migration notes in `docs/specs/<module>.md` and an update to `docs/CHANGELOG.md`. These are not optional follow-up tasks — they are part of the phase.
- Roadmap artifacts live in `work/{session}/plan.md` during planning and may be promoted to a docs location only when finalized and reviewed. Do not commit in-progress plans to `docs/`.
## Companion File Index

None - all guidance is inline.

## References
- ideas/
- docs/architecture/
- docs/handbook.md
- work/
