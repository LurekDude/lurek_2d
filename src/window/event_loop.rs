//! Event-loop helpers for window monitor selection and multi-display queries.
//!
//! The app module owns the `winit` event loop. This file contains data-only helper
//! functions used by both `app` and `lurek.window` monitor APIs.

use winit::event_loop::ActiveEventLoop;
use winit::monitor::MonitorHandle;
use winit::window::Window;

/// Display metadata snapshot used by Lua monitor query APIs.
#[derive(Debug, Clone)]
pub struct DisplayInfo {
	/// Zero-based display index from `available_monitors()` iteration order.
	pub index: i32,
	/// Human-readable display name when available.
	pub name: String,
	/// Top-left monitor position in virtual desktop coordinates.
	pub x: i32,
	/// Top-left monitor position in virtual desktop coordinates.
	pub y: i32,
	/// Monitor width in physical pixels.
	pub width: u32,
	/// Monitor height in physical pixels.
	pub height: u32,
	/// Monitor DPI scale factor.
	pub scale_factor: f64,
	/// Highest refresh rate reported by monitor video modes in hertz.
	pub refresh_rate_hz: u32,
	/// Whether this monitor is the current primary display.
	pub primary: bool,
}

fn monitor_signature(monitor: &MonitorHandle) -> (i32, i32, u32, u32) {
	let pos = monitor.position();
	let size = monitor.size();
	(pos.x, pos.y, size.width, size.height)
}

fn primary_signature(window: &Window) -> Option<(i32, i32, u32, u32)> {
	window.primary_monitor().as_ref().map(monitor_signature)
}

fn monitor_to_info(index: usize, monitor: &MonitorHandle, primary_sig: Option<(i32, i32, u32, u32)>) -> DisplayInfo {
	let pos = monitor.position();
	let size = monitor.size();
	let refresh_rate_hz = monitor
		.video_modes()
		.map(|mode| mode.refresh_rate_millihertz() / 1000)
		.max()
		.unwrap_or(60);
	let primary = primary_sig
		.map(|sig| sig == monitor_signature(monitor))
		.unwrap_or(false);

	DisplayInfo {
		index: index as i32,
		name: monitor.name().unwrap_or_else(|| format!("Display {}", index)),
		x: pos.x,
		y: pos.y,
		width: size.width,
		height: size.height,
		scale_factor: monitor.scale_factor(),
		refresh_rate_hz,
		primary,
	}
}

/// Returns all currently available displays as structured metadata.
pub fn get_displays(window: &Window) -> Vec<DisplayInfo> {
	let primary_sig = primary_signature(window);
	window
		.available_monitors()
		.enumerate()
		.map(|(index, monitor)| monitor_to_info(index, &monitor, primary_sig))
		.collect()
}

/// Returns the current display index for the window, if available.
pub fn current_display_index(window: &Window) -> Option<usize> {
	let current = window.current_monitor()?;
	let current_sig = monitor_signature(&current);
	window
		.available_monitors()
		.enumerate()
		.find(|(_, monitor)| monitor_signature(monitor) == current_sig)
		.map(|(idx, _)| idx)
}

fn monitor_by_index(window: &Window, display_index: Option<usize>) -> Option<MonitorHandle> {
	if let Some(index) = display_index {
		return window.available_monitors().nth(index);
	}
	window
		.current_monitor()
		.or_else(|| window.primary_monitor())
		.or_else(|| window.available_monitors().next())
}

/// Returns desktop dimensions `(width, height)` for the selected display.
pub fn desktop_dimensions_for_display(
	window: &Window,
	display_index: Option<usize>,
) -> Option<(u32, u32)> {
	monitor_by_index(window, display_index).map(|monitor| {
		let size = monitor.size();
		(size.width, size.height)
	})
}

/// Returns the display name for the selected display.
pub fn display_name_for_display(window: &Window, display_index: Option<usize>) -> Option<String> {
	monitor_by_index(window, display_index).map(|monitor| {
		monitor
			.name()
			.unwrap_or_else(|| String::from("Unknown display"))
	})
}

/// Moves and centers the window on the selected display.
///
/// Returns `true` when the monitor index exists and the move was applied.
pub fn move_window_to_display(window: &Window, display_index: usize) -> bool {
	let Some(monitor) = window.available_monitors().nth(display_index) else {
		return false;
	};

	let size = window.outer_size();
	center_window_on_monitor(window, &monitor, size.width, size.height);
	true
}

/// Selects startup monitor from config display index with primary fallback.
pub fn select_startup_monitor(
	event_loop: &ActiveEventLoop,
	display_index: u32,
) -> Option<MonitorHandle> {
	let primary = event_loop
		.primary_monitor()
		.or_else(|| event_loop.available_monitors().next());
	if display_index == 0 {
		return primary;
	}

	let monitor = event_loop.available_monitors().nth(display_index as usize);
	if monitor.is_none() {
		log::warn!(
			"Window display index {} unavailable, falling back to primary monitor",
			display_index
		);
	}
	monitor.or(primary)
}

/// Centers the window inside the selected monitor work area.
pub fn center_window_on_monitor(window: &Window, monitor: &MonitorHandle, width: u32, height: u32) {
	let monitor_size = monitor.size();
	let monitor_position = monitor.position();
	let x = monitor_position.x + ((monitor_size.width as i32 - width as i32).max(0) / 2);
	let y = monitor_position.y + ((monitor_size.height as i32 - height as i32).max(0) / 2);
	window.set_outer_position(winit::dpi::PhysicalPosition::new(x, y));
}
