---
description: "Run CAG validation."
---
# Run Cag Validation

## Goal
- Validate the CAG layer with tools/validate/cag_validate.py.

## Inputs
- None.

## Steps
- Load tools-cag-validation.
- Run python tools/validate/cag_validate.py.
- Read the errors and warnings.
- If this prompt is part of a fix task, fix the files and run the command again.
- Stop only when the final report is clean or the blocking issue is explicit.

## Success Criteria
- [ ] Validation output is available.
- [ ] Problem files are listed when the run fails.
- [ ] Final run is clean when fixes are part of the task.

## Anti-patterns
- Skip the final validation run.
- Declare done after one failing run.
- Use git add .

## Example Invocation
- /run-cag-validation

## CAG Metadata
- **Mode**: agent
- **Loads skills**: tools-cag-validation
