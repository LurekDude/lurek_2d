//! Demo smoke tests — binary screenshot tests for `content/games/` demos.
//!
//! Per repository memory and `.github/copilot-instructions.md` (TST-05),
//! binary screenshot tests for game demos live here as `#[ignore]` tests.
//! Placeholder file: actual test cases will be added by the demo-test
//! migration phase. Declared in `Cargo.toml` as `[[test]] name =
//! "demo_smoke_tests"`; an empty file is a valid integration-test target.

// No tests defined yet — placeholder to satisfy the Cargo target declaration.
//! Binary screenshot smoke tests for Lurek2D demo content.
//!
//! Each test spawns the real `lurek2d` binary, runs a demo for 180 rendered
//! frames (~3 seconds at 60 FPS), captures a screenshot via `--screenshot`,
//! and asserts that the output PNG file exists and is valid.
//!
//! # Running
//!
//! ```bash
//! # Run all demo smoke tests (requires a pre-built binary and a display):
//! cargo test --test demo_smoke_tests -- --include-ignored
//!
//! # Run a single demo:
//! cargo test --test demo_smoke_tests demo_smoke_globe_demo -- --include-ignored
//! ```
//!
//! All tests are `#[ignore]` by default so they do not run in `cargo test`
//! without the `--include-ignored` flag.  They require:
//!   - A compiled `lurek2d` binary under `build/debug/` or `build/release/`.
//!   - A real display (GPU + window).  Use a virtual frame buffer on headless CI.
//!
//! The screenshot is written to `<demo_dir>/screenshot_smoke.png` (relative to
//! the repo root).  Stale screenshots from previous runs are deleted before
//! each test so failures are not masked by cached output.

use std::path::PathBuf;
use std::process::Command;
use std::time::{Duration, Instant};

// ─── helpers ──────────────────────────────────────────────────────────────────

/// Return an absolute path to the first lurek2d binary found.
/// Panics if neither the debug nor release binary exists.
fn find_binary() -> PathBuf {
    let candidates = [
        "build/release/lurek2d.exe",
        "build/debug/lurek2d.exe",
        "build/release/lurek2d",
        "build/debug/lurek2d",
    ];
    for rel in &candidates {
        let p = PathBuf::from(rel);
        if p.exists() {
            return p;
        }
    }
    panic!(
        "No lurek2d binary found. Build first:\n  cargo build\n  \
         or: cargo build --release"
    );
}

/// Spawn the engine for `demo_path`, wait for it to capture a screenshot and
/// exit, then return the absolute path to the screenshot PNG.
///
/// The binary is given 45 seconds to complete before the test aborts.
fn run_demo_screenshot(demo_path: &str) -> PathBuf {
    let binary = find_binary();

    // Resolve absolute paths — the --screenshot= flag requires an absolute path.
    let demo_abs = std::fs::canonicalize(demo_path).unwrap_or_else(|_| {
        panic!(
            "Demo directory not found: {demo_path}\n\
             Run from the repository root."
        )
    });
    let screenshot_abs = demo_abs.join("screenshot_smoke.png");

    // Remove any stale screenshot so we detect failures correctly.
    if screenshot_abs.exists() {
        std::fs::remove_file(&screenshot_abs).expect("Failed to remove stale screenshot");
    }

    let mut child = Command::new(&binary)
        .arg(&demo_abs)
        .arg(format!("--screenshot={}", screenshot_abs.display()))
        .arg("--screenshot-frames=180") // 3 seconds @ 60 FPS
        .spawn()
        .unwrap_or_else(|e| panic!("Failed to spawn {}: {e}", binary.display()));

    // Poll with a 45-second timeout.
    let deadline = Instant::now() + Duration::from_secs(45);
    loop {
        match child.try_wait().expect("Failed to poll child process") {
            Some(_status) => break,
            None => {
                if Instant::now() >= deadline {
                    let _ = child.kill();
                    panic!(
                        "Demo {demo_path} did not exit within 45 seconds. \
                         Make sure the engine exits automatically in screenshot mode."
                    );
                }
                std::thread::sleep(Duration::from_millis(200));
            }
        }
    }

    screenshot_abs
}

