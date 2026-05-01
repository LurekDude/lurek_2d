---
description: "Load when setting up or maintaining CI/CD, GitHub Actions, test pipelines, or release automation. Skip for local dev work or code changes."
alwaysApply: false
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
- The repo currently has no .github/workflows tree, so CI design should start from local quality gates that already exist.
- quality_gate, tools/dev/parallel_cargo.py, rust-toolchain.toml, docs generators, and dist scripts are the current source of truth for what a future workflow should execute.
- Mirror local fmt, clippy, test, docs, and packaging steps as directly as possible.
- Keep jobs deterministic, pin tool versions, and prefer checked-in scripts over long inline shell blocks.
- Split fast feedback from slow packaging or release work.
- Release automation must follow tools/dist/ behavior and profile.dist.
- Start with the smallest reliable matrix that reflects real support needs.
- Caching should accelerate stable inputs like Cargo dependencies, not hide mutable generated artifacts.
- CI workflows should remain non-interactive, explicit, and readably staged.

## References
- .github/
- Cargo.toml
- rust-toolchain.toml
- tools/dev/parallel_cargo.py
- tools/dist/
