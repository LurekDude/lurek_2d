//! - Province grid construction from color-mapped images, assigning unique ids per distinct RGB color.
//! - Pixel-level province id lookup and reverse color retrieval by id.
//! - Adjacency detection between neighboring provinces with shared-border-pixel counts.
//! - Horizontal span extraction for contiguous province row segments.
//! - Border segment detection returning line segments between differing province regions.
//! - Polygon tracing from directed cell edges into closed point loops per province.
//! - Polygon simplification removing collinear vertices and 45-degree staircase patterns.
//! - Binary serialization and deserialization of span and border segment shape data.
//! - Adjacency pair struct exposing province relationships for map graph queries.

use crate::image::ImageData;
use std::collections::{HashMap, HashSet};
/// Adjacency summary for two provinces and the number of shared border pixels.
pub struct AdjacencyPair {
    /// First province id in the pair.
    pub province_a: u32,
    /// Second province id in the pair.
    pub province_b: u32,
    /// Number of border pixels shared by the pair.
    pub border_pixels: u32,
}
/// Province id grid derived from image colors and cached geometry.
pub struct ProvinceGrid {
    /// Grid width in pixels.
    width: u32,
    /// Grid height in pixels.
    height: u32,
    /// Province id for each pixel in row-major order.
    ids: Vec<u32>,
    /// Cached adjacency triples of province ids and shared border count.
    adjacencies: Vec<(u32, u32, u32)>,
    /// Packed RGB color for each province id.
    id_to_color: Vec<u32>,
}
/// Grid coordinate alias used when building polygon edges.
type GridPoint = (u32, u32);
/// Directed edge alias used while tracing province polygons.
type DirectedEdge = (GridPoint, GridPoint);
impl ProvinceGrid {
    /// Build a province grid from an image where non-black pixels define province ids.
    pub fn from_image(img: &ImageData) -> Self {
        let width = img.width();
        let height = img.height();
        let pixel_count = (width * height) as usize;
        let mut color_to_id: HashMap<u32, u32> = HashMap::new();
        let mut next_id: u32 = 1;
        let mut id_to_color: Vec<u32> = vec![0u32];
        let mut ids = Vec::with_capacity(pixel_count);
        for y in 0..height {
            for x in 0..width {
                let id = if let Some((r, g, b, _)) = img.get_pixel(x, y) {
                    if r == 0 && g == 0 && b == 0 {
                        0
                    } else {
                        let key = (r as u32) << 16 | (g as u32) << 8 | b as u32;
                        *color_to_id.entry(key).or_insert_with(|| {
                            let id = next_id;
                            next_id += 1;
                            id_to_color.push(key);
                            id
                        })
                    }
                } else {
                    0
                };
                ids.push(id);
            }
        }
        let adjacencies = Self::detect_adjacencies_internal(&ids, width, height);
        log::info!(
            "ProvinceGrid: {}x{}, {} provinces, {} adjacencies",
            width,
            height,
            next_id - 1,
            adjacencies.len()
        );
        Self {
            width,
            height,
            ids,
            adjacencies,
            id_to_color,
        }
    }
    /// Load an image from disk and derive province ids from it.
    pub fn from_file(path: &str) -> Result<Self, String> {
        let img = ImageData::from_file(path)?;
        Ok(Self::from_image(&img))
    }
    /// Return the grid width in pixels.
    pub fn width(&self) -> u32 {
        self.width
    }
    /// Return the grid height in pixels.
    pub fn height(&self) -> u32 {
        self.height
    }
    /// Return the province id at a coordinate, or `0` when out of bounds.
    pub fn get_at(&self, x: u32, y: u32) -> u32 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.ids[(y * self.width + x) as usize]
    }
    /// Return the highest province id present in the grid.
    pub fn province_count(&self) -> u32 {
        self.ids.iter().copied().max().unwrap_or(0)
    }
    /// Return the RGB color associated with a province id, or `None` for id 0.
    pub fn province_color(&self, id: u32) -> Option<(u8, u8, u8)> {
        if id == 0 {
            return None;
        }
        let packed = *self.id_to_color.get(id as usize)?;
        if packed == 0 {
            return None;
        }
        let r = ((packed >> 16) & 0xFF) as u8;
        let g = ((packed >> 8) & 0xFF) as u8;
        let b = (packed & 0xFF) as u8;
        Some((r, g, b))
    }
    /// Return cached adjacency triples for the grid.
    pub fn adjacencies(&self) -> &[(u32, u32, u32)] {
        &self.adjacencies
    }
    /// Return horizontal spans for each province row segment.
    pub fn province_spans(&self) -> Vec<(u32, u32, u32, u32)> {
        let mut spans = Vec::new();
        let w = self.width as usize;
        let h = self.height as usize;
        for y in 0..h {
            let row_off = y * w;
            let mut x = 0usize;
            while x < w {
                let id = self.ids[row_off + x];
                if id == 0 {
                    x += 1;
                    continue;
                }
                let x0 = x;
                x += 1;
                while x < w && self.ids[row_off + x] == id {
                    x += 1;
                }
                spans.push((id, y as u32, x0 as u32, x as u32));
            }
        }
        spans
    }
    /// Return contiguous border segments between differing provinces.
    pub fn border_segments(&self) -> Vec<(u32, u32, u32, u32, u32, u32)> {
        let mut out = Vec::new();
        let w = self.width as usize;
        let h = self.height as usize;
        if h >= 2 {
            for y in 0..(h - 1) {
                let top_off = y * w;
                let bot_off = (y + 1) * w;
                let mut x = 0usize;
                while x < w {
                    let a = self.ids[top_off + x];
                    let b = self.ids[bot_off + x];
                    if a == 0 || b == 0 || a == b {
                        x += 1;
                        continue;
                    }
                    let pa = a.min(b);
                    let pb = a.max(b);
                    let x0 = x;
                    x += 1;
                    while x < w {
                        let aa = self.ids[top_off + x];
                        let bb = self.ids[bot_off + x];
                        if aa == 0 || bb == 0 || aa == bb {
                            break;
                        }
                        if aa.min(bb) != pa || aa.max(bb) != pb {
                            break;
                        }
                        x += 1;
                    }
                    out.push((pa, pb, x0 as u32, (y + 1) as u32, x as u32, (y + 1) as u32));
                }
            }
        }
        if w >= 2 {
            for x in 0..(w - 1) {
                let mut y = 0usize;
                while y < h {
                    let a = self.ids[y * w + x];
                    let b = self.ids[y * w + (x + 1)];
                    if a == 0 || b == 0 || a == b {
                        y += 1;
                        continue;
                    }
                    let pa = a.min(b);
                    let pb = a.max(b);
                    let y0 = y;
                    y += 1;
                    while y < h {
                        let aa = self.ids[y * w + x];
                        let bb = self.ids[y * w + (x + 1)];
                        if aa == 0 || bb == 0 || aa == bb {
                            break;
                        }
                        if aa.min(bb) != pa || aa.max(bb) != pb {
                            break;
                        }
                        y += 1;
                    }
                    out.push((pa, pb, (x + 1) as u32, y0 as u32, (x + 1) as u32, y as u32));
                }
            }
        }
        out
    }
    /// Trace province polygons as ordered point loops.
    pub fn province_polygons(&self) -> HashMap<u32, Vec<Vec<(u32, u32)>>> {
        let mut edges_by_province: HashMap<u32, Vec<DirectedEdge>> = HashMap::new();
        let w = self.width as usize;
        let h = self.height as usize;
        if w == 0 || h == 0 {
            return HashMap::new();
        }
        for y in 0..h {
            for x in 0..w {
                let id = self.ids[y * w + x];
                if id == 0 {
                    continue;
                }
                let xf = x as u32;
                let yf = y as u32;
                if y == 0 || self.ids[(y - 1) * w + x] != id {
                    edges_by_province
                        .entry(id)
                        .or_default()
                        .push(((xf, yf), (xf + 1, yf)));
                }
                if x + 1 >= w || self.ids[y * w + (x + 1)] != id {
                    edges_by_province
                        .entry(id)
                        .or_default()
                        .push(((xf + 1, yf), (xf + 1, yf + 1)));
                }
                if y + 1 >= h || self.ids[(y + 1) * w + x] != id {
                    edges_by_province
                        .entry(id)
                        .or_default()
                        .push(((xf + 1, yf + 1), (xf, yf + 1)));
                }
                if x == 0 || self.ids[y * w + (x - 1)] != id {
                    edges_by_province
                        .entry(id)
                        .or_default()
                        .push(((xf, yf + 1), (xf, yf)));
                }
            }
        }
        let mut polygons = HashMap::new();
        for (province_id, edges) in edges_by_province {
            let mut loops = Self::trace_loops_from_edges(&edges);
            loops.retain(|ring| ring.len() >= 4 && ring.first() == ring.last());
            if !loops.is_empty() {
                polygons.insert(province_id, loops);
            }
        }
        polygons
    }
    /// Return simplified province polygons with redundant vertices removed.
    pub fn province_polygons_simplified(&self) -> HashMap<u32, Vec<Vec<(u32, u32)>>> {
        let mut polygons = self.province_polygons();
        for loops in polygons.values_mut() {
            for ring in loops.iter_mut() {
                *ring = Self::simplify_polygon_loop(ring);
            }
            loops.retain(|ring| ring.len() >= 4 && ring.first() == ring.last());
        }
        polygons.retain(|_, loops| !loops.is_empty());
        polygons
    }
    /// Detect adjacent province pairs and count shared borders.
    fn detect_adjacencies_internal(ids: &[u32], width: u32, height: u32) -> Vec<(u32, u32, u32)> {
        let mut counts: HashMap<(u32, u32), u32> = HashMap::new();
        for y in 0..height {
            for x in 0..width {
                let a = ids[(y * width + x) as usize];
                if a == 0 {
                    continue;
                }
                if x + 1 < width {
                    let b = ids[(y * width + x + 1) as usize];
                    if b != 0 && b != a {
                        let pair = (a.min(b), a.max(b));
                        *counts.entry(pair).or_insert(0) += 1;
                    }
                }
                if y + 1 < height {
                    let b = ids[((y + 1) * width + x) as usize];
                    if b != 0 && b != a {
                        let pair = (a.min(b), a.max(b));
                        *counts.entry(pair).or_insert(0) += 1;
                    }
                }
            }
        }
        let mut result: Vec<(u32, u32, u32)> = counts
            .into_iter()
            .map(|((pa, pb), count)| (pa, pb, count))
            .collect();
        result.sort_by(|a, b| a.0.cmp(&b.0).then(a.1.cmp(&b.1)));
        result
    }
    /// Trace closed loops from directed border edges.
    fn trace_loops_from_edges(edges: &[DirectedEdge]) -> Vec<Vec<GridPoint>> {
        if edges.is_empty() {
            return Vec::new();
        }
        let mut outgoing: HashMap<GridPoint, Vec<GridPoint>> = HashMap::new();
        for &(start, end) in edges {
            outgoing.entry(start).or_default().push(end);
        }
        let mut used: HashSet<DirectedEdge> = HashSet::new();
        let mut loops: Vec<Vec<GridPoint>> = Vec::new();
        for &(start, next) in edges {
            if used.contains(&(start, next)) {
                continue;
            }
            let mut ring = vec![start, next];
            used.insert((start, next));
            let mut prev = start;
            let mut curr = next;
            let mut closed = curr == start;
            for _ in 0..=edges.len() {
                if closed {
                    break;
                }
                let Some(candidates) = outgoing.get(&curr) else {
                    break;
                };
                let Some(next_point) = Self::pick_next_edge(prev, curr, candidates, &used) else {
                    break;
                };
                used.insert((curr, next_point));
                ring.push(next_point);
                prev = curr;
                curr = next_point;
                if curr == start {
                    closed = true;
                }
            }
            if closed {
                loops.push(ring);
            }
        }
        loops
    }
    /// Pick the next edge while tracing a polygon loop.
    fn pick_next_edge(
        prev: GridPoint,
        curr: GridPoint,
        candidates: &[GridPoint],
        used: &HashSet<DirectedEdge>,
    ) -> Option<GridPoint> {
        let incoming = (curr.0 as i64 - prev.0 as i64, curr.1 as i64 - prev.1 as i64);
        let mut best: Option<(u8, GridPoint)> = None;
        for &cand in candidates {
            if used.contains(&(curr, cand)) {
                continue;
            }
            let out = (cand.0 as i64 - curr.0 as i64, cand.1 as i64 - curr.1 as i64);
            if out.0 == -incoming.0 && out.1 == -incoming.1 {
                continue;
            }
            let rank = Self::turn_rank(incoming, out);
            if best.as_ref().is_none_or(|(best_rank, _)| rank < *best_rank) {
                best = Some((rank, cand));
            }
        }
        if let Some((_, point)) = best {
            return Some(point);
        }
        candidates
            .iter()
            .copied()
            .find(|cand| !used.contains(&(curr, *cand)))
    }
    /// Rank a turn by direction preference when tracing polygon edges.
    fn turn_rank(incoming: (i64, i64), outgoing: (i64, i64)) -> u8 {
        let Some(in_dir) = Self::cardinal_dir(incoming) else {
            return 4;
        };
        let Some(out_dir) = Self::cardinal_dir(outgoing) else {
            return 4;
        };
        let delta = (out_dir + 4 - in_dir) % 4;
        match delta {
            0 => 0,
            1 => 1,
            3 => 2,
            2 => 3,
            _ => 4,
        }
    }
    /// Map a cardinal vector to a compact direction index.
    fn cardinal_dir(v: (i64, i64)) -> Option<u8> {
        match v {
            (1, 0) => Some(0),
            (0, 1) => Some(1),
            (-1, 0) => Some(2),
            (0, -1) => Some(3),
            _ => None,
        }
    }
    /// Remove redundant vertices from a polygon loop and keep it closed.
    fn simplify_polygon_loop(points: &[(u32, u32)]) -> Vec<(u32, u32)> {
        if points.len() < 4 {
            return points.to_vec();
        }
        let mut ring = points.to_vec();
        if ring.first() == ring.last() {
            ring.pop();
        }
        if ring.len() < 3 {
            return points.to_vec();
        }
        loop {
            let n = ring.len();
            let mut reduced = Vec::with_capacity(n);
            let mut changed = false;
            for i in 0..n {
                let prev = ring[(i + n - 1) % n];
                let curr = ring[i];
                let next = ring[(i + 1) % n];
                if Self::is_redundant_vertex(prev, curr, next) {
                    changed = true;
                    continue;
                }
                reduced.push(curr);
            }
            if !changed || reduced.len() < 3 {
                ring = reduced;
                break;
            }
            ring = reduced;
        }
        ring = Self::reduce_45_degree_staircase_vertices(&ring);
        if ring.len() >= 3 {
            loop {
                let n = ring.len();
                let mut reduced = Vec::with_capacity(n);
                let mut changed = false;
                for i in 0..n {
                    let prev = ring[(i + n - 1) % n];
                    let curr = ring[i];
                    let next = ring[(i + 1) % n];
                    if Self::is_redundant_vertex(prev, curr, next) {
                        changed = true;
                        continue;
                    }
                    reduced.push(curr);
                }
                if !changed || reduced.len() < 3 {
                    ring = reduced;
                    break;
                }
                ring = reduced;
            }
        }
        if ring.len() < 3 {
            return points.to_vec();
        }
        ring.push(ring[0]);
        ring
    }
    /// Return whether the middle point can be removed without changing the polygon shape.
    fn is_redundant_vertex(prev: GridPoint, curr: GridPoint, next: GridPoint) -> bool {
        let v1 = (curr.0 as i64 - prev.0 as i64, curr.1 as i64 - prev.1 as i64);
        let v2 = (next.0 as i64 - curr.0 as i64, next.1 as i64 - curr.1 as i64);
        if v1 == (0, 0) || v2 == (0, 0) {
            return true;
        }
        let cross = v1.0 * v2.1 - v1.1 * v2.0;
        let dot = v1.0 * v2.0 + v1.1 * v2.1;
        if cross == 0 && dot > 0 {
            return true;
        }
        false
    }
    /// Collapse repeated 45-degree staircase vertices in a polygon loop.
    fn reduce_45_degree_staircase_vertices(points: &[GridPoint]) -> Vec<GridPoint> {
        let mut ring = points.to_vec();
        loop {
            let n = ring.len();
            if n < 4 {
                break;
            }
            let mut diag_dirs: Vec<Option<(i64, i64)>> = vec![None; n];
            for i in 0..n {
                let prev = ring[(i + n - 1) % n];
                let curr = ring[i];
                let next = ring[(i + 1) % n];
                let in_vec = (curr.0 as i64 - prev.0 as i64, curr.1 as i64 - prev.1 as i64);
                let out_vec = (next.0 as i64 - curr.0 as i64, next.1 as i64 - curr.1 as i64);
                if in_vec == (0, 0) || out_vec == (0, 0) {
                    continue;
                }
                if in_vec.0 * out_vec.0 + in_vec.1 * out_vec.1 != 0 {
                    continue;
                }
                let diag = (next.0 as i64 - prev.0 as i64, next.1 as i64 - prev.1 as i64);
                if diag.0 == 0 || diag.1 == 0 || diag.0.abs() != diag.1.abs() {
                    continue;
                }
                diag_dirs[i] = Some((diag.0.signum(), diag.1.signum()));
            }
            let mut remove = vec![false; n];
            for i in 0..n {
                let Some(dir) = diag_dirs[i] else {
                    continue;
                };
                let left = (i + n - 1) % n;
                let right = (i + 1) % n;
                if diag_dirs[left] == Some(dir) || diag_dirs[right] == Some(dir) {
                    remove[i] = true;
                }
            }
            if !remove.iter().any(|v| *v) {
                break;
            }
            let next_ring: Vec<GridPoint> = ring
                .iter()
                .enumerate()
                .filter_map(|(i, p)| if remove[i] { None } else { Some(*p) })
                .collect();
            if next_ring.len() < 3 {
                break;
            }
            ring = next_ring;
        }
        ring
    }
    /// Serialize spans and border segments into a compact binary blob.
    pub fn serialize_shape_data(&self) -> Vec<u8> {
        const MAGIC: u32 = 0x5348_4150;
        const VERSION: u32 = 1;
        let mut buf = Vec::new();
        buf.extend_from_slice(&MAGIC.to_le_bytes());
        buf.extend_from_slice(&VERSION.to_le_bytes());
        buf.extend_from_slice(&self.width.to_le_bytes());
        buf.extend_from_slice(&self.height.to_le_bytes());
        let spans = self.province_spans();
        buf.extend_from_slice(&(spans.len() as u32).to_le_bytes());
        for (id, y, x0, x1) in spans {
            buf.extend_from_slice(&id.to_le_bytes());
            buf.extend_from_slice(&y.to_le_bytes());
            buf.extend_from_slice(&x0.to_le_bytes());
            buf.extend_from_slice(&x1.to_le_bytes());
        }
        let segs = self.border_segments();
        buf.extend_from_slice(&(segs.len() as u32).to_le_bytes());
        for (a, b, x0, y0, x1, y1) in segs {
            buf.extend_from_slice(&a.to_le_bytes());
            buf.extend_from_slice(&b.to_le_bytes());
            buf.extend_from_slice(&x0.to_le_bytes());
            buf.extend_from_slice(&y0.to_le_bytes());
            buf.extend_from_slice(&x1.to_le_bytes());
            buf.extend_from_slice(&y1.to_le_bytes());
        }
        buf
    }
    /// Decode serialized spans and border segments from a shape-data blob.
    #[allow(clippy::type_complexity)]
    pub fn deserialize_shape_data(
        data: &[u8],
    ) -> Option<(
        Vec<(u32, u32, u32, u32)>,
        Vec<(u32, u32, u32, u32, u32, u32)>,
    )> {
        if data.len() < 16 {
            return None;
        }
        let mut off = 0usize;
        let magic = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
        off += 4;
        if magic != 0x5348_4150 {
            return None;
        }
        let _version = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
        off += 4;
        let _width = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
        off += 4;
        let _height = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
        off += 4;
        if off + 4 > data.len() {
            return None;
        }
        let num_spans =
            u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]) as usize;
        off += 4;
        let mut spans = Vec::new();
        for _ in 0..num_spans {
            if off + 16 > data.len() {
                return None;
            }
            let id = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let y = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let x0 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let x1 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            spans.push((id, y, x0, x1));
        }
        if off + 4 > data.len() {
            return None;
        }
        let num_segs =
            u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]) as usize;
        off += 4;
        let mut segs = Vec::new();
        for _ in 0..num_segs {
            if off + 24 > data.len() {
                return None;
            }
            let a = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let b = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let x0 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let y0 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let x1 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            let y1 = u32::from_le_bytes([data[off], data[off + 1], data[off + 2], data[off + 3]]);
            off += 4;
            segs.push((a, b, x0, y0, x1, y1));
        }
        Some((spans, segs))
    }
}
