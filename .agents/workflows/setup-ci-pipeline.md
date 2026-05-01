---
description: "Set up or update the CI pipeline for the repo."
---

# Setup CI Pipeline

## Goal
- Design or update one CI workflow file that mirrors local quality gates.

## Inputs
- Target CI platform (GitHub Actions).
- Quality gates to mirror.
- Platform matrix constraints.
- Caching and artifact requirements.

## Steps
1. Load ci-cd-pipeline and build-system before acting.
2. Identify which local quality gates to mirror: fmt, clippy, test, docs, packaging.
3. Design jobs that are non-interactive, deterministic, and use checked-in scripts.
4. Split fast feedback from slow packaging or release work.
5. Pin tool versions and prefer cargo cache for Cargo dependencies only.
6. Confirm artifact naming and upload paths align with build/ and dist/ structure.

## Success Criteria
- [ ] Jobs mirror local quality gates exactly.
- [ ] Jobs are deterministic and use checked-in scripts.
- [ ] Fast feedback and slow packaging are separate jobs.
- [ ] Tool versions are pinned.

## Anti-patterns
- Hide repo logic inside CI shell blocks.
- Create CI-only packaging paths that diverge from tools/dist/.
- Cache mutable generated artifacts.

## Example Invocation
- /setup-ci-pipeline platform=github-actions gates=fmt,clippy,test,docs
