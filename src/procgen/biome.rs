//! Biome classification layer over heightmap and noise data.
//!
//! Assigns a [`BiomeType`] to each cell based on elevation (height), moisture, and
//! optionally temperature. This module does not generate noise itself — callers
//! provide pre-generated heightmap slices and separate moisture/temperature arrays.
//!
//! # Usage
//!
//! ```rust
//! use lurek2d::procgen::biome::{BiomeClassifier, BiomeRules, BiomeType};
//!
//! let rules = BiomeRules::default();
//! let classifier = BiomeClassifier::new(rules);
//! let biome = classifier.classify(0.7, 0.4, 0.6);
//! ```

// -------------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------------

/// Discrete biome categories.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BiomeType {
    /// Deep water / ocean (very low elevation).
    Ocean,
    /// Shallow water / coast (low elevation, moderate moisture).
    Coast,
    /// Sandy beach near water.
    Beach,
    /// Hot, dry desert (low moisture, high temperature).
    Desert,
    /// Temperate grassland / plains.
    Grassland,
    /// Shrubland / chaparral (dry temperate).
    Shrubland,
    /// Tropical rainforest (high moisture, high temperature).
    TropicalRainforest,
    /// Temperate deciduous forest.
    TemperateForest,
    /// Boreal / coniferous forest (low temperature).
    Taiga,
    /// Cold, treeless plain (very low temperature or high elevation).
    Tundra,
    /// Rocky mountain or high-elevation terrain.
    Mountain,
    /// Ice cap / snowfield (extreme cold or very high elevation).
    IceCap,
    /// Wetland / swamp (low elevation, very high moisture).
    Swamp,
    /// Tropical savanna (moderate moisture, high temperature).
    Savanna,
}

impl BiomeType {
    /// Returns the canonical string name for this biome.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Ocean => "ocean",
            Self::Coast => "coast",
            Self::Beach => "beach",
            Self::Desert => "desert",
            Self::Grassland => "grassland",
            Self::Shrubland => "shrubland",
            Self::TropicalRainforest => "tropical_rainforest",
            Self::TemperateForest => "temperate_forest",
            Self::Taiga => "taiga",
            Self::Tundra => "tundra",
            Self::Mountain => "mountain",
            Self::IceCap => "ice_cap",
            Self::Swamp => "swamp",
            Self::Savanna => "savanna",
        }
    }

    /// Returns a representative RGBA colour for this biome suitable for visualisation.
    pub fn color_rgba(self) -> [u8; 4] {
        match self {
            Self::Ocean => [30, 60, 150, 255],
            Self::Coast => [60, 100, 180, 255],
            Self::Beach => [220, 200, 150, 255],
            Self::Desert => [210, 180, 90, 255],
            Self::Grassland => [100, 160, 70, 255],
            Self::Shrubland => [140, 160, 80, 255],
            Self::TropicalRainforest => [30, 120, 30, 255],
            Self::TemperateForest => [50, 130, 60, 255],
            Self::Taiga => [70, 110, 80, 255],
            Self::Tundra => [180, 200, 180, 255],
            Self::Mountain => [120, 110, 100, 255],
            Self::IceCap => [230, 240, 255, 255],
            Self::Swamp => [60, 80, 50, 255],
            Self::Savanna => [160, 180, 80, 255],
        }
    }
}

/// Thresholds used by [`BiomeClassifier`] to assign biomes.
///
/// All values are normalised to `[0.0, 1.0]`.
#[derive(Debug, Clone)]
pub struct BiomeRules {
    /// Elevation at or below which cells are classified as ocean.
    pub ocean_threshold: f32,
    /// Elevation at or below which cells near water become coast/beach.
    pub coast_threshold: f32,
    /// Elevation above which cells become mountain.
    pub mountain_threshold: f32,
    /// Elevation above mountain at which cells become ice cap.
    pub ice_cap_threshold: f32,
    /// Temperature below which tundra/taiga is assigned regardless of moisture.
    pub cold_temperature: f32,
    /// Temperature above which tropical biomes are preferred over temperate.
    pub warm_temperature: f32,
    /// Moisture below which desert/shrubland is preferred.
    pub dry_moisture: f32,
    /// Moisture above which swamp/rainforest is preferred.
    pub wet_moisture: f32,
}

impl Default for BiomeRules {
    fn default() -> Self {
        Self {
            ocean_threshold: 0.30,
            coast_threshold: 0.35,
            mountain_threshold: 0.75,
            ice_cap_threshold: 0.90,
            cold_temperature: 0.25,
            warm_temperature: 0.65,
            dry_moisture: 0.25,
            wet_moisture: 0.70,
        }
    }
}

