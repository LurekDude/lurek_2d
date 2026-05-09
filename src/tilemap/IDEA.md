# IDEA — src/tilemap

## Niezrobione TODO/WIP

- TODO(FEAT): dodać pełny `HexMap` renderer (na bazie istniejącej matematyki hex).
- TODO(FEAT): szybki indeks tile-type (`type -> positions`) aktualizowany przy zmianach mapy.
- TODO(PERF): zoptymalizować aktualizację animowanych kafli (viewport/dirty-driven).
- TODO(FEAT): zwracać ustrukturyzowane błędy importu TMX/LDtk do Lua.
- TODO(FEAT): rozważyć wsparcie Wang tiles dla lepszego autotilingu.
- TODO(PERF): mocniejszy viewport culling w renderowaniu dużych map.
- TODO(QUAL): podzielić duże pliki `mapgen.rs` i `tilemap.rs` na mniejsze komponenty.
- TODO(TEST): rozszerzyć testy error-path parserów TMX/LDtk + fuzz XML.
- TODO(dedup): doprecyzować overlap kolizji tilemap z helperami kolizji w `physics`.
- TODO(helper): helpery `camera_follow_walker` i `tilemap_minimap` dla common pattern.
