//! Runtime smoke tests for renderer-backed example output.

use std::time::Duration;

mod smoke_support;

use smoke_support::{
    decode_png, prepare_example_copy, resolve_lurek2d_binary, run_smoke_process,
    summarize_image_content, unsupported_headless_linux,
};

const SCREENSHOT_REL_PATH: &str = "save/sprites_smoke.png";
const PROCESS_TIMEOUT: Duration = Duration::from_secs(20);

#[test]
fn sprites_smoke_mode_writes_non_blank_800x600_png() {
    if unsupported_headless_linux() {
        eprintln!("Skipping sprites smoke test: DISPLAY and WAYLAND_DISPLAY are unset.");
        return;
    }

    let (_temp_dir, game_dir) =
        prepare_example_copy("sprites").expect("Failed to prepare sprites copy");
    let screenshot_path = game_dir.join(SCREENSHOT_REL_PATH);
    let binary_path = resolve_lurek2d_binary();

    assert!(
        binary_path.is_file(),
        "Expected luna2d binary at {}, but it was not found.",
        binary_path.display()
    );
    assert!(
        !screenshot_path.exists(),
        "Screenshot path should be cleared before the smoke run: {}",
        screenshot_path.display()
    );

    let output = run_smoke_process(
        &binary_path,
        &game_dir,
        [
            String::from("--smoke-sprites"),
            format!("--smoke-screenshot={SCREENSHOT_REL_PATH}"),
        ],
        PROCESS_TIMEOUT,
        "sprites smoke",
    )
    .unwrap_or_else(|message| panic!("{message}"));

    assert!(
        output.status.success(),
        "sprites smoke process exited with {:?}\nstdout:\n{}\nstderr:\n{}",
        output.status.code(),
        output.stdout,
        output.stderr
    );
    assert!(
        screenshot_path.is_file(),
        "Smoke run exited successfully but did not create {}\nstdout:\n{}\nstderr:\n{}",
        screenshot_path.display(),
        output.stdout,
        output.stderr
    );

    let image = decode_png(&screenshot_path).unwrap_or_else(|error| panic!("{error}"));

    assert_eq!(
        image.width(),
        800,
        "sprites smoke screenshot width mismatch"
    );
    assert_eq!(
        image.height(),
        600,
        "sprites smoke screenshot height mismatch"
    );

    let summary = summarize_image_content(&image);
    let _ = summary.non_black_pixels;
    assert!(
        summary.unique_colors > 5,
        "Sprites smoke screenshot looks too uniform: only {} unique colors found",
        summary.unique_colors
    );
    assert!(
        summary.pixels_differing_from_first > 4_000,
        "Sprites smoke screenshot looks too close to a flat background: only {} pixels differ from the first pixel",
        summary.pixels_differing_from_first
    );
    assert!(
        summary.bright_pixels > 500,
        "Sprites smoke screenshot is missing bright foreground detail: only {} bright pixels found",
        summary.bright_pixels
    );
}
