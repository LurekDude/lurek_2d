-- content/examples/terminal.lua
-- Hand-written coverage of the lurek.terminal API (82 items).
--
-- The lurek.terminal namespace builds text-grid UIs (in-game consoles,
-- inventory screens, dev REPLs) on top of a fixed-cell font grid with
-- focusable widgets, ANSI parsing, scrollback, and tab completion.
--
-- Run: cargo run -- content/examples/terminal.lua

-- ── lurek.terminal.* functions ──

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal grid with the given dimensions.
-- Pass cols/rows in cells (defaults 80x40); call once at startup and reuse the handle.
do  -- lurek.terminal.newTerminal
  local console = lurek.terminal.newTerminal(100, 30)
  local cols, rows = console:getDimensions()
  lurek.log.info("console grid is " .. cols .. "x" .. rows, "term")
end

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget at 1-based coordinates.
-- Use for static read-only text such as HUD captions or panel headings.
do  -- lurek.terminal.newLabel
  local term = lurek.terminal.newTerminal(80, 25)
  local title = lurek.terminal.newLabel(2, 1, "== Inventory ==")
  term:addWidget(title)
end

--@api-stub: lurek.terminal.newButton
-- Creates a new button widget at 1-based coordinates.
-- Use for clickable menu actions; pair with setOnClick to wire behaviour.
do  -- lurek.terminal.newButton
  local term = lurek.terminal.newTerminal(80, 25)
  local quit_btn = lurek.terminal.newButton(60, 23, 12, 1, "[ Quit ]")
  quit_btn:setOnClick(function() lurek.log.info("quit pressed", "menu") end)
  term:addWidget(quit_btn)
end

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text box widget at 1-based coordinates.
-- Use for command input, naming prompts, or chat composers; focus it to receive textinput.
do  -- lurek.terminal.newTextBox
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 70)
  input:setMaxLength(64)
  term:addWidget(input)
  term:setFocus(input)
end

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget at 1-based coordinates.
-- Use for selectable item lists like inventory or save slots; addItem to populate.
do  -- lurek.terminal.newList
  local term = lurek.terminal.newTerminal(80, 25)
  local saves = lurek.terminal.newList(2, 3, 30, 10)
  saves:addItem("Slot 1 - Forest")
  saves:addItem("Slot 2 - Cave")
  term:addWidget(saves)
end

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget at 1-based coordinates.
-- Use to frame a panel region; setStyle picks single/double/ascii line art.
do  -- lurek.terminal.newBorder
  local term = lurek.terminal.newTerminal(80, 25)
  local frame = lurek.terminal.newBorder(1, 1, 80, 25)
  frame:setStyle("double")
  frame:setTitle(" Status ")
  term:addWidget(frame)
end

--@api-stub: lurek.terminal.newPanel
-- Creates a new container panel widget at 1-based coordinates.
-- Use to group related child widgets so visibility toggles cascade.
do  -- lurek.terminal.newPanel
  local term = lurek.terminal.newTerminal(80, 25)
  local pause_panel = lurek.terminal.newPanel(20, 8, 40, 10)
  pause_panel:addChild(lurek.terminal.newLabel(1, 1, "PAUSED"))
  term:addWidget(pause_panel)
end

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line to this terminal's scrollback buffer.
-- Use after every command echo so history persists when the visible region scrolls.
do  -- lurek.terminal.pushScrollback
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "> spawn enemy 100 200")
  lurek.terminal.pushScrollback(term, "spawned goblin#7 at (100, 200)")
end

--@api-stub: lurek.terminal.getScrollback
-- Returns a table of lines from the scrollback buffer.
-- Pass offset 0 for the most recent lines; useful for redrawing on scroll.
do  -- lurek.terminal.getScrollback
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "build complete")
  local recent = lurek.terminal.getScrollback(term, 0, 10)
  lurek.log.info("rendering " .. #recent .. " scrollback lines", "term")
end

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently in this terminal's scrollback buffer.
-- Use to compute scrollbar thumb size or to detect when buffer hits cap.
do  -- lurek.terminal.scrollbackLen
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "hello")
  if lurek.terminal.scrollbackLen(term) > 500 then
    lurek.log.warn("scrollback growing fast", "term")
  end
