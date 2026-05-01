# Propozycja redukcji agentów i skilli CAG

Data: 2026-04-30
Status: propozycja, bez zmian w live `.github/agents/`

## Cel

Zredukować obecną warstwę CAG z 27 agentów do 12 agentów:

- 1 enabler: `Manager`, który tylko routuje, pilnuje faz i odbiera wynik.
- 11 doerów, którzy wykonują pracę.

Docelowo warstwa ma mieć 48 repo-skilli. Limit maksymalny to 50. Obecnie repo ma 39 skilli, więc propozycja dodaje 9 nowych skilli opisujących realne braki w nowym modelu. Nie są to puste skille. Każdy nowy skill zmienia sposób pracy agenta.

## Zasady docelowe

- `Manager` nie implementuje i nie analizuje merytorycznie. Wybiera właściciela, dzieli fazy, wymaga handoffu i zamyka sesję.
- Każde zadanie ma jednego głównego właściciela.
- `Planner` jest oddzielny. Jego praca to planowanie, research pod plan, roadmapy, backlog i generowanie nowych ideas.
- `Architect` jest oddzielny. Jego praca to nadzór high-level nad całością, spójność z `docs/architecture/`, design decisions i problem solving.
- `Solver` nie jest osobnym agentem. To tryb pracy `Architect`: dla trudnego problemu tworzy kilka opcji, sprawdza je, wybiera jedną i robi interakcję z człowiekiem przy decyzji.
- `Developer` przejmuje wszystkie development-specialist role: Rust engine, renderer, physics, audio, assets, internal tooling i runtime services.
- `Lua-Designer` pilnuje `lurek.*` jako głównego interfejsu człowiek-silnik. Lua API jest produktem, nie tylko bindingiem.
- `Tester` łączy testy i security test thinking. Ma udowodnić zachowanie i odporność przez testy.
- `Verifier` łączy reviewer, hacker i optimizer. Ma ocenić zmianę, ryzyko, jakość, performance i final acceptance.
- `Doc-Writer` łączy functional specs i docs sync. Architect używa tych docs jako materiału do decyzji całościowych, ale ich nie utrzymuje operacyjnie.
- Skill ma być ładowany wtedy, gdy zmienia wykonanie zadania. Agent nie powinien kopiować zasad skilla do swojego pliku.

## Docelowy roster

| Rola | Typ | Zakres | Przykłady zadań |
| --- | --- | --- | --- |
| `Manager` | Enabler | Routing, fazy, handoffy, status sesji, final acceptance flow | Wybrać `Planner` do roadmapy, potem `Architect` do decyzji, potem `Developer` do implementacji; zatrzymać pracę, jeśli brakuje ownera; wymagać raportu od doera. |
| `Planner` | Doer | Plany, roadmapy, backlog, research pod plan, analiza opcji, nowe ideas | Rozbić milestone na zadania; znaleźć luki produktu; przełożyć research na roadmapę; zbudować plan migracji; wymyślić nowe systemy gry i nadać im priorytet. |
| `Architect` | Doer | High-level design, spójność całego repo, `docs/architecture/`, solver/problem solving | Sprawdzić czy nowy moduł pasuje do pięciu grup; wybrać jedną z 3 architektur; ocenić wpływ na CAG, docs i runtime; wymagać zgodności z constraints. |
| `Developer` | Doer | Cały Rust development i implementacja engine | Dodać subsystem w `src/`; naprawić renderer; zmienić physics; dodać asset loader; naprawić audio; zrobić refactor modułu zgodnie z architekturą. |
| `Lua-Designer` | Doer | Publiczne `lurek.*`, Lua API, Lua-Rust bridge, ergonomia API, callback shape | Zaprojektować `lurek.physics.*`; zmienić nazwy metod; ustalić argumenty callbacków; pilnować, żeby API było spójne dla twórcy gry. |
| `Content-Maker` | Doer | `content/examples/`, `content/games/`, `library/`, Lua gameplay scripts, layouts, HTML HUD/UI content | Dodać demo; napisać przykład API; stworzyć library module; zrobić gameplay script; poprawić HUD lub layout. |
| `Extension-Engineer` | Doer | `extensions/vscode/`, developer UX, panels, commands, generated data sync | Dodać komendę VS Code; poprawić hover/completion pipeline; zsynchronizować extension z docs API; dodać panel narzędziowy. |
| `Build-Engineer` | Doer | Cargo profiles, tasks, packaging, dist scripts, CI/CD, GitHub workflow, cross-platform build details | Naprawić release build; zmienić profile Cargo; dodać task; poprawić GitHub Actions; przygotować dist package. |
| `Tester` | Doer | Rust tests, Lua tests, test harness, coverage placement, security test cases, negative paths | Napisać Lua-first coverage; przenieść Rust duplicate coverage; dodać fuzz-like negative tests; sprawdzić sandbox; zbudować repro test. |
| `Verifier` | Doer | Review, adversarial review, performance verification, risk, final quality gate | Zrobić code review; sprawdzić regresje; ocenić performance ryzyko; znaleźć brakujące testy; zaakceptować albo odrzucić zmianę. |
| `Doc-Writer` | Doer | Functional specs, docs, API docs sync, handbook, wiki, changelog policy | Zaktualizować `docs/specs/`; zsynchronizować docs po zmianie API; poprawić handbook; opisać feature; utrzymać changelog. |
| `CAG-Architect` | Doer | `.github` agents, skills, prompts, system prompt, validators, retrieval support | Zmienić agent graph; naprawić CAG validation; dodać skill; poprawić prompt; utrzymać token-economy rules. |

