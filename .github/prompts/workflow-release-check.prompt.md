---
description: "Run the full release-readiness workflow."
---

# Workflow Release Check

## Goal
- Full release readiness check for Lurek2D. Use before tagging a release or merging to main. Runs all quality gates and produces a go/no-go...

## Inputs
- VERSION intended release tag (e.g., v0.2.0)
- PLATFORM target platform(s) for the release binary (e.g., windows-x86_64, linux-x86_64)

## Steps
- Load rust-coding, testing-rust, tools-cag-validation before changing any files.
- Must complete with 0 errors
- Must complete with 0 warnings (treated as errors via -D warnings)
- Must pass (no unformatted files)
- All tests must pass; 0 failures, 0 panics
- Must produce grade B or better on all file families
- 0 CRITICAL issues, 3 HIGH issues
- Window must open and display without panic
- Close manually; verify no stderr errors
- docs/api/lurek.md every lurek.* function in the code has an entry
- README.md version badge and feature list current
- 0 known vulnerabilities in dependencies

## Success Criteria
- [ ] Console output from each gate
- [ ] Go/no-go verdict with specific blocking issues listed

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /workflow-release-check <VERSION>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: rust-coding, testing-rust, tools-cag-validation
- **Inputs required**: VERSION
