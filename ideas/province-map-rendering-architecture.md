# Architektura Renderowania Map Prowincji (styl EU3)

## Problem

Renderowanie mapy świata z ~1500 prowincjami w stylu Europa Universalis 3:
- **Wejście**: PNG 2000×900 px, każdy unikalny kolor RGB = jedna prowincja + 2 specjalne kolory (stolice, etykiety)
- **Wyjście**: dwa tryby zoom — strategiczny (1:1 z map.png) i taktyczny (8:1 upscale = 16000×7200 logicznie)
- **Wymagania**:
  - Kolor wypełnienia per-prowincja (zmienny w runtime — tryby mapy: polityczny, teren, handel itd.)
  - **Fog of War**: per-prowincja widoczność — niewidoczne prowincje nie renderują się wcale
  - **Granice per-para**: coastal / land-land / sea-sea + override „country border" (gruba, czerwona) per para
  - **Gradient cieniujący**: piksele przy granicy prowincji ciemniejsze (~10% obwódka), środek normalny
  - **Stolice i napisy**: wyciągane z 2 specjalnych kolorów w map.png (biały=stolica, magenta=etykieta)
  - **Drogi**: linie między stolicami sąsiednich prowincji (graph-based)
  - **Dwa tryby zoom**: strategiczny (mniej detali) i taktyczny (wszystko)
  - 60 FPS na zintegrowanej GPU w 1080p
  - CPU zarezerwowane dla logiki gry — renderowanie max na GPU
  - Łatwe modowanie (zmiana mapy = podmiana PNG + CSV)

---

## Co już istnieje w silniku

| Komponent | Status | Lokalizacja |
|-----------|--------|-------------|
| Import PNG → siatka prowincji (pixel → ID) | ✅ Gotowe | `src/image/province_grid.rs` |
| Ekstrakcja span-ów (poziome segmenty per prowincja) | ✅ Gotowe | `src/province/` |
| Ekstrakcja segmentów granic | ✅ Gotowe | `src/province/` |
| Graf sąsiedztwa (adjacency) | ✅ Gotowe | `src/province/` |
| Styl per-prowincja (RGBA, terrain, border_style, fog_state, visibility_state) | ✅ Gotowe | `src/province/types.rs` |
| Renderowanie fill z viewport culling (span → rect) | ✅ Gotowe | `src/province/render.rs` |
| Renderowanie granic jako linie (per-class kolor) | ✅ Gotowe | `src/province/render.rs` |
| Stolice (wykrywanie z białych pikseli w PNG) | ✅ Gotowe | `src/province/import.rs` |
| Etykiety (wykrywanie z magenta pikseli w PNG) | ✅ Gotowe | `src/province/import.rs` |
| Marker sanitization (stolica/label → oczyszczona mapa) | ✅ Gotowe | `src/province/import.rs` |
| Fog state + visibility state per prowincja | ✅ Gotowe | `ProvinceStyle::fog_state`, `visibility_state` |
| GPU bridge (repr(C) ProvinceGpuRecord) | ✅ Gotowe | `src/province/gpu_bridge.rs` |
| Border classification (LandLand/Coast/SeaSea/Special) | ✅ Gotowe | `src/province/borders.rs` |
| `setBorderClass(a, b, class)` — per-pair override | ✅ Gotowe | `src/lua_api/province_api.rs` |
| Map modes (political/terrain/visibility) | ✅ Gotowe | `src/province/map_modes.rs` |
| Custom WGSL shader pipeline + post-process | ✅ Gotowe | `src/render/shader.rs`, `postfx_pipeline.rs` |
| Canvas (offscreen render target) | ✅ Gotowe | `src/render/canvas.rs` |
| Graph pathfinding (A*, bidirectional, graph_astar) | ✅ Gotowe | `src/pathfind/graph_nav.rs` |
| Graph data structure (nodes + edges + weights) | ✅ Gotowe | `src/graph/` |
| Demo EU2 (2000×900 × pixel_size=8) | ✅ Gotowe | `content/games/strategy/eu2/` |
| Per-pair border COLOR + THICKNESS override | ❌ Brak | — |
| Province edge gradient/shading | ❌ Brak | — |
| Road rendering (linie stolica→stolica) | ❌ Brak | — |
| Fog of War fill skip (per-province visibility toggle) | ⚠️ Pół | `visibility_state` istnieje, ale render nie skipuje |
| Dual zoom mode (strategiczny vs taktyczny) | ⚠️ Pół | `pixel_size` + `zoom` istnieją, logika trybu nie |
| GPU texture upload (R16 province ID map) | ❌ Brak | — |
| GPU storage buffer (border styles) | ❌ Brak | — |
| GPU border shader z grubością | ❌ Brak | — |
| GPU province shading (edge darkening) | ❌ Brak | — |

---

## Co NIE istnieje (do zbudowania)

1. **Per-pair border style** — kolor + grubość + flagi per para prowincji (nie per klasa)
2. **Fog of War render skip** — jeśli `visibility_state == 0`, prowincja nie renderuje fill ani border
3. **Province edge gradient** — ciemniejsza obwódka ~10% od granicy do środka
4. **Road rendering** — linie między stolicami sąsiednich prowincji (z grafu adjacency)
5. **Dual zoom mode** — strategiczny (pixel_size=1, mniej detali) vs taktyczny (pixel_size=8, wszystko)
6. **Country border override** — gruby czerwony border per-para w trybie politycznym
7. **(Opcjonalnie) GPU border shader** — jeśli CPU cost za wysoki
8. **(Opcjonalnie) GPU province shading** — gradient edge via shader