## Najważniejsza różnica: Planner vs Architect

`Planner` pracuje na pytaniu: co powinniśmy zrobić i w jakiej kolejności?

Typowy output `Planner`:

- roadmapa,
- backlog,
- plan migracji,
- lista acceptance gates,
- research summary pod decyzję,
- lista nowych ideas z priorytetem.

`Architect` pracuje na pytaniu: czy rozwiązanie jest spójne z całym systemem i jak powinno być zaprojektowane?

Typowy output `Architect`:

- decyzja architektoniczna,
- porównanie 2-4 wariantów rozwiązania,
- wybór wariantu z trade-offami,
- mapa wpływu na moduły, docs, testy i constraints,
- wskazanie niespójności z `docs/architecture/`,
- handoff do `Developer`, `Lua-Designer`, `Doc-Writer` lub `Tester`.

Solver jest trybem `Architect`, nie osobnym agentem. Gdy problem jest niejasny lub strategiczny, `Architect` robi solver flow:

1. Definiuje problem i constraints.
2. Tworzy kilka opcji rozwiązania.
3. Sprawdza każdą opcję wobec `docs/architecture/` i repo constraints.
4. Pokazuje trade-offy człowiekowi, jeśli wybór nie jest oczywisty.
5. Wybiera jedną opcję i tworzy handoff do wykonawcy.

## Mapa redukcji obecnych agentów

| Obecny agent | Docelowa rola | Uzasadnienie |
| --- | --- | --- |
| `Manager` | `Manager` | Zostaje jedynym routerem i enablerem. |
| `Planner` | `Planner` | Główna rola planów, roadmap i backlogu. |
| `Research` | `Planner` | Research jest materiałem do planu, roadmapy albo ideas. |
| `Analyst` | `Planner` | Analiza danych i sygnałów zwykle kończy się planem lub zadaniami. |
| `Discovery-Lead` | `Planner` | Opportunity discovery i nowe ideas są częścią planowania. |
| `Architect` | `Architect` | Zostaje jako osobny high-level owner spójności systemu. |
| `Solver` | `Architect` | Solver jest trybem problem solving w Architect. |
| `Developer` | `Developer` | Główny wykonawca kodu Rust. |
| `Renderer` | `Developer` | Renderer to development specjalizacja, nie osobny agent. |
| `Physicist` | `Developer` | Physics implementation wchodzi do Development. |
| `Audio-Eng` | `Developer` | Audio implementation wchodzi do Development. |
| `Configurator` | `Developer` / `Content-Maker` / `Build-Engineer` | Engine config do Developer, example/game config do Content-Maker, build config do Build-Engineer. |
| `Lua-Designer` | `Lua-Designer` | Zostaje osobny, bo Lua API jest głównym interfejsem dla człowieka. |
| `Content-Maker` | `Content-Maker` | Zostaje ownerem contentu. |
| `Player` | `Content-Maker` | Gameplay scripts, examples i demos są content work. |
| `Extension-Engineer` | `Extension-Engineer` | Zostaje osobny, bo VS Code extension jest opt-in dev layer. |
| `Build-Engineer` | `Build-Engineer` | Zostaje ownerem build/release/CI. |
| `Tester` | `Tester` | Zostaje i przejmuje część security przez testy i negative paths. |
| `Security` | `Tester` / `Verifier` | Security test cases idą do Tester; security review i risk idą do Verifier. |
| `Reviewer` | `Verifier` | Review jest final verification. |
| `Hacker` | `Verifier` | Adversarial probing jest częścią verification. |
| `Optimizer` | `Verifier` / `Developer` | Measurement i performance gate do Verifier; fix implementation do Developer. |
| `Doc-Writer` | `Doc-Writer` | Zostaje ownerem docs. |
| `Spec-Owner` | `Doc-Writer` | Functional specs i docs sync są jednym strumieniem. |
| `CAG-Architect` | `CAG-Architect` | Zostaje ownerem `.github` CAG. |
| `RAG-Architect` | `CAG-Architect` | Retrieval architecture wspiera CAG i agent support. |

