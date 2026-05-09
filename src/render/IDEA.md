# IDEA — src/render

## Niezrobione TODO/WIP

- TODO(FEAT): anti-aliased lines/shapes (MSAA lub inna strategia AA dla wektorów).
- TODO(FEAT): GPU instancing dla dużej liczby identycznych sprite'ów/obiektów.
- TODO(FEAT): geometry/static draw caching dla niezmiennych geometrii.
- TODO(PERF): rozważyć adaptive circle LOD i dalsze ograniczenie kosztu tessellacji CPU.
- TODO(QUAL): rozbić duże pliki rendererowe na mniejsze podmoduły.
- TODO(dedup): doprecyzować odpowiedzialność `render` vs `pipeline` (nazewnictwo i zakres).
- TODO(dedup): doprecyzować granicę `render` vs `effect` dla mapowania parametrów post-fx.
- TODO(helper): wydzielić wspólne helpery shader/blend/shadow map i usunąć duplikacje w `postfx_pipeline`.
