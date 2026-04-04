//! Lua API bindings for the `luna.gui.*` retained-mode widget system.
//!
//! Registers the `luna.gui` namespace with functions for creating widgets,
//! managing the widget tree, routing input events, theming, focus navigation,
//! and toast notifications.
//!
//! ## Exposed Lua API
//!
//! | Function | Purpose |
//! |---|---|
//! | `luna.gui.newButton(text?)` | Create a button widget |
//! | `luna.gui.newLabel(text?)` | Create a text label |
//! | `luna.gui.newTextInput()` | Create a text input field |
//! | `luna.gui.newCheckbox(text?)` | Create a checkbox |
//! | `luna.gui.newSlider(min?, max?)` | Create a value slider |
//! | `luna.gui.newProgressBar(min?, max?)` | Create a progress bar |
//! | `luna.gui.newComboBox()` | Create a dropdown |
//! | `luna.gui.newList()` | Create a selectable list |
//! | `luna.gui.newPanel()` | Create a container panel |
//! | `luna.gui.newLayout(direction?)` | Create a flexbox layout |
//! | `luna.gui.newScrollPanel()` | Create a scrollable panel |
//! | `luna.gui.newNinePatch()` | Create a 9-patch slicer |
//! | `luna.gui.newTabBar()` | Create a tab bar |
//! | `luna.gui.newSeparator(vertical?)` | Create a separator line |
//! | `luna.gui.newSpacer(w?, h?)` | Create spacing filler |
//! | `luna.gui.newToast(msg?, duration?)` | Create a toast notification |
//! | `luna.gui.newTreeView()` | Create a collapsible tree |
//! | `luna.gui.newRadioButton(text?, group?)` | Create a grouped radio button |
//! | `luna.gui.newScrollBar(vertical?)` | Create a scroll bar |
//! | `luna.gui.newWindow(title?)` | Create a draggable window |
//! | `luna.gui.newSplitPanel(orientation?)` | Create a split panel |
//! | `luna.gui.newDockPanel()` | Create a dock panel |
//! | `luna.gui.newToolbar(orientation?)` | Create a toolbar |
//! | `luna.gui.newMenuBar()` | Create a menu bar |
//! | `luna.gui.newMenuItem(text?)` | Create a menu item |
//! | `luna.gui.newDialog(title?)` | Create a modal dialog |
//! | `luna.gui.newStatusBar()` | Create a status bar |
//! | `luna.gui.newAccordion()` | Create a collapsible accordion |
//! | `luna.gui.newTooltipPanel(text?)` | Create a tooltip panel |
//! | `luna.gui.newColorPicker()` | Create a color picker |
//! | `luna.gui.newTable()` | Create a data table |
//! | `luna.gui.newImageWidget()` | Create an image widget |
//! | `luna.gui.newTheme()` | Create a theme instance |
//! | `luna.gui.setTheme(theme)` | Set the active theme |
//! | `luna.gui.getTheme()` | Get the active theme |
//! | `luna.gui.getRoot()` | Get the root panel index |
//! | `luna.gui.setFocus(idx/nil)` | Set keyboard focus |
//! | `luna.gui.getFocus()` | Get focused widget index |
//! | `luna.gui.focusNext()` | Tab to next focusable |
//! | `luna.gui.focusPrev()` | Tab to previous focusable |
//! | `luna.gui.clearFocus()` | Clear focus |
//! | `luna.gui.addToast(toast)` | Queue a toast overlay |
//! | `luna.gui.getToastCount()` | Active toast count |
//! | `luna.gui.mousepressed(x,y,btn?)` | Forward mouse press |
//! | `luna.gui.mousereleased(x,y,btn?)` | Forward mouse release |
//! | `luna.gui.mousemoved(x,y)` | Forward mouse move |
//! | `luna.gui.keypressed(key)` | Forward key press |
//! | `luna.gui.textinput(text)` | Forward text input |
//! | `luna.gui.wheelmoved(x,y)` | Forward mouse wheel |
//! | `luna.gui.update(dt)` | Advance toast timers |
//! | `luna.gui.getWidgetCount()` | Total widget count |
//! | Widget methods | See per-type method tables in `src/gui/AGENT.md` |
//!
//! ## Implementation Pattern
//!
//! A single `Rc<RefCell<GuiContext>>` is created at registration time and
//! captured by all closures via Rc clone.  Widget indices (pool positions)
//! are returned to Lua as integers.  Container/list/tab indices are 1-based
//! in Lua.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::gui::containers::LayoutDirection;
use crate::gui::context::{GuiContext, WidgetKind};
use crate::gui::extras::Toast;
use crate::gui::theme::{Theme, WidgetStyle};
use crate::gui::widget::{WidgetState, WidgetType};