## Skill architecture

Target: 40 repo-owned skills. Hard cap: 50.

Obecny stan: 39 repo-skilli. Propozycja: zachować wszystkie 39 i dodać tylko 1 nowy skill. Daje to 40 skilli. To jest lepsze niż sztuczne dochodzenie do 48, bo nowy roster 12 agentów nie potrzebuje aż tylu nowych bytów.

Reguły przypisania:

- Agent ma zwykle 1-3 primary skills i 2-5 secondary skills.
- Primary skill definiuje główny tryb pracy agenta.
- Secondary skill jest dopuszczalny tylko, jeśli agent realnie używa go przy swoim typowym zadaniu.
- Secondary skills mogą się pokrywać między agentami.
- Nie dodawać Verifier/Reviewer jako secondary do agentów, którzy projektują lub implementują. Verification jest osobna faza, nie skill pomocniczy Lua API albo Developer.
- Jeśli agent potrzebuje review, oddaje pracę do `Verifier`, zamiast traktować review jako własny skill pomocniczy.
- Nie dodawać skilla tylko po to, żeby dojść do 50. Ten model celuje w 40, bo tylko jedna luka naprawdę wymaga nowego skilla.

## Existing skills

Obecne 39 repo-skilli zostają. Ich naturalne klastry są takie:

| Cluster | Existing skills |
| --- | --- |
| CAG/routing | `agent-routing`, `cag-workflow`, `tools-cag-validation`, `retrieval-architecture` |
| Planning/research | `roadmap-planning`, `opportunity-discovery`, `analytics`, `github-workflow` |
| Architecture | `module-architecture`, `enterprise-architecture`, `togaf` |
| Rust engine | `rust-coding`, `error-handling`, `dev-debugging`, `logging`, `cross-platform` |
| Runtime subsystems | `asset-pipeline`, `gpu-programming`, `visual-effects`, `performance-profiling`, `game-ai`, `threading` |
| Lua/API | `lua-api-design`, `lua-rust-bridge`, `lua-runtime`, `lua-scripting` |
| Content | `examples-management`, `demo-creation`, `library-authoring`, `html-css`, `ui-layout` |
| Build/release | `build-system`, `ci-cd-pipeline`, `quality-pipeline` |
| Tests/review/docs | `testing-rust`, `module-audit`, `documentation`, `agent-md`, `vscode-extension` |

## Missing skill shape

Po ponownym przejrzeniu istniejących skilli tylko jedna luka naprawdę wymaga nowego skilla:

| Missing shape | Why existing skills are not enough | New skill |
| --- | --- | --- |
| Solver flow dla `Architect` | `enterprise-architecture` i `module-architecture` opisują architekturę, ale nie wymuszają trybu pracy: zdefiniuj problem, zbuduj kilka opcji, sprawdź je i wybierz jedną z udziałem człowieka. | `solution-options` |

Pozostałe potrzeby da się pokryć istniejącymi skillami:

