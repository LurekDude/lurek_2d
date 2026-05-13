#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightType {
    #[default]
    Point,
    Directional,
    Spot,
}
