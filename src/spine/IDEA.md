# IDEA — src/spine

## Niezrobione TODO/WIP

- TODO(FEAT): importer formatów szkieletów (np. Spine/DragonBones JSON).
- TODO(FEAT): mesh deformation / weighted vertices.
- TODO(FEAT): animation state machine / blending tree dla przejść między animacjami.
- TODO(PERF): usunąć klonowanie animacji/constraintów w hot-path (przejście na iterację indeksową).
- TODO(TEST): test integracyjny pełnego pipeline (animacja -> IK -> render).
- TODO(TEST): benchmark `update_world_transforms` dla dużych rigów (100+ kości).
- TODO(helper): helpery typu `from_json`, `pose_at`, `reverse` dla wygodniejszego użycia.
- TODO(plugin): utrzymać ścieżkę ekstrakcji jako TIER-2-PLUGIN (feature-gate).
