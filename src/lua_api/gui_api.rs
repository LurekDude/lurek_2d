//! `luna.ui` — Retained-mode widget UI system.

use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use super::SharedState;
use crate::gui::containers::LayoutDirection;
use crate::gui::context::{GuiContext, GuiEvent, WidgetKind};
use crate::gui::extras::{AccordionSection, TableColumn, Toast};
use crate::gui::theme::{Theme, WidgetStyle};
use crate::gui::widget::{WidgetState, WidgetType};

// -------------------------------------------------------------------------------
// GuiCallbacks — per-widget Lua callback registry
// -------------------------------------------------------------------------------

/// Stores registered Lua callbacks keyed by widget index.
/// Fields: on_click (HashMap<usize, RegistryKey>), on_change (HashMap<usize, RegistryKey>), on_close (HashMap<usize, RegistryKey>), on_select (HashMap<usize, RegistryKey>), on_draw (HashMap<usize, RegistryKey>).
#[derive(Default)]
struct GuiCallbacks {
    /// Per-widget click callbacks (Button, RadioButton, MenuItem).
    on_click: HashMap<usize, LuaRegistryKey>,
    /// Per-widget change callbacks (Slider, TextInput, CheckBox, ColorPicker, etc.).
    on_change: HashMap<usize, LuaRegistryKey>,
    /// Per-widget close callbacks (Dialog, GUIWindow).
    on_close: HashMap<usize, LuaRegistryKey>,
    /// Per-widget select callbacks (GUITable row selection).
    on_select: HashMap<usize, LuaRegistryKey>,
    /// Per-widget custom draw callbacks.
    on_draw: HashMap<usize, LuaRegistryKey>,
}

// -------------------------------------------------------------------------------
// create_widget_table — shared base methods for every widget
// -------------------------------------------------------------------------------

/// Builds a Lua table with common base-widget methods bound to `idx`.
fn create_widget_table<'a>(
    lua: &'a Lua,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    /// @return nil
    t.set("_idx", idx)?;

    // -- setPosition --
    /// Sets the widget position.
    /// @param x : number
    /// @param y : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getPosition --
    /// Returns the widget position.
    /// @return number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setSize --
    /// Sets the widget size.
    /// @param w : number
    /// @param h : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getSize --
    /// Returns the widget size.
    /// @return number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setVisible --
    /// Sets widget visibility.
    /// @param visible : boolean
    let c = ctx.clone();
    /// @return nil
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

    // -- isVisible --
    /// Returns whether the widget is visible.
    /// @return boolean
    let c = ctx.clone();
    /// @return nil
    t.set(
        "isVisible",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).is_some_and(|w| w.base().visible))
        })?,
    )?;

    // -- setEnabled --
    /// Sets whether the widget is enabled.
    /// @param enabled : boolean
    let c = ctx.clone();
    /// @return nil
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

    // -- isEnabled --
    /// Returns whether the widget is enabled.
    /// @return boolean
    let c = ctx.clone();
    /// @return nil
    t.set(
        "isEnabled",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).is_some_and(|w| w.base().enabled))
        })?,
    )?;

    // -- setId --
    /// Sets the widget string identifier.
    /// @param id : string
    let c = ctx.clone();
    /// @return nil
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

    // -- getId --
    /// Returns the widget string identifier.
    /// @return string
    let c = ctx.clone();
    /// @return nil
    t.set(
        "getId",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .map_or(String::new(), |w| w.base().id.clone()))
        })?,
    )?;

    // -- setTooltip --
    /// Sets the widget tooltip text.
    /// @param text : string
    let c = ctx.clone();
    /// @return nil
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

    // -- getTooltip --
    /// Returns the widget tooltip text.
    /// @return string
    let c = ctx.clone();
    /// @return nil
    t.set(
        "getTooltip",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .map_or(String::new(), |w| w.base().tooltip.clone()))
        })?,
    )?;

    // -- getState --
    /// Returns the widget interaction state name.
    /// @return string
    let c = ctx.clone();
    /// @return nil
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

    // -- addChild --
    /// Adds a child widget to this container.
    /// @param child : table
    let c = ctx.clone();
    /// @return nil
    t.set(
        "addChild",
        lua.create_function(move |_, child: LuaTable| {
            let child_idx: usize = child.get("_idx")?;
            let mut g = c.borrow_mut();
            g.add_child(idx, child_idx);
            Ok(())
        })?,
    )?;

    // -- removeChild --
    /// Removes a child widget from this container.
    /// @param child : table
    let c = ctx.clone();
    /// @return nil
    t.set(
        "removeChild",
        lua.create_function(move |_, child: LuaTable| {
            let child_idx: usize = child.get("_idx")?;
            let mut g = c.borrow_mut();
            g.remove_child(idx, child_idx);
            Ok(())
        })?,
    )?;

    // -- getChildCount --
    /// Returns the number of children in this container.
    /// @return number
    let c = ctx.clone();
    /// @return nil
    t.set(
        "getChildCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.child_count(idx))
        })?,
    )?;

    // -- findById --
    /// Recursively searches for a widget by id starting from this widget.
    /// @param id : string
    /// @return table
    let c = ctx.clone();
    /// @return nil
    t.set(
        "findById",
        lua.create_function(move |lua, id: String| {
            let g = c.borrow();
            match g.find_by_id(idx, &id) {
                Some(found_idx) => {
                    let ft = lua.create_table()?;
                    ft.set("_idx", found_idx)?;
                    Ok(LuaValue::Table(ft))
                }
                None => Ok(LuaValue::Nil),
            }
        })?,
    )?;

    // -- setOnClick --
    /// Registers a callback invoked when this widget is clicked.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnClick",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_click.insert(idx, key);
            Ok(())
        })?,
    )?;

    // -- setOnChange --
    /// Registers a callback invoked when this widget's value changes.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnChange",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;

    // -- setOnDraw --
    /// Stores a custom draw callback for later invocation.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnDraw",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_draw.insert(idx, key);
            Ok(())
        })?,
    )?;

    // -- containsPoint --
    /// Returns whether (x, y) is inside this widget.
    /// @param x : number
    /// @param y : number
    /// @return boolean
    let c = ctx.clone();
    /// @return nil
    t.set(
        "containsPoint",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .is_some_and(|w| w.base().contains_point(x, y)))
        })?,
    )?;

    // -- setPadding --
    /// Sets widget padding (CSS-like: top, right?, bottom?, left?).
    /// @param top : number
    /// @param right : number
    /// @param bottom : number
    /// @param left : number
    let c = ctx.clone();
    /// @return nil
    t.set(
        "setPadding",
        lua.create_function(
            move |_, (top, right, bottom, left): (f32, Option<f32>, Option<f32>, Option<f32>)| {
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

    // -- getPadding --
    /// Returns the widget padding (top, right, bottom, left).
    /// @return number, number, number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setMargin --
    /// Sets widget margin (CSS-like: top, right?, bottom?, left?).
    /// @param top : number
    /// @param right : number
    /// @param bottom : number
    /// @param left : number
    let c = ctx.clone();
    /// @return nil
    t.set(
        "setMargin",
        lua.create_function(
            move |_, (top, right, bottom, left): (f32, Option<f32>, Option<f32>, Option<f32>)| {
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

    // -- getMargin --
    /// Returns the widget margin (top, right, bottom, left).
    /// @return number, number, number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setZOrder --
    /// Sets the widget z-order for draw sorting.
    /// @param z : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getZOrder --
    /// Returns the widget z-order.
    /// @return number
    let c = ctx.clone();
    /// @return nil
    t.set(
        "getZOrder",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0, |w| w.base().z_order))
        })?,
    )?;

    // -- setMinSize --
    /// Sets the minimum widget size.
    /// @param w : number
    /// @param h : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getMinSize --
    /// Returns the minimum widget size.
    /// @return number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setMaxSize --
    /// Sets the maximum widget size.
    /// @param w : number
    /// @param h : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getMaxSize --
    /// Returns the maximum widget size.
    /// @return number, number
    let c = ctx.clone();
    /// @return nil
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

    // -- setAnchor --
    /// Sets anchor edges (left, top, right, bottom).
    /// @param left : number
    /// @param top : number
    /// @param right : number
    /// @param bottom : number
    let c = ctx.clone();
    /// @return nil
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

    // -- setAnchorCenter --
    /// Sets center anchor offsets.
    /// @param cx : number
    /// @param cy : number
    let c = ctx.clone();
    /// @return nil
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

    // -- clearAnchor --
    /// Removes all anchor constraints.
    let c = ctx.clone();
    /// @return nil
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

    // -- setFlexGrow --
    /// Sets the flex-grow factor.
    /// @param grow : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getFlexGrow --
    /// Returns the flex-grow factor.
    /// @return number
    let c = ctx.clone();
    /// @return nil
    t.set(
        "getFlexGrow",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_grow))
        })?,
    )?;

    // -- setFlexShrink --
    /// Sets the flex-shrink factor.
    /// @param shrink : number
    let c = ctx.clone();
    /// @return nil
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

    // -- getFlexShrink --
    /// Returns the flex-shrink factor.
    /// @return number
    let c = ctx.clone();
    /// @return table
    t.set(
        "getFlexShrink",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_shrink))
        })?,
    )?;

    Ok(t)
}

