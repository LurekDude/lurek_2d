//! - Terminal grid state machine: fixed-size cell buffer with 1-based cursor, per-cell fg/bg colors, and content-preserving resize.
//! - Widget system: compositable label, button, text-box, list, border, and panel widgets drawn on top of the grid.
//! - Focus and input dispatch: keyboard, text-input, and mouse events routed to the focused widget with event emission.
//! - Scrollback buffer: capped line history with offset-based windowed retrieval.
//! - Command history: push/prev/next navigation for console-style input recall.
//! - Cell manipulation helpers: single-cell set/get, bulk print, colored print, and default-color application.
//! - Render output: composited cell buffer flattened into batched `RenderCommand` lists for the renderer.
//! - Border rendering: single, double, and ASCII frame styles with optional title text.
//! - Panel child tracking: index-based parent-child relationships with automatic adjustment on widget removal.

use super::cell::{TCell, DEFAULT_FG};
use super::widget::{BorderStyle, Widget, WidgetKind};
use crate::render::renderer::RenderCommand;
use crate::runtime::resource_keys::FontKey;

/// Maximum column count accepted by `Terminal::new` and `resize`.
pub(crate) const MAX_COLS: usize = 512;
/// Maximum row count accepted by `Terminal::new` and `resize`.
pub(crate) const MAX_ROWS: usize = 256;

/// Foreground color for unfocused buttons.
const BUTTON_FG: [f32; 4] = [0.9, 0.9, 0.9, 1.0];
/// Foreground color applied to the focused widget.
const FOCUS_FG: [f32; 4] = [1.0, 0.95, 0.5, 1.0];
/// Foreground color for the selected list item.
const LIST_SELECTED_FG: [f32; 4] = [0.7, 0.95, 1.0, 1.0];
/// Character drawn at the text-box cursor position.
const CURSOR_CHAR: char = '_';

/// Event emitted by `Terminal` input handlers and consumed by the Lua API layer.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum TerminalEvent {
    /// A button widget was activated by keyboard or mouse.
    ButtonClicked { index: usize },
    /// A text-box widget contents changed.
    TextChanged { index: usize },
    /// A list widget selection changed.
    SelectionChanged { index: usize },
}

/// Return the number of Unicode scalar values in `text`.
fn char_count(text: &str) -> usize {
    text.chars().count()
}

/// Return the byte offset in `text` corresponding to `char_index`; returns `text.len()` when out of range.
fn byte_index(text: &str, char_index: usize) -> usize {
    text.char_indices()
        .nth(char_index)
        .map(|(idx, _)| idx)
        .unwrap_or(text.len())
}

/// Return a new `String` containing at most `max_chars` Unicode chars from `text`.
fn truncate_chars(text: &str, max_chars: usize) -> String {
    text.chars().take(max_chars).collect()
}

/// Write a single character cell at `(col, row)` in `cells`; silently ignored when out of bounds.
fn set_render_cell(
    cells: &mut [TCell],
    cols: usize,
    rows: usize,
    col: usize,
    row: usize,
    ch: char,
    fg: [f32; 4],
) {
    if col >= cols || row >= rows {
        return;
    }
    let idx = row * cols + col;
    cells[idx].ch = ch as u32;
    cells[idx].fg = fg;
}

/// Fill a rectangular region of `cells` with space characters using `fg`.
#[allow(clippy::too_many_arguments)]
fn clear_render_rect(
    cells: &mut [TCell],
    cols: usize,
    rows: usize,
    x: usize,
    y: usize,
    width: usize,
    height: usize,
    fg: [f32; 4],
) {
    for row in y..y.saturating_add(height) {
        for col in x..x.saturating_add(width) {
            set_render_cell(cells, cols, rows, col, row, ' ', fg);
        }
    }
}

