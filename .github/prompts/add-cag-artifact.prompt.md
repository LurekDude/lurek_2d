---
description: "Add or update one CAG artifact in .github/ with validation and zero drift."
agent: "CAG-Architect"
tools: [tools/validate/cag_validate.py, tools/audit/cag_link_check.py]
---
# Add CAG Artifact

## Goal
- Add or update one CAG artifact and keep the CAG layer coherent.

## Inputs
- Artifact type.
- Target path or name.
- Required behavior or routing impact.
- Any linked docs or validator rule to honor.

## Steps
1. Load [skill: cag-workflow](../skills/cag-workflow/SKILL.md) and [skill: tools-cag-validation](../skills/tools-cag-validation/SKILL.md) before acting.
2. Read the target .github file, .github/agents/README.md, docs/architecture/cag-system.md, and the current validator rules before editing.
3. Place the change in the smallest valid CAG layer, keep wording low-token, and update shared docs when routing, schema, or templates moved.
4. Run the focused CAG validator first, then rerun the full CAG pass and link check when the change crosses files or shared docs.

## Success Criteria
- [ ] The prompt goal was completed: Add or update one CAG artifact and keep the CAG layer coherent.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Duplicate a shared CAG rule that already has a single home.
- Change routing or schema text without updating the shared docs and templates.
- Leave the CAG layer with warnings after touching .github/.

## Example Invocation
- /add-cag-artifact type=skill name=balance-analytics

## CAG Metadata
Mode: agent
Loads skills: cag-workflow, tools-cag-validation
Inputs required: Artifact type., Target path or name., Required behavior or routing impact., Any linked docs or validator rule to honor.
