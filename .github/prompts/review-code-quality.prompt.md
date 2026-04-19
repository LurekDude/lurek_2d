---
description: "Run a full code review against Lurek2D quality gates: compilation, lint, format, tests, conventions."
agent: Reviewer
---
# Review Code Quality

## Goal

Systematic code review against all Lurek2D quality gates.

## Inputs

- **Files**: Which files to review (or "all changed files")

## Steps

1. Load [skill: rust-coding](.github/skills/rust-coding/SKILL.md) before changing any files.
2. Run `cargo build` — verify compilation
3. Run `cargo clippy` — verify 0 warnings
4. Run `cargo fmt --check` — verify formatting
5. Run `cargo test` — verify all tests pass
6. Check for `unsafe` blocks without `// SAFETY:` comments
7. Check module dependency direction (no cross-domain imports)
8. Check Lua API naming consistency (`lurek.*` namespace)
9. Check visibility (`pub(crate)` preferred over `pub`)
10. Check error handling (no `.unwrap()` in production paths)
11. Report findings with severity: BLOCKER / WARNING / NOTE

## Success Criteria

- [ ] Quality gate results (pass/fail for each check)
- [ ] Finding list with file paths, severity, and remediation

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-code-quality`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: rust-coding