/// Helper: create a widget method table with all base Widget methods
/// pre-populated, bound to the given widget index.
fn create_widget_table<'a>(
    lua: &'a Lua,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    t.set("_idx", idx)?;

    // ── Position / Size ───────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setPosition",
            lua.create_function(move |_, (x, y): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    let b = w.base_mut();
                    b.x = x;
                    b.y = y;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getPosition",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    let b = w.base();
                    Ok((b.x, b.y))
                } else {
                    Ok((0.0, 0.0))
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSize",
            lua.create_function(move |_, (w, h): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(wgt) = g.widgets.get_mut(idx) {
                    let b = wgt.base_mut();
                    b.width = w;
                    b.height = h;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    let b = w.base();
                    Ok((b.width, b.height))
                } else {
                    Ok((0.0, 0.0))
                }
            })?,
        )?;
    }

    // ── Visibility / Enabled ──────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setVisible",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().visible = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isVisible",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets.get(idx).is_some_and(|w| w.base().visible))
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setEnabled",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    let b = w.base_mut();
                    b.enabled = v;
                    if !v {
                        b.state = WidgetState::Disabled;
                    } else if b.state == WidgetState::Disabled {
                        b.state = WidgetState::Normal;
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isEnabled",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets.get(idx).is_some_and(|w| w.base().enabled))
            })?,
        )?;
    }

    // ── ID / Tooltip ──────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setId",
            lua.create_function(move |_, id: String| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().id = id;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getId",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets
                    .get(idx)
                    .map_or(String::new(), |w| w.base().id.clone()))
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setTooltip",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().tooltip = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTooltip",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets
                    .get(idx)
                    .map_or(String::new(), |w| w.base().tooltip.clone()))
            })?,
        )?;
    }

    // ── State ─────────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "getState",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets
                    .get(idx)
                    .map_or("normal", |w| w.base().state.as_str())
                    .to_string())
            })?,
        )?;
    }

    // ── Children ──────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "addChild",
            lua.create_function(move |_, child: LuaTable| {
                let child_idx: usize = child.get("_idx")?;
                let mut g = c.borrow_mut();
                g.add_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeChild",
            lua.create_function(move |_, child: LuaTable| {
                let child_idx: usize = child.get("_idx")?;
                let mut g = c.borrow_mut();
                g.remove_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getChildCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.child_count(idx))
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "findById",
            lua.create_function(move |lua, id: String| {
                let g = c.borrow();
                match g.find_by_id(idx, &id) {
                    Some(found_idx) => {
                        let t = lua.create_table()?;
                        t.set("_idx", found_idx)?;
                        Ok(LuaValue::Table(t))
                    }
                    None => Ok(LuaValue::Nil),
                }
            })?,
        )?;
    }

    // ── Callbacks ─────────────────────────────────────────────────────
    // Accept and silently store Lua callback functions. Actual invocation
    // happens when the engine drives the GUI event loop (future work).
    t.set("setOnClick", lua.create_function(|_, _f: LuaFunction| Ok(()))?)?;
    t.set("setOnChange", lua.create_function(|_, _f: LuaFunction| Ok(()))?)?;
    t.set("setOnDraw", lua.create_function(|_, _f: LuaFunction| Ok(()))?)?;

    // ── Hit test ──────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "containsPoint",
            lua.create_function(move |_, (x, y): (f32, f32)| {
                let g = c.borrow();
                Ok(g.widgets
                    .get(idx)
                    .is_some_and(|w| w.base().contains_point(x, y)))
            })?,
        )?;
    }

    // ── Padding / Margin ──────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setPadding",
            lua.create_function(
                move |_,
                      (top, right, bottom, left): (
                    f32,
                    Option<f32>,
                    Option<f32>,
                    Option<f32>,
                )| {
                    let mut g = c.borrow_mut();
                    if let Some(w) = g.widgets.get_mut(idx) {
                        let r = right.unwrap_or(top);
                        let bo = bottom.unwrap_or(top);
                        let l = left.unwrap_or(r);
                        w.base_mut().padding = [top, r, bo, l];
                    }
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getPadding",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    let p = w.base().padding;
                    Ok((p[0], p[1], p[2], p[3]))
                } else {
                    Ok((0.0, 0.0, 0.0, 0.0))
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setMargin",
            lua.create_function(
                move |_,
                      (top, right, bottom, left): (
                    f32,
                    Option<f32>,
                    Option<f32>,
                    Option<f32>,
                )| {
                    let mut g = c.borrow_mut();
                    if let Some(w) = g.widgets.get_mut(idx) {
                        let r = right.unwrap_or(top);
                        let bo = bottom.unwrap_or(top);
                        let l = left.unwrap_or(r);
                        w.base_mut().margin = [top, r, bo, l];
                    }
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMargin",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    let m = w.base().margin;
                    Ok((m[0], m[1], m[2], m[3]))
                } else {
                    Ok((0.0, 0.0, 0.0, 0.0))
                }
            })?,
        )?;
    }

    // ── Z-Order ───────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setZOrder",
            lua.create_function(move |_, z: i32| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().z_order = z;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getZOrder",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets.get(idx).map_or(0, |w| w.base().z_order))
            })?,
        )?;
    }

    // ── Min/Max Size ──────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setMinSize",
            lua.create_function(move |_, (w, h): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(wgt) = g.widgets.get_mut(idx) {
                    let b = wgt.base_mut();
                    b.min_width = w;
                    b.min_height = h;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMinSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    Ok((w.base().min_width, w.base().min_height))
                } else {
                    Ok((0.0, 0.0))
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setMaxSize",
            lua.create_function(move |_, (w, h): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(wgt) = g.widgets.get_mut(idx) {
                    let b = wgt.base_mut();
                    b.max_width = w;
                    b.max_height = h;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMaxSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(w) = g.widgets.get(idx) {
                    Ok((w.base().max_width, w.base().max_height))
                } else {
                    Ok((f32::INFINITY, f32::INFINITY))
                }
            })?,
        )?;
    }

    // ── Anchors ───────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setAnchor",
            lua.create_function(
                move |_,
                      (left, top, right, bottom): (
                    Option<f32>,
                    Option<f32>,
                    Option<f32>,
                    Option<f32>,
                )| {
                    let mut g = c.borrow_mut();
                    if let Some(w) = g.widgets.get_mut(idx) {
                        let b = w.base_mut();
                        b.anchor_left = left;
                        b.anchor_top = top;
                        b.anchor_right = right;
                        b.anchor_bottom = bottom;
                    }
                    Ok(())
                },
            )?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setAnchorCenter",
            lua.create_function(move |_, (cx, cy): (Option<f32>, Option<f32>)| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    let b = w.base_mut();
                    b.anchor_center_x = cx;
                    b.anchor_center_y = cy;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "clearAnchor",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().clear_anchors();
                }
                Ok(())
            })?,
        )?;
    }

    // ── Flex ──────────────────────────────────────────────────────────
    {
        let c = ctx.clone();
        t.set(
            "setFlexGrow",
            lua.create_function(move |_, grow: f32| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().flex_grow = grow;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getFlexGrow",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_grow))
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setFlexShrink",
            lua.create_function(move |_, shrink: f32| {
                let mut g = c.borrow_mut();
                if let Some(w) = g.widgets.get_mut(idx) {
                    w.base_mut().flex_shrink = shrink;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getFlexShrink",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_shrink))
            })?,
        )?;
    }

    Ok(t)
}

/// Add type-specific methods to a widget table for a Button.
fn add_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Button(btn)) = g.widgets.get_mut(idx) {
                    btn.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Button(btn)) => btn.text.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods to a widget table for a Label.
fn add_label_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Label(lbl)) = g.widgets.get_mut(idx) {
                    lbl.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Label(lbl)) => lbl.text.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for TextInput.