/// Write up to `max_chars` characters of `text` into `cells` starting at `(x, y)` with `fg`.
#[allow(clippy::too_many_arguments)]
fn write_render_text(
    cells: &mut [TCell],
    cols: usize,
    rows: usize,
    x: usize,
    y: usize,
    text: &str,
    fg: [f32; 4],
    max_chars: usize,
) {
    for (offset, ch) in text.chars().take(max_chars).enumerate() {
        set_render_cell(cells, cols, rows, x + offset, y, ch, fg);
    }
}
/// Main terminal state machine: grid, widgets, scrollback, command history, and focus tracking.
#[derive(Debug, Clone)]
pub struct Terminal {
    /// Number of columns in the active grid, clamped to `MAX_COLS`.
    cols: usize,
    /// Number of rows in the active grid, clamped to `MAX_ROWS`.
    rows: usize,
    /// Flat row-major cell buffer; length is `cols * rows`.
    grid: Vec<TCell>,
    /// Zero-based column of the cursor (stored internally, exposed via 1-based API).
    cursor_col: usize,
    /// Zero-based row of the cursor (stored internally, exposed via 1-based API).
    cursor_row: usize,
    /// Ordered list of widgets drawn on top of the grid.
    widgets: Vec<Widget>,
    /// Index into `widgets` of the currently focused widget, if any.
    focused: Option<usize>,
    /// Scrollback line history; oldest lines at index 0.
    scrollback: Vec<String>,
    /// Maximum number of lines kept in `scrollback`.
    scrollback_cap: usize,
    /// Current scroll position relative to the end of `scrollback`.
    scrollback_offset: usize,
    /// Command input history for up/down navigation.
    cmd_history: Vec<String>,
    /// Navigation cursor into `cmd_history`; 0 means no active navigation.
    cmd_cursor: usize,
    /// Optional per-terminal cell width override in pixels.
    cell_width_override: Option<f32>,
    /// Optional per-terminal cell height override in pixels.
    cell_height_override: Option<f32>,
}
impl Terminal {
    /// Create a new `Terminal` with a blank grid of `cols`×`rows` cells, clamped to `MAX_COLS`/`MAX_ROWS`.
    pub fn new(cols: usize, rows: usize) -> Self {
        let cols = cols.clamp(1, MAX_COLS);
        let rows = rows.clamp(1, MAX_ROWS);
        Self {
            cols,
            rows,
            grid: vec![TCell::default(); cols * rows],
            cursor_col: 0,
            cursor_row: 0,
            widgets: Vec::new(),
            focused: None,
            scrollback: Vec::new(),
            scrollback_cap: 500,
            scrollback_offset: 0,
            cmd_history: Vec::new(),
            cmd_cursor: 0,
            cell_width_override: None,
            cell_height_override: None,
        }
    }
    /// Set cell at 1-based `(col, row)` to `ch` with `fg` and `bg` colors; silently ignored when out of bounds.
    pub fn set(&mut self, col: usize, row: usize, ch: u32, fg: [f32; 4], bg: [f32; 4]) {
        if let Some(idx) = self.index_1based(col, row) {
            self.grid[idx] = TCell { ch, fg, bg };
        }
    }
    /// Return the cell at 1-based `(col, row)`; returns a default cell when out of bounds.
    pub fn get(&self, col: usize, row: usize) -> TCell {
        self.index_1based(col, row)
            .map(|idx| self.grid[idx])
            .unwrap_or_default()
    }
    /// Reset all cells to their default state.
    pub fn clear(&mut self) {
        for cell in &mut self.grid {
            *cell = TCell::default();
        }
    }

    /// Return `(cols, rows)` of the current grid.
    pub fn get_dimensions(&self) -> (usize, usize) {
        (self.cols, self.rows)
    }

    /// Override the per-cell pixel dimensions; values below 1.0 are clamped to 1.0.
    pub fn set_cell_size(&mut self, w: f32, h: f32) {
        self.cell_width_override = Some(w.max(1.0));
        self.cell_height_override = Some(h.max(1.0));
    }

    /// Clear the cell size override so the render layer computes size from font metrics.
    pub fn reset_cell_size(&mut self) {
        self.cell_width_override = None;
        self.cell_height_override = None;
    }

    /// Return the overridden cell size as `Some((w, h))`, or `None` when using font metrics.
    pub fn get_cell_size(&self) -> Option<(f32, f32)> {
        match (self.cell_width_override, self.cell_height_override) {
            (Some(w), Some(h)) => Some((w, h)),
            _ => None,
        }
    }

    /// Return the cursor position as 1-based `(col, row)`.
    pub fn get_cursor(&self) -> (usize, usize) {
        (self.cursor_col + 1, self.cursor_row + 1)
    }

    /// Move the cursor to 1-based `(col, row)`, clamped to grid bounds.
    pub fn set_cursor(&mut self, col: usize, row: usize) {
        self.cursor_col = col.saturating_sub(1).min(self.cols.saturating_sub(1));
        self.cursor_row = row.saturating_sub(1).min(self.rows.saturating_sub(1));
    }

