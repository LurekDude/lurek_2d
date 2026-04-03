# Minimap & FOV — GPU Compute Shader Opportunities

## Module Covered
- `src/minimap/mod.rs` — minimap content extraction, FOV mask, tile sampling

---

## Current State

The minimap module computes a visibility mask (fog-of-war) and renders
a small overview of the game world. These two operations are the
dominant cost:

1. **FOV computation** — determines which tiles the player can see
2. **Minimap pixel generation** — samples terrain/owner/unit data per pixel

---

## FOV Computation

### The Problem

Shadow-casting FOV or raycasting visibility is computed on the CPU:
- For a vision radius of 30 tiles, the algorithm must evaluate ~2,827 cells
- For multiple units (e.g., 10 units with individual FOV), that's **28,270
  cell evaluations per frame**
- Uses `.retain()` and nested loops over potentially visited cells

### Option A: rayon Parallel Raycasting

Each ray is independent from all other rays — perfect for parallelism:

```rust
// src/minimap/mod.rs
use rayon::prelude::*;

pub fn compute_fov_raycasting(
    world: &TileMap,
    origin: (u32, u32),
    radius: u32,
    output: &mut FovMask,
) {
    let num_rays = (radius * 8) as usize;  // rays around 360°
    let visible: Vec<(u32, u32)> = (0..num_rays)
        .into_par_iter()
        .flat_map(|ray_idx| {
            let angle = (ray_idx as f32 / num_rays as f32) * std::f32::consts::TAU;
            cast_ray(world, origin, radius, angle)
        })
        .collect();
    output.clear();
    for cell in visible { output.set_visible(cell.0, cell.1); }
}
```

**Speedup**: 4× per unit. For 10 units (entirely independent): 40× total.

### Option B: GPU Compute Shader (Highest ROI)

FOV raycasting is embarrassingly parallel per-ray — ideal for GPU:

```wgsl
// fov_raycast.wgsl
@group(0) @binding(0) var<storage, read> tilemap: array<u32>;       // tile passability
@group(0) @binding(1) var<storage, read_write> fov_mask: array<u32>; // output bitmask
@group(0) @binding(2) var<uniform> params: FovParams;

struct FovParams {
    origin: vec2<u32>,
    radius: u32,
    map_width: u32,
}

@compute @workgroup_size(64)
fn cast_fov(@builtin(global_invocation_id) id: vec3<u32>) {
    let ray = id.x;
    let total_rays = params.radius * 8u;
    let angle = f32(ray) / f32(total_rays) * 6.2831853;
    let dx = cos(angle);
    let dy = sin(angle);
    var pos = vec2<f32>(f32(params.origin.x), f32(params.origin.y));
    for (var step = 0u; step < params.radius; step++) {
        pos += vec2<f32>(dx, dy);
        let cell = vec2<u32>(u32(pos.x), u32(pos.y));
        // Mark visible
        let idx = cell.y * params.map_width + cell.x;
        atomicOr(&fov_mask[idx / 32u], 1u << (idx % 32u));
        // Stop at opaque tile
        if tilemap[idx] != 0u { break; }
    }
}
```

**Performance**: 240 rays × 30 steps × 10 units = 72,000 ops.
GPU handles all 72,000 in parallel in ~0.1ms vs ~15ms CPU.

---

## Minimap Texture Generation

### Current Problem

Minimap renders by iterating all visible tiles and writing pixel colors:
```rust
for y in 0..minimap_h {
    for x in 0..minimap_w {
        let tile = sample_tile(world, x, y);
        let fog = fov_mask.is_visible(x, y);
        let color = tile_to_color(tile, fog);
        texture_data[y * minimap_w + x] = color;
    }
}
```

For a 200×200 minimap: **40,000 iterations per frame** just for the overview.

### Option A: rayon Parallel Scanlines

```rust
// src/minimap/mod.rs
use rayon::prelude::*;

pub fn render_minimap(world: &TileMap, fov: &FovMask, output: &mut MinimapTexture) {
    let width = output.width;
    output.pixels
        .par_chunks_mut(width * 4)  // one scanline per task
        .enumerate()
        .for_each(|(y, row)| {
            for x in 0..width {
                let tile = sample_tile(world, x, y);
                let visible = fov.is_visible(x as u32, y as u32);
                let color = tile_to_color(tile, visible);
                row[x*4..x*4+4].copy_from_slice(&color);
            }
        });
}
```

**Speedup**: 4× for 200×200+ minimaps.

### Option B: GPU Render Pass

Sample tilemap and FOV as GPU textures, composite in a fragment shader:

```wgsl
// minimap.wgsl — fragment shader
@fragment
fn fs_main(@builtin(position) pos: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = pos.xy / vec2<f32>(minimap_size);
    let tile_id = textureSample(tilemap_tex, samp, uv).r;
    let fog = textureSample(fov_tex, samp, uv).r;
    let base_color = tile_palette[u32(tile_id * 255.0)];
    return mix(vec4<f32>(0.0, 0.0, 0.0, 1.0), base_color, fog);
}
```

Renders entire minimap in a single GPU pass — effectively free.

---

## Multi-Unit FOV Merging

When 10 units have individual FOV masks, merge them with bitwise OR:

```rust
// CPU merge: O(mask_cells × units) = 40,000 × 10 = 400,000 ops
let merged: Vec<u32> = unit_masks.iter()
    .fold(vec![0u32; cell_count / 32], |mut acc, mask| {
        for (a, m) in acc.iter_mut().zip(mask.iter()) { *a |= m; }
        acc
    });

// rayon parallel reduce merge
let merged = unit_masks.par_iter()
    .cloned()
    .reduce(|| vec![0u32; cell_count / 32],
            |mut a, b| { a.iter_mut().zip(b.iter()).for_each(|(x, y)| *x |= y); a });
```

---

## Implementation Priority

| Opportunity | Effort | Speedup | Notes |
|-------------|--------|---------|-------|
| rayon FOV per-ray | 2 days | 4× single unit | Easy win |
| rayon multi-unit FOV | 3 days | 40× for 10 units | Very high ROI |
| rayon minimap scanlines | 2 days | 4× | Independent rows |
| GPU FOV compute shader | 1 week | 100× | Requires compute pipeline |
| GPU minimap render pass | 1 week | ~free | Reuse existing passes |
