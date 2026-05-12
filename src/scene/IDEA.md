# IDEA — src/scene

## Niezrobione TODO/WIP

- DONE(FEAT): dodano transition chaining/sequencer (kolejkowanie kilku przejść) przez kolejkę transition w `SceneStack` i API Lua.
- DONE(FEAT): wdrożono scene layers (deterministyczna kolejność callbacków); równoległa aktualizacja Lua pozostaje wyłączona z powodu pojedynczego VM.
- DONE(PERF): dodano testy dużych wolumenów `DepthSorter` i uporządkowano ścieżki sortowania dla pomiarów.
- DONE(TEST): dodano stress-test wielu overlay scen (kolejność i active IDs).
- DONE(TEST): dodano boundary testy easing/transition dla nietypowych wartości czasu.
- DONE(dedup): utrzymano `DepthSorter` w `scene` jako właściciela callback lifecycle; granica z `render` doprecyzowana w spec.
- DONE(dedup): doprecyzowano relację transition rendering (`scene`) vs post-fx (`effect`) w spec.
- DONE(helper): wydzielono współdzielony helper `bounce_out` do `src/scene/easing.rs`.
