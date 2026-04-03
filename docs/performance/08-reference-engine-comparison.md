# Reference Engine Comparison — Threading & GPU Patterns

## Overview

This report compares Luna2D's current threading and GPU usage against
reference engines documented in `docs/competition/` and `docs/future/`.

---

## Threading Architecture Comparison

### Love2D (Lua + C++, OpenGL)

| Feature | Love2D | Luna2D | Gap |
|---------|--------|--------|-----|
| Main thread model | Single Lua thread | Single Lua thread | Same ✅ |
| Background threads | `love.thread.newThread()` | `luna.thread.new()` | Same ✅ |
| Inter-thread comms | `love.thread.Channel` | `Channel` + `Arc<Mutex>` | Same ✅ |
| Audio threading | SDL_mixer internal thread | Rodio internal thread | Same ✅ |
| Asset loading | Synchronous | AsyncLoader (1 worker) | Luna2D ahead ✅ |
| Physics threading | Box2D (single-threaded) | rapier2d (parallel available) | Luna2D ahead ✅ |
| Render threading | OpenGL single-context | wgpu (could multi-thread) | Luna2D ahead ✅ |
| Pathfinding | No built-in | AsyncPool (threaded) | Luna2D ahead ✅ |

**Key Insight**: Luna2D already has more threading infrastructure than Love2D.
The gap is in **utilization** — the infrastructure exists but many modules
don't use it yet.

### Corona SDK / Solar2D (Lua + C++, OpenGL ES)

| Feature | Solar2D | Luna2D | Gap |
|---------|---------|--------|-----|
| Main thread model | Single Lua thread | Single Lua thread | Same ✅ |
| Background threads | Limited (timers only) | Full thread pool | Luna2D ahead ✅ |
| Async loading | Network async only | File async | Luna2D ahead ✅ |
| Scene graph | Retained-mode display tree | Immediate-mode commands | Different approach |
| GPU batching | Automatic by material | By texture+blend+shader | Similar |
| Physics | Box2D (single-threaded) | rapier2d | Luna2D ahead ✅ |

**Key Insight**: Solar2D primarily targets mobile with minimal threading.
Luna2D's desktop-first approach allows much more aggressive threading.

### ggez (Rust, wgpu)

| Feature | ggez | Luna2D | Gap |
|---------|------|--------|-----|
| GPU backend | wgpu | wgpu 22 | Same ✅ |
| SpriteBatch | `InstanceArray` (GPU instancing) | SpriteBatch (CPU verts) | ggez ahead ❌ |
| Vertex format | 40 bytes (packed color) | Variable (f32 colors) | ggez ahead ❌ |
| Pipeline caching | 32 cached pipelines | Similar | Same ✅ |
| Threading | None explicit | AsyncLoader + pools | Luna2D ahead ✅ |

**Key Insight**: ggez's GPU instancing (`InstanceArray`) is a significant
rendering optimization Luna2D should adopt. Drawing 1000 identical sprites
uses 1 draw call in ggez vs potentially 1000 in Luna2D.

### macroquad (Rust, miniquad)

| Feature | macroquad | Luna2D | Gap |
|---------|-----------|--------|-----|
| Vertex format | 20 bytes/vert (2D optimized) | ~32 bytes/vert | macroquad ahead ❌ |
| Index buffers | 4 verts + 6 indices per quad | 4 verts + 6 indices | Same ✅ |
| Auto-batching | By texture+pipeline+viewport | By texture+blend+shader | Same ✅ |
| Draw call cost | Minimal (tiny GPU backend) | wgpu overhead | macroquad lighter |
| Threading | None | AsyncLoader + pools | Luna2D ahead ✅ |

**Key Insight**: macroquad's 20-byte vertex for 2D reduces GPU bandwidth
significantly. Luna2D could adopt packed color formats (`[u8; 4]` instead of
`[f32; 4]`) for 25% vertex size reduction.

### Bevy (Rust, wgpu, ECS)

| Feature | Bevy | Luna2D | Gap |
|---------|------|--------|-----|
| Architecture | ECS (data-oriented) | Immediate-mode + SlotMap | Different |
| Threading | Parallel systems (rayon) | Mostly main-thread | Bevy far ahead ❌ |
| GPU instancing | Automatic batching | Manual SpriteBatch | Bevy ahead ❌ |
| Render graph | Multi-pass, multi-thread render | Single-pass, single-thread | Bevy ahead ❌ |
| Compute shaders | Supported | Not used | Bevy ahead ❌ |

**Key Insight**: Bevy's ECS architecture enables automatic system parallelism.
Luna2D's Lua-first design intentionally avoids ECS complexity, but can adopt
specific Bevy patterns (instanced rendering, parallel compute) selectively.

---

## GPU Rendering Comparison

### Draw Call Efficiency

