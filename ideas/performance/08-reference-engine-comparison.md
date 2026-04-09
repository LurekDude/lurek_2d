# Reference Engine Comparison — Threading & GPU Patterns

## Overview

This report compares Lurek2D's current threading and GPU usage against
reference engines documented in `docs/competition/` and `docs/future/`.

---

## Threading Architecture Comparison

### Engine A (Lua + C++, OpenGL)

| Feature | Engine A | Lurek2D | Gap |
|---------|--------|--------|-----|
| Main thread model | Single Lua thread | Single Lua thread | Same ✅ |
| Background threads | `love.thread.newThread()` | `lurek.thread.new()` | Same ✅ |
| Inter-thread comms | `love.thread.Channel` | `Channel` + `Arc<Mutex>` | Same ✅ |
| Audio threading | SDL_mixer internal thread | Rodio internal thread | Same ✅ |
| Asset loading | Synchronous | AsyncLoader (1 worker) | Lurek2D ahead ✅ |
| Physics threading | Box2D (single-threaded) | rapier2d (parallel available) | Lurek2D ahead ✅ |
| Render threading | OpenGL single-context | wgpu (could multi-thread) | Lurek2D ahead ✅ |
| Pathfinding | No built-in | AsyncPool (threaded) | Lurek2D ahead ✅ |

**Key Insight**: Lurek2D already has more threading infrastructure than Engine A.
The gap is in **utilization** — the infrastructure exists but many modules
don't use it yet.

### Engine B / Engine B (Lua + C++, OpenGL ES)

| Feature | Engine B | Lurek2D | Gap |
|---------|---------|--------|-----|
| Main thread model | Single Lua thread | Single Lua thread | Same ✅ |
| Background threads | Limited (timers only) | Full thread pool | Lurek2D ahead ✅ |
| Async loading | Network async only | File async | Lurek2D ahead ✅ |
| Scene graph | Retained-mode display tree | Immediate-mode commands | Different approach |
| GPU batching | Automatic by material | By texture+blend+shader | Similar |
| Physics | Box2D (single-threaded) | rapier2d | Lurek2D ahead ✅ |

**Key Insight**: Engine B primarily targets mobile with minimal threading.
Lurek2D's desktop-first approach allows much more aggressive threading.

### Engine E (Rust, wgpu)

| Feature | Engine E | Lurek2D | Gap |
|---------|------|--------|-----|
| GPU backend | wgpu | wgpu 22 | Same ✅ |
| SpriteBatch | `InstanceArray` (GPU instancing) | SpriteBatch (CPU verts) | Engine E ahead ❌ |
| Vertex format | 40 bytes (packed color) | Variable (f32 colors) | Engine E ahead ❌ |
| Pipeline caching | 32 cached pipelines | Similar | Same ✅ |
| Threading | None explicit | AsyncLoader + pools | Lurek2D ahead ✅ |

**Key Insight**: Engine E's GPU instancing (`InstanceArray`) is a significant
rendering optimization Lurek2D should adopt. Drawing 1000 identical sprites
uses 1 draw call in Engine E vs potentially 1000 in Lurek2D.

### Engine F (Rust, miniquad)

| Feature | Engine F | Lurek2D | Gap |
|---------|-----------|--------|-----|
| Vertex format | 20 bytes/vert (2D optimized) | ~32 bytes/vert | Engine F ahead ❌ |
| Index buffers | 4 verts + 6 indices per quad | 4 verts + 6 indices | Same ✅ |
| Auto-batching | By texture+pipeline+viewport | By texture+blend+shader | Same ✅ |
| Draw call cost | Minimal (tiny GPU backend) | wgpu overhead | Engine F lighter |
| Threading | None | AsyncLoader + pools | Lurek2D ahead ✅ |

**Key Insight**: Engine F's 20-byte vertex for 2D reduces GPU bandwidth
significantly. Lurek2D could adopt packed color formats (`[u8; 4]` instead of
`[f32; 4]`) for 25% vertex size reduction.

### Engine D (Rust, wgpu, ECS)

| Feature | Engine D | Lurek2D | Gap |
|---------|------|--------|-----|
| Architecture | ECS (data-oriented) | Immediate-mode + SlotMap | Different |
| Threading | Parallel systems (rayon) | Mostly main-thread | Engine D far ahead ❌ |
| GPU instancing | Automatic batching | Manual SpriteBatch | Engine D ahead ❌ |
| Render graph | Multi-pass, multi-thread render | Single-pass, single-thread | Engine D ahead ❌ |
| Compute shaders | Supported | Not used | Engine D ahead ❌ |

**Key Insight**: Engine D's ECS architecture enables automatic system parallelism.
Lurek2D's Lua-first design intentionally avoids ECS complexity, but can adopt
specific Engine D patterns (instanced rendering, parallel compute) selectively.

---

## GPU Rendering Comparison

### Draw Call Efficiency

| Engine | Draw Calls for 1000 unique sprites |
|--------|-------------------------------------|
| Engine A | ~1000 (one per sprite) |
| Engine B | ~50-200 (display tree batching) |
| Engine E | ~1 (if same texture: InstanceArray) |
| Engine F | ~1000 (one per texture switch) |
| Engine D | ~1-10 (automatic instancing + atlas) |
| **Lurek2D** | **~1000 (no auto-atlasing)** |

