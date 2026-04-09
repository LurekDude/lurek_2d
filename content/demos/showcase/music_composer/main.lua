-- Music Composer / DAW Simulation
-- Piano roll grid, multi-track, BPM, playback, note placement
-- Run with: cargo run -- demos/showcase/music_composer

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local GRID_COLS = 32   -- beats
local GRID_ROWS = 24   -- notes C3-B4 (2 octaves)
local CELL_W = 22
local CELL_H = 16
local OX, OY = 80, 60
local bpm = 120
local playing = false
local looping = false
local play_cursor = 0  -- beat position (float)
local current_track = 1
local tracks = {}
local track_names = { "Melody", "Bass", "Drums" }
local track_colors = {
    {0.3, 0.7, 1},    -- melody: blue
    {1, 0.5, 0.2},    -- bass: orange
    {0.5, 1, 0.4},    -- drums: green
}
local track_muted = { false, false, false }
local note_names = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
local show_export = false
local export_text = ""
local drag_start = nil  -- for long notes: {col, row}

function luna.init()
    for t = 1, 3 do
        tracks[t] = {}
        for r = 1, GRID_ROWS do
            tracks[t][r] = {}
            for c = 1, GRID_COLS do
                tracks[t][r][c] = false
            end
        end
    end
end

local function note_label(row)
    -- Row 1 = C5 (top), Row 24 = C3 (bottom)
    local idx = GRID_ROWS - row  -- 0-based from bottom
    local octave = 3 + math.floor(idx / 12)
    local note_idx = (idx % 12) + 1
    return note_names[note_idx] .. octave
end

local function is_sharp(row)
    -- Map grid row to a 0-based chromatic index; sharps are the black keys on a piano
    local idx = (GRID_ROWS - row) % 12
    -- sharps: 1, 3, 6, 8, 10
    return idx == 1 or idx == 3 or idx == 6 or idx == 8 or idx == 10
end

local function beats_per_sec()
    -- Convert BPM to beats-per-second for the playback cursor advance rate
    return bpm / 60
end

