---
description: "Drive one failing test cluster back to green with the smallest valid owner set."
agent: "Manager"
tools: [tools/dev/parallel_cargo.py]
---
# Fix Failing Tests

## Goal
- Resolve a failing test cluster without widening scope.

## Inputs
- Failing test command or cluster.
- Known recent changes.
- Target acceptance bar.
- Any blocked owner.

## Steps
1. Load [skill: testing-rust](../skills/testing-rust/SKILL.md), [skill: quality-pipeline](../skills/quality-pipeline/SKILL.md), and [skill: module-architecture](../skills/module-architecture/SKILL.md) before acting.
2. Run or read the smallest failing test target first and cluster failures by owning subsystem instead of treating every failure as separate.
3. Choose the smallest valid owner for each cluster, keep one binary gate per cluster, and avoid parallel work when one root cause is more likely.
4. After each fix, rerun the same failing target before broadening to the next gate or owner.
5. Close only when the original failing cluster is green and any residual unrelated failures are explicit.

## Success Criteria
- [ ] The workflow outcome is complete: Resolve a failing test cluster without widening scope.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Shotgun edits across many modules before identifying the smallest failing owner slice.
- Accept a phase because the diff looks plausible without rerunning the failed tests.
- Hide residual unrelated failures behind a partial green result.

## Example Invocation
- /fix-failing-tests target='python tools/dev/parallel_cargo.py test lua'

## CAG Metadata
Mode: agent
Loads skills: testing-rust, quality-pipeline, module-architecture
Inputs required: Failing test command or cluster., Known recent changes., Target acceptance bar., Any blocked owner.
