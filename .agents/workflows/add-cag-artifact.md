---
description: "Add or update one agent rule or workflow file in .agents/ with validation and zero drift."
---

# Add CAG Artifact

## Goal
- Add or update one .agents/ rule or workflow and keep the layer coherent.

## Inputs
- Artifact type (rule or workflow).
- Target path or name.
- Required behavior or routing impact.
- Any linked docs or validator rule to honor.

## Steps
1. Load cag-workflow and tools-cag-validation before acting.
2. Read the target .agents/ file, docs/architecture/cag-system.md, and the current validator rules before editing.
3. Place the change in the smallest valid layer, keep wording low-token, and update shared docs when routing, schema, or templates moved.
4. Run the focused validator first, then rerun the full pass and link check when the change crosses files.

## Success Criteria
- [ ] The artifact was added or updated with correct frontmatter.
- [ ] Required sync files were updated for the touched slice.
- [ ] Validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Duplicate a shared rule that already has a single home.
- Change routing or schema text without updating shared docs.
- Leave the .agents/ layer with warnings after touching it.

## Example Invocation
- /add-cag-artifact type=skill name=balance-analytics
