# IDEA — src/serial

## Niezrobione TODO/WIP

- TODO(PERF): dodać streaming CSV parsing dla dużych datasetów (bez pełnego ładowania do pamięci).
- TODO(FEAT): schema defaults przy walidacji (uzupełnianie brakujących pól wartościami domyślnymi).
- TODO(PERF): ograniczyć alokacje na ścieżce MessagePack encode/decode.
- TODO(TEST-FUZZ): dodać fuzz targety dla parserów tekstowych (`json`, `toml`, `xml`, `csv`, `ini`).
- TODO(dedup): doprecyzować podział odpowiedzialności serializacji między `serial` i `save`.
- TODO(dedup): potwierdzić pojedynczą implementację CSV/MsgPack (brak równoległych ścieżek w innych modułach).
- TODO(helper): helper auto-detect by extension/content dla wygodniejszego użycia w content/library.
