---
description: "Review unsafe Rust blocks for soundness, documented invariants, and containment."
agent: "Verifier"
---
# Review Unsafe Code

## Goal
- Assess whether unsafe code is justified, documented, and sound.

## Inputs
- Target file or module.
- Unsafe block scope.
- Any suspected invariant issue.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md) and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Read the unsafe blocks, surrounding ownership code, and any comments or tests that state the invariants.
3. Report missing SAFETY reasoning, invariant leaks, aliasing or lifetime risks, and cases where safe Rust should replace unsafe.
4. Summarize the highest-severity unsafe finding and the proof still missing if the block remains.

## Success Criteria
- [ ] Findings were listed first, or the prompt states clearly that no findings were found.
- [ ] Each finding is tied to a file, behavior, or missing proof.
- [ ] Missing validation or test coverage is called out.
- [ ] Residual risk or next owner is explicit.

## Anti-patterns
- Lead with summary instead of findings.
- Treat style nits as more important than behavior, safety, or contract drift.
- Declare the area clean without checking tests, validation, or missing proof.

## Example Invocation
- /review-unsafe-code path=src/runtime

## CAG Metadata
Mode: agent
Loads skills: rust-coding, error-handling
Inputs required: Target file or module., Unsafe block scope., Any suspected invariant issue.
