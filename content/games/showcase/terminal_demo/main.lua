-- content/games/showcase/terminal_demo/main.lua
-- Terminal API showcase: 5 navigable scenes covering all lurek.terminal widgets.
-- Auto-fills the window. Navigate: Left/Right arrows or 1-5.

local SCENE_COUNT = 5
local scene       = 1
local term        ---@type LTerminal
local tick        = 0

local cmd_input   ---@type LWidget?
local filter_input ---@type LWidget?
local inv_list    ---@type LWidget?
local name_input  ---@type LWidget?
local status_lbl  ---@type LWidget?

local process_selected = 1
local process_filter   = ""

local PROCESS_ROWS = {
    { pid = 40,    name = "chrome",      cpu = 29.0, mem = 79.0, user = "tom",   state = "R", uptime = "02:14:22" },
    { pid = 1,     name = "ffmpeg",      cpu = 14.0, mem = 2.3,  user = "media", state = "S", uptime = "00:48:10" },
    { pid = 1,     name = "isync",       cpu = 2.5,  mem = 2.5,  user = "mail",  state = "S", uptime = "05:01:33" },
    { pid = 3,     name = "Xorg",        cpu = 1.4,  mem = 0.8,  user = "root",  state = "S", uptime = "12:40:12" },
    { pid = 3,     name = "alacritty",   cpu = 1.4,  mem = 5.1,  user = "tom",   state = "R", uptime = "00:32:11" },
    { pid = 1,     name = "gotop",       cpu = 1.0,  mem = 0.1,  user = "tom",   state = "S", uptime = "00:07:18" },
    { pid = 1,     name = "nvim",        cpu = 0.9,  mem = 0.1,  user = "tom",   state = "S", uptime = "00:16:54" },
    { pid = 1,     name = "peek",        cpu = 0.5,  mem = 0.3,  user = "tom",   state = "S", uptime = "00:04:40" },
    { pid = 1,     name = "compton",     cpu = 0.5,  mem = 0.2,  user = "root",  state = "S", uptime = "07:17:25" },
    { pid = 759,   name = "TextInputMenu", cpu = 0.4, mem = 0.1, user = "tom",   state = "S", uptime = "00:11:08" },
}

local COL_BORDER = { 0.10, 0.76, 0.79 }
local COL_TITLE  = { 0.76, 0.82, 0.80 }
local COL_TEXT   = { 0.72, 0.77, 0.75 }
local COL_DIM    = { 0.38, 0.44, 0.44 }
local COL_PANEL  = { 0.01, 0.11, 0.14 }
local COL_GREEN  = { 0.48, 0.93, 0.36 }
local COL_YELLOW = { 0.92, 0.80, 0.15 }
local COL_RED    = { 0.97, 0.34, 0.33 }
local COL_BLUE   = { 0.24, 0.66, 1.00 }
local COL_CYAN   = { 0.35, 0.96, 0.92 }
local COL_PURPLE = { 0.85, 0.52, 0.95 }

-- scene 5 precomputed (stored in build, written to cells each frame in lurek.draw)
local s5_ansi = {
    "\27[31mERROR\27[0m: something went wrong at line 42",
    "\27[32mOK\27[0m:    map loaded (\27[36m42 rooms\27[0m, \27[33m7 exits\27[0m)",
    "\27[1;33mWARN\27[0m:  physics budget exceeded \27[1;31m16 ms\27[0m this frame",
    "\27[35mDEBUG\27[0m: lua GC freed \27[36m1.2 MB\27[0m in \27[33m0.3 ms\27[0m",
}
local s5_hl_text  = 'ERROR at line 42: WARN in "main.lua"  OK (0 errors)  count=100'
local s5_hl_rules = {
    { pattern = "ERROR",  fg = { 255, 80,  80  } },
    { pattern = "WARN",   fg = { 255, 200, 50  } },
    { pattern = "OK",     fg = { 80,  255, 80  } },
    { pattern = "%d+",    fg = { 120, 200, 255 } },
    { pattern = "%b\"\"", fg = { 180, 255, 180 } },
}
local s5_stripped  = ""
local s5_comp_text = ""
local s5_next_text = ""

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function add_border(t, c, r, w, h, style, title)
    local b = lurek.terminal.newBorder(c, r, w, h)
    b:setStyle(style or "single")
    if title then b:setTitle(title) end
    b:setColor(COL_BORDER[1], COL_BORDER[2], COL_BORDER[3])
    t:addWidget(b)
    return b
