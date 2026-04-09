---
description: "Run full quality gates: build, clippy, format check, and all tests."
---

# Run Quality Gates

## Purpose

Execute all Lurek2D quality gates in sequence.

## Steps

1. `cargo fmt --check` — formatting compliance
2. `cargo clippy -- -D warnings` — lint with warnings as errors
3. `cargo build` — compilation check
4. `cargo test` — all tests pass
5. Report results for each gate

## Outputs

- Pass/fail for each gate
- Error details for any failures

## Acceptance

- [ ] `cargo fmt --check` passes
- [ ] `cargo clippy` — 0 warnings
- [ ] `cargo build` succeeds
- [ ] `cargo test` — all pass

## References

- System prompt Quality Gates section
