-- content/examples/terminal.lua
-- lurek.terminal API examples: in-game dev consoles, text adventure UIs, roguelike screens, MUD clients.
-- Run: cargo run -- content/examples/terminal.lua

--@api-stub: lurek.terminal.newTerminal
-- Creates a new terminal emulator grid and stages a window size that fits its active cell metrics
do
  -- newTerminal(cols, rows) creates a cell grid for text-mode rendering.
  -- The engine auto-resizes the window to fit the grid using the active font.
  -- Use this as the root surface for any text-UI: dev console, roguelike map, MUD output.
  local console = lurek.terminal.newTerminal(100, 30)

  -- Verify the grid was allocated at the requested size.
  local cols, rows = console:getDimensions()
  lurek.log.info("dev console: " .. cols .. "x" .. rows .. " cells", "term")

  -- Default dimensions are 80x40 if you omit both arguments.
  local default_term = lurek.terminal.newTerminal()
  local dc, dr = default_term:getDimensions()
  lurek.log.debug("default grid: " .. dc .. "x" .. dr, "term")
end

--@api-stub: lurek.terminal.newLabel
-- Creates a new label widget that displays static text at the given cell position
do
  -- Labels are the simplest widget: static read-only text at a fixed cell.
  -- Use them for HUD displays, status bars, or section headers.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Place an inventory header at column 2, row 1.
  -- Positions are 1-based cell coordinates within the terminal grid.
  local title = lurek.terminal.newLabel(2, 1, "== Inventory ==")
  term:addWidget(title)

  -- Labels can be updated dynamically each frame for live stats.
  local hp_display = lurek.terminal.newLabel(2, 24, "HP: 85/100")
  term:addWidget(hp_display)
end

--@api-stub: lurek.terminal.newButton
-- Creates a new clickable button widget with the given position, size, and label text
do
  -- Buttons respond to mouse clicks and keyboard activation (Return key when focused).
  -- Parameters: col, row, width, height (optional, default 1), text (optional).
  local term = lurek.terminal.newTerminal(80, 25)

  -- A quit button for a pause menu: 14 cells wide, 3 cells tall.
  local quit_btn = lurek.terminal.newButton(60, 21, 14, 3, "[ Quit ]")

  -- Register a click handler. The callback fires on mouse click or Return key.
  quit_btn:setOnClick(function()
    lurek.log.info("player pressed quit", "menu")
  end)
  term:addWidget(quit_btn)

  -- A compact single-row button (height defaults to 1 if omitted).
  local help_btn = lurek.terminal.newButton(2, 21, 8, 1, "Help")
  term:addWidget(help_btn)
end

--@api-stub: lurek.terminal.newTextBox
-- Creates a new single-line text input widget at the given position with a fixed width
do
  -- TextBoxes capture keyboard input when focused. Ideal for command prompts,
  -- chat input, or search fields in a dev console.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A 70-cell wide input bar at the bottom of the console.
  local input = lurek.terminal.newTextBox(2, 24, 70)

  -- Limit how many characters the player can type (useful for name entry).
  input:setMaxLength(64)

  term:addWidget(input)

  -- Give this widget keyboard focus so typed characters go here immediately.
  term:setFocus(input)
end

--@api-stub: lurek.terminal.newList
-- Creates a new scrollable list widget for displaying and selecting items
do
  -- Lists display vertically-scrollable items with selection highlighting.
  -- Perfect for save-file browsers, inventory screens, or quest logs.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Create a list: col=2, row=3, width=30 cells, visible height=10 rows.
  local saves = lurek.terminal.newList(2, 3, 30, 10)

  -- Populate with save-slot descriptions. Items are 1-indexed.
  saves:addItem("Slot 1 - Forest Temple (02:15)")
  saves:addItem("Slot 2 - Dark Cave (04:30)")
  saves:addItem("Slot 3 - Empty")

  -- Pre-select the most recent save.
  saves:setSelected(1)

  term:addWidget(saves)
end

--@api-stub: lurek.terminal.newBorder
-- Creates a new decorative border widget drawn using box-drawing characters
do
  -- Borders draw box-drawing frames around a rectangular area.
  -- Use them to visually separate UI regions: status panels, dialog boxes.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A full-screen frame using double-line box-drawing characters.
  local frame = lurek.terminal.newBorder(1, 1, 80, 25)
  frame:setStyle("double")

  -- Optional title text is rendered into the top border line.
  frame:setTitle(" Status ")
  term:addWidget(frame)

  -- Styles available: "single", "double", "ascii".
  local inner = lurek.terminal.newBorder(3, 3, 30, 10)
  inner:setStyle("ascii")
  term:addWidget(inner)
end

--@api-stub: lurek.terminal.newPanel
-- Creates a new panel widget that can contain child widgets for grouped layout
do
  -- Panels are container widgets: child positions are relative to the panel origin.
  -- Use panels for modal dialogs, popup menus, or moveable HUD groups.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A centered pause overlay: 40 cells wide, 10 cells tall.
  local pause_panel = lurek.terminal.newPanel(20, 8, 40, 10)

  -- Children use positions relative to the panel's top-left corner.
  pause_panel:addChild(lurek.terminal.newLabel(1, 1, "=== PAUSED ==="))
  pause_panel:addChild(lurek.terminal.newButton(1, 4, 12, 1, "Resume"))
  pause_panel:addChild(lurek.terminal.newButton(1, 6, 12, 1, "Quit"))

  term:addWidget(pause_panel)
end

--@api-stub: lurek.terminal.pushScrollback
-- Appends a line of text to the terminal scrollback buffer for later retrieval
do
  -- The scrollback buffer stores output history for a dev console or MUD client.
  -- New lines go to the end; oldest lines are discarded when the cap is reached.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Simulate a player typing a command and the engine responding.
  lurek.terminal.pushScrollback(term, "> spawn enemy 100 200")
  lurek.terminal.pushScrollback(term, "[engine] spawned goblin#7 at (100, 200)")
  lurek.terminal.pushScrollback(term, "> kill goblin#7")
  lurek.terminal.pushScrollback(term, "[engine] goblin#7 destroyed")
end

--@api-stub: lurek.terminal.getScrollback
-- Retrieves a range of lines from the terminal scrollback buffer
do
  -- getScrollback(terminal, offset, count) reads lines from the buffer.
  -- offset=0 means the newest line; higher offsets go further back in history.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "line A")
  lurek.terminal.pushScrollback(term, "line B")
  lurek.terminal.pushScrollback(term, "line C")

  -- Retrieve the 10 most recent lines (or fewer if the buffer is shorter).
  local recent = lurek.terminal.getScrollback(term, 0, 10)

  -- Render scrollback onto the terminal grid for a console-like display.
  for i, line in ipairs(recent) do
    lurek.log.debug("scrollback[" .. i .. "] = " .. line, "term")
  end
