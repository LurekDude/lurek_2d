//! Smoke test for the real `examples/terminal_demo` runtime path.

use std::time::Duration;

mod smoke_support;

use smoke_support::{
    decode_png, prepare_example_copy, resolve_lurek2d_binary, run_smoke_process,
    summarize_image_content, unsupported_headless_linux,
};

const SCREENSHOT_REL_PATH: &str = "save/terminal_demo_smoke.png";
const PROCESS_TIMEOUT: Duration = Duration::from_secs(20);

#[test]
#[ignore]
fn terminal_demo_smoke_mode_writes_non_blank_800x600_png() {
    if unsupported_headless_linux() {
        eprintln!("Skipping terminal_demo smoke test: DISPLAY and WAYLAND_DISPLAY are unset.");
        return;
    }

    let (_temp_dir, game_dir) =
        prepare_example_copy("terminal_demo").expect("Failed to prepare terminal_demo copy");
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
            String::from("--smoke-terminal-demo"),
            format!("--smoke-screenshot={SCREENSHOT_REL_PATH}"),
        ],
        PROCESS_TIMEOUT,
        "terminal_demo smoke",
    )
    .unwrap_or_else(|message| panic!("{message}"));

    assert!(
        output.status.success(),
        "terminal_demo smoke process exited with {:?}\nstdout:\n{}\nstderr:\n{}",
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
        "terminal_demo smoke screenshot width mismatch"
    );
    assert_eq!(
        image.height(),
        600,
        "terminal_demo smoke screenshot height mismatch"
    );

    let summary = summarize_image_content(&image);
    let _ = (summary.bright_pixels, summary.pixels_differing_from_first);
    assert!(
        summary.unique_colors > 4,
        "Smoke screenshot looks too uniform: only {} unique colors sampled",
        summary.unique_colors
    );
    assert!(
        summary.non_black_pixels > 500,
        "Smoke screenshot looks effectively blank: only {} non-black pixels found",
        summary.non_black_pixels
    );
}
