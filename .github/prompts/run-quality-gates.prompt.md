---
description: "Run build, lint, format, and tests."
---
# Run Quality Gates

## Goal
- Run the main quality gates in sequence.

## Inputs
- None.

## Steps
- Load quality-pipeline.
- Run the chosen build or check command for the task.
- Run cargo clippy -- -D warnings.
- Run cargo fmt --check.
- Run the required tests.
- Record failures by command and file.
- Re-run only the failed gate after each fix.

## Success Criteria
- [ ] Build or check gate is complete.
- [ ] Clippy is clean.
- [ ] Format check passes.
- [ ] Required tests pass.
- [ ] Remaining failures are listed if the run is not clean.

## Anti-patterns
- Skip a gate because another gate already failed.
- Declare done with only partial output.
- Use git add .

## Example Invocation
- /run-quality-gates

## CAG Metadata
- **Mode**: agent
- **Loads skills**: quality-pipeline