end

--@api-stub: lurek.terminal.scrollbackLen
-- Returns the number of lines currently stored in the terminal scrollback buffer
do
  -- Use scrollbackLen to check how full the buffer is, or to calculate
  -- scroll positions for a custom scrollbar.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushScrollback(term, "hello")
  lurek.terminal.pushScrollback(term, "world")

  local total = lurek.terminal.scrollbackLen(term)
  lurek.log.info("buffer has " .. total .. " lines", "term")

  -- Example: show a warning when the buffer is getting large.
  if total > 500 then
    lurek.log.warn("scrollback growing fast — consider raising the cap", "term")
  end
end

--@api-stub: lurek.terminal.setScrollbackCap
-- Sets the maximum number of lines retained in the terminal scrollback buffer
do
  -- The default cap prevents unbounded memory growth. Set it higher for
  -- long play sessions with verbose output, or lower for memory-constrained builds.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Allow up to 2000 lines of history before oldest lines are discarded.
  lurek.terminal.setScrollbackCap(term, 2000)
  lurek.terminal.pushScrollback(term, "cap is now 2000 lines")
end

--@api-stub: lurek.terminal.pushCmdHistory
-- Appends a command string to the terminal command history for up/down arrow recall
do
  -- Command history lets players recall previously typed commands with arrow keys.
  -- Push each submitted command after executing it.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Player types a cheat command and presses Enter.
  local submitted = "give gold 500"
  lurek.terminal.pushCmdHistory(term, submitted)

  -- Later the player can press Up to recall "give gold 500".
  lurek.terminal.pushCmdHistory(term, "tp 0 0")
  lurek.terminal.pushCmdHistory(term, "noclip on")
end

--@api-stub: lurek.terminal.prevCmd
-- Navigates backward in the terminal command history, returning the previous command or nil if at the start
do
  -- prevCmd moves the history cursor one step back (like pressing Up arrow).
  -- Returns nil when you reach the oldest entry.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "spawn boss")
  lurek.terminal.pushCmdHistory(term, "noclip on")

  -- First call returns the most recent command.
  local recalled = lurek.terminal.prevCmd(term)
  if recalled then
    lurek.log.debug("recalled: " .. recalled, "term") -- "noclip on"
  end

  -- Second call goes further back.
  local older = lurek.terminal.prevCmd(term)
  if older then
    lurek.log.debug("older: " .. older, "term") -- "spawn boss"
  end
end

--@api-stub: lurek.terminal.nextCmd
-- Navigates forward in the terminal command history, returning the next command or nil if at the end
do
  -- nextCmd moves the cursor forward (like pressing Down arrow).
  -- Returns nil when you reach the newest entry.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "help")
  lurek.terminal.pushCmdHistory(term, "status")

  -- Go back, then forward again.
  lurek.terminal.prevCmd(term) -- "status"
  lurek.terminal.prevCmd(term) -- "help"
  local newer = lurek.terminal.nextCmd(term)
  lurek.log.debug("next cmd: " .. tostring(newer), "term") -- "status"
end

--@api-stub: lurek.terminal.cmdHistoryLen
-- Returns the number of commands currently stored in the terminal command history
do
  -- Useful for displaying a "history (N)" indicator or deciding when to trim.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "kill all")
  lurek.terminal.pushCmdHistory(term, "spawn chest")

  local n = lurek.terminal.cmdHistoryLen(term)
  lurek.log.info("history depth: " .. n, "term") -- 2
end

--@api-stub: lurek.terminal.clearCmdHistory
-- Removes all entries from the terminal command history
do
  -- Clear history when the player starts a new session or resets the console.
  local term = lurek.terminal.newTerminal(80, 25)
  lurek.terminal.pushCmdHistory(term, "spawn enemy 50 50")
  lurek.terminal.pushCmdHistory(term, "god mode")

  lurek.terminal.clearCmdHistory(term)
  -- Now cmdHistoryLen(term) == 0 and prevCmd(term) returns nil.
end

--@api-stub: lurek.terminal.applyTheme
-- Applies a named color theme to the terminal, setting default foreground and background colors
do
  -- Built-in themes: "solarized_dark", "solarized_light", "monokai", "dracula", "nord".
  -- Themes set the default fg/bg colors used for new text and cleared cells.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Apply a dark theme suitable for a hacker-style dev console.
  lurek.terminal.applyTheme(term, "dracula")

  -- Switch to a light theme for a text-adventure or documentation viewer.
  local reader = lurek.terminal.newTerminal(80, 40)
  lurek.terminal.applyTheme(reader, "solarized_light")
end

--@api-stub: lurek.terminal.printHighlighted
-- Renders syntax-highlighted text onto the terminal grid using a table of highlight rules with regex patterns and colors
do
  -- printHighlighted applies regex-based coloring to a text string.
  -- Each rule has a `pattern` (Lua pattern), `fg` color {r,g,b} (0-255), and optional `bg`.
  -- Rules are applied in order; first match wins for overlapping regions.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Define rules for a dev-console log viewer.
  local log_rules = {
    { pattern = "ERROR",  fg = { 255, 80, 80 } },   -- red for errors
    { pattern = "WARN",   fg = { 255, 200, 50 } },  -- yellow for warnings
    { pattern = "%d+",    fg = { 120, 200, 255 } },  -- cyan for numbers
    { pattern = "%b\"\"", fg = { 180, 255, 180 } },  -- green for quoted strings
  }

  -- Render a log line with syntax coloring at row 5.
  lurek.terminal.printHighlighted(term, 2, 5, "ERROR at line 42: \"nil value\"", log_rules)
end

--@api-stub: lurek.terminal.stripAnsi
-- Removes all ANSI escape sequences from a string, returning plain text
do
  -- External tools or MUD servers send ANSI-coded text. Strip codes when
  -- you need plain text for logging, searching, or measuring string width.
  local raw = "\27[31mERROR:\27[0m boss spawn failed at position (10, 20)"
  local plain = lurek.terminal.stripAnsi(raw)

  -- plain == "ERROR: boss spawn failed at position (10, 20)"
  lurek.log.warn("clean: " .. plain, "term")
end