    /// Append `widget` and return its index.
    pub fn add_widget(&mut self, widget: Widget) -> usize {
        let index = self.widgets.len();
        self.widgets.push(widget);
        index
    }

    /// Remove the widget at `index`; adjusts focus and panel child references; returns `false` when index is out of range.
    pub fn remove_widget(&mut self, index: usize) -> bool {
        if index >= self.widgets.len() {
            return false;
        }
        self.widgets.remove(index);
        match self.focused {
            Some(focused) if focused == index => self.focused = None,
            Some(focused) if focused > index => self.focused = Some(focused - 1),
            _ => {}
        }
        self.adjust_panel_children_after_removal(index);
        true
    }

    /// Remove all widgets and clear focus.
    pub fn clear_widgets(&mut self) {
        self.widgets.clear();
        self.focused = None;
    }

    /// Return the number of registered widgets.
    pub fn get_widget_count(&self) -> usize {
        self.widgets.len()
    }

    /// Return a shared reference to the widget at `index`, or `None`.
    pub fn get_widget(&self, index: usize) -> Option<&Widget> {
        self.widgets.get(index)
    }

    /// Return a mutable reference to the widget at `index`, or `None`.
    pub fn get_widget_mut(&mut self, index: usize) -> Option<&mut Widget> {
        self.widgets.get_mut(index)
    }
    /// Append `child_index` to the Panel widget at `panel_index`; returns `false` on bad indices or wrong widget kind.
    pub(crate) fn add_panel_child(&mut self, panel_index: usize, child_index: usize) -> bool {
        if panel_index >= self.widgets.len()
            || child_index >= self.widgets.len()
            || panel_index == child_index
        {
            return false;
        }
        match &mut self.widgets[panel_index].kind {
            WidgetKind::Panel { children } => {
                if !children.contains(&child_index) {
                    children.push(child_index);
                }
                true
            }
            _ => false,
        }
    }
    /// Remove `child_index` from the Panel widget at `panel_index`; returns `true` when the child was present.
    pub(crate) fn remove_panel_child(&mut self, panel_index: usize, child_index: usize) -> bool {
        if panel_index >= self.widgets.len() {
            return false;
        }
        match &mut self.widgets[panel_index].kind {
            WidgetKind::Panel { children } => {
                let before = children.len();
                children.retain(|&index| index != child_index);
                before != children.len()
            }
            _ => false,
        }
    }
    /// Remove all children from the Panel widget at `panel_index`; returns `false` when index is wrong kind.
    pub(crate) fn clear_panel_children(&mut self, panel_index: usize) -> bool {
        if panel_index >= self.widgets.len() {
            return false;
        }
        match &mut self.widgets[panel_index].kind {
            WidgetKind::Panel { children } => {
                children.clear();
                true
            }
            _ => false,
        }
    }
    /// Set focus to `index` if valid, or clear focus when `None` or out of range.
    pub fn set_focus(&mut self, index: Option<usize>) {
        self.focused = match index {
            Some(index) if index < self.widgets.len() => Some(index),
            _ => None,
        };
    }

    /// Return the index of the focused widget, or `None` when nothing is focused.
    pub fn get_focused(&self) -> Option<usize> {
        self.focused
    }

    /// Dispatch a key event to the focused widget; return `true` if consumed.
    pub fn keypressed(&mut self, key: &str) -> bool {
        self.keypressed_with_events(key).0
    }

    /// Dispatch a text-input event to the focused widget; return `true` if consumed.
    pub fn textinput(&mut self, text_input: &str) -> bool {
        self.textinput_with_events(text_input).0
    }

