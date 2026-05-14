/// Blend mode for how a light's contribution is combined with the light accumulation buffer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightBlendMode {
    /// Additive: light values are summed into the buffer (default, classic glow).
    #[default]
    Add,
    /// Subtractive: light values are subtracted from the buffer (shadow zones).
    Sub,
    /// Alpha-mix: light values are linearly interpolated with the buffer by intensity.
    Mix,
}
