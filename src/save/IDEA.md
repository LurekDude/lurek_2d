# IDEA — src/save

## Niezrobione TODO/WIP

- TODO(dedup): usunąć lub scalić martwy, dublujący plik `save_data.rs`.
- TODO(FEAT): dodać checksum/integrity check dla plików zapisu.
- TODO(FEAT): dodać deterministyczną serializację (stabilna kolejność kluczy).
- TODO(FEAT): dodać wsparcie kompresji po stronie Rust (nie tylko logika Lua).
- TODO(FEAT): rozważyć screenshot/thumbnail dla slotów zapisu.
- TODO(FEAT): rozważyć incremental/delta save.
- TODO(dedup): doprecyzować kontrakt `save` vs `serial` (obecnie własny format Lua-syntax).
- TODO(dedup): rozważyć przeniesienie I/O slotów do warstwy SaveManager + GameFS.
- TODO(helper): helpery save-utils (rotacja slotów, browser UI, import/export).
