//! Headless load test: attempts to parse/load every `content/games/**/main.lua`
//! via `create_lua_vm` without a window or GPU.
//!
//! Run: cargo test --test games_load_test -- --nocapture
//!
//! Each file is loaded in isolation.  The test passes if the Lua chunk can be
//! compiled and executed without a runtime error.  Failures are collected and
//! reported together at the end so you can see all broken games at once.

use std::cell::RefCell;
use std::path::{Path, PathBuf};
use std::rc::Rc;

use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::runtime::config::Config;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "GamesTest",
        PathBuf::from("."),
    )));
    state.borrow_mut().load_default_fonts();
    create_lua_vm(state, &Config::default().modules).expect("create_lua_vm failed")
}

fn load_game(path: &str) -> Result<(), String> {
    let lua = make_vm();
    let code = std::fs::read_to_string(path).map_err(|e| format!("read error: {e}"))?;
    lua.load(&code)
        .set_name(Path::new(path).file_name().unwrap().to_str().unwrap())
        .exec()
        .map_err(|e| format!("{e}"))
}

/// Recursively collect all `main.lua` files under `content/games/`.
fn collect_game_mains() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    collect_recursive(Path::new("content/games"), &mut paths);
    paths.sort();
    paths
}

fn collect_recursive(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for entry in entries.filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_dir() {
            collect_recursive(&path, out);
        } else if path.file_name().map(|n| n == "main.lua").unwrap_or(false) {
            out.push(path);
        }
    }
}

#[test]
fn games_load_all() {
    let paths = collect_game_mains();
    assert!(
        !paths.is_empty(),
        "No main.lua files found under content/games/"
    );

    let mut failed: Vec<(String, String)> = Vec::new();
    let mut passed = 0usize;

    for path in &paths {
        let s = path.to_str().unwrap();
        let short = s.replace("content/games/", "");
        match load_game(s) {
            Ok(()) => {
                passed += 1;
                println!("PASS {short}");
            }
            Err(e) => {
                println!("FAIL {short}: {e}");
                failed.push((short, e));
            }
        }
    }

    println!("\n=== SUMMARY ===");
    println!("Passed: {}/{}", passed, paths.len());
    if !failed.is_empty() {
        println!("Failed ({}):", failed.len());
        for (name, err) in &failed {
            println!("  {name}: {err}");
        }
        panic!("{} game(s) failed to load", failed.len());
    }
}
