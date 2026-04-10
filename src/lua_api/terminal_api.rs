//! `lurek.terminal` — Grid-based character-cell terminal emulator and widget toolkit.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::{Rc, Weak};

use crate::terminal::{BorderStyle, Terminal, TerminalEvent, Widget, WidgetKind};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Returns `(cell_w, cell_h)` from the active/default font, or `(8.0, 14.0)` as fallback.
fn font_cell_size(st: &SharedState) -> (f32, f32) {
    let key = st.active_font.or(st.default_font);
    if let Some(fk) = key {
        if let Some(font) = st.fonts.get(fk) {
            return (font.cell_width() as f32, font.size());
        }
    }
    (8.0, 14.0)
}

// -------------------------------------------------------------------------------
// Binding infrastructure
// -------------------------------------------------------------------------------

/// Widget callback registry key storage.
#[derive(Default)]
struct WidgetCallbacks {
    on_click: Option<LuaRegistryKey>,
    on_change: Option<LuaRegistryKey>,
    on_select: Option<LuaRegistryKey>,
}

/// Tracks whether a widget handle is detached or attached to a terminal.
enum WidgetAttachment {
    Detached,
    Attached {
        terminal: Rc<TerminalBinding>,
        index: usize,
    },
}

/// Lua-side binding state for a single widget.
struct WidgetBinding {
    widget: Widget,
    callbacks: WidgetCallbacks,
    pending_children: Vec<Rc<RefCell<WidgetBinding>>>,
    attachment: WidgetAttachment,
}

impl WidgetBinding {
    fn new(widget: Widget) -> Self {
        Self {
            widget,
            callbacks: WidgetCallbacks::default(),
            pending_children: Vec::new(),
            attachment: WidgetAttachment::Detached,
        }
    }
}

/// Lua-side binding state for a terminal instance.
struct TerminalBinding {
    terminal: Rc<RefCell<Terminal>>,
    shared_state: Rc<RefCell<SharedState>>,
    widget_handles: RefCell<HashMap<usize, Weak<RefCell<WidgetBinding>>>>,
}

// -------------------------------------------------------------------------------
// Binding helpers
// -------------------------------------------------------------------------------

fn runtime_error(method: &str, message: &str) -> LuaError {
    LuaError::RuntimeError(format!("{method}: {message}"))
}

fn wrong_terminal(method: &str) -> LuaError {
    runtime_error(method, "widget is not attached to this terminal")
}

fn widget_handle_from_userdata(userdata: &LuaAnyUserData) -> LuaResult<Rc<RefCell<WidgetBinding>>> {
    let widget = userdata.borrow::<LuaWidget>()?;
    Ok(widget.binding.clone())
}

fn attached_location(binding: &Rc<RefCell<WidgetBinding>>) -> Option<(Rc<TerminalBinding>, usize)> {
    let binding_ref = binding.borrow();
    match &binding_ref.attachment {
        WidgetAttachment::Attached { terminal, index } => Some((terminal.clone(), *index)),
        WidgetAttachment::Detached => None,
    }
}

fn attached_index_for_terminal(
    binding: &Rc<RefCell<WidgetBinding>>,
    terminal: &Rc<TerminalBinding>,
) -> Option<usize> {
    attached_location(binding).and_then(|(attached_terminal, index)| {
        if Rc::ptr_eq(&attached_terminal, terminal) {
            Some(index)
        } else {
            None
        }
    })
}

fn widget_handle_for_index(
    terminal: &Rc<TerminalBinding>,
    index: usize,
) -> Option<Rc<RefCell<WidgetBinding>>> {
    let weak = {
        let handles = terminal.widget_handles.borrow();
        handles.get(&index).cloned()
    };
    match weak.and_then(|value| value.upgrade()) {
        Some(handle) => Some(handle),
        None => {
            terminal.widget_handles.borrow_mut().remove(&index);
            None
        }
    }
}

fn with_widget<R>(
    binding: &Rc<RefCell<WidgetBinding>>,
    method: &str,
    action: impl FnOnce(&Widget) -> LuaResult<R>,
) -> LuaResult<R> {
    if let Some((terminal, index)) = attached_location(binding) {
        let terminal_ref = terminal.terminal.borrow();
        let widget = terminal_ref
            .get_widget(index)
            .ok_or_else(|| runtime_error(method, "widget handle is stale"))?;
        action(widget)
    } else {
        let binding_ref = binding.borrow();
        action(&binding_ref.widget)
    }
}

fn with_widget_mut<R>(
    binding: &Rc<RefCell<WidgetBinding>>,
    method: &str,
    action: impl FnOnce(&mut Widget) -> LuaResult<R>,
) -> LuaResult<R> {
    if let Some((terminal, index)) = attached_location(binding) {
        let mut terminal_ref = terminal.terminal.borrow_mut();
        let widget = terminal_ref
            .get_widget_mut(index)
            .ok_or_else(|| runtime_error(method, "widget handle is stale"))?;
        action(widget)
    } else {
        let mut binding_ref = binding.borrow_mut();
        action(&mut binding_ref.widget)
    }
}

fn store_callback(
    lua: &Lua,
    slot: &mut Option<LuaRegistryKey>,
    callback: Option<LuaFunction>,
) -> LuaResult<()> {
    *slot = callback
        .map(|func| lua.create_registry_value(func))
        .transpose()?;
    Ok(())
}

