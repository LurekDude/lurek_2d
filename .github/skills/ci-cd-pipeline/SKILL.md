---
name: ci-cd-pipeline
description: "Load this skill when setting up or maintaining CI/CD for Lurek2D: GitHub Actions workflows, build automation, test pipelines, or release processes. Skip it for local development or code implementation."
---

# CI/CD Pipeline — Lurek2D Engine

## Load When

- Creating or updating GitHub Actions workflows
- Setting up automated testing pipeline
- Configuring build automation
- Planning release processes

## Owns

- GitHub Actions workflow configuration
- Build matrix (platforms, Rust versions)
- Automated test execution
- Clippy and format check automation
- Release and artifact publishing

## Does Not Cover

- Local development workflow → use `rust-coding` skill
- Test writing → use `testing-rust` skill
- Code quality → use `rust-coding` skill

## Live Repository Contracts

- `Cargo.toml` — build configuration, dependencies
- `rust-toolchain.toml` — Rust version specification
- `.github/` — CI workflow location (if workflows exist)

## Decision Rules

- **Quality gates in CI**: `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` in every PR
- **Rust version**: Pin to version in `rust-toolchain.toml`
- **Build matrix**: Test on Windows, Linux, macOS when available
- **Cache cargo**: Use `actions/cache` for `~/.cargo` and `target/` directories
- **Fail fast**: Stop pipeline on first failure
- **No secrets in logs**: Never echo keys or tokens in CI output
- **Artifact storage**: Build artifacts attached to release, not committed to repo
- **CAG validation**: Include `python tools/validate/cag_validate.py` in CI pipeline
