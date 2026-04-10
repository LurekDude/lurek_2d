# Stress Test Expansion Plan

**Status**: ✅ IMPLEMENTED — All 13 planned stress tests created. 27 total stress tests now exist in `tests/lua/stress/`. All registered in `tests/lua/harness.rs`.

**Purpose**: Expand stress tests from 12 to 25+, measuring duration and performance for every module with intensive operations.

## Current Stress Tests (12)

| File | Module | What's Stressed | Metric |
|------|--------|-----------------|--------|
| test_tilemap_stress.lua | tilemap | Large map operations | Ops/sec |
| test_physics_stress.lua | physics | 10K+ body simulation | Bodies/step time |
| test_physics_collision_stress.lua | physics | Collision pair throughput | Pairs/sec |
| test_compute_stress.lua | compute | Parallel task dispatch | Tasks/sec |
| test_dataframe_stress.lua | dataframe | Large dataset operations | Rows/sec |
| test_pathfinding_stress.lua | pathfinding | Large grid A* | Paths/sec |
| test_entity_stress.lua | entity | Mass entity create/destroy | Entities/sec |
| test_particle_stress.lua | particle | Mass particle emission | Particles/frame |
| test_graph_stress.lua | graph | Large graph traversal | Nodes/sec |
| test_data_stress.lua | data | JSON/MessagePack throughput | Encode-decode/sec |
| test_data_compression_stress.lua | data | Compression throughput | MB/sec |
| test_math_stress.lua | math | Vector/matrix operations | Ops/sec |

### Modules WITHOUT stress tests (needing them):
animation, camera, savegame, scene, ai, timer, signal, filesystem, serial, procgen, tween, automation, patterns, light, terminal, modding, localization, image, effect

---

## Stress Test Template

```lua
-- Stress Test Template
-- @stress <metric_name>

describe("stress: <module> <operation>", function()
    it("<operation> × <count> completes in <budget>", function()
        local COUNT = 10000
        local start = lurek.time.getTime()

        for i = 1, COUNT do
            -- operation under test
        end

        local elapsed = lurek.time.getTime() - start
        local ops_per_sec = COUNT / elapsed

        print(string.format("[STRESS] %s: %d ops in %.3fs (%.0f ops/sec)",
            "<operation>", COUNT, elapsed, ops_per_sec))

        -- Performance gate: must complete within budget (generous for CI)
        expect_equal(true, elapsed < 10.0,
            "<operation> exceeded 10s budget: " .. elapsed .. "s")
    end)
end)

test_summary()
```

---

## New Stress Tests (13 proposed)

### 1. test_ai_stress.lua
```
Operations:
- Create 1000 agents with FSM (3 states each)
- Tick all FSMs 100 times
- Create 500 behavior trees (5 nodes each), evaluate 100 times
- Run utility AI with 100 actions × 10 considerations, decide 1000 times
Budget: 10s total
Metric: ticks/sec, decisions/sec
```

### 2. test_scene_stress.lua
```
Operations:
- Create scene graph with 10000 nodes (depth 10, fanout 10)
- Traverse full tree 100 times
- Add/remove 1000 nodes
- Transform propagation on 5000-node tree
Budget: 10s total
Metric: traversals/sec, transform updates/sec
```

### 3. test_camera_stress.lua
```
Operations:
- Create 100 cameras, each with different zoom/position
- Update all cameras 10000 times (position + zoom changes)
- World-to-screen transform × 100000
- Screen-to-world transform × 100000
Budget: 5s total
Metric: transforms/sec
```

### 4. test_savegame_stress.lua
```
Operations:
- Create large game state (1000 entities, each with 5 components)
- Serialize state 100 times
- Deserialize state 100 times
- Save + load round-trip 50 times
Budget: 10s total
Metric: serialize/sec, bytes/sec
```

