//! `luna.gui` Lua API bindings.
//!
//! Auto-generated skeleton from `src/gui/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaComboBox ────────────────────────────────────────────────────────────

pub struct LuaComboBox(/* TODO: add key + state fields */);


impl LuaComboBox {
    /// Get the currently selected item text, if any.
    ///
    ///
    /// @return Option<
    pub fn selected_item(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaComboBox {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("selectedItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGraphRenderer ────────────────────────────────────────────────────────────

pub struct LuaGraphRenderer(/* TODO: add key + state fields */);


impl LuaGraphRenderer {
    /// Returns the names of all registered series.
    ///
    ///
    /// @return table
    pub fn get_series_names(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the current cursor position in data coordinates.
    ///
    ///
    /// @return Option<(f64
    pub fn get_cursor_value(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Maps world (data) coordinates to viewport screen-pixel coordinates.
    ///
    ///
    /// @param wx : number
    /// @param wy : number
    pub fn world_to_screen(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Maps viewport screen-pixel coordinates back to world (data) coordinates.
    ///
    ///
    /// @param sx : number
    /// @param sy : number
    pub fn screen_to_world(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGraphRenderer {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSeriesNames", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getCursorValue", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("worldToScreen", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("screenToWorld", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGuiContext ────────────────────────────────────────────────────────────

pub struct LuaGuiContext(/* TODO: add key + state fields */);


impl LuaGuiContext {
    /// Return the number of widgets in the pool (including the root).
    ///
    ///
    /// @return integer
    pub fn widget_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Count the children of a container widget.
    ///
    /// @param widget_idx : integer
    /// @return integer
    pub fn child_count(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the number of active (non-expired) toast notifications.
    ///
    ///
    /// @return integer
    pub fn toast_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Recursively search for a widget by its `id` string, starting from
    /// `start_idx`.
    ///
    /// @param start_idx : integer
    /// @param id : str
    /// @return integer?
    pub fn find_by_id(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGuiContext {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("widgetCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("childCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toastCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findById", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaLayout ────────────────────────────────────────────────────────────

pub struct LuaLayout(/* TODO: add key + state fields */);


impl LuaLayout {
    /// Recalculate child positions based on direction, spacing, alignment,
    /// and justification.
    ///
    /// This method updates the `x` / `y` fields of each child's `WidgetBase`
    /// in the provided mutable slice.  Children are referenced by index in
    /// `self.children`.
    ///
    ///
    /// @param bases : mut [WidgetBase]
    pub fn perform_layout(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaLayout {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("performLayout", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaListBox ────────────────────────────────────────────────────────────

pub struct LuaListBox(/* TODO: add key + state fields */);


impl LuaListBox {
    /// Get the currently selected item text, if any.
    ///
    ///
    /// @return Option<
    pub fn selected_item(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaListBox {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("selectedItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaNinePatch ────────────────────────────────────────────────────────────

pub struct LuaNinePatch(/* TODO: add key + state fields */);


impl LuaNinePatch {
    /// Compute the nine slice rectangles.
    ///
    /// Each returned element is `(sx, sy, sw, sh, dx, dy, dw, dh)` where
    /// `s*` are source coordinates and `d*` are destination coordinates on
    /// the widget.
    ///
    ///
    /// @return Vec<(f32
    pub fn get_slices(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNinePatch {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSlices", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaProgressBar ────────────────────────────────────────────────────────────

pub struct LuaProgressBar(/* TODO: add key + state fields */);


impl LuaProgressBar {
    /// Return the normalized progress in `[0.0, 1.0]`.
    ///
    ///
    /// @return number
    pub fn progress(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaProgressBar {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("progress", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTheme ────────────────────────────────────────────────────────────

pub struct LuaTheme(/* TODO: add key + state fields */);


impl LuaTheme {
    /// Look up the style for a widget type and state.
    ///
    /// Falls back to the `Normal` state entry if no state-specific entry
    /// exists.  Returns `None` only if the type has no theme entries at all.
    ///
    /// @param widget_type : WidgetType
    /// @param state : WidgetState
    /// @return Option<
    pub fn get_style(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTheme {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getStyle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaToast ────────────────────────────────────────────────────────────

pub struct LuaToast(/* TODO: add key + state fields */);


impl LuaToast {
    /// Return the progress through the toast's lifetime as `[0.0, 1.0]`.
    ///
    ///
    /// @return number
    pub fn progress(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return `true` if the toast has exceeded its display duration.
    ///
    ///
    /// @return boolean
    pub fn is_expired(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaToast {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("progress", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isExpired", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaToolbar ────────────────────────────────────────────────────────────

pub struct LuaToolbar(/* TODO: add key + state fields */);


impl LuaToolbar {
    /// Return the 0-based index of the button with the given `id`, or `None`.
    ///
    /// @param id : str
    /// @return integer?
    pub fn get_button_index(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return whether the button identified by `id` is in the toggled state.
    ///
    /// @param id : str
    /// @return boolean?
    pub fn is_button_toggled(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaToolbar {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getButtonIndex", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isButtonToggled", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaTreeView ────────────────────────────────────────────────────────────

pub struct LuaTreeView(/* TODO: add key + state fields */);


impl LuaTreeView {
    /// Return the total number of nodes.
    ///
    ///
    /// @return integer
    pub fn node_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return the display text of the node at `index`, or `None` if out of range.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_node_text(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return whether the node at `index` is expanded.
    ///
    /// @param index : integer
    /// @return boolean?
    pub fn is_node_expanded(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the selected node index, or `None` if nothing is selected.
    ///
    ///
    /// @return integer?
    pub fn get_selected_node(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return a slice of child indices for the node at `index`.
    ///
    /// @param index : integer
    /// @return Option<
    pub fn get_child_nodes(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the parent index of the node at `index`.
    ///
    /// Returns `Some(None)` for root-level nodes and `None` if the index is
    /// out of range.
    ///
    /// @param index : integer
    /// @return integer??
    pub fn get_parent_node(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the depth of the node at `index` (0 for root-level nodes).
    ///
    /// Traverses the parent chain; returns `None` if the index is out of range.
    ///
    /// @param index : integer
    /// @return integer?
    pub fn get_node_depth(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaTreeView {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("nodeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeText", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isNodeExpanded", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSelectedNode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getChildNodes", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getParentNode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeDepth", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaWidgetBase ────────────────────────────────────────────────────────────

pub struct LuaWidgetBase(/* TODO: add key + state fields */);


impl LuaWidgetBase {
    /// Test whether a point `(px, py)` lies within this widget's bounding
    /// rectangle.
    ///
    /// @param px : number
    /// @param py : number
    /// @return boolean
    pub fn contains_point(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaWidgetBase {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("containsPoint", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaWidgetKind ────────────────────────────────────────────────────────────

pub struct LuaWidgetKind(/* TODO: add key + state fields */);


impl LuaWidgetKind {
    /// Return the child indices if this widget is a container type.
    ///
    ///
    /// @return Option<
    pub fn children(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaWidgetKind {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("children", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.gui.* functions ──────────────────────────────────────────

/// Parse a direction string.  Accepted: `"vertical"`, `"horizontal"`, `"grid"`.
///
/// @param s : str
/// @return LayoutDirection?
pub fn parse_str(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Return mutable child indices if this widget is a container type.
///
///
/// @return Option<
pub fn children_mut(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a button and return its pool index.
///
/// @param text : impl Into<String>
/// @return integer
pub fn add_button(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a label and return its pool index.
///
/// @param text : impl Into<String>
/// @return integer
pub fn add_label(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a text input and return its pool index.
///
///
/// @return integer
pub fn add_text_input(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a check box and return its pool index.
///
/// @param text : impl Into<String>
/// @return integer
pub fn add_checkbox(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a slider and return its pool index.
///
/// @param min : number
/// @param max : number
/// @return integer
pub fn add_slider(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a progress bar and return its pool index.
///
/// @param min : number
/// @param max : number
/// @return integer
pub fn add_progress_bar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a combo box and return its pool index.
///
///
/// @return integer
pub fn add_combo_box(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a list box and return its pool index.
///
///
/// @return integer
pub fn add_list_box(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a panel and return its pool index.
///
///
/// @return integer
pub fn add_panel(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a layout and return its pool index.
///
/// @param direction : LayoutDirection
/// @return integer
pub fn add_layout(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a scroll panel and return its pool index.
///
///
/// @return integer
pub fn add_scroll_panel(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a nine-patch and return its pool index.
///
///
/// @return integer
pub fn add_nine_patch(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a tab bar and return its pool index.
///
///
/// @return integer
pub fn add_tab_bar(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a separator and return its pool index.
///
/// @param vertical : boolean
/// @return integer
pub fn add_separator(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a spacer and return its pool index.
///
/// @param width : number
/// @param height : number
/// @return integer
pub fn add_spacer(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a tree view and return its pool index.
///
///
/// @return integer
pub fn add_tree_view(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a radio button and return its pool index.
///
/// @param text : impl Into<String>
/// @param group : impl Into<String>
/// @return integer
pub fn add_radio_button(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a scroll bar and return its pool index.
///
/// @param vertical : boolean
/// @return integer
pub fn add_scroll_bar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a GUI window and return its pool index.
///
/// @param title : impl Into<String>
/// @return integer
pub fn add_gui_window(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a split panel and return its pool index.
///
/// @param orientation : impl Into<String>
/// @return integer
pub fn add_split_panel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a dock panel and return its pool index.
///
///
/// @return integer
pub fn add_dock_panel(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a toolbar and return its pool index.
///
/// @param orientation : impl Into<String>
/// @return integer
pub fn add_toolbar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a menu bar and return its pool index.
///
///
/// @return integer
pub fn add_menu_bar(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a menu item and return its pool index.
///
/// @param text : impl Into<String>
/// @return integer
pub fn add_menu_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a dialog and return its pool index.
///
/// @param title : impl Into<String>
/// @return integer
pub fn add_dialog(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a status bar and return its pool index.
///
///
/// @return integer
pub fn add_status_bar(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add an accordion and return its pool index.
///
///
/// @return integer
pub fn add_accordion(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a tooltip panel and return its pool index.
///
/// @param text : impl Into<String>
/// @return integer
pub fn add_tooltip_panel(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a color picker and return its pool index.
///
///
/// @return integer
pub fn add_color_picker(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add a GUI table and return its pool index.
///
///
/// @return integer
pub fn add_gui_table(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add an image widget and return its pool index.
///
///
/// @return integer
pub fn add_image_widget(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Add `child_idx` as a child of the container at `parent_idx`.
///
/// Returns `false` if the parent is not a container or indices are invalid.
///
/// @param parent_idx : integer
/// @param child_idx : integer
/// @return boolean
pub fn add_child(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove `child_idx` from the container at `parent_idx`.
///
/// @param parent_idx : integer
/// @param child_idx : integer
/// @return boolean
pub fn remove_child(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set keyboard focus to the given widget, clearing focus from the
/// previous widget.
///
///
/// @param widget_idx : integer?
pub fn set_focus(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Queue a toast notification for display.
///
///
/// @param toast : Toast
pub fn add_toast(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advance toast timers and remove expired toasts.
///
///
/// @param dt : number
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a mouse press event to the widget tree.
///
/// Hit-tests all visible, enabled widgets and sets focus + state
/// accordingly.
///
/// @param x : number
/// @param y : number
/// @param _button : integer
/// @return boolean
pub fn mouse_pressed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a mouse release event to the widget tree.
///
/// @param x : number
/// @param y : number
/// @param _button : integer
/// @return boolean
pub fn mouse_released(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a mouse move event to update hover states.
///
/// @param x : number
/// @param y : number
/// @return boolean
pub fn mouse_moved(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a key press event.  Handles tab focus navigation and
/// delegates to focused text inputs.
///
/// @param key : str
/// @return boolean
pub fn key_pressed(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a text input event to the focused text input widget.
///
/// @param text : str
/// @return boolean
pub fn text_input(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Forward a mouse wheel event.
///
/// @param _x : number
/// @param y : number
/// @return boolean
pub fn wheel_moved(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Insert text at the cursor position, respecting `max_length`.
///
/// @param input : str
/// @return boolean
pub fn insert_text(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Delete the character before the cursor (backspace).
///
///
/// @return boolean
pub fn backspace(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Set the current value, clamping to the `[min, max]` range and
/// snapping to `step` if non-zero.
///
///
/// @param v : number
pub fn set_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add an item to the end of the list.
///
///
/// @param text : impl Into<String>
pub fn add_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove an item at the given 0-based index.
///
/// Returns `false` if the index is out of bounds.
///
/// @param index : integer
/// @return boolean
pub fn remove_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add an item to the end of the list.
///
///
/// @param text : impl Into<String>
/// Remove an item at the given 0-based index.
///
/// @param index : integer
/// @return boolean
/// Add a tab with the given label.
///
///
/// @param label : impl Into<String>
pub fn add_tab(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a tab at the given 0-based index.
///
/// @param index : integer
/// @return boolean
pub fn remove_tab(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the screen-pixel viewport for chart rendering.
///
///
/// @param x : number
/// @param y : number
/// @param w : number
/// @param h : number
pub fn set_viewport(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the world (data) coordinate range. Replaces the current range value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param x_min : number
/// @param x_max : number
/// @param y_min : number
/// @param y_max : number
pub fn set_range(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a line series with the given name, data points, and color.
///
///
/// @param name : str
/// @param points : table
/// @param color : Color
pub fn add_line_series(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a scatter series. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param name : str
/// @param points : table
/// @param color : Color
/// @param size : number
pub fn add_scatter_series(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Adds a bar series. Each value maps to category index 0, 1, 2, ….
///
///
/// @param name : str
/// @param values : table
/// @param color : Color
pub fn add_bar_series(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Removes a series by name. Returns `true` if it existed.
///
/// @param name : str
/// @return boolean
pub fn remove_series(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables the background grid.
///
///
/// @param b : boolean
pub fn set_show_grid(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables the x/y axes. Replaces the current show axes value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param b : boolean
pub fn set_show_axes(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Enables or disables axis labels and chart title.
///
///
/// @param b : boolean
pub fn set_show_labels(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the grid line color. Replaces the current grid color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param c : Color
pub fn set_grid_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the axis line color. Replaces the current axis color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param c : Color
pub fn set_axis_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the chart background color. Replaces the current bg color value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param c : Color
pub fn set_bg_color(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the chart title. Replaces the current title value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param text : str
pub fn set_title(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the x-axis and y-axis labels. Replaces the current axis labels value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param x_label : str
/// @param y_label : str
pub fn set_axis_labels(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sets the cursor position in data (world) coordinates.
///
///
/// @param x : number
/// @param y : number
pub fn set_cursor_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Advance the elapsed timer by `dt` seconds.
///
///
/// @param dt : number
/// Add a node to the tree.
///
/// If `parent_index` is `None`, the node is a root-level entry.
/// If `parent_index` is `Some(idx)`, the node is added as a child of node
/// at index `idx`.
///
/// @param text : impl Into<String>
/// @param parent_index : integer?
/// @return integer
pub fn add_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Toggle the expanded state of a node.
///
/// @param index : integer
/// @return boolean
pub fn toggle_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove the node at `index`, detaching it from its parent and remapping
/// all stored indices that follow.  Children of the removed node are
/// orphaned (their `parent` becomes `None`).
///
/// @param index : integer
/// @return boolean
pub fn remove_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the display text of the node at `index`.
///
/// @param index : integer
/// @param text : impl Into<String>
/// @return boolean
pub fn set_node_text(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the icon name placeholder for the node at `index`.
///
/// Passing an empty string clears the icon.
///
/// @param index : integer
/// @param icon : impl Into<String>
/// @return boolean
pub fn set_node_icon(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Expand the node at `index` (make its children visible).
///
/// @param index : integer
/// @return boolean
pub fn expand_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Collapse the node at `index` (hide its children).
///
/// @param index : integer
/// @return boolean
pub fn collapse_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the selected node.
///
/// Passing an out-of-range index clears the selection and returns `false`.
///
/// @param index : integer
/// @return boolean
pub fn set_selected_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a named button to the toolbar.
///
/// If a button with the same `id` already exists, its existing index is
/// returned without creating a duplicate.
///
/// @param id : impl Into<String>
/// @param tooltip : impl Into<String>
/// @return integer
/// Add a flexible spacer to the toolbar.
///
/// This is a placeholder; layout and rendering are handled externally.
///
///
/// @param _width : number
/// Enable or disable the button identified by `id`.
///
/// @param id : str
/// @param enabled : boolean
/// @return boolean
pub fn set_button_enabled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the toggled (latched pressed) state of the button identified by `id`.
///
/// @param id : str
/// @param toggled : boolean
/// @return boolean
pub fn set_button_toggled(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Insert or replace a style entry for the given widget type and state.
///
///
/// @param widget_type : WidgetType
/// @param state : WidgetState
/// @param style : WidgetStyle
pub fn set_style(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a state name string into a [`WidgetState`].
///
/// Accepted values (case-sensitive): `"normal"`, `"hovered"`, `"pressed"`,
/// `"focused"`, `"disabled"`.
///
/// @param s : str
/// @return WidgetState?
/// Registers the `luna.gui` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("childrenMut", lua.create_function(children_mut)?)?;
    tbl.set("addButton", lua.create_function(add_button)?)?;
    tbl.set("addLabel", lua.create_function(add_label)?)?;
    tbl.set("addTextInput", lua.create_function(add_text_input)?)?;
    tbl.set("addCheckbox", lua.create_function(add_checkbox)?)?;
    tbl.set("addSlider", lua.create_function(add_slider)?)?;
    tbl.set("addProgressBar", lua.create_function(add_progress_bar)?)?;
    tbl.set("addComboBox", lua.create_function(add_combo_box)?)?;
    tbl.set("addListBox", lua.create_function(add_list_box)?)?;
    tbl.set("addPanel", lua.create_function(add_panel)?)?;
    tbl.set("addLayout", lua.create_function(add_layout)?)?;
    tbl.set("addScrollPanel", lua.create_function(add_scroll_panel)?)?;
    tbl.set("addNinePatch", lua.create_function(add_nine_patch)?)?;
    tbl.set("addTabBar", lua.create_function(add_tab_bar)?)?;
    tbl.set("addSeparator", lua.create_function(add_separator)?)?;
    tbl.set("addSpacer", lua.create_function(add_spacer)?)?;
    tbl.set("addTreeView", lua.create_function(add_tree_view)?)?;
    tbl.set("addRadioButton", lua.create_function(add_radio_button)?)?;
    tbl.set("addScrollBar", lua.create_function(add_scroll_bar)?)?;
    tbl.set("addGuiWindow", lua.create_function(add_gui_window)?)?;
    tbl.set("addSplitPanel", lua.create_function(add_split_panel)?)?;
    tbl.set("addDockPanel", lua.create_function(add_dock_panel)?)?;
    tbl.set("addToolbar", lua.create_function(add_toolbar)?)?;
    tbl.set("addMenuBar", lua.create_function(add_menu_bar)?)?;
    tbl.set("addMenuItem", lua.create_function(add_menu_item)?)?;
    tbl.set("addDialog", lua.create_function(add_dialog)?)?;
    tbl.set("addStatusBar", lua.create_function(add_status_bar)?)?;
    tbl.set("addAccordion", lua.create_function(add_accordion)?)?;
    tbl.set("addTooltipPanel", lua.create_function(add_tooltip_panel)?)?;
    tbl.set("addColorPicker", lua.create_function(add_color_picker)?)?;
    tbl.set("addGuiTable", lua.create_function(add_gui_table)?)?;
    tbl.set("addImageWidget", lua.create_function(add_image_widget)?)?;
    tbl.set("addChild", lua.create_function(add_child)?)?;
    tbl.set("removeChild", lua.create_function(remove_child)?)?;
    tbl.set("setFocus", lua.create_function(set_focus)?)?;
    tbl.set("addToast", lua.create_function(add_toast)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("mousePressed", lua.create_function(mouse_pressed)?)?;
    tbl.set("mouseReleased", lua.create_function(mouse_released)?)?;
    tbl.set("mouseMoved", lua.create_function(mouse_moved)?)?;
    tbl.set("keyPressed", lua.create_function(key_pressed)?)?;
    tbl.set("textInput", lua.create_function(text_input)?)?;
    tbl.set("wheelMoved", lua.create_function(wheel_moved)?)?;
    tbl.set("insertText", lua.create_function(insert_text)?)?;
    tbl.set("backspace", lua.create_function(backspace)?)?;
    tbl.set("setValue", lua.create_function(set_value)?)?;
    tbl.set("addItem", lua.create_function(add_item)?)?;
    tbl.set("removeItem", lua.create_function(remove_item)?)?;
    tbl.set("addItem", lua.create_function(add_item)?)?;
    tbl.set("removeItem", lua.create_function(remove_item)?)?;
    tbl.set("addTab", lua.create_function(add_tab)?)?;
    tbl.set("removeTab", lua.create_function(remove_tab)?)?;
    tbl.set("setViewport", lua.create_function(set_viewport)?)?;
    tbl.set("setRange", lua.create_function(set_range)?)?;
    tbl.set("addLineSeries", lua.create_function(add_line_series)?)?;
    tbl.set("addScatterSeries", lua.create_function(add_scatter_series)?)?;
    tbl.set("addBarSeries", lua.create_function(add_bar_series)?)?;
    tbl.set("removeSeries", lua.create_function(remove_series)?)?;
    tbl.set("setShowGrid", lua.create_function(set_show_grid)?)?;
    tbl.set("setShowAxes", lua.create_function(set_show_axes)?)?;
    tbl.set("setShowLabels", lua.create_function(set_show_labels)?)?;
    tbl.set("setGridColor", lua.create_function(set_grid_color)?)?;
    tbl.set("setAxisColor", lua.create_function(set_axis_color)?)?;
    tbl.set("setBgColor", lua.create_function(set_bg_color)?)?;
    tbl.set("setTitle", lua.create_function(set_title)?)?;
    tbl.set("setAxisLabels", lua.create_function(set_axis_labels)?)?;
    tbl.set("setCursorPosition", lua.create_function(set_cursor_position)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("addNode", lua.create_function(add_node)?)?;
    tbl.set("toggleNode", lua.create_function(toggle_node)?)?;
    tbl.set("removeNode", lua.create_function(remove_node)?)?;
    tbl.set("setNodeText", lua.create_function(set_node_text)?)?;
    tbl.set("setNodeIcon", lua.create_function(set_node_icon)?)?;
    tbl.set("expandNode", lua.create_function(expand_node)?)?;
    tbl.set("collapseNode", lua.create_function(collapse_node)?)?;
    tbl.set("setSelectedNode", lua.create_function(set_selected_node)?)?;
    tbl.set("addButton", lua.create_function(add_button)?)?;
    tbl.set("addSpacer", lua.create_function(add_spacer)?)?;
    tbl.set("setButtonEnabled", lua.create_function(set_button_enabled)?)?;
    tbl.set("setButtonToggled", lua.create_function(set_button_toggled)?)?;
    tbl.set("setStyle", lua.create_function(set_style)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    luna.set("gui", tbl)?;
    Ok(())
}
