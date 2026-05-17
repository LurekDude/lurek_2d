-- content/games/showcase/terminal_demo/main.lua
-- Terminal API showcase: 5 navigable scenes covering all lurek.terminal widgets.
-- Auto-fills the window. Navigate: Left/Right arrows or 1-5.

local SCENE_COUNT = 5
local scene       = 1
local term        ---@type LTerminal
local tick        = 0

local cmd_input   ---@type LWidget?
local inv_list    ---@type LWidget?
local name_input  ---@type LWidget?
local status_lbl  ---@type LWidget?

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function add_border(t, c, r, w, h, style, title)
    local b = lurek.terminal.newBorder(c, r, w, h)
    b:setStyle(style or "single")
    if title then b:setTitle(title) end
    t:addWidget(b)
    return b
end

local function add_label(t, c, r, text, lr, lg, lb)
    local l = lurek.terminal.newLabel(c, r, text)
    if lr then l:setColor(lr, lg or 1, lb or 1) end
    t:addWidget(l)
    return l
end

local function nav_hint(t, cols, rows)
    add_label(t, 3, rows - 1,
        string.format("  [<-][->] prev/next   [1-5] jump   scene %d/%d  ", scene, SCENE_COUNT),
        0.3, 0.3, 0.3)
end

local function window_fit(font_size)
    local probe = lurek.terminal.newTerminal(10, 10)
    probe:setFont(font_size)
    local cw, ch = probe:getCellSize()
    local w, h   = lurek.window.getDimensions()
    local cols   = math.max(40, math.floor(w / cw))
    local rows   = math.max(10, math.floor(h / ch))
    return cols, rows
end

-- ─── scene 1: raw cell drawing ───────────────────────────────────────────────

