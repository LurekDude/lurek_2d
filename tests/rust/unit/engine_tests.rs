//! Integration tests for the Lurek2D engine core.

use lurek2d::lua_api::system_api;

// ── Processor Count ──────────────────────────────────────────────

#[test]
fn get_processor_count_returns_positive() {
    let count = system_api::get_processor_count();
    assert!(count > 0, "Should detect at least 1 processor, got {count}");
}

#[test]
fn get_processor_count_is_reasonable() {
    let count = system_api::get_processor_count();
    assert!(
        count <= 1024,
        "Processor count should be reasonable, got {count}"
    );
}

// ── Memory Size ──────────────────────────────────────────────────

#[test]
fn get_memory_size_returns_positive() {
    let mem = system_api::get_memory_size();
    assert!(mem > 0, "Should detect system memory, got {mem} MiB");
}

#[test]
fn get_memory_size_is_reasonable() {
    let mem = system_api::get_memory_size();
    assert!(
        mem < 1_000_000,
        "Memory in MiB should be < 1TB, got {mem} MiB"
    );
}

#[test]
fn get_memory_size_at_least_128_mib() {
    let mem = system_api::get_memory_size();
    assert!(
        mem >= 128,
        "Any modern system should have >= 128 MiB, got {mem} MiB"
    );
}

// ── Open URL ─────────────────────────────────────────────────────

#[test]
fn open_url_rejects_file_scheme() {
    assert!(
        !system_api::open_url("file:///etc/passwd"),
        "file:// scheme must be rejected"
    );
}

#[test]
fn open_url_rejects_cmd_scheme() {
    assert!(
        !system_api::open_url("cmd://exploit"),
        "cmd:// scheme must be rejected"
    );
}

#[test]
fn open_url_rejects_javascript_scheme() {
    assert!(
        !system_api::open_url("javascript:alert(1)"),
        "javascript: scheme must be rejected"
    );
}

#[test]
fn open_url_rejects_ftp_scheme() {
    assert!(
        !system_api::open_url("ftp://example.com"),
        "ftp:// scheme must be rejected"
    );
}

#[test]
fn open_url_rejects_empty_string() {
    assert!(!system_api::open_url(""), "Empty URL must be rejected");
}

#[test]
fn open_url_rejects_no_scheme() {
    assert!(
        !system_api::open_url("example.com"),
        "URL without scheme must be rejected"
    );
}

#[test]
fn open_url_rejects_data_scheme() {
    assert!(
        !system_api::open_url("data:text/html,<h1>test</h1>"),
        "data: scheme must be rejected"
    );
}

// ── Preferred Locales ────────────────────────────────────────────

#[test]
fn get_preferred_locales_returns_nonempty() {
    let locales = system_api::get_preferred_locales();
    assert!(!locales.is_empty(), "Should return at least one locale");
}

#[test]
fn get_preferred_locales_first_is_nonempty_string() {
    let locales = system_api::get_preferred_locales();
    assert!(
        !locales[0].is_empty(),
        "First locale should be a non-empty string"
    );
}

// ── Power Info ───────────────────────────────────────────────────

#[test]
fn get_power_info_returns_valid_state() {
    let (state, _percent, _seconds) = system_api::get_power_info();
    let valid = [
        system_api::PowerState::Unknown,
        system_api::PowerState::Battery,
        system_api::PowerState::NoBattery,
        system_api::PowerState::Charging,
        system_api::PowerState::Charged,
    ];
    assert!(
        valid.contains(&state),
        "Power state should be a valid variant"
    );
}

// ── Phase 33 — System Extended ──────────────────────────────────

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::engine::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone(), &Config::default().modules).unwrap();
    (state, lua)
}

#[test]
fn test_lua_get_arch() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local arch = luna.platform.getArch()
        assert(type(arch) == "string")
        assert(#arch > 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_env_existing() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        -- PATH should exist on all platforms
        local path = luna.platform.getEnv("PATH")
        assert(path ~= nil)
        assert(type(path) == "string")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_env_missing() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local val = luna.platform.getEnv("LUREK2D_NONEXISTENT_VAR_12345")
        assert(val == nil)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_args() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local args = luna.platform.getArgs()
        assert(type(args) == "table")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_parse_args_with_table() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local result = luna.platform.parseArgs({"--verbose", "--output=report.txt", "-f", "input.lua"})
        assert(result.flags.verbose == true)
        assert(result.flags.f == true)
        assert(result.options.output == "report.txt")
        assert(result.positional[1] == "input.lua")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_parse_args_end_of_options() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local result = luna.platform.parseArgs({"--debug", "--", "--not-a-flag"})
        assert(result.flags.debug == true)
        assert(result.positional[1] == "--not-a-flag")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_run_batch_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local results = luna.platform.runBatch({
            add = function() return 1 + 1 end,
            mul = function() return 2 * 3 end,
        })
        local passed, failed, skipped = luna.platform.getBatchResults(results)
        assert(passed == 2)
        assert(failed == 0)
        assert(skipped == 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_run_batch_with_error() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local results = luna.platform.runBatch({
            good = function() return true end,
            bad = function() error("fail") end,
        })
        local passed, failed, skipped = luna.platform.getBatchResults(results)
        assert(passed + failed == 2)
        assert(failed >= 1)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn get_power_info_state_string_valid() {
    let (state, _, _) = system_api::get_power_info();
    let valid_strings = ["unknown", "battery", "nobattery", "charging", "charged"];
    assert!(
        valid_strings.contains(&state.as_str()),
        "Power state string '{}' should be valid",
        state.as_str()
    );
}

#[test]
fn get_power_info_desktop_returns_unknown() {
    let (state, percent, seconds) = system_api::get_power_info();
    // On desktop, we expect unknown with no battery info
    assert_eq!(state, system_api::PowerState::Unknown);
    assert!(percent.is_none(), "Desktop should return None for percent");
    assert!(seconds.is_none(), "Desktop should return None for seconds");
}
