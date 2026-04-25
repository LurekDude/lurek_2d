-- Automation Demo — Lurek2D
-- Category: showcase
-- Record and replay input events with visualization

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local TIMELINE_Y = SCREEN_H - 40
local TIMELINE_H = 30
local TIMELINE_X = 20
local TIMELINE_W = SCREEN_W - 40
local HUD_Y = 10
local GHOST_RADIUS = 10
local KEY_FLASH_SIZE = 40
local KEY_FLASH_DURATION = 0.5
local CANVAS_Y = 60
local CANVAS_H = SCREEN_H - 110
local RECT_SIZE = 20

-- ============================================================
-- State
-- ============================================================
local STATE_TITLE    = "TITLE"
local STATE_IDLE     = "IDLE"
local STATE_RECORDING = "RECORDING"
local STATE_PLAYING  = "PLAYING"

local state = STATE_TITLE
local title_timer = 0

-- Recording
local recorded_events = {}
local record_start_time = 0
local record_duration = 0

-- Playback
local playback_index = 1
local playback_start_time = 0
local playback_speed = 1.0
local playback_progress = 0
local ghost_x, ghost_y = SCREEN_W / 2, SCREEN_H / 2
local ghost_target_x, ghost_target_y = ghost_x, ghost_y

-- Key flash visualization
local key_flashes = {}

-- Canvas rectangles drawn by user or automation
local canvas_rects = {}
local color_palette = {
    {0.9, 0.2, 0.3},
    {0.2, 0.7, 0.9},
    {0.3, 0.9, 0.3},
    {0.9, 0.8, 0.2},
    {0.8, 0.3, 0.9},
    {0.9, 0.5, 0.2},
}
local next_color_idx = 1

-- Speed labels
local speed_labels = { [0.5] = "0.5x", [1.0] = "1x", [2.0] = "2x" }

-- Message overlay
local message_text = ""
local message_timer = 0
local MESSAGE_DURATION = 2.5

-- Timeline cursor tween
local timeline_cursor_x = TIMELINE_X
local timeline_cursor_target = TIMELINE_X

-- Particles
local particles = {}

-- FPS
local fps = 0
local fps_timer = 0
local fps_count = 0

-- ============================================================
-- Helpers
-- ============================================================
local function show_message(text)
    message_text = text
    message_timer = MESSAGE_DURATION
end

local function get_time()
    return lurek.timer.getTime()
end

local function spawn_particles(x, y, r, g, b, count, spread)
    count = count or 6
    spread = spread or 40
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 20 + math.random() * spread
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            r = r, g = g, b = b, a = 1.0,
            life = 0.4 + math.random() * 0.4,
            size = 2 + math.random() * 3,
        })
    end
end

local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
end

local function add_event(etype, data)
    local elapsed = get_time() - record_start_time
    table.insert(recorded_events, { time = elapsed, type = etype, data = data })
end

local function place_rect(x, y)
    local c = color_palette[next_color_idx]
    next_color_idx = (next_color_idx % #color_palette) + 1
    table.insert(canvas_rects, { x = x - RECT_SIZE / 2, y = y - RECT_SIZE / 2, r = c[1], g = c[2], b = c[3] })
    spawn_particles(x, y, c[1], c[2], c[3], 4, 25)
end

local function add_key_flash(key_name)
    table.insert(key_flashes, { key = key_name, timer = KEY_FLASH_DURATION })
    spawn_particles(SCREEN_W / 2, HUD_Y + 40, 1, 1, 0.5, 3, 15)
end

-- ============================================================
-- Recording
-- ============================================================
local function start_recording()
    recorded_events = {}
    record_start_time = get_time()
    record_duration = 0
    state = STATE_RECORDING
    show_message("RECORDING...")
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 1, 0.2, 0.2, 12, 60)
end

