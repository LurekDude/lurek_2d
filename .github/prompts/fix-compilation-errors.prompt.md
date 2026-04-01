---
description: "Fix compilation errors, clippy warnings, or formatting issues in Rust source code."
---

# Fix Compilation Errors

## Purpose

Resolve Rust compilation errors, clippy warnings, or formatting failures.

## Inputs

- **Error output**: Compiler or clippy error messages
- **Affected files**: Which files have errors

## Steps

1. Read the full error message (file, line, error code)
2. Read the affected code in context
3. Identify the fix (type mismatch, missing import, lifetime issue, etc.)
4. Apply the fix
5. Run `cargo build`, `cargo clippy`, `cargo fmt --check`
6. Run `cargo test` to verify no regressions

## Acceptance

- [ ] `cargo build` succeeds
- [ ] `cargo clippy` — 0 warnings
- [ ] `cargo fmt --check` passes
- [ ] `cargo test` passes

## References

- `rust-coding` skill
- `error-handling` skill
