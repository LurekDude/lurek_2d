-- content/examples/terminal.lua
-- Practical usage examples for the lurek.terminal API (82 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.terminal.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/terminal.lua

print("[example] lurek.terminal — 82 API entries")

-- ── lurek.terminal.* free functions ──

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal grid with the given dimensions.
-- Call when you need to create a new terminal.
local ok, obj = pcall(function() return lurek.terminal.newTerminal(10, 10) end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newTerminal ok=", ok)

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget at 1-based coordinates.
-- Call when you need to create a new label.
local ok, obj = pcall(function() return lurek.terminal.newLabel(nil, nil, "text value") end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newLabel ok=", ok)

--@api-stub: lurek.terminal.newButton
-- Creates a new button widget at 1-based coordinates.
-- Call when you need to create a new button.
local ok, obj = pcall(function() return lurek.terminal.newButton() end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newButton ok=", ok)

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text box widget at 1-based coordinates.
-- Call when you need to create a new text box.
local ok, obj = pcall(function() return lurek.terminal.newTextBox(nil, nil, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newTextBox ok=", ok)

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget at 1-based coordinates.
-- Call when you need to create a new list.
local ok, obj = pcall(function() return lurek.terminal.newList(nil, nil, 100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newList ok=", ok)

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget at 1-based coordinates.
-- Call when you need to create a new border.
local ok, obj = pcall(function() return lurek.terminal.newBorder(nil, nil, 100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newBorder ok=", ok)

--@api-stub: lurek.terminal.newPanel
-- Creates a new container panel widget at 1-based coordinates.
-- Call when you need to create a new panel.
local ok, obj = pcall(function() return lurek.terminal.newPanel(nil, nil, 100, 100) end)
if ok and obj then print("created:", obj) end
print("lurek.terminal.newPanel ok=", ok)

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line to this terminal's scrollback buffer.
-- Call when you need to invoke push scrollback.
local ok, err = pcall(function() lurek.terminal.pushScrollback(nil, nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.terminal.pushScrollback done=", ok)

--@api-stub: lurek.terminal.getScrollback
-- Returns a table of lines from the scrollback buffer.
-- Call when you need to read scrollback.
local ok, value = pcall(function() return lurek.terminal.getScrollback(nil, nil, 10) end)
local v = ok and value or "(unavailable)"
print("lurek.terminal.getScrollback ->", v)

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently in this terminal's scrollback buffer.
-- Call when you need to invoke scrollback len.
local ok, result = pcall(function() return lurek.terminal.scrollbackLen(nil) end)
if ok then print("lurek.terminal.scrollbackLen ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the scrollback buffer.
-- Call when you need to assign scrollback cap.
local ok, err = pcall(function() lurek.terminal.setScrollbackCap(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.terminal.setScrollbackCap applied=", ok)

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to this terminal's history.
-- Call when you need to invoke push cmd history.
local ok, err = pcall(function() lurek.terminal.pushCmdHistory(nil, nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.terminal.pushCmdHistory done=", ok)

--@api-stub: lurek.terminal.prevCmd
-- Steps one entry back in command history (toward older commands).
-- Call when you need to invoke prev cmd.
local ok, result = pcall(function() return lurek.terminal.prevCmd(nil) end)
if ok then print("lurek.terminal.prevCmd ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.nextCmd
-- Steps one entry forward in command history (toward newer commands).
-- Call when you need to invoke next cmd.
local ok, result = pcall(function() return lurek.terminal.nextCmd(nil) end)
if ok then print("lurek.terminal.nextCmd ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the total number of entries in this terminal's command history.
-- Call when you need to invoke cmd history len.
local ok, result = pcall(function() return lurek.terminal.cmdHistoryLen(nil) end)
if ok then print("lurek.terminal.cmdHistoryLen ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.clearCmdHistory
-- Clears all entries from this terminal's command history.
-- Call when you need to invoke clear cmd history.
local ok, err = pcall(function() lurek.terminal.clearCmdHistory(nil) end)
if not ok then print("skipped:", err) end
print("lurek.terminal.clearCmdHistory cleared=", ok)

--@api-stub: lurek.terminal.applyTheme
-- Applies a named colour theme to a terminal, recolouring all existing cells.
-- Call when you need to invoke apply theme.
local ok, err = pcall(function() lurek.terminal.applyTheme(nil, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.terminal.applyTheme applied=", ok)

--@api-stub: lurek.terminal.printHighlighted
-- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
-- Call when you need to render highlighted.
local ok, result = pcall(function() return lurek.terminal.printHighlighted() end)
if ok then print("lurek.terminal.printHighlighted ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.stripAnsi
-- Strips all ANSI escape codes from `text` and returns the plain string.
-- Call when you need to invoke strip ansi.
local ok, result = pcall(function() return lurek.terminal.stripAnsi("text value") end)
if ok then print("lurek.terminal.stripAnsi ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.parseAnsi
-- Parses `text` into coloured spans.
-- Returns an array of tables, each with.
local ok, result = pcall(function() return lurek.terminal.parseAnsi("text value") end)
if ok then print("lurek.terminal.parseAnsi ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.printAnsi
-- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
-- Call when you need to render ansi.
local ok, result = pcall(function() return lurek.terminal.printAnsi(nil, nil, nil, "text value") end)
if ok then print("lurek.terminal.printAnsi ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.addCompletion
-- Adds a candidate string to the tab-completion engine.
-- Call when you need to add completion.
local ok, err = pcall(function() lurek.terminal.addCompletion(nil) end)
if not ok then print("mutator skipped:", err) end
print("lurek.terminal.addCompletion done=", ok)

--@api-stub: lurek.terminal.removeCompletion
-- Removes a candidate string from the tab-completion engine.
-- Call when you need to remove completion.
local ok, err = pcall(function() lurek.terminal.removeCompletion(nil) end)
if not ok then print("skipped:", err) end
print("lurek.terminal.removeCompletion cleared=", ok)

--@api-stub: lurek.terminal.clearCompletions
-- Clears all completion candidates.
-- Call when you need to invoke clear completions.
local ok, err = pcall(function() lurek.terminal.clearCompletions() end)
if not ok then print("skipped:", err) end
print("lurek.terminal.clearCompletions cleared=", ok)

--@api-stub: lurek.terminal.getCompletions
-- Returns all registered candidates that start with `prefix`, as a sorted array.
-- Call when you need to read completions.
local ok, value = pcall(function() return lurek.terminal.getCompletions(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.terminal.getCompletions ->", v)

--@api-stub: lurek.terminal.nextCompletion
-- Returns the next candidate for `prefix`, cycling on repeated calls.
-- Call when you need to invoke next completion.
local ok, result = pcall(function() return lurek.terminal.nextCompletion(nil) end)
if ok then print("lurek.terminal.nextCompletion ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the cycling cursor without clearing the candidate list.
-- Call when you need to invoke reset completion.
local ok, err = pcall(function() lurek.terminal.resetCompletion() end)
if not ok then print("skipped:", err) end
print("lurek.terminal.resetCompletion cleared=", ok)

--@api-stub: lurek.terminal.getMaxCols
-- Returns the maximum number of columns a Terminal can be constructed with.
-- Call when you need to read max cols.
local ok, value = pcall(function() return lurek.terminal.getMaxCols() end)
local v = ok and value or "(unavailable)"
print("lurek.terminal.getMaxCols ->", v)

--@api-stub: lurek.terminal.getMaxRows
-- Returns the maximum number of rows a Terminal can be constructed with.
-- Call when you need to read max rows.
local ok, value = pcall(function() return lurek.terminal.getMaxRows() end)
local v = ok and value or "(unavailable)"
print("lurek.terminal.getMaxRows ->", v)

-- ── Terminal methods ──

--@api-stub: Terminal:set
-- Sets a cell at 1-based coordinates with character FG and BG colours.
-- Call when you need to invoke set.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:set({}) end)
  print("Terminal:set ->", ok, result)
end

--@api-stub: Terminal:get
-- Returns the cell data at 1-based coordinates.
-- Call when you need to invoke get.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:get(nil, nil) end)
  print("Terminal:get ->", ok, result)
end

--@api-stub: Terminal:clear
-- Clears all cells to defaults.
-- Call when you need to invoke clear.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Terminal:clear ->", ok, result)
end

--@api-stub: Terminal:getDimensions
-- Returns the terminal grid dimensions.
-- Call when you need to read dimensions.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("Terminal:getDimensions ->", ok, result)
end

--@api-stub: Terminal:getCellSize
-- Returns the current cell size in pixels derived from the active font.
-- Call when you need to read cell size.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:getCellSize() end)
  print("Terminal:getCellSize ->", ok, result)
end

--@api-stub: Terminal:addWidget
-- Attaches a widget to this terminal.
-- Call when you need to add widget.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:addWidget(nil) end)
  print("Terminal:addWidget ->", ok, result)
end

--@api-stub: Terminal:removeWidget
-- Detaches a widget from this terminal.
-- Call when you need to remove widget.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:removeWidget(nil) end)
  print("Terminal:removeWidget ->", ok, result)
end

--@api-stub: Terminal:clearWidgets
-- Detaches all widgets from this terminal.
-- Call when you need to invoke clear widgets.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:clearWidgets() end)
  print("Terminal:clearWidgets ->", ok, result)
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of attached widgets.
-- Call when you need to read widget count.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:getWidgetCount() end)
  print("Terminal:getWidgetCount ->", ok, result)
end

--@api-stub: Terminal:setFocus
-- Sets the focused widget, or clears focus if nil is passed.
-- Call when you need to assign focus.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:setFocus(nil) end)
  print("Terminal:setFocus ->", ok, result)
end

--@api-stub: Terminal:getFocused
-- Returns the currently focused widget, or nil.
-- Call when you need to read focused.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:getFocused() end)
  print("Terminal:getFocused ->", ok, result)
end

--@api-stub: Terminal:keypressed
-- Routes a key press to the focused widget and fires callbacks.
-- Call when you need to invoke keypressed.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:keypressed("key") end)
  print("Terminal:keypressed ->", ok, result)
end

--@api-stub: Terminal:textinput
-- Routes text input to the focused widget and fires callbacks.
-- Call when you need to invoke textinput.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:textinput("text value") end)
  print("Terminal:textinput ->", ok, result)
end

--@api-stub: Terminal:render
-- Renders the terminal grid and widgets as render commands.
-- Call when you need to invoke render.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:render(0, 0) end)
  print("Terminal:render ->", ok, result)
end

--@api-stub: Terminal:setFont
-- Sets the terminal font by pixel height, snapping to the nearest built-in size.
-- Call when you need to assign font.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:setFont(100) end)
  print("Terminal:setFont ->", ok, result)
end

--@api-stub: Terminal:setCellSize
-- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
-- Call when you need to assign cell size.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:setCellSize(100, 100) end)
  print("Terminal:setCellSize ->", ok, result)
end

--@api-stub: Terminal:resetCellSize
-- Removes the cell size override, restoring font-derived cell dimensions.
-- Call when you need to invoke reset cell size.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:resetCellSize() end)
  print("Terminal:resetCellSize ->", ok, result)
end

--@api-stub: Terminal:getCellSize
-- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
-- Call when you need to read cell size.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:getCellSize() end)
  print("Terminal:getCellSize ->", ok, result)
end

--@api-stub: Terminal:autoResize
-- Resizes the window to exactly fit the terminal grid at the current font size.
-- Call when you need to invoke auto resize.
-- Build a Terminal via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newTerminal(...)
if instance then
  local ok, result = pcall(function() return instance:autoResize() end)
  print("Terminal:autoResize ->", ok, result)
end

-- ── Widget methods ──

--@api-stub: Widget:setPosition
-- Sets the widget position from 1-based coordinates.
-- Call when you need to assign position.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(nil, nil) end)
  print("Widget:setPosition ->", ok, result)
end

--@api-stub: Widget:getPosition
-- Returns the widget position as 1-based coordinates.
-- Call when you need to read position.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Widget:getPosition ->", ok, result)
end

--@api-stub: Widget:setSize
-- Sets the widget size in cells.
-- Call when you need to assign size.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setSize(100, 100) end)
  print("Widget:setSize ->", ok, result)
end

--@api-stub: Widget:getSize
-- Returns the widget size in cells.
-- Call when you need to read size.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("Widget:getSize ->", ok, result)
end

--@api-stub: Widget:setVisible
-- Sets the widget visibility.
-- Call when you need to assign visible.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setVisible(nil) end)
  print("Widget:setVisible ->", ok, result)
end

--@api-stub: Widget:isVisible
-- Returns whether the widget is visible.
-- Call when you need to check is visible.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:isVisible() end)
  print("Widget:isVisible ->", ok, result)
end

--@api-stub: Widget:setEnabled
-- Sets whether the widget accepts input.
-- Call when you need to assign enabled.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(nil) end)
  print("Widget:setEnabled ->", ok, result)
end

--@api-stub: Widget:isEnabled
-- Returns whether the widget accepts input.
-- Call when you need to check is enabled.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled() end)
  print("Widget:isEnabled ->", ok, result)
end

--@api-stub: Widget:setTag
-- Sets the free-form identification tag.
-- Call when you need to assign tag.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setTag("tag") end)
  print("Widget:setTag ->", ok, result)
end

--@api-stub: Widget:getTag
-- Returns the free-form identification tag.
-- Call when you need to read tag.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getTag() end)
  print("Widget:getTag ->", ok, result)
end

--@api-stub: Widget:setText
-- Sets the text content of a label, button, or text box widget.
-- Call when you need to assign text.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setText("text value") end)
  print("Widget:setText ->", ok, result)
end

--@api-stub: Widget:getText
-- Returns the text content of a label, button, or text box widget.
-- Call when you need to read text.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getText() end)
  print("Widget:getText ->", ok, result)
end

--@api-stub: Widget:getColor
-- Returns the colour of a label or border widget.
-- Call when you need to read color.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getColor() end)
  print("Widget:getColor ->", ok, result)
end

--@api-stub: Widget:setOnClick
-- Registers a click callback for a button widget.
-- Call when you need to assign on click.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setOnClick(function() end) end)
  print("Widget:setOnClick ->", ok, result)
end

--@api-stub: Widget:setMaxLength
-- Sets the maximum character length of a text box widget.
-- Call when you need to assign max length.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setMaxLength(nil) end)
  print("Widget:setMaxLength ->", ok, result)