- planning + research + analiza: `roadmap-planning` + `opportunity-discovery` + `analytics`
- architecture governance: `enterprise-architecture` + `module-architecture`
- functional specs: `documentation` + `agent-md`
- security testing: `testing-rust` + `error-handling` + właściwy owner `Tester`
- final verification: `module-audit` + `performance-profiling` + właściwy owner `Verifier`
- human-facing Lua API: `lua-api-design` + `lua-rust-bridge` + `lua-runtime`

## New skill to add

| Skill | Primary owner | Secondary users | Load when |
| --- | --- | --- | --- |
| `solution-options` | `Architect` | `Planner`, `Manager` | Problem solving high level, 2-4 options, trade-offs, elimination, human decision point, final choice and handoff. |

Po dodaniu tego jednego nowego skilla katalog ma 40:

`agent-md`, `agent-routing`, `analytics`, `asset-pipeline`, `build-system`, `cag-workflow`, `ci-cd-pipeline`, `cross-platform`, `demo-creation`, `dev-debugging`, `documentation`, `enterprise-architecture`, `error-handling`, `examples-management`, `game-ai`, `github-workflow`, `gpu-programming`, `html-css`, `library-authoring`, `logging`, `lua-api-design`, `lua-rust-bridge`, `lua-runtime`, `lua-scripting`, `module-architecture`, `module-audit`, `opportunity-discovery`, `performance-profiling`, `quality-pipeline`, `retrieval-architecture`, `roadmap-planning`, `rust-coding`, `solution-options`, `testing-rust`, `threading`, `togaf`, `tools-cag-validation`, `ui-layout`, `visual-effects`, `vscode-extension`.

## Agent skill bundles

| Agent | Primary skills | Secondary skills | Why |
| --- | --- | --- | --- |
| `Manager` | `agent-routing` | `quality-pipeline`, `roadmap-planning`, `solution-options` | Manager routes, may require a plan, may require solver work from Architect, and uses quality gates before close-out. It does not own implementation skills. |
| `Planner` | `roadmap-planning`, `opportunity-discovery`, `analytics` | `github-workflow`, `documentation`, `enterprise-architecture` | Planner researches, analyzes, creates plans, maps gaps, and turns ideas into ordered work. |
| `Architect` | `solution-options`, `module-architecture`, `enterprise-architecture` | `documentation`, `agent-md`, `togaf`, `roadmap-planning` | Architect stays separate and is also the solver. It owns high-level coherence and option selection, not implementation or verification. |
| `Developer` | `rust-coding`, `error-handling`, `dev-debugging` | `module-architecture`, `asset-pipeline`, `gpu-programming`, `lua-rust-bridge`, `performance-profiling` | Developer writes Rust engine code. Extra subsystem skills are loaded only when that subsystem is touched. |
| `Lua-Designer` | `lua-api-design`, `lua-rust-bridge`, `lua-runtime` | `error-handling`, `documentation`, `threading` | Lua-Designer owns API shape and bridge semantics. No Verifier skill here; review is a separate phase. |
| `Content-Maker` | `lua-scripting`, `examples-management`, `demo-creation` | `library-authoring`, `html-css`, `ui-layout`, `documentation` | Content-Maker creates runnable user-facing content and examples. |
| `Extension-Engineer` | `vscode-extension` | `html-css`, `ui-layout`, `build-system`, `lua-api-design`, `documentation` | Extension work is narrow; it only borrows UI/build/API-doc context when needed. |
| `Build-Engineer` | `build-system`, `ci-cd-pipeline`, `quality-pipeline` | `cross-platform`, `github-workflow`, `tools-cag-validation`, `documentation` | Build owns local/release/CI pipelines and validation tasks. |
| `Tester` | `testing-rust`, `quality-pipeline` | `lua-rust-bridge`, `lua-api-design`, `asset-pipeline`, `error-handling` | Tester writes coverage, including negative and hostile tests, using existing testing skills. |
| `Verifier` | `module-audit`, `performance-profiling` | `testing-rust`, `error-handling`, `quality-pipeline`, `dev-debugging` | Verifier reviews finished work, checks risk and performance, and decides if evidence is strong enough. |
| `Doc-Writer` | `documentation`, `agent-md` | `lua-api-design`, `roadmap-planning`, `enterprise-architecture`, `github-workflow` | Doc-Writer owns specs/docs sync using existing docs skills instead of a separate functional-spec skill. |
| `CAG-Architect` | `cag-workflow`, `tools-cag-validation`, `agent-routing` | `retrieval-architecture`, `documentation`, `module-architecture`, `enterprise-architecture` | CAG-Architect owns agent graph, skills, prompts, validator contracts, and retrieval support. |

