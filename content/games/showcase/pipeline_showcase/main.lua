-- Pipeline Showcase — Lurek2D
-- Category: showcase
-- Visualize the full engine callback pipeline across 3 scenes

-- ============================================================
-- Constants
-- ============================================================
local SCREEN_W = 800
local SCREEN_H = 600
local PIPE_Y = 70
local PIPE_BOX_W = 100
local PIPE_BOX_H = 36
local PIPE_GAP = 18
local PIPE_COUNT = 6
local PIPE_TOTAL_W = PIPE_COUNT * PIPE_BOX_W + (PIPE_COUNT - 1) * PIPE_GAP
local PIPE_X0 = (SCREEN_W - PIPE_TOTAL_W) / 2
local SIM_Y_TOP = 140
local SIM_Y_BOT = 480
local SIM_X_LEFT = 40
local SIM_X_RIGHT = 760
local BALL_RADIUS = 12
local MAX_BALLS = 20
local GRAVITY = 300
local BALL_DAMPING = 0.85
local TITLE_FADE_IN = 1.2

-- ============================================================
-- States
-- ============================================================
local STATE_TITLE = "TITLE"
local STATE_SCENE_1 = "SCENE_1"
local STATE_SCENE_2 = "SCENE_2"
local STATE_SCENE_3 = "SCENE_3"

local state = STATE_TITLE
local title_timer = 0

local scene_names = {
    [STATE_SCENE_1] = "Menu",
    [STATE_SCENE_2] = "Simulation",
    [STATE_SCENE_3] = "Paused",
}

local scene_descs = {
    [STATE_SCENE_1] = "process + render_ui only — minimal menu footprint",
    [STATE_SCENE_2] = "ALL callbacks — balls bouncing with physics",
    [STATE_SCENE_3] = "render only — process skipped, objects frozen",
}

-- ============================================================
-- Pipeline metadata
-- ============================================================
local pipe_names = {"ready", "process", "process_physics", "process_late", "render", "render_ui"}
local pipe_labels = {"ready", "process(dt)", "process_physics(dt)", "process_late(dt)", "render()", "render_ui()"}
local pipe_short = {"RDY", "PROC", "PHYS", "LATE", "RND", "UI"}

local pipe_enabled = {true, true, true, true, true, true}
local pipe_fired = {false, false, false, false, false, false}
local pipe_times_ms = {0, 0, 0, 0, 0, 0}
local pipe_frame_counts = {0, 0, 0, 0, 0, 0}
local pipe_dt_values = {0, 0, 0, 0, 0, 0}
local pipe_highlight = {0, 0, 0, 0, 0, 0}

-- Scene callback masks: which callbacks fire per scene
local scene_masks = {
    [STATE_SCENE_1] = {false, true,  false, false, false, true },
    [STATE_SCENE_2] = {false, true,  true,  true,  true,  true },
    [STATE_SCENE_3] = {false, false, false, false, true,  true },
}

-- ============================================================
-- Helpers
-- ============================================================
local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- ============================================================
-- Particles
-- ============================================================
local particles = {}

local function spawn_particles(x, y, r, g, b, count, spread, life_base)
    count = count or 6
    spread = spread or 40
    life_base = life_base or 0.6
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 10 + math.random() * spread
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 10,
            r = r, g = g, b = b, a = 0.9,
            life = life_base + math.random() * 0.3,
            max_life = life_base + 0.3,
            size = 1.5 + math.random() * 2.5,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 20 * dt
        p.life = p.life - dt
        p.a = math.max(0, (p.life / p.max_life) * 0.9)
        p.size = p.size * (1 - dt * 1.2)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ============================================================
-- Tween state (smooth highlight bars)
-- ============================================================
local tween_bars = {0, 0, 0, 0, 0, 0}
local TWEEN_SPEED = 12

-- ============================================================
-- Simulation balls (Scene 2)
-- ============================================================
local balls = {}

local function spawn_ball(x, y)
    if #balls >= MAX_BALLS then return end
    table.insert(balls, {
        x = x or (SIM_X_LEFT + 40 + math.random() * (SIM_X_RIGHT - SIM_X_LEFT - 80)),
        y = y or (SIM_Y_TOP + 20 + math.random() * 60),
        vx = -60 + math.random() * 120,
        vy = -40 + math.random() * 20,
        r = 0.3 + math.random() * 0.7,
        g = 0.3 + math.random() * 0.7,
        b = 0.3 + math.random() * 0.7,
        radius = BALL_RADIUS - 2 + math.random() * 6,
    })
end

local function init_balls()
    balls = {}
    for i = 1, 10 do
        spawn_ball()
    end