---

## Szczegółowe wymagania

### Fog of War
- Per-prowincja: `visibility_state` (u8)
  - 0 = niewidoczna (nie renderuj NIC — ani fill, ani border, ani stolica)
  - 1 = discovered (szary fill, brak detali)
  - 2+ = fully visible (normalny render)
- Granica rysuje się TYLKO jeśli OBA sąsiady są widoczne (≥ 2)
- Discovered prowincja: szary tone, bez granic, bez stolicy/nazwy
- Change w runtime: `reg:setVisibilityState(id, 0|1|2)` — istniejące API

### Granice per-para
- Domyślny styl wynika z klasyfikacji: LandLand (szary 1px), Coast (żółty 1px), SeaSea (niebieski 1px)
- Override per-para: `reg:setBorderPairStyle(a, b, { color={r,g,b,a}, thickness=3, flags="country" })`
- Country border: gruba (3-4px) czerwona linia, rysowana PONAD normalną granicą
- Flagi: `"country"`, `"alliance"`, `"war"`, `"truce"` — sterują wizualizacją
- W trybie strategicznym: tylko country borders + coastline. Bez land-land.
- W trybie taktycznym: wszystkie granice.

### Province Edge Gradient (Shading)
- Piksele bliżej granicy prowincji są ciemniejsze (multiply 0.7–0.85)
- Piksele w środku = normalny kolor
- Gradient liniowy: od granicy (darkest) do ~10% odległości od granicy do centroidu (normal)
- Efekt wizualny: 3D look na płaskiej mapie, jak w EU3/Victoria 2

### Stolice i napisy
- **Już istnieje**: import z PNG (biały piksel = stolica, magenta = linia etykiety)
- **Potrzebne**: render stolic jako ikonki (nie tylko dot) w trybie taktycznym
- **Potrzebne**: render nazw prowincji wzdłuż linii etykiety (curved text lub straight)
- W trybie strategicznym: stolice jako małe dots, nazwy TYLKO dla dużych prowincji
- W trybie taktycznym: stolice jako ikony (castle/city), nazwy wszystkich

### Drogi
- Drogi = linie proste między stolicami sąsiednich prowincji
- Rysowane TYLKO między widocznymi prowincjami (obie ≥ 2)
- Styl: brązowa linia, 1-2px, może być przerywana
- W trybie strategicznym: bez dróg
- W trybie taktycznym: drogi widoczne
- Dane: wynikają z grafu sąsiedztwa + pozycji stolic — zero dodatkowych plików

### Dwa tryby zoom

| Cecha | Strategiczny (1:1) | Taktyczny (8:1) |
|-------|-------------------|-----------------|
| pixel_size | 1 | 8 |
| Fill prowincji | ✅ | ✅ |
| Fog of War | ✅ | ✅ |
| Granice land-land | ❌ | ✅ |
| Granice coast | ✅ (cienkie) | ✅ |
| Granice country | ✅ (grube) | ✅ (grube) |
| Stolice | Dots | Ikony |
| Nazwy prowincji | Duże tylko | Wszystkie |
| Drogi | ❌ | ✅ |
| Edge gradient | ❌ (za mały) | ✅ |
| Detale terrain | ❌ | ✅ |

Przejście między trybami: animowany zoom (np. próg przy zoom=3.0 przełącza tryb).

---

## Dane liczbowe

```
Prowincje:           ~1500
Średnia sąsiadów:    ~5.5
Pary sąsiedztwa:    (1500 × 5.5) / 2 ≈ 4125 unikalnych par
Piksele wejściowe:  2000 × 900 = 1,800,000
Piksele wyjściowe:  16000 × 7200 = 115,200,000 (ale viewport max ~2M px)
```

---

## Opcja A: Rozszerzony Span-Based CPU (ewolucja obecnego systemu)

### Jak działa
1. PNG → province_grid (każdy piksel = u32 province_id) — **istniejące**
2. Marker sanitization (białe/magenta piksele → stolice/etykiety) — **istniejące**
3. Spans: ciągłe segmenty w rzędzie per prowincja → kolorowe prostokąty — **istniejące**
4. Granice: segmenty linii → per-class lub per-pair styl — **rozszerzenie**
5. Fog of War: skip province if `visibility_state < threshold` — **nowe**
6. Edge gradient: pre-compute distance-from-border per pixel → darken multiplier — **nowe (CPU)**
7. Roads: linie stolica→stolica z adjacency graph — **nowe (proste)**
8. Viewport culling: tylko widoczne + visible prowincje — **rozszerzenie**

### Nowe struktury danych

