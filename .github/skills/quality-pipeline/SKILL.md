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
- tools/README.md plus the workspace tasks are the real map of quality commands in this repo, so start from checked-in entry points before inventing raw command sequences.
- This codebase separates generators, validators, auditors, and fixers on purpose; choosing the right class of tool is often more important than picking the loudest full-pipeline command.
- Generators run before validators when artifacts are derived from source, and validators run before broad audits when you need the fastest possible root cause.
- After Rust or Lua API changes, docs generation and generated-stub validation come before broader audits because later checks assume fresh derived outputs.
- .github, library/, docs, module, and content changes each have different quality surfaces, so the first question is which artifact moved, not which command looks comprehensive.
- Prefer narrow gates while working: one validator, one target test, or one focused audit usually gives a faster and more actionable failure than the entire quality stack.
- quality_report.py is useful as an aggregator, but targeted validators are better when the goal is to understand the first concrete failure instead of reading a wide summary.
- Use repo wrappers and tasks such as parallel_cargo.py, task definitions, and checked-in scripts to preserve the same expectations developers already rely on locally.
- Run order matters: formatter checks, generated-doc steps, clippy, unit or Lua suites, and packaging checks each answer different questions and should not be shuffled casually.
- When a change touches CAG files, generated docs, or library outputs, include the artifact-specific validators in the loop.
## Companion File Index
- None.

## References
- tools/README.md
- tools/gen_all_docs.py
- tools/audit/quality_report.py
- tools/validate/