| Engine | Draw Calls for 1000 unique sprites |
|--------|-------------------------------------|
| Love2D | ~1000 (one per sprite) |
| Solar2D | ~50-200 (display tree batching) |
| ggez | ~1 (if same texture: InstanceArray) |
| macroquad | ~1000 (one per texture switch) |
| Bevy | ~1-10 (automatic instancing + atlas) |
| **Luna2D** | **~1000 (no auto-atlasing)** |

### Vertex Format Efficiency

| Engine | Bytes/Vertex | Color Format | 2D Optimized? |
|--------|--------------|--------------|---------------|
| Love2D | ~32 | f32×4 | No |
| ggez | 40 | u8×4 packed | Partially |
| macroquad | 20 | u8×4 packed | Yes |
| Bevy | 32 | u8×4 packed | No (3D vertex) |
| **Luna2D ColorVertex** | **24** | **f32×4** | **Partially** |
| **Luna2D TexVertex** | **48** | **f32×4** | **No** |

### Culling Strategy

| Engine | Frustum Cull | Tile Cull | LOD |
|--------|-------------|-----------|-----|
| Love2D | None | Manual | None |
| Solar2D | Display tree bounds | Layer-based | None |
| ggez | None | Manual | None |
| macroquad | None | Manual | None |
| Bevy | Automatic AABB | Automatic | Mipmap |
| **Luna2D** | **None (all tessellated)** | **Viewport rect** | **None** |

---

## Threading Pattern Comparison

### File I/O

| Engine | Pattern | Workers |
|--------|---------|---------|
| Love2D | Synchronous | 0 |
| Solar2D | Network async, file sync | 0 |
| Godot 4 | ResourceLoader (threaded) | 1-4 |
| Unity | Addressables (async) | Pool |
| **Luna2D** | **AsyncLoader** | **1** |

### Audio

| Engine | Decode Thread | Playback Thread | DSP Thread |
|--------|--------------|-----------------|------------|
| Love2D | Main thread | SDL_mixer thread | None |
| Solar2D | Main thread | OpenAL thread | None |
| Godot 4 | Background | Audio server | None |
| Unity | Background | FMOD/Wwise thread | DSP graph |
| **Luna2D** | **Main thread ❌** | **Rodio thread** | **None** |

### Physics

| Engine | Solver Threading | Feature |
|--------|-----------------|---------|
| Love2D | Box2D (single) | None |
| Solar2D | Box2D (single) | None |
| Godot 4 | Jolt (threaded) | Automatic |
| Unity | PhysX (threaded) | Job system |
| Bevy | rapier (parallel) | `features=["parallel"]` |
| **Luna2D** | **rapier (single) ❌** | **Available but not enabled** |

### AI / Pathfinding

| Engine | AI Threading | Pathfinding Threading |
|--------|-------------|----------------------|
| Love2D | None built-in | None built-in |
| Solar2D | None | None |
| Godot 4 | None (user threads) | NavigationServer (threaded) |
| Unity | NavMesh (threaded) | Job system |
| **Luna2D** | **Single-threaded ❌** | **AsyncPool ✅** |

---

## Key Lessons from Reference Engines

### Lesson 1: GPU Instancing is the Biggest Rendering Win
ggez and Bevy both demonstrate that GPU instancing reduces draw calls by
100–1000× for repeated geometry. Luna2D should prioritize this over
render thread separation.

### Lesson 2: Packed Vertex Colors Save Bandwidth
macroquad's `[u8; 4]` color (4 bytes) vs Luna2D's `[f32; 4]` (16 bytes)
saves 75% on color data per vertex. For 100k vertices, that's 1.2MB saved
per frame of GPU bandwidth.

### Lesson 3: Feature Flags Beat Code Changes
Bevy enables rapier's `parallel` feature with one Cargo.toml line. Luna2D
should do the same — it's the highest-ROI threading improvement available.

### Lesson 4: Async Loading is Table Stakes
All modern engines (Godot, Unity, Unreal) support async asset loading.
Luna2D's AsyncLoader is already ahead of Love2D/Solar2D, but needs
multi-worker scaling to match Godot/Unity.

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

| Category | Luna2D vs Love2D | Luna2D vs ggez | Luna2D vs Bevy |
|----------|-----------------|----------------|----------------|
| Thread pool | Ahead ✅ | Ahead ✅ | Behind ❌ |
| Async file I/O | Ahead ✅ | Ahead ✅ | Behind ❌ |
| GPU instancing | Behind ❌ | Behind ❌ | Far behind ❌ |
| Frustum culling | Same (none) | Same (none) | Behind ❌ |
| Physics threads | Ahead (rapier) | Ahead | Same (both rapier) |
| Vertex efficiency | Same | Behind ❌ | Same |
| Compute shaders | Same (none) | Same (none) | Behind ❌ |
| AI parallelism | Ahead ✅ | N/A | Behind ❌ |
