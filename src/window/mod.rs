//! - OS window lifecycle: creation, sizing, positioning, fullscreen, and DPI handling.
//! - Multi-monitor support: display enumeration, selection, and window placement.
//! - Virtual viewport: logical-to-pixel scaling and scale-mode selection.

/// Event-loop helpers: display enumeration, monitor selection, window centering, and startup placement.
pub mod event_loop;
/// OS window control: size, position, title, DPI, fullscreen, vsync, focus, icon, and message boxes.
pub mod management;
/// Virtual viewport scaling: logical-to-pixel mapping and scale-mode selection.
pub mod viewport;
pub use event_loop::{center_window_on_monitor, current_display_index, desktop_dimensions_for_display, display_name_for_display, get_displays, move_window_to_display, select_startup_monitor, DisplayInfo};
pub use management::{close, flash, from_dpi_pixels, get_dpi_scale, get_fullscreen, get_fullscreen_type_str, get_mode, get_pixel_dimensions, get_position, get_vsync, has_focus, has_mouse_focus, is_fullscreen, is_maximized, is_minimized, is_visible, maximize, minimize, request_attention, restore, set_display, set_fullscreen, set_icon, set_mode, set_position, set_size, set_title, set_vsync, show_message_box, to_dpi_pixels, ModeInfo};
pub use viewport::{from_pixels, get_height, get_scale_info, get_scale_mode, get_width, set_scale_mode, set_scale_mode_validated, to_pixels, ScaleInfo};
