//! Luna2D — a 2D game engine written in Rust that loads and executes Lua game scripts.
//!
//! This crate is the engine library. It re-exports every subsystem through public submodules so
//! that the `luna2d` binary, integration tests, and tooling can all share the same code paths.
//! Game developers do not interact with this crate directly; they write Lua scripts that call
//! the `luna.*` API, which is registered by the Lua API layer on top of the types defined here.
//!
//! # Architecture overview
//!
//! The engine is split into domain modules with a strict dependency direction:
//! `engine` may depend on all modules; domain modules (`graphics`, `physics`, `audio`, `input`,
//! `timer`, `filesystem`, `math`, `window`) must not depend on each other except through `math`.
//!
//! The main entry point is [`luna_run`], which is called by both the `luna` (console) and
//! `lunec` (no-console) binaries. It installs the panic hook, parses CLI arguments, loads
//! `conf.lua`, and enters the main engine loop via [`engine::App::run`].
//!
//! # Submodule map
//!
//! | Module | Purpose |
//! |---|---|
//! | [`ai`] | FSM, behaviour trees, GOAP, Q-learning, influence maps, steering, squads |
//! | [`audio`] | Sound playback via rodio, bus routing, MIDI synthesis |
//! | [`battle`] | Turn-based battle engine: combatants, actions, statuses, turn order |
//! | [`cardgame`] | Card game backend: cards, decks (stacks), zones, card pools, history |
//! | [`combat`] | Vehicle combat: chassis, turrets, weapons, projectiles |
//! | [`compute`] | N-dimensional numerical arrays (luna.compute) |
//! | [`crafting`] | Recipe-based crafting queues and upgrade trees |
//! | [`data`] | LÖVE2D-compatible binary data: ByteData, compress, hash, encode, LÖVE2D pack format |
//! | [`dataframe`] | In-memory column-major tabular data |
//! | [`dialog`] | Dialogue sequencer for branching narrative with typewriter effect |
//! | [`economy`] | Named resource economy: capacity, flow rates, decay, and reservations |
//! | [`engine`] | App lifecycle, Config, EngineError, SharedState, debug overlay |
//! | [`entity`] | Lightweight ECS with ID recycling, bitmap tags, blueprints, systems |
//! | [`event`] | Event queue for polling and custom events |
//! | [`filesystem`] | Sandboxed game filesystem (GameFS) |
//! | [`graph`] | Directed graph with item-flow simulation and Dijkstra |
//! | [`graphics`] | GPU rendering pipeline via wgpu, draw commands, fonts |
//! | [`image`] | CPU-side RGBA8 pixel buffer for image manipulation |
//! | [`input`] | Keyboard, mouse, gamepad, and touch input state |
//! | [`inventory`] | Inventory slots, stacking, weight limits, equip slots |
//! | [`item`] | Item definitions, attributes, and loot-table rarity |
//! | [`math`] | Vec2, Mat3, Rect, polygon utilities, easing, noise |
//! | [`minimap`] | Minimap content extraction and FOV mask rendering |
//! | [`modding`] | Mod metadata, dependency resolution, and hook dispatch |
//! | [`particle`] | Emitter-based 2D particle effects |
//! | [`pathfinding`] | Grid pathfinding: A★, HPA★, flow fields, NavGrid |
//! | [`physics`] | Rigid bodies, AABB/circle collision, sensors, layer filtering |
//! | [`postfx`] | Post-processing effects data model: bloom, blur, color grading |
//! | [`province_map`] | Province/territory spatial data from colour-coded PNG images |
//! | [`quest`] | Quest tracking, objectives, branching completion states |
//! | [`raycaster`] | DDA grid raycaster for FPS/dungeon-crawler: walls, sprites, lighting, minimap |
//! | [`savegame`] | Slot-based save/load with schema versioning and auto-save |
//! | [`scene`] | Scene stack, depth-sorted rendering, visual transitions |
//! | [`stats`] | Character attributes, derived stats, and buff modifiers |
//! | [`tilemap`] | TileSet, TileMap, autotile, coordinate utilities, map generation |
//! | [`timer`] | Frame delta-time clock, `Clock::tick()`, and scheduled callbacks |
//! | [`thread`] | Background Rust worker threads and `Channel` inter-thread communication |
//! | [`window`] | winit event-loop wrapper and window state |

// Lua API files use `///` doc comments inside function bodies to document Lua-exposed
// bindings at their call site; these are intentional inline docs, not misplaced rustdoc.
#![allow(unused_doc_comments)]
// The same inline `///` blocks do not produce well-formed markdown list continuations;
// suppress that secondary lint across the whole crate.
#![allow(clippy::doc_lazy_continuation)]

