---
name: ci-cd-pipeline
description: "Load this skill when setting up or maintaining CI/CD, GitHub Actions, test pipelines, or release automation. Skip it for local dev work or code changes."
---
# ci-cd-pipeline

## Mission
- Own CI workflow design, job scope, and release automation rules.

## When To Load
- Add or update GitHub Actions workflows.
- Change CI quality gates.
- Add release automation.
- Review pipeline structure or caching.

## When To Skip
- Local development workflow.
- Rust or Lua code changes.

## Domain Knowledge
- The repo currently has no .github/workflows tree, so CI work starts from the local gates that already exist.
- Quality: Gate, tools/dev/parallel_cargo.py, rust-toolchain.toml, and dist scripts are the current source of truth.
- Mirror local fmt, clippy, test, doc, and packaging steps instead of inventing a second CI process.
- Keep jobs deterministic, pin tool versions, and prefer checked-in scripts over long inline shell logic.
- Split fast feedback from slow packaging or release work so failures stay attributable.
- Release automation must follow tools/dist/ behavior, not bypass it.
- Since the repo currently lacks a workflow directory, CI design should be derived from the checked-in local quality pipeline instead of a hypothetical hosted setup.
- Dist jobs should respect the same packaging scripts, release profile, and generated-doc expectations used locally.
- This skill owns automation orchestration, not the definition of engineering quality rules themselves.
## Companion File Index
- None.

## References
- .github/
- Cargo.toml
- rust-toolchain.toml
- tools/dev/parallel_cargo.py
- tools/dist/