/// Classifies individual cells into biomes given height, moisture, and temperature.
///
/// Construct with [`BiomeClassifier::new`] and call [`classify`](BiomeClassifier::classify)
/// per cell, or use [`classify_map`](BiomeClassifier::classify_map) for bulk processing.
#[derive(Debug, Clone)]
pub struct BiomeClassifier {
    rules: BiomeRules,
}

impl BiomeClassifier {
    /// Creates a new classifier with the given rules.
    ///
    /// # Parameters
    /// - `rules` — `BiomeRules`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(rules: BiomeRules) -> Self {
        Self { rules }
    }

    /// Creates a classifier with default rules.
    ///
    /// # Returns
    /// `Self`.
    pub fn default_rules() -> Self {
        Self::new(BiomeRules::default())
    }

    /// Classifies a single cell given its `height`, `moisture`, and `temperature` (all in `[0, 1]`).
    ///
    /// # Parameters
    /// - `height` — `f32`. Normalised elevation in `[0, 1]`.
    /// - `moisture` — `f32`. Normalised moisture in `[0, 1]`.
    /// - `temperature` — `f32`. Normalised temperature in `[0, 1]`. Use `0.5` if unavailable.
    ///
    /// # Returns
    /// [`BiomeType`].
    pub fn classify(&self, height: f32, moisture: f32, temperature: f32) -> BiomeType {
        let r = &self.rules;

        // Water / elevation extremes first
        if height <= r.ocean_threshold {
            return BiomeType::Ocean;
        }
        if height <= r.coast_threshold {
            return if moisture < r.dry_moisture {
                BiomeType::Beach
            } else {
                BiomeType::Coast
            };
        }
        if height >= r.ice_cap_threshold {
            return BiomeType::IceCap;
        }
        if height >= r.mountain_threshold {
            return if temperature < r.cold_temperature {
                BiomeType::IceCap
            } else {
                BiomeType::Mountain
            };
        }

        // Temperature-driven splits
        if temperature < r.cold_temperature {
            return if moisture < r.dry_moisture {
                BiomeType::Tundra
            } else {
                BiomeType::Taiga
            };
        }

        // Moisture-driven splits
        if moisture <= r.dry_moisture {
            return if temperature >= r.warm_temperature {
                BiomeType::Desert
            } else {
                BiomeType::Shrubland
            };
        }

        if moisture >= r.wet_moisture {
            return if temperature >= r.warm_temperature {
                BiomeType::TropicalRainforest
            } else if height > 0.45 {
                BiomeType::TemperateForest
            } else {
                BiomeType::Swamp
            };
        }

        // Mid-moisture mid-temperature
        if temperature >= r.warm_temperature {
            BiomeType::Savanna
        } else if moisture > 0.5 {
            BiomeType::TemperateForest
        } else {
            BiomeType::Grassland
        }
    }

    /// Classifies an entire map from flat arrays.
    ///
    /// `height`, `moisture`, and `temperature` must all have length `width * height`.
    /// If `temperature` is empty, `0.5` is used for every cell.
    ///
    /// # Parameters
    /// - `width` — `u32`. Map width.
    /// - `height_map` — `u32`. Map height.
    /// - `heights` — `&[f32]`. Elevation values in row-major order.
    /// - `moisture` — `&[f32]`. Moisture values in row-major order.
    /// - `temperature` — `&[f32]`. Temperature values (may be empty to use constant 0.5).
    ///
    /// # Returns
    /// `Vec<BiomeType>` in row-major order.
    pub fn classify_map(
        &self,
        width: u32,
        height_map: u32,
        heights: &[f32],
        moisture: &[f32],
        temperature: &[f32],
    ) -> Vec<BiomeType> {
        let n = (width * height_map) as usize;
        let mut biomes = Vec::with_capacity(n);
        for i in 0..n {
            let h = heights.get(i).copied().unwrap_or(0.0);
            let m = moisture.get(i).copied().unwrap_or(0.5);
            let t = temperature.get(i).copied().unwrap_or(0.5);
            biomes.push(self.classify(h, m, t));
        }
        biomes
    }

    /// Returns a reference to the rules used by this classifier.
    ///
    /// # Returns
    /// `&BiomeRules`.
    pub fn rules(&self) -> &BiomeRules {
        &self.rules
    }
}

/// Converts a biome map to an RGBA byte buffer suitable for [`ImageData`](crate::image::ImageData).
///
/// Each biome cell occupies 4 bytes (R, G, B, A) in row-major order.
///
/// # Parameters
/// - `biomes` — `&[BiomeType]`. Row-major biome map.
///
/// # Returns
/// `Vec<u8>` — RGBA pixel data.
pub fn biome_map_to_rgba(biomes: &[BiomeType]) -> Vec<u8> {
    let mut out = Vec::with_capacity(biomes.len() * 4);
    for &b in biomes {
        out.extend_from_slice(&b.color_rgba());
    }
    out
}
