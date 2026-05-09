# IDEA — src/log

## Niezrobione TODO/WIP

- TODO(FEAT): dodać opcjonalny timestamp w liniach sinków plikowych.
- TODO(FEAT): dodać przełącznik ANSI/NO_COLOR dla wyjścia logów.
- TODO(FEAT): dodać format NDJSON/JSON dla sinków plikowych.
- TODO(FEAT): rozszerzyć `SinkLevel` o poziom `Trace`.
- TODO(FEAT): dodać per-tag/per-category filtering w `SinkRegistry`.
- TODO(FEAT): dodać sink callbackowy do pushowania logów do UI bez pollingu.
- TODO(PERF): dodać buforowane/asynchroniczne zapisy do pliku (obecnie sync write per wpis).
- TODO(QUAL): zaimplementować `FromStr` dla `SinkLevel` i usunąć niejednoznaczny inherent `from_str`.
- TODO(TEST-RUST): test rotacji `RotatingFileSink::rotate` (rename/delete cycle).
- TODO(TEST-RUST): testy error-path dla `Sink::file()` i `Sink::rotating_file()`.
- TODO(TEST-RUST): test dispatch z mieszanymi poziomami sinków.
- TODO(dedup): wydzielić wspólny formatter structured logów (`log_structured` vs `Sink::write_structured`).
- TODO(dedup): rozważyć unifikację ring-buffera (`MemorySink` vs `data::RingBuffer`).
- TODO(helper): helper `format_log_line(level, tag, msg, timestamp)` dla wspólnego formatowania linii.