```rust
/// Per-adjacency-pair border override. Stored in HashMap<(ProvinceId, ProvinceId), BorderPairStyle>.
struct BorderPairStyle {
    color: [f32; 4],         // RGBA override (or [0;4] = use class default)
    thickness: f32,          // line width in map pixels (1.0 default)
    flags: BorderPairFlags,  // bitflags: COUNTRY | ALLIANCE | WAR | TRUCE
}

bitflags! {
    struct BorderPairFlags: u8 {
        const COUNTRY  = 0x01;
        const ALLIANCE = 0x02;
        const WAR      = 0x04;
        const TRUCE    = 0x08;
    }
}

/// Pre-computed distance field for edge gradient (per province pixel).
/// Stored as Vec<u8> same size as province grid. Value = distance to nearest border (clamped 0–255).
struct ProvinceDistanceField {
    data: Vec<u8>,  // 2000×900 = 1.8 MB
    width: u32,
    height: u32,
}
```

### Architektura pamięci

| Dane | Rozmiar |
|------|---------|
| Province grid (CPU, Vec<u32>) | 7.2 MB |
| Spans cache (~15 spans/prowincja avg) | ~2 MB |
| Border segments (~4125 par × ~20 segm.) | ~3 MB |
| Per-province style (32B × 1500) | 48 KB |
| **Per-pair border style (16B × 4125)** | **66 KB** |
| **Distance field (1B × 1.8M px)** | **1.8 MB** |
| **Road line cache (stolica→stolica)** | **~64 KB** |
| **RAZEM CPU** | **~14 MB** |
| **GPU (vertex buffers, dynamic)** | **~2-4 MB** |

### Renderowanie (CPU cost per frame)

| Operacja | Koszt | Uwagi |
|----------|-------|-------|
| Visibility filter (1500 provinces) | ~0.05 ms | Skip prov where visibility<2 |
| Viewport culling (visible provinces) | ~0.05 ms | AABB check |
| Emit fill rects (with gradient darken) | ~0.5-1.5 ms | Spans × darken lookup |
| Emit border lines/quads | 0.5-2 ms | Per-pair style lookup |
| Emit roads | ~0.1 ms | ~200 line segments |
| Emit capitals + labels | ~0.2 ms | Per-visible province |
| **Total CPU** | **~1.5-4 ms** | |

### Edge gradient problem (CPU approach)

Dla edge gradientu per-pixel na CPU:
- Opcja A1: Pre-compute distance field at load → multiply darken per span
  - Problem: span = horizontal run, ale gradient jest per-PIXEL — nie per-span
  - Rozwiązanie: split spany na sub-spany w strefach gradientu (inner/outer)
  - Dodaje ~3× więcej rects (1500 prov × 15 spans × 3 strefy = ~67K rects) ⚠️
- Opcja A2: Ignore gradient, render flat — utrata efektu EU3
- Opcja A3: Render do canvas → post-process shader darken edges — **de facto Opcja C**

### Renderowanie (GPU cost per frame)

| Operacja | Koszt |
|----------|-------|
| Draw calls (batched rects + lines + roads) | 4-8 draw calls |
| Vertices (67K rects + 3K borders + 200 roads) | ~300K vertices |
| Fragment fill | ~2M fragments viewport |
| **Total GPU** | **~1-2 ms** |

### Ładowanie

| Faza | Czas (estym.) |
|------|---------------|
| PNG decode (2000×900) | ~20 ms |
| Marker sanitization | ~30 ms |
| Grid scan (unique colors → IDs) | ~30 ms |
| Span extraction | ~50 ms |
| Border segment extraction | ~80 ms |
| Adjacency graph build | ~20 ms |
| **Distance field computation (BFS)** | **~200 ms** |
| Road path computation | ~5 ms |
| Cache binary write (optional) | ~15 ms |
| **Pierwszy raz** | **~450 ms** |
| **Z cache** | **~20 ms** |

### Modowanie

| Aspekt | Ocena |
|--------|-------|
| Dodanie prowincji | ✅ Maluj nowy kolor na PNG, dodaj wiersz w CSV |
| Zmiana granic | ✅ Edytuj PNG |
| Zmiana koloru prowincji | ✅ `reg:setPoliticalColor(id, r,g,b,a)` |
| Zmiana stylu granicy per-para | ✅ `reg:setBorderPairStyle(a, b, {...})` |
| Fog of war | ✅ `reg:setVisibilityState(id, 0|1|2)` |
| Custom efekty wizualne | ❌ Nie da się bez shaderu |
| Format plików | ✅ PNG + CSV (standardowe) |

### Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| Najmniej nowego kodu (~300 loc) | Edge gradient wymaga 3× więcej rects LUB post-process |
| Deterministyczne, łatwe do debug | CPU cost ~4 ms → mniej headroom na logikę gry |
| Brak zależności od GPU features | 300K vertices per frame na iGPU |
| Cache binarny = fast reload | Brak anti-aliasingu na granicach |
| Proste modowanie | Gradient per-pixel = trudny bez shadera |
| Drogi i FOW proste do dodania | Grube granice = quady → więcej geometrii |

---

## Opcja B: Full GPU Shader (styl Clausewitz Engine)

### Jak działa
Cała mapa renderowana jednym fullscreen shader pass:
1. **Province ID texture** (R32Uint, 2000×900) — upload raz
2. **Province data buffer** (storage, 1500 entries) — color + visibility + fog
3. **Border pair index texture** (R16Uint, 2000×900) — border pixel → pair_id
4. **Border style buffer** (storage, 4125 entries) — color + thickness + flags
5. **Distance field texture** (R8, 2000×900) — distance to nearest border (for gradient)
6. **Fragment shader** per viewport pixel: fill + fog + gradient + border detection

