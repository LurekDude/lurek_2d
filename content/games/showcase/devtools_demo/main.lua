-- ============================================================================
-- Devtools Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/devtools_demo/main.lua
-- Run with : cargo run -- content/games/showcase/devtools_demo
-- ============================================================================
-- Developer tools profiling showcase: FPS overlay, memory profiler, entity
-- inspector, performance heatmap, and draw call counter — all toggled live.
-- Controls: F1–F5 toggle panels, Tab cycle, Space spawn, S stress,
--           M slow-mo, E export, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local BALL_MIN_R, BALL_MAX_R = 6, 14
local GRAVITY = 300
local HISTORY_SIZE = 240
local PANEL_W = 260
local PANEL_H = 160
local PANEL_MARGIN = 10

local STATE = { TITLE = 1, RUNNING = 2 }
local current_state = STATE.TITLE

-- ---------------------------------------------------------------------------
-- Ball pool
-- ---------------------------------------------------------------------------
local balls = {}
local draw_call_count = 0
local total_spawned = 0

-- ---------------------------------------------------------------------------
-- Profiling state
-- ---------------------------------------------------------------------------
local show_fps       = false
local show_memory    = false
local show_inspector = false
local show_heatmap   = false
local show_drawcalls = false
local active_panel   = 0       -- 0 = none, 1–5 = panels

local frame_history  = {}      -- ring buffer of frame times
local frame_index    = 1
local fps_value      = 0
local frame_time_ms  = 0
local smoothed_fps   = 60

local mem_objects     = 0
local mem_bytes_est   = 0
local peak_mem_bytes  = 0

local time_scale     = 1.0
local export_text    = nil
local export_timer   = 0

-- ---------------------------------------------------------------------------
-- Particles
-- ---------------------------------------------------------------------------
local ps_spawn  = nil
local ps_stress = nil

-- ---------------------------------------------------------------------------
-- Tween / animation
-- ---------------------------------------------------------------------------
local panel_offsets = { 0, 0, 0, 0, 0 }   -- slide-in X offset per panel
local title_alpha = 0
local title_scale = 0.5

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t) return a + (b - a) * t end

local function rand_range(lo, hi) return lo + math.random() * (hi - lo) end

