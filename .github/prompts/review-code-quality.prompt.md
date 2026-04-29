---
description: "Review a bounded code slice for defects, risks, and missing validation."
agent: "Reviewer"
---
# Review Code Quality

## Goal
- Return a code review centered on bugs, regressions, and weak assumptions.

## Inputs
- Diff, file set, or module.
- Risk focus.
- Any expected acceptance bar.

## Steps
1. Load [skill: rust-coding](../skills/rust-coding/SKILL.md), [skill: module-architecture](../skills/module-architecture/SKILL.md), and [skill: error-handling](../skills/error-handling/SKILL.md) before acting.
2. Read the named diff or files, nearby tests, and the owning contract source if one exists.
3. Prioritize correctness, control-flow risk, error handling, and architecture leakage over style commentary.
4. End with residual risk and validation gaps after the findings list.

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
- /review-code-quality path=src/runtime

## CAG Metadata
Mode: agent
Loads skills: rust-coding, module-architecture, error-handling
Inputs required: Diff, file set, or module., Risk focus., Any expected acceptance bar.
