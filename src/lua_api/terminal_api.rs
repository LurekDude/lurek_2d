//! `lurek.terminal` - Provides an in-game terminal emulator with command parsing, history, output buffering, and ANSI-style formatting.

use super::SharedState;
use crate::terminal::ansi::{parse_ansi_spans, strip_ansi_codes};
use crate::terminal::completion::CompletionEngine;
use crate::terminal::highlighter::{highlight_spans, HighlightRule};
use crate::terminal::{BorderStyle, Terminal, TerminalEvent, Widget, WidgetKind};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::{Rc, Weak};
/// Returns the active terminal cell width and height using the current font or fallback metrics.
fn font_cell_size(st: &SharedState) -> (f32, f32) {
    let key = st.active_font.or(st.default_font);
    if let Some(fk) = key {
        if let Some(font) = st.fonts.get(fk) {
            return (font.cell_width() as f32, font.size());
        }
    }
    (8.0, 14.0)
}
/// Returns the active cell size, preferring a terminal override over font metrics.
fn effective_cell_size(terminal: &Terminal, st: &SharedState) -> (f32, f32) {
    terminal
        .get_cell_size()
        .unwrap_or_else(|| font_cell_size(st))
}

/// Converts terminal dimensions and cell metrics into a logical window size.
fn terminal_window_size(terminal: &Terminal, st: &SharedState) -> (u32, u32) {
    let (cell_w, cell_h) = effective_cell_size(terminal, st);
    let width = (terminal.cols() as f32 * cell_w).ceil().max(1.0) as u32;
    let height = (terminal.rows() as f32 * cell_h).ceil().max(1.0) as u32;
    (width, height)
}

