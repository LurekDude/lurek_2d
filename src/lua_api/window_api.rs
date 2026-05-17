//! `lurek.window` - Provides window management with resizing, fullscreen, title, icon, DPI scaling, and display mode control.

use super::SharedState;
use crate::window;
use mlua::prelude::*;
use rfd;
use std::cell::RefCell;
use std::rc::Rc;

/// Registers the `lurek.window` module and all its Lua-facing methods.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- setTitle --
    /// Sets the window title bar text. This function is exposed to Lua scripts.
    /// @param | title | string | The new window title to display.
    /// @return | nil | No return value.
    tbl.set(
        "setTitle",
        lua.create_function(move |_, title: String| {
            window::set_title(&mut s.borrow_mut().window_state, &title);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getTitle --
    /// Returns the current window title bar text.
    /// @return | string | The current window title.
    tbl.set(
        "getTitle",
        lua.create_function(move |_, ()| Ok(s.borrow().window_title.clone()))?,
    )?;
    let s = state.clone();
    // -- getWidth --
    /// Returns the current window width in logical (DPI-independent) pixels.
    /// @return | number | The window width.
    tbl.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;
    let s = state.clone();
    // -- getHeight --
    /// Returns the current window height in logical (DPI-independent) pixels.
    /// @return | number | The window height.
    tbl.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;
    let s = state.clone();
    // -- getDimensions --
    /// Returns the current window width and height in logical pixels.
    /// @return | number | The window width.
    /// @return | number | The window height.
    tbl.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;
    let s = state.clone();
    // -- setFullscreen --
    /// Enables or disables fullscreen mode. Supports "desktop" (borderless) and "exclusive" types.
    /// @param | enabled | boolean | Whether to enter fullscreen.
    /// @param | fstype | string? | Fullscreen type: "desktop" (default) or "exclusive".
    /// @return | nil | No return value.
    tbl.set(
        "setFullscreen",
        lua.create_function(move |_, (enabled, fstype): (bool, Option<String>)| {
            window::set_fullscreen(
                &mut s.borrow_mut().window_state,
                enabled,
                fstype.as_deref().unwrap_or("desktop"),
            );
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getFullscreen --
    /// Returns the current fullscreen state and type.
    /// @return | boolean | Whether the window is in fullscreen mode.
    tbl.set(
        "getFullscreen",
        lua.create_function(move |_, ()| Ok(window::get_fullscreen(&s.borrow().window_state)))?,
    )?;
    // -- isOpen --
    /// Returns whether the window is currently open. Always returns true while the game is running.
    /// @return | boolean | True if the window exists.
    tbl.set("isOpen", lua.create_function(|_, ()| Ok(true))?)?;
    let s = state.clone();
    // -- setVSync --
    /// Sets the vertical sync mode. Controls how frame presentation is synchronized with the display.
    /// @param | mode | integer | VSync mode: 0 = off, 1 = on, -1 = adaptive.
    /// @return | nil | No return value.
    tbl.set(
        "setVSync",
        lua.create_function(move |_, mode: i32| {
            window::set_vsync(&mut s.borrow_mut().window_state, mode);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getVSync --
    /// Returns the current VSync mode. This function is exposed to Lua scripts.
    /// @return | number | The VSync mode: 0 = off, 1 = on, -1 = adaptive.
    tbl.set(
        "getVSync",
        lua.create_function(move |_, ()| Ok(window::get_vsync(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- hasFocus --
    /// Returns whether the window currently has keyboard focus.
    /// @return | boolean | True if the window has keyboard input focus.
    tbl.set(
        "hasFocus",
        lua.create_function(move |_, ()| Ok(window::has_focus(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- hasMouseFocus --
    /// Returns whether the mouse cursor is inside the window.
    /// @return | boolean | True if the mouse cursor is within the window bounds.
    tbl.set(
        "hasMouseFocus",
        lua.create_function(move |_, ()| Ok(window::has_mouse_focus(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- isMinimized --
    /// Returns whether the window is currently minimized to the taskbar.
    /// @return | boolean | True if the window is minimized.
    tbl.set(
        "isMinimized",
        lua.create_function(move |_, ()| Ok(window::is_minimized(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- isMaximized --
    /// Returns whether the window is currently maximized.
    /// @return | boolean | True if the window is maximized.
    tbl.set(
        "isMaximized",
        lua.create_function(move |_, ()| Ok(window::is_maximized(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- isVisible --
    /// Returns whether the window is currently visible on screen.
    /// @return | boolean | True if the window is visible.
    tbl.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(window::is_visible(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- minimize --
    /// Minimizes the window to the taskbar.
    /// @return | nil | No return value.
    tbl.set(
        "minimize",
        lua.create_function(move |_, ()| {
            window::minimize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- maximize --
    /// Maximizes the window to fill the screen.
    /// @return | nil | No return value.
    tbl.set(
        "maximize",
        lua.create_function(move |_, ()| {
            window::maximize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- restore --
    /// Restores the window from minimized or maximized state to its previous size and position.
    /// @return | nil | No return value.
    tbl.set(
        "restore",
        lua.create_function(move |_, ()| {
            window::restore(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getPosition --
    /// Returns the window position on screen in pixels.
    /// @return | number | The x-coordinate of the window's top-left corner.
    /// @return | number | The y-coordinate of the window's top-left corner.
    tbl.set(
        "getPosition",
        lua.create_function(move |_, ()| Ok(window::get_position(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- setPosition --
    /// Moves the window to the specified screen position.
    /// @param | x | integer | The x-coordinate for the window's top-left corner.
    /// @param | y | integer | The y-coordinate for the window's top-left corner.
    /// @return | nil | No return value.
    tbl.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (i32, i32)| {
            window::set_position(&mut s.borrow_mut().window_state, x, y);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getDisplayCount --
    /// Returns the number of connected displays (monitors).
    /// @return | number | The total number of available displays.
    tbl.set(
        "getDisplayCount",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .map(|w| window::get_displays(w).len() as i32)
                .unwrap_or(1))
        })?,
    )?;
    let s = state.clone();
    // -- getDisplays --
    /// Returns a list of all connected displays with their properties. Each entry contains index, name, position (x, y), resolution (width, height), scale factor, refresh rate, and whether it is the primary monitor.
    /// @return | table | Array of display info tables with fields: index, name, x, y, width, height, scale, refreshRate, primary.
    tbl.set(
        "getDisplays",
        lua.create_function(move |lua, ()| {
            let result = lua.create_table()?;
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                for (idx, display) in window::get_displays(win).iter().enumerate() {
                    let info = lua.create_table()?;
                    /// Performs the 'index' operation.
                    /// @return | nil | No value is returned.
                    info.set("index", display.index)?;
                    /// Performs the 'name' operation.
                    /// @return | nil | No value is returned.
                    info.set("name", display.name.as_str())?;
                    /// Performs the 'x' operation.
                    /// @return | nil | No value is returned.
                    info.set("x", display.x)?;
                    /// Performs the 'y' operation.
                    /// @return | nil | No value is returned.
                    info.set("y", display.y)?;
                    /// Performs the 'width' operation.
                    /// @return | nil | No value is returned.
                    info.set("width", display.width)?;
                    /// Performs the 'height' operation.
                    /// @return | nil | No value is returned.
                    info.set("height", display.height)?;
                    /// Performs the 'scale' operation.
                    /// @return | nil | No value is returned.
                    info.set("scale", display.scale_factor)?;
                    /// Performs the 'refreshRate' operation.
                    /// @return | nil | No value is returned.
                    info.set("refreshRate", display.refresh_rate_hz)?;
                    /// Performs the 'primary' operation.
                    /// @return | nil | No value is returned.
                    info.set("primary", display.primary)?;
                    result.set(idx + 1, info)?;
                }
                return Ok(result);
            }
            let fallback = lua.create_table()?;
            /// Performs the 'index' operation.
            /// @return | nil | No value is returned.
            fallback.set("index", 0)?;
            /// Performs the 'name' operation.
            /// @return | nil | No value is returned.
            fallback.set("name", "Primary")?;
            /// Performs the 'x' operation.
            /// @return | nil | No value is returned.
            fallback.set("x", 0)?;
            /// Performs the 'y' operation.
            /// @return | nil | No value is returned.
            fallback.set("y", 0)?;
            /// Performs the 'width' operation.
            /// @return | nil | No value is returned.
            fallback.set("width", st.window_width)?;
            /// Performs the 'height' operation.
            /// @return | nil | No value is returned.
            fallback.set("height", st.window_height)?;
            /// Performs the 'scale' operation.
            /// @return | nil | No value is returned.
            fallback.set("scale", st.window_state.dpi_scale)?;
            /// Performs the 'refreshRate' operation.
            /// @return | nil | No value is returned.
            fallback.set("refreshRate", 60)?;
            /// Performs the 'primary' operation.
            /// @return | nil | No value is returned.
            fallback.set("primary", true)?;
            result.set(1, fallback)?;
            Ok(result)
        })?,
    )?;
    let s = state.clone();
    // -- getCurrentDisplay --
    /// Returns the index of the display that currently contains the window.
    /// @return | number | The zero-based index of the current display.
    tbl.set(
        "getCurrentDisplay",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .and_then(|w| window::current_display_index(w))
                .map(|idx| idx as i32)
                .unwrap_or(0))
        })?,
    )?;
    let s = state.clone();
    // -- setDisplay --
    /// Moves the window to the specified display. Throws an error if the index is negative.
    /// @param | display | integer | Zero-based index of the target display.
    /// @return | nil | No return value.
    tbl.set(
        "setDisplay",
        lua.create_function(move |_, display: i32| {
            if !window::set_display(&mut s.borrow_mut().window_state, display) {
                return Err(LuaError::RuntimeError(
                    "setDisplay: display index must be >= 0".to_string(),
                ));
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getDesktopDimensions --
    /// Returns the desktop resolution of a specific display, or the current display if none is specified.
    /// @param | display | integer? | Zero-based display index. Uses the current display if omitted.
    /// @return | number | Desktop width in pixels.
    /// @return | number | Desktop height in pixels.
    tbl.set(
        "getDesktopDimensions",
        lua.create_function(move |_, display: Option<i32>| {
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                let display_index = display.and_then(|value| {
                    if value < 0 {
                        None
                    } else {
                        Some(value as usize)
                    }
                });
                if let Some((w, h)) = window::desktop_dimensions_for_display(win, display_index) {
                    return Ok((w, h));
                }
            }
            Ok((st.window_width, st.window_height))
        })?,
    )?;
    let s = state.clone();
    // -- getDPIScale --
    /// Returns the current DPI scale factor of the window. A value of 2.0 means the display uses 2x scaling (e.g., Retina).
    /// @return | number | The DPI scale factor.
    tbl.set(
        "getDPIScale",
        lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- toPixels --
    /// Converts a value from logical (DPI-independent) units to physical pixel units using the current DPI scale.
    /// @param | value | number | The value in logical units.
    /// @return | number | The value in physical pixels.
    tbl.set(
        "toPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::to_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;
    let s = state.clone();
    // -- fromPixels --
    /// Converts a value from physical pixel units to logical (DPI-independent) units using the current DPI scale.
    /// @param | value | number | The value in physical pixels.
    /// @return | number | The value in logical units.
    tbl.set(
        "fromPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::from_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;
    let s = state.clone();
    // -- setIcon --
    /// Sets the window icon from an image file. The file must exist in the game's filesystem. Supports PNG and other common image formats.
    /// @param | path | string | Path to the icon image file.
    /// @return | nil | No return value.
    tbl.set(
        "setIcon",
        lua.create_function(move |_, path: String| {
            if path.is_empty() {
                return Err(LuaError::RuntimeError(
                    "setIcon: path must not be empty".to_string(),
                ));
            }
            if !s.borrow().fs.exists(&path) {
                return Err(LuaError::RuntimeError(format!(
                    "setIcon: file not found: {path}"
                )));
            }
            window::set_icon(&mut s.borrow_mut().window_state, &path);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- setMode --
    /// Sets the window display mode with a specific resolution and optional flags. Use this to resize the window and configure fullscreen or VSync at the same time.
    /// @param | w | integer | The desired window width in pixels.
    /// @param | h | integer | The desired window height in pixels.
    /// @param | flags | table? | Optional table with fields: fullscreen (boolean), fullscreentype (string), vsync (number).
    /// @return | nil | No return value.
    tbl.set(
        "setMode",
        lua.create_function(move |_, (w, h, flags): (u32, u32, Option<LuaTable>)| {
            let fs = flags
                .as_ref()
                .and_then(|f| f.get::<_, bool>("fullscreen").ok());
            let fst = flags
                .as_ref()
                .and_then(|f| f.get::<_, String>("fullscreentype").ok());
            let vsync = flags.as_ref().and_then(|f| f.get::<_, i32>("vsync").ok());
            window::set_mode(
                &mut s.borrow_mut().window_state,
                w,
                h,
                fs,
                fst.as_deref(),
                vsync,
            );
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getMode --
    /// Returns the current window display mode: width, height, and a flags table containing fullscreen state, fullscreen type, and VSync mode.
    /// @return | number | The window width.
    /// @return | number | The window height.
    /// @return | table | Flags table with fields: fullscreen (boolean), fullscreentype (string), vsync (number).
    tbl.set(
        "getMode",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let info = window::get_mode(&st.window_state);
            let flags = lua.create_table()?;
            /// Performs the 'fullscreen' operation.
            /// @return | nil | No value is returned.
            flags.set("fullscreen", info.fullscreen)?;
            /// Performs the 'fullscreentype' operation.
            /// @return | nil | No value is returned.
            flags.set("fullscreentype", info.fullscreen_type)?;
            /// Performs the 'vsync' operation.
            /// @return | nil | No value is returned.
            flags.set("vsync", info.vsync)?;
            Ok((st.window_width, st.window_height, flags))
        })?,
    )?;
    let s = state.clone();
    // -- windowConfig --
    /// Applies multiple window settings at once from a configuration table. Supports title, width, height, fullscreen, fullscreentype, vsync, position (x, y), scaleMode, and display index.
    /// @param | opts | table | Configuration table with optional fields: title (string), width (number), height (number), fullscreen (boolean), fullscreentype (string), vsync (number), x (number), y (number), scaleMode (string), display (number).
    /// @return | nil | No return value.
    tbl.set(
        "windowConfig",
        lua.create_function(move |_, opts: LuaTable| {
            let mut st = s.borrow_mut();
            if let Ok(title) = opts.get::<_, String>("title") {
                window::set_title(&mut st.window_state, &title);
            }
            let width = opts.get::<_, u32>("width").ok();
            let height = opts.get::<_, u32>("height").ok();
            if let (Some(w), Some(h)) = (width, height) {
                let fullscreen = opts.get::<_, bool>("fullscreen").ok();
                let fullscreentype = opts.get::<_, String>("fullscreentype").ok();
                let vsync = opts.get::<_, i32>("vsync").ok();
                window::set_mode(
                    &mut st.window_state,
                    w,
                    h,
                    fullscreen,
                    fullscreentype.as_deref(),
                    vsync,
                );
            }
            if let (Ok(x), Ok(y)) = (opts.get::<_, i32>("x"), opts.get::<_, i32>("y")) {
                window::set_position(&mut st.window_state, x, y);
            }
            if let Ok(scale_mode) = opts.get::<_, String>("scaleMode") {
                window::set_scale_mode_validated(&mut st.window_state, &scale_mode);
            }
            if let Ok(display) = opts.get::<_, i32>("display") {
                let _ = window::set_display(&mut st.window_state, display);
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- close --
    /// Closes the window and signals the engine to shut down.
    /// @return | nil | No return value.
    tbl.set(
        "close",
        lua.create_function(move |_, ()| {
            window::close(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- requestAttention --
    /// Requests user attention by flashing the taskbar icon. Useful for notifying the player when the window is in the background.
    /// @return | nil | No return value.
    tbl.set(
        "requestAttention",
        lua.create_function(move |_, ()| {
            window::request_attention(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- flash --
    /// Flashes the window briefly to attract the user's attention.
    /// @return | nil | No return value.
    tbl.set(
        "flash",
        lua.create_function(move |_, ()| {
            window::flash(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getFullscreenModes --
    /// Returns a list of all supported fullscreen video modes across all monitors. Each entry contains width, height, and refresh rate.
    /// @return | table | Array of mode tables with fields: width (number), height (number), refreshRate (number).
    tbl.set(
        "getFullscreenModes",
        lua.create_function(move |lua, ()| {
            let result = lua.create_table()?;
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                let mut idx = 1i32;
                for monitor in win.available_monitors() {
                    for mode in monitor.video_modes() {
                        let t = lua.create_table()?;
                        let sz = mode.size();
                        /// Performs the 'width' operation.
                        /// @return | nil | No value is returned.
                        t.set("width", sz.width)?;
                        /// Performs the 'height' operation.
                        /// @return | nil | No value is returned.
                        t.set("height", sz.height)?;
                        /// Performs the 'refreshRate' operation.
                        /// @return | nil | No value is returned.
                        t.set("refreshRate", mode.refresh_rate_millihertz() / 1000)?;
                        result.set(idx, t)?;
                        idx += 1;
                    }
                }
            }
            Ok(result)
        })?,
    )?;
    let s = state.clone();
    // -- getDisplayName --
    /// Returns the human-readable name of a display. Returns "Unknown" if the display cannot be identified.
    /// @param | display | integer? | Zero-based display index. Uses the current display if omitted.
    /// @return | string | The display name.
    tbl.set(
        "getDisplayName",
        lua.create_function(move |_, display: Option<i32>| {
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                let display_index = display.and_then(|value| {
                    if value < 0 {
                        None
                    } else {
                        Some(value as usize)
                    }
                });
                if let Some(name) = window::display_name_for_display(win, display_index) {
                    return Ok(name);
                }
            }
            Ok(String::from("Unknown"))
        })?,
    )?;
    let s = state.clone();
    // -- getPixelDimensions --
    /// Returns the window dimensions in actual physical pixels, accounting for DPI scaling.
    /// @return | number | The pixel width.
    /// @return | number | The pixel height.
    tbl.set(
        "getPixelDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(window::get_pixel_dimensions(
                &st.window_state,
                st.window_width,
                st.window_height,
            ))
        })?,
    )?;
    // -- showMessageBox --
    /// Displays a native OS message box dialog. Blocks execution until the user dismisses it.
    /// @param | title | string | The dialog title.
    /// @param | message | string | The message body text.
    /// @param | box_type | string? | Dialog icon type: "info" (default), "warning", or "error".
    /// @param | btn_type | string? | Button layout: "ok" (default), "okcancel", or "yesno".
    /// @return | string | The button the user clicked.
    tbl.set(
        "showMessageBox",
        lua.create_function(
            |_,
             (title, message, box_type, btn_type): (
                String,
                String,
                Option<String>,
                Option<String>,
            )| {
                Ok(window::show_message_box(
                    &title,
                    &message,
                    box_type.as_deref().unwrap_or("info"),
                    btn_type.as_deref().unwrap_or("ok"),
                ))
            },
        )?,
    )?;
    // -- focus --
    /// Requests keyboard focus for the window. No-op if already focused.
    /// @return | nil | No value is returned.
    tbl.set("focus", lua.create_function(|_, ()| Ok(()))?)?;
    let s = state.clone();
    // -- getNativeDPIScale --
    /// Returns the native DPI scale factor reported by the operating system.
    /// @return | number | The native DPI scale.
    tbl.set(
        "getNativeDPIScale",
        lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- getDisplayOrientation --
    /// Returns the display orientation based on the window's aspect ratio.
    /// @return | string | "landscape" if width >= height, "portrait" otherwise.
    tbl.set(
        "getDisplayOrientation",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(if st.window_width >= st.window_height {
                "landscape"
            } else {
                "portrait"
            })
        })?,
    )?;
    let s = state.clone();
    // -- getSafeArea --
    /// Returns the safe drawing area of the window. On desktop this is the full window area. Useful for compatibility with mobile-style layout code.
    /// @return | number | X offset (always 0 on desktop).
    /// @return | number | Y offset (always 0 on desktop).
    /// @return | number | Safe area width.
    /// @return | number | Safe area height.
    tbl.set(
        "getSafeArea",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((
                0.0f32,
                0.0f32,
                st.window_width as f32,
                st.window_height as f32,
            ))
        })?,
    )?;
    // -- getSystemTheme --
    /// Returns the operating system's current color theme. Desktop currently returns "unknown".
    /// @return | string | The system theme name.
    tbl.set(
        "getSystemTheme",
        lua.create_function(|_, ()| Ok("unknown"))?,
    )?;
    // -- isHighDPIAllowed --
    /// Returns whether high-DPI rendering is allowed. Currently always returns false on desktop.
    /// @return | boolean | True if high-DPI mode is enabled.
    tbl.set("isHighDPIAllowed", lua.create_function(|_, ()| Ok(false))?)?;
    let s = state.clone();
    // -- getScaleInfo --
    /// Returns detailed scaling information including scale factors, offsets, and logical game dimensions. Useful for coordinate conversion between screen space and game space.
    /// @return | table | Table with fields: scale_x (number), scale_y (number), offset_x (number), offset_y (number), game_width (number), game_height (number).
    tbl.set(
        "getScaleInfo",
        lua.create_function(move |lua, ()| {
            let info = window::get_scale_info(&s.borrow().window_state);
            let t = lua.create_table()?;
            /// Performs the 'scale_x' operation.
            /// @return | nil | No value is returned.
            t.set("scale_x", info.scale_x)?;
            /// Performs the 'scale_y' operation.
            /// @return | nil | No value is returned.
            t.set("scale_y", info.scale_y)?;
            /// Performs the 'offset_x' operation.
            /// @return | nil | No value is returned.
            t.set("offset_x", info.offset_x)?;
            /// Performs the 'offset_y' operation.
            /// @return | nil | No value is returned.
            t.set("offset_y", info.offset_y)?;
            /// Performs the 'game_width' operation.
            /// @return | nil | No value is returned.
            t.set("game_width", info.game_width)?;
            /// Performs the 'game_height' operation.
            /// @return | nil | No value is returned.
            t.set("game_height", info.game_height)?;
            Ok(t)
        })?,
    )?;
    let s = state.clone();
    // -- getScaleMode --
    /// Returns the current content scale mode name (e.g., "stretch", "letterbox", "pixel-perfect").
    /// @return | string | The active scale mode.
    tbl.set(
        "getScaleMode",
        lua.create_function(move |_, ()| {
            Ok(window::get_scale_mode(&s.borrow().window_state).to_owned())
        })?,
    )?;
    let s = state.clone();
    // -- setScaleMode --
    /// Sets the content scale mode. Controls how the game's logical resolution maps to the window size.
    /// @param | mode | string | The scale mode name (e.g., "stretch", "letterbox", "pixel-perfect").
    /// @return | nil | No return value.
    tbl.set(
        "setScaleMode",
        lua.create_function(move |_, mode: String| {
            window::set_scale_mode_validated(&mut s.borrow_mut().window_state, &mode);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getGameWidth --
    /// Returns the logical game width as defined by the current scale mode and game configuration.
    /// @return | number | The game width in logical units.
    tbl.set(
        "getGameWidth",
        lua.create_function(move |_, ()| Ok(window::get_width(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- getGameHeight --
    /// Returns the logical game height as defined by the current scale mode and game configuration.
    /// @return | number | The game height in logical units.
    tbl.set(
        "getGameHeight",
        lua.create_function(move |_, ()| Ok(window::get_height(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- isFullscreen --
    /// Returns whether the window is currently in fullscreen mode.
    /// @return | boolean | True if the window is fullscreen.
    tbl.set(
        "isFullscreen",
        lua.create_function(move |_, ()| Ok(window::is_fullscreen(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    // -- isResizable --
    /// Returns whether the window can be resized by the user.
    /// @return | boolean | True if the window is resizable.
    tbl.set(
        "isResizable",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .map(|w| w.is_resizable())
                .unwrap_or(false))
        })?,
    )?;
    let dpi_callback: Rc<RefCell<Option<LuaRegistryKey>>> = Rc::new(RefCell::new(None));
    let prev_dpi: Rc<RefCell<f64>> = Rc::new(RefCell::new(1.0));
    let dc = dpi_callback.clone();
    // -- onDpiChange --
    /// Registers a callback function that is called whenever the DPI scale factor changes (e.g., when the window is moved to a different monitor). Only one callback can be active at a time; setting a new one replaces the previous.
    /// @param | func | function | Callback receiving the new DPI scale as a number.
    /// @return | nil | No return value.
    tbl.set(
        "onDpiChange",
        lua.create_function(move |lua, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            if let Some(old) = dc.borrow_mut().replace(key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        })?,
    )?;
    let dc = dpi_callback;
    let pd = prev_dpi;
    let s = state.clone();
    // -- pollDpiChange --
    /// Checks if the DPI scale has changed since the last poll and fires the onDpiChange callback if so. Call this once per frame in your update loop to detect monitor changes.
    /// @return | number | The current DPI scale factor.
    tbl.set(
        "pollDpiChange",
        lua.create_function(move |lua, ()| {
            let current = s.borrow().window_state.dpi_scale;
            let prev = *pd.borrow();
            if (current - prev).abs() > f64::EPSILON {
                *pd.borrow_mut() = current;
                if let Some(key) = dc.borrow().as_ref() {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        func.call::<_, ()>(current)?;
                    }
                }
            }
            Ok(current)
        })?,
    )?;
    // -- openFileDialog --
    /// Opens a native file picker dialog and returns the selected file paths. Blocks until the user picks file(s) or cancels.
    /// @param | opts | table? | Optional config table with fields: title (string), defaultPath (string), multiple (boolean), filters (table of {name, extensions}).
    /// @return | table | Array of selected file path strings. Empty table if cancelled.
    tbl.set(
        "openFileDialog",
        lua.create_function(move |lua, opts: Option<LuaTable>| {
            let mut dialog = rfd::FileDialog::new();
            let mut multi = false;
            if let Some(t) = &opts {
                if let Ok(title) = t.get::<_, String>("title") {
                    dialog = dialog.set_title(title);
                }
                if let Ok(dp) = t.get::<_, String>("defaultPath") {
                    dialog = dialog.set_directory(dp);
                }
                if let Ok(m) = t.get::<_, bool>("multiple") {
                    multi = m;
                }
                if let Ok(filters) = t.get::<_, LuaTable>("filters") {
                    for pair in filters.sequence_values::<LuaTable>() {
                        let ft = pair?;
                        let name: String = ft.get("name").unwrap_or_default();
                        let exts: Vec<String> = ft
                            .get::<_, LuaTable>("extensions")
                            .map(|tbl| {
                                tbl.sequence_values::<String>()
                                    .filter_map(|r| r.ok())
                                    .collect()
                            })
                            .unwrap_or_default();
                        let ext_refs: Vec<&str> = exts.iter().map(|s| s.as_str()).collect();
                        dialog = dialog.add_filter(&name, &ext_refs);
                    }
                }
            }
            if multi {
                match dialog.pick_files() {
                    Some(paths) => {
                        let tbl = lua.create_table()?;
                        for (i, p) in paths.iter().enumerate() {
                            tbl.set(i + 1, p.to_string_lossy().to_string())?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                    None => {
                        let tbl = lua.create_table()?;
                        Ok(LuaValue::Table(tbl))
                    }
                }
            } else {
                let tbl = lua.create_table()?;
                match dialog.pick_file() {
                    Some(path) => {
                        tbl.set(1, path.to_string_lossy().to_string())?;
                        Ok(LuaValue::Table(tbl))
                    }
                    None => Ok(LuaValue::Table(tbl)),
                }
            }
        })?,
    )?;
    let display_tbl = lua.create_table()?;
    /// Performs the 'getCount' operation.
    /// @return | nil | No value is returned.
    display_tbl.set("getCount", tbl.get::<_, LuaFunction>("getDisplayCount")?)?;
    /// Performs the 'getName' operation.
    /// @return | nil | No value is returned.
    display_tbl.set("getName", tbl.get::<_, LuaFunction>("getDisplayName")?)?;
    display_tbl.set(
        "getDesktopDimensions",
        tbl.get::<_, LuaFunction>("getDesktopDimensions")?,
    )?;
    /// Performs the 'getDisplays' operation.
    /// @return | nil | No value is returned.
    display_tbl.set("getDisplays", tbl.get::<_, LuaFunction>("getDisplays")?)?;
    display_tbl.set(
        "getCurrent",
        tbl.get::<_, LuaFunction>("getCurrentDisplay")?,
    )?;
    /// Performs the 'setCurrent' operation.
    /// @return | nil | No value is returned.
    display_tbl.set("setCurrent", tbl.get::<_, LuaFunction>("setDisplay")?)?;
    // display: subtable of display/monitor query and control functions.
    /// Performs the 'display' operation.
    /// @return | nil | No value is returned.
    tbl.set("display", display_tbl)?;
    let mode_tbl = lua.create_table()?;
    /// Performs the 'set' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("set", tbl.get::<_, LuaFunction>("setMode")?)?;
    /// Performs the 'get' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("get", tbl.get::<_, LuaFunction>("getMode")?)?;
    /// Performs the 'setFullscreen' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("setFullscreen", tbl.get::<_, LuaFunction>("setFullscreen")?)?;
    /// Performs the 'getFullscreen' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("getFullscreen", tbl.get::<_, LuaFunction>("getFullscreen")?)?;
    /// Performs the 'isFullscreen' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("isFullscreen", tbl.get::<_, LuaFunction>("isFullscreen")?)?;
    /// Performs the 'setVSync' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("setVSync", tbl.get::<_, LuaFunction>("setVSync")?)?;
    /// Performs the 'getVSync' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("getVSync", tbl.get::<_, LuaFunction>("getVSync")?)?;
    /// Performs the 'minimize' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("minimize", tbl.get::<_, LuaFunction>("minimize")?)?;
    /// Performs the 'maximize' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("maximize", tbl.get::<_, LuaFunction>("maximize")?)?;
    /// Performs the 'restore' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("restore", tbl.get::<_, LuaFunction>("restore")?)?;
    /// Performs the 'isMinimized' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("isMinimized", tbl.get::<_, LuaFunction>("isMinimized")?)?;
    /// Performs the 'isMaximized' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("isMaximized", tbl.get::<_, LuaFunction>("isMaximized")?)?;
    /// Performs the 'isVisible' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("isVisible", tbl.get::<_, LuaFunction>("isVisible")?)?;
    mode_tbl.set(
        "requestAttention",
        tbl.get::<_, LuaFunction>("requestAttention")?,
    )?;
    /// Performs the 'flash' operation.
    /// @return | nil | No value is returned.
    mode_tbl.set("flash", tbl.get::<_, LuaFunction>("flash")?)?;
    // mode: subtable of window mode and state management functions.
    /// Performs the 'mode' operation.
    /// @return | nil | No value is returned.
    tbl.set("mode", mode_tbl)?;
    let cursor_tbl = lua.create_table()?;
    /// Performs the 'hasFocus' operation.
    /// @return | nil | No value is returned.
    cursor_tbl.set("hasFocus", tbl.get::<_, LuaFunction>("hasMouseFocus")?)?;
    // cursor: subtable of cursor focus utilities.
    /// Performs the 'cursor' operation.
    /// @return | nil | No value is returned.
    tbl.set("cursor", cursor_tbl)?;
    /// Performs the 'window' operation.
    /// @return | nil | No value is returned.
    lurek.set("window", tbl)?;
    Ok(())
}
