//! Shadow filter enum for controlling edge quality of shadow boundaries.

/// Edge quality for shadow boundaries.
///
/// # Variants
/// - `None` — None variant.
/// - `Pcf5` — Pcf5 variant.
/// - `Pcf13` — Pcf13 variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ShadowFilter {
    /// Hard shadow edges with no filtering.
    #[default]
    None,
    /// 5-tap percentage-closer filtering for soft edges.
    Pcf5,
    /// 13-tap percentage-closer filtering for smoother edges.
    Pcf13,
}