local function new_ball(x, y)
    local r = rand_range(BALL_MIN_R, BALL_MAX_R)
    local b = {
        x  = x or rand_range(r, SCREEN_W - r),
        y  = y or rand_range(r, SCREEN_H * 0.3),
        vx = rand_range(-120, 120),
        vy = rand_range(-80, 80),
        r  = r,
        cr = 0.2 + math.random() * 0.6,
        cg = 0.2 + math.random() * 0.6,
        cb = 0.4 + math.random() * 0.6,
    }
    balls[#balls + 1] = b
    total_spawned = total_spawned + 1
    mem_objects = #balls
    mem_bytes_est = mem_objects * 72
    if mem_bytes_est > peak_mem_bytes then peak_mem_bytes = mem_bytes_est end
    return b
end

local function spawn_batch(count, x, y)
    for _ = 1, count do new_ball(x, y) end
end

local function record_frame_time(dt_ms)
    frame_history[frame_index] = dt_ms
    frame_index = frame_index % HISTORY_SIZE + 1
end

local function avg_frame_time()
    local sum, n = 0, 0
    for i = 1, HISTORY_SIZE do
        if frame_history[i] then sum = sum + frame_history[i]; n = n + 1 end
    end
    return n > 0 and (sum / n) or 16.67
end

local function heatmap_color(ms)
    if ms < 8 then return 0.2, 0.85, 0.3, 0.7 end
    if ms < 16 then return 0.95, 0.85, 0.2, 0.7 end
    return 0.95, 0.2, 0.15, 0.8
end

local function animate_panel(index, visible)
    local target = visible and 0 or (-PANEL_W - 20)
    lurek.tween.to(0.35, function(t)
        panel_offsets[index] = lerp(panel_offsets[index], target, t)
    end, { ease = "outQuad" })
end

-- ---------------------------------------------------------------------------
-- Input bindings
-- ---------------------------------------------------------------------------
local function bind_inputs()
    lurek.input.bind("toggle_fps",       { "f1" })
    lurek.input.bind("toggle_memory",    { "f2" })
    lurek.input.bind("toggle_inspector", { "f3" })
    lurek.input.bind("toggle_heatmap",   { "f4" })
    lurek.input.bind("toggle_drawcalls", { "f5" })
    lurek.input.bind("spawn",            { "space" })
    lurek.input.bind("stress",           { "s" })
    lurek.input.bind("slowmo",           { "m" })
    lurek.input.bind("export",           { "e" })
    lurek.input.bind("cycle_panel",      { "tab" })
    lurek.input.bind("quit",             { "escape" })
end

-- ── Initialization ─────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Devtools Demo — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.1)
    bind_inputs()

    -- Pre-fill frame history
    for i = 1, HISTORY_SIZE do frame_history[i] = 16.67 end

    -- Particle systems
    ps_spawn = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0,
        lifetimeMin = 0.3, lifetimeMax = 0.6,
        speedMin = 40, speedMax = 100, direction = -1.57, spread = 3.14,
        sizes = { 3, 1 }, colors = { 0.3, 0.7, 1, 1, 0.1, 0.3, 0.8, 0 },
    })
    ps_stress = lurek.particle.newSystem({
        maxParticles = 100, emissionRate = 0,
        lifetimeMin = 0.5, lifetimeMax = 1.0,
        speedMin = 20, speedMax = 60, direction = -1.57, spread = 6.28,
        sizes = { 5, 2, 0 }, colors = { 1, 0.3, 0.1, 1, 1, 0.8, 0.1, 0 },
    })

    -- Initial panel offsets (off-screen)
    for i = 1, 5 do panel_offsets[i] = -PANEL_W - 20 end

    -- Title tween
    lurek.tween.to(0.8, function(t)
        title_alpha = t
        title_scale = lerp(0.5, 1.0, t)
    end, { ease = "outBack" })

    -- Start with a few balls
    spawn_batch(50)
end