### Shader (WGSL) — pełna wersja z FOW + gradient + border

```wgsl
struct ProvinceData {
    color: vec4<f32>,
    visibility: u32,    // 0=hidden, 1=discovered, 2=visible
    fog_tint: f32,      // 0.0-1.0 fog overlay strength
    _pad: vec2<f32>,
}

struct BorderStyle {
    color: vec4<f32>,
    thickness: f32,
    flags: u32,
    _pad: vec2<f32>,
}

@group(0) @binding(0) var province_tex: texture_2d<u32>;
@group(0) @binding(1) var<storage> prov_data: array<ProvinceData>;
@group(0) @binding(2) var border_idx_tex: texture_2d<u32>;
@group(0) @binding(3) var<storage> border_styles: array<BorderStyle>;
@group(0) @binding(4) var distance_tex: texture_2d<f32>;  // R8 normalized

struct Uniforms {
    viewport: vec4<f32>,   // left, top, right, bottom in map space
    map_size: vec2<f32>,
    screen_size: vec2<f32>,
    zoom_mode: u32,        // 0=strategic, 1=tactical
    time: f32,
}
@group(1) @binding(0) var<uniform> u: Uniforms;

@fragment
fn fs_main(@builtin(position) pos: vec4<f32>) -> @location(0) vec4<f32> {
    // Map pos.xy → province grid coordinate
    let map_uv = u.viewport.xy + pos.xy * (u.viewport.zw - u.viewport.xy) / u.screen_size;
    let map_px = vec2<i32>(map_uv);

    // Bounds check
    if (map_px.x < 0 || map_px.y < 0 ||
        map_px.x >= i32(u.map_size.x) || map_px.y >= i32(u.map_size.y)) {
        return vec4(0.0, 0.0, 0.0, 1.0); // Ocean/void
    }

    let id = textureLoad(province_tex, map_px, 0).r;
    if (id == 0u) { return vec4(0.05, 0.15, 0.35, 1.0); } // Sea background

    let prov = prov_data[id];

    // FOG OF WAR
    if (prov.visibility == 0u) {
        return vec4(0.02, 0.02, 0.02, 1.0); // Hidden = black
    }
    if (prov.visibility == 1u) {
        return vec4(0.2, 0.2, 0.2, 1.0); // Discovered = dark grey
    }

    // BASE FILL
    var color = prov.color;

    // EDGE GRADIENT (tactical mode only)
    if (u.zoom_mode == 1u) {
        let dist = textureLoad(distance_tex, map_px, 0).r; // 0..1 (0=border, 1=center)
        let gradient_factor = mix(0.7, 1.0, smoothstep(0.0, 0.10, dist));
        color = vec4(color.rgb * gradient_factor, color.a);
    }

    // BORDER DETECTION
    let border_pair = textureLoad(border_idx_tex, map_px, 0).r;
    if (border_pair > 0u) {
        let style = border_styles[border_pair];

        // Check both neighbors are visible
        let id_r = textureLoad(province_tex, map_px + vec2(1, 0), 0).r;
        let id_d = textureLoad(province_tex, map_px + vec2(0, 1), 0).r;
        let neighbor_id = select(id_d, id_r, id_r != id);
        let neighbor_vis = prov_data[neighbor_id].visibility;

        if (neighbor_vis >= 2u) {
            // Zoom mode filter
            let is_country = (style.flags & 1u) != 0u;
            if (u.zoom_mode == 0u && !is_country && style.thickness <= 1.0) {
                // Strategic mode: skip thin non-country borders
            } else {
                color = style.color;
            }
        }
    }

    return color;
}
```

### Architektura pamięci

| Dane | Rozmiar | Gdzie |
|------|---------|-------|
| Province ID texture (R32Uint) | 7.2 MB | GPU |
| Province data buffer (48B × 1500) | 72 KB | GPU |
| Border index texture (R16Uint) | 3.6 MB | GPU |
| Border style buffer (32B × 4125) | 132 KB | GPU |
| Distance field texture (R8) | 1.8 MB | GPU |
| Province grid (CPU, for picking) | 7.2 MB | CPU |
| Adjacency graph (CPU, for roads) | ~0.5 MB | CPU |
| **RAZEM CPU** | **~7.7 MB** | |
| **RAZEM GPU** | **~12.8 MB** | |
| **RAZEM** | **~20.5 MB** | |

### Renderowanie (CPU cost per frame)

| Operacja | Koszt |
|----------|-------|
| Update province data buffer (dirty only) | ~0.01 ms |
| Update border styles (dirty only) | ~0.01 ms |
| Emit 1 fullscreen quad (map) | ~0 ms |
| Emit road lines (capitals visible only) | ~0.1 ms |
| Emit capital icons + labels | ~0.2 ms |
| **Total CPU** | **~0.3 ms** |

### Renderowanie (GPU cost per frame)

| Operacja | Koszt (iGPU) | Koszt (dGPU) |
|----------|-------------|-------------|
| Map shader (2M fragments, 5 tex reads + branching) | 2-3 ms | < 1 ms |
| Road lines (200 segments) | < 0.1 ms | < 0.1 ms |
| Capitals + labels | < 0.5 ms | < 0.2 ms |
| **Total GPU** | **~2.5-3.5 ms** | **< 1.5 ms** |

