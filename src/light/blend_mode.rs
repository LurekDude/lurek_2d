#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightBlendMode {
    #[default]
    Add,
    Sub,
    Mix,
}
