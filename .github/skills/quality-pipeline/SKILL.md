---
name: quality-pipeline
description: "Load this skill when running quality checks, audits, coverage tools, or doc generation. Skip it for writing code, tests, or doc content."
---
# quality-pipeline

## Mission
- Own tool choice, run order, and result reading for quality work.

## When To Load
- Run pre-commit checks.
- Pick the right audit or validator.
- Read tool output.
- Run the full doc pipeline.

## When To Skip
- Writing Rust code.
- Writing tests.
- Writing docs.

## Domain Knowledge
- tools/README.md plus workspace tasks are the real map of quality commands in this repo.
- Generators run before validators when artifacts are derived from source.
- After Rust or Lua API changes, docs generation and generated-stub validation come before broader audits.
- quality_report.py aggregates; targeted validators are better for fast failure diagnosis.
- .github, library/, docs, module, and content changes each have different validators or audits.
- Prefer narrow gates while working and the full pipeline only at the end.
- This repo already separates generators, validators, auditors, and fixers; choosing the right class of tool matters as much as running it.
- For API or docs changes, generator order is critical because later validators assume fresh derived artifacts.
- The skill owns run order and result interpretation, not the code, docs, or tests being corrected.
## Companion File Index
- None.

## References
- tools/README.md
- tools/gen_all_docs.py
- tools/audit/quality_report.py
- tools/validate/