--@api-stub: lurek.terminal.parseAnsi
-- Parses ANSI escape sequences in a string into an array of span tables with text, bold, fg, and bg fields
do
  -- parseAnsi breaks an ANSI string into structured spans you can render manually.
  -- Each span: { text=string, bold=boolean, fg?={r,g,b}, bg?={r,g,b} }
  local spans = lurek.terminal.parseAnsi("\27[1;32mOK\27[0m loaded map")

  -- Iterate spans for custom rendering or analysis.
  for _, s in ipairs(spans) do
    lurek.log.debug("span: '" .. s.text .. "' bold=" .. tostring(s.bold), "term")
  end
  -- Expected: span "OK" with bold=true, fg={0,255,0}; span " loaded map" with defaults.
end

--@api-stub: lurek.terminal.printAnsi
-- Renders ANSI-colored text directly onto the terminal grid at the given cell position
do
  -- printAnsi is a shortcut: it parses ANSI codes and writes colored text in one call.
  -- Use this for MUD client output or for rendering pre-colored server messages.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A server message with embedded ANSI color codes.
  local msg = "\27[33mWARN:\27[0m low ammo (\27[1;31m3\27[0m remaining)"
  lurek.terminal.printAnsi(term, 2, 3, msg)
end

--@api-stub: lurek.terminal.addCompletion
-- Registers a candidate string for tab-completion in the shared completion engine
do
  -- The completion engine is global (not per-terminal). Register all valid
  -- commands at startup so players can tab-complete in the dev console.
  lurek.terminal.addCompletion("spawn")
  lurek.terminal.addCompletion("teleport")
  lurek.terminal.addCompletion("give")
  lurek.terminal.addCompletion("kill")
  lurek.terminal.addCompletion("noclip")
  lurek.terminal.addCompletion("god")
end

--@api-stub: lurek.terminal.removeCompletion
-- Removes a previously registered completion candidate from the shared completion engine
do
  -- Remove commands that are no longer valid (e.g., after disabling cheat mode).
  lurek.terminal.addCompletion("debug_crash")
  lurek.terminal.removeCompletion("debug_crash")
end

--@api-stub: lurek.terminal.clearCompletions
-- Removes all registered completion candidates from the shared completion engine
do
  -- Reset the entire completion dictionary (e.g., when switching game modes).
  lurek.terminal.addCompletion("noclip")
  lurek.terminal.addCompletion("god")
  lurek.terminal.clearCompletions()
  -- Now getCompletions("") returns an empty table.
end

--@api-stub: lurek.terminal.getCompletions
-- Returns all completion candidates matching the given prefix string
do
  -- getCompletions returns ALL matches as a table, unlike nextCompletion which cycles.
  -- Use this to display a dropdown/popup of all valid options.
  lurek.terminal.addCompletion("spawn_enemy")
  lurek.terminal.addCompletion("spawn_item")
  lurek.terminal.addCompletion("spawn_npc")

  local hits = lurek.terminal.getCompletions("spawn")
  lurek.log.info("matches for 'spawn': " .. #hits, "term") -- 3
end

--@api-stub: lurek.terminal.nextCompletion
-- Cycles to the next matching completion candidate for the given prefix, wrapping around after the last match
do
  -- nextCompletion implements tab-cycling: each call advances to the next match.
  -- After the last candidate it wraps back to the first.
  lurek.terminal.addCompletion("give_gold")
  lurek.terminal.addCompletion("give_xp")
  lurek.terminal.addCompletion("give_item")

  -- Simulating the player pressing Tab repeatedly.
  local first = lurek.terminal.nextCompletion("give")
  local second = lurek.terminal.nextCompletion("give")
  if first then lurek.log.debug("tab1: " .. first, "term") end
  if second then lurek.log.debug("tab2: " .. second, "term") end
end

--@api-stub: lurek.terminal.resetCompletion
-- Resets the completion cycling state so the next call to nextCompletion starts from the first match
do
  -- Reset when the player changes the input prefix or submits a command.
  -- This ensures the next Tab press starts from candidate #1 again.
  lurek.terminal.addCompletion("kill_all")
  lurek.terminal.addCompletion("kill_boss")
  lurek.terminal.nextCompletion("kill") -- advances internal cursor
  lurek.terminal.resetCompletion()      -- cursor back to start
end

--@api-stub: lurek.terminal.getMaxCols
-- Returns the engine-defined maximum number of columns a terminal grid can have
do
  -- Use getMaxCols/getMaxRows to clamp user-requested dimensions to safe limits.
  local max_cols = lurek.terminal.getMaxCols()
  local desired = math.min(120, max_cols)
  lurek.log.info("using " .. desired .. " cols (engine max: " .. max_cols .. ")", "term")
end

--@api-stub: lurek.terminal.getMaxRows
-- Returns the engine-defined maximum number of rows a terminal grid can have
do
  local max_rows = lurek.terminal.getMaxRows()
  local desired = math.min(60, max_rows)
  lurek.log.info("using " .. desired .. " rows (engine max: " .. max_rows .. ")", "term")
end

-- Terminal methods

--@api-stub: Terminal:set
-- Writes a character with foreground and background color to a specific cell
do
  -- set(col, row, ch, fr, fg, fb, fa, br, bg, bb, ba) writes one cell.
  -- Colors are 0-1 floats: fg RGBA then bg RGBA. Omitted channels default to 1/0.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Draw the player '@' symbol in green on a dark background.
  term:set(10, 5, "@", 0, 1, 0, 1, 0.1, 0.1, 0.1, 1)

  -- Draw a red '!' for a danger indicator (no background specified = transparent).
  term:set(11, 5, "!", 1, 0.2, 0.2, 1)

  -- You can also pass a Unicode codepoint as a number instead of a string.
  term:set(12, 5, 9829, 1, 0, 0, 1) -- heart symbol (U+2665)
end

--@api-stub: Terminal:get
-- Reads the character and color data at a specific cell
do
  -- get(col, row) returns 9 values: char codepoint, fg RGBA (4), bg RGBA (4).
  -- Useful for collision detection in roguelikes or copying cell data.
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(3, 3, "X", 1, 0, 0, 1, 0, 0, 0, 0)

  local ch, fr, fg, fb, fa, br, bg, bb, ba = term:get(3, 3)
  lurek.log.debug("cell='" .. string.char(ch) .. "' fg=(" .. fr .. "," .. fg .. "," .. fb .. ")", "term")
end

--@api-stub: Terminal:clear
-- Clears all cells in the terminal grid, resetting characters and colors to defaults
do
  -- Call clear() at the start of each frame for a roguelike or when switching screens.
  local term = lurek.terminal.newTerminal(80, 25)
  term:set(1, 1, "#", 1, 1, 1, 1)
  term:set(2, 1, "#", 1, 1, 1, 1)

  -- Wipe the entire grid back to default (empty cells with theme colors).
  term:clear()
end

--@api-stub: Terminal:getDimensions
-- Returns the number of columns and rows in the terminal grid
do
  -- getDimensions() returns cols, rows. Use to center content or set boundaries.
  local term = lurek.terminal.newTerminal(80, 25)
  local cols, rows = term:getDimensions()

  -- Center a title label horizontally.
  local title_text = "DUNGEON"
  local center_col = math.floor((cols - #title_text) / 2) + 1
  local title = lurek.terminal.newLabel(center_col, 1, title_text)
  term:addWidget(title)
end

--@api-stub: Terminal:addWidget
-- Attaches a widget to this terminal so it is rendered and receives input events
do
  -- Widgets must be added to a terminal before they appear on screen.
  -- The terminal owns rendering order: widgets draw on top of raw cells.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Build a simple HUD with two labels.
  local hp_label = lurek.terminal.newLabel(2, 2, "HP: 100/100")
  local mp_label = lurek.terminal.newLabel(2, 3, "MP: 50/50")
  term:addWidget(hp_label)
  term:addWidget(mp_label)
end

--@api-stub: Terminal:removeWidget
-- Detaches a widget from this terminal, removing it from rendering and input
do
  -- Remove widgets for temporary notifications that expire after a few seconds.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A toast notification that should disappear after being shown.
  local toast = lurek.terminal.newLabel(20, 1, "Item picked up!")
  term:addWidget(toast)

  -- Later (e.g., after 2 seconds): remove it.
  term:removeWidget(toast)
end

--@api-stub: Terminal:clearWidgets
-- Removes all attached widgets from this terminal at once
do
  -- Use clearWidgets when transitioning between screens (e.g., menu -> gameplay).
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "Loading..."))
  term:addWidget(lurek.terminal.newLabel(1, 2, "Please wait"))

  -- Wipe everything before building the new screen.
  term:clearWidgets()
end

--@api-stub: Terminal:getWidgetCount
-- Returns the number of widgets currently attached to this terminal
do
  -- Check widget count to avoid adding duplicate widgets or for debug info.
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(1, 1, "a"))
  term:addWidget(lurek.terminal.newLabel(1, 2, "b"))

  local count = term:getWidgetCount()
  lurek.log.debug("attached widgets: " .. count, "term") -- 2
