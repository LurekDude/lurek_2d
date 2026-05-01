---
description: "Run all quality gates before a commit or release: clippy, tests, doc gen, and coverage."
---

# Run Quality Gates

## Goal
- Verify the current state of the repo passes all required quality checks.

## Inputs
- Scope (all or specific module).
- Whether .github CAG files were touched.

## Steps
1. Load quality-pipeline before acting.
2. Run cargo clippy -- -D warnings. Fix any errors before continuing.
3. Run cargo test for the targeted scope.
4. If Lua API source changed: run python tools/docs/gen_lua_api_data.py and python tools/docs/gen_luadoc.py.
5. Run python tools/audit/doc_coverage.py and python tools/audit/test_coverage.py.
6. If .github was touched: run python tools/validate/cag_validate.py.
7. Report pass or fail for each gate with the command output.

## Success Criteria
- [ ] cargo clippy -- -D warnings passes.
- [ ] cargo test passes.
- [ ] Generated docs are current.
- [ ] Coverage tools report no critical gaps.
- [ ] CAG validator passes if .github was touched.

## Example Invocation
- /run-quality-gates scope=all
