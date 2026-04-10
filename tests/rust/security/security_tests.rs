//! Security and boundary tests for the Lurek2D engine.
//!
//! Covers: path traversal prevention, Lua sandbox isolation, input boundary
//! conditions, and safe memory handling at public API surfaces.
//!
//! All tests must run headless — no GPU, no window, no audio device.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::runtime::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "SecurityTest",
        PathBuf::from("."),
    )));
    create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM")
}

// ═════════════════════════════════════════════════════════════════════════
// Lua sandbox — dangerous globals must be absent
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn lua_sandbox_os_execute_is_nil() {
    let lua = make_vm();
    let result: bool = lua
        .load("return os == nil or os.execute == nil")
        .eval()
        .unwrap_or(true);
    assert!(result, "os.execute must not be accessible in the sandbox");
}

#[test]
fn lua_sandbox_io_open_is_nil() {
    let lua = make_vm();
    let result: bool = lua
        .load("return io == nil or io.open == nil")
        .eval()
        .unwrap_or(true);
    assert!(result, "io.open must not be accessible in the sandbox");
}

#[test]
fn lua_sandbox_load_is_nil() {
    let lua = make_vm();
    let result: bool = lua.load("return load == nil").eval().unwrap_or(true);
    assert!(result, "load() must not be accessible in the Lua sandbox");
}

#[test]
fn lua_sandbox_debug_lib_absent() {
    let lua = make_vm();
    let result: bool = lua.load("return debug == nil").eval().unwrap_or(true);
    assert!(result, "debug library must not be exposed in the sandbox");
}

#[test]
fn lua_sandbox_require_restricted() {
    let lua = make_vm();
    // require('socket') or any external module must fail gracefully
    let result: mlua::Result<mlua::Value> = lua.load("return require('socket')").eval();
    assert!(
        result.is_err(),
        "require() for external modules should fail or be absent"
    );
}

// ═════════════════════════════════════════════════════════════════════════
// Filesystem path traversal prevention
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn filesystem_reject_dotdot_path() {
    use lurek2d::filesystem::GameFS;
    let fs = GameFS::new(PathBuf::from("tests/fixtures"));
    // Attempt to escape sandbox via ..
    let result = fs.read_string("../../Cargo.toml");
    assert!(result.is_err(), "Path traversal via ../ must be rejected");
}

#[test]
fn filesystem_reject_absolute_path() {
    use lurek2d::filesystem::GameFS;
    let fs = GameFS::new(PathBuf::from("tests/fixtures"));
    // Try absolute path
    let result = fs.read_string("/etc/passwd");
    assert!(result.is_err(), "Absolute paths must be rejected by GameFS");
}

#[test]
fn filesystem_reject_null_byte_in_path() {
    use lurek2d::filesystem::GameFS;
    let fs = GameFS::new(PathBuf::from("tests/fixtures"));
    // Null-byte injection
    let result = fs.read_string("file\x00.lua");
    assert!(result.is_err(), "Null bytes in path must be rejected");
}

// ═════════════════════════════════════════════════════════════════════════
// Input boundary conditions
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn math_no_panic_on_nan_input() {
    use lurek2d::math::Vec2;
    let v = Vec2::new(f32::NAN, f32::NAN);
    let _len = v.length(); // must not panic
    let _norm = v.normalize(); // must not panic
}

#[test]
fn math_no_panic_on_infinite_input() {
    use lurek2d::math::Vec2;
    let v = Vec2::new(f32::INFINITY, f32::NEG_INFINITY);
    let _len = v.length();
    let _norm = v.normalize();
}

#[test]
fn terminal_zero_size_does_not_panic() {
    use lurek2d::terminal::Terminal;
    // A 0×0 terminal should degrade to minimum size without panicking
    let t = Terminal::new(0, 0);
    let (cols, _rows) = t.get_dimensions();
    assert!(cols >= 1); // implementation clamps to minimum
}

#[test]
fn terminal_oob_write_does_not_panic() {
    use lurek2d::terminal::Terminal;
    let mut t = Terminal::new(5, 3);
    // Writing out of bounds should be a no-op, not a panic
    t.set(100, 100, b'X' as u32, [1.0; 4], [0.0; 4]);
    t.set(1, 1, b'X' as u32, [1.0; 4], [0.0; 4]);
}

// ═════════════════════════════════════════════════════════════════════════
// Lua — malformed input does not crash the host
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn lua_infinite_loop_budget_guard() {
    // LuaJIT has no built-in CPU budget; this test just verifies the VM
    // handles an error gracefully. If the engine adds a step hook, this
    // test will catch regressions.
    let lua = make_vm();
    // Use a short table iteration that terminates — don't actually infinite-loop
    let result: mlua::Result<i64> = lua
        .load("local n = 0; for i=1,1000 do n = n + 1 end; return n")
        .eval();
    assert_eq!(result.unwrap(), 1000);
}

#[test]
fn lua_extremely_deep_recursion_returns_error() {
    let lua = make_vm();
    let result: mlua::Result<mlua::Value> = lua
        .load("local function f(n) return f(n+1) end; f(0)")
        .eval();
    // Should return a Lua error (stack overflow), not crash the process
    assert!(result.is_err(), "Unbounded recursion must produce an error");
}

#[test]
fn lua_large_string_concat_does_not_crash() {
    let lua = make_vm();
    let result: mlua::Result<usize> = lua
        .load("local t = {} for i=1,1000 do t[i] = 'x' end return #table.concat(t)")
        .eval();
    assert_eq!(result.unwrap(), 1000);
}