end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the scrollback buffer.
-- Cap before pushing high-volume logs to bound memory; older lines are dropped.
do  -- lurek.terminal.setScrollbackCap
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.setScrollbackCap(term, 2000)
  lurek.terminal.pushScrollback(term, "cap set to 2000 lines")
end

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to this terminal's history.
-- Call after the user submits a command so up-arrow can recall it.
do  -- lurek.terminal.pushCmdHistory
  local term = lurek.terminal.newTerminal(80, 25)
  local submitted = "give gold 500"
  lurek.terminal.pushCmdHistory(term, submitted)
end

--@api-stub: lurek.terminal.prevCmd
-- Steps one entry back in command history (toward older commands).
-- Bind to the up-arrow key in your text-box input handler.
do  -- lurek.terminal.prevCmd
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "noclip on")
  local recalled = lurek.terminal.prevCmd(term)
  if recalled then lurek.log.debug("recalled: " .. recalled, "term") end
end

--@api-stub: lurek.terminal.nextCmd
-- Steps one entry forward in command history (toward newer commands).
-- Bind to the down-arrow key; returns nil when past the newest entry.
do  -- lurek.terminal.nextCmd
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "tp 0 0")
  lurek.terminal.prevCmd(term)
  local newer = lurek.terminal.nextCmd(term)
  lurek.log.debug("next cmd: " .. tostring(newer), "term")
end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the total number of entries in this terminal's command history.
-- Use to decide whether to enable up/down recall keys in the UI.
do  -- lurek.terminal.cmdHistoryLen
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "kill all")
  local n = lurek.terminal.cmdHistoryLen(term)
  lurek.log.info("history depth: " .. n, "term")
end

--@api-stub: lurek.terminal.clearCmdHistory
-- Clears all entries from this terminal's command history.
-- Call when starting a fresh session or wiping save data.
do  -- lurek.terminal.clearCmdHistory
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "spawn enemy 50 50")
  lurek.terminal.clearCmdHistory(term)
end

--@api-stub: lurek.terminal.applyTheme
-- Applies a named colour theme to a terminal, recolouring all existing cells.
-- Built-in themes: solarized_dark, solarized_light, monokai, dracula, nord.
do  -- lurek.terminal.applyTheme
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.applyTheme(term, "dracula")
end

--@api-stub: lurek.terminal.printHighlighted
-- Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
-- Pass rules as {pattern=<lua-pattern>, fg={r,g,b}} (0-255 ints) for syntax-style colouring.
do  -- lurek.terminal.printHighlighted
  local term = lurek.terminal.newTerminal(80, 25)
  local rules = {
    { pattern = "ERROR", fg = { 255, 80, 80 } },
    { pattern = "%d+",   fg = { 120, 200, 255 } },
  }
  lurek.terminal.printHighlighted(term, 2, 5, "ERROR at line 42", rules)
end

--@api-stub: lurek.terminal.stripAnsi
-- Strips all ANSI escape codes from `text` and returns the plain string.
-- Use before logging or saving terminal output where colour codes would be noise.
do  -- lurek.terminal.stripAnsi
  local raw = "\27[31mERROR:\27[0m boss spawn failed"
  local plain = lurek.terminal.stripAnsi(raw)
  lurek.log.warn("clean message: " .. plain, "term")
end

--@api-stub: lurek.terminal.parseAnsi
-- Parses `text` into coloured spans.
-- Returned spans have {text, bold, fg?, bg?}; useful for custom rendering or filtering.
do  -- lurek.terminal.parseAnsi
  local spans = lurek.terminal.parseAnsi("\27[1;32mOK\27[0m loaded")
  for _, s in ipairs(spans) do
    lurek.log.debug("span '" .. s.text .. "' bold=" .. tostring(s.bold), "term")
  end
end