end

-- ============================================================
-- FPS tracking
-- ============================================================
local fps = 0
local fps_timer = 0
local fps_count = 0
local total_frames = 0

-- ============================================================
-- Camera
-- ============================================================
local cam_x, cam_y = 0, 0

-- ============================================================
-- Transition helpers
-- ============================================================
local function switch_scene(new_state)
    if state == new_state then return end
    local old_state = state
    state = new_state
    -- Spawn transition particles at pipeline boxes
    for i = 1, PIPE_COUNT do
        local bx = PIPE_X0 + (i - 1) * (PIPE_BOX_W + PIPE_GAP) + PIPE_BOX_W / 2
        spawn_particles(bx, PIPE_Y + PIPE_BOX_H / 2, 0.2, 0.9, 0.5, 4, 25, 0.4)
    end
    -- Reset highlight tweens
    for i = 1, PIPE_COUNT do
        pipe_highlight[i] = 0
        tween_bars[i] = 0
    end
    if new_state == STATE_SCENE_2 then
        init_balls()
    end
    lurek.window.setTitle("Pipeline Showcase — " .. (scene_names[new_state] or "Title"))
end

local function is_pipe_active(index)
    if state == STATE_TITLE then return false end
    local mask = scene_masks[state]
    if not mask then return false end
    return mask[index] and pipe_enabled[index]
end

-- ============================================================
-- Input bindings
-- ============================================================
function lurek.ready()
    lurek.render.setBackgroundColor(0.06, 0.06, 0.08)
    lurek.window.setTitle("Pipeline Showcase — Lurek2D")
    lurek.camera.setPosition(0, 0)

    lurek.input.bind("1", "scene_1")
    lurek.input.bind("2", "scene_2")
    lurek.input.bind("3", "scene_3")
    lurek.input.bind("f1", "toggle_1")
    lurek.input.bind("f2", "toggle_2")
    lurek.input.bind("f3", "toggle_3")
    lurek.input.bind("f4", "toggle_4")
    lurek.input.bind("f5", "toggle_5")
    lurek.input.bind("f6", "toggle_6")
    lurek.input.bind("escape", "quit")

    pipe_fired[1] = true
    pipe_frame_counts[1] = 1
    pipe_highlight[1] = 1.0

    init_balls()
end

-- ============================================================
-- process(dt) — callback index 2
-- ============================================================
lurek.process(function(dt)
    -- FPS
    fps_timer = fps_timer + dt
    fps_count = fps_count + 1
    if fps_timer >= 1.0 then
        fps = fps_count
        fps_count = 0
        fps_timer = fps_timer - 1.0
    end
    total_frames = total_frames + 1

    -- Title state
    if state == STATE_TITLE then
        title_timer = title_timer + dt
        if title_timer > 3.0 then
            switch_scene(STATE_SCENE_2)
        end
        update_particles(dt)

        -- Input check even on title
        if lurek.input.isActionPressed("scene_1") then switch_scene(STATE_SCENE_1) end
        if lurek.input.isActionPressed("scene_2") then switch_scene(STATE_SCENE_2) end
        if lurek.input.isActionPressed("scene_3") then switch_scene(STATE_SCENE_3) end
        if lurek.input.isActionPressed("quit") then lurek.event.quit() end
        return
    end

    -- Input: scene switching
    if lurek.input.isActionPressed("scene_1") then switch_scene(STATE_SCENE_1) end
    if lurek.input.isActionPressed("scene_2") then switch_scene(STATE_SCENE_2) end
    if lurek.input.isActionPressed("scene_3") then switch_scene(STATE_SCENE_3) end
    if lurek.input.isActionPressed("quit") then lurek.event.quit() end

    -- Input: toggle callbacks
    for i = 1, 6 do
        if lurek.input.isActionPressed("toggle_" .. i) then
            pipe_enabled[i] = not pipe_enabled[i]
            local bx = PIPE_X0 + (i - 1) * (PIPE_BOX_W + PIPE_GAP) + PIPE_BOX_W / 2
            if pipe_enabled[i] then
                spawn_particles(bx, PIPE_Y + PIPE_BOX_H / 2, 0.2, 1.0, 0.4, 5, 30, 0.5)
            else
                spawn_particles(bx, PIPE_Y + PIPE_BOX_H / 2, 1.0, 0.3, 0.2, 5, 30, 0.5)
            end
        end
    end

    -- Mark process as fired
    local t0 = lurek.timer.getTime()
    if is_pipe_active(2) then
        pipe_fired[2] = true
        pipe_frame_counts[2] = pipe_frame_counts[2] + 1
        pipe_dt_values[2] = dt
        pipe_highlight[2] = 1.0
    end

    -- Update tween bars
    for i = 1, PIPE_COUNT do
        local target = pipe_fired[i] and 1.0 or 0.0
        tween_bars[i] = lerp(tween_bars[i], target, dt * TWEEN_SPEED)
        pipe_highlight[i] = math.max(0, pipe_highlight[i] - dt * 3.0)
    end

    update_particles(dt)

    pipe_times_ms[2] = (lurek.timer.getTime() - t0) * 1000
end)

