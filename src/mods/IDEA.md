# IDEA — src/mods

## Niezrobione TODO/WIP

- TODO(FEAT): zaimplementować realny hot-reload (nie tylko kolejkę reload).
- TODO(FEAT): dodać semver compatibility check dla `api_version`.
- TODO(FEAT): wykrywanie konfliktów modów (nadpisywanie tych samych asset paths).
- TODO(FEAT): dodać weryfikację integralności/podpisów modów.
- TODO(QUAL): raportować parse błędy `scan_folder` zamiast cichego pomijania.
- TODO(QUAL): dodać pełniejszą walidację schematu `mod.toml`.
- TODO(PERF): rozważyć `HashSet` dla deduplikacji `reload_queue`.
- TODO(TEST): testy dla wadliwych `mod.toml` (brak pola, zły typ, invalid TOML).
- TODO(TEST): testy `from_parts` dla kombinacji pól optional.
- TODO(TEST): test `get_mod_mut` modyfikujący wpis in-place.
- TODO(TEST): test `get_custom_load_order` accessor.
- TODO(dedup): refaktor `scan_folder` do użycia `from_parts` zamiast ręcznego mapowania pól.
- TODO(helper): dodać `get_mods_by_capability(cap)`.
- TODO(helper): dodać `topological_order()` zwracające błąd przy cyklach.
