# IDEA — src/scene

## Niezrobione TODO/WIP

- TODO(FEAT): dodać transition chaining/sequencer (kolejkowanie kilku przejść).
- TODO(FEAT): rozważyć scene groups/layers z równoległą aktualizacją logiczną.
- TODO(PERF): profile i benchmark ścieżek sortowania `DepthSorter` dla dużych wolumenów.
- TODO(TEST): dodać stress-test wielu overlay scen (kolejność i active IDs).
- TODO(TEST): dodać boundary testy easing/transition dla nietypowych wartości czasu.
- TODO(dedup): ocenić czy `DepthSorter` powinien zostać w `scene` czy przejść bliżej `render`.
- TODO(dedup): doprecyzować relację transition rendering (`scene`) vs post-fx (`effect`).
- TODO(helper): rozważyć przeniesienie/lub współdzielenie `bounce_out` z modułem easing.
