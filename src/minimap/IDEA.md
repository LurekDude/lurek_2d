# IDEA — src/minimap

## Niezrobione TODO/WIP

- TODO(FEAT): GPU-accelerated fog of war dla dużych siatek.
- TODO(FEAT): wydzielenie fog-of-war do systemu współdzielonego (nie tylko minimapa).
- TODO(FEAT): wsparcie ikon/tekstur markerów i obiektów (zamiast samych prymitywów).
- TODO(PERF): culling w `build_render_commands` (obecnie iteruje po całej siatce).
- TODO(PERF): zoptymalizować polityczne kolorowanie w `draw_to_image` (uniknąć O(objects*cells)).
- TODO(TEST): test poprawności pikselowej `draw_to_image`.
- TODO(TEST): test spójności `build_render_commands` vs `generate_render_commands`.
- TODO(dedup): scalić podwójną ścieżkę budowy komend renderowania terenu.
- TODO(dedup): wydzielić wspólny helper `fog_multiplier(gx, gy)`.
- TODO(helper): dodać `Minimap::track_camera(camera)`.
- TODO(helper): dodać `Minimap::reveal_radius(cx, cy, radius)`.
