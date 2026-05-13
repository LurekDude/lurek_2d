#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ShadowFilter {
    #[default]
    None,
    Pcf5,
    Pcf13,
}
