//! `lurek.window` - Window management, fullscreen, DPI, display queries, and viewport scaling.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::window;

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.window` API table with the Lua VM.
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- setTitle --
    /// Sets the window title bar text.
    /// @param title : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setTitle",
        lua.create_function(move |_, title: String| {
            window::set_title(&mut s.borrow_mut().window_state, &title);
            Ok(())
        })?,
    )?;

    // -- getTitle --
    /// Returns the current window title.
    /// @return string
    let s = state.clone();
    tbl.set(
        "getTitle",
        lua.create_function(move |_, ()| Ok(s.borrow().window_title.clone()))?,
    )?;

    // -- getWidth --
    /// Returns the window width in pixels.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;

    // -- getHeight --
    /// Returns the window height in pixels.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;

    // -- getDimensions --
    /// Returns the window dimensions as width, height.
    /// @return integer, integer
    let s = state.clone();
    tbl.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;

    // -- setFullscreen --
    /// Enables or disables fullscreen mode.
    /// @param enabled : boolean
    /// @param fstype : string?
    /// @return nil
    let s = state.clone();
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

    // -- getFullscreen --
    /// Returns the fullscreen state and type string.
    /// @return boolean, string
    let s = state.clone();
    tbl.set(
        "getFullscreen",
        lua.create_function(move |_, ()| {
            Ok(window::get_fullscreen(&s.borrow().window_state))
        })?,
    )?;

    // -- isOpen --
    /// Returns whether the window is open.
    /// @return boolean
    tbl.set("isOpen", lua.create_function(|_, ()| Ok(true))?)?;

    // -- setVSync --
    /// Sets the VSync mode (1=on, 0=off, -1=adaptive).
    /// @param mode : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setVSync",
        lua.create_function(move |_, mode: i32| {
            window::set_vsync(&mut s.borrow_mut().window_state, mode);
            Ok(())
        })?,
    )?;

    // -- getVSync --
    /// Returns the current VSync mode integer.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getVSync",
        lua.create_function(move |_, ()| Ok(window::get_vsync(&s.borrow().window_state)))?,
    )?;

    // -- hasFocus --
    /// Returns whether the window has keyboard focus.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "hasFocus",
        lua.create_function(move |_, ()| Ok(window::has_focus(&s.borrow().window_state)))?,
    )?;

    // -- hasMouseFocus --
    /// Returns whether the mouse cursor is inside the window.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "hasMouseFocus",
        lua.create_function(move |_, ()| {
            Ok(window::has_mouse_focus(&s.borrow().window_state))
        })?,
    )?;

    // -- isMinimized --
    /// Returns whether the window is minimized.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isMinimized",
        lua.create_function(move |_, ()| {
            Ok(window::is_minimized(&s.borrow().window_state))
        })?,
    )?;

    // -- isMaximized --
    /// Returns whether the window is maximized.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isMaximized",
        lua.create_function(move |_, ()| {
            Ok(window::is_maximized(&s.borrow().window_state))
        })?,
    )?;

    // -- isVisible --
    /// Returns whether the window is visible.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(window::is_visible(&s.borrow().window_state)))?,
    )?;

    // -- minimize --
    /// Minimizes the window to the taskbar.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "minimize",
        lua.create_function(move |_, ()| {
            window::minimize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- maximize --
    /// Maximizes the window to fill the desktop.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "maximize",
        lua.create_function(move |_, ()| {
            window::maximize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- restore --
    /// Restores the window from minimized or maximized state.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "restore",
        lua.create_function(move |_, ()| {
            window::restore(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- getPosition --
    /// Returns the window position as x, y in screen coordinates.
    /// @return integer, integer
    let s = state.clone();
    tbl.set(
        "getPosition",
        lua.create_function(move |_, ()| {
            Ok(window::get_position(&s.borrow().window_state))
        })?,
    )?;

    // -- setPosition --
    /// Moves the window to the given screen position.
    /// @param x : integer
    /// @param y : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (i32, i32)| {
            window::set_position(&mut s.borrow_mut().window_state, x, y);
            Ok(())
        })?,
    )?;

    // -- getDisplayCount --
    /// Returns the number of connected displays.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getDisplayCount",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st
                .window
                .as_ref()
                .map(|w| w.available_monitors().count())
                .unwrap_or(1) as i32)
        })?,
    )?;

    // -- getDesktopDimensions --
    /// Returns the desktop resolution as width, height.
    /// @return integer, integer
    let s = state.clone();
    tbl.set(
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

    // -- getDPIScale --
    /// Returns the DPI scaling factor for the window.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getDPIScale",
        lua.create_function(move |_, ()| {
            Ok(window::get_dpi_scale(&s.borrow().window_state))
        })?,
    )?;

    // -- toPixels --
    /// Converts a device-independent coordinate to physical pixels.
    /// @param value : number
    /// @return number
    let s = state.clone();
    tbl.set(
        "toPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::to_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;

    // -- fromPixels --
    /// Converts physical pixels to device-independent coordinates.
    /// @param value : number
    /// @return number
    let s = state.clone();
    tbl.set(
        "fromPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::from_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;

    // -- setIcon --
    /// Sets the window icon from a file path.
    /// @param path : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setIcon",
        lua.create_function(move |_, path: String| {
            window::set_icon(&mut s.borrow_mut().window_state, &path);
            Ok(())
        })?,
    )?;

    // -- setMode --
    /// Resizes the window and optionally changes fullscreen and vsync.
    /// @param w : integer
    /// @param h : integer
    /// @param flags : table?
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setMode",
        lua.create_function(move |_, (w, h, flags): (u32, u32, Option<LuaTable>)| {
            let fs = flags.as_ref().and_then(|f| f.get::<_, bool>("fullscreen").ok());
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
    /// Returns the window dimensions and mode flags as width, height, flags.
    /// @return integer, integer, table
    let s = state.clone();
    tbl.set(
        "getMode",
        lua.create_function(move |lua, ()| {
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
    /// Requests the window to close.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "close",
        lua.create_function(move |_, ()| {
            window::close(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- requestAttention --
    /// Flashes the window in the taskbar to request user attention.
    /// @return nil
    let s = state.clone();
    tbl.set(
        "requestAttention",
        lua.create_function(move |_, ()| {
            window::request_attention(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;

    // -- getFullscreenModes --
    /// Returns all available fullscreen video modes.
    /// @return table
    let s = state.clone();
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
    /// Returns the name of the current display.
    /// @param display : integer?
    /// @return string
    let s = state.clone();
    tbl.set(
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

    // -- getPixelDimensions --
    /// Returns the window dimensions in physical pixels.
    /// @return integer, integer
    let s = state.clone();
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
    /// Shows a platform-native message box dialog.
    /// @param title : string
    /// @param message : string
    /// @param boxType : string?
    /// @param btnType : string?
    /// @return string
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
    /// Requests the window manager to bring the window to the foreground.
    /// @return nil
    tbl.set("focus", lua.create_function(|_, ()| Ok(()))?)?;

    // -- getNativeDPIScale --
    /// Returns the native DPI scale factor.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getNativeDPIScale",
        lua.create_function(move |_, ()| {
            Ok(window::get_dpi_scale(&s.borrow().window_state))
        })?,
    )?;

    // -- getDisplayOrientation --
    /// Returns the current display orientation.
    /// @return string
    let s = state.clone();
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

    // -- getSafeArea --
    /// Returns the safe display area as x, y, w, h.
    /// @return number, number, number, number
    let s = state.clone();
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
    /// Returns the OS color theme preference.
    /// @return string
    tbl.set(
        "getSystemTheme",
        lua.create_function(|_, ()| Ok("unknown"))?,
    )?;

    // -- isHighDPIAllowed --
    /// Returns whether high-DPI rendering is allowed.
    /// @return boolean
    tbl.set(
        "isHighDPIAllowed",
        lua.create_function(|_, ()| Ok(false))?,
    )?;

    // -- getScaleInfo --
    /// Returns viewport scale and offset information as a table.
    /// @return table
    let s = state.clone();
    tbl.set(
        "getScaleInfo",
        lua.create_function(move |lua, ()| {
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
    /// @return string
    let s = state.clone();
    tbl.set(
        "getScaleMode",
        lua.create_function(move |_, ()| {
            Ok(window::get_scale_mode(&s.borrow().window_state).to_owned())
        })?,
    )?;

    // -- setScaleMode --
    /// Sets the viewport scale mode.
    /// @param mode : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setScaleMode",
        lua.create_function(move |_, mode: String| {
            window::set_scale_mode_validated(&mut s.borrow_mut().window_state, &mode);
            Ok(())
        })?,
    )?;

    // -- getGameWidth --
    /// Returns the logical game width in virtual pixels.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getGameWidth",
        lua.create_function(move |_, ()| Ok(window::get_width(&s.borrow().window_state)))?,
    )?;

    // -- getGameHeight --
    /// Returns the logical game height in virtual pixels.
    /// @return number
    let s = state.clone();
    tbl.set(
        "getGameHeight",
        lua.create_function(move |_, ()| Ok(window::get_height(&s.borrow().window_state)))?,
    )?;

    // -- isFullscreen --
    /// Returns whether the window is in fullscreen mode.
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isFullscreen",
        lua.create_function(move |_, ()| {
            Ok(window::is_fullscreen(&s.borrow().window_state))
        })?,
    )?;

    // -- isResizable --
    /// Returns whether the window can be resized by the user.
    /// @return boolean
    let s = state.clone();
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

    luna.set("window", tbl)?;
    Ok(())
}
