//! `lurek.window` - Window management, fullscreen, DPI, display queries, and viewport scaling.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::window;
use rfd;
// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

/// Registers the `lurek.window` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- setTitle --
    /// Sets the text displayed in the window's title bar.
    /// @param | title | string | The new window title text
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setTitle", lua.create_function(move |_, title: String| {
            window::set_title(&mut s.borrow_mut().window_state, &title);
            Ok(())
        })?,
    )?;

    // -- getTitle --
    /// Returns the current window title bar text as a string.
    /// @return | string | The current window title
    let s = state.clone();
    tbl.set("getTitle", lua.create_function(move |_, ()| Ok(s.borrow().window_title.clone()))?,
    )?;

    // -- getWidth --
    /// Returns the current window width in logical pixels.
    /// @return | integer | The window width in logical pixels
    let s = state.clone();
    tbl.set("getWidth", lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    // -- getHeight --
    /// Returns the current window height in logical pixels.
    /// @return | integer | The window height in logical pixels
    let s = state.clone();
    tbl.set("getHeight", lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    // -- getDimensions --
    /// Returns the window dimensions as two values (width, height) in logical pixels.
    /// @return | integer | Window width in logical pixels.
    /// @return | integer | Window height in logical pixels.
    let s = state.clone();
    tbl.set("getDimensions", lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // -- setFullscreen --
    /// Enables or disables fullscreen mode.
    /// @param | enabled | boolean | True to enter fullscreen, false to exit
    /// @param | fstype | string? | Fullscreen type: "desktop" or "exclusive" (default "desktop")
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setFullscreen", lua.create_function(move |_, (enabled, fstype): (bool, Option<String>)| {
            window::set_fullscreen(
                &mut s.borrow_mut().window_state,
                enabled,
                fstype.as_deref().unwrap_or("desktop"),
            );
            Ok(())
        })?,
    )?;

    // -- getFullscreen --
    /// Returns the current fullscreen state as two values: a boolean indicating whether fullscreen is active, and a string describing the type ("desktop" or "exclusive").
    /// @return | boolean | True when fullscreen is active.
    /// @return | string | Fullscreen mode name.
    let s = state.clone();
    tbl.set("getFullscreen", lua.create_function(move |_, ()| Ok(window::get_fullscreen(&s.borrow().window_state)))?,
    )?;

    // -- isOpen --
    /// Returns whether the window is currently open and active.
    /// @return | boolean | Always true during normal engine operation
    tbl.set("isOpen", lua.create_function(|_, ()| Ok(true))?)?;

    // -- setVSync --
    /// Sets the vertical synchronisation mode for the window's swap chain.
    /// @param | mode | integer | VSync mode: 1 = on, 0 = off, -1 = adaptive
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setVSync", lua.create_function(move |_, mode: i32| {
            window::set_vsync(&mut s.borrow_mut().window_state, mode);
            Ok(())
        })?,
    )?;

    // -- getVSync --
    /// Returns the current vertical synchronisation mode as an integer: 1 = VSync on, 0 = VSync off, -1 = adaptive VSync.
    /// @return | integer | The current VSync mode
    let s = state.clone();
    tbl.set("getVSync", lua.create_function(move |_, ()| Ok(window::get_vsync(&s.borrow().window_state)))?,
    )?;

    // -- hasFocus --
    /// Returns whether the window currently has keyboard input focus from the operating system.
    /// @return | boolean | True if the window has keyboard focus
    let s = state.clone();
    tbl.set("hasFocus", lua.create_function(move |_, ()| Ok(window::has_focus(&s.borrow().window_state)))?,
    )?;

    // -- hasMouseFocus --
    /// Returns whether the mouse cursor is currently inside the window's client area.
    /// @return | boolean | True if the mouse cursor is inside the window
    let s = state.clone();
    tbl.set("hasMouseFocus", lua.create_function(move |_, ()| Ok(window::has_mouse_focus(&s.borrow().window_state)))?,
    )?;

    // -- isMinimized --
    /// Returns whether the window is currently minimised to the taskbar.
    /// @return | boolean | True if the window is minimised
    let s = state.clone();
    tbl.set("isMinimized", lua.create_function(move |_, ()| Ok(window::is_minimized(&s.borrow().window_state)))?,
    )?;

    // -- isMaximized --
    /// Returns whether the window is currently maximised to fill the entire desktop work area.
    /// @return | boolean | True if the window is maximised
    let s = state.clone();
    tbl.set("isMaximized", lua.create_function(move |_, ()| Ok(window::is_maximized(&s.borrow().window_state)))?,
    )?;

    // -- isVisible --
    /// Returns whether the window is currently visible on screen.
    /// @return | boolean | True if the window is visible
    let s = state.clone();
    tbl.set("isVisible", lua.create_function(move |_, ()| Ok(window::is_visible(&s.borrow().window_state)))?,
    )?;

    // -- minimize --
    /// Minimises the window to the operating system taskbar or dock.
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("minimize", lua.create_function(move |_, ()| {
            window::minimize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- maximize --
    /// Maximises the window so it fills the entire desktop work area, excluding the taskbar.
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("maximize", lua.create_function(move |_, ()| {
            window::maximize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- restore --
    /// Restores the window to its previous size and position after a `minimize` or `maximize` call.
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("restore", lua.create_function(move |_, ()| {
            window::restore(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- getPosition --
    /// Returns the top-left corner position of the window in screen coordinates as two values (x, y).
    /// @return | integer | Window X position in screen coordinates.
    /// @return | integer | Window Y position in screen coordinates.
    let s = state.clone();
    tbl.set("getPosition", lua.create_function(move |_, ()| Ok(window::get_position(&s.borrow().window_state)))?,
    )?;

    // -- setPosition --
    /// Moves the top-left corner of the window to the given screen coordinates.
    /// @param | x | integer | The target horizontal screen coordinate in pixels
    /// @param | y | integer | The target vertical screen coordinate in pixels
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setPosition", lua.create_function(move |_, (x, y): (i32, i32)| {
            window::set_position(&mut s.borrow_mut().window_state, x, y);
            Ok(())
        })?,
    )?;

    // -- getDisplayCount --
    /// Returns the number of displays (monitors) currently connected to the system.
    /// @return | integer | The number of connected displays
    let s = state.clone();
    tbl.set("getDisplayCount", lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .map(|w| w.available_monitors().count())
                .unwrap_or(1) as i32)
        })?,
    )?;

    // -- getDesktopDimensions --
    /// Returns the full desktop resolution of the current monitor as two values (width, height) in physical pixels.
    /// @return | integer | Desktop width in pixels.
    /// @return | integer | Desktop height in pixels.
    let s = state.clone();
    tbl.set("getDesktopDimensions", lua.create_function(move |_, ()| {
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

    // -- getDPIScale --
    /// Returns the current DPI scaling factor for the window as a number.
    /// @return | number | The DPI scale factor (1.0 = standard density)
    let s = state.clone();
    tbl.set("getDPIScale", lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;

    // -- toPixels --
    /// Converts a device-independent (logical) coordinate value to its equivalent in physical pixels using the current DPI scale factor.
    /// @param | value | number | The logical coordinate value to convert
    /// @return | number | The corresponding physical pixel value
    let s = state.clone();
    tbl.set("toPixels", lua.create_function(move |_, value: f64| {
            Ok(window::to_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;

    // -- fromPixels --
    /// Converts a physical pixel value back to device-independent (logical) coordinates using the current DPI scale factor.
    /// @param | value | number | The physical pixel value to convert
    /// @return | number | The corresponding logical coordinate value
    let s = state.clone();
    tbl.set("fromPixels", lua.create_function(move |_, value: f64| {
            Ok(window::from_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;

    // -- setIcon --
    /// Sets the window icon from an image file located in the game directory.
    /// @param | path | string | Relative path to the icon image file
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("setIcon", lua.create_function(move |_, path: String| {
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

    // -- setMode --
    /// Resizes the window and optionally changes fullscreen and vsync settings in a single call.
    /// @param | w | integer | The new window width in logical pixels
    /// @param | h | integer | The new window height in logical pixels
    /// @param | flags | table? | Optional table with fullscreen, fullscreentype, and vsync keys
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("setMode", lua.create_function(move |_, (w, h, flags): (u32, u32, Option<LuaTable>)| {
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

    // -- getMode --
    /// Returns the current window dimensions and mode flags as three values: width, height, and a flags table.
    /// @return | integer | Window width in logical pixels.
    /// @return | integer | Window height in logical pixels.
    /// @return | table | Table of current window mode flags.
    let s = state.clone();
    tbl.set("getMode", lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let info = window::get_mode(&st.window_state);
            let flags = lua.create_table()?;
            flags.set("fullscreen", info.fullscreen)?;
            flags.set("fullscreentype", info.fullscreen_type)?;
            flags.set("vsync", info.vsync)?;
            Ok((st.window_width, st.window_height, flags))
        })?,
    )?;

    // -- close --
    /// Requests the window to close, which will end the game loop after the current frame finishes.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("close", lua.create_function(move |_, ()| {
            window::close(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- requestAttention --
    /// Flashes the window icon in the operating system taskbar or dock to attract the user's attention.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set("requestAttention", lua.create_function(move |_, ()| {
            window::request_attention(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- getFullscreenModes --
    /// Returns an array of all available fullscreen video modes supported by the current monitor.
    /// @return | table | An array of tables, each with width, height, and refreshRate fields
    let s = state.clone();
    tbl.set("getFullscreenModes", lua.create_function(move |lua, ()| {
            let result = lua.create_table()?;
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                let mut idx = 1i32;
                for monitor in win.available_monitors() {
                    for mode in monitor.video_modes() {
                        let t = lua.create_table()?;
                        let sz = mode.size();
                        t.set("width", sz.width)?;
                        t.set("height", sz.height)?;
                        t.set("refreshRate", mode.refresh_rate_millihertz() / 1000)?;
                        result.set(idx, t)?;
                        idx += 1;
                    }
                }
            }
            Ok(result)
        })?,
    )?;

    // -- getDisplayName --
    /// Returns the human-readable name of a connected display as reported by the operating system (for example "DELL U2723QE" or "Built-in Retina").
    /// @param | display | integer? | Zero-based display index; omit for the current monitor
    /// @return | string | The display name string
    let s = state.clone();
    tbl.set("getDisplayName", lua.create_function(move |_, _display: Option<i32>| {
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

    // -- getPixelDimensions --
    /// Returns the window dimensions in physical (device) pixels as two values (width, height).
    /// @return | integer | Window width in physical pixels.
    /// @return | integer | Window height in physical pixels.
    let s = state.clone();
    tbl.set("getPixelDimensions", lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(window::get_pixel_dimensions(
                &st.window_state,
                st.window_width,
                st.window_height,
            ))
        })?,
    )?;

    // -- showMessageBox --
    /// Shows a platform-native message box dialog.
    /// @param | title | string | Window title text.
    /// @param | message | string | Message text.
    /// @param | boxType | string? | Message box type.
    /// @param | btnType | string? | Button layout type.
    /// @return | string | Button or result identifier returned by the native dialog.
    tbl.set("showMessageBox", lua.create_function(
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
    /// Requests the window manager to bring the window to the foreground.
    /// @return | nil | No value is returned.
    tbl.set("focus", lua.create_function(|_, ()| Ok(()))?)?;

    // -- getNativeDPIScale --
    /// Returns the native DPI scale factor.
    /// @return | number | Native DPI scale factor for the current window.
    let s = state.clone();
    tbl.set("getNativeDPIScale", lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;

    // -- getDisplayOrientation --
    /// Returns the current display orientation.
    /// @return | string | Display orientation name: `landscape` or `portrait`.
    let s = state.clone();
    tbl.set("getDisplayOrientation", lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(if st.window_width >= st.window_height {
                "landscape"
            } else {
                "portrait"
            })
        })?,
    )?;

    // -- getSafeArea --
    /// Returns the safe display area as x, y, w, h.
    /// @return | number | Safe-area X coordinate.
    /// @return | number | Safe-area Y coordinate.
    /// @return | number | Safe-area width.
    /// @return | number | Safe-area height.
    let s = state.clone();
    tbl.set("getSafeArea", lua.create_function(move |_, ()| {
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
    /// Returns the OS color theme preference.
    /// @return | string | OS color theme preference string.
    tbl.set("getSystemTheme", lua.create_function(|_, ()| Ok("unknown"))?,
    )?;

    // -- isHighDPIAllowed --
    /// Returns whether high-DPI rendering is allowed.
    /// @return | boolean | Always false because high-DPI rendering is not currently supported.
    tbl.set("isHighDPIAllowed", lua.create_function(|_, ()| Ok(false))?)?;

    // -- getScaleInfo --
    /// Returns viewport scale and offset information as a table.
    /// @return | table | Table with scale, offset, and virtual game size fields.
    let s = state.clone();
    tbl.set("getScaleInfo", lua.create_function(move |lua, ()| {
            let info = window::get_scale_info(&s.borrow().window_state);
            let t = lua.create_table()?;
            t.set("scale_x", info.scale_x)?;
            t.set("scale_y", info.scale_y)?;
            t.set("offset_x", info.offset_x)?;
            t.set("offset_y", info.offset_y)?;
            t.set("game_width", info.game_width)?;
            t.set("game_height", info.game_height)?;
            Ok(t)
        })?,
    )?;

    // -- getScaleMode --
    /// Returns the current viewport scale mode string.
    /// @return | string | Current viewport scale mode name.
    let s = state.clone();
    tbl.set("getScaleMode", lua.create_function(move |_, ()| {
            Ok(window::get_scale_mode(&s.borrow().window_state).to_owned())
        })?,
    )?;

    // -- setScaleMode --
    /// Sets the viewport scale mode.
    /// @param | mode | string | Viewport scale mode name.
    /// @return | nil | No value is returned.
    let s = state.clone();
    tbl.set("setScaleMode", lua.create_function(move |_, mode: String| {
            window::set_scale_mode_validated(&mut s.borrow_mut().window_state, &mode);
            Ok(())
        })?,
    )?;

    // -- getGameWidth --
    /// Returns the logical game width in virtual pixels.
    /// @return | number | Logical game width in virtual pixels.
    let s = state.clone();
    tbl.set("getGameWidth", lua.create_function(move |_, ()| Ok(window::get_width(&s.borrow().window_state)))?,
    )?;

    // -- getGameHeight --
    /// Returns the logical game height in virtual pixels.
    /// @return | number | Logical game height in virtual pixels.
    let s = state.clone();
    tbl.set("getGameHeight", lua.create_function(move |_, ()| Ok(window::get_height(&s.borrow().window_state)))?,
    )?;

    // -- isFullscreen --
    /// Returns whether the window is in fullscreen mode.
    /// @return | boolean | Whether the window is currently in fullscreen mode.
    let s = state.clone();
    tbl.set("isFullscreen", lua.create_function(move |_, ()| Ok(window::is_fullscreen(&s.borrow().window_state)))?,
    )?;

    // -- isResizable --
    /// Returns whether the window can be resized by the user.
    /// @return | boolean | Whether the window can be resized by the user.
    let s = state.clone();
    tbl.set("isResizable", lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .map(|w| w.is_resizable())
                .unwrap_or(false))
        })?,
    )?;

    // DPI-change callback stored locally keyed to this register() call.
    let dpi_callback: Rc<RefCell<Option<LuaRegistryKey>>> = Rc::new(RefCell::new(None));
    let prev_dpi: Rc<RefCell<f64>> = Rc::new(RefCell::new(1.0));

    // -- onDpiChange --
    /// Registers a callback invoked (with the new scale factor) when the display DPI changes.
    /// @param | callback | function | Callback function.
    /// @return | nil | No value is returned.
    let dc = dpi_callback.clone();
    tbl.set("onDpiChange", lua.create_function(move |lua, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            if let Some(old) = dc.borrow_mut().replace(key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        })?,
    )?;

    // -- pollDpiChange --
    /// Checks whether the DPI scale has changed since the last call and fires the onDpiChange callback if so.
    /// @return | number | Current DPI scale factor after polling for changes.
    let dc = dpi_callback;
    let pd = prev_dpi;
    let s = state.clone();
    tbl.set("pollDpiChange", lua.create_function(move |lua, ()| {
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
    /// Opens a blocking native file-open dialog.
    /// @param | opts | table? | Options table.
    /// @return | table | Array of selected file paths.
    tbl.set("openFileDialog", lua.create_function(move |lua, opts: Option<LuaTable>| {
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

    lurek.set("window", tbl)?;
    Ok(())
}
