//! Fixed-point time accumulation helpers shared by runtime subsystems.

/// Accumulate scaled seconds into a deterministic microsecond counter.
///
/// This avoids long-run drift from repeatedly adding `f32` deltas directly
/// into elapsed time fields. Fractional microseconds are preserved in
/// `carry_micros` and rolled into later updates.
///
/// # Parameters
/// - `elapsed_micros`: monotonic elapsed counter in microseconds.
/// - `carry_micros`: fractional microseconds carried between updates.
/// - `dt_seconds`: frame delta in seconds.
/// - `scale`: playback/time-scale multiplier.
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
