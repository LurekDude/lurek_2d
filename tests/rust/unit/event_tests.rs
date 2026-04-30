//! Public event behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_event_unit.lua`.
//!
//! The old Rust smoke tests in this target exercised `lurek.event`-reachable
//! behavior such as signal listener management and event queue polling. Per
//! TST-01 and TST-02, that coverage now lives in Lua and no Rust-only unit
//! cases remain here.
