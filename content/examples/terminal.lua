-- content/examples/terminal.lua
-- lurek.terminal API examples.
-- Run: cargo run -- content/examples/terminal.lua

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal emulator grid and stages a window size that fits its active cell metrics
do
  local console = lurek.terminal.newTerminal(100, 30)
  local cols, rows = console:getDimensions()
  lurek.log.info("console grid is " .. cols .. "x" .. rows, "term")
end

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget that displays static text at the given cell position
do
  local term = lurek.terminal.newTerminal(80, 25)
  local title = lurek.terminal.newLabel(2, 1, "== Inventory ==")
  term:addWidget(title)
end

--@api-stub: lurek.terminal.newButton
-- Creates a new clickable button widget with the given position, size, and label text
do
  local term = lurek.terminal.newTerminal(80, 25)
  local quit_btn = lurek.terminal.newButton(60, 21, 14, 3, "Quit")
  quit_btn:setOnClick(function() lurek.log.info("quit pressed", "menu") end)
  term:addWidget(quit_btn)
end

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text input widget at the given position with a fixed width
do
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 70)
  input:setMaxLength(64)
  term:addWidget(input)
  term:setFocus(input)
end

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget for displaying and selecting items
do
  local term = lurek.terminal.newTerminal(80, 25)
  local saves = lurek.terminal.newList(2, 3, 30, 10)
  saves:addItem("Slot 1 - Forest")
  saves:addItem("Slot 2 - Cave")
  term:addWidget(saves)
end

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget drawn using box-drawing characters
do
  local term = lurek.terminal.newTerminal(80, 25)
  local frame = lurek.terminal.newBorder(1, 1, 80, 25)
  frame:setStyle("double")
  frame:setTitle(" Status ")
  term:addWidget(frame)
end

--@api-stub: lurek.terminal.newPanel
-- Creates a new panel widget that can contain child widgets for grouped layout
do
  local term = lurek.terminal.newTerminal(80, 25)
  local pause_panel = lurek.terminal.newPanel(20, 8, 40, 10)
  pause_panel:addChild(lurek.terminal.newLabel(1, 1, "PAUSED"))
  term:addWidget(pause_panel)
end

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line of text to the terminal scrollback buffer for later retrieval
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "> spawn enemy 100 200")
  lurek.terminal.pushScrollback(term, "spawned goblin#7 at (100, 200)")
end

--@api-stub: lurek.terminal.getScrollback
-- Retrieves a range of lines from the terminal scrollback buffer
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "build complete")
  local recent = lurek.terminal.getScrollback(term, 0, 10)
  lurek.log.info("rendering " .. #recent .. " scrollback lines", "term")
end

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently stored in the terminal scrollback buffer
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "hello")
  if lurek.terminal.scrollbackLen(term) > 500 then
    lurek.log.warn("scrollback growing fast", "term")
  end
end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the terminal scrollback buffer
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.setScrollbackCap(term, 2000)
  lurek.terminal.pushScrollback(term, "cap set to 2000 lines")
end

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to the terminal command history for up/down arrow recall
do
  local term = lurek.terminal.newTerminal(80, 25)
  local submitted = "give gold 500"
  lurek.terminal.pushCmdHistory(term, submitted)
end

--@api-stub: lurek.terminal.prevCmd
-- Navigates backward in the terminal command history, returning the previous command or nil if at the start
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "noclip on")
  local recalled = lurek.terminal.prevCmd(term)
  if recalled then lurek.log.debug("recalled: " .. recalled, "term") end
end

--@api-stub: lurek.terminal.nextCmd
-- Navigates forward in the terminal command history, returning the next command or nil if at the end
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "tp 0 0")
  lurek.terminal.prevCmd(term)
  local newer = lurek.terminal.nextCmd(term)
  lurek.log.debug("next cmd: " .. tostring(newer), "term")
end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the number of commands currently stored in the terminal command history
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "kill all")
  local n = lurek.terminal.cmdHistoryLen(term)
  lurek.log.info("history depth: " .. n, "term")
end

--@api-stub: lurek.terminal.clearCmdHistory
-- Removes all entries from the terminal command history
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "spawn enemy 50 50")
  lurek.terminal.clearCmdHistory(term)
