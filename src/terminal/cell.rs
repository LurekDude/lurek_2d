pub(crate) const DEFAULT_FG: [f32; 4] = [1.0, 1.0, 1.0, 1.0];
pub(crate) const DEFAULT_BG: [f32; 4] = [0.0, 0.0, 0.0, 0.0];
pub(crate) const DEFAULT_CH: u32 = b' ' as u32;
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct TCell {
    pub ch: u32,
    pub fg: [f32; 4],
    pub bg: [f32; 4],
}
impl Default for TCell {
    fn default() -> Self {
        Self {
            ch: DEFAULT_CH,
            fg: DEFAULT_FG,
            bg: DEFAULT_BG,
        }
    }
}
