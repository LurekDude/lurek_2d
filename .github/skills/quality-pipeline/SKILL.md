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
- Generators build JSON and docs from source.
- Validators check rules and fail with exit code 1.
- Auditors measure quality and gaps.
- Fixers change files. Use --dry-run first when possible.
- Quick gate is cargo test and cargo clippy -- -D warnings.
- After API changes, run python tools/gen_all_docs.py first.
- Then run validate_generated_lua_stubs.py and doc_coverage.py as needed.
- Use audit_module.py for one module.
- Use quality_report.py for a combined report.
- Use cag_validate.py after .github changes.
- Use validate_library.py after library/ changes.
- Run generators before validators and auditors.

## Companion File Index
- None.

## References
- tools/README.md
- tools/gen_all_docs.py
- tools/audit/quality_report.py