### Grubość granic w shaderze

Grubość >1px w **Opcja B** realizowana przez **dilated border_idx_texture**:
- Pre-bake: przy load time, dla każdej pary z `thickness > 1`, rozszerz border_idx w promieniu thickness/2
- Runtime shader: proste `if (border_pair > 0)` — O(1), zero kernela
- Koszt: border_idx_texture ma gęstsze piksele granicy → więcej border fragmentów, ale bez overhead per-pixel

Alternatywnie: multi-sample kernel (3×3 lub 5×5) — O(9) lub O(25) texture reads per pixel:
- 3×3 kernel (thickness 2px): 2M × 9 reads = 18M reads → **+1 ms** na iGPU
- 5×5 kernel (thickness 4px): 2M × 25 reads = 50M reads → **+3 ms** na iGPU ⚠️

**Rekomendacja**: pre-bake dilated texture — zero runtime cost, +100 ms load time.

### Ładowanie

| Faza | Czas (estym.) |
|------|---------------|
| PNG decode | ~20 ms |
| Marker sanitization | ~30 ms |
| Grid scan + adjacency | ~50 ms |
| Distance field (BFS) | ~200 ms |
| Border index computation | ~40 ms |
| Border dilation pre-bake | ~100 ms |
| GPU texture uploads (4 textures) | ~15 ms |
| Road graph setup | ~5 ms |
| **Pierwszy raz** | **~460 ms** |
| **Z cache** | **~30 ms** |

### Modowanie

| Aspekt | Ocena |
|--------|-------|
| Dodanie prowincji | ✅ PNG + CSV + reload |
| Zmiana granic | ✅ Edytuj PNG (auto-rebuild) |
| Zmiana koloru (runtime) | ✅ Update 1 entry w buffer (instant) |
| Zmiana border style (runtime) | ✅ Update 1 entry w buffer (instant) |
| FOW toggle | ✅ Update visibility field → shader auto-hides |
| Country border | ✅ Flags w style buffer |
| Custom shader effects | ✅ Podmień/rozszerz WGSL |
| Map mode switch | ✅ Swap color field w prov_data buffer |
| Format plików | ✅ PNG + CSV |

### Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| **CPU ~0.3 ms** — prawie cały budżet wolny na logikę gry | Nowy kod: ~700 loc Rust + ~150 loc WGSL |
| Edge gradient = free (distance tex read) | Debugging shaderów trudniejsze |
| FOW = 1 branch w shaderze (free) | Pre-bake dilation = 100 ms load |
| Country borders = 1 flag check (free) | Wymaga nowego pipeline w gpu_renderer |
| Zoom mode toggle = 1 uniform (free) | Picking wymaga CPU fallback grid |
| Instant map mode switch | Labels/roads nadal CPU-emitted |
| Per-pair style = buffer update (instant) | — |
| Anti-aliasing via bilinear sampling | — |
| Stały koszt niezależnie od widocznych prowincji | — |

---

## Opcja C: Hybrid — CPU Fill + GPU Border/Gradient Pass

### Jak działa
1. **Fill**: istniejący span system — CPU emits rects z viewport culling + FOW skip
2. **Borders + gradient**: GPU post-process shader pass na viewport
3. **Roads + capitals + labels**: CPU-emitted draw commands (proste geometrie)

### Pipeline per frame

```
┌──────────────────────────────────────────────────────┐
│  PASS 1: Province Fill (existing CPU spans)           │
│  - For each province where visibility >= 2:           │
│    - Resolve color (map mode)                         │
│    - Emit span rects with viewport culling            │
│  - For visibility == 1: emit grey rects               │
│  - For visibility == 0: skip entirely                 │
│  Result: colored map WITHOUT borders or gradient      │
├──────────────────────────────────────────────────────┤
│  PASS 2: Border + Gradient Shader (GPU post-process)  │
│  - Input: province_id_tex, border_idx_tex, dist_tex  │
│  - Overlay borders (per-pair style, thickness)        │
│  - Apply edge gradient darkening                      │
│  - Respect visibility (no border if neighbor hidden)  │
│  - Zoom mode filter (strategic: only country+coast)   │
│  Result: borders and shading composited on fill       │
├──────────────────────────────────────────────────────┤
│  PASS 3: Overlays (CPU commands)                      │
│  - Roads (lines between visible capitals)             │
│  - Capital icons (dots or sprites per zoom mode)      │
│  - Province names (text labels)                       │
│  Result: final map with all layers                    │
└──────────────────────────────────────────────────────┘
```

### Architektura pamięci

| Dane | Rozmiar | Gdzie |
|------|---------|-------|
| Province grid (Vec<u32>) | 7.2 MB | CPU |
| Span cache | ~2 MB | CPU |
| Per-province style | 72 KB | CPU |
| Per-pair border style (16B × 4125) | 66 KB | CPU + GPU |
| Province ID texture (R32Uint) | 7.2 MB | GPU |
| Border index texture (R16Uint, dilated) | 3.6 MB | GPU |
| Distance field texture (R8) | 1.8 MB | GPU |
| Border style buffer (32B × 4125) | 132 KB | GPU |
| Visibility buffer (4B × 1500) | 6 KB | GPU |
| Road line cache | ~64 KB | CPU |
| **RAZEM CPU** | **~9.4 MB** | |
| **RAZEM GPU** | **~12.7 MB** | |
| **RAZEM** | **~22 MB** | |

