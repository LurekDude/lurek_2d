---
description: "Review entity lifecycle handling for leaks, stale handles, or invalid state transitions."
agent: "Reviewer"
---
# Review Entity Lifecycle

## Goal
- Find lifecycle bugs or contract drift in an entity-related slice.

## Inputs
- Target entity system or module.
- Lifecycle concern.
- Any repro or failing test.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md), [skill: module-architecture](../skills/module-architecture/SKILL.md), and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Read the owning module, creation or teardown paths, related tests, and any lifecycle spec notes.
3. Look for stale references, invalid transition order, missed cleanup, and ownership that crosses module boundaries.
4. Tie each finding to the exact lifecycle stage and the proof or missing proof behind it.

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
- /review-entity-lifecycle module=ecs issue=despawn_cleanup

## CAG Metadata
Mode: agent
Loads skills: rust-coding, module-architecture, error-handling
Inputs required: Target entity system or module., Lifecycle concern., Any repro or failing test.