--@api-stub: lurek.terminal.printAnsi
-- Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
-- Use to render coloured server logs or REPL output without manually splitting spans.
do  -- lurek.terminal.printAnsi
  local term = lurek.terminal.newTerminal(80, 25)
  local line = "\27[33mWARN:\27[0m low ammo"
  lurek.terminal.printAnsi(term, 2, 3, line)
end

--@api-stub: lurek.terminal.addCompletion
-- Adds a candidate string to the tab-completion engine.
-- Register every command name once at startup so Tab cycles them in the input box.
do  -- lurek.terminal.addCompletion
  lurek.terminal.addCompletion("spawn")
  lurek.terminal.addCompletion("teleport")
  lurek.terminal.addCompletion("give")
end

--@api-stub: lurek.terminal.removeCompletion
-- Removes a candidate string from the tab-completion engine.
-- Call when a command is unregistered (e.g. after a mod is unloaded).
do  -- lurek.terminal.removeCompletion
  lurek.terminal.addCompletion("debug_crash")
  lurek.terminal.removeCompletion("debug_crash")
end

--@api-stub: lurek.terminal.clearCompletions
-- Clears all completion candidates.
-- Call when switching games or contexts so stale commands do not show up.
do  -- lurek.terminal.clearCompletions
  lurek.terminal.addCompletion("noclip")
  lurek.terminal.clearCompletions()
end

