---
description: "Fix Rust compile, clippy, or format issues."
---

# Fix Compilation Errors

## Goal
- Resolve Rust compilation errors, clippy warnings, or formatting failures.

## Inputs
- **Error output**: Compiler or clippy error messages
- **Affected files**: Which files have errors

## Steps
- Load error-handling, rust-coding before changing any files.
- Read the full error message (file, line, error code)
- Read the affected code in context
- Identify the fix (type mismatch, missing import, lifetime issue, etc.)
- Apply the fix
- Run cargo build, cargo clippy, cargo fmt --check
- Run cargo test to verify no regressions

## Success Criteria
- [ ] cargo build succeeds
- [ ] cargo clippy 0 warnings
- [ ] cargo fmt --check passes
- [ ] cargo test passes

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /fix-compilation-errors

## CAG Metadata
- **Mode**: agent
- **Loads skills**: error-handling, rust-coding