-- ============================================================
-- process_physics(dt) — callback index 3
-- ============================================================
lurek.process_physics(function(dt)
    if not is_pipe_active(3) then return end

    local t0 = lurek.timer.getTime()
    pipe_fired[3] = true
    pipe_frame_counts[3] = pipe_frame_counts[3] + 1
    pipe_dt_values[3] = dt
    pipe_highlight[3] = 1.0

    -- Physics: apply gravity and bounce
    if state == STATE_SCENE_2 then
        for _, ball in ipairs(balls) do
            ball.vy = ball.vy + GRAVITY * dt
            ball.x = ball.x + ball.vx * dt
            ball.y = ball.y + ball.vy * dt

            -- Floor bounce
            if ball.y + ball.radius > SIM_Y_BOT then
                ball.y = SIM_Y_BOT - ball.radius
                ball.vy = -math.abs(ball.vy) * BALL_DAMPING
                spawn_particles(ball.x, ball.y + ball.radius, ball.r, ball.g, ball.b, 3, 20, 0.3)
            end
            -- Ceiling bounce
            if ball.y - ball.radius < SIM_Y_TOP then
                ball.y = SIM_Y_TOP + ball.radius
                ball.vy = math.abs(ball.vy) * BALL_DAMPING
            end
            -- Wall bounces
            if ball.x - ball.radius < SIM_X_LEFT then
                ball.x = SIM_X_LEFT + ball.radius
                ball.vx = math.abs(ball.vx) * BALL_DAMPING
            end
            if ball.x + ball.radius > SIM_X_RIGHT then
                ball.x = SIM_X_RIGHT - ball.radius
                ball.vx = -math.abs(ball.vx) * BALL_DAMPING
            end
        end
    end

    pipe_times_ms[3] = (lurek.timer.getTime() - t0) * 1000
end)

-- ============================================================
-- process_late(dt) — callback index 4
-- ============================================================
lurek.process_late(function(dt)
    if not is_pipe_active(4) then return end

    local t0 = lurek.timer.getTime()
    pipe_fired[4] = true
    pipe_frame_counts[4] = pipe_frame_counts[4] + 1
    pipe_dt_values[4] = dt
    pipe_highlight[4] = 1.0

    -- Resolve ball-to-ball overlaps
    if state == STATE_SCENE_2 then
        for i = 1, #balls do
            for j = i + 1, #balls do
                local a = balls[i]
                local b = balls[j]
                local dx = b.x - a.x
                local dy = b.y - a.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local min_dist = a.radius + b.radius
                if dist < min_dist and dist > 0.01 then
                    local overlap = (min_dist - dist) * 0.5
                    local nx = dx / dist
                    local ny = dy / dist
                    a.x = a.x - nx * overlap
                    a.y = a.y - ny * overlap
                    b.x = b.x + nx * overlap
                    b.y = b.y + ny * overlap
                    -- Swap velocity components along normal
                    local rel_vn = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny
                    if rel_vn < 0 then
                        a.vx = a.vx + rel_vn * nx * 0.5
                        a.vy = a.vy + rel_vn * ny * 0.5
                        b.vx = b.vx - rel_vn * nx * 0.5
                        b.vy = b.vy - rel_vn * ny * 0.5
                    end
                end
            end
        end
    end

    pipe_times_ms[4] = (lurek.timer.getTime() - t0) * 1000
end)