enum CallbackKind {
    Click,
    Change,
    Select,
}

fn dispatch_callback(
    lua: &Lua,
    binding: &Rc<RefCell<WidgetBinding>>,
    kind: CallbackKind,
) -> LuaResult<()> {
    let key_ref = {
        let binding_ref = binding.borrow();
        let slot = match kind {
            CallbackKind::Click => &binding_ref.callbacks.on_click,
            CallbackKind::Change => &binding_ref.callbacks.on_change,
            CallbackKind::Select => &binding_ref.callbacks.on_select,
        };
        slot.as_ref()
            .map(|key| lua.registry_value::<LuaFunction>(key))
            .transpose()?
    };
    if let Some(func) = key_ref {
        func.call::<_, ()>(())?;
    }
    Ok(())
}

fn dispatch_terminal_events(
    lua: &Lua,
    terminal: &Rc<TerminalBinding>,
    events: &[TerminalEvent],
) -> LuaResult<()> {
    for event in events {
        let (index, callback) = match event {
            TerminalEvent::ButtonClicked { index } => (*index, CallbackKind::Click),
            TerminalEvent::TextChanged { index } => (*index, CallbackKind::Change),
            TerminalEvent::SelectionChanged { index } => (*index, CallbackKind::Select),
        };
        if let Some(binding) = widget_handle_for_index(terminal, index) {
            dispatch_callback(lua, &binding, callback)?;
        }
    }
    Ok(())
}

fn sync_binding_snapshot(
    binding: &Rc<RefCell<WidgetBinding>>,
    terminal: &Rc<TerminalBinding>,
    index: usize,
    snapshot: Option<Widget>,
) {
    let mut snapshot = snapshot.or_else(|| terminal.terminal.borrow().get_widget(index).cloned());
    let pending_children = match snapshot.as_ref() {
        Some(Widget {
            kind: WidgetKind::Panel { children },
            ..
        }) => children
            .iter()
            .filter_map(|child_index| widget_handle_for_index(terminal, *child_index))
            .collect(),
        _ => Vec::new(),
    };

    if let Some(widget) = &mut snapshot {
        if let WidgetKind::Panel { children } = &mut widget.kind {
            children.clear();
        }
    }

    let mut binding_ref = binding.borrow_mut();
    if let Some(widget) = snapshot {
        binding_ref.widget = widget;
    }
    binding_ref.pending_children = pending_children;
    binding_ref.attachment = WidgetAttachment::Detached;
}

fn reindex_widget_handles(terminal: &Rc<TerminalBinding>, removed_index: usize) {
    let entries: Vec<(usize, Weak<RefCell<WidgetBinding>>)> = {
        let handles = terminal.widget_handles.borrow();
        handles
            .iter()
            .map(|(index, handle)| (*index, handle.clone()))
            .collect()
    };

    let mut reindexed = HashMap::new();
    for (index, weak) in entries {
        if index == removed_index {
            continue;
        }
        if let Some(handle) = weak.upgrade() {
            if index > removed_index {
                let mut handle_ref = handle.borrow_mut();
                if let WidgetAttachment::Attached {
                    terminal: attached_terminal,
                    index: attached_index,
                } = &mut handle_ref.attachment
                {
                    if Rc::ptr_eq(attached_terminal, terminal) {
                        *attached_index -= 1;
                    }
                }
            }
            let new_index = if index > removed_index {
                index - 1
            } else {
                index
            };
            reindexed.insert(new_index, Rc::downgrade(&handle));
        }
    }

    *terminal.widget_handles.borrow_mut() = reindexed;
}

fn attach_widget(
    terminal: &Rc<TerminalBinding>,
    binding: &Rc<RefCell<WidgetBinding>>,
) -> LuaResult<usize> {
    let (widget, pending_children) = {
        let binding_ref = binding.borrow();
        match &binding_ref.attachment {
            WidgetAttachment::Detached => (
                binding_ref.widget.clone(),
                binding_ref.pending_children.clone(),
            ),
            WidgetAttachment::Attached {
                terminal: attached_terminal,
                index,
            } => {
                if Rc::ptr_eq(attached_terminal, terminal) {
                    return Ok(*index);
                }
                return Err(runtime_error(
                    "Terminal:addWidget",
                    "widget is already attached to another terminal",
                ));
            }
        }
    };

    let index = terminal.terminal.borrow_mut().add_widget(widget);
    terminal
        .widget_handles
        .borrow_mut()
        .insert(index, Rc::downgrade(binding));

    {
        let mut binding_ref = binding.borrow_mut();
        binding_ref.pending_children.clear();
        binding_ref.attachment = WidgetAttachment::Attached {
            terminal: terminal.clone(),
            index,
        };
    }

    for child in pending_children {
        let child_index = attach_widget(terminal, &child)?;
        let _ = terminal
            .terminal
            .borrow_mut()
            .add_panel_child(index, child_index);
    }

    Ok(index)
}

