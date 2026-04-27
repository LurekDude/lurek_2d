//! Destructible terrain: a bitgrid-backed static collider system for Worms-style
//! and Tanks-style terrain deformation.
//!
//! [`TerrainMap`] represents the terrain as a flat `Vec<bool>` grid.  Cell changes
//! are batched and applied to the physics world in one flush, using 16Ã—16-cell
//! *chunks* so that only modified regions are rebuilt â€” giving O(changed_chunks)
//! cost rather than O(total_cells).
//!
//! # Architecture
//! ```text
//! TerrainMap
//! â”œâ”€â”€ cells: Vec<bool>             -- flat row-major grid; true = solid
//! â”œâ”€â”€ chunk_body_ids: HashMap<ChunkId, Vec<usize>> -- rapier body IDs per chunk
//! â”œâ”€â”€ dirty_chunks: HashSet<ChunkId>
//! â””â”€â”€ cell_size: f32               -- world units per cell
//! ```
//!
//! On [`TerrainMap::flush`] each dirty chunk's cell data is examined.  Contiguous
//! solid runs produce axis-aligned box bodies in the supplied
//! [`World`](super::world::World) (row-strip merging).
//!
//! # Typical usage sequence
//! 1. `TerrainMap::new(width_cells, height_cells, cell_size)` â€” create.
//! 2. `terrain.fill_all(true); terrain.flush(&mut world)` â€” initialise as solid.
//! 3. `terrain.fill_circle(wx, wy, radius, false)` â€” dig an explosion crater.
//! 4. `terrain.flush(&mut world)` â€” re-sync with rapier.
//! 5. `let before = terrain.solid_cell_positions();`
//! 6. `terrain.collapse_columns(); terrain.flush(&mut world);`
//! 7. `let after = terrain.solid_cell_positions();` then diff for debris.

use std::collections::{HashMap, HashSet};

use super::body::{Body, BodyShape, BodyType};
use super::world::World;

// â”€â”€ Constants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Side length of a rebuild chunk in cells.
///
/// 16Ã—16 balances chunk granularity (smaller â†’ more precise dirty tracking)
/// against rapier body count (larger â†’ fewer bodies).
const CHUNK_SIZE: u32 = 16;

// â”€â”€ ChunkId â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Identifies a `CHUNK_SIZE Ã— CHUNK_SIZE` cell block by its position in chunk
/// coordinate space.
///
/// # Fields
/// - `cx` â€” Chunk column index (`cell_x / CHUNK_SIZE`).
/// - `cy` â€” Chunk row index (`cell_y / CHUNK_SIZE`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ChunkId {
    /// Chunk column index.
    pub cx: u32,
    /// Chunk row index.
    pub cy: u32,
}

// â”€â”€ TerrainMap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Bitgrid-backed destructible terrain with chunked static physics colliders.
///
/// Cells are stored row-major: `index = cy * width + cx`.  Any mutation that
/// changes a cell's solid state marks the containing 16Ã—16 chunk as dirty.
/// Colliders are rebuilt only when [`flush`](TerrainMap::flush) is called, so
/// multiple mutations in one frame incur a single rebuild pass.
///
/// # Fields
/// - `width` â€” Grid width in cells.
/// - `height` â€” Grid height in cells.
/// - `cell_size` â€” World units per cell.
/// - `offset_x` â€” World-space X origin of the terrain grid.
/// - `offset_y` â€” World-space Y origin of the terrain grid.
pub struct TerrainMap {
    /// Grid width in cells.
    pub width: u32,
    /// Grid height in cells.
    pub height: u32,
    /// World units per cell (e.g. `8.0` for 8-pixel cells).
    pub cell_size: f32,
    /// World-space X origin of the terrain grid.
    pub offset_x: f32,
    /// World-space Y origin of the terrain grid.
    pub offset_y: f32,

    cells: Vec<bool>,
    chunk_body_ids: HashMap<ChunkId, Vec<usize>>,
    dirty_chunks: HashSet<ChunkId>,
}