-- ── Update ─────────────────────────────────────────────────────────────────
function lurek.process(dt)
    local scaled_dt = dt * time_scale
    frame_time_ms = dt * 1000
    record_frame_time(frame_time_ms)
    smoothed_fps = lerp(smoothed_fps, 1.0 / math.max(dt, 0.0001), 0.1)
    fps_value = math.floor(smoothed_fps + 0.5)

    -- Particle updates
    ps_spawn:update(dt)
    ps_stress:update(dt)
    lurek.tween.update(dt)

    -- Export timer
    if export_timer > 0 then
        export_timer = export_timer - dt
        if export_timer <= 0 then export_text = nil end
    end

    -- ── TITLE ──────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("spawn") or lurek.input.wasActionPressed("cycle_panel") then
            current_state = STATE.RUNNING
        end
        return
    end

    -- ── RUNNING — input ────────────────────────────────────────
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    if lurek.input.wasActionPressed("toggle_fps") then
        show_fps = not show_fps
        animate_panel(1, show_fps)
    end
    if lurek.input.wasActionPressed("toggle_memory") then
        show_memory = not show_memory
        animate_panel(2, show_memory)
    end
    if lurek.input.wasActionPressed("toggle_inspector") then
        show_inspector = not show_inspector
        animate_panel(3, show_inspector)
    end
    if lurek.input.wasActionPressed("toggle_heatmap") then
        show_heatmap = not show_heatmap
        animate_panel(4, show_heatmap)
    end
    if lurek.input.wasActionPressed("toggle_drawcalls") then
        show_drawcalls = not show_drawcalls
        animate_panel(5, show_drawcalls)
    end

    if lurek.input.wasActionPressed("cycle_panel") then
        -- close current
        if active_panel > 0 then
            local panels = { "show_fps", "show_memory", "show_inspector", "show_heatmap", "show_drawcalls" }
            local flags = { show_fps, show_memory, show_inspector, show_heatmap, show_drawcalls }
            if flags[active_panel] then
                -- already open, skip
            end
        end
        active_panel = active_panel % 5 + 1
        show_fps       = (active_panel == 1)
        show_memory    = (active_panel == 2)
        show_inspector = (active_panel == 3)
        show_heatmap   = (active_panel == 4)
        show_drawcalls = (active_panel == 5)
        for i = 1, 5 do animate_panel(i, i == active_panel) end
    end

    if lurek.input.wasActionPressed("spawn") then
        spawn_batch(10, SCREEN_W * 0.5, SCREEN_H * 0.2)
        ps_spawn:emit(20)
        ps_spawn:moveTo(SCREEN_W * 0.5, SCREEN_H * 0.2)
    end

    if lurek.input.wasActionPressed("stress") then
        spawn_batch(200, SCREEN_W * 0.5, SCREEN_H * 0.1)
        ps_stress:emit(80)
        ps_stress:moveTo(SCREEN_W * 0.5, SCREEN_H * 0.1)
    end

    if lurek.input.wasActionPressed("slowmo") then
        time_scale = (time_scale < 1.0) and 1.0 or 0.25
    end

    if lurek.input.wasActionPressed("export") then
        local avg_ms = avg_frame_time()
        export_text = string.format(
            "PROFILING EXPORT\n" ..
            "Balls: %d | Total spawned: %d\n" ..
            "Avg frame: %.2f ms | FPS: %d\n" ..
            "Mem est: %.1f KB | Peak: %.1f KB\n" ..
            "Time scale: %.2fx",
            #balls, total_spawned, avg_ms, fps_value,
            mem_bytes_est / 1024, peak_mem_bytes / 1024, time_scale
        )
        export_timer = 4.0
    end

    -- ── RUNNING — physics ──────────────────────────────────────
    for i = 1, #balls do
        local b = balls[i]
        b.vy = b.vy + GRAVITY * scaled_dt
        b.x  = b.x + b.vx * scaled_dt
        b.y  = b.y + b.vy * scaled_dt

        -- Wall bounce
        if b.x - b.r < 0 then
            b.x = b.r; b.vx = math.abs(b.vx) * 0.95
        elseif b.x + b.r > SCREEN_W then
            b.x = SCREEN_W - b.r; b.vx = -math.abs(b.vx) * 0.95
        end
        if b.y - b.r < 0 then
            b.y = b.r; b.vy = math.abs(b.vy) * 0.95
        elseif b.y + b.r > SCREEN_H then
            b.y = SCREEN_H - b.r; b.vy = -math.abs(b.vy) * 0.85
        end
    end

    -- Track memory
    mem_objects = #balls
    mem_bytes_est = mem_objects * 72
    if mem_bytes_est > peak_mem_bytes then peak_mem_bytes = mem_bytes_est end
end

-- ── Draw (game scene) ──────────────────────────────────────────────────────
function lurek.render()
    draw_call_count = 0

    if current_state == STATE.TITLE then
        -- Title screen
        lurek.render.setColor(0.3, 0.6, 1.0, title_alpha)
        lurek.render.print("DEVTOOLS DEMO", SCREEN_W * 0.5 - 120, SCREEN_H * 0.3)
        lurek.render.setColor(0.5, 0.8, 1.0, title_alpha * 0.7)
        lurek.render.print("PROFILING & DIAGNOSTICS", SCREEN_W * 0.5 - 140, SCREEN_H * 0.3 + 32)
        lurek.render.setColor(0.7, 0.7, 0.7, title_alpha * 0.5)
        lurek.render.print("Press SPACE or TAB to start", SCREEN_W * 0.5 - 130, SCREEN_H * 0.6)
        draw_call_count = draw_call_count + 3
        return
    end

    -- Draw balls
    for i = 1, #balls do
        local b = balls[i]
        lurek.render.setColor(b.cr, b.cg, b.cb, 0.9)
        lurek.render.circle("fill", b.x, b.y, b.r)
        draw_call_count = draw_call_count + 1
    end

    -- Particles
    lurek.render.setColor(1, 1, 1, 1)
    ps_spawn:draw()
    ps_stress:draw()
    draw_call_count = draw_call_count + 2
end

