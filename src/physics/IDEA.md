# IDEA — src/physics

## Niezrobione TODO/WIP

- TODO(FEAT): dodać one-way platform filter dla platformerów.
- TODO(FEAT): dodać model buoyancy/fluid forces (bez pełnej symulacji cieczy).
- TODO(FEAT): dodać eventy uszkodzeń chunków terenu (terrain damage notifications).
- TODO(PERF): ograniczyć alokacje przy batchowaniu kontaktów w `World::step`.
- TODO(QUAL): podzielić duży `world.rs` na mniejsze części (np. joints/queries).
- TODO(dedup): doprecyzować odpowiedzialność debug-draw pomiędzy `physics` i `render`.
- TODO(helper): helpery wzorców `one_way_platform` i `terrain_explosion` dla Lua/content.
