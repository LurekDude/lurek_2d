-- Rhythm Game — Lurek2D
-- Category: sports
-- A 4-lane rhythm game with scrolling notes, timing windows, combos, and hold notes.

-- Constants
local W, H = 800, 600
local LANE_W = 150
local LANE_GAP = 40
local LANE_COUNT = 4
local TOTAL_LANE_W = LANE_COUNT * LANE_W + (LANE_COUNT - 1) * LANE_GAP
local LANE_START_X = (W - TOTAL_LANE_W) / 2
local HIT_ZONE_Y = 520
local HIT_ZONE_H = 8
local NOTE_W = 20
local NOTE_H = 40
local PERFECT_WINDOW = 2   -- pixels (±30ms at 60fps ≈ ±2px)
local GOOD_WINDOW = 4      -- pixels (±60ms)
local PERFECT_PTS = 300
local GOOD_PTS = 100
local HOLD_PTS_PER_FRAME = 10
local LIFE_MAX = 100
local MISS_PENALTY = 10
local PERFECT_HEAL = 2

-- States
local STATE_TITLE = 1
local STATE_SONG_SELECT = 2
local STATE_PLAYING = 3
local STATE_RESULTS = 4
local current_state = STATE_TITLE

-- Lane colors
local LANE_COLORS = {
    { 0.9, 0.2, 0.2 },  -- red
    { 0.2, 0.4, 0.9 },  -- blue
    { 0.2, 0.8, 0.3 },  -- green
    { 0.9, 0.8, 0.2 },  -- yellow
}

-- Lane key names (mapped via lurek.input.bind)
local LANE_KEYS = { "lane1", "lane2", "lane3", "lane4" }