fn remove_attached_widget(
    terminal: &Rc<TerminalBinding>,
    binding: &Rc<RefCell<WidgetBinding>>,
) -> LuaResult<bool> {
    let Some(index) = attached_index_for_terminal(binding, terminal) else {
        return Ok(false);
    };

    let snapshot = terminal.terminal.borrow().get_widget(index).cloned();
    if !terminal.terminal.borrow_mut().remove_widget(index) {
        return Ok(false);
    }

    terminal.widget_handles.borrow_mut().remove(&index);
    sync_binding_snapshot(binding, terminal, index, snapshot);
    reindex_widget_handles(terminal, index);
    Ok(true)
}

fn clear_attached_widgets(terminal: &Rc<TerminalBinding>) {
    let snapshots: Vec<(usize, Rc<RefCell<WidgetBinding>>, Widget)> = {
        let terminal_ref = terminal.terminal.borrow();
        let handles = terminal.widget_handles.borrow();
        handles
            .iter()
            .filter_map(|(index, handle)| {
                handle.upgrade().and_then(|binding| {
                    terminal_ref
                        .get_widget(*index)
                        .cloned()
                        .map(|widget| (*index, binding, widget))
                })
            })
            .collect()
    };

    for (index, binding, widget) in snapshots {
        sync_binding_snapshot(&binding, terminal, index, Some(widget));
    }

    terminal.terminal.borrow_mut().clear_widgets();
    terminal.widget_handles.borrow_mut().clear();
}

fn usize_from_value(value: Option<LuaValue>) -> usize {
    match value {
        Some(LuaValue::Integer(value)) => value.max(0) as usize,
        Some(LuaValue::Number(value)) => value.max(0.0) as usize,
        _ => 0,
    }
}

fn number_from_value(value: Option<LuaValue>) -> Option<f32> {
    match value {
        Some(LuaValue::Integer(value)) => Some(value as f32),
        Some(LuaValue::Number(value)) => Some(value as f32),
        _ => None,
    }
}

// -------------------------------------------------------------------------------
// LuaTerminal UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Terminal`] with widget binding management.
#[derive(Clone)]
struct LuaTerminal {
    binding: Rc<TerminalBinding>,
}

