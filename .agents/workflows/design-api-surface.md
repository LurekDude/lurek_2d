---
description: "Design or review the lurek.* public API surface for a new or changed module."
---

# Design API Surface

## Goal
- Produce an accepted API design for one lurek.* module or extension.

## Inputs
- Module or feature name.
- Required capabilities and constraints.
- Existing docs/specs/<module>.md or starting notes.

## Steps
1. Load lua-api-design and documentation before acting.
2. Read docs/api/lurek.md, docs/specs/<module>.md, and content/examples/ for the nearest neighbor APIs.
3. Draft the function signatures, callback shapes, and return types. Keep the namespace lurek.* only.
4. Validate consistency: names match existing neighbors, params are explicit, callbacks are predictable.
5. Write or update docs/specs/<module>.md with the accepted design before any Rust implementation begins.

## Success Criteria
- [ ] API stays within lurek.* namespace.
- [ ] Names, params, and returns are consistent with neighbors.
- [ ] docs/specs/<module>.md is written or updated.
- [ ] No Rust code changed in this phase.

## Example Invocation
- /design-api-surface module=minimap
