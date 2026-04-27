-- ============================================================================
-- Debug Bridge Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/debugbridge_demo/main.lua
-- Run with : cargo run -- content/games/showcase/debugbridge_demo
-- ============================================================================
-- Simulated debug bridge visualization demonstrating runtime inspection,
-- console commands, entity inspection, frame time graph, memory display,
-- log filtering, and breakpoint freeze mode.
-- Controls: 1-5 inspect entity, D/I/W/E log level, B breakpoint, Esc quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600
local STATE = { TITLE = 1, RUNNING = 2, PAUSED = 3 }
local current_state = STATE.TITLE

-- Layout
local PANEL_LEFT_W  = 380
local PANEL_RIGHT_W = SCREEN_W - PANEL_LEFT_W - 30
local PANEL_X_LEFT  = 10
local PANEL_X_RIGHT = PANEL_LEFT_W + 20
local PANEL_TOP     = 50

-- Frame graph
local GRAPH_FRAMES   = 120
local GRAPH_H        = 80
local GRAPH_W        = PANEL_RIGHT_W - 20

-- Log levels
local LOG_DEBUG = 1
local LOG_INFO  = 2
local LOG_WARN  = 3
local LOG_ERROR = 4
local LOG_NAMES = { "DEBUG", "INFO", "WARN", "ERROR" }
local LOG_COLORS = {
    [LOG_DEBUG] = { 0.5, 0.5, 0.7 },
    [LOG_INFO]  = { 0.4, 0.8, 0.4 },
    [LOG_WARN]  = { 0.9, 0.8, 0.2 },
    [LOG_ERROR] = { 1.0, 0.3, 0.3 },
}

-- Colors
local COL_BG         = { 0.05, 0.05, 0.08 }
local COL_PANEL      = { 0.08, 0.08, 0.12 }
local COL_PANEL_HEAD = { 0.12, 0.12, 0.18 }
local COL_ACCENT     = { 0.2, 0.7, 1.0 }
local COL_TEXT       = { 0.8, 0.85, 0.9 }
local COL_DIM        = { 0.4, 0.45, 0.5 }
local COL_GRAPH_LINE = { 0.3, 0.9, 0.4 }
local COL_GRAPH_HIGH = { 1.0, 0.3, 0.2 }
local COL_MEM_BAR    = { 0.3, 0.6, 1.0 }
local COL_MEM_USED   = { 0.9, 0.5, 0.2 }
local COL_BREAKPOINT = { 1.0, 0.2, 0.2 }
local COL_TITLE_GLOW = { 0.1, 0.6, 1.0 }