### Vertex Format Efficiency

| Engine | Bytes/Vertex | Color Format | 2D Optimized? |
|--------|--------------|--------------|---------------|
| Engine A | ~32 | f32×4 | No |
| Engine E | 40 | u8×4 packed | Partially |
| Engine F | 20 | u8×4 packed | Yes |
| Engine D | 32 | u8×4 packed | No (3D vertex) |
| **Lurek2D ColorVertex** | **24** | **f32×4** | **Partially** |
| **Lurek2D TexVertex** | **48** | **f32×4** | **No** |

### Culling Strategy

| Engine | Frustum Cull | Tile Cull | LOD |
|--------|-------------|-----------|-----|
| Engine A | None | Manual | None |
| Engine B | Display tree bounds | Layer-based | None |
| Engine E | None | Manual | None |
| Engine F | None | Manual | None |
| Engine D | Automatic AABB | Automatic | Mipmap |
| **Lurek2D** | **None (all tessellated)** | **Viewport rect** | **None** |

---

## Threading Pattern Comparison

### File I/O

| Engine | Pattern | Workers |
|--------|---------|---------|
| Engine A | Synchronous | 0 |
| Engine B | Network async, file sync | 0 |
| Engine C 4 | ResourceLoader (threaded) | 1-4 |
| Engine G | Addressables (async) | Pool |
| **Lurek2D** | **AsyncLoader** | **1** |

### Audio

| Engine | Decode Thread | Playback Thread | DSP Thread |
|--------|--------------|-----------------|------------|
| Engine A | Main thread | SDL_mixer thread | None |
| Engine B | Main thread | OpenAL thread | None |
| Engine C 4 | Background | Audio server | None |
| Engine G | Background | FMOD/Wwise thread | DSP graph |
| **Lurek2D** | **Main thread ❌** | **Rodio thread** | **None** |

### Physics

| Engine | Solver Threading | Feature |
|--------|-----------------|---------|
| Engine A | Box2D (single) | None |
| Engine B | Box2D (single) | None |
| Engine C 4 | Jolt (threaded) | Automatic |
| Engine G | PhysX (threaded) | Job system |
| Engine D | rapier (parallel) | `features=["parallel"]` |
| **Lurek2D** | **rapier (single) ❌** | **Available but not enabled** |

### AI / Pathfinding

| Engine | AI Threading | Pathfinding Threading |
|--------|-------------|----------------------|
| Engine A | None built-in | None built-in |
| Engine B | None | None |
| Engine C 4 | None (user threads) | NavigationServer (threaded) |
| Engine G | NavMesh (threaded) | Job system |
| **Lurek2D** | **Single-threaded ❌** | **AsyncPool ✅** |

---

## Key Lessons from Reference Engines

### Lesson 1: GPU Instancing is the Biggest Rendering Win
Engine E and Engine D both demonstrate that GPU instancing reduces draw calls by
100–1000× for repeated geometry. Lurek2D should prioritize this over
render thread separation.

### Lesson 2: Packed Vertex Colors Save Bandwidth
Engine F's `[u8; 4]` color (4 bytes) vs Lurek2D's `[f32; 4]` (16 bytes)
saves 75% on color data per vertex. For 100k vertices, that's 1.2MB saved
per frame of GPU bandwidth.

### Lesson 3: Feature Flags Beat Code Changes
Engine D enables rapier's `parallel` feature with one Cargo.toml line. Lurek2D
should do the same — it's the highest-ROI threading improvement available.

### Lesson 4: Async Loading is Table Stakes
All modern engines (Engine C, Engine G, Engine H) support async asset loading.
Lurek2D's AsyncLoader is already ahead of Engine A/Engine B, but needs
multi-worker scaling to match Engine C/Engine G.

### Lesson 5: Don't Over-Thread for 2D
2D games rarely need more than 4 threads of actual work:
1. Main thread (Lua + game logic)
2. Render prep (optional — tessellation)
3. Physics (if enabled)
4. Background I/O (async loading)

Adding more threads adds complexity without proportional benefit.
The right strategy is to **eliminate work** (culling, caching, instancing)
rather than **parallelize existing work**.

---

## Competitive Advantage Summary

| Category | Lurek2D vs Engine A | Lurek2D vs Engine E | Lurek2D vs Engine D |
|----------|-----------------|----------------|----------------|
| Thread pool | Ahead ✅ | Ahead ✅ | Behind ❌ |
| Async file I/O | Ahead ✅ | Ahead ✅ | Behind ❌ |
| GPU instancing | Behind ❌ | Behind ❌ | Far behind ❌ |
| Frustum culling | Same (none) | Same (none) | Behind ❌ |
| Physics threads | Ahead (rapier) | Ahead | Same (both rapier) |
| Vertex efficiency | Same | Behind ❌ | Same |
| Compute shaders | Same (none) | Same (none) | Behind ❌ |
| AI parallelism | Ahead ✅ | N/A | Behind ❌ |
