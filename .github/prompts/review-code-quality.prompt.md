---
description: "Run a full code review against Lurek2D quality gates: compilation, lint, format, tests, conventions."
---

# Review Code Quality

## Purpose

Systematic code review against all Lurek2D quality gates.

## Inputs

- **Files**: Which files to review (or "all changed files")

## Steps

1. Run `cargo build` — verify compilation
2. Run `cargo clippy` — verify 0 warnings
3. Run `cargo fmt --check` — verify formatting
4. Run `cargo test` — verify all tests pass
5. Check for `unsafe` blocks without `// SAFETY:` comments
6. Check module dependency direction (no cross-domain imports)
7. Check Lua API naming consistency (`lurek.*` namespace)
8. Check visibility (`pub(crate)` preferred over `pub`)
9. Check error handling (no `.unwrap()` in production paths)
10. Report findings with severity: BLOCKER / WARNING / NOTE

## Outputs

- Quality gate results (pass/fail for each check)
- Finding list with file paths, severity, and remediation

## Acceptance

- [ ] All quality gates checked
- [ ] Findings include specific file paths
- [ ] Severity assigned to each finding
- [ ] Remediation actionable

## References

- `Reviewer` agent
- `rust-coding` skill