-- ── Draw UI (overlays) ─────────────────────────────────────────────────────
function lurek.render_ui()
    if current_state == STATE.TITLE then return end

    local py = PANEL_MARGIN

    -- ── F1: FPS overlay ────────────────────────────────────────
    if show_fps or panel_offsets[1] > -PANEL_W then
        local px = SCREEN_W - PANEL_W - PANEL_MARGIN + panel_offsets[1]
        lurek.render.setColor(0.0, 0.0, 0.0, 0.75)
        lurek.render.rectangle("fill", px, py, PANEL_W, PANEL_H)
        lurek.render.setColor(0.3, 0.8, 1.0, 1)
        lurek.render.print(string.format("FPS: %d  (%.2f ms)", fps_value, frame_time_ms), px + 8, py + 6)

        -- Frame time graph (line)
        local gx, gy, gw, gh = px + 8, py + 28, PANEL_W - 16, PANEL_H - 38
        lurek.render.setColor(0.15, 0.15, 0.2, 0.8)
        lurek.render.rectangle("fill", gx, gy, gw, gh)

        -- 16ms reference line
        local ref_y = gy + gh - (16 / 33) * gh
        lurek.render.setColor(0.5, 0.5, 0.2, 0.5)
        lurek.render.line(gx, ref_y, gx + gw, ref_y)

        -- Graph lines
        local step = gw / HISTORY_SIZE
        for j = 2, HISTORY_SIZE do
            local idx_prev = ((frame_index - 2 + j - 2) % HISTORY_SIZE) + 1
            local idx_curr = ((frame_index - 2 + j - 1) % HISTORY_SIZE) + 1
            local v0 = clamp((frame_history[idx_prev] or 16.67) / 33, 0, 1)
            local v1 = clamp((frame_history[idx_curr] or 16.67) / 33, 0, 1)
            local x0 = gx + (j - 2) * step
            local y0 = gy + gh - v0 * gh
            local x1 = gx + (j - 1) * step
            local y1 = gy + gh - v1 * gh
            local r, g, b, a = heatmap_color(frame_history[idx_curr] or 16.67)
            lurek.render.setColor(r, g, b, a)
            lurek.render.line(x0, y0, x1, y1)
        end
        draw_call_count = draw_call_count + HISTORY_SIZE + 4
    end

    -- ── F2: Memory profiler ────────────────────────────────────
    py = py + PANEL_H + PANEL_MARGIN
    if show_memory or panel_offsets[2] > -PANEL_W then
        local px = SCREEN_W - PANEL_W - PANEL_MARGIN + panel_offsets[2]
        lurek.render.setColor(0.0, 0.0, 0.0, 0.75)
        lurek.render.rectangle("fill", px, py, PANEL_W, 90)
        lurek.render.setColor(0.2, 0.9, 0.4, 1)
        lurek.render.print(string.format("Objects: %d", mem_objects), px + 8, py + 6)
        lurek.render.print(string.format("Est: %.1f KB / Peak: %.1f KB", mem_bytes_est / 1024, peak_mem_bytes / 1024), px + 8, py + 24)

        -- Usage bar
        local bar_x, bar_y, bar_w, bar_h = px + 8, py + 48, PANEL_W - 16, 16
        local fill = clamp(mem_bytes_est / math.max(peak_mem_bytes, 1), 0, 1)
        lurek.render.setColor(0.15, 0.15, 0.2, 1)
        lurek.render.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
        lurek.render.setColor(0.2, 0.8, 0.4, 0.9)
        lurek.render.rectangle("fill", bar_x, bar_y, bar_w * fill, bar_h)
        lurek.render.setColor(0.3, 0.9, 0.5, 1)
        lurek.render.print(string.format("%.0f%%", fill * 100), bar_x + bar_w * 0.5 - 12, py + 70)
        draw_call_count = draw_call_count + 7
    end

    -- ── F3: Entity inspector ───────────────────────────────────
    py = py + 100 + PANEL_MARGIN
    if show_inspector or panel_offsets[3] > -PANEL_W then
        local px = SCREEN_W - PANEL_W - PANEL_MARGIN + panel_offsets[3]
        local rows = math.min(#balls, 8)
        local h = 28 + rows * 16
        lurek.render.setColor(0.0, 0.0, 0.0, 0.75)
        lurek.render.rectangle("fill", px, py, PANEL_W, h)
        lurek.render.setColor(1.0, 0.8, 0.3, 1)
        lurek.render.print(string.format("Entities: %d", #balls), px + 8, py + 6)

        for j = 1, rows do
            local b = balls[j]
            local txt = string.format("#%d  (%.0f,%.0f) v=(%.0f,%.0f)", j, b.x, b.y, b.vx, b.vy)
            lurek.render.setColor(0.8, 0.8, 0.7, 0.85)
            lurek.render.print(txt, px + 8, py + 12 + j * 16)
        end
        if #balls > 8 then
            lurek.render.setColor(0.6, 0.6, 0.5, 0.6)
            lurek.render.print(string.format("... +%d more", #balls - 8), px + 8, py + 12 + (rows + 1) * 16)
        end
        draw_call_count = draw_call_count + rows + 3
    end

    -- ── F4: Performance heatmap ────────────────────────────────
    if show_heatmap or panel_offsets[4] > -PANEL_W then
        local px = PANEL_MARGIN + panel_offsets[4]
        local hm_w, hm_h = 240, 40
        local hm_y = SCREEN_H - hm_h - PANEL_MARGIN
        lurek.render.setColor(0.0, 0.0, 0.0, 0.75)
        lurek.render.rectangle("fill", px, hm_y, hm_w, hm_h)
        lurek.render.setColor(0.9, 0.9, 0.9, 1)
        lurek.render.print("Frame Heatmap", px + 4, hm_y + 2)

        local block_w = hm_w / 60
        for j = 1, 60 do
            local idx = ((frame_index - 2 + (j - 1) * 4) % HISTORY_SIZE) + 1
            local ms = frame_history[idx] or 16.67
            local r, g, b, a = heatmap_color(ms)
            lurek.render.setColor(r, g, b, a)
            lurek.render.rectangle("fill", px + (j - 1) * block_w, hm_y + 18, block_w - 1, 18)
        end
        draw_call_count = draw_call_count + 62
    end

    -- ── F5: Draw call counter ──────────────────────────────────
    if show_drawcalls or panel_offsets[5] > -PANEL_W then
        local px = PANEL_MARGIN + panel_offsets[5]
        local dc_y = SCREEN_H - 90 - PANEL_MARGIN
        lurek.render.setColor(0.0, 0.0, 0.0, 0.75)
        lurek.render.rectangle("fill", px, dc_y, 200, 40)
        lurek.render.setColor(1.0, 0.5, 0.2, 1)
        lurek.render.print(string.format("Draw calls: %d", draw_call_count), px + 8, dc_y + 6)
        lurek.render.setColor(0.8, 0.8, 0.8, 0.7)
        lurek.render.print(string.format("Balls: %d | Particles: 2", #balls), px + 8, dc_y + 22)
        draw_call_count = draw_call_count + 4
    end

    -- ── Slow-mo indicator ──────────────────────────────────────
    if time_scale < 1.0 then
        lurek.render.setColor(1, 0.3, 0.3, 0.9)
        lurek.render.print(string.format("SLOW-MO (%.2fx)", time_scale), PANEL_MARGIN, PANEL_MARGIN)
    end

    -- ── Export overlay ─────────────────────────────────────────
    if export_text then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.85)
        lurek.render.rectangle("fill", SCREEN_W * 0.5 - 180, SCREEN_H * 0.5 - 60, 360, 120)
        lurek.render.setColor(0.2, 1.0, 0.6, 1)
        lurek.render.print(export_text, SCREEN_W * 0.5 - 170, SCREEN_H * 0.5 - 50)
    end

    -- ── Bottom HUD ─────────────────────────────────────────────
    lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
    lurek.render.print(
        "F1:FPS  F2:Mem  F3:Inspector  F4:Heatmap  F5:DrawCalls  Tab:Cycle  Space:+10  S:+200  M:SlowMo  E:Export",
        8, SCREEN_H - 18
    )
    lurek.render.setColor(0.6, 0.6, 0.6, 0.5)
    lurek.render.print(string.format("FPS: %d", fps_value), SCREEN_W - 70, 4)
end