end

--@api-stub: lurek.terminal.applyTheme
-- Applies a named color theme to the terminal, setting default foreground and background colors
do
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.applyTheme(term, "dracula")
end

--@api-stub: lurek.terminal.printHighlighted
-- Renders syntax-highlighted text onto the terminal grid using a table of highlight rules with regex patterns and colors
do
  local term = lurek.terminal.newTerminal(80, 25)
  local rules = {
    { pattern = "ERROR", fg = { 255, 80, 80 } },
    { pattern = "%d+",   fg = { 120, 200, 255 } },
  }
  lurek.terminal.printHighlighted(term, 2, 5, "ERROR at line 42", rules)
end

--@api-stub: lurek.terminal.stripAnsi
-- Removes all ANSI escape sequences from a string, returning plain text
do
  local raw = "\27[31mERROR:\27[0m boss spawn failed"
  local plain = lurek.terminal.stripAnsi(raw)
  lurek.log.warn("clean message: " .. plain, "term")
end

--@api-stub: lurek.terminal.parseAnsi
-- Parses ANSI escape sequences in a string into an array of span tables with text, bold, fg, and bg fields
do
  local spans = lurek.terminal.parseAnsi("\27[1;32mOK\27[0m loaded")
  for _, s in ipairs(spans) do
    lurek.log.debug("span '" .. s.text .. "' bold=" .. tostring(s.bold), "term")
  end
end

--@api-stub: lurek.terminal.printAnsi
-- Renders ANSI-colored text directly onto the terminal grid at the given cell position
do
  local term = lurek.terminal.newTerminal(80, 25)
  local line = "\27[33mWARN:\27[0m low ammo"
  lurek.terminal.printAnsi(term, 2, 3, line)
end

--@api-stub: lurek.terminal.addCompletion
-- Registers a candidate string for tab-completion in the shared completion engine
do
  lurek.terminal.addCompletion("spawn")
  lurek.terminal.addCompletion("teleport")
  lurek.terminal.addCompletion("give")
end

--@api-stub: lurek.terminal.removeCompletion
-- Removes a previously registered completion candidate from the shared completion engine
do
  lurek.terminal.addCompletion("debug_crash")
  lurek.terminal.removeCompletion("debug_crash")
end

--@api-stub: lurek.terminal.clearCompletions
-- Removes all registered completion candidates from the shared completion engine
do
  lurek.terminal.addCompletion("noclip")
  lurek.terminal.clearCompletions()
end

