//! Single terminal cell type and default color constants shared across the
//! terminal emulator. Owns `TCell` and the module-wide default fg/bg/char
//! values. Does not own layout, rendering, or ANSI parsing.

/// Default foreground color: opaque white [r, g, b, a].
pub(crate) const DEFAULT_FG: [f32; 4] = [1.0, 1.0, 1.0, 1.0];
/// Default background color: fully transparent black [r, g, b, a].
pub(crate) const DEFAULT_BG: [f32; 4] = [0.0, 0.0, 0.0, 0.0];
/// Default character codepoint: ASCII space.
pub(crate) const DEFAULT_CH: u32 = b' ' as u32;

/// One character cell in the terminal grid, used by `Terminal` and the render layer.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct TCell {
    /// Unicode codepoint to render in this cell.
    pub ch: u32,
    /// Foreground RGBA color, components in 0.0–1.0.
    pub fg: [f32; 4],
    /// Background RGBA color, components in 0.0–1.0.
    pub bg: [f32; 4],
}

/// `Default` implementation for `TCell`.
impl Default for TCell {
    fn default() -> Self {
        Self {
            ch: DEFAULT_CH,
            fg: DEFAULT_FG,
            bg: DEFAULT_BG,
        }
    }
}

