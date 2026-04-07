# Implementation Plan � Phased Performance Improvements

## Guiding Principles

1. **Eliminate work before parallelizing it** � culling > caching > threading
2. **Feature flags before code changes** � rapier `parallel` is free
3. **Threshold-gated parallelism** � don't thread small workloads
4. **Compatible with Rc<RefCell<SharedState>>** � no shared mutable state across threads
5. **Desktop laptop from 2018** � 4 cores, integrated GPU, 8 GB RAM

---

## Phase 0: Zero-Cost Wins (Effort: 1�2 days)

### 0.1 Enable rapier2d `parallel` feature
- **Change**: One line in `Cargo.toml`
- **Impact**: 2�4� physics for 50+ bodies
- **Risk**: None (rayon already transitive)
- **Files**: `Cargo.toml`
- **Test**: `cargo test --test physics_tests`

### 0.2 Add rayon as direct dependency
- **Change**: `rayon = "1.10"` in `Cargo.toml`
- **Impact**: Enables Phase 1�3 parallelism
- **Risk**: Zero binary cost (already transitive)
- **Files**: `Cargo.toml`

### 0.3 Packed vertex colors
- **Change**: `ColorVertex.color: [u8; 4]` instead of `[f32; 4]`
- **Impact**: 25% reduction in color vertex bandwidth
- **Risk**: Low � WGSL shader needs `unpack4x8unorm()`
- **Files**: `src/graphics/gpu_renderer/render_pass.rs`, vertex shader in `mod.rs`

---

## Phase 1: CPU Work Elimination (Effort: 1�2 weeks)

### 1.1 Frustum culling for DrawCommands
- **Priority**: P0
- **What**: Add AABB check before tessellation in render_pass.rs
- **Impact**: Eliminate 30�80% of tessellation for scrolling games
- **Files**: `src/graphics/gpu_renderer/render_pass.rs`
- **Test**: FPS benchmark with 5000 sprites, half off-screen

### 1.2 Chunk vertex caching for tilemaps
- **Priority**: P0
- **What**: Cache tessellated vertices per chunk, only rebuild on tile change
- **Impact**: Eliminate per-frame re-tessellation for static maps
- **Files**: `src/graphics/large_map_renderer.rs`, `src/tilemap/tilemap.rs`
- **Test**: Tilemap benchmark, measure frame time before/after

### 1.3 Spatial hash for entity visibility
- **Priority**: P1
- **What**: Grid-based spatial hash for quick viewport queries
- **Impact**: O(visible) instead of O(total) for draw command generation
- **Files**: New `src/entity/spatial_hash.rs` or `src/graphics/spatial.rs`
- **Test**: 10k entities, only 500 visible � measure draw command count

### 1.4 Adaptive circle LOD
- **Priority**: P3
- **What**: Segment count based on screen-space radius
- **Impact**: 2�4� fewer vertices for small circles
- **Files**: `src/graphics/gpu_renderer/render_pass.rs` (`tess_ellipse`)
- **Test**: 1000 small circles, vertex count reduction

---

## Phase 2: Rayon Parallelism (Effort: 1�2 weeks)

### 2.1 Particle system parallel update
- **Priority**: P1
- **What**: `par_iter_mut()` for particle position/velocity/lifetime updates
- **Threshold**: Only parallelize when `count > 1000`
- **Impact**: 4�8� for 10k+ particles
- **Files**: `src/particle/system.rs`
- **Test**: Particle benchmark, 10k and 50k particles

### 2.2 NdArray parallel element-wise ops
- **Priority**: P1
- **What**: `par_iter_mut()` for add, sub, mul, div, etc.
- **Threshold**: Only parallelize when `size > 10_000`
- **Impact**: 4�8� for 100k+ elements
- **Files**: `src/compute/ops.rs`
- **Test**: NdArray benchmark, 1M element add

