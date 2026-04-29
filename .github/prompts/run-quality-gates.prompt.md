---
description: "Run the required quality gates for one bounded change area and report the first failing gate."
agent: "Build-Engineer"
tools: [tools/dev/parallel_cargo.py]
---
# Run Quality Gates

## Goal
- Return a clean, ordered quality-gate result for the named scope.

## Inputs
- Scope or target.
- Required gate set.
- Any known flaky area.

## Steps
1. Load [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md) before acting.
2. Choose the narrowest meaningful gate first, then expand to the broader required gates only after the focused gate result is clear.
3. Keep formatter, lints, tests, and docs or generator checks separated so the first real blocker stays obvious.
4. If a gate fails, report the failing command, target surface, and likely owner instead of burying the problem in a long transcript.
5. Close with the exact gate status and any skipped checks that still remain.

## Success Criteria
- [ ] The workflow outcome is complete: Return a clean, ordered quality-gate result for the named scope.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /run-quality-gates scope=audio gates=clippy,test

## CAG Metadata
Mode: agent
Loads skills: quality-pipeline
Inputs required: Scope or target., Required gate set., Any known flaky area.