end

--@api-stub: Widget:getMaxLength
-- Returns the maximum character length of a text box widget.
-- Call when you need to read max length.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getMaxLength() end)
  print("Widget:getMaxLength ->", ok, result)
end

--@api-stub: Widget:setOnChange
-- Registers a text change callback for a text box widget.
-- Call when you need to assign on change.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setOnChange(function() end) end)
  print("Widget:setOnChange ->", ok, result)
end

--@api-stub: Widget:addItem
-- Adds an item to a list widget.
-- Call when you need to add item.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:addItem(nil) end)
  print("Widget:addItem ->", ok, result)
end

--@api-stub: Widget:removeItem
-- Removes an item from a list widget by 1-based index.
-- Call when you need to remove item.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:removeItem(1) end)
  print("Widget:removeItem ->", ok, result)
end

--@api-stub: Widget:clearItems
-- Removes all items from a list widget.
-- Call when you need to invoke clear items.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:clearItems() end)
  print("Widget:clearItems ->", ok, result)
end

--@api-stub: Widget:getItemCount
-- Returns the number of items in a list widget.
-- Call when you need to read item count.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getItemCount() end)
  print("Widget:getItemCount ->", ok, result)
end

--@api-stub: Widget:getItem
-- Returns a list item by 1-based index.
-- Call when you need to read item.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getItem(1) end)
  print("Widget:getItem ->", ok, result)
