-- ============================================================================
-- Hacking Game — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/hacking_game/main.lua
-- Run with : cargo run -- content/games/showcase/hacking_game
-- ============================================================================
-- Terminal-based hacking game with CRT aesthetics. Type commands to scan
-- networks, connect to servers, crack passwords, and download classified
-- data before the trace timer runs out.
-- Controls: Type commands at the prompt, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local LINE_H     = 16
local MAX_LINES  = 32
local PROMPT     = "root@target:~$ "
local TRACE_TIME = 60

local STATE = { TITLE = 1, BOOT = 2, PLAYING = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

-- Colors
local COL_GREEN      = { 0.0, 1.0, 0.3 }
local COL_DIM_GREEN  = { 0.0, 0.6, 0.15 }
local COL_BRIGHT     = { 0.3, 1.0, 0.5 }
local COL_RED        = { 1.0, 0.2, 0.1 }
local COL_YELLOW     = { 1.0, 0.85, 0.2 }
local COL_CYAN       = { 0.2, 0.9, 1.0 }
local COL_WHITE      = { 1.0, 1.0, 1.0 }
local COL_BG         = { 0.0, 0.0, 0.0 }
local COL_SCANLINE   = { 0.0, 0.15, 0.05, 0.25 }

-- ---------------------------------------------------------------------------
-- Server / mission data
-- ---------------------------------------------------------------------------
local SERVERS = {
    { ip = "192.168.1.10", name = "MAILSRV",    difficulty = 1, password = "pass",
      files = {
          { name = "readme.txt",   content = "Welcome to the mail server. Default password is: pass" },
          { name = "inbox.dat",    content = "[CLASSIFIED] Project BLACKOUT launch codes attached.", downloadable = true, points = 100 },
          { name = "config.cfg",   content = "smtp_port=25\nmax_connections=50" },
      }},
    { ip = "10.0.0.55",   name = "PROXYNODE",   difficulty = 0, password = nil, is_proxy = true,
      files = {
          { name = "proxy.log",    content = "Proxy active. Routes all traffic through encrypted tunnel." },
          { name = "status.txt",   content = "ONLINE — 99.7% uptime" },
      }},
    { ip = "172.16.0.2",  name = "SECVAULT",    difficulty = 2, password = "x7k2",
      files = {
          { name = "hint.txt",     content = "The vault code starts with x, ends with 2, has 4 chars." },
          { name = "access.log",   content = "Last login: ADMIN from 10.0.0.55" },
          { name = "vault.dat",    content = "[TOP SECRET] Orbital defense grid schematics.", downloadable = true, points = 250 },
          { name = "personnel.db", content = "[CLASSIFIED] Agent roster — 47 field operatives.", downloadable = true, points = 150 },
      }},
    { ip = "10.10.10.1",  name = "DARKSRV",     difficulty = 3, password = "qz9m",
      files = {
          { name = "memo.txt",     content = "Password hint: q_9_ — fill the blanks with z and m." },
          { name = "payload.bin",  content = "[CRITICAL] Zero-day exploit payload.", downloadable = true, points = 400 },
          { name = "targets.lst",  content = "[CLASSIFIED] Priority target coordinates.", downloadable = true, points = 300 },
          { name = "keys.pem",     content = "RSA private key — do NOT distribute.", downloadable = true, points = 200 },
      }},
}

local MISSIONS = {
    { id = 1, desc = "Download inbox.dat from MAILSRV (192.168.1.10)",
      target_ip = "192.168.1.10", required_files = { "inbox.dat" }, bonus = 200 },
    { id = 2, desc = "Route through PROXYNODE, then download vault.dat from SECVAULT",
      target_ip = "172.16.0.2", required_files = { "vault.dat" }, needs_proxy = true, bonus = 400 },
    { id = 3, desc = "Download ALL classified files from DARKSRV before trace",
      target_ip = "10.10.10.1", required_files = { "payload.bin", "targets.lst", "keys.pem" }, bonus = 600 },
}

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local terminal_lines = {}
local input_buffer   = ""
local cursor_blink   = 0
local cursor_visible = true
local score          = 0
local current_mission = 1
local mission_complete_flags = {}
local downloaded_files = {}

-- Connection state
local connected_server = nil
local trace_timer      = 0
local trace_active     = false
local proxy_active     = false
local proxy_bonus      = 0
local cracked_servers  = {}

-- Boot sequence
local boot_lines = {
    "BIOS v3.7.1 ... OK",
    "Memory check: 65536K ... OK",
    "Loading kernel modules ...",
    "  [+] net_driver.ko",
    "  [+] crypto_engine.ko",
    "  [+] fs_stealth.ko",
    "Initializing network stack ... OK",
    "Mounting encrypted volume ... OK",
    "Starting rootkit services ...",
    "  [ACTIVE] port_scanner",
    "  [ACTIVE] packet_sniffer",
    "  [ACTIVE] password_cracker",
    "System ready.",
    "",
    "Type 'help' for available commands.",
}
local boot_index   = 0
local boot_timer   = 0
local boot_speed   = 0.06

-- Title screen (matrix rain)
local matrix_columns = {}
local MATRIX_CHARS = "01アイウエオカキクケコサシスセソタチツテト"

-- Visual effects
local flicker_timer = 0
local flicker_alpha = 1.0
local trace_bar_pulse = { value = 0 }

-- Particles & tweens
local ps_download = nil
local ps_trace    = nil
local camera      = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function add_line(text, color)
    terminal_lines[#terminal_lines + 1] = { text = text or "", color = color or COL_GREEN }
    if #terminal_lines > MAX_LINES then
        table.remove(terminal_lines, 1)
    end
end

local function add_lines(lines, color)
    for _, line in ipairs(lines) do
        add_line(line, color)
    end
end

local function find_server(ip)
    for _, srv in ipairs(SERVERS) do
        if srv.ip == ip then return srv end
    end
    return nil
end

local function find_file(srv, name)
    for _, f in ipairs(srv.files) do
        if f.name == name then return f end
    end
    return nil
end

local function file_downloaded(fname)
    for _, d in ipairs(downloaded_files) do
        if d == fname then return true end
    end
    return false
end

local function check_mission_complete()
    local m = MISSIONS[current_mission]
    if not m then return false end
    for _, req in ipairs(m.required_files) do
        if not file_downloaded(req) then return false end
    end
    return true
end

local function split_args(str)
    local parts = {}
    for word in str:gmatch("%S+") do
        parts[#parts + 1] = word
    end
    return parts
end

-- ---------------------------------------------------------------------------
-- Command handlers
-- ---------------------------------------------------------------------------
local function cmd_help()
    add_line("")
    add_line("═══ AVAILABLE COMMANDS ═══", COL_CYAN)
    add_line("  help              — show this help", COL_DIM_GREEN)
    add_line("  scan              — scan network for servers", COL_DIM_GREEN)
    add_line("  connect <ip>      — connect to a server", COL_DIM_GREEN)
    add_line("  ls                — list files on connected server", COL_DIM_GREEN)
    add_line("  cat <file>        — read a file", COL_DIM_GREEN)
    add_line("  crack <password>  — attempt password crack", COL_DIM_GREEN)
    add_line("  download <file>   — download classified data", COL_DIM_GREEN)
    add_line("  disconnect        — disconnect from server", COL_DIM_GREEN)
    add_line("  proxy <ip>        — route through proxy (+10s trace)", COL_DIM_GREEN)
    add_line("  mission           — show current mission", COL_DIM_GREEN)
    add_line("  score             — show current score", COL_DIM_GREEN)
    add_line("")
end

local function cmd_scan()
    add_line("")
    add_line("Scanning network ...", COL_YELLOW)
    add_line("")
    for _, srv in ipairs(SERVERS) do
        local status = "LOCKED"
        if srv.is_proxy then status = "PROXY"
        elseif cracked_servers[srv.ip] then status = "CRACKED" end
        add_line(string.format("  %-15s  %-12s  [%s]", srv.ip, srv.name, status), COL_GREEN)
    end
    add_line("")
end

local function cmd_connect(ip)
    if not ip then
        add_line("Usage: connect <ip>", COL_RED)
        return
    end
    if connected_server then
        add_line("Already connected. Disconnect first.", COL_RED)
        return
    end
    local srv = find_server(ip)
    if not srv then
        add_line("Host not found: " .. ip, COL_RED)
        return
    end
    if srv.password and not cracked_servers[srv.ip] then
        add_line("Access denied. Crack the password first.", COL_RED)
        return
    end
    connected_server = srv
    trace_active = true
    trace_timer = TRACE_TIME + proxy_bonus
    add_line("")
    add_line("Connected to " .. srv.name .. " (" .. srv.ip .. ")", COL_BRIGHT)
    add_line("TRACE INITIATED — " .. string.format("%.0f", trace_timer) .. "s remaining", COL_RED)
    add_line("")
end

local function cmd_ls()
    if not connected_server then
        add_line("Not connected to any server.", COL_RED)
        return
    end
    add_line("")
    add_line("Directory listing of " .. connected_server.name .. ":", COL_CYAN)
    for _, f in ipairs(connected_server.files) do
        local tag = ""
        if f.downloadable then tag = " [CLASSIFIED]" end
        if file_downloaded(f.name) then tag = tag .. " [DOWNLOADED]" end
        add_line("  " .. f.name .. tag, COL_GREEN)
    end
    add_line("")
end

local function cmd_cat(filename)
    if not connected_server then
        add_line("Not connected to any server.", COL_RED)
        return
    end
    if not filename then
        add_line("Usage: cat <filename>", COL_RED)
        return
    end
    local f = find_file(connected_server, filename)
    if not f then
        add_line("File not found: " .. filename, COL_RED)
        return
    end
    add_line("")
    add_line("─── " .. filename .. " ───", COL_CYAN)
    for line in f.content:gmatch("[^\n]+") do
        add_line("  " .. line, COL_DIM_GREEN)
    end
    add_line("")
end

local function cmd_crack(attempt)
    if not attempt then
        add_line("Usage: crack <password>", COL_RED)
        return
    end
    -- Find a lockable server that matches
    local cracked_any = false
    for _, srv in ipairs(SERVERS) do
        if srv.password and not cracked_servers[srv.ip] and srv.password == attempt then
            cracked_servers[srv.ip] = true
            cracked_any = true
            add_line("")
            add_line("PASSWORD ACCEPTED — " .. srv.name .. " unlocked!", COL_BRIGHT)
            score = score + 50
            add_line("  +50 points", COL_YELLOW)
            add_line("")
            break
        end
    end
    if not cracked_any then
        add_line("Invalid password. Access denied.", COL_RED)
    end
end

local function cmd_download(filename)
    if not connected_server then
        add_line("Not connected to any server.", COL_RED)
        return
    end
    if not filename then
        add_line("Usage: download <filename>", COL_RED)
        return
    end
    local f = find_file(connected_server, filename)
    if not f then
        add_line("File not found: " .. filename, COL_RED)
        return
    end
    if not f.downloadable then
        add_line("File is not downloadable.", COL_YELLOW)
        return
    end
    if file_downloaded(filename) then
        add_line("Already downloaded: " .. filename, COL_YELLOW)
        return
    end
    downloaded_files[#downloaded_files + 1] = filename
    score = score + f.points
    add_line("")
    add_line("DOWNLOADING " .. filename .. " ...", COL_BRIGHT)
    add_line("  +" .. f.points .. " points", COL_YELLOW)
    -- Emit download particles
    if ps_download then ps_download:emit(30) end
    -- Check mission
    if check_mission_complete() then
        local m = MISSIONS[current_mission]
        score = score + m.bonus
        -- Time bonus: 2 points per second remaining
        local time_bonus = math.floor(trace_timer * 2)
        score = score + time_bonus
        mission_complete_flags[current_mission] = true
        add_line("")
        add_line("═══ MISSION " .. current_mission .. " COMPLETE ═══", COL_CYAN)
        add_line("  Mission bonus: +" .. m.bonus, COL_YELLOW)
        add_line("  Time bonus:    +" .. time_bonus, COL_YELLOW)
        if current_mission < #MISSIONS then
            current_mission = current_mission + 1
            add_line("")
            add_line("NEW MISSION: " .. MISSIONS[current_mission].desc, COL_BRIGHT)
        else
            add_line("")
            add_line("ALL MISSIONS COMPLETE! Final score: " .. score, COL_CYAN)
        end
    end
    add_line("")
end

local function cmd_disconnect()
    if not connected_server then
        add_line("Not connected.", COL_YELLOW)
        return
    end
    add_line("Disconnected from " .. connected_server.name, COL_GREEN)
    connected_server = nil
    trace_active = false
    trace_timer = 0
end

local function cmd_proxy(ip)
    if not ip then
        add_line("Usage: proxy <ip>", COL_RED)
        return
    end
    local srv = find_server(ip)
    if not srv or not srv.is_proxy then
        add_line("Not a valid proxy: " .. ip, COL_RED)
        return
    end
    proxy_active = true
    proxy_bonus = 10
    add_line("")
    add_line("Proxy route established through " .. srv.name, COL_BRIGHT)
    add_line("  Trace timer extended by +10s on next connect", COL_YELLOW)
    add_line("")
end

local function cmd_mission()
    local m = MISSIONS[current_mission]
    if not m then
        add_line("All missions complete!", COL_CYAN)
        return
    end
    add_line("")
    add_line("MISSION " .. m.id .. ": " .. m.desc, COL_CYAN)
    if m.needs_proxy then
        add_line("  (Hint: use a proxy for extra trace time)", COL_YELLOW)
    end
    add_line("")
end

local function cmd_score()
    add_line("")
    add_line("Current score: " .. score, COL_YELLOW)
    add_line("Files downloaded: " .. #downloaded_files, COL_GREEN)
    add_line("")
end

local function execute_command(cmd_str)
    add_line(PROMPT .. cmd_str, COL_DIM_GREEN)
    local args = split_args(cmd_str)
    local cmd = args[1]
    if not cmd or cmd == "" then return end

    if     cmd == "help"       then cmd_help()
    elseif cmd == "scan"       then cmd_scan()
    elseif cmd == "connect"    then cmd_connect(args[2])
    elseif cmd == "ls"         then cmd_ls()
    elseif cmd == "cat"        then cmd_cat(args[2])
    elseif cmd == "crack"      then cmd_crack(args[2])
    elseif cmd == "download"   then cmd_download(args[2])
    elseif cmd == "disconnect" then cmd_disconnect()
    elseif cmd == "proxy"      then cmd_proxy(args[2])
    elseif cmd == "mission"    then cmd_mission()
    elseif cmd == "score"      then cmd_score()
    else
        add_line("Unknown command: " .. cmd, COL_RED)
        add_line("Type 'help' for available commands.", COL_DIM_GREEN)
    end
end

-- ---------------------------------------------------------------------------
-- Matrix rain (title screen)
-- ---------------------------------------------------------------------------
local function init_matrix()
    matrix_columns = {}
    local cols = math.floor(SCREEN_W / 12)
    for i = 1, cols do
        matrix_columns[i] = {
            x = (i - 1) * 12,
            y = math.random(0, SCREEN_H),
            speed = math.random(80, 200),
            chars = {},
            len = math.random(5, 20),
        }
        for j = 1, matrix_columns[i].len do
            local idx = math.random(1, #MATRIX_CHARS)
            matrix_columns[i].chars[j] = MATRIX_CHARS:sub(idx, idx)
        end
    end
end

local function update_matrix(dt)
    for _, col in ipairs(matrix_columns) do
        col.y = col.y + col.speed * dt
        if col.y > SCREEN_H + col.len * LINE_H then
            col.y = -col.len * LINE_H
            col.speed = math.random(80, 200)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Hacking Game — Lurek2D")
    lurek.render.setBackgroundColor(0, 0, 0)

    lurek.input.bind("quit", { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Download stream particles (green data bits)
    ps_download = lurek.particles.newSystem({
        maxParticles = 80, emissionRate = 0,
        lifetimeMin = 0.3, lifetimeMax = 0.8,
        speedMin = 40, speedMax = 120, direction = -1.57, spread = 1.0,
        gravityY = 30,
        sizes = { 3, 1 },
        colors = { 0, 1, 0.3, 1, 0, 0.5, 0.1, 0 },
    })

    -- Trace alert sparks (red warning)
    ps_trace = lurek.particles.newSystem({
        maxParticles = 60, emissionRate = 0,
        lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 60, speedMax = 180, direction = 0, spread = 6.28,
        sizes = { 4, 2, 0 },
        colors = { 1, 0.2, 0.1, 1, 0.8, 0.1, 0, 0 },
    })

    init_matrix()
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.signal.quit() end

    ps_download:update(dt)
    ps_trace:update(dt)
    lurek.tween.update(dt)

    -- Cursor blink
    cursor_blink = cursor_blink + dt
    if cursor_blink >= 0.5 then
        cursor_blink = cursor_blink - 0.5
        cursor_visible = not cursor_visible
    end

    -- CRT flicker
    flicker_timer = flicker_timer + dt
    if flicker_timer > 0.05 then
        flicker_timer = 0
        flicker_alpha = 0.95 + math.random() * 0.05
    end

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        update_matrix(dt)
        return
    end

    -- ── BOOT ──────────────────────────────────────────────────
    if current_state == STATE.BOOT then
        boot_timer = boot_timer + dt
        if boot_timer >= boot_speed and boot_index < #boot_lines then
            boot_timer = boot_timer - boot_speed
            boot_index = boot_index + 1
            add_line(boot_lines[boot_index], COL_GREEN)
        end
        if boot_index >= #boot_lines then
            current_state = STATE.PLAYING
            add_line("")
            cmd_mission()
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────
    if current_state == STATE.PLAYING then
        -- Trace countdown
        if trace_active then
            trace_timer = trace_timer - dt
            if trace_timer <= 0 then
                trace_timer = 0
                trace_active = false
                connected_server = nil
                add_line("")
                add_line("██ TRACE COMPLETE — CONNECTION TERMINATED ██", COL_RED)
                add_line("")
                current_state = STATE.GAME_OVER
                if ps_trace then ps_trace:emit(40) end
            end
            -- Pulse trace bar when low
            if trace_timer < 15 then
                trace_bar_pulse.value = 0.5 + 0.5 * math.sin(trace_timer * 6)
            else
                trace_bar_pulse.value = 0
            end
        end
        return
    end
end

-- ---------------------------------------------------------------------------
-- Text input — character-by-character typing
-- ---------------------------------------------------------------------------
function lurek.textinput(text)
    if current_state == STATE.PLAYING then
        input_buffer = input_buffer .. text
    end
end

function lurek.keypressed(key)
    -- Title screen: any key starts boot
    if current_state == STATE.TITLE then
        if key ~= "escape" then
            current_state = STATE.BOOT
            boot_index = 0
            boot_timer = 0
            terminal_lines = {}
        end
        return
    end

    -- Game over: R to restart
    if current_state == STATE.GAME_OVER then
        if key == "r" then
            -- Reset everything
            terminal_lines = {}
            input_buffer = ""
            score = 0
            current_mission = 1
            mission_complete_flags = {}
            downloaded_files = {}
            connected_server = nil
            trace_active = false
            trace_timer = 0
            proxy_active = false
            proxy_bonus = 0
            cracked_servers = {}
            current_state = STATE.BOOT
            boot_index = 0
            boot_timer = 0
        end
        return
    end

    -- Playing: handle command input
    if current_state == STATE.PLAYING then
        if key == "return" or key == "kpenter" then
            execute_command(input_buffer)
            input_buffer = ""
        elseif key == "backspace" then
            if #input_buffer > 0 then
                input_buffer = input_buffer:sub(1, -2)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render — CRT effects, scanlines, matrix rain (world-space)
-- ---------------------------------------------------------------------------
function lurek.render()
    camera:attach()

    -- CRT scanlines
    lurek.render.setColor(COL_SCANLINE[1], COL_SCANLINE[2], COL_SCANLINE[3], COL_SCANLINE[4])
    for y = 0, SCREEN_H, 3 do
        lurek.render.drawLine(0, y, SCREEN_W, y)
    end

    -- Title state: matrix rain
    if current_state == STATE.TITLE then
        for _, col in ipairs(matrix_columns) do
            for j, ch in ipairs(col.chars) do
                local cy = col.y + (j - 1) * LINE_H
                if cy >= 0 and cy < SCREEN_H then
                    local brightness = 1.0 - (j / col.len) * 0.8
                    lurek.render.setColor(0, brightness, brightness * 0.3, 0.8)
                    lurek.render.drawText(ch, col.x, cy)
                end
            end
        end
    end

    -- Particles (world space)
    lurek.render.setColor(1, 1, 1, 1)
    ps_download:draw()
    ps_trace:draw()

    -- Slight CRT flicker overlay
    lurek.render.setColor(0, 0.02, 0, (1.0 - flicker_alpha) * 0.3)
    lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H)

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI — terminal text, HUD, trace bar
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    local fps = lurek.time.getFPS()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(COL_GREEN[1], COL_GREEN[2], COL_GREEN[3], 1)
        lurek.render.drawText("H A C K I N G   G A M E", SCREEN_W / 2 - 110, SCREEN_H / 2 - 60)
        lurek.render.setColor(COL_DIM_GREEN[1], COL_DIM_GREEN[2], COL_DIM_GREEN[3], 1)
        lurek.render.drawText("[ Press any key to begin ]", SCREEN_W / 2 - 115, SCREEN_H / 2 + 10)
        lurek.render.drawText("Lurek2D Showcase", SCREEN_W / 2 - 65, SCREEN_H / 2 + 50)
        lurek.render.setColor(COL_DIM_GREEN[1], COL_DIM_GREEN[2], COL_DIM_GREEN[3], 0.5)
        lurek.render.drawText(string.format("FPS: %d", fps), SCREEN_W - 80, SCREEN_H - 20)
        return
    end

    -- ── TERMINAL OUTPUT ───────────────────────────────────────
    local start_y = 10
    for i, line in ipairs(terminal_lines) do
        local c = line.color or COL_GREEN
        lurek.render.setColor(c[1], c[2], c[3], flicker_alpha)
        lurek.render.drawText(line.text, 10, start_y + (i - 1) * LINE_H)
    end

    -- ── INPUT LINE ────────────────────────────────────────────
    if current_state == STATE.PLAYING then
        local input_y = start_y + #terminal_lines * LINE_H + 4
        lurek.render.setColor(COL_GREEN[1], COL_GREEN[2], COL_GREEN[3], 1)
        local display = PROMPT .. input_buffer
        if cursor_visible then display = display .. "█" end
        lurek.render.drawText(display, 10, input_y)
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        local gy = start_y + #terminal_lines * LINE_H + 30
        lurek.render.setColor(COL_RED[1], COL_RED[2], COL_RED[3], 1)
        lurek.render.drawText("██ TRACED — GAME OVER ██", SCREEN_W / 2 - 105, gy)
        lurek.render.setColor(COL_YELLOW[1], COL_YELLOW[2], COL_YELLOW[3], 1)
        lurek.render.drawText("Final score: " .. score, SCREEN_W / 2 - 55, gy + 25)
        lurek.render.drawText("Files: " .. #downloaded_files, SCREEN_W / 2 - 35, gy + 45)
        lurek.render.setColor(COL_DIM_GREEN[1], COL_DIM_GREEN[2], COL_DIM_GREEN[3], 1)
        lurek.render.drawText("[ Press R to restart ]", SCREEN_W / 2 - 90, gy + 75)
    end

    -- ── HUD: Trace bar ────────────────────────────────────────
    if trace_active and current_state == STATE.PLAYING then
        local bar_x, bar_y, bar_w, bar_h = SCREEN_W - 220, 10, 200, 14
        local pct = trace_timer / (TRACE_TIME + proxy_bonus)

        -- Background
        lurek.render.setColor(0.15, 0.15, 0.15, 0.8)
        lurek.render.drawRect(bar_x, bar_y, bar_w, bar_h)

        -- Fill (red when low, yellow when mid, green when high)
        local r, g
        if pct > 0.5 then r, g = 0, 1
        elseif pct > 0.25 then r, g = 1, 0.85
        else r, g = 1, 0.1 end

        local pulse = trace_bar_pulse.value
        lurek.render.setColor(r + pulse * 0.3, g * (1 - pulse * 0.3), 0, 0.9)
        lurek.render.drawRect(bar_x, bar_y, bar_w * pct, bar_h)

        -- Border
        lurek.render.setColor(COL_GREEN[1], COL_GREEN[2], COL_GREEN[3], 0.6)
        lurek.render.drawRect(bar_x, bar_y, bar_w, 1)
        lurek.render.drawRect(bar_x, bar_y + bar_h, bar_w, 1)
        lurek.render.drawRect(bar_x, bar_y, 1, bar_h)
        lurek.render.drawRect(bar_x + bar_w, bar_y, 1, bar_h)

        -- Label
        lurek.render.setColor(COL_WHITE[1], COL_WHITE[2], COL_WHITE[3], 1)
        lurek.render.drawText(string.format("TRACE: %.0fs", trace_timer), bar_x, bar_y + bar_h + 3)
    end

    -- ── HUD: Mission / Score / FPS ────────────────────────────
    lurek.render.setColor(COL_DIM_GREEN[1], COL_DIM_GREEN[2], COL_DIM_GREEN[3], 0.7)
    lurek.render.drawText(string.format("Score: %d", score), 10, SCREEN_H - 20)
    if MISSIONS[current_mission] then
        lurek.render.drawText("Mission " .. current_mission .. "/" .. #MISSIONS, 150, SCREEN_H - 20)
    else
        lurek.render.drawText("ALL MISSIONS COMPLETE", 150, SCREEN_H - 20)
    end
    if proxy_active then
        lurek.render.setColor(COL_CYAN[1], COL_CYAN[2], COL_CYAN[3], 0.7)
        lurek.render.drawText("[PROXY]", 370, SCREEN_H - 20)
    end
    lurek.render.setColor(COL_DIM_GREEN[1], COL_DIM_GREEN[2], COL_DIM_GREEN[3], 0.5)
    lurek.render.drawText(string.format("FPS: %d", fps), SCREEN_W - 80, SCREEN_H - 20)
end
