# P9 Alignment Execution Plan (2026-05-06)

## Cel dokumentu
Ten plan przekłada wnioski z audytu modułów na gotowy backlog implementacyjny.
Zakres obejmuje moduły:
- image
- light
- minimap
- particle
- effect
- tilemap
- province
- graph
- globe
- physics
- render

Plan jest przygotowany pod natychmiastową realizację, z jednoznacznymi bramkami zakończenia.

## Definicja sukcesu
Repo po realizacji planu ma spełnić jednocześnie:
1. Brak konfliktu z założeniem A-03 (silnik 2D only) i Twoją zasadą: brak minimapy 2.5D.
2. Jednoznaczne granice odpowiedzialności między image/province/tilemap/globe/graph/render.
3. Spójność kodu, speców, przykładów i changeloga.
4. Zielony quality gate dla zmienianych modułów.

## Priorytety
- P0: Blokery architektoniczne i konflikty domenowe.
- P1: Uporządkowanie odpowiedzialności modułów.
- P2: Synchronizacja spec/API/testy/dokumentacja.
- P3: Utwardzenie quality pipeline i reguł audytu.

## Faza 0 — Baseline i zamrożenie zakresu
Owner: planner
Done When: Istnieje zatwierdzony snapshot bazowy z wynikami: python tools/audit/audit_module.py image light minimap particle effect tilemap province graph globe physics render oraz z listą plików, które będą zmieniane.
Inputs:
- logs/quality/*.md
- docs/architecture/philosophy.md
- docs/specs/*.md (objęte zakresem)
Produces:
- work/<session>/reports/module_alignment_baseline.md
Poza zakresem: brak zmian w src, docs/specs i tests.

## Faza 1 — Kontrakt granic modułów (target architecture)
Owner: architect
Done When: Istnieje zaakceptowany dokument granic modułów oraz decyzji domenowych; uruchomione i zielone: python tools/gen_all_docs.py.
Inputs:
- docs/architecture/philosophy.md
- docs/specs/image.md
- docs/specs/minimap.md
- docs/specs/tilemap.md
- docs/specs/province.md
- docs/specs/graph.md
- docs/specs/globe.md
- docs/specs/render.md
Produces:
- work/<session>/reports/module_boundary_contract.md
Poza zakresem: brak implementacji kodu Rust/Lua.

### Decyzje obowiązkowe w Fazie 1
1. Raycaster nie utrzymuje własnego systemu minimapy publicznej.
2. image nie utrzymuje docelowo logiki domenowej province (poza ewentualnym niskopoziomowym raster index helperem).
3. graph ma być modułem abstrakcyjnym bez zależności runtime/render.
4. tilemap polygon overlay ma mieć jasno ograniczony zakres i brak wejścia w domenę province.
5. render::obj_loader ma być jawnie opisany jako projekcja do 2D (nie pipeline 3D).


$$$

raycaster ma nie miec minimapy, minimapa to oddzielny modul ktora jest swoistym helperem renderu. INtegrcja pomiedzy modulami ma byc na poziomie LUA przez gracza. Minimapa ma ladowac dowolny zestaw danych do pokazania na minimapie, ale nie ma byc zintegrowana z raycasterem. Raycaster moze miec wewnetrzna logike do obliczania pozycji gracza i widocznych obiektow, ale nie ma byc publicznego API do minimapy. To pozwala na czystsza separacje odpowiedzialnosci i unika konfliktu z A-03. Gracz moze uzyc danych z raycastera (np. pozycji gracza) do aktualizacji minimapy, ale to jest jego decyzja, a nie narzucona przez silnik.

Province zajmuje sie swoim renderowaniem, i logika a image ma sie zajac loadowaniem grafiki zeby zbudowac mape. Integracja ma byc na poziomie LUA przez gracza, dwa moduly maja byc neizalezne. Innym sposobem dostarczeni danych do provice moduly jest procgen ktory moze taka mape wygenroawac bez ladowania z image i konwersji. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz moze uzyc image do ladowania tekstur i danych, a province do zarzadzania obszarami i interakcjami, ale to jest jego decyzja, a nie narzucona przez silnik. Province ma byc systemem obszarow polygonowych, a nie tilemapa, i ma byc odpowiedzialny za logike tych obszarow, a nie za renderowanie.

Graph ma byc modulem abstrakcyjnym, bez zaleznosci od runtime czy render. Moze byc w graphie logika do draw commans czy logowania runtime jesli gracz nie uzywac innych modulow do tego, ale to jest na zasadzie default rendering. Graph to tylko model danych i algorytmy, a adaptery do renderowania czy logowania sa poza nim i ma byc integracja na poziomie Lua. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz nie musi uzywac province ani globe ani niczego innego do wizualizcji graph.

TIlemap to tilemap czytaj pola, kwadraty, hexy etc. Wszystko sie dzieje na siatce 2D. Moze byc polygon overlay cos jak Tiled edytor ma polygon do rysowania obszaru. Wiec to jest raczej po to, a nie duplikacji provinces. Province to jest system obszarow polygonowych, ale nie jest to tilemapa. Tilemap ma byc tylko do renderowania i obliczen na siatce, a province ma byc do zarzadzania obszarami i ich interakcjami. Integracja ma byc na poziomie Lua przez gracza, dwa moduly maja byc neizalezne. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz moze uzyc tilemapy do renderowania, a province do logiki, ale to jest jego decyzja, a nie narzucona przez silnik. Ttilemap ma tiles a province ma province / polygons. To ze istnieje polygon w tilemap to tylko helper do logiki, np event sie wydarzy jak cos wpadnei w taki polygon-> nazwijmy to moze jako Tilemap area.

Render i 3D. Gra nie jest 3D. wszsytko jest 2D, wszystkie draw commands sa 2D. Obj loader moze istniec, ale jego output to jest 2D projection, a nie 3D pipeline. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz moze uzyc obj loadera do wczytania modelu i renderowania go jako sprite czy cos, ale to jest jego decyzja, a nie narzucona przez silnik. Raycaster to jest wizaulizacja gry 2D ktora gracz zbudowal do wersji 2.5 D z perspektywa, ale to jest tylko efekt wizualny, a nie zmiana w podstawowej architekturze silnika. Nie ma fizyki 3D, cala fizyka jest 2D, wszystkie interakcje sa 2D, a render jest 2D. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz moze uzyc raycastera do stworzenia efektu 2.5D, ale to jest jego decyzja, a nie narzucona przez silnik. Obiekty w w wersji raycaster to sa nadal obiekty 2D, tylko renderowane z efektem perspektywy. Nie ma zadnych 3D modelow, zadnej 3D fizyki, zadnych 3D interakcji. To jest tylko efekt wizualny, a nie zmiana w podstawowej architekturze silnika.


Light 2D i 2.5D

Swiatlo w 2D czyli light modul i occulers dzialaja normalnie w 2D, mozna tego uzyc na tilemapie tzn swiatlo jest liczone per tile, jakies poziomy ze tile je blokuje, kolory swiatla etc. Patrz  gra ufo xcom defense 1994, wiec modul swiatla poza normalnym swiatlem continues i occulers i efekty swietlnie, ma miec tez modyl do obliczen swiatla per tile, ktory np jest w Dungeon Crawler demo i jest czesciowo w Raytracing. Tam swiatlo jest liczone na 2D wszystko, ma np sile 10 i fallout 1 na pole i kolor RGB i takie swiatlo koloryzuje cale pole na kolor / jasnosc etc. Dodatkowo jest tam ambient ight czyli globalne jakby z nieba. Poziom swiatla jest liczony w tym przypadku jako suma swiatem i cieni (per tile) i to jest w module LIGHT, a raycaster moze to tylko renderowac jako koloryzowanie textu w tym tile konkretnym i obiektow ktore tu stoja, i to robi racyaster, ale modul light zarzadza swiatlem plynnym jak i swiatlem per tile, a raycaster tylko renderuje to co light mu powie. To pozwala na czystsza separacje i unika konfliktu z A-03. Gracz moze uzyc modułu light do zarządzania światłem, a raycaster do renderowania tego światła, ale to jest jego decyzja, a nie narzucona przez silnik.

minimapa moze miec takie cos jak light ovevlay ktory dodatkowo modyfikuje kolory na kazdym pixelu minimapy. Minimapa moze tez dostac input recznie, albo z tilemap albo z province.

$$$

## Faza 2 — Usunięcie konfliktu minimapy 2.5D
Owner: Developer
Done When: Nie ma publicznej ścieżki minimapy w raycaster API i spec; testy przechodzą: cargo test --test lua_tests -- --nocapture oraz cargo clippy -- -D warnings.
Inputs:
- src/raycaster/minimap_overlay.rs
- src/lua_api/raycaster_api.rs
- docs/specs/raycaster.md
- content/examples/* (jeśli używa raycaster minimap)
Produces:
- Refaktor raycaster minimap do statusu internal helper albo pełne usunięcie ścieżki publicznej
- Aktualizacja spec i changelog
Poza zakresem: brak zmian funkcjonalnych w głównym renderingu raycastera.

### Kroki implementacyjne
1. Oznaczyć aktualny zakres minimap_overlay jako internal-only albo usunąć API wejścia.
2. Usunąć/zmienić rejestrację Lua metod minimapowych w raycaster_api.
3. Zaktualizować docs/specs/raycaster.md i przykłady.
4. Dodać test regresji: brak publicznej funkcji minimapy w lurek.raycaster.*.

$$$
minimap module ma byc rozszerzony o opcje ktora sa wykorzystywane w raycast np postacie maja kierunek patrzenia, overlay swiatla liczonego na poziomie tiles (obliczenia w light, wynik overlay i draw command w minimap)
$$$

## Faza 3 — Rozdzielenie image vs province
Owner: Developer
Done When: ProvinceRegistry nie wymaga image::ProvinceGrid jako domenowego centrum; warstwa danych province jest własnością province; cargo test i cargo clippy przechodzą.
Inputs:
- src/image/province_grid.rs
- src/province/registry.rs
- src/province/*
- docs/specs/image.md
- docs/specs/province.md
Produces:
- Ustalony kontrakt: image helper low-level albo migracja pełna do province
- Zredukowany overlap API i odpowiedzialności
Poza zakresem: brak przebudowy pipeline render province poza potrzebnym minimum.

### Kroki implementacyjne
1. Wydzielić model domenowy province geometry do src/province (jeśli pozostaje w image, to tylko adapter/format helper).
2. Przenieść lub zawęzić operacje adjacency/spans/border_segments.
3. Zapewnić kompatybilność istniejących punktów wejścia Lua przez adapter/warstwę przejściową.
4. Dodać testy jednostkowe na zgodność wyników przed/po migracji.

$$$

image ma zawierac wszystko zwiazane z odczytem , zapise i procesowaniem w pamieci grafiki w image data, wiec w jesli czytamy do province mape to przez image, albo do globe to przez image (pamietajmy o odpowiednim rzutowaniu mapy 2D na globe -> so rozne rzutowania i odczyt tego jest w image, ale interpretacja jest w globe)

integracja systeow ma byc przez gracza na poziomie LUA pomiedzy province a image, bo gracz moze stwozyc inpu recznie lub za pomoca procgen i wtedy mamy province map proceduralnie

$$$

## Faza 4 — Uporządkowanie graph jako Foundations
Owner: Developer
Done When: src/graph nie importuje runtime ani render; debug wizualizacja jest przeniesiona do warstwy wyższej; cargo test i cargo clippy przechodzą.
Inputs:
- src/graph/core.rs
- src/graph/render.rs
- src/graph/simulation.rs
- docs/specs/graph.md
Produces:
- Czysty graph domain module
- Ewentualny adapter debug render poza graph
Poza zakresem: brak zmian semantyki algorytmów flow/pathfinding.

### Kroki implementacyjne
1. Usunąć zależności logowania runtime z graph (zastąpić lokalnym interfejsem lub feature-gated adapterem).
2. Wyprowadzić render debug command generation poza src/graph.
3. Zachować API Lua bez regresji (lub dodać migration notes jeśli zmienia się surface).
4. Uporządkować pliki duplikatowe wskazane w spec (graph.rs, traversal.rs) zgodnie z rzeczywistym use.


$$$

$$$

## Faza 5 — Strategia jednego modelu grafowego dla province i globe
Owner: architect
Done When: Zatwierdzony plan techniczny na redukcję duplikacji ProvinceGraph (province/globe) oraz punktów styku z graph; python tools/gen_all_docs.py przechodzi.
Inputs:
- src/province/topology.rs
- src/globe/topology.rs
- src/graph/*
- docs/specs/province.md
- docs/specs/globe.md
- docs/specs/graph.md
Produces:
- work/<session>/reports/graph_unification_design.md
Poza zakresem: brak pełnej implementacji unifikacji w tej fazie.

### Wariant docelowy rekomendowany
1. graph pozostaje abstrakcyjny i niezależny.
2. province/globe utrzymują cienkie adaptery i typy domenowe, ale delegują algorytmikę tam, gdzie to możliwe.
3. Zachować własne cache tam, gdzie koszt konwersji byłby wyższy niż zysk.

## Faza 6 — Ograniczenie overlap tilemap polygon vs province
Owner: Developer
Done When: Zakres tilemap::PolygonMap jest jawnie ograniczony do overlay/render utility; brak dublowania mechanik province; cargo test i cargo clippy przechodzą.
Inputs:
- src/tilemap/polygon_map.rs
- src/tilemap/mapgen.rs
- docs/specs/tilemap.md
- docs/specs/province.md
Produces:
- Zaktualizowany kod i specy granic
Poza zakresem: brak zmian w importach TMX/LDTK niezwiązanych z overlapem.

### Kroki implementacyjne
1. Ograniczyć API PolygonMap do use-case overlay.
2. Przenieść province-like interakcje/atrybuty do province (jeśli są).
3. Dopisać notę architektoniczną o separacji responsibility.

## Faza 7 — Doprecyzowanie render::obj_loader w ramach A-03
Owner: doc-writer
Done When: Dokumentacja i komentarze kodu jednoznacznie mówią, że obj_loader kończy na projekcji do 2D i nie tworzy 3D pipeline; python tools/gen_all_docs.py przechodzi.
Inputs:
- src/render/obj_loader.rs
- docs/specs/render.md
- docs/architecture/philosophy.md
Produces:
- Zaktualizowana dokumentacja granic 2D-only
Poza zakresem: brak usuwania funkcji OBJ, jeśli nadal mają uzasadniony use-case.

## Faza 8 — Synchronizacja spec/API/example/changelog
Owner: doc-writer
Done When: Dla wszystkich objętych modułów SP-04 i W-02/W-04 z audytu są zamknięte; python tools/gen_all_docs.py przechodzi i diff jest spójny.
Inputs:
- docs/specs/{image,light,minimap,particle,effect,tilemap,province,graph,globe,physics,render}.md
- content/examples/*
- docs/CHANGELOG.md
Produces:
- Spójne specy i przykłady
- Uzupełniony changelog
Poza zakresem: brak zmian implementacji biznesowej, tylko sync artefaktów.

### Wymagania szczegółowe
1. Każda publiczna funkcja w Lua API ma wpis w spec i przykład użycia.
2. Stałe i aliasy są pokryte (np. LOD_*, CELL_*).
3. Usunąć rozjazdy typu "w spec, ale nie w przykładzie" i odwrotnie.

## Faza 9 — Naprawa realnych jakościowych błędów kodu
Owner: Developer
Done When: Zamknięte błędy typu ERROR/WARNING, które są realne i nie wynikają z false positive audytora; cargo test i cargo clippy przechodzą.
Inputs:
- logs/quality/*.md
- src/* (tylko moduły objęte planem)
Produces:
- Poprawiony kod i bindingi
Poza zakresem: brak zmian stylistycznych niezwiązanych z findings.

### Priorytetowe punkty z audytu
1. B-04: przeniesienie ciężkiej logiki z closure bindingów do src/<module>/.
2. D-06/D-08: poprawa standardu komentarzy w lua_api.
3. Q-04: redukcja niebezpiecznych unwrap tam, gdzie to realny risk.
4. T-04: epsilon dla porównań float w testach.

## Faza 10 — Korekta narzędzia audytu (false positives test files)
Owner: build-engineer
Done When: audit_module.py poprawnie rozpoznaje test_*_core_unit.lua jako ważne testy jednostkowe; test narzędzia przechodzi.
Inputs:
- tools/audit/audit_module.py
- tests/lua/unit/test_*_core_unit.lua
Produces:
- Poprawione reguły T-02 i raportowanie
Poza zakresem: brak zmian runtime engine.

## Faza 11 — Final quality gate i zamknięcie
Owner: verifier
Done When:
- cargo clippy -- -D warnings
- cargo test
- python tools/gen_all_docs.py
- python tools/audit/audit_module.py image light minimap particle effect tilemap province graph globe physics render
Wszystkie zakończone bez nowych blockerów.
Inputs:
- Wszystkie artefakty z faz 2-10
Produces:
- work/<session>/reports/module_alignment_closure.md
Poza zakresem: brak nowego scope po zamknięciu.

## Kolejność i zależności (DAG)
1. Faza 0
2. Faza 1
3. Fazy równoległe po Fazie 1: 2, 4, 7
4. Faza 3 po 1 i 2
5. Faza 6 po 1 i 3
6. Faza 5 po 3 i 4
7. Faza 8 po 2, 3, 4, 6, 7
8. Faza 9 po 2, 3, 4, 6
9. Faza 10 może iść równolegle od Fazy 0
10. Faza 11 na końcu

## Okna równoległości
- Okno A: Faza 2 + Faza 4 + Faza 7
- Okno B: Faza 8 + Faza 10 (częściowo)

## Ryzyka i pytania blokujące
1. Czy raycaster minimap_overlay ma zostać całkowicie usunięty, czy tylko internal bez Lua API?
2. Czy ProvinceGrid ma zostać zdegradowany do helpera obrazu, czy całkowicie przeniesiony do province?
3. Czy unifikacja ProvinceGraph ma być pełna (wspólna implementacja), czy częściowa (wspólny adapter + niezależne cache)?
4. Czy obj_loader zostaje jako funkcja strategicznie wspierana, czy tryb kompatybilności legacy?

## Kryteria akceptacji per obszar
1. Architektura: brak nowych naruszeń kierunku zależności modułów.
2. API: spec, przykład i binding są 1:1 zgodne.
3. Testy: brak regresji funkcjonalnych, poprawne porównania float.
4. Docs: brak driftu po gen_all_docs.

## Lista modułów i oczekiwane efekty końcowe
- image: CPU image processing i helpery obrazowe, bez ciężkiej odpowiedzialności domenowej province.
- light: 2D source/occluder zgodnie z zakresem.
- minimap: jeden canonical system minimapy, bez 2.5D minimapy raycaster.
- particle: system małych particle bez rozszerzania scope.
- effect: runtime screen/postfx, bez mieszania z file image processing.
- tilemap: rendering/obliczenia tilemap, bez niekontrolowanego wchodzenia w province domain.
- province: generyczny system obszarów polygon-like i ich interakcji/render.
- graph: abstrakcyjny model matematyczny i algorytmiczny.
- globe: interakcje na kuli, warstwy i adaptery do province/graph.
- physics: tylko 2D mechanika.
- render: centralny rendering 2D draw commands.

## Notatka wykonawcza
Ten plan jest gotowy do implementacji. Każda faza ma jednoznacznego ownera, wejścia, produkt i binarną bramkę zakończenia.
