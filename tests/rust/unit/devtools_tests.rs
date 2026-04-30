//! Public devtools behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_devtools_unit.lua`.
//!
//! Rust-only coverage remains below for the standalone `ReplConsole` type.

// ── repl ──────────────────────────────────────────────────────────────────────

mod repl_tests {
    use lurek2d::devtools::repl::ReplConsole;

    #[test]
    fn new_repl_is_empty() {
        let r = ReplConsole::new(50);
        assert!(r.is_empty());
        assert_eq!(r.len(), 0);
    }
}

