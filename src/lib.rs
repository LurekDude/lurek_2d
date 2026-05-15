#![allow(unused_doc_comments)]
#![allow(clippy::doc_lazy_continuation)]
//! Core Lurek2D crate modules and the top-level runtime entry point.

/// Exposes the AI subsystem module.
pub mod ai;
/// Exposes the animation subsystem module.
pub mod animation;
/// Exposes the application bootstrap and runtime loop module.
pub mod app;
/// Exposes the audio subsystem module.
pub mod audio;
#[cfg(feature = "automation-plugin")]
/// Exposes the automation subsystem module when the plugin is enabled.
pub mod automation;
/// Exposes the camera subsystem module.
pub mod camera;
/// Exposes the compute subsystem module.
pub mod compute;
/// Exposes the data utilities subsystem module.
pub mod data;
/// Exposes the dataframe subsystem module.
pub mod dataframe;
/// Exposes the debug bridge subsystem module.
pub mod debugbridge;
#[cfg(feature = "devtools-plugin")]
/// Exposes the developer tools subsystem module when the plugin is enabled.
pub mod devtools;
/// Exposes the runtime documentation subsystem module.
pub mod docs;
/// Exposes the ECS subsystem module.
pub mod ecs;
/// Exposes the visual effects subsystem module.
pub mod effect;
/// Exposes the event subsystem module.
pub mod event;
/// Exposes the filesystem subsystem module.
pub mod filesystem;
/// Exposes the globe subsystem module.
pub mod globe;
#[cfg(feature = "graph")]
/// Exposes the graph subsystem module when the feature is enabled.
pub mod graph;
/// Exposes the HTML subsystem module.
pub mod html;
/// Exposes the internationalization subsystem module.
pub mod i18n;
/// Exposes the image subsystem module.
pub mod image;
/// Exposes the input subsystem module.
pub mod input;
/// Exposes the lighting subsystem module.
pub mod light;
/// Exposes the structured logging subsystem module.
pub mod log;
/// Exposes the Lua API bridge subsystem module.
pub mod lua_api;
/// Exposes the math subsystem module.
pub mod math;
/// Exposes the minimap subsystem module.
pub mod minimap;
/// Exposes the mod management subsystem module.
pub mod mods;
/// Exposes the networking subsystem module.
pub mod network;
/// Exposes the parallax subsystem module.
pub mod parallax;
/// Exposes the particle subsystem module.
pub mod particle;
/// Exposes the pathfinding subsystem module.
pub mod pathfind;
/// Exposes the reusable patterns subsystem module.
pub mod patterns;
/// Exposes the physics subsystem module.
pub mod physics;
/// Exposes the pipeline subsystem module.
pub mod pipeline;
/// Exposes the procedural generation subsystem module.
pub mod procgen;
/// Exposes the province subsystem module.
pub mod province;
/// Exposes the raycaster subsystem module.
pub mod raycaster;
/// Exposes the rendering subsystem module.
pub mod render;
/// Exposes the core runtime subsystem module.
pub mod runtime;
/// Exposes the save subsystem module.
pub mod save;
/// Exposes the scene subsystem module.
pub mod scene;
/// Exposes the serialization subsystem module.
pub mod serial;
/// Exposes the spine animation subsystem module.
pub mod spine;
/// Exposes the sprite subsystem module.
pub mod sprite;
/// Exposes the terminal subsystem module.
pub mod terminal;
/// Exposes the threading subsystem module.
pub mod thread;
/// Exposes the tilemap subsystem module.
pub mod tilemap;
/// Exposes the timer subsystem module.
pub mod timer;
/// Exposes the tween subsystem module.
pub mod tween;
/// Exposes the UI subsystem module.
pub mod ui;
/// Exposes the window subsystem module.
pub mod window;

