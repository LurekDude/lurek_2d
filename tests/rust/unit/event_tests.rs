//! INTERNAL ONLY: public `lurek.event.*` queue and signal behavior is covered
//! by the Lua-first suite in `tests/lua/unit/test_event_core_unit.lua`.
//!
//! The remaining Rust coverage keeps one wildcard-helper edge case that is not
//! reachable via `LSignal:connect`, because the Lua API only routes names with
//! `*` or `?` through wildcard registration.

use lurek2d::event::Signal;

#[test]
fn wildcard_empty_pattern_matches_only_empty_name() {
    let mut signal = Signal::new();
    let handle = signal.subscribe_wildcard("");
    let empty_match = signal.get_wildcard_handles("");
    let non_empty_match = signal.get_wildcard_handles("x");

    assert_eq!(empty_match, vec![handle]);
    assert!(non_empty_match.is_empty());
}