fn add_text_input_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                    ti.text = text.clone();
                    ti.cursor_pos = text.len();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TextInput(ti)) => ti.text.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setPlaceholder",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                    ti.placeholder = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getPlaceholder",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TextInput(ti)) => ti.placeholder.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setMaxLength",
            lua.create_function(move |_, n: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                    ti.max_length = n;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isFocused",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TextInput(ti)) => ti.focused,
                    _ => false,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getCursorPosition",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TextInput(ti)) => ti.cursor_pos,
                    _ => 0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for CheckBox.
fn add_checkbox_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setChecked",
            lua.create_function(move |_, checked: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::CheckBox(cb)) = g.widgets.get_mut(idx) {
                    cb.checked = checked;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isChecked",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::CheckBox(cb)) => cb.checked,
                    _ => false,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::CheckBox(cb)) = g.widgets.get_mut(idx) {
                    cb.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::CheckBox(cb)) => cb.text.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for Slider.
fn add_slider_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setValue",
            lua.create_function(move |_, v: f64| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Slider(sl)) = g.widgets.get_mut(idx) {
                    sl.set_value(v);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getValue",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Slider(sl)) => sl.value,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setRange",
            lua.create_function(move |_, (min, max): (f64, f64)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Slider(sl)) = g.widgets.get_mut(idx) {
                    sl.min = min;
                    sl.max = max;
                    sl.set_value(sl.value);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setStep",
            lua.create_function(move |_, step: f64| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Slider(sl)) = g.widgets.get_mut(idx) {
                    sl.step = step;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMin",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Slider(sl)) => sl.min,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMax",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Slider(sl)) => sl.max,
                    _ => 1.0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for ProgressBar.
fn add_progress_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setValue",
            lua.create_function(move |_, v: f64| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ProgressBar(pb)) = g.widgets.get_mut(idx) {
                    pb.value = v.clamp(pb.min, pb.max);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getValue",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ProgressBar(pb)) => pb.value,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getProgress",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ProgressBar(pb)) => pb.progress(),
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setRange",
            lua.create_function(move |_, (min, max): (f64, f64)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ProgressBar(pb)) = g.widgets.get_mut(idx) {
                    pb.min = min;
                    pb.max = max;
                    pb.value = pb.value.clamp(min, max);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMin",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ProgressBar(pb)) => pb.min,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMax",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ProgressBar(pb)) => pb.max,
                    _ => 1.0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for ComboBox (1-based indices in Lua).
fn add_combo_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addItem",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                    cb.add_item(text);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeItem",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                    if index >= 1 && index <= cb.items.len() {
                        cb.remove_item(index - 1);
                        return Ok(true);
                    }
                }
                Ok(false)
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "clearItems",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                    cb.clear();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getItemCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ComboBox(cb)) => cb.items.len(),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getItem",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ComboBox(cb)) => {
                        if index >= 1 {
                            cb.items.get(index - 1).cloned()
                        } else {
                            None
                        }
                    }
                    _ => None,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSelectedIndex",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                    if index >= 1 && index <= cb.items.len() {
                        cb.selected_index = Some(index - 1);
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSelectedIndex",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ComboBox(cb)) => cb.selected_index.map_or(0, |i| i + 1),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSelectedItem",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ComboBox(cb)) => {
                        cb.selected_item().map(|s| s.to_string())
                    }
                    _ => None,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for ListBox (1-based indices in Lua).