impl TerrainMap {
    /// Creates an empty terrain map (all cells non-solid, no dirty chunks).
    ///
    /// # Parameters
    /// - `width` â€” Grid width in cells.
    /// - `height` â€” Grid height in cells.
    /// - `cell_size` â€” World units per cell.
    ///
    /// # Returns
    /// A new `TerrainMap` with no solid cells and no physics bodies.
    pub fn new(width: u32, height: u32, cell_size: f32) -> Self {
        let total = (width * height) as usize;
        Self {
            width,
            height,
            cell_size,
            offset_x: 0.0,
            offset_y: 0.0,
            cells: vec![false; total],
            chunk_body_ids: HashMap::new(),
            dirty_chunks: HashSet::new(),
        }
    }

    // â”€â”€ Cell accessors â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Sets a single cell solid or empty, marking the containing chunk dirty.
    ///
    /// Out-of-bounds coordinates are silently ignored.
    ///
    /// # Parameters
    /// - `cx` â€” Cell column index (0-based).
    /// - `cy` â€” Cell row index (0-based).
    /// - `solid` â€” `true` = solid terrain, `false` = empty.
    pub fn set_cell(&mut self, cx: u32, cy: u32, solid: bool) {
        if cx >= self.width || cy >= self.height {
            return;
        }
        let idx = (cy * self.width + cx) as usize;
        if self.cells[idx] != solid {
            self.cells[idx] = solid;
            self.mark_dirty(cx, cy);
        }
    }

    /// Returns `true` if the cell at `(cx, cy)` is solid.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `false` for out-of-bounds coordinates.
    ///
    /// # Parameters
    /// - `cx` â€” Cell column index.
    /// - `cy` â€” Cell row index.
    pub fn get_cell(&self, cx: u32, cy: u32) -> bool {
        if cx >= self.width || cy >= self.height {
            return false;
        }
        self.cells[(cy * self.width + cx) as usize]
    }

    // â”€â”€ Bulk mutations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Fills a circle of cells centred at world position `(wx, wy)`.
    ///
    /// Converts to cell coordinates, then tests each candidate cell centre against
    /// the circle equation.  Out-of-bounds cells are skipped.
    ///
    /// # Parameters
    /// - `wx` â€” World-space X centre.
    /// - `wy` â€” World-space Y centre.
    /// - `radius` â€” World-space radius.
    /// - `solid` â€” `true` = fill in, `false` = dig/erase.
    pub fn fill_circle(&mut self, wx: f32, wy: f32, radius: f32, solid: bool) {
        let cell_cx = ((wx - self.offset_x) / self.cell_size) as i64;
        let cell_cy = ((wy - self.offset_y) / self.cell_size) as i64;
        let cell_r = (radius / self.cell_size).ceil() as i64 + 1;
        let r2 = radius * radius;

        for dy in -cell_r..=cell_r {
            for dx in -cell_r..=cell_r {
                let cx = cell_cx + dx;
                let cy = cell_cy + dy;
                if cx < 0 || cy < 0 || cx >= self.width as i64 || cy >= self.height as i64 {
                    continue;
                }
                let world_x = self.offset_x + (cx as f32 + 0.5) * self.cell_size;
                let world_y = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                let ddx = world_x - wx;
                let ddy = world_y - wy;
                if ddx * ddx + ddy * ddy <= r2 {
                    self.set_cell(cx as u32, cy as u32, solid);
                }
            }
        }
    }

