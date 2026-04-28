---
description: "Review unsafe blocks and SAFETY comments."
---

# Review Unsafe Code

## Goal
- Audit all unsafe blocks for proper justification and safety.

## Inputs
- None.

## Steps
- Load rust-coding before changing any files.
- Search for all unsafe blocks in src/
- For each: verify // SAFETY: comment exists immediately above
- Evaluate if unsafe is truly necessary (safe alternative available?)
- Check that safety invariants are correctly maintained
- Report unjustified or unnecessary unsafe usage

## Success Criteria
- [ ] All unsafe blocks have // SAFETY: comments
- [ ] Each use of unsafe is genuinely necessary
- [ ] Safety invariants documented and upheld

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-unsafe-code

## CAG Metadata
- **Mode**: agent
- **Loads skills**: rust-coding