## Skill-to-agent ownership table

| Skill | Primary agent | Secondary agents |
| --- | --- | --- |
| `agent-md` | `Doc-Writer` | `CAG-Architect` |
| `agent-routing` | `Manager` | `CAG-Architect` |
| `analytics` | `Planner` | `Verifier` |
| `asset-pipeline` | `Developer` | `Tester`, `Content-Maker` |
| `build-system` | `Build-Engineer` | `Developer`, `Extension-Engineer` |
| `cag-workflow` | `CAG-Architect` | `Manager` |
| `ci-cd-pipeline` | `Build-Engineer` | `Verifier` |
| `cross-platform` | `Build-Engineer` | `Developer` |
| `demo-creation` | `Content-Maker` | `Tester` |
| `dev-debugging` | `Developer` | `Tester` |
| `documentation` | `Doc-Writer` | `Planner`, `Architect`, `Content-Maker`, `Extension-Engineer`, `CAG-Architect` |
| `enterprise-architecture` | `Architect` | `Planner`, `Doc-Writer` |
| `error-handling` | `Developer` | `Lua-Designer`, `Tester`, `Verifier` |
| `examples-management` | `Content-Maker` | `Doc-Writer`, `Tester` |
| `game-ai` | `Developer` | `Content-Maker`, `Planner` |
| `github-workflow` | `Planner` | `Build-Engineer` |
| `gpu-programming` | `Developer` | `Verifier` |
| `html-css` | `Content-Maker` | `Extension-Engineer` |
| `library-authoring` | `Content-Maker` | `Doc-Writer`, `Tester` |
| `logging` | `Developer` | `Verifier`, `Tester` |
| `lua-api-design` | `Lua-Designer` | `Tester`, `Doc-Writer`, `Extension-Engineer` |
| `lua-rust-bridge` | `Lua-Designer` | `Developer`, `Tester` |
| `lua-runtime` | `Lua-Designer` | `Developer` |
| `lua-scripting` | `Content-Maker` | `Lua-Designer`, `Tester` |
| `module-architecture` | `Architect` | `Developer`, `CAG-Architect` |
| `module-audit` | `Verifier` | `Doc-Writer` |
| `opportunity-discovery` | `Planner` | `Architect` |
| `performance-profiling` | `Developer` | `Verifier` |
| `quality-pipeline` | `Build-Engineer` | `Manager`, `Tester`, `Verifier` |
| `retrieval-architecture` | `CAG-Architect` | `Architect` |
| `roadmap-planning` | `Planner` | `Doc-Writer`, `Architect` |
| `rust-coding` | `Developer` | `Tester`, `Verifier` |
| `solution-options` | `Architect` | `Planner`, `Manager` |
| `testing-rust` | `Tester` | `Verifier` |
| `threading` | `Lua-Designer` | `Developer`, `Tester` |
| `togaf` | `Architect` | `Planner` |
| `tools-cag-validation` | `CAG-Architect` | `Build-Engineer`, `Manager` |
| `ui-layout` | `Content-Maker` | `Extension-Engineer` |
| `visual-effects` | `Developer` | `Content-Maker` |
| `vscode-extension` | `Extension-Engineer` | `CAG-Architect` |

## Przykłady routingu

| Request | Primary agent | Notes |
| --- | --- | --- |
| „Zrób roadmapę AI systemów na 3 milestone” | `Planner` | Research i ideas są częścią planu. Architect nie jest potrzebny, jeśli nie ma decyzji systemowej. |
| „Który model pluginów wybrać?” | `Architect` | Architect robi solver flow: kilka opcji, trade-offy, wybór, potem handoff. |
| „Dodaj physics API do Lua” | `Lua-Designer` -> `Developer` -> `Tester` | Lua-Designer projektuje interface, Developer implementuje, Tester pokrywa `lurek.*`. |
| „Napraw crash w rendererze” | `Developer` | Jeśli crash jest trudny, Developer może użyć `dev-debugging`; Verifier dopiero na review. |
| „Sprawdź czy PR jest bezpieczny i szybki” | `Verifier` | Review, adversarial thinking i performance gate w jednym miejscu. |
| „Napisz testy path traversal dla filesystem” | `Tester` | Security jako test writing należy do Tester. |
| „Zaktualizuj docs/specs po zmianie API” | `Doc-Writer` | Functional specs i docs sync są jednym ownerem. |
| „Zmień agent roster i walidator” | `CAG-Architect` | To praca CAG layer. |
| „Czy nowy renderer łamie docs/architecture?” | `Architect` | High-level coherence z architecture docs. |
| „Zrób demo pokazujące audio mixer” | `Content-Maker` | Demo, examples i Lua content. |

