#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BiomeType {
    Ocean,
    Coast,
    Beach,
    Desert,
    Grassland,
    Shrubland,
    TropicalRainforest,
    TemperateForest,
    Taiga,
    Tundra,
    Mountain,
    IceCap,
    Swamp,
    Savanna,
}
impl BiomeType {
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
#[derive(Debug, Clone)]
pub struct BiomeRules {
    pub ocean_threshold: f32,
    pub coast_threshold: f32,
    pub mountain_threshold: f32,
    pub ice_cap_threshold: f32,
    pub cold_temperature: f32,
    pub warm_temperature: f32,
    pub dry_moisture: f32,
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
#[derive(Debug, Clone)]
pub struct BiomeClassifier {
    rules: BiomeRules,
}
impl BiomeClassifier {
    pub fn new(rules: BiomeRules) -> Self {
        Self { rules }
    }
    pub fn default_rules() -> Self {
        Self::new(BiomeRules::default())
    }
    pub fn classify(&self, height: f32, moisture: f32, temperature: f32) -> BiomeType {
        let r = &self.rules;
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
        if temperature < r.cold_temperature {
            return if moisture < r.dry_moisture {
                BiomeType::Tundra
            } else {
                BiomeType::Taiga
            };
        }
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
        if temperature >= r.warm_temperature {
            BiomeType::Savanna
        } else if moisture > 0.5 {
            BiomeType::TemperateForest
        } else {
            BiomeType::Grassland
        }
    }
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
    pub fn rules(&self) -> &BiomeRules {
        &self.rules
    }
}
pub fn biome_map_to_rgba(biomes: &[BiomeType]) -> Vec<u8> {
    let mut out = Vec::with_capacity(biomes.len() * 4);
    for &b in biomes {
        out.extend_from_slice(&b.color_rgba());
    }
    out
}
