
use std::env;
use std::fs::{self, File};
use std::io::{Seek, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};
use zip::write::FileOptions;
/// Print CLI usage and supported subcommands.
fn print_usage() {
    eprintln!("lurek_headless <command> [args]\n");
    eprintln!("Commands:");
    eprintln!("  validate [game_dir]");
    eprintln!("  pack <game_dir> <output.lurek>");
    eprintln!("  screenshot-batch <games_root> <output_dir> [frames]");
}
/// Run the game validator script for one game directory or default discovery path.
fn run_validate(game_dir: Option<String>) -> Result<(), String> {
    let mut cmd = Command::new("python");
    cmd.arg("tools/validate/validate_game.py");
    if let Some(dir) = game_dir {
        cmd.arg(dir);
    }
    let status = cmd
        .status()
        .map_err(|e| format!("failed to run validator: {}", e))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("validator exited with status {}", status))
    }
}
/// Recursively add files from `dir` into ZIP archive using paths relative to `root`.
fn add_dir_to_zip<W: Write + Seek>(
    zip: &mut zip::ZipWriter<W>,
    root: &Path,
    dir: &Path,
) -> Result<(), String> {
    let options: FileOptions<'_, ()> = FileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated)
        .unix_permissions(0o644);
    for entry in fs::read_dir(dir).map_err(|e| format!("read_dir failed: {}", e))? {
        let entry = entry.map_err(|e| format!("dir entry failed: {}", e))?;
        let path = entry.path();
        if path.is_dir() {
            add_dir_to_zip(zip, root, &path)?;
            continue;
        }
        let rel = path
            .strip_prefix(root)
            .map_err(|e| format!("strip_prefix failed: {}", e))?;
        let name = rel.to_string_lossy().replace('\\', "/");
        let bytes =
            fs::read(&path).map_err(|e| format!("read '{}' failed: {}", path.display(), e))?;
        zip.start_file(name, options)
            .map_err(|e| format!("zip start_file failed: {}", e))?;
        zip.write_all(&bytes)
            .map_err(|e| format!("zip write failed: {}", e))?;
    }
    Ok(())
}
/// Pack a game directory into a `.lurek` archive after checking for `main.lua`.
fn run_pack(game_dir: String, output: String) -> Result<(), String> {
    let root = PathBuf::from(&game_dir);
    if !root.join("main.lua").exists() {
        return Err(format!("'{}' does not contain main.lua", root.display()));
    }
    let out_path = PathBuf::from(output);
    if let Some(parent) = out_path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)
                .map_err(|e| format!("failed to create output directory: {}", e))?;
        }
    }
    let file = File::create(&out_path)
        .map_err(|e| format!("failed to create archive '{}': {}", out_path.display(), e))?;
    let mut zip = zip::ZipWriter::new(file);
    add_dir_to_zip(&mut zip, &root, &root)?;
    zip.finish()
        .map_err(|e| format!("failed to finalize archive: {}", e))?;
    Ok(())
}
/// Run screenshot capture for each valid game folder under `games_root`.
fn run_screenshot_batch(games_root: String, out_dir: String, frames: u32) -> Result<(), String> {
    let root = PathBuf::from(games_root);
    let out = PathBuf::from(out_dir);
    fs::create_dir_all(&out).map_err(|e| format!("failed to create output dir: {}", e))?;
    let engine_bin = if cfg!(windows) {
        PathBuf::from("lurek2d.exe")
    } else {
        PathBuf::from("lurek2d")
    };
    for entry in fs::read_dir(&root).map_err(|e| format!("read_dir failed: {}", e))? {
        let entry = entry.map_err(|e| format!("dir entry failed: {}", e))?;
        let game_dir = entry.path();
        if !game_dir.is_dir() || !game_dir.join("main.lua").exists() {
            continue;
        }
        let name = game_dir
            .file_name()
            .and_then(|n| n.to_str())
            .ok_or_else(|| "invalid game folder name".to_string())?;
        let shot_path = out.join(format!("{}.png", name));
        let status = Command::new(&engine_bin)
            .arg(&game_dir)
            .arg(format!("--screenshot={}", shot_path.display()))
            .arg(format!("--screenshot-frames={}", frames))
            .status()
            .map_err(|e| format!("failed to run lurek2d for '{}': {}", game_dir.display(), e))?;
        if !status.success() {
            return Err(format!(
                "screenshot command failed for '{}' with status {}",
                game_dir.display(),
                status
            ));
        }
    }
    Ok(())
}
/// Parse command-line arguments, execute selected command, and map errors to exit codes.
fn main() -> ExitCode {
    let mut args = env::args().skip(1);
    let Some(cmd) = args.next() else {
        print_usage();
        return ExitCode::from(2);
    };
    let result = match cmd.as_str() {
        "validate" => run_validate(args.next()),
        "pack" => {
            let Some(game_dir) = args.next() else {
                print_usage();
                return ExitCode::from(2);
            };
            let Some(output) = args.next() else {
                print_usage();
                return ExitCode::from(2);
            };
            run_pack(game_dir, output)
        }
        "screenshot-batch" => {
            let Some(games_root) = args.next() else {
                print_usage();
                return ExitCode::from(2);
            };
            let Some(out_dir) = args.next() else {
                print_usage();
                return ExitCode::from(2);
            };
            let frames = args.next().and_then(|v| v.parse::<u32>().ok()).unwrap_or(3);
            run_screenshot_batch(games_root, out_dir, frames)
        }
        _ => {
            print_usage();
            return ExitCode::from(2);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("lurek_headless error: {}", e);
            ExitCode::from(1)
        }
    }
}
