
# Test Roadmap

## Status Snapshot (2026-05-09)

Artifacts generated in this execution:
- `logs/data/lua_api_test_coverage.json`
- `logs/reports/lua_api_test_coverage.md`
- `logs/data/test_analytics.json`
- `logs/reports/test_analytics.html`

Baseline metrics:
- strict marker coverage: `4461/4518` (`99.3%`)
- hybrid coverage: `4510/4518` (`99.8%`)
- describe coverage: `172/4518` (`3.8%`)
- orphaned `@covers` markers: `140`
- unresolved `describe(...)` targets: `82`

Current gate status:
- strict `@covers` gate: PASS for `--threshold 50`
- describe gate (`--describe-threshold 35`): FAIL (expected; backlog remains)
- CI workflow: added in `.github/workflows/test-analytics.yml`

## Faza 1 - Baseline i spojnosc artefaktow
- Wygenerowac nowy raport coverage z aktualnego stanu i podmienic stare liczby oraz priorytety.
- Dopisac aktualny snapshot false-positive po ostatnich markerach.
- Zweryfikowac i ujednolicic sekcje testowe w docs/specs pod zasady marker/evidence/golden.
- Domknac cross-artifact sync miedzy ideas/tests, docs/architecture/test-framework.md i tests/README.md.

## Faza 2 - Marker i describe coverage
- Dokonczyc rollout markerow @covers dla pozostalych unit tests, szczegolnie slabiej pokrytych modulow.
- Dodac parse describe("lurek.x.y", ...) do tools/audit/lua_api_test_coverage.py.
- Dodac metryke describe-score per metoda i per modul do raportu coverage.
- Regularnie czyscic orphaned markers (literowki i nieaktualne nazwy API).
- Ustawic prog CI dla describe coverage.
- Wlaczyc --strict jako domyslny gate CI po ustabilizowaniu marker coverage.

Status:
- zrobione: parse `describe(...)` w `tools/audit/lua_api_test_coverage.py`
- zrobione: `describe_score` per metoda i per modul
- zrobione: prog CI dla describe coverage (`--describe-threshold`)
- zrobione: strict gate jako domyslny krok w workflow CI
- do domkniecia: redukcja orphaned markers i podniesienie `describe coverage`

## Faza 3 - Jakosc i odpornosc testow
- Dodac dedykowane bloki error handling dla: physics, graphics, entity, tilemap, audio.
- Zrobic systematyczny audit nil-argumentow dla API i ujednolicic oczekiwane zachowanie.
- Zrobic globalny audit porownan float i zamienic bledne expect_equal na expect_near.
- Dokonczyc refaktor duzych plikow testowych do mniejszych plikow tematycznych.
- Dodac wspoldzielone fixture helpers (np. make_test_world, make_test_grid).
- Uporzadkowac polityke pending/xit (kazdy skip z powodem i linkiem do zadania).

## Faza 4 - Integracja modulow
- Dokonczyc rozszerzony pakiet integracji (Phase 2 / Group A-F) z zasada: kazdy test integration dotyka co najmniej 2 modulow.
- Uzupelnic scenariusze 3-modulowe (AI/scene/camera, UI/localization/data, postfx/camera, minimap/tilemap/camera, raycaster/tilemap).
- Zweryfikowac i uzupelnic rejestracje nowych testow integration w tests/lua/harness.rs.

Status:
- zrobione: dodano testy `test_ai_scene_camera.lua`, `test_ui_localization_data.lua`, `test_postfx_camera.lua`, `test_minimap_tilemap_camera.lua`, `test_raycaster_tilemap.lua`
- zrobione: rejestracje nowych integracji w `tests/lua/harness.rs`
- zrobione: walidacja selektywna `cargo test --test lua_tests <nowe_integracje>`

