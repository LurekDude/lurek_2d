-- examples/terminal.lua
-- luna.terminal — Grid-based character-cell terminal emulator with widget toolkit.
-- Draw text in a fixed-size cell grid, place interactive widgets (labels, buttons,
-- text boxes, lists, borders, panels), and forward OS input events to focused widgets.
-- All luna.terminal API methods demonstrated with code and comments.

-- ── Creating a Terminal ───────────────────────────────────────────────────────

-- luna.terminal.newTerminal(cols?, rows?) → Terminal
-- cols/rows: grid dimensions in cells (default 80×40)
-- Each cell is 8×14 pixels when drawn with draw().
local term = luna.terminal.newTerminal(80, 40)

-- ── Direct Cell Manipulation ──────────────────────────────────────────────────

-- term:set(col, row, ch, fr, fg, fb, fa, br, bg, bb, ba)
-- col, row: 1-based cell position
-- ch: single character string
-- fr,fg,fb,fa: foreground RGBA (0–255), optional
-- br,bg,bb,ba: background RGBA (0–255), optional
term:set(1, 1, "H", 255, 255, 255, 255, 0, 0, 0, 255)  -- white "H" on black
term:set(2, 1, "i", 200, 200, 0,   255)                 -- yellow "i", no bg
term:set(3, 1, "!")

-- term:get(col, row) → ch, fr, fg, fb, fa, br, bg, bb, ba
local ch, fr, fg, fb, fa, br, bg, bb, ba = term:get(1, 1)
print(ch, fr, fg, fb)   -- H  255  255  255

-- Helper: print a full string at a given position
local function term_print(t, col, row, text, r, g, b, a)
    r, g, b, a = r or 255, g or 255, b or 255, a or 255
    for i = 1, #text do
        t:set(col + i - 1, row, text:sub(i, i), r, g, b, a)
    end
end
term_print(term, 1, 2, "Hello, Terminal!", 0, 255, 100, 255)

-- term:getDimensions() → cols, rows
local cols, rows = term:getDimensions()

-- term:getCellSize() → width, height   (always 8, 14)
local cw, ch_size = term:getCellSize()

-- term:clear()  — fill all cells with spaces
term:clear()

-- ── Drawing the Terminal ──────────────────────────────────────────────────────

-- term:draw(x?, y?)  — render the grid at screen coordinate (x, y), default (0, 0)
-- Call inside luna.draw():
--   term:draw(0, 0)

-- ── Forwarding Input ─────────────────────────────────────────────────────────

-- term:keypressed(key) → boolean    — forward to focused widget; true if consumed
-- term:textinput(text) → boolean    — forward text input; true if consumed
-- term:mousepressed(px, py, button?) — forward mouse click to widgets

-- ── Widget Constructors ───────────────────────────────────────────────────────
-- All constructors take 1-based column/row grid coordinates.

-- newLabel(col, row, text?) → Widget
local lbl = luna.terminal.newLabel(2, 2, "Name:")

-- newButton(col, row, width, height?, text?) → Widget
local btn = luna.terminal.newButton(2, 8, 10, 1, "[ OK ]")

-- newTextBox(col, row, width) → Widget
local txt = luna.terminal.newTextBox(8, 2, 20)

-- newList(col, row, width, height) → Widget
local lst = luna.terminal.newList(2, 10, 20, 8)

-- newBorder(col, row, width, height) → Widget
local brd = luna.terminal.newBorder(1, 1, 40, 20)

-- newPanel(col, row, width?, height?) → Widget
local panel = luna.terminal.newPanel(1, 1, 60, 30)

-- ── Common Widget Methods ─────────────────────────────────────────────────────

-- setPosition(col, row) / getPosition() → col, row
btn:setPosition(2, 12)
local bc, br = btn:getPosition()

-- setSize(w, h) / getSize() → w, h
lst:setSize(24, 10)
local lw, lh = lst:getSize()

-- setVisible(bool) / isVisible() → bool
btn:setVisible(true)
local vis = btn:isVisible()

-- setEnabled(bool) / isEnabled() → bool
btn:setEnabled(true)
local en = btn:isEnabled()

-- setTag(str) / getTag() → str   — arbitrary string identifier
btn:setTag("ok_btn")
local tag = btn:getTag()

