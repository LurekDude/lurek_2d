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
- The repo currently has no .github/workflows tree, so CI design should start from the local quality gates that already exist instead of inventing a second process from scratch.
- Quality: Gate, tools/dev/parallel_cargo.py, rust-toolchain.toml, docs generators, and dist scripts are the current source of truth for what a future workflow should execute.
- Mirror local fmt, clippy, test, docs, and packaging steps as directly as possible; the more CI diverges from checked-in scripts, the harder failures are to reproduce locally.
- Keep jobs deterministic, pin tool versions, and prefer checked-in scripts over long inline shell blocks so maintenance stays in repo code rather than YAML trivia.
- Split fast feedback from slow packaging or release work so failures stay attributable and developers do not wait on dist artifacts to discover a simple lint or test failure.
- Release automation must follow tools/dist/ behavior, profile.dist, and generated-doc expectations rather than bypassing them with a CI-only packaging path.
- Start with the smallest reliable matrix that reflects real support needs; desktop targets matter, but unnecessary platform fan-out increases maintenance before value is proven.
- Caching should accelerate stable inputs like Cargo dependencies, not hide mutable generated artifacts whose freshness is part of the correctness contract.
- Artifact naming and upload paths should align with build/ and dist/ structure so local and hosted outputs remain comparable.
- CI workflows in this repo should remain non-interactive, explicit, and readably staged.
## Companion File Index
- None.

## References
- .github/
- Cargo.toml
- rust-toolchain.toml
- tools/dev/parallel_cargo.py
- tools/dist/