-- ============================================================
-- render() — callback index 5 (simulation world)
-- ============================================================
lurek.render(function()
    -- Title screen
    if state == STATE_TITLE then
        local alpha = clamp(title_timer / TITLE_FADE_IN, 0, 1)
        lurek.render.print("PIPELINE SHOWCASE", SCREEN_W / 2 - 160, SCREEN_H / 2 - 50, 32, 0.2 * alpha, 0.9 * alpha, 1.0 * alpha, alpha)
        lurek.render.print("ENGINE CALLBACK FLOW", SCREEN_W / 2 - 140, SCREEN_H / 2, 20, 0.6 * alpha, 0.7 * alpha, 0.8 * alpha, alpha * 0.8)
        local pulse = 0.5 + 0.5 * math.sin(title_timer * 3)
        lurek.render.print("Press 1 / 2 / 3 to pick a scene", SCREEN_W / 2 - 140, SCREEN_H / 2 + 60, 14, 0.5, 0.5, 0.5, pulse)
        -- Render particles
        for _, p in ipairs(particles) do
            lurek.render.circle(p.x, p.y, p.size, p.r, p.g, p.b, p.a)
        end
        return
    end

    if not is_pipe_active(5) then return end

    local t0 = lurek.timer.getTime()
    pipe_fired[5] = true
    pipe_frame_counts[5] = pipe_frame_counts[5] + 1
    pipe_highlight[5] = 1.0

    -- Draw simulation area border
    lurek.render.rectangle(SIM_X_LEFT - 2, SIM_Y_TOP - 2, SIM_X_RIGHT - SIM_X_LEFT + 4, SIM_Y_BOT - SIM_Y_TOP + 4, 0.15, 0.15, 0.2, 0.6)

    -- Draw balls
    if state == STATE_SCENE_2 or state == STATE_SCENE_3 then
        for _, ball in ipairs(balls) do
            lurek.render.circle(ball.x, ball.y, ball.radius, ball.r, ball.g, ball.b, 0.9)
            -- Shadow
            lurek.render.circle(ball.x + 2, ball.y + 2, ball.radius, 0, 0, 0, 0.2)
        end
    end

    -- Scene 1: menu placeholder
    if state == STATE_SCENE_1 then
        lurek.render.print("(Menu scene — no world render)", SCREEN_W / 2 - 120, SCREEN_H / 2, 16, 0.4, 0.4, 0.5, 0.6)
    end

    -- Particles
    for _, p in ipairs(particles) do
        lurek.render.circle(p.x, p.y, p.size, p.r, p.g, p.b, p.a)
    end

    pipe_times_ms[5] = (lurek.timer.getTime() - t0) * 1000
end)

