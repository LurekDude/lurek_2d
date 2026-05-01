---
description: "Triage open GitHub issues: label, severity, owner, and validation."
---

# Triage GitHub Issues

## Goal
- Process a set of open issues and produce a labeled, prioritized, and owner-assigned list.

## Inputs
- Issue list or label filter.
- Triage depth (quick scan or deep).
- Target module or area focus.

## Steps
1. Load github-workflow before acting.
2. Read each issue and identify: module or area, reproduction signal, severity, and likely owner.
3. Assign labels, milestone, and owner based on repo conventions in CONTRIBUTING.md.
4. Group issues by module or concern family.
5. Return the triaged list with label, severity, owner, and the validation command that would close each issue.

## Success Criteria
- [ ] Each issue has a label, severity, and likely owner.
- [ ] Related issues are grouped.
- [ ] Validation command or next step is explicit.
- [ ] No issues were closed based on assumptions alone.

## Example Invocation
- /triage-github-issues filter=open area=physics
