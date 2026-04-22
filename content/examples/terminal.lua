-- content/examples/terminal.lua
-- Scaffolded coverage of the lurek.terminal API (82 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/terminal_api.rs   (Lua binding, arg types, return shape)
--   * src/terminal/                 (semantics, side effects)
--   * docs/specs/terminal.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/terminal.lua

-- ── lurek.terminal.* functions ──

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal grid with the given dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newTerminal
  local _todo = "TODO: write a real lurek.terminal.newTerminal usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newLabel
  local _todo = "TODO: write a real lurek.terminal.newLabel usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newButton
-- Creates a new button widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newButton
  local _todo = "TODO: write a real lurek.terminal.newButton usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text box widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newTextBox
  local _todo = "TODO: write a real lurek.terminal.newTextBox usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newList
  local _todo = "TODO: write a real lurek.terminal.newList usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newBorder
  local _todo = "TODO: write a real lurek.terminal.newBorder usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.newPanel
-- Creates a new container panel widget at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.newPanel
  local _todo = "TODO: write a real lurek.terminal.newPanel usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line to this terminal's scrollback buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.pushScrollback
  local _todo = "TODO: write a real lurek.terminal.pushScrollback usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.getScrollback
-- Returns a table of lines from the scrollback buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.getScrollback
  local _todo = "TODO: write a real lurek.terminal.getScrollback usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently in this terminal's scrollback buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.scrollbackLen
  local _todo = "TODO: write a real lurek.terminal.scrollbackLen usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the scrollback buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.setScrollbackCap
  local _todo = "TODO: write a real lurek.terminal.setScrollbackCap usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to this terminal's history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.pushCmdHistory
  local _todo = "TODO: write a real lurek.terminal.pushCmdHistory usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.prevCmd
-- Steps one entry back in command history (toward older commands).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.prevCmd
  local _todo = "TODO: write a real lurek.terminal.prevCmd usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.nextCmd
-- Steps one entry forward in command history (toward newer commands).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.nextCmd
  local _todo = "TODO: write a real lurek.terminal.nextCmd usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the total number of entries in this terminal's command history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.cmdHistoryLen
  local _todo = "TODO: write a real lurek.terminal.cmdHistoryLen usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.clearCmdHistory
-- Clears all entries from this terminal's command history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.clearCmdHistory
  local _todo = "TODO: write a real lurek.terminal.clearCmdHistory usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.applyTheme
-- Applies a named colour theme to a terminal, recolouring all existing cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.applyTheme
  local _todo = "TODO: write a real lurek.terminal.applyTheme usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.printHighlighted
-- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.printHighlighted
  local _todo = "TODO: write a real lurek.terminal.printHighlighted usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.stripAnsi
-- Strips all ANSI escape codes from `text` and returns the plain string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.stripAnsi
  local _todo = "TODO: write a real lurek.terminal.stripAnsi usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.parseAnsi
-- Parses `text` into coloured spans.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.parseAnsi
  local _todo = "TODO: write a real lurek.terminal.parseAnsi usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.printAnsi
-- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.printAnsi
  local _todo = "TODO: write a real lurek.terminal.printAnsi usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.addCompletion
-- Adds a candidate string to the tab-completion engine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.addCompletion
  local _todo = "TODO: write a real lurek.terminal.addCompletion usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.removeCompletion
-- Removes a candidate string from the tab-completion engine.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.removeCompletion
  local _todo = "TODO: write a real lurek.terminal.removeCompletion usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.clearCompletions
-- Clears all completion candidates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.clearCompletions
  local _todo = "TODO: write a real lurek.terminal.clearCompletions usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.getCompletions
-- Returns all registered candidates that start with `prefix`, as a sorted array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.getCompletions
  local _todo = "TODO: write a real lurek.terminal.getCompletions usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.nextCompletion
-- Returns the next candidate for `prefix`, cycling on repeated calls.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.nextCompletion
  local _todo = "TODO: write a real lurek.terminal.nextCompletion usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the cycling cursor without clearing the candidate list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.resetCompletion
  local _todo = "TODO: write a real lurek.terminal.resetCompletion usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.getMaxCols
-- Returns the maximum number of columns a Terminal can be constructed with.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.getMaxCols
  local _todo = "TODO: write a real lurek.terminal.getMaxCols usage example"
  print(_todo)
end

--@api-stub: lurek.terminal.getMaxRows
-- Returns the maximum number of rows a Terminal can be constructed with.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: lurek.terminal.getMaxRows
  local _todo = "TODO: write a real lurek.terminal.getMaxRows usage example"
  print(_todo)
end

-- ── Terminal methods ──

--@api-stub: Terminal:set
-- Sets a cell at 1-based coordinates with character FG and BG colours.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:set
  local _todo = "TODO: write a real Terminal:set usage example"
  print(_todo)
end

--@api-stub: Terminal:get
-- Returns the cell data at 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:get
  local _todo = "TODO: write a real Terminal:get usage example"
  print(_todo)
end

--@api-stub: Terminal:clear
-- Clears all cells to defaults.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:clear
  local _todo = "TODO: write a real Terminal:clear usage example"
  print(_todo)
end

--@api-stub: Terminal:getDimensions
-- Returns the terminal grid dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:getDimensions
  local _todo = "TODO: write a real Terminal:getDimensions usage example"
  print(_todo)
end

--@api-stub: Terminal:getCellSize
-- Returns the current cell size in pixels derived from the active font.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:getCellSize
  local _todo = "TODO: write a real Terminal:getCellSize usage example"
  print(_todo)
end

--@api-stub: Terminal:addWidget
-- Attaches a widget to this terminal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:addWidget
  local _todo = "TODO: write a real Terminal:addWidget usage example"
  print(_todo)
end

--@api-stub: Terminal:removeWidget
-- Detaches a widget from this terminal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:removeWidget
  local _todo = "TODO: write a real Terminal:removeWidget usage example"
  print(_todo)
end

--@api-stub: Terminal:clearWidgets
-- Detaches all widgets from this terminal.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:clearWidgets
  local _todo = "TODO: write a real Terminal:clearWidgets usage example"
  print(_todo)
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of attached widgets.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:getWidgetCount
  local _todo = "TODO: write a real Terminal:getWidgetCount usage example"
  print(_todo)
end

--@api-stub: Terminal:setFocus
-- Sets the focused widget, or clears focus if nil is passed.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:setFocus
  local _todo = "TODO: write a real Terminal:setFocus usage example"
  print(_todo)
end

--@api-stub: Terminal:getFocused
-- Returns the currently focused widget, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:getFocused
  local _todo = "TODO: write a real Terminal:getFocused usage example"
  print(_todo)
end

--@api-stub: Terminal:keypressed
-- Routes a key press to the focused widget and fires callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:keypressed
  local _todo = "TODO: write a real Terminal:keypressed usage example"
  print(_todo)
end

--@api-stub: Terminal:textinput
-- Routes text input to the focused widget and fires callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:textinput
  local _todo = "TODO: write a real Terminal:textinput usage example"
  print(_todo)
end

--@api-stub: Terminal:render
-- Renders the terminal grid and widgets as render commands.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:render
  local _todo = "TODO: write a real Terminal:render usage example"
  print(_todo)
end

--@api-stub: Terminal:setFont
-- Sets the terminal font by pixel height, snapping to the nearest built-in size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:setFont
  local _todo = "TODO: write a real Terminal:setFont usage example"
  print(_todo)
end

--@api-stub: Terminal:setCellSize
-- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:setCellSize
  local _todo = "TODO: write a real Terminal:setCellSize usage example"
  print(_todo)
end

--@api-stub: Terminal:resetCellSize
-- Removes the cell size override, restoring font-derived cell dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:resetCellSize
  local _todo = "TODO: write a real Terminal:resetCellSize usage example"
  print(_todo)
end

--@api-stub: Terminal:getCellSize
-- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:getCellSize
  local _todo = "TODO: write a real Terminal:getCellSize usage example"
  print(_todo)
end

--@api-stub: Terminal:autoResize
-- Resizes the window to exactly fit the terminal grid at the current font size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Terminal:autoResize
  local _todo = "TODO: write a real Terminal:autoResize usage example"
  print(_todo)
end

-- ── Widget methods ──

--@api-stub: Widget:setPosition
-- Sets the widget position from 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setPosition
  local _todo = "TODO: write a real Widget:setPosition usage example"
  print(_todo)
end

--@api-stub: Widget:getPosition
-- Returns the widget position as 1-based coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getPosition
  local _todo = "TODO: write a real Widget:getPosition usage example"
  print(_todo)
end

--@api-stub: Widget:setSize
-- Sets the widget size in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setSize
  local _todo = "TODO: write a real Widget:setSize usage example"
  print(_todo)
end

--@api-stub: Widget:getSize
-- Returns the widget size in cells.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getSize
  local _todo = "TODO: write a real Widget:getSize usage example"
  print(_todo)
end

--@api-stub: Widget:setVisible
-- Sets the widget visibility.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setVisible
  local _todo = "TODO: write a real Widget:setVisible usage example"
  print(_todo)
end

--@api-stub: Widget:isVisible
-- Returns whether the widget is visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:isVisible
  local _todo = "TODO: write a real Widget:isVisible usage example"
  print(_todo)
end

--@api-stub: Widget:setEnabled
-- Sets whether the widget accepts input.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setEnabled
  local _todo = "TODO: write a real Widget:setEnabled usage example"
  print(_todo)
end

--@api-stub: Widget:isEnabled
-- Returns whether the widget accepts input.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:isEnabled
  local _todo = "TODO: write a real Widget:isEnabled usage example"
  print(_todo)
end

--@api-stub: Widget:setTag
-- Sets the free-form identification tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setTag
  local _todo = "TODO: write a real Widget:setTag usage example"
  print(_todo)
end

--@api-stub: Widget:getTag
-- Returns the free-form identification tag.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getTag
  local _todo = "TODO: write a real Widget:getTag usage example"
  print(_todo)
end

--@api-stub: Widget:setText
-- Sets the text content of a label, button, or text box widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setText
  local _todo = "TODO: write a real Widget:setText usage example"
  print(_todo)
end

--@api-stub: Widget:getText
-- Returns the text content of a label, button, or text box widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getText
  local _todo = "TODO: write a real Widget:getText usage example"
  print(_todo)
end

--@api-stub: Widget:getColor
-- Returns the colour of a label or border widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getColor
  local _todo = "TODO: write a real Widget:getColor usage example"
  print(_todo)
end

--@api-stub: Widget:setOnClick
-- Registers a click callback for a button widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setOnClick
  local _todo = "TODO: write a real Widget:setOnClick usage example"
  print(_todo)
end

--@api-stub: Widget:setMaxLength
-- Sets the maximum character length of a text box widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setMaxLength
  local _todo = "TODO: write a real Widget:setMaxLength usage example"
  print(_todo)
end

--@api-stub: Widget:getMaxLength
-- Returns the maximum character length of a text box widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getMaxLength
  local _todo = "TODO: write a real Widget:getMaxLength usage example"
  print(_todo)
end

--@api-stub: Widget:setOnChange
-- Registers a text change callback for a text box widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setOnChange
  local _todo = "TODO: write a real Widget:setOnChange usage example"
  print(_todo)
end

--@api-stub: Widget:addItem
-- Adds an item to a list widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:addItem
  local _todo = "TODO: write a real Widget:addItem usage example"
  print(_todo)
end

--@api-stub: Widget:removeItem
-- Removes an item from a list widget by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:removeItem
  local _todo = "TODO: write a real Widget:removeItem usage example"
  print(_todo)
end

--@api-stub: Widget:clearItems
-- Removes all items from a list widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:clearItems
  local _todo = "TODO: write a real Widget:clearItems usage example"
  print(_todo)
end

--@api-stub: Widget:getItemCount
-- Returns the number of items in a list widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getItemCount
  local _todo = "TODO: write a real Widget:getItemCount usage example"
  print(_todo)
end

--@api-stub: Widget:getItem
-- Returns a list item by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getItem
  local _todo = "TODO: write a real Widget:getItem usage example"
  print(_todo)
end

--@api-stub: Widget:setSelected
-- Sets the selected item in a list widget by 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setSelected
  local _todo = "TODO: write a real Widget:setSelected usage example"
  print(_todo)
end

--@api-stub: Widget:getSelected
-- Returns the selected item index (1-based) in a list widget, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getSelected
  local _todo = "TODO: write a real Widget:getSelected usage example"
  print(_todo)
end

--@api-stub: Widget:setOnSelect
-- Registers a selection change callback for a list widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setOnSelect
  local _todo = "TODO: write a real Widget:setOnSelect usage example"
  print(_todo)
end

--@api-stub: Widget:setStyle
-- Sets the border style of a border widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setStyle
  local _todo = "TODO: write a real Widget:setStyle usage example"
  print(_todo)
end

--@api-stub: Widget:getStyle
-- Returns the border style name of a border widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getStyle
  local _todo = "TODO: write a real Widget:getStyle usage example"
  print(_todo)
end

--@api-stub: Widget:setTitle
-- Sets the title of a border widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:setTitle
  local _todo = "TODO: write a real Widget:setTitle usage example"
  print(_todo)
end

--@api-stub: Widget:getTitle
-- Returns the title of a border widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getTitle
  local _todo = "TODO: write a real Widget:getTitle usage example"
  print(_todo)
end

--@api-stub: Widget:addChild
-- Adds a child widget to a panel widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:addChild
  local _todo = "TODO: write a real Widget:addChild usage example"
  print(_todo)
end

--@api-stub: Widget:removeChild
-- Removes a child widget from a panel widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:removeChild
  local _todo = "TODO: write a real Widget:removeChild usage example"
  print(_todo)
end

--@api-stub: Widget:clearChildren
-- Removes all children from a panel widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:clearChildren
  local _todo = "TODO: write a real Widget:clearChildren usage example"
  print(_todo)
end

--@api-stub: Widget:getChildCount
-- Returns the number of children in a panel widget.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getChildCount
  local _todo = "TODO: write a real Widget:getChildCount usage example"
  print(_todo)
end

--@api-stub: Widget:getChild
-- Returns a child widget from a panel by 1-based index, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/terminal_api.rs and docs/specs/terminal.md).
do  -- TODO: Widget:getChild
  local _todo = "TODO: write a real Widget:getChild usage example"
  print(_todo)
end

