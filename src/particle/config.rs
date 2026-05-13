use super::shapes::ParticleShape;
use crate::runtime::resource_keys::TextureKey;
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum AreaDistribution {
    #[default]
    None,
    Uniform,
    Normal,
    Ellipse,
    BorderEllipse,
    BorderRectangle,
}
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum InsertMode {
    #[default]
    Top,
    Bottom,
    Random,
}
#[derive(Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum EmitterState {
    Active,
    Paused,
    Stopped,
}
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum EmissionShape {
    #[default]
    Point,
    Circle {
        radius: f32,
        fill: bool,
    },
    Rectangle {
        width: f32,
        height: f32,
    },
    Ring {
        inner_radius: f32,
        outer_radius: f32,
    },
    Line {
        length: f32,
        angle: f32,
    },
    Cone {
        radius: f32,
        angle: f32,
        spread: f32,
    },
    Star {
        points: u32,
        outer_radius: f32,
        inner_radius: f32,
    },
    Spiral {
        revolutions: f32,
        radius: f32,
    },
    Custom {
        callback_id: u32,
    },
}
#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum RelativeMode {
    #[default]
    Detached,
    Attached,
}
#[derive(Clone, Debug, PartialEq)]
pub struct Attractor {
    pub x: f32,
    pub y: f32,
    pub strength: f32,
    pub radius: f32,
}
#[derive(Clone, Debug, PartialEq)]
pub struct BounceBounds {
    pub x_min: f32,
    pub x_max: f32,
    pub y_min: f32,
    pub y_max: f32,
    pub restitution: f32,
}
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
#[serde(default)]
pub struct ParticleConfig {
    pub max_particles: u32,
    pub emission_rate: f32,
    pub lifetime_min: f32,
    pub lifetime_max: f32,
    pub speed_min: f32,
    pub speed_max: f32,
    pub direction: f32,
    pub spread: f32,
    pub gravity_x: f32,
    pub gravity_y: f32,
    pub sizes: Vec<f32>,
    pub colors: Vec<[f32; 4]>,
    pub spin_min: f32,
    pub spin_max: f32,
    pub rotation_min: f32,
    pub rotation_max: f32,
    pub spin_variation: f32,
    pub size_variation: f32,
    pub linear_accel_x_min: f32,
    pub linear_accel_x_max: f32,
    pub linear_accel_y_min: f32,
    pub linear_accel_y_max: f32,
    pub radial_accel_min: f32,
    pub radial_accel_max: f32,
    pub tangential_accel_min: f32,
    pub tangential_accel_max: f32,
    pub linear_damping_min: f32,
    pub linear_damping_max: f32,
    pub area_distribution: AreaDistribution,
    pub area_width: f32,
    pub area_height: f32,
    pub area_angle: f32,
    pub area_direction_relative: bool,
    pub emitter_lifetime: f32,
    pub insert_mode: InsertMode,
    pub offset_x: f32,
    pub offset_y: f32,
    pub relative_rotation: bool,
    #[serde(skip)]
    pub texture_id: Option<TextureKey>,
    pub quads: Vec<[f32; 4]>,
    pub alpha_keyframes: Vec<f32>,
    pub emission_shape: EmissionShape,
    pub relative_mode: RelativeMode,
    pub turbulence: f32,
    pub drag: f32,
    pub orbit_speed: f32,
    pub animated_frames: u32,
    pub frame_rate: f32,
    pub color_by_speed: bool,
    pub speed_color_min: f32,
    pub speed_color_max: f32,
    pub shape: ParticleShape,
    pub death_emitter: Option<Box<ParticleConfig>>,
    pub death_burst_count: u32,
    pub shrapnel_edges: u8,
    pub ray_aspect: f32,
    pub ring_thickness: f32,
}
impl Default for ParticleConfig {
    fn default() -> Self {
        Self {
            max_particles: 256,
            emission_rate: 10.0,
            lifetime_min: 1.0,
            lifetime_max: 2.0,
            speed_min: 50.0,
            speed_max: 100.0,
            direction: -std::f32::consts::FRAC_PI_2,
            spread: std::f32::consts::FRAC_PI_4,
            gravity_x: 0.0,
            gravity_y: 0.0,
            sizes: vec![4.0, 1.0],
            colors: vec![[1.0, 1.0, 1.0, 1.0], [1.0, 1.0, 1.0, 0.0]],
            spin_min: 0.0,
            spin_max: 0.0,
            rotation_min: 0.0,
            rotation_max: 0.0,
            spin_variation: 0.0,
            size_variation: 0.0,
            linear_accel_x_min: 0.0,
            linear_accel_x_max: 0.0,
            linear_accel_y_min: 0.0,
            linear_accel_y_max: 0.0,
            radial_accel_min: 0.0,
            radial_accel_max: 0.0,
            tangential_accel_min: 0.0,
            tangential_accel_max: 0.0,
            linear_damping_min: 0.0,
            linear_damping_max: 0.0,
            area_distribution: AreaDistribution::None,
            area_width: 0.0,
            area_height: 0.0,
            area_angle: 0.0,
            area_direction_relative: false,
            emitter_lifetime: -1.0,
            insert_mode: InsertMode::Top,
            offset_x: 0.0,
            offset_y: 0.0,
            relative_rotation: false,
            texture_id: None,
            quads: Vec::new(),
            alpha_keyframes: Vec::new(),
            emission_shape: EmissionShape::default(),
            relative_mode: RelativeMode::default(),
            turbulence: 0.0,
            drag: 0.0,
            orbit_speed: 0.0,
            animated_frames: 0,
            frame_rate: 12.0,
            color_by_speed: false,
            speed_color_min: 0.0,
            speed_color_max: 200.0,
            shape: ParticleShape::default(),
            death_emitter: None,
            death_burst_count: 0,
            shrapnel_edges: 6,
            ray_aspect: 4.0,
            ring_thickness: 0.2,
        }
    }
}
impl ParticleConfig {
    pub fn from_toml_str(toml_str: &str) -> Result<Self, String> {
        toml::from_str(toml_str).map_err(|e| e.to_string())
    }
}
