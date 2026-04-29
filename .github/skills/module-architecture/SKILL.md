---
name: module-architecture
description: "Load this skill when planning module boundaries, dependency direction, or crate layout. Skip it for implementation or API naming."
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
- Each src module should map to docs/specs/<module>.md and keep mod.rs as a thin manifest.
- Domain code must not import the binding layer; src/lua_api remains a thin wrapper boundary.
- Prefer one clear owner for state, side effects, and public data types.
- New modules must fit current export shape in src/lib.rs and current dependency direction.
- Large restructures need migration steps and contract impact, not only target diagrams.
- Use validate_module_coverage.py and thin module audits when ownership changes.
- Module shape should match docs/specs, thin wrapper rules, and the current export graph in src/lib.rs rather than a theoretical ideal.
- Ownership decisions here need to preserve test placement, Lua binding boundaries, and docs sync work.
- This skill owns structure and dependency direction, not implementation details or generated docs.
## Companion File Index
- None.

## References
- docs/specs/
- src/lib.rs
- tools/validate/validate_module_coverage.py
- tools/audit/thin_modrs_audit.py
