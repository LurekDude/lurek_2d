---
name: module-audit
description: "Load this skill when performing end-to-end quality audits on Lurek2D src/ modules: docstrings, AGENT.md sync, test coverage, architecture compliance, wiki pages, API docs, performance, and code quality. Skip it for implementing features, writing game scripts, or pure Lua work."
---
# module-audit

## Mission

# Module Audit Skill

## When To Load

- Performing a quality audit on one or more `src/` modules
- Checking docstring coverage, test coverage, or AGENT.md sync for a module
- Running `python tools/audit/audit_module.py <name>` and interpreting results
- Verifying architecture compliance (tier rules, dependency direction) before merging

## When To Skip

- Skip it for implementing features, writing game scripts, or pure Lua work.

## Domain Knowledge

### Owns
- End-to-end module quality audit workflow for all `src/` modules
- Docstring coverage checks via `python tools/docs/collect_docs.py --report-missing`
- AGENT.md sync verification against source files and Lua API
- Test coverage meta-analysis via `python tools/audit/test_coverage.py`
- Architecture compliance: tier rules, dependency direction, import graph
- Module audit runner: `python tools/audit/audit_module.py <name>` (PASS/WARN/ERROR verdict)
- Wiki page completeness for all audited modules

### Purpose
Perform a structured, reproducible end-to-end quality audit on one or more Lurek2D `src/` modules. Every check produces a discrete PASS / WARNING / ERROR verdict. A module FAILS the audit with **1+ ERROR** or **3+ WARNING**.

### Pre-requisites
Before running any checks, load these reference documents:

1. `docs/architecture/engine-architecture.md` — tier assignments and dependency rules
2. `docs/architecture/philosophy.md` — binding constraints
3. `src/lib.rs` — module registrations
4. `src/lua_api/mod.rs` — Lua API registrations

### Module Resolution
The user specifies targets as module names, group shortcuts, or `all`:

| Input | Resolves to |
|-------|-------------|
| `physics` | `src/physics/` only |
| `physics, audio` | Both modules |
| `foundations` | `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns` |
| `all_groups` | `math`, `log`, `data`, `serial`, `compute`, `dataframe`, `graph`, `procgen`, `patterns`, `runtime`, `event`, `timer`, `thread`, `network`, `filesystem`, `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect`, `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` |
| `core-runtime` | `runtime`, `event`, `timer`, `thread`, `network`, `filesystem` |
| `platform-services` | `render`, `audio`, `physics`, `input`, `image`, `window`, `camera`, `light`, `effect` |
| `feature-systems` | `ecs`, `scene`, `animation`, `tween`, `particle`, `tilemap`, `parallax`, `minimap`, `raycaster`, `ui`, `terminal`, `ai`, `pathfind`, `save`, `mods`, `i18n`, `automation`, `sprite`, `spine` |
| `edge` | `app`, `lua_api`, `devtools`, `debugbridge`, `docs`, `pipeline`, `bin` |
| `lunasome` | Lua libraries in `content/library/` — different audit checks apply |
| `all` | All `src/` modules |

All modules should be assigned to one of the five groups. Check `docs/architecture/engine-architecture.md` for the canonical group assignment.

### AGENT.md Canonical Format (SHORT)
**AGENT.md is a SHORT file.** All architecture, types, Lua API, and examples live in `docs/specs/<module>.md`. See `.github/skills/agent-md/SKILL.md` for the full two-layer authoring rules.

When checking A-02 (template structure), the canonical short AGENT.md format is:

> See [snippets/agent-md-canonical-format-short.md](snippets/agent-md-canonical-format-short.md) for the example.

### Required Sections in AGENT.md (ERROR if missing)
- H1 heading
- Metadata table with `**Tier**` row
- `## Purpose`
- `## Source Files`
- `## Full Specification` with link to `docs/specs/<module>.md`

### What Does NOT Belong in AGENT.md
- `## Summary` (500+ chars) → goes in `docs/specs/<module>.md`
- `## Architecture` / ASCII diagrams → goes in `docs/specs/<module>.md`
- `## Submodules` → goes in `docs/specs/<module>.md`
- `## Key Types` → goes in `docs/specs/<module>.md`
- `## Lua API` table → goes in `docs/specs/<module>.md`
- `## Lua Examples` → goes in `docs/specs/<module>.md`
- `## Item Summary` → goes in `docs/specs/<module>.md`

### Check Procedures

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/agent-md-canonical-format-short.md](snippets/agent-md-canonical-format-short.md) — AGENT.md Canonical Format (SHORT)
- [snippets/s-01-lib-rs-registration.txt](snippets/s-01-lib-rs-registration.txt) — S-01: lib.rs Registration
- [snippets/s-02-mod-rs-simplicity.txt](snippets/s-02-mod-rs-simplicity.txt) — S-02: mod.rs Simplicity
- [snippets/s-03-file-size-limits.txt](snippets/s-03-file-size-limits.txt) — S-03: File Size Limits
- [snippets/d-01-d-05-docstring-checks.txt](snippets/d-01-d-05-docstring-checks.txt) — D-01–D-05: Docstring Checks
- [snippets/t-01-t-07-test-coverage.txt](snippets/t-01-t-07-test-coverage.txt) — T-01–T-07: Test Coverage
- [snippets/r-01-r-05-architecture-compliance.txt](snippets/r-01-r-05-architecture-compliance.txt) — R-01–R-05: Architecture Compliance
- [snippets/q-01-q-06-code-quality.txt](snippets/q-01-q-06-code-quality.txt) — Q-01–Q-06: Code Quality
- [snippets/python-validation-tool.ps1](snippets/python-validation-tool.ps1) — Python Validation Tool
- [snippets/what-every-report-contains-docs-quality.txt](snippets/what-every-report-contains-docs-quality.txt) — What every report contains (`logs/quality/<module>.md`)
- [snippets/step-1-generate-reports.ps1](snippets/step-1-generate-reports.ps1) — Step 1 — Generate reports
- [snippets/step-4-re-run-and-verify.ps1](snippets/step-4-re-run-and-verify.ps1) — Step 4 — Re-run and verify
- [snippets/batch-fix-strategy.ps1](snippets/batch-fix-strategy.ps1) — Batch fix strategy
- [snippets/report-template.txt](snippets/report-template.txt) — Report Template
- [snippets/batch-mode.txt](snippets/batch-mode.txt) — Batch Mode
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