end

local function add_label(t, c, r, text, lr, lg, lb)
    local l = lurek.terminal.newLabel(c, r, text)
    if type(lr) == "table" then
        l:setColor(lr[1], lr[2], lr[3])
    elseif lr then
        l:setColor(lr, lg or 1, lb or 1)
    else
        l:setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3])
    end
    t:addWidget(l)
    return l
end

local function nav_hint(t, cols, rows)
    add_label(t, 3, rows - 1,
    string.format("  [<-][->] prev/next   [1-5] jump   scene %d/%d", scene, SCENE_COUNT),
        COL_DIM)
end

local function window_fit(cell_w, cell_h)
    local w, h   = lurek.window.getDimensions()
    local cols   = math.max(84, math.floor(w / cell_w))
    local rows   = math.max(32, math.floor(h / cell_h))
    return cols, rows
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function draw_text(t, c, r, text, fg, bg)
    for i = 1, #text do
        local ch = text:sub(i, i)
        if bg then
            t:set(c + i - 1, r, ch, fg[1], fg[2], fg[3], 1, bg[1], bg[2], bg[3], 1)
        else
            t:set(c + i - 1, r, ch, fg[1], fg[2], fg[3], 1)
        end
    end
end

local function clear_rect(t, c, r, w, h, bg)
    for y = r, r + h - 1 do
        for x = c, c + w - 1 do
            t:set(x, y, " ", COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1, bg[1], bg[2], bg[3], 1)
        end
    end
end

local function sample_wave(seed, i)
    local a = math.sin(tick * 0.050 + i * 0.230 + seed)
    local b = math.sin(tick * 0.028 + i * 0.110 + seed * 1.700)
    return clamp(0.50 + a * 0.28 + b * 0.18, 0.02, 0.98)
end

local function draw_plot(t, x, y, w, h, seed, color, ch)
    for i = 0, w - 1 do
        local v = sample_wave(seed, i)
        local py = y + math.floor((1 - v) * (h - 1) + 0.5)
        t:set(x + i, py, ch or ".", color[1], color[2], color[3], 1)
    end
end