### 5. test_timer_stress.lua
```
Operations:
- Create 10000 timers with different intervals
- Tick all timers 1000 times
- Create/destroy 5000 timers rapidly
- Scheduled callbacks × 10000
Budget: 5s total
Metric: timer ticks/sec
```

### 6. test_signal_stress.lua
```
Operations:
- Register 1000 listeners on same signal
- Emit signal 10000 times (all listeners fire)
- Register/unregister 5000 listeners
- 100 different signals × 100 listeners × 100 emits
Budget: 5s total
Metric: emissions/sec, dispatches/sec
```

### 7. test_animation_stress.lua
```
Operations:
- Create 1000 animations with 10 frames each
- Update all animations 10000 times
- Animation events × 10000
- Frame switching × 100000
Budget: 5s total
Metric: updates/sec
```

### 8. test_serial_stress.lua
```
Operations:
- Encode 10000 small tables (5 fields)
- Encode 100 large tables (1000 fields)
- Decode 10000 small byte sequences
- Round-trip encode-decode × 10000
Budget: 5s total
Metric: encode-decode/sec, bytes/sec
```

### 9. test_tween_stress.lua
```
Operations:
- Create 5000 active tweens simultaneously
- Update all tweens 10000 times
- Tween completion callbacks × 5000
- Chained tweens (5000 chains of 3)
Budget: 5s total
Metric: tween updates/sec
```

### 10. test_image_stress.lua
```
Operations:
- Create 100 images (256×256)
- Apply effect chain (blur + brightness + contrast) × 100
- Pixel get/set × 1000000
- Image resize × 1000
Budget: 10s total
Metric: pixel ops/sec, effects/sec
```

### 11. test_patterns_stress.lua
```
Operations:
- Observer: 1000 observers × 10000 notifications
- State machine: 5000 machines × 100 transitions each
- Command queue: 10000 commands, execute all
- Object pool: allocate/release 100000 objects
Budget: 10s total
Metric: notifications/sec, transitions/sec
```

### 12. test_filesystem_stress.lua
```
Operations:
- Write 1000 small files (1KB each)
- Read 1000 files back
- Enumerate directory with 1000 files
- Write/read 10 large files (1MB each)
Budget: 10s total
Metric: file ops/sec, MB/sec
```

### 13. test_light_stress.lua
```
Operations:
- Create 10000 point lights
- Update all light positions × 100
- Create/destroy 5000 lights
- Query visible lights in area × 10000
Budget: 5s total
Metric: light updates/sec, queries/sec
```

---

## Performance Measurement Framework

### Enhance tests/lua/init.lua with:

```lua
-- Performance measurement helper
function measure(name, count, fn)
    local start = lurek.time.getTime()
    fn()
    local elapsed = lurek.time.getTime() - start
    local ops_per_sec = count / elapsed
    print(string.format("[PERF] %s: %d ops in %.3fs (%.0f ops/sec)",
        name, count, elapsed, ops_per_sec))
    return elapsed, ops_per_sec
end
```

### Reporting

Post-execution, parse stress test output with `tools/audit/parse_test_log.py` to collect `[PERF]` lines into a performance summary:

```json
{
  "stress_results": [
    {
      "test": "test_physics_stress.lua",
      "metric": "bodies_per_step",
      "count": 10000,
      "elapsed_s": 2.34,
      "ops_per_sec": 4274,
      "passed": true
    }
  ]
}
```

---

## Summary

| Category | Current | Proposed | Net New |
|----------|---------|----------|---------|
| Stress tests | 12 | 25 | +13 |
| Modules covered | 8 | 21 | +13 |
| Performance metrics | Ad-hoc | Standardized `[PERF]` format | Framework |

---

## Phase 2 — Graphics, GPU-Compute, and Multithreaded Stress Tests (16 additional)

These tests target modules that process large volumes of visual data or are candidates for GPU offload / CPU parallelism in future engine versions.

### Why Graphics, Compute, and Thread Stress Tests Matter

