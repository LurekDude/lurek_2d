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
- There is currently no GitHub Actions workflows directory in this repo. Any CI setup work must create it from scratch. Mirror existing local quality gates from `tools/dev/parallel_cargo.py` and `.vscode/tasks.json` — CI commands must match local developer experience exactly.
- Required CI stages in this order: (1) `fmt check`, (2) `clippy --deny-warnings`, (3) `cargo test --all-targets` for Rust tests, (4) Lua harness test (`python tools/dev/parallel_cargo.py test lua`), (5) docs validation (`python tools/validate/validate_generated_lua_stubs.py`). Only after all 5 pass should an artifact build be attempted.
- Platform matrix minimum: Windows x86_64 (mandatory), Linux x86_64 (mandatory). macOS ARM is a stretch goal. No mobile, no WASM. Over-expanding the matrix increases maintenance without proportional value.
- LuaJIT CI note: LuaJIT requires a C compiler and a specific build step that can fail on some CI runners. The `lua54` fallback feature exists exactly for this reason. If a runner cannot build LuaJIT, run with `--no-default-features --features lua54` for that job and label the job clearly.
- Pin all tool versions: Rust toolchain via `rust-toolchain.toml` (already in repo), Python version explicitly in CI config, UPX version for dist jobs. Never use `latest` for build tools.
- Cargo dependency caching: cache `~/.cargo/registry`, `~/.cargo/git`, and `target/` by hashing `Cargo.lock`. Invalidate on any `Cargo.lock` change. Do not cache `build/` or `dist/` — these are derived outputs.
- Artifact naming convention: `lurek2d-{os}-{arch}-{git-sha-short}.zip`. Artifacts produced during CI must match the layout that `tools/dist/dist.ps1` produces, so local and CI packaging outputs are structurally identical.
- Release triggers: tag matching `v*.*.*` on the `main` branch. Pre-release triggers: tag matching `v*.*.*-rc.*`. Never trigger a release from a non-main branch automatically.
- Docs generation in CI: run `python tools/gen_all_docs.py` and fail the job if generated files differ from committed files. This enforces that contributors do not commit stale generated docs.
- CI YAML should remain readably staged — each logical step is a named step in the YAML, not a long inline shell block. Prefer checked-in scripts over inline YAML logic.
## Companion File Index
- None.

## References
- .github/
- Cargo.toml
- rust-toolchain.toml
- tools/dev/parallel_cargo.py
- tools/dist/