### Renderowanie (CPU cost per frame)

| Operacja | Koszt |
|----------|-------|
| FOW filter + viewport cull | ~0.1 ms |
| Emit fill spans (visible provinces) | ~0.5-1.0 ms |
| Emit shader pass uniform update | ~0.05 ms |
| Emit roads (line segments) | ~0.1 ms |
| Emit capitals + labels | ~0.2 ms |
| **Total CPU** | **~1.0-1.5 ms** |

### Renderowanie (GPU cost per frame)

| Operacja | Koszt (iGPU) | Koszt (dGPU) |
|----------|-------------|-------------|
| Fill spans (batched rects) | < 0.5 ms | < 0.2 ms |
| Border+gradient shader (2M fragments) | 1.5-2.5 ms | < 1 ms |
| Roads + capitals | < 0.3 ms | < 0.1 ms |
| **Total GPU** | **~2.5-3.5 ms** | **< 1.5 ms** |

### Ładowanie

| Faza | Czas (estym.) |
|------|---------------|
| PNG decode + sanitize | ~50 ms |
| Grid scan + adjacency | ~50 ms |
| Span extraction | ~50 ms |
| Border segments | ~80 ms |
| Distance field (BFS) | ~200 ms |
| Border index + dilation | ~140 ms |
| GPU uploads | ~15 ms |
| Road graph | ~5 ms |
| **Pierwszy raz** | **~590 ms** |
| **Z cache** | **~30 ms** |

### Modowanie

| Aspekt | Ocena |
|--------|-------|
| Dodanie prowincji | ✅ PNG + CSV |
| Zmiana koloru (runtime) | ✅ `setPoliticalColor` → span color updates |
| Zmiana border style | ✅ `setBorderPairStyle` → buffer update |
| FOW toggle | ✅ `setVisibilityState` → skip spans + shader check |
| Country border | ✅ flags w style buffer |
| Custom shader mods | ⚠️ Wymaga WGSL ale oddzielny od fill |
| Map mode switch | ✅ Batch recolor spans |
| Format | ✅ PNG + CSV |

### Pros & Cons

| ✅ Pros | ❌ Cons |
|---------|---------|
| Fill sprawdzony (istniejący kod) | Dwa systemy (spans + shader) |
| CPU ~1.5 ms (dużo headroom na logikę) | Load time najdłuższy (~590 ms cold) |
| Gradient + borders = GPU (free na CPU) | Zmiana mapy = rebuild spans + textures |
| FOW prosty (skip na CPU + check w shader) | Debugowanie hybrydowe trudniejsze |
| Incremental build (fazy niezależne) | Total pamięć ~22 MB (acceptable) |
| Labels/roads = proste CPU commands | — |
| Per-pair borders w shaderze (instant update) | — |

---

## Porównanie opcji (zaktualizowane)

### Wydajność renderowania (1080p, iGPU Intel UHD 630)

| Metryka | Opcja A (CPU+) | Opcja B (Full GPU) | Opcja C (Hybrid) |
|---------|---------------|--------------------|------------------|
| CPU per frame | 1.5-4 ms | **~0.3 ms** | ~1.0-1.5 ms |
| GPU per frame | 1-2 ms | 2.5-3.5 ms | 2.5-3.5 ms |
| Total frame time | 3-6 ms | **~3 ms** | ~4-5 ms |
| CPU free for game logic | ~12-14 ms | **~16 ms** | ~15 ms |
| Draw calls | 4-8 | 1-3 | 3-5 |
| 60 FPS headroom | ✅ OK | ✅ Best | ✅ Good |

### Pamięć

| Metryka | Opcja A | Opcja B | Opcja C |
|---------|---------|---------|---------|
| CPU RAM | ~14 MB | ~7.7 MB | ~9.4 MB |
| GPU VRAM | ~2-4 MB | ~12.8 MB | ~12.7 MB |
| **Total** | **~16-18 MB** | **~20.5 MB** | **~22 MB** |

### Czas ładowania

| Metryka | Opcja A | Opcja B | Opcja C |
|---------|---------|---------|---------|
| Cold load | ~450 ms | ~460 ms | ~590 ms |
| Cached load | ~20 ms | ~30 ms | ~30 ms |

### CPU headroom for game logic

| Metryka | Opcja A | Opcja B | Opcja C |
|---------|---------|---------|---------|
| CPU rendering cost | 1.5-4 ms | 0.3 ms | 1.0-1.5 ms |
| **Free CPU per frame (16.6ms budget)** | **12-15 ms** | **~16 ms** | **~15 ms** |

### Łatwość modowania

| Aspekt | A | B | C |
|--------|---|---|---|
| Zmiana mapy PNG | ✅ | ✅ | ✅ |
| Per-pair border style | ✅ | ✅ | ✅ |
| Edge gradient | ❌ (split spans) | ✅ (shader) | ✅ (shader) |
| FOW per-province | ✅ | ✅ | ✅ |
| Custom visual effects | ❌ | ✅ | ⚠️ (border shader only) |
| Map mode switch speed | ✅ instant | ✅ instant | ✅ instant |
| Debug/inspect | ✅ Easy | ❌ Hard | ⚠️ Mixed |