/// Game AI toolkit: FSM, Behavior Trees, Steering, Pathfinding, Q-Learning, and more.
pub mod ai;
/// Sprite animation system: named clips, frame pools, speed control, and frame-level events.
pub mod animation;
/// Audio playback system backed by rodio.
pub mod audio;
/// Automated input simulation via timed step scripts for testing and replay.
pub mod automation;
/// Camera and viewport types for 2D rendering.
pub mod camera;
// migration-state: pub mod battle; — now library/battle/init.lua
// migration-state: pub mod cardgame; — now library/cardgame/init.lua
// migration-state: pub mod combat; — now library/combat/init.lua
/// Dense N-dimensional numerical arrays (luna.compute).
pub mod compute;
// migration-state: pub mod crafting; — now library/crafting/init.lua
/// LÖVE2D-compatible binary data API: ByteData, compress, hash, encode, and LÖVE2D pack format.
pub mod data;
/// In-memory column-major tabular data (luna.dataframe).
pub mod dataframe;
/// Format-agnostic serialization: JSON, TOML, CSV, and YAML via shared SerialValue.
pub mod serial;
// migration-state: pub mod dialog; — now library/dialog/init.lua
// migration-state: pub mod economy; — now library/economy/init.lua
/// Core engine lifecycle, configuration, and error types.
pub mod engine;
/// Lightweight entity-component-system with ID recycling, bitmap tags, layers, blueprints, and systems.
pub mod entity;
/// Event queue for polling system and custom events.
pub mod event;
/// Sandboxed game filesystem (GameFS).
pub mod filesystem;
/// Directed graph with item flow simulation, pathfinding, and supply/demand.
pub mod graph;
/// 2D GPU rendering pipeline, draw commands, and graphics types.
pub mod graphics;
/// Retained-mode widget UI system: buttons, panels, text fields, layouts.
pub mod gui;
/// CPU-side pixel-level image manipulation.
pub mod image;
/// Keyboard, mouse, and gamepad input state.
pub mod input;
/// 2D point-light data container for dynamic lighting systems.
pub mod light;
// migration-state: pub mod inventory; — now library/inventory/init.lua
// migration-state: pub mod item; — now library/item/init.lua
/// Composable visual effects layer: post-processing pipeline (bloom, blur, CRT, color grading) and screen overlays (weather, ambient, shake, fog).
pub mod fx;
/// Foundational math types: Vec2, Mat3, Rect.
pub mod math;
/// Minimap content extraction, FOV mask, and tile sampling.
pub mod minimap;
/// Mod management framework: metadata, dependencies, load ordering, hooks.
pub mod modding;
/// UDP networking via ENet — reliable packet transport for multiplayer games.
pub mod network;
/// (Deprecated — use `fx::screen` instead.) Composable per-frame screen-effect overlay.
// pub mod overlay; — superseded by fx::screen
/// Emitter-based 2D particle effects.
pub mod particle;
/// Grid pathfinding: A★, HPA★, flow fields, and NavGrid unit-size navigation.
pub mod pathfinding;
/// Physics simulation with rigid bodies (rect and circle shapes), collision events, sensors, and layer filtering.
pub mod physics;
/// DAG-based pipeline orchestrator for composing multi-step workflows.
pub mod pipeline;
/// (Deprecated — use `fx::post` instead.) Post-processing effects data model.
// pub mod postfx; — superseded by fx::post
/// Procedural world generation: cellular automata, Voronoi, flood fill, Poisson disk, periodic noise.
pub mod procgen;
/// Grid-based DDA raycaster for retro FPS and dungeon-crawler games: wall rendering, sprite projection, lighting, doors, heightmaps, minimap.
pub mod raycaster;
// migration-state: pub mod province_map; — now library/province_map/init.lua
// migration-state: pub mod quest; — now library/quest/init.lua
/// Slot-based save/load system with collectors, schema versioning, and auto-save.
pub mod savegame;
/// Scene stack for managing game scene lifecycle, transitions, and depth-sorted rendering.
pub mod scene;
/// Skeletal animation: bone hierarchies, slots, and world-transform propagation.
pub mod spine;
// migration-state: pub mod stats; — now library/stats/init.lua
/// Lua API registration layer: LuaJIT VM creation and `luna.*` module binding.
pub mod lua_api;
/// Grid-based character-cell terminal emulator and widget toolkit.
pub mod terminal;
/// Background Rust worker threads and `Channel` inter-thread communication.
pub mod thread;
/// Tilemap engine: TileSet, TileMap, autotile, coords, and procedural generation.
pub mod tilemap;
/// Frame delta-time clock, `Clock::tick()`, and scheduled callbacks.
pub mod timer;
/// Window event loop placeholder.
pub mod window;