--@api-stub: lurek.terminal.getCompletions
-- Returns all registered candidates that start with `prefix`, as a sorted array.
-- Use to render an autocomplete dropdown beneath the input cursor.
do  -- lurek.terminal.getCompletions
  lurek.terminal.addCompletion("spawn_enemy")
  lurek.terminal.addCompletion("spawn_item")
  local hits = lurek.terminal.getCompletions("spawn")
  lurek.log.info("matches: " .. #hits, "term")
end

--@api-stub: lurek.terminal.nextCompletion
-- Returns the next candidate for `prefix`, cycling on repeated calls.
-- Bind to the Tab key; call resetCompletion when the user edits the prefix.
do  -- lurek.terminal.nextCompletion
  lurek.terminal.addCompletion("give_gold")
  lurek.terminal.addCompletion("give_xp")
  local first = lurek.terminal.nextCompletion("give")
  if first then lurek.log.debug("tab: " .. first, "term") end
end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the cycling cursor without clearing the candidate list.
-- Call from your textinput handler whenever the input string changes.
do  -- lurek.terminal.resetCompletion
  lurek.terminal.addCompletion("kill_all")
  lurek.terminal.nextCompletion("kill")
  lurek.terminal.resetCompletion()
end

--@api-stub: lurek.terminal.getMaxCols
-- Returns the maximum number of columns a Terminal can be constructed with.
-- Clamp user-configurable terminal sizes against this so newTerminal does not error.
do  -- lurek.terminal.getMaxCols
  local max_cols = lurek.terminal.getMaxCols()
  local desired = math.min(120, max_cols)
  lurek.log.info("using " .. desired .. " cols (cap " .. max_cols .. ")", "term")
end

--@api-stub: lurek.terminal.getMaxRows
-- Returns the maximum number of rows a Terminal can be constructed with.
-- Pair with getMaxCols when sizing terminals from a config file.
do  -- lurek.terminal.getMaxRows
  local max_rows = lurek.terminal.getMaxRows()
  local desired = math.min(60, max_rows)
  lurek.log.info("using " .. desired .. " rows (cap " .. max_rows .. ")", "term")
end

-- ── Terminal methods ──

--@api-stub: Terminal:set
-- Sets a cell at 1-based coordinates with character FG and BG colours.
-- Pass char as a 1-char string or codepoint; colours are 0..1 floats.
do  -- Terminal:set
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(10, 5, "@", 1, 1, 0, 1, 0, 0, 0, 0)
  term:set(11, 5, "!", 1, 0.4, 0.4, 1)
end

--@api-stub: Terminal:get
-- Returns the cell data at 1-based coordinates.
-- Returns 9 values: codepoint, fg rgba, bg rgba; useful for save/restore of cells.
do  -- Terminal:get
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(3, 3, "X", 1, 0, 0, 1)
  local ch, r, g, b = term:get(3, 3)
  lurek.log.debug("cell " .. ch .. " fg=" .. r .. "," .. g .. "," .. b, "term")
end

--@api-stub: Terminal:clear
-- Clears all cells to defaults.
-- Call before redrawing a frame from scratch instead of overwriting cell-by-cell.
do  -- Terminal:clear
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(1, 1, "#", 1, 1, 1, 1)
  term:clear()
end

--@api-stub: Terminal:getDimensions
-- Returns the terminal grid dimensions.
-- Use to centre widgets or to clamp draw coordinates within bounds.
do  -- Terminal:getDimensions
  local term = lurek.terminal.newTerminal(80, 25)
  local cols, rows = term:getDimensions()
  local centre = lurek.terminal.newLabel(math.floor(cols / 2) - 3, math.floor(rows / 2), "HELLO")
  term:addWidget(centre)
end

--@api-stub: Terminal:getCellSize
-- Returns the current cell size in pixels derived from the active font.
-- Use to position external sprites in pixel space aligned with the grid.
do  -- Terminal:getCellSize
  local term = lurek.terminal.newTerminal(80, 25)
  local cw, ch = term:getCellSize()
  lurek.log.info("cell pixels: " .. cw .. "x" .. ch, "term")
end

--@api-stub: Terminal:addWidget
-- Attaches a widget to this terminal.
-- Widgets render in attach order; add backgrounds before foreground labels.
do  -- Terminal:addWidget
  local term = lurek.terminal.newTerminal(80, 25)
  local hp_label = lurek.terminal.newLabel(2, 2, "HP: 100/100")
  term:addWidget(hp_label)
end

--@api-stub: Terminal:removeWidget
-- Detaches a widget from this terminal.
-- Use to hide HUD elements when entering menus without destroying the widget handle.
do  -- Terminal:removeWidget
  local term = lurek.terminal.newTerminal(80, 25)
  local toast = lurek.terminal.newLabel(20, 1, "Item picked up!")
  term:addWidget(toast)
  term:removeWidget(toast)
end

--@api-stub: Terminal:clearWidgets
-- Detaches all widgets from this terminal.
-- Call when switching between game screens to wipe the previous UI state.
do  -- Terminal:clearWidgets
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "old screen"))
  term:clearWidgets()
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of attached widgets.
-- Useful to assert UI state in tests or to cap dynamically spawned tooltips.
do  -- Terminal:getWidgetCount
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "a"))
  if term:getWidgetCount() == 0 then
    lurek.log.warn("no widgets attached", "term")
  end
end

--@api-stub: Terminal:setFocus
-- Sets the focused widget, or clears focus if nil is passed.
-- Only the focused widget receives keypressed/textinput; pass nil to release.
do  -- Terminal:setFocus
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
end

--@api-stub: Terminal:getFocused
-- Returns the currently focused widget, or nil.
-- Use to detect whether key events should reach gameplay or stay in the UI.
do  -- Terminal:getFocused
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
  if term:getFocused() == input then
    lurek.log.debug("input has focus", "term")
  end
end

--@api-stub: Terminal:keypressed
-- Routes a key press to the focused widget and fires callbacks.
-- Forward from your global key handler; returns true if the widget consumed the key.
do  -- Terminal:keypressed
  local term = lurek.terminal.newTerminal(80, 25)
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "OK")
  btn:setOnClick(function() lurek.log.info("ok clicked", "ui") end)
  term:addWidget(btn)
  term:setFocus(btn)
  local consumed = term:keypressed("return")
  lurek.log.debug("consumed=" .. tostring(consumed), "term")
end

--@api-stub: Terminal:textinput
-- Routes text input to the focused widget and fires callbacks.
-- Forward from a textinput hook so text boxes accept typed characters.
do  -- Terminal:textinput
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)
  term:textinput("h")
  term:textinput("i")
