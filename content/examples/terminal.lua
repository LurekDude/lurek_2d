-- content/examples/terminal.lua
-- Lurek2D lurek.terminal API Reference
-- Run with: cargo run -- content/examples/terminal
--
-- Scenario: A roguelike game console — a 80x25 text grid with an inventory list,
-- command input box, game log scrollback, and bordered status panels. Demonstrates
-- the full terminal + widget API for building text-mode game UIs.

print("=== lurek.terminal — Roguelike Game Console ===\n")

-- =============================================================================
-- Terminal Grid — create the main 80×25 game console
-- =============================================================================

-- ---- Stub: lurek.terminal.newTerminal ------------------------------------
--@api-stub: lurek.terminal.newTerminal
-- Create an 80-column, 25-row terminal grid for a classic roguelike display.
local term = lurek.terminal.newTerminal(80, 25)
print("terminal created: 80x25 grid")

-- ---- Stub: lurek.terminal.getMaxCols -------------------------------------
--@api-stub: lurek.terminal.getMaxCols
-- Check the engine's maximum supported column count before creating huge terminals.
local max_cols = lurek.terminal.getMaxCols()
print("max supported columns: " .. tostring(max_cols))

-- ---- Stub: lurek.terminal.getMaxRows -------------------------------------
--@api-stub: lurek.terminal.getMaxRows
-- Check the engine's maximum supported row count.
local max_rows = lurek.terminal.getMaxRows()
print("max supported rows: " .. tostring(max_rows))

-- =============================================================================
-- Terminal Methods — cell manipulation, dimensions, font, rendering
-- =============================================================================

-- ---- Stub: Terminal:set --------------------------------------------------
--@api-stub: Terminal:set
-- Draw the player '@' symbol at position (10, 12) in bright green on black.
term:set(10, 12, "@", {0, 1, 0, 1}, {0, 0, 0, 1})
print("player '@' placed at (10, 12) in green")

-- ---- Stub: Terminal:get --------------------------------------------------
--@api-stub: Terminal:get
-- Read the cell at the player's position to confirm it was set correctly.
local cell = term:get(10, 12)
print("cell at (10,12): char=" .. tostring(cell))

-- ---- Stub: Terminal:getDimensions ----------------------------------------
--@api-stub: Terminal:getDimensions
-- Read back the grid size to position UI elements relative to the edges.
local cols, rows = term:getDimensions()
print("terminal dimensions: " .. tostring(cols) .. "x" .. tostring(rows))

-- ---- Stub: Terminal:getCellSize ------------------------------------------
--@api-stub: Terminal:getCellSize
-- Get the pixel size of each cell to calculate screen-space positions.
local cell_w, cell_h = term:getCellSize()
print("cell pixel size: " .. tostring(cell_w) .. "x" .. tostring(cell_h))

-- ---- Stub: Terminal:setFont ----------------------------------------------
--@api-stub: Terminal:setFont
-- Use a 16px font for crisp text on a 1080p display.
term:setFont(16)
print("terminal font set to 16px")

-- ---- Stub: Terminal:setCellSize ------------------------------------------
--@api-stub: Terminal:setCellSize
-- Override the font-derived cell size to exactly 10x18 pixels for tight packing.
term:setCellSize(10.0, 18.0)
print("cell size override: 10x18 pixels")

-- ---- Stub: Terminal:getCellSize ------------------------------------------
--@api-stub: Terminal:getCellSize
-- Verify the override is active — returns the overridden {w,h} table.
local override = term:getCellSize()
print("cell size override: " .. tostring(override))

-- ---- Stub: Terminal:resetCellSize ----------------------------------------
--@api-stub: Terminal:resetCellSize
-- Remove the override to go back to font-derived cell dimensions.
term:resetCellSize()
print("cell size override removed — using font-derived size")