/// Entry-point shared by both `luna` (console) and `lunec` (no-console) binaries.
///
/// Installs the panic hook, reads CLI arguments, loads the game config,
/// and runs the main engine loop. Both binary crates call this function.
///
/// When the first argument is a `.lunar` file (a zip archive containing a game),
/// the archive is extracted to a temporary directory and the engine runs from there.
/// The temporary directory is cleaned up automatically when the engine exits.
pub fn luna_run() {
    use engine::{App, Config};
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

        let msg = format!("Luna2D panicked: {}{}", payload, location);
        log_msg!(
            error,
            crate::engine::log_messages::L060_LUA_CALLBACK_ERROR,
            "{}",
            msg
        );

        #[cfg(target_os = "windows")]
        {
            show_windows_error_box(&msg);
        }

        eprintln!("{}", msg);
    }));

    // Parse CLI arguments. Supported flags:
    //   --screenshot=<path>       Absolute output path for the auto-screenshot PNG.
    //   --screenshot-delay=<secs> Seconds to wait after game start before capturing (default 1.5).
    let mut screenshot_path: Option<std::path::PathBuf> = None;
    let mut screenshot_delay: f64 = 1.5;
    let mut game_arg: Option<String> = None;

    for arg in env::args().skip(1) {
        if let Some(val) = arg.strip_prefix("--screenshot=") {
            screenshot_path = Some(std::path::PathBuf::from(val));
        } else if let Some(val) = arg.strip_prefix("--screenshot-delay=") {
            if let Ok(d) = val.parse::<f64>() {
                screenshot_delay = d;
            }
        } else if !arg.starts_with("--") {
            game_arg = Some(arg);
        }
    }

    let explicit_game_dir = game_arg.is_some();

    // Keep the temp dir alive for the entire engine session; it is dropped (and deleted)
    // after app.run() returns.
    let mut _lunar_temp_dir: Option<tempfile::TempDir> = None;

    let game_dir = if let Some(ref arg) = game_arg {
        let path = std::path::PathBuf::from(arg);
        if path
            .extension()
            .map(|e| e.eq_ignore_ascii_case("lunar"))
            .unwrap_or(false)
        {
            match extract_lunar_archive(&path) {
                Ok(td) => {
                    let dir = td.path().to_path_buf();
                    _lunar_temp_dir = Some(td);
                    dir
                }
                Err(e) => {
                    let msg = format!("Failed to open .lunar archive '{}': {}", path.display(), e);
                    log_msg!(
                        error,
                        crate::engine::log_messages::L060_LUA_CALLBACK_ERROR,
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

    let (mut config, conf_error) = Config::load_from_conf_lua(&game_dir);
    config.modules.validate_and_fix();
    let app = App::new(config, conf_error);
    app.run(game_dir, explicit_game_dir, screenshot_path, screenshot_delay);
}

/// Shows a Windows message box with an error message.
#[cfg(target_os = "windows")]
fn show_windows_error_box(msg: &str) {
    use std::ffi::OsStr;
    use std::iter::once;
    use std::os::windows::ffi::OsStrExt;

    fn to_wide(s: &str) -> Vec<u16> {
        OsStr::new(s).encode_wide().chain(once(0)).collect()
    }

    let text = to_wide(msg);
    let caption = to_wide("Luna2D Crash");

    // SAFETY: Calling Win32 MessageBoxW with valid null-terminated wide strings.
    // MB_OK | MB_ICONERROR = 0x10
    unsafe {
        windows_sys::Win32::UI::WindowsAndMessaging::MessageBoxW(
            std::ptr::null_mut(),
            text.as_ptr(),
            caption.as_ptr(),
            0x10,
        );
    }
}

/// Extracts a `.lunar` zip archive into a fresh temporary directory and returns
/// a handle to that directory.
///
/// The caller must keep the returned [`tempfile::TempDir`] alive for as long as
/// the extracted files are needed; dropping it deletes the directory.
///
/// # Parameters
/// - `archive_path` — `&std::path::Path`. Path to the `.lunar` file on disk.
///
/// # Returns
/// `Result<tempfile::TempDir, Box<dyn std::error::Error>>`.
fn extract_lunar_archive(
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

        // Sanitise path: reject absolute paths and any `..` components to
        // prevent zip-slip directory traversal.
        let relative = std::path::Path::new(&entry_name);
        for component in relative.components() {
            match component {
                std::path::Component::Normal(_) | std::path::Component::CurDir => {}
                _ => {
                    return Err(format!("Unsafe path in .lunar archive: '{entry_name}'").into());
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