--@api-stub: lurek.terminal.getCompletions
-- Returns all completion candidates matching the given prefix string
do
  lurek.terminal.addCompletion("spawn_enemy")
  lurek.terminal.addCompletion("spawn_item")
  local hits = lurek.terminal.getCompletions("spawn")
  lurek.log.info("matches: " .. #hits, "term")
end

--@api-stub: lurek.terminal.nextCompletion
-- Cycles to the next matching completion candidate for the given prefix, wrapping around after the last match
do
  lurek.terminal.addCompletion("give_gold")
  lurek.terminal.addCompletion("give_xp")
  local first = lurek.terminal.nextCompletion("give")
  if first then lurek.log.debug("tab: " .. first, "term") end
end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the completion cycling state so the next call to nextCompletion starts from the first match
do
  lurek.terminal.addCompletion("kill_all")
  lurek.terminal.nextCompletion("kill")
  lurek.terminal.resetCompletion()
end

--@api-stub: lurek.terminal.getMaxCols
-- Returns the engine-defined maximum number of columns a terminal grid can have
do
  local max_cols = lurek.terminal.getMaxCols()
  local desired = math.min(120, max_cols)
  lurek.log.info("using " .. desired .. " cols (cap " .. max_cols .. ")", "term")
end

--@api-stub: lurek.terminal.getMaxRows
-- Returns the engine-defined maximum number of rows a terminal grid can have
do
  local max_rows = lurek.terminal.getMaxRows()
  local desired = math.min(60, max_rows)
  lurek.log.info("using " .. desired .. " rows (cap " .. max_rows .. ")", "term")
end

-- Terminal methods

--@api-stub: Terminal:set
-- Sets the  of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(10, 5, "@", 1, 1, 0, 1, 0, 0, 0, 0)
  term:set(11, 5, "!", 1, 0.4, 0.4, 1)
end

--@api-stub: Terminal:get
-- Returns the  of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(3, 3, "X", 1, 0, 0, 1)
  local ch, r, g, b = term:get(3, 3)
  lurek.log.debug("cell " .. ch .. " fg=" .. r .. "," .. g .. "," .. b, "term")
end

--@api-stub: Terminal:clear
-- Clears all items from this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(1, 1, "#", 1, 1, 1, 1)
  term:clear()
end

--@api-stub: Terminal:getDimensions
-- Returns the dimensions of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local cols, rows = term:getDimensions()
  local centre = lurek.terminal.newLabel(math.floor(cols / 2) - 3, math.floor(rows / 2), "HELLO")
  term:addWidget(centre)
end
-- do  -- Terminal:getCellSize
--   pcall(function()
--     local term = lurek.terminal.newTerminal(80, 25)
--     local cw, ch = term:getCellSize()
--     lurek.log.info("cell pixels: " .. cw .. "x" .. ch, "term")
--   end)
-- end

--@api-stub: Terminal:addWidget
-- Adds a widget to this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local hp_label = lurek.terminal.newLabel(2, 2, "HP: 100/100")
  term:addWidget(hp_label)
end

--@api-stub: Terminal:removeWidget
-- Removes a widget from this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local toast = lurek.terminal.newLabel(20, 1, "Item picked up!")
  term:addWidget(toast)
  term:removeWidget(toast)
end

--@api-stub: Terminal:clearWidgets
-- Clears all widgets items from this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "old screen"))
  term:clearWidgets()
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of widget items in this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "a"))
  if term:getWidgetCount() == 0 then
    lurek.log.warn("no widgets attached", "term")
  end
end

--@api-stub: Terminal:setFocus
-- Sets the focus of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
end

--@api-stub: Terminal:getFocused
-- Returns the focused of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
  if term:getFocused() == input then
    lurek.log.debug("input has focus", "term")
  end
end

--@api-stub: Terminal:keypressed
-- Forwards a key press event to this terminal for input handling.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "OK")
  btn:setOnClick(function() lurek.log.info("ok clicked", "ui") end)
  term:addWidget(btn)
  term:setFocus(btn)
  local consumed = term:keypressed("return")
  lurek.log.debug("consumed=" .. tostring(consumed), "term")
end

--@api-stub: Terminal:textinput
-- Forwards a text input event to this terminal for input handling.
do
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
  term:textinput("h")
  term:textinput("i")
end

--@api-stub: Terminal:render
-- Draws or renders this terminal to the current render target.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(2, 2, "HUD"))
  function lurek.draw() term:render(0, 0) end
end

--@api-stub: Terminal:print
-- Performs the print operation on this terminal.
do
  ---@type LTerminal
  local term = lurek.terminal.newTerminal(80, 25)
  term:print(1, 1, "lurek> print(10)")
  term:print(1, 2, "10")
end

--@api-stub: Terminal:setFont
-- Sets the font of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:setFont(24)
end

--@api-stub: Terminal:setCellSize
-- Sets the cell size of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(16, 16)
end

--@api-stub: Terminal:resetCellSize
-- Resets cell size this terminal to its default state.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(20, 20)
  term:resetCellSize()
end

--@api-stub: Terminal:getCellSize
-- Returns the cell size of this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(18, 18)
  local cw, ch = term:getCellSize()
  lurek.log.debug("cell size " .. cw .. "x" .. ch, "term")
end

--@api-stub: Terminal:autoResize
-- Performs the auto resize operation on this terminal.
do
  local term = lurek.terminal.newTerminal(80, 25)
  term:setFont(20)
  term:autoResize()
end

-- Widget methods

--@api-stub: Widget:setPosition
-- Sets the position of this widget.
do
  local label = lurek.terminal.newLabel(1, 1, "tooltip")
  label:setPosition(40, 12)
end

