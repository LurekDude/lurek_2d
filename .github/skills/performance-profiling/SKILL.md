---
name: performance-profiling
description: "Load this skill when analyzing or optimizing Luna2D performance: frame time, allocations, hot paths, rendering throughput, or Lua/Rust boundary overhead. Skip it for correctness bugs or feature implementation."
---

# Performance Profiling — Luna2D Engine

## Load When

- Investigating frame rate drops or slow performance
- Analyzing per-frame memory allocations
- Optimizing hot paths in the game loop
- Measuring Lua/Rust boundary crossing overhead
- Reducing rendering or physics step time

## Owns

- Frame budget analysis (16.6ms at 60fps)
- Per-frame allocation identification and reduction
- Hot path identification in game loop
- Lua/Rust interop overhead measurement
- Rendering throughput optimization strategies

## Does Not Cover

- Correctness bugs → use `dev-debugging` skill
- Algorithm design → use the relevant domain skill
- Architecture redesign → use `module-architecture` skill

## Live Repository Contracts

- `src/engine/app.rs` — main game loop (hot path)
- `src/graphics/renderer.rs` — draw command processing (hot path)
- `src/physics/world.rs` — world step, collision detection (hot path)
- `src/timer/clock.rs` — frame timing measurement

## Decision Rules

- **Measure first**: Never optimize without profiling evidence
- **Frame budget**: 16.6ms total for input + update + draw + present at 60fps
- **Zero-alloc hot path**: Avoid `Vec::new()`, `String::from()`, `clone()` in per-frame code
- **Pre-allocate buffers**: Reuse Vec/String buffers across frames with `clear()` + reuse
- **Batch lua calls**: Minimize Lua/Rust boundary crossings per frame
- **DrawCommand as data**: DrawCommands should be cheap to create (no allocations in variants)
- **Spatial partitioning**: Use grid or quadtree for collision if body count exceeds ~50
- **Profile tools**: Use `std::time::Instant` for timing; consider `cargo flamegraph` for deep profiling
- **Texture atlas**: Batch draw calls by texture to reduce state changes in renderer

---

## Frame Budget

At 60 FPS the total frame budget is **16.6ms**. Approximate targets for integrated GPU (Intel UHD 620):

| Phase | Budget |
|-------|--------|
| Input event processing | < 0.5ms |
| `luna.update(dt)` | < 4ms |
| `luna.draw()` (Lua push commands) | < 1ms |
| `GpuRenderer::render_frame()` | < 8ms |
| Physics `world:step()` | < 3ms |
| Audio decode (background thread) | 0ms (async) |
| Headroom + present | ~0.1ms |

---

## Profiling Tools

### 1. `std::time::Instant` (built-in, no install)

Inline timing in Rust hot paths:

```rust
let t = std::time::Instant::now();
// ... code to measure ...
log::debug!("phase took {}µs", t.elapsed().as_micros());
```

Control visibility with `RUST_LOG=luna2d=debug`.

### 2. Lua-side timing

```lua
local t = luna.time.getTime()
doExpensiveThing()
print(string.format("%.2f ms", (luna.time.getTime() - t) * 1000))
```

### 3. `cargo flamegraph` (install once)

```powershell
cargo install flamegraph       # one-time install

# Record a flame graph while running a demo:
cargo flamegraph -- demos/hello_world

# Output: flamegraph.svg — open in browser to navigate hot paths
```

Requires `perf` on Linux or `dtrace` on macOS. On Windows use:

```powershell
# Windows: use Visual Studio Performance Profiler or Superluminal
# Then run: cargo build --release && build/release/luna2d.exe demos/hello_world
```

### 4. Debug overlay

Enable the built-in FPS + draw call counter:

```lua
-- conf.lua
function luna.conf(t)
    t.debug.overlay = true   -- shows FPS, draw calls, frame time in top-left
end
```

The overlay shows per-frame draw call count — the primary signal for render performance.

---

## Luna2D-Specific Hot Paths

| Hot Path | Location | Bottleneck |
|----------|----------|------------|
| DrawCommand processing | `src/graphics/gpu_renderer.rs` | Draw call count, state changes |
| Sprite batch flush | `src/graphics/sprite_batch.rs` | Vertex buffer upload size |
| Physics world step | `src/physics/world.rs` | Body + collider count |
| Lua `luna.update()` | `src/engine/app.rs` | Lua computation + GC |
| Particle system update | `src/particle/mod.rs` | Active particle count |
| Font glyph rasterization | `src/graphics/font.rs` | First-time cache miss only |
| Texture decompression | `src/graphics/texture.rs` | Load time, not per-frame |

---

## Draw Call Reduction

Draw call count is the primary render budget variable on integrated GPUs.

**Target: ≤ 200 draw calls per frame.**

### SpriteBatch (most important)

```lua
-- BAD: O(N) draw calls — one per sprite
for _, e in ipairs(entities) do
    luna.gfx.draw(e.image, e.x, e.y)   -- 1 draw call each
end

-- GOOD: 1 draw call for all sprites using the same texture
local batch = luna.gfx.newSpriteBatch(atlas_image, 1000)
function luna.process(dt)
    batch:clear()
    for _, e in ipairs(entities) do
        batch:add(e.quad, e.x, e.y)
    end
end
function luna.render()
    luna.gfx.draw(batch, 0, 0)  -- 1 draw call
end
```

### Texture atlas

Pack small sprites into a single large texture. Use `luna.gfx.newQuad()` to define sub-regions. This keeps SpriteBatch at exactly 1 draw call regardless of sprite count.

---

## Lua GC Pressure Reduction

The LuaJIT GC runs incrementally. Excessive allocation causes visible micro-stalls.

**Detect GC pressure:**

```lua
local before = collectgarbage("count")
doFrame()
local after = collectgarbage("count")
if after - before > 50 then   -- >50KB allocated this frame
    print("GC pressure: " .. (after - before) .. " KB")
end
```

**Patterns:**

```lua
-- BAD: per-frame table allocation
function luna.process(dt)
    local pos = vector(player.x, player.y)   -- new table every frame
end

-- GOOD: pre-allocate, reuse
local _pos = { x = 0, y = 0 }
function luna.process(dt)
    _pos.x = player.x
    _pos.y = player.y
    -- use _pos
end
```

---

## Physics Performance

- `world:step()` cost scales with **body count × collider complexity**
- **50+ dynamic bodies**: enable broadphase stats to confirm bottleneck
- Circle colliders are 3-5× faster than polygon colliders in narrow phase
- Use **sensors** (no collision response) for trigger zones — negligible cost
- Disable sleeping: `body:setSleepingAllowed(false)` increases cost; leave default (true)
- Destroy unused bodies immediately: `world:destroyBody(body)` — stale bodies still cost broadphase time