The Lurek2D rendering pipeline processes a **draw-command queue** per frame. At 60 FPS, the engine has ~16.7ms per frame. A game with 10,000 sprites, lights, particles, and UI elements must build and flush the queue within that budget. Stress tests prove the Lua→Rust draw-call bridge can sustain that load without allocation pressure or GC pauses.

Modules with compute-on-GPU potential (compute, image, dataframe, pathfinding on large grids) benefit from stress tests because bottlenecks here indicate where GPU offload will have highest return.

---

### Graphics Stress Tests (7 new)

#### test_stress_graphics_draw_calls.lua
```
Target: Draw command throughput (the most critical rendering path)
Operations:
- Push 10000 rectangle draw commands per frame (50 frames)
- Push 10000 sprite draw commands per frame (50 frames)
- Push mixed batch: 3000 rects + 3000 circles + 4000 sprites × 50 frames
- Measure: draw command push time (Lua→Rust boundary), clear time

Metric: draw_calls/sec, ms/frame at 10k draw calls
Budget: 3ms per frame for 10k draw calls (60 FPS headroom)
[PERF] graphics_rect_push: 500000 ops in Xs (Y ops/sec)
[PERF] graphics_sprite_push: 500000 ops in Xs (Y ops/sec)
```

#### test_stress_graphics_canvas.lua
```
Target: Canvas render-to-texture operations
Operations:
- Create 100 canvases (512×512), fill each with solid color × 100 iterations
- Stack canvas:renderTo calls 1000 times
- getPixel on 512×512 canvas × 1000000 calls
- Canvas resize (512→256→128) × 1000 times

Metric: renderTo calls/sec, getPixel throughput MB/sec
Budget: 10s total
```

#### test_stress_graphics_sprite_batch.lua
```
Target: Sprite batch construction under load
Operations:
- Add 100000 sprites to single batch (same texture atlas)
- Rebuild batch 100 times (simulating dynamic sprite count)
- Sort 50000 sprites by z-layer 100 times
- Texture swap: alternate between 2 atlases × 10000 times (rebatch each time)

Metric: sprites batched/sec, batch rebuild time
Budget: 10s total
Note: Tests the Lua API side of batch construction - GPU upload not measured
```

#### test_stress_graphics_fonts.lua
```
Target: Text rendering command generation
Operations:
- generate 10000 print() commands with varied UTF-8 strings
- Layout 1000 strings of 200 chars each (word-wrap enabled)
- Switch between 10 different fonts × 10000 times
- Render same string in 5 sizes × 100000 total calls

Metric: text layout calls/sec
Budget: 5s total
```

#### test_stress_graphics_transform_stack.lua
```
Target: Transform push/pop operations (used in scene graph rendering)
Operations:
- Push/pop transform stack 1000000 times (translate + rotate + scale)
- Compose 10000 transform chains (depth 20)
- World-space conversion: 100000 local→world transforms
- Camera viewport transform: 100000 screen↔world conversions

Metric: transforms/sec
Budget: 5s total
```

#### test_stress_tilemap_render.lua
```
Target: Large tilemap draw-command generation
Operations:
- 500×500 tilemap, render 5 layers × 100 frames (draw command generation only)
- 16 different tile textures requiring different draw batches
- Dynamic tile animation (20 animated tiles × 1000 frames)
- Query visible tiles in viewport at 100 random camera positions

Metric: tiles_processed/sec, draw_calls generated/sec
Budget: 10s total
```

#### test_stress_postfx_chain.lua
```
Target: PostFX pipeline configuration stress
Operations:
- Build FX chain with 20 passes, configure × 10000 iterations
- Enable/disable individual passes × 100000 times
- Change effect parameters per-frame × 10000 frames (parametric animations)
- Switch between 5 preset FX chains × 10000 times

Metric: FX config ops/sec, chain switches/sec
Budget: 5s total
```

---

### Compute and GPU-Potential Stress Tests (5 new)