## Faza 5 - Evidence, golden i visual regression
- Dodac runtime smoke dla: light, particle, postfx, audio w tests/rust/ext.
- Dodac screenshot i pixel porownania dla przypadkow, ktore nie sa wiarygodne headless.
- Dokonczyc visual regression pipeline (baseline, diff, tolerancje).
- Ustalic i opisac finalny workflow aktualizacji baseline dla goldenow wizualnych.
- Dodac brakujace goldeny z obszaru visual/effects/spine albo jawnie zamknac je jako out-of-scope.
- Domknac coverage evidence dla obszarow wysokiego ryzyka (light, postfx, particle) i ustawic minimalny gate CI.
- Uzupelnic smoke testy dem i mapowanie demo->test.

Status:
- zrobione: dodano `tests/rust/ext/effects_audio_runtime_smoke_tests.rs` (light + particle + effect + audio)
- zrobione: podpiecie ext smoke testow do `Cargo.toml` (`effects_audio_runtime_smoke_tests`, `graphics_runtime_smoke_tests`, `terminal_demo_smoke_tests`)
- zrobione: selektywna walidacja `cargo test --test effects_audio_runtime_smoke_tests`

## Faza 6 - Metody zaawansowane
- Dodac brakujace property-based testy dla: data, serial, image, physics.
- Rozszerzyc fuzzing API w tests/lua/security (nil/type/extreme) i ustalic zestaw modulow P0.
- Wdrozyc mutation testing (cargo-mutants) dla modulow priorytetowych i raport przezytych mutantow.
- Dodac generator contract-testow na bazie lua_api_data.json i uruchamiac je okresowo.
- Dodac dedykowane load tests (dlugie scenariusze) za feature flaga.

Status:
- zrobione: dodano bloki property-based do `test_data_core_unit.lua`, `test_serial_core_unit.lua`, `test_image_core_unit.lua`, `test_physics_core_unit.lua`
- zrobione: rozszerzono fuzz P0 w `tests/lua/security/test_render.lua`
- zrobione: dodano `tools/audit/mutation_report.py`
- zrobione: dodano generator `tools/audit/gen_lua_contract_tests.py` (generuje `tests/lua/unit/test_lua_contract_generated_unit.lua`)
- zrobione: dodano `tests/rust/stress/long_load_tests.rs` za feature `long-load-tests` i wpisano feature do `Cargo.toml`

## Faza 7 - Stress i wydajnosc
- Dodac brakujace stress testy z rozszerzonego planu (graphics pipeline, duze compute/pathfind/dataframe/serial, multithread).
- Ujednolicic raportowanie [PERF] i automatyczne podsumowanie trendow.
- Dodac progi regresji wydajnosci i egzekwowac je w CI.

Status:
- zrobione: dodano gate `tools/audit/perf_regression_gate.py` (stress coverage + score regression)
- zrobione: baseline perf zapisany do `logs/data/perf_baseline.json`
- zrobione: integracja gate perf w workflow CI

## Faza 8 - CI i operacjonalizacja
- Dodac workflow CI uruchamiajacy analytics i publikujacy artefakty raportu.
- Dodac obsluge --html w tools/audit/test_analytics.py i domknac dashboard HTML.
- Wlaczyc pelna integracje gate'ow coverage/golden/perf w CI.
- Rozszerzyc CI matrix cross-platform zgodnie z priorytetem desktop.

Status:
- zrobione: workflow `test-analytics` uruchamia quality gates + analytics + upload artefaktow
- zrobione: `--html` w `tools/audit/test_analytics.py` + generacja `logs/reports/test_analytics.html`
- zrobione: CI matrix desktop (`windows-latest`, `ubuntu-latest`)
- zrobione: coverage + evidence/golden + stress/perf raport w pipeline

## Faza 9 - Utrzymanie roadmapy
- Po pelnym przebiegu quality gate zaktualizowac metryki sukcesu w roadmapie.
- Uzupelnic dokumentacje analytics o finalny format raportu po wdrozeniu HTML.

Status:
- zrobione: roadmapa zaktualizowana o statusy faz 4-7 i 9
- zrobione: docs testowe i workflow zsynchronizowane z nowymi gate'ami (contract/mutation/perf)