impl LuaUserData for LuaTerminal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- set --
        /// Sets a cell at 1-based coordinates with character FG and BG colours.
        /// @param col : integer
        /// @param row : integer
        /// @param ch : string
        /// @return nil
        methods.add_method("set", |_, this, args: LuaMultiValue| {
            let mut values = args.into_iter();
            let col = usize_from_value(values.next());
            let row = usize_from_value(values.next());
            let ch = match values.next() {
                Some(LuaValue::String(value)) => {
                    value.to_str()?.chars().next().unwrap_or(' ') as u32
                }
                Some(LuaValue::Integer(value)) => value as u32,
                Some(LuaValue::Number(value)) => value as u32,
                _ => b' ' as u32,
            };
            let mut floats = [1.0_f32, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0];
            for float in &mut floats {
                if let Some(value) = number_from_value(values.next()) {
                    *float = value;
                }
            }
            this.binding.terminal.borrow_mut().set(
                col,
                row,
                ch,
                [floats[0], floats[1], floats[2], floats[3]],
                [floats[4], floats[5], floats[6], floats[7]],
            );
            Ok(())
        });

        // -- get --
        /// Returns the cell data at 1-based coordinates.
        /// @param col : integer
        /// @param row : integer
        /// @return integer, number, number, number, number, number, number, number, number
        methods.add_method("get", |_, this, (col, row): (usize, usize)| {
            let cell = this.binding.terminal.borrow().get(col, row);
            Ok((
                cell.ch, cell.fg[0], cell.fg[1], cell.fg[2], cell.fg[3], cell.bg[0], cell.bg[1],
                cell.bg[2], cell.bg[3],
            ))
        });

        // -- clear --
        /// Clears all cells to defaults.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.binding.terminal.borrow_mut().clear();
            Ok(())
        });

        // -- getDimensions --
        /// Returns the terminal grid dimensions.
        /// @return integer, integer
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.binding.terminal.borrow().get_dimensions())
        });

        // -- getCellSize --
        /// Returns the current cell size in pixels derived from the active font.
        /// @return integer, integer
        methods.add_method("getCellSize", |_, this, ()| {
            let st = this.binding.shared_state.borrow();
            let (cw, ch) = font_cell_size(&st);
            Ok((cw as u32, ch as u32))
        });

        // -- addWidget --
        /// Attaches a widget to this terminal.
        /// @param widget : Widget
        /// @return nil
        methods.add_method("addWidget", |_, this, widget_ud: LuaAnyUserData| {
            let widget = widget_handle_from_userdata(&widget_ud)?;
            let _ = attach_widget(&this.binding, &widget)?;
            Ok(())
        });

        // -- removeWidget --
        /// Detaches a widget from this terminal.
        /// @param widget : Widget
        /// @return nil
        methods.add_method("removeWidget", |_, this, widget_ud: LuaAnyUserData| {
            let widget = widget_handle_from_userdata(&widget_ud)?;
            let _ = remove_attached_widget(&this.binding, &widget)?;
            Ok(())
        });

        // -- clearWidgets --
        /// Detaches all widgets from this terminal.
        /// @return nil
        methods.add_method("clearWidgets", |_, this, ()| {
            clear_attached_widgets(&this.binding);
            Ok(())
        });

        // -- getWidgetCount --
        /// Returns the number of attached widgets.
        /// @return integer
        methods.add_method("getWidgetCount", |_, this, ()| {
            Ok(this.binding.terminal.borrow().get_widget_count())
        });

        // -- setFocus --
        /// Sets the focused widget, or clears focus if nil is passed.
        /// @param widget : Widget?
        /// @return nil
        methods.add_method("setFocus", |_, this, value: LuaValue| {
            match value {
                LuaValue::Nil => {
                    this.binding.terminal.borrow_mut().set_focus(None);
                    Ok(())
                }
                LuaValue::UserData(userdata) => {
                    let widget = widget_handle_from_userdata(&userdata)?;
                    let index = attached_index_for_terminal(&widget, &this.binding)
                        .ok_or_else(|| wrong_terminal("Terminal:setFocus"))?;
                    this.binding.terminal.borrow_mut().set_focus(Some(index));
                    Ok(())
                }
                _ => Err(runtime_error("Terminal:setFocus", "expected widget or nil")),
            }
        });

        // -- getFocused --
        /// Returns the currently focused widget, or nil.
        /// @return Widget?
        methods.add_method("getFocused", |lua: &Lua, this, ()| {
            let focused = this.binding.terminal.borrow().get_focused();
            match focused.and_then(|index| widget_handle_for_index(&this.binding, index)) {
                Some(binding) => Ok(LuaValue::UserData(
                    lua.create_userdata(LuaWidget { binding })?,
                )),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- keypressed --
        /// Routes a key press to the focused widget and fires callbacks.
        /// @param key : string
        /// @return boolean
        methods.add_method("keypressed", |lua, this, key: String| {
            let (consumed, events) = this
                .binding
                .terminal
                .borrow_mut()
                .keypressed_with_events(&key);
            dispatch_terminal_events(lua, &this.binding, &events)?;
            Ok(consumed)
        });

        // -- textinput --
        /// Routes text input to the focused widget and fires callbacks.
        /// @param text : string
        /// @return boolean
        methods.add_method("textinput", |lua, this, text: String| {
            let (consumed, events) = this
                .binding
                .terminal
                .borrow_mut()
                .textinput_with_events(&text);
            dispatch_terminal_events(lua, &this.binding, &events)?;
            Ok(consumed)
        });

        // -- mousepressed --
        /// Routes a mouse press to widgets using pixel coordinates.
        /// @param px : number
        /// @param py : number
        /// @param button : integer?
        /// @return nil
        methods.add_method(
            "mousepressed",
            |lua, this, (px, py, button): (f32, f32, Option<usize>)| {
                let (cell_w, cell_h) = font_cell_size(&this.binding.shared_state.borrow());
                let col = (px / cell_w).floor() as usize + 1;
                let row = (py / cell_h).floor() as usize + 1;
                let (_, events) = this.binding.terminal.borrow_mut().mousepressed_with_events(
                    col,
                    row,
                    button.unwrap_or(1),
                );
                dispatch_terminal_events(lua, &this.binding, &events)?;
                Ok(())
            },
        );

        // -- draw --
        /// Renders the terminal grid and widgets as render commands.
        /// @param x : number?
        /// @param y : number?
        /// @return nil
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let st = this.binding.shared_state.borrow();
            let font_key = st.active_font.or(st.default_font);
            if let Some(fk) = font_key {
                let (cell_w, cell_h) = font_cell_size(&st);
                let commands = this.binding.terminal.borrow().build_render_commands(
                    x.unwrap_or(0.0),
                    y.unwrap_or(0.0),
                    cell_w,
                    cell_h,
                    fk,
                );
                drop(st);
                this.binding
                    .shared_state
                    .borrow_mut()
                    .render_commands
                    .extend(commands);
            }
            Ok(())
        });

        // -- setFont --
        /// Sets the terminal font by pixel height, snapping to the nearest built-in size.
        /// @param height : integer
        /// @return nil
        methods.add_method("setFont", |_, this, height: u32| {
            let idx = crate::render::Font::nearest_size(height);
            let st = this.binding.shared_state.borrow();
            if let Some(key) = st.default_fonts[idx] {
                drop(st);
                this.binding.shared_state.borrow_mut().active_font = Some(key);
                Ok(())
            } else {
                Err(LuaError::RuntimeError(
                    "terminal:setFont: built-in fonts not loaded".into(),
                ))
            }
        });

        // -- autoResize --
        /// Resizes the window to exactly fit the terminal grid at the current font size.
        /// @return nil
        methods.add_method("autoResize", |_, this, ()| {
            let st = this.binding.shared_state.borrow();
            let terminal = this.binding.terminal.borrow();
            let cols = terminal.cols();
            let rows = terminal.rows();
            let (cell_w, cell_h) = font_cell_size(&st);
            let new_w = cols as u32 * cell_w as u32;
            let new_h = rows as u32 * cell_h as u32;
            drop(terminal);
            drop(st);
            this.binding.shared_state.borrow_mut().window_state.pending_size = Some((new_w, new_h));
            Ok(())
        });

    }
}

// -------------------------------------------------------------------------------
// LuaWidget UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Widget`] with attachment and callback state.
#[derive(Clone)]
struct LuaWidget {
    binding: Rc<RefCell<WidgetBinding>>,
}