#### test_stress_compute_large.lua
```
Target: Compute task dispatch at scale (current CPU-backed, future GPU candidate)
Operations (expand existing test_compute_stress.lua):
- Dispatch 1000 compute tasks, each operating on 10000-element arrays
- Pipeline: 5 chained compute passes (each output feeds next)
- Concurrent: 8 independent compute tasks dispatched simultaneously
- Memory: allocate 100MB total across compute buffers, then free
- Cancellation: dispatch 1000 tasks, cancel 500 mid-flight

Metric: tasks/sec, GB/s effective memory bandwidth
Budget: 10s total
GPU future note: This test defines the minimum performance threshold that GPU offload must beat.
```

#### test_stress_image_processing.lua
```
Target: Image processing pipeline (CPU-intensive, GPU-candidate)
Operations (expand existing test_image_stress.lua):
- Batch resize: 1000 images (256×256 → 128×128) using bilinear filter
- Convolution: apply 5×5 gaussian blur to 100 images 1024×1024
- Channel operations: split + recombine RGBA × 5000 images
- Composite: alpha-blend 100 layers on 512×512 canvas × 10 times
- Histogram: compute histogram of 10000 images (256-bin)
- Pixel access: random-access 10M pixels across 100 image objects

Metric: mpixels/sec per operation type
Budget: 10s total
GPU future note: Resize, convolution, and composite are prime GPU-accelerate targets.
```

#### test_stress_pathfinding_large.lua
```
Target: A* on large grids (CPU-bound, GPU BFS experimental candidate)
Operations (expand existing test_pathfinding_stress.lua):
- 1000×1000 grid A* pathfinding × 100 random start/end pairs
- Simultaneous: 100 paths on 200×200 grid in same frame (multi-agent)
- Incremental: partial paths (10% of grid) prioritized × 10000
- Visibility graph: 500-node polygon world, all-pairs paths
- Flow field: compute for 1000×1000 grid, single target

Metric: paths/sec, cells_evaluated/sec
Budget: 10s total
GPU future note: Flow field computation (BFS from single source) is ideal for GPU parallelism.
```

#### test_stress_dataframe_large.lua
```
Target: Large dataset operations (CPU-bound, vectorization candidate)
Operations (expand existing test_dataframe_stress.lua):
- Sort 1M rows by 3 columns
- Group-by-aggregate on 1M rows, 50 groups
- Join two 500k-row DataFrames on key column
- Column arithmetic: element-wise mul/add on 1M-row float column × 100
- Rolling window: 30-period moving average on 1M-row series

Metric: rows/sec per operation, MB/s throughput
Budget: 10s total
GPU future note: Column arithmetic, rolling windows ideal for SIMD/GPU vectorization.
```

#### test_stress_serial_large.lua
```
Target: Binary serialization throughput (CPU-bound, thread-parallelism candidate)
Operations (expand existing test_serial_stress.lua):
- Encode 1GB of data in 1KB chunks (1M encode calls)
- Encode 1GB in 1MB chunks (1000 encode calls)
- Concurrent encode: 8 threads each encoding 100MB (via lurek.thread)
- Schema validation: validate 10000 complex game objects per second

Metric: MB/sec encode, MB/sec decode
Budget: 10s total
Thread note: Test concurrent encode to verify thread safety of serial module.
```

---

### Multithreaded Stress Tests (4 new)

#### test_stress_thread_throughput.lua
```
Target: Thread VM creation and Channel message throughput
Operations:
- Spawn 50 threads, each processing 1000 tasks, collect results
- Channel: send 100000 messages across 8 threads (producer-consumer)
- Fanout: 1 producer → 20 consumer threads × 10000 messages each
- Round-trip: send + receive 10000 Channel messages, measure latency
- Thread pool: 8 workers processing 100000 jobs (10ms each simulated)

Metric: messages/sec, threads/sec (create/destroy), job throughput
Budget: 30s total (thread tests are inherently slower)
```

