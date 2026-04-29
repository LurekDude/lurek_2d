---
description: "Run a broader repo quality sweep and summarize real blockers by owner."
agent: "Manager"
tools: [tools/dev/parallel_cargo.py]
---
# Run Quality Sweep

## Goal
- Produce a broad but owner-readable quality sweep result.

## Inputs
- Sweep scope.
- Required gates.
- Any known hot spots.

## Steps
1. Load [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md), [skill: module-audit](../skills/module-audit/SKILL.md), [skill: testing-rust](../skills/testing-rust/SKILL.md), and [skill: documentation](../skills/documentation/SKILL.md) before acting.
2. Decide whether the request needs a full-repo sweep or a bounded sweep first; avoid paying full-repo cost when the question is local.
3. Run the requested gates in a stable order and group findings by owning subsystem or artifact type.
4. Separate hard blockers from advisory gaps so the next owner can act without rereading the whole sweep.
5. Close with a short owner-by-owner action list and the exact gates still red.

## Success Criteria
- [ ] The workflow outcome is complete: Produce a broad but owner-readable quality sweep result.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /run-quality-sweep scope=repo

## CAG Metadata
Mode: agent
Loads skills: quality-pipeline, module-audit, testing-rust, documentation
Inputs required: Sweep scope., Required gates., Any known hot spots.
