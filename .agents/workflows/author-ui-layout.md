---
description: "Author or update a TOML UI layout under content/layouts/."
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
1. Load ui-layout and lua-scripting before acting.
2. Read the target layout file, neighboring layouts, the Lua consumer, and any supporting content assets before editing.
3. Keep the layout readable, consistent with the existing content format, and aligned with the consuming Lua side.
4. Run the narrowest content or runtime check that loads the layout.

## Success Criteria
- [ ] The layout file is usable and consistent with the content format.
- [ ] Required sync files were updated.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Invent new schema fields not supported by src/ui/.
- Skip layout validation.

## Example Invocation
- /author-ui-layout file=content/layouts/inventory.toml screen=inventory