-- ============================================================
-- render_ui() — callback index 6 (pipeline diagram + stats)
-- ============================================================
lurek.render_ui(function()
    if state == STATE_TITLE then return end

    if not is_pipe_active(6) then return end

    local t0 = lurek.timer.getTime()
    pipe_fired[6] = true
    pipe_frame_counts[6] = pipe_frame_counts[6] + 1
    pipe_highlight[6] = 1.0

    -- ── Pipeline flow chart ──
    for i = 1, PIPE_COUNT do
        local bx = PIPE_X0 + (i - 1) * (PIPE_BOX_W + PIPE_GAP)
        local by = PIPE_Y
        local active = is_pipe_active(i)
        local fired = pipe_fired[i]

        -- Connection arrow
        if i > 1 then
            local ax = bx - PIPE_GAP
            lurek.render.rectangle(ax, by + PIPE_BOX_H / 2 - 1, PIPE_GAP, 2, 0.3, 0.3, 0.4, 0.6)
            -- Arrow head
            lurek.render.rectangle(bx - 4, by + PIPE_BOX_H / 2 - 3, 4, 6, 0.3, 0.3, 0.4, 0.6)
        end

        -- Box background
        local bg_r, bg_g, bg_b, bg_a = 0.12, 0.12, 0.18, 0.8
        if not pipe_enabled[i] then
            bg_r, bg_g, bg_b, bg_a = 0.2, 0.08, 0.08, 0.6
        elseif fired and active then
            local h = pipe_highlight[i]
            bg_r = lerp(0.08, 0.1, h)
            bg_g = lerp(0.15, 0.5, h)
            bg_b = lerp(0.08, 0.2, h)
            bg_a = lerp(0.7, 0.95, h)
        end
        lurek.render.rectangle(bx, by, PIPE_BOX_W, PIPE_BOX_H, bg_r, bg_g, bg_b, bg_a)

        -- Box border
        local br, bg, bb = 0.25, 0.25, 0.35
        if fired and active then
            br, bg, bb = 0.3, 0.9, 0.4
        elseif not pipe_enabled[i] then
            br, bg, bb = 0.6, 0.2, 0.2
        end
        lurek.render.rectangle(bx, by, PIPE_BOX_W, 1, br, bg, bb, 0.8)
        lurek.render.rectangle(bx, by + PIPE_BOX_H - 1, PIPE_BOX_W, 1, br, bg, bb, 0.8)
        lurek.render.rectangle(bx, by, 1, PIPE_BOX_H, br, bg, bb, 0.8)
        lurek.render.rectangle(bx + PIPE_BOX_W - 1, by, 1, PIPE_BOX_H, br, bg, bb, 0.8)

        -- Label
        local lr, lg, lb = 0.5, 0.5, 0.6
        if not pipe_enabled[i] then lr, lg, lb = 0.5, 0.2, 0.2 end
        if fired and active then lr, lg, lb = 0.4, 1.0, 0.5 end
        lurek.render.print(pipe_short[i], bx + 6, by + 4, 11, lr, lg, lb, 1.0)

        -- Timing
        local time_str = string.format("%.2fms", pipe_times_ms[i])
        lurek.render.print(time_str, bx + 6, by + 18, 9, 0.4, 0.4, 0.5, 0.7)

        -- F-key toggle indicator
        lurek.render.print("F" .. i, bx + PIPE_BOX_W - 22, by + 4, 9, 0.3, 0.3, 0.4, 0.5)

        -- Tween bar (animated timing indicator below box)
        local bar_w = tween_bars[i] * PIPE_BOX_W
        if bar_w > 1 then
            lurek.render.rectangle(bx, by + PIPE_BOX_H + 2, bar_w, 3, 0.2, 0.7, 0.3, 0.6 * tween_bars[i])
        end
    end

    -- ── Execution order list ──
    local order_y = PIPE_Y + PIPE_BOX_H + 20
    lurek.render.print("Execution Order:", 20, order_y, 12, 0.5, 0.6, 0.7, 0.8)
    local step = 1
    for i = 1, PIPE_COUNT do
        if is_pipe_active(i) then
            local color_g = pipe_fired[i] and 0.9 or 0.4
            lurek.render.print(step .. ". " .. pipe_labels[i], 30, order_y + step * 16, 11, 0.3, color_g, 0.5, 0.8)
            step = step + 1
        end
    end

    -- ── Scene info panel ──
    local panel_x = SCREEN_W - 260
    local panel_y = PIPE_Y + PIPE_BOX_H + 20
    lurek.render.rectangle(panel_x - 8, panel_y - 4, 256, 110, 0.08, 0.08, 0.12, 0.7)

    local sname = scene_names[state] or "Title"
    local sdesc = scene_descs[state] or ""
    lurek.render.print("Scene: " .. sname, panel_x, panel_y, 14, 0.4, 0.8, 1.0, 1.0)
    lurek.render.print(sdesc, panel_x, panel_y + 20, 10, 0.4, 0.5, 0.6, 0.7)

    -- dt values
    lurek.render.print("dt values:", panel_x, panel_y + 42, 11, 0.5, 0.5, 0.6, 0.8)
    local dt_y = panel_y + 56
    for i = 2, 4 do
        if is_pipe_active(i) then
            local dtstr = string.format("%s: %.4fs", pipe_short[i], pipe_dt_values[i])
            lurek.render.print(dtstr, panel_x + 8, dt_y, 10, 0.35, 0.55, 0.45, 0.7)
            dt_y = dt_y + 14
        end
    end

    -- ── Stats bar (bottom) ──
    local bar_y = SCREEN_H - 30
    lurek.render.rectangle(0, bar_y - 4, SCREEN_W, 34, 0.05, 0.05, 0.08, 0.85)

    lurek.render.print("FPS: " .. fps, 12, bar_y, 12, 0.3, 0.8, 0.4, 0.9)
    lurek.render.print("Frames: " .. total_frames, 100, bar_y, 12, 0.4, 0.5, 0.6, 0.8)

    -- Per-callback frame counts
    local cx = 240
    for i = 1, PIPE_COUNT do
        local label = pipe_short[i] .. ":" .. pipe_frame_counts[i]
        local cr = pipe_enabled[i] and 0.35 or 0.5
        local cg = pipe_enabled[i] and 0.55 or 0.2
        local cb = pipe_enabled[i] and 0.45 or 0.2
        lurek.render.print(label, cx, bar_y, 10, cr, cg, cb, 0.7)
        cx = cx + 70
    end

    -- Scene selector hint
    lurek.render.print("[1] Menu  [2] Sim  [3] Pause  |  F1-F6 toggle", 12, bar_y + 14, 10, 0.3, 0.3, 0.4, 0.5)

    -- Ball count for scene 2
    if state == STATE_SCENE_2 then
        lurek.render.print("Balls: " .. #balls, SCREEN_W - 90, bar_y, 12, 0.4, 0.6, 0.8, 0.8)
    end

    pipe_times_ms[6] = (lurek.timer.getTime() - t0) * 1000

    -- Reset fired flags for next frame
    for i = 1, PIPE_COUNT do
        pipe_fired[i] = false
    end
end)
