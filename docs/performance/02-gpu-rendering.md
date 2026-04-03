# GPU Rendering Pipeline — Performance & Threading

## Current Architecture

Luna2D renders via wgpu 22 with this per-frame pipeline:

```
luna.draw() Lua callback
    ↓ pushes DrawCommand variants to Vec<DrawCommand>
CPU tessellation (render_pass.rs)
    ↓ converts DrawCommand → ColorVertex / TexVertex arrays
Batch assembly
    ↓ groups by (texture, blend, shader, target) → PreparedDraw
GPU buffer upload
    ↓ queue.write_buffer() for verts + indices
Render pass execution
    ↓ sequential draw calls per batch
Present
```

### Pre-Allocated GPU Buffers
```rust
MAX_COLOR_VERTS = 131,072 vertices  (1 MB)
MAX_COLOR_IDXS  = 524,288 indices   (2 MB)
MAX_TEX_VERTS   = 16,384 vertices   (256 KB)
MAX_TEX_IDXS    = 65,536 indices    (256 KB)
```
No per-frame heap allocation — buffers reused each frame. This is good.

### Current Bottlenecks

| Bottleneck | Impact | Location |
|------------|--------|----------|
| No frustum culling | All geometry tessellated, even off-screen | render_pass.rs main loop |
| Texture switching | 1 draw call per unique texture | render_pass.rs batch flush |
| CPU re-tessellation | Static geometry rebuilt every frame | render_pass.rs tess_* functions |
| Fixed circle LOD | 32 segments always, even for tiny circles | render_pass.rs tess_ellipse() |
| No instancing | Repeated sprites tessellated individually | render_pass.rs DrawImage |
| Transform stack on CPU | Matrix composition per vertex | render_pass.rs transform_stack |

---

## Opportunity 1: Frustum/Viewport Culling (Effort: Medium, Impact: HIGH)

### Problem
Every `DrawCommand` is tessellated into vertices regardless of whether it's
visible. A game drawing 1000 sprites on a scrollable map tessellates all 1000
even if only 100 are on screen.

### Solution
Before tessellation, check if the draw command's AABB intersects the camera
viewport. Skip tessellation entirely for off-screen objects.

```rust
// Pseudo-code addition to render_pass.rs main loop
for cmd in commands {
    let aabb = cmd.compute_aabb(&transform_stack);
    if !camera_viewport.intersects(aabb) {
        continue; // Skip — 100% off-screen
    }
    // ... existing tessellation code
}
```

### Expected Savings
- **Scrolling game, 5000 sprites**: ~80% of sprites off-screen → 80% less tessellation
- **Fixed-camera game**: Minimal benefit (most sprites on-screen)
- **Large tilemap**: Combined with chunk culling, eliminates entire chunks

### Implementation Notes
- Each DrawCommand variant needs an AABB calculator (trivial for Rect, Image;
  approximate for Circle, Text)
- Camera viewport is already available in `SharedState`
- `LargeMapRenderer` already does chunk-level culling — this extends it to ALL draw types

### Threading Angle
Frustum culling itself is cheap (AABB intersection = 4 comparisons). Not worth
threading. The value is in **eliminating work**, not parallelizing it.

---

## Opportunity 2: Texture Atlas / Automatic Batching (Effort: High, Impact: HIGH)

### Problem
Each unique texture in a frame triggers a batch flush + new draw call.
A sprite-heavy game drawing 200 different sprites produces 200+ draw calls.

Reference engines handle this differently:

| Engine | Approach |
|--------|----------|
| Love2D | `SpriteBatch` (user builds atlas manually) |
| ggez | `SpriteBatch` with `InstanceArray` |
| macroquad | Automatic batching by texture+pipeline state |
| Unity | Sprite Atlas asset + SRP Batcher |

### Solution A: Automatic Texture Atlas (Runtime)
At texture load time, pack small textures into shared atlas pages (e.g., 2048×2048).
Store UV regions per sub-texture. Batch all sprites using the same atlas page.

```
Before: 200 textures → 200 bind groups → 200 draw calls
After:  200 textures → 3 atlas pages → 3 draw calls
```

**Effort**: High — requires atlas packer, UV remapping, dynamic growth.
**Risk**: Large textures (>512px) don't fit well; some games use very large sprites.

### Solution B: GPU Instancing for Repeated Sprites (Medium Effort)
When the same texture is drawn multiple times with different transforms, use
wgpu instancing instead of per-sprite tessellation.

```rust
// Instead of tessellating 500 identical sprites:
// Instance buffer: [(x, y, rotation, scale, color)] × 500
// Single draw call: draw_indexed(6, 500)  // 1 quad, 500 instances
```

**Effort**: Medium — requires instance buffer management, shader changes.
**Impact**: 10–100× draw call reduction for particle-like sprite effects.

### Solution C: SpriteBatch Improvements (Low Effort)
Luna2D already has `SpriteBatch` (`src/graphics/sprite_batch.rs`). Ensure it:
- Supports add/remove individual sprites without full rebuild
- Caches vertex data between frames
- Only re-uploads dirty regions