    /// Dispatch a mouse press at 1-based grid `(grid_col, grid_row)` to the topmost hit widget; return `true` if consumed.
    pub fn mousepressed(&mut self, grid_col: usize, grid_row: usize, button: usize) -> bool {
        self.mousepressed_with_events(grid_col, grid_row, button).0
    }
    /// Dispatch a key event to the focused widget; return `(consumed, events)` for the Lua API layer.
    pub(crate) fn keypressed_with_events(&mut self, key: &str) -> (bool, Vec<TerminalEvent>) {
        let focused_index = match self.focused {
            Some(index) if index < self.widgets.len() => index,
            _ => return (false, Vec::new()),
        };
        let widget = &mut self.widgets[focused_index];
        if !widget.base.enabled || !widget.base.visible {
            return (false, Vec::new());
        }
        let mut events = Vec::new();
        match &mut widget.kind {
            WidgetKind::TextBox {
                text,
                max_length: _,
                cursor_pos,
            } => {
                let mut changed = false;
                let consumed = match key {
                    "backspace" => {
                        if *cursor_pos > 0 {
                            let end = byte_index(text, *cursor_pos);
                            let start = byte_index(text, *cursor_pos - 1);
                            text.replace_range(start..end, "");
                            *cursor_pos -= 1;
                            changed = true;
                        }
                        true
                    }
                    "delete" => {
                        if *cursor_pos < char_count(text) {
                            let start = byte_index(text, *cursor_pos);
                            let end = byte_index(text, *cursor_pos + 1);
                            text.replace_range(start..end, "");
                            changed = true;
                        }
                        true
                    }
                    "left" => {
                        *cursor_pos = cursor_pos.saturating_sub(1);
                        true
                    }
                    "right" => {
                        *cursor_pos = (*cursor_pos + 1).min(char_count(text));
                        true
                    }
                    "home" => {
                        *cursor_pos = 0;
                        true
                    }
                    "end" => {
                        *cursor_pos = char_count(text);
                        true
                    }
                    _ => false,
                };
                if changed {
                    events.push(TerminalEvent::TextChanged {
                        index: focused_index,
                    });
                }
                (consumed, events)
            }
            WidgetKind::List {
                items,
                selected,
                scroll_offset,
            } => {
                let previous = *selected;
                let visible_rows = widget.base.height.max(1);
                let consumed = match key {
                    "up" => {
                        if let Some(current) = *selected {
                            if current > 0 {
                                *selected = Some(current - 1);
                            }
                        } else if !items.is_empty() {
                            *selected = Some(0);
                        }
                        if let Some(current) = *selected {
                            if current < *scroll_offset {
                                *scroll_offset = current;
                            }
                        }
                        true
                    }
                    "down" => {
                        if let Some(current) = *selected {
                            if current + 1 < items.len() {
                                *selected = Some(current + 1);
                            }
                        } else if !items.is_empty() {
                            *selected = Some(0);
                        }
                        if let Some(current) = *selected {
                            if current >= *scroll_offset + visible_rows {
                                *scroll_offset =
                                    current.saturating_sub(visible_rows.saturating_sub(1));
                            }
                        }
                        true
                    }
                    _ => false,
                };
                if *selected != previous {
                    events.push(TerminalEvent::SelectionChanged {
                        index: focused_index,
                    });
                }
                (consumed, events)
            }
            WidgetKind::Button { .. } => {
                if matches!(key, "return" | "space") {
                    events.push(TerminalEvent::ButtonClicked {
                        index: focused_index,
                    });
                    (true, events)
                } else {
                    (false, events)
                }
            }
            _ => (false, events),
        }
    }
    /// Dispatch text input to the focused `TextBox`; return `(consumed, events)` for the Lua API layer.
    pub(crate) fn textinput_with_events(&mut self, text_input: &str) -> (bool, Vec<TerminalEvent>) {
        let focused_index = match self.focused {
            Some(index) if index < self.widgets.len() => index,
            _ => return (false, Vec::new()),
        };
        let widget = &mut self.widgets[focused_index];
        if !widget.base.enabled || !widget.base.visible {
            return (false, Vec::new());
        }
        match &mut widget.kind {
            WidgetKind::TextBox {
                text,
                max_length,
                cursor_pos,
            } => {
                let input_len = char_count(text_input);
                if *max_length > 0 && char_count(text) + input_len > *max_length {
                    return (false, Vec::new());
                }
                let insert_at = byte_index(text, *cursor_pos);
                text.insert_str(insert_at, text_input);
                *cursor_pos += input_len;
                (
                    true,
                    vec![TerminalEvent::TextChanged {
                        index: focused_index,
                    }],
                )
            }
            _ => (false, Vec::new()),
        }
    }
    /// Dispatch a mouse press to the topmost hit widget; return `(consumed, events)` for the Lua API layer.
    pub(crate) fn mousepressed_with_events(
        &mut self,
        grid_col: usize,
        grid_row: usize,
        _button: usize,
    ) -> (bool, Vec<TerminalEvent>) {
        let col = grid_col.saturating_sub(1);
        let row = grid_row.saturating_sub(1);
        for index in (0..self.widgets.len()).rev() {
            let widget = &mut self.widgets[index];
            if !widget.base.visible || !widget.base.enabled {
                continue;
            }
            let within_x = col >= widget.base.x && col < widget.base.x + widget.base.width;
            let within_y = row >= widget.base.y && row < widget.base.y + widget.base.height;
            if !within_x || !within_y {
                continue;
            }
            self.focused = Some(index);
            let mut events = Vec::new();
            match &mut widget.kind {
                WidgetKind::Button { .. } => {
                    events.push(TerminalEvent::ButtonClicked { index });
                }
                WidgetKind::TextBox {
                    text, cursor_pos, ..
                } => {
                    let relative_col = col.saturating_sub(widget.base.x);
                    *cursor_pos = relative_col.min(char_count(text));
                }
                WidgetKind::List {
                    items,
                    selected,
                    scroll_offset,
                } => {
                    let relative_row = row.saturating_sub(widget.base.y);
                    let item_index = *scroll_offset + relative_row;
                    if item_index < items.len() && *selected != Some(item_index) {
                        *selected = Some(item_index);
                        events.push(TerminalEvent::SelectionChanged { index });
                    }
                }
                _ => {}
            }
            return (true, events);
        }
        self.focused = None;
        (false, Vec::new())
    }
    /// Produce a flat cell buffer with all widgets composited on top of the raw grid.
    pub(crate) fn render_cells(&self) -> Vec<TCell> {
        let mut cells = self.grid.clone();
        for (index, widget) in self.widgets.iter().enumerate() {
            if !widget.base.visible {
                continue;
            }
            match &widget.kind {
                WidgetKind::Label { text, color } => {
                    write_render_text(
                        &mut cells,
                        self.cols,
                        self.rows,
                        widget.base.x,
                        widget.base.y,
                        text,
                        *color,
                        char_count(text),
                    );
                }
                WidgetKind::Button { text } => {
                    let fg = if self.focused == Some(index) {
                        FOCUS_FG
                    } else {
                        BUTTON_FG
                    };
                    clear_render_rect(
                        &mut cells,
                        self.cols,
                        self.rows,
                        widget.base.x,
                        widget.base.y,
                        widget.base.width,
                        widget.base.height,
                        fg,
                    );
                    let row = widget.base.y + widget.base.height.saturating_sub(1) / 2;
                    let text_width = char_count(text).min(widget.base.width);
                    let start_col =
                        widget.base.x + widget.base.width.saturating_sub(text_width) / 2;
                    write_render_text(
                        &mut cells,
                        self.cols,
                        self.rows,
                        start_col,
                        row,
                        text,
                        fg,
                        widget.base.width,
                    );
                }
                WidgetKind::TextBox {
                    text, cursor_pos, ..
                } => {
                    clear_render_rect(
                        &mut cells,
                        self.cols,
                        self.rows,
                        widget.base.x,
                        widget.base.y,
                        widget.base.width,
                        widget.base.height,
                        DEFAULT_FG,
                    );
                    let display = truncate_chars(text, widget.base.width);
                    write_render_text(
                        &mut cells,
                        self.cols,
                        self.rows,
                        widget.base.x,
                        widget.base.y,
                        &display,
                        DEFAULT_FG,
                        widget.base.width,
                    );
                    if self.focused == Some(index) && widget.base.width > 0 {
                        let cursor_col = widget.base.x + (*cursor_pos).min(widget.base.width - 1);
                        set_render_cell(
                            &mut cells,
                            self.cols,
                            self.rows,
                            cursor_col,
                            widget.base.y,
                            CURSOR_CHAR,
                            FOCUS_FG,
                        );
                    }
                }
                WidgetKind::List {
                    items,
                    selected,
                    scroll_offset,
                } => {
                    for row_offset in 0..widget.base.height {
                        let row = widget.base.y + row_offset;
                        clear_render_rect(
                            &mut cells,
                            self.cols,
                            self.rows,
                            widget.base.x,
                            row,
                            widget.base.width,
                            1,
                            DEFAULT_FG,
                        );
                        let item_index = scroll_offset + row_offset;
                        if item_index >= items.len() {
                            continue;
                        }
                        let is_selected = *selected == Some(item_index);
                        let fg = if is_selected {
                            LIST_SELECTED_FG
                        } else {
                            DEFAULT_FG
                        };
                        let prefix = if is_selected { "> " } else { "  " };
                        let available = widget.base.width.saturating_sub(char_count(prefix));
                        let text = truncate_chars(&items[item_index], available);
                        write_render_text(
                            &mut cells,
                            self.cols,
                            self.rows,
                            widget.base.x,
                            row,
                            prefix,
                            fg,
                            char_count(prefix),
                        );
                        write_render_text(
                            &mut cells,
                            self.cols,
                            self.rows,
                            widget.base.x + char_count(prefix),
                            row,
                            &text,
                            fg,
                            available,
                        );
                    }
                }
                WidgetKind::Border {
                    style,
                    title,
                    color,
                } => {
                    self.render_border(&mut cells, widget, *style, title, *color);
                }
                WidgetKind::Panel { .. } => {}
            }
        }
        cells
    }
    /// Draw a `BorderStyle` frame with optional `title` into `cells` for `widget`.
    fn render_border(
        &self,
        cells: &mut [TCell],
        widget: &Widget,
        style: BorderStyle,
        title: &str,
        color: [f32; 4],
    ) {
        if widget.base.width == 0 || widget.base.height == 0 {
            return;
        }
        let (top_left, top_right, bottom_left, bottom_right, horizontal, vertical) = match style {
            BorderStyle::Single => ('┌', '┐', '└', '┘', '─', '│'),
            BorderStyle::Double => ('╔', '╗', '╚', '╝', '═', '║'),
            BorderStyle::Ascii => ('+', '+', '+', '+', '-', '|'),
        };
        let x = widget.base.x;
        let y = widget.base.y;
        let width = widget.base.width;
        let height = widget.base.height;
        for offset in 0..width {
            let ch = if offset == 0 {
                top_left
            } else if offset == width.saturating_sub(1) {
                top_right
            } else {
                horizontal
            };
            set_render_cell(cells, self.cols, self.rows, x + offset, y, ch, color);
            if height > 1 {
                let ch = if offset == 0 {
                    bottom_left
                } else if offset == width.saturating_sub(1) {
                    bottom_right
                } else {
                    horizontal
                };
                set_render_cell(
                    cells,
                    self.cols,
                    self.rows,
                    x + offset,
                    y + height - 1,
                    ch,
                    color,
                );
            }
        }
        if height > 2 {
            for offset in 1..height - 1 {
                set_render_cell(cells, self.cols, self.rows, x, y + offset, vertical, color);
                if width > 1 {
                    set_render_cell(
                        cells,
                        self.cols,
                        self.rows,
                        x + width - 1,
                        y + offset,
                        vertical,
                        color,
                    );
                }
            }
        }
        if width > 2 && !title.is_empty() {
            let available = width.saturating_sub(2);
            let title = truncate_chars(title, available);
            write_render_text(
                cells,
                self.cols,
                self.rows,
                x + 1,
                y,
                &title,
                color,
                available,
            );
        }
    }
    /// Patch all Panel children lists after a widget at `removed_index` was removed: drop references to it and decrement higher indices.
    fn adjust_panel_children_after_removal(&mut self, removed_index: usize) {
        for widget in &mut self.widgets {
            if let WidgetKind::Panel { children } = &mut widget.kind {
                let mut i = 0;
                while i < children.len() {
                    if children[i] == removed_index {
                        children.remove(i);
                    } else {
                        if children[i] > removed_index {
                            children[i] -= 1;
                        }
                        i += 1;
                    }
                }
            }
        }
    }
    /// Convert 1-based `(col, row)` to a flat grid index; returns `None` for `col`/`row` of 0 or out of bounds.
    fn index_1based(&self, col: usize, row: usize) -> Option<usize> {
        if col == 0 || row == 0 {
            return None;
        }
        let col = col - 1;
        let row = row - 1;
        if col < self.cols && row < self.rows {
            Some(row * self.cols + col)
        } else {
            None
        }
    }
    /// Return the column count. This function is part of the public API.
    pub fn cols(&self) -> usize {
        self.cols
    }

