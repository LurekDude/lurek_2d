# Province Map — Border Computation and Render Optimization

## Module Covered
- `src/province_map/` — borders.rs, core.rs, adjacency.rs

---

## Current State

Province maps in strategy games can have 100–500 provinces, each with
complex polygon borders. The `province_map` module handles:
- Border polyline extraction (CPU, per-province)
- Adjacency edge building (CPU, pairwise)
- Ownership/color queries (CPU, per-province)

---

## Border Extraction: The Main Bottleneck

```rust
// Approximate src/province_map/borders.rs
pub fn extract_all_borders(&self) -> Vec<PolylineBorder> {
    let mut borders = Vec::new();
    // O(p × neighbors × border_points)
    for province_id in self.provinces.keys() {
        for neighbor_id in self.adjacency.get(province_id).unwrap_or(&[]) {
            if let Some(edge) = self.edges.get(&(*province_id, *neighbor_id)) {
                borders.push(PolylineBorder {
                    points: edge.points.iter().map(|&p| p.to_f32()).collect(),
                    // ...
                });
            }
        }
    }
    borders
}
```

For 300 provinces × 6 neighbors × 50 border points = **90,000 point conversions**.
Called every time ownership changes (territory capture, diplomacy updates).

---

## Opportunity 1: Parallel Border Extraction

Each province's border segments are independent:

```rust
// src/province_map/borders.rs
use rayon::prelude::*;

pub fn extract_all_borders_parallel(&self) -> Vec<PolylineBorder> {
    self.provinces
        .par_iter()
        .flat_map(|(province_id, _)| {
            self.adjacency
                .get(province_id)
                .into_iter()
                .flatten()
                .filter_map(|neighbor_id| {
                    self.edges.get(&(*province_id, *neighbor_id))
                        .map(|edge| PolylineBorder {
                            points: edge.points.iter().map(|&p| p.to_f32()).collect(),
                            from: *province_id,
                            to: *neighbor_id,
                        })
                })
                .collect::<Vec<_>>()
        })
        .collect()
}
```

**Speedup**: 4× for 300+ provinces on quad-core.

---

## Opportunity 2: SIMD Point Coordinate Conversion

The `p.to_f32()` conversion (u32 tile coords → f32 world coords) is called
90,000+ times per border rebuild. Vectorize with SIMD:

```rust
// src/province_map/borders.rs
fn convert_points_simd(points: &[(u32, u32)], scale: f32) -> Vec<[f32; 2]> {
    let mut result = Vec::with_capacity(points.len());
    
    // Process 4 points at a time (4 × 2 coords = 8 f32s)
    let chunks = points.chunks_exact(4);
    let remainder = chunks.remainder();
    
    for chunk in chunks {
        // Unpack 4 (u32, u32) pairs into separate x,y arrays
        let xs: [u32; 4] = [chunk[0].0, chunk[1].0, chunk[2].0, chunk[3].0];
        let ys: [u32; 4] = [chunk[0].1, chunk[1].1, chunk[2].1, chunk[3].1];
        // Convert to f32 and scale
        for i in 0..4 {
            result.push([xs[i] as f32 * scale, ys[i] as f32 * scale]);
        }
    }
    // Handle remainder
    for &(x, y) in remainder {
        result.push([x as f32 * scale, y as f32 * scale]);
    }
    result
}
```

With `std::simd` for real SIMD:
```rust
use std::simd::{u32x4, f32x4};
let x_u32 = u32x4::from_array([...]);
let x_f32: f32x4 = x_u32.cast();  // SIMD u32 → f32
```

---

## Opportunity 3: Province Map Color Texture (GPU)

Instead of extracting border polylines and drawing them as lines (CPU
tessellation into draw commands), generate a province color texture on GPU:

### Approach: Province ID Texture

During map generation, create a 512×512 province ID texture where each
texel stores the province ID for that world tile. Store as `r32uint`.

At render time, sample this texture + province owner lookup:

```wgsl
// province_render.wgsl
@fragment
fn draw_province(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let province_id = u32(textureSample(province_id_tex, samp, uv).r * 65535.0);
    let owner_color = province_colors[province_id];  // uniform array
    let adjacency_darkening = border_proximity(uv);  // edge darkening
    return vec4<f32>(owner_color * (1.0 - adjacency_darkening * 0.3), 1.0);
}
```

**Result**: Zero CPU border extraction. Province colors update by writing to
a uniform array (one `write_buffer` per frame when ownership changes).

### Border Detection in Shader

Borders between provinces detected in the fragment shader by sampling
neighboring pixels:
```wgsl
fn border_proximity(uv: vec2<f32>) -> f32 {
    let p  = sample_province(uv);
    let px = sample_province(uv + vec2<f32>(texel_size, 0.0));
    let py = sample_province(uv + vec2<f32>(0.0, texel_size));
    return f32(p != px || p != py);  // 1 at border, 0 inside
}
```

---

## Opportunity 4: Cache Border Geometry

Borders only change when provinces are built/destroyed (map setup) or
when borders are redrawn (diplomatic map mode). Cache tessellated vertex
data and only rebuild when ownership changes:

```rust
// src/province_map/core.rs
pub struct ProvinceMap {
    cached_borders: Option<Vec<PolylineBorder>>,
    borders_dirty:  bool,
}

impl ProvinceMap {
    pub fn get_borders(&mut self) -> &[PolylineBorder] {
        if self.borders_dirty || self.cached_borders.is_none() {
            self.cached_borders = Some(self.extract_all_borders_parallel());
            self.borders_dirty = false;
        }
        self.cached_borders.as_ref().unwrap()
    }
    
    pub fn capture(&mut self, province: ProvinceId, new_owner: OwnerId) {
        self.provinces[province].owner = new_owner;
        self.borders_dirty = true;  // trigger rebuild on next get_borders()
    }
}
```

**Result**: Border extraction runs **once per capture event** instead of
once per frame. For a turn-based game: max one rebuild per turn.

---

## Summary

| Optimization | Effort | Speedup | Mode |
|--------------|--------|---------|------|
| Parallel border extraction | 2 days | 4× | rayon |
| SIMD point conversion | 2 days | 2–4× | SIMD u32x4 |
| Province color texture | 1 week | eliminate CPU work | GPU |
| Border detection in shader | 3 days | eliminate CPU lines | WGSL |
| Dirty flag border cache | 1 day | 100× (skip per-frame) | Algorithmic |