local function stop_recording()
    record_duration = get_time() - record_start_time
    state = STATE_IDLE
    show_message(string.format("Recorded %d events in %.1f seconds", #recorded_events, record_duration))
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 0.2, 1, 0.2, 10, 50)
end

-- ============================================================
-- Playback
-- ============================================================
local function start_playback()
    if #recorded_events == 0 then
        show_message("Nothing recorded!")
        return
    end
    playback_index = 1
    playback_start_time = get_time()
    playback_progress = 0
    state = STATE_PLAYING
    show_message(string.format("Playing %d events at %s", #recorded_events, speed_labels[playback_speed] or tostring(playback_speed) .. "x"))
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 0.2, 0.8, 1, 10, 50)
end

local function stop_playback()
    state = STATE_IDLE
    show_message("Playback finished")
end

local function process_playback_event(ev)
    if ev.type == "key" then
        add_key_flash(ev.data.key)
        spawn_particles(SCREEN_W / 2, HUD_Y + 40, 1, 1, 0.4, 3, 20)
    elseif ev.type == "mouse_click" then
        ghost_target_x = ev.data.x
        ghost_target_y = ev.data.y
        place_rect(ev.data.x, ev.data.y)
    elseif ev.type == "mouse_move" then
        ghost_target_x = ev.data.x
        ghost_target_y = ev.data.y
        spawn_particles(ev.data.x, ev.data.y, 0.2, 1, 0.5, 1, 10)
    end
end

-- ============================================================
-- Auto-test
-- ============================================================
local function run_autotest()
    recorded_events = {}
    record_duration = 3.0
    -- Generate a grid pattern of clicks
    local t = 0
    local step = 0.08
    local cols, rows = 8, 5
    local ox = (SCREEN_W - cols * 50) / 2 + 25
    local oy = CANVAS_Y + 40
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local cx = ox + col * 50
            local cy = oy + row * 50
            t = t + step
            table.insert(recorded_events, { time = t, type = "mouse_move", data = { x = cx, y = cy } })
            t = t + step * 0.5
            table.insert(recorded_events, { time = t, type = "mouse_click", data = { x = cx, y = cy, button = 1 } })
        end
    end
    -- Add some key events
    t = t + 0.3
    table.insert(recorded_events, { time = t, type = "key", data = { key = "A" } })
    t = t + 0.2
    table.insert(recorded_events, { time = t, type = "key", data = { key = "U" } })
    t = t + 0.2
    table.insert(recorded_events, { time = t, type = "key", data = { key = "T" } })
    t = t + 0.2
    table.insert(recorded_events, { time = t, type = "key", data = { key = "O" } })
    record_duration = t + 0.5

    show_message("Auto-test loaded — press P to play")
    spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 1, 0.8, 0.2, 15, 70)
end

-- ============================================================
-- Input bindings
-- ============================================================
lurek.input.bind("record",  "r")
lurek.input.bind("play",    "p")
lurek.input.bind("clear",   "c")
lurek.input.bind("test",    "t")
lurek.input.bind("speed1",  "1")
lurek.input.bind("speed2",  "2")
lurek.input.bind("speed3",  "3")
lurek.input.bind("quit",    "escape")

-- ============================================================
-- Callbacks
-- ============================================================

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
    lurek.window.setTitle("Automation Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.1, 0.15)
    state = STATE_TITLE
    title_timer = 0
end

local function _ready_setup()
    -- ready
end

function lurek.process(dt)
    -- FPS counter
    fps_timer = fps_timer + dt
    fps_count = fps_count + 1
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end

    -- Message decay
    if message_timer > 0 then
        message_timer = message_timer - dt
    end

    -- Particle update
    local alive = {}
    for _, p in ipairs(particles) do
        p.life = p.life - dt
        if p.life > 0 then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.a = p.life / (p.life + dt)
            p.size = p.size * 0.98
            table.insert(alive, p)
        end
    end
    particles = alive

    -- Key flash update
    local active_flashes = {}
    for _, f in ipairs(key_flashes) do
        f.timer = f.timer - dt
        if f.timer > 0 then
            table.insert(active_flashes, f)
        end
    end
    key_flashes = active_flashes

    -- Title screen
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        if title_timer > 3.0 then
            state = STATE_IDLE
        end
        return
    end

    -- Recording: capture input events
    if state == STATE_RECORDING then
        -- Recording pulse particles
        if math.floor(get_time() * 4) % 2 == 0 then
            spawn_particles(30, 30, 1, 0.2, 0.2, 1, 8)
        end

        local mx, my = lurek.input.mouse.getPosition()
        add_event("mouse_move", { x = mx, y = my })

        if lurek.input.mouse.isDown(1) then
            add_event("mouse_click", { x = mx, y = my, button = 1 })
            place_rect(mx, my)
        end
    end

    -- Playback processing
    if state == STATE_PLAYING then
        local elapsed = (get_time() - playback_start_time) * playback_speed
        if record_duration > 0 then
            playback_progress = math.min(elapsed / record_duration, 1.0)
        end

        -- Timeline cursor tween
        timeline_cursor_target = TIMELINE_X + playback_progress * TIMELINE_W
        timeline_cursor_x = lerp(timeline_cursor_x, timeline_cursor_target, dt * 12)

        -- Ghost cursor smooth interpolation
        ghost_x = lerp(ghost_x, ghost_target_x, dt * 15)
        ghost_y = lerp(ghost_y, ghost_target_y, dt * 15)

        -- Playback trail particles
        spawn_particles(ghost_x, ghost_y, 0.2, 1, 0.5, 1, 6)

        -- Process events up to current time
        while playback_index <= #recorded_events do
            local ev = recorded_events[playback_index]
            if ev.time <= elapsed then
                process_playback_event(ev)

                -- Event marker sparkle
                if ev.type == "mouse_click" or ev.type == "key" then
                    local marker_x = TIMELINE_X + (ev.time / math.max(record_duration, 0.01)) * TIMELINE_W
                    spawn_particles(marker_x, TIMELINE_Y, 1, 0.8, 0.3, 3, 15)
                end

                playback_index = playback_index + 1
            else
                break
            end
        end

        if elapsed >= record_duration then
            stop_playback()
        end
    end

    -- Input handling (only in IDLE)
    if state == STATE_IDLE or state == STATE_RECORDING then
        if lurek.input.isActionDown("record") then
            if state == STATE_RECORDING then
                stop_recording()
            else
                start_recording()
            end
        end
    end

    if state == STATE_IDLE then
        if lurek.input.isActionDown("play") then
            start_playback()
        end
        if lurek.input.isActionDown("clear") then
            recorded_events = {}
            canvas_rects = {}
            next_color_idx = 1
            show_message("Cleared all events and canvas")
            spawn_particles(SCREEN_W / 2, SCREEN_H / 2, 0.5, 0.5, 1, 8, 40)
        end
        if lurek.input.isActionDown("test") then
            run_autotest()
        end
        if lurek.input.isActionDown("speed1") then
            playback_speed = 0.5
            show_message("Speed: 0.5x")
        end
        if lurek.input.isActionDown("speed2") then
            playback_speed = 1.0
            show_message("Speed: 1x")
        end
        if lurek.input.isActionDown("speed3") then
            playback_speed = 2.0
            show_message("Speed: 2x")
        end

        -- Canvas drawing in idle mode
        if lurek.input.mouse.isDown(1) then
            local mx, my = lurek.input.mouse.getPosition()
            if my > CANVAS_Y and my < CANVAS_Y + CANVAS_H then
                place_rect(mx, my)
            end
        end
    end

    if lurek.input.isActionDown("quit") then
        lurek.event.quit()
    end
end

-- ============================================================
-- Render: world-space (canvas content)
-- ============================================================
function lurek.draw()
    -- Canvas background
    lurek.render.setColor(0.08, 0.08, 0.12, 1)
    rect(0, CANVAS_Y, SCREEN_W, CANVAS_H)

    -- Canvas border
    lurek.render.setColor(0.25, 0.25, 0.35, 1)
    rect("line", 0, CANVAS_Y, SCREEN_W, CANVAS_H)

    -- Drawn rectangles
    for _, r in ipairs(canvas_rects) do
        lurek.render.setColor(r.r, r.g, r.b, 0.9)
        rect(r.x, r.y, RECT_SIZE, RECT_SIZE)
        lurek.render.setColor(r.r * 0.6, r.g * 0.6, r.b * 0.6, 1)
        rect("line", r.x, r.y, RECT_SIZE, RECT_SIZE)
    end

    -- Particles (world-space ones)
    for _, p in ipairs(particles) do
        if p.y > CANVAS_Y and p.y < CANVAS_Y + CANVAS_H then
            lurek.render.setColor(p.r, p.g, p.b, p.a)
            circ(p.x, p.y, p.size)
        end
    end

    -- Ghost cursor during playback
    if state == STATE_PLAYING then
        lurek.render.setColor(0.2, 1, 0.5, 0.7)
        circ(ghost_x, ghost_y, GHOST_RADIUS)
        lurek.render.setColor(0.1, 0.8, 0.4, 1)
        circ("line", ghost_x, ghost_y, GHOST_RADIUS + 2)
    end
end

-- ============================================================
-- Render UI: HUD, timeline, messages
-- ============================================================
function lurek.draw_ui()
    -- Title screen
    if state == STATE_TITLE then
        local alpha = 1.0
        if title_timer > 2.0 then
            alpha = math.max(0, 1.0 - (title_timer - 2.0))
        end
        lurek.render.setColor(0.3, 0.8, 1, alpha)
        text_("AUTOMATION DEMO", SCREEN_W / 2 - 120, SCREEN_H / 2 - 40)
        lurek.render.setColor(0.6, 0.6, 0.7, alpha * 0.8)
        text_("RECORD AND REPLAY INPUT", SCREEN_W / 2 - 130, SCREEN_H / 2 + 10)
        lurek.render.setColor(0.4, 0.4, 0.5, alpha * 0.6)
        text_("Lurek2D Showcase", SCREEN_W / 2 - 70, SCREEN_H / 2 + 50)
        return
    end

    -- HUD background
    lurek.render.setColor(0.05, 0.05, 0.1, 0.9)
    rect(0, 0, SCREEN_W, 55)

    -- State indicator
    local state_color_r, state_color_g, state_color_b = 0.5, 0.5, 0.5
    local state_label = state
    if state == STATE_RECORDING then
        state_color_r, state_color_g, state_color_b = 1, 0.2, 0.2
        -- Pulsing record dot
        local pulse = 0.5 + 0.5 * math.sin(get_time() * 6)
        lurek.render.setColor(1, 0.1, 0.1, pulse)
        circ(15, 20, 6)
    elseif state == STATE_PLAYING then
        state_color_r, state_color_g, state_color_b = 0.2, 0.9, 0.5
    elseif state == STATE_IDLE then
        state_color_r, state_color_g, state_color_b = 0.4, 0.6, 1
    end

    lurek.render.setColor(state_color_r, state_color_g, state_color_b, 1)
    text_(state_label, 30, HUD_Y)

    -- Event count
    lurek.render.setColor(0.7, 0.7, 0.8, 1)
    text_(string.format("Events: %d", #recorded_events), 160, HUD_Y)

    -- Playback speed
    lurek.render.setColor(0.6, 0.8, 0.6, 1)
    text_(string.format("Speed: %s", speed_labels[playback_speed] or tostring(playback_speed) .. "x"), 320, HUD_Y)

    -- Playback progress
    if state == STATE_PLAYING then
        lurek.render.setColor(0.2, 1, 0.6, 1)
        text_(string.format("Progress: %d%%", math.floor(playback_progress * 100)), 470, HUD_Y)
    end

    -- FPS
    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    text_(string.format("FPS: %d", fps), SCREEN_W - 80, HUD_Y)

    -- Controls hint
    lurek.render.setColor(0.35, 0.35, 0.45, 1)
    text_("R:Record  P:Play  C:Clear  T:Test  1/2/3:Speed  ESC:Quit", 10, 35)

    -- Key flash boxes
    local flash_x = SCREEN_W / 2 - (#key_flashes * (KEY_FLASH_SIZE + 5)) / 2
    for _, f in ipairs(key_flashes) do
        local alpha = f.timer / KEY_FLASH_DURATION
        lurek.render.setColor(1, 1, 0.5, alpha * 0.8)
        rect(flash_x, CANVAS_Y + 5, KEY_FLASH_SIZE, KEY_FLASH_SIZE)
        lurek.render.setColor(0.1, 0.1, 0.1, alpha)
        text_(f.key, flash_x + 10, CANVAS_Y + 15)
        flash_x = flash_x + KEY_FLASH_SIZE + 5
    end

    -- UI-space particles (outside canvas)
    for _, p in ipairs(particles) do
        if p.y <= CANVAS_Y or p.y >= CANVAS_Y + CANVAS_H then
            lurek.render.setColor(p.r, p.g, p.b, p.a)
            circ(p.x, p.y, p.size)
        end
    end

    -- Event timeline bar
    lurek.render.setColor(0.15, 0.15, 0.2, 1)
    rect(TIMELINE_X, TIMELINE_Y, TIMELINE_W, TIMELINE_H)
    lurek.render.setColor(0.3, 0.3, 0.4, 1)
    rect("line", TIMELINE_X, TIMELINE_Y, TIMELINE_W, TIMELINE_H)

    -- Event markers on timeline
    if record_duration > 0 then
        for _, ev in ipairs(recorded_events) do
            local mx = TIMELINE_X + (ev.time / record_duration) * TIMELINE_W
            if ev.type == "key" then
                lurek.render.setColor(1, 0.8, 0.2, 0.8)
            elseif ev.type == "mouse_click" then
                lurek.render.setColor(0.2, 0.8, 1, 0.8)
            else
                lurek.render.setColor(0.4, 0.4, 0.5, 0.3)
            end
            rect(mx - 1, TIMELINE_Y + 2, 2, TIMELINE_H - 4)
        end
    end

    -- Timeline cursor
    if state == STATE_PLAYING then
        lurek.render.setColor(0.2, 1, 0.5, 1)
        rect(timeline_cursor_x - 2, TIMELINE_Y - 3, 4, TIMELINE_H + 6)
    end

    -- Timeline label
    lurek.render.setColor(0.5, 0.5, 0.6, 1)
    if record_duration > 0 then
        text_(string.format("%.1fs", record_duration), TIMELINE_X + TIMELINE_W + 5, TIMELINE_Y + 7)
    else
        text_("--", TIMELINE_X + TIMELINE_W + 5, TIMELINE_Y + 7)
    end

    -- Message overlay
    if message_timer > 0 then
        local alpha = math.min(message_timer, 1.0)
        lurek.render.setColor(0.05, 0.05, 0.1, alpha * 0.85)
        rect(SCREEN_W / 2 - 200, SCREEN_H / 2 - 20, 400, 40)
        lurek.render.setColor(1, 1, 1, alpha)
        text_(message_text, SCREEN_W / 2 - 180, SCREEN_H / 2 - 8)
    end
end