    /// Return the row count. This function is part of the public API.
    pub fn rows(&self) -> usize {
        self.rows
    }

    /// Return the cell at 1-based `(col, row)` as `Some`, or `None` when out of bounds.
    pub fn try_get(&self, col: usize, row: usize) -> Option<TCell> {
        self.index_1based(col, row).map(|idx| self.grid[idx])
    }

    /// Set only the character codepoint at 1-based `(col, row)`.
    pub fn set_char(&mut self, col: usize, row: usize, ch: u32) {
        if let Some(idx) = self.index_1based(col, row) {
            self.grid[idx].ch = ch;
        }
    }

    /// Set only the foreground color at 1-based `(col, row)`.
    pub fn set_fg(&mut self, col: usize, row: usize, fg: [f32; 4]) {
        if let Some(idx) = self.index_1based(col, row) {
            self.grid[idx].fg = fg;
        }
    }

    /// Set only the background color at 1-based `(col, row)`.
    pub fn set_bg(&mut self, col: usize, row: usize, bg: [f32; 4]) {
        if let Some(idx) = self.index_1based(col, row) {
            self.grid[idx].bg = bg;
        }
    }

    /// Write each character of `text` to successive columns starting at 1-based `(col, row)`, preserving existing fg/bg.
    pub fn print(&mut self, col: usize, row: usize, text: &str) {
        for (offset, ch) in text.chars().enumerate() {
            if let Some(idx) = self.index_1based(col + offset, row) {
                self.grid[idx].ch = ch as u32;
            }
        }
    }

