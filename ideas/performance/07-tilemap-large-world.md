# Tilemap & Large World — Threading & GPU Opportunities

## Current Architecture

Luna2D has two tilemap systems:

### 1. TileLayer / TileMap (src/tilemap/tilemap.rs)
- Standard 2D grid of tile IDs
- Viewport culling via `set_viewport(rect)` — skips tiles outside rect
- Per-frame rendering: iterates visible tiles, generates quads

### 2. LargeMapRenderer (src/graphics/large_map_renderer.rs)
- Chunk-based rendering (16×16 tile chunks by default)
- Camera-aware viewport culling
- Dirty flag per chunk (only rebuild changed chunks)

### 3. IsoMap (src/tilemap/isomap.rs)
- 3-layer isometric tilemap
- Diamond-grid to screen coordinate projection
- Per-tile rendering with layered draw order

---

## Current Bottlenecks

### Bottleneck 1: Per-Tile Vertex Generation Each Frame

Every visible tile generates 4 vertices + 6 indices per frame, even if
nothing changed. For a 100×100 visible area = 10,000 tiles = 40,000 verts.

```
Frame N:  iterate 10k tiles → generate 40k verts → upload → draw
Frame N+1: iterate 10k tiles → generate 40k verts → upload → draw
          (identical data if camera didn't move!)
```

### Bottleneck 2: Single-Threaded Chunk Rebuild

When a chunk is dirty (tiles changed), the rebuild happens on the main thread:
```rust
// In LargeMapRenderer
if chunk.dirty {
    chunk.vertices.clear();
    for ty in 0..chunk_size {
        for tx in 0..chunk_size {
            // Generate quad vertices for tile
        }
    }
    chunk.dirty = false;
}
```

### Bottleneck 3: No LOD for Distant Tiles

When zoomed out, every tile is still rendered at full resolution.
A 1000×1000 map zoomed to fit screen generates 1M quads even though
the screen might only have 800×600 pixels.

---

## Opportunity 1: Chunk Vertex Caching (Effort: Medium, Impact: HIGH)

### Concept
Cache the tessellated vertex data per chunk. Only re-tessellate when:
- A tile in the chunk changes
- The chunk's dirty flag is set

```rust
struct MapChunk {
    tiles: Vec<u16>,              // Tile IDs
    cached_vertices: Vec<TexVertex>,  // Pre-tessellated
    cached_indices: Vec<u32>,
    dirty: bool,
}

impl MapChunk {
    fn ensure_built(&mut self) {
        if !self.dirty { return; }
        self.cached_vertices.clear();
        self.cached_indices.clear();
        // ... tessellate tiles into cached buffers
        self.dirty = false;
    }

    fn draw(&self, vertex_buffer: &mut Vec<TexVertex>, index_buffer: &mut Vec<u32>) {
        // Append cached data — no tessellation
        vertex_buffer.extend_from_slice(&self.cached_vertices);
        index_buffer.extend(&self.cached_indices.iter().map(|i| i + base_offset));
    }
}
```

**Impact**: Eliminates re-tessellation for static maps (99% of frames for
most tile-based games). Camera movement only changes which chunks are drawn,
not the vertex data.

---

## Opportunity 2: Background Chunk Building (Effort: Medium, Impact: Medium)

### Concept
When new chunks enter the viewport (camera scroll), build their vertex data
on a background thread.

```
Main Thread                     Chunk Worker Thread
───────────                     ───────────────────
camera_moved()
  identify new visible chunks
  for each new chunk:
    send build_request ────→    receive request
                                 tessellate chunk vertices
                                 compute chunk metadata
poll_chunk_results()              send result ────→
  receive completed chunks
  insert into render list
```

### Implementation
Reuse the `AsyncLoader` pattern (mpsc channel + worker thread):

```rust
struct ChunkBuilder {
    work_tx: SyncSender<ChunkBuildRequest>,
    result_rx: Receiver<ChunkBuildResult>,
}

struct ChunkBuildRequest {
    chunk_pos: (i32, i32),
    tiles: Vec<u16>,
    tileset: Arc<TilesetData>,  // Shared read-only
}

struct ChunkBuildResult {
    chunk_pos: (i32, i32),
    vertices: Vec<TexVertex>,
    indices: Vec<u32>,
}
```

**Benefit**: Camera scrolling never causes frame stalls from chunk building.
**Tradeoff**: First frame after fast scroll may show blank chunks (pop-in).

---

## Opportunity 3: Tile LOD (Level of Detail) (Effort: High, Impact: Medium)

### Concept
When zoomed out far enough that individual tiles are < 4 pixels:
- Instead of rendering each tile, render a pre-computed lower-resolution image
- At extreme zoom, render entire chunk as a single colored quad

```
Zoom Level    Rendering Strategy
─────────     ──────────────────
> 0.5×        Full tile rendering (normal)
0.25–0.5×     2×2 tile blocks → 1 averaged quad
0.125–0.25×   4×4 tile blocks → 1 averaged quad
< 0.125×      Entire chunk → 1 colored quad (average color)
```

