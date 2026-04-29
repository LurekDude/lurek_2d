---
description: "Audit one module for architecture, docs, tests, and contract drift."
agent: "Reviewer"
---
# Audit Module

## Goal
- Produce a module audit focused on correctness, drift, and missing coverage.

## Inputs
- Target module.
- Review depth.
- Known risk area.
- Any source of truth to honor.

## Steps
1. Load [skill: module-audit](../skills/module-audit/SKILL.md), [skill: module-architecture](../skills/module-architecture/SKILL.md), [skill: documentation](../skills/documentation/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read src/<module>/, docs/specs/<module>.md, related tests, and any linked docs or examples.
3. List findings first in severity order, with emphasis on behavior regressions, ownership leaks, stale docs, and missing tests.
4. Call out the highest-risk drift, the missing validation, and whether the module is ready for more feature work.

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
- /audit-module module=audio depth=full

## CAG Metadata
Mode: agent
Loads skills: module-audit, module-architecture, documentation, testing-rust
Inputs required: Target module., Review depth., Known risk area., Any source of truth to honor.
