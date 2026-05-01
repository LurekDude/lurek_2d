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
- Quality gate order: (1) `python tools/dev/parallel_cargo.py fmt check` — formatting, (2) `python tools/dev/parallel_cargo.py clippy --deny-warnings` — zero-warning lint, (3) `python tools/dev/parallel_cargo.py test rust` — Rust tests, (4) `python tools/dev/parallel_cargo.py test lua` — Lua harness, (5) `python tools/gen_all_docs.py` — docs freshness. Running them out of order wastes time — fmt and clippy failures are cheap to fix early.
- Use the correct entry point for the change type: Lua API change → `python tools/validate/validate_generated_lua_stubs.py`. Module structure change → `python tools/validate/validate_module_coverage.py`. CAG file change → `python tools/validate/cag_validate.py`. Library change → `python tools/docs/gen_lib_docs.py`. Running the full pipeline for a CAG-only change is unnecessary.
- `python tools/audit/quality_report.py` outputs a module-by-module quality score. Interpret it as a routing signal: modules with score < 70 are candidates for an audit task. Do not treat it as a pass/fail gate — it is a diagnostic.
- Clippy with `-D warnings` is a hard gate. Every warning is a blocker. When Clippy emits a warning for intentional code, add a targeted `#[allow(clippy::...)]` with a `// Reason:` comment directly in the source file — never suppress categories repo-wide in `.vscode/settings.json` or `Cargo.toml`.
- Generated files (`docs/api/lurek.md`, `docs/api/lurek.lua`, `docs/api/library.md`) must be committed in the same PR as the source changes that produced them. CI catches stale generated files by running the generator and diffing. A PR with stale generated docs will fail CI.
- `parallel_cargo.py` handles workspace-level parallelism and output formatting. Prefer it over raw `cargo` commands for test, clippy, and fmt so output format stays stable and CI/local behavior is identical.
- When a quality check fails intermittently in CI but passes locally, the most common causes are: (1) non-deterministic Lua tests due to missing fixed seed, (2) generated docs that differ by line ending (CRLF vs LF), (3) a test that reads wall-clock time.
- `python tools/audit/doc_coverage.py` and `python tools/audit/test_coverage.py` are health indicators, not gates. Run them before major releases or module audits to identify where quality investment is needed.
- Test the full Quality Gate task (`Ctrl+Shift+T`) before any commit that touches multiple files. The task sequence (fmt → clippy → tests) aborts at the first failure, so early failures are found first.
## Companion File Index
- None.

## References
- tools/README.md
- tools/gen_all_docs.py
- tools/audit/quality_report.py
- tools/validate/
