//! Depth-sorting for scene draw calls.
//! Owns DepthSorter and DepthEntry; chooses between unstable, stable, radix, and parallel
//! sort strategies depending on entry count and depth type.
//! Does not own rendering or callback dispatch — callers use sorted_entries() to drive draw order.
//! Key dependencies: rayon for the parallel sort path above PARALLEL_SORT_THRESHOLD.

/// Minimum entry count that enables the 8-bit radix sort path over unstable sort.
const RADIX_THRESHOLD: usize = 256;
/// Minimum entry count that switches to rayon parallel sort.
const PARALLEL_SORT_THRESHOLD: usize = 10_000;
/// Bias added to depth before converting to u32 for radix; covers negative depth values down to -65535.
const DEPTH_OFFSET: f32 = 65_535.0;

/// Single sortable draw entry holding depth, callback slot, and object-kind flag.
#[derive(Clone, Copy)]
pub struct DepthEntry {
    /// Depth value used as the sort key; lower values are drawn first.
    pub depth: f32,
    /// Index into the scene callback table that owns this draw call.
    pub callback_index: usize,
    /// True when this entry is a scene object, false for plain layer draws.
    pub is_object: bool,
}

/// Adaptive depth sorter that selects unstable, stable, radix, or parallel strategy by entry count.
pub struct DepthSorter {
    /// Draw entries; may be unsorted when dirty is true.
    entries: Vec<DepthEntry>,
    /// True after add/add_object and before the next sort call.
    dirty: bool,
    /// When true, sort() uses stable ordering to preserve insertion order of equal depths.
    stable: bool,
}
impl DepthSorter {
    /// Create an empty DepthSorter with dirty=false and stable=false.
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            dirty: false,
            stable: false,
        }
    }
    /// Set whether sort() uses stable ordering; stable preserves insertion order for equal depths.
    pub fn set_stable(&mut self, val: bool) {
        self.stable = val;
    }
    /// Return current stable flag value.
    pub fn is_stable(&self) -> bool {
        self.stable
    }
    /// Append a plain layer draw entry at the given depth and mark the sorter dirty.
    pub fn add(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: false,
        });
        self.dirty = true;
    }
    /// Append a scene-object draw entry (is_object=true) at the given depth and mark dirty.
    pub fn add_object(&mut self, callback_index: usize, depth: f32) {
        self.entries.push(DepthEntry {
            depth,
            callback_index,
            is_object: true,
        });
        self.dirty = true;
    }
    /// Sort entries using the best available strategy; delegates to parallel, radix, stable, or unstable.
    pub fn sort(&mut self) {
        if self.entries.len() > PARALLEL_SORT_THRESHOLD {
            self.sort_parallel();
        } else if !self.stable
            && self.entries.len() >= RADIX_THRESHOLD
            && Self::are_integral_depths(&self.entries)
        {
            self.sort_radix();
        } else if self.stable {
            self.entries.sort_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
        } else {
            self.entries.sort_unstable_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
        }
    }
    /// Sort with four 8-bit radix passes; falls back to unstable sort when preconditions fail; returns true on radix path.
    pub fn sort_radix(&mut self) -> bool {
        if self.entries.len() < RADIX_THRESHOLD || !Self::are_integral_depths(&self.entries) {
            self.entries.sort_unstable_by(|a, b| {
                a.depth
                    .partial_cmp(&b.depth)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            self.dirty = false;
            return false;
        }
        let n = self.entries.len();
        let mut keyed: Vec<(u32, usize)> = self
            .entries
            .iter()
            .enumerate()
            .map(|(i, e)| {
                let shifted = (e.depth + DEPTH_OFFSET).clamp(0.0, 2.0 * DEPTH_OFFSET) as u32;
                (shifted, i)
            })
            .collect();
        radix_pass_8bit(&mut keyed, 0);
        radix_pass_8bit(&mut keyed, 8);
        radix_pass_8bit(&mut keyed, 16);
        radix_pass_8bit(&mut keyed, 24);
        let old: Vec<DepthEntry> = std::mem::replace(
            &mut self.entries,
            vec![
                DepthEntry {
                    depth: 0.0,
                    callback_index: 0,
                    is_object: false
                };
                n
            ],
        );
        for (new_pos, (_, orig_idx)) in keyed.iter().enumerate() {
            self.entries[new_pos] = old[*orig_idx];
        }
        self.dirty = false;
        true
    }
    /// Sort using rayon par_sort_unstable_by; used when entry count exceeds PARALLEL_SORT_THRESHOLD.
    pub fn sort_parallel(&mut self) {
        use rayon::prelude::*;
        self.entries.par_sort_unstable_by(|a, b| {
            a.depth
                .partial_cmp(&b.depth)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
        self.dirty = false;
    }
    /// Return sorted entry slice, triggering sort() first if dirty.
    pub fn sorted_entries(&mut self) -> &[DepthEntry] {
        if self.dirty {
            self.sort();
        }
        &self.entries
    }
    /// Clear all entries and reset dirty to false.
    pub fn clear(&mut self) {
        self.entries.clear();
        self.dirty = false;
    }
    /// Return entry count without sorting.
    pub fn get_count(&self) -> usize {
        self.entries.len()
    }
    /// Return true when every entry depth has fract < 1e-4, enabling the radix sort path.
    fn are_integral_depths(entries: &[DepthEntry]) -> bool {
        entries.iter().all(|e| e.depth.fract().abs() < 1e-4)
    }
}
/// Perform one 8-bit counting pass over (key, index) pairs using the given bit shift (0, 8, 16, or 24).
fn radix_pass_8bit(data: &mut Vec<(u32, usize)>, shift: u32) {
    const BUCKETS: usize = 256;
    let mut counts = [0usize; BUCKETS];
    for &(key, _) in data.iter() {
        let bucket = ((key >> shift) & 0xFF) as usize;
        counts[bucket] += 1;
    }
    let mut offsets = [0usize; BUCKETS];
    let mut total = 0;
    for i in 0..BUCKETS {
        offsets[i] = total;
        total += counts[i];
    }
    let mut output = vec![(0u32, 0usize); data.len()];
    for &(key, idx) in data.iter() {
        let bucket = ((key >> shift) & 0xFF) as usize;
        output[offsets[bucket]] = (key, idx);
        offsets[bucket] += 1;
    }
    *data = output;
}
/// Default delegates to new().
impl Default for DepthSorter {
    fn default() -> Self {
        Self::new()
    }
}