end

--@api-stub: Terminal:setFocus
-- Sets which widget currently has keyboard focus
do
  -- Only one widget can have focus at a time. Focused TextBoxes receive typed text.
  -- Pass nil to clear focus entirely (no widget receives keyboard input).
  local term = lurek.terminal.newTerminal(80, 25)
  local cmd_input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(cmd_input)

  -- Give focus to the command input so typing goes there.
  term:setFocus(cmd_input)
end

--@api-stub: Terminal:getFocused
-- Returns the widget that currently has keyboard focus, or nil if none
do
  -- Use getFocused to check state before forwarding input events.
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)

  local focused = term:getFocused()
  if focused == input then
    lurek.log.debug("command input has focus", "term")
  end
end

--@api-stub: Terminal:keypressed
-- Forwards a key press event for widget input processing
do
  -- Call keypressed from your lurek.keypressed callback to dispatch keys to widgets.
  -- Returns true if the terminal consumed the event (e.g., button activation).
  local term = lurek.terminal.newTerminal(80, 25)
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "OK")
  btn:setOnClick(function()
    lurek.log.info("OK button activated via keyboard", "ui")
  end)
  term:addWidget(btn)
  term:setFocus(btn)

  -- Simulate pressing Enter while the button has focus.
  local consumed = term:keypressed("return")
  lurek.log.debug("key consumed: " .. tostring(consumed), "term") -- true
end

--@api-stub: Terminal:textinput
-- Forwards a text input event for character entry into focused widgets
do
  -- Call textinput from your lurek.textinput callback for typing into TextBoxes.
  -- Returns true if the terminal consumed the character.
  local term = lurek.terminal.newTerminal(80, 25)
  local input = lurek.terminal.newTextBox(2, 24, 60)
  term:addWidget(input)
  term:setFocus(input)

  -- Simulate the player typing "hi" into the console.
  term:textinput("h")
  term:textinput("i")
  -- input:getText() now returns "hi"
end

--@api-stub: Terminal:render
-- Renders the terminal grid and widgets, staging a window fit
do
  -- Call render(x, y) inside lurek.draw() to display the terminal.
  -- x, y are optional pixel offsets (default 0, 0).
  local term = lurek.terminal.newTerminal(80, 25)
  term:addWidget(lurek.terminal.newLabel(2, 2, "Game HUD"))

  -- In a real game, this would be inside lurek.draw():
  function lurek.draw()
    -- Render the terminal at the top-left corner of the window.
    term:render(0, 0)
  end
end

--@api-stub: Terminal:print
-- Writes text to the terminal grid starting at a specific cell
do
  -- print(col, row, text) writes a string of characters into consecutive cells.
  -- Faster than calling set() per character; uses default fg/bg from the theme.
  ---@type LTerminal
  local term = lurek.terminal.newTerminal(80, 25)

  -- Simulate a REPL-style dev console.
  term:print(1, 1, "lurek> print(2 + 2)")
  term:print(1, 2, "4")
  term:print(1, 3, "lurek> _")
end

--@api-stub: Terminal:setFont
-- Selects the nearest built-in bitmap font by pixel height and refits the window
do
  -- setFont picks the closest available monospace glyph set by height.
  -- The terminal auto-resizes the window to match the new cell dimensions.
  local term = lurek.terminal.newTerminal(80, 25)

  -- A large font for a roguelike where each cell should be clearly visible.
  term:setFont(24)

  -- A small font for a dense debug console with many rows.
  local debug_term = lurek.terminal.newTerminal(120, 50)
  debug_term:setFont(12)
end

--@api-stub: Terminal:setCellSize
-- Overrides the cell width and height used for rendering and refits the window
do
  -- setCellSize manually controls pixel dimensions per cell, ignoring font metrics.
  -- Useful for square-cell roguelikes or pixel-art tile grids.
  local term = lurek.terminal.newTerminal(80, 25)

  -- Force square 16x16 cells for a tile-based dungeon view.
  term:setCellSize(16, 16)
