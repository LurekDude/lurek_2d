---
description: "Build or publish a release: version bump, packaging, artifact validation."
---

# Op Build Release

## Goal
- Execute one reproducible release build end-to-end.

## Inputs
- Version target.
- Release scope (major, minor, patch).
- Platform and artifact constraints.

## Steps
1. Load build-system and quality-pipeline before acting.
2. Confirm Cargo.toml version matches the release scope bump.
3. Run cargo clippy -- -D warnings. Must pass clean.
4. Run cargo test. Must pass all tests.
5. Run python tools/gen_all_docs.py to regenerate all derived docs.
6. Run the dist packaging script: tools/dist/dist.ps1 or the equivalent.
7. Confirm artifact layout matches the expected build/ and dist/ structure.
8. Confirm docs/CHANGELOG.md has a current version entry.
9. Return pass/fail summary for each gate.

## Success Criteria
- [ ] Cargo.toml version is updated.
- [ ] cargo clippy -- -D warnings passes.
- [ ] cargo test passes.
- [ ] All derived docs are fresh.
- [ ] Packaging artifact is produced and named correctly.
- [ ] docs/CHANGELOG.md has a current version entry.

## Example Invocation
- /op-build-release version=0.5.0 scope=minor