end

--@api-stub: Terminal:render
-- Renders the terminal grid and widgets as render commands.
-- Call from lurek.render after game-world drawing so the terminal sits on top.
do  -- Terminal:render
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(2, 2, "HUD"))
  function lurek.render() term:render(0, 0) end
end

--@api-stub: Terminal:setFont
-- Sets the terminal font by pixel height, snapping to the nearest built-in size.
-- Use to scale UI text for hi-DPI displays or accessibility settings.
do  -- Terminal:setFont
  local term = lurek.terminal.newTerminal(80, 25)
  term:setFont(24)
end

--@api-stub: Terminal:setCellSize
-- Sets a per-terminal cell pixel size override, bypassing the font-derived size.
-- Use to align cells to a sprite atlas grid; values are clamped to >= 1 pixel.
do  -- Terminal:setCellSize
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(16, 16)
end

--@api-stub: Terminal:resetCellSize
-- Removes the cell size override, restoring font-derived cell dimensions.
-- Call after a temporary override (e.g. cinematic zoom) to return to normal.
do  -- Terminal:resetCellSize
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(20, 20)
  term:resetCellSize()
end

--@api-stub: Terminal:getCellSize
-- Returns the active cell size override as `{w, h}`, or `nil` if none is set.
-- Use to detect whether the terminal is using a custom grid before resetting.
do  -- Terminal:getCellSize
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(18, 18)
  local override = term:getCellSize()
  if override then lurek.log.debug("override " .. override.w .. "x" .. override.h, "term") end
end

--@api-stub: Terminal:autoResize
-- Resizes the window to exactly fit the terminal grid at the current font size.
-- Call after setFont when you want the OS window to hug the grid bounds.
do  -- Terminal:autoResize
  local term = lurek.terminal.newTerminal(80, 25)
  term:setFont(20)
  term:autoResize()
end

-- ── Widget methods ──

--@api-stub: Widget:setPosition
-- Sets the widget position from 1-based coordinates.
-- Use to reposition tooltips or floating windows in response to game state.
do  -- Widget:setPosition
  local label = lurek.terminal.newLabel(1, 1, "tooltip")
  label:setPosition(40, 12)
end

--@api-stub: Widget:getPosition
-- Returns the widget position as 1-based coordinates.
-- Use to anchor a child element relative to an existing widget.
do  -- Widget:getPosition
  local label = lurek.terminal.newLabel(10, 5, "anchor")
  local col, row = label:getPosition()
  local arrow = lurek.terminal.newLabel(col + 8, row, "->")
  lurek.log.debug("arrow at " .. (col + 8) .. "," .. row, "term")
end

--@api-stub: Widget:setSize
-- Sets the widget size in cells.
-- Use to grow a list as items are added or to expand a panel for content.
do  -- Widget:setSize
  local list = lurek.terminal.newList(2, 3, 20, 4)
  list:addItem("sword")
  list:addItem("shield")
  list:setSize(20, 8)
end

--@api-stub: Widget:getSize
-- Returns the widget size in cells.
-- Use to compute layout offsets for sibling widgets.
do  -- Widget:getSize
  local panel = lurek.terminal.newPanel(2, 2, 30, 12)
  local w, h = panel:getSize()
  lurek.log.info("panel " .. w .. "x" .. h, "term")
end

--@api-stub: Widget:setVisible
-- Sets the widget visibility.
-- Toggle to show/hide overlays without removing them from the terminal.
do  -- Widget:setVisible
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")
  hint:setVisible(false)
end

--@api-stub: Widget:isVisible
-- Returns whether the widget is visible.
-- Branch on visibility before computing expensive label text updates.
do  -- Widget:isVisible
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")
  hint:setVisible(false)
  if not hint:isVisible() then
    lurek.log.debug("hint hidden, skipping update", "term")
  end
end

--@api-stub: Widget:setEnabled
-- Sets whether the widget accepts input.
-- Disable buttons during async operations to prevent double-clicks.
do  -- Widget:setEnabled
  local save_btn = lurek.terminal.newButton(2, 2, 10, 1, "Save")
  save_btn:setEnabled(false)
