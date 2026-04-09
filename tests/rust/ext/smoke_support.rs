//! Shared helpers for runtime smoke tests under `tests/rust/ext`.

use std::collections::HashSet;
use std::ffi::{OsStr, OsString};
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::process::{Child, ExitStatus, Stdio};
use std::thread;
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

use image::RgbaImage;
use tempfile::TempDir;

pub(crate) struct ProcessOutput {
    pub(crate) status: ExitStatus,
    pub(crate) stdout: String,
    pub(crate) stderr: String,
}

pub(crate) struct ImageSummary {
    pub(crate) unique_colors: usize,
    pub(crate) non_black_pixels: usize,
    pub(crate) bright_pixels: usize,
    pub(crate) pixels_differing_from_first: usize,
}

pub(crate) fn unsupported_headless_linux() -> bool {
    cfg!(target_os = "linux")
        && std::env::var_os("DISPLAY").is_none()
        && std::env::var_os("WAYLAND_DISPLAY").is_none()
}

pub(crate) fn prepare_example_copy(example_name: &str) -> io::Result<(TempDir, PathBuf)> {
    let temp_dir = TempDir::new()?;
    let source_dir = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("examples")
        .join(example_name);
    let target_dir = temp_dir.path().join(example_name);

    copy_dir_recursive(&source_dir, &target_dir)?;

    let save_dir = target_dir.join("save");
    if save_dir.exists() {
        fs::remove_dir_all(&save_dir)?;
    }
    fs::create_dir_all(&save_dir)?;

    Ok((temp_dir, target_dir))
}

pub(crate) fn resolve_lurek2d_binary() -> PathBuf {
    if let Some(path) = std::env::var_os("CARGO_BIN_EXE_lurek2d") {
        return PathBuf::from(path);
    }

    if let Some(path) = option_env!("CARGO_BIN_EXE_lurek2d") {
        return PathBuf::from(path);
    }

    let exe_name = if cfg!(windows) {
        "lurek2d.exe"
    } else {
        "lurek2d"
    };

    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("build")
        .join("debug")
        .join(exe_name)
}

pub(crate) fn run_smoke_process<I, S>(
    binary_path: &Path,
    game_dir: &Path,
    args: I,
    timeout: Duration,
    label: &str,
) -> Result<ProcessOutput, String>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    let args: Vec<OsString> = args
        .into_iter()
        .map(|arg| arg.as_ref().to_os_string())
        .collect();
    let args_display = format_args_for_display(&args);

    let mut child = std::process::Command::new(binary_path)
        .current_dir(Path::new(env!("CARGO_MANIFEST_DIR")))
        .arg(game_dir)
        .args(&args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| {
            format!(
                "Failed to spawn {} against {} with args [{}]: {error}",
                binary_path.display(),
                game_dir.display(),
                args_display
            )
        })?;

    let stdout_reader = spawn_pipe_reader(child.stdout.take());
    let stderr_reader = spawn_pipe_reader(child.stderr.take());

    let status = match wait_for_exit(&mut child, timeout)
        .map_err(|error| format!("Failed while waiting for {label} process: {error}"))?
    {
        Some(status) => status,
        None => {
            let _ = child.kill();
            let _ = child.wait();

            let stdout = join_pipe_reader(stdout_reader, "stdout")?;
            let stderr = join_pipe_reader(stderr_reader, "stderr")?;

            return Err(format!(
                "{label} process timed out after {timeout:?} while running [{}]\nstdout:\n{}\nstderr:\n{}",
                args_display,
                stdout,
                stderr
            ));
        }
    };

    let stdout = join_pipe_reader(stdout_reader, "stdout")?;
    let stderr = join_pipe_reader(stderr_reader, "stderr")?;

    Ok(ProcessOutput {
        status,
        stdout,
        stderr,
    })
}

pub(crate) fn decode_png(path: &Path) -> Result<RgbaImage, String> {
    image::open(path)
        .map(|image| image.into_rgba8())
        .map_err(|error| format!("Failed to decode {}: {error}", path.display()))
}

pub(crate) fn summarize_image_content(image: &RgbaImage) -> ImageSummary {
    let mut unique_colors = HashSet::new();
    let mut non_black_pixels = 0usize;
    let mut bright_pixels = 0usize;
    let mut pixels_differing_from_first = 0usize;
    let first_pixel = image
        .pixels()
        .next()
        .map(|pixel| pixel.0)
        .unwrap_or([0, 0, 0, 0]);

    for pixel in image.pixels() {
        let rgba = pixel.0;
        unique_colors.insert(rgba);

        if rgba[3] != 0 && (rgba[0] != 0 || rgba[1] != 0 || rgba[2] != 0) {
            non_black_pixels += 1;
        }

        if rgba[3] != 0 && rgba[0].max(rgba[1]).max(rgba[2]) >= 200 {
            bright_pixels += 1;
        }

        if rgba != first_pixel {
            pixels_differing_from_first += 1;
        }
    }

    ImageSummary {
        unique_colors: unique_colors.len(),
        non_black_pixels,
        bright_pixels,
        pixels_differing_from_first,
    }
}

fn copy_dir_recursive(source: &Path, target: &Path) -> io::Result<()> {
    fs::create_dir_all(target)?;

    for entry in fs::read_dir(source)? {
        let entry = entry?;
        let source_path = entry.path();
        let target_path = target.join(entry.file_name());
        let file_type = entry.file_type()?;

        if file_type.is_dir() {
            copy_dir_recursive(&source_path, &target_path)?;
        } else if file_type.is_file() {
            fs::copy(&source_path, &target_path)?;
        }
    }

    Ok(())
}

fn wait_for_exit(child: &mut Child, timeout: Duration) -> io::Result<Option<ExitStatus>> {
    let start = Instant::now();

    loop {
        if let Some(status) = child.try_wait()? {
            return Ok(Some(status));
        }

        if start.elapsed() >= timeout {
            return Ok(None);
        }

        thread::sleep(Duration::from_millis(25));
    }
}

fn spawn_pipe_reader<T>(pipe: Option<T>) -> JoinHandle<io::Result<String>>
where
    T: Read + Send + 'static,
{
    thread::spawn(move || {
        let mut bytes = Vec::new();

        if let Some(mut pipe) = pipe {
            pipe.read_to_end(&mut bytes)?;
        }

        Ok(String::from_utf8_lossy(&bytes).into_owned())
    })
}

fn join_pipe_reader(handle: JoinHandle<io::Result<String>>, label: &str) -> Result<String, String> {
    match handle.join() {
        Ok(Ok(output)) => Ok(output),
        Ok(Err(error)) => Err(format!("Failed to read child {label}: {error}")),
        Err(_) => Err(format!("Child {label} reader thread panicked")),
    }
}

fn format_args_for_display(args: &[OsString]) -> String {
    args.iter()
        .map(|arg| arg.to_string_lossy().into_owned())
        .collect::<Vec<_>>()
        .join(" ")
}
