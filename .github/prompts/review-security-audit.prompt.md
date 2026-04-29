---
description: "Review a target surface for security risks, unsafe assumptions, and missing hardening."
agent: "Security"
---
# Review Security Audit

## Goal
- Produce a practical security review for one bounded attack surface.

## Inputs
- Target surface.
- Threat focus.
- Any known incident or repro.

## Steps
1. Load [skill: error-handling](../skills/error-handling/SKILL.md), [skill: asset-pipeline](../skills/asset-pipeline/SKILL.md), and [skill: dev-debugging](../skills/dev-debugging/SKILL.md) before acting.
2. Read the named files, data entry points, relevant asset or script loading paths, and any current validation logic.
3. Prioritize trust boundaries, file or script ingestion, panic paths, unchecked assumptions, and exploitability.
4. State severity, realistic exploit path, and the most important missing validation or hardening step.

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
- /review-security-audit surface=filesystem threat=untrusted_paths

## CAG Metadata
Mode: agent
Loads skills: error-handling, asset-pipeline, dev-debugging
Inputs required: Target surface., Threat focus., Any known incident or repro.
