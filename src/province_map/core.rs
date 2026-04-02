//! Core province map data structures: [`Province`], [`AdjacencyEdge`], and [`ProvinceMap`].

use std::collections::{HashMap, HashSet};

use thiserror::Error;

use crate::math::{Rect, Vec2};

/// Error type for province map operations.
#[derive(Debug, Error)]
pub enum ProvinceError {
    /// The requested province ID does not exist in the map.
    #[error("Province {0} not found")]
    NotFound(u32),
    /// Failed to load or parse a province map image.
    #[error("Failed to load province map: {0}")]
    LoadError(String),
    /// Province data is structurally invalid.
    #[error("Invalid province data: {0}")]
    InvalidData(String),
}

/// A single province in a province map.
///
/// Province IDs are derived from the RGB colour of pixels in the source PNG:
/// `id = (r << 16) | (g << 8) | b`, giving up to 16 M unique provinces.
pub struct Province {
    /// Unique province identifier derived from its RGB colour.
    pub id: u32,
    /// Original RGB colour from the source PNG.
    pub color: [u8; 3],
    /// Total pixel count belonging to this province in the source image.
    pub area: u32,
    /// Geometric centre of the province (average of all pixel positions).
    pub centroid: Vec2,
    /// Axis-aligned bounding box enclosing all pixels of this province.
    pub bounding_box: Rect,
    /// Centre position for label placement (single point, farthest from edge).
    pub center: Vec2,
    /// Optional display name for this province.
    pub name: Option<String>,
}

impl Province {
    /// Create a new province with the given ID and RGB colour.
    ///
    /// All computed fields default to zero / empty. After loading the pixel
    /// data, call position calculation to populate `center`.
    pub fn new(id: u32, color: [u8; 3]) -> Self {
        Self {
            id,
            color,
            area: 0,
            centroid: Vec2::ZERO,
            bounding_box: Rect::new(0.0, 0.0, 0.0, 0.0),
            center: Vec2::ZERO,
            name: None,
        }
    }
}

/// An edge between two adjacent provinces.
///
/// Stores border geometry and user-defined tags (e.g. "river", "wall",
/// "mountain_pass"). The two province IDs are stored in ascending order
/// (`province_a < province_b`) so that adjacency lookups are order-independent.
pub struct AdjacencyEdge {
    /// ID of the first province (always the smaller of the two).
    pub province_a: u32,
    /// ID of the second province (always the larger of the two).
    pub province_b: u32,
    /// Number of border pixels shared between the two provinces.
    pub border_length: u32,
    /// Pixel coordinates of the border segments as `(x, y)` pairs.
    pub border_segments: Vec<(u16, u16)>,
    /// User-defined tags for this edge (e.g. "river", "wall").
    pub tags: HashSet<String>,
}

/// The complete province map — contains all provinces and their relationships.
///
/// Provinces are indexed by their colour-derived ID. A flat pixel-lookup array maps
/// every `(x, y)` position to its province ID for O(1) spatial queries.
pub struct ProvinceMap {
    /// Map width in pixels.
    width: u32,
    /// Map height in pixels.
    height: u32,
    /// All provinces keyed by ID.
    provinces: HashMap<u32, Province>,
    /// Row-major flat array mapping pixel index -> province ID.
    pixel_lookup: Vec<u32>,
    /// Adjacency edges keyed by `(min_id, max_id)`.
    adjacency: HashMap<(u32, u32), AdjacencyEdge>,
}

impl ProvinceMap {
    /// Create an empty province map with the given pixel dimensions.
    pub fn new(width: u32, height: u32) -> Self {
        let pixel_count = (width as usize) * (height as usize);
        Self {
            width,
            height,
            provinces: HashMap::new(),
            pixel_lookup: vec![0; pixel_count],
            adjacency: HashMap::new(),
        }
    }

    /// Get the map width in pixels.
    pub fn width(&self) -> u32 {
        self.width
    }