end

--@api-stub: Terminal:resetCellSize
-- Removes the custom cell size override, reverting to font metrics
do
  -- After experimenting with custom cell sizes, reset to let the font control layout.
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(20, 20)

  -- Revert to automatic sizing based on the active font.
  term:resetCellSize()
end

--@api-stub: Terminal:getCellSize
-- Returns the active cell width and height in pixels
do
  -- getCellSize returns the current effective cell dimensions, whether from
  -- a manual override or the active font metrics.
  local term = lurek.terminal.newTerminal(80, 25)
  term:setCellSize(18, 18)

  local cw, ch = term:getCellSize()
  lurek.log.debug("cell pixels: " .. cw .. "x" .. ch, "term") -- 18x18
end

--@api-stub: Terminal:autoResize
-- Requests the window to resize to exactly fit the terminal grid
do
  -- autoResize recalculates window size from (cols * cell_w, rows * cell_h).
  -- Call after changing font or cell size if you want a pixel-perfect fit.
  local term = lurek.terminal.newTerminal(80, 25)
  term:setFont(20)
  term:autoResize()
end

-- Widget methods

--@api-stub: Widget:setPosition
-- Moves a widget to a new cell position within the terminal grid
do
  -- setPosition(col, row) relocates the widget. Use for animations or tooltips.
  local label = lurek.terminal.newLabel(1, 1, "tooltip: press E")

  -- Move the tooltip to follow a cursor or highlight position.
  label:setPosition(40, 12)
end

--@api-stub: Widget:getPosition
-- Returns the current cell position of a widget
do
  -- getPosition() returns col, row. Useful for relative positioning of other widgets.
  local label = lurek.terminal.newLabel(10, 5, "anchor")
  local col, row = label:getPosition()

  -- Place an arrow indicator just to the right of the anchor.
  local arrow = lurek.terminal.newLabel(col + #"anchor" + 1, row, "<--")
  lurek.log.debug("arrow at col " .. (col + #"anchor" + 1), "term")
end

--@api-stub: Widget:setSize
-- Sets the widget dimensions in cell units
do
  -- setSize(width, height) resizes the widget. Clamped to minimum 1x1.
  -- For lists, changing height changes how many visible rows are shown.
  local list = lurek.terminal.newList(2, 3, 20, 4)
  list:addItem("sword")
  list:addItem("shield")
  list:addItem("potion")
  list:addItem("scroll")
  list:addItem("ring")

  -- Expand the list to show more items at once.
  list:setSize(20, 8)
end

--@api-stub: Widget:getSize
-- Returns the widget width and height in cell units
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 12)
  local w, h = panel:getSize()
  lurek.log.info("panel dimensions: " .. w .. "x" .. h .. " cells", "term")
end

--@api-stub: Widget:setVisible
-- Controls whether the widget is drawn and receives input events
do
  -- Toggle visibility for contextual HUD elements (e.g., interaction prompts).
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")

  -- Hide by default; show only when the player is near an interactable.
  hint:setVisible(false)

  -- Later, when player approaches:
  -- hint:setVisible(true)
end

--@api-stub: Widget:isVisible
-- Returns true if this widget is currently visible
do
  local hint = lurek.terminal.newLabel(2, 2, "[E] interact")
  hint:setVisible(false)

  if not hint:isVisible() then
    lurek.log.debug("hint is hidden — skipping update logic", "term")
  end
end

--@api-stub: Widget:setEnabled
-- Controls whether the widget accepts user interaction
do
  -- Disable buttons when their action is not currently available.
  local save_btn = lurek.terminal.newButton(2, 2, 10, 1, "Save")

  -- Disable during combat (player cannot save mid-fight).
  save_btn:setEnabled(false)

  -- Re-enable after combat: save_btn:setEnabled(true)
end

--@api-stub: Widget:isEnabled
-- Returns true if this widget is currently enabled
do
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Go")
  btn:setEnabled(false)

  if not btn:isEnabled() then
    lurek.log.debug("button disabled — greying out text", "term")
  end
end

--@api-stub: Widget:setTag
-- Assigns an arbitrary string tag to the widget for identification
do
  -- Tags let you identify widgets without keeping Lua references to each one.
  -- Useful for event-driven UIs where callbacks need to know which widget fired.
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")
end

--@api-stub: Widget:getTag
-- Returns the current tag string assigned to the widget
do
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Quit")
  btn:setTag("menu.quit")

  -- In a generic click handler, identify widgets by tag.
  if btn:getTag() == "menu.quit" then
    lurek.log.info("quit button identified by tag", "ui")
  end
end

--@api-stub: Widget:setText
-- Sets the display text of a label, button, or text box widget
do
  -- setText dynamically updates the displayed string. Fires onChange for TextBoxes.
  local fps_label = lurek.terminal.newLabel(2, 1, "FPS: --")

  -- Update each frame with the current frame rate.
  fps_label:setText("FPS: 60")
end

--@api-stub: Widget:getText
-- Returns the current text content of a label, button, or text box widget
do
  -- Read back text from an input widget after the player finishes typing.
  local input = lurek.terminal.newTextBox(2, 24, 40)
  input:setText("noclip on")

  local typed = input:getText()
  lurek.log.info("player submitted: " .. typed, "term")
end

--@api-stub: Widget:getColor
-- Returns the current RGBA color assigned to this widget
do
  -- getColor returns r, g, b, a in the 0..1 range plus the bg RGBA.
  local label = lurek.terminal.newLabel(2, 2, "Health OK")
  local r, g, b, a = label:getColor()
  lurek.log.debug("label fg: " .. r .. "," .. g .. "," .. b .. " a=" .. a, "term")
end

--@api-stub: Widget:setOnClick
-- Registers a callback invoked when a button widget is clicked
do
  -- Only valid for button widgets. The callback takes no arguments.
  local btn = lurek.terminal.newButton(2, 2, 14, 1, "[ New Game ]")
  btn:setOnClick(function()
    lurek.log.info("starting new game", "menu")
  end)

  -- Pass nil to remove the handler.
  -- btn:setOnClick(nil)
end

--@api-stub: Widget:setMaxLength
-- Sets the maximum number of characters allowed in a text box widget
do
  -- Prevent players from entering excessively long names or commands.
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16) -- maximum 16 characters for player name
end

--@api-stub: Widget:getMaxLength
-- Returns the maximum character limit of a text box widget
do
  local name_box = lurek.terminal.newTextBox(2, 5, 24)
  name_box:setMaxLength(16)

  local cap = name_box:getMaxLength()
  lurek.log.info("name max length: " .. cap, "term") -- 16
end

--@api-stub: Widget:setOnChange
-- Registers a callback invoked when text box content changes
do
  -- Fires every time the text is modified (typed, pasted, or set programmatically).
  -- Use for live search/filter as the player types.
  local search = lurek.terminal.newTextBox(2, 1, 30)
  search:setOnChange(function(text)
    lurek.log.debug("live filter: '" .. text .. "'", "ui")
    -- Filter inventory, command list, etc. based on the new text.
  end)
end

--@api-stub: Widget:addItem
-- Appends a text item to a list widget
do
  -- Items are displayed as selectable rows. Indices are 1-based.
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion x3")
  inv:addItem("Iron Sword +1")
  inv:addItem("Lockpick x5")
  inv:addItem("Torch x2")
end

--@api-stub: Widget:removeItem
-- Removes a list item by its 1-based index
do
  -- Use removeItem when the player drops or consumes an inventory item.
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Healing Potion")
  inv:addItem("Bomb")
  inv:addItem("Shield")

  -- Player uses the bomb (index 2).
  inv:removeItem(2)
  -- List now: "Healing Potion", "Shield"
end

--@api-stub: Widget:clearItems
-- Removes all items from a list widget
do
  -- Use clearItems when refreshing a list with new data (e.g., entering a shop).
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("stale data")

  -- Wipe and repopulate with fresh items.
  inv:clearItems()
  inv:addItem("Health Potion - 50g")
  inv:addItem("Mana Potion - 80g")
end

--@api-stub: Widget:getItemCount
-- Returns the number of items in a list widget
do
  -- Check item count to show an "empty" placeholder or limit additions.
  local inv = lurek.terminal.newList(2, 3, 30, 8)

  if inv:getItemCount() == 0 then
    inv:addItem("(inventory is empty)")
  end
end

--@api-stub: Widget:getItem
-- Returns the text of a list item by its 1-based index
do
  -- Read item text for display, search, or to determine the selected action.
  local inv = lurek.terminal.newList(2, 3, 30, 8)
  inv:addItem("Iron Sword")
  inv:addItem("Wooden Bow")

  local first = inv:getItem(1)
  lurek.log.debug("first item: " .. first, "term") -- "Iron Sword"
end

--@api-stub: Widget:setSelected
-- Sets the currently selected item in a list by 1-based index
do
  -- Pre-select an item programmatically (e.g., default save slot).
  -- Pass nil to clear the selection.
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1 - Forest")
  saves:addItem("Slot 2 - Cave")
  saves:setSelected(2) -- highlight "Slot 2 - Cave"
end

--@api-stub: Widget:getSelected
-- Returns the 1-based index of the selected list item, or nil if none
do
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1")
  saves:addItem("Slot 2")
  saves:setSelected(1)

  local idx = saves:getSelected()
  if idx then
    lurek.log.info("loading save slot " .. idx, "save")
  end
end

--@api-stub: Widget:setOnSelect
-- Registers a callback invoked when the selected list item changes
do
  -- The callback receives the new 1-based index (or nil if deselected).
  local saves = lurek.terminal.newList(2, 3, 30, 8)
  saves:addItem("Slot 1 - Forest")
  saves:addItem("Slot 2 - Cave")
  saves:setOnSelect(function(idx)
    lurek.log.debug("preview slot " .. tostring(idx), "ui")
    -- Load a thumbnail or stats summary for the selected save.
  end)
end

--@api-stub: Widget:setStyle
-- Sets the border drawing style for a border or panel widget
do
  -- Available styles: "single", "double", "rounded", "heavy", "none".
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("single") -- thin box-drawing lines
end

--@api-stub: Widget:getStyle
-- Returns the current border style name of a border or panel widget
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setStyle("double")

  local style = frame:getStyle()
  lurek.log.info("border style: " .. style, "term") -- "double"
end

--@api-stub: Widget:setTitle
-- Sets the title text displayed in the top border of a border or panel widget
do
  -- The title renders inline in the top border, centered.
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Inventory ")
end

--@api-stub: Widget:getTitle
-- Returns the current title text of a border or panel widget
do
  local frame = lurek.terminal.newBorder(1, 1, 40, 10)
  frame:setTitle(" Status ")

  local title = frame:getTitle()
  lurek.log.debug("frame title: " .. title, "term") -- " Status "
end

--@api-stub: Widget:addChild
-- Adds a child widget to a panel, making it part of the panel layout
do
  -- Panel children use positions relative to the panel's top-left.
  -- This makes it easy to move an entire dialog by repositioning only the panel.
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "=== PAUSED ==="))
  panel:addChild(lurek.terminal.newButton(1, 3, 10, 1, "Resume"))
  panel:addChild(lurek.terminal.newButton(1, 5, 10, 1, "Options"))