impl LuaUserData for LuaWidget {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- setPosition --
        /// Sets the widget position from 1-based coordinates.
        /// @param col : integer
        /// @param row : integer
        /// @return nil
        methods.add_method("setPosition", |_, this, (col, row): (usize, usize)| {
            with_widget_mut(&this.binding, "Widget:setPosition", |widget| {
                widget.base.set_position_1based(col, row);
                Ok(())
            })
        });

        // -- getPosition --
        /// Returns the widget position as 1-based coordinates.
        /// @return integer, integer
        methods.add_method("getPosition", |_, this, ()| {
            with_widget(&this.binding, "Widget:getPosition", |widget| {
                Ok(widget.base.position_1based())
            })
        });

        // -- setSize --
        /// Sets the widget size in cells.
        /// @param width : integer
        /// @param height : integer
        /// @return nil
        methods.add_method("setSize", |_, this, (width, height): (usize, usize)| {
            with_widget_mut(&this.binding, "Widget:setSize", |widget| {
                widget.base.width = width.max(1);
                widget.base.height = height.max(1);
                Ok(())
            })
        });

        // -- getSize --
        /// Returns the widget size in cells.
        /// @return integer, integer
        methods.add_method("getSize", |_, this, ()| {
            with_widget(&this.binding, "Widget:getSize", |widget| {
                Ok((widget.base.width, widget.base.height))
            })
        });

        // -- setVisible --
        /// Sets the widget visibility.
        /// @param visible : boolean
        /// @return nil
        methods.add_method("setVisible", |_, this, visible: bool| {
            with_widget_mut(&this.binding, "Widget:setVisible", |widget| {
                widget.base.visible = visible;
                Ok(())
            })
        });

        // -- isVisible --
        /// Returns whether the widget is visible.
        /// @return boolean
        methods.add_method("isVisible", |_, this, ()| {
            with_widget(&this.binding, "Widget:isVisible", |widget| {
                Ok(widget.base.visible)
            })
        });

        // -- setEnabled --
        /// Sets whether the widget accepts input.
        /// @param enabled : boolean
        /// @return nil
        methods.add_method("setEnabled", |_, this, enabled: bool| {
            with_widget_mut(&this.binding, "Widget:setEnabled", |widget| {
                widget.base.enabled = enabled;
                Ok(())
            })
        });

        // -- isEnabled --
        /// Returns whether the widget accepts input.
        /// @return boolean
        methods.add_method("isEnabled", |_, this, ()| {
            with_widget(&this.binding, "Widget:isEnabled", |widget| {
                Ok(widget.base.enabled)
            })
        });

        // -- setTag --
        /// Sets the free-form identification tag.
        /// @param tag : string
        /// @return nil
        methods.add_method("setTag", |_, this, tag: String| {
            with_widget_mut(&this.binding, "Widget:setTag", |widget| {
                widget.base.tag = tag;
                Ok(())
            })
        });

        // -- getTag --
        /// Returns the free-form identification tag.
        /// @return string
        methods.add_method("getTag", |_, this, ()| {
            with_widget(&this.binding, "Widget:getTag", |widget| {
                Ok(widget.base.tag.clone())
            })
        });

        // -- setText --
        /// Sets the text content of a label, button, or text box widget.
        /// @param text : string
        /// @return nil
        methods.add_method("setText", |lua, this, text: String| {
            let changed = with_widget_mut(&this.binding, "Widget:setText", |widget| {
                widget.set_text(text).map_err(|e| runtime_error("Widget:setText", e))
            })?;
            if changed {
                dispatch_callback(lua, &this.binding, CallbackKind::Change)?;
            }
            Ok(())
        });

        // -- getText --
        /// Returns the text content of a label, button, or text box widget.
        /// @return string
        methods.add_method("getText", |_, this, ()| {
            with_widget(&this.binding, "Widget:getText", |widget| {
                widget.get_text().map_err(|e| runtime_error("Widget:getText", e))
            })
        });

        // -- setColor --
        /// Sets the colour of a label or border widget.
        /// @param r : number
        /// @param g : number
        /// @param b : number
        /// @param a : number?
        /// @return nil
        methods.add_method(
            "setColor",
            |_, this, (r, g, b, a): (f32, f32, f32, Option<f32>)| {
                with_widget_mut(&this.binding, "Widget:setColor", |widget| {
                    widget
                        .set_color([r, g, b, a.unwrap_or(1.0)])
                        .map_err(|e| runtime_error("Widget:setColor", e))
                })
            },
        );

        // -- getColor --
        /// Returns the colour of a label or border widget.
        /// @return number, number, number, number
        methods.add_method("getColor", |_, this, ()| {
            with_widget(&this.binding, "Widget:getColor", |widget| {
                let c = widget
                    .get_color()
                    .map_err(|e| runtime_error("Widget:getColor", e))?;
                Ok((c[0], c[1], c[2], c[3]))
            })
        });

        // -- setOnClick --
        /// Registers a click callback for a button widget.
        /// @param callback : function?
        /// @return nil
        methods.add_method("setOnClick", |lua, this, callback: Option<LuaFunction>| {
            with_widget(&this.binding, "Widget:setOnClick", |widget| {
                if !widget.is_button() {
                    return Err(runtime_error("Widget:setOnClick", "expected button"));
                }
                Ok(())
            })?;
            let mut binding_ref = this.binding.borrow_mut();
            store_callback(lua, &mut binding_ref.callbacks.on_click, callback)
        });

