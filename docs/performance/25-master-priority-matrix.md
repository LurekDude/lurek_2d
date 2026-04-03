# Master Priority Matrix — All 26 Areas

Comprehensive ranking of every optimization identified across this research series.
Sorted by ROI (impact ÷ effort) within each category.

---

## Legend

- **Effort**: days of Rust dev work (1 dev, not blocked)
- **Speedup**: measured or estimated relative to current baseline
- **Mode**: rayon / GPU / SIMD / Algorithmic / Architecture
- **Report**: file in this series for full details

---

## Priority Tier 1: Free Wins (≤ 2 days, dramatic impact)

| # | Module | Change | Effort | Speedup | Mode | Report |
|---|--------|--------|--------|---------|------|--------|
| 1 | Physics | Enable `rapier2d/parallel` Cargo feature | 0.5d | 4× simulation | Architecture | 01 |
| 2 | Crafting | Recipe output HashMap index | 2d | O(n×i) → O(1) | Algorithmic | 22 |
| 3 | Quest | Status index sets | 2d | O(q) → O(1) | Algorithmic | 22 |
| 4 | Dialog | Pre-computed char offset table | 1d | O(n) → O(1)/frame | Algorithmic | 22 |
| 5 | Savegame | Write-behind thread | 3d | 0 frame stall | Architecture | 24 |
| 6 | Economy | Dirty stats cache | 2d | 100× per stat query | Algorithmic | 19 |
| 7 | Scene | Dirty layout cache (GUI) | 2d | 0 layout work/frame | Algorithmic | 21 |
| 8 | Graph | Single-pass partition (double-retain fix) | 1d | 2× free | Algorithmic | 16 |
| 9 | Overlay | swap_remove over retain | 1d | constant factor | Algorithmic | 17 |
| 10 | Province | Border dirty flag + cache | 1d | 100× for static maps | Algorithmic | 20 |

---

## Priority Tier 2: High ROI Threading (3–7 days, 2–8× speedup)

| # | Module | Change | Effort | Speedup | Mode | Report |
|---|--------|--------|--------|---------|------|--------|
| 11 | Particles | rayon parallel update | 3d | 4× (>1k particles) | rayon | 03 |
| 12 | Overlay | rayon weather particles | 2d | 4× (>500 particles) | rayon | 17 |
| 13 | Tilemap | Chunk dirty caching | 3d | 90%+ CPU reduction | Algorithmic | 07 |
| 14 | Entity | Inverted tag index | 3d | O(n×t) → O(1) | Algorithmic | 18 |
| 15 | CardGame | Precomputed CDF for weighted draw | 3d | O(n) → O(log n) | Algorithmic | 11 |
| 16 | Compute | rayon parallel NdArray ops | 3d | 4× | rayon | 04 |
| 17 | AI | Parallel goal scoring | 4d | 4× GOAP | rayon | 05 |
| 18 | Battle | HashMap combatant index | 2d | O(n) → O(1) lookups | Algorithmic | 10 |
| 19 | Economy | rayon tick per resource | 2d | 4× tick phase | rayon | 19 |
| 20 | Stats | rayon multi-character recompute | 2d | 4× (50+ chars) | rayon | 19 |
| 21 | Pathfinding | Per-unit async rayon query | 3d | 4–8× | rayon | 05 |
| 22 | Modding | Parallel asset loading | 2d | N× per depth layer | rayon | 24 |
| 23 | Province | Parallel border extraction | 2d | 4× (300+ provinces) | rayon | 20 |
| 24 | Crafting | Parallel craftable check | 1d | 4× (500+ recipes) | rayon | 22 |
| 25 | Graph | Parallel decay/transit phases | 3d | 4× (1k+ nodes) | rayon | 16 |
| 26 | Image | rayon parallel pixel scanlines | 2d | 4–8× (>256×256) | rayon | 12 |
| 27 | Math | rayon parallel noise map | 2d | 4× (>64×64) | rayon | 13 |
| 28 | Entity | rayon bitmap queries | 2d | 4× (>5k entities) | rayon | 18 |

---

## Priority Tier 3: GPU Compute Ports (1–2 weeks, 10–1000× for large data)

| # | Module | Change | Effort | Speedup | WGSL | Report |
|---|--------|--------|--------|---------|------|--------|
| 29 | PostFX | Full GPU bloom pipeline | 2w | ~40× vs CPU bloom | wgpu compute + render | 15 |
| 30 | Overlay | GPU particle system | 2w | 30× (>500 particles) | compute + instanced draw | 17 |
| 31 | Minimap | GPU FOV compute shader | 1.5w | 150× (10 units) | wgpu compute | 14 |
| 32 | Tilemap | GPU instanced tile rendering | 2w | 10× (>1k visible tiles) | vertex instancing | 07 |
| 33 | Image | GPU Gaussian blur | 2w | 100× (>1024×1024) | compute shader | 12 |
| 34 | Math | GPU noise texture compute | 1.5w | 100–1000× | compute shader | 13 |
| 35 | Combat | GPU projectile simulation | 2w | 100× (500+ projectiles) | compute shader | 10 |
| 36 | Graphics | GPU frustum culling | 1w | 90% draw call reduction | compute shader | 02 |
| 37 | Province | Province color texture shader | 1.5w | Eliminate CPU borders | fragment shader | 20 |
| 38 | Compute | NdArray GPU compute | 3w | 100× (large arrays) | wgpu compute | 04 |
| 39 | Graph | GPU flow simulation | 3w | 100× (>10k nodes) | compute shader | 16 |

