//! `lurek.ui` - Provides immediate-mode and retained-mode UI widgets including buttons, sliders, text inputs, panels, and layout containers.

use super::SharedState;
use crate::ui::containers::LayoutDirection;
use crate::ui::context::{GuiContext, GuiEvent, WidgetKind};
use crate::ui::extras::{AccordionSection, TableColumn, Toast};
use crate::ui::theme::{Theme, WidgetStyle};
use crate::ui::widget::{WidgetState, WidgetType};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
/// Internal callback registry that stores Lua function references for widget events.
#[derive(Default)]
struct GuiCallbacks {
    on_click: HashMap<usize, LuaRegistryKey>,
    on_change: HashMap<usize, LuaRegistryKey>,
    on_close: HashMap<usize, LuaRegistryKey>,
    on_select: HashMap<usize, LuaRegistryKey>,
    on_draw: HashMap<usize, LuaRegistryKey>,
}
/// Creates a Lua table representing a widget with all shared base methods common to every widget type.
fn create_widget_table<'a>(
    lua: &'a Lua,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
    type_name: &'static str,
) -> LuaResult<LuaTable<'a>> {
    let t = lua.create_table()?;
    /// Performs the '_idx' operation.
    t.set("_idx", idx)?;
    // -- type --
    /// Returns the type name string of this widget (e.g. "LButton", "LSlider").
    /// @param | self | LUiWidget | The widget instance.
    /// @return | string | The widget type name.
    t.set("type", lua.create_function(move |_, _self: LuaValue| Ok(type_name))?)?;
    // -- typeOf --
    /// Checks whether this widget matches the given type name, including base types "LWidget" and "Object".
    /// @param | self | LUiWidget | The widget instance.
    /// @param | name | string | The type name to check against.
    /// @return | boolean | True if the widget is of the given type.
    t.set(
        "typeOf",
        lua.create_function(move |_, (_self, name): (LuaValue, String)| {
            Ok(name == type_name || name == "LWidget" || name == "Object")
        })?,
    )?;
    let c = ctx.clone();
    // -- setPosition --
    /// Sets the local position of this widget relative to its parent.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | x | number | Horizontal position in pixels.
    /// @param | y | number | Vertical position in pixels.
    t.set(
        "setPosition",
        lua.create_function(move |_, (_self, x, y): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                let b = w.base_mut();
                b.x = x;
                b.y = y;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getPosition --
    /// Returns the local position of this widget relative to its parent.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number | The x and y coordinates in pixels.
    t.set(
        "getPosition",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                let b = w.base();
                Ok((b.x, b.y))
            } else {
                Ok((0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setSize --
    /// Sets the width and height of this widget in pixels.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | w | number | Width in pixels.
    /// @param | h | number | Height in pixels.
    t.set(
        "setSize",
        lua.create_function(move |_, (_self, w, h): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(wgt) = g.widgets.get_mut(idx) {
                let b = wgt.base_mut();
                b.width = w;
                b.height = h;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getSize --
    /// Returns the width and height of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number | The width and height in pixels.
    t.set(
        "getSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                let b = w.base();
                Ok((b.width, b.height))
            } else {
                Ok((0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- getRect --
    /// Returns the computed bounding rectangle of this widget in screen coordinates after layout.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number, number, number | The x, y, width, and height of the computed rect.
    t.set(
        "getRect",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                let r = &w.base().computed_rect;
                Ok((r.x, r.y, r.width, r.height))
            } else {
                Ok((0.0, 0.0, 0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setVisible --
    /// Shows or hides this widget. Hidden widgets are not drawn and do not receive input.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | v | boolean | True to show, false to hide.
    t.set(
        "setVisible",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().visible = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isVisible --
    /// Returns whether this widget is currently visible.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | boolean | True if the widget is visible.
    t.set(
        "isVisible",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).is_some_and(|w| w.base().visible))
        })?,
    )?;
    let c = ctx.clone();
    // -- setEnabled --
    /// Enables or disables this widget. Disabled widgets appear grayed out and ignore input.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | v | boolean | True to enable, false to disable.
    t.set(
        "setEnabled",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
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
    let c = ctx.clone();
    // -- isEnabled --
    /// Returns whether this widget is currently enabled and can receive input.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | boolean | True if the widget is enabled.
    t.set(
        "isEnabled",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).is_some_and(|w| w.base().enabled))
        })?,
    )?;
    let c = ctx.clone();
    // -- setId --
    /// Assigns a string identifier to this widget for lookup with findById.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | id | string | A unique identifier string.
    t.set(
        "setId",
        lua.create_function(move |_, (_self, id): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().id = id;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getId --
    /// Returns the string identifier assigned to this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | string | The widget ID, or an empty string if none was set.
    t.set(
        "getId",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .map_or(String::new(), |w| w.base().id.clone()))
        })?,
    )?;
    let c = ctx.clone();
    // -- setTooltip --
    /// Sets the tooltip text shown when the user hovers over this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | text | string | The tooltip message.
    t.set(
        "setTooltip",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().tooltip = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getTooltip --
    /// Returns the tooltip text of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | string | The tooltip text, or an empty string if none is set.
    t.set(
        "getTooltip",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .map_or(String::new(), |w| w.base().tooltip.clone()))
        })?,
    )?;
    let c = ctx.clone();
    // -- getState --
    /// Returns the current interaction state of this widget (e.g. "normal", "hovered", "pressed", "disabled").
    /// @param | self | LUiWidget | The widget instance.
    /// @return | string | The widget state name.
    t.set(
        "getState",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .map_or("normal", |w| w.base().state.as_str())
                .to_string())
        })?,
    )?;
    let c = ctx.clone();
    // -- addChild --
    /// Adds a child widget to this widget's hierarchy.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | child | LUiWidget|integer | The child widget table or widget index to add.
    t.set(
        "addChild",
        lua.create_function(move |_, (_self, child): (LuaValue, LuaValue)| {
            let child_idx = match child {
                LuaValue::Table(t) => t.get::<_, usize>("_idx")?,
                LuaValue::Integer(i) if i >= 0 => i as usize,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "addChild expects a widget table or widget index".into(),
                    ));
                }
            };
            let mut g = c.borrow_mut();
            g.add_child(idx, child_idx);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- removeChild --
    /// Removes a child widget from this widget's hierarchy.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | child | LUiWidget|integer | The child widget table or widget index to remove.
    t.set(
        "removeChild",
        lua.create_function(move |_, (_self, child): (LuaValue, LuaValue)| {
            let child_idx = match child {
                LuaValue::Table(t) => t.get::<_, usize>("_idx")?,
                LuaValue::Integer(i) if i >= 0 => i as usize,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "removeChild expects a widget table or widget index".into(),
                    ));
                }
            };
            let mut g = c.borrow_mut();
            g.remove_child(idx, child_idx);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getChildCount --
    /// Returns the number of direct child widgets attached to this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | integer | The child count.
    t.set(
        "getChildCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.child_count(idx))
        })?,
    )?;
    let c = ctx.clone();
    // -- getChildren --
    /// Returns a table of lightweight child widget references, each containing an _idx field.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | table | Array of child widget tables.
    /// @field | _idx | integer | Widget index.
    t.set(
        "getChildren",
        lua.create_function(move |lua, _self: LuaValue| {
            let child_indices = {
                let g = c.borrow();
                g.widgets
                    .get(idx)
                    .and_then(|w| w.children())
                    .cloned()
                    .unwrap_or_default()
            };
            let out = lua.create_table()?;
            for (list_index, child_idx) in child_indices.into_iter().enumerate() {
                let child = lua.create_table()?;
                /// Performs the '_idx' operation.
                child.set("_idx", child_idx)?;
                out.set(list_index + 1, child)?;
            }
            Ok(out)
        })?,
    )?;
    let c = ctx.clone();
    // -- findById --
    /// Searches this widget's subtree for a child with the given ID.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | id | string | The widget ID to search for.
    /// @return | LWidget | The found widget table, or nil if not found.
    t.set(
        "findById",
        lua.create_function(move |lua, (_self, id): (LuaValue, String)| {
            let g = c.borrow();
            match g.find_by_id(idx, &id) {
                Some(found_idx) => {
                    let ft = lua.create_table()?;
                    /// Performs the '_idx' operation.
                    ft.set("_idx", found_idx)?;
                    Ok(LuaValue::Table(ft))
                }
                None => Ok(LuaValue::Nil),
            }
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnClick --
    /// Registers a callback function invoked when this widget is clicked.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | f | function | Callback receiving the widget index as argument.
    t.set(
        "setOnClick",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_click.insert(idx, key);
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnChange --
    /// Registers a callback function invoked when this widget's value changes.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | f | function | Callback receiving the widget index as argument.
    t.set(
        "setOnChange",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnDraw --
    /// Registers a custom draw callback for this widget, invoked each frame during the draw pass.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | f | function | Callback receiving a rect table {x, y, w, h} with the computed bounds.
    t.set(
        "setOnDraw",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_draw.insert(idx, key);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- containsPoint --
    /// Tests whether the given screen-space point is inside this widget's bounds.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | x | number | X coordinate in screen pixels.
    /// @param | y | number | Y coordinate in screen pixels.
    /// @return | boolean | True if the point is within the widget.
    t.set(
        "containsPoint",
        lua.create_function(move |_, (_self, x, y): (LuaValue, f32, f32)| {
            let g = c.borrow();
            Ok(g.widgets
                .get(idx)
                .is_some_and(|w| w.base().contains_point(x, y)))
        })?,
    )?;
    let c = ctx.clone();
    // -- setPadding --
    /// Sets the inner padding of this widget. Accepts 1 to 4 values (top, right?, bottom?, left?) following CSS shorthand rules.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | top | number | Top padding in pixels (also used as default for other sides).
    /// @param | right | number? | Right padding. Defaults to top.
    /// @param | bottom | number? | Bottom padding. Defaults to top.
    /// @param | left | number? | Left padding. Defaults to right.
    t.set(
        "setPadding",
        lua.create_function(
            move |_, (_self, top, right, bottom, left): (LuaValue, f32, Option<f32>, Option<f32>, Option<f32>)| {
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
    let c = ctx.clone();
    // -- getPadding --
    /// Returns the inner padding of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number, number, number | Top, right, bottom, and left padding in pixels.
    t.set(
        "getPadding",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                let p = w.base().padding;
                Ok((p[0], p[1], p[2], p[3]))
            } else {
                Ok((0.0, 0.0, 0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setMargin --
    /// Sets the outer margin of this widget. Accepts 1 to 4 values (top, right?, bottom?, left?) following CSS shorthand rules.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | top | number | Top margin in pixels (also used as default for other sides).
    /// @param | right | number? | Right margin. Defaults to top.
    /// @param | bottom | number? | Bottom margin. Defaults to top.
    /// @param | left | number? | Left margin. Defaults to right.
    t.set(
        "setMargin",
        lua.create_function(
            move |_, (_self, top, right, bottom, left): (LuaValue, f32, Option<f32>, Option<f32>, Option<f32>)| {
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
    let c = ctx.clone();
    // -- getMargin --
    /// Returns the outer margin of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number, number, number | Top, right, bottom, and left margin in pixels.
    t.set(
        "getMargin",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                let m = w.base().margin;
                Ok((m[0], m[1], m[2], m[3]))
            } else {
                Ok((0.0, 0.0, 0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setZOrder --
    /// Sets the z-order (draw priority) of this widget. Higher values draw on top.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | z | integer | The z-order integer value.
    t.set(
        "setZOrder",
        lua.create_function(move |_, (_self, z): (LuaValue, i32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().z_order = z;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getZOrder --
    /// Returns the z-order (draw priority) of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | integer | The z-order value.
    t.set(
        "getZOrder",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0, |w| w.base().z_order))
        })?,
    )?;
    let c = ctx.clone();
    // -- setMinSize --
    /// Sets the minimum allowed width and height for this widget during layout.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | w | number | Minimum width in pixels.
    /// @param | h | number | Minimum height in pixels.
    t.set(
        "setMinSize",
        lua.create_function(move |_, (_self, w, h): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(wgt) = g.widgets.get_mut(idx) {
                let b = wgt.base_mut();
                b.min_width = w;
                b.min_height = h;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getMinSize --
    /// Returns the minimum width and height of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number | Minimum width and height in pixels.
    t.set(
        "getMinSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                Ok((w.base().min_width, w.base().min_height))
            } else {
                Ok((0.0, 0.0))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setMaxSize --
    /// Sets the maximum allowed width and height for this widget during layout.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | w | number | Maximum width in pixels.
    /// @param | h | number | Maximum height in pixels.
    t.set(
        "setMaxSize",
        lua.create_function(move |_, (_self, w, h): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(wgt) = g.widgets.get_mut(idx) {
                let b = wgt.base_mut();
                b.max_width = w;
                b.max_height = h;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getMaxSize --
    /// Returns the maximum width and height of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number, number | Maximum width and height in pixels.
    t.set(
        "getMaxSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(w) = g.widgets.get(idx) {
                Ok((w.base().max_width, w.base().max_height))
            } else {
                Ok((f32::INFINITY, f32::INFINITY))
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- setAnchor --
    /// Anchors this widget to its parent's edges. Pass nil for any side to leave it unanchored.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | left | number? | Distance from parent's left edge, or nil.
    /// @param | top | number? | Distance from parent's top edge, or nil.
    /// @param | right | number? | Distance from parent's right edge, or nil.
    /// @param | bottom | number? | Distance from parent's bottom edge, or nil.
    t.set(
        "setAnchor",
        lua.create_function(
            move |_,
                  (_self, left, top, right, bottom): (LuaValue,
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
    let c = ctx.clone();
    // -- setAnchorCenter --
    /// Centers this widget within its parent using proportional anchor offsets (0.0 to 1.0).
    /// @param | self | LUiWidget | The widget instance.
    /// @param | cx | number? | Horizontal center fraction (0.5 = centered).
    /// @param | cy | number? | Vertical center fraction (0.5 = centered).
    t.set(
        "setAnchorCenter",
        lua.create_function(move |_, (_self, cx, cy): (LuaValue, Option<f32>, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                let b = w.base_mut();
                b.anchor_center_x = cx;
                b.anchor_center_y = cy;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- clearAnchor --
    /// Removes all anchor constraints from this widget.
    /// @param | self | LUiWidget | The widget instance.
    t.set(
        "clearAnchor",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().clear_anchors();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setFlexGrow --
    /// Sets the flex-grow factor controlling how much extra space this widget receives in a layout.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | grow | number | The grow factor (0 = no growth).
    t.set(
        "setFlexGrow",
        lua.create_function(move |_, (_self, grow): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().flex_grow = grow;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getFlexGrow --
    /// Returns the flex-grow factor of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number | The grow factor.
    t.set(
        "getFlexGrow",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_grow))
        })?,
    )?;
    let c = ctx.clone();
    // -- setFlexShrink --
    /// Sets the flex-shrink factor controlling how much this widget shrinks when layout space is insufficient.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | shrink | number | The shrink factor (0 = no shrinkage).
    t.set(
        "setFlexShrink",
        lua.create_function(move |_, (_self, shrink): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().flex_shrink = shrink;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getFlexShrink --
    /// Returns the flex-shrink factor of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number | The shrink factor.
    t.set(
        "getFlexShrink",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(0.0, |w| w.base().flex_shrink))
        })?,
    )?;
    let c = ctx.clone();
    // -- bind --
    /// Binds this widget to a data key for use with update_bindings.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | key | string | The binding key name.
    t.set(
        "bind",
        lua.create_function(move |_, (_self, key): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().bind_key = Some(key);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- unbind --
    /// Removes the data binding from this widget.
    /// @param | self | LUiWidget | The widget instance.
    t.set(
        "unbind",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().bind_key = None;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setAlpha --
    /// Sets the opacity of this widget, clamped to 0.0 (fully transparent) through 1.0 (fully opaque).
    /// @param | self | LUiWidget | The widget instance.
    /// @param | alpha | number | The opacity value.
    t.set(
        "setAlpha",
        lua.create_function(move |_, (_self, alpha): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().alpha = alpha.clamp(0.0, 1.0);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getAlpha --
    /// Returns the current opacity of this widget.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | number | The alpha value between 0.0 and 1.0.
    t.set(
        "getAlpha",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(g.widgets.get(idx).map_or(1.0, |w| w.base().alpha))
        })?,
    )?;
    let c = ctx.clone();
    // -- fadeIn --
    /// Instantly makes this widget fully opaque and visible.
    /// @param | self | LUiWidget | The widget instance.
    t.set(
        "fadeIn",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().alpha = 1.0;
                w.base_mut().visible = true;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- fadeOut --
    /// Instantly makes this widget fully transparent and hidden.
    /// @param | self | LUiWidget | The widget instance.
    t.set(
        "fadeOut",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().alpha = 0.0;
                w.base_mut().visible = false;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- slideIn --
    /// Moves this widget to the given position and makes it visible.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | x | number | Target x position.
    /// @param | y | number | Target y position.
    t.set(
        "slideIn",
        lua.create_function(move |_, (_self, x, y): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().x = x;
                w.base_mut().y = y;
                w.base_mut().visible = true;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- slideOut --
    /// Moves this widget to the given position and hides it.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | x | number | Target x position.
    /// @param | y | number | Target y position.
    t.set(
        "slideOut",
        lua.create_function(move |_, (_self, x, y): (LuaValue, f32, f32)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().x = x;
                w.base_mut().y = y;
                w.base_mut().visible = false;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- animateAlpha --
    /// Smoothly animates this widget's opacity toward a target value over the given duration.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | target | number | Target alpha value (0.0 to 1.0).
    /// @param | duration | number? | Animation duration in seconds. Defaults to 0.2.
    /// @param | hide_on_complete | boolean? | If true, hides the widget when alpha reaches 0.
    /// @return | table | Table result returned by this call.
    t.set(
        "animateAlpha",
        lua.create_function(
            move |_, (_self, target, duration, hide_on_complete): (LuaValue, f32, Option<f32>, Option<bool>)| {
                Ok(c.borrow_mut().animate_alpha(
                    idx,
                    target,
                    duration.unwrap_or(0.2),
                    hide_on_complete.unwrap_or(false),
                ))
            },
        )?,
    )?;
    let c = ctx.clone();
    // -- animatePosition --
    /// Smoothly animates this widget's position toward the target coordinates.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | x | number | Target x position.
    /// @param | y | number | Target y position.
    /// @param | duration | number? | Animation duration in seconds. Defaults to 0.2.
    /// @return | table | Table result returned by this call.
    t.set(
        "animatePosition",
        lua.create_function(move |_, (_self, x, y, duration): (LuaValue, f32, f32, Option<f32>)| {
            Ok(c.borrow_mut()
                .animate_position(idx, x, y, duration.unwrap_or(0.2)))
        })?,
    )?;
    let c = ctx.clone();
    // -- isAnimating --
    /// Returns whether this widget currently has an active animation.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | boolean | True if an animation is in progress.
    t.set(
        "isAnimating",
        lua.create_function(move |_, _self: LuaValue| Ok(c.borrow().is_animating(idx)))?,
    )?;
    let c = ctx.clone();
    // -- cancelAnimations --
    /// Cancels all active animations on this widget, leaving it at its current state.
    /// @param | self | LUiWidget | The widget instance.
    /// @return | boolean | True if any animations were cancelled.
    t.set(
        "cancelAnimations",
        lua.create_function(move |_, _self: LuaValue| Ok(c.borrow_mut().cancel_animations(idx)))?,
    )?;
    let c = ctx.clone();
    // -- attachToEntity --
    /// Attaches this widget to a game entity so it follows the entity's position on screen.
    /// @param | self | LUiWidget | The widget instance.
    /// @param | entity_id | integer | The entity ID to attach to.
    t.set(
        "attachToEntity",
        lua.create_function(move |_, (_self, entity_id): (LuaValue, u64)| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().entity_attachment = Some(entity_id);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- detachFromEntity --
    /// Detaches this widget from any previously attached entity.
    /// @param | self | LUiWidget | The widget instance.
    t.set(
        "detachFromEntity",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(w) = g.widgets.get_mut(idx) {
                w.base_mut().entity_attachment = None;
            }
            Ok(())
        })?,
    )?;
    Ok(t)
}
/// Adds button-specific methods (setText, getText) to a button widget table.
fn add_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setText --
    /// Sets the display text on this button.
    /// @param | self | LButton | The widget instance.
    /// @param | text | string | The button label text.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Button(btn)) = g.widgets.get_mut(idx) {
                btn.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getText --
    /// Returns the current display text of this button.
    /// @param | self | LButton | The widget instance.
    /// @return | string | The button label.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Button(btn)) => btn.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    Ok(())
}
/// Adds label-specific methods (setText, getText) to a label widget table.
fn add_label_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setText --
    /// Sets the display text on this label.
    /// @param | self | LLabel | The widget instance.
    /// @param | text | string | The label text.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Label(lbl)) = g.widgets.get_mut(idx) {
                lbl.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getText --
    /// Returns the current display text of this label.
    /// @param | self | LLabel | The widget instance.
    /// @return | string | The label text.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Label(lbl)) => lbl.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    Ok(())
}
/// Adds text-input-specific methods to a text input widget table.
fn add_text_input_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setText --
    /// Sets the text content of this text input field and moves the cursor to the end.
    /// @param | self | LTextInput | The widget instance.
    /// @param | text | string | The text to set.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                ti.cursor_pos = text.len();
                ti.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getText --
    /// Returns the current text content of this text input field.
    /// @param | self | LTextInput | The widget instance.
    /// @return | string | The input text.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TextInput(ti)) => ti.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setPlaceholder --
    /// Sets the placeholder text shown when the input is empty.
    /// @param | self | LTextInput | The widget instance.
    /// @param | text | string | The placeholder text.
    t.set(
        "setPlaceholder",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                ti.placeholder = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getPlaceholder --
    /// Returns the placeholder text of this text input.
    /// @param | self | LTextInput | The widget instance.
    /// @return | string | The placeholder text.
    t.set(
        "getPlaceholder",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TextInput(ti)) => ti.placeholder.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setMaxLength --
    /// Sets the maximum number of characters allowed in this text input.
    /// @param | self | LTextInput | The widget instance.
    /// @param | n | integer | Maximum character count.
    t.set(
        "setMaxLength",
        lua.create_function(move |_, (_self, n): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TextInput(ti)) = g.widgets.get_mut(idx) {
                ti.max_length = n;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isFocused --
    /// Returns whether this text input currently has keyboard focus.
    /// @param | self | LTextInput | The widget instance.
    /// @return | boolean | True if focused.
    t.set(
        "isFocused",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TextInput(ti)) => ti.focused,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getCursorPosition --
    /// Returns the current cursor position (character index) within the text input.
    /// @param | self | LTextInput | The widget instance.
    /// @return | integer | The zero-based cursor position.
    t.set(
        "getCursorPosition",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TextInput(ti)) => ti.cursor_pos,
                _ => 0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds checkbox-specific methods to a checkbox widget table.
fn add_checkbox_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setChecked --
    /// Sets the checked state of this checkbox.
    /// @param | self | LCheckbox | The widget instance.
    /// @param | checked | boolean | True to check, false to uncheck.
    t.set(
        "setChecked",
        lua.create_function(move |_, (_self, checked): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::CheckBox(cb)) = g.widgets.get_mut(idx) {
                cb.checked = checked;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isChecked --
    /// Returns whether this checkbox is currently checked.
    /// @param | self | LCheckbox | The widget instance.
    /// @return | boolean | True if checked.
    t.set(
        "isChecked",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::CheckBox(cb)) => cb.checked,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setText --
    /// Sets the label text displayed next to this checkbox.
    /// @param | self | LCheckbox | The widget instance.
    /// @param | text | string | The checkbox label.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::CheckBox(cb)) = g.widgets.get_mut(idx) {
                cb.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getText --
    /// Returns the label text of this checkbox.
    /// @param | self | LCheckbox | The widget instance.
    /// @return | string | The checkbox label.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::CheckBox(cb)) => cb.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    Ok(())
}
/// Adds slider-specific methods to a slider widget table.
fn add_slider_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setValue --
    /// Sets the current value of this slider, clamped to its range.
    /// @param | self | LSlider | The widget instance.
    /// @param | v | number | The value to set.
    t.set(
        "setValue",
        lua.create_function(move |_, (_self, v): (LuaValue, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Slider(sl)) = g.widgets.get_mut(idx) {
                sl.set_value(v);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getValue --
    /// Returns the current value of this slider.
    /// @param | self | LSlider | The widget instance.
    /// @return | number | The slider value.
    t.set(
        "getValue",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Slider(sl)) => sl.value,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setRange --
    /// Sets the minimum and maximum bounds for this slider.
    /// @param | self | LSlider | The widget instance.
    /// @param | min | number | Minimum value.
    /// @param | max | number | Maximum value.
    t.set(
        "setRange",
        lua.create_function(move |_, (_self, min, max): (LuaValue, f64, f64)| {
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
    // -- setStep --
    /// Sets the step increment for this slider's value snapping.
    /// @param | self | LSlider | The widget instance.
    /// @param | step | number | The step size.
    t.set(
        "setStep",
        lua.create_function(move |_, (_self, step): (LuaValue, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Slider(sl)) = g.widgets.get_mut(idx) {
                sl.step = step;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getMin --
    /// Returns the minimum value of this slider's range.
    /// @param | self | LSlider | The widget instance.
    /// @return | number | The minimum value.
    t.set(
        "getMin",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Slider(sl)) => sl.min,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getMax --
    /// Returns the maximum value of this slider's range.
    /// @param | self | LSlider | The widget instance.
    /// @return | number | The maximum value.
    t.set(
        "getMax",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Slider(sl)) => sl.max,
                _ => 1.0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds progress-bar-specific methods to a progress bar widget table.
fn add_progress_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setValue --
    /// Sets the current fill value of this progress bar, clamped to its range.
    /// @param | self | LProgressBar | The widget instance.
    /// @param | v | number | The progress value.
    t.set(
        "setValue",
        lua.create_function(move |_, (_self, v): (LuaValue, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ProgressBar(pb)) = g.widgets.get_mut(idx) {
                pb.value = v.clamp(pb.min, pb.max);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getValue --
    /// Returns the current value of this progress bar.
    /// @param | self | LProgressBar | The widget instance.
    /// @return | number | The progress value.
    t.set(
        "getValue",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ProgressBar(pb)) => pb.value,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getProgress --
    /// Returns the normalized progress as a fraction (0.0 to 1.0) of the current range.
    /// @param | self | LProgressBar | The widget instance.
    /// @return | number | The normalized progress.
    t.set(
        "getProgress",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ProgressBar(pb)) => pb.progress(),
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setRange --
    /// Sets the minimum and maximum bounds for this progress bar.
    /// @param | self | LProgressBar | The widget instance.
    /// @param | min | number | Minimum value.
    /// @param | max | number | Maximum value.
    t.set(
        "setRange",
        lua.create_function(move |_, (_self, min, max): (LuaValue, f64, f64)| {
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
    // -- getMin --
    /// Returns the minimum value of this progress bar's range.
    /// @param | self | LProgressBar | The widget instance.
    /// @return | number | The minimum value.
    t.set(
        "getMin",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ProgressBar(pb)) => pb.min,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getMax --
    /// Returns the maximum value of this progress bar's range.
    /// @param | self | LProgressBar | The widget instance.
    /// @return | number | The maximum value.
    t.set(
        "getMax",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ProgressBar(pb)) => pb.max,
                _ => 1.0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds combo-box-specific methods to a combo box widget table.
fn add_combo_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addItem --
    /// Appends a new text item to this combo box's dropdown list.
    /// @param | self | LComboBox | The widget instance.
    /// @param | text | string | The item label to add.
    t.set(
        "addItem",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                cb.add_item(text);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- removeItem --
    /// Removes the item at the given 1-based index from this combo box.
    /// @param | self | LComboBox | The widget instance.
    /// @param | index | integer | The 1-based index of the item to remove.
    /// @return | boolean | True if the item was removed.
    t.set(
        "removeItem",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- clearItems --
    /// Removes all items from this combo box.
    /// @param | self | LComboBox | The widget instance.
    t.set(
        "clearItems",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ComboBox(cb)) = g.widgets.get_mut(idx) {
                cb.clear();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getItemCount --
    /// Returns the number of items in this combo box.
    /// @param | self | LComboBox | The widget instance.
    /// @return | integer | The item count.
    t.set(
        "getItemCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ComboBox(cb)) => cb.items.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getItem --
    /// Returns the text of the item at the given 1-based index.
    /// @param | self | LComboBox | The widget instance.
    /// @param | index | integer | The 1-based item index.
    /// @return | string | The item text, or nil if out of range.
    t.set(
        "getItem",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- setSelectedIndex --
    /// Sets the selected item by 1-based index.
    /// @param | self | LComboBox | The widget instance.
    /// @param | index | integer | The 1-based index of the item to select.
    t.set(
        "setSelectedIndex",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getSelectedIndex --
    /// Returns the 1-based index of the currently selected item, or 0 if none is selected.
    /// @param | self | LComboBox | The widget instance.
    /// @return | integer | The selected index.
    t.set(
        "getSelectedIndex",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ComboBox(cb)) => cb.selected_index.map_or(0, |i| i + 1),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getSelectedItem --
    /// Returns the text of the currently selected item, or nil if none is selected.
    /// @param | self | LComboBox | The widget instance.
    /// @return | string | The selected item text.
    t.set(
        "getSelectedItem",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ComboBox(cb)) => cb.selected_item().map(|s| s.to_string()),
                _ => None,
            })
        })?,
    )?;
    Ok(())
}
/// Adds list-box-specific methods to a list box widget table.
fn add_list_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addItem --
    /// Appends a new text item to this list box.
    /// @param | self | LListBox | The widget instance.
    /// @param | text | string | The item text to add.
    t.set(
        "addItem",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                lb.add_item(text);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- removeItem --
    /// Removes the item at the given 1-based index from this list box.
    /// @param | self | LListBox | The widget instance.
    /// @param | index | integer | The 1-based index to remove.
    t.set(
        "removeItem",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- clearItems --
    /// Removes all items from this list box.
    /// @param | self | LListBox | The widget instance.
    t.set(
        "clearItems",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                lb.clear();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getItemCount --
    /// Returns the number of items in this list box.
    /// @param | self | LListBox | The widget instance.
    /// @return | integer | The item count.
    t.set(
        "getItemCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ListBox(lb)) => lb.items.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getItem --
    /// Returns the text of the item at the given 1-based index.
    /// @param | self | LListBox | The widget instance.
    /// @param | index | integer | The 1-based item index.
    /// @return | string | The item text, or empty string if out of range.
    t.set(
        "getItem",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- setSelectedIndex --
    /// Sets the selected item by 1-based index.
    /// @param | self | LListBox | The widget instance.
    /// @param | index | integer | The 1-based index of the item to select.
    t.set(
        "setSelectedIndex",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getSelectedIndex --
    /// Returns the 1-based index of the currently selected item, or 0 if none.
    /// @param | self | LListBox | The widget instance.
    /// @return | integer | The selected index.
    t.set(
        "getSelectedIndex",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ListBox(lb)) => lb.selected_index.map_or(0, |i| i + 1),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setItemHeight --
    /// Sets the pixel height of each item row in this list box.
    /// @param | self | LListBox | The widget instance.
    /// @param | h | number | Row height in pixels.
    t.set(
        "setItemHeight",
        lua.create_function(move |_, (_self, h): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ListBox(lb)) = g.widgets.get_mut(idx) {
                lb.item_height = h;
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds tab-bar-specific methods to a tab bar widget table.
fn add_tab_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addTab --
    /// Adds a new tab with the given label to this tab bar.
    /// @param | self | LTabBar | The widget instance.
    /// @param | label | string | The tab label text.
    t.set(
        "addTab",
        lua.create_function(move |_, (_self, label): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TabBar(tb)) = g.widgets.get_mut(idx) {
                tb.add_tab(label);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- removeTab --
    /// Removes the tab at the given 1-based index.
    /// @param | self | LTabBar | The widget instance.
    /// @param | index | integer | The 1-based tab index.
    /// @return | boolean | True if the tab was removed.
    t.set(
        "removeTab",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getTab --
    /// Returns the label of the tab at the given 1-based index.
    /// @param | self | LTabBar | The widget instance.
    /// @param | index | integer | The 1-based tab index.
    /// @return | string | The tab label, or nil if out of range.
    t.set(
        "getTab",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getTabCount --
    /// Returns the total number of tabs in this tab bar.
    /// @param | self | LTabBar | The widget instance.
    /// @return | integer | The tab count.
    t.set(
        "getTabCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TabBar(tb)) => tb.tabs.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setActiveTab --
    /// Sets the active (selected) tab by 1-based index.
    /// @param | self | LTabBar | The widget instance.
    /// @param | index | integer | The 1-based tab index to activate.
    t.set(
        "setActiveTab",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getActiveTab --
    /// Returns the 1-based index of the currently active tab.
    /// @param | self | LTabBar | The widget instance.
    /// @return | integer | The active tab index.
    t.set(
        "getActiveTab",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TabBar(tb)) => tb.active_tab + 1,
                _ => 0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds spin-box-specific methods to a spin box widget table.
fn add_spin_box_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setValue --
    /// Sets the numeric value of this spin box, clamped to its range.
    /// @param | self | LSpinBox | The widget instance.
    /// @param | v | number | The value to set.
    t.set(
        "setValue",
        lua.create_function(move |_, (_self, v): (LuaValue, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SpinBox(sb)) = g.widgets.get_mut(idx) {
                sb.set_value(v);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getValue --
    /// Returns the current numeric value of this spin box.
    /// @param | self | LSpinBox | The widget instance.
    /// @return | number | The spin box value.
    t.set(
        "getValue",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SpinBox(sb)) => sb.value,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- increment --
    /// Increases this spin box's value by one step.
    /// @param | self | LSpinBox | The widget instance.
    t.set(
        "increment",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SpinBox(sb)) = g.widgets.get_mut(idx) {
                sb.increment();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- decrement --
    /// Decreases this spin box's value by one step.
    /// @param | self | LSpinBox | The widget instance.
    t.set(
        "decrement",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SpinBox(sb)) = g.widgets.get_mut(idx) {
                sb.decrement();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setRange --
    /// Sets the minimum and maximum bounds for this spin box.
    /// @param | self | LSpinBox | The widget instance.
    /// @param | min | number | Minimum value.
    /// @param | max | number | Maximum value.
    t.set(
        "setRange",
        lua.create_function(move |_, (_self, min, max): (LuaValue, f64, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SpinBox(sb)) = g.widgets.get_mut(idx) {
                sb.set_range(min, max);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setStep --
    /// Sets the step increment for this spin box.
    /// @param | self | LSpinBox | The widget instance.
    /// @param | step | number | The step size (minimum 1e-9).
    t.set(
        "setStep",
        lua.create_function(move |_, (_self, step): (LuaValue, f64)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SpinBox(sb)) = g.widgets.get_mut(idx) {
                sb.step = step.max(1e-9);
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds switch-specific methods (setOn, isOn, toggle) to a switch widget table.
fn add_switch_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setOn --
    /// Sets the on/off state of this toggle switch.
    /// @param | self | LSwitch | The widget instance.
    /// @param | on | boolean | True to turn on, false to turn off.
    t.set(
        "setOn",
        lua.create_function(move |_, (_self, on): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Switch(sw)) = g.widgets.get_mut(idx) {
                sw.set_on(on);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isOn --
    /// Returns whether this switch is currently in the on state.
    /// @param | self | LSwitch | The widget instance.
    /// @return | boolean | True if the switch is on.
    t.set(
        "isOn",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Switch(sw)) => sw.on,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- toggle --
    /// Toggles this switch between on and off states.
    /// @param | self | LSwitch | The widget instance.
    t.set(
        "toggle",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Switch(sw)) = g.widgets.get_mut(idx) {
                sw.toggle();
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds badge-specific methods to a notification badge widget table.
fn add_badge_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setCount --
    /// Sets the notification count displayed by this badge.
    /// @param | self | LBadge | The widget instance.
    /// @param | count | integer | The notification count.
    t.set(
        "setCount",
        lua.create_function(move |_, (_self, count): (LuaValue, u32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Badge(b)) = g.widgets.get_mut(idx) {
                b.set_count(count);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getCount --
    /// Returns the current notification count of this badge.
    /// @param | self | LBadge | The widget instance.
    /// @return | integer | The badge count.
    t.set(
        "getCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Badge(b)) => b.count,
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getDisplayText --
    /// Returns the formatted display text of this badge (e.g. "99+" when count exceeds the maximum).
    /// @param | self | LBadge | The widget instance.
    /// @return | string | The display text.
    t.set(
        "getDisplayText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Badge(b)) => b.display_text(),
                _ => String::new(),
            })
        })?,
    )?;
    Ok(())
}
/// Adds panel-specific methods (setTitle, getTitle, setScrollable) to a panel widget table.
fn add_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setTitle --
    /// Sets the title text displayed on this panel's header.
    /// @param | self | LPanel | The widget instance.
    /// @param | title | string | The panel title.
    t.set(
        "setTitle",
        lua.create_function(move |_, (_self, title): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Panel(p)) = g.widgets.get_mut(idx) {
                p.title = title;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getTitle --
    /// Returns the title text of this panel.
    /// @param | self | LPanel | The widget instance.
    /// @return | string | The panel title.
    t.set(
        "getTitle",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Panel(p)) => p.title.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setScrollable --
    /// Enables or disables scrolling within this panel.
    /// @param | self | LPanel | The widget instance.
    /// @param | scrollable | boolean | True to enable scrolling.
    t.set(
        "setScrollable",
        lua.create_function(move |_, (_self, scrollable): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Panel(p)) = g.widgets.get_mut(idx) {
                p.scrollable = scrollable;
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds layout-specific methods to a layout container widget table.
fn add_layout_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setDirection --
    /// Sets the layout direction for child arrangement ("horizontal", "vertical", or "grid").
    /// @param | self | LLayout | The widget instance.
    /// @param | dir | string | The layout direction.
    t.set(
        "setDirection",
        lua.create_function(move |_, (_self, dir): (LuaValue, String)| {
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
    // -- getDirection --
    /// Returns the current layout direction.
    /// @param | self | LLayout | The widget instance.
    /// @return | string | The direction name.
    t.set(
        "getDirection",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.direction.as_str().to_string(),
                _ => "vertical".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSpacing --
    /// Sets the spacing in pixels between child widgets in this layout.
    /// @param | self | LLayout | The widget instance.
    /// @param | spacing | number | Gap between children in pixels.
    t.set(
        "setSpacing",
        lua.create_function(move |_, (_self, spacing): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.spacing = spacing;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getSpacing --
    /// Returns the current spacing between children.
    /// @param | self | LLayout | The widget instance.
    /// @return | number | The spacing in pixels.
    t.set(
        "getSpacing",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.spacing,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setColumns --
    /// Sets the number of columns for grid layout mode (minimum 1).
    /// @param | self | LLayout | The widget instance.
    /// @param | n | integer | Column count.
    t.set(
        "setColumns",
        lua.create_function(move |_, (_self, n): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.columns = n.max(1);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setWrap --
    /// Enables or disables wrapping of children to the next row/column when they overflow.
    /// @param | self | LLayout | The widget instance.
    /// @param | wrap | boolean | True to enable wrapping.
    t.set(
        "setWrap",
        lua.create_function(move |_, (_self, wrap): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.wrap = wrap;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getWrap --
    /// Returns whether wrapping is enabled for this layout.
    /// @param | self | LLayout | The widget instance.
    /// @return | boolean | True if wrapping is on.
    t.set(
        "getWrap",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.wrap,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setAlign --
    /// Sets the cross-axis alignment for children (e.g. "start", "center", "end", "stretch").
    /// @param | self | LLayout | The widget instance.
    /// @param | align | string | The alignment mode.
    t.set(
        "setAlign",
        lua.create_function(move |_, (_self, align): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.align = align;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getAlign --
    /// Returns the current cross-axis alignment mode.
    /// @param | self | LLayout | The widget instance.
    /// @return | string | The alignment mode.
    t.set(
        "getAlign",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.align.clone(),
                _ => "start".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setJustify --
    /// Sets the main-axis justification for children (e.g. "start", "center", "end", "space-between").
    /// @param | self | LLayout | The widget instance.
    /// @param | justify | string | The justification mode.
    t.set(
        "setJustify",
        lua.create_function(move |_, (_self, justify): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Layout(l)) = g.widgets.get_mut(idx) {
                l.justify = justify;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getJustify --
    /// Returns the current main-axis justification mode.
    /// @param | self | LLayout | The widget instance.
    /// @return | string | The justification mode.
    t.set(
        "getJustify",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Layout(l)) => l.justify.clone(),
                _ => "start".to_string(),
            })
        })?,
    )?;
    Ok(())
}
/// Adds scroll-panel-specific methods to a scroll panel widget table.
fn add_scroll_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setContentSize --
    /// Sets the virtual content dimensions of this scroll panel.
    /// @param | self | LScrollPanel | The widget instance.
    /// @param | w | number | Content width in pixels.
    /// @param | h | number | Content height in pixels.
    t.set(
        "setContentSize",
        lua.create_function(move |_, (_self, w, h): (LuaValue, f32, f32)| {
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
    // -- getContentSize --
    /// Returns the virtual content dimensions of this scroll panel.
    /// @param | self | LScrollPanel | The widget instance.
    /// @return | number, number | Content width and height in pixels.
    t.set(
        "getContentSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollPanel(sp)) => (sp.content_width, sp.content_height),
                _ => (0.0, 0.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setScrollPosition --
    /// Sets the scroll offset position of this scroll panel.
    /// @param | self | LScrollPanel | The widget instance.
    /// @param | x | number | Horizontal scroll offset.
    /// @param | y | number | Vertical scroll offset.
    t.set(
        "setScrollPosition",
        lua.create_function(move |_, (_self, x, y): (LuaValue, f32, f32)| {
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
    // -- getScrollPosition --
    /// Returns the current scroll offset of this scroll panel.
    /// @param | self | LScrollPanel | The widget instance.
    /// @return | number, number | Horizontal and vertical scroll offsets.
    t.set(
        "getScrollPosition",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollPanel(sp)) => (sp.scroll_x, sp.scroll_y),
                _ => (0.0, 0.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getMaxScroll --
    /// Returns the maximum scroll offset allowed in each axis.
    /// @param | self | LScrollPanel | The widget instance.
    /// @return | number, number | Maximum horizontal and vertical scroll values.
    t.set(
        "getMaxScroll",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollPanel(sp)) => sp.max_scroll(),
                _ => (0.0, 0.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setScrollSpeed --
    /// Sets the scroll speed multiplier for mouse wheel scrolling.
    /// @param | self | LScrollPanel | The widget instance.
    /// @param | speed | number | Scroll speed in pixels per scroll tick.
    t.set(
        "setScrollSpeed",
        lua.create_function(move |_, (_self, speed): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ScrollPanel(sp)) = g.widgets.get_mut(idx) {
                sp.scroll_speed = speed;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getScrollSpeed --
    /// Returns the current scroll speed multiplier.
    /// @param | self | LScrollPanel | The widget instance.
    /// @return | number | The scroll speed.
    t.set(
        "getScrollSpeed",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollPanel(sp)) => sp.scroll_speed,
                _ => 20.0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds nine-patch-specific methods to a nine-patch widget table.
fn add_nine_patch_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setInsets --
    /// Sets the border insets defining the stretchable center region of the nine-patch image.
    /// @param | self | LNinePatch | The widget instance.
    /// @param | left | integer | Left inset in pixels.
    /// @param | top | integer | Top inset in pixels.
    /// @param | right | integer | Right inset in pixels.
    /// @param | bottom | integer | Bottom inset in pixels.
    t.set(
        "setInsets",
        lua.create_function(move |_, (_self, left, top, right, bottom): (LuaValue, u32, u32, u32, u32)| {
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
    // -- getInsets --
    /// Returns the border insets of this nine-patch.
    /// @param | self | LNinePatch | The widget instance.
    /// @return | integer, integer, integer, integer | Left, top, right, and bottom insets.
    t.set(
        "getInsets",
        lua.create_function(move |_, _self: LuaValue| {
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
    // -- setImageDimensions --
    /// Sets the original image dimensions used for nine-patch slice calculations.
    /// @param | self | LNinePatch | The widget instance.
    /// @param | w | integer | Image width in pixels.
    /// @param | h | integer | Image height in pixels.
    t.set(
        "setImageDimensions",
        lua.create_function(move |_, (_self, w, h): (LuaValue, u32, u32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::NinePatch(np)) = g.widgets.get_mut(idx) {
                np.image_width = w;
                np.image_height = h;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getImageDimensions --
    /// Returns the original image dimensions of this nine-patch.
    /// @param | self | LNinePatch | The widget instance.
    /// @return | integer, integer | Image width and height.
    t.set(
        "getImageDimensions",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::NinePatch(np)) => (np.image_width, np.image_height),
                _ => (0, 0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getSlices --
    /// Returns the computed nine-patch slices as a table of source/dest rectangles for rendering.
    /// @param | self | LNinePatch | The widget instance.
    /// @return | table | Array of slice tables with sx, sy, sw, sh, dx, dy, dw, dh fields, or nil.
    /// @field | sx | number | Source x.
    /// @field | sy | number | Source y.
    /// @field | sw | number | Source width.
    /// @field | sh | number | Source height.
    /// @field | dx | number | Dest x.
    /// @field | dy | number | Dest y.
    /// @field | dw | number | Dest width.
    /// @field | dh | number | Dest height.
    t.set(
        "getSlices",
        lua.create_function(move |lua, _self: LuaValue| {
            let g = c.borrow();
            match g.widgets.get(idx) {
                Some(WidgetKind::NinePatch(np)) => {
                    let slices = np.get_slices();
                    let result = lua.create_table()?;
                    for (i, s) in slices.iter().enumerate() {
                        let st = lua.create_table()?;
                        /// Performs the 'sx' operation.
                        st.set("sx", s.0)?;
                        /// Performs the 'sy' operation.
                        st.set("sy", s.1)?;
                        /// Performs the 'sw' operation.
                        st.set("sw", s.2)?;
                        /// Performs the 'sh' operation.
                        st.set("sh", s.3)?;
                        /// Performs the 'dx' operation.
                        st.set("dx", s.4)?;
                        /// Performs the 'dy' operation.
                        st.set("dy", s.5)?;
                        /// Performs the 'dw' operation.
                        st.set("dw", s.6)?;
                        /// Performs the 'dh' operation.
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
/// Adds toast-specific methods to a toast notification widget table.
fn add_toast_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setMessage --
    /// Sets the message text displayed by this toast notification.
    /// @param | self | LToast | The widget instance.
    /// @param | msg | string | The toast message.
    t.set(
        "setMessage",
        lua.create_function(move |_, (_self, msg): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Toast(toast)) = g.widgets.get_mut(idx) {
                toast.message = msg;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getMessage --
    /// Returns the message text of this toast.
    /// @param | self | LToast | The widget instance.
    /// @return | string | The toast message.
    t.set(
        "getMessage",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toast(toast)) => toast.message.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setDuration --
    /// Sets how long this toast is displayed in seconds.
    /// @param | self | LToast | The widget instance.
    /// @param | d | number | Duration in seconds.
    t.set(
        "setDuration",
        lua.create_function(move |_, (_self, d): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Toast(toast)) = g.widgets.get_mut(idx) {
                toast.duration = d.max(0.0);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getDuration --
    /// Returns the display duration of this toast in seconds.
    /// @param | self | LToast | The widget instance.
    /// @return | number | The duration.
    t.set(
        "getDuration",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toast(toast)) => toast.duration,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getProgress --
    /// Returns the elapsed fraction (0.0 to 1.0) of this toast's lifetime.
    /// @param | self | LToast | The widget instance.
    /// @return | number | The progress fraction.
    t.set(
        "getProgress",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toast(toast)) => toast.progress(),
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- isExpired --
    /// Returns whether this toast has exceeded its display duration.
    /// @param | self | LToast | The widget instance.
    /// @return | boolean | True if expired.
    t.set(
        "isExpired",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toast(toast)) => toast.is_expired(),
                _ => true,
            })
        })?,
    )?;
    Ok(())
}
/// Adds separator-specific methods to a separator widget table.
fn add_separator_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- setVertical --
    /// Sets whether this separator draws vertically or horizontally.
    /// @param | self | LSeparator | The widget instance.
    /// @param | v | boolean | True for vertical, false for horizontal.
    t.set(
        "setVertical",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Separator(sep)) = g.widgets.get_mut(idx) {
                sep.vertical = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isVertical --
    /// Returns whether this separator is oriented vertically.
    /// @param | self | LSeparator | The widget instance.
    /// @return | boolean | True if vertical.
    t.set(
        "isVertical",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Separator(sep)) => sep.vertical,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setThickness --
    /// Sets the line thickness of this separator in pixels.
    /// @param | self | LSeparator | The widget instance.
    /// @param | thickness | number | Thickness in pixels.
    t.set(
        "setThickness",
        lua.create_function(move |_, (_self, thickness): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Separator(sep)) = g.widgets.get_mut(idx) {
                sep.thickness = thickness;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getThickness --
    /// Returns the line thickness of this separator.
    /// @param | self | LSeparator | The widget instance.
    /// @return | number | The thickness in pixels.
    t.set(
        "getThickness",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Separator(sep)) => sep.thickness,
                _ => 1.0,
            })
        })?,
    )?;
    Ok(())
}
/// Registers tree-view-specific Lua methods on a widget method table.
fn add_tree_view_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    /// Adds a new node to this tree view, optionally under a parent node.
    /// @param | self | LTreeView | The widget instance.
    /// @param | text | string | The node label text.
    /// @param | parent_index | integer? | The 1-based parent node index, or nil for a root node.
    /// @return | integer | The 1-based index of the newly added node.
    t.set(
        "addNode",
        lua.create_function(move |_, (_self, text, parent_index): (LuaValue, String, Option<usize>)| {
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
    /// Toggles the expanded/collapsed state of the node at the given 1-based index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if the node is now expanded, false if collapsed.
    t.set(
        "toggleNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    /// Returns whether the node at the given 1-based index is currently expanded.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if expanded.
    t.set(
        "isExpanded",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    /// Returns the total number of nodes in this tree view.
    /// @param | self | LTreeView | The widget instance.
    /// @return | integer | The node count.
    t.set(
        "getNodeCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TreeView(tv)) => tv.node_count(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    /// Removes the node at the given 1-based index from this tree view.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if the node was removed.
    t.set(
        "removeNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index.checked_sub(1).is_some_and(|i| tv.remove_node(i)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    /// Removes all nodes from this tree view.
    /// @param | self | LTreeView | The widget instance.
    t.set(
        "clearNodes",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                tv.clear_nodes();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    /// Returns the text of the node at the given 1-based index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | string | The node text, or nil if the index is invalid.
    t.set(
        "getNodeText",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    /// Sets the text of the node at the given 1-based index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @param | text | string | The new node text.
    /// @return | boolean | True if the node text was set.
    t.set(
        "setNodeText",
        lua.create_function(move |_, (_self, index, text): (LuaValue, usize, String)| {
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
    /// Sets the icon of the node at the given 1-based index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @param | icon | string | The icon identifier string.
    /// @return | boolean | True if the icon was set.
    t.set(
        "setNodeIcon",
        lua.create_function(move |_, (_self, index, icon): (LuaValue, usize, String)| {
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
    /// Expands the node at the given 1-based index to show its children.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if the node was expanded.
    t.set(
        "expandNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index.checked_sub(1).is_some_and(|i| tv.expand_node(i)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- collapseNode --
    /// Collapses the node at the given 1-based index to hide its children.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if the node was collapsed.
    t.set(
        "collapseNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                Ok(index.checked_sub(1).is_some_and(|i| tv.collapse_node(i)))
            } else {
                Ok(false)
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- isNodeExpanded --
    /// Returns whether the node at the given 1-based index is expanded. Returns nil if the index is invalid.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if expanded, false if collapsed, nil if invalid.
    t.set(
        "isNodeExpanded",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
            let g = c.borrow();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                Ok(index.checked_sub(1).and_then(|i| tv.is_node_expanded(i)))
            } else {
                Ok(None)
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- expandAll --
    /// Expands all nodes in this tree view.
    /// @param | self | LTreeView | The widget instance.
    t.set(
        "expandAll",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                tv.expand_all();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- collapseAll --
    /// Collapses all nodes in this tree view.
    /// @param | self | LTreeView | The widget instance.
    t.set(
        "collapseAll",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get_mut(idx) {
                tv.collapse_all();
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setSelectedNode --
    /// Sets the selected node by 1-based index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | boolean | True if the node was selected.
    t.set(
        "setSelectedNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getSelectedNode --
    /// Returns the 1-based index of the currently selected node.
    /// @param | self | LTreeView | The widget instance.
    /// @return | integer | The selected node index, or nil if none.
    t.set(
        "getSelectedNode",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            if let Some(WidgetKind::TreeView(tv)) = g.widgets.get(idx) {
                Ok(tv.get_selected_node().map(|i| i + 1))
            } else {
                Ok(None)
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- getChildNodes --
    /// Returns a table of 1-based child node indices for the node at the given index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based parent node index.
    /// @return | integer[] | 1-based child indices.
    t.set(
        "getChildNodes",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getParentNode --
    /// Returns the 1-based index of the parent of the node at the given index.
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | integer | The parent node index, or nil for root nodes.
    t.set(
        "getParentNode",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
    // -- getNodeDepth --
    /// Returns the nesting depth of the node at the given index (0 for root nodes).
    /// @param | self | LTreeView | The widget instance.
    /// @param | index | integer | The 1-based node index.
    /// @return | integer | The depth, or nil if index is invalid.
    t.set(
        "getNodeDepth",
        lua.create_function(move |_, (_self, index): (LuaValue, usize)| {
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
/// Adds radio-button-specific methods to a radio button widget table.
fn add_radio_button_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getText --
    /// Returns the label text of this radio button.
    /// @param | self | LRadioButton | The widget instance.
    /// @return | string | The radio button label.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setText --
    /// Sets the label text of this radio button.
    /// @param | self | LRadioButton | The widget instance.
    /// @param | text | string | The radio button label.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                rb.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isSelected --
    /// Returns whether this radio button is currently selected.
    /// @param | self | LRadioButton | The widget instance.
    /// @return | boolean | True if selected.
    t.set(
        "isSelected",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.selected,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSelected --
    /// Sets the selected state of this radio button.
    /// @param | self | LRadioButton | The widget instance.
    /// @param | v | boolean | True to select.
    t.set(
        "setSelected",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                rb.selected = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getGroup --
    /// Returns the radio button group name. Buttons in the same group are mutually exclusive.
    /// @param | self | LRadioButton | The widget instance.
    /// @return | string | The group name.
    t.set(
        "getGroup",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::RadioButton(rb)) => rb.group.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setGroup --
    /// Sets the radio button group name. Buttons in the same group are mutually exclusive.
    /// @param | self | LRadioButton | The widget instance.
    /// @param | group | string | The group name.
    t.set(
        "setGroup",
        lua.create_function(move |_, (_self, group): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::RadioButton(rb)) = g.widgets.get_mut(idx) {
                rb.group = group;
            }
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnChange --
    /// Registers a callback invoked when this radio button's selection changes.
    /// @param | self | LRadioButton | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnChange",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds scroll-bar-specific methods to a scroll bar widget table.
fn add_scroll_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getScrollPosition --
    /// Returns the current scroll position of this scroll bar.
    /// @param | self | LScrollBar | The widget instance.
    /// @return | number | The scroll position.
    t.set(
        "getScrollPosition",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.position,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setScrollPosition --
    /// Sets the scroll position of this scroll bar, clamped to the valid range.
    /// @param | self | LScrollBar | The widget instance.
    /// @param | v | number | The scroll position.
    t.set(
        "setScrollPosition",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                sb.position = v.clamp(0.0, (sb.content_size - sb.view_size).max(0.0));
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getContentSize --
    /// Returns the total content size tracked by this scroll bar.
    /// @param | self | LScrollBar | The widget instance.
    /// @return | number | The content size.
    t.set(
        "getContentSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.content_size,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setContentSize --
    /// Sets the total content size that this scroll bar represents.
    /// @param | self | LScrollBar | The widget instance.
    /// @param | v | number | The content size.
    t.set(
        "setContentSize",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                sb.content_size = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getViewSize --
    /// Returns the visible viewport size tracked by this scroll bar.
    /// @param | self | LScrollBar | The widget instance.
    /// @return | number | The view size.
    t.set(
        "getViewSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.view_size,
                _ => 0.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setViewSize --
    /// Sets the visible viewport size for this scroll bar.
    /// @param | self | LScrollBar | The widget instance.
    /// @param | v | number | The view size.
    t.set(
        "setViewSize",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ScrollBar(sb)) = g.widgets.get_mut(idx) {
                sb.view_size = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isVertical --
    /// Returns whether this scroll bar is oriented vertically.
    /// @param | self | LScrollBar | The widget instance.
    /// @return | boolean | True if vertical.
    t.set(
        "isVertical",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ScrollBar(sb)) => sb.vertical,
                _ => true,
            })
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnChange --
    /// Registers a callback invoked when this scroll bar's position changes.
    /// @param | self | LScrollBar | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnChange",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds GUI-window-specific methods to a window widget table.
fn add_gui_window_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getTitle --
    /// Returns the title bar text of this GUI window.
    /// @param | self | LGuiWindow | The widget instance.
    /// @return | string | The window title.
    t.set(
        "getTitle",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.title.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setTitle --
    /// Sets the title bar text of this GUI window.
    /// @param | self | LGuiWindow | The widget instance.
    /// @param | title | string | The window title.
    t.set(
        "setTitle",
        lua.create_function(move |_, (_self, title): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                w.title = title;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isCloseable --
    /// Returns whether this window shows a close button.
    /// @param | self | LGuiWindow | The widget instance.
    /// @return | boolean | True if closeable.
    t.set(
        "isCloseable",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.closeable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setCloseable --
    /// Sets whether this window shows a close button.
    /// @param | self | LGuiWindow | The widget instance.
    /// @param | v | boolean | True to show the close button.
    t.set(
        "setCloseable",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                w.closeable = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isDraggable --
    /// Returns whether this window can be dragged by its title bar.
    /// @param | self | LGuiWindow | The widget instance.
    /// @return | boolean | True if draggable.
    t.set(
        "isDraggable",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.draggable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setDraggable --
    /// Sets whether this window can be dragged by its title bar.
    /// @param | self | LGuiWindow | The widget instance.
    /// @param | v | boolean | True to allow dragging.
    t.set(
        "setDraggable",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                w.draggable = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isResizable --
    /// Returns whether this window can be resized by dragging its edges.
    /// @param | self | LGuiWindow | The widget instance.
    /// @return | boolean | True if resizable.
    t.set(
        "isResizable",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUIWindow(w)) => w.resizable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setResizable --
    /// Sets whether this window can be resized.
    /// @param | self | LGuiWindow | The widget instance.
    /// @param | v | boolean | True to allow resizing.
    t.set(
        "setResizable",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUIWindow(w)) = g.widgets.get_mut(idx) {
                w.resizable = v;
            }
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnClose --
    /// Registers a callback invoked when this window is closed.
    /// @param | self | LGuiWindow | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnClose",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_close.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds split-panel-specific methods to a split panel widget table.
fn add_split_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getOrientation --
    /// Returns the orientation of this split panel ("horizontal" or "vertical").
    /// @param | self | LSplitPanel | The widget instance.
    /// @return | string | The orientation.
    t.set(
        "getOrientation",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.orientation.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setOrientation --
    /// Sets the orientation of this split panel ("horizontal" or "vertical").
    /// @param | self | LSplitPanel | The widget instance.
    /// @param | v | string | The orientation.
    t.set(
        "setOrientation",
        lua.create_function(move |_, (_self, v): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                sp.orientation = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getSplitPosition --
    /// Returns the split position as a fraction (0.0 to 1.0) of the panel's total size.
    /// @param | self | LSplitPanel | The widget instance.
    /// @return | number | The split fraction.
    t.set(
        "getSplitPosition",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.split_position,
                _ => 0.5,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSplitPosition --
    /// Sets the split position as a fraction (0.0 to 1.0).
    /// @param | self | LSplitPanel | The widget instance.
    /// @param | v | number | The split fraction.
    t.set(
        "setSplitPosition",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                sp.split_position = v.clamp(0.0, 1.0);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getMinPanelSize --
    /// Returns the minimum pixel size of each split sub-panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @return | number | The minimum size in pixels.
    t.set(
        "getMinPanelSize",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.min_panel_size,
                _ => 50.0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setMinPanelSize --
    /// Sets the minimum pixel size of each split sub-panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @param | v | number | The minimum size in pixels.
    t.set(
        "setMinPanelSize",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                sp.min_panel_size = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setFirstChild --
    /// Sets the widget index for the first (left/top) panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @param | child_idx | integer | The widget index.
    t.set(
        "setFirstChild",
        lua.create_function(move |_, (_self, child_idx): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                sp.first_child = Some(child_idx);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setSecondChild --
    /// Sets the widget index for the second (right/bottom) panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @param | child_idx | integer | The widget index.
    t.set(
        "setSecondChild",
        lua.create_function(move |_, (_self, child_idx): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::SplitPanel(sp)) = g.widgets.get_mut(idx) {
                sp.second_child = Some(child_idx);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getFirstChild --
    /// Returns the widget index of the first (left/top) child panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @return | integer | The widget index, or nil if not set.
    t.set(
        "getFirstChild",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.first_child,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getSecondChild --
    /// Returns the widget index of the second (right/bottom) child panel.
    /// @param | self | LSplitPanel | The widget instance.
    /// @return | integer | The widget index, or nil if not set.
    t.set(
        "getSecondChild",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::SplitPanel(sp)) => sp.second_child,
                _ => None,
            })
        })?,
    )?;
    Ok(())
}
/// Adds dock-panel-specific methods to a dock panel widget table.
fn add_dock_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- dock --
    /// Docks a child widget to the specified side of this dock panel.
    /// @param | self | LDockPanel | The widget instance.
    /// @param | child_idx | integer | The widget index to dock.
    /// @param | side | string | The dock side ("left", "right", "top", "bottom", "center").
    t.set(
        "dock",
        lua.create_function(move |_, (_self, child_idx, side): (LuaValue, usize, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get_mut(idx) {
                dp.docked.push((child_idx, side));
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- undock --
    /// Removes a child widget from this dock panel.
    /// @param | self | LDockPanel | The widget instance.
    /// @param | child_idx | integer | The widget index to undock.
    t.set(
        "undock",
        lua.create_function(move |_, (_self, child_idx): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::DockPanel(dp)) = g.widgets.get_mut(idx) {
                dp.docked.retain(|(ci, _)| *ci != child_idx);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getDockedCount --
    /// Returns the number of widgets docked in this dock panel.
    /// @param | self | LDockPanel | The widget instance.
    /// @return | integer | The docked widget count.
    t.set(
        "getDockedCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::DockPanel(dp)) => dp.docked.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSplitSize --
    /// Sets the size of a dock panel side region.
    /// @param | self | LDockPanel | The widget instance.
    /// @param | side | string | The dock side ("left", "right", "top", "bottom").
    /// @param | size | number | The size in pixels.
    t.set(
        "setSplitSize",
        lua.create_function(move |_, (_self, side, size): (LuaValue, String, f32)| {
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
    // -- getSplitSize --
    /// Returns the size configured for a dock panel side region.
    /// @param | self | LDockPanel | The widget instance.
    /// @param | side | string | The dock side.
    /// @return | number | The size in pixels, or nil if not set.
    t.set(
        "getSplitSize",
        lua.create_function(move |_, (_self, side): (LuaValue, String)| {
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
/// Adds toolbar-specific methods to a toolbar widget table.
fn add_toolbar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getOrientation --
    /// Returns the toolbar orientation ("horizontal" or "vertical").
    /// @param | self | LToolbar | The widget instance.
    /// @return | string | The orientation.
    t.set(
        "getOrientation",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.orientation.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setOrientation --
    /// Sets the toolbar orientation ("horizontal" or "vertical").
    /// @param | self | LToolbar | The widget instance.
    /// @param | v | string | The orientation.
    t.set(
        "setOrientation",
        lua.create_function(move |_, (_self, v): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                tb.orientation = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- addButton --
    /// Adds a new button to this toolbar and returns its 1-based index.
    /// @param | self | LToolbar | The widget instance.
    /// @param | id | string | The button identifier.
    /// @param | tooltip | string? | Optional tooltip text for the button.
    /// @return | integer | The 1-based index of the added button.
    t.set(
        "addButton",
        lua.create_function(move |_, (_self, id, tooltip): (LuaValue, String, Option<String>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get_mut(idx) {
                Ok(tb.add_button(id, tooltip.unwrap_or_default()) + 1)
            } else {
                Ok(0)
            }
        })?,
    )?;
    let c = ctx.clone();
    // -- addSeparator --
    /// Adds a visual separator to this toolbar.
    /// @param | self | LToolbar | The widget instance.
    t.set(
        "addSeparator",
        lua.create_function(move |_, _self: LuaValue| {
            let _ = c.borrow();
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- addSpacer --
    /// Adds a flexible spacer to this toolbar.
    /// @param | self | LToolbar | The widget instance.
    /// @param | _size | number? | Optional size hint (reserved for future use).
    t.set(
        "addSpacer",
        lua.create_function(move |_, (_self, _size): (LuaValue, Option<f32>)| {
            let _ = c.borrow();
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getButton --
    /// Returns a table describing the toolbar button with the given ID.
    /// @param | self | LToolbar | The widget instance.
    /// @param | id | string | The button identifier.
    /// @return | table | Table with id, tooltip, enabled, toggled fields, or nil if not found.
    /// @field | id | integer | Id.
    /// @field | tooltip | string? | Tooltip text.
    /// @field | enabled | boolean | Whether the button is enabled.
    /// @field | toggled | boolean | Whether the button is toggled.
    t.set(
        "getButton",
        lua.create_function(move |lua, (_self, id): (LuaValue, String)| {
            let g = c.borrow();
            if let Some(WidgetKind::Toolbar(tb)) = g.widgets.get(idx) {
                if let Some(btn) = tb.buttons.iter().find(|b| b.id == id) {
                    let bt = lua.create_table()?;
                    /// Performs the 'id' operation.
                    bt.set("id", btn.id.clone())?;
                    /// Performs the 'tooltip' operation.
                    bt.set("tooltip", btn.tooltip.clone())?;
                    /// Performs the 'enabled' operation.
                    bt.set("enabled", btn.enabled)?;
                    /// Performs the 'toggled' operation.
                    bt.set("toggled", btn.toggled)?;
                    return Ok(Some(bt));
                }
            }
            Ok(None)
        })?,
    )?;
    let c = ctx.clone();
    // -- setButtonEnabled --
    /// Enables or disables a toolbar button by its ID.
    /// @param | self | LToolbar | The widget instance.
    /// @param | id | string | The button identifier.
    /// @param | enabled | boolean | True to enable.
    /// @return | boolean | True if the button was found.
    t.set(
        "setButtonEnabled",
        lua.create_function(move |_, (_self, id, enabled): (LuaValue, String, bool)| {
            let mut g = c.borrow_mut();
            Ok(match g.widgets.get_mut(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.set_button_enabled(&id, enabled),
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setButtonToggled --
    /// Sets the toggle state of a toolbar button by its ID.
    /// @param | self | LToolbar | The widget instance.
    /// @param | id | string | The button identifier.
    /// @param | toggled | boolean | True to toggle on.
    /// @return | boolean | True if the button was found.
    t.set(
        "setButtonToggled",
        lua.create_function(move |_, (_self, id, toggled): (LuaValue, String, bool)| {
            let mut g = c.borrow_mut();
            Ok(match g.widgets.get_mut(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.set_button_toggled(&id, toggled),
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- isButtonToggled --
    /// Returns whether a toolbar button is toggled on.
    /// @param | self | LToolbar | The widget instance.
    /// @param | id | string | The button identifier.
    /// @return | boolean | True if toggled, nil if not found.
    t.set(
        "isButtonToggled",
        lua.create_function(move |_, (_self, id): (LuaValue, String)| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Toolbar(tb)) => tb.is_button_toggled(&id),
                _ => None,
            })
        })?,
    )?;
    Ok(())
}
/// Adds menu-bar-specific methods to a menu bar widget table.
fn add_menu_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addMenu --
    /// Adds a menu (by its widget index) to this menu bar.
    /// @param | self | LMenuBar | The widget instance.
    /// @param | menu_idx | integer | The widget index of the menu to add.
    t.set(
        "addMenu",
        lua.create_function(move |_, (_self, menu_idx): (LuaValue, usize)| {
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
    // -- removeMenu --
    /// Removes a menu from this menu bar by its widget index.
    /// @param | self | LMenuBar | The widget instance.
    /// @param | menu_idx | integer | The widget index of the menu to remove.
    /// @return | boolean | True if the menu was found and removed.
    t.set(
        "removeMenu",
        lua.create_function(move |_, (_self, menu_idx): (LuaValue, usize)| {
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
    // -- getMenus --
    /// Returns a table of widget indices for all menus in this menu bar.
    /// @param | self | LMenuBar | The widget instance.
    /// @return | integer[] | Menu widget indices.
    t.set(
        "getMenus",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuBar(mb)) => mb.menus.clone(),
                _ => Vec::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getMenuCount --
    /// Returns the number of menus in this menu bar.
    /// @param | self | LMenuBar | The widget instance.
    /// @return | integer | The menu count.
    t.set(
        "getMenuCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuBar(mb)) => mb.menus.len(),
                _ => 0,
            })
        })?,
    )?;
    Ok(())
}
/// Adds menu-item-specific methods to a menu item widget table.
fn add_menu_item_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getText --
    /// Returns the display text of this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @return | string | The menu item text.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setText --
    /// Sets the display text of this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @param | text | string | The menu item text.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                mi.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getShortcut --
    /// Returns the keyboard shortcut string associated with this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @return | string | The shortcut text.
    t.set(
        "getShortcut",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.shortcut.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setShortcut --
    /// Sets the keyboard shortcut text displayed next to this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @param | shortcut | string | The shortcut text (e.g. "Ctrl+S").
    t.set(
        "setShortcut",
        lua.create_function(move |_, (_self, shortcut): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                mi.shortcut = shortcut;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isChecked --
    /// Returns whether this menu item is checked (for checkable menu items).
    /// @param | self | LMenuItem | The widget instance.
    /// @return | boolean | True if checked.
    t.set(
        "isChecked",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.checked,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setChecked --
    /// Sets the checked state of this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @param | v | boolean | True to check.
    t.set(
        "setChecked",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::MenuItem(mi)) = g.widgets.get_mut(idx) {
                mi.checked = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- addSubItem --
    /// Adds a sub-item to this menu item for building nested menus.
    /// @param | self | LMenuItem | The widget instance.
    /// @param | child_idx | integer | The widget index of the sub-item to add.
    t.set(
        "addSubItem",
        lua.create_function(move |_, (_self, child_idx): (LuaValue, usize)| {
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
    // -- getSubItems --
    /// Returns a table of widget indices for all sub-items of this menu item.
    /// @param | self | LMenuItem | The widget instance.
    /// @return | integer[] | Sub-item widget indices.
    t.set(
        "getSubItems",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::MenuItem(mi)) => mi.items.clone(),
                _ => Vec::new(),
            })
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnClick --
    /// Registers a callback invoked when this menu item is clicked.
    /// @param | self | LMenuItem | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnClick",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_click.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds dialog-specific methods to a dialog widget table.
fn add_dialog_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getTitle --
    /// Returns the title text of this dialog.
    /// @param | self | LDialog | The widget instance.
    /// @return | string | The dialog title.
    t.set(
        "getTitle",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.title.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setTitle --
    /// Sets the title text of this dialog widget.
    /// @param | self | LDialog | The widget instance.
    /// @param | title | string | The dialog title.
    t.set(
        "setTitle",
        lua.create_function(move |_, (_self, title): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                d.title = title;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isModal --
    /// Returns whether this dialog is modal (blocks interaction with other widgets).
    /// @param | self | LDialog | The widget instance.
    /// @return | boolean | True if modal.
    t.set(
        "isModal",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.modal,
                _ => true,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setModal --
    /// Sets whether this dialog widget is modal.
    /// @param | self | LDialog | The widget instance.
    /// @param | v | boolean | True to make modal.
    t.set(
        "setModal",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                d.modal = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isOpen --
    /// Returns whether this dialog is currently open and visible.
    /// @param | self | LDialog | The widget instance.
    /// @return | boolean | True if open.
    t.set(
        "isOpen",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.open,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- open --
    /// Opens this dialog, making it visible.
    /// @param | self | LDialog | The widget instance.
    t.set(
        "open",
        lua.create_function(move |_, _self: LuaValue| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                d.open = true;
            }
            Ok(())
        })?,
    )?;
    let c2 = ctx.clone();
    // -- close --
    /// Closes this dialog and fires the onClose callback if it was open.
    /// @param | self | LDialog | The widget instance.
    t.set(
        "close",
        lua.create_function(move |_, _self: LuaValue| {
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
    let cbs2 = cbs.clone();
    // -- setOnClose --
    /// Registers a callback invoked when this dialog is closed.
    /// @param | self | LDialog | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnClose",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_close.insert(idx, key);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setContent --
    /// Sets the content widget for this dialog.
    /// @param | self | LDialog | The widget instance.
    /// @param | content_idx | integer? | The widget index to show as content, or nil to clear.
    t.set(
        "setContent",
        lua.create_function(move |_, (_self, content_idx): (LuaValue, Option<usize>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Dialog(d)) = g.widgets.get_mut(idx) {
                d.content_idx = content_idx;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getContent --
    /// Returns the widget index of this dialog's content, or nil if not set.
    /// @param | self | LDialog | The widget instance.
    /// @return | integer | The content widget index.
    t.set(
        "getContent",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Dialog(d)) => d.content_idx,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- addButton --
    /// Adds a footer button to this dialog and returns its 1-based index.
    /// @param | self | LDialog | The widget instance.
    /// @param | text | string | The button label.
    /// @param | cb | function? | Optional click callback (reserved for future use).
    /// @return | integer | The 1-based button index.
    t.set(
        "addButton",
        lua.create_function(move |_, (_self, text, _cb): (LuaValue, String, Option<LuaFunction>)| {
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
/// Adds status-bar-specific methods to a status bar widget table.
fn add_status_bar_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addSection --
    /// Adds a labeled section to this status bar.
    /// @param | self | LStatusBar | The widget instance.
    /// @param | text | string | The section display text.
    /// @param | width | number? | The section width in pixels (default 100).
    t.set(
        "addSection",
        lua.create_function(move |_, (_self, text, width): (LuaValue, String, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get_mut(idx) {
                sb.sections.push((text, width.unwrap_or(100.0)));
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setSectionText --
    /// Sets the text of a status bar section by its 1-based index.
    /// @param | self | LStatusBar | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @param | text | string | The new section text.
    t.set(
        "setSectionText",
        lua.create_function(move |_, (_self, section_idx, text): (LuaValue, usize, String)| {
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
    // -- getSectionText --
    /// Returns the text of a status bar section by its 1-based index.
    /// @param | self | LStatusBar | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @return | string | The section text, or nil if out of range.
    t.set(
        "getSectionText",
        lua.create_function(move |_, (_self, section_idx): (LuaValue, usize)| {
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
    // -- getSectionCount --
    /// Returns the number of sections in this status bar.
    /// @param | self | LStatusBar | The widget instance.
    /// @return | integer | The section count.
    t.set(
        "getSectionCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::StatusBar(sb)) => sb.sections.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSectionCount --
    /// Sets the number of sections, truncating or adding empty sections as needed.
    /// @param | self | LStatusBar | The widget instance.
    /// @param | count | integer | The desired section count.
    t.set(
        "setSectionCount",
        lua.create_function(move |_, (_self, count): (LuaValue, usize)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::StatusBar(sb)) = g.widgets.get_mut(idx) {
                if count < sb.sections.len() {
                    sb.sections.truncate(count);
                } else {
                    while sb.sections.len() < count {
                        sb.sections.push((String::new(), 100.0));
                    }
                }
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setSectionWidget --
    /// Associates a widget with a status bar section (reserved for future use).
    /// @param | self | LStatusBar | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @param | widget | table? | The widget table to associate, or nil to clear.
    t.set(
        "setSectionWidget",
        lua.create_function(move |_, (_self, _section_idx, _widget): (LuaValue, usize, LuaValue)| {
            let _ = c.borrow();
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds accordion-specific methods to an accordion widget table.
fn add_accordion_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addSection --
    /// Adds a collapsible section to this accordion.
    /// @param | self | LAccordion | The widget instance.
    /// @param | title | string | The section title.
    /// @param | content_idx | integer? | Optional widget index for the section content.
    t.set(
        "addSection",
        lua.create_function(move |_, (_self, title, content_idx): (LuaValue, String, Option<usize>)| {
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
    // -- getSectionCount --
    /// Returns the number of sections in this accordion.
    /// @param | self | LAccordion | The widget instance.
    /// @return | integer | The section count.
    t.set(
        "getSectionCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => acc.sections.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- toggleSection --
    /// Toggles the expanded state of an accordion section by its 1-based index.
    /// @param | self | LAccordion | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @return | boolean | The new expanded state.
    t.set(
        "toggleSection",
        lua.create_function(move |_, (_self, section_idx): (LuaValue, usize)| {
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
    // -- isSectionExpanded --
    /// Returns whether an accordion section is expanded.
    /// @param | self | LAccordion | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @return | boolean | True if expanded.
    t.set(
        "isSectionExpanded",
        lua.create_function(move |_, (_self, section_idx): (LuaValue, usize)| {
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
    // -- isExclusive --
    /// Returns whether this accordion is in exclusive mode (only one section open at a time).
    /// @param | self | LAccordion | The widget instance.
    /// @return | boolean | True if exclusive.
    t.set(
        "isExclusive",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::Accordion(acc)) => acc.exclusive,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setExclusive --
    /// Sets exclusive mode. When true, expanding one section collapses all others.
    /// @param | self | LAccordion | The widget instance.
    /// @param | v | boolean | True for exclusive mode.
    t.set(
        "setExclusive",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::Accordion(acc)) = g.widgets.get_mut(idx) {
                acc.exclusive = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getSectionTitle --
    /// Returns the title of an accordion section by its 1-based index.
    /// @param | self | LAccordion | The widget instance.
    /// @param | section_idx | integer | The 1-based section index.
    /// @return | string | The section title, or nil if out of range.
    t.set(
        "getSectionTitle",
        lua.create_function(move |_, (_self, section_idx): (LuaValue, usize)| {
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
/// Adds tooltip-panel-specific methods to a tooltip panel widget table.
fn add_tooltip_panel_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getText --
    /// Returns the current tooltip display text.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @return | string | The tooltip text.
    t.set(
        "getText",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.text.clone(),
                _ => String::new(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setText --
    /// Sets the tooltip panel display text content.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @param | text | string | The tooltip text.
    t.set(
        "setText",
        lua.create_function(move |_, (_self, text): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                tp.text = text;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getDelay --
    /// Returns the delay in seconds before this tooltip appears.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @return | number | The delay in seconds.
    t.set(
        "getDelay",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.delay,
                _ => 0.5,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setDelay --
    /// Sets the delay in seconds before this tooltip appears.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @param | v | number | The delay in seconds.
    t.set(
        "setDelay",
        lua.create_function(move |_, (_self, v): (LuaValue, f32)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                tp.delay = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getTarget --
    /// Returns the widget index that this tooltip is attached to.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @return | integer | The target widget index, or nil if unset.
    t.set(
        "getTarget",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::TooltipPanel(tp)) => tp.target_idx,
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setTarget --
    /// Sets the widget index that this tooltip is attached to.
    /// @param | self | LTooltipPanel | The widget instance.
    /// @param | target | integer? | The target widget index, or nil to detach.
    t.set(
        "setTarget",
        lua.create_function(move |_, (_self, target): (LuaValue, Option<usize>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::TooltipPanel(tp)) = g.widgets.get_mut(idx) {
                tp.target_idx = target;
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds color-picker-specific methods to a color picker widget table.
fn add_color_picker_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getColor --
    /// Returns the current color as RGBA components (0.0 to 1.0).
    /// @param | self | LColorPicker | The widget instance.
    /// @return | number | Red component.
    /// @return | number | Green component.
    /// @return | number | Blue component.
    /// @return | number | Alpha component.
    t.set(
        "getColor",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => (cp.r, cp.g, cp.b, cp.a),
                _ => (1.0, 1.0, 1.0, 1.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setColor --
    /// Sets the current color as RGBA components.
    /// @param | self | LColorPicker | The widget instance.
    /// @param | r | number | Red (0.0 to 1.0).
    /// @param | g | number | Green (0.0 to 1.0).
    /// @param | b | number | Blue (0.0 to 1.0).
    /// @param | a | number? | Alpha (0.0 to 1.0), keeps current if omitted.
    t.set(
        "setColor",
        lua.create_function(move |_, (_self, r, green, b, a): (LuaValue, f32, f32, f32, Option<f32>)| {
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
    // -- getShowAlpha --
    /// Returns whether the alpha channel slider is visible.
    /// @param | self | LColorPicker | The widget instance.
    /// @return | boolean | True if the alpha slider is shown.
    t.set(
        "getShowAlpha",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => cp.show_alpha,
                _ => true,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setShowAlpha --
    /// Sets whether the alpha channel slider is visible.
    /// @param | self | LColorPicker | The widget instance.
    /// @param | v | boolean | True to show the alpha slider.
    t.set(
        "setShowAlpha",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get_mut(idx) {
                cp.show_alpha = v;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getColorMode --
    /// Returns the color mode of this picker (e.g. "rgb", "hsv").
    /// @param | self | LColorPicker | The widget instance.
    /// @return | string | The color mode.
    t.set(
        "getColorMode",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ColorPicker(cp)) => cp.color_mode.clone(),
                _ => "rgb".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setColorMode --
    /// Sets the color mode of this picker (e.g. "rgb", "hsv").
    /// @param | self | LColorPicker | The widget instance.
    /// @param | mode | string | The color mode.
    t.set(
        "setColorMode",
        lua.create_function(move |_, (_self, mode): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ColorPicker(cp)) = g.widgets.get_mut(idx) {
                cp.color_mode = mode;
            }
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnChange --
    /// Registers a callback invoked when this color picker's value changes.
    /// @param | self | LColorPicker | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnChange",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_change.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds GUI-table-specific methods to a table widget.
fn add_gui_table_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
    cbs: &Rc<RefCell<GuiCallbacks>>,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- addColumn --
    /// Adds a new column to this table widget.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | header | string | The column header text.
    /// @param | width | number? | The column width in pixels (default 100).
    t.set(
        "addColumn",
        lua.create_function(move |_, (_self, header, width): (LuaValue, String, Option<f32>)| {
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
    // -- getColumnCount --
    /// Returns the number of columns in this table widget.
    /// @param | self | LGuiTable | The widget instance.
    /// @return | integer | The column count.
    t.set(
        "getColumnCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.columns.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- addRow --
    /// Adds a row of data to this table widget.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | cells | table | Array of cell text values.
    t.set(
        "addRow",
        lua.create_function(move |_, (_self, cells): (LuaValue, Vec<String>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                tbl.rows.push(cells);
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getRowCount --
    /// Returns the number of rows in this table widget.
    /// @param | self | LGuiTable | The widget instance.
    /// @return | integer | The row count.
    t.set(
        "getRowCount",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.rows.len(),
                _ => 0,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- getCell --
    /// Returns the text of a cell at the given 1-based row and column.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | row | integer | The 1-based row index.
    /// @param | col | integer | The 1-based column index.
    /// @return | string | The cell text, or nil if out of range.
    t.set(
        "getCell",
        lua.create_function(move |_, (_self, row, col): (LuaValue, usize, usize)| {
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
    // -- setCell --
    /// Sets the text of a cell at the given 1-based row and column.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | row | integer | The 1-based row index.
    /// @param | col | integer | The 1-based column index.
    /// @param | text | string | The new cell text.
    t.set(
        "setCell",
        lua.create_function(move |_, (_self, row, col, text): (LuaValue, usize, usize, String)| {
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
    // -- getSelectedRow --
    /// Returns the 1-based index of the currently selected row, or nil.
    /// @param | self | LGuiTable | The widget instance.
    /// @return | integer | The selected row index.
    t.set(
        "getSelectedRow",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.selected_row.map(|r| r + 1),
                _ => None,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSelectedRow --
    /// Sets the selected row by its 1-based index, or nil to deselect.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | row | integer? | The 1-based row index, or nil.
    t.set(
        "setSelectedRow",
        lua.create_function(move |_, (_self, row): (LuaValue, Option<usize>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                tbl.selected_row = row.map(|r| r.saturating_sub(1));
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- isSortable --
    /// Returns whether columns in this table can be sorted by clicking headers.
    /// @param | self | LGuiTable | The widget instance.
    /// @return | boolean | True if sortable.
    t.set(
        "isSortable",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::GUITable(tbl)) => tbl.sortable,
                _ => false,
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setSortable --
    /// Sets whether columns in this table can be sorted by clicking headers.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | v | boolean | True to enable sorting.
    t.set(
        "setSortable",
        lua.create_function(move |_, (_self, v): (LuaValue, bool)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::GUITable(tbl)) = g.widgets.get_mut(idx) {
                tbl.sortable = v;
            }
            Ok(())
        })?,
    )?;
    let cbs2 = cbs.clone();
    // -- setOnSelect --
    /// Registers a callback invoked when a table row is selected.
    /// @param | self | LGuiTable | The widget instance.
    /// @param | f | function | Callback receiving the widget index.
    t.set(
        "setOnSelect",
        lua.create_function(move |lua, (_self, f): (LuaValue, LuaFunction)| {
            let key = lua.create_registry_value(f)?;
            cbs2.borrow_mut().on_select.insert(idx, key);
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Adds image-widget-specific methods to an image widget table.
fn add_image_widget_methods(
    lua: &Lua,
    t: &LuaTable,
    ctx: &Rc<RefCell<GuiContext>>,
    idx: usize,
) -> LuaResult<()> {
    let c = ctx.clone();
    // -- getScaleMode --
    /// Returns the image scaling mode (e.g. "fit", "fill", "stretch").
    /// @param | self | LImageWidget | The widget instance.
    /// @return | string | The scale mode.
    t.set(
        "getScaleMode",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ImageWidget(iw)) => iw.scale_mode.clone(),
                _ => "fit".to_string(),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setScaleMode --
    /// Sets the image scaling mode (e.g. "fit", "fill", "stretch").
    /// @param | self | LImageWidget | The widget instance.
    /// @param | mode | string | The scale mode.
    t.set(
        "setScaleMode",
        lua.create_function(move |_, (_self, mode): (LuaValue, String)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get_mut(idx) {
                iw.scale_mode = mode;
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- getTint --
    /// Returns the tint color of this image widget as RGBA components.
    /// @param | self | LImageWidget | The widget instance.
    /// @return | number | Red component.
    /// @return | number | Green component.
    /// @return | number | Blue component.
    /// @return | number | Alpha component.
    t.set(
        "getTint",
        lua.create_function(move |_, _self: LuaValue| {
            let g = c.borrow();
            Ok(match g.widgets.get(idx) {
                Some(WidgetKind::ImageWidget(iw)) => (iw.tint.0, iw.tint.1, iw.tint.2, iw.tint.3),
                _ => (1.0, 1.0, 1.0, 1.0),
            })
        })?,
    )?;
    let c = ctx.clone();
    // -- setTint --
    /// Sets the tint color of this image widget as RGBA components.
    /// @param | self | LImageWidget | The widget instance.
    /// @param | r | number | Red (0.0 to 1.0).
    /// @param | g | number | Green (0.0 to 1.0).
    /// @param | b | number | Blue (0.0 to 1.0).
    /// @param | a | number? | Alpha (0.0 to 1.0), defaults to 1.0.
    t.set(
        "setTint",
        lua.create_function(move |_, (_self, r, green, b, a): (LuaValue, f32, f32, f32, Option<f32>)| {
            let mut g = c.borrow_mut();
            if let Some(WidgetKind::ImageWidget(iw)) = g.widgets.get_mut(idx) {
                iw.tint = (r, green, b, a.unwrap_or(1.0));
            }
            Ok(())
        })?,
    )?;
    Ok(())
}
/// Lua-exposed wrapper around a GUI theme for styling widgets.
struct LuaTheme {
    inner: Rc<RefCell<Theme>>,
}
impl LuaUserData for LuaTheme {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setStyle --
        /// Sets a style entry for the given widget type and state.
        /// @param | widget_type | string | The widget type name (e.g. "button").
        /// @param | state | string | The widget state (e.g. "normal", "hovered").
        /// @param | style_table | table | A table of style properties.
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
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LTheme".
        methods.add_method("type", |_, _, ()| Ok("LTheme"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTheme" || name == "Object")
        });
    }
}
/// Parses a widget type name string into a `WidgetType` enum value.
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
/// Parses a Lua table of style properties into a `WidgetStyle`.
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
/// Registers the `lurek.ui` module into the Lua runtime.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let ctx = Rc::new(RefCell::new(GuiContext::new()));
    let callbacks = Rc::new(RefCell::new(GuiCallbacks::default()));
    state.borrow_mut().auto_ui_ctx = Some(Rc::downgrade(&ctx));
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newButton --
    /// Creates a new button widget with optional label text.
    /// @param | text | string? | The button label text.
    /// @return | LButton | The new button widget table.
    tbl.set(
        "newButton",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_button(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LButton")?;
            add_button_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newLabel --
    /// Creates a new label widget for displaying text.
    /// @param | text | string? | The label text.
    /// @return | LLabel | The new label widget table.
    tbl.set(
        "newLabel",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_label(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LLabel")?;
            add_label_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newTextInput --
    /// Creates a new text input widget for user entry.
    /// @return | LTextInput | The new text input widget table.
    tbl.set(
        "newTextInput",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_text_input();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LTextInput")?;
            add_text_input_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newCheckbox --
    /// Creates a new checkbox widget with optional label.
    /// @param | text | string? | The checkbox label text.
    /// @return | LCheckbox | The new checkbox widget table.
    tbl.set(
        "newCheckbox",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_checkbox(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LCheckbox")?;
            add_checkbox_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSlider --
    /// Creates a new slider widget with adjustable range.
    /// @param | min | number? | Minimum value (default 0).
    /// @param | max | number? | Maximum value (default 100).
    /// @return | LSlider | The new slider widget table.
    tbl.set(
        "newSlider",
        lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_slider(min.unwrap_or(0.0), max.unwrap_or(100.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSlider")?;
            add_slider_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newProgressBar --
    /// Creates a new progress bar widget with min and max.
    /// @param | min | number? | Minimum value (default 0).
    /// @param | max | number? | Maximum value (default 100).
    /// @return | LProgressBar | The new progress bar widget table.
    tbl.set(
        "newProgressBar",
        lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_progress_bar(min.unwrap_or(0.0), max.unwrap_or(100.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LProgressBar")?;
            add_progress_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newComboBox --
    /// Creates a new combo box (drop-down) widget.
    /// @return | LComboBox | The new combo box widget table.
    tbl.set(
        "newComboBox",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_combo_box();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LComboBox")?;
            add_combo_box_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newList --
    /// Creates a new list box widget for item selection.
    /// @return | LListBox | The new list box widget table.
    tbl.set(
        "newList",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_list_box();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LListBox")?;
            add_list_box_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newPanel --
    /// Creates a new panel widget (container).
    /// @return | LPanel | The new panel widget table.
    tbl.set(
        "newPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LPanel")?;
            add_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newLayout --
    /// Creates a new layout container widget.
    /// @param | direction | string? | Layout direction: "vertical" or "horizontal" (default "vertical").
    /// @return | LLayout | The new layout widget table.
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
            let t = create_widget_table(lua, &c, idx, &cbs, "LLayout")?;
            add_layout_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newScrollPanel --
    /// Creates a new scrollable panel widget.
    /// @return | LScrollPanel | The new scroll panel widget table.
    tbl.set(
        "newScrollPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_scroll_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LScrollPanel")?;
            add_scroll_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newNinePatch --
    /// Creates a new nine-patch widget for scalable bordered images.
    /// @return | LNinePatch | The new nine-patch widget table.
    tbl.set(
        "newNinePatch",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_nine_patch();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LNinePatch")?;
            add_nine_patch_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newTabBar --
    /// Creates a new tab bar widget for tabbed navigation.
    /// @return | LTabBar | The new tab bar widget table.
    tbl.set(
        "newTabBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_tab_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LTabBar")?;
            add_tab_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSeparator --
    /// Creates a new separator widget for visual division.
    /// @param | vertical | boolean? | True for vertical separator (default false).
    /// @return | LSeparator | The new separator widget table.
    tbl.set(
        "newSeparator",
        lua.create_function(move |lua, vertical: Option<bool>| {
            let mut g = c.borrow_mut();
            let idx = g.add_separator(vertical.unwrap_or(false));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSeparator")?;
            add_separator_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSpacer --
    /// Creates a new spacer widget for spacing between other widgets.
    /// @param | w | number? | The width.
    /// @param | h | number? | The height.
    /// @return | LSpacer | The new spacer widget table.
    tbl.set(
        "newSpacer",
        lua.create_function(move |lua, (w, h): (Option<f32>, Option<f32>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_spacer(w.unwrap_or(0.0), h.unwrap_or(0.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSpacer")?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newToast --
    /// Creates a new toast notification widget.
    /// @param | message | string? | The toast message.
    /// @param | duration | number? | Display duration in seconds (default 3).
    /// @return | LToast | The new toast widget table.
    tbl.set(
        "newToast",
        lua.create_function(
            move |lua, (message, duration): (Option<String>, Option<f32>)| {
                let toast = Toast::new(message.unwrap_or_default(), duration.unwrap_or(3.0));
                let mut g = c.borrow_mut();
                let idx = g.widgets.len();
                g.widgets.push(WidgetKind::Toast(toast));
                drop(g);
                let t = create_widget_table(lua, &c, idx, &cbs, "LToast")?;
                add_toast_methods(lua, &t, &c, idx)?;
                Ok(t)
            },
        )?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newTreeView --
    /// Creates a new tree view widget for hierarchical data.
    /// @return | LTreeView | The new tree view widget table.
    tbl.set(
        "newTreeView",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_tree_view();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LTreeView")?;
            add_tree_view_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newRadioButton --
    /// Creates a new radio button widget in a named group.
    /// @param | text | string? | The radio button label.
    /// @param | group | string? | The radio group name.
    /// @return | LRadioButton | The new radio button widget table.
    tbl.set(
        "newRadioButton",
        lua.create_function(
            move |lua, (text, group): (Option<String>, Option<String>)| {
                let mut g = c.borrow_mut();
                let idx = g.add_radio_button(text.unwrap_or_default(), group.unwrap_or_default());
                drop(g);
                let t = create_widget_table(lua, &c, idx, &cbs, "LRadioButton")?;
                add_radio_button_methods(lua, &t, &c, idx, &cbs)?;
                Ok(t)
            },
        )?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newScrollBar --
    /// Creates a new scroll bar widget for content scrolling.
    /// @param | vertical | boolean? | True for vertical (default true).
    /// @return | LScrollBar | The new scroll bar widget table.
    tbl.set(
        "newScrollBar",
        lua.create_function(move |lua, vertical: Option<bool>| {
            let mut g = c.borrow_mut();
            let idx = g.add_scroll_bar(vertical.unwrap_or(true));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LScrollBar")?;
            add_scroll_bar_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newWindow --
    /// Creates a new GUI window widget with an optional title.
    /// @param | title | string? | The window title.
    /// @return | LGuiWindow | The new window widget table.
    tbl.set(
        "newWindow",
        lua.create_function(move |lua, title: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_gui_window(title.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LGuiWindow")?;
            add_gui_window_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSplitPanel --
    /// Creates a new split panel widget with two resizable sub-panels.
    /// @param | orientation | string? | "horizontal" or "vertical" (default "horizontal").
    /// @return | LSplitPanel | The new split panel widget table.
    tbl.set(
        "newSplitPanel",
        lua.create_function(move |lua, orientation: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_split_panel(orientation.unwrap_or_else(|| "horizontal".to_string()));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSplitPanel")?;
            add_split_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newDockPanel --
    /// Creates a new dock panel widget for docking child widgets to sides.
    /// @return | LDockPanel | The new dock panel widget table.
    tbl.set(
        "newDockPanel",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_dock_panel();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LDockPanel")?;
            add_dock_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newToolbar --
    /// Creates a new toolbar widget for action buttons.
    /// @param | orientation | string? | "horizontal" or "vertical" (default "horizontal").
    /// @return | LToolbar | The new toolbar widget table.
    tbl.set(
        "newToolbar",
        lua.create_function(move |lua, orientation: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_toolbar(orientation.unwrap_or_else(|| "horizontal".to_string()));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LToolbar")?;
            add_toolbar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newMenuBar --
    /// Creates a new menu bar widget for top-level menus.
    /// @return | LMenuBar | The new menu bar widget table.
    tbl.set(
        "newMenuBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_menu_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LMenuBar")?;
            add_menu_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newMenuItem --
    /// Creates a new menu item widget with optional text.
    /// @param | text | string? | The menu item text.
    /// @return | LMenuItem | The new menu item widget table.
    tbl.set(
        "newMenuItem",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_menu_item(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LMenuItem")?;
            add_menu_item_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newDialog --
    /// Creates a new dialog widget with an optional title.
    /// @param | title | string? | The dialog title.
    /// @return | LDialog | The new dialog widget table.
    tbl.set(
        "newDialog",
        lua.create_function(move |lua, title: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_dialog(title.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LDialog")?;
            add_dialog_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newStatusBar --
    /// Creates a new status bar widget for app-level info.
    /// @return | LStatusBar | The new status bar widget table.
    tbl.set(
        "newStatusBar",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_status_bar();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LStatusBar")?;
            add_status_bar_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newAccordion --
    /// Creates a new accordion widget with collapsible sections.
    /// @return | LAccordion | The new accordion widget table.
    tbl.set(
        "newAccordion",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_accordion();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LAccordion")?;
            add_accordion_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newTooltipPanel --
    /// Creates a new tooltip panel widget.
    /// @param | text | string? | The tooltip text.
    /// @return | LTooltipPanel | The new tooltip panel widget table.
    tbl.set(
        "newTooltipPanel",
        lua.create_function(move |lua, text: Option<String>| {
            let mut g = c.borrow_mut();
            let idx = g.add_tooltip_panel(text.unwrap_or_default());
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LTooltipPanel")?;
            add_tooltip_panel_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newColorPicker --
    /// Creates a new color picker widget for color selection.
    /// @return | LColorPicker | The new color picker widget table.
    tbl.set(
        "newColorPicker",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_color_picker();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LColorPicker")?;
            add_color_picker_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newTable --
    /// Creates a new table widget for tabular data display.
    /// @return | LGuiTable | The new table widget.
    tbl.set(
        "newTable",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_gui_table();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LGuiTable")?;
            add_gui_table_methods(lua, &t, &c, idx, &cbs)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newImageWidget --
    /// Creates a new image display widget.
    /// @return | LImageWidget | The new image widget table.
    tbl.set(
        "newImageWidget",
        lua.create_function(move |lua, ()| {
            let mut g = c.borrow_mut();
            let idx = g.add_image_widget();
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LImageWidget")?;
            add_image_widget_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    // -- newTheme --
    /// Creates a new UI theme for styling widgets.
    /// @return | LTheme | The new theme userdata.
    tbl.set(
        "newTheme",
        lua.create_function(move |lua, ()| {
            lua.create_userdata(LuaTheme {
                inner: Rc::new(RefCell::new(Theme::new())),
            })
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- setTheme --
    /// Applies a theme to the entire UI context.
    /// @param | theme_ud | LTheme | The theme userdata to apply.
    tbl.set(
        "setTheme",
        lua.create_function(move |_, theme_ud: LuaAnyUserData| {
            let lua_theme = theme_ud.borrow::<LuaTheme>()?;
            let theme = lua_theme.inner.borrow().clone();
            c.borrow_mut().theme = Some(theme);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- getTheme --
    /// Returns whether a theme is currently set.
    /// @return | boolean | True if a theme is active.
    tbl.set(
        "getTheme",
        lua.create_function(move |_, ()| Ok(c.borrow().theme.is_some()))?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- getRoot --
    /// Returns the root panel widget of the UI tree.
    /// @return | LPanel | The root panel widget table.
    tbl.set(
        "getRoot",
        lua.create_function(move |lua, ()| {
            let t = create_widget_table(lua, &c, 0, &cbs, "LPanel")?;
            add_panel_methods(lua, &t, &c, 0)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- setFocus --
    /// Sets keyboard focus to a widget, or clears focus if nil.
    /// @param | widget | table? | The widget table to focus, or nil to clear.
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
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- getFocus --
    /// Returns the index of the currently focused widget, or nil.
    /// @return | integer | The focused widget index.
    tbl.set(
        "getFocus",
        lua.create_function(move |_, ()| Ok(c.borrow().focused_widget))?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- focusNext --
    /// Moves keyboard focus to the next focusable widget.
    tbl.set(
        "focusNext",
        lua.create_function(move |_, ()| {
            c.borrow_mut().focus_next();
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- focusPrev --
    /// Moves keyboard focus to the previous focusable widget.
    tbl.set(
        "focusPrev",
        lua.create_function(move |_, ()| {
            c.borrow_mut().focus_prev();
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- clearFocus --
    /// Clears keyboard focus from all widgets.
    tbl.set(
        "clearFocus",
        lua.create_function(move |_, ()| {
            c.borrow_mut().set_focus(None);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- addToast --
    /// Adds a toast notification to the queue.
    /// @param | toast_table | table | Table with message (string) and optional duration (number).
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
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- getToastCount --
    /// Returns the number of active toast notifications.
    /// @return | integer | The toast count.
    tbl.set(
        "getToastCount",
        lua.create_function(move |_, ()| Ok(c.borrow().toast_count()))?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- mousepressed --
    /// Delivers a mouse press event to the UI.
    /// @param | x | number | Mouse X position.
    /// @param | y | number | Mouse Y position.
    /// @param | btn | integer? | Mouse button index (default 1).
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "mousepressed",
        lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
            Ok(c.borrow_mut().mouse_pressed(x, y, btn.unwrap_or(1)))
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- mousereleased --
    /// Delivers a mouse release event to the UI.
    /// @param | x | number | Mouse X position.
    /// @param | y | number | Mouse Y position.
    /// @param | btn | integer? | Mouse button index (default 1).
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "mousereleased",
        lua.create_function(move |_, (x, y, btn): (f32, f32, Option<u32>)| {
            Ok(c.borrow_mut().mouse_released(x, y, btn.unwrap_or(1)))
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- mousemoved --
    /// Delivers a mouse move event to the UI.
    /// @param | x | number | Mouse X position.
    /// @param | y | number | Mouse Y position.
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "mousemoved",
        lua.create_function(move |_, (x, y): (f32, f32)| Ok(c.borrow_mut().mouse_moved(x, y)))?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- keypressed --
    /// Delivers a key press event to the UI.
    /// @param | key | string | The key name.
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "keypressed",
        lua.create_function(move |_, key: String| Ok(c.borrow_mut().key_pressed(&key)))?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- textinput --
    /// Delivers a text input event to the UI.
    /// @param | text | string | The input text.
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "textinput",
        lua.create_function(move |_, text: String| Ok(c.borrow_mut().text_input(&text)))?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- wheelmoved --
    /// Delivers a mouse wheel event to the UI.
    /// @param | x | number | Horizontal scroll delta.
    /// @param | y | number | Vertical scroll delta.
    /// @return | boolean | True if a widget consumed the event.
    tbl.set(
        "wheelmoved",
        lua.create_function(move |_, (x, y): (f32, f32)| Ok(c.borrow_mut().wheel_moved(x, y)))?,
    )?;
    let c = ctx.clone();
    let cbs_update = callbacks.clone();
    // -- update --
    /// Updates the UI context and dispatches pending events to callbacks.
    /// @param | dt | number | Delta time in seconds.
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
    let c = ctx.clone();
    let cbs_draw = callbacks.clone();
    // -- draw --
    /// Invokes custom draw callbacks for all widgets that have one registered.
    tbl.set(
        "draw",
        lua.create_function(move |lua, ()| {
            let widget_ids: Vec<usize> = cbs_draw.borrow().on_draw.keys().copied().collect();
            for widget_idx in widget_ids {
                let (rx, ry, rw, rh) = {
                    let g = c.borrow();
                    g.widgets
                        .get(widget_idx)
                        .map(|w| {
                            let r = &w.base().computed_rect;
                            (r.x, r.y, r.width, r.height)
                        })
                        .unwrap_or((0.0, 0.0, 0.0, 0.0))
                };
                let func_opt: Option<LuaFunction> = {
                    let cbs = cbs_draw.borrow();
                    cbs.on_draw
                        .get(&widget_idx)
                        .map(|key| lua.registry_value(key))
                        .transpose()?
                };
                if let Some(func) = func_opt {
                    let rect = lua.create_table()?;
                    /// Performs the 'x' operation.
                    rect.set("x", rx)?;
                    /// Performs the 'y' operation.
                    rect.set("y", ry)?;
                    /// Performs the 'w' operation.
                    rect.set("w", rw)?;
                    /// Performs the 'h' operation.
                    rect.set("h", rh)?;
                    func.call::<_, ()>(rect)?;
                }
            }
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newCustomWidget --
    /// Creates a new custom widget with optional initial configuration.
    /// @param | config | table? | Optional table with x, y, width, height, id, visible, enabled fields.
    /// @return | LUiWidget | The new custom widget table.
    tbl.set(
        "newCustomWidget",
        lua.create_function(move |lua, config: Option<LuaTable>| {
            let idx = {
                let mut g = c.borrow_mut();
                let idx = g.add_custom_widget();
                if let Some(ref cfg) = config {
                    let b = g.widgets[idx].base_mut();
                    if let Ok(v) = cfg.get::<_, f32>("x") {
                        b.x = v;
                    }
                    if let Ok(v) = cfg.get::<_, f32>("y") {
                        b.y = v;
                    }
                    if let Ok(v) = cfg.get::<_, f32>("width") {
                        b.width = v;
                    }
                    if let Ok(v) = cfg.get::<_, f32>("height") {
                        b.height = v;
                    }
                    if let Ok(v) = cfg.get::<_, String>("id") {
                        b.id = v;
                    }
                    if let Ok(v) = cfg.get::<_, bool>("visible") {
                        b.visible = v;
                    }
                    if let Ok(v) = cfg.get::<_, bool>("enabled") {
                        b.enabled = v;
                    }
                }
                idx
            };
            create_widget_table(lua, &c, idx, &cbs, "LWidget")
        })?,
    )?;
    let c = ctx.clone();
    let _cbs = callbacks.clone();
    // -- getWidgetCount --
    /// Returns the total number of widgets in the UI context.
    /// @return | integer | The widget count.
    tbl.set(
        "getWidgetCount",
        lua.create_function(move |_, ()| Ok(c.borrow().widget_count()))?,
    )?;
    let c = ctx.clone();
    // -- drawToImage --
    /// Renders the entire UI to an image buffer.
    /// @param | w | integer | Image width in pixels.
    /// @param | h | integer | Image height in pixels.
    /// @return | LImageData | The rendered image.
    tbl.set(
        "drawToImage",
        lua.create_function(move |_, (w, h): (u32, u32)| {
            let img = c.borrow().draw_to_image(w, h);
            Ok(img)
        })?,
    )?;
    // -- newLineChart --
    /// Creates a new line chart for data visualization.
    /// @param | opts | table | Table with width, height, and optional title.
    /// @return | LLineChart | The new line chart userdata.
    tbl.set(
        "newLineChart",
        lua.create_function(move |_, opts: LuaTable| {
            let width = opts.get::<_, u32>("width").unwrap_or(400);
            let height = opts.get::<_, u32>("height").unwrap_or(300);
            let title = opts.get::<_, Option<String>>("title").ok().flatten();
            let cfg = crate::ui::chart::ChartConfig {
                width,
                height,
                title,
                ..crate::ui::chart::ChartConfig::default()
            };
            Ok(LuaLineChart {
                inner: crate::ui::chart::LineChart::new(cfg),
            })
        })?,
    )?;
    // -- newBarChart --
    /// Creates a new bar chart for data visualization.
    /// @param | opts | table | Table with width, height, and optional title.
    /// @return | LBarChart | The new bar chart userdata.
    tbl.set(
        "newBarChart",
        lua.create_function(move |_, opts: LuaTable| {
            let width = opts.get::<_, u32>("width").unwrap_or(400);
            let height = opts.get::<_, u32>("height").unwrap_or(300);
            let title = opts.get::<_, Option<String>>("title").ok().flatten();
            let cfg = crate::ui::chart::ChartConfig {
                width,
                height,
                title,
                ..crate::ui::chart::ChartConfig::default()
            };
            Ok(LuaBarChart {
                inner: crate::ui::chart::BarChart::new(cfg),
            })
        })?,
    )?;
    // -- newScatterPlot --
    /// Creates a new scatter plot for data visualization.
    /// @param | opts | table | Table with width, height, and optional title.
    /// @return | LScatterPlot | The new scatter plot userdata.
    tbl.set(
        "newScatterPlot",
        lua.create_function(move |_, opts: LuaTable| {
            let width = opts.get::<_, u32>("width").unwrap_or(400);
            let height = opts.get::<_, u32>("height").unwrap_or(400);
            let title = opts.get::<_, Option<String>>("title").ok().flatten();
            let cfg = crate::ui::chart::ChartConfig {
                width,
                height,
                title,
                ..crate::ui::chart::ChartConfig::default()
            };
            Ok(LuaScatterPlot {
                inner: crate::ui::chart::ScatterPlot::new(cfg),
            })
        })?,
    )?;
    // -- newPieChart --
    /// Creates a new pie chart for data visualization.
    /// @param | opts | table | Table with width, height, and optional title.
    /// @return | LPieChart | The new pie chart userdata.
    tbl.set(
        "newPieChart",
        lua.create_function(move |_, opts: LuaTable| {
            let width = opts.get::<_, u32>("width").unwrap_or(400);
            let height = opts.get::<_, u32>("height").unwrap_or(400);
            let title = opts.get::<_, Option<String>>("title").ok().flatten();
            let cfg = crate::ui::chart::ChartConfig {
                width,
                height,
                title,
                ..crate::ui::chart::ChartConfig::default()
            };
            Ok(LuaPieChart {
                inner: crate::ui::chart::PieChart::new(cfg),
            })
        })?,
    )?;
    // -- newAreaChart --
    /// Creates a new area chart for data visualization.
    /// @param | opts | table | Table with width, height, and optional title.
    /// @return | LAreaChart | The new area chart userdata.
    tbl.set(
        "newAreaChart",
        lua.create_function(move |_, opts: LuaTable| {
            let width = opts.get::<_, u32>("width").unwrap_or(400);
            let height = opts.get::<_, u32>("height").unwrap_or(300);
            let title = opts.get::<_, Option<String>>("title").ok().flatten();
            let cfg = crate::ui::chart::ChartConfig {
                width,
                height,
                title,
                ..crate::ui::chart::ChartConfig::default()
            };
            Ok(LuaAreaChart {
                inner: crate::ui::chart::AreaChart::new(cfg),
            })
        })?,
    )?;
    // -- parseWidgetState --
    /// Validates and normalizes a widget state string.
    /// @param | state | string | The state name to parse (e.g. "normal", "hovered").
    /// @return | string | The normalized state string, or nil if invalid.
    tbl.set(
        "parseWidgetState",
        lua.create_function(|_, state: String| {
            Ok(WidgetState::parse_str(&state).map(|ws| ws.as_str().to_string()))
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSpinBox --
    /// Creates a new spin box (numeric stepper) widget.
    /// @param | min | number? | Minimum value (default 0).
    /// @param | max | number? | Maximum value (default 100).
    /// @return | LSpinBox | The new spin box widget table.
    tbl.set(
        "newSpinBox",
        lua.create_function(move |lua, (min, max): (Option<f64>, Option<f64>)| {
            let mut g = c.borrow_mut();
            let idx = g.add_spin_box(min.unwrap_or(0.0), max.unwrap_or(100.0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSpinBox")?;
            add_spin_box_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newSwitch --
    /// Creates a new toggle switch widget.
    /// @param | on | boolean? | Initial on/off state (default false).
    /// @return | LSwitch | The new switch widget table.
    tbl.set(
        "newSwitch",
        lua.create_function(move |lua, on: Option<bool>| {
            let mut g = c.borrow_mut();
            let idx = g.add_switch(on.unwrap_or(false));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LSwitch")?;
            add_switch_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    let cbs = callbacks.clone();
    // -- newBadge --
    /// Creates a new badge widget for displaying counts.
    /// @param | count | integer? | Initial count (default 0).
    /// @return | LBadge | The new badge widget table.
    tbl.set(
        "newBadge",
        lua.create_function(move |lua, count: Option<u32>| {
            let mut g = c.borrow_mut();
            let idx = g.add_badge(count.unwrap_or(0));
            drop(g);
            let t = create_widget_table(lua, &c, idx, &cbs, "LBadge")?;
            add_badge_methods(lua, &t, &c, idx)?;
            Ok(t)
        })?,
    )?;
    let c = ctx.clone();
    // -- setDefaultTheme --
    /// Applies the built-in default theme to the UI context.
    tbl.set(
        "setDefaultTheme",
        lua.create_function(move |_, ()| {
            c.borrow_mut().set_default_theme();
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- setViewport --
    /// Sets the viewport size for the UI context.
    /// @param | w | number | Viewport width.
    /// @param | h | number | Viewport height.
    tbl.set(
        "setViewport",
        lua.create_function(move |_, (w, h): (f32, f32)| {
            c.borrow_mut().set_viewport(w, h);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- flushCache --
    /// Flushes internal UI layout and render caches.
    /// @return | boolean | True if the cache was flushed.
    tbl.set(
        "flushCache",
        lua.create_function(move |_, ()| Ok(c.borrow_mut().flush_cache()))?,
    )?;
    let c = ctx.clone();
    // -- beginDrag --
    /// Begins a drag operation on a widget.
    /// @param | widget | table|number | The widget table or widget index.
    /// @return | boolean | True if the drag started.
    tbl.set(
        "beginDrag",
        lua.create_function(move |_, widget: LuaValue| {
            let widget_idx = match widget {
                LuaValue::Table(t) => t.get::<_, usize>("_idx")?,
                LuaValue::Integer(i) if i >= 0 => i as usize,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "beginDrag expects a widget table or widget index".into(),
                    ));
                }
            };
            Ok(c.borrow_mut().begin_drag(widget_idx))
        })?,
    )?;
    let c = ctx.clone();
    // -- getActiveDrag --
    /// Returns the widget index currently being dragged, or nil.
    /// @return | integer | The dragged widget index.
    tbl.set(
        "getActiveDrag",
        lua.create_function(move |_, ()| Ok(c.borrow().active_drag()))?,
    )?;
    let c = ctx.clone();
    // -- dropOn --
    /// Drops the currently dragged widget onto a target widget.
    /// @param | target | table|number | The target widget table or widget index.
    /// @return | boolean | True if the drop succeeded.
    tbl.set(
        "dropOn",
        lua.create_function(move |_, target: LuaValue| {
            let target_idx = match target {
                LuaValue::Table(t) => t.get::<_, usize>("_idx")?,
                LuaValue::Integer(i) if i >= 0 => i as usize,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "dropOn expects a widget table or widget index".into(),
                    ));
                }
            };
            Ok(c.borrow_mut().drop_on(target_idx))
        })?,
    )?;
    let c = ctx.clone();
    // -- endDrag --
    /// Ends the current drag operation without dropping.
    /// @return | integer | The widget index that was being dragged, or nil if no drag was active.
    tbl.set(
        "endDrag",
        lua.create_function(move |_, ()| Ok(c.borrow_mut().end_drag()))?,
    )?;
    let c = ctx.clone();
    // -- update_bindings --
    /// Updates data bindings for widgets that reference binding keys.
    /// @param | data | table | A table mapping binding keys to values.
    tbl.set(
        "update_bindings",
        lua.create_function(move |_, data: mlua::Table| {
            let mut values = std::collections::HashMap::new();
            for pair in data.clone().pairs::<mlua::Value, mlua::Value>() {
                let (k, v) = pair?;
                let key = match k {
                    mlua::Value::String(s) => s.to_str()?.to_string(),
                    mlua::Value::Integer(n) => n.to_string(),
                    mlua::Value::Number(n) => n.to_string(),
                    _ => continue,
                };
                let val = match v {
                    mlua::Value::Number(n) => crate::ui::UiBindingValue::Number(n),
                    mlua::Value::Integer(n) => crate::ui::UiBindingValue::Number(n as f64),
                    mlua::Value::Boolean(b) => crate::ui::UiBindingValue::Bool(b),
                    mlua::Value::String(s) => {
                        crate::ui::UiBindingValue::Text(s.to_str()?.to_string())
                    }
                    _ => continue,
                };
                values.insert(key, val);
            }
            c.borrow_mut().update_bindings(&values);
            Ok(())
        })?,
    )?;
    let c = ctx.clone();
    // -- loadLayout --
    /// Loads a UI layout from a Lua table definition.
    /// @param | def | table | The layout definition table.
    /// @return | integer | The root widget index.
    tbl.set(
        "loadLayout",
        lua.create_function(move |_, def: mlua::Table| {
            let widget_def = lua_table_to_widget_def(&def)?;
            let mut g = c.borrow_mut();
            let root_idx =
                crate::ui::load_layout_def(&mut g, &widget_def).map_err(mlua::Error::external)?;
            g.add_child(0, root_idx);
            Ok(root_idx as u32)
        })?,
    )?;
    let c = ctx.clone();
    // -- loadLayoutFile --
    /// Loads a UI layout from a TOML layout file.
    /// @param | path | string | Path to the TOML layout file.
    /// @return | integer | The root widget index.
    tbl.set(
        "loadLayoutFile",
        lua.create_function(move |_, path: String| {
            let src = std::fs::read_to_string(&path).map_err(|e| {
                mlua::Error::external(format!("loadLayoutFile: cannot read '{path}': {e}"))
            })?;
            let mut g = c.borrow_mut();
            let root_idx =
                crate::ui::load_layout_toml(&mut g, &src).map_err(mlua::Error::external)?;
            g.add_child(0, root_idx);
            Ok(root_idx as u32)
        })?,
    )?;
    let c = ctx.clone();
    // -- renderToImage --
    /// Renders the entire UI to a PNG image file.
    /// @param | width | integer | Image width in pixels.
    /// @param | height | integer | Image height in pixels.
    /// @param | path | string | Output file path.
    tbl.set(
        "renderToImage",
        lua.create_function(move |_, (width, height, path): (u32, u32, String)| {
            let mut g = c.borrow_mut();
            crate::ui::render_to_image(&mut g, width, height, &path).map_err(mlua::Error::external)
        })?,
    )?;
    /// Performs the 'ui' operation.
    luna.set("ui", tbl)?;
    Ok(())
}
/// Converts a Lua table into a `WidgetDef` for layout loading.
fn lua_table_to_widget_def(table: &mlua::Table) -> mlua::Result<crate::ui::WidgetDef> {
    let widget_type: String = table
        .get::<_, String>("type")
        .or_else(|_| table.get::<_, String>("widget_type"))
        .unwrap_or_else(|_| "panel".to_string());
    let children_table: Option<mlua::Table> = table.get("children").ok();
    let children = if let Some(ct) = children_table {
        let len = ct.raw_len();
        let mut result = Vec::with_capacity(len);
        for i in 1..=len {
            let child_table: mlua::Table = ct.get(i)?;
            result.push(lua_table_to_widget_def(&child_table)?);
        }
        Some(result)
    } else {
        None
    };
    Ok(crate::ui::WidgetDef {
        widget_type,
        id: table.get("id").ok(),
        x: table.get("x").ok(),
        y: table.get("y").ok(),
        w: table.get("w").ok(),
        h: table.get("h").ok(),
        text: table.get("text").ok(),
        min: table.get("min").ok(),
        max: table.get("max").ok(),
        value: table.get("value").ok(),
        checked: table.get("checked").ok(),
        on: table.get("on").ok(),
        visible: table.get("visible").ok(),
        enabled: table.get("enabled").ok(),
        placeholder: table.get("placeholder").ok(),
        tooltip: table.get("tooltip").ok(),
        direction: table.get("direction").ok(),
        spacing: table.get("spacing").ok(),
        orientation: table.get("orientation").ok(),
        group: table.get("group").ok(),
        children,
    })
}
/// Lua-exposed line chart for data visualization.
pub struct LuaLineChart {
    pub inner: crate::ui::chart::LineChart,
}
impl LuaUserData for LuaLineChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeries --
        /// Adds a named series of points to this line chart.
        /// @param | name | string | The series name.
        /// @param | pts_tbl | table | Array of `{x, y}` point tables.
        /// @param | r | number | Red color component.
        /// @param | g | number | Green color component.
        /// @param | b | number | Blue color component.
        methods.add_method_mut(
            "addSeries",
            |_, this, (name, pts_tbl, r, g, b): (String, LuaTable, f32, f32, f32)| {
                let mut pts: Vec<(f32, f32)> = Vec::new();
                for pair in pts_tbl.sequence_values::<LuaTable>() {
                    let p = pair?;
                    let x: f32 = p.get(1).unwrap_or(0.0);
                    let y: f32 = p.get(2).unwrap_or(0.0);
                    pts.push((x, y));
                }
                this.inner
                    .add_series(&name, &pts, crate::math::color::Color::new(r, g, b, 1.0));
                Ok(())
            },
        );
        // -- setYMax --
        /// Sets the maximum Y-axis value for this line chart.
        /// @param | v | number | The Y-axis maximum.
        methods.add_method_mut("setYMax", |_, this, v: f32| {
            this.inner.y_max = v;
            Ok(())
        });
        // -- setXMax --
        /// Sets the maximum X-axis value for this line chart.
        /// @param | v | number | The X-axis maximum.
        methods.add_method_mut("setXMax", |_, this, v: f32| {
            this.inner.x_max = v;
            Ok(())
        });
        // -- drawToImage --
        /// Renders this line chart to an image buffer.
        /// @param | target | LImageData | The image to draw into.
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::image::ImageData>()?;
            this.inner.draw_to_image(&mut img);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LLineChart".
        methods.add_method("type", |_, _, ()| Ok("LLineChart"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLineChart" || name == "Object")
        });
    }
}
/// Lua-exposed bar chart for data visualization.
pub struct LuaBarChart {
    pub inner: crate::ui::chart::BarChart,
}
impl LuaUserData for LuaBarChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeries --
        /// Adds a named series to this bar chart.
        /// @param | name | string | The series name.
        /// @param | r | number | Red color component.
        /// @param | g | number | Green color component.
        /// @param | b | number | Blue color component.
        methods.add_method_mut(
            "addSeries",
            |_, this, (name, r, g, b): (String, f32, f32, f32)| {
                this.inner
                    .add_series(&name, crate::math::color::Color::new(r, g, b, 1.0));
                Ok(())
            },
        );
        // -- addCategory --
        /// Adds a category with values for each series.
        /// @param | label | string | The category label.
        /// @param | vals_tbl | table | Array of values, one per series.
        methods.add_method_mut(
            "addCategory",
            |_, this, (label, vals_tbl): (String, LuaTable)| {
                let mut vals: Vec<f32> = Vec::new();
                for v in vals_tbl.sequence_values::<f32>() {
                    vals.push(v?);
                }
                this.inner.add_category(&label, &vals);
                Ok(())
            },
        );
        // -- drawToImage --
        /// Renders this bar chart to an image buffer.
        /// @param | target | LImageData | The image to draw into.
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::image::ImageData>()?;
            this.inner.draw_to_image(&mut img);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LBarChart".
        methods.add_method("type", |_, _, ()| Ok("LBarChart"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBarChart" || name == "Object")
        });
    }
}
/// Lua-exposed scatter plot for data visualization.
pub struct LuaScatterPlot {
    pub inner: crate::ui::chart::ScatterPlot,
}
impl LuaUserData for LuaScatterPlot {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSeries --
        /// Adds a data series to this scatter plot.
        /// @param | name | string | The series name.
        /// @param | pts_tbl | table | Array of {x, y} point tables.
        /// @param | r | number | Red color component.
        /// @param | g | number | Green color component.
        /// @param | b | number | Blue color component.
        methods.add_method_mut(
            "addSeries",
            |_, this, (name, pts_tbl, r, g, b): (String, LuaTable, f32, f32, f32)| {
                let mut pts: Vec<(f32, f32)> = Vec::new();
                for pair in pts_tbl.sequence_values::<LuaTable>() {
                    let p = pair?;
                    let x: f32 = p.get(1).unwrap_or(0.0);
                    let y: f32 = p.get(2).unwrap_or(0.0);
                    pts.push((x, y));
                }
                this.inner
                    .add_series(&name, &pts, crate::math::color::Color::new(r, g, b, 1.0));
                Ok(())
            },
        );
        // -- setXRange --
        /// Sets the X-axis range for this scatter plot.
        /// @param | mn | number | Minimum X value.
        /// @param | mx | number | Maximum X value.
        methods.add_method_mut("setXRange", |_, this, (mn, mx): (f32, f32)| {
            this.inner.x_range = (mn, mx);
            Ok(())
        });
        // -- setYRange --
        /// Sets the Y-axis range for this scatter plot.
        /// @param | mn | number | Minimum Y value.
        /// @param | mx | number | Maximum Y value.
        methods.add_method_mut("setYRange", |_, this, (mn, mx): (f32, f32)| {
            this.inner.y_range = (mn, mx);
            Ok(())
        });
        // -- drawToImage --
        /// Renders this scatter plot to an image buffer.
        /// @param | target | LImageData | The image to draw into.
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::image::ImageData>()?;
            this.inner.draw_to_image(&mut img);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LScatterPlot".
        methods.add_method("type", |_, _, ()| Ok("LScatterPlot"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LScatterPlot" || name == "Object")
        });
    }
}
/// Lua-exposed pie chart for data visualization.
pub struct LuaPieChart {
    pub inner: crate::ui::chart::PieChart,
}
impl LuaUserData for LuaPieChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addSegment --
        /// Adds a labeled segment to this pie chart widget.
        /// @param | label | string | The segment label.
        /// @param | value | number | The segment value.
        /// @param | r | number | Red color component.
        /// @param | g | number | Green color component.
        /// @param | b | number | Blue color component.
        methods.add_method_mut(
            "addSegment",
            |_, this, (label, value, r, g, b): (String, f32, f32, f32, f32)| {
                this.inner
                    .add_segment(&label, value, crate::math::color::Color::new(r, g, b, 1.0));
                Ok(())
            },
        );
        // -- drawToImage --
        /// Renders this pie chart to an image buffer.
        /// @param | target | LImageData | The image to draw into.
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::image::ImageData>()?;
            this.inner.draw_to_image(&mut img);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LPieChart".
        methods.add_method("type", |_, _, ()| Ok("LPieChart"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LPieChart" || name == "Object")
        });
    }
}
/// Lua-exposed area chart for data visualization.
pub struct LuaAreaChart {
    pub inner: crate::ui::chart::AreaChart,
}
impl LuaUserData for LuaAreaChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addLayer --
        /// Adds a data layer to this area chart.
        /// @param | name | string | The layer name.
        /// @param | vals_tbl | table | Array of numeric values.
        /// @param | r | number | Red color component.
        /// @param | g | number | Green color component.
        /// @param | b | number | Blue color component.
        methods.add_method_mut(
            "addLayer",
            |_, this, (name, vals_tbl, r, g, b): (String, LuaTable, f32, f32, f32)| {
                let mut vals: Vec<f32> = Vec::new();
                for v in vals_tbl.sequence_values::<f32>() {
                    vals.push(v?);
                }
                this.inner
                    .add_layer(&name, &vals, crate::math::color::Color::new(r, g, b, 1.0));
                Ok(())
            },
        );
        // -- setYMax --
        /// Sets the maximum Y-axis value for this area chart.
        /// @param | v | number | The Y-axis maximum.
        methods.add_method_mut("setYMax", |_, this, v: f32| {
            this.inner.y_max = v;
            Ok(())
        });
        // -- drawToImage --
        /// Renders this area chart to an image buffer.
        /// @param | target | LImageData | The image to draw into.
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::image::ImageData>()?;
            this.inner.draw_to_image(&mut img);
            Ok(())
        });
        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Always "LAreaChart".
        methods.add_method("type", |_, _, ()| Ok("LAreaChart"));
        // -- typeOf --
        /// Checks whether this object matches the given type name.
        /// @param | name | string | Type name to check.
        /// @return | boolean | True if the name matches this userdata type.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAreaChart" || name == "Object")
        });
    }
}