    /// Fills an axis-aligned rectangle of cells whose world extent covers
    /// `(wx, wy, w, h)`.
    ///
    /// # Parameters
    /// - `wx` â€” World-space left edge.
    /// - `wy` â€” World-space top edge.
    /// - `w` â€” Width in world units.
    /// - `h` â€” Height in world units.
    /// - `solid` â€” Fill value.
    pub fn fill_rect(&mut self, wx: f32, wy: f32, w: f32, h: f32, solid: bool) {
        let x0 = ((wx - self.offset_x) / self.cell_size).floor() as i64;
        let y0 = ((wy - self.offset_y) / self.cell_size).floor() as i64;
        let x1 = ((wx + w - self.offset_x) / self.cell_size).ceil() as i64;
        let y1 = ((wy + h - self.offset_y) / self.cell_size).ceil() as i64;

        for cy in y0..y1 {
            for cx in x0..x1 {
                if cx >= 0 && cy >= 0 && cx < self.width as i64 && cy < self.height as i64 {
                    self.set_cell(cx as u32, cy as u32, solid);
                }
            }
        }
    }

    /// Sets every cell in the grid to `solid` and marks all chunks dirty.
    ///
    /// # Parameters
    /// - `solid` â€” Fill value.
    pub fn fill_all(&mut self, solid: bool) {
        for v in self.cells.iter_mut() {
            *v = solid;
        }
        let chunk_cols = self.width.div_ceil(CHUNK_SIZE);
        let chunk_rows = self.height.div_ceil(CHUNK_SIZE);
        for cy in 0..chunk_rows {
            for cx in 0..chunk_cols {
                self.dirty_chunks.insert(ChunkId { cx, cy });
            }
        }
    }

