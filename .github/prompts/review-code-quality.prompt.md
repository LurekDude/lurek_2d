---
description: "Run a full code-quality review."
---

# Review Code Quality

## Goal
- Systematic code review against all Lurek2D quality gates.

## Inputs
- **Files**: Which files to review (or "all changed files")

## Steps
- Load rust-coding before changing any files.
- Run cargo build verify compilation
- Run cargo clippy verify 0 warnings
- Run cargo fmt --check verify formatting
- Run cargo test verify all tests pass
- Check for unsafe blocks without // SAFETY: comments
- Check module dependency direction (no cross-domain imports)
- Check Lua API naming consistency (lurek.* namespace)
- Check visibility (pub(crate) preferred over pub)
- Check error handling (no .unwrap() in production paths)
- Report findings with severity: BLOCKER / WARNING / NOTE

## Success Criteria
- [ ] Quality gate results (pass/fail for each check)
- [ ] Finding list with file paths, severity, and remediation

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-code-quality

## CAG Metadata
- **Mode**: agent
- **Loads skills**: rust-coding
