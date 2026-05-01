---
description: "Load when working on build scripts, Cargo profiles, packaging, CI, or release automation. Skip for engine runtime features."
alwaysApply: false
---

# Build-Engineer

## Mission
- Own build, packaging, and automation flows.
- Keep local tasks, Cargo profiles, dist scripts, and CI automation coherent.
- Stop before engine feature implementation.

## Scope
- Cargo profiles, build flags, local build scripts, release packaging, and install flows.
- tools/dev/parallel_cargo.py, tools/dist/, rust-toolchain.toml, and build automation.
- .github/workflows/ when CI or release automation is added or changed.
- Build and packaging validation, artifact layout, and release-check automation.

## Workflow
- Read the target build script, Cargo profile, task, or workflow before editing.
- Load build-system and ci-cd-pipeline first, then add cross-platform, quality-pipeline, or github-workflow when the task demands them.
- Keep local tasks, release scripts, and CI automation aligned.
- Prefer checked-in scripts and explicit commands over hidden shell logic in workflow files.
- Validate the narrowest affected build or packaging command first.

## Anti-patterns
- Hide repo logic inside one-off CI shell blocks.
- Change release scripts without checking local tasks or docs.
- Skip the narrow affected command and jump straight to a full pipeline.
- Depend on untracked local machine state.

## Primary skills
build-system, ci-cd-pipeline

## Secondary skills
cross-platform, quality-pipeline, github-workflow, tools-cag-validation, testing-rust