## Agent handoff contract

Minimalny handoff od każdego doera:

- co zostało ustalone lub zrobione,
- jakie pliki lub obszary są dotknięte,
- jakie testy lub walidacje są wymagane,
- jakie ryzyko zostało,
- do którego agenta praca powinna przejść dalej.

Przykłady:

- `Planner` -> `Architect`: „Roadmap wymaga decyzji, czy networking ma być runtime-only czy plugin-facing.”
- `Architect` -> `Developer`: „Wybrana opcja B. Implementuj w `src/network/`, bez platform SDK w core binary.”
- `Lua-Designer` -> `Developer`: „API ma być `lurek.thread.newChannel(name)` i zwraca userdata z metodami X/Y.”
- `Developer` -> `Tester`: „Zmiana dotyka `src/lua_api/window_api.rs`; potrzebne testy Lua dla argumentów invalid.”
- `Tester` -> `Verifier`: „Testy przechodzą; pozostaje ryzyko performance w batch renderingu.”
- `Verifier` -> `Manager`: „Accept z jednym follow-upem docs.”

## Skills to merge if cap becomes tight

Jeśli katalog urośnie powyżej 50, scalać w tej kolejności:

| Merge target | Absorb | Reason |
| --- | --- | --- |
| `module-audit` | `quality-pipeline` | Jeśli audit stanie się tylko częścią jakościowego gate. |
| `enterprise-architecture` | `module-architecture` | Jeśli high-level i module-level architecture przestaną wymagać osobnych workflow. |
| `demo-creation` | `examples-management` | Jeśli demo i example workflow zbiegną się w jeden content flow. |
| `visual-effects` | `gpu-programming` | Jeśli efekty zostaną tylko podzbiorem ogólnej pracy GPU. |

## Implementation plan

1. Update `.github/agents/README.md` with the 12-agent roster, role family map, and routing examples.
2. Add the single proposed skill `solution-options` under `.github/skills/` with short trigger-focused description.
3. Replace or rename agent files so live names match the roster in one migration pass.
4. Update validator known-agent lists and skill references.
5. Update prompts that reference removed agents.
6. Update `docs/architecture/cag-system.md` if the architecture docs describe agent roster or handoff rules.
7. Run focused CAG validation for changed files.
8. Run full `python tools/validate/cag_validate.py`.
9. Run `python tools/audit/cag_link_check.py --strict`.
10. Run `python tools/audit/cag_coverage.py` and `python tools/audit/cag_persona_matrix.py` if agent graph or persona coverage changes.
11. Update `docs/CHANGELOG.md` when applying the live policy change.
12. Record phase output in `work/{session}/logs/agent_log.jsonl`.

## Known baseline state

The baseline command `python tools/validate/cag_validate.py --baseline` currently reports existing E105 errors for agent tool references such as `execute/runInTerminal`, `read/readFile`, and related paths. This proposal does not fix those errors. The live migration should either fix the validator tool allow-list or update the agent tool references before expecting a clean CAG pass.

## Recommendation

Use this 12-agent model:

`Manager`, `Planner`, `Architect`, `Developer`, `Lua-Designer`, `Content-Maker`, `Extension-Engineer`, `Build-Engineer`, `Tester`, `Verifier`, `Doc-Writer`, `CAG-Architect`.

This keeps the main human workflows separate:

- planning and analysis,
- high-level architecture and solution design,
- implementation,
- Lua API as human interface,
- content creation,
- extension work,
- build/release,
- test writing including security tests,
- verification and review,
- docs/specs sync,
- CAG governance.

It also keeps the skill catalog under control: 48 planned repo-skills, with 2 reserved slots before the hard cap of 50.