        // -- setMaxLength --
        /// Sets the maximum character length of a text box widget.
        /// @param max_length : integer
        /// @return nil
        methods.add_method("setMaxLength", |_, this, max_length: usize| {
            with_widget_mut(&this.binding, "Widget:setMaxLength", |widget| {
                widget
                    .set_max_length(max_length)
                    .map_err(|e| runtime_error("Widget:setMaxLength", e))
            })
        });

        // -- getMaxLength --
        /// Returns the maximum character length of a text box widget.
        /// @return integer
        methods.add_method("getMaxLength", |_, this, ()| {
            with_widget(&this.binding, "Widget:getMaxLength", |widget| {
                widget
                    .get_max_length()
                    .map_err(|e| runtime_error("Widget:getMaxLength", e))
            })
        });

        // -- setOnChange --
        /// Registers a text change callback for a text box widget.
        /// @param callback : function?
        /// @return nil
        methods.add_method("setOnChange", |lua, this, callback: Option<LuaFunction>| {
            with_widget(&this.binding, "Widget:setOnChange", |widget| {
                if !widget.is_textbox() {
                    return Err(runtime_error("Widget:setOnChange", "expected text box"));
                }
                Ok(())
            })?;
            let mut binding_ref = this.binding.borrow_mut();
            store_callback(lua, &mut binding_ref.callbacks.on_change, callback)
        });

        // -- addItem --
        /// Adds an item to a list widget.
        /// @param item : string
        /// @return nil
        methods.add_method("addItem", |_, this, item: String| {
            with_widget_mut(&this.binding, "Widget:addItem", |widget| {
                widget
                    .add_item(item)
                    .map_err(|e| runtime_error("Widget:addItem", e))
            })
        });

        // -- removeItem --
        /// Removes an item from a list widget by 1-based index.
        /// @param index : integer
        /// @return nil
        methods.add_method("removeItem", |_, this, index: usize| {
            with_widget_mut(&this.binding, "Widget:removeItem", |widget| {
                widget
                    .remove_item_1based(index)
                    .map_err(|e| runtime_error("Widget:removeItem", e))
            })
        });

        // -- clearItems --
        /// Removes all items from a list widget.
        /// @return nil
        methods.add_method("clearItems", |_, this, ()| {
            with_widget_mut(&this.binding, "Widget:clearItems", |widget| {
                widget
                    .clear_items()
                    .map_err(|e| runtime_error("Widget:clearItems", e))
            })
        });

        // -- getItemCount --
        /// Returns the number of items in a list widget.
        /// @return integer
        methods.add_method("getItemCount", |_, this, ()| {
            with_widget(&this.binding, "Widget:getItemCount", |widget| {
                widget
                    .get_item_count()
                    .map_err(|e| runtime_error("Widget:getItemCount", e))
            })
        });

        // -- getItem --
        /// Returns a list item by 1-based index.
        /// @param index : integer
        /// @return string
        methods.add_method("getItem", |_, this, index: usize| {
            with_widget(&this.binding, "Widget:getItem", |widget| {
                widget
                    .get_item_1based(index)
                    .map_err(|e| runtime_error("Widget:getItem", e))
            })
        });

        // -- setSelected --
        /// Sets the selected item in a list widget by 1-based index.
        /// @param index : integer?
        /// @return nil
        methods.add_method("setSelected", |lua, this, index: Option<usize>| {
            let changed = with_widget_mut(&this.binding, "Widget:setSelected", |widget| {
                widget
                    .set_selected_1based(index)
                    .map_err(|e| runtime_error("Widget:setSelected", e))
            })?;
            if changed {
                dispatch_callback(lua, &this.binding, CallbackKind::Select)?;
            }
            Ok(())
        });

        // -- getSelected --
        /// Returns the selected item index (1-based) in a list widget, or nil.
        /// @return integer?
        methods.add_method("getSelected", |_, this, ()| {
            with_widget(&this.binding, "Widget:getSelected", |widget| {
                widget
                    .get_selected_1based()
                    .map_err(|e| runtime_error("Widget:getSelected", e))
            })
        });

        // -- setOnSelect --
        /// Registers a selection change callback for a list widget.
        /// @param callback : function?
        /// @return nil
        methods.add_method("setOnSelect", |lua, this, callback: Option<LuaFunction>| {
            with_widget(&this.binding, "Widget:setOnSelect", |widget| {
                if !widget.is_list() {
                    return Err(runtime_error("Widget:setOnSelect", "expected list"));
                }
                Ok(())
            })?;
            let mut binding_ref = this.binding.borrow_mut();
            store_callback(lua, &mut binding_ref.callbacks.on_select, callback)
        });

        // -- setStyle --
        /// Sets the border style of a border widget.
        /// @param style : string
        /// @return nil
        methods.add_method("setStyle", |_, this, style_name: String| {
            let style = BorderStyle::from_str_name(&style_name)
                .ok_or_else(|| runtime_error("Widget:setStyle", "invalid border style"))?;
            with_widget_mut(&this.binding, "Widget:setStyle", |widget| {
                widget
                    .set_border_style(style)
                    .map_err(|e| runtime_error("Widget:setStyle", e))
            })
        });