end

--@api-stub: Widget:setSelected
-- Sets the selected item in a list widget by 1-based index.
-- Call when you need to assign selected.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setSelected(1) end)
  print("Widget:setSelected ->", ok, result)
end

--@api-stub: Widget:getSelected
-- Returns the selected item index (1-based) in a list widget, or nil.
-- Call when you need to read selected.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getSelected() end)
  print("Widget:getSelected ->", ok, result)
end

--@api-stub: Widget:setOnSelect
-- Registers a selection change callback for a list widget.
-- Call when you need to assign on select.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setOnSelect(function() end) end)
  print("Widget:setOnSelect ->", ok, result)
end

--@api-stub: Widget:setStyle
-- Sets the border style of a border widget.
-- Call when you need to assign style.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setStyle("style_name") end)
  print("Widget:setStyle ->", ok, result)
end

--@api-stub: Widget:getStyle
-- Returns the border style name of a border widget.
-- Call when you need to read style.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getStyle() end)
  print("Widget:getStyle ->", ok, result)
end

--@api-stub: Widget:setTitle
-- Sets the title of a border widget.
-- Call when you need to assign title.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:setTitle(nil) end)
  print("Widget:setTitle ->", ok, result)
end

--@api-stub: Widget:getTitle
-- Returns the title of a border widget.
-- Call when you need to read title.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getTitle() end)
  print("Widget:getTitle ->", ok, result)
end

--@api-stub: Widget:addChild
-- Adds a child widget to a panel widget.
-- Call when you need to add child.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:addChild(nil) end)
  print("Widget:addChild ->", ok, result)
end

--@api-stub: Widget:removeChild
-- Removes a child widget from a panel widget.
-- Call when you need to remove child.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:removeChild(nil) end)
  print("Widget:removeChild ->", ok, result)
end

--@api-stub: Widget:clearChildren
-- Removes all children from a panel widget.
-- Call when you need to invoke clear children.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:clearChildren() end)
  print("Widget:clearChildren ->", ok, result)
end

--@api-stub: Widget:getChildCount
-- Returns the number of children in a panel widget.
-- Call when you need to read child count.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getChildCount() end)
  print("Widget:getChildCount ->", ok, result)
end

--@api-stub: Widget:getChild
-- Returns a child widget from a panel by 1-based index, or nil.
-- Call when you need to read child.
-- Build a Widget via the appropriate lurek.terminal.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.terminal.newWidget(...)
if instance then
  local ok, result = pcall(function() return instance:getChild(1) end)
  print("Widget:getChild ->", ok, result)
end

