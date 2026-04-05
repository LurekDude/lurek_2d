//! Cell data types for the terminal grid.

/// Default foreground colour (white, fully opaque).
pub(crate) const DEFAULT_FG: [f32; 4] = [1.0, 1.0, 1.0, 1.0];

/// Default background colour (black, fully transparent).
pub(crate) const DEFAULT_BG: [f32; 4] = [0.0, 0.0, 0.0, 0.0];

/// Default character (space).
pub(crate) const DEFAULT_CH: u32 = b' ' as u32;

/// A single character cell in the terminal grid.
///
/// Each cell stores a Unicode codepoint and two RGBA float colours — one for
/// the foreground glyph and one for the background fill.
///
/// # Fields
/// - `ch` — `u32`. Unicode codepoint (default: U+0020, space).
/// - `fg` — `[f32; 4]`. Foreground RGBA colour (default: white).
/// - `bg` — `[f32; 4]`. Background RGBA colour (default: transparent black).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct TCell {
    /// Unicode codepoint (default: U+0020, space).
    pub ch: u32,
    /// Foreground RGBA colour (default: white, fully opaque).
    pub fg: [f32; 4],
    /// Background RGBA colour (default: transparent black).
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