### 2.3 NdArray parallel convolution
- **Priority**: P1
- **What**: Row-parallel outer loop for `convolve2d()`
- **Threshold**: Only parallelize when `rows > 64`
- **Impact**: 4�8� for 256�256+ inputs
- **Files**: `src/compute/spatial.rs`
- **Test**: 512�512 convolution benchmark

### 2.4 Influence map parallel propagation
- **Priority**: P2
- **What**: Row-parallel diffusion with double-buffer
- **Threshold**: Only parallelize when `width * height > 10_000`
- **Impact**: 4�8� for large maps
- **Files**: `src/ai/influence_map.rs`
- **Test**: 500�500 influence map propagation benchmark

### 2.5 DataFrame parallel sort
- **Priority**: P3
- **What**: `par_sort_by()` for large DataFrames
- **Threshold**: Only parallelize when `row_count > 100_000`
- **Impact**: 2�3� for 1M+ rows
- **Files**: `src/dataframe/query.rs`
- **Test**: DataFrame sort benchmark

---

## Phase 3: Async I/O & Audio (Effort: 1�2 weeks)

### 3.1 Multi-worker AsyncLoader
- **Priority**: P1
- **What**: Scale AsyncLoader to N workers (default: 2, max: 4)
- **Impact**: 2�4� faster bulk asset loading
- **Files**: `src/filesystem/async_loader.rs`
- **Test**: Load 100 texture files, measure total time

### 3.2 Async audio decoding
- **Priority**: P1
- **What**: Decode audio on background thread, poll from main
- **Impact**: Eliminates main-thread stalls during sound loading
- **Files**: `src/audio/mixer.rs`, `src/audio/decoder.rs`
- **Lua API**: `luna.audio.newSourceAsync(path)` returns handle
- **Test**: Load 10 large audio files, measure frame drops

### 3.3 Write-behind for save files
- **Priority**: P2
- **What**: Queue file writes to background thread
- **Impact**: No frame drops during autosave
- **Files**: `src/filesystem/mod.rs`, `src/savegame/`
- **Test**: Write 1MB save file, verify zero frame stall

### 3.4 Async asset Lua API
- **Priority**: P2
- **What**: `luna.gfx.newImageAsync()`, `luna.audio.newSourceAsync()`
- **Impact**: Non-blocking asset loading from game scripts
- **Files**: `src/lua_api/graphics_api.rs`, `src/lua_api/audio_api.rs`
- **Test**: Loading screen example that polls asset readiness

---

## Phase 4: GPU Optimization (Effort: 2�4 weeks)

### 4.1 GPU instanced sprite rendering
- **Priority**: P1
- **What**: Instance buffer for repeated sprites (same texture, different transforms)
- **Impact**: 100�1000� draw call reduction for particle-like effects
- **Files**: `src/graphics/gpu_renderer/`, shader changes
- **Lua API**: Automatic when using SpriteBatch, manual via `luna.gfx.newInstanceBatch()`
- **Test**: 10k sprites benchmark, draw call counter

### 4.2 Texture atlas auto-packing
- **Priority**: P2
- **What**: Runtime texture atlas packer for small textures
- **Impact**: Reduce bind group switches (fewer draw calls)
- **Files**: New `src/graphics/atlas.rs`, modify `gpu_resources.rs`
- **Test**: 200 small textures, measure draw call count

### 4.3 GPU compute for NdArray
- **Priority**: P3
- **What**: wgpu compute shaders for element-wise ops and convolution
- **Impact**: 10�100� for 100k+ elements
- **Files**: New compute pipeline in `src/graphics/gpu_renderer/`
- **Lua API**: `luna.compute.gpuAdd(a, b)` or automatic offload
- **Test**: GPU vs CPU benchmark for 1M element add

### 4.4 GPU tilemap rendering
- **Priority**: P3
- **What**: Instance-based tile rendering (tile ID grid as GPU texture)
- **Impact**: 1 draw call for entire visible tilemap
- **Files**: `src/graphics/gpu_renderer/`, new tilemap render mode
- **Test**: 1000�1000 tilemap benchmark

---

## Phase 5: Advanced Threading (Effort: 2�4 weeks)

