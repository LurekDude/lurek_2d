#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum FalloffMode {
    #[default]
    Linear,
    Smooth,
    Constant,
}
