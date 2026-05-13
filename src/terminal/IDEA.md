# IDEA — src/terminal

## Niezrobione TODO/WIP

- DONE(FEAT): ANSI 256-color i true-color (24-bit) parsing (`38;5;n` / `48;5;n` oraz `38;2;r;g;b` / `48;2;r;g;b` w `ansi.rs`).
- TODO(FEAT): skróty klawiaturowe terminala (np. clipboard/editing shortcuts).
- DONE(FEAT): hover/highlight interakcje myszy na poziomie komórek - `terminal_tests.rs` ma mousepressed/focus routing, `test_terminal_core_unit.lua` ma testy click detection.
- TODO(PERF): ograniczyć klonowanie bufora siatki przy kompozycji widgetów.
- TODO(TEST): rozszerzyć testy widgetów terminalowych (np. złożone scenariusze focus/children).
- DONE(dedup): wydzielić wspólne helpery zapisu komórek (\set_render_cell\/\clear_render_rect\/\write_render_text\).
- TODO(helper): przenieść generyczne helpery tekstowe do współdzielonego \	ext_utils\.
- TODO(plugin): ocenić ekstrakcję modułu jako feature/plugin dla gier bez terminala.