        // -- getStyle --
        /// Returns the border style name of a border widget.
        /// @return string
        methods.add_method("getStyle", |_, this, ()| {
            with_widget(&this.binding, "Widget:getStyle", |widget| {
                let style = widget
                    .get_border_style()
                    .map_err(|e| runtime_error("Widget:getStyle", e))?;
                Ok(style.as_str().to_string())
            })
        });

        // -- setTitle --
        /// Sets the title of a border widget.
        /// @param title : string
        /// @return nil
        methods.add_method("setTitle", |_, this, title: String| {
            with_widget_mut(&this.binding, "Widget:setTitle", |widget| {
                widget
                    .set_title(title)
                    .map_err(|e| runtime_error("Widget:setTitle", e))
            })
        });

        // -- getTitle --
        /// Returns the title of a border widget.
        /// @return string
        methods.add_method("getTitle", |_, this, ()| {
            with_widget(&this.binding, "Widget:getTitle", |widget| {
                widget
                    .get_title()
                    .map_err(|e| runtime_error("Widget:getTitle", e))
            })
        });

        // -- addChild --
        /// Adds a child widget to a panel widget.
        /// @param child : Widget
        /// @return nil
        methods.add_method("addChild", |_, this, child_ud: LuaAnyUserData| {
            with_widget(&this.binding, "Widget:addChild", |widget| {
                if !widget.is_panel() {
                    return Err(runtime_error("Widget:addChild", "expected panel"));
                }
                Ok(())
            })?;

            let child = widget_handle_from_userdata(&child_ud)?;
            if Rc::ptr_eq(&this.binding, &child) {
                return Err(runtime_error("Widget:addChild", "panel cannot add itself"));
            }

            if let Some((terminal, panel_index)) = attached_location(&this.binding) {
                let child_index = match attached_location(&child) {
                    Some((child_terminal, child_index)) => {
                        if !Rc::ptr_eq(&child_terminal, &terminal) {
                            return Err(runtime_error(
                                "Widget:addChild",
                                "child widget is attached to another terminal",
                            ));
                        }
                        child_index
                    }
                    None => attach_widget(&terminal, &child)?,
                };
                let _ = terminal
                    .terminal
                    .borrow_mut()
                    .add_panel_child(panel_index, child_index);
                Ok(())
            } else {
                if attached_location(&child).is_some() {
                    return Err(runtime_error(
                        "Widget:addChild",
                        "cannot add an attached child to a detached panel",
                    ));
                }
                let mut binding_ref = this.binding.borrow_mut();
                if !binding_ref
                    .pending_children
                    .iter()
                    .any(|existing| Rc::ptr_eq(existing, &child))
                {
                    binding_ref.pending_children.push(child);
                }
                Ok(())
            }
        });

        // -- removeChild --
        /// Removes a child widget from a panel widget.
        /// @param child : Widget
        /// @return nil
        methods.add_method("removeChild", |_, this, child_ud: LuaAnyUserData| {
            with_widget(&this.binding, "Widget:removeChild", |widget| {
                if !widget.is_panel() {
                    return Err(runtime_error("Widget:removeChild", "expected panel"));
                }
                Ok(())
            })?;

            let child = widget_handle_from_userdata(&child_ud)?;
            if let Some((terminal, panel_index)) = attached_location(&this.binding) {
                if let Some(child_index) = attached_index_for_terminal(&child, &terminal) {
                    let _ = terminal
                        .terminal
                        .borrow_mut()
                        .remove_panel_child(panel_index, child_index);
                }
                Ok(())
            } else {
                let mut binding_ref = this.binding.borrow_mut();
                binding_ref
                    .pending_children
                    .retain(|existing| !Rc::ptr_eq(existing, &child));
                Ok(())
            }
        });

        // -- clearChildren --
        /// Removes all children from a panel widget.
        /// @return nil
        methods.add_method("clearChildren", |_, this, ()| {
            with_widget(&this.binding, "Widget:clearChildren", |widget| {
                if !widget.is_panel() {
                    return Err(runtime_error("Widget:clearChildren", "expected panel"));
                }
                Ok(())
            })?;

            if let Some((terminal, panel_index)) = attached_location(&this.binding) {
                let _ = terminal
                    .terminal
                    .borrow_mut()
                    .clear_panel_children(panel_index);
            } else {
                this.binding.borrow_mut().pending_children.clear();
            }
            Ok(())
        });

        // -- getChildCount --
        /// Returns the number of children in a panel widget.
        /// @return integer
        methods.add_method("getChildCount", |_, this, ()| {
            with_widget(&this.binding, "Widget:getChildCount", |widget| {
                if !widget.is_panel() {
                    return Err(runtime_error("Widget:getChildCount", "expected panel"));
                }
                Ok(())
            })?;

            if let Some((terminal, panel_index)) = attached_location(&this.binding) {
                let terminal_ref = terminal.terminal.borrow();
                match terminal_ref.get_widget(panel_index) {
                    Some(Widget {
                        kind: WidgetKind::Panel { children },
                        ..
                    }) => Ok(children.len()),
                    _ => Ok(0),
                }
            } else {
                Ok(this.binding.borrow().pending_children.len())
            }
        });