--@api-stub: Widget:getPosition
-- Returns the position of this widget.
do
  local label = lurek.terminal.newLabel(10, 5, "anchor")
  local col, row = label:getPosition()
  local arrow = lurek.terminal.newLabel(col + 8, row, "->")
  lurek.log.debug("arrow at " .. (col + 8) .. "," .. row, "term")
end

--@api-stub: Widget:setSize
-- Sets the size of this widget.
do
  local list = lurek.terminal.newList(2, 3, 20, 4)
  list:addItem("sword")
  list:addItem("shield")
  list:setSize(20, 8)
end

--@api-stub: Widget:getSize
-- Returns the size of this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 12)
  local w, h = panel:getSize()
  lurek.log.info("panel " .. w .. "x" .. h, "term")
end

--@api-stub: Widget:setVisible
-- Sets the visibility flag for this widget.
do
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")
  hint:setVisible(false)
end

--@api-stub: Widget:isVisible
-- Returns true if this widget is currently visible.
do
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")
  hint:setVisible(false)
  if not hint:isVisible() then
    lurek.log.debug("hint hidden, skipping update", "term")
  end
end

--@api-stub: Widget:setEnabled
-- Sets whether this widget is enabled and accepts input.
do
  local save_btn = lurek.terminal.newButton(2, 2, 10, 1, "Save")
  save_btn:setEnabled(false)
end

--@api-stub: Widget:isEnabled
-- Returns true if this widget is currently enabled.
do
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Go")
  btn:setEnabled(false)
  if not btn:isEnabled() then
    lurek.log.debug("button still disabled", "term")
  end
end

--@api-stub: Widget:setTag
-- Sets the tag of this widget.
do
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")
end

--@api-stub: Widget:getTag
-- Returns the tag of this widget.
do
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")
  if btn:getTag() == "menu.quit" then
    lurek.log.info("quit button identified", "ui")
  end
end

--@api-stub: Widget:setText
-- Sets the text of this widget.
do
  local fps_label = lurek.terminal.newLabel(2, 1, "FPS: --")
  fps_label:setText("FPS: 60")
end

--@api-stub: Widget:getText
-- Returns the text of this widget.
do
  local input = lurek.terminal.newTextBox(2, 24, 40)
  input:setText("noclip on")
  local typed = input:getText()
  lurek.log.info("submit: " .. typed, "term")
end

--@api-stub: Widget:getColor
-- Returns the color of this widget.
do
  local label = lurek.terminal.newLabel(2, 2, "Hello")
  local r, g, b, a = label:getColor()
  lurek.log.debug("colour rgba " .. r .. "," .. g .. "," .. b .. "," .. a, "term")
end

--@api-stub: Widget:setOnClick
-- Sets the on click of this widget.
do
  local btn = lurek.terminal.newButton(2, 2, 12, 1, "[ Start ]")
  btn:setOnClick(function() lurek.log.info("starting game", "menu") end)
end

--@api-stub: Widget:setMaxLength
-- Sets the max length of this widget.
do
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16)
end

--@api-stub: Widget:getMaxLength
-- Returns the max length of this widget.
do
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16)
  local cap = name_box:getMaxLength()
  lurek.log.info("max name length " .. cap, "term")
end

--@api-stub: Widget:setOnChange
-- Sets the on change of this widget.
do
  local search = lurek.terminal.newTextBox(2, 1, 30)
  search:setOnChange(function(text)
    lurek.log.debug("filter: " .. text, "ui")
  end)
end

--@api-stub: Widget:addItem
-- Adds a item to this widget.
do
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion x3")
  inv:addItem("Iron Sword")
  inv:addItem("Lockpick x5")
end

--@api-stub: Widget:removeItem
-- Removes a item from this widget.
do
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion")
  inv:addItem("Bomb")
  inv:removeItem(2)
end

--@api-stub: Widget:clearItems
-- Clears all items items from this widget.
do
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("stale")
  inv:clearItems()
  inv:addItem("fresh")
end

--@api-stub: Widget:getItemCount
-- Returns the number of item items in this widget.
do
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  if inv:getItemCount() == 0 then
    inv:addItem("(empty)")
  end
end

--@api-stub: Widget:getItem
-- Returns the item of this widget.
do
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Iron Sword")
  inv:addItem("Bow")
  local first = inv:getItem(1)
  lurek.log.debug("first item: " .. first, "term")