local function export_notes()
    local lines = {}
    for t = 1, 3 do
        lines[#lines + 1] = "=== " .. track_names[t] .. " ==="
        local notes = {}
        for c = 1, GRID_COLS do
            for r = 1, GRID_ROWS do
                if tracks[t][r][c] then
                    -- Find note length
                    local length = 1
                    local cc = c + 1
                    while cc <= GRID_COLS and tracks[t][r][cc] do
                        length = length + 1
                        cc = cc + 1
                    end
                    notes[#notes + 1] = "Beat " .. c .. ": " .. note_label(r) .. " (len=" .. length .. ")"
                    -- Skip to end of this note in scan
                end
            end
        end
        if #notes == 0 then
            lines[#lines + 1] = "(empty)"
        else
            for _, n in ipairs(notes) do
                lines[#lines + 1] = n
            end
        end
        lines[#lines + 1] = ""
    end
    export_text = table.concat(lines, "\n")
end

function luna.process(dt)
    if playing then
        play_cursor = play_cursor + beats_per_sec() * dt
        if play_cursor >= GRID_COLS then
            if looping then
                play_cursor = 0
            else
                playing = false
                play_cursor = 0
            end
        end
    end
end

function luna.keypressed(key)
    if show_export then
        if key == "escape" or key == "e" then show_export = false end
        return
    end

    if key == "space" then
        playing = not playing
        if playing then play_cursor = 0 end
    elseif key == "1" then current_track = 1
    elseif key == "2" then current_track = 2
    elseif key == "3" then current_track = 3
    elseif key == "up" then bpm = clamp(bpm + 5, 60, 200)
    elseif key == "down" then bpm = clamp(bpm - 5, 60, 200)
    elseif key == "l" then looping = not looping
    elseif key == "c" then
        -- Clear current track
        for r = 1, GRID_ROWS do
            for c2 = 1, GRID_COLS do
                tracks[current_track][r][c2] = false
            end
        end
    elseif key == "m" then
        -- Mute toggle for current track
        track_muted[current_track] = not track_muted[current_track]
    elseif key == "e" then
        export_notes()
        show_export = true
    elseif key == "escape" then
        luna.signal.quit()
    end
end

function luna.mousepressed(mx, my, btn)
    if show_export then return end
    -- Check grid click
    local col = math.floor((mx - OX) / CELL_W) + 1
    local row = math.floor((my - OY) / CELL_H) + 1
    if col >= 1 and col <= GRID_COLS and row >= 1 and row <= GRID_ROWS then
        if btn == 1 then
            -- Toggle note
            tracks[current_track][row][col] = not tracks[current_track][row][col]
            drag_start = { col = col, row = row }
        elseif btn == 2 then
            -- Right click: fill a long note from here to next empty
            if not tracks[current_track][row][col] then
                -- Fill 2-4 beats
                local len = clamp(math.random(2, 4), 1, GRID_COLS - col + 1)
                for i = 0, len - 1 do
                    if col + i <= GRID_COLS then
                        tracks[current_track][row][col + i] = true
                    end
                end
            end
        end
    end
end

local function draw_waveform()
    -- Simple visual waveform during playback
    if not playing then return end
    local wx = OX
    local wy = OY + GRID_ROWS * CELL_H + 25
    local ww = GRID_COLS * CELL_W
    local wh = 40

    luna.gfx.setColor(0.15, 0.15, 0.2, 1)
    luna.gfx.rectangle("fill", wx, wy, ww, wh)

    local time = luna.time.getTime()
    for t = 1, 3 do
        if not track_muted[t] then
            local tc = track_colors[t]
            luna.gfx.setColor(tc[1], tc[2], tc[3], 0.6)
            local beat = math.floor(play_cursor) + 1
            local active = 0
            if beat >= 1 and beat <= GRID_COLS then
                for r = 1, GRID_ROWS do
                    if tracks[t][r][beat] then active = active + 1 end
                end
            end
            -- Draw sine-like wave scaled by active notes
            local amp = active * 6
            luna.gfx.setLineWidth(1.5)
            for px = 0, ww - 2 do
                local phase = (px / ww) * 12 + time * (3 + t) + t * 2
                local y1 = wy + wh / 2 + math.sin(phase) * amp
                local y2 = wy + wh / 2 + math.sin(phase + 0.1) * amp
                luna.gfx.line(wx + px, y1, wx + px + 1, y2)
            end
        end
    end
    luna.gfx.setLineWidth(1)
end

function luna.render()
    luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)

    -- Title bar
    luna.gfx.setColor(0.9, 0.7, 1, 1)
    luna.gfx.print("Music Composer", 10, 5, 1.2)
    luna.gfx.setColor(0.7, 0.7, 0.8, 1)
    luna.gfx.print("Track: " .. track_names[current_track], 200, 8, 0.85)
    luna.gfx.print("BPM: " .. bpm, 370, 8, 0.85)
    luna.gfx.print(playing and "PLAYING" or "STOPPED", 460, 8, 0.85)
    luna.gfx.print(looping and "[LOOP]" or "", 560, 8, 0.85)

    -- Controls
    luna.gfx.setColor(0.5, 0.5, 0.55, 1)
    luna.gfx.print("Space=play/stop | 1/2/3=track | Up/Down=BPM | L=loop | C=clear | M=mute | E=export | Esc=quit", 10, 30, 0.55)
    luna.gfx.print("Left-click=toggle note | Right-click=long note (2-4 beats)", 10, 42, 0.55)

    -- Note labels (left side)
    for r = 1, GRID_ROWS do
        local label = note_label(r)
        local sharp = is_sharp(r)
        if sharp then
            luna.gfx.setColor(0.6, 0.5, 0.7, 1)
        else
            luna.gfx.setColor(0.7, 0.7, 0.75, 1)
        end
        luna.gfx.print(label, OX - 40, OY + (r - 1) * CELL_H + 1, 0.55)
    end

    -- Beat numbers (top)
    for c = 1, GRID_COLS do
        local is_measure = (c - 1) % 4 == 0
        if is_measure then
            luna.gfx.setColor(0.8, 0.8, 0.5, 1)
        else
            luna.gfx.setColor(0.4, 0.4, 0.4, 1)
        end
        luna.gfx.print(tostring(c), OX + (c - 1) * CELL_W + 4, OY - 14, 0.5)
    end

    -- Grid
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local gx = OX + (c - 1) * CELL_W
            local gy = OY + (r - 1) * CELL_H

            -- Background
            local sharp = is_sharp(r)
            local is_measure_line = (c - 1) % 4 == 0
            if sharp then
                luna.gfx.setColor(0.12, 0.12, 0.16, 1)
            else
                luna.gfx.setColor(0.14, 0.14, 0.18, 1)
            end
            luna.gfx.rectangle("fill", gx, gy, CELL_W - 1, CELL_H - 1)

            -- Measure lines
            if is_measure_line then
                luna.gfx.setColor(0.3, 0.3, 0.35, 0.6)
                luna.gfx.line(gx, gy, gx, gy + CELL_H)
            end

            -- Draw notes from all visible tracks (current track on top)
            for t = 1, 3 do
                if tracks[t][r][c] then
                    local tc = track_colors[t]
                    local alpha = (t == current_track) and 0.9 or 0.35
                    if track_muted[t] then alpha = alpha * 0.3 end
                    luna.gfx.setColor(tc[1], tc[2], tc[3], alpha)
                    luna.gfx.rectangle("fill", gx + 1, gy + 1, CELL_W - 3, CELL_H - 3)
                end
            end
        end
    end

    -- Play cursor
    if playing then
        local cx = OX + play_cursor * CELL_W
        luna.gfx.setColor(1, 1, 1, 0.7)
        luna.gfx.setLineWidth(2)
        luna.gfx.line(cx, OY, cx, OY + GRID_ROWS * CELL_H)
        luna.gfx.setLineWidth(1)

        -- Highlight active notes
        local beat = math.floor(play_cursor) + 1
        if beat >= 1 and beat <= GRID_COLS then
            for t = 1, 3 do
                if not track_muted[t] then
                    for r = 1, GRID_ROWS do
                        if tracks[t][r][beat] then
                            local gx = OX + (beat - 1) * CELL_W
                            local gy = OY + (r - 1) * CELL_H
                            luna.gfx.setColor(1, 1, 1, 0.4)
                            luna.gfx.rectangle("fill", gx, gy, CELL_W - 1, CELL_H - 1)
                        end
                    end
                end
            end
        end
    end

    -- Track status panel
    local px = OX + GRID_COLS * CELL_W + 15
    luna.gfx.setColor(0.8, 0.75, 0.9, 1)
    luna.gfx.print("Tracks:", px, OY, 0.85)
    for t = 1, 3 do
        local ty = OY + 22 + (t - 1) * 30
        local tc = track_colors[t]
        if t == current_track then
            luna.gfx.setColor(tc[1], tc[2], tc[3], 1)
            luna.gfx.rectangle("fill", px, ty, 10, 14)
            luna.gfx.setColor(1, 1, 1, 1)
        else
            luna.gfx.setColor(tc[1], tc[2], tc[3], 0.5)
            luna.gfx.rectangle("fill", px, ty, 10, 14)
            luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        end
        local mute_txt = track_muted[t] and " [M]" or ""
        luna.gfx.print(t .. " " .. track_names[t] .. mute_txt, px + 14, ty, 0.7)
    end

    -- Time signature and info
    luna.gfx.setColor(0.6, 0.6, 0.7, 1)
    luna.gfx.print("4/4 time", px, OY + 120, 0.7)
    luna.gfx.print(GRID_COLS .. " beats", px, OY + 138, 0.7)
    luna.gfx.print(math.floor(GRID_COLS / 4) .. " measures", px, OY + 156, 0.7)

    -- Waveform
    draw_waveform()

    -- Export overlay
    if show_export then
        luna.gfx.setColor(0, 0, 0, 0.85)
        luna.gfx.rectangle("fill", 40, 40, 700, 400)
        luna.gfx.setColor(0.4, 0.4, 0.6, 1)
        luna.gfx.rectangle("line", 40, 40, 700, 400)
        luna.gfx.setColor(1, 0.9, 0.5, 1)
        luna.gfx.print("Note Export (press E or Esc to close)", 60, 50, 1)
        luna.gfx.setColor(0.85, 0.85, 0.9, 1)
        -- Print export text line by line
        local line_y = 80
        for line in export_text:gmatch("[^\n]+") do
            luna.gfx.print(line, 60, line_y, 0.65)
            line_y = line_y + 16
            if line_y > 420 then break end
        end
    end

    luna.gfx.setColor(0.4, 0.4, 0.4, 1)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 730, 5, 0.6)
end
