---
description: "Review code that contains unsafe blocks for SAFETY justification and correctness."
---

# Review Unsafe Code

## Goal
- Audit all unsafe blocks in a given module for missing SAFETY comments and genuine correctness risks.

## Inputs
- Module or files to review.

## Steps
1. Load rust-coding before acting.
2. Find all unsafe blocks in the target files with grep or search.
3. For each block: check that a SAFETY comment exists explaining the invariant, and verify the invariant is actually upheld by the surrounding code.
4. Flag any unsafe block with no SAFETY comment as critical.
5. Flag any unsafe block where the invariant claim is incomplete or false as critical.
6. Return the ranked list with file and line references.

## Success Criteria
- [ ] Every unsafe block has a SAFETY comment.
- [ ] All SAFETY invariants are verifiable from the surrounding code.
- [ ] Critical issues are identified with file and line.

## Example Invocation
- /review-unsafe-code module=src/render/
