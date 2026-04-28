---
description: "Run a repo-wide quality sweep."
---
# Run Quality Sweep

## Goal
- Run an audit-fix-verify sweep over the chosen scope and report what is still open.

## Inputs
- scope: the named area to sweep.

## Steps
- Load quality-pipeline.
- Define the target scope.
- Run the right audits and validators for that scope.
- Fix only issues that belong to this sweep.
- Re-run the same checks.
- Summarize what passed, what still fails, and who should own the next step.

## Success Criteria
- [ ] The sweep scope is clear.
- [ ] The right checks ran for that scope.
- [ ] Any applied fixes were revalidated.
- [ ] Remaining issues and owners are listed.

## Anti-patterns
- Run unrelated checks outside scope.
- Mix unrelated fixes into the sweep.
- Stop after the first failed check with no summary.
- Use git add .

## Example Invocation
- /run-quality-sweep src/

## CAG Metadata
- **Mode**: agent
- **Loads skills**: quality-pipeline
- **Inputs required**: scope
