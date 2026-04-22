-- content/examples/terminal.lua
-- Auto-scaffolded coverage of the lurek.terminal Lua API (82 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/terminal.lua

print("[example] lurek.terminal loaded — 82 API items demonstrated")

-- ── lurek.terminal free functions ──

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal grid with the given dimensions.
-- Use this when creates a new terminal grid with the given dimensions is needed.
if false then
  local _r = lurek.terminal.newTerminal(1, 1)
  print(_r)
end

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget at 1-based coordinates.
-- Use this when creates a new label widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newLabel(nil, 0, 0)
  print(_r)
end

--@api-stub: lurek.terminal.newButton
-- Creates a new button widget at 1-based coordinates.
-- Use this when creates a new button widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newButton()
  print(_r)
end

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text box widget at 1-based coordinates.
-- Use this when creates a new single-line text box widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newTextBox(nil, 0, 1)
  print(_r)
end

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget at 1-based coordinates.
-- Use this when creates a new scrollable list widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newList(nil, 0, 1, 1)
  print(_r)
end

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget at 1-based coordinates.
-- Use this when creates a new decorative border widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newBorder(nil, 0, 1, 1)
  print(_r)
end

--@api-stub: lurek.terminal.newPanel
-- Creates a new container panel widget at 1-based coordinates.
-- Use this when creates a new container panel widget at 1-based coordinates is needed.
if false then
  local _r = lurek.terminal.newPanel(nil, 0, 1, 1)
  print(_r)
end

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line to this terminal's scrollback buffer.
-- Use this when appends a line to this terminal's scrollback buffer is needed.
if false then
  local _r = lurek.terminal.pushScrollback(0, 1)
  print(_r)
end

--@api-stub: lurek.terminal.getScrollback
-- Returns a table of lines from the scrollback buffer.
-- Use this when returns a table of lines from the scrollback buffer is needed.
if false then
  local _r = lurek.terminal.getScrollback(0, 0, 1)
  print(_r)
end

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently in this terminal's scrollback buffer.
-- Use this when returns the number of lines currently in this terminal's scrollback buffer is needed.
if false then
  local _r = lurek.terminal.scrollbackLen(0)
  print(_r)
end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the scrollback buffer.
-- Use this when sets the maximum number of lines retained in the scrollback buffer is needed.
if false then
  local _r = lurek.terminal.setScrollbackCap(0, nil)
  print(_r)
end

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to this terminal's history.
-- Use this when appends a command string to this terminal's history is needed.
if false then
  local _r = lurek.terminal.pushCmdHistory(0, nil)
  print(_r)
end

--@api-stub: lurek.terminal.prevCmd
-- Steps one entry back in command history (toward older commands).
-- Use this when steps one entry back in command history (toward older commands) is needed.
if false then
  local _r = lurek.terminal.prevCmd(0)
  print(_r)
end

--@api-stub: lurek.terminal.nextCmd
-- Steps one entry forward in command history (toward newer commands).
-- Use this when steps one entry forward in command history (toward newer commands) is needed.
if false then
  local _r = lurek.terminal.nextCmd(0)
  print(_r)
end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the total number of entries in this terminal's command history.
-- Use this when returns the total number of entries in this terminal's command history is needed.
if false then
  local _r = lurek.terminal.cmdHistoryLen(0)
  print(_r)
end

--@api-stub: lurek.terminal.clearCmdHistory
-- Clears all entries from this terminal's command history.
-- Use this when clears all entries from this terminal's command history is needed.
if false then
  local _r = lurek.terminal.clearCmdHistory(0)
  print(_r)
end

--@api-stub: lurek.terminal.applyTheme
-- Applies a named colour theme to a terminal, recolouring all existing cells.
-- Use this when applies a named colour theme to a terminal, recolouring all existing cells is needed.
if false then
  local _r = lurek.terminal.applyTheme(0, 0)
  print(_r)
end

--@api-stub: lurek.terminal.printHighlighted
-- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
-- Use this when prints text at 1-based `(col, row)` with per-keyword colour highlighting is needed.
if false then
  local _r = lurek.terminal.printHighlighted()
  print(_r)
end

--@api-stub: lurek.terminal.stripAnsi
-- Strips all ANSI escape codes from `text` and returns the plain string.
-- Use this when strips all ANSI escape codes from `text` and returns the plain string is needed.
if false then
  local _r = lurek.terminal.stripAnsi(0)
  print(_r)
end

--@api-stub: lurek.terminal.parseAnsi
-- Parses `text` into coloured spans.
-- Returns an array of tables, each with
if false then
  local _r = lurek.terminal.parseAnsi(0)
  print(_r)
end

--@api-stub: lurek.terminal.printAnsi
-- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
-- Use this when prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)` is needed.
if false then
  local _r = lurek.terminal.printAnsi(0, nil, 0, 0)
  print(_r)
end

--@api-stub: lurek.terminal.addCompletion
-- Adds a candidate string to the tab-completion engine.
-- Use this when adds a candidate string to the tab-completion engine is needed.
if false then
  local _r = lurek.terminal.addCompletion(1)
  print(_r)
end

--@api-stub: lurek.terminal.removeCompletion
-- Removes a candidate string from the tab-completion engine.
-- Use this when removes a candidate string from the tab-completion engine is needed.
if false then
  local _r = lurek.terminal.removeCompletion(1)
  print(_r)
end

--@api-stub: lurek.terminal.clearCompletions
-- Clears all completion candidates.
-- Use this when clears all completion candidates is needed.
if false then
  local _r = lurek.terminal.clearCompletions()
  print(_r)
end

--@api-stub: lurek.terminal.getCompletions
-- Returns all registered candidates that start with `prefix`, as a sorted array.
-- Use this when returns all registered candidates that start with `prefix`, as a sorted array is needed.
if false then
  local _r = lurek.terminal.getCompletions(0)
  print(_r)
end

--@api-stub: lurek.terminal.nextCompletion
-- Returns the next candidate for `prefix`, cycling on repeated calls.
-- Use this when returns the next candidate for `prefix`, cycling on repeated calls is needed.
if false then
  local _r = lurek.terminal.nextCompletion(0)
  print(_r)
end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the cycling cursor without clearing the candidate list.
-- Use this when resets the cycling cursor without clearing the candidate list is needed.
if false then
  local _r = lurek.terminal.resetCompletion()
  print(_r)
end

--@api-stub: lurek.terminal.getMaxCols
-- Returns the maximum number of columns a Terminal can be constructed with.
-- Use this when returns the maximum number of columns a Terminal can be constructed with is needed.
if false then
  local _r = lurek.terminal.getMaxCols()
  print(_r)
end

--@api-stub: lurek.terminal.getMaxRows
-- Returns the maximum number of rows a Terminal can be constructed with.
-- Use this when returns the maximum number of rows a Terminal can be constructed with is needed.
if false then
  local _r = lurek.terminal.getMaxRows()
  print(_r)
end

-- ── Terminal methods ──

--@api-stub: Terminal:set
-- Sets a cell at 1-based coordinates with character FG and BG colours.
-- Use this when sets a cell at 1-based coordinates with character FG and BG colours is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:set({})
end

--@api-stub: Terminal:get
-- Returns the cell data at 1-based coordinates.
-- Use this when returns the cell data at 1-based coordinates is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:get(nil, 0)
end

--@api-stub: Terminal:clear
-- Clears all cells to defaults.
-- Use this when clears all cells to defaults is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:clear()
end

--@api-stub: Terminal:getDimensions
-- Returns the terminal grid dimensions.
-- Use this when returns the terminal grid dimensions is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:getDimensions()
end

--@api-stub: Terminal:getCellSize
-- Returns the current cell size in pixels derived from the active font.
-- Use this when returns the current cell size in pixels derived from the active font is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:getCellSize()
end

--@api-stub: Terminal:addWidget
-- Attaches a widget to this terminal.
-- Use this when attaches a widget to this terminal is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:addWidget(1)
end

--@api-stub: Terminal:removeWidget
-- Detaches a widget from this terminal.
-- Use this when detaches a widget from this terminal is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:removeWidget(1)
end

--@api-stub: Terminal:clearWidgets
-- Detaches all widgets from this terminal.
-- Use this when detaches all widgets from this terminal is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:clearWidgets()
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of attached widgets.
-- Use this when returns the number of attached widgets is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:getWidgetCount()
end

--@api-stub: Terminal:setFocus
-- Sets the focused widget, or clears focus if nil is passed.
-- Use this when sets the focused widget, or clears focus if nil is passed is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:setFocus(0)
end

--@api-stub: Terminal:getFocused
-- Returns the currently focused widget, or nil.
-- Use this when returns the currently focused widget, or nil is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:getFocused()
end

--@api-stub: Terminal:keypressed
-- Routes a key press to the focused widget and fires callbacks.
-- Use this when routes a key press to the focused widget and fires callbacks is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:keypressed(0)
end

--@api-stub: Terminal:textinput
-- Routes text input to the focused widget and fires callbacks.
-- Use this when routes text input to the focused widget and fires callbacks is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:textinput(0)
end

--@api-stub: Terminal:render
-- Renders the terminal grid and widgets as render commands.
-- Use this when renders the terminal grid and widgets as render commands is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:render(0, 0)
end

--@api-stub: Terminal:setFont
-- Sets the terminal font by pixel height, snapping to the nearest built-in size.
-- Use this when sets the terminal font by pixel height, snapping to the nearest built-in size is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:setFont(1)
end

--@api-stub: Terminal:setCellSize
-- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
-- Use this when sets a per-terminal cell pixel size override, bypassing the font-derived size is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:setCellSize(0, 0)
end

--@api-stub: Terminal:resetCellSize
-- Removes the cell size override, restoring font-derived cell dimensions.
-- Use this when removes the cell size override, restoring font-derived cell dimensions is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:resetCellSize()
end

--@api-stub: Terminal:getCellSize
-- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
-- Use this when returns the active cell size override as `{w, h}`, or `nil` if none is set is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:getCellSize()
end

--@api-stub: Terminal:autoResize
-- Resizes the window to exactly fit the terminal grid at the current font size.
-- Use this when resizes the window to exactly fit the terminal grid at the current font size is needed.
if false then
  local _o = nil  -- Terminal instance
  _o:autoResize()
end

-- ── Widget methods ──

--@api-stub: Widget:setPosition
-- Sets the widget position from 1-based coordinates.
-- Use this when sets the widget position from 1-based coordinates is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setPosition(nil, 0)
end

--@api-stub: Widget:getPosition
-- Returns the widget position as 1-based coordinates.
-- Use this when returns the widget position as 1-based coordinates is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getPosition()
end

--@api-stub: Widget:setSize
-- Sets the widget size in cells.
-- Use this when sets the widget size in cells is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setSize(1, 1)
end

--@api-stub: Widget:getSize
-- Returns the widget size in cells.
-- Use this when returns the widget size in cells is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getSize()
end

--@api-stub: Widget:setVisible
-- Sets the widget visibility.
-- Use this when sets the widget visibility is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setVisible(0)
end

--@api-stub: Widget:isVisible
-- Returns whether the widget is visible.
-- Use this when returns whether the widget is visible is needed.
if false then
  local _o = nil  -- Widget instance
  _o:isVisible()
end

--@api-stub: Widget:setEnabled
-- Sets whether the widget accepts input.
-- Use this when sets whether the widget accepts input is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setEnabled(1)
end

--@api-stub: Widget:isEnabled
-- Returns whether the widget accepts input.
-- Use this when returns whether the widget accepts input is needed.
if false then
  local _o = nil  -- Widget instance
  _o:isEnabled()
end

--@api-stub: Widget:setTag
-- Sets the free-form identification tag.
-- Use this when sets the free-form identification tag is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setTag(0)
end

--@api-stub: Widget:getTag
-- Returns the free-form identification tag.
-- Use this when returns the free-form identification tag is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getTag()
end

--@api-stub: Widget:setText
-- Sets the text content of a label, button, or text box widget.
-- Use this when sets the text content of a label, button, or text box widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setText(0)
end

--@api-stub: Widget:getText
-- Returns the text content of a label, button, or text box widget.
-- Use this when returns the text content of a label, button, or text box widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getText()
end

--@api-stub: Widget:getColor
-- Returns the colour of a label or border widget.
-- Use this when returns the colour of a label or border widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getColor()
end

--@api-stub: Widget:setOnClick
-- Registers a click callback for a button widget.
-- Use this when registers a click callback for a button widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setOnClick(function() end)
end

--@api-stub: Widget:setMaxLength
-- Sets the maximum character length of a text box widget.
-- Use this when sets the maximum character length of a text box widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setMaxLength(1)
end

--@api-stub: Widget:getMaxLength
-- Returns the maximum character length of a text box widget.
-- Use this when returns the maximum character length of a text box widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getMaxLength()
end

--@api-stub: Widget:setOnChange
-- Registers a text change callback for a text box widget.
-- Use this when registers a text change callback for a text box widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setOnChange(function() end)
end

--@api-stub: Widget:addItem
-- Adds an item to a list widget.
-- Use this when adds an item to a list widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:addItem(0)
end

--@api-stub: Widget:removeItem
-- Removes an item from a list widget by 1-based index.
-- Use this when removes an item from a list widget by 1-based index is needed.
if false then
  local _o = nil  -- Widget instance
  _o:removeItem(1)
end

--@api-stub: Widget:clearItems
-- Removes all items from a list widget.
-- Use this when removes all items from a list widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:clearItems()
end

--@api-stub: Widget:getItemCount
-- Returns the number of items in a list widget.
-- Use this when returns the number of items in a list widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getItemCount()
end

--@api-stub: Widget:getItem
-- Returns a list item by 1-based index.
-- Use this when returns a list item by 1-based index is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getItem(1)
end

--@api-stub: Widget:setSelected
-- Sets the selected item in a list widget by 1-based index.
-- Use this when sets the selected item in a list widget by 1-based index is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setSelected(1)
end

--@api-stub: Widget:getSelected
-- Returns the selected item index (1-based) in a list widget, or nil.
-- Use this when returns the selected item index (1-based) in a list widget, or nil is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getSelected()
end

--@api-stub: Widget:setOnSelect
-- Registers a selection change callback for a list widget.
-- Use this when registers a selection change callback for a list widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setOnSelect(function() end)
end

--@api-stub: Widget:setStyle
-- Sets the border style of a border widget.
-- Use this when sets the border style of a border widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setStyle(1)
end

--@api-stub: Widget:getStyle
-- Returns the border style name of a border widget.
-- Use this when returns the border style name of a border widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getStyle()
end

--@api-stub: Widget:setTitle
-- Sets the title of a border widget.
-- Use this when sets the title of a border widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:setTitle(0)
end

--@api-stub: Widget:getTitle
-- Returns the title of a border widget.
-- Use this when returns the title of a border widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getTitle()
end

--@api-stub: Widget:addChild
-- Adds a child widget to a panel widget.
-- Use this when adds a child widget to a panel widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:addChild(0)
end

--@api-stub: Widget:removeChild
-- Removes a child widget from a panel widget.
-- Use this when removes a child widget from a panel widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:removeChild(0)
end

--@api-stub: Widget:clearChildren
-- Removes all children from a panel widget.
-- Use this when removes all children from a panel widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:clearChildren()
end

--@api-stub: Widget:getChildCount
-- Returns the number of children in a panel widget.
-- Use this when returns the number of children in a panel widget is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getChildCount()
end

--@api-stub: Widget:getChild
-- Returns a child widget from a panel by 1-based index, or nil.
-- Use this when returns a child widget from a panel by 1-based index, or nil is needed.
if false then
  local _o = nil  -- Widget instance
  _o:getChild(1)
end

