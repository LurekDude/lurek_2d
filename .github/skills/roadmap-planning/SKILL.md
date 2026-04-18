---
name: roadmap-planning
description: "Load this skill when creating or maintaining roadmap phase documentation, updating phase files, or auditing roadmap consistency. Owns phase file format, dependency graph rules, acceptance gate authoring, and roadmap consistency. Skip it for code implementation or API design."
companion_files:
  examples: []
  templates: []
  snippets: []
related_skills: []
---

# roadmap-planning

## Mission

# Roadmap Planning — Lurek2D Engine

## When To Load

- Updating an existing phase (status, scope, tasks, acceptance gates)
- Adding a phase dependency (`Depends On` / `Blocks`)
- Auditing roadmap for completeness, gaps, or stale phases
- Renumbering phases after insertion

## When To Skip

- Code implementation that fulfils a phase → route to `Developer`, `Renderer`, `Physicist`, `Audio-Eng`
- API surface design within a phase → use `lua-api-design` skill
- Architecture decisions like module boundaries → use `module-architecture` skill
- CAG file authoring (skills, agents, prompts) → use `tools-cag-validation` skill

## Domain Knowledge

### Owns
- Phase numbering convention and dependency graph
- Acceptance gate format and measurability standard
- Phase frontmatter metadata (Priority, Scope, Depends On, Blocks)
- Current-state analysis section structure

### Live Repository Contracts
- `docs/architecture/engine-architecture.md` — source of truth for module names, dependency direction, and platform targets
- `.github/copilot-instructions.md` — defines tech baseline; roadmap phases must not contradict it
- `Cargo.toml` — dependency versions referenced in phases must match actual Cargo entries

### Phase File Format
> See example_1.md for the phase file format code example.

### File Naming
> See example_2.txt for the file naming code example.

- `NN` is zero-padded to two digits: `01`–`09`, then `10`, `11`, …
- `slug` is lowercase-hyphenated, max 4 words, describes the feature not the status
- Examples: `phase-02-graphics-deep-parity.md`, `phase-16-luajit.md`, `phase-18-mobile-web.md`

### Priority Values
| Value | Meaning |
|---|---|
| `Critical` | Blocks all or most subsequent phases; fix before anything else |
| `High` | Needed for core gameplay or developer experience |
| `Medium` | Fills capability gaps; important but not unblocking |
| `Low` | Nice-to-have; stretch goal for a release |

### Dependency Graph Rules
- `Depends On: Nothing` is valid for foundation phases (like Phase 1)
- Circular dependencies are forbidden — verify the graph is a DAG
- If phase A `Blocks` phase B, then phase B must list A in `Depends On`
- New phases that depend on core (Phase 1) must say so explicitly
- Parallel workstreams (no shared files, no shared code) → `Blocks: Nothing`

### Acceptance Gate Rules
- Every gate must be a **binary test** — pass or fail, no "mostly works"
- At least one gate must be a `cargo test` or `cargo build` command
- Feature phases touching `lurek.*` API must include a Lua test gate
- Documentation phases must name the specific file updated
- Never use vague gates like "the feature works" or "code quality is good"

### Scope Estimation Convention
- "~N files modified" — count only non-trivial edits (not just a `use` line)
- "~N files added" — count new source files only (not test files)
- If scope is genuinely unknown: write `Large — requires discovery`
- Scope is an estimate for planning, not a contract

### Updating Existing Phases
When updating a phase that has been partially or fully implemented:

1. Add a `## Status` section immediately after the frontmatter block (before `## Goal`):
   > See example_3.md for the updating existing phases code example.
2. Do NOT delete original task descriptions — they are the design record
3. Update `Depends On` / `Blocks` if new dependencies emerge
4. Add retrospective notes to `## Current State Analysis` as "**As-Built**:" callouts

### Common Mistakes to Avoid
- Using `Depends On: Phase 0` — there is no Phase 0; use `Nothing` for foundation phases
- Writing acceptance gates that depend on human judgement ("looks good", "feels right")
- Numbering sub-tasks from `1.1` instead of `N.1` (N must match the phase number)
- Omitting the `---` horizontal rule separators between sections
- Referencing crate versions that don't match `Cargo.toml`
- Writing tasks without an **Agent** assignment for multi-agent phases

## Companion File Index

- (no companion files extracted)

## References

- See related skills in `.github/skills/`.
