//! Lua API binding modules and shared runtime re-exports for building Lurek2D Lua VMs.

pub use crate::runtime::{ErrorInfo, FullscreenType, SharedState, WindowState};
/// Exposes the `lurek.ai` binding module.
pub mod ai_api;
/// Exposes the `lurek.animation` binding module.
pub mod animation_api;
/// Exposes the `lurek.audio` binding module.
pub mod audio_api;
/// Exposes the `lurek.automation` binding module.
pub mod automation_api;
/// Exposes shared callback registry helpers for Lua bindings.
pub mod callback_registry;
/// Exposes the `lurek.camera` binding module.
pub mod camera_api;
/// Exposes the `lurek.compute` binding module.
pub mod compute_api;
/// Exposes the `lurek.data` binding module.
pub mod data_api;
/// Exposes the `lurek.dataframe` binding module.
pub mod dataframe_api;
/// Exposes the `lurek.debugbridge` binding module.
pub mod debugbridge_api;
/// Exposes the `lurek.devtools` binding module.
pub mod devtools_api;
/// Exposes the `lurek.docs` binding module.
pub mod docs_api;
/// Exposes the `lurek.ecs` binding module.
pub mod ecs_api;
/// Exposes the `lurek.effect` binding module.
pub mod effect_api;
/// Exposes the `lurek.runtime` binding module.
pub mod engine_api;
/// Exposes the `lurek.event` binding module.
pub mod event_api;
/// Exposes the `lurek.filesystem` binding module.
pub mod filesystem_api;
/// Exposes the `lurek.globe` binding module.
pub mod globe_api;
/// Exposes the `lurek.graph` binding module.
pub mod graph_api;
/// Exposes the `lurek.html` binding module.
pub mod html_api;
/// Exposes the `lurek.i18n` binding module.
pub mod i18n_api;
/// Exposes the `lurek.image` binding module.
pub mod image_api;
/// Exposes the `lurek.input` binding module.
pub mod input_api;
/// Exposes the `lurek.light` binding module.
pub mod light_api;
/// Exposes the `lurek.log` binding module.
pub mod log_api;
/// Exposes shared Lua binding type helpers.
pub mod lua_types;
/// Exposes the `lurek.math` binding module.
pub mod math_api;
/// Exposes the `lurek.minimap` binding module.
pub mod minimap_api;
/// Exposes the `lurek.mods` binding module.
pub mod mods_api;
/// Exposes the `lurek.network` binding module.
pub mod network_api;
/// Exposes the `lurek.parallax` binding module.
pub mod parallax_api;
/// Exposes the `lurek.particle` binding module.
pub mod particle_api;
/// Exposes the `lurek.pathfind` binding module.
pub mod pathfind_api;
/// Exposes the `lurek.patterns` binding module.
pub mod patterns_api;
/// Exposes the `lurek.physics` binding module.
pub mod physics_api;
/// Exposes the `lurek.pipeline` binding module.
pub mod pipeline_api;
/// Exposes the `lurek.procgen` binding module.
pub mod procgen_api;
/// Exposes the `lurek.province` binding module.
pub mod province_api;
/// Exposes the `lurek.raycaster` binding module.
pub mod raycaster_api;
/// Exposes Lua VM registration helpers.
pub mod register;
/// Exposes the `lurek.render` binding module.
pub mod render_api;
/// Exposes the `lurek.save` binding module.
pub mod save_api;
/// Exposes the `lurek.scene` binding module.
pub mod scene_api;
/// Exposes the `lurek.serial` binding module.
pub mod serial_api;
/// Exposes the `lurek.spine` binding module.
pub mod spine_api;
/// Exposes the `lurek.sprite` binding module.
pub mod sprite_api;
/// Exposes the `lurek.runtime` system binding module.
pub mod system_api;
/// Exposes the `lurek.terminal` binding module.
pub mod terminal_api;
/// Exposes the `lurek.thread` binding module.
pub mod thread_api;
/// Exposes the `lurek.tilemap` binding module.
pub mod tilemap_api;
/// Exposes the `lurek.timer` binding module.
pub mod timer_api;
/// Exposes the `lurek.tween` binding module.
pub mod tween_api;
/// Exposes the `lurek.ui` binding module.
pub mod ui_api;
/// Exposes the `lurek.window` binding module.
pub mod window_api;
pub use register::{create_lua_vm, create_test_vm};
