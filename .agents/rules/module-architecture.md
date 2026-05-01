---
description: "Load when planning module boundaries, dependency direction, or crate layout. Skip for implementation or API naming."
alwaysApply: false
---

# module-architecture

## Mission
- Own module boundaries, dependency direction, and visibility rules.

## When To Load
- Plan a new module.
- Review module boundaries.
- Fix bad dependency direction.
- Check crate or folder layout.

## When To Skip
- Implementation work.
- API naming.

## Domain Knowledge
- Each src module should map to docs/specs/<module>.md and keep mod.rs as a thin manifest, so structure decisions remain visible to both code readers and spec readers.
- Domain code must not import the binding layer; src/lua_api remains a thin wrapper boundary, not a shared utility layer or architectural shortcut.
- Prefer one clear owner for state, side effects, public data types, and lifecycle transitions; split modules only when ownership becomes clearer, not because a file feels large in isolation.
- New modules must fit the current export shape in src/lib.rs and the documented dependency direction across foundations, core runtime, platform services, feature systems, and edge or integration layers.
- Avoid dependency cycles by keeping cross-layer traffic one-directional; when a module wants data from a higher layer, that is usually a sign the boundary is wrong.
- Large restructures need migration steps, contract impact, and downstream sync plans, not only target diagrams or aspirational folder trees.
- Ownership changes should preserve test placement rules, Lua binding boundaries, examples, and docs/specs sync instead of treating architecture as a src/-only concern.
- Public types should live with the module that owns their invariants; forwarding them through unrelated modules weakens dependency clarity and reviewability.
- Use validate_module_coverage.py and thin module audits when ownership changes so the structural story remains consistent across code and docs.

## References
- docs/specs/
- src/lib.rs
- tools/validate/validate_module_coverage.py
- tools/audit/thin_modrs_audit.py