### Złożoność implementacji

| Metryka | Opcja A | Opcja B | Opcja C |
|---------|---------|---------|---------|
| Nowy Rust | ~300 loc | ~700 loc | ~500 loc |
| Nowy WGSL | 0 | ~150 loc | ~100 loc |
| Nowe pliki | 2 | 4 | 3 |
| Ryzyko regresji | Niskie | Średnie | Niskie-Średnie |
| Wymagana wiedza | Rust only | Rust + WGSL + wgpu pipeline | Rust + WGSL (simpler) |

---

## Sugerowane rozwiązanie: Opcja B (Full GPU)

### Zmiana rekomendacji vs poprzednia wersja

Poprzednio rekomendowałem Hybrid (C), ale po uwzględnieniu nowych wymagań:
1. **CPU musi być wolne** — logika gry w czasie rzeczywistym potrzebuje max headroom
2. **Edge gradient** — nie da się zrobić wydajnie na CPU (3× rects = więcej CPU)
3. **FOW** — shader check jest darmowy, CPU skip wymaga branching per-span
4. **Zoom mode toggle** — shader uniform jest darmowy, CPU musi przefiltrować spans
5. **Country borders** — shader flag check = 0 cost

**Opcja B** daje **~0.3 ms CPU** vs **1.5 ms** (C) lub **4 ms** (A). To +1.2-3.7 ms extra na game logic per frame — significant na iGPU.

### Dlaczego nie Opcja C?

Opcja C ma sens gdy:
- Nie potrzeba edge gradientu (ale potrzeba)
- Fill jest skomplikowany (ale nie jest — to flat color)
- Shader integration jest trudna (ale postfx pipeline już istnieje)

Skoro fill = flat color per province, to shader robi to samo co spans ale bez CPU overhead.

### Plan implementacji (Opcja B)

| Faza | Opis | Gate | Owner |
|------|------|------|-------|
| 1 | **Per-pair border structure** — `BorderPairStyle` + `AdjacencyStyleTable` | Unit test: 4125 par set/get | developer |
| 2 | **Distance field pre-compute** — BFS from border pixels, store as Vec<u8> | Test: dist[border_px]=0, dist[center]>0 | developer |
| 3 | **Border index pre-compute** — scan grid, dilate for thick borders | Test: pair_id correct for all border px | developer |
| 4 | **GPU texture upload** — R32Uint province ID, R16Uint border index, R8 distance | Textures created, correct size | developer |
| 5 | **Province map WGSL shader** — fill + FOW + gradient + borders + zoom mode | Visual: correct render vs reference | developer |
| 6 | **Lua API extensions** | `setBorderPairStyle`, zoom mode toggle | developer |
| 7 | **Road rendering** — adjacency graph → capital-to-capital lines | Roads visible in tactical mode | developer |
| 8 | **Zoom mode logic** — threshold-based strategic/tactical switch | Smooth transition at zoom=3 | developer |
| 9 | **Integration** — EU2 demo upgrade or new demo | Full EU3-like map playable | content-maker |

### Pliki do utworzenia/zmienić

```
src/province/border_pair_style.rs     — BorderPairStyle + AdjacencyStyleTable + serialization
src/province/distance_field.rs        — BFS distance field computation
src/province/border_index.rs          — border pair index grid + dilation
src/province/gpu_upload.rs            — R32Uint/R16Uint/R8 texture creation + buffer upload
src/province/gpu_bridge.rs            — extend ProvinceGpuRecord with visibility
assets/shaders/province_map.wgsl      — main map shader (fill+border+gradient+FOW)
src/render/province_map_pipeline.rs   — wgpu pipeline setup, bind groups, render pass
src/lua_api/province_api.rs           — new methods: setBorderPairStyle, setZoomMode
src/province/render.rs                — add road line generation, zoom mode options
tests/lua/unit/test_province_borders.lua
tests/lua/unit/test_province_fow.lua
content/games/strategy/eu2/           — upgrade demo
```

---

## Alternatywa: Kiedy wybrać Opcję A (CPU)

Jeśli:
- Edge gradient nie jest potrzebny (akceptujesz flat fill)
- GPU integration jest zbyt ryzykowna na start
- Chcesz szybki prototyp bez WGSL

Wtedy: zbuduj Opcję A jako MVP, potem migruj na B/C gdy CPU headroom stanie się problemem.

## Alternatywa: Kiedy wybrać Opcję C (Hybrid)

Jeśli:
- Fill musi mieć bardziej skomplikowaną logikę per-span (terrain texturing)
- Chcesz zachować CPU-side debugging fill
- GPU shader integration jest jednorazowa (border+gradient only, fill zostaje spans)

---

## Notatki techniczne

### wgpu R32Uint texture (province IDs)