// -------------------------------------------------------------------------------
// Per-widget-type method helpers
// -------------------------------------------------------------------------------

/// Adds Button-specific methods to a widget table.
fn add_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    // -- setText --
    let c = ctx.clone();
    /// Sets the text for this Button widget.
    /// @return nil
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
    // -- getText --
    let c = ctx.clone();
    /// Returns the text of this Button widget.
    /// @return string
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
    Ok(())
}

/// Adds Label-specific methods to a widget table.
fn add_label_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the text for this Label widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the text of this Label widget.
    /// @return string
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
    Ok(())
}

/// Adds TextInput-specific methods to a widget table.
fn add_text_input_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the text for this Text_Input widget.
    /// @return nil
    t.set(
        "setText",
        lua.create_function(move |_, text: String| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                ti.cursor_pos = text.len();
                ti.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the text of this Text_Input widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the placeholder for this Text_Input widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the placeholder of this Text_Input widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the max length for this Text_Input widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if focused is enabled for this Text_Input widget.
    /// @return boolean
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
    let c = ctx.clone();
    /// Returns the cursor position of this Text_Input widget.
    /// @return integer
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
    Ok(())
}

/// Adds CheckBox-specific methods to a widget table.
fn add_checkbox_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the checked for this Checkbox widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if checked is enabled for this Checkbox widget.
    /// @return boolean
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
    let c = ctx.clone();
    /// Sets the text for this Checkbox widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the text of this Checkbox widget.
    /// @return string
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
    Ok(())
}

/// Adds Slider-specific methods to a widget table.
fn add_slider_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the value for this Slider widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the value of this Slider widget.
    /// @return number
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
    let c = ctx.clone();
    /// Sets the range for this Slider widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Sets the step for this Slider widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the min of this Slider widget.
    /// @return number
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
    let c = ctx.clone();
    /// Returns the max of this Slider widget.
    /// @return number
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
    Ok(())
}

/// Adds ProgressBar-specific methods to a widget table.
fn add_progress_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the value for this Progress_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the value of this Progress_Bar widget.
    /// @return number
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
    let c = ctx.clone();
    /// Returns the progress of this Progress_Bar widget.
    /// @return number
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
    let c = ctx.clone();
    /// Sets the range for this Progress_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the min of this Progress_Bar widget.
    /// @return number
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
    let c = ctx.clone();
    /// Returns the max of this Progress_Bar widget.
    /// @return number
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
    Ok(())
}

/// Adds ComboBox-specific methods (1-based indices in Lua).
fn add_combo_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a item entry to this Combo_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Removes the item from this Combo_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Clears all items entries from this Combo_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the item count of this Combo_Box widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Returns the item of this Combo_Box widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the selected index for this Combo_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the selected index of this Combo_Box widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Returns the selected item of this Combo_Box widget.
    /// @return string
    t.set(
        "getSelectedItem",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ComboBox(cb)) => cb.selected_item().map(|s| s.to_string()),
                _ => None,
            })
        })?,
    )?;
    Ok(())
}

/// Adds ListBox-specific methods (1-based indices in Lua).
fn add_list_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a item entry to this List_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Removes the item from this List_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Clears all items entries from this List_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the item count of this List_Box widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Returns the item of this List_Box widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the selected index for this List_Box widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the selected index of this List_Box widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Sets the item height for this List_Box widget.
    /// @return nil
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
    Ok(())
}

/// Adds TabBar-specific methods (1-based indices in Lua).
fn add_tab_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a tab entry to this Tab_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Removes the tab from this Tab_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the tab of this Tab_Bar widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Returns the tab count of this Tab_Bar widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Sets the active tab for this Tab_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the active tab of this Tab_Bar widget.
    /// @return integer
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
    Ok(())
}

/// Adds Panel-specific methods.
fn add_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the title for this Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the title of this Panel widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the scrollable for this Panel widget.
    /// @return nil
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
    Ok(())
}