-- ---- Stub: Terminal:autoResize -------------------------------------------
--@api-stub: Terminal:autoResize
-- Resize the game window to perfectly fit the 80x25 grid at the current font size.
-- Avoids black borders or partial cells.
term:autoResize()
print("window auto-resized to fit 80x25 grid")

-- ---- Stub: Terminal:clear ------------------------------------------------
--@api-stub: Terminal:clear
-- Clear the entire grid before drawing a new frame — resets all cells to defaults.
term:clear()
print("terminal cleared for new frame")

-- =============================================================================
-- Scrollback Buffer — game message log
-- =============================================================================

-- ---- Stub: lurek.terminal.pushScrollback ---------------------------------
--@api-stub: lurek.terminal.pushScrollback
-- Log game events to the scrollback buffer — the player can scroll back to read them.
lurek.terminal.pushScrollback(term, "You enter the Dungeon of Doom.")
lurek.terminal.pushScrollback(term, "A goblin appears!")
lurek.terminal.pushScrollback(term, "You swing your sword... Hit! 12 damage.")
lurek.terminal.pushScrollback(term, "The goblin is defeated. +25 XP.")
print("4 game log messages pushed to scrollback")

-- ---- Stub: lurek.terminal.scrollbackLen ----------------------------------
--@api-stub: lurek.terminal.scrollbackLen
-- Show the log line count in a debug overlay.
local sb_len = lurek.terminal.scrollbackLen(term)
print("scrollback lines: " .. tostring(sb_len))

