-- ============================================================================
-- Music Composer — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/music_composer/main.lua
-- Run with : cargo run -- content/games/showcase/music_composer
-- ============================================================================
-- Visual piano roll music sequencer. Place notes on a 32×24 grid across
-- three colored tracks with looping playback, smooth cursor, and particles.
-- Controls: 1/2/3 tracks, Click place, Space play, +/- BPM, C/X clear,
--           P presets, V mute, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local GRID_COLS   = 32     -- beats
local GRID_ROWS   = 24     -- notes C2..B3
local CELL_W      = 18
local CELL_H      = 18
local GRID_X      = 80     -- left offset for piano keys
local GRID_Y      = 50     -- top offset for header

local BPM_MIN     = 60
local BPM_MAX     = 240
local BPM_DEFAULT = 120
local TRACK_COUNT = 3

local STATE = { TITLE = 1, COMPOSING = 2 }
local current_state = STATE.TITLE

-- Note names for 24 rows (top = B3, bottom = C2)
local NOTE_NAMES = {}
do
    local base = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
    for oct = 3, 2, -1 do
        for i = 12, 1, -1 do
            NOTE_NAMES[#NOTE_NAMES + 1] = base[i] .. oct
        end
    end
end

-- Track colors
local TRACK_COLORS = {
    { 0.30, 0.55, 1.00 },  -- Track 1: blue
    { 0.25, 0.85, 0.40 },  -- Track 2: green
    { 1.00, 0.30, 0.30 },  -- Track 3: red
}
local TRACK_DIM = {
    { 0.15, 0.28, 0.55 },
    { 0.12, 0.42, 0.20 },
    { 0.55, 0.15, 0.15 },
}

-- UI colors
local COL_BG         = { 0.06, 0.06, 0.10 }
local COL_GRID_LINE  = { 0.18, 0.18, 0.25 }
local COL_GRID_BG    = { 0.08, 0.08, 0.14 }
local COL_CURSOR     = { 1.00, 0.95, 0.40, 0.35 }
local COL_CURSOR_LINE = { 1.00, 0.95, 0.40, 0.80 }
local COL_KEY_WHITE  = { 0.90, 0.90, 0.92 }
local COL_KEY_BLACK  = { 0.20, 0.20, 0.25 }
local COL_TEXT       = { 0.85, 0.85, 0.90 }
local COL_TEXT_DIM   = { 0.50, 0.50, 0.58 }
local COL_METRO_ON   = { 1.00, 0.80, 0.20 }
local COL_METRO_OFF  = { 0.25, 0.22, 0.10 }
local COL_TITLE      = { 0.45, 0.70, 1.00 }
local COL_SUBTITLE   = { 0.65, 0.80, 1.00 }
local COL_MUTED      = { 0.40, 0.40, 0.45 }

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local tracks = {}       -- tracks[t][row][col] = true/false
local muted  = { false, false, false }
local active_track = 1
local bpm    = BPM_DEFAULT
local playing = false
local play_beat   = 1   -- 1-based current beat
local beat_timer  = 0
local beat_flash  = 0   -- metronome flash countdown
local cursor_x    = 0   -- smoothed cursor pixel x
local preset_index = 0

-- Title state
local title_timer = 0
local title_pulse = 0

-- Particles & tweens
local ps_sparkle   = nil
local ps_beat      = nil
local ps_cursor    = nil
local camera       = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function beat_duration()
    return 60.0 / bpm
end

local function init_tracks()
    tracks = {}
    for t = 1, TRACK_COUNT do
        tracks[t] = {}
        for r = 1, GRID_ROWS do
            tracks[t][r] = {}
            for c = 1, GRID_COLS do
                tracks[t][r][c] = false
            end
        end
    end
end

local function count_notes(t)
    local n = 0
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            if tracks[t][r][c] then n = n + 1 end
        end
    end
    return n
end

local function clear_track(t)
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            tracks[t][r][c] = false
        end
    end
end

local function clear_all()
    for t = 1, TRACK_COUNT do
        clear_track(t)
    end
end

local function is_black_key(row)
    local name = NOTE_NAMES[row] or ""
    return name:find("#") ~= nil
end

local function grid_to_pixel(col, row)
    local px = GRID_X + (col - 1) * CELL_W
    local py = GRID_Y + (row - 1) * CELL_H
    return px, py
end

local function pixel_to_grid(mx, my)
    local col = math.floor((mx - GRID_X) / CELL_W) + 1
    local row = math.floor((my - GRID_Y) / CELL_H) + 1
    if col >= 1 and col <= GRID_COLS and row >= 1 and row <= GRID_ROWS then
        return col, row
    end
    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Preset patterns
-- ---------------------------------------------------------------------------
local function apply_preset(idx)
    clear_all()
    if idx == 1 then
        -- Simple bass line (Track 1) — low notes on beats
        local bass_rows = { 24, 24, 20, 20, 22, 22, 19, 19 }
        for i, r in ipairs(bass_rows) do
            local c1 = (i - 1) * 4 + 1
            if c1 <= GRID_COLS then tracks[1][r][c1] = true end
            local c2 = c1 + 2
            if c2 <= GRID_COLS then tracks[1][r][c2] = true end
        end
    elseif idx == 2 then
        -- Chord progression (Track 2) — triads
        local chords = {
            { 18, 15, 12 }, -- C major
            { 16, 13, 10 }, -- D minor
            { 14, 11, 8 },  -- E minor
            { 13, 10, 7 },  -- F major
        }
        for ci, chord in ipairs(chords) do
            local base_c = (ci - 1) * 8 + 1
            for _, r in ipairs(chord) do
                for off = 0, 3 do
                    local c = base_c + off * 2
                    if c <= GRID_COLS and r >= 1 and r <= GRID_ROWS then
                        tracks[2][r][c] = true
                    end
                end
            end
        end
    elseif idx == 3 then
        -- Melody (Track 3) — ascending/descending run
        local melody = { 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 8, 9, 10, 9, 8, 7,
                         6, 5, 4, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2, 1 }
        for c = 1, GRID_COLS do
            local r = melody[c]
            if r and r >= 1 and r <= GRID_ROWS then
                tracks[3][r][c] = true
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
local function setup_input()
    lurek.input.bind("track1", "1")
    lurek.input.bind("track2", "2")
    lurek.input.bind("track3", "3")
    lurek.input.bind("play",   "space")
    lurek.input.bind("bpm_up", "plus")
    lurek.input.bind("bpm_down", "minus")
    lurek.input.bind("clear",    "c")
    lurek.input.bind("clear_all", "x")
    lurek.input.bind("preset",   "p")
    lurek.input.bind("mute",     "v")
    lurek.input.bind("quit",     "escape")
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Music Composer — Lurek2D")
    lurek.render.setBackgroundColor(COL_BG[1], COL_BG[2], COL_BG[3])
    setup_input()
    init_tracks()

    camera = lurek.camera.new()
    camera:setPosition(0, 0)

    -- Note placement sparkle
    ps_sparkle = lurek.particle.new()
    ps_sparkle:setEmissionRate(0)
    ps_sparkle:setParticleLifetime(0.3, 0.6)
    ps_sparkle:setSpeed(30, 80)
    ps_sparkle:setSpread(math.pi * 2)
    ps_sparkle:setSizes(3, 1)
    ps_sparkle:setColors(1, 1, 1, 1, 1, 1, 1, 0)

    -- Beat pulse
    ps_beat = lurek.particle.new()
    ps_beat:setEmissionRate(0)
    ps_beat:setParticleLifetime(0.2, 0.5)
    ps_beat:setSpeed(10, 50)
    ps_beat:setSpread(math.pi * 2)
    ps_beat:setSizes(4, 1)
    ps_beat:setColors(1, 0.95, 0.4, 1, 1, 0.95, 0.4, 0)

    -- Cursor glow
    ps_cursor = lurek.particle.new()
    ps_cursor:setEmissionRate(40)
    ps_cursor:setParticleLifetime(0.15, 0.35)
    ps_cursor:setSpeed(5, 25)
    ps_cursor:setSpread(math.pi * 2)
    ps_cursor:setSizes(2, 0.5)
    ps_cursor:setColors(1, 0.95, 0.4, 0.8, 1, 0.95, 0.4, 0)
    ps_cursor:stop()
end

-- ---------------------------------------------------------------------------
-- Ready
-- ---------------------------------------------------------------------------
local function _ready_setup()
    current_state = STATE.TITLE
    title_timer = 0
end

-- ---------------------------------------------------------------------------
-- Process
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Update particles
    ps_sparkle:update(dt)
    ps_beat:update(dt)
    ps_cursor:update(dt)

    -- Title state
    if current_state == STATE.TITLE then
        title_timer = title_timer + dt
        title_pulse = title_pulse + dt * 3
        if lurek.input.wasActionPressed("play") then
            current_state = STATE.COMPOSING
            playing = false
            play_beat = 1
            beat_timer = 0
            cursor_x = GRID_X
        end
        return
    end

    -- === COMPOSING state ===
    -- Track switching
    if lurek.input.wasActionPressed("track1") then
        active_track = 1
    elseif lurek.input.wasActionPressed("track2") then
        active_track = 2
    elseif lurek.input.wasActionPressed("track3") then
        active_track = 3
    end

    -- Mute toggle
    if lurek.input.wasActionPressed("mute") then
        muted[active_track] = not muted[active_track]
    end

    -- BPM control
    if lurek.input.wasActionPressed("bpm_up") then
        bpm = math.min(bpm + 5, BPM_MAX)
    end
    if lurek.input.wasActionPressed("bpm_down") then
        bpm = math.max(bpm - 5, BPM_MIN)
    end

    -- Clear
    if lurek.input.wasActionPressed("clear") then
        clear_track(active_track)
    end
    if lurek.input.wasActionPressed("clear_all") then
        clear_all()
    end

    -- Presets
    if lurek.input.wasActionPressed("preset") then
        preset_index = (preset_index % 3) + 1
        apply_preset(preset_index)
    end

    -- Play / pause
    if lurek.input.wasActionPressed("play") then
        playing = not playing
        if playing then
            ps_cursor:start()
        else
            ps_cursor:stop()
        end
    end

    -- Mouse click → toggle note
    if lurek.input.isMousePressed(1) then
        local mx, my = lurek.input.mouse.getPosition()
        local col, row = pixel_to_grid(mx, my)
        if col and row then
            tracks[active_track][row][col] = not tracks[active_track][row][col]
            if tracks[active_track][row][col] then
                -- sparkle on placement
                local px, py = grid_to_pixel(col, row)
                ps_sparkle:setPosition(px + CELL_W * 0.5, py + CELL_H * 0.5)
                ps_sparkle:emit(12)
                local tc = TRACK_COLORS[active_track]
                ps_sparkle:setColors(tc[1], tc[2], tc[3], 1, tc[1], tc[2], tc[3], 0)
            end
        end
    end

    -- Playback
    if playing then
        beat_timer = beat_timer + dt
        local dur = beat_duration()

        if beat_timer >= dur then
            beat_timer = beat_timer - dur
            play_beat = play_beat + 1
            if play_beat > GRID_COLS then
                play_beat = 1
            end
            -- Beat flash
            beat_flash = 0.15
            -- Beat pulse particle at cursor column top
            local cx = GRID_X + (play_beat - 1) * CELL_W + CELL_W * 0.5
            ps_beat:setPosition(cx, GRID_Y - 5)
            ps_beat:emit(8)
        end

        -- Smooth cursor via tween-like lerp
        local target_x = GRID_X + (play_beat - 1) * CELL_W
        cursor_x = cursor_x + (target_x - cursor_x) * math.min(1.0, dt * 14)

        -- Cursor particle position
        ps_cursor:setPosition(cursor_x + CELL_W * 0.5, GRID_Y + GRID_ROWS * CELL_H * 0.5)

        -- Metronome flash decay
        if beat_flash > 0 then
            beat_flash = beat_flash - dt
            if beat_flash < 0 then beat_flash = 0 end
        end
    end

    -- FPS title
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle(string.format("Music Composer — %d FPS", fps))
end

-- ---------------------------------------------------------------------------
-- Render — grid, notes, cursor
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE then
        return
    end

    camera:attach()

    -- Grid background
    lurek.render.setColor(COL_GRID_BG[1], COL_GRID_BG[2], COL_GRID_BG[3], 1)
    lurek.render.rectangle("fill", GRID_X, GRID_Y, GRID_COLS * CELL_W, GRID_ROWS * CELL_H)

    -- Grid lines — horizontal
    lurek.render.setColor(COL_GRID_LINE[1], COL_GRID_LINE[2], COL_GRID_LINE[3], 0.5)
    for r = 0, GRID_ROWS do
        local y = GRID_Y + r * CELL_H
        lurek.render.line(GRID_X, y, GRID_X + GRID_COLS * CELL_W, y)
    end
    -- Grid lines — vertical (thicker every 4 beats)
    for c = 0, GRID_COLS do
        local x = GRID_X + c * CELL_W
        if c % 4 == 0 then
            lurek.render.setColor(COL_GRID_LINE[1], COL_GRID_LINE[2], COL_GRID_LINE[3], 0.8)
        else
            lurek.render.setColor(COL_GRID_LINE[1], COL_GRID_LINE[2], COL_GRID_LINE[3], 0.3)
        end
        lurek.render.line(x, GRID_Y, x, GRID_Y + GRID_ROWS * CELL_H)
    end

    -- Black-key row shading
    for r = 1, GRID_ROWS do
        if is_black_key(r) then
            lurek.render.setColor(0, 0, 0, 0.15)
            local py = GRID_Y + (r - 1) * CELL_H
            lurek.render.rectangle("fill", GRID_X, py, GRID_COLS * CELL_W, CELL_H)
        end
    end

    -- Notes — draw all tracks (back to front: 3, 2, 1 so active is on top)
    local draw_order = {}
    for t = 1, TRACK_COUNT do
        if t ~= active_track then draw_order[#draw_order + 1] = t end
    end
    draw_order[#draw_order + 1] = active_track

    for _, t in ipairs(draw_order) do
        local col = muted[t] and COL_MUTED or TRACK_COLORS[t]
        local dim = muted[t] and COL_MUTED or TRACK_DIM[t]
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                if tracks[t][r][c] then
                    local px, py = grid_to_pixel(c, r)
                    -- Filled note
                    if t == active_track then
                        lurek.render.setColor(col[1], col[2], col[3], 0.95)
                    else
                        lurek.render.setColor(dim[1], dim[2], dim[3], 0.65)
                    end
                    lurek.render.rectangle("fill", px + 1, py + 1, CELL_W - 2, CELL_H - 2)
                    -- Border
                    lurek.render.setColor(col[1], col[2], col[3], 0.4)
                    lurek.render.rectangle("line", px + 1, py + 1, CELL_W - 2, CELL_H - 2)
                end
            end
        end
    end

    -- Playback cursor column highlight
    if playing then
        lurek.render.setColor(COL_CURSOR[1], COL_CURSOR[2], COL_CURSOR[3], COL_CURSOR[4])
        lurek.render.rectangle("fill", cursor_x, GRID_Y, CELL_W, GRID_ROWS * CELL_H)
        -- Cursor line
        lurek.render.setColor(COL_CURSOR_LINE[1], COL_CURSOR_LINE[2], COL_CURSOR_LINE[3], COL_CURSOR_LINE[4])
        lurek.render.line(cursor_x + CELL_W * 0.5, GRID_Y, cursor_x + CELL_W * 0.5, GRID_Y + GRID_ROWS * CELL_H)
    end

    -- Particles
    lurek.render.draw(ps_sparkle)
    lurek.render.draw(ps_beat)
    if playing then
        lurek.render.draw(ps_cursor)
    end

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI — piano keys, HUD, controls
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state == STATE.TITLE then
        -- Title screen
        local cx = SCREEN_W * 0.5
        local alpha = math.min(1.0, title_timer * 1.5)
        local pulse = 0.85 + 0.15 * math.sin(title_pulse)

        lurek.render.setColor(COL_TITLE[1] * pulse, COL_TITLE[2] * pulse, COL_TITLE[3], alpha)
        lurek.render.print("MUSIC COMPOSER", cx - 120, SCREEN_H * 0.32, 0, 2.2, 2.2)

        lurek.render.setColor(COL_SUBTITLE[1], COL_SUBTITLE[2], COL_SUBTITLE[3], alpha * 0.8)
        lurek.render.print("CREATE YOUR MELODY", cx - 95, SCREEN_H * 0.45, 0, 1.2, 1.2)

        local blink = math.floor(title_timer * 2) % 2 == 0
        if blink then
            lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], alpha * 0.7)
            lurek.render.print("Press SPACE to start", cx - 85, SCREEN_H * 0.65)
        end

        lurek.render.setColor(COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3], alpha * 0.5)
        lurek.render.print("A Lurek2D Showcase", cx - 72, SCREEN_H * 0.85)
        return
    end

    -- === COMPOSING UI ===

    -- Piano key labels (left side)
    for r = 1, GRID_ROWS do
        local name = NOTE_NAMES[r] or "?"
        local py = GRID_Y + (r - 1) * CELL_H + 3
        local bk = is_black_key(r)

        -- Key background
        if bk then
            lurek.render.setColor(COL_KEY_BLACK[1], COL_KEY_BLACK[2], COL_KEY_BLACK[3], 1)
            lurek.render.rectangle("fill", 2, py - 3, GRID_X - 6, CELL_H)
            lurek.render.setColor(0.75, 0.75, 0.80, 0.9)
        else
            lurek.render.setColor(COL_KEY_WHITE[1], COL_KEY_WHITE[2], COL_KEY_WHITE[3], 0.12)
            lurek.render.rectangle("fill", 2, py - 3, GRID_X - 6, CELL_H)
            lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 0.7)
        end
        lurek.render.print(name, 10, py)
    end

    -- Top bar: Track indicator, BPM, beat counter
    local bar_y = 8
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
    lurek.render.print("Track:", 10, bar_y)

    for t = 1, TRACK_COUNT do
        local tx = 60 + (t - 1) * 50
        local tc = muted[t] and COL_MUTED or TRACK_COLORS[t]
        if t == active_track then
            lurek.render.setColor(tc[1], tc[2], tc[3], 1)
            lurek.render.rectangle("fill", tx, bar_y - 2, 38, 18)
            lurek.render.setColor(0, 0, 0, 1)
            lurek.render.print(tostring(t), tx + 14, bar_y)
        else
            lurek.render.setColor(tc[1], tc[2], tc[3], 0.5)
            lurek.render.rectangle("line", tx, bar_y - 2, 38, 18)
            lurek.render.setColor(tc[1], tc[2], tc[3], 0.7)
            lurek.render.print(tostring(t), tx + 14, bar_y)
        end
        if muted[t] then
            lurek.render.setColor(COL_MUTED[1], COL_MUTED[2], COL_MUTED[3], 0.8)
            lurek.render.print("M", tx + 28, bar_y)
        end
    end

    -- BPM display
    lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
    lurek.render.print(string.format("BPM: %d", bpm), 240, bar_y)

    -- Beat counter
    if playing then
        lurek.render.setColor(COL_CURSOR_LINE[1], COL_CURSOR_LINE[2], COL_CURSOR_LINE[3], 1)
        lurek.render.print(string.format("Beat %d/%d", play_beat, GRID_COLS), 340, bar_y)
    else
        lurek.render.setColor(COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3], 0.7)
        lurek.render.print("PAUSED", 340, bar_y)
    end

    -- Metronome indicator
    local metro_x, metro_y = 460, bar_y
    if playing and beat_flash > 0 then
        local f = beat_flash / 0.15
        lurek.render.setColor(COL_METRO_ON[1], COL_METRO_ON[2], COL_METRO_ON[3], f)
        lurek.render.circle("fill", metro_x + 6, metro_y + 7, 6 + f * 3)
    else
        lurek.render.setColor(COL_METRO_OFF[1], COL_METRO_OFF[2], COL_METRO_OFF[3], 0.6)
        lurek.render.circle("fill", metro_x + 6, metro_y + 7, 6)
    end

    -- Preset label
    if preset_index > 0 then
        local pnames = { "Bass Line", "Chords", "Melody" }
        lurek.render.setColor(COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3], 0.8)
        lurek.render.print("Preset: " .. pnames[preset_index], 500, bar_y)
    end

    -- Note counts (bottom)
    local bot_y = GRID_Y + GRID_ROWS * CELL_H + 10
    for t = 1, TRACK_COUNT do
        local tc = muted[t] and COL_MUTED or TRACK_COLORS[t]
        lurek.render.setColor(tc[1], tc[2], tc[3], 0.9)
        local nx = GRID_X + (t - 1) * 180
        local label = string.format("Track %d: %d notes", t, count_notes(t))
        if muted[t] then label = label .. " [MUTED]" end
        lurek.render.print(label, nx, bot_y)
    end

    -- Controls help (bottom right)
    lurek.render.setColor(COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3], 0.5)
    lurek.render.print("Space:Play  +/-:BPM  C:Clear  X:ClearAll  P:Preset  V:Mute", GRID_X, bot_y + 20)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3], 0.4)
    lurek.render.print(string.format("%d FPS", fps), SCREEN_W - 60, SCREEN_H - 20)
end
