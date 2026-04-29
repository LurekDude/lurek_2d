---
description: "Run the full CAG validation flow and report the owning files for any violations."
agent: "CAG-Architect"
tools: [tools/validate/cag_validate.py, tools/audit/cag_link_check.py, tools/audit/cag_coverage.py, tools/audit/cag_persona_matrix.py]
---
# Run CAG Validation

## Goal
- Return a clear validation result for the current CAG layer.

## Inputs
- Scope: file, type, or full layer.
- Need for strict or baseline mode.
- Any recent shared-doc or routing changes.

## Steps
1. Load [skill: tools-cag-validation](../skills/tools-cag-validation/SKILL.md) before acting.
2. Choose the narrowest validator scope that can answer the question, then widen to a full pass if the change crossed files or shared contracts.
3. Run supporting audits such as link, coverage, or persona checks when the touched scope makes them relevant.
4. Group any failures by file and rule so the owning fix is obvious, and keep warnings visible instead of smoothing them over.
5. Close with the exact commands run and whether the layer is strict-green or still blocked.

## Success Criteria
- [ ] The workflow outcome is complete: Return a clear validation result for the current CAG layer.
- [ ] The controlling files, checks, or owners were identified.
- [ ] Required validation or gate output is attached.
- [ ] Remaining blockers or risks are explicit.

## Anti-patterns
- Let the workflow widen with no clear owner or gate.
- Skip the first focused check and rely on narrative confidence.
- Close the task while blockers, warnings, or failed gates are still open.

## Example Invocation
- /run-cag-validation scope=prompt

## CAG Metadata
Mode: agent
Loads skills: tools-cag-validation
Inputs required: Scope: file, type, or full layer., Need for strict or baseline mode., Any recent shared-doc or routing changes.