    /// Resize the grid to `new_cols`×`new_rows`, preserving the overlapping content region.
    pub fn resize(&mut self, new_cols: usize, new_rows: usize) {
        let new_cols = new_cols.clamp(1, MAX_COLS);
        let new_rows = new_rows.clamp(1, MAX_ROWS);
        let mut new_grid = vec![TCell::default(); new_cols * new_rows];
        let copy_cols = new_cols.min(self.cols);
        let copy_rows = new_rows.min(self.rows);
        for row in 0..copy_rows {
            for col in 0..copy_cols {
                new_grid[row * new_cols + col] = self.grid[row * self.cols + col];
            }
        }
        self.cols = new_cols;
        self.rows = new_rows;
        self.grid = new_grid;
        self.cursor_col = self.cursor_col.min(self.cols.saturating_sub(1));
        self.cursor_row = self.cursor_row.min(self.rows.saturating_sub(1));
    }
    /// Return the number of registered widgets.
    pub fn widget_count(&self) -> usize {
        self.widgets.len()
    }

    /// Return the first widget whose `base.tag` matches `tag`, or `None`.
    pub fn find_by_tag(&self, tag: &str) -> Option<&Widget> {
        self.widgets.iter().find(|widget| widget.base.tag == tag)
    }

    /// Build a batched `RenderCommand` list for the composited cell grid at pixel origin `(ox, oy)` with `cell_w`/`cell_h` and `font_key`.
    pub fn build_render_commands(
        &self,
        ox: f32,
        oy: f32,
        cell_w: f32,
        cell_h: f32,
        font_key: FontKey,
    ) -> Vec<RenderCommand> {
        let cells = self.render_cells();
        let mut commands = Vec::new();
        for row in 0..self.rows {
            let row_cells = &cells[row * self.cols..(row + 1) * self.cols];
            if row_cells.is_empty() {
                continue;
            }
            let mut run_start = 0usize;
            let mut run_color = row_cells[0].fg;
            let mut run_text = String::new();
            let flush_run = |commands: &mut Vec<RenderCommand>,
                             run_start: usize,
                             run_color: [f32; 4],
                             run_text: &mut String| {
                if !run_text.trim().is_empty() {
                    commands.push(RenderCommand::SetColor(
                        run_color[0],
                        run_color[1],
                        run_color[2],
                        run_color[3],
                    ));
                    commands.push(RenderCommand::Print {
                        font_key,
                        text: run_text.clone(),
                        x: ox + run_start as f32 * cell_w,
                        y: oy + row as f32 * cell_h,
                        scale: 1.0,
                    });
                }
                run_text.clear();
            };
            for (col, cell) in row_cells.iter().enumerate() {
                if col > 0 && cell.fg != run_color {
                    flush_run(&mut commands, run_start, run_color, &mut run_text);
                    run_start = col;
                    run_color = cell.fg;
                }
                run_text.push(char::from_u32(cell.ch).unwrap_or(' '));
            }
            flush_run(&mut commands, run_start, run_color, &mut run_text);
        }
        if !commands.is_empty() {
            commands.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 1.0));
        }
        commands
    }
    /// Apply `fg` and `bg` to every cell in the grid without changing character codepoints.
    pub fn set_default_colors(&mut self, fg: [f32; 4], bg: [f32; 4]) {
        for cell in &mut self.grid {
            cell.fg = fg;
            cell.bg = bg;
        }
    }

    /// Write `text` with explicit `fg` and optional `bg` starting at 1-based `(col, row)`.
    pub fn print_colored(
        &mut self,
        col: usize,
        row: usize,
        text: &str,
        fg: [f32; 4],
        bg: Option<[f32; 4]>,
    ) {
        for (offset, ch) in text.chars().enumerate() {
            let c = col + offset;
            if let Some(idx) = self.index_1based(c, row) {
                self.grid[idx].ch = ch as u32;
                self.grid[idx].fg = fg;
                if let Some(b) = bg {
                    self.grid[idx].bg = b;
                }
            }
        }
    }
    /// Set the scrollback line cap; trims oldest lines immediately if the buffer exceeds the new limit.
    pub fn set_scrollback_cap(&mut self, cap: usize) {
        self.scrollback_cap = cap.max(1);
        if self.scrollback.len() > self.scrollback_cap {
            let excess = self.scrollback.len() - self.scrollback_cap;
            self.scrollback.drain(0..excess);
        }
    }

    /// Return the current scrollback line cap.
    pub fn scrollback_cap(&self) -> usize {
        self.scrollback_cap
    }

    /// Append `line` to scrollback, evicting the oldest line when the cap is reached; resets scroll offset to 0.
    pub fn push_scrollback(&mut self, line: &str) {
        if self.scrollback.len() >= self.scrollback_cap {
            self.scrollback.remove(0);
        }
        self.scrollback.push(line.to_owned());
        self.scrollback_offset = 0;
    }

    /// Return up to `count` lines ending `offset` lines from the bottom; returns empty when buffer is empty or `count` is 0.
    pub fn get_scrollback(&self, offset: usize, count: usize) -> Vec<&str> {
        let len = self.scrollback.len();
        if len == 0 || count == 0 {
            return Vec::new();
        }
        let end = len.saturating_sub(offset);
        let start = end.saturating_sub(count);
        self.scrollback[start..end]
            .iter()
            .map(|s| s.as_str())
            .collect()
    }

    /// Return the current scrollback scroll offset.
    pub fn scrollback_offset(&self) -> usize {
        self.scrollback_offset
    }

    /// Set the scrollback scroll offset, clamped to buffer length.
    pub fn set_scrollback_offset(&mut self, offset: usize) {
        self.scrollback_offset = offset.min(self.scrollback.len());
    }

    /// Return the number of lines in the scrollback buffer.
    pub fn scrollback_len(&self) -> usize {
        self.scrollback.len()
    }

    /// Append a non-empty trimmed `cmd` to the command history and reset the navigation cursor.
    pub fn push_cmd_history(&mut self, cmd: &str) {
        if cmd.trim().is_empty() {
            return;
        }
        self.cmd_history.push(cmd.to_owned());
        self.cmd_cursor = 0;
    }

    /// Navigate to the previous command history entry; returns `None` when history is empty.
    pub fn prev_cmd(&mut self) -> Option<&str> {
        let len = self.cmd_history.len();
        if len == 0 {
            return None;
        }
        if self.cmd_cursor < len {
            self.cmd_cursor += 1;
        }
        let idx = len - self.cmd_cursor;
        Some(&self.cmd_history[idx])
    }

    /// Navigate to the next (more recent) command history entry; returns `None` when at the newest position.
    pub fn next_cmd(&mut self) -> Option<&str> {
        if self.cmd_cursor == 0 {
            return None;
        }
        self.cmd_cursor -= 1;
        if self.cmd_cursor == 0 {
            return None;
        }
        let len = self.cmd_history.len();
        let idx = len - self.cmd_cursor;
        Some(&self.cmd_history[idx])
    }

    /// Return the number of entries in the command history.
    pub fn cmd_history_len(&self) -> usize {
        self.cmd_history.len()
    }

    /// Clear all command history and reset the navigation cursor.
    pub fn clear_cmd_history(&mut self) {
        self.cmd_history.clear();
        self.cmd_cursor = 0;
    }
}

/// `Default` implementation for `Terminal`.
impl Default for Terminal {
    fn default() -> Self {
        Self::new(80, 40)
    }
}