        // -- getChild --
        /// Returns a child widget from a panel by 1-based index, or nil.
        /// @param index : integer
        /// @return Widget?
        methods.add_method("getChild", |lua: &Lua, this, index: usize| {
            with_widget(&this.binding, "Widget:getChild", |widget| {
                if !widget.is_panel() {
                    return Err(runtime_error("Widget:getChild", "expected panel"));
                }
                Ok(())
            })?;

            if index == 0 {
                return Ok(LuaValue::Nil);
            }

            if let Some((terminal, panel_index)) = attached_location(&this.binding) {
                let child_handle = {
                    let terminal_ref = terminal.terminal.borrow();
                    match terminal_ref.get_widget(panel_index) {
                        Some(Widget {
                            kind: WidgetKind::Panel { children },
                            ..
                        }) if index <= children.len() => {
                            widget_handle_for_index(&terminal, children[index - 1])
                        }
                        _ => None,
                    }
                };
                match child_handle {
                    Some(binding) => Ok(LuaValue::UserData(
                        lua.create_userdata(LuaWidget { binding })?,
                    )),
                    None => Ok(LuaValue::Nil),
                }
            } else {
                let child = this
                    .binding
                    .borrow()
                    .pending_children
                    .get(index - 1)
                    .cloned();
                match child {
                    Some(binding) => Ok(LuaValue::UserData(
                        lua.create_userdata(LuaWidget { binding })?,
                    )),
                    None => Ok(LuaValue::Nil),
                }
            }
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.terminal` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newTerminal --
    /// Creates a new terminal grid with the given dimensions.
    /// @param cols : integer?
    /// @param rows : integer?
    /// @return Terminal
    let s = state.clone();
    tbl.set(
        "newTerminal",
        lua.create_function(move |lua, (cols, rows): (Option<usize>, Option<usize>)| {
            let binding = Rc::new(TerminalBinding {
                terminal: Rc::new(RefCell::new(Terminal::new(
                    cols.unwrap_or(80),
                    rows.unwrap_or(40),
                ))),
                shared_state: s.clone(),
                widget_handles: RefCell::new(HashMap::new()),
            });
            lua.create_userdata(LuaTerminal { binding })
        })?,
    )?;

    // -- newLabel --
    /// Creates a new label widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param text : string?
    /// @return Widget
    tbl.set(
        "newLabel",
        lua.create_function(
            move |lua, (col, row, text): (usize, usize, Option<String>)| {
                let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_label(
                    col,
                    row,
                    text.unwrap_or_default(),
                ))));
                lua.create_userdata(LuaWidget { binding })
            },
        )?,
    )?;

    // -- newButton --
    /// Creates a new button widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param width : integer
    /// @param height : integer?
    /// @param text : string?
    /// @return Widget
    tbl.set(
        "newButton",
        lua.create_function(
            move |lua,
                  (col, row, width, height, text): (
                usize,
                usize,
                usize,
                Option<usize>,
                Option<String>,
            )| {
                let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_button(
                    col,
                    row,
                    width,
                    height.unwrap_or(1),
                    text.unwrap_or_default(),
                ))));
                lua.create_userdata(LuaWidget { binding })
            },
        )?,
    )?;

    // -- newTextBox --
    /// Creates a new single-line text box widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param width : integer
    /// @return Widget
    tbl.set(
        "newTextBox",
        lua.create_function(move |lua, (col, row, width): (usize, usize, usize)| {
            let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_text_box(
                col, row, width,
            ))));
            lua.create_userdata(LuaWidget { binding })
        })?,
    )?;

    // -- newList --
    /// Creates a new scrollable list widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param width : integer
    /// @param height : integer
    /// @return Widget
    tbl.set(
        "newList",
        lua.create_function(
            move |lua, (col, row, width, height): (usize, usize, usize, usize)| {
                let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_list(
                    col, row, width, height,
                ))));
                lua.create_userdata(LuaWidget { binding })
            },
        )?,
    )?;

    // -- newBorder --
    /// Creates a new decorative border widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param width : integer
    /// @param height : integer
    /// @return Widget
    tbl.set(
        "newBorder",
        lua.create_function(
            move |lua, (col, row, width, height): (usize, usize, usize, usize)| {
                let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_border(
                    col, row, width, height,
                ))));
                lua.create_userdata(LuaWidget { binding })
            },
        )?,
    )?;

    // -- newPanel --
    /// Creates a new container panel widget at 1-based coordinates.
    /// @param col : integer
    /// @param row : integer
    /// @param width : integer?
    /// @param height : integer?
    /// @return Widget
    tbl.set(
        "newPanel",
        lua.create_function(
            move |lua, (col, row, width, height): (usize, usize, Option<usize>, Option<usize>)| {
                let binding = Rc::new(RefCell::new(WidgetBinding::new(Widget::new_panel(
                    col,
                    row,
                    width.unwrap_or(1),
                    height.unwrap_or(1),
                ))));
                lua.create_userdata(LuaWidget { binding })
            },
        )?,
    )?;

    luna.set("terminal", tbl)?;
    Ok(())
}
