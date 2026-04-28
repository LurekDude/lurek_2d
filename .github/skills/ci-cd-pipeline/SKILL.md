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
- Keep CI gates aligned with the repo quality gates.
- Prefer deterministic jobs and explicit tool versions.
- Keep workflow scope narrow and readable.
- Cache only what is safe and worth the complexity.
- Separate fast feedback jobs from slower release or package jobs.
- Keep workflow logic in CI files, not hidden in undocumented local assumptions.

## Companion File Index
- None.

## References
- .github/workflows/
- Cargo.toml
- rust-toolchain.toml