end

--@api-stub: Widget:removeChild
-- Detaches a child widget from a panel
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  local hint = lurek.terminal.newLabel(1, 1, "temporary tip")
  panel:addChild(hint)

  -- Remove the hint after the player acknowledges it.
  panel:removeChild(hint)
end

--@api-stub: Widget:clearChildren
-- Removes all child widgets from a panel
do
  -- Use clearChildren to rebuild a panel's content (e.g., switching dialog pages).
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "page 1 content"))

  -- Switch to page 2.
  panel:clearChildren()
  panel:addChild(lurek.terminal.newLabel(1, 1, "page 2 content"))
end

--@api-stub: Widget:getChildCount
-- Returns the number of child widgets in a panel
do
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "a"))
  panel:addChild(lurek.terminal.newLabel(1, 2, "b"))

  local n = panel:getChildCount()
  lurek.log.debug("panel has " .. n .. " children", "term") -- 2
end

--@api-stub: Widget:getChild
-- Returns a child widget from a panel by its 1-based index
do
  -- Access specific children to update them without keeping separate references.
  local panel = lurek.terminal.newPanel(2, 2, 30, 10)
  panel:addChild(lurek.terminal.newLabel(1, 1, "Title"))
  panel:addChild(lurek.terminal.newLabel(1, 2, "Subtitle"))

  local first = panel:getChild(1)
  if first then
    first:setText("Updated Title")
  end
end

