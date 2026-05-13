use super::SharedState;
use crate::window;
use mlua::prelude::*;
use rfd;
use std::cell::RefCell;
use std::rc::Rc;
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "setTitle",
        lua.create_function(move |_, title: String| {
            window::set_title(&mut s.borrow_mut().window_state, &title);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getTitle",
        lua.create_function(move |_, ()| Ok(s.borrow().window_title.clone()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getWidth",
        lua.create_function(move |_, ()| Ok(s.borrow().window_width))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getHeight",
        lua.create_function(move |_, ()| Ok(s.borrow().window_height))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getDimensions",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok((st.window_width, st.window_height))
        })?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "getFullscreen",
        lua.create_function(move |_, ()| Ok(window::get_fullscreen(&s.borrow().window_state)))?,
    )?;
    tbl.set("isOpen", lua.create_function(|_, ()| Ok(true))?)?;
    let s = state.clone();
    tbl.set(
        "setVSync",
        lua.create_function(move |_, mode: i32| {
            window::set_vsync(&mut s.borrow_mut().window_state, mode);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getVSync",
        lua.create_function(move |_, ()| Ok(window::get_vsync(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "hasFocus",
        lua.create_function(move |_, ()| Ok(window::has_focus(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "hasMouseFocus",
        lua.create_function(move |_, ()| Ok(window::has_mouse_focus(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "isMinimized",
        lua.create_function(move |_, ()| Ok(window::is_minimized(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "isMaximized",
        lua.create_function(move |_, ()| Ok(window::is_maximized(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "isVisible",
        lua.create_function(move |_, ()| Ok(window::is_visible(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "minimize",
        lua.create_function(move |_, ()| {
            window::minimize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "maximize",
        lua.create_function(move |_, ()| {
            window::maximize(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "restore",
        lua.create_function(move |_, ()| {
            window::restore(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPosition",
        lua.create_function(move |_, ()| Ok(window::get_position(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPosition",
        lua.create_function(move |_, (x, y): (i32, i32)| {
            window::set_position(&mut s.borrow_mut().window_state, x, y);
            Ok(())
        })?,
    )?;
    let s = state.clone();
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
    tbl.set(
        "getDisplays",
        lua.create_function(move |lua, ()| {
            let result = lua.create_table()?;
            let st = s.borrow();
            if let Some(win) = st.window.as_ref() {
                for (idx, display) in window::get_displays(win).iter().enumerate() {
                    let info = lua.create_table()?;
                    info.set("index", display.index)?;
                    info.set("name", display.name.as_str())?;
                    info.set("x", display.x)?;
                    info.set("y", display.y)?;
                    info.set("width", display.width)?;
                    info.set("height", display.height)?;
                    info.set("scale", display.scale_factor)?;
                    info.set("refreshRate", display.refresh_rate_hz)?;
                    info.set("primary", display.primary)?;
                    result.set(idx + 1, info)?;
                }
                return Ok(result);
            }
            let fallback = lua.create_table()?;
            fallback.set("index", 0)?;
            fallback.set("name", "Primary")?;
            fallback.set("x", 0)?;
            fallback.set("y", 0)?;
            fallback.set("width", st.window_width)?;
            fallback.set("height", st.window_height)?;
            fallback.set("scale", st.window_state.dpi_scale)?;
            fallback.set("refreshRate", 60)?;
            fallback.set("primary", true)?;
            result.set(1, fallback)?;
            Ok(result)
        })?,
    )?;
    let s = state.clone();
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
    tbl.set(
        "getDPIScale",
        lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "toPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::to_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "fromPixels",
        lua.create_function(move |_, value: f64| {
            Ok(window::from_dpi_pixels(&s.borrow().window_state, value))
        })?,
    )?;
    let s = state.clone();
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
    let s = state.clone();
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
    tbl.set(
        "close",
        lua.create_function(move |_, ()| {
            window::close(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "requestAttention",
        lua.create_function(move |_, ()| {
            window::request_attention(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "flash",
        lua.create_function(move |_, ()| {
            window::flash(&mut s.borrow_mut().window_state);
            Ok(())
        })?,
    )?;
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
    let s = state.clone();
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
    tbl.set("focus", lua.create_function(|_, ()| Ok(()))?)?;
    let s = state.clone();
    tbl.set(
        "getNativeDPIScale",
        lua.create_function(move |_, ()| Ok(window::get_dpi_scale(&s.borrow().window_state)))?,
    )?;
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
    tbl.set(
        "getSystemTheme",
        lua.create_function(|_, ()| Ok("unknown"))?,
    )?;
    tbl.set("isHighDPIAllowed", lua.create_function(|_, ()| Ok(false))?)?;
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
    let s = state.clone();
    tbl.set(
        "getScaleMode",
        lua.create_function(move |_, ()| {
            Ok(window::get_scale_mode(&s.borrow().window_state).to_owned())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setScaleMode",
        lua.create_function(move |_, mode: String| {
            window::set_scale_mode_validated(&mut s.borrow_mut().window_state, &mode);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getGameWidth",
        lua.create_function(move |_, ()| Ok(window::get_width(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getGameHeight",
        lua.create_function(move |_, ()| Ok(window::get_height(&s.borrow().window_state)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "isFullscreen",
        lua.create_function(move |_, ()| Ok(window::is_fullscreen(&s.borrow().window_state)))?,
    )?;
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
    let dpi_callback: Rc<RefCell<Option<LuaRegistryKey>>> = Rc::new(RefCell::new(None));
    let prev_dpi: Rc<RefCell<f64>> = Rc::new(RefCell::new(1.0));
    let dc = dpi_callback.clone();
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
    display_tbl.set("getCount", tbl.get::<_, LuaFunction>("getDisplayCount")?)?;
    display_tbl.set("getName", tbl.get::<_, LuaFunction>("getDisplayName")?)?;
    display_tbl.set(
        "getDesktopDimensions",
        tbl.get::<_, LuaFunction>("getDesktopDimensions")?,
    )?;
    display_tbl.set("getDisplays", tbl.get::<_, LuaFunction>("getDisplays")?)?;
    display_tbl.set(
        "getCurrent",
        tbl.get::<_, LuaFunction>("getCurrentDisplay")?,
    )?;
    display_tbl.set("setCurrent", tbl.get::<_, LuaFunction>("setDisplay")?)?;
    tbl.set("display", display_tbl)?;
    let mode_tbl = lua.create_table()?;
    mode_tbl.set("set", tbl.get::<_, LuaFunction>("setMode")?)?;
    mode_tbl.set("get", tbl.get::<_, LuaFunction>("getMode")?)?;
    mode_tbl.set("setFullscreen", tbl.get::<_, LuaFunction>("setFullscreen")?)?;
    mode_tbl.set("getFullscreen", tbl.get::<_, LuaFunction>("getFullscreen")?)?;
    mode_tbl.set("isFullscreen", tbl.get::<_, LuaFunction>("isFullscreen")?)?;
    mode_tbl.set("setVSync", tbl.get::<_, LuaFunction>("setVSync")?)?;
    mode_tbl.set("getVSync", tbl.get::<_, LuaFunction>("getVSync")?)?;
    mode_tbl.set("minimize", tbl.get::<_, LuaFunction>("minimize")?)?;
    mode_tbl.set("maximize", tbl.get::<_, LuaFunction>("maximize")?)?;
    mode_tbl.set("restore", tbl.get::<_, LuaFunction>("restore")?)?;
    mode_tbl.set("isMinimized", tbl.get::<_, LuaFunction>("isMinimized")?)?;
    mode_tbl.set("isMaximized", tbl.get::<_, LuaFunction>("isMaximized")?)?;
    mode_tbl.set("isVisible", tbl.get::<_, LuaFunction>("isVisible")?)?;
    mode_tbl.set(
        "requestAttention",
        tbl.get::<_, LuaFunction>("requestAttention")?,
    )?;
    mode_tbl.set("flash", tbl.get::<_, LuaFunction>("flash")?)?;
    tbl.set("mode", mode_tbl)?;
    let cursor_tbl = lua.create_table()?;
    cursor_tbl.set("hasFocus", tbl.get::<_, LuaFunction>("hasMouseFocus")?)?;
    tbl.set("cursor", cursor_tbl)?;
    lurek.set("window", tbl)?;
    Ok(())
}
