# Luna2D Ecosystem — Crate Recommendations

> **Purpose**: Definitive guide for which Rust crates Luna2D should use, consider, or avoid — per module, per tier.
> Aligned with the three-tier distribution model: **Luna2D Light**, **Luna2D Standard**, **Luna2D Full**.
> Updated: 2026-03-31 (v2). Based on architecture.md, design-assumptions.md, zen-of-luna.md, and Cargo.toml analysis.

---

## Table of Contents

- [Tier Model](#tier-model)
- [Binary Size Budget](#binary-size-budget)
- [Current Dependency Audit](#current-dependency-audit)
- [Tier 1 — Luna2D Light (Core)](#tier-1--luna2d-light-core)
- [Tier 2 — Luna2D Standard (Extended)](#tier-2--luna2d-standard-extended)
- [Tier 3 — Luna2D Full (Heavy Optional)](#tier-3--luna2d-full-heavy-optional)
- [Module-by-Module Recommendations](#module-by-module-recommendations)
  - [Graphics / Rendering](#1-graphics--rendering)
  - [Audio](#2-audio)
  - [Physics](#3-physics)
  - [Input](#4-input)
  - [Math](#5-math)
  - [Timer](#6-timer)
  - [Filesystem](#7-filesystem)
  - [Window / System](#8-window--system)
  - [Particles](#9-particles)
  - [Data / Compression / Hashing / Encoding](#10-data--compression--hashing--encoding)
  - [Image Processing](#11-image-processing)
  - [Sound Processing](#12-sound-processing)
  - [Fonts / Text](#13-fonts--text)
  - [Tilemap](#14-tilemap)
  - [Scene Management](#15-scene-management)
  - [Pathfinding](#16-pathfinding)
  - [Entity / ECS](#17-entity--ecs)
  - [AI (FSM, Behavior Trees, Steering, GOAP)](#18-ai-fsm-behavior-trees-steering-goap)
  - [Graph / Flow Networks](#19-graph--flow-networks)
  - [Compute Arrays / DataFrame](#20-compute-arrays--dataframe)
  - [Noise / Procedural Generation](#21-noise--procedural-generation)
  - [Tweening / Easing / Animation](#22-tweening--easing--animation)
  - [Serialization](#23-serialization)
  - [Networking](#24-networking)
  - [Logging](#25-logging)
  - [Clipboard / Dialogs](#26-clipboard--dialogs)
  - [System Info / Performance Monitoring](#27-system-info--performance-monitoring)
  - [Random Number Generation](#28-random-number-generation)
- [Removal Candidates](#removal-candidates)
- [Version Bump Recommendations](#version-bump-recommendations)
- [Summary Decision Matrix](#summary-decision-matrix)

---

## Tier Model

Luna2D ships in three tiers. Each tier adds binary size and capabilities:

| Tier | Name | Description | Binary Target |
|---|---|---|---|
| **1** | **Luna2D Light** | Core Love2D equivalent. Graphics, audio, input, physics, timer, filesystem, math, window, events, system, particles. | ≤ 10 MB |
| **2** | **Luna2D Standard** | Extended game systems. Tilemap, scene, pathfinding, entity/ECS, AI, graph, data processing, compute, noise, tweening. Pure Rust or tiny crate additions only. | ≤ 15 MB |
| **3** | **Luna2D Full** | Optional heavy features controlled by Cargo feature flags. Advanced physics (rapier2d), networking, advanced audio effects, Tiled import, Zstd compression. | ≤ 25 MB |

**The golden rule**: a game with 5 MB of assets should not ship with a 200 MB engine. Luna2D Light must be smaller than the game it runs.

---

## Binary Size Budget

Current baseline (debug build, all features): ~30 MB.

Estimated release binary breakdown by dependency weight:

| Dependency | Est. Release Contribution | Notes |
|---|---|---|
| wgpu 29 | ~4-6 MB | Largest dep. Mandatory for GPU rendering. |
| rapier2d 0.32 | ~1.5-2.5 MB | Heavy. Feature-gate candidate. |
| mlua 0.11 (LuaJIT) | ~1-1.5 MB | Core. Vendored LuaJIT. |
| rodio 0.22 | ~300-500 KB | Moderate. Includes decoders (symphonia backend). |
| gilrs 0.11 | ~200-400 KB | Gamepad. SDL_GameControllerDB bundled. |
| image 0.25 | ~200-400 KB | PNG/JPEG/BMP decoders. |
| glam 0.30 | ~50-100 KB | SIMD math. Near-zero cost (mostly inlines). |
| fontdue 0.9 | ~50-100 KB | Tiny. Perfect. |
| Everything else combined | ~500-800 KB | Serde, crypto, compression, etc. |

**Projected Light tier** (removing rapier2d): **~7-10 MB release**.
**Projected Standard tier** (Light + tiny pure-Rust additions): **~10-12 MB release**.
**Projected Full tier** (Standard + rapier2d + optional heavy deps): **~15-20 MB release**.

---

## Current Dependency Audit

Review of every dependency in Cargo.toml with keep/drop/feature-gate/bump recommendation:

| Crate | Current | Latest | Tier | Verdict | Notes |
|---|---|---|---|---|---|
| wgpu | 22 | **29** | 1 | **BUMP** | Core renderer. Major migration needed. |
| winit | 0.30 | **0.31** | 1 | **BUMP** | Core windowing. Minor API updates. |
| bytemuck | 1 | **1.25** | 1 | **KEEP** | Zero-cost. Semver-compatible. |
| pollster | 0.3 | **0.4** | 1 | **BUMP** | Tiny blocking executor. |
| mlua | 0.9 | **0.11** | 1 | **BUMP** | Core scripting. Breaking API changes 0.9→0.11. |
| image | 0.24 | **0.25** | 1 | **BUMP** | Texture loading. New features. |
| rodio | 0.17 | **0.22** | 1 | **BUMP** | Audio playback. Major rewrite (symphonia backend). |
| midly | 0.5 | **0.5.3** | 2 | **KEEP** | Tiny MIDI parser. |
| fontdue | 0.9 | **0.9.3** | 1 | **KEEP** | Tiny font rasterizer. |
| gilrs | 0.11 | **0.11.1** | 1 | **KEEP** | Gamepad input. |
| slotmap | 1 | **1.1** | 1 | **KEEP** | Generational arenas. |
| fastrand | 2 | **2.3** | 1 | **KEEP** | Tiny RNG. |
| thiserror | 1 | **2.0** | 1 | **BUMP** | Error derives. Breaking v2. |
| log | 0.4 | **0.4.27** | 1 | **KEEP** | Logging facade. |
| env_logger | 0.10 | **0.11** | 1 | **BUMP** | Log backend. |
| flate2 | 1 | **1.1** | 1 | **KEEP** | Deflate/gzip. |
| lz4_flex | 0.11 | **0.13** | 1 | **BUMP** | Pure Rust LZ4. |
| sha2 | 0.10 | **0.10.8** | 1 | **KEEP** | SHA-256/512. |
| sha1 | 0.10 | **0.10.6** | 1 | **KEEP** | SHA-1. |
| md-5 | 0.10 | **0.10.6** | 1 | **KEEP** | MD5. |
| base64 | 0.22 | **0.22.1** | 1 | **KEEP** | Base64. |
| hex | 0.4 | **0.4.3** | 1 | **KEEP** | Hex encoding. |
| serde | 1 | **1.0.219** | 1 | **KEEP** | Serialization. |
| serde_json | 1 | **1.0.149** | 1 | **KEEP** | JSON. |
| directories | 5 | **6.0** | 1 | **BUMP** | Platform paths. Breaking v6. |
| arboard | 3 | **3.6** | 2 | **KEEP** | Clipboard. |
| rfd | 0.14 | **0.17** | 2 | **BUMP** | File dialogs. Wayland fixes. |
| rapier2d | 0.32 | **0.32** | **3** | **FEATURE-GATE** | Heavy. ~2 MB. Optional. |
| sysinfo | 0.30 | **0.38** | 2 | **BUMP** | System info. Major API changes. |
| tiny-skia | 0.11 | — | — | **REMOVE** | Legacy CPU renderer. Dead code. |
| minifb | 0.27 | — | — | **REMOVE** | Legacy windowing. Dead code. |
| glam | — | **0.30** | 1 | **ADD** | SIMD math. Industry standard. |
| toml | — | **0.8** | 2 | **ADD** | TOML config format. |
| tiled | — | **0.15** | 3 | **ADD** | Tiled Map Editor import. |

---

## Tier 1 — Luna2D Light (Core)

The Love2D equivalent. Every game needs these. Must be as lean as possible.

### Modules Included

| Module | Current SLoC | Crate Strategy |
|---|---|---|
| Graphics (GPU renderer) | 8,148 | wgpu 29 *(mandatory, heavy but no alternative)* |
| Lua API bindings | 18,161 | mlua 0.11 *(mandatory)* |
| Audio | 1,135 | rodio 0.22 *(adequate for core)* |
| Input (keyboard, mouse, gamepad, touch) | 642 | winit 0.31 + gilrs 0.11 |
| Math (Vec2, Mat3, Rect, easing, random) | 4,463 | **glam 0.30** for core types + hand-rolled extensions |
| Timer | 85 | **Native** — trivial |
| Filesystem (sandboxed I/O, VFS) | 685 | **Native** — security-critical sandboxing |
| Engine (app loop, config, errors) | 2,144 | **Native** |
| Particles | 624 | **Native** — Love2D parity |
| Data (ByteData, compress, hash, encode) | 249 | flate2 + lz4_flex + sha2/md-5 + base64/hex |
| Image (CPU pixel buffer) | 188 | image 0.25 (PNG/JPEG/BMP features) |
| Sound (PCM samples) | 97 | **Native** — trivial |
| Fonts | — | fontdue 0.9 |
| Window management | 1 | winit 0.31 |

### Crates for Tier 1

```toml
# Mandatory — no alternatives
wgpu = "29"
winit = "0.31"
mlua = { version = "0.11", default-features = false }
bytemuck = { version = "1", features = ["derive"] }
pollster = "0.4"

# SIMD Math
glam = "0.30"

# Audio
rodio = "0.22"

# Image loading + saving
image = { version = "0.25", default-features = false, features = ["png", "jpeg", "bmp"] }

# Fonts
fontdue = "0.9"

# Gamepad
gilrs = "0.11"

# Resource management
slotmap = "1"

# Data processing
flate2 = "1"
lz4_flex = "0.13"
sha2 = "0.10"
sha1 = "0.10"
md-5 = "0.10"
base64 = "0.22"
hex = "0.4"

# Infrastructure
serde = { version = "1", features = ["derive"] }
serde_json = "1"
toml = "0.8"
log = "0.4"
env_logger = "0.11"
thiserror = "2"
fastrand = "2"
directories = "6"
```

### What Tier 1 does NOT include

- rapier2d (heavy physics → Tier 3)
- arboard/rfd (clipboard/dialogs → Tier 2)
- sysinfo (system info → Tier 2)
- midly (MIDI → Tier 2)
- Any tilemap, scene, pathfinding, AI, graph, compute, dataframe, entity modules

### Tier 1 Physics Strategy

Tier 1 ships with the **hand-rolled AABB physics** already implemented in `src/physics/`. This provides:
- Gravity, velocity, acceleration
- AABB collision detection and resolution
- Restitution, friction, damping
- Static, dynamic, kinematic body types
- Basic raycasting

This is sufficient for platformers, top-down games, puzzle games, and simple action games — the 80% use case. It adds **zero** binary overhead beyond the ~1,500 SLoC already written.

---

## Tier 2 — Luna2D Standard (Extended)

Game systems that go beyond Love2D. Pure Rust implementations with optional tiny crate additions.

### Modules Included (on top of Tier 1)

| Module | Current SLoC | Crate Strategy | Crate Binary Impact |
|---|---|---|---|
| Tilemap | 2,343 | **Native** — expanded built-in features | 0 |
| Scene management | 250 | **Native** — expanded with Solar2D-style lifecycle | 0 |
| Pathfinding | 1,464 | **Native** — hand-rolled A*/flow fields work well | 0 |
| Entity/ECS | 570 | **Native** — expanded with more features | 0 |
| AI (FSM, BT, steering, GOAP) | 1,791 | **Native** — keep and expand | 0 |
| Graph/flow networks | 2,253 | **Native** — expanded with more algorithms | 0 |
| Compute arrays | 1,439 | **Native** — expanded with more operations | 0 |
| DataFrame | 2,268 | **Native** — hand-rolled CSV/JSON/SQL | 0 |
| Math extensions (noise, geometry, procgen) | (in math) | **Native** — expanded noise features | 0 |
| Tweening / Animation | (in math) | **Native** — expanded easing + sprite animation | 0 |
| MIDI | — | midly 0.5 | ~10 KB |
| Clipboard | — | arboard 3 | ~50 KB |
| File dialogs | — | rfd 0.17 | ~50 KB |
| Performance monitoring | — | sysinfo 0.38 (no-default-features) | ~200-400 KB |
| Serialization (TOML) | — | toml 0.8 (included in Tier 1) | ~50-80 KB |
| Serialization (binary) | — | **Native** — simple binary dump | 0 |

### Tier 2 Crate Assessment — Module by Module

#### Tilemap — KEEP NATIVE, expand built-in features

The hand-rolled tilemap (2,343 SLoC) already covers:
- Orthogonal, isometric, hexagonal coordinate systems
- Autotiling (4-bit and 8-bit bitmask)
- Chunk-based storage, viewport culling
- Collision detection (solid, AABB, swept)
- Procedural map generation (MapGen, MapBlock, MapScript)

**Expand with**:
- **Hex grid utilities**: Implement hex neighbor lookup, hex ring/spiral iterators, hex-to-pixel and pixel-to-hex conversion natively. Inspired by `hexx` crate algorithms (cube coordinates, offset coordinates, axial coordinates, hex distance, hex line drawing, hex range queries). Keep native — hex math is well-documented and straightforward.
- **Layer blending modes**: Alpha, additive, multiply for tile layer compositing.
- **Object layers**: Named rectangle/polygon/point objects for spawn points, triggers, collision zones.
- **Tile properties**: Arbitrary key/value metadata per tile ID (material type, walkability cost, animation speed).

**Verdict**: KEEP NATIVE. Expand with hex grid and object layer features.

#### Pathfinding — KEEP NATIVE

The hand-rolled pathfinding (1,464 SLoC) already has:
- NavGrid with A* search and path smoothing
- HPA* hierarchical abstraction
- Flow fields (BFS integration + direction field)
- Unit-size-aware collision
- Async path thread pool
- LRU path cache

**Verdict**: KEEP NATIVE. The hand-rolled version is tailored to 2D game needs and already feature-complete.

#### Entity/ECS — KEEP NATIVE, expand

The hand-rolled entity system (570 SLoC) provides:
- Entity lifecycle with ID recycling
- Named components stored as Lua values
- Bitmap tags (O(1), max 63)
- Draw layers
- Blueprints with inheritance
- System dispatch

**Expand with**:
- **Entity queries**: Filter entities by component/tag combinations efficiently.
- **Component lifecycle hooks**: on_add, on_remove callbacks per component type.
- **Entity groups/pools**: Named collections for batch operations (all enemies, all bullets).
- **Parent-child relationships**: Hierarchical entity trees for composite objects.

**Verdict**: KEEP NATIVE. The Lua-value-based ECS is the right design for a scripting engine.

#### AI — KEEP NATIVE

The hand-rolled AI (1,791 SLoC) already covers FSM, behavior trees, utility AI, GOAP, steering behaviors, PathGrid, FlowField, InfluenceMap, squad formations, command queues, and Q-learning.

**Verdict**: KEEP NATIVE. The integrated AI toolkit is a competitive advantage.

#### Graph — KEEP NATIVE, expand with more algorithms

The hand-rolled graph module (2,253 SLoC) provides game-specific flow simulation. However, `petgraph` (18K SLoC) contains valuable algorithms worth reimplementing natively:

**Algorithms to reimplement from petgraph** (keep native, don't add the crate):
- **Bellman-Ford** shortest path — handles negative edge weights (useful for cost/benefit analysis).
- **Strongly connected components (Tarjan's)** — detect circular dependencies in production chains.
- **Min spanning tree (Kruskal/Prim)** — optimal network layout for base building games.
- **Max flow (Ford-Fulkerson)** — optimize throughput in factory/logistics simulations.
- **Graph isomorphism** — compare graph structures for pattern matching.

**Verdict**: KEEP NATIVE. Reimplement select petgraph algorithms as native code (~500-800 SLoC total).

#### Compute Arrays — KEEP NATIVE, expand

The hand-rolled compute module (1,439 SLoC) provides N-dimensional arrays with arithmetic, reduction, and spatial ops.

**Expand with** (inspired by `ndarray` but kept native):
- **Cumulative sum / cumulative product** along axes.
- **Sorting** along axes (argsort, partial sort).
- **Histogram / binning** operations.
- **Interpolation** (linear, bilinear) on arrays.
- **GPU compute offload**: For large arrays, consider wgpu compute shaders for parallel operations (matmul, convolution). This leverages the existing wgpu dependency at zero additional binary cost.

**Verdict**: KEEP NATIVE. Expand with sorting, histogram, interpolation. Consider wgpu compute shaders for hot paths.

#### Noise Generation — KEEP NATIVE, expand features

Luna2D already hand-rolls Perlin/Simplex/Worley/FBM noise with domain warping and bulk map generation.

**Expand with**:
- **Value noise** — simpler interpolated grid noise, good for terrain.
- **Blue noise** — Poisson disk sampling for object placement (trees, rocks, NPCs).
- **Cellular automata** — cave/dungeon generation (already partially in procgen, expand).
- **Wave Function Collapse (WFC)** — constraint-based procedural generation for tiles and levels.
- **Voronoi diagrams** — biome boundaries, territory division.
- **Gradient ramp/color mapping** — map noise values to color gradients for terrain visualization.

**Verdict**: KEEP NATIVE. Expand with blue noise, WFC, Voronoi, and cellular automata.

### Tier 2 Additional Crates (new additions)

```toml
# TOML configuration (moved to Tier 1 — mandatory per design-assumptions.md B-05)
# toml = "0.8"  # already in Tier 1

# Desktop integration (already present, bump)
arboard = "3"
rfd = "0.17"

# MIDI (already present)
midly = "0.5"

# Performance monitoring (replaces static system info)
sysinfo = { version = "0.38", default-features = false, features = ["system"] }
```

---

## Tier 3 — Luna2D Full (Heavy Optional)

Features that require heavy external crates. Each is behind a Cargo feature flag. Users who don't need them don't pay the binary cost.

### Feature-Gated Heavy Dependencies

| Feature Flag | Crate | Version | Binary Impact | What It Enables |
|---|---|---|---|---|
| `physics-rapier` | rapier2d | 0.32 | ~1.5-2.5 MB | Full rigid-body physics: circles, polygons, joints, raycasting, CCD |
| `tiled-import` | tiled | 0.15 | ~30-60 KB | Load TMX/TSX files from the Tiled Map Editor |
| `networking` | message-io | 0.19 | ~200-400 KB | TCP/UDP/WebSocket game networking |
| `compress-zstd` | zstd | 0.13 | ~800 KB | High-ratio Zstd compression (C binding) |

### Proposed Cargo.toml Feature Flags

```toml
[features]
default = ["lua-jit"]
lua-jit = ["mlua/luajit", "mlua/vendored"]
lua54 = ["mlua/lua54", "mlua/vendored"]

# Tier 3 optional features
physics-rapier = ["dep:rapier2d"]
tiled-import = ["dep:tiled"]
networking = ["dep:message-io"]
compress-zstd = ["dep:zstd"]

# Bundle: everything
full = ["physics-rapier", "tiled-import", "networking", "compress-zstd"]
```

### Rapier2D Feature-Gate Strategy

Currently rapier2d is unconditional. To feature-gate it:

1. Move `src/physics/world.rs` rapier2d integration behind `#[cfg(feature = "physics-rapier")]`
2. Keep the hand-rolled AABB physics as the always-available fallback
3. When `physics-rapier` is enabled, the `luna.physics.newWorld()` creates a rapier2d-backed world
4. When disabled, `luna.physics.newWorld()` creates the lightweight AABB world
5. The Lua API surface stays identical — only the backend changes

---

## Module-by-Module Recommendations

### 1. Graphics / Rendering

| Aspect | Current | Recommendation |
|---|---|---|
| GPU renderer | wgpu 22 (8,148 SLoC) | **BUMP to wgpu 29** — major migration needed |
| CPU fallback | tiny-skia 0.11 + minifb 0.27 | **REMOVE** — dead code |
| Texture loading | image 0.24 | **BUMP to image 0.25** — new format support |
| Font rasterization | fontdue 0.9 | **KEEP** — tiny, fast, perfect |
| Vertex data | bytemuck 1 | **KEEP** — zero-cost |
| wgpu init | pollster 0.3 | **BUMP to 0.4** |
| SIMD Math | — | **ADD glam 0.30** — SIMD-optimized Vec2/Vec3/Mat3/Mat4 |

**glam integration strategy**: The `glam` crate (0.30) is the industry-standard SIMD math library for Rust game engines (used by Bevy, wgpu internally). It provides `Vec2`, `Vec3`, `Vec4`, `Mat2`, `Mat3`, `Mat4`, `Quat` with optional SIMD acceleration.

**Integration plan**:
- Use `glam::Vec2` and `glam::Mat3` as the internal representation in Luna2D's math types.
- Keep the existing `luna.math.Vec2` Lua API surface unchanged — wrap glam types in UserData.
- Benefit: SIMD-accelerated vector/matrix operations at near-zero binary cost (glam is mostly inlines).
- Benefit: Compatibility with wgpu's internal math (reduces conversion overhead at GPU boundaries).
- The 4,463 SLoC of math code stays, but hot-path operations delegate to glam.

**GPU compute**: wgpu compute shaders can accelerate large-array operations (matmul, convolution, noise generation). This uses the existing wgpu dependency — zero additional binary cost.

### 2. Audio

| Aspect | Current | Recommendation |
|---|---|---|
| Core playback | rodio 0.17 | **BUMP to rodio 0.22** — symphonia backend, new features |
| MIDI | midly 0.5 | **KEEP** |
| Advanced audio effects | — | **EXPAND NATIVE** using rodio's built-in DSP chain |

**Audio effects — NATIVE EXPANSION using rodio 0.22**:

rodio 0.22 ships with a rich Source trait and built-in audio processors. Luna2D should expand the native audio module to expose:

- **Lowpass filter** — already implemented (keep and improve with configurable cutoff frequency)
- **Highpass filter** — already implemented (keep and improve)
- **Bandpass filter** — combine lowpass + highpass for frequency band isolation
- **Echo/Delay** — delay line with feedback (native, ~50 SLoC)
- **Reverb** — simple Schroeder reverb using multiple delay lines + allpass filters (native, ~100-200 SLoC)
- **Chorus** — modulated delay for thickening sounds (native, ~80 SLoC)
- **Distortion/Overdrive** — waveshaping/clipping (native, ~30 SLoC)
- **Fade in/out** — already implemented
- **Gain/volume** — already implemented
- **Pitch shift** — already implemented via rodio
- **Speed control** — playback rate adjustment
- **Compressor/limiter** — dynamic range compression (native, ~100 SLoC)
- **Panning** — stereo panning (already implemented)
- **EQ (3-band)** — simple equalizer using cascaded biquad filters (native, ~150 SLoC)

**Implementation strategy**: Build these as native Rust types that implement rodio's `Source` trait. Chain them together in a DSP pipeline. The Lua API exposes `luna.audio.newEffect("reverb", {params})` and `source:addEffect(effect)`.

**Why NOT kira**: kira (0.12) is an excellent game audio library but would add ~200-400 KB to the binary. The audio effects listed above can be implemented natively in ~500-700 SLoC total, using rodio's existing infrastructure. The native approach gives Luna2D full control over the DSP pipeline and the Lua API surface. **Verdict: Keep rodio, expand native effects.**

### 3. Physics

| Aspect | Current | Recommendation |
|---|---|---|
| AABB physics | Hand-rolled (1,510 SLoC) | **KEEP** as Tier 1 default |
| Full physics | rapier2d 0.32 | **FEATURE-GATE** as Tier 3 (`physics-rapier`) |

**No changes to physics strategy.** The hand-rolled AABB physics is sufficient for 80% of 2D games. rapier2d remains available as an optional heavy dependency for games needing circles, polygons, and joints.

### 4. Input

| Aspect | Current | Recommendation |
|---|---|---|
| Keyboard/mouse/touch | winit 0.30 | **BUMP to 0.31** |
| Gamepad | gilrs 0.11 | **KEEP** |

No changes needed. Both are lightweight and well-suited.

### 5. Math

| Aspect | Current | Recommendation |
|---|---|---|
| Core types | Hand-rolled Vec2, Mat3, Rect | **Delegate to glam 0.30** internally |
| Easing | Hand-rolled (22 functions) | **EXPAND** with more curves |
| Noise | Hand-rolled (Perlin, Simplex, Worley, FBM) | **EXPAND** (see §21) |
| Random | fastrand 2 | **KEEP** — tiny, fast |
| Geometry | Hand-rolled (14 functions) | **KEEP NATIVE** |
| Triangulation | Hand-rolled (ear-clipping) | **KEEP NATIVE** |

**glam integration**: Use `glam::Vec2` as the backing type for Luna2D's `Vec2`. Keep the Lua API surface identical — `luna.math.newVec2(x, y)` still works. The change is internal: hot-path operations (add, sub, mul, dot, normalize, length, distance) use SIMD-accelerated glam implementations. Mat3 and transform operations similarly delegate.

**Easing expansion** — add these curves beyond the existing 22:
- `ease_in_out_elastic` — complete the elastic family
- `ease_in_out_bounce` — complete the bounce family
- `ease_in_out_back` — complete the back family
- `ease_in_circ`, `ease_out_circ`, `ease_in_out_circ` — circular curves
- `spring(damping, frequency)` — spring physics-based easing
- `smooth_step` / `smoother_step` — Hermite interpolation
- `bezier(p1x, p1y, p2x, p2y)` — custom cubic Bézier easing curves
- `catmull_rom` — Catmull-Rom spline interpolation

### 6. Timer

No external dependencies. 85 SLoC. **KEEP NATIVE** — trivial.

### 7. Filesystem

No external dependencies beyond `std`. 685 SLoC. **KEEP NATIVE** — security-critical sandboxing must be hand-controlled.

### 8. Window / System

| Aspect | Current | Recommendation |
|---|---|---|
| Windowing | winit 0.30 | **BUMP to 0.31** |
| Clipboard | arboard 3 | **KEEP** (Tier 2) — simple clipboard is enough |
| File dialogs | rfd 0.14 | **BUMP to 0.17** (Tier 2) |
| OS directories | directories 5 | **BUMP to 6** |
| System info | sysinfo 0.30 | **BUMP to 0.38** — refocused on performance monitoring |
| Locale detection | sys-locale 0.3 | **KEEP** — tiny |

### 9. Particles

No external dependencies. 624 SLoC. **KEEP NATIVE** — perfect scope. Love2D parity.

### 10. Data / Compression / Hashing / Encoding

| Aspect | Current | Recommendation |
|---|---|---|
| Compression (deflate/gzip) | flate2 1 | **KEEP** |
| Compression (LZ4) | lz4_flex 0.11 | **BUMP to 0.13** |
| Compression (Zstd) | — | **ADD as Tier 3** feature gate |
| Hashing (SHA-256/512) | sha2 0.10 | **KEEP** |
| Hashing (SHA-1) | sha1 0.10 | **KEEP** |
| Hashing (MD5) | md-5 0.10 | **KEEP** |
| Encoding (base64) | base64 0.22 | **KEEP** |
| Encoding (hex) | hex 0.4 | **KEEP** — provides hex encoding/decoding for strings and bytes |
| ByteData | Hand-rolled (249 SLoC) | **KEEP NATIVE** |

**hex crate details**: The `hex` crate (0.4.3) provides:
- `hex::encode(bytes) → String` — convert bytes to hex string
- `hex::decode(hex_string) → Vec<u8>` — convert hex string back to bytes
- `FromHex` / `ToHex` traits for custom types
- Useful for debugging binary data, color codes (`"FF00FF"`), and hash display.
This is purely an encoding library — NOT a hex grid library. Hex grid functionality belongs in the tilemap module (see §14).

### 11. Image Processing

| Aspect | Current | Recommendation |
|---|---|---|
| Image loading | image 0.24 | **BUMP to 0.25** — PNG read/write focus |
| ImageData (CPU pixels) | Hand-rolled (188 SLoC) | **EXPAND NATIVE** |

**PNG-focused expansion** — the user wants full PNG workflow:
- **Load PNG** — already supported via `image` crate (keep)
- **Save PNG** — add `ImageData:save(path)` using `image::save_buffer()` with PNG encoder
- **Screenshot to PNG** — add `luna.graphics.captureScreenshot(path)` that reads the framebuffer and saves to PNG
- **Pixel-by-pixel access** — already implemented (`get_pixel`, `set_pixel`), ensure it works for loaded PNGs
- **Raw byte access** — already implemented (`as_bytes`), document for advanced users

**ImageData API expansion**:
- `ImageData:encode("png") → ByteData` — encode to PNG bytes in memory
- `ImageData:clone() → ImageData` — deep copy
- `ImageData:paste(source, x, y)` — blit one image onto another
- `ImageData:getSubImage(x, y, w, h) → ImageData` — extract sub-region

### 12. Sound Processing

| Aspect | Current | Recommendation |
|---|---|---|
| SoundData (PCM) | Hand-rolled (97 SLoC) | **KEEP NATIVE** — trivial |

### 13. Fonts / Text

| Aspect | Current | Recommendation |
|---|---|---|
| Font rendering | fontdue 0.9 | **KEEP** — tiny, fast, supports TTF/OTF |

### 14. Tilemap

| Aspect | Current | Recommendation |
|---|---|---|
| Core tilemap | Hand-rolled (2,343 SLoC) | **KEEP NATIVE — EXPAND** |
| Tiled editor import | — | **ADD `tiled` 0.15** as Tier 3 feature |

**`tiled` crate integration (Tier 3, feature-gated)**:
The `tiled` crate (0.15, maintained by the Tiled editor team) enables importing `.tmx` (tile maps) and `.tsx` (tilesets) files from the Tiled Map Editor — the most popular 2D map editor in the industry.

**What `tiled` provides**:
- TMX/TSX XML parsing
- Orthogonal, isometric, staggered, hexagonal map support
- Tile layers, object layers, image layers, group layers
- Tile animations, tile collision shapes
- Custom properties on maps, layers, tiles, objects
- Built-in zstd/zlib/gzip decompression of tile data
- World file (.world) support for multi-map games

**Integration plan**: Behind `#[cfg(feature = "tiled-import")]`. Add `luna.tilemap.loadTiled(path)` that returns a native Luna2D `TileMap` populated from the TMX data. Map TMX layers → TileLayer, TMX tilesets → TileSet, TMX objects → a Lua table of shapes/points.

**Native tilemap expansion** (independent of `tiled`):
- **Hex grid support**: Cube/axial/offset coordinate systems, hex neighbors, hex distance, hex ring/spiral iteration, hex line drawing, hex-to-pixel and pixel-to-hex. Keep native — hex math is well-documented. Inspired by `hexx` crate algorithms but reimplemented.
- **Object layers**: Named objects with type, position, size, rotation, and custom properties. For triggers, spawn points, collision zones.
- **Tile properties table**: Arbitrary key/value metadata per tile ID (walkability, material, animation speed).
- **Layer blend modes**: Normal, additive, multiply compositing for tile layer rendering.

### 15. Scene Management

| Aspect | Current | Recommendation |
|---|---|---|
| Scene stack | Hand-rolled (250 SLoC) | **KEEP NATIVE — EXPAND** |

**Expansion inspired by Solar2D (Corona) Composer**:

The current scene system has: push, pop, register, enter/leave/pause/resume callbacks, transitions, inter-scene data, depth sorting. This is a solid foundation.

**Add**:
- **Two-phase event lifecycle**: `will_enter` / `did_enter` / `will_leave` / `did_leave` — gives scenes hooks before and after transitions complete. Solar2D's `will`/`did` phase pattern is proven.
- **Scene overlays**: `pushOverlay(sceneName, params)` — a modal scene that renders on top of the current scene without pausing it. For dialog boxes, HUD panels, inventory popups. `popOverlay()` dismisses.
- **Scene preloading**: `preloadScene(sceneName)` — create the scene object and run its `create` callback without showing it. For loading screens.
- **Scene recycling**: When a scene is hidden, its view can be destroyed (freeing GPU textures) while the scene object persists. `recycleOnLeave` flag per scene.
- **More transition effects**:
  - `crossFade` — old and new scene blend simultaneously
  - `zoomIn` / `zoomOut` — scale transitions
  - `flipHorizontal` / `flipVertical` — card-flip style
  - `iris` / `irisOpen` — circular reveal/close (common in retro games)
- **Inter-scene variables**: `luna.scene.setVariable(key, value)` / `getVariable(key)` — clean global state bridge between scenes (Solar2D pattern). Already partially implemented via inter-scene data — formalize the API.

### 16. Pathfinding

| Aspect | Current | Recommendation |
|---|---|---|
| A* / Dijkstra / BFS | Hand-rolled (1,464 SLoC) | **KEEP NATIVE** |

### 17. Entity / ECS

| Aspect | Current | Recommendation |
|---|---|---|
| Entity system | Hand-rolled (570 SLoC) | **KEEP NATIVE — EXPAND** |

**Expansion**:
- **Entity queries**: `universe:query("health", "position")` → returns entities with both components. Bitmap tag intersection for fast filtering.
- **Component lifecycle hooks**: `on_add(entity, component_name)`, `on_remove(entity, component_name)` callbacks.
- **Entity groups/pools**: Named collections (`enemies`, `bullets`, `pickups`) with O(1) membership test.
- **Parent-child hierarchies**: `setParent(child, parent)` for composite entities. Kill parent → kill children.
- **Entity serialization**: `universe:serialize() / universe:deserialize()` for save/load.

### 18. AI (FSM, Behavior Trees, Steering, GOAP)

| Aspect | Current | Recommendation |
|---|---|---|
| All AI subsystems | Hand-rolled (1,791 SLoC) | **KEEP NATIVE** |

### 19. Graph / Flow Networks

| Aspect | Current | Recommendation |
|---|---|---|
| Directed graph with flow | Hand-rolled (2,253 SLoC) | **KEEP NATIVE — EXPAND** |

**Native expansion — algorithms inspired by petgraph** (do NOT add the crate, reimplement natively):
- **Bellman-Ford shortest path** — handles negative edge weights. Useful for cost/benefit analysis in factory simulations. ~80 SLoC.
- **Strongly connected components (Tarjan's)** — detect circular dependencies in production chains. ~60 SLoC.
- **Minimum spanning tree (Kruskal's)** — optimal network layout for base-building games. ~70 SLoC.
- **Maximum flow (Ford-Fulkerson / Edmonds-Karp)** — optimize throughput in logistics/factory simulations. ~100 SLoC.
- **Topological sort** — dependency ordering for tech trees, build orders. ~40 SLoC.

Total expansion: ~350-400 SLoC of additional graph algorithms.

### 20. Compute Arrays / DataFrame

| Aspect | Current | Recommendation |
|---|---|---|
| NdArray (1D/2D/3D) | Hand-rolled (1,439 SLoC) | **KEEP NATIVE — EXPAND** |
| DataFrame | Hand-rolled (2,268 SLoC) | **KEEP NATIVE** |

**Compute expansion** (inspired by ndarray, keep native):
- **Cumulative sum / cumulative product** along axes.
- **Argsort** / partial sort along axes.
- **Histogram** / binning with configurable bin edges.
- **Linear interpolation** (`lerp`) and bilinear interpolation on 2D arrays.
- **Clamp** to min/max range.
- **Normalize** to [0, 1] or [-1, 1] range.
- **Dot product** for 1D arrays.

**GPU compute acceleration**: For large arrays (>100K elements), wgpu compute shaders can parallelize matmul, convolution, and element-wise operations. This uses the existing wgpu dependency — zero additional binary cost. Expose via `luna.compute.gpuMatmul(a, b)`.

### 21. Noise / Procedural Generation

| Aspect | Current | Recommendation |
|---|---|---|
| Perlin/Simplex/Worley/FBM | Hand-rolled | **KEEP NATIVE — EXPAND** |

**Native expansion** — new noise features:
- **Value noise** — grid-based interpolated noise, simpler than Perlin. ~40 SLoC.
- **Blue noise / Poisson disk sampling** — for natural-looking object placement (trees, rocks, NPCs). ~80 SLoC.
- **Voronoi diagram generation** — biome boundaries, territory maps, shattered glass effects. ~100 SLoC.
- **Wave Function Collapse (WFC)** — constraint-based procedural level generation. Input: small example patterns. Output: large consistent maps. ~300-500 SLoC.
- **Cellular automata** — cave/dungeon generation with configurable rules. Already partially in procgen — expand with more rule presets (B3/S23, B5678/S45678, etc.). ~60 SLoC.
- **Gradient ramp / color mapping** — map noise values to color gradients for terrain visualization. ~30 SLoC.
- **Noise combination operators** — add, multiply, min, max, power of two noise generators. ~40 SLoC.

Total expansion: ~650-850 SLoC of additional noise/procgen algorithms.

### 22. Tweening / Easing / Animation

| Aspect | Current | Recommendation |
|---|---|---|
| Easing functions (22) | Hand-rolled | **EXPAND** — add 10+ more curves |
| Tween interpolator | Hand-rolled | **EXPAND** — more features |
| Sprite animation | Hand-rolled | **EXPAND** — more animation types |

**Easing expansion** — add these beyond the existing 22:
- `ease_in_out_elastic`, `ease_in_out_bounce`, `ease_in_out_back` — complete all families
- `ease_in_circ`, `ease_out_circ`, `ease_in_out_circ` — circular ease
- `spring(damping, frequency, t)` — spring physics simulation
- `smooth_step(t)` — Hermite S-curve (3t² - 2t³)
- `smoother_step(t)` — improved S-curve (6t⁵ - 15t⁴ + 10t³)
- `bezier(p1x, p1y, p2x, p2y, t)` — cubic Bézier easing
- `catmull_rom(p0, p1, p2, p3, t)` — Catmull-Rom spline

**Tween expansion**:
- **Sequence tweens**: Chain multiple tweens end-to-end with optional delays.
- **Parallel tweens**: Run multiple tweens simultaneously on different properties.
- **Repeat / yoyo**: Repeat N times or ping-pong back and forth.
- **Tween callbacks**: `onStart`, `onComplete`, `onRepeat`, `onUpdate` hooks.
- **Color tweening**: Interpolate between colors in HSL space for smooth color transitions.
- **Path tweening**: Interpolate along a series of waypoints with optional smoothing.

**Sprite animation expansion**:
- **Animation events**: Fire callbacks at specific frames ("footstep" at frame 3, "attack_hit" at frame 5).
- **Animation blending**: Crossfade between two animations over N frames.
- **Animation state machine**: Define states (idle → walk → run → jump) with transitions and conditions.
- **Ping-pong playback**: Play forward then backward for seamless loops.
- **Speed curve**: Non-linear playback speed per animation (slow-mo hit frames).

### 23. Serialization

| Aspect | Current | Recommendation |
|---|---|---|
| JSON | serde_json 1 | **KEEP** — read and write JSON files |
| TOML | — | **ADD `toml` 0.8** — preferred config format (Tier 1) |
| Lua tables | mlua native | **KEEP** — `luna.filesystem.load()` for Lua data files |
| Binary dump | — | **ADD NATIVE** — simple binary serialization |

**Serialization API surface**:
- `luna.data.encodeJSON(table) → string` — Lua table to JSON string
- `luna.data.decodeJSON(string) → table` — JSON string to Lua table
- `luna.data.encodeToml(table) → string` — Lua table to TOML string
- `luna.data.parseToml(string) → table` — TOML string to Lua table
- `luna.data.encodeBinary(table) → ByteData` — simple binary dump (native, ~200 SLoC)
- `luna.data.decodeBinary(ByteData) → table` — binary load
- `luna.filesystem.load(path)` — load and execute Lua file, return its result table

**Binary dump format** (native implementation):
A simple tagged binary format for game save data. Type-length-value encoding:
- `0x01` nil, `0x02` boolean, `0x03` integer (i64), `0x04` number (f64), `0x05` string (length-prefixed), `0x06` table (key-value pairs terminated by 0x00).
- No external crate needed. ~200 SLoC.

**Why NOT rmp-serde**: MessagePack would add a dependency for a format game developers rarely choose themselves. The native binary dump is simpler, Luna2D-specific, and sufficient for save data. If MessagePack is needed in the future, add it then.

### 24. Networking

| Aspect | Current | Recommendation |
|---|---|---|
| Game networking | Not implemented | **Tier 3 feature**: CONSIDER `message-io` 0.19 |

`message-io` (3.6K SLoC, 141 KiB) provides TCP/UDP/WebSocket with a simple non-async API. Perfect for game networking without pulling in the tokio ecosystem. Feature-gate as `networking`.

**Implementation will happen in a future phase.** For now, keep as a documented recommendation.

### 25. Logging

| Aspect | Current | Recommendation |
|---|---|---|
| Log facade | log 0.4 | **KEEP** |
| Log backend | env_logger 0.10 | **BUMP to 0.11** |

**Logging strategy — expanded for AI agent consumption**:

The user needs logging that serves two purposes:
1. **Human debugging** — readable console output during development.
2. **AI analytics** — structured log data that AI agents can parse to understand game behavior.

**Implementation plan (native, no additional crates)**:

- **Structured log format**: Implement a custom `log` backend (or wrap `env_logger`) that outputs JSON-structured log lines when `LUNA_LOG_FORMAT=json` is set. Format: `{"ts":"ISO8601","level":"INFO","module":"physics","msg":"step complete","dt_ms":16.2}`.
- **Log levels**: Use standard `log` crate levels (`error`, `warn`, `info`, `debug`, `trace`).
- **Log categories/tags**: Add a `target` field to all engine log calls. Categories: `engine`, `graphics`, `audio`, `physics`, `input`, `lua`, `timer`, `filesystem`, `ai`, `scene`, `entity`, `tilemap`.
- **Lua-side logging**: `luna.log.info(msg)`, `luna.log.warn(msg)`, `luna.log.error(msg)`, `luna.log.debug(msg)` — game scripts can write to the same log stream.
- **Log file output**: `luna.log.setFile(path)` — redirect log output to a file for post-mortem analysis. Append mode, with session start marker.
- **Performance logging**: `luna.log.perf(label, fn)` — time a function and log the duration. For profiling specific game operations.
- **AI-friendly analytics**: `luna.log.event(category, data_table)` — structured event logging. Example: `luna.log.event("combat", {attacker="player", damage=25, target="goblin_3"})`. These entries are JSON-formatted for easy parsing by AI agents.

**Why NOT tracing**: tracing (452 KiB) adds structured logging, async spans, and subscriber framework — all unnecessary for a synchronous game engine. The native JSON log format achieves the same AI-readable output with zero additional dependencies.

### 26. Clipboard / Dialogs

| Aspect | Current | Recommendation |
|---|---|---|
| Clipboard | arboard 3 | **KEEP** — simple clipboard is sufficient |
| File dialogs | rfd 0.14 | **BUMP to 0.17** |

Simple clipboard (copy/paste text) via `arboard` is enough. No need for advanced clipboard features.

### 27. System Info / Performance Monitoring

| Aspect | Current | Recommendation |
|---|---|---|
| System info | sysinfo 0.30 | **BUMP to 0.38** — refocused on LIVE utilization |

**Refocused purpose**: The user does NOT need static hardware info (CPU count, memory size). They need **live performance monitoring**:

- **CPU utilization %** — how much CPU is the game using right now?
- **Memory utilization %** — how much RAM is consumed vs available?
- **Disk I/O** — read/write throughput for asset loading diagnostics.
- **GPU utilization** — wgpu doesn't expose this directly, but frame time serves as a proxy.

**sysinfo 0.38 provides** (with `system` feature):
- `System::cpu_usage()` → per-core and overall CPU utilization percentage
- `System::used_memory()` / `System::total_memory()` → RAM usage
- `System::processes()` → per-process CPU/memory for the engine process
- Disk I/O read/write bytes per process

**Lua API surface**:
- `luna.system.getCpuUsage() → number` — overall CPU utilization % (0-100)
- `luna.system.getMemoryUsage() → number, number` — used MB, total MB
- `luna.system.getProcessMemory() → number` — engine process memory in MB
- `luna.system.getFrameTime() → number` — last frame duration in ms (already in timer)

**Why keep sysinfo**: Despite being ~200-400 KB, it's the only maintained crate for live CPU/memory utilization metrics on all three desktop platforms. The alternatives (`num_cpus`, `std::env`) provide only static info, not utilization.

### 28. Random Number Generation

| Aspect | Current | Recommendation |
|---|---|---|
| RNG | fastrand 2 | **KEEP** — tiny, fast, perfect for games |

Best-in-class for the use case. No changes needed.

---

## Removal Candidates

| Crate | Current Role | Why Remove | Binary Savings |
|---|---|---|---|
| **tiny-skia 0.11** | Legacy CPU renderer | Dead code. wgpu is the only active renderer. | ~200-300 KB |
| **minifb 0.27** | Legacy windowing | Dead code. winit is the only active windowing backend. | ~200-300 KB |

**Combined savings**: ~400-600 KB.

**Action**:
1. Remove `tiny-skia` and `minifb` from `[dependencies]` in Cargo.toml.
2. Remove all `use tiny_skia::*` and `use minifb::*` imports from source code.
3. Remove or archive `src/graphics/renderer.rs` (the legacy software renderer).
4. Remove any `minifb::Window` references.
5. Run `cargo build` to verify clean compilation.

---

## Version Bump Recommendations

| Crate | Current | Target | Priority | Migration Effort | Notes |
|---|---|---|---|---|---|
| wgpu | 22 | **29** | HIGH | **MAJOR** | Largest migration. API churn every release. Dedicated session required. |
| mlua | 0.9 | **0.11** | HIGH | **MAJOR** | Breaking API changes. Send/serialize feature changes. Test all Lua bindings. |
| rodio | 0.17 | **0.22** | HIGH | **MAJOR** | Symphonia backend replaces legacy decoders. Rewrite audio loading. |
| thiserror | 1 | **2** | MEDIUM | MODERATE | Derive macro changes. Update all `#[derive(Error)]` types. |
| directories | 5 | **6** | MEDIUM | MODERATE | Method renames. Update filesystem paths. |
| image | 0.24 | **0.25** | MEDIUM | MODERATE | New feature flags. Update image loading code. |
| sysinfo | 0.30 | **0.38** | MEDIUM | MODERATE | Major API restructuring. Update system_api.rs. |
| env_logger | 0.10 | **0.11** | LOW | LOW | Minor API changes. |
| lz4_flex | 0.11 | **0.13** | LOW | LOW | Non-breaking improvements. |
| rfd | 0.14 | **0.17** | LOW | LOW | Wayland fixes. Non-breaking. |
| winit | 0.30 | **0.31** | LOW | LOW | Minor changes. |
| pollster | 0.3 | **0.4** | LOW | LOW | Drop-in upgrade. |

**New additions**:

| Crate | Version | Priority | Purpose |
|---|---|---|---|
| glam | **0.30** | HIGH | SIMD-accelerated math types |
| toml | **0.8** | MEDIUM | TOML config parsing (design-assumptions.md B-05) |
| tiled | **0.15** | LOW | Tiled Map Editor import (feature-gated) |

---

## Summary Decision Matrix

| Module | SLoC | Tier | Strategy | New Crate? | Binary Impact |
|---|---|---|---|---|---|
| Graphics (wgpu) | 8,148 | 1 | External crate (BUMP) | NO (existing) | — |
| Lua API (mlua) | 18,161 | 1 | External crate (BUMP) | NO (existing) | — |
| Audio (rodio) | 1,135 | 1 | External crate (BUMP) + native effects | NO (existing) | — |
| Input (winit+gilrs) | 642 | 1 | External crate | NO (existing) | — |
| Math | 4,463 | 1-2 | **glam** + hand-rolled extensions | YES: **glam** | ~50-100 KB |
| Timer | 85 | 1 | **NATIVE** | NO | 0 |
| Filesystem | 685 | 1 | **NATIVE** | NO | 0 |
| Engine | 2,144 | 1 | **NATIVE** | NO | 0 |
| Particles | 624 | 1 | **NATIVE** | NO | 0 |
| Data/compress/hash | 249 | 1 | Mix (native + crates) | NO (existing) | — |
| Image | 188 | 1 | **NATIVE** + image crate (BUMP) | NO (existing) | — |
| Sound | 97 | 1 | **NATIVE** | NO | 0 |
| Fonts (fontdue) | — | 1 | External crate | NO (existing) | — |
| Tilemap | 2,343 | 2 | **NATIVE — EXPAND** | optional: tiled | +30-60 KB |
| Scene | 250 | 2 | **NATIVE — EXPAND** | NO | 0 |
| Pathfinding | 1,464 | 2 | **NATIVE** | NO | 0 |
| Entity/ECS | 570 | 2 | **NATIVE — EXPAND** | NO | 0 |
| AI | 1,791 | 2 | **NATIVE** | NO | 0 |
| Graph | 2,253 | 2 | **NATIVE — EXPAND** | NO | 0 |
| Compute | 1,439 | 2 | **NATIVE — EXPAND** | NO | 0 |
| DataFrame | 2,268 | 2 | **NATIVE** | NO | 0 |
| Noise/procgen | (in math) | 2 | **NATIVE — EXPAND** | NO | 0 |
| Tweening/Animation | (in math) | 2 | **NATIVE — EXPAND** | NO | 0 |
| Serialization | — | 1-2 | Mix (crates + native binary) | YES: **toml** | +50-80 KB |
| MIDI | — | 2 | Existing crate | NO (existing) | — |
| Clipboard | — | 2 | Existing crate | NO (existing) | — |
| Dialogs | — | 2 | Existing crate (BUMP) | NO (existing) | — |
| System info | — | 2 | Existing crate (BUMP) | NO (existing) | — |
| Physics (rapier2d) | 1,510 | **3** | **Feature-gated** | NO (existing, gated) | +1.5-2.5 MB |
| Networking | — | 3 | Future feature | YES: **message-io** | +200-400 KB |
| Tiled import | — | 3 | Feature-gated | YES: **tiled** | +30-60 KB |
| Zstd compression | — | 3 | Feature-gated | YES: **zstd** | +800 KB |

### Bottom Line

- **10 modules** get **native expansion** — graph, compute, noise, tilemap, scene, entity, easing, tweening, animation, audio effects
- **2 new crates** for Tier 1: `glam` (SIMD math) + `toml` (config parsing)
- **4 feature-gated crates** for Tier 3: rapier2d (existing), tiled, message-io, zstd
- **2 removed**: tiny-skia, minifb (saves ~400-600 KB)
- **7 major version bumps**: wgpu, mlua, rodio, thiserror, directories, image, sysinfo
- **5 minor version bumps**: env_logger, lz4_flex, rfd, winit, pollster
- **1 removed recommendation**: kira (replaced by native audio effects)
- **1 removed recommendation**: rmp-serde (replaced by native binary dump)

Luna2D's strategy is clear: **use crates for infrastructure** (GPU, windowing, audio playback, scripting) and **build game systems natively** (tilemap, scene, AI, physics, graph, compute, noise, animation, serialization). This gives full control over the Lua API surface while keeping binary size under 15 MB for Standard tier.

---

*Last updated: 2026-03-31 (v2). Review when adding new modules or when the Rust crate ecosystem evolves.*
