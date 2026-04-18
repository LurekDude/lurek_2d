---
description: "Fix a dependency issue in Cargo.toml: version conflict, missing feature, or unnecessary dependency."
mode: agent
loads_skills: [documentation]
loads_tools: []
expected_agent: Developer
inputs_required: []
---

# Fix Dependency Issue

## Goal

Resolve Cargo.toml dependency problems.

## Inputs

- **Issue**: Version conflict, missing features, build failure
- **Affected crate**: Which dependency has the problem

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md) before changing any files.
2. Read `Cargo.toml` for current dependency configuration
3. Check the crate's documentation for correct version and features
4. Fix version pin, feature flags, or remove unnecessary dependency
5. Run `cargo build` and `cargo test`

## Success Criteria

- [ ] `Cargo.toml` uses semver pins (e.g., `"0.27"` not `"*"`)
- [ ] mlua uses `features = ["lua54", "vendored"]`
- [ ] No unnecessary dependencies
- [ ] `cargo build` and `cargo test` pass

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/fix-dependency-issue`
