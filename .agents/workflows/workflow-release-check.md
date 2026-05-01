---
description: "Run the full release quality sweep: clippy, tests, docs, coverage, changelog, and version checks."
---

# Workflow Release Check

## Goal
- Confirm the repo is ready for a release by running all required checks.

## Inputs
- Target version.
- Release scope (major, minor, patch).

## Steps
1. Load quality-pipeline before acting.
2. Confirm Cargo.toml version matches the release scope bump.
3. Run cargo clippy -- -D warnings. Must pass clean.
4. Run cargo test. Must pass all tests.
5. Run python tools/gen_all_docs.py to regenerate all derived docs.
6. Run python tools/audit/doc_coverage.py and python tools/audit/test_coverage.py. Report gaps.
7. Confirm docs/CHANGELOG.md has an entry for the current version.
8. Return a pass/fail summary for each gate.

## Success Criteria
- [ ] Cargo.toml version is updated.
- [ ] cargo clippy -- -D warnings passes.
- [ ] cargo test passes.
- [ ] All derived docs are fresh.
- [ ] docs/CHANGELOG.md has a current version entry.

## Example Invocation
- /workflow-release-check version=0.4.0 scope=minor