local function draw_meter(t, x, y, w, label, frac, color)
    local pct = math.floor(frac * 100 + 0.5)
    local prefix = string.format("%-7s %3d%% ", label, pct)
    local bar_w = math.max(6, w - #prefix)
    draw_text(t, x, y, prefix, color)
    for i = 0, bar_w - 1 do
        local fill = i < math.floor(bar_w * frac + 0.5)
        local fg = fill and color or COL_DIM
        t:set(x + #prefix + i, y, fill and "#" or ".", fg[1], fg[2], fg[3], 1)
    end
end

local function scene1_layout(cols, rows)
    local left_w = math.max(28, math.floor((cols - 5) * 0.33))
    local right_w = cols - 3 - left_w
    local cpu_y = 3
    local cpu_h = 9
    local disk_y = cpu_y + cpu_h + 1
    local disk_h = 5
    local temp_y = disk_y + disk_h + 1
    local temp_h = 5
    local net_y = temp_y + temp_h + 1
    local net_h = rows - net_y - 2
    local mem_y = disk_y
    local mem_h = 6
    local proc_y = mem_y + mem_h + 1
    local proc_h = rows - proc_y - 2
    return {
        cpu  = { x = 2,         y = cpu_y,  w = cols - 2, h = cpu_h  },
        disk = { x = 2,         y = disk_y, w = left_w,   h = disk_h },
        temp = { x = 2,         y = temp_y, w = left_w,   h = temp_h },
        net  = { x = 2,         y = net_y,  w = left_w,   h = net_h  },
        mem  = { x = left_w+3,  y = mem_y,  w = right_w,  h = mem_h  },
        proc = { x = left_w+3,  y = proc_y, w = right_w,  h = proc_h },
    }
end

local function draw_scene1(t, cols, rows)
    local L = scene1_layout(cols, rows)
    clear_rect(t, L.cpu.x + 1,  L.cpu.y + 1,  L.cpu.w - 2,  L.cpu.h - 2,  COL_PANEL)
    clear_rect(t, L.disk.x + 1, L.disk.y + 1, L.disk.w - 2, L.disk.h - 2, COL_PANEL)
    clear_rect(t, L.temp.x + 1, L.temp.y + 1, L.temp.w - 2, L.temp.h - 2, COL_PANEL)
    clear_rect(t, L.net.x + 1,  L.net.y + 1,  L.net.w - 2,  L.net.h - 2,  COL_PANEL)
    clear_rect(t, L.mem.x + 1,  L.mem.y + 1,  L.mem.w - 2,  L.mem.h - 2,  COL_PANEL)
    clear_rect(t, L.proc.x + 1, L.proc.y + 1, L.proc.w - 2, L.proc.h - 2, COL_PANEL)

    local cpu_colors = { COL_BLUE, COL_CYAN, COL_YELLOW, COL_RED }
    local graph_x = L.cpu.x + 18
    local graph_y = L.cpu.y + 1
    local graph_w = L.cpu.w - 20
    local graph_h = L.cpu.h - 2
    for i = 1, 4 do
        local frac = sample_wave(i * 1.2, 0)
        draw_text(t, L.cpu.x + 2, L.cpu.y + i, string.format("CPU%d  %3d%%", i - 1, math.floor(frac * 100 + 0.5)), cpu_colors[i])
        draw_plot(t, graph_x, graph_y, graph_w, graph_h, i * 1.2, cpu_colors[i], ".")
    end

    draw_text(t, L.disk.x + 2, L.disk.y + 1, "Disk  Mount   Used   Free", COL_TITLE)
    draw_text(t, L.disk.x + 2, L.disk.y + 2, "sda1  /boot   15%   225MB", COL_TEXT)
    draw_text(t, L.disk.x + 2, L.disk.y + 3, "sda2  /       29%    81GB", COL_TEXT)

    draw_text(t, L.temp.x + 2, L.temp.y + 1, "acpitz                49C", COL_YELLOW)
    draw_text(t, L.temp.x + 2, L.temp.y + 2, "coretemp_core0        44C", COL_GREEN)
    draw_text(t, L.temp.x + 2, L.temp.y + 3, "coretemp_core1        44C", COL_GREEN)

    draw_meter(t, L.mem.x + 2, L.mem.y + 1, L.mem.w - 4, "Main", 0.57, COL_PURPLE)
    draw_meter(t, L.mem.x + 2, L.mem.y + 2, L.mem.w - 4, "Swap", 0.03, COL_YELLOW)
    draw_text(t, L.mem.x + 2, L.mem.y + 4, "available: 6.8 GiB   cached: 2.4 GiB", COL_DIM)

    local rx = 67.0 + sample_wave(9.0, 0) * 1.2
    local tx = 2.2 + sample_wave(11.0, 0) * 0.5
    draw_text(t, L.net.x + 2, L.net.y + 1, string.format("Total Rx: %4.1f MB", rx), COL_TEXT)
    draw_text(t, L.net.x + 2, L.net.y + 2, string.format("Total Tx: %4.1f MB", tx), COL_TEXT)
    draw_text(t, L.net.x + 2, L.net.y + 4, "Rx/s:", COL_DIM)
    draw_plot(t, L.net.x + 8, L.net.y + 4, L.net.w - 10, 2, 6.0, COL_BLUE, ".")
    draw_text(t, L.net.x + 2, L.net.y + 6, "Tx/s:", COL_DIM)
    draw_plot(t, L.net.x + 8, L.net.y + 6, L.net.w - 10, 2, 7.2, COL_CYAN, ".")

    draw_text(t, L.proc.x + 2, L.proc.y + 1, "Count  Command              CPU%   Mem%", COL_TITLE)
    local rows_to_show = math.min(#PROCESS_ROWS, L.proc.h - 3)
    for i = 1, rows_to_show do
        local p = PROCESS_ROWS[i]
        local fg = (i == 1) and COL_BLUE or COL_TEXT
        local bg = (i == 1) and { 0.05, 0.28, 0.46 } or COL_PANEL
        local line = string.format("%-6d %-18s %5.1f   %5.1f", p.pid, p.name, p.cpu, p.mem)
        line = line:sub(1, L.proc.w - 4)
        draw_text(t, L.proc.x + 2, L.proc.y + i + 1, line, fg, bg)
    end
end

-- ─── scene 1: raw cell drawing ───────────────────────────────────────────────

local function build_scene1(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 1/5: Overview Dashboard ", 1, 0.9, 0.2)

    local L = scene1_layout(cols, rows)
    add_border(t, L.cpu.x,  L.cpu.y,  L.cpu.w,  L.cpu.h,  "single", " CPU Usage ")
    add_border(t, L.disk.x, L.disk.y, L.disk.w, L.disk.h, "single", " Disk Usage ")
    add_border(t, L.temp.x, L.temp.y, L.temp.w, L.temp.h, "single", " Temperatures ")
    add_border(t, L.net.x,  L.net.y,  L.net.w,  L.net.h,  "single", " Network Usage ")
    add_border(t, L.mem.x,  L.mem.y,  L.mem.w,  L.mem.h,  "single", " Memory Usage ")
    add_border(t, L.proc.x, L.proc.y, L.proc.w, L.proc.h, "single", " Processes ")

    nav_hint(t, cols, rows)
end

-- ─── scene 2: buttons, textbox, list ─────────────────────────────────────────

local function build_scene2(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 2/5: Process View  Filter  Actions ", 1, 0.9, 0.2)

    local list_w = math.max(46, math.floor((cols - 5) * 0.58))
    local side_x = list_w + 3
    local side_w = cols - 3 - list_w
    local panel_h = rows - 9

    add_label(t, 3, 3, "Filter:", COL_DIM)
    filter_input = lurek.terminal.newTextBox(11, 3, math.min(28, cols - 20))
    filter_input:setMaxLength(24)
    filter_input:setOnChange(function(text)
        process_filter = string.lower(text or "")
        if process_filter ~= "" then
            for i, proc in ipairs(PROCESS_ROWS) do
                if string.find(string.lower(proc.name), process_filter, 1, true) then
                    process_selected = i
                    if inv_list then inv_list:setSelected(i) end
                    break
                end
            end
        end
        if status_lbl then
            if process_filter == "" then
                status_lbl:setText("Filter cleared  |  Up/Down or mouse to inspect")
            else
                status_lbl:setText("Filter: '" .. process_filter .. "'")
            end
        end
    end)
    t:addWidget(filter_input)

    add_border(t, 2, 5, list_w, panel_h, "single", " Processes ")
    inv_list = lurek.terminal.newList(3, 6, list_w - 2, panel_h - 2)
    for _, proc in ipairs(PROCESS_ROWS) do
        inv_list:addItem(string.format("%5d  %-16s  %5.1f%%  %5.1f%%", proc.pid, proc.name, proc.cpu, proc.mem))
    end
    inv_list:setSelected(process_selected)
    inv_list:setOnSelect(function(idx)
        process_selected = idx or 1
        if status_lbl then
            local proc = PROCESS_ROWS[process_selected]
            status_lbl:setText(string.format("Selected: %s   cpu %.1f%%   mem %.1f%%", proc.name, proc.cpu, proc.mem))
        end
    end)
    t:addWidget(inv_list)

    add_border(t, side_x, 5, side_w, panel_h, "single", " Details ")
    add_label(t, side_x + 2, 6, "Actions", COL_DIM)

    local b_normal = lurek.terminal.newButton(side_x + 2, 8, side_w - 4, 1, "Inspect")
    b_normal:setOnClick(function()
        if status_lbl then status_lbl:setText("Inspect signal sent to selected process") end
    end)
    t:addWidget(b_normal)

    local b_wide = lurek.terminal.newButton(side_x + 2, 10, side_w - 4, 1, "Suspend")
    b_wide:setOnClick(function()
        if status_lbl then status_lbl:setText("Suspend request queued") end
    end)
    t:addWidget(b_wide)

    local b_dis = lurek.terminal.newButton(side_x + 2, 12, side_w - 4, 1, "Terminate")
    b_dis:setOnClick(function()
        if status_lbl then status_lbl:setText("Terminate blocked in demo mode") end
    end)
    t:addWidget(b_dis)

    add_border(t, 2, rows - 5, cols - 2, 4, "single", " Status / Events ")
    status_lbl = lurek.terminal.newLabel(4, rows - 4, "Focus: filter box   [Tab] switch   click or arrows to inspect")
    status_lbl:setColor(.2, 1, .45)
    t:addWidget(status_lbl)

    add_label(t, 4, rows - 3,
        string.format("rows: %d   selected: %d   filter length: %d",
            inv_list:getItemCount(), process_selected, filter_input:getMaxLength()),
        .35, .35, .7)

    t:setFocus(filter_input)

    nav_hint(t, cols, rows)
end

-- ─── scene 3: border styles, panel, widget state ─────────────────────────────

local function build_scene3(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 3/5: Layout  Panels  Visibility  States ", 1, 0.9, 0.2)

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

    add_label(t, 3, 11, "Nested panel layout with child widgets and status controls:", .5, .5, .5)
    local pw  = math.min(52, cols - 4)
    local panel = lurek.terminal.newPanel(3, 12, pw, 11)
    local pb  = lurek.terminal.newBorder(1, 1, pw, 11)
    pb:setStyle("single")
    panel:addChild(pb)
    local cx  = math.floor((pw - 18) / 2)
    local ph  = lurek.terminal.newLabel(cx, 2, "=== SERVICE MENU ===")
    ph:setColor(1, .9, .2)
    panel:addChild(ph)
    local bx  = math.floor((pw - 14) / 2)
    local pr  = lurek.terminal.newButton(bx, 4, 14, 1, "Resume")
    pr:setOnClick(function() end)
    panel:addChild(pr)
    local po  = lurek.terminal.newButton(bx, 6, 14, 1, "Options")
    po:setOnClick(function() end)
    panel:addChild(po)
    local pq  = lurek.terminal.newButton(bx, 8, 14, 1, "Quit")
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
        local v1 = lurek.terminal.newLabel(rx + 2, 14, "Visible item")
        v1:setVisible(true)
        t:addWidget(v1)
        local v2 = lurek.terminal.newLabel(rx + 2, 15, "Hidden item")
        v2:setVisible(false)
        t:addWidget(v2)
        local en = lurek.terminal.newButton(rx + 2, 17, cols - rx - 4, 1, "Enabled action")
        en:setEnabled(true)
        en:setOnClick(function() end)
        t:addWidget(en)
        local di = lurek.terminal.newButton(rx + 2, 19, cols - rx - 4, 1, "Disabled action")
        di:setEnabled(false)
        t:addWidget(di)
        local tg = lurek.terminal.newLabel(rx + 2, 21, "")
        tg:setTag("menu.quit")
        add_label(t, rx + 2, 21, 'Tag: ' .. tg:getTag(), .7, .7, 1)
    end

    nav_hint(t, cols, rows)
end

-- ─── scene 4: dev console ────────────────────────────────────────────────────

local function build_scene4(t, cols, rows)
    add_border(t, 1, 1, cols, rows, "double")
    add_label(t, 3, 1, " Scene 4/5: Console  Scrollback  History  Enter=submit ", 1, 0.9, 0.2)

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
    local base   = 3 + out_h - 2   -- inner bottom row (row 3+out_h-1 is the border line)
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
    add_label(t, 3, 1, " Scene 5/5: Themes  ANSI  Highlight  Completion ", 1, 0.9, 0.2)

    add_label(t, 3, 3, "Built-in themes:", .5, .5, .5)
    local themes = { "dracula", "monokai", "nord", "solarized_dark", "solarized_light" }
    local tx = 3
    for i, th in ipairs(themes) do
        local lbl = lurek.terminal.newLabel(tx, 4, "[" .. i .. "] " .. th)
        t:addWidget(lbl)
        tx = tx + #th + 6
    end

    add_label(t, 3, 6, "ANSI samples:", .5, .5, .5)
    -- s5_ansi samples written each frame in lurek.draw()

    add_label(t, 3, 12, "ANSI stripped text:", .5, .5, .5)
    s5_stripped = lurek.terminal.stripAnsi("\27[1;32mOK\27[0m test \27[31mfailed\27[0m (3 errors)") or ""

    add_label(t, 3, 15, "Highlight rules:", .5, .5, .5)
    -- s5_hl_text / s5_hl_rules written each frame in lurek.draw()

    add_label(t, 3, 18, "Command completion:", .5, .5, .5)
    lurek.terminal.clearCompletions()
    for _, cmd in ipairs({ "spawn_enemy","spawn_item","spawn_npc","give_gold","give_xp","kill_all","noclip","god_mode" }) do
        lurek.terminal.addCompletion(cmd)
    end
    local hits = lurek.terminal.getCompletions("spawn")
    local tab1 = lurek.terminal.nextCompletion("give")
    local tab2 = lurek.terminal.nextCompletion("give")
    lurek.terminal.resetCompletion()
    s5_comp_text = ("getCompletions('spawn'): " .. table.concat(hits or {}, ", ")):sub(1, cols - 5)
    s5_next_text = "nextCompletion('give') x2: " .. tostring(tab1) .. " -> " .. tostring(tab2)

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
    filter_input = nil
    inv_list   = nil
    name_input = nil
    status_lbl = nil

    local cols, rows = window_fit(8, 14)
    term = lurek.terminal.newTerminal(cols, rows)
    term:setFont(14)
    builders[scene](term, cols, rows)
    term:autoResize()
end

-- ─── game loop ───────────────────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.0, 0.0, 0.0)
    build_current_scene()
end

function lurek.resize(w, h)
    build_current_scene()
end

function lurek.draw()
    if not term then return end
    local cols, rows = term:getDimensions()

    if scene == 1 then
        draw_scene1(term, cols, rows)
    end

    if scene == 2 then
        local list_w = math.max(46, math.floor((cols - 5) * 0.58))
        local side_x = list_w + 3
        local side_w = cols - 3 - list_w
        local detail_y = 15
        local detail_h = rows - detail_y - 6
        clear_rect(term, side_x + 2, detail_y, side_w - 4, detail_h, COL_PANEL)
        local proc = PROCESS_ROWS[process_selected] or PROCESS_ROWS[1]
        draw_text(term, side_x + 2, detail_y, "PID:   " .. tostring(proc.pid), COL_TITLE)
        draw_text(term, side_x + 2, detail_y + 1, "Name:  " .. proc.name, COL_TEXT)
        draw_text(term, side_x + 2, detail_y + 2, "User:  " .. proc.user, COL_TEXT)
        draw_text(term, side_x + 2, detail_y + 3, "State: " .. proc.state, COL_TEXT)
        draw_text(term, side_x + 2, detail_y + 4, "Uptime:" .. proc.uptime, COL_TEXT)
        draw_meter(term, side_x + 2, detail_y + 6, side_w - 4, "CPU", clamp(proc.cpu / 100, 0, 1), COL_GREEN)
        draw_meter(term, side_x + 2, detail_y + 7, side_w - 4, "MEM", clamp(proc.mem / 100, 0, 1), COL_BLUE)
        draw_text(term, side_x + 2, detail_y + 9, "Filter text:", COL_DIM)
        draw_text(term, side_x + 2, detail_y + 10, process_filter == "" and "(none)" or process_filter, COL_CYAN)
        draw_text(term, side_x + 2, detail_y + 12, "Cmd:", COL_DIM)
        draw_text(term, side_x + 2, detail_y + 13, "/usr/bin/" .. proc.name .. " --foreground", COL_TEXT)
    end

    if scene == 4 then
        render_scrollback(cols, rows)
    end

    if scene == 5 then
        for i, line in ipairs(s5_ansi) do
            lurek.terminal.printAnsi(term, 3, 6 + i, line)
        end
        term:print(3, 13, "stripped: " .. s5_stripped)
        lurek.terminal.printHighlighted(term, 3, 16, s5_hl_text, s5_hl_rules)
        term:print(3, 19, s5_comp_text)
        term:print(3, 20, s5_next_text)
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
        if focused == filter_input then
            term:setFocus(inv_list)
            if status_lbl then status_lbl:setText("Focus: process list  |  arrows move selection") end
        else
            term:setFocus(filter_input)
            if status_lbl then status_lbl:setText("Focus: filter box  |  type to jump to first match") end
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
