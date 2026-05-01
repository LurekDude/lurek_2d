---
description: "Run the broad quality sweep across all check categories: clippy, tests, docs, coverage, and CAG."
---

# Run Quality Sweep

## Goal
- Confirm the repo passes all quality checks across all categories.

## Inputs
- Scope (all or specific modules).
- Whether CAG files were touched.
- Whether Lua API source changed.

## Steps
1. Load quality-pipeline before acting.
2. Run cargo fmt --check. Fix formatting issues.
3. Run cargo clippy -- -D warnings. Fix all errors.
4. Run cargo test for the targeted scope.
5. If Lua API source changed, regenerate docs.
6. Run python tools/audit/doc_coverage.py and python tools/audit/test_coverage.py.
7. Run python tools/audit/example_coverage.py if content was touched.
8. If .agents/ was touched, run python tools/validate/cag_validate.py.
9. Report pass or fail for each gate.

## Success Criteria
- [ ] cargo fmt --check passes.
- [ ] cargo clippy -- -D warnings passes.
- [ ] cargo test passes.
- [ ] Coverage tools show no critical gaps.
- [ ] CAG validator passes if .agents/ was touched.

## Example Invocation
- /run-quality-sweep scope=all
