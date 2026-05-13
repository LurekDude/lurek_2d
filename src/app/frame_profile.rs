//! Scope: Frame-profile text formatting for app diagnostics.
//! This file defines helpers that convert runtime profile values into compact strings.
//! It owns stable formatting of app tick/update/render timing summaries.

use crate::runtime::FrameProfile;

// ---- Helper Functions: Frame Profile Formatting ----

/// Builds a compact one-line summary used by overlays and Lua tooling.
pub fn format_frame_profile_line(profile: &FrameProfile) -> String {
    format!(
        "tick={:.2}ms update={:.2}ms render={:.2}ms cb={:.2}ms",
        profile.app_tick_ms,
        profile.app_update_ms,
        profile.app_render_ms,
        profile.callback_total_ms,
    )
}