    /// Get the map height in pixels.
    pub fn height(&self) -> u32 {
        self.height
    }

    /// Look up a province by its ID.
    pub fn get_province(&self, id: u32) -> Option<&Province> {
        self.provinces.get(&id)
    }

    /// Look up a province mutably by its ID.
    pub fn get_province_mut(&mut self, id: u32) -> Option<&mut Province> {
        self.provinces.get_mut(&id)
    }

    /// Return the total number of provinces in this map.
    pub fn province_count(&self) -> usize {
        self.provinces.len()
    }

    /// Return a sorted list of all province IDs.
    pub fn province_ids(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.provinces.keys().copied().collect();
        ids.sort_unstable();
        ids
    }

    /// Get the province ID at the given pixel coordinate.
    ///
    /// Returns `None` if `(x, y)` is out of bounds.
    pub fn get_province_at(&self, x: u32, y: u32) -> Option<u32> {
        if x >= self.width || y >= self.height {
            return None;
        }
        let idx = (y as usize) * (self.width as usize) + (x as usize);
        Some(self.pixel_lookup[idx])
    }

    /// Get the IDs of all provinces adjacent to the given province.
    ///
    /// Returns an empty `Vec` if the province has no neighbours or does not exist.
    pub fn get_neighbors(&self, id: u32) -> Vec<u32> {
        self.adjacency
            .iter()
            .filter_map(|(&(a, b), _)| {
                if a == id {
                    Some(b)
                } else if b == id {
                    Some(a)
                } else {
                    None
                }
            })
            .collect()
    }

    /// Get the adjacency edge between two provinces.
    ///
    /// The order of `a` and `b` does not matter — they are normalised internally.
    pub fn get_adjacency(&self, a: u32, b: u32) -> Option<&AdjacencyEdge> {
        let key = if a <= b { (a, b) } else { (b, a) };
        self.adjacency.get(&key)
    }

    /// Expose the raw pixel-lookup buffer (row-major, `width x height`).
    pub fn pixel_lookup(&self) -> &[u32] {
        &self.pixel_lookup
    }

    /// Return the total number of adjacency edges in this map.
    pub fn adjacency_count(&self) -> usize {
        self.adjacency.len()
    }

    /// Get a mutable reference to the adjacency edge between two provinces.
    pub fn get_adjacency_mut(&mut self, a: u32, b: u32) -> Option<&mut AdjacencyEdge> {
        let key = if a <= b { (a, b) } else { (b, a) };
        self.adjacency.get_mut(&key)
    }

    /// Insert a province into the map, keyed by its ID.
    pub(crate) fn insert_province(&mut self, province: Province) {
        self.provinces.insert(province.id, province);
    }

    /// Set the province ID at the given pixel coordinate.
    ///
    /// # Panics
    /// Panics if `(x, y)` is out of bounds.
    pub(crate) fn set_pixel(&mut self, x: u32, y: u32, id: u32) {
        let idx = (y as usize) * (self.width as usize) + (x as usize);
        self.pixel_lookup[idx] = id;
    }

    /// Insert an adjacency edge into the map.
    pub(crate) fn insert_adjacency(&mut self, edge: AdjacencyEdge) {
        let key = (edge.province_a, edge.province_b);
        self.adjacency.insert(key, edge);
    }

    /// Euclidean distance between two province centroids.
    ///
    /// Returns `f64::INFINITY` if either province does not exist.
    pub fn distance(&self, a: u32, b: u32) -> f64 {
        let pa = match self.get_province(a) {
            Some(p) => p,
            None => return f64::INFINITY,
        };
        let pb = match self.get_province(b) {
            Some(p) => p,
            None => return f64::INFINITY,
        };

        let dx = (pa.centroid.x - pb.centroid.x) as f64;
        let dy = (pa.centroid.y - pb.centroid.y) as f64;
        (dx * dx + dy * dy).sqrt()
    }
}
