# P9 Alignment Execution Plan

Owner: manager

Done When:
- All architecture boundary tasks are implemented and documented.
- Cross-artifact sync is complete for scope modules.
- Final quality gate is green.

Inputs:
- src/raycaster/*
- src/minimap/*
- src/image/*
- src/province/*
- src/graph/*
- src/tilemap/*
- src/render/obj_loader.rs
- docs/specs/* (affected)
- docs/CHANGELOG.md

Produces:
- work/<session>/reports/p9_alignment_closure.md

Execution Phases:
1. Remove raycaster public minimap path and keep minimap public surface in minimap module.
2. Separate image and province ownership (domain logic in province, image IO/processing in image).
3. Remove runtime/render dependency from graph core.
4. Restrict tilemap polygon scope to tilemap utility and overlay use-cases.
5. Document obj_loader as 2D projection only.
6. Finalize province, globe, graph adapter boundaries and publish contract note.
7. Execute cross-artifact sync in one pass:
  - specs
  - examples
  - changelog
8. Close quality findings in scope:
  - thin-wrapper logic issues
  - unsafe unwrap hotspots
  - float assertion robustness
9. Fix audit false positives in tools/audit/audit_module.py for unit test naming.
10. Run final gates:
  - cargo clippy -- -D warnings
  - cargo test
  - python tools/gen_all_docs.py
  - python tools/audit/audit_module.py image light minimap particle effect tilemap province graph globe physics render

Out of Scope:
- Expanding scope to unrelated modules.
- New feature additions not required by alignment.
