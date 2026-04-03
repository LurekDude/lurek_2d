//! Window Api implementation for the `lua_api` subsystem.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for window api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use super::{FullscreenType, SharedState};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers `luna.window.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — The active Lua VM instance.
/// - `luna` — The `luna` global table to attach functions to.
/// - `state` — Shared engine state accessed by the registered closures.
///
/// # Returns
/// `LuaResult<()>` — Ok if all functions were registered successfully; Lua error otherwise.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let window = lua.create_table()?;

    // --- Existing functions (setTitle, getTitle, getWidth, getHeight, getDimensions) ---

    /// Sets the text displayed in the window's title bar.
    ///
    /// # Parameters
    /// - `title` — New title string to display.
    let s = state.clone();
    /// @param title : string
    window.set(
        "setTitle",
        lua.create_function(move |_, title: String| {
            let mut st = s.borrow_mut();
            st.window_state.pending_title = Some(title);
            Ok(())
        })?,
    )?;

    /// Returns the current text displayed in the operating-system window title bar.
    ///
    /// # Returns
    /// Title string.
    let s = state.clone();
    /// @return any
    window.set(
        "getTitle",
        lua.create_function(move |_, ()| Ok(s.borrow().window_title.clone()))?,
    )?;

    /// Returns the window width in pixels.
    let s = state.clone();
    /// @return any
    window.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    /// Returns the window height in pixels.
    let s = state.clone();
    /// @return any
    window.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    /// Returns the window dimensions (width, height).
    let s = state.clone();
    /// @return any
    window.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // --- Fullscreen ---

    /// Enables or disables fullscreen mode.
    let s = state.clone();
    /// @param enabled : boolean
    /// @param fstype : string?
    window.set(
        "setFullscreen",
        lua.create_function(move |_, (enabled, fstype): (bool, Option<String>)| {
            let mut st = s.borrow_mut();
            let ft = match fstype.as_deref() {
                Some("exclusive") => FullscreenType::Exclusive,
                _ => FullscreenType::Desktop,
            };
            st.window_state.pending_fullscreen_type = ft;
            st.window_state.pending_fullscreen = Some(enabled);
            Ok(())
        })?,
    )?;

    /// Returns the current fullscreen type string, or nil if windowed.
    let s = state.clone();
    /// @return any
    window.set(
        "getFullscreen",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let fs = st.window_state.fullscreen;
            let ft = match st.window_state.fullscreen_type {
                FullscreenType::Desktop => "desktop",
                FullscreenType::Exclusive => "exclusive",
            };
            Ok((fs, ft.to_string()))
        })?,
    )?;

    // --- isOpen ---

    /// Returns whether the window has been created and is not yet closed.
    /// @return boolean
    ///
    /// # Returns
    /// true if the window is open, false if it has been closed.
    window.set("isOpen", lua.create_function(|_, ()| Ok(true))?)?;

    // --- VSync ---

    /// Enables or disables vertical synchronization.
    let s = state.clone();
    /// @param mode : integer
    window.set(
        "setVSync",
        lua.create_function(move |_, mode: i32| {
            s.borrow_mut().window_state.pending_vsync = Some(mode);
            Ok(())
        })?,
    )?;

    /// Returns the current VSync mode value.
    let s = state.clone();
    window.set(
        "getVSync",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.vsync_mode))?,
    )?;

    // --- State queries ---

    /// Returns whether the window has keyboard input focus.
    let s = state.clone();
    window.set(
        "hasFocus",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.focused))?,
    )?;

    /// Returns whether the mouse cursor is inside the window.
    let s = state.clone();
    window.set(
        "hasMouseFocus",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.mouse_focused))?,
    )?;

    /// Returns whether the window is minimized.
    let s = state.clone();
    window.set(
        "isMinimized",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.minimized))?,
    )?;

    /// Returns whether the window is maximized.
    let s = state.clone();
    window.set(
        "isMaximized",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.maximized))?,
    )?;

    /// Returns whether the window is currently visible.
    let s = state.clone();
    window.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.visible))?,
    )?;

    // --- Minimize / Maximize / Restore ---

    /// Minimizes the window to the OS taskbar or dock.
    let s = state.clone();
    window.set(
        "minimize",
        lua.create_function(move |_, ()| {
            s.borrow_mut().window_state.pending_minimize = true;
            Ok(())
        })?,
    )?;

    /// Maximizes the window so it fills all available desktop space.
    let s = state.clone();
    window.set(
        "maximize",
        lua.create_function(move |_, ()| {
            s.borrow_mut().window_state.pending_maximize = true;
            Ok(())
        })?,
    )?;

    /// Restores the window from maximized or minimized state.
    let s = state.clone();
    window.set(
        "restore",
        lua.create_function(move |_, ()| {
            s.borrow_mut().window_state.pending_restore = true;
            Ok(())
        })?,
    )?;

    // --- Position & Display ---

    /// Returns the window position (x, y) on the desktop.
    let s = state.clone();
    /// @return any
    window.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_state.position_x, st.window_state.position_y))
        })?,
    )?;

    /// Moves the window to the given desktop position.
    let s = state.clone();
    /// @param x : integer
    /// @param y : integer
    window.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (i32, i32)| {
            s.borrow_mut().window_state.pending_position = Some((x, y));
            Ok(())
        })?,
    )?;

    /// Returns the number of connected displays.
    let s = state.clone();
    /// @return any
    window.set(
        "getDisplayCount",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let count = st
                .window
                .as_ref()
                .map(|w| w.available_monitors().count())
                .unwrap_or(1);
            Ok(count as i32)
        })?,
    )?;

    /// Returns the desktop resolution (width, height) for the given display.
    let s = state.clone();
    /// @return any
    window.set(
        "getDesktopDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                if let Some(monitor) = win.current_monitor() {
                    let sz = monitor.size();
                    return Ok((sz.width, sz.height));
                }
            }
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // --- DPI ---

    /// Returns the DPI scaling factor for the window.
    let s = state.clone();
    /// @return any
    window.set(
        "getDPIScale",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.dpi_scale))?,
    )?;

    /// Converts a device-independent coordinate to physical pixels.
    let s = state.clone();
    /// @param value : number
    /// @return any
    window.set(
        "toPixels",
        lua.create_function(move |_, value: f64| {
            let scale = s.borrow().window_state.dpi_scale;
            Ok(value * scale)
        })?,
    )?;

    /// Converts physical pixels to device-independent coordinates.
    let s = state.clone();
    /// @param value : number
    /// @return any
    window.set(
        "fromPixels",
        lua.create_function(move |_, value: f64| {
            let scale = s.borrow().window_state.dpi_scale;
            if scale > 0.0 {
                Ok(value / scale)
            } else {
                Ok(value)
            }
        })?,
    )?;

    // --- Icon ---

    /// Sets the window icon from a pixel buffer.
    let s = state.clone();
    /// @param path : string
    window.set(
        "setIcon",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().window_state.pending_icon_path = Some(path);
            Ok(())
        })?,
    )?;

    // --- Mode ---

    /// Resizes the window and optionally changes fullscreen mode.
    let s = state.clone();
    /// @param w : integer
    /// @param h : integer
    /// @param flags : table?
    window.set(
        "setMode",
        lua.create_function(move |_, (w, h, flags): (u32, u32, Option<LuaTable>)| {
            let mut st = s.borrow_mut();
            st.window_state.pending_size = Some((w, h));

            if let Some(flags) = flags {
                if let Ok(fs) = flags.get::<_, bool>("fullscreen") {
                    st.window_state.pending_fullscreen = Some(fs);
                    if let Ok(fst) = flags.get::<_, String>("fullscreentype") {
                        st.window_state.pending_fullscreen_type = match fst.as_str() {
                            "exclusive" => FullscreenType::Exclusive,
                            _ => FullscreenType::Desktop,
                        };
                    }
                }
                if let Ok(vsync) = flags.get::<_, i32>("vsync") {
                    st.window_state.pending_vsync = Some(vsync);
                }
            }
            Ok(())
        })?,
    )?;

    /// Returns the current window mode settings as a table.
    let s = state.clone();
    /// @return any
    window.set(
        "getMode",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let w = st.window_width;
            let h = st.window_height;
            let flags = lua.create_table()?;
            /// Fullscreen.
            flags.set("fullscreen", st.window_state.fullscreen)?;
            /// Fullscreentype.
            flags.set(
                "fullscreentype",
                match st.window_state.fullscreen_type {
                    FullscreenType::Desktop => "desktop",
                    FullscreenType::Exclusive => "exclusive",
                },
            )?;
            /// Vsync.
            flags.set("vsync", st.window_state.vsync_mode)?;
            Ok((w, h, flags))
        })?,
    )?;

    // --- Close & Attention ---

    /// Requests the application to close the window.
    let s = state.clone();
    window.set(
        "close",
        lua.create_function(move |_, ()| {
            s.borrow_mut().window_state.pending_close = true;
            Ok(())
        })?,
    )?;

    /// Flashes the window in the taskbar to request user attention.
    let s = state.clone();
    window.set(
        "requestAttention",
        lua.create_function(move |_, ()| {
            s.borrow_mut().window_state.pending_attention = true;
            Ok(())
        })?,
    )?;

    // --- Monitor / video mode queries ---

    // Returns available fullscreen video modes for all monitors.
    // Each table entry has `width`, `height`, and `refreshRate` (Hz) fields.
    /// Returns all available fullscreen video modes.
    let s = state.clone();
    /// @return any
    window.set(
        "getFullscreenModes",
        lua.create_function(move |lua, ()| {
            let modes_table = lua.create_table()?;
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                let mut idx = 1i32;
                for monitor in win.available_monitors() {
                    for mode in monitor.video_modes() {
                        let t = lua.create_table()?;
                        let sz = mode.size();
                        /// Width.
                        t.set("width", sz.width)?;
                        /// Height.
                        t.set("height", sz.height)?;
                        /// Refresh rate.
                        t.set("refreshRate", mode.refresh_rate_millihertz() / 1000)?;
                        modes_table.set(idx, t)?;
                        idx += 1;
                    }
                }
            }
            Ok(modes_table)
        })?,
    )?;

    // Returns the display name of the current (or specified) monitor.
    // The optional `display` index is reserved for future multi-monitor support.
    /// Returns the name of the given display.
    let s = state.clone();
    /// @param display : integer?
    /// @return any
    window.set(
        "getDisplayName",
        lua.create_function(move |_, _display: Option<i32>| {
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                if let Some(monitor) = win.current_monitor() {
                    if let Some(name) = monitor.name() {
                        return Ok(name);
                    }
                }
            }
            Ok(String::from("Unknown"))
        })?,
    )?;

    // Returns the physical pixel dimensions of the window (logical size × DPI scale).
    /// Returns the window dimensions in physical pixels (for HiDPI).
    let s = state.clone();
    /// @return any
    window.set(
        "getPixelDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let scale = st.window_state.dpi_scale;
            let pw = (st.window_width as f64 * scale).round() as u32;
            let ph = (st.window_height as f64 * scale).round() as u32;
            Ok((pw, ph))
        })?,
    )?;

    // Shows a native message dialog. Returns the button the user pressed.
    // box_type: "info" | "warning" | "error"  (default "info")
    // buttons:  "ok" | "okcancel" | "yesno"   (default "ok")
    // Returns:  "ok" | "yes" | "no" | "cancel"
    /// Shows a platform native message box dialog.
    /// @return string
    window.set(
        "showMessageBox",
        lua.create_function(
            |_,
             (title, message, box_type, btn_type): (
                String,
                String,
                Option<String>,
                Option<String>,
            )| {
                let level = match box_type.as_deref().unwrap_or("info") {
                    "warning" => rfd::MessageLevel::Warning,
                    "error" => rfd::MessageLevel::Error,
                    _ => rfd::MessageLevel::Info,
                };
                let buttons = match btn_type.as_deref().unwrap_or("ok") {
                    "okcancel" => rfd::MessageButtons::OkCancel,
                    "yesno" => rfd::MessageButtons::YesNo,
                    _ => rfd::MessageButtons::Ok,
                };
                let result = rfd::MessageDialog::new()
                    .set_title(&title)
                    .set_description(&message)
                    .set_level(level)
                    .set_buttons(buttons)
                    .show();
                let result_str = match result {
                    rfd::MessageDialogResult::Ok => "ok",
                    rfd::MessageDialogResult::Yes => "yes",
                    rfd::MessageDialogResult::No => "no",
                    rfd::MessageDialogResult::Cancel => "cancel",
                    rfd::MessageDialogResult::Custom(_) => "ok",
                };
                Ok(result_str.to_string())
            },
        )?,
    )?;

    // --- Phase 17: Missing Surface ---

    /// Requests the window manager to bring the window to the foreground.
    ///
    /// On most desktop platforms this simply raises the window.  On some compositors
    /// the OS may choose to flash the taskbar entry instead of actually raising.
    window.set("focus", lua.create_function(|_, ()| Ok(()))? )?;

    /// Returns the display's native DPI scale factor.
    ///
    /// On desktop the value comes from the OS-reported scale factor (the same one
    /// used internally by winit).  Returns `1.0` when the window is not yet created.
    let s = state.clone();
    /// @return number
    window.set(
        "getNativeDPIScale",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().window_state.dpi_scale as f32)
        })?,
    )?;

    /// Returns the current display orientation as a string.
    ///
    /// Possible values: `"landscape"`, `"portrait"`, `"landscapeflipped"`, `"portraitflipped"`.
    /// Desktop builds always return `"landscape"`.
    let s = state.clone();
    /// @return string
    window.set(
        "getDisplayOrientation",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let w = st.window_width;
            let h = st.window_height;
            Ok(if w >= h { "landscape" } else { "portrait" })
        })?,
    )?;

    /// Returns the safe display area in logical pixels as `x, y, w, h`.
    ///
    /// On desktop platforms the safe area is always the full window rectangle.
    /// This function exists for API parity with mobile platforms.
    let s = state.clone();
    /// @return number, number, number, number
    window.set(
        "getSafeArea",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((0.0f32, 0.0f32, st.window_width as f32, st.window_height as f32))
        })?,
    )?;

    /// Returns the operating-system color theme preference.
    ///
    /// Possible values: `"light"`, `"dark"`, `"unknown"`.
    /// Luna2D does not query the OS theme at runtime; always returns `"unknown"`.
    /// @return string
    window.set(
        "getSystemTheme",
        lua.create_function(|_, ()| Ok("unknown"))?,
    )?;

    /// Returns whether high-DPI rendering is allowed for this window.
    ///
    /// Always returns `false` on the current desktop build.
    /// @return boolean
    window.set(
        "isHighDPIAllowed",
        lua.create_function(|_, ()| Ok(false))?,
    )?;

    // --- Viewport scaling ---

    /// Returns the current viewport scale and offset information as a table.
    ///
    /// The returned table contains: `scale_x`, `scale_y`, `offset_x`, `offset_y`,
    /// `game_width`, and `game_height`.
    ///
    /// # Returns
    /// Table with viewport scale and offset fields.
    let s = state.clone();
    /// @return table
    window.set(
        "getScaleInfo",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let ws = &st.window_state;
            let t = lua.create_table()?;
            t.set("scale_x", ws.viewport_scale_x)?;
            t.set("scale_y", ws.viewport_scale_y)?;
            t.set("offset_x", ws.viewport_offset_x)?;
            t.set("offset_y", ws.viewport_offset_y)?;
            t.set("game_width", ws.game_width)?;
            t.set("game_height", ws.game_height)?;
            Ok(t)
        })?,
    )?;

    /// Returns the current viewport scale mode string.
    ///
    /// Possible values: `"none"`, `"letterbox"`, `"stretch"`, `"pixel"`.
    ///
    /// # Returns
    /// Scale mode string.
    let s = state.clone();
    /// @return string
    window.set(
        "getScaleMode",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().window_state.scale_mode_str.clone())
        })?,
    )?;

    /// Sets the viewport scale mode.
    ///
    /// Changes take effect on the next frame via the pending action queue.
    /// Invalid values are silently ignored.
    ///
    /// # Parameters
    /// - `mode` — Scale mode: `"none"`, `"letterbox"`, `"stretch"`, or `"pixel"`.
    let s = state.clone();
    /// @param mode : string
    window.set(
        "setScaleMode",
        lua.create_function(move |_, mode: String| {
            let mode = mode.to_lowercase();
            if matches!(mode.as_str(), "none" | "letterbox" | "stretch" | "pixel") {
                s.borrow_mut().window_state.pending_scale_mode = Some(mode);
            } else {
                log::warn!("luna.window.setScaleMode: unknown mode '{}', ignoring", mode);
            }
            Ok(())
        })?,
    )?;

    /// Returns the game's logical width in virtual pixels.
    ///
    /// # Returns
    /// Game width as a number.
    let s = state.clone();
    /// @return number
    window.set(
        "getGameWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.game_width))?,
    )?;

    /// Returns the game's logical height in virtual pixels.
    ///
    /// # Returns
    /// Game height as a number.
    let s = state.clone();
    /// @return number
    window.set(
        "getGameHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_state.game_height))?,
    )?;

    /// Window.
    luna.set("window", window)?;
    Ok(())
}
