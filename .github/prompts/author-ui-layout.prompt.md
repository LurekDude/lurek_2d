---
description: "Author or update a TOML UI layout under content/layouts/."
agent: "Content-Maker"
---
# Author UI Layout

## Goal
- Produce one usable layout file for a concrete UI surface.

## Inputs
- Target screen or HUD.
- Layout file path.
- Required widgets or regions.
- Any runtime consumer.

## Steps
1. Load [skill: ui-layout](../skills/ui-layout/SKILL.md) and [skill: lua-scripting](../skills/lua-scripting/SKILL.md) before acting.
2. Read the target layout file, neighboring layouts, the Lua consumer, and any supporting content assets before editing.
3. Keep the layout readable, consistent with the existing content format, and aligned with the consuming Lua side instead of inventing new schema fields.
4. Run the narrowest content or runtime check that loads the layout and confirm the touched screen still resolves correctly.

## Success Criteria
- [ ] The prompt goal was completed: Produce one usable layout file for a concrete UI surface.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /author-ui-layout file=content/layouts/inventory.toml screen=inventory

## CAG Metadata
Mode: agent
Loads skills: ui-layout, lua-scripting
Inputs required: Target screen or HUD., Layout file path., Required widgets or regions., Any runtime consumer.