/// Starts the Lurek2D runtime using the current CLI arguments and active game path.
pub fn lurek_run() {
    use app::App;
    use runtime::Config;
    use std::env;
    std::panic::set_hook(Box::new(|info| {
        let payload = if let Some(s) = info.payload().downcast_ref::<&str>() {
            s.to_string()
        } else if let Some(s) = info.payload().downcast_ref::<String>() {
            s.clone()
        } else {
            "Unknown panic".to_string()
        };
        let location = info
            .location()
            .map(|l| format!(" at {}:{}:{}", l.file(), l.line(), l.column()))
            .unwrap_or_default();
        let msg = format!("Lurek2D panicked: {}{}", payload, location);
        log_msg!(
            error,
            crate::runtime::log_messages::L060_LUA_CALLBACK_ERROR,
            "{}",
            msg
        );
        #[cfg(target_os = "windows")]
        {
            let is_screenshot_mode = std::env::args().any(|a| a.starts_with("--screenshot"));
            if !is_screenshot_mode {
                show_windows_error_box(&msg);
            }
        }
        eprintln!("{}", msg);
        std::process::exit(1);
    }));
    let mut screenshot_path: Option<std::path::PathBuf> = None;
    let mut screenshot_frames: u32 = 3;
    let mut screenshot_time: Option<f32> = None;
    let mut window_x: Option<i32> = None;
    let mut window_y: Option<i32> = None;
    let mut window_width: Option<u32> = None;
    let mut window_height: Option<u32> = None;
    let mut game_arg: Option<String> = None;
    for arg in env::args().skip(1) {
        if let Some(val) = arg.strip_prefix("--screenshot=") {
            screenshot_path = Some(std::path::PathBuf::from(val));
        } else if let Some(val) = arg.strip_prefix("--screenshot-frames=") {
            if let Ok(n) = val.parse::<u32>() {
                screenshot_frames = n;
            }
        } else if let Some(val) = arg.strip_prefix("--screenshot-time=") {
            if let Ok(s) = val.parse::<f32>() {
                screenshot_time = Some(s);
            }
        } else if let Some(val) = arg.strip_prefix("--window-x=") {
            if let Ok(n) = val.parse::<i32>() {
                window_x = Some(n);
            }
        } else if let Some(val) = arg.strip_prefix("--window-y=") {
            if let Ok(n) = val.parse::<i32>() {
                window_y = Some(n);
            }
        } else if let Some(val) = arg.strip_prefix("--window-width=") {
            if let Ok(n) = val.parse::<u32>() {
                window_width = Some(n);
            }
        } else if let Some(val) = arg.strip_prefix("--window-height=") {
            if let Ok(n) = val.parse::<u32>() {
                window_height = Some(n);
            }
        } else if !arg.starts_with("--") {
            game_arg = Some(arg);
        }
    }
    let explicit_game_dir = game_arg.is_some();
    let mut _lurek_temp_dir: Option<tempfile::TempDir> = None;
    let game_dir = if let Some(ref arg) = game_arg {
        let path = std::path::PathBuf::from(arg);
        if path
            .extension()
            .map(|e| e.eq_ignore_ascii_case("lurek") || e.eq_ignore_ascii_case("lurek"))
            .unwrap_or(false)
        {
            match extract_lurek_archive(&path) {
                Ok(td) => {
                    let dir = td.path().to_path_buf();
                    _lurek_temp_dir = Some(td);
                    dir
                }
                Err(e) => {
                    let msg = format!("Failed to open .lurek archive '{}': {}", path.display(), e);
                    log_msg!(
                        error,
                        crate::runtime::log_messages::L060_LUA_CALLBACK_ERROR,
                        "{}",
                        msg
                    );
                    #[cfg(target_os = "windows")]
                    show_windows_error_box(&msg);
                    eprintln!("{}", msg);
                    return;
                }
            }
        } else {
            path
        }
    } else {
        env::current_dir().unwrap_or_else(|_| std::path::PathBuf::from("."))
    };
    let (mut config, conf_error) = Config::load(&game_dir);
    config.modules.validate_and_fix();
    if let Some(width) = window_width {
        config.window.width = width;
    }
    if let Some(height) = window_height {
        config.window.height = height;
    }
    let app = App::new(config, conf_error);
    app.run(
        game_dir,
        explicit_game_dir,
        screenshot_path,
        screenshot_frames,
        screenshot_time,
        window_x.zip(window_y),
    );
}
#[cfg(target_os = "windows")]
fn show_windows_error_box(msg: &str) {
    use std::ffi::OsStr;
    use std::iter::once;
    use std::os::windows::ffi::OsStrExt;
    fn to_wide(s: &str) -> Vec<u16> {
        OsStr::new(s).encode_wide().chain(once(0)).collect()
    }
    let text = to_wide(msg);
    let caption = to_wide("Lurek2D Crash");
    unsafe {
        windows_sys::Win32::UI::WindowsAndMessaging::MessageBoxW(
            std::ptr::null_mut(),
            text.as_ptr(),
            caption.as_ptr(),
            0x10,
        );
    }
}
fn extract_lurek_archive(
    archive_path: &std::path::Path,
) -> Result<tempfile::TempDir, Box<dyn std::error::Error>> {
    use std::fs;
    use std::io;
    let file = fs::File::open(archive_path)?;
    let mut archive = zip::ZipArchive::new(file)?;
    let temp_dir = tempfile::tempdir()?;
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i)?;
        let entry_name = entry.name().to_owned();
        let relative = std::path::Path::new(&entry_name);
        for component in relative.components() {
            match component {
                std::path::Component::Normal(_) | std::path::Component::CurDir => {}
                _ => {
                    return Err(format!("Unsafe path in .lurek archive: '{entry_name}'").into());
                }
            }
        }
        let dest = temp_dir.path().join(relative);
        if entry.is_dir() {
            fs::create_dir_all(&dest)?;
        } else {
            if let Some(parent) = dest.parent() {
                fs::create_dir_all(parent)?;
            }
            let mut out = fs::File::create(&dest)?;
            io::copy(&mut entry, &mut out)?;
        }
    }
    Ok(temp_dir)
}