/// Assert that the file at `path` is a valid, non-trivial PNG.
fn assert_screenshot_valid(path: &PathBuf, demo_name: &str) {
    assert!(
        path.exists(),
        "Screenshot not created for {demo_name}: {path:?}\n\
         The engine may have crashed before reaching frame 180."
    );

    let size = std::fs::metadata(path)
        .unwrap_or_else(|e| panic!("Cannot stat screenshot for {demo_name}: {e}"))
        .len();

    assert!(
        size > 2048,
        "Screenshot for {demo_name} is only {size} bytes — \
         likely a blank or corrupt frame."
    );

    // Check PNG magic bytes: 0x89 P N G
    let bytes = std::fs::read(path)
        .unwrap_or_else(|e| panic!("Cannot read screenshot for {demo_name}: {e}"));
    assert!(
        bytes.starts_with(&[0x89, 0x50, 0x4E, 0x47]),
        "File {path:?} is not a valid PNG (bad magic bytes) for {demo_name}"
    );
}

// ─── macro ────────────────────────────────────────────────────────────────────

/// Generate a single `#[test] #[ignore]` function that runs the demo at
/// `$path` and validates its screenshot.
macro_rules! demo_smoke_test {
    ($fn_name:ident, $path:expr) => {
        #[test]
        #[ignore = "requires lurek2d binary and display — run with --include-ignored"]
        fn $fn_name() {
            let screenshot = run_demo_screenshot($path);
            assert_screenshot_valid(&screenshot, stringify!($fn_name));
        }
    };
}

// ─── showcase demos ───────────────────────────────────────────────────────────

demo_smoke_test!(demo_smoke_globe_demo, "content/games/showcase/globe_demo");
demo_smoke_test!(demo_smoke_hello_world, "content/games/showcase/hello_world");
demo_smoke_test!(demo_smoke_sprites, "content/games/showcase/sprites");
demo_smoke_test!(
    demo_smoke_particles_demo,
    "content/games/showcase/particles_demo"
);
demo_smoke_test!(demo_smoke_tween_demo, "content/games/showcase/tween_demo");
demo_smoke_test!(demo_smoke_scene_demo, "content/games/showcase/scene_demo");
demo_smoke_test!(demo_smoke_postfx_demo, "content/games/showcase/postfx_demo");
demo_smoke_test!(
    demo_smoke_minimap_demo,
    "content/games/showcase/minimap_demo"
);
demo_smoke_test!(demo_smoke_light_demo, "content/games/showcase/light_demo");
demo_smoke_test!(demo_smoke_demo_game, "content/games/showcase/demo_game");

// ─── arcade demos ─────────────────────────────────────────────────────────────

demo_smoke_test!(demo_smoke_pong, "content/games/arcade/pong");
demo_smoke_test!(demo_smoke_snake, "content/games/arcade/snake");
demo_smoke_test!(demo_smoke_tetris, "content/games/arcade/tetris");
demo_smoke_test!(demo_smoke_pac_man, "content/games/arcade/pac_man");
demo_smoke_test!(demo_smoke_asteroids, "content/games/arcade/asteroids");

// ─── simulation demos ─────────────────────────────────────────────────────────

demo_smoke_test!(
    demo_smoke_physics_demo,
    "content/games/simulation/physics_demo"
);
demo_smoke_test!(
    demo_smoke_physics_sandbox,
    "content/games/simulation/physics_sandbox"
);

// ─── action demos ─────────────────────────────────────────────────────────────

demo_smoke_test!(demo_smoke_platformer, "content/games/action/platformer");
demo_smoke_test!(
    demo_smoke_brick_breaker,
    "content/games/action/brick_breaker"
);

// ─── strategy demos ───────────────────────────────────────────────────────────

demo_smoke_test!(
    demo_smoke_tower_defense,
    "content/games/strategy/tower_defense"
);

// ─── showcase: HTML UI demos ──────────────────────────────────────────────────

demo_smoke_test!(demo_smoke_html_hud, "content/games/showcase/html-hud");
demo_smoke_test!(
    demo_smoke_html_inventory,
    "content/games/showcase/html-inventory"
);
demo_smoke_test!(demo_smoke_html_dialog, "content/games/showcase/html-dialog");
demo_smoke_test!(
    demo_smoke_html_load_document,
    "content/games/showcase/html-load-document"
);
demo_smoke_test!(
    demo_smoke_html_settings,
    "content/games/showcase/html-settings"
);
demo_smoke_test!(
    demo_smoke_html_scoreboard,
    "content/games/showcase/html-scoreboard"
);
