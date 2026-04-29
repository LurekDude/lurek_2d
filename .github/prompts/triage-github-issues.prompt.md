---
description: "Triage issue input into clusters, priorities, and next actions."
agent: "Discovery-Lead"
---
# Triage Github Issues

## Goal
- Turn a raw issue set into a short, actionable triage result.

## Inputs
- Issue list or export.
- Target milestone or theme.
- Priority lens.
- Any existing labels.

## Steps
1. Load [skill: github-workflow](../skills/github-workflow/SKILL.md) and [skill: opportunity-discovery](../skills/opportunity-discovery/SKILL.md) before acting.
2. Read the issue set, current labels or milestones, and any linked idea or roadmap notes before clustering.
3. Group duplicates and related pain points into shared themes so priority is set on real opportunity size rather than issue count.
4. Separate bugs, backlog candidates, content gaps, and tooling pain, and recommend the smallest next routing or labeling step for each cluster.
5. Close with the priority order, evidence strength, and any issue set that still lacks enough context to rank safely.

## Success Criteria
- [ ] The workflow outcome is complete: Turn a raw issue set into a short, actionable triage result.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /triage-github-issues milestone=0.3 source=issues_export.json

## CAG Metadata
Mode: agent
Loads skills: github-workflow, opportunity-discovery
Inputs required: Issue list or export., Target milestone or theme., Priority lens., Any existing labels.
