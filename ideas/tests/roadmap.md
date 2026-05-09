
# Test Roadmap

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

## Faza 5 - Evidence, golden i visual regression
- Dodac runtime smoke dla: light, particle, postfx, audio w tests/rust/ext.
- Dodac screenshot i pixel porownania dla przypadkow, ktore nie sa wiarygodne headless.
- Dokonczyc visual regression pipeline (baseline, diff, tolerancje).
- Ustalic i opisac finalny workflow aktualizacji baseline dla goldenow wizualnych.
- Dodac brakujace goldeny z obszaru visual/effects/spine albo jawnie zamknac je jako out-of-scope.
- Domknac coverage evidence dla obszarow wysokiego ryzyka (light, postfx, particle) i ustawic minimalny gate CI.
- Uzupelnic smoke testy dem i mapowanie demo->test.

## Faza 6 - Metody zaawansowane
- Dodac brakujace property-based testy dla: data, serial, image, physics.
- Rozszerzyc fuzzing API w tests/lua/security (nil/type/extreme) i ustalic zestaw modulow P0.
- Wdrozyc mutation testing (cargo-mutants) dla modulow priorytetowych i raport przezytych mutantow.
- Dodac generator contract-testow na bazie lua_api_data.json i uruchamiac je okresowo.
- Dodac dedykowane load tests (dlugie scenariusze) za feature flaga.

## Faza 7 - Stress i wydajnosc
- Dodac brakujace stress testy z rozszerzonego planu (graphics pipeline, duze compute/pathfind/dataframe/serial, multithread).
- Ujednolicic raportowanie [PERF] i automatyczne podsumowanie trendow.
- Dodac progi regresji wydajnosci i egzekwowac je w CI.

## Faza 8 - CI i operacjonalizacja
- Dodac workflow CI uruchamiajacy analytics i publikujacy artefakty raportu.
- Dodac obsluge --html w tools/audit/test_analytics.py i domknac dashboard HTML.
- Wlaczyc pelna integracje gate'ow coverage/golden/perf w CI.
- Rozszerzyc CI matrix cross-platform zgodnie z priorytetem desktop.

## Faza 9 - Utrzymanie roadmapy
- Po pelnym przebiegu quality gate zaktualizowac metryki sukcesu w roadmapie.
- Uzupelnic dokumentacje analytics o finalny format raportu po wdrozeniu HTML.