```rust
let province_tex = device.create_texture(&wgpu::TextureDescriptor {
    label: Some("province_id_map"),
    size: wgpu::Extent3d { width: 2000, height: 900, depth_or_array_layers: 1 },
    mip_level_count: 1,
    sample_count: 1,
    dimension: wgpu::TextureDimension::D2,
    format: wgpu::TextureFormat::R32Uint,
    usage: wgpu::TextureUsages::TEXTURE_BINDING | wgpu::TextureUsages::COPY_DST,
    view_formats: &[],
});
// Upload: queue.write_texture(texture, &grid_data_as_bytes, ...)
```

### Distance Field (BFS)

```rust
/// Compute distance from each pixel to the nearest border pixel.
/// Returns Vec<u8> where 0 = border pixel, 255 = farthest from border.
fn compute_distance_field(grid: &[u32], width: u32, height: u32) -> Vec<u8> {
    let mut dist = vec![u8::MAX; (width * height) as usize];
    let mut queue: VecDeque<(u32, u32)> = VecDeque::new();

    // Seed: all border pixels (where neighbor differs)
    for y in 0..height {
        for x in 0..width {
            let id = grid[(y * width + x) as usize];
            let is_border = (x + 1 < width && grid[(y * width + x + 1) as usize] != id)
                || (y + 1 < height && grid[((y + 1) * width + x) as usize] != id);
            if is_border {
                dist[(y * width + x) as usize] = 0;
                queue.push_back((x, y));
            }
        }
    }

    // BFS to fill distances
    while let Some((x, y)) = queue.pop_front() {
        let d = dist[(y * width + x) as usize];
        if d >= 25 { continue; } // Max gradient radius = 25px
        for (nx, ny) in [(x+1,y),(x.wrapping_sub(1),y),(x,y+1),(x,y.wrapping_sub(1))] {
            if nx < width && ny < height {
                let idx = (ny * width + nx) as usize;
                if dist[idx] > d + 1 {
                    dist[idx] = d + 1;
                    queue.push_back((nx, ny));
                }
            }
        }
    }
    dist
}
```

### Border pair indexing

Pre-bake `border_index_texture` (R16Uint, 2000×900):
- Piksel nie-granica = 0
- Piksel granicy = pair_id (1..4125)
- Dilation: dla thickness > 1, rozszerz pair_id w promieniu thickness/2

Pair ID assignment:
```rust
let mut pair_map: HashMap<(u32, u32), u16> = HashMap::new();
let mut next_pair_id: u16 = 1;

fn get_pair_id(a: u32, b: u32) -> u16 {
    let key = if a < b { (a, b) } else { (b, a) };
    *pair_map.entry(key).or_insert_with(|| {
        let id = next_pair_id;
        next_pair_id += 1;
        id
    })
}
```

### Road rendering

Drogi = linie między stolicami sąsiednich prowincji:
```lua
-- Pseudocode w grze:
for _, pair in ipairs(reg:adjacencies()) do
    local a, b = pair.province_a, pair.province_b
    if reg:getVisibility(a) >= 2 and reg:getVisibility(b) >= 2 then
        local ca = reg:getCapital(a)
        local cb = reg:getCapital(b)
        if ca and cb then
            lurek.graphics.line(ca.x * ps, ca.y * ps, cb.x * ps, cb.y * ps)
        end
    end
end
```

Alternatywnie: pre-compute road list at province load → cache → emit only visible.

### Zoom mode transition

```lua
local STRATEGIC_THRESHOLD = 3.0  -- zoom < 3 = strategic

function get_zoom_mode(zoom)
    return zoom >= STRATEGIC_THRESHOLD and "tactical" or "strategic"
end

-- W uniform buffer shader'a: zoom_mode = 0 (strategic) lub 1 (tactical)
```

### Pre-bake cache format (binary, for fast reload)

```
[magic: u32][version: u32]
[width: u32][height: u32][province_count: u32][pair_count: u32]
[province_grid: u32 × (w×h)]
[distance_field: u8 × (w×h)]
[border_index: u16 × (w×h)]
[spans: (province_id: u32, y: u32, x0: u32, x1: u32) × N]
[pair_styles: BorderPairStyle × pair_count]
[capitals: (province_id: u32, x: f32, y: f32) × K]
```

Cache invalidation: compare PNG file hash. If different → rebuild.

---

## Risks & Open Questions

1. **wgpu bind group limits**: 4 textures + 2 buffers + 1 uniform = 7 bindings per draw. Standard wgpu limit = 16 per group. ✅ OK.
2. **R32Uint texture support**: universal on all wgpu backends. ✅ OK.
3. **Storage buffer max size**: 4125 × 32B = 132 KB. Min guaranteed = 128 MB. ✅ OK.
4. **iGPU bandwidth**: 5 texture reads per pixel × 2M px = 10M reads. At 4B average = 40 MB/frame. Intel UHD 630 bandwidth = ~25 GB/s = 400 frames possible at this rate. ✅ OK.
5. **Province picking (mouse hover)**: shader nie zwraca province_id — potrzebna CPU lookup z `grid[mouse_map_x, mouse_map_y]`. **Istniejące** `reg:screenToProvince()`.
6. **Hot-reload**: zmiana PNG → rebuild all textures + spans. ~460 ms. Acceptable for dev mode.
7. **Labels on shader-rendered map**: labels renderowane PONAD shader pass (Pass 3). Font rendering jest CPU-emitted (istniejący system). Nie wymaga zmian.