-- ---------------------------------------------------------------------------
-- Song chart builder helpers
-- ---------------------------------------------------------------------------
local function gen_easy_chart()
    local chart = {}
    local t = 1.0
    for i = 1, 60 do
        chart[#chart + 1] = { lane = ((i - 1) % 4) + 1, time = t, hold = (i % 12 == 0) and 0.5 or nil }
        t = t + 0.5
    end
    return chart
end

local function gen_medium_chart()
    local chart = {}
    local t = 0.8
    local patterns = { 1, 3, 2, 4, 1, 2, 3, 4, 2, 1 }
    for i = 1, 100 do
        local lane = patterns[((i - 1) % #patterns) + 1]
        chart[#chart + 1] = { lane = lane, time = t, hold = (i % 8 == 0) and 0.4 or nil }
        t = t + 0.35
    end
    return chart
end

local function gen_hard_chart()
    local chart = {}
    local t = 0.5
    for i = 1, 150 do
        local lane = ((i * 3 + i % 7) % 4) + 1
        chart[#chart + 1] = { lane = lane, time = t, hold = (i % 6 == 0) and 0.35 or nil }
        t = t + 0.22
    end
    return chart
end

local SONGS = {
    { name = "Easy Beat",     speed = 200, chart_fn = gen_easy_chart },
    { name = "Medium Groove", speed = 300, chart_fn = gen_medium_chart },
    { name = "Hard Rush",     speed = 400, chart_fn = gen_hard_chart },
}

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local camera = nil
local title_timer = 0
local selected_song = 1
local song_speed = 200
local notes = {}          -- active notes: { lane, y, hold_len, hold_rem, hit, held }
local next_note_idx = 1   -- index into current chart
local chart = {}
local song_time = 0
local score = 0
local display_score = 0
local combo = 0
local max_combo = 0
local life = LIFE_MAX
local display_life = LIFE_MAX
local perfects = 0
local goods = 0
local misses = 0
local total_notes_in_song = 0
local lane_glow = { 0, 0, 0, 0 }    -- glow alpha per lane
local hit_flash = { 0, 0, 0, 0 }    -- flash timer per lane
local bg_pulse = 0
local result_grade = "F"

-- Particles
local hit_particles = nil
local combo_particles = nil

-- Tweens
local score_tween = nil
local life_tween = nil
local hit_zone_pulse = 0

-- Lane press state (for hold notes)
local lane_held = { false, false, false, false }
local lane_just_pressed = { false, false, false, false }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function get_multiplier()
    if combo >= 50 then return 4
    elseif combo >= 25 then return 3
    elseif combo >= 10 then return 2
    else return 1 end
end

local function lane_center_x(lane)
    return LANE_START_X + (lane - 1) * (LANE_W + LANE_GAP) + LANE_W / 2
end

local function calc_grade()
    local total = perfects + goods + misses
    if total == 0 then return "F" end
    local pct = (perfects * PERFECT_PTS + goods * GOOD_PTS) / (total * PERFECT_PTS) * 100
    if pct > 95 then return "S"
    elseif pct > 85 then return "A"
    elseif pct > 75 then return "B"
    elseif pct > 60 then return "C"
    else return "F" end
end

-- ---------------------------------------------------------------------------
-- Start a song
-- ---------------------------------------------------------------------------
local function start_song(idx)
    local song = SONGS[idx]
    song_speed = song.speed
    chart = song.chart_fn()
    total_notes_in_song = #chart
    notes = {}
    next_note_idx = 1
    song_time = 0
    score = 0
    display_score = 0
    combo = 0
    max_combo = 0
    life = LIFE_MAX
    display_life = LIFE_MAX
    perfects = 0
    goods = 0
    misses = 0
    lane_glow = { 0, 0, 0, 0 }
    hit_flash = { 0, 0, 0, 0 }
    bg_pulse = 0
    lane_held = { false, false, false, false }
    current_state = STATE_PLAYING
end

-- ---------------------------------------------------------------------------
-- Process a hit on a lane
-- ---------------------------------------------------------------------------
local function process_hit(lane)
    local best_note = nil
    local best_dist = 999999
    for i, n in ipairs(notes) do
        if n.lane == lane and not n.hit then
            local dist = math.abs(n.y - HIT_ZONE_Y)
            if dist < best_dist then
                best_dist = dist
                best_note = n
            end
        end
    end

    if best_note and best_dist <= GOOD_WINDOW * (song_speed / 60) then
        local mult = get_multiplier()
        if best_dist <= PERFECT_WINDOW * (song_speed / 60) then
            -- Perfect
            score = score + PERFECT_PTS * mult
            perfects = perfects + 1
            combo = combo + 1
            life = clamp(life + PERFECT_HEAL, 0, LIFE_MAX)
            hit_flash[lane] = 0.4
            if hit_particles then
                lurek.particle.emit(hit_particles, lane_center_x(lane), HIT_ZONE_Y, 20)
            end
        else
            -- Good
            score = score + GOOD_PTS * mult
            goods = goods + 1
            combo = combo + 1
            hit_flash[lane] = 0.25
        end
        if best_note.hold_rem and best_note.hold_rem > 0 then
            best_note.held = true
        else
            best_note.hit = true
        end
        if combo > max_combo then max_combo = combo end
        lane_glow[lane] = 1.0

        -- Combo milestone particles
        if combo > 0 and combo % 10 == 0 and combo_particles then
            lurek.particle.emit(combo_particles, W / 2, H / 2, 40)
        end

        -- Tweens
        if lurek.tween then
            score_tween = lurek.tween.new(0.3, { val = display_score }, { val = score }, "outQuad")
            life_tween = lurek.tween.new(0.3, { val = display_life }, { val = life }, "outQuad")
        end
        hit_zone_pulse = 1.0
    else
        -- Miss (pressed but no note nearby)
        misses = misses + 1
        combo = 0
        life = clamp(life - MISS_PENALTY, 0, LIFE_MAX)
        if lurek.tween then
            life_tween = lurek.tween.new(0.3, { val = display_life }, { val = life }, "outQuad")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Engine callbacks
-- ---------------------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Rhythm Game — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.02, 0.08)

    camera = lurek.camera.new()
    camera:setPosition(0, 0)

    -- Input bindings
    lurek.input.bind("lane1", "d")
    lurek.input.bind("lane2", "f")
    lurek.input.bind("lane3", "j")
    lurek.input.bind("lane4", "k")
    lurek.input.bind("quit", "escape")
    lurek.input.bind("confirm", "return")
    lurek.input.bind("nav_up", "up")
    lurek.input.bind("nav_down", "down")

    -- Particles: hit burst
    if lurek.particle then
        hit_particles = lurek.particle.new()
        lurek.particle.setColors(hit_particles, { { 1, 0.85, 0.2, 1 }, { 1, 0.5, 0.1, 0 } })
        lurek.particle.setSpeed(hit_particles, 80, 200)
        lurek.particle.setLifetime(hit_particles, 0.3, 0.6)
        lurek.particle.setSize(hit_particles, 4, 1)
        lurek.particle.setSpread(hit_particles, math.pi * 2)

        combo_particles = lurek.particle.new()
        lurek.particle.setColors(combo_particles, { { 1, 1, 1, 1 }, { 0.5, 0.8, 1, 0 } })
        lurek.particle.setSpeed(combo_particles, 100, 300)
        lurek.particle.setLifetime(combo_particles, 0.5, 1.0)
        lurek.particle.setSize(combo_particles, 6, 2)
        lurek.particle.setSpread(combo_particles, math.pi * 2)
    end
end

local function _ready_setup()
    lurek.window.setTitle("Rhythm Game — Lurek2D")
end

function lurek.process(dt)
    local fps = lurek.timer.getFPS()
    title_timer = title_timer + dt

    -- Quit
    if lurek.input.pressed("quit") then
        if current_state == STATE_PLAYING then
            current_state = STATE_RESULTS
            result_grade = calc_grade()
        elseif current_state == STATE_SONG_SELECT then
            current_state = STATE_TITLE
        elseif current_state == STATE_RESULTS then
            current_state = STATE_SONG_SELECT
        else
            lurek.event.signal("quit")
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- TITLE
    -- -----------------------------------------------------------------------
    if current_state == STATE_TITLE then
        if lurek.input.pressed("confirm") then
            current_state = STATE_SONG_SELECT
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- SONG SELECT
    -- -----------------------------------------------------------------------
    if current_state == STATE_SONG_SELECT then
        if lurek.input.pressed("nav_up") then
            selected_song = selected_song - 1
            if selected_song < 1 then selected_song = #SONGS end
        end
        if lurek.input.pressed("nav_down") then
            selected_song = selected_song + 1
            if selected_song > #SONGS then selected_song = 1 end
        end
        if lurek.input.pressed("confirm") then
            start_song(selected_song)
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- RESULTS
    -- -----------------------------------------------------------------------
    if current_state == STATE_RESULTS then
        if lurek.input.pressed("confirm") then
            current_state = STATE_SONG_SELECT
        end
        return
    end

    -- -----------------------------------------------------------------------
    -- PLAYING
    -- -----------------------------------------------------------------------
    song_time = song_time + dt

    -- Update lane input state
    for i = 1, LANE_COUNT do
        local was_held = lane_held[i]
        lane_held[i] = lurek.input.down(LANE_KEYS[i])
        lane_just_pressed[i] = lane_held[i] and not was_held
    end

    -- Spawn notes from chart
    while next_note_idx <= #chart do
        local cn = chart[next_note_idx]
        if cn.time <= song_time + (HIT_ZONE_Y / song_speed) then
            local hold_len = cn.hold and (cn.hold * song_speed) or nil
            notes[#notes + 1] = {
                lane = cn.lane,
                y = -NOTE_H,
                hold_len = hold_len,
                hold_rem = hold_len,
                hit = false,
                held = false,
            }
            next_note_idx = next_note_idx + 1
        else
            break
        end
    end

    -- Move notes downward
    for i = #notes, 1, -1 do
        local n = notes[i]
        if not n.hit then
            n.y = n.y + song_speed * dt
        end

        -- Hold note: if being held, consume tail
        if n.held and n.hold_rem and n.hold_rem > 0 then
            if lane_held[n.lane] then
                n.hold_rem = n.hold_rem - song_speed * dt
                score = score + HOLD_PTS_PER_FRAME * get_multiplier()
                if n.hold_rem <= 0 then
                    n.hit = true
                    n.hold_rem = 0
                end
            else
                -- Released early: miss
                n.hit = true
                n.held = false
                misses = misses + 1
                combo = 0
                life = clamp(life - MISS_PENALTY / 2, 0, LIFE_MAX)
            end
        end

        -- Passed hit zone without being hit → miss
        if not n.hit and not n.held and n.y > HIT_ZONE_Y + GOOD_WINDOW * (song_speed / 60) + NOTE_H then
            n.hit = true
            misses = misses + 1
            combo = 0
            life = clamp(life - MISS_PENALTY, 0, LIFE_MAX)
            if lurek.tween then
                life_tween = lurek.tween.new(0.3, { val = display_life }, { val = life }, "outQuad")
            end
        end

        -- Remove notes well below screen
        if n.hit and n.y > H + 100 then
            table.remove(notes, i)
        end
    end

    -- Process key presses
    for i = 1, LANE_COUNT do
        if lane_just_pressed[i] then
            process_hit(i)
        end
    end

    -- Decay visual effects
    for i = 1, LANE_COUNT do
        lane_glow[i] = lane_glow[i] * (1 - 5 * dt)
        hit_flash[i] = math.max(0, hit_flash[i] - dt)
    end
    hit_zone_pulse = hit_zone_pulse * (1 - 4 * dt)
    bg_pulse = bg_pulse * (1 - 3 * dt)

    -- Pulse background with note hits
    if combo > 0 then
        bg_pulse = clamp(bg_pulse + dt * 0.5, 0, 0.3)
    end

    -- Update tweens
    if score_tween then
        score_tween:update(dt)
        display_score = score_tween.subject.val
    else
        display_score = score
    end
    if life_tween then
        life_tween:update(dt)
        display_life = life_tween.subject.val
    else
        display_life = life
    end

    -- Update particles
    if hit_particles then lurek.particle.update(hit_particles, dt) end
    if combo_particles then lurek.particle.update(combo_particles, dt) end

    -- Life check
    if life <= 0 then
        current_state = STATE_RESULTS
        result_grade = calc_grade()
    end

    -- Song end check
    if next_note_idx > #chart and #notes == 0 then
        current_state = STATE_RESULTS
        result_grade = calc_grade()
    end
end

-- ---------------------------------------------------------------------------
-- Render: lanes, notes, effects
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE_TITLE then
        -- Pulsing background
        local pulse = math.sin(title_timer * 2) * 0.05 + 0.1
        lurek.render.setBackgroundColor(0.05 + pulse, 0.02, 0.08 + pulse * 0.5)
        local cx = W / 2
        -- Title text
        local alpha = clamp(math.sin(title_timer * 1.5) * 0.3 + 0.7, 0.4, 1)
        lurek.render.print("RHYTHM GAME", cx - 120, 180, 48, 1, alpha, 0.3, alpha)
        lurek.render.print("FEEL THE BEAT", cx - 90, 250, 24, 0.7, 0.5, 0.9, alpha)
        lurek.render.print("Press ENTER to start", cx - 90, 400, 18, 0.6, 0.6, 0.6, 0.5 + math.sin(title_timer * 3) * 0.3)
        return
    end

    if current_state == STATE_SONG_SELECT then
        lurek.render.print("SELECT A SONG", W / 2 - 100, 80, 36, 0.9, 0.8, 1, 1)
        for i, song in ipairs(SONGS) do
            local yy = 180 + (i - 1) * 80
            local sel = (i == selected_song)
            local r, g, b = 0.5, 0.5, 0.5
            if sel then r, g, b = 1, 0.85, 0.2 end
            local arrow = sel and "> " or "  "
            lurek.render.print(arrow .. song.name, W / 2 - 120, yy, 28, r, g, b, 1)
            lurek.render.print(string.format("  %d notes  |  %dpx/s", #song.chart_fn(), song.speed), W / 2 - 100, yy + 32, 16, 0.5, 0.5, 0.6, 0.8)
        end
        lurek.render.print("Up/Down to select, Enter to play", W / 2 - 140, H - 60, 16, 0.4, 0.4, 0.5, 0.7)
        return
    end

    if current_state == STATE_RESULTS then
        return  -- results drawn in render_ui
    end

    -- PLAYING state
    -- Pulsing background
    local bgr = 0.05 + bg_pulse * 0.3
    local bgb = 0.08 + bg_pulse * 0.2
    lurek.render.setBackgroundColor(bgr, 0.02, bgb)

    -- Draw lane backgrounds
    for i = 1, LANE_COUNT do
        local lx = LANE_START_X + (i - 1) * (LANE_W + LANE_GAP)
        local c = LANE_COLORS[i]
        -- Lane background (dark)
        lurek.render.rectangle("fill", lx, 0, LANE_W, H, c[1] * 0.1, c[2] * 0.1, c[3] * 0.1, 0.5)
        -- Lane glow
        if lane_glow[i] > 0.01 then
            lurek.render.rectangle("fill", lx, 0, LANE_W, H, c[1], c[2], c[3], lane_glow[i] * 0.15)
        end
    end

    -- Draw hit zone
    local hz_alpha = 0.6 + hit_zone_pulse * 0.4
    lurek.render.rectangle("fill", LANE_START_X - 10, HIT_ZONE_Y - HIT_ZONE_H / 2, TOTAL_LANE_W + 20, HIT_ZONE_H, 1, 1, 1, hz_alpha * 0.3)
    -- Per-lane hit zone highlights
    for i = 1, LANE_COUNT do
        local lx = LANE_START_X + (i - 1) * (LANE_W + LANE_GAP)
        local c = LANE_COLORS[i]
        if lane_held[i] then
            lurek.render.rectangle("fill", lx, HIT_ZONE_Y - 20, LANE_W, 40, c[1], c[2], c[3], 0.4)
        end
        if hit_flash[i] > 0 then
            lurek.render.rectangle("fill", lx, HIT_ZONE_Y - 30, LANE_W, 60, 1, 1, 1, hit_flash[i])
        end
    end

    -- Draw notes
    for _, n in ipairs(notes) do
        if not n.hit or n.held then
            local c = LANE_COLORS[n.lane]
            local nx = lane_center_x(n.lane) - NOTE_W / 2
            -- Hold tail
            if n.hold_rem and n.hold_rem > 0 then
                local tail_h = n.hold_rem
                lurek.render.rectangle("fill", nx + 4, n.y - tail_h, NOTE_W - 8, tail_h, c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 0.6)
            end
            -- Note head
            local bright = 1.0
            if n.held then bright = 1.2 end
            lurek.render.rectangle("fill", nx, n.y - NOTE_H, NOTE_W, NOTE_H, c[1] * bright, c[2] * bright, c[3] * bright, 0.95)
            -- Note border
            lurek.render.rectangle("line", nx, n.y - NOTE_H, NOTE_W, NOTE_H, 1, 1, 1, 0.3)
        end
    end

    -- Draw particles
    if hit_particles then lurek.particle.draw(hit_particles) end
    if combo_particles then lurek.particle.draw(combo_particles) end
end

-- ---------------------------------------------------------------------------
-- Render UI: score, combo, life, grade
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    if current_state == STATE_RESULTS then
        -- Results screen
        local grade_colors = {
            S = { 1, 0.85, 0.2 }, A = { 0.3, 0.9, 0.3 }, B = { 0.3, 0.6, 1 },
            C = { 0.7, 0.5, 0.2 }, F = { 0.8, 0.2, 0.2 },
        }
        local gc = grade_colors[result_grade] or { 1, 1, 1 }
        lurek.render.print("RESULTS", W / 2 - 60, 60, 40, 0.9, 0.9, 1, 1)
        lurek.render.print(result_grade, W / 2 - 30, 120, 72, gc[1], gc[2], gc[3], 1)
        lurek.render.print(string.format("Score: %d", score), W / 2 - 80, 220, 24, 1, 1, 1, 0.9)
        lurek.render.print(string.format("Max Combo: %d", max_combo), W / 2 - 80, 260, 20, 0.8, 0.8, 0.8, 0.8)
        lurek.render.print(string.format("Perfect: %d  Good: %d  Miss: %d", perfects, goods, misses), W / 2 - 140, 300, 18, 0.7, 0.7, 0.7, 0.8)
        local mult_text = string.format("Best Multiplier: %dx", (max_combo >= 50 and 4) or (max_combo >= 25 and 3) or (max_combo >= 10 and 2) or 1)
        lurek.render.print(mult_text, W / 2 - 90, 340, 18, 0.6, 0.6, 0.7, 0.7)
        lurek.render.print("Press ENTER to continue", W / 2 - 100, H - 60, 16, 0.5, 0.5, 0.6, 0.6 + math.sin(title_timer * 3) * 0.3)
        return
    end

    if current_state ~= STATE_PLAYING then return end

    -- Score
    lurek.render.print(string.format("SCORE: %d", math.floor(display_score)), 10, 10, 24, 1, 1, 1, 0.9)

    -- Combo
    if combo > 0 then
        local mult = get_multiplier()
        local combo_alpha = clamp(0.6 + combo * 0.01, 0.6, 1)
        local cr, cg, cb = 1, 1, 1
        if mult >= 4 then cr, cg, cb = 1, 0.85, 0.2
        elseif mult >= 3 then cr, cg, cb = 0.9, 0.5, 1
        elseif mult >= 2 then cr, cg, cb = 0.3, 0.9, 1 end
        lurek.render.print(string.format("%d COMBO", combo), W / 2 - 50, 20, 28, cr, cg, cb, combo_alpha)
        if mult > 1 then
            lurek.render.print(string.format("%dx", mult), W / 2 + 50, 24, 20, cr, cg, cb, 0.8)
        end
    end

    -- Life bar
    local bar_w = 200
    local bar_h = 14
    local bar_x = W - bar_w - 20
    local bar_y = 12
    local life_pct = clamp(display_life / LIFE_MAX, 0, 1)
    -- Background
    lurek.render.rectangle("fill", bar_x, bar_y, bar_w, bar_h, 0.2, 0.2, 0.2, 0.7)
    -- Fill
    local lr, lg, lb = 0.2, 0.8, 0.3
    if life_pct < 0.3 then lr, lg, lb = 0.9, 0.2, 0.2
    elseif life_pct < 0.6 then lr, lg, lb = 0.9, 0.7, 0.2 end
    lurek.render.rectangle("fill", bar_x, bar_y, bar_w * life_pct, bar_h, lr, lg, lb, 0.9)
    -- Border
    lurek.render.rectangle("line", bar_x, bar_y, bar_w, bar_h, 1, 1, 1, 0.3)
    lurek.render.print("LIFE", bar_x - 40, bar_y, 14, 0.8, 0.8, 0.8, 0.7)

    -- Song progress
    local progress = 0
    if total_notes_in_song > 0 then
        progress = clamp((perfects + goods + misses) / total_notes_in_song, 0, 1)
    end
    lurek.render.rectangle("fill", 10, H - 20, (W - 20) * progress, 6, 0.4, 0.4, 0.8, 0.5)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.print(string.format("FPS: %d", fps), W - 80, H - 20, 12, 0.4, 0.4, 0.4, 0.5)
end