    // â”€â”€ Dirty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Returns `true` when at least one chunk is dirty and needs flushing.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_dirty(&self) -> bool {
        !self.dirty_chunks.is_empty()
    }

    fn mark_dirty(&mut self, cx: u32, cy: u32) {
        self.dirty_chunks.insert(ChunkId {
            cx: cx / CHUNK_SIZE,
            cy: cy / CHUNK_SIZE,
        });
    }

    // â”€â”€ Flush â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Rebuilds physics bodies for all dirty chunks and clears the dirty set.
    ///
    /// For each dirty chunk:
    /// 1. Destroys all existing rapier bodies that the chunk previously owned.
    /// 2. Scans for solid cells, merging contiguous horizontal runs in each row
    ///    into a single static box body (row-strip merging).
    ///
    /// Call once per frame **before** `World::step`.
    ///
    /// # Parameters
    /// - `world` â€” The physics world to synchronise.
    pub fn flush(&mut self, world: &mut World) {
        let dirty: Vec<ChunkId> = self.dirty_chunks.drain().collect();
        for chunk in dirty {
            // Destroy stale bodies.
            if let Some(old_ids) = self.chunk_body_ids.remove(&chunk) {
                for id in old_ids {
                    world.destroy_body(id);
                }
            }

            let cell_x0 = chunk.cx * CHUNK_SIZE;
            let cell_y0 = chunk.cy * CHUNK_SIZE;
            let cell_x1 = (cell_x0 + CHUNK_SIZE).min(self.width);
            let cell_y1 = (cell_y0 + CHUNK_SIZE).min(self.height);

            let mut new_ids: Vec<usize> = Vec::new();

            for cy in cell_y0..cell_y1 {
                let mut run_start: Option<u32> = None;
                for cx in cell_x0..=cell_x1 {
                    let solid = if cx < cell_x1 {
                        self.cells[(cy * self.width + cx) as usize]
                    } else {
                        false // sentinel: close the last run
                    };

                    match (solid, run_start) {
                        (true, None) => run_start = Some(cx),
                        (false, Some(start)) => {
                            let run_len = cx - start;
                            let bx = self.offset_x
                                + (start as f32 + run_len as f32 * 0.5) * self.cell_size;
                            let by = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                            let bw = run_len as f32 * self.cell_size;
                            let bh = self.cell_size;

                            let mut body = Body::new(bx, by, BodyType::Static);
                            body.shape = BodyShape::Rect {
                                width: bw,
                                height: bh,
                            };
                            body.width = bw;
                            body.height = bh;
                            body.restitution = 0.0;
                            body.friction = 0.8;

                            new_ids.push(world.add_body(body));
                            run_start = None;
                        }
                        _ => {}
                    }
                }
            }

            if !new_ids.is_empty() {
                self.chunk_body_ids.insert(chunk, new_ids);
            }
        }
    }

    // â”€â”€ Column collapse â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Removes unsupported cells, simulating gravity-driven column collapse.
    ///
    /// A cell is considered unsupported when it is solid, the cell directly below
    /// it is empty, and neither horizontal neighbour in the same row is solid.
    ///
    /// Iterates bottom-up so each pass captures only cells with no floor support.
    /// Call `flush(world)` afterwards to push the change to rapier.
    ///
    /// # Returns
    /// The number of cells removed.
    pub fn collapse_columns(&mut self) -> u32 {
        let mut count = 0u32;
        for cy in (0..self.height.saturating_sub(1)).rev() {
            for cx in 0..self.width {
                let idx = (cy * self.width + cx) as usize;
                if !self.cells[idx] {
                    continue;
                }
                let below = self.cells[((cy + 1) * self.width + cx) as usize];
                if !below {
                    let left = cx > 0 && self.cells[(cy * self.width + cx - 1) as usize];
                    let right =
                        cx + 1 < self.width && self.cells[(cy * self.width + cx + 1) as usize];
                    if !left && !right {
                        self.cells[idx] = false;
                        self.mark_dirty(cx, cy);
                        count += 1;
                    }
                }
            }
        }
        count
    }

    // â”€â”€ Debris helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Returns the world-space centres of all currently solid cells.
    ///
    /// Call *before* `collapse_columns` to capture the pre-collapse snapshot.
    ///
    /// # Returns
    /// A `Vec<(f32, f32)>` of world-space `(x, y)` centres for all solid cells.
    pub fn solid_cell_positions(&self) -> Vec<(f32, f32)> {
        let mut out = Vec::new();
        for cy in 0..self.height {
            for cx in 0..self.width {
                if self.cells[(cy * self.width + cx) as usize] {
                    let wx = self.offset_x + (cx as f32 + 0.5) * self.cell_size;
                    let wy = self.offset_y + (cy as f32 + 0.5) * self.cell_size;
                    out.push((wx, wy));
                }
            }
        }
        out
    }

    /// Spawns a dynamic debris body at each position in `positions`.
    ///
    /// Each debris body is a square the same size as one terrain cell.
    /// Intended to be called with positions of cells that just collapsed.
    ///
    /// # Parameters
    /// - `world` â€” Physics world to add debris to.
    /// - `positions` â€” World-space `(x, y)` centres.
    /// - `cell_mass` â€” Mass per debris body.
    /// - `restitution` â€” Bounciness per debris body.
    ///
    /// # Returns
    /// The body IDs of the newly-created debris bodies.
    pub fn spawn_debris_at(
        &self,
        world: &mut World,
        positions: &[(f32, f32)],
        cell_mass: f32,
        restitution: f32,
    ) -> Vec<usize> {
        positions
            .iter()
            .map(|&(wx, wy)| {
                let mut b = Body::new(wx, wy, BodyType::Dynamic);
                b.shape = BodyShape::Rect {
                    width: self.cell_size,
                    height: self.cell_size,
                };
                b.width = self.cell_size;
                b.height = self.cell_size;
                b.mass = cell_mass;
                b.restitution = restitution;
                world.add_body(b)
            })
            .collect()
    }

    // â”€â”€ Image export â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Generates an RGBA pixel buffer for the terrain grid.
    ///
    /// One pixel per cell; row-major; 4 bytes per pixel (R, G, B, A).
    ///
    /// # Parameters
    /// - `solid_rgba` â€” `[r, g, b, a]` colour for solid cells.
    /// - `empty_rgba` â€” `[r, g, b, a]` colour for empty cells.
    ///
    /// # Returns
    /// A `Vec<u8>` of length `width * height * 4`.
    pub fn to_image_data(&self, solid_rgba: [u8; 4], empty_rgba: [u8; 4]) -> Vec<u8> {
        let mut buf = Vec::with_capacity((self.width * self.height * 4) as usize);
        for &solid in &self.cells {
            let c = if solid { solid_rgba } else { empty_rgba };
            buf.extend_from_slice(&c);
        }
        buf
    }

    // â”€â”€ Serialisation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Serialises the terrain to a compact byte buffer.
    ///
    /// Format (little-endian):
    /// `[width: u32][height: u32][cell_size bits: u32][packed cell bits]`.
    /// Cell bits are MSB-first; the last byte is zero-padded.
    ///
    /// # Returns
    /// A `Vec<u8>` passable to [`from_bytes`](TerrainMap::from_bytes).
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut buf = Vec::new();
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());
        buf.extend_from_slice(&self.cell_size.to_bits().to_le_bytes());
        let mut bit_byte = 0u8;
        let mut bit_pos = 7i32;
        for &solid in &self.cells {
            if solid {
                bit_byte |= 1 << bit_pos;
            }
            bit_pos -= 1;
            if bit_pos < 0 {
                buf.push(bit_byte);
                bit_byte = 0;
                bit_pos = 7;
            }
        }
        if bit_pos < 7 {
            buf.push(bit_byte);
        }
        buf
    }

    /// Deserialises a terrain from bytes produced by [`to_bytes`](TerrainMap::to_bytes).
    ///
    /// All chunks are marked dirty so a subsequent `flush(world)` recreates all
    /// physics bodies from scratch.
    ///
    /// # Parameters
    /// - `bytes` â€” Byte slice from `to_bytes`.
    ///
    /// # Returns
    /// `Some(TerrainMap)` on success; `None` if the buffer is too short or malformed.
    #[allow(clippy::needless_range_loop)]
    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() < 12 {
            return None;
        }
        let width = u32::from_le_bytes(bytes[0..4].try_into().ok()?);
        let height = u32::from_le_bytes(bytes[4..8].try_into().ok()?);
        let cell_size_bits = u32::from_le_bytes(bytes[8..12].try_into().ok()?);
        let cell_size = f32::from_bits(cell_size_bits);
        let total = (width * height) as usize;
        let mut cells = vec![false; total];
        let bit_buf = &bytes[12..];
        for i in 0..total {
            let byte_idx = i / 8;
            let bit_idx = 7 - (i % 8);
            if let Some(&byte) = bit_buf.get(byte_idx) {
                cells[i] = (byte >> bit_idx) & 1 == 1;
            }
        }
        let chunk_cols = width.div_ceil(CHUNK_SIZE);
        let chunk_rows = height.div_ceil(CHUNK_SIZE);
        let mut dirty_chunks = HashSet::new();
        for cy in 0..chunk_rows {
            for cx in 0..chunk_cols {
                dirty_chunks.insert(ChunkId { cx, cy });
            }
        }
        Some(Self {
            width,
            height,
            cell_size,
            offset_x: 0.0,
            offset_y: 0.0,
            cells,
            chunk_body_ids: HashMap::new(),
            dirty_chunks,
        })
    }

    /// Replaces this terrain's cell data with data deserialized from `bytes`.
    ///
    /// Grid dimensions must match.  All chunks are marked dirty so a `flush` call
    /// subsequently recreates physics bodies from the new data.
    ///
    /// # Parameters
    /// - `bytes` — Byte slice produced by `to_bytes`.
    ///
    /// # Returns
    /// `true` on success; `false` if the byte slice is invalid or dimensions differ.
    pub fn load_from_bytes(&mut self, bytes: &[u8]) -> bool {
        match TerrainMap::from_bytes(bytes) {
            Some(loaded) if loaded.width == self.width && loaded.height == self.height => {
                self.cells = loaded.cells;
                self.dirty_chunks = loaded.dirty_chunks;
                true
            }
            Some(_) => false, // dimension mismatch
            None => false,
        }
    }
}