--@api-stub: Terminal:mousepressed
-- Forwards a mouse press event, converting pixel coordinates to cell coordinates
do
  -- Call from lurek.mousepressed to let the terminal handle button clicks.
  -- The terminal converts pixel positions to cell coordinates internally.
  local term = lurek.terminal.newTerminal(80, 24)
  local btn = lurek.terminal.newButton(2, 2, 10, 1, "Click me")
  btn:setOnClick(function()
    lurek.log.info("button clicked via mouse", "ui")
  end)
  term:addWidget(btn)

  -- Simulate a mouse click at pixel position (20, 30), left button.
  term:mousepressed(20, 30, 1)
end

--@api-stub: Widget:setColor
-- Sets the foreground color of the widget as RGBA components (0-1 range)
do
  -- Color the widget text. Alpha defaults to 1 if omitted.
  local lbl = lurek.terminal.newLabel(1, 1, "OK")

  -- Green text for success messages.
  lbl:setColor(0.2, 0.9, 0.3)

  -- Red with partial transparency for a fading warning.
  local warn_lbl = lurek.terminal.newLabel(1, 2, "DANGER")
  warn_lbl:setColor(1.0, 0.2, 0.2, 0.7)
end

-- -----------------------------------------------------------------------------
-- LTerminal methods
-- -----------------------------------------------------------------------------

--@api-stub: LTerminal:type
-- Returns the type name string "LTerminal"
do
  -- type() returns the string identifier of the userdata object.
  -- Useful for runtime type checks in generic code.
  local terminal_obj = lurek.terminal.newTerminal(80, 24)
  local t = terminal_obj:type()
  lurek.log.info("type = " .. t, "terminal") -- "LTerminal"
end

--@api-stub: LTerminal:typeOf
-- Checks whether this object matches a given type name
do
  -- typeOf accepts "LTerminal" or "Object" (the base type for all engine userdata).
  local terminal_obj = lurek.terminal.newTerminal(80, 24)
  lurek.log.info("is LTerminal: " .. tostring(terminal_obj:typeOf("LTerminal")), "terminal") -- true
  lurek.log.info("is Object: " .. tostring(terminal_obj:typeOf("Object")), "terminal")       -- true
  lurek.log.info("is wrong: " .. tostring(terminal_obj:typeOf("Unknown")), "terminal")       -- false
end

--@api-stub: LWidget:type
-- Returns the type name string "LWidget"
do
  local widget_obj = lurek.terminal.newLabel(1, 1, "hello")
  local t = widget_obj:type()
  lurek.log.info("type = " .. t, "terminal") -- "LWidget"
end

--@api-stub: LWidget:typeOf
-- Checks whether this object matches a given type name
do
  local widget_obj = lurek.terminal.newLabel(1, 1, "hello")
  lurek.log.info("is LWidget: " .. tostring(widget_obj:typeOf("LWidget")), "terminal") -- true
  lurek.log.info("is Object: " .. tostring(widget_obj:typeOf("Object")), "terminal")   -- true
  lurek.log.info("is wrong: " .. tostring(widget_obj:typeOf("Unknown")), "terminal")   -- false
end

print("content/examples/terminal.lua")

-- =============================================================================
-- STUBS: 55 uncovered lurek.terminal API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LTerminal methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LTerminal:set -------------------------------------------------
--@api-stub: LTerminal:set
-- Writes a character with foreground and background color to a specific cell in the terminal grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:set(...)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:get -------------------------------------------------
--@api-stub: LTerminal:get
-- Reads the character and colors at a specific cell in the terminal grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:get(col, row)  -- -> number, number, number, number, number, number, number, number, number
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:clear -----------------------------------------------
--@api-stub: LTerminal:clear
-- Clears all cells in the terminal grid, resetting characters and colors to defaults.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:clear()
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:print -----------------------------------------------
--@api-stub: LTerminal:print
-- Writes text to the terminal grid starting at a specific cell.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:print(col, row, "Hello, world!")
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:getDimensions ---------------------------------------
--@api-stub: LTerminal:getDimensions
-- Returns the number of columns and rows in the terminal grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:getDimensions()  -- -> number, number
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:addWidget -------------------------------------------
--@api-stub: LTerminal:addWidget
-- Attaches a widget to this terminal so it is rendered and receives input events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:addWidget(widget_ud)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:removeWidget ----------------------------------------
--@api-stub: LTerminal:removeWidget
-- Detaches a widget from this terminal, removing it from rendering and input handling.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:removeWidget(widget_ud)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:clearWidgets ----------------------------------------
--@api-stub: LTerminal:clearWidgets
-- Removes all attached widgets from this terminal at once.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:clearWidgets()
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:getWidgetCount --------------------------------------
--@api-stub: LTerminal:getWidgetCount
-- Returns the number of widgets currently attached to this terminal.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:getWidgetCount()  -- -> number
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:setFocus --------------------------------------------
--@api-stub: LTerminal:setFocus
-- Sets which widget currently has keyboard focus, or clears focus when nil is passed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:setFocus(42)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:getFocused ------------------------------------------
--@api-stub: LTerminal:getFocused
-- Returns the widget that currently has keyboard focus, or nil if no widget is focused.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:getFocused()  -- -> LWidget
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:keypressed ------------------------------------------
--@api-stub: LTerminal:keypressed
-- Forwards a key press event to the terminal for widget input processing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:keypressed("player_score")  -- -> boolean
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:textinput -------------------------------------------
--@api-stub: LTerminal:textinput
-- Forwards a text input event to the terminal for character entry into focused widgets.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:textinput("Hello, world!")  -- -> boolean
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:mousepressed ----------------------------------------
--@api-stub: LTerminal:mousepressed
-- Forwards a mouse press event to the terminal, converting pixel coordinates to cell coordinates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:mousepressed(px, py, [button])
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:render ----------------------------------------------
--@api-stub: LTerminal:render
-- Renders the terminal grid and widgets and stages a window size matching the grid and active cell size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:render([x], [y])
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:setFont ---------------------------------------------
--@api-stub: LTerminal:setFont
-- Selects the nearest built-in bitmap font by pixel height and refits the window to the terminal grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:setFont(256)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:setCellSize -----------------------------------------
--@api-stub: LTerminal:setCellSize
-- Overrides the cell width and height used for rendering this terminal grid and refits the window.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:setCellSize(64.0, 64.0)
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:resetCellSize ---------------------------------------
--@api-stub: LTerminal:resetCellSize
-- Removes any custom cell size override, reverting to the active font metrics and refitting the window.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:resetCellSize()
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:getCellSize -----------------------------------------
--@api-stub: LTerminal:getCellSize
-- Returns the active terminal cell width and height in pixels, using custom override or font metrics.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:getCellSize()  -- -> number, number
-- (replace lTerminal_stub with your real LTerminal instance above)

