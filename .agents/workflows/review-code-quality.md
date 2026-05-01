---
description: "Review Rust code for quality, ownership, style, and cross-artifact sync compliance."
---

# Review Code Quality

## Goal
- Identify quality issues in a Rust code slice and produce a ranked list with fixes.

## Inputs
- Files or modules to review.
- Review focus (style, ownership, safety, tests, sync).

## Steps
1. Load rust-coding, module-architecture, and quality-pipeline before acting.
2. Read the target files and check against: mod.rs-thin rule, binding layer thinness, no cfg(test) in src/, correct error propagation, and docs/specs sync.
3. Run cargo clippy -- -D warnings and cargo test for the touched slice.
4. Produce a ranked list of issues: critical, warning, and suggestion. Include the file and line for each.
5. Fix critical issues inline. Return warnings and suggestions for owner decision.

## Success Criteria
- [ ] cargo clippy -- -D warnings passes.
- [ ] Critical issues are fixed or escalated.
- [ ] No unrelated drift was introduced.

## Example Invocation
- /review-code-quality files=src/event/
