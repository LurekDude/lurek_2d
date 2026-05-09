# IDEA — src/ui

## Niezrobione TODO/WIP

- TODO(FEAT): drag-and-drop między kontenerami (inventory/card patterns).
- TODO(FEAT): data-binding model <-> widget state (automatyczna synchronizacja wartości).
- TODO(FEAT): widget transitions/animations jako first-class mechanizm.
- TODO(PERF): dirty-flag/diff render dla widget tree (zamiast pełnego redraw co frame).
- TODO(TEST): rozszerzyć pokrycie chart draw paths (scatter/area + edge cases).
- TODO(TEST): rozszerzyć testy layout_loader dla zagnieżdżonych drzew i render_to_image.
- TODO(dedup): ograniczyć boilerplate dispatch (`WidgetKind::base/base_mut` i pokrewne match arms).
- TODO(dedup): wydzielić i ujednolicić wspólne fragmenty renderowania wykresów/legend.
- TODO(helper): wydzielić `WidgetRenderer`/helpery emit_* dla czytelniejszego pipeline rysowania.
- TODO(plugin): ocenić osobne feature-gate dla cięższych części (`ui-charts`, layout loader).