-- ---- Stub: LTerminal:autoResize ------------------------------------------
--@api-stub: LTerminal:autoResize
-- Requests the window to resize so it exactly fits the terminal grid at the current cell size.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lTerminal_stub:autoResize()
-- (replace lTerminal_stub with your real LTerminal instance above)

-- -----------------------------------------------------------------------------
-- LWidget methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LWidget:setPosition -------------------------------------------
--@api-stub: LWidget:setPosition
-- Sets the widget position in 1-based cell coordinates within the terminal grid.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setPosition(col, row)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getPosition -------------------------------------------
--@api-stub: LWidget:getPosition
-- Returns the widget position as 1-based column and row.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getPosition()  -- -> number, number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setSize -----------------------------------------------
--@api-stub: LWidget:setSize
-- Sets the widget dimensions in cell units, clamped to a minimum of 1x1.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setSize(256, 256)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getSize -----------------------------------------------
--@api-stub: LWidget:getSize
-- Returns the widget dimensions as width and height in cell units.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getSize()  -- -> number, number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setVisible --------------------------------------------
--@api-stub: LWidget:setVisible
-- Controls whether the widget is drawn and receives input events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setVisible(is_visible)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:isVisible ---------------------------------------------
--@api-stub: LWidget:isVisible
-- Returns whether the widget is currently visible.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:isVisible()  -- -> boolean
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setEnabled --------------------------------------------
--@api-stub: LWidget:setEnabled
-- Controls whether the widget accepts user interaction (clicks, typing).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setEnabled(is_enabled)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:isEnabled ---------------------------------------------
--@api-stub: LWidget:isEnabled
-- Returns whether the widget is currently enabled for user interaction.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:isEnabled()  -- -> boolean
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setTag ------------------------------------------------
--@api-stub: LWidget:setTag
-- Assigns an arbitrary string tag to the widget for identification or grouping.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setTag(new_tag)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getTag ------------------------------------------------
--@api-stub: LWidget:getTag
-- Returns the current tag string assigned to the widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getTag()  -- -> string
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setText -----------------------------------------------
--@api-stub: LWidget:setText
-- Sets the display text of a label, button, or text box widget. Fires the onChange callback if the text actually changed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setText("Hello, world!")
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getText -----------------------------------------------
--@api-stub: LWidget:getText
-- Returns the current text content of a label, button, or text box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getText()  -- -> string
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setColor ----------------------------------------------
--@api-stub: LWidget:setColor
-- Sets the foreground color of the widget as RGBA components (0-1 range).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setColor(1.0, 0.8, 0.2, [a])
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getColor ----------------------------------------------
--@api-stub: LWidget:getColor
-- Returns the current RGBA color assigned to this widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getColor()  -- -> number, number, number, number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setOnClick --------------------------------------------
--@api-stub: LWidget:setOnClick
-- Registers a callback function invoked when a button widget is clicked. Only valid for button widgets.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setOnClick([callback])
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setMaxLength ------------------------------------------
--@api-stub: LWidget:setMaxLength
-- Sets the maximum number of characters allowed in a text box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setMaxLength(max_length)  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getMaxLength ------------------------------------------
--@api-stub: LWidget:getMaxLength
-- Returns the maximum character limit of a text box widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getMaxLength()  -- -> number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setOnChange -------------------------------------------
--@api-stub: LWidget:setOnChange
-- Registers a callback function invoked when the text content of a text box widget changes. Only valid for text box widgets.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setOnChange([callback])
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:addItem -----------------------------------------------
--@api-stub: LWidget:addItem
-- Appends a text item to a list widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:addItem(item)  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:removeItem --------------------------------------------
--@api-stub: LWidget:removeItem
-- Removes a list item by its 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:removeItem(1)  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:clearItems --------------------------------------------
--@api-stub: LWidget:clearItems
-- Removes all items from a list widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:clearItems()  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getItemCount ------------------------------------------
--@api-stub: LWidget:getItemCount
-- Returns the number of items in a list widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getItemCount()  -- -> number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getItem -----------------------------------------------
--@api-stub: LWidget:getItem
-- Returns the text of a list item by its 1-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getItem(1)  -- -> string
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setSelected -------------------------------------------
--@api-stub: LWidget:setSelected
-- Sets the currently selected item in a list widget by 1-based index, or clears the selection with nil. Fires the onSelect callback if changed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setSelected([index])
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getSelected -------------------------------------------
--@api-stub: LWidget:getSelected
-- Returns the 1-based index of the currently selected list item, or nil if nothing is selected.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getSelected()  -- -> number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setOnSelect -------------------------------------------
--@api-stub: LWidget:setOnSelect
-- Registers a callback function invoked when the selected item in a list widget changes. Only valid for list widgets.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setOnSelect([callback])
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setStyle ----------------------------------------------
--@api-stub: LWidget:setStyle
-- Sets the border drawing style for a border or panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setStyle(style_name)  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getStyle ----------------------------------------------
--@api-stub: LWidget:getStyle
-- Returns the current border style name of a border or panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getStyle()  -- -> string
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:setTitle ----------------------------------------------
--@api-stub: LWidget:setTitle
-- Sets the title text displayed in the border of a border or panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:setTitle(title)  -- -> LuaValue
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getTitle ----------------------------------------------
--@api-stub: LWidget:getTitle
-- Returns the current title text of a border or panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getTitle()  -- -> string
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:addChild ----------------------------------------------
--@api-stub: LWidget:addChild
-- Adds a child widget to a panel widget. The child becomes part of the panel layout and rendering.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:addChild(child_ud)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:removeChild -------------------------------------------
--@api-stub: LWidget:removeChild
-- Removes a child widget from a panel, detaching it from the panel layout.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:removeChild(child_ud)
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:clearChildren -----------------------------------------
--@api-stub: LWidget:clearChildren
-- Removes all child widgets from a panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:clearChildren()
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getChildCount -----------------------------------------
--@api-stub: LWidget:getChildCount
-- Returns the number of child widgets in a panel widget.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getChildCount()  -- -> number
-- (replace lWidget_stub with your real LWidget instance above)

-- ---- Stub: LWidget:getChild ----------------------------------------------
--@api-stub: LWidget:getChild
-- Returns a child widget from a panel by its 1-based index, or nil if the index is out of range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lWidget_stub:getChild(1)  -- -> LWidget
-- (replace lWidget_stub with your real LWidget instance above)