/// Stages a window resize so the terminal grid exactly fills the logical window.
fn queue_terminal_window_fit(binding: &TerminalBinding) {
    let (width, height) = {
        let st = binding.shared_state.borrow();
        let terminal = binding.terminal.borrow();
        terminal_window_size(&terminal, &st)
    };
    binding.shared_state.borrow_mut().window_state.pending_size = Some((width, height));
}
/// Stored Lua callback registry keys for widget interaction events.
#[derive(Default)]
struct WidgetCallbacks {
    on_click: Option<LuaRegistryKey>,
    on_change: Option<LuaRegistryKey>,
    on_select: Option<LuaRegistryKey>,
}
/// Tracks whether a widget is detached or attached to a specific terminal at a given index.
enum WidgetAttachment {
    Detached,
    Attached {
        terminal: Rc<TerminalBinding>,
        index: usize,
    },
}
/// Binds a Rust `Widget` to its Lua-side callbacks, pending children, and attachment state.
struct WidgetBinding {
    widget: Widget,
    callbacks: WidgetCallbacks,
    pending_children: Vec<Rc<RefCell<WidgetBinding>>>,
    attachment: WidgetAttachment,
}
impl WidgetBinding {
    /// Creates a detached widget binding with empty callbacks and no pending children.
    fn new(widget: Widget) -> Self {
        Self {
            widget,
            callbacks: WidgetCallbacks::default(),
            pending_children: Vec::new(),
            attachment: WidgetAttachment::Detached,
        }
    }
}
/// Associates a Rust `Terminal` with shared engine state and a map of live widget handles.
struct TerminalBinding {
    terminal: Rc<RefCell<Terminal>>,
    shared_state: Rc<RefCell<SharedState>>,
    widget_handles: RefCell<HashMap<usize, Weak<RefCell<WidgetBinding>>>>,
}
/// Builds a terminal API runtime error tagged with the Lua-visible method name.
fn runtime_error(method: &str, message: &str) -> LuaError {
    LuaError::RuntimeError(format!("{method}: {message}"))
}
/// Builds the standard error used when a widget belongs to a different terminal.
fn wrong_terminal(method: &str) -> LuaError {
    runtime_error(method, "widget is not attached to this terminal")
}
/// Extracts a widget binding handle from Lua widget userdata.
fn widget_handle_from_userdata(userdata: &LuaAnyUserData) -> LuaResult<Rc<RefCell<WidgetBinding>>> {
    let widget = userdata.borrow::<LuaWidget>()?;
    Ok(widget.binding.clone())
}
/// Returns the attached terminal and widget index for a binding when it is currently mounted.
fn attached_location(binding: &Rc<RefCell<WidgetBinding>>) -> Option<(Rc<TerminalBinding>, usize)> {
    let binding_ref = binding.borrow();
    match &binding_ref.attachment {
        WidgetAttachment::Attached { terminal, index } => Some((terminal.clone(), *index)),
        WidgetAttachment::Detached => None,
    }
}
/// Returns a widget index only when the binding is attached to the requested terminal.
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
/// Resolves a live widget binding for a terminal index and removes stale weak handles.
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
/// Runs a read-only action against the latest widget state whether it is attached or detached.
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
/// Runs a mutable action against the latest widget state whether it is attached or detached.
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
/// Stores or clears one Lua callback registry key in a widget callback slot.
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
/// Identifies which widget callback to dispatch.
enum CallbackKind {
    /// Button click callback slot.
    Click,
    /// Text or value change callback slot.
    Change,
    /// Selection change callback slot.
    Select,
}
/// Invokes the requested widget callback when the binding has one registered.
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
/// Dispatches terminal widget events back into their corresponding Lua callbacks.
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
/// Copies the latest terminal widget state back into a detached binding snapshot.
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
/// Reindexes stored widget handles after one widget has been removed from a terminal.
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
/// Attaches a detached widget binding to a terminal and returns its widget index.
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
/// Detaches one widget from a terminal and restores its local snapshot state.
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
/// Detaches every widget from a terminal and clears the live widget registry.
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
/// Converts an optional Lua numeric value into a non-negative `usize` with zero fallback.
fn usize_from_value(value: Option<LuaValue>) -> usize {
    match value {
        Some(LuaValue::Integer(value)) => value.max(0) as usize,
        Some(LuaValue::Number(value)) => value.max(0.0) as usize,
        _ => 0,
    }
}
/// Converts an optional Lua numeric value into an `f32` when possible.
fn number_from_value(value: Option<LuaValue>) -> Option<f32> {
    match value {
        Some(LuaValue::Integer(value)) => Some(value as f32),
        Some(LuaValue::Number(value)) => Some(value as f32),
        _ => None,
    }
}
/// Lua-side userdata wrapping a terminal emulator grid with cell access, widgets, input, and rendering.
#[derive(Clone)]
struct LuaTerminal {
    binding: Rc<TerminalBinding>,
}
impl LuaUserData for LuaTerminal {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- set --
        /// Writes a character with foreground and background color to a specific cell in the terminal grid.
        /// @param | col | integer | Column index (1-based).
        /// @param | row | integer | Row index (1-based).
        /// @param | ch | string|number | Character as a string or Unicode codepoint.
        /// @param | fr | number? | Foreground red (0-1, default 1).
        /// @param | fg | number? | Foreground green (0-1, default 1).
        /// @param | fb | number? | Foreground blue (0-1, default 1).
        /// @param | fa | number? | Foreground alpha (0-1, default 1).
        /// @param | br | number? | Background red (0-1, default 0).
        /// @param | bg | number? | Background green (0-1, default 0).
        /// @param | bb | number? | Background blue (0-1, default 0).
        /// @param | ba | number? | Background alpha (0-1, default 0).
        /// @return | nil | No value is returned.
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
        /// Reads the character and colors at a specific cell in the terminal grid.
        /// @param | col | integer | Column index (1-based).
        /// @param | row | integer | Row index (1-based).
        /// @return | integer, number, number, number, number, number, number, number, number | Character codepoint, fg RGBA, bg RGBA.
        methods.add_method("get", |_, this, (col, row): (usize, usize)| {
            let cell = this.binding.terminal.borrow().get(col, row);
            Ok((
                cell.ch, cell.fg[0], cell.fg[1], cell.fg[2], cell.fg[3], cell.bg[0], cell.bg[1],
                cell.bg[2], cell.bg[3],
            ))
        });
        // -- clear --
        /// Clears all cells in the terminal grid, resetting characters and colors to defaults.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.binding.terminal.borrow_mut().clear();
            Ok(())
        });
        // -- print --
        /// Writes text to the terminal grid starting at a specific cell.
        /// @param | col | integer | Column index (1-based) where writing starts.
        /// @param | row | integer | Row index (1-based) where writing starts.
        /// @param | text | string | Text to write into consecutive cells.
        /// @return | nil | No value is returned.
        methods.add_method(
            "print",
            |_, this, (col, row, text): (usize, usize, String)| {
                this.binding.terminal.borrow_mut().print(col, row, &text);
                Ok(())
            },
        );
        // -- getDimensions --
        /// Returns the number of columns and rows in the terminal grid.
        /// @return | integer, integer | Column count, row count.
        methods.add_method("getDimensions", |_, this, ()| {
            Ok(this.binding.terminal.borrow().get_dimensions())
        });
        // -- addWidget --
        /// Attaches a widget to this terminal so it is rendered and receives input events.
        /// @param | widget | LWidget | The widget to attach.
        /// @return | nil | No value is returned.
        methods.add_method("addWidget", |_, this, widget_ud: LuaAnyUserData| {
            let widget = widget_handle_from_userdata(&widget_ud)?;
            let _ = attach_widget(&this.binding, &widget)?;
            Ok(())
        });
        // -- removeWidget --
        /// Detaches a widget from this terminal, removing it from rendering and input handling.
        /// @param | widget | LWidget | The widget to detach.
        /// @return | nil | No value is returned.
        methods.add_method("removeWidget", |_, this, widget_ud: LuaAnyUserData| {
            let widget = widget_handle_from_userdata(&widget_ud)?;
            let _ = remove_attached_widget(&this.binding, &widget)?;
            Ok(())
        });
        // -- clearWidgets --
        /// Removes all attached widgets from this terminal at once.
        /// @return | nil | No value is returned.
        methods.add_method("clearWidgets", |_, this, ()| {
            clear_attached_widgets(&this.binding);
            Ok(())
        });
        // -- getWidgetCount --
        /// Returns the number of widgets currently attached to this terminal.
        /// @return | integer | Widget count.
        methods.add_method("getWidgetCount", |_, this, ()| {
            Ok(this.binding.terminal.borrow().get_widget_count())
        });
        // -- setFocus --
        /// Sets which widget currently has keyboard focus, or clears focus when nil is passed.
        /// @param | widget | LWidget? | The widget to focus, or nil to clear focus.
        /// @return | nil | No value is returned.
        methods.add_method("setFocus", |_, this, value: LuaValue| match value {
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
        });
        // -- getFocused --
        /// Returns the widget that currently has keyboard focus, or nil if no widget is focused.
        /// @return | LWidget | The focused widget, or nil.
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
        /// Forwards a key press event to the terminal for widget input processing.
        /// @param | key | string | The key name (e.g. "return", "backspace", "left").
        /// @return | boolean | True if the terminal consumed the key event.
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
        /// Forwards a text input event to the terminal for character entry into focused widgets.
        /// @param | text | string | The text characters entered.
        /// @return | boolean | True if the terminal consumed the text input.
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
        /// Forwards a mouse press event to the terminal, converting pixel coordinates to cell coordinates.
        /// @param | px | number | Pixel X position of the mouse click.
        /// @param | py | number | Pixel Y position of the mouse click.
        /// @param | button | integer? | Mouse button index (default 1 for left).
        /// @return | nil | No value is returned.
        methods.add_method(
            "mousepressed",
            |lua, this, (px, py, button): (f32, f32, Option<usize>)| {
                let (cell_w, cell_h) = {
                    let st = this.binding.shared_state.borrow();
                    let terminal = this.binding.terminal.borrow();
                    effective_cell_size(&terminal, &st)
                };
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
        // -- render --
        /// Renders the terminal grid and widgets and stages a window size matching the grid and active cell size.
        /// @param | x | number? | Screen X offset in pixels (default 0).
        /// @param | y | number? | Screen Y offset in pixels (default 0).
        /// @return | nil | No value is returned.
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let st = this.binding.shared_state.borrow();
            let font_key = st.active_font.or(st.default_font);
            if let Some(fk) = font_key {
                let terminal = this.binding.terminal.borrow();
                let (cell_w, cell_h) = effective_cell_size(&terminal, &st);
                let (target_w, target_h) = terminal_window_size(&terminal, &st);
                let commands = terminal.build_render_commands(
                    x.unwrap_or(0.0),
                    y.unwrap_or(0.0),
                    cell_w,
                    cell_h,
                    fk,
                );
                drop(terminal);
                drop(st);
                let mut shared = this.binding.shared_state.borrow_mut();
                shared.window_state.pending_size = Some((target_w, target_h));
                shared.render_commands.extend(commands);
            }
            Ok(())
        });
        // -- setFont --
        /// Selects the nearest built-in bitmap font by pixel height and refits the window to the terminal grid.
        /// @param | height | integer | Desired font height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setFont", |_, this, height: u32| {
            let idx = crate::render::Font::nearest_size(height);
            let st = this.binding.shared_state.borrow();
            if let Some(key) = st.default_fonts[idx] {
                drop(st);
                this.binding.shared_state.borrow_mut().active_font = Some(key);
                queue_terminal_window_fit(&this.binding);
                Ok(())
            } else {
                Err(LuaError::RuntimeError(
                    "terminal:setFont: built-in fonts not loaded".into(),
                ))
            }
        });
        // -- setCellSize --
        /// Overrides the cell width and height used for rendering this terminal grid and refits the window.
        /// @param | w | number | Cell width in pixels.
        /// @param | h | number | Cell height in pixels.
        /// @return | nil | No value is returned.
        methods.add_method("setCellSize", |_, this, (w, h): (f32, f32)| {
            this.binding.terminal.borrow_mut().set_cell_size(w, h);
            queue_terminal_window_fit(&this.binding);
            Ok(())
        });
        // -- resetCellSize --
        /// Removes any custom cell size override, reverting to the active font metrics and refitting the window.
        /// @return | nil | No value is returned.
        methods.add_method("resetCellSize", |_, this, ()| {
            this.binding.terminal.borrow_mut().reset_cell_size();
            queue_terminal_window_fit(&this.binding);
            Ok(())
        });
        // -- getCellSize --
        /// Returns the active terminal cell width and height in pixels, using custom override or font metrics.
        /// @return | number, number | Cell width and height in pixels.
        methods.add_method("getCellSize", |_, this, ()| {
            let st = this.binding.shared_state.borrow();
            let terminal = this.binding.terminal.borrow();
            Ok(effective_cell_size(&terminal, &st))
        });
        // -- autoResize --
        /// Requests the window to resize so it exactly fits the terminal grid at the current cell size.
        /// @return | nil | No value is returned.
        methods.add_method("autoResize", |_, this, ()| {
            queue_terminal_window_fit(&this.binding);
            Ok(())
        });
        // -- type --
        /// Returns the type name string "LTerminal".
        /// @return | string | Always "LTerminal".
        methods.add_method("type", |_, _, ()| Ok("LTerminal"));
        // -- typeOf --
        /// Checks whether this object matches a given type name. Accepts "LTerminal" or "Object".
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTerminal" || name == "Object")
        });
    }
}
/// Lua-side userdata wrapping a terminal widget (label, button, text box, list, border, or panel).
#[derive(Clone)]
struct LuaWidget {
    binding: Rc<RefCell<WidgetBinding>>,
}
impl LuaUserData for LuaWidget {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setPosition --
        /// Sets the widget position in 1-based cell coordinates within the terminal grid.
        /// @param | col | integer | Column index (1-based).
        /// @param | row | integer | Row index (1-based).
        /// @return | nil | No value is returned.
        methods.add_method("setPosition", |_, this, (col, row): (usize, usize)| {
            with_widget_mut(&this.binding, "Widget:setPosition", |widget| {
                widget.base.set_position_1based(col, row);
                Ok(())
            })
        });
        // -- getPosition --
        /// Returns the widget position as 1-based column and row.
        /// @return | integer, integer | Column, row.
        methods.add_method("getPosition", |_, this, ()| {
            with_widget(&this.binding, "Widget:getPosition", |widget| {
                Ok(widget.base.position_1based())
            })
        });
        // -- setSize --
        /// Sets the widget dimensions in cell units, clamped to a minimum of 1x1.
        /// @param | width | integer | Width in cells.
        /// @param | height | integer | Height in cells.
        /// @return | nil | No value is returned.
        methods.add_method("setSize", |_, this, (width, height): (usize, usize)| {
            with_widget_mut(&this.binding, "Widget:setSize", |widget| {
                widget.base.width = width.max(1);
                widget.base.height = height.max(1);
                Ok(())
            })
        });
        // -- getSize --
        /// Returns the widget dimensions as width and height in cell units.
        /// @return | integer, integer | Width, height.
        methods.add_method("getSize", |_, this, ()| {
            with_widget(&this.binding, "Widget:getSize", |widget| {
                Ok((widget.base.width, widget.base.height))
            })
        });
        // -- setVisible --
        /// Controls whether the widget is drawn and receives input events.
        /// @param | visible | boolean | True to show, false to hide.
        /// @return | nil | No value is returned.
        methods.add_method("setVisible", |_, this, is_visible: bool| {
            with_widget_mut(&this.binding, "Widget:setVisible", |widget| {
                widget.base.visible = is_visible;
                Ok(())
            })
        });
        // -- isVisible --
        /// Returns whether the widget is currently visible.
        /// @return | boolean | True if visible.
        methods.add_method("isVisible", |_, this, ()| {
            with_widget(&this.binding, "Widget:isVisible", |widget| {
                Ok(widget.base.visible)
            })
        });
        // -- setEnabled --
        /// Controls whether the widget accepts user interaction (clicks, typing).
        /// @param | enabled | boolean | True to enable, false to disable.
        /// @return | nil | No value is returned.
        methods.add_method("setEnabled", |_, this, is_enabled: bool| {
            with_widget_mut(&this.binding, "Widget:setEnabled", |widget| {
                widget.base.enabled = is_enabled;
                Ok(())
            })
        });
        // -- isEnabled --
        /// Returns whether the widget is currently enabled for user interaction.
        /// @return | boolean | True if enabled.
        methods.add_method("isEnabled", |_, this, ()| {
            with_widget(&this.binding, "Widget:isEnabled", |widget| {
                Ok(widget.base.enabled)
            })
        });
        // -- setTag --
        /// Assigns an arbitrary string tag to the widget for identification or grouping.
        /// @param | tag | string | The tag value.
        /// @return | nil | No value is returned.
        methods.add_method("setTag", |_, this, new_tag: String| {
            with_widget_mut(&this.binding, "Widget:setTag", |widget| {
                widget.base.tag = new_tag;
                Ok(())
            })
        });
        // -- getTag --
        /// Returns the current tag string assigned to the widget.
        /// @return | string | The tag value.
        methods.add_method("getTag", |_, this, ()| {
            with_widget(&this.binding, "Widget:getTag", |widget| {
                Ok(widget.base.tag.clone())
            })
        });
        // -- setText --
        /// Sets the display text of a label, button, or text box widget. Fires the onChange callback if the text actually changed.
        /// @param | text | string | The new text content.
        /// @return | nil | No value is returned.
        methods.add_method("setText", |lua, this, text: String| {
            let changed = with_widget_mut(&this.binding, "Widget:setText", |widget| {
                widget
                    .set_text(text)
                    .map_err(|e| runtime_error("Widget:setText", e))
            })?;
            if changed {
                dispatch_callback(lua, &this.binding, CallbackKind::Change)?;
            }
            Ok(())
        });
        // -- getText --
        /// Returns the current text content of a label, button, or text box widget.
        /// @return | string | The widget text.
        methods.add_method("getText", |_, this, ()| {
            with_widget(&this.binding, "Widget:getText", |widget| {
                widget
                    .get_text()
                    .map_err(|e| runtime_error("Widget:getText", e))
            })
        });
        // -- setColor --
        /// Sets the foreground color of the widget as RGBA components (0-1 range).
        /// @param | r | number | Red channel.
        /// @param | g | number | Green channel.
        /// @param | b | number | Blue channel.
        /// @param | a | number? | Alpha channel (default 1).
        /// @return | nil | No value is returned.
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
        /// Returns the foreground color of the widget as RGBA components.
        /// @return | number, number, number, number | Red, green, blue, and alpha channels.
        methods.add_method("getColor", |_, this, ()| {
            with_widget(&this.binding, "Widget:getColor", |widget| {
                let c = widget
                    .get_color()
                    .map_err(|e| runtime_error("Widget:getColor", e))?;
                Ok((c[0], c[1], c[2], c[3]))
            })
        });
        // -- setOnClick --
        /// Registers a callback function invoked when a button widget is clicked. Only valid for button widgets.
        /// @param | callback | function? | The click handler, or nil to clear.
        /// @return | nil | No value is returned.
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
        /// Sets the maximum number of characters allowed in a text box widget.
        /// @param | maxLength | integer | Maximum character count.
        /// @return | nil | No value is returned.
        methods.add_method("setMaxLength", |_, this, max_length: usize| {
            with_widget_mut(&this.binding, "Widget:setMaxLength", |widget| {
                widget
                    .set_max_length(max_length)
                    .map_err(|e| runtime_error("Widget:setMaxLength", e))
            })
        });
        // -- getMaxLength --
        /// Returns the maximum character limit of a text box widget.
        /// @return | integer | Maximum character count.
        methods.add_method("getMaxLength", |_, this, ()| {
            with_widget(&this.binding, "Widget:getMaxLength", |widget| {
                widget
                    .get_max_length()
                    .map_err(|e| runtime_error("Widget:getMaxLength", e))
            })
        });
        // -- setOnChange --
        /// Registers a callback function invoked when the text content of a text box widget changes. Only valid for text box widgets.
        /// @param | callback | function? | The change handler, or nil to clear.
        /// @return | nil | No value is returned.
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
        /// Appends a text item to a list widget.
        /// @param | item | string | The item text to add.
        /// @return | nil | No value is returned.
        methods.add_method("addItem", |_, this, item: String| {
            with_widget_mut(&this.binding, "Widget:addItem", |widget| {
                widget
                    .add_item(item)
                    .map_err(|e| runtime_error("Widget:addItem", e))
            })
        });
        // -- removeItem --
        /// Removes a list item by its 1-based index.
        /// @param | index | integer | 1-based item index to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeItem", |_, this, index: usize| {
            with_widget_mut(&this.binding, "Widget:removeItem", |widget| {
                widget
                    .remove_item_1based(index)
                    .map_err(|e| runtime_error("Widget:removeItem", e))
            })
        });
        // -- clearItems --
        /// Removes all items from a list widget.
        /// @return | nil | No value is returned.
        methods.add_method("clearItems", |_, this, ()| {
            with_widget_mut(&this.binding, "Widget:clearItems", |widget| {
                widget
                    .clear_items()
                    .map_err(|e| runtime_error("Widget:clearItems", e))
            })
        });
        // -- getItemCount --
        /// Returns the number of items in a list widget.
        /// @return | integer | Item count.
        methods.add_method("getItemCount", |_, this, ()| {
            with_widget(&this.binding, "Widget:getItemCount", |widget| {
                widget
                    .get_item_count()
                    .map_err(|e| runtime_error("Widget:getItemCount", e))
            })
        });
        // -- getItem --
        /// Returns the text of a list item by its 1-based index.
        /// @param | index | integer | 1-based item index.
        /// @return | string | The item text.
        methods.add_method("getItem", |_, this, index: usize| {
            with_widget(&this.binding, "Widget:getItem", |widget| {
                widget
                    .get_item_1based(index)
                    .map_err(|e| runtime_error("Widget:getItem", e))
            })
        });
        // -- setSelected --
        /// Sets the currently selected item in a list widget by 1-based index, or clears the selection with nil. Fires the onSelect callback if changed.
        /// @param | index | integer? | 1-based item index, or nil to clear selection.
        /// @return | nil | No value is returned.
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
        /// Returns the 1-based index of the currently selected list item, or nil if nothing is selected.
        /// @return | integer | Selected item index, or nil.
        methods.add_method("getSelected", |_, this, ()| {
            with_widget(&this.binding, "Widget:getSelected", |widget| {
                widget
                    .get_selected_1based()
                    .map_err(|e| runtime_error("Widget:getSelected", e))
            })
        });
        // -- setOnSelect --
        /// Registers a callback function invoked when the selected item in a list widget changes. Only valid for list widgets.
        /// @param | callback | function? | The selection handler, or nil to clear.
        /// @return | nil | No value is returned.
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
        /// Sets the border drawing style for a border or panel widget.
        /// @param | styleName | string | Border style name (e.g. "single", "double", "rounded", "heavy", "none").
        /// @return | nil | No value is returned.
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
        /// Returns the current border style name of a border or panel widget.
        /// @return | string | The border style name.
        methods.add_method("getStyle", |_, this, ()| {
            with_widget(&this.binding, "Widget:getStyle", |widget| {
                let style = widget
                    .get_border_style()
                    .map_err(|e| runtime_error("Widget:getStyle", e))?;
                Ok(style.as_str().to_string())
            })
        });
        // -- setTitle --
        /// Sets the title text displayed in the border of a border or panel widget.
        /// @param | title | string | The title text.
        /// @return | nil | No value is returned.
        methods.add_method("setTitle", |_, this, title: String| {
            with_widget_mut(&this.binding, "Widget:setTitle", |widget| {
                widget
                    .set_title(title)
                    .map_err(|e| runtime_error("Widget:setTitle", e))
            })
        });
        // -- getTitle --
        /// Returns the current title text of a border or panel widget.
        /// @return | string | The title text.
        methods.add_method("getTitle", |_, this, ()| {
            with_widget(&this.binding, "Widget:getTitle", |widget| {
                widget
                    .get_title()
                    .map_err(|e| runtime_error("Widget:getTitle", e))
            })
        });
        // -- addChild --
        /// Adds a child widget to a panel widget. The child becomes part of the panel layout and rendering.
        /// @param | child | LWidget | The child widget to add.
        /// @return | nil | No value is returned.
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
        /// Removes a child widget from a panel, detaching it from the panel layout.
        /// @param | child | LWidget | The child widget to remove.
        /// @return | nil | No value is returned.
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
        /// Removes all child widgets from a panel widget.
        /// @return | nil | No value is returned.
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
        /// Returns the number of child widgets in a panel widget.
        /// @return | integer | Child count.
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
        /// Returns a child widget from a panel by its 1-based index, or nil if the index is out of range.
        /// @param | index | integer | 1-based child index.
        /// @return | LWidget | The child widget, or nil.
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
        // -- type --
        /// Returns the type name string "LWidget".
        /// @return | string | Always "LWidget".
        methods.add_method("type", |_, _, ()| Ok("LWidget"));
        // -- typeOf --
        /// Checks whether this object matches a given type name. Accepts "LWidget" or "Object".
        /// @param | name | string | Type name to test against.
        /// @return | boolean | True if the name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LWidget" || name == "Object")
        });
    }
}
/// Registers the `lurek.terminal` module on the given Lua table, exposing terminal creation, widget factories, scrollback, command history, ANSI parsing, syntax highlighting, and tab completion.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    // -- newTerminal --
    /// Creates a new terminal emulator grid and stages a window size that fits its active cell metrics.
    /// @param | cols | integer? | Number of columns (default 80).
    /// @param | rows | integer? | Number of rows (default 40).
    /// @return | LTerminal | The new terminal object.
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
            queue_terminal_window_fit(&binding);
            lua.create_userdata(LuaTerminal { binding })
        })?,
    )?;
    // -- newLabel --
    /// Creates a new label widget that displays static text at the given cell position.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | text | string? | Initial text (default empty).
    /// @return | LWidget | The new label widget.
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
    /// Creates a new clickable button widget with the given position, size, and label text.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | width | integer | Button width in cells.
    /// @param | height | integer? | Button height in cells (default 1).
    /// @param | text | string? | Button label text (default empty).
    /// @return | LWidget | The new button widget.
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
    /// Creates a new single-line text input widget at the given position with a fixed width.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | width | integer | Input field width in cells.
    /// @return | LWidget | The new text box widget.
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
    /// Creates a new scrollable list widget for displaying and selecting items.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | width | integer | List width in cells.
    /// @param | height | integer | List height in cells (visible rows).
    /// @return | LWidget | The new list widget.
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
    /// Creates a new decorative border widget drawn using box-drawing characters.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | width | integer | Border width in cells.
    /// @param | height | integer | Border height in cells.
    /// @return | LWidget | The new border widget.
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
    /// Creates a new panel widget that can contain child widgets for grouped layout.
    /// @param | col | integer | Column position (1-based).
    /// @param | row | integer | Row position (1-based).
    /// @param | width | integer? | Panel width in cells (default 1).
    /// @param | height | integer? | Panel height in cells (default 1).
    /// @return | LWidget | The new panel widget.
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
    let s = state.clone();
    // -- pushScrollback --
    /// Appends a line of text to the terminal scrollback buffer for later retrieval.
    /// @param | terminal | LTerminal | The terminal to push to.
    /// @param | line | string | The text line to append.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, (term_ud, line): (LuaAnyUserData, String)| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            let _ = s.borrow();
            term_ref
                .binding
                .terminal
                .borrow_mut()
                .push_scrollback(&line);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- getScrollback --
    /// Retrieves a range of lines from the terminal scrollback buffer.
    /// @param | terminal | LTerminal | The terminal to read from.
    /// @param | offset | integer | 0-based offset from the newest line.
    /// @param | count | integer | Number of lines to retrieve.
    /// @return | table | Array of scrollback line strings.
    tbl.set(
        "getScrollback",
        lua.create_function(
            move |lua, (term_ud, offset, count): (LuaAnyUserData, usize, usize)| {
                let term_ref = term_ud.borrow::<LuaTerminal>()?;
                let _ = s.borrow();
                let binding = term_ref.binding.terminal.borrow_mut();
                let lines = binding.get_scrollback(offset, count);
                let result = lua.create_table()?;
                for (i, l) in lines.iter().enumerate() {
                    result.set(i + 1, l.to_string())?;
                }
                Ok(result)
            },
        )?,
    )?;
    // -- scrollbackLen --
    /// Returns the number of lines currently stored in the terminal scrollback buffer.
    /// @param | terminal | LTerminal | The terminal to query.
    /// @return | integer | Line count.
    tbl.set(
        "scrollbackLen",
        lua.create_function(|_, term_ud: LuaAnyUserData| {
            let term_ref = term_ud.borrow::<LuaTerminal>()?;
            let binding = term_ref.binding.terminal.borrow_mut();
            Ok(binding.scrollback_len())
        })?,
    )?;
    // -- setScrollbackCap --
    /// Sets the maximum number of lines retained in the terminal scrollback buffer. Older lines are discarded when the cap is exceeded.
    /// @param | terminal | LTerminal | The terminal to configure.
    /// @param | cap | integer | Maximum number of scrollback lines.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(|_, (term_ud, cap): (LuaAnyUserData, usize)| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            term_ref
                .binding
                .terminal
                .borrow_mut()
                .set_scrollback_cap(cap);
            Ok(())
        })?,
    )?;
    // -- pushCmdHistory --
    /// Appends a command string to the terminal command history for up/down arrow recall.
    /// @param | terminal | LTerminal | The terminal to push to.
    /// @param | cmd | string | The command string to store.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(|_, (term_ud, cmd): (LuaAnyUserData, String)| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            term_ref
                .binding
                .terminal
                .borrow_mut()
                .push_cmd_history(&cmd);
            Ok(())
        })?,
    )?;
    // -- prevCmd --
    /// Navigates backward in the terminal command history, returning the previous command or nil if at the start.
    /// @param | terminal | LTerminal | The terminal to navigate.
    /// @return | string | The previous command, or nil.
    tbl.set(
        "prevCmd",
        lua.create_function(|_, term_ud: LuaAnyUserData| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            let mut binding = term_ref.binding.terminal.borrow_mut();
            Ok(binding.prev_cmd().map(|s| s.to_owned()))
        })?,
    )?;
    // -- nextCmd --
    /// Navigates forward in the terminal command history, returning the next command or nil if at the end.
    /// @param | terminal | LTerminal | The terminal to navigate.
    /// @return | string | The next command, or nil.
    tbl.set(
        "nextCmd",
        lua.create_function(|_, term_ud: LuaAnyUserData| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            let mut binding = term_ref.binding.terminal.borrow_mut();
            Ok(binding.next_cmd().map(|s| s.to_owned()))
        })?,
    )?;
    // -- cmdHistoryLen --
    /// Returns the number of commands currently stored in the terminal command history.
    /// @param | terminal | LTerminal | The terminal to query.
    /// @return | integer | History entry count.
    tbl.set(
        "cmdHistoryLen",
        lua.create_function(|_, term_ud: LuaAnyUserData| {
            let term_ref = term_ud.borrow::<LuaTerminal>()?;
            let binding = term_ref.binding.terminal.borrow_mut();
            Ok(binding.cmd_history_len())
        })?,
    )?;
    // -- clearCmdHistory --
    /// Removes all entries from the terminal command history.
    /// @param | terminal | LTerminal | The terminal to clear.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(|_, term_ud: LuaAnyUserData| {
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            term_ref.binding.terminal.borrow_mut().clear_cmd_history();
            Ok(())
        })?,
    )?;
    // -- applyTheme --
    /// Applies a named color theme to the terminal, setting default foreground and background colors.
    /// @param | terminal | LTerminal | The terminal to theme.
    /// @param | theme | string | Theme name: "solarized_dark", "solarized_light", "monokai", "dracula", or "nord".
    /// @return | nil | No value is returned.
    tbl.set("applyTheme", lua.create_function(|_, (term_ud, theme): (LuaAnyUserData, String)| {
            let (fr, fg_c, fb, br, bg_c, bb): (u8, u8, u8, u8, u8, u8) = match theme.as_str() {
                "solarized_dark" => (131, 148, 150, 0, 43, 54),
                "solarized_light" => (101, 123, 131, 253, 246, 227),
                "monokai" => (248, 248, 242, 39, 40, 34),
                "dracula" => (248, 248, 242, 40, 42, 54),
                "nord" => (236, 239, 244, 46, 52, 64),
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "unknown theme '{other}' â€” available: solarized_dark, solarized_light, monokai, dracula, nord"
                    )));
                }
            };
            let fg = [fr as f32 / 255.0, fg_c as f32 / 255.0, fb as f32 / 255.0, 1.0];
            let bg = [br as f32 / 255.0, bg_c as f32 / 255.0, bb as f32 / 255.0, 1.0];
            let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
            term_ref.binding.terminal.borrow_mut().set_default_colors(fg, bg);
            Ok(())
        })?,
    )?;
    // -- printHighlighted --
    /// Renders syntax-highlighted text onto the terminal grid using a table of highlight rules with regex patterns and colors.
    /// @param | terminal | LTerminal | The terminal to print to.
    /// @param | col | integer | Starting column (1-based).
    /// @param | row | integer | Row to print on (1-based).
    /// @param | text | string | The text to highlight.
    /// @param | rules | table | Array of rule tables, each with `pattern` (string), `fg` (table {r,g,b} 0-255), and optional `bg` (table {r,g,b} 0-255).
    /// @return | nil | No value is returned.
    tbl.set(
        "printHighlighted",
        lua.create_function(
            |_,
             (term_ud, col, row, text, rules_t): (
                LuaAnyUserData,
                usize,
                usize,
                String,
                LuaTable,
            )| {
                let mut rules: Vec<HighlightRule> = Vec::new();
                for pair in rules_t.sequence_values::<LuaTable>() {
                    let rt = pair?;
                    let pattern: String = rt.get("pattern")?;
                    let fg_t: LuaTable = rt.get("fg")?;
                    let fr: u8 = fg_t.get(1)?;
                    let fg_c: u8 = fg_t.get(2)?;
                    let fb: u8 = fg_t.get(3)?;
                    let bg_opt: Option<LuaTable> = rt.get("bg").ok();
                    let bg = bg_opt.and_then(|bt| {
                        let br: u8 = bt.get(1).ok()?;
                        let bg_c: u8 = bt.get(2).ok()?;
                        let bb: u8 = bt.get(3).ok()?;
                        Some([
                            br as f32 / 255.0,
                            bg_c as f32 / 255.0,
                            bb as f32 / 255.0,
                            1.0,
                        ])
                    });
                    rules.push(HighlightRule {
                        pattern,
                        fg: [
                            fr as f32 / 255.0,
                            fg_c as f32 / 255.0,
                            fb as f32 / 255.0,
                            1.0,
                        ],
                        bg,
                    });
                }
                let default_fg = [1.0f32, 1.0, 1.0, 1.0];
                let spans = highlight_spans(&text, &rules, default_fg);
                let term_ref = term_ud.borrow_mut::<LuaTerminal>()?;
                let mut cur_col = col;
                for span in &spans {
                    term_ref
                        .binding
                        .terminal
                        .borrow_mut()
                        .print_colored(cur_col, row, &span.text, span.fg, span.bg);
                    cur_col += span.text.chars().count();
                }
                Ok(())
            },
        )?,
    )?;
    // -- stripAnsi --
    /// Removes all ANSI escape sequences from a string, returning plain text.
    /// @param | text | string | Input string with ANSI codes.
    /// @return | string | Clean text without escape sequences.
    tbl.set(
        "stripAnsi",
        lua.create_function(|_, text: String| Ok(strip_ansi_codes(&text)))?,
    )?;
    // -- parseAnsi --
    /// Parses ANSI escape sequences in a string into an array of span tables with text, bold, fg, and bg fields.
    /// @param | text | string | Input string with ANSI codes.
    /// @return | table | Array of span tables: { text=string, bold=boolean, fg?={r,g,b}, bg?={r,g,b} }.
    tbl.set(
        "parseAnsi",
        lua.create_function(|lua, text: String| {
            let spans = parse_ansi_spans(&text);
            let arr = lua.create_table()?;
            for (i, span) in spans.iter().enumerate() {
                let t = lua.create_table()?;
                /// Performs the 'text' operation.
                /// @return | nil | No value is returned.
                t.set("text", span.text.clone())?;
                /// Performs the 'bold' operation.
                /// @return | nil | No value is returned.
                t.set("bold", span.bold)?;
                if let Some(ref c) = span.fg {
                    let ct = lua.create_table()?;
                    /// Performs the 'r' operation.
                    /// @return | nil | No value is returned.
                    ct.set("r", c.r)?;
                    /// Performs the 'g' operation.
                    /// @return | nil | No value is returned.
                    ct.set("g", c.g)?;
                    /// Performs the 'b' operation.
                    /// @return | nil | No value is returned.
                    ct.set("b", c.b)?;
                    /// Performs the 'fg' operation.
                    /// @return | nil | No value is returned.
                    t.set("fg", ct)?;
                }
                if let Some(ref c) = span.bg {
                    let ct = lua.create_table()?;
                    /// Performs the 'r' operation.
                    /// @return | nil | No value is returned.
                    ct.set("r", c.r)?;
                    /// Performs the 'g' operation.
                    /// @return | nil | No value is returned.
                    ct.set("g", c.g)?;
                    /// Performs the 'b' operation.
                    /// @return | nil | No value is returned.
                    ct.set("b", c.b)?;
                    /// Performs the 'bg' operation.
                    /// @return | nil | No value is returned.
                    t.set("bg", ct)?;
                }
                arr.set(i + 1, t)?;
            }
            Ok(arr)
        })?,
    )?;
    // -- printAnsi --
    /// Renders ANSI-colored text directly onto the terminal grid at the given cell position.
    /// @param | terminal | LTerminal | The terminal to print to.
    /// @param | col | integer | Starting column (1-based).
    /// @param | row | integer | Row to print on (1-based).
    /// @param | text | string | Text containing ANSI escape sequences.
    /// @return | nil | No value is returned.
    tbl.set(
        "printAnsi",
        lua.create_function(
            |_, (t_ud, col, row, text): (LuaAnyUserData, i64, i64, String)| {
                let t = t_ud.borrow_mut::<LuaTerminal>()?;
                let spans = parse_ansi_spans(&text);
                let mut cur_col = col as usize;
                for span in &spans {
                    let fg: [f32; 4] = span
                        .fg
                        .as_ref()
                        .map(|c| {
                            [
                                c.r as f32 / 255.0,
                                c.g as f32 / 255.0,
                                c.b as f32 / 255.0,
                                1.0,
                            ]
                        })
                        .unwrap_or(if span.bold {
                            [1.0, 1.0, 1.0, 1.0]
                        } else {
                            [0.667, 0.667, 0.667, 1.0]
                        });
                    let bg: Option<[f32; 4]> = span.bg.as_ref().map(|c| {
                        [
                            c.r as f32 / 255.0,
                            c.g as f32 / 255.0,
                            c.b as f32 / 255.0,
                            1.0,
                        ]
                    });
                    t.binding.terminal.borrow_mut().print_colored(
                        cur_col,
                        row as usize,
                        &span.text,
                        fg,
                        bg,
                    );
                    cur_col += span.text.chars().count();
                }
                Ok(())
            },
        )?,
    )?;
    let comp_rc = Rc::new(RefCell::new(CompletionEngine::new()));
    let crc = comp_rc.clone();
    // -- addCompletion --
    /// Registers a candidate string for tab-completion in the shared completion engine.
    /// @param | candidate | string | The completion candidate to add.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, candidate: String| {
            crc.borrow_mut().add_candidate(&candidate);
            Ok(())
        })?,
    )?;
    let crc = comp_rc.clone();
    // -- removeCompletion --
    /// Removes a previously registered completion candidate from the shared completion engine.
    /// @param | candidate | string | The completion candidate to remove.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, candidate: String| {
            crc.borrow_mut().remove_candidate(&candidate);
            Ok(())
        })?,
    )?;
    let crc = comp_rc.clone();
    // -- clearCompletions --
    /// Removes all registered completion candidates from the shared completion engine.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            crc.borrow_mut().clear();
            Ok(())
        })?,
    )?;
    let crc = comp_rc.clone();
    // -- getCompletions --
    /// Returns all completion candidates matching the given prefix string.
    /// @param | prefix | string | The prefix to match against.
    /// @return | table | Array of matching candidate strings.
    tbl.set(
        "getCompletions",
        lua.create_function(move |lua, prefix: String| {
            let matches = crc.borrow().completions_for(&prefix);
            let t = lua.create_table()?;
            for (i, m) in matches.iter().enumerate() {
                t.set(i + 1, m.clone())?;
            }
            Ok(t)
        })?,
    )?;
    let crc = comp_rc.clone();
    // -- nextCompletion --
    /// Cycles to the next matching completion candidate for the given prefix, wrapping around after the last match.
    /// @param | prefix | string | The prefix to match against.
    /// @return | string | The next matching candidate, or nil if none match.
    tbl.set(
        "nextCompletion",
        lua.create_function(move |_, prefix: String| {
            Ok(crc.borrow_mut().next_completion(&prefix))
        })?,
    )?;
    let crc = comp_rc.clone();
    // -- resetCompletion --
    /// Resets the completion cycling state so the next call to nextCompletion starts from the first match.
    /// @return | nil | No value is returned.
    tbl.set(
        lua.create_function(move |_, ()| {
            crc.borrow_mut().reset();
            Ok(())
        })?,
    )?;
    // -- getMaxCols --
    /// Returns the engine-defined maximum number of columns a terminal grid can have.
    /// @return | integer | Maximum column count.
    tbl.set(
        "getMaxCols",
        lua.create_function(|_, ()| Ok(crate::terminal::MAX_COLS as u32))?,
    )?;
    // -- getMaxRows --
    /// Returns the engine-defined maximum number of rows a terminal grid can have.
    /// @return | integer | Maximum row count.
    tbl.set(
        "getMaxRows",
        lua.create_function(|_, ()| Ok(crate::terminal::MAX_ROWS as u32))?,
    )?;
    /// Performs the 'terminal' operation.
    /// @return | nil | No value is returned.
    luna.set("terminal", tbl)?;
    Ok(())
}
