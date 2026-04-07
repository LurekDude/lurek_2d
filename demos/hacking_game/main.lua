-- Hacking Game — Luna2D Demo
-- Terminal-based hacking: crack passwords, explore filesystems, download targets

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local LINE_H = 16
local MAX_LINES = 32
local PROMPT = "> "

local lines, input_buf, cursor_blink
local servers, current_server, logged_in
local trace_timer, trace_max, proxies
local score, game_over, game_won
local crack_active, crack_words, crack_scroll, crack_target, crack_timer

local function make_fs(files)
    -- Build an in-memory directory tree from a flat {path -> content} table
    -- Enables ls / cd / cat commands without any real filesystem access
    local fs = {["/"] = {}}
    for path, content in pairs(files) do
        local dir, name = path:match("^(.*)/([^/]+)$")
        if not dir or dir == "" then dir = "/" end
        if not fs[dir] then fs[dir] = {} end
        fs[dir][name] = content
    end
    return fs
end

local function add_line(text)
    lines[#lines+1] = text
    if #lines > 200 then table.remove(lines, 1) end
end

local function add_lines(text)
    for line in text:gmatch("[^\n]+") do add_line(line) end
end

local function init_servers()
    servers = {
        {name="corp-gateway", ip="10.0.1.5", password="OVERRIDE", cwd="/",
         fs=make_fs({
             ["/readme.txt"]="Welcome to CorpNet gateway.\nSSH to 10.0.2.8 for research data.",
             ["/logs/access.log"]="2026-01-15 admin login\n2026-02-03 maintenance",
             ["/etc/shadow"]="admin:$6$x9Kz...(hashed)",
             ["/target.dat"]="CLASSIFIED: Project coordinates uploaded to research server.",
         })},
        {name="research-db", ip="10.0.2.8", password="NUCLEUS", cwd="/",
         fs=make_fs({
             ["/data/experiment.csv"]="Trial,Result\n1,Stable\n2,Unstable\n3,Critical",
             ["/data/notes.txt"]="The final key is on the mainframe at 10.0.3.1",
             ["/backup/creds.txt"]="mainframe user: root\nhint: the password is an element",
             ["/target.dat"]="RESEARCH DATA: Genome sequences extracted.",
         })},
        {name="mainframe", ip="10.0.3.1", password="PLUTONIUM", cwd="/",
         fs=make_fs({
             ["/secret/plans.txt"]="Operation complete. All data secured.",
             ["/secret/key.enc"]="DECRYPTED: ALPHA-OMEGA-7749",
             ["/target.dat"]="MAINFRAME BREACHED: Mission accomplished.",
         })},
    }
end

function luna.load()
    lines = {}
    input_buf = ""
    cursor_blink = 0
    game_over = false
    game_won = false
    score = 0
    trace_timer = 120
    trace_max = 120
    proxies = 0
    logged_in = false
    current_server = 0
    crack_active = false
    init_servers()
    add_lines("=== HACKTERM v2.1 ===")
    add_lines("Your mission: breach 3 servers and download target files.")
    add_lines("Commands: ls, cd <dir>, cat <file>, ssh <ip>, crack, decrypt, proxy, help")
    add_lines("Type 'ssh 10.0.1.5' to begin.")
    add_line("")
end

local function get_server()
    if current_server >= 1 and current_server <= #servers then return servers[current_server] end
    return nil
end

local function exec_command(cmd)
    local parts = {}
    for w in cmd:gmatch("%S+") do parts[#parts+1] = w end
    if #parts == 0 then return end
    local c = parts[1]
    local srv = get_server()

    if c == "help" then
        add_lines("ls — list files | cd <dir> — change directory | cat <file> — read file")
        add_lines("ssh <ip> — connect | crack — crack password | decrypt — decode files")
        add_lines("proxy — add proxy (+15s trace) | download — grab target.dat")
    elseif c == "proxy" then
        proxies = proxies + 1
        trace_timer = trace_timer + 15
        trace_max = trace_max + 15
        add_line("[+] Proxy #" .. proxies .. " connected. Trace slowed.")
    elseif c == "ssh" then
        local ip = parts[2]
        if not ip then add_line("Usage: ssh <ip>"); return end
        local found = false
        for i, s in ipairs(servers) do
            if s.ip == ip then
                current_server = i; logged_in = false; found = true
                add_line("Connecting to " .. s.name .. " (" .. ip .. ")...")
                add_line("Password required. Type 'crack' to break in.")
                break
            end
        end
        if not found then add_line("Connection refused: " .. ip) end
    elseif c == "crack" then
        if not srv then add_line("Not connected."); return end
        if logged_in then add_line("Already logged in."); return end
        crack_active = true
        crack_scroll = 0
        crack_timer = 8
        crack_target = srv.password
        crack_words = {}
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        for i = 1, 40 do
            local w = ""
            for j = 1, #crack_target do
                local ci = math.random(1, #chars)
                w = w .. chars:sub(ci, ci)
            end
            crack_words[i] = w
        end
        crack_words[math.random(1, 40)] = crack_target
        -- Show only the first two characters of the hint so the player must scan the grid
        add_line("[CRACK] Find: " .. crack_target:sub(1,2) .. string.rep("?", #crack_target - 2))
        add_line("[CRACK] Click the matching word in the hex dump!")
    elseif not srv or not logged_in then
        add_line("Not connected to a server. Use 'ssh <ip>'.")
    elseif c == "ls" then
        local dir = srv.cwd
        if srv.fs[dir] then
            for name, _ in pairs(srv.fs[dir]) do add_line("  " .. name) end
        else add_line("Empty directory.") end
    elseif c == "cd" then
        local d = parts[2]
        if not d then add_line("Usage: cd <dir>"); return end
        if d == ".." then srv.cwd = "/"; return end
        local path = srv.cwd == "/" and ("/" .. d) or (srv.cwd .. "/" .. d)
        if srv.fs[path] then srv.cwd = path; add_line(path)
        else add_line("No such directory: " .. d) end
    elseif c == "cat" then
        local f = parts[2]
        if not f then add_line("Usage: cat <file>"); return end
        local dir = srv.cwd
        if srv.fs[dir] and srv.fs[dir][f] then add_lines(srv.fs[dir][f])
        else add_line("File not found: " .. f) end
    elseif c == "download" then
        if srv.fs["/"] and srv.fs["/"]["target.dat"] then
            add_line("[+] Downloaded target.dat from " .. srv.name)
            srv.downloaded = true
            score = score + math.floor(trace_timer)
            local all_done = true
            for _, s in ipairs(servers) do if not s.downloaded then all_done = false end end
            if all_done then game_won = true end
        else add_line("No target.dat in root.") end
    else
        add_line("Unknown command: " .. c)
    end
end

function luna.update(dt)
    cursor_blink = cursor_blink + dt
    if game_over or game_won then return end

    if current_server > 0 then
        trace_timer = trace_timer - dt
        if trace_timer <= 0 then game_over = true; add_line("[!] TRACED. Connection terminated.") end
    end

    if crack_active then
        crack_scroll = crack_scroll + dt * 6
        crack_timer = crack_timer - dt
        if crack_timer <= 0 then
            crack_active = false
            add_line("[CRACK] Time expired! Password not cracked.")
        end
    end
end

function luna.keypressed(key)
    if game_over or game_won then
        if key == "r" then luna.load() end
        if key == "escape" then luna.event.quit() end
        return
    end
    if crack_active then return end

    if key == "return" then
        add_line(PROMPT .. input_buf)
        exec_command(input_buf)
        input_buf = ""
    elseif key == "backspace" then
        if #input_buf > 0 then input_buf = input_buf:sub(1, -2) end
    elseif key == "escape" then
        luna.event.quit()
    elseif #key == 1 then
        input_buf = input_buf .. key
    elseif key == "space" then
        input_buf = input_buf .. " "
    end
end

function luna.mousepressed(mx, my, btn)
    if not crack_active or btn ~= 1 then return end
    local start_y = 100
    local idx = math.floor((my - start_y) / LINE_H) + math.floor(crack_scroll)
    if idx >= 1 and idx <= #crack_words then
        if crack_words[idx] == crack_target then
            crack_active = false
            logged_in = true
            add_line("[+] Password cracked! Logged into " .. get_server().name)
            add_line("Type 'ls' to look around, 'download' to grab target.dat")
        else
            add_line("[CRACK] Wrong! Try again.")
            trace_timer = trace_timer - 3
        end
    end
end

function luna.draw()
    luna.graphics.setBackgroundColor(0, 0.02, 0)

    if crack_active then
        luna.graphics.setColor(0,0.15,0,1)
        luna.graphics.rectangle("fill", 0, 0, 800, 600)
        luna.graphics.setColor(0,1,0,1)
        luna.graphics.print("=== PASSWORD CRACK ===  Time: " .. math.floor(crack_timer), 20, 20, 1.2)
        luna.graphics.print("Find: " .. crack_target, 20, 50, 1)
        local start_y = 100
        local vis = math.floor((500) / LINE_H)
        local offset = math.floor(crack_scroll) % #crack_words
        for i = 0, vis do
            local idx = ((offset + i - 1) % #crack_words) + 1
            local hex = string.format("%04X", idx * 0x1A3F)
            local w = crack_words[idx]
            local y = start_y + i * LINE_H
            if w == crack_target then
                luna.graphics.setColor(0,1,0.5,1)
            else
                luna.graphics.setColor(0,0.7,0,0.8)
            end
            luna.graphics.print(hex .. "  " .. w, 60, y, 1)
        end
        return
    end

    -- terminal output
    local start = clamp(#lines - MAX_LINES + 1, 1, #lines)
    for i = start, #lines do
        local y = (i - start) * LINE_H + 10
        luna.graphics.setColor(0, 1, 0, 1)
        luna.graphics.print(lines[i], 10, y, 0.9)
    end

    -- input line
    local iy = clamp(#lines - start + 1, 0, MAX_LINES) * LINE_H + 10
    luna.graphics.setColor(0, 1, 0, 1)
    local caret = ""
    if math.floor(cursor_blink * 2) % 2 == 0 then caret = "_" end
    luna.graphics.print(PROMPT .. input_buf .. caret, 10, iy, 0.9)

    -- trace bar
    if current_server > 0 then
        local pct = clamp(trace_timer / trace_max, 0, 1)
        luna.graphics.setColor(0.2, 0.2, 0.2, 1)
        luna.graphics.rectangle("fill", 600, 5, 190, 12)
        luna.graphics.setColor(1 - pct, pct, 0, 1)
        luna.graphics.rectangle("fill", 600, 5, 190 * pct, 12)
        luna.graphics.setColor(0,1,0,0.7)
        luna.graphics.print("TRACE: " .. math.floor(trace_timer) .. "s", 605, 3, 0.7)
    end

    if game_over then
        luna.graphics.setColor(1,0,0,1)
        luna.graphics.print("CONNECTION TRACED — GAME OVER", 200, 280, 1.3)
        luna.graphics.print("Score: " .. score .. "  [R]estart  [ESC]Quit", 240, 320, 1)
    end
    if game_won then
        luna.graphics.setColor(0,1,0.5,1)
        luna.graphics.print("ALL TARGETS DOWNLOADED — MISSION COMPLETE", 140, 280, 1.2)
        luna.graphics.print("Score: " .. score .. "  [R]estart  [ESC]Quit", 240, 320, 1)
    end
end
