---
description: "Review unsafe code blocks: verify SAFETY comments and justification for every unsafe usage."
---

# Review Unsafe Code

## Purpose

Audit all `unsafe` blocks for proper justification and safety.

## Steps

1. Search for all `unsafe` blocks in `src/`
2. For each: verify `// SAFETY:` comment exists immediately above
3. Evaluate if `unsafe` is truly necessary (safe alternative available?)
4. Check that safety invariants are correctly maintained
5. Report unjustified or unnecessary `unsafe` usage

## Acceptance

- [ ] All `unsafe` blocks have `// SAFETY:` comments
- [ ] Each use of `unsafe` is genuinely necessary
- [ ] Safety invariants documented and upheld

## References

- `Security` agent
- `rust-coding` skill
