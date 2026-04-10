//! Window management — Tier 1 Engine Subsystem.
//!
//! Provides pure Rust functions for reading and writing [`crate::runtime::shared_state::WindowState`]
//! fields.  **No winit calls are made in this module.**  Deferred window operations are placed in
//! `pending_*` fields and consumed by `engine::app::App` at the start of the next frame.
//!
//! ## Files
//!
//! | File | Scope |
//! |------|-------|
//! | `management` | Title, fullscreen, vsync, position, size, minimize, maximize, close, icon |
//! | `viewport` | Logical dimensions, scale mode, pixel ↔ game-space coordinate conversion |
//! | `event_loop` | Reserved for future platform-specific event loop integration |

/// Window management commands: title, fullscreen, position, size, minimize, maximize, close, icon.
pub mod management;

/// Viewport utilities: logical dimensions, scale mode, pixel ↔ game-space conversion.
pub mod viewport;

/// Reserved for future platform-specific event loop integration.
pub mod event_loop;

pub use management::{
    close, from_dpi_pixels, get_dpi_scale, get_fullscreen, get_fullscreen_type_str, get_mode,
    get_pixel_dimensions, get_position, get_vsync, has_focus, has_mouse_focus, is_fullscreen,
    is_maximized, is_minimized, is_visible, maximize, minimize, request_attention, restore,
    set_fullscreen, set_icon, set_mode, set_position, set_size, set_title, set_vsync,
    show_message_box, to_dpi_pixels, ModeInfo,
};
pub use viewport::{
    from_pixels, get_height, get_scale_info, get_scale_mode, get_width, set_scale_mode,
    set_scale_mode_validated, to_pixels, ScaleInfo,
};