local function build_scene1(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 1/5: set()  print()  Unicode  getDimensions ", 1, 0.9, 0.2)

    -- animated rainbow banner redrawn each frame in lurek.draw
    add_label(t, 3, 5, "print() - writes text into cells:", 0.5, 0.5, 0.5)
    t:print(3, 6, "The quick brown fox jumps over the lazy dog")
    t:print(3, 7, "1234567890  !@#$%^&*()-=[]{}|;:,.<>?")

    add_label(t, 3, 9, "set() - per-cell foreground and background color:", 0.5, 0.5, 0.5)
    local ch_set  = { "#", "@", "%", "&", "*", "=", "+", "-", "^", "!" }
    local col_set = {
        {1,.3,.3},{1,.7,.2},{.9,1,.2},{.2,1,.4},{.2,.9,1},
        {.4,.4,1},{.9,.3,1},{1,.5,.5},{.5,1,.5},{.5,.5,1},
    }
    for i, ch in ipairs(ch_set) do
        local x = (i - 1) * 5 + 3
        local c = col_set[i]
        for dy = 0, 3 do
            t:set(x, 10 + dy, ch, c[1], c[2], c[3], 1, c[1]*.12, c[2]*.12, c[3]*.12, 1)
        end
    end

    add_label(t, 3, 15, "set() - Unicode codepoints:", 0.5, 0.5, 0.5)
    local glyphs = {9829,9830,9824,9827,9733,9658,9650,9660,9632,9633,9679,8984}
    for i, cp in ipairs(glyphs) do
        t:set(3 + (i - 1) * 3, 16, cp, 1, 0.9, 0.3, 1)
    end

    local dc, dr   = t:getDimensions()
    local cw, ch2  = t:getCellSize()
    add_label(t, 3, 18, string.format("getDimensions: %d x %d cells", dc, dr), .4, 1, .4)
    add_label(t, 3, 19, string.format("getCellSize:   %d x %d px/cell", cw, ch2), .4, 1, .4)
    add_label(t, 3, 20, "type(): " .. t:type() .. "  typeOf(LTerminal): " .. tostring(t:typeOf("LTerminal")), .7, .7, 1)

    nav_hint(t, cols, rows)
end

-- ─── scene 2: buttons, textbox, list ─────────────────────────────────────────

local function build_scene2(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 2/5: Button  TextBox  List  setFocus  callbacks ", 1, 0.9, 0.2)

    add_border(t, 2, 3, 36, 12, "single", " Buttons ")

    local b_normal = lurek.terminal.newButton(4, 5, 20, 1, "[ Normal button ]")
    b_normal:setOnClick(function()
        if status_lbl then status_lbl:setText("Clicked: Normal button") end
    end)
    t:addWidget(b_normal)

    local b_wide = lurek.terminal.newButton(4, 7, 28, 3, "[ Wide 3-row button ]")
    b_wide:setOnClick(function()
        if status_lbl then status_lbl:setText("Clicked: Wide (3-row) button") end
    end)
    t:addWidget(b_wide)

    local b_dis = lurek.terminal.newButton(4, 11, 28, 1, "[ Disabled - setEnabled(false) ]")
    b_dis:setEnabled(false)
    t:addWidget(b_dis)

    add_border(t, 2, 16, 36, 5, "single", " TextBox - setMaxLength(20) ")
    add_label(t, 4, 18, "Name:", .5, .5, .5)
    name_input = lurek.terminal.newTextBox(10, 18, 24)
    name_input:setMaxLength(20)
    name_input:setOnChange(function(text)
        if status_lbl then status_lbl:setText("onChange: '" .. text .. "'") end
    end)
    t:addWidget(name_input)
    t:setFocus(name_input)

    local lx = math.min(40, cols - 20)
    local lw = cols - lx - 2
    local lh = rows - 10
    add_border(t, lx, 3, lw, lh + 2, "single", " List - setOnSelect ")
    inv_list = lurek.terminal.newList(lx + 1, 4, lw - 2, lh)
    local items = {
        "Healing Potion x3", "Iron Sword +1",   "Wooden Shield",
        "Lockpick x5",       "Torch x2",         "Magic Scroll",
        "Leather Armor",     "Gold Key",          "Rope (10m)",
        "Bomb x2",           "Map Fragment",      "Ancient Coin",
        "Elixir of Speed",   "Dragon Scale",      "Rune Stone",
    }
    for _, item in ipairs(items) do inv_list:addItem(item) end
    inv_list:setSelected(1)
    inv_list:setOnSelect(function(idx)
        if status_lbl and idx then
            status_lbl:setText("onSelect[" .. idx .. "]: " .. inv_list:getItem(idx))
        end
    end)
    t:addWidget(inv_list)

    add_border(t, 2, rows - 6, cols - 2, 4, "single", " Status / Events ")
    status_lbl = lurek.terminal.newLabel(4, rows - 5, "Focus: TextBox   [Tab]=switch   click buttons/list")
    status_lbl:setColor(.2, 1, .45)
    t:addWidget(status_lbl)

    add_label(t, 4, rows - 4,
        string.format("getWidgetCount: %d   getItemCount: %d   getMaxLength: %d",
            t:getWidgetCount() + 1, inv_list:getItemCount(), name_input:getMaxLength()),
        .35, .35, .7)

    nav_hint(t, cols, rows)
end

-- ─── scene 3: border styles, panel, widget state ─────────────────────────────

local function build_scene3(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 3/5: Border styles  Panel  setVisible  setEnabled  setTag ", 1, 0.9, 0.2)

    local styles = { "single", "double", "rounded", "heavy", "ascii" }
    local bw     = math.floor((cols - 4) / #styles)
    local x      = 3
    for _, sty in ipairs(styles) do
        local b = lurek.terminal.newBorder(x, 3, bw, 7)
        b:setStyle(sty)
        b:setTitle(" " .. sty .. " ")
        t:addWidget(b)
        t:print(x + 2, 5, "setStyle()")
        t:print(x + 2, 6, '"' .. sty .. '"')
        t:print(x + 2, 7, "getStyle:")
        t:print(x + 2, 8, '"' .. b:getStyle() .. '"')
        x = x + bw
    end

    add_label(t, 3, 11, "Panel - child positions are relative to panel origin:", .5, .5, .5)
    local pw  = math.min(52, cols - 4)
    local panel = lurek.terminal.newPanel(3, 12, pw, 11)
    local pb  = lurek.terminal.newBorder(1, 1, pw, 11)
    pb:setStyle("single")
    panel:addChild(pb)
    local cx  = math.floor((pw - 18) / 2)
    local ph  = lurek.terminal.newLabel(cx, 2, "=== PAUSE MENU ===")
    ph:setColor(1, .9, .2)
    panel:addChild(ph)
    local bx  = math.floor((pw - 14) / 2)
    local pr  = lurek.terminal.newButton(bx, 4, 14, 1, "[ Resume ]")
    pr:setOnClick(function() end)
    panel:addChild(pr)
    local po  = lurek.terminal.newButton(bx, 6, 14, 1, "[ Options ]")
    po:setOnClick(function() end)
    panel:addChild(po)
    local pq  = lurek.terminal.newButton(bx, 8, 14, 1, "[ Quit ]")
    pq:setColor(1, .3, .3)
    pq:setOnClick(function() end)
    panel:addChild(pq)
    local pc  = lurek.terminal.newLabel(2, 10, "getChildCount: " .. (panel:getChildCount() + 1))
    pc:setColor(.4, 1, .4)
    panel:addChild(pc)
    t:addWidget(panel)

    local rx = pw + 6
    if rx + 26 <= cols then
        add_border(t, rx, 12, cols - rx, 11, "single", " Widget State ")
        local v1 = lurek.terminal.newLabel(rx + 2, 14, "setVisible(true)  <- shown")
        v1:setVisible(true)
        t:addWidget(v1)
        local v2 = lurek.terminal.newLabel(rx + 2, 15, "setVisible(false) <- hidden")
        v2:setVisible(false)
        t:addWidget(v2)
        local en = lurek.terminal.newButton(rx + 2, 17, cols - rx - 4, 1, "setEnabled(true) <- works")
        en:setEnabled(true)
        en:setOnClick(function() end)
        t:addWidget(en)
        local di = lurek.terminal.newButton(rx + 2, 19, cols - rx - 4, 1, "setEnabled(false) <- blocked")
        di:setEnabled(false)
        t:addWidget(di)
        local tg = lurek.terminal.newLabel(rx + 2, 21, "")
        tg:setTag("menu.quit")
        add_label(t, rx + 2, 21, 'setTag("menu.quit"): ' .. tg:getTag(), .7, .7, 1)
    end

    nav_hint(t, cols, rows)
end

-- ─── scene 4: dev console ────────────────────────────────────────────────────

local function build_scene4(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 4/5: Scrollback  pushScrollback  ANSI  history  [Enter]=submit ", 1, 0.9, 0.2)

    lurek.terminal.applyTheme(t, "dracula")
    lurek.terminal.setScrollbackCap(t, 500)

    local out_h = rows - 9
    add_border(t, 2, 3, cols - 2, out_h, "single", " Output - Up/Down history ")

    for _, line in ipairs({
        "\27[32m[engine]\27[0m Lurek2D terminal demo started",
        "\27[33mWARN:\27[0m no save file - starting fresh",
        "\27[32m[engine]\27[0m assets loaded",
        "\27[36mINFO:\27[0m scene 4 active",
        "> help",
        "\27[32m[console]\27[0m Commands: help  clear  echo <text>  scrollbackLen  historyLen",
    }) do
        lurek.terminal.pushScrollback(t, line)
    end

    add_border(t, 2, rows - 5, cols - 2, 3, "single", " Command input - press Enter to submit ")
    cmd_input = lurek.terminal.newTextBox(4, rows - 4, cols - 9)
    cmd_input:setMaxLength(120)
    t:addWidget(cmd_input)
    t:setFocus(cmd_input)

    add_label(t, 4, rows - 2,
        string.format("scrollbackLen: %d   cmdHistoryLen: %d   cap: 500",
            lurek.terminal.scrollbackLen(t), lurek.terminal.cmdHistoryLen(t)),
        .3, .3, .3)

    nav_hint(t, cols, rows)
end

local function render_scrollback(cols, rows)
    if not term then return end
    local out_h  = rows - 9
    local recent = lurek.terminal.getScrollback(term, 0, out_h)
    local base   = 3 + out_h - 1
    local blank  = string.rep(" ", cols - 6)
    for i = 1, #recent do
        local row = base - (#recent - i)
        if row >= 4 then
            term:print(3, row, blank)
            lurek.terminal.printAnsi(term, 3, row, recent[i])
        end
    end
end

-- ─── scene 5: ANSI, themes, highlight, completion ────────────────────────────

local function build_scene5(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 5/5: applyTheme  printAnsi  stripAnsi  printHighlighted  completions ", 1, 0.9, 0.2)

    add_label(t, 3, 3, "applyTheme - built-in themes:", .5, .5, .5)
    local themes = { "dracula", "monokai", "nord", "solarized_dark", "solarized_light" }
    local tx = 3
    for i, th in ipairs(themes) do
        local lbl = lurek.terminal.newLabel(tx, 4, "[" .. i .. "] " .. th)
        t:addWidget(lbl)
        tx = tx + #th + 6
    end

    add_label(t, 3, 6, "printAnsi - ANSI escape codes:", .5, .5, .5)
    local samples = {
        "\27[31mERROR\27[0m: something went wrong at line 42",
        "\27[32mOK\27[0m:    map loaded (\27[36m42 rooms\27[0m, \27[33m7 exits\27[0m)",
        "\27[1;33mWARN\27[0m:  physics budget exceeded \27[1;31m16 ms\27[0m this frame",
        "\27[35mDEBUG\27[0m: lua GC freed \27[36m1.2 MB\27[0m in \27[33m0.3 ms\27[0m",
    }
    for i, line in ipairs(samples) do
        lurek.terminal.printAnsi(t, 3, 6 + i, line)
    end

    add_label(t, 3, 12, "stripAnsi:", .5, .5, .5)
    local stripped = lurek.terminal.stripAnsi("\27[1;32mOK\27[0m test \27[31mfailed\27[0m (3 errors)")
    t:print(3, 13, "stripped: " .. stripped)

    add_label(t, 3, 15, "printHighlighted - regex color rules:", .5, .5, .5)
    lurek.terminal.printHighlighted(t, 3, 16,
        'ERROR at line 42: WARN in "main.lua"  OK (0 errors)  count=100',
        {
            { pattern = "ERROR",  fg = { 255, 80,  80  } },
            { pattern = "WARN",   fg = { 255, 200, 50  } },
            { pattern = "OK",     fg = { 80,  255, 80  } },
            { pattern = "%d+",    fg = { 120, 200, 255 } },
            { pattern = "%b\"\"", fg = { 180, 255, 180 } },
        })

    add_label(t, 3, 18, "Completion engine:", .5, .5, .5)
    lurek.terminal.clearCompletions()
    for _, cmd in ipairs({ "spawn_enemy","spawn_item","spawn_npc","give_gold","give_xp","kill_all","noclip","god_mode" }) do
        lurek.terminal.addCompletion(cmd)
    end
    local hits = lurek.terminal.getCompletions("spawn")
    local tab1 = lurek.terminal.nextCompletion("give")
    local tab2 = lurek.terminal.nextCompletion("give")
    lurek.terminal.resetCompletion()
    t:print(3, 19, ("getCompletions('spawn'): " .. table.concat(hits, ", ")):sub(1, cols - 5))
    t:print(3, 20, "nextCompletion('give') x2: " .. tostring(tab1) .. " -> " .. tostring(tab2))

    lurek.terminal.pushCmdHistory(t, "spawn_enemy 10 20")
    lurek.terminal.pushCmdHistory(t, "give_gold 500")
    lurek.terminal.pushCmdHistory(t, "noclip on")
    add_label(t, 3, 22,
        string.format("cmdHistoryLen: %d   scrollbackLen: %d   prevCmd: %s",
            lurek.terminal.cmdHistoryLen(t),
            lurek.terminal.scrollbackLen(t),
            tostring(lurek.terminal.prevCmd(t))),
        .4, 1, .4)

    local mc, mr = lurek.terminal.getMaxCols(), lurek.terminal.getMaxRows()
    add_label(t, 3, 23, string.format("getMaxCols: %d   getMaxRows: %d", mc, mr), .4, 1, .4)

    nav_hint(t, cols, rows)
end

-- ─── scene builder ───────────────────────────────────────────────────────────

local builders = { build_scene1, build_scene2, build_scene3, build_scene4, build_scene5 }

local function build_current_scene()
    cmd_input  = nil
    inv_list   = nil
    name_input = nil
    status_lbl = nil

    local cols, rows = window_fit(16)
    term = lurek.terminal.newTerminal(cols, rows)
    term:setFont(16)
    builders[scene](term, cols, rows)
    term:autoResize()
end

-- ─── game loop ───────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.03, 0.03, 0.04)
    build_current_scene()
end

function lurek.resize(w, h)
    build_current_scene()
end

function lurek.draw()
    if not term then return end
    local cols, rows = term:getDimensions()

    if scene == 1 then
        local banner = "  TERMINAL  DEMO  "
        local bc     = math.max(1, math.floor((cols - #banner) / 2) + 1)
        for i = 1, #banner do
            local phase = (tick * 0.025 + (i - 1) / #banner) % 1
            local r2 = math.abs(math.sin(phase * math.pi))
            local g2 = math.abs(math.sin(phase * math.pi + 2.1))
            local b2 = math.abs(math.sin(phase * math.pi + 4.2))
            term:set(bc + i - 1, 3, banner:sub(i, i), r2, g2, b2, 1)
        end
    end

    if scene == 4 then
        render_scrollback(cols, rows)
    end

    term:render(0, 0)
end

function lurek.process(dt)
    tick = tick + 1
end

function lurek.keypressed(key)
    if not term then return end

    if key == "right" then
        scene = (scene % SCENE_COUNT) + 1
        build_current_scene()
        return
    elseif key == "left" then
        scene = ((scene - 2 + SCENE_COUNT) % SCENE_COUNT) + 1
        build_current_scene()
        return
    end
    local num = tonumber(key)
    if num and num >= 1 and num <= SCENE_COUNT then
        scene = num
        build_current_scene()
        return
    end

    if scene == 4 and key == "return" and cmd_input then
        local text = cmd_input:getText()
        if text ~= "" then
            lurek.terminal.pushScrollback(term, "> " .. text)
            lurek.terminal.pushCmdHistory(term, text)
            if text == "clear" then
                lurek.terminal.setScrollbackCap(term, 0)
                lurek.terminal.setScrollbackCap(term, 500)
            elseif text:sub(1, 5) == "echo " then
                lurek.terminal.pushScrollback(term, text:sub(6))
            elseif text == "help" then
                lurek.terminal.pushScrollback(term, "\27[32m[console]\27[0m Commands: help  clear  echo <text>  scrollbackLen  historyLen")
            elseif text == "scrollbackLen" then
                lurek.terminal.pushScrollback(term, tostring(lurek.terminal.scrollbackLen(term)))
            elseif text == "historyLen" then
                lurek.terminal.pushScrollback(term, tostring(lurek.terminal.cmdHistoryLen(term)))
            else
                lurek.terminal.pushScrollback(term, "\27[31mUnknown:\27[0m " .. text .. "  (type 'help')")
            end
            cmd_input:setText("")
        end
        return
    end

    if scene == 4 and cmd_input then
        if key == "up" then
            local prev = lurek.terminal.prevCmd(term)
            if prev then cmd_input:setText(prev) end
            return
        elseif key == "down" then
            local nxt = lurek.terminal.nextCmd(term)
            cmd_input:setText(nxt or "")
            return
        end
    end

    if scene == 2 and key == "tab" then
        local focused = term:getFocused()
        if focused == name_input then
            term:setFocus(inv_list)
            if status_lbl then status_lbl:setText("Focus: List - arrow keys select  [Tab]=back to textbox") end
        else
            term:setFocus(name_input)
            if status_lbl then status_lbl:setText("Focus: TextBox - type to filter  [Tab]=switch to list") end
        end
        return
    end

    term:keypressed(key)
end

function lurek.textinput(text)
    if term then term:textinput(text) end
end

function lurek.mousepressed(x, y, button)
    if term then term:mousepressed(x, y, button) end
end