end

--@api-stub: Widget:isEnabled
-- Returns whether the widget accepts input.
-- Check before re-enabling so you do not clobber an explicit disabled state.
do  -- Widget:isEnabled
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Go")
  btn:setEnabled(false)
  if not btn:isEnabled() then
    lurek.log.debug("button still disabled", "term")
  end
end

--@api-stub: Widget:setTag
-- Sets the free-form identification tag.
-- Use a stable string id so event handlers can identify widgets without table refs.
do  -- Widget:setTag
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")
end

--@api-stub: Widget:getTag
-- Returns the free-form identification tag.
-- Use in click callbacks to dispatch by tag instead of comparing widget refs.
do  -- Widget:getTag
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")
  if btn:getTag() == "menu.quit" then
    lurek.log.info("quit button identified", "ui")
  end
end

--@api-stub: Widget:setText
-- Sets the text content of a label, button, or text box widget.
-- Reuse a single label widget and update its text every frame instead of recreating.
do  -- Widget:setText
  local fps_label = lurek.terminal.newLabel(2, 1, "FPS: --")
  fps_label:setText("FPS: 60")
end

--@api-stub: Widget:getText
-- Returns the text content of a label, button, or text box widget.
-- Read after textinput to grab what the user typed.
do  -- Widget:getText
  local input = lurek.terminal.newTextBox(2, 24, 40)
  input:setText("noclip on")
  local typed = input:getText()
  lurek.log.info("submit: " .. typed, "term")
end

--@api-stub: Widget:getColor
-- Returns the colour of a label or border widget.
-- Use to fade widgets by reading the current colour and animating the alpha.
do  -- Widget:getColor
  local label = lurek.terminal.newLabel(2, 2, "Hello")
  local r, g, b, a = label:getColor()
  lurek.log.debug("colour rgba " .. r .. "," .. g .. "," .. b .. "," .. a, "term")
end

--@api-stub: Widget:setOnClick
-- Registers a click callback for a button widget.
-- The callback runs on Enter when focused or on a mouse click on the button cells.
do  -- Widget:setOnClick
  local btn = lurek.terminal.newButton(2, 2, 12, 1, "[ Start ]")
  btn:setOnClick(function() lurek.log.info("starting game", "menu") end)
end

--@api-stub: Widget:setMaxLength
-- Sets the maximum character length of a text box widget.
-- Cap so player names or chat lines fit your network packet limits.
do  -- Widget:setMaxLength
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16)
end

--@api-stub: Widget:getMaxLength
-- Returns the maximum character length of a text box widget.
-- Use to drive a "12/16" character counter beside the input.
do  -- Widget:getMaxLength
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16)
  local cap = name_box:getMaxLength()
  lurek.log.info("max name length " .. cap, "term")
end

--@api-stub: Widget:setOnChange
-- Registers a text change callback for a text box widget.
-- Use for live filtering (search boxes) or to validate input as it is typed.
do  -- Widget:setOnChange
  local search = lurek.terminal.newTextBox(2, 1, 30)
  search:setOnChange(function(text)
    lurek.log.debug("filter: " .. text, "ui")
  end)
end

--@api-stub: Widget:addItem
-- Adds an item to a list widget.
-- Use during inventory refreshes; items appear in insertion order.
do  -- Widget:addItem
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion x3")
  inv:addItem("Iron Sword")
  inv:addItem("Lockpick x5")
end

--@api-stub: Widget:removeItem
-- Removes an item from a list widget by 1-based index.
-- Use after the player drops or consumes the corresponding inventory entry.
do  -- Widget:removeItem
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion")
  inv:addItem("Bomb")
  inv:removeItem(2)
end

--@api-stub: Widget:clearItems
-- Removes all items from a list widget.
-- Call before refilling the list from a fresh inventory snapshot.
do  -- Widget:clearItems
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("stale")
  inv:clearItems()
  inv:addItem("fresh")
