//! Public tween behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_tween_unit.lua`.
//!
//! This target previously duplicated `lurek.tween`-reachable behavior for
//! `TweenState` and spring userdata. Those cases now execute through the Lua
//! API surface, so no Rust-only unit coverage remains here.