fn add_list_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addItem",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                    lb.add_item(text);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeItem",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                    if index >= 1 {
                        lb.remove_item(index - 1);
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "clearItems",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                    lb.clear();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getItemCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ListBox(lb)) => lb.items.len(),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getItem",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ListBox(lb)) => {
                        if index >= 1 {
                            lb.items.get(index - 1).cloned().unwrap_or_default()
                        } else {
                            String::new()
                        }
                    }
                    _ => String::new(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSelectedIndex",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                    if index >= 1 && index <= lb.items.len() {
                        lb.selected_index = Some(index - 1);
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSelectedIndex",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ListBox(lb)) => lb.selected_index.map_or(0, |i| i + 1),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setItemHeight",
            lua.create_function(move |_, h: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                    lb.item_height = h;
                }
                Ok(())
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for TabBar (1-based indices in Lua).
fn add_tab_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addTab",
            lua.create_function(move |_, label: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TabBar(tb)) = g.widgets.get_mut(idx) {
                    tb.add_tab(label);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeTab",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TabBar(tb)) = g.widgets.get_mut(idx) {
                    if index >= 1 && index <= tb.tabs.len() {
                        tb.remove_tab(index - 1);
                        return Ok(true);
                    }
                }
                Ok(false)
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTab",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TabBar(tb)) => {
                        if index >= 1 {
                            tb.tabs.get(index - 1).cloned()
                        } else {
                            None
                        }
                    }
                    _ => None,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTabCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TabBar(tb)) => tb.tabs.len(),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setActiveTab",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TabBar(tb)) = g.widgets.get_mut(idx) {
                    if index >= 1 && index <= tb.tabs.len() {
                        tb.active_tab = index - 1;
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getActiveTab",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TabBar(tb)) => tb.active_tab + 1,
                    _ => 0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for Panel.
fn add_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setTitle",
            lua.create_function(move |_, title: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Panel(p)) = g.widgets.get_mut(idx) {
                    p.title = title;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTitle",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Panel(p)) => p.title.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setScrollable",
            lua.create_function(move |_, scrollable: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Panel(p)) = g.widgets.get_mut(idx) {
                    p.scrollable = scrollable;
                }
                Ok(())
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for Layout.
fn add_layout_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setDirection",
            lua.create_function(move |_, dir: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    if let Some(d) = LayoutDirection::parse_str(&dir) {
                        layout.direction = d;
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getDirection",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Layout(layout)) => layout.direction.as_str().to_string(),
                    _ => "vertical".to_string(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSpacing",
            lua.create_function(move |_, spacing: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    layout.spacing = spacing;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSpacing",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Layout(layout)) => layout.spacing,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setColumns",
            lua.create_function(move |_, n: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    layout.columns = n.max(1);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setWrap",
            lua.create_function(move |_, wrap: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    layout.wrap = wrap;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getWrap",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Layout(layout)) => layout.wrap,
                    _ => false,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setAlign",
            lua.create_function(move |_, align: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    layout.align = align;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getAlign",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Layout(layout)) => layout.align.clone(),
                    _ => "start".to_string(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setJustify",
            lua.create_function(move |_, justify: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Layout(layout)) = g.widgets.get_mut(idx) {
                    layout.justify = justify;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getJustify",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Layout(layout)) => layout.justify.clone(),
                    _ => "start".to_string(),
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for ScrollPanel.
fn add_scroll_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setContentSize",
            lua.create_function(move |_, (w, h): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.content_width = w;
                    sp.content_height = h;
                    sp.clamp_scroll();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getContentSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ScrollPanel(sp)) => (sp.content_width, sp.content_height),
                    _ => (0.0, 0.0),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setScrollPosition",
            lua.create_function(move |_, (x, y): (f32, f32)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.scroll_x = x;
                    sp.scroll_y = y;
                    sp.clamp_scroll();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getScrollPosition",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ScrollPanel(sp)) => (sp.scroll_x, sp.scroll_y),
                    _ => (0.0, 0.0),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMaxScroll",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ScrollPanel(sp)) => sp.max_scroll(),
                    _ => (0.0, 0.0),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setScrollSpeed",
            lua.create_function(move |_, speed: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.scroll_speed = speed;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getScrollSpeed",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::ScrollPanel(sp)) => sp.scroll_speed,
                    _ => 20.0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for NinePatch.
fn add_nine_patch_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setInsets",
            lua.create_function(move |_, (left, top, right, bottom): (u32, u32, u32, u32)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::NinePatch(np)) = g.widgets.get_mut(idx) {
                    np.inset_left = left;
                    np.inset_top = top;
                    np.inset_right = right;
                    np.inset_bottom = bottom;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getInsets",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::NinePatch(np)) => {
                        (np.inset_left, np.inset_top, np.inset_right, np.inset_bottom)
                    }
                    _ => (0, 0, 0, 0),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setImageDimensions",
            lua.create_function(move |_, (w, h): (u32, u32)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::NinePatch(np)) = g.widgets.get_mut(idx) {
                    np.image_width = w;
                    np.image_height = h;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getImageDimensions",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::NinePatch(np)) => (np.image_width, np.image_height),
                    _ => (0, 0),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSlices",
            lua.create_function(move |lua, ()| {
                let g = c.borrow();
                match g.widgets.get(idx) {
                    Some(WidgetKind::NinePatch(np)) => {
                        let slices = np.get_slices();
                        let result = lua.create_table()?;
                        for (i, s) in slices.iter().enumerate() {
                            let slice_t = lua.create_table()?;
                            slice_t.set("sx", s.0)?;
                            slice_t.set("sy", s.1)?;
                            slice_t.set("sw", s.2)?;
                            slice_t.set("sh", s.3)?;
                            slice_t.set("dx", s.4)?;
                            slice_t.set("dy", s.5)?;
                            slice_t.set("dw", s.6)?;
                            slice_t.set("dh", s.7)?;
                            result.set(i + 1, slice_t)?;
                        }
                        Ok(LuaValue::Table(result))
                    }
                    _ => Ok(LuaValue::Nil),
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for Toast.
fn add_toast_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setMessage",
            lua.create_function(move |_, msg: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Toast(toast)) = g.widgets.get_mut(idx) {
                    toast.message = msg;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMessage",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Toast(toast)) => toast.message.clone(),
                    _ => String::new(),
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setDuration",
            lua.create_function(move |_, d: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Toast(toast)) = g.widgets.get_mut(idx) {
                    toast.duration = d;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getDuration",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Toast(toast)) => toast.duration,
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getProgress",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Toast(toast)) => toast.progress(),
                    _ => 0.0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isExpired",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Toast(toast)) => toast.is_expired(),
                    _ => true,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for Separator.
fn add_separator_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "setVertical",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Separator(sep)) = g.widgets.get_mut(idx) {
                    sep.vertical = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isVertical",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Separator(sep)) => sep.vertical,
                    _ => false,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setThickness",
            lua.create_function(move |_, thickness: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Separator(sep)) = g.widgets.get_mut(idx) {
                    sep.thickness = thickness;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getThickness",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::Separator(sep)) => sep.thickness,
                    _ => 1.0,
                })
            })?,
        )?;
    }
    Ok(())
}

/// Add type-specific methods for TreeView (1-based indices in Lua).
fn add_tree_view_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addNode",
            lua.create_function(move |_, (text, parent_index): (String, Option<usize>)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    let pi = parent_index.map(|i| i.saturating_sub(1));
                    let node_idx = tv.add_node(text, pi);
                    Ok(node_idx + 1) // 1-based
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "toggleNode",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    if index >= 1 {
                        tv.toggle_node(index - 1);
                        return Ok(tv.nodes.get(index - 1).is_some_and(|n| n.expanded));
                    }
                }
                Ok(false)
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isExpanded",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TreeView(tv)) => {
                        if index >= 1 {
                            tv.nodes.get(index - 1).is_some_and(|n| n.expanded)
                        } else {
                            false
                        }
                    }
                    _ => false,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getNodeCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(match g.widgets.get(idx) {
                    Some(WidgetKind::TreeView(tv)) => tv.node_count(),
                    _ => 0,
                })
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeNode",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.remove_node(i)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "clearNodes",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    tv.clear_nodes();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getNodeText",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(index.checked_sub(1)
                        .and_then(|i| tv.get_node_text(i))
                        .map(str::to_string))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setNodeText",
            lua.create_function(move |_, (index, text): (usize, String)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.set_node_text(i, text)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setNodeIcon",
            lua.create_function(move |_, (index, icon): (usize, String)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.set_node_icon(i, icon)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "expandNode",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.expand_node(i)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "collapseNode",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.collapse_node(i)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isNodeExpanded",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(index.checked_sub(1).and_then(|i| tv.is_node_expanded(i)))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "expandAll",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    tv.expand_all();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "collapseAll",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    tv.collapse_all();
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSelectedNode",
            lua.create_function(move |_, index: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                    Ok(index.checked_sub(1).is_some_and(|i| tv.set_selected_node(i)))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSelectedNode",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(tv.get_selected_node().map(|i| i + 1))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getChildNodes",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(index
                        .checked_sub(1)
                        .and_then(|i| tv.get_child_nodes(i))
                        .map(|v| v.iter().map(|&c| c + 1).collect::<Vec<_>>())
                        .unwrap_or_default())
                } else {
                    Ok(Vec::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getParentNode",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(index
                        .checked_sub(1)
                        .and_then(|i| tv.get_parent_node(i))
                        .flatten()
                        .map(|p| p + 1))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getNodeDepth",
            lua.create_function(move |_, index: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                    Ok(index.checked_sub(1).and_then(|i| tv.get_node_depth(i)))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    Ok(())
}


/// Add RadioButton-specific Lua methods to the widget table.
fn add_radio_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get(idx) {
                    Ok(rb.text.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                    rb.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isSelected",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get(idx) {
                    Ok(rb.selected)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSelected",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                    rb.selected = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getGroup",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get(idx) {
                    Ok(rb.group.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setGroup",
            lua.create_function(move |_, group: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                    rb.group = group;
                }
                Ok(())
            })?,
        )?;
    }
    t.set(
        "setOnChange",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add ScrollBar-specific Lua methods to the widget table.
fn add_scroll_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getScrollPosition",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get(idx) {
                    Ok(sb.position)
                } else {
                    Ok(0.0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setScrollPosition",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                    sb.position = v.clamp(0.0, (sb.content_size - sb.view_size).max(0.0));
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getContentSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get(idx) {
                    Ok(sb.content_size)
                } else {
                    Ok(0.0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setContentSize",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                    sb.content_size = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getViewSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get(idx) {
                    Ok(sb.view_size)
                } else {
                    Ok(0.0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setViewSize",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                    sb.view_size = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isVertical",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get(idx) {
                    Ok(sb.vertical)
                } else {
                    Ok(true)
                }
            })?,
        )?;
    }
    t.set(
        "setOnChange",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add GUIWindow-specific Lua methods to the widget table.
fn add_gui_window_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getTitle",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get(idx) {
                    Ok(w.title.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setTitle",
            lua.create_function(move |_, title: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                    w.title = title;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isCloseable",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get(idx) {
                    Ok(w.closeable)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setCloseable",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                    w.closeable = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isDraggable",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get(idx) {
                    Ok(w.draggable)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setDraggable",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                    w.draggable = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isResizable",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get(idx) {
                    Ok(w.resizable)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setResizable",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                    w.resizable = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                g.add_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                g.remove_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getChildren",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get(idx) {
                    Ok(w.children.clone())
                } else {
                    Ok(Vec::new())
                }
            })?,
        )?;
    }
    t.set(
        "setOnClose",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add SplitPanel-specific Lua methods to the widget table.
fn add_split_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getOrientation",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get(idx) {
                    Ok(sp.orientation.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setOrientation",
            lua.create_function(move |_, v: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.orientation = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSplitPosition",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get(idx) {
                    Ok(sp.split_position)
                } else {
                    Ok(0.5)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSplitPosition",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.split_position = v.clamp(0.0, 1.0);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMinPanelSize",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get(idx) {
                    Ok(sp.min_panel_size)
                } else {
                    Ok(50.0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setMinPanelSize",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.min_panel_size = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setFirstChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.first_child = Some(child_idx);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSecondChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                    sp.second_child = Some(child_idx);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getFirstChild",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get(idx) {
                    Ok(sp.first_child)
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSecondChild",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get(idx) {
                    Ok(sp.second_child)
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add DockPanel-specific Lua methods to the widget table.
fn add_dock_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "dock",
            lua.create_function(move |_, (child_idx, side): (usize, String)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get_mut(idx) {
                    dp.docked.push((child_idx, side));
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "undock",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get_mut(idx) {
                    dp.docked.retain(|(ci, _)| *ci != child_idx);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getDockedCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get(idx) {
                    Ok(dp.docked.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSplitSize",
            lua.create_function(move |_, (side, size): (String, f32)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get_mut(idx) {
                    if let Some(entry) = dp.split_sizes.iter_mut().find(|(s, _)| *s == side) {
                        entry.1 = size;
                    } else {
                        dp.split_sizes.push((side, size));
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSplitSize",
            lua.create_function(move |_, side: String| {
                let g = c.borrow();
                if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get(idx) {
                    Ok(dp
                        .split_sizes
                        .iter()
                        .find(|(s, _)| *s == side)
                        .map(|(_, v)| *v))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add Toolbar-specific Lua methods to the widget table.
fn add_toolbar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getOrientation",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                    Ok(tb.orientation.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setOrientation",
            lua.create_function(move |_, v: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                    tb.orientation = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                g.add_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeChild",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                g.remove_child(idx, child_idx);
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getChildren",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                    Ok(tb.children.clone())
                } else {
                    Ok(Vec::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addButton",
            lua.create_function(
                move |_, (id, tooltip): (String, Option<String>)| {
                    let mut g = c.borrow_mut();
                    if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                        let btn_idx = tb.add_button(id, tooltip.unwrap_or_default());
                        Ok(btn_idx + 1)
                    } else {
                        Ok(0)
                    }
                },
            )?,
        )?;
    }
    t.set(
        "addSeparator",
        lua.create_function(|_, ()| Ok(()))?,
    )?;
    t.set(
        "addSpacer",
        lua.create_function(|_, _width: Option<f32>| Ok(()))?,
    )?;
    {
        let c = ctx.clone();
        t.set(
            "getButton",
            lua.create_function(move |lua, id: String| {
                let g = c.borrow();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                    if let Some(btn) = tb.buttons.iter().find(|b| b.id == id) {
                        let tbl = lua.create_table()?;
                        tbl.set("id", btn.id.clone())?;
                        tbl.set("tooltip", btn.tooltip.clone())?;
                        tbl.set("enabled", btn.enabled)?;
                        tbl.set("toggled", btn.toggled)?;
                        return Ok(Some(tbl));
                    }
                }
                Ok(None)
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setButtonEnabled",
            lua.create_function(move |_, (id, enabled): (String, bool)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                    Ok(tb.set_button_enabled(&id, enabled))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setButtonToggled",
            lua.create_function(move |_, (id, toggled): (String, bool)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                    Ok(tb.set_button_toggled(&id, toggled))
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isButtonToggled",
            lua.create_function(move |_, id: String| {
                let g = c.borrow();
                if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                    Ok(tb.is_button_toggled(&id))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add MenuBar-specific Lua methods to the widget table.
fn add_menu_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addMenu",
            lua.create_function(move |_, menu_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuBar(mb)) = g.widgets.get_mut(idx) {
                    if !mb.menus.contains(&menu_idx) {
                        mb.menus.push(menu_idx);
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "removeMenu",
            lua.create_function(move |_, menu_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuBar(mb)) = g.widgets.get_mut(idx) {
                    mb.menus.retain(|m| *m != menu_idx);
                    Ok(true)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMenus",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuBar(mb)) = g.widgets.get(idx) {
                    Ok(mb.menus.clone())
                } else {
                    Ok(Vec::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getMenuCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuBar(mb)) = g.widgets.get(idx) {
                    Ok(mb.menus.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add MenuItem-specific Lua methods to the widget table.
fn add_menu_item_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get(idx) {
                    Ok(mi.text.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                    mi.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getShortcut",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get(idx) {
                    Ok(mi.shortcut.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setShortcut",
            lua.create_function(move |_, shortcut: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                    mi.shortcut = shortcut;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isChecked",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get(idx) {
                    Ok(mi.checked)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setChecked",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                    mi.checked = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addSubItem",
            lua.create_function(move |_, child_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                    if !mi.items.contains(&child_idx) {
                        mi.items.push(child_idx);
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSubItems",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get(idx) {
                    Ok(mi.items.clone())
                } else {
                    Ok(Vec::new())
                }
            })?,
        )?;
    }
    t.set(
        "setOnClick",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add Dialog-specific Lua methods to the widget table.
fn add_dialog_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getTitle",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get(idx) {
                    Ok(d.title.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setTitle",
            lua.create_function(move |_, title: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.title = title;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isModal",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get(idx) {
                    Ok(d.modal)
                } else {
                    Ok(true)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setModal",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.modal = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isOpen",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get(idx) {
                    Ok(d.open)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "open",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.open = true;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "close",
            lua.create_function(move |_, ()| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.open = false;
                }
                Ok(())
            })?,
        )?;
    }
    t.set(
        "setOnClose",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    {
        let c = ctx.clone();
        t.set(
            "setContent",
            lua.create_function(move |_, content_idx: Option<usize>| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.content_idx = content_idx;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getContent",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get(idx) {
                    Ok(d.content_idx)
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addButton",
            lua.create_function(move |_, (text, _cb): (String, Option<LuaFunction>)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                    d.footer_buttons.push(text);
                    Ok(d.footer_buttons.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add StatusBar-specific Lua methods to the widget table.
fn add_status_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addSection",
            lua.create_function(move |_, (text, width): (String, Option<f32>)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get_mut(idx) {
                    sb.sections.push((text, width.unwrap_or(100.0)));
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSectionText",
            lua.create_function(move |_, (section_idx, text): (usize, String)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get_mut(idx) {
                    if section_idx >= 1 && section_idx <= sb.sections.len() {
                        sb.sections[section_idx - 1].0 = text;
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSectionText",
            lua.create_function(move |_, section_idx: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get(idx) {
                    if section_idx >= 1 && section_idx <= sb.sections.len() {
                        Ok(Some(sb.sections[section_idx - 1].0.clone()))
                    } else {
                        Ok(None)
                    }
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSectionCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get(idx) {
                    Ok(sb.sections.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSectionCount",
            lua.create_function(move |_, n: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get_mut(idx) {
                    sb.sections.resize(n, (String::new(), 100.0));
                }
                Ok(())
            })?,
        )?;
    }
    t.set(
        "setSectionWidget",
        lua.create_function(|_, (_sidx, _widx): (usize, usize)| Ok(()))?,
    )?;
    Ok(())
}

/// Add Accordion-specific Lua methods to the widget table.
fn add_accordion_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addSection",
            lua.create_function(move |_, (title, content_idx): (String, Option<usize>)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get_mut(idx) {
                    acc.sections.push(crate::gui::extras::AccordionSection {
                        title,
                        content_idx,
                        expanded: false,
                    });
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSectionCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get(idx) {
                    Ok(acc.sections.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "toggleSection",
            lua.create_function(move |_, section_idx: usize| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get_mut(idx) {
                    if section_idx >= 1 && section_idx <= acc.sections.len() {
                        let new_state = !acc.sections[section_idx - 1].expanded;
                        if acc.exclusive && new_state {
                            for s in acc.sections.iter_mut() {
                                s.expanded = false;
                            }
                        }
                        acc.sections[section_idx - 1].expanded = new_state;
                        Ok(new_state)
                    } else {
                        Ok(false)
                    }
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isSectionExpanded",
            lua.create_function(move |_, section_idx: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get(idx) {
                    if section_idx >= 1 && section_idx <= acc.sections.len() {
                        Ok(acc.sections[section_idx - 1].expanded)
                    } else {
                        Ok(false)
                    }
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isExclusive",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get(idx) {
                    Ok(acc.exclusive)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setExclusive",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get_mut(idx) {
                    acc.exclusive = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSectionTitle",
            lua.create_function(move |_, section_idx: usize| {
                let g = c.borrow();
                if let Some(WidgetKind::Accordion(acc)) = g.widgets.get(idx) {
                    if section_idx >= 1 && section_idx <= acc.sections.len() {
                        Ok(Some(acc.sections[section_idx - 1].title.clone()))
                    } else {
                        Ok(None)
                    }
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    Ok(())
}

/// Add TooltipPanel-specific Lua methods to the widget table.
fn add_tooltip_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getText",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get(idx) {
                    Ok(tp.text.clone())
                } else {
                    Ok(String::new())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setText",
            lua.create_function(move |_, text: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                    tp.text = text;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getDelay",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get(idx) {
                    Ok(tp.delay)
                } else {
                    Ok(0.5)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setDelay",
            lua.create_function(move |_, v: f32| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                    tp.delay = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTarget",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get(idx) {
                    Ok(tp.target_idx)
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setTarget",
            lua.create_function(move |_, target: Option<usize>| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                    tp.target_idx = target;
                }
                Ok(())
            })?,
        )?;
    }
    Ok(())
}

/// Add ColorPicker-specific Lua methods to the widget table.
fn add_color_picker_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getColor",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get(idx) {
                    Ok((cp.r, cp.g, cp.b, cp.a))
                } else {
                    Ok((1.0, 1.0, 1.0, 1.0))
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setColor",
            lua.create_function(move |_, (r, green, b, a): (f32, f32, f32, Option<f32>)| {
                let mut ctx_ref = c.borrow_mut();
                if let Some(WidgetKind::ColorPicker(cp)) = ctx_ref.widgets.get_mut(idx) {
                    cp.r = r;
                    cp.g = green;
                    cp.b = b;
                    cp.a = a.unwrap_or(cp.a);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getShowAlpha",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get(idx) {
                    Ok(cp.show_alpha)
                } else {
                    Ok(true)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setShowAlpha",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get_mut(idx) {
                    cp.show_alpha = v;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getColorMode",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get(idx) {
                    Ok(cp.color_mode.clone())
                } else {
                    Ok("rgb".to_string())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setColorMode",
            lua.create_function(move |_, mode: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get_mut(idx) {
                    cp.color_mode = mode;
                }
                Ok(())
            })?,
        )?;
    }
    t.set(
        "setOnChange",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add GUITable-specific Lua methods to the widget table.
fn add_gui_table_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "addColumn",
            lua.create_function(move |_, (header, width): (String, Option<f32>)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                    tbl.columns.push(crate::gui::extras::TableColumn {
                        header,
                        width: width.unwrap_or(100.0),
                    });
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getColumnCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get(idx) {
                    Ok(tbl.columns.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "addRow",
            lua.create_function(move |_, cells: Vec<String>| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                    tbl.rows.push(cells);
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getRowCount",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get(idx) {
                    Ok(tbl.rows.len())
                } else {
                    Ok(0)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getCell",
            lua.create_function(move |_, (row, col): (usize, usize)| {
                let g = c.borrow();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get(idx) {
                    if row >= 1
                        && row <= tbl.rows.len()
                        && col >= 1
                        && col <= tbl.rows[row - 1].len()
                    {
                        Ok(Some(tbl.rows[row - 1][col - 1].clone()))
                    } else {
                        Ok(None)
                    }
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setCell",
            lua.create_function(move |_, (row, col, text): (usize, usize, String)| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                    if row >= 1
                        && row <= tbl.rows.len()
                        && col >= 1
                        && col <= tbl.rows[row - 1].len()
                    {
                        tbl.rows[row - 1][col - 1] = text;
                    }
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getSelectedRow",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get(idx) {
                    Ok(tbl.selected_row.map(|r| r + 1))
                } else {
                    Ok(None)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSelectedRow",
            lua.create_function(move |_, row: Option<usize>| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                    tbl.selected_row = row.map(|r| r.saturating_sub(1));
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "isSortable",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get(idx) {
                    Ok(tbl.sortable)
                } else {
                    Ok(false)
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setSortable",
            lua.create_function(move |_, v: bool| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                    tbl.sortable = v;
                }
                Ok(())
            })?,
        )?;
    }
    t.set(
        "setOnSelect",
        lua.create_function(|_, _f: LuaFunction| Ok(()))?,
    )?;
    Ok(())
}

/// Add ImageWidget-specific Lua methods to the widget table.
fn add_image_widget_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    {
        let c = ctx.clone();
        t.set(
            "getScaleMode",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get(idx) {
                    Ok(iw.scale_mode.clone())
                } else {
                    Ok("fit".to_string())
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setScaleMode",
            lua.create_function(move |_, mode: String| {
                let mut g = c.borrow_mut();
                if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get_mut(idx) {
                    iw.scale_mode = mode;
                }
                Ok(())
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "getTint",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get(idx) {
                    Ok((iw.tint.0, iw.tint.1, iw.tint.2, iw.tint.3))
                } else {
                    Ok((1.0, 1.0, 1.0, 1.0))
                }
            })?,
        )?;
    }
    {
        let c = ctx.clone();
        t.set(
            "setTint",
            lua.create_function(move |_, (r, green, b, a): (f32, f32, f32, Option<f32>)| {
                let mut ctx_ref = c.borrow_mut();
                if let Some(WidgetKind::ImageWidget(iw)) = ctx_ref.widgets.get_mut(idx) {
                    iw.tint = (r, green, b, a.unwrap_or(1.0));
                }
                Ok(())
            })?,
        )?;
    }
    Ok(())
}

/// Register the `luna.gui` namespace.
///
/// Creates the `gui` table on the `luna` global, populates it with widget
/// constructor functions, module-level utilities (focus, theme, toast, input
/// routing), and binds them to a shared `GuiContext`.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let gui_table = lua.create_table()?;
    let ctx = Rc::new(RefCell::new(GuiContext::new()));

    // ── Widget Constructors ───────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "newButton",
            lua.create_function(move |lua, text: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_button(text.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_button_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newLabel",
            lua.create_function(move |lua, text: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_label(text.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_label_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newTextInput",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_text_input();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_text_input_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newCheckbox",
            lua.create_function(move |lua, text: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_checkbox(text.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_checkbox_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newSlider",
            lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_slider(min.unwrap_or(0.0), max.unwrap_or(100.0));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_slider_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newProgressBar",
            lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_progress_bar(min.unwrap_or(0.0), max.unwrap_or(100.0));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_progress_bar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newComboBox",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_combo_box();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_combo_box_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newList",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_list_box();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_list_box_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newPanel",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_panel();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_panel_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newLayout",
            lua.create_function(move |lua, direction: Option<String>| {
                let dir = direction
                    .as_deref()
                    .and_then(LayoutDirection::parse_str)
                    .unwrap_or(LayoutDirection::Vertical);
                let mut g = c.borrow_mut();
                let idx = g.add_layout(dir);
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_layout_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newScrollPanel",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_scroll_panel();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_scroll_panel_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newNinePatch",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_nine_patch();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_nine_patch_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newTabBar",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_tab_bar();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_tab_bar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newSeparator",
            lua.create_function(move |lua, vertical: Option<bool>| {
                let mut g = c.borrow_mut();
                let idx = g.add_separator(vertical.unwrap_or(false));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_separator_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newSpacer",
            lua.create_function(move |lua, (w, h): (Option<f32>, Option<f32>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_spacer(w.unwrap_or(0.0), h.unwrap_or(0.0));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newToast",
            lua.create_function(move |lua, (message, duration): (Option<String>, Option<f32>)| {
                let toast = Toast::new(
                    message.unwrap_or_default(),
                    duration.unwrap_or(3.0),
                );
                let mut g = c.borrow_mut();
                let idx = g.widgets.len();
                g.widgets.push(WidgetKind::Toast(toast));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_toast_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newTreeView",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_tree_view();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_tree_view_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }


    {
        let c = ctx.clone();
        gui_table.set(
            "newRadioButton",
            lua.create_function(move |lua, (text, group): (Option<String>, Option<String>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_radio_button(text.unwrap_or_default(), group.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_radio_button_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newScrollBar",
            lua.create_function(move |lua, vertical: Option<bool>| {
                let mut g = c.borrow_mut();
                let idx = g.add_scroll_bar(vertical.unwrap_or(true));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_scroll_bar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newWindow",
            lua.create_function(move |lua, title: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_gui_window(title.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_gui_window_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newSplitPanel",
            lua.create_function(move |lua, orientation: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_split_panel(orientation.unwrap_or_else(|| "horizontal".to_string()));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_split_panel_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newDockPanel",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_dock_panel();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_dock_panel_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newToolbar",
            lua.create_function(move |lua, orientation: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_toolbar(orientation.unwrap_or_else(|| "horizontal".to_string()));
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_toolbar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newMenuBar",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_menu_bar();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_menu_bar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newMenuItem",
            lua.create_function(move |lua, text: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_menu_item(text.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_menu_item_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newDialog",
            lua.create_function(move |lua, title: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_dialog(title.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_dialog_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newStatusBar",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_status_bar();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_status_bar_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newAccordion",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_accordion();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_accordion_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newTooltipPanel",
            lua.create_function(move |lua, text: Option<String>| {
                let mut g = c.borrow_mut();
                let idx = g.add_tooltip_panel(text.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_tooltip_panel_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newColorPicker",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_color_picker();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_color_picker_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newTable",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_gui_table();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_gui_table_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "newImageWidget",
            lua.create_function(move |lua, ()| {
                let mut g = c.borrow_mut();
                let idx = g.add_image_widget();
                drop(g);
                let t = create_widget_table(lua, &c, idx)?;
                add_image_widget_methods(lua, &t, &c, idx)?;
                Ok(t)
            })?,
        )?;
    }

    // ── Theme ─────────────────────────────────────────────────────────

    gui_table.set(
        "newTheme",
        lua.create_function(|lua, ()| {
            let t = lua.create_table()?;
            let theme = Rc::new(RefCell::new(Theme::new()));

            {
                let th = theme.clone();
                t.set(
                    "setStyle",
                    lua.create_function(
                        move |_, (widget_type, state, style_table): (String, String, LuaTable)| {
                            let wt = match widget_type.as_str() {
                                "button" => WidgetType::Button,
                                "label" => WidgetType::Label,
                                "textinput" => WidgetType::TextInput,
                                "checkbox" => WidgetType::CheckBox,
                                "slider" => WidgetType::Slider,
                                "progressbar" => WidgetType::ProgressBar,
                                "combobox" => WidgetType::ComboBox,
                                "listbox" => WidgetType::ListBox,
                                "panel" => WidgetType::Panel,
                                "layout" => WidgetType::Layout,
                                "scrollpanel" => WidgetType::ScrollPanel,
                                "ninepatch" => WidgetType::NinePatch,
                                "tabbar" => WidgetType::TabBar,
                                "toast" => WidgetType::Toast,
                                "separator" => WidgetType::Separator,
                                "spacer" => WidgetType::Spacer,
                                "treeview" => WidgetType::TreeView,
                                "radiobutton" => WidgetType::RadioButton,
                                "scrollbar" => WidgetType::ScrollBar,
                                "guiwindow" => WidgetType::GUIWindow,
                                "splitpanel" => WidgetType::SplitPanel,
                                "dockpanel" => WidgetType::DockPanel,
                                "toolbar" => WidgetType::Toolbar,
                                "menubar" => WidgetType::MenuBar,
                                "menuitem" => WidgetType::MenuItem,
                                "dialog" => WidgetType::Dialog,
                                "statusbar" => WidgetType::StatusBar,
                                "accordion" => WidgetType::Accordion,
                                "tooltippanel" => WidgetType::TooltipPanel,
                                "colorpicker" => WidgetType::ColorPicker,
                                "guitable" => WidgetType::GUITable,
                                "imagewidget" => WidgetType::ImageWidget,
                                _ => {
                                    return Err(LuaError::external(format!(
                                        "gui.newTheme:setStyle: unknown widget type '{}'",
                                        widget_type
                                    )));
                                }
                            };
                            let ws = WidgetState::parse_str(&state).ok_or_else(|| {
                                LuaError::external(format!(
                                    "gui.newTheme:setStyle: unknown state '{}'",
                                    state
                                ))
                            })?;

                            let mut style = WidgetStyle::default();
                            if let Ok(bg) = style_table.get::<_, LuaTable>("bg") {
                                style.bg_color = [
                                    bg.get::<_, f32>(1).unwrap_or(0.2),
                                    bg.get::<_, f32>(2).unwrap_or(0.2),
                                    bg.get::<_, f32>(3).unwrap_or(0.2),
                                    bg.get::<_, f32>(4).unwrap_or(1.0),
                                ];
                            }
                            if let Ok(fg) = style_table.get::<_, LuaTable>("fg") {
                                style.fg_color = [
                                    fg.get::<_, f32>(1).unwrap_or(1.0),
                                    fg.get::<_, f32>(2).unwrap_or(1.0),
                                    fg.get::<_, f32>(3).unwrap_or(1.0),
                                    fg.get::<_, f32>(4).unwrap_or(1.0),
                                ];
                            }
                            if let Ok(bc) = style_table.get::<_, LuaTable>("border") {
                                style.border_color = [
                                    bc.get::<_, f32>(1).unwrap_or(0.4),
                                    bc.get::<_, f32>(2).unwrap_or(0.4),
                                    bc.get::<_, f32>(3).unwrap_or(0.4),
                                    bc.get::<_, f32>(4).unwrap_or(1.0),
                                ];
                            }
                            if let Ok(bw) = style_table.get::<_, f32>("borderWidth") {
                                style.border_width = bw;
                            }
                            if let Ok(cr) = style_table.get::<_, f32>("cornerRadius") {
                                style.corner_radius = cr;
                            }
                            if let Ok(fs) = style_table.get::<_, f32>("fontSize") {
                                style.font_size = fs;
                            }

                            th.borrow_mut().set_style(wt, ws, style);
                            Ok(())
                        },
                    )?,
                )?;
            }

            // Store theme Rc in table for retrieval
            t.set("_theme", lua.create_any_userdata(theme)?)?;

            Ok(t)
        })?,
    )?;

    {
        let c = ctx.clone();
        gui_table.set(
            "setTheme",
            lua.create_function(move |_, theme_table: LuaTable| {
                let theme_ud = theme_table.get::<_, LuaAnyUserData>("_theme")?;
                let theme_rc = theme_ud.borrow::<Rc<RefCell<Theme>>>()?;
                let theme = theme_rc.borrow().clone();
                c.borrow_mut().theme = Some(theme);
                Ok(())
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "getTheme",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.theme.is_some())
            })?,
        )?;
    }

    // ── Root ──────────────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "getRoot",
            lua.create_function(move |lua, ()| {
                let t = create_widget_table(lua, &c, 0)?;
                add_panel_methods(lua, &t, &c, 0)?;
                Ok(t)
            })?,
        )?;
    }

    // ── Focus ─────────────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "setFocus",
            lua.create_function(move |_, widget: Option<LuaTable>| {
                let idx = match widget {
                    Some(t) => Some(t.get::<_, usize>("_idx")?),
                    None => None,
                };
                c.borrow_mut().set_focus(idx);
                Ok(())
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "getFocus",
            lua.create_function(move |_, ()| {
                let g = c.borrow();
                Ok(g.focused_widget)
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "focusNext",
            lua.create_function(move |_, ()| {
                c.borrow_mut().focus_next();
                Ok(())
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "focusPrev",
            lua.create_function(move |_, ()| {
                c.borrow_mut().focus_prev();
                Ok(())
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "clearFocus",
            lua.create_function(move |_, ()| {
                c.borrow_mut().set_focus(None);
                Ok(())
            })?,
        )?;
    }

    // ── Toasts ────────────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "addToast",
            lua.create_function(move |_, toast_table: LuaTable| {
                let msg: String = toast_table
                    .get::<_, Option<String>>("message")?
                    .or_else(|| toast_table.get::<_, Option<String>>(1).ok().flatten())
                    .unwrap_or_default();
                let dur: f32 = toast_table
                    .get::<_, Option<f32>>("duration")?
                    .or_else(|| toast_table.get::<_, Option<f32>>(2).ok().flatten())
                    .unwrap_or(3.0);
                c.borrow_mut().add_toast(Toast::new(msg, dur));
                Ok(())
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "getToastCount",
            lua.create_function(move |_, ()| Ok(c.borrow().toast_count()))?,
        )?;
    }

    // ── Input Routing ─────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "mousepressed",
            lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
                Ok(c.borrow_mut().mouse_pressed(x, y, btn.unwrap_or(1)))
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "mousereleased",
            lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
                Ok(c.borrow_mut().mouse_released(x, y, btn.unwrap_or(1)))
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "mousemoved",
            lua.create_function(move |_, (x, y, _dx, _dy): (f32, f32, Option<f32>, Option<f32>)| {
                Ok(c.borrow_mut().mouse_moved(x, y))
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "keypressed",
            lua.create_function(move |_, key: String| {
                Ok(c.borrow_mut().key_pressed(&key))
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "textinput",
            lua.create_function(move |_, text: String| {
                Ok(c.borrow_mut().text_input(&text))
            })?,
        )?;
    }

    {
        let c = ctx.clone();
        gui_table.set(
            "wheelmoved",
            lua.create_function(move |_, (x, y): (f32, f32)| {
                Ok(c.borrow_mut().wheel_moved(x, y))
            })?,
        )?;
    }

    // ── Update ────────────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "update",
            lua.create_function(move |_, dt: f32| {
                c.borrow_mut().update(dt);
                Ok(())
            })?,
        )?;
    }

    // ── Draw (no-op in headless; real rendering handled by engine) ────

    gui_table.set(
        "draw",
        lua.create_function(|_, ()| {
            // In headless tests, draw is a no-op.
            // Real rendering is driven by the engine's wgpu pipeline.
            Ok(())
        })?,
    )?;

    // ── Widget Count ──────────────────────────────────────────────────

    {
        let c = ctx.clone();
        gui_table.set(
            "getWidgetCount",
            lua.create_function(move |_, ()| Ok(c.borrow().widget_count()))?,
        )?;
    }

    luna.set("gui", gui_table)?;
    Ok(())
}