---

## Priority Tier 4: SIMD Micro-Optimizations (1–3 days, 2–4× on specific paths)

| # | Module | Change | Effort | Speedup | Report |
|---|--------|--------|--------|---------|--------|
| 40 | Image | SIMD u8x16 pixel blend | 3d | 4× blending | 12 |
| 41 | Math | Vec2x4 SoA SIMD batch | 3d | 4× particle ops | 13 |
| 42 | Math | SIMD easing batch | 2d | 4× tween systems | 13 |
| 43 | CardGame | SIMD weight sum | 2d | 4× weight total | 11 |
| 44 | Entity | SIMD u64x4 bitmap query | 3d | 4× ECS queries | 18 |
| 45 | Economy | SIMD f32x4 decay | 2d | 4× decay phase | 19 |
| 46 | Province | SIMD u32→f32 coord convert | 2d | 4× point conversion | 20 |
| 47 | Battle | SIMD modifier accumulation | 2d | 4× damage calc | 10 |

---

## Priority Tier 5: Architecture Investments (weeks, pay off at scale)

| # | Module | Change | Effort | Returns when | Report |
|---|--------|--------|--------|-------------|--------|
| 48 | Audio | Async sound decode | 1w | Game has >50 sounds | 03 |
| 49 | Filesystem | Multi-worker AsyncLoader | 1w | Level loads >100 assets | 06 |
| 50 | Compute | GPU DataArray with wgpu | 2w | >1M element arrays | 04 |
| 51 | AI | Behavior tree async eval | 1w | >100 active agents | 05 |
| 52 | Tilemap | Procedural gen thread worker | 1w | Infinite worlds | 07 |
| 53 | Network | tokio async runtime bridge | 2w | Multiplayer games | 23 |
| 54 | Pipeline | rayon parallel stages | 1w | Batch data processing | 23 |
| 55 | Modding | Hot-reload file watcher | 1w | Active mod development | 24 |
| 56 | Savegame | Atomic rename save | 1d | All games | 24 |
| 57 | Savegame | Parallel slot migration | 2d | Games with schema upgrades | 24 |

---

## Module-to-Report Cross Reference

| Module | Reports |
|--------|---------|
| `graphics` | 02 (GPU rendering), 15 (PostFX shaders) |
| `physics` | 01 (rapier2d parallel) |
| `audio` | 03 (async decode) |
| `particle` | 03 (rayon), 17 (GPU) |
| `compute` | 04 (rayon + GPU NdArray) |
| `ai` | 05 (GOAP parallel, influence maps) |
| `pathfinding` | 05 (A★ async pool) |
| `filesystem` | 06 (AsyncLoader), 24 (prefetch) |
| `tilemap` | 07 (GPU instancing, chunk cache) |
| `battle` | 10 (HashMap index, SIMD buffs) |
| `cardgame` | 11 (CDF weighted draw) |
| `item` | 11 (loot table CDF) |
| `image` | 12 (rayon, GPU blur, SIMD) |
| `math` | 13 (noise SIMD, GPU compute) |
| `minimap` | 14 (GPU FOV) |
| `postfx` | 15 (bloom GPU pipeline) |
| `graph` | 16 (rayon simulation phases) |
| `overlay` | 17 (GPU weather particles) |
| `entity` | 18 (ECS tag index, SIMD bitmap) |
| `economy` | 19 (rayon tick, SIMD decay) |
| `stats` | 19 (cache, rayon multi-char) |
| `province_map` | 20 (parallel borders, GPU texture) |
| `gui` | 21 (dirty cache, hit-test) |
| `scene` | 21 (radix depth sort) |
| `event` | 21 (parallel handlers) |
| `crafting` | 22 (recipe index, rayon) |
| `dialog` | 22 (char offset table) |
| `quest` | 22 (status index, rayon) |
| `network` | 23 (tokio bridge design) |
| `pipeline` | 23 (staged rayon design) |
| `savegame` | 24 (write-behind, atomic) |
| `modding` | 24 (parallel load, hot-reload) |

---

## Recommended Implementation Order

### Sprint 1 (2 weeks): Free 4× wins
- Enable `rapier2d/parallel` (30 min)  
- Recipe/Quest/Dialog algorithmic fixes as a bundle  
- Write-behind save thread  
- Graph/Overlay `.retain()` → swap_remove

### Sprint 2 (2 weeks): rayon threading wave  
- Particle + overlay rayon pass  
- Tilemap dirty chunk cache  
- Entity inverted tag index  
- NdArray rayon ops  
- Economy/stats rayon + dirty cache

### Sprint 3 (1 month): GPU compute push  
- PostFX bloom GPU pipeline (biggest visual payoff)  
- GPU overlay particle system  
- GPU minimap FOV  
- GPU tilemap instancing  
- Graphics frustum culling compute

### Sprint 4 (ongoing): SIMD + architecture investments  
- Selected SIMD passes where profiling confirms hot paths  
- Async audio decode  
- Network module design (tokio bridge)
