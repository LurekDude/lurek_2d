# P6 Overlap Matrix

Owner: architect

Done When:
- Dead duplicates removed or justified as intentional.
- Top overlap boundaries have signed-off ownership decisions.
- Shared-helper extraction candidates have implementation owners.

Inputs:
- src/save/save_data.rs
- src/graph/graph.rs
- src/graph/traversal.rs
- docs/specs/* for overlap modules

Produces:
- work/<session>/reports/p6_overlap_resolution.md

Execution Steps:
1. Immediate cleanup:
  - remove dead duplicates in save and graph module paths
2. Lock boundary decisions:
  - tween vs animation
  - effect vs camera shake
  - serial vs data msgpack ownership
  - sprite vs animation Aseprite parsing
  - thread vs event queue model
3. Define shared-helper extractions:
  - render command builders
  - parse/format conversion helpers
4. Create implementation tickets with done-when gate per overlap item.

Out of Scope:
- New gameplay features.
- Broad architecture changes outside overlap set.