---

## Opportunity 3: Geometry Caching (Effort: Medium, Impact: Medium)

### Problem
Static geometry (background scenery, UI elements, non-moving sprites) is
re-tessellated from `DrawCommand` → vertices every frame. This is wasted CPU work.

### Solution
Add a cached draw mode where tessellated geometry is stored and reused:

```lua
-- Lua API concept
local bg = luna.graphics.newGeometryCache()
bg:begin()
  luna.graphics.rectangle("fill", 0, 0, 800, 600)
  luna.graphics.draw(background_img, 0, 0)
bg:finish()

function luna.draw()
  bg:draw()  -- Reuses cached vertices, zero tessellation
  -- ... dynamic stuff below
end
```

### Implementation
- Store tessellated `Vec<ColorVertex>` and `Vec<TexVertex>` per cache
- On `draw()`, memcpy cached verts into frame's vertex buffer
- Invalidate cache on transform changes

### Threading Angle
Geometry caching reduces CPU work — fewer vertices to generate means the
main thread has more budget for other work.

---

## Opportunity 4: Render Thread Separation (Effort: HIGH, Impact: Medium)

### Current Model
```
Main Thread: [Lua update] → [Lua draw → tessellate] → [GPU submit] → [present]
                                                          ↑
                                                    Blocks until GPU done
```

### Proposed Model
```
Main Thread:    [Lua update N+1] → [Lua draw N+1 → tessellate]
Render Thread:  [GPU submit N] → [present N]
                 ↑ reads vertex buffer snapshot from frame N
```

### How It Works
1. Main thread writes to vertex buffer A (frame N)
2. Render thread uploads buffer A to GPU and submits
3. Main thread writes to vertex buffer B (frame N+1) while GPU processes A
4. Swap buffers each frame

### Complexity
- Double-buffered vertex arrays (2× memory, ~6 MB)
- Synchronization via fence/semaphore at frame boundary
- wgpu `Queue` is `Send` but `Device` usage rules must be respected
- Texture uploads must be sequenced with render pass

### When Worth It
Only if CPU tessellation + GPU submit takes > 8ms combined. For most 2D
games, the GPU is idle most of the time — the CPU is the bottleneck.

---

## Opportunity 5: Parallel Tessellation (Effort: Medium, Impact: Low–Medium)

### Concept
Split the DrawCommand queue into N chunks, tessellate each chunk on a
separate thread (rayon), merge results into the final vertex buffer.

```rust
let chunks: Vec<&[DrawCommand]> = commands.chunks(commands.len() / num_threads);
let results: Vec<(Vec<ColorVertex>, Vec<u32>)> = chunks
    .par_iter()
    .map(|chunk| tessellate_chunk(chunk, &transform_stack))
    .collect();
// Merge results into GPU buffer
```

### Challenges
- Transform stack is stateful (push/pop across commands) — chunking breaks it
- Blend mode / texture state changes must be preserved in order
- Merging requires index offset fixup

### Practical Limit
Works only for independent draw calls (no transform stack between them).
Could be applied to specific cases like particle rendering or tile rendering
where each element is independent.

---

## Opportunity 6: Adaptive Circle LOD (Effort: Low, Impact: Low)

### Problem
`tess_ellipse()` always generates 32 segments per circle, regardless of
screen size. A 3-pixel circle uses the same vertex count as a 300-pixel circle.

### Solution
```rust
fn segment_count(radius: f32, zoom: f32) -> u32 {
    let screen_radius = radius * zoom;
    let segments = (screen_radius * 0.5).max(8.0).min(64.0) as u32;
    // 8 segments for tiny circles, up to 64 for large ones
    segments
}
```

### Impact
For games with many small circles (particles, debug visualization), reduces
vertex count by 2–4×.

---

## Opportunity 7: GPU Compute for Post-Processing (Effort: High, Impact: Medium)

### Current PostFX Pipeline
Post-processing effects (bloom, blur, color grading) are defined in
`src/postfx/` as CPU-side config. The actual GPU application happens in
`lua_api` using additional render passes.

### Opportunity
Use wgpu compute shaders for:
- **Gaussian blur**: Separable 2-pass blur on GPU (current: CPU-side or multi-pass fragment shader)
- **Bloom**: Threshold → downsample → blur → composite (all GPU compute)
- **Color grading**: 3D LUT lookup via compute shader

### Impact
Offloads post-processing from fragment shader to compute pipeline, freeing
fragment shader bandwidth for the actual scene rendering.

## Summary Priority Matrix

| Opportunity | Effort | Impact | Priority |
|-------------|--------|--------|----------|
| Frustum culling | Medium | HIGH | **P0** |
| Texture atlas batching | High | HIGH | **P1** |
| Geometry caching | Medium | Medium | **P2** |
| GPU instancing | Medium | High (for repeated sprites) | **P2** |
| Adaptive circle LOD | Low | Low | **P3** |
| Render thread separation | High | Medium | **P3** |
| Parallel tessellation | Medium | Low–Medium | **P4** |
| GPU compute post-FX | High | Medium | **P4** |
