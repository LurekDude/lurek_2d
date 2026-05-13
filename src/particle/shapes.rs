#[derive(Clone, Debug, Default, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum ParticleShape {
    #[default]
    Square,
    Circle,
    Triangle,
    Spark,
    Diamond,
    Shrapnel {
        edges: u8,
    },
    Ray {
        aspect: f32,
    },
    Puff,
    Ring {
        thickness: f32,
    },
    Capsule,
}
