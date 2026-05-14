//! Shadow filter quality preset for soft-shadow kernel selection in 2D lights.
//! Used by `Light2D::shadow_filter`; evaluated by the renderer when running shadow passes.
//! Higher variants increase sample count and blur quality at the cost of fill-rate.

/// Shadow filter quality preset controlling the soft-shadow sample kernel.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ShadowFilter {
    /// Hard shadows with no filtering; fastest (default).
    #[default]
    None,
    /// 5-tap Percentage Closer Filtering; soft edges with low sample count.
    Pcf5,
    /// 13-tap Percentage Closer Filtering; smoother soft edges at higher cost.
    Pcf13,
}
