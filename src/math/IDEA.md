# IDEA — src/math

## Niezrobione TODO/WIP

- TODO(FEAT): dodać parametryzację stałej prędkości dla krzywych Beziera (`evaluate_at_distance`).
- TODO(FEAT): rozważyć GPU offload generacji noise map dla dużych map (`compute`).
- TODO(FEAT): dodać algorytm rect packing (atlas/UI).
- TODO(PERF): ograniczyć alokacje w hot-path (`BezierCurve::evaluate`, `SpatialHash::query_*`, `polygon_clip`).
- TODO(PERF): rozważyć optymalizację `AabbTree::find_best_sibling` (lepsza strategia wyboru kandydata).
- TODO(TEST): dodać edge-case testy dla `noise_generator` (0 octaves, ujemna persistence).
- TODO(TEST): dodać edge-case testy geometrii dla wejść współliniowych (`delaunay_triangulate`, `convex_hull`).
- TODO(dedup): ujednolicić rozwiązywanie easing (`math/tween.rs` vs `src/tween`).
- TODO(dedup): doprecyzować i/lub scalić dublujące się API `noise_functions` vs `noise_generator`.
