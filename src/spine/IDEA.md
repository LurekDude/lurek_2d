# IDEA — src/spine

## Niezrobione TODO/WIP

- TODO(FEAT): importer formatów szkieletów (np. Spine/DragonBones JSON).
- TODO(FEAT): mesh deformation / weighted vertices.
- DONE(FEAT): animation state machine / blending tree dla przejść między animacjami - `animation_blended()` z blend_weight parametrem (0.0-1.0) zaimplementowany w `timeline.rs`.
- TODO(PERF): usunąć klonowanie animacji/constraintów w hot-path (przejście na iterację indeksową).
- TODO(TEST): test integracyjny pełnego pipeline (animacja -> IK -> render).
- TODO(TEST): benchmark `update_world_transforms` dla dużych rigów (100+ kości).
- DONE(helper): helpery `from_json`, `pose_at`, `reverse` dodane w `timeline.rs` i wyeksponowane do Lua (`poseAt`, `reverse`, `animationFromJson`).
- TODO(plugin): utrzymać ścieżkę ekstrakcji jako TIER-2-PLUGIN (feature-gate).
