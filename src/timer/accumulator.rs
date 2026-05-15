//! - Drift-free microsecond accumulation for scaled elapsed-time tracking.
//! - Fractional sub-microsecond carry prevents rounding loss across frames.
//! - All negative inputs clamped to zero for monotonic guarantees.

/// Advance `elapsed_micros` by `dt_seconds * scale`, accumulating fractional.
/// microseconds in `carry_micros` to avoid drift; clamps negative inputs to zero.
pub(crate) fn accumulate_scaled_micros(
    elapsed_micros: &mut u64,
    carry_micros: &mut f64,
    dt_seconds: f32,
    scale: f32,
) {
    let delta = (dt_seconds.max(0.0) as f64) * (scale.max(0.0) as f64) * 1_000_000.0;
    let total = *carry_micros + delta;
    let whole = total.floor();
    *carry_micros = total - whole;
    *elapsed_micros = elapsed_micros.saturating_add(whole as u64);
}
