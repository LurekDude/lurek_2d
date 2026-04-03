//! Luna2D — a 2D game engine written in Rust that loads and executes Lua game scripts.
//!
//! This crate is the engine library. It re-exports every subsystem through public submodules so
//! that the `luna2d` binary, integration tests, and tooling can all share the same code paths.
//! Game developers do not interact with this crate directly; they write Lua scripts that call
//! the `luna.*` API, which is registered by [`lua_api`] on top of the types defined here.
//!
//! # Architecture overview
//!
//! The engine is split into domain modules with a strict dependency direction:
//! `engine` may depend on all modules; `lua_api` bridges engine types to the Lua VM;
//! domain modules (`graphics`, `physics`, `audio`, `input`, `timer`, `filesystem`, `math`,
//! `window`) must not depend on each other except through `math`.
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
//! | [`data`] | Binary data, compression, hashing, base64/hex encoding |
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
//! | [`lua_api`] | Lua VM creation and all `luna.*` API bindings |
//! | [`math`] | Vec2, Mat3, Rect, polygon utilities, easing, noise |
//! | [`minimap`] | Minimap content extraction and FOV mask rendering |
//! | [`modding`] | Mod metadata, dependency resolution, and hook dispatch |
//! | [`particle`] | Emitter-based 2D particle effects |
//! | [`pathfinding`] | Grid pathfinding: A★, HPA★, flow fields, NavGrid |
//! | [`physics`] | Rigid bodies, AABB/circle collision, sensors, layer filtering |
//! | [`postfx`] | Post-processing effects data model: bloom, blur, color grading |
//! | [`province_map`] | Province/territory spatial data from colour-coded PNG images |
//! | [`quest`] | Quest tracking, objectives, branching completion states |
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
/// Audio playback system backed by rodio.
pub mod audio;
/// Card game backend engine: Card, Deck (Stack), DeckBuilder, Zone (StackManager), CardPool, Slot, StackHistory.
pub mod cardgame;
/// Turn-based battle engine: battles, combatants, abilities, and statuses.
pub mod battle;
/// Vehicle combat engine: chassis, turrets, weapons, projectiles, and collision groups.
pub mod combat;
/// Dense N-dimensional numerical arrays (luna.compute).
pub mod compute;
/// Crafting system: recipes, queues, upgrade trees.
pub mod crafting;
/// Binary data manipulation, compression, hashing, and encoding.
pub mod data;
/// In-memory column-major tabular data (luna.dataframe).
pub mod dataframe;
/// Dialog sequencer for visual-novel style text with typewriter effect, choices, waits, and callbacks.
pub mod dialog;
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
/// CPU-side pixel-level image manipulation.
pub mod image;
/// Keyboard, mouse, and gamepad input state.
pub mod input;
/// Item container and equip-slot inventory system.
pub mod inventory;
/// Generic item data structures: Item, Stack, StackBuilder, StackManager, ItemPool, Slot, StackHistory.
pub mod item;
/// Lua VM creation and the luna.* API bindings.
pub mod lua_api;
/// Foundational math types: Vec2, Mat3, Rect.
pub mod math;
/// Mod management framework: metadata, dependencies, load ordering, hooks.
pub mod modding;
/// Emitter-based 2D particle effects.
pub mod particle;
/// Minimap content extraction, FOV mask, and tile sampling.
pub mod minimap;
/// Post-processing effects data model: bloom, blur, color grading, screen-space shaders.
pub mod postfx;
/// Grid pathfinding: A★, HPA★, flow fields, and NavGrid unit-size navigation.
pub mod pathfinding;
/// Physics simulation with rigid bodies (rect and circle shapes), collision events, sensors, and layer filtering.
pub mod physics;
/// Province map module — spatial province data from colour-coded PNG images.
pub mod province_map;
/// Quest tracking: stages, objectives, quest log.
pub mod quest;
/// Named resource economy: capacity, flow rates, decay, interest, reservations, and overflow policies.
pub mod economy;
/// Slot-based save/load system with collectors, schema versioning, and auto-save.
pub mod savegame;
/// Scene stack for managing game scene lifecycle, transitions, and depth-sorted rendering.
pub mod scene;
/// Character attribute and buff system.
pub mod stats;
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
pub fn luna_run() {
    use engine::{App, Config};
    use std::env;
    use std::path::PathBuf;

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
        log::error!("{}", msg);

        #[cfg(target_os = "windows")]
        {
            show_windows_error_box(&msg);
        }

        eprintln!("{}", msg);
    }));

    let explicit_arg = env::args().nth(1);
    let explicit_game_dir = explicit_arg.is_some();
    let game_dir = explicit_arg
        .map(PathBuf::from)
        .unwrap_or_else(|| env::current_dir().unwrap_or_else(|_| PathBuf::from(".")));

    let (config, conf_error) = Config::load_from_conf_lua(&game_dir);
    let app = App::new(config, conf_error);
    app.run(game_dir, explicit_game_dir);
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