### Implementation
- Pre-compute LOD textures during chunk build (average 2×2, 4×4 tile colors)
- Store as additional cached vertex sets per LOD level
- Camera zoom determines which LOD to render

---

## Opportunity 4: GPU-Based Tilemap Rendering (Effort: HIGH, Impact: HIGH)

### Concept
Instead of generating 4 verts per tile on CPU, use a compute shader or
instanced rendering to draw tiles entirely on GPU.

### Approach A: Instanced Rendering
```
CPU: Upload tile ID grid as texture (u16 per cell)
GPU Vertex Shader:
  - Instance ID → grid position
  - Sample tile ID texture → UV coordinates in tileset atlas
  - Output quad vertices with correct UVs
```

**1 draw call for ALL visible tiles**, regardless of count.

### Approach B: Compute Shader Tile Meshing
```wgsl
@compute @workgroup_size(16, 16)
fn build_tile_mesh(@builtin(global_invocation_id) id: vec3<u32>) {
    let tile_x = id.x;
    let tile_y = id.y;
    let tile_id = tile_grid[tile_y * width + tile_x];

    // Compute vertex positions and UVs
    let base_idx = (tile_y * width + tile_x) * 4;
    vertices[base_idx + 0] = TexVertex { ... };
    vertices[base_idx + 1] = TexVertex { ... };
    vertices[base_idx + 2] = TexVertex { ... };
    vertices[base_idx + 3] = TexVertex { ... };
}
```

**Impact**:
- 100×100 visible tiles: 1 draw call instead of potentially hundreds
- GPU utilization goes from near-zero to productive
- CPU freed from tile vertex generation entirely

**Prerequisite**: Tileset atlas texture (all tiles packed into one texture)

---

## Opportunity 5: Spatial Partitioning for Non-Tile Objects (Effort: Medium)

### Problem
Games with large worlds have thousands of sprites (enemies, items, NPCs).
Without spatial partitioning, every sprite is evaluated for drawing each frame.

### Solution: Quadtree or Grid-Based Spatial Hash

```rust
struct SpatialGrid {
    cells: HashMap<(i32, i32), Vec<EntityId>>,
    cell_size: f32,
}

impl SpatialGrid {
    fn query_visible(&self, viewport: &Rect) -> Vec<EntityId> {
        let min_cell = self.pos_to_cell(viewport.min());
        let max_cell = self.pos_to_cell(viewport.max());
        let mut result = Vec::new();
        for cy in min_cell.1..=max_cell.1 {
            for cx in min_cell.0..=max_cell.0 {
                if let Some(entities) = self.cells.get(&(cx, cy)) {
                    result.extend(entities);
                }
            }
        }
        result
    }
}
```

**Integration with Luna2D**:
- Entities register their world position in the spatial grid
- Each frame, query grid with camera viewport
- Only visible entities generate draw commands

**Impact**: O(visible) instead of O(total) for draw command generation

---

## Opportunity 6: Chunk Streaming for Infinite/Large Maps (Effort: High)

### Concept
For very large maps (1000×1000+ tiles), don't load the entire map into memory.
Stream chunks from disk as the camera approaches them.

```
Memory Layout:
  ┌─────────────────────────────┐
  │  5×5 chunk ring buffer      │
  │  around camera position     │
  │                             │
  │    [C][C][C][C][C]          │
  │    [C][C][X][C][C]  ← X = camera chunk
  │    [C][C][C][C][C]          │
  │    [C][C][C][C][C]          │
  │    [C][C][C][C][C]          │
  └─────────────────────────────┘

  Chunks outside ring: unloaded from memory
  Chunks entering ring: loaded from disk (async)
  Chunks in ring: ready for rendering
```

**Threading**: Use `AsyncLoader` to load chunk data from disk files.
Combine with Opportunity 2 (background chunk building) for zero-stall streaming.

---

## Opportunity 7: Isometric Map Optimization (Effort: Medium)

### Current IsoMap Issues
- Diamond-grid coordinate conversion done per-tile per-frame
- 3 layers rendered separately (ground, objects, sky)
- No back-to-front sorting optimization (painter's algorithm)

### Solutions
- **Pre-compute screen positions**: Store iso→screen conversion per tile at map load
- **Depth buffer**: Use wgpu depth testing instead of painter's algorithm
- **Layer batching**: All ground tiles in one batch, all object tiles in another

---

## Summary

| Opportunity | Effort | Impact | Priority |
|-------------|--------|--------|----------|
| Chunk vertex caching | Medium | **HIGH** | **P0** |
| Background chunk building | Medium | Medium | **P1** |
| Spatial partitioning (sprites) | Medium | **HIGH** | **P1** |
| GPU instanced tilemap rendering | High | **HIGH** | **P2** |
| Tile LOD for zoom-out | High | Medium | **P3** |
| Chunk streaming (infinite maps) | High | Medium (niche) | **P3** |
| Isometric optimization | Medium | Medium | **P3** |
| GPU compute tile meshing | High | High | **P4** |