-- setText(str) / getText() → str   — label text, button label, textbox content
lbl:setText("Player name:")
txt:setText("")
local text_val = txt:getText()

-- setColor(r, g, b, a?) / getColor() → r, g, b, a   (0–255 range)
lbl:setColor(255, 200, 0, 255)
local lr, lg, lb, la = lbl:getColor()

-- ── Button Callbacks ─────────────────────────────────────────────────────────

-- setOnClick(function?)
btn:setOnClick(function()
    print("OK clicked! name =", txt:getText())
end)

-- ── TextBox Methods ───────────────────────────────────────────────────────────

-- setMaxLength(n) / getMaxLength() → int   — limit text input length
txt:setMaxLength(16)
local maxl = txt:getMaxLength()

-- setOnChange(function?)   — called whenever text changes
txt:setOnChange(function()
    print("Text changed:", txt:getText())
end)

-- ── List Methods ──────────────────────────────────────────────────────────────

-- addItem(str)   — append an entry
lst:addItem("Sword")
lst:addItem("Shield")
lst:addItem("Potion")

-- removeItem(index)   — remove by 1-based index
-- lst:removeItem(2)

-- clearItems()
-- lst:clearItems()

-- getItemCount() → int
local n_items = lst:getItemCount()

-- getItem(index) → str
local first = lst:getItem(1)

-- setSelected(index?) / getSelected() → int?
lst:setSelected(2)
local sel_idx = lst:getSelected()

-- setOnSelect(function?)
lst:setOnSelect(function()
    print("Selected:", lst:getItem(lst:getSelected()))
end)

-- ── Border / Title Methods ────────────────────────────────────────────────────

-- setStyle(str) / getStyle() → str
-- Styles: "single", "double", "rounded", "dotted", "tab" (or similar names)
brd:setStyle("double")
local style = brd:getStyle()

-- setTitle(str) / getTitle() → str
brd:setTitle("[ Inventory ]")
local title = brd:getTitle()

-- ── Panel / Child Methods ─────────────────────────────────────────────────────

-- addChild(widget)
panel:addChild(lbl)
panel:addChild(txt)
panel:addChild(btn)

-- removeChild(widget)
-- panel:removeChild(btn)

-- clearChildren()
-- panel:clearChildren()

-- getChildCount() → int
local cn = panel:getChildCount()

-- getChild(index) → Widget?   (1-based)
local first_child = panel:getChild(1)

-- ── Adding Widgets to Terminal ────────────────────────────────────────────────

-- term:addWidget(widget)
term:addWidget(brd)
term:addWidget(lbl)
term:addWidget(txt)
term:addWidget(btn)
term:addWidget(lst)

-- term:getWidgetCount() → int
local wn = term:getWidgetCount()

-- term:setFocus(widget?) / term:getFocused() → Widget?
term:setFocus(txt)
local focused = term:getFocused()

-- term:removeWidget(widget)
-- term:clearWidgets()

-- ── Full Integration Example ─────────────────────────────────────────────────

--[[
local my_term

function luna.init()
    my_term = luna.terminal.newTerminal(80, 30)

    local brd = luna.terminal.newBorder(1, 1, 40, 12)
    brd:setStyle("double")
    brd:setTitle("[ Login ]")
    my_term:addWidget(brd)

    local lbl_user = luna.terminal.newLabel(3, 3, "Username:")
    my_term:addWidget(lbl_user)

    local txt_user = luna.terminal.newTextBox(13, 3, 20)
    txt_user:setMaxLength(20)
    my_term:addWidget(txt_user)

    local btn_ok = luna.terminal.newButton(3, 10, 12, 1, "[ Connect ]")
    btn_ok:setOnClick(function()
        print("Connecting as:", txt_user:getText())
    end)
    my_term:addWidget(btn_ok)

    my_term:setFocus(txt_user)
end

function luna.keypressed(key)
    my_term:keypressed(key)
end

function luna.textinput(text)
    my_term:textinput(text)
end

function luna.mousepressed(x, y, button)
    local cw, ch = my_term:getCellSize()
    -- convert pixel coords to cell coords for mousepressed
    my_term:mousepressed(
        math.floor(x / cw) + 1,
        math.floor(y / ch) + 1,
        button
    )
end

function luna.render()
    my_term:draw(0, 0)
end
]]