#### test_stress_thread_data_sharing.lua
```
Target: Cross-thread data marshalling cost (via Channel serialization)
Operations:
- Send 10000 small tables (5 fields) cross-thread, measure marshal overhead
- Send 100 large tables (10000 fields) cross-thread
- Send 1MB binary blobs × 1000 times cross-thread
- Measure: serialization dominates vs Channel overhead

Metric: MB/sec effective cross-thread throughput
Budget: 10s total
Note: Identifies whether slow cross-thread comms are serialization or Channel overhead.
```

#### test_stress_entity_component_mt.lua
```
Target: Entity component system under parallel read load (if ECS supports parallel query)
Operations:
- 100000 entities with 3 components each
- Parallel query: 4 threads each iterating all entities with component X
- System update: 10 systems each processing 100000 entities × 100 frames
- Archetype change: move 10000 entities between archetypes under load

Metric: entity/component queries per second
Budget: 10s total
Note: Establishes baseline before any ECS parallelism work.
```

#### test_stress_automation_parallel.lua
```
Target: Automation module concurrent coroutine execution
Operations:
- Create 10000 coroutines, each yielding 5 times
- Resume all 10000 coroutines in sequence (single frame batch)
- Create 1000 async tasks and await all
- Composite: 100 event-driven pipelines each with 50 steps

Metric: coroutine resumes/sec, async task completions/sec
Budget: 10s total
```

---

## Updated Summary

| Category | Current | Phase 1 Plan | Phase 2 Plan | Total |
|----------|---------|-------------|-------------|-------|
| Stress tests | 12 | +13 = 25 | +16 = 41 | 41 |
| Modules/domains covered | 8 | 21 | 27 | 27 |
| Graphics-specific | 0 | 0 | 7 | 7 |
| GPU/compute-candidate | 1 (compute) | 1 | 5 | 5 |
| Multithreaded | 0 | 0 | 4 | 4 |

### Registration in harness.rs (Phase 2 additions)

```rust
// Graphics stress
#[test] fn lua_stress_graphics_draw_calls() { run_lua_test("stress/test_stress_graphics_draw_calls.lua"); }
#[test] fn lua_stress_graphics_canvas() { run_lua_test("stress/test_stress_graphics_canvas.lua"); }
#[test] fn lua_stress_graphics_sprite_batch() { run_lua_test("stress/test_stress_graphics_sprite_batch.lua"); }
#[test] fn lua_stress_graphics_fonts() { run_lua_test("stress/test_stress_graphics_fonts.lua"); }
#[test] fn lua_stress_graphics_transform_stack() { run_lua_test("stress/test_stress_graphics_transform_stack.lua"); }
#[test] fn lua_stress_tilemap_render() { run_lua_test("stress/test_stress_tilemap_render.lua"); }
#[test] fn lua_stress_postfx_chain() { run_lua_test("stress/test_stress_postfx_chain.lua"); }
// Compute/GPU-candidate stress
#[test] fn lua_stress_compute_large() { run_lua_test("stress/test_stress_compute_large.lua"); }
#[test] fn lua_stress_image_processing() { run_lua_test("stress/test_stress_image_processing.lua"); }
#[test] fn lua_stress_pathfinding_large() { run_lua_test("stress/test_stress_pathfinding_large.lua"); }
#[test] fn lua_stress_dataframe_large() { run_lua_test("stress/test_stress_dataframe_large.lua"); }
#[test] fn lua_stress_serial_large() { run_lua_test("stress/test_stress_serial_large.lua"); }
// Multithreaded stress
#[test] fn lua_stress_thread_throughput() { run_lua_test("stress/test_stress_thread_throughput.lua"); }
#[test] fn lua_stress_thread_data_sharing() { run_lua_test("stress/test_stress_thread_data_sharing.lua"); }
#[test] fn lua_stress_entity_component_mt() { run_lua_test("stress/test_stress_entity_component_mt.lua"); }
#[test] fn lua_stress_automation_parallel() { run_lua_test("stress/test_stress_automation_parallel.lua"); }
```