-- ---- Stub: lurek.terminal.getScrollback ----------------------------------
--@api-stub: lurek.terminal.getScrollback
-- Retrieve the most recent 10 lines starting from offset 0 for the visible log area.
local recent = lurek.terminal.getScrollback(term, 0, 10)
if recent then
    print("recent log (" .. #recent .. " lines):")
    for i, line in ipairs(recent) do
        print("  [" .. i .. "] " .. line)
    end
end

-- ---- Stub: lurek.terminal.setScrollbackCap -------------------------------
--@api-stub: lurek.terminal.setScrollbackCap
-- Limit the scrollback to 500 lines to prevent unbounded memory growth in long sessions.
lurek.terminal.setScrollbackCap(term, 500)
print("scrollback cap set to 500 lines")

-- =============================================================================
-- Command History — arrow-key recall of typed commands
-- =============================================================================

-- ---- Stub: lurek.terminal.pushCmdHistory ---------------------------------
--@api-stub: lurek.terminal.pushCmdHistory
-- Save each command the player types so they can recall it with arrow keys.
lurek.terminal.pushCmdHistory(term, "look")
lurek.terminal.pushCmdHistory(term, "inventory")
lurek.terminal.pushCmdHistory(term, "attack goblin")
lurek.terminal.pushCmdHistory(term, "use potion")
print("4 commands saved to history")

-- ---- Stub: lurek.terminal.cmdHistoryLen ----------------------------------
--@api-stub: lurek.terminal.cmdHistoryLen
-- Show history depth in the debug panel.
local hist_len = lurek.terminal.cmdHistoryLen(term)
print("command history: " .. tostring(hist_len) .. " entries")

-- ---- Stub: lurek.terminal.prevCmd ----------------------------------------
--@api-stub: lurek.terminal.prevCmd
-- Press Up arrow — recall the previous command ("use potion").
local prev = lurek.terminal.prevCmd(term)
print("prev command: " .. tostring(prev))

-- ---- Stub: lurek.terminal.nextCmd ----------------------------------------
--@api-stub: lurek.terminal.nextCmd
-- Press Down arrow — step forward in history.
local nxt = lurek.terminal.nextCmd(term)
print("next command: " .. tostring(nxt))

-- ---- Stub: lurek.terminal.clearCmdHistory --------------------------------
--@api-stub: lurek.terminal.clearCmdHistory
-- Clear history when starting a new game session.
lurek.terminal.clearCmdHistory(term)
print("command history cleared for new session")

-- =============================================================================
-- Theme and ANSI — colours, highlighting, escape codes
-- =============================================================================

-- ---- Stub: lurek.terminal.applyTheme -------------------------------------
--@api-stub: lurek.terminal.applyTheme
-- Apply the "solarized_dark" theme for a warm, readable colour palette.
lurek.terminal.applyTheme(term, "solarized_dark")
print("theme applied: solarized_dark")

-- ---- Stub: lurek.terminal.printHighlighted -------------------------------
--@api-stub: lurek.terminal.printHighlighted
-- Print a status line with keyword-based colour highlighting.
-- Keywords like "HP" and "MP" get distinct colours for quick scanning.
lurek.terminal.printHighlighted(term, 1, 25, "HP: 85/100  MP: 30/50  Gold: 142", {
    HP = {1, 0.3, 0.3, 1},
    MP = {0.3, 0.3, 1, 1},
    Gold = {1, 0.85, 0, 1},
})
print("highlighted status line printed at row 25")

-- ---- Stub: lurek.terminal.stripAnsi --------------------------------------
--@api-stub: lurek.terminal.stripAnsi
-- Strip ANSI codes from a log line before saving to a plain-text file.
local ansi_text = "\27[31mCRITICAL HIT!\27[0m You deal 48 damage."
local plain = lurek.terminal.stripAnsi(ansi_text)
print("stripped: " .. plain)

-- ---- Stub: lurek.terminal.parseAnsi --------------------------------------
--@api-stub: lurek.terminal.parseAnsi
-- Parse ANSI text into coloured spans for custom rendering.
local spans = lurek.terminal.parseAnsi("\27[32mHealed\27[0m 20 HP")
if spans then
    print("parsed " .. #spans .. " ANSI spans:")
    for i, span in ipairs(spans) do
        print("  span " .. i .. ": text='" .. tostring(span.text) .. "'")
    end
end

-- ---- Stub: lurek.terminal.printAnsi --------------------------------------
--@api-stub: lurek.terminal.printAnsi
-- Print an ANSI-escaped string directly onto the terminal grid at (1, 24).
-- The engine interprets ANSI colour codes and maps them to cell FG/BG colours.
lurek.terminal.printAnsi(term, 1, 24, "\27[33mWarning:\27[0m Low health!")
print("ANSI text printed at (1, 24)")

-- =============================================================================
-- Tab Completion — auto-complete game commands
-- =============================================================================

-- ---- Stub: lurek.terminal.addCompletion ----------------------------------
--@api-stub: lurek.terminal.addCompletion
-- Register all valid game commands for tab-completion.
local commands = {"look", "inventory", "attack", "use", "drop", "equip",
                  "unequip", "talk", "open", "close", "cast", "rest"}
for _, cmd in ipairs(commands) do
    lurek.terminal.addCompletion(cmd)
end
print(#commands .. " commands registered for tab-completion")

-- ---- Stub: lurek.terminal.getCompletions ---------------------------------
--@api-stub: lurek.terminal.getCompletions
-- Get all completions matching the prefix "a" — should return {"attack"}.
local matches = lurek.terminal.getCompletions("a")
print("completions for 'a': " .. tostring(#matches))
if matches then
    for _, m in ipairs(matches) do print("  " .. m) end
end

-- ---- Stub: lurek.terminal.nextCompletion ---------------------------------
--@api-stub: lurek.terminal.nextCompletion
-- Cycle through completions for prefix "c" — "cast", "close", "cast", ...
local c1 = lurek.terminal.nextCompletion("c")
print("first completion for 'c': " .. tostring(c1))
local c2 = lurek.terminal.nextCompletion("c")
print("second completion for 'c': " .. tostring(c2))

-- ---- Stub: lurek.terminal.resetCompletion --------------------------------
--@api-stub: lurek.terminal.resetCompletion
-- Reset the cycle cursor when the user changes the input prefix.
lurek.terminal.resetCompletion()
print("completion cycle reset")

-- ---- Stub: lurek.terminal.removeCompletion -------------------------------
--@api-stub: lurek.terminal.removeCompletion
-- Remove "rest" from completions — the player lost the ability to rest in combat.
lurek.terminal.removeCompletion("rest")
print("'rest' removed from completions (combat mode)")

-- ---- Stub: lurek.terminal.clearCompletions -------------------------------
--@api-stub: lurek.terminal.clearCompletions
-- Clear all completions when transitioning to a cutscene (no input allowed).
lurek.terminal.clearCompletions()
print("all completions cleared for cutscene")

-- =============================================================================
-- Widget Factory — labels, buttons, text boxes, lists, borders, panels
-- =============================================================================

-- ---- Stub: lurek.terminal.newLabel ---------------------------------------
--@api-stub: lurek.terminal.newLabel
-- Create a title label at the top of the screen showing the dungeon name.
local title_label = lurek.terminal.newLabel(30, 1, "Dungeon of Doom - Floor 3")
print("title label created at (30, 1)")

-- ---- Stub: lurek.terminal.newButton --------------------------------------
--@api-stub: lurek.terminal.newButton
-- Create a "Rest" button in the bottom-right corner of the terminal.
local rest_btn = lurek.terminal.newButton()
print("rest button created")

-- ---- Stub: lurek.terminal.newTextBox -------------------------------------
--@api-stub: lurek.terminal.newTextBox
-- Create a command input box at the bottom of the screen, 60 chars max.
local cmd_input = lurek.terminal.newTextBox(2, 24, 60)
print("command input text box created at (2, 24), max 60 chars")

-- ---- Stub: lurek.terminal.newList ----------------------------------------
--@api-stub: lurek.terminal.newList
-- Create an inventory list on the right side of the screen — 20 cols wide, 15 rows tall.
local inv_list = lurek.terminal.newList(60, 3, 20, 15)
print("inventory list created at (60, 3), 20x15 cells")

-- ---- Stub: lurek.terminal.newBorder --------------------------------------
--@api-stub: lurek.terminal.newBorder
-- Create a decorative border around the inventory area.
local inv_border = lurek.terminal.newBorder(59, 2, 22, 17)
print("inventory border created at (59, 2), 22x17 cells")

-- ---- Stub: lurek.terminal.newPanel ---------------------------------------
--@api-stub: lurek.terminal.newPanel
-- Create a status panel in the bottom-left for HP/MP bars.
local status_panel = lurek.terminal.newPanel(1, 20, 30, 5)
print("status panel created at (1, 20), 30x5 cells")

-- =============================================================================
-- Widget Management — attach/detach widgets to the terminal
-- =============================================================================

-- ---- Stub: Terminal:addWidget --------------------------------------------
--@api-stub: Terminal:addWidget
-- Attach all widgets to the terminal so they render with the grid.
term:addWidget(title_label)
term:addWidget(rest_btn)
term:addWidget(cmd_input)
term:addWidget(inv_list)
term:addWidget(inv_border)
term:addWidget(status_panel)
print("6 widgets attached to terminal")

-- ---- Stub: Terminal:getWidgetCount ---------------------------------------
--@api-stub: Terminal:getWidgetCount
-- Verify the expected widget count for a debug assertion.
local wcount = term:getWidgetCount()
print("attached widgets: " .. tostring(wcount))

-- ---- Stub: Terminal:removeWidget -----------------------------------------
--@api-stub: Terminal:removeWidget
-- Temporarily remove the rest button during combat (can't rest while fighting).
term:removeWidget(rest_btn)
print("rest button removed during combat")

-- Re-add it after combat
term:addWidget(rest_btn)

-- ---- Stub: Terminal:clearWidgets -----------------------------------------
--@api-stub: Terminal:clearWidgets
-- Clear all widgets when transitioning to a different screen (e.g. main menu).
-- We'll re-add them immediately for this example.
term:clearWidgets()
print("all widgets cleared (screen transition)")

-- Re-attach for remaining examples
term:addWidget(title_label)
term:addWidget(cmd_input)
term:addWidget(inv_list)
term:addWidget(inv_border)
term:addWidget(status_panel)

-- =============================================================================
-- Widget Common Methods — position, size, visibility, enabled, tag, text
-- =============================================================================

-- ---- Stub: Widget:setPosition --------------------------------------------
--@api-stub: Widget:setPosition
-- Move the title label to center it after measuring the terminal width.
title_label:setPosition(28, 1)
print("title label repositioned to (28, 1)")

-- ---- Stub: Widget:getPosition --------------------------------------------
--@api-stub: Widget:getPosition
-- Read back position for layout debugging.
local lx, ly = title_label:getPosition()
print("title label position: (" .. tostring(lx) .. ", " .. tostring(ly) .. ")")

-- ---- Stub: Widget:setSize ------------------------------------------------
--@api-stub: Widget:setSize
-- Resize the inventory list to be taller when the player has many items.
inv_list:setSize(20, 18)
print("inventory list resized to 20x18")

-- ---- Stub: Widget:getSize ------------------------------------------------
--@api-stub: Widget:getSize
-- Read back list size for scroll calculations.
local lw, lh = inv_list:getSize()
print("inventory list size: " .. tostring(lw) .. "x" .. tostring(lh))

-- ---- Stub: Widget:setVisible ---------------------------------------------
--@api-stub: Widget:setVisible
-- Hide the inventory during cutscenes.
inv_list:setVisible(false)
print("inventory hidden for cutscene")

-- ---- Stub: Widget:isVisible ----------------------------------------------
--@api-stub: Widget:isVisible
-- Check visibility before attempting to draw.
local vis = inv_list:isVisible()
print("inventory visible: " .. tostring(vis))

-- Show it again
inv_list:setVisible(true)

-- ---- Stub: Widget:setEnabled ---------------------------------------------
--@api-stub: Widget:setEnabled
-- Disable the command input during an animation sequence.
cmd_input:setEnabled(false)
print("command input disabled during animation")

-- ---- Stub: Widget:isEnabled ----------------------------------------------
--@api-stub: Widget:isEnabled
-- Check if input is accepting keystrokes.
local enabled = cmd_input:isEnabled()
print("command input enabled: " .. tostring(enabled))

-- Re-enable after animation
cmd_input:setEnabled(true)

-- ---- Stub: Widget:setTag -------------------------------------------------
--@api-stub: Widget:setTag
-- Tag widgets for programmatic lookup by name.
title_label:setTag("title")
cmd_input:setTag("cmd_input")
inv_list:setTag("inventory")
print("widgets tagged: title, cmd_input, inventory")

-- ---- Stub: Widget:getTag -------------------------------------------------
--@api-stub: Widget:getTag
-- Retrieve a widget's tag for identification.
local tag = cmd_input:getTag()
print("cmd_input tag: " .. tostring(tag))

-- ---- Stub: Widget:setText ------------------------------------------------
--@api-stub: Widget:setText
-- Update the title label to show the current floor.
title_label:setText("Dungeon of Doom - Floor 5 (Boss)")
print("title updated to Floor 5")

-- ---- Stub: Widget:getText ------------------------------------------------
--@api-stub: Widget:getText
-- Read back the current title text.
local title_text = title_label:getText()
print("title text: " .. tostring(title_text))

-- ---- Stub: Widget:getColor -----------------------------------------------
--@api-stub: Widget:getColor
-- Read the label's colour to apply a matching tint to the border.
local label_color = title_label:getColor()
print("title label color: " .. tostring(label_color))

-- =============================================================================
-- Button Widget — click callbacks
-- =============================================================================

-- ---- Stub: Widget:setOnClick ---------------------------------------------
--@api-stub: Widget:setOnClick
-- Register a click handler for the rest button — heals the player.
rest_btn:setOnClick(function()
    print("  [button] Rest clicked — player heals 10 HP")
end)
print("rest button onClick registered")

-- =============================================================================
-- TextBox Widget — input, max length, change callback
-- =============================================================================

-- ---- Stub: Widget:setMaxLength -------------------------------------------
--@api-stub: Widget:setMaxLength
-- Limit command input to 80 characters to fit on one terminal row.
cmd_input:setMaxLength(80)
print("command input max length: 80 chars")

-- ---- Stub: Widget:getMaxLength -------------------------------------------
--@api-stub: Widget:getMaxLength
-- Read back the max length for a help tooltip: "Commands up to N chars".
local max_len = cmd_input:getMaxLength()
print("command input max length: " .. tostring(max_len))

-- ---- Stub: Widget:setOnChange --------------------------------------------
--@api-stub: Widget:setOnChange
-- Trigger auto-complete suggestions as the player types.
cmd_input:setOnChange(function(new_text)
    print("  [input] text changed: '" .. tostring(new_text) .. "'")
end)
print("command input onChange registered for auto-complete")

-- =============================================================================
-- List Widget — inventory items
-- =============================================================================

-- ---- Stub: Widget:addItem ------------------------------------------------
--@api-stub: Widget:addItem
-- Populate the inventory with starting items.
inv_list:addItem("Iron Sword")
inv_list:addItem("Leather Armor")
inv_list:addItem("Health Potion x3")
inv_list:addItem("Torch x5")
inv_list:addItem("Rope (50 ft)")
inv_list:addItem("Rations x10")
print("6 items added to inventory")

-- ---- Stub: Widget:getItemCount -------------------------------------------
--@api-stub: Widget:getItemCount
-- Show "Inventory (N items)" in the border title.
local item_count = inv_list:getItemCount()
print("inventory items: " .. tostring(item_count))

-- ---- Stub: Widget:getItem ------------------------------------------------
--@api-stub: Widget:getItem
-- Read the first item to display in a tooltip.
local first_item = inv_list:getItem(1)
print("first inventory item: " .. tostring(first_item))

-- ---- Stub: Widget:setSelected --------------------------------------------
--@api-stub: Widget:setSelected
-- Auto-select the first item when opening the inventory.
inv_list:setSelected(1)
print("first item selected")

-- ---- Stub: Widget:getSelected --------------------------------------------
--@api-stub: Widget:getSelected
-- Read the selected index to highlight it in the UI.
local sel_idx = inv_list:getSelected()
print("selected index: " .. tostring(sel_idx))

-- ---- Stub: Widget:setOnSelect --------------------------------------------
--@api-stub: Widget:setOnSelect
-- Show item details when the player selects an inventory entry.
inv_list:setOnSelect(function(index)
    print("  [list] item " .. tostring(index) .. " selected")
end)
print("inventory onSelect registered")

-- ---- Stub: Widget:removeItem ---------------------------------------------
--@api-stub: Widget:removeItem
-- Remove item 3 (Health Potion) after the player uses it.
inv_list:removeItem(3)
print("item 3 removed (Health Potion used)")

-- ---- Stub: Widget:clearItems ---------------------------------------------
--@api-stub: Widget:clearItems
-- Clear the inventory when the player dies and restarts.
inv_list:clearItems()
print("inventory cleared for new game")

-- Re-add items for remaining examples
inv_list:addItem("Iron Sword")
inv_list:addItem("Leather Armor")

-- =============================================================================
-- Border Widget — decorative frames with titles and styles
-- =============================================================================

-- ---- Stub: Widget:setStyle -----------------------------------------------
--@api-stub: Widget:setStyle
-- Use double-line border style for the inventory frame — looks polished.
inv_border:setStyle("double")
print("inventory border style: double")

-- ---- Stub: Widget:getStyle -----------------------------------------------
--@api-stub: Widget:getStyle
-- Confirm the border style for a style-switching toggle.
local border_style = inv_border:getStyle()
print("border style: " .. tostring(border_style))

-- ---- Stub: Widget:setTitle -----------------------------------------------
--@api-stub: Widget:setTitle
-- Set the border title to show "Inventory (2 items)".
inv_border:setTitle("Inventory (" .. tostring(inv_list:getItemCount()) .. " items)")
print("border title set")

-- ---- Stub: Widget:getTitle -----------------------------------------------
--@api-stub: Widget:getTitle
-- Read back the border title for validation.
local border_title = inv_border:getTitle()
print("border title: " .. tostring(border_title))

-- =============================================================================
-- Panel Widget — container with children
-- =============================================================================

-- ---- Stub: Widget:addChild -----------------------------------------------
--@api-stub: Widget:addChild
-- Add HP and MP labels as children of the status panel.
local hp_label = lurek.terminal.newLabel(2, 1, "HP: 85/100")
local mp_label = lurek.terminal.newLabel(2, 2, "MP: 30/50")
local gold_label = lurek.terminal.newLabel(2, 3, "Gold: 142")
status_panel:addChild(hp_label)
status_panel:addChild(mp_label)
status_panel:addChild(gold_label)
print("3 stat labels added to status panel")

-- ---- Stub: Widget:getChildCount ------------------------------------------
--@api-stub: Widget:getChildCount
-- Verify the panel has the expected number of stat labels.
local child_count = status_panel:getChildCount()
print("status panel children: " .. tostring(child_count))

-- ---- Stub: Widget:getChild -----------------------------------------------
--@api-stub: Widget:getChild
-- Get the first child (HP label) to update its text after taking damage.
local hp_child = status_panel:getChild(1)
if hp_child then
    hp_child:setText("HP: 73/100")
    print("HP label updated after taking damage")
end

-- ---- Stub: Widget:removeChild --------------------------------------------
--@api-stub: Widget:removeChild
-- Remove the gold display during combat (less clutter).
status_panel:removeChild(gold_label)
print("gold label removed from status panel during combat")

-- ---- Stub: Widget:clearChildren ------------------------------------------
--@api-stub: Widget:clearChildren
-- Clear all children when transitioning to a different screen.
status_panel:clearChildren()
print("status panel children cleared")

-- =============================================================================
-- Focus and Input Routing — keyboard navigation between widgets
-- =============================================================================

-- Re-add widgets for focus examples
term:addWidget(rest_btn)

-- ---- Stub: Terminal:setFocus ---------------------------------------------
--@api-stub: Terminal:setFocus
-- Focus the command input box so keystrokes go to it immediately.
term:setFocus(cmd_input)
print("focus set to command input")

-- ---- Stub: Terminal:getFocused -------------------------------------------
--@api-stub: Terminal:getFocused
-- Check which widget has focus — used for visual highlight indicators.
local focused = term:getFocused()
print("focused widget: " .. tostring(focused))

-- ---- Stub: Terminal:keypressed -------------------------------------------
--@api-stub: Terminal:keypressed
-- Route a key press to the focused widget — simulates the player pressing Enter.
local handled = term:keypressed("return")
print("keypress 'return' handled: " .. tostring(handled))

-- ---- Stub: Terminal:textinput --------------------------------------------
--@api-stub: Terminal:textinput
-- Route text input to the focused text box — simulates the player typing "look".
local text_handled = term:textinput("look")
print("textinput 'look' handled: " .. tostring(text_handled))

-- =============================================================================
-- Rendering — draw the terminal grid and all attached widgets
-- =============================================================================

-- ---- Stub: Terminal:render -----------------------------------------------
--@api-stub: Terminal:render
-- Render the entire terminal at screen position (0, 0).
-- Call this once per frame in lurek.render() to draw the grid + all widgets.
term:render(0, 0)
print("terminal rendered at (0, 0)")

print("\n-- terminal.lua example complete --")
