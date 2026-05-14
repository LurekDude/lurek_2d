//! Cross-platform blocking sleep helper. Owns `sleep`; used by `lurek.timer`
//! for Lua-requested delays. Does not own the frame clock or scheduler.

/// Block the calling thread for `seconds`; no-ops for values <= 0.0.
pub fn sleep(seconds: f64) {
    if seconds > 0.0 {
        std::thread::sleep(std::time::Duration::from_secs_f64(seconds));
    }
}