### 5.1 Multi-agent GOAP parallel planning
- **Priority**: P2
- **What**: Rayon thread pool for independent agent planning
- **Impact**: 2�8� for 10+ agents planning simultaneously
- **Files**: `src/ai/goap.rs`, new `src/ai/parallel_planner.rs`
- **Test**: 50 agents planning, measure total plan time

### 5.2 Background physics stepping
- **Priority**: P3
- **What**: Run physics on background thread, interpolate on main thread
- **Impact**: Frees main thread for Lua + rendering
- **Files**: `src/physics/world.rs`, new interpolation layer
- **Risk**: One-frame lag, complex synchronization
- **When**: Only if physics > 2ms/frame

### 5.3 Geometry caching for static scenes
- **Priority**: P3
- **What**: Cache tessellated vertex data for non-moving draw commands
- **Impact**: Eliminate re-tessellation for backgrounds, UI
- **Files**: `src/graphics/gpu_renderer/render_pass.rs`, new cache layer
- **Lua API**: `luna.gfx.newGeometryCache()`

### 5.4 Render thread separation
- **Priority**: P4
- **What**: Double-buffer vertices, submit GPU on separate thread
- **Impact**: Overlap CPU tessellation with GPU execution
- **Risk**: High complexity, marginal gain for 2D
- **When**: Only if combined tessellate+submit > 8ms/frame

---

## Thread Budget (Target: 4-Core Laptop)

```
Phase 0�1 (Current + Culling):
  Core 0: Main thread (Lua + tessellate + GPU submit)
  Core 1: AsyncLoader (1 worker)
  Core 2: Pathfinding AsyncPool
  Core 3: (unused)

Phase 2�3 (Rayon + Async I/O):
  Core 0: Main thread (Lua + GPU submit)
  Core 1-3: Rayon pool (particles, compute, physics solver)
  Background: AsyncLoader (2 workers), audio decode

Phase 4�5 (Full):
  Core 0: Main thread (Lua + draw command generation)
  Core 1: Render prep (tessellation, if separated)
  Core 2-3: Rayon pool (physics, particles, compute, AI)
  Background: Async I/O, audio decode, chunk building
```

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Rayon overhead on small workloads | Threshold-gated: only parallelize above cutoff |
| Thread contention on SharedState | SharedState stays Rc<RefCell> on main thread; threads use channels |
| Non-deterministic physics | rapier `parallel` uses deterministic solver (same result regardless of thread count) |
| GPU compute shader compatibility | Fallback to CPU path when compute unavailable |
| Texture atlas fragmentation | Power-of-two pages, LRU eviction, configurable max atlas size |
| Background chunk pop-in | Pre-load buffer zone (2 chunks beyond viewport) |

---

## Success Metrics

| Metric | Current (est.) | Phase 1 Target | Phase 4 Target |
|--------|---------------|----------------|----------------|
| Draw calls (1000 sprites) | ~1000 | ~1000 | ~10 |
| Frame time (10k particles) | ~3ms | ~3ms | ~0.5ms |
| Asset load time (100 textures) | ~2s | ~2s | ~0.5s |
| Physics step (200 bodies) | ~1ms | ~0.3ms | ~0.3ms |
| Convolution 512�512 | ~10ms | ~10ms | ~2ms |
| Tilemap render (100�100) | ~1ms | ~0.1ms | ~0.02ms |

---

## Dependencies Between Phases

```
Phase 0 ��� Phase 2 (rayon dependency needed)
         ��� Phase 1 (independent)

Phase 1 ��� Phase 4.4 (tilemap caching before GPU tilemap)
         ��� Phase 5.3 (culling before geometry caching)

Phase 2 ��� Phase 5.1 (rayon for AI parallelism)

Phase 3 ��� Phase 3.4 (async API depends on multi-worker loader)

Phase 4 ��� Phase 4.3 (compute pipeline before GPU array ops)
```

Phases 0, 1, 2, 3 are largely independent and can proceed in parallel
across different developers/agents.