-- ---------------------------------------------------------------------------
-- Simulated entities
-- ---------------------------------------------------------------------------
local entities = {
    { id = 1, name = "Player",   etype = "Actor",   x = 120, y = 300, hp = 85, components = { "Transform", "Sprite", "Physics", "Input", "Health" } },
    { id = 2, name = "Enemy_01", etype = "NPC",     x = 450, y = 280, hp = 60, components = { "Transform", "Sprite", "Physics", "AI", "Health" } },
    { id = 3, name = "Chest_A",  etype = "Pickup",  x = 600, y = 400, hp = -1, components = { "Transform", "Sprite", "Interact", "Inventory" } },
    { id = 4, name = "Camera",   etype = "System",  x = 400, y = 300, hp = -1, components = { "Transform", "Camera", "Shake" } },
    { id = 5, name = "Light_01", etype = "Effect",  x = 320, y = 180, hp = -1, components = { "Transform", "Light", "Flicker" } },
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local frame_times     = {}
local log_entries     = {}
local console_lines   = {}
local selected_entity = 0
local log_filter      = LOG_DEBUG
local sim_time        = 0
local sim_memory_used = 42.5
local sim_memory_max  = 128.0
local console_input   = ""
local title_timer     = 0

-- Graph tween
local graph_scroll = { offset = 0 }

-- Particle systems
---@type ParticleSystem|nil
local ps_log_pulse  = nil
---@type ParticleSystem|nil
local ps_breakpoint = nil

-- Tween highlight
local entity_highlight = { alpha = 0 }

-- Camera
---@type LCamera
local camera = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function fmt_time()
    local t = math.floor(sim_time)
    local h = math.floor(t / 3600)
    local m = math.floor((t % 3600) / 60)
    local s = t % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function add_log(level, msg)
    log_entries[#log_entries + 1] = {
        level = level,
        text  = msg,
        time  = fmt_time(),
    }
    -- Cap at 200 entries
    if #log_entries > 200 then
        table.remove(log_entries, 1)
    end
end

local function add_console(text, is_response)
    console_lines[#console_lines + 1] = { text = text, response = is_response or false }
    if #console_lines > 80 then
        table.remove(console_lines, 1)
    end
end

local function process_command(cmd)
    cmd = cmd:lower()
    add_console("> " .. cmd, false)

    if cmd == "help" then
        add_console("Commands: status, fps, memory, entities, help", true)
        add_console("Keys: 1-5 inspect, D/I/W/E filter, B pause", true)
    elseif cmd == "status" then
        add_console("Engine: RUNNING | Uptime: " .. fmt_time(), true)
        add_console("Entities: " .. #entities .. " | Draw calls: " .. math.random(40, 80), true)
        add_console("Log level: " .. LOG_NAMES[log_filter], true)
    elseif cmd == "fps" then
        local avg = 0
        local count = math.min(#frame_times, 60)
        for i = #frame_times - count + 1, #frame_times do
            avg = avg + (frame_times[i] or 16.67)
        end
        if count > 0 then avg = avg / count end
        add_console(string.format("FPS: %.1f (avg %.2fms)", 1000 / math.max(avg, 0.001), avg), true)
    elseif cmd == "memory" then
        add_console(string.format("Heap: %.1f / %.1f MB (%.0f%%)", sim_memory_used, sim_memory_max, sim_memory_used / sim_memory_max * 100), true)
    elseif cmd == "entities" then
        for i = 1, #entities do
            local e = entities[i]
            local hp_str = e.hp >= 0 and (" HP:" .. e.hp) or ""
            add_console(string.format("  [%d] %s (%s)%s", e.id, e.name, e.etype, hp_str), true)
        end
    else
        add_console("Unknown command: " .. cmd .. "  (type 'help')", true)
    end
end

local function generate_log_message()
    local msgs = {
        { LOG_DEBUG, "Tick #" .. math.floor(sim_time * 60) .. " processed" },
        { LOG_DEBUG, "Physics step: " .. string.format("%.2fms", math.random() * 2 + 0.5) },
        { LOG_INFO,  "Entity spawned at (" .. math.random(0, 800) .. ", " .. math.random(0, 600) .. ")" },
        { LOG_INFO,  "Asset loaded: sprite_sheet_0" .. math.random(1, 9) .. ".png" },
        { LOG_WARN,  "Draw call batch exceeded 64 — flushing" },
        { LOG_WARN,  "Audio buffer underrun on bus 'sfx'" },
        { LOG_ERROR, "Texture slot " .. math.random(100, 999) .. " freed twice" },
        { LOG_ERROR, "Lua callback 'on_hit' returned nil (expected table)" },
        { LOG_DEBUG, "GC sweep: " .. math.random(10, 50) .. " objects collected" },
        { LOG_INFO,  "Camera lerp target updated: (" .. math.random(100, 700) .. ", " .. math.random(100, 500) .. ")" },
    }
    local entry = msgs[math.random(1, #msgs)]
    add_log(entry[1], entry[2])
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Debug Bridge Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.08)

    -- Input bindings
    lurek.input.bind("entity1",    { "1" })
    lurek.input.bind("entity2",    { "2" })
    lurek.input.bind("entity3",    { "3" })
    lurek.input.bind("entity4",    { "4" })
    lurek.input.bind("entity5",    { "5" })
    lurek.input.bind("debug",      { "d" })
    lurek.input.bind("info",       { "i" })
    lurek.input.bind("warn",       { "w" })
    lurek.input.bind("error",      { "e" })
    lurek.input.bind("breakpoint", { "b" })
    lurek.input.bind("quit",       { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Particle: log message pulse (soft glow on new log)
    ps_log_pulse = lurek.particle.newSystem({
        maxParticles = 30, emissionRate = 0, lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 10, speedMax = 40, direction = -1.57, spread = 2.0,
        sizes = { 3, 1 }, colors = { 0.4, 0.8, 0.4, 0.8, 0.2, 0.5, 1.0, 0 },
    })

    -- Particle: breakpoint flash (red burst)
    ps_breakpoint = lurek.particle.newSystem({
        maxParticles = 80, emissionRate = 0, lifetimeMin = 0.3, lifetimeMax = 0.8,
        speedMin = 40, speedMax = 140, direction = 0, spread = 6.28,
        gravityY = 30, sizes = { 4, 2, 0 },
        colors = { 1, 0.2, 0.2, 1, 0.8, 0.1, 0, 0 },
    })

    -- Initial frame times
    for i = 1, GRAPH_FRAMES do
        frame_times[i] = 16.67
    end

    -- Seed console
    add_console("=== Debug Bridge Console ===", true)
    add_console("Type 'help' for available commands", true)
    add_console("", true)

    -- Seed some log entries
    for _ = 1, 8 do generate_log_message() end
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if ps_log_pulse  then ps_log_pulse:update(dt)  end
    if ps_breakpoint then ps_breakpoint:update(dt) end
    lurek.tween.update(dt)

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        if lurek.input.wasActionPressed("entity1")
        or lurek.input.wasActionPressed("entity2")
        or lurek.input.wasActionPressed("entity3")
        or lurek.input.wasActionPressed("breakpoint")
        or lurek.input.wasActionPressed("debug") then
            current_state = STATE.RUNNING
            sim_time = 0
            add_log(LOG_INFO, "Debug session started")
        end
        return
    end

    -- ── PAUSED (breakpoint) ───────────────────────────────────
    if current_state == STATE.PAUSED then
        if lurek.input.wasActionPressed("breakpoint") then
            current_state = STATE.RUNNING
            add_log(LOG_INFO, "Execution resumed")
            add_console("[BREAKPOINT] Resumed", true)
        end
        -- Allow entity inspection while paused
        for idx = 1, 5 do
            local action = "entity" .. idx
            if lurek.input.wasActionPressed(action) then
                selected_entity = idx
                entity_highlight.alpha = 1.0
                lurek.tween.to(entity_highlight, { alpha = 0.3 }, 0.6)
                add_console("[INSPECT] " .. entities[idx].name .. " (frozen)", true)
            end
        end
        return
    end

    -- ── RUNNING ───────────────────────────────────────────────
    sim_time = sim_time + dt

    -- Record frame time
    local ft = dt * 1000
    -- Add simulated jitter for visual interest
    ft = ft + (math.random() - 0.5) * 4
    ft = clamp(ft, 1, 50)
    table.remove(frame_times, 1)
    frame_times[#frame_times + 1] = ft

    -- Smooth graph scroll tween
    graph_scroll.offset = graph_scroll.offset + 1

    -- Simulate memory fluctuation
    sim_memory_used = sim_memory_used + (math.random() - 0.48) * 0.3
    sim_memory_used = clamp(sim_memory_used, 20, sim_memory_max * 0.85)

    -- Simulate entity movement
    for i = 1, #entities do
        local e = entities[i]
        if e.etype == "Actor" or e.etype == "NPC" then
            e.x = e.x + math.sin(sim_time * (0.5 + i * 0.3)) * 30 * dt
            e.y = e.y + math.cos(sim_time * (0.3 + i * 0.2)) * 15 * dt
            e.x = clamp(e.x, 0, SCREEN_W)
            e.y = clamp(e.y, 0, SCREEN_H)
        end
    end

    -- Generate random log messages
    if math.random() < 0.15 then
        generate_log_message()
        if ps_log_pulse then
            ps_log_pulse:setPosition(PANEL_X_LEFT + 10, SCREEN_H - 60)
            ps_log_pulse:emit(5)
        end
    end

    -- Entity inspection
    for idx = 1, 5 do
        local action = "entity" .. idx
        if lurek.input.wasActionPressed(action) then
            selected_entity = idx
            entity_highlight.alpha = 1.0
            lurek.tween.to(entity_highlight, { alpha = 0.3 }, 0.6)
            local e = entities[idx]
            add_console("[INSPECT] " .. e.name .. " @ (" .. string.format("%.0f, %.0f", e.x, e.y) .. ")", true)
            add_log(LOG_DEBUG, "Inspector focused on entity #" .. idx)
        end
    end

    -- Log level filter
    if lurek.input.wasActionPressed("debug") then
        log_filter = LOG_DEBUG
        add_console("[FILTER] Log level → DEBUG", true)
    end
    if lurek.input.wasActionPressed("info") then
        log_filter = LOG_INFO
        add_console("[FILTER] Log level → INFO", true)
    end
    if lurek.input.wasActionPressed("warn") then
        log_filter = LOG_WARN
        add_console("[FILTER] Log level → WARN", true)
    end
    if lurek.input.wasActionPressed("error") then
        log_filter = LOG_ERROR
        add_console("[FILTER] Log level → ERROR", true)
    end

    -- Breakpoint
    if lurek.input.wasActionPressed("breakpoint") then
        current_state = STATE.PAUSED
        add_log(LOG_WARN, "BREAKPOINT HIT — execution paused")
        add_console("[BREAKPOINT] Execution frozen — press B to resume", true)
        if ps_breakpoint then
            ps_breakpoint:setPosition(SCREEN_W / 2, SCREEN_H / 2)
            ps_breakpoint:emit(40)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Render — frame graph and particles (world-space)
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE then return end

    -- Draw particle effects in world space
    if ps_log_pulse  then ps_log_pulse:render()  end
    if ps_breakpoint then ps_breakpoint:render() end

    -- Frame time graph (drawn in world-space for camera interaction)
    local gx = PANEL_X_RIGHT + 10
    local gy = PANEL_TOP + 20
    local bar_w = GRAPH_W / GRAPH_FRAMES

    -- Graph background
    lurek.render.setColor(0.06, 0.06, 0.1, 0.9)
    rect("fill", gx - 2, gy - 2, GRAPH_W + 4, GRAPH_H + 4)

    -- Target line (16.67ms = 60fps)
    local target_y = gy + GRAPH_H - (16.67 / 50 * GRAPH_H)
    lurek.render.setColor(0.3, 0.3, 0.4, 0.5)
    ln(gx, target_y, gx + GRAPH_W, target_y)

    -- Frame time bars
    for i = 1, GRAPH_FRAMES do
        local ft = frame_times[i] or 16.67
        local h = clamp(ft / 50 * GRAPH_H, 1, GRAPH_H)
        local bx = gx + (i - 1) * bar_w
        local by = gy + GRAPH_H - h
        if ft > 25 then
            lurek.render.setColor(COL_GRAPH_HIGH[1], COL_GRAPH_HIGH[2], COL_GRAPH_HIGH[3], 0.9)
        else
            lurek.render.setColor(COL_GRAPH_LINE[1], COL_GRAPH_LINE[2], COL_GRAPH_LINE[3], 0.7)
        end
        rect("fill", bx, by, math.max(bar_w - 1, 1), h)
    end

    -- Graph labels
    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
    text_("50ms", gx - 2, gy - 14, 10)
    text_("0ms", gx - 2, gy + GRAPH_H + 2, 10)
    text_("16.7ms (60fps)", gx + GRAPH_W - 80, target_y - 12, 10)

    -- Memory bar chart
    local mem_y = gy + GRAPH_H + 30
    local mem_w = GRAPH_W
    local mem_h = 20
    local used_frac = sim_memory_used / sim_memory_max

    lurek.render.setColor(COL_MEM_BAR[1], COL_MEM_BAR[2], COL_MEM_BAR[3], 0.3)
    rect("fill", gx, mem_y, mem_w, mem_h)
    lurek.render.setColor(COL_MEM_USED[1], COL_MEM_USED[2], COL_MEM_USED[3], 0.8)
    rect("fill", gx, mem_y, mem_w * used_frac, mem_h)
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
    text_(string.format("Heap: %.1f / %.1f MB", sim_memory_used, sim_memory_max), gx + 4, mem_y + 3, 12)

    -- Breakpoint frozen overlay
    if current_state == STATE.PAUSED then
        lurek.render.setColor(COL_BREAKPOINT[1], COL_BREAKPOINT[2], COL_BREAKPOINT[3], 0.08 + math.sin(sim_time * 4) * 0.04)
        rect("fill", 0, 0, SCREEN_W, SCREEN_H)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI — console, log window, inspector, HUD
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        -- Background grid effect
        lurek.render.setColor(0.08, 0.1, 0.15, 0.3)
        for gx = 0, SCREEN_W, 40 do
            ln(gx, 0, gx, SCREEN_H)
        end
        for gy = 0, SCREEN_H, 40 do
            ln(0, gy, SCREEN_W, gy)
        end

        -- Glowing title
        local pulse = 0.6 + math.sin(title_timer * 2) * 0.4
        lurek.render.setColor(COL_TITLE_GLOW[1] * pulse, COL_TITLE_GLOW[2] * pulse, COL_TITLE_GLOW[3] * pulse, 1)
        text_("DEBUG BRIDGE", SCREEN_W / 2 - 110, SCREEN_H / 2 - 60, 32)

        lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 0.7)
        text_("RUNTIME INSPECTION", SCREEN_W / 2 - 95, SCREEN_H / 2 - 15, 16)

        -- Decorative brackets
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.5 + math.sin(title_timer * 3) * 0.3)
        text_("{", SCREEN_W / 2 - 140, SCREEN_H / 2 - 55, 28)
        text_("}", SCREEN_W / 2 + 120, SCREEN_H / 2 - 55, 28)

        -- Prompt
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.5 + math.sin(title_timer * 4) * 0.3)
        text_("Press any key to start debug session", SCREEN_W / 2 - 150, SCREEN_H / 2 + 50, 13)

        -- Version / credit
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.5)
        text_("Lurek2D — Debug Bridge Showcase", SCREEN_W / 2 - 120, SCREEN_H - 30, 11)
        return
    end

    -- ── HUD header ────────────────────────────────────────────
    lurek.render.setColor(COL_PANEL_HEAD[1], COL_PANEL_HEAD[2], COL_PANEL_HEAD[3], 0.95)
    rect("fill", 0, 0, SCREEN_W, 40)

    lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
    text_("DEBUG BRIDGE", 10, 10, 16)

    local status_text = current_state == STATE.PAUSED and "PAUSED" or "RUNNING"
    local status_col = current_state == STATE.PAUSED and COL_BREAKPOINT or COL_GRAPH_LINE
    lurek.render.setColor(status_col[1], status_col[2], status_col[3], 1)
    text_(status_text, 160, 12, 14)

    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
    text_("Uptime: " .. fmt_time(), 280, 14, 11)
    text_("Entities: " .. #entities, 420, 14, 11)
    text_("Filter: " .. LOG_NAMES[log_filter], 540, 14, 11)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
    text_(string.format("FPS: %d", fps), SCREEN_W - 80, 14, 11)

    -- ── LEFT PANEL: Debug Console ─────────────────────────────
    local lx = PANEL_X_LEFT
    local ly = PANEL_TOP

    -- Panel background
    lurek.render.setColor(COL_PANEL[1], COL_PANEL[2], COL_PANEL[3], 0.92)
    rect("fill", lx, ly, PANEL_LEFT_W, 200)

    -- Panel header
    lurek.render.setColor(COL_PANEL_HEAD[1], COL_PANEL_HEAD[2], COL_PANEL_HEAD[3], 1)
    rect("fill", lx, ly, PANEL_LEFT_W, 20)
    lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
    text_("Debug Console", lx + 6, ly + 3, 12)

    -- Console lines (show last ~12 lines)
    local visible_lines = 12
    local start_idx = math.max(1, #console_lines - visible_lines + 1)
    for i = start_idx, #console_lines do
        local line = console_lines[i]
        local row = i - start_idx
        local tx = lx + 8
        local ty = ly + 24 + row * 14
        if line.response then
            lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.9)
        else
            lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
        end
        local display = line.text
        if #display > 52 then display = display:sub(1, 52) .. "…" end
        text_(display, tx, ty, 11)
    end

    -- ── LEFT PANEL: Log Window ────────────────────────────────
    local log_y = ly + 210
    local log_h = SCREEN_H - log_y - 10

    lurek.render.setColor(COL_PANEL[1], COL_PANEL[2], COL_PANEL[3], 0.92)
    rect("fill", lx, log_y, PANEL_LEFT_W, log_h)

    lurek.render.setColor(COL_PANEL_HEAD[1], COL_PANEL_HEAD[2], COL_PANEL_HEAD[3], 1)
    rect("fill", lx, log_y, PANEL_LEFT_W, 20)
    lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
    text_("Log Output", lx + 6, log_y + 3, 12)

    -- Filter indicator
    local fc = LOG_COLORS[log_filter]
    lurek.render.setColor(fc[1], fc[2], fc[3], 1)
    text_("[" .. LOG_NAMES[log_filter] .. "+]", lx + PANEL_LEFT_W - 70, log_y + 3, 11)

    -- Filtered log entries
    local filtered = {}
    for i = 1, #log_entries do
        if log_entries[i].level >= log_filter then
            filtered[#filtered + 1] = log_entries[i]
        end
    end

    local log_visible = math.floor((log_h - 24) / 13)
    local log_start = math.max(1, #filtered - log_visible + 1)
    for i = log_start, #filtered do
        local entry = filtered[i]
        local row = i - log_start
        local ty = log_y + 24 + row * 13
        local lc = LOG_COLORS[entry.level]

        -- Level tag
        lurek.render.setColor(lc[1], lc[2], lc[3], 0.9)
        text_(string.format("[%s]", LOG_NAMES[entry.level]), lx + 6, ty, 10)

        -- Timestamp
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.7)
        text_(entry.time, lx + 55, ty, 10)

        -- Message
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.8)
        local msg = entry.text
        if #msg > 38 then msg = msg:sub(1, 38) .. "…" end
        text_(msg, lx + 110, ty, 10)
    end

    -- ── RIGHT PANEL: Engine State ─────────────────────────────
    local rx = PANEL_X_RIGHT
    local ry = PANEL_TOP

    -- Panel header
    lurek.render.setColor(COL_PANEL_HEAD[1], COL_PANEL_HEAD[2], COL_PANEL_HEAD[3], 1)
    rect("fill", rx, ry, PANEL_RIGHT_W, 20)
    lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
    text_("Engine State", rx + 6, ry + 3, 12)

    -- Frame graph label
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.8)
    text_("Frame Time (ms)", rx + 10, ry + 5 + GRAPH_H + 20, 11)

    -- ── RIGHT PANEL: Entity Inspector ─────────────────────────
    local insp_y = ry + GRAPH_H + 80
    local insp_h = SCREEN_H - insp_y - 10

    lurek.render.setColor(COL_PANEL[1], COL_PANEL[2], COL_PANEL[3], 0.92)
    rect("fill", rx, insp_y, PANEL_RIGHT_W, insp_h)

    lurek.render.setColor(COL_PANEL_HEAD[1], COL_PANEL_HEAD[2], COL_PANEL_HEAD[3], 1)
    rect("fill", rx, insp_y, PANEL_RIGHT_W, 20)
    lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], 1)
    text_("Entity Inspector [1-5]", rx + 6, insp_y + 3, 12)

    if selected_entity >= 1 and selected_entity <= #entities then
        local e = entities[selected_entity]
        local iy = insp_y + 26

        -- Entity name with highlight
        lurek.render.setColor(COL_ACCENT[1], COL_ACCENT[2], COL_ACCENT[3], entity_highlight.alpha)
        rect("fill", rx + 4, iy - 2, PANEL_RIGHT_W - 8, 18)

        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        text_(string.format("#%d  %s", e.id, e.name), rx + 8, iy, 12)
        iy = iy + 20

        -- Properties
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
        text_("Type:", rx + 8, iy, 11)
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        text_(e.etype, rx + 55, iy, 11)
        iy = iy + 16

        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
        text_("Pos:", rx + 8, iy, 11)
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        text_(string.format("(%.1f, %.1f)", e.x, e.y), rx + 55, iy, 11)
        iy = iy + 16

        if e.hp >= 0 then
            lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
            text_("HP:", rx + 8, iy, 11)
            local hp_col = e.hp > 50 and COL_GRAPH_LINE or (e.hp > 25 and LOG_COLORS[LOG_WARN] or COL_BREAKPOINT)
            lurek.render.setColor(hp_col[1], hp_col[2], hp_col[3], 1)
            text_(tostring(e.hp), rx + 55, iy, 11)
            iy = iy + 16
        end

        -- Components
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 1)
        text_("Components:", rx + 8, iy, 11)
        iy = iy + 16

        for c = 1, #e.components do
            lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.8)
            text_("• " .. e.components[c], rx + 16, iy, 10)
            iy = iy + 14
        end
    else
        lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.7)
        text_("Press 1-5 to inspect an entity", rx + 10, insp_y + 30, 11)
    end

    -- ── Breakpoint overlay text ───────────────────────────────
    if current_state == STATE.PAUSED then
        lurek.render.setColor(COL_BREAKPOINT[1], COL_BREAKPOINT[2], COL_BREAKPOINT[3], 0.6 + math.sin(sim_time * 6) * 0.3)
        text_("BREAKPOINT", SCREEN_W / 2 - 55, SCREEN_H - 30, 16)
        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.5)
        text_("Press B to resume", SCREEN_W / 2 - 55, SCREEN_H - 12, 10)
    end

    -- ── Key hints ─────────────────────────────────────────────
    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.5)
    text_("[1-5] Inspect  [D/I/W/E] Filter  [B] Break  [Esc] Quit", 10, SCREEN_H - 14, 10)
end