end

--@api-stub: Widget:setSelected
-- Sets the selected of this widget.
do
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:addItem("Slot 2")
  saves:setSelected(2)
end

--@api-stub: Widget:getSelected
-- Returns the selected of this widget.
do
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:setSelected(1)
  local idx = saves:getSelected()
  if idx then lurek.log.info("loaded slot " .. idx, "save") end
end

--@api-stub: Widget:setOnSelect
-- Sets the on select of this widget.
do
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:setOnSelect(function(idx)
    lurek.log.debug("preview slot " .. tostring(idx), "ui")
  end)
end

--@api-stub: Widget:setStyle
-- Sets the style of this widget.
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("single")
end

--@api-stub: Widget:getStyle
-- Returns the style of this widget.
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("double")
  local style = frame:getStyle()
  lurek.log.info("border style: " .. style, "term")
end

--@api-stub: Widget:setTitle
-- Sets the title of this widget.
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Inventory ")
end

--@api-stub: Widget:getTitle
-- Returns the title of this widget.
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Status ")
  local title = frame:getTitle()
  lurek.log.debug("frame titled: " .. title, "term")
end

--@api-stub: Widget:addChild
-- Adds a child to this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "PAUSED"))
  panel:addChild(lurek.terminal.newButton(1, 3, 10, 1, "Resume"))
end

--@api-stub: Widget:removeChild
-- Removes a child from this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  local hint = lurek.terminal.newLabel(1, 1, "tip")
  panel:addChild(hint)
  panel:removeChild(hint)
end

--@api-stub: Widget:clearChildren
-- Clears all children items from this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "old"))
  panel:clearChildren()
end

--@api-stub: Widget:getChildCount
-- Returns the number of child items in this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "a"))
  local n = panel:getChildCount()
  lurek.log.debug("panel children: " .. n, "term")
end

--@api-stub: Widget:getChild
-- Returns the child of this widget.
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "first"))
  local first = panel:getChild(1)
  if first then lurek.log.debug("got first child", "term") end
end

--@api-stub: Terminal:mousepressed
-- Forwards a mouse press event to this terminal for input handling.
do
  local term = lurek.terminal.newTerminal(80, 24)
  term:mousepressed(10, 5, 1)
  lurek.log.info("mouse event forwarded", "terminal")
end

--@api-stub: Widget:setColor
-- Sets the color of this widget.
do
  local lbl = lurek.terminal.newLabel(1, 1, "OK")
  lbl:setColor(0.2, 0.9, 0.3)
  lurek.log.info("widget colour set", "terminal")
end


-- -----------------------------------------------------------------------------
-- LTerminal methods
-- -----------------------------------------------------------------------------

--@api-stub: LTerminal:type
-- Returns the type name string "LTerminal"
do
  local terminal_obj = lurek.terminal.newTerminal(80, 24)
  local t = terminal_obj:type()
  lurek.log.info("LTerminal:type = " .. t, "terminal")
end
--@api-stub: LTerminal:typeOf
-- Checks whether this object matches a given type name
do
  local terminal_obj2 = lurek.terminal.newTerminal(80, 24)
  lurek.log.info("is LTerminal: " .. tostring(terminal_obj2 and terminal_obj2:typeOf("LTerminal") or false), "terminal")
  lurek.log.info("is wrong: " .. tostring(terminal_obj2 and terminal_obj2:typeOf("Unknown") or false), "terminal")
end
--@api-stub: LWidget:type
-- Returns the type name string "LWidget"
do
  local widget_obj = lurek.terminal.newLabel(0, 0, "hello")
  local t = widget_obj:type()
  lurek.log.info("LWidget:type = " .. t, "terminal")
end
--@api-stub: LWidget:typeOf
-- Checks whether this object matches a given type name
do
  local widget_obj2 = lurek.terminal.newLabel(0, 0, "hello")
  lurek.log.info("is LWidget: " .. tostring(widget_obj2 and widget_obj2:typeOf("LWidget") or false), "terminal")
  lurek.log.info("is wrong: " .. tostring(widget_obj2 and widget_obj2:typeOf("Unknown") or false), "terminal")
end