/// Adds Layout-specific methods.
fn add_layout_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the direction for this Layout widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the direction of this Layout widget.
    /// @return string
    t.set(
        "getDirection",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.direction.as_str().to_string(),
                _ => "vertical".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the spacing for this Layout widget.
    /// @return nil
    t.set(
        "setSpacing",
        lua.create_function(move |_, spacing: f32| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.spacing = spacing;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the spacing of this Layout widget.
    /// @return number
    t.set(
        "getSpacing",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.spacing,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the columns for this Layout widget.
    /// @return nil
    t.set(
        "setColumns",
        lua.create_function(move |_, n: usize| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.columns = n.max(1);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the wrap for this Layout widget.
    /// @return nil
    t.set(
        "setWrap",
        lua.create_function(move |_, wrap: bool| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.wrap = wrap;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the wrap of this Layout widget.
    /// @return boolean
    t.set(
        "getWrap",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.wrap,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the align for this Layout widget.
    /// @return nil
    t.set(
        "setAlign",
        lua.create_function(move |_, align: String| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.align = align;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the align of this Layout widget.
    /// @return string
    t.set(
        "getAlign",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.align.clone(),
                _ => "start".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the justify for this Layout widget.
    /// @return nil
    t.set(
        "setJustify",
        lua.create_function(move |_, justify: String| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.justify = justify;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the justify of this Layout widget.
    /// @return string
    t.set(
        "getJustify",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.justify.clone(),
                _ => "start".to_string(),
            })
        })?,
    )?;
    Ok(())
}

/// Adds ScrollPanel-specific methods.
fn add_scroll_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the content size for this Scroll_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the content size of this Scroll_Panel widget.
    /// @return number, number
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
    let c = ctx.clone();
    /// Sets the scroll position for this Scroll_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the scroll position of this Scroll_Panel widget.
    /// @return number, number
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
    let c = ctx.clone();
    /// Returns the max scroll of this Scroll_Panel widget.
    /// @return number, number
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
    let c = ctx.clone();
    /// Sets the scroll speed for this Scroll_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the scroll speed of this Scroll_Panel widget.
    /// @return number
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
    Ok(())
}

/// Adds NinePatch-specific methods.
fn add_nine_patch_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the insets for this Nine_Patch widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the insets of this Nine_Patch widget.
    /// @return integer, integer, integer, integer
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
    let c = ctx.clone();
    /// Sets the image dimensions for this Nine_Patch widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the image dimensions of this Nine_Patch widget.
    /// @return integer, integer
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
    let c = ctx.clone();
    /// Returns the slices of this Nine_Patch widget.
    /// @return table
    t.set(
        "getSlices",
        lua.create_function(move |lua, ()| {
            let g = c.borrow();
            match g.widgets.get(idx) {
                Some(WidgetKind::NinePatch(np)) => {
                    let slices = np.get_slices();
                    let result = lua.create_table()?;
                    for (i, s) in slices.iter().enumerate() {
                        let st = lua.create_table()?;
                        st.set("sx", s.0)?;
                        st.set("sy", s.1)?;
                        st.set("sw", s.2)?;
                        st.set("sh", s.3)?;
                        st.set("dx", s.4)?;
                        st.set("dy", s.5)?;
                        st.set("dw", s.6)?;
                        st.set("dh", s.7)?;
                        result.set(i + 1, st)?;
                    }
                    Ok(LuaValue::Table(result))
                }
                _ => Ok(LuaValue::Nil),
            }
        })?,
    )?;
    Ok(())
}

/// Adds Toast-specific methods.
fn add_toast_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the message for this Toast widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the message of this Toast widget.
    /// @return string
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
    let c = ctx.clone();
    /// Sets the duration for this Toast widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the duration of this Toast widget.
    /// @return number
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
    let c = ctx.clone();
    /// Returns the progress of this Toast widget.
    /// @return number
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
    let c = ctx.clone();
    /// Returns true if expired is enabled for this Toast widget.
    /// @return boolean
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
    Ok(())
}

/// Adds Separator-specific methods.
fn add_separator_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Sets the vertical for this Separator widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if vertical is enabled for this Separator widget.
    /// @return boolean
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
    let c = ctx.clone();
    /// Sets the thickness for this Separator widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the thickness of this Separator widget.
    /// @return number
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
    Ok(())
}

/// Adds TreeView-specific methods (1-based indices in Lua).
fn add_tree_view_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a node entry to this Tree_View widget.
    /// @return nil
    t.set(
        "addNode",
        lua.create_function(move |_, (text, parent_index): (String, Option<usize>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                let pi = parent_index.map(|i| i.saturating_sub(1));
                Ok(tv.add_node(text, pi) + 1)
            } else {
                Ok(0)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Toggles the node state of this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if expanded is enabled for this Tree_View widget.
    /// @return boolean
    t.set(
        "isExpanded",
        lua.create_function(move |_, index: usize| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TreeView(tv)) => {
                    index >= 1 && tv.nodes.get(index - 1).is_some_and(|n| n.expanded)
                }
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the node count of this Tree_View widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Removes the node from this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Clears all nodes entries from this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the node text of this Tree_View widget.
    /// @return string
    t.set(
        "getNodeText",
        lua.create_function(move |_, index: usize| {
            let g = c.borrow();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                Ok(index
                    .checked_sub(1)
                    .and_then(|i| tv.get_node_text(i))
                    .map(str::to_string))
            } else {
                Ok(None)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the node text for this Tree_View widget.
    /// @return nil
    t.set(
        "setNodeText",
        lua.create_function(move |_, (index, text): (usize, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index
                    .checked_sub(1)
                    .is_some_and(|i| tv.set_node_text(i, text)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the node icon for this Tree_View widget.
    /// @return nil
    t.set(
        "setNodeIcon",
        lua.create_function(move |_, (index, icon): (usize, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index
                    .checked_sub(1)
                    .is_some_and(|i| tv.set_node_icon(i, icon)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Performs the expand node operation on this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Performs the collapse node operation on this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if node expanded is enabled for this Tree_View widget.
    /// @return boolean
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
    let c = ctx.clone();
    /// Performs the expand all operation on this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Performs the collapse all operation on this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Sets the selected node for this Tree_View widget.
    /// @return nil
    t.set(
        "setSelectedNode",
        lua.create_function(move |_, index: usize| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index
                    .checked_sub(1)
                    .is_some_and(|i| tv.set_selected_node(i)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the selected node of this Tree_View widget.
    /// @return integer
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
    let c = ctx.clone();
    /// Returns the child nodes of this Tree_View widget.
    /// @return nil
    t.set(
        "getChildNodes",
        lua.create_function(move |_, index: usize| {
            let g = c.borrow();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                Ok(index
                    .checked_sub(1)
                    .and_then(|i| tv.get_child_nodes(i))
                    .map(|v| v.iter().map(|&ci| ci + 1).collect::<Vec<_>>())
                    .unwrap_or_default())
            } else {
                Ok(Vec::new())
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the parent node of this Tree_View widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the node depth of this Tree_View widget.
    /// @return nil
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
    Ok(())
}

/// Adds RadioButton-specific methods.
fn add_radio_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the text of this Radio_Button widget.
    /// @return string
    t.set(
        "getText",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the text for this Radio_Button widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if selected is enabled for this Radio_Button widget.
    /// @return boolean
    t.set(
        "isSelected",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.selected,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the selected for this Radio_Button widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the group of this Radio_Button widget.
    /// @return string
    t.set(
        "getGroup",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.group.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the group for this Radio_Button widget.
    /// @return nil
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
    /// Registers a callback invoked when this widget's value changes.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnChange",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds ScrollBar-specific methods.
fn add_scroll_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the scroll position of this Scroll_Bar widget.
    /// @return number
    t.set(
        "getScrollPosition",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.position,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the scroll position for this Scroll_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the content size of this Scroll_Bar widget.
    /// @return number
    t.set(
        "getContentSize",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.content_size,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the content size for this Scroll_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the view size of this Scroll_Bar widget.
    /// @return number
    t.set(
        "getViewSize",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.view_size,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the view size for this Scroll_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if vertical is enabled for this Scroll_Bar widget.
    /// @return boolean
    t.set(
        "isVertical",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.vertical,
                _ => true,
            })
        })?,
    )?;
    /// Registers a callback invoked when this widget's value changes.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnChange",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds GUIWindow-specific methods.
fn add_gui_window_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the title of this Gui_Window widget.
    /// @return string
    t.set(
        "getTitle",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.title.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the title for this Gui_Window widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if closeable is enabled for this Gui_Window widget.
    /// @return boolean
    t.set(
        "isCloseable",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.closeable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the closeable for this Gui_Window widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if draggable is enabled for this Gui_Window widget.
    /// @return boolean
    t.set(
        "isDraggable",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.draggable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the draggable for this Gui_Window widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if resizable is enabled for this Gui_Window widget.
    /// @return boolean
    t.set(
        "isResizable",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.resizable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the resizable for this Gui_Window widget.
    /// @return nil
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
    /// Registers a callback invoked when this window is closed.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnClose",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_close.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds SplitPanel-specific methods.
fn add_split_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the orientation of this Split_Panel widget.
    /// @return string
    t.set(
        "getOrientation",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.orientation.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the orientation for this Split_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the split position of this Split_Panel widget.
    /// @return number
    t.set(
        "getSplitPosition",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.split_position,
                _ => 0.5,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the split position for this Split_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the min panel size of this Split_Panel widget.
    /// @return number
    t.set(
        "getMinPanelSize",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.min_panel_size,
                _ => 50.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the min panel size for this Split_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Sets the first child for this Split_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Sets the second child for this Split_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the first child of this Split_Panel widget.
    /// @return nil
    t.set(
        "getFirstChild",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.first_child,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the second child of this Split_Panel widget.
    /// @return nil
    t.set(
        "getSecondChild",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.second_child,
                _ => None,
            })
        })?,
    )?;
    Ok(())
}

/// Adds DockPanel-specific methods.
fn add_dock_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Performs the dock operation on this Dock_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Performs the undock operation on this Dock_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the docked count of this Dock_Panel widget.
    /// @return integer
    t.set(
        "getDockedCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::DockPanel(dp)) => dp.docked.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the split size for this Dock_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the split size of this Dock_Panel widget.
    /// @return nil
    t.set(
        "getSplitSize",
        lua.create_function(move |_, side: String| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::DockPanel(dp)) => dp
                    .split_sizes
                    .iter()
                    .find(|(s, _)| *s == side)
                    .map(|(_, v)| *v),
                _ => None,
            })
        })?,
    )?;
    Ok(())
}

/// Adds Toolbar-specific methods.
fn add_toolbar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the orientation of this Toolbar widget.
    /// @return string
    t.set(
        "getOrientation",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.orientation.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the orientation for this Toolbar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Adds a button entry to this Toolbar widget.
    /// @return nil
    t.set(
        "addButton",
        lua.create_function(move |_, (id, tooltip): (String, Option<String>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                Ok(tb.add_button(id, tooltip.unwrap_or_default()) + 1)
            } else {
                Ok(0)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the button of this Toolbar widget.
    /// @return boolean
    t.set(
        "getButton",
        lua.create_function(move |lua, id: String| {
            let g = c.borrow();
            if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                if let Some(btn) = tb.buttons.iter().find(|b| b.id == id) {
                    let bt = lua.create_table()?;
                    bt.set("id", btn.id.clone())?;
                    bt.set("tooltip", btn.tooltip.clone())?;
                    bt.set("enabled", btn.enabled)?;
                    bt.set("toggled", btn.toggled)?;
                    return Ok(Some(bt));
                }
            }
            Ok(None)
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the button enabled for this Toolbar widget.
    /// @return nil
    t.set(
        "setButtonEnabled",
        lua.create_function(move |_, (id, enabled): (String, bool)| {
            let mut g = c.borrow_mut();
            Ok(match g.widgets.get_mut(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.set_button_enabled(&id, enabled),
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the button toggled for this Toolbar widget.
    /// @return nil
    t.set(
        "setButtonToggled",
        lua.create_function(move |_, (id, toggled): (String, bool)| {
            let mut g = c.borrow_mut();
            Ok(match g.widgets.get_mut(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.set_button_toggled(&id, toggled),
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns true if button toggled is enabled for this Toolbar widget.
    /// @return boolean
    t.set(
        "isButtonToggled",
        lua.create_function(move |_, id: String| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.is_button_toggled(&id),
                _ => None,
            })
        })?,
    )?;
    Ok(())
}

/// Adds MenuBar-specific methods.
fn add_menu_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a menu entry to this Menu_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Removes the menu from this Menu_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the menus of this Menu_Bar widget.
    /// @return nil
    t.set(
        "getMenus",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuBar(mb)) => mb.menus.clone(),
                _ => Vec::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the menu count of this Menu_Bar widget.
    /// @return integer
    t.set(
        "getMenuCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuBar(mb)) => mb.menus.len(),
                _ => 0,
            })
        })?,
    )?;
    Ok(())
}

/// Adds MenuItem-specific methods.
fn add_menu_item_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the text of this Menu_Item widget.
    /// @return string
    t.set(
        "getText",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the text for this Menu_Item widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the shortcut of this Menu_Item widget.
    /// @return string
    t.set(
        "getShortcut",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.shortcut.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the shortcut for this Menu_Item widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if checked is enabled for this Menu_Item widget.
    /// @return boolean
    t.set(
        "isChecked",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.checked,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the checked for this Menu_Item widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Adds a sub item entry to this Menu_Item widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the sub items of this Menu_Item widget.
    /// @return nil
    t.set(
        "getSubItems",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.items.clone(),
                _ => Vec::new(),
            })
        })?,
    )?;
    /// Registers a callback invoked when this menu item is clicked.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnClick",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_click.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds Dialog-specific methods.
fn add_dialog_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the title of this Dialog widget.
    /// @return string
    t.set(
        "getTitle",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.title.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the title for this Dialog widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if modal is enabled for this Dialog widget.
    /// @return boolean
    t.set(
        "isModal",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.modal,
                _ => true,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the modal for this Dialog widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if open is enabled for this Dialog widget.
    /// @return boolean
    t.set(
        "isOpen",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.open,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Performs the open operation on this Dialog widget.
    /// @return nil
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
    /// Closes and removes this dialog from the screen.
    /// @return nil
    let c2 = ctx.clone();
    t.set(
        "close",
        lua.create_function(move |_, ()| {
            let mut g = c2.borrow_mut();
            let was_open = matches!(g.widgets.get(idx), Some(WidgetKind::Dialog(d)) if d.open);
            if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                d.open = false;
            }
            if was_open {
                g.pending_events.push(GuiEvent::Close(idx));
            }
            Ok(())
        })?,
    )?;
    /// Registers a callback invoked when this dialog is closed.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnClose",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_close.insert(idx, key);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the content for this Dialog widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the content of this Dialog widget.
    /// @return integer
    t.set(
        "getContent",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.content_idx,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Adds a button entry to this Dialog widget.
    /// @return nil
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
    Ok(())
}

/// Adds StatusBar-specific methods.
fn add_status_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a section entry to this Status_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Sets the section text for this Status_Bar widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the section text of this Status_Bar widget.
    /// @return integer
    t.set(
        "getSectionText",
        lua.create_function(move |_, section_idx: usize| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::StatusBar(sb)) => {
                    if section_idx >= 1 && section_idx <= sb.sections.len() {
                        Some(sb.sections[section_idx - 1].0.clone())
                    } else {
                        None
                    }
                }
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the section count of this Status_Bar widget.
    /// @return integer
    t.set(
        "getSectionCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::StatusBar(sb)) => sb.sections.len(),
                _ => 0,
            })
        })?,
    )?;
    Ok(())
}

/// Adds Accordion-specific methods (1-based sections in Lua).
fn add_accordion_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a section entry to this Accordion widget.
    /// @return nil
    t.set(
        "addSection",
        lua.create_function(move |_, (title, content_idx): (String, Option<usize>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Accordion(acc)) = g.widgets.get_mut(idx) {
                acc.sections.push(AccordionSection {
                    title,
                    content_idx,
                    expanded: false,
                });
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the section count of this Accordion widget.
    /// @return integer
    t.set(
        "getSectionCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => acc.sections.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Toggles the section state of this Accordion widget.
    /// @return nil
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
                    return Ok(new_state);
                }
            }
            Ok(false)
        })?,
    )?;
    let c = ctx.clone();
    /// Returns true if section expanded is enabled for this Accordion widget.
    /// @return boolean
    t.set(
        "isSectionExpanded",
        lua.create_function(move |_, section_idx: usize| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => {
                    section_idx >= 1
                        && section_idx <= acc.sections.len()
                        && acc.sections[section_idx - 1].expanded
                }
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns true if exclusive is enabled for this Accordion widget.
    /// @return boolean
    t.set(
        "isExclusive",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => acc.exclusive,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the exclusive for this Accordion widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the section title of this Accordion widget.
    /// @return nil
    t.set(
        "getSectionTitle",
        lua.create_function(move |_, section_idx: usize| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => {
                    if section_idx >= 1 && section_idx <= acc.sections.len() {
                        Some(acc.sections[section_idx - 1].title.clone())
                    } else {
                        None
                    }
                }
                _ => None,
            })
        })?,
    )?;
    Ok(())
}

/// Adds TooltipPanel-specific methods.
fn add_tooltip_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the text of this Tooltip_Panel widget.
    /// @return string
    t.set(
        "getText",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the text for this Tooltip_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the delay of this Tooltip_Panel widget.
    /// @return number
    t.set(
        "getDelay",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.delay,
                _ => 0.5,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the delay for this Tooltip_Panel widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the target of this Tooltip_Panel widget.
    /// @return nil
    t.set(
        "getTarget",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.target_idx,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the target for this Tooltip_Panel widget.
    /// @return nil
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
    Ok(())
}

/// Adds ColorPicker-specific methods.
fn add_color_picker_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the color of this Color_Picker widget.
    /// @return number, number, number, number
    t.set(
        "getColor",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => (cp.r, cp.g, cp.b, cp.a),
                _ => (1.0, 1.0, 1.0, 1.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the color for this Color_Picker widget.
    /// @return nil
    t.set(
        "setColor",
        lua.create_function(move |_, (r, green, b, a): (f32, f32, f32, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get_mut(idx) {
                cp.r = r;
                cp.g = green;
                cp.b = b;
                cp.a = a.unwrap_or(cp.a);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the show alpha of this Color_Picker widget.
    /// @return boolean
    t.set(
        "getShowAlpha",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => cp.show_alpha,
                _ => true,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the show alpha for this Color_Picker widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the color mode of this Color_Picker widget.
    /// @return string
    t.set(
        "getColorMode",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => cp.color_mode.clone(),
                _ => "rgb".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the color mode for this Color_Picker widget.
    /// @return nil
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
    /// Registers a callback invoked when this widget's value changes.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnChange",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds GUITable-specific methods (1-based rows/cols in Lua).
fn add_gui_table_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a column entry to this Gui_Table widget.
    /// @return nil
    t.set(
        "addColumn",
        lua.create_function(move |_, (header, width): (String, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                tbl.columns.push(TableColumn {
                    header,
                    width: width.unwrap_or(100.0),
                });
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the column count of this Gui_Table widget.
    /// @return integer
    t.set(
        "getColumnCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.columns.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Adds a row entry to this Gui_Table widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the row count of this Gui_Table widget.
    /// @return integer
    t.set(
        "getRowCount",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.rows.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the cell of this Gui_Table widget.
    /// @return nil
    t.set(
        "getCell",
        lua.create_function(move |_, (row, col): (usize, usize)| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => {
                    if row >= 1
                        && row <= tbl.rows.len()
                        && col >= 1
                        && col <= tbl.rows[row - 1].len()
                    {
                        Some(tbl.rows[row - 1][col - 1].clone())
                    } else {
                        None
                    }
                }
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the cell for this Gui_Table widget.
    /// @return nil
    t.set(
        "setCell",
        lua.create_function(move |_, (row, col, text): (usize, usize, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                if row >= 1 && row <= tbl.rows.len() && col >= 1 && col <= tbl.rows[row - 1].len() {
                    tbl.rows[row - 1][col - 1] = text;
                }
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the selected row of this Gui_Table widget.
    /// @return nil
    t.set(
        "getSelectedRow",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.selected_row.map(|r| r + 1),
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the selected row for this Gui_Table widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns true if sortable is enabled for this Gui_Table widget.
    /// @return boolean
    t.set(
        "isSortable",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.sortable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the sortable for this Gui_Table widget.
    /// @return nil
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
    /// Registers a callback invoked when a table row is selected.
    /// @param fn : function
    /// @return nil
    let cbs2 = cbs.clone();
    t.set(
        "setOnSelect",
        lua.create_function(move |lua, f: LuaFunction| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_select.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}

/// Adds ImageWidget-specific methods.
fn add_image_widget_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Returns the scale mode of this Image_Widget widget.
    /// @return string
    t.set(
        "getScaleMode",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ImageWidget(iw)) => iw.scale_mode.clone(),
                _ => "fit".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the scale mode for this Image_Widget widget.
    /// @return nil
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
    let c = ctx.clone();
    /// Returns the tint of this Image_Widget widget.
    /// @return number, number, number, number
    t.set(
        "getTint",
        lua.create_function(move |_, ()| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ImageWidget(iw)) => (iw.tint.0, iw.tint.1, iw.tint.2, iw.tint.3),
                _ => (1.0, 1.0, 1.0, 1.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Sets the tint for this Image_Widget widget.
    /// @return nil
    t.set(
        "setTint",
        lua.create_function(move |_, (r, green, b, a): (f32, f32, f32, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get_mut(idx) {
                iw.tint = (r, green, b, a.unwrap_or(1.0));
            }
            Ok(())
        })?,
    )?;
    Ok(())
}

// -------------------------------------------------------------------------------
// LuaTheme UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a GUI [`Theme`].
struct LuaTheme {
    inner: Rc<RefCell<Theme>>,
}

impl LuaUserData for LuaTheme {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setStyle --
        /// Sets a style for a (widget_type, state) pair.
        /// @param widgetType : string
        /// @param state : string
        /// @param style : table
        /// @return nil
        methods.add_method(
            "setStyle",
            |_, this, (widget_type, state, style_table): (String, String, LuaTable)| {
                let wt = parse_widget_type(&widget_type).ok_or_else(|| {
                    LuaError::external(format!(
                        "gui.newTheme:setStyle: unknown widget type '{widget_type}'"
                    ))
                })?;
                let ws = WidgetState::parse_str(&state).ok_or_else(|| {
                    LuaError::external(format!("gui.newTheme:setStyle: unknown state '{state}'"))
                })?;
                let style = parse_widget_style(&style_table)?;
                this.inner.borrow_mut().set_style(wt, ws, style);
                Ok(())
            },
        );
    }
}

/// Parses a widget type string into a [`WidgetType`].
fn parse_widget_type(s: &str) -> Option<WidgetType> {
    match s {
        "button" => Some(WidgetType::Button),
        "label" => Some(WidgetType::Label),
        "textinput" => Some(WidgetType::TextInput),
        "checkbox" => Some(WidgetType::CheckBox),
        "slider" => Some(WidgetType::Slider),
        "progressbar" => Some(WidgetType::ProgressBar),
        "combobox" => Some(WidgetType::ComboBox),
        "listbox" => Some(WidgetType::ListBox),
        "panel" => Some(WidgetType::Panel),
        "layout" => Some(WidgetType::Layout),
        "scrollpanel" => Some(WidgetType::ScrollPanel),
        "ninepatch" => Some(WidgetType::NinePatch),
        "tabbar" => Some(WidgetType::TabBar),
        "toast" => Some(WidgetType::Toast),
        "separator" => Some(WidgetType::Separator),
        "spacer" => Some(WidgetType::Spacer),
        "treeview" => Some(WidgetType::TreeView),
        "radiobutton" => Some(WidgetType::RadioButton),
        "scrollbar" => Some(WidgetType::ScrollBar),
        "guiwindow" => Some(WidgetType::GUIWindow),
        "splitpanel" => Some(WidgetType::SplitPanel),
        "dockpanel" => Some(WidgetType::DockPanel),
        "toolbar" => Some(WidgetType::Toolbar),
        "menubar" => Some(WidgetType::MenuBar),
        "menuitem" => Some(WidgetType::MenuItem),
        "dialog" => Some(WidgetType::Dialog),
        "statusbar" => Some(WidgetType::StatusBar),
        "accordion" => Some(WidgetType::Accordion),
        "tooltippanel" => Some(WidgetType::TooltipPanel),
        "colorpicker" => Some(WidgetType::ColorPicker),
        "guitable" => Some(WidgetType::GUITable),
        "imagewidget" => Some(WidgetType::ImageWidget),
        _ => None,
    }
}

/// Parses a Lua style table into a [`WidgetStyle`].
fn parse_widget_style(t: &LuaTable) -> LuaResult<WidgetStyle> {
    let mut style = WidgetStyle::default();
    if let Ok(bg) = t.get::<_, LuaTable>("bg") {
        style.bg_color = [
            bg.get::<_, f32>(1).unwrap_or(0.2),
            bg.get::<_, f32>(2).unwrap_or(0.2),
            bg.get::<_, f32>(3).unwrap_or(0.2),
            bg.get::<_, f32>(4).unwrap_or(1.0),
        ];
    }
    if let Ok(fg) = t.get::<_, LuaTable>("fg") {
        style.fg_color = [
            fg.get::<_, f32>(1).unwrap_or(1.0),
            fg.get::<_, f32>(2).unwrap_or(1.0),
            fg.get::<_, f32>(3).unwrap_or(1.0),
            fg.get::<_, f32>(4).unwrap_or(1.0),
        ];
    }
    if let Ok(bc) = t.get::<_, LuaTable>("border") {
        style.border_color = [
            bc.get::<_, f32>(1).unwrap_or(0.4),
            bc.get::<_, f32>(2).unwrap_or(0.4),
            bc.get::<_, f32>(3).unwrap_or(0.4),
            bc.get::<_, f32>(4).unwrap_or(1.0),
        ];
    }
    if let Ok(bw) = t.get::<_, f32>("borderWidth") {
        style.border_width = bw;
    }
    if let Ok(cr) = t.get::<_, f32>("cornerRadius") {
        style.corner_radius = cr;
    }
    if let Ok(fs) = t.get::<_, f32>("fontSize") {
        style.font_size = fs;
    }
    Ok(style)
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.ui` API table.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let ctx = Rc::new(RefCell::new(GuiContext::new()));
    let callbacks = Rc::new(RefCell::new(GuiCallbacks::default()));

    // -- newButton --
    /// Creates a button widget.
    /// @param text : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newButton",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_button(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_button_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newLabel --
    /// Creates a text label widget.
    /// @param text : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newLabel",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_label(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_label_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newTextInput --
    /// Creates a text input widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newTextInput",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_text_input();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_text_input_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newCheckbox --
    /// Creates a checkbox widget.
    /// @param text : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newCheckbox",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_checkbox(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_checkbox_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newSlider --
    /// Creates a value slider widget.
    /// @param min : number
    /// @param max : number
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newSlider",
        lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_slider(min.unwrap_or(0.0), max.unwrap_or(100.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_slider_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newProgressBar --
    /// Creates a progress bar widget.
    /// @param min : number
    /// @param max : number
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newProgressBar",
        lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_progress_bar(min.unwrap_or(0.0), max.unwrap_or(100.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_progress_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newComboBox --
    /// Creates a dropdown combo box widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newComboBox",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_combo_box();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_combo_box_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newList --
    /// Creates a selectable list widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newList",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_list_box();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_list_box_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newPanel --
    /// Creates a container panel widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newLayout --
    /// Creates a flexbox layout container.
    /// @param direction : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newLayout",
        lua.create_function(move |lua, direction: Option<String>| {
            let dir = direction
                .as_deref()
                .and_then(LayoutDirection::parse_str)
                .unwrap_or(LayoutDirection::Vertical);
            let mut g = c.borrow_mut();
            let idx = g.add_layout(dir);
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_layout_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newScrollPanel --
    /// Creates a scrollable panel widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newScrollPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_scroll_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_scroll_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newNinePatch --
    /// Creates a 9-patch slicer widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newNinePatch",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_nine_patch();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_nine_patch_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newTabBar --
    /// Creates a tab bar widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newTabBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_tab_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_tab_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newSeparator --
    /// Creates a separator line.
    /// @param vertical : boolean
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newSeparator",
        lua.create_function(move |lua, vertical: Option<bool>| {
            let mut g = c.borrow_mut();
            let idx = g.add_separator(vertical.unwrap_or(false));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_separator_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newSpacer --
    /// Creates a spacing filler widget.
    /// @param w : number
    /// @param h : number
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newSpacer",
        lua.create_function(move |lua, (w, h): (Option<f32>, Option<f32>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_spacer(w.unwrap_or(0.0), h.unwrap_or(0.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newToast --
    /// Creates a toast notification widget.
    /// @param message : string
    /// @param duration : number
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newToast",
        lua.create_function(
            move |lua, (message, duration): (Option<String>, Option<f32>)| {
                let toast = Toast::new(message.unwrap_or_default(), duration.unwrap_or(3.0));
                let mut g = c.borrow_mut();
                let idx = g.widgets.len();
                g.widgets.push(WidgetKind::Toast(toast));
                drop(g);
                let t = create_widget_table(lua, &c, idx, &cbs)?;
                add_toast_methods(lua, &t, &c, idx)?;
                Ok(t)
            },
        )?,
    )?;

    // -- newTreeView --
    /// Creates a collapsible tree view widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newTreeView",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_tree_view();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_tree_view_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newRadioButton --
    /// Creates a grouped radio button widget.
    /// @param text : string
    /// @param group : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newRadioButton",
        lua.create_function(
            move |lua, (text, group): (Option<String>, Option<String>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_radio_button(text.unwrap_or_default(), group.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx, &cbs)?;
                add_radio_button_methods(lua, &t, &c, idx, &cbs)?;
                Ok(t)
            },
        )?,
    )?;

    // -- newScrollBar --
    /// Creates a scroll bar widget.
    /// @param vertical : boolean
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newScrollBar",
        lua.create_function(move |lua, vertical: Option<bool>| {
            let mut g = c.borrow_mut();
            let idx = g.add_scroll_bar(vertical.unwrap_or(true));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_scroll_bar_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newWindow --
    /// Creates a draggable window widget.
    /// @param title : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newWindow",
        lua.create_function(move |lua, title: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_gui_window(title.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_gui_window_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newSplitPanel --
    /// Creates a resizable split panel.
    /// @param orientation : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newSplitPanel",
        lua.create_function(move |lua, orientation: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_split_panel(orientation.unwrap_or_else(|| "horizontal".to_string()));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_split_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newDockPanel --
    /// Creates a dock panel.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newDockPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_dock_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_dock_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newToolbar --
    /// Creates a toolbar widget.
    /// @param orientation : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newToolbar",
        lua.create_function(move |lua, orientation: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_toolbar(orientation.unwrap_or_else(|| "horizontal".to_string()));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_toolbar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newMenuBar --
    /// Creates a menu bar widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newMenuBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_menu_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_menu_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newMenuItem --
    /// Creates a menu item widget.
    /// @param text : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newMenuItem",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_menu_item(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_menu_item_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newDialog --
    /// Creates a modal dialog widget.
    /// @param title : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newDialog",
        lua.create_function(move |lua, title: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_dialog(title.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_dialog_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newStatusBar --
    /// Creates a status bar widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newStatusBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_status_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_status_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newAccordion --
    /// Creates a collapsible accordion widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newAccordion",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_accordion();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_accordion_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newTooltipPanel --
    /// Creates a tooltip panel widget.
    /// @param text : string
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newTooltipPanel",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_tooltip_panel(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_tooltip_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newColorPicker --
    /// Creates a color picker widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newColorPicker",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_color_picker();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_color_picker_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newTable --
    /// Creates a data table widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newTable",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_gui_table();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_gui_table_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;

    // -- newImageWidget --
    /// Creates an image display widget.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "newImageWidget",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_image_widget();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs)?;
            add_image_widget_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;

    // -- newTheme --
    /// Creates a new theme instance.
    /// @return Theme
    tbl.set(
        "newTheme",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaTheme {
                inner: Rc::new(RefCell::new(Theme::new())),
            })
        })?,
    )?;

    // -- setTheme --
    /// Sets the active GUI theme.
    /// @param theme : Theme
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "setTheme",
        lua.create_function(move |_, theme_ud: LuaAnyUserData| {
            let lua_theme = theme_ud.borrow::<LuaTheme>()?;
            let theme = lua_theme.inner.borrow().clone();
            c.borrow_mut().theme = Some(theme);
            Ok(())
        })?,
    )?;

    // -- getTheme --
    /// Returns whether a theme is set.
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "getTheme",
        lua.create_function(move |_, ()| Ok(c.borrow().theme.is_some()))?,
    )?;

    // -- getRoot --
    /// Returns the root panel widget table.
    /// @return table
    let c = ctx.clone();
    let cbs = callbacks.clone();
    /// @return table
    tbl.set(
        "getRoot",
        lua.create_function(move |lua, ()| {
            let t = create_widget_table(lua, &c, 0, &cbs)?;
            add_panel_methods(lua, &t, &c, 0)?;
            Ok(t)
        })?,
    )?;

    // -- setFocus --
    /// Sets keyboard focus to a widget or clears it.
    /// @param widget : table
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
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

    // -- getFocus --
    /// Returns the focused widget index or nil.
    /// @return number
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "getFocus",
        lua.create_function(move |_, ()| Ok(c.borrow().focused_widget))?,
    )?;

    // -- focusNext --
    /// Moves focus to the next focusable widget.
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "focusNext",
        lua.create_function(move |_, ()| {
            c.borrow_mut().focus_next();
            Ok(())
        })?,
    )?;

    // -- focusPrev --
    /// Moves focus to the previous focusable widget.
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "focusPrev",
        lua.create_function(move |_, ()| {
            c.borrow_mut().focus_prev();
            Ok(())
        })?,
    )?;

    // -- clearFocus --
    /// Clears keyboard focus.
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "clearFocus",
        lua.create_function(move |_, ()| {
            c.borrow_mut().set_focus(None);
            Ok(())
        })?,
    )?;

    // -- addToast --
    /// Queues a toast notification from a table.
    /// @param toast : table
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "addToast",
        lua.create_function(move |_, toast_table: LuaTable| {
            let msg: String = toast_table
                .get::<_, Option<String>>("message")?
                .or_else(|| toast_table.get::<_, Option<String>>(1).ok().flatten())
                .unwrap_or_default();
            let dur: f32 = toast_table
                .get::<_, Option<f32>>("duration")?
                .unwrap_or(3.0);
            c.borrow_mut().add_toast(Toast::new(msg, dur));
            Ok(())
        })?,
    )?;

    // -- getToastCount --
    /// Returns the number of active toasts.
    /// @return number
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "getToastCount",
        lua.create_function(move |_, ()| Ok(c.borrow().toast_count()))?,
    )?;

    // -- mousepressed --
    /// Forwards a mouse press event to the GUI.
    /// @param x : number
    /// @param y : number
    /// @param button : number
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "mousepressed",
        lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
            Ok(c.borrow_mut().mouse_pressed(x, y, btn.unwrap_or(1)))
        })?,
    )?;

    // -- mousereleased --
    /// Forwards a mouse release event to the GUI.
    /// @param x : number
    /// @param y : number
    /// @param button : number
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "mousereleased",
        lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
            Ok(c.borrow_mut().mouse_released(x, y, btn.unwrap_or(1)))
        })?,
    )?;

    // -- mousemoved --
    /// Forwards a mouse move event to the GUI.
    /// @param x : number
    /// @param y : number
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "mousemoved",
        lua.create_function(move |_, (x, y): (f32, f32)| Ok(c.borrow_mut().mouse_moved(x, y)))?,
    )?;

    // -- keypressed --
    /// Forwards a key press event to the GUI.
    /// @param key : string
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "keypressed",
        lua.create_function(move |_, key: String| Ok(c.borrow_mut().key_pressed(&key)))?,
    )?;

    // -- textinput --
    /// Forwards text input to the focused text input widget.
    /// @param text : string
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "textinput",
        lua.create_function(move |_, text: String| Ok(c.borrow_mut().text_input(&text)))?,
    )?;

    // -- wheelmoved --
    /// Forwards a mouse wheel event to the GUI.
    /// @param x : number
    /// @param y : number
    /// @return boolean
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "wheelmoved",
        lua.create_function(move |_, (x, y): (f32, f32)| Ok(c.borrow_mut().wheel_moved(x, y)))?,
    )?;

    // -- update --
    /// Advances toast timers, removes expired toasts, and dispatches pending GUI events.
    /// @param dt : number
    let c = ctx.clone();
    let cbs_update = callbacks.clone();
    /// @return nil
    tbl.set(
        "update",
        lua.create_function(move |lua, dt: f32| {
            c.borrow_mut().update(dt);
            let events = c.borrow_mut().drain_events();
            for ev in events {
                match ev {
                    GuiEvent::Click(widget_idx) => {
                        if let Some(key) = cbs_update.borrow().on_click.get(&widget_idx) {
                            let f: LuaFunction = lua.registry_value(key)?;
                            f.call::<_, ()>(widget_idx as u64)?;
                        }
                    }
                    GuiEvent::Change(widget_idx) => {
                        if let Some(key) = cbs_update.borrow().on_change.get(&widget_idx) {
                            let f: LuaFunction = lua.registry_value(key)?;
                            f.call::<_, ()>(widget_idx as u64)?;
                        }
                    }
                    GuiEvent::Close(widget_idx) => {
                        if let Some(key) = cbs_update.borrow().on_close.get(&widget_idx) {
                            let f: LuaFunction = lua.registry_value(key)?;
                            f.call::<_, ()>(widget_idx as u64)?;
                        }
                    }
                    GuiEvent::Select(widget_idx, item_idx) => {
                        if let Some(key) = cbs_update.borrow().on_select.get(&widget_idx) {
                            let f: LuaFunction = lua.registry_value(key)?;
                            f.call::<_, ()>((widget_idx as u64, item_idx as u64))?;
                        }
                    }
                }
            }
            Ok(())
        })?,
    )?;

    // -- getWidgetCount --
    /// Returns the total widget count in the context.
    /// @return number
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    /// @return nil
    tbl.set(
        "getWidgetCount",
        lua.create_function(move |_, ()| Ok(c.borrow().widget_count()))?,
    )?;

    luna.set("ui", tbl)?;
    Ok(())
}