end

--@api-stub: Widget:getItemCount
-- Returns the number of items in a list widget.
-- Use to drive an "Empty" placeholder label when the list has no entries.
do  -- Widget:getItemCount
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  if inv:getItemCount() == 0 then
    inv:addItem("(empty)")
  end
end

--@api-stub: Widget:getItem
-- Returns a list item by 1-based index.
-- Use with getSelected to fetch the highlighted entry on Enter.
do  -- Widget:getItem
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Iron Sword")
  inv:addItem("Bow")
  local first = inv:getItem(1)
  lurek.log.debug("first item: " .. first, "term")
end

--@api-stub: Widget:setSelected
-- Sets the selected item in a list widget by 1-based index.
-- Pass nil to clear; useful when programmatically restoring a saved selection.
do  -- Widget:setSelected
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:addItem("Slot 2")
  saves:setSelected(2)
end

--@api-stub: Widget:getSelected
-- Returns the selected item index (1-based) in a list widget, or nil.
-- Read on confirm to know which entry the player highlighted.
do  -- Widget:getSelected
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:setSelected(1)
  local idx = saves:getSelected()
  if idx then lurek.log.info("loaded slot " .. idx, "save") end
end

--@api-stub: Widget:setOnSelect
-- Registers a selection change callback for a list widget.
-- Use to update a preview pane whenever the highlight moves.
do  -- Widget:setOnSelect
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:setOnSelect(function(idx)
    lurek.log.debug("preview slot " .. tostring(idx), "ui")
  end)
end

--@api-stub: Widget:setStyle
-- Sets the border style of a border widget.
-- Valid styles: "single", "double", "ascii"; choose ascii for low-glyph fonts.
do  -- Widget:setStyle
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("single")
end

--@api-stub: Widget:getStyle
-- Returns the border style name of a border widget.
-- Use to round-trip the style when persisting UI preferences.
do  -- Widget:getStyle
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("double")
  local style = frame:getStyle()
  lurek.log.info("border style: " .. style, "term")
end

--@api-stub: Widget:setTitle
-- Sets the title of a border widget.
-- The title overlays the top edge; use a leading/trailing space for breathing room.
do  -- Widget:setTitle
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Inventory ")
end

--@api-stub: Widget:getTitle
-- Returns the title of a border widget.
-- Use when rebuilding a panel to preserve the previously displayed heading.
do  -- Widget:getTitle
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Status ")
  local title = frame:getTitle()
  lurek.log.debug("frame titled: " .. title, "term")
end

--@api-stub: Widget:addChild
-- Adds a child widget to a panel widget.
-- Children draw with the panel; toggling panel visibility cascades to all children.
do  -- Widget:addChild
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "PAUSED"))
  panel:addChild(lurek.terminal.newButton(1, 3, 10, 1, "Resume"))
end

--@api-stub: Widget:removeChild
-- Removes a child widget from a panel widget.
-- Use to hot-swap a single subview without rebuilding the entire panel.
do  -- Widget:removeChild
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  local hint = lurek.terminal.newLabel(1, 1, "tip")
  panel:addChild(hint)
  panel:removeChild(hint)
end

--@api-stub: Widget:clearChildren
-- Removes all children from a panel widget.
-- Call before rebuilding a panel's contents from a fresh data source.
do  -- Widget:clearChildren
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "old"))
  panel:clearChildren()
end

--@api-stub: Widget:getChildCount
-- Returns the number of children in a panel widget.
-- Use to lay out children dynamically (e.g. position the next at row N+1).
do  -- Widget:getChildCount
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "a"))
  local n = panel:getChildCount()
  lurek.log.debug("panel children: " .. n, "term")
end

--@api-stub: Widget:getChild
-- Returns a child widget from a panel by 1-based index, or nil.
-- Iterate from 1 to getChildCount to walk all children for layout passes.
do  -- Widget:getChild
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "first"))
  local first = panel:getChild(1)
  if first then lurek.log.debug("got first child", "term") end
end
